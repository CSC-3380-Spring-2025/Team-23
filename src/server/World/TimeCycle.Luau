-- Services
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
-- Variables
local CurrentTime : number = 10 * 100 -- Local track of current time of day
local SECONDS_IN_A_DAY : number = 60 * 10 -- Increment for time, make higher for days to go faster
local TimeIncrement = 0.01 -- Increment for time, make higher for days to go faster
local TimeCycle : table = {}

local Enabled : RBXScriptConnection -- Holder for the runservice loop connection 

local States : table = {} -- Description of time period for lighting effects
States.Sunset = {16, 18} -- Sunset occurs between these two times
States.Night = {18, 6} -- Night occurs between these two times
States.Day = {6, 16} -- Day occurs between these two times
local State: table = States.Day -- Current state of the ingame lighting (Day, sunset, night)

local CurrentPeriod : string  = "Day" -- String definition of time period

--Functions

--@Description: Gets the time as described inside of the module and returns it
--@Return: Current time (Number)
function TimeCycle:GetCurrentTime() : number
    return CurrentTime
end

--@Description: Changes the current time to the new number
--@Param NewTime: Time the world should be set to.
function TimeCycle:ChangeTime(NewTime : number) : ()
	CurrentTime = math.clamp(NewTime, 0, 24) * 100
end

--@Description: Changes the current time increment to make the day/night cycle faster/slower
--@Param NewTime: Number the increment should be set to.
function TimeCycle:ChangeIncrement(NewIncrement : number) : ()
	TimeIncrement = NewIncrement
end

--@Description: Gets the day period the script is in.
--@Return: Current day period (String)
function TimeCycle:GetCurrentPeriod() : string
    return CurrentPeriod
 end

 function TimeCycle:ChangeCurrentState(State : string) : ()
    if State == "Day" then
		CurrentTime = 10 * 100
		TimeCycle:Update()
	elseif State == "Sunset" then
		CurrentTime = 18 * 100
		TimeCycle:Update()
	elseif State == "Night" then
		CurrentTime = 18 * 100
		TimeCycle:Update()
	end
 end

 --@Description: Changes the current environment to match a sunset time period.
 --@Return: N/A
function TimeCycle:UpdateSunsetEnvironment() : ()
	--TODO: Play around with effects to make a good sunset
	State = States.Sunset;
    CurrentPeriod = "Sunset"
end

 --@Description: Changes the current environment to match a night time period.
 --@Return: N/A
function TimeCycle:UpdateNightEnvironment() : ()
	--TODO: Play around with effects to make a good night
	State = States.Night;
	local List1 : table = CollectionService:GetTagged("NightLight")
	for i : any ,v : any in pairs(List1) do
	   if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
		v.Enabled = true
	   elseif v:IsA("BasePart") then
		for c,d in pairs(v:GetChildren()) do
			if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
				v.Enabled = true
			end
		end
	   end
	end
	local List2 : table = CollectionService:GetTagged("DayLight")
	for i : any ,v : any in pairs(List2) do
	   if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
		v.Enabled = false
	   elseif v:IsA("BasePart") then
		for c,d in pairs(v:GetChildren()) do
			if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
				v.Enabled = false
			end
		end
	   end
	end
    CurrentPeriod = "Night"
end

 --@Description: Changes the current environment to match a day time period.
 --@Return: N/A
function TimeCycle:UpdateDayEnvironment() : ()
		--TODO: Play around with effects to make a good day
		local List1 : table = CollectionService:GetTagged("NightLight")
		for i : any ,v : any in pairs(List1) do
			if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
			 v.Enabled = false
			elseif v:IsA("BasePart") then
			 for c,d in pairs(v:GetChildren()) do
				 if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					 v.Enabled = false
				 end
			 end
			end
		 end
		 local List2 : table = CollectionService:GetTagged("DayLight")
		 for i : any ,v : any in pairs(List2) do
			if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
			 v.Enabled = true
			elseif v:IsA("BasePart") then
			 for c,d in pairs(v:GetChildren()) do
				 if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					 v.Enabled = true
				 end
			 end
			end
		 end
	State = States.Day
    CurrentPeriod = "Day"
end

 --@Description: Checks to see if the current time period needs to be switched based on current time as recorded within the module.
 --@Return: N/A
function TimeCycle:Update() : ()
    local TimeStamp: number = CurrentTime or 10
	if (TimeStamp > States.Sunset[1] and 
		TimeStamp < States.Sunset[2]) and not (State == States.Sunset) then
            TimeCycle:UpdateSunsetEnvironment()
	elseif ((TimeStamp > States.Night[1] and TimeStamp <= 24)
		or (TimeStamp >= 0 and TimeStamp < States.Night[2])) and not (State == States.Night) then
            TimeCycle:UpdateNightEnvironment()
	elseif (TimeStamp > States.Day[1] and 
		TimeStamp < States.Day[2]) and not (State == States.Day) then
            TimeCycle:UpdateDayEnvironment()
	end
end

 --@Description: Increments the timecycle and updates the current time inside of the module.
 --@Return: N/A
function TimeCycle:Step() : ()
	local Time = CurrentTime or 10
	local PercentInCurrentDay = Time % SECONDS_IN_A_DAY / SECONDS_IN_A_DAY
	local SetNewTimeStamp =  (PercentInCurrentDay * 24)
	SetNewTimeStamp = (SetNewTimeStamp > 24 and SetNewTimeStamp - 12) or SetNewTimeStamp
	Lighting.ClockTime = SetNewTimeStamp
    CurrentTime += TimeIncrement
		if SetNewTimeStamp > 24 then 
            CurrentTime = 0
		end
	TimeCycle:Update()
end

 --@Description: Starts the timecycle.
 --@Return: N/A
function TimeCycle:Start() : ()
	Lighting:ClearAllChildren()
	if not workspace.Terrain:FindFirstChildWhichIsA("Clouds") then --Critical for changing the atmosphere as the day progresses
		Instance.new("Clouds", workspace.Terrain)
	end
	TimeCycle:Update()
	if Enabled then --Check to make sure start hasn't already been called, and disconnect the loop if it has
        Enabled:Disconnect()
    end
	Enabled = RunService.Heartbeat:Connect(function() -- main time control loop
		TimeCycle:Step()
	end)
end

 --@Description: Ends the timecycle.
 --@Return: N/A
function TimeCycle:Stop() : ()
    if Enabled then
        Enabled:Disconnect()
    end
end

--Uncomment this for testing purposes as needed

--TimeCycle:Start()