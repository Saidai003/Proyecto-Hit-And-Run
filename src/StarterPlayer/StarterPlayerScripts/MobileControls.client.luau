local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local input = require(ReplicatedStorage:WaitForChild("MobileInput"))
local sprites = require(ReplicatedStorage:WaitForChild("MobileSpriteCatalog"))

local gui = Instance.new("ScreenGui")
gui.Name = "HitAndRunMobileControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.Parent = playerGui

local labels = {
	SprintButton = "SPRINT",
	JumpButton = "JUMP",
	AnyOtherActionButton = "ACTION",
	DropPalletButton = "DROP",
	BreakPalletButton = "BREAK",
	ClimbButton = "CLIMB",
	VaultButton = "VAULT",
	SlideButton = "SLIDE",
	ThrowSomethingButton = "THROW",
}

local function setSprite(button, mode)
	button.Image = sprites[mode] or ""
	button.Fallback.Text = labels[mode] or "ACTION"
	button.Fallback.Visible = not button.IsLoaded
end

local function makeButton(name, mode)
	local button = Instance.new("ImageButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Size = UDim2.fromOffset(68, 68)
	button.BackgroundColor3 = Color3.fromRGB(25, 32, 42)
	button.BackgroundTransparency = 0.12
	-- Estos JPG son imagenes completas, no spritesheets. Recortar por pixeles
	-- ocultaba el arte cuando Roblox entregaba una textura reducida.
	button.ImageRectOffset = Vector2.zero
	button.ImageRectSize = Vector2.zero
	button.ScaleType = Enum.ScaleType.Stretch
	button.AutoButtonColor = false
	button.ZIndex = 18
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local fallback = Instance.new("TextLabel")
	fallback.Name = "Fallback"
	fallback.BackgroundTransparency = 1
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.Font = Enum.Font.GothamBold
	fallback.TextColor3 = Color3.new(1, 1, 1)
	fallback.TextScaled = true
	fallback.ZIndex = 19
	fallback.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.Parent = fallback
	button:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		fallback.Visible = not button.IsLoaded
	end)
	setSprite(button, mode)
	return button, scale
end

local sprintButton = makeButton("Sprint", "SprintButton")
local jumpButton = makeButton("Jump", "JumpButton")
local actionButton, actionScale = makeButton("Action", "AnyOtherActionButton")
local throwButton = makeButton("Throw", "ThrowSomethingButton")
throwButton.Visible = false
local sprintLockButton = Instance.new("TextButton")
sprintLockButton.Name = "SprintLock"
sprintLockButton.AnchorPoint = Vector2.new(0.5, 0.5)
sprintLockButton.BackgroundColor3 = Color3.fromRGB(32, 39, 48)
sprintLockButton.BackgroundTransparency = 0.05
sprintLockButton.BorderSizePixel = 0
sprintLockButton.AutoButtonColor = true
sprintLockButton.Font = Enum.Font.GothamBold
sprintLockButton.Text = "LOCK"
sprintLockButton.TextColor3 = Color3.new(1, 1, 1)
sprintLockButton.TextScaled = true
sprintLockButton.ZIndex = 20
sprintLockButton.Parent = gui
local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 8)
lockCorner.Parent = sprintLockButton
local lockPadding = Instance.new("UIPadding")
lockPadding.PaddingLeft = UDim.new(0, 3)
lockPadding.PaddingRight = UDim.new(0, 3)
lockPadding.Parent = sprintLockButton

