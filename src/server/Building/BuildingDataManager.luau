--[[
 * BuildingDataManager:
 *
 * This script manages the process of loading and saving the buildings on a players plot of land into and from the data store. 
 * It only works for BaseParts or Models with primary parts that are in replicated storage/buildings
 * 
 * - The only functions to be used are LoadBuildings on player join or plot assignemnt and SaveBuildings on player leave or plot deallocation.

 * - Refer to Defailt Player data script to see the layout of the session data used in these functions
]]

--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
 * getBasePartProperties - This function extracts a set of commonly used and storable 
 *                properties from a given BasePart instance. It returns them in a dictionary 
 *                where each key is the property's name (as a string) and the value is a 
 *                primitive data type suitable for saving to DataStore (e.g., 
 *                strings of name of instance instead of instance itself or tables of numbers instead of Vector3).
 * 
 * NOTE:Any properties added here must also be handled in `setBasePartProperty` 
 *
 * @part - The basepart whose properties are to be extracted.
 *
 * @return - table of property names and their values:
 *          
]]
local function getBasePartProperties(part: BasePart): {}
	local properties = {}
	properties["Name"] = part.Name or nil
	properties["Material"] = part.Material.Name or nil
	properties["Transparency"] = part.Transparency or nil
	properties["CanCollide"] = part.CanCollide or nil 
	properties["Reflectance"] = part.Reflectance or nil
	properties["BrickColor"] = part.BrickColor.Name or nil
	properties["TopSurface"] = part.TopSurface.Name or nil
	properties["BottomSurface"] = part.BottomSurface.Name or nil
	if part:IsA("Part") then
		properties["Shape"] = part.Shape.Name or nil
	end
	properties["Size"] = {part.Size.X, part.Size.Y, part.Size.Z}
	return properties
end


--[[
 * setBasePartProperty - assigns a given property to a BasePart. Because some BasePart 
 *                properties like BrickColor, and size require conversion from primitive values into Roblox instances, 
 *                this function includes conditional logic to handle those cases. Otherwise, properties like Name amd 
 * 				Transparency are assigned directly.
 *
 *  NOTE:Any properties added here must also be handled in `getBasePartProperty` 
 *
 * @part - (BasePart) The part whose property should be modified.
 * @propertyName - (string) The name of the property to change.
 * @propertyValue - (any) The value to assign to the property.
 *
 * @return - () Void. The function modifies the given part.
]]
local function setBasePartProperty(part: BasePart, propertyName: string, propertyValue: any): ()
	if propertyName == "BrickColor" then
		part.BrickColor = BrickColor.new(propertyValue)
	elseif propertyName == "Material" then
		part.Material = Enum.Material[propertyValue]
	elseif propertyName == "TopSurface" then
		part.TopSurface = Enum.SurfaceType[propertyValue]
	elseif propertyName == "BottomSurface" then
		part.BottomSurface = Enum.SurfaceType[propertyValue]
	elseif propertyName == "Shape" and part:IsA("Part") then
		part.Shape = Enum.PartType[propertyValue]
	elseif propertyName == "Size" then
		part.Size = Vector3.new(propertyValue[1], propertyValue[2], propertyValue[3])
	else
		-- For properties whih dont need to be turned into an instance like Name and Transparency
		pcall(function()
			part[propertyName] = propertyValue
		end)
	end
end


--[[
 * SaveBasePart/SaveModel - This function saves BaseParts data 
 *                into a table of primitive values suitable for saving to a DataStore. 
 *                It stores the part's CFrame relative to the `PlayerPlot` origin, 
 *                along with its key properties and custom attributes.
 *
 *                If the building does not contain the "BuildingTemplate" attribute, it returns `nil` 
 *                to prevent saving an invalid or unrecognized object by the load functions.
 *
 * @Building - (BasePart) The part to be turned into a table.
 * @PlayerPlot - (BasePart) The origin part used to calculate the relative CFrame. Should be center of land building is on
 *
 * @return -  Returns nil or a table containing the following:
 *           - buildingType: string ("basepart")
 *           - CFrame: table {x, y, z, rotX, rotY, rotZ}
 *           - properties: table of BasePart properties
 *           - attributes: table of custom attributes from the part

]]
local function SaveBasePart(Building: BasePart, PlayerPlot: BasePart): {}?
	--check if building template attribute exists
	if not Building:GetAttribute("BuildingTemplate") then
		warn("BuildingTemplate attribute does not exist on", Building.Name)
		return nil
	end
	
	--add relative cframe element
	local relativeCFrame: CFrame = PlayerPlot.CFrame:ToObjectSpace(Building.CFrame) 
	local xAngle: number, yAngle: number, zAngle: number = relativeCFrame:ToEulerAnglesXYZ()
	local relCframeTable: table = {relativeCFrame.Position.X, relativeCFrame.Position.Y, relativeCFrame.Position.Z, xAngle, yAngle, zAngle}
	
	--add building properties
	local propertiesTable: table = {}
	for propertyName, propertyValue in getBasePartProperties(Building) do
		if propertyValue ~= nil then
			propertiesTable[propertyName] = propertyValue
		end
	end
	
	--add building attributes
	local attributesTable: table = {}
	for attributeName, attributeValue in Building:GetAttributes() do
		if attributeName ~= nil then
			attributesTable[attributeName] = attributeValue
		end
	end
	local buildingData: table = {buildingType = "basepart", CFrame = relCframeTable, properties = propertiesTable, attributes = attributesTable}
	return buildingData
