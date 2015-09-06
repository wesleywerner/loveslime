# SLIME

SLIME is a point-and-click adventure game library for LÖVE.

# BUILDING

Meant for bundling the code and third-party libraries into a release.

    $ ./release.sh

# WHAT DOES SLIME STAND FOR

The name is an acronym for SLUDGE to LÖVE Inspired Mimicry Enrichment. 

It is inspired by the SLUDGE game engine.

# ROADMAP

**Version 0.1**

* Animated backgrounds.
* Actors.
* Pathfinding movement. Read an image mask that is converted into the walkable map.

_TODO_

* Actor animations. Certain animation keys like "Walk East" and "Walk West" are automatically used for movement. Custom actions can be triggered via `AnimateActor ("jump", [repeat count], [callback])` (pseudocode).
* Hotspots. Define regions that fires a callback on click.
* Cursors. Set with a mode like "pointer", "look", "take". The mode is passed to hotspot or actor callbacks.

# USING SLIME

## Setting the stage

`slime.background (image, x, y [, delay])`

Add a background to the stage. `x` and `y` set where the background is drawn, and the delay sets for how many milliseconds to display the background for when you have multiple (and ths animated) backgrounds.


## Adding actors

    The cardinal directions are oriented to your screen so that `SOUTH` points to the bottom of your screen, and `NORTH` to the top. So an actor facing `SOUTH` is looking at the player.

### `slime.actor (name, x, y, hotspotx, hotspoty)`
  * `name` identifies the actor. You can use the same name multiple times, however when calling `moveActor` (which take the name) only the first actor with that name is moved.
  * `x` and `y` sets the starting position of the actor.
  * `hotspotx` and `hotspoty` sets the hotspot of the actor. The default actor hotspot (if not given) to centered at the base of the image.
### `slime.idleAnimation`, `slime.walkAnimation`, `slime.talkAnimation`: `(actor, tileset, w, h, south, southd [, west, westd, north, northd, east, eastd])`
  * `actor` is an instance create via `slime.actor`
  * `tileset` is the filename of the image tileset.
  * `w` and `h` are the width and height of each frame.
  * `south` and `southd` are the frames and delays for the south-facing animation.
  * The other directions are optional but recommended. `SOUTH` will be used as default if none of the other directions are given.
### `slime.addAnimation (actor, key, tileset, w, h, frames, delays)`
  * `actor` is an instance create via `slime.actor`
  * `key` is the animation key.
  * `w` and `h` are the width and height of each frame.
  * `frames` and `delays` are the frames and delays for the animation.

## Layers

## Notes

* Actor animation tilesets are cached. Multiple actors who use the same tileset filename will re-use the cached tileset image.
* 

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
