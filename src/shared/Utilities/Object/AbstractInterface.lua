--[[
This interface provides basic utilities for creating abstract methods.
--]]
local AbstractInterface = {}

--[[
    Warns the user of a class that an abstract funciton was not implemented
    @param FuncName (string) name of the function thats abstract
    @param ClassName (string) name of the class that owns this function
--]]
function AbstractInterface:AbstractError(FuncName, ClassName) : ()
    error("Attempted to use abstract function \"" .. FuncName .. "\" from abstract class \"" .. ClassName .. "\" while undefined")
end

--[[
Warns the user of a class that an abstract instance variable was not implemented
--]]
function AbstractInterface:AbstractVarError(VarName, ClassName)
    error("Attempted to use abstract instance \"" .. VarName .. "\" from abstract class \"" 
    .. ClassName .. "\" while undefined")
end

return AbstractInterface