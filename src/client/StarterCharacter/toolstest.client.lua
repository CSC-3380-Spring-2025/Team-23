local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pickaxe = require(ReplicatedStorage.Shared.Client.Tools.Pickaxe)

local Players = game:GetService("Players")

local me = Players:WaitForChild("claytakiler")
local pickAxeItems = ReplicatedStorage.Tools.Animation.Pickaxe
local motor6d = pickAxeItems.Pickaxe6d
local myPickaxeTool = me.Backpack:WaitForChild("Pickaxe")
local character = me.Character or me.CharacterAdded:Wait()
local rightHand = character:FindFirstChild("RightHand")

local isFirst = true

if isFirst then
    local clone6d = motor6d:Clone()
    local mesh = myPickaxeTool:FindFirstChild("Pickaxe")
    clone6d.Part1 = mesh
    clone6d.Part0 = rightHand
    clone6d.Parent = rightHand 
    isFirst = false
end

local myPickaxe = Pickaxe.new("Pickaxe 1", myPickaxeTool)

print(myPickaxe.Name)

myPickaxeTool.Activated:Connect(function()
    myPickaxe:Activated()
end)