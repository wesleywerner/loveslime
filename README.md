# SLIME

SLIME is a point-and-click adventure game library for L&Ouml;VE. It is inspired by the [SLUDGE game engine](https://opensludge.github.io/).

The name is an acronym for "SLUDGE to L&Ouml;VE Inspired Mimicry Environment".

**Status:** In Development  
**Version:** 0.1  

# Features

* Animated backgrounds.
* Animated actors with directional movement.
* A Star path finding movement.
* Status text.
* Hotspots - Regions that fires a callback on click.
* Actor Speech

**TODO**  


# Thanks

I want to thank these people for making use of their code:

* kikito, for your animation library, [anim8](https://love2d.org/wiki/anim8).
* GloryFish, for your [A* path finding](https://github.com/GloryFish/lua-astar) lua code.
* Bresenham's Line Algorithm [from roguebasin.com](http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua)

Thank you!

---

# SLIME API

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

![func](api/func.png) `slime.actor (name, x, y [, hotspotY, hotspotY, image])`  

Add a new actor to the stage and returns the new actor object.

  * The `name` identifies the actor. You can use the same name multiple times, however when calling `moveActor` (which take the name) only the first actor with that name is moved.
  * The `x` and `y` sets the starting position of the actor.
  * Optional `hotspot X` and `hotspot Y` sets the point relative to the `x/y`. This point determines when an actor is considered behind a layer baseline. It is also the offset used to draw the actor sprite. If no hotspot is given, it will default to centered at the base of the sprite for animated actors, and to `0,0` for static image actors.
  * Optional `image` is a static (non-animated) image file name to use for the actor's sprite.
  
The returned actor object has these additional properties you may optionally set:

    actor["speechcolor"] = {255, 255, 255}          -- Set the speech color for this actor as {red, green, blue}

**Direction**
  
The cardinal directions are oriented to your screen so that `SOUTH` points to the bottom of your screen, and `NORTH` to the top. So an actor facing `SOUTH` is looking at the player.

![func](api/func.png) `slime.idleAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.walkAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.talkAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  

These are helper functions that in turn call `addAnimation` with the `keys` "idle", "walk" and "talk" respectively. 

  * The `actor` is an instance create via `slime.actor`
  * The `tileset` is a file name.
  * The `w` and `h` are the width and height of each frame.
  * The `south` and `southd` are the frames and delays for the south-facing animation.
  * The other directions are optional but recommended. `SOUTH` will be used as default if none of the other directions are given.

The format of the `south` frames and delays following the [anim8 library](https://github.com/kikito/anim8) convention. I recommend you go over there to read about the Frames format.

Notes:

* The `tileset` is a file name to the image tileset, they are cached for re-use. Multiple actors who use the same tileset will re-use the cached copies.
* Only `south` and `southd` parameters are mandatory. If the rest are omitted then south will be used as the default for all directions.
* If a `west` parameter is given, and `east` is `nil` or omitted, then the west animation will automatically be mirrored and used for the `east`.

![func](api/func.png) `slime.addAnimation (actor, key, tileset, w, h, frames, delays)`  

This is for adding custom animations.

  * The `actor` is an instance create via `slime.actor`
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

![func](api/func.png) `slime.hotspot(name, callback, x, y, w, h)`

Adds a hotspot to the stage. The callback will fire if the pointer is over the hotspot when `slime.interact` is called.

![func](api/func.png) `slime.interact (x, y)`

Check if any object is under `x/y` and fire it's callback if there is on.

Returns `true` if the callback was fired.

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
