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

    Copyright (c) 2011 Enrique García Cota

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

function slime.reset ()
    slime.counters = {}
    slime.backgrounds = {}
    slime.actors = {}
    slime.layers = {}
    slime.debug.log = {}
    slime.hotspots = {}
    slime.astar = nil
    slime.statusText = nil
end

--                       _      
--    ___  ___ ___ _ __ (_) ___ 
--   / __|/ __/ _ \ '_ \| |/ __|
--   \__ \ (_|  __/ | | | | (__ 
--   |___/\___\___|_| |_|_|\___|


slime.backgrounds = {}

function slime.background (backgroundfilename, delay)

    -- Add a background to the stage, drawn at x, y for the given delay
    -- before drawing the next available background.
    -- If no delay is given, the background will draw forever.
    
    local image = love.graphics.newImage(backgroundfilename)
    
    newBackground = {
        ["image"] = image,
        ["delay"] = delay
        }
    
    table.insert(slime.backgrounds, newBackground)
    
    -- default to the first background
    if (#slime.backgrounds == 1) then
        slime.counters["background index"] = 1
        slime.counters["background delay"] = delay
    end
end

-- Set the floor mask that determines walkable areas.
function slime.floor (floorfilename)
    slime.handler = SlimeMapHandler()
    floorimage = love.graphics.newImage(floorfilename)
    slime.handler:convert(floorimage)
    slime.astar = AStar(slime.handler)
end

function slime.updateBackground (dt)

    -- Rotates to the next background if there is one and delay expired.
    
    if (#slime.backgrounds <= 1) then
        -- skip background rotation if there is one or none
        return
    end

    local index = slime.counters["background index"]
    local background = slime.backgrounds[index]
    local timer = slime.counters["background delay"]
    
    if (timer == nil or background == nil) then
        -- start a new timer
        index = 1
        timer = background.delay
    else
        timer = timer - dt
        -- this timer has expired
        if (timer < 0) then
            -- move to the next index (with wrapping)
            index = (index == #slime.backgrounds) and 1 or index + 1
            if (slime.backgrounds[index]) then
                timer = slime.backgrounds[index].delay
            end
        end
    end

    slime.counters["background index"] = index
    slime.counters["background delay"] = timer

end


--               _                 
--     __ _  ___| |_ ___  _ __ ___ 
--    / _` |/ __| __/ _ \| '__/ __|
--   | (_| | (__| || (_) | |  \__ \
--    \__,_|\___|\__\___/|_|  |___/

slime.actors = {}
slime.tilesets = {}

function slime.actor (name)

    -- Add an actor to the stage.
    -- Allows adding the same actor name multiple times, but only
    -- the first instance uses the "name" as the key, subsequent
    -- duplicates will use the natural numbering of the table.
    
    -- default sprite size
    local w = 10
    local h = 10
    
    local newActor = {
        ["name"] = name,
        ["x"] = 0,
        ["y"] = 0,
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
        local key = self.action .. " " .. self.direction
        return self.animations[key]
    end
    
    if (slime.actors[name]) then
        table.insert(slime.actors, newActor)
    else
        slime.actors[name] = newActor
    end
    
    return newActor
end

-- Helper functions to batch build actor animations
function slime.idleAnimation (name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    slime.prefabAnimation ("idle", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

function slime.walkAnimation (name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    slime.prefabAnimation ("walk", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

function slime.talkAnimation (name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
    slime.prefabAnimation ("talk", name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)
end

-- Create a prefabricated animation sequence of the cardinal directions.
-- Use the south direction (facing the player) as default if none of the other directions are given.
function slime.prefabAnimation (prefix, name, tileset, w, h, south, southd, west, westd, north, northd, east, eastd)

    slime.addAnimation (name, prefix .. " south", tileset, w, h, south, southd)
    slime.addAnimation (name, prefix .. " west", tileset, w, h, west or south, westd or southd)
    slime.addAnimation (name, prefix .. " north", tileset, w, h, north or south, northd or southd)

    -- if the east animations is empty, flip the west animation if there is one
    if (not east and west) then
        local eastAnim = slime.addAnimation (name, prefix .. " east", tileset, w, h, east or west, eastd or westd)
        eastAnim:flipH()
    else
        slime.addAnimation (name, prefix .. " east", tileset, w, h, east or south, eastd or southd)
    end
end

-- Create a custom animation.
function slime.addAnimation (name, key, tileset, w, h, frames, delays)

    local actor = slime.actors[name]
    
    if (not actor) then
        slime.log ("Add animation failed: no actor named " .. name)
        return
    end
    
    -- cache tileset image to save loading duplicate images
    local image = slime.tilesets[tileset]
    if (not slime.tilesets[tileset]) then
        image = love.graphics.newImage(tileset)
        slime.tilesets[tileset] = image
    end

    -- default actor hotspot to centered at the base of the image
    actor["w"] = w
    actor["h"] = h
    actor["base"] = { w/2, h }
    
    local g = anim8.newGrid(w, h, image:getWidth(), image:getHeight())
    local animation = anim8.newAnimation(g(unpack(frames)), delays)
    
    actor.animations[key] = { 
        --["name"] = key,
        ["tileset"] = tileset,
        ["animation"] = animation
        }
        
    -- default to this anim
    if (not actor.anim) then
        actor.anim = actor.animations[key]
    end
    
    return animation
    
end

-- Set a static image as an actor's sprite.
function slime.addImage (name, image)

    local actor = slime.actors[name]
    
    if (not actor) then
        slime.log ("Add image failed: no actor named " .. name)
    else
        actor.image = image
        actor.w = image:getWidth()
        actor.h = image:getHeight()
        actor.base = { actor.w/2, actor.h }
    end
    
end

function slime.drawActor (actor)

    local animation = actor:getAnim()
    if (animation) then
        local tileset = slime.tilesets[animation["tileset"]]
        animation["animation"]:draw(tileset, actor.x - actor.base[1], actor.y - actor.base[2])
    elseif (actor.image) then
        love.graphics.draw(actor.image, actor.x - actor.base[1], actor.y - actor.base[2])
    else
        love.graphics.rectangle ("fill", actor.x - actor.base[1], actor.y - actor.base[2], actor.w, actor.h)
    end

end

function slime.turnActor (name, direction)

    local actor = slime.actors[name]

    if (actor) then
        actor.direction = direction
    end
    
end

function slime.moveActor (name, x, y, moveCompleteCallback)

    -- Move an actor to point xy using A Star path finding
    
    if (slime.astar == nil) then 
        slime.log("No walkable area defined")
        return 
    end
        
    local actor = slime.actors[name]

    if (actor == nil) then
        slime.log("No actor named " .. name)
    else
        -- Our path runs backwards so we can pop the points off the stack
        local start = { x = actor.x, y = actor.y }
        local goal = { x = x, y = y }
        
        -- If the goal is on a solid block, we use the bresenham line
        -- algorithm to draw a straight line to the origin, and return
        -- the first open node on that line.
        local findNearestPoint = slime.handler:nodeBlocking(goal)
        if (findNearestPoint) then
            local walkTheLine = bresenham (start, goal)
            while (findNearestPoint) do
                if (#walkTheLine == 0) then
                    findNearestPoint = false
                else
                    goal = table.remove(walkTheLine)
                    findNearestPoint = slime.handler:nodeBlocking(goal)
                end
            end
        end
        
        -- Calculate a path
        local path = slime.astar:findPath(goal, start)
        if (path == nil) then
            slime.log("no actor path found")
        else
            actor.path = path:getNodes()
            -- Callback when the goal is reached
            actor.moveCompleteCallback = moveCompleteCallback
            -- Default to walking animation
            actor.action = "walk"
            -- Calculate actor direction immediately
            actor.lastx, actor.lasty = actor.x, actor.y
            actor.direction = slime.calculateDirection(actor.x, actor.y, x, y)
            -- Output debug
            slime.log("move " .. name .. " to " .. x .. " : " .. y)
        end
    end
end

-- Move an actor to another actor
function slime.moveActorTo (name, target, moveCompleteCallback)

    local targetActor = slime.actors[target]
    
    if (targetActor) then
        slime.moveActor (name, targetActor.x, targetActor.y, moveCompleteCallback)
    else
        slime.log("no actor named " .. target)
    end
end

function slime.moveActorOnPath (actor, dt)
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
                actor.direction = slime.calculateDirection(actor.lastx, actor.lasty, actor.x, actor.y)
                actor.lastx, actor.lasty = actor.x, actor.y
            end
        end
        
        if (#actor.path == 0) then
            actor.action = "idle"
            if (actor.moveCompleteCallback) then
                actor.moveCompleteCallback()
            end
        end
    end
end

-- Return the nearest cardinal direction represented by the angle of movement.
function slime.calculateDirection (x1, y1, x2, y2)

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
function slime.addSpeech (name, text)

    local newSpeech = {
        ["actor"] = slime.actors[name],
        ["text"] = text,
        ["time"] = 3
        }
        
    if (not newSpeech.actor) then
        slime.log("Speech failed: No actor named " .. name)
        return
    end
    
    table.insert(slime.speech, newSpeech)

end


-- Checks if there is an actor talking.
function slime.someoneTalking ()

    return (#slime.speech > 0)

end

-- Skips the current speech
function slime.skipSpeech ( )

    local spc = slime.speech[1]
    if (spc) then
        table.remove(slime.speech, 1)
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

function slime.layer (backgroundfilename, maskfilename, baseline)

    local source = love.graphics.newImage(backgroundfilename)
    local mask = love.graphics.newImage(maskfilename)
    
    local newLayer = { 
        ["image"] = slime:createLayer(source, mask),
        ["baseline"] = baseline
        }
    
    table.insert(slime.layers, newLayer)
    
    -- Order the layers by their baselines.
    -- This is important for when we draw the layers.
    table.sort(slime.layers, function (a, b) return a.baseline < b.baseline end )
    
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

slime.hotspots = {}

function slime.hotspot(name, InteractCallback, x, y, w, h)

    table.insert(slime.hotspots, {
        ["name"] = name, 
        ["InteractCallback"] = InteractCallback, 
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

slime.inventories = { }

-- Give an inventory item
function slime.addInventory (bag, object)

    -- Replace the image path with the image data
    object.image = love.graphics.newImage(object.image)
    
    -- Add the inventory item under "name"
    if (not slime.inventories[bag]) then slime.inventories[bag] = { } end
    local inv = slime.inventories[bag]
    table.insert(inv, object)
    
    slime.log (bag .. " given " .. object.name)

end

-- Get a list of inventory items
function slime.getInventory (bag)

    return slime.inventories[bag] or { }

end

-- Delete an inventory item from a list
function slime.delInventory (bag, name)

    local inv = slime.inventories[bag]
    if (inv) then 
        for i, item in pairs(inv) do
            if (item.name == name) then
                table.remove(inv, i)
            end
        end
    end
    
end

--        _                    
--     __| |_ __ __ ___      __
--    / _` | '__/ _` \ \ /\ / /
--   | (_| | | | (_| |\ V  V / 
--    \__,_|_|  \__,_| \_/\_/  

function slime.update (dt)

    slime.updateBackground(dt)
    
    -- Update animations
    for iactor, actor in pairs(slime.actors) do
        slime.moveActorOnPath (actor, dt)
        local anim = actor:getAnim()
        if (anim and anim["animation"]) then
            anim["animation"]:update(dt)
        end
    end
    
    -- Update the speech display time.
    if (#slime.speech > 0) then
        local spc = slime.speech[1]
        spc.time = spc.time - dt
        if (spc.time < 0) then
            slime.skipSpeech()
        else
            spc.actor.action = "talk"
        end
    end

end

function slime.draw (scale)

    scale = scale or 1

    -- Background
    local bg = slime.backgrounds[slime.counters["background index"]]
    if (bg) then
        love.graphics.draw(bg.image, 0, 0)
    end

    -- Layers
    -- layers are ordered by their baselines: smaller values first.
    -- for each layer, draw the actors above it, then draw the layer.
    local maxBaseline = nil
    for i, layer in pairs(slime.layers) do
        for iactor, actor in pairs(slime.actors) do
            if (actor.y) < layer.baseline then
                slime.drawActor(actor)
            end
        end
        love.graphics.draw(layer.image, 0, 0)
        maxBaseline = layer.baseline
    end

    -- draw actors above all the baselines
    for iactor, actor in pairs(slime.actors) do
        if (actor.y) >= maxBaseline then
            slime.drawActor(actor)
        end
    end
    
    -- status text
    if (slime.statusText) then
        love.graphics.setFont(love.graphics.newFont(slime.settings["status font size"]))
        love.graphics.printf(slime.statusText, 0, slime.settings["status position"], love.window.getWidth() / scale, "center")
    end
    
    -- Draw Speech
    if (#slime.speech > 0) then
        local spc = slime.speech[1]
        -- Store the original color
        local r, g, b, a = love.graphics.getColor()
        -- Set a new speech color
        love.graphics.setColor(spc.actor.speechcolor)
        love.graphics.setFont(love.graphics.newFont(slime.settings["speech font size"]))
        love.graphics.printf(spc.text, 0, slime.settings["speech position"], love.window.getWidth() / scale, "center")
        -- Restore original color
        love.graphics.setColor(r, g, b, a)
    end
    
    slime.outlineStageElements()

end

-- Set a status text
function slime.status (text)

    slime.statusText = text

end

-- Gets the object under xy.
function slime.getObjects (x, y)

    local objects = { }

    for iactor, actor in pairs(slime.actors) do
        if (x >= actor.x - actor.base[1] and x <= actor.x - actor.base[1] + actor.w) and 
            (y >= actor.y - actor.base[2] and y <= actor.y - actor.base[2] + actor.h) then
            table.insert(objects, actor)
        end
    end
    
    for ihotspot, hotspot in pairs(slime.hotspots) do
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

function slime.interact (x, y)

    local objects = slime.getObjects(x, y)
    if (not objects) then return end
    
    for i, object in pairs(objects) do
        if (object.InteractCallback) then
            slime.log("Interacting with " .. object.name)
            object.InteractCallback()
        end
    end
    
end

--        _      _                 
--     __| | ___| |__  _   _  __ _ 
--    / _` |/ _ \ '_ \| | | |/ _` |
--   | (_| |  __/ |_) | |_| | (_| |
--    \__,_|\___|_.__/ \__,_|\__, |
--                           |___/ 
-- Provides helpful debug information while building your game.

slime.debug = { ["enabled"] = true, ["log"] = {} }

function slime.log (text)
    -- add a debug log entry
    table.insert(slime.debug.log, text)
    if (#slime.debug.log > 10) then table.remove(slime.debug.log, 1) end
end

slime.debugdraw = function ( )

    if (not slime.debug["enabled"]) then return end
    
    -- get the debug overlay image
    local debugOverlay = slime.debug["overlay"]
    
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
        slime.debug["overlay"] = debugOverlay
    end

    -- draw the overlay
    love.graphics.draw(debugOverlay, 0, 0);
    
    -- print frame speed
    love.graphics.print(tostring(love.timer.getFPS()) .. " fps", 12, 10)

    -- print background info
    if (slime.counters["background index"] and slime.counters["background delay"]) then
        love.graphics.print("background #" .. slime.counters["background index"] .. " showing for " .. string.format("%.1f", slime.counters["background delay"]) .. "s", 60, 10)
    end
    
    -- print info of everything under the pointer
    -- TODO
    
    -- log texts
    for i, n in pairs(slime.debug.log) do
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.print(n, 11, 21 + (10 * i))
        love.graphics.setColor(0, 255, 0, 128)
        love.graphics.print(n, 10, 20 + (10 * i))
    end

    -- restore the original colour
    love.graphics.setColor(r, g, b, a)
    
end

function slime.outlineStageElements()

    if (not slime.debug["enabled"]) then return end
    
    local r, g, b, a = love.graphics.getColor( )
    
    -- draw baselines for layers
    love.graphics.setColor(255, 0, 0, 64)
    for i, layer in pairs(slime.layers) do
        love.graphics.line( 0, layer.baseline, love.window.getHeight(), layer.baseline)
    end
    
    -- draw outlines of hotspots
    love.graphics.setColor(0, 0, 255, 64)
    for ihotspot, hotspot in pairs(slime.hotspots) do
        love.graphics.rectangle("line", hotspot.x, hotspot.y, hotspot.w, hotspot.h)
    end
    
    -- draw outlines of actors
    love.graphics.setColor(0, 255, 0, 64)
    for iactor, actor in pairs(slime.actors) do
        love.graphics.rectangle("line", actor.x - actor.base[1], actor.y - actor.base[2], actor.w, actor.h)
        love.graphics.circle("line", actor.x, actor.y, 1, 6)
    end

    love.graphics.setColor(r, g, b, a)
    
end

return slime

