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

_TODO_

* Actor animations. Certain animation keys like "Walk East" and "Walk West" are automatically used for movement. Custom actions can be triggered via `AnimateActor ("jump", [repeat count], [callback])` (pseudocode).
* Pathfinding movement. Read an image mask that is converted into the walkable map.
* Hotspots. Define regions that fires a callback on click.
* Cursors. Set with a mode like "pointer", "look", "take". The mode is passed to hotspot or actor callbacks.

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
