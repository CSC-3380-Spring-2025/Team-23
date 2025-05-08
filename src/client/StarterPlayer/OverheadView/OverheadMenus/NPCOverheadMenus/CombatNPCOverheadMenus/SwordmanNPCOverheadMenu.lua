--[[
This class handles the pop up menu for all Swordsman NPCs
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local CombatNPCOverheadMenu = require(script.Parent.CombatNPCOverheadMenu)
local SwordmanNPCOverheadMenu = {}
CombatNPCOverheadMenu:Supersedes(SwordmanNPCOverheadMenu)

function SwordmanNPCOverheadMenu.new(MenuName, SwordsmanNPC) : ExtType.ObjectInstance
    local self = CombatNPCOverheadMenu.new(MenuName, SwordsmanNPC)
    setmetatable(self, SwordmanNPCOverheadMenu)
    return self
end

return SwordmanNPCOverheadMenu