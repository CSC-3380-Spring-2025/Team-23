--[[
 * AssignPlot
 *
 * This module manages the assignment and unassignment of plots to players in the game as people join and leave. 
 * It creates a folder for them in workspace wehre their properties will be located as well as uses the BuildingDataManager to
 * handle the interaction for the building data in their datastore table.
 *
]]


--module scripts
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
local BuildingDataManager = require(game.ServerScriptService.Server.Buildings.BuildingDataManager)
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssignPlot = {}
Object:Supersedes(AssignPlot)
local BuildingDataManagerInstance = BuildingDataManager.new("BuildingDataManagerInstance")

--Constructor that takes in no parameters
function AssignPlot.new(Name)
	local self = Object.new(Name)
	setmetatable(self, AssignPlot)

	return self
end


--[[
 * AssignPlot - Assigns a random, unclaimed plot of land to a player upon joining the game.
 *                         It clones the PlayerPlot template from ReplicatedStorage, places it at the selected area, creates a folder for the player inside Workspace/PlayersWorkspace, 
 *                         and loads any previously saved buildings using BuildingDataManager. It also sets the player's
 *                         RespawnLocation and teleports them to the assigned plot.
 *
 * @Player - (Player) The player who is being assigned a plot.
 *
 *NOTE: If loading buildings fails or no unassigned plot is found, the player is kicked.
 *
 * @return - Returns true if a plot was successfully assigned and loaded. Other wise returns false
]]
function AssignPlot:AssignPlot(Player: Player): boolean
	local rootParts: { BasePart } = game.Workspace.PlotRootParts:GetChildren()

	for i = 1, #rootParts * 2 do
		local pickedPart: BasePart = rootParts[math.random(1, #rootParts)]
		if pickedPart:GetAttribute("AssignedPlayer") == "" then
			local playerPlotTemplate: BasePart = game.ServerStorage.PlayerPlot.PlayerPlotTemplate:Clone()
			playerPlotTemplate.Position = Vector3.new(pickedPart.Position.X,1, pickedPart.Position.Z)
			-- Make players folder in Playerworkspace
			local playerWorkspace = workspace:WaitForChild("PlayersWorkspace")
			local playerFolder = Instance.new("Folder")
			playerFolder.Name = Player.Name
			playerFolder.Parent = playerWorkspace
			local plotsFolder = Instance.new("Folder")
			plotsFolder.Name = "PlayerPlots"
			plotsFolder.Parent = playerFolder
			local playerPlotFolder = Instance.new("Folder")
			playerPlotFolder.Name = "PlayerPlot"
			playerPlotFolder.Parent = plotsFolder
			playerPlotTemplate.Parent = playerPlotFolder

			if BuildingDataManagerInstance:LoadBuildings(Player, playerPlotTemplate) then
				--set player spawnlocation and teleport them to plot
				local playerSpawnLocation = pickedPart.Position
				local spawnPoint: SpawnLocation = game.ServerStorage.PlayerPlot.SpawnLocation:Clone()
				spawnPoint.Parent = plotsFolder
				spawnPoint.Position = playerSpawnLocation
				Player.RespawnLocation = spawnPoint
				-- Once player spawns, teleport to plot
				local character = Player.Character or Player.CharacterAdded:Wait()
				character:MoveTo(playerSpawnLocation)
				pickedPart:SetAttribute("AssignedPlayer", Player.Name)
				return true
			else
				break
			end
		end
	end
	warn("No plot could be assigned or there was an error loading buildings for ", Player.Name)
	task.wait(3)
	Player:Kick("No plot could be assigned or there was an error loading buildings for", Player.Name)
	return false
end


--[[
 * UnassignPlot - Saves all buildings currently placed in a player's plot and releases their assigned plot for reuse by another player.
 *                            .Uses BuildingDataManager to save the building data, and then destroys the PlayerPlot
 *
 * @Player - (Player) The player whose plot is being unassigned.
 *
 * @return - (boolean) Returns true if the plot was successfully unassigned and buildings were saved. Other wise returns false
]]
function AssignPlot:UnassignPlot(Player: Player): boolean
	for _,rootPart in ipairs(game.Workspace.PlotRootParts:GetChildren()) do
		if rootPart:GetAttribute("AssignedPlayer") == Player.Name then
			local playerPlotTemplate: BasePart = workspace.PlayersWorkspace[Player.Name]:FindFirstChild("PlayerPlotTemplate", true)

			if BuildingDataManagerInstance:SaveBuildings(Player, playerPlotTemplate) then
				--set player spawnlocation and teleport them to plot
				rootPart:SetAttribute("AssignedPlayer", "")
				playerPlotTemplate:Destroy()
				return true
			else
				break
			end
		end
	end
	warn("Players plot not found or there was an error saving buidlings to roblox store ", Player.Name)
	return false
end

return AssignPlot
