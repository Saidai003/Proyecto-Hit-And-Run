# Pendientes de juego

Registrados a partir de los últimos playtests del usuario. Los ajustes de código indicados abajo están preparados en Rojo; **falta verificar el comportamiento en Studio y publicado antes de darlos por cerrados**.

## Escalada

- **Preparado, por probar:** conservar el estado en subidas largas y entre piezas contiguas; comprobar `Drop Off` / `NoEscalando` al soltar o llegar al extremo.
- **Preparado, por probar:** aceptar `TrussPart` y piezas `BasePart` marcadas con el atributo booleano o etiqueta `Escalable`. Una pieza normal marcada debe tener geometría de escalera que el Humanoid realmente pueda subir; la marca no transforma una pared lisa en escalera.
- **Preparado, por probar:** cobrar 5 puntos de stamina por stud vertical recorrido al subir o bajar, sin tarifa inicial; a cero, soltar la escalada. Comprobar que no se cobre por caídas ajenas a la escalada.

## Salto con Espacio

- **Preparado, por probar:** reducir `JumpPower` experimental de 50 a 40; comprobar en los muros del mapa si basta para preservar los recorridos de persecución.
- **Preparado, por probar:** Espacio pasa a ser la tecla del salto; ALT deja de saltar. Comprobar el gasto de stamina y que no se active parkour accidentalmente.

## Donación y pantalla de compra

- **Explicación probable, pendiente de confirmar con la cuenta del usuario:** el producto `Donation` aparece con precio regional de **75 Robux** frente al precio base de 100, y, con saldo de **0 Robux**, Roblox ofrece comprar un paquete de **500 Robux**. El **400 Robux tachado** parece corresponder a la oferta del paquete, no al precio del producto; la captura no basta para confirmarlo.
- Verificar en Creator Dashboard el precio regional del Developer Product `3717856374` y confirmar que el botón del lobby muestra 75 Robux para esa cuenta. La UI consulta `GetProductInfoAsync`; no tiene codificados 75, 500 ni 400.
- **Preparado, por probar:** mostrar una confirmación propia antes del aviso nativo que distingue el precio de la donación del paquete de Robux y aclara que no hay recompensa. El juego no puede modificar el diseño ni los paquetes de Robux del aviso de Roblox. No se cambió el precio ni se iniciaron compras.

## Interfaz «How to Play»

- **Preparado, por probar:** sustituir el bloque de texto cortado por tarjetas visuales desplazables y mantener `GOT IT!` fuera de la zona de contenido. Las tarjetas explican Espacio para saltar y clic derecho para parkour.
- **Preparado, por probar:** pestañas Runner y Chaser con explicación propia de objetivos, controles y seis rondas alternadas. Las tarjetas ajustan su altura al texto. Verificar que nada se corte al cambiar de pestaña o resolución.
- **Preparado, por probar:** el resultado final y el resaltado del marcador dan la victoria a quien acumuló **más** tiempo como Runner, según la regla confirmada por el usuario.
- Verificar la presentación en distintas resoluciones y escalas de pantalla, con el panel del lobby abierto.

## Nueva tanda de ajustes

- **Preparado, por probar:** reducir la altura del panel oscuro de stamina en el lobby, sin quitar información de las rondas.
- **Preparado, por probar:** ubicar el botón de donación fuera de la lista de jugadores y del indicador central de parkour: abajo a la derecha en pantallas anchas y arriba a la izquierda en pantallas estrechas.
- **Preparado, por probar:** mostrar `CHASER` como nombre visible del perseguidor.
- **Preparado, por probar:** tras un fallo, ralentizar al perseguidor un 60 % brevemente y sin animación extra; tras un acierto, mantener cooldown largo y hacer que el bate apunte hacia abajo y vuelva lentamente mediante una pose procedural. Verificar mano y bate, tanto al acertar como al fallar, y que el bate vuelva a su agarre al cambiar de herramienta.
- **Pendiente de diseño:** encontrar una solución clara para que las ventanas se crucen mediante su vault y no con el salto normal. Se retiró solo la conversión de Espacio en vault al acercarse a una ventana porque, tras alejarse, el salto quedaba inutilizable durante varios segundos. La aproximación automática al marcador al usar clic derecho sí se conserva. Mientras tanto, el usuario colocó una pared visible sobre la ventana para explicar la barrera.
- **Preparado, por probar:** la aproximación automática al marcador al pulsar clic derecho se mantiene. Mientras dura esa caminata, se impone la dirección hacia el marcador después del control normal del jugador, sin cambiar su `WalkSpeed`; verificar que el vault se active tanto parado como manteniendo sprint contra la pared y que el control vuelva al terminar o fallar la aproximación.
- **Preparado, por probar:** el bonus de velocidad del 35 % para ventana y paso estrecho depende del estado de sprint activo, movimiento y stamina positiva al iniciar la acción; caminar hacia el marcador sin Shift ya no lo otorga. Probar Shift mantenido, soltado, agotamiento de stamina y respawn.
- **Preparado, por probar:** el Chaser atraviesa ventanas y pasos estrechos al 80 % de la velocidad base del Runner, en lugar de aproximadamente la mitad; confirmar que sigue siendo ligeramente más lento con y sin sprint y con stamina baja.
- **Preparado, por probar:** al eliminar al Runner, el Chaser ve `You Win` y el Runner `You Lose`; al agotarse el tiempo se invierten. Los finales de prueba o interrupción muestran `Round Over`, y el resultado final conserva textos en inglés.
- **Preparado, por probar:** anticipar el noqueo al aterrizar y mostrar bordes rojos al recibir daño, amarillos al quedar aturdido. Verificar caídas con y sin pérdida de vidas.
- **Preparado, por probar:** todas las acciones de parkour pasan de Espacio a clic derecho, incluido soltar la escalada; verificar en lobby y partida que el clic derecho no interfiera con cámara ni interfaces.

## Alertas de Studio ajenas a estos scripts

- El plugin de Rojo mostró `GetClassIcon:  is not a Roblox class` dentro de `Roact/VirtualScroller`. El servidor Rojo 7.7.1 seguía escuchando en `127.0.0.1:34872` y el build local pasó. Confirmar si reaparece al reiniciar Studio; si ocurre, guardar la primera línea de error, no solo el stack.
- `Workspace.ROCK.Script` espera indefinidamente un hijo `ThrowEvent`. El asset `ROCK` está en el Place, fuera de los scripts sincronizados por Rojo. No crear el evento a ciegas: confirmar si el asset se usa y, si no, desactivar solo su script huérfano en una copia guardada del Place.

## Verificación

- Probar estos cambios en el lobby y en partida, en R15, con subida y bajada largas, salida manual con clic derecho, llegada natural al extremo y stamina baja o agotada.
- Confirmar que las acciones de parkour existentes y el indicador contextual no presentan regresiones.
