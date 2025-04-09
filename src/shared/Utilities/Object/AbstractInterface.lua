--[[
This interface provides basic utilities for creating abstract methods.
--]]
local AbstractInterface = {}

--[[
    @param FuncName (string) name of the function thats abstract
    @param ClassName (string) name of the class that owns this function
--]]
function AbstractInterface:AbstractError(FuncName, ClassName) : ()
    error("Attempted to use abstract function \"" .. FuncName .. "\" from abstract class \"" .. ClassName .. "\" while undefined")
end

return AbstractInterface