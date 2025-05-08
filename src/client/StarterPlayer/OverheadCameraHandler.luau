--[[  
 * THIS CLASS EXTENDS CLASS: OBJECT
 * OverheadCamerHandler - Superclass of all methods using the overhead tactical view.  
 *  
 * This class represents the command & control structure for the player's overhead camera view, and handles
 * camera movement and basic unit icons. It does NOT handle the actual logic for selecting or moving things.
]]

-- Services
local Players: Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedFirst: ReplicatedFirst = game:GetService("ReplicatedFirst")
local TS: TweenService = game:GetService("TweenService")
local RS: RunService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService: CollectionService = game:GetService("CollectionService")
local UIS: UserInputService = game:GetService("UserInputService")

-- Variables
local OverheadCameraHandler: any = {}

--Objects
local overheadMenus: Folder = script.Parent.OverheadView.OverheadMenus
local NPCOverheadMenus: Folder = overheadMenus.NPCOverheadMenus
local ResourceNPCOverheadMenus: Folder = NPCOverheadMenus.ResourceNPCOverheadMenus
local MinerNPCOverheadMenu = require(ResourceNPCOverheadMenus.MinerNPCOverheadMenu)
local EnemyOverheadMenus: Folder = overheadMenus.EnemyOverheadMenus
local EnemyOverheadMenu = require(EnemyOverheadMenus.EnemyOverheadMenu)
local NPCCombatMenus: Folder = NPCOverheadMenus.CombatNPCOverheadMenus
local SwordsmanNPCOverheadMenu = require(NPCCombatMenus.SwordmanNPCOverheadMenu)
local resourceOverheadMenus: Folder = overheadMenus.ResourceOverheadMenus
local OreOverheadMenu = require(resourceOverheadMenus.OreOverheadMenu)

local Player: Player = Players.LocalPlayer
local playersMouse = Player:GetMouse()
local Camera: Camera = workspace.CurrentCamera
local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local Controls: any = require(Player.PlayerScripts.PlayerModule):GetControls()
local BridgeNet2: {} = require(game.ReplicatedStorage.BridgeNet2)
local Object: any = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local RaycastParams: RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Object:Supersedes(OverheadCameraHandler)

--Events
local TraverseNPCs: ExtType.Bridge = BridgeNet2.ReferenceBridge("TraverseNPCs")
local MinerNPCsCollect: ExtType.Bridge = BridgeNet2.ReferenceBridge("MinerNPCsCollect")

local tags: Folder = ReplicatedFirst:WaitForChild("UI"):WaitForChild("Tags")
local IconTable: { string } = {
	["Axe"] = tags.AxemanTag,
	["Pickaxe"] = tags.PickaxeManTag,
	["Sword"] = tags.SwordmanTag
}
-- Functions

--[[
@Description: Constructor for the overhead camera handler class. ONLY ONE OF THESE SHOULD EVER BE MADE!!!!!!
@Param Name (String): The name of the specific thing. Only exists for uniformity, shouldn't be set.
@Param CamPosition (Vector3): Legacy input for setting the first cameraposition.
@Return OverheadCameraHandler (Array): The constructed camera handler.
]]

function OverheadCameraHandler.new(Name, CamPosition, Whitelist, Blacklist): ExtType.ObjectInstance
	local self = Object.new(Name or "OverheadMap")
	setmetatable(self, OverheadCameraHandler)
	self.__CamPosition = CamPosition or Vector3.new(0, 100, 0)
	self.__Blacklist = Blacklist or {}
	RaycastParams.FilterDescendantsInstances = self.__Blacklist
	self.__PressKeyHandler = nil
	self.__ReleaseKeyhandler = nil
	self.__HeldKeyHandler = nil
	self.__ActiveTweens = {}
	self.__ActiveIcons = {}
	self.__Selected = {}
	self.__Active = false
	self.__Debounce = false
	self.__NPCMenus = {} --List of all npc menus where the character of NPC is the key
	Character:WaitForChild("Humanoid")
	self.__DeathConnection = Character.Humanoid.Died:Connect(function()
		self:Deactivate()
	end)
	self.__NewCharacterConnection = Player.CharacterAdded:Connect(function(NCharacter: Model)
		Character = NCharacter
		self.__DeathConnection:Disconnect()
		self.__DeathConnection = NCharacter.Humanoid.Died:Connect(function()
			self:Deactivate()
		end)
	end)
	self.__ActiveLoop = nil
	self.__ZoomLevel = 100
	self.__CamRotation = 0
	self.__SpecialTags = {}
	self.__UnitTags = {}
	self.__HostileTags = {}
	self.__FriendlyTags = {}
	self.__MaxZoom = 50
	self.__MinZoom = 200
	self:Enable()
	return self
