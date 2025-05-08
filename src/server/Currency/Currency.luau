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
 * @Player - The player whos currency will be fetched from their sesssion data
 * @NameOfCurrency - The name of the type of currency whos value will be returned. Should only be passed in and called from subclasses. For example, Gold class should pass "gold"
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
 * @Player - The player whose currency will be updated in their session data.
 * @Value - (number) The new currency amount. 
 *          - Must be a positive number; the amount cannot be negative.
 * @NameOfCurrency - The name of the type of currency being updated (e.g., "gold"). Must be passed from the subclass
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
 * @Player - The player whose currency will be modified in their session data.
 * @Value - (number) The amount to modify the currency by. 
 *          - Positive values increase the amount.
 *          - Negative values decrease the amount (only if balance is sufficient).
 * @NameOfCurrency - The name of the type of currency being modified (e.g., "gold"). Must be passed from subclass
 *
 * @NOTE: No negative currency balances are allowed. If the operation would cause the balance to fall below zero, it is clamped to 0.
 *
 * @return - None 
]]
function Currency:ModAmountBy(Player:Player, Value: number, NameOfCurrency: string): ()
	local table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	if table then
		local currencyAmount: number = table.Currency[NameOfCurrency] 
		local newAmount = currencyAmount + Value
		if newAmount <= 0 then
			newAmount = 0
		end
	table.Currency[NameOfCurrency] = newAmount
	SessionDataManagerInstance:SetPlayerData(Player.UserId, table)
	end
end

return Currency
