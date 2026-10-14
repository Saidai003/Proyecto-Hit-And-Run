local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ParkourPairs = require(ReplicatedStorage:WaitForChild("ParkourPairs"))
local Climbables = require(ReplicatedStorage:WaitForChild("Climbables"))

local jugador = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ParkourPrompt"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = jugador:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "ActionPrompt"
panel.Size = UDim2.fromOffset(260, 48)
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -34)
panel.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
panel.BackgroundTransparency = 0.13
panel.Visible = false
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local key = Instance.new("TextLabel")
key.Name = "RightMouseKey"
key.Size = UDim2.fromOffset(72, 34)
key.Position = UDim2.fromOffset(7, 7)
key.BackgroundColor3 = Color3.fromRGB(42, 47, 56)
key.Text = "RMB"
key.TextColor3 = Color3.new(1, 1, 1)
key.TextSize = 17
key.Font = Enum.Font.GothamBold
key.Parent = panel
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 6)
keyCorner.Parent = key

local action = Instance.new("TextLabel")
action.Name = "Action"
action.Size = UDim2.fromOffset(167, 42)
action.Position = UDim2.fromOffset(88, 3)
action.BackgroundTransparency = 1
action.TextXAlignment = Enum.TextXAlignment.Left
action.Text = ""
action.TextColor3 = Color3.fromRGB(242, 245, 249)
action.TextSize = 18
action.Font = Enum.Font.GothamBold
action.Parent = panel

local function distanciaSuperficie(parte, posicion)
	local localPos = parte.CFrame:PointToObjectSpace(posicion)
	local mitad = parte.Size * 0.5
	local cercano = Vector3.new(
		math.clamp(localPos.X, -mitad.X, mitad.X),
		math.clamp(localPos.Y, -mitad.Y, mitad.Y),
		math.clamp(localPos.Z, -mitad.Z, mitad.Z)
	)
	return (localPos - cercano).Magnitude
end

local candidatos = {}
local function registrar(objeto)
	if Climbables.IsClimbable(objeto) or (objeto:IsA("BasePart") and (
		objeto.Name == "PuntoPale_1" or objeto.Name == "PuntoPale_2"
		or objeto.Name == "PuntoSalto_1" or objeto.Name == "PuntoSalto_2"
		or objeto.Name == "PuntoEntrada_1" or objeto.Name == "PuntoEntrada_2")) then
		candidatos[objeto] = true
	end
end
for _, objeto in ipairs(Workspace:GetDescendants()) do registrar(objeto) end
Workspace.DescendantAdded:Connect(registrar)
Workspace.DescendantRemoving:Connect(function(objeto) candidatos[objeto] = nil end)
local function elegirAccion(posicion, rol, humanoide)
	if humanoide:GetAttribute("EscaladaEstado") == "Escalando" then return "Drop Off" end
	local paleMasCercano, distanciaPale = nil, 6.5
	local parqueMasCercano, distanciaParque = nil, 5.8
	local trussMasCercano = 5.5
	for objeto in pairs(candidatos) do
		if Climbables.IsClimbable(objeto) then
			local d = distanciaSuperficie(objeto, posicion)
			if d <= trussMasCercano then trussMasCercano = d end
		elseif objeto:IsA("BasePart") then
			if objeto.Name == "PuntoPale_1" or objeto.Name == "PuntoPale_2" then
				local pale = objeto.Parent
				if pale and pale:FindFirstChild(objeto.Name == "PuntoPale_1" and "PuntoPale_2" or "PuntoPale_1") then
					local estado = pale:GetAttribute("EstadoPale") or "Parado"
					local rompiendo = pale:GetAttribute("Rompiendo")
					local mensaje = nil
					if rol == "PERSEGUIDO" then
						if estado == "Parado" then mensaje = "Drop Pallet"
						elseif estado == "Caido" then mensaje = "Vault Pallet" end
					elseif rol == "PERSEGUIDOR" and estado == "Caido" and not rompiendo then
						mensaje = "Break Pallet"
					end
					local d = (posicion - objeto.Position).Magnitude
					if mensaje and d <= distanciaPale
						and math.abs(posicion.Y - objeto.Position.Y) <= 4.5 then
						paleMasCercano, distanciaPale = mensaje, d
					end
				end
			elseif (objeto.Name == "PuntoSalto_1" or objeto.Name == "PuntoSalto_2"
				or objeto.Name == "PuntoEntrada_1" or objeto.Name == "PuntoEntrada_2")
				and ParkourPairs.Resolve(objeto)
				and math.abs(posicion.Y - objeto.Position.Y) <= 4.5 then
				local d = (posicion - objeto.Position).Magnitude
				if d <= distanciaParque then
					parqueMasCercano = objeto.Name:find("PuntoSalto", 1, true) and "Vault" or "Go Through"
					distanciaParque = d
				end
			end
		end
	end
	if paleMasCercano then return paleMasCercano end
	if parqueMasCercano then return parqueMasCercano end
	if trussMasCercano < 5.5 then return "Climb" end
	return nil
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.12 then return end
	elapsed = 0
	local disponible = Workspace:GetAttribute("RondaEnJuego") == true
		or Workspace:GetAttribute("LobbyPractica") == true
	local character = jugador.Character
	local humanoide = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not disponible or not humanoide or not root or humanoide.Health <= 0
		or humanoide:GetAttribute("Inmovilizado") or humanoide:GetAttribute("FallStunned")
		or humanoide:GetAttribute("ParkourEspecialActivo")
		or humanoide:GetAttribute("Sliding") then
		panel.Visible = false
		jugador:SetAttribute("ParkourAction", nil)
		return
	end
	local mensaje = elegirAccion(root.Position, jugador:GetAttribute("Rol"), humanoide)
	jugador:SetAttribute("ParkourAction", mensaje)
	panel.Visible = mensaje ~= nil and not UserInputService.TouchEnabled
	if mensaje then action.Text = mensaje end
	panel.Position = UDim2.new(0.5, 0, 1, Workspace:GetAttribute("LobbyPractica") and -105 or -34)
end)
