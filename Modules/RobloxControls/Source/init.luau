local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Promise = require(script.Parent.Promise)

local FREEZE_ACTION = "RobloxControls-FreezeAction"

local resetRequestedBindable = Instance.new("BindableEvent")
local gameCoreGuiElements = {
	Enum.CoreGuiType.All,
}

--[=[
	@class RobloxControls

	RobloxControls is a package that wraps around Roblox CoreGui and Core actions, in the hopes of reducing boilerplate
	code and improving the interaction between Roblox v Developer.

	When this module is required, it will by default disable Respawning, this module implements it's own Respawn loop.
]=]
local RobloxControls = {}

RobloxControls.Public = {}
RobloxControls.Private = {}

function RobloxControls.Private.OnRespawnCharacterRequested()
	local localPlayer = Players.LocalPlayer
	local character = localPlayer.Character
	
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	humanoid.Health = 0
end

--[=[
	@method SetCoreAsync
	@within RobloxControls

	@return promise

	Wraps a `:SetCore` call into a promise, will attempt to keep calling `:SetCore` if the initial request failed.

	This method is useful to combat Core actions being called, before Roblox has registered them:

	> SetCore: ResetButtonCallback has not been registered by the CoreScripts

	```lua
		RobloxControls:SetCoreAsync("SendNotification", {
			Title = "Example Core Notification",
			Text = "Hello, World!"
		})
	```
]=]
function RobloxControls.Public.SetCoreAsync(self: RobloxControls, ...)
	local setCoreParameters = { ... }

	return Promise.new(function(resolve)
		local success
		local response

		while not success do
			success, response = pcall(StarterGui.SetCore, StarterGui, table.unpack(setCoreParameters))

			if not success then
				warn(response)
			end

			task.wait(0.5)
		end

		return resolve()
	end)
end

--[=[
	@method GetCoreAsync
	@within RobloxControls

	@return promise

	Wraps a `:GetCore` call into a promise, will attempt to keep calling `:GetCore` if the initial request failed.

	This method is useful to combat Core actions being called, before Roblox has registered them:

	> GetCore: ResetButtonCallback has not been registered by the CoreScripts

	```lua
		local isDevConsoleVisible = RobloxControls:GetCoreAsync("DevConsoleVisible"):expect()
	```
]=]
function RobloxControls.Public.GetCoreAsync(self: RobloxControls, ...)
	local getCoreParameters = { ... }

	return Promise.new(function(resolve)
		local success
		local response

		while not success do
			success, response = pcall(StarterGui.SetCore, StarterGui, table.unpack(getCoreParameters))

			if not success then
				warn(response)
			end

			task.wait(0.5)
		end

		return resolve(response)
	end)
end

--[=[
	@method SetRespawnCallback
	@within RobloxControls

	Set the respawn callback, this callback will be invoked when the player resets their character through the roblox Core UI.

	```lua
		RobloxControls:SetRespawnCallback(function()
			print("Local-Player has tried to reset their character!")
		end)
	```
]=]
function RobloxControls.Public.SetRespawnCallback(self: RobloxControls, callback: () -> ())
	RobloxControls.Private.OnRespawnCharacterRequested = callback
end

--[=[
	@method DisableRespawning
	@within RobloxControls

	Convenience method for disabling respawning

	```lua
		RobloxControls:DisableRespawning()
	```
]=]
function RobloxControls.Public.DisableRespawning(self: RobloxControls)
	self:SetCoreAsync("ResetButtonCallback", false)
end

--[=[
	@method EnableRespawning
	@within RobloxControls

	Convenience method for enabling respawning

	```lua
		RobloxControls:EnableRespawning()
	```
]=]
function RobloxControls.Public.EnableRespawning(self: RobloxControls)
	self:SetCoreAsync("ResetButtonCallback", resetRequestedBindable)
end

--[=[
	@method SetDefaultCoreGui
	@within RobloxControls

	Enables a developer to specify specific Core Gui elements that will be rendered in the current place.

	Any elements that are NOT passed into this function, will be disabled, and should remain disabled.

	```lua
		RobloxControls:SetDefaultCoreGui(
			Enum.CoreGuiType.Chat -- the current game will ONLY support the Chat Core UI
		)
	```
]=]
function RobloxControls.Public.SetDefaultCoreGui(self: RobloxControls, ...)
	gameCoreGuiElements = { ... }

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	for _, coreGuiType in gameCoreGuiElements do
		StarterGui:SetCoreGuiEnabled(coreGuiType, true)
	end
end

--[=[
	@method EnableCoreGui
	@within RobloxControls

	Enables the CoreGui specified through the `:SetDefaultCoreGui` method.

	```lua
		RobloxControls:EnableCoreGui()
	```
]=]
function RobloxControls.Public.EnableCoreGui(self: RobloxControls)
	for _, coreGuiType in gameCoreGuiElements do
		StarterGui:SetCoreGuiEnabled(coreGuiType, true)
	end
end

--[=[
	@method DisableCoreGui
	@within RobloxControls

	Disables the CoreGui specified through the `:SetDefaultCoreGui` method.

	```lua
		RobloxControls:EnableCoreGui()
	```
]=]
function RobloxControls.Public.DisableCoreGui(self: RobloxControls)
	for _, coreGuiType in gameCoreGuiElements do
		StarterGui:SetCoreGuiEnabled(coreGuiType, false)
	end
end

--[=[
	@method DisableCharacterInput
	@within RobloxControls

	Disables player-character input.

	```lua
		RobloxControls:DisableCharacterInput()
	```
]=]
function RobloxControls.Public.DisableCharacterInput(self: RobloxControls)
	ContextActionService:BindAction(
		FREEZE_ACTION,
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		table.unpack(Enum.PlayerActions:GetEnumItems())
	)
end

--[=[
	@method EnableCharacterInput
	@within RobloxControls

	Enables player-character input.

	```lua
		RobloxControls:EnableCharacterInput()
	```
]=]
function RobloxControls.Public.EnableCharacterInput(self: RobloxControls)
	ContextActionService:UnbindAction(FREEZE_ACTION)
end

RobloxControls.Public:DisableRespawning()
resetRequestedBindable.Event:Connect(function()
	RobloxControls.Private.OnRespawnCharacterRequested()
end)

type RobloxControls = typeof(RobloxControls.Public)

return RobloxControls.Public