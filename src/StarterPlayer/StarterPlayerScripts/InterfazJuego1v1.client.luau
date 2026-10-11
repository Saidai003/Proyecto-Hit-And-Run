local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

print("[INTERFAZ]: Cargando interfaz 1v1...")

local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")
local EventoAtaque = ReplicatedStorage:WaitForChild("EventoAtaque")
local EventoMatchmaking = ReplicatedStorage:WaitForChild("EventoMatchmaking")
local esPartidaPrivada = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

-- =========================================================
-- LIMPIAR INTERFAZ ANTERIOR
-- =========================================================

local interfazAnterior = playerGui:FindFirstChild("PantallaPrincipal_1v1_GUI")

if interfazAnterior then
	interfazAnterior:Destroy()
end

-- =========================================================
-- SCREEN GUI
-- =========================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PantallaPrincipal_1v1_GUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- =========================================================
-- BANNER
-- =========================================================

local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.Size = UDim2.fromOffset(350, 40)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 16)
banner.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
banner.BackgroundTransparency = 0.18
banner.Text = "HIT & RUN  |  1v1"
banner.TextColor3 = Color3.fromRGB(245, 248, 250)
banner.TextSize = 18
banner.Font = Enum.Font.GothamBold
banner.ZIndex = 1
banner.Parent = screenGui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 10)
bannerCorner.Parent = banner

-- =========================================================
-- MENU
-- =========================================================

local sideMenu = Instance.new("Frame")
sideMenu.Name = "SideMenu"
sideMenu.Size = UDim2.fromOffset(500, 70)
sideMenu.AnchorPoint = Vector2.new(0.5, 1)
sideMenu.Position = UDim2.new(0.5, 0, 1, -18)
sideMenu.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
sideMenu.BackgroundTransparency = 0.18
sideMenu.ZIndex = 10
sideMenu.Parent = screenGui
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = sideMenu

-- =========================================================
-- PLAY NOW
-- =========================================================

local btnPlay = Instance.new("TextButton")
btnPlay.Name = "PlayNow"
btnPlay.Size = UDim2.fromOffset(232, 48)
btnPlay.Position = UDim2.fromOffset(11, 11)
btnPlay.BackgroundColor3 = Color3.fromRGB(45, 180, 80)
btnPlay.BorderSizePixel = 0
btnPlay.Text = "PLAY NOW!"
btnPlay.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPlay.TextSize = 22
btnPlay.Font = Enum.Font.GothamBold
btnPlay.ZIndex = 11
btnPlay.Parent = sideMenu

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 8)
playCorner.Parent = btnPlay

-- =========================================================
-- HOW TO PLAY
-- =========================================================

local btnHowTo = Instance.new("TextButton")
btnHowTo.Name = "HowToPlay"
btnHowTo.Size = UDim2.fromOffset(232, 48)
btnHowTo.Position = UDim2.fromOffset(257, 11)
btnHowTo.BackgroundColor3 = Color3.fromRGB(46, 94, 147)
btnHowTo.BorderSizePixel = 0
btnHowTo.Text = "HOW TO PLAY"
btnHowTo.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHowTo.TextSize = 18
btnHowTo.Font = Enum.Font.GothamBold
btnHowTo.ZIndex = 11
btnHowTo.Parent = sideMenu

local howCorner = Instance.new("UICorner")
howCorner.CornerRadius = UDim.new(0, 8)
howCorner.Parent = btnHowTo

-- =========================================================
-- MODAL HOW TO PLAY
-- =========================================================

local modalHowTo = Instance.new("Frame")
modalHowTo.Name = "HowToPlayModal"
modalHowTo.Size = UDim2.fromOffset(400, 290)
modalHowTo.AnchorPoint = Vector2.new(0.5, 0.5)
modalHowTo.Position = UDim2.fromScale(0.5, 0.5)
modalHowTo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
modalHowTo.BackgroundTransparency = 0.05
modalHowTo.BorderSizePixel = 0
modalHowTo.Visible = false
modalHowTo.ZIndex = 100
modalHowTo.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 10)
modalCorner.Parent = modalHowTo

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -30, 0, 35)
modalTitle.Position = UDim2.new(0, 15, 0, 15)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "HOW TO PLAY"
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.TextSize = 24
modalTitle.Font = Enum.Font.GothamBold
modalTitle.ZIndex = 101
modalTitle.Parent = modalHowTo

