-- Mock Löve
-- Provides a polyfill that mocks the Löve API for unit testing.
--
-- Copyright (c) 2015-2021 Wesley Werner
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
--
-- * Redistributions of source code must retain the above copyright
--   notice, this list of conditions and the following disclaimer.
-- * Redistributions in binary form must reproduce the above
--   copyright notice, this list of conditions and the following disclaimer
--   in the documentation and/or other materials provided with the
--   distribution.
-- * Neither the name of the  nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-- A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-- LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-- DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-- THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--


local mock = {}

mock.graphics = {}
mock.image = {}

function mock.graphics.draw ()

end

function mock.graphics.getDimensions ()
    return 800, 600
end

function mock.graphics.getWidth ()
    return 800
end

function mock.graphics.newFont ()
    return true
end

function mock.graphics.newImage (a)
    local _image = {}
    if type(a) == "table" then
        _image.pixeldata = a.pixeldata
    end
    _image.getDimensions = function ()
        return 800, 600
    end
    return _image
end

function mock.graphics.pop ()

end

function mock.graphics.printf ()

end

function mock.graphics.push ()

end

function mock.graphics.scale ()

end

function mock.graphics.setColor ()

end

function mock.graphics.setFont ()

end

-- Mocks an image object with instance functions.
-- Provides a mechanism to override the pixel data by setting
-- love.mock_pixels
function mock.image.newImageData (a, b)
    local _image = {width=640, height=480}
    if type(a) == "string" then
        _image.filename = a
    end
    if type(a) == "number" then
        _image.w, _image.h = a, b
        _image.filename = tostring(math.random())
    end
    if _image.filename == "small.png" then
        _image.w, _image.h = 10, 10
    end
    if mock.mock_pixels and mock.mock_pixels[_image.filename] then
        _image.pixeldata = mock.mock_pixels[_image.filename]
        _image.w = #_image.pixeldata[1]
        _image.h = #_image.pixeldata
    end
    _image.getDimensions = function (self)
        return self:getWidth(), self:getHeight()
    end
    _image.getWidth = function (self)
        return self.w
    end
    _image.getHeight = function (self)
        return self.h
    end
    _image.getPixel = function(self, x, y)
        if self.pixeldata then
            local _v = self.pixeldata[y][x]
            return _v, _v, _v, _v
        else
            return 1, 1, 1, 1
        end
    end
    _image.mapPixel = function (self, func)
        for _y=1, self.h do
            for _x=1, self.w do
                local _r, _g, _b, _a = self:getPixel(_x, _y)
                _image.pixeldata[_y][_x] = func(_x, _y, _r, _g, _b, _a)
            end
        end
    end
    _image.paste = function (self, source, x, y, w, h, sw, sh)
        _image.pixeldata = {}
        for _y=1, self.h do
            table.insert(_image.pixeldata, {})
        end
        for _y=1, sh do
            for _x=1, sw do
                local _r, _g, _b, _a = source:getPixel(_x, _y)
                _image.pixeldata[_y][_x] = _r+_g+_b+_a
            end
        end
    end
    return _image
end

return mock
