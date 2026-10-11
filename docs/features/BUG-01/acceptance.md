# BUG-01 — Checklist observable

Estado: `- [~]` implementado, pendiente del playtest del autor con 2 clientes.

## Qué cambió

- `ServerScriptService/SistemaPale1v1`
  - Nuevo handle `EventoJuego` (el script solo tenía `EventoPale`).
  - `inmovilizar(jugador, humanoide, duracion)` ahora emite `BLOQUEAR_MOVIMIENTO`
    al entrar y `DESBLOQUEAR_MOVIMIENTO` al salir.
  - Los 4 call sites pasan el jugador: soltarPale, stun, romperPale, saltarPale.
  - `liberarTodos()` difunde `DESBLOQUEAR_MOVIMIENTO` a todos los clientes.
- `StarterPlayer/StarterPlayerScripts/LogicaVelocidad1v1`
  - `CharacterAdded` pone `movimientoBloqueado = false`.

## Validaciones del servidor (sin cambios)

- El servidor sigue siendo la autoridad: valida rol, distancia y estado del pale
  antes de llamar a `romperPale`. El cliente solo pide `INTERACTUAR`.
- El cliente no envía nada nuevo. No se amplió ninguna superficie de confianza.

## Qué confía el cliente

- Que el Heartbeat deje de escribir `WalkSpeed` mientras `movimientoBloqueado`.
  Ese flag lo fija y lo limpia el servidor mediante `EventoJuego`.

## Observables

- [ ] El perseguidor no se mueve durante los 2.0 s de romper, aunque pulse WASD.
- [ ] El pale se rompe igual (`EstadoPale == "Roto"`, `InvisibleWall.CanCollide == false`).
- [ ] Al terminar la animación el perseguidor recupera su velocidad normal.
- [ ] El stun por caída de pale también inmoviliza al perseguidor.
- [ ] Al terminar la ronda nadie queda bloqueado (ningún jugador se queda quieto
      en el siguiente round).
- [ ] Si el perseguido muere durante un salto de pale, al reaparecer puede moverse.

## Nota sobre el atributo

`Inmovilizado` se mantiene porque `Controlador1v1.atacar` lo consulta para impedir
que un perseguidor aturdido golpee. El atributo solo ya no basta para detener el
movimiento, por eso el bloqueo real pasa ahora por el evento.