local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventoHit = ReplicatedStorage:WaitForChild("EventoHit1v1")

local DISTANCIA_HIT = 4
local COOLDOWN_HIT = 0.8

local cooldowns = {}

local function obtenerPersonaje(player)
	local personaje = player.Character

	if not personaje then
		return nil
	end

	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	local rootPart = personaje:FindFirstChild("HumanoidRootPart")

	if not humanoide or not rootPart then
		return nil
	end

	return personaje, humanoide, rootPart
end

local function puedeGolpear(chaser, objetivo)
	local _, humanoideChaser, rootChaser = obtenerPersonaje(chaser)
	local _, humanoideObjetivo, rootObjetivo = obtenerPersonaje(objetivo)

	if not humanoideChaser or not rootChaser then
		return false
	end

	if not humanoideObjetivo or not rootObjetivo then
		return false
	end

	if humanoideChaser.Health <= 0 or humanoideObjetivo.Health <= 0 then
		return false
	end

	local distancia = (rootChaser.Position - rootObjetivo.Position).Magnitude

	return distancia <= DISTANCIA_HIT
end

local function intentarHit(chaser, objetivo)
	if chaser == objetivo then
		return
	end

	if cooldowns[chaser] then
		return
	end

	if not puedeGolpear(chaser, objetivo) then
		return
	end

	cooldowns[chaser] = true

	eventoHit:FireClient(chaser, "Realizado")
	eventoHit:FireClient(objetivo, "Recibido")

	task.delay(COOLDOWN_HIT, function()
		cooldowns[chaser] = nil
	end)
end