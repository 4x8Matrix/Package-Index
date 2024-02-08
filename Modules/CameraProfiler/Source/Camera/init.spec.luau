return function()
	local Camera = require(script.Parent)

	it("Should be able to generate a Camera instance", function()
		expect(function()
			Camera.new("Abc")
		end).never.to.throw()

		expect(function()
			Camera.new()
		end).to.throw()
	end)

	it("Should be able to detect a Camera instance", function()
		local cameraObject = Camera.new("Abcd")

		expect(Camera.is(cameraObject)).to.equal(true)
	end)

	describe("Camera Lifecycle methods", function()
		it("Should be able to invoke & run camera lifecycles", function()
			local cameraObject = Camera.new("Abcde")
			local cameraFlag = false

			function cameraObject:abc()
				cameraFlag = true
			end

			cameraObject:InvokeLifecycleMethod("abc")

			expect(cameraFlag).to.equal(true)
		end)

		it("Should be able to invoke & run camera lifecycles with varadic parameters", function()
			local cameraObject = Camera.new("Abcdef")
			local cameraFlag = false

			function cameraObject:abc(a)
				cameraFlag = a
			end

			cameraObject:InvokeLifecycleMethod("abc", true)

			expect(cameraFlag).to.equal(true)
		end)

		it("Should be able to return the result of a lifecycle", function()
			local cameraObject = Camera.new("Abcdefg")

			function cameraObject:abc(a)
				return a
			end

			expect(cameraObject:InvokeLifecycleMethod("abc", true)).to.equal(true)
		end)
	end)
end