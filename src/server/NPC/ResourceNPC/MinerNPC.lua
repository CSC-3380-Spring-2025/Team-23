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
	@param DeathHandler (boolean) if set to true enables the death handler for clean up or disables otherwise
	If you do not know what your doing, then you should set this to true.
	@param StatsConfig ({}) determines the config for the NPC's stats. Keys left out follow a default format
	see the table of statsconfig below in the cosntructor for more details in Backpack NPC
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
	ResourceWhiteList: { string }?,
	DeathHandler: any,
	StatsConfig: {}?
)
	local self = ResourceNPC.new(
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
		ResourceWhiteList,
		DeathHandler,
		StatsConfig
	)
	setmetatable(self, MinerNPC)
	self.__NPC:SetAttribute("Type", "Pickaxe")
	CollectionService:AddTag(self.__NPC, "MinerNPC")
	--Give pickaxe
	local tools = ReplicatedStorage.Tools
	local pickaxe = tools.Resource.Pickaxes.Pickaxe
	self:AddPickaxe(pickaxe, 1)
	return self
end

--Vars
local harvestRadious: number = 5 --studs within NPC is allowed to harvest

--[[
Checks if a given resource object is an Ore
	@param ResourceObject (any) any resource object
	@return (boolean) true if Ore or false otherwise
--]]
function MinerNPC:IsOre(ResourceObject): boolean
	return CollectionService:HasTag(ResourceObject, "Ore")
end

--[[
Helper function that plays a given animation for pickaxe use
	@param Animation (Animaiton) animation to play for player
	@param Target (BasePart) the ore target the player is mining to turn to.
	@param NPCCharacter (Model) the NPC's character
	@param Self (any) instance of the class
	@return (AnimationTrack?) the track set up and played
--]]
local function PlayAnimation(Animation: Animation, Target: BasePart, NPCCharacter: Model, Self): AnimationTrack?
	--Turn player to target
	local rootPart: any = NPCCharacter:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local direction = Vector3.new(Target.Position.X, rootPart.Position.Y, Target.Position.Z)
		local endFrame: CFrame = CFrame.lookAt(rootPart.Position, direction)
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
	@param NPCCharacter (Model) the NPC's character
	@return (boolean) true on within distance or false otherwise
--]]
local function WithinDistance(Target: BasePart, MaxDistance: number, NPCCharacter: Model): boolean
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
	@param OreCollectedSoundID (number) the id number of the core collection sound
	@return (boolean) true on last strike false otherwise
--]]
local function HandleIntegrity(Target: BasePart, Effectiveness: number): boolean
	local integrity: number = Target:GetAttribute("Integrity") :: number
	local newIntegrity: number = integrity - Effectiveness
	if newIntegrity <= 0 then
		--Give Coal if last strike
		--Hide ore while sound then destroy to prevent audio issues
		--Target.Transparency = 1
		local collectSoundId = Target:GetAttribute("CollectSoundID")
		if collectSoundId then
			local sound: Sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://" .. collectSoundId
			sound.Parent = Target
			sound:Play()
			--Destroy to prevent memory leaks
			sound.Ended:Once(function()
				sound:Destroy()
			end)
		end
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
local function StrikeSound(SoundId: number, Target: BasePart): ()
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
Helper functiont that handles the count attribute of an item during pick up
	and also spawns the item on the ground if not able to fill backpack with it
	@param Item (any) any item to check for
	@param Self (any) the instance fo the class
	@return (number) the count attributes remaining number of the item
	returns -1 on error
--]]
local function HandleCount(Item: any, Self: any): number
	local count: number = Item:GetAttribute("Count")
	if not count then
		warn('NPC "' .. Self.Name .. '" Attempted to harvest an object that lacks a Count attribute')
		return -1
	end
	local maxCount: number = Self:GetMaxCollect(Item.Name)
	if count <= maxCount then
		--Safe to put full amount in backpack
		Self:CollectItem(Item.Name, count)
		Item:SetAttribute("Count", 0)
		Item:Destroy()
		return 0
	else
		--Not enough space to put full thing in backpack
		Self:CollectItem(Item.Name, maxCount)
		local remainingCount: number = count - maxCount
		Item:SetAttribute("Count", remainingCount)
		--Drop item on ground since collected but full
		--Add DropItem tag
		CollectionService:AddTag(Item, "DropItem")
		MinerNPCUtils:DropItem(Item, Self.__NPC) --At some point add fall back to check for drop error
		return remainingCount
	end
