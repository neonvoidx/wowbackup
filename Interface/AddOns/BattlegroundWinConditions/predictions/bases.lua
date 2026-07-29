local _, NS = ...

local next = next
local pairs = pairs
local ipairs = ipairs
local GetTime = GetTime
local CreateFrame = CreateFrame

local sfind = string.find
local smatch = string.match
local mfloor = math.floor
local mceil = math.ceil
local mmin = math.min
local mmax = math.max
local twipe = wipe

local After = C_Timer.After
local GetDoubleStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo
local GetDoubleStateIconRowVisualizationInfo = C_UIWidgetManager.GetDoubleStateIconRowVisualizationInfo

local Banner = NS.Banner
local Score = NS.Score
local Bases = NS.Bases
local Flags = NS.Flags
local Interface = NS.Interface

local BasePrediction = {}
NS.BasePrediction = BasePrediction

local BaseFrame = CreateFrame("Frame", "BaseFrame")
BaseFrame:SetScript("OnEvent", function(_, event, ...)
  if BasePrediction[event] then
    BasePrediction[event](BasePrediction, ...)
  end
end)

do
  local allyBases, allyIncBases = 0, 0
  local hordeBases, hordeIncBases = 0, 0
  local winBases, loseBases = 0, 0
  local allyFlags, hordeFlags = 0, 0
  local allyTimers, hordeTimers, winTable = {}, {}, {}
  -- assigned from widget info but never read here (luacheck W231)
  -- luacheck: ignore 231
  local minScore, maxScore, winScore, loseScore = 0, 1500, 0, 0
  local winName, loseName, winText = "", "", ""
  local curMap = {
    id = 0,
    maxBases = 0,
    tickRate = 0,
    assaultTime = 0,
    contestedTime = 0,
    resetTime = 0,
    baseResources = {},
    flagResources = {},
  }

  NS.ACTIVE_BASE_COUNT = 0
  NS.INCOMING_BASE_COUNT = 0
  NS.WIN_INC_BASE_COUNT = 0
  NS.BASE_TIMER_EXPIRED = false

  -- Configuration tables for map-specific widget IDs and patterns
  local SCORE_WIDGET_IDS = {
    [1366] = 1671, -- Arathi Basin
    [1383] = 1671, -- Arathi Comp Stomp
    [837] = 1671, -- Arathi Blizzard
    [275] = 1671, -- The Battle for Gilneas
    [112] = 1671, -- Eye of the Storm
    [397] = 1671, -- Eye of the Storm (Rated)
    [1576] = 2074, -- Deepwind Gorge
  }

  local OBJECTIVE_CONFIG = {
    -- Standard base BGs use pattern "(.-) %-%s" for extracting base name
    [1366] = { widgetID = 1645, pattern1 = "(.-) %-%s", pattern2 = "(.-) %-%s", isEOTS = false },
    [1383] = { widgetID = 1645, pattern1 = "(.-) %-%s", pattern2 = "(.-) %-%s", isEOTS = false },
    [837] = { widgetID = 1645, pattern1 = "(.-) %-%s", pattern2 = "(.-) %-%s", isEOTS = false },
    [1576] = { widgetID = 2339, pattern1 = "(.-) %-%s", pattern2 = "(.-) %-%s", isEOTS = false },
    [275] = { widgetID = 1670, pattern1 = "(.-) %-%s", pattern2 = "(.-) %-%s", isEOTS = false },
    -- EOTS uses different patterns
    [112] = { widgetID = 1672, pattern1 = "assaulted the (.+)", pattern2 = "captured the (.+)", isEOTS = true },
    [397] = { widgetID = 1672, pattern1 = "assaulted the (.+)", pattern2 = "captured the (.+)", isEOTS = true },
  }

  -- Helper function to process base icons for one faction
  local function processBaseIcons(icons, config, isAlliance)
    local bases, incBases, flags = 0, 0, 0
    local ownTimers = isAlliance and allyTimers or hordeTimers
    local enemyTimers = isAlliance and hordeTimers or allyTimers

    for _, v in ipairs(icons) do
      local iconState = v.iconState
      if iconState == Enum.IconState.ShowState1 then
        local str = v.state1Tooltip

        -- EOTS has flags mixed in with bases
        if config.isEOTS and sfind(str, "flag") then
          flags = flags + 1
        else
          incBases = incBases + 1
          local base = smatch(str, config.pattern1)
          -- if enemy had the base, now they don't
          if enemyTimers[base] then
            enemyTimers[base] = nil
          end
          -- if fresh capture, or they once had it lose it fully then got it again
          if ownTimers[base] == nil or (ownTimers[base] and ownTimers[base] - GetTime() <= 0) then
            ownTimers[base] = curMap.contestedTime + GetTime()
          end
        end
      elseif iconState == Enum.IconState.ShowState2 then
        bases = bases + 1
        local base = smatch(v.state2Tooltip, config.pattern2)
        -- if taking a base from enemy mid-cap
        if enemyTimers[base] then
          enemyTimers[base] = nil
        end
        -- if finished capping a base, now its theirs
        if ownTimers[base] then
          ownTimers[base] = nil
        end
      end
    end

    return bases, incBases, flags
  end

  function BasePrediction:GetFlagValue()
    if allyBases > 0 or hordeBases > 0 then
      local flagsNeeded = (loseBases > 0 and winText ~= "TIE")
          and NS.calculateFlagsToCatchUp(maxScore, winScore, loseScore, winBases, loseBases, curMap)
        or 0

      local allyFlagValue = curMap.flagResources[allyBases]
      local hordeFlagValue = curMap.flagResources[hordeBases]
      local flagValue = NS.PLAYER_FACTION == NS.ALLIANCE_NAME and allyFlagValue or hordeFlagValue

      Flags:SetText(Flags, NS.PLAYER_FACTION, winName, flagsNeeded, flagValue, allyFlags, hordeFlags)

      if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
        NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, NS.Bases, NS.Flags }, "BasePrediction:GetFlagValue")
      end
    end
  end

  function BasePrediction:FlagTracker(widgetID)
    -- widgetType == 14
    -- 1672 = EOTS
    if widgetID == 1672 then
      -- Eye of the Storm
      allyFlags = 0
      hordeFlags = 0

      local flagInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

      if not flagInfo or not flagInfo.leftIcons or not flagInfo.rightIcons then
        return
      end

      for _, v in pairs(flagInfo.leftIcons) do
        if v.iconState == Enum.IconState.ShowState1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            allyFlags = allyFlags + 1
          end
        end
      end

      for _, v in pairs(flagInfo.rightIcons) do
        if v.iconState == Enum.IconState.ShowState1 then
          local str = v.state1Tooltip

          if sfind(str, "flag") then
            hordeFlags = hordeFlags + 1
          end
        end
      end

      if NS.isEOTS(curMap.id) then
        if winText == "TIE" then
          Flags:SetAnchor(Banner.frame, 0, -5)
        else
          Flags:SetAnchor(Bases.frame, 0, -5)
        end

        self:GetFlagValue()
      end
    end
  end

  do
    local prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
    local timeBetweenEachTick, prevTick, winTime = 0, 0, 0
    local aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0
    local prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0

    -- Compensates for tick drift caused by the After(0.5) delay in ScoreTracker.
    -- Score events arrive ~0.5s after the actual server tick, so the raw calcWinTime
    -- is slightly stale by the time we process it. Instead of subtracting a fixed 0.5s
    -- (like Capping does), we subtract the actual elapsed time since the tick event
    -- (tickAge = GetTime() - tickTime) for better accuracy under variable latency.
    local function getAdjustedWinTime(calcWinTime, tickTime)
      if tickTime and tickTime > 0 then
        local tickAge = GetTime() - tickTime
        local adjusted = mmax(0, calcWinTime - tickAge)
        NS.Debug("DRIFT:", calcWinTime, "->", adjusted, "age:", tickAge)
        return adjusted
      end
      return calcWinTime
    end

    function BasePrediction:BasePredictor(refresh, tickTime)
      if aScore < maxScore and hScore < maxScore then
        -- For REFRESH calls, scores haven't changed since the last tick event,
        -- so use prevTime (the last tick's timestamp) as the drift reference.
        -- Without this, REFRESH would use GetTime() as the baseline, causing a
        -- ~1s prediction jump since the drift correction would be near-zero.
        local effectiveTickTime = tickTime or (refresh and prevTime > 0 and prevTime or nil)
        local source = refresh and "REFRESH" or (tickTime and "SCORE_TICK" or "OBJECTIVE")
        NS.Debug(
          "PREDICT [" .. source .. "] A:",
          aScore,
          "H:",
          hScore,
          "ABases:",
          allyBases,
          "+" .. allyIncBases,
          "HBases:",
          hordeBases,
          "+" .. hordeIncBases
        )

        if refresh then
          self:GetScoreByMapID(curMap.id)
          self:GetObjectivesByMapID(curMap.id)
        end

        local allyTicksToWin = NS.getWinTicks(maxScore, aScore, curMap.tickRate, curMap.baseResources[allyBases])
        local allyTimeToWin = NS.getWinTime(allyTicksToWin, curMap.tickRate)

        local hordeTicksToWin = NS.getWinTicks(maxScore, hScore, curMap.tickRate, curMap.baseResources[hordeBases])
        local hordeTimeToWin = NS.getWinTime(hordeTicksToWin, curMap.tickRate)

        local currentWinTicks = mmin(allyTicksToWin, hordeTicksToWin)
        local currentWinTime = mmin(allyTimeToWin, hordeTimeToWin)
        NS.Debug(
          "PREDICT winTime:",
          currentWinTime,
          "ticks:",
          currentWinTicks,
          "aTime:",
          allyTimeToWin,
          "hTime:",
          hordeTimeToWin,
          "tickRate:",
          curMap.tickRate
        )

        if allyIncBases == 0 and hordeIncBases == 0 then
          local winTicks = currentWinTicks
          winTime = currentWinTime

          if allyTicksToWin == hordeTicksToWin then
            winText = "TIE"

            Banner:Start(getAdjustedWinTime(winTime, effectiveTickTime), winText)
            Bases:Stop(Bases, Bases.timerAnimationGroup)
            Score:Stop(Score)
            Flags:Stop(Flags)

            if NS.isEOTS(curMap.id) then
              Flags:SetAnchor(Banner.frame, 0, -5)
              self:GetFlagValue()
            else
              if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                NS.UpdateInfoSize(
                  NS.Info.frame,
                  NS.Banner,
                  { NS.Score, NS.Bases, NS.Flags },
                  "BasePrediction:BasePredictor"
                )
              end
            end

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local aWins = allyTicksToWin < hordeTicksToWin

            local allyIncrease = curMap.tickRate * curMap.baseResources[allyBases]
            local afs = aWins and maxScore or aScore + (currentWinTicks * allyIncrease)
            local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs

            local hordeIncrease = curMap.tickRate * curMap.baseResources[hordeBases]
            local hfs = aWins and hScore + (currentWinTicks * hordeIncrease) or maxScore
            local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

            winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(getAdjustedWinTime(winTime, effectiveTickTime), winText)
            Score:SetText(Score.text, finalAScore, finalHScore)

            -- local currentWinBases = aWins and allyBases or hordeBases
            -- local currentLoseBases = aWins and hordeBases or allyBases

            winBases = aWins and allyBases or hordeBases
            loseBases = aWins and hordeBases or allyBases
            winScore = aWins and aScore or hScore
            loseScore = aWins and hScore or aScore

            NS.WIN_INC_BASE_COUNT = 0

            winTable = {}
            for needBases = loseBases + 1, curMap.maxBases do
              local table = NS.checkWinCondition(
                needBases,
                winBases,
                loseBases,
                winScore,
                loseScore,
                winName,
                loseName,
                winTime,
                winTicks,
                0,
                curMap.maxBases,
                maxScore,
                winTime,
                winTicks,
                curMap.tickRate,
                curMap.baseResources,
                curMap.assaultTime,
                curMap.contestedTime
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end

              local firstKey = next(winTable)
              if firstKey and winTable[firstKey] then
                -- Skip expired conditions unless it's the final (maxBases) condition.
                -- This ensures REFRESH transitions to the next base count instead of
                -- looping on the same expired condition 10x/sec.
                if winTable[firstKey].ownTime - GetTime() > 0 or needBases == curMap.maxBases then
                  break
                end
                NS.Debug("SKIP expired condition bases:", needBases, "ownTime:", winTable[firstKey].ownTime - GetTime())
                twipe(winTable)
              end
            end
          end
        else
          local aBaseIncrease, aScoreIncrease, aTickIncrease = NS.getIncomingBaseInfo(
            allyTimers,
            allyBases,
            allyIncBases,
            curMap.baseResources,
            curMap.tickRate,
            currentWinTicks
          )
          local hBaseIncrease, hScoreIncrease, hTickIncrease = NS.getIncomingBaseInfo(
            hordeTimers,
            hordeBases,
            hordeIncBases,
            curMap.baseResources,
            curMap.tickRate,
            currentWinTicks
          )

          local newAllyScore = aScore + aScoreIncrease
          local newHordeScore = hScore + hScoreIncrease

          local newAllyBases = allyBases + aBaseIncrease
          local newHordeBases = hordeBases + hBaseIncrease

          local aFutureScore = newAllyScore
          local hFutureScore = newHordeScore

          local winTimeIncrease = 0

          if aTickIncrease ~= 0 or hTickIncrease ~= 0 then
            if aTickIncrease > hTickIncrease then
              local tickDifference = aTickIncrease - hTickIncrease
              local scoreDifference = hFutureScore
                + tickDifference * (curMap.tickRate * curMap.baseResources[newHordeBases])
              if scoreDifference < maxScore then
                hFutureScore = scoreDifference

                if aTickIncrease < currentWinTicks then
                  winTimeIncrease = aTickIncrease * curMap.tickRate
                end
              end
            elseif hTickIncrease > aTickIncrease then
              local tickDifference = hTickIncrease - aTickIncrease
              local scoreDifference = aFutureScore
                + tickDifference * (curMap.tickRate * curMap.baseResources[newAllyBases])
              if scoreDifference < maxScore then
                aFutureScore = scoreDifference

                if hTickIncrease < currentWinTicks then
                  winTimeIncrease = hTickIncrease * curMap.tickRate
                end
              end
            end
          end

          local allyFutureTicksToWin =
            NS.getWinTicks(maxScore, aFutureScore, curMap.tickRate, curMap.baseResources[newAllyBases])
          local allyFutureTimeToWin = NS.getWinTime(allyFutureTicksToWin, curMap.tickRate)

          local hordeFutureTicksToWin =
            NS.getWinTicks(maxScore, hFutureScore, curMap.tickRate, curMap.baseResources[newHordeBases])
          local hordeFutureTimeToWin = NS.getWinTime(hordeFutureTicksToWin, curMap.tickRate)

          local futureWinTicks = mmin(allyFutureTicksToWin, hordeFutureTicksToWin)
          local futureWinTime = mmin(allyFutureTimeToWin, hordeFutureTimeToWin)

          local winTicks = futureWinTicks
          winTime = futureWinTime + winTimeIncrease

          if allyFutureTicksToWin == hordeFutureTicksToWin then
            winText = "TIE"

            Banner:Start(getAdjustedWinTime(winTime, effectiveTickTime), winText)
            Bases:Stop(Bases, Bases.timerAnimationGroup)
            Score:Stop(Score)
            Flags:Stop(Flags)

            if NS.isEOTS(curMap.id) then
              Flags:SetAnchor(Banner.frame, 0, -5)
              self:GetFlagValue()
            else
              if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                NS.UpdateInfoSize(
                  NS.Info.frame,
                  NS.Banner,
                  { NS.Score, NS.Bases, NS.Flags },
                  "BasePrediction:BasePredictor"
                )
              end
            end

            prevAIncrease, prevHIncrease = -1, -1
            return
          else
            local aWins = allyFutureTicksToWin < hordeFutureTicksToWin

            local allyFutureIncrease = curMap.tickRate * curMap.baseResources[newAllyBases]
            local afs = aWins and maxScore or aFutureScore + (winTicks * allyFutureIncrease)
            local finalAScore = (allyBases == 0 and allyIncBases == 0) and aScore or afs

            local hordeFutureIncrease = curMap.tickRate * curMap.baseResources[newHordeBases]
            local hfs = aWins and hFutureScore + (winTicks * hordeFutureIncrease) or maxScore
            local finalHScore = (hordeBases == 0 and hordeIncBases == 0) and hScore or hfs

            -- local currentWinBases = aWins and allyBases or hordeBases
            local currentLoseBases = aWins and hordeBases or allyBases

            winBases = aWins and newAllyBases or newHordeBases
            loseBases = aWins and newHordeBases or newAllyBases
            winScore = aWins and aFutureScore or hFutureScore
            loseScore = aWins and hFutureScore or aFutureScore

            winName = aWins and NS.ALLIANCE_NAME or NS.HORDE_NAME
            loseName = aWins and NS.HORDE_NAME or NS.ALLIANCE_NAME
            winText = winName == NS.PLAYER_FACTION and "WIN" or "LOSE"

            Banner:Start(getAdjustedWinTime(winTime, effectiveTickTime), winText)
            Score:SetText(Score.text, finalAScore, finalHScore)

            local trueLoseBases = currentLoseBases == 0 and loseBases or currentLoseBases
            -- local trueLoseBases = currentLoseBases + 1 == winBases and loseBases or currentLoseBases

            NS.WIN_INC_BASE_COUNT = aWins and aBaseIncrease or hBaseIncrease

            winTable = {}
            for needBases = trueLoseBases + 1, curMap.maxBases do
              local table = NS.checkWinCondition(
                needBases,
                winBases,
                loseBases,
                winScore,
                loseScore,
                winName,
                loseName,
                winTime,
                winTicks,
                winTimeIncrease,
                curMap.maxBases,
                maxScore,
                currentWinTime,
                currentWinTicks,
                curMap.tickRate,
                curMap.baseResources,
                curMap.assaultTime,
                curMap.contestedTime
              )

              for a, b in pairs(table) do
                winTable[a] = b
              end

              local firstKey = next(winTable)
              if firstKey and winTable[firstKey] then
                -- Skip expired conditions unless it's the final (maxBases) condition.
                -- This ensures REFRESH transitions to the next base count instead of
                -- looping on the same expired condition 10x/sec.
                if winTable[firstKey].ownTime - GetTime() > 0 or needBases == curMap.maxBases then
                  break
                end
                NS.Debug("SKIP expired condition bases:", needBases, "ownTime:", winTable[firstKey].ownTime - GetTime())
                twipe(winTable)
              end
            end
          end
        end

        local firstKey = next(winTable)
        if firstKey and winTable[firstKey] then
          Bases:Start(getAdjustedWinTime(winTime, effectiveTickTime), winTable, BasePrediction)

          if NS.isEOTS(curMap.id) then
            Flags:SetAnchor(Bases.frame, 0, -5)
          end
        else
          if NS.isEOTS(curMap.id) then
            Flags:SetAnchor(Banner.frame, 0, -5)
          end
        end

        if NS.isEOTS(curMap.id) then
          self:GetFlagValue()
        else
          if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
            NS.UpdateInfoSize(
              NS.Info.frame,
              NS.Banner,
              { NS.Score, NS.Bases, NS.Flags },
              "BasePrediction:BasePredictor"
            )
          end
        end
      end
    end

    function BasePrediction:ScoreTracker(widgetID)
      -- widgetType == 3
      -- 2074 = DWG
      -- 1671 = AB, TBFG, EOTS
      -- 1689 = TOK
      if widgetID == 1671 or widgetID == 2074 then
        -- Arathi Basin, The Battle for Gilneas, Eye of the Storm, Deepwind Gorge
        local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)

        if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
          return
        end

        if prevTime == 0 then
          prevTime = GetTime()
          prevAScore = scoreInfo.leftBarValue
          prevHScore = scoreInfo.rightBarValue
          return
        end

        local t = GetTime()
        local elapsed = t - prevTime
        prevTime = t

        if elapsed > 0.5 then
          -- If there's only 1 update, it could be either alliance or horde, so we update both stats in this one
          minScore = scoreInfo.leftBarMin -- Min Bar
          maxScore = scoreInfo.leftBarMax -- Max Bar
          aScore = scoreInfo.leftBarValue -- Alliance Bar
          hScore = scoreInfo.rightBarValue -- Horde Bar
          aIncrease = aScore - prevAScore
          hIncrease = hScore - prevHScore
          prevAScore = aScore
          prevHScore = hScore
          -- Round to the closest time
          timeBetweenEachTick = elapsed % 1 >= 0.5 and mceil(elapsed) or mfloor(elapsed)
          -- NS.Debug("TICK elapsed:", elapsed, "rounded:", timeBetweenEachTick, "config:", curMap.tickRate, "aInc:", aIncrease, "hInc:", hIncrease)

          After(0.5, function()
            if
              aIncrease ~= prevAIncrease
              or hIncrease ~= prevHIncrease
              or timeBetweenEachTick ~= prevTick
              or allyBases ~= prevABases
              or hordeBases ~= prevHBases
              or allyIncBases ~= prevAIncBases
              or hordeIncBases ~= prevHIncBases
            then
              -- NS.Debug("START", aIncrease, hIncrease, "-----", aIncrease > 65, hIncrease > 65, "END")

              -- > 65 increase means captured a flag in EOTS
              -- 5 bases in AB/DWG blitz = 65 per tick
              if aIncrease > 65 or hIncrease > 65 then
                Interface:Clear()

                -- -- blitz eots flag cap no longer resets
                -- if NS.isEOTS(curMap.id) and NS.isBlitz() and aScore ~= maxScore and hScore ~= maxScore then
                --   Banner:Start(curMap.resetTime, "RESET")
                -- else
                --   prevAIncrease = -1
                --   prevHIncrease = -1
                -- end
                prevAIncrease = -1
                prevHIncrease = -1

                return
              end

              if
                NS.isBlitz()
                and (NS.isArathi(curMap.id) or NS.isDeepwind(curMap.id))
                and aIncrease == 0
                and hIncrease == 0
                and aScore ~= maxScore
                and hScore ~= maxScore
                and (aScore > 0 or hScore > 0)
              then
                Interface:Clear()

                NS.Debug("what happens here??")

                prevAIncrease = -1
                prevHIncrease = -1

                return
              end

              prevAIncrease = aIncrease
              prevHIncrease = hIncrease
              prevTick = timeBetweenEachTick

              BasePrediction:BasePredictor(nil, t)
            end
          end)
        else
          -- If elapsed < 0.5 then the event fired twice because both alliance and horde have bases.
          -- 1st update = alliance, 2nd update = horde
          -- If only one faction has bases, the event only fires once.
          -- Unfortunately we need to wait for the 2nd event to fire (the horde update) to know the true horde stats.
          -- In this one where we have 2 updates, we overwrite the horde stats from the 1st update.
          hScore = scoreInfo.rightBarValue -- Horde Bar
          hIncrease = hScore - prevHScore
          prevHScore = hScore
        end
      end
    end

    function BasePrediction:ObjectiveTracker(widgetID)
      -- widgetType == 14
      -- 2339 = DWG
      -- 1672 = EOTS
      -- 1645 = AB
      -- 1670 = TBFG
      -- 1683 = TOK
      if widgetID == 1645 or widgetID == 1670 or widgetID == 2339 then
        -- Arathi Basin, The Battle for Gilneas, Deepwind Gorge
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in ipairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            local str = v.state1Tooltip

            allyIncBases = allyIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if horde had the base, now they dont
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if fresh capture for alliance, or they once had it lose it fully then got it again
            if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
              allyTimers[base] = curMap.contestedTime + GetTime()
            end
          elseif v.iconState == Enum.IconState.ShowState2 then
            local str = v.state2Tooltip

            allyBases = allyBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in ipairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            local str = v.state1Tooltip

            hordeIncBases = hordeIncBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if alliance had the base, now they dont
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if fresh capture for horde, or they once had it lose it fully then got it again
            if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
              hordeTimers[base] = curMap.contestedTime + GetTime()
            end
          elseif v.iconState == Enum.IconState.ShowState2 then
            local str = v.state2Tooltip

            hordeBases = hordeBases + 1

            local base = smatch(str, "(.-) %-%s")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end

        local totalAllyBases = allyBases + allyIncBases
        local totalHordeBases = hordeBases + hordeIncBases
        NS.ACTIVE_BASE_COUNT = totalAllyBases + totalHordeBases
        NS.INCOMING_BASE_COUNT = allyIncBases + hordeIncBases
      elseif widgetID == 1672 then
        -- Eye of the Storm
        allyBases, allyIncBases = 0, 0
        hordeBases, hordeIncBases = 0, 0

        local baseInfo = GetDoubleStateIconRowVisualizationInfo(widgetID)

        if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
          return
        end

        for _, v in ipairs(baseInfo.leftIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            local str = v.state1Tooltip -- Alliance has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              allyIncBases = allyIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if horde had the base, now they dont
              if hordeTimers[base] then
                hordeTimers[base] = nil
              end
              -- if fresh capture for alliance, or they once had it lose it fully then got it again
              if allyTimers[base] == nil or (allyTimers[base] and allyTimers[base] - GetTime() <= 0) then
                allyTimers[base] = curMap.contestedTime + GetTime()
              end
            end
          elseif v.iconState == Enum.IconState.ShowState2 then
            local str = v.state2Tooltip -- Alliance has captured the Mage Tower

            allyBases = allyBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from horde mid-cap
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
            -- if alliance finished capping a base, now its theirs
            if allyTimers[base] then
              allyTimers[base] = nil
            end
          end
        end

        for _, v in ipairs(baseInfo.rightIcons) do
          if v.iconState == Enum.IconState.ShowState1 then
            local str = v.state1Tooltip -- Horde has assaulted the Mage Tower

            if sfind(str, "flag") == nil then
              hordeIncBases = hordeIncBases + 1

              local base = smatch(str, "assaulted the (.+)")
              -- if alliance had the base, now they dont
              if allyTimers[base] then
                allyTimers[base] = nil
              end
              -- if fresh capture for horde, or they once had it lose it fully then got it again
              if hordeTimers[base] == nil or (hordeTimers[base] and hordeTimers[base] - GetTime() <= 0) then
                hordeTimers[base] = curMap.contestedTime + GetTime()
              end
            end
          elseif v.iconState == Enum.IconState.ShowState2 then
            local str = v.state2Tooltip -- Horde has captured the Mage Tower

            hordeBases = hordeBases + 1

            local base = smatch(str, "captured the (.+)")
            -- if taking a base from alliance mid-cap
            if allyTimers[base] then
              allyTimers[base] = nil
            end
            -- if horde finished capping a base, now its theirs
            if hordeTimers[base] then
              hordeTimers[base] = nil
            end
          end
        end

        local totalAllyBases = allyBases + allyIncBases
        local totalHordeBases = hordeBases + hordeIncBases
        NS.ACTIVE_BASE_COUNT = totalAllyBases + totalHordeBases
        NS.INCOMING_BASE_COUNT = allyIncBases + hordeIncBases
      end

      if widgetID == 1645 or widgetID == 1670 or widgetID == 2339 or widgetID == 1672 then
        -- Arathi Basin, The Battle for Gilneas, Deepwind Gorge, Eye of the Storm
        if
          allyBases ~= prevABases
          or hordeBases ~= prevHBases
          or allyIncBases ~= prevAIncBases
          or hordeIncBases ~= prevHIncBases
        then
          prevABases = allyBases
          prevHBases = hordeBases
          prevAIncBases = allyIncBases
          prevHIncBases = hordeIncBases

          self:BasePredictor()
        end
      end
    end

    function BasePrediction:GetScoreByMapID(mapID)
      local widgetID = SCORE_WIDGET_IDS[mapID]
      if not widgetID then
        return
      end

      local scoreInfo = GetDoubleStatusBarWidgetVisualizationInfo(widgetID)
      if not scoreInfo or not scoreInfo.leftBarMax or not scoreInfo.rightBarMax then
        return
      end

      minScore = scoreInfo.leftBarMin -- Min Bar
      maxScore = scoreInfo.leftBarMax -- Max Bar
      aScore = scoreInfo.leftBarValue -- Alliance Bar
      hScore = scoreInfo.rightBarValue -- Horde Bar
    end

    function BasePrediction:GetObjectivesByMapID(mapID)
      local config = OBJECTIVE_CONFIG[mapID]
      if not config then
        return
      end

      local baseInfo = GetDoubleStateIconRowVisualizationInfo(config.widgetID)
      if not baseInfo or not baseInfo.leftIcons or not baseInfo.rightIcons then
        return
      end

      -- Reset counters
      allyBases, allyIncBases = 0, 0
      hordeBases, hordeIncBases = 0, 0
      if config.isEOTS then
        allyFlags = 0
        hordeFlags = 0
      end

      -- Process alliance icons (left side)
      local aBase, aInc, aFlag = processBaseIcons(baseInfo.leftIcons, config, true)
      allyBases, allyIncBases = aBase, aInc
      if config.isEOTS then
        allyFlags = aFlag
      end

      -- Process horde icons (right side)
      local hBase, hInc, hFlag = processBaseIcons(baseInfo.rightIcons, config, false)
      hordeBases, hordeIncBases = hBase, hInc
      if config.isEOTS then
        hordeFlags = hFlag
      end

      -- Update global counters
      local totalAllyBases = allyBases + allyIncBases
      local totalHordeBases = hordeBases + hordeIncBases
      NS.ACTIVE_BASE_COUNT = totalAllyBases + totalHordeBases
      NS.INCOMING_BASE_COUNT = allyIncBases + hordeIncBases
    end

    function BasePrediction:ARENA_OPPONENT_UPDATE()
      -- Re-read widget 1672 when arena tokens change so allyFlags/hordeFlags update immediately
      if NS.isEOTS(curMap.id) then
        self:FlagTracker(1672)
      end
    end

    function BasePrediction:UPDATE_UI_WIDGET(widgetInfo)
      if widgetInfo then
        local widgetID = widgetInfo.widgetID
        -- local widgetSetID = widgetInfo.widgetSetID
        -- local widgetType = widgetInfo.widgetType
        -- local unitToken = widgetInfo.unitToken
        -- local typeInfo = UIWidgetManager:GetWidgetTypeInfo(widgetType)
        -- local visInfo = typeInfo.visInfoDataFunction(widgetID)

        BasePrediction:ScoreTracker(widgetID)
        BasePrediction:ObjectiveTracker(widgetID)
        BasePrediction:FlagTracker(widgetID)
      end
    end

    function BasePrediction:StartInfoTracker(mapInfo)
      -- local
      prevTime, prevAScore, prevHScore, prevAIncrease, prevHIncrease = 0, 0, 0, 0, 0
      timeBetweenEachTick, prevTick, winTime = 0, 0, 0
      aScore, hScore, aIncrease, hIncrease = 0, 0, 0, 0
      prevABases, prevHBases, prevAIncBases, prevHIncBases = 0, 0, 0, 0
      -- global
      allyBases, allyIncBases = 0, 0
      hordeBases, hordeIncBases = 0, 0
      winBases, loseBases = 0, 0
      allyFlags, hordeFlags = 0, 0
      minScore, maxScore, winScore, loseScore = 0, 1500, 0, 0
      winName, loseName, winText = "", "", ""
      curMap = mapInfo

      twipe(allyTimers)
      twipe(hordeTimers)
      twipe(winTable)

      NS.ACTIVE_BASE_COUNT = 0
      NS.INCOMING_BASE_COUNT = 0
      NS.WIN_INC_BASE_COUNT = 0
      NS.BASE_TIMER_EXPIRED = false

      self:GetScoreByMapID(curMap.id)
      self:GetObjectivesByMapID(curMap.id)

      BaseFrame:RegisterEvent("UPDATE_UI_WIDGET")
      if NS.isEOTS(curMap.id) then
        BaseFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
      end
    end
  end
end

function BasePrediction:StopInfoTracker()
  BaseFrame:UnregisterEvent("UPDATE_UI_WIDGET")
  BaseFrame:UnregisterEvent("ARENA_OPPONENT_UPDATE")
end
