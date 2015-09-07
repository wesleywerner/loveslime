-- Store the slime module in a global variable so that other stage files
-- have access to it.
slime = require ("slime")

-- We can separate each stage into a file for easier code management.
require ("cell")

-- Scale our graphics so that our pixel art is better visible.
-- When handling mouse positions we account for scale in the xy points.
scale = 4

function love.load()
    
    -- Nearest image interpolation (pixel graphics, no anti-aliasing)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Load the first room, our prison cell
    cellRoom()
    
end

function love.draw()

    love.graphics.push()
    love.graphics.scale(scale)
    slime.draw(scale)
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
        
        -- interact with the object at this point
        local interacted = slime.interact(x, y)
        
        if (not interacted) then
            -- move ego if nothing happened
            slime.moveActor("ego", x, y)
        end
        
    end
    
end

-- Show the name of the object under our pointer.
function updateStatus()
    
    local x, y = love.mouse.getPosition()
    
    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)
    
    local obj = slime.getObject(x, y)
    
    if (obj) then
        slime.status(obj.name)
    else
        slime.status()
    end
    
end
