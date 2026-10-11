local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StaminaService = require(script.Parent:WaitForChild("StaminaService"))
local ParkourPairs = require(ReplicatedStorage:WaitForChild("ParkourPairs"))

local remote = ReplicatedStorage:WaitForChild("SolicitarParkour1v1")

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

remote.OnServerInvoke = function(jugador, accion, origen, destino)
	if typeof(accion) ~= "string" then return nil end
	local character = jugador.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoide = character and character:FindFirstChildOfClass("Humanoid")
	if accion == "EscaladaFin" then
		if humanoide then humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end
		return true
	end
	if not Workspace:GetAttribute("RondaEnJuego") then return nil end
	if not root or not humanoide or humanoide.Health <= 0
		or humanoide:GetAttribute("Inmovilizado") or humanoide:GetAttribute("FallStunned") then return nil end
	if accion == "Escalada" then
		if typeof(origen) ~= "Instance" or not origen:IsA("TrussPart") or not origen:IsDescendantOf(Workspace)
			or distanciaParte(origen, root.Position) > 5 then return nil end
		local factor = StaminaService.Consume(jugador, accion)
		if factor then humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, true) end
		return factor
	end
	local prefijo = nombres[accion]
	if not prefijo or typeof(origen) ~= "Instance" or typeof(destino) ~= "Instance"
		or not origen:IsA("BasePart") or not destino:IsA("BasePart")
		or not origen:IsDescendantOf(Workspace) or not destino:IsDescendantOf(Workspace)
		or origen == destino or origen.Parent ~= destino.Parent
		or ParkourPairs.Resolve(origen) ~= destino
		or not origen.Name:match("^" .. prefijo .. "_[12]$")
		or not destino.Name:match("^" .. prefijo .. "_[12]$")
		or origen.Name == destino.Name
		or (root.Position - origen.Position).Magnitude > 5.5
		or (origen.Position - destino.Position).Magnitude > 30 then return nil end
	return StaminaService.Consume(jugador, accion)
end

local function prepararJugador(jugador)
	jugador.CharacterAdded:Connect(function(character)
		local humanoide = character:WaitForChild("Humanoid")
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end)
	if jugador.Character then
		local humanoide = jugador.Character:FindFirstChildOfClass("Humanoid")
		if humanoide then humanoide:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) end
	end
end
Players.PlayerAdded:Connect(prepararJugador)
for _, jugador in ipairs(Players:GetPlayers()) do prepararJugador(jugador) end
