-- This example shows how to display speech and
-- includes a basic linear conversation.

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
    -- see @{slime:reset}
    slime:reset ()

    -- add a background image to the stage
    -- see @{backgrounds:add}
    slime.backgrounds:add ("media/lab-background.png")

    -- set the walkable floor
    -- see @{floors:set}
    slime.floors:set ("media/lab-floor.png")

    -- add a walk-behind layer
    -- see @{layers:add}
    slime.layers:add ("media/lab-background.png", "media/lab-layer-bench.png", 200)
    slime.layers:add ("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- add a couple of hotspots to interact with
    slime.hotspots:add ("Cameras", 9, 2, 40, 20)

    -- add the player actor
    -- see @{actors:add}
    slime.actors:add ({

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
        speed = 16,

        -- set the player speech color
        speechcolor = {0, 1, 0}

    })

    -- add an intercom actor, whom we can converse with
    slime.actors:add ({
        name = "Intercom",
        image = love.graphics.newImage ("media/intercom-still.png"),
        x = 18,
        y = 50,
        speechcolor = {1, 1, 0}
    })

    -- say a greeting
    slime.speech:say ("Player", "Hey, that intercom on the wall is new", 6)

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
        love.graphics.push ()
        love.graphics.scale (scale)
        love.graphics.setFont (statusFont)
        love.graphics.setColor ({1, 1, 1})
        love.graphics.printf (statusText, 0, 84, 170, "center")
        love.graphics.pop ()
    end

end


function love.mousepressed (x, y, button, istouch, presses)

    -- skip any speech currently on screen, and ignore further clicks.
    if slime.speech:isTalking () then
        slime.speech:skip ()
        return
    end

    -- interact with an object if the mouse is over something
    if statusText then
        slime:interact (x, y)
    else
        -- otherwise, walk there
        -- see @{actors:move}
        slime.actors:move ("Player", x, y)
    end

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- get all things under the mouse cursor
    -- see @{slime:getObjects}
    local things = slime:getObjects (x, y)

    -- set our status text to the first thing found
    if things then
        statusText = things[1].name
    else
        statusText = nil
    end

end

-- a simple linear dialog with an intercom
local dialog = {
    {
        {"Player", "Hello, anybody there?"},
        {"Intercom", "*pop* *crackle*"},
        {"Intercom", "Security, what is the problem?"},
    },
    {
        {"Player", "Just checking in..."},
        {"Player", "How is the weather up there?"},
        {"Intercom", "*pop* *crackle*"},
        {"Intercom", "This channel is for security related emergencies only."},
        {"Intercom", "Now leave me alone."},
    },
    {
        {"Player", "I better leave the grumpy intercom alone."},
    }
}

local dialogPosition = 1

-- Hook into the interact event.
-- This is called when @{slime:interact} happens when the cursor is over
-- an actor or hotspot.
-- The "event" parameter will be "interact" by default, or the name of the
-- cursor if you set one, but we won't check it's value in this example.
function slime.events.interact (event, actor)

    -- see @{speech:say}
    if actor.name == "Intercom" then

        -- ensure we are close enough to speak into the Intercom
        local distance = slime.actors:measure ("Player", actor)

        if distance > 20 then
            slime.speech:say ("Player", "I am not close enough")
            return
        end

        -- say the current dialog.
        -- notice how we call say multiple times, this queues the speeches
        -- one after the other.
        for _, data in ipairs (dialog[dialogPosition]) do
            slime.speech:say (data[1], data[2])
        end

        -- advance the dialog position
        dialogPosition = math.min (#dialog, dialogPosition + 1)

    elseif actor.name == "Cameras" then

        slime.speech:say ("Player", "Our lab is monitored.")
        slime.speech:say ("Player", "This is top-secret work.")

    end

end
