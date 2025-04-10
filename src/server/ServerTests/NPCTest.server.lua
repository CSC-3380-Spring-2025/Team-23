script.Enabled = false

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local rigsFolder = ServerStorage.NPC.Rigs
local NPC = require(ServerScriptService.Server.NPC.NPC)
local BackpackNPC = require(ServerScriptService.Server.NPC.BackpackNPC)
local ResourceNPC = require(ServerScriptService.Server.NPC.ResourceNPC.ResourceNPC)
local MinerNPC = require(ServerScriptService.Server.NPC.ResourceNPC.MinerNPC)

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

--[[
local ResourceNPC1 = ResourceNPC.new("ResourceNPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 16, 100, 70, 100)

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
--]]

--Walk speed test
--[[
local NPC1 = NPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 30)

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

NPC1:SetSpeed(6)

print(NPC1:GetSpeed())
--]]

--Destroy test
--[[
local NPC1 = MinerNPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 30, 100, 70, 100, nil)

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

NPC1:Destroy()
--]]

--ToolNPC tests
----[[
local ToolNPC = require(ServerScriptService.Server.NPC.ToolNPC)
local NPC1 = ToolNPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 30, 100, 70, 100, nil)

local waypoints = Workspace:FindFirstChild("PathfindingTest")
local waypoint1 = waypoints:FindFirstChild("Waypoint1")
local waypoint10 = waypoints:FindFirstChild("Waypoint10")
local homePoint = waypoints:FindFirstChild("HomePoint")
--[[
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

NPC1:Destroy()
--]]

--ToolNPC tools test
----[[
local tools = ReplicatedStorage.Tools
local pickaxe = tools.Resource.Pickaxes.Pickaxe
NPC1:AddTool(pickaxe, 1)

task.wait(5)
NPC1:EquipTool(pickaxe.Name)
task.wait(5)
NPC1:UnequipTool()
--]]

--Animation test
--[[
local NPC1 = NPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 16)
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://86591655675033"

local animTrack = NPC1:LoadAnimation(animation)
task.wait(5)
animTrack:Play()
task.wait(3)
NPC1:RemoveAnimation(animTrack)
task.wait(2)
print("Playing but should error")
animTrack:Play()
--]]
