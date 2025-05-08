local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Currency = require(script.Parent.Currency)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

--Events
local SetGoldStat: ExtType.Bridge = BridgeNet2.ReferenceBridge("SetGoldStat")

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
	return Currency:GetAmount(Player, "Gold")
end

function Gold:SetAmount(Player: Player, Value: number): ()
	local setAmount = Currency:SetAmount(Player, Value, "Gold")
	SetGoldStat:Fire(self:GetAmount(Player))
	return setAmount
end

function Gold:ModAmountBy(Player: Player, Value: number): ()
	local setAmount = Currency:ModAmountBy(Player, Value, "Gold")
	SetGoldStat:Fire(Player, self:GetAmount(Player))
	return setAmount
end

return Gold
