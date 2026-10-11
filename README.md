# Proyecto Roblox Prototype

Esta carpeta es la fuente de los scripts del MVP. `default.project.json` sincroniza
`src/ServerScriptService` y `src/StarterPlayer/StarterPlayerScripts` con Roblox Studio.
El mapa y los objetos de Workspace siguen en el archivo `.rbxl` de Studio; el
respaldo anterior está en `Backup_DO_NOT_TOUCH`. Guarda también la versión actual
del Place en esta carpeta para que el nuevo `Baseball Bat` no quede solo en Studio.

## Rojo

El servidor de este proyecto escucha en `localhost:34873`. La sesión de prueba
`RojoTest` en el puerto 34872 no se modifica. Conecta el plugin de Rojo de Studio
al **34873** estando abierto el Place correcto. Rojo está configurado para
preservar instancias no representadas por archivos (mapa, silla, bate y remotos).
Antes de la primera sincronización, guarda una copia del Place actual.

Para reiniciar el servidor desde esta carpeta: `rojo serve default.project.json`.
Para comprobar la estructura: `rojo build default.project.json --output check.rbxlx`.
Ese build no incluye el mapa ni sustituye una prueba de juego.

## Cambios de esta tanda

- El perseguidor recibe el bate del Workspace al comenzar su rol. Equiparlo usa
  mayor alcance y cooldown que el golpe con la mano; se puede desequipar para
  volver a la mano y equipar la silla independientemente.
- Space inicia o corta la escalada de una `TrussPart` próxima. Ventanas, estrechos,
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

1. Conectar Rojo al puerto 34873 y confirmar que `Baseball Bat` está en Workspace.
   Revisar su agarre, escala y orientación en R15; retirar scripts incorporados
   al asset público si los tiene.
2. En Studio con dos clientes: comprobar mano/bate/silla, 6 rondas, stamina baja,
   escalada Space y caída desde una ventana alta. Revisar Output por errores.
3. En una versión publicada con dos cuentas: entrar al mismo lobby, pulsar Play,
   confirmar que ambos llegan a la misma instancia privada y que al acabar
   vuelven juntos al lobby original o a uno público. Roblox no admite probar
   `TeleportService` plenamente en el playtest local de Studio.

El salto normal deliberadamente **no está implementado**: su control sigue como
decisión de diseño. La guía de puntería de la silla también se mantiene por ahora.
