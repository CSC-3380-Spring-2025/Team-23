local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MerchantNPC = require(ReplicatedStorage.Shared.NPC.MerchantNPC)
local Workspace = game:GetService("Workspace")
local NPC = Workspace:WaitForChild("NPC")
--print(ServerScriptService)
local Player = game:GetService("Players")
local Player1 = Player.LocalPlayer

local NPC1 = MerchantNPC.new("Dialogue", NPC)

NPC1:InsertMenu("Test 2", "Headline")
NPC1:InsertMenu("Test 1", "Headline")

local function transitionDuck()
    NPC1:TransitionDialogue("Test 1")
end

local function printer()
    print("That")
end



NPC1:InsertOption("Test 1", "Second Option", printer, 1)
NPC1:InsertOption("Test 2", "Third Option", transitionDuck, 2)
NPC1:InsertSellOption("Coal", 1)


NPC1:SetHomeMenu("Test 2")
task.wait(15)
--NPC1:DestroyInstance()

--print(NPC1)
