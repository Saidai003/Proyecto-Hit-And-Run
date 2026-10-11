local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local throwEvent = ReplicatedStorage:FindFirstChild("ThrowChairEvent")
if not throwEvent then
	throwEvent = Instance.new("RemoteEvent")
	throwEvent.Name = "ThrowChairEvent"
	throwEvent.Parent = ReplicatedStorage
end

-- Deben coincidir con el LocalScript
local KNOCKOUT_TIME = 3        -- segundos noqueado
local MIN_HIT_SPEED = 25       -- velocidad mÃ­nima de la silla para noquear
local HIT_WINDOW = 4           -- segundos despuÃ©s del lanzamiento en que puede noquear
local KNOCK_IMPULSE = 35       -- fuerza del empujÃ³n al golpear

local THROW_VELOCITY = 60
local START_FORWARD = 4
local START_UP = 1.5
local PICKUP_DELAY = 1.5

local KNOCK_IMMUNITY = 1.5 -- segundos de inmunidad al despertar

local function knockOut(victimChar, direction, handle)
	local hum = victimChar:FindFirstChildOfClass("Humanoid")
	local root = victimChar:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return end
	if victimChar:GetAttribute("KnockedOut") then return end

	print("[KNOCKOUT]", victimChar.Name) -- diagnÃ³stico: si sale dos veces seguidas, hay otro script llamÃ¡ndolo

	victimChar:SetAttribute("KnockedOut", true)
	hum.PlatformStand = true

	-- La silla deja de colisionar con la vÃ­ctima, para que no la empuje al levantarse
	for _, part in ipairs(victimChar:GetDescendants()) do
		if part:IsA("BasePart") then
			local nc = Instance.new("NoCollisionConstraint")
			nc.Part0 = handle
			nc.Part1 = part
			nc.Parent = handle
		end
	end

	pcall(function() root:SetNetworkOwner(nil) end)
	root:ApplyImpulse(direction * root.AssemblyMass * KNOCK_IMPULSE + Vector3.new(0, root.AssemblyMass * 15, 0))
	root.AssemblyAngularVelocity = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))

	task.delay(KNOCKOUT_TIME, function()
		if not victimChar.Parent then return end

		-- Enderezar al personaje y quitar velocidades antes de despertarlo
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			local _, yaw, _ = root.CFrame:ToOrientation()
			root.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, yaw, 0)
		end

		if hum.Parent and hum.Health > 0 then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if root.Parent then
			pcall(function() root:SetNetworkOwnershipAuto() end)
		end

		-- Inmunidad corta para que no se encadene otro noqueo
		task.delay(KNOCK_IMMUNITY, function()
			if victimChar.Parent then
				victimChar:SetAttribute("KnockedOut", nil)
			end
		end)
	end)
end

local function startHitDetection(handle, tool, character)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, tool }

	local expire = os.clock() + HIT_WINDOW
	local lastVelocity = Vector3.new(0, 0, 1) * THROW_VELOCITY
	local conn

	conn = RunService.Heartbeat:Connect(function()
		if os.clock() > expire or not handle.Parent then
			conn:Disconnect()
			return
		end

		-- Se usa la velocidad del frame anterior, antes de que el choque la frene
		if lastVelocity.Magnitude >= MIN_HIT_SPEED then
			local parts = workspace:GetPartBoundsInBox(handle.CFrame, handle.Size + Vector3.new(1, 1, 1), params)
			for _, part in ipairs(parts) do
				local victimChar = part:FindFirstAncestorOfClass("Model")
				if victimChar and victimChar:FindFirstChildOfClass("Humanoid") then
					conn:Disconnect() -- un solo golpe por lanzamiento
					local dir = lastVelocity.Unit
					knockOut(victimChar, Vector3.new(dir.X, 0, dir.Z), handle)
					return
				end
			end
		end

		lastVelocity = handle.AssemblyLinearVelocity
	end)
end

throwEvent.OnServerEvent:Connect(function(player, aimDirection)
	if typeof(aimDirection) ~= "Vector3" or aimDirection.Magnitude < 0.5 or aimDirection.Magnitude ~= aimDirection.Magnitude then
		return
	end
	aimDirection = aimDirection.Unit
	local character = player.Character
	if not character then return end

	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool:GetAttribute("Throwable") then return end
	if tool:GetAttribute("Throwing") then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local handle = tool:FindFirstChild("Handle")
	if not humanoid or humanoid.Health <= 0 or not root or not handle then return end

	tool:SetAttribute("Throwing", true)

	local look = root.CFrame.LookVector
	local startPos = root.Position + look * START_FORWARD + Vector3.new(0, START_UP, 0)
	local velocity = aimDirection * THROW_VELOCITY

	handle.CanTouch = false -- evita la recogida automÃ¡tica inmediata

	-- RF06: sacar la Tool completa de las manos
	tool.Parent = workspace

	for _, joint in ipairs(handle:GetJoints()) do
		local other = joint.Part0 == handle and joint.Part1 or joint.Part0
		if other and other:IsDescendantOf(character) then
			joint:Destroy()
		end
	end

	if handle.Parent then
		handle.CanCollide = true
		handle.CFrame = CFrame.new(startPos) * handle.CFrame.Rotation
		-- The old Heartbeat:Wait() left the chair stationary for one network frame.
		-- Establish authority and launch in the same server step.
		pcall(function() handle:SetNetworkOwner(nil) end)

		handle.AssemblyLinearVelocity = velocity
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = velocity
		bv.Parent = handle
		Debris:AddItem(bv, 0.1)
		
		startHitDetection(handle, tool, character)
	end

	tool:SetAttribute("Throwing", nil)

	task.delay(PICKUP_DELAY, function()
		if handle and handle.Parent then
			handle.CanTouch = true
		end
	end)
end)
