--[[
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://77955291928497"
local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--local animationTrack = humanoid:LoadAnimation(animation)
--animationTrack.Priority = Enum.AnimationPriority.Action2
--task.wait(10)
--print("Play sword swing")
--animationTrack:Play()

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local function tagCharacter(character)
	if character and not CollectionService:HasTag(character, "Enemy") then
		CollectionService:AddTag(character, "Enemy")
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
        if player == Players.LocalPlayer then
            return
        end
		tagCharacter(character)
	end)

	-- Tag character if already loaded
	if player.Character then
		tagCharacter(player.Character)
	end
end

-- Handle all existing players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Listen for new players
Players.PlayerAdded:Connect(onPlayerAdded)
--]]