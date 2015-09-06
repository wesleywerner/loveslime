slime = require ("slime")

function love.load()
    
    -- nearest image interpolation
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    
    slime.background("background.png")
    slime.layer("background.png", "layer-mask.png", 50)
    slime.floor("walk-door-open-mask.png")

    local ego = slime.actor("ego", 70, 50)
    ego.movedelay = 0.05
    
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

function love.draw()

    -- scale the graphics larger to see our pixel art better.
    love.graphics.push()
    love.graphics.scale(4, 4)
    slime.draw()
    love.graphics.pop()
    
    -- Display debug info.
    -- This only works if slime.debug["enabled"] == true
    slime.debugdraw()

end

function love.update(dt)
    
    slime.update (dt)

end

function love.keypressed( key, isrepeat )
    if key == "escape" then
        love.event.quit()
    end
    if key == "r" then
        slime.reset()
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
