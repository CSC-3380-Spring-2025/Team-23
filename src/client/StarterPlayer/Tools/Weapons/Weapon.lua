--[[
This script defines an abstract interface required for all weapon tools.
Any tool child simply manipulates and uses the given tool instance.
The user is responsible for cloning and handing a given tool instance to the constructor.
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local RaycastHitboxV4 = require(ReplicatedStorage.RaycastHitboxV4)
local Tool = require(script.Parent.Parent.Tool)
local Weapon = {}
Tool:Supersedes(Weapon)

--[[
Prepares a weapons hit box if it exists
    @param WeaponRef ({[string]: any}) a refrence to the item in self.__Backpack
    @return (ExtType.RaycastHitbox?) a RaycastHitbox if hitbox exists or nil otherwise
--]]
local function PrepHitbox(Weapon: Tool, Self: ExtType.ObjectInstance) : ExtType.RaycastHitbox?
    local hitboxPart: BasePart? = Weapon:FindFirstChild("Hitbox") :: BasePart?
    if not hitboxPart then
        --Weapon has no hitbot
        return nil
    end
    return RaycastHitboxV4.new(hitboxPart)
end

--[[
The constructor for the Tools class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool in workspace being used
    does not copy the given tool but uses it directly
--]]
function Weapon.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance
    local self = Tool.new(Name, PhysTool)
	setmetatable(self, Weapon)
    --Set up hit box
    self.__Hitbox = PrepHitbox(PhysTool, self)
    --Get damage
    local damage: number? = PhysTool:GetAttribute("Damage") :: number?
    if damage == nil then
        warn("Attempt to set up Weapon instance but damage attribute was not set")
        return self
    end
    self.__Damage = PhysTool
	return self
end

return Weapon