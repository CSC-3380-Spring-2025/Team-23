--Used in Data module to assign default data values to new player upon joining
--should also serve as an overview of the data structure for any player
local DefaultPlayerData = {}

DefaultPlayerData.data = {
    Currency = {
        gold = 0,
        silver = 0
    },
    Base = {},
    Backpack = {}
}

return DefaultPlayerData
