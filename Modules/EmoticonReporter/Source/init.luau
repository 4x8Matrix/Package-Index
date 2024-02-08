local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

local TEST_STATUS_SUCCESS = TestEz.TestEnum.TestStatus.Success
local TEST_STATUS_FAILURE = TestEz.TestEnum.TestStatus.Failure
local TEST_STATUS_SKIPPED = TestEz.TestEnum.TestStatus.Skipped
local TEST_STATUS_UNKNOWN = newproxy(false)

local PROTOTYPE_STATUS_IDLE = "idle"
local PROTOTYPE_STATUS_DONE = "finished"

local INDENTATION = "    "

local TEST_STATUS_EMOTES = table.freeze({
	[TEST_STATUS_SUCCESS] = "🟢",
	[TEST_STATUS_FAILURE] = "🔴",
	[TEST_STATUS_SKIPPED] = "🟡",
	[TEST_STATUS_UNKNOWN] = "🟣",
})

local TEST_STATUS_PRIORITY = table.freeze({
	[TEST_STATUS_SUCCESS] = 1,
	[TEST_STATUS_FAILURE] = 2,
	[TEST_STATUS_SKIPPED] = 3,
	[TEST_STATUS_UNKNOWN] = 4,
})

--[=[
	@class Emoticon Reporter

	A simple alternative to the default Roblox `TestEz` reporter, this Reporter attempts to bundle in a few quality of life things to help make testing your code easier.

	Emoji definitions:
	- 🟣 - *Unknown Test Status*
	- 🟢 - *Successful Test Status*
	- 🔴 - *Failed Test Status*
	- 🟡 - *Skipped Test Status*
]=]
local EmoticonReporter = {}

EmoticonReporter.Interface = {}
EmoticonReporter.Prototype = {}

--[=[
	@method ToString
	@within Emoticon Reporter

	@return string

	Returns a prettified string version of the state table.

	```lua
		local Reporter = EmoticonReporter.new()

		print(tostring(Reporter)) -- EmoticonReporter<Status: idle>
	```
]=]
function EmoticonReporter.Prototype:ToString()
	return `EmoticonReporter<Status: '{self._status}'>`
end

--[=[
	@method StripErrorMessage
	@within Emoticon Reporter

	@param stacktrace string

	@return string

	Strips away common `testez` lines that can often obscure the stack trace
]=]
function EmoticonReporter.Prototype:StripErrorMessage(stacktrace)
	if not self._truncateErrors then
		return stacktrace
	end

	local messageSplitArray = string.split(stacktrace, "\n")
	local testEzMessageFlag = false
	local newMessageObject = {}

	for _, line in messageSplitArray do
		if not string.find(line, ".testez.") then
			if testEzMessageFlag then
				testEzMessageFlag = false
			end

			table.insert(newMessageObject, line)

			continue
		end

		local testEzModule = string.match(line, ".(%a+):(%d+)")

		if testEzMessageFlag == testEzModule then
			continue
		end

		testEzMessageFlag = testEzModule

		table.insert(newMessageObject, `*.TestEz.{testEzModule}: truncated`)
	end

	return table.concat(newMessageObject, "\n")
end

--[=[
	@method StripErrors
	@within Emoticon Reporter

	@param errorArray { string }

	@return { string }

	QoL call that loops through an array and calls `:StripErrorMessage`
]=]
function EmoticonReporter.Prototype:StripErrors(errorArray)
	for index, stacktrace in errorArray do
		errorArray[index] = self:StripErrorMessage(stacktrace)
	end

	return errorArray
end

--[=[
	@method SerialiseNode
	@within Emoticon Reporter

	@param testEzNode { ... }

	@return string

	Primary method used to parse and compute testez result nodes, this function is recursive and will parse children of the passed in testez node.
]=]
function EmoticonReporter.Prototype:SerialiseNode(nodeObject)
	local serialisedNode = ""

	self._scope += 1

	serialisedNode ..= `  {self._timestamp}  `
	serialisedNode ..= `{string.rep(INDENTATION, self._scope)}`

	if self._scope >= self._maxScope then
		self._scope -= 1

		serialisedNode ..= `[⚠️]: Maximum node depth reached!`

		return serialisedNode
	end

	serialisedNode ..= `[{TEST_STATUS_EMOTES[nodeObject.status] or TEST_STATUS_EMOTES[TEST_STATUS_UNKNOWN]}]:`
	serialisedNode ..= ` "{nodeObject.planNode.phrase}"`

	for _, nodeChild in nodeObject.children do
		local resource = self:SerialiseNode(nodeChild)

		if not resource then
			continue
		end

		serialisedNode ..= `\n{resource}`
	end

	self._scope -= 1

	return serialisedNode
