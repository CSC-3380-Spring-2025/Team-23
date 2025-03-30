local Crop = require(script.Parent.Crop)

local Wheat = {}
Crop:Supersedes(Wheat) --Wheat inherits from crop superclass

function Wheat.new(Name: string, EarlyCrop: Model, MidCrop: Model, FinishedCrop: Model, GrowTime: number): table?
	--Wheat item stats for backpack handler 
	local itemName = "Wheat" --dont change. Should be name of subclass
	local itemWeight = 1
	local itemStack = 100
	local self = Crop.new(Name, EarlyCrop, MidCrop, FinishedCrop, GrowTime, itemName, itemWeight, itemStack)
	
	--for backpack handler
	self.Weight = itemWeight 
	self.MaxStack = itemStack; 
	
	setmetatable(self, Wheat) 
	return self
end


function Wheat:Reap(Target: Instance, Player: Player)
	if Wheat:IsInstanceOf(self, self) then
		self:Reap(Target, Player)
		return true
	end
	return false
end

return Wheat
