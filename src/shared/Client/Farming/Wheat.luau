local Crop = require(script.Parent.Crop)

local Wheat = {}
Crop:Supersedes(Wheat) --Wheat inherits from crop superclass

function Wheat.new(Name: string, EarlyCrop: Model, MidCrop: Model, FinishedCrop: Model, GrowTime: number): table?
	local self = Crop.new(Name, EarlyCrop, MidCrop, FinishedCrop, GrowTime)
	setmetatable(self, Wheat) 
	return self
end

return Wheat
