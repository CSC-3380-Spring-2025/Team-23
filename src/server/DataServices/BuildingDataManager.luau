--[[
 * BuildingDataManager - This module loads a player's buildings when they join or when their plot is reassigned, 
 *                using data stored in the `Base` section of their player data table. 
 *                When a player leaves or their plot is reassigned, it removes and saves their buildings 
 *                back into their data table for future use.
 *
]]
--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local SessionDataManager = require(script.Parent.SessionDataManager)

--services
local ReplicatedStorage = game:GetService("ReplicatedStorage") --For building templates
local Workspace = game:GetService("Workspace") --To spawn or remove player buildings

local BuildingDataManager = {}
Object:Supersedes(BuildingDataManager) 


local SessionDataManagerInstance: table = SessionDataManager.new()

--Constructor that takes in no parameters
function BuildingDataManager.new(Name) 
	local self = Object.new(Name)
	setmetatable(self, BuildingDataManager)  
	return self
end

--[[
 * LoadBasePart/LoadModel - This function retrieves the appropriate building template from 
 *                ReplicatedStorage/Buildings, clones it, applies its position relative 
 *                to `playerPlotOrigin`, and sets any specified properties and attributes.
 *                Finally, the building is placed to Workspace/PlayerPlots/userID to 
 *                associate it with the correct player and spawn it in the world.

 * @player - (Player) The player whose building is being loaded.
 * @playerPlotOrigin - (CFrame) The CFrame position where the player's building should be placed.
 * @buildingType - (string) The type of building (e.g., "Barracks", "Farm", "House") that corresponds 
 *                 to a folder inside ReplicatedStorage/Buildings.
 * @buildingData - (table) A table containing building-specific data like buildingName, CFrame, properties, etc...
 *
 * @return - (boolean) Returns `true` if the building was successfully loaded and placed.
 *                     Returns `false` if an error occurs, such as a missing template or workspace folder.
]]
local function LoadBasePart(player: Player, playerPlotOrigin: CFrame, buildingType: string, buildingData: table): boolean
	print("entered loadbase part for", buildingData)
	local buildingName: string = buildingData.buildingName

	-- Check if the building template exists in ReplicatedStorage
	local buildingTemplate = ReplicatedStorage:FindFirstChild("Buildings") 
		and ReplicatedStorage.Buildings:FindFirstChild(buildingType) 
		and ReplicatedStorage.Buildings[buildingType]:FindFirstChild(buildingName)

	if not buildingTemplate then
		warn("Building template not found: " .. buildingType .. " / " .. buildingName)
		return false
	end

	-- Clone the building template and apply the relativeCframe, properties and attributes
	local newBuilding = buildingTemplate:Clone()

	-- Create CFrames from data and apply them to the building relative to playplot
	local relCframe: table = buildingData.CFrame

	local relativeCFrame: CFrame = CFrame.new(relCframe[1], relCframe[2], relCframe[3]) 
		* CFrame.Angles(math.rad(relCframe[4] or 0), math.rad(relCframe[5] or 0), math.rad(relCframe[6] or 0))

	newBuilding.CFrame = playerPlotOrigin * relativeCFrame

	if buildingData.properties then
		for propertyName, propertyValue in pairs(buildingData.properties) do
			if propertyValue ~= nil then 
				if propertyName == "Color" and type(propertyValue) == "table" then
					newBuilding[propertyName] = Color3.new(unpack(propertyValue)) -- Converts {R, G, B} to Color3
				else
					newBuilding[propertyName] = propertyValue
				end
			else
				warn("Property " .. propertyName .. " does not exist on " .. buildingName)
			end
		end
		newBuilding.Anchored = true
	end

	if buildingData.attributes then
		for attrName, attrValue in pairs(buildingData.attributes) do
			if attrValue ~= nil then
				newBuilding:SetAttribute(attrName, attrValue)
			end
		end
	end

	-- Check if Users PlayerPlot exists in Workspace
	local playerPlots = Workspace:FindFirstChild("PlayerPlots")

	if playerPlots then
		local playerPlot = playerPlots:FindFirstChild(player.UserId)
		if not playerPlot then
			playerPlot = Instance.new("Folder")
			playerPlot.Name = tostring(player.UserId)
			playerPlot.Parent = playerPlots
		end
		-- Create the new building inside players playerPlot
		newBuilding.Parent = playerPlot
		print("Successfully loaded building:", buildingName)
		return true
	else
		warn("PlayerPlots folder not found")
		return false
	end

end

