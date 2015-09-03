--        _ _                
--    ___| (_)_ __ ___   ___ 
--   / __| | | '_ ` _ \ / _ \
--   \__ \ | | | | | | |  __/
--   |___/_|_|_| |_| |_|\___|
--   
-- SLIME is a point-and-click adventure game library for LÖVE.

require 'map'

local slime = {}

slime.counters = {}


function slime.reset ()
    slime.counters = {}
    slime.backgrounds = {}
    slime.actors = {}
    slime.layers = {}
    slime.debug.log = {}
    slime.astar = nil
end

--                       _      
--    ___  ___ ___ _ __ (_) ___ 
--   / __|/ __/ _ \ '_ \| |/ __|
--   \__ \ (_|  __/ | | | | (__ 
--   |___/\___\___|_| |_|_|\___|


slime.backgrounds = {}

function slime.background (image, x, y, delay)

    -- Add a background to the stage, drawn at x, y for the given delay
    -- before drawing the next available background.
    -- If no delay is given, the background will draw forever.
    
    newBackground = {
        ["image"] = image,
        ["x"] = x,
        ["y"] = y,
        ["delay"] = delay
        }
    table.insert(slime.backgrounds, newBackground)
    
    -- default to the first background
    if (#slime.backgrounds == 1) then
        slime.counters["background index"] = 1
        slime.counters["background delay"] = delay
    end
end

function slime.walkable (mask)
    slime.handler = SlimeMapHandler()
    slime.handler:convert(mask)
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

function slime.actor (name, image, x, y, hotspotx, hotspoty)

    -- Add an actor to the stage.
    -- Allows adding the same actor name multiple times, but only
    -- the first instance uses the "name" as the key, subsequent
    -- duplicates will use the natural numbering of the table.
    --
    -- The hotspotX/Y values are the offset of the actor's hotspot
    -- from the image origin. By default this is centered at the base
    -- of the image.

    local newActor = {
        ["name"] = name,
        ["image"] = image,
        ["x"] = x,
        ["y"] = y,
        ["hotspotX"] = image:getWidth() / 2,
        ["hotspotY"] = image:getHeight()
        }
        
    if (hotspotx and hotspoty) then
        newActor.hotspotX = hotspotx
        newActor.hotspotY = hotspoty
    end
    
    if (slime.actors[name]) then
        table.insert(slime.actors, newActor)
    else
        slime.actors[name] = newActor
    end
    
    return newActor
end

function slime.drawActor (actor)
    love.graphics.draw(actor.image, actor.x - actor.hotspotX, actor.y - actor.hotspotY)
end

function slime.moveActor (name, x, y)

    -- Move an actor to point xy using A Star path finding
    
    if (slime.astar == nil) then 
        slime.log("No walkable area defined")
        return 
    end
        
    local actor = slime.actors[name]

    if (actor == nil) then
        slime.log("No actor named " .. name)
    else
        local start = { x = actor.x, y = actor.y }
        local goal = { x = x, y = y }
        local path = slime.astar:findPath(goal, start)
        if (path == nil) then
            slime.log("no actor path found")
        else
            actor.path = path:getNodes()
            slime.log("move " .. name .. " to " .. x .. " : " .. y)
        end
    end
end

function slime.moveActorOnPath (actor, dt)
    if (actor.path) then
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
        end
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

function slime.layer (source, mask, x, y, baseline)
    local newLayer = { 
        ["image"] = slime:createLayer(source, mask),
        ["x"] = x,
        ["y"] = y,
        ["baseline"] = baseline
        }
    table.insert(slime.layers, newLayer)
    
    -- order the layers by their baselines.
    -- this is important for when we draw the layers
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

--        _                    
--     __| |_ __ __ ___      __
--    / _` | '__/ _` \ \ /\ / /
--   | (_| | | | (_| |\ V  V / 
--    \__,_|_|  \__,_| \_/\_/  

function slime.update (dt)

    slime.updateBackground(dt)
    
    for iactor, actor in pairs(slime.actors) do
        slime.moveActorOnPath (actor, dt)
    end

end

function slime.draw ( )

    -- Background
    local bg = slime.backgrounds[slime.counters["background index"]]
    if (bg) then
        love.graphics.draw(bg.image, bg.x, bg.y)
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
        love.graphics.draw(layer.image, layer.x, layer.y)
        maxBaseline = layer.baseline
    end

    -- draw actors above all the baselines
    for iactor, actor in pairs(slime.actors) do
        if (actor.y) >= maxBaseline then
            slime.drawActor(actor)
        end
    end
    
    slime.outlineStageElements()

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
    
    -- draw outlines of layers
    love.graphics.setColor(255, 0, 0, 64)
    for i, layer in pairs(slime.layers) do
        love.graphics.line( 0, layer.baseline, love.window.getHeight(), layer.baseline)
    end
    
    -- draw walkable areas
    -- TODO
    
    -- draw outlines of characters
    love.graphics.setColor(0, 255, 0, 64)
    for iactor, actor in pairs(slime.actors) do
        love.graphics.rectangle( "line", actor.x - actor.hotspotX, actor.y - actor.hotspotY, actor.image:getWidth(), actor.image:getHeight() )
        love.graphics.circle( "line", actor.x, actor.y, 1, 6 )
    end

    love.graphics.setColor(r, g, b, a)
    
end

return slime

