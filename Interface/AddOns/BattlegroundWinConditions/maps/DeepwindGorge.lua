local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local DWG = Maps:NewMod()

local commonConfig = {
  maxBases = 5,
  tickRate = 2,
  assaultTime = 6,
  contestedTime = 60,
  resetTime = 0,
  controlTime = 0,
  baseResources = {
    [0] = 0,
    [1] = 1, -- blitz = 3.5 = 7
    [2] = 1.5, -- blitz = 5 = 10
    [3] = 2, -- blitz = 7.5 = 15
    [4] = 3.5, -- blitz = 25 = 50
    [5] = 30, -- blitz = 32.5 = 65
  },
}

local instanceIdToMapId = {
  -- DeepwindGorge
  [2245] = {
    id = 1576,
    maxBases = commonConfig.maxBases,
    tickRate = commonConfig.tickRate,
    assaultTime = commonConfig.assaultTime,
    contestedTime = commonConfig.contestedTime,
    resetTime = commonConfig.resetTime,
    controlTime = commonConfig.controlTime,
    baseResources = commonConfig.baseResources,
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or commonConfig.assaultTime
  convertedInfo.contestedTime = isBlitz and 30 or commonConfig.contestedTime
  convertedInfo.resetTime = isBlitz and 5 or commonConfig.resetTime
  convertedInfo.controlTime = isBlitz and 45 or commonConfig.controlTime
  convertedInfo.baseResources = {
    [0] = commonConfig.baseResources[0],
    [1] = isBlitz and 3.5 or commonConfig.baseResources[1],
    [2] = isBlitz and 5 or commonConfig.baseResources[2],
    [3] = isBlitz and 7.5 or commonConfig.baseResources[3],
    [4] = isBlitz and 25 or commonConfig.baseResources[4],
    [5] = isBlitz and 32.5 or commonConfig.baseResources[5],
  }
  return convertedInfo
end

function DWG:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.deepwindgorge.enabled then
    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)
      BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
    end
  end
end

function DWG:ExitZone()
  if NS.db.global.maps.deepwindgorge.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  DWG:RegisterZone(id)
end
