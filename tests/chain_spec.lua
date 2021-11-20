describe("chain", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    function mock_user_function() end

    it("begin clear done", function()
        slime.clear()
        -- begin 1
        slime.chain.begin("test 1")
        local _chain1 = slime.chain.list["test 1"]
        assert.are.equals(slime.chain.capture, _chain1)
        -- begin 2
        slime.chain.begin("test 2")
        local _chain2 = slime.chain.list["test 2"]
        assert.are.equals(slime.chain.capture, _chain2)
        -- done
        slime.chain.done()
        assert.is_falsy(slime.chain.capture)
        -- clear
        slime.chain.clear("test 1")
        assert.is_falsy(slime.chain.list["test 1"])
        assert.is_truthy(slime.chain.list["test 2"])
    end)

    it("actor move", function()

        -- set up actors
        slime.clear()
        local _ego = slime.actor.add({
            name="ego", feet="bottom", x=10, y=10, width=10, height=40
        })
        local _lamp = slime.actor.add({
            name="lamp", feet="bottom", x=14, y=14, width=10, height=40
        })

        -- test chain has begun
        slime.chain.clear()
        slime.chain.begin("test")
        local _chain = slime.chain.list["test"]

        -- test actor movement chained
        slime.actor.move_to("ego", "lamp")
        slime.chain.done()
        local _move_action = _chain.actions[1]
        assert.are.equals(1, #_chain.actions)
        assert.are.equals(_lamp.x, _move_action.parameters[2])
        assert.are.equals(_lamp.y, _move_action.parameters[3])

        -- test actor gets a path once chain updates
        assert.are.equals("nil", type(_ego.path))
        assert.is.falsy(_move_action.ran)
        slime.chain.update()
        assert.is.truthy(_move_action.ran)
        assert.are.equals("table", type(_ego.path))
        assert.is.truthy(#_ego.path > 0)

        -- test chain action removed when movement path is empty
        slime.actor.update(0) -- step
        slime.chain.update() -- ...
        assert.are.equals("table", type(_ego.path))
        slime.actor.update(0) -- step
        slime.actor.update(0) -- ...
        slime.actor.update(0) -- ...
        slime.actor.update(0) -- ...
        slime.chain.update() -- update chain, removes action
        assert.are.equals("nil", type(_ego.path))
        assert.are.equals(0, #_chain.actions)

    end)

    it("wait", function()
        slime.clear()
        slime.chain.begin("test")
        -- wait 3 seconds
        slime.chain.wait(3)
        slime.chain.done()
        -- action exists
        local _chain = slime.chain.list["test"]
        assert.are.equals(1, #_chain.actions)
        -- simulate 3 seconds passed
        slime.update(2)
        slime.update(2)
        assert.are.equals(0, #_chain.actions)
    end)

    it("user function", function()
        local _user = spy.new(mock_user_function)
        slime.chain.clear()
        slime.chain.begin("test")
        slime.chain.add(_user, {"one", "two"})
        -- update the chain, triggers the user function
        slime.chain.update()
        -- test user function was called
        assert.spy(_user).was_called_with("one", "two")
        -- test the user action expired and was removed
        assert.are.equals(0, #slime.chain.list["test"].actions)
    end)

    it("actor turn", function()
        slime.clear()
        local _ego = slime.actor.add({
            name="ego", feet="bottom", x=10, y=10, width=10, height=40
        })
        slime.chain.begin()
        slime.actor.turn("ego", "west")
        slime.chain.done()
        assert.are.equals("south", _ego.direction)
        slime.chain.update()
        assert.are.equals("west", _ego.direction)
    end)

    it("floor set", function()
        slime.clear()
        slime.chain.begin()
        slime.floor.set("small.png")
        slime.chain.done()
        assert.is.falsy(slime.floor.data)
        slime.chain.update()
        assert.is.truthy(slime.floor.data)
    end)

    it("speech say", function()
        local _event = spy.new(function() end)
        local _default = slime.event.speech_started
        slime.event.speech_started = _event
        slime.clear()
        slime.actor.add({
            name="ego", feet="bottom", x=10, y=10, width=10, height=40
        })

        -- chain speech
        slime.chain.begin()
        slime.speech.say("ego", "hello world")
        slime.chain.done()

        -- negative test
        slime.speech.update()
        assert.is_false(slime.speech.is_talking("ego"))
        assert.spy(_event).was_not_called_with("ego")

        -- trigger speech
        slime.chain.update()
        slime.speech.update()
        assert.is_true(slime.speech.is_talking("ego"))
        assert.spy(_event).was_called_with("ego")
    end)

    it("active", function()
        slime.clear()
        slime.chain.begin("active test")
        slime.chain.wait(1)
        slime.chain.done()
        assert.is_false(slime.chain.active("default"))
        assert.is_true(slime.chain.active("active test"))
    end)

    it("interact", function()

        -- spy on the slime.interact method
        local _default = slime.interact
        local _event = spy.new(slime.interact)
        slime.interact = _event

        slime.clear()
        slime.chain.begin("interact test")
        slime.interact(10, 22)
        slime.chain.done()

        -- test action parameters
        local _chain = slime.chain.list["interact test"]
        assert.are.equals(1, #_chain.actions)
        assert.are.same({10, 22}, _chain.actions[1].parameters)

        -- test method called n times with correct parameters
        slime.chain.update()
        assert.spy(_event).was_called(2)
        assert.spy(_event).was_called_with(10, 22)

        slime.interact = _default
    end)

end)
