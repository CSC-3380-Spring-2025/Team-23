--[[
This class enables NPCs to interact and sell stuff. It is designed to be
modular with all parameters customizable to the user/developer.
--]]

--establishing local variables for game services and folders that will need to be accessed
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local getBackpackContents = Events:WaitForChild("GetBackpackContents")

--local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)

local NPCDialogue = require(script.parent.NPCDialogue)
local MerchantNPC = {}
local optionButtonReferencer: ImageButton = ReplicatedFirst.UI.NPC.Dialogue.OptionButton
local ItemName = {}


NPCDialogue:Supersedes(MerchantNPC) --this extends NPCDialogue
--local backpackAccess = BackpackHandler.new()
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
    self:InsertMenu("SellMenu", "Choose something to sell")
    self.__SellOptions = {} --table of string that says what items the vendors are allowed to sell
    return self
end

local function DisplaySellItems(Self)
    local sellMenu: ScreenGui = Self.__Menus["SellMenu"]
    local optionButtonCopy: ImageButton = optionButtonReferencer:Clone()
    local scrollingFrame: ScrollingFrame = sellMenu.Frame.OptionFrame.ScrollingFrame
    
    --look up Backpack Item list
    local backpackItems = getBackpackContents:InvokeServer()
    
    --if backpackItem is a whitelisted item in selloptions
    --then displayitem with amount and sell value per unit
    --action func = local function to pass in, sells one unit if left click, sell 10 if ctrl + left click
    --ctrl + shift = 100
    --if less then sell all
    --remove items from backpack and add money
    

    for _, backpackItem in pairs(backpackItems) do
        
        local obrText: TextLabel = optionButtonCopy.TextLabel
		obrText.Text = backpackItem.__Name
        --print(obrText.Text)
        optionButtonCopy.MouseButton1Down:Connect(Self.ItemRemoval(obrText.Text)) 
        optionButtonCopy.Parent = scrollingFrame
	end
end

--local function ClearLastItems()
    
--end

function MerchantNPC:SetHomeMenu(MenuName)
    print("This is home menu!")
    local foundMenu: ScreenGui = self.__Menus[MenuName]
    --warning when there is not a menu to be set
    if not foundMenu then
        warn("Failed to set Home Menu. " .. MenuName .. " does not exist.")
        return
    end
    
    local function SellMenu()
        --ClearLastItems()
        DisplaySellItems(self)
        self:TransitionDialogue("SellMenu")
    end
    self:InsertOption(MenuName, "Sell", SellMenu, -1)
    self.__HomeMenu = foundMenu
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)
	
end



function MerchantNPC:InsertSellOption(ItemName, Priority)
    
    
    
    
    
	
	
end

function MerchantNPC:InsertMultiSellOptions(ItemList: {}, Priority)
    
end



function MerchantNPC:Test()
	task.wait(5)

end



return MerchantNPC
