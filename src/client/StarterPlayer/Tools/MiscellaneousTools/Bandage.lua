--[[
This class handles what happens for a bandage tool
--]]

local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Tool = require(script.Parent.Parent.Tool)

local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local BackpackHandler = require(game.ServerScriptService.Server.Player.BackpackHandler)
local Bandage = {}

Tool:Supersedes(Bandage)

--Events
local HealPlayerEvent = BridgeNet2.ReferenceBridge("BandageHealPlayer")

--[[
The constructor for the Bandage class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool in workspace being used
    does not copy the given tool but uses it directly
--]]
function Bandage.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance
    local self = Tool.new(Name, PhysTool)
	setmetatable(self, Bandage)
    --Instance variable not already defined in the Tool class
    self.__Connections = {}--Table of all connections for the Tool
    self.__Tasks = {}--Table of all tasks for a tool
	return self
end

--[[
Defines the behaivore of a bandage when activated
--]]
function Bandage:Activate() : ()

    --fire event to heal player here with the amount to heal
    HealPlayerEvent:Connect(20)
    
end

--[[
Cleans up the given bandage instance.
    DOES NOT destroy the tool given to the cosntructor.
    The physical tool is preserved.
    Not using this function with a given instance may lead to both memory leaks
    and also undefined behaivore.
    You should cycle through the tables of self.__Tasks and self.__Connections and destroy them
    using their own roblox defined way of doing so like :Disconnect() and task.cancel(thread)
--]]
function Bandage:DestroyInstance() : ()
    BackpackHandler:DestroyItem(Player, "Bandage", 1)

    --Clean up self.__Tasks and self.__Connections tables defined from Tool class
end

return Bandage
