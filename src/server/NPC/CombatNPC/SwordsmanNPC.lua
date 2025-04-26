local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local RaycastHitboxV4 = require(ReplicatedStorage.RaycastHitboxV4)
local CombatNPC = require(ServerScriptService.Server.NPC.CombatNPC.CombatNPC)
local SwordsmanNPC = {}
CombatNPC:Supersedes(SwordsmanNPC)

--Vars
local attackRange = 5 --Distance in studs that the NPCs sword will activate

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

local function ActivateWeapon(Self)
    local weapon = Self.__Weapon
    if not weapon then
        warn("Attempt to attack with SwordsmanNPC but no weapon set")
        return
    end
    local swingAnim = weapon.Animations["Swing"]
    if not swingAnim then
        warn("Swing animations not in Animations folder of weapon for NPC \"" .. Self.Name .. "\"")
        return
    end
    local hitBox = weapon.Hitbox
    if not hitBox then
        warn("Hitbox not set for tool of NPC \"" .. Self.Name .. "\"")
        return
    end

    --Activate weapon
    local physTool = weapon.DropItem
    local damage = physTool:GetAttribute("Damage")
    if not damage then
        warn("Damage attribute not set for tool of NPC \"" .. Self.Name .. "\"")
        return
    end
    HandleHits(hitBox, Self, damage)
    swingAnim:Play()
    hitBox:HitStart()
    CleanUpAttack(hitBox, swingAnim, Self)
end

function SwordsmanNPC:CancelAttack(Self)
    if Self.__Tasks.Attack then
        --Handle target death by no longer attacking
        Self:Unfollow()
        --Instead of canceling attack allow it to end on its own to handle clean up
        Self.__IsAttacking = false
    end
end

--[[
This function defines the behaivore of the Combat NPC when they
    are given a target to attack
    If a homepoint is set they will return home once complete
    @param Target (Instance) any target instance to attack
--]]
function SwordsmanNPC:Attack(Target: Instance)
    local rootPart = Target:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return--has no root part to follow
    end
    --Handle target death
    local humanoid = Target:FindFirstChild("Humanoid")
    if not humanoid then
        return--No humanoid to track
    end
    humanoid.Died:Once(function()
        print("Target died!")
        self:CancelAttack(self)
    end)
    self:Follow(rootPart)
    --Keep checking if in range to attack
    self.__Tasks.Attack = task.spawn(function()
        self.__IsAttacking = true
        while self.__IsAttacking do
            if (self.__RootPart.Position - rootPart.Position).Magnitude <= attackRange then
                --Targets in range to attack
                ActivateWeapon(self)
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

--[[
Guards a specific area. If somthing comes within distance the NPC chaces after the target.
    If home point is set, after a target gets away or is killed it will return to the homepoint.
    If a homepoint is not set it will remain in its current pos
    @param AggroRadious (number) the radious in studs that the target must be in to pursue
    @param EscapeRadious (number) the radious in studs that when the target leaves,
    the NPC will stop going after the target
--]]
function SwordsmanNPC:SentryMode(AggroRadious: number, EscapeRadious: number) : ()
    
end

return SwordsmanNPC