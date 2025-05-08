--[[
This script handles any and all events relating to stats
--]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
--Events
local StatsDmgPlayer = BridgeNet2.ReferenceBridge("StatsDmgPlayer")

StatsDmgPlayer:Connect(function(Player, Damage)
    local character: Model? = Player.Character
    if not character then
        return
    end
    local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then
        return
    end
    --Damage player
    humanoid:TakeDamage(Damage)
end)
