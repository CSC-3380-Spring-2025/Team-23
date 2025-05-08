local Players : Players = game:GetService("Players")

--Variables
local BridgeNet2 : {any} = require(game.ReplicatedStorage.BridgeNet2)
local UserInputService : UserInputService = game:GetService("UserInputService")
local Player : Player = Players.LocalPlayer
local GUI : ScreenGui = Player.PlayerGui:WaitForChild("PlayerUI")
local Hotbar : CanvasGroup = GUI.Hotbar
local Backpack : CanvasGroup = GUI.Backpack
local PlayerBackpack : Backpack = Player.Backpack
local Object : any = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local StarterGui : StarterGui = game:GetService("StarterGui")
local ClientBackpackHandler : table = {}
local CurrentContents : {any} = {}
local CurrentlyEquipped : {any} = {}
local CurrentlyEquippedTool : Tool
local CurrentlyEquippedSlot : Frame
ClientBackpackHandler.__index = ClientBackpackHandler
Object:Supersedes(ClientBackpackHandler)

local GetContents : {} = BridgeNet2.ReferenceBridge("GetContents")
local EquipItem : {} = BridgeNet2.ReferenceBridge("EquipItem")
local MoveItemToHotbar : {} = BridgeNet2.ReferenceBridge("MoveItemToHotbar")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
local Keycodes : {Enum.KeyCode} = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero
}
function ClientBackpackHandler:GetNewContents() : boolean
	CurrentContents = {}
	GetContents:Fire()
	repeat task.wait() until self.__Received == true
	self:SetupHotbar()
	return true
end

function ClientBackpackHandler:HandleEquip(Slot : Frame) : {}
	if CurrentlyEquippedTool then
		local Humanoid : Humanoid = Player.Character.Humanoid
		CurrentlyEquippedSlot.Equipped.Enabled = false
		if not Humanoid then return end
		Humanoid:UnequipTools()
	end
	local ToolName : string = Slot:GetAttribute("ToolName")
	if not ToolName then return end
	local FoundTool : Tool = PlayerBackpack:FindFirstChild(ToolName)
	if not FoundTool then return end
	if CurrentlyEquippedTool == FoundTool then CurrentlyEquippedTool = nil CurrentlyEquippedSlot = nil return end
	local Humanoid : Humanoid = Player.Character.Humanoid
	if not Humanoid then return end
		Humanoid:EquipTool(FoundTool)
	CurrentlyEquippedTool = FoundTool
	CurrentlyEquippedSlot = Slot
	Slot.Equipped.Enabled = true
end

function ClientBackpackHandler:SetupHotbar() : {}
	if CurrentContents == {} then return end
	for __ : Frame, Target : Frame in pairs(Hotbar.Holder:GetChildren()) do
		if Target:IsA("UIListLayout") then continue end
		if #Target.ViewportFrame:GetChildren() > 0 then
			Target.ViewportFrame:ClearAllChildren()
			Target:SetAttribute("ToolName", nil)
			--self.__EquippedConnections[Target]:Disconnect()
			self.__EquippedConnections[Target] = nil
		end
	end
	for Index : number, ModelData : any in pairs(CurrentlyEquipped) do
		local Slot : Frame = Hotbar.Holder:FindFirstChild(tostring(Index))
		if not Slot then continue end
		self.__EquippedConnections[Slot] = true
		Slot:SetAttribute("ToolName", ModelData.Name)
		Slot:SetAttribute("ToolID", ModelData.ToolID)
		Slot.ItemData.Text = ModelData.Name
		local Camera = Instance.new("Camera", Slot.ViewportFrame)
		Slot.ViewportFrame.CurrentCamera = Camera
		local Item : any = game.ReplicatedStorage.ItemDrops:FindFirstChild(ModelData.Name)
		if not Item then return end
		local Model : Model = Instance.new("Model", Slot.ViewportFrame)
		local Tool : Tool = Item:Clone()
		Tool:PivotTo(CFrame.new(0,0,0))
			for c,d in pairs(Tool:GetChildren()) do
				if not d:IsA("BasePart") then
					d:Destroy()
				else
					d.Parent = Model
				end
			end
			Camera.CameraSubject = Model
			Camera.CFrame = CFrame.new(2,0,0)
	end
end

