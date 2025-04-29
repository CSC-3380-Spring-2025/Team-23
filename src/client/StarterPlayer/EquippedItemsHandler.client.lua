--[[
This script handles the behaivore of items for a client like when a tool (or item) is equiped
Must remain in starterplayer to avoid data loss
--]]

local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ItemUtils = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local StatsHandlerInterfaceObject = require(playerScripts.StatsHandlerInterface)

--Events
local events = ReplicatedStorage.Events
local RemovePlayerBackpackItem = events:WaitForChild("RemovePlayerBackpackItem")

--Instances
local itemHandlerUtilsInst = ItemUtils.new("ItemHandlerUtilsInst")
local statsHandlerInterface = StatsHandlerInterfaceObject.new("ItemsHandlerStatsHandler")

local function Food(Item)
	Item.Activated:Connect(function()
		print("FOOD ACTIVATED!")
		local foodInfo = itemHandlerUtilsInst:GetItemInfo(Item.Name)
		if not foodInfo then
			--Invalid food item
			return
		end

		local hungerRegen: number = foodInfo.HungerRegen
		--Fire event to server to remove one item from backpack and suspend activating tool again until done
        --RemovePlayerBackpackItem:InvokeServer(Item.Name, 1)
        --Regen hunger
        statsHandlerInterface:FeedPlayer(hungerRegen)
	end)
end

local function Drink(Item)
	Item.Activated:Connect(function()
		print("Drink ACTIVATED!")
		local drinkInfo = itemHandlerUtilsInst:GetItemInfo(Item.Name)
		if not drinkInfo then
			--Invalid food item
			return
		end

		local thirstRegen: number = drinkInfo.ThirstRegen
		--Fire event to server to remove one item from backpack and suspend activating tool again until done
        --RemovePlayerBackpackItem:InvokeServer(Item.Name, 1)
        --Regen hunger
        statsHandlerInterface:HydratePlayer(thirstRegen)
	end)
end

local function EquippedHandler(Item: Tool): ()
	--Determine what type of item it is and do behaivore of that item
	if CollectionService:HasTag(Item, "Food") then
		--Food item
		print("FOOD WAS EQUIPPED!")
		Food(Item)
	elseif CollectionService:HasTag(Item, "Drink") then
		print("DRINK WAS EQUIPPED!")
		Drink(Item)
	end
end

--Detect when a tool is activated
player.CharacterAdded:Connect(function(Character)
	Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			--A tool was equipped
			EquippedHandler(Child)
		end
	end)
end)
