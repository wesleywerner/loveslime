-- Copyright (c) 2021 Wesley Werner
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--- A basic sprite animation module using Löve quads.
-- It only supports sprite sheets that have no offsets or padding. The individual
-- sprites also have to be the same size. Useful to get you up and running or
-- for prototyping. You will no doubt seek, and are encouraged to find, a
-- more feature rich animation library.
-- @module simpleanim

local anim = {}

--- Create and return a new animation pack.
-- The arguments define the sprite sheet size and individual sprite frame size.
--
-- @tparam number ref_w
-- The total sprite sheet width, this is passed to the quad reference width parameter.
--
-- @tparam number ref_h
-- The total sprite sheet height, this is passed to the quad reference height parameter.
--
-- @tparam number sprite_w
-- The width of an individual sprite.
--
-- @tparam number sprite_h
-- The heigt of an individual sprite.
--
-- @return
-- The animation pack. Store it somewhere safe, you need to pass it to
-- the other functions in this module.
function anim.new (ref_w, ref_h, sprite_w, sprite_h)

    local instance = {
        ref_w=ref_w,
        ref_h=ref_h,
        sprite_w=sprite_w,
        sprite_h=sprite_h,
        db={}
    }
    return instance

end

--- Add animation frames to existing pack.
-- The Löve quads are generated and stored in the pack.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The identifying name of this animation. If the key exists in this pack it
-- will be clobbered.
--
-- @tparam table frames
-- A list of index pairs listed as {column, row, ...}.
-- The index is one-based so that {1, 1} is the top-left frame and
-- {2, 1} the second frame on the top row, and so forth.
--
-- @tparam table delays
-- A list of numbers where each correspond to each column-row pair.
-- This is the time that a frame is displayed before moving on to the next frame.
-- If all frames for this key have the same duration you can give delays as a
-- single number.
function anim.add (pack, key, frames, delays)

    assert(type(frames)=="table", "missing argument: frames")
    assert(#frames % 2 == 0, "frames must contain pairs of col/row indexes")

    -- expand delays into a table with the value duplicated for each frame pair
    if type(delays) == "number" then
        local _expanded = {}
        for n=1, #frames / 2 do
            table.insert(_expanded, delays)
        end
        delays = _expanded
    end

    assert(type(delays)~="nil", "missing argument: delays")
    assert(#frames / 2 == #delays, "number of delays must equals number of frame pairs")

    local _data = {
        -- the number of currently drawn quad
        index=0,
        -- time left to display the current quad
        timer=0,
        -- flag tracks looped state
        has_looped = false,
        -- list of quads
        quads={},
        -- frame delays
        delays=delays
    }

    for pos=1, #frames, 2 do
        local _column = frames[pos]-1
        local _row = frames[pos+1]-1
        table.insert(_data.quads,
            love.graphics.newQuad(
                                _column * pack.sprite_w,
                                _row * pack.sprite_h,
                                pack.sprite_w, pack.sprite_h,
                                pack.ref_w, pack.ref_h))
    end

    pack.db[key] = _data
end

--- Updates an animation.
-- This reduces the display delay for the current frame, and forwards to
-- the next frame if the delay has expired.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The animation key to update.
--
-- @tparam number dt
-- The delta time value as given by Löve
function anim.update (pack, key, dt)

    local _data = pack.db[key]

    if not _data then return end

    -- reduce the current frame timing
    _data.timer = _data.timer - dt

    -- advance to the next frame with cycling
    _data.has_looped = false
    if _data.timer <= 0 then
        _data.index = (_data.index + 1) % (#_data.quads+1)
        if _data.index == 0 then
            _data.has_looped = true
            _data.index = 1
        end
        _data.timer = _data.delays[_data.index]
    end

end

--- Gets the current quad of an animation.
-- The quad returned matches the current frame for this key.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The animation key to query.
--
-- @return
-- A love.quad of the current animation frame.
function anim.quad_of (pack, key)

    local _data = pack.db[key]
    if _data then
        return _data.quads[_data.index]
    end

end

--- Gets the current frame index of an animation.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The animation key to query.
--
-- @return
-- The frame index.
function anim.frame_of (pack, key)

    return pack.db[key].index

end

--- Clears an animation delay and loop counters.
-- If you need to clear the delay or loop counters, for special animation
-- where you want to ensure they play from frame 1.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The animation key to reset.
function anim.reset (pack, key)

    local _data = pack.db[key]
    _data.index = 0
    _data.timer = 0
    _data.has_looped = false

end

--- Test if an animation has looped.
-- This flag is only true for the current update where the loop occurs.
-- The subsequent update will clear this flag, until the next loop is hit.
--
-- @tparam table pack
-- The animation pack you received from @{simpleanim.new}
--
-- @tparam string key
-- The animation key to query.
--
-- @return
-- True if the animation looped on this update.
function anim.looped (pack, key)

    return pack.db[key].has_looped

end

return anim
