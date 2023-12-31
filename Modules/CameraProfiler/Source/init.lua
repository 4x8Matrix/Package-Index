local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

--[=[
	@class Camera Profiler

	The Camera Profiler is a singleton responsible for handling what camera is active, what cameras are not active and the primary entrypoint for activating different camera objects.
]=]
local CameraProfiler = {}

--[=[
	@prop Camera [CameraObject](/Packages/CameraProfiler/Camera)
	@within Camera Profiler
]=]

--[=[
	@prop CameraActivated RBXScriptSignal
	@within Camera Profiler
]=]

--[=[
	@prop CameraDeactivated RBXScriptSignal
	@within Camera Profiler
]=]

CameraProfiler.Interface = {}
CameraProfiler.Active = nil

CameraProfiler.Interface.Camera = require(script.Camera)

CameraProfiler.Interface.CameraActivated = Signal.new()
CameraProfiler.Interface.CameraDeactivated = Signal.new()

--[=[
	@method GetActiveCamera
	@within Camera Profiler

	@return string

	Get the active camera instance, this'll return a string that represents a camera object.

	```lua
		local activeCamera = CameraProfile:GetActiveCamera()
	```
]=]
function CameraProfiler.Interface:GetActiveCamera(): string
	return CameraProfiler.Active and CameraProfiler.Active.Name
end

--[=[
	@method SetActiveCamera
	@within Camera Profiler

	@param cameraName string

	@return string

	Set the active camera instance, this'll invoke a few lifecycle methods as well as swap out the current camera for the requested camera if found.

	```lua
		CameraProfile:SetActiveCamera("Example")
	```
]=]
function CameraProfiler.Interface:SetActiveCamera(cameraName: string): ()
	local cameraObject = CameraProfiler.Interface.Camera.get(cameraName)
	local cameraReference = workspace.CurrentCamera

	assert(cameraObject, `Failed to call ':GetActiveCamera' for the {cameraName} camera!`)

	if CameraProfiler.Active and CameraProfiler.Active.Name == cameraName then
		return
	end

	if CameraProfiler.Active then
		CameraProfiler.Interface.CameraDeactivated:Fire(CameraProfiler.Active.Name)
		CameraProfiler.Active:InvokeLifecycleMethod("OnDeactivated", cameraReference)
	end

	CameraProfiler.Active = cameraObject
	cameraObject.Instance.Parent = workspace

	-- selene: allow(incorrect_standard_library_use)
	workspace.CurrentCamera = cameraObject.Instance

	cameraReference.Parent = nil

	CameraProfiler.Interface.CameraActivated:Fire(cameraObject.Name)
	cameraObject:InvokeLifecycleMethod("OnActivated", cameraObject.Instance)
end

function CameraProfiler:Init()
	RunService.RenderStepped:Connect(function(deltaTime)
		if not CameraProfiler.Active then
			return
		end

		CameraProfiler.Active:InvokeLifecycleMethod("OnRenderStepped", deltaTime)
	end)

	return CameraProfiler.Interface
end

return CameraProfiler:Init() :: typeof(CameraProfiler.Interface)
