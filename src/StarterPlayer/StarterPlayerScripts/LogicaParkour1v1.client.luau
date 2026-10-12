local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SolicitarParkour = ReplicatedStorage:WaitForChild("SolicitarParkour1v1")
local ParkourPairs = require(ReplicatedStorage:WaitForChild("ParkourPairs"))
local Climbables = require(ReplicatedStorage:WaitForChild("Climbables"))
local CollectionService = game:GetService("CollectionService")

local jugadorLocal = Players.LocalPlayer

local DISTANCIA_INTERACCION = 5.8
local DISTANCIA_INICIO_ANIMACION = 1.8
local VELOCIDAD_NARROWED_WALK = 6.5
local VELOCIDAD_SALTO_VENTANA = 9
local FACTOR_PARKOUR_PERSEGUIDOR = 0.8

local MULTIPLICADOR_CARRERA = 1.35

local ALTURA_SALTO_VENTANA = 0.8

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
local inicioEscalada = 0
local ultimoEstadoEscalando = 0
local ultimaProximidadEscalada = 0
local escaladaPersonalizada = nil

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

				if distancia <= distanciaMasCercana
					and math.abs(rootPart.Position.Y - objeto.Position.Y) <= 4.5 then
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

local function obtenerMultiplicadorAccion()
	if humanoide:GetAttribute("SprintActivoLocal") == true
		and humanoide.MoveDirection.Magnitude > 0.05
		and (jugadorLocal:GetAttribute("Stamina") or 0) > 0 then
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
	local alturaMinima = humanoide.HipHeight + rootPart.Size.Y * 0.5 + 0.12
	local yMinima = sueloY + alturaMinima
	if rootPart.Position.Y < yMinima then
		rootPart.CFrame = crearCFrameOrientado(
			Vector3.new(rootPart.Position.X, yMinima, rootPart.Position.Z), direccion
		)
		local velocidad = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(velocidad.X, math.max(0, velocidad.Y), velocidad.Z)
	end
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

local function aproximarseAlPunto(punto)
	local objetivo = Vector3.new(punto.Position.X, rootPart.Position.Y, punto.Position.Z)
	local distancia = (rootPart.Position - objetivo).Magnitude
	if distancia <= DISTANCIA_INICIO_ANIMACION then return true end
	local humanoideAproximacion = humanoide
	local rootAproximacion = rootPart
	local limite = os.clock() + math.max(1, distancia / math.max(humanoideAproximacion.WalkSpeed, 1) + 1)
	local nombreControl = "ParkourApproach1v1"
	-- Default player controls overwrite MoveTo while a movement key is held.
	-- Apply the walk direction after those controls, without changing WalkSpeed.
	RunService:BindToRenderStep(nombreControl, Enum.RenderPriority.Character.Value + 1, function()
		if not humanoideAproximacion.Parent or not rootAproximacion.Parent then return end
		local diferencia = objetivo - Vector3.new(rootAproximacion.Position.X, objetivo.Y, rootAproximacion.Position.Z)
		humanoideAproximacion:Move(diferencia.Magnitude > DISTANCIA_INICIO_ANIMACION
			and diferencia.Unit or Vector3.zero, false)
	end)
	local llego = false
	while os.clock() < limite and humanoideAproximacion.Parent and rootAproximacion.Parent
		and humanoide == humanoideAproximacion and rootPart == rootAproximacion do
		local restante = (Vector3.new(rootAproximacion.Position.X, objetivo.Y, rootAproximacion.Position.Z) - objetivo).Magnitude
		if restante <= DISTANCIA_INICIO_ANIMACION then
			llego = true
			break
		end
		RunService.Heartbeat:Wait()
	end
	RunService:UnbindFromRenderStep(nombreControl)
	if humanoideAproximacion.Parent then humanoideAproximacion:Move(Vector3.zero, false) end
	return llego
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
	if rootPart and rootPart.Parent and humanoide and humanoide.Parent then
		ajustarAlSuelo(direccion)
	end

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
	local rootFinal = rootPart
	task.spawn(function()
		local fin = os.clock() + 0.35
		while os.clock() < fin and not accionActiva and rootFinal == rootPart
			and rootFinal and rootFinal.Parent and humanoide and humanoide.Parent do
			ajustarAlSuelo(direccion)
			RunService.Heartbeat:Wait()
		end
	end)

	cooldown = true

	task.delay(TIEMPO_COOLDOWN, function()
		cooldown = false
	end)
end

-- ACCIÃN GENÃRICA -------------------------------------------------------

