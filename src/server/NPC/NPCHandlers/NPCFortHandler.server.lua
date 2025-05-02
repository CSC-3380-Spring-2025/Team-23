--[[
This script handles all barbarian forts
--]]
--Services
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Requires
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local SwordsmanObject = require(ServerScriptService.Server.NPC.CombatNPC.SwordsmanNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
--Instances
local NPCHandler: ExtType.ObjectInstance = NPCHandlerObject.new("NPCHandler Test")

--Rigs needed
local rigsFolder: Folder = ServerStorage.NPC.Rigs
local swordsmanRig: Model? = rigsFolder:FindFirstChild("SwordsmanNPC") :: Model?

--Vars
local barbarianEnemies: { string } = { "PlayerNPC", "Player" } --List of enemy tags barbarians aggro
local lootModels: Folder = ServerStorage.LootModels

--[[
Returns a randomized child of the given parent
    @param Parent (Instance) any instance that has children
    @return (Instance?) a random child of the parent or nil if non found
--]]
local function RandomItem(Parent: Instance): Instance?
	local children: { Instance } = Parent:GetChildren()
	if #children == 0 then
		return nil --No children
	end
	local randmInd: number = math.random(1, #children)
	return children[randmInd]
end

--[[
Finds a point from a folder of IdlePoints that is not yet reserved
    @param IdlePoints (Folder) the folder of IdlePoints
    @return (Basepart?) returns a idle point object if availible or nil if non found
--]]
local function FindOpenIdlePoint(IdlePoints: Folder): BasePart?
	--Find unused IdlePoint
	for _, point in pairs(IdlePoints:GetChildren()) do
		local reserved: boolean? = point:GetAttribute("Reserved") :: boolean?
		if not reserved then
			point:SetAttribute("Reserved", true)
			return point
		end
	end
	return nil
end

--[[
Gives the given barbarian NPC the EnemyNPC tag
	@param NPCInstance (ExtType.ObjectInstance) the instance fo the barbarian NPC
--]]
local function MakeEnemy(NPCInstance: ExtType.ObjectInstance) : ()
	NPCInstance:AddTag("EnemyNPC")
end

--[[
Spawns a swordsman instance for the barbarian fort
    @param Spawn (BasePart) the basepart acting as a spawn
    @param NPCName (string) the name of the NPC
    @param IdlePoint (BasePart) any part acting as an idlepoint
    @param FortNPCs ({ { [any]: any } }) the table of the forts NPCs
--]]
local function SpawnSwordsman(
	Spawn: BasePart,
	NPCName: string,
	IdlePoint: BasePart,
	FortNPCs: { { [any]: any } }
): { [any]: any }
	local sword: Tool = ReplicatedStorage.ItemDrops.Sword
	local spawnPos: Vector3 = Spawn.Position
	local newSwordsman: { [any]: any } = SwordsmanObject.new(
		NPCName,
		swordsmanRig :: Model,
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
	MakeEnemy(newSwordsman)
	return newSwordsman
end

--[[
Makes a deep copy clone of any given Model
	Copys both tags and attributes
	@param (LootModel) any model from the LootModel folder
	@return (Model) returns a full copy o the origional model
--]]
local function DeepCopyLoot(LootModel: Model) : Model
	local clone: Model = LootModel:Clone()
	for _, attributeName in pairs(LootModel:GetAttributes()) do
		clone:SetAttribute(attributeName, LootModel:GetAttribute(attributeName))
	end
	for _, tag in pairs(CollectionService:GetTags(LootModel)) do
		CollectionService:AddTag(clone, tag)
	end
	return clone
end

--[[
Handles what happens when a barbarian fort is finished and destroyed
--]]
local function SpawnLoot(Fort: Model)
	local lootSpawns: Folder? = Fort:FindFirstChild("LootSpawns", true) :: Folder?
	if lootSpawns == nil then
		Fort:Destroy()--No loot set
		return
	end
	local lootFolder: Folder = Instance.new("Folder")
	lootFolder.Parent = Fort.Parent
	lootFolder.Name = "LootOf" .. Fort.Name
	--Spawn all loot
	for _, spawn in pairs(lootSpawns:GetChildren()) do
		local lootModel: Model? = lootModels:FindFirstChild(spawn.Name, true) :: Model?
		if lootModel == nil then
			warn("LootSpawn point set for fort but no such model by name in LootModels folder in ServerStorage")
			continue
		end
		local lootModelClone: Model = DeepCopyLoot(lootModel)
		local lootPos: CFrame = spawn.CFrame
		lootModelClone:PivotTo(lootPos)
		lootModelClone.Parent = lootFolder
	end
	Fort:Destroy()
end

--[[
Spawns a swordsman instance for the barbarian fort
    @param Spawn (BasePart) the basepart acting as a spawn
    @param NPCName (string) the name of the NPC
    @param IdlePoints (Folder) folder holding the IdlePoint baseparts
    @param BarbarianType (string) the type of barbarian that died
    @param Fort (Model) the fort model
    @param FortNPCs ({ { [any]: any } }) the table of the forts NPCs
--]]
local function BarbarianDeathHandler(
	Spawn: BasePart,
	NPCName: string,
	IdlePoints: Folder,
	BarbarianType: string,
	Fort: Model?,
	FortNPCs: { { [any]: any } },
	NPCsFolder: Folder
): ()
	--Check if forts NPCs is empty and if so then stop process and destroy building
	if #FortNPCs == 0 then
		if Fort then
			SpawnLoot(Fort)
		end
		return --Fort is destroyed so return
	end
	--Replace NPC
	--Find availible idlePoint
	local idlePoint: BasePart? = FindOpenIdlePoint(IdlePoints)
	--Choose correct type
	if BarbarianType == "Swordsman" then
		task.wait(15) --Cooldown before spawn
		--Check if only NPC just in case other NPCs died during cooldown
		if #FortNPCs == 0 or not idlePoint then
			return
		end
		local newSwordsman: { [any]: any } = SpawnSwordsman(Spawn, NPCName, idlePoint, FortNPCs)
		newSwordsman:SetParent(NPCsFolder)
		--Handle next death
		local hasDiedConnect: RBXScriptConnection
		hasDiedConnect = newSwordsman.HasDied:Connect(function()
			hasDiedConnect:Disconnect()
			print("Fort was told that NPC has died!")
			table.remove(FortNPCs, table.find(FortNPCs, newSwordsman))
			BarbarianDeathHandler(Spawn, NPCName, IdlePoints, "Swordsman", Fort, FortNPCs, NPCsFolder)
		end)
	else
		warn("BarbarianDeathHandler called but BarbarianType does not exist for: " .. BarbarianType)
	end
end

--[[
Handles what happens when an NPC dies
    @param BarbarianNPC ({ [any]: any }) the barbarin NPCs instance
	@param FortNPCs ({ { [any]: any } }) the table of the forts NPC instances
	@param BarbarianName (string) the name of the NPC
	@param IdlePoints (Folder) the folder of the forts IdlePoints
	@param Fort (Model) the Fort model
	@param FortNPCsFolder (Folder) the forts NPCs folder
	@param Spawn (BasePart) the spawn part of the Fort
--]]
local function DeathHandlerEvent(
	BarbarianNPC: { [any]: any },
	FortNPCs: { { [any]: any } },
	BarbarianName: string,
	IdlePoints: Folder,
	Fort: Model,
	FortNPCsFolder: Folder,
	Spawn: BasePart
) : ()
	local hasDiedConnect: RBXScriptConnection
	hasDiedConnect = BarbarianNPC.HasDied:Connect(function()
		hasDiedConnect:Disconnect()
		table.remove(FortNPCs, table.find(FortNPCs, BarbarianNPC))
		BarbarianDeathHandler(Spawn, BarbarianName, IdlePoints, "Swordsman", Fort, FortNPCs, FortNPCsFolder)
	end)
end

--[[
Determines what happens when a fort is spawned
    @param Fort (Model) the model of the fort added
--]]
local function FortHandler(Fort: Model)
	local fortNPCs: { { [any]: any } } = {}
	--For each type of listed NPC spawn and given enough time for NPC to move away.
	--Give fort some time to load in
	task.wait(5)
	local spawns: Folder? = Fort:FindFirstChild("Spawns") :: Folder?
	if not spawns then
		warn("Spawns folder and parts net set for fort")
		return
	end
	local idlePoints: Folder? = Fort:FindFirstChild("IdlePoints") :: Folder?
	if not spawns then
		warn("IdlePoints folder and parts net set for fort")
		return
	end

	local fortNPCsFolder: Folder = Instance.new("Folder", Fort)
	fortNPCsFolder.Name = "NPCs"

	local swordsmanCount: number = Fort:GetAttribute("SwordsmanCount") :: number
	if swordsmanCount then
		--Spawn all swordsman
		for i = 1, swordsmanCount do
			local spawn: BasePart? = RandomItem(spawns) :: BasePart?
			local idlePoint: BasePart? = FindOpenIdlePoint(idlePoints :: Folder)
			if not idlePoint then
				break --No availible idle points
			end
			local swordsmanName: string = "Barbarian Swordsman " .. i
			local newSwordsman: { [any]: any } = SpawnSwordsman(spawn :: BasePart, swordsmanName, idlePoint, fortNPCs)
			newSwordsman:SetParent(fortNPCsFolder)
			--Handle death
			DeathHandlerEvent(newSwordsman, fortNPCs, swordsmanName, idlePoints :: Folder, Fort, fortNPCsFolder, spawn :: BasePart)
			task.wait(5)
		end
	end
end

task.wait(10) --Wait for forts to load in
--Handle all forts
for _, fort in pairs(CollectionService:GetTagged("BarbarianFort")) do
	task.spawn(function()
		FortHandler(fort)
	end)
end

--Handle all forts that get added
CollectionService:GetInstanceAddedSignal("BarbarianFort"):Connect(function(Fort)
	FortHandler(Fort)
end)
