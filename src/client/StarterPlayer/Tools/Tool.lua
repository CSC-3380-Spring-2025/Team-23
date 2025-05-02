--[[
This script defines an abstract interface required for all player tools.
Any tool child simply manipulates and uses the given tool instance.
The user is responsible for cloning and handing a given tool instance to the constructor.
--]]
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players: Players = game:GetService("Players")
local player: Player = Players.LocalPlayer
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ItemUtilsObject = require(ReplicatedStorage.Shared.Items.ItemsUtils)
local AbstractInterface = require(ReplicatedStorage.Shared.Utilities.Object.AbstractInterface)
local ClientMutexSeq = require(script.Parent.Parent.ClientUtilities.ClientMutexSeq)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local Tool = {}
Object:Supersedes(Tool)

--Instances
local itemUtils: ExtType.ObjectInstance = ItemUtilsObject.new("ToolItemUtils")

--Vars
local toolCount: number = 0

--[[
Sets up the needed cool down info needed for a tool
	@param Tool (Tool) the tool associated with this tool instance
    @param Self (ExtType.ObjectInstanc)
--]]
local function PrepCoolDown(Tool: Tool, Self: ExtType.ObjectInstance) : ()
    local coolDownTime: number? = Tool:GetAttribute("CoolDown") :: number?
    if not coolDownTime then
        coolDownTime = 0
    end
    local mainAnimName: string? = Tool:GetAttribute("ActiveAnimName") :: string?
    local animationTime: number = 0
    if mainAnimName then
        --Find animation for mainAnim
        local mainAnim: AnimationTrack = Self.__Animations[mainAnimName]
        if mainAnim then
            animationTime = mainAnim.Length
        end
    end
	--Make sure cool down is not less than the main animation
	if animationTime <= coolDownTime then
		Self.__CoolDownTime = coolDownTime
	else
		Self.__CoolDownTime = animationTime
	end
	Self.__OnCoolDown = false--Indicates if the tool is on cool down or not
	Self.__CoolDownLockKey = "SwordsmanCoolDown" .. toolCount
	Self.__CoolDownLock = ClientMutexSeq.new(Self.__CoolDownLockKey) --used to safely access OnCoolDown
end

local protFuncs: ExtType.AnyDict = {}
--[[
Cools down the given tool instance
    protected function that is only for this class and its children
    @param Self (ExtType.ObjectInstance) the instance of this class
--]]
protFuncs.CoolDown = function(Self: ExtType.ObjectInstance)
    Self.__Tasks["CoolDown"] = task.spawn(function()
		Self.__CoolDownLock:Lock()
		Self.__OnCoolDown = true
		Self.__CoolDownLock:Unlock()
		task.wait(Self.__CoolDownTime)
		Self.__CoolDownLock:Lock()
		Self.__OnCoolDown = false
		Self.__CoolDownLock:Unlock()
	end)
end

--[[
Checks if the given tool instance is on a cooldown
    protected function that is only for this class and its children
    @param Self (ExtType.ObjectInstance) the instance of this class
--]]
protFuncs.IsOnCoolDown = function(Self: ExtType.ObjectInstance)
    Self.__CoolDownLock:Lock()
	local coolDown: boolean = Self.__OnCoolDown
	Self.__CoolDownLock:Unlock()
	return coolDown
end

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
    --Store tool info if it exists
    local toolInfo: ExtType.InfoMod = itemUtils:GetItemInfo(PhysTool.Name)
    self.__ToolInfo = toolInfo--Stores the tools item info if it exists to prevent needing to always get it
    --Set up cool down for tool if it exists for tool
    PrepCoolDown(PhysTool, self)
    --Optional functions that are protected by this class and children
    self.__ProtFuncs = protFuncs
    toolCount = toolCount + 1
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