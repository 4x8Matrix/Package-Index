-- // Services
local RunService = game:GetService("RunService")

-- // External Imports
local Signal = require(script.Parent.Signal)

-- // Internal Imports
local Types = require(script.Types)

-- // Constants
local DEFAULT_LOGGING_SCHEMA = "[%s][%s] :: %s"
local MAXIMUM_CACHED_LOGS = 500
local PRETTY_TABLE_TAB = string.rep("\t", (RunService:IsStudio() and 1) or 5)

--[=[
	@class Console

	Console class description
]=]
local Console = { }

Console.Type = "Console"

Console.LogLevel = 1
Console.Schema = DEFAULT_LOGGING_SCHEMA

Console.Cache = setmetatable({}, { __mode = "kv" })

Console.Functions = { }
Console.Interface = { }
Console.Instances = { }
Console.Prototype = { }

Console.Interface.onMessageOut = Signal.new()
Console.Interface.LogLevel = {
	["Debug"] = 1,
	["Log"] = 2,
	["Warn"] = 3,
	["Error"] = 4,
	["Critical"] = 5,
}

-- // QoL functions
function Console.Functions:AddScopeToString(string)
	local stringSplit = string.split(string, "\n")

	for index, value in stringSplit do
		if index == 1 then
			continue
		end

		stringSplit[index] = string.format("%s%s", PRETTY_TABLE_TAB, value)
	end

	return table.concat(stringSplit, "\n")
end

function Console.Functions:ToPrettyString(...)
	local stringifiedObjects = { }

	for _, object in { ... } do
		local objectType = typeof(object)

		if objectType == "table" then
			if Console.Cache[object] then
				table.insert(stringifiedObjects, `RecursiveTable<{tostring(object)}>`)

				continue
			else
				Console.Cache[object] = true
			end

			local tableSchema = "{\n"
			local tableEntries = 0

			for key, value in object do
				tableEntries += 1

				key = self:ToPrettyString(key)

				if typeof(value) == "table" then
					value = self:AddScopeToString(self:ToPrettyString(value))
				else
					value = self:ToPrettyString(value)
				end

				tableSchema ..= string.format("%s[%s] = %s,\n", PRETTY_TABLE_TAB, key, value)
			end

			table.insert(stringifiedObjects, tableEntries == 0 and "{ }" or tableSchema .. "}")
		elseif objectType == "string" then
			table.insert(stringifiedObjects, string.format('"%s"', object))
		else
			table.insert(stringifiedObjects, tostring(object))
		end
	end

	return table.concat(stringifiedObjects, " ")
end

