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

local backgrounds = { }
local settings = { }

function slime.reset (self)
	settings:clear ()
    backgrounds:clear ()
    self.actors = {}
    self.debug.log = {}
    self.hotspots = {}
    self.astar = nil
    self.statusText = nil
end

slime.cursor = { ["quads"] = {}, ["names"] = {} }

function slime.callback (event, object)
end

function slime.animationLooped (actor, key, counter)
end

function slime.onDrawSpeechCallback(actorX, actorY, speechcolor, words)
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

-- Expose the API
function slime.background (self, ...)

	backgrounds:add (...)

end



--~   __ _
--~  / _| | ___   ___  _ __ ___
--~ | |_| |/ _ \ / _ \| '__/ __|
--~ |  _| | (_) | (_) | |  \__ \
--~ |_| |_|\___/ \___/|_|  |___/


-- Set the floor mask that determines walkable areas.
function slime.floor (self, floorfilename)
    self.handler = SlimeMapHandler()
    self.handler:convert(floorfilename)
    self.astar = AStar(self.handler)
end



--               _
--     __ _  ___| |_ ___  _ __ ___
--    / _` |/ __| __/ _ \| '__/ __|
--   | (_| | (__| || (_) | |  \__ \
--    \__,_|\___|\__\___/|_|  |___/

slime.actors = {}
slime.tilesets = {}

function slime.actor (self, name, x, y)

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
        ["base"] = {0, 0},                  -- image draw offset vs actor x/y
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

    table.insert(self.actors, newActor)

    -- set actor image method
    newActor.setImage = slime.setImage

    -- set the actor new animation method
    newActor.tileset = slime.defineTileset

    -- set slime host reference
    newActor.host = self

    self:sortLayers()

    return newActor
end


-- Gets the actor by name
function slime.getActor (self, name)
    for _, actor in ipairs(self.actors) do
        if actor.name == name then
            return actor
        end
    end
end


-- Internal callback fired on any animation loop
function slime.internalAnimationLoop (frames, counter)
    local pack = frames.pack
    pack.loopcounter = pack.loopcounter + 1
    if pack.loopcounter > 255 then
        pack.loopcounter = 0
    end
    slime.animationLooped (pack.anim.actor.name, pack.key, pack.loopcounter)
end



function slime.removeActor (self, name)
    for i, actor in ipairs(self.actors) do
        if actor.name == name then
            table.remove(self.actors, i)
            return true
        end
    end
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


-- Helper method to add an animation to an actor
function slime.defineTileset (self, tileset, size)

    local actor = self

    -- cache tileset image to save loading duplicate images
    actor.host:cache(tileset)

    -- default actor hotspot to centered at the base of the image
    actor["w"] = size.w
    actor["h"] = size.h
    actor["base"] = { size.w / 2, size.h }

    return {
        actor = actor,
        tileset = tileset,
        size = size,
        define = slime.defineAnimation
        }

end

-- A helper method to define frames against an animation object.
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

    local image = self.anim.actor.host:cache(self.anim.tileset)

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

-- Helper method to flip defined animations
function slime.defineFlip (self)
    self._frames:flipH()
    return self
end

-- Set the animation of an actor
function slime.setAnimation (self, name, key)

    local actor = self:getActor(name)

    if (not actor) then
        self:log ("Set animation failed: no actor named " .. name)
    else
        actor.customAnimationKey = key
        -- reset the animation counter
        local anim = actor:getAnim()
        if anim then
            anim.loopcounter = 0
            -- Recalculate the actor's base offset
            local size = anim.anim.size
            actor["w"] = size.w
            actor["h"] = size.h
            actor["base"] = { size.w / 2, size.h }
        end
    end

end


-- Gets the duration of a given animation
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
function slime.setImage (self, image)

    local actor = self

    if (not actor) then
        self:log ("slime.Image method should be called from an actor instance")
    else
        image = love.graphics.newImage(image)
        actor.image = image
        actor.w = image:getWidth()
        actor.h = image:getHeight()
        actor.base = { actor.w/2, actor.h }
    end

end

function slime.drawActor (self, actor)

    local anim = actor:getAnim()

    if anim then
        local tileset = self:cache(anim.anim.tileset)
        anim._frames:draw(tileset,
            actor.x - actor.base[1] + anim._offset.x,
            actor.y - actor.base[2] + anim._offset.y)
    elseif (actor.image) then
        love.graphics.draw(actor.image,
            actor.x - actor.base[1],
            actor.y - actor.base[2])
    else
        love.graphics.rectangle ("fill", actor.x - actor.base[1], actor.y - actor.base[2], actor.w, actor.h)
    end

end

function slime.turnActor (self, name, direction)

    local actor = self:getActor(name)

    if (actor) then
        actor.direction = direction
    end

end

function slime.moveActor (self, name, x, y)

    -- Move an actor to point xy using A Star path finding

    if (self.astar == nil) then
        self:log("No walkable area defined")
        return
    end

    local actor = self:getActor(name)

    if (actor == nil) then
        self:log("No actor named " .. name)
    else
        -- Our path runs backwards so we can pop the points off the stack
        local start = { x = actor.x, y = actor.y }
        local goal = { x = x, y = y }

        -- If the goal is on a solid block find the nearest open node.
        if (self.handler:nodeBlocking(goal)) then
            goal = self:findNearestOpenPoint (goal)
        end

        -- Calculate a path
        local path = self.astar:findPath(goal, start)
        if (path == nil) then
            self:log("no actor path found")
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
            self:log("move " .. name .. " to " .. x .. " : " .. y)
        end
    end
end

-- Find the nearest open point to the south, west, north or east.
-- Use the bresenham line algorithm to project four lines from the goal:
-- (S, W, N, E) and find the first open node on each line.
-- We then choose the point with the shortest distance from the goal.
function slime.findNearestOpenPoint (self, point)

    -- Get the dimensions of the walkable floor map.
    local size = self.handler:size()

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
                findNearestPoint = self.handler:nodeBlocking(goal)
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

-- Move an actor to another actor
function slime.moveActorTo (self, name, target)

    local targetActor = self:getActor(target)

    if (targetActor) then
        self:moveActor (name, targetActor.x, targetActor.y)
    else
        self:log("no actor named " .. target)
    end
end


function slime.moveActorOnPath (self, actor, dt)
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
            actor.path = nil
            actor.action = "idle"
            self.callback ("moved", actor)
        end
    end
end


-- Return the nearest cardinal direction represented by the angle of movement.
function slime.calculateDirection (self, x1, y1, x2, y2)

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


-- Stops an actor from moving
function slime.stopActor (self, name)
    local actor = self:getActor(name)
    if actor then
        actor.path = nil
    end
end


--        _ _       _
--     __| (_) __ _| | ___   __ _ _   _  ___
--    / _` | |/ _` | |/ _ \ / _` | | | |/ _ \
--   | (_| | | (_| | | (_) | (_| | |_| |  __/
--    \__,_|_|\__,_|_|\___/ \__, |\__,_|\___|
--                          |___/

slime.speech = { }


-- Make an actor say something
function slime.say (self, name, text)

    local newSpeech = {
        ["actor"] = self:getActor(name),
        ["text"] = text,
        ["time"] = 3
        }

    if (not newSpeech.actor) then
        self:log("Speech failed: No actor named " .. name)
        return
    end

    table.insert(self.speech, newSpeech)

end


-- Checks if there is an actor talking.
function slime.someoneTalking (self)

    return (#self.speech > 0)

end


-- Checks if specific actor is talking
function slime.actorTalking (self, actor)
    return self.speech[1] and self.speech[1].actor.name == actor
end


-- Skips the current speech
function slime.skipSpeech (self)

    local spc = self.speech[1]
    if (spc) then
        table.remove(self.speech, 1)
        spc.actor.action = "idle"
    end

end

--    _
--   | | __ _ _   _  ___ _ __ ___
--   | |/ _` | | | |/ _ \ '__/ __|
--   | | (_| | |_| |  __/ |  \__ \
--   |_|\__,_|\__, |\___|_|  |___/
--            |___/
--
-- Layers define areas of the background that actors can walk behind.


function slime.layer (self, background, mask, baseline)

    local newLayer = {
        ["image"] = self.createLayer(self, background, mask),
        ["baseline"] = baseline,
        islayer = true
        }

    table.insert(self.actors, newLayer)

end

function slime:createLayer (source, mask)

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

--    _           _                   _
--   | |__   ___ | |_ ___ _ __   ___ | |_ ___
--   | '_ \ / _ \| __/ __| '_ \ / _ \| __/ __|
--   | | | | (_) | |_\__ \ |_) | (_) | |_\__ \
--   |_| |_|\___/ \__|___/ .__/ \___/ \__|___/
--                       |_|

slime.hotspots = { }

function slime.hotspot(self, name, x, y, w, h)
    local hotspot = {
        ["name"] = name,
        ["x"] = x,
        ["y"] = y,
        ["w"] = w,
        ["h"] = h
    }
    table.insert(self.hotspots, hotspot)
    return hotspot
end

--    _                      _
--   (_)_ ____   _____ _ __ | |_ ___  _ __ _   _
--   | | '_ \ \ / / _ \ '_ \| __/ _ \| '__| | | |
--   | | | | \ V /  __/ | | | || (_) | |  | |_| |
--   |_|_| |_|\_/ \___|_| |_|\__\___/|_|   \__, |
--                                         |___/

-- Stores bags and their contents.
slime.bags = { }
slime.bagButtons = { }

-- Placeholder for the inventory changed callback
function slime.inventoryChanged ( )

end

-- Add an item to a bag.
function slime.bagInsert (self, bag, object)

    -- load the image data
    if type(object.image) == "string" then
        object.image = love.graphics.newImage(object.image)
    end

    -- Add the inventory item under "name"
    if (not self.bags[bag]) then self.bags[bag] = { } end
    local inv = self.bags[bag]
    table.insert(inv, object)
    self.inventoryChanged (bag)

    self:log ("Added " .. object.name .. " to bag \"" .. bag .. "\"")

end

-- Get items from a bag.
function slime.bagContents (self, bag)

    return self.bags[bag] or { }

end

-- Checks if an item is inside a bag
function slime.bagContains (self, bag, item)
    local bago = self:bagContents(bag)
    for _, v in pairs(bago) do
        if v.name == item then
            return true
        end
    end
end

-- Remove an item from a bag.
function slime.bagRemove (self, bag, name)

    local inv = self.bags[bag]
    if (inv) then
        for i, item in pairs(inv) do
            if (item.name == name) then
                table.remove(inv, i)
                self:log ("Removed " .. name .. " from bag \"" .. bag .. "\"")
                self.inventoryChanged (bag)
            end
        end
    end

end

function slime.bagButton (self, name, image, x, y)

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


--        _
--     __| |_ __ __ ___      __
--    / _` | '__/ _` \ \ /\ / /
--   | (_| | | | (_| |\ V  V /
--    \__,_|_|  \__,_| \_/\_/

function slime.update (self, dt)

    backgrounds:update (dt)

    self:sortLayers()

    -- Update animations
    for _, actor in ipairs(self.actors) do
        if actor.isactor then
            self:moveActorOnPath (actor, dt)
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

    -- Update the speech display time.
    if (#self.speech > 0) then
        local spc = self.speech[1]
        spc.time = spc.time - dt
        if (spc.time < 0) then
            self:skipSpeech()
        else
            spc.actor.action = "talk"
            if not settings["walk and talk"] then
                spc.actor.path = nil
            end
        end
    end

    -- Update chained actions
    self:updateChains(dt)

end


-- Sort actors and layers for correct zorder drawing
function slime.sortLayers (self)
    table.sort(self.actors, function (a, b)
            local m = a.isactor and a.y or a.baseline
            local n = b.isactor and b.y or b.baseline
            if a.isactor and a.nozbuffer then m = 10000 end
            if b.isactor and b.nozbuffer then n = 10001 end
            return m < n
            end)
end


function slime.draw (self, scale)

    scale = scale or 1

    backgrounds:draw ()

    for _, o in ipairs(self.actors) do
        if o.isactor then
            self:drawActor(o)
        elseif o.islayer then
            love.graphics.draw(o.image, 0, 0)
        end
    end

    -- Bag Buttons
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

    -- Draw Speech
    if (#self.speech > 0) then
        local spc = self.speech[1]
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

    self:outlineStageElements()

    -- Draw Cursor
    local quad = self.cursor.quads[self.cursor.current]

    if quad then

        local x, y = love.mouse.getPosition()
        x = x / scale
        y = y / scale

        if self.cursor.custom then
            local cursorhotspot = self.cursor.custom.hotspot
            love.graphics.draw(self.cursor.custom.image,
                x-cursorhotspot.x, y-cursorhotspot.y)
        else

            local cursorhotspot = self.cursor.hotspots[self.cursor.current]
            cursorhotspot = cursorhotspot or {x=0, y=0}
            love.graphics.draw(self.cursor.image, quad,
                x-cursorhotspot.x, y-cursorhotspot.y)
        end
    end

end

-- Set a status text
function slime.status (self, text)

    self.statusText = text

end

-- Gets the object under xy.
function slime.getObjects (self, x, y)

    local objects = { }

    for _, actor in pairs(self.actors) do
        if actor.isactor and
            (x >= actor.x - actor.base[1]
            and x <= actor.x - actor.base[1] + actor.w)
        and (y >= actor.y - actor.base[2]
            and y <= actor.y - actor.base[2] + actor.h) then
            table.insert(objects, actor)
        end
    end

    for ihotspot, hotspot in pairs(self.hotspots) do
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

    for i, object in pairs(objects) do
        local cursorname = self.cursor.custom and self.cursor.custom.name
        cursorname = cursorname or (self.cursor.names[self.cursor.current])
        self.callback (cursorname or "", object)
    end

    return true

end


-- Loads the cursors as a spritemap, w and h is the size of each quad
function slime.loadCursors (self, path, w, h, names, hotspots)

    self.cursor = {}
    self.cursor.names = names or {}
    self.cursor.hotspots = hotspots or {}
    self.cursor.image = love.graphics.newImage(path)
    self.cursor.quads = {}
    self.cursor.current = 1

    local imgwidth, imgheight = self.cursor.image:getDimensions()

    local totalImages = imgwidth / w

    for x = 1, totalImages do

        local quad = love.graphics.newQuad((x - 1) * w, 0,
            w, h, imgwidth, imgheight)

        table.insert(self.cursor.quads, quad)

    end

end


-- Uses a preloaded cursor
function slime.useCursor (self, index)
    self.cursor.current = index
end


function slime.getCursor (self)
    return self.cursor.current
end


-- Set a custom cursor.
function slime.setCursor (self, name, image, hotspot)

    if name then
        self.cursor.custom = {
            name=name,
            image=image,
            hotspot=hotspot or {x=0, y=0}
            }
    else
        self.cursor.custom = nil
    end

--    local cursor = nil
--    if (image) then
--        local w, h = image:getDimensions ()
--        local cursorCanvas = love.graphics.newCanvas (w * scale, h * scale)
--        cursorCanvas:renderTo(function()
--                love.graphics.draw (image, 0, 0, 0, scale, scale)
--            end)
--        cursor = love.mouse.newCursor (cursorCanvas:getImageData(),
--            hotx * scale, hoty * scale)
--    end
--    love.mouse.setCursor (cursor)
end

--        _      _
--     __| | ___| |__  _   _  __ _
--    / _` |/ _ \ '_ \| | | |/ _` |
--   | (_| |  __/ |_) | |_| | (_| |
--    \__,_|\___|_.__/ \__,_|\__, |
--                           |___/
-- Provides helpful debug information while building your game.

slime.debug = { ["enabled"] = true, ["log"] = {} }

function slime.log (self, text)
    -- add a debug log entry
    table.insert(self.debug.log, text)
    if (#self.debug.log > 10) then table.remove(self.debug.log, 1) end
end

function slime.debugdraw (self)

    if (not self.debug["enabled"]) then return end

    -- get the debug overlay image
    local debugOverlay = self.debug["overlay"]

    -- remember the original colour
    local r, g, b, a = love.graphics.getColor( )

    -- create a new overlay
    if (not debugOverlay) then
        debugOverlay = love.graphics.newCanvas( )
        debugOverlay:renderTo(function()
                local w = debugOverlay:getWidth()
                local h = debugOverlay:getHeight()
                love.graphics.setColor(0, 255, 0)
                love.graphics.rectangle( "line", 10, 10, w - 20, h - 20 )
                love.graphics.setFont( love.graphics.newFont( 12 ))
                love.graphics.print("SLIME DEBUG ON", 12, h - 26)
            end)
        self.debug["overlay"] = debugOverlay
    end

    -- draw the overlay
    love.graphics.draw(debugOverlay, 0, 0);

    -- print frame speed
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(tostring(love.timer.getFPS()) .. " fps", 12, 10)

    -- print background info
    if (self.counters["background index"] and self.counters["background delay"]) then
        love.graphics.print("background #" .. self.counters["background index"] .. " showing for " .. string.format("%.1f", self.counters["background delay"]) .. "s", 60, 10)
    end

    -- print info of everything under the pointer
    -- TODO

    -- log texts
    for i, n in pairs(self.debug.log) do
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.print(n, 11, 21 + (10 * i))
        love.graphics.setColor(0, 255, 0, 128)
        love.graphics.print(n, 10, 20 + (10 * i))
    end

    -- restore the original colour
    love.graphics.setColor(r, g, b, a)

end

function slime.outlineStageElements(self)

    if (not self.debug["enabled"]) then return end

    local r, g, b, a = love.graphics.getColor( )

    -- draw outlines of hotspots
    love.graphics.setColor(0, 0, 255, 64)
    for ihotspot, hotspot in pairs(self.hotspots) do
        love.graphics.rectangle("line", hotspot.x, hotspot.y, hotspot.w, hotspot.h)
    end

    -- Outline bag buttons
    love.graphics.setColor(255, 0, 255, 64)
    for counter, button in pairs(self.bagButtons) do
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h)
    end

    -- draw outlines of actors
    for _, actor in ipairs(self.actors) do
        if actor.isactor then
            love.graphics.setColor(0, 255, 0, 64)
            love.graphics.rectangle("line", actor.x - actor.base[1],
                actor.y - actor.base[2], actor.w, actor.h)
            love.graphics.circle("line", actor.x, actor.y, 1, 6)
        elseif actor.islayer then
            -- draw baselines for layers
            love.graphics.setColor(255, 0, 0, 64)
            love.graphics.line(0, actor.baseline,
                love.graphics.getHeight(), actor.baseline)
        end
    end

    love.graphics.setColor(r, g, b, a)

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

-- Export
slime.settings = settings


return slime

