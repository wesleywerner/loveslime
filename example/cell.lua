-- This is our prison cell room
function cellRoom()

    -- Make sure everything is cleared for our new stage
    slime.reset()

    -- Add the background
    slime.background("background.png")
    
    -- Apply a layer where actors can walk behind walls
    slime.layer("background.png", "layer-mask.png", 50)
    
    -- Set the floor that actors can walk on
    slime.floor("walk-door-open-mask.png")
    
    -- Add a hole in the wall hotspot
    slime.hotspot("hole", holeInteraction, 92, 23, 9, 9)

    -- Add our main actor, Ego
    local ego = slime.actor("ego", 70, 50)
    setupEgoAnimations(ego)
    
    -- Add a bowl on the floor as an actor
    local bowl = slime.actor("bowl", 65, 37, 2, 5, "bowl1.png")
    bowl.callback = bowlInteraction
    


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

-- Called when interacting with the hole in the wall
function holeInteraction ( )
    
    local turnEgo = function() slime.turnActor("ego", "east") end
    
    slime.moveActor("ego", 90, 34, turnEgo)
    
end

function bowlInteraction ( )
    local function takeBowl ()
        slime.log("take the bowl")
    end
    slime.moveActorTo ("ego", "bowl", takeBowl)
end