--Documentation can be found in LoadBasePart.
local function LoadModel(player: Player, playerPlotOrigin: CFrame, buildingType: string, buildingData: table): boolean
	local buildingName: string = buildingData.buildingName

	-- Check if the building template exists in ReplicatedStorage
	local buildingsFolder = ReplicatedStorage:FindFirstChild("Buildings")
	local buildingTemplate = buildingsFolder and buildingsFolder:FindFirstChild(buildingType) 
		and buildingsFolder[buildingType]:FindFirstChild(buildingName)

	if not buildingTemplate or not buildingTemplate:IsA("Model") then
		warn("Model template not found: " .. buildingType .. " / " .. buildingName)
		return false
	end

	-- Clone the model template
	local newBuilding = buildingTemplate:Clone()

	-- Ensure the model has a PrimaryPart
	if not newBuilding.PrimaryPart then
		warn("Model " .. buildingName .. " has no PrimaryPart. Cannot set CFrame.")
		return false
	end

	-- Create CFrames from data and apply relative positioning
	local relCframe: table = buildingData.CFrame
	local relativeCFrame: CFrame = CFrame.new(relCframe[1], relCframe[2], relCframe[3]) 
		* CFrame.Angles(math.rad(relCframe[4] or 0), math.rad(relCframe[5] or 0), math.rad(relCframe[6] or 0))

	newBuilding:SetPrimaryPartCFrame(playerPlotOrigin * relativeCFrame)

	-- Apply properties with special handling for CFrame and Color3
	if buildingData.properties then
		for propertyName, propertyValue in pairs(buildingData.properties) do
			if propertyValue ~= nil then
				if propertyName == "Color" and type(propertyValue) == "table" then
					newBuilding.PrimaryPart[propertyName] = Color3.new(unpack(propertyValue)) -- Converts {R, G, B} to Color3
				else
					newBuilding.PrimaryPart[propertyName] = propertyValue
				end
			end
		end
		newBuilding.PrimaryPart.Anchored = true
	end

	-- Apply attributes
	if buildingData.attributes then
		for attrName, attrValue in pairs(buildingData.attributes) do
			if attrValue ~= nil then
				newBuilding:SetAttribute(attrName, attrValue)
			end
		end
	end

	-- Check if Users PlayerPlot exists in Workspace
	local playerPlots = Workspace:FindFirstChild("PlayerPlots")

	if playerPlots then
		local playerPlot = playerPlots:FindFirstChild(player.UserId)
		if not playerPlot then
			playerPlot = Instance.new("Folder")
			playerPlot.Name = tostring(player.UserId)
			playerPlot.Parent = playerPlots
		end
		-- Create the new building inside players playerPlot
		newBuilding.Parent = playerPlot
		print("Successfully loaded building:", buildingName)
		return true
	else
		warn("PlayerPlots folder not found")
		return false
	end
end

--[[
 * LoadBuildings - Loads the buildings stored in a player's data table and places them at the specified plot origin.
 *
 * @player - (Player) The player whose buildings need to be loaded.
 * @playerPlotOrigin - (CFrame) The CFrame position of the origin of the players plot. This is for the relative c frame positions in the data table
 *
 * NOTE: in the buildings file in replicated storage, every model should have a primary part
 * 
 * @return - None. 
]]
function BuildingDataManager:LoadBuildings(player: Player, playerPlotOrigin: CFrame)
	local playerData: table = SessionDataManagerInstance:GetPlayerData(player.UserId)
	print("entering load buildings. data im working with", playerData)
	local playerBuildingData: table = playerData.Base
	for buildingType, buildingTypeData in pairs(playerBuildingData) do
		for _, building in ipairs(buildingTypeData) do
			print("buuliding", building)
			local buildingMade: boolean = false
			if building.buildingType == "basePart" then
				buildingMade = LoadBasePart(player, playerPlotOrigin, buildingType, building)
			elseif building.buildingType == "model" then
				buildingMade = LoadModel(player, playerPlotOrigin, buildingType, building)	
			else
				warn("building type not recognised", building.buildingType, "for", building.buildingName)
			end
			if not buildingMade then warn("an error occured when attempting to load building", building.buildingName) end

		end
	end
end


--Work in progress. DO NOT USE.
function BuildingDataManager:SaveBuildings(player: Player)
	local playerData: table = SessionDataManagerInstance:GetPlayerData(player.UserId)
	local playerBuildingData: table = playerData.Base
	-- Check if Users PlayerPlot exists in Workspace
	local playerPlot = Workspace:FindFirstChild("PlayerPlots")
		and workspace.PlayerPlots:FindFirstChild(player.UserId)
	if playerPlot then
		for building in pairs(playerPlot) do 
			--todo. have each building class export data to playerData
		end
	end
end

return BuildingDataManager

