--[[  
 * Axe - Subclass of ToolHandler 
 *  
 * This class is meant to be an example of how to make a tool class.
 * This class extends ToolHandler.
]]

local Handler = require(game.ServerScriptService.Server.Player.ToolHandler)
local Axe = {}
Handler:Supersedes(Axe)

--[[
@Description: Example Activate function that prints a success message when called.
]]
function Axe:Activate() : ()
	print("Activated Axe")
end
--[[
@Description: Example Equip function that prints a success message when called.
]]
function Axe:Equip() : ()
	print("Equipped Axe")
end
--[[
@Description: Example Unequip function that prints a success message when called.
]]
function Axe:Unequip() : ()
	print("Unequipped Axe")
end

function Axe.new(Player, Amount, Durability, Effectiveness)
	local self: table = Handler.new(Player, "Axe", Amount, Durability, Effectiveness)
	setmetatable(self, Axe) 
    return self
end

return Axe
