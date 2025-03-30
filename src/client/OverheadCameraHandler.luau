--[[  
 * THIS CLASS EXTENDS CLASS: OBJECT
 * OverheadCamerHandler - Superclass of all methods using the overhead tactical view.  
 *  
 * This class represents the command & control structure for the player's overhead camera view, and handles
 * camera movement and basic unit icons. It does NOT handle the actual logic for selecting or moving things.
]]



-- Services
local Players : Players = game:GetService("Players")
local TS: TweenService = game:GetService("TweenService")
local RS: RunService = game:GetService("RunService")
local CS : CollectionService = game:GetService("CollectionService")
local UIS : UserInputService = game:GetService("UserInputService")

-- Variables
local OverheadCameraHandler : table = {}

local Player : Player = Players.LocalPlayer
local Camera : Camera = workspace.CurrentCamera
local Character : Model = Player.Character or Player.CharacterAdded:Wait()
local Controls : table = require(Player.PlayerScripts.PlayerModule):GetControls()
--local BridgeNet2 : table = require(game.ReplicatedStorage.BridgeNet2)
local Object : table = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Object:Supersedes(OverheadCameraHandler)

-- Functions

--[[
@Description: Constructor for the overhead camera handler class. ONLY ONE OF THESE SHOULD EVER BE MADE!!!!!!
@Param Name (String): The name of the specific thing. Only exists for uniformity, shouldn't be set.
@Param CamPosition (Vector3): Legacy input for setting the first cameraposition.
@Return OverheadCameraHandler (Array): The constructed camera handler.
]]

function OverheadCameraHandler.new(Name, CamPosition, Whitelist, Blacklist) : {}
	local self = Object.new(Name or "OverheadMap")
	setmetatable(self, OverheadCameraHandler)
	self.__CamPosition = CamPosition or Vector3.new(0,100,0)
	self.__Blacklist = Blacklist or {}
	RaycastParams.FilterDescendantsInstances = self.__Blacklist
	self.__PressKeyHandler = nil
	self.__ReleaseKeyhandler = nil
	self.__HeldKeyHandler = nil
	self.__ActiveTweens = {}
	self.__Active = false
	self.__DeathConnection = Character.Humanoid.Died:Connect(function()
		self:Deactivate()
	end)
	self.__NewCharacterConnection = Player.CharacterAdded:Connect(function(NCharacter : Model)
		Character = NCharacter
		self.__DeathConnection:Disconnect()
		self.__DeathConnection = NCharacter.Humanoid.Died:Connect(function()
			self:Deactivate()
		end)
	end)
	self.__ActiveLoop = nil
	self.__ZoomLevel  = 100
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
function OverheadCameraHandler:Enable() : {}
	self.__PressKeyHandler = UIS.InputBegan:Connect(function(Input : InputObject, GME : boolean)
		print("Key pressed")
		if GME then return end
        self:HandleKeyPressed(Input)
	end)
	
	self.__ReleaseKeyHandler = UIS.InputEnded:Connect(function(Input : InputObject, GME : boolean)
		if GME then return end
	end)
	
	self.__HeldKeyHandler = UIS.InputChanged:Connect(function(Input : InputObject, GME :boolean)
		if GME then return end
		self:InputChanged(Input)
	end)
end

