local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SolicitarParkour = ReplicatedStorage:WaitForChild("SolicitarParkour1v1")
local ParkourPairs = require(ReplicatedStorage:WaitForChild("ParkourPairs"))

local jugadorLocal = Players.LocalPlayer

local DISTANCIA_INTERACCION = 5
local VELOCIDAD_APROXIMACION = 10
local VELOCIDAD_NARROWED_WALK = 6.5
local VELOCIDAD_SALTO_VENTANA = 9

local MULTIPLICADOR_CARRERA = 1.35
local UMBRAL_DIRECCION_CARRERA = 0.7

local ALTURA_SALTO_VENTANA = 0.8

local DISTANCIA_LLEGADA = 0.1
local TIEMPO_COOLDOWN = 0.6

local NARROWED_ANIM_INICIO = 0.29
local NARROWED_ANIM_FIN = 1.0

local ANIM_NARROWED_WALK = "rbxassetid://127538049880566"
local ANIM_VAULT_WINDOW = "rbxassetid://139297087203362"

local DISTANCIA_RAYCAST_SUELO = 50

local personaje
local humanoide
local rootPart

local accionActiva = false
local cooldown = false
local escaladaActiva = false
local trussActivo = nil

local tracksPrecargados = {}

local antiGravity
local antiGravityAttachment

local walkSpeedOriginal = 16
local alturaSobreSuelo = 3

local function obtenerPersonaje()
	personaje = jugadorLocal.Character

	if not personaje then
		return false
	end

	humanoide = personaje:FindFirstChildOfClass("Humanoid")
	rootPart = personaje:FindFirstChild("HumanoidRootPart")

	return humanoide ~= nil and rootPart ~= nil
end

-- ANTI GRAVEDAD ---------------------------------------------------------

local function crearAntiGravity()
	if antiGravity then
		antiGravity:Destroy()
		antiGravity = nil
	end

	if antiGravityAttachment then
		antiGravityAttachment:Destroy()
		antiGravityAttachment = nil
	end

	antiGravityAttachment = Instance.new("Attachment")
	antiGravityAttachment.Parent = rootPart

	antiGravity = Instance.new("VectorForce")
	antiGravity.Attachment0 = antiGravityAttachment
	antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
	antiGravity.ApplyAtCenterOfMass = true
	antiGravity.Force = Vector3.new(
		0,
		rootPart.AssemblyMass * workspace.Gravity,
		0
	)
	antiGravity.Enabled = false
	antiGravity.Parent = rootPart
end

local function activarAntiGravity()
	if not antiGravity or not antiGravity.Parent then
		crearAntiGravity()
	end

	antiGravity.Force = Vector3.new(
		0,
		rootPart.AssemblyMass * workspace.Gravity,
		0
	)

	antiGravity.Enabled = true
end

local function desactivarAntiGravity()
	if antiGravity then
		antiGravity.Enabled = false
	end
end

-- UTILIDADES ------------------------------------------------------------

local function precargarAnimaciones()
	local h = humanoide
	if not h then
		return
	end

	local nuevos = {}
	tracksPrecargados = nuevos

	task.spawn(function()
		for _, id in ipairs({ ANIM_NARROWED_WALK, ANIM_VAULT_WINDOW }) do
			if not h.Parent then
				return
			end

			local animacion = Instance.new("Animation")
			animacion.AnimationId = id

			pcall(function()
				ContentProvider:PreloadAsync({ animacion })
			end)

			local track = h:LoadAnimation(animacion)
			track.Priority = Enum.AnimationPriority.Action4

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

			nuevos[id] = track
		end
	end)
end

local function crearAnimacion(id)
	-- Si ya estÃ¡ precargado, se reutiliza
	local track = tracksPrecargados[id]

	if track and track.Length > 0 then
		return track
	end

	-- Respaldo: se carga ahora y se espera a que tenga datos
	local animacion = Instance.new("Animation")
	animacion.AnimationId = id

	track = humanoide:LoadAnimation(animacion)
	track.Priority = Enum.AnimationPriority.Action4

	animacion:Destroy()

	local inicio = os.clock()
	while track.Length == 0 and os.clock() - inicio < 3 do
		task.wait()
	end

	tracksPrecargados[id] = track

	return track
end

local function buscarPuntoMasCercano(prefijo)
	if not rootPart then
		return nil
	end

	local puntoMasCercano = nil
	local distanciaMasCercana = DISTANCIA_INTERACCION

	for _, objeto in ipairs(workspace:GetDescendants()) do
		if objeto:IsA("BasePart") then
			if objeto.Name == prefijo .. "_1"
				or objeto.Name == prefijo .. "_2" then
				if not ParkourPairs.Resolve(objeto) then continue end

				local distancia =
					(rootPart.Position - objeto.Position).Magnitude

				if distancia <= distanciaMasCercana then
					distanciaMasCercana = distancia
					puntoMasCercano = objeto
				end
			end
		end
	end

	return puntoMasCercano, distanciaMasCercana
