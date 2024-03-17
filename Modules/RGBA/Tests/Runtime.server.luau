local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

local RGBA = require(ReplicatedStorage.Packages.RGBA:Clone())

local IMAGE_SIZE = 1024 -- 512

CaptureService:CaptureScreenshot(function(id)
	local EditableImage = AssetService:CreateEditableImageAsync(id)
	local FlatRGBAArray = EditableImage:ReadPixels(Vector2.zero, Vector2.new(IMAGE_SIZE, IMAGE_SIZE))

	local PNG = RGBA.PNG.new(
		Vector2.new(IMAGE_SIZE, IMAGE_SIZE),
		FlatRGBAArray
	)
	
	game:GetService("HttpService"):RequestAsync({
		Url = "http://localhost:1227",
		Method = "POST",
		Body = PNG:ToString() -- table.concat(png.output, "")
	})
end)
