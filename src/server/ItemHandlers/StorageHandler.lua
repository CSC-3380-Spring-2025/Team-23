--[[
This script provides handling for any and all storage types
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerMutexSeq = require(ServerScriptService.Server.ServerUtilities.ServerMutexSeq)
local ItemUtils = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local StorageHandler = {}
Object:Supersedes(StorageHandler)

--[[
Constructor of the StorageHandler instance
    @param Name (string) name of your instance
--]]
function StorageHandler.new(Name)
    local self = Object.new(Name)
    setmetatable(self, StorageHandler)
    return self
end

--Instances
local itemUtilities: any = ItemUtils.new("StorageHandlerItemUtils")

--Vars
local storageTable: {} = {} --Stores a list of all storage availible on the server
local storageDescriptor: number = 1 --GLobal storage descriptor for easy access to storage
local storageMutex: any = ServerMutexSeq.new("StorageMutex")

--[[
Gets the table of items from a StorageDescriptors value
    @param StorageDescriptor (number) the storage descriptor number
    @return ({}) the inventory table of an individual storage
--]]
local function GetInventory(StorageDescriptor: number) : {}
    local curDescript: {any} = storageTable[StorageDescriptor]
    return curDescript.Inventory
end

--[[
Returns the number of max stacks allowed for a storage
    @param StorageDescriptor (number) the storage descriptor number
    @return (number) the number of stacks allowed for the given storage
--]]
local function GetMaxStack(StorageDescriptor: number) : number
    local curDescript: {any} = storageTable[StorageDescriptor]
    return curDescript.Config.MaxStack
end

--[[
Handles the stack when removing an item
	@param Item (any) any item to manage the stack for thats in the storage inventory
	@param Amount (number) amount of item being removed
	@param Self (any) an instance of the class
	@param ItemInfo (ModuleScript) the module script containing the items info
--]]
local function ManageStacksRemove(Item: any, Amount: number, Self: any, ItemInfo: {}): ()
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
Removes an item from a storage effectively deleting it
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @param ItemName (string) the name of the item to remove
    @param Amount (number) the number of the item to remove
--]]
function StorageHandler:RemoveItem(StorageDescriptor: number, ItemName: string, Amount: number) : ()
    storageMutex:Lock()
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to remove item from storage descriptor that is not valid")
        storageMutex:Unlock()
        return
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
    local item: {[string]: any} = inventory[ItemName]
	if not item then
		warn('"' .. ItemName .. '" not found in inventory of storage when attempting to remove item')
        storageMutex:Unlock()
		return
	end
	--Handle stack during remove
	local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
	ManageStacksRemove(item, Amount, self, itemInfo)
	item.Count = item.Count - Amount
	if item.Count < 0 or item.Count == 0 then
		--Remove item from inventory because 0 or less
		inventory[ItemName] = nil
	end
	storageMutex:Unlock()
end

--[[
Deletes all items from a storage inventory
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
--]]
function StorageHandler:RemoveAllItems(StorageDescriptor: number): ()
    storageMutex:Lock()
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to remove all items from storage descriptor that is not valid")
        storageMutex:Unlock()
        return
    end
    local curDescript: {[string]: any} = storageTable[StorageDescriptor]
	curDescript.Inventory = {} --Empty ineventory table
    storageMutex:Unlock()
end

--[[
Checks for a given item in a storage inventory
	@param ItemName (string) the name of the item to check for
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (boolean) true if in inventory or false otherwise
--]]
function StorageHandler:CheckForItem(ItemName: string, StorageDescriptor: number): boolean
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to check for item from storage descriptor that is not valid")
        return false
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local item: {[string]: any} = inventory[ItemName]
	if item then
		--item is present in inventory
		return true
	else
		return false --item not found in inventory
	end
end

--[[
Checks for a given item and returns the count of that item
	@param ItemName (string) the name of the item to check for
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (number) count of item if found or -1 otherwise
--]]
function StorageHandler:GetItemCount(ItemName: string, StorageDescriptor: number): number
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to check for item from storage descriptor that is not valid")
        return -1
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local item: {[string]: any} = inventory[ItemName]
	if item then
		--item is present in inventory so return count of item
		return item.Count
	else
		warn(
			'"' .. ItemName .. '" not found in inventory of storage when attempting to get item count'
		)
		return -1 --item not found in inventory
	end
end

--[[
Checks if a given storage descriptor is valid
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
--]]
function StorageHandler:ValidDescriptor(StorageDescriptor: number) : boolean
    if not storageTable[StorageDescriptor] then
        --No refrence to this descriptor anymore
        return false
    else
        return true
    end
end

