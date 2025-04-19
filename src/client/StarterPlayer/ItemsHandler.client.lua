--[[
This script handles the behaivore of items for a client like when a tool (or item) is equiped
Must remain in starterplayer to avoid data loss
--]]

local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ItemUtils = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

local RemovePlayerBackpackItem = BridgeNet2.ReferenceBridge("RemovePlayerBackpackItem")

--Instances
local itemHandlerUtilsInst = ItemUtils.new("ItemHandlerUtilsInst")

local function Food(Item)
	Item.Activated:Connect(function()
		local foodInfo = itemHandlerUtilsInst:GetItemInfo(Item.Name)
		if not foodInfo then
			--Invalid food item
			return
		end

		local hungerRegen: number = foodInfo.HungerRegen
		--Fire event to server to remove one item from backpack and suspend activating tool again until done
        local removeArgs = {
            ItemName = Item.Name,
            DestroyAmount = 1
        }
        RemovePlayerBackpackItem:Fire(removeArgs)
        --Find a way to wait for response
        --Regen hunger
        
	end)
end

local function EquippedHandler(Item: Tool): ()
	--Determine what type of item it is and do behaivore of that item
	if CollectionService:HasTag(Item, "Food") then
		--Food item
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
