--[[
This script allows for configurating all players from a client side view.
Any changes here will not affect the server view and thus not other players.
--]]
local Players: Players = game:GetService("Players")
local CollectionService: CollectionService = game:GetService("CollectionService")
local localPlayer: Player = Players.LocalPlayer

--[[
Adds all tags important to the local player of another player when they spawn
    @param Character (Model) the players character
--]]
local function AddPlayerCharTags(Character: Model) : ()
    CollectionService:AddTag(Character, "EnemyPlayer")
end

--Check for when a player joins
Players.PlayerAdded:Connect(function(Player: Player)
    --ignore local player
    if Player == localPlayer then
        return
    end
    --Check for when a player spawns
    Player.CharacterAdded:Connect(function(Character: Model)
        --Handle other players character
        AddPlayerCharTags(Character)
    end)
end)