end

local function obtenerPuntoOpuesto(punto)
	return ParkourPairs.Resolve(punto)
end

local function obtenerDireccion(puntoInicial, puntoFinal)
	local diferencia = puntoFinal.Position - puntoInicial.Position

	if diferencia.Magnitude <= 0 then
		return rootPart.CFrame.LookVector
	end

	return diferencia.Unit
end

local function crearCFrameOrientado(posicion, direccion)
	return CFrame.lookAt(posicion, posicion + direccion)
end

local function estaCorriendoHaciaPunto(punto)
	local direccionMovimiento = humanoide.MoveDirection

	if direccionMovimiento.Magnitude <= 0 then
		return false
	end

	local direccionAlPunto = (punto.Position - rootPart.Position).Unit

	return direccionMovimiento:Dot(direccionAlPunto)
		>= UMBRAL_DIRECCION_CARRERA
end

local function obtenerMultiplicadorAccion(punto)
	if estaCorriendoHaciaPunto(punto) then
		return MULTIPLICADOR_CARRERA
	end

	return 1
end

-- SUELO -----------------------------------------------------------------

-- Devuelve la posiciÃ³n Y del suelo bajo una posiciÃ³n (ignora al personaje
-- y a las partes con CanCollide = false, como los puntos de marcado).
local function buscarSueloY(posicion)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { personaje }
	params.RespectCanCollide = true

	local resultado = workspace:Raycast(
		posicion + Vector3.new(0, 2, 0),
		Vector3.new(0, -DISTANCIA_RAYCAST_SUELO, 0),
		params
	)

	if resultado then
		return resultado.Position.Y
	end

	return nil
end

local function medirAlturaSobreSuelo()
	local sueloY = buscarSueloY(rootPart.Position)

	if sueloY then
		alturaSobreSuelo = rootPart.Position.Y - sueloY
	end
	-- si no hay suelo detectado, se conserva el Ãºltimo valor conocido
end

-- Coloca al personaje exactamente sobre el suelo en su posiciÃ³n actual.
local function ajustarAlSuelo(direccion)
	local sueloY = buscarSueloY(rootPart.Position)

	if not sueloY then
		return
	end

	local posicion = Vector3.new(
		rootPart.Position.X,
		sueloY + alturaSobreSuelo,
		rootPart.Position.Z
	)

	rootPart.CFrame = crearCFrameOrientado(posicion, direccion)
end

-- COLISIONES ------------------------------------------------------------

local function desactivarColisionesPersonaje()
	for _, objeto in ipairs(personaje:GetDescendants()) do
		if objeto:IsA("BasePart") then
			objeto:SetAttribute("ColisionOriginal", objeto.CanCollide)
			objeto.CanCollide = false
		end
	end
end

local function restaurarColisionesPersonaje()
	for _, objeto in ipairs(personaje:GetDescendants()) do
		if objeto:IsA("BasePart") then
			local colisionOriginal = objeto:GetAttribute("ColisionOriginal")

			if colisionOriginal ~= nil then
				objeto.CanCollide = colisionOriginal
				objeto:SetAttribute("ColisionOriginal", nil)
			end
		end
	end
end

-- APROXIMACIÃN ----------------------------------------------------------

local function aproximarseAlPunto(punto, direccion)
	-- Se mantiene la altura actual del root: solo se mueve en X/Z
	local posicionObjetivo = Vector3.new(
		punto.Position.X,
		rootPart.Position.Y,
		punto.Position.Z
	)

	local distancia = (rootPart.Position - posicionObjetivo).Magnitude

	if distancia <= DISTANCIA_LLEGADA then
		return
	end

	local duracion = distancia / VELOCIDAD_APROXIMACION

	local tween = TweenService:Create(
		rootPart,
		TweenInfo.new(duracion, Enum.EasingStyle.Linear),
		{ CFrame = crearCFrameOrientado(posicionObjetivo, direccion) }
	)

	tween:Play()
	tween.Completed:Wait()
end

-- INICIO / FIN DE ACCIÃN ------------------------------------------------

local function comenzarAccion()
	accionActiva = true

	-- Altura real del root sobre el suelo, antes de tocar nada
	medirAlturaSobreSuelo()

	humanoide:SetAttribute("ParkourEspecialActivo", true)

	walkSpeedOriginal = humanoide.WalkSpeed

	humanoide.AutoRotate = false
	humanoide.WalkSpeed = 0
	humanoide:Move(Vector3.zero)

	activarAntiGravity()

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	desactivarColisionesPersonaje()
end

