local slime = require ("slime")

local width, height = 640, 400

-- assets are 320x200, scale them up x2 to match our window size.
local scale = 2

-- the name of the thing under the mouse cursor
local statusText = nil

-- print status with this font
local statusFont

function love.load ()

    -- set window size, font and drawing filter
    love.window.setMode (width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    statusFont = love.graphics.newFont (10)

    -- reset slime for a new game
    -- see @{slime:reset}
    slime:reset ()

    -- add a background image to the stage
    -- see @{backgrounds:add}
    slime.backgrounds:add ("media/fantasy-forest.png")

    -- set the walkable floor
    -- see @{floors:set}
    slime.floors:set ("media/fantasy-forest-floor.png")

    -- add a walk-behind layer
    -- see @{layers:add}
    slime.layers:add ("media/fantasy-forest.png", "media/fantasy-forest-layer.png", 200)

	-- add a couple of hotspots to interact with
    slime.hotspots:add ("scary tree", 50, 30, 70, 170)
    slime.hotspots:add ("spiderweb", 140, 0, 70, 40)

    -- add the actor
    -- see @{actors:add}
    slime.actors:add ({

        -- name of the actor
        name = "Fairy",

        -- use a still image for the Fairy.
        image = love.graphics.newImage ("media/fairy-still.png"),

        -- set the position of the actor's feet
        feet = "bottom",

        -- starting position
        x = 160,
        y = 185,

        -- walking speed
        movedelay = 0.01

    })

end

function love.update (dt)

    -- see @{slime:update}
    slime:update (dt)

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit ()
    end

end

function love.draw ()

    -- see @{slime:draw}
    slime:draw (scale)

	-- print the text of the thing under the mouse cursor.
	-- we intentionally draw a small font scaled up
	-- so the style matches our pixelated game.
    if statusText then
		local x, y = slime:scalePoint (love.mouse.getPosition ())
		x = x + 10
		love.graphics.push ()
		love.graphics.scale (scale)
		love.graphics.setFont (statusFont)
        love.graphics.setColor ({1, 1, 1})
        --love.graphics.printf (statusText, 0, 160, 200, "center")
        love.graphics.print (statusText, x, y)
        love.graphics.pop ()
    end

end

function love.mousepressed (x, y, button, istouch, presses)

	-- see @{actors:move}
	slime.actors:move ("Fairy", x, y)

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- get all things under the mouse position
    -- see @{slime:getObjects}
    local things = slime:getObjects (x, y)

    -- set our status text to the first thing found
    if things then
        statusText = things[1].name
    else
        statusText = nil
    end

end
