----[[
----[[
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local rigsFolder = ServerStorage.NPC.Rigs
local NPC = require(ServerScriptService.Server.NPC.NPC)
local BackpackNPC = require(ServerScriptService.Server.NPC.BackpackNPC)
local ResourceNPC = require(ServerScriptService.Server.NPC.ResourceNPC.ResourceNPC)
local MinerNPC = require(ServerScriptService.Server.NPC.ResourceNPC.MinerNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local NPCHandler = NPCHandlerObject.new("NPCHandler Test")
--]]
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

]]
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
--[[
local ToolNPC = require(ServerScriptService.Server.NPC.ToolNPC)
local NPC1 = ToolNPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 16, 1000, 100, 70, 100, {"Coal", "Iron", "Pickaxe"}, nil)

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
--[[
local tools = ReplicatedStorage.Tools
local pickaxe = tools.Resource.Pickaxes.Pickaxe
NPC1:AddTool(pickaxe, 1)

task.wait(5)
NPC1:EquipTool(pickaxe.Name)
task.wait(5)
--NPC1:UnequipTool()
NPC1:Kill()
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

--BackNPC collection test
--[[
local NPC1 = BackpackNPC.new("NPC 1", rigsFolder.DefaultNPC, 100, Vector3.new(0, 10, 0), 16, 1000, 100, 70, 100, {"Coal", "Iron"}, nil)

local success = false
--local success = NPC1:SetLinkedWaypoint(waypoint10.Position)
local waypoints = Workspace:FindFirstChild("PathfindingTest")
local waypoint1 = waypoints:FindFirstChild("Waypoint1")
local waypoint10 = waypoints:FindFirstChild("Waypoint10")
local homePoint = waypoints:FindFirstChild("HomePoint")
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
	--NPC1:TraverseWaypoints()
end

task.wait(5)
NPC1:CollectItem("Coal", 10)
NPC1:CollectItem("Iron", 20)
NPC1:Kill()
--]]

--MinerNPC test

----[[
local tools = ReplicatedStorage.Tools
local pickaxe = tools.Resource.Pickaxes.Pickaxe
local NPC1 = MinerNPC.new(
	"Miner 1",
	rigsFolder.DefaultNPC,
	100,
	Vector3.new(0, 10, 0),
	16,
	1000,
	100,
	70,
	100,
	{ "Coal", "Iron", "Pickaxe", "Bread", "Water"},
	nil,
	nil,
	{ "Coal" },
    true,
	nil
)
local coal = workspace:FindFirstChild("OreModelDemo"):FindFirstChild("Coal")
NPCHandler:AddNPCToPlayerPool(NPC1, 81328434)
local NPC1secondref = NPCHandler:GetPlayerNPCByCharacter(NPC1.__NPC, 81328434)
print(NPC1:IsOre(coal))
NPC1:AddPickaxe(pickaxe, 1)
NPC1:HarvestResource(coal)
print(NPC1:GetItemCount("Coal"))
--NPC1:UnequipTool()
--NPC1:Kill()
--]]


--Stats test
--[[
local NPC1 = MinerNPC.new(
	"Miner 1",
	rigsFolder.DefaultNPC,
	100,
	Vector3.new(0, 10, 0),
	16,
	1000,
	100,
	70,
	100,
	{ "Coal", "Iron", "Pickaxe", "Bread", "Water"},
	nil,
	nil,
	{ "Coal" },
    true
)

NPC1:CollectItem("Bread", 30)
NPC1:CollectItem("Water", 10)

print("Checking NPC1 name: " .. NPC1.Name)
--]]
