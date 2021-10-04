describe("cursor", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    -- mock cursor draw event.
    function mock_draw_cursor()
    end

    it("none set", function()
        local _x, _y = 10, 20
        local _data = {
            name = "C",
            image = love.graphics.newImage("mock.png")
        }
        slime.cursor.clear()
        assert.are.equals("interact", slime.cursor.name())
        slime.cursor.update(_x, _y)
        assert.are.equals(_x, slime.cursor.x)
        assert.are.equals(_y, slime.cursor.y)
    end)

    it("set", function()
        local _x, _y = 10, 20
        local _data = {
            name = "C",
            image = love.graphics.newImage("mock.png")
        }
        slime.cursor.clear()
        slime.cursor.set(_data)
        assert.are.equals(_data, slime.cursor.current)
        local _name = slime.cursor.name()
        assert.are.equals("C", _name)
    end)

    it("draw custom", function()
        local _x, _y = 10, 20
        local _event = spy.new(mock_draw_cursor)
        local _data = {
            name = "C",
            image = love.graphics.newImage("mock.png")
        }
        local _default = slime.event.draw_cursor
        slime.event.draw_cursor = _event
        slime.cursor.clear()
        slime.cursor.set(_data)
        slime.cursor.update(_x, _y)
        slime.cursor.draw()
        slime.event.draw_cursor = _default
        assert.are.equals(_x, slime.cursor.x)
        assert.are.equals(_y, slime.cursor.y)
        assert.spy(_event).was.called_with(_data, _x, _y)
    end)

    it("draw default", function()
        slime.cursor.draw()
        -- with quad
        slime.cursor.set({name="test", image=true, quad=true})
        slime.cursor.draw()
    end)

end)
