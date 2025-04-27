--[[ObjectGeneration - Handles spawning items in terrain]]
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local __BasePlate = workspace:FindFirstChild("Baseplate") 

local ObjectGeneration = {}
Object:Supersedes(ObjectGeneration)

--Constructor where the only parameter is the name of the instance
function ObjectGeneration.new(Name) 
	local self = Object.new(Name)
	setmetatable(self, ObjectGeneration)  
	return self
end

--[[
 * shouldSpawnItem - Determines if an item should spawn based on its probability of spawning.
 * 
 * @probability - A float between 0.00 and 1 that represents the probability of the item spawning when the function is called.
 * For example: 0.5 = 50% chance of spawning.
 * 
 * @return - boolean - Returns true if the item should spawn. Otherwise returns false.
]]
local function ShouldSpawnItem(Probability: number): boolean
	local randomNumber = math.random(0.01, 1.00)
	return randomNumber <= Probability
end

--[[
 * IsPartAtPosition - Checks if any part of an object is at a given position, excluding certain objects
 * like the terrain where the item spawns on and the baseplate. Also checks if item will spawn in any of the player plots. This is useful to detect if other items 
 * like trees or buildings are present at the spawn position.
 * 
 * @position - The position (Vector3) where the check will be performed.
 * @terrain - The terrain (Instance) in which the item will spawn, which will be excluded from the check.
 * 
 * @return - boolean - Returns true if one or more parts are found at the position (excluding terrain, 
 *                     spawn location, and base plate), and if the position is within the area of where a playerplot spawns.Otherwise returns false.
]]
local function IsPartAtPosition(Position: Vector3, Terrain: Instance): boolean
	local playerPlots: BasePart = workspace.PlotRootParts:GetDescendants()
	local playerPlotXSize: number = game.ServerStorage.PlayerPlot.PlayerPlotTemplate.Size.X
	local playerPlotZSize: number = game.ServerStorage.PlayerPlot.PlayerPlotTemplate.Size.Z
	for _,playerPlot: BasePart in ipairs(playerPlots) do
		local xUpperBound: number = playerPlot.Position.X + playerPlotXSize/2
		local xLowerBound: number = playerPlot.Position.X - playerPlotXSize/2
		local zUpperBound: number = playerPlot.Position.Z + playerPlotZSize/2
		local zLowerBound: number = playerPlot.Position.Z - playerPlotZSize/2
		if (Position.X < xUpperBound and Position.Z < zUpperBound and Position.X > xLowerBound and Position.Z > zLowerBound) then
			return true
		end
	end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { Terrain, __BasePlate }

	local parts = workspace:GetPartBoundsInBox(CFrame.new(Position), Vector3.one * 0.5, overlapParams)
	return #parts > 0
end

--[[
 * FindValidSpawnHeight - Casts a downward ray from a high y position at the given X and Z coordinates. 
 * If the ray hits the terrain and no part is already occupying that position, it returns the position.
 * This function will attempt to  makes up to 30 attempts to find a valid spawn location.
 * 
 * @X - The X coordinate (number) of the desired spawn location.
 * @Z - The Z coordinate (number) of the desired spawn location.
 * @Terrain - The terrain (Instance) in which the item will spawn on.
 * 
 * @return - Vector3 or nil - Returns the valid spawn location as a Vector3 if found, otherwise returns nil.
]]
local function FindValidSpawnHeight(X: number, Z: number, Terrain: Instance): Vector3?
	--set up ray
	local raycastParams: RaycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { Terrain }
	local origin: Vector3 = Vector3.new(X, 690, Z)
	local direction: Vector3 = Vector3.new(0, -2000, 0) -- Goes directly downward
	local ray: Workspace = workspace:Raycast(origin, direction, raycastParams)
	--spawn item when ray hits terrain floor
	if ray then
		local spawnLocation: Vector3 = ray.Position
		--if item exists at spawn location, regenerate new spawn location
		if not IsPartAtPosition(spawnLocation, Terrain) then
			return ray.Position 
		end
	end
	return nil
