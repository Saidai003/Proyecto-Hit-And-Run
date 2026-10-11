# BUG-02 — Cómo verificarlo

Test > Clients and Servers > 2 Players.

## La prueba

1. Que el perseguido suelte un pale **con el perseguidor a 6-8 studs**, sin
   estar encima.
2. Observar si el perseguidor se queda clavado unos 2 segundos.

Esperado: **se queda clavado**. Antes soltaba el impacto a menos que estuviera
literalmente pegado al pale.

## La prueba importante (el caso nuevo)

Repite lo mismo, pero haz que el perseguidor se acerque **desde el lado
contrario** a hacia el que cayó el pale.

Esperado: **también se queda clavado**. Antes esto nunca funcionaba,
independientemente de la distancia, porque la zona solo cubría un lado de la
bisagra.

Ese es el cambio de verdad de este ítem. Si solo pruebas el primer caso y
funciona, no confirma el arreglo.

## Si no se aturde

Fíjate en dos cosas y dime cuáles son:

- ¿A cuántos studs estaba el perseguidor cuando el perseguido soltó el pale?
- ¿El pale cayó **hacia** el perseguidor o **hacia el perseguido**?

Con eso se sabe si es distancia o lado.