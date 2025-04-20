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
instStorageHandler:AddItem(storageDesc, "Coal", 10)
print("Item count in storage is: " .. instStorageHandler:GetItemCount("Coal", storageDesc))