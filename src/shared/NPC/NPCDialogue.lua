--[[
This class provides utilities for establishing, adding, binding to functions,
removing, closing, and destroying of dialogue elements/GUIs. It is designed to be
modular with all parameters customizable to the user/developer.
--]]

--establishing local variables for game services and folders that will need to be accessed
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPCDialogue = {}

Object:Supersedes(NPCDialogue) --this extends Dialogue from Object

local dialogue: ScreenGui = ReplicatedFirst.UI.NPC.Dialogue.Dialogue
local optionButtonReferencer: ImageButton = ReplicatedFirst.UI.NPC.Dialogue.OptionButton

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


--[[
Constructor of a new NPC Dialogue
    @param Name (string) name of the NPC dialogue
    @param NPC (string) name of the NPC being assigned to that dialogue
--]]
function NPCDialogue.new(Name: string, NPC: string) 
    local self = Object.new(Name)
    setmetatable(self, NPCDialogue) 
    self.__NPC= NPC 
    
    --creating other empty and miscellaneous parameters to be modified with other associated functions below
    self.__CurrentMenu = nil
    self.__DialogueVisibleProperty = false
    self.__Menus= {}
    self.__HomeMenu = nil
    self.__ProxPrompt = Instance.new("ProximityPrompt")
    self.__ProxPrompt.MaxActivationDistance = 10
    self.__ProxPrompt.RequiresLineOfSight = false
    self.__ProxPrompt.Parent = NPC
    self.__ProxPromptAction = nil
    return self
end


--[[
Function to insert a new Menu inside NPC Dialogue
    @param MenuName (string) name of the menu that needs insertion
    @param Dialogue (string) the content, text of the dialogue being inserted
--]]
function NPCDialogue:InsertMenu(MenuName: string, Dialogue: string) : ()
    --creates a clone of the existing dialogue
    local dialogueClone: ScreenGui = dialogue:Clone()
    dialogueClone.Name = MenuName
    --modifies its text label with new text parameters from Dialogue
    local cloneTextLabel: TextLabel = dialogueClone.Frame.DialogueFrame.TextLabel
    cloneTextLabel.Text = Dialogue
    --reinsert it back into player's interface
    dialogueClone.Parent = player.PlayerGui
    dialogueClone.Enabled = false
    --save to the current Menu table
    self.__Menus[MenuName] = dialogueClone
    --[[ 
    function to close the current dialogue 
    --]]
    local function callCloseDialogue() : ()
        self:CloseDialogue()
    end
    --inserts a default close dialogue option for users to easily close out
    self:InsertOption(MenuName, "Nevermind", callCloseDialogue, 10)
end

--[[
Function to set home Menu inside NPC Dialogue
    @param MenuName (string) name of the menu that needs to be set to Home Menu
--]]

function NPCDialogue:SetHomeMenu(MenuName: string) : ()
    local foundMenu: ScreenGui = self.__Menus[MenuName]
    --warning when there is not a menu to be set
    if not foundMenu then
        warn("Failed to set Home Menu. " .. MenuName .. " does not exist.")
        return
    end
    self.__HomeMenu = foundMenu
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)
end   

--[[
Function to insert Option inside a Menu within NPC Dialogue
    @param MenuName (string) name of the destination menu for the inserted message
    @param OptionMessage (string) the message being inserted
    @param ActionFunc (function) a user-defined function to be binded with the inserted message
    @param Priority (number) the order in which the inserted message appears in the UI
--]]
function NPCDialogue:InsertOption(MenuName: string, OptionMessage: string, ActionFunc, Priority: number) : ()
    
    --look up MenuName in the Menus table and save to UI variable
    local currentMenu: ScreenGui = self.__Menus[MenuName]
    local optionButtonCopy: ImageButton = optionButtonReferencer:Clone()
    --set LayoutOrder to Priority (order in which the option message will be showed)
    optionButtonCopy.LayoutOrder = Priority

    local scrollingFrame: ScrollingFrame = currentMenu.Frame.OptionFrame.ScrollingFrame
    --insert new OptionMessage into that UI
    local obrText: TextLabel = optionButtonCopy.TextLabel
    obrText.Text = OptionMessage
     --set click detector to initiate ActionFunc
    optionButtonCopy.MouseButton1Down:Connect(ActionFunc)

    optionButtonCopy.Parent = scrollingFrame

end
--[[
Function to transition between a menu to another within NPC Dialogue
    @param MenuName (string) name of the target menu to transition to
--]]
function NPCDialogue:TransitionDialogue(MenuName: string) : ()
    --take in MenuName and set as newMenu
    local newMenu: ScreenGui = self.__Menus[MenuName]
    --check if newMenu exists, if not, warn
    if not newMenu then
        warn("Failed to transition dialogue. " .. MenuName .. " does not exist.")
        return
    end
    --if does, disable CurrentMenu
    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end
    --and enable newMenu
    newMenu.Enabled = true
    self.__CurrentMenu = newMenu
    
end
--[[
Function to close dialogue
--]]
function NPCDialogue:CloseDialogue() : ()
    --disables CurrentMenu
    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end
    --resets menu to HomeMenu
    if self.__HomeMenu then
        self.__CurrentMenu = self.__HomeMenu
    end
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)

end
--[[
Function to destroy dialogue instance within NPC Dialogue
--]]
function NPCDialogue:DestroyInstance() : ()
    print("Destroyed!")
    --destroy proximity prompt
    self.__ProxPrompt:Destroy()
    print("ProxPrompt is destroyed.")
    --destroy Menu table
    for _, currentMenu in pairs(self.__Menus) do
         currentMenu:Destroy()
         print("Menu is destroyed.")
    end
end

return NPCDialogue
 
