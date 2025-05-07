local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BuyMinerEvent = BridgeNet2.ReferenceBridge("BuyMiner")
local MinerNPCObject = require(ServerScriptService.Server.NPC.ResourceNPC.MinerNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local StorageHandlerObject = require(ServerScriptService.Server.ItemHandlers.StorageHandler)

--Events
local NPCEvents = ReplicatedStorage.Events.NPCEvents
local GetWhitelistedStorage = NPCEvents:WaitForChild("GetWhitelistedStorage")
local TraverseNPCs = BridgeNet2.ReferenceBridge("TraverseNPCs")
local MinerNPCsCollect = BridgeNet2.ReferenceBridge("MinerNPCsCollect")
local NPCSetwaypoint = BridgeNet2.ReferenceBridge("NPCSetwaypoint")
local NPCTraverseWaypoints = BridgeNet2.ReferenceBridge("NPCTraverseWaypoints")
local HarvestNearestResource = BridgeNet2.ReferenceBridge("HarvestNearestResource")
local AssignStorage = BridgeNet2.ReferenceBridge("NPCAssignStorage")
local StartAutoHarvest = BridgeNet2.ReferenceBridge("NPCStartAutoHarvest")

--Instances
local storageHandler: ExtType.ObjectInstance = StorageHandlerObject.new("NPCEventsStorageHandler")
local NPCHandler: ExtType.ObjectInstance = NPCHandlerObject.new("NPCHandlerEvents")

--Rigs
local rigs = ServerStorage.NPC.Rigs
local minerNPCRig = rigs.MinerNPC


BuyMinerEvent:Connect(function(Player, Args)
	local playerID = Player.UserId
	--Attempt to remove money to "purchase"
	--Make NPC and add it to the NPC Pool
	local nameNPC = Player.Name .. "'s Miner"
    local spawnPos = Vector3.new(0, 10, 0)
	local newMiner = MinerNPCObject.new(
		nameNPC,
		minerNPCRig,
		100,
		spawnPos,
		16,
		10,
		100,
		70,
		100,
		Args.ItemWhitelist,
		nil,
		nil,
		{"Coal", "Iron"},
		true,
		nil
	)
    --Store NPC to players pool
    NPCHandler:AddNPCToPlayerPool(newMiner, playerID)
end)

NPCSetwaypoint:Connect(function(Player, Args)
	local NPCharacter = Args.Character
	local waypoint =  Args.Waypoint
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:SetWaypoint(waypoint)
end)

NPCTraverseWaypoints:Connect(function(Player, NPCharacter)
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:TraverseWaypoints()
end)



TraverseNPCs:Connect(function(Player, Args)
	local NPCs = Args.NPCs
	local waypoints = Args.Waypoints
	local realNPCs = {}
	for _, character in pairs(NPCs) do
		table.insert(realNPCs, NPCHandler:GetPlayerNPCByCharacter(character, Player.UserId))
	end

	for _, NPCInstance in pairs(realNPCs) do
		NPCInstance:CancelWaypoints()
	end

	for _, NPCInstance in pairs(realNPCs) do
		for _, waypoint in pairs(waypoints) do
			NPCInstance:SetLinkedWaypoint(waypoint)
		end
	end

	for _, NPCInstance in pairs(realNPCs) do
		NPCInstance:TraverseWaypoints()
	end
end)

--[[
Event that handles handles a reqst for a MinerNPC to harvest an Ore
--]]
MinerNPCsCollect:Connect(function(Player, Args)
	local minerNPCs = Args.MinerNPCs
	local resourceTarget = Args.Resource
	local realNPCs = {}
	for _, character in pairs(minerNPCs) do
		table.insert(realNPCs, NPCHandler:GetPlayerNPCByCharacter(character, Player.UserId))
	end

	for _, NPCInstance in pairs(realNPCs) do
		NPCInstance:CancelWaypoints()
	end

	for _, NPCInstance in pairs(realNPCs) do
		NPCInstance:HarvestResource(resourceTarget)
	end
end)

--Handle resource NPC requests below

--[[
Event for making an NPC collect the nearest resource
Assumes that the NPC is a ResourceNPC
--]]
HarvestNearestResource:Connect(function(Player, NPCharacter)
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:HarvestNearestResource()
end)

--[[
Returns a number key dictionary where the key is the storageDescriptor and the value is its whitelisted storage instance
	@return ({[number]: Instance}?) the dictionary on success or nil otherwise
--]]
GetWhitelistedStorage.OnServerInvoke =  function(Player: Player, NPCharacter) :  {[number]: Instance}?
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	local resourceWhitelist = NPCInstance:GetResourceWhitelist()
	if resourceWhitelist == nil then
		return nil--No whitelist set
	end
	local playersStorage: {number}? = storageHandler:GetPlayersStorageDevices(Player.UserId)
	if playersStorage == nil then
		return nil--No storage found for player
	end
	--Loop through all storage and check if any of the NPCs whitelisted items are valid
	local validStorages: {number} = {}
	for _, descriptor in pairs(playersStorage) do
		for _, listedName in pairs(resourceWhitelist) do
			if storageHandler:IsValidItem(descriptor, listedName) then
				 table.insert(validStorages, descriptor)--Valid storage to set for NPC
			end
		end
	end

	if #validStorages == 0 then
		--No storage descriptors whitelisted
		return nil
	end

	--Loop through descriptors and get their instances to return
	local storageInstancesDict: {[number]: Instance} = {}
	for _, descriptor in pairs(validStorages) do
		local storageInstance: Instance = storageHandler:GetInstanceFromDescriptor(descriptor) :: Instance
		storageInstancesDict[descriptor] = storageInstance
	end
	return storageInstancesDict
end

--[[
Assigns a storage device to a given resource NPC
--]]
AssignStorage:Connect(function(Player, Args)
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(Args.Character, Player.UserId)
	NPCInstance:AssignStorage(Args.StorageDevice)
end)

StartAutoHarvest:Connect(function(Player, NPCharacter)
	local NPCInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:AutoHarvest()
end)
