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

Para reiniciar el servidor desde esta carpeta: `rojo serve default.project.json`.
Para comprobar la estructura: `rojo build default.project.json --output check.rbxlx`.
Ese build no incluye el mapa ni sustituye una prueba de juego.
Los `RemoteEvent` y `SolicitarParkour1v1` ahora están declarados en
`default.project.json`; no dependen de objetos creados manualmente en Studio.
Si desaparecen a la vez el menú y el parkour, comprueba primero que el servidor
Rojo siga escuchando en 34872 y que el plugin indique **Connected**. Al cambiar
`default.project.json`, vuelve a conectar el plugin si perdió la conexión;
para cambios normales de scripts, basta con reiniciar el playtest.

## Cambios de esta tanda

- El perseguidor recibe un bate construido con un agarre vertical controlado al comenzar su rol. Equiparlo usa
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

1. Conectar Rojo al puerto 34872 y confirmar que `ParkourPairs` aparece en
   ReplicatedStorage. Revisar el agarre del bate en R15. El asset público sigue
   en Workspace, pero el bate equipado usa piezas controladas para evitar su
   pivote desplazado.
2. En Studio con dos clientes: comprobar mano/bate/silla, 6 rondas, stamina baja,
   escalada Space y caída desde una ventana alta. Revisar Output por errores.
3. En una versión publicada con dos cuentas: entrar al mismo lobby, pulsar Play,
   confirmar que ambos llegan a la misma instancia privada y que al acabar
   vuelven juntos al lobby original o a uno público. Roblox no admite probar
   `TeleportService` plenamente en el playtest local de Studio.

El salto normal deliberadamente **no está implementado**: su control sigue como
decisión de diseño. La guía de puntería de la silla también se mantiene por ahora.

Prueba de regresión de marcadores del respaldo:
`node tools/check-parkour-pairs.cjs`. Necesita la dependencia local en `.tools`.
