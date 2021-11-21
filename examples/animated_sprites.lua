-- Demonstrates animated actor sprites along with:
-- * Hotspots, fixed areas on the stage you can interact with
-- * Multiple actors and interacting with them.
-- * Basic speech in a linear dialogue
-- * Chaining actions to run in sequence

local slime = require("slime")

-- In this example we use the simple animation module utilizing Löve quads.
-- It only supports sprite sheets that have no offsets or padding. The individual
-- sprites also have to be the same size. Useful to get you up and running or
-- for prototyping. You will no doubt seek, and are encouraged to find, a
-- more feature rich animation library.
local simple_anim = require("simpleanim")

-- The display resolution of our game window
local width, height = 900, 500

-- Assets are 170x96 and scaled up on draw
local scale = 5

-- Stores the displayed status text.
-- This is set from the object under the mouse cursor.
local status_text = nil
local status_font = nil

-- Stores animation data.
local animations = {}

-- Stores actor sprite sheets or still images.
local actor_sprites = {}

-- Defines a very basic linear conversation.
-- Each time the player interacts with the intercom the relevant lines are said
-- and the dialog position is incremented.
local dialog_position = 1
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


function love.load ()

    -- Create the game window and set scaling filter to be pixel-perfect
    love.window.setMode(width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    status_font = love.graphics.newFont(10)

    -- Reset slime to clear any previously used resources.
    -- This is most useful when restarting a game, and is used here
    -- to illustrate only.
    -- see @{slime.reset}
    slime.reset()

    -- Add a background to the stage.
    -- see @{background.add}
    slime.background.add("media/lab-background.png")

    -- Set the walkable areas of the floor.
    -- see @{floor.set}
    slime.floor.set("media/lab-floor.png")

    -- Add a walk-behind layer
    slime.layer.add("media/lab-background.png", "media/lab-layer-desks.png", 51)

    -- add a couple of hotspots to interact with
    slime.hotspot.add("Cameras", 9, 2, 40, 20)

    actor_sprites = {
        Intercom = love.graphics.newImage("media/intercom-still.png"),
        Player = love.graphics.newImage("media/scientist.png")
    }

    -- Add the player actor.
    -- Note how we no longer set the image property.
    -- We override the request_sprite method, which provides
    -- all the data needed for drawing actor sprites.
    slime.actor.add({
        name = "Player",
        feet = "bottom",
        x = 80,
        y = 40,
        width = 12,
        height = 18,
        speed = 16
    })

    -- Add an intercom actor, whom we can converse with
    slime.actor.add({
        name = "Intercom",
        x = 18,
        y = 50,
        width = 9,
        height = 15
    })

    -- Define player animation quads using the simple animation module.
    -- West facing sprites are just copies of East, and will be flipped in
    -- the request_sprite method.

    -- Create an animation pack.
    -- The first two arguments define the total sprite sheet size,
    -- the second two the size of a single sprite.
    local ego_anim = simple_anim.new(444, 18, 12, 18)

    -- Add frames to the animation pack.
    -- Frames are defined as column-row pairs in the form {col, row, col, row, ...}
    -- Delays are in milliseconds.
    local idle_delays = {0.1, 3} -- each frame has a unique delay
    local walk_delays = 0.1 -- all frames have the same delay
    local talk_delays = 0.2
    simple_anim.add(ego_anim, "idle north", {18,1, 18,1}, idle_delays)
    simple_anim.add(ego_anim, "idle south", {10,1, 11,1}, idle_delays)
    simple_anim.add(ego_anim, "idle east",  {2,1, 3,1}, idle_delays)
    simple_anim.add(ego_anim, "idle west",  {2,1, 3,1}, idle_delays)
    simple_anim.add(ego_anim, "walk north", {19,1, 20,1, 21,1, 20,1}, walk_delays)
    simple_anim.add(ego_anim, "walk south", {11,1, 12,1, 13,1, 14,1}, walk_delays)
    simple_anim.add(ego_anim, "walk east",  {4,1, 5,1, 6,1, 5,1}, walk_delays)
    simple_anim.add(ego_anim, "walk west",  {4,1, 5,1, 6,1, 5,1}, walk_delays)
    simple_anim.add(ego_anim, "talk north", {18,1}, talk_delays)
    simple_anim.add(ego_anim, "talk south", {15,1, 17,1, 15,1, 16,1}, talk_delays)
    simple_anim.add(ego_anim, "talk east",  {7,1, 9,1, 7,1, 8,1}, talk_delays)
    simple_anim.add(ego_anim, "talk west",  {7,1, 9,1, 7,1, 8,1}, talk_delays)
    animations["Player"] = ego_anim

end

function love.update (dt)

    -- Update actor movement.
    -- see @{slime.update}
    slime.update(dt)

end

function love.keypressed (key)

    if key == "escape" then
        love.event.quit()
    end

end

function love.draw ()

    -- Draw the stage to screen in the given scale.
    -- see @{slime.draw}
    slime.draw(scale)

    -- Print the status text.
    -- We intentionally draw a small font scaled up
    -- so the style matches our pixelated game.
    if status_text then
        love.graphics.push()
        love.graphics.scale(scale)
        love.graphics.setFont(status_font)
        love.graphics.setColor({1, 1, 1})
        love.graphics.printf(status_text, 0, 80, 170, "center")
        love.graphics.pop()
    end

end


function love.mousepressed (x, y, button, istouch, presses)

    -- Skip any speech currently on screen and stop further processing.
    -- See @{speech.is_talking}
    if slime.speech.is_talking() then
        slime.speech.skip()
        return
    end

    -- Interrupt the chain named "moving towards the intercom".
    -- see @{chain.active}
    if slime.chain.active("moving towards the intercom") then
        slime.chain.clear("moving towards the intercom")
        slime.actor.stop("Player")
        return
    end

    -- Interact with the object under the mouse cursor.
    -- see @{slime.interact}
    if status_text then
        slime.interact(x, y)
        return
    end

    -- Move the player actor to the clicked position.
    -- see @{actor.move}
    slime.actor.move("Player", x, y)

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- Get all object under the cursor.
    -- see @{slime.get_objects}
    local things = slime.get_objects(x, y)

    -- Set the status text to the first thing.
    if things then
        status_text = things[1].name
    else
        status_text = nil
    end

end

-- Override the interact event.
-- This is fired when @{slime.interact} is called with coordinates
-- over an actor or hotspot.
-- The "event" parameter will be "interact" by default, or the name of the
-- cursor if you set one. We did not set any cursor in this example,
-- so we won't check it's value in this example.
function slime.event.interact (event, actor, clicked_x, clicked_y)

    if actor.name == "Intercom" then

        -- Test Player is close enough to speak into the Intercom.
        -- If not then move closer and interact again.
        local distance = slime.actor.measure("Player", actor)

        if distance > 20 then
            -- begin a chain of of sequencial actions.
            -- see @{chain.begin}
            slime.chain.begin("moving towards the intercom")
            slime.speech.say("Player", "I need to move closer to the Intercom.")
            slime.actor.move_to("Player", actor.name)
            slime.interact(clicked_x, clicked_y)
            slime.chain.done()
            return
        end

        -- Speak the current dialog.
        -- Note that calling say() multiple times queues the speeches.
        -- Speech progresses to the next queued item when @{slime.skip} is called.
        for _, data in ipairs(dialog[dialog_position]) do
            slime.speech.say(data[1], data[2])
        end

        -- Advance the dialog position
        dialog_position = math.min(#dialog, dialog_position + 1)

        return

    end

    if actor.name == "Cameras" then

        slime.speech.say("Player", "Our lab is monitored.")
        slime.speech.say("Player", "This is top-secret work.")

    end

end

-- Override the request_sprite event.
-- This gets called by slime to request the sprite info for an actor.
-- See @{event.request_sprite}
function slime.event.request_sprite(actor_name, action, direction, dt, sprite)

    -- This actor has animation
    if animations[actor_name] then

        local anim_pack = animations[actor_name]

        -- The animation key is same as was defined in Load()
        local key = action.." "..direction

        -- Update the animation by key and get its quad
        simple_anim.update(anim_pack, key, dt)
        sprite.quad = simple_anim.quad_of(anim_pack, key)

        -- west sprites are flipped copies of east sprites
        if direction == "west" then

            -- Flip the sprite by setting a negative scale on the x-axiz.
            -- See the love.draw() documentation.
            sprite.sx = -1

            -- Set the origin offset on the x-axiz to the sprite width.
            -- This ensures the flipped copy is drawn at the same location
            -- relative to the actor's bounding box.
            sprite.ox = anim_pack.sprite_w

        else
            -- Non-flipped sprites have normal scale and origin
            sprite.sx = 1
            sprite.ox = 0
        end

    end

    -- Set the sprite image
    sprite.image = actor_sprites[actor_name]

end
