local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")
local EventoCountdown = ReplicatedStorage:WaitForChild("EventoCountdown")
local EventoAtaque = ReplicatedStorage:WaitForChild("EventoAtaque")
local EventoHit1v1 = ReplicatedStorage:WaitForChild("EventoHit1v1")
local EventoMatchmaking = ReplicatedStorage:FindFirstChild("EventoMatchmaking")
if not EventoMatchmaking then
	EventoMatchmaking = Instance.new("RemoteEvent")
	EventoMatchmaking.Name = "EventoMatchmaking"
	EventoMatchmaking.Parent = ReplicatedStorage
end

local RoundSpawn1 = Workspace:WaitForChild("RoundSpawn1")
local RoundSpawn2 = Workspace:WaitForChild("RoundSpawn2")


--==================================================
-- CONFIGURACIÃN
--==================================================

local ES_SERVIDOR_PARTIDA = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local datosPartida = nil
local TIEMPO_ESPERA_RIVAL = 60

local CANTIDAD_RONDAS = 6
local DURACION_ENTRE_RONDAS = 2
local TIEMPO_MAXIMO_RONDA = 120
local TIEMPO_RESULTADO_FINAL = 5

local VELOCIDAD_PERSEGUIDOR = 20
local VELOCIDAD_PERSEGUIDO = 16

local VIDAS_INICIALES = 3
local DISTANCIA_ATAQUE = 6
local COOLDOWN_ATAQUE = 1
local DISTANCIA_BATE = 8
local COOLDOWN_BATE = 1.8


--==================================================
-- ESTADO
--==================================================

local EstadoPartida = "ESPERANDO_JUGADORES"

local jugador1 = nil
local jugador2 = nil
local jugadoresEnCola = {}

local rondaActual = 0

local perseguidor = nil
local perseguido = nil

local tiempoInicioRonda = 0
local ataquesHabilitados = false

local tiemposAcumulados = {}
local vidas = {}
local ultimoAtaque = {}


--==================================================
-- ATAQUES / ESTADO DE RONDA
--==================================================

local function establecerAtaques(valor)

	ataquesHabilitados = valor

	Workspace:SetAttribute("RondaEnJuego", valor)
end


--==================================================
-- UTILIDADES
--==================================================

local function obtenerHumanoide(jugador)

	if not jugador then
		return nil
	end

	local character = jugador.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end


local function obtenerHRP(jugador)

	if not jugador then
		return nil
	end

	local character = jugador.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end


local function establecerVelocidad(jugador, velocidad)

	local humanoide = obtenerHumanoide(jugador)

	if humanoide then
		humanoide.WalkSpeed = velocidad
	end
end


local function prepararJugador(jugador)

	if not jugador or not jugador.Parent then
		return
	end

	local character = jugador.Character

	if not character then
		character = jugador.CharacterAdded:Wait()
	end

	character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
end


local function jugadoresPresentes()

	return jugador1 ~= nil
		and jugador2 ~= nil
		and jugador1.Parent ~= nil
		and jugador2.Parent ~= nil
end


--==================================================
-- VOLVER AL LOBBY
--==================================================

local function volverAlLobby(listaJugadores)

	if RunService:IsStudio() or not ES_SERVIDOR_PARTIDA or #listaJugadores == 0 then
		return false
	end

	local opciones = Instance.new("TeleportOptions")
	local origen = datosPartida and datosPartida.originJobId
	if typeof(origen) == "string" and origen ~= "" then
		opciones.ServerInstanceId = origen
	end

	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, listaJugadores, opciones)
	end)
	if ok then return true end

	warn("[Partida] Lobby original unavailable; using a public lobby: ", err)
	local fallbackOk, fallbackErr = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, listaJugadores)
	end)
	if not fallbackOk then
		warn("[Partida] Could not return to lobby: ", fallbackErr)
		EventoJuego:FireAllClients("ERROR_LOBBY", "Could not return to the lobby. Please try again.")
	end
	return fallbackOk
