local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then return end

task.delay(3, function()
	local metricas = {
		instancias = 0,
		partes = 0,
		meshes = 0,
		unions = 0,
		sinAnclar = 0,
		colision = 0,
		toque = 0,
		consulta = 0,
		sombras = 0,
		transparentes = 0,
		colisionPrecisa = 0,
		luces = 0,
		lucesConSombras = 0,
		particulas = 0,
		tasaParticulas = 0,
		beamsTrails = 0,
		texturas = 0,
		sonidos = 0,
		scriptsEnWorkspace = 0,
	}
	local meshIds = {}
	local textureIds = {}
	local grupos = {}
	local conteosGrupo = {}
	local descendientes = Workspace:GetDescendants()

	for _, objeto in ipairs(descendientes) do
		if objeto:IsA("Model") or objeto:IsA("Folder") then
			conteosGrupo[objeto] = { total = 0, partes = 0 }
		end
	end

	for _, objeto in ipairs(descendientes) do
		metricas.instancias += 1
		if objeto:IsA("BasePart") then
			metricas.partes += 1
			if not objeto.Anchored then metricas.sinAnclar += 1 end
			if objeto.CanCollide then metricas.colision += 1 end
			if objeto.CanTouch then metricas.toque += 1 end
			if objeto.CanQuery then metricas.consulta += 1 end
			if objeto.CastShadow then metricas.sombras += 1 end
			if objeto.Transparency > 0 and objeto.Transparency < 1 then
				metricas.transparentes += 1
			end
			if objeto:IsA("MeshPart") then
				metricas.meshes += 1
				if objeto.MeshId ~= "" then meshIds[objeto.MeshId] = true end
				if objeto.TextureID ~= "" then textureIds[objeto.TextureID] = true end
				if objeto.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then
					metricas.colisionPrecisa += 1
				end
			elseif objeto:IsA("UnionOperation") then
				metricas.unions += 1
				if objeto.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then
					metricas.colisionPrecisa += 1
				end
			end
		elseif objeto:IsA("PointLight") or objeto:IsA("SpotLight") or objeto:IsA("SurfaceLight") then
			metricas.luces += 1
			if objeto.Shadows then metricas.lucesConSombras += 1 end
		elseif objeto:IsA("ParticleEmitter") then
			metricas.particulas += 1
			if objeto.Enabled then metricas.tasaParticulas += objeto.Rate end
		elseif objeto:IsA("Beam") or objeto:IsA("Trail") then
			metricas.beamsTrails += 1
		elseif objeto:IsA("Texture") or objeto:IsA("Decal") or objeto:IsA("SurfaceAppearance") then
			metricas.texturas += 1
		elseif objeto:IsA("Sound") then
			metricas.sonidos += 1
		elseif objeto:IsA("LuaSourceContainer") then
			metricas.scriptsEnWorkspace += 1
		end

		local ancestro = objeto.Parent
		while ancestro and ancestro ~= Workspace do
			local conteo = conteosGrupo[ancestro]
			if conteo then
				conteo.total += 1
				if objeto:IsA("BasePart") then conteo.partes += 1 end
			end
			ancestro = ancestro.Parent
		end
	end

	for grupo, conteo in pairs(conteosGrupo) do
		if conteo.total >= 50 then
			table.insert(grupos, {
				nombre = grupo:GetFullName(),
				total = conteo.total,
				partes = conteo.partes,
			})
		end
	end

	local meshesUnicos = 0
	for _ in pairs(meshIds) do meshesUnicos += 1 end
	local texturasUnicas = 0
	for _ in pairs(textureIds) do texturasUnicas += 1 end
	table.sort(grupos, function(a, b) return a.total > b.total end)

	print("\n================ PERFORMANCE AUDIT (STUDIO) ================")
	print(string.format("Instances: %d | BaseParts: %d | MeshParts: %d (%d unique IDs) | Unions: %d",
		metricas.instancias, metricas.partes, metricas.meshes, meshesUnicos, metricas.unions))
	print(string.format("Unanchored: %d | CanCollide: %d | CanTouch: %d | CanQuery: %d",
		metricas.sinAnclar, metricas.colision, metricas.toque, metricas.consulta))
	print(string.format("CastShadow: %d | Partial transparency: %d | Precise collisions: %d",
		metricas.sombras, metricas.transparentes, metricas.colisionPrecisa))
	print(string.format("Lights: %d (%d shadowed) | ParticleEmitters: %d (enabled rate %.1f) | Beams/Trails: %d",
		metricas.luces, metricas.lucesConSombras, metricas.particulas,
		metricas.tasaParticulas, metricas.beamsTrails))
	print(string.format("Texture/Decal/SurfaceAppearance: %d | Mesh texture IDs: %d | Sounds: %d | Scripts in Workspace: %d",
		metricas.texturas, texturasUnicas, metricas.sonidos, metricas.scriptsEnWorkspace))
	print("Largest Models/Folders (copy this entire audit back to Codex):")
	for indice = 1, math.min(15, #grupos) do
		local grupo = grupos[indice]
		print(string.format("%02d. %s | instances=%d | parts=%d",
			indice, grupo.nombre, grupo.total, grupo.partes))
	end
	print("============================================================\n")
end)
