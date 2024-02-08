--[=[
	@class Camera Object

	The base camera object that the end developer will be interacting with, think of this object as an extendable class that you'll overwrite lifecycle methods on.
]=]

--[=[
	@prop Name string
	@within Camera Object
]=]

--[=[
	@prop Instance Instance
	@within Camera Object
]=]

local Camera = {}

Camera.Type = "Camera"

Camera.Internal = {}
Camera.Instances = {}
Camera.Interface = {}
Camera.Prototype = {}

--[=[
	@method OnActivated
	@within Camera Object

	Lifecycle method that'll invoke once the camera has been activated

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnActivated()
			renderStepPrep()
		end
	```
]=]
function Camera.Prototype:OnActivated() end

--[=[
	@method OnDeactivated
	@within Camera Object

	Lifecycle method that'll invoke once the camera has been deactivated

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnDeactivated()
			cleanUpCamera()
		end
	```
]=]
function Camera.Prototype:OnDeactivated() end

--[=[
	@method OnRenderStepped
	@within Camera Object

	Render Stepped lifecycle method that'll be called each render stepped when the camera is active

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:OnRenderStepped()
			self.Instance.CFrame = CFrame.new(1, 0, 1)
		end
	```
]=]
function Camera.Prototype:OnRenderStepped() end

--[=[
	@method InvokeLifecycleMethod
	@within Camera Object

	@return ...

	Attempt to execute a camera object's lifecycle method

	```lua
		local cameraObject = CameraProfile.Camera.new("DefaultCamera")

		function cameraObject:methodName(a, b, c)
			print(a, b, c) -- 1, 2, 3
		end

		cameraObject:InvokeLifecycleMethod("methodName", 1, 2, 3)
	```
]=]
function Camera.Prototype:InvokeLifecycleMethod(lifecycleMethod: string, ...)
	if not self[lifecycleMethod] then
		return
	end

	return self[lifecycleMethod](self, ...)
end

--[=[
	@method ToString
	@within Camera Object

	@return string

	Get a string'd version of the current Camera instance

	```lua
		CameraProfile.Camera.new("DefaultCamera"):ToString() -- > "Camera<"DefaultCamera">"
	```
]=]
function Camera.Prototype:ToString(): string
	return `{Camera.Type}<"{self.Name}">`
end

--[=[
	@function wrap
	@within Camera Object

	@param name string
	@param cameraInstance Instance
	
	@return Camera Object

	Wrap around a Camera instance, the goal being to allow developers to wrap around already instantiated camera objects.

	```lua
		-- wrap around the current workspace camera!

		CameraProfile.Camera.wrap("DefaultCamera", workspace.CurrentCamera)
	```
]=]
function Camera.Interface.wrap(name: string, cameraInstance: Camera): CameraObject
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

--[=[
	@function new
	@within Camera Object

	@param name string

	@return Camera Object

	Generate a new camera instance

	```lua
		CameraProfile.Camera.new("CustomCamera")
	```
]=]
function Camera.Interface.new(name: string): CameraObject
	return Camera.Interface.wrap(name, Instance.new("Camera"))
end

--[=[
	@function is
	@within Camera Object

	@param object any

	@return boolean

	Validate if an object is a camera object

	```lua
		CameraProfile.Camera.is(
			CameraProfile.Camera.new("CustomCamera")
		) -- > true

		CameraProfile.Camera.is(
			123
		) -- > false
	```
]=]
function Camera.Interface.is(object: any): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Camera.Type
end

--[=[
	@function get
	@within Camera Object

	@param name string

	@return Camera Object?

	Get a camera object from it's camera name

	```lua
		CameraProfile.Camera.get("DefaultCamera")
	```
]=]
function Camera.Interface.get(name: string): CameraObject?
	return Camera.Instances[name]
end

export type CameraObject = typeof(Camera.Prototype) & {
	Name: string,
	Instance: Camera,
}

return Camera.Interface
