local net = require("@lune/net")
local fs = require("@lune/fs")

local PORT = 1227

print(`Binding 'file-server' to port {PORT}!`)

net.serve(PORT, function(data)
	print("Writing PNG file!")

	fs.writeFile(`example.png`, data.body)

	return {
		status = 200,
	}
end)
