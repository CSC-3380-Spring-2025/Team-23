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
	Backpack: {}?
)
	local self = BackpackNPC.new(Name, Rig, Health, SpawnPos, Speed, MaxWeight, MediumWeight, HeavyWeight)
	setmetatable(self, ToolNPC)
    self.__EquippedTool = nil --The tool equipped by the NPC
	return self
end

--[[
Equips a tool for the NPC and unequips any tools currently open
    Tool must already be present in NPC's backpack
    @param ToolName (string) the name of the tool to Equip
--]]
function ToolNPC:EquipTool(ToolName: string) : ()
    
end

--[[
Unequips the current tool held by the NPC
--]]
function ToolNPC:UnequipTool() : ()
    
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
function ToolNPC:AddTool(Tool: Tool, Amount: number) : boolean
    if Amount <= 0 then
        warn("Attempted to add Amount of 0 or less for tool \"" .. Tool.Name .. "\"")
        return false
    end
    local weight = Tool:GetAttribute("Weight")
    if weight == nil then
        warn("Weight not set for tool \"" .. Tool.Name .. "\"")
        return false
    elseif weight < 0 then 
        warn("Weight may not be negative for tool \"" .. Tool.Name .."\"")
        return false
    end

    --Check for if allowed to add to backpack here at somepoint

    local toolClone = CloneTool(Tool)
    toolClone:SetAttribute("Count", Amount)

    self.__Backpack[Tool.Name] = {
        ItemType = "Tool",
        Count = Amount,
        Weight = weight,
        Item = toolClone,
    }
    return true --Success
end

--[[
Removes a given tool by its name
    @param ToolName (string) the name of the tool to remove
--]]
function ToolNPC:RemoveTool(ToolName) : ()
    local tool = self:GetItem(ToolName)
    if tool == nil then
        warn("Attempted to remove tool \"" .. ToolName .. "\" from NPC \"" 
        .. self.Name .. "\" but tool is not in backpack")
        return
    end
    tool:Destroy()
    self.__Backpack[ToolName] = nil --Sets to nil to remove from backack
end

--[[
Returns a table of all tool names
    @return ({string}) a table of tool names owned by the NPC
--]]
function ToolNPC:GetTools() : {string}
    local tools: {string} = {}
    for key, value in pairs(self.__Backpack) do
        if value.ItemType == "Tool" then
            table.insert(tools, key)
        end
    end
    return tools
end

return ToolNPC
