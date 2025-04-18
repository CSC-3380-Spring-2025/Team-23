local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events
local getBackpackContents = Events.GetBackpackContents
local ServerScriptService = game:GetService("ServerScriptService")
local BackpackHandler = require(ServerScriptService:WaitForChild("Server").Player.BackpackHandler)

print("About to be invoked!")
local function getContents(Player) 
    print("Was invoked!")
    local contents = BackpackHandler:GetContents()
    return contents
end
getBackpackContents.OnServerInvoke = getContents




