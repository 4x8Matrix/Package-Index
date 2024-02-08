return function()
	local ConsoleModule = require(script.Parent)

	it("Should be able to generate a Logger object", function()
		expect(function()
			ConsoleModule.new("Example")
		end).never.to.throw()
	end)

	it("Should be able to detect 'Console' objects", function()
		expect(function()
			local consoleObject = ConsoleModule.new("Example")

			expect(ConsoleModule.is(consoleObject)).to.equal(true)
		end).never.to.throw()
	end)

	it("Should be able to log recursive tables", function()
		expect(function()
			local consoleObject = ConsoleModule.new("Example")

			local recursiveTable = { }

			recursiveTable.b = { c = recursiveTable }

			-- consoleObject:SetLogLevel(10)
			consoleObject:Log(recursiveTable)
		end).never.to.throw()
	end)

	describe("Ability to 'fetch' previously logged messages", function()
		it("Should be able to fetch logs by order", function()
			local consoleObject = ConsoleModule.new("Example")

			consoleObject:SetLogLevel(10)

			consoleObject:Log(0)
			consoleObject:Warn(0)

			expect(consoleObject:FetchLogs(1)[1][1]).to.equal("warn")
			expect(consoleObject:FetchLogs(2)[2][1]).to.equal("log")
		end)
	end)

	describe("Assertions, Critical, Error, Warn, Logs & Debug calls", function()
		it("Should be able to assert conditions correctly", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:Assert(true, "Test")
			end).never.to.throw()

			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:Assert(false, "Test")
			end).to.throw()
		end)

		it("Should be able to critical message", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:SetLogLevel(10)
				consoleObject:Critical("Test")

				expect(consoleObject:FetchLogs(1)[1]).to.equal("critical")
			end).to.throw()
		end)

		it("Should be able to error message", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:SetLogLevel(10)
				consoleObject:Error("Test")

				expect(consoleObject:FetchLogs(1)[1]).to.equal("error")
			end).to.throw()
		end)

		it("Should be able to warn message", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:SetLogLevel(10)
				consoleObject:Warn("Test")

				expect(consoleObject:FetchLogs(1)[1]).to.equal("warn")
			end).to.throw()
		end)

		it("Should be able to log message", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:SetLogLevel(10)
				consoleObject:Log("Test")

				expect(consoleObject:FetchLogs(1)[1]).to.equal("log")
			end).to.throw()
		end)

		it("Should be able to debug message", function()
			expect(function()
				local consoleObject = ConsoleModule.new("Example")

				consoleObject:SetLogLevel(10)
				consoleObject:Debug("Test")

				expect(consoleObject:FetchLogs(1)[1]).to.equal("debug")
			end).to.throw()
		end)
	end)
end