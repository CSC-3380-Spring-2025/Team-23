local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local rigsFolder = ServerStorage.NPC.Rigs
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local NPCHandler = NPCHandlerObject.new("NPCHandler Test")
--]]

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
	{ "Sword" }
)
local sword = ReplicatedStorage.ItemDrops.Sword
swordManNPC1:AddTool(sword, 1)
swordManNPC1:SelectWeapon("Sword")
task.wait(4)
for i=1, 5, 1 do
	print("Attack started")
	swordManNPC1:Attack()
	print("Attack ended")
end
