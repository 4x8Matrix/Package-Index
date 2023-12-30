local Signal = require(script.Parent.Signal)

local MAX_RECORD_ALLOCATION = 15

--[=[
	@class State

	The `State` class represents an object that wraps around a Roblox datatype. State is NOT immutable, meaning any/all data that the State is handling will NOT account for changes to that value outside of State.

	---

	There is quite a few features that have been bundled into State, however Developers do not need to take advantage of them all, here's a small rundown of what you can do with state:

	- Record/Save previous states
		- For an example, this can come in handy if you need to record the player keystrokes
	- QoL functions for mutating state
		- State implements several QoL functions *(for ex: `Increment`, `Decrement`)* to allow developers to quickly mutate state without getting and setting values.
	- Support for Roblox Attributes
		- State will track and update Roblox Attributes on an Object, this can help quite a bit to remove the Roblox boilerplate for tracking when an Attribute has changed.
]=]
local State = {}

State.Type = "State"

State.Interface = {}
State.Prototype = {}

--[=[
	@prop Value any
	@within State
]=]

--[=[
	@prop Changed RBXScriptSignal
	@within State
]=]

--[=[
	@prop Destroyed RBXScriptSignal
	@within State
]=]

--[=[
	@method SetRecordingState
	@within State

	@param isRecording boolean

	Sets the state of recording, when recording all states will be saved into a history of states

	<Callout emoji="⚠️">
		A single state object can only save up to **15** previous states!
	</Callout>

	```lua
		local NumberState = State.new(0)
		
		NumberState:SetRecordingState(true)
	```
]=]
function State.Prototype:SetRecordingState(isRecording: boolean): State
	self._recording = isRecording

	return self
end

--[=[
	@method GetRecord
	@within State

	@param count number?

	@return { [number]: any }

	Retrieves an array of previous states that have been set

	```lua
		local NumberState = State.new(0)
		
		NumberState:SetRecordingState(true)

		for index = 1, 5 do
			NumberState:Set(index)
		end

		print(NumberState:GetRecord(3)) --> {
		--		[1] = 0,
		--		[2] = 1,
		--		[3] = ...
		--	}
	```
]=]
function State.Prototype:GetRecord(count: number): { [number]: any }
	if not count then
		return self._record
	end

	local record = {}

	for index = 1, count do
		record[index] = self._record[index]
	end

	return record
end

--[=[
	@method Destroy
	@within State

	Safe way to remove references to the `Value` as well as removing any generated content

	```lua
		local Value = State.new(0)

		...

		Value:Destroy()
	```
]=]
function State.Prototype:Destroy(): ()
	self._record = {}
	self.Value = nil

	self.Destroyed:Fire()
end

