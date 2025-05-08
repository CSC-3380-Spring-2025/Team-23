--Used in Data module to assign default data values to new player upon joining
--should also serve as an overview of the data structure for any player
local DefaultPlayerData = {}

DefaultPlayerData.data = {
	Currency = {
		Gold = 10,
	},
	Base = {
		{
			buildingType = "model",
			CFrame = { 0, 0, 0, 0, 0, 0 },
			properties = {},
			attributes = {
				BuildingTemplate = "HouseLevel1",
			},
		},
	},
	Backpack = {},
}

--exists purely to set a players table to hold certain values to test scripts.
DefaultPlayerData.testTable = {
	Currency = {
		Gold = 69,
	},
	Base = {
		{
			buildingType = "model",
			CFrame = { 0, 0, 0, 0, 0, 0 },
			properties = {},
			attributes = {
				BuildingTemplate = "HouseLevel3",
			},
		},
		{
			buildingType = "model",
			CFrame = { -81.635, 0, -141.038, 0, 0, 0 },
			properties = {},
			attributes = {
				BuildingTemplate = "BarracksLevel1",
				health = 69,
			},
		},
		{
			buildingType = "model",
			CFrame = { 91.635, 0, -34, 0, 0, 0 },
			properties = {},
			attributes = {
				BuildingTemplate = "RefineryLevel1",
				health = 69,
			},
		},
		{
			buildingType = "model",
			CFrame = { 60.635, 0.093, 32.038, 0, 0, 0 },
			properties = {},
			attributes = {
				BuildingTemplate = "WheatFarmLevel1",
			},
		},
	},
	Backpack = {}
}
return DefaultPlayerData
