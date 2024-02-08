local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EXECUTE_PROJECT_TESTEZ_TESTS = true

if EXECUTE_PROJECT_TESTEZ_TESTS then
	local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
	local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

	local Reporter = EmoticonReporter.new()

	print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

	TestEz.TestBootstrap:run({
		ReplicatedStorage.Packages.State
	}, Reporter)

	Reporter:Print()
end