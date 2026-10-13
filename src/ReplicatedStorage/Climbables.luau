local Climbables = {}

local function tieneAtributoEscalable(instance)
	-- Los atributos distinguen mayusculas de minusculas. Climbable es el
	-- nombre oficial; se conserva climbable para no romper objetos antiguos.
	return instance:GetAttribute("Climbable") == true
		or instance:GetAttribute("climbable") == true
end

function Climbables.IsClimbable(instance)
	if typeof(instance) ~= "Instance" or not instance:IsA("BasePart") then
		return false
	end
	if instance:IsA("TrussPart") or tieneAtributoEscalable(instance) then
		return true
	end

	-- Permite marcar una construccion completa sin repetir el atributo en cada
	-- pieza. Solo se hereda desde Models, no desde Folders globales que podrian
	-- convertir accidentalmente una zona completa del mapa en escalable.
	local ancestor = instance.Parent
	while ancestor and ancestor ~= workspace do
		if ancestor:IsA("Model") and tieneAtributoEscalable(ancestor) then
			return true
		end
		ancestor = ancestor.Parent
	end

	return false
end

return Climbables
