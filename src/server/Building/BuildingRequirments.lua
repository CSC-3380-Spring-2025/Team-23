--[[
BuildingRequirments: data table that exists to establish how many resources a buidllign will cost to make.
This should also list the amount of resources that will be given when the building is sold or scrapped. 
]]
local BuildingRequirments = {}

--[[
Table of Costs to building and what you obtain from buildigns found in replicated storage. 
The Gold attribute is the origonal amount of gold it would cost to place down the schematic of the building.
From there the CostToBUild table will be used to evaluate the progress towards a building being complete.
For a future sell feature, the GiveFromCell table will be used to determine how many resources are given to the player]]
local __Costs = {
	Barracks = {
		BarracksLevel1 = {
			Gold = 10,
			CostToBuild = {
				Wheat = 25,
			},
			GiveFromSell = {
				Gold = 5,
				Wheat = 10,
			},
		},
		BarracksLevel2 = {
			Gold = 50,
			CostToBuild = {
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
			Gold = 5,
			CostToBuild = {
				Wood = 5,
			},
			GiveFromSell = {
				Gold = 2,
			},
		},
		WheatFarmLevel2 = {
			Gold = 30,
			CostToBuild = {
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
			Gold = 10,
			CostToBuild = {
				Wood = 20,
			},
			GiveFromSell = {
				Gold = 5,
			},
		},
		HouseLevel2 = {
			Gold = 35,
			CostToBuild = {
				Wheat = 50,
				Iron = 3,
				Coal = 5,
			},
			GiveFromSell = {
				Gold = 15,
				Wheat = 10,
			},
		},
		HouseLevel3 = {
			Gold = 50,
			CostToBuild = {
				Wheat = 100,
				Iron = 15,
				Coal = 30,
			},
			GiveFromSell = {
				Gold = 35,
				Wheat = 40,
				Iron = 3,
				Coal = 12,
			},
		},
	},
	Mines = {
		CoalMineLevel1 = {
			Gold = 20,
			CostToBuild = {
				Wood = 12,
			},
			GiveFromSell = {
				Gold = 3,
				Coal = 5,
			},
		},
	},
	Refinery = {
		RefineryLevel1 = {
			Gold = 30,
			CostToBuild = {
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

--Returns the table of all building costs
function BuildingRequirments:GetAllCosts(): {}
	return __Costs
end
--[[
Searches the Costs table for the name of the building and returns the Gold value or nil if not found
@Name: the name of the building to find. Refer to buliding name or BuildingTemplate attribute to obtain it]]
function BuildingRequirments:GetGoldFromName(Name: string): table?
	for buildingType, typeTable in pairs(__Costs) do
		for buildingName, buildingTable in pairs(typeTable) do
			if buildingName == Name then
				return buildingTable.Gold
			end
		end
	end
	return nil
end
--Identical to GetGoldFromName, but returns CostToBuildTable
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

--Identical to GetGoldFromName, but returns GiveFromSell
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
