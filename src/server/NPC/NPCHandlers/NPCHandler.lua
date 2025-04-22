--[[This script handles the storing and access of any and all NPCs--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPCHandler = {}
Object:Supersedes(NPCHandler)

--Pool of all NPCs listed under a players id
local playerNPCPool: {[number]: {[number]: any}} = {}
local serverNPCPool: {[number]: any} = {}
local serverPoolIndex = 1

function NPCHandler.new(Name)
    local self = Object.new(Name)
    setmetatable(self, NPCHandler)
    return self
end

--[[
Inserts an NPC instance into the players NPC pool for easy access
	@param NPCInstance (any) the actuale instance of the NPC object created
	@param PlayerID (number) the players ID who owns the NPC
	@return (number) NPC descriptor number that represents the NPC
    NOT the instance refrence
--]]
function NPCHandler:AddNPCToPlayerPool(NPCInstance: any, PlayerID: number) : ()
	local curPlayersPool: {[number]: {[string]: any}}? = playerNPCPool[PlayerID]
	if not curPlayersPool then
		--players first NPC so set up pool
		local poolValue: {[number]: any} = {
			NPCPool = {}, --Pool of all the players NPCs
			playerPoolIndex = 1
		}
		poolValue.NPCPool[poolValue.playerPoolIndex] = NPCInstance
		poolValue.playerPoolIndex = poolValue.playerPoolIndex + 1
		playerNPCPool[PlayerID] = poolValue
		return
	end
	local NPCPool: {[number]: any} = curPlayersPool.NPCPool
    local curIndex: number = curPlayersPool.playerPoolIndex
	NPCPool[curIndex] = NPCInstance
	curPlayersPool.playerPoolIndex =  curIndex + 1
end

--[[
Returns the refrence to the NPC object instance
    @param Character (Model) the character of the NPC you are looking for
    @param PlayerID (number) the id of the player who owns the NPC
	@return (any) the instance of the NPC object
--]]
function NPCHandler:GetPlayerNPCByCharacter(Character: Model, PlayerID: number) : any
	local curPlayersPool: {[number]: {[string]: any}}? = playerNPCPool[PlayerID]
	if not curPlayersPool then
		warn("Attempt to get NPC by character but player has No NPC's")
		return nil
	end
	local npcPool: {[string]: any} = curPlayersPool.NPCPool
	for _, NPC in pairs(npcPool) do
		local characterNPC = NPC.__NPC
		if characterNPC == Character then
			--found the npc's value for given character
			return NPC
		end
	end
	return nil
end

--[[
Adds a given NPCInstance to the servers NPC Pool
	@param NPCInstance (any) any NPC instance that needs to be added to the pool
--]]
function NPCHandler:AddNPCToServerPool(NPCInstance: any) : ()
	serverNPCPool[serverPoolIndex] = NPCInstance
	serverPoolIndex = serverPoolIndex + 1
end

--[[
Returns the refrence to the NPC object instance
    @param Character (Model) the character of the NPC you are looking for
    @param PlayerID (number) the id of the player who owns the NPC
	@return (any) the instance of the NPC object
--]]
function NPCHandler:GetServerNPCByCharacter(Character: Model, PlayerID: number) : any
	for _, NPC in pairs(serverNPCPool) do
		local characterNPC = NPC.__NPC
		if characterNPC == Character then
			--found the npc's value for given character
			return NPC
		end
	end
	return nil
end

return NPCHandler