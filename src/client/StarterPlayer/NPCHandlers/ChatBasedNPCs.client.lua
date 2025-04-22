local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local NPCDialogueObject = require(ReplicatedStorage.Shared.NPC.NPCDialogue)

--NPC Adviser is the go to NPC for creating and handling NPCs
local adviserRig = Workspace:WaitForChild("ChatBasedNPCs"):WaitForChild("NPC Adviser")
local npcAdviser = NPCDialogueObject.new("NPC Adviser", adviserRig)

npcAdviser:InsertMenu("ManageMiningGuild", "Very well, what will it be today?")
--npcAdviser:InsertOption()

--Root menu that is first opened for the adviser
npcAdviser:InsertMenu("HomeMenu", "Greetings, your majesty! What is your desire?")
local function _miningGuildOpt()
    npcAdviser:TransitionDialogue("ManageMiningGuild")
end
npcAdviser:InsertOption("HomeMenu", "I wish to manage my mining guild!", _miningGuildOpt, 1)
npcAdviser:SetHomeMenu("HomeMenu")

