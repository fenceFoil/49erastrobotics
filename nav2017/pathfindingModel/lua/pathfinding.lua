--[[

Pathfinding. Algorithm will vary, as this is the very core of this prototype: 
a testbed for different pathfinding formulas.



Intermediate positions between curves are given by getAllPositions(), and
are selected to be arranged in a higher density where the pathfinding
algorithm needs to look harder for valid paths.

Note: Position logic holds state during a particular path search with desperation,
so a single instance of pathfinding is not thread-safe!

PATH OBJECTS:
- positions (an array of positions)
  - for each item:
    - 1 - x (m)
    - 2 - y (m)
    - 3 - angle (rad)
    - length (m)
    - curviness (sum of absolute rad deltas)
    - isFwd - (boolean) (was movement to this position foreward)
--]]

local pathfinding = {}

local robotinfo = require "robotinfo"

pathfinding.maxMoves = 3

-- positions per meter
pathfinding.pathResolution = 0.3
pathfinding.deadZone = 0.75

-- weights
pathfinding.lengthWeight = 1
pathfinding.angleWeight = 0

-- anti-spin-in-place path segment penalty
pathfinding.tooShortPenalty = 1000
pathfinding.tooShortThreshold = 2

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

function pathfinding.getAllPositions()
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
  {x1=0, x2=1.75, density=0.15},
  {x1=1.75, x2=4.5, density=0.5},
  {x1=4.5, x2=robotinfo.arenaWidth, density=0.5}
}
-- note: positions are cached for performance. to refresh after changing
-- position grid densities, etc, set pathfinding.allPositinos to nil as a dirty
-- flag
pathfinding.allPositions = nil
function pathfinding.getAllPositions()
  local positions = {}
  if pathfinding.allPositions == nil then
    for i, grid in pairs(pathfinding.positionGrids) do
      -- for each grid, create an even distribution of points throughout
      -- start with columns across x-axis, then go down columns
      for x = math.max(grid.x1, pathfinding.deadZone), 
      math.min(grid.x2, robotinfo.arenaWidth-pathfinding.deadZone), grid.density do
        for y = pathfinding.deadZone, robotinfo.arenaHeight-pathfinding.deadZone, grid.density do
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

-- Path object factory.
local function createEmptyPath()
  local newPath = {positions = {}}

  newPath.getCost = function(self)
    -- cost = sum of lengths * lengthweight + sum of angleSums * angleSumWeight
    local lenSum = 0
    local angleSum = 0
    for i,pos in pairs(self.positions) do
      lenSum = lenSum + pos.length
      angleSum = angleSum + pos.angleSum
    end

    local costCounter = lenSum * pathfinding.lengthWeight + angleSum * pathfinding.angleWeight

    -- note number of anti-spin-in-place penalties (reversals and too-short paths)
    local lastDirection = nil
    local distanceThisDirection = 0
    for i,pos in pairs(self.positions) do
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

    return costCounter
  end

  return newPath
end

-- Path object factory.
local function createNewPath(nodeX, nodeY, nodeAngle, length, angleSum, isFwd)
  local newPath = createEmptyPath()
  local newPos = {}
  newPos[1] = nodeX
  newPos[2] = nodeY
  newPos[3] = nodeAngle
  newPos.length = length
  newPos.angleSum = angleSum
  newPos.isFwd = isFwd

  newPath.positions[#newPath.positions+1] = newPos
  return newPath
end

-- return true if path1 < path2
function pathfinding.compareCosts(path1, path2)
  return path1:getCost() < path2:getCost()
end

--[[
Returns a list of paths from starting point to destination. 
Considers paths passing through a grid of positions defined by pathResolution, deadZone, etc.

--]]
local function getPathsTo2(startX, startY, startAngle, destX, destY, movementModel, movesLeft)
  -- By default, recurse THREE times
  if movesLeft == nil then movesLeft = pathfinding.maxMoves-1 end

  local pathsToDest = {}

  -- Examine movement directly from current position to destination
  local directMove = movementModel.move(startX, startY, startAngle, destX, destY)
  if directMove.didReach then 
    -- Add this movement as a path to destination paths
    pathsToDest[#pathsToDest+1] = createNewPath(destX, destY, directMove.positions[#directMove.positions][3], directMove.length, directMove.angleSum, directMove.movedFwd)
  else
    -- If can't get to destination in one hop, consider alternatives
    if movesLeft > 0 then
      -- Examine each possible step from current point to destination
      for i,pos in ipairs(pathfinding.getAllPositions()) do
        local move = movementModel.move(startX, startY, startAngle, pos[1], pos[2])

        if move.didReach then
          -- Recurse and try to reach destination from here
          local subPathsToDest = getPathsTo2(pos[1], pos[2], move.positions[#move.positions][3], destX, destY, movementModel, movesLeft - 1)
          -- Take each found path to the destination, prepend our previous move, and add to pathsToDest
          for j,path in ipairs(subPathsToDest) do
            local moveInfo = {length=move.length, angleSum=move.angleSum, isFwd=move.movedFwd}
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

  return pathsToDest
end

function pathfinding.getPathsTo(startX, startY, startAngle, destX, destY, movementModel)
  local paths = getPathsTo2(startX, startY, startAngle, destX, destY, movementModel)

  table.sort(paths, pathfinding.compareCosts)

  return paths
end


return pathfinding