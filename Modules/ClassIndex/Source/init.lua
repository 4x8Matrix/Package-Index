local apiDump = require(script["generated-api-dump"])

--[=[
	@class ClassIndex

	A package that enables developers to get context about specific Roblox classes, this package uses a late-ish dump of the Roblox API
		to be able to query information such as the superclasses for a specific class, properties for specific classes and so fourth.

	This package uses the [lune](https://lune-org.github.io/docs) runtime to update the 'generated-api-dump'
]=]
local ClassIndex = {}

ClassIndex.Public = {}
ClassIndex.Private = {}

--[=[
	@method FetchApiDump
	@within ClassIndex

	@return RawApiDump

	Returns the Roblox API dump the current package is using. The returned object is typed.

	```lua
		local APIDump = ClassIndex.FetchApiDump()

		print(APIDump.Classes["Workspace"].Members)
	```
]=]
function ClassIndex.Public.FetchApiDump(): apiDump
	return apiDump
end

--[=[
	@method FetchAllClassNames
	@within ClassIndex

	@return { string }

	Returns an array of all classes in the Roblox Engine

	```lua
		local classNames = ClassIndex.FetchAllClassNames()

		for _, className in classNames do
			print(className)
		end
	```
]=]
function ClassIndex.Public.FetchAllClassNames(): { string }
	local classNames = {}

	for _, classStruct in apiDump.Classes do
		table.insert(classNames, classStruct.Name)
	end

	return classNames
end

--[=[
	@method FetchPropertiesOfClass
	@within ClassIndex

	@param class string

	@return { [string]: { string } }

	Returns a dictionary, containing all properties of the supplied class and all of the supplied class super classes.

	```lua
		local properties = ClassIndex.FetchPropertiesOfClass("Workspace")

		--[[
			properties = {
				["Instance"] = {
					[1] = "Archivable",
					[2] = "ClassName",
					[3] = "Name",
					[4] = "Parent",
					[5] = "RobloxLocked",
					[6] = "SourceAssetId"
				},
				["Model"] = {...},
				["PVInstance"] = {},
				["Workspace"] = {...},
				["WorldRoot"] = {}
			}
		]]

		local workspaceProperties = properties.Workspace
		local instanceProperties = properties.Instance
		local modelProperties = properties.Model
	```
]=]
function ClassIndex.Public.FetchPropertiesOfClass(className: string)
	local class = apiDump.Classes[className]
	local classProperties = {
		[className] = {},
	}

	for _, memberStruct in class.Members do
		if
			memberStruct.MemberType == "Property"
			and (memberStruct.Category == "Behavior" or memberStruct.Category == "Data")
		then
			if memberStruct.Tags and table.find(memberStruct.Tags, "Deprecated") then
				continue
			end

			table.insert(classProperties[className], memberStruct.Name)
		end
	end

	local superclasses = ClassIndex.Public.FetchClassSuperClasses(className)

	if #superclasses ~= 0 then
		for _, superclass in superclasses do
			local superclassProperties = ClassIndex.Public.FetchPropertiesOfClass(superclass)

			for superclassName, superclassValue in superclassProperties do
				classProperties[superclassName] = superclassValue
			end
		end
	end

	return classProperties
end

--[=[
	@method FetchClassSuperClasses
	@within ClassIndex

	@param class string

	@return { string }

	Returns an array of all superclasses of the passed in class

	```lua
		local superclasses = ClassIndex.FetchPropertiesOfClass("Workspace")

		--[[
			superclasses = {
				[1] = "WorldRoot",
				[2] = "Model",
				[3] = "PVInstance",
				[4] = "Instance"
			}
		]]
	```
]=]
function ClassIndex.Public.FetchClassSuperClasses(className: string)
	local class = apiDump.Classes[className]
	local superclasses = {}

	local currentClass = class

	while true do
		if currentClass.Superclass == "<<<ROOT>>>" then
			return superclasses
		else
			currentClass = apiDump.Classes[currentClass.Superclass]

			table.insert(superclasses, currentClass.Name)
		end
	end
end

export type apiDump = {
	Classes: {
		[string]: {
			MemoryCategory: string,
			Superclass: string,
			Name: string,

			Members: {
				{
					Category: string,
					MemberType: string,
					ThreadSafety: string,
					Name: string,
					Security: {
						Read: string?,
						Write: string?,
					},
					Serialization: {
						CanLoad: boolean?,
						CanSave: boolean?,
					},
					ValueType: {
						Category: string,
						Name: string,
					},
				}?
			},
		},
	},
}

return ClassIndex.Public