end

--[[
Determines what happens when a ore is "ripe" and ready to be harvested
	used on last strike of the ore
	@param ResourceObject (any) any object thats a resource
	@param Self (any) any instance of the class
--]]
local function Harvest(ResourceObject: any, Self: any): ()
	--Give NPC the ore
	local resourceName: string = ResourceObject.Name
	if not Self:CheckItemWhitelist(resourceName) then
		--not whitelisted resource item
		warn('NPC "' .. Self.Name('" Attempted to harvest object that is not whitelisted'))
		return
	end
	HandleCount(ResourceObject, Self)
end

--[[
Helper function that traverses the NPC to the given resource
	@param Self (any) the instance of the class
	@param Resource (any) any resource object
	@return (boolean) true on success or false otherwise
--]]
local function TraverseToResource(Self: any, Resource: any): boolean
	local success: boolean = Self:SetWaypoint(Resource.Position)
	if success then
		Self:TraverseWaypoints()
		--Wait for traverse
		while Self:IsTraversing() do
			task.wait(1)
		end
	end
	return success
end

--[[
Handles any given resource 
	@param Target (any) any given target
	@param Tool (Tool) the tool being used
	@param Self (any) an instance of the object
--]]
local function HandleResource(Target: any, Tool: Tool, Self: any): boolean
	local oreInfo: ModuleScript = Self:GetItemInfo(Target:GetAttribute("Resource"))
	local strikeSoundId = Target:GetAttribute("StrikeSoundID")
	if strikeSoundId then
		StrikeSound(strikeSoundId, Target)
	end
	local finished: boolean = HandleIntegrity(Target, Tool:GetAttribute("Effectiveness") :: number)
	return finished
end

--HArvestResource but without the task.spawn
local function HarvestResourceHelp(ResourceObject, Self)
	if not Self:IsResource(ResourceObject) then
		warn('NPC "' .. Self.Name .. '" Attempted to harvest object that is not a resource')
		return false
	end
	if not Self:IsOre(ResourceObject) then
		warn('Miner NPC "' .. Self.Name .. "Attempted to harvest object that is not a Ore")
		return false
	end
	if not Self:WhitelistedResource(ResourceObject.Name) then
		warn('Miner NPC "' .. Self.Name .. "Attempted to harvest resource that is not whitelisted")
		return false
	end
	if not Self.__Pickaxe then
		warn('Miner NPC "' .. Self.Name .. "Attempted to harvest a resource but has no pickaxe")
		return false
	end
	if not ResourceObject:GetAttribute("Integrity") then
		warn('Miner NPC "' .. Self.Name .. "Attempted to harvest a resource that has no integrity set")
		return false
	end

	local target: any = ResourceObject

	--Equip tool
	local tool: Tool = Self.__Pickaxe.DropItem
	local animations: Folder? = tool:FindFirstChild("Animations") :: Folder?
	if not animations then
		warn('Tool "' .. tool.Name .. '" missing Animations Folder')
		return false
	end
	local swingAnimation: Animation? = animations:FindFirstChild("Activate") :: Animation?
	if not swingAnimation then
		warn('Tool "' .. tool.Name .. '" missing Activate animation')
		return false
	end
	if not tool:GetAttribute("Effectiveness") then
		warn('Miner NPC "' .. Self.Name .. "Attempted to use pickaxe with no attribute Effectiveness")
		return false
	end

	--Check NPC distance
	if not WithinDistance(target, harvestRadious, Self.__NPC) then
		--Go to resource
		if not TraverseToResource(Self, ResourceObject) then
			return false
		end
	end

	if CollectionService:HasTag(target, "DropItem") then
		--Already mined and on ground
		Harvest(ResourceObject, Self)
		return true
	end

	Self:EquipTool(tool.Name) --Unequip after use
	local animTrack: AnimationTrack? = PlayAnimation(swingAnimation, target, Self.__NPC, Self)
	if not animTrack then
		return false
	end

	--Keep calling the animation
	local finished: boolean = false
	animTrack.Stopped:Connect(function()
		--Determine behaivore by ore type
		finished = HandleResource(target, tool, Self)
		if not finished then
			animTrack:Play() --Repeat animation because not finished
		else
			return --Exit loop
		end
	end)

	while not finished do
		task.wait(2) --wait for process to finish
	end

	--Finished so clean up
	Harvest(ResourceObject, Self)

	Self:UnequipTool()

	return true