end

--Similar to SpawnItemAtRandom so view that documentation--
local function SpawnToolOrModelAtRandom(
	CenterX: number,
	CenterZ: number,
	AreaLength: number,
	AreaWidth: number,
	ItemToSpawn: Model | Tool,
	Terrain: Instance,
	SpawnDelay: number,
	SpawnChance: number
): ()
	while true do
		task.wait(SpawnDelay)
		if ShouldSpawnItem(SpawnChance) then
			local success: boolean = false
			for attempt = 1, 5 do
				local x: number = math.random(CenterX - (AreaLength / 2), CenterX + (AreaLength / 2))
				local z: number = math.random(CenterZ - (AreaWidth / 2), CenterZ + (AreaWidth / 2))
				local spawnLocation: Vector3? = FindValidSpawnHeight(x, z, Terrain)
				if spawnLocation then
					local spawnedItem: Model | Tool = ItemToSpawn:Clone()
					spawnedItem:SetPrimaryPartCFrame(CFrame.new(spawnLocation))
					spawnedItem.Parent = workspace
					success = true
					break
				end
			end
			if not success then
				warn("Error to many attempts to spawn ", ItemToSpawn.Name, " that failed")
			end
		end
	end
end

--Similar to SpawnItemAtRandom so view that documentation--
local function SpawnBasePartAtRandom(
	CenterX: number,
	CenterZ: number,
	AreaLength: number,
	AreaWidth: number,
	ItemToSpawn: BasePart,
	Terrain: Instance,
	SpawnDelay: number,
	SpawnChance: number
): ()
	while true do
		task.wait(SpawnDelay)
		if ShouldSpawnItem(SpawnChance) then
			local success: boolean = false
			for attempt = 1, 5 do
				local x: number = math.random(CenterX - (AreaLength / 2), CenterX + (AreaLength / 2))
				local z: number = math.random(CenterZ - (AreaWidth / 2), CenterZ + (AreaWidth / 2))
				local spawnLocation: Vector3? = FindValidSpawnHeight(x, z, Terrain)
				if spawnLocation then
					local spawnedItem: BasePart = ItemToSpawn:Clone()
					spawnedItem.Position = spawnLocation
					spawnedItem.Parent = workspace
					success = true
					break
				end
			end
			if not success then
				warn("Error to many attempts to spawn item that failed")
			end
		end
	end
end
	

