--[[
This class provides utilities for using mutex locks in paraell based threading.
Mutex locks should only be used when there is a risk of tasks coliding.
It is the users responsibility to avoid dead locks.
WARNING: This class is only intended to be used by actors that use true multithreading.
If you are trying to instead use a mutex lock for normal sequential based multithreading see ServerMutexSeq. 
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local ServerMutex = {}
Object:Supersedes(ServerMutex)

local globalServerLocks: {{boolean}} = {}

--[[
Constructor of a new mutex lock
    @param Key (any) a key that can be used to refrence the mutex by any script
    @return (instance) instance of the given object
--]]
function ServerMutex.new(Key: any) : ()
    local self = Object.new(Key)
    setmetatable(self, ServerMutex)
    self.__lock = {}
    --Retrieve mutex for key that already exists
    if not globalServerLocks[Key] then
        globalServerLocks[Key] = {locked = false}
    end
    self.__lock[Key] = globalServerLocks[Key]
    return self
end

--[[
Method for locking the given mutex lock
--]]
function ServerMutex:Lock() : ()
    --Spin lock
    while self.__lock[self.Name].locked do
        task.wait() 
    end
    task.synchronize()
    self.__lock.locked = true
end

--[[
Method for unlocking the given mutex lock
--]]
function ServerMutex:Unlock() : ()
    task.synchronize()
    self.__lock[self.Name].locked = false
end

return ServerMutex
