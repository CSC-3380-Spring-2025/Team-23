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

function SpendResourcesToBuild:AttemptToBuild(Player: Player, BuildingToBuild: Instance): boolean
	local buildingToBuildName: string = BuildingToBuild.Name
	local buildingCost: {} = BuildingRequirments:GetCostsFromName(buildingToBuildName)
	if ReplicatedStorage.Buildings:FindFirstChild(buildingToBuildName, true) and buildingCost then
		local data = SessionDataManagerInstance:GetPlayerData(Player.UserId)
		if not data then return false end
		local playerGoldCount = data.Currency.Gold
		local goldCost = buildingCost.Gold
		if goldCost <= playerGoldCount then 
			data.Currency.Gold -= goldCost
			return SessionDataManagerInstance:SetPlayerData(Player.UserId, data)
		else
			return false
		end

		
	end

end

return SpendResourcesToBuild
