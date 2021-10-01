-- This example shows how to set a stage background image, set a walkable floor,
-- add an actor that moves where you click, and walk-behind layers.

local slime = require ("slime")

local width, height = 680, 384

-- assets are 170x96, scale them up to match our window size.
local scale = 4

-- stores the displayed status text
local statusText = nil

-- font used to print the status text
local statusFont

function love.load ()

    -- set window size, font and drawing filter
    love.window.setMode (width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    -- load the status text font
    statusFont = love.graphics.newFont (10)

    -- reset slime for a new game
    -- see @{slime.reset}
    slime.reset ()

    -- add a background image to the stage
    -- see @{backgrounds.add}
    slime.backgrounds.add ("media/lab-background.png")

    -- set the walkable floor
    -- see @{floors.set}
    slime.floors.set ("media/lab-floor.png")

    -- add a walk-behind layer
    -- see @{layers.add}
    slime.layers.add ("media/lab-background.png", "media/lab-layer-bench.png", 200)
    slime.layers.add ("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- add the player actor
    -- see @{actors.add}
    slime.actors.add ({

        -- name of the actor
        name = "Player",

        -- use a still image for now, we will add animated sprites later.
        -- this allows quick game development without animations.
        image = love.graphics.newImage ("media/scientist-still.png"),

        -- set the position of the actor's feet (by default this is "bottom")
        feet = "bottom",

        -- starting position
        x = 80,
        y = 40,

        -- walking speed in pixels per second
        speed = 16

    })

end

function love.update (dt)

    -- see @{slime.update}
    slime.update (dt)

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit ()
    end

end

function love.draw ()

    -- see @{slime.draw}
    slime.draw (scale)

    -- print the text of the thing under the mouse cursor.
    -- we intentionally draw a small font scaled up
    -- so the style matches our pixelated game.
    if statusText then
        love.graphics.push ()
        love.graphics.scale (scale)
        love.graphics.setFont (statusFont)
        love.graphics.setColor ({1, 1, 1})
        love.graphics.printf (statusText, 0, 84, 170, "center")
        love.graphics.pop ()
    end

end

function love.mousepressed (x, y, button, istouch, presses)

    -- see @{actors.move}
    slime.actors.move ("Player", x, y)

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- get all things under the mouse position
    -- see @{slime.getObjects}
    local things = slime.getObjects (x, y)

    -- set our status text to the first thing found
    if things then
        statusText = things[1].name
    else
        statusText = nil
    end

end