end

--[[
@Description: Sets up the keybind connections needed for opening the map and other functions.
]]
function OverheadCameraHandler:Enable(): ()
	self.__PressKeyHandler = UIS.InputBegan:Connect(function(Input: InputObject, GME: boolean)
		--print("Key pressed")
		if GME then
			return
		end
		self:HandleKeyPressed(Input)
	end)

	self.__ReleaseKeyHandler = UIS.InputEnded:Connect(function(Input: InputObject, GME: boolean)
		if GME then
			return
		end
	end)

	self.__HeldKeyHandler = UIS.InputChanged:Connect(function(Input: InputObject, GME: boolean)
		if GME then
			return
		end
		self:InputChanged(Input)
	end)
end

--Table of selected waypoints for a sequence of the player clicking on the ground
--Clears if next click is not on the ground
local wayPointTable: {Vector3} = {}

local function GetNPCMenu(NPCharacter, Self): ExtType.ObjectInstance
	local menu = Self.__NPCMenus[NPCharacter]
	return menu
end

local function MinerNPCMenu(MinerNPC: Model, Self: ExtType.ObjectInstance) : ()
	local minerMenu: ExtType.ObjectInstance = GetNPCMenu(MinerNPC, Self)
	if minerMenu == nil then
		minerMenu = MinerNPCOverheadMenu.new("MinerNPC", MinerNPC)
		Self.__NPCMenus[MinerNPC] = minerMenu
	end
	--Move menu to where player clicked
	minerMenu:PlaceMenu(MinerNPC:GetPivot().Position)
	--Open the menu
	minerMenu:OpenMenu()
end

local function SwordsmanNPCMenu(SwordsmanNPC: Model, Self: ExtType.ObjectInstance) : ()
	local swordsmanMenu: ExtType.ObjectInstance = GetNPCMenu(SwordsmanNPC, Self)
	if swordsmanMenu == nil then
		swordsmanMenu = SwordsmanNPCOverheadMenu.new("MinerNPC", SwordsmanNPC)
		Self.__NPCMenus[SwordsmanNPC] = swordsmanMenu
	end
	--Move menu to where player clicked
	swordsmanMenu:PlaceMenu(SwordsmanNPC:GetPivot().Position)
	--Open the menu
	swordsmanMenu:OpenMenu()
end

--Helper function used to handle all NPCMenus within ShiftMouse3
local function NPCMenus(NPC: Model, Self: ExtType.ObjectInstance) : ()
	--Figure out what type of NPC it is
	if CollectionService:HasTag(NPC, "MinerNPC") then
		MinerNPCMenu(NPC, Self)
	elseif CollectionService:HasTag(NPC, "SwordsmanNPC") then
		SwordsmanNPCMenu(NPC, Self)
	end
end

