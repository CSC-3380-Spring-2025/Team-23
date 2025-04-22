--[[  
 * Wheat - A subclass of the Crop class, representing the wheat crop with specific growth models 
 * and item attributes for the backpack system (weight and stack size).
 *  
 * Inherits from Crop, with predefined stats for item name ("Wheat"), weight, and max stack size.
 * Wheat models can be found in ReplicatedStorage.Farming.Crops
--]]

local Crop = require(script.Parent.Crop)
local CollectionService = game:GetService("CollectionService")
local Wheat = {}
Crop:Supersedes(Wheat) --Wheat inherits from crop superclass

local __ItemName = "Wheat"
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
	local self = Crop.new(Name, EarlyCrop, MidCrop, FinishedCrop, GrowTime)
	setmetatable(self, Wheat)
	return self
end

--Work in progress until it is possible to use subclasses with backpackHandler class
function Wheat:Reap(Target: Instance, Player: Player): (string, number)
	if Target:HasTag("FarmLand") and Target:HasTag("Harvest_Ready") then
		local cropYield: number = Target:GetAttribute("HarvestAmount") * Target:GetAttribute("YieldFactor")
		for _, cropModel in pairs(Target:GetDescendants()) do
			if cropModel.Name == __ItemName then
				cropModel:Destroy()
			end
		end
		if Target:IsA("BasePart") then
			Target.Material = Enum.Material.LeafyGrass
			Target.BrickColor = BrickColor.new("CGA brown")
		end
		CollectionService:RemoveTag("Harvest_Ready")
		CollectionService:AddTag(Target, "Unsowed")
		return "Wheat", cropYield
	end
	return nil
end

return Wheat
