--[[
This class is simplky a utilities class made to assist with making NPC classes
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPCUtils = {}
Object:Supersedes(NPCUtils)

--[[
Constructor for NPCUtils
    @param Name (string) the name of the instance
--]]
function NPCUtils.new(Name)
    local self = Object.new(Name)
	setmetatable(self, NPCUtils)
    return self
end

--[[
Copys any given item with its tags and attributes included
    @param Item (any) any item to clone
    @return (any) a copy/clone of the item
--]]
function NPCUtils:CopyItem(Item: any) : any
    local itemClone = Item:Clone()
    --Copy tags
    for _, tag in pairs(CollectionService:GetTags(Item)) do
        CollectionService:AddTag(itemClone, tag)
    end
    --Copy attributes
    for key, value in pairs(Item:GetAttributes()) do
        itemClone:SetAttribute(key, value)
    end
    return itemClone
end


--[[
Drops the given item at the NPC's feet
    @param Item (any) the item to drop
    @param NPCCharacter (model) character model to drop from
    @return (boolean) true on success or false otherwise
--]]
function NPCUtils:DropItem(Item: any, NPCCharacter: Model) : boolean
	local rootPart = NPCCharacter:FindFirstChild("HumanoidRootPart")
	local front = rootPart.CFrame.LookVector
	local dropDistance = 0 --Distance from NPC to drop
    local dropPosition = rootPart.Position + dropDistance * front
	--Handle proper placement through raycasting
	-- Create the ray origin and direction
	local rayOrigin = dropPosition + Vector3.new(0, 5, 0) -- Start ray above the intended position
	local rayDirection = Vector3.new(0, -1, 0) * 1e6 -- Extend downward with a very large value

	-- Create RaycastParams
	local params = RaycastParams.new()

	-- Gather all player characters and the NPC to exclude them
	local filterInstances = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(filterInstances, player.Character)
		end
	end
    table.insert(filterInstances, NPCCharacter)

	params.FilterDescendantsInstances = filterInstances -- Ignore all player and the NPC's characters
	params.FilterType = Enum.RaycastFilterType.Exclude -- Set to blacklist mode

	-- Perform the raycast
	local result = Workspace:Raycast(rayOrigin, rayDirection, params)
	if result then
		if Item:IsA("Model") then
			-- Get the extents size of the model
			local extentsSize = Item:GetExtentsSize()

			-- Get the height (Y-axis size)
			local height = extentsSize.Y
			local position = Vector3.new(dropPosition.X, result.Position.Y + height / 2, dropPosition.Z)
			local CFrame = CFrame.new(position, position + front) -- Face the same direction as the player
			Item:PivotTo(CFrame)
		else
			Item.Position = Vector3.new(dropPosition.X, result.Position.Y + Item.Size.Y / 2, dropPosition.Z)
			Item.CFrame = CFrame.new(Item.Position, Item.Position + front) -- Face the same direction as the player
		end
		Item.Parent = Workspace
	else
		--Notify user that there was an error
        return false
	end
    return true --success
end

return NPCUtils