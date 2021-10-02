-- This example shows how to use a custom cursor,
-- and watch for the different SLIME events.

local slime = require ("slime")

local width, height = 680, 384

-- assets are 170x96, scale them up to match our window size.
local scale = 4

-- stores the displayed status text
local statusText = nil

-- portrait images for talking actors
local portraits = { }


-- define our custom cursors.
-- see the @{cursor} table structure here.
local cursors = {
    current = 1,
    name = "walk",
    list = {
        {
            name = "walk",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad (80, 64, 16, 16, 128, 96)
        },
        {
            name = "look",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad (16, 0, 16, 16, 128, 96)
        },
        {
            name = "talk",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad (112, 0, 16, 16, 128, 96)
        }
    }
}

function love.load ()

    -- set window size, font and drawing filter
    love.window.setMode (width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    -- load the cursor image.
    -- we do this here, after calling setDefaultFilter, because
    -- setDefaultFilter does not apply retroactively to loaded images.
    local cursorImage = love.graphics.newImage ("media/point and click cursor.png")
    for _, cursor in ipairs (cursors.list) do
        cursor.image = cursorImage
    end

    -- load a small font
    love.graphics.setFont (love.graphics.newFont (10))

    -- load actor portraits
    portraits["Intercom"] = love.graphics.newImage ("media/intercom-portrait.png")
    portraits["Player"] = love.graphics.newImage ("media/scientist-portrait.png")

    -- reset slime for a new game
    -- see @{slime.reset}
    slime.reset ()

    -- add a background image to the stage
    -- see @{background.add}
    slime.background.add ("media/lab-background.png")

    -- set the walkable floor
    -- see @{floor.set}
    slime.floor.set ("media/lab-floor.png")

    -- add a walk-behind layer
    -- see @{layer.add}
    slime.layer.add ("media/lab-background.png", "media/lab-layer-bench.png", 200)
    slime.layer.add ("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- add a couple of hotspots to interact with
    slime.hotspot.add ("Cameras", 9, 2, 40, 20)

    -- add the player actor
    -- see @{actor.add}
    slime.actor.add ({

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
    slime.actor.add ({
        name = "Intercom",
        image = love.graphics.newImage ("media/intercom-still.png"),
        x = 18,
        y = 50,
        speechcolor = {1, 1, 0}
    })

    -- say a greeting
    slime.speech.say ("Player", "Hey, that intercom on the wall is new", 6)

    -- set the first cursor
    slime.cursor.set (cursors.list[cursors.current])
    love.mouse.setVisible (false)

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

    -- we intentionally draw a small font scaled up
    -- so the style matches our pixelated game.
    love.graphics.push ()
    love.graphics.scale (scale)

    -- print the text of the thing under the mouse cursor.
    if statusText then
        love.graphics.setColor ({1, 1, 1})
        love.graphics.printf (statusText, 0, 84, 170, "center")
    end

    love.graphics.pop ()

end


function love.mousepressed (x, y, button, istouch, presses)

    -- skip any speech currently on screen, and ignore further clicks.
    if slime.speech.isTalking () then
        slime.speech.skip ()
        return
    end

    -- right click cycles the cursors
    if button == 2 then
        cursors.current = math.max (1, (cursors.current + 1) % (#cursors.list + 1))
        slime.cursor.set (cursors.list[cursors.current])
        -- store the name for quick access during mouse clicks below
        cursors.name = cursors.list[cursors.current].name
        return
    end

    if cursors.name == "walk" then
        slime.actor.move ("Player", x, y)
    else
        slime.interact (x, y)
    end

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- to enable the custom cursor, we must update it's position.
    slime.cursor.update (x, y)

    -- get all things under the mouse cursor
    -- see @{slime.getObjects}
    local things = slime.getObjects (x, y)

    -- set our status text to the first thing found
    if things then
        statusText = things[1].name
    else
        statusText = nil
    end

end

--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

-- Here we show how to hook into the various SLIME events.

-- @{event.animation}
-- When an animation loops.
--
-- @{event.bag}
-- When the contents of a bag changes.
--
-- @{event.interact}
-- When a call to @{interact} happens over a hotspot or actor.
--
-- @{event.moved}
-- When an actor reached their destination.
--
-- @{event.speech}
-- When an actor starts or stops talking.
--

function slime.event.interact (event, actor)

    if event == "look" then
        if actor.name == "Cameras" then
            slime.speech.say ("Player", "Security is watching the lab")
        elseif actor.name == "Intercom" then
            slime.speech.say ("Player", "It is a direct line to security")
        elseif actor.name == "Player" then
            slime.speech.say ("Player", "That is me")
        end
    end

    if event == "talk" then
        if actor.name == "Intercom" then

            -- ensure we are close enough to speak into the Intercom
            local distance = slime.actor.measure ("Player", actor)

            if distance > 20 then
                slime.speech.say ("Player", "I am not close enough")
                return
            end

            slime.speech.say ("Player", "Hello, anybody there?")
            slime.speech.say ("Intercom", "*pop* *crackle*")

        elseif actor.name == "Cameras" then
            slime.speech.say ("Player", "I can use the Intercom to talk to security")
        end
    end

end

function slime.event.moved (actor, clickedX, clickedY)


end

-- Override the speech event to show a portrait of the actor
-- who started talking.
function slime.event.speech (actor, isTalking)

    if isTalking then
        -- show a portrait of the talking actor
        talkingPortrait = portraits[actor.name]
    else
        -- hide the talking portrait
        talkingPortrait = nil
    end

end

-- Override the speech drawing event to wrap
-- the words around our actor portraits.
function slime.event.draw.speech (actor, words)

    local x, y = 0, 0

    -- the width of text, before it starts wrapping
    -- (adjusted to scale, which turns out to be our asset size)
    local w = 170   -- = width / scale

    -- measure the size of the portrait to fit the speech
    if talkingPortrait then
        x = talkingPortrait:getWidth ()
        w = w - x
    end

    -- shadowed background
    love.graphics.setColor({0, 0, 0, 0.5})
    love.graphics.rectangle ("fill", 0, 0, 170, 96)

    -- print words
    love.graphics.setColor(actor.speechcolor)
    love.graphics.printf(words, x, y, w, "center")

    -- draw the talking portrait
    if talkingPortrait then
        love.graphics.setColor({1, 1, 1})
        love.graphics.draw (talkingPortrait)
    end

end

-- Override the cursor draw event so that we can colorize cursors
-- that are hoevered over things.
function slime.event.draw.cursor (cursor, x, y)

    if statusText then
        love.graphics.setColor (0, 1, 1)
    else
        love.graphics.setColor (1, 1, 1)
    end

    if cursor.quad then
        love.graphics.draw (cursor.image, cursor.quad, x, y)
    else
        love.graphics.draw (cursor.image, x, y)
    end

end
