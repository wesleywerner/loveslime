function love.conf(t)
    t.window.title = "SLIME Example Game"
    t.window.width = 170 * 4
    t.window.height = 96 * 4
    --t.window.fullscreen = true
    
    t.modules.joystick = false
    t.modules.physics = false
end
