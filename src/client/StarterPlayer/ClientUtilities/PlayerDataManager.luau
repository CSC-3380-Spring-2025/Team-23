local BridgeNet2 = require(game.ReplicatedStorage.BridgeNet2)
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local ClientMutexSeq = require(game.StarterPlayer.StarterPlayerScripts.ClientUtilities.ClientMutexSeq)
local PlayerDataManager: table = {}
Object:Supersedes(PlayerDataManager)

--Instance variables
local __PlayerDataManagerBridge = BridgeNet2.ReferenceBridge("PlayerDataManager")
local PlayerDataManagerInstance = nil
local __SessionData = nil -- Table to store all players' session data
local __MutexLock = nil
local __Player = game.Players.LocalPlayer

--[[
* new - Singleton constructor for the class. Uses bridge net to communicate and retrieve the players data table from the session data manager
*
* NOTE: should be used on player join
* @return - Returns the instance of SessionDataManager. If an instance has already been created, calling this constructor again will return the
* existing instance instead of creating a new one.
]]
function PlayerDataManager.new()
	if PlayerDataManagerInstance then
		return PlayerDataManagerInstance -- Return existing instance
	end
	local self = Object.new("PlayerDataManager")
	__PlayerDataManagerBridge:Fire(__Player, "RequestPlayerData")
	__PlayerDataManagerBridge:Connect(function(player, responseType, playerDataTable)
		if responseType == "PlayerDataResponse" then
			self.__SessionData = playerDataTable
		end
	end)
	-- For testing the bridge between client session mamagner and serversession manager scripts print("Player data table on clinet side",self.sessionData)
	self.__MutexLock = ClientMutexSeq.new("PlayerDataManagerMutexKey")
	setmetatable(self, PlayerDataManager)
	if self.__SessionData then
		PlayerDataManagerInstance = self
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
	self.__MutexLock:Lock()
	local userData: table = self.__SessionData
	self.__MutexLock:Unlock()
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
		self.__MutexLock:Lock()
		self.__SessionData = data
		self.__MutexLock:Unlock()
		return true
	end
	return false
end

--[[
 * PlayerDataManager:Destroy - Sends the player's current data table from the client to the server 
 * so that it can be saved. This function should be called on player leave, and MUST be executed 
 * before the `Data:SavePlayerData` function is called on the server side (inside the script named `DataServices`).
 * 
 * The data is sent by firing a remote event (`__PlayerDataManagerBridge`) to the sessionDataManager in the server scripts.
 * 
 * @return - nil
]]
function PlayerDataManager:Destroy(): ()
	self.__MutexLock:Lock()
	__PlayerDataManagerBridge:Fire(__Player, "ReturningPlayerData", self.__SessionData)
	self.__MutexLock:Unlock()
end


return PlayerDataManager