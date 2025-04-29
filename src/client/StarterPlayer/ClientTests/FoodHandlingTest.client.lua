local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player: Player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local StatsHandlerInterfaceObject = require(playerScripts.StatsHandlerInterface)
local myStatsHandler = StatsHandlerInterfaceObject.new("Test Interface")
--[[
task.wait(20)
myStatsHandler:FeedPlayer(20)
myStatsHandler:HydratePlayer(20)
--]]