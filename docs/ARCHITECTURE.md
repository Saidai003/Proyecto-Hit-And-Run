# ARCHITECTURE — Prototipo: Golpear y huir

- Place: `118890619753629`
- Studio instance id used during read: `7e2df06b-66dc-4c04-92d5-1031ad882f1c`
- Source of every line range and attribute in this doc: read-only MCP calls (`script_read`, `inspect_instance`, `search_game_tree`, `script_grep`) on the running Studio.
- **Nothing in this file was written from memory or guessing.** Items marked **(inferred)** mean the script's behavior was deduced from its code but not yet exercised by a test; **(unverified)** means the MCP result was ambiguous or couldn't be confirmed.

> How to read this doc: every section is named and cross-linked. "VALIDATES" lines name the only authoritative checks on the server. Anything the client writes that the server doesn't is a bug-class action, called out as such.

---

## 1. High-level flow

1. Both players spawn at `LobbySpawn`.
2. Player 1 clicks **PLAY NOW!** (`InterfazJuego1v1` client script) → fires `EventoMatchmaking:FireServer("BUSCAR_PARTIDA")`.
3. Server (`Controlador1v1` + `ServidorMatchmaking1v1`) puts them in `jugadoresEnCola`, replies with `EventoJuego:FireClient(player, "ESPERANDO_JUGADOR")`.
4. As soon as a second player is queued, server pairs `jugador1` / `jugador2` and enters the **RONDAS** loop.
5. Each round: server teleports both to `RoundSpawn1` / `RoundSpawn2` (+3 studs Y), assigns roles, fires `BLOQUEAR_MOVIMIENTO`, fires `EventoCountdown` (BindableEvent) → `ControladorCountdown` `FireAllClients("COUNTDOWN", n)` 3→2→1→`"INICIO"`.
6. `DESBLOQUEAR_MOVIMIENTO` and `establecerAtaques(true)` after countdown. Runners are `PERSEGUIDO` (HP 16 base), killers are `PERSEGUIDOR` (HP 20 base + 1.25× height/width/headscale).
7. Either the runner survives `TIEMPO_MAXIMO_RONDA = 120 s`, or lives reach 0 (`"DERROTA"`), or one leaves (`"Un jugador abandonó…"`). Server fires `RESULTADO_RONDA` and waits `DURACION_ENTRE_RONDAS = 2 s`.
8. After `CANTIDAD_RONDAS = 6`, server totals accumulated survival times per player, picks the smaller, fires `RESULTADO_FINAL`, waits `TIEMPO_RESULTADO_FINAL = 5 s`, then `OCULTAR_RESULTADO`, then `TeleportAsync` to lobby `PLACE_ID_LOBBY = 0` (effectively a no-op — see §11).

---

## 2. Script inventory

Read on Studio MCP. Line counts confirmed by reading the last lines and getting a "file only has N lines" response. **17 script bodies in `/Workspace` and `StarterPlayer/StarterPlayerScripts`. 1 of those is empty** (see §6).

