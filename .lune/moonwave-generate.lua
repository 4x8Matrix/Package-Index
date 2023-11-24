local process = require("@lune/process")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local task = require("@lune/task")
local net = require("@lune/net")

local typedMap = {
	["boolean"] = "h"
}

local result = process.spawn("moonwave", {
	"extract", "-b", "Modules"
})

if not result.ok then
	error(result.stderr)
end

local jsonData = serde.decode("json", result.stdout)

if fs.isDir("pages/Packages") then
	fs.removeDir("pages/Packages")
end

fs.writeDir("pages/Packages")

local function typeify(luaType)
	if luaType == "boolean" then
		return `[boolean](https://create.roblox.com/docs/en-us/luau/booleans)`
	end

	return luaType
end

local meta = { }

for _, package in jsonData do
	local mdxContent = ""

	local methods = { }
	local functions = { }

	for _, object in package.functions do
		if object.function_type == "method" then
			table.insert(methods, object)
		else
			table.insert(functions, object)
		end
	end

	mdxContent ..= "import { Callout } from 'nextra/components'\n\n"

	mdxContent ..= `# {package.name}\n`
	mdxContent ..= `{package.desc}\n`

	mdxContent ..= `\n---\n`
	mdxContent ..= `## Properties\n`

	mdxContent ..= `\n---\n`
	mdxContent ..= `## Methods\n`

	for _, object in methods do
		mdxContent ..= `#### {object.name}\n`
		mdxContent ..= `{object.desc}\n`

		if #object.params > 0 then
			mdxContent ..= `##### Parameters\n`

			for _, param in object.params do
				mdxContent ..= `- *{param.name}*: {typeify(param.lua_type)}\n`

				if param.desc ~= "" then
					mdxContent ..= `	- {param.desc}\n`
				end
			end
		end

		if #object.returns > 0 then
			mdxContent ..= `##### Return\n`

			for _, returned in object.returns do
				mdxContent ..= `- {typeify(returned.lua_type)}\n`
			end
		end
	end

	mdxContent ..= `\n---\n`
	mdxContent ..= `## Functions\n`

	meta[net.urlEncode(package.name)] = package.name

	fs.writeFile(`pages/Packages/{net.urlEncode(package.name)}.mdx`, mdxContent)
end

fs.writeFile(`pages/Packages/_meta.json`, serde.encode("json", meta))