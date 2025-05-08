--[[
This class defines a common ancestry and behaivore of all ResourceTools
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ItemUtilsObject = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local Tool = require(script.Parent.Parent.Tool)
local ResourceTool = {}
Tool:Supersedes(ResourceTool)

--[[
The constructor for the Tools class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool in workspace being used
    does not copy the given tool but uses it directly
--]]
function ResourceTool.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance
    local self = Tool.new(Name, PhysTool)
	setmetatable(self, ResourceTool)
    self.__Effectiveness = PhysTool:GetAttribute("Effectiveness")--Defines the distance needed to activate this tool
    self.__ActivationRadious = 3--Distance in studs that a pickaxe user can activate their pickaxe from an ore
    if not self.__Effectiveness then
        warn("Attempt to create ResourceTool instance but physical tool is missing Effectiveness attribute")
    end
    if not self.__ToolInfo then
        warn("Attempt to create ResourceTool instance but ItemInfo Folder is missing ItemInfo")
        return self
    end
    self.__ResourceWhitelist = self.__ToolInfo.ResourceWhitelist--List of all resource types a tool is allowed to interact with
	return self
end

--[[
This function determines if a ResoureTool is allowed to interact with a certain resource or not
    given any instance assumed to be a resource object.
    @param Instance (Instance) any instance assumed to be a resource
    @return (boolean) true if whitelisted or false otherwise
--]]
function ResourceTool:CanInteract(Instance: Instance) : boolean
    if not self.__ResourceWhitelist then
        return false--This tool has no whitelisted items
    end
    --Check all tags for Instance and check if in whitelist
    for resourceType, resourceTable in pairs(self.__ResourceWhitelist) do
        --Check for resource type
        if not CollectionService:HasTag(Instance, resourceType) then
            continue--whitelisted ResourceType not tagged for Instance
        end
        --Check for resources
        for _, resource in pairs(resourceTable) do
            if CollectionService:HasTag(Instance, resource) then
                return true
            elseif resource == "All" then
                return true--Checks if all items are allowed of this ResourceType
            end
        end
    end
    return false--no tags that indicate its a valid resource for this tool
end

return ResourceTool