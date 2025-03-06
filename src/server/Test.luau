local Test = {}
local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)
--set currency to 2 for gold without using interface
function Test:assignGold(player)
	print("entered function")
	local playerData = SessionDataManager:GetPlayerData(player)
	playerData.Currency.gold = 2
end

function Test:printGoldAmount(player)
	local playerData = SessionDataManager:GetPlayerData(player)
	print(tostring(playerData.Currency.gold))
end