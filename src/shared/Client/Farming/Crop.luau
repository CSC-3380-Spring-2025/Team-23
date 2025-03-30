--[[  
 * Crop - Superclass of types of crops for farming  
 *  
 * This class represents a basic farming system that handles the process of planting the crops, waiting for them to grow, and harvesting them.
 * It then stores the crops to the players invetory via the inventory handler   
]]

local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local CollectionService = game:GetService("CollectionService")

local Crop: table = {}
Object:Supersedes(Crop)
Crop.__index = Crop --Currency has lookup.

--Attributes
local __EarlyCrop: Model
local __MidCrop: Model
local __FinishedCrop: Model
local __GrowTime: number

--[[
Base constructor of all crops
    @param Name (string) name of instance you are creating
    @param EarlyCrop (model) instance of the plot of land that is unsowed
    @return (instance) instance of the object.
]]
function Crop.new(Name: string, EarlyCrop: Model, MidCrop: Model, FinishedCrop: Model, GrowTime: number): table?
	local self = Object.new(Name)
	setmetatable(self, Crop)
    self.__EarlyCrop = EarlyCrop or error
    self.__MidCropCrop = MidCrop or error
    self.__finishCropCrop = FinishedCrop or error
    self.__GrowTime = GrowTime or error("")
    return self
end

function Crop:Sow(Target: Instance): boolean
    if Target:HasTag("FarmLand") then
        local isUnsowed: string = Target:FindFirstChild("Unsowed")
        if isUnsowed then
            if Target:IsA("BasePart") then
                Target.Material = Enum.Material.Ground
                Target.BrickColor = BrickColor.new("Reddish brown")
                --add decal
                CollectionService:RemoveTag(Target, "Unsowed")
                CollectionService:AddTag(Target, "Sowed")
                return true
            end
        end
   end
   return false
end

local function UpdateCropModels(Target: Instance, CropName: string, To: Model): boolean
    for _, cropModel in pairs(Target:GetDescendants()) do
        if cropModel.Name == CropName then
			local fromPosition: Vector3 = cropModel:GetPivot()
			cropModel:Destroy()
			local replacementModel: Model = To:Clone()
			replacementModel:PivotTo(fromPosition)
			replacementModel.Name = CropName
			replacementModel.Parent = Target
        end
    end
end

function Crop:Plant(Target: Instance, CropName: string): boolean
    if Target:HasTag("FarmLand") then
        local isSowed: string = Target:FindFirstChild("Sowed")
        if isSowed then
            local timePassed: number = Target:GetAttribute("TimePassed")
            local replacementModel: Model = self.__EarlyCrop:Clone()
			replacementModel:PivotTo(Target.Posiiton)
			replacementModel.Name = CropName
			replacementModel.Parent = Target
            while (timePassed < self.__GrowTime/2) do
                task.wait(5)
                timePassed += 5
                Target:SetAttribute("TimePassed", timePassed)
            end
            UpdateCropModels(Target, CropName, self.__MidCropCrop)
            while (timePassed < self.__GrowTime) do
                task.wait(5)
                timePassed += 5
                Target:SetAttribute("TimePassed", timePassed)
            end
            UpdateCropModels(Target, CropName, self.__FinishedCrop)
            CollectionService:RemoveTag("Sowed")
            CollectionService:AddTag(Target, "Harvest_Ready")
            return true
        end
    end
end
return Crop