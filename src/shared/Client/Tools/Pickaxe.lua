local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Pickaxe = {}
Object:Supersedes(Pickaxe)

function Pickaxe.new(Name, Tool, CoolDown, Radious, Effectiveness, WhiteList)
	local self = Object.new(Name)
	setmetatable(self, Pickaxe)
	self.__Tool = Tool
	self.__CoolDown = CoolDown or 0
	self.__Cooled = true
	self.__Radious = Radious
	self.__WhiteList = WhiteList or nil
	self.__Effectiveness = Effectiveness or error('No "Effectiveness" provided for pickaxe constructor.')
	return self
end

--Common vars
local pickaxeAnimation = Instance.new("Animation")
pickaxeAnimation.AnimationId = "rbxassetid://" .. 97711803196266
local oreCollectedSound = 3908308607
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function PlayAnimation(Animation, Target)
	local character = player.Character
	if not character then
		return nil
	end

	--Turn player to target
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local endFrame = CFrame.lookAt(rootPart.Position, Target.Position)
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(rootPart, tweenInfo, { CFrame = endFrame })
		tween:Play()
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
	animTrack.Priority = Enum.AnimationPriority.Action
	task.spawn(function()
		--animTrack.PlaybackSpeed = animTrack.Length / swingTime
		animTrack:Play()
		animTrack.Stopped:Once(function()
			animTrack:Destroy()
		end)
	end)

	return animTrack
end

local function CheckList(OreObject, List)
	if List == nil then
		return true --Vacuously true because no list
	end

	local foundListed = false
	--Check for if ore is in whitelist
	for _, listed in pairs(List) do
		if CollectionService:HasTag(OreObject, listed) then
			foundListed = true
			break
		end
	end
	return foundListed
end

local function WithinDistance(Target, MaxDistance)
	local character = player.Character
	if not character then
		return nil
	end

	--Check target distance
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		if (rootPart.Position - Target.Position).Magnitude <= MaxDistance then
			return true
		end
	end

	return false
end

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

local function HandleIntegrity(Target, Effectiveness)
	local integrity = Target:GetAttribute("Integrity")
	local newIntegrity = integrity - Effectiveness
	if newIntegrity <= 0 then
		--Give Coal if last strike
        --Hide ore while sound then destroy to prevent audio issues
		Target.Transparency = 1
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. oreCollectedSound
		sound.Parent = Target
		sound:Play()
		print("Played audio!")
		--Destroy to prevent memory leaks
		sound.Ended:Once(function()
			sound:Destroy()
            Target:Destroy()
		end)
		return true
	else
		--Lower integrity
		Target:SetAttribute("Integrity", newIntegrity)
		return false
	end
end

--Below functions are helper functions that specify behaivor of each ore type

local function Iron(Target, Position, Effectiveness)
	StrikeSound(7650220708, Target)
	local finished = HandleIntegrity(Target, Effectiveness)
	if finished then
		--Give Iron
	end
	print(Target.Name .. " Is Iron!")
end

local function Coal(Target, Position, Effectiveness)
	StrikeSound(7650220708, Target)
	local finished = HandleIntegrity(Target, Effectiveness)
	if finished then
		--Give coal
	end
	print(Target.Name .. " Is Coal!")
end

--[[
Determines the behaivore of the pick axe when activated by the player
--]]
function Pickaxe:Activate()
	--Check for cooldown
	if self.__Cooled == false then
		return false
	end

	local target = mouse.Target
	local position = mouse.Hit.Position

	--Check player distance
	if not WithinDistance(target, self.__Radious) then
		return false
	end

	--Check for if target was ore else void
	if not CollectionService:HasTag(target, "Ore") then
		return false
	end

	--Check whitelist
	if not CheckList(target, self.__WhiteList) then
		return false --Is not a white listed ore so void
	end

	local animTrack = PlayAnimation(pickaxeAnimation, target)
	if not animTrack then
		return false
	end

	animTrack.Stopped:Once(function()
		--Determine behaivore by ore type
		if CollectionService:HasTag(target, "Iron") then --Iron
			Iron(target, position, self.__Effectiveness)
		elseif CollectionService:HasTag(target, "Coal") then --Coal
			Coal(target, position, self.__Effectiveness)
		end
	end)

	return true --Indicate success
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

return Pickaxe