--[[
@Description: Handles a key being pressed when the handler has been properly enabled.
@Param Input (InputObject): Input object that holds all of the data for determing which key has been pressed.
]]
function OverheadCameraHandler:HandleKeyPressed(Input : InputObject) : ()
	if Input.KeyCode == Enum.KeyCode.M then
		print("Attempting to activate/deactivate map")
		if self.__Active == false then
			self:Activate()
		else
			self:Deactivate()
		end

	elseif Input.KeyCode == Enum.KeyCode.W and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.W) do
			task.wait(0.01)
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__CamPosition += Vector3.new(0,0,-5)
		else
			self.__CamPosition += Vector3.new(0,0,-1)
			end
			end
	elseif Input.KeyCode == Enum.KeyCode.S and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.S) do
			task.wait(0.01)
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__CamPosition += Vector3.new(0,0,5)
		else
			self.__CamPosition += Vector3.new(0,0,1)
			end
			end
	elseif Input.KeyCode== Enum.KeyCode.A and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.A) do
			task.wait(0.01)
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__CamPosition += Vector3.new(-5,0,0)
		else
			self.__CamPosition += Vector3.new(-1,0,0)
			end
			end
	elseif Input.KeyCode == Enum.KeyCode.D and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.D) do
			task.wait(0.01)
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__CamPosition += Vector3.new(5,0,0)
		else
			self.__CamPosition += Vector3.new(1,0,0)
			end
		end
	--[[elseif Input.KeyCode == Enum.KeyCode.E and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.E) do
			task.wait(0.01)
				self.__CamRotation += 1
		end
	elseif Input.KeyCode == Enum.KeyCode.Q and self.__Active then
		while UIS:IsKeyDown(Enum.KeyCode.Q) do
			task.wait(0.01)
			self.__CamRotation -= 1
		end]]
	end
end

--[[
@Description: Handles the scrollwheel zooming in and out when the handler has been properly enabled.
@Param Input (InputObject): Input object that holds all of the data for determing which key has been pressed.
]]
function OverheadCameraHandler:InputChanged(Input : InputObject) : {}
	if Input.UserInputType == Enum.UserInputType.MouseWheel and self.__Active then
		local Direction : number = Input.Position.Z < 0 and 2 or -2
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			self.__ZoomLevel = math.clamp(self.__ZoomLevel + (Direction * 3), self.__MaxZoom, self.__MinZoom)
		else
			self.__ZoomLevel = math.clamp(self.__ZoomLevel + (Direction), self.__MaxZoom, self.__MinZoom)
		end
		self.__CamPosition = Vector3.new(self.__CamPosition.X, self.__ZoomLevel, self.__CamPosition.Z)
		end
end

--[[
@Description: Disables the camera handler and disconnects all events and key handlers.
]]
function OverheadCameraHandler:Disable() : {}
	self.__PressKeyHandler:Disconnect()
	self.__ReleaseKeyHandler:Disconnect()
	self.__HeldKeyHandler:Disconnect()
	self:Deactivate()
end

--[[
@Description: Handles moving the camera to the overhead position, disabling the player's movement, and running a loop to move it to the points specified elsewhere.
@Param SetPosition (Vector3): The camera will zoom out to the position instead of above the character if it is supplied.
]]
function OverheadCameraHandler:Activate(SetPosition : Vector3) : {}
	if self.__Active then return end
	print("Activating")
	self.__Active = true
	Controls:Disable()
	self:UpdateTransparency()
	Camera.CameraType = Enum.CameraType.Scriptable
	local TargetPosition = SetPosition or Vector3.new(Character.HumanoidRootPart.Position.X, self.__ZoomLevel, Character.HumanoidRootPart.Position.Z)
	self.__CamPosition = TargetPosition
	local Tween = TS:Create(Camera, TweenInfo.new(2), {CFrame = CFrame.new(TargetPosition) * CFrame.Angles(math.rad(-90),0,math.rad(self.__CamRotation))})
	Tween:Play()
	Tween.Completed:Wait()
	self.__ActiveLoop = task.spawn(function()
		local TargetPos : Vector3 = TargetPosition
		local ActiveTween : Tween
		local ActiveRotationTween : Tween
		local TargetRotation : number = self.__CamRotation
		local Offset : Vector3 = Vector3.new(0,0,0)
		while task.wait() do
			local RayResult : RaycastResult = workspace:Raycast(self.__CamPosition, Vector3.new(0,-(self.__ZoomLevel - 1),0), RaycastParams)
			if RayResult then
				Offset = Vector3.new(0,self.__ZoomLevel - RayResult.Distance,0)
			else
				Offset = Vector3.new(0,0,0)
			end
			if TargetPos ~= (self.__CamPosition + Offset) then
				TargetPos = self.__CamPosition + Offset
				if ActiveTween then
					ActiveTween:Pause()
					ActiveTween:Destroy()
				end
				ActiveTween = TS:Create(Camera, TweenInfo.new(1), {CFrame = CFrame.new(TargetPos) * CFrame.Angles(math.rad(-90),0,math.rad(TargetRotation))})
				ActiveTween:Play()
			end
			if TargetRotation ~= self.__CamRotation then
				TargetRotation = self.__CamRotation
				if ActiveRotationTween then
					ActiveRotationTween:Pause()
					ActiveRotationTween:Destroy()
				end
				ActiveRotationTween = TS:Create(Camera, TweenInfo.new(0.01), {CFrame = CFrame.new(TargetPos) * CFrame.Angles(math.rad(-90),0,math.rad(TargetRotation))})
				ActiveRotationTween:Play()
			end
		end
	end)
