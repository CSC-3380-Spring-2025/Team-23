--[[
This class provides the common interface for all item types
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local ItemsInterface = {}
Object:Supersedes(ItemsInterface)

function ItemsInterface.new(Name, Weight, MaxStack, ItemType)
    local self = Object.new(Name)
    setmetatable(self, ItemsInterface)
    self.__Weight = Weight or AbstractInterface:AbstractVarError("Weight", "ItemsInterface")
    self.__MaxStack = MaxStack or AbstractInterface:AbstractVarError("MaxStack", "ItemsInterface")
    self.__ItemType = ItemType or AbstractInterface:AbstractVarError("ItemType", "ItemsInterface")
    return self
end

--[[
@Description: Returns the weight of one item of this type.
@Return Weight (Number): The weight of one item.
]]
function ItemsInterface:GetWeight() : number
    AbstractInterface:AbstractError("GetWeight", "ItemsInterface")
    return -1
end
--[[
@Description: Returns the name of this item.
@Return ItemName (String): The name of one item.
]]
function ItemsInterface:GetName() : string
    AbstractInterface:AbstractError("GetName", "ItemsInterface")
    return ""
end
--[[
@Description: Returns the maximum stack size of this item.
@Return ItemStack (Number): The maximum amount this item can be stacked.
]]
function ItemsInterface:GetMaxStack() : number
    AbstractInterface:AbstractError("GetWeight", "ItemsInterface")
    return -1
 end

return ItemsInterface
