--[[
This script is reserved for handling the stats of a player when their character loads in
If the player is joining for the first time then the stats info may need to be loaded in first
All subsequent deaths after a player joins will have an entirely new stats for Hunger and hydration
DANGER: This script sues Mutex Locks. All exit paths MUST ensure that locks are released when used.
If a related script pauses execution it is highly likely that this script ran into a dead lock.
--]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local player: Player = Players.LocalPlayer
local playerScripts = player.PlayerScripts
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local UIHandler = require(playerScripts:WaitForChild("UIHandler"))
local ClientMutexSeq = require(playerScripts.ClientUtilities.ClientMutexSeq)

--Instances
local statsUIHandler: any = UIHandler.new("StatsUIHandler")
local hungerMutex = ClientMutexSeq.new("HungerMutex")
local thirstMutex = ClientMutexSeq.new("ThirstMutex")
--Events
local StatsDmgPlayer = BridgeNet2.ReferenceBridge("StatsDmgPlayer")
local bindableEvents = ReplicatedFirst:WaitForChild("BindableEvents")
local statBindEvents = bindableEvents:WaitForChild("Stats")
local FeedPlayerEvent = statBindEvents:WaitForChild("FeedPlayer")
local HydratePlayerEvent = statBindEvents:WaitForChild("HydratePlayer")

local tasks: { thread } = {} --table of executing tasks
local connections: { RBXScriptConnection } = {} --Table of conections

local statsConfig: { any } = {
	--Handles config for stats
	MaxFood = 100, --Max hunger of the player
	MaxHydration = 100, --MaxHydration of the player
	FdDeteriorationRate = 5, --time in seconds between when food stat gos down
	HydDeteriorationRate = 6, --time in seconds between when hydration stat gos down
	FdDecrement = 30, --The amount that the food stat is decremented by every FdDeteriorationRate
	HydDecrement = 30, --The amount that the hydration stat is decremented by every HydDeteriorationRate
	StarveDmg = 20, --The damage done to a player every StarveDmgRate
	StarveDmgRate = 5, --rate in seconds that damage is dealt during a starve
	ThirstDmg = 20, --The damage done to a player every ThirstDmgRate
	ThirstDmgRate = 5, --rate in seconds that damage is dealt during a thirst
}

local stats: { number } = {
	--The stat values
	Food = statsConfig.MaxFood,
	Hydration = statsConfig.MaxHydration,
}

--[[
Starves the player until it is given food
--]]
local function Starve(): ()
	tasks.StvTask = task.spawn(function()
		--Damage NPC
		while true do
			hungerMutex:Lock()
			if stats.Food > 0 then
				tasks.StvTask = nil
				hungerMutex:Unlock()
				return --No longer starving
			end
			hungerMutex:Unlock()
			--Tell server to damage player by given amount
			StatsDmgPlayer:Fire(statsConfig.StarveDmg)
			task.wait(statsConfig.StarveDmgRate)
		end
	end)
end

--Handle hunger stats
tasks.Hunger = task.spawn(function()
	while true do
		task.wait(statsConfig.FdDeteriorationRate) --Wait between decrements
		hungerMutex:Lock()
		local newStat: number = stats.Food - statsConfig.FdDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end

		if newStat ~= lastStat then
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
		hungerMutex:Unlock()
	end
end)

--[[
Thirsts the player until it is given a drink
--]]
local function Thirst(): ()
	tasks.ThirstTask = task.spawn(function()
		--Damage NPC
		while true do
			thirstMutex:Lock()
			if stats.Hydration > 0 then
				tasks.ThirstTask = nil
				thirstMutex:Unlock()
				return --No longer starving
			end
			thirstMutex:Unlock()
			--Tell server to damage player by given amount
			StatsDmgPlayer:Fire(statsConfig.ThirstDmg)
			task.wait(statsConfig.ThirstDmgRate)
		end
	end)
end

--Handle hydration stats
tasks.Hydration = task.spawn(function()
	while true do
		task.wait(statsConfig.HydDeteriorationRate) --Wait between decrements
		thirstMutex:Lock()
		local newStat: number = stats.Hydration - statsConfig.HydDecrement
		if newStat < 0 then
			newStat = 0 --Prevent negative stat
		end

		if newStat ~= lastStat then
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
		thirstMutex:Unlock()
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

--Handle stat events

--[[
This function increases the players hunger stat by FoodRegen amount
	if foodregen exceeds the config for max hunger then it is set to max hunger
	@param FoodRegen (number) the amount to increase hunger stat by
--]]
local function FeedPlayer(FoodRegen: number): ()
	--Up food stat by regen amount or max amount if greater than max amount
	hungerMutex:Lock()
	local newStat = stats.Food + FoodRegen
	if newStat <= statsConfig.MaxFood then
		stats.Food = newStat
	else
		stats.Food = statsConfig.MaxFood
	end
	--Update UI for new hunger stat
	local newPrcnt: number = (newStat / statsConfig.MaxFood)
	statsUIHandler:AdjustBarUI("Hunger", newPrcnt, false)
	hungerMutex:Unlock()
end

--[[
This function increases the players hydration stat by HydrationRegen amount
	if HydrationRegen exceeds the config for max hunger then it is set to max hydration
	@param HydrationRegen (number) the amount to increase Hydration stat by
--]]
local function HydratePlayer(HydrationRegen: number): ()
	--Up water stat by regen amount or max amount if greater than max amount
	thirstMutex:Lock()
	local newStat = stats.Hydration + HydrationRegen
	if newStat <= statsConfig.MaxHydration then
		stats.Hydration = newStat
	else
		stats.Hydration = statsConfig.MaxFood
	end
	--Update UI for new Hydration stat
	local newPrcnt: number = (newStat / statsConfig.MaxHydration)
	statsUIHandler:AdjustBarUI("Water", newPrcnt, false)
	thirstMutex:Unlock()
end

FeedPlayerEvent.Event:Connect(function(FoodRegen)
	print("Recieved Food Regen event!")
	FeedPlayer(FoodRegen)
end)

HydratePlayerEvent.Event:Connect(function(HydrationRegen)
	print("Recieved drink Regen event!")
	HydratePlayer(HydrationRegen)
end)
