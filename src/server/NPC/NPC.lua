--[[
This class functions as a general purpouse manager for creating non dialogue NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
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
    --Set up NPC body
    self.__NPC = Rig:Clone()
    self.__NPC.Parent = workspace
    local rootPart = self.__NPC:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(SpawnPos)
    end
    self.__RootPart = rootPart
    self.__Humanoid = self.__NPC:FindFirstChild("Humanoid")
    self.__NPC.Name = Name
    self.__Health = Health
    if RewardValue < 0  then
        error("RewardValue may not be less than 0")
    end
    self.__RewardValue = RewardValue or 0
    --Add tools to npc here eventually
    --Spawn NPC here eventually at SpawnPos
    local waypoints: {{Vector3}} = {}
    self.__Waypoints = waypoints
    return self
end

--[[
Sets an NPC to follow a given opject
    The object may be any object including a player or another NPC etc.
    Creating a waypoint will undo a follow command.
--]]
function NPC:Follow(Object) : boolean
    return false
end

--[[
Cancels a Follow command
--]]
function NPC:Unfollow(Object) : boolean
    return false
end

--[[
Sets a singular waypoint and cancels any linked waypoints
    SetWaypoint is only intended for a singular waypoint and does not allow for a chain of waypoints
    However SetLinkedWaypoint may extend an already existing way point set by SetWaypoint
    @param
--]]
function NPC:SetWaypoint(Position) : boolean
    local path = PathfindingService:CreatePath()
    --Wrap in pcall to detect a fail
    local success, errorMessage = pcall(function()
        path:ComputeAsync(self.__RootPart.Position, Position)
    end)

    if success then
        table.insert(self.__Waypoints, path:GetWaypoints()) --Insert at end of table
        return true
    else
        warn("NPC \"" .. self.__NPC.Name .. "\" failed to find a path")
        return false
    end
    return false
end

--[[
Extends an existing waypoint, or extends the waypoint previously set in a chain
    allows for long term movement plans
--]]
function NPC:SetLinkedWaypoint(Position) : boolean
    return false
end

--[[
Tells the NPC to begin traversing the current set of waypoints
--]]
function NPC:TraverseWaypoints()
    if self.__Waypoints == nil then
        return
    end
    for _, set in pairs(self.__Waypoints) do
        if set == nil then
            return
        end
        for _, waypoint in pairs(set) do
            if waypoint == nil then
                return
            end
            self.__Humanoid:MoveTo(waypoint.Position)
            self.__Humanoid.MoveToFinished:Wait() --Handle cases where they get stuck before it ends eventually else this will make them stuck
        end
        table.remove(self.__Waypoints, 1)--Remove set from front of table like que once completed
    end
end

--[[
Cancels waypoints of any type
    Sends back to home point if set
--]]
function NPC:CancelWaypoints() : boolean
    return false
end

--[[
Sets the exact position an NPC will attempt to return to when there are no more pathingfinding commands.
--]]
function NPC:SetHomePoint(HomePointPosition)
    
end

--[[
Enables homepoint functionality
--]]
function NPC:EnableHomePoint()
    
end

--[[
Disables HomePoint functionality
--]]
function NPC:DisableHomePoint()
    
end

--[[
Drops the reward amount in a money bag when an NPC is killed
--]]
function NPC:DropReward()
    --May NOT take ANY parameters. Must use instance variables by using self.__RewardValue
    error("Must Implement DropReward!") --Remove this to start
end

return NPC