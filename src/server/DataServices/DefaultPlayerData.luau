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
    Base = {},
    Backpack = {}
}

return DefaultPlayerData

