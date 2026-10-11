local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugadorLocal = Players.LocalPlayer
local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")
local EventoSprint = ReplicatedStorage:WaitForChild("Sprint1v1")

local camara = workspace.CurrentCamera


--==================================================
-- CONFIG
--==================================================

local VELOCIDAD_PERSEGUIDO = 16
local VELOCIDAD_PERSEGUIDOR = 18

local STAMINA_PERSEGUIDO = 100
local STAMINA_PERSEGUIDOR = 120

local VELOCIDAD_SPRINT_PERSEGUIDO = 22
local VELOCIDAD_SPRINT_PERSEGUIDOR = 24

local CONSUMO_SPRINT_PERSEGUIDO = 18
local CONSUMO_SPRINT_PERSEGUIDOR = 20

local RECUPERACION_STAMINA = 14

local FOV_NORMAL = 70
local FOV_SPRINT = 76
local CAMERA_DISTANCIA = 12
local zoomMinOriginal = jugadorLocal.CameraMinZoomDistance
local zoomMaxOriginal = jugadorLocal.CameraMaxZoomDistance
local camaraDePartida = false
local cursorOriginal = UserInputService.MouseIconEnabled

local function configurarCamaraDePartida(activa)
	camaraDePartida = activa
	if activa then
		jugadorLocal.CameraMinZoomDistance = CAMERA_DISTANCIA
		jugadorLocal.CameraMaxZoomDistance = CAMERA_DISTANCIA
		UserInputService.MouseIconEnabled = false
	else
		jugadorLocal.CameraMinZoomDistance = zoomMinOriginal
		jugadorLocal.CameraMaxZoomDistance = zoomMaxOriginal
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = cursorOriginal
	end
end

RunService:BindToRenderStep("MatchFreeLook", Enum.RenderPriority.Camera.Value + 1, function()
	if camaraDePartida then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end)

--==================================================
-- STATE
--==================================================

local character = nil
local humanoide = nil

local rolActual = nil

local velocidadBase = VELOCIDAD_PERSEGUIDO
local velocidadSprint = VELOCIDAD_SPRINT_PERSEGUIDO

local staminaMaxima = STAMINA_PERSEGUIDO
local stamina = STAMINA_PERSEGUIDO

local consumoSprint = CONSUMO_SPRINT_PERSEGUIDO

local sprintActivo = false
local movimientoBloqueado = false
local ultimoSaltoAlt = 0

local fovObjetivo = FOV_NORMAL


--==================================================
-- PERSONAJE
--==================================================

local function obtenerPersonaje()

	character = jugadorLocal.Character

	if not character then
		return
	end

	humanoide = character:WaitForChild("Humanoid")

	humanoide.UseJumpPower = true
	humanoide.JumpPower = 0
end


--==================================================
-- ROL
--==================================================

local function configurarRol(rol)

	rolActual = rol

	if rol == "PERSEGUIDOR" then

		velocidadBase = VELOCIDAD_PERSEGUIDOR
		velocidadSprint = VELOCIDAD_SPRINT_PERSEGUIDOR

		staminaMaxima = STAMINA_PERSEGUIDOR
		consumoSprint = CONSUMO_SPRINT_PERSEGUIDOR

	elseif rol == "PERSEGUIDO" then

		velocidadBase = VELOCIDAD_PERSEGUIDO
		velocidadSprint = VELOCIDAD_SPRINT_PERSEGUIDO

		staminaMaxima = STAMINA_PERSEGUIDO
		consumoSprint = CONSUMO_SPRINT_PERSEGUIDO
	end

	stamina = staminaMaxima
	EventoSprint:FireServer(false)

	if humanoide and not movimientoBloqueado then
		humanoide.WalkSpeed = velocidadBase
	end

	print(
		"--- VELOCIDAD --- Rol:",
		rolActual,
		"| Base:",
		velocidadBase,
		"| Sprint:",
		velocidadSprint,
		"| Stamina:",
		staminaMaxima
	)
end


--==================================================
-- SPRINT
--==================================================

local function activarSprint()

	if movimientoBloqueado then
		return
	end

	if stamina < 15 then
		return
	end

	sprintActivo = true
	EventoSprint:FireServer(true)

	if humanoide then
		humanoide.WalkSpeed = velocidadSprint
	end

	fovObjetivo = FOV_SPRINT

	print("--- SPRINT ACTIVADO ---")
end


local function desactivarSprint(informarServidor)

	sprintActivo = false
	if informarServidor ~= false then EventoSprint:FireServer(false) end

	if humanoide and not movimientoBloqueado then
		humanoide.WalkSpeed = velocidadBase
	end

	fovObjetivo = FOV_NORMAL

	print("--- SPRINT DESACTIVADO ---")
