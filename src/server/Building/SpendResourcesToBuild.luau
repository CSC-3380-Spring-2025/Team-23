--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local BuildingDataManager = require(game.ServerScriptService.Server.Building.BuildingDataManager)
local StorageHandler = require(game.ServerScriptService.Server.ItemHandlers.StorageHandler)
local BuildingRequirments = require(script.Parent.SpendResourcesToBuild)
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)

--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SpendResourcesToBuild = {}
Object:Supersedes(SpendResourcesToBuild)
local BuildingDataManagerInstance = BuildingDataManager.new("BuildingDataManagerInstance")
local StorageHandlerInstance = StorageHandler.new("StorageHandlerInstance")
local BuildingRequirmentsInstance = BuildingRequirments.new("BuildingRequirmentsInstance")
local SessionDataManagerInstance: table = SessionDataManager.new()


--Constructor that takes in no parameters
function SpendResourcesToBuild.new(Name)
	local self = Object.new(Name)
	setmetatable(self, SpendResourcesToBuild)
	return self
end

function SpendResourcesToBuild:AttemptToBuild(Player: Player, BuildingToBuild: Instance): boolean
	local BuildingToBuildName: string = BuildingToBuild.Name
	if ReplicatedStorage.Bulidings:FindFirstChild(BuildingToBuildName, true) and BuildingRequirmentsInstance:GetCostsFromName(BuildingToBuildName) then
		local data = SessionDataManagerInstance:GetPlayerData(Player.UserId)
		local playerGoldCount = data.Currency.Gold
		
		
	end

end

return SpendResourcesToBuild
