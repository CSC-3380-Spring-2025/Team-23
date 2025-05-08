local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local NPCDialogue = require(ReplicatedStorage.Shared.NPC.NPCDialogue)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local ItemUtils = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

--Instances
local myItemUtils = ItemUtils.new("ItemUtils")

--Events
local dataEvents: Folder = ReplicatedStorage.Events.DataEvents
local GetGoldStat: RemoteFunction = dataEvents:WaitForChild("GetGold") :: RemoteFunction
local BuyNPCEvent = BridgeNet2.ReferenceBridge("BuyNPC")
local events = ReplicatedStorage.Events
local backpackEvents = events.BackpackEvents
local GetCount = backpackEvents:WaitForChild("GetCount")
local MerchantPurchase = BridgeNet2.ReferenceBridge("MerchantPurchase")

local NPCs = Workspace:WaitForChild("DialogueNPCs")
local merchantRig = NPCs:WaitForChild("Merchant")
local NPCAdviserRig = NPCs:WaitForChild("NPC Adviser")
local adviserRootPart = NPCAdviserRig:WaitForChild("HumanoidRootPart")
local spawnPosition = adviserRootPart.Position

local function GetGold() : number
    return GetGoldStat:InvokeServer()
end

local function CanBuy(Price) : boolean
    local curGold = GetGold()
    if (Price - curGold) <= 0 then
        return true
    else
        return false
    end
end

local function PurchaseNPC(Name, Price)
    local args = {
        NPCName = Name,
        Price = Price,
        SpawnPos = spawnPosition
    }
    BuyNPCEvent:Fire(args)
end

local NPCAdviser = NPCDialogue.new("NPC Adviser", NPCAdviserRig)
NPCAdviser:InsertMenu("HomeMenu", "Welcome, Sire!")

--Miner option
local function BuyMiner()
    local price = 50
    if CanBuy(price) then
        --Give NPC to player and remvoe money
        PurchaseNPC("MinerNPC", price)
    end
end
NPCAdviser:InsertOption("HomeMenu", "Buy Miner: 500 Gold", BuyMiner, 1)

--Swordsman Option
local function BuySwordsman()
    local price = 50
    if CanBuy(price) then
        --Give NPC to player and remvoe money
        PurchaseNPC("SwordsmanNPC", price)
    end
end
NPCAdviser:InsertOption("HomeMenu", "Buy Swordsman: 500 Gold", BuySwordsman, 1)

NPCAdviser:SetHomeMenu("HomeMenu")

--Begin Merchant
local merchant = NPCDialogue.new("Merchant", merchantRig)
merchant:InsertMenu("HomeMenu", "Welcome, Sire!")

local function GetCountItem(ItemName)
    return GetCount:InvokeServer(ItemName)
end

local function GetItemInfo(ItemName)
    return myItemUtils:GetItemInfo(ItemName)
end

local function Lumber()
    local itemCount = GetCountItem("Lumber")
    local itemInfo = GetItemInfo("Lumber")
    local args = {
        Amount = itemCount,
        Price = itemInfo.Price,
        Resource = "Lumber"
    }
    MerchantPurchase:Fire(args)
end

local function Iron()
    local itemCount = GetCountItem("Iron")
    local itemInfo = GetItemInfo("Iron")
    local args = {
        Amount = itemCount,
        Price = itemInfo.Price,
        Resource = "Iron"
    }
    MerchantPurchase:Fire(args)
end

local function Coal()
    local itemCount = GetCountItem("Coal")
    local itemInfo = GetItemInfo("Coal")
    local args = {
        Amount = itemCount,
        Price = itemInfo.Price,
        Resource = "Coal"
    }
    MerchantPurchase:Fire(args)
end

merchant:InsertOption("HomeMenu", "Sell Lumber", Lumber, 1)
merchant:InsertOption("HomeMenu", "Sell Iron", Iron, 1)
merchant:InsertOption("HomeMenu", "Sell Coal", Coal, 1)
merchant:SetHomeMenu("HomeMenu")


