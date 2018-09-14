slime = require ("slime")

-- Begin defining our game stage, a jail cell
local cell = {}

function cell.setup ()

    -- Clear the stage
    slime:reset()

    -- Add the background
    slime:background("images/cell-background.png")

    -- Apply the walk-behind layer
    slime:layer("images/cell-background.png", "images/cell-layer.png", 50)

    -- Set the floor
    slime:floor("images/cell-floor-closed.png")

    -- Add our main actor
    cell.addEgoActor(70, 50)

    -- Add the cell door
    cell.addCellDoor(50, 49)

    -- Hole in the wall
    local x, y, width, height = 92, 23, 8, 8
    slime:hotspot("hole", x, y, width, height)

    -- Bowl and spoon
    local bowl = slime:actor("bowl and spoon", 65, 37)
    bowl:setImage("images/bowl1.png")

    -- Hook into the slime callbacks
    slime.callback = cell.callback
    slime.inventoryChanged = cell.inventoryChanged
    slime.animationLooped = cell.animationLooped

end

function cell.addEgoActor (x, y)

    -- Add an actor named "ego"
    local ego = slime:actor("ego", x, y)

    -- The time between actor steps. More delay means slower steps.
    ego.movedelay = 0.05

    -- create a new animation pack for ego using a tileset of 12x12 frames
    local egoAnim = ego:tileset("images/ego.png", {w=12, h=12})

    -- Idle animation
    -- The idle animation plays when the actor is not walking or talking:
    -- a simple two-frame animation: Open eyes, and blink.

    local southFrames = {'11-10', 1}
    local southDelays = {3, 0.2}
    local westFrames = {'3-2', 1}
    local westDelays = {3, 0.2}
    local northFrames = {18, 1}
    local northDelays = 1

    egoAnim:define("idle south")
      :frames(southFrames):delays(southDelays)
    egoAnim:define("idle west")
      :frames(westFrames):delays(westDelays)
    egoAnim:define("idle north")
      :frames(northFrames):delays(northDelays)
    egoAnim:define("idle east")
      :frames(westFrames):delays(westDelays):flip()

    -- Walk animation
    southFrames = {'11-14', 1}
    southDelays = 0.2
    westFrames = {'6-3', 1}
    westDelays = 0.2
    northFrames = {'18-21', 1}
    northDelays = 0.2

    egoAnim:define("walk south")
      :frames(southFrames):delays(southDelays)
    egoAnim:define("walk west")
      :frames(westFrames):delays(westDelays)
    egoAnim:define("walk north")
      :frames(northFrames):delays(northDelays)
    egoAnim:define("walk east")
      :frames(westFrames):delays(westDelays):flip()

    -- Talk animation
    southFrames = {'15-17', 1}
    southDelays = 0.2
    westFrames = {'7-9', 1}
    westDelays = 0.2
    northFrames = {'15-17', 1}
    northDelays = 0.2

    egoAnim:define("talk south")
      :frames(southFrames):delays(southDelays)
    egoAnim:define("talk west")
      :frames(westFrames):delays(westDelays)
    egoAnim:define("talk north")
      :frames(northFrames):delays(northDelays)
    egoAnim:define("talk east")
      :frames(westFrames):delays(westDelays):flip()

    -- Ego animation using the spoon to dig
    egoAnim:define("dig")
      :frames({"22-25", 1}):delays(0.2):flip()

end


function cell.addCellDoor (x, y)

    -- Add the door as an actor
    local cellDoor = slime:actor("door", x, y)

    cellDoor.baseline = 5

    -- Sprite frames
    local frameWidth, frameHeight = 9, 30
    local animationDelay = 0.05
    -- A single frame that shows the door as open or closed
    local closedFrame = {1, 1}
    local openFrame = {31, 1}
    -- A series of frames that open or close the door
    local openingFrames = {"1-31", 1}
    local closingFrames = {"31-1", 1}

    local doorAnim = cellDoor:tileset("images/cell-door.png", {w=9, h=30})
    doorAnim
		:define ("closing")
		:frames (closingFrames)
		:delays (animationDelay)
    doorAnim
        :define("closed")
        :frames(closedFrame)
        :delays(10)
    doorAnim
		:define ("opening")
		:frames (openingFrames)
		:delays (animationDelay)
    doorAnim
		:define ("open")
		:frames (openFrame)
        :delays(10)

    -- Start off closed
    slime:setAnimation("door", "closed")

end


function cell.openCellDoor ()
    slime:setAnimation("door", "opening")
    slime:floor("images/cell-floor-open.png")
