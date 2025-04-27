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
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxStack (number) the number of stacks allowed for the backpack
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
    @param WhiteList ({string}) table of item names that may be added
    @param EncumbranceSpeed ({[Light, Medium, Heavy] = number}) a table of keys defined
    as Light, Medium, Heavy that have a value pair indicating the speed to go at each Encumbrance level
    if not provided then Light = -1/3speed, Heavy = -2/3 speed
	@param DeathHandler (boolean) if set to true enables the death handler for clean up or disables otherwise
	If you do not know what your doing, then you should set this to true.
	@param StatsConfig ({}) determines the config for the NPC's stats. Keys left out follow a default format
	see the table of statsconfig below in the cosntructor for more details in Backpack NPC
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
This function defines the behaivore of the Combat NPC when they
    are given a target to attack
    @param Target (Instance) any target instance to attack
--]]
function CombatNPC:Attack(Target: Instance) : ()
    AbstractInterface:AbstractError("Attack", "CombatNPC")
end

--[[
Cancels an attack action
--]]
function CombatNPC:CancelAttack() : ()
    AbstractInterface:AbstractError("CancelAttack", "CombatNPC")
end

--[[
Prepares a weapons hit box if it exists
    @param WeaponRef ({[string]: any}) a refrence to the item in self.__Backpack
--]]
local function PrepHitbox(WeaponRef: {[string]: any}) : ()
    local physTool: Tool = WeaponRef.DropItem
    local hitboxPart: BasePart? = physTool:FindFirstChild("Hitbox") :: BasePart?
    if not hitboxPart or WeaponRef.Hitbox then
        --Weapon has no hitbot or one is already set so can ignore
        return
    end
    WeaponRef.Hitbox = RaycastHitboxV4.new(hitboxPart)
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