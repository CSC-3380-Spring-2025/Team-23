--[[  
 * THIS CLASS INHERITS FROM CLASS: OBJECT
 * This class represents a full set of functions to control the Player's UI
 * without having to directly interact with it. This includes adjusting display bars,
 * Displaying the inventory, and equipping/unequipping tools.
]]

-- Services
local Players: Players = game:GetService("Players")
local TS: TweenService = game:GetService("TweenService")
local RS: RunService = game:GetService("RunService")
local CS: CollectionService = game:GetService("CollectionService")
local UIS: UserInputService = game:GetService("UserInputService")
local Object: {any} = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local UIHandler = {}
--local BridgeNet2 : table = require(game.ReplicatedStorage.BridgeNet2)
Object:Supersedes(UIHandler)

-- Variables
local Player: Player = Players.LocalPlayer

-- Functions

function UIHandler.new(Name: string, Data: {}?): {[any]: any}
	local self = Object.new(Name)
	setmetatable(self, UIHandler)
	self.__UI = Player.PlayerGui:WaitForChild("PlayerUI")
	self.__UIValues = {
		["Health"] = self.__UI.Bars.HealthBar,
		["Hunger"] = self.__UI.Bars.HungerBar,
		["Water"] = self.__UI.Bars.WaterBar,
	}
	self.__UIScales = {
		["Health"] = self.__UI.Bars.HealthBar.Size,
		["Hunger"] = self.__UI.Bars.HungerBar.Size,
		["Water"] = self.__UI.Bars.WaterBar.Size,
	}
	self.__UIColors = {
		["Health"] = self.__UI.Bars.HealthBar.BackgroundColor3,
		["Hunger"] = self.__UI.Bars.HungerBar.BackgroundColor3,
		["Water"] = self.__UI.Bars.WaterBar.BackgroundColor3,
	}
	return self
end

--[[
@Description: Adjusts one of three bar UIs (Health, Hunger, Water) based on a provided decimal within the range of 0-1.
@Param UIName (String): The name of the UI bar to be changed. This is not its actual name in the GUI, but what it represents (Health, Hunger, Water)
@Param Percentage (Number): A number between or equal to 0-1 that represents how far the bar will be shrunk/expanded based on its minimum/maximum size.
@Param SkipTween (Boolean): If true, no graphical "tween" effect will play, the bar will simply snap to its new size.
]]
function UIHandler:AdjustBarUI(UIName: string, Percentage: number, SkipTween: boolean): ()
	if not self.__UIValues[UIName] then
		warn("UI name is incorrect, check the list!")
		return
	end
	local UI: Frame = self.__UIValues[UIName]
	Percentage = math.clamp(Percentage, 0, 1)
	if not SkipTween then
		TS:Create(
			UI,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = UDim2.new(self.__UIScales[UIName].X.Scale * Percentage, 0, self.__UIScales[UIName].Y.Scale, 0) }
		):Play()
	else
		UI.Size = UDim2.new(self.__UIScales[UIName].X.Scale * Percentage, 0, self.__UIScales[UIName].Y.Scale, 0)
	end
	if Percentage <= 0.4 and Percentage > 0.2 then
		UI.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	elseif Percentage <= 0.2 then
		UI.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	else
		UI.BackgroundColor3 = self.__UIColors[UIName]
	end
end

--[[
@Description: Adjusts the player's money display in the GUI via tweening it to the new value supplied.
@Param Amount (Number): The amount of money that should be displayed.
]]
function UIHandler:AdjustMoney(Amount: number): ()
	local NumberValue: NumberValue = Instance.new("NumberValue")
	local Tween: Tween = TS:Create(NumberValue, TweenInfo.new(0.4), { Value = Amount })

	NumberValue:GetPropertyChangedSignal("Value"):Connect(function()
		self.__UI.Bars.Money.Text = math.round(NumberValue.Value)
	end)
	Tween:Play()
	task.wait(0.4)
	NumberValue:Destroy()
end
--[[
@Description: A quick testing function that will run random commands on the UI to ensure that all bars and displays move as intended.
]]
function UIHandler:Test(): ()
	for i = 1, 5 do
		task.wait(2)
		self:AdjustMoney(math.random(1, 1000))
		self:AdjustBarUI("Hunger", math.random(1, 100) * 0.01)
		self:AdjustBarUI("Health", math.random(1, 100) * 0.01)
		self:AdjustBarUI("Water", math.random(1, 100) * 0.01)
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
