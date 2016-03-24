slime = require ("slime")

-- Clicks below this point skip actor movement
bagPosition = 86

function love.load()
    -- Nearest image interpolation (pixel graphics, no anti-aliasing)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    setupStage()
end

function love.draw ()
    love.graphics.push ()
    love.graphics.scale (scale)
    slime:draw (scale)
    love.graphics.pop ()
    slime:debugdraw ()
end

function love.update(dt)
    slime:update(dt)
end

function love.keypressed(key, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

function setupStage ()

    -- Clear the stage
    slime:reset ()

    -- Add the background
    slime:background ("images/cell-background.png")
    
    -- Apply the walk-behind layer
    slime:layer ("images/cell-background.png", "images/cell-layer.png", 50)
    
    -- Set the floor
    slime:floor ("images/cell-floor-closed.png")
    
    -- Add our main actor
    addEgoActor (70, 50)
    
    -- Add the cell door
    addCellDoor (50, 49)
    
    -- Hole in the wall
    local x, y, width, height = 92, 23, 8, 8
    slime:hotspot ("hole", x, y, width, height)

    -- Bowl and spoon
    local bowl = slime:actor("bowl and spoon", 65, 37, "images/bowl1.png")
    
    slime.callback = myStageCallback
    
end

function addEgoActor (x, y)

    -- Add an actor named "ego"
    local ego = slime:actor ("ego", x, y)
    
    -- The time between actor steps. More delay means slower steps.
    ego.movedelay = 0.05

    -- Set the actor's idle animation parameters.
    -- The idle animation plays when the actor is not walking or talking.
    -- This is a simple two-frame animation: Open eyes, then a blink every 3 seconds.
    -- If we do not give East facing frames, the West frame will be
    -- flipped for us automatically. So let us take advantage of that.
    
    local tileWidth = 12
    local tileHeight = 12
    local southFrames = {'11-10', 1}
    local southDelays = {3, 0.2}
    local westFrames = {'3-2', 1}
    local westDelays = {3, 0.2}
    local northFrames = {18, 1}
    local northDelays = 1
    local eastFrames = nil
    local eastDelays = nil
    slime:idleAnimation (
        "ego", "images/ego.png",
        tileWidth, tileHeight,
        southFrames, southDelays,
        westFrames, westDelays,
        northFrames, northDelays,
        eastFrames, eastDelays )

    -- Walk animation
    local southFrames = {'11-14', 1}
    local southDelays = 0.2
    local westFrames = {'6-3', 1}
    local westDelays = 0.2
    local northFrames = {'18-21', 1}
    local northDelays = 0.2
    slime:walkAnimation (
        "ego", "images/ego.png",
        tileWidth, tileHeight,
        southFrames, southDelays,
        westFrames, westDelays,
        northFrames, northDelays,
        eastFrames, eastDelays )
        
    -- Talk animation
    local southFrames = {'15-17', 1}
    local southDelays = 0.2
    local westFrames = {'7-9', 1}
    local westDelays = 0.2
    local northFrames = {'15-17', 1}
    local northDelays = 0.2
    slime:talkAnimation (
        "ego", "images/ego.png",
        tileWidth, tileHeight,
        southFrames, southDelays,
        westFrames, westDelays,
        northFrames, northDelays,
        eastFrames, eastDelays )
                        
end

-- Left clicking moves our Ego actor, and interacts with objects.
function love.mousepressed(x, y, button)

    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)

    -- Left mouse button
    if button == "l" then
    
        -- The point is in our bag inventory area
        if (y > bagPosition) then 
            slime:interact (x, y)
        else
            -- Move Ego then interact with any objects
            slime:moveActor ("ego", x, y)
        end

    end
    
    -- Right clicks uses the default cursor
    if button == "r" then
        slime:setCursor()
    end
    
end

function addCellDoor (x, y)

    -- Add the door as an actor
    local cellDoor = slime:actor("door", x, y)

    -- Sprite size and frames
    local frameWidth, frameHeight = 9, 30
    local animationDelay = 0.05
    -- A single frame that shows the door as open or closed
    local closedFrame = {1, 1}
    local openFrame = {31, 1}
    -- A series of frames that open or close the door
    local openingFrames = {"1-31", 1}
    local closingFrames = {"31-1", 1}
    
    -- Keep the door open after the opening animation played.
    local function onOpeningLoop ()
        slime:setAnimation ("door", "open")
    end
    
    -- Keep the door closed after the closing animation played.
    local function onClosingLoop ()
        slime:setAnimation ("door", "closed")
    end
    
    -- Add the animations. Both the closing and opening have callbacks set.
    slime:addAnimation ("door", "closing", "images/cell-door.png", frameWidth, frameHeight, closingFrames, animationDelay, onClosingLoop)
    slime:addAnimation ("door", "closed", "images/cell-door.png", frameWidth, frameHeight, closedFrame, animationDelay)
    slime:addAnimation ("door", "opening", "images/cell-door.png", frameWidth, frameHeight, openingFrames, animationDelay, onOpeningLoop)
    slime:addAnimation ("door", "open", "images/cell-door.png", frameWidth, frameHeight, openFrame, animationDelay)
    
    -- Start off closed
    slime:setAnimation ("door", "closed")

end

function openCellDoor ()

    slime:setAnimation ("door", "opening")
    slime:floor("images/cell-floor-open.png")

end

function closeCellDoor ()

    slime:setAnimation ("door", "closing")
    slime:floor("images/cell-floor-closed.png")

end

-- **

function myStageCallback (event, object)

    slime:log (event .. " on " .. object.name)

    if (event == "moved" and object.name == "ego") then
        slime:interact (object.clickedX, object.clickedY)
    end
    
    if (event == "interact") then
    
        -- give ego a bowl and a spoon inventory items
        if (object.name == "bowl and spoon") then
            -- Face Ego to the player
            slime:turnActor ("ego", "south")
            -- Add items to Ego's bag
            slime:bagInsert ("ego", { ["name"] = "bowl", ["image"] = "images/bowl2.png" })
            slime:bagInsert ("ego", { ["name"] = "spoon", ["image"] = "images/spoon.png" })
            -- Remove the bowl and spoon actor from the stage
            slime.actors["bowl and spoon"] = nil
        end
        
        -- Look at the hole in the wall
        if (object.name == "hole") then
            slime:addSpeech ("ego", "I see a hole in the wall")
        end
        
        -- Set the cursor when interacting on bag items
        if (object.name == "spoon") then
            slime:setCursor (object.name, object.image, scale, 0, 0)
        end
    
    end
    
    if (event == "spoon" and object.name == "door") then
        slime:addSpeech ("ego", "The spoon won't open this door")
    end
    
end

-- Clear and reposition the clickable buttons for the bag (inventory)
-- when it has items added or removed.
function slime.inventoryChanged (bag)
    slime.bagButtons = { }
    for counter, item in pairs(slime:bagContents("ego")) do
        slime:bagButton (item.name, item.image, counter * 10, bagPosition)
    end
end

-- **

