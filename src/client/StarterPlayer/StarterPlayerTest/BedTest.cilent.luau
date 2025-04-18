local localPlayer: Player = game:GetService("Players").LocalPlayer 
local char : Model = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hum : Humanoid = char:WaitForChild("Humanoid")
local hrp : BasePart = char:WaitForChild("HumanoidRootPart")

