local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local function registrarModulosRecibidos(etapa)
	local mobile = ReplicatedStorage:FindFirstChild("MobileInput")
	local sprites = ReplicatedStorage:FindFirstChild("MobileSpriteCatalog")
	print("[DEPLOY-CHECK] client", etapa, "MobileInput",
		mobile and mobile.ClassName or "missing", "MobileSpriteCatalog",
		sprites and sprites.ClassName or "missing")
end
registrarModulosRecibidos("startup")
task.delay(15, function() registrarModulosRecibidos("after-15s") end)
ReplicatedStorage.ChildAdded:Connect(function(hijo)
	if hijo.Name == "MobileInput" or hijo.Name == "MobileSpriteCatalog" then
		registrarModulosRecibidos("added-" .. hijo.Name)
	end
end)
ReplicatedStorage.ChildRemoved:Connect(function(hijo)
	if hijo.Name == "MobileInput" or hijo.Name == "MobileSpriteCatalog" then
		registrarModulosRecibidos("removed-" .. hijo.Name)
	end
end)
local donationConfig = require(ReplicatedStorage:WaitForChild("DonationConfig"))

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

if UserInputService.TouchEnabled then
	sideMenu.AnchorPoint = Vector2.zero
	sideMenu.Position = UDim2.fromOffset(12, 70)
	sideMenu.Size = UDim2.fromOffset(220, 58)
	btnPlay.Position = UDim2.fromOffset(8, 7)
	btnPlay.Size = UDim2.fromOffset(98, 44)
	btnPlay.TextSize = 16
	btnHowTo.Position = UDim2.fromOffset(114, 7)
	btnHowTo.Size = UDim2.fromOffset(98, 44)
	btnHowTo.TextSize = 13
end

local btnDonate = Instance.new("TextButton")
btnDonate.Name = "Donate"
btnDonate.Size = UDim2.fromOffset(132, 38)
btnDonate.AnchorPoint = Vector2.new(1, 1)
btnDonate.Position = UDim2.new(1, -16, 1, -24)
btnDonate.BackgroundColor3 = Color3.fromRGB(97, 69, 37)
btnDonate.BorderSizePixel = 0
btnDonate.Text = donationConfig.ProductId > 0 and "DONATE" or "DONATE SOON"
btnDonate.TextColor3 = Color3.fromRGB(255, 244, 218)
btnDonate.TextSize = 16
btnDonate.Font = Enum.Font.GothamBold
btnDonate.ZIndex = 11
btnDonate.Parent = screenGui
local donateCorner = Instance.new("UICorner")
donateCorner.CornerRadius = UDim.new(0, 8)
donateCorner.Parent = btnDonate

local donateFeedback = Instance.new("TextLabel")
donateFeedback.Name = "DonationFeedback"
donateFeedback.Size = UDim2.fromOffset(230, 52)
donateFeedback.AnchorPoint = Vector2.new(1, 1)
donateFeedback.Position = UDim2.new(1, -16, 1, -84)
donateFeedback.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
donateFeedback.BackgroundTransparency = 0.12
donateFeedback.TextColor3 = Color3.new(1, 1, 1)
donateFeedback.TextWrapped = true
donateFeedback.TextSize = 14
donateFeedback.Font = Enum.Font.Gotham
donateFeedback.Visible = false
donateFeedback.ZIndex = 12
donateFeedback.Parent = screenGui
local feedbackCorner = Instance.new("UICorner")
feedbackCorner.CornerRadius = UDim.new(0, 8)
feedbackCorner.Parent = donateFeedback

-- Keep the donation away from both the player list and the centered parkour prompt.
local donationViewportConnection
local function positionDonation()
	local camera = Workspace.CurrentCamera
	if UserInputService.TouchEnabled then
		btnDonate.AnchorPoint = Vector2.zero
		btnDonate.Position = UDim2.fromOffset(16, 138)
		donateFeedback.AnchorPoint = Vector2.zero
		donateFeedback.Position = UDim2.fromOffset(16, 182)
	elseif camera and camera.ViewportSize.X >= 850 then
		btnDonate.AnchorPoint = Vector2.new(1, 1)
		btnDonate.Position = UDim2.new(1, -16, 1, -24)
		donateFeedback.AnchorPoint = Vector2.new(1, 1)
		donateFeedback.Position = UDim2.new(1, -16, 1, -84)
	else
		btnDonate.AnchorPoint = Vector2.new(0, 0)
		btnDonate.Position = UDim2.fromOffset(16, 76)
		donateFeedback.AnchorPoint = Vector2.new(0, 0)
		donateFeedback.Position = UDim2.fromOffset(16, 121)
	end
