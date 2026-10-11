local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")

local catalog = require(ReplicatedStorage:WaitForChild("AudioCatalog"))
local lobbyId = catalog.LobbyMusic
if type(lobbyId) ~= "number" or lobbyId <= 0 then return end

local music = Instance.new("Sound")
music.Name = "MusicaLobby"
music.SoundId = "rbxassetid://" .. tostring(lobbyId)
music.Looped = true
music.Volume = 0
music.Parent = SoundService

local targetVolume = 0.26
local currentTween
local changeSerial = 0

local function update()
	changeSerial += 1
	local serial = changeSerial
	if currentTween then currentTween:Cancel() end

	if Workspace:GetAttribute("LobbyPractica") == true then
		if not music.IsPlaying then music:Play() end
		currentTween = TweenService:Create(music, TweenInfo.new(1.4), {Volume = targetVolume})
		currentTween:Play()
	else
		currentTween = TweenService:Create(music, TweenInfo.new(0.8), {Volume = 0})
		local fadeOut = currentTween
		fadeOut:Play()
		task.spawn(function()
			fadeOut.Completed:Wait()
			if serial == changeSerial and Workspace:GetAttribute("LobbyPractica") ~= true then
				music:Stop()
			end
		end)
	end
end

Workspace:GetAttributeChangedSignal("LobbyPractica"):Connect(update)
task.spawn(function()
	pcall(function() ContentProvider:PreloadAsync({music}) end)
	update()
end)
