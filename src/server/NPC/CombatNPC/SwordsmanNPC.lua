--[[
This class handles all SwordsmanNPCs and their behaivore
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local RaycastHitboxV4 = require(ReplicatedStorage.RaycastHitboxV4)
local CombatNPC = require(ServerScriptService.Server.NPC.CombatNPC.CombatNPC)
local NPCHandlerObject = require(ServerScriptService.Server.NPC.NPCHandlers.NPCHandler)
local SwordsmanNPC = {}
CombatNPC:Supersedes(SwordsmanNPC)

--Instances
local NPCHandler = NPCHandlerObject.new("NPCHandlerSwordsman")

--Vars
local attackRange = 5 --Distance in studs that the NPCs sword will activate

--[[
Constructor of the SwordsmanNPC class
    @param Name (string) name of the NPC
    @param Rig (rig) rig to make an NPC (the body)
    @param Health (number) health value to set NPC at
    @param SpawnPos (Vector3) position to spawn NPC at
    @param Speed (number) the walk speed of a NPC. Default of 16
    @param MaxStack (number) the number of stacks allowed for the backpack
    @param MaxWeight (number) max weight of an NPC
    @param MediumWeight (number) Weight at wich below you are light, 
    but above you are medium
    @param HeavyWeight (number) weight at wich you become heavy
    @param Backpack ({[ItemName]}) where [ItemName] has a .Count of item and 
    .Weight of whole item stack. Backpack is empty if not given.
    @param WhiteList ({string}) table of item names that may be added
    @param EncumbranceSpeed ({[Light, Medium, Heavy] = number}) a table of keys defined
    as Light, Medium, Heavy that have a value pair indicating the speed to go at each Encumbrance level
    if not provided then Light = -1/3speed, Heavy = -2/3 speed
	@param DeathHandler (boolean) if set to true enables the death handler for clean up or disables otherwise
	If you do not know what your doing, then you should set this to true.
	@param StatsConfig ({}) determines the config for the NPC's stats. Keys left out follow a default format
	see the table of statsconfig below in the cosntructor for more details in Backpack NPC
    @param AggroList ({string}) List of tags placed on a target that an NPC will check to see if it can Aggro
--]]
function SwordsmanNPC.new(
	Name: string,
	Rig: Model,
	Health: number,
	SpawnPos: Vector3,
	Speed: number,
	MaxStack: number,
	MaxWeight: number,
	MediumWeight: number,
	HeavyWeight: number,
	WhiteList: { string },
	Backpack: {}?,
	EncumbranceSpeed: {}?,
	DeathHandler: any,
	StatsConfig: {}?,
	AggroList: { string }
)
	local self = CombatNPC.new(
		Name,
		Rig,
		Health,
		SpawnPos,
		Speed,
		MaxStack,
		MaxWeight,
		MediumWeight,
		HeavyWeight,
		WhiteList,
		Backpack,
		EncumbranceSpeed,
		StatsConfig,
		AggroList
	)
	setmetatable(self, SwordsmanNPC)
	--Load animations
	return self
end

--[[
Handles what happens when a item is hit by the sword
    @param HitBox ({[any]: any}) the raycast system hitbox instance. Not the block
    @param Self ({[any]: any}) the instance of the class
    @param Damage (number) the amount of damage done on hits
--]]
local function HandleHits(HitBox: { [any]: any }, Self: { [any]: any }, Damage: number): ()
	Self.__Connections["Hit"] = HitBox.OnHit:Connect(function(HitPart, HitHum)
		HitHum:TakeDamage(20)
	end)
end

--[[
Cleans up the attack function
    @param HitBox ({[any]: any}) the raycast system hitbox instance. Not the block
    @param Animation (AnimationTrack) the animation track of the swing animation
    @param Self ({[any]: any}) the instance of the class
--]]
local function CleanUpAttack(HitBox: { [any]: any }, Animation: AnimationTrack, Self: { [any]: any })
	Animation.Stopped:Wait()
	Self.__Connections["Hit"]:Disconnect() --Disc hit connection
	HitBox:HitStop()
end

--[[
Activates the given weapon
    @param Self ({[any]: any}) the instance of the class
--]]
local function ActivateWeapon(Self: { [any]: any })
	local weapon: { [string]: any } = Self.__Weapon
	if not weapon then
		warn("Attempt to attack with SwordsmanNPC but no weapon set")
		return
	end
	local swingAnim: AnimationTrack? = weapon.Animations["Swing"]
	if not swingAnim then
		warn('Swing animations not in Animations folder of weapon for NPC "' .. Self.Name .. '"')
		return
	end
	local hitBox: { [any]: any } = weapon.Hitbox
	if not hitBox then
		warn('Hitbox not set for tool of NPC "' .. Self.Name .. '"')
		return
	end

	--Activate weapon
	local physTool: Tool = weapon.DropItem
	local damage: number? = physTool:GetAttribute("Damage") :: number?
	if not damage then
		warn('Damage attribute not set for tool of NPC "' .. Self.Name .. '"')
		return
	end
	HandleHits(hitBox, Self, damage)
	swingAnim:Play()
	hitBox:HitStart()
	CleanUpAttack(hitBox, swingAnim, Self)
end

--[[
Cancels an attack action
--]]
function SwordsmanNPC:CancelAttack(): ()
	if self.__Tasks.Attack then
		--Handle target death by no longer attacking
		self:Unfollow()
		--Instead of canceling attack allow it to end on its own to handle clean up
		self.__IsAttacking = false
	end
end

--[[
This function defines the behaivore of the Combat NPC when they
    are given a target to attack
    @param Target (Instance) any target instance to attack
--]]
function SwordsmanNPC:Attack(Target: Instance): ()
	if not self:CanTarget(Target) then
		warn("Attempt to attack invalid target")
		return
	end
	local rootPart: BasePart? = Target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return --has no root part to follow
	end
	--Handle target death
	local humanoid: Humanoid? = Target:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then
		return --No humanoid to track
	end
	humanoid.Died:Once(function()
		print("Target died!")
		self:CancelAttack()
	end)
	self:Follow(rootPart)
	--Keep checking if in range to attack
	self.__Tasks.Attack = task.spawn(function()
		self.__IsAttacking = true
		while self.__IsAttacking do
			if (self.__RootPart.Position - rootPart.Position).Magnitude <= attackRange then
				--Targets in range to attack
				ActivateWeapon(self)
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

--[[
Helper function used to find the NPCs target during SentryMode
    @param Self ({[any]: any}) the instance of the class
    @param AggroRadious (number) the number of studs within an NPC will attack a target
    in its AggroList
    @param EscapeRadious (number) the distance in studs that a NPC will give up on attacking a target
    @return (Model?) targets character on success or false otherwise
--]]
local function GetSentryTarget(Self: { [any]: any }, AggroRadious: number, EscapeRadious: number): Model?
	local targetMagnitudes: {} = {}
	--Loop through players first
	for _, player in pairs(Players:GetPlayers()) do
		--Get distance between player and NPC
		local character: Model? = player.Character
		if not character or not Self:CanTarget(character) then
			continue --Not a valid target so skip over
		end
		local distance: number = player:DistanceFromCharacter(Self.__RootPart.Position)
		if Self.__Target == character then
			--Is the existing target
			if distance >= EscapeRadious then
				Self.__Target = nil
				continue --Target escaped
			else
				table.insert(targetMagnitudes, { distance, character })
			end
		else
			--Not the existing target so check if better target
			if distance <= AggroRadious then
				--Can aggro
				table.insert(targetMagnitudes, { distance, character })
				continue
			end
		end
	end

	--Loop through for NPCs
	local allNPCs: { { [any]: any } }? = NPCHandler:GetAllNPCs()
	if allNPCs then
		--NPCs exist
		for _, NPCInstance in pairs(allNPCs) do
			if NPCInstance == Self then
				continue --Dont count itself
			end
			local NPCRootPart = NPCInstance.__RootPart
			local character: Model? = NPCInstance.__NPC
			if not character or not Self:CanTarget(character) then
				continue --Not a valid target so skip over
			end
			local distance = (NPCRootPart.Position - Self.__RootPart.Position).Magnitude
			if Self.__Target == character then
				--Is the existing target
				if distance >= EscapeRadious then
					Self.__Target = nil
					continue --Target escaped
				else
					table.insert(targetMagnitudes, { distance, character })
				end
			else
				--Not the existing target so check if better target
				if distance <= AggroRadious then
					--Can aggro
					table.insert(targetMagnitudes, { distance, character })
					continue
				end
			end
		end
	end
    
	table.sort(targetMagnitudes, function(a, b)
		return a[1] < b[1]
	end)

	if #targetMagnitudes > 0 then
		--Found atleast one target to attack
		return targetMagnitudes[1][2]
	end

	return nil --Failed to find target
end

--[[
Helper funtion that handles finding targets and attacking them for the NPC during SentryMode
    @param Self ({[any]: any}) the instance of the class
    @param AggroRadious (number) the number of studs within an NPC will attack a target
    in its AggroList
    @param EscapeRadious (number) the distance in studs that a NPC will give up on attacking a target
--]]
local function SentrySeekTarget(Self: { [any]: any }, AggroRadious: number, EscapeRadious: number): ()
	local returningHome: boolean = false
	while true do
		--print("Checking for target!")
		local target: Model? = GetSentryTarget(Self, AggroRadious, EscapeRadious)
		--print("Target is: ", target)
		if target == nil then
			--No target to attack anymore
			if returningHome then
				--Can skip
				RunService.Heartbeat:Wait()
				continue
			end

			Self.__Target = nil
			Self:CancelAttack()
			--If has home point then return home
			if not Self.__HomePoint then
				--No homepoint set so done
				RunService.Heartbeat:Wait()
				continue
			end

			Self:ReturnHome()
			returningHome = true
			Self.__Tasks.SwordsmanReturnHome = task.spawn(function()
				--Detect when NPC gets home
				while returningHome do
					if not Self:IsTraversing() then
						--Finished returning home
						returningHome = false
						return
					end
					RunService.Heartbeat:Wait()
				end
			end)
		elseif not (target == Self.__Target) then
			print("Attacking new target!")
			--New target to transition too
			Self.__Target = target
			local humanoid: Humanoid? = target:FindFirstChild("Humanoid") :: Humanoid?
			if not humanoid then
				RunService.Heartbeat:Wait()
				continue --No humanoid found so skip
			end
			--HandleSentryTargetDeath(Self, humanoid)
			Self:CancelAttack()
			returningHome = false
			--Set up new attack
			Self:Attack(target)
		end
		RunService.Heartbeat:Wait()
	end
end

--[[
Guards a specific area. If somthing comes within distance the NPC chaces after the target.
    If home point is set, after a target gets away or is killed it will return to the homepoint.
    If a homepoint is not set it will remain in its current pos
    @param AggroRadious (number) the radious in studs that the target must be in to pursue
    @param EscapeRadious (number) the radious in studs that when the target leaves,
    the NPC will stop going after the target
--]]
function SwordsmanNPC:SentryMode(AggroRadious: number, EscapeRadious: number): ()
	--Keep looking for target to lock on to and attack
	self.__Tasks.SentryMode = task.spawn(function()
		SentrySeekTarget(self, AggroRadious, EscapeRadious)
	end)
end

return SwordsmanNPC
