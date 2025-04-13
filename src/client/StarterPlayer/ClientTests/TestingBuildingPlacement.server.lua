--NOTE: there is not yet a feature for creating a playplot for a player upon joining so i manually had to add one to the workspace named after my roblox player name
--the Placing buildilng script should be called from a client script in order to work
--[[
	local Players = game:GetService("Players")
	
	local PlaceBuilding = require(game.StarterPlayer.StarterPlayerScripts.PlaceBuilding)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local Bulidings = replicatedStorage:FindFirstChild("Buildings")
	local House = Bulidings:FindFirstChild("House")
	local Houselv1 = House:FindFirstChild("HouseLevel1")
	
	local playerPlotTemplate = replicatedStorage.PlayerPlotTemplate.PlayerPlotTemplate
	local usersPlayerPlot = playerPlotTemplate:Clone()
	local player = Players.LocalPlayer
	usersPlayerPlot.Parent = workspace[player.Name].PlayerPlots.PlayerPlot
	
	
	
local playerPlotTemplate = workspace[player.Name].PlayerPlots.PlayerPlot:FindFirstChild("PlayerPlotTemplate")


PlaceBuildingInstance = PlaceBuilding.new("PlaceBuildingInstance")

PlaceBuildingInstance:PlaceBuilding(playerPlotTemplate, Houselv1, player)

]]