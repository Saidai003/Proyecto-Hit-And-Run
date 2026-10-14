local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StaminaService = require(script.Parent:WaitForChild("StaminaService"))
local ParkourPairs = require(ReplicatedStorage:WaitForChild("ParkourPairs"))
local Climbables = require(ReplicatedStorage:WaitForChild("Climbables"))
local audio = require(ReplicatedStorage:WaitForChild("AudioPlayback"))

local remote = ReplicatedStorage:WaitForChild("SolicitarParkour1v1")
local slides = {}
local escaladas = {}

local function sueloCercanoSlide(character, root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local suelo = Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
	return suelo and suelo.Distance <= 4.25 and suelo.Normal.Y > 0.2
end

local function liberarSlide(jugador)
	local estado = slides[jugador]
	if not estado then return end
	slides[jugador] = nil
	StaminaService.EndSlide(jugador)
	if estado.collider then estado.collider:Destroy() end
	for parte, canCollide in pairs(estado.colisiones) do
		if parte.Parent then parte.CanCollide = canCollide end
	end
	if estado.humanoide.Parent then estado.humanoide:SetAttribute("Sliding", false) end
end

local function puedeLevantarse(estado)
	local root = estado.root
	if not root.Parent then return true end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { estado.character }
	rayParams.RespectCanCollide = true
	local ground = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
	if not ground then return true end
	local desdeSuelo = Vector3.new(root.Position.X, ground.Position.Y + 1.2, root.Position.Z)
	local techo = Workspace:Raycast(desdeSuelo, Vector3.new(0, 4.6, 0), rayParams)
	return not (techo and techo.Instance.CanCollide)
end

local function crearColliderSlide(character, root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local suelo = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
	local distancia = suelo and suelo.Distance or 3
	local collider = Instance.new("Part")
	collider.Name = "SlideCollider"
	collider.Size = Vector3.new(2, 1.2, 2)
	collider.Transparency = 1
	collider.CanCollide = true
	collider.CanTouch = false
	collider.CanQuery = false
	collider.Massless = true
	collider.CollisionGroup = root.CollisionGroup
	collider.CFrame = root.CFrame * CFrame.new(0, -math.max(0.8, distancia - 0.7), 0)
	collider.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = collider
	weld.Parent = collider
	return collider
end

local nombres = { Ventana = "PuntoSalto", Estrecho = "PuntoEntrada" }
local function distanciaParte(parte, posicion)
	local localPos = parte.CFrame:PointToObjectSpace(posicion)
	local mitad = parte.Size * 0.5
	local cercano = Vector3.new(
		math.clamp(localPos.X, -mitad.X, mitad.X),
		math.clamp(localPos.Y, -mitad.Y, mitad.Y),
		math.clamp(localPos.Z, -mitad.Z, mitad.Z)
	)
	return (localPos - cercano).Magnitude
end

local function tocaSuelo(character, root, humanoide)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local alcance = humanoide.HipHeight + root.Size.Y * 0.5 + 1
	return Workspace:Raycast(root.Position, Vector3.new(0, -alcance, 0), params) ~= nil
end

remote.OnServerInvoke = function(jugador, accion, origen, destino)
	if typeof(accion) ~= "string" then return nil end
	local character = jugador.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoide = character and character:FindFirstChildOfClass("Humanoid")
	if accion == "EscaladaFin" then
		local escalable = escaladas[jugador]
		escaladas[jugador] = nil
		if root and humanoide and escalable and escalable.Parent then
			local bordeSuperior = escalable.Position.Y + escalable.Size.Y * 0.5
			local cercaDeCima = root.Position.Y >= bordeSuperior - 2.5
			local cercaDelEscalable = distanciaParte(escalable, root.Position) <= 7
			if cercaDeCima and cercaDelEscalable then
				-- Una ventana corta permite saltar al coronar aunque FloorMaterial
				-- tarde un frame en actualizarse. Solo vale tras una escalada real.
				humanoide:SetAttribute("ClimbJumpGraceUntil", Workspace:GetServerTimeNow() + 0.75)
			end
		end
		StaminaService.EndClimb(jugador)
		if root then
			local climbSound = root:FindFirstChild("Climb")
			if climbSound and climbSound:IsA("Sound") then climbSound:Destroy() end
		end
		if humanoide then humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end
		return true
	end
	if accion == "SlideEnd" then
		local estado = slides[jugador]
		if not estado then return true end
		if not puedeLevantarse(estado) then return false end
		liberarSlide(jugador)
		return true
	end
	if not (Workspace:GetAttribute("RondaEnJuego") or Workspace:GetAttribute("LobbyPractica")) then return nil end
	if not root or not humanoide or humanoide.Health <= 0
		or humanoide:GetAttribute("Inmovilizado") or humanoide:GetAttribute("FallStunned") then return nil end
	if accion == "SlideStart" then
		if slides[jugador] or humanoide:GetAttribute("ParkourEspecialActivo")
			or humanoide:GetAttribute("EscaladaActiva") or humanoide:GetAttribute("Sliding")
			or humanoide:GetAttribute("GolpeActivo") or humanoide:GetAttribute("AttackRecovery")
			or not sueloCercanoSlide(character, root)
			or not StaminaService.BeginSlide(jugador, root) then return nil end
		local colisiones = {}
		for _, parte in ipairs(character:GetDescendants()) do
			if parte:IsA("BasePart") then
				colisiones[parte] = parte.CanCollide
				parte.CanCollide = false
			end
		end
		local collider = crearColliderSlide(character, root)
		slides[jugador] = {
			character = character,
			humanoide = humanoide,
			root = root,
			collider = collider,
			colisiones = colisiones,
		}
		humanoide:SetAttribute("Sliding", true)
		return true
	end
	if accion == "Salto" then
		local graciaEscalada = (humanoide:GetAttribute("ClimbJumpGraceUntil") or 0) >= Workspace:GetServerTimeNow()
		if not tocaSuelo(character, root, humanoide) and not graciaEscalada
			or humanoide:GetAttribute("ParkourEspecialActivo")
			or humanoide:GetAttribute("EscaladaActiva")
			or humanoide:GetAttribute("Sliding") then return nil end
		humanoide:SetAttribute("ClimbJumpGraceUntil", nil)
		return StaminaService.Consume(jugador, accion)
	end
	if accion == "Escalada" then
		if humanoide:GetAttribute("Sliding") then return nil end
		if typeof(origen) ~= "Instance" or not Climbables.IsClimbable(origen) or not origen:IsDescendantOf(Workspace)
			or distanciaParte(origen, root.Position) > 5.5 then return nil end
		local factor = StaminaService.BeginClimb(jugador, root, not origen:IsA("TrussPart"))
		if factor then
			escaladas[jugador] = origen
			humanoide:SetAttribute("ClimbJumpGraceUntil", nil)
			humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			local previousSound = root:FindFirstChild("Climb")
			if previousSound and previousSound:IsA("Sound") then previousSound:Destroy() end
			audio.Play("Climb", root, 0.45, false, true)
		end
		return factor
	end
	local prefijo = nombres[accion]
	if humanoide:GetAttribute("Sliding") then return nil end
	if not prefijo or typeof(origen) ~= "Instance" or typeof(destino) ~= "Instance"
		or not origen:IsA("BasePart") or not destino:IsA("BasePart")
		or not origen:IsDescendantOf(Workspace) or not destino:IsDescendantOf(Workspace)
		or origen == destino or origen.Parent ~= destino.Parent
		or ParkourPairs.Resolve(origen) ~= destino
		or not origen.Name:match("^" .. prefijo .. "_[12]$")
		or not destino.Name:match("^" .. prefijo .. "_[12]$")
		or origen.Name == destino.Name
		or (root.Position - origen.Position).Magnitude > 6.3
		or math.abs(root.Position.Y - origen.Position.Y) > 4.5
		or (origen.Position - destino.Position).Magnitude > 30 then return nil end
	local factor = StaminaService.Consume(jugador, accion)
	if factor and accion == "Ventana" then audio.Play("VaultWindow", root, 0.65, 5) end
	return factor
end

local function prepararJugador(jugador)
	jugador.CharacterRemoving:Connect(function() liberarSlide(jugador) end)
	jugador.CharacterAdded:Connect(function(character)
		local humanoide = character:WaitForChild("Humanoid")
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end)
	if jugador.Character then
		local humanoide = jugador.Character:FindFirstChildOfClass("Humanoid")
		if humanoide then humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end
	end
end
Players.PlayerRemoving:Connect(function(jugador)
	liberarSlide(jugador)
	escaladas[jugador] = nil
end)
RunService.Heartbeat:Connect(function()
	for jugador, estado in pairs(slides) do
		if jugador.Parent ~= Players or jugador.Character ~= estado.character
			or estado.humanoide.Health <= 0 or estado.humanoide:GetAttribute("FallStunned")
			or estado.humanoide:GetAttribute("Inmovilizado")
			or not (Workspace:GetAttribute("RondaEnJuego") or Workspace:GetAttribute("LobbyPractica")) then
			liberarSlide(jugador)
		else
			for parte in pairs(estado.colisiones) do
				if parte.Parent and parte.CanCollide then parte.CanCollide = false end
			end
		end
	end
end)
Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in ipairs(Players:GetPlayers()) do prepararJugador(jugador) end
