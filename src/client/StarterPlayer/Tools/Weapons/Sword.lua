--[[
This script defines an abstract interface required for all sword tools.
Any tool child simply manipulates and uses the given tool instance.
The user is responsible for cloning and handing a given tool instance to the constructor.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local PlayerUtilitiesObject = require(script.Parent.Parent.Parent.PlayerUtilities)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local Weapon = require(script.Parent.Weapon)
local Sword = {}
Weapon:Supersedes(Sword)

--Events
local DmgTarget: ExtType.Bridge = BridgeNet2.ReferenceBridge("DamageTargetCombat")

--Instances
local playerUtilities = PlayerUtilitiesObject.new("PlayerUtilitiesSword")

--Vars
local swordCoolDown = 10

function HandleHits(Self)
    local hitbox = Self.__Hitbox
    local damage = Self.__Damage
    Self.__Connections["Hit"] = hitbox.OnHit:Connect(function(HitPart: BasePart, HitHum: Humanoid)
        print("Hit a target!")
        local character = HitHum.Parent
        if playerUtilities:CanAttack(character) then
            --tell server to damage player
            print("CAN DAMAGE TARGET! AHHHHH")
            local dmgTargetArgs = {
                Damage = damage,
                DmgHum = HitHum
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
local function MakeCoolDown(SwingAnim: AnimationTrack) : number
    local animationTime = SwingAnim.Length
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
function Sword.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance?
    local self = Weapon.new(Name, PhysTool)
	setmetatable(self, Sword)
    --Set up swing anim priority
    local swingAnim: AnimationTrack? = self.__Animations["Swing"]
    if swingAnim == nil then
        warn("Attempt to make sword instance but sword was missing Animation Swing")
        return nil
    else
        swingAnim.Priority = Enum.AnimationPriority.Action2
    end
    self.__CoolDown = MakeCoolDown(swingAnim)
	return self
end

--[[
Ends the current attack swing.
    @param Self (ExtType.ObjectInstance) the instance of this class
    @param Animation (AnimationTrack) the animation track being played
    @param Hitbox (ExtType.RaycastHitbox) the RaycastHitboxV4 instance
--]]
local function EndAttack(Self: ExtType.ObjectInstance, Animation: AnimationTrack, Hitbox: ExtType.RaycastHitbox) : ()
    Animation.Stopped:Wait()
    Hitbox:HitStop()
end

--[[
Activates the tool given in the constructor
--]]
function Sword:Activate() : ()
    print("SWORD WAS ACTIVATED!")
    if not self.__Hitbox then
        warn("Attempt to activate sword but sword was missing Hitbox for RaycastHitboxV4")
        return
    end
    local swingAnim: AnimationTrack = self.__Animations["Swing"]
    HandleHits(self)
    local hitbox = self.__Hitbox
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
function Sword:DestroyInstance() : ()
    --Clean up connections
    self.__Connections["Hit"]:Disconnect()
end

return Sword