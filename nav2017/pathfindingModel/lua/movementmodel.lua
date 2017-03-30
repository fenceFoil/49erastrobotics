--[[

Movement Model for NAVTune.

Models movement of the UNCC_ASTR1 robot as a circular curve, followed
by a line segment. Uses iterative method to find points, and notes
collisions with walls.

All positions are in meters.

tolerance, segLength, and turnRadius can be set with the public
variables provided below.

Note, I was paranoid about clamping angle to range 0..2pi. Maybe
you could cut the number of those.

--]]

local movementmodel = {}

local robotinfo = require "robotinfo"

-- Source: https://love2d.org/wiki/General_math (Feb 9 2017)
local function dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Ensure angle given is always within the range 0..2pi
local function clampAngle(a) return math.fmod(((math.fmod(a, 2*math.pi)) + 2*math.pi), 2*math.pi) end

-- returns 1 for front, 2 for back side of robot
function movementmodel.getCloserEnd(botX, botY, botAngle, destX, destY)
  local corners = robotinfo.getCorners(botX, botY, botAngle)
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

-- NOTE: These values should be set in main.lua. Defaults here are not defaults
-- used there!!! Ignore these defaults most of the time!!!
movementmodel.turnRadius = 2
movementmodel.tolerance = 0.01
movementmodel.segLength = 0.1

-- already dug pit obstacle size
movementmodel.pitRadius = 0.5
-- already dug pit locations. Array of tables.
-- Each pit:
-- x, y -- location coordinates
movementmodel.pits = {}

