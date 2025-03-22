--Services
local Players : Players = game:GetService("Players")

--Variables
local Backpacks : array = {} -- Holds all of the backpacks of all players
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)

local Handler = {}
Handler.__index = Handler
Object:Supersedes(Handler)

local BackpackSize : number = 150 -- How many items can be put into the backpack at its base?
local BackpackWeights : array = { -- Weight limits for different types of encumberance
	[50] = "Light";
	[70] = "Medium";
	[100] = "Heavy";
} 

local ToolStorage : Folder = game.ServerScriptService.Server.Items

local Tools : array = {} -- Storage for tool modules for easily figuring out things like size without making a new object

-- Functions

for i,v in pairs(ToolStorage:GetChildren()) do -- Indexes all items within the Tools array
	local tool = require(v);
	Tools[tool:GetName()] = tool
end
--[[
@Description: Creates a new "item" object by calling the item's .new function with the specified amount. Will automatically split items into groups if the amount exceeds the item's max stack.
@Param ItemName (String): The name of the item that is to be created.
@Param Amount (Number): How many of these items should be in the created stack.
@Return CreatedItems (Table): Returns a table with all of the created item objects.
]]
function Handler:CreateItem(ItemName : string, Amount : number) : table
	if not Tools[ItemName] then 
		print("Item doesn't exist!") 
		return {} 
	end
	local Item = Tools[ItemName];
	local MaxStack : number = Item:GetMaxStack();
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
			local Stack = Item.new(MaxStack, Handler)
			table.insert(CreatedItems, Stack)
		else
			local Stack = Item.new(TotalInLastStack, Handler)
			table.insert(CreatedItems, Stack)
		end
	end
	return CreatedItems
end
--[[
@Description: Returns the total weight in the current player's backpack.
@Param Player (Player): The player who will have their backpack checked.
@Return Weight (Number): Returns a number representing the total weight in the player's backpack.
]]
function Handler:GetWeight(Player : Player) : number
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
function Handler:GetContents(Player : Player) : array
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
function Handler:AdjustBackpackSize(Player : Player, Amount : number, ReplaceNumber : boolean) : ()
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
function Handler:GetTotalItems(Player : Player) : number
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
function Handler:GetBackpackSize(Player : Player) : number
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
function Handler:IsFull(Player : Player) : boolean
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
function Handler:AddToBackPack(Player : Player, ItemName:string, Stack : number,  ItemData : any) : ()
	if not ItemData then
		ItemData = Handler:CreateItem(ItemName, Stack)
	end
	if not Backpacks[Player] then
		Handler:CreateBackpack(Player, BackpackSize)
	end
	local TargetBackpack : array = Backpacks[Player]

	if TargetBackpack["TotalItems"] + Stack > TargetBackpack["Size"] then
		print("Not enough space in the backpack!")
		ItemData = nil -- Delete the reference so garbage collection cleans it up
		return
	end
	local AddedWeight : number = 0
	for i,v in pairs(ItemData) do
		AddedWeight += v.Weight
		table.insert(TargetBackpack["Contents"], v)
		print(v)
		print("Inserted ".. v.Name.. " at stack " .. v.Amount .. " with weight ".. v.Weight)
		if v.IsTool then
			v.ID = game:GetService("HttpService"):GenerateGUID()
			table.insert(TargetBackpack["UseableItems"], v)
		end
	end
	Handler:CalculateCurrentWeight(Player, AddedWeight)


	TargetBackpack.Weight += AddedWeight
	TargetBackpack.TotalItems += Stack 
end
--[[
@Description: Checks the current weight of the player's backpack and returns a string describing it.
@Param Player (Player): The player who will have their backpack weight checked.
@Param AddedWeight (Number): This is added to the backpack's current weight to calculate the effects of adding another item with this weight.
@Return WeightClass (String): This represents the player's current encumberance in string form.
]]
function Handler:CalculateCurrentWeight(Player : Player, AddedWeight : number) : string
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
	-- TODO: Tie this in with an overarching player handler so it doesn't edit their walkspeed seperately
	if WeightClass == "Light" then
		print("Player is at light weight!")
	elseif WeightClass == "Medium" then
		print("Player is at medium weight!")
	elseif WeightClass == "Heavy" then
		print("Player is at heavy weight!")
	end
    return WeightClass
end

--[[
@Description: Drops an item from the player's backpack.
@Param Player (Player): The player who will have the item dropped.
@Param ItemName (String): The name of the item that should be dropped from the backpack.
@Param DropAmount (Number): How many items should be dropped from the stack.
]]
function Handler:DropItem(Player:Player, ItemName : string, DropAmount : number) : ()
	if not Backpacks[Player] then
		print("How you gon drop something when you don't even have a backpack?")
		return
	end
	local TargetBackpack : array = Backpacks[Player]
	for c,v in pairs(TargetBackpack["Contents"]) do
		--TODO: Get models and put a function here to interact with them and drop items
		if v.Amount >= DropAmount then
			v.Amount -= DropAmount
			TargetBackpack["Weight"] -= v.Weight
			TargetBackpack["TotalItems"] -= DropAmount
			print("Removed ".. v.Name.. " for " .. DropAmount .. " with weight ".. v.Weight)
			v.Weight = v:GetWeight() * v.Amount
			DropAmount -= v.Amount
			if v.Amount <= 0 then
				table.remove(TargetBackpack["Contents"], c)
			end
		end
		if DropAmount <= 0 then
			break
		end
	end
	Handler:CalculateCurrentWeight(Player, 0)
end

function Handler:MoveItemToToolbar(Player : Player, ItemData, ItemID : string) : ()

end

--[[
@Description: Creates a backpack object for a player.
@Param Player (Player): The player who will have their backpack created.
@Param Size (Number): The size of the created backpack.
]]
function Handler:CreateBackpack(Player : Player, Size : number) : ()
	if not Backpacks[Player] then
		Backpacks[Player] = {
			["Size"] = Size or BackpackSize;
			["Weight"] = 0;
			["TotalItems"] = 0;
			["Contents"] = {};
			["UseableItems"] = {};
		}
	end
end

function Handler.new(Name, Amount)
	local self: table = Object.new(Name)
	self.Name = Name or "Item"
	self.Amount = Amount or 0
	return self
end

--[[
@Description: Quickly tests the system to make sure nothing errors out. Results are printed and should be checked against what is expected.
]]
function Handler:Test() : ()
	task.wait(5)
	for i,v in pairs(game:GetService("Players"):GetChildren()) do
		Handler:AddToBackPack(v, "Coal", 150)
		print(Handler:IsFull(v))
		print(Handler:GetTotalItems(v))
		print(Handler:GetContents(v))
		print(Handler:GetWeight(v))
		Handler:DropItem(v, "Coal", 50)
		print(Handler:IsFull(v))
		print(Handler:GetTotalItems(v))
		print(Handler:GetContents(v))
		print(Handler:GetWeight(v))
		Handler:AddToBackPack(v, "Coal", 150)
	end
end

return Handler