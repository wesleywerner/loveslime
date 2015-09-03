slime = require ("slime")

function love.load()
    
    -- nearest image interpolation
    love.graphics.setDefaultFilter( "nearest", "nearest", 1 )
    
    local background = love.graphics.newImage("background.png")
    local background2 = love.graphics.newImage("background2.png")
    local mask = love.graphics.newImage("mask.png")
    local scientist = love.graphics.newImage("scientist.png")
    local walkzone = love.graphics.newImage("walkzone2.png")
    
    slime.background(background, 0, 0, 2)
    slime.background(background2, 0, 0, 1)
    slime.layer(background, mask, 0, 0, 62)
    slime.walkable(walkzone)

    local ego = slime.actor("ego", scientist, 40, 60)
    ego.movedelay = 0.05
    
    slime.actor("scientist", scientist, 68, 57)
    
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
