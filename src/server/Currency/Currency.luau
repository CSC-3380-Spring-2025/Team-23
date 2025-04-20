--[[  
 * Currency - Superclass of all currency classes.  
 *  
 * This class represents a basic currency system that tracks an amount and provides methods  
 * for retrieving, setting, and modifying the currency value. It extends the Object class.  
 *  
]]

local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)


local Currency: table = {}
Object:Supersedes(Currency)
Currency.__index = Currency --Currency has lookup.
local SessionDataManagerInstance: {} = SessionDataManager.new("SessionDataManagerInstance")
--[[
Base constructor of all currencies
    @param Name (string) name of instance you are creating
    @param Amount (number) optional amount of the currency
    @return (instance) instance of the object.
]]
function Currency.new(Name: string) 
	local self = Object.new(Name)
	setmetatable(self, Currency)  
	return self
end

--[[
 * getAmount - Retrieves the current amount of currency.
 * 
 * @return - (number) - The current value of `self.__Amount`.
]]
function Currency:GetAmount(Player: Player, NameOfCurrency: string): number
	local table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	if table then
		local amount: number = table.Currency[NameOfCurrency]
		return amount
	end
	return nil
end

--[[
 * setAmount - Sets the currency amount to a specified value.
 * 
 * @value - (number) The new currency amount. 
 *          - Value needs to be positive since amount cant ve negative  
 *
 * @return - None
]]
function Currency:SetAmount(Player: Player, Value: number, NameOfCurrency: string): ()
	if Value > 0 then 
		local table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
		if table then
			table.Currency[NameOfCurrency] = Value
			SessionDataManagerInstance:SetPlayerData(Player.UserId, table)
		end
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
function Currency:ModAmountBy(Player:Player, Value: number, NameOfCurrency: string): ()
	local table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	if table then
		local currencyAmount: number = table.Currency[NameOfCurrency] 
		if Value > 0 then
			currencyAmount = currencyAmount + Value
		elseif currencyAmount > Value then
			currencyAmount = currencyAmount - Value
		end
		if 
			currencyAmount < 0 then currencyAmount=0 
		end
	table.Currency[NameOfCurrency] = currencyAmount
	SessionDataManagerInstance:SetPlayerData(Player.UserId, table)
	end
end

return Currency
