# CHANGES

Registro de cambios por ítem del backlog. Formato: qué cambió, qué valida el
servidor, qué confía el cliente, tests y estado del playtest.

---

## BUG-01 — El perseguidor ya no se mueve al romper un pale

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor con 2 clientes.
- **Problema:** al mover el perseguidor durante la animación de romper, la acción
  se cortaba y el pale no se rompía. El servidor ponía `WalkSpeed = 0`, pero
  `LogicaVelocidad1v1` reescribía `WalkSpeed` con `velocidadBase` en cada frame
  del Heartbeat, deshaciendo el bloqueo al instante.
- **Cambiado:**
  - `ServerScriptService/SistemaPale1v1` — se añadió el handle
    `EventoJuego` (el script solo tenía `EventoPale`). La firma pasó a
    `inmovilizar(jugador, humanoide, duracion)` y ahora emite
    `BLOQUEAR_MOVIMIENTO` al bloquear y `DESBLOQUEAR_MOVIMIENTO` al liberar.
    Los 4 call sites pasan el jugador: `soltarPale`, el stun de
    `soltarPale`, `romperPale` y `saltarPale`.
  - `ServerScriptService/SistemaPale1v1` — `liberarTodos()` difunde
    `DESBLOQUEAR_MOVIMIENTO` a todos los clientes.
  - `StarterPlayer/StarterPlayerScripts/LogicaVelocidad1v1` — `CharacterAdded`
    pone `movimientoBloqueado = false`.
- **Validaciones del servidor:** sin cambios. El servidor sigue validando rol,
  distancia y estado del pale antes de ejecutar `romperPale`; el cliente solo
  pide `INTERACTUAR`. No se añadió ninguna validación nueva ni se amplió la
  superficie de confianza del cliente.
- **Qué confía el cliente:** que su Heartbeat deje de escribir `WalkSpeed`
  mientras `movimientoBloqueado` es true. Ese flag lo fija y lo limpia
  únicamente el servidor mediante `EventoJuego`.
- **Correcciones al plan original:** el brief daba 3 call sites y ningún handle
  de `EventoJuego`; eran 4 call sites y el handle no existía. Además, el fix
  "solo servidor" dejaba dos caminos que podían dejar a un cliente bloqueado
  para siempre: el reinicio de ronda (`liberarTodos` vacía la tabla y los
  `task.delay` ya no cierran su desbloqueo) y la muerte durante un salto de
  pale (el flag es local y `CharacterAdded` no lo limpiaba).
- **Tests:** `docs/features/BUG-01/spec.feature` (Gherkin),
  `docs/features/BUG-01/acceptance.md`, `docs/features/BUG-01/qa-procedure.md`.
  Sin test automatizado: la comprobación depende del Heartbeat del cliente, no
  hay forma de simularlo desde un ModuleScript.
- **Playtest:** 2026-10-07, 2 clientes, **PASS** en el bug reportado (el autor
  confirma que no pudo moverse manteniendo WASD durante la animación de romper).
  Las dos redes de seguridad siguen sin verificar. Ver `docs/PLAYTEST_LOG.md`.
- **Preguntas abiertas:** ninguna. `Inmovilizado` se conserva porque
  `Controlador1v1.atacar` lo consulta para impedir que un perseguidor aturdido
  golpee.

---

## BUG-02 / T02 — Zona de aturdimiento del pale, simétrica

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor.
- **Problema:** el aturdimiento solo funcionaba si el perseguidor estaba
  pegado al pale. La causa no era solo el rango: la zona estaba **asimétrica**.
  El límite `a >= -0.5` exigía que el perseguidor estuviera en el lado hacia el
  que cae el pale. Como la dirección de caída la fija la geometría del pale y
  no la posición de los jugadores, quien llegaba por el lado contrario quedaba
  excluido a cualquier distancia.
