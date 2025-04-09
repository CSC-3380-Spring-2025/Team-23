--[[
This class provides the common interface for all tool items
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemsInterface = require(ReplicatedStorage.Shared.Items.ItemsInterface)
local Tool = {}
ItemsInterface:Supersedes(Tool)

function Tool.new(Name, Weight, MaxStack, ItemName)
    local self = ItemsInterface.new(Name, Weight, MaxStack, "Tool", ItemName)
    setmetatable(self, Tool)
    return self
end



return Tool
