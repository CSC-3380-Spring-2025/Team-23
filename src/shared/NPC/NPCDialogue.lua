local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPCDialogue = {}
--local ProximityPrompt = script.Parent.ProximityPrompt


Object:Supersedes(NPCDialogue) --this extends Dialogue from Object
---this is constructor
local dialogue = ReplicatedFirst.UI.NPC.Dialogue.Dialogue
local optionButtonReferencer = ReplicatedFirst.UI.NPC.Dialogue.OptionButton


local function ProxPromptHandler(Self) 
    --helper function that handles resetting of proximity prompt functions
    --disconnect actions and reassign to open new menus afterwards
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
    local self = Object.new(Name)
    setmetatable(self, NPCDialogue) --helps construct the inheritance
    self.__NPC = NPC --same principles apply, I'm too lazy to comment (__ to make private)
    
    self.__CurrentMenu = nil
    self.__DialogueVisibleProperty = false
    self.__Menus = {}
    self.__HomeMenu = nil
    self.__ProxPrompt = Instance.new("ProximityPrompt")
    self.__ProxPrompt.MaxActivationDistance = 10
    self.__ProxPrompt.RequiresLineOfSight = false
    self.__ProxPrompt.Parent = NPC
    self.__ProxPromptAction = nil
    --set miscellaneous properties: activation proximity, direct line of sight, and parent


    --something to check distance with ProximityPrompt
    --call closeDialogue function when activated
    return self
end



function NPCDialogue:InsertMenu(MenuName, Dialogue)
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
    self:InsertOption(MenuName, "Nevermind", callCloseDialogue, -1)

    -- clone the ui
    -- set the dialogue text to the parameter
    -- save the UI to the menuTable in line 21
    -- under the key of MenuName

end

--when shown
--DialogueVisibleProperty = true;

function NPCDialogue:SetHomeMenu(MenuName)
    local foundMenu = self.__Menus[MenuName]
    if not foundMenu then
        warn("Failed to set Home Menu. " .. MenuName .. " does not exist.")
        return
    end
    self.__HomeMenu = foundMenu

    ProxPromptHandler(self)
    --check on definition tmrw
end   

function NPCDialogue:InsertOption(MenuName, OptionMessage, ActionFunc, Priority)
    local currentMenu = self.__Menus[MenuName]
    local optionButtonCopy = optionButtonReferencer:Clone()
    optionButtonCopy.LayoutOrder = Priority

    local scrollingFrame = currentMenu.Frame.OptionFrame.ScrollingFrame
    local obrText = optionButtonCopy.TextLabel
    obrText.Text = OptionMessage
    optionButtonCopy.MouseButton1Down:Connect(ActionFunc)

    optionButtonCopy.Parent = scrollingFrame

    -- onClick ? implement things to happen
    -- onClick -> Action -> do (___)

    -- make more sense to action when onClick works
    -- pass in actionfunc into clickEvent -> run function

    -- if not called, do nothing

    -- pass in menu name
    -- look up menuname in menu table
    -- save that to ui variable
    -- insert new option message into that ui
    -- set onClick event for that optionButton
    -- onClick -> execute action
    -- set the layout order to priority

end

function NPCDialogue:TransitionDialogue(MenuName)
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
    
    

    --take in the MenuName
    --look up key with MN -> set currentdisplay visible  = false
    -- make the menu visible
    --(basically swapping old menu for new)
end

function NPCDialogue:CloseDialogue()
    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end

    if self.__HomeMenu then
        self.__CurrentMenu = self.__HomeMenu
    end

    ProxPromptHandler(self)
    
    
    --close the dialogue, hide so not visible
    --make it so it resets the NPC dialogue to base
    -- if not called, do nothing
end
--find a way to disable dialogue, 10 studs
--


function NPCDialogue:Destroy()
    if self.__Dialogue then
        
    end

    if self.__CurrentMenu then
        self.__CurrentMenu.Enabled = false
    end
    --OptionMessage = null
    --ActionFunc = null
    --destroy prox prompt, destroy UI
    --in addition to destroying prox prompt, destroy also all the UI in MenuTable
    --if not called, do nothing
    --localplayer.playergui.---.Frame.OptionFrame.ScrollingFrame.OptionButton
end

--debounce blocks sth from happening until condition is activated
-- make instancevar self__isOriginalDialogue = true
-- i

local function onPromptTriggered(Prompt, Player) : ()
    if Prompt.Name == "Interact" then
        print("Check!")
    end
end

--pps.PromptTriggered:Connect(onPromptTriggered)


return NPCDialogue
 
