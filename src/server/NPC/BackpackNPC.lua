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
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local NPC = require(ServerScriptService.Server.NPC.NPC)
local BackpackNPC = {}
NPC:Supersedes(BackpackNPC)

--[[
Constructor for the BackpackNPC class
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
--]]
function BackpackNPC.new(Name: string, Rig: Model, Health: number, SpawnPos: Vector3, 
    Speed: number, MaxWeight: number, MediumWeight: number, HeavyWeight: number, Backpack: {}?)
    local self = NPC.new(Name, Rig, Health, SpawnPos, Speed)
    setmetatable(self, BackpackNPC)
    self.__Backpack = Backpack or {}
    self.__MaxWeight = MaxWeight or 100
    self.__MediumWeight = MediumWeight or 70 --Weight at wich below you are light, but above you are medium
    self.__HeavyWeight = HeavyWeight or 100 --weight at wich you become heavy
    return self
end

--[[
Puts a given item and its amount in the NPC's backpack
    @param ItemName (string) the name of the item
    @param Amount (number) the number of the item to add to the player
--]]
function BackpackNPC:CollectItem(ItemName: string, Amount: number) : boolean
    AbstractInterface:AbstractError("CollectItem", "BackpackNPC")
    return false
end

--[[
Checks if a given item is valid to be added to the NPC
    @param ItemName (string) the name of the item to check for
    @return (boolean) true on valid or false otherwise
--]]
function BackpackNPC:ValidItemCollection(ItemName: string) : boolean
    AbstractInterface:AbstractError("ValidItemCollection", "BackpackNPC")
    return false
end

--[[
Drops a given item given its amount
    @param ItemName (string) the name of the item to remove
    @param Amount (number) the amount of item to remove
--]]
function BackpackNPC:DropItem(ItemName: string, Amount: number) : ()
    AbstractInterface:AbstractError("DropItem", "BackpackNPC")
end

--[[
Drops all items in a NPC's backpack
--]]
function BackpackNPC:DropAllItems() : ()
    AbstractInterface:AbstractError("DropAllItems", "BackpackNPC")
end

--[[
Deletes an item in an NPC's inventory for a given amount
    @param ItemName the name of the item to delete
    @param Amount the amount of that item to delete
--]]
function BackpackNPC:RemoveItem(ItemName: string, Amount: number) : ()
    for key, item in pairs(self.__Backpack) do
        if key == ItemName then
            item.Count = item.Count - Amount
            if item.Count < 0 or item.Count == 0 then
                --Remove item from backpack because 0 or less
                item = nil
            end
        end
    end
    warn("\"" .. ItemName .. "\" not found in backpack of NPC \"" .. self.Name .. "\" when attempting to remove item")
end

--[[
Deletes all items from a NPC's backpack
--]]
function BackpackNPC:RemoveAllItems() : ()
    self.__Backpack = {} --Empty backpack table
end

--[[
Transfers a given item from an NPC to some form of storage
    @param ItemName (string) the name of the item to transfer
    @param Amount (number) the amount of the item to transfer to storage
    @param StorageDevice (any) any form of storage device that can take an item
    @return (boolean) true on success or false otherwise
--]]
function BackpackNPC:TransferItemToStorage(ItemName: string, Amount: number, StorageDevice: any) : boolean
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
function BackpackNPC:TransferItemToPlayer(ItemName: string, Amount: number, Player: Player) : boolean
    AbstractInterface:AbstractError("TransferItemToPlayer", "BackpackNPC")
    return false
end

--[[
Checks for a given item in a NPC's backpack
@param ItemName (string) the name of the item to check for
@return (boolean) true if in backpack or false otherwise
--]]
function BackpackNPC:CheckForItem(ItemName: string) : boolean
    for key, value in pairs(self.__Backpack) do
        if key == ItemName then
            --item is present in backpack so return count and weight of item
            return true
        end
    end
    return false --item not found in backpack
end

--[[
Checks for a given item and returns the count of that item
@param ItemName (string) the name of the item to check for
@return (number) count of item if found or -1 otherwise
--]]
function BackpackNPC:GetItemCount(ItemName: string) : number
    for key, value in pairs(self.__Backpack) do
        if key == ItemName then
            --item is present in backpack so return count and weight of item
            return value.Count
        end
    end
    return -1 --item not found in backpack
end

--[[
Checks for a given item and returns the count of that item
@param ItemName (string) the name of the item to check for
@return (number) count of item if found or -1 otherwise
--]]
function BackpackNPC:GetItemWeight(ItemName: string) : number
    for key, value in pairs(self.__Backpack) do
        if key == ItemName then
            --item is present in backpack so return count and weight of item
            return value.Weight
        end
    end
    return -1 --item not found in backpack
end

--[[
Checks the numerical value of the weight of the NPC
@return (number) the NPC's current weight
--]]
function BackpackNPC:CheckNPCWeight() : number
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
function BackpackNPC:CheckEncumberment() : string
    local weight = self:CheckNPCWeight()
    if weight < self.__Medium then
        return "Light"
    elseif weight >= self.__Medium and weight < self.__Heavy then
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
function BackpackNPC:CheckItemType(ItemName: string) : string?
    for key, value in pairs(self.__Backpack) do
        if key == ItemName then
            --item is present in backpack so return count and weight of item
            return value.ItemType
        end
    end
    return nil
end

--[[
Returns the real item of the ItemName if in backpack
    @param ItemName (string) the name of the item to get from backpack
    @return (any) the item with the item name on success or nil otherwise
--]]
function BackpackNPC:GetItem(ItemName) : any
    for key, value in pairs(self.__Backpack) do
        if key == ItemName then
            --item is present in backpack so return count and weight of item
            return value.Item
        end
    end
    return nil
end

return BackpackNPC