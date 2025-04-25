--[[
BuildingRequirments: data table that exists to establish how many resources a buidllign will cost to make.
This should also list the amount of resources that will be given when the building is sold or scrapped. 
]]
local BuildingRequirments = {}

local __Costs = {
	Barracks = {
		BarracksLevel1 = {
			CostToBuild = {
				Gold = 10,
				Wheat = 25,
			},
			GiveFromSell = {
				Gold = 5,
				Wheat = 10,
			},
		},
		BarracksLevel2 = {
			CostToBuild = {
				Gold = 50,
				Wheat = 100,
				Iron = 15,
			},
			GiveFromSell = {
				Gold = 25,
				Wheat = 50,
				Iron = 4,
			},
		},
	},
	Farms = {
		WheatFarmLevel1 = {
			CostToBuild = {
				Gold = 5,
			},
			GiveFromSell = {
				Gold = 2,
			},
		},
		WheatFarmLevel2 = {
			CostToBuild = {
				Gold = 30,
				Wheat = 25,
			},
			GiveFromSell = {
				Gold = 15,
				Wheat = 10,
			},
		},
	},
	House = {
		HouseLevel1 = {
			CostToBuild = {
				Gold = 10,
			},
			GiveFromSell = {
				Gold = 5,
			},
		},
		HouseLevel2 = {
			CostToBuild = {
				Gold = 35,
				Wheat = 50,
				Iron = 3,
				Coal = 5,
			},
			GiveFromSell = {
				Gold = 15,
				Wheat = 10,
			},
		},
	},
	Mines = {
		CoalMineLevel1 = {
			CostToBuild = {
				Gold = 20,
			},
			GiveFromSell = {
				Gold = 3,
				Coal = 5,
			},
		},
	},
	Refinery = {
		RefineryLevel1 = {
			CostToBuild = {
				Gold = 30,
				Coal = 20,
				Iron = 1,
			},
			GiveFromSell = {
				Gold = 10,
				Coal = 5,
			},
		},
	},
}

function BuildingRequirments:GetAllCosts(): {}
	return __Costs
end

function BuildingRequirments:GetCostsFromName(Name: string): table?
	for buildingType, typeTable in pairs(__Costs) do
		for buildingName, buildingTable in pairs(typeTable) do
			if buildingName == Name then
				return buildingTable.CostToBuild
			end
		end
	end
	return nil
end

function BuildingRequirments:GetSellValueFromName(Name: string): table?
	for buildingType, typeTable in pairs(__Costs) do
		for buildingName, buildingTable in pairs(typeTable) do
			if buildingName == Name then
				return buildingTable.GiveFromSell
			end
		end
	end
	return nil
end

return BuildingRequirments
