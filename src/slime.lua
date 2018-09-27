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

-- Handles animated sprites and calling the events.animation event.
local animations = { }

-- Manages actors on stage.
local actors = { }

-- Manages still and animated backgrounds.
local backgrounds = { }

-- Simple inventory storage component.
local bags = { }

-- Cache images for optimized memory usage.
local cache = { }

-- Provides chaining of actions to create scripted scenes.
local chains = { }

-- Callback events which the calling code can hook into.
local events = { }

-- Manages the on-screen cursor.
local cursor = { }

-- Provides interactive hotspots on the stage, specifically areas
-- that do draw themselves on screen.
local hotspots = { }

-- Manages the walkable areas.
local floors = { }

-- Manages walk-behind layers.
local layers = { }

-- Provides path finding for actor movement.
local path = { }

-- Collection of settings that changes SLIME behaviour.
local settings = { }

-- Manages talking actors.
local speech = { }

-- Provides an integrated debugging environment
local ooze = { }

-- Reusable functions
local tools = { }


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
-- @table actor
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
-- @tfield love.Image image
-- A still image drawn for this actor.

--- Clear actors.
-- This gets called by @{slime:clear}
--
-- @local
function actors:clear ( )

	self.list = { }

end

--- Add an actor.
--
-- @tparam actor actor
function actors:add (actor)

	-- get the size if a still image is set
	if actor.image then
		actor.width, actor.height = actor.image:getDimensions ()
	end

	assert (actor, "Actor definition must be given.")
	assert (actor.x, "Actor x position must be given.")
	assert (actor.y, "Actor y position must be given.")
	assert (actor.width, "Actor width must be given.")
	assert (actor.height, "Actor height must be given.")

    actor.isactor = true
    actor["direction recalc delay"] = 0
    actor.feet = actor.feet or "bottom"
    actor.direction = "south"
    actor.speechcolor = {1, 1, 1}
    actor.action = "idle"

    -- map the feet position from string to a table
    if actor.feet == "bottom" then
		actor.feet = { x = actor.width / 2, y = actor.height}
    elseif actor.feet == "top" then
		actor.feet = { x = actor.width / 2, y = 0}
    elseif actor.feet == "left" then
		actor.feet = { x = 0, y = actor.height / 2}
    elseif actor.feet == "right" then
		actor.feet = { x = actor.width, y = actor.height / 2}
    end

	assert (type(actor.feet) == "table", "Actor feet property must be string or a table")
    assert (actor.feet.x, "Actor feet must have x position")
    assert (actor.feet.y, "Actor feet must have y position")

    table.insert(self.list, actor)
    self:sort ()
    return actor

end


--- Update actors
--
--  animations and movement.
--
-- @tparam int dt
-- The delta time since the last update.
--
-- @local
function actors:update (dt)

	-- remember if any actors moved during this update
	local actorsMoved = false

    for _, actor in ipairs(self.list) do
        if actor.isactor then

			-- update the movement path
            if self:updatePath (actor, dt) then
				actorsMoved = true
            end

			-- set the animation key.
			-- walking or talking includes the facing direction.
			if actor.action == "talk"
			or actor.action == "walk"
			or actor.action == "idle" then
				actor.key = string.format("%s %s", actor.action, actor.direction)
			else
				actor.key = actor.action
			end

			animations:update (actor, dt)

            --~ local anim = actor:getAnim()
            --~ if anim then
                --~ anim._frames:update(dt)
                --~ local framesound = anim._sounds[anim._frames.position]
                --~ if framesound then
                    --~ love.audio.play(framesound)
                --~ end
            --~ end

        end
    end

	-- sort the draw order of actor if any moved
	if actorsMoved then
		self:sort ()
    end

end