local function terminarAccion(direccion)
	desactivarAntiGravity()

	if rootPart and rootPart.Parent then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	if personaje and personaje.Parent then
		restaurarColisionesPersonaje()
	end

	if humanoide and humanoide.Parent then
		humanoide.WalkSpeed = walkSpeedOriginal
		humanoide.AutoRotate = true
		humanoide:SetAttribute("ParkourEspecialActivo", false)
		-- Gravity takes over at the endpoint; a lower floor must be reached by falling.
		humanoide:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	accionActiva = false
	cooldown = true

	task.delay(TIEMPO_COOLDOWN, function()
		cooldown = false
	end)
end

-- ACCIÃN GENÃRICA -------------------------------------------------------

local function ejecutarAccion(puntoInicial, puntoFinal, config)
	local okReserva, factorCosto = pcall(function()
		return SolicitarParkour:InvokeServer(config.tipo, puntoInicial, puntoFinal)
	end)
	if not okReserva or not factorCosto then return end
	-- Se calcula ANTES de comenzarAccion, mientras MoveDirection aÃºn es vÃ¡lido
	local multiplicador = obtenerMultiplicadorAccion(puntoInicial)

	-- Si aÃºn no estÃ¡ listo, la espera ocurre ANTES de bloquear al personaje
	local animacion = crearAnimacion(config.animacion)

	comenzarAccion()

	local direccion = obtenerDireccion(puntoInicial, puntoFinal)

	local ok, err = pcall(function()
		local velocidad = config.velocidad * multiplicador / factorCosto

		aproximarseAlPunto(puntoInicial, direccion)

		rootPart.CFrame = crearCFrameOrientado(rootPart.Position, direccion)

		animacion:Play(0.05)

		if config.animInicio then
			animacion.TimePosition = config.animInicio
		end

		animacion:AdjustSpeed(multiplicador / factorCosto)

		local posicionInicio = rootPart.Position

		-- Preserve the root's offset from the authored marker, including
		-- windows whose exit is higher or lower than the entry.
		local alturaMarcador = posicionInicio.Y - puntoInicial.Position.Y
		local posicionSalida = Vector3.new(
			puntoFinal.Position.X,
			puntoFinal.Position.Y + alturaMarcador,
			puntoFinal.Position.Z
		)

		local distancia = (posicionSalida - posicionInicio).Magnitude
		local duracion = math.max(distancia / velocidad, 0.01)
		local tiempoInicio = os.clock()

		while true do
			if not rootPart or not rootPart.Parent then
				break
			end

			local t = math.clamp(
				(os.clock() - tiempoInicio) / duracion,
				0,
				1
			)

			local posicion = posicionInicio:Lerp(posicionSalida, t)

			if config.alturaArco then
				posicion += Vector3.new(
					0,
					4 * config.alturaArco * t * (1 - t),
					0
				)
			end

			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			rootPart.CFrame = crearCFrameOrientado(posicion, direccion)

			if config.animLoopFin then
				if not animacion.IsPlaying then
					animacion:Play(0)
					animacion.TimePosition = config.animInicio or 0
					animacion:AdjustSpeed(multiplicador / factorCosto)
				elseif animacion.TimePosition >= config.animLoopFin - 0.03 then
					animacion.TimePosition = config.animInicio or 0
				end
			end

			if t >= 1 then
				break
			end

			RunService.Heartbeat:Wait()
		end

		if rootPart and rootPart.Parent then
			rootPart.CFrame = crearCFrameOrientado(posicionSalida, direccion)
		end

		animacion:Stop(0.05)
	end)

	if not ok then
		warn("Error en acciÃ³n de parkour:", err)
	end

	terminarAccion(direccion)
end

local function ejecutarNarrowedWalk(puntoInicial, puntoFinal)
	-- DETECTAR SI ES PERSEGUIDOR PARA REDUCIR LA VELOCIDAD
	local velocidadActual = VELOCIDAD_NARROWED_WALK
	if jugadorLocal:GetAttribute("Rol") == "PERSEGUIDOR" then
		velocidadActual = 3.0 -- Velocidad lenta exclusiva para el perseguidor en espacios estrechos
	end

	ejecutarAccion(puntoInicial, puntoFinal, {
		tipo = "Estrecho",
		velocidad = velocidadActual,
		animacion = ANIM_NARROWED_WALK,
		animInicio = NARROWED_ANIM_INICIO,
		animLoopFin = NARROWED_ANIM_FIN,
		alturaArco = nil,
	})
end

