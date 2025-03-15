local Currency = require(script.Parent.Gold)

local Gold = {}
Currency:Supersedes(Gold) --Gold inherits from Currency superclass

function Gold.new(Name: string, amount: number)
	local self = Currency.new(Name, amount)
	setmetatable(self, Gold) 
	return self
end

return Gold
