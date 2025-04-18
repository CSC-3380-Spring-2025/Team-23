--[[
This abstract class provides the required methods for an NPC that has a backpack
Before making a subclass or expanding this class you should take great care
in examining the existing functions and ensure that you follow the same approach 
in the backpack table layout with its keys and values.
All backpack NPC's are assumed to require food and water and must be provided food and water on an ongoing basis.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local NPC = require(ServerScriptService.Server.NPC.NPC)
local NPCUtils = require(ServerScriptService.Server.NPC.NPCUtils)
local BackpackNPCUtils = NPCUtils.new("BackpackNPCUtils")
local BackpackNPC = {}
NPC:Supersedes(BackpackNPC)

local statsEnabled = true --Indicates if the stats system is activated.

--[[
Returns the optomial amount of food to eat at a time given a food item in the NPC's backpack
	@param HungerRegen (number) the amount of hunger that a single item of this tiem will regen
	@param Stats ({}) the Stats of the NPC
	@param MaxHunger (number) the max hunger of the NPC
	@param ItemStats ({}) the table of the item in the backpack
--]]
local function MaxFoodConsume(HungerRegen: number, Stats: {}, MaxHunger: number, ItemStats: {}): number
	local deficit: number = MaxHunger - Stats.Food
	local foodMax: number = math.floor(deficit / HungerRegen)
	local itemCount: number = ItemStats.Count
	if foodMax <= itemCount then
		return foodMax
	else
		return itemCount
	end
end

--[[
Handles when an NPC consumes food.
	@param Self (any) instance of this class
	@param StatsConfig ({}) the table of stats config 
	@param Stats ({}) the table of the current stats
	@param Tasks ({thread}) the table of active tasks
	@return (boolean) true on success eating or false otherwise
--]]
local function ConsumeFood(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : boolean
	--Check for food
	local backpack: {} = Self.__Backpack
	local maxHunger: number = StatsConfig.MaxFood
	--Loop through backpack and find anything of type food
	--If food is wasted attempt to search for another food
	local leastWasteFood: string? = nil
	local leastWasteRegen: number = 0
	for itemName, item in pairs(backpack) do
		if item.ItemType == "Food" then
			--Check for if food is wasted an dif not add
			local itemInfo: {} = Self:GetItemInfo(itemName)
			local hungerRegen: number = itemInfo.HungerRegen
			local canEat: number = MaxFoodConsume(hungerRegen, Stats, maxHunger, item)
			if canEat > 0 then
				--Found edible food that doesnt waste
				Self:RemoveItem(itemName, canEat)
				Stats.Food = Stats.Food + (canEat * hungerRegen) --Update stat
				return true --Ate
			end
			--Could not consume without waste so check for if leastWaste
			if ((-1 * hungerRegen) > leastWasteRegen) or not leastWasteFood then
				--least waste so far
				leastWasteFood = itemInfo.Name
				leastWasteRegen = -1 * hungerRegen
			end
		end
	end
	--Could not consume without waste. If starving eat food of least waste
	if leastWasteFood and Tasks.StvTask then
		--There was food and NPC is starving so eat out of desperation
		Self:RemoveItem(leastWasteFood, 1)
		local newFoodStat: number = Stats.Food + math.abs(leastWasteRegen)
		if newFoodStat <= maxHunger then
			--Within max hunger
			Stats.Food = newFoodStat
		else
			--Set to max stat since greater than allowed stat
			Stats.Food = maxHunger
		end
		return true --Ate
	elseif Tasks.StvTask then
		--print("No Food found! Cant eat and starving!")
	end
	return false --Could not eat
end

--[[
Starves a given NPC until it is given food
	@param Self (any) any instance fo this class
	@param StatsConfig ({}) table of stat configs
	@param Stats ({}) table of stats
	@param Tasks ({thread}) table of the current tasks
--]]
local function Starve(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : ()
	Tasks.StvTask = task.spawn(function()
		--Damage NPC
		while true do
			local didConsume: boolean = ConsumeFood(Self, StatsConfig, Stats, Tasks) --Try to consume food first
			if didConsume or Stats.Food > 0 then
				Tasks.StvTask = nil
				return--No longer starving
			end
			--print("Taking starve damage!")
			Self.__Humanoid:TakeDamage(StatsConfig.StarveDmg)
			task.wait(StatsConfig.StarveDmgRate)
		end
	end)
end

--[[
Handles the food stat
	@param Self (any) any instance fo this class
	@param StatsConfig ({}) table of stat configs
	@param Stats ({}) table of stats
	@param Tasks ({thread}) table of the current tasks
--]]
local function HandleFoodStat(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : ()
	--For each loop if hungry then consume food until out
	--If out of food then need to cancel starveTsk when given food
	--local starveTsk = nil --The task for when a player is starving
	--print("Handling food")
	while true do
		task.wait(StatsConfig.FdDeteriorationRate) --Wait between decrements
		local newStat: number = Stats.Food - StatsConfig.FdDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end
		--print("Decrementing food. Food is now: " .. newStat)
		Stats.Food = newStat
		--Check if starved
		if newStat <= 0 and not Tasks.StvTask then
			--Start damaging player and store task to cancel when given food
			--print(Self.Name .. "Is starving")
			--Attempt to consume food first
			local didEat: boolean = ConsumeFood(Self, StatsConfig, Stats, Tasks)
			if didEat then
				continue--Skip to next loop
			end
			Starve(Self, StatsConfig, Stats, Tasks)
		end
	end
end

--[[
Returns the optomial amount of food to eat at a time given a food item in the NPC's backpack
	@param HungerRegen (number) the amount of hunger that a single item of this tiem will regen
	@param Stats ({}) the Stats of the NPC
	@param MaxHunger (number) the max hunger of the NPC
	@param ItemStats ({}) the table of the item in the backpack
--]]
local function MaxDrinkConsume(HydrationRegen: number, Stats: {}, MaxHydration: number, ItemStats: {}): number
	local deficit: number = MaxHydration - Stats.Hydration
	local drinkMax: number = math.floor(deficit / HydrationRegen)
	local itemCount: number = ItemStats.Count
	if drinkMax <= itemCount then
		return drinkMax
	else
		return itemCount
	end
end

--[[
Handles when an NPC consumes drinks
	@param Self (any) any instance fo this class
	@param StatsConfig ({}) table of stat configs
	@param Stats ({}) table of stats
	@param Tasks ({thread}) table of the current tasks
	@return (boolean) true on drank or false otherwise
--]]
local function ConsumeDrink(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : boolean
	--Check for drink
	local backpack: {} = Self.__Backpack
	local maxDrink: number = StatsConfig.MaxHydration
	--Loop through backpack and find anything of type Drink
	--If drink is wasted attempt to search for another drink
	local leastWastedDrink: string? = nil
	local leastWasteRegen: number = 0
	for itemName, item in pairs(backpack) do
		if item.ItemType == "Drink" then
			--Check for if drink is wasted and if not add
			local itemInfo: {} = Self:GetItemInfo(itemName)
			local hydrationRegen: number = itemInfo.HydrationRegen
			local canDrink: number = MaxDrinkConsume(hydrationRegen, Stats, maxDrink, item)
			if canDrink > 0 then
				--Found drink that doesnt waste
				Self:RemoveItem(itemName, canDrink)
				Stats.Hydration = Stats.Hydration + (canDrink * hydrationRegen) --Update stat
				return true --Ate
			end
			--Could not consume without waste so check for if leastWaste
			if ((-1 * hydrationRegen) > leastWasteRegen) or not leastWastedDrink then
				--least waste so far
				leastWastedDrink = itemInfo.Name
				leastWasteRegen = -1 * hydrationRegen
			end
		end
	end

	--Could not consume without waste. If thirsting consome drink of least waste
	if leastWastedDrink and Tasks.ThirstTask then
		--There was food and NPC is starving so eat out of desperation
		Self:RemoveItem(leastWastedDrink, 1)
		local newDrinkStat: number = Stats.Hydration + math.abs(leastWasteRegen)
		if newDrinkStat <= maxDrink then
			--Within max hunger
			Stats.Hydration = newDrinkStat
		else
			--Set to max stat since greater than allowed stat
			Stats.Hydration = maxDrink
		end
		return true --Drinked
	elseif Tasks.ThirstTask then
		--print("No drink found! Cant drink and thirsting!")
	end
	return false --Could not drink
end

--[[
Handles when an NPC is thirsty
	@param Self (any) any instance fo this class
	@param StatsConfig ({}) table of stat configs
	@param Stats ({}) table of stats
	@param Tasks ({thread}) table of the current tasks
--]]
local function Thirst(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : ()
	Tasks.ThirstTask = task.spawn(function()
		--Damage NPC
		while true do
			local didConsume: boolean = ConsumeDrink(Self, StatsConfig, Stats, Tasks) --Try to consume drink first
			if didConsume or Stats.Hydration > 0 then
				Tasks.ThirstTask = nil
				return--No longer thirsting
			end
			print("Taking starve damage!")
			Self.__Humanoid:TakeDamage(StatsConfig.ThirstDmg)
			task.wait(StatsConfig.ThirstDmgRate)
		end
	end)
end

--[[
Handles the drink stat
	@param Self (any) any instance of this class
	@param StatsConfig ({}) table of stat configs
	@param Stats ({}) table of stats
	@param Tasks ({thread}) table of the current tasks
--]]
local function HandleDrinkStat(Self: any, StatsConfig: {}, Stats: {}, Tasks: {thread}) : ()
	--For each loop if thristy then consume drink until out
	--If out of drink then need to cancel ThirstTask when given drink
	print("Handling hydration")
	while true do
		task.wait(StatsConfig.FdDeteriorationRate) --Wait between decrements
		local newStat: number = Stats.Hydration - StatsConfig.HydDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end
		print("Decrementing hydration. Hydration is now: " .. newStat)
		Stats.Hydration = newStat
		--Check if thristy
		if newStat <= 0 and not Tasks.ThirstTask then
			--Start damaging player and store task to cancel when given drink
			print(Self.Name .. "Is thristing")
			--Attempt to consume drink first
			local didDrink: boolean = ConsumeDrink(Self, StatsConfig, Stats, Tasks)
			if didDrink then
				continue--Skip to next loop
			end
			Thirst(Self, StatsConfig, Stats, Tasks)
		end
	end
end

--[[
Handles the NPC's stats like food and hydration
	Weight impacts rate of food stats going down
	Movement impacts rate of food stats going down
	Should be used inside of a task.spawn
--]]
local function HandleStats(Self) : ()
	print("Starting stats")
	local statsConfig: {} = Self.__StatsConfig
	local stats: {} = Self.__Stats
	local tasks: {thread} = Self.__Tasks
	--Handle food stats
	tasks.FoodStat = task.spawn(function()
		HandleFoodStat(Self, statsConfig, stats, tasks)
	end)
	tasks.HydrationStat = task.spawn(function()
		HandleDrinkStat(Self, statsConfig, stats, tasks)
	end)
	print("Finished seting up food stats handler")
end

--[[
Handles what happens when the NPC dies
	@param Self (any) an instance of the class
--]]
local function HandleDeath(Self) : ()
	Self.__Humanoid.Died:Once(function()
		print("Backpack NPC died!")
		--End tasks
		for _, thread in pairs(Self.__Tasks) do
			if task then
				task.cancel(thread)
			end
		end
		task.wait(5)
		Self:Destroy()
	end)
end

--[[
Constructor for the BackpackNPC class
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxStack (number) the number of stacks allowed for the backpack
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
    @param WhiteList ({string}) table of item names that may be added
    @param EncumbranceSpeed ({[Light, Medium, Heavy] = number}) a table of keys defined
    as Light, Medium, Heavy that have a value pair indicating the speed to go at each Encumbrance level
    if not provided then Light = -1/3speed, Heavy = -2/3 speed
--]]
function BackpackNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxStack: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	WhiteList: { string },
	Backpack: {}?,
	EncumbranceSpeed: {}?,
	DeathHandler: boolean
)
	local self = NPC.new(Name, Rig, Health, SpawnPos, Speed, false)
	setmetatable(self, BackpackNPC)
	self.__OriginalSpeed = Speed
	self.__Backpack = Backpack or {}
	self.__MaxWeight = MaxWeight or 100
	self.__MediumWeight = MediumWeight or 70 --Weight at wich below you are light, but above you are medium
	self.__HeavyWeight = HeavyWeight or 100 --weight at wich you become heavy
	self.__WhiteList = WhiteList or {}
	self.__MaxStack = MaxStack
	if EncumbranceSpeed then
		self.__EncumbranceSpeed = EncumbranceSpeed
	else
		self.__EncumbranceSpeed = {
			Light = Speed,
			Medium = (2 / 3) * Speed,
			Heavy = (1 / 3) * Speed,
		}
	end
	--Handle stats set up
	self.__StatsConfig = {
		--Handles config for stats
		MaxFood = 100,
		MaxHydration = 100,
		FdDeteriorationRate = 5, --time in seconds between when food stat gos down
		HydDeteriorationRate = 120, --time in seconds between when hydration stat gos down
		FdDecrement = 20, --The amount that the food stat is decremented by every FdDeteriorationRate
		HydDecrement = 10, --The amount that the hydration stat is decremented by every HydDeteriorationRate
		StarveDmg = 20,
		StarveDmgRate = 5,
		ThirstDmg = 5,
		ThirstDmgRate = 30,
	}
	self.__Stats = {
		--The stat values
		Food = self.__StatsConfig.MaxFood,
		Hydration = self.__StatsConfig.MaxHydration,
	}
	self.__Tasks = {
		StvTask = nil, --Task that dmgs player during starve
		ThirstTask = nil, --Task that dmgs player during thirst
	}
	self.__Tasks.StvTask = nil
	self.__Tasks.ThirstTask = nil
	HandleStats(self)
	--Handle death
	print("Checking for humanoid")
	print(self.__Humanoid)
	if DeathHandler then
		HandleDeath(self)
	end
	return self
end

--[[
Helper function that manages the encumbrance
	@param Self (any) instance of the class
--]]
local function ManageEncumbrance(Self)
	local encumbrance: string = Self:CheckEncumberment()
	if encumbrance == "Light" then
		local speed: number = Self.__EncumbranceSpeed["Light"]
		if speed == Self:GetSpeed() then
			return
		end
		Self:SetSpeed(Self.__EncumbranceSpeed["Light"])
		Self.__Speed = speed
	elseif encumbrance == "Medium" then
		local speed: number = Self.__EncumbranceSpeed["Medium"]
		if speed == Self:GetSpeed() then
			return
		end
		Self:SetSpeed(speed)
		Self.__Speed = speed
	elseif encumbrance == "Heavy" then
		local speed: number = Self.__EncumbranceSpeed["Heavy"]
		if speed == Self:GetSpeed() then
			return
		end
		Self:SetSpeed(speed)
		Self.__Speed = speed
	end
end

--[[
Used to retrieve the info of any item within the Item Directory in
    ReplicatedStorage.Shared.Items
    @param ItemName (string) name of item to get info of
    @return ({any}) table of info related to the item
--]]
function BackpackNPC:GetItemInfo(ItemName: string): ModuleScript?
	local items: Folder = ReplicatedStorage.Shared.Items
	local itemMod: any? = items:FindFirstChild(ItemName, true)
	if not itemMod then
		warn('Item "' .. ItemName .. '" does not exist within Item directory')
		return nil
	end
	if not itemMod:IsA("ModuleScript") then
		warn('Item "' .. ItemName .. '" is in Item directory but is not a ModuleScript')
		return nil
	end

	local itemInfo: ModuleScript = require(itemMod)
	return itemInfo
end

--[[
Checks if a given item is a drop item that can be picked up
	@param Object (any) any object
	@return (boolean) true if DropItem or false otherwise
--]]
function BackpackNPC:IsDropItem(Object: any): boolean
	return CollectionService:HasTag(Object, "DropItem")
end

--[[
Returns the current amount of stacks filled in the NPC's backpack
    @return (number) the amount of stacks filled in NPC's backpack
--]]
function BackpackNPC:GetStackAmount(): number
	local stackCount: number = 0
	for _, item in pairs(self.__Backpack) do
		stackCount = stackCount + item.StackCount
	end
	return stackCount
end

--[[
Returns the amount of stack slots left into an NPC's inventory
    @return (number) the amount of slots left
--]]
function BackpackNPC:StackSlotsLeft(): number
	return self.__MaxStack - self:GetStackAmount()
end

--[[
Returns the space left without allocating a new stack for a given item
    @param ItemName (string) name of the item in the NPC's backpack
    @return (number) space left for given item on success or -1 otherwise
--]]
function BackpackNPC:StackSpace(ItemName: string): number
	local item: any = self.__Backpack[ItemName]
	if not item then
		warn('Item "' .. ItemName .. '" does not exist within NPC "' .. self.Name .. '"')
		return -1
	end

	local itemInfo: ModuleScript = self:GetItemInfo(ItemName)
	local stackSpaceCap: number = item.StackCount * itemInfo.ItemStack
	local spaceLeft: number = stackSpaceCap - item.Count
	return spaceLeft
end

--[[
Handles the stack when adding a new item
	@param Item (any) a refrence to the item element of the backpack table
	@param Amount (number) to amount of the item being added (not amoutn of stacks)
	@param Self (any) instance of the class
	@param ItemInfo (ModuleScript) the module script of the items info
	@return (boolean) true on success or false otherwise
--]]
local function ManageStacksAdd(Item: any, Amount: number, Self: any, ItemInfo: ModuleScript): boolean
	local spaceLeft: number = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter: number = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks: number = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
		if (Self:StackSlotsLeft() - neededStacks) < 0 then
			--NPC out of slots to add more
			return false
		end

		--Stacks are availible to add
		Item.StackCount = Item.StackCount + neededStacks
		return true
	end
end

--[[
Checks the stack when adding a new item to see if valid
	@param Item (any) a refrence to the item element of the backpack table
	@param Amount (number) to amount of the item being added (not amoutn of stacks)
	@param Self (any) instance of the class
	@param ItemInfo (ModuleScript) the module script of the items info
	@return (boolean) true on success or false otherwise
--]]
local function CheckStacksAdd(Item: any, Amount: number, Self: any, ItemInfo: ModuleScript): boolean
	local spaceLeft: number = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter: number = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks: number = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
		if (Self:StackSlotsLeft() - neededStacks) < 0 then
			--NPC out of slots to add more
			return false
		end

		--Stacks are availible to add
		return true
	end
end

--[[
Puts a given item and its amount in the NPC's backpack
    @param ItemName (string) the name of the item
    @param Amount (number) the number of the item to add to the player
	@return (boolean) true on success or false on error
--]]
function BackpackNPC:CollectItem(ItemName: string, Amount: number): boolean
	--Check whitelist
	if not self:CheckItemWhitelist(ItemName) then
		warn('Item "' .. ItemName .. '" not in whitelist of NPC "' .. self.Name .. '" when trying to collect item')
		return false --Not in whitelist
	end

	--Check amount for negative or 0
	if Amount <= 0 then
		warn('Attempted to add Item "' .. ItemName .. '" to NPC "' .. self.Name .. '" with amount of 0 or less')
		return false
	end

	local itemInfo: ModuleScript = self:GetItemInfo(ItemName)
	if not itemInfo then
		return false
	end
	local item: any = self.__Backpack[ItemName]
	local firstAdd: boolean = false
	if not item then
		--Not added yet needs set up
		item = {} --Init item
		item.Weight = 0
		item.Count = 0
		item.StackCount = 0
		item.ItemType = itemInfo.ItemType
		item.DropItem = itemInfo.DropItem
		firstAdd = true
	end
	--Check weight
	local addedWeight: number = (Amount * itemInfo.ItemWeight)
	if (self:CheckNPCWeight() + addedWeight) > self.__MaxWeight then
		warn('Attempted to add Item "' .. ItemName .. '" to NPC "' .. self.Name .. '" but amount exceeded MaxWeight')
		return false
	end
	local stackSuccess: boolean = ManageStacksAdd(item, Amount, self, itemInfo)
	if stackSuccess then
		--Add amount to count and weight
		item.Count = item.Count + Amount
		item.Weight = item.Weight + addedWeight
	else
		warn('Attempted to add Item "' .. ItemName .. '" to NPC "' .. self.Name .. '" but amount exceeded stack slots')
		return false
	end

	--If first add of item then set up item in backpack
	if firstAdd then
		self.__Backpack[ItemName] = item
	end
	ManageEncumbrance(self)
	return true
end

--[[
Determines the max amount of an item type possible given NPCs backpack state
	by stack
	@param ItemInfo (ModuleScript) the module script holding the items info
	@param Self (any) any instance of the class
	@return (number) the max amount of the item that can be added to the backpack 
	considering the stacks
--]]
local function CheckMaxByStack(ItemInfo: ModuleScript, Self: any): number
	local spaceLeft: number = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end

	local stacksLeft: number = Self:StackSlotsLeft()
	local maxCount: number = (stacksLeft * ItemInfo.ItemStack) + spaceLeft
	return maxCount
end

--[[
Determines the max amount of an item type possible given NPCs backpack state
	by weight
	@param ItemInfo (ModuleScript) the module script holding the items info
	@param Self (any) any instance of the class
	@return (number) the max amount of the item that can be added to the backpack 
	considering the weight
--]]
local function CheckMaxByWeight(ItemInfo: ModuleScript, Self: any): number
	local currentWeight: number = Self:CheckNPCWeight()
	local itemWeight: number = ItemInfo.ItemWeight
	local remainingWeight: number = Self.__MaxWeight - currentWeight
	local maxCount: number = math.floor(remainingWeight / itemWeight)
	return maxCount
end

--[[
Determines the max amount of the item type that can be picked up
	given the NPC's current backpack
	@param ItemName (string) name of the item
	does not need to be in backpack but must have an info mod script
	@return (number) max amount possible to be put into the NPC
--]]
function BackpackNPC:GetMaxCollect(ItemName: string): number
	local itemInfo: ModuleScript = self:GetItemInfo(ItemName)
	if not itemInfo then
		return -1
	end
	--Determine what factor provides the least amount of the item and return that value
	local maxByStack: number = CheckMaxByStack(itemInfo, self)
	local maxByWeight: number = CheckMaxByWeight(itemInfo, self)

	if maxByWeight <= maxByStack then
		return maxByWeight
	else
		return maxByStack
	end
end

--[[
Helper functiont that handles the count attribute of an item during pick up
	@param Item (any) any item witch a count attribute
	@param Self (any) instance of the class
	@return (number) the count attributes remaining number of the item
	returns -1 on error
--]]
local function HandleCount(Item: any, Self: any): number
	local count: number = Item:GetAttribute("Count")
	if not count then
		warn('NPC "' .. Self.Name .. '" Attempted to pick up object that lacks a Count attribute')
		return -1
	end
	local maxCount: number = Self:GetMaxCollect(Item.Name)
	if count <= maxCount then
		--Safe to put full amount in backpack
		Self:CollectItem(Item.Name, count)
		Item:SetAttribute("Count", 0)
		return 0
	else
		--Not enough space to put full thing in backpack
		Self:CollectItem(Item.Name, maxCount)
		local remainingCount: number = count - maxCount
		Item:SetAttribute("Count", remainingCount)
		return remainingCount
	end
end

--[[
Picks up an item physicaly in the workspace
	attempts to pick up as much "count" of the item as possible
	@param Item (any) any item considerd a DropItem
	@return (number) the remaining count of the item left not picked up
	due to not being able to add to NPC inventory
	returns -1 on error
--]]
function BackpackNPC:PickUp(Item: any): number
	if not self:IsDropItem(Item) then
		warn(
			'Attempted to pick up Item "' .. Item.Name .. '" for NPC "' .. self.Name .. '" but item was not a DropItem'
		)
		return -1
	end
	local itemCount: number = HandleCount(Item, self)
	if itemCount == 0 then
		--item out of count so can destroy
		Item:Destroy()
		return itemCount
	else
		--Return amount of item still on ground or -1 if count error
		return itemCount
	end
end

--[[
Checks if a given item is valid to be added to the NPC
    @param ItemName (string) the name of the item to check for
	@param Amount (number) the amount of the item checking to be added for
    @return (boolean) true on valid or false otherwise
--]]
function BackpackNPC:ValidItemCollection(ItemName: string, Amount): boolean
	--Check whitelist
	if not self:CheckItemWhitelist(ItemName) then
		return false --Not in whitelist
	end

	if Amount <= 0 then
		--Amount may not be 0 or negative
		return false
	end

	local itemInfo: ModuleScript = self:GetItemInfo(ItemName)
	if not itemInfo then
		--Info module missing from items folder
		return false
	end

	local item: any = self.__Backpack[ItemName]
	local itemCopy: { any } = {}
	if item then
		itemCopy.Weight = item.Weight
		itemCopy.Count = item.Count
		itemCopy.StackCount = item.StackCount
		itemCopy.ItemType = itemInfo.ItemType
	else
		itemCopy.Weight = 0
		itemCopy.Count = 0
		itemCopy.StackCount = 0
		itemCopy.ItemType = itemInfo.ItemType
	end

	--Check weight
	local addedWeight: number = (Amount * itemInfo.ItemWeight)
	if (self:CheckNPCWeight() + addedWeight) > self.__MaxWeight then
		return false
	end
	local stackSuccess = CheckStacksAdd(itemCopy, Amount, self, itemInfo)
	if stackSuccess then
		return true
	else
		return false
	end
end

--[[
Drops the physical item of the item on to the ground of the NPC
    @param ItemTemplate (any) any item to be put on the ground
	@param NPCCharacter (Model) the model of the NPC
	@param Count (number) the number of the item to drop
--]]
local function SpawnDrop(ItemTemplate: any, NPCCharacter: Model, Count: number): ()
	local item: any = BackpackNPCUtils:CopyItem(ItemTemplate)
	item:SetAttribute("Count", Count)
	local spawnSuccess: boolean = BackpackNPCUtils:DropItem(item, NPCCharacter)
	if not spawnSuccess then
		--Consider at somepoint adding fallback
		item:Destroy()
	end
end

--[[
Drops a given item given its amount to drop
    setting the Amount to remove greater than the present items is NOT
    considerd an error and will generate no warnings
    instead all items in that case will be droped
    @param ItemName (string) the name of the item to remove
    @param Amount (number) the amount of item to remove
--]]
function BackpackNPC:DropItem(ItemName: string, Amount: number): ()
	local item: any = self.__Backpack[ItemName]
	if not item then
		warn('Attempted to drop Item "' .. ItemName .. '" from NPC "' .. self.Name .. '" but item was not in backpack')
		return
	end

	local dropItem: any = item.DropItem
	if not dropItem then
		warn(
			'Attempted to drop Item "'
				.. ItemName
				.. '" from NPC "'
				.. self.Name
				.. '" but item does not have a DropItem saved in Items info'
		)
	end

	--Drop the amount equal to or less than current amount
	local currentAmount: number = item.Count
	if (currentAmount - Amount) < 0 then
		--Drop current amount
		SpawnDrop(item.DropItem, self.__NPC, currentAmount)
		--Remove from backpack
		self:RemoveItem(ItemName, currentAmount)
	else
		--Drop Amount
		SpawnDrop(item.DropItem, self.__NPC, Amount)
		--Remove from backpack
		self:RemoveItem(ItemName, Amount)
	end
end

--[[
Drops all items in a NPC's backpack
--]]
function BackpackNPC:DropAllItems(): ()
	for itemName, item in pairs(self.__Backpack) do
		self:DropItem(itemName, item.Count)
	end
end

--[[
Handles the stack when removing an item
	@param Item (any) any item to manage the stack for thats in the backpack
	@param Amount (number) amount of item being removed
	@param Self (any) an instance of the class
	@param ItemInfo (ModuleScript) the module script containing the items info
--]]
local function ManageStacksRemove(Item: any, Amount: number, Self: any, ItemInfo: ModuleScript): ()
	local amountItemAfter: number = Item.Count - Amount
	if amountItemAfter <= 0 then
		--Stack count will be empty because removing more or same amount of exisitng items that exist
		Item.StackCount = 0
	else
		--Calc new amount of stacks needed
		Item.StackCount = math.ceil(amountItemAfter / ItemInfo.ItemStack)
	end
end

--[[
Deletes an item in an NPC's inventory for a given amount
    @param ItemName the name of the item to delete
    @param Amount the amount of that item to delete
--]]
function BackpackNPC:RemoveItem(ItemName: string, Amount: number): ()
	local item: any = self.__Backpack[ItemName]
	if not item then
		warn('"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to remove item')
		return
	end
	--Handle stack during remove
	local itemInfo: ModuleScript = self:GetItemInfo(ItemName)
	ManageStacksRemove(item, Amount, self, itemInfo)
	item.Count = item.Count - Amount
	if item.Count < 0 or item.Count == 0 then
		--Remove item from backpack because 0 or less
		self.__Backpack[ItemName] = nil
	end
	ManageEncumbrance(self)
end

--[[
Deletes all items from a NPC's backpack
--]]
function BackpackNPC:RemoveAllItems(): ()
	self.__Backpack = {} --Empty backpack table
	ManageEncumbrance(self)
end

--[[
Transfers a given item from an NPC to some form of storage
    @param ItemName (string) the name of the item to transfer
    @param Amount (number) the amount of the item to transfer to storage
    @param StorageDevice (any) any form of storage device that can take an item
    @return (boolean) true on success or false otherwise
--]]
function BackpackNPC:TransferItemToStorage(ItemName: string, Amount: number, StorageDevice: any): boolean
	AbstractInterface:AbstractError("TransferItemToStorage", "BackpackNPC")
	return false
end

--[[
Transfers a given item from an NPC to a players backpack
    @param ItemName (string) the name of the item to transfer
    @param Amount (number) the amount of the item to transfer to storage
    @param StorageDevice (any) any form of storage device that can take an item
    @return (boolean) true on success or false otherwise
--]]
function BackpackNPC:TransferItemToPlayer(ItemName: string, Amount: number, Player: Player): boolean
	AbstractInterface:AbstractError("TransferItemToPlayer", "BackpackNPC")
	return false
end

--[[
Checks for a given item in a NPC's backpack
	@param ItemName (string) the name of the item to check for
	@return (boolean) true if in backpack or false otherwise
--]]
function BackpackNPC:CheckForItem(ItemName: string): boolean
	local item: any = self.__Backpack[ItemName]
	if item then
		--item is present in backpack
		return true
	else
		return false --item not found in backpack
	end
end

--[[
Checks for a given item and returns the count of that item
	@param ItemName (string) the name of the item to check for
	@return (number) count of item if found or -1 otherwise
--]]
function BackpackNPC:GetItemCount(ItemName: string): number
	local item: any = self.__Backpack[ItemName]
	if item then
		--item is present in backpack so return count and weight of item
		return item.Count
	else
		warn(
			'"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to get item count'
		)
		return -1 --item not found in backpack
	end
end

--[[
Checks for a given item and returns the count of that item
	@param ItemName (string) the name of the item to check for
	@return (number) count of item if found or -1 otherwise
--]]
function BackpackNPC:GetItemWeight(ItemName: string): number
	local item: any = self.__Backpack[ItemName]
	if item then
		--item is present in backpack so return count and weight of item
		return item.Weight
	else
		warn(
			'"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to get item weight'
		)
		return -1 --item not found in backpack
	end
end

--[[
Checks the numerical value of the weight of the NPC
	@return (number) the NPC's current weight
--]]
function BackpackNPC:CheckNPCWeight(): number
	local weight: number = 0
	for _, value in pairs(self.__Backpack) do
		weight = weight + value.Weight
	end
	return weight
end

--[[
Checks the NPC encumberment based on its weight
@return (string) "Light", "Medium", or "Heavy" based on respective encumberment
--]]
function BackpackNPC:CheckEncumberment(): string
	local weight: number = self:CheckNPCWeight()
	if weight < self.__MediumWeight then
		return "Light"
	elseif weight >= self.__MediumWeight and weight < self.__HeavyWeight then
		return "Medium"
	else
		return "Heavy"
	end
end

--[[
Gets an items type
    Item must already be present in NPC's backpack
    @param ItemName (string) the name of the item to check for
    @return (string) name of item type on success or nil otherwise
--]]
function BackpackNPC:CheckItemType(ItemName: string): string?
	local item: any = self.__Backpack[ItemName]
	if item then
		return item.ItemType
	else
		warn('"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to get item type')
		return nil
	end
end

--[[
Checks if an item is included in an NPC's whitelist
	@param ItemName (string) the name of the item to check for
--]]
function BackpackNPC:CheckItemWhitelist(ItemName: string): boolean
	if table.find(self.__WhiteList, ItemName) then
		return true
	else
		return false --Not in whitelist
	end
end

--[[
Kills the NPC and drops all items in its backpack and destroys the NPC
--]]
function BackpackNPC:Kill()
	self:DropAllItems()
	self:Destroy()
end

return BackpackNPC