- **Cambiado:** `ServerScriptService/SistemaPale1v1`
  - `LARGO_ZONA_ATURDIMIENTO = 5` → `STUN_RANGE = 7`.
  - `dentroDeZona` usa ahora `math.abs(a) <= STUN_RANGE`: mismo alcance a
    ambos lados de la bisagra. Se eliminó `STUN_RANGE_BEHIND`.
  - La zona pasa de asimétrica (5 hacia delante, 0.5 hacia atrás) a simétrica
    de 7 a cada lado.
  - `MARGEN_LATERAL_ZONA` y el límite vertical `±6` sin cambios.
- **Validaciones del servidor:** sin cambios. El aturdimiento se sigue decidiendo
  en el servidor desde la posición real del perseguidor. No se amplió ninguna
  superficie de confianza del cliente.
- **Qué confía el cliente:** nada nuevo.
- **Notas de la revisión 2026-10-07:** una primera pasada aplicó un rango
  asimétrico (7 delante / 3 detrás). El autor confirmó que la zona seguía
  sin funcionar a distancia razonable, así que se cambió a simétrica. Ningún
  jugador ha visto esa versión intermedia.
- **Tests:** `docs/features/BUG-02/acceptance.md`, `docs/features/BUG-02/qa-procedure.md`.
- **Playtest:** pendiente. Con `STUN_RANGE = 14` simétrico, un perseguidor dentro
  de 14 studs a cualquier lado de la bisagra y a ±4.5 del eje del pale queda
  aturdido 2 s. 14 es la última decisión del autor en la sesión 2026-10-07
  (probó 7, luego 12, y pidió "uno o dos studs más" para asegurar que el stun
  se dispare por radio, no por contacto).
- **Notas de la revisión 2026-10-07:** una primera pasada aplicó un rango
  asimétrico (7 delante / 3 detrás). El autor confirmó que la zona seguía
  sin funcionar a distancia razonable. Se cambió a simétrica con 7, luego 12,
  luego 14. Ningún jugador ha visto los valores intermedios.
- **Trigger:** el aturdimiento se decide por radio (`dentroDeZona` mira la
  posición del perseguidor en el instante en que el pale termina de caer),
  NO por contacto físico. El autor pidió explícitamente confirmarlo.

---

## T05 / Dual-vault conflict — la cámara del salto ya no se traslada

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor.
- **Problema:** al saltar un pale caído, la cámara se trasladaba bruscamente.
  El autor pensaba que era por la pared invisible; en realidad eran **dos
  motores moviendo el root a la vez**: `SaltoPaleCliente` corre un tween
  parabólico servidor-disparado y `LogicaPallet1v1` corría en paralelo un
  `TweenService:Create` recto hacia el lado opuesto del pale. El cliente ni
  siquiera notificaba al servidor (`FireServer` faltaba en la rama de
  salto), así que el `saltarPale` del servidor nunca se ejecutaba.
- **Cambiado:** `StarterPlayer/StarterPlayerScripts/LogicaPallet1v1`
  - Eliminada toda la rama del tween recto y del lookup de `PuntoPale_1/2`
    del lado del cliente.
  - Eliminadas las escrituras a `pale:FindFirstChild("BloqueoPale").CanCollide`
    (el hijo real se llama `InvisibleWall`; eran código muerto).
  - La rama de salto del cliente ahora solo dispara
    `EventoPale:FireServer("INTERACTUAR")` y reproduce la animación. El
    servidor calcula el destino parabólico y dispara el tween vía
    `SaltoPaleCliente`.
- **No se ha tocado:** `SaltoPaleCliente` y `SistemaPale1v1.saltarPale`,
  que ya hacían el trabajo correcto y ahora son la única vía.
- **Pendiente (T15):** `obtenerPaleCercano` sigue iterando con
  `Workspace:GetDescendants()`. Se arreglará con `CollectionService`.