function ClientBackpackHandler:EquipToHotbar(Slot) : {}
	if not self.__BackpackSelection then return end
	local ItemName : string = self.__BackpackSelection:GetAttribute("ToolName")
	local ItemID : string = self.__BackpackSelection:GetAttribute("ToolID")
	self.__BackpackSelection:Destroy()
	if CurrentlyEquipped[tonumber(Slot.Name)] then
		if CurrentlyEquippedTool and CurrentlyEquippedSlot == Slot then
			local Humanoid : Humanoid = Player.Character.Humanoid
			CurrentlyEquippedSlot.Equipped.Enabled = false
			CurrentlyEquippedTool = nil
			CurrentlyEquippedSlot = nil
			CurrentlyEquippedSlot.ItemData.Visible = false
			if not Humanoid then return end
			Humanoid:UnequipTools()
		end
		CurrentlyEquipped[tonumber(Slot.Name)] = nil
		local Target : Frame = Slot
		Target.ViewportFrame:ClearAllChildren()
		Target:SetAttribute("ToolName", nil)
		--self.__EquippedConnections[Target]:Disconnect()
		self.__EquippedConnections[Target] = nil
	end
	for i,v in pairs(CurrentContents) do
		if v["ToolID"] and v["ToolID"] == ItemID then
			CurrentlyEquipped[tonumber(Slot.Name)] = v
			self.__EquippedConnections[Slot] = true
			Slot.ItemData.Text = ItemName
			Slot.ItemData.Visible = true
			Slot:SetAttribute("ToolName", v.Name)
			Slot:SetAttribute("ToolID", v.ToolID)
			local Camera = Instance.new("Camera", Slot.ViewportFrame)
			Slot.ViewportFrame.CurrentCamera = Camera
			local Item : any = game.ReplicatedStorage.ItemDrops:FindFirstChild(ItemName)
			if not Item then return end
			local Model : Model = Instance.new("Model", Slot.ViewportFrame)
			local Tool : Tool = Item:Clone()
			Tool:PivotTo(CFrame.new(0,0,0))
			for c,d in pairs(Tool:GetChildren()) do
				if not d:IsA("BasePart") then
					d:Destroy()
				else
					d.Parent = Model
				end
			end
			Camera.CameraSubject = Model
			Camera.CFrame = CFrame.new(2,0,0)
			self.__BackpackSelection = nil
			self:PopulateBackpack()
				break
			end
		end
end
function ClientBackpackHandler:PopulateBackpack() : {}
	for i,v in pairs(Backpack.Holder:GetChildren()) do
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
	for i,v in pairs(CurrentContents) do
		if table.find(CurrentlyEquipped, v) then continue end
		local Clone : Frame = Backpack.Template.ItemTemplate:Clone()
		Clone.Parent = Backpack.Holder
		Clone.Visible = true
		Clone.ItemData.Text = tostring(v.Stack).."x "..v.Name
		local Camera = Instance.new("Camera", Clone.ViewportFrame)
		Clone.ViewportFrame.CurrentCamera = Camera
		local Item : any = game.ReplicatedStorage.ItemDrops:FindFirstChild(v.Name)
		if not Item then return end
		if Item:IsA("BasePart") then
			Item = Item:Clone()
			Item.Parent = Clone.ViewportFrame
			Item.CFrame = CFrame.new(0,0,0)
			Camera.CameraSubject = Item
			Camera.CFrame = CFrame.new(2,0,0)
		elseif Item:IsA("Tool") then
			local Model : Model = Instance.new("Model", Clone.ViewportFrame)
			local Tool : Tool = Item:Clone()
			Tool:PivotTo(CFrame.new(0,0,0))
			for c,d in pairs(Tool:GetChildren()) do
				if not d:IsA("BasePart") then
					d:Destroy()
				else
					d.Parent = Model
				end
			end
			Camera.CameraSubject = Model
			Camera.CFrame = CFrame.new(2,0,0)
		elseif Item:IsA("Model") then
			local Model : Model = Item:Clone()
			Model:PivotTo(CFrame.new(0,0,0))
			Camera.CameraSubject = Item
			Camera.CFrame = CFrame.new(2,0,0)
		end
		if v["ToolID"] then
			Clone:SetAttribute("ToolName", v.Name)
			Clone:SetAttribute("ToolID", v.ToolID)
		self.__BackpackConnections[Clone] = Clone.TextButton.MouseButton1Click:Connect(function()
			if self.__BackpackSelection then
				self.__BackpackSelection.ItemSelected.Enabled = false
			end
			self.__BackpackSelection = Clone
			Clone.ItemSelected.Enabled = true
			end)
			end
	end
