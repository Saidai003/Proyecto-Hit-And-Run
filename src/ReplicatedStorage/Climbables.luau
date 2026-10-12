local CollectionService = game:GetService("CollectionService")

local Climbables = {}

local function marked(value)
	if value == true then return true end
	if type(value) ~= "string" then return false end
	local normalized = string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
	return normalized == "true" or normalized == "climbable" or normalized == "yes"
end

function Climbables.IsClimbable(instance)
	return typeof(instance) == "Instance" and instance:IsA("BasePart") and (
		instance:IsA("TrussPart")
		or instance:GetAttribute("Escalable") == true
		or CollectionService:HasTag(instance, "Escalable")
		or marked(instance:GetAttribute("climbable"))
		or marked(instance:GetAttribute("Climbable"))
		or CollectionService:HasTag(instance, "climbable")
		or CollectionService:HasTag(instance, "Climbable")
	)
end

return Climbables
