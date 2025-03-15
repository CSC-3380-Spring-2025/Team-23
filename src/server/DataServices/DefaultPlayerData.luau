--[[
 * DefaultPlayerData - Provides default data values for new players upon joining.
 *
 * This module serves two purposes:  
 * 1. It assigns default data values to players who join for the first time in the Data module script
 * 2. It serves as an overview of the data structure for every player, detailing how their data will be structured.

 * This module does not need to inherit from any object.
]]  
local DefaultPlayerData = {}

DefaultPlayerData.data = {
    Currency = {
        gold = 0,
        silver = 0
    },
	Base = {
		house = {},
		barracks = {},
		farms = {}
	},
    Backpack = {}
}

--exists purely to set a players table to hold certain values to test scripts.
local test_table = {
	Currency = {
		gold = 0,
		silver = 0
	},
	Base = {
		House = {
			{
				buildingType = "basePart",
				buildingName = "houseLevel1",
				CFrame = {-70.237, 0.093, -66.48, 0, 0, 0},
				properties = {
					Color = {165, 32, 154}
				},
				attributes = { 
					health = nil
				}
			}
		},
		Barracks = {
			{
				buildingType = "model",
				buildingName = "barracksLevel1",
				CFrame = {-61.635, 0.093, -141.038, -90, 0, 0},
				properties = {
					Color = nil
				},
				attributes = {
					health = nil
				}
			},
			{
				buildingType = "model",
				buildingName = "barracksLevel1",
				CFrame = {-130.635, 0.093, -141.038, 0, 180, 0}, 
				properties = {
					Color = nil
				},
				attributes = {
					health = nil
				}
			}
		}
	},
	Backpack = {}
}

return DefaultPlayerData

