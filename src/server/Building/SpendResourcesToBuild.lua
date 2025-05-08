--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local StorageHandler = require(game.ServerScriptService.Server.ItemHandlers.StorageHandler)
local BuildingRequirments = require(script.Parent.BuildingRequirments)
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)

--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SpendResourcesToBuild = {}
Object:Supersedes(SpendResourcesToBuild)
local StorageHandlerInstance = StorageHandler.new("StorageHandlerInstance")
local SessionDataManagerInstance: table = SessionDataManager.new()


--Constructor that takes in no parameters
function SpendResourcesToBuild.new(Name)
	local self = Object.new(Name)
	setmetatable(self, SpendResourcesToBuild)
	return self
end

--[[
 * AttemptToBuild - Checks if a player has enough gold to place a building schematic
 * @Player (Player) - The player attempting to place the building.
 * @BuildingToBuild (Instance) - The instance of the building the player is attempting to place.The building’s name is used to look up its required gold cost.
 *
 * Returns:
 * @boolean - Returns true if the player has enough gold and the cost was successfully deducted.
 *            Returns false if the player doesn't have enough gold, if the building is invalid,
 *            or if player data could not be retrieved.
]]
function SpendResourcesToBuild:AttemptToBuild(Player: Player, BuildingToBuild: Instance): boolean
	local buildingToBuildName: string = BuildingToBuild.Name
	local buildingCost: number = BuildingRequirments:GetGoldFromName(buildingToBuildName)
	if ReplicatedStorage.Buildings:FindFirstChild(buildingToBuildName, true) and buildingCost then
		local data = SessionDataManagerInstance:GetPlayerData(Player.UserId)
		if not data then return false end
		local playerGoldCount = data.Currency.gold
		local goldCost = buildingCost
		if goldCost <= playerGoldCount then 
			data.Currency.gold -= goldCost
			return SessionDataManagerInstance:SetPlayerData(Player.UserId, data)
		else
			return false
		end		
	end

end

return SpendResourcesToBuild
