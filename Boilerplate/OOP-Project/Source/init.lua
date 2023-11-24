--[[
	@class Project

	Summary
]]
local Project = {}

Project.Type = "Project"

Project.Interface = {}
Project.Prototype = {}

function Project.Interface.new(): Project
	local self = setmetatable({ }, {
		__index = Project.Prototype,
		__type = Project.Type
	})

	return self
end

export type Project = typeof(Project.Prototype)

return Project.Interface