# Configuración de streaming

El proyecto administra estas propiedades de `Workspace` mediante Rojo:

- `StreamingEnabled = true`
- `StreamingMinRadius = 64`
- `StreamingTargetRadius = 512`
- `StreamOutBehavior = Opportunistic`
- `StreamingIntegrityMode = PauseOutsideLoadedArea`
- `ModelStreamingBehavior = Improved`

El radio de 512 studs es un punto de partida moderado para este mapa. Debe ajustarse después de probar el recorrido completo y observar cuándo aparecen las estructuras.

Antes de transportar a cada jugador a su punto inicial, el servidor solicita temporalmente la región mediante `Player:RequestStreamAroundAsync()`. Así el suelo y los obstáculos cercanos tienen oportunidad de llegar antes del cambio de posición.

## Modelos especiales

Los objetos normales no necesitan atributos. Roblox los carga y descarga según la distancia.

- `KeepStreamed` (Boolean, `true`): mantiene permanentemente el `Model` completo en los clientes. Usarlo únicamente en unos pocos modelos pequeños que deban estar siempre disponibles o visibles.
- `StreamAsAtomic` (Boolean, `true`): transmite el `Model` como una unidad completa. Es apropiado para conjuntos interactivos cuyas piezas no deben aparecer por separado.

Si ambos atributos están activos, `KeepStreamed` tiene prioridad. Al quitarlos durante la ejecución, se restaura el modo anterior del modelo.

Para edificios decorativos lejanos que deban conservar una silueta, agruparlos en modelos estáticos pequeños y establecer `LevelOfDetail = SLIM` desde Properties en Studio. No usar SLIM en objetos animados o modificados durante la partida. Roblox recomienda que cada modelo de este tipo tenga una extensión espacial aproximada menor a 64 studs; dividir edificios grandes en secciones cuando sea posible.

## Prueba

1. Reiniciar el playtest después de sincronizar Rojo.
2. Recorrer todas las rutas a velocidad de sprint y mediante parkour.
3. Confirmar que ventanas, pallets, objetos lanzables, peligros y puntos de aparición estén presentes antes de necesitarlos.
4. Abrir el panel de red con `Shift + Ctrl + F3` y pulsar `Shift + 1` hasta llegar a la vista de streaming.
5. Comparar FPS, memoria y aparición visual antes de reducir nuevamente el radio objetivo.

Si aparecen objetos demasiado tarde, subir `StreamingTargetRadius` primero a 768. Si todo funciona y todavía hay presión de memoria, probar 384 como siguiente ajuste controlado.
