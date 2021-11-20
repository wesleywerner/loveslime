describe("floor", function()

    _G.love = require("mocklove")

    local slime = require("slime")

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

    it("cache enabled", function()
        slime.reset()
        slime.setting["cache_floors"] = true
        slime.floor.set("small.png")
        assert.is_true(slime.cache.contains("small.png"))
    end)

    it("cache disabled", function()
        slime.reset()
        slime.setting["cache_floors"] = false
        slime.floor.set("small.png")
        assert.is_false(slime.cache.contains("small.png"))
    end)

end)
