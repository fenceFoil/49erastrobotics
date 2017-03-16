--[[

Pathfinding. Algorithm will vary, as this is the very core of this prototype: 
a testbed for different pathfinding formulas.



Intermediate positions between curves are specified as an index in a fixed set.
Positions range between 1..getNumPositions(), and each maps to an XY position
in meters, in columns along X and then rows along Y (last bit subject to change).

PATH OBJECTS:
- positions (an array of positions)
  - for each item:
    - 1 - x (m)
    - 2 - y (m)
    - 3 - angle (rad)
    - length (m)
    - curviness (sum of absolute rad deltas)

--]]

local pathfinding = {}

local robotinfo = require "robotinfo"

pathfinding.maxMoves = 3

-- positions per meter
pathfinding.pathResolution = 0.3
pathfinding.deadZone = 0.75

-- weights
pathfinding.lengthWeight = 1
pathfinding.angleWeight = 1

-- anti-spin-in-place path segment penalty
pathfinding.tooShortPenalty = 4
pathfinding.tooShortThreshold = 1.5

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

  -- XXX: Broken. Are positions 1-indexed or 0-indexed?
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
    local costCounter =  lenSum * pathfinding.lengthWeight + angleSum * pathfinding.angleWeight
    if lenSum < pathfinding.tooShortThreshold and self.isReversal then
      costCounter = costCounter + pathfinding.tooShortPenalty
    end
    return costCounter
  end

  return newPath
end

-- Path object factory.
local function createNewPath(nodeX, nodeY, nodeAngle, length, angleSum, isReversal=false)
  local newPath = createEmptyPath()
  local newPos = {}
  newPos[1] = nodeX
  newPos[2] = nodeY
  newPos[3] = nodeAngle
  newPos.length = length
  newPos.angleSum = angleSum
  newPos.isReversal = isReversal

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
local function getPathsTo2(startX, startY, startAngle, destX, destY, movementModel, movesLeft, lastMoveFwd)
  -- By default, recurse THREE times
  if movesLeft == nil then movesLeft = pathfinding.maxMoves-1 end

  -- TODO: How handle end of recursion?

  local pathsToDest = {}

  -- TO DO Examine movement directly from current position to destination
  local directMove = movementModel.move(startX, startY, startAngle, destX, destY)
  local moveWasReversal = true
  -- In LabVIEW, use xor. Not available in lua
  if (lastMoveFwd and directMove.movedFwd) or ((not lastMoveFwd) and (not directMove.movedFwd)) then
    moveWasReversal = false
  end
  if directMove.didReach then 
    -- Add this movement as a path to destination paths
    pathsToDest[#pathsToDest+1] = createNewPath(destX, destY, directMove.positions[#directMove.positions][3], directMove.length, directMove.angleSum, moveWasReversal)
  else
    -- If can't get to destination in one hop, consider alternatives
    if movesLeft > 0 then
      -- Examine each possible step from current point to destination
      for i,pos in ipairs(pathfinding.getAllPositions()) do
        local move = movementModel.move(startX, startY, startAngle, pos[1], pos[2])

        if move.didReach then
          -- Recurse and try to reach destination from here
          local subPathsToDest = getPathsTo2(pos[1], pos[2], move.positions[#move.positions][3], destX, destY, movementModel, movesLeft - 1, lastMoveFwd)
          -- Take each found path to the destination, prepend our previous move, and add to pathsToDest
          for j,path in ipairs(subPathsToDest) do
            local moveInfo = {length=move.length, angleSum=move.angleSum}
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