--[[  
 * THIS CLASS INHERITS FROM CLASS: OBJECT
 * This class represents a full set of functions to control the Player's UI
 * without having to directly interact with it. This includes adjusting display bars,
 * Displaying the inventory, and equipping/unequipping tools.
]]


-- Services
local Players : Players = game:GetService("Players")
local TS: TweenService = game:GetService("TweenService")
local RS: RunService = game:GetService("RunService")
local CS : CollectionService = game:GetService("CollectionService")
local UIS : UserInputService = game:GetService("UserInputService")

-- Variables
local UIHandler = {}
local Player : Player = Players.LocalPlayer
local UI : PlayerGui = Player.PlayerGui:WaitForChild("PlayerUI")
local Character : Model = Player.Character or Player.CharacterAdded:Wait()
--local BridgeNet2 : table = require(game.ReplicatedStorage.BridgeNet2)
local Object : table = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
Object:Supersedes(UIHandler)
local UIValues = {
	["Health"] = UI.Bars.HealthBar;
	["Hunger"] = UI.Bars.HungerBar;
	["Water"] = UI.Bars.WaterBar;
}
local UIScales = {
	["Health"] = UI.Bars.HealthBar.Size;
	["Hunger"] = UI.Bars.HungerBar.Size;
	["Water"] = UI.Bars.WaterBar.Size;
}
local UIColors = {
	["Health"] = UI.Bars.HealthBar.BackgroundColor3;
	["Hunger"] = UI.Bars.HungerBar.BackgroundColor3;
	["Water"] = UI.Bars.WaterBar.BackgroundColor3;
}
-- Functions

function UIHandler.new(Name: string, Data: table) : ()
	local self = Object.new(Name)
	setmetatable(self, UIHandler)
	self.__DeathConnection = Character.Humanoid.Died:Connect(function()
		self.__HealthChanged:Disconnect()
	end)
	self.__NewCharacterConnection = Player.CharacterAdded:Connect(function(NCharacter : Model)
		Character = NCharacter
		if self.__HealthChanged then
			self.__HealthChanged:Disconnect()
		end
		self.__HealthChanged = Character.Humanoid.HealthChanged:Connect(function()
			self:AdjustBarUI("Health", Character.Humanoid.Health/Character.Humanoid.MaxHealth)
		end)
	end)
	return self
end

--[[
@Description: Adjusts one of three bar UIs (Health, Hunger, Thirst) based on a provided decimal within the range of 0-1.
@Param UIName (String): The name of the UI bar to be changed. This is not its actual name in the GUI, but what it represents (Health, Hunger, Thirst)
@Param Percentage (Number): A number between or equal to 0-1 that represents how far the bar will be shrunk/expanded based on its minimum/maximum size.
@Param SkipTween (Boolean): If true, no graphical "tween" effect will play, the bar will simply snap to its new size.
]]
function UIHandler:AdjustBarUI(UIName : string, Percentage : number, SkipTween : boolean) : ()
	if not UIValues[UIName] then warn("UI name is incorrect, check the list!") return end
	local UI : Frame = UIValues[UIName]
	Percentage = math.clamp(Percentage, 0, 1)
	if not SkipTween then
		TS:Create(UI, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(UIScales[UIName].X.Scale * Percentage, 0, UIScales[UIName].Y.Scale, 0)}):Play()
	else
		UI.Size = UDim2.new(UIScales[UIName].X.Scale * Percentage, 0, UIScales[UIName].Y.Scale, 0)
	end
	if Percentage <= 0.4 and Percentage > 0.2 then
		UI.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	elseif Percentage <= 0.2 then
		UI.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	else
		UI.BackgroundColor3 = UIColors[UIName]
	end
end

--[[
@Description: Adjusts the player's money display in the GUI via tweening it to the new value supplied.
@Param Amount (Number): The amount of money that should be displayed.
]]
function UIHandler:AdjustMoney(Amount : number) : ()
	local NumberValue : NumberValue = Instance.new("NumberValue")
	local Tween : Tween = TS:Create(NumberValue, TweenInfo.new(0.4), {Value = Amount})

	NumberValue:GetPropertyChangedSignal("Value"):Connect(function()
		UI.Bars.Money.Text = math.round(NumberValue.Value)
	end)
	Tween:Play()
	task.wait(0.4)
	NumberValue:Destroy()
end
--[[
@Description: A quick testing function that will run random commands on the UI to ensure that all bars and displays move as intended.
]]
function UIHandler:Test() : ()
	for i = 1, 5 do
		task.wait(2)
		self:AdjustMoney(math.random(1,1000))
		self:AdjustBarUI("Hunger", math.random(1,100) * 0.01)
		self:AdjustBarUI("Health", math.random(1,100) * 0.01)
		self:AdjustBarUI("Water", math.random(1,100) * 0.01)
	end
	task.wait(2)
	self:AdjustBarUI("Hunger", 0.1)
	self:AdjustBarUI("Health", 0.1)
	self:AdjustBarUI("Water", 0.1)
	task.wait(2)
	self:AdjustBarUI("Hunger", 1)
	self:AdjustBarUI("Health", 1)
	self:AdjustBarUI("Water", 1)
	self:AdjustMoney(0)
end

return UIHandler