--[[
Displays the list of
--]]
local function OreMenu(Ore: BasePart, Self: ExtType.ObjectInstance)  : ()
	--Get a list of all friendly combat NPCs
	local minerNPCs: {ExtType.ObjectInstance} = {}
	for _, item in pairs(Self.__Selected) do
		local isNPC: boolean = CollectionService:HasTag(item, "NPC")
		local isMinerNPC: boolean = CollectionService:HasTag(item, "MinerNPC")
		local isEnemyNPC: boolean = CollectionService:HasTag(item, "EnemyNPC")
		if not isNPC or not isMinerNPC or isEnemyNPC then
			continue --Not friendly combat NPC
		end
		table.insert(minerNPCs, item)
	end

	--Determine what was clicked on to act accordingly
	--Nothing meaningful was clicked so means trying to open normal menu of NPC away from it
	local oreMenu: ExtType.ObjectInstance = GetNPCMenu(Ore, Self)
	if oreMenu == nil then
		oreMenu = OreOverheadMenu.new("OreMenu", Ore, minerNPCs)
		Self.__NPCMenus[Ore] = oreMenu
	end
	--Move menu to where barbarian is
	oreMenu:PlaceMenu(Ore.Position)
	--Open the menu
	oreMenu:OpenMenu()
end

local function ResourceMenus(Resource: BasePart, Self: ExtType.ObjectInstance) : ()
	--Determine what type of resource it is
	if CollectionService:HasTag(Resource, "Lumber") then
		--Lumber
	elseif CollectionService:HasTag(Resource, "Ore") then
		--Ores
		OreMenu(Resource, Self)
	end
end

local function ExternalMinerNPCMenu(Self: ExtType.ObjectInstance, HitPos: Vector3, Target: BasePart, MinerNPC: Model)
	--Determine what was clicked on to act accordingly
	if CollectionService:HasTag(Target, "PlaceHolder") then
	else
		--Nothing meaningful was clicked so means trying to open normal menu of NPC away from it
		local minerMenu: ExtType.ObjectInstance = GetNPCMenu(MinerNPC, Self)
		if minerMenu == nil then
			minerMenu = MinerNPCOverheadMenu.new("MinerNPC", MinerNPC)
			Self.__NPCMenus[MinerNPC] = minerMenu
		end
		--Move menu to where player clicked
		minerMenu:PlaceMenu(HitPos)
		--Open the menu
		minerMenu:OpenMenu()
	end
end

--[[
Defines what happens when an NPC is selected but player opened menu 
after clicking somewhere other than the NPC
--]]
local function ExternalNPCMenus(Self: ExtType.ObjectInstance, HitPos: Vector3, Target: BasePart, SelectedNPC: Model)
	--Determine what External NPCMenu to use
	if CollectionService:HasTag(SelectedNPC, "MinerNPC") then
		ExternalMinerNPCMenu(Self, HitPos, Target, SelectedNPC)
	end
end

--[[
Helper function that determines what happens when Shift is clicked with mouse 3
	Reserved for displaying a list of options fro the object clicked on
--]]
local function ShiftMouse3(Self: ExtType.ObjectInstance)
	if not UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
		return
	end
	local target: BasePart = playersMouse.Target
	local hitPos: Vector3 = playersMouse.Hit.Position
	--Check if player has a single target selected
	--If single target selected then place menu on ground where clicked

	if CollectionService:HasTag(target, "Resource") then
		ResourceMenus(target, Self)
	else
		--External menu
		--Check for if multiple npcs are selected or only one
		local NPCCount: number = 0
		local lastNPC: Model = nil
		for _, item in pairs(Self.__Selected) do
			if CollectionService:HasTag(item, "NPC") and not CollectionService:HasTag(item, "EnemyNPC") then
				NPCCount = NPCCount + 1
				lastNPC = item
			end
		end
		if NPCCount == 1 then
			--Single npc external menu
			ExternalNPCMenus(Self, hitPos, target, lastNPC)
		end
	end
end

