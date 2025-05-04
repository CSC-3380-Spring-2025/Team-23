--[[  
 * THIS CLASS INHERITS FROM CLASS: OBJECT
 * This Class is designed in a nonstandard way and can simply be required and all its functions accessed without calling a constructor.
 * BackpackHandler - Superclass of all item and tool classes.  
 *  
 * This class represents a full backpack interaction system for players, allowing for
 * easy manipulation, creation, and removal of all types of items, as well as moving
 * items into the hotbar for use. It extends the Object class.
]]



--Services
local Players : Players = game:GetService("Players")

--Variables
local Backpacks : array = {} -- Holds all of the backpacks of all players
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local BackpackHandler : table = {}
BackpackHandler.__index = BackpackHandler
Object:Supersedes(BackpackHandler)
local BackpackSize : number = 150 -- How many items can be put into the backpack at its base?
local BackpackWeights : array = { -- Weight limits for different types of encumberance
	[50] = "Light";
	[70] = "Medium";
	[100] = "Heavy";
} 
local BridgeNet2 : {} = require(game.ReplicatedStorage.BridgeNet2)
local GetContents : {} = BridgeNet2.ReferenceBridge("GetContents")
local EquipItem : {} = BridgeNet2.ReferenceBridge("EquipItem")
local MoveItemToHotbar : {} = BridgeNet2.ReferenceBridge("MoveItemToHotbar")

local ItemUtil : {} = require(game.ReplicatedStorage.Shared.Items.ItemsUtils)
-- Functions

--[[
@Description: Creates a new "item" object by calling the item's .new function with the specified amount. Will automatically split items into groups if the amount exceeds the item's max stack.
@Param ItemName (String): The name of the item that is to be created.
@Param Amount (Number): How many of these items should be in the created stack.
@Return CreatedItems (Table): Returns a table with all of the created item objects.
]]
function BackpackHandler:CreateItem(ItemName : string, Amount : number) : table
	if not ItemUtil:GetItemInfo(ItemName) then 
		print("Item doesn't exist!") 
		return {} 
	end
	local Item = ItemUtil:GetItemInfo(ItemName);
	local MaxStack : number = Item.ItemStack;
	local StacksToMake : number
	local TotalInLastStack : number
	if Amount > MaxStack then
		if Amount % MaxStack ~= 0 then
			while Amount > MaxStack do
				task.wait()
				Amount -= MaxStack;
				StacksToMake += 1
			end
			StacksToMake += 1
			TotalInLastStack = Amount;
		else
			StacksToMake = Amount/MaxStack
		end
	else
		StacksToMake = 1
		TotalInLastStack = Amount
	end
	local CreatedItems : table = {}
	for i = 1, StacksToMake do
		if not TotalInLastStack or i < StacksToMake then
			local Stack = {
				["Name"] = Item.ItemName;
				["Stack"] = Item.ItemStack;
				["Type"] = Item.ItemType;
			}
			table.insert(CreatedItems, Stack)
		else
			local Stack = {
				["Name"] = Item.ItemName;
				["Stack"] = TotalInLastStack;
				["Type"] = Item.ItemType;
			}
			table.insert(CreatedItems, Stack)
		end
	end
	return CreatedItems
end

--[[
@Description: Creates a new "item" object by calling the item's .new function with the specified amount. Will automatically split items into groups if the amount exceeds the item's max stack.
@Param Player (Player): The player this tool is to be attached to.
@Param ToolName (String): The name of the tool that is to be created.
@Param Amount (Number): How many of these tools should be in the created stack.
@Param Durability (Number): What durability should the tool have
@Param Effectiveness (Number): What level is this tool (1-3)
@Return CreatedItems (Table): Returns a table with all of the created item objects.
]]
function BackpackHandler:CreateTool(Player : Player, ToolName : string, Amount : number, Durability : number, Effectiveness : number) : table
	if not ItemUtil:GetItemInfo(ToolName) then 
		print("Item doesn't exist!") 
		return {} 
	end
	local Tool = ItemUtil:GetItemInfo(ToolName);
	local MaxStack : number = 1;
	local StacksToMake : number
	local TotalInLastStack : number
	if Amount > MaxStack then
		if Amount % MaxStack ~= 0 then
			while Amount > MaxStack do
				task.wait()
				Amount -= MaxStack;
				StacksToMake += 1
			end
			StacksToMake += 1
			TotalInLastStack = Amount;
		else
			StacksToMake = Amount/MaxStack
		end
	else
		StacksToMake = 1
		TotalInLastStack = Amount
	end
	local CreatedTools : table = {}
	for i = 1, StacksToMake do
		if not TotalInLastStack or i < StacksToMake then
			local Stack = {
				["Name"] = Tool.ItemName;
				["Stack"] = Tool.ItemStack;
				["Type"] = Tool.ItemType;
			}
			table.insert(CreatedTools, Stack)
		else
			local Stack = {
				["Name"] = Tool.ItemName;
				["Stack"] = TotalInLastStack;
				["Type"] = Tool.ItemType;
			}
			table.insert(CreatedTools, Stack)
		end
	end
	return CreatedTools