local function ejecutarSaltoVentana(puntoInicial, puntoFinal)
	-- DETECTAR SI ES PERSEGUIDOR PARA REDUCIR LA VELOCIDAD
	local velocidadActual = VELOCIDAD_SALTO_VENTANA
	if jugadorLocal:GetAttribute("Rol") == "PERSEGUIDOR" then
		velocidadActual = 4.5 -- Velocidad lenta exclusiva para el perseguidor al saltar
	end

	ejecutarAccion(puntoInicial, puntoFinal, {
		tipo = "Ventana",
		velocidad = velocidadActual,
		animacion = ANIM_VAULT_WINDOW,
		animInicio = nil,
		animLoopFin = nil,
		alturaArco = ALTURA_SALTO_VENTANA,
	})
end

-- INPUT -----------------------------------------------------------------

local function distanciaTruss(objeto)
	local localPos = objeto.CFrame:PointToObjectSpace(rootPart.Position)
	local mitad = objeto.Size * 0.5
	local cercano = Vector3.new(
		math.clamp(localPos.X, -mitad.X, mitad.X),
		math.clamp(localPos.Y, -mitad.Y, mitad.Y),
		math.clamp(localPos.Z, -mitad.Z, mitad.Z)
	)
	return (localPos - cercano).Magnitude
end

local function trussCercano()
	local mejor, distancia = nil, 5
	for _, objeto in ipairs(workspace:GetDescendants()) do
		if objeto:IsA("TrussPart") then
			local d = distanciaTruss(objeto)
			if d < distancia then mejor, distancia = objeto, d end
		end
	end
	return mejor
end

local function alternarEscalada()
	if escaladaActiva then
		pcall(function() SolicitarParkour:InvokeServer("EscaladaFin") end)
		escaladaActiva = false
		trussActivo = nil
		humanoide:SetAttribute("EscaladaActiva", false)
		humanoide:SetAttribute("EscaladaLenta", nil)
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoide:ChangeState(Enum.HumanoidStateType.Freefall)
		return true
	end
	local truss = trussCercano()
	if not truss then return false end
	local ok, factor = pcall(function()
		return SolicitarParkour:InvokeServer("Escalada", truss)
	end)
	if not ok or not factor then return true end
	escaladaActiva = true
	trussActivo = truss
	humanoide:SetAttribute("EscaladaActiva", true)
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	humanoide:ChangeState(Enum.HumanoidStateType.Climbing)
	humanoide:SetAttribute("EscaladaLenta", factor > 1)
	return true
end

RunService.Heartbeat:Connect(function()
	if not escaladaActiva or not humanoide or not rootPart then return end
	if not trussActivo or not trussActivo.Parent or distanciaTruss(trussActivo) > 7 then
		escaladaActiva = false
		pcall(function() SolicitarParkour:InvokeServer("EscaladaFin") end)
		humanoide:SetAttribute("EscaladaActiva", false)
		humanoide:SetAttribute("EscaladaLenta", nil)
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		return
	end
end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then
		return
	end

	if input.KeyCode ~= Enum.KeyCode.Space then
		return
	end

	if accionActiva or cooldown then
		return
	end

	if not obtenerPersonaje() then
		return
	end
	if escaladaActiva then
		alternarEscalada()
		return
	end
	-- The pallet controller owns Space whenever a pallet endpoint is in range.
	for _, objeto in ipairs(workspace:GetDescendants()) do
		if objeto:IsA("BasePart")
			and (objeto.Name == "PuntoPale_1" or objeto.Name == "PuntoPale_2")
			and (rootPart.Position - objeto.Position).Magnitude <= 5 then
			return
		end
	end

	local puntoNarrowed, distanciaNarrowed = buscarPuntoMasCercano("PuntoEntrada")
	local puntoVentana, distanciaVentana = buscarPuntoMasCercano("PuntoSalto")

	if puntoNarrowed and (not puntoVentana or distanciaNarrowed <= distanciaVentana) then
		local puntoFinal = obtenerPuntoOpuesto(puntoNarrowed)

		if puntoFinal then
			ejecutarNarrowedWalk(puntoNarrowed, puntoFinal)
			return
		end
	end

	if puntoVentana then
		local puntoFinal = obtenerPuntoOpuesto(puntoVentana)

		if puntoFinal then
			ejecutarSaltoVentana(puntoVentana, puntoFinal)
			return
		end
	end
	alternarEscalada()
end)

jugadorLocal.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")

	obtenerPersonaje()
	escaladaActiva = false
	trussActivo = nil
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	accionActiva = false
	cooldown = false

	antiGravity = nil
	antiGravityAttachment = nil

	precargarAnimaciones()
end)

if obtenerPersonaje() then
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	precargarAnimaciones()
end
