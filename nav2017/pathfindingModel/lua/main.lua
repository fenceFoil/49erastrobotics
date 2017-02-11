--[[

Main file of NAVTune.

Visualizer code, making calls out to the movement and pathfinding models.

--]]

-- Background image
-- Size of this dictates size of window. Modify conf.lua manually to match.
arenaBGFilename = "sand-texture1.png"

-- Visualizations
-- 1: A single movement path
-- 2: A "sea of arrows", at arbitrary resolution
-- 3: A "sea of arrows", at each pathfinding position
currVisualization = 1
numVisualizations = 3

-- Imports
robotinfo = require "robotinfo"
movement = require "movementmodel"
movement.turnRadius = 2
movement.tolerance = 0.05
movement.segLength = 0.1

function love.load()
  if arg[#arg] == "-debug" then require("mobdebug").start() end

  arenaBG = love.graphics.newImage(arenaBGFilename)
  boomImage = love.graphics.newImage("boom.png")

  -- debug movement
  --movement.move (3, 3, 0, 2, 2, 1, 0.1, 0.1)

end

-- TEMP STUFF
robotAngle = 0
lastScrollTime = love.timer.getTime()
function love.wheelmoved(x, y)
  robotAngle = robotAngle + y * (math.pi / 16)
  lastScrollTime = love.timer.getTime()
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
  if button == 1 then
    -- change visualization
    currVisualization = currVisualization + 1
    if currVisualization > numVisualizations then currVisualization = 1 end
  elseif button == 2 then
    destX, destY = pixelsToM(x, y)
  end
end

function love.draw()
  love.graphics.draw(arenaBG)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)

  -- Print position in meters by the mouse
  mx, my = love.mouse.getPosition()
  mxm, mym = pixelsToM(mx, my)
  love.graphics.print(round2(mxm).."m, "..round2(mym).."m", mx+16, my+16)

  -- Draw the robot at the mouse cursor
  local cornerPoints = {}
  local cornerPointsMeters = robotinfo.getCornersLoop(mxm, mym, robotAngle)
  for i = 1, #cornerPointsMeters, 2 do
    cornerPoints[i], cornerPoints[i+1] = mToPixels(cornerPointsMeters[i], cornerPointsMeters[i+1])
    if i < 8 then love.graphics.printf(math.floor(i/2)+1, cornerPoints[i], cornerPoints[i+1], 10, "center") end
  end
  love.graphics.line(cornerPoints)
  -- draw arrow
  drawArrow(mx, my, mToPixels1(robotinfo.length / 3), robotAngle)

  if currVisualization == 1 then
    -- Show a single path from current position to destination point

    -- Draw destination point
    love.graphics.setColor(HSV(40, 255, 255))
    love.graphics.circle("fill", mToPixels1(destX), mToPixels1(destY), 10)
    love.graphics.setColor(255, 255, 255)

    -- Draw lines from corners of robot to destination
    for i = 1, 8, 2 do
      local destXp, destYp = mToPixels(destX, destY)
      love.graphics.setColor(255, 255, 255, 128)
      love.graphics.line(destXp, destYp, cornerPoints[i], cornerPoints[i+1])
      love.graphics.setColor(255, 255, 255, 255)
    end

    -- Draw simulated robot movement towards destination
    move = movement.move(mxm, mym, robotAngle, destX, destY)
    if (#move.positions > 1) then
      -- Convert movement points to pixel points for rendering
      local movePixelPoints = {}
      for i,point in ipairs(move.positions) do
        local pixX, pixY = mToPixels(point[1], point[2])
        movePixelPoints[(i-1)*2+1] = pixX
        movePixelPoints[(i-1)*2+1+1] = pixY
      end
      if move.didReach then
        love.graphics.setColor(0, 255, 0)
      else
        love.graphics.setColor(255, 0, 0)
      end
      love.graphics.line(movePixelPoints)
      love.graphics.setColor(255, 255, 255, 255)
      if move.didCollide then
        love.graphics.draw(boomImage, movePixelPoints[#movePixelPoints-1], movePixelPoints[#movePixelPoints], 0, 0.4, 0.4, boomImage:getWidth()/2, boomImage:getHeight()/2)
      end
    end
  elseif currVisualization == 2 then
    -- sea of arrows
    local step = 30
    for x = 0, arenaWidth, step do
      for y = 0, arenaHeight, step do
        -- draw an arrow
        local xMeters, yMeters = pixelsToM(x, y)
        local move = movement.move(mxm, mym, robotAngle, xMeters, yMeters)
        if move.didReach then
          drawArrow(x, y, step*0.7, move.positions[#move.positions][3])
        else
          love.graphics.setColor(255, 0, 0, 80)
          love.graphics.circle("fill", x, y, step/3)
          love.graphics.setColor(255, 255, 255, 255)
        end
      end
    end
  elseif currVisualization == 3 then
    -- sea of arrows, at pathfinding position resolution
    
  end
end

function love.update(dt)
  arenaHeight = love.graphics.getHeight()
  arenaWidth = love.graphics.getWidth()

  if love.timer.getTime() - lastScrollTime > 5 then
    robotAngle = robotAngle + dt*0.6
  end
end

-- Converts a position on the screen in pixels to a position in meters
-- returns metersX, metersY
function pixelsToM(pixelX, pixelY)
  return ((pixelX / arenaWidth) * robotinfo.arenaWidth), ((pixelY / arenaHeight) * robotinfo.arenaHeight)
end

-- Converts a position on the screen from meters to pixels
-- returns metersX, metersY
function mToPixels(meterX, meterY)
  return ((meterX / robotinfo.arenaWidth) * arenaWidth), ((meterY / robotinfo.arenaHeight) * arenaHeight)
end

function mToPixels1(meters)
  return ((meters / robotinfo.arenaWidth) * arenaWidth)
end


-- Round decimal numbers to 2 places
-- Source: http://lua-users.org/wiki/SimpleRound
function round2(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 2) .. "f", num))
end