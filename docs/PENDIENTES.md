# Pendientes de juego

Registrados a partir de los últimos playtests del usuario. **No están implementados ni verificados.**

## Escalada

- Corregir la interrupción inesperada del estado de escalada durante subidas largas. Se observó en `Truss`; comprobar también otros objetos escalables y que `Drop Off` / `NoEscalando` reflejen siempre el estado real.
- Permitir la acción de escalada en cualquier objeto que Roblox marque como escalable, no solamente en instancias `TrussPart`. Investigar qué tipos y propiedades concretas utiliza el Place antes de cambiar la detección.
- Hacer que el consumo de stamina sea proporcional a la distancia efectivamente escalada, tanto al subir como al bajar. Evitar cobrar distancia no recorrida y definir/verificar el comportamiento al agotarse la stamina a mitad de la escalada.

## Salto experimental con ALT

- Reducir la altura del salto unos studs para que no permita superar muros y evitar los recorridos de persecución previstos. Probar el ajuste en el mapa antes de fijar una cifra.
- La tecla definitiva de salto sigue siendo una decisión de diseño abierta; ALT continúa siendo solo una prueba.

## Donación y pantalla de compra

- Investigar la discrepancia observada en una prueba publicada: el producto `Donation` aparece con precio de **75 Robux**, pero, con saldo de **0 Robux**, la ventana `Comprar Robux y objeto` ofrece comprar **500 Robux** y muestra **400 Robux tachados**, lo que parece un descuento incoherente para el jugador.
- Verificar en Creator Dashboard el precio vigente y la configuración regional del Developer Product `3717856374`, y confirmar qué precio muestra el botón del lobby para esa misma cuenta y región. Distinguir el precio del producto de cualquier paquete de Robux que Roblox ofrezca para financiar la compra.
- Si esa oferta de Robux es una interfaz propia de Roblox, evaluar cómo aclarar el precio de la donación antes de abrirla. No cambiar precios ni iniciar compras hasta entender el origen de la discrepancia.

## Verificación

- Probar estos cambios en el lobby y en partida, en R15, con subida y bajada largas, salida manual con Space, llegada natural al extremo y stamina baja o agotada.
- Confirmar que las acciones de parkour existentes y el indicador contextual no presentan regresiones.
