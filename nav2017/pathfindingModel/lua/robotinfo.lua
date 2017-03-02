--[[

Contains relatively constant info about the robot, such as dimensions.
Also arena info.

Corners are numbered as follows: (following angles in radians)

2 +--------+ 1
  |        |
  |        |    ==> fwd (cameras in front, boxes in back)
3 +--------+ 4

Front of robot, with the cameras, faces forward.

--]]

local robotinfo = {}

-- Size of the arena. Will not change unless RMC rules change.
robotinfo.arenaWidth = 7.38 -- meters
robotinfo.arenaHeight = 3.78 -- meters

-- robot width and height in meters
robotinfo.width = 0.71
robotinfo.length = 1.117

-- robot "radius", a bubble outside of which collisions are impossible
-- padded a little bit just to be safe
-- (an optimization for movement modelling)
robotinfo.bubble = 0.1 + ((robotinfo.width/2)^2+(robotinfo.length/2)^2)^0.5

-- botAngle is in radians
-- returns a list of x,y coordinates for the 4 corners of the robot (8 number array)
-- x, y in meters
function robotinfo.getCorners(botX, botY, botAngle)
  -- assume robot is not at an angle yet, find corner coords in polar
  -- get radian coordinates
  local theta1 = math.atan((robotinfo.width/2)/(robotinfo.length/2))
  local r = ((robotinfo.width/2)*(robotinfo.width/2) + (robotinfo.length/2)*(robotinfo.length/2))^0.5
  -- use theat0 to calculate all corners
  -- simultaneously add botAngle to rotate robot
  local thetas = {theta1 + botAngle, math.pi - theta1 + botAngle, math.pi + theta1 + botAngle, 2*math.pi - theta1 + botAngle}
  
  -- convert corner points from polar to x,y, simultaneously adding botX and botY
  local xycoords = {}
  for i,theta in ipairs(thetas) do
    -- x
    xycoords[#xycoords+1] = r*math.cos(theta) + botX

    -- y
    xycoords[#xycoords+1] = r*math.sin(theta) + botY
  end
  
  return xycoords
end

-- same as robotinfo.getcorners, except with a fifth point back at corner 0
function robotinfo.getCornersLoop(botX, botY, botAngle)
  local coords = robotinfo.getCorners(botX, botY, botAngle)
  coords[#coords+1] = coords[1]
  coords[#coords+1] = coords[2]
  
  return coords
end

return robotinfo;