end

--For documentation, please refer to SaveBasePart function as both are nearly identical
local function SaveModel(Building: Model, PlayerPlot: BasePart): {}?
	--check if building template attribute exists
	if not Building:GetAttribute("BuildingTemplate") then
		warn("BuildingTemplate attribute does not exist on", Building.Name)
		return nil
	end

	--add relative cframe element
	local relativeCFrame: CFrame = PlayerPlot.CFrame:ToObjectSpace(Building:GetPrimaryPartCFrame())
	local xAngle: number, yAngle: number, zAngle: number = relativeCFrame:ToEulerAnglesXYZ()
	local relCframeTable: table = {relativeCFrame.Position.X, relativeCFrame.Position.Y, relativeCFrame.Position.Z, xAngle, yAngle, zAngle}

	--add building properties
	local propertiesTable: table = {}
	for propertyName, propertyValue in getBasePartProperties(Building.PrimaryPart) do
		if propertyValue ~= nil then
			propertiesTable[propertyName] = propertyValue
		end
	end

	--add building attributes
	local attributesTable: table = {}
	for attributeName, attributeValue in Building:GetAttributes() do
		if attributeName ~= nil then
			attributesTable[attributeName] = attributeValue
		end
	end
	local buildingData: table = {buildingType = "model", CFrame = relCframeTable, properties = propertiesTable, attributes = attributesTable}
	return buildingData
end


--[[
 * SaveBuildings - Saves and removes all buildings within a player's plot of land. Each buildings 
data is stored as primitive vlaues into a table and then replaces the existing building data in the players session data

 *NOTE: Buildings must be either a BasePart or a Model with a PrimaryPart.
 *
 *
 * @Player - (Player) The player whose buildings are being saved.
 * @PlayerPlot - (BasePart) The plot of land that belongs to the player
 *
 * @return - (boolean) Returns `true` if all buildings were successfully saved and stored in the 
 *                     session data for the player. Returns `false` if any building fails to be saved.
]]
function BuildingDataManager:SaveBuildings(Player: Player, PlayerPlot: BasePart): boolean
	local playerData: table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	local playerBuildingData: table = {}
	local playerPlotFolder: Folder = workspace.PlayersWorkspace[Player.Name].PlayerPlots.PlayerPlot
	for _,building in playerPlotFolder:GetChildren() do
		local buildingSaved: boolean = false
		if building.Name == "PlayerPlotTemplate" then
			buildingSaved = true

		elseif building:IsA("BasePart") then
			local buildingData: table = SaveBasePart(building, PlayerPlot)
			if buildingData then
				table.insert(playerBuildingData, buildingData)
				buildingSaved = true
			end
			building:Destroy()
		
		elseif building:IsA("Model") then
			if building.PrimaryPart then
				local buildingData: table = SaveModel(building, PlayerPlot)
				if buildingData then
					table.insert(playerBuildingData, buildingData)
					buildingSaved = true
				end
			end
			building:Destroy()
		
		else
			warn("building type not recognised for", building.buildingName, "Please ensure that it is a baseplate or model containing a primary part")
		end
		if not buildingSaved then
			warn("an error occured when attempting to save building", building.buildingName, "Please ensure that it is a baseplate or model containing a primary part")
			return false	
		end
	end
	playerData.Base = playerBuildingData
	return SessionDataManagerInstance:SetPlayerData(Player.UserId, playerData)
end


