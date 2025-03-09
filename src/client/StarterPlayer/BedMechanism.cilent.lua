--[[
file that contains function to initiate sleeping-related prompt and functions
]]--

local pps = game:GetService("ProximityPromptService")
local localPlayer: Player = game:GetService("Players").LocalPlayer 
local char : Model = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hum : Humanoid = char:WaitForChild("Humanoid")
local hrp : BasePart = char:WaitForChild("HumanoidRootPart")
local sleepAnim : Animation = hum.Animator:LoadAnimation(script.SleepAnim)
local ts = game:GetService("TweenService")	--summon game resources for animation


local animator : Animator = hum:WaitForChild("Animator")	
local animation : Animation = Instance.new("Animation") --call new instance for animation
animation.AnimationId = "rbxassetid://101980808823459" --summon animation code from ROBLOX Studio
local animationTrack : AnimationTrack = animator:LoadAnimation(animation) --load animation to be ready for use

--[[
function to initiate sleeping-related prompt and functions
	also including health regeneration after some time on bed
	@param Prompt (Proximity Prompt) - proximity prompt of either "Sleep" or "Wake up"
	@param Player (Player) - the player who comes in contact with the prompt
	returns null
--]]
local function onPromptTriggered(Prompt, Player) : ()

	if Prompt.Name == "Sleep" then
		local bed: BasePart = Prompt.Parent
		local sleepPause: BasePart = bed:FindFirstChild("SleepPause")
		Prompt.Enabled = false
		
		--- animation
		hum.WalkSpeed = 0 --freezes the player
		hum.JumpPower = 0
		hum.UseJumpPower = true
		local ti: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
		local tween: TweenService = ts:Create(hrp, ti, { CFrame=CFrame.new(bed.Position, bed.Parent.BedHeadboard.Position) + Vector3.new(0,5,0) })
		tween:Play()
		tween.Completed:Wait()
		animationTrack:Play()
		
		--- health
		bed.WakeUp.Enabled = true
		local humanoid: Humanoid = localPlayer.Character.Humanoid --function to get humanoid from character
		print(humanoid.Health)
		while(bed.WakeUp.Enabled == true) do
			task.wait(1)
			humanoid.Health = humanoid.Health + 1
			end
		
		
		
	elseif Prompt.Name == "WakeUp" then
		local bed: BasePart = Prompt.Parent
		Prompt.Enabled = false
		sleepAnim:Stop()
		animationTrack:Stop()
		print("I woke up") 
		hum.WalkSpeed = 16	--unfreezes the player
		hum.JumpPower = 50
		
		bed.Sleep.Enabled = true
	end

end

pps.PromptTriggered:Connect(onPromptTriggered)