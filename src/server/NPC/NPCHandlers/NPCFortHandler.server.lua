--[[
This script handles all barbarian forts
--]]
--Services
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Requires
local SwordsmanObject = require(ServerScriptService.Server.NPC.CombatNPC.SwordsmanNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
--Instances
local NPCHandler = NPCHandlerObject.new("NPCHandler Test")

--Rigs needed
local rigsFolder = ServerStorage.NPC.Rigs
local swordsmanRig = rigsFolder:FindFirstChild("SwordsmanNPC")

--Vars
local barbarianEnemies = { "PlayerNPC", "Player" } --List of enemy tags barbarians aggro
local replacementCooldown = 5 --The amount of time in seconds that it takes for a NPC that has died to be replaced

--[[
Returns a randomized child of the given parent
    @param Parent (Instance) any instance that has children
    @return (Instance?) a random child of the parent or nil if non found
--]]
local function RandomItem(Parent: Instance): Instance?
	local children = Parent:GetChildren()
	if #children == 0 then
		return nil --No children
	end
	local randmInd = math.random(1, #children)
	return children[randmInd]
end

--[[
Finds a point from a folder of IdlePoints that is not yet reserved
    @param IdlePoints (Folder) the folder of IdlePoints
--]]
local function FindOpenIdlePoint(IdlePoints: Folder)
	--Find unused IdlePoint
	for _, point in pairs(IdlePoints:GetChildren()) do
		local reserved = point:GetAttribute("Reserved")
		if not reserved then
			point:SetAttribute("Reserved", true)
			return point
		end
	end
	return nil
end

--Spawns a swordsman instance for the barbarian fort
local function SpawnSwordsman(Spawn, NPCName, IdlePoint, FortNPCs)
	local sword = ReplicatedStorage.ItemDrops.Sword
	local spawnPos = Spawn.Position
	local newSwordsman = SwordsmanObject.new(
		NPCName,
		swordsmanRig,
		100,
		spawnPos,
		16,
		5,
		100,
		70,
		100,
		{ "Sword" },
		nil,
		nil,
		true,
		nil,
		barbarianEnemies
	)
	NPCHandler:AddNPCToServerPool(newSwordsman)
	table.insert(FortNPCs, newSwordsman)
	newSwordsman:AddTool(sword, 1)
	newSwordsman:SelectWeapon("Sword")
	newSwordsman:SetHomePoint(IdlePoint.Position)
	newSwordsman:ReturnHome()
	newSwordsman:SentryMode(15, 20)
	return newSwordsman
end

local function BarbarianDeathHandler(Spawn, NPCName, FortNPCs, IdlePoints, BarbarianType: string)
	--Replace NPC
	--Find availible idlePoint
	local idlePoint = FindOpenIdlePoint(IdlePoints)
	--Choose correct type
	if BarbarianType == "Swordsman" then
        task.wait(10)--Cooldown before spawn
		SpawnSwordsman(Spawn, NPCName, idlePoint, FortNPCs)
    else
        warn("BarbarianDeathHandler called but BarbarianType does not exist for: " .. BarbarianType)
	end
end

local function FortHandler(Fort)
	local fortNPCs = {}
	--For each type of listed NPC spawn and given enough time for NPC to move away.
	--Give fort some time to load in
	task.wait(10)
	local spawns: Folder = Fort:FindFirstChild("Spawns")
	if not spawns then
		warn("Spawns folder and parts net set for fort")
		return
	end
	local idlePoints = Fort:FindFirstChild("IdlePoints")
	if not spawns then
		warn("IdlePoints folder and parts net set for fort")
		return
	end

    local fortNPCsFolder = Instance.new("Folder", Fort)
    fortNPCsFolder.Name = "NPCs"

	local swordsmanCount: number = Fort:GetAttribute("SwordsmanCount") :: number
	if swordsmanCount then
		--Spawn all swordsman
		for i = 1, swordsmanCount do
			local spawn: Instance = RandomItem(spawns) :: Instance
			local idlePoint = FindOpenIdlePoint(idlePoints)
			if not idlePoint then
				break --No availible idle points
			end
			local swordsmanName = "Barbarian Swordsman " .. i
			local newSwordsman = SpawnSwordsman(spawn, swordsmanName, idlePoint, fortNPCs)
            newSwordsman:SetParent(fortNPCsFolder)
			--Handle death
			local hasDiedConnect
			hasDiedConnect = newSwordsman.HasDied:Connect(function()
				hasDiedConnect:Disconnect()
				print("Fort was told that NPC has died!")
				BarbarianDeathHandler(spawn, swordsmanName, fortNPCs, idlePoints, "Swordsman")
			end)
			task.wait(5)
		end
	end
end

task.wait(10) --Wait for forts to load in
for _, fort in pairs(CollectionService:GetTagged("BarbarianFort")) do
	task.spawn(function()
		FortHandler(fort)
	end)
end

CollectionService:GetInstanceAddedSignal("BarbarianFort"):Connect(function(Fort)
	FortHandler(Fort)
end)
