local addonName, addon = ...

local function InitializeDB()
  RaidLeaderMarkerDB = RaidLeaderMarkerDB or {}

  RaidLeaderMarkerDB.leaderIcon = RaidLeaderMarkerDB.leaderIcon or {
    enabled = true,
    anchor = "CENTER",
    offsetX = 0,
    offsetY = 0,
    size = 16,
  }

  RaidLeaderMarkerDB.targetMarker = RaidLeaderMarkerDB.targetMarker or {
    enabled = true,
    anchor = "LEFT",
    offsetX = -16,
    offsetY = 0,
    size = 16,
  }
end

addon.InitializeDB = InitializeDB
