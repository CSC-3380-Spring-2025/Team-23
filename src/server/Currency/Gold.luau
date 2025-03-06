local Currency = require(game.ServerScriptService.server.Currency)

local Gold = setmetatable({}, { __index = Currency }) -- Inheriting from Currency
Gold.__index = Gold

function Gold.new(amount: number)
    local self = setmetatable(Currency.new("Gold", amount), Gold) 
    return self
end

return Gold
