local Wheat = {}
Wheat.ItemName = "Wheat"
Wheat.ItemWeight = 1
Wheat.ItemStack = 50
Wheat.ItemType = "Crop"
Wheat.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Wheat")

return Wheat