local modalDescription = Instance.new("TextLabel")
modalDescription.Size = UDim2.new(1, -30, 0, 185)
modalDescription.Position = UDim2.new(0, 15, 0, 55)
modalDescription.BackgroundTransparency = 1
modalDescription.Text = [[
Play as a Runner or Killer!

- RUNNER: Outsmart the Killer and survive until time runs out.
- KILLER: Hunt down and eliminate the Runner using [F].

[CONTROLS]: Hold Shift to sprint. Space vaults windows/pallets,
squeezes through gaps, or toggles climbing near a truss.
These actions use stamina; low stamina slows parkour.
]]
modalDescription.TextColor3 = Color3.fromRGB(220, 220, 220)
modalDescription.TextSize = 16
modalDescription.Font = Enum.Font.Gotham
modalDescription.TextWrapped = true
modalDescription.TextXAlignment = Enum.TextXAlignment.Left
modalDescription.TextYAlignment = Enum.TextYAlignment.Top
modalDescription.ZIndex = 101
modalDescription.Parent = modalHowTo

local btnCloseModal = Instance.new("TextButton")
btnCloseModal.Size = UDim2.new(0, 120, 0, 35)
btnCloseModal.Position = UDim2.new(0.5, -60, 1, -50)
btnCloseModal.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
btnCloseModal.BorderSizePixel = 0
btnCloseModal.Text = "GOT IT!"
btnCloseModal.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCloseModal.TextSize = 16
btnCloseModal.Font = Enum.Font.GothamBold
btnCloseModal.ZIndex = 101
btnCloseModal.Parent = modalHowTo

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = btnCloseModal

-- =========================================================
-- HUD DE PARTIDA
-- =========================================================

local hudPanel = Instance.new("Frame")
hudPanel.Name = "MatchHud"
hudPanel.Size = UDim2.fromOffset(312, 132)
hudPanel.Position = UDim2.new(0, 16, 1, -148)
hudPanel.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
hudPanel.BackgroundTransparency = 0.17
hudPanel.BorderSizePixel = 0
hudPanel.Visible = false
hudPanel.ZIndex = 19
hudPanel.Parent = screenGui
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hudPanel

local roleLabel = Instance.new("TextLabel")
roleLabel.Name = "Role"
roleLabel.Size = UDim2.fromOffset(288, 34)
roleLabel.Position = UDim2.fromOffset(12, 8)
roleLabel.BackgroundTransparency = 1
roleLabel.TextXAlignment = Enum.TextXAlignment.Left
roleLabel.Text = ""
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.TextSize = 24
roleLabel.Font = Enum.Font.GothamBold
roleLabel.Visible = false
roleLabel.ZIndex = 20
roleLabel.Parent = hudPanel

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "Stamina"
staminaLabel.Size = UDim2.fromOffset(288, 30)
staminaLabel.Position = UDim2.fromOffset(12, 47)
staminaLabel.BackgroundTransparency = 1
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.TextSize = 18
staminaLabel.Font = Enum.Font.GothamBold
staminaLabel.Visible = false
staminaLabel.ZIndex = 20
staminaLabel.Parent = hudPanel

local function actualizarStamina()
	local actual = jugador:GetAttribute("Stamina") or 0
	local maximo = jugador:GetAttribute("StaminaMax") or 100
	staminaLabel.Text = string.format("STAMINA  %d / %d", math.floor(actual), maximo)
	staminaLabel.TextColor3 = actual < 25
		and Color3.fromRGB(255, 120, 85) or Color3.fromRGB(120, 220, 160)
end
jugador:GetAttributeChangedSignal("Stamina"):Connect(actualizarStamina)
jugador:GetAttributeChangedSignal("StaminaMax"):Connect(actualizarStamina)
actualizarStamina()

local livesLabel = Instance.new("TextLabel")
livesLabel.Name = "Lives"
livesLabel.Size = UDim2.fromOffset(288, 32)
livesLabel.Position = UDim2.fromOffset(12, 85)
livesLabel.BackgroundTransparency = 1
livesLabel.TextXAlignment = Enum.TextXAlignment.Left
livesLabel.Text = ""
livesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
livesLabel.TextSize = 22
livesLabel.Font = Enum.Font.GothamBold
livesLabel.Visible = false
livesLabel.ZIndex = 20
livesLabel.Parent = hudPanel