local function ejecutarAccion(puntoInicial, puntoFinal, config)
	local multiplicador = obtenerMultiplicadorAccion()
	accionActiva = true
	local direccion = obtenerDireccion(puntoInicial, puntoFinal)
	if not aproximarseAlPunto(puntoInicial) then
		accionActiva = false
		return
	end
	local okReserva, factorCosto = pcall(function()
		return SolicitarParkour:InvokeServer(config.tipo, puntoInicial, puntoFinal)
	end)
	if not okReserva or not factorCosto then
		accionActiva = false
		return
	end
	-- Si aÃºn no estÃ¡ listo, la espera ocurre ANTES de bloquear al personaje
	local animacion = crearAnimacion(config.animacion)

	comenzarAccion()

	local ok, err = pcall(function()
		local velocidad = config.velocidad * multiplicador / factorCosto

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
	local velocidadActual = VELOCIDAD_NARROWED_WALK
	if jugadorLocal:GetAttribute("Rol") == "PERSEGUIDOR" then
		velocidadActual *= FACTOR_PARKOUR_PERSEGUIDOR
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
	local velocidadActual = VELOCIDAD_SALTO_VENTANA
	if jugadorLocal:GetAttribute("Rol") == "PERSEGUIDOR" then
		velocidadActual *= FACTOR_PARKOUR_PERSEGUIDOR
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

local function distanciaEscalable(objeto)
	local localPos = objeto.CFrame:PointToObjectSpace(rootPart.Position)
	local mitad = objeto.Size * 0.5
	local cercano = Vector3.new(
		math.clamp(localPos.X, -mitad.X, mitad.X),
		math.clamp(localPos.Y, -mitad.Y, mitad.Y),
		math.clamp(localPos.Z, -mitad.Z, mitad.Z)
	)
	return (localPos - cercano).Magnitude
end

local escalables = {}
local function registrarEscalable(objeto)
	if Climbables.IsClimbable(objeto) then escalables[objeto] = true end
end
for _, objeto in ipairs(workspace:GetDescendants()) do registrarEscalable(objeto) end
workspace.DescendantAdded:Connect(registrarEscalable)
workspace.DescendantRemoving:Connect(function(objeto) escalables[objeto] = nil end)
for _, tag in ipairs({ "Escalable", "climbable", "Climbable" }) do
	CollectionService:GetInstanceAddedSignal(tag):Connect(registrarEscalable)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(objeto)
		if not Climbables.IsClimbable(objeto) then escalables[objeto] = nil end
	end)
end

local function escalableCercano(limite)
	local mejor, distancia = nil, 5.5
	if limite then distancia = limite end
	for objeto in pairs(escalables) do
		if objeto:IsDescendantOf(workspace) and Climbables.IsClimbable(objeto) then
			local d = distanciaEscalable(objeto)
			if d < distancia then mejor, distancia = objeto, d end
		end
	end
	return mejor
end

local function limpiarEscaladaPersonalizada()
	if not escaladaPersonalizada then return end
	escaladaPersonalizada.velocidad:Destroy()
	escaladaPersonalizada.attachment:Destroy()
	if humanoide then humanoide.AutoRotate = escaladaPersonalizada.autoRotate end
	escaladaPersonalizada = nil
end

local function iniciarEscaladaPersonalizada()
	local attachment = Instance.new("Attachment")
	attachment.Name = "CustomClimbAttachment"
	attachment.Parent = rootPart
	local velocidad = Instance.new("LinearVelocity")
	velocidad.Name = "CustomClimbVelocity"
	velocidad.Attachment0 = attachment
	velocidad.RelativeTo = Enum.ActuatorRelativeTo.World
	velocidad.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocidad.ForceLimitsEnabled = false
	velocidad.VectorVelocity = Vector3.zero
	velocidad.Parent = rootPart
	escaladaPersonalizada = {
		attachment = attachment,
		velocidad = velocidad,
		autoRotate = humanoide.AutoRotate,
	}
	humanoide.AutoRotate = false
end

local function alternarEscalada()
	if escaladaActiva then
		pcall(function() SolicitarParkour:InvokeServer("EscaladaFin") end)
		escaladaActiva = false
		trussActivo = nil
		limpiarEscaladaPersonalizada()
		humanoide:SetAttribute("EscaladaActiva", false)
		humanoide:SetAttribute("EscaladaEstado", "NoEscalando")
		humanoide:SetAttribute("EscaladaLenta", nil)
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoide:ChangeState(Enum.HumanoidStateType.Freefall)
		return true
	end
	local truss = escalableCercano()
	if not truss then return false end
	local ok, factor = pcall(function()
		return SolicitarParkour:InvokeServer("Escalada", truss)
	end)
	if not ok or not factor then return true end
	escaladaActiva = true
	trussActivo = truss
	inicioEscalada = os.clock()
	ultimoEstadoEscalando = inicioEscalada
	ultimaProximidadEscalada = inicioEscalada
	humanoide:SetAttribute("EscaladaActiva", true)
	humanoide:SetAttribute("EscaladaEstado", "Escalando")
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	humanoide:ChangeState(Enum.HumanoidStateType.Climbing)
	humanoide:SetAttribute("EscaladaLenta", factor > 1)
	if not truss:IsA("TrussPart") then iniciarEscaladaPersonalizada() end
	return true
