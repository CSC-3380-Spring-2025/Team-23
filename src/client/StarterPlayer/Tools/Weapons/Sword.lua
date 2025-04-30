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

--[[
The constructor for the Tools class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool of the weapon being used
--]]
function Sword.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance
    local self = Weapon.new(Name, PhysTool)
	setmetatable(self, Sword)
	return self
end

function HandleHits(Self)
    local hitbox = Self.__Hitbox
    local damage = Self.__Damage
    Self.__Connections["Hit"] = hitbox.OnHit:Connect(function(HitPart: BasePart, HitHum: Humanoid)
        local character = HitHum.Parent
        if playerUtilities:CanAttack(character) then
            --tell server to damage player
            DmgTarget:Fire(damage)
        end
    end)
end

--[[
Activates the tool given in the constructor
--]]
function Sword:Activate() : ()
    local swingAnim: AnimationTrack? = self.__Animations["Swing"]
    if swingAnim == nil then
        warn("Attempt to activate sword but sword was missing Animation Swing")
        return
    end
    if not self.__Hitbox then
        warn("Attempt to activate sword but sword was missing Hitbox for RaycastHitboxV4")
        return
    end
    local sword: Tool = self.__Tool
end

--[[
Cleans up the given tool instance.
    DOES NOT destroy the tool given to the cosntructor.
    The physical tool is preserved.
    Not using this function with a given instance may lead to both memory leaks
    and also undefined behaivore.
--]]
function Sword:DestroyInstance() : ()
    
end

return Sword