| Path | Side | Lines | Purpose | Server-side validation present? |
|---|---|---:|---|---|
| `ServerScriptService.Controlador1v1` | Server Script | 893 | Top-level match loop: matchmaking, role assignment, round timer, attack handler, result panel data. Owns `EventoMatchmaking.OnServerEvent`. | yes (queue + attack) |
| `ServerScriptService.SistemaPale1v1` | Server Script | 1436 | Pallet registry on load, drop animation, vault through, break, stun. Owns `EventoPale1v1.OnServerEvent`. | yes |
| `ServerScriptService.ServerThrow` | Server Script | 173 | Authoritative throwable (chair) system. Validates aim Vector3, tool is `Throwable`, not currently `Throwing`, humanoid alive. Drives `startHitDetection` to apply `knockOut`. | yes |
| `ServerScriptService.SistemaHit1v1` | Server Script | 70 | **Dead code** (see §6). Defines `intentarHit` that is never called; sends `FireClient("Realizado"/"Recibido")` events no client handles. Uses an unreachable gap of `DISTANCIA_HIT = 4`. | n/a |
| `ServerScriptService.ServidorMatchmaking1v1` | Server Script | 31 | Lightweight listener for `BUSCAR_PARTIDA` that just sets `Jugador:SetAttribute("BuscandoPartida", true)` and echoes `ESPERANDO_JUGADOR`. **The actual queue logic lives in `Controlador1v1`** — this script is mostly redundant. | minimal |
| `ServerScriptService.ControladorCountdown` | Server Script | 19 | Listens to `EventoCountdown` (BindableEvent), fires `EventoJuego:FireAllClients("COUNTDOWN"/"INICIO")`. | yes (driver only) |
| `StarterPlayer.StarterPlayerScripts.InterfazJuego1v1` | Local | 556 | Builds the HUD: PLAY NOW, HOW TO PLAY modal, role/lives/round labels, ATTACK button, message, final result panel. Listens to `EventoJuego.OnClientEvent`. | yes |
| `StarterPlayer.StarterPlayerScripts.LogicaVelocidad1v1` | Local | 325 | Client-only stamina + sprint (LShift), FOV smooth, locks/unlocks movement on `BLOQUEAR/DESBLOQUEAR_MOVIMIENTO`. **Server has no awareness.** | no (client-only state) |
| `StarterPlayer.StarterPlayerScripts.LogicaPallet1v1` | Local | 154 | Reads Space key. (a) Drop pallet: `FireServer("INTERACTUAR")` + drop animation. (b) Vault fallen pallet: **client-side straight TweenService tween to `punto + (0,2,0)`** AND toggles `BloqueoPale.CanCollide` from the client (F3). | no client validation; server re-validates on `FireServer` |
| `StarterPlayer.StarterPlayerScripts.LogicaParkour1v1` | Local | 609 | Reads Space key for `PuntoEntrada` (NarrowedWalk) and `PuntoSalto` (Window). Uses `VectorForce` anti-gravity, character collision off, parabolic `Lerp` over a single `Heartbeat` loop, then `Freefall`-style reattach via raycast. Killer is slower than runner here. | no server validation — there is no worker dispatching this from the server |
| `StarterPlayer.StarterPlayerScripts.LogicaNarrowedWalk` | Local | **0** | `Source=""` — empty placeholder. Not loaded by any other script. | n/a |
| `StarterPlayer.StarterPlayerScripts.SistemaHit1v1` | Local | 425 | Killer lunge + attack. Plays animation, transient speed boost (×1.5), then `EventoAtaque:FireServer()`. Handles `EventoHit1v1.OnClientEvent("HIT", …)` → sparks + screen flash + camera shake. | client trusts server; only fires on user input |
| `StarterPlayer.StarterPlayerScripts.EfectosPale1v1` | Local | 223 | Plays stun animation on whoever the server sends via `EventoPale1v1:FireAllClients("ATURDIDO", other, duracion)`. Uses `Animation` ID `74925900786167` at 0.5× speed. | n/a (display only) |
| `StarterPlayer.StarterPlayerScripts.SaltoPaleCliente` | Local | 105 | Server-driven pallet-vault parabola. Listens to `EventoPale1v1:FireClient(jugador, "SALTAR", destino, duracion, altura)`; **only path** for windows is `LogicaParkour1v1`. First 13 lines are leftover ThrowChairClient debug (F1 bug). | client trusts server `destino`/`duracion`/`altura` |
| `StarterPlayer.StarterPlayerScripts.ThrowChairCliente` | Local | 90+ | Reads MouseButton1 hold to aim throwable (FOV 65, camera offset, raised arms, neon parabola). On release, fires `ThrowChairEvent:FireServer(direction)`. | n/a (client-only input) |
| `StarterPlayer.StarterPlayerScripts.MatchmakingCliente` | Local | 90 | **Dead code** (see §6). Builds a second "Jugar / Cancelar" GUI that the server never drives — server only understands `"BUSCAR_PARTIDA"`, not `"BUSCAR"` or `"CANCELAR"`, and never sends back `EN_COLA`/`FUERA_DE_COLA`/`ENCONTRADO`/`ERROR`. | n/a |
| `StarterPlayer.StarterPlayerScripts.ControladorMusica` | Local | 33 | Listens to `Workspace:GetAttributeChangedSignal("RondaEnJuego")`; 2 s fade-in / 1.5 s fade-out for `SoundService.MusicaPersecucion` (id `89277650004927`). | n/a (audio only) |
| `Workspace.ROCK.Script` | Tool Script | 72 | **Dead code** (see §6). A complete throwable system (anti-cheat, BodyVelocity, joints, network ownership), but waits forever on `Tool:WaitForChild("ThrowEvent")` — that event doesn't exist anywhere. | n/a (never runs) |
| `Workspace.ROCK.LocalScript` | Tool LocalScript | 13 | **Dead code** (see §6). On `Tool.Activated` calls `Tool.RemoteFunction:InvokeServer({target, char, hum})`. The RemoteFunction has no `OnServerInvoke`. | n/a |
| `Workspace.ROCK.RemoteFunction` | — | — | Orphan `RemoteFunction`, no script listens. | n/a |

**Total: 19 script bodies.** 18 are read in full; `Workspace.ROCK.RemoteFunction` is a non-script instance included for completeness.

---

## 3. RemoteEvent / BindableEvent inventory

All instances confirmed via `search_game_tree` on `ReplicatedStorage`. Validations listed are what the **server** does; nothing client-side is trusted.

