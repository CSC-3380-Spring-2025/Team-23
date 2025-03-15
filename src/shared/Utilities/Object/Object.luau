--[[
This module script provides the basis for all inheritince.
All base classes MUST inherit from this.
In addition, it provides multiple utilities for an Object below.
All objects inherit these utilities.
--]]
local Object : any = {}
Object.__index = Object --Set Object has lookup.

--[[
Base constructor of all Objects
    @param Name (string) required name of the instance you are creating 
    @return (instance) instance of the object.
--]]
function Object.new(Name: string) : any
    local self: any = setmetatable({}, Object)
    self.Name = Name or error("Class did not define \"Name\" when instantiated", 5)
    return self
end

--[[
Helper function that recursively copys all elements and its children
    @param Instance (instance) any Object instance
    @return (instance) copy of instance and a fresh copy of all its children 
--]]
local function NestedCopy(Instance: any) : any
    if type(Instance) ~= "table" then
        --Not table, recursive copy not needed.
        return Instance
    else
        --Table so need to create independant copy
        local tableCopy: any = {}
        for key, value in pairs(Instance) do
            tableCopy[key] = NestedCopy(value)
        end
        return tableCopy
    end
end

--[[
Determines if an object is an instance of another object
    @param Instance (instance) the instance to check for
    @param Parent (object) object asumed to be inherited from
    @return (boolean) returns true if is instance or false otherwise
--]]
function Object:IsInstance(Instance: any, Parent: any) : boolean
    local metaTable: any = getmetatable(Instance)

    --Iterate over the instance's meta table
    while metaTable do
        if metaTable == Parent then
            return true--Is instance of parent
        end
        metaTable = getmetatable(metaTable)--Traverse table
    end
    return false --Not instance of parent
end

--[[
Determines if an instance is of  a specific object type
    @param Instance (instance) the instance to check for being of that type
    @param Object (object) the object type asumed to be the same as instance
    @return (boolean) returns true if instance is of same object type or false otherwise
--]]
function Object:IsObject(Instance: any, Object: any) : boolean
    local metaTable: any = getmetatable(Instance)
    if metaTable == Object then
        return true
    else
        return false
    end
end

--[[
Casts a given instance into another object type and returns an entirely new instance
    any fields/methods not present in the object catsed to is removed
    any fields that are present in both recieves a one to one copy
    all table fields do not maintain a pass by refrence
    @param Instance (instance) instance of an object
    @param Cast (object) object type to be casted to
    @return (instance) new instance copy that is casted into the type of Cast
--]]
function Object:TypeCast(Instance: any, Cast: any) : any
    if Object:IsInstance(Instance, Cast) then
        local castedInstance: any = Cast.new(Instance.Name)

        --Preserve the fields of previous instance if consistent with super class
        for key, value in pairs(Instance) do
            if castedInstance[key] ~= nil then
                castedInstance[key] = NestedCopy(value) 
            end
        end
        return castedInstance
    else
        --Not instance and may not cast
        if (Instance.Name and Cast.Name) then
            error("Instance \"" .. Instance.Name .. "\" is not an instance of object \"" .. Cast.Name .. "\" and may not use TypeCast()", 5)
        else
            error("Instance is not an instance of given object and may not use TypeCast()", 5)
        end
    end
end

--[[
Checks if two instances have equal names and state. Must be a one to one copy.
    @param InstanceA (instance) first instance for checking against InstanceB
    @param InstanceB (instance) second instance for checking against InstanceA
    @return (boolean) true if one to one copies or false otherwise
--]]
function Object:Equal(InstanceA: any, InstanceB: any) : boolean
    --Check if keys in instance a are in instance b/have same value
    for key, value in pairs(InstanceA) do
        if type(value) == "table" then
            if not Object:Equal(value, InstanceB[key]) then
                return false
            end
        elseif InstanceB[key] ~= value then
            return false
        end
    end

    --Make sure all keys of B are included in A
    for key in pairs(InstanceB) do
        if InstanceA[key] == nil then
            return false
        end
    end

    return true--All keys and values match
end

--[[
Method for inheriting from the object (parent) who calls Supersedes
    Similiar to extends in Java but reversed.
    @param Class (object) class that is extending the parent class
--]]
function Object:Supersedes(Class: any) : ()
    Class.__index = Class
    setmetatable(Class, self)
end

return Object