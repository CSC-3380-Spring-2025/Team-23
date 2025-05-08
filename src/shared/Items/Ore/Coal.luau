local Coal = {}
Coal.ItemName = "Coal"
Coal.ItemWeight = 2 -- Weight per 1 item
Coal.ItemStack = 50 -- Max stack of items possible
Coal.ItemType = "Ore"
Coal.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Coal")
Coal.Price = 10

return Coal