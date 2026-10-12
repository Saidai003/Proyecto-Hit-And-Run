# Pendientes de juego

Registrados a partir de los últimos playtests del usuario. Los ajustes de código indicados abajo están preparados en Rojo; **falta verificar el comportamiento en Studio y publicado antes de darlos por cerrados**.

## Slide

- **Preparado, por probar:** mientras se corre, Ctrl izquierdo o C inicia un slide que consume 12 de stamina. Comienza al 125 % de la velocidad de sprint, frena gradualmente en plano durante alrededor de 1,5–2 segundos y termina al perder impulso, sin anular de golpe la velocidad restante. Ahora puede iniciarse con suelo inclinado cercano aunque `FloorMaterial` fluctúe; en bajada el impulso puede mantenerse/aumentar. Espacio o la misma tecla lo interrumpe cuando existe espacio para levantarse.
- **Preparado, por probar:** la animación `81512224938575` se congela al 50 % durante el deslizamiento y reproduce el resto al terminar. El track se mantiene en loop hasta congelarse para evitar que una carga tardía lo termine antes de fijar la pose. En el servidor se sustituyen temporalmente las colisiones del cuerpo por un collider invisible bajo; en el cliente el Humanoid pasa temporalmente al estado `Physics` para que su motor de caminar no frene el impulso limitado del slide. Se restaura `Running`/`Freefall` al terminar o `Running` para salir de un techo bajo a velocidad reducida. La orientación permanece estabilizada y el impulso deja de empujar antes de chocar con paredes, sin anular la velocidad horizontal. La comprobación de golpe del Chaser sigue siendo por distancia, de modo que el slide no da inmunidad al bate.
- **Preparado, por probar:** el audio loopeable `Sliding_on_the_floor.mp3`, nivelado a aproximadamente -20 LUFS y aprobado como asset `124746201934592`, se reproduce durante el slide y se destruye al finalizar.
- **Confirmado en playtest por el usuario (2026-10-11):** el slide ya avanza correctamente y no presenta el temblor físico anterior. Mantener la cancelación manual actual.
- **Decisión de diseño abierta:** valorar que una nueva orden de movimiento después de iniciar el slide lo interrumpa automáticamente. Distinguir esa nueva orden de la tecla de movimiento que ya estaba presionada para correr, pues de otro modo se cancelaría apenas comience. Por ahora no cambiar la cancelación con C/Ctrl (o Space).
- Probar en Studio con dos jugadores y avatares R6/R15: inicio solo al correr, choque frontal y oblicuo con pared (sin atravesarla ni temblar), fin gradual en plano, entrada y descenso por rampa moderada/empinada, túnel bajo, salto/parkour/ataque bloqueados durante el slide, agotamiento de stamina, muerte/respawn y limpieza de la colisión al terminar. Si vuelve a cortarse antes de lo esperado, anotar la línea `[SLIDE END]` de Output: distingue fin por pared, baja velocidad, atasco, aire, interrupción y tecla manual. La física y la altura visual dependen de la pose del asset y necesitan playtest real.

## Escalada

- **Preparado, por probar:** conservar el estado en subidas largas y entre piezas contiguas; comprobar `Drop Off` / `NoEscalando` al soltar o llegar al extremo.
- **Preparado, por probar:** aceptar `TrussPart` automáticamente y cualquier otra `BasePart` únicamente cuando tenga el atributo booleano exacto `climbable = true`. Strings, otras capitalizaciones y tags ya no cuentan como configuración válida. Las piezas marcadas reciben locomoción vertical personalizada (W/S), con cobro de stamina por distancia. Probar en Studio con una pared lisa, una escalera hecha de Parts, ambos roles y los extremos superior/inferior; verificar el descenso y `Drop Off`.
- **Preparado, por probar:** cobrar 5 puntos de stamina por stud vertical recorrido al subir o bajar, sin tarifa inicial; a cero, soltar la escalada. Comprobar que no se cobre por caídas ajenas a la escalada.

## Salto con Espacio

- **Preparado, por probar:** reducir `JumpPower` experimental de 50 a 40; comprobar en los muros del mapa si basta para preservar los recorridos de persecución.
- **Preparado, por probar:** Espacio pasa a ser la tecla del salto; ALT deja de saltar. Comprobar el gasto de stamina y que no se active parkour accidentalmente.
- **Corrección preparada, por probar (2026-10-12):** el cooldown empieza únicamente cuando el servidor acepta el salto y existe un búfer de entrada de 0,4 s para no perder Espacio al pulsarlo justo antes de que cliente/servidor reconozcan el aterrizaje. La detección local usa un raycast bajo el personaje en vez de depender de un único frame de `FloorMaterial`.
- **Corrección preparada, por probar (2026-10-12):** al llegar arriba o abajo de una escalada natural, salir antes del estado de escalada y forzar `Running` o `Freefall`. Verificar salto inmediato al coronar un `TrussPart`, una pieza marcada `climbable` y justo después de aterrizar de un salto normal.

## Pallets

