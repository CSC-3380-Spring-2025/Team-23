--[[
This class handles the behavior of all axes
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local ResourceTool = require(script.Parent.ResourceTool)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)
local Axe = {}
ResourceTool:Supersedes(Axe)

--Events
local HandleAxeStrikeEvent: ExtType.Bridge = BridgeNet2.ReferenceBridge("HandleAxeStrike")

--[[
Constructor for a pick axe instance
	@param Name (String) name of the pickaxe
	@param PhysTool (Tool) the physical tool of the pickaxe
--]]
function Axe.new(Name: string, PhysTool: Tool): ExtType.ObjectInstance
	local self = ResourceTool.new(Name, PhysTool)
	setmetatable(self, Axe)
	local overheadAnim: AnimationTrack? = self.__Animations["AxeOverHeadSwing"]
	if not overheadAnim then
		warn("Attempt to make instance of Axe but tool has no animation called AxeOverHeadSwing")
		return self
	end
    overheadAnim.Priority = Enum.AnimationPriority.Action2
    local sideAnim: AnimationTrack? = self.__Animations["AxeSideSwing"]
    if not sideAnim then
		warn("Attempt to make instance of Axe but tool has no animation called AxeSideSwing")
		return self
	end
	--Set up swingAnim
	sideAnim.Priority = Enum.AnimationPriority.Action2
	self.__ActivationRadious = 8
	return self
end

--Common vars
local player: Player = Players.LocalPlayer
local mouse: Mouse = player:GetMouse()
local camera: Camera = Workspace.CurrentCamera

local function PlayAnimation(Target, SwingAnim)
    local character: Model? = player.Character
	if not character then
		return
	end
    --Turn player to target
	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		local direction: Vector3 = Vector3.new(Target.Position.X, rootPart.Position.Y, Target.Position.Z)
		local endFrame: CFrame = CFrame.lookAt(rootPart.Position, direction)
		local tweenInfo: TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween: Tween = TweenService:Create(rootPart, tweenInfo, { CFrame = endFrame })
		tween:Play()
	end

	SwingAnim:Play()
end

--[[
Determines if the surface normal vector faces mostly upwards or not
    @param NormalVector (Vector3) the normal vector of the surface clicked on
--]]
local function IsUpDominate(NormalVector: Vector3) : boolean
    --get sideways value
    local sideways: number = math.sqrt(NormalVector.X^2 + NormalVector.Z^2)
    --get upwards value
    local upwards: number = NormalVector.Y
    if upwards > sideways then
        return true
    else
        return false
    end
end

--[[
Calculates what version of the swing animation to use based on the targets normal vector
    @param SideSwing (AnimationTrack) the swide swing version of the axe animation
    @param OverheadSwing (AnimationTrack) the overhead swing version of the axe animation
--]]
local function CalcSwingAnim(SideSwing: AnimationTrack, OverheadSwing: AnimationTrack) : AnimationTrack
    local origin: Vector3 = camera.CFrame.Position
    local direction: Vector3 = (mouse.Hit.Position - origin).Unit * 1000
    local raycastParams: RaycastParams = RaycastParams.new()
    --Exclude players char
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result: RaycastResult? = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        --Sucess. Determine anim based on normal vector
        if IsUpDominate(result.Normal) then
            --Clicked on a most upward surface so use overhead
            return OverheadSwing
        else
            --Clicked on non upwards dominant surface to use side swing
            return SideSwing
        end
    else
        --Failed. So just choose overhead.
        return OverheadSwing
    end
end

function Axe:Activate()
    --print("Activating Axe")
    --Check for cooldown
	if self.__ProtFuncs.IsOnCoolDown(self) then
		return --Is on cooldown
	end
    if not self.__Effectiveness then
		return --No effectiveness attribute set
	end
    local target: BasePart = mouse.Target
	--Check for if target was allowed ore else void
	if not self:CanInteract(target) then
		return
	end
    local hitPos: Vector3 = mouse.Hit.Position
    --Check player distance
	if not self.__ProtFuncs.WithinDistance(target, self.__ActivationRadious) then
		return
	end
    local overheadAnim: AnimationTrack? = self.__Animations["AxeOverHeadSwing"]
	if not overheadAnim then
		warn("Attempt to activate Axe but tool has no animation called AxeOverHeadSwing")
		return 
	end
    local sideAnim: AnimationTrack? = self.__Animations["AxeSideSwing"]
    if not sideAnim then
		warn("Attempt to activate Axe but tool has no animation called AxeSideSwing")
		return
	end
    local usedAnim: AnimationTrack = CalcSwingAnim(sideAnim, overheadAnim)
    PlayAnimation(target, usedAnim)
    usedAnim.Stopped:Once(function()
        local strikeArgs: ExtType.StrDict = {
            Target = target,
            Effectiveness = self.__Effectiveness,
            HitPos = hitPos
        }
        HandleAxeStrikeEvent:Fire(strikeArgs)
    end)
    self.__ProtFuncs.CoolDown(self)--Cooldown
end

return Axe