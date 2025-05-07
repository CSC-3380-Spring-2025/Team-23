--[[
This class provides the common ancestry of all NPCOverheadMenus 
This menu is inteded for ONLY whena  single NPC is selected
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local OverheadMenu = require(script.Parent.Parent.OverheadMenu)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local NPCOverheadMenu = {}
OverheadMenu:Supersedes(NPCOverheadMenu)

--Events
local NPCSetwaypoint = BridgeNet2.ReferenceBridge("NPCSetwaypoint")
local NPCTraverseWaypoints = BridgeNet2.ReferenceBridge("NPCTraverseWaypoints")

local function MakeMenu(Self)
    local NPC: Model = Self.__NPC
    local functions = Self.__ProtFuncs
    local InsertMenu = functions.InsertMenu
    local InsertMenuOption = functions.InsertMenuOption
    local SetHomeMenu = functions.SetHomeMenu
    local TransitionMenu = functions.TransitionMenu
    InsertMenu("HomeMenu", NPC.Name, Self)--All NPCs reset to the home menu
    --Set waypoint button
    --[[
    Sets a waypoint where the menus current position is set
    --]]
    local function setWayPoint()
        local wayPointArgs = {
            Waypoint = Self.__MenuPos,
            Character = NPC
        }
        NPCSetwaypoint:Fire(wayPointArgs)
    end
    local setWayPointText = "Set waypoint here"
    InsertMenuOption("HomeMenu", setWayPointText, setWayPoint, Self, 1)
    --Set linked waypoint button
    --Traverse waypoints button
    --[[
    traverses the established waypoints
    --]]
    local function traverseWaypoints()
        NPCTraverseWaypoints:Fire(NPC)
    end
    local traverseWaypointsText = "Traverse Waypoints"
    InsertMenuOption("HomeMenu", traverseWaypointsText, traverseWaypoints, Self, 2)
    SetHomeMenu("HomeMenu", Self)
    TransitionMenu("HomeMenu", Self)
end

--[[
--]]
function NPCOverheadMenu.new(MenuName, NPC: Model)
    local self = OverheadMenu.new(MenuName)
    setmetatable(self, NPCOverheadMenu)
    self.__NPC = NPC
    MakeMenu(self)
    return self
end

return NPCOverheadMenu