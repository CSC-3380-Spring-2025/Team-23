local Backpack = require(game.ServerScriptService.server.Player.BackpackHandler)

local Coal = setmetatable({}, { __index = Backpack }) -- Inheriting from Currency
Coal.__index = Coal

local ItemName : string = "Coal"
local ItemWeight : number = 2 -- Weight per 1 item
local ItemStack : number = 50 -- Max stack of items possible

function Coal:GetWeight() : number
    return ItemWeight
end

function Coal:GetName() : string
    return ItemName
end

function Coal:GetMaxStack() : number
    return ItemStack
 end

function Coal.new(amount: number)
    local self = setmetatable(Backpack.new("Coal", amount), Coal) 
    self.Weight = amount * ItemWeight; -- Weight of the object
    self.MaxStack = ItemStack; -- Max object stack
    return self
end

return Coal
