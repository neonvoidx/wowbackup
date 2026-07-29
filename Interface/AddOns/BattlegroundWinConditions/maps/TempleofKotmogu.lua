local _, NS = ...

local next = next

local Anchor = NS.Anchor
local OrbPrediction = NS.OrbPrediction
local Info = NS.Info
local Orbs = NS.Orbs
local Maps = NS.Maps

local TOK = Maps:NewMod()

local instanceIdToMapId = {
  -- TempleofKotmogu
  -- Points for the positions:
  -- - starting area/lobby
  -- - outside main area/gates
  -- - outer ring/platform
  -- - inner pit/arena
  -- Updates every 5 second
  -- normal: 0 start, 2/5 out, 4/5 ring, 6/5 inner
  -- blitz: 0 start, 4/5 out, 6/5 ring, 8/5 inner
  -- x however many orbs you have
  -- kill = 10
  -- x4 for 45s = 4x pts
  -- only tooltip1 has info
  -- tooltip1: "TEAM has taken the ORB"
  -- 6*4=24
  -- 24*4=96
  -- aura.points[1] = Negative Healing Received, ex: -10
  -- aura.points[2] = Damage taken increase, ex: 60
  -- aura.points[3] = Damage done increase, ex: 20
  [998] = {
    id = 417,
    maxOrbs = 4,
    tickRate = 5,
    stackIncrement = 30,
    debuffTime = 15,
    buffTime = 45,
    orbResources = {
      ["starting"] = 0,
      ["outside"] = 2 / 5,
      ["inside"] = 4 / 5,
      ["arena"] = 6 / 5,
    },
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.orbResources = {
    ["starting"] = 0,
    ["outside"] = (isBlitz and 2 or 2) / 5,
    ["inside"] = (isBlitz and 6 or 4) / 5,
    ["arena"] = (isBlitz and 8 or 6) / 5,
  }
  return convertedInfo
end

function TOK:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.templeofkotmogu.enabled then
    NS.IS_TEMPLE = true

    Info:SetAnchor(Anchor.frame, 0, 0)

    if NS.db.global.general.infogroup.infobg then
      Orbs:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
    else
      Orbs:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
    end

    OrbPrediction:StartInfoTracker(checkInfo(id, isBlitz))
  end
end

function TOK:ExitZone()
  if NS.db.global.maps.templeofkotmogu.enabled then
    NS.IS_TEMPLE = false
    OrbPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  TOK:RegisterZone(id)
end
