--Services
local Players : Players = game:GetService("Players")

--Variables
local Backpacks : array = {}

local Handler = {}
Handler.__index = Handler

local BackpackSize : number = 150 -- How many items can be put into the backpack at its base?
local BackpackWeights : array = { -- Weight limits for different types of encumberance
    [50] = "Light";
    [70] = "Medium";
    [100] = "Heavy";
} 

local ToolStorage : Folder = game.ServerScriptService.Items

local Tools : array = {}

-- Functions

for i,v in pairs(ToolStorage:GetChildren()) do
local tool = require(v);
Tools[tool:GetName()] = tool
end

function Handler:CreateItem(ItemName : string, Amount : number) : table
if not Tools[ItemName] then 
    print("Item doesn't exist!") 
    return {} 
end
local Item = Tools[ItemName];
local MaxStack : number = Item:GetMaxStack();
local StacksToMake : number
local TotalInLastStack : number
if Amount > MaxStack then
  if Amount % MaxStack ~= 0 then
     while Amount > MaxStack do
        task.wait()
        Amount -= MaxStack;
        StacksToMake += 1
     end
     StacksToMake += 1
     TotalInLastStack = Amount;
else
   StacksToMake = Amount/MaxStack
end
else
    StacksToMake = 1
    TotalInLastStack = Amount
end
local CreatedItems : table = {}
for i = 1, StacksToMake do
    if not TotalInLastStack or i < StacksToMake then
       local Stack = Item.new(MaxStack)
       table.insert(CreatedItems, Stack)
    else
        local Stack = Item.new(TotalInLastStack)
        table.insert(CreatedItems, Stack)
    end
end
return CreatedItems
end

function Handler:GetWeight(Player : Player) : number
if not Backpacks[Player] then 
    return 0
end
return Backpacks[Player]["Weight"]
end

function Handler:GetContents(Player : Player) : array
    if not Backpacks[Player] then 
        return {}
    end
    return Backpacks[Player]["Contents"]
end

function Handler:GetTotalItems(Player : Player) : number
    if not Backpacks[Player] then 
        return 0
    end
    return Backpacks[Player]["TotalItems"]
end

function Handler:IsFull(Player : Player) : boolean
    if not Backpacks[Player] then 
        return false
    end
    return Backpacks[Player]["TotalItems"] >= Backpacks[Player]["Size"]
end

function Handler:AddToBackPack(Player : Player, ItemName:string, Stack : number,  ItemData : any) : ()
if not ItemData then
  ItemData = Handler:CreateItem(ItemName, Stack)
end
    if not Backpacks[Player] then
       Handler:CreateBackpack(Player, BackpackSize)
    end
    local TargetBackpack : array = Backpacks[Player]
   
    if TargetBackpack["TotalItems"] + Stack > TargetBackpack["Size"] then
    print("Not enough space in the backpack!")
    ItemData = nil -- Delete the reference so garbage collection cleans it up
    return
    end
    local AddedWeight : number = 0
    for i,v in pairs(ItemData) do
        AddedWeight += ItemData.Weight
        table.insert(TargetBackpack["Contents"], v)
        print("Inserted ".. v.Name.. "at stack " .. v.Stack .. "with weight ".. v.Weight)
        if ItemData.IsTool then
            ItemData.ID = game:GetService("HttpService"):GenerateGUID()
            table.insert(TargetBackpack["UseableItems"], v)
          end
    end
    local TotalWeight : number = TargetBackpack["Weight"] + AddedWeight
    local TargetWeight : number = 0
    local WeightClass : string
    for i,v in pairs(BackpackWeights) do
      if i <= TotalWeight and TargetWeight < TotalWeight then
        WeightClass = v
        TargetWeight = i
    end
end
        -- TODO: Tie this in with an overarching player handler so it doesn't edit their walkspeed seperately
    if WeightClass == "Light" then
        print("Player is at light weight!")
    elseif WeightClass == "Medium" then
        print("Player is at medium weight!")
    elseif WeightClass == "Heavy" then
        print("Player is at heavy weight!")
    end

    TargetBackpack.Weight += AddedWeight
    TargetBackpack.TotalItems += Stack 
end

function Handler:DropItem(Player:Player, ItemName : string, DropAmount : number) : ()
    if not Backpacks[Player] then
        print("How you gon drop something when you don't even have a backpack?")
        return
     end
     local Item = Tools[ItemName];
     local TargetBackpack : array = Backpacks[Player]
     for c,v in pairs(TargetBackpack["Contents"]) do
        --TODO: Get models and put a function here to interact with them and drop items
        if v.Amount >= DropAmount then
            v.Amount -= DropAmount
            TargetBackpack["Weight"] -= v.Weight
            print("Removed ".. v.Name.. "for " .. DropAmount .. "with weight ".. v.Weight)
            v.Weight = v:GetWeight() * v.Amount
            DropAmount -= v.Amount
            if v.Amount <= 0 then
            table.remove(TargetBackpack["Contents"], v)
            end
        end
        if DropAmount <= 0 then
            break
        end
    end
end

function Handler:MoveItemToToolbar(Player : Player, ItemData, ItemID : string) : ()

end
function Handler:CreateBackpack(Player : Player, Size : number) : ()
    if not Backpacks[Player] then
        Backpacks[Player] = {
            ["Size"] = Size or BackpackSize;
            ["Weight"] = 0;
            ["TotalItems"] = 0;
            ["Contents"] = {};
            ["UseableItems"] = {};
        }
    end
end

function Handler.new(Name, Amount)
    local self: table = setmetatable({}, Handler)
    self.Name = Name or "Item"
    self.Amount = Amount or 0
    return self
end

repeat task.wait() until game:GetService("Players"):GetChildren() ~= {}
for i,v in pairs(game:GetService("Players"):GetChildren()) do
Handler:AddToBackPack(v, "Coal", 150)
print(Handler:IsFull(v))
print(Handler:GetTotalItems(v))
print(Handler:GetContents(v))
print(Handler:GetWeight(v))
Handler:DropItem(v, "Coal", 50)
print(Handler:IsFull(v))
print(Handler:GetTotalItems(v))
print(Handler:GetContents(v))
print(Handler:GetWeight(v))
Handler:AddToBackPack(v, "Coal", 150)
end
--return Handler