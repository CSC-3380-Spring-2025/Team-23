local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Player = Players:WaitForChild("bachancuc123")

local BackpackHandler = require(ServerScriptService:WaitForChild("Server").Player.BackpackHandler)
task.wait(5)
BackpackHandler:AddItemToBackPack(Player,"Coal", 150)
