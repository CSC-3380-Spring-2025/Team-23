
local ObjectGeneration = require(game.ServerScriptService.Workspace.ObjectGeneration)
local hill = game.Workspace.Terrain.Hill
local workspace = require(game.Workspace)
local treeModel = workspace["Flash Light"]

local ObjectGenerationInstance = ObjectGeneration.new("ObjectGenerationInstance")

ObjectGenerationInstance:SpawnItemsAtOnce(hill.Position.X, hill.Position.Z, hill.Size.X, hill.Size.Z, treeModel, hill, 25)