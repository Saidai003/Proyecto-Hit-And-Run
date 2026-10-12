local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local audio = require(ReplicatedStorage:WaitForChild("AudioPlayback"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("SolicitarParkour1v1")
local SLIDE_ANIMATION = "rbxassetid://81512224938575"
local MIN_SPEED = 7
local MAX_SPEED = 36
local INITIAL_SPEED_MULTIPLIER = 1.25
local FLAT_FRICTION = 7
local SLOPE_ACCELERATION = 36

local animation = Instance.new("Animation")
animation.AnimationId = SLIDE_ANIMATION
task.spawn(function()
	pcall(function() ContentProvider:PreloadAsync({ animation }) end)
end)

local character
local humanoid
local root
local track
local active = false
local frozen = false
local direction = Vector3.zero
local speed = 0
local started = 0
local airborne = 0
local lastEndAttempt = 0
local originalAutoRotate = true
local originalCameraOffset = Vector3.zero
local motionAttachment
local motionVelocity
local slideSound
local animateScript
local animateWasEnabled = true

local function clearMotion()
	if motionVelocity then motionVelocity:Destroy() motionVelocity = nil end
	if motionAttachment then motionAttachment:Destroy() motionAttachment = nil end
end

local function canStandLocally()
	if not character or not root then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
	if not ground then return true end
	local origin = Vector3.new(root.Position.X, ground.Position.Y + 1.2, root.Position.Z)
	local ceiling = workspace:Raycast(origin, Vector3.new(0, 4.6, 0), params)
	return not (ceiling and ceiling.Instance.CanCollide)
end

local function stopOtherAnimations()
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, other in ipairs(animator:GetPlayingAnimationTracks()) do
		if other ~= track and other.Priority.Value <= Enum.AnimationPriority.Movement.Value then
			other:Stop(0.08)
		end
	end
end

local function finish(force)
	if not active then return true end
	if not force then
		if not canStandLocally() then return false end
		if os.clock() - lastEndAttempt < 0.25 then return false end
		lastEndAttempt = os.clock()
	end
	active = false
	clearMotion()
	if slideSound then slideSound:Stop() slideSound:Destroy() slideSound = nil end
	if humanoid and humanoid.Parent then
		humanoid:SetAttribute("Sliding", false)
		humanoid.AutoRotate = originalAutoRotate
		humanoid.CameraOffset = originalCameraOffset
		humanoid.WalkSpeed = player:GetAttribute("Rol") == "PERSEGUIDOR" and 18 or 16
	end
	local finishedAnimate = animateScript
	local finishedAnimateWasEnabled = animateWasEnabled
	local restoreAnimateAfter = 0
	if track and track.IsPlaying then
		if force then
			track:Stop(0.08)
		else
			local finishedTrack = track
			local finishedSlide = started
			local length = finishedTrack.Length
			if length > 0 then
				finishedTrack.TimePosition = math.max(finishedTrack.TimePosition, length * 0.5)
			end
			finishedTrack:AdjustSpeed(1)
			restoreAnimateAfter = math.max(0.15, length * 0.5 + 0.1)
			task.delay(restoreAnimateAfter, function()
				if finishedTrack.IsPlaying and not active and started == finishedSlide then
					finishedTrack:Stop(0.08)
				end
			end)
		end
	end
	local finishedSlide = started
	task.delay(force and 0 or restoreAnimateAfter, function()
		if finishedAnimate and finishedAnimate.Parent and started == finishedSlide then
			finishedAnimate.Enabled = finishedAnimateWasEnabled
		end
	end)
	task.spawn(function()
		for _ = 1, 12 do
			local ok, allowed = pcall(function() return remote:InvokeServer("SlideEnd") end)
			if ok and allowed then return end
			if force then return end
			task.wait(0.15)
		end
		warn("[SLIDE] El servidor no pudo confirmar el fin del slide")
	end)
	return true
end

local function attach(newCharacter)
	finish(true)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")
	local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
	track = ok and loaded or nil
	animateScript = character:FindFirstChild("Animate")
	if track then
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = false
	else
		warn("[SLIDE] No se pudo cargar la animacion " .. SLIDE_ANIMATION)
	end
end

local function start()
	if active or not humanoid or not root or humanoid.Health <= 0 then return end
	if not (workspace:GetAttribute("RondaEnJuego") or workspace:GetAttribute("LobbyPractica")) then return end
	if humanoid:GetAttribute("SprintActivoLocal") ~= true
		or humanoid:GetAttribute("ParkourEspecialActivo")
		or humanoid:GetAttribute("EscaladaActiva")
		or humanoid:GetAttribute("Inmovilizado")
		or humanoid:GetAttribute("FallStunned")
		or humanoid:GetAttribute("GolpeActivo")
		or humanoid:GetAttribute("AttackRecovery")
		or humanoid.FloorMaterial == Enum.Material.Air then return end
	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontal.Magnitude < 11 then return end
	local sprintSpeed = humanoid.WalkSpeed
	local ok, allowed = pcall(function() return remote:InvokeServer("SlideStart") end)
	if not ok or not allowed then return end
	active = true
	frozen = false
	direction = horizontal.Unit
	speed = math.clamp(math.max(horizontal.Magnitude, sprintSpeed * INITIAL_SPEED_MULTIPLIER), 0, MAX_SPEED)
	started = os.clock()
	airborne = 0
	lastEndAttempt = 0
	originalAutoRotate = humanoid.AutoRotate
	originalCameraOffset = humanoid.CameraOffset
	humanoid.AutoRotate = false
	humanoid.CameraOffset = originalCameraOffset + Vector3.new(0, -1.2, 0)
	humanoid:SetAttribute("Sliding", true)
	humanoid.WalkSpeed = 0
	if animateScript and animateScript:IsA("LocalScript") then
		animateWasEnabled = animateScript.Enabled
		animateScript.Enabled = false
	end
	motionAttachment = Instance.new("Attachment")
	motionAttachment.Name = "SlideMotionAttachment"
	motionAttachment.Parent = root
	motionVelocity = Instance.new("LinearVelocity")
	motionVelocity.Name = "SlideMotionVelocity"
	motionVelocity.Attachment0 = motionAttachment
	motionVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	motionVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	motionVelocity.PrimaryTangentAxis = Vector3.xAxis
	motionVelocity.SecondaryTangentAxis = Vector3.zAxis
	motionVelocity.ForceLimitsEnabled = false
	motionVelocity.PlaneVelocity = Vector2.new(direction.X * speed, direction.Z * speed)
	motionVelocity.Parent = root
	if track then
		track:Play(0.08, 1, 1)
	end
	stopOtherAnimations()
	slideSound = audio.Play("Slide", root, 0.5, false, true)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
		if active then finish(false) else start() end
	elseif input.KeyCode == Enum.KeyCode.Space and active then
		finish(false)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if not active then return end
	if not character or not character.Parent or not humanoid or humanoid.Health <= 0
		or humanoid:GetAttribute("FallStunned") or humanoid:GetAttribute("Inmovilizado")
		or not (workspace:GetAttribute("RondaEnJuego") or workspace:GetAttribute("LobbyPractica")) then
		finish(true)
		return
	end
	if track and track.IsPlaying and not frozen and track.Length > 0
		and track.TimePosition >= track.Length * 0.5 then
		track:AdjustSpeed(0)
		track.TimePosition = track.Length * 0.5
		frozen = true
	end
	local desired = humanoid.MoveDirection
	desired = Vector3.new(desired.X, 0, desired.Z)
	if desired.Magnitude > 0.2 and direction:Dot(desired.Unit) > -0.2 then
		local steered = direction:Lerp(desired.Unit, math.min(dt * 2.2, 1))
		if steered.Magnitude > 0 then direction = steered.Unit end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
	if ground then
		airborne = 0
		local gravity = Vector3.new(0, -1, 0)
		local downSlope = gravity - ground.Normal * gravity:Dot(ground.Normal)
		local downhill = Vector3.new(downSlope.X, 0, downSlope.Z)
		local acceleration = downhill:Dot(direction) * SLOPE_ACCELERATION - FLAT_FRICTION
		speed = math.clamp(speed + acceleration * dt, 0, MAX_SPEED)
	else
		airborne += dt
	end

	if speed <= MIN_SPEED or airborne > 0.3 then
		if finish(false) then return end
		-- Stay low and keep moving until there is enough room to stand.
		speed = math.max(speed, MIN_SPEED)
	end
	if motionVelocity then
		motionVelocity.PlaneVelocity = Vector2.new(direction.X * speed, direction.Z * speed)
	end
	humanoid.WalkSpeed = 0
end)

player.CharacterAdded:Connect(attach)
if player.Character then attach(player.Character) end
