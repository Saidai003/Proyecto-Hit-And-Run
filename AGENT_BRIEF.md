# Agent Brief: Stabilize the Roblox 1v1 Chase Game (TDD)

You are working on a Roblox game (Dead-by-Daylight-style 1v1: one PERSEGUIDOR/killer, one PERSEGUIDO/survivor, pallets, windows, a throwable chair, stamina/sprint). The game is in alpha. The author does not read code; he reads **test results and CHANGES.md**. Your job is to make behavior correct and *prove* it with tests.

This brief was written by another AI that only saw a subset of the code. Anything marked **UNKNOWN** or **HYPOTHESIS** must be verified by you before acting on it. If something you need is missing, say so. Do not invent code that fits scripts you have not read.

---

## 0. Ground rules

1. **Read before you edit.** First action: dump the full Explorer tree (services, scripts, RemoteEvents, attributes) and write `docs/ARCHITECTURE.md` describing what each script does and who talks to whom.
2. **Red, green, refactor.** For every task: write a failing test, see it fail for the right reason, make the smallest change that passes, then clean up. Never mark a task done without a test or a recorded playtest that exercised it.
3. **One task at a time.** One commit/checkpoint per task. Do not bundle.
4. **Server is the authority.** Hits, vaults, stamina costs, cooldowns, roles, collision state and knockouts are decided on the server. The client only shows effects and sends *requests*.
5. **Never trust client arguments.** Validate type, range, distance, role, state and cooldown for every RemoteEvent handler.
6. **All player-visible text must be English.** Existing scripts mix Spanish and English. Spanish identifiers in code are fine; Spanish strings shown to players are bugs.
7. **Do not make design decisions** listed in section 6. Ask or leave a clearly named constant.
8. **If a script is too large to read at once, read it in chunks and confirm you reached the end.** Pasted scripts were truncated several times in the past (the cause was truncated pasting, not the logic).

## 1. Project facts

### Scripts known to exist (from Output logs)
| Script | Side | Notes |
|---|---|---|
| `Controlador1v1` | Server | Matchmaking and round flow. Prints `[MATCHMAKING]`. 400+ lines. **UNKNOWN contents.** |
| `SistemaPale1v1` | Server | Pallet registry/logic (prints `[PALE REGISTRADO]` at line ~1428, so it is very long). **UNKNOWN contents.** Probably owns pallet state, stun, windows. |
| `InterfazJuego1v1` | Client | UI, 555+ lines. **UNKNOWN contents.** Role text, round text. |
| `LogicaVelocidad1v1` | Client | Sprint on/off. Probably holds stamina. **UNKNOWN.** |
| `LogicaPale1v1` | Client | Reviewed. Handles the Space key: drop pallet, vault pallet, break pallet. |
| `SaltoPaleCliente` | Client | Reviewed. Handles server `"SALTAR"` event with a parabolic CFrame jump. |
| `EfectosPale` | Client | Reviewed. Plays the stun animation when server sends `"ATURDIDO"`. |
| `ThrowChairCliente` | Client (StarterPlayerScripts) | Chair aiming/camera/trajectory. Works. |
| Chair server script (`ThrowChairServer` or `ServerThrow`, in ServerScriptService) | Server | Throw + hit detection + knockout. Works. |
| `Workspace.ROCK.Script` | Server | Obsolete, waits for a `ThrowEvent` that does not exist. Delete. |

### Known RemoteEvents
- `ReplicatedStorage.EventoPale1v1` (client and server; actions seen: `"INTERACTUAR"` client->server, `"SALTAR"` and `"ATURDIDO"` server->client).
- `ReplicatedStorage.ThrowChairEvent` (created by the chair server script if missing). Client sends an aim direction `Vector3`.

### Known attributes
- `Player:GetAttribute("Rol")` is `"PERSEGUIDO"` or `"PERSEGUIDOR"`.
- Pallet folder (`Pallet_01`..`Pallet_04`): attributes `EstadoPale` (`"Parado"` / `"Caido"`), `Rompiendo` (bool). Children: `PuntoPale_1`, `PuntoPale_2`, `BloqueoPale` (invisible collision wall).
- `Humanoid:GetAttribute("Inmovilizado")` blocks actions.
- Chair `Tool`: attribute `Throwable = true` (required), `Throwing` (set temporarily by the server). Needs a part named `Handle`.
- Character attribute `KnockedOut`.

