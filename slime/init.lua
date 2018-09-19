--        _ _
--    ___| (_)_ __ ___   ___
--   / __| | | '_ ` _ \ / _ \
--   \__ \ | | | | | | |  __/
--   |___/_|_|_| |_| |_|\___|
--
-- SLIME is a point-and-click adventure game library for LÖVE.

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

-- bresenham line algorithm
require 'slime.bresenham'

-- Uses anim8 by Enrique García Cota
-- https://github.com/kikito/anim8
local anim8 = require 'slime.anim8'

local actors = { }
local backgrounds = { }
local bags = { }
local chains = { }
local events = { }
local debug = { }
local cursor = { }
local hotspots = { }
local floors = { }
local layers = { }
local path = { }
local settings = { }
local speech = { }



--               _
--     __ _  ___| |_ ___  _ __ ___
--    / _` |/ __| __/ _ \| '__/ __|
--   | (_| | (__| || (_) | |  \__ \
--    \__,_|\___|\__\___/|_|  |___/

function actors.clear (self)

	self.list = { }

end

-- TODO change actor.add sig to a table
function actors.add (self, name, x, y)

    -- Add an actor to the stage.
    -- Allows adding the same actor name multiple times, but only
    -- the first instance uses the "name" as the key, subsequent
    -- duplicates will use the natural numbering of the table.

    -- default sprite size
    local w = 10
    local h = 10

    local newActor = {
        ["isactor"] = true,
        ["name"] = name,
        ["x"] = x,
        ["y"] = y,
        ["direction recalc delay"] = 0,     -- delay direction calc counter.
        ["w"] = w,
        ["h"] = h,
        ["feet"] = {0, 0},                  -- position of actor's feet (relative to the sprite)
        ["image"] = nil,                    -- a static image of this actor.
        ["animations"] = { },
        ["direction"] = "south",
        ["action"] = "idle",
        ["speechcolor"] = {255, 255, 255},
        ["inventory"] = { }
        }

    function newActor:getAnim ()
        local priorityAction = self.action == "talk" or self.action == "walk"
        if (self.customAnimationKey and not priorityAction) then
            return self.animations[self.customAnimationKey]
        else
            local key = self.action .. " " .. self.direction
            return self.animations[key]
        end
    end

    table.insert(self.list, newActor)

    -- set actor image method
    newActor.setImage = slime.setImage

    -- set the actor new animation method
    -- TODO refactor this, pass animation data to this add() method
    -- instead of all this chaining business.
    newActor.tileset = slime.defineTileset

    -- set slime host reference
    newActor.host = self

    self:sortLayers()

    return newActor

end

function actors.update (self, dt)

	local actorsMoved = false

    -- Update animations
    for _, actor in ipairs(self.list) do
        if actor.isactor then

            if self:updatePath (actor, dt) then
				actorsMoved = true
            end

            local anim = actor:getAnim()
            if anim then
                anim._frames:update(dt)
                local framesound = anim._sounds[anim._frames.position]
                if framesound then
                    love.audio.play(framesound)
                end
            end
        end
    end

	-- reorder if any actors moved
	if actorsMoved then
		self:sortLayers()
    end

end

--- Sort actors and layers for correct zorder drawing
function actors.sortLayers (self)

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

function actors.updatePath (self, actor, dt)

    if (actor.path and #actor.path > 0) then

        -- Check if the actor's speed is set to delay movement.
        -- If no speed is set, we move on every update.
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

            if (actor["direction recalc delay"] <= 0) then
                actor["direction recalc delay"] = 5
                actor.direction = self:calculateDirection (actor.lastx, actor.lasty, actor.x, actor.y)
                actor.lastx, actor.lasty = actor.x, actor.y
            end

        end

		-- the goal is reached
        if (#actor.path == 0) then

			debug:append (actor.name .. " moved complete")
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


-- Return the nearest cardinal direction represented by the angle of movement.
function actors.calculateDirection (self, x1, y1, x2, y2)

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

function actors.get (self, name)

    for _, actor in ipairs(self.list) do
        if actor.name == name then
            return actor
        end
    end

end

function actors.remove (self, name)

    for i, actor in ipairs(self.list) do
        if actor.name == name then
            table.remove(self.list, i)
            return true
        end
    end

end

function actors.draw (self)

    for _, actor in ipairs(self.list) do
        if actor.isactor then

			local anim = actor:getAnim()

			if anim then
				local tileset = slime:cache(anim.anim.tileset)
				anim._frames:draw(tileset,
					actor.x - actor.feet[1] + anim._offset.x,
					actor.y - actor.feet[2] + anim._offset.y)
			elseif (actor.image) then
				love.graphics.draw(actor.image,
					actor.x - actor.feet[1],
					actor.y - actor.feet[2])
			else
				love.graphics.rectangle ("fill", actor.x - actor.feet[1], actor.y - actor.feet[2], actor.w, actor.h)
			end

        elseif actor.islayer then
            love.graphics.draw(actor.image, 0, 0)
        end
    end

end

--- Move an actor to point xy using A Star path finding
function actors.move (self, name, x, y)

	-- intercept chaining
	if chains.capturing then
		debug:append (string.format("chaining %s move", name))
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
        debug:append ("No actor named " .. name)
        return
    end

	local start = { x = actor.x, y = actor.y }
	local goal = { x = x, y = y }

	-- If the goal is on a solid block find the nearest open point
	if floors:hasMap () then
		if not floors.isWalkable (goal.x, goal.y) then
			goal = floors:findNearestOpenPoint (goal)
		end
	end

	local useCache = false
	local width, height = floors:size ()
	local route = path:find (width, height, start, goal, floors.isWalkable, useCache)

	-- we have a path
	if route then
		actor.clickedX = x
		actor.clickedY = y
		actor.path = route
		-- Default to walking animation
		actor.action = "walk"
		-- Calculate actor direction immediately
		actor.lastx, actor.lasty = actor.x, actor.y
		actor.direction = actors:calculateDirection (actor.x, actor.y, x, y)
		-- Output debug
		debug:append ("move " .. name .. " to " .. x .. " : " .. y)
	else
		debug:append ("no actor path found")
	end

end

function actors.turn (self, name, direction)

	-- intercept chaining
	if chains.capturing then
		debug:append (string.format("chaining %s turn %s", name, direction))
		chains:add (actors.turn, {self, name, direction})
		return
	end

    local actor = self:get (name)

    if (actor) then
        actor.direction = direction
    end

end

--- Move an actor to another actor
function actors.moveTowards (self, name, target)

    local targetActor = self:get (target)

    if (targetActor) then
        self:move (name, targetActor.x, targetActor.y)
    else
        debug:append ("no actor named " .. target)
    end

end

function actors.stop (self, name)

    local actor = self:get (name)

    if actor then
        actor.path = nil
    end

end


--~  _                _                                   _
--~ | |__   __ _  ___| | ____ _ _ __ ___  _   _ _ __   __| |___
--~ | '_ \ / _` |/ __| |/ / _` | '__/ _ \| | | | '_ \ / _` / __|
--~ | |_) | (_| | (__|   < (_| | | | (_) | |_| | | | | (_| \__ \
--~ |_.__/ \__,_|\___|_|\_\__, |_|  \___/ \__,_|_| |_|\__,_|___/
--~ 				      |___/

--- Add a background image to the room.
-- This can be called many times to create an animated background.
--
-- @param filename
-- The image filename of the background.
--
-- @param delay
-- The seconds to display the background.
-- When the delay has expired the next background is displayed.
function backgrounds.add (self, filename, delay)

    -- Add a background to the stage, drawn at x, y for the given delay
    -- before drawing the next available background.
    -- If no delay is given, the background will draw forever.

    local image = love.graphics.newImage(filename)
    local width, height = image:getDimensions ()

    -- set the background size
    if not self.width or not self.height then
		self.width, self.height = width, height
    end

    -- ensure consistent background sizes
    assert (width == self.width, "backgrounds must have the same size")
    assert (height == self.height, "backgrounds must have the same size")

    local data = {
        ["image"] = image,
        ["delay"] = delay
        }

    table.insert(self.list, data)

    -- default to the first background
    if #self.list == 1 then
        self.index = 1
        self.timeout = delay
    end

end

--- Clears all backgrounds.
function backgrounds.clear (self)

	-- stores the list of backgrounds
	self.list = { }

	-- the index of the current background
	self.index = 1

	-- time remaining until the background cycles
	self.timeout = 1

	-- background size
	self.width, self.height = nil, nil

end

--- Draws the current background to screen.
function backgrounds.draw (self)

    local bg = self.list[self.index]

    if (bg) then
        love.graphics.draw(bg.image, 0, 0)
    end

end

--- Rotates to the next background if there is one and delay expired.
function backgrounds.update (self, dt)

    if (#self.list <= 1) then
        -- skip background rotation if there is one or none
        return
    end

    local index = self.index
    local background = self.list[index]
    local timer = self.timeout

    if (timer == nil or background == nil) then
        -- start a new timer
        index = 1
        timer = background.delay
    else
        timer = timer - dt
        -- this timer has expired
        if (timer < 0) then
            -- move to the next index (with wrapping)
            index = (index == #self.list) and 1 or index + 1
            if (self.list[index]) then
                timer = self.list[index].delay
            end
        end
    end

    self.index = index
    self.timeout = timer

end



--~  _
--~ | |__   __ _  __ _ ___
--~ | '_ \ / _` |/ _` / __|
--~ | |_) | (_| | (_| \__ \
--~ |_.__/ \__,_|\__, |___/
--~              |___/

--- Clears the contents of all bags.
function bags.clear (self)

	self.contents = { }

end

--- Adds an item to a named bag.
function bags.add (self, bag, object)

    -- load the image data
    if type(object.image) == "string" then
        object.image = love.graphics.newImage(object.image)
    end

    -- create the bag
    if not self.contents[bag] then
		self.contents[bag] = { }
	end

	-- add object to the bag
    table.insert(self.contents[bag], object)

    -- notify bag callback
    events.bag (self, bag)

    -- OBSOLETE: replaced by events.bag
    slime.inventoryChanged (bag)

    debug:append ("Added " .. object.name .. " to bag \"" .. bag .. "\"")

end

function bags.remove (self, bag, name)

    local inv = self.contents[bag] or { }

	for i, item in pairs(inv) do
		if (item.name == name) then
			table.remove(inv, i)
			debug:append ("Removed " .. name .. " from bag \"" .. bag .. "\"")
			slime.inventoryChanged (bag)
		end
	end

end

--- Test if a bag contains a named item.
function bags.contains (self, bag, item)

    local inv = self.contents[bag] or { }

    for _, v in pairs(inv) do
        if v.name == item then
            return true
        end
    end

end


--       _           _
--   ___| |__   __ _(_)_ __  ___
--  / __| '_ \ / _` | | '_ \/ __|
-- | (__| | | | (_| | | | | \__ \
--  \___|_| |_|\__,_|_|_| |_|___/

-- Provides ways to chain actions to run in sequence

--- Removes all action chains
-- @param self
-- The slime instance
function chains.clear (self)

	-- Allow calling this table like it was a function.
	setmetatable (chains, {
		__call = function (self, ...)
			return self:capture (...)
		end
	})

	self.list = { }

	-- when capturing all other actions will queue themselves
	-- to the chain instead of actioning instantly.
	self.capturing = nil

end

--- Begins chain capturing mode.
-- While in this mode, the next call to a slime function
-- will be added to the chain action list instead of executing
-- immediately.
--
-- @param self
--
-- @param name
-- Optional name of the chain
-- Specifying a name allows creating multiple, concurrent chains.
--
-- @param userFunction
-- Optional user provided function
-- Adds a user function to the chain that will be called in turn.
--
-- @return The slime instance to allow further action chaining
function chains.capture (self, name, userFunction)

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
		debug:append (string.format ("created chain %q", name))
	end

	-- queue custom function
	if type (userFunction) == "function" then
		self:add (userFunction, { })
		debug:append (string.format("user function chained"))
	end

	-- return the slime instance to allow further action chaining
	return slime

end

--- Adds a action to the capturing chain.
--
-- @param self
--
-- @param func
-- The function to call
--
-- @param parameters
-- The function parameters
--
-- @param expired
-- Optional function that returns true when the action
-- has expired, which does so instantly if this parameter
-- is not given.
function chains.add (self, func, parameters, expired)

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

--- Process chain actions
--
-- @param self
-- Slime instance
--
-- @param dt
-- The delta time since the last update
function chains.update (self, dt)

	-- for each chain
	for key, chain in pairs(self.list) do

		-- the next command in this chain
		local command = chain.actions[1]

		if command then

			-- run the action once only
			if not command.ran then
				--debug:append (string.format("running chain command"))
				command.ran = true
				command.func (unpack (command.parameters))
			end

			-- test if the action expired
			local skipTest = type (command.expired) ~= "function"

			-- remove expired actions from this chain
			if skipTest or command.expired (command.parameters, dt) then
				--debug:append (string.format("chain action expired"))
				table.remove (chain.actions, 1)
			end

		end

	end

end

--- Pause the chain
--
-- @param seconds
-- The number of seconds to wait
function chains.wait (self, seconds)

	if chains.capturing then

		--debug:append (string.format("waiting %ds", seconds))

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


--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

--- Callback when an animation loops
--
-- @param self
-- The slime instance
--
-- @param actor
-- The actor being interacted with
--
-- @param key
-- The animation key that looped
--
-- @param counter
-- The number of times the animation has looped
function events.animation (self, actor, key, counter)

end

--- Callback when a bag contents has changed
--
-- @param self
-- The slime instance
--
-- @param bag
-- The name of the bag that changed
function events.bag (self, bag)

end

--- Callback when a mouse interaction occurs.
--
-- @param self
-- The slime instance
--
-- @param event
-- The name of the cursor
--
-- @param actor
-- The actor being interacted with
function events.interact (self, event, actor)

end

--- Callback when an actor reached their destination.
--
-- @param self
-- The slime instance
--
-- @param actor
-- The actor that moved
function events.moved (self, actor)

end

--- Callback when an actor begins speaking a new line
--
-- @param self
-- The slime instance
--
-- @param actor
-- The talking actor
--
-- @param started
-- true if the actor has started speaking
--
-- @param ended
-- true if the actor has ended speaking
function events.speech (self, actor, started, ended)

end


--   ___ _   _ _ __ ___  ___  _ __
--  / __| | | | '__/ __|/ _ \| '__|
-- | (__| |_| | |  \__ \ (_) | |
--  \___|\__,_|_|  |___/\___/|_|
--


--- Clears all cursor data
function cursor.clear (self)

	self.quads = { }
	self.names = { }

end

--- Draws the cursor on screen
function cursor.draw (self)

    local quad = self.quads[self.current]

    if quad then

        local x, y = love.mouse.getPosition()
        x = x / scale
        y = y / scale

		-- A custom cursor (like that of an inventory item)
		-- set through setCursor
        if self.custom then
            local cursorhotspot = self.custom.hotspot
            love.graphics.draw(self.custom.image,
                x-cursorhotspot.x, y-cursorhotspot.y)
        else

            local cursorhotspot = self.hotspots[self.current]
            cursorhotspot = cursorhotspot or {x=0, y=0}
            love.graphics.draw(self.image, quad,
                x-cursorhotspot.x, y-cursorhotspot.y)
        end
    end

end

--- Get the current cursor name
-- TODO rename to "name"
function cursor.getName (self)

	-- TODO tidy up with if-else
	local cursorname = self.custom and self.custom.name
	cursorname = cursorname or (self.names[self.current])
	return cursorname or "interact"

end

-- Set a custom cursor.
-- TODO change signature to take a table of cursor data.
-- also rename "hotspot", it is too ambiguous with the hotspots namespace.
function cursor.set (self, name, image, hotspot)

    if name then
        cursor.custom = {
            name=name,
            image=image,
            hotspot=hotspot or {x=0, y=0}
            }
    else
        cursor.custom = nil
    end

end


--        _      _
--     __| | ___| |__  _   _  __ _
--    / _` |/ _ \ '_ \| | | |/ _` |
--   | (_| |  __/ |_) | |_| | (_| |
--    \__,_|\___|_.__/ \__,_|\__, |
--                           |___/
-- Provides helpful debug information while building your game.

--- Clears the debug log
function debug.clear (self)

	self.log = { }
	self.enabled = true

	-- debug border
	self.padding = 10
	self.width, self.height = love.graphics.getDimensions ()
	self.width = self.width - (self.padding * 2)
	self.height = self.height - (self.padding * 2)

	-- the alpha for debug outlines
	local alpha = 0.42

	-- define colors for debug outlines
	self.hotspotColor = {1, 1, 0, alpha}
	self.actorColor = {0, 0, 1, alpha}
	self.layerColor = {1, 0, 0, alpha}
	self.textColor = {0, 1, 0, alpha}

	-- the font for printing debug texts
	self.font = love.graphics.newFont (12)

end


--- Appends an entry to the debugging log.
function debug.append (self, text)

    table.insert(self.log, text)

    -- cull the log
    if (#self.log > 10) then
		table.remove(self.log, 1)
	end

end


--- Draws debug information and object outlines.
function debug.draw (self, scale)

	-- draw the debug frame
	love.graphics.setColor (self.textColor)
	love.graphics.rectangle ("line", self.padding, self.padding, self.width, self.height)
	love.graphics.setFont (self.font)
	love.graphics.printf ("SLIME DEBUG", self.padding, self.padding, self.width, "center")

    -- print fps
    love.graphics.print (tostring(love.timer.getFPS()) .. " fps", self.padding, self.padding)

    -- print background info
    if (backgrounds.index and backgrounds.timeout) then
        love.graphics.print(
			string.format("background #%d showing for %.1f",
			backgrounds.index, backgrounds.timeout), 60, 10)
    end

	-- print log
    for i, n in ipairs(self.log) do
        love.graphics.print (n, self.padding, self.padding * 3 + (16 * i))
    end

	-- draw object outlines to scale
	love.graphics.push ()
	love.graphics.scale (scale)

    -- outline hotspots
	love.graphics.setColor (self.hotspotColor)
    for ihotspot, hotspot in pairs(hotspots.list) do
        love.graphics.rectangle ("line", hotspot.x, hotspot.y, hotspot.w, hotspot.h)
    end

    -- outline actors
    for _, actor in ipairs(actors.list) do
        if actor.isactor then
			love.graphics.setColor (self.actorColor)
            love.graphics.rectangle("line", actor.x - actor.feet[1], actor.y - actor.feet[2], actor.w, actor.h)
            love.graphics.circle("line", actor.x, actor.y, 1, 6)
        elseif actor.islayer then
            -- draw baselines for layers
			love.graphics.setColor (self.layerColor)
            love.graphics.line(0, actor.baseline, self.width, actor.baseline)
        end
    end

    love.graphics.pop ()

end


--~   __ _
--~  / _| | ___   ___  _ __ ___
--~ | |_| |/ _ \ / _ \| '__/ __|
--~ |  _| | (_) | (_) | |  \__ \
--~ |_| |_|\___/ \___/|_|  |___/


--- Clears all walkable floors.
function floors.clear (self)

	self.walkableMap = nil

end

--- Test if a walkable map is loaded
function floors.hasMap (self)

	return self.walkableMap ~= nil

end

function floors.set (self, filename)

	-- intercept chaining
	if chains.capturing then
		chains:add (floors.set, {self, filename})
		return
	end

	self:convert (filename)

end

--- Convert a walkable floor mask to a point map
-- Any non-black pixel is walkable.
--
-- @param self
-- Slime instance
--
-- @param filename
-- The floor map image filename
function floors.convert (self, filename)

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

--- Test if the floor point is walkable
-- Callback used by path finding.
-- @return true if the position is open to walk
function floors.isWalkable (x, y)

	if floors:hasMap () then
		-- clamp to floor boundary
		x = path:clamp (x, 1, floors.width - 1)
		y = path:clamp (y, 1, floors.height - 1)
		return floors.walkableMap[y][x]
	else
		-- no floor is always walkable
		return true
	end

end

--- Gets the size of the floor
function floors.size (self)

	if self.walkableMap then
		return self.width, self.height
	else
		-- without a floor map, we return the background size
		return backgrounds.width, backgrounds.height
	end

end


-- Find the nearest open point to the south, west, north or east.
-- Use the bresenham line algorithm to project four lines from the goal:
-- (S, W, N, E) and find the first open node on each line.
-- We then choose the point with the shortest distance from the goal.
function floors.findNearestOpenPoint (self, point)

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
        local walkTheLine = bresenham (direction, goal)
        local continueSearch = true
        while (continueSearch) do
            if (#walkTheLine == 0) then
                continueSearch = false
            else
                goal = table.remove(walkTheLine)
                continueSearch = not self.isWalkable (goal.x, goal.y)
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



--    _           _                   _
--   | |__   ___ | |_ ___ _ __   ___ | |_ ___
--   | '_ \ / _ \| __/ __| '_ \ / _ \| __/ __|
--   | | | | (_) | |_\__ \ |_) | (_) | |_\__ \
--   |_| |_|\___/ \__|___/ .__/ \___/ \__|___/
--                       |_|

function hotspots.clear (self)

	self.list = { }

end

function hotspots.add (self, name, x, y, w, h)

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


--    _
--   | | __ _ _   _  ___ _ __ ___
--   | |/ _` | | | |/ _ \ '__/ __|
--   | | (_| | |_| |  __/ |  \__ \
--   |_|\__,_|\__, |\___|_|  |___/
--            |___/
--
-- Layers define areas of the background that actors can walk behind.

--- Add a walk-behind layer.
function layers.add (self, background, mask, baseline)

    local newLayer = {
        ["image"] = self:convertMask (background, mask),
        ["baseline"] = baseline,
        islayer = true
        }

	-- layers are merged with actors so that we can perform
	-- efficient sorting, enabling drawing of actors behind layers.
    table.insert(actors.list, newLayer)

    actors:sortLayers()

end

--- Cut a shape out of an image.
-- All corresponding black pixels from the mask will cut and discard
-- pixels (they become transparent), and only non-black mask pixels
-- preserve the matching source pixels.
function layers.convertMask (self, source, mask)

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


--              _   _
--  _ __   __ _| |_| |__
-- | '_ \ / _` | __| '_ \
-- | |_) | (_| | |_| | | |
-- | .__/ \__,_|\__|_| |_|
-- |_|
--

--- Clear all cached paths
function path.clear (self)

    self.cache = nil

end

--- Gets a unique start/goal key
function path.keyOf (self, start, goal)

    return string.format("%d,%d>%d,%d", start.x, start.y, goal.x, goal.y)

end

-- Returns the cached path
function path.getCached (self, start, goal)

    if self.cache then
        local key = self:keyOf (start, goal)
        return self.cache[key]
    end

end

-- Saves a path to the cache
function path.saveCached (self, start, goal, path)

    self.cache = self.cache or { }
    local key = self:keyOf (start, goal)
    self.cache[key] = path

end

-- Get the distance between two points
-- This method doesn't bother getting the square root of s, it is faster
-- and it still works for our use.
function path.distance (self, x1, y1, x2, y2)

	local dx = x1 - x2
	local dy = y1 - y2
	local s = dx * dx + dy * dy
	return s

end

-- Clamp a value to a range.
function path.clamp (self, x, min, max)

	return x < min and min or (x > max and max or x)

end

-- (Internal) Return the score of a node.
-- G is the cost from START to this node.
-- H is a heuristic cost, in this case the distance from this node to the goal.
-- Returns F, the sum of G and H.
function path.calculateScore (self, previous, node, goal)

    local G = previous.score + 1
    local H = self:distance (node.x, node.y, goal.x, goal.y)
    return G + H, G, H

end

-- Returns true if the given list contains the specified item.
function path.listContains (self, list, item)
    for _, test in ipairs(list) do
        if test.x == item.x and test.y == item.y then
            return true
        end
    end
    return false
end

-- Returns the item in the given list.
function path.listItem (self, list, item)
    for _, test in ipairs(list) do
        if test.x == item.x and test.y == item.y then
            return test
        end
    end
end

-- Requests adjacent map values around the given node.
function path.getAdjacent (self, width, height, node, positionIsOpenFunc)

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

    for _, point in ipairs(positions) do
        local px = self:clamp (node.x + point.x, 1, width)
        local py = self:clamp (node.y + point.y, 1, height)
        local value = positionIsOpenFunc( px, py )
        if value then
            table.insert( result, { x = px, y = py  } )
        end
    end

    return result

end

-- Returns the path from start to goal, or false if no path exists.
function path.find (self, width, height, start, goal, positionIsOpenFunc, useCache)

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
    start.H = self:distance (start.x, start.y, goal.x, goal.y)
    start.parent = { x = 0, y = 0 }
    table.insert(open, start)

    while not success and #open > 0 do

        -- sort by score: high to low
        table.sort(open, function(a, b) return a.score > b.score end)

        local current = table.remove(open)

        table.insert(closed, current)

        success = self:listContains (closed, goal)

        if not success then

            local adjacentList = self:getAdjacent (width, height, current, positionIsOpenFunc)

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




--                           _
--  ___ _ __   ___  ___  ___| |__
-- / __| '_ \ / _ \/ _ \/ __| '_ \
-- \__ \ |_) |  __/  __/ (__| | | |
-- |___/ .__/ \___|\___|\___|_| |_|
--     |_|

--- Clears all current or queued speeches
function speech.clear (self)

	self.queue = { }

end

--- Make an actor say something
--
-- @param self
-- Slime instance
--
-- @param name
-- Name of the actor
--
-- @param text
-- The words to display
--
-- @param time
-- Number of seconds to display the words.
-- Optional. Defaults to 3 seconds.
function speech.say (self, name, text, seconds)

	-- intercept chaining
	if chains.capturing then
		debug:append (string.format("chaining %s say", name))
		chains:add (speech.say,
					{self, name, text, seconds},
					-- expires when actor is not talking
					function (parameters)
						return not speech:talking (parameters[2])
					end
					)
		return
	end

    local newSpeech = {
        ["actor"] = actors:get (name),
        ["text"] = text,
        ["time"] = seconds or 3
        }

    if (not newSpeech.actor) then
        debug:append ("Speech failed: No actor named " .. name)
        return
    end

    table.insert(self.queue, newSpeech)

end

--- Returns if an actor is busy talking
--
-- @param self
-- Slime instance
--
-- @param actor
-- Optional name of the actor to test against.
-- If not given, any talking actor is tested.
--
-- @return true if any actor, or the specified actor is talking.
function speech.talking (self, actor)

	if actor then
		-- if a specific actor is talking
		return self.queue[1] and self.queue[1].actor.name == actor
	else
		-- if any actor is talking
		return (#self.queue > 0)
	end

end

--- Skips the current spoken line.
function speech.skip (self)

    local speech = self.queue[1]

    if (speech) then

		-- remove the line
        table.remove(self.queue, 1)

        -- restore the actor animation to idle
        speech.actor.action = "idle"

        -- clear the current spoken line
        self.currentLine = nil

        -- notify speech ended event
        events.speech (slime, speech.actor, false, true)

    end

end

--- Update spoken words
--
-- @param self
-- Slime instance
--
-- @param dt
-- Time Delta since the last update
function speech.update (self, dt)

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

--- Draw spoken words on screen.
function speech.draw (self)

    if (#self.queue > 0) then
        local spc = self.queue[1]
        if settings["builtin text"] then

            -- Store the original color
            local r, g, b, a = love.graphics.getColor()

            local y = settings["speech position"]
            local w = love.graphics.getWidth() / scale

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



--      _ _
--  ___| (_)_ __ ___   ___
-- / __| | | '_ ` _ \ / _ \
-- \__ \ | | | | | | |  __/
-- |___/_|_|_| |_| |_|\___|
--

function slime.update (self, dt)

	chains:update (dt)
    backgrounds:update (dt)
	actors:update (dt)
	speech:update (dt)

end


function slime.draw (self, scale)

    scale = scale or 1

    -- reset draw color
    love.graphics.setColor (1, 1, 1)

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
        local w = love.graphics.getWidth() / scale
        love.graphics.setFont(settings["status font"])
        -- Outline
        love.graphics.setColor({0, 0, 0, 255})
        love.graphics.printf(self.statusText, 1, y+1, w, "center")
        love.graphics.setColor({255, 255, 255, 255})
        love.graphics.printf(self.statusText, 0, y, w, "center")
    end

	speech:draw ()
	cursor:draw ()

end

-- Gets the object under xy.
function slime.getObjects (self, x, y)

    local objects = { }

    for _, actor in pairs(actors.list) do
        if actor.isactor and
            (x >= actor.x - actor.feet[1]
            and x <= actor.x - actor.feet[1] + actor.w)
        and (y >= actor.y - actor.feet[2]
            and y <= actor.y - actor.feet[2] + actor.h) then
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

function slime.interact (self, x, y)

    local objects = self:getObjects(x, y)
    if (not objects) then return end

	local cursorname = cursor:getName ()

    for i, object in pairs(objects) do
		debug:append (cursorname .. " on " .. object.name)

		-- notify the interact callback
		events.interact (self, cursorname, object)

		-- OBSOLETE: slime.callback replaced by events
        slime.callback (cursorname, object)
    end

    return true

end


--~           _   _   _
--~  ___  ___| |_| |_(_)_ __   __ _ ___
--~ / __|/ _ \ __| __| | '_ \ / _` / __|
--~ \__ \  __/ |_| |_| | | | | (_| \__ \
--~ |___/\___|\__|\__|_|_| |_|\__, |___/
                          --~ |___/

--- Clears slime settings to defaults.
function settings.clear (self)

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


--~              _
--~   __ _ _ __ (_)
--~  / _` | '_ \| |
--~ | (_| | |_) | |
--~  \__,_| .__/|_|
--~       |_|


--- Clears backgrounds, actors, floors and layers.
function slime.clear (self)

    actors:clear ()
    backgrounds:clear ()
    chains:clear ()
    debug:clear ()
    floors:clear ()
    hotspots:clear ()
    speech:clear ()
    self.statusText = nil

end

--- Analagous to clear() and additionally also clears
-- slime settings and persistent data.
function slime.reset (self)

	self:clear ()
	settings:clear ()

end


--~        _               _      _
--~   ___ | |__  ___  ___ | | ___| |_ ___
--~  / _ \| '_ \/ __|/ _ \| |/ _ \ __/ _ \
--~ | (_) | |_) \__ \ (_) | |  __/ ||  __/
--~  \___/|_.__/|___/\___/|_|\___|\__\___|
--~

--- Clears the room and actors.
-- TODO rename to clear
function slime.reset (self)
	print ("slime.reset will be obsoleted. Use slime:clear() instead.")
	self:clear ()
end

function slime.callback (event, object)
end

function slime.animationLooped (actor, key, counter)
end

function slime.onDrawSpeechCallback(actorX, actorY, speechcolor, words)
end

function slime.background (self, ...)

	backgrounds:add (...)

end

-- OBSOLETE IN FUTURE
function slime.setCursor (self, ...)

	print ("slime.setCursor will be obsoleted, use slime.cursor:set()")
	cursor:set (...)

end

--- Loads the cursors as a spritemap, w and h is the size of each quad
-- OBSOLETE IN FUTURE
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

-- Uses a preloaded cursor
-- OBSOLETE IN FUTURE
function slime.useCursor (self, index)
	--print ("slime.useCursor will be obsoleted, use slime.cursor:set()")
    cursor.current = index
end

function slime.getCursor (self)
	print ("slime.getCursor will be obsoleted")
    return self.cursor.current
end

-- Set the floor mask that determines walkable areas.
function slime.floor (self, filename)

	print ("slime.floors will be obsoleted, use slime.floors:set()")
	floors:set (filename)

end


function slime.actor (self, ...)

	print ("slime.actor will be obsoleted, use slime.actors:add()")
	return actors:add (...)

end


-- Gets the actor by name
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


-- Helper method to add an animation to an actor
-- OBSOLETE IN FUTURE
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

-- A helper method to define frames against an animation object.
-- OBSOLETE IN FUTURE
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

-- OBSOLETE IN FUTURE
function slime.defineFrames (self, frames)
    self.framesDefinition = frames
    return self
end

-- OBSOLETE IN FUTURE
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

-- OBSOLETE IN FUTURE
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

-- OBSOLETE IN FUTURE
function slime.defineOffset (self, x, y)
    self._offset = {x=x, y=y}
    return self
end

-- OBSOLETE IN FUTURE
function slime.defineFlip (self)
    self._frames:flipH()
    return self
end

-- OBSOLETE IN FUTURE
function slime.setAnimation (self, name, key)

	-- intercept chaining
	if chains.capturing then
		chains:add (slime.setAnimation, {self, name, key})
		return
	end

    local actor = self:getActor(name)

    if (not actor) then
        debug:append ("Set animation failed: no actor named " .. name)
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


-- Gets the duration of a given animation
-- OBSOLETE IN FUTURE
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


-- Set a static image as an actor's sprite.
-- OBSOLETE IN FUTURE
function slime.setImage (self, image)

    local actor = self

    if (not actor) then
        debug:append ("slime.Image method should be called from an actor instance")
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

-- Stops an actor from moving
function slime.stopActor (self, ...)

	-- OBSOLETE IN FUTURE
	print ("slime.stopActor will be obsoleted, use slime.actors:stop()")
	actors:stop (...)

end


function slime.say (self, name, text)

	print ("slime.say will be obsoleted, use slime.speech:say()")
	speech:say (name, text)

end


-- Checks if there is an actor talking.
-- OBSOLETE IN FUTURE
function slime.someoneTalking (self)

	print ("slime.someoneTalking will be obsoleted, use slime.speech:talking()")
	return speech:talking ()

end


-- Checks if specific actor is talking
-- OBSOLETE IN FUTURE
function slime.actorTalking (self, actor)

	print ("slime.actorTalking will be obsoleted, use slime.speech:talking()")
	return speech:talking (actor)

end


-- Skips the current speech
-- OBSOLETE IN FUTURE
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


-- OBSOLETE IN FUTURE
slime.bagButtons = { }

-- Placeholder for the inventory changed callback
function slime.inventoryChanged ( )
	-- OBSOLETE IN FUTURE
	-- replace with the future room structure
end

-- Add an item to a bag.
function slime.bagInsert (self, ...)

	print ("slime.bagInsert will be obsoleted, use slime.bags:add()")
	bags:add (...)

end

-- Get items from a bag.
-- OBSOLETE IN FUTURE
function slime.bagContents (self, bag)

	print ("slime.bagContents will be obsoleted, use slime.bags.contents[<key>]")
    return bags.contents[bag] or { }

end

-- Checks if an item is inside a bag
function slime.bagContains (self, ...)
	print ("slime.bagContains will be obsoleted, use slime.bags:contains()")
	return bags:contains (...)
end

-- Remove an item from a bag.
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

-- Set a status text
function slime.status (self, text)

	--print ("slime.status will be obsoleted")
    self.statusText = text

end





slime.tilesets = {}

-- Internal callback fired on any animation loop
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



-- Cache a tileset image in slime, or return an already cached one.
function slime.cache (self, path)

    -- cache tileset image to save loading duplicate images
    local image = self.tilesets[path]

    if not image then
        image = love.graphics.newImage(path)
        self.tilesets[path] = image
    end

    return image

end




                            --~ _
--~   _____  ___ __   ___  _ __| |_
--~  / _ \ \/ / '_ \ / _ \| '__| __|
--~ |  __/>  <| |_) | (_) | |  | |_
--~  \___/_/\_\ .__/ \___/|_|   \__|
          --~ |_|


-- Clear these components on load
-- Warning! these will call on every require.
cursor:clear ()
bags:clear ()
settings:clear ()

slime.actors = actors
slime.backgrounds = backgrounds
slime.bags = bags
slime.chain = chains
slime.cursor = cursor
slime.debug = debug
slime.events = events
slime.floors = floors
slime.layers = layers
slime.settings = settings
slime.speech = speech
slime.wait = chains.wait

return slime

