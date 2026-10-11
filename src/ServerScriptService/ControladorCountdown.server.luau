local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")
local EventoCountdown = ReplicatedStorage:WaitForChild("EventoCountdown")

local function iniciarCountdown()
	-- Los jugadores no pueden moverse durante la cuenta atrÃ¡s.
	-- Antes solo se bloqueaba dentro de iniciarRonda, que corre
	-- despuÃ©s de este script, asÃ­ que los 3 segundos quedaban
	-- libres.
	EventoJuego:FireAllClients(
		"BLOQUEAR_MOVIMIENTO"
	)

	for segundos = 3, 1, -1 do
		EventoJuego:FireAllClients("COUNTDOWN", segundos)
		task.wait(1)
	end

	EventoJuego:FireAllClients(
		"DESBLOQUEAR_MOVIMIENTO"
	)

	EventoJuego:FireAllClients("INICIO")
end

EventoCountdown.Event:Connect(iniciarCountdown)