--[[
This class defines the common ancestry for all Enemy NPCs and their common menus
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local OverheadMenu = require(script.Parent.Parent.OverheadMenu)
local EnemyOverheadMenu = {}
OverheadMenu:Supersedes(EnemyOverheadMenu)

--Events
local NPCAttack: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCAttack")

local function MakeMenu(Self)
    local Enemy: Model = Self.__Enemy
    local FriendlyNPCs: {Model} = Self.__FriendlyNPCs
    local functions = Self.__ProtFuncs
    local InsertMenu = functions.InsertMenu
    local InsertMenuOption = functions.InsertMenuOption
    local SetHomeMenu = functions.SetHomeMenu
    local TransitionMenu = functions.TransitionMenu
    local function exitMenu()
        Self:CloseMenu()
    end

    local function attackEnemyNPC()
        --Attack the given enemy with friendly NPCs
        local attackArgs: ExtType.StrDict = {
            Target = Enemy,
            FriendlyNPCs = FriendlyNPCs
        }
        NPCAttack:Fire(attackArgs)
    end
    InsertMenu("HomeMenu", "Enemy", Self)
    InsertMenuOption("HomeMenu", "Attack", attackEnemyNPC, Self, 1)
    InsertMenuOption("HomeMenu", "Exit", exitMenu, Self, 1)

    SetHomeMenu("HomeMenu", Self)
    TransitionMenu("HomeMenu", Self)
end

function EnemyOverheadMenu.new(MenuName: string, Enemy: Model, FriendlyNPCs: {Model})
    local self  = OverheadMenu.new(MenuName)
    setmetatable(self, EnemyOverheadMenu)
    self.__Enemy = Enemy
    self.__FriendlyNPCs = FriendlyNPCs
    MakeMenu(self)
    return self
end


return EnemyOverheadMenu