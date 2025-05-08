
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local GoldObject = require(script.Parent.Parent.Currency.Gold)
local dataEvents: Folder = ReplicatedStorage.Events.DataEvents
local GetGoldStat: RemoteFunction = dataEvents:WaitForChild("GetGold") :: RemoteFunction

local goldInterface: ExtType.ObjectInstance = GoldObject.new("EventsHandler")

GetGoldStat.OnServerInvoke = function(Player: Player) : number
    return goldInterface:GetAmount(Player)
end
