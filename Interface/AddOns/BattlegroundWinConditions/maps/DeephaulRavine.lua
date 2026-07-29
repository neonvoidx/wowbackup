local _, NS = ...

local next = next

-- local CartPrediction = NS.CartPrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local DHR = Maps:NewMod()

local instanceIdToMapId = {
  -- Deephaul Ravine
  [2656] = {
    id = 2345,
    maxCarts = 2,
    tickRate = 2,
    flagResources = {
      [0] = 0,
      [1] = 100,
      [2] = 100,
    },
    cartResources = {
      [0] = 0,
      [1] = 1.5,
      [2] = 3,
    },
    -- Cart capping times in seconds, rounded up 1 second each
    cartTimers = {
      [0] = 10, -- 9sec -- respawn
      [1] = 181, -- 3min 0sec -- top short
      [2] = 233, -- 3min 52sec -- top long
    },
  },
}

-- local function checkInfo(id, isBlitz)
--   local convertedInfo = {}
--   convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
--   return convertedInfo
-- end

function DHR:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.deephaulravine.enabled then
    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)
      -- CartPrediction:StartInfoTracker(checkInfo(id, isBlitz))
    end
  end
end

function DHR:ExitZone()
  -- if NS.db.global.maps.deephaulravine.enabled then
  --   -- CartPrediction:StopInfoTracker()
  -- end
end

for id in next, instanceIdToMapId do
  DHR:RegisterZone(id)
end