--[=[
	@method Set
	@within State

	@param value any

	Set the value of a state, when setting a state the 'Changed' signal will invoke.

	```lua
		local Value = State.new(0)

		Value:Set(1)
	```
]=]
function State.Prototype:Set(value: any): State
	local oldValue = self.Value

	if oldValue == value then
		return self
	end

	if self._recording then
		table.insert(self._record, 1, value)

		if #self._record > MAX_RECORD_ALLOCATION then
			self._record[#self._record] = nil
		end
	end

	self.Value = value
	self.Changed:Fire(oldValue, value)

	return self
end

--[=[
	@method Increment
	@within State

	@param value number

	Increments the value by a given input

	```lua
		local value = State.new(5)
			:Increment(5)

		print(value:Get()) -- 10
	```
]=]
function State.Prototype:Increment(value: number): State
	assert(
		type(self.Value) == "number",
		`Expected value to be a number when calling ':Increment', instead got {type(self.Value)}`
	)

	self:Set(self.Value + value)

	return self
end

--[=[
	@method Decrement
	@within State

	@param value number

	Decrement the value by a given input

	```lua
		local value = State.new(10)
			:Decrement(5)

		print(value:Get()) -- 5
	```
]=]
function State.Prototype:Decrement(value: number): State
	assert(
		type(self.Value) == "number",
		`Expected value to be a number when calling ':Decrement', instead got {type(self.Value)}`
	)

	self:Set(self.Value - value)

	return self
end

--[=[
	@method Concat
	@within State

	@param value string

	Concat the value by a given input

	```lua
		local Value = State.new("Hello ")
			:Concat("World!")

		print(value:Get()) -- Hello World!
	```
]=]
function State.Prototype:Concat(value: string): State
	assert(
		type(self.Value) == "string",
		`Expected value to be a string when calling ':Concat', instead got {type(self.Value)}`
	)

	self:Set(self.Value .. value)

	return self
end

--[=[
	@method Update
	@within State

	@param transformFn (value: any) -> any

	Will change the value of the state to the result of the transform function

	```lua
		local Value = State.new("Hello ")
			:Update(function(value)
				return value .. "World!"
			end)

		print(value:Get()) -- Hello World!
	```
]=]
function State.Prototype:Update(transform: (value: any) -> any): State
	assert(
		type(transform) == "function",
		`Expected #1 parameter 'transform' to be a function when calling ':Update', instead got {type(transform)}`
	)

	self:Set(transform(self.Value))

	return self
end

--[=[
	@method Get
	@within State

	@return any

	Fetches the value that the State currently holds.

	<Callout emoji="ℹ️">
		As an alternative, `State` offers a `.Value` property which you can directly refer to.
	</Callout>

	```lua
		local Value = State.new(0)
		local resolve = Value:Get()
	```
]=]
function State.Prototype:Get(): any
	return self.Value
end

--[=[
	@method Observe
	@within State

	@param callbackFn (oldValue: any, newValue: any) -> ()

	@return RBXScriptConnection

	Quick QoL function to observe any changes made to the states value

	```lua
		local Value = State.new(0)

		Value:Observe(function(oldValue, newValue)
			doSomething(oldValue, newValue)
		end)
	```
]=]
function State.Prototype:Observe(callbackFn: (oldValue: any, newValue: any) -> ()): RBXScriptConnection
	task.spawn(callbackFn, nil, self.Value)

	return self.Changed:Connect(callbackFn)
end

--[=[
	@method ToString
	@within State

	@return string

	Returns a prettified string version of the state table.

	```lua
		local Value = State.new(0)

		print(tostring(Value)) -- Value<0>
	```
]=]
function State.Prototype:ToString()
	return `{State.Type}<{tostring(self.Value)}>`
end

--[=[
	@function new
	@within State

	@param value any

	@return State

	Constructor function used to generate a new 'State' object

	```lua
		local object = State.new("Hello, World!")

		...
	```
]=]
function State.Interface.new(value: any): State
	local self = setmetatable({ Value = value, _record = { value } }, {
		__type = State.Type,
		__index = State.Prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	self.Changed = Signal.new()
	self.Destroyed = Signal.new()

	return self
end

--[=[
	@function fromAttribute
	@within State

	@param object Instance
	@param attribute string

	@return State

	Wrapper for `State.new` however wraps around a Roblox attribute, the State object will always have the latest attribute value.

	```lua
		local object = State.fromAttribute(workspace.object, "attributeName")

		...
	```
]=]
function State.Interface.fromAttribute(object: Instance, attribute: string): State
	local attributeValue = object:GetAttribute(attribute)
	local stateObject = State.Interface.new(attributeValue)

	local attributeConnections = {}

	table.insert(
		attributeConnections,
		object:GetAttributeChangedSignal(attribute):Connect(function()
			stateObject:Set(object:GetAttribute(attribute))
		end)
	)

	stateObject.Destroyed:Once(function()
		for _, connection in attributeConnections do
			connection:Disconnect()
		end
	end)

	return stateObject
end

--[=[
	@function is
	@within State

	@param object State?

	@return boolean?

	Validate if an object is a 'State' object

	```lua
		local object = State.new("Hello, World!")

		if State.is(object) then
			...
		end
	```
]=]
function State.Interface.is(object: State?): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == State.Type
end

export type State = typeof(State.Prototype) & {
	Value: any,
}

return State.Interface
