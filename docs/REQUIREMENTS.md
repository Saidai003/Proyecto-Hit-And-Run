# REQUIREMENTS

Ordered from most to least important. Each entry: checkbox, ID, title, priority (A game-breaking, B balance, C polish), one-line reason, acceptance criteria (observable behavior), how to verify, evidence.

Legend:
- `- [ ]` pending
- `- [~]` implemented, waiting for the author's manual playtest (2-client items)
- `- [x]` done — evidence written below

---

## Priority A — game-breaking bugs

These make the current build not match its own design. Fix in this order.

- [~] **T01** — Pallet InvisibleWall blocks the killer only when the pallet is `Caido`; client never writes `CanCollide`; round restart resets state.
  - **Priority:** A — a killer walking through a "down" pallet breaks the core chase dynamic.
  - **Root cause found 2026-10-07:** the `InvisibleWall` rotated the same `ANGULO_CAIDA` (50°) as the pallet body inside `aplicarRotacion`, leaving it tilted with open ground underneath on one side. Fixed by making the wall static — it now keeps its authored CFrame and never rotates. Fall direction untouched. Client-side `BloqueoPale` writes remain dead code (real child is `InvisibleWall`) and are tracked under T14 / Dual-vault conflict.
  - **Acceptance:** a killer walking into a fallen pallet is blocked from both sides; the wall stays vertical and never rotates with the pallet.
  - **Verify:** 2-client playtest — survivor drops a pallet, both players try to walk through it; neither gets past. Confirm the vault still passes through normally.
  - **Evidence:** (pending playtest)

- [~] **BUG-01** — Action lock survives the break-pallet animation (was breaking silently when the chaser moved). **Core bug confirmed fixed by the author's playtest 2026-10-07.** The two added safety nets (round-reset unlock, respawn-after-death) remain unverified. See `docs/features/BUG-01/` and `docs/CHANGES.md`.
  - **Verification:** just play a couple of rounds. The only question is whether any player ever gets stuck unable to move. If never, mark done.
  - **Evidence:** `docs/PLAYTEST_LOG.md` — 2026-10-07, 2 clients, chaser did not move while holding WASD during the break animation.

- [~] **T02 / BUG-02** — Pallet stun zone is server-validated, exposed as named constants, and reachable from both sides of the hinge.
  - **Priority:** A — the zone was only 5.5 studs deep, but 9 wide, and biased to a single side of the hinge (`a >= -0.5`). A killer approaching from the far side could never be stunned at any distance, which is the reported symptom.
  - **Acceptance:** A killer within `STUN_RANGE` (7) studs ahead of the hinge, or within `STUN_RANGE_BEHIND` (3) studs behind it, and within `ancho/2 + MARGEN_LATERAL_ZONA` laterally and ±6 vertically, gets `Inmovilizado = true` for `DURACION_ATURDIMIENTO` and `ATURDIDO` fires exactly once per drop. Both bounds are named constants.
  - **Verify:** 2-client playtest — killer at 6-8 studs gets stunned; repeat approaching from the side *opposite* to where the pallet fell (this case never worked before and is the real fix). Recorded in `docs/features/BUG-02/`.
  - **Evidence:** (pending playtest)

- [ ] **T03** — Killer attack range is one named `ATTACK_RANGE` constant, server-validated from server-side positions with no `Touched`-based detection.
  - **Priority:** A — current `DISTANCIA_ATAQUE = 6` is shorter than the swing animation visually suggests, so swings that look like hits do nothing.
  - **Acceptance:** When the killer's lunge ends and `|hrpKiller - hrpSurvivor| <= ATTACK_RANGE`, the survivor loses 1 life, sees the hit reaction (sparks, red flash, camera shake), and `EventoHit1v1:FireAllClients("HIT", killer, survivor, lives)` fires exactly once per swing. Swings where the survivor is further than `ATTACK_RANGE` deal no damage. `ATTACK_RANGE` is one named constant.
  - **Verify:** unit for `HitMath` (within range hits, outside misses). Integration: spawn killer + survivor at distances 3, 5, 7 studs and trigger the server handler. 2-client playtest: swings that visually connect deal damage; ones that don't, don't.
  - **Evidence:** (empty)

- [ ] **T04** — Role (`KILLER`/`RUNNER`), round number and lives are visible from round 1 for every player, including late-joiners and respawners.
  - **Priority:** A — without role, the survivor's and killer's UI shows the same neutral state on the first round, so the player has no idea what to do.
  - **Acceptance:** A player joining mid-match, or respawning, sees their role label, round number and (if runner) lives counter within one render frame of being in a character. `Player:GetAttribute("Rol")` is set before any client reads it, or the client uses `GetAttributeChangedSignal`.
  - **Verify:** unit for `RoundState` snapshot. Integration: simulate a late-joining client and assert it receives the snapshot. 2-client playtest: join fresh, role visible from round 1.
  - **Evidence:** (empty)

