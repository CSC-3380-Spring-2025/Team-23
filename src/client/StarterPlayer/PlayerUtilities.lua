--[[
This class is used to manipulate aspects of the player like who they can target
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local PlayerUtilities = {}
Object:Supersedes(PlayerUtilities)

--Vars
local canAggro: {string} = {"EnemyNPC", "EnemyPlayer"} --Defines the list of tags that a player is allowed to target

--[[
The constructor for the PlayerUtilities class
    @param Name (string) the name of this ObjectInstance
    @param AggroList ({string}) a table of strings that represent the
    whitelsited tags that a player is allowed to aggro
--]]
function PlayerUtilities.new(Name: string, AggroList: {string}?) : ExtType.ObjectInstance
    local self = Object.new(Name)
	setmetatable(self, PlayerUtilities)
    if AggroList then
        --Add list to canAggro
        for _, tag in pairs(AggroList) do
            table.insert(canAggro, tag)
        end
    end
	return self
end

--[[
Determines if a player can attack a given instance
    @param Character (Model) any given character model
    @return (boolean) true on success or false otherwise
--]]
function PlayerUtilities:CanAttack(Character: Model) : boolean
    for _, tag in pairs(canAggro) do
        if CollectionService:HasTag(Character, tag) then
            return true --Found a tag that player can aggro
        end
    end
    return false--Could not find a viable tag
end

return PlayerUtilities