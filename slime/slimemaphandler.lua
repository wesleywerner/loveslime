-- A simple implementation of the A* (A Star) pathfinding algorithm for lua
-- https://github.com/GloryFish/lua-astar
-- Created by Jay Roberts on 2011-01-12.
-- Copyright 2011 GloryFish.org. All rights reserved.

require 'slime.middleclass'
require 'slime.astar'

SlimeMapHandler = class('SlimeMapHandler')

function SlimeMapHandler:convert(filename)
    -- Converts a walkable image mask into map points.
    local mask = love.image.newImageData(filename)
    local w = mask:getWidth()
    local h = mask:getHeight()
    local row = nil
    local r = nil
    local g = nil
    local b = nil
    local a = nil
    self.tiles = { }
    for ih = 1, h - 1 do
        row = { }
        for iw = 1, w - 1 do
            r, g, b, a = mask:getPixel (iw, ih)
            if (r + g + b == 0) then
                table.insert(row, 1)
            else
                table.insert(row, 0)
            end
        end
        table.insert(self.tiles, row)
    end
end

function SlimeMapHandler:initialize()
  self.tiles = { }
end

function SlimeMapHandler:size()
    return { w = #self.tiles[1], h = #self.tiles }
end

function SlimeMapHandler:getNode(location)
  -- Here you make sure the requested node is valid (i.e. on the map, not blocked)
  if location.x > #self.tiles[1] or location.y > #self.tiles then
    -- print 'location is outside of map on right or bottom'
    return nil
  end

  if location.x < 1 or location.y < 1 then
    -- print 'location is outside of map on left or top'
    return nil
  end

  if self.tiles[location.y][location.x] == 1 then
    -- print(string.format('location is solid: (%i, %i)', location.x, location.y))

    return nil
  end

  return Node(location, 1, location.y * #self.tiles[1] + location.x)
end


function SlimeMapHandler:getAdjacentNodes(curnode, dest)
  -- Given a node, return a table containing all adjacent nodes
  -- The code here works for a 2d tile-based game but could be modified
  -- for other types of node graphs
  local result = {}
  local cl = curnode.location
  local dl = dest

  local n = false

  n = self:_handleNode(cl.x + 1, cl.y, curnode, dl.x, dl.y)
  if n then
    table.insert(result, n)
  end

  n = self:_handleNode(cl.x - 1, cl.y, curnode, dl.x, dl.y)
  if n then
    table.insert(result, n)
  end

  n = self:_handleNode(cl.x, cl.y + 1, curnode, dl.x, dl.y)
  if n then
    table.insert(result, n)
  end

  n = self:_handleNode(cl.x, cl.y - 1, curnode, dl.x, dl.y)
  if n then
    table.insert(result, n)
  end

  return result
end

function SlimeMapHandler:locationsAreEqual(a, b)
  return a.x == b.x and a.y == b.y
end

function SlimeMapHandler:_handleNode(x, y, fromnode, destx, desty)
  -- Fetch a Node for the given location and set its parameters
  local loc = {
    x = x,
    y = y
  }

  local n = self:getNode(loc)

  if n ~= nil then
    local dx = math.max(x, destx) - math.min(x, destx)
    local dy = math.max(y, desty) - math.min(y, desty)
    local emCost = dx + dy

    n.mCost = n.mCost + fromnode.mCost
    n.score = n.mCost + emCost
    n.parent = fromnode

    return n
  end

  return nil
end

function SlimeMapHandler:nodeBlocking(location)
    return self.tiles[location.y][location.x] == 1
end
