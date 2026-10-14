# Proyecto Roblox Prototype

Esta carpeta es la fuente de los scripts del MVP. `default.project.json` sincroniza
`src/ServerScriptService`, `src/ReplicatedStorage` y
`src/StarterPlayer/StarterPlayerScripts` con Roblox Studio.
El mapa y los objetos de Workspace siguen en el archivo `.rbxl` de Studio; el
respaldo anterior está en `Backup_DO_NOT_TOUCH`. Guarda también la versión actual
del Place en esta carpeta para que el mapa actual no quede solo en Studio.

## Rojo

El servidor de este proyecto escucha en `localhost:34872`. La antigua sesión de
prueba `RojoTest` fue reemplazada para evitar confusiones. Conecta el plugin de
Rojo de Studio al **34872** estando abierto el Place correcto. Rojo está configurado para
preservar instancias no representadas por archivos (mapa, silla, bate y remotos).
Antes de la primera sincronización, guarda una copia del Place actual.

Para iniciar Rojo desde cualquier ubicación, abre PowerShell y ejecuta:

```powershell
Set-Location 'C:\Users\Maxim\OneDrive\Escritorio\ProyectoRobloxPrototype'
& '.\.tools\rojo-7.7.1\rojo.exe' serve 'default.project.json'
```

Deja abierta esa ventana mientras uses Studio. Debe indicar `localhost:34872`;
en el plugin Rojo de Studio, conecta al proyecto `GolpearYHuirMVP` en ese puerto.
Para detener el servidor, pulsa `Ctrl+C` en PowerShell. Conectar Rojo
sincroniza el código con el Place abierto en Studio, pero **no publica** una
nueva versión para los jugadores; después de comprobar el mapa y los cambios,
publica el Place desde Studio y verifica que Version History marque la nueva
versión como `Published`.

Para comprobar la estructura: `rojo build default.project.json --output check.rbxlx`.

**Importante:** el mapa se guarda en el Place de Studio, no en el árbol de
archivos de Rojo. `default.project.json` usa `$ignoreUnknownInstances: true`
en `Workspace` y los servicios parcialmente gestionados; no cambiarlo a
`false`, pues Rojo eliminaría los objetos del Place que no existen en disco.
Antes de conectar Rojo a un Place nuevo, guardar una copia `.rbxl` desde
Studio. Un `.rbxlx` creado con `rojo build` contiene solamente lo modelado en
Rojo y **no** es un respaldo completo del mapa.

Los nueve sprites de `Sprites/` se subieron como assets Image a la biblioteca del propietario.
Sus IDs actuales están en `tools/sprite-image-ids.json` y en
`src/ReplicatedStorage/MobileSpriteCatalog.luau`. Los controles móviles se
activan cuando Roblox detecta pantalla táctil: Action/Sprint en la fila superior
y Throw/Jump en la inferior. El pequeño botón LOCK junto a Sprint deja el
sprint fijo hasta pulsar ON o hasta que la stamina o el estado lo interrumpan;
mantener pulsado Sprint sigue funcionando de forma momentánea. La acción es contextual;
al equipar una Tool con `Throwable = true`, aparece además un botón Throw
independiente (mantener para apuntar y soltar para lanzar). Los sprites se
muestran completos, sin recorte por píxeles, con texto de respaldo si no cargan.
Al mantener y arrastrar un botón se puede girar la cámara; la zona libre de
pantalla conserva el control de cámara predeterminado de Roblox. Los IDs viejos
de tipo Decal quedan registrados en `tools/sprite-ids.json` como historial.
Rojo sincroniza scripts e IDs con Studio, pero la versión publicada solo cambia
después de publicar el Place desde Studio.
Ese build no incluye el mapa ni sustituye una prueba de juego.
Los eventos (`RemoteEvent`, `EventoCountdown` como `BindableEvent`) y
`SolicitarParkour1v1` ahora están declarados en
`default.project.json`; no dependen de objetos creados manualmente en Studio.
Si desaparecen a la vez el menú y el parkour, comprueba primero que el servidor
Rojo siga escuchando en 34872 y que el plugin indique **Connected**. Al cambiar
`default.project.json`, vuelve a conectar el plugin si perdió la conexión;
para cambios normales de scripts, basta con reiniciar el playtest.

## Audio

