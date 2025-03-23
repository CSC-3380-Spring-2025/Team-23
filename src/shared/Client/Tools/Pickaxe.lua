--[[
This class handles the behavior of all pickaxe's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Pickaxe = {}
Object:Supersedes(Pickaxe)

--[[
Constructor for a pick axe instance
	Name (String) name of the pickaxe
	Tool (Tool) tool to be scripted for
	CoolDown (number) cool down time 
	Radious (number) number in studs you have to be in to mine an object
	Effectiveness (number) damage done to an object with each blow
	WhiteList ({string}) tables of strings that represent the types of ore whitelsited
--]]
function Pickaxe.new(Name: string, Tool: Tool, CoolDown: number, Radious: number, Effectiveness: number, WhiteList: {string}?)
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
local pickaxeAnimation: Animation = Instance.new("Animation")
pickaxeAnimation.AnimationId = "rbxassetid://" .. 97711803196266
local oreCollectedSound: number = 3908308607
local player: Player = Players.LocalPlayer
local mouse: Mouse = player:GetMouse()

--[[
Helper function that plays a given animation for pickaxe use
	@param Animation (Animaiton) animation to play for player
	@param Target (BasePart) the ore target the player is mining to turn to.
	@return (AnimationTrack) the track set up and played
--]]
local function PlayAnimation(Animation: Animation, Target: BasePart) : AnimationTrack?
	local character: Model? = player.Character
	if not character then
		return nil
	end

	--Turn player to target
	local rootPart: any = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local endFrame: CFrame = CFrame.lookAt(rootPart.Position, Target.Position)
		local tweenInfo: TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween: Tween = TweenService:Create(rootPart, tweenInfo, { CFrame = endFrame })
		tween:Play()
	end

	local humanoid: any = character:FindFirstChild("Humanoid")
	if not character then
		return nil
	end
	local animator: Animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return nil
	end

	local animTrack: AnimationTrack = animator:LoadAnimation(Animation)
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

--[[
Helper function that checks whitelist for given ore
	@param OreObject (BasePart) the ore part to mine
	@param List ({string}) table of stirngs of whitelisted ore types
	@return (boolean) true on found or falsew otherwise
--]]
local function CheckList(OreObject: BasePart, List: {string}?) : boolean
	if List == nil then
		return true --Vacuously true because no list
	end

	local foundListed: boolean = false
	--Check for if ore is in whitelist
	for _, listed in pairs(List) do
		if CollectionService:HasTag(OreObject, listed) then
			foundListed = true
			break
		end
	end
	return foundListed
end

--[[
Checks if player is within radious of player
	@param Target (BasePart) ore part to check for within distance
	@param MaxDistance (number) max distance to check for
	@return (boolean) true on within distance or false otherwise
--]]
local function WithinDistance(Target: BasePart, MaxDistance: number) : boolean?
	local character: Model? = player.Character
	if not character then
		return nil
	end

	--Check target distance
	local rootPart: any = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		if (rootPart.Position - Target.Position).Magnitude <= MaxDistance then
			return true
		end
	end

	return false
end

--[[
Helper function that plays on strike
	@param SoundId (number) id of sound
	@param Target (BasePart) ore part top do sound for
--]]
local function StrikeSound(SoundId: number, Target: BasePart) : ()
	local sound: Sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. SoundId
	sound.Parent = Target
	sound:Play()
	print("Played audio!")
	--Destroy to prevent memory leaks
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

--[[
Decreases integrity and gives reward on last strike
	@param Target (BasePart) ore part that player hits
	@param Effectiveness (number) the pickaxes Effectiveness
	@return (boolean) true on last strike fals eotherwise
--]]
local function HandleIntegrity(Target: BasePart, Effectiveness: number) : boolean
	local integrity: number = Target:GetAttribute("Integrity")
	local newIntegrity: number = integrity - Effectiveness
	if newIntegrity <= 0 then
		--Give Coal if last strike
        --Hide ore while sound then destroy to prevent audio issues
		Target.Transparency = 1
		local sound: Sound = Instance.new("Sound")
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

--[[
Helper function that determiens behaivor of iron
	@param Target (BasePart) the ore part being hit
	@param Positon (Vector3) position of target
	@param Effectiveness (number) damage done to target
--]]
local function Iron(Target: BasePart, Position: Vector3, Effectiveness: number) : ()
	StrikeSound(7650220708, Target)
	local finished: boolean = HandleIntegrity(Target, Effectiveness)
	if finished then
		--Give Iron
	end
	print(Target.Name .. " Is Iron!")
end

--[[
Helper function that determiens behaivor of Coal
	@param Target (BasePart) the ore part being hit
	@param Positon (Vector3) position of target
	@param Effectiveness (number) damage done to target
--]]
local function Coal(Target: BasePart, Position: Vector3, Effectiveness: number)
	StrikeSound(7650220708, Target)
	local finished: boolean = HandleIntegrity(Target, Effectiveness)
	if finished then
		--Give coal
	end
	print(Target.Name .. " Is Coal!")
end

--[[
Determines the behaivore of the pick axe when activated by the player
	@return (boolean) true on success false otherwise
--]]
function Pickaxe:Activate() : boolean
	--Check for cooldown
	if self.__Cooled == false then
		return false
	end

	local target: any = mouse.Target
	local position: Vector3 = mouse.Hit.Position

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

	local animTrack: AnimationTrack? = PlayAnimation(pickaxeAnimation, target)
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

--[[
Triggers a cooldown for the pickaxe
--]]
function Pickaxe:CoolDown() : ()
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
