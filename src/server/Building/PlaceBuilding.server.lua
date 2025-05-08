
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceBuildingRemoteFunction : RemoteFunction =  ReplicatedStorage:FindFirstChild("PlaceBuildingRemoteFunction")


PlaceBuildingRemoteFunction:Connect(function(player, args)
	local buildingName = args.BuildingName
	local placementPosition = args.PlacementPosition
	local parentFolder = args.ParentFolder
	if not buildingName or not parentFolder or not placementPosition then return end
	local building = ReplicatedStorage.Buildings:FindFirstChild(buildingName, true):Clone()

	if building:IsA("Model") then
		building:SetPrimaryPartCFrame(CFrame.new(placementPosition))
		building.PrimaryPart.Parent = parentFolder
	elseif building:IsA("BasePart") then
		building.CFrame = CFrame.new(placementPosition)
		building.Parent = parentFolder
	end
end)



