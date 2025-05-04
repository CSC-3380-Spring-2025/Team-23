--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local BuildingRequirments = require(game.ServerScriptService.Server.Building.BuildingRequirments)
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")


local BuildingInProgress = {}
Object:Supersedes(BuildingInProgress)

--Constructor that takes in no parameters
function BuildingInProgress.new(Name)
	local self = Object.new(Name)
	setmetatable(self, BuildingInProgress)
	return self
end

local function GetBuildingProgress(CurrentResources: {}, ResourceRequirments: {}): number
	if CurrentResources == {} then return 0 end
	local totalReqCount: number = 0
	local totalCurrCount: number = 0
	for resource, amount in pairs(CurrentResources) do
		totalCurrCount += amount
	end
	for resource, amount in pairs(ResourceRequirments) do
		totalReqCount += amount
	end
	if totalReqCount and totalCurrCount then
		return ((totalCurrCount/totalReqCount)*100)
	else return 0
	end
end

local function ChangeBuildingTransparency(Building: Model | BasePart, PercentBuilt: number): ()
	local Transparency: number = 0
	if PercentBuilt == 100 then
		Transparency = 1
	elseif PercentBuilt == 0 then
		Transparency = 0.05
	else
		Transparency = (((PercentBuilt / 100) / 0.75) + 0.05)
	end

	if Building:IsA("BasePart") then
		Building.Transparency = Transparency
		Building.CanCollide = false
	else
		for _, child in ipairs(Building:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = Transparency
				child.CanCollide = false
			end
		end
	end
end

local function ChangeBuildingFuncitonality(Building: Model | BasePart, TurnOnFunctionality: boolean): ()
	if TurnOnFunctionality then
		for _, descendant in ipairs(Building:GetDescendants()) do
			if
				(descendant:IsA("ProximityPrompt")
				or descendant:IsA("ClickDetector")
				or descendant:IsA("TouchTransmitter")) and 
				(descendant:FindFirstChild("Enabled"))
			then
				descendant.Enabled = true
			elseif descendant:IsA("BasePart") then
				if descendant:FindFirstChild("CanTouch") then
					descendant.CanTouch = true
				end
				if descendant:FindFirstChild("CanCollide") then
					descendant.CanCollide = true
				end
			end
		end
	else
		for _, descendant in ipairs(Building:GetDescendants()) do
			if
				(descendant:IsA("ProximityPrompt")
				or descendant:IsA("ClickDetector")
				or descendant:IsA("TouchTransmitter")) and 
				(descendant:FindFirstChild("Enabled"))
			then
				descendant.Enabled = false
			elseif descendant:IsA("BasePart") then
				if descendant:FindFirstChild("CanTouch") then
					descendant.CanTouch = false
				end
				if descendant:FindFirstChild("CanCollide") then
					descendant.CanCollide = false
				end
			end
		end
	end
end

local function SetUpBuildingGUI(Building: Model | BasePart, CurrentResources: {}, ResourceRequirments: {}): boolean
	local buildingGuiFolder = ReplicatedStorage:FindFirstChild("BuildingInProgress")
	local BuildingGUIElement = buildingGuiFolder:FindFirstChild("BillboardGui"):Clone()
	if not BuildingGUIElement then 
		warn("Unable to get GUI for building construction")
		return false 
	end
	local displayTable: {} = {}
	for resource, amount in pairs(ResourceRequirments) do
	    displayTable[resource] = {
			currentAmount = CurrentResources[resource] or 0,
			amountRequired = ResourceRequirments
		}
	end
	if not displayTable then 
		warn("unable to retrieve from resource tables for buildign construction")
		return false
	end
	--todo: display all items in display table and add buttons for each that will call the add resource function 
	BuildingGUIElement.Adornee = Building
	BuildingGUIElement.Parent = Building
	return true 
end

function BuildingInProgress:SetBuildingToConstructionState(Building: Model, ConstructionParams: {}): boolean
	--grab required resources table from building requirments class
	local buildingTemplate = Building:GetAttribute("BuildingTemplate")
	if not buildingTemplate then buildingTemplate =  Building.Name end
	local ResourceRequirments = BuildingRequirments:GetCostsFromName(buildingTemplate)
	if not ResourceRequirments then 
		warn("unable to get building requirments for", Building.Name)
		return false
	end
	--get current buidling progress from current resources and required resources 
	local PercentBuilt: number = GetBuildingProgress(ConstructionParams, ResourceRequirments)
	if not PercentBuilt then 
		warn("unable to obtain percent progress from ", Building.Name)
		return false
	end
	--change transparency to match current progress
	ChangeBuildingTransparency(Building, PercentBuilt)
	--disable all funcitonality for building
	ChangeBuildingFuncitonality(Building, false)
	--add GUI interactable to finish building
	local buildingGUI = SetUpBuildingGUI(Building, ConstructionParams, ResourceRequirments)
	if not buildingGUI then
		return false
	end
	--finally add uncerconstruction tag to buliding to identify it duering saving process
	CollectionService:AddTag(Building, "UnderConstruction")
	return true
end

function BuildingInProgress:ExportConstructionParams(Building: Model)
	
end

return BuildingInProgress