--[[
@Description: Handles a key being pressed when the handler has been properly enabled.
@Param Input (InputObject): Input object that holds all of the data for determing which key has been pressed.
]]
function OverheadCameraHandler:HandleKeyPressed(Input: InputObject): ()
	if Input.KeyCode == Enum.KeyCode.M then
		--print("Attempting to activate/deactivate map")
		if self.__Active == false then
			self:Activate()
		else
			self:Deactivate()
		end
	elseif Input.KeyCode == Enum.KeyCode.W and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.W) do
			task.wait(0.01)
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				self.__CamPosition += Vector3.new(0, 0, -5)
			else
				self.__CamPosition += Vector3.new(0, 0, -1)
			end
		end
	elseif Input.KeyCode == Enum.KeyCode.S and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.S) do
			task.wait(0.01)
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				self.__CamPosition += Vector3.new(0, 0, 5)
			else
				self.__CamPosition += Vector3.new(0, 0, 1)
			end
		end
	elseif Input.KeyCode == Enum.KeyCode.A and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.A) do
			task.wait(0.01)
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				self.__CamPosition += Vector3.new(-5, 0, 0)
			else
				self.__CamPosition += Vector3.new(-1, 0, 0)
			end
		end
	elseif Input.KeyCode == Enum.KeyCode.D and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.D) do
			task.wait(0.01)
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				self.__CamPosition += Vector3.new(5, 0, 0)
			else
				self.__CamPosition += Vector3.new(1, 0, 0)
			end
		end
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 and self.__Active then
		local HoveredOver: { any } = Player.PlayerGui:GetGuiObjectsAtPosition(Input.Position.X, Input.Position.Y)
		for i, v in pairs(HoveredOver) do
			if table.find(self.__ActiveIcons, v) then
				return
			end
		end
		for c, d in pairs(self.__ActiveIcons) do
			d.Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		end

		table.clear(self.__Selected)
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and self.__Active then
		--Loop through all NPCs and tell them to go to players current positon
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			--Linked way point
			table.insert(wayPointTable, playersMouse.Hit.Position)
		elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			--This keybind is reserved for poping up a menu for an objects option set
			--If the object has only one option then it defaults to doing that one option
			ShiftMouse3(self)
		else
			--only click so traverse
			table.insert(wayPointTable, playersMouse.Hit.Position)
			--Send message to server to traverse with all NPCs and waypoint
			local argsNPCs: {Model} = {}
			for _, item in pairs(self.__Selected) do
				if item:GetAttribute("NPC") and not CollectionService:HasTag(item, "EnemyNPC") then
					table.insert(argsNPCs, item)
				end
			end
			local eventArgs: ExtType.StrDict = {
				Waypoints = table.clone(wayPointTable),
				NPCs = argsNPCs,
			}
			TraverseNPCs:Fire(eventArgs)
			table.clear(wayPointTable) --Reset so next click doesnt reuse
		end
	elseif Input.KeyCode == Enum.KeyCode.LeftAlt and self.__Active then
		--Cancel all waypoints
		table.clear(wayPointTable)
	end
end

--[[
@Description: Handles the scrollwheel zooming in and out when the handler has been properly enabled.
@Param Input (InputObject): Input object that holds all of the data for determing which key has been pressed.
]]
function OverheadCameraHandler:InputChanged(Input: InputObject): ()
	if Input.UserInputType == Enum.UserInputType.MouseWheel and self.__Active then
		local Direction: number = Input.Position.Z < 0 and 2 or -2
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__ZoomLevel = math.clamp(self.__ZoomLevel + (Direction * 3), self.__MaxZoom, self.__MinZoom)
		else
			self.__ZoomLevel = math.clamp(self.__ZoomLevel + Direction, self.__MaxZoom, self.__MinZoom)
		end
		self.__CamPosition = Vector3.new(self.__CamPosition.X, self.__ZoomLevel, self.__CamPosition.Z)
	end
end

--[[
@Description: Disables the camera handler and disconnects all events and key handlers.
]]
function OverheadCameraHandler:Disable(): ()
	self.__PressKeyHandler:Disconnect()
	self.__ReleaseKeyHandler:Disconnect()
	self.__HeldKeyHandler:Disconnect()
	self:Deactivate()
end

