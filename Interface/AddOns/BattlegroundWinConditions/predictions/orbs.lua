local _, NS = ...

local pairs = pairs
local CreateFrame = CreateFrame
-- local GetRealmName = GetRealmName
local UnitExists = UnitExists
local time = time

local mfloor = math.floor
local smatch = string.match
local sfind = string.find

local NewTicker = C_Timer.NewTicker
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local GetActiveMatchDuration = C_PvP.GetActiveMatchDuration

local Orbs = NS.Orbs

local OrbPrediction = {}
NS.OrbPrediction = OrbPrediction

local orbTicker = nil

local OrbFrame = CreateFrame("Frame", "OrbFrame")
OrbFrame:SetScript("OnEvent", function(_, event, ...)
  if OrbPrediction[event] then
    OrbPrediction[event](OrbPrediction, ...)
  end
end)

do
  local allyOrbs, hordeOrbs = 0, 0
  local prevAOrbs, prevHOrbs = 0, 0
  local curMap = {
    id = 0,
    maxOrbs = 0,
    tickRate = 0,
    stackIncrement = 0,
    debuffTime = 0,
    buffTime = 0,
  }

  do
    local arenaIndexToOrb = { [1] = "Blue", [2] = "Purple", [3] = "Green", [4] = "Orange" }
    local orbCarriers = {
      ["Blue"] = "",
      ["Green"] = "",
      ["Orange"] = "",
      ["Purple"] = "",
    }
    local orbStacks = {
      ["Blue"] = 0,
      ["Green"] = 0,
      ["Orange"] = 0,
      ["Purple"] = 0,
    }
    local orbPickupTime = {
      ["Blue"] = nil,
      ["Green"] = nil,
      ["Orange"] = nil,
      ["Purple"] = nil,
    }

    -- Reload correction via SavedVariables: save per-orb pickup times on every
    -- pickup/drop, recover on reload by recomputing elapsed stacks.
    -- Pickup times are epoch (time(), not GetTime()) so they also survive a
    -- client crash/restart.
    -- mapID is stored to reject stale saves from a previous BG.
    local function saveOrbStacks()
      local pickupTime = {}
      for orbKey, t in pairs(orbPickupTime) do
        pickupTime[orbKey] = t
      end
      NS.db.global.lastOrbStackInfo = { pickupTime = pickupTime, mapID = curMap.id }
    end

    -- Trust saved pickup times only if they're from this map and fall inside
    -- the current match (epoch elapsed <= live match clock) -- anything else
    -- is a previous match's state and is discarded. Pickups can only exist
    -- while the match clock is running (orbs spawn after the gates), so a
    -- 0/nil duration always means stale state.
    local function getExistingOrbStacks()
      local restored = {}
      local saved = NS.db.global.lastOrbStackInfo
      if not saved or saved.mapID ~= curMap.id or not saved.pickupTime then
        return restored
      end
      local matchDuration = GetActiveMatchDuration()
      if not matchDuration or matchDuration == 0 then
        return restored
      end
      local t = time()
      for orbKey, pickupTime in pairs(saved.pickupTime) do
        local elapsed = t - pickupTime
        -- +5s slop: the match clock and our epoch stamps tick independently
        if elapsed >= 0 and elapsed <= matchDuration + 5 then
          restored[orbKey] = pickupTime
        end
      end
      return restored
    end

    local function computeOrbStacks(pickupTime, t)
      return curMap.stackIncrement + mfloor((t - pickupTime) / curMap.debuffTime) * curMap.stackIncrement
    end

    local function tickOrbStacks()
      local t = time()
      local changed = false
      for orbKey, pickupTime in pairs(orbPickupTime) do
        if pickupTime then
          local newStacks = computeOrbStacks(pickupTime, t)
          if newStacks ~= orbStacks[orbKey] then
            orbStacks[orbKey] = newStacks
            changed = true
          end
        end
      end
      if changed then
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:BuffTimer(aOrbs, hOrbs, pAOrbs, pHOrbs)
      if aOrbs ~= pAOrbs or hOrbs ~= pHOrbs then
        prevAOrbs = aOrbs
        prevHOrbs = hOrbs

        if aOrbs == curMap.maxOrbs then
          Orbs:Start(curMap.buffTime, NS.formatTeamName(NS.ALLIANCE_NAME, NS.PLAYER_FACTION))
        end

        if hOrbs == curMap.maxOrbs then
          Orbs:Start(curMap.buffTime, NS.formatTeamName(NS.HORDE_NAME, NS.PLAYER_FACTION))
        end

        if aOrbs ~= curMap.maxOrbs and hOrbs ~= curMap.maxOrbs then
          Orbs:Stop(Orbs, Orbs.timerAnimationGroup, false)
        end
      end
    end

    function OrbPrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- TOK = 417
      if mapID == 417 then
        -- Temple of Kotmogu
        allyOrbs, hordeOrbs = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(1683)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        -- temple base states are always state 1 which is technically contested in all other maps
        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            -- local str = v.state1Tooltip
            allyOrbs = allyOrbs + 1
            -- local orb = smatch(str, "the (%a+) orb")
            -- pickedOrbs[orb] = true
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            -- local str = v.state1Tooltip
            hordeOrbs = hordeOrbs + 1
            -- local orb = smatch(str, "the (%a+) orb")
            -- pickedOrbs[orb] = true
          end
        end
      end
    end

    function OrbPrediction:ObjectiveTracker(widgetID)
      -- widgetType == 14
      -- 1683 = TOK
      if widgetID == 1683 then
        -- Temple of Kotmogu
        allyOrbs, hordeOrbs = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        -- temple base states are always state 1 which is technically contested in all other maps
        for _, v in pairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            -- local str = v.state1Tooltip
            allyOrbs = allyOrbs + 1
            -- local orb = smatch(str, "the (%a+) orb")
            -- pickedOrbs[orb] = true
          end
        end

        for _, v in pairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            -- local str = v.state1Tooltip
            hordeOrbs = hordeOrbs + 1
            -- local orb = smatch(str, "the (%a+) orb")
            -- pickedOrbs[orb] = true
          end
        end

        self:BuffTimer(allyOrbs, hordeOrbs, prevAOrbs, prevHOrbs)
      end
    end

    function OrbPrediction:GetStacksByMapID(mapID)
      -- mapID == Zone ID in-game
      -- TOK = 417
      if mapID == 417 then
        -- Reload recovery: resume from saved pickup times where valid, seed
        -- any carrier the restore didn't cover at base stacks (the real
        -- pickup time is unknowable here)
        local restored = getExistingOrbStacks()
        local t = time()
        for i = 1, 4 do
          local orbKey = arenaIndexToOrb[i]
          if UnitExists("arena" .. i) then
            orbCarriers[orbKey] = NS.GetUnitNameAndRealm("arena" .. i)
            orbPickupTime[orbKey] = restored[orbKey] or t
            orbStacks[orbKey] = computeOrbStacks(orbPickupTime[orbKey], t)
          else
            orbCarriers[orbKey] = ""
            orbPickupTime[orbKey] = nil
            orbStacks[orbKey] = 0
          end
        end
        saveOrbStacks()
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:ARENA_OPPONENT_UPDATE(unitToken, updateReason)
      local idx = tonumber(unitToken:match("^arena(%d)$"))
      if not idx or idx > 4 then
        return
      end
      local orbKey = arenaIndexToOrb[idx]
      if not orbKey then
        return
      end
      if updateReason == "seen" then
        if UnitExists(unitToken) then
          orbCarriers[orbKey] = NS.GetUnitNameAndRealm(unitToken)
          if not orbPickupTime[orbKey] then
            orbPickupTime[orbKey] = time()
            orbStacks[orbKey] = curMap.stackIncrement
            saveOrbStacks()
          end
        end
      elseif updateReason == "cleared" then
        if not UnitExists(unitToken) then
          orbCarriers[orbKey] = ""
          orbPickupTime[orbKey] = nil
          orbStacks[orbKey] = 0
          saveOrbStacks()
        end
      end
      self:BuffTimer(allyOrbs, hordeOrbs, prevAOrbs, prevHOrbs)
      Orbs:StartOrbList(orbStacks)
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_ALLIANCE(message, _)
      local pickedName = smatch(message, "^(.-) has taken the")
      local pickedOrb = smatch(message, "the (|c%x%x%x%x%x%x%x%x%a+|r) orb")
      if pickedOrb then
        local orbKey = NS.stripColorCode(pickedOrb)
        orbCarriers[orbKey] = pickedName
        orbPickupTime[orbKey] = time()
        orbStacks[orbKey] = curMap.stackIncrement
        saveOrbStacks()
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message, _)
      local pickedName = smatch(message, "^(.-) has taken the")
      local pickedOrb = smatch(message, "the (|c%x%x%x%x%x%x%x%x%a+|r) orb")
      if pickedOrb then
        local orbKey = NS.stripColorCode(pickedOrb)
        orbCarriers[orbKey] = pickedName
        orbPickupTime[orbKey] = time()
        orbStacks[orbKey] = curMap.stackIncrement
        saveOrbStacks()
        Orbs:StartOrbList(orbStacks)
      end
    end

    function OrbPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local gameOver = sfind(message, "wins")
      if gameOver then
        Orbs:Stop(Orbs, Orbs.timerAnimationGroup, true)

        for k, _ in pairs(orbCarriers) do
          orbCarriers[k] = ""
          orbPickupTime[k] = nil
          orbStacks[k] = 0
        end
        NS.db.global.lastOrbStackInfo = nil
      end
    end

    function OrbPrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        OrbPrediction:ObjectiveTracker(widgetID)
      end
    end

    function OrbPrediction:StartInfoTracker(mapInfo)
      orbCarriers = {
        ["Blue"] = "",
        ["Green"] = "",
        ["Orange"] = "",
        ["Purple"] = "",
      }
      orbStacks = {
        ["Blue"] = 0,
        ["Green"] = 0,
        ["Orange"] = 0,
        ["Purple"] = 0,
      }
      orbPickupTime = {
        ["Blue"] = nil,
        ["Green"] = nil,
        ["Orange"] = nil,
        ["Purple"] = nil,
      }
      curMap = mapInfo
      allyOrbs, hordeOrbs = 0, 0
      prevAOrbs, prevHOrbs = 0, 0

      self:GetObjectivesByMapID(curMap.id)
      self:GetStacksByMapID(curMap.id)
      Orbs:StartOrbList(orbStacks)

      orbTicker = NewTicker(1, tickOrbStacks)

      OrbFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
      OrbFrame:RegisterEvent("UPDATE_UI_WIDGET")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
      OrbFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    end
  end
end

function OrbPrediction:StopInfoTracker()
  NS.db.global.lastOrbStackInfo = nil

  if orbTicker then
    orbTicker:Cancel()
    orbTicker = nil
  end

  OrbFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
  OrbFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
  OrbFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
end
