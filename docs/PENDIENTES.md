# Pendientes de juego

Registrados a partir de los últimos playtests del usuario. Los ajustes de código indicados abajo están preparados en Rojo; **falta verificar el comportamiento en Studio y publicado antes de darlos por cerrados**.

## Escalada

- **Preparado, por probar:** conservar el estado en subidas largas y entre piezas contiguas; comprobar `Drop Off` / `NoEscalando` al soltar o llegar al extremo.
- **Preparado, por probar:** aceptar `TrussPart` y piezas `BasePart` marcadas con el atributo booleano o etiqueta `Escalable`. Una pieza normal marcada debe tener geometría de escalera que el Humanoid realmente pueda subir; la marca no transforma una pared lisa en escalera.
- **Preparado, por probar:** cobrar 5 puntos de stamina por stud vertical recorrido al subir o bajar, sin tarifa inicial; a cero, soltar la escalada. Comprobar que no se cobre por caídas ajenas a la escalada.

## Salto experimental con ALT

- **Preparado, por probar:** reducir `JumpPower` experimental de 50 a 40; comprobar en los muros del mapa si basta para preservar los recorridos de persecución.
- La tecla definitiva de salto sigue siendo una decisión de diseño abierta; ALT continúa siendo solo una prueba.

## Donación y pantalla de compra

- **Explicación probable, pendiente de confirmar con la cuenta del usuario:** el producto `Donation` aparece con precio regional de **75 Robux** frente al precio base de 100, y, con saldo de **0 Robux**, Roblox ofrece comprar un paquete de **500 Robux**. El **400 Robux tachado** parece corresponder a la oferta del paquete, no al precio del producto; la captura no basta para confirmarlo.
- Verificar en Creator Dashboard el precio regional del Developer Product `3717856374` y confirmar que el botón del lobby muestra 75 Robux para esa cuenta. La UI consulta `GetProductInfoAsync`; no tiene codificados 75, 500 ni 400.
- **Preparado, por probar:** mostrar una confirmación propia antes del aviso nativo que distingue el precio de la donación del paquete de Robux y aclara que no hay recompensa. El juego no puede modificar el diseño ni los paquetes de Robux del aviso de Roblox. No se cambió el precio ni se iniciaron compras.

## Interfaz «How to Play»

- **Preparado, por probar:** sustituir el bloque de texto cortado por tarjetas visuales desplazables y mantener `GOT IT!` fuera de la zona de contenido. La tarjeta de `ALT` explica el salto experimental.
- Verificar la presentación en distintas resoluciones y escalas de pantalla, con el panel del lobby abierto.

## Verificación

- Probar estos cambios en el lobby y en partida, en R15, con subida y bajada largas, salida manual con Space, llegada natural al extremo y stamina baja o agotada.
- Confirmar que las acciones de parkour existentes y el indicador contextual no presentan regresiones.
