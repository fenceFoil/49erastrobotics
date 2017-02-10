--[[

Movement Model for NAVTune.

Models movement of the UNCC_ASTR1 robot as a circular curve, followed
by a line segment. Uses iterative method to find points.

All positions are in meters.

--]]

local movementmodel = {}

robotinfo = require "robotinfo"

-- Source: https://love2d.org/wiki/General_math (Feb 9 2017)
local function dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

local function getCloserSide(botX, botY, botAngle, destX, destY)
  -- Get distances from corners to destination
  
  -- Get position of each corner
  cornerPoints = {{}, {}, {}, {}}
  
  -- Get distance from each corner to dest
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
function generateMovement(startX, startY, startAngle, destX, destY, radius, segLength)
  
end

return movementmodel