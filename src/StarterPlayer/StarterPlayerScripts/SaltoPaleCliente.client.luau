print("[ThrowChairClient] iniciando")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local throwEvent = ReplicatedStorage:WaitForChild("ThrowChairEvent", 10)
if not throwEvent then
	warn("[ThrowChairClient] No existe ThrowChairEvent: revisa el Script de servidor en ServerScriptService")
	return
end
print("[ThrowChairClient] cargado")

local jugador = Players.LocalPlayer
local EventoPale = ReplicatedStorage:WaitForChild("EventoPale1v1")

local NOMBRE_BIND = "SaltoPale"

EventoPale.OnClientEvent:Connect(
	function(accion, inicio, destino, duracion, altura)

		if accion ~= "SALTAR" then
			return
		end

		local personaje = jugador.Character

		local root =
			personaje
			and personaje:FindFirstChild("HumanoidRootPart")

		local humanoide =
			personaje
			and personaje:FindFirstChildOfClass("Humanoid")

		if not root or not humanoide then
			return
		end

		RunService:UnbindFromRenderStep(NOMBRE_BIND)

		local t0 = os.clock()

		-- La rotaciÃ³n NO se bloquea: la controla el Humanoid
		-- a travÃ©s de AutoRotate (que sigue a la cÃ¡mara) durante
		-- todo el salto. El tween solo escribe la posiciÃ³n; si
		-- conservamos la rotaciÃ³n actual del HumanoidRootPart,
		-- el personaje no se queda mirando en una direcciÃ³n
		-- fija despuÃ©s de terminar la animaciÃ³n (el "lock" que
		-- reportaba el autor).

		-- Prioridad justo despuÃ©s del personaje y ANTES de
		-- la cÃ¡mara, para que la cÃ¡mara no tiemble.
		RunService:BindToRenderStep(
			NOMBRE_BIND,
			Enum.RenderPriority.Character.Value + 1,
			function()

				if humanoide.Health <= 0
					or not root.Parent then

					RunService:UnbindFromRenderStep(NOMBRE_BIND)
					return
				end

				local a =
					math.clamp(
						(os.clock() - t0) / duracion,
						0,
						1
					)

				-- Trayectoria en arco (parÃ¡bola). inicio y
				-- destino son Vector3 (antes el destino viajaba
				-- como CFrame y el Lerp reventaba con
				-- "invalid argument #2 (Vector3 expected,
				-- got CFrame)" en cada frame del RenderStep).
				local pos =
					inicio:Lerp(destino, a)
					+ Vector3.new(
						0,
						altura * 4 * a * (1 - a),
						0
					)

				-- Solo escribimos la posiciÃ³n; conservamos la
				-- rotaciÃ³n que el Humanoid acaba de fijar este
				-- mismo frame (AutoRotate siguiendo a la cÃ¡mara).
				root.CFrame =
					CFrame.new(pos) * root.CFrame.Rotation

				root.AssemblyLinearVelocity = Vector3.zero

				if a >= 1 then

					RunService:UnbindFromRenderStep(NOMBRE_BIND)

					-- T05: dejar que la gravedad haga visible
					-- la caÃ­da tras la animaciÃ³n. Antes el
					-- personaje se quedaba flotando porque el
					-- tween dejaba la velocidad a cero.
					humanoide:ChangeState(
						Enum.HumanoidStateType.Freefall
					)

				end
			end
		)
	end
)