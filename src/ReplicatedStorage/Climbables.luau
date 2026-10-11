local CollectionService = game:GetService("CollectionService")

local Climbables = {}

function Climbables.IsClimbable(instance)
	return instance:IsA("BasePart") and (
		instance:IsA("TrussPart")
		or instance:GetAttribute("Escalable") == true
		or CollectionService:HasTag(instance, "Escalable")
	)
end

return Climbables
