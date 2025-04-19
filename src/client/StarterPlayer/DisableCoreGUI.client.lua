--[[
This script disables Roblox's core GUI to replace with custom UI
--]]
local StarterGui = game:GetService("StarterGui")
--Disable normal health bar
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)