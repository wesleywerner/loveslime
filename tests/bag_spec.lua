describe("bag", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    function mock_bag_updated (name)
    end

    it("add", function()
        local _event = spy.new(mock_bag_updated)
        local _default = slime.event.bag_updated
        slime.event.bag_updated = _event
        slime.bag.clear()
        slime.bag.add("bag name", {["name"]="thing name", ["image"]="mock.png"})
        slime.event.bag_updated = _default
        assert.are.equals(1, #slime.bag.contents["bag name"])
        assert.spy(_event).was.called()
        assert.spy(_event).was.called_with("bag name", "thing name")
    end)

    it("add incomplete", function()
        slime.bag.clear()
        assert.has_error(function()
                        slime.bag.add("bag name", {["bad"]="thing name"})
                        end, "bag item requires a name")
    end)

    it("add duplicate", function()
        slime.bag.clear()
        slime.bag.add("bag name", {["name"]="thing name"})
        assert.has_error(function()
                        slime.bag.add("bag name", {["name"]="thing name"})
                        end, "bag \"bag name\" already contains \"thing name\"")
    end)

    it("remove", function()
        local _event = spy.new(mock_bag_updated)
        slime.bag.clear()
        slime.bag.add("bag name", {["name"]="thing name"})
        local _default = slime.event.bag_updated
        slime.event.bag_updated = _event
        slime.bag.remove("bag name", "thing name")
        slime.event.bag_updated = _default
        assert.are.equals(0, #slime.bag.contents["bag name"])
        assert.spy(_event).was.called_with("bag name", "thing name")
    end)

end)