end
local function watchDonationViewport()
	if donationViewportConnection then donationViewportConnection:Disconnect() end
	local camera = Workspace.CurrentCamera
	if camera then
		donationViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(positionDonation)
	end
	positionDonation()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchDonationViewport)
watchDonationViewport()

local function mostrarDonacion(mensaje)
	donateFeedback.Text = mensaje
	donateFeedback.Visible = true
	task.delay(4, function()
		if donateFeedback.Text == mensaje then donateFeedback.Visible = false end
	end)
end

local donateConfirm = Instance.new("Frame")
donateConfirm.Name = "DonationConfirmation"
donateConfirm.Size = UDim2.new(0.82, 0, 0, 194)
donateConfirm.AnchorPoint = Vector2.new(0.5, 0.5)
donateConfirm.Position = UDim2.fromScale(0.5, 0.5)
donateConfirm.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
donateConfirm.BorderSizePixel = 0
donateConfirm.Visible = false
donateConfirm.ZIndex = 120
donateConfirm.Parent = screenGui
local donateLimit = Instance.new("UISizeConstraint")
donateLimit.MaxSize = Vector2.new(410, 194)
donateLimit.Parent = donateConfirm
local donateRound = Instance.new("UICorner")
donateRound.CornerRadius = UDim.new(0, 10)
donateRound.Parent = donateConfirm

local donateTitle = Instance.new("TextLabel")
donateTitle.Size = UDim2.new(1, -24, 0, 30)
donateTitle.Position = UDim2.fromOffset(12, 10)
donateTitle.BackgroundTransparency = 1
donateTitle.Text = "SUPPORT THE GAME"
donateTitle.TextColor3 = Color3.new(1, 1, 1)
donateTitle.TextSize = 20
donateTitle.Font = Enum.Font.GothamBold
donateTitle.ZIndex = 121
donateTitle.Parent = donateConfirm

local donateExplanation = Instance.new("TextLabel")
donateExplanation.Size = UDim2.new(1, -28, 0, 93)
donateExplanation.Position = UDim2.fromOffset(14, 42)
donateExplanation.BackgroundTransparency = 1
donateExplanation.Text = ""
donateExplanation.TextColor3 = Color3.fromRGB(220, 225, 230)
donateExplanation.TextSize = 14
donateExplanation.Font = Enum.Font.Gotham
donateExplanation.TextWrapped = true
donateExplanation.TextXAlignment = Enum.TextXAlignment.Left
donateExplanation.TextYAlignment = Enum.TextYAlignment.Top
donateExplanation.ZIndex = 121
donateExplanation.Parent = donateConfirm

local donateCancel = Instance.new("TextButton")
donateCancel.Size = UDim2.new(0.44, 0, 0, 38)
donateCancel.Position = UDim2.new(0.04, 0, 1, -48)
donateCancel.BackgroundColor3 = Color3.fromRGB(65, 70, 78)
donateCancel.Text = "CANCEL"
donateCancel.TextColor3 = Color3.new(1, 1, 1)
donateCancel.TextSize = 15
donateCancel.Font = Enum.Font.GothamBold
donateCancel.ZIndex = 121
donateCancel.Parent = donateConfirm
local donateContinue = donateCancel:Clone()
donateContinue.Name = "Continue"
donateContinue.Position = UDim2.new(0.52, 0, 1, -48)
donateContinue.BackgroundColor3 = Color3.fromRGB(130, 91, 42)
donateContinue.Text = "CONTINUE"
donateContinue.Parent = donateConfirm

local productoDisponible = false
local precioDonacion = nil
if donationConfig.ProductId > 0 then
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(donationConfig.ProductId, Enum.InfoType.Product)
		end)
		if ok and info and info.IsForSale ~= false and info.PriceInRobux then
			productoDisponible = true
			precioDonacion = info.PriceInRobux
			btnDonate.Text = "DONATE " .. tostring(info.PriceInRobux) .. " R$"
		else
			btnDonate.Text = "DONATE UNAVAILABLE"
		end
	end)
end
btnDonate.MouseButton1Click:Connect(function()
	if not productoDisponible then
		mostrarDonacion("Donation is not available yet. No purchase was started.")
		return
	end
	donateExplanation.Text = "Donation: " .. tostring(precioDonacion) .. " Robux. No in-game reward. If your balance is low, Roblox may offer a larger Robux package. That package is not the donation price."
	donateConfirm.Visible = true
end)
donateCancel.MouseButton1Click:Connect(function()
	donateConfirm.Visible = false
end)
donateContinue.MouseButton1Click:Connect(function()
	donateConfirm.Visible = false
	if not productoDisponible then return end
	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(jugador, donationConfig.ProductId)
	end)
	if not ok then mostrarDonacion("Donation is unavailable right now.") end
end)

-- =========================================================
-- MODAL HOW TO PLAY
-- =========================================================