-- Dos filas segun el esquema: Action/Sprint arriba, Throw/Jump abajo.
-- Throw no desplaza los otros controles al equipar o soltar una herramienta.
local function layoutButtons()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local width, height = viewport.X, viewport.Y
	if width <= 0 or height <= 0 then return end
	local size = math.clamp(math.floor(height * 0.17 + 0.5), 56, 84)
	local topY = height * 0.56
	local bottomY = math.max(height * 0.70, topY + size + 10)
	bottomY = math.min(bottomY, height - size / 2 - 24)
	topY = math.min(topY, bottomY - size - 10)
	local sprintX = width * 0.77
	local jumpX = width * 0.76
	local actionX = math.min(width * 0.67, sprintX - size - 10)
	local throwX = math.min(width * 0.625, jumpX - size - 18)
	for button, center in pairs({
		[sprintButton] = Vector2.new(sprintX, topY),
		[actionButton] = Vector2.new(actionX, topY),
		[jumpButton] = Vector2.new(jumpX, bottomY),
		[throwButton] = Vector2.new(throwX, bottomY),
	}) do
		button.Size = UDim2.fromOffset(size, size)
		button.Position = UDim2.fromOffset(math.floor(center.X + 0.5), math.floor(center.Y + 0.5))
	end
	local lockWidth = math.clamp(math.floor(size * 0.49), 32, 42)
	sprintLockButton.Size = UDim2.fromOffset(lockWidth, math.floor(lockWidth * 0.72))
	sprintLockButton.Position = UDim2.fromOffset(
		math.floor(sprintX + size * 0.68), math.floor(topY - size * 0.4))
end

local viewportConnection
local function watchViewport()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutButtons)
	end
	layoutButtons()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchViewport)
watchViewport()

task.spawn(function()
	local mainGui = playerGui:WaitForChild("PantallaPrincipal_1v1_GUI")
	local howTo = mainGui:WaitForChild("HowToPlayModal")
	local results = mainGui:WaitForChild("FinalResult")
	local function updateVisibility()
		gui.Enabled = not howTo.Visible and not results.Visible
	end
	howTo:GetPropertyChangedSignal("Visible"):Connect(updateVisibility)
	results:GetPropertyChangedSignal("Visible"):Connect(updateVisibility)
	updateVisibility()
end)

-- Roblox's standard touch thumbstick remains in use; its duplicate jump
-- button is hidden so the player sees exactly the three game controls.
local function hideDefaultJump(descendant)
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if descendant.Name ~= "JumpButton" or not descendant:IsA("GuiButton")
		or not touchGui or not descendant:IsDescendantOf(touchGui) then return end
	descendant.Visible = false
	descendant:GetPropertyChangedSignal("Visible"):Connect(function()
		if descendant.Visible then descendant.Visible = false end
	end)
end
playerGui.DescendantAdded:Connect(hideDefaultJump)
for _, descendant in ipairs(playerGui:GetDescendants()) do hideDefaultJump(descendant) end

local sprintHeld = false
local sprintLocked = false
local sprintAttributeConnection
local function updateSprintLock()
	sprintLockButton.Text = sprintLocked and "ON" or "LOCK"
	sprintLockButton.BackgroundColor3 = sprintLocked
		and Color3.fromRGB(34, 145, 79) or Color3.fromRGB(32, 39, 48)
end

