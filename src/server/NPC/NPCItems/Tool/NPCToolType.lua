--[[
This class provides the common interface for all tool items
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolType = require(ReplicatedStorage.Shared.Items.Tool.ToolType)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local NPCToolType = {}
ToolType:Supersedes(NPCToolType)

function NPCToolType.new(Name, Weight, MaxStack, ItemName)
    local self = ToolType.new(Name, Weight, MaxStack, ItemName)
    setmetatable(self, NPCToolType)
    return self
end

function NPCToolType:Activate() : ()
    AbstractInterface:AbstractError("Activate", "NPCToolType")
end

return NPCToolType