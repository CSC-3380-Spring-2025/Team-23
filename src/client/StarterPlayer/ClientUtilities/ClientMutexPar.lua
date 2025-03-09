--[[
This class provides utilities for using mutex locks in paraell based threading.
Mutex locks should only be used when there is a risk of tasks coliding.
It is the users responsibility to avoid dead locks.
WARNING: This class is only intended to be used by actors that use true multithreading.
If you are trying to instead use a mutex lock for normal sequential based multithreading see ClientMutexSeq. 
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Object = require(ReplicatedStorage.Shared.Utilities.Object.Object)
local ClientMutexPar = {}
Object:Supersedes(ClientMutexPar)

local globalClientLocks: {{boolean}} = {}

--[[
Constructor of a new mutex lock
    @param Key (any) a key that can be used to refrence the mutex by any script
    @return (instance) instance of the given object
--]]
function ClientMutexPar.new(Key) : ()
    local self = Object.new(Key)
    setmetatable(self, ClientMutexPar)
    self.__lock = {}
    --Retrieve mutex for key that already exists
    if not globalClientLocks[Key] then
        globalClientLocks[Key] = {locked = false}
    end
    self.__lock[Key] = globalClientLocks[Key]
    return self
end

--[[
Method for locking the given mutex lock
--]]
function ClientMutexPar:Lock() : ()
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
function ClientMutexPar:Unlock() : ()
    task.synchronize()
    self.__lock[self.Name].locked = false
end

return ClientMutexPar
