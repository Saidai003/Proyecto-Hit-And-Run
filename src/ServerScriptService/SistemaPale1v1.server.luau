local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local StaminaService = require(script.Parent:WaitForChild("StaminaService"))
local PhysicsService = game:GetService("PhysicsService")

local EventoJuego = ReplicatedStorage:WaitForChild("EventoJuego")

local EventoPale = ReplicatedStorage:FindFirstChild("EventoPale1v1")

if not EventoPale then

	EventoPale = Instance.new("RemoteEvent")
	EventoPale.Name = "EventoPale1v1"
	EventoPale.Parent = ReplicatedStorage

end


--==================================================
-- CONFIGURACIÃN
--==================================================

local DISTANCIA_INTERACCION = 8.5

local TIEMPO_CAIDA = 0.3
local ANGULO_CAIDA = 50
local TIEMPO_BLOQUEO_SOBREVIVIENTE = 0.4

local TIEMPO_ROMPER = 2.0
local DURACION_ATURDIMIENTO = 2.0

-- Zona de aturdimiento, medida desde la bisagra del pale
-- sobre el eje de caÃ­da. SimÃ©trica: el mismo alcance hacia
-- el lado al que cae el pale y hacia el contrario. Antes era
-- asimÃ©trica y excluÃ­a al perseguidor si llegaba por detrÃ¡s.
local STUN_RANGE = 14
local MARGEN_LATERAL_ZONA = 1

local GROSOR_BLOQUEO = 1.2

-- Salto del perseguido sobre el pale caÃ­do
local DURACION_SALTO = 0.7
local ALTURA_SALTO = 2
local MARGEN_ATERRIZAJE = 5

local GRUPO_PARED = "PaleWall"
local GRUPO_ATRAVESANDO = "Saltando"

local SONIDO_CAIDA = "rbxassetid://0"
local SONIDO_ROMPER = "rbxassetid://0"
local SONIDO_ATURDIMIENTO = "rbxassetid://0"


--==================================================
-- COLLISION GROUPS
--==================================================

-- pcall porque registrar un grupo que ya existe lanza error.
pcall(function()
	PhysicsService:RegisterCollisionGroup(GRUPO_PARED)
end)

pcall(function()
	PhysicsService:RegisterCollisionGroup(GRUPO_ATRAVESANDO)
end)

PhysicsService:CollisionGroupSetCollidable(
	GRUPO_ATRAVESANDO,
	GRUPO_PARED,
	false
)

-- Mete (activo = true) o saca (activo = false) a un personaje
-- del grupo que atraviesa la pared del pale.
local function establecerAtravesando(personaje, activo)

	if not personaje then
		return
	end

	local grupo =
		activo
		and GRUPO_ATRAVESANDO
		or "Default"

	for _, parte in
		ipairs(personaje:GetDescendants()) do

		if parte:IsA("BasePart") then

			parte.CollisionGroup = grupo

		end
	end
end


--==================================================
-- ESTADO
--==================================================

local pales = {}
local bloqueos = {}
local ultimoUso = {}

local carpetaPlantillas =
	Instance.new("Folder")

carpetaPlantillas.Name = "PalesPlantilla"
carpetaPlantillas.Parent = ServerStorage


--==================================================
-- UTILIDADES
--==================================================

local function idRonda()

	return Workspace:GetAttribute("IdRonda") or 0

end


local function obtenerPersonaje(jugador)

	local personaje =
		jugador and jugador.Character

	if not personaje then
		return nil
	end

	local humanoide =
		personaje:FindFirstChildOfClass("Humanoid")

	local root =
		personaje:FindFirstChild("HumanoidRootPart")

	if humanoide
		and root
		and humanoide.Health > 0 then

		return humanoide, root
	end

	return nil
end


local function reproducirSonido(id, posicion)

	if id == "rbxassetid://0" then
		return
	end

	local anclaje = Instance.new("Part")

	anclaje.Anchored = true
	anclaje.CanCollide = false
	anclaje.CanQuery = false
	anclaje.CanTouch = false
	anclaje.Transparency = 1
	anclaje.Size = Vector3.one
	anclaje.Position = posicion
	anclaje.Parent = Workspace

	local sonido = Instance.new("Sound")

	sonido.SoundId = id
	sonido.Volume = 1
	sonido.RollOffMaxDistance = 80
	sonido.Parent = anclaje

	sonido:Play()

	Debris:AddItem(anclaje, 4)
