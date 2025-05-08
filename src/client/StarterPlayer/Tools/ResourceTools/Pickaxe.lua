--[[
This class handles the behavior of all pickaxe's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ResourceTool = require(script.Parent.ResourceTool)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local Pickaxe = {}
ResourceTool:Supersedes(Pickaxe)

--Events
local HandleAxeStrikeEvent: ExtType.Bridge = BridgeNet2.ReferenceBridge("GiveOre")

--[[
Constructor for a pick axe instance
	@param Name (String) name of the pickaxe
	@param PhysTool (Tool) the physical tool of the pickaxe
--]]
function Pickaxe.new(Name: string, PhysTool: Tool): ExtType.ObjectInstance
	local self = ResourceTool.new(Name, PhysTool)
	setmetatable(self, Pickaxe)
	local swingAnim: AnimationTrack = self.__Animations["PickaxeSwing"]
	if not swingAnim then
		warn("Attemot to make instance of Picaxe but tool has no animation called PickaxeSwing")
		return self
	end
	--Set up swingAnim
	swingAnim.Priority = Enum.AnimationPriority.Action2
	self.__ActivationRadious = 8
	return self
end

--Common vars
local player: Player = Players.LocalPlayer
local mouse: Mouse = player:GetMouse()

--[[
Checks if player is within Radius of player
	@param Target (BasePart) ore part to check for within distance
	@param MaxDistance (number) max distance to check for
	@return (boolean) true on within distance or false otherwise
--]]
local function WithinDistance(Target: BasePart, MaxDistance: number): boolean
	local character: Model? = player.Character
	if not character then
		return false
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
	@param Target (BasePart) ore part top do sound for
	@param Self (ExtType.ObjectInstance) the instance of this class
--]]
local function StrikeSound(Target: BasePart, Self: ExtType.ObjectInstance): ()
	local soundId: number? = Target:GetAttribute("StrikeSoundID") :: number?
	if not soundId then
		return--No Strike sound set
	end
	local sound: Sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Parent = Target
	sound:Play()
	--Destroy to prevent memory leaks
	Self.__Connections["StrikeSound"] = sound.Ended:Once(function()
		sound:Destroy()
	end)
end

--[[
Decreases integrity and gives reward on last strike
	@param Target (BasePart) ore part that player hits
	@param Effectiveness (number) the pickaxes Effectiveness
	@param Self (ExtType.ObjectInstance) the instance of this class
	@return (boolean) true on last strike false otherwise
--]]
local function HandleIntegrity(Target: BasePart, Effectiveness: number, Self: ExtType.ObjectInstance): boolean
	local integrity: number = Target:GetAttribute("Integrity") :: number
	local newIntegrity: number = integrity - Effectiveness
	if newIntegrity <= 0 then
		--Give ore if last strike
		--Hide ore while sound then destroy to prevent audio issues
		local collectSoundID: number? = Target:GetAttribute("CollectSoundID") :: number?
		if collectSoundID ~= nil then
			Target.Transparency = 1
			Target.CanCollide = false
			local sound: Sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://" .. collectSoundID
			sound.Parent = Target
			sound:Play()
			print("Played audio!")
			--Destroy to prevent memory leaks
			Self.__Connections["FinishedSound"] = sound.Ended:Once(function()
				sound:Destroy()
				Target:Destroy()
			end)
		else
			--No sound so just destroy
			Target:Destroy()
		end
		return true
	else
		--Lower integrity
		Target:SetAttribute("Integrity", newIntegrity)
		return false
	end
end

--[[
Gives the player the given resource
	@param Target (BasePart) ore part that player hits
--]]
local function GiveResource(Target: BasePart)
	local ore: string? = Target:GetAttribute("Ore") :: string?
	if not ore then
		warn("Could not give ore to player because ore attribute not set for target \"" .. Target.Name .. "\"")
		return
	end
	local count: number? = Target:GetAttribute("Count") :: number?
	if not count then
		warn("Could not give ore to player because Count attribute not set for target \"" .. Target.Name .. "\"")
		return
	end
	--Put item in players backpack here
	local args = {
		Amount = count,
		Ore = ore
	}
	HandleAxeStrikeEvent:Fire(args)
end

--[[
Plays the animation when mining the given target
	@param Target (BasePart) ore part that player hits
	@param SwingAnim (AnimationTrack) the swing animation track of the pickaxe
--]]
local function PlayAnimation(Target: BasePart, SwingAnim: AnimationTrack) : ()
	local character: Model? = player.Character
	if not character then
		return
	end

	--Turn player to target
	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		local endFrame: CFrame = CFrame.lookAt(rootPart.Position, Target.Position)
		local tweenInfo: TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween: Tween = TweenService:Create(rootPart, tweenInfo, { CFrame = endFrame })
		tween:Play()
	end

	SwingAnim:Play()
end

--[[
Determines the behaivore of the pick axe when activated by the player
	@return (boolean) true on success false otherwise
--]]
function Pickaxe:Activate()
	--Check for cooldown
	if self.__ProtFuncs.IsOnCoolDown(self) then
		return --Is on cooldown
	end

	if not self.__Effectiveness then
		return --No effectiveness attribute set
	end

	local target: BasePart = mouse.Target
	--Check for if target was allowed ore else void
	if not self:CanInteract(target) then
		return
	end

	--Make sure target has integrity set
	if not target:GetAttribute("Integrity") then
		warn("Could not mine target \"" .. target.Name .. "\" because target has no integrity set")
		return --not set
	end
	--Check player distance
	if not WithinDistance(target, self.__ActivationRadious) then
		return
	end

	local swingAnim: AnimationTrack? = self.__Animations["PickaxeSwing"]
	if not swingAnim then
		return
	end
	--Activate pickaxe
	PlayAnimation(target, swingAnim)
	--Activate cooldown
	self.__ProtFuncs.CoolDown(self)
	self.__Connections["SwingStop"] = swingAnim.Stopped:Once(function()
		--Determine behaivore by ore type
		--Reduce integrity
		StrikeSound(target, self)
		local destroyed: boolean = HandleIntegrity(target, self.__Effectiveness, self)
		if destroyed then
			--Give resource
			GiveResource(target)
		end
	end)
end

--[[
Cleans up the given tool instance.
    DOES NOT destroy the tool given to the cosntructor.
    The physical tool is preserved.
    Not using this function with a given instance may lead to both memory leaks
    and also undefined behaivore.
--]]
function Pickaxe:DestroyInstance() : ()
	--Clean up connections
	for _, connection in pairs(self.__Connections) do
		connection:Disconnect()
	end
	--Clean up tasks
	for _, thread in pairs(self.__Tasks) do
		task.cancel(thread)
	end
    self = nil
end

return Pickaxe