end

--[[
@Description: Moves the camera back to the player and reattaches it, allowing the player to continue moving.
]]
function OverheadCameraHandler:Deactivate() : {}
	if not self.__Active then return end
	self.__Active = false
	local Tween = TS:Create(Camera, TweenInfo.new(2), {CFrame = CFrame.new(Character.HumanoidRootPart.Position) * CFrame.Angles(0,0,0) * CFrame.new(0,1,5)})
	Tween:Play()
	Tween.Completed:Wait()
	Controls:Enable()

	Camera.CameraType = Enum.CameraType.Custom
    
end

--[[
@Description: Checks for items tagged "MinimapInvisible" and the blacklist and sets their transparency to 1.
]]
function OverheadCameraHandler:UpdateTransparency() : {}
	local List : table = CS:GetTagged("MinimapInvisible")
	
	for i,v in pairs(List) do
		self.__Blacklist[v] = v.Transparency
	end
	
	for i,v in pairs(self.__Blacklist) do
		i.Transparency = 1
	end
end

--[[
@Description: Makes all items on the blacklist visible at their original transparency.
]]
function OverheadCameraHandler:DisableTransparency() : {}
	for i,v in pairs(self.__Blacklist) do
		i.Transparency = v
	end
end

--[[
@Description: Updates the camera's position manually if the player is already in map view.
]]
function OverheadCameraHandler:UpdatePosition(Position : Vector3) : {}
  self.__CamPosition = Position
end

--[[
@Description: Updates the camera's zoom manually if the player is already in map view.
]]
function OverheadCameraHandler:Zoom(Amount : number) : {}
	self.__ZoomLevel = math.clamp(self.__ZoomLevel + Amount, self.__MaxZoom, self.__MinZoom)
end

--[[
@Description: Gets the camera's current position.
@Return: __CamPosition (Vector3): The camera's current vector
]]
function OverheadCameraHandler:GetCurrentPosition() : Vector3
	return self.__CamPosition
end

--[[
@Description: Gets the camera's current zoom level.
@Return: __ZoomLevel (Number): The camera's current zoom
]]
function OverheadCameraHandler:GetCurrentZoom() : number
	return self.__ZoomLevel
end

--[[
@Description: addsa an item from the blacklist and makes it invisible, if it's not on the list.
@Param: Item (BasePart): The item to be added to the blacklist.
]]
function OverheadCameraHandler:AddItemToBlacklist(Item : BasePart) : {}
	if not self.__Blacklist[Item] then
		self.__Blacklist[Item] = Item.Transparency
		self:UpdateTransparency()
	end
end

--[[
@Description: Removes an item from the blacklist and makes it visible, if it's on the list.
@Param: Item (BasePart): The item to be removed from the blacklist.
]]
function OverheadCameraHandler:RemoveItemFromBlacklist(Item : BasePart) : {}
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
function OverheadCameraHandler:SetBlacklist(BlacklistTable : table) : {}
	self.__Blacklist = BlacklistTable
	self:DisableTransparency()
	self:UpdateTransparency()
end

--[[
@Description: Placeholder function for when icons are added.
]]
function OverheadCameraHandler:UpdateIcons() : {}
	
end

return OverheadCameraHandler