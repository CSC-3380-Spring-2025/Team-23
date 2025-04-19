--[[
This script provides common utilities for things involing ItemInfo
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local ItemsUtils = {}
Object:Supersedes(ItemsUtils)

--[[
Constructor that creates an instance for item utils
    @param Name (string) any name for naming your instance
    name does not impact anything and is only for debugs
--]]
function ItemsUtils.new(Name: string)
	local self = Object.new(Name)
	setmetatable(self, ItemsUtils)
	return self
end

--[[
Used to retrieve the info of any item within the Item Directory in
    ReplicatedStorage.Shared.Items
    @param ItemName (string) name of item to get info of
    @return ({any}) table of info related to the item
--]]
function ItemsUtils:GetItemInfo(ItemName: string): ModuleScript?
	local items: Folder = ReplicatedStorage.Shared.Items
	local itemMod: any? = items:FindFirstChild(ItemName, true)
	if not itemMod then
		warn('Item "' .. ItemName .. '" does not exist within Item directory')
		return nil
	end
	if not itemMod:IsA("ModuleScript") then
		warn('Item "' .. ItemName .. '" is in Item directory but is not a ModuleScript')
		return nil
	end

	local itemInfo: ModuleScript = require(itemMod)
	return itemInfo
end

return ItemsUtils