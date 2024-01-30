-- local EXECUTE_PROJECT_TESTEZ_TESTS = true

-- if EXECUTE_PROJECT_TESTEZ_TESTS then
-- 	return
-- end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassIndex = require(ReplicatedStorage.Packages.ClassIndex)

print(ClassIndex.FetchPropertiesOfClass("Workspace"))
