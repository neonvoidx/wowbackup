local _, NS = ...

local pairs = pairs
local tnumber = tonumber
local CreateFrame = CreateFrame
local UnitName = UnitName
-- local GetRealmName = GetRealmName

local sfind = string.find
local smatch = string.match
local mfloor = math.floor

local After = C_Timer.After
local GetIconAndTextWidgetVisualizationInfo = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo
local Banner = NS.Banner
local Stacks = NS.Stacks

local FlagPrediction = {}
NS.FlagPrediction = FlagPrediction

local FlagsFrame = CreateFrame("Frame", "FlagsFrame")
FlagsFrame:SetScript("OnEvent", function(_, event, ...)
  if FlagPrediction[event] then
    FlagPrediction[event](FlagPrediction, ...)
  end
end)

-- Reload correction via SavedVariables: save stack count + time when stacks start,
-- recover on reload by computing elapsed ticks.
-- mapID is stored to reject stale saves from a previous BG.
local curMapID = 0

-- Returns count, remaining (seconds until next tick). remaining is nil on no-save (fresh start).
local function getExistingFlagStacks()
  local saved = NS.db.global.lastFlagStackInfo
  if not saved then
    return 0, nil
  end
  if saved.mapID ~= curMapID then
    return 0, nil
  end
  local elapsed = GetTime() - saved.time
  local recovered = saved.count + mfloor(elapsed / saved.stackTime)
  local remaining = saved.stackTime - (elapsed % saved.stackTime)
  return recovered, remaining
end

-- remaining: seconds until next tick. nil = fresh start (uses full stackTime).
-- Saves tickStartTime so subsequent reloads recompute correctly.
local function startStacks(stackTime, count, remaining)
  remaining = remaining or stackTime
  local tickStartTime = GetTime() - (stackTime - remaining)
  NS.db.global.lastFlagStackInfo = { count = count, time = tickStartTime, stackTime = stackTime, mapID = curMapID }
  Stacks:Start(remaining, count, stackTime)
end

local function stopStacks()
  NS.db.global.lastFlagStackInfo = nil
  Stacks:Stop(Stacks, Stacks.timerAnimationGroup)
end

