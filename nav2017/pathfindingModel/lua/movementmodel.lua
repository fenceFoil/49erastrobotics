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
Iteratively moves the robot along a circular/straight curve towards the 
end point. This movement may or may not succeed, and the result is given
in didReach. The "resolution" of the movement is determined by segLength,
in meters/iteration of movement. The movement will also fail if the robot collides with the edge of the arena. 

The robot may move forward or backward, depending on the closer of the 
summed distances of the cameras on the front and back.

Returns a movement table:

- didReach
- didCollide
- array of positions:
  - {x, y, angle}
--]]
function move(startX, startY, startAngle, destX, destY, radius, segLength)

end

return movementmodel