end


--==================================================
-- INMOVILIZACIÃN
--==================================================

local function inmovilizar(
	jugador,
	humanoide,
	duracion
)

	if not humanoide
		or humanoide.Health <= 0 then

		return
	end

	local registro = bloqueos[humanoide]

	if not registro then

		registro = {

			id = 0,

			velocidad =
				humanoide.WalkSpeed,

			ronda = idRonda(),

		}

		bloqueos[humanoide] = registro
	end

	registro.id += 1

	local miId = registro.id

	humanoide.WalkSpeed = 0

	humanoide:SetAttribute(
		"Inmovilizado",
		true
	)

	-- El cliente (LogicaVelocidad1v1) reescribe
	-- WalkSpeed cada frame, asÃ­ que ponerlo a 0
	-- aquÃ­ no basta: el bloqueo real tiene que
	-- viajar por el evento.
	if jugador then

		EventoJuego:FireClient(
			jugador,
			"BLOQUEAR_MOVIMIENTO"
		)

	end

	task.delay(duracion, function()

		if bloqueos[humanoide] ~= registro
			or registro.id ~= miId then

			return
		end

		bloqueos[humanoide] = nil

		if humanoide.Parent then

			humanoide:SetAttribute(
				"Inmovilizado",
				false
			)

			if registro.ronda == idRonda() then

				humanoide.WalkSpeed =
					registro.velocidad

			end
		end

		-- Se envÃ­a incluso si el personaje ya no
		-- existe: el cliente guarda su flag local
		-- y necesita liberarlo para el respawn.
		if jugador then

			EventoJuego:FireClient(
				jugador,
				"DESBLOQUEAR_MOVIMIENTO"
			)

		end
	end)
end


local function liberarTodos()

	for humanoide in pairs(bloqueos) do

		if humanoide.Parent then

			humanoide:SetAttribute(
				"Inmovilizado",
				false
			)

		end
	end

	table.clear(bloqueos)

	-- El desbloqueo de la ronda ahora lo controla
	-- Controlador1v1: BLOQUEAR al iniciar la cuenta atrÃ¡s
	-- y DESBLOQUEAR al final del pre-round. Difundir
	-- DESBLOQUEAR_MOVIMIENTO aquÃ­ provocaba una carrera
	-- con el BLOQUEAR del countdown y dejaba a los
	-- jugadores moverse unos instantes al inicio de
	-- la cuenta atrÃ¡s.
end


--==================================================
-- GEOMETRÃA
--==================================================

local function mitadExtension(parte, direccion)

	local cf = parte.CFrame
	local s = parte.Size

	return 0.5 * (
		math.abs(
			direccion:Dot(cf.RightVector)
		) * s.X

			+ math.abs(
				direccion:Dot(cf.UpVector)
			) * s.Y

			+ math.abs(
				direccion:Dot(cf.LookVector)
			) * s.Z
	)
end


local function esMarcador(parte)

	return parte.Name == "PuntoPale_1"
		or parte.Name == "PuntoPale_2"

end


local function esVisual(objeto)

	if not objeto:IsA("BasePart") then
		return false
	end

	if esMarcador(objeto) then
		return false
	end

	if objeto.Name == "InvisibleWall" then
		return false
	end

	if objeto.Name:sub(1, 4) == "Fijo" then
		return false
	end

	return true
end


--==================================================
-- CONFIGURAR INVISIBLE WALL
--==================================================

local function configurarInvisibleWall(invisibleWall)

	if not invisibleWall then
		return
	end

	invisibleWall.Anchored = true
	invisibleWall.CanCollide = false
	invisibleWall.CanTouch = false

	-- Lo dejamos consultable por raycasts/query si fuese necesario.
	invisibleWall.CanQuery = true

	invisibleWall.Transparency = 1

	-- Los personajes en el grupo "Saltando" atraviesan esta pared.
	invisibleWall.CollisionGroup = GRUPO_PARED
end