--[[
 * SpawnItemAtRandom - Spawns a given item at a random location within a specified area on the terrain floor.
 * The item has a specified chance of spawning every n seconds.
 * The function uses raycasting to ensure that the item spawns on the terrain floor, regardless of the y-position 
 * of the terrain, and checks if the position is clear of other items before spawning.
 * 
 * @centerX - The x-coordinate of the center of the spawning area (number). Usually found via terrain.Position.X
 * @centerZ - The z-coordinate of the center of the spawning area (number). Usually found via terrain.Position.Z
 * @areaLength - The length of the spawning area (number). Usually found via terrain.size.X
 * @areaWidth - The width of the spawning area (number). Usually found via terrain.size.z
 * @itemToSpawn - The item to spawn, which can be any Object (Model/Tool).
 * @terrain - The terrain object in which the item will spawn. This refers to the terrain floor and will be used to 
 *            determine where the item is placed.
 * @spawnDelay - The delay in seconds between each potential spawn (number).
 * @spawnChance - The chance that the item will spawn on each delay (number between 0.01 and 1.00).
 * 
 * @return - Boolean. This function returns true if it calls one of the functions to start the random spawning and they end. Otherwise it will return false 
 * 
 * Notes:
 * - This function uses raycasting to ensure that the item spawns on the terrain floor, regardless of the terrain's 
 *   current y-position.
 * - The function checks if there are any other parts at the spawn location using `IsPartAtPosition`. If other parts 
 *   (like trees or buildings) are detected, it will regenerate the spawn location.
 * - If the item is a tool, it must have a PrimaryPart in order to be positioned correctly. If a tool does not have 
 *   a PrimaryPart, the program will return false.
 * 
 * Example usage:
 * ObjectGeneration:SpawnItemAtRandom(0, 0, 50, 50, someItem, terrain, 5, 50)
 * This will attempt to spawn `someItem` within a 50x50 area centered at (0, 0) on the terrain, 
 * with a 50% chance every 5 seconds.
]]
function ObjectGeneration:SpawnItemAtRandom(
	CenterX: number,
	CenterZ: number,
	AreaLength: number,
	AreaWidth: number,
	ItemToSpawn: Object,
	Terrain: Instance,
	SpawnDelay: number,
	SpawnChance: number
): boolean
	if ItemToSpawn:IsA("Tool") or ItemToSpawn:IsA("Model") then
		if ItemToSpawn.PrimaryPart then
			SpawnToolOrModelAtRandom(
				CenterX,
				CenterZ,
				AreaLength,
				AreaWidth,
				ItemToSpawn,
				Terrain,
				SpawnDelay,
				SpawnChance
			)
			return true
		else
			warn("Error: ", ItemToSpawn.Name, " needs to posses a primary part in order to use SpawnItemAtRandom")
			return false
		end
	elseif ItemToSpawn:IsA("BasePart") then
		SpawnBasePartAtRandom(
			CenterX,
			CenterZ,
			AreaLength,
			AreaWidth,
			ItemToSpawn,
			Terrain,
			SpawnDelay,
			SpawnChance
		)
		return true
	else
		warn("Error: ", ItemToSpawn.Name, " needs to be a tool, model, or basepart in order to use SpawnItemAtRandom")
		return false
	end
end

--[[
 * isFarEnough - Checks if a point (x, z) is at least `minSpacing` distance from all existing spawn points.
 * 
 * @x - The x-coordinate of the new spawn point to check (number).
 * @z - The z-coordinate of the new spawn point to check(number).
 * @spawnPoints - A table of existing spawn points (table of Vector3).
 * @minRadius - The minimum distance between the new point and existing points (number).
 * 
 * @return - Returns `true` if the point is far enough, `false` otherwise.
]]
local function IsFarEnough(X: number, Z: number, SpawnPoints: table, MinRadius: number): boolean
	for _, point in pairs(SpawnPoints) do
		local dx: number = point.x - X
		local dz: number = point.z - Z
		if math.sqrt(dx * dx + dz * dz) < MinRadius then
			return false
		end
	end
	return true
end


--[[
 * poisonDiscSampling - Generates spaced-out spawn locations within a given area.
 * 
 * @params - The x-coordinate of the center of the spawn area (number).
 * @centerZ - The z-coordinate of the center of the spawn area (number).
 * @areaLength - The length of the spawn area (number).
 * @areaWidth - The width of the spawn area (number).
 * @terrain - The terrain instance  (Instance).
 * @numOfItems - The number of spawn points to generate (number).
 * 
 * @return - A table of Vector3 values representing valid spawn locations on the terrain.
 * 
 * Notes:
 * - The minRadius value is set at 6 but could be changed to space out the distance between points even more, although this isnt recommended and may lead to less points being found than intended.
]]
local function PoisonDiscSampling(CenterX: number, CenterZ: number, AreaLength: number, AreaWidth: number, Terrain: Instance, NumOfItems: number): { Vector3 }?

	local minRadius: number = 6  -- Minimum distance between spawn points
	local spawnPoints: {} = {} 
	local maxAttempts: number = 5000
	local attempts: number = 0

	while #spawnPoints < NumOfItems and attempts < maxAttempts do
		attempts += 1
		local randX: number = CenterX - AreaLength / 2 + math.random() * AreaLength
		local randZ: number = CenterZ - AreaWidth / 2 + math.random() * AreaWidth

		if IsFarEnough(randX, randZ, spawnPoints, minRadius) then
			local spawnPoint: Vector3? = FindValidSpawnHeight(randX, randZ, Terrain)
			if spawnPoint then
				table.insert(spawnPoints, spawnPoint)
			end
		end
	end
	return spawnPoints
