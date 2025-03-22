--Services
local Players : Players = game:GetService("Players")
local Object = require(game.ReplicatedStorage.Shared.Utilities.Object.Object)
--Variables
local Handler = {}
Handler.__index = Handler
Object:Supersedes(Handler)

local ToolStorage : Folder = game.ServerScriptService.Server.Items

local Tools : array = {} -- Storage for tool modules for easily figuring out things like size without making a new object

-- Functions



function Handler.new(Name)
	local self: table = setmetatable({}, Handler)
	self.Name = Name or "Item"
	self.Amount = Amount or 0
	return self
end


return Handler