--==================================================
-- REGISTRO DE PALE
--==================================================

local function registrarPale(
	contenedor,
	plantilla,
	padre
)

	local p1 =
		contenedor:FindFirstChild(
			"PuntoPale_1",
			true
		)

	local p2 =
		contenedor:FindFirstChild(
			"PuntoPale_2",
			true
		)

	local invisibleWall =
		contenedor:FindFirstChild(
			"InvisibleWall",
			true
		)

	if not p1 or not p2 then

		warn(
			"[Pale] Falta PuntoPale_1 o PuntoPale_2 en",
			contenedor:GetFullName()
		)

		return nil
	end

	if not invisibleWall then

		warn(
			"[Pale] Falta InvisibleWall en",
			contenedor:GetFullName()
		)

		return nil
	end

	local d =
		(p2.Position - p1.Position)
		* Vector3.new(1, 0, 1)

	if d.Magnitude < 0.01 then

		warn(
			"[Pale] Los puntos estÃ¡n alineados en vertical:",
			contenedor:GetFullName()
		)

		return nil
	end

	-- La lÃ­nea entre los puntos corre a lo ANCHO del pale,
	-- asÃ­ que es el eje de la bisagra (t).
	local t = d.Unit

	-- El eje de caÃ­da (d) es perpendicular a esa lÃ­nea.
	d = t:Cross(Vector3.yAxis).Unit

	local partes = {}
	local origen = {}

	local dMin, dMax =
		math.huge,
		-math.huge

	local tMin, tMax =
		math.huge,
		-math.huge

	local yMin = math.huge

	for _, objeto in
		ipairs(contenedor:GetDescendants()) do

		if esVisual(objeto) then

			objeto.Anchored = true
			objeto.CanCollide = false

			table.insert(
				partes,
				objeto
			)

			origen[objeto] =
				objeto.CFrame

			local pos =
				objeto.Position

			local cd =
				pos:Dot(d)

			local ed =
				mitadExtension(
					objeto,
					d
				)

			dMin =
				math.min(
					dMin,
					cd - ed
				)

			dMax =
				math.max(
					dMax,
					cd + ed
				)

			local ct =
				pos:Dot(t)

			local et =
				mitadExtension(
					objeto,
					t
				)

			tMin =
				math.min(
					tMin,
					ct - et
				)

			tMax =
				math.max(
					tMax,
					ct + et
				)

			yMin =
				math.min(
					yMin,
					pos.Y
					- mitadExtension(
						objeto,
						Vector3.yAxis
					)
				)
		end
	end

	if #partes == 0 then

		warn(
			"[Pale] No hay partes visuales en",
			contenedor:GetFullName()
		)

		return nil
	end

	-- Centro de la base inferior del pale.
	--
	-- d = eje de caÃ­da (perpendicular a los puntos)
	-- t = eje lateral (la lÃ­nea entre los puntos)
	-- yMin = parte inferior
	local hinge =
		d * ((dMin + dMax) / 2)
		+ t * ((tMin + tMax) / 2)
		+ Vector3.new(
			0,
			yMin,
			0
		)

	-- DirecciÃ³n de caÃ­da fija: hacia los puntos, derecha
	-- y perpendicular a la lÃ­nea que los une.
	-- Si cae al revÃ©s, cambia ">= 0" por "< 0".
	local centroPuntos =
		(p1.Position + p2.Position) / 2

	local signo =
		(centroPuntos - hinge):Dot(d) >= 0
		and 1
		or -1

	local direccionCaidaFija = d * signo

	configurarInvisibleWall(
		invisibleWall
	)

	-- Guardamos el CFrame original de la pared para que
	-- la rotaciÃ³n NO se acumule frame a frame.
	origen[invisibleWall] =
		invisibleWall.CFrame

	local datos = {

		contenedor = contenedor,

		plantilla = plantilla,

		padre = padre,

		p1 = p1,

		p2 = p2,

		invisibleWall = invisibleWall,

		partes = partes,

		origen = origen,

		d = d,

		direccionCaida = direccionCaidaFija,

		t = t,

		hinge = hinge,

		ancho = tMax - tMin,

		estado = "Parado",

		valido = true,

	}

	contenedor:SetAttribute(
		"EstadoPale",
		"Parado"
	)

	contenedor:SetAttribute(
		"Rompiendo",
		false
	)

	pales[contenedor] = datos

	return datos
