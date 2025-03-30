--establishing local variables for game services and folders that will need to be accessed
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPCDialogue = {}

Object:Supersedes(NPCDialogue) --this extends Dialogue from Object

local dialogue = ReplicatedFirst.UI.NPC.Dialogue.Dialogue
local optionButtonReferencer = ReplicatedFirst.UI.NPC.Dialogue.OptionButton


local function ProxPromptHandler(Self) 
    --helper function that handles resetting of Proximity Prompt
    --disconnect actions and reassign them to open new menus afterwards
    local proxPrompt = Self.__ProxPrompt
    local action = Self.__ProxPromptAction
    if action then
        action:Disconnect()
    end
    local function NewAction()
        Self.__HomeMenu.Enabled = true
    end
    Self.__ProxPromptAction = proxPrompt.Triggered:Connect(NewAction)
end



function NPCDialogue.new(Name, NPC) 
    --takes in two parameters, Name and NPC
    --creates from there a new object with name Name and assigned to NPC
    local self = Object.new(Name)
    setmetatable(self, NPCDialogue) 
    self.__NPC = NPC 
    
    --creating other empty and miscellaneous parameters to be modified with other associated functions below
    self.__CurrentMenu = nil
    self.__DialogueVisibleProperty = false
    self.__Menus = {}
    self.__HomeMenu = nil
    self.__ProxPrompt = Instance.new("ProximityPrompt")
    self.__ProxPrompt.MaxActivationDistance = 10
    self.__ProxPrompt.RequiresLineOfSight = false
    self.__ProxPrompt.Parent = NPC
    self.__ProxPromptAction = nil
    return self
end



function NPCDialogue:InsertMenu(MenuName, Dialogue)
    --takes in MenuName and Dialogue
    --creates a clone of the existing dialogue
    --modifies it with new text parameters from Dialogue
    --reinsert it back into player's interface
    --save to the current Menu table
    --close the current dialogue
    local dialogueClone = dialogue:Clone()
    dialogueClone.Name = MenuName
    local cloneTextLabel = dialogueClone.Frame.DialogueFrame.TextLabel
    cloneTextLabel.Text = Dialogue
    dialogueClone.Parent = player.PlayerGui
    dialogueClone.Enabled = false
    
    self.__Menus[MenuName] = dialogueClone
    local function callCloseDialogue()
        self:CloseDialogue()
    end
    --inserts a default close dialogue option for users to easily close out
    self:InsertOption(MenuName, "Nevermind", callCloseDialogue, 10)


end

function NPCDialogue:SetHomeMenu(MenuName)
    --take in MenuName and set it as the home menu
    local foundMenu = self.__Menus[MenuName]
    --warning when there is not a menu to be set
    if not foundMenu then
        warn("Failed to set Home Menu. " .. MenuName .. " does not exist.")
        return
    end
    self.__HomeMenu = foundMenu
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)
end   

function NPCDialogue:InsertOption(MenuName, OptionMessage, ActionFunc, Priority)
    --take in MenuName, OptionMessage, ActionFunc, Priority
    --look up MenuName in the Menus table and save to UI variable
    --insert new OptionMessage into that UI
    --set click detector to initiate ActionFunc
    --set LayoutOrder to Priority (order in which the option message will be showed)
    local currentMenu = self.__Menus[MenuName]
    local optionButtonCopy = optionButtonReferencer:Clone()
    optionButtonCopy.LayoutOrder = Priority

    local scrollingFrame = currentMenu.Frame.OptionFrame.ScrollingFrame
    local obrText = optionButtonCopy.TextLabel
    obrText.Text = OptionMessage
    optionButtonCopy.MouseButton1Down:Connect(ActionFunc)

    optionButtonCopy.Parent = scrollingFrame

end

function NPCDialogue:TransitionDialogue(MenuName)
    --take in MenuName and set as newMenu
    --check if newMenu exists, if not, warn
    --if does, disable CurrentMenu, and enable newMenu
    local newMenu = self.__Menus[MenuName]
    if not newMenu then
        warn("Failed to transition dialogue. " .. MenuName .. " does not exist.")
        return
    end
    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end
    newMenu.Enabled = true
    self.__CurrentMenu = newMenu
    
end

function NPCDialogue:CloseDialogue()
    --closes the dialogue
    --resets menu to HomeMenu
    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end

    if self.__HomeMenu then
        self.__CurrentMenu = self.__HomeMenu
    end
    --call helper function to reset Proximity Prompt
    ProxPromptHandler(self)

end

function NPCDialogue:DestroyInstance()
    --destroy NPC dialogue
    --destroy proximity prompt
    --destroy Menu table
    print("Destroyed!")
    
    self.__ProxPrompt:Destroy()
    print("ProxPrompt is destroyed.")
    for _, currentMenu in pairs(self.__Menus) do
         currentMenu:Destroy()
         print("Menu is destroyed.")
    end
end

return NPCDialogue
 
