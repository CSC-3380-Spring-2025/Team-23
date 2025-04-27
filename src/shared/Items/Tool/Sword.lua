
local Sword = {}

Sword.ItemName = "Sword"
Sword.ItemWeight = 2 -- Weight per 1 item
Sword.ItemStack = 50 -- Max stack of items possible
Sword.ItemType = "Tool"
Sword.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Sword")

return Sword