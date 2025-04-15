--[[
	local Wheat = require(game.ReplicatedStorage.Shared.Farming.Wheat)
	local replicatedStorage = game:GetService("ReplicatedStorage")
local Farming = replicatedStorage:FindFirstChild("Farming")
local Crops = Farming:FindFirstChild("Crops")
local WheatCrop = Crops:FindFirstChild("Wheat")
	
local EarlyCrop: Model = WheatCrop:FindFirstChild("WheatBushelEarly")
local MidCrop: Model = WheatCrop:FindFirstChild("WheatBushelMid")
local FinishedCrop: Model = WheatCrop:FindFirstChild("WheatBushelRipe")

local WheatInstance = Wheat.new("WheatInstance", EarlyCrop, MidCrop, FinishedCrop, 10)
local Target: Instance = workspace:FindFirstChild("Farmland1")


WheatInstance:Sow(Target)

WheatInstance:Fertilize(Target, 2)

WheatInstance:Plant(Target, "WheatBushel")
for _,player in pairs(game:GetService("Players"):GetChildren()) do
	WheatInstance:Reap(Target, player)
end

	]]