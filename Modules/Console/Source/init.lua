local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

local DEFAULT_LOGGING_SCHEMA = "[%s][%s] :: %s"
local MAXIMUM_CACHED_LOGS = 500
local PRETTY_TABLE_TAB = string.rep("\t", (RunService:IsStudio() and 1) or 5)

--[=[
	@class Console

	A package that helps to organise the Roblox output, primarily offering developers quality of life features over the default Roblox output behaviour.
]=]
local Console = {}

--[=[
	@prop id string
	@within Console
]=]

--[=[
	@prop level number
	@within Console
]=]

--[=[
	@prop schema string
	@within Console
]=]

--[=[
	@prop enabled boolean
	@within Console
]=]

--[=[
	@prop logs { }
	@within Console
]=]

Console.Type = "Console"

Console.LogLevel = 1
Console.Schema = DEFAULT_LOGGING_SCHEMA

Console.Cache = setmetatable({}, { __mode = "kv" })

Console.Functions = {}
Console.Interface = {}
Console.Instances = {}
Console.Prototype = {}

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
	local stringifiedObjects = {}

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

	return string.format(message, table.unpack(args))
end

function Console.Functions:FormatMessageSchema(schema: string, source: string, ...)
	source = source or debug.info(2, "s")

	return string.format(schema, source, ...)
end

--[=[
	@method Assert
	@within Console

	@param condition boolean?
	@param message ...

	Assertions, however written through our Console, if the condition isn't met, the Console will call :error on itself with the given message.

	```lua
		local Console = Console.new("Console")

		Console:Assert(1 == 1, "Hello, World!") -- > will output: nothing
		Console:Assert(1 == 2, "Hello, World!") -- > will output: [Console][error]: "Hello, World!" <stack attached>
	```
]=]
function Console.Prototype:Assert(condition, ...): ()
	if not condition then
		self:Error(...)
	end
end