### Chair system summary
Client holds MouseButton1 to aim (FOV, camera offset, raised arms, neon parabola), releases to send direction. Server validates (Tool equipped, has `Throwable`, humanoid alive, direction is a finite Vector3 with magnitude >= 0.5), moves the Tool to Workspace, breaks joints, sets velocity (also a short `BodyVelocity`), sets `CanTouch=false` for `PICKUP_DELAY` so it doesn't re-attach to the thrower. Hit detection uses `GetPartBoundsInBox` each Heartbeat (not `Touched`, because `CanTouch=false` disables it), using the previous frame's velocity. On hit: `knockOut()` sets `PlatformStand`, server takes network ownership, applies impulse, adds `NoCollisionConstraint` between the chair and the victim, and on wake-up zeroes velocity, straightens the character and applies `KNOCK_IMMUNITY`.
Constants that must match client and server: `THROW_VELOCITY`, `START_FORWARD`, `START_UP`. Consider moving them into a shared `ModuleScript` in ReplicatedStorage.

## 2. Findings from code already reviewed

These come from reading `LogicaPale1v1`, `SaltoPaleCliente` and `EfectosPale`. Verify each one.

- **F1. `SaltoPaleCliente` has leftover test code.** Its first 13 lines are `ThrowChairClient` debug code (`print`, `WaitForChild("ThrowChairEvent", 10)` and a `return` on failure). If that event is missing, the whole vault script silently never connects. Remove all of it. This also explains the `[ThrowChairClient]` prints that show `SaltoPaleCliente` as source.
- **F2. Two possible vault implementations that may fight.** `LogicaPale1v1` moves the root client-side with a `TweenService` tween to `PuntoPale_x + (0,2,0)`. `SaltoPaleCliente` moves the root with a parabolic CFrame when the server sends `"SALTAR"`. **UNKNOWN which is used for which action** (pallet vs window). If both run for the same action, the character is moved twice. Decide on a single mechanism.
- **F3. `BloqueoPale.CanCollide` is changed from a LocalScript.** Changes made on the client do not replicate to the server or other clients. Probable cause of "the invisible wall doesn't block when the pallet is down" (HYPOTHESIS): the server's value, or the other player's client, never gets updated. The collision state must be set by the server, driven by `EstadoPale`. The client then must not toggle it. For the vaulting player to pass through, use `NoCollisionConstraint` or a collision group on the server for that player's character, or let the vault move ignore the wall.
- **F4. The client decides vault speed and whether actions are allowed.** `esRapido = humanoid.WalkSpeed > 12`, state read from attributes, debounce on the client. The server must validate distance to the pallet, role, pallet state, cooldown and stamina, and be the one that tells the client to animate.
- **F5. Performance and input.** `obtenerPaleCercano` iterates `Workspace:GetDescendants()` on every Space press. Use `CollectionService` tags or a cached list. Space is also the Roblox jump key, so the character may jump while interacting. Use `ContextActionService:BindActionAtPriority` and sink the input when an interaction applies. Handlers use `task.wait` inside the input callback; prefer a state machine or `task.spawn`.
- **F6. Fall after vault looks wrong.** `SaltoPaleCliente` sets `root.CFrame` every frame with zero velocity while the Humanoid is in its normal state. At `a >= 1` it only unbinds and re-enables `AutoRotate`. HYPOTHESIS: the character lands at the destination, but the animation track keeps playing, so the fall is not visible. Desired behavior: during the vault the Humanoid does not fight the movement, the track is stopped on arrival, and after arrival the Humanoid enters `Freefall` so gravity and the fall animation are visible. The destination must be at the height of the obstacle edge, not the ground below it. Do **not** use `Anchored` from the client. A sketch that was suggested: `Humanoid:ChangeState(Enum.HumanoidStateType.Physics)` during the move, then `Freefall` at the end, optionally with a small forward velocity.
- **F7. `EfectosPale` only handles `Player` targets.** `objetivo.Character` is used, so NPC dummies cannot be stunned or animated. Fine for now, but tests with dummies will not work for stun animation.
- **F8. Stun is probably animation plus the `Inmovilizado` attribute.** The server code that sets it and defines the stun range is in `SistemaPale1v1` (**UNKNOWN**).
- **F9. No lobby.** There is no separate lobby place; matchmaking is disabled. Players are not teleported anywhere. See T16.

## 3. TDD approach for Roblox

Roblox code is hard to test if the logic is welded to engine objects. Use this split:

1. **Pure logic in ModuleScripts** (no `game:GetService` at top level when avoidable, no Instances in the core functions). Candidates:
   - `HitMath`: given attacker CFrame, victim position, range, angle, returns hit or not.
   - `StaminaModel`: drain, regen, cost of an action, speed multiplier given stamina.
   - `PalletStateMachine`: `Parado -> Caido -> Roto`, who may do what, collision flag per state.
   - `VaultRules`: validates distance, role, state, cooldown, stamina; returns allowed or a reason.
   - `KnockoutRules`: duration, immunity, can-be-knocked.
   - `Strings`: all player-visible English text, keyed.
   - `RoundState`: the state that a client needs when it joins mid-round (role, round number, phase).