end

local function enviarAPartidaPrivada(primero, segundo)
	local opciones = Instance.new("TeleportOptions")
	opciones.ShouldReserveServer = true
	opciones:SetTeleportData({
		match1v1 = true,
		originJobId = game.JobId,
		player1 = primero.UserId,
		player2 = segundo.UserId,
	})
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, {primero, segundo}, opciones)
	end)
	if not ok then
		warn("[MATCHMAKING] Private match teleport failed: ", err)
		for _, jugador in ipairs({primero, segundo}) do
			if jugador.Parent == Players then
				EventoJuego:FireClient(jugador, "ERROR_LOBBY", "Could not start the match. Please try again.")
				EventoMatchmaking:FireClient(jugador, "ERROR")
			end
		end
	end
	return ok
end

TeleportService.TeleportInitFailed:Connect(function(jugador, resultado, mensaje)
	if jugador.Parent == Players then
		warn("[Teleport] ", jugador.Name, resultado, mensaje)
		EventoMatchmaking:FireClient(jugador, "ERROR")
	end
end)


--==================================================
-- TELETRANSPORTE
--==================================================

local function transportarJugadores()

	prepararJugador(jugador1)
	prepararJugador(jugador2)

	local hrp1 = obtenerHRP(jugador1)
	local hrp2 = obtenerHRP(jugador2)

	if hrp1 then

		hrp1.CFrame =
			RoundSpawn1.CFrame
			+ Vector3.new(0, 3, 0)

	end

	if hrp2 then

		hrp2.CFrame =
			RoundSpawn2.CFrame
			+ Vector3.new(0, 3, 0)

	end
end


--==================================================
-- ASIGNAR ROLES
--==================================================

