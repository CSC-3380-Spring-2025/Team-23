local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Pickaxe = {}
Object:Supersedes(Pickaxe)

function Pickaxe.new(Name, Tool)
    local self = Object.new(Name)
    setmetatable(self, Pickaxe)
    self.__Tool = Tool
    return self
end

--Common vars
local pickaxeAnimation = Instance.new("Animation")
pickaxeAnimation.AnimationId = "97711803196266"
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local effectiveDistance = 5--studs. Determines distance you can mine from

--Below fucntions are helper fucntions that specify behaivor of each ore type

local function Iron(Target, Position)
    print(Target.Name .. " Is Iron!")
end

local function Coal(Target, Position)
    print(Target.Name .. " Is Coal!")
end

--[[
Determines the behaivore of the pick axe when activated by the player
--]]
function Pickaxe:Activated()
    local target = mouse.Target
    local targetName = target.Name
    local position = mouse.Hit.Position

    --Check for if target was ore else void
    if not CollectionService:HasTag(target, "Ore") then
        return
    end

    --Determine behaivore by ore type
    if CollectionService:HasTag(target, "Iron") then --Silver
        Iron(target, position)
    elseif CollectionService:HasTag(target, "Coal") then
        Coal(target, position)
    end
end

function Pickaxe:TransferToPlayer()
    
end

function Pickaxe:TransferToStorage()
    
end

return Pickaxe