--- Sort actors.
--
-- Orders actors and layers for correct z-order drawing.
-- It sorts by actor feet position (for actors)
-- and baselines (for layers).
--
-- @local
function actors:sort ( )

    table.sort(self.list, function (a, b)

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
-- @tparam actor actor
-- The actor to update.
--
-- @tparam int dt
-- The delta time since last update.
--
-- @local
function actors:updatePath (actor, dt)

    if (actor.path and #actor.path > 0) then

        -- Check if the actor's speed is set to delay movement.
        -- If no speed is set, we move on every update.

        -- TODO rename movedelay to speed.
        -- 		(can we specify this as pixels per second?)
        --		(one step on the path will be ~ 1 pixel)
        if (actor.movedelay) then

            -- start a new move delay counter
            if (not actor.movedelaydelta) then
                actor.movedelaydelta = actor.movedelay
            end

            actor.movedelaydelta = actor.movedelaydelta - dt

            -- the delay has not yet passed
            if (actor.movedelaydelta > 0) then
                return
            end

            -- the delay has passed. Reset it and continue.
            actor.movedelaydelta = actor.movedelay

        end

		-- load the next point in the path
        local point = table.remove (actor.path, 1)

        if (point) then

			-- update actor position
            actor.x, actor.y = point.x, point.y

            -- Test if we should calculate actor direction
            actor["direction recalc delay"] = actor["direction recalc delay"] - 1

			-- TODO: delete this direction delay. works better without it.
            do --(actor["direction recalc delay"] <= 0) then
                actor["direction recalc delay"] = 5
                actor.direction = self:directionOf (actor.previousX, actor.previousY, actor.x, actor.y)
                -- store previous position, to calculate the
                -- facing direction on the next iteration.
                actor.previousX, actor.previousY = actor.x, actor.y
            end

        end

		-- the goal is reached
        if (#actor.path == 0) then

			ooze:append (actor.name .. " moved complete")
            actor.path = nil
            actor.action = "idle"

			-- notify the moved callback
            events.moved (self, actor)

            -- OBSOLETE: replaced by events.move callback
            slime.callback ("moved", actor)

        end

		-- return movement signal
		return true

    end

end

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
function actors:directionOf (x1, y1, x2, y2)

    -- function angle(x1, y1, x2, y2)
    --     local ang = math.atan2(y2 - y1, x2 - x1) * 180 / math.pi
    --     ang = 90 - ang
    --     if (ang < 0) then ang = ang + 360 end
    --     return ang
    -- end
    --
    -- print('nw', angle(100, 100, 99, 99))
    -- print('n', angle(100, 100, 100, 99))
    -- print('ne', angle(100, 100, 101, 99))
    -- print('sw', angle(100, 100, 99, 101))
    -- print('s', angle(100, 100, 100, 101))
    -- print('se', angle(100, 100, 101, 101))
    -- print('w', angle(100, 100, 99, 100))
    -- print('e', angle(100, 100, 101, 100))
    --
    -- nw	225.0
    -- n	180.0
    -- ne	135.0
    -- sw	315.0
    -- s	0.0
    -- se	45.0
    -- w	270.0
    -- e	90.0
    --
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

    -- test if a value is between a range (inclusive)
    local function between(n, a, b)
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

    --return 'south'
end

--- Get an actor.
-- Find an actor by name.
--
-- @tparam string name
-- The name of the actor
--
-- @return the @{actor} or nil if not found.
function actors:get (name)

    for _, actor in ipairs(self.list) do
        if actor.name == name then
            return actor
        end
    end

end

--- Remove an actor.
-- Removes an actor by name
--
-- @tparam string name
-- The name of the actor to remove.
function actors:remove (name)

    for i, actor in ipairs(self.list) do
        if actor.name == name then
            table.remove(self.list, i)
            return true
        end
    end

end

--- Draw actors on screen.
--
-- @local
function actors:draw ()

    for _, actor in ipairs(self.list) do
        if actor.isactor then

			local tileset, quad, x, y, r, sx, sy, ox, oy = animations:getDrawParameters (actor)

			if quad and tileset then
				love.graphics.draw (tileset, quad, x, y, r, sx, sy, ox, oy)
			elseif tileset then
				-- drawable without a quad
				love.graphics.draw (tileset, x, y, r, sx, sy, ox, oy)
			end

        elseif actor.islayer then
            love.graphics.draw(actor.image, 0, 0)
        end
    end

end

--- Move an actor.
-- Uses path finding when a walkable floor is set, otherwise
-- if no floor is set an actor can walk anywhere.
--
-- @tparam string name
-- Name of the actor to move.
--
-- @tparam int x
-- X-position to move to.
--
-- @tparam int y
-- Y-position to move to.
--
-- @see floors:set
function actors:move (name, x, y)

	x, y = slime:scalePoint (x, y)

	-- intercept chaining
	if chains.capturing then
		ooze:append (string.format("chaining %s move", name))
		chains:add (actors.move,
			{self, name, x, y},
			-- expires when actor path is empty
			function (parameters)
				local actor = actors:get (parameters[2])
				if not actor or not actor.path then
					return true
				end
			end
			)
		return
	end

	-- test if the actor is on the stage
    local actor = self:get (name)

    if (actor == nil) then
        ooze:append ("No actor named " .. name)
        return
    end

	local start = { x = actor.x, y = actor.y }
	local goal = { x = x, y = y }

	-- If the goal is on a solid block find the nearest open point
	if floors:hasMap () then
		if not floors:isWalkable (goal.x, goal.y) then
			goal = floors:findNearestOpenPoint (goal)
		end
	end

	local useCache = false
	local width, height = floors:size ()

	local route

	if floors:hasMap () then
		route = path:find (width, height, start, goal, floors.isWalkable, useCache)
	else
		-- no floor is loaded, so move in a straight line
		route = floors:bresenham (start, goal)
	end

	-- we have a path
	if route then
		actor.clickedX = x
		actor.clickedY = y
		actor.path = route
		-- Default to walking animation
		actor.action = "walk"
		-- Calculate actor direction immediately
		actor.previousX, actor.previousY = actor.x, actor.y
		actor.direction = actors:directionOf (actor.x, actor.y, x, y)
		-- Output debug
		ooze:append ("move " .. name .. " to " .. x .. " : " .. y)
	else
		ooze:append ("no actor path found")
	end

end

--- Turn an actor.
-- Turn to face a cardinal direction, north south east or west.
--
-- @tparam string name
-- The actor to turn.
--
-- @tparam string direction
-- A cardinal direction: north, south, east or west.
function actors:turn (name, direction)

	-- intercept chaining
	if chains.capturing then
		ooze:append (string.format("chaining %s turn %s", name, direction))
		chains:add (actors.turn, {self, name, direction})
		return
	end

    local actor = self:get (name)

    if (actor) then
        actor.direction = direction
    end

end

--- Move an actor.
-- Moves towards another actor, as close as possible as
-- the walkable floor allows.
--
-- @tparam string name
-- Name of the actor to move.
--
-- @tparam string target
-- Name of the actor to move towards.
function actors:moveTowards (name, target)

    local targetActor = self:get (target)

    if (targetActor) then
        self:move (name, targetActor.x, targetActor.y)
    else
        ooze:append ("no actor named " .. target)
    end

end

--- Stop and actor.
-- Stop an actor from moving along their movement path.
--
-- @tparam string name
-- Name of the actor.
function actors:stop (name)

    local actor = self:get (name)

    if actor then
        actor.path = nil
    end

end

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--              _                 _   _
--   __ _ _ __ (_)_ __ ___   __ _| |_(_) ___  _ __  ___
--  / _` | '_ \| | '_ ` _ \ / _` | __| |/ _ \| '_ \/ __|
-- | (_| | | | | | | | | | | (_| | |_| | (_) | | | \__ \
--  \__,_|_| |_|_|_| |_| |_|\__,_|\__|_|\___/|_| |_|___/
--

--- Draw an actor's animation frame.
--
-- @tparam actor entity
-- The actor to draw.
--
-- @local
function animations:getDrawParameters (entity)

	-- if this actor has a still image
	if entity.image then
		if entity.x and entity.feet then
			local x, y = entity.drawX, entity.drawY
			local sx, sy = 1, 1
			local r, ox, oy = 0, 0, 0
			-- flip when going east
			if entity.direction == "east" then
				sx = -1
				ox = entity.width
			end
			return entity.image, x, y, r, sx, sy, ox, oy
		end
	end

	local sprites = entity.sprites
	local frames = sprites.animations[entity.key]

	if frames then

		local frame = frames[sprites.index]

		if not frame.quad then
			frame.quad = love.graphics.newQuad (
				frame.x, frame.y,
				frame.width, frame.height,
				sprites.size.width, sprites.size.height)
		end

		-- position
		local x, y = entity.drawX, entity.drawY
		-- rotation
		local r = 0
		-- scale
		local sx, sy = 1, 1
		-- origin
		local ox, oy = 0, 0

		-- invert scale to flip
		if frame.flip == true then
			sx = -1
			ox = entity.width
		end

		local tileset = cache(entity.sprites.filename)

		return tileset, frame.quad, x, y, r, sx, sy, ox, oy

	end

end


--- Update animation.
--
-- @tparam actor entity
-- The entity to update.
--
-- @tparam int dt
-- Delta time since last update.
--
-- @local
function animations:update (entity, dt)

	-- entity.sprites: sprite animation definition
	-- entity.name: fed back to the event.animation callback on loop
	-- entity.key: animation key to update
	-- entity.x, entity.y: position on screen

	local sprites = entity.sprites

	-- if there are no sprites, only a still image
	if not sprites and entity.image then
		if entity.x and entity.feet then
			entity.drawX = entity.x - entity.feet.x
			entity.drawY = entity.y - entity.feet.y
		end
		return
	end

	if not sprites then
		return
	end

	local frames = sprites.animations[entity.key]

	if not frames then
		return
	end

	-- initialize and clamp the index.
	-- when switching between animation keys, the index
	-- is not reset.
	sprites.index = sprites.index or 1
	sprites.index = math.min (sprites.index, #frames)

	if frames then

		local frame = frames[sprites.index]

		if not frame then
			print (sprites.index, #frames, entity.key, sprites.lastkey)
			error ("frame is empty")
		end
		sprites.lastkey = entity.key

		-- reduce the frame timer
		sprites.timer = (sprites.timer or 1) - dt

		if sprites.timer <= 0 then

			-- move to the next frame
			sprites.index = sprites.index + 1

			-- wrap the animation
			if sprites.index > #frames then
				-- animation loop ended
				sprites.index = 1
				-- reload the correct frame
				frame = frames[sprites.index]
				-- notify event
				events.animation (slime, actor, entity.key)
			end

			-- set the timer for this frame
			sprites.timer = frame.delay or 0.2

		end

		if not frame then
			print (sprites.index, entity.key, #frames)
			error ("frame is empty")
		end

		-- update the draw offset for actor sprites
		if entity.x and entity.feet then
			entity.drawX = entity.x - entity.feet.x + frame.xoffset
			entity.drawY = entity.y - entity.feet.y + frame.yoffset
		end

	end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--  _                _                                   _
-- | |__   __ _  ___| | ____ _ _ __ ___  _   _ _ __   __| |___
-- | '_ \ / _` |/ __| |/ / _` | '__/ _ \| | | | '_ \ / _` / __|
-- | |_) | (_| | (__|   < (_| | | | (_) | |_| | | | | (_| \__ \
-- |_.__/ \__,_|\___|_|\_\__, |_|  \___/ \__,_|_| |_|\__,_|___/
-- 				      |___/

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
function backgrounds:add (path, seconds)

    local image = love.graphics.newImage (path)
    local width, height = image:getDimensions ()

    -- set the background size
    if not self.width or not self.height then
		self.width, self.height = width, height
    end

    -- ensure consistent background sizes
    assert (width == self.width, "backgrounds must have the same size")
    assert (height == self.height, "backgrounds must have the same size")

    table.insert(self.list, {
		image = image,
		seconds = seconds
	})

end

--- Clear all backgrounds.
-- This gets called by @{slime:clear}
--
-- @local
function backgrounds:clear ()

	-- stores the list of backgrounds
	self.list = { }

	-- the index of the current background
	self.index = 1

	-- background size
	self.width, self.height = nil, nil

end

--- Draw the background.
--
-- @local
function backgrounds:draw ()

    local bg = self.list[self.index]

    if (bg) then
        love.graphics.draw(bg.image, 0, 0)
    end

end

--- Update backgrounds.
-- Tracks background delays and performs their rotation.
--
-- @tparam int dt
-- Delta time since the last update.
--
-- @local
function backgrounds:update (dt)

	-- skip background rotation if there is no more than one
    if not self.list[2] then
        return
    end

    local index = self.index
    local background = self.list[index]
    local timer = self.timer

    if (timer == nil) then
        -- start a new timer
        index = 1
        timer = background.seconds
    else
        timer = timer - dt
        -- this timer has expired
        if (timer < 0) then
            -- move to the next background
            index = (index == #self.list) and 1 or index + 1
            if (self.list[index]) then
                timer = self.list[index].seconds
            end
        end
    end

    self.index = index
    self.timer = timer

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--  _
-- | |__   __ _  __ _ ___
-- | '_ \ / _` |/ _` / __|
-- | |_) | (_| | (_| \__ \
-- |_.__/ \__,_|\__, |___/
--              |___/

--- Clear all bags.
-- This gets called by @{slime:clear}
--
-- @local
function bags:clear ()

	self.contents = { }

end

--- Add a thing to a bag.
--
-- @tparam string name
-- Name of the bag to store in.
--
-- @tparam table object
-- TODO: this bag object thing is a bit under-developed.
-- define it's structure.
function bags:add (name, object)

    -- load the image
    if type(object.image) == "string" then
        object.image = love.graphics.newImage(object.image)
    end

    -- create it
    self.contents[name] = self.contents[name] or { }

	-- add the object to it
    table.insert(self.contents[name], object)

    -- notify the callback
    events.bag (self, name)

    -- OBSOLETE: replaced by events.bag
    slime.inventoryChanged (name)

	ooze:append (string.format("Added %s to bag", object.name))

end

--- Remove a thing from a bag.
--
-- @tparam string name
-- Name of the bag.
--
-- @tparam string thingName
-- Name of the thing to remove.
function bags:remove (name, thingName)

    local inv = self.contents[name] or { }

	for i, item in pairs(inv) do
		if (item.name == thingName) then
			table.remove(inv, i)
			ooze:append (string.format("Removed %s", thingName))
			slime.inventoryChanged (name)
		end
	end

end

--- Test if a bag has a thing.
--
-- @tparam string name
-- Name of bag to search.
--
-- @tparam string thingName
-- Name of thing to find.
function bags:contains (name, thingName)

    local inv = self.contents[name] or { }

    for _, v in pairs(inv) do
        if v.name == thingName then
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
function cache:init ()

	-- Calling a table like a function
	setmetatable (self, {
		__call = function (self, ...)
			return self:interface (...)
		end
	})

	self.store = { }

end

--- Save to cache and return a copy.
--
-- @tparam string path
-- Path to the image to load.
--
-- @local
function cache:interface (path)

    -- cache tileset image to save loading duplicate images
    local image = self.store[path]

    if not image then
        image = love.graphics.newImage(path)
        self.store[path] = image
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
-- This gets called by @{slime:clear}
--
-- @local
function chains:clear ()

	-- Allow calling this table like it was a function.
	-- We do this for brevity sake.
	setmetatable (chains, {
		__call = function (self, ...)
			return self:capture (...)
		end
	})

	self.list = { }

	-- when capturing: certain actor functions will queue themselves
	-- to the chain instead of actioning instantly.
	self.capturing = nil

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
--
-- @function chain
-- @see chains_example.lua
function chains:capture (name, userFunction)

	-- catch obsolete usage
	if type (name) == "table" then
		assert (false, "slime:chain is obsolete. use slime.chain()... notation")
	end

	-- use a default chain name if none is provided
	name = name or "default"

	-- fetch the chain from storage
	self.capturing = self.list[name]

	-- create a new chain instead
	if not self.capturing then
		self.capturing = { name = name, actions = { } }
		self.list[name] = self.capturing
		ooze:append (string.format ("created chain %q", name))
	end

	-- queue custom function
	if type (userFunction) == "function" then
		self:add (userFunction, { })
		ooze:append (string.format("user function chained"))
	end

	-- return the slime instance to allow further action chaining
	return slime

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
function chains:add (func, parameters, expired)

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
	table.insert (self.capturing.actions, command)

	-- release this capture
	self.capturing = nil

end

--- Process chains.
--
-- @tparam int dt
-- Delta time since the last update
--
-- @local
function chains:update (dt)

	-- for each chain
	for key, chain in pairs(self.list) do

		-- the next command in this chain
		local command = chain.actions[1]

		if command then

			-- run the action once only
			if not command.ran then
				--ooze:append (string.format("running chain command"))
				command.ran = true
				command.func (unpack (command.parameters))
			end

			-- test if the action expired
			local skipTest = type (command.expired) ~= "function"

			-- remove expired actions from this chain
			if skipTest or command.expired (command.parameters, dt) then
				--ooze:append (string.format("chain action expired"))
				table.remove (chain.actions, 1)
			end

		end

	end

end

--- Pause the chain.
--
-- @tparam int seconds
-- Seconds to wait before the next action is run.
function chains:wait (seconds)

	if chains.capturing then

		--ooze:append (string.format("waiting %ds", seconds))

		chains:add (chains.wait,

					-- pack parameter twice, the second being
					-- our countdown
					{seconds, seconds},

					-- expires when the countdown reaches zero
					function (p, dt)
						p[2] = p[2] - dt
						return p[2] < 0
					end
					)

	end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

--- Actor animation looped callback.
--
-- @param self
-- The slime instance
--
-- @tparam actor actor
-- The actor being interacted with
--
-- @tparam string key
-- The animation key that looped
--
-- @tparam int counter
-- The number of times the animation has looped
function events.animation (self, actor, key, counter)

end

--- Bag contents changed callback.
--
-- @param self
-- The slime instance
--
-- @tparam string bag
-- The name of the bag that changed
function events.bag (self, bag)

end

--- Callback when a mouse interaction occurs.
--
-- @param self
-- The slime instance
--
-- @tparam string event
-- The name of the cursor
--
-- @tparam actor actor
-- The actor being interacted with
function events.interact (self, event, actor)

end

--- Actor finished moving callback.
--
-- @param self
-- The slime instance
--
-- @tparam actor actor
-- The actor that moved
function events.moved (self, actor)

end

--- Actor speaking callback.
--
-- @param self
-- The slime instance
--
-- @tparam actor actor
-- The talking actor
--
-- @tparam bool started
-- true if the actor has started talking
--
-- @tparam bool ended
-- true if the actor has stopped talking
function events.speech (self, actor, started, ended)

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--   ___ _   _ _ __ ___  ___  _ __
--  / __| | | | '__/ __|/ _ \| '__|
-- | (__| |_| | |  \__ \ (_) | |
--  \___|\__,_|_|  |___/\___/|_|
--

--- Custom cursor data
--
-- @table cursor
--
-- @tfield string name
-- Name of the cursor. This gets passed back to the
-- @{events.interact} callback event.
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
-- This gets called by @{slime:clear}
--
-- @local
function cursor:clear ()

	self.cursor = nil

end

--- Draw the cursor.
--
-- @local
function cursor:draw ()

	if self.cursor and self.x then
		if self.cursor.quad then
			love.graphics.draw (self.cursor.image, self.cursor.quad, self.x, self.y)
		else
			love.graphics.draw (self.cursor.image, self.x, self.y)
		end
	end

end

--- Get the current cursor name.
--
-- @local
function cursor:getName ()

	if self.cursor then
		return self.cursor.name
	else
		return "interact"
	end

end

--- Set a custom cursor.
--
-- @tparam cursor cursor
-- The cursor data.
function cursor:set (cursor)

	assert (cursor.name, "cursor needs a name")
	assert (cursor.image, "cursor needs an image")

	-- default hotspot to top-left corner
	cursor.hotspot = cursor.hotspot or {x = 0, y = 0}

	self.cursor = cursor

	ooze:append (string.format("set cursor %q", cursor.name))

end

--- Update the cursor position.
--
-- @tparam int x
-- @tparam int y
function cursor:update (x, y)

	x, y = slime:scalePoint (x, y)

	-- adjust draw position to center around the hotspot
	if self.cursor then
		self.x = x - self.cursor.hotspot.x
		self.y = y - self.cursor.hotspot.y
	else
		self.x, self.y = x, y
	end

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--   __ _
--  / _| | ___   ___  _ __ ___
-- | |_| |/ _ \ / _ \| '__/ __|
-- |  _| | (_) | (_) | |  \__ \
-- |_| |_|\___/ \___/|_|  |___/


--- Clear walkable floors.
-- This gets called by @{slime:clear}
--
-- @local
function floors:clear ()

	self.walkableMap = nil

end

--- Test if a walkable map is loaded.
--
-- @local
function floors:hasMap ()

	return self.walkableMap ~= nil

end

--- Set a walkable floor.
-- The floor mask defines where actors can walk.
-- Any non-black pixel is walkable.
--
-- @tparam string filename
-- The image mask defining walkable areas.
function floors:set (filename)

	-- intercept chaining
	if chains.capturing then
		chains:add (floors.set, {self, filename})
		return
	end

	self:convert (filename)

end

--- Convert a walkable floor mask.
-- Prepares the mask for use in path finding.
--
-- @tparam string filename
-- The floor map image filename
--
-- @local
function floors:convert (filename)

    -- Converts a walkable image mask into map points.
    local mask = love.image.newImageData(filename)
    local w = mask:getWidth()
    local h = mask:getHeight()

    -- store the size
    self.width, self.height = w, h

    local row = nil
    local r = nil
    local g = nil
    local b = nil
    local a = nil
    self.walkableMap = { }

    -- builds a 2D array of the image size, each index references
    -- a pixel in the mask
    for ih = 1, h - 1 do
        row = { }
        for iw = 1, w - 1 do
            r, g, b, a = mask:getPixel (iw, ih)
            if (r + g + b == 0) then
				-- not walkable
                table.insert(row, false)
            else
				-- walkable
                table.insert(row, true)
            end
        end
        table.insert(self.walkableMap, row)
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
function floors:isWalkable (x, y)

	if self:hasMap () then
		-- clamp to floor boundary
		x = tools:clamp (x, 1, self.width - 1)
		y = tools:clamp (y, 1, self.height - 1)
		return self.walkableMap[y][x]
	else
		-- no floor is always walkable
		return true
	end

end

--- Get the size of the floor.
--
-- @local
function floors:size ()

	if self.walkableMap then
		return self.width, self.height
	else
		-- without a floor map, we return the background size
		return backgrounds.width, backgrounds.height
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
function floors:bresenham (start, goal)

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
function floors:findNearestOpenPoint (point)

    -- Get the dimensions of the walkable floor map.
    local width, height = floors:size ()

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
        local walkTheLine = self:bresenham (direction, goal)
        local continueSearch = true
        while (continueSearch) do
            if (#walkTheLine == 0) then
                continueSearch = false
            else
                goal = table.remove(walkTheLine)
                continueSearch = not self:isWalkable (goal.x, goal.y)
            end
        end
        -- math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
        local distance = math.sqrt( (goal.x - point.x)^2 + (goal.y - point.y)^2 )
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
-- This gets called by @{slime:clear}
--
-- @local
function hotspots:clear ()

	self.list = { }

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
function hotspots:add (name, x, y, w, h)

    local hotspot = {
        ["name"] = name,
        ["x"] = x,
        ["y"] = y,
        ["w"] = w,
        ["h"] = h
    }

    table.insert(self.list, hotspot)
    return hotspot

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
function layers:add (background, mask, baseline)

	assert (background ~= nil, "Missing parameter to layers:add")
	assert (mask ~= nil, "Missing parameter to layers:add")
	assert (baseline ~= nil, "Missing parameter to layers:add")

    local newLayer = {
        ["image"] = self:convertMask (background, mask),
        ["baseline"] = baseline,
        islayer = true
        }

	-- layers are merged with actors so that we can perform
	-- efficient sorting, enabling drawing of actors behind layers.
    table.insert(actors.list, newLayer)

    actors:sort()

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
function layers:convertMask (source, mask)

    -- Returns a copy of the source image with transparent pixels where
    -- the positional pixels in the mask are black.

    local sourceData = love.image.newImageData(source)
    local maskData = love.image.newImageData(mask)

	local sourceW, sourceH = sourceData:getDimensions()
    layerData = love.image.newImageData( sourceW, sourceH )

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
function ooze:clear ()

	self.trigger:init ()
	self.logger:init ()
	self.outliner:init ()
	self.spriteview:init ()		-- incomplete and not listed in available states
	self.menu:init ()

	-- list available ooze states
	self.states = { nil, self.logger, self.outliner }
	self.index = 1

	self:loadMenu ()

end


--- Append to the log.
--
-- @local
function ooze:append (text)

	self.logger:append (text)

end


--- Draw the debug overlay.
function ooze:draw (scale)

	-- drawing enabled ooze updates
	self.enabled = true

	self.trigger:draw (scale)
	self.menu:draw ()

	if self.states[self.index] then
		self.states[self.index]:draw (scale)
	end

end


function ooze:mousemoved (x, y, dx, dy, istouch)

	self.menu:mousemoved (x, y, dx, dy, istouch)

end

function ooze:mousepressed (x, y, button, istouch, presses)

	-- test if the trigger zone was clicked
	if self.trigger:mousepressed (x, y) then

		-- move to the next state
		self.index = self.index + 1

		-- wrap states
		if self.index > #self.states then
			self.index = 1
		end

		-- load new menu options
		self:loadMenu ()

		return true
	end

	-- pass this event through to the current state
	local state = self.states[self.index]
	if state and state.mousepressed then
		local handled = state:mousepressed (x, y, button, istouch, presses)
		-- handled events are eaten up
		if handled == true then
			return handled
		end
	end

end


--- Loads the menu options for the state.
--
-- @local
function ooze:loadMenu ()

	local state = self.states[self.index]
	if state and state.buildMenu then
		self.menu:set (state:buildMenu())
	else
		self.menu:clear ()
	end

end

function ooze:update (dt)

	self.menu:update (dt)

end

function ooze:wheelmoved (x, y)

	self.menu:wheelmoved (x, y)

end


--                       _
--   ___   ___ _______  | | ___   __ _  __ _  ___ _ __
--  / _ \ / _ \_  / _ \ | |/ _ \ / _` |/ _` |/ _ \ '__|
-- | (_) | (_) / /  __/ | | (_) | (_| | (_| |  __/ |
--  \___/ \___/___\___| |_|\___/ \__, |\__, |\___|_|
--                               |___/ |___/
--

function ooze.logger:init ()

	self.log = { }

	-- debug border
	self.padding = 10
	self.width, self.height = love.graphics.getDimensions ()
	self.width = self.width - (self.padding * 2)
	self.height = self.height - (self.padding * 2)

	-- the font for printing debug texts
	self.font = love.graphics.newFont (12)
	self.color = {0, 1, 0}

end

function ooze.logger:append (text)

    table.insert(self.log, text)

    -- cull the log
    if (#self.log > 20) then
		table.remove(self.log, 1)
	end

end

function ooze.logger:draw (scale)

	love.graphics.setColor (self.color)
	love.graphics.setFont (self.font)

    -- print fps
    love.graphics.printf (
		string.format("%d fps", love.timer.getFPS()),
		self.padding, self.padding, self.width, "center")

    -- print background info
    if (backgrounds.index and backgrounds.timer) then
		love.graphics.printf (
			string.format("background #%d showing for %.1f",
			backgrounds.index, backgrounds.timer),
			self.padding, self.padding, self.width, "right")
	end

	-- print log
    for i, n in ipairs(self.log) do
		love.graphics.setColor ({0, 0, 0})
        love.graphics.print (n, self.padding + 1, self.padding + 1 + (16 * i))
		love.graphics.setColor (self.color)
        love.graphics.print (n, self.padding, self.padding + (16 * i))
    end

end


--                                   _   _ _
--   ___   ___ _______    ___  _   _| |_| (_)_ __   ___ _ __
--  / _ \ / _ \_  / _ \  / _ \| | | | __| | | '_ \ / _ \ '__|
-- | (_) | (_) / /  __/ | (_) | |_| | |_| | | | | |  __/ |
--  \___/ \___/___\___|  \___/ \__,_|\__|_|_|_| |_|\___|_|
--

function ooze.outliner:init ()

	self.width, self.height = love.graphics.getDimensions ()

	self.hotspotColor = {1, 1, 0, 0.8}	-- yellow
	self.actorColor = {0, 0, 1, 0.8}	-- blue

	-- list of colors we can cycle through so each layer has it's own.
	self.layerColors = {
		{1, 0, 0, 0.5},		-- red
		{0, 1, 0, 0.5}, 	-- green
		{0.5, 0, 1, 0.5}, 	-- purple
		{1, 0, 1, 0.5}, 	-- magenta
	}

end

function ooze.outliner:draw (scale)

	-- draw object outlines to scale
	love.graphics.push ()
	love.graphics.scale (scale)

    -- outline hotspots
	love.graphics.setColor (self.hotspotColor)
    for ihotspot, hotspot in pairs(hotspots.list) do
        love.graphics.rectangle ("line", hotspot.x, hotspot.y, hotspot.w, hotspot.h)
    end

    -- track layer counter
    local layerCounter = 1

    -- outline actors
    for _, actor in ipairs(actors.list) do
        if actor.isactor then
			love.graphics.setColor (self.actorColor)
			-- TODO calculate draw position in actor:update
            love.graphics.rectangle("line", actor.drawX, actor.drawY, actor.width, actor.height)
            love.graphics.circle("line", actor.x, actor.y, 1, 6)
        elseif actor.islayer then
            -- draw baselines for layers
            local layerColorIndex = math.max (1, layerCounter % (#self.layerColors + 1))
			love.graphics.setColor (self.layerColors[layerColorIndex])
			love.graphics.draw (actor.image)
            love.graphics.line(0, actor.baseline, self.width, actor.baseline)
            layerCounter = layerCounter + 1
        end
    end

    love.graphics.pop ()

end

function ooze.outliner:buildMenu ()

	return {

	}

end


--                       _        _
--   ___   ___ _______  | |_ _ __(_) __ _  __ _  ___ _ __
--  / _ \ / _ \_  / _ \ | __| '__| |/ _` |/ _` |/ _ \ '__|
-- | (_) | (_) / /  __/ | |_| |  | | (_| | (_| |  __/ |
--  \___/ \___/___\___|  \__|_|  |_|\__, |\__, |\___|_|
--                                  |___/ |___/

function ooze.trigger:init ()

	self.width, self.height = love.graphics.getDimensions ()
	self.borderColor = {0, 1, 0}
	self.triggerColor = {0, 1, 0, 0.42}

	-- radius of the trigger area in the screen corner
	self.triggerSize = 20

	self.triggerX = 0
	self.triggerY = self.height

end

function ooze.trigger:draw (scale)

	love.graphics.setColor (self.borderColor)
	love.graphics.rectangle ("line", 0, 0, self.width, self.height)
	love.graphics.setColor (self.triggerColor)
	love.graphics.circle ("fill", self.triggerX, self.triggerY, self.triggerSize)

end

function ooze.trigger:mousepressed (x, y, button, istouch, presses)

	-- check distance to the trigger zone.
	local dist = tools:distance (x, y, self.triggerX, self.triggerY)
	return dist < self.triggerSize

end


--                                      _ _               _
--   ___   ___ _______   ___ _ __  _ __(_) |_ ___  __   _(_) _____      __
--  / _ \ / _ \_  / _ \ / __| '_ \| '__| | __/ _ \ \ \ / / |/ _ \ \ /\ / /
-- | (_) | (_) / /  __/ \__ \ |_) | |  | | ||  __/  \ V /| |  __/\ V  V /
--  \___/ \___/___\___| |___/ .__/|_|  |_|\__\___|   \_/ |_|\___| \_/\_/
--                          |_|

function ooze.spriteview:init ()

end

function ooze.spriteview:draw (scale)
	love.graphics.rectangle("fill", 0, 0, 100, 100)
end

function ooze.spriteview:mousepressed (x, y, button, istouch, presses)
	return true
end




--   ___   ___ _______   _ __ ___   ___ _ __  _   _
--  / _ \ / _ \_  / _ \ | '_ ` _ \ / _ \ '_ \| | | |
-- | (_) | (_) / /  __/ | | | | | |  __/ | | | |_| |
--  \___/ \___/___\___| |_| |_| |_|\___|_| |_|\__,_|

--- Initialize the ooze menu.
function ooze.menu:init (options)

    -- the radius of the wheel
    self.r = 100

    -- seconds to wait before fading out
    self.displayFor = 2

    -- angle facing north
    self.north = 270

	self.screenWidth, self.screenHeight = love.graphics.getDimensions ()

    -- start invisible
    self.opacity = { dt = self.displayFor, amount = 0 }

end

--- Clear the ooze menu.
function ooze.menu:clear ()

	self.modes = nil

end

--- Set the ooze menu options.
-- @tparam table option
function ooze.menu:set (options)

    -- the menu options
    self.modes = {
        "add",
        "alter",
        "delete",
        "name",
        "copy",
        "paste",
        "grid"
    }

    -- angle step size divided evenly between all modes
    self.step = math.floor (360 / #self.modes)

    -- set the first mode
    self.mode = self.modes[1]

    -- precalculate starting positions
    self.points = { }
    for n, mode in ipairs (self.modes) do
        -- mind we store point angles in degrees!
        local factor = n - 1
        local itemAngle = self.north + (factor * self.step)
        self.points[mode] = {
            goal = itemAngle,
            actual = itemAngle,
            dt = 1,
            scale = 1
        }
    end

    -- set invisible
    self.opacity = { dt = self.displayFor, amount = 0 }
    self.x, self.y = love.mouse.getPosition ()

end

function ooze.menu.update (self, dt)

	if not self.modes then
		return
	end

    -- update actual angles to match goal angles
    for key, point in pairs (self.points) do

        point.dt = math.min (1, point.dt + dt)
        point.actual = tools:lerp (point.actual, point.goal, point.dt)

        -- adjust scale
        if key == self.mode then
            point.scale = math.min (1, point.scale + dt)
        else
            point.scale = math.max (0.5, point.scale - dt)
        end

    end

    -- update opacity
    self.opacity.dt = self.opacity.dt + dt
    if self.opacity.dt > self.displayFor then
        -- decrease
        self.opacity.amount = math.max (0, self.opacity.amount - dt * 2)
    elseif self.opacity.amount < 1 then
        -- increase
        self.opacity.amount = math.min (1, self.opacity.amount + dt * 2)
    end

end

function ooze.menu:draw ()

	if not self.modes then
		return
	end

    --~ -- show the current mode as an icon always on-screen
    --~ local icon = self.icons[self.mode]
    --~ if icon then
        --~ love.graphics.setColor (1, 1, 1, 0.4)
        --~ love.graphics.draw (icon, 0, 0, 0, 0.5, 0.5)
    --~ end

    -- skip drawing further, since we are now invisible
    if self.opacity.amount == 0 then
        return
    end

    -- fill background
    love.graphics.setColor ({0, 0, 0, math.min (self.opacity.amount, 0.5) })
    love.graphics.circle ("fill", self.x, self.y, self.r * 1.2)

    -- draw circumference
    --love.graphics.setColor (1, 1, 1, self.opacity.amount * 0.1)
    --love.graphics.circle ("line", self.x, self.y, self.r)

    -- draw each mode at the actual angle
    for key, point in pairs (self.points) do

        -- convert the angle to radians before plotting
        local angle = math.rad (point.actual)
        local nx, ny = self:pointOnCircle (self.x, self.y, self.r, angle)

        --~ -- fade the icon color into existence
        --~ local keycolor = self.colors[key] or colors.white
        --~ local r, g, b = unpack (keycolor)
        --~ love.graphics.setColor (r, g, b, self.opacity.amount)

        --~ -- draw the icon
        --~ if self.icons[key] then
            --~ love.graphics.draw (self.icons[key], nx, ny, 0, point.scale, point.scale, 32, 32)
        --~ end

		love.graphics.setColor ({1, 1, 1})
        love.graphics.printf (key, nx, ny, self.r * 1, "left")

    end

    -- print the menu mode as centered text
    --love.graphics.setFont (fonts.medium)
    love.graphics.setColor ({1, 1, 1, self.opacity.amount })
    love.graphics.printf (self.mode, self.x - self.r, self.y - 40, self.r * 2, "center")

end

function ooze.menu.mousemoved (self, x, y, dx, dy, istouch)
    -- clamp the menu to the screen
    self.x = tools:clamp (x, self.r, self.screenWidth - self.r)
    self.y = tools:clamp (y, self.r, self.screenHeight - self.r)
end

function ooze.menu.mousepressed (self, x, y, button, istouch, presses)
    if self.mode == "copy" then
        local dump = require ("dump")
        local ser = dump.tostring (frames.db)
        love.system.setClipboardText (ser)
        print (ser)
    elseif self.mode == "paste" then
        local contents = "return " .. love.system.getClipboardText ()
		local loaded = loadstring(contents)
		if type(loaded) == "function" then
			frames.db = loaded()
		else
			print ("Content is not lua string")
		end
    end
end

function ooze.menu.wheelmoved (self, x, y)

    -- prevent cycling on show
    if self.opacity.amount == 0 then
        self.opacity.dt = 1
        return
    end

    if y then
        for key, point in pairs (self.points) do
            -- move the goal angle
            point.goal = (point.goal + self.step * y)
            -- reset the angle movement
            point.dt = 0
            -- the distance between the goal and the north point
            -- determines the current mode, it can also vary up to
            -- 12 degrees (depending how many modes you have, ala step size)
            local diff = math.abs((point.goal % 360) - self.north)
            if diff < 13 then
                -- store the north facing mode
                self.mode = key
                -- store the point of reference
                --self.point = point
            end
        end

        -- keep opacity steady while scrolling the wheel
        self.opacity.dt = 0
    end
end

--- Returns a point on a circle.
-- https://wesleywerner.github.io/harness/doc/modules/trig.html#module:pointOnCircle
--
-- @tparam number cx
-- The origin of the circle
--
-- @tparam number cy
-- The origin of the circle
--
-- @tparam number r
-- The circle radius
--
-- @tparam number a
-- The angle of the point to the origin.
--
-- @treturn number
-- x, y
function ooze.menu.pointOnCircle (self, cx, cy, r, a)

    x = cx + r * math.cos(a)
    y = cy + r * math.sin(a)
    return x, y

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
-- This gets called by @{slime:clear}
--
-- @local
function path:clear ()

    self.cache = nil

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
function path:keyOf (start, goal)

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
function path:getCached (start, goal)

    if self.cache then
        local key = self:keyOf (start, goal)
        return self.cache[key]
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
-- @tparam table path
-- List of points representing a path.
--
-- @local
function path:saveCached (start, goal, path)

    self.cache = self.cache or { }
    local key = self:keyOf (start, goal)
    self.cache[key] = path

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
function path:calculateScore (previous, node, goal)

    local G = previous.score + 1
    local H = tools:distance (node.x, node.y, goal.x, goal.y)
    return G + H, G, H

end

--- Test an item is in a list.
--
-- @tparam table list
-- @table item
--
-- @local
function path:listContains (list, item)

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
function path:listItem (list, item)

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
function path:getAdjacent (width, height, point, openTest)

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
        local px = tools:clamp (point.x + position.x, 1, width)
        local py = tools:clamp (point.y + position.y, 1, height)
        local value = openTest (floors, px, py)
        if value then
            table.insert( result, { x = px, y = py  } )
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
function path:find (width, height, start, goal, openTest, useCache)

    if useCache then
        local cachedPath = self:getCached (start, goal)
        if cachedPath then
            return cachedPath
        end
    end

    local success = false
    local open = { }
    local closed = { }

    start.score = 0
    start.G = 0
    start.H = tools:distance (start.x, start.y, goal.x, goal.y)
    start.parent = { x = 0, y = 0 }
    table.insert(open, start)

    while not success and #open > 0 do

        -- sort by score: high to low
        table.sort(open, function(a, b) return a.score > b.score end)

        local current = table.remove(open)

        table.insert(closed, current)

        success = self:listContains (closed, goal)

        if not success then

            local adjacentList = self:getAdjacent (width, height, current, openTest)

            for _, adjacent in ipairs(adjacentList) do

                if not self:listContains (closed, adjacent) then

                    if not self:listContains (open, adjacent) then

                        adjacent.score = self:calculateScore (current, adjacent, goal)
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
    local node = self:listItem (closed, closed[#closed])
    local path = { }

    while node do

        table.insert(path, 1, { x = node.x, y = node.y } )
        node = self:listItem (closed, node.parent)

    end

    self:saveCached (start, goal, path)

    -- reverse the closed list to get the solution
    return path

end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                           _
--  ___ _ __   ___  ___  ___| |__
-- / __| '_ \ / _ \/ _ \/ __| '_ \
-- \__ \ |_) |  __/  __/ (__| | | |
-- |___/ .__/ \___|\___|\___|_| |_|
--     |_|


--- Clear queued speeches.
-- This gets called by @{slime:clear}
--
-- @local
function speech:clear ()

	self.queue = { }

end


--- Make an actor talk.
-- Call this multiple times to queue speech.
--
-- @tparam string name
-- Name of the actor.
--
-- @tparam string text
-- The words to display.
--
-- @tparam[opt=3] int seconds
-- Seconds to display the words.
function speech:say (name, text, seconds)

	-- default seconds
	seconds = seconds or 3

	-- intercept chaining
	if chains.capturing then
		ooze:append (string.format("chaining %s say", name))
		chains:add (speech.say,
					{self, name, text, seconds},
					-- expires when actor is not talking
					function (parameters)
						return not speech:isTalking (parameters[2])
					end
					)
		return
	end

    local newSpeech = {
        ["actor"] = actors:get (name),
        ["text"] = text,
        ["time"] = seconds
        }

    if (not newSpeech.actor) then
        ooze:append ("Speech failed: No actor named " .. name)
        return
    end

    table.insert(self.queue, newSpeech)

end


--- Test if someone is talking.
--
-- @tparam[opt] string actor
-- The actor to test against.
-- If not given, any talking actor is tested.
--
-- @return true if any actor, or the specified actor is talking.
function speech:isTalking (actor)

	if type (actor) == "string" then
		actor = actors:get (actor)
	end

	if actor then
		-- if a specific actor is talking
		return self.queue[1] and self.queue[1].actor.name == actor
	else
		-- if any actor is talking
		return (#self.queue > 0)
	end

end


--- Skip the current spoken line.
-- Jumps to the next line in the queue.
function speech:skip ()

    local speech = self.queue[1]

    if (speech) then

		-- remove the line
        table.remove(self.queue, 1)

        -- restore the idle animation
        speech.actor.action = "idle"

        -- clear the current spoken line
        self.currentLine = nil

        -- notify speech ended event
        events.speech (slime, speech.actor, false, true)

    end

end


--- Update speech.
--
-- @tparam int dt
-- Delta time since the last update.
--
-- @local
function speech:update (dt)

    if (#self.queue > 0) then

        local speech = self.queue[1]
        speech.time = speech.time - dt

        -- notify speech started event
        if self.currentLine ~= speech.text then
			self.currentLine = speech.text
			events.speech (slime, speech.actor, true)
		end

        if (speech.time < 0) then
            self:skip ()
        else
            speech.actor.action = "talk"
            if not settings["walk and talk"] then
                speech.actor.path = nil
            end
        end

    end

end


--- Draw speech.
--
-- @local
function speech:draw ()

    if (#self.queue > 0) then
        local spc = self.queue[1]
        if settings["builtin text"] then

            -- Store the original color
            local r, g, b, a = love.graphics.getColor()

            local y = settings["speech position"]
            local w = love.graphics.getWidth() / slime.scale

            love.graphics.setFont(settings["speech font"])

            -- Black outline
            love.graphics.setColor({0, 0, 0, 255})
            love.graphics.printf(spc.text, 1, y+1, w, "center")

            love.graphics.setColor(spc.actor.speechcolor)
            love.graphics.printf(spc.text, 0, y, w, "center")

            -- Restore original color
            love.graphics.setColor(r, g, b, a)

        else
            self:onDrawSpeechCallback(spc.actor.x, spc.actor.y,
                spc.actor.speechcolor, spc.text)
        end
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
function slime:clear ()

	self.scale = 1
    actors:clear ()
    backgrounds:clear ()
    chains:clear ()
	cursor:clear ()
    floors:clear ()
    hotspots:clear ()
    speech:clear ()
    self.statusText = nil

end

--- Reset slime.
-- This calls @{slime:clear} in addition to clearing bags and settings.
-- Call this when starting a new game.
function slime:reset ()

	self:clear ()
	bags:clear ()
	settings:clear ()
	cache:init ()
    ooze:clear ()

end

--- Update the game.
--
-- @tparam int dt
-- Delta time since the last update.
function slime:update (dt)

	chains:update (dt)
    backgrounds:update (dt)
	actors:update (dt)
	speech:update (dt)

end

--- Draw the room.
--
-- @tparam[opt=1] int scale
-- Draw at the given scale.
function slime:draw (scale)

    self.scale = scale or 1

    -- reset draw color
    love.graphics.setColor (1, 1, 1)

	-- draw to scale
    love.graphics.push()
    love.graphics.scale(scale)

    backgrounds:draw ()
	actors:draw ()

    -- Bag Buttons
	-- OBSOLETE IN FUTURE
    for counter, button in pairs(self.bagButtons) do
        love.graphics.draw (button.image, button.x, button.y)
    end

    -- status text
    if (self.statusText) then
        local y = settings["status position"]
        local w = love.graphics.getWidth() / self.scale
        love.graphics.setFont(settings["status font"])
        -- Outline
        love.graphics.setColor({0, 0, 0, 255})
        love.graphics.printf(self.statusText, 1, y+1, w, "center")
        love.graphics.setColor({255, 255, 255, 255})
        love.graphics.printf(self.statusText, 0, y, w, "center")
    end

	speech:draw ()
	cursor:draw ()

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
function slime:getObjects (x, y)

	x, y = self:scalePoint (x, y)

    local objects = { }

    for _, actor in pairs(actors.list) do
        if actor.isactor and
            (x >= actor.x - actor.feet.x
            and x <= actor.x - actor.feet.x + actor.width)
        and (y >= actor.y - actor.feet.y
            and y <= actor.y - actor.feet.y + actor.height) then
            table.insert(objects, actor)
        end
    end

	-- TODO convert to hotspots:getAt()
    for ihotspot, hotspot in pairs(hotspots.list) do
        if (x >= hotspot.x and x <= hotspot.x + hotspot.w) and
            (y >= hotspot.y and y <= hotspot.y + hotspot.h) then
            table.insert(objects, hotspot)
        end
    end

    for ihotspot, hotspot in pairs(self.bagButtons) do
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
-- This triggers the @{events.interact} callback for every
-- object that is interacted with, passing the current cursor name.
--
-- @tparam int x
-- X-position to interact with.
--
-- @tparam int y
-- Y-position to interact with.
function slime:interact (x, y)

    local objects = self:getObjects(x, y)
    if (not objects) then return end

	local cursorname = cursor:getName ()

    for i, object in pairs(objects) do
		ooze:append (cursorname .. " on " .. object.name)

		-- notify the interact callback
		events.interact (self, cursorname, object)

		-- OBSOLETE: slime.callback replaced by events
        slime.callback (cursorname, object)
    end

    return true

end


function slime:scalePoint (x, y)

	-- adjust to scale
	x = math.floor (x / self.scale)
	y = math.floor (y / self.scale)
	return x, y

end

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--           _   _   _
--  ___  ___| |_| |_(_)_ __   __ _ ___
-- / __|/ _ \ __| __| | '_ \ / _` / __|
-- \__ \  __/ |_| |_| | | | | (_| \__ \
-- |___/\___|\__|\__|_|_| |_|\__, |___/
                          -- |___/

--- Clear slime settings.
-- This gets called by @{slime:reset}
--
-- @local
function settings:clear ()

	-- Let slime handle displaying of speech text on screen,
	-- if false the onDrawSpeechCallback function is called.
    self["builtin text"] = true

	-- The y-position to display status text
    self["status position"] = 70

    self["status font"] = love.graphics.newFont(12)

    -- The y-position to display speech text
    self["speech position"] = 0

    self["speech font"] = love.graphics.newFont(10)

    -- actors stop walking when they speak
    self["walk and talk"] = false

end


--  _              _
-- | |_ ___   ___ | |___
-- | __/ _ \ / _ \| / __|
-- | || (_) | (_) | \__ \
--  \__\___/ \___/|_|___/
--

--- Linear interpolation.
function tools:lerp (a, b, amount)
    return a + (b - a) * self:clamp (amount, 0, 1)
end

--- Distance between two points.
-- This method doesn't bother getting the square root of s, it is faster
-- and it still works for our use.
--
-- @tparam int x1
-- @tparam int y1
-- @tparam int x2
-- @tparam int y2
--
-- @local
function tools:distance (x1, y1, x2, y2)

	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt (dx * dx + dy * dy)

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
function tools:clamp (x, min, max)

	return x < min and min or (x > max and max or x)

end

-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--~        _               _      _
--~   ___ | |__  ___  ___ | | ___| |_ ___
--~  / _ \| '_ \/ __|/ _ \| |/ _ \ __/ _ \
--~ | (_) | |_) \__ \ (_) | |  __/ ||  __/
--~  \___/|_.__/|___/\___/|_|\___|\__\___|
--~


function slime.callback (event, object)
end

function slime.animationLooped (actor, key, counter)
end

function slime.onDrawSpeechCallback(actorX, actorY, speechcolor, words)
end

function slime.background (self, ...)

	backgrounds:add (...)

end

function slime.setCursor (self, name, image, hotspot, quad)

	print ("slime.setCursor will be obsoleted, use slime.cursor:set()")

	local data = {
		name = name,
		image = image,
		quad = quad,
		hotspot = hotspot
	}
	cursor:set (data)

end

function slime.loadCursors (self, path, w, h, names, hotspots)

	print ("slime.loadCursors will be obsoleted, use slime.cursor:set()")
    cursor.names = names or {}
    cursor.hotspots = hotspots or {}
    cursor.image = love.graphics.newImage(path)
    cursor.quads = {}
    cursor.current = 1

    local imgwidth, imgheight = cursor.image:getDimensions()

    local totalImages = imgwidth / w

    for x = 1, totalImages do

        local quad = love.graphics.newQuad((x - 1) * w, 0,
            w, h, imgwidth, imgheight)

        table.insert(cursor.quads, quad)

    end

end

function slime.useCursor (self, index)
	--print ("slime.useCursor will be obsoleted, use slime.cursor:set()")
    cursor.current = index
end

function slime.getCursor (self)
	print ("slime.getCursor will be obsoleted")
    return self.cursor.current
end

function slime.floor (self, filename)

	print ("slime.floors will be obsoleted, use slime.floors:set()")
	floors:set (filename)

end

function slime.actor (self, name, x, y)

	print ("slime.actor will be obsoleted, use slime.actors:add()")
	return actors:add ({
		name = name,
		x = x,
		y = y
	})

end

function slime.getActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.getActor will be obsoleted, use slime.actors:get()")
	return actors:get (...)

end

function slime.removeActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.removeActor will be obsoleted, use slime.actors:remove()")
	return actors:remove (...)

end

function slime.defineTileset (self, tileset, size)

	print ("slime.defineTileset will be obsoleted.")
    local actor = self

    -- cache tileset image to save loading duplicate images
    slime:cache(tileset)

    -- default actor hotspot to centered at the base of the image
    actor.w = size.w
    actor.h = size.h
    actor.feet = { size.w / 2, size.h }

    return {
        actor = actor,
        tileset = tileset,
        size = size,
        define = slime.defineAnimation
        }

end

function slime.defineAnimation (self, key)

    local pack = {
        anim = self,
        frames = slime.defineFrames,
        delays = slime.defineDelays,
        sounds = slime.defineSounds,
        offset = slime.defineOffset,
        flip = slime.defineFlip,
        key = key,
        loopcounter = 0,
        _sounds = {},
        _offset = {x=0, y=0}
    }

    return pack

end

function slime.defineFrames (self, frames)
    self.framesDefinition = frames
    return self
end

function slime.defineDelays (self, delays)

    local image = slime:cache(self.anim.tileset)

    local g = anim8.newGrid(
        self.anim.size.w,
        self.anim.size.h,
        image:getWidth(),
        image:getHeight())

    self._frames = anim8.newAnimation(
        g(unpack(self.framesDefinition)),
        delays or 1,
        slime.internalAnimationLoop)

    -- circular ref back
    self._frames.pack = self

    -- store this animation object in the actor's animation table
    self.anim.actor.animations[self.key] = self

    return self
end

function slime.defineSounds (self, sounds)
    sounds = sounds or {}
    for i, v in pairs(sounds) do
        if type(v) == "string" then
            sounds[i] = love.audio.newSource(v, "static")
        end
    end
    self._sounds = sounds
    return self
end

function slime.defineOffset (self, x, y)
    self._offset = {x=x, y=y}
    return self
end

function slime.defineFlip (self)
    self._frames:flipH()
    return self
end

function slime.setAnimation (self, name, key)

	-- intercept chaining
	if chains.capturing then
		chains:add (slime.setAnimation, {self, name, key})
		return
	end

    local actor = self:getActor(name)

    if (not actor) then
        ooze:append ("Set animation failed: no actor named " .. name)
    else
        actor.customAnimationKey = key
        -- reset the animation counter
        local anim = actor:getAnim()
        if anim then
            anim.loopcounter = 0
            -- Recalculate the actor's base offset
            local size = anim.anim.size
            actor.w = size.w
            actor.h = size.h
            actor.base = { size.w / 2, size.h }
        end
    end

end

function slime.animationDuration(self, name, key)
    local a = self:getActor(name)
    if a then
        local anim = a.animations[key]
        if anim then
            return anim._frames.totalDuration
        end
    end
    return 0
end

function slime.setImage (self, image)

    local actor = self

    if (not actor) then
        ooze:append ("slime.Image method should be called from an actor instance")
    else
        image = love.graphics.newImage(image)
        actor.image = image
        actor.w = image:getWidth()
        actor.h = image:getHeight()
        actor.feet = { actor.w/2, actor.h }
    end

end

function slime.turnActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.turnActor will be obsoleted, use slime.actors:turn()")
	actors:turn (...)

end

function slime.moveActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.moveActor will be obsoleted, use slime.actors:move()")
	return actors:move (...)

end

function slime.moveActorTo (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.moveActorTo will be obsoleted, use slime.actors:moveTowards()")
	actors:moveTowards (...)

end

function slime.stopActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.stopActor will be obsoleted, use slime.actors:stop()")
	actors:stop (...)

end

function slime.say (self, name, text)

	print ("slime.say will be obsoleted, use slime.speech:say()")
	speech:say (name, text)

end

function slime.someoneTalking (self)

	print ("slime.someoneTalking will be obsoleted, use slime.speech:isTalking()")
	return speech:isTalking ()

end

function slime.actorTalking (self, actor)

	print ("slime.actorTalking will be obsoleted, use slime.speech:isTalking()")
	return speech:isTalking (actor)

end

function slime.skipSpeech (self)

	print ("slime.skipSpeech will be obsoleted, use slime.speech:skip()")
	speech:skip ()

end

function slime.layer (self, ...)

	print ("slime.layer will be obsoleted, use slime.layers:add()")
	layers:add (...)

end

function slime:createLayer (source, mask)

	print ("slime.layer will be obsoleted, use slime.layers:add()")
	return layers:convertMask (source, mask)

end

function slime.hotspot(self, ...)

	print ("slime.hotspot will be obsoleted, use slime.hotspots:add()")
	hotspots:add (...)

end

slime.bagButtons = { }

function slime.inventoryChanged ( )
	-- OBSOLETE IN FUTURE
	-- replace with the future room structure
end

function slime.bagInsert (self, ...)

	print ("slime.bagInsert will be obsoleted, use slime.bags:add()")
	bags:add (...)

end

function slime.bagContents (self, bag)

	print ("slime.bagContents will be obsoleted, use slime.bags.contents[<key>]")
    return bags.contents[bag] or { }

end

function slime.bagContains (self, ...)
	print ("slime.bagContains will be obsoleted, use slime.bags:contains()")
	return bags:contains (...)
end

function slime.bagRemove (self, ...)

	print ("slime.bagRemove will be obsoleted, use slime.bags:remove()")
	bags:remove (...)

end

function slime.bagButton (self, name, image, x, y)

	print ("slime.bagButton will be obsoleted")

    if type(image) == "string" then image = love.graphics.newImage(image) end

    local w, h = image:getDimensions ()

    table.insert(self.bagButtons, {
        ["name"] = name,
        ["image"] = image,
        ["x"] = x,
        ["y"] = y,
        ["w"] = w,
        ["h"] = h,
        ["data"] = data
    })

end

function slime.status (self, text)

	--print ("slime.status will be obsoleted")
    self.statusText = text

end


function slime.internalAnimationLoop (frames, counter)
    local pack = frames.pack
    pack.loopcounter = pack.loopcounter + 1
    if pack.loopcounter > 255 then
        pack.loopcounter = 0
    end

	-- notify the animation callback
    events.animation (slime, pack.anim.actor.name, pack.key, pack.loopcounter)

    -- OBSOLETE: replaced by events.animation
    slime.animationLooped (pack.anim.actor.name, pack.key, pack.loopcounter)
end


-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--                             _        _    ____ ___
--   _____  ___ __   ___  _ __| |_     / \  |  _ \_ _|
--  / _ \ \/ / '_ \ / _ \| '__| __|   / _ \ | |_) | |
-- |  __/>  <| |_) | (_) | |  | |_   / ___ \|  __/| |
--  \___/_/\_\ .__/ \___/|_|   \__| /_/   \_\_|  |___|
--           |_|

slime.actors = actors
slime.backgrounds = backgrounds
slime.bags = bags
slime.chain = chains
slime.cursor = cursor
slime.hotspots = hotspots
slime.ooze = ooze
slime.events = events
slime.floors = floors
slime.layers = layers
slime.settings = settings
slime.speech = speech
slime.wait = chains.wait
return slime
