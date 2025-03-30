--[[  
 * Wheat - A subclass of the Crop class, representing the wheat crop with specific growth models 
 * and item attributes for the backpack system (weight and stack size).
 *  
 * Inherits from Crop, with predefined stats for item name ("Wheat"), weight, and max stack size.
 * Wheat models can be found in ReplicatedStorage.Farming.Crops
--]]


local Crop = require(script.Parent.Crop)

local Wheat = {}
Crop:Supersedes(Wheat) --Wheat inherits from crop superclass


--[[  
 * Constructor for Wheat object, inheriting from the Crop class 
 *  
 * NOTE: The itemName, itemWeight, and itemStack values are for the items stats for the backpack. The stack and weight may be changed but the name must remain fixed as the name of the subclass 
 *
 * @Name - A string representing the name of the wheat crop.
 *
 * NOTE: Models for early, mid, and finished crop stages should have their PrimaryPart set to "Hitbox".
 * @EarlyCrop - A Model representing the wheat crop in its early growth stage.
 * @MidCrop - A Model representing the wheat crop at its mid-growth stage.
 * @FinishedCrop - A Model representing the fully grown wheat crop, ready for harvest.
 * NOTE: Wheat models can be found in ReplicatedStorage.Farming.Crops 
 *
 * @GrowTime - A number representing the time in seconds it takes for the wheat crop to fully grow.
 *
 * @return - table - Returns a new Wheat object initialized with the provided values and item stats.
]]
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

--Work in progress until it is possible to use subclasses with backpackHandler class
--[[
function Wheat:Reap(Target: Instance, Player: Player)
	if Wheat:IsInstanceOf(self, self) then
		self:Reap(Target, Player)
		return true
	end
	return false
end
]]

return Wheat
