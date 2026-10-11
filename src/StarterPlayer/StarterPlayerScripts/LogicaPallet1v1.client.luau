local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local jugadorLocal = Players.LocalPlayer
local EventoPale = ReplicatedStorage:WaitForChild("EventoPale1v1", 5)

--==================================================
-- IDs DE ANIMACIONES
--==================================================
local ANIM_SLOW_VAULT = "rbxassetid://113078777285485"
local ANIM_FAST_VAULT = "rbxassetid://91247705762076"
local ANIM_DROP = "rbxassetid://95338026656426"
local ANIM_HIT = "rbxassetid://122984890985296"

local DISTANCIA_INTERACCION = 7
local DISTANCIA_LLEGADA = 0.1
local VELOCIDAD_APROXIMACION = 10
local debounce = false

--==================================================
-- FUNCIONES AUXILIARES
--==================================================
local function reproducirAnimacion(idAnimacion)
	local character = jugadorLocal.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animacion = Instance.new("Animation")
	animacion.AnimationId = idAnimacion

	local track = animator:LoadAnimation(animacion)
	track:Play()
	return track
end

-- Nueva bÃºsqueda optimizada para tu estructura de Folder
local function obtenerPaleCercano(posicionJugador)
	local mejorPale = nil
	local mejorDistancia = DISTANCIA_INTERACCION

	-- Buscamos los bloques fÃ­sicos PuntoPale_1 directamente
	for _, objeto in ipairs(Workspace:GetDescendants()) do
		if objeto:IsA("BasePart") and objeto.Name == "PuntoPale_1" then
			local contenedor = objeto.Parent -- Este es tu Folder "Pallet_01"

			if contenedor then
				local p2 = contenedor:FindFirstChild("PuntoPale_2")

				if p2 then
					local dist1 = (posicionJugador - objeto.Position).Magnitude
					local dist2 = (posicionJugador - p2.Position).Magnitude
					local distancia = math.min(dist1, dist2)

					if distancia <= mejorDistancia then
						mejorDistancia = distancia
						mejorPale = contenedor
					end
				end
			end
		end
	end

	return mejorPale
end

-- Devuelve el PuntoPale mÃ¡s cercano al jugador y el Punto
-- opuesto dentro de ese pale. La misma idea que
-- obtenerPuntoOpuesto en LogicaParkour1v1, pero scoped al
-- contenedor del pale.
local function obtenerPuntosDelPale(contenedor, posicionJugador)
	local p1 = contenedor:FindFirstChild("PuntoPale_1")
	local p2 = contenedor:FindFirstChild("PuntoPale_2")

	if not p1 or not p2 then
		return nil, nil
	end

	local d1 = (posicionJugador - p1.Position).Magnitude
	local d2 = (posicionJugador - p2.Position).Magnitude

	if d1 <= d2 then
		return p1, p2
	else
		return p2, p1
	end
end

-- Aproxima al personaje al Punto mÃ¡s cercano del pale con
-- un tween, conservando la altura actual del root. Al
-- terminar, lo reorienta para mirar hacia el Punto
-- opuesto. Misma mecÃ¡nica que aproximarseAlPunto en
-- LogicaParkour1v1, aplicada al salto de pale para que no
-- sea un movimiento brusco cuando se pulsa Space lejos del
-- Punto exacto.
local function aproximarseAlPuntoDelPale(puntoCercano, puntoOpuesto)
	local character = jugadorLocal.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- DirecciÃ³n horizontal del salto: del Punto cercano al
	-- Punto opuesto. Se proyecta al plano XZ para que la
	-- rotaciÃ³n no tenga componente vertical.
	local diferenciaHorizontal =
		(puntoOpuesto.Position - puntoCercano.Position)
		* Vector3.new(1, 0, 1)

	local direccion
	if diferenciaHorizontal.Magnitude > 0.01 then
		direccion = diferenciaHorizontal.Unit
	else
		direccion = root.CFrame.LookVector
	end

	-- PosiciÃ³n objetivo: X/Z del Punto, Y actual del root
	-- (para no levantarlo del suelo al acercarlo).
	local posicionObjetivo = Vector3.new(
		puntoCercano.Position.X,
		root.Position.Y,
		puntoCercano.Position.Z
	)

	local distancia =
		(root.Position - posicionObjetivo).Magnitude

	-- Si ya estÃ¡ lo bastante cerca, basta con reorientar.
	if distancia <= DISTANCIA_LLEGADA then
		root.CFrame = CFrame.lookAt(
			root.Position,
			root.Position + direccion
		)
		return
	end

	local duracion = distancia / VELOCIDAD_APROXIMACION

	local tween = TweenService:Create(
		root,
		TweenInfo.new(
			duracion,
			Enum.EasingStyle.Linear
		),
		{
			CFrame = CFrame.lookAt(
				posicionObjetivo,
				posicionObjetivo + direccion
			)
		}
	)

	tween:Play()
	tween.Completed:Wait()

	-- Reorientar al llegar para que el personaje quede
	-- mirando al pale antes de que arranque la animaciÃ³n
	-- de vault.
	root.CFrame = CFrame.lookAt(
		root.Position,
		root.Position + direccion
	)
