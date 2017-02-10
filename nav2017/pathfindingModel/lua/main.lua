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


-- Imports
robotinfo = require "robotinfo"
movement = require "movementmodel"

function love.load()
  arenaBG = love.graphics.newImage(arenaBGFilename)

end

-- TEMP STUFF
robotAngle = 0
function love.wheelmoved(x, y)
  robotAngle = robotAngle + y * (math.pi / 16)
end
-- END

-- source: https://love2d.org/wiki/HSV_color
function HSV(h, s, v)
  if s <= 0 then return v,v,v end
  h, s, v = h/256*6, s/255, v/255
  local c = v*s
  local x = (1-math.abs((h%2)-1))*c
  local m,r,g,b = (v-c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end return (r+m)*255,(g+m)*255,(b+m)*255
end

function drawArrow(startX, startY, length, angle)
  local endX = startX + length * math.cos(angle)
  local endY = startY + length * math.sin(angle)
  love.graphics.line(startX, startY, endX, endY)

  local arrowheadAngle = math.pi / 4
  local endAngle1 = angle + arrowheadAngle
  local endAngle2 = angle - arrowheadAngle
  love.graphics.line(endX, endY, endX - (length / 3) * math.cos(endAngle1), endY - (length / 3) * math.sin(endAngle1))
  love.graphics.line(endX, endY, endX - (length / 3) * math.cos(endAngle2), endY - (length / 3) * math.sin(endAngle2))
end

destX = 4
destY = 2

function love.mousereleased(x, y, button)
  if button == 2 then
    destX, destY = pixelsToM(x, y)
  end
end

function love.draw()
  love.graphics.draw(arenaBG)

  -- Print position in meters by the mouse
  mx, my = love.mouse.getPosition()
  mxm, mym = pixelsToM(mx, my)
  love.graphics.print(round2(mxm).."m, "..round2(mym).."m", mx+16, my+16)

  -- Draw destination point
  love.graphics.setColor(HSV(40, 255, 255))
  love.graphics.circle("fill", mToPixels1(destX), mToPixels1(destY), 10)
  love.graphics.setColor(255, 255, 255)

  -- Draw the robot at the mouse cursor
  local cornerPoints = {}
  local cornerPointsMeters = robotinfo.getcornersloop(mxm, mym, robotAngle)
  for i = 1, #cornerPointsMeters, 2 do
    cornerPoints[i], cornerPoints[i+1] = mToPixels(cornerPointsMeters[i], cornerPointsMeters[i+1])
    if i < 8 then love.graphics.printf(math.floor(i/2)+1, cornerPoints[i], cornerPoints[i+1], 10, "center") end
  end
  love.graphics.line(cornerPoints)
  -- draw arrow
  if movement.getCloserEnd(mxm, mym, robotAngle, destX, destY) == 1 then
    drawArrow(mx, my, mToPixels1(robotinfo.length / 3), robotAngle)
  else 
    drawArrow(mx, my, mToPixels1(robotinfo.length / 3), robotAngle+math.pi)
  end

  -- Draw lines from corners of robot to destination
  for i = 1, 8, 2 do
    local destXp, destYp = mToPixels(destX, destY)
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.line(destXp, destYp, cornerPoints[i], cornerPoints[i+1])
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Label closer side of robot
--  if movement.getCloserEnd(mxm, mym, robotAngle, destX, destY) == 1 then
--    love.graphics.print("CLOSER", mx + mToPixels1(robotinfo.length * 0.66) *math.cos(robotAngle), my + mToPixels1(robotinfo.length * 0.66) * math.sin(robotAngle))
--  else 
--    love.graphics.print("CLOSER", mx + mToPixels1(-robotinfo.length * 0.66) *math.cos(robotAngle), my + mToPixels1(-robotinfo.length * 0.66) * math.sin(robotAngle))
--  end
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

function mToPixels1(meters)
  return ((meters / arenaWidthM) * arenaWidth)
end


-- Round decimal numbers to 2 places
-- Source: http://lua-users.org/wiki/SimpleRound
function round2(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 2) .. "f", num))
end