end
--[[
@Description: Returns the total weight in the current player's backpack.
@Param Player (Player): The player who will have their backpack checked.
@Return Weight (Number): Returns a number representing the total weight in the player's backpack.
]]
function BackpackHandler:GetBackpackWeight(Player : Player) : number
	if not Backpacks[Player] then 
		return 0
	end
	return Backpacks[Player]["Weight"]
end
--[[
@Description: Returns the current objects in the current player's backpack.
@Param Player (Player): The player who will have their backpack checked.
@Return Contents (Array): Returns an array with all of the items in the player's backpack.
]]
function BackpackHandler:GetContents(Player : Player) : array
	if not Backpacks[Player] then 
		return {}
	end
	return Backpacks[Player]["Contents"]
end
--[[
@Description: Adjusts the player's backpack size. 
@Param Player (Player): The player who will have their backpack checked.
@Param Amount (Number): The amount the backpack size should be increased/decreased.
@Param ReplaceNumber (Boolean): If true, instead of adding/subtracting the number from the backpack, the number will be set as the new backpack size.
]]
function BackpackHandler:AdjustBackpackSize(Player : Player, Amount : number, ReplaceNumber : boolean) : ()
	if not Backpacks[Player] then 
		return 
	end
	if ReplaceNumber then
		Backpacks[Player]["Size"] = Amount
	else
		Backpacks[Player]["Size"] += Amount
	end
end
--[[
@Description: Returns the total number of items in the player's backpack.
@Param Player (Player): The player who will have their backpack checked.
@Return TotalItems (Number): Returns a number representing all of the items in the player's backpack.
]]
function BackpackHandler:GetTotalItems(Player : Player) : number
	if not Backpacks[Player] then 
		return 0
	end
	return Backpacks[Player]["TotalItems"]
end
--[[
@Description: Returns the size of the current player's backpack.
@Param Player (Player): The player who will have their backpack checked.
@Return Size (Number): Returns a number representing the size of the player's backpack.
]]
function BackpackHandler:GetBackpackSize(Player : Player) : number
	if not Backpacks[Player] then 
		return 0
	end
	return Backpacks[Player]["Size"]
end

--[[
@Description: Returns whether or not the player's backpack is full.
@Param Player (Player): The player who will have their backpack checked.
@Return IsFull (Boolean): Returns true if the player's backpack has a totalitem amount equal to or more than the backpack's size, and false if not.
]]
function BackpackHandler:IsFull(Player : Player) : boolean
	if not Backpacks[Player] then 
		return false
	end
	return Backpacks[Player]["TotalItems"] >= Backpacks[Player]["Size"]
end