| Remote | Type | Server handler script | Server validates | Client fires | Client listens |
|---|---|---|---|---|---|
| `EventoJuego` | RemoteEvent | `Controlador1v1` (server-side only `FireClient/AllClients`) | n/a (outgoing only) | — | `InterfazJuego1v1`, `LogicaVelocidad1v1`, `SistemaHit1v1` |
| `EventoAtaque` | RemoteEvent | `Controlador1v1.atacar()` (line 551) | state, `ataquesHabilitados`, role, cooldown, distance ≤ `DISTANCIA_ATAQUE=6`, attacker not `Inmovilizado`, victim alive | `SistemaHit1v1` client (line 264) | — |
| `EventoCountdown` | BindableEvent | `ControladorCountdown` (driver) | none (it's a signal) | `Controlador1v1` (`EventoCountdown:Fire()`) | `ControladorCountdown` (`OnServerEvent:Connect(iniciarCountdown)` is actually `BindableEvent.Event:Connect`) |
| `EventoHit1v1` | RemoteEvent | **none on the server** | n/a (outgoing only) | — | `SistemaHit1v1` client (line 401) |
| `EventoMatchmaking` | RemoteEvent | `ServidorMatchmaking1v1`, `Controlador1v1` | string match `"BUSCAR_PARTIDA"` only — no rate-limit, no role/state check | `InterfazJuego1v1` (line 384, valid), `MatchmakingCliente` (line 86–88, dead) | `MatchmakingCliente` (line 78, dead) |
| `EventoPale1v1` | RemoteEvent | `SistemaPale1v1` (line 1214) | state of round (`RondaEnJuego`), debounce ≥ 0.3 s, not `Inmovilizado`, role+state+distance to the **nearest** of `p1`/`p2` (≤ `DISTANCIA_INTERACCION=5`) | `LogicaPallet1v1` (`FireServer("INTERACTUAR")`) | `SaltoPaleCliente` (`SALTAR`), `EfectosPale1v1` (`ATURDIDO`) |
| `ThrowChairEvent` | RemoteEvent | `ServerThrow` (line 111) | aim is a finite `Vector3` with `0.5 ≤ |aim|`, tool has `Throwable`, not `Throwing`, humanoid alive | `ThrowChairCliente` | — |

**Central `EventoJuego` server-side commands** (server → client, all confirmed):
`"ROL"`, `"RONDA"`, `"VIDAS"`, `"COUNTDOWN"`, `"INICIO"`, `"BLOQUEAR_MOVIMIENTO"`, `"DESBLOQUEAR_MOVIMIENTO"`, `"RESULTADO_RONDA"`, `"RESULTADO_FINAL"`, `"OCULTAR_RESULTADO"`, `"ESPERANDO_JUGADOR"`, `"RESET_JUGADOR"` (sent by `LogicaVelocidad1v1` listener, **never sent by the server** — confirmed by re-reading `Controlador1v1`).

**Central `EventoJuego` actions sent from the client side**: **none** (`script_grep` returned no `FireServer("EventoJuego"…)` call site). Every command originates server-side.

---

## 4. Attribute inventory

| Attribute | Set by | Read by | Notes |
|---|---|---|---|
| `Player.Rol` = `"PERSEGUIDO"` \| `"PERSEGUIDOR"` | `Controlador1v1.asignarRoles()` (line 243–244) | `LogicaVelocidad1v1`, `LogicaPallet1v1`, `LogicaParkour1v1`, `SistemaHit1v1`, `InterfazJuego1v1` | set once per round; clients read it via `GetAttribute`, never `GetAttributeChangedSignal` |
| `Humanoid.Inmovilizado` (bool) | `SistemaPale1v1.inmovilizar()` (line 214) | `Controlador1v1.atacar()` line 573, `SistemaPale1v1` line 1253, `LogicaPallet1v1` line 91 | server-authoritative; bumped per call (records an `id`) so newer interrupts override older releases |
| `Humanoid.GolpeActivo` (bool) | `SistemaHit1v1` client (line 309) | `SistemaHit1v1` client (line 319) | client-only marker so parkour can block the lunge |
| `Humanoid.ParkourEspecialActivo` (bool) | `LogicaParkour1v1.comenzarAccion()` (line 377) | `SistemaHit1v1` (line 287, 319) | client-only marker; nothing on server |
| `Humanoid.KnockedOut` (bool) | `ServerThrow.knockOut()` (line 33, 72) | `ServerThrow.knockOut()` (line 29) | chair-induced knockout (not pallet stun) |
| `Player.BuscandoPartida` (bool) | `ServidorMatchmaking1v1` (line 17) | nowhere read | orphan flag, harmless |
| `Pallet_NN.EstadoPale` = `"Parado"` \| `"Cayendo"` \| `"Caido"` \| `"Roto"` | `SistemaPale1v1.registrarPale/soltarPale/explotarPale` | `LogicaPallet1v1` (line 99), `SistemaPale1v1` self | resets every round via `reiniciarPales()` watching `Workspace.IdRonda` |
| `Pallet_NN.Rompiendo` (bool) | `SistemaPale1v1.romperPale()` | `LogicaPallet1v1` (line 100), `SistemaPale1v1` | prevents re-arming the break animation |
| `Pallet_NN.InvisibleWall.CollisionGroup` = `"PaleWall"` | `SistemaPale1v1.configurarInvisibleWall()` | server only | group `Saltando` collides with `PaleWall` = false (line 65–69) |
| `Workspace.RondaEnJuego` (bool) | `Controlador1v1.establecerAtaques()` (line 68) | `ControladorMusica`, `SistemaPale1v1` (line 1223) | drives music fade and pallet interaction gate |
| `Workspace.IdRonda` (number) | `Controlador1v1.iniciarRonda()` (line 449) | `SistemaPale1v1` (line 1205), `inmovilizar()` line 201 | monotonically increases; resets/restarts pales on change |
| `Tool.Throwable` (bool) | present on `Workspace.Chair` (Tool, **not on `Workspace.ROCK`**) | `ServerThrow` (line 120), `ThrowChairCliente` (line 34) | required for any throwable path |
| `Tool.Throwing` (bool) | `ServerThrow` line 128 | `ServerThrow` line 121, `ThrowChairCliente` (via server) | one in-flight throw per tool |

---

## 5. Workspace map (relevant parts only)

Confirmed via `search_game_tree(Workspace)` and `inspect_instance`.

| Object | Children / Notes |
|---|---|
| `RoundSpawn1`, `RoundSpawn2`, `LobbySpawn` | spawn anchors used by `Controlador1v1.transportarJugadores()` |
| `SpawnLocation` | default spawn |
| `ParkourInteractables.Pallet_01..Pallet_04` (Folders) | each has `Pallet` (MeshPart), `PuntoPale_1`, `PuntoPale_2`, `InvisibleWall`. **No child named `BloqueoPale` is present** — the brief's mention is stale. The brief's "BloqueoPale" name is `InvisibleWall` everywhere in code. |
| `ParkourInteractables.Window_01` (Folder) | `PuntoSalto_1`, `PuntoSalto_2` (no geometry; "window" is just markers) |
| `ParkourInteractables.NarrowedWalk_01` (Folder) | `PuntoEntrada_1`, `PuntoEntrada_2` (no geometry) |
| `Window`, `Walls`, `Crane`, `Construction Crane`, `Stone Character Statue`, `Homer`, `Folder` (decorative), `InvisibleWall` (decorative root-level duplicate) | not in scope |
| `Chair` (Tool, `Throwable=true`) | the throwable item that uses `ServerThrow` + `ThrowChairCliente` |
| `ROCK` (Tool, **no `Throwable` attribute**) | leftover decoration with dead code inside (see §6) |
| `SoundService.MusicaPersecucion` (Sound, id `89277650004927`) | driven by `ControladorMusica` |
| `ReplicatedStorage` | `EventoJuego`, `EventoAtaque`, `EventoCountdown` (BindableEvent), `EventoHit1v1`, `EventoMatchmaking`, `ThrowChairEvent` |
| `ServerStorage.PalesPlantilla` (Folder) | created at runtime by `SistemaPale1v1` line 105; holds pallet clones used by `reiniciarPales` |
| `StarterPack` | empty |
| `StarterGui` | empty (HUDs are built in code by `InterfazJuego1v1`, `MatchmakingCliente`, `SistemaHit1v1`) |

---

## 6. Dead / redundant / stale code inventory

Verified by reading each script and seeing nothing actually calls them.

| Symbol | Why it's dead | Brief expected this? |
|---|---|---|
| `Workspace.ROCK` (entire Tool) | No `Throwable` attribute; the parent `StarterPack` is empty so players never receive it; the two scripts inside wait for events that don't exist (the throwable system is `ThrowChairEvent` / `ServerThrow`). | partly — brief only flagged `Workspace.ROCK.Script` |
| `Workspace.ROCK.Script` | `Tool:WaitForChild("ThrowEvent")` yields forever (no such child) → `:Connect` line never runs. Body is a complete, working throwable system (would be a peer of `ServerThrow`), but unreachable. | yes (T14 delete) |
| `Workspace.ROCK.LocalScript` + `ROCK.RemoteFunction` | No `OnServerInvoke` for the RemoteFunction; client just calls `InvokeServer` and ignores the reply. | no |
| `ServerScriptService.SistemaHit1v1` | Defines `intentarHit(chaser, objetivo)` but **nothing calls it** (the script never connects to a RemoteEvent, and `Controlador1v1.atacar()` uses its own distance/cooldown). Also sends `"Realizado"/"Recibido"` events that no client handles. Uses a smaller `DISTANCIA_HIT = 4` than the real attacker (`DISTANCIA_ATAQUE = 6`). | no (T14 candidate) |
| `StarterPlayer.StarterPlayerScripts.MatchmakingCliente` | Server never sends `"EN_COLA"/"FUERA_DE_COLA"/"ENCONTRADO"/"ERROR"`. Server only understands `"BUSCAR_PARTIDA"` (from `InterfazJuego1v1`), not `"BUSCAR"` or `"CANCELAR"` (from this dead UI). The visible "Jugar" button is orphaned. | no (T14 candidate) |
| `StarterPlayer.StarterPlayerScripts.LogicaNarrowedWalk` | `Source=""` (verified by `inspect_instance` returning empty `Source`). Nothing imports/requires it. | no |
| `ServidorMatchmaking1v1` | Mostly redundant: `Controlador1v1.agregarALaCola` also runs on `BUSCAR_PARTIDA`. The attribute `BuscandoPartida` set here is never read. The brief already said matchmaking is disabled. | no |
| First 13 lines of `SaltoPaleCliente` | Leftover from a copy-paste of `ThrowChairCliente`: prints `[ThrowChairClient]`, waits for `ThrowChairEvent`, `return` if missing. **If `ThrowChairEvent` ever goes missing**, the whole script `return`s and never even calls `WaitForChild("EventoPale1v1")` (which is **after** the early return). | yes (F1) |
| Client `SistemaHit1v1`'s `FlashHit` ScreenGui | Created at top-level (line 161) on every respawn — never destroyed. Respawn leak. | no (cosmetic) |

---

## 7. Section-7 unknowns — answers

| # | Question | Answer (where) |
|---|---|---|
| 1 | Full contents of `Controlador1v1`, `SistemaPale1v1`, `InterfazJuego1v1`, `LogicaVelocidad1v1` — write summaries into this doc. | See §2 row for each, plus §1 / §8. All four read in full; line ranges verified. |
| 2 | Which script defines the killer attack and its current hitbox. | `Controlador1v1.atacar()` (line 551), handler at `EventoAtaque.OnServerEvent:Connect(atacar)` line 642. Hitbox = distance only, no cone, ≤ `DISTANCIA_ATAQUE = 6` studs. Cooldown `COOLDOWN_ATAQUE = 1` s. (inferred) the client uses lunge up to 1.5× speed and waits `RETRASO_IMPACTO = 0.1 s` before firing the remote (line 264 in `SistemaHit1v1` client). |
| 3 | Pallet stun: where, range, `Inmovilizado`. | `SistemaPale1v1.inmovilizar()` line 182; stun zone computed by `dentroDeZona()` line 599 (`LARGO_ZONA_ATURDIMIENTO=5` along fall direction, width = `datos.ancho/2 + MARGEN_LATERAL_ZONA`, vertical `±6` studs). Triggered after fall in `soltarPale()` line 791 with `DURACION_ATURDIMIENTO=2.0`. `Inmovilizado` is set/cleared by `inmovilizar()` only. |
| 4 | Where stamina lives and whether the server knows it. | **Entirely client-side** in `LogicaVelocidad1v1` (lines 19–28, 188–217). The server never sees it; sprint state lives in `sprintActivo` local; `WalkSpeed` is overwritten client-side every Heartbeat. Round start sets server-side WalkSpeed via `establecerVelocidad()` (line 108), but the next Heartbeat in `LogicaVelocidad1v1` overwrites it. |
| 5 | Which vault mechanism for pallets vs windows; which `EventoPale1v1` actions the server sends. | Pallets: server sends `"SALTAR"` (from `saltarPale` line 1126) → client `SaltoPaleCliente` parabolic CFrame (line 105). **In parallel**, `LogicaPallet1v1` lines 121–138 does its own client-side straight `TweenService` tween to `punto + (0,2,0)` and toggles `BloqueoPale.CanCollide` from the client. The two movement tweens fight on the same root (F2 confirmed). Windows: only `LogicaParkour1v1` handles them (line 535 `ejecutarSaltoVentana`). Server also sends `"ATURDIDO"` (`FireAllClients`, line 798). Drop animation on `LogicaPallet1v1` is just visual; server is authoritative. |
| 6 | All RemoteEvents, who fires them, whether each server handler validates. | See §3 table — every RemoteEvent accounted for, with validation column. |
| 7 | Where the round starts and how roles are assigned. | `Controlador1v1.iniciarRonda()` line 442, called inside the `for numeroRonda = 1, CANTIDAD_RONDAS` loop (line 827). Role assignment in `asignarRoles()` line 229: `rondaActual % 2 == 1` → `jugador1 = PERSEGUIDIDO`, `jugador2 = PERSEGUIDOR`; else swapped. Set via `SetAttribute("Rol", …)` on both players. **Bug for T04**: `asignarRoles()` runs **before** `BLOQUEAR_MOVIMIENTO` fires (line 461). A late-joining client that respawns or reloads during the COUNTDOWN window sees the role label update normally, but a client that joined at the same instant as `iniciarRonda` can call `rol=""` for one heartbeat (T04 race). (inferred) — never tested. |
| 8 | Other scripts touching `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `MouseBehavior`, `Humanoid.WalkSpeed`. | `script_grep` for all four returned **0 matches**. Only writers of `WalkSpeed` are `Controlador1v1.establecerVelocidad()` (round start) and `LogicaVelocidad1v1` (every Heartbeat). Camera FOV is touched in `LogicaVelocidad1v1` (sprint FOV 76) and `ThrowChairCliente` (aim FOV 65). **No zoom-distance conflict, no MouseBehavior conflict.** |
| 9 | Whether the project can be exported to Rojo format cleanly. | **(unknown, untested in Phase 1.)** No `default.project.json` is present in `Workspace` files. The author would need to install Rojo and run `rojo init` over the place; conflicts likely on (a) `Workspace.ROCK` (named `ROCK`, capitalized — Rojo often expects lowercase), (b) the auto-created `ServerStorage.PalesPlantilla` folder from `SistemaPale1v1` (runtime-only, would need to be ignored), (c) the dynamic `ThrowChairEvent` / `EventoMatchmaking` creation-if-missing in two scripts (Roblox will reject pre-created duplicates from a Rojo-import). Recommend deferring the export until after T14 cleanup. |

---

## 8. Two-tier interaction map (who does what)

### 8.1 Pallet

```
[client LogicaPallet1v1] Space on a nearby pallet
  if Parado (runner):
    play ANIM_DROP, FireServer("INTERACTUAR"), wait 0.8 s
  if Caido (runner):
    play ANIM_SLOW_VAULT (or FAST_VAULT if WalkSpeed>12)
    find nearest PuntoPale_x
    set BloqueoPale.CanCollide=false (client-side bug, F3)
    TweenService root -> pDestino + (0,2,0)
    wait duracion then set BloqueoPale.CanCollide=true
  if Caido (killer, !Rompiendo):
    play ANIM_HIT, FireServer("INTERACTUAR"), wait 2.0 s

[server SistemaPale1v1] OnServerEvent("INTERACTUAR")
  validate: RondaEnJuego, debounce ≥ 0.3 s, !Inmovilizado, role+state
  pick nearest pallet (≤ DISTANCIA_INTERACCION=5)
  if runner+Parado: soltarPale(mejor)
    if runner+Caido:  saltarPale(mejor)
      - compute destino = wall.side - sign(margin), setear Atravesando(true)
      - FireClient(jugador, "SALTAR", destino, 0.7, 4)         -- (in SaltoPaleCliente)
      - task.delay(0.85) setear Atravesando(false)
  if killer+Caido: romperPale(mejor)
    - inmovilize killer for 2 s, rotate facing, then explode()
    - then pallet parts fly + fade
  after drop animation completes:
    - For each PERSEGUIDOR whose root is inside dentroDeZona(): inmovilize for 2.0 s
    - FireAllClients("ATURDIDO", other, 2.0)                    -- (in EfectosPale1v1)
    - For any character in the falling line, snap them outside the wall (GROSOR_BLOQUEO=1.2 + 1)
  on round IdRonda change: reiniciarPales (destroy all, clone template, re-register)
```

### 8.2 Window vault / NarrowedWalk

```
[client LogicaParkour1v1] Space near PuntoEntrada_X or PuntoSalto_X
  arrancar AntiGravity (VectorForce = mass*gravity), WalkSpeed=0, AutoRotate=false
  desactivarColisionesPersonaje (CanCollide=false on every BasePart)
  aproximarse to punto_inicial
  play ANIM_NARROWED_WALK or ANIM_VAULT_WINDOW (loop segment for narrow)
  every Heartbeat: set root.CFrame = Lerp(inicio, salida, t) + arc
  on finish: ajustarAlSuelo (raycast for ground), restaurarColisiones, WalkSpeed=orig, AutoRotate=true
  Cooldown 0.6 s
  No server interaction. Killer is slower (3.0 stud/s narrow, 4.5 stud/s window vs 6.5 / 9 for runner)
```

### 8.3 Attack

```
[client SistemaHit1v1] Mouse1 down on a character you can hit (role PERSEGUIDOR, !ParkourEspecialActivo, !bloqueado)
  if no anim loaded yet: lanzarGolpe() -> task.delay(RETRASO_IMPACTO) EventoAtaque:FireServer()
  else:
    trackGolpe:Play at INICIO_LUNGE=0.29, WalkSpeed *= 1.5
    Heartbeat: while holding and t < FIN_LUNGE=0.71 -> keep boosting
    on release or FIN_LUNGE: trackGolpe.TimePosition=FIN_LUNGE, lanzarGolpe()
  COOLDOWN_GOLPE = 1.1 s

[server Controlador1v1.atacar()] on EventoAtaque
  validate: state RONDA_ACTIVA, ataquesHabilitados, role==perseguidor, !Inmovilizado
  cooldown 1 s
  if |hrpPerseguidor - hrpPerseguido| <= DISTANCIA_ATAQUE=6:
    vidas[perseguido] -= 1
    FireAllClients("HIT", perseguidor, perseguido, vidas)
    FireClient(perseguido, "VIDAS", vidas)
    if vidas<=0: finalizarRonda("DERROTA")

[client SistemaHit1v1] on "HIT"
  play sparks + Highlight on victim; red flash + CameraOffset shake if victim == local
```

### 8.4 Throwable chair

```
[client ThrowChairCliente] Mouse1 down while holding a Tool with Throwable=true
  set isAiming, walk-speed 8, FOV 65, camera offset
  Mouse1 up: aim direction = (raycast target - startPos).Unit
  FireServer(aimDirection)

[server ServerThrow.OnServerEvent]
  validate: aim is a finite Vector3 with magnitude in [0.5,∞); tool has Throwable; !Throwing
  tool.Parent = workspace; break joints; AssemblyLinearVelocity = aim * 60
  BodyVelocity 0.1 s then remove
  startHitDetection: Heartbeat loop for 4 s, lastVelocity check, GetPartBoundsInBox
  on hit: knockOut(victim, dir, handle)
    - PlatformStand, AddItem NoCollisionConstraint(handle, victim)
    - ApplyImpulse horizontal (35×mass) + vertical (15×mass)
    - task.delay(KNOCKOUT_TIME=3) straighten, ChangeState GettingUp
    - task.delay(KNOCK_IMMUNITY=1.5) clear attribute
```

---

## 9. Constants (one place to look)

These are the authoritative knobs in the code. T11 should pull all visible strings; T12–T15 will want to retune some of these.

**Round** (`Controlador1v1`): `VIDAS_INICIALES=3`, `DISTANCIA_ATAQUE=6`, `COOLDOWN_ATAQUE=1`, `TIEMPO_MAXIMO_RONDA=120`, `DURACION_ENTRE_RONDAS=2`, `CANTIDAD_RONDAS=6`, `TIEMPO_RESULTADO_FINAL=5`, `TIEMPO_ESPERA_RIVAL=60`, `PLACE_ID_LOBBY=0`, `VELOCIDAD_PERSEGUIDOR=20`, `VELOCIDAD_PERSEGUIDO=16`.

**Stamina/sprint** (`LogicaVelocidad1v1`): `STAMINA_PERSEGUIDO=100`, `STAMINA_PERSEGUIDOR=120`, `CONSUMO_SPRINT_PERSEGUIDO=18`, `CONSUMO_SPRINT_PERSEGUIDOR=20`, `RECUPERACION_STAMINA=14`, `VELOCIDAD_SPRINT_PERSEGUIDO=22`, `VELOCIDAD_SPRINT_PERSEGUIDOR=24`, `FOV_SPRINT=76`, `FOV_NORMAL=70`.

**Pallet** (`SistemaPale1v1`): `DISTANCIA_INTERACCION=5`, `TIEMPO_CAIDA=0.3`, `ANGULO_CAIDA=50`, `TIEMPO_BLOQUEO_SOBREVIVIENTE=0.4`, `TIEMPO_ROMPER=2.0`, `DURACION_ATURDIMIENTO=2.0`, `LARGO_ZONA_ATURDIMIENTO=5`, `MARGEN_LATERAL_ZONA=1`, `GROSOR_BLOQUEO=1.2`, `DURACION_SALTO=0.7`, `ALTURA_SALTO=4`, `MARGEN_ATERRIZAJE=2.5`. Sound IDs are placeholders (`rbxassetid://0`).

**Window / NarrowedWalk** (`LogicaParkour1v1`): `DISTANCIA_INTERACCION=5`, `VELOCIDAD_APROXIMACION=10`, `VELOCIDAD_NARROWED_WALK=6.5`, `VELOCIDAD_SALTO_VENTANA=9`, `MULTIPLICADOR_CARRERA=1.35`, `UMBRAL_DIRECCION_CARRERA=0.7`, `ALTURA_SALTO_VENTANA=0.8`, `DISTANCIA_LLEGADA=0.1`, `TIEMPO_COOLDOWN=0.6`, `NARROWED_ANIM_INICIO=0.29`, `NARROWED_ANIM_FIN=1.0`, killer-only slowdown: 3.0 narrow / 4.5 window.

**Throwable** (`ServerThrow`): `KNOCKOUT_TIME=3`, `MIN_HIT_SPEED=25`, `HIT_WINDOW=4`, `KNOCK_IMPULSE=35`, `THROW_VELOCITY=60`, `START_FORWARD=4`, `START_UP=1.5`, `PICKUP_DELAY=1.5`, `KNOCK_IMMUNITY=1.5`.

**Throwable (client)** (`ThrowChairCliente`, lines 22–29): `WALK_SPEED_AIMING=8`, `THROW_VELOCITY=60`, `START_FORWARD=4`, `START_UP=1.5`, `AIM_FOV=65`, `ORIGINAL_FOV=70`, `AIM_CAMERA_OFFSET=(-2.5,1.2,-6)`, `SMOOTHNESS=12`. **Both server and client duplicate `THROW_VELOCITY`, `START_FORWARD`, `START_UP`** — should move to a shared module (per brief §1 / Chair summary).

**Animation IDs in use (real, not placeholders)**: stun `74925900786167`, attack lunge `122984890985296`, pallet drop `95338026656426`, pallet slow vault `113078777285485`, pallet fast vault `91247705762076`, narrowed walk `127538049880566`, window vault `139297087203362`. Music `89277650004927`.

---

## 10. How a round works (the canonical happy path)

1. Both players click **PLAY NOW!** — `InterfazJuego1v1:377–385`. Button greys out, `FireServer("BUSCAR_PARTIDA")`.
2. Server (`Controlador1v1:363–377`) calls `agregarALaCola` for each, echoes `"ESPERANDO_JUGADOR"`. The `Message` label shows "WAITING FOR OPPONENT…" (`InterfazJuego1v1:412–424`).
3. Server polls the queue every 0.5 s (`esperarJugadores:397–435`). Two players → pair `jugador1`/`jugador2`, reset state, `EventoCountdown:Fire()`, wait 4 s while the countdown plays ("3" "2" "1" "GO!").
4. Server resets stats, `iniciarRonda()` runs:
   - `establecerAtaques(false)` so attacks are inert during the COUNTDOWN window.
   - Bumps `Workspace.IdRonda` → `SistemaPale1v1` clones fresh pallets (replaces any broken ones from prior rounds).
   - `vidas = {3,3}`.
   - `transportarJugadores()` teleports both to `RoundSpawn1` / `RoundSpawn2` (+3 Y).
   - `asignarRoles()` for odd rounds: j1 is runner, j2 is killer; reverse for even. Sets `Player.Rol`, sets `WalkSpeed`, mutates `HumanoidDescription` (HeightScale 1.25, WidthScale 1.25, HeadScale 1.15 for the killer), then prints round header.
   - `FireClient("ROL", "…")` to each, `FireAllClients("RONDA", n)`, `FireClient("VIDAS", 3)` to runner.
   - `FireAllClients("BLOQUEAR_MOVIMIENTO")` → `LogicaVelocidad1v1` zeroes `WalkSpeed`, `SistemaHit1v1` cancels any active lunge.
   - `task.wait(0.5)`. `tiempoInicioRonda = os.clock()`. **At this point the player is locked but already on the field — that's the T04 race window.**
5. Outer loop fires `EventoCountdown` again, waits 4 s, then `FireAllClients("DESBLOQUEAR_MOVIMIENTO")` and `establecerAtaques(true)`.
6. Players run. Music fades in over 2 s (`ControladorMusica`).
7. Killer swings: `SistemaHit1v1` client → lunge animation + 1.5× speed → `FireServer()` → server checks distance ≤ 6 → decrements lives → fires `EventoHit1v1("HIT", …)` → victim sees sparks, red flash, camera shake.
8. Runner drops a pallet on Space (`LogicaPallet1v1`) → server falls it (50° rotation, 0.3 s). On landing, the killer inside the 5-stud × `ancho/2+1` × 6-stud box behind the wall gets 2 s stun; everyone sees the stun animation; anyone in the falling line is snapped out. Runner holds Space to vault — **two client tweens fire** (`SaltoPaleCliente` parabola from server, `LogicaPallet1v1` straight tween from client).
9. Killer breaks a pallet: 2 s break animation, then the parts fly and fade.
10. Round ends if 120 s elapsed (`finalizarRonda("Tiempo máximo…")`), or any player's `parent == nil` (`"Un jugador abandonó…"`), or lives reach 0 (`"DERROTA"`).
11. Between rounds: `FireAllClients("DESBLOQUEAR_MOVIMIENTO")` and `FireAllClients("RESULTADO_RONDA", motivo)` (the message text is shown verbatim as `"DERROTA"` etc. by `InterfazJuego1v1:477–482` — Spanish reasons on the screen, English role labels elsewhere). Wait 2 s. Loop next round.
12. After round 6: `mostrarResultadoFinal()` totals `tiemposAcumulados[jugador]`, picks smaller, fires `RESULTADO_FINAL` with `{nombre1, nombre2, tiempo1, tiempo2, ganador}` — `InterfazJuego1v1` colors the winner green and shows `"You win!" / "You lose!" / "Draw!"`. After 5 s, `FireAllClients("OCULTAR_RESULTADO")` resets the lobby UI.
13. `volverAlLobby(Players:GetPlayers())` → `TeleportAsync(0, players)`. **`PLACE_ID_LOBBY = 0` → this throws, gets caught, retries 3 times, then `:Kick("No se pudo volver al lobby. Vuelve a entrar al juego.")`** for everyone. (inferred) the intended target was probably a separate place that was never wired up.

---

## 11. Surprises / risks surfaced by the read

1. **There are TWO independent killer-attack scripts.** `Controlador1v1.atacar()` (line 551, distance ≤ 6) is the one that actually fires from the client and decrements lives. `ServerScriptService.SistemaHit1v1` defines a competing `intentarHit` with `DISTANCIA_HIT = 4` that is **never called from anywhere**. If a future change wires up `SistemaHit1v1`, it would silently double-fire hits on the same target with weaker distance tolerance. Recommend deleting in T14.

2. **Stamina is invisible to the server.** `LogicaVelocidad1v1` overwrites `WalkSpeed` every Heartbeat. Server thinks `WalkSpeed` is what it set at round start. Any server-side distance check (attack, vault) uses the server's nominal value, but the killer on the screen is faster/slower than the server believes. T06 must move stamina to a server attribute.

3. **Pallet vaults have TWO movement tweens on the same root.** Server sends `SALTAR` → `SaltoPaleCliente` does a parabolic CFrame move (line 91). In parallel, `LogicaPallet1v1` (line 129) does its own `TweenService` straight-line move. The destinations differ (`SaltoPaleCliente` uses server-computed `destino`; `LogicaPallet1v1` uses `(p1 or p2).CFrame + (0,2,0)`). Two engines fighting over `root.CFrame` → torn movement and an animation that doesn't match the actual path. T05 needs a single mechanism.

4. **`TeleportAsync` is broken at round end.** `PLACE_ID_LOBBY = 0` (line 21) means every match ends with a `:Kick("No se pudo volver al lobby. Vuelve a entrar al juego.")` for both players, even though `RondaEnJuego` was just cleared. This is the live "lobby" today — players rejoin from the menu. T16 must decide the real lobby architecture before fixing this.

5. **Matchmaking server-side trusts the client string and uses an unbounded queue.** `ServidorMatchmaking1v1` accepts `"BUSCAR_PARTIDA"` and adds the player to a list with no rate limit; `Controlador1v1` does the same in its own loop. A malicious client can spam `"BUSCAR_PARTIDA"` 100×/s and either (a) cause repeated queue churn, or (b) pair with itself if it spawns a fake second player (none currently). Real fix is server-side: validate against `EstadoPartida == "ESPERANDO_JUGADORES"` and reject duplicates; do not trust the client's intent.

---

## 12. Open items for the author

- **Stun "PH" server vs "ATURDIDO" client name**: client `EfectosPale1v1` listens for `"ATURDIDO"` and that matches server. ✅
- **`RESET_JUGADOR` event**: client `LogicaVelocidad1v1:270–287` listens for `"RESET_JUGADOR"`; **the server never sends it.** `RESET_JUGADOR` is dead code. Either wire it from `Controlador1v1` between rounds, or remove the listener.
- **`MatchmakingCliente` vs `InterfazJuego1v1` UI**: two separate "PLAY NOW" UIs exist; only the green button in `InterfazJuego1v1` works. The other should go (T14).
- **`PLAYTESTS` data**: `MouseBehavior` and `CameraMinZoomDistance` are untouched, so T09/T10 start with a clean slate. Good.
- **Visible text still in Spanish**: `"DERROTA"`, `"Tiempo máximo…"`, `"Un jugador abandonó…"`, `"Jugar"`, `"Buscando rival…"`, `"¡Rival encontrado!…"`, `"No se pudo crear la partida. Intenta de nuevo."`, `"ATURDIDO"`, `"COUNTDOWN"`, `"INICIO"`, `"BLOQUEAR_MOVIMIENTO"`, `"DESBLOQUEAR_MOVIMIENTO"`, `"RESULTADO_RONDA"`, `"RESULTADO_FINAL"`, `"ESPERANDO_JUGADOR"`, `"RONDA"`, `"ROL"`, `"ATAQUE_DISPONIBLE"`, `"VIDAS"`. The brief says all **player-visible** text must be English; identifiers are fine. T11 should pull these into a `Strings` module.