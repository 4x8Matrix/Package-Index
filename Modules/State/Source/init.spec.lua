return function()
	local StateModule = require(script.Parent)

	it("Should be able to generate a new State Object", function()
		expect(function()
			StateModule.new(123)
		end).never.to.throw()
	end)

	it("Should be able to detect 'State' objects", function()
		expect(function()
			local stateObject = StateModule.new(123)

			expect(StateModule.is(stateObject)).to.equal(true)
		end).never.to.throw()
	end)

	describe("Update, Set, Observe & Get on state objects", function()
		it("Should be able to Get state values", function()
			local stateObject = StateModule.new(0)

			expect(stateObject:Get()).to.equal(0)
		end)

		it("Should be able to Set state values", function()
			local stateObject = StateModule.new(0)

			stateObject:Set(1)

			expect(stateObject:Get()).to.equal(1)
		end)

		it("Should be able to Observe changes to state values", function()
			local stateObject = StateModule.new(0)
			local observeFlag = false

			stateObject:Observe(function()
				observeFlag = true
			end)

			stateObject:Set(1)

			expect(observeFlag).to.equal(true)
		end)

		it("Should be able to Update state values", function()
			local stateObject = StateModule.new(0)

			stateObject:Update(function(value)
				return value + 10
			end)

			expect(stateObject:Get()).to.equal(10)
		end)
	end)

	describe("Incrementing & Decrementing on number based states", function()
		it("Should be able to increment state object", function()
			expect(function()
				local stateObject = StateModule.new(0)

				stateObject:Increment(10)

				expect(stateObject:Get()).to.equal(10)
			end).never.to.throw()
		end)

		it("Should be able to decrement state object", function()
			expect(function()
				local stateObject = StateModule.new(10)

				stateObject:Decrement(10)

				expect(stateObject:Get()).to.equal(0)
			end).never.to.throw()
		end)
	end)

	describe("Concatenation on string based states", function()
		it("Should be able to concat a string onto an existing string", function()
			local stateObject = StateModule.new("")

			stateObject:Concat("Hello, World!")

			expect(stateObject:Get()).to.equal("Hello, World!")
		end)
	end)

	describe("State records & previous states", function()
		it("Should be able to enable recording on a State", function()
			expect(function()
				StateModule.new("")
					:SetRecordingState(true)
					:SetRecordingState(false)
			end).never.to.throw()
		end)

		it("Should be able to record changes on a State", function()
			expect(function()
				local stateObject = StateModule.new(0):SetRecordingState(true)

				stateObject:Set(1)
				stateObject:Set(2)
				stateObject:Set(3)

				local stateRecord = stateObject:GetRecord(4)

				expect(stateRecord[1]).to.equal(3)
				expect(stateRecord[2]).to.equal(2)
				expect(stateRecord[3]).to.equal(1)
				expect(stateRecord[4]).to.equal(0)
			end).never.to.throw()
		end)
	end)
end