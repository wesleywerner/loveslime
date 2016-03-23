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

slime.counters = {}

-- Store settings to customize the look of SLIME
slime.settings = {
    ["status position"] = 70,
    ["status font size"] = 12,
    ["speech position"] = 0,
    ["speech font size"] = 10
    }

function slime.reset (self)
    self.counters = {}
    self.backgrounds = {}
    self.actors = {}
    self.layers = {}
    self.debug.log = {}
    self.hotspots = {}
    self.astar = nil
    self.statusText = nil
    self.cursorName = nil
end

function slime.callback (event, object)
end

--                       _      
--    ___  ___ ___ _ __ (_) ___ 
--   / __|/ __/ _ \ '_ \| |/ __|
--   \__ \ (_|  __/ | | | | (__ 
--   |___/\___\___|_| |_|_|\___|


slime.backgrounds = {}

function slime.background (self, backgroundfilename, delay)

    -- Add a background to the stage, drawn at x, y for the given delay
    -- before drawing the next available background.
    -- If no delay is given, the background will draw forever.
    
    local image = love.graphics.newImage(backgroundfilename)
    
    newBackground = {
        ["image"] = image,
        ["delay"] = delay
        }
    
    table.insert(self.backgrounds, newBackground)
    
    -- default to the first background
    if (#self.backgrounds == 1) then
        self.counters["background index"] = 1
        self.counters["background delay"] = delay
    end
end

-- Set the floor mask that determines walkable areas.
function slime.floor (self, floorfilename)
    self.handler = SlimeMapHandler()
    floorimage = love.graphics.newImage(floorfilename)
    self.handler:convert(floorimage)
    self.astar = AStar(self.handler)
end

function slime.updateBackground (self, dt)

    -- Rotates to the next background if there is one and delay expired.
    
    if (#self.backgrounds <= 1) then
        -- skip background rotation if there is one or none
        return
    end

    local index = self.counters["background index"]
    local background = self.backgrounds[index]
    local timer = self.counters["background delay"]
    
    if (timer == nil or background == nil) then
        -- start a new timer
        index = 1
        timer = background.delay
    else
        timer = timer - dt
        -- this timer has expired
        if (timer < 0) then
            -- move to the next index (with wrapping)
            index = (index == #self.backgrounds) and 1 or index + 1
            if (self.backgrounds[index]) then
                timer = self.backgrounds[index].delay
            end
        end
    end

    self.counters["background index"] = index
    self.counters["background delay"] = timer

end


--               _                 
--     __ _  ___| |_ ___  _ __ ___ 
--    / _` |/ __| __/ _ \| '__/ __|
--   | (_| | (__| || (_) | |  \__ \
--    \__,_|\___|\__\___/|_|  |___/

slime.actors = {}
slime.tilesets = {}

function slime.actor (self, name, x, y, staticImage)

    -- Add an actor to the stage.
    -- Allows adding the same actor name multiple times, but only
    -- the first instance uses the "name" as the key, subsequent
    -- duplicates will use the natural numbering of the table.
    
    -- default sprite size
    local w = 10
    local h = 10
    
    local newActor = {
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
        if (self.customAnimationKey) then
            return self.animations[self.customAnimationKey]
        else
            local key = self.action .. " " .. self.direction
            return self.animations[key]
        end
    end
    
    if (self.actors[name]) then
        table.insert(self.actors, newActor)
    else
        self.actors[name] = newActor
    end
    
    if (staticImage) then
        self:addImage (name, staticImage)
    end
    
    return newActor
end

-- Helper functions to batch build actor animations
function slime.idleAnimation (self, name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    self:prefabAnimation ("idle", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

function slime.walkAnimation (self, name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    self:prefabAnimation ("walk", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

function slime.talkAnimation (self, name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    self:prefabAnimation ("talk", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

-- Create a prefabricated animation sequence of the cardinal directions.
-- Use the south direction (facing the player) as default if none of the other directions are given.
function slime.prefabAnimation (self, prefix, name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)

    self:addAnimation (name, prefix .. " south", tileset, w, h, south, southd)
    self:addAnimation (name, prefix .. " west", tileset, w, h, west or south, westd or southd)
    self:addAnimation (name, prefix .. " north", tileset, w, h, north or south, northd or southd)

    -- if the east animations is empty, flip the west animation if there is one
    if (not east and west) then
        local eastAnim = self:addAnimation (name, prefix .. " east", tileset, w, h, east or west, eastd or westd)
        eastAnim:flipH()
    else
        self:addAnimation (name, prefix .. " east", tileset, w, h, east or south, eastd or southd)
    end
end

-- Create a custom animation.
function slime.addAnimation (self, name, key, tileset, w, h, frames, delays, onLoop)

    local actor = self.actors[name]
    
    if (not actor) then
        self:log ("Add animation failed: no actor named " .. name)
        return
    end
    
    -- cache tileset image to save loading duplicate images
    local image = self.tilesets[tileset]
    if (not self.tilesets[tileset]) then
        image = love.graphics.newImage(tileset)
        self.tilesets[tileset] = image
    end

    -- default actor hotspot to centered at the base of the image
    actor["w"] = w
    actor["h"] = h
    actor["base"] = { w/2, h }
    
    local g = anim8.newGrid(w, h, image:getWidth(), image:getHeight())
    local animation = anim8.newAnimation(g(unpack(frames)), delays, onLoop)
    
    actor.animations[key] = { 
        ["tileset"] = tileset,
        ["animation"] = animation
        }
    
    --actor.customAnimationKey = key
    
    return animation
    
end

-- Set the animation of an actor
function slime.setAnimation (self, name, key)

    local actor = self.actors[name]
    
    if (not actor) then
        self:log ("Set animation failed: no actor named " .. name)
    else
        actor.customAnimationKey = key
    end
    
end

-- Set a static image as an actor's sprite.
function slime.addImage (self, name, image)

    local actor = self.actors[name]
    
    if (not actor) then
        self:log ("Add image failed: no actor named " .. name)
    else
        image = love.graphics.newImage(image)
        actor.image = image
        actor.w = image:getWidth()
        actor.h = image:getHeight()
        actor.base = { actor.w/2, actor.h }
    end
    
end

function slime.drawActor (self, actor)

    local animation = actor:getAnim()
    if (animation) then
        local tileset = self.tilesets[animation["tileset"]]
        animation["animation"]:draw(tileset, actor.x - actor.base[1], actor.y - actor.base[2])
    elseif (actor.image) then
        love.graphics.draw(actor.image, actor.x - actor.base[1], actor.y - actor.base[2])
    else
        love.graphics.rectangle ("fill", actor.x - actor.base[1], actor.y - actor.base[2], actor.w, actor.h)
    end

end

function slime.turnActor (self, name, direction)

    local actor = self.actors[name]

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
        
    local actor = self.actors[name]

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

    local targetActor = self.actors[target]
    
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


--        _ _       _                        
--     __| (_) __ _| | ___   __ _ _   _  ___ 
--    / _` | |/ _` | |/ _ \ / _` | | | |/ _ \
--   | (_| | | (_| | | (_) | (_| | |_| |  __/
--    \__,_|_|\__,_|_|\___/ \__, |\__,_|\___|
--                          |___/            

slime.speech = { }


-- Make an actor say something
function slime.addSpeech (self, name, text)

    local newSpeech = {
        ["actor"] = self.actors[name],
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


slime.layers = {}

function slime.layer (self, background, mask, baseline)

    local source = love.graphics.newImage(background)
    local mask = love.graphics.newImage(mask)
    
    local newLayer = { 
        ["image"] = slime:createLayer(source, mask),
        ["baseline"] = baseline
        }
    
    table.insert(self.layers, newLayer)
    
    -- Order the layers by their baselines.
    -- This is important for when we draw the layers.
    table.sort(self.layers, function (a, b) return a.baseline < b.baseline end )
    
end

function slime:createLayer (source, mask)

    -- Returns a copy of the source image with transparent pixels where
    -- the positional pixels in the mask are black.

    sourceW = source:getWidth()
    sourceH = source:getHeight()
    layerData = love.image.newImageData( sourceW, sourceH )
    maskData = mask:getData()
    
    -- copy the orignal
    layerData:paste(source:getData(), 0, 0, 0, 0, sourceW, sourceH)

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

    table.insert(self.hotspots, {
        ["name"] = name, 
        ["x"] = x, 
        ["y"] = y, 
        ["w"] = w, 
        ["h"] = h
    })

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

    self:updateBackground(dt)
    
    -- Update animations
    for iactor, actor in pairs(self.actors) do
        self:moveActorOnPath (actor, dt)
        local anim = actor:getAnim()
        if (anim and anim["animation"]) then
            anim["animation"]:update(dt)
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
        end
    end

end

function slime.draw (self, scale)

    scale = scale or 1

    -- Background
    local bg = self.backgrounds[self.counters["background index"]]
    if (bg) then
        love.graphics.draw(bg.image, 0, 0)
    end

    -- Layers
    -- layers are ordered by their baselines: smaller values first.
    -- for each layer, draw the actors above it, then draw the layer.
    local maxBaseline = 0
    for i, layer in pairs(self.layers) do
        for iactor, actor in pairs(self.actors) do
            if (actor.y) < layer.baseline then
                self:drawActor(actor)
            end
        end
        love.graphics.draw(layer.image, 0, 0)
        maxBaseline = layer.baseline
    end

    -- draw actors above all the baselines
    for iactor, actor in pairs(self.actors) do
        if (actor.y) >= maxBaseline then
            self:drawActor(actor)
        end
    end
    
    -- Bag Buttons
    for counter, button in pairs(self.bagButtons) do
        love.graphics.draw (button.image, button.x, button.y)
    end
    
    -- status text
    if (self.statusText) then
        love.graphics.setFont(love.graphics.newFont(self.settings["status font size"]))
        love.graphics.printf(self.statusText, 0, self.settings["status position"], love.window.getWidth() / scale, "center")
    end
    
    -- Draw Speech
    if (#self.speech > 0) then
        local spc = self.speech[1]
        -- Store the original color
        local r, g, b, a = love.graphics.getColor()
        -- Set a new speech color
        love.graphics.setColor(spc.actor.speechcolor)
        love.graphics.setFont(love.graphics.newFont(self.settings["speech font size"]))
        love.graphics.printf(spc.text, 0, self.settings["speech position"], love.window.getWidth() / scale, "center")
        -- Restore original color
        love.graphics.setColor(r, g, b, a)
    end
    
    self:outlineStageElements()

end

-- Set a status text
function slime.status (self, text)

    self.statusText = text

end

-- Gets the object under xy.
function slime.getObjects (self, x, y)

    local objects = { }

    for iactor, actor in pairs(self.actors) do
        if (x >= actor.x - actor.base[1] and x <= actor.x - actor.base[1] + actor.w) and 
            (y >= actor.y - actor.base[2] and y <= actor.y - actor.base[2] + actor.h) then
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
        self.callback (self.cursorName or "interact", object)
    end
    
end

-- Set a hardware cursor with scale applied.
function slime.setCursor (self, name, image, scale, hotx, hoty)

    self.cursorName = name
    local cursor = nil
    if (image) then
        local w, h = image:getDimensions ()
        local cursorCanvas = love.graphics.newCanvas (w * scale, h * scale)
        cursorCanvas:renderTo(function()
                love.graphics.draw (image, 0, 0, 0, scale, scale)
            end)
        cursor = love.mouse.newCursor (cursorCanvas:getImageData(), hotx, hoty)
    end
    love.mouse.setCursor (cursor)
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
    
    -- draw baselines for layers
    love.graphics.setColor(255, 0, 0, 64)
    for i, layer in pairs(self.layers) do
        love.graphics.line( 0, layer.baseline, love.window.getHeight(), layer.baseline)
    end
    
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
    love.graphics.setColor(0, 255, 0, 64)
    for iactor, actor in pairs(self.actors) do
        love.graphics.rectangle("line", actor.x - actor.base[1], actor.y - actor.base[2], actor.w, actor.h)
        love.graphics.circle("line", actor.x, actor.y, 1, 6)
    end
    
    love.graphics.setColor(r, g, b, a)
    
end

return slime

