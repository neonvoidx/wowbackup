local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local TBFG = Maps:NewMod()

local commonConfig = {
  maxBases = 3,
  tickRate = 1,
  assaultTime = 6,
  contestedTime = 60,
  resetTime = 0,
  baseResources = {
    [0] = 0,
    [1] = 1,
    [2] = 3,
    [3] = 30,
  },
}

local instanceIdToMapId = {
  -- Gilneas
  [761] = {
    id = 275,
    maxBases = commonConfig.maxBases,
    tickRate = commonConfig.tickRate,
    assaultTime = commonConfig.assaultTime,
    contestedTime = commonConfig.contestedTime,
    resetTime = commonConfig.resetTime,
    baseResources = commonConfig.baseResources,
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or commonConfig.assaultTime
  convertedInfo.contestedTime = isBlitz and 30 or commonConfig.contestedTime
  convertedInfo.baseResources = {
    [0] = commonConfig.baseResources[0],
    [1] = isBlitz and 2 or commonConfig.baseResources[1],
    [2] = isBlitz and 5 or commonConfig.baseResources[2],
    [3] = commonConfig.baseResources[3],
  }
  return convertedInfo
end

function TBFG:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.thebattleforgilneas.enabled then
    Info:SetAnchor(Banner.frame, 0, 0)
    BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
  end
end

function TBFG:ExitZone()
  if NS.db.global.maps.thebattleforgilneas.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  TBFG:RegisterZone(id)
end
