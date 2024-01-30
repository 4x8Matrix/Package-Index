local net = require("@lune/net")
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function fetchLatestStudioVersion()
	local response = net.request({
		url = "https://s3.amazonaws.com/setup.roblox.com/versionQTStudio",
		method = "GET",
	})

	if not response.ok then
		print(`Failed to get latest studio version`)

		return process.exit(1)
	end

	return response.body
end

local function fetchLatestStudioDump(version: string)
	local response = net.request({
		url = `https://s3.amazonaws.com/setup.roblox.com/{version}-API-Dump.json`,
		method = "GET",
	})

	if not response.ok then
		print(`Failed to get latest studio api dump`)

		return process.exit(1)
	end

	local jsonData = net.jsonDecode(response.body)
	local updatedClasses = {}

	jsonData.Enums = nil

	for index, value in jsonData.Classes do
		updatedClasses[value.Name] = value
	end

	jsonData.Classes = updatedClasses

	jsonData = serde.encode("json", jsonData, true)

	return jsonData
end

local function main()
	local version = fetchLatestStudioVersion()
	local apiDump = fetchLatestStudioDump(version)

	fs.writeFile(`Source/generated-api-dump.json`, apiDump)
end

main()
