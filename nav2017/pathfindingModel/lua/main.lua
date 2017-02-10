--[[

Main file of NAVTune.

Visualizer code, making calls out to the movement and pathfinding models.

--]]

-- Background image
-- Size of this dictates size of window. Modify conf.lua manually to match.
arenaBGFilename = "sand-texture1.png"

-- Size of the arena. Will not change unless RMC rules change.
arenaWidthM = 7.38 -- meters
arenaHeightM = 3.78 -- meters

robotinfo = require "robotinfo"

function love.load()
  arenaBG = love.graphics.newImage(arenaBGFilename)

end

-- TEMP STUFF
robotAngle = 0
function love.wheelmoved(x, y)
  robotAngle = robotAngle + y * (math.pi / 16)
end
-- END

function love.draw()
  love.graphics.draw(arenaBG)
  
  -- Draw line between specific meter coordinates
  lx1, ly1 = mToPixels(1, 1)
  lx2, ly2 = mToPixels(2, 2)
  love.graphics.line(lx1, ly1, lx2, ly2)
  
  -- Print position in meters by the mouse
  mx, my = love.mouse.getPosition()
  mxm, mym = pixelsToM(mx, my)
  love.graphics.print(round2(mxm).."m, "..round2(mym).."m", mx+16, my+16)
  
  -- Draw the robot at the mouse cursor
  local cornerPoints = {}
  local cornerPointsMeters = robotinfo.getcornersloop(mxm, mym, robotAngle)
  for i = 1, #cornerPointsMeters, 2 do
    cornerPoints[i], cornerPoints[i+1] = mToPixels(cornerPointsMeters[i], cornerPointsMeters[i+1])
  end
  love.graphics.line(cornerPoints)
end

function love.update(dt)
  arenaHeight = love.graphics.getHeight()
  arenaWidth = love.graphics.getWidth()
end

-- Converts a position on the screen in pixels to a position in meters
-- returns metersX, metersY
function pixelsToM(pixelX, pixelY)
  return ((pixelX / arenaWidth) * arenaWidthM), ((pixelY / arenaHeight) * arenaHeightM)
end

-- Converts a position on the screen from meters to pixels
-- returns metersX, metersY
function mToPixels(meterX, meterY)
  return ((meterX / arenaWidthM) * arenaWidth), ((meterY / arenaHeightM) * arenaHeight)
end

-- Round decimal numbers to 2 places
-- Source: http://lua-users.org/wiki/SimpleRound
function round2(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 2) .. "f", num))
end