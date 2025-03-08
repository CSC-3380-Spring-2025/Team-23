local SessionDataManager: table = {}
SessionDataManager.sessionData = {} -- Table to store all players' session data

function SessionDataManager:GetPlayerData(player: Player): table?
	if not self.sessionData[player.UserId] then
		return nil
	end
	return self.sessionData[player.UserId]
end

function SessionDataManager:SetPlayerData(player: Player, data: table): boolean
	if data then
		self.sessionData[player.UserId] = data
		return true
	end
	return false
end

function SessionDataManager:RemovePlayerData(player: Player): boolean
	if self.sessionData[player.UserId] then
		self.sessionData[player.UserId] = nil
		return true
	end
	return false
end

return SessionDataManager
