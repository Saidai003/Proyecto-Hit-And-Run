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

---

## 2026-10-11 — ronda de estabilización MVP

- **Autor:** usuario, prueba en Studio tras conectar Rojo.
- **Confirmado:** el bate aparece; el HUD muestra stamina; parkour con poca
  stamina se ejecuta más lento.
- **Fallos observados:** stamina comienza a recuperarse al llegar a cero con
  Shift aún presionado; bate desplazado a la derecha; marcadores de parkour
  pueden activar una ventana equivocada o no activarse; HUD tapa el chat y el
  lobby tiene textos poco legibles.
- **Corrección preparada, pendiente de repetir playtest:** bloqueo de
  recuperación hasta soltar Shift y breve pausa de agotamiento; bate geométrico
  vertical agarrado por el extremo inferior; emparejamiento recíproco y cercano
  de marcadores; HUD agrupado abajo a la izquierda y lobby de mayor contraste.
- **Prueba automática local:** 22 marcadores del último respaldo tienen pares
  recíprocos; `rojo build` pasa. Esto no valida los marcadores que se hayan
  añadido después en Studio ni sustituye el playtest.
