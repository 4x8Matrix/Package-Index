--[=[
	@class PNGObject 

	The PNG Object enables a developer to write Roblox's flat RGBA array into a PNG file format, allowing developers to export
		the contents of `EditableImage:ReadPixels`, which could come in handy for things such as Plugins.

	Most of the work is done upon creating this class, essentially all you have to do as a dev is call `:ToString` to get the
		binary blob, the image itself.

	TL;DR, this is a PNG encoder.

	<Callout emoji="ℹ️">
		Any PNG file created through this encoder will export an image w/o compression, true color with alpha.
	</Callout>

	---

	I do want to credit the following people for both a resource and reference for this impl;

	- https://github.com/wyozi/lua-pngencoder/tree/master
		- [Joonas](https://github.com/wyozi)
		- [David Vogel](https://github.com/Dadido3)

	- https://www.w3.org/TR/png/
]=]

local DEFLATE_MAX_BLOCK_SIZE = 65535

local PNG = {}

PNG.Interface = {}
PNG.Prototype = {}

PNG.Prototype.Height = -0
PNG.Prototype.Width = -0
PNG.Prototype.LineSize = 0
PNG.Prototype.UncompressedDataRemaining = 0
PNG.Prototype.DeflateBlocksCount = 0
PNG.Prototype.DeflateBlockFilled = -1
PNG.Prototype.IDATSize = 0
PNG.Prototype.Buffer = newproxy() :: buffer
PNG.Prototype.BufferPosition = -1
PNG.Prototype.BufferSize = -1

function PNG.Prototype.Write(self: PNG, ...)
	for _, object in { ... } do
		buffer.writeu8(self.Buffer, self.BufferPosition, object)
		self.BufferPosition += 1
	end
end

function PNG.Prototype.Destroy(self: PNG, ...)
	buffer.fill(self.Buffer, 0, 0)
end

function PNG.Prototype.WriteUInt32(self: PNG, ...)
	for _, object in { ... } do
		for index = 0, 3 do
			self:Write(bit32.band(bit32.rshift(object, (3 - index) * 8), 0xFF))
		end
	end
end

function PNG.Prototype.WriteIEND(self: PNG)
	self:WriteUInt32(self.Adler)
	self:WriteUInt32(self:UpdateCRC32(4))

	self:Write(0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82)
end

function PNG.Prototype.WritePixels(self: PNG, rgba: { [number]: number })
	local positionX = 0
	local positionY = 0

	for rgbaIndex = 1, #rgba, 4 do
		local rawPixelQueue = { rgba[rgbaIndex + 0], rgba[rgbaIndex + 1], rgba[rgbaIndex + 2], rgba[rgbaIndex + 3] }

		repeat
			if self.DeflateBlockFilled == -1 then
				local deflateBlockSize = DEFLATE_MAX_BLOCK_SIZE

				if self.UncompressedDataRemaining < DEFLATE_MAX_BLOCK_SIZE then
					deflateBlockSize = self.UncompressedDataRemaining
				end

				self:Write(bit32.band((self.UncompressedDataRemaining <= DEFLATE_MAX_BLOCK_SIZE and 1 or 0), 0xFF))
				self:Write(bit32.band(bit32.rshift(deflateBlockSize, 0), 0xFF))
				self:Write(bit32.band(bit32.rshift(deflateBlockSize, 8), 0xFF))
				self:Write(bit32.band(bit32.bxor(bit32.rshift(deflateBlockSize, 0), 0xFF), 0xFF))
				self:Write(bit32.band(bit32.bxor(bit32.rshift(deflateBlockSize, 8), 0xFF), 0xFF))

				self:UpdateCRC32(5)

				self.DeflateBlockFilled = 0
			end

			if positionX == 0 then
				self:Write(0)
				self:UpdateCRC32(1)
				self:UpdateAdler32(1)

				positionX += 1

				self.UncompressedDataRemaining -= 1
				self.DeflateBlockFilled += 1
			else
				local index = math.clamp(DEFLATE_MAX_BLOCK_SIZE - self.DeflateBlockFilled, 0, 4)

				if self.LineSize - positionX < index then
					index = self.LineSize - positionX
				end

				if #rawPixelQueue < index then
					index = #rawPixelQueue
				end

				for pixelIndex = 1, index do
					self:Write(table.remove(rawPixelQueue, 1) :: number * 255)
				end

				self:UpdateCRC32(index)
				self:UpdateAdler32(index)

				positionX += index

				self.DeflateBlockFilled += index
				self.UncompressedDataRemaining -= index
			end

			if self.DeflateBlockFilled >= DEFLATE_MAX_BLOCK_SIZE then
				self.DeflateBlockFilled = -1
			end

			if positionX == self.LineSize then
				positionX = 0
				positionY += 1
			end
		until #rawPixelQueue == 0
	end
end

function PNG.Prototype.UpdateCRC32(self: PNG, length: number, resetCRC: boolean)
	if resetCRC then
		self.CRC = 0
	end

    self.CRC = bit32.bnot(self.CRC)

	for index = self.BufferPosition - length, self.BufferPosition - 1 do
		local byte = buffer.readu8(self.Buffer, index)

		for bitIndex = 0, 7 do  -- Inefficient bitwise implementation, instead of table-based
			local bit = bit32.band(bit32.bxor(self.CRC, bit32.rshift(byte, bitIndex)), 1);

			self.CRC = bit32.bxor(bit32.rshift(self.CRC, 1), bit32.band((-bit), 0xEDB88320));
		end
	end

	self.CRC = bit32.bnot(self.CRC)

	return self.CRC
end

function PNG.Prototype.UpdateAdler32(self: PNG, length: number)
	local s1 = bit32.band(self.Adler, 0xFFFF)
	local s2 = bit32.rshift(self.Adler, 16)

	for index = self.BufferPosition - length, self.BufferPosition - 1 do
		s1 = (s1 + buffer.readu8(self.Buffer, index)) % 65521
		s2 = (s2 + s1) % 65521
	end

	self.Adler = bit32.bor(bit32.lshift(s2, 16), s1)
end

--[=[
	@method ToString
	@within PNGObject

	@return string

	Returns the binary blob for the PNG file, this is essentially the content you'd find under a `object.png` file.
]=]
function PNG.Prototype.ToString(self: PNG)
	return buffer.tostring(self.Buffer)
end

--[=[
	@function new
	@within PNGObject

	@param size Vector2
	@param rgba { [number]: number }

	@return PNGObject

	Constructor function that creates a new PNG file, when this function is called, the binary data for the RGBA array will
		be generated alongside this call.

	```lua
		local pixels = EditableImage:ReadPixels()
		local pngObject = RGBA.PNG.new(EditableImage.Size, pixels)

		HttpService:PostAsync("https://some-image-uploading-site/upload", pngObject:ToString())
	```
]=]
function PNG.Interface.new(size: Vector2, rgba: { [number]: number })
	local self = setmetatable({}, { __index = PNG.Prototype })

	self.Height = size.X
	self.Width = size.Y

	self.LineSize = (self.Width * 4 + 1)
	self.UncompressedDataRemaining = self.LineSize * self.Height
	self.DeflateBlocksCount = math.ceil(self.UncompressedDataRemaining / DEFLATE_MAX_BLOCK_SIZE)
	self.IDATSize = (self.DeflateBlocksCount * 5 + 6) + self.UncompressedDataRemaining
	
	self.BufferPosition = 0
	self.BufferSize = self.IDATSize + 96
	self.Buffer = buffer.create(self.BufferSize)

	self.CRC = 0
	self.Adler = 1
	
	-- SIGNATURE
	self:Write(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
	
	-- IHDR
	self:Write(0x00, 0x00, 0x00, 0x0D) -- magic
	self:Write(0x49, 0x48, 0x44, 0x52) -- header
	self:WriteUInt32(self.Width)  -- width
	self:WriteUInt32(self.Height) -- height
	self:Write(0x08) -- bit depth
	self:Write(6) -- color type
	self:Write(0x00) -- compression method
	self:Write(0x00) -- filter method
	self:Write(0x00) -- interlace method

	self:UpdateCRC32(17)
	self:WriteUInt32(self.CRC)

	-- TEXT
	self:WriteUInt32(27)  -- size
	self:Write(0x74, 0x45, 0x58, 0x74) -- header
	self:Write(0x53, 0x65, 0x63, 0x72, 0x65, 0x74) -- egg?
	self:Write(0x00)
	self:Write(0x41, 0x73, 0x79, 0x6E, 0x63, 0x4D, 0x61, 0x74, 0x72, 0x69, 0x78) -- not sure what this is
	self:Write(0x20, 0x57, 0x61, 0x73, 0x20, 0x48, 0x65, 0x72, 0x65) -- or this

	self:UpdateCRC32(31, true)
	self:WriteUInt32(self.CRC)

	-- -- IDAT
	self:WriteUInt32(self.IDATSize) -- size
	self:Write(0x49, 0x44, 0x41, 0x54) -- header
	self:Write(0x08, 0x1D) -- deflate

	self:UpdateCRC32(6, true)

	self:WritePixels(rgba)

	self:WriteIEND()

	return self
end

export type PNG = typeof(PNG.Prototype)

return PNG.Interface
