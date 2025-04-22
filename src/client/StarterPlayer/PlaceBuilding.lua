--[[
Module to handle the process of placing a building model on a player's designated plot in the game world.
This includes mouse-based placement, keyboard/touchscreen controls, and raycasting.
--NOTE: this must be called from the client in order to work
]]

--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlaceBuilding = {}
Object:Supersedes(PlaceBuilding)

--Constructor
function PlaceBuilding.new(Name)
	local self = Object.new(Name)
	setmetatable(self, PlaceBuilding)
	return self
end

--[[
 * IsPartAtPosition - Checks if any part of an object is at a given position to avoid collisions, this excludes certain objects
 * like the land where the building is placed on, the spawn location, and the base plate. This is useful to detect if other buildings 
 * are present at the spawn position.
 * 
 * @position - The position (Vector3) where the check will be performed.
 * @PlacingOn - The land (Instance) in which the item will spawn, which will be excluded from the check.
 * @Placing - The building (Basepart or Model) being placed whcih will will be excluded from the search

 * @return - boolean - Returns true if one or more parts are found at the position (excluding terrain, 
 *                     spawn location, and base plate), otherwise returns false.
]]
local function IsPartAtPosition(Position: Vector3, PlacingOn: Instance, Placing: BasePart | Model): boolean
	local overlapParams = OverlapParams.new()
	local spawnLocation = workspace:FindFirstChild("SpawnLocation") -- Retrieve SpawnLocation
	local basePlate = workspace:FindFirstChild("Baseplate") -- Retrieve Baseplate

	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { PlacingOn, Placing, spawnLocation, basePlate }
	local parts = workspace:GetPartBoundsInBox(CFrame.new(Position), Vector3.one * 0.2, overlapParams)
	return #parts > 0
end

--[[
 * FindValidSpawnHeight - Casts a downward ray from a high y position at the given X and Z coordinates. 
 * If the ray hits the land and no part is already occupying that position, it returns the position.
 * 
 * @X - The X coordinate (number) of the desired spawn location.
 * @Z - The Z coordinate (number) of the desired spawn location.
 * @PlacingOn - The land (Instance) in which the item will spawn on.
 * @Placing - The building (Basepart or Model) being placed whcih will hold significance for the helper function
 * 
 * @return - Vector3 or nil - Returns the valid spawn location as a Vector3 if found, otherwise returns nil.
]]
local function FindValidSpawnHeight(X: number, Z: number, PlacingOn: Instance, Placing: BasePart | Model): Vector3?
	--set up ray
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { PlacingOn }
	local origin: Vector3 = Vector3.new(X, 690, Z)
	local direction: Vector3 = Vector3.new(0, -2000, 0) -- Goes directly downward
	local ray: Workspace = workspace:Raycast(origin, direction, raycastParams)
	--spawn item when ray hits terrain floor
	if ray then
		local spawnLocation: Vector3 = ray.Position
		--if item exists at spawn location, regenerate new spawn location
		if not IsPartAtPosition(spawnLocation, PlacingOn, Placing) then
			return ray.Position
		end
	end
	return nil
end