--[[
Returns the current amount of stacks filled in the storage device
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @return (number) the amount of stacks filled in storage or -1 on error
--]]
function StorageHandler:GetFilledStackAmount(StorageDescriptor: number): number
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempt to GetFilledStackAmount but descriptor was invalid")
        return -1
    end
	local stackCount: number = 0
	for _, item in pairs(GetInventory(StorageDescriptor)) do
		stackCount = stackCount + item.StackCount
	end
	return stackCount
end

--[[
Returns the amount of stack slots left into a storages inventory
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @return (number) the amount of slots left or -1 on error
--]]
function StorageHandler:StackSlotsLeft(StorageDescriptor: number): number
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempt to StackSlotsLeft but descriptor was invalid")
        return -1
    end
    local maxStack: number = GetMaxStack(StorageDescriptor)
	return maxStack - self:GetFilledStackAmount(StorageDescriptor)
end

--[[
Returns the space left for a particular item in an exisitng stack without allocating a new stack for a given item
    @param ItemName (string) name of the item in the storages inventory
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @return (number) space left for given item on success or -1 otherwise
--]]
function StorageHandler:StackSpace(ItemName: string, StorageDescriptor: number): number
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempt to get StackSpace but descriptor was invalid")
        return -1
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local item: {[string]: any} = inventory[ItemName]
	if not item then
		warn('Item "' .. ItemName .. '" does not exist within given storage')
		return -1
	end

	local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
    if not itemInfo then
        return -1
    end
	local stackSpaceCap: number = item.StackCount * itemInfo.ItemStack
	local spaceLeft: number = stackSpaceCap - item.Count
	return spaceLeft
end

--[[
Handles the stack when adding a new item
	@param Item (any) a refrence to the item element of the storages item table
	@param Amount (number) to amount of the item being added (not amount of stacks)
	@param Self (any) instance of the class
	@param ItemInfo (ModuleScript) the module script of the items info
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (boolean) true on success or false otherwise
--]]
local function ManageStacksAdd(Item: any, Amount: number, Self: any, ItemInfo: {[string]: any}, StorageDescriptor: number): boolean
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local spaceLeft: number = 0
	if inventory[ItemInfo.ItemName] then
		--Is already in inventory so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName, StorageDescriptor)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter: number = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks: number = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
		if (Self:StackSlotsLeft(StorageDescriptor) - neededStacks) < 0 then
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
	@param Item (any) a refrence to the item element of the inventory table
	@param Amount (number) to amount of the item being added (not amoutn of stacks)
	@param Self (any) instance of the class
	@param ItemInfo (ModuleScript) the module script of the items info
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (boolean) true on success or false otherwise
--]]
local function CheckStacksAdd(Item: any, Amount: number, Self: any, ItemInfo: {}, StorageDescriptor: number): boolean
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local spaceLeft: number = 0
	if inventory[ItemInfo.ItemName] then
		--Is already in inventory so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName, StorageDescriptor)
		--else spaceLeft is 0 because no stack made yet
	end
	local spaceAfter: number = spaceLeft - Amount

	if spaceAfter >= 0 then
		--Current stack can accomodate no need to add new stack
		return true
	else
		--Attempt to add new stack or stacks
		local neededStacks: number = math.ceil(math.abs(spaceAfter) / ItemInfo.ItemStack)
		if (Self:StackSlotsLeft(StorageDescriptor) - neededStacks) < 0 then
			--NPC out of slots to add more
			return false
		end

		--Stacks are availible to add
		return true
	end
end

--[[
Adds a given item to a storage device=
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @param ItemName (string) the name of the item to remove
    @param Self (any) an instance of the class
    @return (boolean) true on success or false otherwise
--]]
local function AddToStorage(StorageDescriptor: number, ItemName: string, Amount: number, Self: {}) : boolean
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)

    local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
	if not itemInfo then
		return false
	end
	local item: {[string]: any} = inventory[ItemName]
	local firstAdd: boolean = false
	if not item then
		--Not added yet needs set up
		item = {} --Init item
		item.Count = 0
		item.StackCount = 0
		item.ItemType = itemInfo.ItemType
		item.DropItem = itemInfo.DropItem
		firstAdd = true
	end

	local stackSuccess: boolean = ManageStacksAdd(item, Amount, Self, itemInfo, StorageDescriptor)
	if stackSuccess then
		--Add amount to count and weight
		item.Count = item.Count + Amount
	else
		warn('Attempted to add Item "' .. ItemName .. '" to storage but amount exceeded stack slots')
		return false
	end

	--If first add of item then set up item in inventory
	if firstAdd then
		inventory[ItemName] = item
	end
	return true
