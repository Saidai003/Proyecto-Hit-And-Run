local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local throwEvent = ReplicatedStorage:WaitForChild("ThrowChairEvent", 10)
if not throwEvent then
	warn("[ThrowChairClient] No existe ThrowChairEvent: revisa el Script de servidor en ServerScriptService")
	return
end

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isAiming = false
local returning = false
local folderVisuals = nil
local savedWalkSpeed = 16
local currentOffset = Vector3.zero

-- CONFIGURACIONES (deben coincidir con el Script de servidor)
local WALK_SPEED_AIMING = 8
local THROW_VELOCITY = 60
local START_FORWARD = 4
local START_UP = 1.5
local AIM_FOV = 65
local ORIGINAL_FOV = 70
local AIM_CAMERA_OFFSET = Vector3.new(-2.5, 1.2, -6)
local SMOOTHNESS = 12

local function getEquippedTool()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("Throwable") then
		return tool
	end
	return nil
end

local function setArmsRaised(character, raised)
	local rUpper = character:FindFirstChild("RightUpperArm")
	local lUpper = character:FindFirstChild("LeftUpperArm")
	local rShoulder = rUpper and rUpper:FindFirstChild("RightShoulder")
	local lShoulder = lUpper and lUpper:FindFirstChild("LeftShoulder")

	if rShoulder and lShoulder then
		local cf = raised and CFrame.Angles(math.rad(90), 0, 0) or CFrame.new()
		rShoulder.Transform = cf
		lShoulder.Transform = cf
	end
end

local function clearTrajectory()
	if folderVisuals then folderVisuals:ClearAllChildren() end
end

local function getStartPos(root)
	return root.Position + root.CFrame.LookVector * START_FORWARD + Vector3.new(0, START_UP, 0)
end

-- DirecciÃ³n desde el punto de salida hacia lo que apunta el centro de la cÃ¡mara
local function getAimDirection(startPos, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, folderVisuals }

	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local result = workspace:Raycast(origin, look * 500, params)
	local target = result and result.Position or (origin + look * 500)

	-- Si el objetivo estÃ¡ muy cerca, usar la direcciÃ³n de la cÃ¡mara tal cual
	if (target - origin).Magnitude < START_FORWARD + 3 then
		return look
	end
	return (target - startPos).Unit
end

local function updateTrajectory(character)
	if not folderVisuals or not folderVisuals.Parent then
		folderVisuals = Instance.new("Folder")
		folderVisuals.Name = "TrajectoryVisuals"
		folderVisuals.Parent = workspace
	else
		folderVisuals:ClearAllChildren() -- RNF04
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local startPos = getStartPos(root)
	local velocity = getAimDirection(startPos, character) * THROW_VELOCITY
	local gravityVec = Vector3.new(0, -workspace.Gravity, 0)

	local pointsCount = 35
	local timeStep = 1.0 / pointsCount

	for i = 1, pointsCount do
		local t = i * timeStep
		local sphere = Instance.new("Part")
		sphere.Size = Vector3.new(0.25, 0.25, 0.25)
		sphere.Shape = Enum.PartType.Ball
		sphere.Color = Color3.fromRGB(0, 255, 150)
		sphere.Material = Enum.Material.Neon
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.CanQuery = false
		sphere.CanTouch = false
		sphere.Position = startPos + velocity * t + 0.5 * gravityVec * t * t
		sphere.Parent = folderVisuals
	end
end

local function stopAiming()
	if not isAiming then return end
	isAiming = false
	returning = true
	clearTrajectory()

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character then setArmsRaised(character, false) end
	if humanoid then
		humanoid.WalkSpeed = savedWalkSpeed
		humanoid.AutoRotate = true
	end
end

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local alpha = 1 - math.exp(-SMOOTHNESS * dt) -- RNF02

	if isAiming and (not getEquippedTool() or not humanoid or humanoid.Health <= 0 or humanoid.PlatformStand) then
		stopAiming()
	end

	if isAiming and humanoid and root then
		humanoid.WalkSpeed = WALK_SPEED_AIMING -- RF02
		humanoid.AutoRotate = false -- RF03

		local cameraLook = camera.CFrame.LookVector
		local targetYaw = math.atan2(-cameraLook.X, -cameraLook.Z)
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, targetYaw, 0)

		camera.FieldOfView = camera.FieldOfView + (AIM_FOV - camera.FieldOfView) * alpha
		currentOffset = currentOffset:Lerp(AIM_CAMERA_OFFSET, alpha)

		setArmsRaised(character, true) -- RF05
		updateTrajectory(character) -- RF04
	elseif returning then
		camera.FieldOfView = camera.FieldOfView + (ORIGINAL_FOV - camera.FieldOfView) * alpha
		currentOffset = currentOffset:Lerp(Vector3.zero, alpha)

		local fovDone = math.abs(camera.FieldOfView - ORIGINAL_FOV) < 0.05
		if fovDone and currentOffset.Magnitude < 0.02 then
			camera.FieldOfView = ORIGINAL_FOV
			currentOffset = Vector3.zero
			returning = false
		end
	end
end)

-- Aplica el desplazamiento en el espacio de la cÃ¡mara, DESPUÃS del script de cÃ¡mara de Roblox
RunService:BindToRenderStep("ThrowChairCameraOffset", Enum.RenderPriority.Camera.Value + 1, function()
	if currentOffset.Magnitude > 0.001 then
		camera.CFrame = camera.CFrame * CFrame.new(currentOffset)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if isAiming then return end

	local tool = getEquippedTool()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if tool and humanoid and humanoid.Health > 0 and not humanoid:GetAttribute("Sliding") then
		savedWalkSpeed = humanoid.WalkSpeed
		returning = false
		isAiming = true -- RF01
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isAiming then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local direction = camera.CFrame.LookVector
		if root then
			direction = getAimDirection(getStartPos(root), character)
		end

		throwEvent:FireServer(direction)
		stopAiming()
	end
end)

