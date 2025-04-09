--[[
This class provides the common interface for all item types
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local ItemsInterface = {}
Object:Supersedes(ItemsInterface)

function ItemsInterface.new(Name, Weight, MaxStack, ItemType, ItemName)
    local self = Object.new(Name)
    setmetatable(self, ItemsInterface)
    self.__Weight = Weight or AbstractInterface:AbstractVarError("Weight", "ItemsInterface")
    self.__MaxStack = MaxStack or AbstractInterface:AbstractVarError("MaxStack", "ItemsInterface")
    self.__ItemType = ItemType or AbstractInterface:AbstractVarError("ItemType", "ItemsInterface")
    self.__ItemName = ItemType or AbstractInterface:AbstractVarError("ItemName", "ItemsInterface")
    return self
end

--[[
Returns the weight of one item of this type.
    @Return (number) The weight of one item.
]]
function ItemsInterface:GetWeight() : number
    return self.__Weight
end

--[[
Returns the name of this item.
    @Return (string) The name of one item.
]]
function ItemsInterface:GetName() : string
    return self.__ItemName
end

--[[
Returns the maximum stack size of this item.
    @Return (number) The maximum amount this item can be stacked.
]]
function ItemsInterface:GetMaxStack() : number
    return self.__MaxStack
end

--[[
Returns the type of item
    @return (string) the name of the type of item
--]]
function ItemsInterface:GetItemType() : string
    return self.__ItemType
end

return ItemsInterface
