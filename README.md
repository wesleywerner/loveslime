# SLIME

SLIME is a point-and-click adventure game library for L&Ouml;VE. It is inspired by the [SLUDGE game engine](https://opensludge.github.io/).

The name is an acronym for "SLUDGE to L&Ouml;VE Inspired Mimicry Environment".

**Status:** In Development  
**Version:** 0.1  

# Features

* Animated backgrounds.
* Animated actors with directional movement.
* A Star path finding movement.

**TODO**  

* Hotspots - Regions that fires a callback on click.
* Customer cursors.
* Text status bar.
* Actor dialogues.

---

# SLIME API

## Backgrounds

![func](api/func.png) `slime.background (image, [, delay])`

Add a background to the stage. `delay` sets how many milliseconds to display the background if multiple backgrounds are loaded, and may be omitted if only one background is set.

![func](api/func.png) `slime.walkable (mask)`

Set the areas that are walkable by actors, where black (`#000`) indicates non-walkable areas, and any other color for walkable.

## Layers

Layers define areas of your background where actors can walk behind.

![func](api/func.png) `slime.layer (source, mask, baseline)`

Set a new layer on the `source` background using the `mask` image. The mask is an image of the same dimensions as the background.

The `baseline` is the y-position a character needs to be behind in order to be hidden by the layer.

## Actors

The cardinal directions are oriented to your screen so that `SOUTH` points to the bottom of your screen, and `NORTH` to the top. So an actor facing `SOUTH` is looking at the player.

![func](api/func.png) `slime.actor (name, x, y, hotspotx, hotspoty)`  

Add a new actor to the stage.

  * `name` identifies the actor. You can use the same name multiple times, however when calling `moveActor` (which take the name) only the first actor with that name is moved.
  * `x` and `y` sets the starting position of the actor.
  * `hotspotx` and `hotspoty` sets the hotspot of the actor. The default actor hotspot (if not given) to centered at the base of the image.
  
![func](api/func.png) `slime.idleAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.walkAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  
![func](api/func.png) `slime.talkAnimation (actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`  

These are helper functions that in turn call `addAnimation` with the `keys` "idle", "walk" and "talk" respectively. 

  * `actor` is an instance create via `slime.actor`
  * `tileset` is the filename of the image tileset.
  * `w` and `h` are the width and height of each frame.
  * `south` and `southd` are the frames and delays for the south-facing animation.
  * The other directions are optional but recommended. `SOUTH` will be used as default if none of the other directions are given.
  
Notes:

* `tileset` is a file name to the image tileset, they are cached for re-use. Multiple actors who use the same tileset will re-use the cached copies.
* Only `south` and `southd` parameters are mandatory. If the rest are omitted then south will be used as the default for all directions.
* If a `west` parameter is given, and `east` is `nil` or omitted, then the west animation will automatically be mirrored and used for the `east`.

![func](api/func.png) `slime.addAnimation (actor, key, tileset, w, h, frames, delays)`  

This is for adding custom animations.

  * `actor` is an instance create via `slime.actor`
  * `key` is the animation key.
  * `w` and `h` are the width and height of each frame.
  * `frames` and `delays` are the frames and delays for the animation.

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
