local _, NS = ...

local next = next

local CartPrediction = NS.CartPrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local SSM = Maps:NewMod()

local instanceIdToMapId = {
  -- Silvershard Mines
  [727] = {
    id = 423,
    maxCarts = 3,
    tickRate = 2,
    cartResources = {
      [0] = 0, -- 9sec -- respawn
      [1] = 90, -- 3min 0sec -- top short
      [2] = 116, -- 3min 52sec -- top long
      [3] = 64, -- 2min 8sec -- middle
      [4] = 48, -- 1min 36sec -- lava short
      [5] = 76, -- 2min 32sec -- lava long
    },
    -- Cart capping times in seconds, rounded up 1 second each
    cartTimers = {
      [0] = 10, -- 9sec -- respawn
      [1] = 181, -- 3min 0sec -- top short
      [2] = 233, -- 3min 52sec -- top long
      [3] = 129, -- 2min 8sec -- middle
      [4] = 97, -- 1min 36sec -- lava short
      [5] = 153, -- 2min 32sec -- lava long
    },
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  return convertedInfo
end

function SSM:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.silvershardmines.enabled then
    NS.IS_SSM = true

    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)
      CartPrediction:StartInfoTracker(checkInfo(id, isBlitz))
    end
  end
end

function SSM:ExitZone()
  if NS.db.global.maps.silvershardmines.enabled then
    NS.IS_SSM = false
    CartPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  SSM:RegisterZone(id)
end
