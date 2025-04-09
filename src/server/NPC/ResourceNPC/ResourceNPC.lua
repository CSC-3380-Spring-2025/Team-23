--[[
This class functions as a general purpouse manager for Resource NPCs
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local BackpackNPC = require(ServerScriptService.Server.NPC.BackpackNPC)
local ResourceNPC = {}
BackpackNPC:Supersedes(ResourceNPC)


--[[
Constructor for the ResourceNPC class
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
--]]
function ResourceNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	Backpack: {}?
)
	local self = BackpackNPC.new(Name, Rig, Health, SpawnPos, Speed, MaxWeight, MediumWeight, HeavyWeight)
	setmetatable(self, ResourceNPC)
	return self
end

return ResourceNPC
