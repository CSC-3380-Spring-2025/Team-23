--Services
local Players : Players = game:GetService("Players")
--Variables
local ItemHandler : table = {} 
ItemHandler.__index = ItemHandler

local ToolStorage : Folder = game.ServerScriptService.Server.Items
local ItemData = require(script.Parent.ItemData)

local ModuleParent : any

local Tools : array = {} -- Storage for tool modules for easily figuring out things like size without making a new object


function ItemHandler:GetName() : string
	return self.__Name
end

function ItemHandler:Equip() : ()
	error("Equip function not implemented for this tool!")
end

function ItemHandler:Unequip() : ()
	error("Unequip function not implemented for this tool!")
end

function ItemHandler:Activate() : ()
	error("Activate function not implemented for this tool!")
end

function ItemHandler:FixTool(Amount) : ()
	self.__Durability = Amount or self.__MaxDurability
end

function ItemHandler:GetDurability() : number
	return self.__Durability
end

function ItemHandler:GetEffectiveness() : number
	return self.__Effectiveness
end

function ItemHandler:BreakTool(BreakSound : Sound)
	if BreakSound then
		BreakSound:Play()
	end
	self:DestroyTool(self.Player, self.ID)
	self = nil
end

function ItemHandler:DecreaseHealthByHit(Amount)
	self.__Durability -= Amount
	print("Decreased health by "..Amount)
	if self.__Durability <= 0 then
		self:BreakTool()
	end
end
-- Functions

function ItemHandler.new(Player, Name, Amount, Durability, Effectiveness)
	local self: table = ModuleParent.new(Name, Amount)
	setmetatable(self, ItemHandler) 
	self.Player = Player
	self.__Name = Name or error("No tool name defined!")
	self.__Effectiveness = Effectiveness or error("No tool effectiveness defined!")
	self.Amount = Amount or 1
	self.__IsTool = true
	self.ID = game:GetService("HttpService"):GenerateGUID()
	self.__Durability = Durability or 100
	self.__MaxDurability = Durability or 100
	self.__MaxStack = 1
	self.__Weight = Amount * ItemData[Name]["Weight"]; -- Weight of the object
	return self
end

function ItemHandler:Init(Parent)
	ModuleParent = Parent
	Parent:Supersedes(ItemHandler)
end

return ItemHandler