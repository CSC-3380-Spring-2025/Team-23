--[[
This script handle all events relating to a players backpack
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Events
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)
local events = ReplicatedStorage.Events
local backpackEvents = events.BackpackEvents
local GetCount = backpackEvents:WaitForChild("GetCount")

--Instances
local backpackHandlerInst = BackpackHandler.new("BackpackHandlerInstEvents") --backpack handler needs ot be updated to use new properly

--Events
local events = ReplicatedStorage.Events
local RemovePlayerBackpackItem = events:WaitForChild("RemovePlayerBackpackItem")

RemovePlayerBackpackItem.OnServerInvoke = function(Player, ItemName, DestroyAmount)
	backpackHandlerInst:DestroyItem(Player, ItemName, DestroyAmount)
    return true--Success
end

local function GetAmountOfItem(Player, ItemName)
    local Contents = BackpackHandler:GetContents(Player)
	local Amount = 0
	for i,v in pairs(Contents) do
		if v.Name == ItemName then
			Amount += v.Stack
		end
	end
	return Amount
end

GetCount.OnServerInvoke = function(Player, ItemName)
    return GetAmountOfItem(Player, ItemName)
end
