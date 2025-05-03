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
local Axe = {}
ResourceTool:Supersedes(Axe)

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

--[[
Gets the ancestor of the instance with a given tag
    @param Instance (Instance) any instance
    @param Tag (string) any tag
    @return (Instance?) Instance with given Tag or nil if non found
--]]
local function GetTaggedAncestor(Instance: Instance, Tag: string) : Instance?
    local ancestor: Instance? = Instance.Parent
    while ancestor ~= nil do
        local hasTag: boolean = CollectionService:HasTag(ancestor, Tag)
        if hasTag then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil--No part has tree tag
end

--[[
Gets the overall model of the tree from one of its children
    @param TreePart (Instance) an instance that is a part of a tree
--]]
local function GetTreeModel(TreePart: Instance) : Model?
    local tree: Instance? = GetTaggedAncestor(TreePart, "Tree")
    if tree and tree:IsA("Model") then
        return tree
    end
    return nil--Tree not found
end

--[[
This function maintains the origional integrity of an object in an attribute
    called OgIntegrity for objects that need to reuse their integrity
    @param (Instance) any instance with Integrity
--]]
local function HandleOgIntegrity(Instance: Instance) : ()
    if Instance:GetAttribute("OgIntegrity") then
        return--Already set
    end
    local integrity: number = Instance:GetAttribute("Integrity") :: number
    Instance:SetAttribute("OgIntegrity", integrity)
end

--[[
Handles the integrity attribute of the Instance
    If integrity of instance becomes 0 (instance is destroyed) then returns true
    @param Instance (Instance) any instance with the integrity attribute
    @param Effectiveness (number) the Effectiveness of the current tool
--]]
local function HandleIntegrity(Instance: Instance, Effectiveness: number) : boolean
    HandleOgIntegrity(Instance)
    local integrity: number = Instance:GetAttribute("Integrity") :: number
    local newIntegrity: number =  integrity - Effectiveness
    if newIntegrity <= 0 then
        Instance:SetAttribute("Integrity", 0)
        return true
    else
        Instance:SetAttribute("Integrity", newIntegrity)
        return false
    end
end

--[[
Determines if an instance of a tree is a trunk or not
    @param TreeInstance (Instance) the instance assumed to be a trunk
    @return (boolean) true if is a "trunk" folder and has the word Trunk in its name 
    or false otherwise
--]]
local function IsTrunk(TreeInstance: Instance) : boolean
    local instanceName: string = TreeInstance.Name
    if string.find(instanceName, "Trunk") and TreeInstance:IsA("Folder") then
        return true
    else
        return false
    end
end

