-- This is our prison cell room
function cellRoom()

    -- Make sure everything is cleared for our new stage
    slime.reset()

    -- Add the background
    slime.background("images/background.png")
    
    -- Apply a layer where actors can walk behind walls
    slime.layer("images/background.png", "images/layer-mask.png", 50)
    
    -- Set the floor that actors can walk on
    slime.floor("images/walk-door-open-mask.png")
    
    -- Add a hole in the wall hotspot
    slime.hotspot("hole", holeInteraction, 92, 23, 9, 9)

    -- Add our main actor, Ego
    addEgoAnimations(slime.actor("ego", 70, 50))
    
    -- Add a bowl on the floor as an actor
    local bowl = slime.actor("bowl", 65, 37, 2, 5, "images/bowl1.png")
    bowl.InteractCallback = bowlInteraction
    
end

-- Called when interacting with the hole in the wall
function holeInteraction ( )
    
    slime.log ("dig cement")
    slime.turnActor ("ego", "east")
    
end

function bowlInteraction ( )
    slime.log ("take the bowl")
    slime.turnActor ("ego", "south")
    slime.addSpeech ("ego", "I can't pick it up yet...")
    slime.addSpeech ("ego", "but I hope to soon!")
end
