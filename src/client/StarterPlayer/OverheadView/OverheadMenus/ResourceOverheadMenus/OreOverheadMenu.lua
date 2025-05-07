local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ResourceOverheadMenu = require(script.Parent.ResourceOverheadMenu)
local OreOverheadMenu = {}
ResourceOverheadMenu:Supersedes(OreOverheadMenu)

function OreOverheadMenu.new(MenuName: string, ResourceObject: BasePart, MinerNPCs: {Model}) : ExtType.ObjectInstance
    local self = ResourceOverheadMenu.new(MenuName, ResourceObject, MinerNPCs)
    setmetatable(self, OreOverheadMenu)
    return self
end

return OreOverheadMenu