end


--[[
 * SpawnItemsAtOnce - Spawns a given number of items across a terrain area using procedural generation.
 * The function uses Poisson Disc Sampling to determine valid spawn points that are evenly spaced and random,
 * similar to how trees are distributed in Minecraft.
 * Raycasting is used to align each item with the terrain floor.
 * 
 * @centerX - The x-coordinate of the center of the spawning area (number). Usually found via terrain.Position.X
 * @centerZ - The z-coordinate of the center of the spawning area (number). Usually found via terrain.Position.Z
 * @areaLength - The length of the spawning area (number). Usually found via terrain.Size.X
 * @areaWidth - The width of the spawning area (number). Usually found via terrain.Size.Z
 * @itemToSpawn - The item to spawn, which can be a Model, Tool, pr BasePart. If a model or tool, the item must have a PrimaryPart.
 * @terrain - The terrain object on which the items will be spawned on.
 * @numOfItems - The number of items to spawn across the terrain (number).
 * 
 * @return - Boolean. Returns true if all items were successfully spawned.
 *           Returns false if an error occurs — e.g., failed point generation, missing PrimaryPart, or raycast failure.
 *           An appropriate warning is printed to describe the issue.
 * 
 * Notes:
 * - This function uses raycasting to align each spawned item to the surface of the terrain.
 *
 * Example usage:
 * ObjectGeneration:SpawnItemsAtOnce(Terrain.Position.X, Terrain.Position.Z, Terrain.Size.X,	Terrain.Size.Z, treeModel, Terrain, 25)
 * This will attempt to spawn 25 instances of `treeModel` randomly over the area of the terrain
]]
function ObjectGeneration:SpawnItemsAtOnce(
	CenterX: number,
	CenterZ: number,
	AreaLength: number,
	AreaWidth: number,
	ItemToSpawn: Model | Tool,
	Terrain: Instance,
	NumOfItems: number
): boolean
	if ItemToSpawn:IsA("Tool") or ItemToSpawn:IsA("Model") then
		if ItemToSpawn.PrimaryPart then
			local points: table = PoisonDiscSampling(CenterX, CenterZ, AreaLength, AreaWidth, Terrain, NumOfItems)
			print("number of ", ItemToSpawn.Name, "spawned: ", #points)
			for _,point in pairs(points) do
				local spawnedItem: Model | Tool = ItemToSpawn:Clone()
				local itemAngles: CFrame = spawnedItem:GetPrimaryPartCFrame() - spawnedItem.PrimaryPart.Position
				local spawnedCFrame: CFrame = CFrame.new(point) * itemAngles
				spawnedItem:SetPrimaryPartCFrame(spawnedCFrame)
				spawnedItem.PrimaryPart.Anchored=true
				spawnedItem.Parent = workspace.Terrain
			end
		else
			warn("Error: ", ItemToSpawn.Name, " needs to posses a primary part in order to use SpawnItemsAtOnce")
			return false
		end
		
	elseif ItemToSpawn:IsA("BasePart") then
		local points: {} = PoisonDiscSampling(CenterX, CenterZ, AreaLength, AreaWidth, Terrain, NumOfItems)
		for _,point in pairs(points) do
			local spawnedItem: BasePart = ItemToSpawn:Clone()
			local itemAngles: CFrame = spawnedItem:GetPrimaryPartCFrame() - spawnedItem.PrimaryPart.Position
			local spawnedCFrame: CFrame = CFrame.new(point) * itemAngles
			spawnedItem.CFrame = CFrame.new(spawnedCFrame)
			spawnedItem.Anchored = true
			spawnedItem.Parent = workspace.Terrain
		end
		
	else
		warn("Error: ", ItemToSpawn.Name, " needs to be a tool, model, or basepart in order to use SpawnItemsAtOnce")
		return false
	end
	return true
end

return ObjectGeneration
