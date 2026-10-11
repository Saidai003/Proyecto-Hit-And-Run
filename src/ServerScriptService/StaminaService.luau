local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StaminaService = {}
local stamina = {}
local sprint = {}
local ultimoUso = {}
local agotadoHasta = {}
local MAX = { PERSEGUIDO = 100, PERSEGUIDOR = 120 }
local COSTO = { Ventana = 25, Estrecho = 20, Pale = 20, Escalada = 15, Salto = 15 }
local REGEN = 14
local PAUSA_TRAS_AGOTARSE = 1.25

local remote = ReplicatedStorage:WaitForChild("Sprint1v1")

local function maximo(jugador)
	return MAX[jugador:GetAttribute("Rol")] or 100
end

local function publicar(jugador)
	if jugador.Parent == Players then
		jugador:SetAttribute("StaminaMax", maximo(jugador))
		jugador:SetAttribute("Stamina", math.floor((stamina[jugador] or 0) * 10 + 0.5) / 10)
	end
end

function StaminaService.Reset(jugador)
	stamina[jugador] = maximo(jugador)
	sprint[jugador] = false
	agotadoHasta[jugador] = 0
	publicar(jugador)
end

-- Returns a duration multiplier. At low stamina, speed is 70% of normal.
function StaminaService.Consume(jugador, accion)
	local costo = COSTO[accion]
	if not costo or jugador.Parent ~= Players
		or not (Workspace:GetAttribute("RondaEnJuego") or Workspace:GetAttribute("LobbyPractica")) then
		return nil
	end
	local ahora = os.clock()
	if ahora - (ultimoUso[jugador] or -math.huge) < 0.25 then
		return nil
	end
	ultimoUso[jugador] = ahora
	local actual = stamina[jugador] or maximo(jugador)
	if accion == "Salto" and actual < costo then return nil end
	local lento = actual < costo
	stamina[jugador] = math.max(0, actual - costo)
	if stamina[jugador] == 0 then
		agotadoHasta[jugador] = ahora + PAUSA_TRAS_AGOTARSE
	end
	publicar(jugador)
	return lento and (1 / 0.7) or 1
end

remote.OnServerEvent:Connect(function(jugador, activo)
	if typeof(activo) ~= "boolean" then return end
	sprint[jugador] = activo
end)

Players.PlayerAdded:Connect(function(jugador)
	if not jugador:GetAttribute("Rol") then jugador:SetAttribute("Rol", "PERSEGUIDO") end
	StaminaService.Reset(jugador)
	jugador:GetAttributeChangedSignal("Rol"):Connect(function()
		StaminaService.Reset(jugador)
	end)
end)
Players.PlayerRemoving:Connect(function(jugador)
	stamina[jugador] = nil
	sprint[jugador] = nil
	ultimoUso[jugador] = nil
	agotadoHasta[jugador] = nil
end)
for _, jugador in ipairs(Players:GetPlayers()) do
	if not jugador:GetAttribute("Rol") then jugador:SetAttribute("Rol", "PERSEGUIDO") end
	StaminaService.Reset(jugador)
end

local publishClock = 0
RunService.Heartbeat:Connect(function(dt)
	publishClock += dt
	for _, jugador in ipairs(Players:GetPlayers()) do
		local actual = stamina[jugador] or maximo(jugador)
		local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		local enJuego = Workspace:GetAttribute("RondaEnJuego") == true
			or Workspace:GetAttribute("LobbyPractica") == true
		local puedeCorrer = sprint[jugador] and enJuego
			and humanoide and humanoide.Health > 0 and humanoide.MoveDirection.Magnitude > 0
			and not humanoide:GetAttribute("Inmovilizado")
			and not humanoide:GetAttribute("ParkourEspecialActivo")
		if puedeCorrer and actual > 0 then
			actual = math.max(0, actual - (jugador:GetAttribute("Rol") == "PERSEGUIDOR" and 20 or 18) * dt)
			if actual == 0 then agotadoHasta[jugador] = os.clock() + PAUSA_TRAS_AGOTARSE end
		elseif not (sprint[jugador] and enJuego) and os.clock() >= (agotadoHasta[jugador] or 0) then
			actual = math.min(maximo(jugador), actual + REGEN * dt)
		end
		stamina[jugador] = actual
	end
	if publishClock >= 0.1 then
		publishClock = 0
		for _, jugador in ipairs(Players:GetPlayers()) do publicar(jugador) end
	end
end)

return StaminaService
