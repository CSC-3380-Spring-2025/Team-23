local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local rigsFolder = ServerStorage.NPC.Rigs
local NPC = require(ServerScriptService.Server.NPC.NPC)

local NPC1 = NPC.new("NPC 1", rigsFolder.DefaultNPC, 100, 0, nil, Vector3.new(0, 10, 0))

local waypoints = Workspace:FindFirstChild("PathfindingTest")
local waypoint1 = waypoints:FindFirstChild("Waypoint1")
local waypoint10 = waypoints:FindFirstChild("Waypoint10")

task.wait(5)
local success = false
--local success = NPC1:SetLinkedWaypoint(waypoint10.Position)

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

print("Am I sitll going?")