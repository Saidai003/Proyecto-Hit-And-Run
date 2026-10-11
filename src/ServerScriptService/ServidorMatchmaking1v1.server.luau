local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Crear el evento si no existe
local EventoMatchmaking = ReplicatedStorage:FindFirstChild("EventoMatchmaking")
if not EventoMatchmaking then
	EventoMatchmaking = Instance.new("RemoteEvent")
	EventoMatchmaking.Name = "EventoMatchmaking"
	EventoMatchmaking.Parent = ReplicatedStorage
end

-- Escuchar cuando un jugador presiona "PLAY NOW!"
EventoMatchmaking.OnServerEvent:Connect(function(jugador, accion)
	if accion == "BUSCAR_PARTIDA" then

		-- Le asignamos el atributo de que estÃ¡ buscando partida
		jugador:SetAttribute("BuscandoPartida", true)
		print("[MATCHMAKING] El jugador", jugador.Name, "estÃ¡ listo para jugar.")

		-- Avisar a la interfaz del jugador para que cambie a "Waiting for opponent..."
		local EventoJuego = ReplicatedStorage:FindFirstChild("EventoJuego")
		if EventoJuego then
			EventoJuego:FireClient(jugador, "ESPERANDO_JUGADOR")
		end
	end
end)

-- Limpiar el atributo si el jugador sale (aunque Roblox lo destruye, es buena prÃ¡ctica)
Players.PlayerRemoving:Connect(function(jugador)
	jugador:SetAttribute("BuscandoPartida", nil)
end)