local rivalLivesLabel = Instance.new("TextLabel")
rivalLivesLabel.Name = "RivalLives"
rivalLivesLabel.Size = UDim2.fromOffset(288, 32)
rivalLivesLabel.Position = UDim2.fromOffset(12, 85)
rivalLivesLabel.BackgroundTransparency = 1
rivalLivesLabel.Text = ""
rivalLivesLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
rivalLivesLabel.TextSize = 22
rivalLivesLabel.Font = Enum.Font.GothamBold
rivalLivesLabel.TextXAlignment = Enum.TextXAlignment.Left
rivalLivesLabel.Visible = false
rivalLivesLabel.ZIndex = 20
rivalLivesLabel.Parent = hudPanel

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "Round"
roundLabel.Size = UDim2.new(0, 250, 0, 35)
roundLabel.Position = UDim2.new(1, -270, 0, 20)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = ""
roundLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
roundLabel.TextSize = 20
roundLabel.Font = Enum.Font.Gotham
roundLabel.Visible = false
roundLabel.ZIndex = 20
roundLabel.Parent = screenGui

-- =========================================================
-- ATTACK
-- =========================================================

local attackButton = Instance.new("TextButton")
attackButton.Name = "AttackButton"
attackButton.Size = UDim2.new(0, 180, 0, 55)
attackButton.Position = UDim2.new(1, -210, 1, -80)
attackButton.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
attackButton.BorderSizePixel = 0
attackButton.Text = "ATTACK [F]"
attackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
attackButton.TextSize = 18
attackButton.Font = Enum.Font.GothamBold
attackButton.Visible = false
attackButton.ZIndex = 20
attackButton.Parent = screenGui

local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 8)
attackCorner.Parent = attackButton

-- =========================================================
-- MENSAJE CENTRAL
-- =========================================================

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Size = UDim2.fromOffset(460, 76)
messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
messageLabel.Position = UDim2.fromScale(0.5, 0.45)
messageLabel.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
messageLabel.BackgroundTransparency = 0.2
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextSize = 28
messageLabel.Font = Enum.Font.GothamBold
messageLabel.Visible = false
messageLabel.ZIndex = 20
messageLabel.Parent = screenGui
local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 10)
messageCorner.Parent = messageLabel

-- =========================================================
-- RESULTADO FINAL
-- =========================================================

local resultPanel = Instance.new("Frame")
resultPanel.Name = "FinalResult"
resultPanel.Size = UDim2.new(0, 400, 0, 220)
resultPanel.Position = UDim2.new(0.5, -200, 0.5, -110)
resultPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
resultPanel.BorderSizePixel = 0
resultPanel.Visible = false
resultPanel.ZIndex = 50
resultPanel.Parent = screenGui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 10)
resultCorner.Parent = resultPanel

local player1Label = Instance.new("TextLabel")
player1Label.Size = UDim2.new(0.5, -10, 0, 35)
player1Label.Position = UDim2.new(0, 10, 0, 85)
player1Label.BackgroundTransparency = 1
player1Label.Text = ""
player1Label.TextColor3 = Color3.fromRGB(220, 220, 220)
player1Label.TextSize = 18
player1Label.Font = Enum.Font.Gotham
player1Label.ZIndex = 51
player1Label.Parent = resultPanel


local player2Label = Instance.new("TextLabel")
player2Label.Size = UDim2.new(0.5, -10, 0, 35)
player2Label.Position = UDim2.new(0.5, 0, 0, 85)
player2Label.BackgroundTransparency = 1
player2Label.Text = ""
player2Label.TextColor3 = Color3.fromRGB(220, 220, 220)
player2Label.TextSize = 18
player2Label.Font = Enum.Font.Gotham
player2Label.ZIndex = 51
player2Label.Parent = resultPanel


local tiempo1Label = Instance.new("TextLabel")
tiempo1Label.Size = UDim2.new(0.5, -10, 0, 45)
tiempo1Label.Position = UDim2.new(0, 10, 0, 120)
tiempo1Label.BackgroundTransparency = 1
tiempo1Label.Text = ""
tiempo1Label.TextColor3 = Color3.fromRGB(220, 220, 220)
tiempo1Label.TextSize = 22
tiempo1Label.Font = Enum.Font.GothamBold
tiempo1Label.ZIndex = 51
tiempo1Label.Parent = resultPanel