--[[
@Description: Adds an item to the defined player's backpack.
@Param Player (Player): The player who will have the items added to their backpack.
@Param ItemName (String): The name of the item to be added.
@Param Stack (Number): How many items should be added to the player's backpack.
@Param ItemData (Any): Instead of creating a new item, the function will use this for all calculations. Used for things like existing items being picked up.
]]
function BackpackHandler:AddItemToBackPack(Player : Player, ItemName:string, Stack : number,  ItemData : any) : ()
	if not ItemData then
		ItemData = BackpackHandler:CreateItem(ItemName, Stack)
	end
	if not Backpacks[Player] then
		BackpackHandler:CreateBackpack(Player, BackpackSize)
	end
	local TargetBackpack : array = Backpacks[Player]

	if TargetBackpack["TotalItems"] + Stack > TargetBackpack["Size"] then
		print("Not enough space in the backpack!")
		ItemData = nil -- Delete the reference so garbage collection cleans it up
		return
	end
	local AddedWeight : number = ItemUtil:GetItemInfo(ItemName).ItemWeight * Stack
	for i,v in pairs(ItemData) do
		table.insert(TargetBackpack["Contents"], v)
		print(v)
		print("Inserted ".. v.Name.. " at stack " .. v.Stack .. " with weight ".. ItemUtil:GetItemInfo(ItemName).ItemWeight)
	end
	BackpackHandler:CalculateCurrentWeight(Player, AddedWeight)
	TargetBackpack.Weight += AddedWeight
	TargetBackpack.TotalItems += Stack 
end

--[[
@Description: Creates a new "tool" object by calling the item's .new function with the specified amount. Will automatically split items into groups if the amount exceeds the item's max stack.
@Param Player (Player): The player who will have the items added to their backpack.
@Param ItemName (String): The name of the tool that is to be created.
@Param Stack (Number): How many of these tools should be in the created stack.
@Param ItemData (Any): Instead of creating a new item, the function will use this for all calculations. Used for things like existing items being picked up.
@Param Durability (Number): What durability should the tool have.
@Param Effectiveness (Number): What level is this tool (1-3).
]]
function BackpackHandler:AddToolToBackPack(Player : Player, ItemName:string, Stack : number,  ItemData : any, Durability : number, Effectiveness : number) : ()
	if not ItemData then
		ItemData = BackpackHandler:CreateTool(Player, ItemName, Stack, Durability, Effectiveness)
	end
	if not Backpacks[Player] then
		BackpackHandler:CreateBackpack(Player, BackpackSize)
	end
	local TargetBackpack : array = Backpacks[Player]

	if TargetBackpack["TotalItems"] + Stack > TargetBackpack["Size"] then
		print("Not enough space in the backpack!")
		ItemData = nil -- Delete the reference so garbage collection cleans it up
		return
	end
	local AddedWeight : number = 0
	for i,v in pairs(ItemData) do
		AddedWeight += ItemUtil:GetItemInfo(ItemName).ItemWeight
		table.insert(TargetBackpack["Contents"], v)
		print(v)
		print("Inserted ".. v.Name.. " at stack " .. v.Stack .. " with weight ".. ItemUtil:GetItemInfo(ItemName).ItemWeight)
		table.insert(TargetBackpack["UseableItems"], v)
	end
	BackpackHandler:CalculateCurrentWeight(Player, AddedWeight)
	TargetBackpack.Weight += AddedWeight
	TargetBackpack.TotalItems += Stack 
end

--[[
@Description: Checks the current weight of the player's backpack and returns a string describing it.
@Param Player (Player): The player who will have their backpack weight checked.
@Param AddedWeight (Number): This is added to the backpack's current weight to calculate the effects of adding another item with this weight.
@Return WeightClass (String): This represents the player's current encumberance in string form.
]]
function BackpackHandler:CalculateCurrentWeight(Player : Player, AddedWeight : number) : string
	local TargetBackpack : array = Backpacks[Player]
	if not TargetBackpack then return "Light" end
	local TotalWeight : number = TargetBackpack["Weight"] + AddedWeight
	local TargetWeight : number = 0
	local WeightClass : string
	for i,v in pairs(BackpackWeights) do
		if i <= TotalWeight and TargetWeight < TotalWeight then
			WeightClass = v
			TargetWeight = i
		end
	end
	-- TODO: Tie this in with an overarching player BackpackHandler so it doesn't edit their walkspeed seperately
	if WeightClass == "Light" then
		print("Player is at light weight!")
	elseif WeightClass == "Medium" then
		print("Player is at medium weight!")
	elseif WeightClass == "Heavy" then
		print("Player is at heavy weight!")
	end
    return WeightClass
end

function BackpackHandler:GetName() : string
	return self.__Name
end