local modalHowTo = Instance.new("Frame")
modalHowTo.Name = "HowToPlayModal"
modalHowTo.Size = UDim2.new(0.88, 0, 0.78, 0)
modalHowTo.AnchorPoint = Vector2.new(0.5, 0.5)
modalHowTo.Position = UDim2.fromScale(0.5, 0.5)
modalHowTo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
modalHowTo.BackgroundTransparency = 0.05
modalHowTo.BorderSizePixel = 0
modalHowTo.Visible = false
modalHowTo.ZIndex = 100
modalHowTo.Parent = screenGui

local modalSize = Instance.new("UISizeConstraint")
modalSize.MaxSize = Vector2.new(520, 440)
modalSize.Parent = modalHowTo

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 10)
modalCorner.Parent = modalHowTo

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -32, 0, 32)
modalTitle.Position = UDim2.fromOffset(16, 12)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "HOW TO PLAY"
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.TextSize = 24
modalTitle.Font = Enum.Font.GothamBold
modalTitle.ZIndex = 101
modalTitle.Parent = modalHowTo

local guideSubtitle = Instance.new("TextLabel")
guideSubtitle.Size = UDim2.new(1, -32, 0, 24)
guideSubtitle.Position = UDim2.fromOffset(16, 47)
guideSubtitle.BackgroundTransparency = 1
guideSubtitle.Text = "Pick a role below"
guideSubtitle.TextColor3 = Color3.fromRGB(181, 194, 207)
guideSubtitle.TextSize = 13
guideSubtitle.Font = Enum.Font.Gotham
guideSubtitle.TextXAlignment = Enum.TextXAlignment.Left
guideSubtitle.ZIndex = 101
guideSubtitle.Parent = modalHowTo

local guideTabs = Instance.new("Frame")
guideTabs.Name = "RoleTabs"
guideTabs.Size = UDim2.new(1, -32, 0, 40)
guideTabs.Position = UDim2.fromOffset(16, 77)
guideTabs.BackgroundTransparency = 1
guideTabs.ZIndex = 101
guideTabs.Parent = modalHowTo

local function createRoleTab(name, label, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.5, -4, 1, 0)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(45, 52, 61)
	button.BorderSizePixel = 0
	button.Text = label
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 102
	button.Parent = guideTabs
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local runnerTab = createRoleTab("RunnerTab", "RUNNER", UDim2.fromScale(0, 0))
local chaserTab = createRoleTab("ChaserTab", "CHASER", UDim2.new(0.5, 4, 0, 0))

local guideScroll = Instance.new("ScrollingFrame")
guideScroll.Name = "GuideScroll"
guideScroll.Size = UDim2.new(1, -32, 1, -185)
guideScroll.Position = UDim2.fromOffset(16, 125)
guideScroll.BackgroundTransparency = 1
guideScroll.BorderSizePixel = 0
guideScroll.ScrollBarThickness = 5
guideScroll.ScrollBarImageColor3 = Color3.fromRGB(124, 145, 168)
guideScroll.CanvasSize = UDim2.fromOffset(0, 0)
guideScroll.ZIndex = 101
guideScroll.Parent = modalHowTo

local guideLayout = Instance.new("UIListLayout")
guideLayout.Padding = UDim.new(0, 7)
guideLayout.Parent = guideScroll
guideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	guideScroll.CanvasSize = UDim2.fromOffset(0, guideLayout.AbsoluteContentSize.Y + 8)
end)

local function addGuideCard(keyText, title, description, accent)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 104)
	card.BackgroundColor3 = Color3.fromRGB(38, 44, 52)
	card.BorderSizePixel = 0
	card.ZIndex = 102
	card.Parent = guideScroll
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(82, 42)
	badge.Position = UDim2.fromOffset(9, 31)
	badge.BackgroundColor3 = accent
	badge.Text = keyText
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.TextSize = 15
	badge.Font = Enum.Font.GothamBold
	badge.ZIndex = 103
	badge.Parent = card
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 6)
	badgeCorner.Parent = badge

	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, -108, 0, 23)
	heading.Position = UDim2.fromOffset(101, 8)
	heading.BackgroundTransparency = 1
	heading.Text = title
	heading.TextColor3 = Color3.new(1, 1, 1)
	heading.TextSize = 15
	heading.Font = Enum.Font.GothamBold
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.ZIndex = 103
	heading.Parent = card

	local detail = Instance.new("TextLabel")
	detail.Size = UDim2.new(1, -108, 0, 69)
	detail.Position = UDim2.fromOffset(101, 30)
	detail.BackgroundTransparency = 1
	detail.Text = description
	detail.TextColor3 = Color3.fromRGB(207, 216, 224)
	detail.TextSize = 12
	detail.Font = Enum.Font.Gotham
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.ZIndex = 103
	detail.Parent = card
	return { frame = card, badge = badge, detail = detail }
