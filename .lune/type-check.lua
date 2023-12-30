--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")

-- currently this CI step is disabled, i've found multiple issues trying to enforce type checking in CI.
local TYPE_CHECK_ENABLED = false

local function execute(application, ...)
	local result = process.spawn(application, { ... })

	if not result.ok then
		print(`Executing application '{application}' failed: '{result.stderr}'`)

		return process.exit(result.code)
	end

	return result.stdout
end

local function downloadRobloxTypes()
	local response = net.request({
		url = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua",
		method = "GET",
	})

	if not response.ok then
		print(`Failed to publish to Roblox: {response.statusCode} - '{response.statusMessage}'`)

		return process.exit(1)
	end

	fs.writeFile("roblox.d.lua", response.body)

	return
end

local function main()
	if not fs.isFile("roblox.d.lua") then
		downloadRobloxTypes()
	end

	execute("rojo", "sourcemap", "default.project.json", "-o", "sourcemap.json")
	execute("luaulsp", "analyze", "--defs=roblox.d.lua", "--sourcemap=sourcemap.json", "Places")
end

if TYPE_CHECK_ENABLED then
	return main()
end
