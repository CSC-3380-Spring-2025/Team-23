--services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
--other scripts
local DefaultPlayerData = require(game.ServerScriptService.Server.DefaultPlayerData)
local SessionDataManager = require(game.ServerScriptService.Server.SessionDataManager)
local Test = require(game.ServerScriptService.Server.Test)


--globals
local database = DataStoreService:GetDataStore("data")

-- Function to load player data
local function loadPlayerData(player: Player) : boolean
	local key: string = tostring(player.UserId)
	local success: boolean
	local errorMsg: any = nil
	local attempt: number = 1
	local playerData: table? = nil
	--connect to DataStoreService

	repeat
		success, errorMsg = pcall(function()
			playerData=database:GetAsync(key)
		end)
		if not success then
			warn(errorMsg)
			task.wait(3) --TODO: have a loading screen of some sorts occupy screen while script attempts to fetch data
		end
		attempt += 1
	until success or attempt > 5

	--Add fetched data to session data table via session data handler interface
	if success then
		print("Connected to database")
		if playerData then
			SessionDataManager:SetPlayerData(player, playerData)
		else --if first time joining server
			SessionDataManager:SetPlayerData(player,DefaultPlayerData.data)
		end
		return true
	else
		warn("Unable to get data for ", player.Name)
		player:Kick("Unable to load your data. Try again later")
		return false
	end
end

-- Function to save player data
local function savePlayerData(player: Player) : boolean
	print("Entering save player")
	local key: string = tostring(player.UserId)
	local data = SessionDataManager:GetPlayerData(player)

	if data then
		local success: boolean
		local errorMsg: any = nil
		local attempt: number = 1

		repeat
			success, errorMsg = pcall(function()
				database:SetAsync(key, data)
			end)
			if not success then
				warn(errorMsg)
				task.wait(3)
			end
			attempt += 1
		until success or attempt > 5

		if success then
			print("Data saved for ", player.Name)
			return true
		else
			warn("Unable to save for", player.Name)
			return false
		end
	end
end

-- Player joins: Load their data
game.Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player) 
end)

-- Player leaves: Save their data
game.Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)


--Save all player data on server shutdown
function ServerShutdown()
	print("Server shutting down...")
	for _, player in ipairs(Players:GetPlayers()) do
		local saved = savePlayerData(player)
		if not saved then
			warn("Failed to save data for", player.Name, "before shutdown")
		end
	end
	task.wait(3) -- Give time for saving before the server closes
end

game:BindToClose(ServerShutdown)