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

    it("add", function()
        slime.actor.clear()
        slime.actor.add ({
            name = "P1",
            image = love.graphics.newImage("mock.png"), -- with
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
