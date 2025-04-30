--[[
This class provides utilities for using mutex locks in sequential based threading.
Mutex locks should only be used when there is a risk of tasks coliding.
It is the users responsibility to avoid dead locks.
WARNING: This class is not intended to be used on true parrel threade actors. Instead see ServerMutexPar. 
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local ServerMutex = {}
Object:Supersedes(ServerMutex)

local globalServerLocks: {{boolean}} = {} --Server global table that holds all server sequential based mutex locks

--[[
Constructor of a new mutex lock
    @param Key (any) a key that can be used to refrence the mutex by any script
    @return (instance) instance of the given object
--]]
function ServerMutex.new(Key: any) : ExtType.ObjectInstance
    local self = Object.new(Key)
    setmetatable(self, ServerMutex)
    self.__lock = {}
    --Retrieve mutex for key that already exists
    if not globalServerLocks[Key] then
        globalServerLocks[Key] = {locked = false, queue = {}}
    end
    self.__lock[Key] = globalServerLocks[Key]
    return self
end

--[[
Method for locking the given mutex lock
--]]
function ServerMutex:Lock() : ()
    local currentThread: thread = coroutine.running()
    table.insert(self.__lock[self.Name].queue, currentThread)

    while self.__lock[self.Name].queue[1] ~= currentThread or self.__lock[self.Name].locked do
        coroutine.yield()
    end

    --Get lock
    self.__lock[self.Name].locked = true
    table.remove(self.__lock[self.Name].queue, 1) --Pop front of que
end

--[[
Method for unlocking the given mutex lock
--]]
function ServerMutex:Unlock() : ()
    self.__lock[self.Name].locked = false

    --Resume next task in line
    if #self.__lock[self.Name].queue> 0 then
        task.spawn(self.__lock[self.Name].queue[1])
    end
end

return ServerMutex
