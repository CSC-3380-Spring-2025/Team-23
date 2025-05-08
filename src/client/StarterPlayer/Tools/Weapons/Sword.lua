--[[
This script defines an abstract interface required for all sword tools.
Any tool child simply manipulates and uses the given tool instance.
The user is responsible for cloning and handing a given tool instance to the constructor.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local PlayerUtilitiesObject = require(script.Parent.Parent.Parent.PlayerUtilities)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local ClientMutexSeqObject = require(script.Parent.Parent.Parent.ClientUtilities.ClientMutexSeq)
local Weapon = require(script.Parent.Weapon)
local Sword = {}
Weapon:Supersedes(Sword)

--Events
local DmgTarget: ExtType.Bridge = BridgeNet2.ReferenceBridge("DamageTargetCombat")

--Instances
local playerUtilities: ExtType.ObjectInstance = PlayerUtilitiesObject.new("PlayerUtilitiesSword")

--Vars
local swordCoolDown: number = 3 --Time it takes for sword to cool down if less than swingAnim time
local swordCount: number = 0 --The number of swords equipped so far

--[[
Helper function that manages what happens when a sword hits somthing
    @param Self (ExtType.ObjectInstance) Instance of this class
--]]
local function HandleHits(Self: ExtType.ObjectInstance) : ()
	local hitbox: ExtType.RaycastHitbox = Self.__Hitbox
	local damage: number = Self.__Damage
	Self.__Connections["Hit"] = hitbox.OnHit:Connect(function(HitPart: BasePart, HitHum: Humanoid)
		local character: Model = HitHum.Parent :: Model
		if playerUtilities:CanAttack(character) then
			--tell server to damage player
			local dmgTargetArgs: ExtType.StrDict = {
				Damage = damage,
				DmgHum = HitHum,
			}
			DmgTarget:Fire(dmgTargetArgs)
		end
	end)
end

--[[
Given the swingAnim set for the sword, the cooldown time is comapred to the default cooldown time.
    The max cooldown time allowed is returned
    @param SwingAnim (AnimationTrack) the swing animation track
--]]
local function MakeCoolDown(SwingAnim: AnimationTrack): number
	local animationTime: number = SwingAnim.Length
	if animationTime <= swordCoolDown then
		return swordCoolDown
	else
		return animationTime
	end
end

--[[
The constructor for the Tools class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool of the weapon being used
--]]
function Sword.new(Name: string, PhysTool: Tool): ExtType.ObjectInstance?
	local self = Weapon.new(Name, PhysTool)
	setmetatable(self, Sword)
	--Set up swing anim priority
	local swingAnim: AnimationTrack? = self.__Animations["SwordSwing"]
	if swingAnim == nil then
		warn("Attempt to make sword instance but sword was missing Animation Swing")
		return nil
	else
		swingAnim.Priority = Enum.AnimationPriority.Action2
	end
	self.__CoolDownTime = MakeCoolDown(swingAnim)
	self.__OnCoolDown = false --Indicates weather the tool is on cooldown
	self.__CoolDownLockKey = "SwordCoolDown" .. swordCount
	self.__CoolDownLock = ClientMutexSeqObject.new(self.__CoolDownLockKey)
	swordCount = swordCount + 1
	return self
end

--[[
Ends the current attack swing.
    @param Self (ExtType.ObjectInstance) the instance of this class
    @param Animation (AnimationTrack) the animation track being played
    @param Hitbox (ExtType.RaycastHitbox) the RaycastHitboxV4 instance
--]]
local function EndAttack(Self: ExtType.ObjectInstance, Animation: AnimationTrack, Hitbox: ExtType.RaycastHitbox): ()
	Animation.Stopped:Wait()
	Hitbox:HitStop()
end

--[[
Helper function that manages the cool down of the sword
    @param Self (ExtType.ObjectInstance) the instance of this class
--]]
local function CoolDown(Self: ExtType.ObjectInstance) : ()
	Self.__Tasks["CoolDown"] = task.spawn(function()
		Self.__CoolDownLock:Lock()
		Self.__OnCoolDown = true
		Self.__CoolDownLock:Unlock()
		task.wait(Self.__CoolDownTime)
		Self.__CoolDownLock:Lock()
		Self.__OnCoolDown = false
		Self.__CoolDownLock:Unlock()
	end)
end

--[[
Determines of this sword instance is on cool down or not
    @param Self (ExtType.ObjectInstance) the instance of this class
    @return (boolean) true if on cooldown or false otherwise
--]]
local function IsOnCoolDown(Self: ExtType.ObjectInstance): boolean
	Self.__CoolDownLock:Lock()
	local coolDown: boolean = Self.__OnCoolDown
	Self.__CoolDownLock:Unlock()
	return coolDown
end

--[[
Activates the tool given in the constructor
--]]
function Sword:Activate(): ()
	if not self.__Hitbox then
		warn("Attempt to activate sword but sword was missing Hitbox for RaycastHitboxV4")
		return
	end
	if IsOnCoolDown(self) then
		return --on cool down so cant activate
	end
	CoolDown(self)--Handle cooldown
	local swingAnim: AnimationTrack = self.__Animations["SwordSwing"]
	HandleHits(self)
	local hitbox: ExtType.RaycastHitbox = self.__Hitbox
	hitbox:HitStart()
	swingAnim:Play()
	EndAttack(self, swingAnim, hitbox)
end

--[[
Cleans up the given tool instance.
    DOES NOT destroy the tool given to the cosntructor.
    The physical tool is preserved.
    Not using this function with a given instance may lead to both memory leaks
    and also undefined behaivore.
--]]
function Sword:DestroyInstance(): ()
	--Clean up connections
    if self.__Connections["Hit"] then
        self.__Connections["Hit"]:Disconnect()
    end
end

return Sword
