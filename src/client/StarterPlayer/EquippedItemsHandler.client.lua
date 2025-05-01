--[[
This script handles the behaivore of items for a client like when a tool (or item) is equiped
Must remain in starterplayer to avoid data loss
--]]

local Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ItemUtils = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local StatsHandlerInterfaceObject = require(playerScripts.StatsHandlerInterface)
local SwordObject = require(script.Parent.Tools.Weapons.Sword)

--Events
local events: Folder = ReplicatedStorage.Events
local RemovePlayerBackpackItem: RemoteFunction = events:WaitForChild("RemovePlayerBackpackItem") :: RemoteFunction

--Instances
local itemHandlerUtilsInst: ExtType.ObjectInstance = ItemUtils.new("ItemHandlerUtilsInst")
local statsHandlerInterface: ExtType.ObjectInstance = StatsHandlerInterfaceObject.new("ItemsHandlerStatsHandler")

--[[
This function defines the behaivore of a food item
	@param Item (Tool) any "Tool" that acts as food.
--]]
local function Food(Item: Tool) : ()
	Item.Activated:Connect(function()
		local foodInfo: ExtType.InfoMod = itemHandlerUtilsInst:GetItemInfo(Item.Name)
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

--[[
This function defines the behaivore of a Drink item
	@param Item (Tool) any "Tool" that acts as a drink.
--]]
local function Drink(Item: Tool) : ()
	Item.Activated:Connect(function()
		local drinkInfo: ExtType.InfoMod = itemHandlerUtilsInst:GetItemInfo(Item.Name)
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

--[[
Handles all Swords
	@param Sword (Tool) the tool to be used as a sword
--]]
local function Sword(Sword: Tool)
	--Create sword instance for tool
	local swordInstance: ExtType.ObjectInstance? = SwordObject.new(Sword.Name, Sword)
	if swordInstance == nil then
		return--Error
	end
	Sword.Activated:Connect(function()
		swordInstance:Activate()
	end)
end

--[[
Handles all weapons
	@param Weapon (Tool) the tool that is the weapon
--]]
local function Weapon(Weapon: Tool)
	if CollectionService:HasTag(Weapon, "Sword") then
		Sword(Weapon)
	end
end

--[[
Guides a tool into the correct type of tool for determining its intent and behaivore.
	@param Item (Tool) any "Tool" that acts as a drink.
--]]
local function EquippedHandler(Item: Tool): ()
	--Set up Motor6d of tool if it exists
	local motor6d: Motor6D? = Item:FindFirstChild("Motor6d", true) :: Motor6D?
	if motor6d ~= nil then
		--Has motor6d to set up
		local motorParent1: BasePart? = Item:FindFirstChild("MotorParent1", true) :: BasePart?
		if motorParent1 == nil then
			warn('Attempt to equip Item "' .. Item.Name .. '" but tool has no part named MotorParent1')
			return
		end

		local character: Model = player.Character :: Model--Assumed to be existent as this script is called by adding to character
		local rightHand: BasePart = character:FindFirstChild("RightHand") :: BasePart
		motor6d.Part1 = motorParent1
		motor6d.Part0 = rightHand
	end
	--Determine what type of item it is and do behaivore of that item
	if CollectionService:HasTag(Item, "Food") then
		--Food item
		Food(Item)
	elseif CollectionService:HasTag(Item, "Drink") then
		--Drink item
		Drink(Item)
	elseif CollectionService:HasTag(Item, "Weapon") then
		Weapon(Item)
	end
end

--Detect when a tool is Equipped
player.CharacterAdded:Connect(function(Character)
	Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			--A tool was equipped
			EquippedHandler(Child)
		end
	end)
end)
