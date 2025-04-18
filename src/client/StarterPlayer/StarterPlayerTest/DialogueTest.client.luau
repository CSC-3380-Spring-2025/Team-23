local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCDialogue = require(ReplicatedStorage.Shared.NPC.NPCDialogue)
local Workspace = game:GetService("Workspace")
local NPC = Workspace:WaitForChild("NPC")

--[[

--Create the object NPCDialogue as be

local NPC1 = NPCDialogue.new("Dialogue", NPC)

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

NPC1:SetHomeMenu("Test 2")
task.wait(30)

NPC1:DestroyInstance()

print(NPC1)

--]]
