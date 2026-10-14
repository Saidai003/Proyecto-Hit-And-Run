local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local MobileInput = require(ReplicatedStorage:WaitForChild("MobileInput"))

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
local ANIMACION_SPRINT_ID = "rbxassetid://72846871061644"
local VELOCIDAD_REFERENCIA_ANIMACION_SPRINT = 22
local CAMERA_DISTANCIA = 11.5
local CAMERA_RETORNO_TAU = 0.45
local CAMERA_RADIO_COLISION = 0.3
local CAMERA_MARGEN_COLISION = 0.15
local zoomMinOriginal = jugadorLocal.CameraMinZoomDistance
local zoomMaxOriginal = jugadorLocal.CameraMaxZoomDistance
local camaraDePartida = false
local distanciaVisualActual = nil
local personajeFiltradoCamara = nil
local parametrosColisionCamara = RaycastParams.new()
parametrosColisionCamara.FilterType = Enum.RaycastFilterType.Exclude
parametrosColisionCamara.RespectCanCollide = true
parametrosColisionCamara.IgnoreWater = true
local cursorOriginal = UserInputService.MouseIconEnabled

local function configurarCamaraDePartida(activa)
	camaraDePartida = activa
	distanciaVisualActual = nil
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
	if camaraDePartida and not UserInputService.TouchEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end)

