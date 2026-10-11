local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugadorLocal = Players.LocalPlayer

local EventoPale =
	ReplicatedStorage:WaitForChild(
		"EventoPale1v1"
	)

local ID_ANIMACION_STUN =
	"rbxassetid://74925900786167"

local VELOCIDAD_ANIMACION_STUN = 0.5

local animacionStun = nil
local trackStun = nil


--==================================================
-- OBTENER ANIMATOR
--==================================================

local function obtenerAnimator()

	local personaje =
		jugadorLocal.Character

	if not personaje then
		return nil
	end

	local humanoide =
		personaje:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoide then
		return nil
	end

	local animator =
		humanoide:FindFirstChildOfClass(
			"Animator"
		)

	if not animator then

		animator =
			Instance.new("Animator")

		animator.Parent =
			humanoide
	end

	return animator
end


--==================================================
-- CARGAR ANIMACIÃN
--==================================================

local function prepararAnimacion()

	local animator =
		obtenerAnimator()

	if not animator then
		return
	end

	if animacionStun then
		animacionStun:Destroy()
	end

	animacionStun =
		Instance.new("Animation")

	animacionStun.AnimationId =
		ID_ANIMACION_STUN

	trackStun =
		animator:LoadAnimation(
			animacionStun
		)

	trackStun.Priority =
		Enum.AnimationPriority.Action

	trackStun.Looped = false
end


--==================================================
-- REPRODUCIR STUN
--==================================================

local function reproducirStun()

	if not trackStun
		or not trackStun.Parent then

		prepararAnimacion()
	end

	if not trackStun then
		return
	end

	if trackStun.IsPlaying then
		trackStun:Stop(0)
	end

	trackStun:Play(
		0.05,
		1,
		VELOCIDAD_ANIMACION_STUN
	)
end


--==================================================
-- EVENTO PALE
--==================================================

EventoPale.OnClientEvent:Connect(
	function(accion, objetivo)

		if accion ~= "ATURDIDO" then
			return
		end

		-- El servidor indica quiÃ©n recibiÃ³ el stun.
		-- Cada cliente reproduce la animaciÃ³n Ãºnicamente
		-- si ese personaje estÃ¡ presente en este cliente.
		if objetivo
			and objetivo.Character then

			local personaje =
				objetivo.Character

			local humanoide =
				personaje:FindFirstChildOfClass(
					"Humanoid"
				)

			if not humanoide then
				return
			end

			local animator =
				humanoide:FindFirstChildOfClass(
					"Animator"
				)

			if not animator then

				animator =
					Instance.new("Animator")

				animator.Parent =
					humanoide
			end

			local animacion =
				Instance.new("Animation")

			animacion.AnimationId =
				ID_ANIMACION_STUN

			local track =
				animator:LoadAnimation(
					animacion
				)

			track.Priority =
				Enum.AnimationPriority.Action

			track.Looped = false

			-- La animaciÃ³n dura aproximadamente 1 s.
			-- 0.5x => aproximadamente 2 s.
			track:Play(
				0.05,
				1,
				VELOCIDAD_ANIMACION_STUN
			)

			track.Stopped:Connect(
				function()

					animacion:Destroy()

				end
			)

		end
	end
)


--==================================================
-- RESPAWN
--==================================================

jugadorLocal.CharacterAdded:Connect(
	function()

		task.wait(0.5)

		prepararAnimacion()

	end
)


if jugadorLocal.Character then

	task.defer(
		prepararAnimacion
	)

end