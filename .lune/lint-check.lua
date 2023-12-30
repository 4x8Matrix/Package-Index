--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")

local function execute(application, ...)
	local result = process.spawn(application, { ... })

	if not result.ok then
		print(`Executing application '{application}' failed: '{result.stderr}'`)

		return process.exit(result.code)
	end

	return result.stdout
end

local function main()
	execute("selene", "lint", "Modules")
end

return main()
