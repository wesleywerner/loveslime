-- This example shows how to display speech and
-- includes a basic linear conversation.

local slime = require("slime")
local sa = require("simpleanim")

local width, height = 900, 500

-- assets are 170x96, scale them up to match our window size.
local scale = 5

-- stores the displayed status text
local statusText = nil

-- font used to print the status text
local statusFont

function love.load ()

    -- set window size, font and drawing filter
    love.window.setMode(width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    -- load the status text font
    statusFont = love.graphics.newFont(10)

    -- reset slime for a new game
    slime.reset()

    -- add a background image to the stage
    slime.background.add("media/lab-background.png")

    -- set the walkable floor
    slime.floor.set("media/lab-floor.png")

    -- add a walk-behind layer
    slime.layer.add("media/lab-background.png", "media/lab-layer-bench.png", 200)
    slime.layer.add("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- add a couple of hotspots to interact with
    slime.hotspot.add("Cameras", 9, 2, 40, 20)

    images={
        Intercom=love.graphics.newImage("media/intercom-still.png"),
        Player=love.graphics.newImage("media/scientist.png")
    }

    -- add the player actor
    slime.actor.add({

        -- name of the actor
        name = "Player",

        -- use a still image for now, we will add animated sprites later.
        -- this allows quick game development without animations.
        --image = love.graphics.newImage("media/scientist-still.png"),

        -- set the position of the actor's feet (by default this is "bottom")
        feet = "bottom",

        -- starting position
        x = 80,
        y = 40,

        width=12,
        height=18,

        -- walking speed in pixels per second
        speed = 16,

        -- set the player speech color
        speechcolor = {0, 1, 0}

    })

    -- add an intercom actor, whom we can converse with
    slime.actor.add({
        name="Intercom",
        x=18,
        y=50,
        width=9,
        height=15,
        speechcolor={1, 1, 0}
    })

    -- Define player sprites using @{simpleanim}.
    -- West facing sprites are just copies of East, and will be flipped in
    -- the slime.event.request_sprite callback below.
    ego_anim = sa.new(444, 18, 12, 18)
    sa.add(ego_anim, "idle north", {18,1}, 1)
    sa.add(ego_anim, "idle south", {10,1, 11,1}, {0.1, 3})
    sa.add(ego_anim, "idle east", {2,1, 3,1}, {0.1, 3})
    sa.add(ego_anim, "idle west", {2,1, 3,1}, {0.1, 3})
    sa.add(ego_anim, "walk north", {19,1, 20,1, 21,1, 20,1}, 0.1)
    sa.add(ego_anim, "walk south", {11,1, 12,1, 13,1, 14,1}, 0.1)
    sa.add(ego_anim, "walk east", {4,1, 5,1, 6,1, 5,1}, 0.1)
    sa.add(ego_anim, "walk west", {4,1, 5,1, 6,1, 5,1}, 0.1)
    sa.add(ego_anim, "talk north", {18,1}, 1)
    sa.add(ego_anim, "talk south", {15,1, 17,1, 15,1, 16,1}, 0.2)
    sa.add(ego_anim, "talk east", {7,1, 9,1, 7,1, 8,1}, 0.2)
    sa.add(ego_anim, "talk west", {7,1, 9,1, 7,1, 8,1}, 0.2)

    -- say a greeting
    --slime.speech.say("Player", "Hey, that intercom on the wall is new", 6)

end

function love.update (dt)

    -- see @{slime.update}
    slime.update(dt)

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit()
    end

end

function love.draw ()

    -- see @{slime.draw}
    slime.draw(scale)
    --slime.ooze.outliner.draw(scale)

    -- print the text of the thing under the mouse cursor.
    -- we intentionally draw a small font scaled up
    -- so the style matches our pixelated game.
    if statusText then
        love.graphics.push()
        love.graphics.scale(scale)
        love.graphics.setFont(statusFont)
        love.graphics.setColor({1, 1, 1})
        love.graphics.printf(statusText, 0, 80, 170, "center")
        love.graphics.pop()
    end

end


function love.mousepressed (x, y, button, istouch, presses)

    -- skip any speech currently on screen, and ignore further clicks.
    if slime.speech.is_talking() then
        slime.speech.skip()
        return
    end

    -- interact with an object if the mouse is over something
    if statusText then
        slime.interact(x, y)
    else
        -- otherwise, walk there
        -- see @{actor.move}
        slime.actor.move("Player", x, y)
    end

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- get all things under the mouse cursor
    -- see @{slime.get_objects}
    local things = slime.get_objects(x, y)

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
-- This is called when @{slime.interact} happens when the cursor is over
-- an actor or hotspot.
-- The "event" parameter will be "interact" by default, or the name of the
-- cursor if you set one, but we won't check it's value in this example.
function slime.event.interact (event, actor)

    -- see @{speech.say}
    if actor.name == "Intercom" then

        -- ensure we are close enough to speak into the Intercom
        local distance = slime.actor.measure("Player", actor)

        if distance > 20 then
            slime.speech.say("Player", "I am not close enough")
            return
        end

        -- say the current dialog.
        -- notice how we call say multiple times, this queues the speeches
        -- one after the other.
        for _, data in ipairs(dialog[dialogPosition]) do
            slime.speech.say(data[1], data[2])
        end

        -- advance the dialog position
        dialogPosition = math.min(#dialog, dialogPosition + 1)

    elseif actor.name == "Cameras" then

        slime.speech.say("Player", "Our lab is monitored.")
        slime.speech.say("Player", "This is top-secret work.")

    end

end

function slime.event.request_sprite(actor_name, action, direction, dt)

    local quad = nil

    local ox, sx = 0, 1

    if actor_name == "Player" then
        -- update this action animation and get the quad
        local key = action.." "..direction
        sa.update(ego_anim, key, dt)
        quad = sa.quad_of(ego_anim, key)
        -- west facing sprites are just flipped versions of the east sprites
        if direction == "west" then
            sx = -1
            ox = ego_anim.sprite_w
        end
    end

    return {
        image=images[actor_name], quad=quad,
        x=0, y=0, r=0, sx=sx, sy=1, ox=ox, oy=0
    }

end
