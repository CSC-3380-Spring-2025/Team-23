local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local rigsFolder = ServerStorage.NPC.Rigs
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local NPCHandler = NPCHandlerObject.new("NPCHandler Test")
--]]


Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		CollectionService:AddTag(character, "Player")
	end)
end)
--[[
--Swordsman
local SwordsmanObject = require(ServerScriptService.Server.NPC.CombatNPC.SwordsmanNPC)
local swordManNPC1 = SwordsmanObject.new(
	"Proto swordsman",
	rigsFolder.DefaultNPC,
	100,
	Vector3.new(0, 10, 0),
	16,
	10,
	100,
	70,
	100,
	{ "Sword" },
	nil,
	nil,
	true,
	nil,
	{"Enemy"}
)
swordManNPC1:AddTag("OtherEnemy")
NPCHandler:AddNPCToServerPool(swordManNPC1)

local sword = ReplicatedStorage.ItemDrops.Sword
swordManNPC1:AddTool(sword, 1)
swordManNPC1:SelectWeapon("Sword")

enemySwordsman = SwordsmanObject.new(
	"Proto swordsman",
	rigsFolder.DefaultNPC,
	100,
	Vector3.new(20, 10, 0),
	16,
	10,
	100,
	70,
	100,
	{ "Sword" },
	nil,
	nil,
	true,
	nil,
	{"OtherEnemy"}
)
enemySwordsman:AddTag("Enemy")
task.wait(4)
NPCHandler:AddNPCToPlayerPool(enemySwordsman, 81328434)
enemySwordsman:AddTool(sword, 1)
enemySwordsman:SelectWeapon("Sword")

task.wait(10)
print("Init sentry mode!")
swordManNPC1:SetHomePoint(Vector3.new(0, 0, 0))
swordManNPC1:SentryMode(10, 15)
enemySwordsman:SetHomePoint(Vector3.new(0, 0, 0))
enemySwordsman:SentryMode(10, 15)
--]]