end

local guideCards = {
	RUNNER = {
		{ "MATCH", "Six rounds", "Roles swap every round. Each player is Runner three times. A round lasts up to 120 seconds; the longest total Runner survival time wins the match." },
		{ "GOAL", "Stay alive", "You have three lives each round. Survive until the timer ends; every hit or severe fall can cost a life." },
		{ "SHIFT", "Sprint", "Hold Shift to run faster. Sprint drains stamina; starting a window or gap action while sprinting makes it faster." },
		{ "CTRL / C", "Slide", "While sprinting, press Left Ctrl or C to slide under low obstacles. Downhill slopes keep you moving. Press again to stop when there is room to stand." },
		{ "SPACE", "Jump", "Jump over small obstacles. It costs stamina. Space does not vault windows; use the window prompt instead." },
		{ "RMB", "Windows / gaps", "Right-click at Vault or Go Through to cross a window or narrow gap. You walk to its marker first if needed." },
		{ "RMB", "Pallets", "Right-click to drop a standing pallet or vault a fallen one. A dropped pallet can delay the Chaser." },
		{ "RMB", "Climb / drop", "Right-click near a climbable surface or truss to climb; click again to drop off. Use W/S to climb marked walls. Climbing drains stamina by distance." },
		{ "STAMINA", "Manage energy", "Low stamina slows obstacle actions. At zero you cannot jump or continue climbing. High falls can stun you." },
	},
	CHASER = {
		{ "MATCH", "Six rounds", "Roles swap every round. Each player is Chaser three times. Each round lasts up to 120 seconds; the longest total Runner survival time wins the match." },
		{ "GOAL", "Catch the Runner", "Remove the Runner's three lives before time runs out. Their remaining lives appear on your HUD." },
		{ "F / LMB", "Attack", "Press F or left-click to strike. The bat reaches farther than your hand. A hit has a longer recovery; a miss slows you only briefly." },
		{ "HOTBAR", "Choose a tool", "Equip or put away the bat to switch between bat and hand attacks. The throwable chair is a separate tool." },
		{ "SHIFT", "Sprint", "Hold Shift to run faster. Sprint drains stamina; starting a window or gap action while sprinting makes it faster." },
		{ "CTRL / C", "Slide", "While sprinting, press Left Ctrl or C to slide under low obstacles. Downhill slopes keep you moving. Press again to stop when there is room to stand." },
		{ "SPACE", "Jump", "Jump over small obstacles. It costs stamina. Space does not vault windows; use the window prompt instead." },
		{ "RMB", "Windows / gaps", "Right-click at Vault or Go Through to cross a window or narrow gap. You are slightly slower than the Runner." },
		{ "RMB", "Pallets", "Right-click near a fallen pallet to break it and clear the route. The Runner can drop or vault pallets." },
		{ "RMB", "Climb / drop", "Right-click near a climbable surface or truss to climb; click again to drop off. Use W/S to climb marked walls. Climbing drains stamina by distance." },
		{ "STAMINA", "Manage energy", "Low stamina slows obstacle actions. At zero you cannot jump or continue climbing." },
	},
}

if UserInputService.TouchEnabled then
	for _, cards in pairs(guideCards) do
		table.insert(cards, 3, { "TOUCH", "Mobile controls", "Hold Sprint to run, or slide that button upward to lock sprint; tap Sprint again to stop. Tap Jump to leap. Drag a held button to look around. Action changes near obstacles and becomes Slide while sprinting. Equipping a throwable shows Throw: hold to aim, release to throw. As Chaser, generic Action attacks." })
	end
end

local currentGuideRole = "RUNNER"
local visibleGuideCards = {}
local function resizeGuideCards()
	local textWidth = math.max(90, guideScroll.AbsoluteSize.X - 118)
	for _, entry in ipairs(visibleGuideCards) do
		local detail = entry.detail
		local textHeight = TextService:GetTextSize(detail.Text, detail.TextSize, detail.Font,
			Vector2.new(textWidth, 1000)).Y
		local cardHeight = math.max(88, 40 + textHeight)
		entry.frame.Size = UDim2.new(1, -10, 0, cardHeight)
		entry.badge.Position = UDim2.fromOffset(9, math.floor((cardHeight - 42) / 2))
		detail.Size = UDim2.new(1, -108, 0, textHeight + 4)
	end
