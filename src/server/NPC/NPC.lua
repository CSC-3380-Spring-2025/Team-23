--[[
This class functions as a general purpouse manager for creating non dialogue NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPC = {}
Object:Supersedes(NPC)


--[[
Constructor that creates an NPC
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param RewardValue (number) the amount of gold droped for a player when NPC dies.
    @param Tools (undetermined)
    @param SpawnPos (Vector3) position to spawn NPC at
--]]
function NPC.new(Name, Rig, Health, RewardValue, Tools, SpawnPos)
    local self = Object.new(Name)
    setmetatable(self, NPC)
    self.__Rig = Rig --Eventually make copy instead here
    self.__Health = Health
    if RewardValue < 0  then
        error("RewardValue may not be less than 0")
    end
    self.__RewardValue = RewardValue or 0
    --Add tools to npc here eventually
    --Spawn NPC here eventually at SpawnPos
    return self
end

--[[
Drops the reward amount in a money bag when an NPC is killed
--]]
function NPC:DropReward()
    --May NOT take ANY parameters. Must use instance variables by using self.__RewardValue
    error("Must Implement DropReward!") --Remove this to start
end

return NPC