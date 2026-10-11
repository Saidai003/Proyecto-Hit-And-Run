local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local audio = require(ReplicatedStorage:WaitForChild("AudioPlayback"))
local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local connectedButtons = setmetatable({}, { __mode = "k" })
local lastHardLanding = -math.huge

local function watchCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local fallStartY
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Freefall then
			fallStartY = root.Position.Y
		elseif newState == Enum.HumanoidStateType.Landed then
			local drop = fallStartY and fallStartY - root.Position.Y or 0
			fallStartY = nil
			if drop >= 6 then
				task.delay(0.2, function()
					if character.Parent and os.clock() - lastHardLanding > 0.5 then
						audio.Play("SoftLanding", root, 0.45, 4)
					end
				end)
			end
		end
	end)
end
Players.LocalPlayer.CharacterAdded:Connect(watchCharacter)
if Players.LocalPlayer.Character then task.spawn(watchCharacter, Players.LocalPlayer.Character) end

local function connectButton(button)
	if not button:IsA("GuiButton") or connectedButtons[button] then return end
	connectedButtons[button] = true
	button.Activated:Connect(function()
		audio.Play(button.Name == "PlayNow" and "DoubleClick" or "Click", SoundService, 0.35, 3)
	end)
end

local function connectGameGui(gui)
	if gui.Name ~= "PantallaPrincipal_1v1_GUI" then return end
	for _, descendant in ipairs(gui:GetDescendants()) do connectButton(descendant) end
	gui.DescendantAdded:Connect(connectButton)
end

for _, child in ipairs(playerGui:GetChildren()) do connectGameGui(child) end
playerGui.ChildAdded:Connect(connectGameGui)

EventoJuego.OnClientEvent:Connect(function(state, result)
	if state == "RESULTADO_RONDA" then
		if result == "WIN" then
			audio.Play("RoundWin", SoundService, 0.65, 6)
		elseif result == "LOSE" then
			audio.Play("RoundLose", SoundService, 0.65, 6)
		end
	elseif state == "RESULTADO_FINAL" and type(result) == "table" then
		local winner = result.ganador
		if winner == Players.LocalPlayer.Name then
			audio.Play("FinalWin", SoundService, 0.7, 12)
			audio.Play("WinVoice", SoundService, 0.65, 6)
		elseif winner then
			audio.Play("FinalLose", SoundService, 0.7, 12)
			audio.Play("LoseVoice", SoundService, 0.65, 6)
		end
	elseif state == "CAIDA_ATURDIDO" then
		lastHardLanding = os.clock()
		audio.Play("HardLanding", SoundService, 0.8, 4)
	end
end)
