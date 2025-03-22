--[[ObjectGeneration - Handles spawning items in terrain]]
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local spawnLocation = workspace:FindFirstChild("SpawnLocation") -- Retrieve SpawnLocation
local basePlate = workspace:FindFirstChild("Baseplate") -- Retrieve Baseplate

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
local function ShouldSpawnItem(probability: number): boolean
	local randomNumber: number = math.random(0.01, 1.00)
	return randomNumber <= probability
end

--[[
 * IsPartAtPosition - Checks if any part of an object is at a given position, excluding certain objects
 * like the terrain where the item spawns on, the spawn location, and the base plate. This is useful to detect if other items 
 * like trees or buildings are present at the spawn position.
 * 
 * @position - The position (Vector3) where the check will be performed.
 * @terrain - The terrain (Instance) in which the item will spawn, which will be excluded from the check.
 * 
 * @return - boolean - Returns true if one or more parts are found at the position (excluding terrain, 
 *                     spawn location, and base plate), otherwise returns false.
]]
local function IsPartAtPosition(position: Vector3, terrain: Instance): boolean
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { terrain, spawnLocation, basePlate }

	local parts = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.one * 0.1, overlapParams)
	return #parts > 0
end

--[[
	Finds a valid spawn height at a given X and Z coordinate by raycasting downward to detect the terrain surface.

	@param x number - The X coordinate of the spawn attempt.
	@param z number - The Z coordinate of the spawn attempt.
	@param terrain Instance - The terrain instance to raycast against.

	@return Vector3 | nil - Returns a valid spawn position (Vector3) if found, otherwise nil.
]]
local function findValidSpawnHeight(x: number, z: number, terrain: Instance): Vector3 | nil
	for i = 1, 30 do
		--set up ray
		local raycastParams: RaycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { terrain }
		local origin: Vector3 = Vector3.new(x, 690, z)
		local direction: Vector3 = Vector3.new(0, -2000, 0) -- Goes directly downward
		local ray: Workspace = workspace:Raycast(origin, direction, raycastParams)
		--spawn item when ray hits terrain floor
		if ray then
			local spawnLocation: Vector3 = ray.Position
			--if item exists at spawn location, regenerate new spawn location
			if not IsPartAtPosition(spawnLocation, terrain) then
				return ray.Position
			end
		end
	end
	warn("Error to many attempts to find valid y position for item to spawn")
	return nil
end

local function SpawnToolOrModelAtRandom(
	centerX: number,
	centerZ: number,
	areaLength: number,
	areaWidth: number,
	itemToSpawn: Model | Tool,
	terrain: Instance,
	spawnDelay: number,
	spawnChance: number
)
	while true do
		task.wait(spawnDelay)
		if ShouldSpawnItem(spawnChance) then
			local X: number = math.random(centerX - (areaLength / 2), centerX + (areaLength / 2))
			local Z: number = math.random(centerZ - (areaWidth / 2), centerZ + (areaWidth / 2))
			local spawnLocation: Vector3 | nil = findValidSpawnHeight(X, Z, terrain)
			if spawnLocation then
				local spawnedItem: Model | Tool = itemToSpawn:Clone()
				spawnedItem:SetPrimaryPartCFrame(CFrame.new(spawnLocation))
				spawnedItem.Parent = workspace
			else
				warn("Error to many attempts to spawn item that failed")
			end
		end
	end
end

local function SpawnBasePartAtRandom(
	centerX: number,
	centerZ: number,
	areaLength: number,
	areaWidth: number,
	itemToSpawn: BasePart,
	terrain: Instance,
	spawnDelay: number,
	spawnChance: number
)
	local maxAttempts = 30
	while true do
		task.wait(spawnDelay)
		if ShouldSpawnItem(spawnChance) then
			local X: number = math.random(centerX - (areaLength / 2), centerX + (areaLength / 2))
			local Z: number = math.random(centerZ - (areaWidth / 2), centerZ + (areaWidth / 2))
			local spawnLocation: Vector3 | nil = findValidSpawnHeight(X, Z, terrain)
			if spawnLocation then
				local spawnedItem: BasePart = itemToSpawn:Clone()
				spawnedItem.position = spawnLocation
				spawnedItem.Parent = workspace
			else
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
 * @return - Boolean. This function returns true if it ends without ever hiting an exception. If an error occurs anywhere 
 * in the function, the function will return false
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
	centerX: number,
	centerZ: number,
	areaLength: number,
	areaWidth: number,
	itemToSpawn: Object,
	terrain: Instance,
	spawnDelay: number,
	spawnChance: number
)
	if itemToSpawn:IsA("Tool") or itemToSpawn:IsA("Model") then
		if itemToSpawn.PrimaryPart then
			return SpawnToolOrModelAtRandom(
				centerX,
				centerZ,
				areaLength,
				areaWidth,
				itemToSpawn,
				terrain,
				spawnDelay,
				spawnChance
			)
		else
			print("Item or Model to spawn does not posses a primary part. Please give it one")
			return false
		end
	elseif itemToSpawn:IsA("BasePart") then
		return SpawnBasePartAtRandom(
			centerX,
			centerZ,
			areaLength,
			areaWidth,
			itemToSpawn,
			terrain,
			spawnDelay,
			spawnChance
		)
	else
		error("Item passed in needs to be a tool, model, or basepart")
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
local function isFarEnough(x: number, z: number, spawnPoints: table, minRadius: number): boolean
	for _, point in pairs(spawnPoints) do
		local dx: number = point.x - x
		local dz: number = point.z - z
		if math.sqrt(dx * dx + dz * dz) < minRadius then
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
local function poisonDiscSampling(centerX, centerZ, areaLength, areaWidth, terrain, numOfItems)
	local minRadius: number = 6 -- Minimum distance between spawn points
	local spawnPoints: table = {}
	local maxAttempts: number = 100
	local attempts: number = 0

	while #spawnPoints < numOfItems and attempts < maxAttempts do
		attempts += 1
		local randX: number = centerX - areaLength / 2 + math.random() * areaLength
		local randZ: number = centerZ - areaWidth / 2 + math.random() * areaWidth

		if isFarEnough(randX, randZ, spawnPoints, minRadius) then
			local spawnPoint: Vector3 = findValidSpawnHeight(randX, randZ, terrain)
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
	centerX: number,
	centerZ: number,
	areaLength: number,
	areaWidth: number,
	itemToSpawn: any,
	terrain: Instance,
	numOfItems: number
): boolean
	if itemToSpawn:IsA("Tool") or itemToSpawn:IsA("Model") then
		if itemToSpawn.PrimaryPart then
			local points: table = poisonDiscSampling(centerX, centerZ, areaLength, areaWidth, terrain, numOfItems)
			for _, point in pairs(points) do
				local spawnedItem: Model | Tool = itemToSpawn:Clone()
				spawnedItem:SetPrimaryPartCFrame(CFrame.new(point))
				spawnedItem.Parent = workspace
			end
		else
			print("Item or Model to spawn does not posses a primary part. Please give it one")
			return false
		end
	elseif itemToSpawn:IsA("BasePart") then
		local points: table = poisonDiscSampling(centerX, centerZ, areaLength, areaWidth, terrain, numOfItems)
		for _, point in pairs(points) do
			local spawnedItem: BasePart = itemToSpawn:Clone()
			spawnedItem.Position = CFrame.new(point)
			spawnedItem.Parent = workspace
		end
	else
		error("Item passed in needs to be a tool, model, or basepart")
		return false
	end
	return true
end

return ObjectGeneration
