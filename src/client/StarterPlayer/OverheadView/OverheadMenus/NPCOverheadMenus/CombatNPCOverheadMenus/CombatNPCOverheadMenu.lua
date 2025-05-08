local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local NPCOverheadMenu = require(script.Parent.Parent.NPCOverheadMenu)
local CombatNPCOverheadMenu = {}
NPCOverheadMenu:Supersedes(CombatNPCOverheadMenu)

--Events
local NPCSentryMode: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCSentryMode")

local function MakeMenu(Self)
    local NPC = Self.__NPC
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
    local TransitionMenu = functions.TransitionMenu
    local InsertMenu = functions.InsertMenu

    local function backHomeMenu()
        TransitionMenu("HomeMenu", Self)
    end

     --Set up exit button
     local function exitMenu()
        Self:CloseMenu()
    end

    --Make combat Menu
    InsertMenu("CombatMenu", "Combat Options", Self)
    InsertMenuOption("CombatMenu", "Exit", exitMenu, Self, 1)
    InsertMenuOption("CombatMenu", "Back", backHomeMenu, Self, 1)
    local function toCombatMenu()
        TransitionMenu("CombatMenu", Self)
    end
    InsertMenuOption("HomeMenu", "Combat", toCombatMenu, Self)

    --Add combat options
    local function activateSentryMode()
        NPCSentryMode:Fire(NPC)--Activate sentry mode
    end
    InsertMenuOption("CombatMenu", "Activate Sentry Mode", activateSentryMode, Self)
    --Make sentry mode option 
    TransitionMenu("HomeMenu", Self)
end

function CombatNPCOverheadMenu.new(Name, CombatNPC) : ExtType.ObjectInstance
    local self = NPCOverheadMenu.new(Name, CombatNPC)
    setmetatable(self, CombatNPCOverheadMenu)
    MakeMenu(self)
    return self
end

return CombatNPCOverheadMenu