end

--==================================================
-- DETECCIÃN DE TECLADO
--==================================================
UserInputService.InputBegan:Connect(function(input, procesado)
	if UserInputService:GetFocusedTextBox() ~= nil then return end

	if input.KeyCode == Enum.KeyCode.Space then
		if debounce then return end

		local character = jugadorLocal.Character
		if not character then return end

		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not root or not humanoid or humanoid.Health <= 0 then return end
		if humanoid:GetAttribute("Inmovilizado") or humanoid:GetAttribute("ParkourEspecialActivo")
			or humanoid:GetAttribute("EscaladaActiva") then return end

		local rol = jugadorLocal:GetAttribute("Rol")
		local pale = obtenerPaleCercano(root.Position)

		if not pale then return end

		-- Leemos el estado. Si Roblox se demorÃ³ en replicar el atributo al Folder, asume "Parado".
		local estado = pale:GetAttribute("EstadoPale") or "Parado"
		local rompiendo = pale:GetAttribute("Rompiendo") or false

		-- 1. SOBREVIVIENTE (PERSEGUIDO)
		if rol == "PERSEGUIDO" then
			if estado == "Parado" then
				debounce = true
				reproducirAnimacion(ANIM_DROP)
				EventoPale:FireServer("INTERACTUAR")

				task.wait(0.8)
				debounce = false

			elseif estado == "Caido" then
				debounce = true

				-- Misma mecÃ¡nica que las acciones de parkour
				-- (saltar ventana, lugar estrecho): si el
				-- jugador estÃ¡ dentro del rango de interacciÃ³n
				-- pero no en el Punto exacto, primero lo
				-- aproximamos al Punto mÃ¡s cercano con un
				-- tween, lo reorientamos para mirar al pale, y
				-- solo entonces disparamos el FireServer. Esto
				-- evita que el salto arranque con un cambio
				-- brusco de posiciÃ³n.
				local pCercano, pOpuesto = obtenerPuntosDelPale(
					pale,
					root.Position
				)

				if pCercano and pOpuesto then
					aproximarseAlPuntoDelPale(
						pCercano,
						pOpuesto
					)
				end

				local esRapido = humanoid.WalkSpeed > 12
				local trackAnim = reproducirAnimacion(esRapido and ANIM_FAST_VAULT or ANIM_SLOW_VAULT)
				local duracionSalto = (trackAnim and trackAnim.Length > 0) and trackAnim.Length or 0.6

				-- El servidor valida la distancia, calcula el
				-- destino parabÃ³lico y dispara el tween vÃ­a
				-- SaltoPaleCliente. Antes el cliente corrÃ­a su
				-- propio tween recto en paralelo, lo que provocaba
				-- saltos bruscos de cÃ¡mara. Las escrituras a
				-- "BloqueoPale" eran cÃ³digo muerto: el hijo real
				-- es "InvisibleWall".
				EventoPale:FireServer("INTERACTUAR")

				task.wait(duracionSalto)
				debounce = false
			end

			-- 2. ASESINO (PERSEGUIDOR)
		elseif rol == "PERSEGUIDOR" then
			if estado == "Caido" and not rompiendo then
				debounce = true
				local trackBreak = reproducirAnimacion(ANIM_HIT)
				-- Leemos la duraciÃ³n REAL de la animaciÃ³n de
				-- romper y se la pasamos al servidor. Antes el
				-- servidor usaba TIEMPO_ROMPER = 2.0 hardcodeado
				-- y el cliente esperaba otros 2.0 tambiÃ©n; si la
				-- animaciÃ³n duraba menos, el pale terminaba la
				-- animaciÃ³n y se quedaba un segundo parado antes
				-- de romperse de verdad.
				local duracionBreak = (trackBreak and trackBreak.Length > 0) and trackBreak.Length or 2.0
				EventoPale:FireServer("INTERACTUAR", duracionBreak)

				task.wait(duracionBreak)
				debounce = false
			end
		end
	end
end)