end


--==================================================
-- ZONA DE ATURDIMIENTO
--==================================================

local function dentroDeZona(
	datos,
	direccionCaida,
	posicion
)

	local rel =
		posicion - datos.hinge

	local a =
		rel:Dot(direccionCaida)

	local l =
		rel:Dot(datos.t)

	return math.abs(a) <= STUN_RANGE
		and math.abs(l)
		<= datos.ancho / 2
		+ MARGEN_LATERAL_ZONA
		and math.abs(rel.Y) <= 6

end


--==================================================
-- ROTAR PALE
--==================================================

local function aplicarRotacion(
	datos,
	direccionCaida,
	progreso
)

	-- El eje de rotaciÃ³n es la lÃ­nea entre los puntos (t),
	-- perpendicular a la direcciÃ³n en que cae el pale.
	local eje = datos.t

	-- Determinamos el signo para que el pale
	-- siempre caiga hacia direccionCaida.
	if eje:Dot(
		Vector3.yAxis:Cross(direccionCaida)
		) < 0 then

		eje = -eje
	end

	local anguloFinal =
		math.rad(ANGULO_CAIDA)

	local angulo =
		anguloFinal
		* progreso
		* progreso

	local rotacion =
		CFrame.new(datos.hinge)
		* CFrame.fromAxisAngle(
			eje,
			angulo
		)
		* CFrame.new(-datos.hinge)

	for _, parte in
		ipairs(datos.partes) do

		if parte.Parent then

			parte.CFrame =
				rotacion
				* datos.origen[parte]

		end
	end

	-- El InvisibleWall NO rota con el pale: es un bloque
	-- de colisiÃ³n, no una parte visual. Antes rotaba los
	-- mismos 50 grados y quedaba inclinado, dejando paso
	-- por debajo de un lado.
end


--==================================================
-- SOLTAR PALE
--==================================================

local function soltarPale(datos, jugador)

	local humanoide, root =
		obtenerPersonaje(jugador)

	if not humanoide then
		return
	end

	if datos.estado ~= "Parado"
		or not datos.valido then

		return
	end

	datos.estado = "Cayendo"

	datos.contenedor:SetAttribute(
		"EstadoPale",
		"Cayendo"
	)

	-- DirecciÃ³n fija, definida al registrar el pale.
	local direccionCaida = datos.direccionCaida

	-- Evitamos que el propio jugador quede atrapado
	-- durante la animaciÃ³n de caÃ­da.
	inmovilizar(
		jugador,
		humanoide,
		TIEMPO_BLOQUEO_SOBREVIVIENTE
	)

	local inicio =
		os.clock()

	while true do

		if not datos.valido then
			return
		end

		local progreso =
			math.clamp(
				(os.clock() - inicio)
				/ TIEMPO_CAIDA,
				0,
				1
			)

		aplicarRotacion(
			datos,
			direccionCaida,
			progreso
		)

		if progreso >= 1 then
			break
		end

		RunService.Heartbeat:Wait()
	end

	if not datos.valido then
		return
	end


	--==================================================
	-- ACTIVAR COLLISION DEL PALE
	--==================================================

	if datos.invisibleWall
		and datos.invisibleWall.Parent then

		datos.invisibleWall.CanCollide = true

	end


	--==================================================
	-- ATURDIR AL PERSEGUIDOR
	--==================================================

	for _, otro in
		ipairs(Players:GetPlayers()) do

		if otro:GetAttribute("Rol")
			== "PERSEGUIDOR" then

			local hum, rootOtro =
				obtenerPersonaje(otro)

			if hum
				and dentroDeZona(
					datos,
					direccionCaida,
					rootOtro.Position
				) then

				inmovilizar(
					otro,
					hum,
					DURACION_ATURDIMIENTO
				)

				-- Todos los clientes reciben el evento
				-- para que ambos puedan ver el efecto.
				EventoPale:FireAllClients(
					"ATURDIDO",
					otro,
					DURACION_ATURDIMIENTO
				)

				reproducirSonido(
					SONIDO_ATURDIMIENTO,
					rootOtro.Position
				)

			end
		end
	end


	--==================================================
	-- SACAR JUGADORES DE LA LÃNEA DEL PALE
	--==================================================

	for _, otro in
		ipairs(Players:GetPlayers()) do

		local _, rootOtro =
			obtenerPersonaje(otro)

		if rootOtro then

			local rel =
				rootOtro.Position
			- datos.hinge

			local a =
				rel:Dot(direccionCaida)

			local l =
				rel:Dot(datos.t)

			if math.abs(a)
				< GROSOR_BLOQUEO / 2 + 0.9

				and math.abs(l)
				<= datos.ancho / 2 + 1

				and math.abs(rel.Y) <= 7 then

				local lado2 =
					a >= 0 and 1 or -1

				local nuevaA =
					lado2
					* (
						GROSOR_BLOQUEO / 2
						+ 1.2
					)

				rootOtro.CFrame =
					rootOtro.CFrame
					+ direccionCaida
					* (nuevaA - a)

			end
		end
	end


	--==================================================
	-- ESTADO FINAL
	--==================================================

	datos.estado = "Caido"

	datos.contenedor:SetAttribute(
		"EstadoPale",
		"Caido"
	)

	reproducirSonido(
		SONIDO_CAIDA,
		datos.hinge
	)
