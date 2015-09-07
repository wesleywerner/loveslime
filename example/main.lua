slime = require ("slime")

function love.load()
    
    -- Nearest image interpolation (pixel graphics, no anti-aliasing)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    -- Load the first room
    cellRoom()
    
end

function love.draw()

    -- scale the graphics larger to see our pixel art better.
    love.graphics.push()
    love.graphics.scale(4, 4)
    slime.draw(4, 4)
    love.graphics.pop()
    
    -- Display debug info (only works if slime.debug["enabled"] == true)
    slime.debugdraw()

end

function love.update(dt)
    
    slime.update (dt)
    updateStatus()

end

function love.keypressed( key, isrepeat )
    if key == "escape" then
        love.event.quit()
    end
    if key == "tab" then
        slime.debug.enabled = not slime.debug.enabled and true or false
    end
end

function love.mousepressed(x, y, button)
    if button == "l" then
        -- Adjust for scale
        x = math.floor(x / 4)
        y = math.floor(y / 4)
        slime.moveActor("ego", x, y)
    end
end

function updateStatus()
    
    local x, y = love.mouse.getPosition( )
    
    -- Adjust for scale
    x = math.floor(x / 4)
    y = math.floor(y / 4)
    
    local obj = slime.getObject(x, y)
    
    if (obj) then
        --print(obj, obj.name)
        slime.status(obj.name)
    else
        slime.status()
    end
    
end

-- Since the player's actor, or Ego, will appear in many scenes
-- it is easier to set up this actor with a function for re-use.
function setupEgoAnimations(ego)

    -- actor movement delay in ms
    ego.movedelay = 0.05

    -- The idle animation plays when the actor is not walking or talking.
    -- We have two frames, the first shows for a few seconds,
    -- the second flashes by to make the actor blink.
    slime.idleAnimation (ego,
                        "green-monster.png",
                        12, 12,         -- tile width & height
                        {'11-10', 1},   -- south
                        {3, 0.2},       -- delays
                        {'3-2', 1},     -- west
                        {3, 0.2},       -- delays
                        {18, 1},        -- north
                        1,              -- delays
                        nil,            -- east
                        nil             -- (auto flipped from west)
                        )

    slime.walkAnimation (ego,
                        "green-monster.png",
                        12, 12,         -- tile width & height
                        {'11-14', 1},   -- south
                        0.2,            -- delays
                        {'6-3', 1},     -- west
                        0.2,            -- delays
                        {'18-21', 1},   -- north
                        0.2,            -- delays
                        nil,            -- east
                        nil             -- (auto flipped from west)
                        )


    --ego:talkAnimation ("green-monster.png",
                        --12, 12,         -- tile width & height
                        --{'15-17', 1},   -- north
                        --0.2,            -- delays
                        --{'7-9', 1},     -- east
                        --0.2,            -- delays
                        --{'15-17', 1},   -- south
                        --0.2,            -- delays
                        --{'7-9', 1},     -- west
                        --0.2             -- delays
                        --)
                            
end

function cellRoom()

    slime.reset()

    slime.background("background.png")
    slime.layer("background.png", "layer-mask.png", 50)
    slime.floor("walk-door-open-mask.png")

    local ego = slime.actor("ego", 70, 50)
    setupEgoAnimations(ego)


end
