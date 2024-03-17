--[=[
	@class RGBA 

	RGBA is a Roblox/Luau library for encoding/decoding various image file formats, allowing developers to encode/decode roblox's
		flat RGBA array into standard file formats.

	To note; I'm throwing the world 'RGBA' around a bit, by this, I mean the object Roblox returns when calling `EditableImage:ReadPixels`
		https://create.roblox.com/docs/reference/engine/classes/EditableImage#ReadPixels
]=]

local RGBA = {}

RGBA.Interface = {}

--[=[
	@prop PNG [PNG](/Packages/RGBA/PNGObject)
	@within RGBA
]=]
RGBA.Interface.PNG = require(script.PNG)

return RGBA.Interface