-- La camara predeterminada se acerca inmediatamente a las paredes. Al salir
-- de un espacio estrecho, suavizamos solo el regreso a la distancia libre.
-- Tambien funciona en lobby, sin cambiar su zoom ni su control de raton.
-- Se aplica despues de la camara de Roblox y del offset de apuntar la silla.
RunService:BindToRenderStep("MatchCameraReturn", Enum.RenderPriority.Camera.Value + 2, function(dt)
	local camera = workspace.CurrentCamera
	if not camera or camera.CameraType ~= Enum.CameraType.Custom then
		distanciaVisualActual = nil
		return
	end

	local objetivo = camera.CFrame
	local foco = camera.Focus.Position
	local vector = objetivo.Position - foco
	local distanciaDisponible = vector.Magnitude
	if distanciaDisponible < 0.05 then
		distanciaVisualActual = nil
		return
	end
	local direccion = vector.Unit
	local personaje = jugadorLocal.Character
	if personaje ~= personajeFiltradoCamara then
		personajeFiltradoCamara = personaje
		parametrosColisionCamara.FilterDescendantsInstances = personaje and { personaje } or {}
	end
	-- Roblox puede tardar un fotograma en acercar la camara mientras el jugador
	-- retrocede contra una pared. Comprobamos el espacio libre cada fotograma.
	local obstaculo = workspace:Spherecast(
		foco,
		CAMERA_RADIO_COLISION,
		direccion * distanciaDisponible,
		parametrosColisionCamara
	)
	if obstaculo then
		distanciaDisponible = math.min(
			distanciaDisponible,
			math.max(0.05, obstaculo.Distance - CAMERA_MARGEN_COLISION)
		)
	end

	if not distanciaVisualActual or distanciaDisponible <= distanciaVisualActual then
		-- Si aparece una pared, no permitimos que la camara la atraviese.
		distanciaVisualActual = distanciaDisponible
	else
		local alfa = 1 - math.exp(-math.max(0, dt) / CAMERA_RETORNO_TAU)
		distanciaVisualActual += (distanciaDisponible - distanciaVisualActual) * alfa
	end
	-- Se escribe tambien al acercarse: actualizar solo la distancia almacenada
	-- dejaba la camara visualmente quieta hasta que el personaje se detenia.
	camera.CFrame = CFrame.new(foco + direccion * distanciaVisualActual)
		* objetivo.Rotation
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		-- En lobby, el zoom manual debe responder inmediatamente.
		distanciaVisualActual = nil
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
local trackSprint = nil
local idCargaSprint = 0
local avisoReproduccionSprint = false
local ultimoSalto = 0
local solicitudSalto = 0
local BUFFER_SALTO = 0.4
local COOLDOWN_SALTO = 0.2

local animacionSprint = Instance.new("Animation")
animacionSprint.Name = "Sprint"
animacionSprint.AnimationId = ANIMACION_SPRINT_ID

task.spawn(function()
	local ok, mensaje = pcall(function()
		ContentProvider:PreloadAsync({ animacionSprint })
	end)
	if not ok then
		warn("[SPRINT] No se pudo precargar la animacion:", mensaje)
	end
end)

local function detenerAnimacionSprint(fadeTime)
	if trackSprint and trackSprint.IsPlaying then
		trackSprint:Stop(fadeTime or 0.12)
	end
end

local function cargarAnimacionSprint()
	detenerAnimacionSprint(0)
	trackSprint = nil
	idCargaSprint += 1
	local estaCarga = idCargaSprint

	if not humanoide or not humanoide.Parent then
		return
	end

	local animator = humanoide:FindFirstChildOfClass("Animator")
		or humanoide:WaitForChild("Animator", 5)
	if not animator then
		warn("[SPRINT] El Humanoid no tiene Animator")
		return
	end

	local ok, resultado = pcall(function()
		return animator:LoadAnimation(animacionSprint)
	end)
	if not ok then
		warn("[SPRINT] No se pudo cargar la animacion:", resultado)
		return
	end

	trackSprint = resultado
	-- Action2 gana sobre las pistas predeterminadas de caminar/correr y
	-- permanece por debajo del ataque (Action3) y parkour/pallets (Action4).
	-- No elevarla a Action4: este asset carga, pero sobre el avatar R15 actual
	-- aplica una pose neutra en vez de movimiento y deja al jugador rigido.
	trackSprint.Priority = Enum.AnimationPriority.Action2
	trackSprint.Looped = true
	avisoReproduccionSprint = false

	task.spawn(function()
		local limite = os.clock() + 5
		while estaCarga == idCargaSprint and trackSprint == resultado
			and resultado.Length <= 0 and os.clock() < limite do
			task.wait(0.1)
		end
		if estaCarga ~= idCargaSprint or trackSprint ~= resultado then return end
		if resultado.Length <= 0 then
			warn(string.format(
				"[SPRINT] El asset %s no cargo para el rig %s. Revisa que la animacion y el avatar usen el mismo rig.",
				ANIMACION_SPRINT_ID,
				humanoide and humanoide.RigType.Name or "desconocido"
			))
		else
			print(string.format(
				"[SPRINT] Animacion lista (rig %s, duracion %.2fs)",
				humanoide and humanoide.RigType.Name or "desconocido",
				resultado.Length
			))
		end
	end)
end

local function puedeReproducirAnimacionSprint()
	if not sprintActivo or movimientoBloqueado or not humanoide or humanoide.Health <= 0 then
		return false
	end

	if humanoide.MoveDirection.Magnitude < 0.05
		or humanoide.FloorMaterial == Enum.Material.Air
		or humanoide:GetAttribute("ParkourEspecialActivo")
		or humanoide:GetAttribute("EscaladaActiva")
		or humanoide:GetAttribute("Sliding")
		or humanoide:GetAttribute("Inmovilizado")
		or humanoide:GetAttribute("FallStunned")
		or humanoide:GetAttribute("GolpeActivo")
		or humanoide:GetAttribute("AttackRecovery")
		or humanoide:GetAttribute("AttackRecoveryLocal") then
		return false
	end

	local estado = humanoide:GetState()
	return estado ~= Enum.HumanoidStateType.Jumping
		and estado ~= Enum.HumanoidStateType.Freefall
		and estado ~= Enum.HumanoidStateType.Climbing
		and estado ~= Enum.HumanoidStateType.Seated
end

local function actualizarAnimacionSprint()
	if not puedeReproducirAnimacionSprint() then
		detenerAnimacionSprint()
		return
	end

	if not trackSprint then
		cargarAnimacionSprint()
	end
	if not trackSprint then
		return
	end

	if not trackSprint.IsPlaying then
		trackSprint:Play(0.1, 1, 1)
		trackSprint:AdjustWeight(1, 0.08)
		if not avisoReproduccionSprint then
			avisoReproduccionSprint = true
			print("[SPRINT] Reproduciendo animacion de sprint")
		end
	end
	trackSprint:AdjustSpeed(math.clamp(
		humanoide.WalkSpeed / VELOCIDAD_REFERENCIA_ANIMACION_SPRINT,
		0.85,
		1.2
	))
end

local function establecerSprintActivo(activo)
	sprintActivo = activo
	if not activo then
		detenerAnimacionSprint()
	end
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
	cargarAnimacionSprint()
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
		or (not tocaSueloLocal() and os.clock() > (humanoide:GetAttribute("ClimbJumpGraceLocalUntil") or 0))
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
	humanoide:SetAttribute("ClimbJumpGraceLocalUntil", nil)
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

MobileInput.SprintStart.Event:Connect(activarSprint)
MobileInput.SprintEnd.Event:Connect(desactivarSprint)
MobileInput.Jump.Event:Connect(solicitarSaltoConBuffer)

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

	actualizarAnimacionSprint()

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

		-- RESET_JUGADOR representa una restauracion completa (por ejemplo, al
		-- volver al lobby). No debe conservar el flag local de un bloqueo de la
		-- ultima ronda, incluso si su DESBLOQUEAR se perdio o llego antes.
		movimientoBloqueado = false
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
	cargarAnimacionSprint()

	-- El servidor pudo bloquear el movimiento del
	-- personaje anterior (pale, stun). Ese flag es
	-- local, asi que hay que liberarlo al reaparecer
	-- o el jugador respawna congelado.
	movimientoBloqueado = false
	solicitudSalto += 1
	ultimoSalto = 0
	humanoide:SetAttribute("ClimbJumpGraceLocalUntil", nil)

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