2. **Thin scripts** that call those modules and do the Instance work.
3. **Three test layers:**
   - *Unit tests* for the pure modules, run fast, outside Studio if possible.
   - *Integration tests* inside Studio on the server using fake characters/pallets built by the test (spawn a rig, a pallet folder with the expected children, call the handler, assert attributes and collisions).
   - *Playtest scripts* (manual or Computer Use) with two clients for anything involving real input, camera or replication. Record results in `docs/PLAYTEST_LOG.md` with date, task ID, steps, pass or fail.

**Suggested tooling (verify current availability and status; choose what fits):**
- Rojo for syncing the project to the filesystem, so code lives in git and is editable by agents.
- Jest-Lua (or TestEZ if already present) for tests running in Studio or via a runner.
- Lune or the Luau CLI to run pure-Luau unit tests outside Studio.
- StyLua and Selene for formatting and linting.
- Roblox Studio MCP server if available, or Computer Use on Studio, for playtests with *Test > Clients and Servers > 2 Players*.
- Test-only code must never ship: keep tests in a `Tests` folder (ServerStorage) and exclude from the published place.

If Rojo migration is too heavy for the first pass, begin by writing the pure modules and unit tests, then migrate. Do not block bug fixes on tooling, but **do not skip tests**.

## 4. Task backlog

Each task: write the listed tests **first**. IDs are referenced in `CHANGES.md`.

### Priority A: game-breaking bugs

**T01. Pallet blocker collision when fallen** (F3)
- Given a pallet in state `Caido`, the server sets `BloqueoPale.CanCollide = true`. In `Parado` it is `false` (or as the design requires). It resets on round restart.
- Tests: unit for `PalletStateMachine` collision flag per state. Integration: drop pallet, assert `BloqueoPale.CanCollide` on the server. Playtest with 2 clients: killer cannot walk through a fallen pallet, including in round 2.
- Remove client-side writes to `BloqueoPale.CanCollide`.
- Find out first: which script currently sets it, and in what order the writes happen.

**T02. Pallet stun range too small**
- Increase the stun hitbox and keep it server-validated with `GetPartBoundsInBox` or distance plus angle, never `Touched`.
- Tests: unit for range math (hit at distance D, miss at D+epsilon, behind the pallet side excluded if design requires). Integration with fake rigs. Playtest: killer slightly outside the old range now gets stunned.
- Need: find the current stun range and where it is applied. Expose it as one named constant (`STUN_RANGE`).

**T03. Killer attack range too short**
- Ampliar la hitbox delante del asesino. The server computes hits from its own view of positions (allow a small lag compensation tolerance), with a maximum distance check.
- Tests: unit for `HitMath` (within range hits, outside misses, cone angle). Integration: fake killer and survivor at distances 3, 5, 7 studs. Playtest: if the swing visually connects, damage applies.
- Need: find the attack script (probably in `Controlador1v1` or a script not yet identified).

**T04. Role and text missing on the first round** (HYPOTHESIS: race condition)
- The client must send "ready" when `InterfazJuego1v1` is loaded, and the server must respond with the **current** state (role, round, phase, text). Do not rely on a one-time broadcast.
- Tests: unit for `RoundState` snapshot. Integration: simulate a late-joining client and assert it receives the snapshot. Playtest: join fresh, role is visible from round 1.
- Also verify `Player:GetAttribute("Rol")` is set before any client script reads it, or the client uses `GetAttributeChangedSignal`.

**T05. Vault fall and movement** (F2, F6)
- Single vault mechanism. Server validates and orders the vault; client animates. Stop the animation track on arrival; then Freefall.
- Tests: unit for vault duration/destination math (destination height equals edge height). Playtest: vault onto a lower floor and watch the fall happen *after* the animation, not a teleport. Test also on flat ground.

### Priority B: balance and gameplay

**T06. Stamina cost for vaults (windows and pallets)**
- Each vault consumes stamina. With insufficient stamina: slower vault or not allowed (see decisions in section 6). Server validates cost and cooldown. No infinite window loops.
- Tests: unit for `StaminaModel` (cost, regen, floor at zero, speed multiplier). Integration: chain vaults until the server refuses. Playtest.
- Need: where stamina currently lives (`LogicaVelocidad1v1`, probably client-side). If stamina is client-only, move the authoritative value to the server (attribute on the player) and let the client display it.

**T07. Chair too strong**
- Lower `KNOCKOUT_TIME` (suggested 1.5 to 2 s). Add a cooldown, or one use per round (decision). Decide whether the killer can use it at all (decision). Validate role on the server.
- Tests: unit for `KnockoutRules`. Integration: second throw within cooldown is rejected.

