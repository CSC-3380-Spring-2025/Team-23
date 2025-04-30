--[[
This script defines the connections for when a player needs to fire an event for combat
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)


--Events
local DmgTarget: ExtType.Bridge = BridgeNet2.ReferenceBridge("DamageTargetCombat")

--[[
This event connection defines what happens when a player wants to damage a target in combat
--]]
DmgTarget:Connect(function(Player, Damage)
    local character: Model? = Player.Character
    if not character then
        return
    end
    local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then
        return
    end
    humanoid:TakeDamage(Damage)
end)