end
guideScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGuideCards)
local function showGuideRole(role)
	currentGuideRole = role
	visibleGuideCards = {}
	for _, child in ipairs(guideScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local accent = role == "RUNNER" and Color3.fromRGB(35, 126, 100)
		or Color3.fromRGB(146, 61, 65)
	runnerTab.BackgroundColor3 = role == "RUNNER" and Color3.fromRGB(35, 126, 100)
		or Color3.fromRGB(45, 52, 61)
	chaserTab.BackgroundColor3 = role == "CHASER" and Color3.fromRGB(146, 61, 65)
		or Color3.fromRGB(45, 52, 61)
	for _, card in ipairs(guideCards[role]) do
		table.insert(visibleGuideCards, addGuideCard(card[1], card[2], card[3], accent))
	end
	resizeGuideCards()
	guideScroll.CanvasPosition = Vector2.zero
	task.defer(function()
		resizeGuideCards()
		guideScroll.CanvasSize = UDim2.fromOffset(0, guideLayout.AbsoluteContentSize.Y + 8)
	end)
end
runnerTab.MouseButton1Click:Connect(function() showGuideRole("RUNNER") end)
chaserTab.MouseButton1Click:Connect(function() showGuideRole("CHASER") end)
showGuideRole(currentGuideRole)

local btnCloseModal = Instance.new("TextButton")
btnCloseModal.Size = UDim2.fromOffset(132, 38)
btnCloseModal.AnchorPoint = Vector2.new(0.5, 1)
btnCloseModal.Position = UDim2.new(0.5, 0, 1, -11)
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
if UserInputService.TouchEnabled then
	local hudScale = Instance.new("UIScale")
	hudScale.Scale = 0.68
	hudScale.Parent = hudPanel
end
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

local staminaWidget = Instance.new("Frame")
staminaWidget.Name = "Stamina"
staminaWidget.Size = UDim2.fromOffset(288, 38)
staminaWidget.Position = UDim2.fromOffset(12, 45)
staminaWidget.BackgroundTransparency = 1
staminaWidget.Visible = false
staminaWidget.ZIndex = 20
staminaWidget.Parent = hudPanel

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "Label"
staminaLabel.Size = UDim2.new(0.5, 0, 0, 19)
staminaLabel.BackgroundTransparency = 1
staminaLabel.Text = "STAMINA"
staminaLabel.TextColor3 = Color3.fromRGB(220, 230, 236)
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.TextSize = 14
staminaLabel.Font = Enum.Font.GothamBold
staminaLabel.ZIndex = 21
staminaLabel.Parent = staminaWidget

local staminaValue = Instance.new("TextLabel")
staminaValue.Name = "Value"
staminaValue.Size = UDim2.new(0.5, 0, 0, 19)
staminaValue.Position = UDim2.fromScale(0.5, 0)
staminaValue.BackgroundTransparency = 1
staminaValue.TextXAlignment = Enum.TextXAlignment.Right
staminaValue.TextSize = 14
staminaValue.Font = Enum.Font.GothamBold
staminaValue.ZIndex = 21
staminaValue.Parent = staminaWidget

local staminaTrack = Instance.new("Frame")
staminaTrack.Name = "Track"
staminaTrack.Size = UDim2.new(1, 0, 0, 11)
staminaTrack.Position = UDim2.fromOffset(0, 24)
staminaTrack.BackgroundColor3 = Color3.fromRGB(58, 65, 72)
staminaTrack.BorderSizePixel = 0
staminaTrack.ClipsDescendants = true
staminaTrack.ZIndex = 21
staminaTrack.Parent = staminaWidget
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = staminaTrack

local staminaFill = Instance.new("Frame")
staminaFill.Name = "Fill"
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = Color3.fromRGB(95, 219, 149)
staminaFill.BorderSizePixel = 0
staminaFill.ZIndex = 22
staminaFill.Parent = staminaTrack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = staminaFill

local function actualizarStamina()
	local actual = tonumber(jugador:GetAttribute("Stamina")) or 0
	local maximo = math.max(1, tonumber(jugador:GetAttribute("StaminaMax")) or 100)
	local porcentaje = math.clamp(actual / maximo, 0, 1)
	local color = porcentaje <= 0.25 and Color3.fromRGB(236, 104, 85)
		or porcentaje <= 0.5 and Color3.fromRGB(242, 186, 77)
		or Color3.fromRGB(95, 219, 149)
	staminaValue.Text = string.format("%d / %d", math.floor(actual), maximo)
	staminaValue.TextColor3 = color
	staminaFill.Size = UDim2.fromScale(porcentaje, 1)
	staminaFill.BackgroundColor3 = color
end
jugador:GetAttributeChangedSignal("Stamina"):Connect(actualizarStamina)
jugador:GetAttributeChangedSignal("StaminaMax"):Connect(actualizarStamina)
actualizarStamina()

local livesWidget = Instance.new("Frame")
livesWidget.Name = "RunnerLives"
livesWidget.Size = UDim2.fromOffset(145, 48)
livesWidget.Position = UDim2.fromOffset(12, 90)
livesWidget.BackgroundTransparency = 1
livesWidget.Visible = false
livesWidget.ZIndex = 20
livesWidget.Parent = hudPanel

local function ajustarTamanoHud()
	local enLobby = sideMenu.Visible
	local altura = livesWidget.Visible and 144 or 94
	local ancho = enLobby and 240 or 312
	hudPanel.Size = UDim2.fromOffset(ancho, altura)
	if UserInputService.TouchEnabled then
		-- Debajo de Donate en lobby, pero por encima del thumbstick nativo.
		local camera = Workspace.CurrentCamera
		local viewHeight = camera and camera.ViewportSize.Y or 360
		local top = math.max(enLobby and 186 or 88,
			viewHeight - altura * 0.68 - 160)
		hudPanel.Position = UDim2.fromOffset(12, math.floor(top))
	else
		hudPanel.Position = UDim2.new(0, 16, 1, -(altura + (enLobby and 96 or 16)))
	end
	roleLabel.Size = UDim2.fromOffset(ancho - 24, 34)
	staminaWidget.Size = UDim2.fromOffset(ancho - 24, 38)
end
livesWidget:GetPropertyChangedSignal("Visible"):Connect(ajustarTamanoHud)
sideMenu:GetPropertyChangedSignal("Visible"):Connect(ajustarTamanoHud)
ajustarTamanoHud()

local heart = Instance.new("TextLabel")
heart.Name = "Heart"
heart.Size = UDim2.fromOffset(62, 54)
heart.Position = UDim2.fromOffset(0, -3)
heart.BackgroundTransparency = 1
heart.Text = utf8.char(0x2764)
heart.TextColor3 = Color3.fromRGB(225, 53, 78)
heart.TextSize = 53
heart.Font = Enum.Font.GothamBold
heart.ZIndex = 20
heart.Parent = livesWidget

local runnerPortrait = Instance.new("ImageLabel")
runnerPortrait.Name = "RunnerPortrait"
runnerPortrait.Size = UDim2.fromOffset(33, 33)
runnerPortrait.Position = UDim2.fromOffset(14, 11)
runnerPortrait.BackgroundColor3 = Color3.fromRGB(145, 57, 74)
runnerPortrait.BorderSizePixel = 0
runnerPortrait.Image = ""
runnerPortrait.ZIndex = 21
runnerPortrait.Parent = livesWidget
local portraitCorner = Instance.new("UICorner")
portraitCorner.CornerRadius = UDim.new(1, 0)
portraitCorner.Parent = runnerPortrait

local portraitFallback = Instance.new("TextLabel")
portraitFallback.Name = "PortraitFallback"
portraitFallback.Size = UDim2.fromScale(1, 1)
portraitFallback.BackgroundTransparency = 1
portraitFallback.Text = "?"
portraitFallback.TextColor3 = Color3.fromRGB(255, 255, 255)
portraitFallback.TextSize = 18
portraitFallback.Font = Enum.Font.GothamBold
portraitFallback.ZIndex = 22
portraitFallback.Parent = runnerPortrait

local portraitViewport = Instance.new("ViewportFrame")
portraitViewport.Name = "StudioPortraitFallback"
portraitViewport.Size = runnerPortrait.Size
portraitViewport.Position = runnerPortrait.Position
portraitViewport.BackgroundColor3 = runnerPortrait.BackgroundColor3
portraitViewport.BorderSizePixel = 0
portraitViewport.Ambient = Color3.fromRGB(225, 225, 225)
portraitViewport.LightColor = Color3.fromRGB(255, 255, 255)
portraitViewport.Visible = false
portraitViewport.ZIndex = 23
portraitViewport.Parent = livesWidget
local viewportCorner = Instance.new("UICorner")
viewportCorner.CornerRadius = UDim.new(1, 0)
viewportCorner.Parent = portraitViewport
local portraitWorld = Instance.new("WorldModel")
portraitWorld.Parent = portraitViewport
local portraitCamera = Instance.new("Camera")
portraitCamera.CFrame = CFrame.lookAt(Vector3.new(0, 0, -3), Vector3.zero)
portraitCamera.Parent = portraitViewport
portraitViewport.CurrentCamera = portraitCamera

local function mostrarCabezaLocal(userId)
	local runner = Players:GetPlayerByUserId(userId)
	local head = runner and runner.Character and runner.Character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end
	local ok, clone = pcall(function()
		local archivable = head.Archivable
		head.Archivable = true
		local copia = head:Clone()
		head.Archivable = archivable
		return copia
	end)
	if not ok or not clone then return end
	portraitWorld:ClearAllChildren()
	clone.Anchored = true
	clone.CanCollide = false
	clone.CFrame = CFrame.new()
	clone.Parent = portraitWorld
	portraitViewport.Visible = true
end

local livesCount = Instance.new("TextLabel")
livesCount.Name = "Count"
livesCount.Size = UDim2.fromOffset(78, 46)
livesCount.Position = UDim2.fromOffset(64, 1)
livesCount.BackgroundTransparency = 1
livesCount.TextXAlignment = Enum.TextXAlignment.Left
livesCount.Text = ""
livesCount.TextColor3 = Color3.fromRGB(255, 245, 245)
livesCount.TextSize = 27
livesCount.Font = Enum.Font.GothamBold
livesCount.ZIndex = 20
livesCount.Parent = livesWidget

local portraitUserId = nil
local function actualizarVidas(cantidad, userId)
	livesWidget.Visible = true
	livesCount.Text = "x " .. tostring(cantidad)
	if typeof(userId) ~= "number" or portraitUserId == userId then return end
	portraitUserId = userId
	runnerPortrait.Image = ""
	portraitViewport.Visible = false
	local runner = Players:GetPlayerByUserId(userId)
	portraitFallback.Text = runner and string.upper(string.sub(runner.DisplayName, 1, 1)) or "?"
	portraitFallback.Visible = true
	mostrarCabezaLocal(userId)
	task.spawn(function()
		for _ = 1, 10 do
			if not portraitViewport.Visible then mostrarCabezaLocal(userId) end
			local ok, contenido, listo = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			if portraitUserId ~= userId then return end
			if ok and typeof(contenido) == "string" and contenido ~= "" then
				runnerPortrait.Image = contenido
				if listo then
					portraitFallback.Visible = false
					portraitViewport.Visible = false
					return
				end
			end
			task.wait(0.5)
		end
	end)
end

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
local teleportCountdownLabel = Instance.new("TextLabel")
teleportCountdownLabel.Name = "TeleportCountdown"
teleportCountdownLabel.Size = UDim2.fromOffset(360, 40)
teleportCountdownLabel.AnchorPoint = Vector2.new(0.5, 0)
teleportCountdownLabel.Position = UDim2.new(0.5, 0, 0.45, 43)
teleportCountdownLabel.BackgroundColor3 = Color3.fromRGB(18, 24, 30)
teleportCountdownLabel.BackgroundTransparency = 0.2
teleportCountdownLabel.TextColor3 = Color3.fromRGB(235, 242, 250)
teleportCountdownLabel.TextSize = 20
teleportCountdownLabel.Font = Enum.Font.GothamBold
teleportCountdownLabel.Visible = false
teleportCountdownLabel.ZIndex = 20
teleportCountdownLabel.Parent = screenGui
local teleportCountdownCorner = Instance.new("UICorner")
teleportCountdownCorner.CornerRadius = UDim.new(0, 8)
teleportCountdownCorner.Parent = teleportCountdownLabel

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

EventoMatchmaking.OnClientEvent:Connect(function(estado, segundos)
	if estado == "EN_COLA" then
		buscandoPartida = true
		btnPlay.Text = "CANCEL SEARCH"
		btnPlay.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
		btnPlay.Active = true
	elseif estado == "FUERA_DE_COLA" or estado == "ERROR" then
		teleportCountdownLabel.Visible = false
		buscandoPartida = false
		btnPlay.Text = "PLAY NOW!"
		btnPlay.BackgroundColor3 = Color3.fromRGB(45, 180, 80)
		btnPlay.Active = true
		messageLabel.Visible = estado == "ERROR"
		if estado == "ERROR" then messageLabel.Text = "Could not connect. Try again." end
	elseif estado == "ENCONTRADO" then
		teleportCountdownLabel.Visible = false
		buscandoPartida = false
		btnPlay.Active = false
		btnPlay.Text = "ENTERING MATCH..."
		messageLabel.Text = "Opponent found!"
		messageLabel.TextColor3 = Color3.fromRGB(140, 235, 165)
		messageLabel.Visible = true
	elseif estado == "COUNTDOWN_TELEPORT" then
		teleportCountdownLabel.Text = "Entering match in " .. tostring(segundos) .. "..."
		teleportCountdownLabel.Visible = true
	end
end)

local function atacar()
	EventoAtaque:FireServer()
end

attackButton.MouseButton1Click:Connect(atacar)

-- =========================================================
-- EVENTOS DEL SERVIDOR
-- =========================================================

EventoJuego.OnClientEvent:Connect(function(estado, ...)
	local datos = {...}
	if estado ~= "RESULTADO_RONDA" then
		messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	print("[INTERFAZ]: Evento recibido:", estado)

	if estado == "ESPERANDO_JUGADOR" then
		teleportCountdownLabel.Visible = false
		local lobbyPractica = Workspace:GetAttribute("LobbyPractica") == true and not esPartidaPrivada

		messageLabel.Visible = true
		messageLabel.Text = "WAITING FOR OPPONENT..."
		hudPanel.Visible = lobbyPractica
		banner.Visible = not esPartidaPrivada

		roleLabel.Visible = lobbyPractica
		if lobbyPractica then
			roleLabel.Text = jugador:GetAttribute("Rol") == "PERSEGUIDOR" and "CHASER" or "RUNNER"
		end
		staminaWidget.Visible = lobbyPractica
		livesWidget.Visible = false
		roundLabel.Visible = false
		attackButton.Visible = false
		resultPanel.Visible = false

		sideMenu.Visible = not esPartidaPrivada
		btnDonate.Visible = not esPartidaPrivada
		btnHowTo.Visible = true

	elseif estado == "ROL" then
		teleportCountdownLabel.Visible = false

		local rol = datos[1]

		sideMenu.Visible = false
		btnDonate.Visible = false
		donateFeedback.Visible = false
		donateConfirm.Visible = false
		banner.Visible = false
		hudPanel.Visible = true
		modalHowTo.Visible = false
		messageLabel.Visible = false
		resultPanel.Visible = false

		roleLabel.Visible = true
		staminaWidget.Visible = true

		if rol == "PERSEGUIDOR" then
			roleLabel.Text = "CHASER"
			attackButton.Visible = not UserInputService.TouchEnabled
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

		actualizarVidas(vidas, datos[2])

	elseif estado == "VIDAS_RIVAL" then

		local vidasRival = datos[1]

		actualizarVidas(vidasRival, datos[2])

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
		if resultado == "WIN" then
			messageLabel.Text = "You Win"
			messageLabel.TextColor3 = Color3.fromRGB(60, 220, 100)
		elseif resultado == "LOSE" then
			messageLabel.Text = "You Lose"
			messageLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
		else
			messageLabel.Text = "Round Over"
			messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

	elseif estado == "RESULTADO_FINAL" then

		local resultado = datos[1]

		roleLabel.Visible = false
		hudPanel.Visible = false
		livesWidget.Visible = false
		roundLabel.Visible = false
		staminaWidget.Visible = false
		attackButton.Visible = false
		messageLabel.Visible = false

		resultPanel.Visible = true

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

		if tiempo1 > tiempo2 then
			tiempo1Label.TextColor3 = Color3.fromRGB(60, 220, 100)
			tiempo1Label.TextSize = 28

		elseif tiempo2 > tiempo1 then
			tiempo2Label.TextColor3 = Color3.fromRGB(60, 220, 100)
			tiempo2Label.TextSize = 28
		end

		local jugadorLocal = Players.LocalPlayer

		if resultado.ganador == jugadorLocal.Name then
			resultTitle.Text = "You Win"
			resultTitle.TextColor3 = Color3.fromRGB(60, 220, 100)

		elseif resultado.ganador then
			resultTitle.Text = "You Lose"
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
		btnDonate.Visible = not esPartidaPrivada
		banner.Visible = not esPartidaPrivada
		btnPlay.Visible = true
		btnHowTo.Visible = true
		btnPlay.Active = true
		btnPlay.Text = "PLAY NOW!"
		btnPlay.BackgroundColor3 = Color3.fromRGB(45, 180, 80)

		livesWidget.Visible = false
		roundLabel.Visible = false
	elseif estado == "ERROR_LOBBY" then
		messageLabel.Visible = true
		messageLabel.Text = tostring(datos[1] or "Could not return to lobby.")
	end
end)

if esPartidaPrivada then
	sideMenu.Visible = false
	banner.Visible = false
	btnDonate.Visible = false
end

local function actualizarHudLobby()
	if Workspace:GetAttribute("LobbyPractica") == true then
		local veniaDePartidaPrivada = esPartidaPrivada
		esPartidaPrivada = false
		if veniaDePartidaPrivada then
			sideMenu.Visible = true
			btnDonate.Visible = true
			banner.Visible = true
		end
	end
	if Workspace:GetAttribute("LobbyPractica") == true and sideMenu.Visible then
		hudPanel.Visible = true
		roleLabel.Visible = true
		roleLabel.Text = jugador:GetAttribute("Rol") == "PERSEGUIDOR" and "CHASER" or "RUNNER"
		staminaWidget.Visible = true
		livesWidget.Visible = false
	elseif sideMenu.Visible then
		hudPanel.Visible = false
	end
end
Workspace:GetAttributeChangedSignal("LobbyPractica"):Connect(actualizarHudLobby)
jugador:GetAttributeChangedSignal("Rol"):Connect(actualizarHudLobby)
actualizarHudLobby()

print("[INTERFAZ]: Interfaz 1v1 cargada correctamente.")
