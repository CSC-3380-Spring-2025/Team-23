local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Pickaxe = {}
Object:Supersedes(Pickaxe)

function Pickaxe.new(Name, Tool, CoolDown)
	local self = Object.new(Name)
	setmetatable(self, Pickaxe)
	self.__Tool = Tool
	self.__CoolDown = CoolDown
	self.__Cooled = true
	return self
end

--Common vars
local pickaxeAnimation = Instance.new("Animation")
pickaxeAnimation.AnimationId = "rbxassetid://" .. 97711803196266

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local effectiveDistance = 5 --studs. Determines distance you can mine from
local coolDown = 0 --Seconds

local function StrikeSound(SoundId, Target)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. SoundId
	sound.Parent = Target
	sound:Play()
	print("Played audio!")
	--Destroy to prevent memory leaks
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

--Below fucntions are helper fucntions that specify behaivor of each ore type

local function Iron(Target, Position)
	StrikeSound(7650220708, Target)
	print(Target.Name .. " Is Iron!")
end

local function Coal(Target, Position)
	StrikeSound(7650220708, Target)
	print(Target.Name .. " Is Coal!")
end

local function PlayAnimation(Animation)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChild("Humanoid")
	if not character then
		return nil
	end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return nil
	end

	local animTrack = animator:LoadAnimation(Animation)
	task.spawn(function()
		animTrack.Priority = Enum.AnimationPriority.Action
		--animTrack.PlaybackSpeed = animTrack.Length / swingTime
		animTrack:Play()
		animTrack.Stopped:Once(function()
			animTrack:Destroy()
		end)
	end)

	return animTrack
end

--[[
Determines the behaivore of the pick axe when activated by the player
--]]
function Pickaxe:Activate()
	--Check for cooldown
	if self.__Cooled == false then
		return
	end

	local target = mouse.Target
	local position = mouse.Hit.Position

	--Check for if target was ore else void
	if not CollectionService:HasTag(target, "Ore") then
		return
	end

	local animTrack = PlayAnimation(pickaxeAnimation)
	if not animTrack then
		return
	end

	animTrack.Stopped:Once(function()
		--Determine behaivore by ore type
		if CollectionService:HasTag(target, "Iron") then --Iron
			Iron(target, position)
		elseif CollectionService:HasTag(target, "Coal") then --Coal
			Coal(target, position)
		end
	end)
end

function Pickaxe:CoolDown()
	task.spawn(function()
		if self.__Cooled == false then
			return --Already doing a cooldown
		end
		self.__Cooled = false
		task.wait(self.__CoolDown)
		self.__Cooled = true
	end)
end

function Pickaxe:TransferToPlayer() end

function Pickaxe:TransferToStorage() end

return Pickaxe
