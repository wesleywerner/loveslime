--- Graphical game development tools for SLIME.
--
-- @module ooze
local ooze = {
    _VERSION     = 'v0.1',
    _DESCRIPTION = 'Graphical game development tools for SLIME.',
    _URL         = 'https://github.com/wesleywerner/loveslime',
    _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2016-2022 Wesley Werner

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

-- Constants
local BLACK = {0, 0, 0}
local RED = {1, 0, 0}
-- TODO define colors
local UI_COLOR = {0, 1, 0} -- green
local HOTSPOT_COLOR = {1, 1, 0} -- yellow
local ACTOR_COLOR = {0, 0, 1} -- blue
local FEET_COLOR = {0, 1, 1} -- cyan
local LAYER_COLORS = {
                        {1, 0, 0, 0.5},     -- red
                        {0, 1, 0, 0.5},     -- green
                        {0.5, 0, 1, 0.5},   -- purple
                        {1, 0, 1, 0.5},     -- magenta
                    }


-- Default hotkeys
local hotkeys = {
    ui = "f1",
    actor = "f2",
    hotspot = "f3",
    layer = "f4",
    floor = "f5",
    log = "f6",
    watch = "f7",
    help = "h"
}

-- Window dimensions
local WIN_WIDTH, WIN_HEIGHT = 0, 0

-- Manages the love callback hooks and executing ooze functions.
local hook = {}

-- View instances
local view = {}
view.actor = {}
view.help = {}
view.hotspot = {}
view.layer = {}
view.log = {}
view.floor = {}
view.ui = {}
view.watch = {}


--  _                 _
-- | |__   ___   ___ | | _____
-- | '_ \ / _ \ / _ \| |/ / __|
-- | | | | (_) | (_) |   <\__ \
-- |_| |_|\___/ \___/|_|\_\___/
--

--- Initialize Ooze.
-- Replaces the love callbacks with Ooze hooks
-- and returns a function to receive the slime reference from the caller.
function hook.init ()

    assert(love ~= nil, "Ooze did not detect the Löve namespace")

    -- Welcome! Grab the window size.
    print("Initializing Ooze")
    WIN_WIDTH, WIN_HEIGHT = love.graphics.getDimensions()

    -- Replace love's callbacks
    if type(love.draw) == "function" then
        hook.draw_ref = love.draw
        love.draw = hook.draw
    end
    if type(love.keypressed) == "function" then
        hook.keypressed_ref = love.keypressed
        love.keypressed = hook.keypressed
    end
    if type(love.mousemoved) == "function" then
        hook.mousemoved_ref = love.mousemoved
        love.mousemoved = hook.mousemoved
    end
    if type(love.mousepressed) == "function" then
        hook.mousepressed_ref = love.mousepressed
        love.mousepressed = hook.mousepressed
    end
    if type(love.update) == "function" then
        hook.update_ref = love.update
        love.update = hook.update
    end
    if type(love.wheelmoved) == "function" then
        hook.wheelmoved_ref = love.wheelmoved
        love.wheelmoved = hook.wheelmoved
    end

    -- SLIME reference getter
    return function(ref)
        ooze.slime = ref
        -- Initialize views
        view.ui.init()
        for _, label in ipairs(view.ui.label) do
            if type(view[label.viewname].init) == "function" then
                view[label.viewname].init()
            end
        end
    end

end

function hook.draw ()

    -- Call the original love callback
    hook.draw_ref()

    if not ooze.slime then
        assert(false, "Ooze requires a slime reference: require('ooze')(slime)")
    end

    if view.ui.on then

        love.graphics.push()
        love.graphics.scale(ooze.slime.draw_scale)

        -- Draw each visible view
        view.ui.for_each_visible(function(view)
            if not view.skip_draw then
                view.draw()
            end
        end)

        -- redraw game cursor over debugger outlines
        ooze.slime.cursor.draw()
        love.graphics.pop()

        -- Overlay the OOZE ui on top
        view.ui.draw()

    end


end

function hook.keypressed (key, scancode, isrepeat)

    -- toggle view on/off
    for name, hotkey in pairs(hotkeys) do
        if key == hotkey and view[name] then
            -- Toggle on
            if not view[name].on then
                view[name].on = true
            else
                -- Toggle alt mode
                if view[name].has_alt_mode then
                    view[name].alt_mode = not view[name].alt_mode
                    if not view[name].alt_mode then
                        -- Toggle off
                        view[name].on = false
                    end
                else
                    -- Toggle off
                    view[name].on = false
                end
            end
            view.ui.status = nil
        end
    end

    -- send key to views
    local _intercepted = false

    view.ui.for_each_visible(function(view)
        if view.keypressed then
            _intercepted = view.keypressed(key)
        end
    end)

    if not _intercepted then
        hook.keypressed_ref(key, scancode, isrepeat)
    end

end

function hook.mousemoved (x, y, dx, dy, istouch)

    local _intercepted = false

    if view.ui.on then
        view.ui.for_each_visible(function(view)
            if view.mousemoved then
                view.mousemoved(x, y)
            end
        end)
    end

    if not _intercepted then
        hook.mousemoved_ref(x, y, dx, dy, istouch)
    end

end

function hook.mousepressed (x, y, button, istouch, presses)

    local _intercepted = false

    if view.ui.on then
        view.ui.for_each_visible(function(view)
            if view.mousepressed then
                _intercepted = view.mousepressed(x, y, button)
            end
        end)
    end

    if not _intercepted then
        hook.mousepressed_ref(x, y, button, istouch, presses)
    end

end

function hook.update (dt)
    hook.update_ref(dt)
end

function hook.wheelmoved (x, y)
    hook.wheelmoved_ref(x, y)
end

--        _                              _
-- __   _(_) _____      ___    __ _  ___| |_ ___  _ __
-- \ \ / / |/ _ \ \ /\ / (_)  / _` |/ __| __/ _ \| '__|
--  \ V /| |  __/\ V  V / _  | (_| | (__| || (_) | |
--   \_/ |_|\___| \_/\_/ (_)  \__,_|\___|\__\___/|_|
--

function view.actor.draw ()
    for _, actor in ipairs(ooze.slime.actor.list) do
        if actor._is_actor then
            love.graphics.setColor(ACTOR_COLOR)
            love.graphics.rectangle("line", actor._drawx, actor._drawy, actor.width, actor.height)
            love.graphics.setColor(FEET_COLOR)
            love.graphics.circle("line", actor.x, actor.y, 1, 6)
        end
    end
end

--function view.actors.update (dt)

--end

--        _                    __ _
-- __   _(_) _____      ___   / _| | ___   ___  _ __
-- \ \ / / |/ _ \ \ /\ / (_) | |_| |/ _ \ / _ \| '__|
--  \ V /| |  __/\ V  V / _  |  _| | (_) | (_) | |
--   \_/ |_|\___| \_/\_/ (_) |_| |_|\___/ \___/|_|
--

function view.floor.draw ()

    if ooze.slime.floor.is_set () then
        if not view.floor.image then
            view.floor.image = love.graphics.newImage(ooze.slime.floor.data)
        end
        love.graphics.setColor(1, 1, 1, .2)
        love.graphics.draw(view.floor.image)
    end

end

function view.floor.init ()

    -- Allow alternate mode
    view.floor.has_alt_mode = true

    -- Create floor edit brushes
    local _small = 3
    view.floor.small_brush = love.image.newImageData(_small, _small)
    view.floor.small_clear = love.image.newImageData(_small, _small)

    -- Fill brushes with pixels
    for _y = 0, _small -1 do
        for _x = 0, _small -1 do
            view.floor.small_clear:setPixel(_x, _y, 0, 0, 0, 0)
            view.floor.small_brush:setPixel(_x, _y, 1, 1, 1, 1)
        end
    end

end

function view.floor.keypressed (key)

    if key == hotkeys["floor"] then
        if view.floor.alt_mode then
            view.floor.color = RED
            view.ui.status = "Floor edit enabled"
        else
            view.floor.color = nil
        end
        return true
    end

end

function view.floor.mousemoved (x, y)

    if view.floor.alt_mode then
        if love.mouse.isDown(1) then
            view.floor.paint(x, y, view.floor.small_brush)
        elseif love.mouse.isDown(2) then
            view.floor.paint(x, y, view.floor.small_clear)
        end
        return true
    end

end

function view.floor.mousepressed (x, y, button)

    if view.floor.alt_mode then
        if button == 1 then
            view.floor.paint(x, y, view.floor.small_brush)
        else
            view.floor.paint(x, y, view.floor.small_clear)
        end
        return true
    end

end

function view.floor.paint (x, y, brush)

    x, y = ooze.slime.tool.scale_point(x, y)
    if ooze.slime.floor.is_set() then
        ooze.slime.floor.data:paste(brush, x, y, 0, 0, 9, 9)
        --ooze.slime.floor.data:setPixel(x, y, 1, 1, 1, 1)
        view.floor.image = love.graphics.newImage(ooze.slime.floor.data)
    end

end

--        _                   _          _
-- __   _(_) _____      ___  | |__   ___| |_ __
-- \ \ / / |/ _ \ \ /\ / (_) | '_ \ / _ \ | '_ \
--  \ V /| |  __/\ V  V / _  | | | |  __/ | |_) |
--   \_/ |_|\___| \_/\_/ (_) |_| |_|\___|_| .__/
--                                        |_|
--

function view.help.draw ()

    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(BLACK)
    love.graphics.rectangle("fill", unpack(view.help.bounding_box))
    love.graphics.setColor(UI_COLOR)
    love.graphics.rectangle("line", unpack(view.help.bounding_box))
    love.graphics.pop()

end

function view.help.init ()

    local _padding = 30
    local _self = view.help
    _self.bounding_box = {
                            _padding,
                            _padding,
                            WIN_WIDTH - _padding * 2,
                            WIN_HEIGHT - _padding * 2}

end

--        _                   _           _                   _
-- __   _(_) _____      ___  | |__   ___ | |_ ___ _ __   ___ | |_
-- \ \ / / |/ _ \ \ /\ / (_) | '_ \ / _ \| __/ __| '_ \ / _ \| __|
--  \ V /| |  __/\ V  V / _  | | | | (_) | |_\__ \ |_) | (_) | |_
--   \_/ |_|\___| \_/\_/ (_) |_| |_|\___/ \__|___/ .__/ \___/ \__|
--                                               |_|
--

function view.hotspot.draw ()

    love.graphics.setColor(HOTSPOT_COLOR)

    for _, item in ipairs(ooze.slime.hotspot.list) do
        love.graphics.rectangle("line", item.x, item.y, item.w, item.h)
    end

end

function view.hotspot.mousemoved (x, y)

    x, y = ooze.slime.tool.scale_point(x, y)
    local item = ooze.slime.hotspot.get(x, y)

    if item then
        view.ui.status = string.format("hotspot pos: %dx%d size: %dx%d", item.x, item.y, item.w, item.h)
    else
        view.ui.status = nil
    end

end

--        _                   _
-- __   _(_) _____      ___  | | __ _ _   _  ___ _ __
-- \ \ / / |/ _ \ \ /\ / (_) | |/ _` | | | |/ _ \ '__|
--  \ V /| |  __/\ V  V / _  | | (_| | |_| |  __/ |
--   \_/ |_|\___| \_/\_/ (_) |_|\__,_|\__, |\___|_|
--                                    |___/

--- Draw overlays on layers.
-- The baseline is underlined.
function view.layer.draw ()

    local _color_counter = 0

    for _, actor in ipairs(ooze.slime.actor.list) do
        if actor._is_layer then
            local layerColorIndex = math.max(1, _color_counter % (#LAYER_COLORS + 1))
            love.graphics.setColor(LAYER_COLORS[layerColorIndex])
            love.graphics.draw(actor.image)
            love.graphics.line(0, actor.baseline, WIN_WIDTH, actor.baseline)
            _color_counter = _color_counter + 1
        end
    end

end

--        _                   _
-- __   _(_) _____      ___  | | ___   __ _
-- \ \ / / |/ _ \ \ /\ / (_) | |/ _ \ / _` |
--  \ V /| |  __/\ V  V / _  | | (_) | (_| |
--   \_/ |_|\___| \_/\_/ (_) |_|\___/ \__, |
--                                    |___/
--

function view.log.draw ()

end

--        _                         _
-- __   _(_) _____      ___   _   _(_)
-- \ \ / / |/ _ \ \ /\ / (_) | | | | |
--  \ V /| |  __/\ V  V / _  | |_| | |
--   \_/ |_|\___| \_/\_/ (_)  \__,_|_|
--

--- Draw a border and ooze view labels.
function view.ui.draw ()

    if not view.ui.on then
        return
    end

    -- border
    love.graphics.setColor(UI_COLOR)
    love.graphics.rectangle("line", view.ui.x, view.ui.y, view.ui.w, view.ui.h)
    love.graphics.setFont(view.ui.font)

    -- labels
    for _, label in ipairs(view.ui.label) do
        -- fill background
        if view[label.viewname].on then
            love.graphics.setColor(view[label.viewname].color or UI_COLOR)
        else
            love.graphics.setColor(BLACK)
        end
        love.graphics.rectangle("fill", label.x, label.y, label.w, label.h)
        -- border
        love.graphics.setColor(UI_COLOR)
        love.graphics.rectangle("line", label.x, label.y, label.w, label.h)
        -- text
        if view[label.viewname].on then
            love.graphics.setColor(BLACK)
        else
            love.graphics.setColor(UI_COLOR)
        end
        love.graphics.print(label.text, label.x, label.y)
    end

    -- status bar
    love.graphics.setColor(BLACK)
    love.graphics.rectangle("fill", unpack(view.ui.status_box))
    love.graphics.setColor(UI_COLOR)
    love.graphics.rectangle("line", unpack(view.ui.status_box))
    if view.ui.status then
        love.graphics.printf(view.ui.status, unpack(view.ui.status_pbox))
    end

end

function view.ui.for_each_visible (func)

    for _, label in ipairs(view.ui.label) do
        if view[label.viewname].on then
            func(view[label.viewname], label)
        end
    end

end

function view.ui.init ()

    -- Prevent multiple inits
    if view.ui.label then
        return
    end

    -- ui on
    view.ui.on = true

    -- Dont draw in scaled loop
    view.ui.skip_draw = true

    -- Border line
    local border = 10
    view.ui.x = border
    view.ui.y = border
    view.ui.w = WIN_WIDTH - border * 2
    view.ui.h = WIN_HEIGHT - border * 2

    view.ui.small_font = love.graphics.newFont(8)
    view.ui.font = love.graphics.newFont(16)

    local _label_h = view.ui.font:getHeight("OOZE")
    local _width = view.ui.font:getWidth("OOZE")

    -- Title label
    view.ui.label = {}
    view.ui.label[1] = {
        viewname = "ui",
        text = "OOZE",
        x = border * 1.5,
        y = 0,
        w = _width,
        h = _label_h
    }

    -- Generate view labels from hotkeys
    local _labels = {}
    for _name, _hotkey  in pairs(hotkeys) do
        table.insert(_labels, {
            viewname = _name,
            text = string.format("%s:%s", _hotkey, _name)
        })
    end

    -- Sort labels
    table.sort(_labels,
                        function(a, b)
                            return a.text < b.text
                        end)

    -- View labels
    local _x_offset = border * 2
    for _, _label in ipairs(_labels) do
        local _width = view.ui.font:getWidth(_label.text)
        table.insert(view.ui.label, {
                                        viewname = _label.viewname,
                                        text = _label.text,
                                        x = _x_offset,
                                        y = view.ui.h,
                                        w = _width,
                                        h = _label_h
                                    })
        _x_offset = _x_offset + _width + border * 2
    end

    -- Start status bar after the OOZE title
    local _status_x = view.ui.label[1].x + view.ui.label[1].w

    -- Extend the status bar to the right edge of the screen (minus border padding)
    view.ui.status_box = {
                          _status_x,
                          view.ui.label[1].y,
                          WIN_WIDTH - _status_x - border * 2,
                          _label_h
                          }

    -- Predefine the printf bounds
    view.ui.status_pbox = {
                          view.ui.status_box[1],
                          view.ui.status_box[2],
                          view.ui.status_box[3],
                          "center"
                          }

end

--        _                                 _       _
-- __   _(_) _____      ___  __      ____ _| |_ ___| |__
-- \ \ / / |/ _ \ \ /\ / (_) \ \ /\ / / _` | __/ __| '_ \
--  \ V /| |  __/\ V  V / _   \ V  V / (_| | || (__| | | |
--   \_/ |_|\___| \_/\_/ (_)   \_/\_/ \__,_|\__\___|_| |_|
--

function view.watch.draw ()

end



return hook.init()
