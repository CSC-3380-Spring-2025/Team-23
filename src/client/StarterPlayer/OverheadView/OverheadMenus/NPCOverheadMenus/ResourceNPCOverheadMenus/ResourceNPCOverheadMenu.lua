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
local NPCEmptyToStorage = BridgeNet2.ReferenceBridge("NPCEmptyToStorage")

local function ListStorageEmptyToOpts(Self, MenuName)
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
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
            NPCEmptyToStorage:Fire(storageArgs)--Tell server to assign the given storage device
        end
        InsertMenuOption(MenuName, instance.Name, storageChoice, Self, 2)
    end
end

local function ListStorageChoices(Self, MenuName)
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
        InsertMenuOption(MenuName, instance.Name, storageChoice, Self, 2)
    end
end

local function MakeMenu(Self)
    local functions = Self.__ProtFuncs
    local InsertMenuOption = functions.InsertMenuOption
    local TransitionMenu = functions.TransitionMenu
    local InsertMenu = functions.InsertMenu

    local function backHomeMenu()
        TransitionMenu("HomeMenu", Self)
    end

    --Set up AutoHarvest menu. Most automated
    InsertMenu("AutoHarvestMenu", "Configure Auto Harvest", Self)
    --Set up exit button
    local function exitMenu()
        Self:CloseMenu()
    end
    InsertMenuOption("AutoHarvestMenu", "Exit", exitMenu, Self, 1)
    local function backAutomationMenu()
        TransitionMenu("AutomationMenu", Self)
    end
    InsertMenuOption("AutoHarvestMenu", "Back", backAutomationMenu, Self, 1)

    --Set up automation options
    InsertMenu("AutomationMenu", "Automation Options", Self)
    InsertMenuOption("AutomationMenu", "Exit", exitMenu, Self, 1)
    InsertMenuOption("AutomationMenu", "Back", backHomeMenu, Self, 1)
    --Make option for HomeMenu to swap to Automation Menu
    local function swapToAutomationMenu()
        TransitionMenu("AutomationMenu", Self)
    end
    local automationText = "Automation"
    InsertMenuOption("HomeMenu", automationText, swapToAutomationMenu, Self, 4)

    --Set up AssignStorage option/menu for Automation menu
    InsertMenu("StorageConfigMenu", "Choose Return Storage", Self)
    InsertMenuOption("StorageConfigMenu", "Exit", exitMenu, Self, 1)
    ListStorageChoices(Self, "StorageConfigMenu")--Set up StorageConfig choices
    --Set up return button
    local function returnToAutoHarvestMenu()
        TransitionMenu("AutoHarvestMenu", Self)
    end
    InsertMenuOption("StorageConfigMenu", "Back", returnToAutoHarvestMenu, Self, 1)
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
    
    --Set up Transfer Inventory to Storage
    InsertMenu("TransferStorageMenu", "Select Storage", Self)
    InsertMenuOption("TransferStorageMenu", "Exit", exitMenu, Self, 1)
    --Set up options for storage
    ListStorageEmptyToOpts(Self, "TransferStorageMenu")
    InsertMenuOption("TransferStorageMenu", "Back", backHomeMenu, Self, 1)

    --Add option to HomeMenu
    local function toStorageMenu()
        TransitionMenu("TransferStorageMenu", Self)
    end
    local transferText = "Transfer Inventory to Storage"
    InsertMenuOption("HomeMenu", transferText, toStorageMenu, Self)


    TransitionMenu("HomeMenu", Self)--Refresh menu
end

function ResourceNPCOverheadMenu.new(MenuName, ResourceNPC)
    local self = NPCOverheadMenu.new(MenuName, ResourceNPC)
    setmetatable(self, ResourceNPCOverheadMenu)
    MakeMenu(self)
    return self
end

return ResourceNPCOverheadMenu