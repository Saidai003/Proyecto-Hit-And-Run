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
local ultimoSalto = 0
local solicitudSalto = 0
local BUFFER_SALTO = 0.4
local COOLDOWN_SALTO = 0.2

local function establecerSprintActivo(activo)
	sprintActivo = activo
	if humanoide and humanoide.Parent then
		humanoide:SetAttribute("SprintActivoLocal", activo)
	end
end

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
	establecerSprintActivo(false)
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
	if humanoide and humanoide:GetAttribute("Sliding") then return end

	if stamina < 15 then
		return
	end

	establecerSprintActivo(true)
	EventoSprint:FireServer(true)

	if humanoide then
		humanoide.WalkSpeed = velocidadSprint
	end

	fovObjetivo = FOV_SPRINT

	print("--- SPRINT ACTIVADO ---")
end


local function desactivarSprint(informarServidor)

	establecerSprintActivo(false)
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

local function tocaSueloLocal()
	if not character or not humanoide then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local alcance = humanoide.HipHeight + root.Size.Y * 0.5 + 1.15
	return workspace:Raycast(root.Position, Vector3.new(0, -alcance, 0), params) ~= nil
end

local function intentarSalto()
	if movimientoBloqueado or not humanoide or humanoide.Health <= 0
		or humanoide:GetAttribute("Sliding")
		or not tocaSueloLocal()
		or humanoide:GetAttribute("ParkourEspecialActivo")
		or humanoide:GetAttribute("EscaladaActiva")
		or humanoide:GetAttribute("FallStunned")
		or os.clock() - ultimoSalto < COOLDOWN_SALTO then return false end
	local ok, permitido = pcall(function()
		return ReplicatedStorage:WaitForChild("SolicitarParkour1v1"):InvokeServer("Salto")
	end)
	if not ok or not permitido or not humanoide or not humanoide.Parent then return false end
	-- El cooldown empieza solo cuando el servidor acepta el salto. Antes, un
	-- intento hecho en el primer frame del aterrizaje bloqueaba el siguiente.
	ultimoSalto = os.clock()
	humanoide.JumpPower = 40
	humanoide.Jump = true
	humanoide:ChangeState(Enum.HumanoidStateType.Jumping)
	local humanoideDelSalto = humanoide
	task.delay(0.12, function()
		if humanoideDelSalto.Parent then humanoideDelSalto.JumpPower = 0 end
	end)
	return true
end

local function solicitarSaltoConBuffer()
	solicitudSalto += 1
	local estaSolicitud = solicitudSalto
	local limite = os.clock() + BUFFER_SALTO
	task.spawn(function()
		repeat
			if estaSolicitud ~= solicitudSalto then return end
			if intentarSalto() then return end
			RunService.Heartbeat:Wait()
		until os.clock() >= limite
	end)
end

UserInputService.InputBegan:Connect(function(input, procesado)

	if procesado then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		activarSprint()
	elseif input.KeyCode == Enum.KeyCode.Space then
		solicitarSaltoConBuffer()
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
	if humanoide:GetAttribute("Sliding") and sprintActivo then
		desactivarSprint(false)
	end
	if sprintActivo and stamina <= 0 then
		desactivarSprint(false)
	end


	-- VELOCIDAD

	if not humanoide:GetAttribute("ParkourEspecialActivo")
		and not humanoide:GetAttribute("Sliding")
		and not humanoide:GetAttribute("Inmovilizado")
		and not humanoide:GetAttribute("FallStunned") then
		local velocidad = sprintActivo and velocidadSprint or velocidadBase
		if humanoide:GetAttribute("EscaladaActiva") and humanoide:GetAttribute("EscaladaLenta") then
			velocidad *= 0.7
		end
		if humanoide:GetAttribute("AttackRecovery") or humanoide:GetAttribute("AttackRecoveryLocal") then
			velocidad *= 0.4
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
		establecerSprintActivo(false)
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

		establecerSprintActivo(false)
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
	solicitudSalto += 1
	ultimoSalto = 0

	establecerSprintActivo(false)
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
