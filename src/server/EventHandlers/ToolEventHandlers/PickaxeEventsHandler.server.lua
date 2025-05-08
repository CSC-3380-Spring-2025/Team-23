local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService: ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ExtType = require(ReplicatedStorage.Shared.ExtType)
local BackpackHandler = require(ServerScriptService.Server.Player.BackpackHandler)
local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

--Events
local HandleAxeStrikeEvent: ExtType.Bridge = BridgeNet2.ReferenceBridge("GiveOre")
HandleAxeStrikeEvent:Connect(function(Player, Args)
    local ore: string = Args.Ore
    local amount: number = Args.Amount
    BackpackHandler:AddItemToBackPack(Player, ore, amount)
end)
