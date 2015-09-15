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

* Tutorial

# Thanks

I want to thank these people for making use of their code:

* kikito, for your animation library, [anim8](https://love2d.org/wiki/anim8).
* GloryFish, for your [A* path finding](https://github.com/GloryFish/lua-astar) lua code.
* Bresenham's Line Algorithm [from roguebasin.com](http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua)

Thank you!

# Building

These steps detail setting up to build for a release of SLIME. If you intend to only use the library for _making_ a game (and not developing SLIME) then consider using one of the provided **release packages** instead.

1. Clone this repository. The `--recursive` option will fetch submodules for you.

    git clone --recursive git@github.com:wesleywerner/loveslime.git
    
2. We need to copy the dependency modules into slime, and update one line so that the `require` call can find the module. From the root SLIME directory:
    * Copy over the required files  
        cp lua-astar/{astar,middleclass}.lua slime/
        cp anim8/anim8.lua slime/
    * Update the require path  
        sed -i "s/require 'middleclass'/require 'slime.middleclass'/g" slime/astar.lua


---

# SLIME API

To use SLIME simply `require` it into your `main.lua`:

    slime = require ("slime.slime")

A note on Direction:
  
The cardinal directions are oriented so that `SOUTH` points to the bottom of your screen, and `NORTH` to the top. So an actor facing `SOUTH` is looking at the player.

## Backgrounds

![func](api/func.png) `slime.background (backgroundfilename, [, delay])`

Add a background to the stage. `delay` sets how many milliseconds to display the background if multiple backgrounds are loaded, and may be omitted if only one background is set.

![func](api/func.png) `slime.floor (floorfilename)`

Set the floor where actors can walk. This is an image where black (`#000`) indicates non-walkable areas, and any other color for walkable.

## Layers

Layers define areas of your background where actors can walk behind.

![func](api/func.png) `slime.layer (backgroundfilename, maskfilename, baseline)`

Add a new layer over the `background` using the `mask` image. The mask is an image with black (`#000`) where there is no layer, or any other colour to indicate a hide-behind layer.

The `baseline` is the y-position a character needs to be behind in order to be hidden by the layer.

## Actors

Actors are items on your stage that may move or talk, like people, animals or robots. They can also be inanimate objects that may not move or talk but are animated, like doors, toasters and computers.

![func](api/func.png) `slime.actor (name)`

Adds and returns an actor to the stage. After this call you need to give the actor a position and image/animation for it to become visible on the stage. These properties are available:

    actor.x = 50    -- The actor position.
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

![func](api/func.png) `slime.addAnimation (name, key, tileset, w, h, frames, delays)`  

This is for adding custom animations.

* The `name` of the actor that was created via `slime.actor`
* The `key` is the animation key.
* The `w` and `h` are the width and height of each frame.
* The `frames` and `delays` are the frames and delays for the animation.

![func](api/func.png) `slime.moveActor (name, x, y, callback)`

Move an actor by `name` to a point. There has to be a valid path to the destination. The `callback` is fired when the actor reaches the destination.

Example:

    local turnEgo = function() slime.turnActor("ego", "east") end
    slime.moveActor("ego", 90, 34, turnEgo)
    
![func](api/func.png) `slime.moveActorTo (name, target, callback)`

Move actor `name` to another actor `target`.

![func](api/func.png) `slime.turnActor (name, direction)`

Turns an Actor to face a direction, one of `south`, `west`, `north` or `east`.

Note that because movement is asyncronous, calling this while an actor is moving won't have any effect as their movement will override their facing direction. This can be solved by calling `turnActor` as a callback to `moveActor`.

## Hotspots

![func](api/func.png) `slime.hotspot (name, callback, x, y, w, h [,data])`

Adds a hotspot to the stage. The `callback` will fire if the pointer is over the hotspot when `slime.interact` is called.

The optional `data` value gets passed to your callback. This is useful for when you have multiple hotspots that all use the same callback function.

![func](api/func.png) `slime.interact (x, y)`

Check if any object is under `x/y` and fire it's handler.

Returns `true` if the handler was fired.

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
