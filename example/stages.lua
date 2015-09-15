-- This is our prison cell room
function cellRoom()

    -- Make sure everything is cleared for our new stage
    slime.reset()

    -- Add the background
    slime.background("images/cell-background.png")
    
    -- Apply a layer where actors can walk behind walls
    slime.layer("images/cell-background.png", "images/cell-layer.png", 50)
    
    -- Set the floor that actors can walk on
    slime.floor("images/cell-floor-closed.png")
    
    -- Add a hole in the wall hotspot
    slime.hotspot("hole", holeHandler, 92, 23, 9, 9)

    -- Add our main actor, Ego
    local ego = slime.actor("ego")
    ego.x, ego.y = 70, 50
    addEgoAnimations(ego)
    
    -- Add a bowl on the floor as an actor
    local bowl = slime.actor("bowl")
    bowl.x, bowl.y = 65, 37
    slime.addImage("bowl", love.graphics.newImage("images/bowl1.png"))
    bowl.callback = bowlHandler
    
end

-- Called when interacting with the hole in the wall
function holeHandler ( data )
    
    slime.log ("dig cement")
    slime.turnActor ("ego", "east")
    slime.bagRemove ("ego", "spoon")
    
end

function bowlHandler ( )

    -- give ego a bowl and a spoon inventory items
    slime.bagInsert ("ego", { ["name"] = "bowl", ["image"] = love.graphics.newImage("images/bowl2.png") })
    slime.bagInsert ("ego", { ["name"] = "spoon", ["image"] = love.graphics.newImage("images/spoon.png") })
    
        
    slime.turnActor ("ego", "south")
    slime.addSpeech ("ego", "I can't pick it up yet...")
    slime.addSpeech ("ego", "but I hope to soon!")
end
