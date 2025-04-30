--[[
This script is used to manipulate the StatsHandler in StarterCharacter
Bindable events are used to allow for stat handling to destroy itself easily when the character dies and needs to be reset.
Using bindable events allows for nothing to happen in the case that a character has not yet spawned or
is in the process of respawning.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local StatsHandlerInterface = {}
Object:Supersedes(StatsHandlerInterface)

--Events
local bindableEvents: Folder = ReplicatedFirst:WaitForChild("BindableEvents")
local statBindEvents: Folder = bindableEvents:WaitForChild("Stats") :: Folder
local FeedPlayerEvent: BindableEvent = statBindEvents:WaitForChild("FeedPlayer") :: BindableEvent
local HydratePlayerEvent: BindableEvent = statBindEvents:WaitForChild("HydratePlayer") :: BindableEvent


--[[
Constructor for a StatsHandler instance
	@param Name (string) the name of the instance
--]]
function StatsHandlerInterface.new(Name: string) : ExtType.ObjectInstance
	local self = Object.new(Name)
	setmetatable(self, StatsHandlerInterface)
	return self
end

--[[
This function increases the players hunger stat by FoodRegen amount
	if foodregen exceeds the config for max hunger then it is set to max hunger
	@param FoodRegen (number) the amount to increase hunger stat by
--]]
function StatsHandlerInterface:FeedPlayer(FoodRegen: number) : ()
	--Up food stat by regen amount or max amount if greater than max amount
	FeedPlayerEvent:Fire(FoodRegen)
end

--[[
This function increases the players hydration stat by HydrationRegen amount
	if HydrationRegen exceeds the config for max hunger then it is set to max hydration
	@param HydrationRegen (number) the amount to increase Hydration stat by
--]]
function StatsHandlerInterface:HydratePlayer(HydrationRegen: number) : ()
	--Up water stat by regen amount or max amount if greater than max amount
	HydratePlayerEvent:Fire(HydrationRegen)
end

return StatsHandlerInterface