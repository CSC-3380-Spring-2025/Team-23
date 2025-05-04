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
local PickaxeObject = require(script.Parent.Tools.ResourceTools.Pickaxe)
local AxeObject = require(script.Parent.Tools.ResourceTools.Axe)

--Events
local events: Folder = ReplicatedStorage.Events
local RemovePlayerBackpackItem: RemoteFunction = events:WaitForChild("RemovePlayerBackpackItem") :: RemoteFunction

--Instances
local itemHandlerUtilsInst: ExtType.ObjectInstance = ItemUtils.new("ItemHandlerUtilsInst")
local statsHandlerInterface: ExtType.ObjectInstance = StatsHandlerInterfaceObject.new("ItemsHandlerStatsHandler")

--Vars
--[[
Table of tool instances and their phys tool
Used to prevent needing to create new instances every time a tool is equipped
Follows format: {["Instance"] = Instance, ["Tool"] = PhysTool}
--]]
local toolInstances: {ExtType.StrDict} = {}
--[[
All tool based connections must be inserted into this table for clean up
Rather than disconnecting signals they must be disconnected by using ClearToolConnect()
--]]
local toolConnections: {RBXScriptConnection} = {}

--[[
BOTH disconnects the given connection AND removes it from toolConnections
	@param Connection (RBXScriptConnection) any tool specific connections
--]]
local function ClearToolConnect(Connection: RBXScriptConnection)
	--Remove from table
	for index, curConnection in ipairs(toolConnections) do
		if curConnection == Connection then
			table.remove(toolConnections, index)
		end
	end
	Connection:Disconnect() --Disconnect to prevent mem leaks
end

--[[
Helper function that inserts any given tool instance
	@param ToolInstance (ExtType.ObjectInstance) any created tool instance
	@param PhysTool (Tool) the physical tool associated with the ToolInstance
--]]
local function InsertToolInstance(ToolInstance: ExtType.ObjectInstance, PhysTool: Tool) : ()
	local tableValue: ExtType.StrDict = {
		Instance = ToolInstance,
		Tool = PhysTool
	}
	table.insert(toolInstances, tableValue)
end

--[[
Helper function used to retrieve the ToolInstance based on the given PhysTool associated with it
	as long as the ToolInstance is stored using InsertToolInstance()
	@param PhysTool (Tool) the physical tool of the suspected instance.
	@return (ExtType.ObjectInstance?) ExtType.ObjectInstance if it exists or false otherwise
--]]
local function FindToolInstance(PhysTool: Tool) : ExtType.ObjectInstance?
	for _, value in pairs(toolInstances) do
		local tool: Tool? = value["Tool"]
		if not tool then
			continue--ToolInstance not added or does not exist
		end
		if tool == PhysTool then
			local toolInstance: ExtType.ObjectInstance = value["Instance"]
			if toolInstance then
				return toolInstance
			end
		end
	end
	return nil--does not exist
end

--[[
Removes a ToolInstance by supplying either the ToolInstance or PhysTool refrence
	@param Refrence (ExtType.ObjectInstance | Tool) either a tool instance or 
	physical Tool associated with the given instance.
	:DestroyInstance() is called for all tool instances.
	If :DestroyInstance() is not implemented by the given tool
	then an error will occur.
--]]
local function RemoveToolInstance(Refrence: ExtType.ObjectInstance | Tool) : ()
	if Refrence:IsA("Tool") then
		for index, value in ipairs(toolInstances) do
			local tool: Tool? = value["Tool"]
			if not tool then
				continue--ToolInstance not added or does not exist
			end
			if tool == Refrence then
				--Remove tool instance
				local toolInstance: ExtType.ObjectInstance = value["Instance"]
				table.remove(toolInstances, index)
				if toolInstance then
					toolInstance:DestroyInstance()
				end
			end
		end
	else
		--Is a ExtType.ObjectInstance
		for index, value in ipairs(toolInstances) do
			local toolInstance: ExtType.ObjectInstance? = value["Tool"]
			if not toolInstance then
				continue--ToolInstance not added or does not exist
			end
			if toolInstance == Refrence then
				--Remove tool instance
				table.remove(toolInstances, index)
				toolInstance:DestroyInstance()
			end
		end
	end
