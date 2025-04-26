local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ToolNPC = require(ServerScriptService.Server.NPC.ToolNPC)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local ItemUtilsObject = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local RaycastHitboxV4 = require(ReplicatedStorage.RaycastHitboxV4)
local CombatNPC = {}
ToolNPC:Supersedes(CombatNPC)

--Instances
local itemUtils = ItemUtilsObject.new("CombatNPCItemUtils")

--[[
Constructor of the CombatNPC class
    @param AggroList ({string}) List of tags placed on a target that an NPC will check to see if it can Aggro
--]]
function CombatNPC.new(
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
	StatsConfig: {}?,
    AggroList: {string}
)
	local self = ToolNPC.new(
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
		false,
		StatsConfig
	)
    setmetatable(self, CombatNPC)
    self.__Weapon = nil --The NPCs current weapon. The weapon/tool equipped when attacking
    self.__IsAttacking = false--Indicates if the NPC is attacking
    self.__AggroList = AggroList or {}
    self.__Target = nil --The current target of an NPC
    return self
end

--[[
This function defines the behaivore of the Combat NPC when they activate their weapon.
--]]
function CombatNPC:Attack(Target: Instance)
    AbstractInterface:AbstractError("Attack", "CombatNPC")
end

--[[
Cancels an attack action.
--]]
function CombatNPC:CancelAttack()
    AbstractInterface:AbstractError("CancelAttack", "CombatNPC")
end

local function PrepHitbox(WeaponRef: {[string]: any})
    local physTool = WeaponRef.DropItem
    local hitboxPart = physTool:FindFirstChild("Hitbox")
    if not hitboxPart or WeaponRef.Hitbox then
        --Weapon has no hitbot or one is already set so can ignore
        return
    end
    WeaponRef.Hitbox = RaycastHitboxV4.new(hitboxPart)
    print("Showing hit box vals")
    print(WeaponRef.Hitbox)
end

--[[
This function selects a weapon from the NPCs backpack
    the item must already be present in the NPCs backpack
    the item must be of type Weapon
    @param WeaponName (string) the name of the weapon in the NPCs backpack
    @return (boolean) true on success or false otherwise
--]]
function CombatNPC:SelectWeapon(WeaponName: string) : boolean
    if self:CheckForItem(WeaponName) then
        --item exists in backpack
        if self.__Backpack[WeaponName].DropItem and self.__Backpack[WeaponName].DropItem:GetAttribute("Weapon") then
            --Valid choice
            self.__Weapon = self.__Backpack[WeaponName]
            --Prepare hitbox
            PrepHitbox(self.__Weapon)
            --Equip the weapon
            self:EquipTool(WeaponName)
            return true--Success
        else
            warn('Attempt to select weapon "' .. WeaponName ..  '" for NPC "' .. self.Name .. '" but item was not of type "Weapon"')
        end
    else
        warn('Attempt to select weapon "' .. WeaponName ..  '" for NPC "' .. self.Name  .. '" but weapon was not in backpack')
    end
    return false --Failed to select weapon
end

--[[
This function unselects the current weapon set.
    If this is called an NPC will not be able to use a weapon until SelectWeapon is used again
--]]
function CombatNPC:UnselectWeapon() : ()
    self.__Weapon = nil
end

--[[
Determines if an NPC can target a given instanc eby checking if its in its aggrolist
    @param Target (Instance) any instance acting as a target
    @return (boolean) true if valid or false otherwise
--]]
function CombatNPC:CanTarget(Target: Instance) : boolean
    for _, tagName in pairs(self.__AggroList) do
        if CollectionService:HasTag(Target, tagName) then
            return true--Is in aggrolist
        end
    end
    return false--Not in aggrolist
end

return CombatNPC