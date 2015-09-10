-- Bresenham's Line Algorithm is a way of drawing a line segment onto a square grid.
-- http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm#Lua

function bresenham(start, goal)
  local linepath = { }
  local x1, y1, x2, y2 = start.x, start.y, goal.x, goal.y
  delta_x = x2 - x1
  ix = delta_x > 0 and 1 or -1
  delta_x = 2 * math.abs(delta_x)
 
  delta_y = y2 - y1
  iy = delta_y > 0 and 1 or -1
  delta_y = 2 * math.abs(delta_y)
 
  table.insert(linepath, {["x"] = x1, ["y"] = y1})
 
  if delta_x >= delta_y then
    error = delta_y - delta_x / 2
 
    while x1 ~= x2 do
      if (error >= 0) and ((error ~= 0) or (ix > 0)) then
        error = error - delta_x
        y1 = y1 + iy
      end
 
      error = error + delta_y
      x1 = x1 + ix
 
      table.insert(linepath, {["x"] = x1, ["y"] = y1})
    end
  else
    error = delta_x - delta_y / 2
 
    while y1 ~= y2 do
      if (error >= 0) and ((error ~= 0) or (iy > 0)) then
        error = error - delta_y
        x1 = x1 + ix
      end
 
      error = error + delta_x
      y1 = y1 + iy
 
      table.insert(linepath, {["x"] = x1, ["y"] = y1})
    end
  end
  
  return linepath
end
