--[[
This class functions as a general purpouse manager for creating non dialogue NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local NPC = require(ServerScriptService.Server.NPC.NPC)
local ResourceNPC = {}
NPC:Supersedes(ResourceNPC)

function ResourceNPC.new(Name: string, Rig: Model, Health: number, RewardValue: number, Tools: Tool, SpawnPos: Vector3)
    local self = NPC.new(Name, Rig, Health, RewardValue, Tools, SpawnPos)
    setmetatable(self, ResourceNPC)
    return self
end

return ResourceNPC