# Errores anteriores y precauciones para futuras IA

## 1. Rojo borró el mapa del Place (2026-10-13)

**Error cometido:** inicié/propuse sincronizar Rojo sin advertir que `default.project.json` tenía `$ignoreUnknownInstances: false` en `Workspace` y otros contenedores. El mapa existe principalmente en el archivo de Studio, no en `src/`. Al conectar Rojo, las instancias que no estaban representadas en el proyecto se eliminaron del Place de edición.

**Recuperación:** con Rojo desconectado, el usuario usó una sola vez Ctrl+Z y recuperó el mapa. Guardó `Backup_DO_NOT_TOUCH/Backup 3.rbxl`; se verificó que contiene el mapa y `RoundSpawn1`/`RoundSpawn2`, y se subió a GitHub. Los valores de `$ignoreUnknownInstances` se cambiaron a `true`. Al reconectar, el usuario confirmó que el mapa y los spawns permanecían.

**Regla obligatoria:** antes de conectar Rojo o editar el árbol del proyecto, verificar `default.project.json`, el respaldo `.rbxl` reciente y qué instancias son exclusivas del Place. No tratar un `rojo build` como respaldo completo del mapa. No volver a poner `$ignoreUnknownInstances: false` sin haber migrado y comprobado todo el mapa en archivos. Ante una desaparición, detener Rojo y **no guardar ni publicar** el Place afectado; recuperar desde Undo o respaldo primero.

## 2. Diagnósticos prematuros de `InvisibleDeathZone` (2026-10-14)

**Error cometido:** supuse primero que el contacto fallaba por ser una pieza delgada y después que el mapa ampliado quedaba fuera de su área de 600×600 studs. Esas eran hipótesis plausibles, pero las presenté como causa y subí cambios antes de confirmar con una prueba real. El usuario repitió el playtest: el servidor registraba la pieza, pero nunca aparecía el mensaje de activación. `rojo build` confirmó que el proyecto se empaquetaba, **no** que la lógica funcionara en Roblox.

**Estado conocido:** el script `Controlador1v1` arranca y registra `Workspace.InvisibleDeathZone` con `MakesPlayersLose = true`. En el Place probado, su centro estaba en Y≈293.96. La traza confirmó que el servidor ve caer al personaje de Y=349 hasta Y=62 y que `LobbyPractica` sigue en `true`, pero `zona registrada` cambia de `true` a `false` antes de llegar al límite. En la prueba siguiente apareció explícitamente `InvisibleDeathZone salio de Workspace`; aún no está identificada la causa de esa retirada. Las alertas de `PoseLink` y `ROCK` son ajenas a esta detección.

**Corrección aplicada y lobby verificado (2026-10-14):** el controlador guarda la altura global al registrar la zona y ya no depende de que la pieza permanezca en `Workspace` para detectar una caída. El usuario confirmó en Studio los mensajes `Bajo el limite:` y `Lobby:` y el regreso al spawn tras aproximadamente 2 segundos. La traza temporal de altura se retiró. Falta probar una ronda con dos jugadores y determinar qué retira la pieza, aunque la caída de lobby ya funciona aun después de esa retirada.

## Práctica de entrega

- Separar claramente **cambio escrito**, **construcción Rojo exitosa** y **playtest confirmado**; son tres niveles distintos de verificación.
- No publicar una versión como estable mientras un fallo reportado siga sin reproducirse y resolverse en Studio.
- Conservar los cambios ajenos del usuario y no sobrescribir archivos `.rbxl` sin un respaldo verificado.