end


--==================================================
-- DESTRUCCIÃN
--==================================================

local function explotarPale(datos)

	if not datos.valido then
		return
	end

	if datos.estado ~= "Caido" then
		return
	end

	datos.estado = "Roto"

	datos.contenedor:SetAttribute(
		"EstadoPale",
		"Roto"
	)

	datos.contenedor:SetAttribute(
		"Rompiendo",
		false
	)


	--==================================================
	-- DESACTIVAR INVISIBLE WALL
	--==================================================

	if datos.invisibleWall
		and datos.invisibleWall.Parent then

		datos.invisibleWall.CanCollide = false

	end


	--==================================================
	-- SONIDO
	--==================================================

	reproducirSonido(
		SONIDO_ROMPER,
		datos.hinge
	)


	--==================================================
	-- EFECTO DE DESTRUCCIÃN
	--==================================================

	for _, parte in
		ipairs(datos.partes) do

		if parte.Parent then

			parte.Anchored = false
			parte.CanCollide = false

			parte.AssemblyLinearVelocity =
				Vector3.new(
					math.random(-12, 12),
					math.random(10, 20),
					math.random(-12, 12)
				)

			parte.AssemblyAngularVelocity =
				Vector3.new(
					math.random(-8, 8),
					math.random(-8, 8),
					math.random(-8, 8)
				)

			TweenService:Create(
				parte,
				TweenInfo.new(
					1.2,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out,
					0,
					false,
					0.3
				),
				{
					Transparency = 1
				}
			):Play()

		end
	end

	-- No eliminamos inmediatamente el contenedor.
	-- Dejamos que termine el efecto visual.
	Debris:AddItem(
		datos.contenedor,
		2
	)
end


--==================================================
-- ROMPER PALE
--==================================================

local function romperPale(
	datos,
	jugador,
	duracionAnim
)

	local humanoide, root =
		obtenerPersonaje(jugador)

	if not humanoide then
		return
	end

	if datos.estado ~= "Caido"
		or not datos.valido then

		return
	end

	if datos.contenedor:GetAttribute(
		"Rompiendo"
		) then

		return
	end

	datos.contenedor:SetAttribute(
		"Rompiendo",
		true
	)

	-- El cliente manda la duraciÃ³n real de la animaciÃ³n
	-- (leÃ­da de track.Length) para que el bloqueo y el
	-- break ocurran exactamente cuando termina la animaciÃ³n,
	-- no un segundo despuÃ©s.
	local duracionRomper = duracionAnim or TIEMPO_ROMPER

	-- El perseguidor queda quieto durante
	-- toda la animaciÃ³n de romper.
	inmovilizar(
		jugador,
		humanoide,
		duracionRomper
	)

	local direccion =
		(datos.hinge - root.Position)
		* Vector3.new(1, 0, 1)

	if direccion.Magnitude > 0.1 then

		root.CFrame =
			CFrame.lookAt(
				root.Position,
				root.Position + direccion
			)

	end


	-- La duraciÃ³n del servidor coincide con
	-- la duraciÃ³n de la animaciÃ³n de romper.
	task.delay(
		duracionRomper,
		function()

			if not datos.valido
				or datos.estado ~= "Caido" then

				return
			end

			if not humanoide.Parent
				or humanoide.Health <= 0 then

				datos.contenedor:SetAttribute(
					"Rompiendo",
					false
				)

				return
			end

			explotarPale(datos)

		end
	)
