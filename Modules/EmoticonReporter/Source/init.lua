--[[
	EmoticonReporter - An overhauled roblox 'TestEz Reporter'

	Updated Status Symbols:
		[🟣]: Unknown Test Status
		[🟢]: Successful Test Status
		[🔴]: Failed Test Status
		[🟡]: Skipped Test Status
]]--

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
	[TEST_STATUS_UNKNOWN] = "🟣"
})

local TEST_STATUS_PRIORITY = table.freeze({
	[TEST_STATUS_SUCCESS] = 1,
	[TEST_STATUS_FAILURE] = 2,
	[TEST_STATUS_SKIPPED] = 3,
	[TEST_STATUS_UNKNOWN] = 4
})

local EmoticonReporter = {}

EmoticonReporter.Interface = {}
EmoticonReporter.Prototype = {}

function EmoticonReporter.Prototype:ToString()
	return `EmoticonReporter<Status: '{self._status}'>`
end

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

function EmoticonReporter.Prototype:StripErrors(errorArray)
	for index, stacktrace in errorArray do
		errorArray[index] = self:StripErrorMessage(stacktrace)
	end

	return errorArray
end

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

function EmoticonReporter.Prototype:SerialiseHeadNode(nodeObject)
	local source = { }

	for _, nodeChild in self:SortDescendants(nodeObject.children) do
		local resource = self:SerialiseNode(nodeChild)

		if not resource then
			continue
		end

		table.insert(source, resource)
	end

	return source
end

function EmoticonReporter.Prototype:ParseReport(headNode)
	self._successCount = headNode.successCount
	self._skippedCount = headNode.skippedCount
	self._failureCount = headNode.failureCount

	self._timestamp = os.date("%H.%M:%S.000")

	self._errors = self:StripErrors(headNode.errors)
	self._source = self:SerialiseHeadNode(headNode)

	self._status = PROTOTYPE_STATUS_DONE
end

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

function EmoticonReporter.Prototype:SetErrorsTruncated(state)
	self._truncateErrors = state
end

function EmoticonReporter.Prototype:SetMaxScope(value)
	self._maxScope = value
end

function EmoticonReporter.Prototype:SetIsSorted(state)
	self._sorted = state
end

function EmoticonReporter.Interface.new()
	local self = setmetatable({
		_status = PROTOTYPE_STATUS_IDLE,
		_isFirstNode = true,
		_truncateErrors = true,
		_scope = -1,
		_maxScope = 999,
		_sorted = true
	}, {
		__index = EmoticonReporter.Prototype,
		__tostring = function(object)
			return object:ToString()
		end
	})

	self.report = function(...)
		self:ParseReport(...)
	end

	return self
end

return EmoticonReporter.Interface
