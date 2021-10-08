describe("slime", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    it("get objects", function()

        slime.clear()

        -- adds a layer to test it is excluded from get_objects
        _G.love.mock_pixels = {}
        _G.love.mock_pixels["background.png"] = {
                                {1,1,1,1,1},
                                {2,2,2,2,2},
                                {3,3,3,3,3},
                                {4,4,4,4,4},
                                {5,5,5,5,5}}

        _G.love.mock_pixels["mask.png"] = {
                                {0,0,0,0,0},
                                {0,1,1,1,0},
                                {0,1,1,1,0},
                                {0,1,1,1,0},
                                {0,0,0,0,0}}
        slime.layer.add("background.png", "mask.png", 5)
        _G.love.mock_pixels = nil

        -- adds an actor, it should be returned by get_objects
        local _actor = slime.actor.add ({
            name = "ego",
            image = love.graphics.newImage("small.png"),
            feet = "bottom", x = 80, y = 40
        })

        -- adds a hotspot, it should be returned by get_objects
        local _hotspot = slime.hotspot.add("spot", 70, 30, 90, 50)

        -- test objects match
        local _data = slime.get_objects(80, 40)
        assert.are.equals(2, #_data)
        assert.are.equals(_actor, _data[1])
        assert.are.equals(_hotspot, _data[2])

        -- negative test: no results
        local _data = slime.get_objects(10, 10)
        assert.is_nil(_data)

    end)

    it("actor interact", function()

        slime.clear()
        -- use a custom cursor name
        slime.cursor.set({name="look", image=true})
        local _actor = slime.actor.add ({
            name = "ego",
            image = love.graphics.newImage("small.png"),
            feet = "bottom", x = 80, y = 40
        })
        local _event = spy.new(function()end)
        local _default = slime.event.interact
        slime.event.interact = _event
        slime.interact(80, 40)
        slime.event.interact = _default
        assert.spy(_event).was_called_with("look", _actor)

    end)

    it("hotspot interact", function()

        slime.clear()
        local _hotspot = slime.hotspot.add("spot", 0, 0, 20, 20)
        local _event = spy.new(function()end)
        local _default = slime.event.interact
        slime.event.interact = _event
        slime.interact(5, 5)
        slime.event.interact = _default
        assert.spy(_event).was_called_with("interact", _hotspot)

    end)

    it("update / draw", function()
        slime.clear()
        slime.background.add("mock.png")
        slime.actor.add ({
            name = "ego",
            image = love.graphics.newImage("small.png"),
            feet = "bottom", x = 80, y = 40
        })
        slime.update(0.1)
        slime.draw()
    end)

end)