end

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
local function Sword(Sword: Tool) : ()
	--Check if an instance already exists
	local swordInstance: ExtType.ObjectInstance? = FindToolInstance(Sword)
	--Create sword instance for tool if does not exist yet
	if swordInstance == nil then
		swordInstance = SwordObject.new(Sword.Name, Sword)
		InsertToolInstance(swordInstance :: ExtType.ObjectInstance, Sword)
	end
	if swordInstance == nil then
		return--Error
	end

	local activated: RBXScriptConnection = Sword.Activated:Connect(function()
		swordInstance:Activate()
	end)
	table.insert(toolConnections, activated)--Insert for clean up on player death
	local unequipped: RBXScriptConnection
	--Handle unequipped
	unequipped = Sword.Unequipped:Connect(function()
		--Clean up to prevent mem leaks
		ClearToolConnect(activated)
		ClearToolConnect(unequipped)
	end)
	table.insert(toolConnections, unequipped)--Add to list of tool connects
end

--[[
Handles all weapons
	@param Weapon (Tool) the tool that is the weapon
--]]
local function Weapon(Weapon: Tool) : ()
	if CollectionService:HasTag(Weapon, "Sword") then
		Sword(Weapon)
	end
end

--[[
Handles all pickaxe tools
	@param Pickaxe (Tool) the tool that is a pickaxe
--]]
local function Pickaxe(Pickaxe: Tool) : ()
	--Check if an instance already exists
	local pickaxeInstance: ExtType.ObjectInstance? = FindToolInstance(Pickaxe)
	--Create sword instance for tool if does not exist yet
	if pickaxeInstance == nil then
		pickaxeInstance = PickaxeObject.new(Pickaxe.Name, Pickaxe)
		InsertToolInstance(pickaxeInstance :: ExtType.ObjectInstance, Pickaxe)
	end
	if pickaxeInstance == nil then
		return--Error
	end

	local activated: RBXScriptConnection = Pickaxe.Activated:Connect(function()
		pickaxeInstance:Activate()
	end)
	table.insert(toolConnections, activated)--Insert for clean up on player death
	local unequipped: RBXScriptConnection
	--Handle unequipped
	unequipped = Pickaxe.Unequipped:Connect(function()
		--Clean up to prevent mem leaks
		ClearToolConnect(activated)
		ClearToolConnect(unequipped)
	end)
	table.insert(toolConnections, unequipped)--Add to list of tool connects
end

--[[
Handles all Axes
	@param Axe (Tool) any Axe Tool
--]]
local function Axe(Axe: Tool)
	--Check if an instance already exists
	local axeInstance: ExtType.ObjectInstance? = FindToolInstance(Axe)
	--Create sword instance for tool if does not exist yet
	if axeInstance == nil then
		axeInstance = AxeObject.new(Axe.Name, Axe)
		InsertToolInstance(axeInstance :: ExtType.ObjectInstance, Axe)
	end
	if axeInstance == nil then
		return--Error
	end

	local activated: RBXScriptConnection = Axe.Activated:Connect(function()
		axeInstance:Activate()
	end)
	table.insert(toolConnections, activated)--Insert for clean up on player death
	local unequipped: RBXScriptConnection
	--Handle unequipped
	unequipped = Axe.Unequipped:Connect(function()
		--Clean up to prevent mem leaks
		ClearToolConnect(activated)
		ClearToolConnect(unequipped)
	end)
	table.insert(toolConnections, unequipped)--Add to list of tool connects
end

--[[
Handles all ResourceTools
	@param ResourceTool (Tool) any tool that is a ResourceTool
--]]
local function ResourceTool(ResourceTool: Tool)
	if CollectionService:HasTag(ResourceTool, "Pickaxe") then
		Pickaxe(ResourceTool)
	elseif CollectionService:HasTag(ResourceTool, "Axe") then
		Axe(ResourceTool)
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
	elseif CollectionService:HasTag(Item, "ResourceTool") then
		--ResourceTools
		ResourceTool(Item)
	end
end

--[[
Helper function used to clean up all tool instances during a player death
	Not calling this function may result in memory leaks
--]]
local function HandlePlayerDeath() : ()
	--Purge all tool instances
	while #toolInstances > 0 do
		local refrenceSet: ExtType.StrDict = table.remove(toolInstances) :: ExtType.StrDict
		local toolInstance: ExtType.ObjectInstance = refrenceSet["Instance"]
		if toolInstance then
			toolInstance:DestroyInstance()
		end
	end

	while #toolConnections > 0 do
		local connection: RBXScriptConnection = table.remove(toolConnections) :: RBXScriptConnection
		connection:Disconnect()
	end
end

--Detect when a tool is Equipped
player.CharacterAdded:Connect(function(Character)
	local newChild: RBXScriptConnection = Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			--A tool was equipped
			EquippedHandler(Child)
		end
	end)
	local humanoid: Humanoid = Character:WaitForChild("Humanoid")
	--Handle death
	humanoid.Died:Once(function()
		newChild:Disconnect()
		HandlePlayerDeath()
	end)
end)
