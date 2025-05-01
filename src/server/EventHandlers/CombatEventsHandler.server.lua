--[[
This script defines the connections for when a player needs to fire an event for combat
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)


--Events
local DmgTarget: ExtType.Bridge = BridgeNet2.ReferenceBridge("DamageTargetCombat")

--[[
This event connection defines what happens when a player wants to damage a target in combat
--]]
DmgTarget:Connect(function(Player, Args)
    local humanoid: Humanoid = Args.DmgHum
    local damage: number = Args.Damage
    humanoid:TakeDamage(damage)
end)
