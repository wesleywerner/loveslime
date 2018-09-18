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

-- Uses Lua A* by GloryFish
-- https://github.com/GloryFish/lua-astar
require 'slime.slimemaphandler'

-- bresenham line algorithm
require 'slime.bresenham'

-- Uses anim8 by Enrique García Cota
-- https://github.com/kikito/anim8
local anim8 = require 'slime.anim8'

local actors = { }
local backgrounds = { }
local bags = { }
local events = { }
local debug = { }
local cursor = { }
local hotspots = { }
local floors = { }
local layers = { }
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

            if self:moveActorOnPath (actor, dt) then
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

function actors.moveActorOnPath (self, actor, dt)

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

        local point = table.remove(actor.path)
        if (point) then
            actor.x, actor.y = point.location.x, point.location.y
            -- Test if we should calculate actor direction
            actor["direction recalc delay"] = actor["direction recalc delay"] - 1
            if (actor["direction recalc delay"] <= 0) then
                actor["direction recalc delay"] = 5
                actor.direction = self:calculateDirection(actor.lastx, actor.lasty, actor.x, actor.y)
                actor.lastx, actor.lasty = actor.x, actor.y
            end
        end

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

    if (floors.astar == nil) then
        debug:append ("No walkable area defined")
        return
    end

    local actor = self:get(name)

    if (actor == nil) then
        debug:append ("No actor named " .. name)
    else
        -- Our path runs backwards so we can pop the points off the stack
        local start = { x = actor.x, y = actor.y }
        local goal = { x = x, y = y }

        -- If the goal is on a solid block find the nearest open node.
        if (floors.handler:nodeBlocking(goal)) then
            goal = floors:findNearestOpenPoint (goal)
        end

        -- Calculate a path
        local path = floors.astar:findPath(goal, start)
        if (path == nil) then
            debug:append ("no actor path found")
        else
            actor.clickedX = x
            actor.clickedY = y
            actor.path = path:getNodes()
            -- Default to walking animation
            actor.action = "walk"
            -- Calculate actor direction immediately
            actor.lastx, actor.lasty = actor.x, actor.y
            actor.direction = self:calculateDirection(actor.x, actor.y, x, y)
            -- Output debug
            debug:append ("move " .. name .. " to " .. x .. " : " .. y)
        end
    end

end

function actors.turn (self, name, direction)

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

--                       _
--   _____   _____ _ __ | |_ ___
--  / _ \ \ / / _ \ '_ \| __/ __|
-- |  __/\ V /  __/ | | | |_\__ \
--  \___| \_/ \___|_| |_|\__|___/
--

--- Callback when an actor reached their destination.
--
-- @param self
-- The slime instance
--
-- @param actor
-- The actor that moved
function events.moved (self, actor)

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

	self.astar = nil

end

function floors.set (self, filename)

    self.handler = SlimeMapHandler()
    self.handler:convert(filename)
    self.astar = AStar(self.handler)

end


