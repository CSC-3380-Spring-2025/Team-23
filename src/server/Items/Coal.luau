
local Coal = {}
Coal.__index = Coal

local ItemName : string = "Coal"
local ItemWeight : number = 2 -- Weight per 1 item
local ItemStack : number = 50 -- Max stack of items possible

--[[
@Description: Returns the weight of one item of this type.
@Return Weight (Number): The weight of one item.
]]
function Coal:GetWeight() : number
    return ItemWeight
end
--[[
@Description: Returns the name of this item.
@Return ItemName (String): The name of one item.
]]
function Coal:GetName() : string
    return ItemName
end
--[[
@Description: Returns the maximum stack size of this item.
@Return ItemStack (Number): The maximum amount this item can be stacked.
]]
function Coal:GetMaxStack() : number
    return ItemStack
 end

function Coal.new(amount: number, Backpack)
    local self = setmetatable(Backpack.new("Coal", amount), Coal) 
    self.Weight = amount * ItemWeight; -- Weight of the object
    self.MaxStack = ItemStack; -- Max object stack
    return self
end

return Coal
