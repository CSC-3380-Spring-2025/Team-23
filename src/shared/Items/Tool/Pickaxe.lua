
local Pickaxe = {}

Pickaxe.ItemName = "Pickaxe"
Pickaxe.ItemWeight = 2 -- Weight per 1 item
Pickaxe.ItemStack = 50 -- Max stack of items possible
Pickaxe.ItemType = "Tool"
Pickaxe.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Pickaxe")

return Pickaxe