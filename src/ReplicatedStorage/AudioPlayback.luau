local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local catalog = require(ReplicatedStorage:WaitForChild("AudioCatalog"))

local AudioPlayback = {}

function AudioPlayback.GetId(name)
	local value = catalog[name]
	if type(value) == "table" then
		local available = {}
		for _, id in ipairs(value) do
			if type(id) == "number" and id > 0 then
				table.insert(available, id)
			end
		end
		value = #available > 0 and available[math.random(1, #available)] or nil
	end
	return type(value) == "number" and value > 0 and value or nil
end

function AudioPlayback.Play(name, parent, volume, lifetime, looped)
	local id = AudioPlayback.GetId(name)
	if not id or not parent then return nil end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume or 0.7
	sound.RollOffMaxDistance = 75
	sound.Looped = looped == true
	sound.Parent = parent
	sound:Play()
	if lifetime ~= false then Debris:AddItem(sound, lifetime or 15) end
	return sound
end

return AudioPlayback