end

RunService.Heartbeat:Connect(function()
	if not escaladaActiva or not humanoide or not rootPart then return end
	if jugadorLocal:GetAttribute("EscaladaSinStamina") then
		alternarEscalada()
		return
	end
	local ahora = os.clock()
	local estado = humanoide:GetState()
	if estado == Enum.HumanoidStateType.Climbing or escaladaPersonalizada then ultimoEstadoEscalando = ahora end
	if escaladaPersonalizada then
		local subir = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
		local bajar = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
		local direccion = UserInputService:GetFocusedTextBox() and 0 or (subir and 1 or 0) - (bajar and 1 or 0)
		local velocidad = math.min(humanoide.WalkSpeed * 0.55, 9)
		escaladaPersonalizada.velocidad.VectorVelocity = Vector3.new(0, direccion * velocidad, 0)
	end
	local cercano = escaladaPersonalizada and trussActivo or escalableCercano(6.5)
	if cercano and (not cercano:IsDescendantOf(workspace) or distanciaEscalable(cercano) > 6.5) then cercano = nil end
	if cercano then
		trussActivo = cercano
		ultimaProximidadEscalada = ahora
	end
	humanoide:SetAttribute("EscaladaLenta", (jugadorLocal:GetAttribute("Stamina") or 0) < 15)
	local terminoNaturalmente = ahora - inicioEscalada > 0.8
		and ahora - ultimoEstadoEscalando > 0.2
		and humanoide.FloorMaterial ~= Enum.Material.Air
	if not trussActivo or not trussActivo.Parent or ahora - ultimaProximidadEscalada > 0.65
		or terminoNaturalmente then
		escaladaActiva = false
		trussActivo = nil
		limpiarEscaladaPersonalizada()
		pcall(function() SolicitarParkour:InvokeServer("EscaladaFin") end)
		humanoide:SetAttribute("EscaladaActiva", false)
		humanoide:SetAttribute("EscaladaEstado", "NoEscalando")
		humanoide:SetAttribute("EscaladaLenta", nil)
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		-- Al coronar una subida Roblox puede conservar brevemente el estado
		-- Climbing aunque ya haya suelo. Forzar la transición evita que el
		-- primer salto después de llegar arriba se pierda.
		humanoide:ChangeState(humanoide.FloorMaterial ~= Enum.Material.Air
			and Enum.HumanoidStateType.Running or Enum.HumanoidStateType.Freefall)
		return
	end
end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado and input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end
	if UserInputService:GetFocusedTextBox() then return end
	local interfaz = jugadorLocal.PlayerGui:FindFirstChild("PantallaPrincipal_1v1_GUI")
	if interfaz and ((interfaz:FindFirstChild("HowToPlayModal") and interfaz.HowToPlayModal.Visible)
		or (interfaz:FindFirstChild("DonationConfirmation") and interfaz.DonationConfirmation.Visible)) then return end

	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end

	if accionActiva or cooldown then
		return
	end

	if not obtenerPersonaje() then
		return
	end
	if humanoide:GetAttribute("Sliding") then return end
	if escaladaActiva then
		alternarEscalada()
		return
	end
	-- The pallet controller owns right-click whenever a pallet endpoint is in range.
	for _, objeto in ipairs(workspace:GetDescendants()) do
		if objeto:IsA("BasePart")
			and (objeto.Name == "PuntoPale_1" or objeto.Name == "PuntoPale_2")
			and (rootPart.Position - objeto.Position).Magnitude <= 6.5
			and math.abs(rootPart.Position.Y - objeto.Position.Y) <= 4.5 then
			local pale = objeto.Parent
			local estado = pale and (pale:GetAttribute("EstadoPale") or "Parado")
			local rol = jugadorLocal:GetAttribute("Rol")
			if (rol == "PERSEGUIDO" and (estado == "Parado" or estado == "Caido"))
				or (rol == "PERSEGUIDOR" and estado == "Caido"
					and not pale:GetAttribute("Rompiendo")) then
				return
			end
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

	limpiarEscaladaPersonalizada()
	obtenerPersonaje()
	escaladaActiva = false
	trussActivo = nil
	humanoide:SetAttribute("EscaladaActiva", false)
	humanoide:SetAttribute("EscaladaEstado", "NoEscalando")
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	accionActiva = false
	cooldown = false

	antiGravity = nil
	antiGravityAttachment = nil

	precargarAnimaciones()
end)

if obtenerPersonaje() then
	humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoide:SetAttribute("EscaladaActiva", false)
	humanoide:SetAttribute("EscaladaEstado", "NoEscalando")
	precargarAnimaciones()
end
