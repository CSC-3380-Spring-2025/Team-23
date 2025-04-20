--[[Spawn Resources - Handles spawning terrain objects like trees and ores aorund the map on server start]]
local ObjectGeneration = require(script.Parent.ObjectGeneration)
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local __SpawnLocation = workspace:FindFirstChild("SpawnLocation")  -- Retrieve SpawnLocation
local __BasePlate = workspace:FindFirstChild("Baseplate")  -- Retrieve Baseplate

local ObjectGenerationInstance = ObjectGeneration.new("ObjectGenerationInstance")
--[[
 * SpawnResources - Spawns world resources from ServerStorage onto the Baseplate using the ObjectGeneration module.
 * This function is designed to run once on server start to populate the world with various items 
 * such as lumber, ores, grass, etc., in random locations while avoiding player plot spaces and 
 * overlapping spawns.
 *
 * REQUIREMENTS & NOTES:
 * • The structure of ServerStorage.Resources must follow this format:
 *    Resources
 *      └─ [ResourceType Folder] (e.g., "Lumber", "Ores")
 *            └─ [Individual Resource Folder] (e.g., "Oak", "Coal")
 *                  • Must contain a `SpawnCount` attribute (number)
 *                  • Children must be instances of either:
 *                      - BasePart
 *                      - Model with a PrimaryPart 
 *                      - Tool
 *
 * • Invalid types (not BasePart or Model) and folder without attribute are skipped with a warning.
 * • For more information on the item spawning process, refer to ObjectGeneration script
 * @params - none
 * @return - none
]]
local function SpawnResources(): ()
	local BasePlate: BasePart = workspace.Baseplate
	local Resources = ServerStorage.Resources
	for _,folder in Resources:GetChildren() do
		for _,itemType in folder:GetChildren() do
			local spawnCount: number = itemType:GetAttribute("SpawnCount")
			if not spawnCount then
				warn(itemType, "Does not have the SpawnCount Attribute")
				continue
			end
			local itemsToSpawn: {} = {}

			for i = 1, spawnCount do
				local children: {any} = itemType:GetChildren() 
				local itemToSpawn: any = children[math.random(1, #children)]
				itemsToSpawn[itemToSpawn] = (itemsToSpawn[itemToSpawn] or 0) + 1
			end
			for item: Instance, timesToSpawn:number in pairs(itemsToSpawn) do
				if item:IsA("Model") or item:IsA("BasePart") then
					ObjectGenerationInstance:SpawnItemsAtOnce(BasePlate.Position.X,
						BasePlate.Position.Z,
						BasePlate.Size.X,
						BasePlate.Size.Z,
						item,
						BasePlate,
						timesToSpawn)
				else
					warn(item.Name, "Is not a basepart or model with a primary part and cannot be spawned in world")
				end
			end
		end
	end
end

SpawnResources()