Los efectos de `SFX/` se enlazan mediante `src/ReplicatedStorage/AudioCatalog.luau`.
El script `tools/upload-audio.cjs` sube solo los efectos usados por el MVP a la
biblioteca de la cuenta propietaria mediante Open Cloud y registra los IDs en
`tools/audio-ids.json` (historial de la primera carga). Requiere una clave con
acceso a Assets/Write en la variable local `ROBLOX_API_KEY`; nunca se guarda la
clave en el repositorio. Los 22 efectos usados por el MVP tienen versiones
niveladas aprobadas y sus IDs actuales están en el catálogo. La pista
`lobby_music.mp3` también se subió y suena en el lobby con entrada/salida gradual;
se apaga al encontrar partida. Los efectos cortos se precargan en segundo plano
para reducir el retraso de su primera reproducción. La música de persecución existente en
Studio no se modifica. El duplicado local `brief_metallic_hit.mp3` se eliminó;
`lobby_music.mp3` es la única copia de esa pista en `SFX/`. Los MP3 de `SFX/`
permanecen locales; no se publican en GitHub.

Para nivelar el audio sin cambiar los volúmenes del código, ejecuta
`node tools/normalize-audio.cjs` con FFmpeg disponible en `.tools/` o en
`FFMPEG_PATH`. Las versiones niveladas quedan en `.tools/normalized-audio/`;
los MP3 locales de `SFX/` se reemplazaron tras respaldar los originales en
`.tools/audio-originals-2026-10-11/`. Roblox no permite actualizar el contenido
de assets de audio, así que `tools/upload-balanced-audio.cjs` crea IDs nuevos,
registrados en `tools/audio-balanced-ids.json`. Roblox aprobó los 23 reemplazos
y `AudioCatalog.luau` ya usa los nuevos IDs; los anteriores quedaron sin uso.

## Cambios de esta tanda

- Rango ajustado a 5.8 studs para ventanas/pasos estrechos, 6.5 para palés y
  5.5 para escalada. La escalada muestra `Drop Off` al estar activa y vuelve a
  `NoEscalando` al soltarla o terminar naturalmente.
- La aproximación a una acción usa `Humanoid:MoveTo` y la velocidad actual del
  jugador; si no puede llegar, no inicia la animación.
- Espacio ejecuta el salto de potencia 40 y gasta 15 de stamina; con menos de
  15 no se puede saltar. ALT ya no ejecuta el salto. El ajuste de altura aún
  necesita prueba en los muros del mapa.
- El retrato de vidas tiene un fallback con la cabeza del personaje de Studio
  cuando Roblox no entrega una miniatura de los jugadores simulados.
- El aturdimiento de caída aplica un impulso y giro breve para que el personaje
  no permanezca parado mientras está noqueado.
- El botón de donación usa el Developer Product `3717856374` creado por el dueño
  con precio base de 100 Robux. La UI consulta el precio vigente de Roblox antes
  de abrir el aviso de compra, y muestra una aclaración de que cualquier paquete
  de Robux ofrecido por Roblox es distinto del precio de la donación. El botón
  se sitúa abajo a la derecha en pantallas anchas y arriba a la izquierda en
  pantallas estrechas, sin tapar el indicador central de parkour. La compra
  no entrega objetos ni ventajas.
- En el lobby público se puede practicar parkour y sprint como perseguido; al
  encontrar pareja se desactiva la práctica.
- Un indicador inferior muestra `RMB` (clic derecho) y la acción de parkour disponible.
- Las acciones de ventana y paso estrecho reciben el bonus de velocidad del 35 %
  solo al iniciarse mientras el personaje esprinta con stamina y se mueve;
  caminar hacia el marcador ya no concede ese bonus.
- El Chaser cruza ventanas y pasos estrechos al 80 % de la velocidad del Runner,
  con el mismo bonus de sprint y las mismas reglas de stamina.
- El resultado de cada ronda se muestra desde la perspectiva del jugador como
  `You Win` o `You Lose`; los textos visibles de la interfaz están en inglés.
- `HOW TO PLAY` tiene pestañas separadas para Runner y Chaser. Explica objetivos,
  controles, stamina, parkour y las seis rondas con roles alternados. El resultado
  final premia al jugador que acumuló **más** tiempo sobreviviendo como Runner;
  las tarjetas crecen según el texto para que se pueda leer sin recortes.
- El panel de stamina se ajusta a su contenido y queda encima del menú en lobby
  cuando no hay contador de vidas. Muestra una barra proporcional a la stamina
  máxima de cada rol, con valor numérico y color de advertencia al agotarse.
- El nombre visible del rol perseguidor es `CHASER`.
- Tras fallar un ataque, el perseguidor camina al 40 % de su velocidad normal
  solo brevemente (0,35 s con mano, 0,5 s con bate), sin animación adicional.
  Un acierto mantiene el cooldown más largo (1 s / 1,8 s); con el bate, una
  recuperación procedural lo apunta hacia abajo y lo devuelve lentamente a su posición.