end

--[[
Checks if item is a valid item for the storage and if so then adds to the storage
    @param StorageDescriptor (number) the descriptor of the storage device
    returned by other methods like AddStorageDevice
    @param Item (any) any item in the Items directory in replciated storage
    @param Amount (number) the number of this item to add to storage
    @return (boolean) true on success or false otherwise
--]]
function StorageHandler:AddItem(StorageDescriptor: number, ItemName: string, Amount: number) : boolean
    storageMutex:Lock()
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to add item to storage descriptor that is not valid")
        storageMutex:Unlock()
        return false
    end
    --Check amount for negative or 0
	if Amount <= 0 then
		warn('Attempted to add Item "' .. ItemName .. '" to storage with amount of 0 or less')
        storageMutex:Unlock()
		return false
	end
    local success: boolean = false
    --Check for if whitelsited item
    if self:IsValidItem(StorageDescriptor, ItemName) then
        --Valid item so add item
        success = AddToStorage(StorageDescriptor, ItemName, Amount, self)
    end
    --Try to add item if item is not full
    storageMutex:Unlock()
    return success
end


--[[
Helper function that checks for if an item is whitelisted in the config
    @param DescriptorValue ({[string]: any}) the value of the descriptor
    @param ItemName (string) the name of the item
    @param ItemTypeName (string) the name of the type of item
    @return (boolean) true if whitelisted or false otherwise
--]]
local function CheckItem(DescriptorValue: {[string]: any}, ItemName: string, ItemTypeName: string) : boolean
    local itemConfig: {[string]: any} = DescriptorValue.Config.ItemsConfig
    for itemType, itemList in pairs(itemConfig) do
        if ItemTypeName == itemType then
            for _, item in pairs(itemList) do
                if item == "AllItems" then
                    --All items are valid of this type
                    return true
                elseif item == ItemName then
                    return true
                end
            end 
        end
    end
    return false --Item not found in whitelist
end

--[[
Determines if an item is a valid add or not.
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @param ItemName (string) the name of the item to check if valid
    @return (boolean) true on is valid or false otherwise
--]]
function StorageHandler:IsValidItem(StorageDescriptor: number, ItemName: string) : boolean
    --Check for if item is in whitelist
    local curDescript: {[string]: any} = storageTable[StorageDescriptor]
    if not curDescript then
        warn("Storage Descriptor not exist for any storage")
        return false
    end
    local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
    if not itemInfo then
        return false --No info found and itemInfo already warns
    end
    return CheckItem(curDescript, ItemName, itemInfo.ItemType)
end

--[[
Checks if an item add will fit into the storage device
    This does NOT check if it is a valid item for the storage
    If you attempt to see if an item fits that is invalid you will recieve a warning
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @param ItemName (string) the name of the item to check if the item fits
    @param Amount (number) the amount of the item you are adding
    @return (boolean) true on does fit or false otherwise
--]]
function StorageHandler:ItemFits(StorageDescriptor: number, ItemName: string, Amount: number)
    if not self:IsValidItem(StorageDescriptor, ItemName) then
        warn("Attempted to use ItemFits with invalid item")
        return false
    end
    if Amount <= 0 then
		--Amount may not be 0 or negative
		return false
	end

    local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
	if not itemInfo then
		--Info module missing from items folder
		return false
	end

    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
    local item: {[string]: any} = inventory[ItemName]
	local itemCopy: {[string]: any} = {}
	if item then
		itemCopy.Count = item.Count
		itemCopy.StackCount = item.StackCount
		itemCopy.ItemType = itemInfo.ItemType
	else
		itemCopy.Count = 0
		itemCopy.StackCount = 0
		itemCopy.ItemType = itemInfo.ItemType
	end

	local stackSuccess = CheckStacksAdd(itemCopy, Amount, self, itemInfo, StorageDescriptor)
	if stackSuccess then
		return true
	else
		return false
	end
end

--[[
Determines the max amount of an item type possible given NPCs backpack state
	by stack
	@param ItemInfo (ModuleScript) the module script holding the items info
	@param Self (any) any instance of the class
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (number) the max amount of the item that can be added to the backpack 
	considering the stacks
--]]
local function CheckMaxByStack(ItemInfo: {[string]: any}, Self: any, StorageDescriptor: number): number
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
	local spaceLeft: number = 0
	if inventory[ItemInfo.ItemName] then
		--Is already in backpack so can get stackspace
		spaceLeft = Self:StackSpace(ItemInfo.ItemName, StorageDescriptor)
		--else spaceLeft is 0 because no stack made yet
	end

	local stacksLeft: number = Self:StackSlotsLeft(StorageDescriptor)
	local maxCount: number = (stacksLeft * ItemInfo.ItemStack) + spaceLeft
	return maxCount
