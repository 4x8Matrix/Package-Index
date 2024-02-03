local apiDump = require(script["generated-api-dump"])
local spritesheetData = require(script["spritesheet-data"])

--[=[
	@class ClassIndex

	A package that enables developers to get context about specific Roblox classes, this package uses a late-ish dump of the Roblox API
		to be able to query information such as the superclasses for a specific class, properties for specific classes and so fourth.

	This package uses the [lune](https://lune-org.github.io/docs) runtime to update the 'generated-api-dump'
]=]
local ClassIndex = {}

ClassIndex.Public = {}
ClassIndex.Private = {}

ClassIndex.Private.SpritesheetClassMap = {}

--[=[
	@function FetchApiDump
	@within ClassIndex

	@return ApiDump

	Returns the Roblox 'Api Dump' that the package is currently using.

	```lua
		local ApiDump = ClassIndex.FetchApiDump()

		print(ApiDump.Classes["Workspace"].Members)
	```
]=]
function ClassIndex.Public.FetchApiDump(): apiDump
	return apiDump
end

--[=[
	@function FetchAllClasses
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
function ClassIndex.Public.FetchAllClasses(): { string }
	local classNames = {}

	for className in apiDump.Classes do
		table.insert(classNames, className)
	end

	return classNames
end

--[=[
	@function IsClassRegistered
	@within ClassIndex

	@param className string

	@return boolean

	Returns wheather the Api Dump the package is using contains metadata on a class

	```lua
		local isClassSupported = ClassIndex.IsClassRegistered("Workspace")

		if isClassSupported then
			local workspaceMembers = ClassIndex.FetchClassMembers("Workspace")

			...
		end
	```
]=]
function ClassIndex.Public.IsClassRegistered(className: string): boolean
	if not apiDump.Classes[className] then
		return false
	end

	return true
end

--[=[
	@function FetchClassMembers
	@within ClassIndex

	@param className string
	@param security string?
	@param includeNonScriptable boolean?

	@return { string }

	Returns the 'Members' of a class, class members could be one of many things, ranging from;

	- Methods
	- Events
	- Properties

	```lua
		local workspaceMembers = ClassIndex.FetchClassMembers("Workspace")

		local workspaceMethods = {}
		local workspaceEvents = {}
		local workspaceProperties = {}

		for _, memberName in workspaceMembers do
			local indexType = typeof(workspaceMethods[memberName])

			if indexType == "function" then
				table.insert(workspaceMethods, memberName)
			elseif indexType == "RbxScriptSignal" then
				table.insert(workspaceEvents, memberName)
			else
				table.insert(workspaceProperties, memberName)
			end
		end
	```
]=]
function ClassIndex.Public.FetchClassMembers(
	className: string,
	security: string?,
	includeNonScriptable: boolean?
): { string }
	local class = apiDump.Classes[className]
	local classMembers = {}

	if not security then
		security = "None"
	end

	for memberName, memberStruct in class.Members do
		if memberStruct.Tags.NotScriptable and not includeNonScriptable then
			continue
		end

		if type(memberStruct.Security) == "string" then
			if memberStruct.Security ~= security then
				continue
			end
		else
			if memberStruct.Security.Read ~= security then
				continue
			end
		end

		table.insert(classMembers, memberName)
	end

	return classMembers
end

--[=[
	@function FetchClassIcon
	@within ClassIndex

	@param className string

	@return { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 }

	Re-implements the :GetClassIcon call seen under 'StudioService', allowing developers outside of the Plugin space to get class
	icons.

	> https://create.roblox.com/docs/reference/engine/classes/StudioService#GetClassIcon

	*Curse you Roblox! Why is this locked to just plugins?!*

	```lua
		local label = Instance.new("ImageLabel")
		
		for property, value in ClassIndex.FetchClassIcon("Workspace") do
			label[property] = value
		end

		...
	```
]=]
function ClassIndex.Public.FetchClassIcon(
	className: string
): { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 }
	local classImageData = spritesheetData.Content[className]

	if not classImageData then
		classImageData = spritesheetData.Content.File
	end

	--[[
		Note for myself in the future so I don't waste hours on this..

		USE THIS SITE: https://www.codeandweb.com/free-sprite-sheet-packer - thank you!
	]]

	return {
		Image = "http://www.roblox.com/asset/?id=16231724441",
		ImageRectOffset = Vector2.new(classImageData.x, classImageData.y),
		ImageRectSize = Vector2.new(classImageData.w, classImageData.h),
	}
end

--[=[
	@function FetchClassMemberType
	@within ClassIndex

	@param className string
	@param memberName string

	@return string

	Returns the 'MemberType' of a class member.

	```lua
		local gravityMemberType = ClassIndex.FetchClassMemberType("Workspace", "Gravity")

		print(gravityMemberType) -- "Property"
	```
]=]
function ClassIndex.Public.FetchClassMemberType(className: string, memberName: string): memberType
	local class = apiDump.Classes[className]
	local member = class.Members[memberName]

	return member.MemberType
end

--[=[
	@function FetchClassMemberTags
	@within ClassIndex

	@param className string
	@param memberName string

	@return { Hidden: boolean?, NotReplicated: boolean?, ReadOnly: boolean?, Deprecated: boolean? }

	Returns the tags that have been applied to a class member.

	```lua
		local gravityMemberTags = ClassIndex.FetchClassMemberTags("Workspace", "Gravity")

		if gravityMemberTags.Deprecated then
			print("Oh noo! Where did Gravity go?!")
		end
	```
]=]
function ClassIndex.Public.FetchClassMemberTags(className: string, memberName: string): memberTags
	local class = apiDump.Classes[className]
	local member = class.Members[memberName]

	local shallowClone = {}

	for index, value in member.Tags do
		shallowClone[index] = value
	end

	return shallowClone
end

--[=[
	@function FetchClassMemberSecurity
	@within ClassIndex

	@param className string
	@param memberName string

	@return { Read: string, Write: string }

	Returns a table containg both a Read and Write key, the value sof these keys will define if the developer has
		access to write and read the member of that class.

	```lua
		local memberSecurity = ClassIndex.FetchClassMemberSecurity("Workspace", "Gravity")

		if memberSecurity.Read == "None" then
			local gravity = workspace.Gravity
		end
	```
]=]
function ClassIndex.Public.FetchClassMemberSecurity(
	className: string,
	memberName: string
): { Read: memberSecurity, Write: memberSecurity }
	local class = apiDump.Classes[className]
	local member = class.Members[memberName]

	local shallowClone = {}

	if type(member.Security) == "table" then
		for index, value in member.Security do
			shallowClone[index] = value
		end
	else
		shallowClone.Read = member.Security
		shallowClone.Write = member.Security
	end

	return shallowClone
end

--[=[
	@function FetchClassMemberThreadSafety
	@within ClassIndex

	@param className string
	@param memberName string

	@return string

	Returns a string defining if the developer can access/manipulate that member when using roblox's multi threading feature.

	```lua
		local memberThreadSafe = ClassIndex.FetchClassMemberThreadSafety("Workspace", "Gravity")

		if memberSecurity == "Safe" then
			task.desynchronize()

			workspace.Gravity *= 2

			task.synchronize()
		end
	```
]=]
function ClassIndex.Public.FetchClassMemberThreadSafety(className: string, memberName: string): memberThreadSafety
	local class = apiDump.Classes[className]
	local member = class.Members[memberName]

	return member.ThreadSafety
end

--[=[
	@function FetchClassSuperclass
	@within ClassIndex

	@param className string

	@return string

	Returns the superclass of a given class. For etcetera, the Workspace's superclass is 'WorldRoot'!

	```lua
		local workspaceSuperclass = ClassIndex.FetchClassSuperclass("Workspace")

		print(workspaceSuperclass) -- "WorldRoot"
	```
]=]
function ClassIndex.Public.FetchClassSuperclass(className: string)
	local class = apiDump.Classes[className]

	return class.Superclass
end

--[=[
	@function FetchClassSuperclasses
	@within ClassIndex

	@param className string

	@return string

	Returns an array containing the superclass ancestry, the last index in this array will always be `<<<ROOT>>>` since that's the
		base class for everything under the Roblox engine.

	```lua
		local workspaceSuperclasses = ClassIndex.FetchClassSuperclasses("Workspace")

		print(workspaceSuperclasses) -- { "WorldRoot", "Model", "PVInstance", "Instance", "`<<<ROOT>>>`" }
	```
]=]
function ClassIndex.Public.FetchClassSuperclasses(className: string)
	local currentClass = apiDump.Classes[className]
	local classes = {}

	while currentClass do
		table.insert(classes, currentClass.Superclass)

		currentClass = apiDump.Classes[currentClass.Superclass]
	end

	return classes
end

export type apiDump = typeof(apiDump)
export type memberType = "Property" | "Event" | "Function" | "Data"
export type memberSecurity = "RobloxScriptSecurity" | "PluginSecurity" | "None"
export type memberThreadSafety = "Unsafe" | "ReadSafe" | "Safe"
export type memberTags = {
	["Hidden"]: boolean?,
	["NotReplicated"]: boolean?,
	["ReadOnly"]: boolean?,
	["Deprecated"]: boolean?,
}

return ClassIndex.Public
