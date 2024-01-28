local RunService = game:GetService("RunService")

local Terrain = workspace:FindFirstChildOfClass("Terrain")

local OFFSET = Vector3.new(0, 0.1, 0)

--[=[
	@class Windline

	Windline is a simple module to help create streaks of wind in a Roblox experience, this module was NOT created by me! This is a package that was created
		by Boatbomber! ( boatbomber - https://boatbomber.com )

	I have made small QoL adjustments and uploaded this module to Wally since there's not a version already avaliable.
]=]
local WindLines = {}

WindLines.Public = {}
WindLines.Private = {}

WindLines.Private.Lifetime = 3
WindLines.Private.Direction = workspace.GlobalWind
WindLines.Private.Speed = 6
WindLines.Private.SpawnRate = 25

WindLines.Private.LastSpawned = os.clock()

WindLines.Private.UpdateConnection = nil
WindLines.Private.UpdateQueue = table.create(10)

--[=[
	@method Init
	@within Windline

	@param settings { Lifetime: number?, Direction: Vector3?, Speed: number?, SpawnRate: number? }

	The initiation function that'll enable the Windlines module to spawn 3d windlines/streaks <SpawnRate> times a minute.

	- Lifetime is set to 3 by default
	- Direction is set to `workspace.GlobalWind` by default
	- Speed is set to 6 by default
	- SpawnRate is set to 25 by default

	```lua
		local Windline = require(ReplicatedStorage.Packages.Windline)
		
		Windline:Init({
			Lifetime = 3,
			Direction = workspace.GlobalWind,
			Speed = 6,
			SpawnRate = 25,
		})
	```
]=]
function WindLines.Public.Init(self: WindLines, settings: WindLineSettings?)
	-- Set defaults
	if settings then
		WindLines.Private.Lifetime = settings.Lifetime or WindLines.Private.Lifetime
		WindLines.Private.Direction = settings.Direction or WindLines.Private.Direction
		WindLines.Private.Speed = settings.Speed or WindLines.Private.Speed
		WindLines.Private.SpawnRate = settings.SpawnRate or WindLines.Private.SpawnRate
	end

	----------

	self:Cleanup()

	----------

	WindLines.Private.LastSpawned = os.clock()
	local SpawnRate = 1 / (WindLines.Private.SpawnRate or 25)

	-- Setup logic loop
	WindLines.Private.UpdateConnection = RunService.Heartbeat:Connect(function()
		local Clock = os.clock()

		-- Spawn handler
		if Clock - WindLines.Private.LastSpawned > SpawnRate then
			WindLines.Private:Create()
			WindLines.Private.LastSpawned = Clock
		end

		-- Update queue handler
		debug.profilebegin("Wind Lines")
		for i, WindLine in WindLines.Private.UpdateQueue do
			local AliveTime = Clock - WindLine.StartClock

			if AliveTime >= WindLine.Lifetime then
				-- Destroy the objects
				WindLine.Attachment0:Destroy()
				WindLine.Attachment1:Destroy()
				WindLine.Trail:Destroy()

				-- unordered remove at this index
				local Length = #WindLines.Private.UpdateQueue
				WindLines.Private.UpdateQueue[i] = WindLines.Private.UpdateQueue[Length]
				WindLines.Private.UpdateQueue[Length] = nil

				continue
			end

			WindLine.Trail.MaxLength = 20 - (20 * (AliveTime / WindLine.Lifetime))

			local SeededClock = (Clock + WindLine.Seed) * (WindLine.Speed * 0.2)
			local StartPos = WindLine.Position
			WindLine.Attachment0.WorldPosition = (CFrame.new(StartPos, StartPos + WindLine.Direction) * CFrame.new(
				0,
				0,
				WindLine.Speed * -AliveTime
			)).Position + Vector3.new(
				math.sin(SeededClock) * 0.5,
				math.sin(SeededClock) * 0.8,
				math.sin(SeededClock) * 0.5
			)

			WindLine.Attachment1.WorldPosition = WindLine.Attachment0.WorldPosition + OFFSET
		end
		debug.profileend()
	end)
end

--[=[
	@method Cleanup
	@within Windline

	@param settings { Lifetime: number?, Direction: Vector3?, Speed: number?, SpawnRate: number? }

	Cleanup all existing windline/streaks as well as flush the internal update queue.

	```lua
		local Windline = require(ReplicatedStorage.Packages.Windline)
		
		Windline:Cleanup()
	```
]=]
function WindLines.Public.Cleanup(self: WindLines)
	if WindLines.Private.UpdateConnection then
		WindLines.Private.UpdateConnection:Disconnect()
		WindLines.Private.UpdateConnection = nil
	end

	for _, WindLine in WindLines.Private.UpdateQueue do
		WindLine.Attachment0:Destroy()
		WindLine.Attachment1:Destroy()
		WindLine.Trail:Destroy()
	end

	table.clear(WindLines.Private.UpdateQueue)
end

--[=[
	@method Create
	@within Windline

	@param settings { Lifetime: number?, Direction: Vector3?, Speed: number?, Position: Vector3?, }

	Create a new wind streak, the 'settings' table passed defines the scope of this streak/line

	- Lifetime by default is set to what the `:Init` function settings has.
	- Direction by default is set to what the `:Init` function settings has.
	- Speed by default is set to what the `:Init` function settings has.
	- Position by default is set to a randomized point around the players camera.

	```lua
		local Windline = require(ReplicatedStorage.Packages.Windline)
		
		Windline:Create({
			Lifetime = 3,
			Direction = workspace.GlobalWind,
			Speed = 6,
			Position = workspace.Object.Position,
		})
	```
]=]
function WindLines.Public.Create(self: WindLines, settings: WindLineObjectSettings?)
	debug.profilebegin("Add Wind Line")

	local lifetime = WindLines.Private.Lifetime
	local direction = WindLines.Private.Direction
	local speed = WindLines.Private.Speed
	local position = (
		workspace.CurrentCamera.CFrame
		* CFrame.Angles(math.rad(math.random(-30, 70)), math.rad(math.random(-80, 80)), 0)
	) * CFrame.new(0, 0, math.random(200, 600) * -0.1).Position

	if settings then
		lifetime = settings.Lifetime or WindLines.Private.Lifetime
		direction = settings.Direction or WindLines.Private.Direction
		speed = settings.Speed or WindLines.Private.Speed
		position = settings.Speed or WindLines.Private.Position
	end

	if speed <= 0 then
		return
	end

	local Attachment0 = Instance.new("Attachment")
	local Attachment1 = Instance.new("Attachment")

	local Trail = Instance.new("Trail")
	Trail.Attachment0 = Attachment0
	Trail.Attachment1 = Attachment1
	Trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.2, 1),
		NumberSequenceKeypoint.new(0.8, 1),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	Trail.Transparency = NumberSequence.new(0.7)
	Trail.FaceCamera = true
	Trail.Parent = Attachment0

	Attachment0.WorldPosition = position
	Attachment1.WorldPosition = position + OFFSET

	local WindLine = {
		Attachment0 = Attachment0,
		Attachment1 = Attachment1,
		Trail = Trail,
		Lifetime = lifetime + (math.random(-10, 10) * 0.1),
		Position = position,
		Direction = direction,
		Speed = speed + (math.random(-10, 10) * 0.1),
		StartClock = os.clock(),
		Seed = math.random(1, 1000) * 0.1,
	}

	WindLines.Private.UpdateQueue[#WindLines.Private.UpdateQueue + 1] = WindLine

	Attachment0.Parent = Terrain
	Attachment1.Parent = Terrain

	debug.profileend()
end

export type WindLines = typeof(WindLines.Public)
export type WindLineSettings = {
	Lifetime: number?,
	Direction: Vector3?,
	Speed: number?,
	SpawnRate: number?,
}
export type WindLineObjectSettings = {
	Lifetime: number?,
	Direction: Vector3?,
	Speed: number?,
	Position: Vector3?,
}

return WindLines.Public
