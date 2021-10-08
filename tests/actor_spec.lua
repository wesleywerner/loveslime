describe("actor", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    -- mock callback returns sprite data during update call.
    -- dt 1 gives the sprite a quad value.
    function mock_request_sprite(dt)
        return {
            ["image"] = true,
            x = 0,
            y = 0,
            quad = dt==1 and true or false
        }
    end

    function mock_actor_moved()
    end

    it("add", function()
        slime.actor.clear()
        slime.actor.add ({
            name = "P1",
            image = love.graphics.newImage("small.png"),
            feet = "bottom", x = 80, y = 40
        })
        slime.actor.add ({
            name = "P2", image = nil, feet = "top", x = 200, y = 100
        })
        local _p3 = slime.actor.add ({
            name = "P3", image = nil, feet = "left", x = 80, y = 40
        })
        slime.actor.add ({
            name = "P4", image = nil, feet = "right", x = 80, y = 40
        })
        local _data = slime.actor.get("P3")
        assert.are.equals(_p3, _data)
        assert.are.equals("P3", _data.name)
    end)

    it("move", function()
        -- A pixel map defining the walkable path.
        -- The goal is non-walkable so slime should pick the point just
        -- below it (which is walkable)
        _G.love.mock_pixels = { ["floor.png"]={
                                {0,0,0,0,0,0,0,0,0,0}, -- start 2,2
                                {0,8,8,8,8,8,1,1,1,1}, -- goal 2,4
                                {0,0,0,0,0,0,8,1,1,1}, -- path (8)
                                {0,0,1,0,1,8,1,1,1,1},
                                {0,8,8,0,8,1,1,1,1,1},
                                {0,1,1,8,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1}}
                              }
        local _thepath = {  {x=2,y=2}, {x=3,y=2}, {x=4,y=2}, {x=5,y=2},
                            {x=6,y=2}, {x=7,y=3}, {x=6,y=4}, {x=5,y=5},
                            {x=4,y=6}, {x=3,y=5}, {x=2,y=5}}
        -- load floor from mocked pixels; clear them when done.
        slime.floor.set("floor.png")
        _G.love.mock_pixels = nil

        local _data = slime.actor.add({
            name="ego",
            x=2,
            y=2,
            movedelay=1
        })

        slime.actor.move("ego", 2, 4)
        assert.is_not_nil(_data.path)
        assert.are.same(_thepath, _data.path)
        local _event = spy.new(mock_actor_moved)
        local _default = slime.event.actor_moved
        slime.event.actor_moved = _event
        slime.actor.update(1) -- update movement enough times to reach the goal
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.event.actor_moved = _default
        assert.spy(_event).was.called(1)
        assert.spy(_event).was.called_with("ego", 2, 4)
        assert.are.equals(2, _data.x)
        -- y-position 4 is solid. movement will be adjusted to the point below it.
        assert.are.equals(5, _data.y)
    end)

    it("move_to", function()
        -- A pixel map defining the walkable path.
        -- The goal is non-walkable so slime should pick the point just
        -- below it (which is walkable)
        _G.love.mock_pixels = { ["floor.png"]={
                                {0,0,0,0,0,0,0,0,0,0}, -- start 2,2
                                {0,8,8,8,8,8,1,1,1,1}, -- goal 2,4
                                {0,0,0,0,0,0,8,1,1,1}, -- path (8)
                                {0,0,1,0,1,8,1,1,1,1},
                                {0,8,8,0,8,1,1,1,1,1},
                                {0,1,1,8,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1},
                                {0,1,1,1,1,1,1,1,1,1}}
                              }
        local _thepath = {  {x=2,y=2}, {x=3,y=2}, {x=4,y=2}, {x=5,y=2},
                            {x=6,y=2}, {x=7,y=3}, {x=6,y=4}, {x=5,y=5},
                            {x=4,y=6}, {x=3,y=5}, {x=2,y=5}}
        -- load floor from mocked pixels; clear them when done.
        slime.floor.set("floor.png")
        _G.love.mock_pixels = nil

        local _ego = slime.actor.add({
            name="ego",
            x=2,
            y=2,
            movedelay=1
        })
        local _apple = slime.actor.add({
            name="apple",
            x=2,
            y=5
        })

        slime.actor.move_to("ego", "apple")
        assert.is_not_nil(_ego.path)
        assert.are.same(_thepath, _ego.path)
        local _event = spy.new(mock_actor_moved)
        local _default = slime.event.actor_moved
        slime.event.actor_moved = _event
        slime.actor.update(1) -- update movement enough times to reach the goal
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.actor.update(1)
        slime.event.actor_moved = _default
        assert.spy(_event).was.called(1)
        assert.spy(_event).was.called_with("ego", 2, 5)
        assert.are.equals(_apple.x, _ego.x)
        assert.are.equals(_apple.y, _ego.y)
    end)

    it("turn", function()
        slime.actor.clear()
        local _data = slime.actor.add ({
            name = "P1", feet = "bottom", x = 80, y = 40
        })
        slime.actor.turn("P1", "west")
        assert.are.equals("west", _data.direction)
    end)

    -- Although Löve is mocked, we can still test for syntax bugs.
    it("update / draw", function()
        slime.actor.clear()
        local _data = slime.actor.add ({
            name = "P1",
            image = love.graphics.newImage("mock.png"),
            feet = "bottom", x = 80, y = 40, speed = 10
        })
        slime.actor.turn("P1", "east")
        slime.event.request_sprite = mock_request_sprite
        slime.actor.update(0) -- without quad
        slime.actor.draw()
        slime.actor.update(1) -- and with
        slime.actor.draw()
        assert.are.equals("number", type(_data.drawX))
        assert.are.equals("number", type(_data.drawY))
        assert.are.equals("idle east", _data.key)
    end)

    it("measure distance between", function()
        slime.actor.clear()
        slime.actor.add ({
            name = "P1", feet = "bottom", x = 80, y = 40
        })
        slime.actor.add ({
            name = "P2", feet = "bottom", x = 200, y = 100
        })
        local _dist = math.floor(slime.actor.measure("P1", "P2"))
        assert.are.equals(134, _dist)
    end)

    it("remove", function()
        slime.actor.clear()
        slime.actor.add ({
            name = "P1", feet = "bottom", x = 80, y = 40
        })
        local _return = slime.actor.remove("P1")
        local _data = slime.actor.get("P1")
        assert.are.equals(true, _return)
        assert.is_nil(_data)
        assert.are.equals(0, #slime.actor.list)
    end)

end)
