-- Client-only bridge: the touch HUD invokes the same handlers as keyboard/mouse.
local function signal()
	return Instance.new("BindableEvent")
end

return {
	SprintStart = signal(),
	SprintEnd = signal(),
	Jump = signal(),
	Action = signal(),
	Slide = signal(),
	ThrowStart = signal(),
	ThrowEnd = signal(),
	LookDelta = signal(),
	AttackStart = signal(),
	AttackEnd = signal(),
}
