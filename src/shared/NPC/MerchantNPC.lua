--[[
This class enables NPCs to interact and . It is designed to be
modular with all parameters customizable to the user/developer.
--]]

--establishing local variables for game services and folders that will need to be accessed
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer

local NPCDialogue = require(script.parent.NPCDialogue)
local MerchantNPC = {}


NPCDialogue:Supersedes(MerchantNPC) --this extends NPCDialogue

--[[
Helper function assisting with resetting Proximity Prompt.
    @param Self (any) - applies to any self reference being utilized in the program.
    @returns nothing
--]]
local function ProxPromptHandler(Self: any) : ()
    
    local proxPrompt: ProximityPrompt = Self.__ProxPrompt
    local action: RBXScriptSignal = Self.__ProxPromptAction
    --disconnect actions 
    if action then
        action:Disconnect()
    end
    --and reassign them to open new menus afterwards
    local function NewAction() : ()
        Self.__HomeMenu.Enabled = true
    end
    Self.__ProxPromptAction = proxPrompt.Triggered:Connect(NewAction)
end

function MerchantNPC.new(Name, NPC)
    local self = NPCDialogue.new(Name, NPC)
    setmetatable(self, MerchantNPC) 

    return self
end

function MerchantNPC:SetHomeMenu(MenuName)
    print("This is home menu!")
    local foundMenu: ScreenGui = self.__Menus[MenuName]
    --warning when there is not a menu to be set
    if not foundMenu then
        warn("Failed to set Home Menu. " .. MenuName .. " does not exist.")
        return
    end
    
    local function SellMenu()
        self:InsertMenu("SellMenu", "Choose something to sell")
        --adding sell option
        --self:InsertOption("SellMenu")

        self:TransitionDialogue("SellMenu")

    end
    
    self:InsertOption(MenuName, "Sell", SellMenu, 9)
    print("Inserted Sell Option")
    
    self.__HomeMenu = foundMenu
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)

end



return MerchantNPC
