local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local jugador = Players.LocalPlayer

local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")
local EventoAtaque = ReplicatedStorage:WaitForChild("EventoAtaque")
local EventoHit1v1 = ReplicatedStorage:WaitForChild("EventoHit1v1")

--==================================================
-- CONFIGURACIÃN
--==================================================

local ANIM_GOLPE = "rbxassetid://122984890985296"
local SONIDO_HIT = "rbxassetid://0" -- <- tu sonido de hit

-- Tiempos de la animaciÃ³n (en segundos de la animaciÃ³n)
local INICIO_LUNGE = 0.29
local FIN_LUNGE = 0.71

-- Mientras dura el lunge, la velocidad se multiplica por esto
local MULTIPLICADOR_LUNGE = 1.5

-- Segundos desde que empieza el ataque (0.71) hasta que el golpe "conecta"
local RETRASO_IMPACTO = 0.1

-- Cooldown desde que empieza el ataque. Debe ser un poco mayor que
-- COOLDOWN_ATAQUE del servidor (1) para evitar rechazos por latencia.
local COOLDOWN_GOLPE = 1.1
local COOLDOWN_BATE = 1.8

local function herramientaEquipada()
	local personaje = jugador.Character
	return personaje and personaje:FindFirstChildOfClass("Tool")
end

local DURACION_SACUDIDA = 0.25
local INTENSIDAD_SACUDIDA = 0.4

--==================================================
-- ESTADO
--==================================================

local rol = nil
local bloqueado = true

local humanoide = nil
local trackGolpe = nil

local ocupado = false        -- lunge + ataque + cooldown
local presionando = false    -- botÃ³n de golpe mantenido
local idAtaque = 0           -- invalida acciones pendientes al cancelar
local conexionLunge = nil

local velocidadBase = nil
local velocidadBoost = nil

--==================================================
-- ANIMACIÃN
--==================================================

local function cargarAnimacion()
	trackGolpe = nil

	if ANIM_GOLPE == "rbxassetid://0" or not humanoide then
		return
	end

	local h = humanoide

	task.spawn(function()
		local animacion = Instance.new("Animation")
		animacion.AnimationId = ANIM_GOLPE

		pcall(function()
			ContentProvider:PreloadAsync({ animacion })
		end)

		local cargador = h:FindFirstChildOfClass("Animator") or h

		local track = cargador:LoadAnimation(animacion)
		track.Priority = Enum.AnimationPriority.Action3 -- por debajo del parkour (Action4)
		track.Looped = false
		animacion:Destroy()

		-- Esperar a que el track tenga datos reales
		local inicio = os.clock()
		while track.Length == 0 and os.clock() - inicio < 5 do
			task.wait()
		end

		-- Calentamiento: reproducir una vez sin que se note
		track:Play(0, 0.001, 0)
		task.wait()
		track:Stop(0)

		trackGolpe = track
	end)
end

--==================================================
-- EFECTOS
--==================================================

local function efectoImpacto(personajeVictima)
	local root = personajeVictima:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	-- Sonido en el punto de impacto
	if SONIDO_HIT ~= "rbxassetid://0" then
		local sonido = Instance.new("Sound")
		sonido.SoundId = SONIDO_HIT
		sonido.Volume = 1
		sonido.RollOffMaxDistance = 80
		sonido.Parent = root
		sonido:Play()
		Debris:AddItem(sonido, 3)
	end

	-- Chispas
	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local emisor = Instance.new("ParticleEmitter")
	emisor.Rate = 0
	emisor.Lifetime = NumberRange.new(0.2, 0.4)
	emisor.Speed = NumberRange.new(15, 25)
	emisor.SpreadAngle = Vector2.new(180, 180)
	emisor.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emisor.Color = ColorSequence.new(
		Color3.fromRGB(255, 255, 200),
		Color3.fromRGB(255, 120, 40)
	)
	emisor.LightEmission = 1
	emisor.Parent = attachment
	emisor:Emit(18)

	Debris:AddItem(attachment, 1)

	-- Destello rojo sobre el personaje golpeado
	local destello = Instance.new("Highlight")
	destello.FillColor = Color3.fromRGB(255, 60, 60)
	destello.FillTransparency = 0.25
	destello.OutlineTransparency = 1
	destello.Parent = personajeVictima

	TweenService:Create(
		destello,
		TweenInfo.new(0.25),
		{ FillTransparency = 1 }
	):Play()

	Debris:AddItem(destello, 0.3)
end

local pantallaGui = Instance.new("ScreenGui")
pantallaGui.Name = "FlashHit"
pantallaGui.IgnoreGuiInset = true
pantallaGui.ResetOnSpawn = false
pantallaGui.DisplayOrder = 50
pantallaGui.Parent = jugador:WaitForChild("PlayerGui")

local flashRojo = Instance.new("Frame")
flashRojo.Size = UDim2.fromScale(1, 1)
flashRojo.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
flashRojo.BackgroundTransparency = 1
flashRojo.BorderSizePixel = 0
flashRojo.Parent = pantallaGui

local function efectoRecibido()
	-- Flash rojo en pantalla
	flashRojo.BackgroundTransparency = 0.65

	TweenService:Create(
		flashRojo,
		TweenInfo.new(0.35),
		{ BackgroundTransparency = 1 }
	):Play()

	-- Sacudida de cÃ¡mara
	local h = humanoide

	if not h then
		return
	end

	local inicio = os.clock()
	local conexion

	conexion = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - inicio) / DURACION_SACUDIDA

		if t >= 1 or not h.Parent then
			h.CameraOffset = Vector3.zero
			conexion:Disconnect()
			return
		end

		local intensidad = INTENSIDAD_SACUDIDA * (1 - t)

		h.CameraOffset = Vector3.new(
			(math.random() - 0.5) * 2 * intensidad,
			(math.random() - 0.5) * 2 * intensidad,
			0
		)
	end)
