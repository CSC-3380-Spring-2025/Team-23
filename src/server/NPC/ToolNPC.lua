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
local BackpackNPC = require(ServerScriptService.Server.NPC.BackpackNPC)
local ToolNPC = {}
BackpackNPC:Supersedes(ToolNPC)

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
	@param WhiteList ({string}) table of item names that may be added
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
--]]
function ToolNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	WhiteList: {string},
	Backpack: {}?
)
	local self = BackpackNPC.new(Name, Rig, Health, SpawnPos, Speed, MaxWeight, MediumWeight, HeavyWeight, WhiteList, Backpack)
	setmetatable(self, ToolNPC)
	self.__EquippedTool = nil --The tool equipped by the NPC
	return self
end

--[[
Returns the real tool in the players backpack
    @param ToolName (string) the name of the tool to find in backpack
    @param Self (any) the instance of the class
--]]
local function FindPhysTool(ToolName: string, Self: any): Tool?
	for key, value in pairs(Self.__Backpack) do
		if key == ToolName then
			--item is present in backpack so return count and weight of item
			return value.Item
		end
	end
	return nil
end

--[[
Equips a tool for the NPC and unequips any tools currently open
    Tool must already be present in NPC's backpack
    @param ToolName (string) the name of the tool to Equip
--]]
function ToolNPC:EquipTool(ToolName: string): boolean
	local tool = FindPhysTool(ToolName, self)
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

local function PrepToolMotor6d(Tool: Tool, Self: any): boolean
	local animations = Tool:FindFirstChild("Animations")
	if animations == nil then
		warn('Tool "' .. Tool.Name .. '" missing Animations folder')
		return false
	end
	local motor6d = animations:FindFirstChild("Motor6d")
	if motor6d == nil then
		warn('Tool "' .. Tool.Name .. '" missing Motor6d in Animations folder')
		return false
	end
	local motorParent1 = Tool:FindFirstChild("MotorParent1", true)
	if motorParent1 == nil then
		warn('Tool "' .. Tool.Name .. '" found no tool part with name MotorParent1 for Motor6d')
		return false
	end
	local rightHand = Self.__NPC:FindFirstChild("RightHand")

	motor6d.Part1 = motorParent1
	motor6d.Part0 = rightHand

	return true --Success
end

--[[
Returns a clone of a tool
    @param Tool (Tool) the tool to copy
    @return (Tool) a tool clone
--]]
local function CloneTool(Tool)
	local toolClone = Tool:Clone()
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
Adds a given tool to an NPC.
    The given tool is copied, not transfered.
    @param Tool (Tool) any given tool to be added to the NPC
    @param Amount (number) the amount of the tool to add
    @return (booleam) true on success or false otherwise
--]]
function ToolNPC:AddTool(Tool: Tool, Amount: number): boolean
	--Check for valid tool and amount
	if not self:ValidToolAdd(Tool, Amount) then
		warn(
			'Attempted to add tool "' .. Tool.Name .. '" to NPC "' .. self.Name .. '" but Tool or weight was not valid'
		)
		return false
	end

	if Amount <= 0 then
		warn('Attempted to add Amount of 0 or less for tool "' .. Tool.Name .. '"')
		return false
	end
	local weight = Tool:GetAttribute("Weight")
	if weight == nil then
		warn('Weight not set for tool "' .. Tool.Name .. '"')
		return false
	elseif weight < 0 then
		warn('Weight may not be negative for tool "' .. Tool.Name .. '"')
		return false
	end

	local toolClone = CloneTool(Tool)
	local success6d = PrepToolMotor6d(toolClone, self) --Prep motor6d for animations
	if not success6d then
		toolClone:Destroy()
		return false
	end

	toolClone:SetAttribute("Count", Amount)

	self.__Backpack[Tool.Name] = {
		ItemType = "Tool",
		Count = Amount,
		Weight = weight,
		Item = toolClone,
	}
	toolClone.Parent = nil --Not equipped
	return true --Success
end

--[[
Removes a given tool by its name
    @param ToolName (string) the name of the tool to remove
--]]
function ToolNPC:RemoveTool(ToolName): ()
	local tool = self:GetItem(ToolName)
	if tool == nil then
		warn('Attempted to remove tool "' .. ToolName .. '" from NPC "' .. self.Name .. '" but tool is not in backpack')
		return
	end
	tool:Destroy()
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

--[[
Determines if the tool is valid to add to the backpack or not
    @param Tool (Tool) the tool to check for
    @param Amount (number) the amount of the tool to add
    @return (boolean) true on valid or false otherwise
--]]
function ToolNPC:ValidToolAdd(Tool: Tool, Amount: number)
	--Check blacklist for tool name
	if not table.find(self.__WhiteList, Tool.Name) then
		return false
	end
	--Check weight
	local toolWeight = Tool:GetAttribute("Weight")
	if ((toolWeight * Amount) + self:CheckNPCWeight()) > self.__MaxWeight then
		return false
	else
		return true
	end
end

return ToolNPC
