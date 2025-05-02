
local Pickaxe = {}

Pickaxe.ItemName = "Pickaxe"
Pickaxe.ItemWeight = 2 -- Weight per 1 item
Pickaxe.ItemStack = 50 -- Max stack of items possible
Pickaxe.ItemType = "Tool"
Pickaxe.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Pickaxe")
--[[
ResourceWhitelist is a StrDict where the key represents the ResourceType and the keys values is a table
of allowed resources of that ResourceType.
Including "All" in a ResourceType table allows for all resources of that ResourceType
--]]
Pickaxe.ResourceWhitelist = {
    Ore = {"All"}
}

return Pickaxe