--[[  
* THIS IS A MANIFEST, NOT A CLASS
* This module stores a table that contains the data for items created in the "backpackhandler" class. Namely, their maximum stack size
* and weight.
* All item data containers should have the same parameters, even if their values are 0.
]]


local ItemData = {
    ["Coal"] = {
        ["MaxStack"] = 50;
        ["Weight"] = 2;
    };
    ["Axe"] = {
        ["MaxStack"] = 1;
        ["Weight"] = 10;
    };
}

return ItemData