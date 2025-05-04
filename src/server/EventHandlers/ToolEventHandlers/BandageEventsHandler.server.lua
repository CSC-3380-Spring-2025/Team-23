--[[
This class handles what happens for a bandage tool when an event is needed
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Players = game:GetService("Players")
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

--Events
local HealPlayerEvent = BridgeNet2.ReferenceBridge("BandageHealPlayer")

HealPlayerEvent:Connect(function(Player, HealAmount)
    --Heal player
end)