--[=[
	@method Critical
	@within Console

	@param message ...

	Create a new log for 'critical', critical being deployed in a situation where something has gone terribly wrong.

	```lua
		local Console = Console.new("Console")

		Console:Critical("Hello, World!") -- > will output: [Console][critical]: "Hello, World!" <stack attached>
	```
]=]
function Console.Prototype:Critical(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(
		self.schema or Console.Schema,
		self.id,
		"critical",
		Console.Functions:FormatVaradicArguments(...)
	)

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

--[=[
	@method Assert
	@within Console

	@param message ...

	Create a new log for 'error', this is for errors raised through a developers code on purpose.

	```lua
		local Console = Console.new("Console")

		Console:Error("Hello, World!") -- > will output: [Console][error]: "Hello, World!" <stack attached>
	```
]=]
function Console.Prototype:Error(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(
		self.schema or Console.Schema,
		self.id,
		"error",
		Console.Functions:FormatVaradicArguments(...)
	)

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

--[=[
	@method Warn
	@within Console

	@param message ...

	Create a new log for 'warn', this is for informing developers about something which takes precedence over a log

	```lua
		local Console = Console.new("Console")

		Console:Warn("Hello, World!") -- > will output: [Console][warn]: "Hello, World!"
	```
]=]
function Console.Prototype:Warn(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(
		self.schema or Console.Schema,
		self.id,
		"warn",
		Console.Functions:FormatVaradicArguments(...)
	)

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

--[=[
	@method Log
	@within Console

	@param message ...

	Create a new log for 'log', this is for general logging - ideally what we would use in-place of print.

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > will output: [Console][log]: "Hello, World!"
	```
]=]
function Console.Prototype:Log(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(
		self.schema or Console.Schema,
		self.id,
		"log",
		Console.Functions:FormatVaradicArguments(...)
	)

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

--[=[
	@method Debug
	@within Console

	@param message ...

	Create a new log for 'debug', typically we should only use 'debug' when debugging code or leaving hints for developers.

	```lua
		local Console = Console.new("Console")

		Console:Debug("Hello, World!") -- > will output: [Console][debug]: "Hello, World!"
	```
]=]
function Console.Prototype:Debug(...): ()
	local outputMessage = Console.Functions:FormatMessageSchema(
		self.schema or Console.Schema,
		self.id,
		"debug",
		Console.Functions:FormatVaradicArguments(...)
	)

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

--[=[
	@method SetLogLevel
	@within Console

	@param logLevel number 

	Set an log level for this Console, log levels assigned per Console override the global log level.

	LogLevels that are by default set in `Console`:

	- 1 = Debug
	- 2 = Log
	- 3 = Warn
	- 4 = Error
	- 5 = Critical

	<Callout emoji="ℹ️">
		As an alternative, Console provides a `LogLevel` enum, you can access this enum like: `Console.LogLevel.Debug`
	</Callout>

	```lua
		local Console = ConsoleModule.new("Console")

		ConsoleModule.setGlobalLogLevel(Console.LogLevel.Warn)

		Console:Log("Hello, World!") -- this will NOT output anything
		Console:Warn("Hello, World!") -- this will output something

		Console:SetLogLevel(Console.LogLevel.Log)

		Console:Log("Hello, World!") -- this will output something
		Console:Warn("Hello, World!") -- this will output something
	```
]=]
function Console.Prototype:SetLogLevel(logLevel: number): ()
	self.level = logLevel
end

--[=[
	@method SetState
	@within Console

	@param state: boolean

	Sets the state of the Console, state depicts if the Console can log messages into the output.

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > will output: [Console][log]: "Hello, World!"
		Console:SetState(false)
		Console:Log("Hello, World!") -- > will output: nothing
	```
]=]
function Console.Prototype:SetState(state: boolean): ()
	self.enabled = state
end

--[=[
	@method FetchLogs
	@within Console

	@param count: number?

	@return { [number]: { logType: string, message: string, logId: string } }

	Fetch an array of logs generated through this Console

	```lua
		local Console = Console.new("Console")

		Console:Log("Hello, World!") -- > [Console][log]: "Hello, World!"
		Console:FetchLogs() -- > [[
			{
				"log",
				"[Console][log]: \"Hello, World!\"",
				"Console"
			}
		]]--
	```
]=]
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

--[=[
	@method ToString
	@within Console

	@return string

	Returns a prettified string version of the Console table.

	```lua
		local Value = State.new(0)

		print(tostring(Value)) -- Value<0>
	```
]=]
function Console.Prototype:ToString(): string
	return `{Console.Type}<"{tostring(self.id)}">`
end

--[=[
	@function setGlobalLogLevel
	@within Console

	@param logLevel number

	Set the global log level for all Consoles, a log level is the priority of a log, priorities are represented by a number.

	LogLevels that are by default set in `Console`:

	- 1 = Debug
	- 2 = Log
	- 3 = Warn
	- 4 = Error
	- 5 = Critical

	<Callout emoji="ℹ️">
		As an alternative, Console provides a `LogLevel` enum, you can access this enum like: `Console.LogLevel.Debug`
	</Callout>

	```lua
		Console.setGlobalLogLevel(Console.LogLevel.Warn)

		Console:log("Hello, World!") -- this will NOT output anything
		Console:warn("Hello, World!") -- this will output something
	```
]=]
function Console.Interface.setGlobalLogLevel(logLevel: number): ()
	Console.LogLevel = logLevel
end

--[=[
	@function setGlobalSchema
	@within Console

	@param schema string

	Set the global schema for all Consoles, a schema is how the log is displayed in the console.

	```lua
		Console.setGlobalSchema("[%s][%s]: %s")

		Console:log("Hello, World!") -- > [<ReporterName>][log]: Hello, World!
	```
]=]
function Console.Interface.setGlobalSchema(schema: string): ()
	Console.Schema = schema
end

--[=[
	@function get
	@within Console

	@param logId string

	@return Console?

	Fetch a `Console` object through it's given `logId`

	```lua
		Console.get("Console"):log("Hello, World!") -- > [Console][log]: "Hello, World!"
	```
]=]
function Console.Interface.get(logId: string): Console?
	return Console.Instances[logId]
end

--[=[
	@function new
	@within Console

	@param logId string?
	@param schema string?

	@return Console

	Constructor to generate a `Console` prototype

	```lua
		Console.new("Example"):log("Hello, World!") -- > [Example][log]: "Hello, World!"
	```
]=]
function Console.Interface.new(logId: string?, schema: string?): Console
	local self = setmetatable({
		id = logId,
		level = Console.Interface.LogLevel.Debug,
		schema = schema,
		enabled = true,
		logs = {},
	}, {
		__index = Console.Prototype,
		__type = Console.Type,
		__tostring = function(obj)
			return obj:ToString()
		end,
	})

	if logId then
		Console.Instances[self.id] = self
	end

	return self
end

--[=[
	@function newOrphaned
	@within Console

	@since 2.0.3

	@param logId string?
	@param schema string?

	@return Console

	Constructor to generate an orphaned `Console` prototype, orphaned in this case meaning a console object that the Console library will
		not track or monitor, thus any global console updates will not be applied to this console object.

	This should be used when using `Console` in a library so that any game `Consoles` are isolated from the libraries `Consoles`

	```lua
		Console.newOrphaned("Example"):log("Hello, World!") -- > [Example][log]: "Hello, World!"
	```
]=]
function Console.Interface.newOrphaned(logId: string?, schema: string?): Console
	local self = setmetatable({
		id = logId,
		level = Console.Interface.LogLevel.Debug,
		schema = schema,
		enabled = true,
		logs = {},
	}, {
		__index = Console.Prototype,
		__type = Console.Type,
		__tostring = function(obj)
			return obj:ToString()
		end,
	})

	if logId then
		Console.Instances[self.id] = self
	end

	return self
end

--[=[
	@function is
	@within Console

	@param object Console?

	@return boolean

	Validate if an object is a 'Console' object

	```lua
		local object = Console.new("Test")

		if Console.is(object) then
			...
		end
	```
]=]
function Console.Interface.is(object: Console?): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Console.Type
end

export type Console = typeof(Console.Prototype) & {
	id: string,
	level: number,
	schema: string,
	enabled: boolean,
	logs: {},
}

return Console.Interface
