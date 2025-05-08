--[[
This class defines the common ancestry for all Enemy NPCs and their common menus
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local OverheadMenu = require(script.Parent.Parent.OverheadMenu)
local ResourceOverheadMenu = {}
OverheadMenu:Supersedes(ResourceOverheadMenu)

--Events
local NPCCollectResource: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCCollectResource")

local function MakeMenu(Self: ExtType.ObjectInstance)
    local resourceObject: BasePart = Self.__ResourceObject
    local resourceNPCs: {Model} = Self.__ResourceNPCs
    local functions: ExtType.StrDict = Self.__ProtFuncs
    local InsertMenu = functions.InsertMenu
    local InsertMenuOption = functions.InsertMenuOption
    local SetHomeMenu = functions.SetHomeMenu
    local TransitionMenu = functions.TransitionMenu
    local function exitMenu()
        Self:CloseMenu()
    end

    local function collectResource()
        --Attack the given enemy with friendly NPCs
        local collectArgs: ExtType.StrDict = {
            ResourceObject = resourceObject,
            ResourceNPCs = Self.__ResourceNPCs
        }
        NPCCollectResource:Fire(collectArgs)
    end
    local resourceCount: number = resourceObject:GetAttribute("Count") :: number
    local titleText: string = resourceObject.Name .. ": " .. resourceCount
    InsertMenu("HomeMenu", titleText, Self)
    InsertMenuOption("HomeMenu", "Collect", collectResource, Self, 1)
    InsertMenuOption("HomeMenu", "Exit", exitMenu, Self)

    SetHomeMenu("HomeMenu", Self)
    TransitionMenu("HomeMenu", Self)
end

function ResourceOverheadMenu.new(MenuName: string, ResourceObject: BasePart, ResourceNPCs:{Model}) : ExtType.ObjectInstance
    local self  = OverheadMenu.new(MenuName)
    setmetatable(self, ResourceOverheadMenu)
    self.__ResourceObject = ResourceObject
    self.__ResourceNPCs = ResourceNPCs or {}
    MakeMenu(self)
    return self
end


return ResourceOverheadMenu