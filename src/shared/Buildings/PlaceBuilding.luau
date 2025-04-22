--[[
local StarterPlayer = game:GetService("StarterPlayer")
local PlaceBuildingRemoteScript = require(StarterPlayer.StarterPlayerScripts.PlaceBuilding)

PlaceBuildingRemoteScript.OnServerEvent:Connect(function(player, building: Instance, parentFolder: Instance)
	if not building or not parentFolder then return end
	building.Parent = parentFolder
end)
]]
