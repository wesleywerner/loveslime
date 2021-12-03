-- Demonstrates overriding SLIME events to:
-- * Draw a custom cursor that can be changed with right click.
-- * Draw actor portraits while they are talking.

local slime = require("slime")

-- See the animated sprites example for more on this module.
local simple_anim = require("simpleanim")

-- The display resolution of our game window
local width, height = 900, 500

-- Assets are 170x96 and scaled up on draw
local scale = 5

-- stores the displayed status text
local status_text = nil
local status_font = nil

-- Stores animations and sprites.
local animations = {}
local actor_sprites = {}


-- Define our custom cursors.
-- Note that conjunction is our custom property, and simply demonstrates
-- how to attach meta data to cursors.
-- see the @{cursor_data} table structure here.
local cursors = {

    -- Tracks the index of the current cursor.
    index = 1,

    -- Reference to the current cursor for easy access.
    current = nil,

    -- List of available cursors.
    list = {
        {
            name = "walk",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad(64, 0, 16, 16, 128, 96),
            conjunction = " to "
        },
        {
            name = "look",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad(96, 0, 16, 16, 128, 96),
            conjunction = " at "
        },
        {
            name = "talk",
            image = nil,    -- get set on load
            quad = love.graphics.newQuad(112, 0, 16, 16, 128, 96),
            conjunction = " to "
        }
    }
}

function love.load ()

    -- set window size, font and drawing filter
    love.window.setMode(width, height)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    require("ooze")(slime)

    status_font = love.graphics.newFont(10)

    -- load the cursor image.
    -- we do this here, after calling setDefaultFilter, because
    -- setDefaultFilter does not apply retroactively to loaded images.
    local cursorImage = love.graphics.newImage("media/point and click cursor.png")
    for _, cursor in ipairs(cursors.list) do
        cursor.image = cursorImage
    end

    -- load a small font
    love.graphics.setFont(love.graphics.newFont(10))

    -- reset slime for a new game
    -- see @{slime.reset}
    slime.reset()

    -- add a background image to the stage
    -- see @{background.add}
    slime.background.add("media/lab-background.png")

    -- set the walkable floor
    -- see @{floor.set}
    slime.floor.set("media/lab-floor.png")

    -- add a walk-behind layer
    -- see @{layer.add}
    slime.layer.add("media/lab-background.png", "media/lab-layer-desks.png", 51)
    slime.layer.add("media/lab-background.png", "media/lab-layer-bench.png", 200)

    -- add a couple of hotspots to interact with
    slime.hotspot.add("Cameras", 9, 2, 40, 20)

    actor_sprites = {
        Intercom = love.graphics.newImage("media/intercom-still.png"),
        Player = love.graphics.newImage("media/scientist.png")
    }

    -- add the player actor
    -- see @{actor.add}
    slime.actor.add({
        name = "Player",
        feet = "bottom",
        x = 80,
        y = 40,
        width = 12,
        height = 18,
        speed = 16,
        speechcolor = {0, 1, 0}
    })

    -- add an intercom actor, whom we can converse with
    slime.actor.add({
        name = "Intercom",
        x = 18,
        y = 50,
        width = 9,
        height = 15,
        speechcolor = {1, 1, 0}
    })

    -- Define the player animations.
    -- See the animated sprites example.
    local ego_anim = simple_anim.new(444, 18, 12, 18)
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

    -- set the first cursor
    cursors.current = cursors.list[cursors.index]
    slime.cursor.set(cursors.current)
    love.mouse.setVisible(false)

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

    -- we intentionally draw a small font scaled up
    -- so the style matches our pixelated game.
    love.graphics.push()
    love.graphics.scale(scale)

    -- print the text of the thing under the mouse cursor.
    if status_text then
        love.graphics.setColor({1, 1, 1})
        love.graphics.setFont(status_font)
        love.graphics.printf(status_text, 0, 84, 170, "center")
    end

    love.graphics.pop()

end


function love.mousepressed (x, y, button, istouch, presses)

    -- Skip any speech currently on screen and stop further processing.
    -- See @{speech.is_talking}
    if slime.speech.is_talking() then
        slime.speech.skip()
        return
    end

    -- right click cycles the cursors
    if button == 2 then
        -- Cycle to the next cursor
        cursors.index = math.max(1, (cursors.index + 1) % (#cursors.list + 1))
        cursors.current = cursors.list[cursors.index]
        slime.cursor.set(cursors.current)
        update_status_text(x, y)
        return
    end

    if cursors.current.name == "walk" then
        slime.actor.move("Player", x, y)
    else
        slime.interact(x, y)
    end

end

function love.mousemoved (x, y, dx, dy, istouch)

    -- to enable the custom cursor, we must update it's position.
    slime.cursor.update(x, y)

    update_status_text(x, y)

end

-- Set the status text to the thing under the cursor and the cursor name.
function update_status_text (x, y)

    local things = slime.get_objects(x, y)

    if things then
        cursors.current.color = {0, 1, 1}
        status_text = cursors.current.name ..
                    cursors.current.conjunction .. things[1].name
    else
        cursors.current.color = {1, 1, 1}
        status_text = cursors.current.name
    end

end

--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

-- @{event.interact}
-- When a call to @{interact} happens over a hotspot or actor.
-- The event argument will equal the name of the cursor given to @{cursor.set}.
function slime.event.interact (event, actor)

    if event == "look" then
        if actor.name == "Cameras" then
            slime.speech.say("Player", "Security is watching the lab")
        elseif actor.name == "Intercom" then
            slime.speech.say("Player", "It is a direct line to security")
        elseif actor.name == "Player" then
            slime.speech.say("Player", "That is me")
        end
    end

    if event == "talk" then
        if actor.name == "Intercom" then

            -- ensure we are close enough to speak into the Intercom
            local distance = slime.actor.measure("Player", actor)

            if distance > 20 then
                slime.speech.say("Player", "I am not close enough")
                return
            end

            slime.speech.say("Player", "Hello, anybody there?")
            slime.speech.say("Intercom", "*pop* *crackle*")

        elseif actor.name == "Cameras" then
            slime.speech.say("Player", "I can use the Intercom to talk to security")
        end
    end

end

-- @{event.draw_speech}
-- Override speech drawing to show an enlarged actor portrait while talking.
function slime.event.draw_speech (actor_name, words)

    -- Wrap text at this width
    local wrap_width = 170 - 45

    local print_x, print_y = 45, 0

    local actor = slime.actor.get(actor_name)

    -- A dark overlay
    love.graphics.setColor({0, 0, 0, 0.5})
    love.graphics.rectangle("fill", 0, 0, 170, 96)

    -- Print the spoken words
    love.graphics.setColor(actor.speechcolor)
    love.graphics.printf(words, print_x, print_y, wrap_width, "center")

    -- Draw the actor sprite as a portrait.
    -- This is a cheap way to demonstrate how speech can be customized.
    love.graphics.push()
    love.graphics.scale(5, 5)
    love.graphics.setColor({1, 1, 1})
    if actor.sprite.quad then
        love.graphics.draw(actor.sprite.image, actor.sprite.quad)
    else
        love.graphics.draw(actor.sprite.image)
    end
    love.graphics.pop()

end

-- @{event.draw_cursor}
-- Override cursor drawing to colorize cursors that are hovered over things.
function slime.event.draw_cursor (cursor, x, y)

    love.graphics.setColor(cursors.current.color)
    love.graphics.draw(cursor.image, cursor.quad, x, y)

end

-- @{event.request_sprite}
-- See the animated sprites example for notes on this override.
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
