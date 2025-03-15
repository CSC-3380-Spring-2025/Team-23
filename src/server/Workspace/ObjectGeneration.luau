--[[ObjectGeneration - Handles spawning items in terrain]]
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local spawnLocation = workspace:FindFirstChild("SpawnLocation")  -- Retrieve SpawnLocation
local basePlate = workspace:FindFirstChild("Baseplate")  -- Retrieve Baseplate


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
local function shouldSpawnItem(probability: number): boolean
	local randomNumber = math.random(0.01, 1.00)
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
	print("Parts detected", parts)
	return #parts > 0
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
		if shouldSpawnItem(spawnChance) then
			local validSpawn: boolean = false
			repeat
				local X: number = math.random(centerX - (areaLength / 2), centerX + (areaLength / 2))
				local Z: number = math.random(centerZ - (areaWidth / 2), centerZ + (areaWidth / 2))
				--set up ray
				local raycastParams: RaycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }
				local origin: Vector3 = Vector3.new(X, 690, Z)
				local direction: Vector3 = Vector3.new(0, -690, 0) -- Goes directly downward
				local ray: Workspace = workspace:Raycast(origin, direction, raycastParams)
				--spawn item when ray hits terrain floor
				if ray then
					local spawnLocation: Vector3 = ray.Position
					--if item exists at spawn location, regenerate new spawn location
					if IsPartAtPosition(Vector3.new(spawnLocation), terrain) then
						validSpawn = true
					else
						local spawnedItem: Model | Tool = itemToSpawn:Clone()
						spawnedItem:SetPrimaryPartCFrame(CFrame.new(spawnLocation))
						spawnedItem.Parent = workspace
					end
				else
					print("Error: ray did not hit terrain")
					return false
				end
			until validSpawn
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
	while true do
		task.wait(spawnDelay)
		if shouldSpawnItem(spawnChance) then
			repeat
				local validSpawn: boolean = true
				local X: number = math.random(centerX - (areaLength / 2), centerX + (areaLength / 2))
				local Z: number = math.random(centerZ - (areaWidth / 2), centerZ + (areaWidth / 2))
				--set up ray
				local raycastParams: RaycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Include
				raycastParams.FilterDescendantsInstances = { terrain }
				local origin: Vector3 = Vector3.new(X, 690, Z)
				local direction: Vector3 = Vector3.new(0, -690, 0) -- Goes directly downward
				local ray: Workspace = workspace:Raycast(origin, direction, raycastParams)
				--spawn item when ray hits terrain floor
				if ray then
					local spawnLocation: Vector3 = ray.Position
					--if item exists at spawn location, regenerate new spawn location
					if IsPartAtPosition(Vector3.new(spawnLocation), terrain) then
						validSpawn = false
					else
						local spawnedItem: BasePart = itemToSpawn:Clone()
						spawnedItem.position = spawnLocation
						spawnedItem.Parent = workspace
					end
				else
					print("Error: ray did not hit terrain")
					return false
				end
			until validSpawn
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
		print("Item passed in needs to be a tool, model, or basepart")
		return false
	end
end

function ObjectGeneration:SpawnItemsAtOnce()
	--todo: implement function where n items spawn all at once in random locations aorund a given area
end

return ObjectGeneration
