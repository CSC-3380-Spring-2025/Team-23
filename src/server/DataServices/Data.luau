--[[  
 * Data - Handles saving and loading player data using the Roblox DataStore.  
 *  
 * This module is responsible for retrieving a player's data from the DataStore  
 * when they join and saving it when they leave.
 * 
 * This should be the first module script to run when a player joins.  
 * It interacts with the SessionDataManager module to safely add and remove  
 * player data from the global session data table, which contains all active players' data.  
 *  
 * To view the structure of a player's data, refer to the DefaultPlayerData module.  
]]  
--services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
--other scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local DefaultPlayerData = require(script.Parent.DefaultPlayerData)
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)

--globals
local Data = {}
Object:Supersedes(Data)
local Database = DataStoreService:GetDataStore("data")
local SessionDataManagerInstance: table = SessionDataManager.new()

--Constructor that has no parameters apart from instance name
function Data.new(Name) 
	local self = Object.new(Name)
	setmetatable(self, Data)  
	return self
end



--[[  
 * loadPlayerData - Retrieves player data from the Roblox DataStore.  
 * If data retrieval fails after multiple attempts, the player is kicked.  
 * Once data is retrieved, it is stored in the global session data table  
 * via the SessionDataManager module. If the player is new, they are assigned  
 * a default data table from the DefaultPlayerData module.  
 *  
 * This function should only be used when the player joins the game.  
 *  
 * @player - The Player instance provided through the PlayerAdded signal.  
 *  
 * @return - boolean - Returns true if data retrieval is successful, otherwise  
 *                     returns false and kicks the player from the game.  
]]  
function Data:LoadPlayerData(Player: Player): boolean
	local key: string = tostring(Player.UserId)
	local success: boolean
	local errorMsg: any = nil
	local attempt: number = 1
	local playerData: table? = nil
	--connect to DataStoreService

	repeat
		success, errorMsg = pcall(function()
			playerData = Database:GetAsync(key)
		end)
		if not success then
			warn(errorMsg)
			task.wait(3) --TODO: have a loading screen of some sorts occupy screen while script attempts to fetch data
		end
		attempt += 1
	until success or attempt > 5

	--Add fetched data to session data table via session data handler interface
	if success then
		print("Connected ", Player.Name, " to database")
		if playerData then
			
			SessionDataManagerInstance:SetPlayerData(Player.UserId, playerData)
		else --if first time joining server
			SessionDataManagerInstance:SetPlayerData(Player.UserId, DefaultPlayerData.data)
		end
		return true
	else
		warn("Unable to get data for ", Player.Name)
		Player:Kick("Unable to load your data. Try again later")
		return false
	end
end


--[[  
 * savePlayerData - Retrieves the player's data from the global data table using the
 * SessionDataManager module. The data is then stored in the DataStore.
 *  
 * If the save process fails after multiple attempts, a warning is issued,
 * and the function returns false, meaning the player's progress will be lost.
 *  
 * This function should only be called when a player leaves the game or
 * when the server crashes.
 *
 * @player - The Player instance provided through the PlayerRemoving signal.
 *
 * @return - boolean - Returns true if data is successfully saved, otherwise
 *                     returns false if an error occurs during saving.
]]
function Data:SavePlayerData(Player: Player): boolean
	local key: string = tostring(Player.UserId)
	local data = SessionDataManagerInstance:GetPlayerData(Player.UserId)
	if data then
		local success: boolean
		local errorMsg: any = nil
		local attempt: number = 1

		repeat
			success, errorMsg = pcall(function()
				Database:SetAsync(key, data)
			end)
			if not success then
				warn(errorMsg)
				task.wait(3)
			end
			attempt += 1
		until success or attempt > 5

		if success then
			print("Data saved for ", Player.Name)
			return true
		else
			warn("Unable to save for", Player.Name)
			return false
		end
	end
end


return Data
