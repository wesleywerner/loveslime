-- We organize all our game actors in this file to keep things neat.

-- Since the player's actor, or Ego, will appear in many scenes
-- it is easier to set up this actor with a function for re-use.
function addEgoAnimations(ego)

    -- actor movement delay in ms
    ego.movedelay = 0.05

    -- The idle animation plays when the actor is not walking or talking.
    -- We have two frames, the first shows for a few seconds,
    -- the second flashes by to make the actor blink.
    slime.idleAnimation ("ego",
                        "images/green-monster.png",
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

    slime.walkAnimation ("ego",
                        "images/green-monster.png",
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


    slime.talkAnimation ("ego",
                        "images/green-monster.png",
                        12, 12,         -- tile width & height
                        {'15-17', 1},   -- south
                        0.2,            -- delays
                        {'7-9', 1},     -- west
                        0.2,            -- delays
                        {'15-17', 1},   -- north
                        0.2,            -- delays
                        nil,            -- east
                        nil             -- (auto flipped from west)
                        )
                            
end
