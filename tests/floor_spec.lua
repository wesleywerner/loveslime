describe("floor", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    function mock_actor_moved()
    end

    it("path", function()
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
        -- we cant test called_with as actor drawX, action, key is altered after the callback fired
        --assert.spy(_event).was.called_with(_data, 1, 3)
    end)

    it("set", function()
        slime.floor.clear()
        slime.floor.set("small.png")
        assert.are_not.same({}, slime.floor.walkableMap)
    end)

    it("size", function()
        slime.floor.clear()
        -- without floor: size from background
        slime.background.add("large.png")
        local _w, _h = slime.floor.size()
        assert.are.equals(800, _w)
        assert.are.equals(600, _h)
        -- with floor
        slime.floor.set("small.png")
        local _w, _h = slime.floor.size()
        assert.are.equals(10, _w)
        assert.are.equals(10, _h)
    end)

end)