- [ ] **T05** — Single pallet-vault mechanism; server is the authority for destination and timing; client animates; animation track stops on arrival; Humanoid enters Freefall.
  - **Priority:** A — two movement engines fighting on the runner's root produces torn movement and a vault that doesn't match the obstacle.
  - **Acceptance:** During a vault, `root.CFrame` is touched by exactly one engine (server-driven parabola). The destination equals the obstacle edge height, not the ground below. On arrival the vault animation track stops; the Humanoid enters `Freefall` so gravity and the fall animation are visible. A destination higher than the current root position is supported (e.g. for a true window).
  - **Verify:** unit for vault destination math (destination height equals edge height). Playtest (2-client): vault onto a lower floor and watch the fall happen *after* the animation, not a teleport. Same test on flat ground.
  - **Evidence:** (empty)

- [ ] **Dual-vault conflict** — While T05 is being designed, this separate entry exists because the bug has two concrete causes: (a) `LogicaPallet1v1` line 121–138 runs a client-side straight `TweenService` tween to `(p1 or p2).CFrame + (0,2,0)` while `SaltoPaleCliente` runs the server-driven parabolic move from `EventoPale1v1("SALTAR", destino, duracion, altura)`. (b) `LogicaPallet1v1` line 126–127 and line 137 set `BloqueoPale.CanCollide` from the client (no such child exists; current name is `InvisibleWall`, so the writes silently target nothing).
  - **Priority:** A — same severity as T05 but tracked independently so the dual-tween removal is its own checkbox.
  - **Acceptance:** The straight client tween in `LogicaPallet1v1` for vaulting is removed or made server-driven. The client writes to `InvisibleWall.CanCollide` are removed (server is the only writer). The leftover `BloqueoPale` references in the code are deleted.
  - **Verify:** integration test asserts `root.CFrame` is touched by exactly one engine during a pallet-vault. `script_grep` for `CanCollide` finds zero writes from `LogicaPallet1v1`.
  - **Evidence:** (empty)

- [ ] **T17** — `Controlador1v1.volverAlLobby` must not silently Kick everyone when no lobby place is wired up.
  - **Priority:** A — verified by the author against the codebase backup: `Controlador1v1` line 21 sets `PLACE_ID_LOBBY = 0`; `volverAlLobby` at line 148 returns `false` while `RunService:IsStudio()`, so Studio playtests hide the bug; in a published server it calls `TeleportAsync(0, players)`, fails, retries 3 times, then `:Kick("No se pudo volver al lobby. Vuelve a entrar al juego.")` every player at line 183. Today's author playtest (yesterday) was in Studio so the Kick never fired, but the next review of this code on a live server will hit it. **Do not change** until the author decides how the end of a match should behave (lobby teleport, soft-return-to-menu, leave-in-place, etc.).
  - **Acceptance:** After end-of-match, players end up in the documented target state with no `:Kick` from `volverAlLobby`. The exact target state is the author's call (see *Needs author decision → End-of-match behavior*).
  - **Verify:** in a published server (or via a temporary stand-in place whose id is valid), end a match and confirm no `Kick` fires and players arrive at the expected place. Until the author decides, mark as "verify-only" and run the end-of-match path on the existing place with a stand-in place id to see the failure mode.
  - **Evidence:** (empty)

---

## Priority B — balance and gameplay

Items that need the author's design decisions are listed here **only when the technical work is unblocked**. Anything still waiting on the author is in the *Needs author decision* section.

- [ ] **T06** — Vaults (windows and pallets) consume stamina; server validates cost and cooldown; no infinite window loops.
  - **Priority:** B — without stamina, the runner escapes for free; chase dynamic collapses.
  - **Acceptance:** Every vault decrements stamina by the configured cost. With insufficient stamina, the vault is rejected by the server (or accepted with a slower speed, per author). A server-side cooldown (`COOLDOWN_VAULT`) prevents chain-vaulting within `COOLDOWN_VAULT` seconds. Stamina is a server-owned attribute on the Player.
  - **Verify:** unit for `StaminaModel` (cost, regen, floor at zero, speed multiplier). Integration: chain vaults until the server refuses. 2-client playtest.
  - **Evidence:** (empty)