end


--==================================================
-- SALTAR PALE CAÃDO (PERSEGUIDO)
--==================================================

local function saltarPale(datos, jugador)

	local humanoide, root =
		obtenerPersonaje(jugador)

	if not humanoide then
		return
	end

	if datos.estado ~= "Caido"
		or not datos.valido then

		return
	end

	local p1 = datos.contenedor:FindFirstChild("PuntoPale_1")
	local p2 = datos.contenedor:FindFirstChild("PuntoPale_2")

	if not p1 or not p2 then
		return
	end
	local factorCosto = StaminaService.Consume(jugador, "Pale")
	if not factorCosto then return end
	local duracionSalto = DURACION_SALTO * factorCosto

	-- El salto va de un PuntoPale al otro. El mÃ¡s cercano
	-- al jugador marca el INICIO de la animaciÃ³n; el OTRO
	-- Punto (el del extremo opuesto de la bisagra) es el
	-- DESTINO. Ambos extremos se envÃ­an al cliente como
	-- Vector3 para que el tween use Lerp(Vector3, Vector3, t)
	-- y no reviente con "invalid argument #2 (Vector3 expected,
	-- got CFrame)".
	local d1 = (root.Position - p1.Position).Magnitude
	local d2 = (root.Position - p2.Position).Magnitude
	local pOrigen = (d1 < d2) and p1 or p2
	local pDestino = (d1 < d2) and p2 or p1

	-- El Punto estÃ¡ en el suelo. Si igualamos la Y del centro
	-- del personaje a la Y del Punto, los pies se hunden
	-- HipHeight studs por debajo del piso y se ve el "phase"
	-- al arrancar y al aterrizar. Subimos la Y de inicio y
	-- destino por la altura de la cadera del personaje (leÃ­da
	-- del Humanoid para que tambiÃ©n funcione con el perso-
	-- naje escalado del perseguidor) para que los pies
	-- queden apoyados en el Punto (sobre el piso) al inicio
	-- y al final de la animaciÃ³n.
	local alturaSobreMarcador = root.Position.Y - pOrigen.Position.Y
	local inicio = pOrigen.Position + Vector3.new(0, alturaSobreMarcador, 0)
	local destino = pDestino.Position + Vector3.new(0, alturaSobreMarcador, 0)

	local personaje = jugador.Character

	-- Durante el salto atraviesa la pared.
	establecerAtravesando(personaje, true)

	inmovilizar(
		jugador,
		humanoide,
		duracionSalto + 0.1
	)

	EventoPale:FireClient(
		jugador,
		"SALTAR",
		inicio,
		destino,
		duracionSalto,
		ALTURA_SALTO
	)

	-- Al terminar vuelve a colisionar normalmente.
	task.delay(duracionSalto + 0.15, function()

		if personaje and personaje.Parent then

			establecerAtravesando(
				personaje,
				false
			)

		end
	end)
end


--==================================================
-- REINICIO ENTRE RONDAS
--==================================================

local function reiniciarPales()

	liberarTodos()

	local lista = {}

	for _, datos in pairs(pales) do

		table.insert(
			lista,
			datos
		)

	end

	table.clear(pales)

	for _, datos in ipairs(lista) do

		datos.valido = false

		if datos.contenedor.Parent then

			datos.contenedor:Destroy()

		end

		local nuevo =
			datos.plantilla:Clone()

		nuevo.Parent =
			datos.padre

		local nuevoDatos =
			registrarPale(
				nuevo,
				datos.plantilla,
				datos.padre
			)

		if nuevoDatos then

			print(
				"[PALE REGISTRADO]:",
				nuevo.Name
			)

		end
	end
