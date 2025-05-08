local ServerScriptService: ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local MinerNPCObject = require(ServerScriptService.Server.NPC.ResourceNPC.MinerNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local StorageHandlerObject = require(ServerScriptService.Server.ItemHandlers.StorageHandler)
local GoldObject = require(ServerScriptService.Server.Currency.Gold)
local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)
local NPCs = ServerScriptService.Server.NPC
local SwardsmanNPC = require(NPCs.CombatNPC.SwordsmanNPC)

--Events
local NPCEvents: Folder = ReplicatedStorage.Events.NPCEvents
local GetWhitelistedStorage: RemoteFunction = NPCEvents:WaitForChild("GetWhitelistedStorage") :: RemoteFunction
local TraverseNPCs: ExtType.Bridge = BridgeNet2.ReferenceBridge("TraverseNPCs")
local MinerNPCsCollect: ExtType.Bridge = BridgeNet2.ReferenceBridge("MinerNPCsCollect")
local NPCSetwaypoint: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCSetwaypoint")
local NPCTraverseWaypoints: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCTraverseWaypoints")
local HarvestNearestResource: ExtType.Bridge = BridgeNet2.ReferenceBridge("HarvestNearestResource")
local AssignStorage: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCAssignStorage")
local StartAutoHarvest: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCStartAutoHarvest")
local NPCCancelActions: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCCancelActions")
local NPCEmptyToStorage: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCEmptyToStorage")
local NPCAttack: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCAttack")
local NPCSentryMode: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCSentryMode")
local NPCCollectResource: ExtType.Bridge = BridgeNet2.ReferenceBridge("NPCCollectResource")
local BuyNPCEvent = BridgeNet2.ReferenceBridge("BuyNPC")
local MerchantPurchase = BridgeNet2.ReferenceBridge("MerchantPurchase")

--Instances
local storageHandler: ExtType.ObjectInstance = StorageHandlerObject.new("NPCEventsStorageHandler")
local NPCHandler: ExtType.ObjectInstance = NPCHandlerObject.new("NPCHandlerEvents")
local GoldHandler: ExtType.ObjectInstance = GoldObject.new("NPCEvents")

--Rigs
local rigs: Folder = ServerStorage.NPC.Rigs
local minerNPCRig: Model = rigs.DefaultNPC

NPCSetwaypoint:Connect(function(Player: Player, Args: ExtType.StrDict)
	local NPCharacter: Model = Args.Character
	local waypoint: Vector3 = Args.Waypoint
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:SetWaypoint(waypoint)
end)

NPCTraverseWaypoints:Connect(function(Player: Player, NPCharacter: Model)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:TraverseWaypoints()
end)

TraverseNPCs:Connect(function(Player: Player, Args: ExtType.StrDict)
	local NPCs: { Model } = Args.NPCs
	local waypoints: { Vector3 } = Args.Waypoints
	local realNPCs: ExtType.ObjectInstance = {}
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
	local minerNPCs: { Model } = Args.MinerNPCs
	local resourceTarget: BasePart = Args.Resource
	local realNPCs: ExtType.ObjectInstance = {}
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
HarvestNearestResource:Connect(function(Player: Player, NPCharacter: Model)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:HarvestNearestResource()
end)

--[[
Returns a number key dictionary where the key is the storageDescriptor and the value is its whitelisted storage instance
	@return ({[number]: Instance}?) the dictionary on success or nil otherwise
--]]
GetWhitelistedStorage.OnServerInvoke = function(Player: Player, NPCharacter): { [number]: Instance }?
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	local resourceWhitelist: { string } = NPCInstance:GetResourceWhitelist()
	if resourceWhitelist == nil then
		return nil --No whitelist set
	end
	local playersStorage: { number }? = storageHandler:GetPlayersStorageDevices(Player.UserId)
	if playersStorage == nil then
		return nil --No storage found for player
	end
	--Loop through all storage and check if any of the NPCs whitelisted items are valid
	local validStorages: { number } = {}
	for _, descriptor in pairs(playersStorage) do
		for _, listedName in pairs(resourceWhitelist) do
			if storageHandler:IsValidItem(descriptor, listedName) then
				table.insert(validStorages, descriptor) --Valid storage to set for NPC
			end
		end
	end

	if #validStorages == 0 then
		--No storage descriptors whitelisted
		return nil
	end

	--Loop through descriptors and get their instances to return
	local storageInstancesDict: { [number]: Instance } = {}
	for _, descriptor in pairs(validStorages) do
		local storageInstance: Instance = storageHandler:GetInstanceFromDescriptor(descriptor) :: Instance
		storageInstancesDict[descriptor] = storageInstance
	end
	return storageInstancesDict
end

--[[
Assigns a storage device to a given resource NPC
--]]
AssignStorage:Connect(function(Player: Player, Args: ExtType.StrDict)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(Args.Character, Player.UserId)
	NPCInstance:AssignStorage(Args.StorageDevice)
end)

StartAutoHarvest:Connect(function(Player: Player, NPCharacter: ExtType.StrDict)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:AutoHarvest()
end)

NPCCancelActions:Connect(function(Player: Player, NPCharacter: ExtType.StrDict)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:CancelActionTasks()
end)

NPCEmptyToStorage:Connect(function(Player: Player, Args: ExtType.StrDict)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(Args.Character, Player.UserId)
	NPCInstance:AssignStorage(Args.StorageDevice)
	NPCInstance:TraverseEmptyToStorage()
end)

NPCAttack:Connect(function(Player: Player, Args: ExtType.StrDict)
	local target = Args.Target
	local friendlyNPCs = Args.FriendlyNPCs
	--Loop through all friendly NPCs and have them attack the target
	for _, NPC in pairs(friendlyNPCs) do
		local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPC, Player.UserId)
		NPCInstance:Attack(target)
	end
end)

