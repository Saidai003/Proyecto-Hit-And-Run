# Pendientes de juego

Registrados a partir de los últimos playtests del usuario. **No están implementados ni verificados.**

## Escalada

- Corregir la interrupción inesperada del estado de escalada durante subidas largas. Se observó en `Truss`; comprobar también otros objetos escalables y que `Drop Off` / `NoEscalando` reflejen siempre el estado real.
- Permitir la acción de escalada en cualquier objeto que Roblox marque como escalable, no solamente en instancias `TrussPart`. Investigar qué tipos y propiedades concretas utiliza el Place antes de cambiar la detección.
- Hacer que el consumo de stamina sea proporcional a la distancia efectivamente escalada, tanto al subir como al bajar. Evitar cobrar distancia no recorrida y definir/verificar el comportamiento al agotarse la stamina a mitad de la escalada.

## Salto experimental con ALT

- Reducir la altura del salto unos studs para que no permita superar muros y evitar los recorridos de persecución previstos. Probar el ajuste en el mapa antes de fijar una cifra.
- La tecla definitiva de salto sigue siendo una decisión de diseño abierta; ALT continúa siendo solo una prueba.

## Verificación

- Probar estos cambios en el lobby y en partida, en R15, con subida y bajada largas, salida manual con Space, llegada natural al extremo y stamina baja o agotada.
- Confirmar que las acciones de parkour existentes y el indicador contextual no presentan regresiones.
