--[[
This class functions as a general purpouse manager for creating miner NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ResourceNPC = require(ServerScriptService.Server.NPC.ResourceNPC.ResourceNPC)
local NPCUtils = require(ServerScriptService.Server.NPC.NPCUtils)
local MinerNPCUtils = NPCUtils.new("MinerNPCUtils")
local MinerNPC = {}
ResourceNPC:Supersedes(MinerNPC)

--[[
Constructor for the MinerNPC class
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
--]]
function MinerNPC.new(
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
	EncumbranceSpeed: {}?
)
	local self = ResourceNPC.new(Name, Rig, Health, SpawnPos, Speed, MaxStack, MaxWeight, MediumWeight, HeavyWeight, WhiteList, Backpack, EncumbranceSpeed)
	setmetatable(self, ResourceNPC)
	return self
end

--[[
Checks if a given resource object is an Ore
	@param ResourceObject (any) any resource object
	@return (boolean) true if Ore or false otherwise
--]]
function MinerNPC:IsOre(ResourceObject) : boolean
	return CollectionService:HasTag(ResourceObject, "Ore")
end

--[[
Helper functiont that handles the count attribute of an item during pick up
	and also spawns the item on the ground if not able to fill backpack with it
	@return (number) the count attributes remaining number of the item
	returns -1 on error
--]]
local function HandleCount(Item, Self) : ()
	local count = Item:GetAttribute("Count")
	if not count then
		warn('NPC "' .. Self.Name .. '" Attempted to harvest an object that lacks a Count attribute')
		return -1
	end
	local maxCount = Self:GetMaxCollect(Item.Name)
	if count <= maxCount then
		--Safe to put full amount in backpack
		Self:CollectItem(Item.Name, count)
		Item:SetAttribute("Count", 0)
		return 0
	else
		--Not enough space to put full thing in backpack
		Self:CollectItem(Item.Name, maxCount)
		local remainingCount = count - maxCount
		Item:SetAttribute("Count", remainingCount)
		--Drop item on ground since collected but full
		--Add DropItem tag
		CollectionService:AddTag(Item, "DropItem")
		MinerNPCUtils:DropItem(Item, Self.__NPC) --At some point add fall back to check for drop error
		return remainingCount
	end
end

--[[
Determiens what happens when a ore is "ripe" and ready to be harvested
	used on last strike of the ore
--]]
local function Harvest(ResourceObject, Self) : ()
	--Give NPC the ore
	local resourceName = ResourceObject.Name
	if not Self:CheckItemWhitelist(resourceName) then
		--not whitelisted resource item
		warn('NPC "'.. Self.Name '" Attempted to harvest object that is not whitelisted')
		return
	end 
	HandleCount(ResourceObject, Self)
end

--[[
Used to harvest a resource item target in workspace
	Item must be at a stage that is ready to be picked up and have attribute count set
	Objects to be harvested must have the name of the ItemDrop to be picked up
	@param ResourceItem (any) any item in workspace that may be considerd a resource item
	@return (boolean) true on success or false otherwise
--]]
function MinerNPC:HarvestResource(ResourceObject: any) : boolean
	if not self:IsResource(ResourceObject) then
		warn( 'NPC "'.. self.Name '" Attempted to harvest object that is not a resource')
		return false
	end
	if not self:IsOre(ResourceObject) then
		warn('Miner NPC "' .. self.Name .. "Attempted to harvest object that is not a Ore")
	end
	return true
end

return MinerNPC