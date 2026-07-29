local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps
local Flags = NS.Flags
local Bases = NS.Bases

local EOTS = Maps:NewMod()

local commonConfig = {
  maxBases = 4,
  tickRate = 2,
  assaultTime = 6,
  contestedTime = 60,
  resetTime = 20,
  baseResources = {
    [0] = 0,
    [1] = 1,
    [2] = 1.5,
    [3] = 2,
    [4] = 6,
  },
  flagResources = {
    [0] = 0,
    [1] = 75,
    [2] = 85,
    [3] = 100,
    [4] = 500,
  },
}

-- only iconState 1 has flag info
-- "TEAM has taken the flag"
local instanceIdToMapId = {
  -- EyeoftheStorm
  [566] = {
    id = 112,
    maxBases = commonConfig.maxBases,
    tickRate = commonConfig.tickRate,
    assaultTime = commonConfig.assaultTime,
    contestedTime = commonConfig.contestedTime,
    resetTime = commonConfig.resetTime,
    baseResources = commonConfig.baseResources,
    flagResources = commonConfig.flagResources,
  },
  -- RatedEyeoftheStorm
  [968] = {
    id = 397,
    maxBases = commonConfig.maxBases,
    tickRate = commonConfig.tickRate,
    assaultTime = commonConfig.assaultTime,
    contestedTime = commonConfig.contestedTime,
    resetTime = commonConfig.resetTime,
    baseResources = commonConfig.baseResources,
    flagResources = commonConfig.flagResources,
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or commonConfig.assaultTime
  convertedInfo.contestedTime = isBlitz and 60 or commonConfig.contestedTime
  convertedInfo.maxBases = isBlitz and 4 or commonConfig.maxBases
  convertedInfo.baseResources = isBlitz
      and {
        [0] = 0,
        [1] = 1.5, -- confirmed
        [2] = 3, -- confirmed
        [3] = 5, -- confirmed
        [4] = 10, -- confirmed
      }
    or instanceIdToMapId[id].baseResources
  convertedInfo.flagResources = isBlitz
      and {
        [0] = 0,
        [1] = 100, -- confirmed
        [2] = 125, -- confirmed
        [3] = 150, -- confirmed
        [4] = 200, -- confirmed
      }
    or instanceIdToMapId[id].flagResources
  return convertedInfo
end

function EOTS:EnterZone(id, isBlitz)
  if NS.db.global.maps.eyeofthestorm.enabled then
    NS.IS_EOTS = true
    Info:SetAnchor(Banner.frame, 0, 0)
    Flags:SetAnchor(Bases.frame, 0, -5)
    BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
  end
end

function EOTS:ExitZone()
  if NS.db.global.maps.eyeofthestorm.enabled then
    NS.IS_EOTS = false
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  EOTS:RegisterZone(id)
end