--[[
helper function to handle the placement of a model (building) on a player's plot, allowing continuous tracking of the mouse position and building controls via keyboard and mouse.

@param PlacingOn (BasePart) - The part of the land (typically the player's designated "PlayerPlot") where the building is placed on.
@param Placing (Model) - The model (building) being placed.
@param Player (Player) - The player who is placing the building.

returns boolean - Returns true if the building was successfully placed. Returns false if the placement was canceled or failed due to errors.
--]]
local function PlaceModel(PlacingOn: BasePart, Placing: Model, Player: Player): boolean
	--clone building and set up ray for contant model tracking
	local buildingToPlace: Model = Placing:Clone()
	buildingToPlace.Parent = workspace.PlayersWorkspace[Player.Name].PlayerPlots.PlayerPlot

	for _, child in ipairs(buildingToPlace:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Transparency = 0.35
			child.CanCollide = false
		end
	end

	local ContextActionService = game:GetService("ContextActionService")
	local mouse = Player:GetMouse()
	local runService = game:GetService("RunService")
	local buildingPlaced: boolean = false
	local endLoop: boolean = false
	local x: number, y: number, z: number = buildingToPlace:GetPrimaryPartCFrame():ToEulerAnglesXYZ()
	local buildingOrientation: Vector3 = Vector3.new(x, y, z)

	local moveBuildingWithMouse = runService.RenderStepped:Connect(function()
		mouse.TargetFilter = buildingToPlace
		local placementPosition: Vector3 = mouse.Hit.Position
		buildingToPlace:SetPrimaryPartCFrame(
			CFrame.new(placementPosition)
				* (CFrame.fromEulerAnglesXYZ(buildingOrientation.X, buildingOrientation.Y, buildingOrientation.Z))
		)
	end)

	--[[
	nested helper function to handle the confirmation of building placement when the mouse is clicked.
	Checks if the building is within the bounds of the player plot and if there are no other buildings at the location.
	Uses ray casting to find the correct height to place the building.

	@param - no significance. action name set in context acction service binding 

	returns void - This function does not return anything but modifies flags related to placement success and completion.
	--]]
	local function ConfirmPlace(acitonName: string, inputState: Enum)
		if acitonName == "PlaceBuilding" and inputState == Enum.UserInputState.Begin then
			local canPlace = true
			local modelCFrame: Vector3, modelSize: number = buildingToPlace:GetBoundingBox()
			--check if all model corners in x-z plane are within the bounds of the player plot
			local corners: { Vector3 } = {}
			table.insert(corners, Vector3.new((modelCFrame.X + modelSize.X / 2), 0, (modelCFrame.Z + modelSize.Z / 2)))
			table.insert(corners, Vector3.new((modelCFrame.X + modelSize.X / 2), 0, (modelCFrame.Z - modelSize.Z / 2)))
			table.insert(corners, Vector3.new((modelCFrame.X - modelSize.X / 2), 0, (modelCFrame.Z + modelSize.Z / 2)))
			table.insert(corners, Vector3.new((modelCFrame.X - modelSize.X / 2), 0, (modelCFrame.Z - modelSize.Z / 2)))
			for _, corner in ipairs(corners) do
				if
					(corner.X > PlacingOn.Position.X + PlacingOn.Size.X / 2)
					or (corner.X < PlacingOn.Position.X - PlacingOn.Size.X / 2)
					or (corner.Z > PlacingOn.Position.Z + PlacingOn.Size.Z / 2)
					or (corner.Z < PlacingOn.Position.Z - PlacingOn.Size.Z / 2)
				then
					canPlace = false
				end
			end
			if canPlace then
				--check if other buildings exist at location as well as the height to place the building
				local buildingPosition: Vector3 =
					FindValidSpawnHeight(modelCFrame.X, modelCFrame.Z, PlacingOn, buildingToPlace)
				if buildingPosition then
					--Spawn model in location
					for _, child in ipairs(buildingToPlace:GetDescendants()) do
						if child:IsA("BasePart") then
							child.Transparency = 0
							child.CanCollide = true
						end
					end
					buildingToPlace:SetPrimaryPartCFrame(CFrame.new(buildingPosition))
					buildingPlaced = true
					endLoop = true
				else
					canPlace = false
				end
			end
			if not canPlace then
				--make building appear red for a moment
				local colorsToRemember = {}
				for _, child in ipairs(buildingToPlace:GetDescendants()) do
					if child:IsA("BasePart") then
						colorsToRemember[child] = child.Color
						child.Color = Color3.fromRGB(255, 0, 0)
					end
				end

				task.wait(1)

				for part, color in pairs(colorsToRemember) do
					part.Color = color
				end
			end 
		end
	end

	--[[
	nested helper function to handle the cancellation of building placement when the Cancel key is pressed.
	Sets the buildingPlaced flag to false and ends the placement process.

	@param - no significance. action name set in context acction service binding 

	returns void - This function does not return anything but modifies flags to stop the building placement process.
	--]]
	local function CancelPlace(acitonName: string, inputState: Enum)
		if acitonName == "CancelPlacement" and inputState == Enum.UserInputState.Begin then
			buildingPlaced = false
			endLoop = true
		end
	end

	--[[
	function to handle the rotation of the building when the Rotate key is pressed by Rotating the building by 90 degrees around the Y-axis.

	@param - no significance. action name set in context acction service binding 

	returns void 
	--]]
	local function RotateBuilding(acitonName: string, inputState: Enum)
		if acitonName == "RotateBuilding" and inputState == Enum.UserInputState.Begin then
			buildingOrientation = buildingOrientation + Vector3.new(0, math.pi * 0.5, 0)
		end
	end

	ContextActionService:BindAction("PlaceBuilding", ConfirmPlace, true, Enum.UserInputType.MouseButton1)
	ContextActionService:SetTitle("PlaceBuilding", "Place")
	ContextActionService:SetPosition("PlaceBuilding", UDim2.new(-0.85, 0, -1, 0))

	ContextActionService:BindAction("CancelPlacement", CancelPlace, true, Enum.KeyCode.C)
	ContextActionService:SetTitle("CancelPlacement", "Cancel")
	ContextActionService:SetPosition("CancelPlacement", UDim2.new(-0.65, 0, -1, 0))

	ContextActionService:BindAction("RotateBuilding", RotateBuilding, true, Enum.KeyCode.R)
	ContextActionService:SetTitle("RotateBuilding", "Rotate")
	ContextActionService:SetPosition("RotateBuilding", UDim2.new(-1, 0, -1, 0))
	while not endLoop do
		task.wait()
	end
	ContextActionService:UnbindAction("PlaceBuilding")
	ContextActionService:UnbindAction("CancelPlacement")
	ContextActionService:UnbindAction("RotateBuilding")
	if not buildingPlaced then
		buildingToPlace:Destroy()
	end
	if moveBuildingWithMouse then
		moveBuildingWithMouse:Disconnect()
	end

	return buildingPlaced
end

--same documentation as function above except this one if for placing a basepart instead of a model
local function PlaceBasePart(PlacingOn: BasePart, Placing: BasePart, Player: Player): boolean
	--clone building and set up ray for contant model tracking
	local buildingToPlace: BasePart = Placing:Clone()
	buildingToPlace.Parent = workspace.PlayersWorkspace[Player.Name].PlayerPlots.PlayerPlot

	buildingToPlace.Transparency = 0.35
	buildingToPlace.CanCollide = false

	local ContextActionService = game:GetService("ContextActionService")
	local mouse = Player:GetMouse()
	local runService = game:GetService("RunService")
	local buildingPlaced: boolean = false
	local endLoop: boolean = false
	local x: number, y: number, z: number = buildingToPlace.CFrame:ToEulerAnglesXYZ()
	local buildingOrientation: Vector3 = Vector3.new(x, y, z)

	local moveBuildingWithMouse = runService.RenderStepped:Connect(function()
		mouse.TargetFilter = buildingToPlace
		local placementPosition: Vector3 = mouse.Hit.Position
		buildingToPlace.CFrame = CFrame.new(placementPosition)
			* (CFrame.fromEulerAnglesXYZ(buildingOrientation.X, buildingOrientation.Y, buildingOrientation.Z))
	end)

	local function ConfirmPlace(acitonName: string, inputState: Enum)
		if acitonName == "PlaceBuilding" and inputState == Enum.UserInputState.Begin then
			--check if all model corners in x-z plane are within the bounds of the player plot
			local corners: { Vector3 } = {}
			table.insert(
				corners,
				Vector3.new(
					(buildingToPlace.Position.X + buildingToPlace.Size.X / 2),
					0,
					(buildingToPlace.Position.Z + buildingToPlace.Size.Z / 2)
				)
			)
			table.insert(
				corners,
				Vector3.new(
					(buildingToPlace.Position.X + buildingToPlace.Size.X / 2),
					0,
					(buildingToPlace.Position.Z - buildingToPlace.Size.Z / 2)
				)
			)
			table.insert(
				corners,
				Vector3.new(
					(buildingToPlace.Position.X - buildingToPlace.Size.X / 2),
					0,
					(buildingToPlace.Position.Z + buildingToPlace.Size.Z / 2)
				)
			)
			table.insert(
				corners,
				Vector3.new(
					(buildingToPlace.Position.X - buildingToPlace.Size.X / 2),
					0,
					(buildingToPlace.Position.Z - buildingToPlace.Size.Z / 2)
				)
			)
			for _, corner in ipairs(corners) do
				if
					(corner.X > PlacingOn.Position.X + PlacingOn.Size.X / 2)
					or (corner.X < PlacingOn.Position.X - PlacingOn.Size.X / 2)
					or (corner.Z > PlacingOn.Position.Z + PlacingOn.Size.Z / 2)
					or (corner.Z < PlacingOn.Position.Z - PlacingOn.Size.Z / 2)
				then
					return
				end
			end
			--check if other buildings exist at location as well as the height to place the building
			local buildingPosition: Vector3 =
				FindValidSpawnHeight(buildingToPlace.Position.X, buildingToPlace.Position.Z, PlacingOn, buildingToPlace)
			if buildingPosition then
				--Spanw model in location
				buildingToPlace.Transparency = 0
				buildingToPlace.CanCollide = true
				buildingToPlace.CFrame = CFrame.new(buildingPosition)	
				buildingPlaced = true
				endLoop = true
			end
		end
	end

	local function CancelPlace(acitonName: string, inputState: Enum)
		if acitonName == "CancelPlacement" and inputState == Enum.UserInputState.Begin then
			buildingPlaced = false
			endLoop = true
		end
	end

	local function RotateBuilding(acitonName: string, inputState: Enum)
		if acitonName == "RotateBuilding" and inputState == Enum.UserInputState.Begin then
			buildingOrientation = buildingOrientation + Vector3.new(0, math.pi * 0.5, 0)
		end
	end

	ContextActionService:BindAction("PlaceBuilding", ConfirmPlace, true, Enum.UserInputType.MouseButton1)
	ContextActionService:SetTitle("PlaceBuilding", "Place")
	ContextActionService:SetPosition("PlaceBuilding", UDim2.new(-0.85, 0, -1, 0))

	ContextActionService:BindAction("CancelPlacement", CancelPlace, true, Enum.KeyCode.C)
	ContextActionService:SetTitle("CancelPlacement", "Cancel")
	ContextActionService:SetPosition("CancelPlacement", UDim2.new(-0.65, 0, -1, 0))

	ContextActionService:BindAction("RotateBuilding", RotateBuilding, true, Enum.KeyCode.R)
	ContextActionService:SetTitle("RotateBuilding", "Rotate")
	ContextActionService:SetPosition("RotateBuilding", UDim2.new(-1, 0, -1, 0))
	while not endLoop do
		task.wait()
	end
	ContextActionService:UnbindAction("PlaceBuilding")
	ContextActionService:UnbindAction("CancelPlacement")
	ContextActionService:UnbindAction("RotateBuilding")
	if not buildingPlaced then
		buildingToPlace:Destroy()
	end
	if moveBuildingWithMouse then
		moveBuildingWithMouse:Disconnect()
	end

	return buildingPlaced
end

--[[
handles the clients select of where to place a building in their land using their mouse and keyboard or phone touch screen.

Controls:
- Left mouse click places the building.
- "C" key cancels the placement.
- "R" key rotates the building.

@param PlacingOn (BasePart) - The part of the land (typically the player's designated "PlayerPlot") where the building is placed on.
@param Placing (BasePart | Model) - The building being placed. If a model, it must have a defined PrimaryPart, typically centered.
@param Player (Player) - The player who is placing the building.

returns boolean - Returns true if the building was successfully placed. Returns false if an error occurred or the building was not placed due to user cancellation.
--]]
function PlaceBuilding:PlaceBuilding(PlacingOn: BasePart, Placing: BasePart | Model, Player: Player): boolean
	if not PlacingOn:HasTag("PlayerPlot") then
		warn("Part to place on did not contain PlayerPlot tag: " .. PlacingOn.Name)
		return false
	end
	if Placing:IsA("Model") then
		if Placing.PrimaryPart then
			return PlaceModel(PlacingOn, Placing, Player)
		else
			warn("Model " .. Placing.Name .. " has no PrimaryPart. Cannot set CFrame.")
			return false
		end
	else
		return PlaceBasePart(PlacingOn, Placing, Player)
	end
end

return PlaceBuilding
