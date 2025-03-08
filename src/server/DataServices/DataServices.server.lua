--Services
local Players = game:GetService("Players")
--Requires
local Data = require(game.ServerScriptService.Server.DataServices.Data)


local function runData()
	-- Player joins: Load their data
	game.Players.PlayerAdded:Connect(function(player)
		Data:loadPlayerData(player)
	end)
	-- Player leaves: Save their data
	game.Players.PlayerRemoving:Connect(function(player)
		Data:savePlayerData(player)
	end)
	-- Bind shutdown event
	game:BindToClose(function()
		Data:ServerShutdown()
	end)
end
runData()