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
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = playerGui

local function makeButton(name, image, xOffset, yOffset, size)
	local button = Instance.new("ImageButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, xOffset, 1, yOffset)
	button.Size = UDim2.fromOffset(size, size)
	button.BackgroundTransparency = 1
	button.Image = image
	button.ImageRectOffset = Vector2.new(300, 300)
	button.ImageRectSize = Vector2.new(1448, 1448)
	button.ScaleType = Enum.ScaleType.Stretch
	button.AutoButtonColor = false
	button.ZIndex = 18
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	return button, scale
end

local sprintButton = makeButton("Sprint", sprites.SprintButton, -14, -152, 68)
local jumpButton = makeButton("Jump", sprites.JumpButton, -14, -12, 68)
local actionButton, actionScale = makeButton("Action", sprites.AnyOtherActionButton, -14, -82, 68)

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

local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutoJumpEnabled = false
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end

local actionMode = "AnyOtherActionButton"
local actionGeneration = 0
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
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("Throwable") == true then return "ThrowSomethingButton" end
	if humanoid and (humanoid:GetAttribute("Sliding")
		or (humanoid:GetAttribute("SprintActivoLocal") and humanoid.MoveDirection.Magnitude > 0.2)) then
		return "SlideButton"
	end
	return "AnyOtherActionButton"
end

local function updateAction()
	local mode = chooseMode()
	if mode == actionMode then return end
	actionMode = mode
	actionGeneration += 1
	local generation = actionGeneration
	TweenService:Create(actionScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = 0.82 }):Play()
	task.delay(0.1, function()
		if generation ~= actionGeneration or not actionButton.Parent then return end
		actionButton.Image = sprites[mode]
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
		held[button] = { touch = touch, ended = ended }
		began()
	end)
end

bindTouch(sprintButton, function() input.SprintStart:Fire() end,
	function() input.SprintEnd:Fire() end)
bindTouch(jumpButton, function() input.Jump:Fire() end, function() end)
bindTouch(actionButton, function()
	local mode = actionMode
	if mode == "DropPalletButton" or mode == "BreakPalletButton"
		or mode == "ClimbButton" or mode == "VaultButton" then
		input.Action:Fire()
	elseif mode == "SlideButton" then
		input.Slide:Fire()
	elseif mode == "ThrowSomethingButton" then
		input.ThrowStart:Fire()
	elseif player:GetAttribute("Rol") == "PERSEGUIDOR" then
		input.AttackStart:Fire()
	end
	held[actionButton].mode = mode
end, function(mode)
	if mode == "ThrowSomethingButton" then input.ThrowEnd:Fire() end
	if mode == "AnyOtherActionButton" then input.AttackEnd:Fire() end
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