end

--==================================================
-- GOLPE: LUNGE + ATAQUE
--==================================================

-- Termina el impulso del lunge y restaura la velocidad.
local function terminarLunge()
	if conexionLunge then
		conexionLunge:Disconnect()
		conexionLunge = nil
	end

	if humanoide then
		-- Solo se restaura si nadie mÃ¡s cambiÃ³ la velocidad mientras tanto
		if velocidadBoost and humanoide.WalkSpeed == velocidadBoost then
			humanoide.WalkSpeed = velocidadBase
		end

		humanoide:SetAttribute("GolpeActivo", false)
	end

	velocidadBoost = nil
end

-- Cancela todo el golpe (muerte, bloqueo, nuevo personaje...).
local function cancelarGolpe()
	idAtaque += 1
	terminarLunge()

	if trackGolpe and trackGolpe.IsPlaying then
		trackGolpe:Stop(0.1)
	end

	ocupado = false
end

-- Empieza el ataque en sÃ­ (a partir de 0.71).
local function lanzarGolpe(miId)
	terminarLunge()

	-- Si se soltÃ³ antes de tiempo, salta directo al ataque
	if trackGolpe and trackGolpe.IsPlaying and trackGolpe.TimePosition < FIN_LUNGE then
		trackGolpe.TimePosition = FIN_LUNGE
	end

	-- El servidor valida distancia, cooldown y vidas
	task.delay(RETRASO_IMPACTO, function()
		if idAtaque ~= miId then
			return
		end

		EventoAtaque:FireServer()
	end)

	-- Cooldown
	local herramienta = herramientaEquipada()
	local cooldown = herramienta and herramienta:GetAttribute("AttackKind") == "Bat"
		and COOLDOWN_BATE or COOLDOWN_GOLPE
	task.delay(cooldown, function()
		if idAtaque ~= miId then
			return
		end

		ocupado = false
	end)
end

local function iniciarGolpe()
	if ocupado or bloqueado or rol ~= "PERSEGUIDOR" then
		return
	end
	local herramienta = herramientaEquipada()
	if herramienta and herramienta:GetAttribute("Throwable") then return end

	if not humanoide or humanoide.Health <= 0 then
		return
	end

	-- No golpear en medio de una acciÃ³n de parkour
	if humanoide:GetAttribute("ParkourEspecialActivo") then
		return
	end

	idAtaque += 1
	local miId = idAtaque

	ocupado = true

	-- Sin animaciÃ³n cargada: ataque directo, sin lunge
	if not trackGolpe then
		lanzarGolpe(miId)
		return
	end

	trackGolpe:Play(0.05, 1, 1)
	trackGolpe.TimePosition = INICIO_LUNGE

	-- Impulso del lunge
	velocidadBase = humanoide.WalkSpeed
	velocidadBoost = velocidadBase * MULTIPLICADOR_LUNGE
	humanoide.WalkSpeed = velocidadBoost
	humanoide:SetAttribute("GolpeActivo", true)

	conexionLunge = RunService.Heartbeat:Connect(function()
		if idAtaque ~= miId then
			return
		end

		if bloqueado
			or not humanoide
			or humanoide.Health <= 0
			or humanoide:GetAttribute("ParkourEspecialActivo") then

			cancelarGolpe()
			return
		end

		-- SoltÃ³ el botÃ³n, o el lunge llegÃ³ a su fin natural
		if not presionando or trackGolpe.TimePosition >= FIN_LUNGE then
			lanzarGolpe(miId)
		end
	end)
end

--==================================================
-- PERSONAJE
--==================================================

local function configurarPersonaje(char)
	cancelarGolpe()
	presionando = false

	humanoide = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")

	humanoide.Died:Connect(cancelarGolpe)

	cargarAnimacion()
end

--==================================================
-- ESTADO DE LA PARTIDA (segÃºn EventoJuego)
--==================================================

EventoJuego.OnClientEvent:Connect(function(tipo, valor)
	if tipo == "ROL" then
		rol = valor

	elseif tipo == "ESPERANDO_JUGADOR" then
		rol = nil

	elseif tipo == "BLOQUEAR_MOVIMIENTO"
		or tipo == "RESULTADO_RONDA"
		or tipo == "RESULTADO_FINAL" then

		bloqueado = true
		cancelarGolpe()

	elseif tipo == "DESBLOQUEAR_MOVIMIENTO" then
		bloqueado = false
	end
end)

--==================================================
-- INPUT
--==================================================

local function esInputGolpe(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.F
end

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then
		return
	end

	if esInputGolpe(input) then
		presionando = true
		iniciarGolpe()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if esInputGolpe(input) then
		presionando = false
	end
end)

--==================================================
-- HIT CONFIRMADO POR EL SERVIDOR
--==================================================

EventoHit1v1.OnClientEvent:Connect(function(tipo, atacante, victima)
	if tipo ~= "HIT" then
		return
	end

	local personajeVictima = victima and victima.Character

	if personajeVictima then
		efectoImpacto(personajeVictima) -- lo ven y oyen los dos jugadores
	end

	if victima == jugador then
		efectoRecibido()
	end
end)

--==================================================
-- INICIO
--==================================================

jugador.CharacterAdded:Connect(configurarPersonaje)

if jugador.Character then
	configurarPersonaje(jugador.Character)
end
