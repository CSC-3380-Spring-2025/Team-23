--[[
This script defines all main custom types. All types must have documentation and a clear use case for it.
If you are making a custom type that will not be used often make another export script for types.
All scripts that use these custom types must require this script.
--]]

--[[
ObjectInstance is the type for any and all Object instances.
All cosntructors of any object should return this type.
--]]
export type ObjectInstance = {[any]: any}

--[[
An instance of a BridgeNet
All refrenceBridges should be defined as this type.
--]]
export type Bridge = {[any]: any}

--[[
Defines the type for any string indexed dictionary
--]]
export type StrDict = {[string]: any}

--[[
Defines the type for any a dictionary that uses any index
--]]
export type AnyDict = {[any]: any}

--[[
The return of a module script being used purely for info.
Example: ItemInfo mod scripts
--]]
export type InfoMod = StrDict

--[[
Defines the type for any instance of the RaycastHitboxV4.new
--]]
export type RaycastHitbox = {[any]: any}

return nil--Prevents script from being used as a module script