NPCSentryMode:Connect(function(Player: Player, NPCharacter: Model)
	local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPCharacter, Player.UserId)
	NPCInstance:SentryMode(30, 40)
end)

NPCCollectResource:Connect(function(Player: Player, Args: ExtType.StrDict)
	local resourceObject = Args.ResourceObject
	local resourceNPCs = Args.ResourceNPCs
	--Loop through all resource NPCs and have them collect the given resource
	for _, NPC in pairs(resourceNPCs) do
		local NPCInstance: ExtType.ObjectInstance = NPCHandler:GetPlayerNPCByCharacter(NPC, Player.UserId)
		NPCInstance:HarvestResource(resourceObject)
	end
end)

BuyNPCEvent:Connect(function(Player, Args)
	local price: number = Args.Price
	local NPC: string = Args.NPCName
	local spawnPos = Args.SpawnPos
	GoldHandler:ModAmountBy(Player, (-1 * price))
	if NPC == "MinerNPC" then
		local minerNPC = MinerNPCObject.new(
			"Miner",
			minerNPCRig,
			100,
			spawnPos,
			16,
			10,
			100,
			70,
			100,
			{ "Coal", "Iron", "Pickaxe", "Bread", "Water" },
			nil,
			nil,
			{ "Coal" },
			true
		)
		minerNPC:SetAttribute("AttachTo", "Head")
		minerNPC:SetAttribute("NPC", true)
		minerNPC:SetAttribute("Owner", Player.Name)
		minerNPC:SetAttribute("Type", "Pickaxe")
		minerNPC:AddTag("OverheadUnit")
		NPCHandler:AddNPCToPlayerPool(minerNPC, Player.UserId)
	elseif NPC == "SwordsmanNPC" then
		local newSwordsman = SwardsmanNPC.new("Swordsman", minerNPCRig, 100, spawnPos, 16, 10, 100, 70, 100)
		newSwordsman:SetAttribute("AttachTo", "Head")
		newSwordsman:SetAttribute("NPC", true)
		newSwordsman:SetAttribute("Owner", Player.Name)
		newSwordsman:SetAttribute("Type", "Sword")
		newSwordsman:AddTag("OverheadUnit")
		NPCHandler:AddNPCToPlayerPool(newSwordsman, Player.UserId)
	end
end)

local function GetAmountOfItem(Player, ItemName)
    local Contents = BackpackHandler:GetContents(Player)
	local Amount = 0
	for i,v in pairs(Contents) do
		if v.Name == ItemName then
			Amount += v.Stack
		end
	end
	return Amount
end

MerchantPurchase:Connect(function(Player, Args)
	local amount = Args.Amount
	local price = Args.Price
	local resource = Args.Resource
	BackpackHandler:DestroyItem(Player, resource, amount)
	GoldHandler:ModAmountBy(Player, (price * amount))
end)
