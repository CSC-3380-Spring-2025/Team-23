--[[
This class provides the base inheritance of all overhead pop up menus
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst: ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players: Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ClientMutexSeq = require(script.Parent.Parent.Parent.ClientUtilities.ClientMutexSeq)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local OverheadMenu = {}
Object:Supersedes(OverheadMenu)

--Vars
local overheadMenuTemplate: BillboardGui = ReplicatedFirst:WaitForChild("BillboardGuis"):WaitForChild("OverheadMenu")
local optionTemplates: Folder = overheadMenuTemplate:WaitForChild("Templates") :: Folder
local optionButtonTemplate: TextButton = optionTemplates:WaitForChild("OptionButton") :: TextButton
local MenusFolderLock = ClientMutexSeq.new("OverheadMenusFolder") --used to prevent race conditions of folder duplicates
local player: Player = Players.LocalPlayer

local protFuncs = {}

--[[
Protected function that inserts a Menu into the Menu list to be accessed by other menus
    @param MenuName (string) the name of the menu key to refrence
    @param Title (string) the title of the menu shown to the player
    @param Self (ExtType.ObjectInstance) instance of this class
--]]
protFuncs.InsertMenu = function(MenuName: string, Title: string, Self: ExtType.ObjectInstance): ()
	local coMenus: ExtType.StrDict = Self.__CoMenus

	local menuStruct: ExtType.StrDict = {
		Title = Title, --Title of the menu
		Options = {}, --createempty list of options
	}
	coMenus[MenuName] = menuStruct --Create key for menu with empty list of options
end

--[[
Protected function that inserts a option into the Menu list to be accessed by the player in the specified Menu
    @param MenuName (string) the name of the menu to insert the option into
    @param OptionText (string) the text of the option button
    @param ActionFunc (function) any function without arguments to be passed in and executed
    @param Priority (number) priority of option in option list of menu
    @param Self (ExtType.ObjectInstance) instance of this class
--]]
protFuncs.InsertMenuOption = function(
	MenuName: string,
	OptionText: string,
	ActionFunc,
	Self: ExtType.ObjectInstance,
	Priority: number
): ()
	local coMenus: ExtType.StrDict = Self.__CoMenus
	local menuStruct: ExtType.StrDict? = coMenus[MenuName]
	if menuStruct == nil then
		warn('Attempt to InsertMenuOption but over head menu .."' .. MenuName .. '" does not exist')
		return
	end
	local options: { ExtType.StrDict } = menuStruct.Options
	--Create an option from menu templates
	local newButton: TextButton = optionButtonTemplate:Clone()
	if Priority then
		newButton.LayoutOrder = Priority
	end
	newButton.Visible = false
	newButton.Text = OptionText
	--Store ActionFunc
	local optionStruct: ExtType.StrDict = {
		Button = newButton,
		ActionFunc = ActionFunc,
		Connection = nil,
	}
	table.insert(options, optionStruct)
end

--[[
Helper function used to clear the existing viewable set of options in the MenuFrame
    @param Self (ExtType.ObjectInstance) instance of this class
--]]
local function ClearOptions(Self: ExtType.ObjectInstance): ()
	local curOptions: { ExtType.StrDict } = Self.__CurOptions
	local option: ExtType.StrDict? = table.remove(curOptions)
	while option do
		--Clean up connection
		local connection: RBXScriptConnection = option.Connection
		connection:Disconnect()
		option.Connection = nil
		--clean up button
		local button: TextButton = option.Button
		button.Visible = false
		button.Parent = nil
		option = table.remove(curOptions)
	end
end

--[[
Inserts the options for the new menu into the frame
    @param MenuStruct (ExtType.StrDict) the dictionary of the menu
    @param Self (ExtType.ObjectInstance) the instance of this class
--]]
local function InsertOptions(MenuStruct: ExtType.StrDict, Self: ExtType.ObjectInstance)
	local menuFrame: BillboardGui = Self.__MenuFrame
	local optionHolder: ScrollingFrame = menuFrame:WaitForChild("Holder") :: ScrollingFrame
	local curOptions: { ExtType.StrDict } = Self.__CurOptions
	local options: { ExtType.StrDict } = MenuStruct.Options
	--Cycle through menus options structs
	for _, optionStruct in pairs(options) do
		--Set up click connection with actionfunc
		local button: TextButton = optionStruct.Button
		optionStruct.Connection = button.MouseButton1Click:Connect(optionStruct.ActionFunc)
		button.Parent = optionHolder
		button.Visible = true
		table.insert(curOptions, optionStruct)
	end
end

--[[
Protected function that transitions to another Menu
    @param MenuName (string) the name of the menu to transition to
    @param Self (ExtType.ObjectInstance) instance of this class
--]]
protFuncs.TransitionMenu = function(MenuName: string, Self: ExtType.ObjectInstance): ()
	local menuStruct: ExtType.StrDict = Self.__CoMenus[MenuName]
	if menuStruct == nil then
		warn('Attempt to transition menu but over head menu .."' .. MenuName .. '" does not exist')
		return
	end
	ClearOptions(Self)
	InsertOptions(menuStruct, Self)
	local menuFrame: BillboardGui = Self.__MenuFrame
	local menuNameText: TextLabel = menuFrame:WaitForChild("MenuName") :: TextLabel
	menuNameText.Text = MenuName
end

--[[
Sets a home menu for when the player closes the menu
	if the menu is closed then the menu sets back to this home menu
	@param MenuName (string) the name of the menu to set to
	@param Self (ExtType.ObjectInstance) instance of this class
--]]
protFuncs.SetHomeMenu = function(MenuName: string, Self: ExtType.ObjectInstance) : ()
	local menu = Self.__CoMenus[MenuName]
	if not menu then
		warn("Attempt to set home menu for menu \"" .. MenuName .. "\" but menu does not exist")
		return
	end
	Self.__HomeMenuName = MenuName
end

--[[
Removes the home menu
	@param Self (ExtType.ObjectInstance) an instance of this class
--]]
protFuncs.RemoveHomeMenu = function(Self: ExtType.ObjectInstance) : ()
	Self.__HomeMenuName = nil
end

--[[
Constructor for the default menu of the OverheadMenu
	@param MenuName (string) name of the menu instance
	NOT the name of a menu or title
	creating menus (and options) is not accessible outside of OverheadMenu 
	and its children
--]]
function OverheadMenu.new(MenuName: string): ExtType.ObjectInstance
	local self = Object.new(MenuName)
	setmetatable(self, OverheadMenu)
	--Set up menu frame
	local menu: BillboardGui = overheadMenuTemplate:Clone()
	menu.Enabled = false
	menu.Name = MenuName
	self.__MenuFrame = menu --Shared menu frame for this menu
	--List of all co existing menus for this menu. Holds all optiosn for the menu with the key being the menu name
	self.__CoMenus = {}
	self.__CurOptions = {} --Table of current options set for frame
	local parentPart: Part = Instance.new("Part")
	parentPart.Size = Vector3.new(0.1, 0.1, 0.1)
	parentPart.Transparency = 1
	parentPart.Anchored = true
	parentPart.CanCollide = false
	self.__MenuFrame.Parent = player.PlayerGui
	MenusFolderLock:Lock()
	local overHeadMenusFolder: Folder? = Workspace:FindFirstChild("OverheadMenus")
	if overHeadMenusFolder == nil then
		local newFolder: Folder = Instance.new("Folder")
		newFolder.Name = "OverheadMenus"
		newFolder.Parent = Workspace
		overHeadMenusFolder = newFolder
	end
	MenusFolderLock:Unlock()
	parentPart.Name = "MenuPartOf" .. menu.Name
	parentPart.Parent = overHeadMenusFolder
	menu.Adornee = parentPart--Tells it to follow the parent part in workspace
	self.__ParentPart = parentPart --Used to move around the menu
	self.__ProtFuncs = protFuncs --Set of protected functions
	self.__Tasks = {} --Dictionary of all tasks
	self.__Connections = {} --Dictionary of all tasks not stored somewhere else
	self.__HomeMenuName = nil--Name of the home menu if set
	self.__MenuPos = nil --The current position of the menu
	return self
end

--[[
Places the Menu at a certain position
	@param MenuPos (Vector3) the place to put the menu
--]]
function OverheadMenu:PlaceMenu(MenuPos: Vector3) : ()
	self.__ParentPart.Position = MenuPos
	self.__MenuPos = MenuPos
end

--[[
Opens the menu
--]]
function OverheadMenu:OpenMenu() : ()
	self.__MenuFrame.Enabled = true
end

--[[
Closes the menu
--]]
function OverheadMenu:CloseMenu() : ()
	self.__MenuFrame.Enabled = false
	--If set then change back to home menu
	protFuncs.TransitionMenu(self.__HomeMenuName, self)
end

function OverheadMenu:Destroy() : ()
	self.__ParentPart:Destroy() --Destroy phys objects
	self.__MenuFrame:Destroy()
	--Disconect all connections in options
	for _, menuStruct in pairs(self.__CoMenus) do
		local options = menuStruct.Options
		for _, optionStruct in pairs(options) do
			local connection = optionStruct.Connection
			if connection then
				connection:Disconnect()
			end
		end
	end
	--Disconcent all other connections
	for _, connection in pairs(self.__Connections) do
		connection:Disconcent()
	end
	--cancel all tasks
	for _, thread in pairs(self.__Tasks) do
		if thread then
			task.cancel(thread)
		end
	end
end

return OverheadMenu