end


function cell.closeCellDoor ()
    slime:setAnimation("door", "closing")
    slime:floor("images/cell-floor-closed.png")
end


-- Picks up the spoon and place them in inventory
function cell.pickUpSpoon ()
    -- Face Ego to the player
    slime:turnActor("ego", "south")
    -- Add items to Ego's bag
    slime:bagInsert("ego", { ["name"] = "bowl", ["image"] = "images/bowl2.png" })
    slime:bagInsert("ego", { ["name"] = "spoon", ["image"] = "images/spoon.png" })
    -- Remove the bowl and spoon actor from the stage
    slime.actors:remove ("bowl and spoon")
end


-- Picks up the cement dust
function cell.pickUpDust ()
    slime:bagInsert("ego",
        { ["name"] = "cement dust", ["image"] = "images/inv-dust.png" })
    slime.actors.remove ("dust")
end


-- Creates an animation of falling dust where ego digs into the wall
function cell.addDustAnimation ()
    local dustActor = slime:actor("dust", 96, 34)
    local dustAnim = dustActor:tileset("images/dust.png", {w=5, h=6})
    dustAnim:define("fall", {'1-14', 1}, 0.2)
    dustAnim:define("still", {14, 1})
    slime:setAnimation("dust", "fall")
end


function cell.callback (event, object)

  if not event then return end

    slime:log(event .. " on " .. object.name)

    if (event == "moved" and object.name == "ego") then
        slime:interact(object.clickedX, object.clickedY)
    end

    if event == "interact" then

        -- give ego a bowl and a spoon inventory items
        if object.name == "bowl and spoon" then
            cell.pickUpSpoon()
        end

        -- Look at the hole in the wall
        if object.name == "hole" then
            slime:say("ego", "I see a hole in the wall")
        end

        -- Set the cursor when interacting on bag items
        if object.name == "spoon" then
            slime:setCursor(object.name, object.image, scale, 0, 0)
        end

        if object.name == "dust" then
            cell.pickUpDust()
        end

    end

    if event == "spoon" then
        if object.name == "door" then
            slime:say("ego", "The spoon won't open this door")
        end
        if object.name == "hole" then
            slime:turnActor("ego", "east")
            slime:setAnimation("ego", "dig")
            cell.addDustAnimation()
            slime:setCursor()
        end
    end

end


-- Clear and reposition the clickable buttons for the bag (inventory)
-- when it has items added or removed.
function cell.inventoryChanged (bag)
    slime.bagButtons = { }
    for counter, item in pairs(slime:bagContents("ego")) do
        slime:bagButton(item.name, item.image, counter * 10, bagPosition)
    end
end


function cell.animationLooped (actor, key, counter)

    if actor == "door" then

        -- Keep the door closed after the closing animation played.
        if key == "closing" then
            slime:setAnimation("door", "closed")
        end

        -- Keep the door open after the opening animation played.
        if key == "opening" then
            slime:setAnimation("door", "open")
        end

    end

    if actor == "dust" then
        slime:setAnimation("dust", "still")
        slime:setAnimation("ego", nil)
    end

end

-- Handle Love events

-- Clicks below this point skip actor movement
bagPosition = 86

function love.load ()
    -- Nearest image interpolation (pixel graphics, no anti-aliasing)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    cell.setup()
end

function love.draw ()
    love.graphics.push()
    love.graphics.scale(scale)
    slime:draw(scale)
    love.graphics.pop()
    slime:debugdraw()
end

function love.update (dt)
    slime:update(dt)

    -- display hover over objects
    local x, y = love.mouse.getPosition()
    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)
    local objects = slime:getObjects(x, y)
    if objects then
        local items = ''
        for _, hoverobject in pairs(objects) do
            items = string.format("%s %s", hoverobject.name, items)
        end
        slime:status(items)
    else
        slime:status()
    end

end

function love.keypressed (key, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
end

-- Left clicking moves our Ego actor, and interacts with objects.
function love.mousepressed (x, y, button)

    -- Adjust for scale
    x = math.floor(x / scale)
    y = math.floor(y / scale)

    -- Left mouse button
    if button == 1 then

        -- The point is in our bag inventory area
        if (y > bagPosition) then
            slime:interact(x, y)
        else
            if slime:someoneTalking() then
                slime:skipSpeech()
            else
                -- Move Ego then interact with any objects
                slime:moveActor("ego", x, y)
            end
        end

    end

    -- Right clicks uses the default cursor
    if button == 2 then
        slime:setCursor()
    end

end
