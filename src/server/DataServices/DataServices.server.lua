--[[
 * DataServices - A script that constantly listens for and calls the Data
 * module script when a player leaves, a player joins, or the server crashes.
]]

--Services
local Players = game:GetService("Players")
--Requires
local Data = require(script.Parent.Data)
local BuildingDataManager = require(script.Parent.BuildingDataManager)

local function runData()
	--Initialize classes to call
	local BuildingDataManagerInstance = BuildingDataManager.new("BuildingDataManagerInstance")
	local DataInstance = Data.new("DataInstance")
	-- Player joins: Load their data
	game.Players.PlayerAdded:Connect(function(player)
		DataInstance:loadPlayerData(player)
		BuildingDataManagerInstance:loadBuildings(player)
	end)
	
	-- Player leaves: Save their data
	game.Players.PlayerRemoving:Connect(function(player)
		BuildingDataManagerInstance:saveBuldings(player)	
		DataInstance:savePlayerData(player)
	end)
	
	-- Server shuts down
	game:BindToClose(function()
		Data:ServerShutdown()
		for _, player in ipairs(Players:GetPlayers()) do
			BuildingDataManagerInstance:saveBuldings(player)
			local saved = DataInstance:savePlayerData(player)
			if not saved then
				warn("Failed to save data for", player.Name, "before shutdown")
			end
		end
		task.wait(5) -- Give time for saving before the server closes
	end)
end
runData()