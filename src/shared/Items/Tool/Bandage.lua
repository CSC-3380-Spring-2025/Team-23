
local Bandage = {}

Bandage.ItemName = "Bandage"
Bandage.ItemWeight = 1 -- Weight per 1 item
Bandage.ItemStack = 10 -- Max stack of items possible
Bandage.ItemType = "Tool"
Bandage.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Bandage")
Bandage.HealthRegen = 20--The amount that the bandage heals the player

return Bandage