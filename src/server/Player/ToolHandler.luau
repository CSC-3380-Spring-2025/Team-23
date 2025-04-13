--[[  
 * ToolHandler - Subclass of BackpackHandler and Superclass of all Tool items.  
 *  
 * This class represents functions that are common between all tools, regardless of function or use.
 * It extends from the BackpackHandler class.
]]


--Services
local Players : Players = game:GetService("Players")
--Variables
local ItemHandler : table = {} 
ItemHandler.__index = ItemHandler

local ToolStorage : Folder = game.ServerScriptService.Server.Items
local ItemData = require(script.Parent.ItemData) -- Common item datapoints, such as weight or max stack size.

local ModuleParent : any -- Defines the module's parent for extension.

local Tools : array = {} -- Storage for tool modules for easily figuring out things like size without making a new object

-- Functions

--[[
@Description: Placeholder for a required "Equip" function in every tool. Errors if not superceded.
]]
function ItemHandler:Equip() : ()
	error("Equip function not implemented for this tool!")
end
--[[
@Description: Placeholder for a required "Unequip" function in every tool. Errors if not superceded.
]]
function ItemHandler:Unequip() : ()
	error("Unequip function not implemented for this tool!")
end
--[[
@Description: Placeholder for a required "Activate" function in every tool. Errors if not superceded.
]]
function ItemHandler:Activate() : ()
	error("Activate function not implemented for this tool!")
end

--[[
@Description: Repairs the tool by the given amount, or simply maxes its durability if no value is provided.
@Param Amount (Number): The amount to be added to the item's durability. Leave blank for a full repair.
]]
function ItemHandler:FixTool(Amount : number) : ()
	self.__Durability = math.clamp(self.__Durability + Amount, 0, self.__MaxDurability) or self.__MaxDurability
end
--[[
@Description: Returns the tool's current durability.
@Return Durability (Number): The item's current durability.
]]
function ItemHandler:GetDurability() : number
	return self.__Durability
end
--[[
@Description: Returns the tool's current level.
@Return Effectiveness (Number): The item's current level.
]]
function ItemHandler:GetEffectiveness() : number
	return self.__Effectiveness
end
--[[
@Description: Breaks the tool via removing it from the backpack, regardless of durability.
@Param BreakSound (Sound): An optional sound that will be played when the item is destroyed.
]]
function ItemHandler:BreakTool(BreakSound : Sound) : ()
	if BreakSound then
		BreakSound:Play()
	end
	self:DestroyTool(self.Player, self.ID)
	self = nil
end
--[[
@Description: Decrease's the tool's durability by the given amount. If the durability is less than 0 after being decreased, it calls the BreakTool() function.
@Param Amount (Number): The amount to decrease the current tool's durability.
]]
function ItemHandler:DecreaseHealthByHit(Amount) : ()
	self.__Durability -= Amount
	if self.__Durability <= 0 then
		self:BreakTool()
	end
end

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

--[[
@Description: Initializes the ItemHandler and make sure that it is superceded by its parent module, BackpackHandler.
@Param Parent (Any): The parent module.
]]
function ItemHandler:Init(Parent : any) : ()
	ModuleParent = Parent
	Parent:Supersedes(ItemHandler)
end

return ItemHandler