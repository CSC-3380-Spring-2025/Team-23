local Currency = require(script.Parent.Currency)

local Gold = {}
Currency:Supersedes(Gold) --Gold inherits from Currency superclass

function Gold.new(Name: string)
	local self = Currency.new(Name)
	setmetatable(self, Gold) 
	return self
end


--[[
The following functions are simply calling to the currency class and passing the nameOfcurrency parameter as "gold" so that it knows what currency to get/set.
For more on these methods, check currency
]]
function Gold:GetAmount(Player: Player): number
	return Currency:GetAmount(Player, "gold")
end

function Gold:SetAmount(Player: Player, Value: number): ()
	return Currency:SetAmount(Player, Value, "gold")
end

function Gold:ModAmountBy(Player: Player, Value: number): ()
	return Currency:ModAmountBy(Player, Value, "gold")
end

return Gold
