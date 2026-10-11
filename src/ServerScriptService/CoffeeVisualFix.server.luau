-- Coffee's visible cup is a nested, anchored Model. Its direct Tool.Handle is
-- transparent, so the cup stays behind when Roblox equips or throws the Tool.
-- Keep the imported asset intact in Studio and repair its physics assembly at runtime.
local function prepareCoffee(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Coffee" then return end
	local handle = tool:FindFirstChild("Handle")
	local visualModel = tool:FindFirstChild("Coffee")
	if not handle or not handle:IsA("BasePart")
		or not visualModel or not visualModel:IsA("Model") then return end

	-- The asset's old joints connect only the nested pieces, and some references
	-- are stale. Weld each visible piece directly to the real Tool.Handle instead.
	for _, descendant in ipairs(visualModel:GetDescendants()) do
		if descendant:IsA("Weld") then
			descendant:Destroy()
		end
	end

	for _, part in ipairs(visualModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if not part:FindFirstChild("CoffeeHandleWeld") then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "CoffeeHandleWeld"
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = part
			end
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true
		end
	end
end

for _, descendant in ipairs(game:GetDescendants()) do
	if descendant:IsA("Tool") and descendant.Name == "Coffee" then
		prepareCoffee(descendant)
	end
end

game.DescendantAdded:Connect(function(descendant)
	local tool = descendant:IsA("Tool") and descendant
		or descendant:FindFirstAncestorOfClass("Tool")
	if tool and tool.Name == "Coffee" then
		task.defer(prepareCoffee, tool)
	end
end)
