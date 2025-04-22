--[[
This script is reserved for handling the stats of a player when their character loads in
If the player is joining for the first time then the stats info may need to be loaded in first
All subsequent deaths after a player joins will have an entirely new stats for Hunger and hydration
--]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player: Player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local UIHandler = require(playerScripts:WaitForChild("UIHandler"))
--Instances
local statsUIHandler: any = UIHandler.new("StatsUIHandler")
--Events
local StatsDmgPlayer = BridgeNet2.ReferenceBridge("StatsDmgPlayer")

local tasks: {thread} = {} --table of executing tasks
local connections: {RBXScriptConnection} = {} --Table of conections

local statsConfig: {any} = {
	--Handles config for stats
	MaxFood = 100, --Max hunger of the player
	MaxHydration = 100, --MaxHydration of the player
	FdDeteriorationRate = 120, --time in seconds between when food stat gos down
	HydDeteriorationRate = 120, --time in seconds between when hydration stat gos down
	FdDecrement = 5, --The amount that the food stat is decremented by every FdDeteriorationRate
	HydDecrement = 5, --The amount that the hydration stat is decremented by every HydDeteriorationRate
	StarveDmg = 5, --The damage done to a player every StarveDmgRate
	StarveDmgRate = 20, --rate in seconds that damage is dealt during a starve
	ThirstDmg = 5, --The damage done to a player every ThirstDmgRate
	ThirstDmgRate = 20,--rate in seconds that damage is dealt during a thirst
}

local stats: {number} = {
	--The stat values
	Food = statsConfig.MaxFood,
	Hydration = statsConfig.MaxHydration,
}

--[[
Starves the player until it is given food
--]]
local function Starve() : ()
	tasks.StvTask = task.spawn(function()
		--Damage NPC
		while true do
			if stats.Food > 0 then
				tasks.StvTask = nil
				return--No longer starving
			end
			--Tell server to damage player by given amount
            StatsDmgPlayer:Fire(statsConfig.StarveDmg)
			task.wait(statsConfig.StarveDmgRate)
		end
	end)
end

--Handle hunger stats
tasks.Hunger = task.spawn(function()
    local lastStat: number = 0
	while true do
		task.wait(statsConfig.FdDeteriorationRate) --Wait between decrements
		local newStat: number = stats.Food - statsConfig.FdDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end

        if newStat == lastStat then
            continue--Skip to next loop nothing new to do
        else
            --Update UI for new hunger stat
            local newPrcnt: number = (newStat / statsConfig.MaxFood)
            statsUIHandler:AdjustBarUI("Hunger", newPrcnt, false)
        end
		stats.Food = newStat
		--Check if starved
		if newStat <= 0 then
			--Start damaging player and store task to cancel when given food
			Starve()
		end
        lastStat = newStat --Update lastStat
	end
end)

--[[
Thirsts the player until it is given a drink
--]]
local function Thirst() : ()
	tasks.ThirstTask = task.spawn(function()
		--Damage NPC
		while true do
			if stats.Hydration > 0 then
				tasks.ThirstTask = nil
				return--No longer starving
			end
			--Tell server to damage player by given amount
            StatsDmgPlayer:Fire(statsConfig.ThirstDmg)
			task.wait(statsConfig.ThirstDmgRate)
		end
	end)
end

--Handle hydration stats
tasks.Hydration = task.spawn(function()
    local lastStat: number = 0
	while true do
		task.wait(statsConfig.HydDeteriorationRate) --Wait between decrements
		local newStat: number = stats.Hydration - statsConfig.HydDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end

        if newStat == lastStat then
            continue--Skip to next loop nothing new to do
        else
            --Update UI for new Hydration stat
            local newPrcnt: number = (newStat / statsConfig.MaxHydration)
            statsUIHandler:AdjustBarUI("Water", newPrcnt, false)
        end
		stats.Hydration = newStat
		--Check if starved
		if newStat <= 0 then
			--Start damaging player because of thirst
			Thirst()
		end
        lastStat = newStat --Update lastStat
	end
end)

--Handles health bar
tasks.Health = task.spawn(function()
    local character: Model = player.Character :: Model
    local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

    humanoid.Died:Once(function()
        --Clean up health change connect to prevent mem leaks
        if connections.healthChange then
            connections.healthChange:Disconnect()
        end
    end)
    
    connections.healthChange = humanoid.HealthChanged:Connect(function(curHealth)
        --Update health
        local newPrcnt: number = curHealth / humanoid.MaxHealth
        statsUIHandler:AdjustBarUI("Health", newPrcnt, false)
    end)

end)
