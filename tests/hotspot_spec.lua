describe("hotspot", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    it("add", function()
        slime.hotspot.clear()
        slime.hotspot.add("on", 10, 10, 10, 10)
        slime.hotspot.add("off", 30, 30, 20, 20)
        assert.are.equals(2, #slime.hotspot.list)

        slime.hotspot.clear()
        assert.are.equals(0, #slime.hotspot.list)
    end)

    it("add error", function()
        slime.hotspot.clear()
        assert.has_error(function()
                            slime.hotspot.add("on")
                            end, "hotspot.add missing x argument")
    end)

    it("get error", function()
        slime.hotspot.clear()
        assert.has_error(function()
                            slime.hotspot.get()
                            end, "hotspot.get called with invalid arguments")
    end)

    it("get", function()
        slime.hotspot.clear()
        slime.hotspot.add("on", 10, 10, 10, 10)
        slime.hotspot.add("off", 30, 30, 20, 20)

        -- get by name
        local _getA = slime.hotspot.get("on")
        -- get by position
        local _getB = slime.hotspot.get(35, 35)

        assert.are.equals("on", _getA.name)
        assert.are.equals("off", _getB.name)
    end)

end)