end

--[[
Determines the max amount of the item that can be added to a storages inventory
	given the storages current inventory
	@param ItemName (string) name of the item
	does not need to be in backpack but must have an info mod script
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
	@return (number) max amount possible to be put into storage or -1 on error
--]]
function StorageHandler:GetMaxAdd(ItemName: string, StorageDescriptor: number): number
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to GetMaxAdd from storage descriptor that is not valid")
        return -1
    end
	local itemInfo: {[string]: any} = itemUtilities:GetItemInfo(ItemName)
	if not itemInfo then
        warn('Attempt to GetMaxAdd for item "' .. ItemName .. '" but item not listed in item directory')
		return -1
	end
	--Determine what factor provides the least amount of the item and return that value
	return CheckMaxByStack(itemInfo, self, StorageDescriptor)
end



--[[
Returns a table of strings of all items in a storage device
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @return ({string}?) table of strings that are the names of the items in a storage inventory or nil if error
    or if there is no items
--]]
function StorageHandler:SeekStorageContents(StorageDescriptor: number) : {string}?
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to SeekStorageContents from storage descriptor that is not valid")
        return nil
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
    local invenCount: number = 0
    local contents: {string} = {}

    for itemName, _ in pairs(inventory) do
        table.insert(contents, itemName)
        invenCount = invenCount + 1
    end

    if invenCount ==  0 then
        --No items in inventory
        return nil
    end
    
    return contents
end

--[[
Gets the type of a given item in the storage inventory
    @param ItemName (string) name of the item
	does not need to be in backpack but must have an info mod script
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
    @return (string?) the name of the item type or nil otherwise
--]]
function StorageHandler:GetItemType(ItemName: string, StorageDescriptor: number) : string?
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to SeekStorageContents from storage descriptor that is not valid")
        return nil
    end
    local inventory: {[string]: {[string]: any}} = GetInventory(StorageDescriptor)
    local item: {[string]: any} = inventory[ItemName]
    if not item then
        warn('Item "' .. ItemName .. '" not in storage when checking item type')
        return nil
    end
    return item.ItemType
end

--[[
Initializes a storage device and returns its Storage Descriptor
    @param StorageConfig ({{string}}?) table of keys that hold a table of strings allwoed fro that ItemType
    setting the value to string "AllItems" for an ItemType indicates all items are allwoed for
    that item type. Not including a StorageConfig table indicates that all items are allowed
    Example:
    StorageConfig = {
        MaxStack = 10,
        ItemsConfig = {
            Food = {"Bread", "Rice"},
            Drink = {"Water"},
            Tool = {"AllItems"}
        }
    } 
    @param StorageDevice (Instance) any instance representing the storage device
    @return (number) the storageDescriptor for access
--]]
function StorageHandler:AddStorageDevice(StorageConfig: {{string}}?, StorageDevice: Instance) : number
    storageMutex:Lock()
    local curDescriptor: number = storageDescriptor
    local storageValue: {[string]: any} = {
        Config = StorageConfig,
        Device = StorageDevice,
        Inventory = {} --Table of contents of this device
    }
    storageTable[curDescriptor] = storageValue
    storageDescriptor = storageDescriptor + 1
    storageMutex:Unlock()
    return curDescriptor
end

--[[
Removes a given storage device
    @param StorageDescriptor (number) the storage descriptor number of the desired storage device
--]]
function StorageHandler:RemoveStorageDevice(StorageDescriptor) : ()
    if not self:ValidDescriptor(StorageDescriptor) then
        warn("Attempted to remove storage device from storage descriptor that is not valid")
        return
    end
    --Remove storage device from table
    storageTable[StorageDescriptor] = nil
end

--[[
Used to find the storage descriptor associated with a given instance (StorageDevice)
    @param Instance (Instance) any given instance that was binded to a StorageDescriptor during its init
    @return (number) the StorageDescriptor or -1 on failed
--]]
function StorageHandler:FindStorageByInstance(Instance: Instance) : number
    for storageDescriptor, storage in pairs(storageTable) do
        local device: Instance = storage.Device
        if device == Instance then
            --Found storage descriptor
            return storageDescriptor
        end
    end
    return -1--Failed to find an instance with the descriptor
end

--[[
Used to load in a previously saved storage device
--]]
function StorageHandler:LoadStorageDevice()
    
end

--[[
Exports the data of a storage device for saving
    should only be used for saving to a datastore
--]]
function StorageHandler:ExportStorageDevice()
    
end

return StorageHandler