end

--[=[
	@method SortDescendants
	@within Emoticon Reporter

	@param children { testEzNode }

	@return { testEzNode }

	Sorts the TestEz nodes so that we show any failed tests first instead of having to scroll to find what tests failed.
]=]
function EmoticonReporter.Prototype:SortDescendants(children)
	if not self._sorted or (self._skippedCount == 0 and self._failureCount == 0) then
		return children
	end

	table.sort(children, function(node0, node1)
		return TEST_STATUS_PRIORITY[node0.status] < TEST_STATUS_PRIORITY[node1.status]
	end)

	for _, nodeObject in children do
		nodeObject.children = self:SortDescendants(nodeObject.children)
	end

	return children
end

--[=[
	@method SerialiseHeadNode
	@within Emoticon Reporter

	@param testEzNode { ... }

	@return string

	Primary method used to parse the testez head node, this function will then call `:SerialiseNode` to parse child nodes.
]=]
function EmoticonReporter.Prototype:SerialiseHeadNode(nodeObject)
	local source = {}

	for _, nodeChild in self:SortDescendants(nodeObject.children) do
		local resource = self:SerialiseNode(nodeChild)

		if not resource then
			continue
		end

		table.insert(source, resource)
	end

	return source
end

--[=[
	@method ParseReport
	@within Emoticon Reporter

	@param testEzNode { ... }

	Called by the TestEz library, used to parse test results.
]=]
function EmoticonReporter.Prototype:ParseReport(headNode)
	self._successCount = headNode.successCount
	self._skippedCount = headNode.skippedCount
	self._failureCount = headNode.failureCount

	self._timestamp = os.date("%H.%M:%S.000")

	self._errors = self:StripErrors(headNode.errors)
	self._source = self:SerialiseHeadNode(headNode)

	self._status = PROTOTYPE_STATUS_DONE
end

--[=[
	@method Print
	@within Emoticon Reporter

	Display the results of a test in the output, the Reporter won't display these results when TestEz reports the finished test, instead the developer will need to call this method to see the status of the test.
]=]
function EmoticonReporter.Prototype:Print()
	if #self._source == 0 then
		print("TestEz Results: Unable to locate any '*.spec.lua' modules!")

		return
	end

	print(`TestEz Results:\n{table.concat(self._source, `\n\n`)}\n`)

	for _, message in self._errors do
		local messageSplit = string.split(message, "\n")

		local errorMessage = table.remove(messageSplit, 1)
		local stackMessage = ""

		table.insert(messageSplit, 1, "Stack Begin")
		table.insert(messageSplit, "Stack End")

		for index, value in messageSplit do
			if value == "\n" or value == "" then
				continue
			end

			if index ~= 1 then
				stackMessage ..= `\n  {self._timestamp}  TestService: {value}`
			else
				stackMessage ..= value
			end
		end

		TestService:Error(errorMessage)
		TestService:Message(stackMessage)

		print("")
	end
end

--[=[
	@method SetErrorsTruncated
	@within Emoticon Reporter

	@param state boolean

	Disable/Enable the ability for EmoticonReporter to strip away TestEz error messages
]=]
function EmoticonReporter.Prototype:SetErrorsTruncated(state)
	self._truncateErrors = state
end

--[=[
	@method SetMaxScope
	@within Emoticon Reporter

	@param value number

	Set the max scope for the Reporter to show, anything past the `value` passed in will be marked off as "Maximum node depth reached"
]=]
function EmoticonReporter.Prototype:SetMaxScope(value)
	self._maxScope = value
end

--[=[
	@method SetIsSorted
	@within Emoticon Reporter

	@param value number

	Enable/Disable reporter sorting for the TestEz output.
]=]
function EmoticonReporter.Prototype:SetIsSorted(state)
	self._sorted = state
end

--[=[
	@function new
	@within Emoticon Reporter

	Construct a new `EmoticonReporter` object

	```lua
		local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
		local Reporter = EmoticonReporter.new()

		TestEz.TestBootstrap:run({
			ServerScriptService.Modules,
		}, Reporter)

		Reporter:Print()
	```
]=]
function EmoticonReporter.Interface.new()
	local self = setmetatable({
		_status = PROTOTYPE_STATUS_IDLE,
		_isFirstNode = true,
		_truncateErrors = true,
		_scope = -1,
		_maxScope = 999,
		_sorted = true,
	}, {
		__index = EmoticonReporter.Prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	self.report = function(...)
		self:ParseReport(...)
	end

	return self
end

return EmoticonReporter.Interface
