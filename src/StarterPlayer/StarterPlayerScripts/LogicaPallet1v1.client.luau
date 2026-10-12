local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")

local jugadorLocal = Players.LocalPlayer
local EventoPale = ReplicatedStorage:WaitForChild("EventoPale1v1", 5)

--==================================================
-- IDs DE ANIMACIONES
--==================================================
local ANIM_SLOW_VAULT = "rbxassetid://113078777285485"
local ANIM_FAST_VAULT = "rbxassetid://91247705762076"
local ANIM_DROP = "rbxassetid://95338026656426"
local ANIM_HIT = "rbxassetid://122984890985296"

local DISTANCIA_INTERACCION = 6.5
local DISTANCIA_INICIO_ANIMACION = 1.8
local debounce = false
local animaciones = {}

for _, id in ipairs({ ANIM_SLOW_VAULT, ANIM_FAST_VAULT, ANIM_DROP, ANIM_HIT }) do
	local animacion = Instance.new("Animation")
	animacion.AnimationId = id
	animaciones[id] = animacion
end

task.spawn(function()
	local lista = {}
	for _, animacion in pairs(animaciones) do table.insert(lista, animacion) end
	pcall(function() ContentProvider:PreloadAsync(lista) end)
end)

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

	local animacion = animaciones[idAnimacion]
	if not animacion then return nil end
	local ok, track = pcall(function() return animator:LoadAnimation(animacion) end)
	if not ok or not track then
		warn("[PALET] No se pudo cargar la animacion " .. idAnimacion)
		return nil
	end
	-- Las acciones del pallet deben imponerse a caminar, al bate y a otras
	-- animaciones de movimiento mientras dura la interacción.
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(0.05, 1, 1)
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

					if distancia <= mejorDistancia
						and math.min(math.abs(posicionJugador.Y - objeto.Position.Y),
							math.abs(posicionJugador.Y - p2.Position.Y)) <= 4.5 then
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
-- sea un movimiento brusco cuando se pulsa clic derecho lejos del
-- Punto exacto.
local function aproximarseAlPuntoDelPale(puntoCercano)
	local character = jugadorLocal.Character
	if not character then return false end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	-- PosiciÃ³n objetivo: X/Z del Punto, Y actual del root
	-- (para no levantarlo del suelo al acercarlo).
	local posicionObjetivo = Vector3.new(
		puntoCercano.Position.X,
		root.Position.Y,
		puntoCercano.Position.Z
	)

	local distancia =
		(root.Position - posicionObjetivo).Magnitude

	if distancia <= DISTANCIA_INICIO_ANIMACION then return true end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	local limite = os.clock() + math.max(1, distancia / math.max(humanoid.WalkSpeed, 1) + 1)
	while os.clock() < limite and root.Parent and humanoid.Parent do
		local restante = (Vector3.new(root.Position.X, posicionObjetivo.Y, root.Position.Z) - posicionObjetivo).Magnitude
		if restante <= DISTANCIA_INICIO_ANIMACION then
			humanoid:MoveTo(root.Position)
			return true
		end
		humanoid:MoveTo(posicionObjetivo)
		RunService.Heartbeat:Wait()
	end
	humanoid:MoveTo(root.Position)
	return false
end

--==================================================
-- DETECCIÃN DE TECLADO
--==================================================
UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	if UserInputService:GetFocusedTextBox() ~= nil then return end
	local interfaz = jugadorLocal.PlayerGui:FindFirstChild("PantallaPrincipal_1v1_GUI")
	if interfaz and ((interfaz:FindFirstChild("HowToPlayModal") and interfaz.HowToPlayModal.Visible)
		or (interfaz:FindFirstChild("DonationConfirmation") and interfaz.DonationConfirmation.Visible)) then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if debounce then return end

		local character = jugadorLocal.Character
		if not character then return end

		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not root or not humanoid or humanoid.Health <= 0 then return end
		if humanoid:GetAttribute("Inmovilizado") or humanoid:GetAttribute("ParkourEspecialActivo")
			or humanoid:GetAttribute("EscaladaActiva") or humanoid:GetAttribute("Sliding") then return end

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
					local llego = aproximarseAlPuntoDelPale(pCercano)
					if not llego then
						debounce = false
						return
					end
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