--[[
@Description: Drops an item from the player's backpack.
@Param Player (Player): The player who will have the item dropped.
@Param ItemName (String): The name of the item that should be dropped from the backpack.
@Param DropAmount (Number): How many items should be dropped from the stack.
]]
function BackpackHandler:DropItem(Player:Player, ItemName : string, DropAmount : number) : ()
	if not Backpacks[Player] then
		warn("How you gon drop something when you don't even have a backpack?")
		return
	end
	local TargetBackpack : array = Backpacks[Player]
	for c,v in pairs(TargetBackpack["Contents"]) do
		--TODO: Get models and put a function here to interact with them and drop items
		if v.Stack >= DropAmount then
			v.Stack -= DropAmount
			TargetBackpack["Weight"] -= ItemUtil:GetItemInfo(v.Name).ItemWeight * v.Stack
			TargetBackpack["TotalItems"] -= DropAmount
			print("Removed ".. v.Name.. " for " .. DropAmount .. " with weight ".. ItemUtil:GetItemInfo(v.Name).ItemWeight)
			v.Weight = ItemUtil:GetItemInfo(v.Name).ItemWeight * v.Stack
			DropAmount -= v.Stack
			if v.Stack <= 0 then
				table.remove(TargetBackpack["Contents"], c)
			end
		end
		if DropAmount <= 0 then
			break
		end
	end
	BackpackHandler:CalculateCurrentWeight(Player, 0)
end

--[[
@Description: Destroys an item from the player's backpack.
@Param Player (Player): The player who will have the item destroyed.
@Param ItemName (String): The name of the item that should be destroyed from the backpack.
@Param DestroyAmount (Number): How many items should be destroyed from the stack.
]]
function BackpackHandler:DestroyItem(Player:Player, ItemName : string, DestroyAmount : number) : ()
	if not Backpacks[Player] then
		warn("How you gon drop something when you don't even have a backpack?")
		return
	end
	local TargetBackpack : array = Backpacks[Player]
	for c,v in pairs(TargetBackpack["Contents"]) do
		if v.Stack >= DestroyAmount then
			v.Stack -= DestroyAmount
			TargetBackpack["Weight"] -= ItemUtil:GetItemInfo(v.Name).ItemWeight * v.Stack
			TargetBackpack["TotalItems"] -= DestroyAmount
			print("Removed ".. v.Name.. " for " .. DestroyAmount .. " with weight ".. ItemUtil:GetItemInfo(v.Name).ItemWeight)
			v.Weight = ItemUtil:GetItemInfo(v.Name).ItemWeight * v.Stack
			DestroyAmount -= v.Stack
			if v.Stack <= 0 then
				table.remove(TargetBackpack["Contents"], c)
			end
		end
		if DestroyAmount <= 0 then
			break
		end
	end
	BackpackHandler:CalculateCurrentWeight(Player, 0)
end

--[[
@Description: Drops a tool from the player's backpack.
@Param Player (Player): The player who will have the tool dropped.
@Param ToolID (Number): The tool's unique GUID identifier.
]]
function BackpackHandler:DropTool(Player:Player, ToolID : number) : ()
	if not Backpacks[Player] then
		warn("How you gon drop something when you don't even have a backpack?")
		return
	end
	local TargetBackpack : array = Backpacks[Player]
	for c,v in pairs(TargetBackpack["Contents"]) do
		--TODO: Get models and put a function here to interact with them and drop items
		if v.ToolID and  v.ToolID == ToolID then
			v.Stack -= 1
			TargetBackpack["Weight"] -= ItemUtil:GetItemInfo(v.Name).ItemWeight
			TargetBackpack["TotalItems"] -= 1
			print("Removed ".. v.Name.. " for " .. 1 .. " with weight ".. ItemUtil:GetItemInfo(v.Name).ItemWeight)
			v.Weight = ItemUtil:GetItemInfo(v.Name).ItemWeight * v.Stack
			if v.Stack <= 0 then
				table.remove(TargetBackpack["Contents"], c)
				table.remove(TargetBackpack["UsableItems"], c)
				table.remove(TargetBackpack["ToolbarItems"], c)
			end
			break
		end
	end
	BackpackHandler:CalculateCurrentWeight(Player, 0)
end

