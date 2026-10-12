local Workspace = game:GetService("Workspace")

-- Convenciones opcionales para Models del mapa:
--   KeepStreamed = true   -> siempre disponible en todos los clientes.
--   StreamAsAtomic = true -> aparece y desaparece como una unidad completa.
-- Persistent se reserva para muy pocos modelos pequeños e imprescindibles.

local originales = setmetatable({}, { __mode = "k" })
local conexiones = setmetatable({}, { __mode = "k" })

local function aplicar(modelo)
	local persistente = modelo:GetAttribute("KeepStreamed") == true
	local atomico = modelo:GetAttribute("StreamAsAtomic") == true

	if persistente or atomico then
		if originales[modelo] == nil then
			originales[modelo] = modelo.ModelStreamingMode
		end
		modelo.ModelStreamingMode = persistente
			and Enum.ModelStreamingMode.Persistent
			or Enum.ModelStreamingMode.Atomic
	elseif originales[modelo] ~= nil then
		modelo.ModelStreamingMode = originales[modelo]
		originales[modelo] = nil
	end
end

local function observar(instancia)
	if not instancia:IsA("Model") or conexiones[instancia] then return end

	aplicar(instancia)
	local conexionKeep = instancia:GetAttributeChangedSignal("KeepStreamed"):Connect(function()
		aplicar(instancia)
	end)
	local conexionAtomic = instancia:GetAttributeChangedSignal("StreamAsAtomic"):Connect(function()
		aplicar(instancia)
	end)
	conexiones[instancia] = { conexionKeep, conexionAtomic }
end

for _, instancia in ipairs(Workspace:GetDescendants()) do
	observar(instancia)
end

Workspace.DescendantAdded:Connect(observar)
Workspace.DescendantRemoving:Connect(function(instancia)
	local lista = conexiones[instancia]
	if not lista then return end
	for _, conexion in ipairs(lista) do conexion:Disconnect() end
	conexiones[instancia] = nil
	originales[instancia] = nil
end)
