local Handler = require(game.ServerScriptService.Server.Player.ToolHandler)
local Axe = {}
Handler:Supersedes(Axe)

function Axe:Activate() : ()
	print("Activated Axe")
end

function Axe:Equip() : ()
	print("Equipped Axe")
end

function Axe:Unequip() : ()
	print("Unequipped Axe")
end

function Axe.new(Player, Amount, Durability, Effectiveness)
	local self: table = Handler.new(Player, "Axe", Amount, Durability, Effectiveness)
	setmetatable(self, Axe) 
    return self
end

return Axe
