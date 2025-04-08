local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local rigsFolder = ServerStorage.NPC.Rigs
local NPC = require(ServerScriptService.Server.NPC.NPC)
local ResourceNPC = require(ServerScriptService.Server.NPC.ResourceNPC.ResourceNPC)

--[[
local NPC1 = NPC.new("NPC 1", rigsFolder.DefaultNPC, 100, 0, nil, Vector3.new(0, 10, 0))

local waypoints = Workspace:FindFirstChild("PathfindingTest")
local waypoint1 = waypoints:FindFirstChild("Waypoint1")
local waypoint10 = waypoints:FindFirstChild("Waypoint10")
local homePoint = waypoints:FindFirstChild("HomePoint")

task.wait(5)
local success = false
--local success = NPC1:SetLinkedWaypoint(waypoint10.Position)

NPC1:SetHomePoint(homePoint.Position)

--LinkedWaypoint test
for i = 1, 12 do
    local point = waypoints:FindFirstChild("Waypoint" .. i)
    success = NPC1:SetLinkedWaypoint(point.Position)
    if not success then
        break
    end
end

if success then
    NPC1:TraverseWaypoints()
end

task.wait(10)

--[[
success = NPC1:SetWaypoint(waypoint1.Position)
if success then
    NPC1:TraverseWaypoints()
end
--]]

--[[
print("Stopping waypoints!")
--NPC1:CancelWaypoints()
NPC1:ReturnHome()

task.wait(20)

----[[
success = NPC1:SetLinkedWaypoint(waypoint10.Position)
if success then
    NPC1:TraverseWaypoints() 
end
--]]


--print("Am I sitll going?")
--]]
--]]

--ResourceNPC tests

local ResourceNPC1 = NPC.new("ResourceNPC 1", rigsFolder.DefaultNPC, 100, 0, nil, Vector3.new(0, 10, 0))

local waypoints = Workspace:FindFirstChild("PathfindingTest")
local waypoint1 = waypoints:FindFirstChild("Waypoint1")
local waypoint10 = waypoints:FindFirstChild("Waypoint10")
local homePoint = waypoints:FindFirstChild("HomePoint")

task.wait(5)
local success = false
--local success = NPC1:SetLinkedWaypoint(waypoint10.Position)

ResourceNPC1:SetHomePoint(homePoint.Position)

--LinkedWaypoint test
for i = 1, 12 do
    local point = waypoints:FindFirstChild("Waypoint" .. i)
    success = ResourceNPC1:SetLinkedWaypoint(point.Position)
    if not success then
        break
    end
end

if success then
    ResourceNPC1:TraverseWaypoints()
end