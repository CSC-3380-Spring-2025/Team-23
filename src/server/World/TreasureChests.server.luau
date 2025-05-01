--[[
This script handles all treasure chests and their loot
--]]
local CollectionService: CollectionService = game:GetService("CollectionService")
local Workspace: Workspace = game:GetService("Workspace")
local ServerScriptService: ServerScriptService = game:GetService("ServerScriptService")
local GoldObject = require(ServerScriptService.Server.Currency.Gold)
local GoldAccessInstance = GoldObject.new("TreasureChestsGold")

--[[
Gives the player the amount of gold set by the Gold attribute in the chest model
    @param Chest (Model) the Model of the TreasureChest
    @param Player (Player) the player who is opening the chest
--]]
local function Gold(Chest: Model, Player: Player) : ()
    local goldAmount: number? = Chest:GetAttribute("Gold") :: number?
    if not goldAmount then 
        return--No gold in chest
    end
    --Give player gold
    GoldAccessInstance:ModAmountBy(Player, goldAmount)
end

--[[
Handles the loot given by the Chest. Any new loot types should be added here
    @param Chest (Model) the Model of the TreasureChest
    @param Player (Player) the player who is opening the chest
--]]
local function GiveLoot(Chest: Model, Player: Player) : ()
    Gold(Chest, Player)
end

--[[
Sets up the given Chest instance detected by CollectionService
    @param Chest (Model) the Model of the TreasureChest
--]]
local function HandleChest(Chest: Model)
    local promptPart: BasePart? = Chest:FindFirstChild("PromptPart") :: BasePart?
    if promptPart == nil then
        warn("Chest " .. Chest.Name .. "has no PromptPart")
        return
    end
    --Set up ProxPrompt
    local prompt: ProximityPrompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "Treasure Chest"
    prompt.ActionText = "Claim Rewards"
    prompt.HoldDuration = Chest:GetAttribute("HoldDuration") :: number? or 3
    prompt.Parent = promptPart
    prompt.RequiresLineOfSight = false
    prompt.Triggered:Connect(function(Player)
        --Handle all possible rewards
        GiveLoot(Chest, Player)
        Chest:Destroy()--Remove chest after finished
    end)
end

--Get already placed chests
for _, chest in pairs(CollectionService:GetTagged("TreasureChest")) do
    if not chest:IsDescendantOf(Workspace) then
        continue
    end
    HandleChest(chest)
end

--Get newly added chests as they are made
CollectionService:GetInstanceAddedSignal("TreasureChest"):Connect(function(Chest)
    HandleChest(Chest)
end)