end


Workspace:GetAttributeChangedSignal(
	"IdRonda"
):Connect(reiniciarPales)


--==================================================
-- INTERACCIÃN
--==================================================

EventoPale.OnServerEvent:Connect(
	function(jugador, accion, duracionAnim)

		if accion ~= "INTERACTUAR" then
			return
		end

		-- Un pale solo puede utilizarse durante
		-- gameplay real.
		local rondaEnJuego =
			Workspace:GetAttribute(
				"RondaEnJuego"
			)

		if not rondaEnJuego and not Workspace:GetAttribute("LobbyPractica") then

			return
		end

		local ahora =
			os.clock()

		if ultimoUso[jugador]
			and ahora - ultimoUso[jugador]
			< 0.3 then

			return
		end

		ultimoUso[jugador] =
			ahora

		local humanoide, root =
			obtenerPersonaje(jugador)

		if not humanoide then
			return
		end

		if humanoide:GetAttribute(
			"Inmovilizado"
			) then

			return
		end

		local rol =
			jugador:GetAttribute("Rol")

		local mejor = nil

		local mejorDistancia =
			DISTANCIA_INTERACCION

		for _, datos in pairs(pales) do

			if datos.valido then

				local aplica =
					(
						rol == "PERSEGUIDO"
						and (
							datos.estado == "Parado"
							or datos.estado == "Caido"
						)
					)
					or
					(
						rol == "PERSEGUIDOR"
						and datos.estado == "Caido"
						and not datos.contenedor:GetAttribute(
							"Rompiendo"
						)
					)

				if aplica then

					local distancia =
						math.min(
							(
								root.Position
								- datos.p1.Position
							).Magnitude,

							(
								root.Position
								- datos.p2.Position
							).Magnitude
						)

					if distancia <= mejorDistancia
						and math.min(math.abs(root.Position.Y - datos.p1.Position.Y),
							math.abs(root.Position.Y - datos.p2.Position.Y)) <= 4.5 then

						mejorDistancia =
							distancia

						mejor =
							datos

					end
				end
			end
		end

		if not mejor then

			print(
				"[CANCELADO]: El jugador estÃ¡ muy lejos del pale o el estado no coincide con su rol. Rol:",
				tostring(rol)
			)

			return
		end

		print(
			"[SERVIDOR]: Procesando interacciÃ³n de",
			jugador.Name,
			"| Rol:",
			rol,
			"| Pale:",
			mejor.contenedor.Name
		)

		if rol == "PERSEGUIDO" then

			if mejor.estado == "Parado" then

				task.spawn(
					soltarPale,
					mejor,
					jugador
				)

			elseif mejor.estado == "Caido" then

				saltarPale(
					mejor,
					jugador
				)

			end

		elseif rol == "PERSEGUIDOR" then

			romperPale(
				mejor,
				jugador,
				duracionAnim
			)

		end
	end
)


--==================================================
-- PLAYER REMOVING
--==================================================

Players.PlayerRemoving:Connect(
	function(jugador)

		ultimoUso[jugador] = nil

	end
)


--==================================================
-- INICIO
-- Registrar todos los pales del Workspace
--==================================================

local vistos = {}

for _, objeto in
	ipairs(Workspace:GetDescendants()) do

	if objeto:IsA("BasePart")
		and objeto.Name == "PuntoPale_1" then

		local contenedor =
			objeto.Parent

		if contenedor
			and contenedor ~= Workspace
			and not vistos[contenedor]
			and contenedor:FindFirstChild(
				"PuntoPale_2"
			)
				and contenedor:FindFirstChild(
					"InvisibleWall",
					true
				) then

			vistos[contenedor] = true

			-- IMPORTANTE:
			-- La plantilla se crea ANTES de modificar
			-- el pale original.
			local plantilla =
				contenedor:Clone()

			plantilla.Parent =
				carpetaPlantillas

			local datos =
				registrarPale(
					contenedor,
					plantilla,
					contenedor.Parent
				)

			if datos then

				print(
					"[PALE REGISTRADO]:",
					contenedor.Name
				)

			end
		end
	end
end
