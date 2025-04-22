local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BuyMinerEvent = BridgeNet2.ReferenceBridge("BuyMiner")
local MinerNPCObject = require(ServerScriptService.Server.NPC.ResourceNPC.MinerNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local NPCHandler = NPCHandlerObject.new("NPCHandlerEvents")
local TraverseNPCs = BridgeNet2.ReferenceBridge("TraverseNPCs")
local CollectNPCs = BridgeNet2.ReferenceBridge("CollectNPCs")

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

CollectNPCs:Connect(function(Player, Args)
	local NPCs = Args.NPCs
	local resourceTarget = Args.Resource
	local realNPCs = {}
	for _, character in pairs(NPCs) do
		if character:GetAttribute("Type") == "Pickaxe" then
			--Is pickaxe NPC
			table.insert(realNPCs, NPCHandler:GetPlayerNPCByCharacter(character, Player.UserId))
		end
	end

	for _, NPCInstance in pairs(realNPCs) do
		NPCInstance:CancelWaypoints()
	end

	for _, NPCInstance in pairs(realNPCs) do
		--Check if resource type
		NPCInstance:HarvestResource(resourceTarget)
	end
end)
