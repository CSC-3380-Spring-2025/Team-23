--[[
This abstract class provides the required methods for an NPC that has a backpack
Before making a subclass or expanding this class you should take great care
in examining the existing functions and ensure that you follow the same approach 
in the backpack table layout with its keys and values.
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
	EncumbranceSpeed: {}?
)
	local self = NPC.new(Name, Rig, Health, SpawnPos, Speed)
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
	return self
end

local function ManageEncumbrance(Self)
	local encumbrance = Self:CheckEncumberment()
	if encumbrance == "Light" then
		local speed = Self.__EncumbranceSpeed["Light"]
		if speed == Self:GetSpeed() then
			return
		end
		Self:SetSpeed(Self.__EncumbranceSpeed["Light"])
		Self.__Speed = speed
	elseif encumbrance == "Medium" then
		local speed = Self.__EncumbranceSpeed["Medium"]
		if speed == Self:GetSpeed() then
			return
		end
		Self:SetSpeed(speed)
		Self.__Speed = speed
	elseif encumbrance == "Heavy" then
		local speed = Self.__EncumbranceSpeed["Heavy"]
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
function BackpackNPC:GetItemInfo(ItemName: string): { any }?
	local items = ReplicatedStorage.Shared.Items
	local itemMod = items:FindFirstChild(ItemName, true)
	if not itemMod then
		warn('Item "' .. ItemName .. '" does not exist within Item directory')
		return nil
	end
	if not itemMod:IsA("ModuleScript") then
		warn('Item "' .. ItemName .. '" is in Item directory but is not a ModuleScript')
		return nil
	end

	local itemInfo = require(itemMod)
	return itemInfo
end

--[[
Checks if a given item is a drop item that can be picked up
	@param Object (any) any object
	@return (boolean) true if DropItem or false otherwise
--]]
function BackpackNPC:IsDropItem(Object)
	return CollectionService:HasTag(Object, "DropItem")
end

--[[
Returns the current amount of stacks filled in the NPC's backpack
    @return (number) the amount of stacks filled in NPC's backpack
--]]
function BackpackNPC:GetStackAmount()
	local stackCount = 0
	for _, item in pairs(self.__Backpack) do
		stackCount = stackCount + item.StackCount
	end
	return stackCount
end

--[[
Returns the amount of stack slots left into an NPC's inventory
    @return (number) the amount of slots left
--]]
function BackpackNPC:StackSlotsLeft()
	return self.__MaxStack - self:GetStackAmount()
end

--[[
Returns the space left without allocating a new stack for a given item
    @param ItemName (string) name of the item in the NPC's backpack
    @return (number) space left for given item on success or -1 otherwise
--]]
function BackpackNPC:StackSpace(ItemName)
	local item = self.__Backpack[ItemName]
	if not item then
		warn('Item "' .. ItemName .. '" does not exist within NPC "' .. self.Name .. '"')
		return -1
	end

	local itemInfo = self:GetItemInfo(ItemName)
	local stackSpaceCap = item.StackCount * itemInfo.ItemStack
	local spaceLeft = stackSpaceCap - item.Count
	return spaceLeft
end

--[[
Handles the stack when adding a new item
--]]
local function ManageStacksAdd(Item, Amount, Self, ItemInfo): boolean
	local spaceLeft = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
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
--]]
local function CheckStacksAdd(Item, Amount, Self, ItemInfo): boolean
	local spaceLeft = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
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

	local itemInfo = self:GetItemInfo(ItemName)
	if not itemInfo then
		return false
	end
	local item = self.__Backpack[ItemName]
	local firstAdd = false
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
	local addedWeight = (Amount * itemInfo.ItemWeight)
	if (self:CheckNPCWeight() + addedWeight) > self.__MaxWeight then
		warn('Attempted to add Item "' .. ItemName .. '" to NPC "' .. self.Name .. '" but amount exceeded MaxWeight')
		return false
	end
	local stackSuccess = ManageStacksAdd(item, Amount, self, itemInfo)
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
--]]
local function CheckMaxByStack(ItemInfo, Self)
	local spaceLeft = 0
	if Self.__Backpack[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName)
		--else spaceLeft is 0 because no stack made yet
	end

	local stacksLeft = Self:StackSlotsLeft()
	local maxCount = (stacksLeft * ItemInfo.ItemStack) + spaceLeft
	return maxCount
