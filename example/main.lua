-- Store the slime module in a global variable so that other stage files
-- have access to it.
slime = require ("slime.slime")

require ("actors")
require ("stages")

-- Scale our graphics so that our pixel art is better visible.
-- When handling mouse positions we account for scale in the xy points.
scale = 4

-- Hotspots below this mark is from our inventory bag
bagPosition = 86

function love.load()
    
    -- Nearest image interpolation (pixel graphics, no anti-aliasing)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Load the first room, our prison cell
    cellRoom()
    
end

function drawInventory ()
    for i, inv in pairs(slime.bagContents("ego")) do
        love.graphics.draw(inv.image, i * 10, 86)
    end
end

-- Handles bag hotspot clicks
function bagHandler (data)
    slime.log ("bag clicked on " .. data.name)
end

function slime.inventoryChanged ( )
    
    -- Clear existing bag hotspots
    for i, spot in ipairs(slime.hotspots) do
        if (type(spot.data) == "table") and spot.data.isbagitem then
            table.remove (slime.hotspots, i)
        end
    end
    
    -- Add current bag hotspots
    for i, inv in pairs(slime.bagContents("ego")) do
        local data = {
            ["isbagitem"] = true,
            ["name"] = inv.name
            }
        local w, h = inv.image:getDimensions()
        slime.hotspot (inv.name, bagHandler, i * 10, bagPosition, w, h, data)
    end
    
end

function love.draw()

    love.graphics.push()
    love.graphics.scale(scale)
    slime.draw(scale)
    drawInventory()
    love.graphics.pop()
    
    -- Display debug info (only works if slime.debug["enabled"] == true)
    slime.debugdraw()

end

function love.update(dt)
    
    slime.update (dt)
    updateStatus()

end

-- Escape key exits, Tab key toggles debug information
function love.keypressed(key, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    if key == "tab" then
        slime.debug.enabled = not slime.debug.enabled and true or false
    end
end

-- Left clicking moves our Ego actor, and interacts with objects.
function love.mousepressed(x, y, button)

    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)

    if button == "l" then
        
        -- If there is speech showing, skip it on mouse click 
        -- and ignore any other interactions.
        if (slime.someoneTalking()) then
            slime.skipSpeech()
            return
        end
        
        -- The point is in our bag inventory area
        if (y > bagPosition) then
            slime.interact (x, y)
        end
        
        -- Move Ego to the x/y position and interact with any
        -- object that is there.
        slime.moveActor ("ego", x, y, 
            function() slime.interact (x, y) end)

    end
    
end

-- Show the name of the object under our pointer.
function updateStatus()
    
    local x, y = love.mouse.getPosition()
    
    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)
    
    local objects = slime.getObjects(x, y)
    
    if (objects) then
        local items = {}
        for i, obj in pairs(objects) do
            table.insert(items, obj.name)
        end
        slime.status(table.concat(items, ", "))
    else
        slime.status()
    end
    
end