--[[
@Description: Handles moving the camera to the overhead position, disabling the player's movement, and running a loop to move it to the points specified elsewhere.
@Param SetPosition (Vector3): The camera will zoom out to the position instead of above the character if it is supplied.
]]
function OverheadCameraHandler:Activate(SetPosition: Vector3): ()
	if self.__Active or self.__Debounce then
		return
	end
	self.__Debounce = true
	self.__Active = true
	Controls:Disable()
	self:UpdateTransparency()
	Camera.CameraType = Enum.CameraType.Scriptable
	local TargetPosition:Vector3 = SetPosition
		or Vector3.new(Character.HumanoidRootPart.Position.X, self.__ZoomLevel, Character.HumanoidRootPart.Position.Z)
	self.__CamPosition = TargetPosition
	local Tween: Tween = TS:Create(
		Camera,
		TweenInfo.new(2),
		{ CFrame = CFrame.new(TargetPosition) * CFrame.Angles(math.rad(-90), 0, math.rad(self.__CamRotation)) }
	)
	Player.PlayerGui.PlayerUI.Hotbar.GroupTransparency = 1
	Player.PlayerGui.PlayerUI.Hotbar.Interactable = false
	Tween:Play()
	Character:SetAttribute("InOverhead", true)
	Tween.Completed:Wait()
	self:SetupIcons()
	self:SetupBuildMenu()
	self.__Debounce = false
	self.__ActiveLoop = task.spawn(function()
		local TargetPos: Vector3 = TargetPosition
		local ActiveTween: Tween
		local ActiveRotationTween: Tween
		local TargetRotation: number = self.__CamRotation
		local Offset: Vector3 = Vector3.new(0, 0, 0)
		while task.wait() do
			local RayResult: RaycastResult =
				workspace:Raycast(self.__CamPosition, Vector3.new(0, -(self.__ZoomLevel - 1), 0), RaycastParams)
			if RayResult then
				Offset = Vector3.new(0, self.__ZoomLevel - RayResult.Distance, 0)
			else
				Offset = Vector3.new(0, 0, 0)
			end
			if TargetPos ~= (self.__CamPosition + Offset) then
				TargetPos = self.__CamPosition + Offset
				if ActiveTween then
					ActiveTween:Pause()
					ActiveTween:Destroy()
				end
				ActiveTween = TS:Create(
					Camera,
					TweenInfo.new(1),
					{ CFrame = CFrame.new(TargetPos) * CFrame.Angles(math.rad(-90), 0, math.rad(TargetRotation)) }
				)
				ActiveTween:Play()
			end
			if TargetRotation ~= self.__CamRotation then
				TargetRotation = self.__CamRotation
				if ActiveRotationTween then
					ActiveRotationTween:Pause()
					ActiveRotationTween:Destroy()
				end
				ActiveRotationTween = TS:Create(
					Camera,
					TweenInfo.new(0.01),
					{ CFrame = CFrame.new(TargetPos) * CFrame.Angles(math.rad(-90), 0, math.rad(TargetRotation)) }
				)
				ActiveRotationTween:Play()
			end
		end
	end)
end

--[[
@Description: Moves the camera back to the player and reattaches it, allowing the player to continue moving.
]]
function OverheadCameraHandler:Deactivate(): {}
	if not self.__Active or self.__Debounce then
		return
	end
	self.__Active = false
	self.__Debounce = true
	if self.__ActiveLoop then
		task.cancel(self.__ActiveLoop)
	end
	self:RemoveIcons()
	self:ClearBuildMenu()
	local Tween: Tween = TS:Create(
		Camera,
		TweenInfo.new(2),
		{ CFrame = CFrame.new(Character.HumanoidRootPart.Position) * CFrame.new(0, 1, 5) }
	)
	Tween:Play()
	Tween.Completed:Wait()
	Character:SetAttribute("InOverhead", false)
	self.__Debounce = false
	Player.PlayerGui.PlayerUI.Hotbar.GroupTransparency = 0
	Player.PlayerGui.PlayerUI.Hotbar.Interactable = true
	Controls:Enable()

	Camera.CameraType = Enum.CameraType.Custom
end