- **Revisión 2026-10-07 (mismo día):**
  - `ALTURA_SALTO = 2` (antes 4): la parábola era demasiado alta. Ahora el
    pico del arco queda a 2 studs sobre la línea de vuelo, no 4.
  - `MARGEN_ATERRIZAJE = 5` (antes 2.5): la zona de aterrizaje
    (`aDestino = ±(mitadExtension + margen) = ±6.5` desde la bisagra) ahora
    cae más allá del pale caído, no en medio de su volumen.
  - `SaltoPaleCliente` ahora llama
    `humanoide:ChangeState(Enum.HumanoidStateType.Freefall)` al final del
    tween. Antes el personaje se quedaba flotando a la altura de la
    parábola hasta que la gravedad lo bajaba, lo que daba la sensación de
    "saltar al aire".
  - **Precaución sobre el destino:** si el jugador está del MISMO lado al
    que cae el pale (más allá del pale caído), el salto lo lleva al otro
    lado de la bisagra, no más allá del pale. Es coherente con la idea de
    "cruzar el pale", pero si el autor lo quiere distinto, este es el
    sitio a cambiar.
- **Revisión 2026-10-07 (mismo día, misma sesión):** el autor corrigió el
  destino del salto. Lo anterior lo calculaba a partir de la posición de
  la `InvisibleWall` (que está en la bisagra), lo que en algunos casos
  devolvía al jugador "hacia atrás" al lado de la bisagra. Ahora se
  calcula a partir de los `PuntoPale_1` y `PuntoPale_2`, los dos extremos
  de la línea de bisagra: el destino es el Punto más cercano al jugador
  en distancia 3D, elevado 2 studs. La pared y la bisagra ya no participan
  en el cálculo. `MARGEN_ATERRIZAJE` deja de tener efecto sobre el salto.

---

## BUG-03 — Carrera al inicio de la cuenta atrás

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor.
- **Problema:** durante la primera fracción de segundo del countdown, el
  jugador podía moverse brevemente. Causa: el broadcast de
  `DESBLOQUEAR_MOVIMIENTO` que añadí en `liberarTodos()` (BUG-01) se
  disparaba por la señal diferida de `IdRonda` durante el `task.wait(0.5)` de
  `iniciarRonda`, dejando al cliente libre un instante antes de que el
  `BLOQUEAR_MOVIMIENTO` de `ControladorCountdown` llegara.
- **Cambiado:** `ServerScriptService/SistemaPale1v1.liberarTodos()` ya no
  difunde `DESBLOQUEAR_MOVIMIENTO`. El desbloqueo de ronda lo controla
  ahora `Controlador1v1` (al final del pre-round de 4 s).

---

## T01 — La pared invisible NO gira con el pale

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor.
- **Problema:** el pale caído se podía rodear caminando por encima, para ambos
  jugadores. Causa raíz: en `aplicarRotacion` el `InvisibleWall` rotaba los
  mismos `ANGULO_CAIDA` (50°) que el cuerpo del pale. Una pared meanta para
  bloquear de pie quedaba inclinada en la dirección de la caída, dejando hueco
  al suelo por debajo en el lado opuesto. La inclinación además reducía su
  cobertura vertical de 6 studs a unos 3.9.
- **Cambiado:** `ServerScriptService/SistemaPale1v1`, función `aplicarRotacion`.
  Se eliminó el bloque que asignaba `datos.invisibleWall.CFrame`. La pared
  conserva su CFrame de origen y queda siempre vertical y estática.
- **Por qué su posición original es la correcta:** el centro de la pared está
  en X≈96.46 y los dos `PuntoPale` del pale se centran en X≈96.46. Además el
  pale rota sobre su bisagra inferior, así que su huella apenas se desplaza.
- **Dirección de caída:** intacta. `signo`, `direccionCaidaFija` y el cuerpo
  visual del pale no se tocaron. El autor lo pidió así explícitamente.
- **Efecto sobre el salto:** ninguno. El salto atraviesa la pared mediante
  grupos de colisión (`Saltando` / `PaleWall`), no mediante la rotación de la
  pared.
- **Validaciones del servidor:** sin cambios. `datos.invisibleWall.CanCollide`
  lo sigue activando el servidor en `soltarPale` cuando el pale pasa a `Caido`
  y desactivándolo en `explotarPale`.