-- Find the nearest open point to the south, west, north or east.
-- Use the bresenham line algorithm to project four lines from the goal:
-- (S, W, N, E) and find the first open node on each line.
-- We then choose the point with the shortest distance from the goal.
function floors.findNearestOpenPoint (self, point)

    -- Get the dimensions of the walkable floor map.
    local size = floors.handler:size()

    -- Define the cardinal direction to test against relative to the point.
    local directions = {
        { ["x"] = point.x, ["y"] = size.h },    -- S
        { ["x"] = 1, ["y"] = point.y },         -- W
        { ["x"] = point.x, ["y"] = 1 },         -- N
        { ["x"] = size.w, ["y"] = point.y }     -- E
        }

    -- Stores the four directional points found and their distance.
    local foundPoints = { }

    for idirection, direction in pairs(directions) do
        local goal = point
        local walkTheLine = bresenham (direction, goal)
        local findNearestPoint = true
        while (findNearestPoint) do
            if (#walkTheLine == 0) then
                findNearestPoint = false
            else
                goal = table.remove(walkTheLine)
                findNearestPoint = floors.handler:nodeBlocking(goal)
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


--~                           _
--~  ___ _ __   ___  ___  ___| |__
--~ / __| '_ \ / _ \/ _ \/ __| '_ \
--~ \__ \ |_) |  __/  __/ (__| | | |
--~ |___/ .__/ \___|\___|\___|_| |_|
--~     |_|

--- Clears all current or queued speeches
function speech.clear (self)

	self.queue = { }

end

--- Make an actor say something
function speech.say (self, name, text)

    local newSpeech = {
        ["actor"] = slime:getActor(name),
        ["text"] = text,
        ["time"] = 3
        }

    if (not newSpeech.actor) then
        debug:append ("Speech failed: No actor named " .. name)
        return
    end

    table.insert(self.queue, newSpeech)

end

--- Returns if any actor is busy talking
function speech.talking (self, actor)

	if actor then
		-- if a specific actor is talking
		return self.queue[1] and self.queue[1].actor.name == actor
	else
		-- if any actor is talking
		return (#self.queue > 0)
	end

end

function speech.skip (self)

    local spc = self.queue[1]
    if (spc) then
        table.remove(self.queue, 1)
        spc.actor.action = "idle"
    end
end

function speech.update (self, dt)

    -- Update the speech display time.
    if (#self.queue > 0) then
        local spc = self.queue[1]
        spc.time = spc.time - dt
        if (spc.time < 0) then
            self:skip ()
        else
            spc.actor.action = "talk"
            if not settings["walk and talk"] then
                spc.actor.path = nil
            end
        end
    end

end

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



--        _
--     __| |_ __ __ ___      __
--    / _` | '__/ _` \ \ /\ / /
--   | (_| | | | (_| |\ V  V /
--    \__,_|_|  \__,_| \_/\_/

function slime.update (self, dt)

    backgrounds:update (dt)
	actors:update (dt)
	speech:update (dt)

    -- Update chained actions
    self:updateChains(dt)

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


--      _           _
--  ___| |__   __ _(_)_ __  ___
-- / __| '_ \ / _` | | '_ \/ __|
--| (__| | | | (_| | | | | \__ \
-- \___|_| |_|\__,_|_|_| |_|___/

-- Provides ways to chain actions to run in sequence

slime.chains = { queue={}, current=nil}

function slime.chain(self)

    local thischain = {}
    table.insert(self.chains.queue, thischain)
    return {
        slime = self,
        ref = thischain,
        image = slime.chainImage,
        move = slime.chainMove,
        turn = slime.chainTurn,
        wait = slime.chainWait,
        anim = slime.chainAnim,
        floor = slime.chainFloor,
        func = slime.chainFunc,
        say = slime.chainSay,
        sound = slime.chainSound,
        }
end

function slime.chainImage (self, actor, path)
    table.insert(self.ref, {method="image", actor=actor, path=path})
end

function slime.chainMove (self, actor, position, y)
    if type(position) == "number" then
        position = {x=position, y=y}
    end
    table.insert(self.ref, {method="move", actor=actor, position=position})
end

function slime.chainTurn (self, actor, direction)
    table.insert(self.ref, {method="turn", actor=actor, direction=direction})
end

function slime.chainWait (self, duration)
    table.insert(self.ref, {method="wait", duration=duration})
end

function slime.chainAnim (self, actor, key, wait)
    table.insert(self.ref, {method="anim", actor=actor, key=key})
    -- if wait is true, wait for the duration of the animation
    if wait then
        local duration = self.slime:animationDuration(actor, key)
        self:wait(duration)
    end
end

function slime.chainFloor (self, path)
    table.insert(self.ref, {method="floor", path=path})
end

function slime.chainFunc (self, func, params)
    table.insert(self.ref, {method="func", func=func, params=params})
end

function slime.chainSay (self, actor, words)
    table.insert(self.ref, {method="talk", actor=actor, words=words})
end

function slime.chainSound (self, source)
    if type(source) == "string" then
        source = love.audio.newSource(source, "static")
    end
    table.insert(self.ref, {method="sound", source=source})
end


function slime.updateChains (self, dt)

    -- process the first link in each chain
    for cidx, chain in pairs(self.chains.queue) do

        local link = chain[1] or {}
        local expired = false

        -- Action this link (one-time only)
        if not link.processed then
            link.processed = true
            if link.method == "image" then
                local actor = self:getActor(link.actor)
                if actor then actor:setImage(link.path) end
            elseif link.method == "floor" then
                self:floor(link.path)
            elseif link.method == "move" then
                if type(link.position) == "string" then
                    self:moveActorTo(link.actor, link.position)
                else
                    self:moveActor(link.actor, link.position.x, link.position.y)
                end
            elseif link.method == "turn" then
                self:turnActor(link.actor, link.direction)
            elseif link.method == "talk" then
                self:say(link.actor, link.words)
            elseif link.method == "wait" then
                -- no action
            elseif link.method == "anim" then
                self:setAnimation(link.actor, link.key)
            elseif link.method == "func" then
                link.func(unpack(link.params or {}))
            elseif link.method == "sound" then
                love.audio.play(link.source)
            end
        end

        -- Test if the link expires
        if link.method == "image" then
            expired = true
        elseif link.method == "floor" then
            expired = true
        elseif link.method == "move" then
            -- skip link if not actor exists
            local actor = self:getActor(link.actor)
            if not actor then
                expired = true
            elseif not actor.path then
                expired = true
            end
        elseif link.method == "turn" then
            expired = true
        elseif link.method == "talk" then
            if not self:actorTalking(link.actor) then
                expired = true
            end
        elseif link.method == "wait" then
            link.duration = link.duration - dt
            expired = link.duration < 0
        elseif link.method == "anim" then
            expired = true
        elseif link.method == "func" then
            expired = true
        elseif link.method == "sound" then
            expired = true
        end

        -- remove expired links
        if expired and #chain > 0 then
            table.remove(chain, 1)
        end

        -- remove empty chains
        if #chain == 0 then
            table.remove(self.chains.queue, cidx)
        end

    end

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
slime.cursor = cursor
slime.debug = debug
slime.events = events
slime.floors = floors
slime.layers = layers
slime.settings = settings

return slime

