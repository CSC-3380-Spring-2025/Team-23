
local Iron = {}

Iron.ItemName = "Iron"
Iron.ItemWeight = 2 -- Weight per 1 item
Iron.ItemStack = 50 -- Max stack of items possible
Iron.ItemType = "Ore"
Iron.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Iron")

return Iron