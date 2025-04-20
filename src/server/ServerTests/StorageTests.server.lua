local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local StorageHandler = require(ServerScriptService.Server.ItemHandlers.StorageHandler)
local instStorageHandler = StorageHandler.new("StorageTestsStorageHandler")

local coalCrate = Workspace:FindFirstChild("Coal Crate")
local storageConfig = {
    MaxStack = 10,
    ItemsConfig = {
        Ore = {"Coal"}
    }
}
local storageDesc = instStorageHandler:AddStorageDevice(storageConfig, coalCrate)
--[[
print(instStorageHandler:ItemFits(storageDesc, "Coal", 10))
print("Get max add before adding item: " .. instStorageHandler:GetMaxAdd("Coal", storageDesc))
instStorageHandler:AddItem(storageDesc, "Coal", 10)
print("Storage contents are: ")
print(instStorageHandler:SeekStorageContents(storageDesc))
print("Item count in storage is: " .. instStorageHandler:GetItemCount("Coal", storageDesc))
print("Get max add after adding item: " .. instStorageHandler:GetMaxAdd("Coal", storageDesc))
instStorageHandler:RemoveItem(storageDesc, "Coal", 10)
print("Item count in storage after remove is: " .. instStorageHandler:GetItemCount("Coal", storageDesc))
--]]
local descByInstance = instStorageHandler:FindStorageByInstance(coalCrate)
print("SD is: " .. descByInstance)