local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = require(ReplicatedStorage:WaitForChild("DonationConfig"))

if typeof(config.ProductId) == "number" and config.ProductId > 0 then
	MarketplaceService:BindReceiptHandler(
		Enum.ReceiptType.DeveloperProduct,
		function(receipt)
			print("[DONATION] Receipt confirmed for user", receipt.PlayerId)
			return Enum.ReceiptDecision.Processed
		end,
		{ config.ProductId }
	)
end
