# Errores anteriores y precauciones para futuras IA

## 1. Rojo borró el mapa del Place (2026-10-13)

**Error cometido:** inicié/propuse sincronizar Rojo sin advertir que `default.project.json` tenía `$ignoreUnknownInstances: false` en `Workspace` y otros contenedores. El mapa existe principalmente en el archivo de Studio, no en `src/`. Al conectar Rojo, las instancias que no estaban representadas en el proyecto se eliminaron del Place de edición.

**Recuperación:** con Rojo desconectado, el usuario usó una sola vez Ctrl+Z y recuperó el mapa. Guardó `Backup_DO_NOT_TOUCH/Backup 3.rbxl`; se verificó que contiene el mapa y `RoundSpawn1`/`RoundSpawn2`, y se subió a GitHub. Los valores de `$ignoreUnknownInstances` se cambiaron a `true`. Al reconectar, el usuario confirmó que el mapa y los spawns permanecían.

**Regla obligatoria:** antes de conectar Rojo o editar el árbol del proyecto, verificar `default.project.json`, el respaldo `.rbxl` reciente y qué instancias son exclusivas del Place. No tratar un `rojo build` como respaldo completo del mapa. No volver a poner `$ignoreUnknownInstances: false` sin haber migrado y comprobado todo el mapa en archivos. Ante una desaparición, detener Rojo y **no guardar ni publicar** el Place afectado; recuperar desde Undo o respaldo primero.

## 2. Diagnósticos prematuros de `InvisibleDeathZone` (2026-10-14)

**Error cometido:** supuse primero que el contacto fallaba por ser una pieza delgada y después que el mapa ampliado quedaba fuera de su área de 600×600 studs. Esas eran hipótesis plausibles, pero las presenté como causa y subí cambios antes de confirmar con una prueba real. El usuario repitió el playtest: el servidor registraba la pieza, pero nunca aparecía el mensaje de activación. `rojo build` confirmó que el proyecto se empaquetaba, **no** que la lógica funcionara en Roblox.

**Estado conocido:** el script `Controlador1v1` arranca y registra `Workspace.InvisibleDeathZone` con `MakesPlayersLose = true`. En el Place probado, su centro estaba en Y≈293.96. El usuario informó que el personaje caía al vacío, pero Output no mostraba `Bajo el limite:` ni `Lobby:`. Por ello aún **no se puede afirmar que la zona funcione**. Las alertas de `PoseLink` y `ROCK` son ajenas a esta detección.

**Siguiente diagnóstico:** medir la altura de `HumanoidRootPart` que ve el servidor mientras cae, si la zona sigue registrada y si `Workspace.LobbyPractica` está activo. El código incluye una traza temporal `[MakesPlayersLose] Altura servidor:` cada 30 studs de descenso. Pedir el Output de una sola prueba en lobby; no acumular más parches hipotéticos antes de leerlo. Retirar la traza cuando se identifique y corrija la causa. Después verificar lobby y ronda con dos jugadores antes de considerar el arreglo terminado.

## Práctica de entrega

- Separar claramente **cambio escrito**, **construcción Rojo exitosa** y **playtest confirmado**; son tres niveles distintos de verificación.
- No publicar una versión como estable mientras un fallo reportado siga sin reproducirse y resolverse en Studio.
- Conservar los cambios ajenos del usuario y no sobrescribir archivos `.rbxl` sin un respaldo verificado.
