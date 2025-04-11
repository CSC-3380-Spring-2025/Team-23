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
local TweenService = game:GetService("TweenService")
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
	EncumbranceSpeed: {}?,
	Pickaxe: Tool
)
	local self = ResourceNPC.new(Name, Rig, Health, SpawnPos, Speed, MaxStack, MaxWeight, MediumWeight, HeavyWeight, WhiteList, Backpack, EncumbranceSpeed)
	setmetatable(self, ResourceNPC)
	self.__Pickaxe = Pickaxe or nil
	return self
end

--Vars
local harvestRadious = 8 --studs within NPC is allowed to harvest

--[[
Checks if a given resource object is an Ore
	@param ResourceObject (any) any resource object
	@return (boolean) true if Ore or false otherwise
--]]
function MinerNPC:IsOre(ResourceObject) : boolean
	return CollectionService:HasTag(ResourceObject, "Ore")
end

--[[
Helper function that plays a given animation for pickaxe use
	@param Animation (Animaiton) animation to play for player
	@param Target (BasePart) the ore target the player is mining to turn to.
	@return (AnimationTrack) the track set up and played
--]]
local function PlayAnimation(Animation: Animation, Target: BasePart, NPCCharacter: Model, Self) : AnimationTrack?
	--Turn player to target
	local rootPart: any = NPCCharacter:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local endFrame: CFrame = CFrame.lookAt(rootPart.Position, Target.Position)
		local tweenInfo: TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween: Tween = TweenService:Create(rootPart, tweenInfo, { CFrame = endFrame })
		tween:Play()
	end

	local animTrack: AnimationTrack = Self:LoadAnimation(Animation)
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack:Play()

	return animTrack
end

--[[
Checks if NPC is within Radius of object
	@param Target (BasePart) ore part to check for within distance
	@param MaxDistance (number) max distance to check for
	@return (boolean) true on within distance or false otherwise
--]]
local function WithinDistance(Target: BasePart, MaxDistance: number, NPCCharacter: Model) : boolean
	--Check target distance
	local rootPart: any = NPCCharacter:FindFirstChild("HumanoidRootPart")
	if rootPart then
		if (rootPart.Position - Target.Position).Magnitude <= MaxDistance then
			return true
		end
	end

	return false
end

--[[
Decreases integrity and gives reward on last strike
	@param Target (BasePart) ore part that player hits
	@param Effectiveness (number) the pickaxes Effectiveness
	@return (boolean) true on last strike fals eotherwise
--]]
local function HandleIntegrity(Target: BasePart, Effectiveness: number, OreCollectedSoundID: number) : boolean
	local integrity: number = Target:GetAttribute("Integrity")
	local newIntegrity: number = integrity - Effectiveness
	if newIntegrity <= 0 then
		--Give Coal if last strike
        --Hide ore while sound then destroy to prevent audio issues
		Target.Transparency = 1
		local sound: Sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. OreCollectedSoundID
		sound.Parent = Target
		sound:Play()
		print("Played audio!")
		--Destroy to prevent memory leaks
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		return true
	else
		--Lower integrity
		Target:SetAttribute("Integrity", newIntegrity)
		return false
	end
end

--[[
Helper function that plays on strike
	@param SoundId (number) id of sound
	@param Target (BasePart) ore part top do sound for
--]]
local function StrikeSound(SoundId: number, Target: BasePart) : ()
	local sound: Sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. SoundId
	sound.Parent = Target
	sound:Play()
	print("Played audio!")
	--Destroy to prevent memory leaks
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end


--[[
Helper function that determiens behaivor of iron
	@param Target (BasePart) the ore part being hit
	@param Positon (Vector3) position of target
	@param Effectiveness (number) damage done to target
	@return (boolean) true if finished false otherwise
--]]
local function Iron(Target: BasePart, Position: Vector3, Effectiveness: number) : boolean
	StrikeSound(7650220708, Target)
	local finished: boolean = HandleIntegrity(Target, Effectiveness, 3908308607)
	if finished then
		
		return true
	end
	return false --Not finished off
end

--[[
Helper function that determiens behaivor of Coal
	@param Target (BasePart) the ore part being hit
	@param Positon (Vector3) position of target
	@param Effectiveness (number) damage done to target
	@return (boolean) true if finished false otherwise
--]]
local function Coal(Target: BasePart, Position: Vector3, Effectiveness: number) : boolean
	StrikeSound(7650220708, Target)
	local finished: boolean = HandleIntegrity(Target, Effectiveness, 3908308607)
	if finished then
		return true
	end
	return false
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

local function TraverseToResource(Self, Resource)
	local success = Self:SetWaypoint(Resource.Position)
	if success then
		Self:TraverseWaypoints()
	end
	return success
end

--[[
Used to harvest a ore item target in workspace
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
		return false
	end
	if not self:WhitelistedResource(ResourceObject.Name) then
		warn('Miner NPC "' .. self.Name .. "Attempted to harvest resource that is not whitelisted")
		return false
	end
	if not self.__Pickaxe then
		warn('Miner NPC "' .. self.Name .. "Attempted to harvest a resource but has no pickaxe")
		return false
	end

	local target = ResourceObject
	local position: Vector3 = ResourceObject.Position

	--Check NPC distance
	if not WithinDistance(target, harvestRadious, self.__NPC) then
		--Go to resource
		if not TraverseToResource(self, ResourceObject) then
			return false
		end
	end

	--Equip tool
	local tool = self.__Pickaxe.DropItem
	local animations = tool:FindFirstChild("Animations")
	if not animations then
		warn('Tool "' .. tool.Name .. '" missing Animations Folder')
		return false
	end
	local swingAnimation = animations:FindFirstChild("Activate")
	if not swingAnimation then
		warn('Tool "' .. tool.Name .. '" missing Activate animation')
		return false
	end

	self:EquipTool(tool.Name) --Unequip after use
	local animTrack: AnimationTrack? = PlayAnimation(swingAnimation, target, self.__NPC, self)
	if not animTrack then
		return false
	end

	--Keep calling the animation
	local finished = false
	animTrack.Stopped:Connect(function()
		--Determine behaivore by ore type
		if CollectionService:HasTag(target, "Iron") then --Iron
			Iron(target, position, self.__Effectiveness)
		elseif CollectionService:HasTag(target, "Coal") then --Coal
			Coal(target, position, self.__Effectiveness)
		end
		if not finished then
			animTrack:Play() --Repeat animation because not finished
		end
	end)

	while not finished do
		task.wait(2) --wait for process to finish
	end

	--Finished so clean up
	Harvest(ResourceObject, self)

	self:UnequipTool()

	return true
end

function MinerNPC:AddPickaxe(Tool, Amount)
	self:AddTool(Tool, 1)
	self.__Pickaxe = self.__Backpack[Tool.Name]
end

function MinerNPC:HasPickaxe() : boolean
	if not self.__Pickaxe then
		return false
	else
		return true
	end
end

return MinerNPC