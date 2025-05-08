--[[
local NPCOverheadMenu = require(script.Parent.Parent.OverheadView.OverheadMenus.NPCOverheadMenus.NPCOverheadMenu)
local myNPC = game.Workspace:WaitForChild("Overhead NPC")
local myNPCMenu = NPCOverheadMenu.new("MyMenu", myNPC)
task.wait(10)
myNPCMenu:PlaceMenu(Vector3.new(0, 5, 0))
myNPCMenu:OpenMenu()
--myNPCMenu:CloseMenu()
--myNPCMenu:Destroy()
--]]