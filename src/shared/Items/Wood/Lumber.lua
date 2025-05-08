local Lumber = {}
Lumber.ItemName = "Lumber"
Lumber.ItemWeight = 2 -- Weight per 1 item
Lumber.ItemStack = 50 -- Max stack of items possible
Lumber.ItemType = "Ore"
Lumber.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Lumber")

return Lumber