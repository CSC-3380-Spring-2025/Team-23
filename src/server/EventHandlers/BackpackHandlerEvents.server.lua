--[[
This script handle all events relating to a players backpack
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)

--Instances
local backpackHandlerInst = BackpackHandler.new("BackpackHandlerInstEvents") --backpack handler needs ot be updated to use new properly

--Events
local events = ReplicatedStorage.Events
local RemovePlayerBackpackItem = events:WaitForChild("RemovePlayerBackpackItem")

RemovePlayerBackpackItem.OnServerInvoke = function(Player, ItemName, DestroyAmount)
	backpackHandlerInst:DestroyItem(Player, ItemName, DestroyAmount)
end
