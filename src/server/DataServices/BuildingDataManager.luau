local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local SessionDataManager = require(script.Parent.SessionDataManager)

local BuildingDataManager = {}
Object:Supersedes(BuildingDataManager) 


local SessionDataManagerInstance: table = SessionDataManager.new()


function BuildingDataManager.new(Name) --parameter that asks for Name
	local self = Object.new(Name)
	setmetatable(self, BuildingDataManager)  
	return self
end

function BuildingDataManager:loadBuildings(player: Player)
	print("implement me")
end


function BuildingDataManager:saveBuildings(player: Player)
	print("implement me")
end

return BuildingDataManager

