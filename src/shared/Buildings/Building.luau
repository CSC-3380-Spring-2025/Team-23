local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local BuildingDataManager = require(game.ServerScriptService.Server.DataServices.BuildingDataManager)
local CollectionService = game:GetService("CollectionService")

local Building: table = {}
Object:Supersedes(Building)
Building.__index = Building --Building has lookup.

--Attributes


function Building.new(Name: string): table?
	local self = Object.new(Name)
	setmetatable(self, Building)
	--self.__EarlyCrop = EarlyCrop or error("EarlyCrop not provided for Crop constructor")
	 
	return self
end

--[[  
 * Sow - Changes the state of a farmland part from "Unsowed" to "Sowed",
 * allowing crops to be planted on it.
 *  
 * NOTE: Target must have the "FarmLand" and "Unsowed" tags,
 * as well as be a basepart 
 *
 * @Target - A BasePart representing a plot of land that may be used for planting crops
 *
 * @return - boolean - Returns true if the land is successfully marked as "Sowed", otherwise returns false.
]]
function Crop:Sow(Target: Instance): boolean
	if Target:HasTag("FarmLand") then
		if Target:HasTag("Unsowed") then
			if Target:IsA("BasePart") then
				Target.Material = Enum.Material.Ground
				Target.BrickColor = BrickColor.new("Reddish brown")
				CollectionService:RemoveTag(Target, "Unsowed")
				CollectionService:AddTag(Target, "Sowed")
				return true
			end
		end
	end
	return false
end

--[[  
 * UpdateCropModels - Helper function for Plant that changes the appearance of crops in a farmland part by replacing
 * existing crop models with more grown versions.
 *  
 * @Target - A BasePart representing the land where the crops are located.
 * @CropName - A string representing the name of the crop (e.g., "WheatBushel") to be replaced.
 * @To - A Model representing the more grown version of the crop to replace the existing one.
 *
 * @return - Returns nothing
]]
local function UpdateCropModels(Target: Instance, CropName: string, To: Model): ()
	local changedCrops: {Model} = {} 
	for _, cropModel in pairs(Target:GetDescendants()) do
		if cropModel.Name == CropName then
			local fromPosition: Vector3 = cropModel:GetPivot().Position
			local spawnHeight: number = ((Target.Position.Y+(Target.Size.Y/2)) + select(2, To:GetBoundingBox()).Y/2)
			local cropSpawnLocation: Vector3 = Vector3.new(fromPosition.X,spawnHeight, fromPosition.Z)
			cropModel:Destroy()
			local replacementModel: Model = To:Clone()
			replacementModel:PivotTo(CFrame.new(cropSpawnLocation))
			replacementModel.Name = CropName
			table.insert(changedCrops, replacementModel)
		end
	end

	for _, changedModel in pairs(changedCrops)	do
		changedModel.Parent = Target
	end	
end

--[[  
 * Plant - Handles the process of a crop growing over time, updating the crop's
 * appearance at different stages (early, mid, finished), and keeping track of the 
 * time until the crop can be harvested.
 *  
 * NOTE: Target must have both the "FarmLand" and "Sowed" tags in order to plant crops on it.
 *
 * @Target - A BasePart representing the land where the crop will be planted.
 * @CropName - A string representing the name of the crop (e.g., "WheatBushel").
 *
 * @return - boolean - Returns true if the crop was successfully planted and reached harvestable state,
 *                     otherwise returns false
]]
function Crop:Plant(Target: Instance, CropName: string): boolean
	if Target:HasTag("FarmLand") then
		if Target:HasTag("Sowed") then
			local timePassed: number = Target:GetAttribute("TimePassed")
			if self.__EarlyCrop then
				local replacementModel: Model = self.__EarlyCrop:Clone()
				local spawnHeight: number = ((Target.Position.Y+(Target.Size.Y/2)) + select(2, self.__EarlyCrop:GetBoundingBox()).Y/2)
				local cropSpawnLocation: Vector3 = Vector3.new(
					Target.Position.X, 
					(spawnHeight), 
					Target.Position.Z)
				replacementModel:PivotTo(CFrame.new(cropSpawnLocation))
				replacementModel.Name = CropName
				replacementModel.Parent = Target
			else 
				warn("Error: ", self.__EarlyCrop, " Was unable to clone")
				return false
			end
			while (timePassed < self.__GrowTime/2) do
				task.wait(5)
				timePassed += 5
				Target:SetAttribute("TimePassed", timePassed)
			end
			if self.__MidCrop then
				UpdateCropModels(Target, CropName, self.__MidCrop)
			else
				warn("Error: ", self.__MidCrop, " Was unable to clone")
				return false
			end
			
			while (timePassed < self.__GrowTime) do
				task.wait(5)
				timePassed += 5
				Target:SetAttribute("TimePassed", timePassed)
			end
			if self.__MidCrop then
				UpdateCropModels(Target, CropName, self.__FinishedCrop)
			else
				warn("Error: ", self.__FinishedCrop, " Was unable to clone")
				return false
			end
			
			CollectionService:RemoveTag("Sowed")
			CollectionService:AddTag(Target, "Harvest_Ready")
			return true
		end
	end
end

--[[  
 * Fertilize - Increases the crop's yield factor by the specified amount.
 *  
 * NOTE: Target must have the "FarmLand" tag to fertilize the crop.
 *
 * @Target - A BasePart representing the land where the crop is located.
 * @FactorIncrease - A number representing the amount to increase the crop's yield factor.
 *
 * @return - boolean - Returns true if the fertilization process is successful, 
 *                     otherwise returns false.
]]
function Crop:Fertilize(Target: Instance, FactorIncrease: number): boolean
	if Target:HasTag("FarmLand") then
		local currentYieldFactor = Target:GetAttribute("YieldFactor")
		local maxYield = Target:GetAttribute("MaxYield")
		local newYield = currentYieldFactor
		if currentYieldFactor+FactorIncrease > maxYield then
			newYield = maxYield
		else
			newYield = currentYieldFactor + FactorIncrease
		end
		return true	
	end
	return false
end

--Work in progress until it is possible to use subclasses with backpackHandler class
--[[
function Crop:Reap(Target: Instance, Player: Player)
	if Target:HasTag("FarmLand") and Target:HasTag("Harvest Ready") then
		local cropYield: number = Target:GetAttribute("HarvestAmount") * Target:GetAttribute("YieldFactor")
		BackpackHandler:AddItemToBackPack(Player, self.__ItemName, cropYield)
		for _, cropModel in pairs(Target:GetDescendants()) do
			if cropModel.Name == self.__ItemName then
				cropModel:Destroy()
			end
		end
		if Target:IsA("BasePart") then
			Target.Material = Enum.Material.LeafyGrass
			Target.BrickColor = BrickColor.new("CGA brown")
		end
		CollectionService:RemoveTag("Harvest_Ready")
		CollectionService:AddTag(Target, "Unsowed")
	end
end
]]
return Crop
