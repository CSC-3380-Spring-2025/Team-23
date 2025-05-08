local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local NPCDialogue = require(ReplicatedStorage.Shared.NPC.NPCDialogue)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

--Events
local dataEvents: Folder = ReplicatedStorage.Events.DataEvents
local GetGoldStat: RemoteFunction = dataEvents:WaitForChild("GetGold") :: RemoteFunction
local BuyNPCEvent = BridgeNet2.ReferenceBridge("BuyNPC")

local NPCs = Workspace:WaitForChild("DialogueNPCs")
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