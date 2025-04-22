--[[
This class functions as a general purpouse manager for Resource NPCs
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ToolNPC = require(ServerScriptService.Server.NPC.ToolNPC)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local ResourceNPC = {}
ToolNPC:Supersedes(ResourceNPC)

--[[
Constructor for the ResourceNPC class
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxStack (number) the number of stacks allowed for the backpack
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
    @param WhiteList ({string}) table of item names that may be added
    @param EncumbranceSpeed ({[Light, Medium, Heavy] = number}) a table of keys defined
    as Light, Medium, Heavy that have a value pair indicating the speed to go at each Encumbrance level
    if not provided then Light = -1/3speed, Heavy = -2/3 speed
	@param DeathHandler (boolean) if set to true enables the death handler for clean up or disables otherwise
	If you do not know what your doing, then you should set this to true.
	@param StatsConfig ({}) determines the config for the NPC's stats. Keys left out follow a default format
	see the table of statsconfig below in the cosntructor for more details in Backpack NPC
--]]
function ResourceNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxStack: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	WhiteList: { string },
	Backpack: {}?,
	EncumbranceSpeed: {}?,
	ResourceWhiteList: { string }?,
	DeathHandler: any,
	StatsConfig: {}?
)
	local self = ToolNPC.new(
		Name,
		Rig,
		Health,
		SpawnPos,
		Speed,
		MaxStack,
		MaxWeight,
		MediumWeight,
		HeavyWeight,
		WhiteList,
		Backpack,
		EncumbranceSpeed,
		DeathHandler,
		StatsConfig
	)
	setmetatable(self, ResourceNPC)
	self.__ResourceWhiteList = ResourceWhiteList or {}
	return self
end

--[[
Used to harvest a resource item target in workspace
	@param ResourceItem (any) any item in workspace that may be considerd a resource
	@return (boolean) true on success or false otherwise
--]]
function ResourceNPC:HarvestResource(ResourceItem: any): boolean
	AbstractInterface:AbstractError("HarvestResource", "ResourceNPC")
	return false
end

--[[
Used to determine if an item is considerd a resource
	To be considerd a resource the item must have the resource tag
	@param Object (any) any object
	@return (boolean) true if resource or false otherwise
--]]
function ResourceNPC:IsResource(Object: any): boolean
	return CollectionService:HasTag(Object, "Resource")
end

--[[
Determines if a resource is whitelisted by name
	@param ResourceName (string) the name of resource type to check for
	@return (boolean) true on Whitelisted or false otherwise
--]]
function ResourceNPC:WhitelistedResource(ResourceName: string): boolean
	if table.find(self.__ResourceWhiteList, ResourceName) then
		return true
	else
		return false
	end
end

return ResourceNPC