- [ ] **T07** — Chair is not overpowered; one `KnockoutRules` module owns duration, immunity and per-round limits; server validates role and tool attributes.
  - **Priority:** B — current `KNOCKOUT_TIME = 3` plus infinite-throw is unbalanced.
  - **Acceptance:** `KNOCKOUT_TIME` is reduced (suggested 1.5–2 s). A cooldown, or one use per round, applies (per author). Whether the killer can use it at all is decided by the author. Role + `Tool.Throwable` validated on the server. The `[KNOCKOUT]` server print fires exactly once per hit.
  - **Verify:** unit for `KnockoutRules`. Integration: second throw within cooldown rejected. 2-client playtest: one chair throw ≈ one short stun, not a chain.
  - **Evidence:** (empty)

- [ ] **T08** — Double-knockout residue: after `knockOut` returns, the victim's posture, velocity and `GettingUp` state are correct; `[KNOCKOUT]` prints once per hit.
  - **Priority:** B — sub-item of T07, kept separate for testability.
  - **Acceptance:** `[KNOCKOUT]` server log fires exactly once per chair hit. After wake-up the victim is upright, velocities are zero, and a follow-up hit within `KNOCK_IMMUNITY` is rejected.
  - **Verify:** integration test that triggers one hit and counts `[KNOCKOUT]` calls; second hit within immunity window is a no-op. 2-client playtest for visual confirmation.
  - **Evidence:** (empty)

- [ ] **T09** — Camera distance is fixed in matches; min zoom = max zoom = `CAMERA_DISTANCIA`; doesn't permanently overwrite `ThrowChairCliente` aim zoom.
  - **Priority:** B — wide zoom variance during a chase is disorienting.
  - **Acceptance:** During a round, `CameraMinZoomDistance == CameraMaxZoomDistance == CAMERA_DISTANCIA`. After a round, the original values are restored. `ThrowChairCliente` aim may temporarily change FOV but must save and restore the values, not leave them modified at the new value.
  - **Verify:** integration: assert `CameraMinZoomDistance == CameraMaxZoomDistance == CAMERA_DISTANCIA` for both players during match; assert they match the original values 1 s after the round ends.
  - **Evidence:** (empty)

---

## Priority C — polish and cleanup

- [ ] **T11** — All player-visible text is English. A `Strings` module in `ReplicatedStorage` owns every visible string.
  - **Priority:** C — current build mixes Spanish (`"DERROTA"`, `"Jugar"`, `"Tiempo máximo…"`, `"Un jugador abandonado"`, `"Buscando rival…"`, etc.) with English (`"PLAY NOW!"`, `"HOW TO PLAY"`, `"WAITING FOR OPPONENT…"`, role labels, etc.).
  - **Acceptance:** A scanner walks `StarterGui`, `StarterPlayerScripts`, and any billboard/notification instances; it flags every Spanish keyword and every non-ASCII Spanish character in a visible string; CI/script fails the build on a hit. Every `TextLabel`/`TextButton` text is sourced from the `Strings` module.
  - **Verify:** script scans `StarterGui` + `StarterPlayerScripts` for Spanish keywords and accents. Manual visual pass on the HUD.
  - **Evidence:** (empty)

- [ ] **T14** — Cleanup of leftover debug code, redundant server logic, and dead tool scripts.
  - **Priority:** C — without this, every later test reads noise, and `script_grep` becomes unreliable.
  - **Acceptance:** No `[ThrowChairClient]` print, no `[DEBUG]` block in `ThrowChairCliente`, no first-13-line leftover in `SaltoPaleCliente`, no duplicate `local ReplicatedStorage` declarations. Server-side hit validation has exactly one source. `script_grep` returns no matches for known-dead patterns.
  - **Sub-items:**
    - [ ] **T14a — Unused `ServerScriptService.SistemaHit1v1`** deletion. **Gated:** first run `script_grep` for `intentarHit` and `SistemaHit1v1` across all scripts to prove nothing in the codebase calls it; only then delete.
    - [ ] **T14b — `Workspace.ROCK` Tool deletion.** Script, LocalScript, RemoteFunction and `effects` folder are all orphaned (no `Throwable` attribute, no StarterPack distribution).
    - [ ] **T14c — `SaltoPaleCliente` lines 1–13** removal (the leftover ThrowChairClient code that `return`s if `ThrowChairEvent` is missing, breaking the pallet vault subscription).
    - [ ] **T14d — `[DEBUG]` input print block in `ThrowChairCliente`** removal (brief F1).
    - [ ] **T14e — Duplicate `local ReplicatedStorage` declarations** removal where two are declared in the same script.
  - **Stay (per author decision):** `MatchmakingCliente`, `ServidorMatchmaking1v1`, the `RESET_JUGADOR` listener in `LogicaVelocidad1v1`. The orphan UI in `MatchmakingCliente` is allowed to be set to `Enabled = false` so it doesn't visually intrude.
  - **Verify:** `script_grep` for the dead symbols returns zero hits in the place; output log has no `[ThrowChairClient]` / `[DEBUG]` prints during a 1-round solo playtest.
  - **Evidence:** (empty)

