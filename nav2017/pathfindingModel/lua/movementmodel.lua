--[[

Movement Model for NAVTune.

Models movement of the UNCC_ASTR1 robot as a circular curve, followed
by a line segment. Uses iterative method to find points.

All positions are in meters.

--]]

local movementmodel = {}

local robotinfo = require "robotinfo"

-- Source: https://love2d.org/wiki/General_math (Feb 9 2017)
local function dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- returns 1 for front, 2 for back side of robot
function movementmodel.getCloserEnd(botX, botY, botAngle, destX, destY)
  local corners = robotinfo.getcorners(botX, botY, botAngle)
  -- Get distances from corners to destination
  local cornerDists = {}
  -- step through corner points
  for i = 1, 8, 2 do
    cornerDists[#cornerDists+1] = dist(destX, destY, corners[i], corners[i+1])
  end
  -- Get distance from each corner to dest
  if (cornerDists[1] + cornerDists[4]) <= (cornerDists[2] + cornerDists[3]) then
    -- front end
    return 1
  else
    return 2
  end
end

--[[
-- in meters
robotinfo.turningRadius = 1

-- tolerance for finishing a movement (meters)
robotinfo.moveTolerance = 0.1
--]]

--[[
Iteratively moves the robot along a circular/straight curve towards the 
end point. This movement may or may not succeed, and the result is given
in didReach. The "resolution" of the movement is determined by segLength,
in meters/iteration of movement. The movement will also fail if the robot collides with the edge of the arena. 

The robot may move forward or backward, depending on the closer of the 
summed distances of the cameras on the front and back.

TO DO:
- failure condition checking
  - cant reach
  - collision
    - walls
    - already-dug pits
- tolerance

Returns a movement table:

- didReach
- didCollide
- array of positions:
  - {x, y, angle}
--]]
function move(startX, startY, startAngle, destX, destY, turnRadius, tolerance, segLength)
  local currX, currY, currAngle = startX, startY, startAngle
  
  local positions = {}

  local didReach = true
  local didCollide = false

  -- Calculate the max angle the robot is capable of turning each segLength 
  -- of movement.
  -- (2pi rad / 2pi turnRadius m) = (1/turnRadius rad/m), then
  -- (1/turnRadius rad/m) * segLength m = maxAngleDelta (rad)
  -- The robot can turn in a full circle every circumference length of the 
  -- circle described by its turning radius.
  local maxAngleDelta = (1 / turnRadius) * segLength

  -- Keep inching robot forward, one segment at a time, until it is within tolerance of
  -- its destination
  local lastDist = dist(startX, startY, destX, destY)
  while (dist(currX, currY, destX, destY) > tolerance) do
    -- Log robot's current position
    positions[#positions+1] = {currX, currY, currAngle}

    -- Calculate next line segment towards destination

    -- Need to turn this segment?
    -- If not pointed at destination, move angle towards destination
    -- Find error in robot's angle
    local angleToDest = math.atan((destY - startY), (destX - startX))
    local angleError = angleToDest - currAngle
    -- If obtuse angle, make acute
    if (angleError > math.pi) then angleError = angleError - math.pi end 
    -- Move current angle towards pointing at destination
    if angleError > 0 then
      currAngle = currAngle - math.min(angleError, maxAngleDelta)
    else 
      currAngle = currAngle + math.min(-angleError, maxAngleDelta)
    end
    
    -- Move robot along line segment towards destination
    local moveDist = math.min(dist(currX, currY, destX, destY), segLength)
    currX = currX + moveDist * math.cos(currAngle)
    currY = currY + moveDist * math.sin(currAngle)

    -- TO DO: Collision detection: walls

    -- TO DO: Collision detection: dug pits

    -- Move towards destination, but only while still growing closer.
    -- Catch the robot moving away from destination
    if (dist(currX, currY, destX, destY) >= lastDist) then
      didReach = false
      break
    end

    -- Buffer this destination for future comparisions
    lastDist = dist(currX, currY, destX, destY)
  end
  
  -- Note the robot's final location
  if not didReach then
    positions[#positions+1] = {currX, currY, currAngle}
  else
    -- add actual destination as last point, since it was reached
    positions[#positions+1] = {destX, destY, currAngle}
  end
  
  return {"didReach"=didReach, "didCollide"=didCollide, "positions"=positions}
end

return movementmodel