local function retirarBate(jugador)
	for _, contenedor in ipairs({jugador.Character, jugador:FindFirstChildOfClass("Backpack")}) do
		if contenedor then
			for _, item in ipairs(contenedor:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("AttackKind") == "Bat" then
					item:Destroy()
				end
			end
		end
	end
end

local function entregarBate(jugador)
	local mochila = jugador:FindFirstChildOfClass("Backpack")
	local humanoide = obtenerHumanoide(jugador)
	if not mochila or not humanoide then
		warn("[Bat] Missing backpack or humanoid for ", jugador.Name)
		return
	end
	local herramienta = Instance.new("Tool")
	herramienta.Name = "Baseball Bat"
	herramienta.CanBeDropped = false
	herramienta.RequiresHandle = true
	herramienta:SetAttribute("AttackKind", "Bat")
	-- The hand holds the lower end of a vertical bat. We avoid the public
	-- model's unknown pivot, which previously displaced it to the right.
	herramienta.Grip = CFrame.identity
	local mango = Instance.new("Part")
	mango.Name = "Handle"
	mango.Size = Vector3.new(0.32, 1.1, 0.32)
	mango.Transparency = 1
	mango.CanCollide = false
	mango.CanTouch = false
	mango.Massless = true
	mango.Parent = herramienta
	local function agregarParte(nombre, largo, diametro, color, altura)
		local parte = Instance.new("Part")
		parte.Name = nombre
		parte.Shape = Enum.PartType.Cylinder
		parte.Size = Vector3.new(largo, diametro, diametro)
		parte.Color = color
		parte.Material = Enum.Material.Wood
		parte.CanCollide = false
		parte.CanTouch = false
		parte.Massless = true
		-- Roblox cylinders are long along local X; turn X onto the handle's Y.
		parte.CFrame = mango.CFrame * CFrame.new(0, altura, 0)
			* CFrame.Angles(0, 0, math.rad(90))
		parte.Parent = herramienta
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = mango
		soldadura.Part1 = parte
		soldadura.Parent = parte
	end
	agregarParte("GripVisual", 1.1, 0.32, Color3.fromRGB(66, 43, 31), 0)
	agregarParte("Barrel", 2.05, 0.62, Color3.fromRGB(171, 110, 57), 1.55)
	agregarParte("Pommel", 0.18, 0.44, Color3.fromRGB(55, 36, 26), -0.62)
	herramienta.Parent = mochila
	humanoide:EquipTool(herramienta)
end

local function asignarRoles()

	if rondaActual % 2 == 1 then

		perseguido = jugador1
		perseguidor = jugador2

	else

		perseguido = jugador2
		perseguidor = jugador1

	end

	perseguido:SetAttribute("Rol", "PERSEGUIDO")
	perseguidor:SetAttribute("Rol", "PERSEGUIDOR")
	retirarBate(perseguido)
	retirarBate(perseguidor)

	establecerVelocidad(
		perseguido,
		VELOCIDAD_PERSEGUIDO
	)

	establecerVelocidad(
		perseguidor,
		VELOCIDAD_PERSEGUIDOR
	)

	local perseguidorDaRonda = perseguidor
	entregarBate(perseguidorDaRonda)
	for _, jugador in ipairs({perseguido, perseguidorDaRonda}) do
		task.spawn(function()
			local character = jugador.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			local ok, err = pcall(function()
				local desc = humanoid:GetAppliedDescription()
					or Instance.new("HumanoidDescription")
				if jugador == perseguidorDaRonda then
					desc.HeightScale = 1.25
					desc.WidthScale = 1.25
					desc.HeadScale = 1.15
				else
					desc.HeightScale = 1
					desc.WidthScale = 1
					desc.HeadScale = 1
				end
				humanoid:ApplyDescription(desc)
			end)
			if not ok then warn("[Roles] Appearance could not be applied: ", err) end
			if jugador == perseguidorDaRonda and perseguidor == perseguidorDaRonda
				and jugador:GetAttribute("Rol") == "PERSEGUIDOR" then
				local characterActual = jugador.Character
				local mochila = jugador:FindFirstChildOfClass("Backpack")
				local tieneBate = (characterActual and characterActual:FindFirstChild("Baseball Bat"))
					or (mochila and mochila:FindFirstChild("Baseball Bat"))
				if not tieneBate then entregarBate(jugador) end
			end
		end)
	end

	print("----------------------------------------")
	print("RONDA " .. rondaActual)
	print("Perseguido: " .. perseguido.Name)
	print("Perseguidor: " .. perseguidor.Name)
	print("----------------------------------------")

	EventoJuego:FireClient(
		perseguidor,
		"ROL",
		"PERSEGUIDOR"
	)

	EventoJuego:FireClient(
		perseguido,
		"ROL",
		"PERSEGUIDO"
	)

	EventoJuego:FireAllClients(
		"RONDA",
		rondaActual
	)

	EventoJuego:FireClient(
		perseguido,
		"VIDAS",
		vidas[perseguido]
	)

	-- El perseguidor ve las vidas del RIVAL (las del
	-- perseguido), no las propias, para que sepa cuan
	-- cerca esta de ganar.
	EventoJuego:FireClient(
		perseguidor,
		"VIDAS_RIVAL",
		vidas[perseguido]
	)

	EventoJuego:FireClient(
		perseguidor,
		"ATAQUE_DISPONIBLE"
	)
end


--==================================================
-- FUNCIONES DE COLA
--==================================================

local function jugadorEstaEnCola(jugador)

	for _, jugadorEnCola in ipairs(jugadoresEnCola) do

		if jugadorEnCola == jugador then
			return true
		end

	end

	return false
end


local function sacarDeLaCola(jugador)

	for i, jugadorEnCola in ipairs(jugadoresEnCola) do

		if jugadorEnCola == jugador then

			table.remove(jugadoresEnCola, i)
			return

		end

	end
end


local function agregarALaCola(jugador)

	if jugadorEstaEnCola(jugador) then
		return
	end

	table.insert(jugadoresEnCola, jugador)

	print("[MATCHMAKING]: " .. jugador.Name .. " entro a la cola.")

	EventoJuego:FireClient(
		jugador,
		"ESPERANDO_JUGADOR"
	)
	EventoMatchmaking:FireClient(jugador, "EN_COLA")
end


--==================================================
-- EVENTO MATCHMAKING
--==================================================

EventoMatchmaking.OnServerEvent:Connect(function(jugador, accion)
	if ES_SERVIDOR_PARTIDA and not RunService:IsStudio() then return end
	if accion == "BUSCAR" or accion == "BUSCAR_PARTIDA" then
		agregarALaCola(jugador)
	elseif accion == "CANCELAR" then
		sacarDeLaCola(jugador)
		EventoMatchmaking:FireClient(jugador, "FUERA_DE_COLA")
	end

end)


--==================================================
-- ESPERAR JUGADORES
--==================================================

local function esperarJugadores()

	EstadoPartida = "ESPERANDO_JUGADORES"
	if ES_SERVIDOR_PARTIDA and not RunService:IsStudio() then
		local limite = os.clock() + TIEMPO_ESPERA_RIVAL
		while os.clock() < limite do
			for _, jugador in ipairs(Players:GetPlayers()) do
				local joinData = jugador:GetJoinData()
				local data = joinData and joinData.TeleportData
				if joinData.SourcePlaceId == game.PlaceId
					and typeof(data) == "table" and data.match1v1 == true
					and typeof(data.player1) == "number" and typeof(data.player2) == "number"
					and typeof(data.originJobId) == "string" then
					datosPartida = data
					break
				end
			end
			if datosPartida then
				jugador1 = Players:GetPlayerByUserId(datosPartida.player1)
				jugador2 = Players:GetPlayerByUserId(datosPartida.player2)
				if jugadoresPresentes() then return true end
			end
			task.wait(0.5)
		end
		return false
	end

	print("[MATCHMAKING]: Esperando dos jugadores en cola...")

	while true do

		for i = #jugadoresEnCola, 1, -1 do

			local jugador = jugadoresEnCola[i]

			if jugador.Parent ~= Players then
				table.remove(jugadoresEnCola, i)
			end

		end

		if #jugadoresEnCola >= 2 then

			jugador1 = jugadoresEnCola[1]
			jugador2 = jugadoresEnCola[2]

			table.remove(jugadoresEnCola, 1)
			table.remove(jugadoresEnCola, 1)

			print(
				"[MATCHMAKING]: Partida encontrada:",
				jugador1.Name,
				"vs",
				jugador2.Name
			)
			EventoMatchmaking:FireClient(jugador1, "ENCONTRADO")
			EventoMatchmaking:FireClient(jugador2, "ENCONTRADO")

			return true
		end

		task.wait(0.5)
	end
end


--==================================================
-- INICIAR RONDA
--==================================================

local function iniciarRonda()

	EstadoPartida = "RONDA_ACTIVA"

	establecerAtaques(false)

	Workspace:SetAttribute(
		"IdRonda",
		(Workspace:GetAttribute("IdRonda") or 0) + 1
	)

	vidas[jugador1] = VIDAS_INICIALES
	vidas[jugador2] = VIDAS_INICIALES

	transportarJugadores()

	asignarRoles()

	EventoJuego:FireAllClients(
		"BLOQUEAR_MOVIMIENTO"
	)

	task.wait(0.5)

	tiempoInicioRonda = os.clock()

	print(
		"RONDA "
			.. rondaActual
			.. " INICIADA"
	)
end


--==================================================
-- FINALIZAR RONDA
--==================================================

local function finalizarRonda(motivo)

	if EstadoPartida ~= "RONDA_ACTIVA" then
		return
	end

	EstadoPartida = "FINALIZANDO_RONDA"

	establecerAtaques(false)

	local tiempoRonda =
		os.clock() - tiempoInicioRonda

	if perseguido then

		tiemposAcumulados[perseguido] =
			(tiemposAcumulados[perseguido] or 0)
			+ tiempoRonda

	end

	EventoJuego:FireAllClients(
		"DESBLOQUEAR_MOVIMIENTO"
	)

	EventoJuego:FireAllClients(
		"RESULTADO_RONDA",
		motivo
	)

	print("")
	print("========================================")
	print("FIN DE LA RONDA")
	print("Motivo: " .. motivo)

	print(
		string.format(
			"Tiempo: %.3f segundos",
			tiempoRonda
		)
	)

	print("========================================")
end


--==================================================
-- COMANDO TEMPORAL DE PRUEBA
--==================================================

_G.FinalizarRondaAhora = function()

	if EstadoPartida == "RONDA_ACTIVA" then

		finalizarRonda("PRUEBA")

	else

		warn(
			"No hay una ronda activa. Estado actual: "
				.. tostring(EstadoPartida)
		)

	end
end


--==================================================
-- ATAQUE
--==================================================

local function atacar(jugador)

	if EstadoPartida ~= "RONDA_ACTIVA" then
		return
	end

	if not ataquesHabilitados then
		return
	end

	if jugador ~= perseguidor then
		return
	end

	if not perseguido then
		return
	end

	local humanoideAtacante =
		obtenerHumanoide(jugador)

	if humanoideAtacante
		and (humanoideAtacante:GetAttribute("Inmovilizado")
			or humanoideAtacante:GetAttribute("FallStunned")) then

		return
	end

	local ahora = os.clock()
	local herramienta = jugador.Character and jugador.Character:FindFirstChildOfClass("Tool")
	if herramienta and herramienta:GetAttribute("Throwable") then return end
	local usaBate = herramienta and herramienta:GetAttribute("AttackKind") == "Bat"
	local cooldown = usaBate and COOLDOWN_BATE or COOLDOWN_ATAQUE
	local alcance = usaBate and DISTANCIA_BATE or DISTANCIA_ATAQUE

	if ultimoAtaque[jugador] and ahora < ultimoAtaque[jugador] then

		return
	end

	ultimoAtaque[jugador] = ahora + cooldown

	local hrpPerseguidor =
		obtenerHRP(perseguidor)

	local hrpPerseguido =
		obtenerHRP(perseguido)

	if not hrpPerseguidor
		or not hrpPerseguido then

		return
	end

	local distancia =
		(
			hrpPerseguidor.Position
			- hrpPerseguido.Position
		).Magnitude

	if distancia > alcance then
		return
	end

	vidas[perseguido] -= 1

	print(
		perseguidor.Name
			.. " golpeÃ³ a "
			.. perseguido.Name
			.. " | Vidas: "
			.. vidas[perseguido]
	)

	EventoHit1v1:FireAllClients(
		"HIT",
		perseguidor,
		perseguido,
		vidas[perseguido]
	)

	EventoJuego:FireClient(
		perseguido,
		"VIDAS",
		vidas[perseguido]
	)

	-- Mantener al perseguidor al tanto de las vidas
	-- restantes del rival despuÃ©s de cada golpe.
	EventoJuego:FireClient(
		perseguidor,
		"VIDAS_RIVAL",
		vidas[perseguido]
	)

	if vidas[perseguido] <= 0 then

		finalizarRonda("DERROTA")

	end
end


EventoAtaque.OnServerEvent:Connect(atacar)

-- Measure the actual server-observed drop after any parkour endpoint.
-- Only the pursued player's round lives can be reduced by a fall.
local UMBRAL_ATURDIMIENTO_CAIDA = 12
local UMBRAL_DANO_CAIDA = 25
local registroCaidas = {}

RunService.Heartbeat:Connect(function()
	if EstadoPartida ~= "RONDA_ACTIVA" or not ataquesHabilitados then
		table.clear(registroCaidas)
		return
	end
	for _, jugador in ipairs({jugador1, jugador2}) do
		if jugador and jugador.Parent == Players then
			local humanoide = obtenerHumanoide(jugador)
			local root = obtenerHRP(jugador)
			if humanoide and root and humanoide.Health > 0 then
				local registro = registroCaidas[jugador]
				if humanoide.FloorMaterial == Enum.Material.Air then
					if not registro or registro.character ~= jugador.Character then
						registroCaidas[jugador] = {character = jugador.Character, maxY = root.Position.Y}
					else
						registro.maxY = math.max(registro.maxY, root.Position.Y)
					end
				elseif registro then
					registroCaidas[jugador] = nil
					local caida = registro.maxY - root.Position.Y
					if caida >= UMBRAL_ATURDIMIENTO_CAIDA
						and not jugador.Character:GetAttribute("KnockedOut") then
						local duracion = math.clamp(0.4 + (caida - UMBRAL_ATURDIMIENTO_CAIDA) * 0.04, 0.4, 2.5)
						humanoide:SetAttribute("FallStunned", true)
						humanoide.PlatformStand = true
						task.delay(duracion, function()
							if humanoide.Parent and humanoide:GetAttribute("FallStunned") then
								if not humanoide:GetAttribute("Inmovilizado")
									and not jugador.Character:GetAttribute("KnockedOut") then
									humanoide.PlatformStand = false
									humanoide:ChangeState(Enum.HumanoidStateType.GettingUp)
								end
								humanoide:SetAttribute("FallStunned", nil)
							end
						end)
						if jugador == perseguido and caida >= UMBRAL_DANO_CAIDA then
							local dano = math.max(1, math.floor((caida - UMBRAL_DANO_CAIDA) / 15) + 1)
							vidas[jugador] = math.max(0, (vidas[jugador] or 0) - dano)
							EventoJuego:FireClient(jugador, "VIDAS", vidas[jugador])
							if perseguidor and perseguidor.Parent == Players then
								EventoJuego:FireClient(perseguidor, "VIDAS_RIVAL", vidas[jugador])
							end
							if vidas[jugador] <= 0 then finalizarRonda("DERROTA") end
						end
					end
				end
			end
		end
	end
end)


--==================================================
-- ESPERAR FIN DE RONDA
--==================================================

local function esperarFinDeRonda()

	while EstadoPartida == "RONDA_ACTIVA" do

		local tiempoTranscurrido =
			os.clock() - tiempoInicioRonda

		if tiempoTranscurrido >= TIEMPO_MAXIMO_RONDA then

			finalizarRonda(
				"Time limit reached"
			)

			return
		end

		if not jugadoresPresentes() then

			finalizarRonda(
				"A player abandoned the match"
			)

			return
		end

		task.wait(0.1)
	end
end


--==================================================
-- RESULTADO FINAL
--==================================================

local function mostrarResultadoFinal()

	EstadoPartida = "RESULTADO_FINAL"

	local tiempo1 =
		tiemposAcumulados[jugador1] or 0

	local tiempo2 =
		tiemposAcumulados[jugador2] or 0

	local ganador

	if tiempo1 < tiempo2 then

		ganador = jugador1

	elseif tiempo2 < tiempo1 then

		ganador = jugador2

	else

		ganador = nil
	end

	local resultado = {

		jugador1 = jugador1,
		jugador2 = jugador2,

		nombre1 = jugador1.Name,
		nombre2 = jugador2.Name,

		tiempo1 = tiempo1,
		tiempo2 = tiempo2,

		ganador = ganador and ganador.Name or nil
	}

	EventoJuego:FireAllClients(
		"RESULTADO_FINAL",
		resultado
	)

	task.wait(TIEMPO_RESULTADO_FINAL)
end

-- ============================================================
-- COMANDOS DE PRUEBA: FORZAR ROL EN SINGLE PLAYER
-- ============================================================

_G.ForzarRol = function(rol)

	local jugador = Players:GetPlayers()[1]

	if not jugador then
		warn("No hay ningÃºn jugador.")
		return
	end

	local personaje = jugador.Character
	local humanoide = obtenerHumanoide(jugador)

	if not personaje or not humanoide then
		warn("El jugador no tiene un personaje vÃ¡lido.")
		return
	end

	if rol == "PERSEGUIDO" then

		jugador:SetAttribute("Rol", "PERSEGUIDO")

		establecerVelocidad(
			jugador,
			VELOCIDAD_PERSEGUIDO
		)

		perseguido = jugador
		perseguidor = nil

		print("[PRUEBA] Rol asignado: PERSEGUIDO")

	elseif rol == "PERSEGUIDOR" then

		jugador:SetAttribute("Rol", "PERSEGUIDOR")

		establecerVelocidad(
			jugador,
			VELOCIDAD_PERSEGUIDOR
		)

		perseguidor = jugador
		perseguido = nil

		print("[PRUEBA] Rol asignado: PERSEGUIDOR")

	else

		warn("Rol invÃ¡lido. Usa PERSEGUIDO o PERSEGUIDOR.")
	end
end

--==================================================
-- LOOP PRINCIPAL
--==================================================

while true do

	local listo = esperarJugadores()

	if not listo then

		print(
			"El rival no llegÃ³. Volviendo al lobby..."
		)

		if volverAlLobby(Players:GetPlayers()) then
			break
		end

		continue
	end

	if not ES_SERVIDOR_PARTIDA and not RunService:IsStudio() then
		enviarAPartidaPrivada(jugador1, jugador2)
		jugador1 = nil
		jugador2 = nil
		continue
	end

	prepararJugador(jugador1)
	prepararJugador(jugador2)

	rondaActual = 0

	perseguidor = nil
	perseguido = nil

	tiemposAcumulados = {}
	vidas = {}
	ultimoAtaque = {}

	-- El desbloqueo de la ronda anterior deja al
	-- cliente libre al inicio de la PRIMERA cuenta
	-- atrÃ¡s. Reforzamos el BLOQUEAR desde aquÃ­ para
	-- eliminar la carrera con el BLOQUEAR del
	-- ControladorCountdown.
	EventoJuego:FireAllClients(
		"BLOQUEAR_MOVIMIENTO"
	)

	EventoCountdown:Fire()

	task.wait(4)


	--==================================================
	-- RONDAS
	--==================================================

	for numeroRonda = 1, CANTIDAD_RONDAS do

		if not jugadoresPresentes() then
			break
		end

		rondaActual = numeroRonda

		prepararJugador(jugador1)
		prepararJugador(jugador2)

		iniciarRonda()

		EventoCountdown:Fire()

		task.wait(4)

		EventoJuego:FireAllClients(
			"DESBLOQUEAR_MOVIMIENTO"
		)

		establecerAtaques(true)

		esperarFinDeRonda()

		task.wait(DURACION_ENTRE_RONDAS)
	end


	--==================================================
	-- FIN DE PARTIDA
	--==================================================

	establecerAtaques(false)

	mostrarResultadoFinal()

	print("")
	print("La partida ha terminado.")
	print("Volviendo al lobby...")

	-- El resultado deja de mostrarse Ãºnicamente
	-- cuando realmente terminÃ³ el tiempo del modal.
	EventoJuego:FireAllClients(
		"OCULTAR_RESULTADO"
	)

	task.wait(1)

	if volverAlLobby(Players:GetPlayers()) then
		break
	end


	--==================================================
	-- REINICIO EN STUDIO
	--==================================================

	jugador1 = nil
	jugador2 = nil

	perseguidor = nil
	perseguido = nil

	EstadoPartida = "ESPERANDO_JUGADORES"
end
