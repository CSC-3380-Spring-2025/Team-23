--[[
This class provides the common ancestry of all NPCOverheadMenus 
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local NPCOverheadMenu = require(script.Parent.Parent.NPCOverheadMenu)
local ResourceNPCOverheadMenu = {}
NPCOverheadMenu:Supersedes(ResourceNPCOverheadMenu)

--Events
local NPCEvents = ReplicatedStorage.Events.NPCEvents
local GetWhitelistedStorage = NPCEvents:WaitForChild("GetWhitelistedStorage")
local StartAutoHarvest = BridgeNet2.ReferenceBridge("NPCStartAutoHarvest")
local HarvestNearestResource = BridgeNet2.ReferenceBridge("HarvestNearestResource")
local AssignStorage = BridgeNet2.ReferenceBridge("NPCAssignStorage")

local function ListStorageChoices(Self)
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
    local TransitionMenu = functions.TransitionMenu
    local InsertMenu = functions.InsertMenu
    local choices: {[number]: Instance}? = GetWhitelistedStorage:InvokeServer(Self.__NPC)
    if choices == nil then
        return--Player has no storage devices
    end
    --Prepare options for all viable storage devices
    for descriptor, instance in pairs(choices) do
        local function storageChoice()
            --Fire descriptor as choice for assigned storage for NPC
            local storageArgs = {
                Character = Self.__NPC,
                StorageDevice = descriptor
            }
            AssignStorage:Fire(storageArgs)--Tell server to assign the given storage device
        end
        InsertMenuOption("StorageConfigMenu", instance.Name, storageChoice, Self, 2)
    end

    --Set up return button
    local function returnToAutoHarvestMenu()
        TransitionMenu("AutoHarvestMenu", Self)
    end
    InsertMenuOption("StorageConfigMenu", "Back", returnToAutoHarvestMenu, Self, 1)
end

local function MakeMenu(Self)
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
    local TransitionMenu = functions.TransitionMenu
    local InsertMenu = functions.InsertMenu

    --Set up AutoHarvest menu. Most automated
    InsertMenu("AutoHarvestMenu", "Configure Auto Harvest", Self)

    --Set up automation options
    InsertMenu("AutomationMenu", "Automation Options", Self)
    --Make option for HomeMenu to swap to Automation Menu
    local function swapToAutomationMenu()
        TransitionMenu("AutomationMenu", Self)
    end
    local automationText = "Automation"
    InsertMenuOption("HomeMenu", automationText, swapToAutomationMenu, Self, 4)

    --Set up AssignStorage option/menu for Automation menu
    InsertMenu("StorageConfigMenu", "Choose Return Storage", Self)
    ListStorageChoices(Self)--Set up StorageConfig choices
    local function openStorageConfig()
        TransitionMenu("StorageConfigMenu", Self)
    end
    InsertMenuOption("AutoHarvestMenu", "Choose Storage", openStorageConfig, Self, 1)
    --Add option to start AutoHarvest
    local function startAutoHarvest()
        StartAutoHarvest:Fire(Self.__NPC)
    end
    InsertMenuOption("AutoHarvestMenu", "Start", startAutoHarvest, Self, 2)
    --Insert AutoHarvestMenu into Automation menu
    local function swapToAutoHarvestMenu()
        TransitionMenu("AutoHarvestMenu", Self)
    end
    InsertMenuOption("AutomationMenu", "Auto Harvest", swapToAutoHarvestMenu, Self)

    --Harvest nearest resource option
    local function harvestNearestResource()
        HarvestNearestResource:Fire(Self.__NPC)
    end
    local harvestNearestResourceText = "Harvest nearest resource"
    InsertMenuOption("AutomationMenu", harvestNearestResourceText, harvestNearestResource, Self, 4)
    --InsertMenuOption("AutomationMenu", _, _, _, _)
    

    TransitionMenu("HomeMenu", Self)--Refresh menu
end

function ResourceNPCOverheadMenu.new(MenuName, ResourceNPC)
    local self = NPCOverheadMenu.new(MenuName, ResourceNPC)
    setmetatable(self, ResourceNPCOverheadMenu)
    MakeMenu(self)
    return self
end

return ResourceNPCOverheadMenu