end


--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input, procesado)

	if procesado then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		activarSprint()
	elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		if movimientoBloqueado or not humanoide or humanoide.Health <= 0
			or humanoide.FloorMaterial == Enum.Material.Air
			or humanoide:GetAttribute("ParkourEspecialActivo")
			or humanoide:GetAttribute("EscaladaActiva")
			or humanoide:GetAttribute("FallStunned")
			or os.clock() - ultimoSaltoAlt < 0.4 then return end
		ultimoSaltoAlt = os.clock()
		local ok, permitido = pcall(function()
			return ReplicatedStorage:WaitForChild("SolicitarParkour1v1"):InvokeServer("Salto")
		end)
		if ok and permitido and humanoide and humanoide.Parent then
			humanoide.JumpPower = 50
			humanoide.Jump = true
			humanoide:ChangeState(Enum.HumanoidStateType.Jumping)
			task.delay(0.12, function()
				if humanoide and humanoide.Parent then humanoide.JumpPower = 0 end
			end)
		end
	end
end)


UserInputService.InputEnded:Connect(function(input)

	if input.KeyCode == Enum.KeyCode.LeftShift then
		desactivarSprint()
	end
end)


--==================================================
-- HEARTBEAT
--==================================================

RunService.Heartbeat:Connect(function(deltaTime)

	if not humanoide then
		return
	end

	if movimientoBloqueado then
		return
	end


	-- STAMINA

	stamina = jugadorLocal:GetAttribute("Stamina") or stamina
	if sprintActivo and stamina <= 0 then
		desactivarSprint(false)
	end


	-- VELOCIDAD

	if not humanoide:GetAttribute("ParkourEspecialActivo")
		and not humanoide:GetAttribute("Inmovilizado")
		and not humanoide:GetAttribute("FallStunned") then
		local velocidad = sprintActivo and velocidadSprint or velocidadBase
		if humanoide:GetAttribute("EscaladaActiva") and humanoide:GetAttribute("EscaladaLenta") then
			velocidad *= 0.7
		end
		humanoide.WalkSpeed = velocidad
	end


	-- FOV

	camara.FieldOfView =
		camara.FieldOfView
		+ (fovObjetivo - camara.FieldOfView)
		* math.min(deltaTime * 10, 1)
end)


--==================================================
-- SERVER EVENTS
--==================================================

EventoJuego.OnClientEvent:Connect(function(estado, datos)

	if estado == "ROL" then

		configurarRol(datos)

		configurarCamaraDePartida(true)

	elseif estado == "ESPERANDO_JUGADOR" or estado == "RESULTADO_FINAL" then
		configurarCamaraDePartida(false)


	elseif estado == "BLOQUEAR_MOVIMIENTO" then

		movimientoBloqueado = true
		sprintActivo = false
		EventoSprint:FireServer(false)

		fovObjetivo = FOV_NORMAL

		if humanoide then
			humanoide.WalkSpeed = 0
		end


	elseif estado == "DESBLOQUEAR_MOVIMIENTO" then

		movimientoBloqueado = false

		if humanoide then
			humanoide.WalkSpeed = velocidadBase
		end


	elseif estado == "RESET_JUGADOR" then

		sprintActivo = false
		EventoSprint:FireServer(false)

		stamina = staminaMaxima

		fovObjetivo = FOV_NORMAL
		camara.FieldOfView = FOV_NORMAL

		if humanoide then

	
			humanoide.WalkSpeed =
				velocidadBase
		end
	end
end)


--==================================================
-- RESPAWN
--==================================================

jugadorLocal.CharacterAdded:Connect(function(nuevoCharacter)

	character = nuevoCharacter

	humanoide =
		nuevoCharacter:WaitForChild("Humanoid")

	humanoide.UseJumpPower = true
	humanoide.JumpPower = 0

	-- El servidor pudo bloquear el movimiento del
	-- personaje anterior (pale, stun). Ese flag es
	-- local, asi que hay que liberarlo al reaparecer
	-- o el jugador respawna congelado.
	movimientoBloqueado = false

	sprintActivo = false
	EventoSprint:FireServer(false)

	stamina = staminaMaxima

	fovObjetivo = FOV_NORMAL

	camara.FieldOfView = FOV_NORMAL


	humanoide.WalkSpeed =
		velocidadBase

	if not camaraDePartida then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)


--==================================================
-- START
--==================================================

obtenerPersonaje()
