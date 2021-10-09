--- A point-and-click adventure game library for LÖVE.
--
-- Local functions are  used internally by SLIME, you are free
-- to call these from your game if they fit a specific need.
--
-- If SLIME is missing some kind
-- of feature that you need, don't hestiate to open a ticket at
-- https://github.com/wesleywerner/loveslime
--
-- @module slime
local slime = {
    _VERSION     = 'slime v0.1',
    _DESCRIPTION = 'A point-and-click adventure game library for LÖVE',
    _URL         = 'https://github.com/wesleywerner/loveslime',
    _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2016 Wesley Werner

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

-- [ LOCAL VARIABLES ]
--
-- The draw scale is used to calculate the correct point on the screen
-- when the game is drawn at a enlarged scale.
-- Set in the slime.draw function.
local draw_scale = 1

-- Stores the delta time from the most recent update.
local last_dt = 0

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                                                   _
--   ___ ___  _ __ ___  _ __   ___  _ __   ___ _ __ | |_ ___
--  / __/ _ \| '_ ` _ \| '_ \ / _ \| '_ \ / _ \ '_ \| __/ __|
-- | (_| (_) | | | | | | |_) | (_) | | | |  __/ | | | |_\__ \
--  \___\___/|_| |_| |_| .__/ \___/|_| |_|\___|_| |_|\__|___/
--                     |_|
--
-- SLIME is structured into a modular component pattern.
-- Functionality is separated into logical tables (components) that
-- isolate their behaviour from each other.


-- Manages actors on stage.
local actor = { }

-- Manages still and animated backgrounds.
local background = { }

-- Simple inventory storage component.
local bag = { }

-- Cache images for optimized memory usage.
local cache = { }

-- Provides chaining of actions to create scripted scenes.
local chain = { }

-- Callback events which the calling code can hook into.
local event = { }

-- Manages the on-screen cursor.
local cursor = { }

-- Provides interactive hotspots on the stage, specifically areas
-- that do draw themselves on screen.
local hotspot = { }

-- Manages the walkable areas.
local floor = { }

-- Manages walk-behind layers.
local layer = { }

-- Provides path finding for actor movement.
local path = { }

-- Collection of settings that changes SLIME behaviour.
local setting = { }

-- Manages talking actors.
local speech = { }

-- Provides an integrated debugging environment
local ooze = { }

-- Reusable functions
local tool = { }


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--               _
--     __ _  ___| |_ ___  _ __ ___
--    / _` |/ __| __/ _ \| '__/ __|
--   | (_| | (__| || (_) | |  \__ \
--    \__,_|\___|\__\___/|_|  |___/

--- Actors are items on your stage that walk or talk,
-- like people, animals and robots.
-- They can also be inanimate objects like doors, toasters and computers.
--
-- @table actor_data
--
-- @tfield string name
-- The name of the actor.
--
-- @tfield int x
--
-- @tfield int y
--
-- @tfield[opt="bottom"] string feet
-- Position of the actor's feet relative to the sprite.
--
-- @tfield int speed
-- Movement speed of actor measured in pixels per second.
--
-- @tfield string action
-- The actor's current action. One of "idle", "walk" or "talk".
--
-- @tfield string direction
-- The direction the actor is facing, one of "north", "south", "east", "west".
--


--- Clear actors.
-- This gets called by @{slime.clear}
--
-- @local
function actor.clear ( )

    actor.list = { }

end

--- Add an actor.
--
-- @tparam actor_data data
function actor.add (data)

    assert(data, "Actor definition must be given.")

    assert(data.x, "Actor x position must be given.")
    assert(data.y, "Actor y position must be given.")
    assert(data.width, "Actor width must be given.")
    assert(data.height, "Actor height must be given.")

    data.isactor = true
    data.feet = data.feet or "bottom"
    data.direction = "south"
    data.speechcolor = data.speechcolor or {1, 1, 1}
    data.action = "idle"

    -- map the feet position from string to a table
    if data.feet == "bottom" then
        data.feet = { x = data.width / 2, y = data.height}
    elseif data.feet == "top" then
        data.feet = { x = data.width / 2, y = 0}
    elseif data.feet == "left" then
        data.feet = { x = 0, y = data.height / 2}
    elseif data.feet == "right" then
        data.feet = { x = data.width, y = data.height / 2}
    end

    assert(type(data.feet) == "table", "Actor feet property must be string or a table")
    assert(data.feet.x, "Actor feet must have x position")
    assert(data.feet.y, "Actor feet must have y position")

    -- set the movement speed.
    -- speed is assumed to be the pixels per second to move.
    -- we convert this to time to wait before updating the path.
    if type(data.speed) == "number" then
        data.movedelay = 1 / data.speed
    end

    table.insert(actor.list, data)
    actor.sort()
    return data

end

--- Measure distance between two actors.
--
-- @param from
-- The object to measure, this can be an @{actor_data}, a @{point}, or
-- the name of an actor.
--
-- @param to
-- The object to measure, this can be an @{actor_data}, a @{point}, or
-- the name of an actor.
--
-- @return Distance in pixels
-- @see tool.distance
function actor.measure (from, to)

    -- resolve actors by name
    if type(from) == "string" then
        from = actor.get(from)
    end
    if type(to) == "string" then
        to = actor.get(to)
    end

    assert(type(from) == "table", "measure from parameter must be a table")
    assert(type(to) == "table", "measure from parameter must be a table")
    assert(type(from.x) == "number", "measure from.x property must be a number")
    assert(type(from.y) == "number", "measure from.y property must be a number")
    assert(type(to.x) == "number", "measure to.x property must be a number")
    assert(type(to.y) == "number", "measure to.y property must be a number")

    return tool.distance(from.x, from.y, to.x, to.y)

end

--- Update actors
--
--  animations and movement.
--
-- @tparam int dt
-- The delta time since the last update.
--
-- @local
function actor.update (dt)

    -- remember if any actors moved during this update
    local actorsMoved = false

    for _, whom in ipairs(actor.list) do
        if whom.isactor then

            -- update the movement path
            if not whom.movement_paused and actor.update_movement(whom, dt) then
                actorsMoved = true
            end

            -- calculate the sprite draw position
            -- relative to the actor's feet
            if whom.x and whom.feet then
                whom.drawX = whom.x - whom.feet.x
                whom.drawY = whom.y - whom.feet.y
            end

            -- request the next sprite frame
            whom.sprite = event.request_sprite(whom.name, whom.action, whom.direction, dt)

        end
    end

    -- sort the draw order of actor if any moved
    if actorsMoved then
        actor.sort()
    end

end

--- Sort actors.
--
-- Orders actors and layers for correct z-order drawing.
-- It sorts by actor feet position (for actors)
-- and baselines (for layers).
--
-- @local
function actor.sort ( )

    table.sort(actor.list, function (a, b)

            --~ local m = a.isactor and a.y or a.baseline
            --~ local n = b.isactor and b.y or b.baseline
            --~ if a.isactor and a.nozbuffer then m = 10000 end
            --~ if b.isactor and b.nozbuffer then n = 10001 end
            --~ return m < n

            -- layers only have a baseline.
            -- actors can optionally have a baseline.

            local aY = 0
            local bY = 0

            if a.islayer then
                aY = a.baseline
            elseif a.onTop then
                aY = 10000
            elseif a.onBottom then
                aY = -10000
            else
                aY = a.y + (a.baseline or 0)
            end

            if b.islayer then
                bY = b.baseline
            elseif b.onTop then
                bY = 10001
            elseif b.onBottom then
                bY = -10001
            else
                bY = b.y + (b.baseline or 0)
            end

            return aY < bY

    end)

end

--- Update actor path.
-- Moves an actor to the next point in their movement path.
--
-- @tparam actor_data data
-- The actor to update.
--
-- @tparam int dt
-- The delta time since last update.
--
-- @local
function actor.update_movement (data, dt)

    if (data.path and #data.path > 0) then

        data.action = "walk"

        -- Check if the actor's speed is set to delay movement.
        -- If no speed is set, we move on every update.

        -- TODO change actor movedelay to pixel "speed".
        --      (can we specify this as pixels per second?)
        --      (one step on the path will be ~ 1 pixel)
        if (data.movedelay) then

            -- start a new move delay counter
            if (not data.movedelaydelta) then
                data.movedelaydelta = data.movedelay
            end

            data.movedelaydelta = data.movedelaydelta - dt

            -- the delay has not yet passed
            if (data.movedelaydelta > 0) then
                return
            end

            -- the delay has passed. Reset it and continue.
            data.movedelaydelta = data.movedelay

        end

        -- load the next point in the path
        local point = table.remove(data.path, 1)
        local next_point = data.path[1]

        if (point) then

            data.x, data.y = point.x, point.y

            if next_point then
                data.direction = tool.calculate_direction(data.x, data.y, next_point.x, next_point.y)
            end

        end

        -- the goal is reached
        if (#data.path == 0) then

            ooze.append(data.name .. " moved complete")
            data.path = nil
            data.action = "idle"

            -- notify the moved callback
            event.actor_moved(data.name, data.clickedX, data.clickedY)

        end

        return true

    end

end

--- Get an actor.
-- Find an actor by name.
--
-- @tparam string actor_name
-- The name of the actor
--
-- @return the @{actor_data} or nil if not found.
function actor.get (actor_name)

    for _, whom in ipairs(actor.list) do
        if whom.name == actor_name then
            return whom
        end
    end

end

--- Remove an actor.
-- Removes an actor by name
--
-- @tparam string actor_name
-- The name of the actor to remove.
function actor.remove (actor_name)

    for i, whom in ipairs(actor.list) do
        if whom.name == actor_name then
            table.remove(actor.list, i)
            return true
        end
    end

end

--- Draw actors on screen.
--
-- @local
function actor.draw ()

    for _, whom in ipairs(actor.list) do
        if whom.sprite then

            if whom.sprite.quad and whom.sprite.image then

                -- drawable with a quad
                love.graphics.draw(
                    whom.sprite.image,
                    whom.sprite.quad,
                    whom.drawX + whom.sprite.x,
                    whom.drawY + whom.sprite.y,
                    whom.sprite.r,
                    whom.sprite.sx,
                    whom.sprite.sy,
                    whom.sprite.ox,
                    whom.sprite.oy)

            elseif whom.sprite.image then

                -- drawable without a quad
                love.graphics.draw(
                    whom.sprite.image,
                    whom.drawX + whom.sprite.x,
                    whom.drawY + whom.sprite.y,
                    whom.sprite.r,
                    whom.sprite.sx,
                    whom.sprite.sy,
                    whom.sprite.ox,
                    whom.sprite.oy)

            end

        elseif whom.islayer then
            love.graphics.draw(whom.image, 0, 0)
        end
    end

end

--- Move an actor.
-- Uses path finding when a walkable floor is set, otherwise
-- if no floor is set an actor can walk anywhere.
--
-- @tparam string actor_name
-- Name of the actor to move.
--
-- @tparam int x
-- X-position to move to.
--
-- @tparam int y
-- Y-position to move to.
--
-- @see floor.set
function actor.move (actor_name, x, y)

    x, y = tool.scale_point(x, y)

    -- intercept chaining
    if chain.capture then
        ooze.append(string.format("chaining %s move", actor_name))
        chain.add(
            actor.move,
            {actor_name, x, y},
            -- expires when actor path is empty
            function (_name)
                local _actor = actor.get(_name)
                if not _actor or not _actor.path then
                    return true
                end
            end
            )
        return
    end

    -- test if the actor is on the stage
    local whom = actor.get(actor_name)

    if (whom == nil) then
        ooze.append("No actor named " .. actor_name)
        return
    end

    local start = { x = whom.x, y = whom.y }
    local goal = { x = x, y = y }

    -- If the goal is on a solid block find the nearest open point
    if floor.hasMap() then
        if not floor.isWalkable(goal.x, goal.y) then
            goal = floor.nearest_walkable_point(goal)
        end
    end

    local useCache = false
    local width, height = floor.size()

    local route

    if floor.hasMap() then
        route = path.find(width, height, start, goal, floor.isWalkable, useCache)
    else
        -- no floor is loaded, so move in a straight line
        route = floor.bresenham(start, goal)
    end

    if route then
        whom.clickedX = x
        whom.clickedY = y
        whom.path = route
        whom.action = "walk"
        ooze.append("move " .. actor_name .. " to " .. x .. " : " .. y)
    else
        ooze.append("no actor path found")
    end

end

--- Turn an actor.
-- Turn to face a cardinal direction, north south east or west.
--
-- @tparam string actor_name
-- The actor to turn.
--
-- @tparam string direction
-- A cardinal direction: north, south, east or west.
function actor.turn (actor_name, direction)

    -- intercept chaining
    if chain.capture then
        ooze.append(string.format("chaining %s turn %s", actor_name, direction))
        chain.add(actor.turn, {actor_name, direction})
        return
    end

    local whom = actor.get(actor_name)

    if (whom) then
        whom.direction = direction
    end

end

--- Move an actor.
-- Moves towards another actor, as close as possible as
-- the walkable floor allows.
--
-- @tparam string actor_name
-- Name of the actor to move.
--
-- @tparam string target_name
-- Name of the actor to move towards.
function actor.move_to (actor_name, target_name)

    local whom = actor.get(target_name)

    if (whom) then
        actor.move(actor_name, whom.x, whom.y)
    else
        ooze.append("no actor named " .. target_name)
    end

end

function actor.pause (actor_name)
    local _actor = actor.get(actor_name)
    if _actor.path then
        _actor.movement_paused = true
    end
end

function actor.resume (actor_name)
    local _actor = actor.get(actor_name)
    if _actor.movement_paused then
        _actor.movement_paused = false
    end
end

--- Stop and actor.
-- Stop an actor from moving along their movement path.
--
-- @tparam string actor_name
-- Name of the actor.
function actor.stop (actor_name)

    local whom = actor.get(actor_name)

    if whom then
        whom.path = nil
    end

end

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--  _                _                                   _
-- | |__   __ _  ___| | ____ _ _ __ ___  _   _ _ __   __| |___
-- | '_ \ / _` |/ __| |/ / _` | '__/ _ \| | | | '_ \ / _` / __|
-- | |_) | (_| | (__|   < (_| | | | (_) | |_| | | | | (_| \__ \
-- |_.__/ \__,_|\___|_|\_\__, |_|  \___/ \__,_|_| |_|\__,_|___/
--                    |___/

--- Add a background.
-- Called multiple times, is how one creates animated backgrounds,
-- with a delay (in seconds), which when expired,
-- cycles to the next background.
--
-- The image size of each one, has to match the background before it.
-- If no delay is given, the background will draw forever.
--
-- @tparam string path
-- The image path.
--
-- @tparam[opt] int seconds
-- Seconds to display before cycling the background.
function background.add (path, seconds)

    local image = love.graphics.newImage(path)
    local width, height = image:getDimensions()

    -- set the background size
    if not background.width or not background.height then
        background.width, background.height = width, height
    end

    -- ensure consistent background sizes
    assert(width == background.width, "backgrounds must have the same size")
    assert(height == background.height, "backgrounds must have the same size")

    table.insert(background.list, {
        image = image,
        seconds = seconds
    })

end

--- Clear all backgrounds.
-- This gets called by @{slime.clear}
--
-- @local
function background.clear ()

    -- stores the list of backgrounds
    background.list = { }

    -- the index of the current background
    background.index = 1

    -- background size
    background.width, background.height = nil, nil

end

--- Draw the background.
--
-- @local
function background.draw ()

    local data = background.list[background.index]

    if (data) then
        love.graphics.draw(data.image, 0, 0)
    end

end

--- Update backgrounds.
-- Tracks background delays and performs their rotation.
--
-- @tparam int dt
-- Delta time since the last update.
--
-- @local
function background.update (dt)

    -- skip background rotation if there is no more than one
    if not background.list[2] then
        return
    end

    local index = background.index
    local current = background.list[index]
    local timer = background.timer

    if (timer == nil) then
        -- start a new timer
        index = 1
        timer = current.seconds
    else
        timer = timer - dt
        -- this timer has expired
        if (timer < 0) then
            -- move to the next background
            index = (index == #background.list) and 1 or index + 1
            if (background.list[index]) then
                timer = background.list[index].seconds
            end
        end
    end

    background.index = index
    background.timer = timer

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--  _
-- | |__   __ _  __ _ ___
-- | '_ \ / _` |/ _` / __|
-- | |_) | (_| | (_| \__ \
-- |_.__/ \__,_|\__, |___/
--              |___/

--- Clear all bags.
-- This gets called by @{slime.clear}
--
-- @local
function bag.clear ()

    bag.contents = { }

end

--- Add a thing to a bag.
--
-- @tparam string name
-- Name of the bag to store in.
--
-- @tparam table object
-- TODO: this bag object thing is a bit under-developed.
-- define it's structure.
function bag.add (name, object)

    -- load the image
    if type(object.image) == "string" then
        object.image = love.graphics.newImage(object.image)
    end

    assert(object.name, "bag item requires a name")

    assert(not bag.contains(name, object.name),
        string.format("bag %q already contains %q", name, object.name))

    -- create it
    bag.contents[name] = bag.contents[name] or { }

    -- add the object to it
    table.insert(bag.contents[name], object)

    -- notify the callback
    event.bag_updated(name, object.name)

    ooze.append(string.format("Added %s to bag", object.name))

end

--- Remove a thing from a bag.
--
-- @tparam string bag_name
-- Name of the bag.
--
-- @tparam string thing_name
-- Name of the thing to remove.
function bag.remove (bag_name, thing_name)

    local inv = bag.contents[bag_name] or { }

    for i, item in pairs(inv) do
        if (item.name == thing_name) then
            table.remove(inv, i)
            ooze.append(string.format("Removed %s", thing_name))
            event.bag_updated(bag_name, thing_name)
        end
    end

end

--- Test if a bag has a thing.
--
-- @tparam string bag_name
-- Name of bag to search.
--
-- @tparam string thing_name
-- Name of thing to find.
function bag.contains (bag_name, thing_name)

    local inv = bag.contents[bag_name] or { }

    for _, v in pairs(inv) do
        if v.name == thing_name then
            return true
        end
    end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                 _
--   ___ __ _  ___| |__   ___
--  / __/ _` |/ __| '_ \ / _ \
-- | (_| (_| | (__| | | |  __/
--  \___\__,_|\___|_| |_|\___|
--

--- Initialize image cache.
-- Clears cached image references.
--
-- @local
function cache.init ()

    -- Calling a table like a function
    setmetatable(cache, {
        __call = function (cache, ...)
            return cache.interface(...)
        end
    })

    cache.store = { }

end

--- Save to cache and return a copy.
--
-- @tparam string path
-- Path to the image to load.
--
-- @local
function cache.interface (path)

    -- cache tileset image to save loading duplicate images
    local image = cache.store[path]

    if not image then
        image = love.graphics.newImage(path)
        cache.store[path] = image
    end

    return image

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--       _           _
--   ___| |__   __ _(_)_ __  ___
--  / __| '_ \ / _` | | '_ \/ __|
-- | (__| | | | (_| | | | | \__ \
--  \___|_| |_|\__,_|_|_| |_|___/

-- Provides ways to chain actions to run in sequence

--- Clear all chained actions.
-- Call this to start or append an actor action to build a chain of events.
-- This gets called by @{slime.clear}
--
-- @local
function chain.clear (name)

    if name then
        chain.list[name] = nil
    else
        -- clear all
        chain.list = { }
    end

    chain.capture = nil

end

--- Begins chain capturing mode.
-- While in this mode, the next call to a slime function
-- will be added to the chain action list instead of executing
-- immediately.
--
-- @tparam[opt] string name
-- Specifying a name allows creating multiple, concurrent chains.
--
-- @tparam[opt] function userFunction
-- User provided function to add to the chain.
--
-- @return The slime instance
function chain.begin (name)

    -- use a default chain name if none is provided
    name = name or "default"

    -- fetch the chain from storage
    local _current = chain.list[name]

    -- create a new chain instead
    if not _current then
        _current = {name=name, actions={}}
        chain.list[name] = _current
        ooze.append(string.format("created chain %q", name))
    end

    chain.capture = _current

end

--- Document this.
function chain.done ()

    chain.capture = nil

end

--- Add an action to the capturing chain.
--
-- @tparam function func
-- The function to call
--
-- @tparam table parameters
-- The function parameters
--
-- @tparam[opt] function expired
-- Function that returns true when the action
-- has expired, which does so instantly if this parameter
-- is not given.
--
-- @local
function chain.add (func, parameters, expired)

    if type(expired) ~= "function" then
        expired = function()
            -- expires instantly
            return true
        end
    end

    local command = {
        -- the function to be called
        func = func,
        -- parameters to pass the function
        parameters = parameters,
        -- a function that tests if the command has expired
        expired = expired,
        -- a flag to ensure the function is only called once
        ran = false
    }

    -- queue this command in the capturing chain
    table.insert(chain.capture.actions, command)

    -- release this capture
    chain.capture = nil

end

--- Process chains.
--
-- @tparam int dt
-- Delta time since the last update
--
-- @local
function chain.update ()

    -- for each chain
    for key, chain in pairs(chain.list) do

        -- the next command in this chain
        local command = chain.actions[1]

        if command then

            -- run the action once only
            if not command.ran then
                --ooze.append (string.format("running chain command"))
                command.ran = true
                command.func(unpack(command.parameters))
            end

            -- remove expired actions from this chain
            if command.expired(unpack(command.parameters)) then
                --ooze.append (string.format("chain action expired"))
                table.remove(chain.actions, 1)
            end

        end

    end

end

--- Pause the chain.
--
-- @tparam int seconds
-- Seconds to wait before the next action is run.
function chain.wait (seconds)

    if chain.capture then
        --ooze.append (string.format("waiting %ds", seconds))
        chain.add(
            function() end,
            {seconds},
            function (timeout)
                timeout = timeout - last_dt
                return timeout < 0
            end)
    end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

--- Sprite info.
-- Contains data to draw a sprite.
--
-- @table sprite_data
--
-- @tfield Image image
-- The sprite image, or the spritesheet that contains the sprite.
--
-- @tfield Quad quad
-- The quad of the sprite within the spritesheet. Can be given as nil if
-- the image is not a spritesheet.
--
-- @tfield number x
-- The x offset of the sprite relative to the actor's position.
--
-- @tfield number y
-- The y offset of the sprite relative to the actor's position.
--
-- @tfield number r
-- Draw orientation in radians.
--
-- @tfield number sx
-- Scale factor on the x-axiz.
--
-- @tfield number sy
-- Scale factor on the y-axiz.
--
-- @tfield number ox
-- Origin offset on the x-axiz.
--
-- @tfield number oy
-- Origin offset on the y-axiz.



--- Actor animation looped event.
-- TODO REVIEW IF NEEDED
--
-- @tparam actor_data data
-- The actor being interacted with
--
-- @tparam string key
-- The animation key that looped
--
-- @tparam int counter
-- The number of times the animation has looped
function event.animation_looped (data, key, counter)

end

--- Bag contents changed event.
-- This is fired when something is added or removed from a bag.
--
-- @tparam string bag
-- The name of the bag that changed
function event.bag_updated (bag)

end

--- Draw speech override.
-- Override this function to handle drawing spoken text.
--
-- @tparam string actor_name
-- The actor who is talking.
--
-- @tparam string words
-- The words to print on screen.
function event.draw_speech (actor_name, words)

    local y = 0
    local w = love.graphics.getWidth() / draw_scale
    local _actor = actor.get(actor_name)

    love.graphics.setFont(setting["speech font"])

    -- Black shadow
    love.graphics.setColor({0, 0, 0, 1})
    love.graphics.printf(words, 1, y + 1, w, "center")

    love.graphics.setColor(_actor.speechcolor)
    love.graphics.printf(words, 0, y, w, "center")

end

--- Draw cursor override.
-- Override this function to handle drawing the cursor.
--
-- @tparam cursor_data data
-- The cursor that is to be drawn.
--
-- @tparam int x
-- @tparam int y
function event.draw_cursor (data, x, y)

    if data.quad then
        love.graphics.draw(data.image, data.quad, x, y)
    else
        love.graphics.draw(data.image, x, y)
    end

end

--- Request sprite drawable event.
-- Fired when requesting the drawable for an animated sprite.
--
-- @tparam int dt
-- Delta time since the last update.
-- This should be used to forward animations.
--
-- @tparam actor_data data
-- The actor whom the sprite request is for. The actor.action, actor.direction
-- properties can be accessed to determine the sprite to return.
--
-- @return @{sprite_data}
function event.request_sprite (actor_name, action, direction, dt)

end

--- Callback when a mouse interaction occurs.
--
-- @tparam string event
-- The name of the cursor
--
-- @tparam actor_data data
-- The actor being interacted with
function event.interact (event, data)

end

--- Actor finished moving callback.
--
-- @tparam string actor_name
-- The actor that moved
--
-- @tparam int clickedX
-- The point given to the original @{actor.move} method.
-- This may be different than the actor's location, if for example
-- the floor does not allow standing on the point, the actor moves
-- as close as possible to the point.
-- This can be used to call @{interact} after an actor has moved.
--
-- @tparam int clickedY
--
function event.actor_moved (actor_name, clickedX, clickedY)

end

--- Actor speaking callback.
--
-- @tparam string actor_name
-- The talking actor
function event.speech_started (actor_name)

    actor.pause(actor_name)

end

--- Actor has stopped talking.
--
-- @tparam string actor_name
-- The actor whom has finished talking.
function event.speech_ended (actor_name)

    actor.resume(actor_name)

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--   ___ _   _ _ __ ___  ___  _ __
--  / __| | | | '__/ __|/ _ \| '__|
-- | (__| |_| | |  \__ \ (_) | |
--  \___|\__,_|_|  |___/\___/|_|
--

--- Custom cursor data
--
-- @table cursor_data
--
-- @tfield string name
-- Name of the cursor. This gets passed back to the
-- @{event.interact} callback event.
--
-- @tfield image image
-- The cursor image.
--
-- @tfield[opt] quad quad
-- If image is a spritesheet, then quad defines the position
-- in of the cursor in the image.
--
-- @tfield[opt] table hotspot
-- The {x, y} point on the cursor that identifies as the click point.
-- Defaults to the top-left corner if not specified.


--- Clear the custom cursor.
-- This gets called by @{slime.clear}
--
-- @local
function cursor.clear ()

    cursor.current = nil

end

--- Draw the cursor.
--
-- @local
function cursor.draw ()

    if cursor.current and cursor.x then
        event.draw_cursor(cursor.current, cursor.x, cursor.y)
    end

end

--- Get the current cursor name.
--
-- @local
function cursor.name ()

    if cursor.current then
        return cursor.current.name
    else
        return "interact"
    end

end

--- Set a custom cursor.
--
-- @tparam cursor_data data
-- The cursor data.
function cursor.set (data)

    assert(data.name, "cursor needs a name")
    assert(data.image, "cursor needs an image")

    -- default hotspot to top-left corner
    data.hotspot = data.hotspot or {x = 0, y = 0}

    cursor.current = data

    ooze.append(string.format("set cursor %q", data.name))

end

--- Update the cursor position.
--
-- @tparam int x
-- @tparam int y
function cursor.update (x, y)

    x, y = tool.scale_point(x, y)

    -- adjust draw position to center around the hotspot
    if cursor.current then
        cursor.x = x - cursor.current.hotspot.x
        cursor.y = y - cursor.current.hotspot.y
    else
        cursor.x, cursor.y = x, y
    end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--   __ _
--  / _| | ___   ___  _ __ ___
-- | |_| |/ _ \ / _ \| '__/ __|
-- |  _| | (_) | (_) | |  \__ \
-- |_| |_|\___/ \___/|_|  |___/


--- Clear walkable floors.
-- This gets called by @{slime.clear}
--
-- @local
function floor.clear ()

    floor.walkableMap = nil

end

--- Test if a walkable map is loaded.
--
-- @local
function floor.hasMap ()

    return floor.walkableMap ~= nil

end

--- Set a walkable floor.
-- The floor mask defines where actors can walk.
-- Any non-black pixel is walkable.
--
-- @tparam string filename
-- The image mask defining walkable areas.
function floor.set (filename)

    -- intercept chaining
    if chain.capture then
        chain.add(floor.set, {filename})
        return
    end

    floor.convert(filename)

end

--- Convert a walkable floor mask.
-- Prepares the mask for use in path finding.
--
-- @tparam string filename
-- The floor map image filename
--
-- @local
function floor.convert (filename)

    -- Converts a walkable image mask into map points.
    local mask = love.image.newImageData(filename)
    local w = mask:getWidth()
    local h = mask:getHeight()

    -- store the size
    floor.width, floor.height = w, h

    local row = nil
    local r = nil
    local g = nil
    local b = nil
    local a = nil
    floor.walkableMap = { }

    -- builds a 2D array of the image size, each index references
    -- a pixel in the mask
    for ih = 1, h - 1 do
        row = { }
        for iw = 1, w - 1 do
            r, g, b, a = mask:getPixel(iw, ih)
            if (r + g + b == 0) then
                -- not walkable
                table.insert(row, false)
            else
                -- walkable
                table.insert(row, true)
            end
        end
        table.insert(floor.walkableMap, row)
    end

end

--- Test if a point is walkable.
-- This is the callback used by path finding.
--
-- @tparam int x
-- X-position to test.
--
-- @tparam int y
-- Y-position to test.
--
-- @return true if the position is open to walk
--
-- @local
function floor.isWalkable (x, y)

    if floor.hasMap() then
        -- clamp to floor boundary
        x = tool.clamp(x, 1, floor.width - 1)
        y = tool.clamp(y, 1, floor.height - 1)
        return floor.walkableMap[y][x]
    else
        -- no floor is always walkable
        return true
    end

end

--- Get the size of the floor.
--
-- @local
function floor.size ()

    if floor.walkableMap then
        return floor.width, floor.height
    else
        -- without a floor map, we return the background size
        return background.width, background.height
    end

end

--- Get the points of a line.
-- http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua
--
-- @tparam table start
-- {x, y} of the line start.
--
-- @tparam table goal
-- {x, y} of the line end.
--
-- @return table of list of points from start to goal.
--
-- @local
function floor.bresenham (start, goal)

  local linepath = { }
  local x1, y1, x2, y2 = start.x, start.y, goal.x, goal.y
  delta_x = x2 - x1
  ix = delta_x > 0 and 1 or -1
  delta_x = 2 * math.abs(delta_x)

  delta_y = y2 - y1
  iy = delta_y > 0 and 1 or -1
  delta_y = 2 * math.abs(delta_y)

  table.insert(linepath, {["x"] = x1, ["y"] = y1})

  if delta_x >= delta_y then
    error = delta_y - delta_x / 2

    while x1 ~= x2 do
      if (error >= 0) and ((error ~= 0) or (ix > 0)) then
        error = error - delta_x
        y1 = y1 + iy
      end

      error = error + delta_y
      x1 = x1 + ix

      table.insert(linepath, {["x"] = x1, ["y"] = y1})
    end
  else
    error = delta_x - delta_y / 2

    while y1 ~= y2 do
      if (error >= 0) and ((error ~= 0) or (iy > 0)) then
        error = error - delta_y
        x1 = x1 + ix
      end

      error = error + delta_x
      y1 = y1 + iy

      table.insert(linepath, {["x"] = x1, ["y"] = y1})
    end
  end

  return linepath

end

--- Find the nearest open point.
-- Use the bresenham line algorithm to project four lines from the goal:
-- North, south, East and West, and find the first open point on each line.
-- We then choose the point with the shortest distance from the goal.
--
-- @tparam table point
-- {x, y} of the point to reach.
--
-- @local
function floor.nearest_walkable_point (point)

    -- Get the dimensions of the walkable floor map.
    local width, height = floor.size()

    -- Define the cardinal direction to test against relative to the point.
    local directions = {
        { ["x"] = point.x, ["y"] = height },    -- S
        { ["x"] = 1, ["y"] = point.y },         -- W
        { ["x"] = point.x, ["y"] = 1 },         -- N
        { ["x"] = width, ["y"] = point.y }      -- E
        }

    -- Stores the four directional points found and their distance.
    local foundPoints = { }

    for idirection, direction in pairs(directions) do
        local goal = point
        local walkTheLine = floor.bresenham(direction, goal)
        local continueSearch = true
        while (continueSearch) do
            if (#walkTheLine == 0) then
                continueSearch = false
            else
                goal = table.remove(walkTheLine)
                continueSearch = not floor.isWalkable(goal.x, goal.y)
            end
        end
        -- math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
        local distance = math.sqrt((goal.x - point.x)^2 + (goal.y - point.y)^2 )
        table.insert(foundPoints, { ["goal"] = goal, ["distance"] = distance })
    end

    -- Sort the results with shortest distance first
    table.sort(foundPoints, function (a, b) return a.distance < b.distance end )

    -- Return the winning point
    return foundPoints[1].goal

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--    _           _                   _
--   | |__   ___ | |_ ___ _ __   ___ | |_ ___
--   | '_ \ / _ \| __/ __| '_ \ / _ \| __/ __|
--   | | | | (_) | |_\__ \ |_) | (_) | |_\__ \
--   |_| |_|\___/ \__|___/ .__/ \___/ \__|___/
--                       |_|

--- Clear hotspots.
-- This gets called by @{slime.clear}
--
-- @local
function hotspot.clear ()

    hotspot.list = { }

end

--- Add a hotspot.
--
-- @tparam string name
-- Name of the hotspot.
--
-- @tparam int x
-- @tparam int y
-- @tparam int w
-- @tparam int h
function hotspot.add (name, x, y, w, h)

    assert(type(name) == "string", "hotspot.add missing name argument")
    assert(type(x) == "number", "hotspot.add missing x argument")
    assert(type(y) == "number", "hotspot.add missing y argument")
    assert(type(w) == "number", "hotspot.add missing w argument")
    assert(type(h) == "number", "hotspot.add missing h argument")

    local point = {
        ["name"] = name,
        ["x"] = x,
        ["y"] = y,
        ["w"] = w,
        ["h"] = h
    }

    table.insert(hotspot.list, point)
    return point

end

--- TODO Document
function hotspot.get (a, b)

    if type(a) == "string" then

        for _, item in pairs(hotspot.list) do
            if item.name == a then
                return item
            end
        end

    elseif type(a) == "number" and type(b) == "number" then

        for _, item in pairs(hotspot.list) do
            if (a >= item.x and a <= item.x + item.w) and
                (b >= item.y and b <= item.y + item.h) then
                return item
            end
        end

    else
        error("hotspot.get called with invalid arguments")
    end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--    _
--   | | __ _ _   _  ___ _ __ ___
--   | |/ _` | | | |/ _ \ '__/ __|
--   | | (_| | |_| |  __/ |  \__ \
--   |_|\__,_|\__, |\___|_|  |___/
--            |___/
--
-- Layers define areas of the background that actors can walk behind.

--- Add a walk-behind layer.
-- The layer mask is used to cut out a piece of the background, and
-- drawn over other actors to create a walk-behind layer.
--
-- @tparam string background
-- Filename of the background to cut out.
--
-- @tparam string mask
-- Filename of the mask.
--
-- @tparam int baseline
-- The Y-position on the mask that defines the behind/in-front point.
function layer.add (background, mask, baseline)

    assert(background ~= nil, "Missing parameter background")
    assert(mask ~= nil, "Missing parameter to mask")
    assert(baseline ~= nil, "Missing parameter to baseline")

    -- TODO: allow empty baseline, which is then calculated as the
    --      largest Y point in the mask.

    local newLayer = {
        ["image"] = layer.image_from_mask(background, mask),
        ["baseline"] = baseline,
        islayer = true
        }

    -- layers are merged with actors so that we can perform
    -- efficient sorting, enabling drawing of actors behind layers.
    table.insert(actor.list, newLayer)

    actor.sort()

end

--- Cut a shape out of an image.
-- All corresponding black pixels from the mask will cut and discard
-- pixels (they become transparent), and only non-black mask pixels
-- preserve the matching source pixels.
--
-- @tparam string source
-- Source image filename.
--
-- @tparam string mask
-- Mask image filename.
--
-- @return the cut out image.
--
-- @local
function layer.image_from_mask (source, mask)

    -- Returns a copy of the source image with transparent pixels where
    -- the positional pixels in the mask are black.

    local sourceData = love.image.newImageData(source)
    local maskData = love.image.newImageData(mask)

    local sourceW, sourceH = sourceData:getDimensions()
    layerData = love.image.newImageData(sourceW, sourceH)

    -- copy the orignal
    layerData:paste(sourceData, 0, 0, 0, 0, sourceW, sourceH)

    -- map black mask pixels to transparent layer pixels
    layerData:mapPixel( function (x, y, r, g, b, a)
                            r2, g2, b2, a2 = maskData:getPixel(x, y)
                            if (r2 + g2 + b2 == 0) then
                                return 0, 0, 0, 0
                            else
                                return r, g, b, a
                            end
                        end)

    return love.graphics.newImage(layerData)

end



-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--   ___   ___ _______
--  / _ \ / _ \_  / _ \
-- | (_) | (_) / /  __/
--  \___/ \___/___\___|
--
-- Provides helpful debug information while building your game.

-- components inside ooze:

-- Logs events
ooze.logger = { }

-- Outlines stage elements
ooze.outliner = { }

-- Handles the trigger area
ooze.trigger = { }

-- Handles viewing animated sprites
ooze.spriteview = { }

-- Provides a reusable menu system
ooze.menu = { }


--- Clear and reset debug variables.
function ooze.clear ()

    ooze.trigger.init()
    ooze.logger.init()
    ooze.outliner.init()
    ooze.spriteview.init()     -- incomplete and not listed in available states
    ooze.menu.init()

    -- list available ooze states
    ooze.states = { nil, ooze.logger, ooze.outliner }
    ooze.index = 1

    ooze.load_menu()

end


--- Append to the log.
--
-- @local
function ooze.append (text)

    ooze.logger.append(text)

end


--- Draw the debug overlay.
function ooze.draw (scale)

    -- drawing enabled ooze updates
    ooze.enabled = true

    ooze.trigger.draw(scale)
    ooze.menu.draw()

    if ooze.states[ooze.index] then
        ooze.states[ooze.index].draw(scale)
    end

end


function ooze.mousemoved (x, y, dx, dy, istouch)

    ooze.menu.mousemoved(x, y, dx, dy, istouch)

end

function ooze.mousepressed (x, y, button, istouch, presses)

    -- test if the trigger zone was clicked
    if ooze.trigger.mousepressed(x, y) then

        -- move to the next state
        ooze.index = ooze.index + 1

        -- wrap states
        if ooze.index > #ooze.states then
            ooze.index = 1
        end

        -- load new menu options
        ooze.load_menu()

        return true
    end

    -- pass this event through to the current state
    local state = ooze.states[ooze.index]
    if state and state.mousepressed then
        local handled = state.mousepressed(x, y, button, istouch, presses)
        -- handled events are eaten up
        if handled == true then
            return handled
        end
    end

end


--- Loads the menu options for the state.
--
-- @local
function ooze.load_menu ()

    local state = ooze.states[ooze.index]
    if state and state.build_menu then
        ooze.menu.set(state.build_menu())
    else
        ooze.menu.clear()
    end

end

function ooze.update (dt)

    ooze.menu.update(dt)

end

function ooze.wheelmoved (x, y)

    ooze.menu.wheelmoved(x, y)

end


--                       _
--   ___   ___ _______  | | ___   __ _  __ _  ___ _ __
--  / _ \ / _ \_  / _ \ | |/ _ \ / _` |/ _` |/ _ \ '__|
-- | (_) | (_) / /  __/ | | (_) | (_| | (_| |  __/ |
--  \___/ \___/___\___| |_|\___/ \__, |\__, |\___|_|
--                               |___/ |___/
--

function ooze.logger.init ()

    ooze.logger.log = { }

    -- debug border
    ooze.logger.padding = 10
    ooze.logger.width, ooze.logger.height = love.graphics.getDimensions()
    ooze.logger.width = ooze.logger.width - (ooze.logger.padding * 2)
    ooze.logger.height = ooze.logger.height - (ooze.logger.padding * 2)

    -- the font for printing debug texts
    ooze.logger.font = love.graphics.newFont(12)
    ooze.logger.color = {0, 1, 0}

end

function ooze.logger.append (text)

    table.insert(ooze.logger.log, text)

    -- cull the log
    if (#ooze.logger.log > 20) then
        table.remove(ooze.logger.log, 1)
    end

end

function ooze.logger.draw (scale)

    love.graphics.setColor(ooze.logger.color)
    love.graphics.setFont(ooze.logger.font)

    -- print fps
    love.graphics.printf(
        string.format("%d fps", love.timer.getFPS()),
        ooze.logger.padding, ooze.logger.padding, ooze.logger.width, "center")

    -- print background info
    if (background.index and background.timer) then
        love.graphics.printf(
            string.format("background #%d showing for %.1f",
            background.index, background.timer),
            ooze.logger.padding, ooze.logger.padding, ooze.logger.width, "right")
    end

    -- print log
    for i, n in ipairs(ooze.logger.log) do
        love.graphics.setColor({0, 0, 0})
        love.graphics.print(n, ooze.logger.padding + 1, ooze.logger.padding + 1 + (16 * i))
        love.graphics.setColor(ooze.logger.color)
        love.graphics.print(n, ooze.logger.padding, ooze.logger.padding + (16 * i))
    end

end


--                                   _   _ _
--   ___   ___ _______    ___  _   _| |_| (_)_ __   ___ _ __
--  / _ \ / _ \_  / _ \  / _ \| | | | __| | | '_ \ / _ \ '__|
-- | (_) | (_) / /  __/ | (_) | |_| | |_| | | | | |  __/ |
--  \___/ \___/___\___|  \___/ \__,_|\__|_|_|_| |_|\___|_|
--

function ooze.outliner.init ()

    ooze.outliner.width, ooze.outliner.height = love.graphics.getDimensions()

    ooze.outliner.hotspotColor = {1, 1, 0, 0.8}  -- yellow
    ooze.outliner.actorColor = {0, 0, 1, 0.8}    -- blue

    -- list of colors we can cycle through so each layer has it's own.
    ooze.outliner.layerColors = {
        {1, 0, 0, 0.5},     -- red
        {0, 1, 0, 0.5},     -- green
        {0.5, 0, 1, 0.5},   -- purple
        {1, 0, 1, 0.5},     -- magenta
    }

end

function ooze.outliner.draw (scale)

    -- draw object outlines to scale
    love.graphics.push()
    love.graphics.scale(scale)

    -- outline hotspots
    love.graphics.setColor(ooze.outliner.hotspotColor)
    for ihotspot, hotspot in pairs(hotspot.list) do
        love.graphics.rectangle("line", hotspot.x, hotspot.y, hotspot.w, hotspot.h)
    end

    -- track layer counter
    local layerCounter = 1

    -- outline actors
    for _, actor in ipairs(actor.list) do
        if actor.isactor then
            love.graphics.setColor(ooze.outliner.actorColor)
            -- TODO calculate draw position in actor:update
            love.graphics.rectangle("line", actor.drawX, actor.drawY, actor.width, actor.height)
            love.graphics.circle("line", actor.x, actor.y, 1, 6)
        elseif actor.islayer then
            -- draw baselines for layers
            local layerColorIndex = math.max(1, layerCounter % (#ooze.outliner.layerColors + 1))
            love.graphics.setColor(ooze.outliner.layerColors[layerColorIndex])
            love.graphics.draw(actor.image)
            love.graphics.line(0, actor.baseline, ooze.outliner.width, actor.baseline)
            layerCounter = layerCounter + 1
        end
    end

    love.graphics.pop()

end

function ooze.outliner.build_menu ()

    return {

    }

end


--                       _        _
--   ___   ___ _______  | |_ _ __(_) __ _  __ _  ___ _ __
--  / _ \ / _ \_  / _ \ | __| '__| |/ _` |/ _` |/ _ \ '__|
-- | (_) | (_) / /  __/ | |_| |  | | (_| | (_| |  __/ |
--  \___/ \___/___\___|  \__|_|  |_|\__, |\__, |\___|_|
--                                  |___/ |___/

function ooze.trigger.init ()

    ooze.trigger.width, ooze.trigger.height = love.graphics.getDimensions()
    ooze.trigger.borderColor = {0, 1, 0}
    ooze.trigger.triggerColor = {0, 1, 0, 0.42}

    -- radius of the trigger area in the screen corner
    ooze.trigger.triggerSize = 20

    ooze.trigger.triggerX = 0
    ooze.trigger.triggerY = ooze.trigger.height

end

function ooze.trigger.draw (scale)

    local self = ooze.trigger
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", 0, 0, self.width, self.height)
    love.graphics.setColor(self.triggerColor)
    love.graphics.circle("fill", self.triggerX, self.triggerY, self.triggerSize)

end

function ooze.trigger.mousepressed (x, y, button, istouch, presses)

    -- check distance to the trigger zone.
    local dist = tool.distance(x, y, ooze.trigger.triggerX, ooze.trigger.triggerY)
    return dist < ooze.trigger.triggerSize

end


--                                      _ _               _
--   ___   ___ _______   ___ _ __  _ __(_) |_ ___  __   _(_) _____      __
--  / _ \ / _ \_  / _ \ / __| '_ \| '__| | __/ _ \ \ \ / / |/ _ \ \ /\ / /
-- | (_) | (_) / /  __/ \__ \ |_) | |  | | ||  __/  \ V /| |  __/\ V  V /
--  \___/ \___/___\___| |___/ .__/|_|  |_|\__\___|   \_/ |_|\___| \_/\_/
--                          |_|

function ooze.spriteview.init ()

end

function ooze.spriteview.draw (scale)
    love.graphics.rectangle("fill", 0, 0, 100, 100)
end

function ooze.spriteview.mousepressed(x, y, button, istouch, presses)
    return true
end




--   ___   ___ _______   _ __ ___   ___ _ __  _   _
--  / _ \ / _ \_  / _ \ | '_ ` _ \ / _ \ '_ \| | | |
-- | (_) | (_) / /  __/ | | | | | |  __/ | | | |_| |
--  \___/ \___/___\___| |_| |_| |_|\___|_| |_|\__,_|

--- Initialize the ooze menu.
function ooze.menu.init (options)

    -- the radius of the wheel
    ooze.menu.r = 100

    -- seconds to wait before fading out
    ooze.menu.displayFor = 2

    -- angle facing north
    ooze.menu.north = 270

    ooze.menu.screenWidth, ooze.menu.screenHeight = love.graphics.getDimensions()

    -- start invisible
    ooze.menu.opacity = { dt = ooze.menu.displayFor, amount = 0 }

end

--- Clear the ooze menu.
function ooze.menu.clear ()

    ooze.menu.modes = nil

end

--- Set the ooze menu options.
-- @tparam table options
function ooze.menu.set (options)

    -- the menu options
    ooze.menu.modes = {
        "add",
        "alter",
        "delete",
        "name",
        "copy",
        "paste",
        "grid"
    }

    -- angle step size divided evenly between all modes
    ooze.menu.step = math.floor(360 / #ooze.menu.modes)

    -- set the first mode
    ooze.menu.mode = ooze.menu.modes[1]

    -- precalculate starting positions
    ooze.menu.points = { }
    for n, mode in ipairs(ooze.menu.modes) do
        -- mind we store point angles in degrees!
        local factor = n - 1
        local itemAngle = ooze.menu.north + (factor * ooze.menu.step)
        ooze.menu.points[mode] = {
            goal = itemAngle,
            actual = itemAngle,
            dt = 1,
            scale = 1
        }
    end

    -- set invisible
    ooze.menu.opacity = { dt = ooze.menu.displayFor, amount = 0 }
    ooze.menu.x, ooze.menu.y = love.mouse.getPosition()

end

function ooze.menu.update (dt)

    if not ooze.menu.modes then
        return
    end

    -- update actual angles to match goal angles
    for key, point in pairs(ooze.menu.points) do

        point.dt = math.min(1, point.dt + dt)
        point.actual = tool.lerp(point.actual, point.goal, point.dt)

        -- adjust scale
        if key == ooze.menu.mode then
            point.scale = math.min(1, point.scale + dt)
        else
            point.scale = math.max(0.5, point.scale - dt)
        end

    end

    -- update opacity
    ooze.menu.opacity.dt = ooze.menu.opacity.dt + dt
    if ooze.menu.opacity.dt > ooze.menu.displayFor then
        -- decrease
        ooze.menu.opacity.amount = math.max(0, ooze.menu.opacity.amount - dt * 2)
    elseif ooze.menu.opacity.amount < 1 then
        -- increase
        ooze.menu.opacity.amount = math.min(1, ooze.menu.opacity.amount + dt * 2)
    end

end

function ooze.menu.draw ()

    if not ooze.menu.modes then
        return
    end

    --~ -- show the current mode as an icon always on-screen
    --~ local icon = ooze.menu.icons[ooze.menu.mode]
    --~ if icon then
        --~ love.graphics.setColor (1, 1, 1, 0.4)
        --~ love.graphics.draw (icon, 0, 0, 0, 0.5, 0.5)
    --~ end

    -- skip drawing further, since we are now invisible
    if ooze.menu.opacity.amount == 0 then
        return
    end

    -- fill background
    love.graphics.setColor({0, 0, 0, math.min(ooze.menu.opacity.amount, 0.5) })
    love.graphics.circle("fill", ooze.menu.x, ooze.menu.y, ooze.menu.r * 1.2)

    -- draw circumference
    --love.graphics.setColor (1, 1, 1, ooze.menu.opacity.amount * 0.1)
    --love.graphics.circle ("line", ooze.menu.x, ooze.menu.y, ooze.menu.r)

    -- draw each mode at the actual angle
    for key, point in pairs(ooze.menu.points) do

        -- convert the angle to radians before plotting
        local angle = math.rad(point.actual)
        local nx, ny = tool.point_on_circle(ooze.menu.x, ooze.menu.y, ooze.menu.r, angle)

        --~ -- fade the icon color into existence
        --~ local keycolor = ooze.menu.colors[key] or colors.white
        --~ local r, g, b = unpack (keycolor)
        --~ love.graphics.setColor (r, g, b, ooze.menu.opacity.amount)

        --~ -- draw the icon
        --~ if ooze.menu.icons[key] then
            --~ love.graphics.draw (ooze.menu.icons[key], nx, ny, 0, point.scale, point.scale, 32, 32)
        --~ end

        love.graphics.setColor({1, 1, 1})
        love.graphics.printf(key, nx, ny, ooze.menu.r * 1, "left")

    end

    -- print the menu mode as centered text
    --love.graphics.setFont (fonts.medium)
    love.graphics.setColor({1, 1, 1, ooze.menu.opacity.amount })
    love.graphics.printf(ooze.menu.mode, ooze.menu.x - ooze.menu.r, ooze.menu.y - 40, ooze.menu.r * 2, "center")

end

function ooze.menu.mousemoved (x, y, dx, dy, istouch)
    -- clamp the menu to the screen
    ooze.menu.x = tool.clamp(x, ooze.menu.r, ooze.menu.screenWidth - ooze.menu.r)
    ooze.menu.y = tool.clamp(y, ooze.menu.r, ooze.menu.screenHeight - ooze.menu.r)
end

function ooze.menu.mousepressed (x, y, button, istouch, presses)
    if ooze.menu.mode == "copy" then
        local dump = require("dump")
        local ser = dump.tostring(frames.db)
        love.system.setClipboardText(ser)
        print(ser)
    elseif ooze.menu.mode == "paste" then
        local contents = "return " .. love.system.getClipboardText()
        local loaded = loadstring(contents)
        if type(loaded) == "function" then
            frames.db = loaded()
        else
            print("Content is not lua string")
        end
    end
end

function ooze.menu.wheelmoved (x, y)

    -- prevent cycling on show
    if ooze.menu.opacity.amount == 0 then
        ooze.menu.opacity.dt = 1
        return
    end

    if y then
        for key, point in pairs(ooze.menu.points) do
            -- move the goal angle
            point.goal = (point.goal + ooze.menu.step * y)
            -- reset the angle movement
            point.dt = 0
            -- the distance between the goal and the north point
            -- determines the current mode, it can also vary up to
            -- 12 degrees (depending how many modes you have, ala step size)
            local diff = math.abs((point.goal % 360) - ooze.menu.north)
            if diff < 13 then
                -- store the north facing mode
                ooze.menu.mode = key
                -- store the point of reference
                --ooze.menu.point = point
            end
        end

        -- keep opacity steady while scrolling the wheel
        ooze.menu.opacity.dt = 0
    end
end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--              _   _
--  _ __   __ _| |_| |__
-- | '_ \ / _` | __| '_ \
-- | |_) | (_| | |_| | | |
-- | .__/ \__,_|\__|_| |_|
-- |_|
--

--- A 2D point.
--
-- @tparam int x
-- @tparam int y
-- @table point


--- Clear all cached paths
-- This gets called by @{slime.clear}
--
-- @local
function path.clear ()

    path.cache = nil

end

--- Gets a unique key for a start and goal point.
-- The key is used for caching paths.
--
-- @tparam point start
-- The start point.
--
-- @tparam point goal
-- The goal point.
--
-- @local
function path.cache_key (start, goal)

    return string.format("%d,%d>%d,%d", start.x, start.y, goal.x, goal.y)

end

--- Get a cached path.
--
-- @tparam point start
-- The start point.
--
-- @tparam point goal
-- The goal point.
--
-- @local
function path.read_cache (start, goal)

    if path.cache then
        local key = path.cache_key(start, goal)
        return path.cache[key]
    end

end

--- Saves a path to the cache.
--
-- @tparam point start
-- The start point.
--
-- @tparam point goal
-- The goal point.
--
-- @tparam table points
-- List of points representing a path.
--
-- @local
function path.write_cache (start, goal, points)

    path.cache = path.cache or { }
    local key = path.cache_key(start, goal)
    path.cache[key] = points

end


--- Get movement cost.
--
-- @tparam point previous
-- The previous point in the path.
--
-- @tparam point node
-- Current point in the path.
--
-- @tparam point goal
-- The goal point to reach.
--
-- G is the cost from START to this node.
-- H is a heuristic cost, in this case the distance from this node to the goal.
--
-- @return F, the sum of G and H.
function path.calculate_score (previous, node, goal)

    local G = previous.score + 1
    local H = tool.distance(node.x, node.y, goal.x, goal.y)
    return G + H, G, H

end

--- Test an item is in a list.
--
-- @tparam table list
--
-- @tparam point item
--
-- @local
function path.list_contains (list, item)

    for _, test in ipairs(list) do
        if test.x == item.x and test.y == item.y then
            return true
        end
    end

    return false

end

--- Get an item in a list.
--
-- @tparam table list
--
-- @tparam table item
--
-- @local
function path.get_list_item (list, item)

    for _, test in ipairs(list) do
        if test.x == item.x and test.y == item.y then
            return test
        end
    end

end

--- Get adjacent map points.
--
-- @tparam int width
--
--
-- @tparam int height
--
--
-- @tparam table point
-- {x, y} point to test.
--
-- @tparam function openTest
-- Function that should return if a point is open.
--
-- @return table of points adjacent to the point.
--
-- @local
function path.adjacent_points (width, height, point, openTest)

    local result = { }

    local positions = {
        { x = 0, y = -1 },  -- top
        { x = -1, y = 0 },  -- left
        { x = 0, y = 1 },   -- bottom
        { x = 1, y = 0 },   -- right
        -- include diagonal movements
        { x = -1, y = -1 },   -- top left
        { x = 1, y = -1 },   -- top right
        { x = -1, y = 1 },   -- bot left
        { x = 1, y = 1 },   -- bot right
    }

    for _, position in ipairs(positions) do
        local px = tool.clamp(point.x + position.x, 1, width)
        local py = tool.clamp(point.y + position.y, 1, height)
        local value = openTest(px, py)
        if value then
            table.insert(result, { x = px, y = py  })
        end
    end

    return result

end


--- Find a walkable path.
--
-- @tparam int width
-- Width of the floor.
--
-- @tparam int height
-- Height of the floor.
--
-- @tparam table start
-- {x, y} of the starting point.
--
-- @tparam table goal
-- {x, y} of the goal to reach.
--
-- @tparam function openTest
-- Called when querying if a point is open.
--
-- @tparam bool useCache
-- Cache paths for future re-use.
-- Caching is not used at the moment.
--
-- @return the path from start to goal, or false if no path exists.
--
-- @local
function path.find (width, height, start, goal, openTest, useCache)

    if useCache then
        local cachedPath = path.read_cache(start, goal)
        if cachedPath then
            return cachedPath
        end
    end

    local success = false
    local open = { }
    local closed = { }

    start.score = 0
    start.G = 0
    start.H = tool.distance(start.x, start.y, goal.x, goal.y)
    start.parent = { x = 0, y = 0 }
    table.insert(open, start)

    while not success and #open > 0 do

        -- sort by score: high to low
        table.sort(open, function(a, b) return a.score > b.score end)

        local current = table.remove(open)

        table.insert(closed, current)

        success = path.list_contains(closed, goal)

        if not success then

            local adjacentList = path.adjacent_points(width, height, current, openTest)

            for _, adjacent in ipairs(adjacentList) do

                if not path.list_contains(closed, adjacent) then

                    if not path.list_contains(open, adjacent) then

                        adjacent.score = path.calculate_score(current, adjacent, goal)
                        adjacent.parent = current
                        table.insert(open, adjacent)

                    end

                end

            end

        end

    end

    if not success then
        return false
    end

    -- traverse the parents from the last point to get the path
    local node = path.get_list_item(closed, closed[#closed])
    local walked_points = { }

    while node do

        table.insert(walked_points, 1, { x = node.x, y = node.y } )
        node = path.get_list_item(closed, node.parent)

    end

    if useCache then
        path.write_cache(start, goal, walked_points)
    end

    -- reverse the closed list to get the solution
    return walked_points

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                           _
--  ___ _ __   ___  ___  ___| |__
-- / __| '_ \ / _ \/ _ \/ __| '_ \
-- \__ \ |_) |  __/  __/ (__| | | |
-- |___/ .__/ \___|\___|\___|_| |_|
--     |_|


--- Clear queued speeches.
-- This gets called by @{slime.clear}
--
-- @local
function speech.clear ()

    speech.queue = { }

end


--- Make an actor talk.
-- Call this multiple times to queue speech.
--
-- @tparam string actor_name
-- Name of the actor.
--
-- @tparam string text
-- The words to display.
function speech.say (actor_name, text)

    -- intercept chaining
    if chain.capture then
        ooze.append(string.format("chaining %s say", actor_name))
        chain.add(speech.say,
                    {actor_name, text},
                    -- expires when actor is not talking
                    function (_name)
                        return not speech.is_talking(_name)
                    end
                    )
        return
    end

    if (not actor.get(actor_name)) then
        ooze.append("Speech failed: No actor named " .. actor_name)
        return
    end

    table.insert(speech.queue, {name=actor_name, text=text})

end


--- Test if someone is talking.
--
-- @tparam[opt] string actor_name
-- The actor to test against.
-- If not given, any talking actor is tested.
--
-- @return true if any actor, or the specified actor is talking.
function speech.is_talking (actor_name)

    if actor_name then
        -- if a specific actor is talking
        return speech.queue[1] and speech.queue[1].name == actor_name or false
    else
        -- if any actor is talking
        return (#speech.queue > 0)
    end

end


--- Skip the current spoken line.
-- Jumps to the next line in the queue.
function speech.skip ()

    local _speech_data = speech.queue[1]

    if (_speech_data) then

        -- remove the line
        table.remove(speech.queue, 1)

        -- restore the idle animation
        local _actor = actor.get(_speech_data.name)
        _actor.action = "idle"

        -- clear the current spoken line
        speech.current_text = nil

        -- fire speech ended event
        -- only if the next speech is not the same actor
        local _next_speech = speech.queue[1]
        if not _next_speech or _next_speech.name ~= _speech_data.name then
            event.speech_ended(_speech_data.name)
        end

    end

end


--- Update speech.
--
-- @tparam int dt
-- Delta time since the last update.
--
-- @local
function speech.update (dt)

    if (#speech.queue > 0) then

        local _speech_data = speech.queue[1]

        -- notify speech started event
        if speech.current_text ~= _speech_data.text then
            speech.current_text = _speech_data.text
            local _actor = actor.get(_speech_data.name)
            _actor.action = "talk"
            event.speech_started(_speech_data.name)
        end

    end

end


--- Draw speech on screen.
-- If there is speech data in the queue, of course.
-- This calls the @{event.draw_speech} callback.
--
-- @local
function speech.draw ()

    local _speech_data = speech.queue[1]

    if _speech_data then
        event.draw_speech(_speech_data.name, _speech_data.text)
    end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--      _ _
--  ___| (_)_ __ ___   ___
-- / __| | | '_ ` _ \ / _ \
-- \__ \ | | | | | | |  __/
-- |___/_|_|_| |_| |_|\___|
--


--- Clear the stage.
-- Call this before setting up a new stage.
-- Clears actors, backgrounds, chained actions, cursors,
-- walkable floors, walk-behind layers, hotspots, speeches.
function slime.clear ()

    draw_scale = 1
    actor.clear()
    background.clear()
    chain.clear()
    cursor.clear()
    floor.clear()
    hotspot.clear()
    speech.clear()

end

--- Reset slime.
-- This calls @{slime.clear} in addition to clearing bags and settings.
-- Call this when starting a new game.
function slime.reset ()

    slime.clear()
    bag.clear()
    setting.clear()
    cache.init()
    ooze.clear()

end

--- Update the game.
--
-- @tparam int dt
-- Delta time since the last update.
function slime.update (dt)

    last_dt = dt
    background.update(dt)
    actor.update(dt)
    speech.update(dt)
    chain.update(dt)

end

--- Draw the room.
--
-- @tparam[opt=1] int scale
-- Draw at the given scale.
function slime.draw (scale)

    -- draw to scale
    draw_scale = scale or 1
    love.graphics.push()
    love.graphics.scale(scale)

    love.graphics.setColor(1, 1, 1)
    background.draw()

    love.graphics.setColor(1, 1, 1)
    actor.draw()

    love.graphics.setColor(1, 1, 1)
    speech.draw()

    love.graphics.setColor(1, 1, 1)
    cursor.draw()

    love.graphics.pop()

end


--- Get objects at a point.
-- Includes actors, hotspots.
--
-- @tparam int x
-- X-position to test.
--
-- @tparam int y
-- Y-position to test.
--
-- @return table of objects.
function slime.get_objects (x, y)

    x, y = tool.scale_point(x, y)

    local objects = { }

    for _, actor in pairs(actor.list) do
        if actor.isactor and
            (x >= actor.x - actor.feet.x
            and x <= actor.x - actor.feet.x + actor.width)
        and (y >= actor.y - actor.feet.y
            and y <= actor.y - actor.feet.y + actor.height) then
            table.insert(objects, actor)
        end
    end

    -- TODO convert to hotspots:getAt()
    for ihotspot, hotspot in pairs(hotspot.list) do
        if (x >= hotspot.x and x <= hotspot.x + hotspot.w) and
            (y >= hotspot.y and y <= hotspot.y + hotspot.h) then
            table.insert(objects, hotspot)
        end
    end

    if (#objects == 0) then
        return nil
    else
        return objects
    end

end

--- Interact with objects.
-- This triggers the @{event.interact} callback for every
-- object that is interacted with, passing the current cursor name.
--
-- @tparam int x
-- X-position to interact with.
--
-- @tparam int y
-- Y-position to interact with.
function slime.interact (x, y)

    local objects = slime.get_objects(x, y)
    if (not objects) then return end

    local cursorname = cursor.name()

    for i, object in pairs(objects) do
        ooze.append(cursorname .. " on " .. object.name)
        -- fire the interact event
        event.interact(cursorname, object)
    end

    return true

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--           _   _   _
--  ___  ___| |_| |_(_)_ __   __ _ ___
-- / __|/ _ \ __| __| | '_ \ / _` / __|
-- \__ \  __/ |_| |_| | | | | (_| \__ \
-- |___/\___|\__|\__|_|_| |_|\__, |___/
                          -- |___/

--- Clear slime settings.
-- This gets called by @{slime.reset}
--
-- @local
function setting.clear ()

    setting["speech font"] = love.graphics.newFont(10)

end


--  _              _
-- | |_ ___   ___ | |___
-- | __/ _ \ / _ \| / __|
-- | || (_) | (_) | \__ \
--  \__\___/ \___/|_|___/
--

--- Get direction between two points.
--
-- @tparam int x1
-- Point 1 x
--
-- @tparam int y1
-- Point 1 y
--
-- @tparam int x2
-- Point 2 x
--
-- @tparam int y2
-- Point 2 y
--
-- @return nearest cardinal direction represented by the angle:
-- north south east or west.
--
-- @local
function tool.calculate_direction (x1, y1, x2, y2)

    --        180
    --         N
    --   225   |    135
    --         |
    --  270    |      90
    --  W -----+----- E
    --         |
    --         |
    --   315   |    45
    --         S
    --         0

    -- test value between a range
    local between = function(n, a, b)
        return n >= a and n <= b
    end

    -- calculate the angle between the two points
    local ang = math.atan2(y2 - y1, x2 - x1) * 180 / math.pi

    -- map the angle to a 360 degree range
    ang = 90 - ang
    if (ang < 0) then ang = ang + 360 end

    if between(ang, 0, 45) or between(ang, 315, 359) then
        return 'south'
    elseif between(ang, 45, 135) then
        return 'east'
    elseif between(ang, 135, 225) then
        return 'north'
    elseif between(ang, 225, 315) then
        return 'west'
    end

end

--- Clamp a value to a range.
--
-- @tparam int x
-- The value to test.
--
-- @tparam int min
-- Minimum value.
--
-- @tparam int max
-- Maximum value.
--
-- @local
function tool.clamp (x, min, max)

    return x < min and min or (x > max and max or x)

end

--- Measure the distance between two points.
--
-- @tparam int x1
-- @tparam int y1
-- @tparam int x2
-- @tparam int y2
--
-- @local
function tool.distance (x1, y1, x2, y2)

    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)

end

--- Linear interpolation.
--
-- @tparam number a
-- The starting value.
--
-- @tparam number b
-- The ending value.
--
-- @tparam number amount
-- Amount of interpolation to apply, between 0 and 1.
--
-- @local
function tool.lerp (a, b, amount)
    return a + (b - a) * tool.clamp(amount, 0, 1)
end

--- Constrain a point to a circle.
-- Given a radius and angle, get a point on the circumference of a circle.
-- https://wesleywerner.github.io/harness/doc/modules/trig.html#module:pointOnCircle
--
-- @tparam number cx
-- The x origin of the circle
--
-- @tparam number cy
-- The y origin of the circle
--
-- @tparam number r
-- The circle radius
--
-- @tparam number a
-- The angle of the point to the origin.
--
-- @treturn number
-- x, y
function tool.point_on_circle (cx, cy, r, a)

    x = cx + r * math.cos(a)
    y = cy + r * math.sin(a)
    return x, y

end

--- Scale a point from screen space to game space.
-- The ratio scaled is that which was supplied to the @{slime.draw} call.
-- This is used internally so that the end user does not have to bother
-- to perform coordinate scaling.
--
-- @tparam int x
-- @tparam int y
--
-- @return The scaled x, y values.
function tool.scale_point (x, y)

    -- adjust to scale
    x = math.floor(x / draw_scale)
    y = math.floor(y / draw_scale)
    return x, y

end

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                             _        _    ____ ___
--   _____  ___ __   ___  _ __| |_     / \  |  _ \_ _|
--  / _ \ \/ / '_ \ / _ \| '__| __|   / _ \ | |_) | |
-- |  __/>  <| |_) | (_) | |  | |_   / ___ \|  __/| |
--  \___/_/\_\ .__/ \___/|_|   \__| /_/   \_\_|  |___|
--           |_|

slime.reset()
slime.actor = actor
slime.background = background
slime.bag = bag
slime.chain = chain
slime.cursor = cursor
slime.hotspot = hotspot
slime.ooze = ooze
slime.event = event
slime.floor = floor
slime.layer = layer
slime.setting = setting
slime.speech = speech
slime.wait = chain.wait
return slime
