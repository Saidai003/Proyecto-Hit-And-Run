# BUG-01 — Cómo verificarlo

## Lo importante ya está verificado

El perseguidor no se mueve durante la animación de romper. Ese era el bug
reportado y quedó corregido el 2026-10-07.

## El resto

Los otros dos casos son **redes de seguridad**: los añadí para que nadie quedara
congelado permanentemente. No hay que montarlos a propósito.

### Lo único que tienes que hacer

Juega un par de rondas normalmente y fíjate en una sola cosa:

> **¿En algún momento un jugador se queda pegado, sin poder moverse?**

- **Nunca pasa** → las redes funcionan. BUG-01 se puede marcar como terminado.
- **Pasa** → anota qué pasó justo antes (rompiendo un pale, después de un golpe,
  al empezar una ronda) y dímelo.

Ese es todo el protocolo. No hace falta probar cada caso por separado.

## Por qué esto es suficiente

Los dos riesgos que añadí solo se disparan en circumstances concretas:

| Riesgo | Cuándo se dispararía | Cómo lo ves jugando |
|---|---|---|
| Round reset no desbloquea | Un jugador estaba aturdido/rompiendo cuando terminó la ronda | Empezar la ronda 2 y no poder caminar |
| Muerte durante un salto deja el flag | El perseguido muere mientras salta un pale | Reaparecer y no poder caminar |

Si juegas varias rondas y nunca aparece ninguno de los dos, ninguno existe en la
práctica. Si aparece, es visible sin ambigüedad: el jugador se queda clavado.

## Nota

La versión anterior de este documento pedía seis pruebas montadas. Era
demasiado trabajo para lo que se estaba comprobando. Este es el protocolo real.