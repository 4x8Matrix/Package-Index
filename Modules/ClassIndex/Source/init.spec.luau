return function()
	local ClassIndex = require(script.Parent)

	it("Should be able to access the raw API dump", function()
		local apiDump = ClassIndex.FetchApiDump()

		expect(apiDump).never.to.equal(nil)
		expect(apiDump.Classes).never.to.equal(nil)
		expect(apiDump.Version).never.to.equal(nil)
	end)

	it("Should be able to fetch all classes from the raw API dump", function()
		local classArray = ClassIndex.FetchAllClasses()

		expect(#classArray).never.to.equal(0)
		expect(table.find(classArray, "Workspace")).never.to.equal(nil)
	end)

	it("Should be able to query class names", function()
		expect(ClassIndex.IsClassRegistered("Workspace")).to.equal(true)
		expect(ClassIndex.IsClassRegistered("FakeWorkspace")).to.equal(false)
	end)

	it("Should be able to query class members", function()
		local classMembers = ClassIndex.FetchClassMembers("Workspace")

		expect(#classMembers).never.to.equal(0)

		for _, propertyName in classMembers do
			expect(workspace[propertyName]).never.to.equal(nil)
		end
	end)

	it("Should be able to fetch the member type from a class", function()
		local gravityMemberType = ClassIndex.FetchClassMemberType("Workspace", "Gravity")

		expect(gravityMemberType).to.equal("Property")
	end)

	it("Should be able to fetch the tags for a member of a class", function()
		local streamingMinRadiusTags = ClassIndex.FetchClassMemberTags("Workspace", "StreamingMinRadius")

		expect(streamingMinRadiusTags.NotScriptable).to.equal(true)
	end)

	it("Should be able to fetch the security for a member of a class", function()
		local streamingEnabledSecurity = ClassIndex.FetchClassMemberSecurity("Workspace", "StreamingEnabled")

		expect(streamingEnabledSecurity.Read).to.equal("None")
		expect(streamingEnabledSecurity.Write).to.equal("PluginSecurity")
	end)

	it("Should be able to fetch the thread safety for a member of a class", function()
		local streamingEnabledThreadSafety = ClassIndex.FetchClassMemberThreadSafety("Workspace", "StreamingEnabled")

		expect(streamingEnabledThreadSafety).to.equal("ReadSafe")
	end)

	it("Should be able to query class superclass", function()
		local workspaceSuperClass = ClassIndex.FetchClassSuperclass("Workspace")

		expect(workspaceSuperClass).to.equal("WorldRoot")
	end)

	it("Should be able to query class superclasses", function()
		local workspaceSuperClasses = ClassIndex.FetchClassSuperclasses("Workspace")

		expect(#workspaceSuperClasses).never.to.equal(0)

		expect(workspaceSuperClasses[#workspaceSuperClasses]).to.equal("<<<ROOT>>>")
		expect(workspaceSuperClasses[1]).to.equal("WorldRoot")
	end)
end
