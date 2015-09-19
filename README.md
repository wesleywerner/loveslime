# SLIME

SLIME is a point-and-click adventure game library for L&Ouml;VE. It is inspired by the [SLUDGE game engine](https://opensludge.github.io/).

The name is an acronym for "SLUDGE to L&Ouml;VE Inspired Mimicry Environment".

**Status:** In Development  
**Version:** 0.1  

# Features

* Animated backgrounds
* Actors with directional movement
* Path finding movement
* Status text
* Hotspots
* Actor Speech
* Bags (inventory)

**TODO**  

* Replace the `addAnimation` callback with a serializable solution
* Tutorial
* Tidy function parameter names

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
        slime.reset ()
        slime.background ("background.png")
        slime.layer ("background.png", "layer.png", 50)
        slime.floor ("floor.png")
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
                -- An actor or hotspot was interacted with (you called slime.interact (x, y))
                -- object is an instance of the actor or hotspot.
            end
        end
    end

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

## Reset

![func](api/func.png) `slime.reset ()`

Clear the stage, actors and hotspots. Call this before setting up a new stage. Note that bags (inventories) are _not_ cleared.

## Backgrounds

![func](api/func.png) `slime.background (backgroundfilename, [, delay])`

Add a background to the stage. `delay` sets how many milliseconds to display the background if multiple backgrounds are loaded, and may be omitted if only one background is set.

![func](api/func.png) `slime.floor (floorfilename)`

Set the floor where actors can walk. This is an image where black (`#000`) indicates non-walkable areas, and any other color for walkable.

## Layers

Layers define areas of your background where actors can walk behind.

![func](api/func.png) `slime.layer (background, mask, baseline)`

Add a walk-behind layer. The `background` is where to cut the layer from. The `mask` defines where to cut.

The mask is an image with black (`#000`) where there is no layer, or any other colour to indicate the hide-behind layer.

The `baseline` is the y-position a character needs to be behind in order to be hidden by the layer.

## Actors

Actors are items on your stage that may move or talk, like people, animals or robots. They can also be inanimate objects that may not move or talk but are animated, like doors, toasters and computers.

![func](api/func.png) `slime.actor (name)`

Adds and returns an actor to the stage. After this call you need to give the actor a position and image/animation for it to become visible on the stage. These properties are available:

    actor.x = 50
    actor.y = 50
    actor.speechcolor = {255, 255, 255}     -- Set the speech color for this actor as {red, green, blue}

![func](api/func.png) `slime.addImage (name, image)`

Sets a static (non-animated) image as an actor's sprite.

![func](api/func.png) `slime.idleAnimation (name, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.walkAnimation (name, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.talkAnimation (name, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  

These are helper functions that in turn call `addAnimation` with the `keys` "idle", "walk" and "talk" respectively. 

  * The `name` of the actor that was created via `slime.actor`
  * The `tileset` is a file name.
  * The `w` and `h` are the width and height of each frame.
  * The `south` and `southd` are the frames and delays for the south-facing animation.
  * The other directions are optional but recommended. `SOUTH` will be used as default if none of the other directions are given.

The format of the `south` frames and delays follow the [anim8 library](https://github.com/kikito/anim8) convention. I recommend you go over there to read about the Frames format.

Notes:

* The `tileset` is a file name to the image tileset, they are cached for re-use. Multiple actors who use the same tileset will re-use the cached copies.
* Only `south` and `southd` parameters are mandatory. If the rest are omitted then south will be used as the default for all directions.
* If a `west` parameter is given, and `east` is `nil` or omitted, then the west animation will automatically be mirrored and used for the `east`.

![func](api/func.png) `slime.addAnimation (name, key, tileset, w, h, frames, delays [,onLoop])`  

This is for adding custom animations.

* The `name` of the actor that was created via `slime.actor`
* The `key` is the animation key.
* The `w` and `h` are the width and height of each frame.
* The `frames` and `delays` are the frames and delays for the animation.
* If you give the `onLoop` value as a function, it will be called when the animation loops.

![func](api/func.png) `slime.moveActor (name, x, y)`

Move an actor. There has to be a valid floor set for movement to find a path.

Example:

    slime.moveActor("ego", 90, 34)
    
![func](api/func.png) `slime.moveActorTo (name, target)`

Move an actor to another actor.

![func](api/func.png) `slime.turnActor (name, direction)`

Turns an Actor to face a direction, one of `south`, `west`, `north` or `east`.

## Hotspots

![func](api/func.png) `slime.hotspot (name, x, y, w, h)`

Adds a hotspot to the stage.

![func](api/func.png) `slime.interact (x, y)`

Interacts with all objects at `x/y`. This triggers an "interact" event in `slime.callback`.

![func](api/func.png) `slime.getObjects (x, y)`

Gets a table of objects under `x/y`, or `nil` if no object is found.

## Status

![func](api/func.png) `slime.status (text)`

Set or unset the status bar text.

## Drawing

![func](api/func.png) `slime.update (dt)`

Update animated backgrounds, actor movements and animations.

![func](api/func.png) `slime.draw ([scale])`

Draw the scene to the display. The `scale` parameter defaults to 1, and is only needed if you called `love.graphics.scale` before calling this function.

## Actor Speech

You can queue multiple speeches at once, the actor animation will change to "talk" and the words will print on screen.

![func](api/func.png) `slime.addSpeech (name, text)`

Queue a speech for an actor by `name`.

![func](api/func.png) `slime.someoneTalking ()`

Returns `true` if there is speech displaying.

## Bags

Bags are analogous to inventory. The bags system is very simple yet flexible: Each bag has a name and can hold multiple items. In this way it supports inventory for multiple actors.

![func](api/func.png) `slime.bagInsert (bag, object)`

Inserts something into a bag.

* The name of the `bag` can be anything, but for clarity, using an actor's name is a sensible choice.
* The `object` is a table with a `name` value. You can add your own values to the object too.

Example:

    local theSpoon = { ["name"] = "spoon" }
    slime.bagInsert ("ego", theSpoon)

![func](api/func.png) `slime.bagContents (bag)`

Gets the contents of a bag as a table.

![func](api/func.png) `slime.bagRemove (bag, name)`

Removes an item (`name`) from a `bag`.

![func](api/func.png) `slime.bagButton (name, image, x, y)`

Add a hotspot with an image that draws on screen. 

## Settings

SLIME offers these settings to customize your game:

    slime.settings["status position"] = 70      -- The Y position to print the built-in status text
    slime.settings["status font size"] = 12     -- The font size for status text
    slime.settings["speech position"] = 0       -- The Y position to print speech
    slime.settings["speech font size"] = 10     -- The font size for speech

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
