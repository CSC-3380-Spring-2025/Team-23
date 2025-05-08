local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BridgeNet2 = require(game.ReplicatedStorage.BridgeNet2)
local __PlaceBuildingBridge = BridgeNet2.ReferenceBridge("PlaceBuilding")
local SpendResourcesToBuild = require(game.ServerScriptService.Server.Building.SpendResourcesToBuild)
local PlaceBuildingRemoteFunction = ReplicatedStorage:FindFirstChild("PlaceBuildingRemoteFunction")
local SpendResourcesToBuildInstance = SpendResourcesToBuild.new("SpendResourcesToBuildInstance")

--Recieve From client PlaceBuilding class to check if biulding schematic can be placed andp places it if it can.
PlaceBuildingRemoteFunction.OnServerInvoke = function(player: Player, args: {})
    local buildingName: string  = args.BuildingName
    local placementPosition: Vector3 = args.PlacementPosition
    local parentFolder: Instance = args.ParentFolder

    if not buildingName or not parentFolder or not placementPosition then return false end
    --check if player has enough resources to build
    local building = ReplicatedStorage.Buildings:FindFirstChild(buildingName, true):Clone()
    if not SpendResourcesToBuildInstance:AttemptToBuild(player, building) then return false end
    --send to class that will turn it to a building in progress
    if building:IsA("Model") then
        building:SetPrimaryPartCFrame(CFrame.new(placementPosition))
        building.Parent = parentFolder
    elseif building:IsA("BasePart") then
        building.CFrame = CFrame.new(placementPosition)
        building.Parent = parentFolder
    end
    return true
end



