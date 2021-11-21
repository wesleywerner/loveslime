--- Demonstrates setting up a basic game.
-- + A background image
-- + A walkable floor that uses path finding to move around
-- + A player actor that moves where you click
-- + Layers that the actor moves behind

local slime = require ("slime")

-- The display resolution of our game window
local width, height = 900, 500

-- Assets are 170x96 and scaled up on draw
local scale = 5


function love.load ()

    -- Create the game window and set scaling filter to be pixel-perfect
    love.window.setMode (width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    -- Reset slime to clear any previously used resources.
    -- This is most useful when restarting a game, and is used here
    -- to illustrate only.
    -- see @{slime.reset}
    slime.reset ()

    -- Add a background to the stage.
    -- see @{background.add}
    slime.background.add ("media/lab-background.png")

    -- Set the walkable areas of the floor.
    -- see @{floor.set}
    slime.floor.set ("media/lab-floor.png")

    -- Layers are areas which actors walk behind.
    -- Layers are composed of a background image and a mask that define
    -- the pixels which should be layered.
    -- The player is drawn behind the three desks in the center of the room
    -- if the player y is above 51 pixels.
    -- see @{layer.add}
    slime.layer.add ("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- Add the player actor.
    -- see @{actor.add}
    slime.actor.add ({

        name = "Player",

        -- Use a still image for this basic game.
        -- We will look at animated sprites in later examples.
        -- This allows for quick prototyping.
        image = love.graphics.newImage ("media/scientist-still.png"),

        -- Set the position of the actor's feet.
        -- This is the point on the actor image that travels along the floor.
        -- The default is "bottom"
        feet = "bottom",

        -- Starting position in the game's native scale (170x96).
        x = 80,
        y = 40,

        -- Size of this actor
        width=12,
        height=18,

        -- Walking speed in pixels per second
        speed = 16

    })

end

function love.update (dt)

    -- Update actor movement.
    -- see @{slime.update}
    slime.update (dt)

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit ()
    end

end

function love.draw ()

    -- Draw the stage to screen in the given scale.
    -- The scale is stored internally and used to automatically
    -- convert coordinates given to the actor move (and other) methods.
    -- see @{slime.draw}
    slime.draw (scale)

end

function love.mousepressed (x, y, button, istouch, presses)

    -- Move the player actor to the clicked position.
    -- Since a floor was set during Load(), the actor will find a path
    -- through walkable areas.
    -- see @{actor.move}
    slime.actor.move ("Player", x, y)

end
