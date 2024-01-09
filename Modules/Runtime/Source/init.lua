--[[
	@class Runtime

	Runtime is a simple wally package that helps to "initialize" core game modules. Ideally helping to cut down the "loader" script size and improve the
		look of the loader script.

	This package was inspired by sleitnicks 'Loader' class, please go check it out!
		- https://sleitnick.github.io/RbxUtil/api/Loader
]]
local Runtime = {}

Runtime.Public = {}
Runtime.Private = {}

Runtime.Private.FastFlags = {}

--[=[
	@method RequireChildren
	@within Runtime

	@param parent Instance
	@param middlewareFn (module: ModuleScript, content: { [any]: any }) -> { [any]: any }

	@return { { [any]: any } }

	A simple function that will iterate over a "Parent" instance's children and require all modules. This module will then return an array, containing the result of each `require` call

	```lua
		local Runtime = require(ReplicatedStorage.Packages.Runtime)

		Runtime:RequireChildren(script.Parent.Controllers, function(module: ModuleScript, moduleContent: { [any]: any })
			print(`Loaded module '{module.Name}'`)

			return moduleContent
		end)
	```
]=]
function Runtime.Public.RequireChildren(self: Runtime, parent: Instance, middlewareFn: Middleware?)
	local children = {}

	for _, object in parent:GetChildren() do
		if not object:IsA("ModuleScript") then
			continue
		end

		local requiredObject = require(object)

		if middlewareFn then
			requiredObject = middlewareFn(object, requiredObject)
		end

		table.insert(children, requiredObject)
	end

	return children
end

--[=[
	@method RequireDescendants
	@within Runtime

	@param parent Instance
	@param middlewareFn (module: ModuleScript, content: { [any]: any }) -> { [any]: any }

	@return { { [any]: any } }

	A simple function that will iterate over a "Parent" instance's descendants and require all modules. This module will then return an array, containing the result of each `require` call

	```lua
		local Runtime = require(ReplicatedStorage.Packages.Runtime)

		Runtime:RequireDescendants(script.Parent, function(module: ModuleScript, moduleContent: { [any]: any })
			print(`Loaded module '{module.Name}'`)

			return moduleContent
		end)
	```
]=]
function Runtime.Public.RequireDescendants(self: Runtime, parent: Instance, middlewareFn: Middleware?)
	local descendants = {}

	for _, object in parent:GetDescendants() do
		if not object:IsA("ModuleScript") then
			continue
		end

		local requiredObject = require(object)

		if middlewareFn then
			requiredObject = middlewareFn(object, requiredObject)
		end

		table.insert(descendants, requiredObject)
	end

	return descendants
end

--[=[
	@method CallMethodOn
	@within Runtime

	@param modules { { [any]: any } }
	@param methodName string
	@param arguments ...

	A simple function that will call a method on an array of tables. Useful when used in combination with `RequireDescendants`/`RequireChildren` calls.

	```lua
		local Runtime = require(ReplicatedStorage.Packages.Runtime)
		
		local gameConstants = {
			...
		}

		-- require all modules under the 'Controllers' instance, call 'OnInit'
		-- function in each module, if it exists, with the parameter of 'GameConstants!

		Runtime:CallMethodOn(Runtime:RequireChildren(script.Parent.Controllers), "OnInit", gameConstants)
	```
]=]
function Runtime.Public.CallMethodOn(self: Runtime, modules: { [any]: any }, methodName: string, ...)
	for _, module in modules do
		if not module[methodName] then
			continue
		end

		task.spawn(module[methodName], module, ...)
	end
end

--[=[
	@method SetFFValue
	@within Runtime

	@param ffName string
	@param value any

	A simple method to allow the developer to set runtime variables, useful when setting/getting metadata for the Runtime of a game.

	```lua
		local Runtime = require(ReplicatedStorage.Packages.Runtime)

		Runtime:RequireChildren(script.Parent.Controllers)
		Runtime:RequireChildren(script.Parent.Cameras)
		Runtime:RequireChildren(script.Parent.Components)

		Runtime:SetFFValue("IsLoaded", true)
		Runtime:SetFFValue("GameVersion", "0.1.0")
	```
]=]
function Runtime.Public.SetFFValue(self: Runtime, ffName: string, value: any)
	Runtime.Private.FastFlags[ffName] = value
end

--[=[
	@method GetFFValue
	@within Runtime

	@param ffName string

	Fetch the value of a fast flag set by a different script.

	```lua
		local Runtime = require(ReplicatedStorage.Packages.Runtime)

		local Module = {}

		function Module.OnInit()
			-- GameVersion is set by the loader script.

			Module.GameVersion = Runtime:GetFFValue("GameVersion")
		end

		return Module
	```
]=]
function Runtime.Public.GetFFValue(self: Runtime, ffName: string)
	return Runtime.Private.FastFlags[ffName]
end

export type Runtime = typeof(Runtime.Public)
export type Middleware = (module: ModuleScript, content: { [any]: any }) -> { [any]: any }

return Runtime.Public
