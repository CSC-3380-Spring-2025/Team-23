--[[
 * DataServices - A script that constantly listens for and calls the Data
 * module script when a player leaves, a player joins, or the server crashes.
]]

--Services
local Players = game:GetService("Players")
--Requires
local Data = require(script.Parent.Data)
local AssignPlot = require(game.ServerScriptService.Server.Building.AssignPlot)

local function RunData()
	--Initialize classes to call
	local AssignPlotInstance = AssignPlot.new("AssignPlotInstance")
	local DataInstance = Data.new("DataInstance")
	-- Player joins: Load their data
	game.Players.PlayerAdded:Connect(function(player)
		DataInstance:LoadPlayerData(player)
		local SessionDataManager = require(game.ServerScriptService.Server.DataServices.SessionDataManager)
		local SessionDataManagerInstance = SessionDataManager.new("SessionDataManagerInstance") 
		--[[comment this whole test table stuff out after presentaion]]
		local testTable = {
			Currency = {
				gold = 69,
			},
			Base = {
				{
					buildingType = "model",
					CFrame = {0, 0, 0, 0, 0, 0},
					properties = {},
					attributes = { 
						BuildingTemplate = "HouseLevel3",
					}
				},
				{
					buildingType = "model",
					CFrame = {-81.635, 0, -141.038, 0, 0, 0},
					properties = {},
					attributes = {
						BuildingTemplate = "BarracksLevel1",
						health = 69
					}
				},
				{
					buildingType = "model",
					CFrame = {91.635, 0, -34, 0, 0, 0},
					properties = {},
					attributes = {
						BuildingTemplate = "RefineryLevel1",
						health = 69
					}
				},
				{
					buildingType = "model",
					CFrame = {60.635, 0.093, 32.038, 0, 0, 0},
					properties = {},
					attributes = {
						BuildingTemplate = "WheatFarmLevel1",
					}
				}
			},
			Backpack = {}
		}
		--SessionDataManagerInstance:SetPlayerData(player.UserId, testTable)
		AssignPlotInstance:AssignPlot(player)
	end)
	
	-- Player leaves: Save their data
	game.Players.PlayerRemoving:Connect(function(player)
		for i=1, 3 do
			if AssignPlotInstance:UnassignPlot(player) then
				break
			else 
				task.wait(1)
			end
		end
		DataInstance:SavePlayerData(player)
	end)
	
	--commented out right now due to problems with this causing scripts to run forever until roblox force closes
	--[[
	-- Server shuts down. Same as when the leave in function above but for all players
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			for i=1, 3 do
				if AssignPlotInstance:UnassignPlot(player) then
					break
				end
			end
			local saved = DataInstance:SavePlayerData(player)
			if not saved then
				warn("Failed to save data for", player.Name, "before shutdown")
			end
		end
		task.wait(5) -- Give time for saving before the server closes
	end)
	]]
end
RunData()