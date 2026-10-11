# BUG-02 / T02 — Zona de aturdimiento del pale

Estado: `- [~]` implementado, pendiente del playtest del autor con 2 clientes.

## Qué cambió

`ServerScriptService/SistemaPale1v1`

- `LARGO_ZONA_ATURDIMIENTO = 5` → dos constantes con nombre:
  - `STUN_RANGE = 7` — alcance hacia el lado al que cae el pale.
  - `STUN_RANGE_BEHIND = 3` — alcance hacia el lado contrario.
- `dentroDeZona` usa `a >= -STUN_RANGE_BEHIND and a <= STUN_RANGE`.

`MARGEN_LATERAL_ZONA = 1` y el límite vertical `±6` no cambian.

## Por qué el cambio era más que subir el número

La zona anterior era un rectángulo de 9 studs de ancho por 5.5 de fondo, y
**estaba sesgada a un solo lado**: el límite `a >= -0.5` exigía que el
perseguidor estuviera en el lado hacia el que cae el pale.

La dirección de caída la fija la geometría del pale, no la posición de los
jugadores. Un perseguidor que llegaba por el lado contrario quedaba excluido
sin importar la distancia, lo que explica el síntoma "solo funciona si el
perseguidor está pegado al pale".

Con `-3`, la zona abarca 10 studs a cada lado de la bisagra.

## Medidas reales del mapa

- Ancho del pale (`PuntoPale_1` → `PuntoPale_2`): 7.0 studs exactos.
- Margen lateral efectivo: `7/2 + 1` = 9 studs.
- Velocidad del perseguidor: 18 base / 24 sprint.
- Animación de caída antes de la comprobación: 0.3 s.

Un perseguidor a sprint recorre ~7.2 studs durante la caída. Con el rango
anterior de 5, quien estuviera a más de ~12 studs de la bisagra al soltar el
perseguido ya había salido de la zona.

## Observables

- [ ] El perseguido suelta el pale con el perseguidor a ~6-8 studs y el
      perseguidor **queda aturdido** (~2 s, sin moverse).
- [ ] El perseguidor tampoco puede atacar durante el aturdimiento.
- [ ] Al terminar el aturdimiento recupera la velocidad normal.
- [ ] Repetir desde el lado contrario de la bisagra: también aturde. Este es el
      caso que antes nunca funcionaba.

## Nota de diseño

`STUN_RANGE_BEHIND = 3` permite que un perseguidor a 3 studs por detrás de la
bisagra sea aturdido aunque no haya tocado el pale. Es un cambio de diseño
deliberado, aprobado por el autor, y el número está aislado en una constante
para poder ajustarlo sin tocar la lógica.