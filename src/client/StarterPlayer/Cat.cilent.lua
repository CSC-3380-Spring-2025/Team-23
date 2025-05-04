--[[
Supporting script to make cat meow
]]--

local pps = game:GetService("ProximityPromptService")
local localPlayer: Player = game:GetService("Players").LocalPlayer 
local sound = game.Workspace.Cat.CatBody.Sound
local part = game.Workspace.Cat.CatBody

--[[
function to initiate petting mechanisms
	@param Prompt (Proximity Prompt) - proximity prompt to trigger meow sounds
	@param Player (Player) - the player who comes in contact with the prompt
	returns null
--]]
local function onPromptTriggered(Prompt, Player) : ()

	if Prompt.Name == "Pet" then
        sound:Play()
		print("Meow")
    end
	
end

pps.PromptTriggered:Connect(onPromptTriggered)