end

--[[
Used to harvest a ore item target in workspace
	@param ResourceItem (any) any item in workspace that may be considerd a resource item
	@return (boolean) true on success or false otherwise
--]]
function MinerNPC:HarvestResource(ResourceObject: any): ()
	self.__HarvestTask = task.spawn(function()
		HarvestResourceHelp(ResourceObject, self)
	end)
	self.__Tasks["HarvestTask"] = self.__HarvestTask
	self.__ActionTasks["HarvestTask"] = self.__HarvestTask--Save to be canceld by player
end

--[[
Adds a given pickaxe tool to the Miner NPC
	@param Tool (Tool) the tool to add for the NPC
	@param Amount (number) the number of the pickaxe to add to the miner NPC
--]]
function MinerNPC:AddPickaxe(Tool: Tool, Amount: number): ()
	self:AddTool(Tool, 1)
	self.__Pickaxe = self.__Backpack[Tool.Name]
end

--[[
Checks if a Miner NPC has a pickaxe
	@return (boolean) true if it has one or false otherwise
--]]
function MinerNPC:HasPickaxe(): boolean
	if not self.__Pickaxe then
		return false
	else
		return true
	end
end

local function SortByDistance(FirstOreStruct, SecondOreStruct)
	if FirstOreStruct.Distance < SecondOreStruct.Distance then
		return false
	else
		return true
	end
end

--[[
Helper function that finds the nearest ore
--]]
local function GetNearestOre(Self): BasePart?
	--Cycle through all ore tags and find the nearest whitelisted one
	local ores = CollectionService:GetTagged("Ore")
	local whitelistedOre = {}
	local NPCPos = Self.__RootPart.Position
	for _, ore in pairs(ores) do
		local oreType = ore:GetAttribute("Ore")
		if not oreType or not ore:IsDescendantOf(Workspace) then
			continue --Missing ore attribute or not in workspace
		end
		if Self:WhitelistedResource(oreType) then
			local oreStruct = {
				Ore = ore,
				Distance = (NPCPos - ore.Position).Magnitude,
			}
			table.insert(whitelistedOre, oreStruct)
		end
	end
	--Sort values
	table.sort(whitelistedOre, SortByDistance)
	local chosenOre = table.remove(whitelistedOre)
	if chosenOre == nil then
		return nil --Nothing found that can be harvested
	end
	return chosenOre.Ore
end

--[[
Finds the nearest whitelisted resource to harvest automaticly
--]]
function MinerNPC:HarvestNearestResource()
	--Harvest given resource
	self.__HarvestTask = task.spawn(function()
		local chosenOre = GetNearestOre(self)
		if chosenOre then
			HarvestResourceHelp(chosenOre, self)
		end
	end)
	self.__Tasks["HarvestTask"] = self.__HarvestTask
end

--[[
Tells the NPC to keep harvesting the nearest resource and then
	loads it into the asigned chest the player chooses
--]]
function MinerNPC:AutoHarvest()
	--Create cycle of going to get resource, deliver it to the assigned storage, and then repeat
	self.__HarvestTask = task.spawn(function()
		while true do
			--Harvest resource until full
			local chosenOre = GetNearestOre(self)
			while chosenOre and self:ValidItemCollection(chosenOre.Name, 1) do
				--Atleast 1 of this ore will fit
				HarvestResourceHelp(chosenOre, self)
				chosenOre = GetNearestOre(self)
			end
			--Return home since finished
			self:ReturnHome()
			while self:IsTraversing() do
				task.wait(2)
			end
			--Empty into storage
			self:EmptyInventoryToStorage(self.__AssignedStorage)
		end
	end)
	self.__Tasks["HarvestTask"] = self.__HarvestTask
	self.__ActionTasks["HarvestTask"] =self.__HarvestTask--Save to be canceld by player
end

--Cancels any harvest task going on
function MinerNPC:CancelHarvest()
	if self.__HarvestTask then
		task.cancel(self.__HarvestTask)
	end
end

return MinerNPC