do
  -- carrier names tracked but never read (write-only state; luacheck W231)
  -- luacheck: ignore 231
  local allyFlagCarrier, hordeFlagCarrier = nil, nil
  local allyFlags, hordeFlags = 0, 0
  local curMap = {
    id = 0,
    stackTime = 0,
  }
  local allyHasFlag, hordeHasFlag = false, false
  local stacksCounting = false
  local currentStacks = 0

  function FlagPrediction:FlagTracker(widgetID)
    -- widgetType == 14
    -- 1640 = WSG, TP
    if widgetID == 1640 then
      -- Warsong Gulch, Twin Peaks
      allyFlags = 0
      hordeFlags = 0

      local flagInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
        return
      end

      for _, v in pairs(flagInfo.leftIcons) do
        if v.iconState == Enum.IconState.ShowState1 then
          allyFlags = allyFlags + 1
          allyHasFlag = true
          NS.HAS_FLAG_CARRIER = true
        end
      end

      for _, v in pairs(flagInfo.rightIcons) do
        if v.iconState == Enum.IconState.ShowState1 then
          hordeFlags = hordeFlags + 1
          hordeHasFlag = true
          NS.HAS_FLAG_CARRIER = true
        end
      end

      -- Reload recovery only: resume stacks if we have saved state from this game.
      -- Fresh game / mid-game join without save: do nothing here; chat handlers start stacks live.
      if (allyHasFlag or hordeHasFlag) and not stacksCounting then
        local count, remaining = getExistingFlagStacks()
        if remaining ~= nil then
          stacksCounting = true
          NS.STACKS_COUNTING = stacksCounting
          startStacks(curMap.stackTime, count, remaining)
        end
      end
    end
  end

  do
    local winTime = 0
    local prevAScore, prevHScore = 0, 0
    -- assigned but never read (luacheck W231)
    -- luacheck: ignore 231
    local minScore, maxScore, aScore, hScore = 0, 3, 0, 0

    function FlagPrediction:FlagPredictor(team)
      if aScore == 0 and hScore == 0 then
        Banner:Start(winTime, "TIE")
      elseif aScore < maxScore and hScore < maxScore then
        if team then
          NS.db.global.lastFlagCapBy = team
        end

        local winName, winText

        if aScore == hScore then
          if NS.db.global.lastFlagCapBy == NS.ALLIANCE_NAME then
            winName = NS.ALLIANCE_NAME
          elseif NS.db.global.lastFlagCapBy == NS.HORDE_NAME then
            winName = NS.HORDE_NAME
          end
        else
          winName = (aScore > hScore) and NS.ALLIANCE_NAME or NS.HORDE_NAME
        end

        if winName then
          winText = (winName == NS.PLAYER_FACTION) and "WIN" or "LOSE"
          Banner:Start(winTime, winText)
        end
      end
    end

    function FlagPrediction:GetRemainingTime(widgetID, team)
      local timeInfo = GetIconAndTextWidgetVisualizationInfo(widgetID)

      if timeInfo and timeInfo.text and timeInfo.state == Enum.IconAndTextWidgetState.Shown then
        local minutes, seconds = smatch(timeInfo.text, "(%d+):(%d+)")

        minutes = tnumber(minutes)
        seconds = tnumber(seconds)

        if minutes and seconds then
          local remaining = seconds + NS.minutesToSeconds(minutes)

          if remaining > 0 then
            winTime = remaining + 1
            self:FlagPredictor(team)
          end
        end
      end
    end

    function FlagPrediction:GetObjectivesByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        allyFlags = 0
        hordeFlags = 0

        local flagInfo = GetDoubleStateIconRowVisualizationInfo(1640)

        if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
          return
        end

        for _, v in pairs(flagInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            allyFlags = allyFlags + 1
            allyHasFlag = true
            NS.HAS_FLAG_CARRIER = true
            if UnitName("arena2") then
              allyFlagCarrier = NS.GetUnitNameAndRealm("arena2")
            end
          end
        end

        for _, v in pairs(flagInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            hordeFlags = hordeFlags + 1
            hordeHasFlag = true
            NS.HAS_FLAG_CARRIER = true
            if UnitName("arena1") then
              hordeFlagCarrier = NS.GetUnitNameAndRealm("arena1")
            end
          end
        end

        if (allyHasFlag or hordeHasFlag) and not stacksCounting then
          local count, remaining = getExistingFlagStacks()
          if remaining ~= nil then
            stacksCounting = true
            NS.STACKS_COUNTING = stacksCounting
            startStacks(curMap.stackTime, count, remaining)
          end
        end
      end
    end

    function FlagPrediction:GetTimeByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        After(0, function()
          self:GetRemainingTime(6)
        end)
      end
    end

    function FlagPrediction:GetScoreByMapID(mapID)
      -- mapID == Zone ID in-game
      -- WSG = 1339
      -- TP = 206
      if mapID == 1339 or mapID == 206 then
        -- Warsong Gulch, Twin Peaks
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(2)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar

        prevAScore = aScore
        prevHScore = hScore

        if aScore > 0 and hScore > 0 then
          if aScore > hScore then
            NS.db.global.lastFlagCapBy = NS.ALLIANCE_NAME
          elseif hScore > aScore then
            NS.db.global.lastFlagCapBy = NS.HORDE_NAME
          end
        end
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_ALLIANCE(message)
      local pickedName = smatch(message, "picked up by (.+)%!") -- horde picked ally flag
      if pickedName then
        hordeFlagCarrier = pickedName
        hordeHasFlag = true
        NS.HAS_FLAG_CARRIER = true
        if allyHasFlag and not stacksCounting then
          stacksCounting = true
          NS.STACKS_COUNTING = stacksCounting
          startStacks(curMap.stackTime, 0)
        end
      end

      if smatch(message, "dropped by (.+)%!") then -- horde dropped ally flag
        hordeHasFlag = false
        if allyHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end

      if sfind(message, "returned to its base by") then -- ally flag returned by ally
        hordeFlagCarrier = nil
        hordeHasFlag = false
        if not allyHasFlag and stacksCounting then
          NS.HAS_FLAG_CARRIER = false
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          stopStacks()
        end
      end

      if sfind(message, "captured the") then -- alliance captured horde flag
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        stopStacks()
        self:GetRemainingTime(6, NS.ALLIANCE_NAME)
      end

      if sfind(message, "wins") then -- ally wins
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        stopStacks()
        Banner:Stop(Banner, Banner.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_HORDE(message)
      local pickedName = smatch(message, "picked up by (.+)%!") -- ally picked horde flag
      if pickedName then
        allyFlagCarrier = pickedName
        allyHasFlag = true
        NS.HAS_FLAG_CARRIER = true
        if hordeHasFlag and not stacksCounting then
          stacksCounting = true
          NS.STACKS_COUNTING = stacksCounting
          startStacks(curMap.stackTime, 0)
        end
      end

      if smatch(message, "dropped by (.+)%!") then -- ally dropped horde flag
        allyHasFlag = false
        if hordeHasFlag == false then
          NS.HAS_FLAG_CARRIER = false
        end
      end

      if sfind(message, "returned to its base by") then -- horde flag returned by horde
        allyFlagCarrier = nil
        allyHasFlag = false
        if not hordeHasFlag and stacksCounting then
          NS.HAS_FLAG_CARRIER = false
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          stopStacks()
        end
      end

      if sfind(message, "captured the") then -- horde captured alliance flag
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        stopStacks()
        self:GetRemainingTime(6, NS.HORDE_NAME)
      end

      if sfind(message, "wins") then -- horde wins
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        stopStacks()
        Banner:Stop(Banner, Banner.timerAnimationGroup)
      end
    end

    function FlagPrediction:CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
      local flagsReturned = string.find(message, "placed at their bases") -- all flags returned
      if flagsReturned then
        allyFlagCarrier = nil
        hordeFlagCarrier = nil
        allyHasFlag = false
        hordeHasFlag = false
        NS.HAS_FLAG_CARRIER = false
        stacksCounting = false
        NS.STACKS_COUNTING = stacksCounting
        currentStacks = 0
        NS.CURRENT_STACKS = currentStacks
        stopStacks()
      end
    end

    function FlagPrediction:ScoreTracker(widgetID)
      -- widgetType == 3
      -- 2 = WG, TP
      if widgetID == 2 then
        -- Warsong Gulch, Twin Peaks
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        aScore = scoreInfo.leftBarValue -- Alliance Bar
        hScore = scoreInfo.rightBarValue -- Horde Bar

        if (aScore ~= prevAScore or hScore ~= prevHScore) and aScore < maxScore and hScore < maxScore then
          prevAScore = aScore
          prevHScore = hScore

          NS.Debug("TRIGGERED", "aScore", aScore, "hScore", hScore)

          allyFlagCarrier = nil
          hordeFlagCarrier = nil
          allyHasFlag = false
          hordeHasFlag = false
          NS.HAS_FLAG_CARRIER = false
          stacksCounting = false
          NS.STACKS_COUNTING = stacksCounting
          currentStacks = 0
          NS.CURRENT_STACKS = currentStacks
          stopStacks()
          self:GetRemainingTime(6, NS.HORDE_NAME)
        end
      end
    end

    function FlagPrediction:TimeTracker(widgetID)
      -- widgetType == 0
      -- 6 = WG, TP
      if widgetID == 6 then
        local timeInfo = GetIconAndTextWidgetVisualizationInfo(widgetID)

        if not timeInfo or not timeInfo.text or timeInfo.state ~= Enum.IconAndTextWidgetState.Shown then
          return
        end

        self:GetRemainingTime(widgetID)
      end
    end

    --[[
    -- while this tracks updates to who has the flag
    -- it doesnt provide a safe way to detect dropped stacks
    --
    -- since we can know if both teams have no flag
    -- but not know if the flags were returned post drop
    -- i.e. someone can re-pick either flag before it gets returned, retaining stacks
    --
    -- seen, unseen, cleared, destroyed
    -- as alliance arena1 is horde, arena2 is ally
    --
    -- this updates more often sometimes then when someone actually picks the flag,
    -- so we can't use this reliably
    --]]
    -- function FlagPrediction:ARENA_OPPONENT_UPDATE(unitToken, updateReason)
    --   -- make sure we dont spam updates when the game is over
    --   if aScore < maxScore and hScore < maxScore then
    --     -- we only care about the flag carriers
    --     if unitToken == "arena1" or unitToken == "arena2" then
    --       -- old code here
    --     end
    --   end
    -- end

    function FlagPrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        FlagPrediction:ScoreTracker(widgetID)
        FlagPrediction:FlagTracker(widgetID)
        FlagPrediction:TimeTracker(widgetID)
      end
    end

    function FlagPrediction:StartInfoTracker(mapInfo)
      -- local
      winTime = 0
      prevAScore, prevHScore = 0, 0
      minScore, maxScore, aScore, hScore = 0, 3, 0, 0
      -- global
      allyFlagCarrier, hordeFlagCarrier = nil, nil
      NS.HAS_FLAG_CARRIER = false
      allyFlags, hordeFlags = 0, 0
      allyHasFlag, hordeHasFlag = false, false
      curMap = mapInfo
      curMapID = curMap.id
      stacksCounting = false
      NS.STACKS_COUNTING = stacksCounting
      currentStacks = 0
      NS.CURRENT_STACKS = currentStacks

      self:GetScoreByMapID(curMap.id)
      self:GetObjectivesByMapID(curMap.id)
      self:GetTimeByMapID(curMap.id)

      -- FlagsFrame:RegisterEvent("UNIT_AURA")
      FlagsFrame:RegisterEvent("UPDATE_UI_WIDGET")
      -- FlagsFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
      FlagsFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    end
  end
end

function FlagPrediction:StopInfoTracker()
  NS.db.global.lastFlagStackInfo = nil
  NS.db.global.lastFlagCapBy = ""
  FlagsFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  -- FlagsFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
  FlagsFrame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
end
