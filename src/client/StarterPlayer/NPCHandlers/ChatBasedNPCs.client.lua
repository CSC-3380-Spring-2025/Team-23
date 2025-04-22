local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local NPCDialogueObject = require(ReplicatedStorage.Shared.NPC.NPCDialogue)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BuyMinerEvent = BridgeNet2.ReferenceBridge("BuyMiner")

--NPC Adviser is the go to NPC for creating and handling NPCs
local adviserRig = Workspace:WaitForChild("ChatBasedNPCs"):WaitForChild("NPC Adviser")
local npcAdviser = NPCDialogueObject.new("NPC Adviser", adviserRig)

npcAdviser:InsertMenu("ManageMiningGuild", "Very well, what will it be today?")
local function _BuyMiner()
    local args = {
        ItemWhitelist = {"Coal", "Iron"}
    }
    BuyMinerEvent:Fire(args)
end
npcAdviser:InsertOption("ManageMiningGuild", "Buy Miner", _BuyMiner, 1)

--Root menu that is first opened for the adviser
npcAdviser:InsertMenu("HomeMenu", "Greetings, your majesty! What is your desire?")
local function _MiningGuildOpt()
    npcAdviser:TransitionDialogue("ManageMiningGuild")
end
npcAdviser:InsertOption("HomeMenu", "I wish to manage my mining guild!", _MiningGuildOpt, 1)
npcAdviser:SetHomeMenu("HomeMenu")

