# SLIME

SLIME is a point-and-click adventure game library for L&Ouml;VE. It is inspired by the [SLUDGE game engine](https://opensludge.github.io/).

The name is an acronym for "SLUDGE to L&Ouml;VE Inspired Mimicry Environment".

**Status:** In Development  
**Version:** 0.1  

---

1. [Features](#features)
1. [Thanks](#thanks)
1. [API Reference](#slime-api)
    1. [Notes and Terminology](#notes)
    1. [Stage setup](#stage-setup)
    1. [Callbacks](#callbacks)
    1. [Reset](#reset)
    1. [Backgrounds](#backgrounds)
    1. [Layers](#layers)
    1. [Actors](#actors)
    1. [Animations](#animations)
    1. [Hotspots](#hotspots)
    1. [Status](#status)
    1. [Drawing](#drawing)
    1. [Speech](#speech)
    1. [Bags](#bags)
    1. [Cursors](#cursors)
    1. [Settings](#settings)
1. [Code Snippets](#code-snippets)
1. [License](#license)

---

# Features

* Animated backgrounds
* Actors with directional movement
* Path finding movement
* Status text
* Hotspots
* Actor Speech
* Bags (inventory)

# Thanks

I want to thank these people for making use of their code:

* kikito, for your animation library, [anim8](https://love2d.org/wiki/anim8).
* GloryFish, for your [A* path finding](https://github.com/GloryFish/lua-astar) lua code.
* Bresenham's Line Algorithm [from roguebasin.com](http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua)

Thank you!

---

# SLIME API

This API reference lists the available functionality of SLIME. You should read the [SLIME tutorial](https://github.com/wesleywerner/loveslime/blob/master/tutorial/tutorial.md) to see an example how these are used.

To use SLIME simply `require`:

    slime = require ("slime")

## Notes
  
* The cardinal directions are oriented so that `SOUTH` points to the bottom of your screen, and `NORTH` to the top. So an actor facing `SOUTH` is looking at the player.
* Whenever an image is passed to SLIME, assume it is the filename of the image. The image data will be loaded for you.

## Terminology

* Stage: A room or game screen.
* Actors: Visible objects on the stage that may be animated or have static images, they can move around or be stationary.
* Hotspots: Invisible areas on the stage that the player can interact with.
* Floor: Defines where actors are able to walk.
* Layers: Defines areas where actors can walk behind.
* Bags: A short synonymn for inventory.

## Stage setup

To set up your stage for play you need to clear objects, load a background, set the floor, add any layers, actors and hotspots.

A basic stage setup might look like this:

    function setupStage ()
        slime:reset ()
        slime:background ("background.png")
        slime:layer ("background.png", "layer.png", 50)
        slime:floor ("floor.png")
        addActors ()
        addHotspots ()
        slime.callback = myStageCallback
    end

    function myStageCallback (event, object)
        if (event == "moved") then
            if (object.name == "ego") then
                -- The "ego" actor reached her destination.
                -- object is an instance of the actor.
            end
        end
        if (event == "interact") then
            if (object.name == "spoon") then
                -- An actor or hotspot was interacted with (you called slime:interact (x, y))
                -- object is an instance of the actor or hotspot.
            end
        end
    end

## Callbacks

These SLIME callbacks trigger on certain game events.

![func](api/func.png) `slime.callback (event, object)`

This callback notifies you when an actor has moved, or the player interacts something.

**event**:  

* moved: an actor was told to move and has reached their destination.
* interact: an object was clicked on (via `interact (x, y)`).

**object**:  

The related actor or hotspot. When this is an actor from a "moved" event, you can access the `x/y` where the actor was told to move with:

    object.clickedX
    object.clickedY

These may be different than the actor's actual `x` and `y` if the floor does not allow walking to the position exactly. In these cases the actor will try to get as close as possible, but you still want the clicked position to call the `interact (x, y)` function.

![func](api/func.png) `slime.inventoryChanged (bag)`

This callback notifies you when a bag's content has changed. The name of the bag is passed.

![func](api/func.png) `slime.animationLooped (actor, key, counter)`

Called when an actor's animation loops. 

**actor**:

This is the name of the actor whose animation has looped.

**key**:

This is the key of the animation that looped.

**counter**:

This is the number of times the animation has looped.

## Reset

![func](api/func.png) `slime:reset ()`

Clear the stage, actors and hotspots. Call this before setting up a new stage. Note that bags (inventories) are _not_ cleared.

## Backgrounds

![func](api/func.png) `slime:background (backgroundfilename, [, delay])`

Add a background to the stage. `delay` sets how many milliseconds to display the background if multiple backgrounds are loaded, and may be omitted if only one background is set.

![func](api/func.png) `slime:floor (floorfilename)`

Set the floor where actors can walk. This is an image where black (`#000`) indicates non-walkable areas, and any other color for walkable.

## Layers

Layers define areas of your background where actors can walk behind.

![func](api/func.png) `slime:layer (background, mask, baseline)`

Add a walk-behind layer. The `background` is where to cut the layer from. The `mask` defines where to cut.

The mask is an image with black (`#000`) where there is no layer, or any other colour to indicate the hide-behind layer.

The `baseline` is the y-position a character needs to be behind in order to be hidden by the layer.

## Actors

Actors are items on your stage that may move or talk, like people, animals or robots. They can also be inanimate objects that may not move or talk but are animated, like doors, toasters and computers.

![func](api/func.png) `slime:actor (name, x, y)`

Adds an actor to the stage. The actor object is returned:

    local boss = slime:actor ("Big Boss", 100, 100)
    boss.speechcolor = {255, 0, 0}     -- Set the speech color for this actor as {red, green, blue}

![func](api/func.png) `slime:removeActor (name)`  

Removes the actor named `name`

![func](api/func.png) `slime:getActor (name)`  

Gets the actor by name. 

![func](api/func.png) `actor:setImage (path)`

Sets a static (non-animated) image as the actor's sprite.

![property](api/prop.png) `actor.nozbuffer`

Set this property to `true` if this actor draws above all layers.

    boss.nozbuffer = true

## Animations

You define animations on actor objects.

![func](api/func.png) `actor:tileset (path, {w, h})`  

Loads a tileset for the actor, and returns the object used to define animation frames. The `size` is the width and height of each frame.

    local tileset = ego:tileset("ego.png", {w=12, h=12})

![func](api/func.png) `{tileset}:define (key)`  

Defines a new animation on a tileset object. This returns the object used to define animation frames.

![func](api/func.png) `{animation}:frames (frames)`  
![func](api/func.png) `{animation}:delays (delays)`  

Sets the frames that make up an animation.

The format of the `frames` and `delays` follow the [anim8 library](https://github.com/kikito/anim8) convention. I recommend you go over there to read about the Frames format.

    local tileset = ego:tileset("ego.png", {w=12, h=12})
    local anim = tileset:define("walk south")
    anim:frames({'1-5', 1)  -- frames 1 through 5 on the first row in the tileset
    anim:delays(0.2)        -- 0.2 seconds delay for all frames

The animation object can chain calls for cleaner code:

    local tileset = ego:tileset("ego.png", {w=12, h=12})
    tileset:define("walk south"):frames({'1-5', 1):delays(0.2)
    tileset:define("walk north"):frames({'6-9', 1):delays(0.2)

![func](api/func.png) `{animation}:flip ()`  

You can mirror an animation:

    -- create an east facing animation by flipping west facing frames
    tileset:define("walk west"):frames({'10-15', 1):delays(0.2)
    tileset:define("walk east"):frames({'10-15', 1):delays(0.2):flip()

![func](api/func.png) `{animation}:sounds (sounds)`  

The `sounds` function takes an indexed table of sound sources, each sound plays when the corresponding frame position is drawn.

    -- play step.wav when frame 1 shows. Occurs every animation loop.
    tileset:define("walk west")
        :frames({'10-15', 1)
        :delays(0.2)
        :sounds( {[1] = "step.wav"} )

![func](api/func.png) `{animation}:offset ({x, y})`  

The `offset` function takes `{x, y}` which displaces the drawing of frames. This is used in special cases when your actor has a certain animation with a different tileset size than it's normal frames. Switching to such an animtion makes the draw position jump since the center of the larger frames don't line up with the normal frames. Compensate for this variation with the offset.

![func](api/func.png) `slime:animationDuration(actor, key)`  

Returns the duration of an animation in seconds. This value is the sum of all frame delays on an animation, and totals to one loop of the animation.

### Special Animation Keys

Actor animations with these keys will automatically be used by the SLIME engine. The direction an actor faces can be south, west, east or north.
The actions that are special are:

* idle: The actor is not speaking or walking. They are idle.
* walk: The actor is walking.
* talk: The actor is speaking.

Here is a sample of combinations of actor animation names that are picked up by SLIME:

* "idle north"
* "walk east"
* "talk south"

![func](api/func.png) `slime:moveActor (name, x, y)`  

Move an actor. There has to be a valid floor set for movement to find a path.

Example:

    slime:moveActor("ego", 90, 34)
    
![func](api/func.png) `slime:moveActorTo (name, target)`

Move an actor to another actor.

![func](api/func.png) `slime:turnActor (name, direction)`

Turns an Actor to face a direction, one of `south`, `west`, `north` or `east`.

## Hotspots

![func](api/func.png) `slime:hotspot (name, x, y, w, h)`

Adds a hotspot to the stage.

![func](api/func.png) `slime:interact (x, y)`

Interacts with all objects at `x, y`. This triggers an "interact" event in `slime.callback`.

Returns true if there are any objects at that position.

![func](api/func.png) `slime:getObjects (x, y)`

Gets a table of objects under `x/y`, or `nil` if no object is found.

## Status

![func](api/func.png) `slime:status (text)`

Set or unset the status bar text.

## Drawing

![func](api/func.png) `slime:update (dt)`

Update animated backgrounds, actor movements and animations.

![func](api/func.png) `slime:draw ([scale])`

Draw the scene to the display. The `scale` parameter defaults to 1, and is only needed if you called `love.graphics.scale` before calling this function.

## Speech

You can queue multiple speeches at once, the actor animation will change to "talk" and the words will print on screen.

![func](api/func.png) `slime:say (name, words)`

Make an actor say something.

![func](api/func.png) `slime:someoneTalking()`

Returns `true` if there is speech displaying.

## Bags

Bags are analogous to inventory. The bags system is very simple yet flexible: Each bag has a name and can hold multiple items. In this way it supports inventory for multiple actors.

![func](api/func.png) `slime:bagInsert (bag, object)`

Inserts something into a bag.

* The name of the `bag` can be anything, but for clarity, using an actor's name is a sensible choice.
* The `object` is a table with a `name` value. You can add your own values to the object too.

Example:

    local theSpoon = { ["name"] = "spoon" }
    slime:bagInsert ("ego", theSpoon)

![func](api/func.png) `slime:bagContents (bag)`

Gets the contents of a bag as a table.

![func](api/func.png) `slime:bagRemove (bag, name)`

Removes an item (`name`) from a `bag`.

![func](api/func.png) `slime:bagButton (name, image, x, y)`

Add a hotspot with an image that draws on screen. 


## Chains

Chains give you a way to script actor movement and dialogue in sequence. If your main actor needs to walk to a tree, says something witty, walk down to a pond and then jump in, chains allow you to script this.

![func](api/func.png) `slime:chain()`  

Creates and returns a new chain of events. Use this chain object to add the links to your chain. Links process in sequence, each waiting in turn until the one before it resolves.

![func](api/func.png) `chain:image (actor, path)`  

Calls `actor:setImage`. Resolves immediately.

![func](api/func.png) `chain:move (actor, x, y)`  
![func](api/func.png) `chain:move (actor, target)`  

Calls `slime:moveActor` or `slime:moveActorTo`, depending which paramters are given. Target is a string of another actor's name. Resolves when the given actor's movement path is emptied.

Also note that this fires the `slime.callback` event for "moved" as usual, that is to say, chained actions behave like the player performed them.

![func](api/func.png) `chain:turn (actor, direction)`  

Calls `slime:turnActor`. Resolves immediately.

![func](api/func.png) `chain:wait (duration)`  

Waits at this link for a duration of seconds.

![func](api/func.png) `chain:anim (actor, key [,wait])`  

Calls `slime:setAnimation`. Resolves immediately.

If `wait` is given as `true`, then the chain will wait for the duration of one animation loop.

For example, this code:

    chain:anim("ego", "throw dust")
    chain:wait(slime:animationDuration("ego", "throw dust"))

gives the same result as this line:

    chain:anim("ego", "throw dust", true)

![func](api/func.png) `chain:floor (path)`  

Calls `slime:floor`. Resolves immediately.

![func](api/func.png) `chain:func (func, params)`  

Calls the function `func` with the given parameters. Resolves immediately.

![func](api/func.png) `chain:say (actor, words)`  

Calls `slime:say`. Resolves when the given actor is not busy speaking. If `slime:skipSpeech` is called while the actor is talking, then this link will be resolved.

![func](api/func.png) `chain:sound (source)`

Plays the given audio source. Resolves immediately.

### Example Chain

    local chain = slime:chain()
    chain:move("ego", "light switch")
    chain:anim("ego", "flip the switch")
    chain:image("light", "light-on.png")
    chain:sound(love.audio.newSource("sounds/switch.wav", "static"))
    chain:say("ego", "Now I can see")


## Cursors

![func](api/func.png) `slime:setCursor (name, image, scale, hotx, hoty)`

Set a hardware cursor with scale applied.

When you set a cursor, the `name` is passed back as the `event` parameter to `slime.callback`. This makes it easy to check if the player is using a key on a door.

Call with no parameters to set the default cursor.

## Settings

SLIME offers these settings to customize your game. They are set through the `slime.settings` table, as in `slime.settings["setting name"] = true`

* "status position": The Y position where to print the built-in status text
* "status font": A love.graphics.Font object for drawing status
* "speech position": The Y position where to print speech
* "speech font": A love.graphics.Font object for drawing speech
* "walk and talk": Set to `true` to allow an actor talking while moving. Default is false.

---

# CODE SNIPPETS

## Flip the frames on a custom animation

The `addAnimation` call returns the Anim8 object which has flip functions:

    local myanim = slime:addAnimation("ego", "dig", "images/ego.png", tileSize, tileSize, {"22-25", 1}, 0.2)
    myanim:flipH()  -- flips horizontally
    myanim:flipV()  -- flips vertically

## One shot animations

To animate an actor once, like an opening door, hook into the Animation Looped callback:


    function slime.animationLooped (actor, key, counter)
        
        -- Keep the door closed after the closing animation played.
        if actor == "door" and key == "closing" then
            slime:setAnimation ("door", "closed")
        end
        
    end

Of course this assume you have added a "door" actor with the "closing" and "closed" custom animations.

---

# LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.
