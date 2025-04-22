--Used in Data module to assign default data values to new player upon joining
--should also serve as an overview of the data structure for any player
local DefaultPlayerData = {}

DefaultPlayerData.data = {
    Currency = {
        gold = 0,
        silver = 0
    },
	Base = {
		house = {},
		barracks = {
			buildingType = "model",
			CFrame = {0., 2, 0, 0, 0, 0},
			properties = {},
			attributes = {
				BuildingTemplate = "BarracksLevel1",
				health = nil
			}
		},
		farms = {}
	},
    Backpack = {}
}

--exists purely to set a players table to hold certain values to test scripts.
local testTable = {
	Currency = {
		gold = 69,
	},
	Base = {
		{
			buildingType = "basepart",
			CFrame = {-70.237, 0.093, -66.48, 0, 0, 0},
			properties = {},
			attributes = { 
				BuildingTemplate = "HouseLevel1",
			}
		},
		{
			buildingType = "model",
			CFrame = {-61.635, 0.093, -141.038, -90, 0, 0},
			properties = {},
			attributes = {
				BuildingTemplate = "BarracksLevel1",
				health = nil
			}
		},
		{
			buildingType = "model",
			CFrame = {-81.635, 0.093, -141.038, -90, 0, 0},
			properties = {},
			attributes = {
				BuildingTemplate = "BarracksLevel1",
				health = 69
			}
		}
	},
	Backpack = {}
}
return DefaultPlayerData
