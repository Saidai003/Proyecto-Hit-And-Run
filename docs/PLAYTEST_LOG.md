# PLAYTEST LOG

Registro de playtests manuales ejecutados por el autor.

---

## 2026-10-07 — BUG-01 (romper pale)

- **Autor:** Maximiliano Abascal
- **Modo:** 2 clientes (Test > Clients and Servers > 2 Players)
- **Resultado:** PARCIAL

| # | Caso | Resultado |
|---|---|---|
| 2 | Romper pulsando Espacio y manteniendo WASD | **PASS** — el perseguidor no se movió y el pale se rompió |
| 3 | Recuperación del movimiento tras la animación | PASS (implícito: no quedó clavado) |
| 5 | Desbloqueo al reiniciar ronda | No verificado |
| 6 | Muerte durante salto de pale → respawn | No verificado |

**Evidencia:** el autor confirma textualmente que «intentó moverse durante la
animación y no pudo moverse como resultado de los cambios». Ese es el bug
reportado y queda corregido.

**Pendiente:** los casos 5 y 6 son redes de seguridad añadidas durante el
arreglo, no functionality preexistente. El autor no los probó porque el
procedimiento era demasiado tedioso para montarlos. Protocolo reducido a una sola
pregunta: *¿algún jugador quedó pegado sin poder moverse?*

**Nota:** el autor creyó que el rango de aturdimiento había cambiado en este
playtest. No lo había: `LARGO_ZONA_ATURDIMIENTO` seguía en 5. El cambio se
aplicó después, como BUG-02.