local tiempo2Label = Instance.new("TextLabel")
tiempo2Label.Size = UDim2.new(0.5, -10, 0, 45)
tiempo2Label.Position = UDim2.new(0.5, 0, 0, 120)
tiempo2Label.BackgroundTransparency = 1
tiempo2Label.Text = ""
tiempo2Label.TextColor3 = Color3.fromRGB(220, 220, 220)
tiempo2Label.TextSize = 22
tiempo2Label.Font = Enum.Font.GothamBold
tiempo2Label.ZIndex = 51
tiempo2Label.Parent = resultPanel


local winnerLabel = Instance.new("TextLabel")
winnerLabel.Size = UDim2.new(1, -20, 0, 40)
winnerLabel.Position = UDim2.new(0, 10, 0, 170)
winnerLabel.BackgroundTransparency = 1
winnerLabel.Text = ""
winnerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
winnerLabel.TextSize = 22
winnerLabel.Font = Enum.Font.GothamBold
winnerLabel.ZIndex = 51
winnerLabel.Parent = resultPanel

local resultText = Instance.new("TextLabel")
resultText.Size = UDim2.new(1, -40, 0, 80)
resultText.Position = UDim2.new(0, 20, 0, 85)
resultText.BackgroundTransparency = 1
resultText.Text = ""
resultText.TextColor3 = Color3.fromRGB(220, 220, 220)
resultText.TextSize = 22
resultText.Font = Enum.Font.Gotham
resultText.TextWrapped = true
resultText.ZIndex = 51
resultText.Parent = resultPanel

local resultTitle = Instance.new("TextLabel")
resultTitle.Name = "ResultTitle"
resultTitle.Parent = resultPanel
resultTitle.BackgroundTransparency = 1
resultTitle.Size = UDim2.new(1, 0, 0, 50)
resultTitle.Position = UDim2.new(0, 0, 0, 20)
resultTitle.Font = Enum.Font.GothamBold
resultTitle.TextSize = 32
resultTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
resultTitle.ZIndex = 51
resultTitle.Text = ""

-- =========================================================
-- MODAL
-- =========================================================

local function toggleModal(abrir)
	modalHowTo.Visible = abrir
end

-- =========================================================
-- BOTONES
-- =========================================================

btnHowTo.MouseButton1Click:Connect(function()
	toggleModal(true)
end)

btnCloseModal.MouseButton1Click:Connect(function()
	toggleModal(false)
end)

local buscandoPartida = false
btnPlay.MouseButton1Click:Connect(function()
	if esPartidaPrivada then return end
	if buscandoPartida then
		EventoMatchmaking:FireServer("CANCELAR")
	else
		EventoMatchmaking:FireServer("BUSCAR")
	end
end)

EventoMatchmaking.OnClientEvent:Connect(function(estado)
	if estado == "EN_COLA" then
		buscandoPartida = true
		btnPlay.Text = "CANCEL SEARCH"
		btnPlay.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
		btnPlay.Active = true
	elseif estado == "FUERA_DE_COLA" or estado == "ERROR" then
		buscandoPartida = false
		btnPlay.Text = "PLAY NOW!"
		btnPlay.BackgroundColor3 = Color3.fromRGB(45, 180, 80)
		btnPlay.Active = true
		messageLabel.Visible = estado == "ERROR"
		if estado == "ERROR" then messageLabel.Text = "Could not connect. Try again." end
	elseif estado == "ENCONTRADO" then
		buscandoPartida = false
		btnPlay.Active = false
		btnPlay.Text = "ENTERING MATCH..."
	end
end)

local function atacar()
	EventoAtaque:FireServer()
end

attackButton.MouseButton1Click:Connect(atacar)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		atacar()
	end
end)

-- =========================================================
-- EVENTOS DEL SERVIDOR
-- =========================================================

