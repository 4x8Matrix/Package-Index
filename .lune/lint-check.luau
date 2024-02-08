--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")
local fileSystem = require("@lune/fs")

local function main()
	for _, packageName in fileSystem.readDir("Modules") do
		local result = process.spawn(`selene`, {
			`.`,
		}, {
			cwd = `{process.cwd}Modules/{packageName}`,
		})

		if result.ok then
			print(`[Lint-Projects]: project '{packageName}' selene lint OK`)
		else
			print(
				`[Lint-Projects]: project '{packageName}' selene lint FAIL ({result.code}):\n{result.stderr}\n{result.stdout}`
			)

			process.exit(result.code)
		end
	end
end

return main()
