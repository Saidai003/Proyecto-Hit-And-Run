local ParkourPairs = {}

local DISTANCIA_MAXIMA = 11
local DIFERENCIA_ALTURA_MAXIMA = 3

local function masCercano(origen)
	if typeof(origen) ~= "Instance" or not origen:IsA("BasePart") or not origen.Parent then return nil end
	local base, numero = origen.Name:match("^(PuntoSalto)_([12])$")
	if not base then base, numero = origen.Name:match("^(PuntoEntrada)_([12])$") end
	if not base then return nil end
	local nombreOpuesto = base .. (numero == "1" and "_2" or "_1")
	local mejor, distancia = nil, DISTANCIA_MAXIMA
	for _, candidato in ipairs(origen.Parent:GetChildren()) do
		if candidato:IsA("BasePart") and candidato.Name == nombreOpuesto then
			local desnivel = math.abs(candidato.Position.Y - origen.Position.Y)
			local d = (candidato.Position - origen.Position).Magnitude
			if desnivel <= DIFERENCIA_ALTURA_MAXIMA and d < distancia then
				mejor, distancia = candidato, d
			end
		end
	end
	return mejor
end

function ParkourPairs.Resolve(origen)
	local destino = masCercano(origen)
	if destino and masCercano(destino) == origen then return destino end
	return nil
end

return ParkourPairs