--[[
Iteratively moves the robot along a circular/straight curve towards the 
end point. This movement may or may not succeed, and the result is given
in didReach. The "resolution" of the movement is determined by segLength,
in meters/iteration of movement. The movement will also fail if the robot 
collides with the edge of the arena. 

The robot may move forward or backward, depending on the closer of the 
summed distances of the cameras on the front and back.

Turning radius is determined by the variable provided above.

logAllPoints defaults to false

TO DO:
- failure condition checking
  - collision
    - already-dug pits
    
Params:
  startX, startY - in meters
  startAngle - in rads
  destX, destY - destination point
    (you cannot specify an end angle, fundamentally)
  logAllPoints - for animation and rendering. defaults to false if set to nil
  forceDirection - force robot to move forwards or backwards. nil lets closer end 
    of robot determine. Forwards = true, backwards = false if you do set this
    value.

Returns a movement table:
- didReach
- didCollide
- angleSum (how many radians robot turned over course of movement)
- length (sum length of segments)
- array of positions: (either just a couple or many, depending on logAllPoints)
  - {x, y, angle}
- movedFwd (boolean)
--]]
function movementmodel.move(startX, startY, startAngle, destX, destY, logAllPoints, forceDirection, turnRadius, segLength)
  local currX, currY = startX, startY
  local currAngle = startAngle

  if turnRadius == nil then turnRadius = movementmodel.turnRadius end
  local tolerance = movementmodel.tolerance
  if segLength == nil then segLength = movementmodel.segLength end

  -- "Spin" robot 180 degrees "logically" here if the the robot moves backwards.
  -- Report the robot's angle as being 180 degrees again off it's "logical" angle here.
  local movingBackward
  if forceDirection == nil then
    if movementmodel.getCloserEnd(startX, startY, startAngle, destX, destY) == 1 then
      movingBackward = false
    else
      movingBackward = true
      currAngle = currAngle + math.pi
    end
  else
    if forceDirection then
      movingBackward = false
    else
      movingBackward = true
      currAngle = currAngle + math.pi
    end
  end

  -- Ensure that currAngle is between 0..2pi
  currAngle = clampAngle(currAngle)

  local positions = {}

  local didReach = true
  local didCollide = false
  local angleSum = 0
  local length = 0

  -- Calculate the max angle the robot is capable of turning each segLength 
  -- of movement.
  -- (2pi rad / 2pi turnRadius m) = (1/turnRadius rad/m), then
  -- (1/turnRadius rad/m) * segLength m = maxAngleDelta (rad)
  -- The robot can turn in a full circle every circumference length of the 
  -- circle described by its turning radius.
  local maxAngleDelta = (1 / turnRadius) * segLength

  -- Keep inching robot forward, one segment at a time, until it is within tolerance of
  -- its destination
  -- needless sqrt in dist
  --local lastDist = dist(startX, startY, destX, destY)
  local lastDist = (startX-destX)*(startX-destX)+(startY-destY)*(startY-destY)
  while (dist(currX, currY, destX, destY) > tolerance) do
    -- keep this position if logging all positions, or else keep only the
    -- starting position
    if logAllPoints or #positions == 0 then
      -- Log robot's current position
      if not movingBackward then
        positions[#positions+1] = {currX, currY, currAngle}
      else
        positions[#positions+1] = {currX, currY, clampAngle(currAngle + math.pi)}
      end
    end

    -- Calculate next line segment towards destination


    -- Need to turn this segment?
    -- If not pointed at destination, move angle towards destination
    -- Find error in robot's angle
    local angleToDest = math.atan2((destY - currY), (destX - currX))
    -- Find the smallest signed, acute angle between current 
    -- angle and angle towards destination. Inputs must lie between 0 and 2pi(?)
    local angleError = ((angleToDest-currAngle)+math.pi) % (2*math.pi) - math.pi
    -- Correct range of atan2's output from -pi..pi to 0..2pi
    --if angleError < 0 then angleError = angleError + 2 * math.pi end
    -- Move current angle towards pointing at destination
    if angleError >= 0 then
      currAngle = currAngle + math.min(angleError, maxAngleDelta)
      -- note turn
      angleSum = angleSum + math.min(angleError, maxAngleDelta)
    else 
      currAngle = currAngle - math.min(-angleError, maxAngleDelta)
      -- note turn. Turning a negative angle is still more curviness,
      -- so note the abs of the previous expression
      angleSum = angleSum + math.abs(math.min(-angleError, maxAngleDelta)) 
    end

    -- Ensure currAngle remains between 0 and 2pi
    currAngle = clampAngle(currAngle)

    -- Move robot along line segment towards destination
    local moveDist = math.min(dist(currX, currY, destX, destY), segLength)
    currX = currX + moveDist * math.cos(currAngle)
    currY = currY + moveDist * math.sin(currAngle)
    -- Note movement
    length = length + moveDist

    -- Collision Detection: Walls
    -- Check each corner of the robot to ensure it is inside arena.
    -- Only perform corner check if robot is close enough to walls
    if currX - robotinfo.bubble < 0 or currX + robotinfo.bubble > robotinfo.arenaWidth 
    or currY - robotinfo.bubble < 0 or currY + robotinfo.bubble > robotinfo.arenaHeight then
      local corners = robotinfo.getCorners(currX, currY, currAngle)
      for i = 1, 8, 2 do
        if corners[i] < 0 or corners[i] >= robotinfo.arenaWidth then
          didReach = false
          didCollide = true
        end

        if corners[i+1] < 0 or corners[i+1] >= robotinfo.arenaHeight then
          didReach = false
          didCollide = true
        end
      end
    end

    -- Collision Detection: Pits
    local corners = robotinfo.getCorners(currX, currY, currAngle)
    for i, pit in ipairs(movementmodel.pits) do
      for corner = 1, 8, 2 do
          if dist(corners[corner], corners[corner+1], pit.x, pit.y) < movementmodel.pitRadius then
            didReach = false
            didCollide = true
          end
        end
      end

      -- TO DO: Collision detection: dug pits

      -- Stop moving if a collision has occurred
      if didCollide then break end

      -- Move towards destination, but only while still growing closer.
      -- Catch the robot moving away from destination
      local unrootedDist = (currX-destX)*(currX-destX) + (currY-destY)*(currY-destY)
      -- needless sqrt if (dist(currX, currY, destX, destY) >= lastDist) then
      if (unrootedDist >= lastDist) then
        didReach = false
        break
      end

      -- Buffer this distanec for future comparisions
      lastDist = unrootedDist
    end

    -- Note the robot's final location
    if not didReach then
      if not movingBackward then
        positions[#positions+1] = {currX, currY, currAngle}
      else
        positions[#positions+1] = {currX, currY, clampAngle(currAngle + math.pi)}
      end
    else
      -- add actual destination as last point, since it was reached
      if not movingBackward then
        positions[#positions+1] = {destX, destY, currAngle}
      else
        positions[#positions+1] = {destX, destY, clampAngle(currAngle + math.pi)}
      end
    end

    return {didReach=didReach, didCollide=didCollide, length=length, angleSum=angleSum, positions=positions, movedFwd=(not movingBackward)}
  end

  return movementmodel