EventoJuego.OnClientEvent:Connect(function(estado, ...)
	local datos = {...}

	print("[INTERFAZ]: Evento recibido:", estado)

	if estado == "ESPERANDO_JUGADOR" then

		messageLabel.Visible = true
		messageLabel.Text = "WAITING FOR OPPONENT..."
		hudPanel.Visible = false
		banner.Visible = not esPartidaPrivada

		roleLabel.Visible = false
		staminaLabel.Visible = false
		livesLabel.Visible = false
		roundLabel.Visible = false
		attackButton.Visible = false
		resultPanel.Visible = false
		rivalLivesLabel.Visible = false

		sideMenu.Visible = not esPartidaPrivada
		btnHowTo.Visible = true

	elseif estado == "ROL" then

		local rol = datos[1]

		sideMenu.Visible = false
		banner.Visible = false
		hudPanel.Visible = true
		modalHowTo.Visible = false
		messageLabel.Visible = false
		resultPanel.Visible = false

		roleLabel.Visible = true
		staminaLabel.Visible = true

		if rol == "PERSEGUIDOR" then
			roleLabel.Text = "KILLER"
			attackButton.Visible = true
		else
			roleLabel.Text = "RUNNER"
			attackButton.Visible = false
		end

	elseif estado == "RONDA" then

		local ronda = datos[1]

		roundLabel.Visible = true
		roundLabel.Text = "ROUND " .. tostring(ronda)

	elseif estado == "VIDAS" then

		local vidas = datos[1]

		livesLabel.Visible = true
		livesLabel.Text = "YOUR LIVES: " .. tostring(vidas)

	elseif estado == "VIDAS_RIVAL" then

		local vidasRival = datos[1]

		rivalLivesLabel.Visible = true
		rivalLivesLabel.Text = "RUNNER LIVES: " .. tostring(vidasRival)

	elseif estado == "COUNTDOWN" then

		local numero = datos[1]

		messageLabel.Visible = true
		messageLabel.Text = tostring(numero)

	elseif estado == "INICIO" then

		messageLabel.Visible = true
		messageLabel.Text = "GO!"

		task.delay(1, function()
			if messageLabel.Text == "GO!" then
				messageLabel.Visible = false
			end
		end)

	elseif estado == "RESULTADO_RONDA" then

		local resultado = datos[1]

		messageLabel.Visible = true
		messageLabel.Text = tostring(resultado)

	elseif estado == "RESULTADO_FINAL" then

		local resultado = datos[1]

		roleLabel.Visible = false
		hudPanel.Visible = false
		livesLabel.Visible = false
		roundLabel.Visible = false
		staminaLabel.Visible = false
		attackButton.Visible = false
		messageLabel.Visible = false

		resultPanel.Visible = true
		rivalLivesLabel.Visible = false

		local tiempo1 = resultado.tiempo1
		local tiempo2 = resultado.tiempo2

		player1Label.Text = resultado.nombre1
		player2Label.Text = resultado.nombre2

		tiempo1Label.Text = string.format("%.2fs", tiempo1)
		tiempo2Label.Text = string.format("%.2fs", tiempo2)

		tiempo1Label.TextSize = 22
		tiempo2Label.TextSize = 22

		tiempo1Label.TextColor3 = Color3.fromRGB(220, 220, 220)
		tiempo2Label.TextColor3 = Color3.fromRGB(220, 220, 220)

		if tiempo1 < tiempo2 then
			tiempo1Label.TextColor3 = Color3.fromRGB(60, 220, 100)
			tiempo1Label.TextSize = 28

		elseif tiempo2 < tiempo1 then
			tiempo2Label.TextColor3 = Color3.fromRGB(60, 220, 100)
			tiempo2Label.TextSize = 28
		end

		local jugadorLocal = Players.LocalPlayer

		if resultado.ganador == jugadorLocal.Name then
			resultTitle.Text = "You win!"
			resultTitle.TextColor3 = Color3.fromRGB(60, 220, 100)

		elseif resultado.ganador then
			resultTitle.Text = "You lose!"
			resultTitle.TextColor3 = Color3.fromRGB(220, 70, 70)

		else
			resultTitle.Text = "Draw!"
			resultTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		if resultado.ganador then
			winnerLabel.Text = "Winner: " .. resultado.ganador
		else
			winnerLabel.Text = "DRAW"
		end

	elseif estado == "OCULTAR_RESULTADO" then

		messageLabel.Visible = false
		resultPanel.Visible = false

		sideMenu.Visible = not esPartidaPrivada
		banner.Visible = not esPartidaPrivada
		btnPlay.Visible = true
		btnHowTo.Visible = true
		btnPlay.Active = true
		btnPlay.Text = "PLAY NOW!"
		btnPlay.BackgroundColor3 = Color3.fromRGB(45, 180, 80)

		rivalLivesLabel.Visible = false
		livesLabel.Visible = false
		roundLabel.Visible = false
	elseif estado == "ERROR_LOBBY" then
		messageLabel.Visible = true
		messageLabel.Text = tostring(datos[1] or "Could not return to lobby.")
	end
end)

if esPartidaPrivada then
	sideMenu.Visible = false
	banner.Visible = false
end

print("[INTERFAZ]: Interfaz 1v1 cargada correctamente.")
