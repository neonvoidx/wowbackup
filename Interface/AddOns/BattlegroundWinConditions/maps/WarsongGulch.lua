local _, NS = ...

local next = next

local FlagPrediction = NS.FlagPrediction
local Banner = NS.Banner
local Info = NS.Info
local Stacks = NS.Stacks
local Maps = NS.Maps

local WG = Maps:NewMod()

local instanceIdToMapId = {
  -- Warsong Gulch
  [2106] = {
    id = 1339,
    stackTime = 30,
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  convertedInfo = NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.stackTime = isBlitz and 15 or 30
  return convertedInfo
end

function WG:EnterZone(id, isBlitz)
  if NS.db and NS.db.global.maps.warsonggulch.enabled then
    NS.IS_WG = true

    Info:SetAnchor(Banner.frame, 0, 0)

    if NS.db.global.general.info == false then
      Stacks:SetAnchor(Info.frame, 0, -5, "TOPLEFT", "TOPLEFT")
    else
      Stacks:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
    end

    FlagPrediction:StartInfoTracker(checkInfo(id, isBlitz))
  end
end

function WG:ExitZone()
  if NS.db.global.maps.warsonggulch.enabled then
    NS.IS_WG = false
    FlagPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  WG:RegisterZone(id)
end