local function onCharacter(character)
	sprintLocked = false
	sprintHeld = false
	updateSprintLock()
	if sprintAttributeConnection then sprintAttributeConnection:Disconnect() end
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutoJumpEnabled = false
	sprintAttributeConnection = humanoid:GetAttributeChangedSignal("SprintActivoLocal"):Connect(function()
		-- Stamina agotada, slide o un bloqueo de ronda cortan el sprint real.
		if sprintLocked and humanoid:GetAttribute("SprintActivoLocal") ~= true then
			sprintLocked = false
			updateSprintLock()
		end
	end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end

local actionMode = "AnyOtherActionButton"
local actionGeneration = 0
local function equippedThrowable()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool and tool:GetAttribute("Throwable") == true
end

local function chooseMode()
	local parkour = player:GetAttribute("ParkourAction")
	if parkour == "Drop Pallet" then return "DropPalletButton" end
	if parkour == "Break Pallet" then return "BreakPalletButton" end
	if parkour == "Climb" or parkour == "Drop Off" then return "ClimbButton" end
	if parkour == "Vault" or parkour == "Vault Pallet" or parkour == "Go Through" then
		return "VaultButton"
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and (humanoid:GetAttribute("Sliding")
		or (humanoid:GetAttribute("SprintActivoLocal") and humanoid.MoveDirection.Magnitude > 0.2)) then
		return "SlideButton"
	end
	return "AnyOtherActionButton"
end

local function updateAction()
	throwButton.Visible = equippedThrowable() == true
	local mode = chooseMode()
	if mode == actionMode then return end
	actionMode = mode
	actionGeneration += 1
	local generation = actionGeneration
	TweenService:Create(actionScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = 0.82 }):Play()
	task.delay(0.1, function()
		if generation ~= actionGeneration or not actionButton.Parent then return end
		setSprite(actionButton, mode)
		TweenService:Create(actionScale, TweenInfo.new(0.16, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
		task.delay(0.16, function()
			if generation ~= actionGeneration or not actionButton.Parent then return end
			TweenService:Create(actionScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
	end)
end

local held = {}
local function bindTouch(button, began, ended)
	button.InputBegan:Connect(function(touch)
		if touch.UserInputType ~= Enum.UserInputType.Touch or held[button] then return end
		held[button] = {
			touch = touch,
			ended = ended,
			lastPosition = Vector2.new(touch.Position.X, touch.Position.Y),
		}
		began()
	end)
end

local function checkLockedSprint()
	-- El controlador puede rechazar el inicio por falta de stamina o movimiento bloqueado.
	task.delay(0.05, function()
		if not sprintLocked then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid:GetAttribute("SprintActivoLocal") ~= true then
			sprintLocked = false
			updateSprintLock()
		end
	end)
end

bindTouch(sprintButton, function()
	sprintHeld = true
	input.SprintStart:Fire()
end, function()
	sprintHeld = false
	if not sprintLocked then input.SprintEnd:Fire() end
end)
sprintLockButton.Activated:Connect(function()
	sprintLocked = not sprintLocked
	updateSprintLock()
	if sprintLocked then
		input.SprintStart:Fire()
		checkLockedSprint()
	elseif not sprintHeld then
		input.SprintEnd:Fire()
	end
end)
bindTouch(jumpButton, function() input.Jump:Fire() end, function() end)
bindTouch(throwButton, function() input.ThrowStart:Fire() end,
	function() input.ThrowEnd:Fire() end)
bindTouch(actionButton, function()
	local mode = actionMode
	if mode == "DropPalletButton" or mode == "BreakPalletButton"
		or mode == "ClimbButton" or mode == "VaultButton" then
		input.Action:Fire()
	elseif mode == "SlideButton" then
		input.Slide:Fire()
	elseif player:GetAttribute("Rol") == "PERSEGUIDOR" then
		input.AttackStart:Fire()
	end
	held[actionButton].mode = mode
end, function(mode)
	if mode == "AnyOtherActionButton" then input.AttackEnd:Fire() end
end)

-- Un dedo puede mantener la accion y deslizarse para orientar la camara.
-- El control de camara normal de Roblox no usa los toques capturados por UI.
UserInputService.TouchMoved:Connect(function(touch)
	for _, state in pairs(held) do
		if state.touch == touch then
			local position = Vector2.new(touch.Position.X, touch.Position.Y)
			local delta = position - state.lastPosition
			state.lastPosition = position
			if delta.Magnitude > 0.5 then input.LookDelta:Fire(delta) end
			break
		end
	end
end)

UserInputService.InputEnded:Connect(function(touch)
	for button, state in pairs(held) do
		if state.touch == touch then
			held[button] = nil
			state.ended(state.mode)
		end
	end
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	updateAction()
end)
player:GetAttributeChangedSignal("ParkourAction"):Connect(updateAction)
