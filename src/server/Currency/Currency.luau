local Currency : table = {}
Currency.__index = Currency
--in server script 
function Currency.new(name, amount)
    local self: table = setmetatable({}, Currency)
    self.name = name or "Currency"
    self.amount = amount or 0
    return self
end

function Currency:getAmount()
    return self.amount
end

function Currency:setAmount(value)
    if value > 0 then 
    self.amount = value
    end
end

function Currency:modAmountBy(value)
    if value > 0 then
        self.amount = self.amount + value
    else 
        if self.amount > value then 
            self.amount = self.amount - value
        end
    end
end

return Currency
