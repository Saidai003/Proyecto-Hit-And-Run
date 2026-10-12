local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StaminaService = {}
local stamina = {}
local sprint = {}
local ultimoUso = {}
local agotadoHasta = {}
local climb = {}
local slide = {}
local ultimoSlide = {}
local MAX = { PERSEGUIDO = 100, PERSEGUIDOR = 120 }
local COSTO = { Ventana = 25, Estrecho = 20, Pale = 20, Salto = 15 }
local REGEN = 14
local PAUSA_TRAS_AGOTARSE = 1.25
local COSTO_ESCALADA_POR_STUD = 5
local COSTO_SLIDE = 12
local UMBRAL_ESCALADA_LENTA = 15
local VELOCIDAD_ESCALADA_MAXIMA = 12

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
	climb[jugador] = nil
	slide[jugador] = nil
	ultimoSlide[jugador] = nil
	jugador:SetAttribute("EscaladaSinStamina", false)
	stamina[jugador] = maximo(jugador)
	sprint[jugador] = false
	agotadoHasta[jugador] = 0
	publicar(jugador)
end

function StaminaService.BeginClimb(jugador, root, custom)
	if jugador.Parent ~= Players or not root or (stamina[jugador] or 0) <= 0 then return nil end
	climb[jugador] = { root = root, y = root.Position.Y, custom = custom == true }
	jugador:SetAttribute("EscaladaSinStamina", false)
	return (stamina[jugador] or 0) < UMBRAL_ESCALADA_LENTA and (1 / 0.7) or 1
end

function StaminaService.EndClimb(jugador)
	climb[jugador] = nil
end

function StaminaService.BeginSlide(jugador, root)
	local ahora = os.clock()
	local actual = stamina[jugador] or 0
	local horizontal = root and Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude or 0
	local movement = root and root.AssemblyLinearVelocity.Magnitude or 0
	if jugador.Parent ~= Players or not sprint[jugador] or actual < COSTO_SLIDE
		or movement < 11 or horizontal < 4
		or ahora - (ultimoSlide[jugador] or -math.huge) < 0.8 then
		return false
	end
	ultimoSlide[jugador] = ahora
	stamina[jugador] = actual - COSTO_SLIDE
	sprint[jugador] = false
	slide[jugador] = true
	publicar(jugador)
	return true
end

function StaminaService.EndSlide(jugador)
	slide[jugador] = nil
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
	sprint[jugador] = activo and not slide[jugador]
end)

Players.PlayerAdded:Connect(function(jugador)
	if not jugador:GetAttribute("Rol") then jugador:SetAttribute("Rol", "PERSEGUIDO") end
	StaminaService.Reset(jugador)
	jugador:GetAttributeChangedSignal("Rol"):Connect(function()
		StaminaService.Reset(jugador)
	end)
end)
Players.PlayerRemoving:Connect(function(jugador)
	climb[jugador] = nil
	slide[jugador] = nil
	stamina[jugador] = nil
	sprint[jugador] = nil
	ultimoUso[jugador] = nil
	ultimoSlide[jugador] = nil
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
		local climbing = climb[jugador]
		if climbing then
			local root = climbing.root
			local humanoide = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
			if not humanoide or humanoide.Health <= 0 or jugador.Character ~= root.Parent then
				climb[jugador] = nil
			else
				local moved = math.min(math.abs(root.Position.Y - climbing.y), VELOCIDAD_ESCALADA_MAXIMA * dt)
				climbing.y = root.Position.Y
				local controlledClimb = if climbing.custom
					then math.abs(root.AssemblyLinearVelocity.Y) <= VELOCIDAD_ESCALADA_MAXIMA + 1
					else humanoide:GetState() == Enum.HumanoidStateType.Climbing
				if controlledClimb and moved > 0 then
					actual = math.max(0, actual - moved * COSTO_ESCALADA_POR_STUD)
					if actual == 0 then
						climb[jugador] = nil
						agotadoHasta[jugador] = os.clock() + PAUSA_TRAS_AGOTARSE
						jugador:SetAttribute("EscaladaSinStamina", true)
					end
				end
			end
		end
		local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		local enJuego = Workspace:GetAttribute("RondaEnJuego") == true
			or Workspace:GetAttribute("LobbyPractica") == true
		local puedeCorrer = sprint[jugador] and enJuego and not climb[jugador] and not slide[jugador]
			and humanoide and humanoide.Health > 0 and humanoide.MoveDirection.Magnitude > 0
			and not humanoide:GetAttribute("Inmovilizado")
			and not humanoide:GetAttribute("ParkourEspecialActivo")
		if puedeCorrer and actual > 0 then
			actual = math.max(0, actual - (jugador:GetAttribute("Rol") == "PERSEGUIDOR" and 20 or 18) * dt)
			if actual == 0 then agotadoHasta[jugador] = os.clock() + PAUSA_TRAS_AGOTARSE end
		elseif not (sprint[jugador] and enJuego) and not climb[jugador] and not slide[jugador]
			and os.clock() >= (agotadoHasta[jugador] or 0) then
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
