--[[
 * SessionDataManager - A singleton object that handles the storage and management of all players' data while in server.
 *
 * The data is indexed by the player's user ID, and it can be accessed, modified, or removed as needed during the game session.
 *
 * The sessionData table is the primary storage for player data, with the user ID as the key and the player's data table as the value.
 * To view the structure of a player's data table, refer to the DefaultPlayerData module script. 
 *
 * NOTE: This system utilizes ServerMutexSeq to ensure safe concurrent access to player data.  

]]  

local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local ServerMutexSeq = require(game.ServerScriptService.Server.ServerUtilities.ServerMutexSeq)
local SessionDataManager: table = {}
Object:Supersedes(SessionDataManager)

--Instance variables
local sessionDataManagerInstance = nil
local sessionData = nil -- Table to store all players' session data
local mutexLock = nil

--[[
* new - Singleton constructor for the class.
*
* @return - Returns the instance of SessionDataManager. If an instance has already been created, calling this constructor again will return the
* existing instance instead of creating a new one.
]]
function SessionDataManager.new()
	if sessionDataManagerInstance then
		return sessionDataManagerInstance -- Return existing instance
	end
	local self = Object.new("SessionDataManager")
	self.sessionData = {} 
	self.mutexLock = ServerMutexSeq.new("SessionDataManagerMutexKey")
	setmetatable(self, SessionDataManager)
	sessionDataManagerInstance = self
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
function SessionDataManager:GetPlayerData(userID: number): table?
	self.mutexLock:Lock()
	local userData: table = self.sessionData[userID] or nil
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
function SessionDataManager:SetPlayerData(userID: number, data: table): boolean
	if data then
		self.mutexLock:Lock()
		self.sessionData[userID] = data
		self.mutexLock:Unlock()
		return true
	end
	return false
end


--[[
	* RemovePlayerData - Removes a player from the global sessionData table.
	*
	* @userID - The user ID of the player whose data is to be removed.
	*
	* @return - Returns true if the player's data was successfully removed,
	* or false if the player’s data was not found in the sessionData table.
]]
function SessionDataManager:RemovePlayerData(userID: number): boolean
	self.mutexLock:Lock()
	if self.sessionData[userID] then
		self.sessionData[userID] = nil
		self.mutexLock:Unlock()
		return true
	end
	self.mutexLock:Unlock()
	return false
end


return SessionDataManager
