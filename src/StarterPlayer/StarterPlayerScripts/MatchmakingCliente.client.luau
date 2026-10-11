local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local EventoMatchmaking = ReplicatedStorage:WaitForChild("EventoMatchmaking")
if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
	return
end

--==================================================
-- INTERFAZ
--==================================================

local pantallaGui = Instance.new("ScreenGui")
pantallaGui.Name = "MatchmakingGui"
pantallaGui.ResetOnSpawn = false
pantallaGui.Parent = jugador:WaitForChild("PlayerGui")

local boton = Instance.new("TextButton")
boton.AnchorPoint = Vector2.new(0.5, 1)
boton.Position = UDim2.fromScale(0.5, 0.9)
boton.Size = UDim2.fromOffset(260, 60)
boton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
boton.TextColor3 = Color3.new(1, 1, 1)
boton.TextScaled = true
boton.Font = Enum.Font.GothamBold
boton.Text = "Play"
boton.Parent = pantallaGui

local esquina = Instance.new("UICorner")
esquina.CornerRadius = UDim.new(0, 12)
esquina.Parent = boton

local mensaje = Instance.new("TextLabel")
mensaje.AnchorPoint = Vector2.new(0.5, 1)
mensaje.Position = UDim2.fromScale(0.5, 0.82)
mensaje.Size = UDim2.fromOffset(400, 36)
mensaje.BackgroundTransparency = 1
mensaje.TextColor3 = Color3.new(1, 1, 1)
mensaje.TextStrokeTransparency = 0.5
mensaje.TextScaled = true
mensaje.Font = Enum.Font.Gotham
mensaje.Text = ""
mensaje.Parent = pantallaGui

--==================================================
-- ESTADO
--==================================================

local buscando = false
local bloqueado = false

local function mostrarEstado(estado)
	if estado == "EN_COLA" then
		buscando = true
		boton.Text = "Cancel Search"
		boton.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
		mensaje.Text = "Searching for opponent..."

	elseif estado == "FUERA_DE_COLA" then
		buscando = false
		boton.Text = "Play"
		boton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
		mensaje.Text = ""

	elseif estado == "ENCONTRADO" then
		bloqueado = true
		boton.Visible = false
		mensaje.Text = "Opponent found! Entering the match..."

	elseif estado == "ERROR" then
		bloqueado = false
		buscando = false
		boton.Visible = true
		boton.Text = "Play"
		boton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
		mensaje.Text = "Could not create the match. Try again."
	end
end

EventoMatchmaking.OnClientEvent:Connect(mostrarEstado)

boton.Activated:Connect(function()
	if bloqueado then
		return
	end

	if buscando then
		EventoMatchmaking:FireServer("CANCELAR")
	else
		EventoMatchmaking:FireServer("BUSCAR")
	end
end)
