--[[
This class functions as a general purpouse manager for creating non dialogue NPC's
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Runservice = game:GetService("RunService")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local NPC = {}
Object:Supersedes(NPC)

--[[
Alters the cost of a path to take for an NPC
    example:
    Wood = 1,
    Neon = 100,
--]]
local costTable: {any} = {

}

--Specifies allowed behaivore
local agentParameters: {any} = {
    AgentCanJump = true,
    AgentCanClimb = true,
    AgentRadious = 4,
    Costs = costTable
}

--[[
Constructor that creates an NPC
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param RewardValue (number) the amount of gold dropped for a player when NPC dies.
    @param Tools (undetermined)
    @param SpawnPos (Vector3) position to spawn NPC at
--]]
function NPC.new(Name: string, Rig: Model, Health: number, RewardValue: number, Tools: Tool, SpawnPos: Vector3)
	local self = Object.new(Name)
	setmetatable(self, NPC)
	--Set up NPC body
	self.__NPC = Rig:Clone()
	self.__NPC.Parent = workspace
	local rootPart = self.__NPC:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(SpawnPos)
	end
	self.__RootPart = rootPart
	self.__Humanoid = self.__NPC:FindFirstChild("Humanoid")
	self.__NPC.Name = Name
	self.__Health = Health
	if RewardValue < 0 then
		error("RewardValue may not be less than 0")
	end
	self.__RewardValue = RewardValue or 0
	--Add tools to npc here eventually
	--Spawn NPC here eventually at SpawnPos
	local waypoints: {Path} = {}
	self.__Waypoints = waypoints
	self.__PathFindingTask = nil --Task set to executing the pathfinding
	self.__HomePoint = nil
	return self
end

--[[
Helper function for preparing a waypoint
    @param StartPosition (Vector3) position to start from
    @param EndPosition (Vector3) position to end at
    @param Self (instance) instance of current class making this call
    @param Overwrite (boolean) indicates weather to overwrite other set waypoints
    @return (boolean) true on success or false on fail
--]]
local function PrepWaypoint(StartPosition: Vector3, EndPositon: Vector3, Self: any, Overwrite: boolean): boolean
	local path: Path = PathfindingService:CreatePath(agentParameters)
	--Wrap in pcall to detect a fail
	local success: boolean, errorMessage: string = pcall(function()
		path:ComputeAsync(StartPosition, EndPositon)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		if Overwrite then
			Self.__Waypoints = {} --Clear prev waypoints
		end
		table.insert(Self.__Waypoints, path) --Insert at end of table
		return true
	else
		warn('NPC "' .. Self.__NPC.Name .. '" failed to find a path. ' .. errorMessage)
		return false
	end
end

--[[
Sets a singular waypoint and cancels any linked waypoints
    SetWaypoint is only intended for a singular waypoint and does not allow for a chain of waypoints
    However SetLinkedWaypoint may extend an already existing way point set by SetWaypoint
    @param Position (Vector3) position of waypoint to set
    @return (boolean) True on success or false on fail
--]]
function NPC:SetWaypoint(Position: Vector3): boolean
	self:CancelWaypoints()
	return PrepWaypoint(self.__RootPart.Position, Position, self, true)
end

--[[
Extends an existing waypoint, or extends the waypoint previously set in a chain
    allows for long term movement plans
    @param Position (Vector3) position of waypoint to set
    @return (boolean) True on success or false on fail
--]]
function NPC:SetLinkedWaypoint(Position: Vector3): boolean
	--If currently traversing cancel it
	if self.__PathFindingTask then
		self:CancelWaypoints()
	end
	--If existing waypoint get its position as position else use current pos
	local startPos: Vector3 = self.__RootPart.Position
	if self.__Waypoints ~= nil then
		local lastPath: Path = self.__Waypoints[#self.__Waypoints]
		if lastPath ~= nil then
            local lastWaypoints: {PathWaypoint} = lastPath:GetWaypoints()
			local lastPoint: PathWaypoint = lastWaypoints[#lastWaypoints]
			if lastPoint ~= nil then
				startPos = lastPoint.Position
			end
		end
	end
	return PrepWaypoint(startPos, Position, self, false)
end

local function ValidatePath(Path)
    local waypoints = (Path:GetWaypoints())
    local firstPos = waypoints[1].Position
    local lastPos = waypoints[#waypoints].Position
    local newPath: Path = PathfindingService:CreatePath(agentParameters)
    local success: boolean, errorMessage: string = pcall(function()
		newPath:ComputeAsync(firstPos, lastPos)
	end)

    if success and newPath.Status == Enum.PathStatus.Success then
        return true
    else
        warn("Path is no longer viable")
        return false
    end
end

local function ReroutePath(FirstPos, LastPos)
    local newPath: Path = PathfindingService:CreatePath(agentParameters)
    local success: boolean, errorMessage: string = pcall(function()
		newPath:ComputeAsync(FirstPos, LastPos)
	end)

    if success and newPath.Status == Enum.PathStatus.Success then
        return newPath
    else
        return nil
    end
end

local function Reroute(Self, Path)
    --Find current path index
    local pathIndex = 1
    for i, path in ipairs(Self.__Waypoints) do
        if path == Path then
            pathIndex = i
        end
    end

    --Redirect to next path end point
    local nextPath = Self.__Waypoints[pathIndex + 1]
    if nextPath then
        local currentPathWaypoints = Path:GetWaypoints()
        local currentPathStart = currentPathWaypoints[1]
        local nextPathWaypoints = nextPath:GetWaypoints()
        local nextPathEnd = nextPathWaypoints[#nextPathWaypoints]

        --Attempt to find path to next endpoint
        local newPath = ReroutePath(currentPathStart.Position, nextPathEnd.Position)
        if newPath then
            Self.__Waypoints[pathIndex + 1] = newPath
            return true
        end
    end
    return false --Could not find path or was no next path
end

local function BlockedFallBack(Self, Path) : ()
    --Check if path is valid again every 2 seconds for 5 times.
    for i = 1, 5 do
        task.wait(2)
        local validPath = ValidatePath(Path)
        print(validPath)
        if validPath then
            return true
        end
    end

    --Attempt to reoute to next waypoint
    local rerouteSuccess = Reroute(Self, Path)
    if rerouteSuccess then
        return true
    end

    return false --Attempt failed
end

local function DetectBlock(Path)
    Path.Blocked:Connect(function()
        print("Path is blocked!!")
    end)
end

--[[
Tells the NPC to begin traversing the current set of waypoints
--]]
function NPC:TraverseWaypoints(): ()
	--Check to prevent double traverse
	if self.__PathFindingTask then
		warn("Attempted to call TraverseWaypoints() while previous call to TraverseWaypoints() is stull running")
		return
	end
	self.__PathFindingTask = task.spawn(function()
		if self.__Waypoints == nil then
			return
		end
		for _, path in ipairs(self.__Waypoints) do
			if path == nil then
				return
			end
            --Check if path is still valid
            if not ValidatePath(path) then
                local fallBackSuccess = BlockedFallBack(self, path)
                if fallBackSuccess then
                    continue--Skip to next loop because next path has been rerouted from current position.
                else
                    --All attempts failed. Abandon traverse.
                    self:CancelWaypoints()
                    return
                end
            end
			for _, waypoint in pairs(path:GetWaypoints()) do
				if waypoint == nil then
					return
				end
				self.__Humanoid:MoveTo(waypoint.Position)
                --Handle jump conditions
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    self.__Humanoid.Jump = true
                end
				self.__Humanoid.MoveToFinished:Wait() --Handle cases where they get stuck before it ends eventually else this will make them stuck
                --Check if stuck
                if path.Status == Enum.PathStatus.Success then
                    --print(true)
                else
                    --print(false)
                end
			end
		end
		--Traverse complete. Remove current prev waypoints
		self.__Waypoints = {}
	end)
end

--[[
Cancels waypoints of any type
--]]
function NPC:CancelWaypoints(): ()
	if self.__PathFindingTask then
		task.cancel(self.__PathFindingTask)
		self.__PathFindingTask = nil --Reset pathfindingtask to indicate no pathfinding
	end
	if not self.__Humanoid.MoveToFinished then
		--If still moving end movement
		self.__Humanoid:MoveTo(self.__RootPart.Position)
	end
	self.__Waypoints = {}
end

--[[
Sets the exact position an NPC will attempt to return to when there are no more pathfinding commands.
    @param HomePointPosition (Vector3) the position that is considerd home for the NPC
--]]
function NPC:SetHomePoint(HomePointPosition: Vector3)
	self.__HomePoint = HomePointPosition
end

--[[
Makes the NPC return to the set home point
--]]
function NPC:ReturnHome()
	if not self.__HomePoint then
		warn("ReturnHome() called but no HomePoint set")
		return
	end
	self:CancelWaypoints()
	local success: boolean = PrepWaypoint(self.__RootPart.Position, self.__HomePoint, self, true)
	if success then
		self:TraverseWaypoints()
	end
end

--[[
Helper function for taversing the waypoints set during follow
    @param Self (instance) instance of the class
    @param CurrentObjPos (Vector3) current position of the object being followed
--]]
local function TraverseFollowPoints(Self: any, CurrentObjPos: Vector3) : ()
	Self.__Waypoints = {} --Reset waypoints
	local success: boolean = PrepWaypoint(Self.__RootPart.Position, CurrentObjPos, Self, true)
	--If valid path start following player
	if success then
		--Traverse waypoints in each set of waypoints
		for _, path in ipairs(Self.__Waypoints) do
			if path == nil then
				break
			end
			for _, waypoint in pairs(path:GetWaypoints()) do
				if waypoint == nil then
					return
				end
				Self.__Humanoid:MoveTo(waypoint.Position)
			end
		end
	end
end

--[[
Loops the follow command to follow a player until it is killed
    @param Self (instance) the instance of the class
    @param Object (BasePart) the object to follow
--]]
local function FollowLoop(Self, Object) : ()
	local lastObjPos: Vector3 = nil
	--Indefinetly follow given object
	while true do
		local currentObjPos: Vector3 = Object.Position
		--If object has moved set new waypoints
		if currentObjPos ~= lastObjPos then
            TraverseFollowPoints(Self, currentObjPos)
		end
		lastObjPos = currentObjPos
		Runservice.Heartbeat:Wait() --Waits per frame
	end
end

--[[
Sets an NPC to follow a given object
    The object may be any object including a player or another NPC etc.
    Creating a waypoint will undo a follow command.
    @param Object (BasePart) the object to follow
--]]
function NPC:Follow(Object: BasePart): ()
	if self.__Waypoints then
		self:CancelWaypoints() --Cancel any prev tasks.
	end

	self.__PathFindingTask = task.spawn(function()
        FollowLoop(self, Object)
	end)
end

--[[
Cancels a Follow command
--]]
function NPC:Unfollow(): ()
	self:CancelWaypoints()
end

--WORK IN PROGRESS START:
--[[
Drops the reward amount in a money bag when an NPC is killed
--]]
function NPC:DropReward()
	--May NOT take ANY parameters. Must use instance variables by using self.__RewardValue
	error("Must Implement DropReward!") --Remove this to start
end

--WORK IN PROGRESS END

return NPC
