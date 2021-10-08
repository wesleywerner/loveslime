describe("layer", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    it("add", function()
        -- A pixel map defining both background and layer.
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

        local _expected = {
            [1] = {0, 0,  0,  0,  0},
            [2] = {0, 8,  8,  8,  0},
            [3] = {0, 12, 12, 12, 0},
            [4] = {0, 16, 16, 16, 0},
            [5] = {0, 0,  0,  0,  0}}

        -- add layer from mocked pixels; clear them when done.
        slime.layer.add("background.png", "mask.png", 5)
        _G.love.mock_pixels = nil

        -- test drawing the layer
        slime.actor.draw()

        -- layers and actors share a table for quick sorting
        local _data = slime.actor.list[1]
        assert.is_not_nil(_data)
        assert.is_true(_data.islayer)
        assert.are.same(_expected, _data.image.pixeldata)
    end)

end)
