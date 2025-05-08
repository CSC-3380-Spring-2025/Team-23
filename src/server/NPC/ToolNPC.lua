--[[
This class functions as a general purpouse manager for NPC's that use tools
Most importantly this class provides functions specific to the use of tools by NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BackpackNPC = require(ServerScriptService.Server.NPC.BackpackNPC)
local ServerMutexSeq = require(ServerScriptService.Server.ServerUtilities.ServerMutexSeq)
local ToolNPC = {}
BackpackNPC:Supersedes(ToolNPC)

--[[
Constructor for the ToolNPC class
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
function ToolNPC.new(
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
	DeathHandler: any,
	StatsConfig: {}?
)
	local self = BackpackNPC.new(
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
	setmetatable(self, ToolNPC)
	self.__EquippedTool = nil --The tool equipped by the NPC
	return self
end

--[[
Returns the real tool in the players backpack
    @param ToolName (string) the name of the tool to find in backpack
    @param Self (any) the instance of the class
	@return (Tool?) the tool if found or nil otherwise
--]]
local function FindPhysTool(ToolName: string, Self: any): Tool?
	local tool: any = Self.__Backpack[ToolName]
	if tool then
		return tool.DropItem
	end
	return nil
end

--[[
Equips a tool for the NPC and unequips any tools currently open
    Tool must already be present in NPC's backpack
    @param ToolName (string) the name of the tool to Equip
	@return (boolean) true on success or false otherwise
--]]
function ToolNPC:EquipTool(ToolName: string): boolean
	local tool: Tool? = FindPhysTool(ToolName, self)
	if not tool then
		warn('Tool "' .. ToolName .. '" missing from backpack of NPC "' .. self.Name .. '." Unable to equip')
		return false
	end
	tool.Parent = self.__NPC --Parent to NPC to make visible
	self.__EquippedTool = tool
	return true
end

--[[
Unequips the current tool held by the NPC
--]]
function ToolNPC:UnequipTool(): ()
	if self.__EquippedTool == nil then
		warn('Attempted to unequip tool from NPC "' .. self.Name .. '" but no tool equipped')
		return
	end
	self.__EquippedTool.Parent = nil
	self.__EquippedTool = nil
end

--[[
Prepares the Motor6d of the tool for the NPC
	@param Tool (Tool) the tool of the Motor6d
	@param Self (ExtType.ObjectInstance) an instance of the class
	@return (boolean) true on success or false otherwise
--]]
local function PrepToolMotor6d(Tool: Tool, Self: ExtType.ObjectInstance): boolean
	local animations: Folder? = Tool:FindFirstChild("Animations") :: Folder?
	if animations == nil then
		warn('Tool "' .. Tool.Name .. '" missing Animations folder')
		return false
	end
	local motor6d: Motor6D? = animations:FindFirstChild("Motor6d") :: Motor6D?
	if motor6d == nil then
		warn('Tool "' .. Tool.Name .. '" missing Motor6d in Animations folder')
		return false
	end
	local motorParent1: any? = Tool:FindFirstChild("MotorParent1", true)
	if motorParent1 == nil then
		warn('Tool "' .. Tool.Name .. '" found no tool part with name MotorParent1 for Motor6d')
		return false
	end
	local rightHand: BasePart? = Self.__NPC:FindFirstChild("RightHand")

	motor6d.Part1 = motorParent1
	motor6d.Part0 = rightHand

	return true --Success
end

--[[
Returns a clone of a tool
    @param Tool (Tool) the tool to copy
    @return (Tool) a tool clone
--]]
local function CloneTool(Tool: Tool)
	local toolClone: Tool = Tool:Clone()
	--Copy attributes over
	for atrName, value in pairs(Tool:GetAttributes()) do
		toolClone:SetAttribute(atrName, value)
	end

	--Copy tags Over
	for _, tag in pairs(CollectionService:GetTags(Tool)) do
		CollectionService:AddTag(toolClone, tag)
	end
	return toolClone
end

--[[
Prepares all animations of a tool in the Animations folder by loading them and storing them to a dictionary of the NPC
	@param ToolRef ({[string]: any}) a refrence to the toolitem in the backpack
	@param Self ({[string]: any}) the instance of the coass
--]]
local function PrepAnims(ToolRef: {[string]: any}, Self: {[string]: any}) : ()
	local physTool: Tool = ToolRef.DropItem
	local animations: Folder? = physTool:FindFirstChild("Animations") :: Folder?
	if not animations then
		return
	end
	for _, animation in pairs(animations:GetChildren()) do
		if animation:IsA("Animation") then
			Self.__Animations[animation.Name] = Self:LoadAnimation(animation)
		end
	end
end

--[[
Sets up the needed cool down info needed for an NPC tool
	@param CoolDownTime (number) the time in seconds the weapon takes to cool down
	@param ToolRef (ExtType.StrDict) the StrDict of the tool in the NPCs backpack
	@param ActiveAnim (AnimationTrack) the main track of the tool that is played when activated
--]]
local function PrepCoolDown(CoolDownTime: number, ToolRef: ExtType.StrDict, ActiveAnim: AnimationTrack, Self: ExtType.ObjectInstance) : ()
	local animationTime: number = ActiveAnim.Length
	--Make sure cool down is not less than the main animation
	if animationTime <= CoolDownTime then
		ToolRef.CoolDownTime = CoolDownTime
	else
		ToolRef.CoolDownTime = animationTime
	end
	ToolRef.__OnCoolDown = false--Indicates if the tool is on cool down or not
	ToolRef.__CoolDownLockKey = "SwordsmanCoolDown" .. Self:GetItemCount(ToolRef.ItemName)
	ToolRef.__CoolDownLock = ServerMutexSeq.new(ToolRef.__CoolDownLockKey) --used to safely access OnCoolDown
end

--[[
Puts a given tool on cool down
	If tool is already on cool down then this may lead to undefined behaivore
	@param ToolName (string) the name of the tool to cool down
--]]
function ToolNPC:CoolDownTool(ToolName: string) : ()
	local toolRef: ExtType.StrDict = self.__Backpack[ToolName]
	if not toolRef then
		warn('Attempt to use CoolDownTool but ToolName "' .. ToolName .. '" was not in backpack of NPC')
		return--vaciously false
	end
	if not toolRef.__CoolDownLockKey then
		return--Tool has no cooldown
	end
	self.__Tasks["CoolDown"] = task.spawn(function()
		toolRef.__CoolDownLock:Lock()
		toolRef.OnCoolDown = true
		toolRef.__CoolDownLock:Unlock()
		task.wait(toolRef.CoolDownTime)
		toolRef.__CoolDownLock:Lock()
		toolRef.OnCoolDown = false
		toolRef.__CoolDownLock:Unlock()
	end)
end

--[[
This function determines if a tool in the NPCs backpack is on cool down
	@param ToolName (string) the name of the tool in the NPCs backpack
--]]
function ToolNPC:ToolOnCoolDown(ToolName: string) : boolean
	local toolRef: ExtType.StrDict = self.__Backpack[ToolName]
	if not toolRef then
		warn('Attempt to check ToolOnCoolDown but ToolName "' .. ToolName .. '" was not in backpack of NPC')
		return false--vaciously false
	end
	if not toolRef.__CoolDownLockKey then
		return false--Tool has no cooldown
	end
	toolRef.__CoolDownLock:Lock()
	local isOnCoolDown: boolean = toolRef.OnCoolDown
	toolRef.__CoolDownLock:Unlock()
	return isOnCoolDown
end

--[[
Adds a given tool to an NPC.
    The given tool is copied, not transfered.
    @param Tool (Tool) any given tool to be added to the NPC
    @param Amount (number) the amount of the tool to add
    @return (boolean) true on success or false otherwise
--]]
function ToolNPC:AddTool(Tool: Tool, Amount: number): boolean
	--Collect tool item to preserve base class functions
	local collectSuccess: boolean = self:CollectItem(Tool.Name, Amount)
	if not collectSuccess then
		return false --Collection failed
	end
	local toolItem: ExtType.StrDict = self.__Backpack[Tool.Name]

	--Add tool specific behaivore

	local toolClone: Tool = CloneTool(Tool)
	local success6d: boolean = PrepToolMotor6d(toolClone, self) --Prep motor6d for animations
	if not success6d then
		toolClone:Destroy()
		self.__Backpack[Tool.Name] = nil --Remove from backpack
		return false
	end

	toolItem.DropItem = toolClone
	PrepAnims(toolItem, self)
	toolClone.Parent = nil --Not equipped
	--Set up cool down if it exists
	local toolCoolDown: number? = toolClone:GetAttribute("CoolDown") :: number?
	if toolCoolDown then
		local mainAnimName: string? = toolClone:GetAttribute("ActivateAnimName") :: string?
		if mainAnimName then
			local mainAnim: AnimationTrack? = self.__Animations[mainAnimName]
			if mainAnim == nil then
				warn('Attempt to set up cool down for tool "' .. Tool.Name .. '" but tool ActivateAnimName does not exist in Animation folder')
				toolClone:Destroy()
				self.__Backpack[Tool.Name] = nil --Remove from backpack
				return false
			end
			PrepCoolDown(toolCoolDown, toolItem, mainAnim, self)
		end
	end
	return true --Success
end

--[[
Removes a given tool by its name
    @param ToolName (string) the name of the tool to remove
--]]
function ToolNPC:RemoveTool(ToolName: string): ()
	local tool: any = self.__Backpack[ToolName]
	if tool == nil then
		warn('Attempted to remove tool "' .. ToolName .. '" from NPC "' .. self.Name .. '" but tool is not in backpack')
		return
	end
	local realTool = FindPhysTool(ToolName, self)
	realTool:Destroy()
	self.__Backpack[ToolName] = nil --Sets to nil to remove from backack
end

--[[
Returns a table of all tool names
    @return ({string}) a table of tool names owned by the NPC
--]]
function ToolNPC:GetTools(): { string }
	local tools: { string } = {}
	for key, value in pairs(self.__Backpack) do
		if value.ItemType == "Tool" then
			table.insert(tools, key)
		end
	end
	return tools
end

return ToolNPC
