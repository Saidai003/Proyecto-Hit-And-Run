local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local musica = SoundService:WaitForChild("MusicaPersecucion")
local volumenMaximo = 0.5 -- Ajusta este valor (0.1 a 1) segÃºn quÃ© tan fuerte sea tu canciÃ³n

Workspace:GetAttributeChangedSignal("RondaEnJuego"):Connect(function()
	local enJuego = Workspace:GetAttribute("RondaEnJuego")

	if enJuego then
		musica.TimePosition = 0 -- Inicia la pista desde el segundo 0
		musica.Volume = 0
		musica:Play()

		-- Fade In: Sube el volumen suavemente durante 2 segundos
		local fadeIn = TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(musica, fadeIn, {Volume = volumenMaximo}):Play()

	else
		-- Fade Out: Baja el volumen suavemente durante 1.5 segundos al terminar la ronda
		local fadeOut = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local animacion = TweenService:Create(musica, fadeOut, {Volume = 0})

		animacion:Play()

		-- Esperamos a que termine el fade out para detener la pista por completo
		animacion.Completed:Wait()
		if not Workspace:GetAttribute("RondaEnJuego") then
			musica:Stop()
		end
	end
end)