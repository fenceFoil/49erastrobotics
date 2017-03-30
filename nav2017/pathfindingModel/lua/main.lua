--[[

Main file of NAVTune.

Visualizer code, making calls out to the movement and pathfinding models.

Visually demonstrates capabilities of robot pathfinding, and allows a Java
control panel to connect up to quickly tweak and test different constant values.

Controls Across Simulations:
Robot sticks to mouse or is dragged with left mouse button.
Scroll wheel spins robot.
Right mouse button click places a yellow destination marker.
Middle mouse button (wheel) changes visualization.

Note: Dimensions must be converted often between pixels and meters.

Server:
Creates a TCP socket server on port 31336 (see PORT_NUM) that will execute any
string sent over the connection followed by a newline, enabling external control 
of this demo script.
Code sent is executed in the scope of this main.lua, so it can, for instance,
set the values in the movement model by saying movement.turnRadius = 1.1,
for instance.

--]]

-- Background image
-- Size of this dictates size of window. Modify conf.lua manually to match.
arenaBGFilename = "labeledArena-black.png"

-- Visualizations
-- 1: A single movement path
-- 2: A "sea of arrows", at arbitrary resolution
-- 3: Positions used in pathfinding
-- 4: A "sea of arrows", at each pathfinding position
-- 5: Top-scoring path between mouse pos and destination marker
-- 6: Robot competition run animation
currVisualization = 6
numVisualizations = 6

-- Lock robot pos: Must drag mouse to move robot. Otherwise robot locked to mouse
lockRobotPos = false
-- Turn robot using scroll wheel: 8 steps, or smoothly?
lock8Angles = false
-- Turn robot in a kind of demo mode after a few moments untouched?
autoSpin = true

-- Imports & setup
robotinfo = require "robotinfo"
movement = require "movementmodel"
movement.turnRadius = 1.5
movement.tolerance = 0.05
movement.segLength = 0.2
pathfinding = require "pathfinding"

-- Java Control Panel server imports and setup
local PORT_NUM = 31336
socket = require "socket"
server = assert(socket.bind("*", PORT_NUM))
server:settimeout(0) -- do not block while waiting for request

