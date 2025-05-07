--[[
This class provides the common ancestry of all NPCOverheadMenus 
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ResourceNPCOverheadMenu = require(script.Parent.ResourceNPCOverheadMenu)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local MinerNPCOverheadMenu = {}
ResourceNPCOverheadMenu:Supersedes(MinerNPCOverheadMenu)

--Events

local function MakeMenu(Self)
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
    local TransitionMenu = functions.TransitionMenu
end

function MinerNPCOverheadMenu.new(MenuName, MinerNPC)
    local self = ResourceNPCOverheadMenu.new(MenuName, MinerNPC)
    setmetatable(self, MinerNPCOverheadMenu)
    MakeMenu(self)
    return self
end

return MinerNPCOverheadMenu