- **Corrección preparada, por probar (2026-10-12):** precargar las cuatro animaciones de pallet y reproducirlas con prioridad `Action4`. Esto evita que la animación de romper el pallet (`122984890985296`) quede oculta por locomoción o por la pista del ataque/bate. Probar como Chaser con y sin bate equipado y confirmar que la destrucción coincide con el final de la animación.

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
- **Preparado, por probar:** sustituir el contador principal de stamina por una barra con valor numérico; comprobar Runner (100), Chaser (120), agotamiento y regeneración, tanto en lobby como junto a las vidas durante una ronda.
- **Preparado, por probar:** ubicar el botón de donación fuera de la lista de jugadores y del indicador central de parkour: abajo a la derecha en pantallas anchas y arriba a la izquierda en pantallas estrechas.
- **Preparado, por probar:** mostrar `CHASER` como nombre visible del perseguidor.
- **Preparado, por probar:** tras un fallo, ralentizar al perseguidor un 60 % brevemente y sin animación extra; tras un acierto, mantener cooldown largo y hacer que el bate apunte hacia abajo y vuelva lentamente mediante una pose procedural. Verificar mano y bate, tanto al acertar como al fallar, y que el bate vuelva a su agarre al cambiar de herramienta.
- **Pendiente de diseño:** encontrar una solución clara para que las ventanas se crucen mediante su vault y no con el salto normal. Se retiró solo la conversión de Espacio en vault al acercarse a una ventana porque, tras alejarse, el salto quedaba inutilizable durante varios segundos. La aproximación automática al marcador al usar clic derecho sí se conserva. Mientras tanto, el usuario colocó una pared visible sobre la ventana para explicar la barrera.
- **Preparado, por probar:** la aproximación automática al marcador al pulsar clic derecho se mantiene. Mientras dura esa caminata, se impone la dirección hacia el marcador después del control normal del jugador, sin cambiar su `WalkSpeed`; verificar que el vault se active tanto parado como manteniendo sprint contra la pared y que el control vuelva al terminar o fallar la aproximación.
- **Preparado, por probar:** el bonus de velocidad del 35 % para ventana y paso estrecho depende del estado de sprint activo, movimiento y stamina positiva al iniciar la acción; caminar hacia el marcador sin Shift ya no lo otorga. Probar Shift mantenido, soltado, agotamiento de stamina y respawn.
- **Preparado, por probar (2026-10-12):** usar la animación `72846871061644` exclusivamente durante el sprint real sobre el suelo. Se precarga, usa prioridad `Action2`, fuerza peso completo, ajusta ligeramente su velocidad entre Runner y Chaser y se detiene al quedarse quieto, saltar, escalar, deslizarse, ejecutar parkour, atacar, quedar noqueado o bloquearse el movimiento. Output informa si cargó, su duración y el rig activo; probarla con ambos roles y después de reaparecer.
- **Preparado, por probar (2026-10-12):** cualquier `BasePart` con el atributo booleano exacto `MakesPlayersLose = true` hace perder inmediatamente la ronda al jugador que la toca, sin importar su rol. El servidor lo noquea, lo devuelve a su `RoundSpawn`, concede la ronda al rival y mantiene el noqueo durante los 2 segundos del resultado. Probarlo como Runner y Chaser, incluyendo contacto durante slide/parkour y una pieza que no tenga el atributo.
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
- **Preparado, por probar:** equipar y lanzar `Coffee`; la taza y el vapor deben seguir visibles y unidos al `Handle`, y la silla debe continuar funcionando. El script `CoffeeVisualFix` repara el asset importado al cargarlo, pero la Tool sigue siendo un objeto del Place fuera de Rojo.

## Audio

- **Subidos y enlazados:** 22 efectos de `SFX/` para botones, resultados, ventana, palés, escalada, golpes, lanzamiento y caídas, más `lobby_music.mp3` para el lobby. Los IDs actuales están en `AudioCatalog.luau` y `tools/audio-balanced-ids.json`; `tools/audio-ids.json` conserva los IDs anteriores. La clave no se guarda en el repositorio.
- **Pendiente de verificación:** el usuario confirma que los efectos se reproducen, pero con retraso. Probar volumen/duplicaciones con dos clientes y comprobar que la precarga mejora el primer uso tras sincronizar Rojo y publicar.
- Comprobar que la música de lobby se oye solo mientras `LobbyPractica` es verdadero y que se desvanece al encontrar partida. Medir si la precarga y el recorte de silencio reducen el retraso de los efectos; si persiste, revisar los disparos desde servidor.
- El audio de cuenta regresiva dura 11 segundos pero la cuenta actual es de 3; requiere edición o selección de una muestra diferente antes de integrarlo. Los 4 sonidos de cristal tampoco tienen todavía una acción de rotura asignada.
- La música de persecución que ya existe en el Place debe quedar intacta. Se eliminó el MP3 local duplicado `brief_metallic_hit.mp3`; la pista de lobby permanece como `lobby_music.mp3`.
- **Nivelación offline (11 oct 2026):** 23 MP3 de uso actual se nivelaron por categoría con techo de pico alrededor de -2 dBFS; `VaultPallet` pasó de -30.95 a -18.25 LUFS. Se recortó silencio inicial de cinco efectos (máximo 252 ms). Los archivos originales están respaldados en `.tools/audio-originals-2026-10-11/`, fuera de Git. No se cambiaron los valores `Sound.Volume` del juego.
- **Nuevos assets activados:** como Roblox no permite reemplazar el contenido de audio existente, se subieron 23 assets nuevos. Todos figuran como `Approved`; sus IDs están en `tools/audio-balanced-ids.json` y `AudioCatalog.luau` ya los usa. Los anteriores permanecen sin uso en la biblioteca.
- Tras activarlos, probar especialmente el volumen de `VaultPallet` y `LobbyMusic` (señalados por el usuario) y escuchar si el recorte de silencios redujo el retraso percibido. Ajustar la masterización si fuese necesario, sin cambiar `Sound.Volume` salvo acuerdo posterior.