function Console.Functions:FormatVaradicArguments(...)
	local args = { ... }

	local message = string.rep("%s ", #args)
	local messageType = typeof(args[1])

	if messageType == "string" then
		message = table.remove(args, 1)
	end

	for index, value in args do
		args[index] = self:ToPrettyString(value)
	end

	table.clear(Console.Cache)

	return string.format(
		message,
		table.unpack(args)
	)
end

function Console.Functions:FormatMessageSchema(schema: string, source: string, ...)
	source = source or debug.info(2, "s")

	return string.format(
		schema, source, ...
	)
end

-- // Prototype functions
--[[
	Assertions, however written through our Console, if the condition isn't met, the Console will call :error on itself with the given message.

	### Parameters
	- **condition**: *the condition we are going to validate*
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Assert(1 == 1, "Hello, World!") -- > will output: nothing
		Console:Assert(1 == 2, "Hello, World!") -- > will output: [Console][error]: "Hello, World!" <stack attached>
	```
]]
function Console.Prototype:Assert(condition, ...): ()
	if not condition then
		self:Error(...)
	end
end

--[[
	Create a new log for 'critical', critical being deployed in a situation where something has gone terribly wrong.

	### Parameters
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Critical("Hello, World!") -- > will output: [Console][critical]: "Hello, World!" <stack attached>
	```
]]
function Console.Prototype:Critical(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(self.schema or Console.Schema, self.id, "critical", Console.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "critical", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Console.Interface.LogLevel.Critical or Console.LogLevel > Console.Interface.LogLevel.Critical then
		task.cancel(coroutine.running())

		return
	end

	Console.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	error(outputMessage, 2)
end

--[[
	Create a new log for 'error', this is for errors raised through a developers code on purpose.

	### Parameters
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Error("Hello, World!") -- > will output: [Console][error]: "Hello, World!" <stack attached>
	```
]]
function Console.Prototype:Error(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(self.schema or Console.Schema, self.id, "error", Console.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "error", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Console.Interface.LogLevel.Error or Console.LogLevel > Console.Interface.LogLevel.Error then
		task.cancel(coroutine.running())

		return
	end

	Console.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	error(outputMessage, 2)
end

--[[
	Create a new log for 'warn', this is for informing developers about something which takes precedence over a log

	### Parameters
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Warn("Hello, World!") -- > will output: [Console][warn]: "Hello, World!"
	```
]]
function Console.Prototype:Warn(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(self.schema or Console.Schema, self.id, "warn", Console.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "warn", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Console.Interface.LogLevel.Warn or Console.LogLevel > Console.Interface.LogLevel.Warn then
		return
	end

	Console.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	warn(outputMessage)
end

--[[
	Create a new log for 'log', this is for general logging - ideally what we would use in-place of print.

	### Parameters
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > will output: [Console][log]: "Hello, World!"
	```
]]
function Console.Prototype:Log(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(self.schema or Console.Schema, self.id, "log", Console.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "log", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Console.Interface.LogLevel.Log or Console.LogLevel > Console.Interface.LogLevel.Log then
		return
	end

	Console.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	print(outputMessage)
end

--[[
	Create a new log for 'debug', typically we should only use 'debug' when debugging code or leaving hints for developers.

	### Parameters
	- **...**: *anything, Console is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Debug("Hello, World!") -- > will output: [Console][debug]: "Hello, World!"
	```
]]
function Console.Prototype:Debug(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(self.schema or Console.Schema, self.id, "debug", Console.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "debug", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Console.Interface.LogLevel.Debug or Console.LogLevel > Console.Interface.LogLevel.Debug then
		return
	end

	Console.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	print(outputMessage)
end

--[[
	Set an log level for this Console, log levels assigned per Console override the global log level.

	### Parameters
	- **logLevel**: *The logLevel priority you only want to show in output*
		* *Log Levels are exposed through `Console.LogLevel`*

	### Returns
	- **Array**: *The array of logs created from this Console*

	---
	Example:

	```lua
		local Console = ConsoleModule.new("Console")

		ConsoleModule.setGlobalLogLevel(Console.LogLevel.Warn)

		Console:Log("Hello, World!") -- this will NOT output anything
		Console:Warn("Hello, World!") -- this will output something

		Console:SetLogLevel(Console.LogLevel.Log)

		Console:Log("Hello, World!") -- this will output something
		Console:Warn("Hello, World!") -- this will output something
	```
]]
function Console.Prototype:SetLogLevel(logLevel: number): ()
	self.level = logLevel
end

--[[
	Sets the state of the Console, state depicts if the Console can log messages into the output.

	### Parameters
	- **state**: *A bool to indicate weather this Console is enabled or not.*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > will output: [Console][log]: "Hello, World!"
		Console:SetState(false)
		Console:Log("Hello, World!") -- > will output: nothing
	```
]]
function Console.Prototype:SetState(state: boolean): ()
	self.enabled = state
end

--[[
	Fetch an array of logs generated through this Console

	### Parameters
	- **count**: *The amount of logs you're trying to retrieve*

	### Returns
	- **Array**: *The array of logs created from this Console*

	---
	Example:

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > [Console][log]: "Hello, World!"
		Console:FetchLogs() -- > [=[
			{
				"log",
				"[Console][log]: \"Hello, World!\"",
				"Console"
			}
		]=]--
	```
]]
function Console.Prototype:FetchLogs(count: number): { [number]: { logType: string, message: string, logId: string } }
	local fetchedLogs = {}

	if not count then
		return self.logs
	end

	for index = 1, count do
		if not self.logs[index] then
			return fetchedLogs
		end

		table.insert(fetchedLogs, self.logs[index])
	end

	return fetchedLogs
end

--[[
	Returns a prettified string version of the Console table.

	---
	Example:

	```lua
		local Value = State.new(0)

		print(tostring(Value)) -- Value<0>
	```
]]
function Console.Prototype:ToString(): string
	return `{Console.Type}<"{tostring(self.id)}">`
end

-- // Module functions
--[[
	Set the global log level for all Consoles, a log level is the priority of a log, priorities are represented by a number.

	### Parameters
	- **logLevel**: *The logLevel priority you only want to show in output*
		* *Log Levels are exposed through `Console.LogLevel`*

	---
	Example:

	```lua
		Console.setGlobalLogLevel(Console.LogLevel.Warn)

		Console:log("Hello, World!") -- this will NOT output anything
		Console:warn("Hello, World!") -- this will output something
	```
]]
function Console.Interface.setGlobalLogLevel(logLevel: number): ()
	Console.LogLevel = logLevel
end

--[[
	Set the global schema for all Consoles, a schema is how we display the output of a log.

	### Parameters
	- **schema**: *The schema you want all Consoles to follow*
		* **schema format**: *ConsoleName / logType / logMessage*
		* **example schema**: *[%s][%s]: %s*

	---
	Example:

	```lua
		Console.setGlobalSchema("[%s][%s]: %s")

		Console:log("Hello, World!") -- > [<ReporterName>][log]: Hello, World!
	```
]]
function Console.Interface.setGlobalSchema(schema: string): ()
	Console.Schema = schema
end

--[[
	Fetch a `Console` object through it's given `logId`

	### Parameters
	- **logId?**: *The name of the `Console` object you want to fetch*

	### Returns
	- **Console**: *The constructed `Console` prototype*
	- **nil**: *Unable to find the `Console`*

	---
	Example:

	```lua
		Console.get("Console"):log("Hello, World!") -- > [Console][log]: "Hello, World!"
	```
]]
function Console.Interface.get(logId: string): Types.Console | nil
	return Console.Instances[logId]
end

--[[
	Constructor to generate a `Console` prototype

	### Parameters
	- **logId?**: *The name of the `Console`, this will default to the calling script name.*
	- **schema?**: *The schema this paticular `Console` will follow*

	### Returns
	- **Console**: The constructed `Console` prototype

	---
	Example:

	```lua
		Console.new("Example"):log("Hello, World!") -- > [Example][log]: "Hello, World!"
	```
]]
function Console.Interface.new(logId: string?, schema: string?): Types.Console
	local self = setmetatable({
		id = logId,
		level = Console.Interface.LogLevel.Debug,
		schema = schema,
		enabled = true,
		logs = { },
	}, {
		__index = Console.Prototype,
		__type = Console.Type,
		__tostring = function(obj)
			return obj:ToString()
		end
	})

	if logId then
		Console.Instances[self.id] = self
	end

	return self
end

--[[
	Validate if an object is a 'Console' object

	### Parameters
	- **object**: *potentially an 'Console' object*

	---
	Example:

	```lua
		local object = Console.new("Test")

		if Console.is(object) then
			...
		end
	```
]]
function Console.Interface.is(object: Types.Console?): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Console.Type
end

return Console.Interface :: Types.ConsoleModule