describe("background", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    it("add", function()
        slime.background.clear()
        slime.background.add("mock.png", 1)
        assert.are.equals(1, #slime.background.list)
    end)

    it("draw", function()
        slime.background.clear()
        slime.background.add("mock.png", 1)
        slime.background.update(0)
        slime.background.draw()
    end)

    it("add", function()
        slime.background.clear()
        slime.background.add("mock 1.png", 1)
        slime.background.add("mock 2.png", 1)
        slime.background.update(1)
        slime.background.update(2) -- timer moves to next background
    end)

end)
