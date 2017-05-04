--[[

Pathfinding. Algorithm will vary, as this is the very core of this prototype: 
a testbed for different pathfinding formulas.



Intermediate positions between curves are given by getIntermediatePositions(), and
are selected to be arranged in a higher density where the pathfinding
algorithm needs to look harder for valid paths.

Note: Position logic holds state during a particular path search with desperation,
so a single instance of pathfinding is not thread-safe!

Note: getPathsTo changes the values of the movementModel passed to it, so it is
not thread-safe!

PATH OBJECTS:
- positions (an array of positions)
  - for each item:
    - 1 - x (m)
    - 2 - y (m)
    - 3 - angle (rad)
    - length (m)
    - curviness (sum of absolute rad deltas)
    - isFwd - (boolean) (was movement to this position forward. backward if false)
--]]

local pathfinding = {}

local robotinfo = require "robotinfo"

-- path search depth
pathfinding.maxMoves = 3

-- area around arena with no positions
pathfinding.deadZone = 0.9

-- weights
pathfinding.lengthWeight = 1
pathfinding.angleWeight = 0
-- (angleError multiplied by this value)
pathfinding.angleErrorWeight = 100
-- (angleError multiplied by Weight, minus this threshold, outside this threshold)
pathfinding.angleErrorThreshold = math.pi/8

pathfinding.perSegmentPenalty = 2

-- closeness weight
pathfinding.closenessWeight = 10

-- anti-spin-in-place path segment penalty
pathfinding.tooShortPenalty = 100
pathfinding.tooShortThreshold = 1.75

-- Ensure angle given is always within the range 0..2pi
local function clampAngle(a) return math.fmod(((math.fmod(a, 2*math.pi)) + 2*math.pi), 2*math.pi) end