--[[
Unachores all Descendants of a instance if baseparts
    @param Instance (Instance) any instance with descendants
--]]
local function UnanchoreDescendants(Instance: Instance)
    for _, descendant in pairs(Instance:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
        end
    end
end

--[[
Sets up and plays the strike sound of the given tree object
    @param Target (Instance) any instance with the StrikeSoundID
    @param HitPos (Vector3) the position of where the player clicked 
--]]
local function StrikeSound(Target: Instance, HitPos: Vector3) : ()
    local strikeSoundID: number? = Target:GetAttribute("StrikeSoundID") :: number?
    if not strikeSoundID then
        return--No strike sound set
    end
    --Set up the sounds parent
    local soundPart: Part = Instance.new("Part")
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.Parent = Workspace
    soundPart.Position = HitPos
    --Set up the sound
    local sound: Sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. strikeSoundID
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMaxDistance = 100--studs. Distance where least volume is heard
    sound.RollOffMinDistance = 5--Studs. Distance where max volume is heard
    sound.PlayOnRemove = true--Makes it so that as we destroy it sound plays
    sound.Parent = soundPart
    soundPart:Destroy()
end

--[[
Sets up and plays the strike sound of the given tree object
    @param Tree (Model) any tree Model
    @param HitPos (Vector3) the position of where the player clicked 
--]]
local function ToppleSound(Tree: Model, HitPos: Vector3) : ()
    local toppleSoundID: number? = Tree:GetAttribute("ToppleSoundID") :: number?
    if not toppleSoundID then
        return--No strike sound set
    end
    --Set up the sounds parent
    local soundPart: Part = Instance.new("Part")
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.Parent = Workspace
    soundPart.Position = HitPos
    --Set up the sound
    local sound: Sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. toppleSoundID
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMaxDistance = 100--studs. Distance where least volume is heard
    sound.RollOffMinDistance = 5--Studs. Distance where max volume is heard
    sound.PlayOnRemove = true--Makes it so that as we destroy it sound plays
    sound.Parent = soundPart
    soundPart:Destroy()
end

--[[
Removes the step weld of the tree so that the stump stays behind
    @param Tree (Model) any given tree
--]]
local function RemoveStumpWeld(Tree: Model) : ()
    local welds: Folder? = Tree:FindFirstChild("Welds") :: Folder?
    if not welds then
        return
    end
    local baseWeld: Motor6D? = welds:FindFirstChild("Base>Trunk1") :: Motor6D?
    if not baseWeld then
        return
    end
    baseWeld.Enabled = false
end

--[[
Topples the given tree
    @param Tree (Model) the tree to topple
    @param HitPos (Vector3) the position of where the player clicked
--]]
local function ToppleTree(Tree: Model, HitPos: Vector3) : ()
    --Unanchore tree trunks
    --print("Topple the tree!")
    ToppleSound(Tree, HitPos)
    RemoveStumpWeld(Tree)
    for _, child in pairs(Tree:GetChildren()) do
        if IsTrunk(child) then
            UnanchoreDescendants(child)
        end
    end
    --transition state to FallenTree
    CollectionService:RemoveTag(Tree, "Tree")
    CollectionService:AddTag(Tree, "FallenTree")
end

--[[
Handles the behaivore of the Target if it is still part of the overall tree standing
    @param Tree (Model) the tree still standing
    @param Effectiveness (number) the Effectiveness attribute set for the tool
    @param HitPos (Vector3) the position of where the player clicked
--]]
local function HandleTree(Tree: Model, Effectiveness: number, HitPos: Vector3) : ()
    --print("Handling tree!")
    local toppled: boolean = HandleIntegrity(Tree, Effectiveness)
    if toppled then
        --Topple the tree
        ToppleTree(Tree, HitPos)
    end
end

--[[
Gets the model of a fallen tree if the tree has fallen
    @param TreePart (BasePart) the part of the tree clicked by a player
    @return (Model?) the tree fallen tree model on success or nil otherwise
--]]
local function GetFallenTreeModel(TreePart: BasePart) : Model?
    local fallenTree: Instance? = GetTaggedAncestor(TreePart, "FallenTree")
    if fallenTree and fallenTree:IsA("Model") then
        return fallenTree
    end
    return nil--Tree not found
end

--[[
Gets the tree trunk of a tree
    @param TreeInstance (Instance) any instance of a tree
    @return (Folder?) the trees trunk folder on success or false otherwise
--]]
local function GetTreeTrunk(TreeInstance: Instance) : Folder?
    local ancestor: Instance? = TreeInstance.Parent
    while ancestor ~= nil do
        if IsTrunk(ancestor) then
            return ancestor :: Folder
        end
        ancestor = ancestor.Parent
    end
    return nil--TreeTrunk folder not found
end

--[[
Finds a child of an instance with a sub string in the name
    @param Instance (Instance) any instance
    @param Name (string) the substring of a Name of a child you are looking for
    @return (Instance?) the instance with a name with the name as a substring or nil if non found
--]]
local function FindChildSubName(Instance: Instance, Name: string) : Instance?
    local children: {Instance} = Instance:GetChildren()
    if not children then
        return nil
    end
    for _, child in pairs(children) do
        if string.find(child.Name, Name) then
            return child
        end
    end
    return nil
end

--[[
Gets the number at the end of a string
    usefull for geting a name with a counted number at the end
    @param String (string) any string with a number at the end
    @return (number?) number at the end of the string or nil if there is no number at the end
--]]
local function GetStrEndNumber(String: string) : number?
    local endNumber: string? = String:match("(%d+)$")
    if endNumber then
        return tonumber(endNumber)
    else
        return nil
    end
end

--[[
Restores the origional integrity set for a given instance if it exists
    @param Instance (Instance) any instance that had a Integrity set
--]]
local function RestoreOgIntegrity(Instance: Instance)
    local ogIntegrity: number = Instance:GetAttribute("OgIntegrity") :: number
    Instance:SetAttribute("Integrity", ogIntegrity)
end

--[[
Updates the tree trunks state given a fallen tree
    @param FallenTree (Model) the model of a fallen tree
--]]
local function UpdateTrunks(FallenTree: Model) : ()
    local welds: Folder = FallenTree:FindFirstChild("Welds") :: Folder
    local children: {Instance} = FallenTree:GetChildren()
    if not children then
        return
    end
    for _, child in pairs(children) do
        if IsTrunk(child) then
            local prevWeld: Motor6D? = FindChildSubName(welds, ">" .. child.Name) :: Motor6D?
            local nextWeld: Motor6D? = FindChildSubName(welds, child.Name .. ">") :: Motor6D?
            if not prevWeld and not nextWeld then
                --Trunk is now independant
                CollectionService:AddTag(child, "SeparatedTreeTrunk")
                RestoreOgIntegrity(child)
                child.Parent = Workspace
            end
        end
    end
end

--[[
Seperates a given tree trunk from a fallen tree
    @param TreeTrunk (Folder) the tree trunk folder of the trunk to seperate
    @param FallenTree (Model) the model of the fallen tree
--]]
local function SeperateTrunk(TreeTrunk: Folder, FallenTree: Model) : ()
    --Unweld trunk from its neighbors if they exist
    local trunkName: string = TreeTrunk.Name
    local welds: Folder? = FallenTree:FindFirstChild("Welds") :: Folder?
    if welds == nil then
        return
    end
    local prevWeld: Motor6D? = FindChildSubName(welds, ">" .. trunkName) :: Motor6D?
    if prevWeld then
        prevWeld.Enabled = false
        prevWeld:Destroy()
    end
    local nextWeld: Motor6D? = FindChildSubName(welds, trunkName .. ">") :: Motor6D?
    if nextWeld then
        nextWeld.Enabled = false
        nextWeld:Destroy()
    end
    --Update truncs
    UpdateTrunks(FallenTree)
end

--[[
Handles what happens when a fallen tree is striked
    @param FallenTree (Model) the model of the fallen tree
    @param HitPos (Vector3) the position of where the player clicked
    @param Target (BasePart) the part the player clicked on
    @param Effectiveness (number) the Effectiveness attribute set for the tool
--]]
local function HandleFallenTree(FallenTree: Model, HitPos: Vector3, Target: BasePart, Effectiveness: number) : ()
    local treeTrunk: Folder? = GetTreeTrunk(Target)
    if treeTrunk == nil then
        return--Nothing to do because not a tree trunk
    end
    StrikeSound(treeTrunk, HitPos)
    HandleOgIntegrity(treeTrunk)--Store origional integrity for latter strike types
    local split: boolean = HandleIntegrity(treeTrunk, Effectiveness)
    --Check if trunk is finished seperating
    if split then
        SeperateTrunk(treeTrunk, FallenTree) 
    end
end

--[[
Checks for/finds an upper branch from the current tree instance
    @param TrunkInstance (Instance) any instance the trunk is an ancestor of
    @return (Folder?) the branch folder above this instance or nil if not found
--]]
local function GetUpperBranch(TrunkInstance: Instance) : Folder?
    local ancestor: Instance? = TrunkInstance.Parent
    while ancestor ~= nil do
        if ancestor:IsA("Folder") and ancestor.Name == "Branch" then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil--No part has tree tag
end

--[[
Removes the welds of the given upper branch
    @param UpperBranch (Folder) any given upper branch that needs welds removed
--]]
local function RemoveUpperBranchWelds(UpperBranch: Folder) : ()
    local upperBark: BasePart = UpperBranch:FindFirstChild("Bark") :: BasePart
    local upperInner: BasePart = UpperBranch:FindFirstChild("Inner") :: BasePart
    for _, descendant in pairs(UpperBranch:GetDescendants()) do
        if descendant:IsA("Motor6D") and not (descendant.Name == "Part") then
            if descendant.Part0 == upperBark or descendant.Part1 == upperBark then
                --Motor6d welds upperBark so remove it
                descendant:Destroy()
            end
            if descendant.Part0 == upperInner or descendant.Part1 == upperInner then
                --Motor6d welds upperInner so remove it
                descendant:Destroy()
            end
        end
    end 
end

--[[
Moves any given upper branch to a FallenBranches folder in workspace
    @param UpperBranch (Folder) the upper branch Folder to move the branch to
--]]
local function MoveChildrenToBranchesFolder(UpperBranch: Folder) : ()
    local folder: Folder = GetTaggedAncestor(UpperBranch, "FallenBranches") :: Folder
    if folder == nil then
        --Not yet in FallenBranches folder because UpperBranch is a trunk not just an UpperBranch
        folder = Instance.new("Folder")
        folder.Name = "FallenBranches"
        CollectionService:AddTag(folder, "FallenBranches")
        folder.Parent = Workspace
    end
    for _, child in pairs(UpperBranch:GetChildren()) do
        if child.Name == "Branch" and child:IsA("Folder") then
            child.Parent = folder
        end
    end
    if #folder:GetChildren() == 0 then
        folder:Destroy()
    end
end

--[[
Seperates a given upper branch from its children branches if it exists
    @param UpperBranch (Folder) any given upper branch who you want its children branches seperated from it
--]]
local function SeperateChildrenBranches(UpperBranch: Folder) : ()
    --Remove related welds
    RemoveUpperBranchWelds(UpperBranch)
    --Move children to its own folder
    MoveChildrenToBranchesFolder(UpperBranch)
end


--[[
Transitons a branch into a FallenBranch
    this DOES NOT make it a member of FallenBranches or a FallenBranches folder
    a FallenBranch is the lowest stage of an axe hiaerchy where after this
    stage the branch can be split into resources to collect
--]]
local function TransitionToFallenBranch(Branch: Folder) : ()
    local branchBark: BasePart = Branch:FindFirstChild("Bark") :: BasePart
    local branchInner: BasePart = Branch:FindFirstChild("Inner") :: BasePart
    local folder: Folder = Instance.new("Folder")
    folder.Name = "FallenBranch"
    branchBark.Parent = folder
    CollectionService:AddTag(folder, "FallenBranch")
    branchInner.Parent = folder
    local ogIntegrity: number = Branch:GetAttribute("OgIntegrity") :: number
    folder:SetAttribute("Integrity", ogIntegrity)
    local branchStrikeSoundID: number? = Branch:GetAttribute("StrikeSoundID") :: number?
    if branchStrikeSoundID then
        folder:SetAttribute("StrikeSoundID", branchStrikeSoundID)
    end
    local count: number? = Branch:GetAttribute("Count") :: number?
    if not count then
        error("Count attribute not set for branch folder or tree trunk for giving lumber")
    end
    folder:SetAttribute("Count", count)
    folder.Parent = Workspace
    Branch:Destroy()--Branch folder no longer needed
end

--[[
Seperates a given branch from its parent branch
    @param Branch (Folder) any given Branch folder of the tree
--]]
local function SeperateBranchFromParent(Branch: Folder) : ()
    local branchBark: BasePart = Branch:FindFirstChild("Bark") :: BasePart
    local branchInner: BasePart = Branch:FindFirstChild("Inner") :: BasePart
    local parentBranch: Folder? = GetUpperBranch(Branch)
    if not parentBranch then
        return
    end
    --Remove any welds that may be in parent
    for _, child in pairs(parentBranch:GetChildren()) do
        if child == Branch then
            continue
        end
        for _, descendant in pairs(child:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                if descendant.Part0 == branchBark or descendant.Part1 == branchBark then
                    --Motor6d welds upperBark so remove it
                    descendant:Destroy()
                end
                if descendant.Part0 == branchInner or descendant.Part1 == branchInner then
                    --Motor6d welds upperInner so remove it
                    descendant:Destroy()
                end
            end
        end
    end
    --Remove any welds in current branch that might relate to parent
    local parentBark: BasePart = parentBranch:FindFirstChild("Bark") :: BasePart
    local parentInner: BasePart = parentBranch:FindFirstChild("Inner") :: BasePart
    for _, descendant in pairs(Branch:GetDescendants()) do
        if descendant:IsA("Motor6D") then
            if descendant.Part0 == parentBark or descendant.Part1 == parentBark then
                --Motor6d welds upperBark so remove it
                descendant:Destroy()
            end
            if descendant.Part0 == parentInner or descendant.Part1 == parentInner then
                --Motor6d welds upperInner so remove it
                descendant:Destroy()
            end
        end
    end
end

--[[
This function handles the case where a player strikes a branch that isnt the base of a tree trunk
    @param Branch (Folder) any given branch folder in a fallen tree
    @param HitPos (Vector3) the position where the player clicked
    @param Target (BasePart) the part the player clicked
    @param Effectiveness (number) the Effectiveness attribute set by the tool
--]]
local function HandleBranch(Branch: Folder, HitPos: Vector3, Target: BasePart, Effectiveness : number)
    StrikeSound(Branch, HitPos)
    local isSplit: boolean = HandleIntegrity(Branch, Effectiveness)
    if isSplit then
        --Seperate any possible children branches
        SeperateChildrenBranches(Branch)
        --Seperate from parent branches
        SeperateBranchFromParent(Branch)
        --transition to fallen branch
        TransitionToFallenBranch(Branch)
    end
end

--[[
This function retrieves single branch that has fallen it does NOT
    include branches with children branches OR upper branches
    a FallenBranch is a branch that is an individual branch
    a FallEnBranch is the lowest level and is the last stage of an axe
    @param BranchInstance (Instance) any instance the branch is an ancestor of
    @return (Folder?) the fallen branch folder if found or nil otherwise
--]]
local function GetFallenBranch(BranchInstance: Instance) : Folder?
    local fallenBranch: Folder? = GetTaggedAncestor(BranchInstance, "FallenBranch") :: Folder?
    if fallenBranch then
        return fallenBranch
    else
        return nil
    end
end

--[[
Handles a tree trunk that has already been seperated and clicked on by the player
    @param TreeTrunk (Folder) any given tree trunk folder that a player clicked a descendant of
    @param HitPos (Vector3) the position of where the player clicked
    @param Target (BasePart) the part the player clicked on
    @param Effectiveness (number) the Effectiveness attribute set by the tool
--]]
local function HandleSeparatedTrunk(TreeTrunk: Folder, HitPos: Vector3, Target: BasePart, Effectiveness: number) : ()
    --Trunk is seperated from tree so need to check if hiting a branched part of main branch or if this is the only branch
    --Check for upper branch
    local upperBranch: Folder? = GetUpperBranch(Target)
    if upperBranch then
        --target is a subset of a seperated tree trunk
        HandleBranch(upperBranch, HitPos, Target, Effectiveness)
        return
    end
    --no upper branch so player hit the base of the trunk
    StrikeSound(TreeTrunk, HitPos)
    local isSplit: boolean = HandleIntegrity(TreeTrunk, Effectiveness)
    if isSplit then
        --seperate base of trunk from its children branches and make them independant
        SeperateChildrenBranches(TreeTrunk)
        --Treat trunkBase as a fallen branch now
        TransitionToFallenBranch(TreeTrunk)
    end
end

--[[
Spawns a lumber resource for the player to collect and add to their backpack
    @param SpawnPos (Vector3) the position of where to spawn the lumber resource to collect
    @param Count (number) the count of the resource to give the player
--]]
local function SpawnLumberResource(SpawnPos: Vector3, Count: number) : ()
    local lumberDrop: Model = ReplicatedStorage.ItemDrops:FindFirstChild("Lumber")
    local lumberDropClone: Model = lumberDrop:Clone()
    lumberDropClone.Parent = Workspace
    lumberDropClone:PivotTo(CFrame.new(SpawnPos))
    --Move loot to FallenBranch
    local prompt: ProximityPrompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "Lumber: " .. Count
    prompt.ActionText = "Claim Lumber"
    prompt.HoldDuration =  2
    prompt.Parent = lumberDropClone:FindFirstChild("Plank")
    prompt.RequiresLineOfSight = false
    prompt.Triggered:Connect(function(Player: Player)
        --Handle all possible rewards
        --Give player lumber here
        print("Gave player lumber in amount of: " .. Count)
        lumberDropClone:Destroy()--Remove chest after finished
    end)
end

--[[
Handles what happens when a player strikes a fallen branch
    @param FallenBranch (Folder) any FallenBranch Folder
    @param HitPos (Vector3) the position of where the player clicked
    @param Target (BasePart) the part the player clicked on
    @param Effectiveness (number) the Effectiveness attribute set by the tool
--]]
local function HandleFallenBranch(FallenBranch: Folder, HitPos: Vector3, Target: BasePart, Effectiveness: number) : ()
    StrikeSound(FallenBranch, HitPos)
    local isFinished = HandleIntegrity(FallenBranch, Effectiveness)
    if isFinished then
        local count = FallenBranch:GetAttribute("Count")
        if not count then
            warn("Trees branch or trunk was missing count. Can not give player reward of wood")
            return
        end
        
        FallenBranch:Destroy()
        --Spawn wood loot
        SpawnLumberResource(HitPos, count) 
    end
end

--[[
Determines what to do when a player clicks a given object with an axe
    @param Target (BasePart) the part the player clicked on
    @param Effectiveness (number) the Effectiveness attribute set by the tool
    @param HitPos (Vector3) the position of where the player clicked
--]]
local function HandleStrike(Target: BasePart, Effectiveness: number, HitPos: Vector3) : ()
    local tree: Model? = GetTreeModel(Target)
    if tree then
        StrikeSound(tree, HitPos)
        HandleTree(tree, Effectiveness, HitPos)
        return
    end
    local fallenTree = GetFallenTreeModel(Target)
    if fallenTree then
        HandleFallenTree(fallenTree, HitPos, Target, Effectiveness)
        return
    end
    --If at this point then the tree trunk being striked has been seperated
    local treeTrunk = GetTreeTrunk(Target)
    if treeTrunk then
        HandleSeparatedTrunk(treeTrunk, HitPos, Target, Effectiveness)
        return
    end
    --if at this point then branch could have children branches but is definetly not a part of a tree trunk anymore
    local fallenUpperBranch = GetUpperBranch(Target)
    if fallenUpperBranch then
        HandleBranch(fallenUpperBranch, HitPos, Target, Effectiveness)
        return
    end

    --If at this point the axe is striking the lowest level possible of a branch
    --This is the last state where a branch is broken into resources
    local fallenBranch = GetFallenBranch(Target)
    if fallenBranch then
        HandleFallenBranch(fallenBranch, HitPos, Target, Effectiveness)
        return
    end

    error("Edge case found for Axe HandleStrike")--Should not ever be here
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
    local usedAnim = CalcSwingAnim(sideAnim, overheadAnim)
    PlayAnimation(target, usedAnim)
    usedAnim.Stopped:Once(function()
        HandleStrike(target, self.__Effectiveness, hitPos)
    end)
    self.__ProtFuncs.CoolDown(self)--Cooldown
end

return Axe