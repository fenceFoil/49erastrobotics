--[[

Contains info about the robot, such as dimensions.

Corners are numbered as follows: (following angles in radians)

1 +--------+ 0
  |        |
  |        |    ==> fwd (cameras in front, boxes in back)
2 +--------+ 3

--]]

local robotinfo = {}

-- robot width and height in meters
robotinfo.width = 0.71
robotinfo.length = 1.117

-- botAngle is in radians
-- returns a list of x,y coordinates for the 4 corners of the robot (8 number array)
function robotinfo.getcorners(botX, botY, botAngle)
  -- assume robot is not at an angle yet, find corner coords in polar
  -- get radian coordinates
  local theta0 = math.atan((robotinfo.width/2)/(robotinfo.length/2))
  local r = ((robotinfo.width/2)*(robotinfo.width/2) + (robotinfo.length/2)*(robotinfo.length/2))^0.5
  -- use theat0 to calculate all corners
  -- simultaneously add botAngle to rotate robot
  local thetas = {theta0 + botAngle, math.pi - theta0 + botAngle, math.pi + theta0 + botAngle, 2*math.pi - theta0 + botAngle}
  
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
function robotinfo.getcornersloop(botX, botY, botAngle)
  local coords = robotinfo.getcorners(botX, botY, botAngle)
  coords[#coords+1] = coords[1]
  coords[#coords+1] = coords[2]
  
  return coords
end

return robotinfo;