- Los bordes de pantalla muestran rojo al recibir daño y amarillo en el
  aturdimiento de caída. La detección de aterrizaje comienza antes del contacto
  pleno para reducir el retardo percibido del noqueo.
- Las vidas del perseguido se muestran una sola vez con corazón, retrato circular
  del avatar y contador; el retrato dinámico utiliza la miniatura nativa de
  Roblox de 420×420 (la API no ofrece 512×512).
- El cursor se oculta durante la ronda y vuelve al lobby. Al terminar el parkour,
  el personaje se corrige solo si penetró el suelo, sin adelantar su caída.
- El perseguidor recibe un bate construido con un agarre vertical controlado al comenzar su rol. Equiparlo usa
  mayor alcance y cooldown que el golpe con la mano; se puede desequipar para
  volver a la mano y equipar la silla independientemente.
- La Tool `Coffee` importada se corrige al cargar: sus piezas visibles dejan de
  estar ancladas y se unen al `Handle` exterior invisible. Así acompañan al
  personaje al equiparla y al proyectil al lanzarla; la silla no se modifica.
  La exportación original está conservada en `tools/coffee.rbxm`; el objeto del
  Place aún se mantiene en Studio, fuera de la sincronización de Rojo.
- El clic derecho inicia o corta la escalada de una `TrussPart` o pieza marcada `Escalable`. También se reconoce una `BasePart` con el atributo String `climbable` = `"true"` (o `"climbable"`/`"yes"`), o con la etiqueta `climbable`. Las piezas normales marcadas usan ascenso/descenso vertical personalizado con W/S; se deben probar las superficies concretas del mapa en Studio.
- Mientras se corre, Ctrl izquierdo o C inicia un deslizamiento que consume 12 de stamina y arranca al 125 % de la velocidad de sprint. La animación `81512224938575` mantiene la pose central hasta salir; las pendientes descendentes prolongan el movimiento, una colisión baja permite pasar por huecos apropiados y el audio de suelo se reproduce en loop. Requiere probar dimensiones de los huecos y la pose en Studio.
  próxima. La escalada consume 5 puntos de stamina por stud vertical realmente
  recorrido, hacia arriba o abajo; al agotarse se suelta. Las piezas marcadas
  deben tener geometría que el Humanoid pueda escalar. Ventanas, estrechos,
  salto de pale y escalada consumen stamina validada por el servidor. Con stamina
  insuficiente se ejecutan un 30 % más lento.
- Las acrobacias terminan a la altura del marcador de salida; después actúa la
  gravedad. Las caídas suficientemente altas aturden y pueden quitar vidas al
  perseguido.
- Cámara libre con mouse centrado y distancia fija durante la ronda; cámara
  estándar en lobby. La silla se lanza sin esperar un frame extra en el servidor.
- Dos jugadores de un lobby público se envían juntos a una instancia reservada
  del mismo Place. Al terminar intentan volver al servidor original y, si ya no
  existe, a otro lobby público. No hace falta un segundo Place.
- El botón principal de matchmaking permite buscar o cancelar. La antigua
  interfaz de matchmaking queda desactivada.

## Verificación pendiente en Studio / publicado

Los nuevos ajustes de escalada y salto solicitados tras el último playtest están
registrados en [docs/PENDIENTES.md](docs/PENDIENTES.md); están preparados en
Rojo, pero falta el playtest para confirmarlos.

1. Conectar Rojo al puerto 34872 y confirmar que `ParkourPairs` aparece en
   ReplicatedStorage. Revisar el agarre del bate en R15. El asset público sigue
   en Workspace, pero el bate equipado usa piezas controladas para evitar su
   pivote desplazado.
2. En Studio con dos clientes: comprobar mano/bate/silla, 6 rondas, stamina baja,
   escalada con clic derecho y caída desde una ventana alta. Abrir las dos pestañas
   de `HOW TO PLAY` y comprobar el desplazamiento en distintos tamaños de pantalla.
   Confirmar que gana el mayor tiempo acumulado como Runner. Revisar Output por errores.
3. En una versión publicada con dos cuentas: entrar al mismo lobby, pulsar Play,
   confirmar que ambos llegan a la misma instancia privada y que al acabar
   vuelven juntos al lobby original o a uno público. Roblox no admite probar
   `TeleportService` plenamente en el playtest local de Studio.

El salto con Espacio y potencia 40 aún necesita balance en el mapa. La guía de
puntería de la silla también se mantiene por ahora.

Prueba de regresión de marcadores del respaldo:
`node tools/check-parkour-pairs.cjs`. Necesita la dependencia local en `.tools`.
