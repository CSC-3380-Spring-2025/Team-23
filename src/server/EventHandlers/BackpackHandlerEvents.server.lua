--[[
This script handle all events relating to a players backpack
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)

--Instances
local backpackHandlerInst = BackpackHandler.new("BackpackHandlerInstEvents") --backpack handler needs ot be updated to use new properly

local RemovePlayerBackpackItem = BridgeNet2.ReferenceBridge("RemovePlayerBackpackItem")

RemovePlayerBackpackItem:Connect(function(Player, Args)
    backpackHandlerInst:DestroyItem(Player, Args.ItemName, Args.DestroyAmount)
end)