--[[
@Description: Checks for items tagged "MinimapInvisible" and the blacklist and sets their transparency to 1.
]]
function OverheadCameraHandler:UpdateTransparency(): ()
	local List: {Instance} = CollectionService:GetTagged("MinimapInvisible")

	for i, v in pairs(List) do
		self.__Blacklist[v] = v.Transparency
	end

	for i, v in pairs(self.__Blacklist) do
		i.Transparency = 1
	end
end

--[[
@Description: Makes all items on the blacklist visible at their original transparency.
]]
function OverheadCameraHandler:DisableTransparency(): ()
	for i, v in pairs(self.__Blacklist) do
		i.Transparency = v
	end
end

--[[
@Description: Updates the camera's position manually if the player is already in map view.
]]
function OverheadCameraHandler:UpdatePosition(Position: Vector3): {}
	self.__CamPosition = Position
end

--[[
@Description: Updates the camera's zoom manually if the player is already in map view.
]]
function OverheadCameraHandler:Zoom(Amount: number): {}
	self.__ZoomLevel = math.clamp(self.__ZoomLevel + Amount, self.__MaxZoom, self.__MinZoom)
end

--[[
@Description: Gets the camera's current position.
@Return: __CamPosition (Vector3): The camera's current vector
]]
function OverheadCameraHandler:GetCurrentPosition(): Vector3
	return self.__CamPosition
end

--[[
@Description: Gets the camera's current zoom level.
@Return: __ZoomLevel (Number): The camera's current zoom
]]
function OverheadCameraHandler:GetCurrentZoom(): number
	return self.__ZoomLevel
end

--[[
@Description: addsa an item from the blacklist and makes it invisible, if it's not on the list.
@Param: Item (BasePart): The item to be added to the blacklist.
]]
function OverheadCameraHandler:AddItemToBlacklist(Item: BasePart): ()
	if not self.__Blacklist[Item] then
		self.__Blacklist[Item] = Item.Transparency
		self:UpdateTransparency()
	end
end

--[[
@Description: Removes an item from the blacklist and makes it visible, if it's on the list.
@Param: Item (BasePart): The item to be removed from the blacklist.
]]
function OverheadCameraHandler:RemoveItemFromBlacklist(Item: BasePart): ()
	if self.__Blacklist[Item] then
		self:DisableTransparency()
		self.__Blacklist[Item] = nil
		self:UpdateTransparency()
	end
end

--[[
@Description: Gets the camera's current position.
@Param: BlacklistTable (Array): The array to replace the current blacklist array, should be formatted Array[Item] = Item.Transparency
]]
function OverheadCameraHandler:SetBlacklist(BlacklistTable: {}): ()
	self.__Blacklist = BlacklistTable
	self:DisableTransparency()
	self:UpdateTransparency()
end

--[[
Highlights a given tags background
--]]
local function HighlightTag(Tag:{ Background: { BorderColor3: Color3 } })
	Tag.Background.BorderColor3 = Color3.fromRGB(255, 255, 255)
end

local function BarbarianMenus(Barbarian: Model, Self: ExtType.ObjectInstance)
	--Get a list of all friendly combat NPCs
	local combatNPCs: {Model} = {}
	for _, item in pairs(Self.__Selected) do
		local isNPC: boolean = CollectionService:HasTag(item, "NPC")
		local isCombatNPC: boolean = CollectionService:HasTag(item, "CombatNPC")
		local isEnemyNPC: boolean = CollectionService:HasTag(item, "EnemyNPC")
		if not isNPC or not isCombatNPC or isEnemyNPC then
			continue --Not friendly combat NPC
		end
		table.insert(combatNPCs, item)
	end

	--Determine what was clicked on to act accordingly
	--Nothing meaningful was clicked so means trying to open normal menu of NPC away from it
	local barbarianMenu: ExtType.ObjectInstance = GetNPCMenu(Barbarian, Self)
	if barbarianMenu == nil then
		barbarianMenu = EnemyOverheadMenu.new("EnemyMenu", Barbarian, combatNPCs)
		Self.__NPCMenus[Barbarian] = barbarianMenu
	end
	--Move menu to where barbarian is
	barbarianMenu:PlaceMenu(Barbarian:GetPivot().Position)
	--Open the menu
	barbarianMenu:OpenMenu()
