--[[
This script defines an abstract interface required for all player tools.
Any tool child simply manipulates and uses the given tool instance.
The user is responsible for cloning and handing a given tool instance to the constructor.
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players: Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Tool = {}
Object:Supersedes(Tool)

--[[
The constructor for the Tools class
    @param Name (string) the name of this ObjectInstance
    @param PhysTool (Tool) the physical tool in workspace being used
    does not copy the given tool but uses it directly
    The player is assumed to have a character and have the tool already equipped
--]]
function Tool.new(Name: string, PhysTool: Tool) : ExtType.ObjectInstance
    local self = Object.new(Name)
	setmetatable(self, Tool)
    self.__Tool = PhysTool
    --Load animations
    local animations: Folder? = PhysTool:FindFirstChild("Animations") :: Folder?
    if not animations then
        warn("Attempted to construct tool but animations could not be loaded due to missing animations folder")
        return self
    end
    local character: Model? = player.Character
    if not character then
        warn("Attempt to make instance of Tool but player has no character")
        return self
    end
    local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then
        warn("Attempt to make instance of Tool but player has no humanoid")
        return self
    end
    local animator: Animator? = humanoid:FindFirstChild("Animator") :: Animator?
    if animator == nil then
        warn("Attempt to make instance of Tool but player has no animator")
        return self
    end
    self.__Animations = {}
    for _, animation in pairs(animations:GetChildren()) do
        if animation:IsA("Animation") then
            local track: AnimationTrack = animator:LoadAnimation(animation)
            self.__Animations[animation.Name] = track
        end
    end
    self.__Connections = {}--Table of all connections for the Tool
    self.__Tasks = {}--Table of all tasks for a tool
	return self
end

--[[
Defines the behaivore of a tool when activated
--]]
function Tool:Activate() : ()
    AbstractInterface:AbstractError("Activate", "Tools")
end

--[[
Cleans up the given tool instance.
    DOES NOT destroy the tool given to the cosntructor.
    The physical tool is preserved.
    Not using this function with a given instance may lead to both memory leaks
    and also undefined behaivore.
--]]
function Tool:DestroyInstance() : ()
    AbstractInterface:AbstractError("DestroyInstance", "Tools")
end

return Tool