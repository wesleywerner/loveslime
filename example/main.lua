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
        
        local interactCall = function()
            slime.interact (x, y)
        end
        
        -- Move Ego to the x/y position and interact with any
        -- object that is there.
        slime.moveActor ("ego", x, y, interactCall)

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