-- Start script.
function love.load()
  if arg[#arg] == "-debug" then require("mobdebug").start() end

  arenaBG = love.graphics.newImage(arenaBGFilename)
  boomImage = love.graphics.newImage("boom.png")
end

-- Mouse wheel spins robot
robotAngle = 0
lastScrollTime = love.timer.getTime()
function love.wheelmoved(x, y)
  if lock8Angles then
    robotAngle = robotAngle + y * (math.pi / 4)
  else 
    robotAngle = robotAngle + y * (math.pi / 16)
  end
  lastScrollTime = love.timer.getTime()
end
-- Moving mouse stops auto spin
function love.mousemoved(x, y, d, dy, istouch)
  -- don't start spinning robot while mouse is moving
  lastScrollTime = love.timer.getTime()
end

-- Utility function. Alternative color space from RGB.
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

-- Graphics: Draws a 3-line vector arrow in one call.
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

-- Destination of robot (yellow circle marker)
destX = 4
destY = 2
-- Move robot to destination point and this angle
-- used in some visualizations
destAngle = 0

lastdt = 0

-- Middle clicking mouse changes visualization
function love.mousereleased(x, y, button)
  if button == 3 then
    -- change visualization
    currVisualization = currVisualization + 1
    if currVisualization > numVisualizations then currVisualization = 1 end
  end
  if button == 2 then
    destX, destY = pixelsToM(x, y)
  end
end

-- positions are in meters
function drawRobot(botX, botY, robotAngle)
  -- Print position in meters by the mouse
  local botXPixel, botYPixel = mToPixels(botX, botY)

  love.graphics.print(round2(botX).."m, "..round2(botY).."m", botXPixel+16, botYPixel+16)
  local cornerPoints = {}
  local cornerPointsMeters = robotinfo.getCornersLoop(botX, botY, robotAngle)
  for i = 1, #cornerPointsMeters, 2 do
    cornerPoints[i], cornerPoints[i+1] = mToPixels(cornerPointsMeters[i], cornerPointsMeters[i+1])
  end
  love.graphics.line(cornerPoints)
  -- draw arrow
  drawArrow(botXPixel, botYPixel, mToPixels1(robotinfo.length / 3), robotAngle)
end

-- Called from love.draw(); draws the current frame of an animation of a complete competition run
-- compAnim is the state of the animation between function calls
compAnim = {state="reset", stateJustChanged=false, botPos = {0, 0, 0}, miningDest = {0, 0}, botSpeed = 1, segLength = 0.001}
compAnim.startMovingTowards = function (self, destPos)
  -- Calculate mining path
  local miningPaths, radiusUsed, totalPathsChecked = pathfinding.getPathsTo(self.botPos[1], self.botPos[2], self.botPos[3], destPos[1], destPos[2], movement, destPos[3])

  -- Cache detailed movement along path
  self.currAnimPath = movement.move(self.botPos[1], self.botPos[2], self.botPos[3], miningPaths[1].positions[1][1], miningPaths[1].positions[1][2], true, miningPaths[1].positions[1].isFwd, radiusUsed, self.segLength)
  self.currAnimTime = 0
  
  -- Cachce overall path being taken
  self.currCompletePath = miningPaths[1]
  self.currCompletePathRadius = radiusUsed

  -- Switch states
  self.state = "anim-to-mining"
  self.stateJustChanged = true
end
movement.turnRadius = 1.7
function updateCompetitionAnimation() 
  if compAnim.state == "reset" then
    -- let user select a starting position

    -- show robot attached to mouse cursor
    local mxm, mym = pixelsToM(love.mouse.getPosition())
    drawRobot(mxm, mym, robotAngle)

    -- clicking starts animation
    if love.mouse.isDown(1) then
      -- TODO: calculate path to mining area, change state to animate it

      -- TODO: Select a mining destination
      compAnim.botPos = {mxm, mym, robotAngle}
      compAnim.miningDest = {6.4, 0.8, math.pi}

      compAnim:startMovingTowards(compAnim.miningDest)
    end
  elseif compAnim.state == "anim-to-mining" then
    -- Increment animation time
    if not compAnim.stateJustChanged then
      compAnim.currAnimTime = compAnim.currAnimTime + lastdt
    else
      compAnim.stateJustChanged = false
    end

    -- Draw bot's current path
    -- Choose top path
    local path = compAnim.currCompletePath.positions

    --love.graphics.print("Paths Found: "..#pathsFound.." Paths Checked: "..pathsChecked)
    love.graphics.print("Turning Radius Used: "..compAnim.currCompletePathRadius, 0, 20)

    -- Draw movement between each point of path
    local lastPos = compAnim.botPos
    for i,nextPos in ipairs(path) do
      love.graphics.print(round2(nextPos[1])..","..round2(nextPos[2])..","..round2(nextPos[3]), 400, 20*i)

      -- Draw simulated robot movement towards destination
      local move = movement.move(lastPos[1], lastPos[2], lastPos[3], nextPos[1], nextPos[2], true, nextPos.isFwd, compAnim.currCompletePathRadius)
      if (#move.positions > 1) then
        -- Convert movement points to pixel points for rendering
        local movePixelPoints = {}
        if move.movedFwd then
          love.graphics.setColor(0, 255, 0)
        else
          love.graphics.setColor(0, 255, 255)
        end
        for j,point in ipairs(move.positions) do
          local pixX, pixY = mToPixels(point[1], point[2])
          movePixelPoints[(j-1)*2+1] = pixX
          movePixelPoints[(j-1)*2+1+1] = pixY

          love.graphics.circle("fill", pixX, pixY, 4)
        end
        love.graphics.line(movePixelPoints)
        love.graphics.setColor(255, 255, 255, 255)
      end

      lastPos = nextPos
    end

    -- Draw bot at a position along path
    local currBotTravelDist = compAnim.botSpeed * compAnim.currAnimTime
    local currBotTravelPosition = math.floor(currBotTravelDist / compAnim.segLength) + 1
    if currBotTravelPosition > #compAnim.currAnimPath.positions then
      compAnim.botPos = compAnim.currAnimPath.positions[#compAnim.currAnimPath.positions]
      compAnim:startMovingTowards(compAnim.miningDest)
      -- TODO redo state change stuff above until reached end of paths
      return
    end
    local currBotPos = compAnim.currAnimPath.positions[currBotTravelPosition]
    
    drawRobot(currBotPos[1], currBotPos[2], currBotPos[3])
  end
end

-- Update simulation, and render any current visualization
function love.draw()
  local windowWidth, windowHeight = love.window.getMode()
  love.graphics.draw(arenaBG, 0, 0, 0, (windowWidth / arenaBG:getWidth()), (windowHeight / arenaBG:getHeight()))

  if currVisualization == 6 then
    updateCompetitionAnimation()
    return
  end

  love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)

  -- update robot position to mouse position
  if not (lockRobotPos and not love.mouse.isDown(1)) then
    mx, my = love.mouse.getPosition()
  end
  if mx == nil or my == nil then
    mx, my = mToPixels(0.95, 1.12)
  end
  local mxm, mym = pixelsToM(mx, my)
  -- Print position in meters by the mouse
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

    -- Draw bubble for collisions around robot
    love.graphics.setColor(255, 255, 255, 45)
    love.graphics.circle("line", mx, my, mToPixels1(robotinfo.bubble))
    love.graphics.setColor(255, 255, 255, 255)

    -- Draw lines from corners of robot to destination
    for i = 1, 8, 2 do
      local destXp, destYp = mToPixels(destX, destY)
      love.graphics.setColor(255, 255, 255, 128)
      love.graphics.line(destXp, destYp, cornerPoints[i], cornerPoints[i+1])
      love.graphics.setColor(255, 255, 255, 255)
    end

    -- Draw simulated robot movement towards destination
    local move = movement.move(mxm, mym, robotAngle, destX, destY, true)
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
    local step = 20
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
    -- pathfinding positions

    -- Draw dead zone
    ulx, uly = mToPixels(pathfinding.deadZone, pathfinding.deadZone)
    lrx, lry = mToPixels(robotinfo.arenaWidth - pathfinding.deadZone, robotinfo.arenaHeight - pathfinding.deadZone)
    love.graphics.rectangle("line", ulx, uly, lrx-ulx, lry-uly)

    -- for now, just show positions considered in pathfinding
    for i,pos in ipairs(pathfinding.getIntermediatePositions()) do
      px, py = mToPixels(pos[1], pos[2])
      love.graphics.setColor(0, 0, 255, 80)
      love.graphics.circle("fill", px, py, 10)
      love.graphics.setColor(255, 255, 255, 255)
      love.graphics.print(i, px, py)
    end
  elseif currVisualization == 4 then
    -- sea of arrows, at pathfinding position resolution

    -- for now, just show positions considered in pathfinding
    for i,pos in ipairs(pathfinding.getIntermediatePositions()) do
      x, y = pos[1], pos[2]
      px, py = mToPixels(x, y)


      -- draw an arrow
      local xMeters, yMeters = pixelsToM(x, y)
      local move = movement.move(mxm, mym, robotAngle, x, y)
      if move.didReach then
        drawArrow(px, py, 20, move.positions[#move.positions][3])
      else
        love.graphics.setColor(255, 0, 0, 80)
        love.graphics.circle("fill", px, py, 10)
        love.graphics.setColor(255, 255, 255, 255)
      end
    end
  elseif currVisualization == 5 then
    -- simple pathfinding best path, drawn

    -- Draw destination point
    love.graphics.setColor(HSV(40, 255, 255))
    local destXpixels, destYpixels = mToPixels(destX, destY)
    love.graphics.circle("fill", destXpixels, destYpixels, 10)
    love.graphics.setColor(255, 255, 255)
    if destAngle ~= nil then
      drawArrow(destXpixels, destYpixels, 20, destAngle)
    end

    -- Run pathfinding
    local pathsFound, usedRadius, pathsChecked = pathfinding.getPathsTo(mxm, mym, robotAngle, destX, destY, movement, destAngle)

    if #pathsFound >= 1 then
      -- Choose top path
      local path = pathsFound[1]

      love.graphics.print("Paths Found: "..#pathsFound.." Paths Checked: "..pathsChecked)
      love.graphics.print("Turning Radius Used: "..usedRadius, 0, 20)

      -- Draw movement between each point of path
      local lastPos = {mxm, mym, robotAngle}
      for i,nextPos in ipairs(path.positions) do
        love.graphics.print(round2(nextPos[1])..","..round2(nextPos[2])..","..round2(nextPos[3]), 400, 20*i)

        -- Draw simulated robot movement towards destination
        local tempRad = movement.turnRadius
        movement.turnRadius = usedRadius
        local move = movement.move(lastPos[1], lastPos[2], lastPos[3], nextPos[1], nextPos[2], true, nextPos.isFwd)
        movement.turnRadius = tempRad
        if (#move.positions > 1) then
          -- Convert movement points to pixel points for rendering
          local movePixelPoints = {}
          if move.movedFwd then
            love.graphics.setColor(0, 255, 0)
          else
            love.graphics.setColor(0, 255, 255)
          end
          for j,point in ipairs(move.positions) do
            local pixX, pixY = mToPixels(point[1], point[2])
            movePixelPoints[(j-1)*2+1] = pixX
            movePixelPoints[(j-1)*2+1+1] = pixY

            love.graphics.circle("fill", pixX, pixY, 4)
          end
          --love.graphics.line(movePixelPoints)
          love.graphics.setColor(255, 255, 255, 255)
        end

        lastPos = nextPos
      end
    else
      love.graphics.print("No paths found!", 100, 100)
    end
  elseif currVisualization == 6 then
    -- Perform an animation of the robot's complete sequence of movements
    updateCompetitionAnimation()
  end
end

-- Auto-spin is implemented here
lastAngle = 0
lastAngleChange = 0
function love.update(dt)
  arenaHeight = love.graphics.getHeight()
  arenaWidth = love.graphics.getWidth()

  -- spin robot in 45 degree incrments each second
  if love.timer.getTime() - lastScrollTime > 5 then
    if autoSpin then
      if lock8Angles then
        if love.timer.getTime() - lastAngleChange > 2 then
          lastAngle = (lastAngle + 1) % 8
          robotAngle = lastAngle * (math.pi / 4)

          lastAngleChange = love.timer.getTime()
        end
      else
        robotAngle = robotAngle + math.pi*dt*0.05
      end
    end
  end

  -- Check for new server connections
  if controlClient == nil then
    -- will remain nil if timeout occurs
    controlClient = server:accept()
  else
    controlClient:settimeout(0) -- no blocking here!
    while true do
      local line, err = controlClient:receive()
      if not err then 
        -- execute line received
        loadstring(line)()
      elseif err ~= "timeout" then
        controlClient:close()
        controlClient = nil
        break
      else
        break
      end
    end
  end

  lastdt = dt
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

function love.quit()
  server:close()
end