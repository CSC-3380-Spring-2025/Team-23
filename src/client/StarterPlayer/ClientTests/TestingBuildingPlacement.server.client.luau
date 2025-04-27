--[[
--NOTE: there is not yet a feature for creating a playplot for a player upon joining so i manually had to add one to the workspace named after my roblox player name
--the Placing buildilng script should be called from a client script in order to work
task.wait(3)
local Players = game:GetService("Players")

local PlaceBuilding = require(game.StarterPlayer.StarterPlayerScripts.PlaceBuilding)
local replicatedStorage = game:GetService("ReplicatedStorage")
local Bulidings = replicatedStorage:FindFirstChild("Buildings")
local Barracks = Bulidings:FindFirstChild("Barracks")
local BarracksLevel1 = Barracks:FindFirstChild("BarracksLevel1")

local player = Players.LocalPlayer


local playerPlotTemplate = workspace.PlayersWorkspace[player.Name].PlayerPlots.PlayerPlot:FindFirstChild("PlayerPlotTemplate")


PlaceBuildingInstance = PlaceBuilding.new("PlaceBuildingInstance")
print(playerPlotTemplate, BarracksLevel1, player)
PlaceBuildingInstance:PlaceBuilding(playerPlotTemplate, BarracksLevel1, player)

]]