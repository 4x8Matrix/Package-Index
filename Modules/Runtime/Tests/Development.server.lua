local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = require(ReplicatedStorage.Packages.Runtime)

Runtime:CallMethodOn(
	Runtime:RequireChildren(script.Parent.Services, function(object: ModuleScript, module: { [any]: any })
		warn("Loaded", object)

		return module
	end),
	"OnInit"
)
