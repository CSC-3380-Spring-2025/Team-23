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
local BridgeNet2 = require(game.ReplicatedStorage.BridgeNet2)
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local ServerMutexSeq = require(game.ServerScriptService.Server.ServerUtilities.ServerMutexSeq)
local SessionDataManager: table = {}
Object:Supersedes(SessionDataManager)

--Instance variables
local __PlayerDataManagerBridge = BridgeNet2.ReferenceBridge("PlayerDataManager")
local __SessionDataManagerInstance = nil
local __SessionData = nil -- Table to store all players' session data
local __MutexLock = nil

--[[
* new - Singleton constructor for the class.
*
* @return - Returns the instance of SessionDataManager. If an instance has already been created, calling this constructor again will return the
* existing instance instead of creating a new one.
]]
function SessionDataManager.new()
	if __SessionDataManagerInstance then
		return __SessionDataManagerInstance -- Return existing instance
	end
	local self = Object.new("SessionDataManager")
	self.__SessionData = {} 
	self.__MutexLock = ServerMutexSeq.new("SessionDataManagerMutexKey")
	setmetatable(self, SessionDataManager)
	__SessionDataManagerInstance = self
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
function SessionDataManager:GetPlayerData(UserID: number): table?
	self.__MutexLock:Lock()
	local userData: table = self.__SessionData[UserID] or nil
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
function SessionDataManager:SetPlayerData(UserID: number, Data: table): boolean
	if Data then
		self.__MutexLock:Lock()
		self.__SessionData[UserID] = Data
		self.__MutexLock:Unlock()
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
function SessionDataManager:RemovePlayerData(UserID: number): boolean
	self.__MutexLock:Lock()
	if self.__SessionData[UserID] then
		self.__SessionData[UserID] = nil
		self.__MutexLock:Unlock()
		return true
	end
	self.__MutexLock:Unlock()
	return false
end


--[[
	* GetCustomPlayerData - Retrieves a specific subtable from a user's session data.
	*
	* @param Key (string) - The subtable name to retrieve. 
	* Only "Currency", "Base", and "Backpack" are currently supported, but refer to the default player data file to view the structure and immediate children.
	*
	* @param UserID (number) - The user ID used to locate the player’s data in the global session data table.
	*
	* @return (table | nil) - Returns the requested subtable if it exists for the user,
	* or nil if the subtable does not exist or the user has no data.
]]
function SessionDataManager:GetCustomPlayerData(Key: String, UserID: number): {}?
	local customPlayerData = nil
	self.__MutexLock:Lock()
	if self.__SessionData[UserID][Key] then 
		customPlayerData = self.__SessionData[UserID][Key]
	end
	self.__MutexLock:Unlock()
	return customPlayerData
end

--[[
	* SetCustomPlayerData - Updates only a specific section in a user's session data.
	*
	* @param Key (string) - The subtable name to set. 
	* Only "Currency", "Base", and "Backpack" are currently supported.
	*
	* @param Value (table) - The new table to set for the given key. Must not be nil or an empty table.
	* NOTE: You will not be allowed to set the value of these tables to nothing (nil or empty).
	*
	* @param UserID (number) - The user ID used to locate the player’s data in the global session data table.
	*
	* @return (boolean) - Returns true if the subtable was successfully updated, or false otherwise
	*
]]
function SessionDataManager:SetCustomPlayerData(Key: String, Value: {}, UserID: number): {}
	local setSuccsessful = false 
	self.__MutexLock:Lock()
	if self.__SessionData[UserID][Key] then 
		if Value == nil or {} then
			warn("Setting ", Key, " in data table for ", UserID, "to nil. This action is not allowed")	
		else
			self.__SessionData[UserID][Key] = Value
			setSuccsessful = true
		end
	end
	self.__MutexLock:Unlock()
	return setSuccsessful
end
--Listen for PlayerDataManager to fire 
__PlayerDataManagerBridge:Connect(function(Player: Player, RequestType: string)
	if RequestType == "RequestPlayerData" then
		local playerDataTable: table = SessionDataManager:GetPlayerData(Player.UserId)
		-- Fire the player data back to the client
		__PlayerDataManagerBridge:Fire(Player,"PlayerDataResponse", playerDataTable)
	end
end)


return SessionDataManager
