--[[
This script handles any and all events relating to buildings
--]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local CollectionService = game:GetService("CollectionService")
local StorageHandler = require(game.ServerScriptService.Server.ItemHandlers.StorageHandler)
--Bridge Events
local GetStorageDescriptor = BridgeNet2.ReferenceBridge("GetStorageDescriptor")
local ReturnStorageDescriptor = BridgeNet2.ReferenceBridge("ReturnStorageDescriptor")

local GetFurnaceDescriptor = BridgeNet2.ReferenceBridge("GetFurnaceDescriptor")
local ReturnFurnaceDescriptor = BridgeNet2.ReferenceBridge("ReturnFurnaceDescriptor")




--Class instances
local StorageHandlerInstance = StorageHandler.new("StorageHandlerInstance")

GetStorageDescriptor:Connect(function(Player, storageInstance)
	if CollectionService:HasTag(storageInstance, "Storage") then
        --set up ingot storage chest using storage handler 
		local ingotStorage: Part | Model ? = nil
		
		local ingotStorageConfig:{{string}}? = {
			MaxStack = 100,
			ItemsConfig = {
				Ingot = {"AllItems"}
			}
		}
		local ingotStorageDescriptor = StorageHandlerInstance:AddStorageDevice(ingotStorageConfig, ingotStorage)
		ReturnStorageDescriptor:Fire(ingotStorageDescriptor)
		return
    end
end)


GetFurnaceDescriptor:Connect(function(Player, FurnaceInstance)
	if CollectionService:HasTag(FurnaceInstance, "Furnace") then
		local furnaceStorageConfig:{{string}}? = {
			MaxStack = 30,
			ItemsConfig = {
				Ore = nil
			}
		}
		if FurnaceInstance:GetAttribute("Ore") == "Coal" then
				furnaceStorageConfig.ItemsConfig.Ore = {"Coal"}
		elseif FurnaceInstance:GetAttribute("Ore") == "Iron" then
				furnaceStorageConfig.ItemsConfig.Ore = {"Iron"}
			--TODO: add for any additional ores implemented in the future	
		else
		warn("Unsupported ore type for furnace: ", FurnaceInstance.Name, ". Check for Ore attribute on furncace")
		return
		end
		local furnaceDescriptor = StorageHandlerInstance:AddStorageDevice(furnaceStorageConfig, FurnaceInstance)
		ReturnFurnaceDescriptor:Fire(furnaceDescriptor)
	end
end)		