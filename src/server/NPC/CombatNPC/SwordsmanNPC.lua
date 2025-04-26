local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RaycastHitboxV4 = require(ReplicatedStorage.RaycastHitboxV4)
local CombatNPC = require(ServerScriptService.Server.NPC.CombatNPC.CombatNPC)
local SwordsmanNPC = {}
CombatNPC:Supersedes(SwordsmanNPC)

function SwordsmanNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxStack: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	WhiteList: { string },
	Backpack: {}?,
	EncumbranceSpeed: {}?,
	DeathHandler: any,
	StatsConfig: {}?
)
	local self = CombatNPC.new(
        Name,
        Rig,
        Health,
        SpawnPos,
        Speed,
        MaxStack,
        MaxWeight,
        MediumWeight,
        HeavyWeight,
        WhiteList,
        Backpack,
        EncumbranceSpeed,
        StatsConfig
    )
    setmetatable(self, SwordsmanNPC)
    --Load animations
    return self
end

local function HandleHits(HitBox, Self, Damage)
    Self.__Connections["Hit"] = HitBox.OnHit:Connect(function(HitPart, HitHum)
        print("SWORD HIT!")
        print(HitPart, HitHum)
        HitHum:TakeDamage(20)
    end)
end

local function CleanUpAttack(HitBox, Animation, Self)
    Animation.Stopped:Wait()
    Self.__Connections["Hit"]:Disconnect()--Disc hit connection
    HitBox:HitStop()
end

--[[
This function defines the behaivore of the Combat NPC when they activate their weapon.
    Assumes that the NPC already has a sword equipped
--]]
function SwordsmanNPC:Attack()
    local weapon = self.__Weapon
    if not weapon then
        warn("Attempt to attack with SwordsmanNPC but no weapon set")
        return
    end
    local swingAnim = weapon.Animations["Swing"]
    if not swingAnim then
        warn("Swing animations not in Animations folder of weapon for NPC \"" .. self.Name .. "\"")
        return
    end
    local hitBox = weapon.Hitbox
    if not hitBox then
        warn("Hitbox not set for tool of NPC \"" .. self.Name .. "\"")
        return
    end

    --Activate weapon
    local physTool = weapon.DropItem
    local damage = physTool:GetAttribute("Damage")
    if not damage then
        warn("Damage attribute not set for tool of NPC \"" .. self.Name .. "\"")
        return
    end
    HandleHits(hitBox, self, damage)
    swingAnim:Play()
    hitBox:HitStart()
    CleanUpAttack(hitBox, swingAnim, self)
end

return SwordsmanNPC