--[[
 * LoadBasePart - creates and places a building on the playerplot using the provided
 *                BuildingData table. It clones the corresponding building template from 
 *                ReplicatedStorage/Buildings and applies its cframe, attributes, and properties
 * 				
 This function is typically used when loading buildings from saved session data.
 *
 *NOTE: If the BuildingType attribute is not in the table or dosent exist in replicated storage/Buildings,the function will return false and the building will not be placed.
 *
 * @PlayerPlot - (BasePart) The plot where the buildings will be loaded.
 * @BuildingData - (table) A table containing data about the building, including:
 *                 - CFrame: Relative position and rotation stored as a table of 6 numbers.
 *                 - properties: Dictionary of primitive-stored BasePart properties.
 *                 - attributes: Dictionary of custom attributes to assign.
 					- buildingType: a string that can be "model" or "basepart"
 *
 * @return -Returns true if the building was successfully created and placed. Other wise false
]]
local function LoadBasePart(PlayerPlot: BasePart, BuildingData: table): boolean
	--creeate string version of table to print when something goes wrong
	local tableString = table.concat(BuildingData, "/")
	--check if building template attribute exists
	local buildingTemplate: string = BuildingData.attributes.BuildingTemplate
	if not buildingTemplate then
		warn("BuildingTemplate attribute does not exist on: ", tableString)
		return false
	end 
	
	-- Check if the building template exists in ReplicatedStorage
	local buildings: Folder = ReplicatedStorage:FindFirstChild("Buildings")
	local buildingToClone: BasePart = buildings:FindFirstChild(buildingTemplate, true)
	if not buildingToClone then
		warn("Building template not found: ", tableString)
		return false
	end
	local newBuilding: BasePart = buildingToClone:Clone()
	
	-- Create CFrames from data and apply them to the building relative to playplot
	local relCframe: table = BuildingData.CFrame
	local relativeCFrame: CFrame = CFrame.new(relCframe[1], relCframe[2], relCframe[3])
		* CFrame.Angles(math.rad(relCframe[4] or 0), math.rad(relCframe[5] or 0), math.rad(relCframe[6] or 0))
	newBuilding.CFrame = CFrame.new(PlayerPlot.Position) * relativeCFrame

	if BuildingData.properties then
		for propertyName, propertyValue in pairs(BuildingData.properties) do
			if propertyValue ~= nil then
				setBasePartProperty(newBuilding, propertyName, propertyValue)
			end
		end
		newBuilding.Anchored = true --just to be sure
	end

	if BuildingData.attributes then
		for attributeName, attributeValue in pairs(BuildingData.attributes) do
			if attributeValue ~= nil then
				newBuilding:SetAttribute(attributeName, attributeValue)
			end
		end
	end
	
	newBuilding.Parent = PlayerPlot.Parent
	return true
end

--Similar to LoadBasePart so view documentation for that.
local function LoadModel(PlayerPlot: BasePart, BuildingData: table): boolean
	--creeate string version of table to print when something goes wrong
	local tableString = table.concat(BuildingData, "/")
	--check if building template attribute exists
	local buildingTemplate: string = BuildingData.attributes.BuildingTemplate
	if not buildingTemplate then
		warn("BuildingTemplate attribute does not exist on: ", tableString)
		return false
	end 

	-- Check if the building template exists in ReplicatedStorage
	local buildings: Folder = ReplicatedStorage:FindFirstChild("Buildings")
	local buildingToClone: Model = buildings:FindFirstChild(buildingTemplate, true)
	if not buildingToClone then
		warn("Building template not found: " .. tableString)
		return false
	end
	local newBuilding: Model = buildingToClone:Clone()

	-- Create CFrames from data and apply them to the building relative to playplot
	local relCframe: table = BuildingData.CFrame
	local relativeCFrame: CFrame = CFrame.new(relCframe[1], relCframe[2], relCframe[3])
		* CFrame.Angles(math.rad(relCframe[4] or 0), math.rad(relCframe[5] or 0), math.rad(relCframe[6] or 0))
	newBuilding:SetPrimaryPartCFrame(CFrame.new(PlayerPlot.Position) * relativeCFrame)
	if BuildingData.properties then
		for propertyName, propertyValue in pairs(BuildingData.properties) do
			if propertyValue ~= nil then
				setBasePartProperty(newBuilding.PrimaryPart, propertyName, propertyValue)
			end
		end
		newBuilding.PrimaryPart.Anchored = true --just to be sure
	end

	if BuildingData.attributes then
		for attributeName, attributeValue in pairs(BuildingData.attributes) do
			if attributeValue ~= nil then
				newBuilding:SetAttribute(attributeName, attributeValue)
			end
		end
	end


	newBuilding.Parent = PlayerPlot.Parent
	return true
end

--[[
 * LoadBuildings - Loads the buildings stored in a player's data table and places them at the specified PlayerPlot.
 *
 * @player - (Player) The player whose buildings need to be loaded.
 * @PlayerPlot - (CFrame) The plot of land in which the buildings will be placed on
 * 
 * @return - True if all buildings in players session data were able to be placed. Returns flase if any building was unable to be placed. 
]]
function BuildingDataManager:LoadBuildings(Player: Player, PlayerPlot: BasePart): boolean
	local playerData: table = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	for _, building in pairs(playerData.Base) do
		local buildingMade: boolean = false
		if building.buildingType == "basepart" then
			buildingMade = LoadBasePart(PlayerPlot, building)
		elseif building.buildingType == "model" then
			buildingMade = LoadModel(PlayerPlot, building)
		else
			warn("building type not recognised")
		end
		if not buildingMade then
			warn("an error occured when attempting to load building: ", building, ". This building will not be saved")
		end
	end
	return true
end


return BuildingDataManager
