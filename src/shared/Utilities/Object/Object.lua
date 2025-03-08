--[[
This module script provides the basis for all inheritince.
All base classes MUST inherit from this.
In addition, it provides multiple utilities for an Object below.
--]]
local Object = {}
Object.__index = Object

function Object.new(Name: string) : any
    local self: any = setmetatable({}, Object)
    self.Name = Name or error("Class did not define \"Name\" when instantiated", 5)
    return self
end

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

function Object:IsInstance(Instance: any, Parent: any) : boolean
    local metaTable: any = getmetatable(Instance)

    --Iterate over the instance's meta table
    while metaTable do
        if metaTable == Parent then
            return true--Is instance of parent
        end
        metaTable = getmetatable(metaTable)
    end
    return false --Not instance of parent
end

function Object:IsObject(Instance: any, Object: any) : boolean
    local metaTable: any = getmetatable(Instance)
    if metaTable == Object then
        return true
    else
        return false
    end
end

function Object:TypeCast(Instance: any, Cast: any) : any
    if Object:IsInstance(Instance, Cast) then
        local castedInstance: any = Cast.new(Instance.Name)

        --Preserve the fields of previous instance if consistent with super class
        --local currentTable = getmetatable(Instance)

        for key, value in pairs(Instance) do
            if castedInstance[key] ~= nil then
                castedInstance[key] = NestedCopy(value) 
            end
        end
        return castedInstance
    else
        if (Instance.Name and Cast.Name) then
            error("Instance \"" .. Instance.Name .. "\" is not an instance of object \"" .. Cast.Name .. "\" and may not use TypeCast()", 5)
        else
            error("Instance is not an instance of given object and may not use TypeCast()", 5)
        end
    end
end

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

function Object:Supersedes(Class: any)
    Class.__index = Class
    setmetatable(Class, self)
end

return Object