end

--[[
Determines the max amount of an item type possible given NPCs backpack state
	by weight
--]]
local function CheckMaxByWeight(ItemInfo, Self)
	local currentWeight = Self:CheckNPCWeight()
	local itemWeight = ItemInfo.ItemWeight
	local remainingWeight = Self.__MaxWeight - currentWeight
	local maxCount = math.floor(remainingWeight / itemWeight)
	return maxCount
end

--[[
Determines the max amount of the item type that can be picked up
	given the NPC's current backpack
--]]
function BackpackNPC:GetMaxCollect(ItemName) : number
	local itemInfo = self:GetItemInfo(ItemName)
	if not itemInfo then
		return -1
	end
	--Determine what factor provides the least amount of the item and return that value
	local maxByStack = CheckMaxByStack(itemInfo, self)
	local maxByWeight = CheckMaxByWeight(itemInfo, self)

	if maxByWeight <= maxByStack then
		return maxByWeight
	else
		return maxByStack
	end
end

--[[
Helper functiont that handles the count attribute of an item during pick up
	@return (number) the count attributes remaining number of the item
	returns -1 on error
--]]
local function HandleCount(Item, Self) : number
	local count = Item:GetAttribute("Count")
	if not count then
		warn('NPC "' .. Self.Name .. '" Attempted to pick up object that lacks a Count attribute')
		return -1
	end
	local maxCount = Self:GetMaxCollect(Item.Name)
	if count <= maxCount then
		--Safe to put full amount in backpack
		Self:CollectItem(Item.Name, count)
		Item:SetAttribute("Count", 0)
		return 0
	else
		--Not enough space to put full thing in backpack
		Self:CollectItem(Item.Name, maxCount)
		local remainingCount = count - maxCount
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
function BackpackNPC:PickUp(Item) : number
	if not self:IsDropItem(Item) then
		warn('Attempted to pick up Item "' .. Item.Name .. '" for NPC "' .. self.Name .. '" but item was not a DropItem')
		return -1
	end
	local itemCount = HandleCount(Item, self)
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

	local itemInfo = self:GetItemInfo(ItemName)
	if not itemInfo then
		--Info module missing from items folder
		return false
	end

	local item = self.__Backpack[ItemName]
	local itemCopy = {}
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
	local addedWeight = (Amount * itemInfo.ItemWeight)
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
    @param NPCCharacter that NPC's Character
--]]
local function SpawnDrop(ItemTemplate: any, NPCCharacter: Model, Count: number) : ()
    local item = BackpackNPCUtils:CopyItem(ItemTemplate)
    item:SetAttribute("Count", Count)
	local spawnSuccess = BackpackNPCUtils:DropItem(item, NPCCharacter)
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
	local item = self.__Backpack[ItemName]
	if not item then
		warn('Attempted to drop Item "' .. ItemName .. '" from NPC "' .. self.Name .. '" but item was not in backpack')
		return
	end

	local dropItem = item.DropItem
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
	local currentAmount = item.Count
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
--]]
local function ManageStacksRemove(Item, Amount, Self, ItemInfo): ()
	local amountItemAfter = Item.Count - Amount
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
	local item = self.__Backpack[ItemName]
	if not item then
		warn('"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to remove item')
		return
	end
	--Handle stack during remove
	local itemInfo = self:GetItemInfo(ItemName)
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
	local item = self.__Backpack[ItemName]
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
	local item = self.__Backpack[ItemName]
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
	local item = self.__Backpack[ItemName]
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
	local weight = 0
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
	local weight = self:CheckNPCWeight()
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
	local item = self.__Backpack[ItemName]
	if item then
		return item.ItemType
	else
		warn('"' .. ItemName .. '" not found in backpack of NPC "' .. self.Name .. '" when attempting to get item type')
		return nil
	end
end

--[[
Checks if an item is included in an NPC's whitelist
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
