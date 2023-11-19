-- // Module
local Camera = {}

Camera.Type = "Camera"

Camera.Internal = {}
Camera.Instances = {}
Camera.Interface = {}
Camera.Prototype = {}

-- // Prototype lifecycles
--[[
	Lifecycle method that'll invoke once the camera has been activated

	---
	Example:

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnActivated()
			renderStepPrep()
		end
	```
]]
function Camera.Prototype:OnActivated() end

--[[
	Lifecycle method that'll invoke once the camera has been deactivated

	---
	Example:

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnRenderStepped()
			cleanUpCamera()
		end
	```
]]
function Camera.Prototype:OnDeactivated() end

--[[
	Render Stepped lifecycle method that'll be called each render stepped when the camera is active

	---
	Example:

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnRenderStepped()
			self.Instance.CFrame = CFrame.new(1, 0, 1)
		end
	```
]]
function Camera.Prototype:OnRenderStepped() end

-- // Prototype functions
--[[
	Attempt to execute a camera object's lifecycle method

	---
	Example:

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:methodName(a, b, c)
			print(a, b, c) -- 1, 2, 3
		end

		cameraObject:InvokeLifecycleMethod("methodName", 1, 2, 3)
	```
]]
function Camera.Prototype:InvokeLifecycleMethod(lifecycleMethod, ...)
	if not self[lifecycleMethod] then
		return
	end

	return self[lifecycleMethod](self, ...)
end

--[[
	Get a string'd version of the current Camera instance

	---
	Example:

	```lua
		CameraProfile.Camera.new("DefaultCamera"):ToString() -- > "Camera<"DefaultCamera">"
	```
]]
function Camera.Prototype:ToString()
	return `{Camera.Type}<"{self.Name}">`
end

-- // Module functions
--[[
	Wrap around a Camera instance, the goal being to allow developers to wrap around already instantiated camera objects.

	### Parameters
	- **name**: *the name of the Camera object*
	- **cameraInstance**: *the camera object you're wrapping*

	---
	Example:

	```lua
		-- wrap around the current workspace camera!

		CameraProfile.Camera.wrap("DefaultCamera", workspace.CurrentCamera)
	```
]]
function Camera.Interface.wrap(name, cameraInstance)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	assert(
		type(cameraInstance) == "userdata",
		`Expected parameter #2 'cameraInstance' to be a userdata, got {type(cameraInstance)}`
	)
	assert(
		cameraInstance:IsA("Camera"),
		`Expected parameter #2 'cameraInstance' to be a camera instance, got {cameraInstance.ClassName}`
	)

	local self = setmetatable({
		Name = name,
		Instance = cameraInstance,
	}, {
		__index = Camera.Prototype,
		__type = Camera.Type,

		__tostring = function(object)
			return object:ToString()
		end,
	})

	self.Instance.Name = `Camera<"{self.Name}">`

	if workspace.CurrentCamera == self.Instance then
		self:InvokeLifecycleMethod("OnActivated", self.Instance)
	end

	assert(not Camera.Instances[name], `Expected {name} to be unique, are you sure this isn't a duplicate Camera?`)

	Camera.Instances[name] = self
	return Camera.Instances[name]
end

--[[
	Generate a new camera instance

	### Parameters
	- **name**: *the name of the Camera object*

	---
	Example:

	```lua
		CameraProfile.Camera.new("CustomCamera")
	```
]]
function Camera.Interface.new(name)
	return Camera.Interface.wrap(name, Instance.new("Camera"))
end

--[[
	Validate if an object is a camera object

	### Parameters
	- **object**: *the camera instance, or what could be a camera instance*

	---
	Example:

	```lua
		CameraProfile.Camera.is(
			CameraProfile.Camera.new("CustomCamera")
		) -- > true

		CameraProfile.Camera.is(
			123
		) -- > false
	```
]]
function Camera.Interface.is(object)
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Camera.Type
end

--[[
	Get a camera object from it's camera name

	### Parameters
	- **name**: *the name of the camera you're trying to retrieve*

	---
	Example:

	```lua
		CameraProfile.Camera.get("DefaultCamera")
	```
]]
function Camera.Interface.get(name)
	return Camera.Instances[name]
end

return Camera.Interface