-- This logic creates a grid of intermediate points, with a constant density.
-- deprecated in favor of pathGrids logic down below
-- positions per meter
--pathfinding.pathResolution = 0.3
--[[
local function getGridWidth()
  return math.ceil((robotinfo.arenaWidth - 2*pathfinding.deadZone) / pathfinding.pathResolution)
end

local function getGridHeight()
  return math.ceil((robotinfo.arenaHeight - 2*pathfinding.deadZone) / pathfinding.pathResolution)
end

local function getNumPositions()
  local gridWidth = getGridWidth()
  local gridHeight = getGridHeight()

  return gridWidth * gridHeight
end

function pathfinding.posToXY (pos)
  local gridWidth = getGridWidth()

  local pointX = ((pos-1) % gridWidth) * pathfinding.pathResolution + pathfinding.deadZone
  local pointY = math.floor((pos-1) / gridWidth) * pathfinding.pathResolution + pathfinding.deadZone
  return pointX, pointY
end

function pathfinding.getIntermediatePositions()
  local positions = {}
  for i = 1, getNumPositions() do
    local x, y = pathfinding.posToXY(i)
    positions[#positions+1] = {x, y}
  end
  return positions
end
--]]


--[[
Returns a grid of positions. Positions are distributed in a rectangular grid, 
split into three sections (for the starting, obstacle, and mining areas),
each with different densities of positions.
--]]
pathfinding.positionGrids = {
  {x1=0, x2=1.5, resolution=0.45},
  --[[{x1=1.75, x2=4.5, density=0.4},
  {x1=4.5, x2=robotinfo.arenaWidth, density=0.4}]]--
  {x1=1.75, x2=4.5, resolution=0.45}
}
-- note: positions are cached for performance. to refresh after changing
-- position grid densities, etc, set pathfinding.allPositinos to nil as a dirty
-- flag
pathfinding.allPositions = nil
function pathfinding.getIntermediatePositions()
  local positions = {}
  if pathfinding.allPositions == nil then
    for i, grid in pairs(pathfinding.positionGrids) do
      -- for each grid, create an even distribution of points throughout
      -- start with columns across x-axis, then go down columns
      for x = math.max(grid.x1, pathfinding.deadZone), 
      math.min(grid.x2, robotinfo.arenaWidth-pathfinding.deadZone), grid.resolution do
        for y = pathfinding.deadZone, robotinfo.arenaHeight-pathfinding.deadZone, grid.resolution do
          positions[#positions+1] = {x, y}
        end
      end
    end
    pathfinding.allPositions = positions
  else
    positions = pathfinding.allPositions
  end
  return positions
end

-- Empty path object factory.
local function createEmptyPath()
  local newPath = {positions = {}}

  -- Add the self-assessing cost function for this new path
  newPath.getCost = function(self)
    -- cost = sum of lengths * lengthweight + sum of angleSums * angleSumWeight
    local lenSum = 0
    local angleSum = 0
    local closenessSum = 0
    for i,pos in pairs(self.positions) do
      lenSum = lenSum + pos.length
      angleSum = angleSum + pos.angleSum
      closenessSum = closenessSum + pos.closeness
    end

    local costCounter = lenSum * pathfinding.lengthWeight + angleSum * pathfinding.angleWeight + closenessSum * pathfinding.closenessWeight

    -- note number of anti-spin-in-place penalties (reversals and too-short paths)
    local lastDirection = nil
    local distanceThisDirection = 0
    for i,pos in pairs(self.positions) do
      -- Add a tiny token cost to each segment of the path
      costCounter = costCounter + pathfinding.perSegmentPenalty

      if lastDirection == nil then
        lastDirection = pos.isFwd
      else
        if lastDirection ~= pos.isFwd then
          -- this segment is the start of a reversal
          -- was movement before it it too short? penalize it like heck
          if distanceThisDirection < pathfinding.tooShortThreshold then
            costCounter = costCounter + pathfinding.tooShortPenalty
          end

          distanceThisDirection = 0
        end

        lastDirection = pos.isFwd
      end
      distanceThisDirection = distanceThisDirection + pos.length
    end

    -- note how close to final destination angle path came
    -- if it was attempting to reach a particular destination angle
    if self.destAngleDelta ~= nil and self.destAngleDelta > pathfinding.angleErrorThreshold then
      costCounter = costCounter + pathfinding.angleErrorWeight * (self.destAngleDelta - pathfinding.angleErrorThreshold)
    end

    return costCounter
  end

  return newPath
end

-- Path object factory, but with values and a starting position at positions[1]
-- A destAngleDelta value of nil indicates no destinationAngle was considered 
-- finding this path.
local function createNewPath(nodeX, nodeY, nodeAngle, length, angleSum, closeness, isFwd, destAngleDelta)
  local newPath = createEmptyPath()
  local newPos = {}
  newPos[1] = nodeX
  newPos[2] = nodeY
  newPos[3] = nodeAngle
  newPos.length = length
  newPos.angleSum = angleSum
  newPos.isFwd = isFwd
  newPos.closeness = closeness
  newPath.destAngleDelta = destAngleDelta

  newPath.positions[#newPath.positions+1] = newPos
  return newPath
end

-- return true if path1 < path2
function pathfinding.compareCosts(path1, path2)
  return path1:getCost() < path2:getCost()
end

-- output is basically points if you leave angle as nil
-- outputs an even spread of points down a vertical line
function pathfinding.getVectorsInRange(pointX, bottomY, topY, numPoints, angle)
  local points = {}

  for currY = bottomY,topY,((topY-bottomY)/numPoints) do
    points[#points+1] = {pointX, currY, angle}
  end

  return points
end

--[[
Returns a list of paths from starting point to destination. 

This function is called by a public function. It searches through a single 
level of the tree of all possible paths the robot could take, and recurses
to explore each possibility deeper.

Additionally attempts and returns (if found) the path from the starting position to
the destination in one jump.

Params:
startX, startY, startAngle - starting position
destX, destY - destination info
movementModel - a movement model with a turningRadius set, etc, to simulate movement with
movesLeft - used in recursion. When this function is called with movesLeft = 0, do not 
  recurse any further, only return the attempt to move directly to the destination from
  starting positions.
destAngle - if left nil, a path is found to the destination. If specified, more possible
  paths will be tried, SLOWER!, and path that reaches destination with closest arrival angle
  possible to specified destAngle will be returned.

--]]
local function getPathsToRecurse(startX, startY, startAngle, destPoints, movementModel, movesLeft, destAngle)
  local pathsToDest = {}
  local destX = destPoints[1][1]
  local destY = destPoints[1][2]

  -- Tally of total movements performed using movementModel
  local totalPathsChecked = 0

  -- Create an array of EITHER forwards and backwards, OR movements any direction
  -- Then run a for loop through it

  -- Perform two movements, one in each direction, if searching endlessly for 
  -- a particular end angle. Otherwise, let the robot move in the most convenient
  -- direction.
  local moveDirections = {"nodir"} -- would store a nil, but then array length = 0!
  if destAngle ~= nil then
    moveDirections = {true, false}
  end

  for i, dir in ipairs(moveDirections) do
    if dir == "nodir" then dir = nil end

    -- Try to move directly from current position to destination
    local didAnyDirectMoveReach = false
    for i, destPoint in ipairs(destPoints) do
      local directMove = movementModel.move(startX, startY, startAngle, destPoint[1], destPoint[2], false, dir)
      totalPathsChecked = totalPathsChecked + 1
      if directMove.didReach then   
        local angleError = nil
        if destAngle ~= nil then 
          angleError = math.abs(((destAngle - directMove.positions[#directMove.positions][3])+math.pi) % (2*math.pi) - math.pi)
        end
        pathsToDest[#pathsToDest+1] = createNewPath(destPoint[1], destPoint[2], directMove.positions[#directMove.positions][3], directMove.length, directMove.angleSum, directMove.closeness, directMove.movedFwd, angleError)
        didAnyDirectMoveReach = true
      end
    end

    -- Try moving from current position to every single possible intermediate position
    -- Explore further routes, if we didn't reach the destination, or
    -- if we want to find one that may take longer, but 
    -- reaches the end destination at a particular angle
    if not didAnyDirectMoveReach or destAngle ~= nil then

      -- ACTUALLY, do not explore any more moves in tree if out of recursions
      if movesLeft > 0 then

        -- Examine each possible move from current point to destination
        for i,pos in ipairs(pathfinding.getIntermediatePositions()) do
          -- Check that we're not positioned on top of this point
          if math.abs(startX-pos[1]) > 0.001 and math.abs(startY-pos[2]) > 0.001 then

            local move = movementModel.move(startX, startY, startAngle, pos[1], pos[2], false, dir)

            totalPathsChecked = totalPathsChecked + 1

            if move.didReach then
              -- Recurse and try to reach destination again from this intermediate point
              local subPathsToDest, subPathsChecked = getPathsToRecurse(pos[1], pos[2], move.positions[#move.positions][3], destPoints, movementModel, movesLeft - 1, destAngle, 0)
              totalPathsChecked = totalPathsChecked + subPathsChecked
              -- Take each found path to the destination, copy our move so far in front, and add to pathsToDest
              for j,path in ipairs(subPathsToDest) do
                local moveInfo = {length=move.length, angleSum=move.angleSum, closeness=move.closeness, isFwd=move.movedFwd}
                moveInfo[1] = pos[1]
                moveInfo[2] = pos[2]
                moveInfo[3] = move.positions[#move.positions][3]
                table.insert(path.positions, 1, moveInfo)
                pathsToDest[#pathsToDest+1] = path
              end
            end
          end
        end
      end
    end
  end

  return pathsToDest, totalPathsChecked
end

--[[

TODO: Comments here

Considers paths passing through a grid of positions defined by pathResolution, deadZone, etc.

Params:
startX, startY, startAngle - starting position
destX, destY - destination info
movementModel - a movement model with a turningRadius set, etc, to simulate movement with
movesLeft - used in recursion. When this function is called with movesLeft = 0, do not 
  recurse any further, only return the attempt to move directly to the destination from
  starting positions.
destAngle - if left nil, a path is found to the destination. If specified, more possible
  paths will be tried, SLOWER!, and path that reaches destination with closest arrival angle
  possible to specified destAngle will be returned.


returns a list of found paths (see object definition above), the turning radius
used for movement, and the total number of checked paths
--]]
function pathfinding.getPathsTo(startX, startY, startAngle, destPoints, movementModel, destAngle)  
  -- For debugging and prototyping: reset field of intermediate points to
  -- recalculate from density parameters again, if changed.
  pathfinding.allPositions = nil

  if destAngle ~= nil then destAngle = clampAngle(destAngle) end

  -- save orginal turning radius of movement model, despite desperation below
  local originalRadius = movementModel.turnRadius
  -- Desperation: in the odd case no path can be found at a turning radius of x,
  -- try to assume a tighter turning radius until a path can be found.
  local paths = {}
  local totalPathsChecked = 0
  repeat
    local tempPathsChecked = 0
    paths, tempPathsChecked = getPathsToRecurse(startX, startY, startAngle, destPoints, movementModel, pathfinding.maxMoves-1, destAngle)
    totalPathsChecked = totalPathsChecked + tempPathsChecked
    if (#paths <= 0) then movementModel.turnRadius = movementModel.turnRadius * 0.9 end
    -- XXX: Tune ^^^ constants
  until #paths > 0 or movementModel.turnRadius < originalRadius * 0.7
  -- XXX: Tune ^^^ constants
  local usedRadius = movementModel.turnRadius
  movementModel.turnRadius = originalRadius

  table.sort(paths, pathfinding.compareCosts)

  return paths, usedRadius, totalPathsChecked
end


return pathfinding