**T08. Double knockout residue**
- The `[KNOCKOUT]` print should fire once per hit. Verify. If it still happens, inspect the post-wake state (posture, velocity, `GettingUp` state). Add a test that triggers one hit and counts calls.

**T09. Fixed camera distance in matches**
- Min zoom = max zoom (suggested 12, tune). Applies only in match, not in menus if there are any. Make sure `ThrowChairCliente` aim zoom does not overwrite it permanently (it saves and restores).

**T10. Camera without holding right mouse button**
- Investigate `MouseBehavior.LockCenter` and what it breaks (cursor for UI, aiming). Do **not** implement before the decision about the right-click action (section 6).

### Priority C: polish and cleanup

**T11. All visible text in English.** Create `Strings` module, replace every hardcoded Spanish string in client UI, billboard text, notifications and prints that players can see. Test: a script scans `StarterGui` and the UI scripts for Spanish keywords and non-ASCII accents and fails if found in visible strings.

**T12. Aim camera pushed forward when looking up** (camera occlusion). Options: raise pivot with `Humanoid.CameraOffset` Y only, shorter distance, or accept. Low priority.

**T13. Chair "hangs" for a moment in mid-air after throw.** Network ownership handoff. Try assigning velocity before releasing ownership, or briefly let the thrower own it. Security trade-off: client ownership is more exposable. Low priority.

**T14. Cleanup.**
- Remove the leftover debug code in `SaltoPaleCliente` (F1).
- Remove the `[DEBUG]` input print block in `ThrowChairCliente`.
- Delete `Workspace.ROCK.Script`.
- Make sure there is exactly one server script listening to `ThrowChairEvent`.
- Remove duplicate `local ReplicatedStorage` declarations.

**T15. Performance.** Replace `Workspace:GetDescendants()` scans with tags (F5).

**T16. Lobby and teleport architecture (design first, do not implement without approval).**
- Today: single place, matchmaking disabled. Proposed target: a lobby place that queues players and uses `TeleportService` to send them to reserved match servers, plus `MessagingService` or teleport data for round setup.
- Deliverable for now: a one-page design in `docs/LOBBY_DESIGN.md` listing what in `Controlador1v1` depends on the queue, what a single-place alpha needs, and the minimum steps to separate them. No code.

## 5. Definition of done (per task)

- Tests written first, fail, then pass. Test names reference the task ID.
- Playtested with 2 clients for anything touching input, camera, animation or replication; result logged.
- No new `Infinite yield` warnings or errors in Output.
- A line added to `CHANGES.md`: what changed, which scripts, **which server-side validations exist** (this list is what the human reviews).
- No regressions on previous tasks: re-run the full suite.

### `CHANGES.md` format
```
## T0X Title
- Changed: scripts and constants
- Server validations: (e.g. role, distance <= N, cooldown, stamina, pallet state)
- Client trusts: nothing / list
- Tests: file names and results
- Playtest: date and result
- Open questions:
```

## 6. Decisions the agent must NOT make (ask the author or leave a named constant)

- What the right mouse button does (throw objects?), and whether the camera locks to the mouse.
- Stamina cost per vault and cooldown length; what happens at zero stamina (slower vs impossible).
- Chair: cooldown, once per round, who can use it.
- Hiding spots: leave as is until more playtests.
- Any gameplay number beyond what is already defined. Expose constants in one config module.

## 7. Information the agent must gather (UNKNOWN items)

1. Full contents of `Controlador1v1`, `SistemaPale1v1`, `InterfazJuego1v1`, `LogicaVelocidad1v1`: write their summaries into `docs/ARCHITECTURE.md`.
2. Which script defines the killer attack and its current hitbox.
3. Which script defines the pallet stun, its range, and sets `Inmovilizado`.
4. Where stamina lives and whether the server knows it.
5. Which vault mechanism is used for pallets and which for windows (F2), and which `EventoPale1v1` actions the server sends.
6. All RemoteEvents, who fires them, and whether each server handler validates its arguments.
7. Where the round starts and how roles are assigned (for T04).
8. Whether the map has other `Script`s that touch `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `MouseBehavior` or `Humanoid.WalkSpeed` (conflicts with T09, T10, T06).
9. Whether the project can be exported to Rojo format cleanly.

## 8. Suggested order of work

1. Architecture dump (section 7) and T14 cleanup.
2. Test infrastructure plus pure modules skeleton.
3. T01, T02, T03 (collision and ranges).
4. T04 (round start state).
5. T05 and T06 together (vault movement plus stamina).
6. T07 to T10.
7. T11, then T12, T13, T15.
8. T16 design document.

At the end, deliver: passing test suite, `CHANGES.md`, `docs/ARCHITECTURE.md`, `docs/PLAYTEST_LOG.md`, and a list of open questions for the author.