end

function ClientBackpackHandler:ToggleBackpack() : {}
	self.__BackpackOpen = not self.__BackpackOpen
	if self.__BackpackOpen then
		Backpack.GroupTransparency = 0
		Backpack.Holder.Visible = true
		Backpack.Interactable = true
		local BackpackUI : TextButton = Backpack.Background.TextButton
		self.__BackpackClickedConnection = BackpackUI.MouseButton1Click:Connect(function()
			if self.__BackpackSelection then
					if CurrentlyEquippedTool and CurrentlyEquippedSlot == self.__BackpackSelection then
						local Humanoid : Humanoid = Player.Character.Humanoid
						CurrentlyEquippedSlot.Equipped.Enabled = false
						CurrentlyEquippedTool = nil
						CurrentlyEquippedSlot = nil
						CurrentlyEquippedSlot.ItemData.Visible = false
						if not Humanoid then return end
						Humanoid:UnequipTools()
					end
					CurrentlyEquipped[tonumber(self.__BackpackSelection.Name)] = nil
					local Target : Frame = self.__BackpackSelection
					Target.ViewportFrame:ClearAllChildren()
					Target:SetAttribute("ToolName", nil)
					--self.__EquippedConnections[Target]:Disconnect()
				self.__EquippedConnections[Target] = nil
				self.__BackpackSelection.Equipped.Enabled = false
				self.__BackpackSelection = nil
				self:PopulateBackpack()
			end
		end)
	else
		if self.__BackpackClickedConnection then
			self.__BackpackClickedConnection:Disconnect()
		end
		if self.__BackpackSelection then
			self.__BackpackSelection.ItemSelected.Enabled = false
			self.__BackpackSelection = nil
		end
		if self.__HotbarSelection then
			self.__HotbarSelection.Equipped.Enabled = true
			self.__HotbarSelection  = nil
			end
		Backpack.GroupTransparency = 1
		Backpack.Holder.Visible = false
		Backpack.Interactable = false
	end
end
function ClientBackpackHandler.new() : {}
	local self = Object.new("ClientBackpackHandler")
	setmetatable(self, ClientBackpackHandler)
	self.__EquippedConnections = {}
	self.__BackpackConnections = {}
	self.__BackpackSelection = nil
	self.__BackpackOpen = false
	self.GetContents = GetContents:Connect(function(Contents : {any})
		self.__Received = false
		CurrentContents = Contents["Contents"]
		if CurrentlyEquipped ~= Contents["ToolbarItems"] then
			self:SetupHotbar()
		end
		CurrentlyEquipped = Contents["ToolbarItems"]
		self:PopulateBackpack()
		self.__Recieved = true
	end)
	task.delay(2, function()
		self:GetNewContents()
	end)
	UserInputService.InputEnded:Connect(function(Input : InputObject, GME : boolean)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.__Button1Down = false
		end
	end)
	UserInputService.InputBegan:Connect(function(Input : InputObject, GME : boolean)
		if GME then return end
		if Input.KeyCode == Enum.KeyCode.B then
			self:ToggleBackpack()
		end
		for i,v in pairs(self.__EquippedConnections) do
			print(i.Name)
			print(Keycodes[tonumber(i.Name)])
			if Input.KeyCode == Keycodes[tonumber(i.Name)] then
				print("Here")
				self:HandleEquip(i)
				break
			end
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.__Button1Down = true
		end
	end)
	for i,v in pairs(Hotbar.Holder:GetChildren()) do
		if v:IsA("UIListLayout") then continue end
		v.TextButton.MouseButton1Click:Connect(function()
			if self.__BackpackSelection then
				self:EquipToHotbar(v)
			else
				self:HandleEquip(v.Name)
			--elseif self.__BackpackOpen and CurrentlyEquipped[tonumber(v.Name)] then
			--	self.__HotbarSelection = v
			--	v.Equipped.Enabled = true
			end
		end)
	end
	return self
end

ClientBackpackHandler.new()