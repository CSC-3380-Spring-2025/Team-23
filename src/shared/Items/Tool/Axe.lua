
local Axe = {}

Axe.ItemName = "Axe"
Axe.ItemWeight = 2 -- Weight per 1 item
Axe.ItemStack = 1 -- Max stack of items possible
Axe.ItemType = "Tool"
Axe.DropItem = game:GetService("ReplicatedStorage"):WaitForChild("ItemDrops"):WaitForChild("Axe")
--[[
ResourceWhitelist is a StrDict where the key represents the ResourceType and the keys values is a table
of allowed resources of that ResourceType.
Including "All" in a ResourceType table allows for all resources of that ResourceType
--]]
Axe.ResourceWhitelist = {
    Lumber = {"All"}
}

return Axe