--[[
@Description: Destroys a tool in the player's backpack.
@Param Player (Player): The player who will have the tool Destroyed.
@Param ToolID (Number): The tool's unique GUID identifier.
]]
function BackpackHandler:DestroyTool(Player:Player, ToolID : number) : ()
	if not Backpacks[Player] then
		warn("How you gon destroy something when you don't even have a backpack?")
		return
	end
	local TargetBackpack : array = Backpacks[Player]
	for c,v in pairs(TargetBackpack["Contents"]) do
		--TODO: Get models and put a function here to interact with them and drop items
		if v.ID and  v.ID == ToolID then
			table.remove(TargetBackpack["Contents"], c)
			table.remove(TargetBackpack["UseableItems"], c)
			table.remove(TargetBackpack["ToolbarItems"], c)
			TargetBackpack["Weight"] -= ItemUtil:GetItemInfo(v.Name).ItemWeight
			TargetBackpack["TotalItems"] -= 1
			print("Removed ".. v.__Name.. " for " .. 1 .. " with weight ".. ItemUtil:GetItemInfo(v.Name).ItemWeight)
			v = nil
			break
		end
	end
	BackpackHandler:CalculateCurrentWeight(Player, 0)
end

--[[
@Description: This is a placeholder. The toolbar and backpack UI must be implemented before it can be created.
]]
function BackpackHandler:MoveItemToToolbar(Player : Player, ItemData, ItemID : string) : ()

end

--[[
@Description: Creates a backpack object for a player.
@Param Player (Player): The player who will have their backpack created.
@Param Size (Number): The size of the created backpack.
]]
function BackpackHandler:CreateBackpack(Player : Player, Size : number) : ()
	if not Backpacks[Player] then
		Backpacks[Player] = {
			["Size"] = Size or BackpackSize;
			["Weight"] = 0;
			["TotalItems"] = 0;
			["Contents"] = {};
			["UseableItems"] = {};
			["ToolbarItems"] = {};
		}
	end
end

function BackpackHandler.new(Name, Amount)
	local self: table = Object.new(Name)
	setmetatable(self, BackpackHandler) 
	self.__Name = Name or "Item"
	self.Amount = Amount or 1
	return self
end

--[[
@Description: Quickly tests the item side of the system to make sure nothing errors out. Results are printed and should be checked against what is expected.
]]
function BackpackHandler:TestItems() : ()
	task.wait(5)
	for i,v in pairs(game:GetService("Players"):GetChildren()) do
		print("Testing Player....")
		BackpackHandler:AddItemToBackPack(v, "Coal", 150)
		print(BackpackHandler:IsFull(v))
		print(BackpackHandler:GetTotalItems(v))
		print(BackpackHandler:GetContents(v))
		print(BackpackHandler:GetBackpackWeight(v))
		BackpackHandler:DropItem(v, "Coal", 50)
		print(BackpackHandler:IsFull(v))
		print(BackpackHandler:GetTotalItems(v))
		print(BackpackHandler:GetContents(v))
		print(BackpackHandler:GetBackpackWeight(v))
		BackpackHandler:AddItemToBackPack(v, "Coal", 150)
	end
end
--[[
@Description: Quickly tests the tool side of the system to make sure nothing errors out. Results are printed and should be checked against what is expected.
]]
function BackpackHandler:TestTools() : ()
	task.wait(5)
	for i,v in pairs(game:GetService("Players"):GetChildren()) do
		BackpackHandler:AddToolToBackPack(v, "Axe", 1,  nil, 100, 1)
		print(BackpackHandler:IsFull(v))
		print(BackpackHandler:GetTotalItems(v))
		print(BackpackHandler:GetContents(v))
		print(BackpackHandler:GetBackpackWeight(v))
		for c,d in pairs(BackpackHandler:GetContents(v)) do
			if d.__IsTool then
				print("Yup, it's a tool")
				d:Activate()
				d:Unequip()
				d:Equip()
				d:DecreaseHealthByHit(50)
				d:GetName()
				print(d:GetDurability())
				d:BreakTool()
			end
		end
		BackpackHandler:DropTool(v, 25)
		print(BackpackHandler:IsFull(v))
		print(BackpackHandler:GetTotalItems(v))
		print(BackpackHandler:GetContents(v))
		print(BackpackHandler:GetBackpackWeight(v))
		BackpackHandler:AddToolToBackPack(v, "Axe", 1,  nil, 100, 1)
	end
end
return BackpackHandler