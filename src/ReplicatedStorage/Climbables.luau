local Climbables = {}

function Climbables.IsClimbable(instance)
	return typeof(instance) == "Instance" and instance:IsA("BasePart") and (
		instance:IsA("TrussPart")
		or instance:GetAttribute("climbable") == true
	)
end

return Climbables