end

local function SetUpBarbarianActions(Barbarian, Button, Icon, Self)
	--Set up what happens when a player clicks the button with right shift
	Button.MouseButton2Click:Connect(function()
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			--use NPCMenu Pop up
			HighlightTag(Icon)
			table.insert(Self.__Selected, Barbarian)
			BarbarianMenus(Barbarian, Self)
		end
	end)
end

local function PrepIcons(Self, WorldItem)
	if not IconTable[WorldItem:GetAttribute("Type")] then
		return
	end
	Self.__ActiveIcons[WorldItem] = IconTable[WorldItem:GetAttribute("Type")]:Clone()
	Self.__ActiveIcons[WorldItem].Parent = Player.PlayerGui
	if WorldItem:IsA("BasePart") then
		Self.__ActiveIcons[WorldItem].Adornee = WorldItem
	elseif WorldItem:IsA("Model") then
		Self.__ActiveIcons[WorldItem].Adornee = WorldItem:FindFirstChild(WorldItem:GetAttribute("AttachTo"))
	end
	if WorldItem:GetAttribute("Owner") ~= Player.Name then
		Self.__ActiveIcons[WorldItem].Background.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		table.insert(Self.__HostileTags, Self.__ActiveIcons[WorldItem])
		SetUpBarbarianActions(WorldItem, Self.__ActiveIcons[WorldItem].TextButton, Self.__ActiveIcons[WorldItem], Self)
	else
		table.insert(Self.__FriendlyTags, Self.__ActiveIcons[WorldItem])
		Self.__ActiveIcons[WorldItem].TextButton.MouseButton1Click:Connect(function()
			if not UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
				for c, d in pairs(Self.__ActiveIcons) do
					d.Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
				end
				table.clear(Self.__Selected)
				table.insert(Self.__Selected, WorldItem)
				Self.__ActiveIcons[WorldItem].Background.BorderColor3 = Color3.fromRGB(255, 255, 255)
			else
				table.insert(Self.__Selected, WorldItem)
				Self.__ActiveIcons[WorldItem].Background.BorderColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
		--Add suport for pop up menus for NPCs
		Self.__ActiveIcons[WorldItem].TextButton.MouseButton2Click:Connect(function()
			--use NPCMenu Pop up
			HighlightTag(Self.__ActiveIcons[WorldItem])
			table.insert(Self.__Selected, WorldItem)
			NPCMenus(WorldItem, Self)
		end)
	end
	if WorldItem:GetAttribute("NPC") and not CollectionService:HasTag(WorldItem, "EnemyNPC") then
		table.insert(Self.__UnitTags, Self.__ActiveIcons[WorldItem])
	end
end

--[[
@Description: Adds icons to predetermined and tagged units based on their attributes when the camera is first activated.
]]
function OverheadCameraHandler:SetupIcons(): ()
	for _, v in pairs(self.__ActiveIcons) do
		v:Destroy()
	end
	local Tagged = CollectionService:GetTagged("OverheadUnit")
	for _, worldItem in pairs(Tagged) do
		PrepIcons(self, worldItem)
	end
	CollectionService:GetInstanceAddedSignal("OverheadUnit"):Connect(function(WorldItem)
		PrepIcons(self, WorldItem)
	end)
end

--[[
@Description: Populates the build menu GUI dynamically with all models that are children of the TargetFolder and allows them to be clicked on and placed.
@Param: TargetFolder (Folder): The folder that the menu should dynamically populate from.
]]
function OverheadCameraHandler:PopulateBuildMenu(TargetFolder: Folder): {}
	local GUI: CanvasGroup = Player.PlayerGui.PlayerUI.Overhead
	GUI.Selection.GroupTransparency = 0
	GUI.Selection.Interactable = true
	GUI.Selection.SelectionHolder.Active = true
	GUI.Selection.SelectionHolder.Visible = true
	for i, v in pairs(GUI.Selection.SelectionHolder:GetChildren()) do
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
	for i, v in pairs(TargetFolder:GetChildren()) do
		local C: Frame = GUI.Templates.Building:Clone()
		C.Interactable = true
		C.Visible = true
		C.BuildingName.Text = v.Name
		C.Parent = GUI.Selection.SelectionHolder
		local Viewport: ViewportFrame = C.ViewportFrame
		local Camera: Camera = Instance.new("Camera")
		Camera.Parent = Viewport
		Camera.CFrame = CFrame.new(0, 15, 50)
		Viewport.CurrentCamera = Camera
		local Model: Model = v:Clone()
		Model:PivotTo(CFrame.new(0, 0, 0))
		Model.Parent = Viewport
		Camera.CameraSubject = Model.PrimaryPart
		C.Select.MouseButton1Click:Connect(function()
			-- INSERT CODE HERE
			local PlaceBuilding = require(game.StarterPlayer.StarterPlayerScripts.PlaceBuilding)
			local replicatedStorage = game:GetService("ReplicatedStorage")
			local Bulidings = replicatedStorage:FindFirstChild("Buildings")
			local BuildingToPlace = Bulidings:FindFirstChild(v.Name, true)

			local player = Players.LocalPlayer

			local playerPlotTemplate =
				workspace.PlayersWorkspace[player.Name].PlayerPlots.PlayerPlot:FindFirstChild("PlayerPlotTemplate")

			local PlaceBuildingInstance = PlaceBuilding.new("PlaceBuildingInstance")
			PlaceBuildingInstance:PlaceBuilding(playerPlotTemplate, BuildingToPlace, player)

			GUI.Selection.GroupTransparency = 0
			GUI.Selection.Interactable = false
			for i, v in pairs(GUI.Selection.SelectionHolder:GetChildren()) do
				if not v:IsA("UIListLayout") then
					v:Destroy()
				end
			end
		end)
	end
end

--[[
@Description: Sets up the build menu when the player first enters the camera via making it visible and populating it with all of the categories present.
]]
function OverheadCameraHandler:SetupBuildMenu(): {}
	local GUI: CanvasGroup = Player.PlayerGui.PlayerUI.Overhead
	GUI.GroupTransparency = 0
	GUI.Interactable = true
	GUI.Holder.Active = true
	GUI.Holder.Visible = true
	for i, v in pairs(game:GetService("ReplicatedStorage").Buildings:GetChildren()) do
		local C: TextButton = GUI.Templates.Selection:Clone()
		C.Interactable = true
		C.Visible = true
		C.Text = v.Name
		C.Parent = GUI.Holder
		C.MouseButton1Click:Connect(function()
			self:PopulateBuildMenu(v)
		end)
	end
end

--[[
@Description: Clears the build menu and makes it invisible when the player exits the overhead view.
]]
function OverheadCameraHandler:ClearBuildMenu(): {}
	local GUI: CanvasGroup = Player.PlayerGui.PlayerUI.Overhead
	GUI.GroupTransparency = 1
	GUI.Selection.GroupTransparency = 1
	GUI.Interactable = false
	GUI.Selection.Interactable = false
	GUI.Holder.Active = false
	GUI.Holder.Visible = false
	GUI.Selection.SelectionHolder.Active = false
	GUI.Selection.SelectionHolder.Visible = false
	for i, v in pairs(GUI.Holder:GetChildren()) do
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
	for i, v in pairs(GUI.Selection.SelectionHolder:GetChildren()) do
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
end

--[[
@Description: Removes all active icons regardless of category or team.
]]
function OverheadCameraHandler:RemoveIcons(): {}
	for i, v in pairs(self.__ActiveIcons) do
		v:Destroy()
	end
	table.clear(self.__Selected)
	table.clear(self.__UnitTags)
	table.clear(self.__HostileTags)
	table.clear(self.__FriendlyTags)
	--Close all pop up menus
	for _, menu in pairs(self.__NPCMenus) do
		menu:CloseMenu()
	end
end
return OverheadCameraHandler