- **Trabajo pendiente relacionado:** el cliente `LogicaPallet1v1` sigue
  escribiendo `CanCollide` sobre un hijo llamado `BloqueoPale` que **no existe**
  (el nombre real es `InvisibleWall`). Es código muerto e inofensivo, pero
  confunde; queda como parte de "Dual-vault conflict" / T14.

---

## BUG-03 — Bloqueo de movimiento durante la cuenta atrás

- **Estado:** `- [~]` implementado. Pendiente del playtest del autor.
- **Problema:** los jugadores podían moverse libremente durante los 3 segundos
  de la cuenta atrás. No era una regresión: la cuenta atrás nunca estuvo
  bloqueada. `ControladorCountdown` solo emitía `COUNTDOWN` e `INICIO`, y el
  único bloqueo vivía en `iniciarRonda`, que corre **después** del countdown.
- **Cambiado:**
  - `ServerScriptService/ControladorCountdown`
    - Emite `BLOQUEAR_MOVIMIENTO` al iniciar la cuenta atrás.
    - Emite `DESBLOQUEAR_MOVIMIENTO` justo antes de `INICIO`.
  - `ServerScriptService/Controlador1v1`, main loop
    - Emite `BLOQUEAR_MOVIMIENTO` justo antes del primer
      `EventoCountdown:Fire()` de la partida. Antes de este cambio, la
      primera cuenta atrás dejaba al cliente libre al inicio porque
      `finalizarRonda` de la ronda anterior acababa de difundir un
      `DESBLOQUEAR` y nada lo volvía a bloquear antes del countdown. Con
      `iniciarRonda` en rondas posteriores esto ya pasaba porque
      `iniciarRonda` mismo emite `BLOQUEAR` antes del countdown.
- **Qué NO se tocó:** `iniciarRonda` y el resto del flujo de ronda siguen igual.

---

## Fragilidad detectada (sin tocar, requiere decisión)

`Controlador1v1.iniciarRonda` emite `BLOQUEAR_MOVIMIENTO` (línea 460) y **nunca
lo libera**. Hoy los jugadores quedan libres durante la ronda únicamente porque
`SistemaPale1v1.liberarTodos()` — introducido en BUG-01 — difunde
`DESBLOQUEAR_MOVIMIENTO` a todos cuando cambia `IdRonda`, y esa señal se
resuelve de forma diferida, después del `task.wait(0.5)` de `iniciarRonda`.

Es decir: **el desbloqueo de la ronda depende hoy del script de pales.** Si
alguna vez se toca `liberarTodos`, `reiniciarPales` o el orden de señales, los
jugadores quedarían congelados toda la ronda sin ningún mensaje de error.

La corrección natural sería que `iniciarRonda` emita su propio
`DESBLOQUEAR_MOVIMIENTO` tras el `task.wait(0.5)`, dejando el flujo de ronda
autocontenido. No se aplicó porque modifica el flujo de partida y requiere
aprobación del autor.

---

## 2026-10-11 — regresiones detectadas tras sincronizar Rojo

- `StaminaService`: Shift permanece como entrada retenida al agotarse. La
  recuperación no empieza hasta soltarlo y transcurrir una breve pausa.
- `ParkourPairs`: cliente y servidor resuelven el mismo par de marcadores por
  cercanía, desnivel y reciprocidad. Evita que un marcador hijo directo de
  Workspace se empareje con la primera ventana del mapa. La acción más cercana
  entre ventana y estrecho tiene prioridad.
- `Controlador1v1`: bate con geometría y mango controlados, vertical respecto
  de la mano, sin depender del pivote del asset público.
- `InterfazJuego1v1`: rol, stamina y vidas se agrupan abajo a la izquierda;
  lobby y mensajes reciben paneles de alto contraste.
- **Verificación:** 22 marcadores del respaldo pasan la comprobación de pares;
  compilación Rojo correcta. Playtest de dos clientes pendiente.
