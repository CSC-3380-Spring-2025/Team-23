local BridgeNet2 = require(game.ReplicatedStorage.BridgeNet2)
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local ClientMutexSeq = require(game.StarterPlayer.StarterPlayerScripts.ClientUtilities.ClientMutexSeq)
local PlayerDataManager: table = {}
Object:Supersedes(PlayerDataManager)

--Instance variables
local PlayerDataManagerBridge = BridgeNet2.ReferenceBridge("PlayerDataManager")
local playerDataManagerInstance = nil
local sessionData = nil -- Table to store all players' session data
local mutexLock = nil
local player = game.Players.LocalPlayer

--[[
* new - Singleton constructor for the class.
*
* @return - Returns the instance of SessionDataManager. If an instance has already been created, calling this constructor again will return the
* existing instance instead of creating a new one.
]]
function PlayerDataManager.new()
	if playerDataManagerInstance then
		return playerDataManagerInstance -- Return existing instance
	end
	local self = Object.new("PlayerDataManager")
	PlayerDataManagerBridge:Fire(player, "RequestPlayerData")
	PlayerDataManagerBridge:Connect(function(player, responseType, playerDataTable)
		if responseType == "PlayerDataResponse" then
			self.sessionData = playerDataTable
		end
	end)
	print("Player data table on clinet side",self.sessionData)
	self.mutexLock = ClientMutexSeq.new("PlayerDataManagerMutexKey")
	setmetatable(self, PlayerDataManager)
	if self.sessionData then
		playerDataManagerInstance = self
	end
	return self
end

--[[
* GetPlayerData - Retrieves the data table for a specific player from the sessionData table.
*
* @userID - The user id for the player whose data is to be retrieved.
*
* @return - Returns the player's data table from the sessionData global table
* if found, or nil if the player’s data is not found.
]]
function PlayerDataManager:GetPlayerData(): table?
	self.mutexLock:Lock()
	local userData: table = self.sessionData
	self.mutexLock:Unlock()
	return userData
end

--[[  
	* SetPlayerData - Adds or changes player's data to the global sessionData table.
	*
	* @userID - The user id for the player whose data is to be retrieved.
	*
	* @return - Returns true if the data was successfully added to the
	* sessionData table, or false if the data was not provided.
]]
function PlayerDataManager:SetPlayerData(data: table): boolean
	if data then
		self.mutexLock:Lock()
		self.sessionData = data
		self.mutexLock:Unlock()
		return true
	end
	return false
end

return PlayerDataManager