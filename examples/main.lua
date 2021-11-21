local examples = {
    "basic_setup",
    "animated_sprites",
    "events"
}

local cursor = 1
local width, height = 640, 400

function love.load ()

    love.window.setMode (width, height)
    love.graphics.setFont (love.graphics.newFont (20))

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit ()
    elseif key == "up" then
        cursor = math.max (1, cursor - 1)
    elseif key == "down" then
        cursor = math.min (cursor + 1, #examples)
    elseif key == "return" then
        require (examples[cursor])
        -- call the example load method
        love.load ()
    end

end

function love.draw ()

    love.graphics.clear ({0.3, 0.3, 0.6})
    love.graphics.setColor ({0.7, 0.7, 1})
    love.graphics.printf ("Use your cursor keys to pick the example to run", 0, 20, width, "center")

    for num, example in ipairs (examples) do

        local y = 40 + (num * 24)

        if num == cursor then
            love.graphics.setColor ({0.7, 1, 1})
        else
            love.graphics.setColor ({0.7, 0.7, 1})
        end

        love.graphics.printf (example, 0, y, width, "center")

    end

end
