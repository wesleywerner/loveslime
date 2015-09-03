slime = require ("slime")

function love.load()
    
    -- nearest image interpolation
    love.graphics.setDefaultFilter( "nearest", "nearest", 1 )
    
    local background = love.graphics.newImage("background.png")
    local background2 = love.graphics.newImage("background2.png")
    local mask = love.graphics.newImage("mask.png")
    local scientist = love.graphics.newImage("scientist.png")
    
    slime.background(background, 0, 0, 2)
    slime.background(background2, 0, 0, 1)
    slime.layer(background, mask, 0, 0, 62)

    slime.actor("ego", scientist, 28, 61)
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
    if love.keyboard.isDown("left") then
        slime.moveActor("ego", -20 * dt, 0)
    end
    if love.keyboard.isDown("right") then
        slime.moveActor("ego", 20 * dt, 0)
    end
    if love.keyboard.isDown("up") then
        slime.moveActor("ego", 0, -20 * dt)
    end
    if love.keyboard.isDown("down") then
        slime.moveActor("ego", 0, 20 * dt)
    end
    if love.keyboard.isDown("a") then
        slime.moveActor("scientist", -20 * dt, 0)
    end
    if love.keyboard.isDown("d") then
        slime.moveActor("scientist", 20 * dt, 0)
    end
    if love.keyboard.isDown("w") then
        slime.moveActor("scientist", 0, -20 * dt)
    end
    if love.keyboard.isDown("s") then
        slime.moveActor("scientist", 0, 20 * dt)
    end
    
    slime.update (dt)

end

function love.keypressed( key, isrepeat )
    if key == "escape" then
        love.event.quit()
    end
    if key == "r" then
        slime.reset()
    end
end
