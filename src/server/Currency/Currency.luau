--[[  
 * Currency - Superclass of all currency classes.  
 *  
 * This class represents a basic currency system that tracks an amount and provides methods  
 * for retrieving, setting, and modifying the currency value. It extends the Object class.  
 *  
]]

local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local Currency: table = {}
Object:Supersedes(Currency)
Currency.__index = Currency --Currency has lookup.

--Attributes
local __Amount: number = 0
--[[
Base constructor of all currencies
    @param Name (string) name of instance you are creating
    @param Amount (number) optional amount of the currency
    @return (instance) instance of the object.
]]
function Currency.new(Name: string, Amount: number) 
	local self = Object.new(Name)
	setmetatable(self, Currency)  
	self.__Amount = Amount
	return self
end

--[[
 * getAmount - Retrieves the current amount of currency.
 * 
 * @return - (number) - The current value of `self.__Amount`.
]]
function Currency:GetAmount()
    return self.__Amount
end

--[[
 * setAmount - Sets the currency amount to a specified value.
 * 
 * @value - (number) The new currency amount. 
 *          - Value needs to be positive since amount cant ve negative  
 *
 * @return - None
]]
function Currency:SetAmount(Value: number): ()
    if Value > 0 then 
	    self.__Amount = Value
    end
end

--[[
 * modAmountBy - Modifies the amount of currency by adding or subtracting a given value.
 * 
 * @value - (number) The amount to modify the currency by. 
 *          - If positive, the currency amount increases by this value.
 *          - If negative, the currency amount decreases by this value (if sufficient balance exists).
 * @note - No negative amounts can exist so if you decrease by mroe than the current amount, it will be 0
 * 
 * @return - None 
]]
function Currency:ModAmountBy(Value: number): ()
    if Value > 0 then
        self.__Amount = self.__Amount + Value
    else 
        if self.__Amount > Value then 
            self.__Amount = self.__Amount - Value
        end
	end
	if self.__Amount < 0 then self.__Amount=0 end
end

return Currency
