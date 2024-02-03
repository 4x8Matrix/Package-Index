--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")
local fs = require("@lune/fs")

local function execute(application, arguments, spawnOptions)
	local result = process.spawn(application, arguments, spawnOptions)

	if not result.ok then
		print(`Executing application '{application}' failed: '{result.stderr}'`)

		return process.exit(result.code)
	end

	return result.stdout
end

local function main()
	if not fs.isDir("Binaries") then
		fs.writeDir("Binaries")
	end

	for _, moduleName in fs.readDir("Modules") do
		print(`Building binary for: '{moduleName}'`)

		execute("wally", { "install" }, { cwd = `Modules/{moduleName}` })
		execute("rojo", { "build", "-o", `../../Binaries/{moduleName}.rbxm` }, { cwd = `Modules/{moduleName}` })
	end
end

return main()