- [ ] **T12** — Aim camera doesn't push above walls when looking up. Options: raise pivot with `Humanoid.CameraOffset` Y only, shorter distance, or accept.
  - **Priority:** C — minor visual bug; doesn't break gameplay.
  - **Acceptance:** Camera position respects the chosen option (TBD by the author). `Humanoid.CameraOffset.Y` does not grow unboundedly during aim.
  - **Verify:** integration: `CameraOffset` stays within limits during a 5 s aim while looking up.
  - **Evidence:** (empty)

- [ ] **T13** — Chair does not pause mid-air after the throw (network-ownership handoff).
  - **Priority:** C — visible but doesn't break gameplay.
  - **Acceptance:** From release to hit/landing, the chair follows a continuous trajectory (no >0.1 s pause). Security trade-off documented: keeping the thrower as the network owner for the first 0.1 s is acceptable for this prototype.
  - **Verify:** 2-client playtest: record trajectory visually; no mid-air pause.
  - **Evidence:** (empty)

- [ ] **T15** — Performance: `Workspace:GetDescendants()` scans replaced with `CollectionService` tags (F5). Affected scripts: `LogicaPallet1v1.obtenerPaleCercano`, `LogicaParkour1v1.buscarPuntoMasCercano` and `obtenerPuntoOpuesto`.
  - **Priority:** C — only matters at scale; current map is small.
  - **Acceptance:** No `Workspace:GetDescendants()` calls in those three functions. New `CollectionService` tags: `Pallet` (or `PalletPoint`), `WindowPoint`, `NarrowedWalkPoint`. Pallet folder / punto parts are tagged in the place.
  - **Verify:** integration: under a profiler, the per-frame cost of those functions drops.
  - **Evidence:** (empty)

- [ ] **T10** — Camera looks around without holding right mouse button (mouse lock center). **BLOCKED on author decision: right-click action.**
  - **Priority:** C — UX nicety.
  - **Acceptance:** `MouseBehavior` is `LockCenter` or `Default` per author; cursor handling for the aim UI is not broken.
  - **Verify:** playtest: camera responds to mouse movement without RMB.
  - **Evidence:** (empty)
  - **Blocker:** see *Needs author decision → Right-click action*.

---

## Future / known limitations (design only — no code yet)

- [ ] **T16** — Lobby and match-server architecture (design only).
  - **Priority:** Future. Today's matchmaking works inside a single place. Teleporting the two matched players to their own dedicated match server (reserved server, teleport data, MessagingService, etc.) is not implemented.
  - **Acceptance:** One-page design in `docs/LOBBY_DESIGN.md` listing what in `Controlador1v1` depends on the queue, what a single-place alpha needs, and the minimum steps to separate them. **No code** in this task.
  - **Sub-items (no code yet):**
    - [ ] **T16a — `PLACE_ID_LOBBY` verification.** Yesterday's author playtest found that matchmaking, rounds and the final results screen all work end-to-end. The Kick in `Controlador1v1.volverAlLobby` (line 183) is therefore *unverified* in this codebase: find precisely when the Kick fires relative to the results screen, and whether it is reachable at all.
    - [ ] **T16b — Players beyond the 2 matched share the competition map.** When 3 or more players are in the server, the matched pair plays; the others stand on the same map while the match runs. This is a known limitation, not to be fixed in the prototype phase.

---

## Needs author decision (do not work on until decided)

Each row unblocks specific Priority A/B/C items when chosen.

| Decision | Unblocks |
|---|---|
| Right-click action (throw object, lock camera, do nothing) | T10 |
| Stamina cost per vault (pallet / window / 2 separate numbers) and vault cooldown length | T06 |
| What happens at zero stamina (slower, cannot finish, or stop sprinting only) | T06 |
| Chair rules: cooldown, once per round, who can use (runner / killer / both) | T07 |
| Hiding spots (lockers) — keep, remove, redesign | not listed above yet; track as design input |
| End-of-match behavior (lobby teleport, soft-return-to-menu, leave-in-place, etc.) | T17 |

---

## Studio edit target

For all Priority A/B/C items I will edit:

- **Studio instance name:** `Prototipo: Golpear y huir`
- **studio_id:** `7e2df06b-66dc-4c04-92d5-1031ad882f1c`
- **placeId:** `118890619753629`

I will not edit any other open Studio instance without you naming one. If a different one is your working copy, tell me before the first edit.