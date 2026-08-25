local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime
local next = next

local mmin = math.min
local mmax = math.max
-- local mceil = math.ceil
local sformat = string.format

local Info = NS.Info

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Bases = {}
NS.Bases = Bases

local BasesFrame = CreateFrame("Frame", AddonName .. "BasesFrame", Info.frame)
Bases.frame = BasesFrame

-- Tracks win-locked state transitions for UI resize triggering
-- isWin: current state (true when win is locked in with 1 base and no time left)
-- wasWin: previous state (used to detect the moment of transition)
Bases.isWin = false
Bases.wasWin = false

function Bases:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Bases:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(BasesFrame, frame)
end

function Bases:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Bases:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(BasesFrame, frame)
end

function Bases:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  if animationGroup then
    animationGroup:Stop()
  end

  frame.frame:SetAlpha(0)

  if frame.text then
    frame.text:SetFormattedText("")
  end
end

function Bases:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local function blitzWinMessage(text, winCondition)
  local winTime = winCondition.winTime - GetTime()
  local ownTime = winCondition.ownTime - GetTime()
  local winName = winCondition.winName
  local winMinBases = winCondition.minBases
  local afterCapBases = winCondition.winBases
  local maxBases = winCondition.maxBases
  local capBases = winCondition.bases
  local message

  if winMinBases == 1 and ownTime <= 0 then
    message = ""
    Bases.isWin = true
  else
    if not NS.WILL_WIN and afterCapBases == 0 then
      message = sformat("%s are ahead right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION))
    elseif NS.WIN_INC_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and capBases == winMinBases + 1 then
      if NS.WILL_WIN then
        message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), afterCapBases)
      else
        message =
          sformat("%s are ahead with %d after cap\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), afterCapBases)
      end
    else
      if NS.WILL_WIN then
        message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), afterCapBases)
      else
        message =
          sformat("%s are ahead with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), afterCapBases)
      end
    end

    if NS.WILL_WIN then
      message = message .. sformat("Hold %d for %s to win\n", winMinBases, NS.formatTime(winTime))
    elseif afterCapBases > 0 then
      message = message .. "Hold what you have to stay ahead\n"
    end
  end

  Bases:SetText(text, "%s", message)

  if Bases.isWin ~= Bases.wasWin then
    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      if NS.IN_GAME then
        NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, Bases, NS.Flags }, "blitzWinMessage")
      else
        NS.UpdateInfoSize(
          NS.Info.frame,
          NS.Banner,
          { NS.Score, Bases, NS.Flags, NS.Orbs, NS.Stacks },
          "blitzWinMessage"
        )
      end
    end
    Bases.wasWin = Bases.isWin
  end
end

local function blitzLoseMessage(text, winCondition)
  local ownTime = winCondition.ownTime - GetTime()
  local capBases = winCondition.bases
  local maxBases = winCondition.maxBases
  local loseName = winCondition.loseName
  local message

  if NS.WILL_WIN or (capBases == maxBases and ownTime <= 0) then
    message = ""
  else
    message = sformat("%s need %d to get ahead", NS.formatTeamName(loseName, NS.PLAYER_FACTION), capBases)
  end

  Bases:SetText(text, "%s", message)
end

local function winMessage(text, winCondition)
  local ownTime = winCondition.ownTime + winCondition.driftTime - GetTime()
  local winName = winCondition.winName
  -- The minimum number of bases the projected winner needs to hold to still win
  -- against this hypothetical losing-team base count. When this is 1, the winner
  -- only needs 1 base to win from this projected state.
  local winMinBases = winCondition.minBases
  -- The map's total number of base nodes.
  local maxBases = winCondition.maxBases
  local maxWinMinBases = winMinBases - 1 <= 0 and 1 or winMinBases - 1
  -- The number of total bases the losing team would need to control to win again.
  local capBases = winCondition.bases
  local message

  -- NS.WIN_INC_BASE_COUNT = how many incoming bases the winning team is gaining (i.e. i just capped 1, so 1 would be the number).
  -- NS.ACTIVE_BASE_COUNT = how many bases are claimed by either team, including incoming bases.

  if NS.WIN_INC_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and capBases == winMinBases + 1 then
    message = sformat("%s win with %d after cap\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
  else
    message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
  end

  if winMinBases == 1 then
    message = message .. sformat("Hold %d to %s to win\n", winMinBases, NS.formatScore(winName, winCondition.ownScore))
  else
    message = message
      .. sformat(
        "Hold %d to %s to win with %d\n",
        winMinBases,
        NS.formatScore(winName, winCondition.ownScore),
        maxWinMinBases
      )
  end

  message = message .. sformat("Hold for ~%s\n", NS.formatWinTime(ownTime))

  Bases:SetText(text, "%s", message)

  if Bases.isWin ~= Bases.wasWin then
    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      if NS.IN_GAME then
        NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, Bases, NS.Flags }, "winMessage")
      else
        NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, Bases, NS.Flags, NS.Orbs, NS.Stacks }, "winMessage")
      end
    end
    Bases.wasWin = Bases.isWin
  end
end

local function loseMessage(text, winCondition)
  local capTime = winCondition.capTime + winCondition.driftTime - GetTime()
  local capBases = winCondition.bases
  local maxBases = winCondition.maxBases
  local capScore = winCondition.capScore
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local loseBases = winCondition.loseBases
  local winMinBases = winCondition.minBases

  local timing = NS.WIN_INC_BASE_COUNT > 0
      and NS.ACTIVE_BASE_COUNT == maxBases
      and capBases == winMinBases + 1
      and "after cap"
    or "right now"

  local message = ""
  if loseBases > 0 then
    message = sformat("%s lose with %d %s\n", NS.formatTeamName(loseName, NS.PLAYER_FACTION), loseBases, timing)
  end

  message = message
    .. sformat(
      "%s need %d by %s\n",
      NS.formatTeamName(loseName, NS.PLAYER_FACTION),
      capBases,
      NS.formatScore(winName, capScore)
    )

  if capTime <= 0 then
    message = message .. "Not enough cap time\n"
  else
    message = message .. sformat("Cap within ~%s\n", NS.formatWinTime(capTime))
  end

  Bases:SetText(text, "%s", message)
end

local function animationUpdate(frame, winTable, animationGroup, callbackFn)
  local t = GetTime()

  local currentKey = next(winTable)
  if not currentKey or not winTable[currentKey] then
    return
  end

  local winCondition = winTable[currentKey]

  local driftTime
  if NS.IN_GAME and (not NS.CUR_MAP or not NS.CUR_MAP.basesReset) then
    driftTime = winCondition.driftTime
  end

  if t >= frame.exp and driftTime == nil then
    if animationGroup then
      animationGroup:Stop()
    end
    -- frame.text:Hide()
    return
  end

  local time = frame.exp - t
  frame.remaining = time

  local ownTime = winCondition.ownTime + (driftTime or 0) - t

  -- Check up to 5 win conditions (max bases)
  for _ = 1, 5 do
    if driftTime ~= nil or ownTime > 0 or winCondition.bases == winCondition.maxBases then
      if NS.IN_GAME and NS.CUR_MAP and NS.CUR_MAP.basesReset then
        if winCondition.winName == NS.PLAYER_FACTION then
          blitzWinMessage(frame.text, winCondition)
        else
          blitzLoseMessage(frame.text, winCondition)
        end
      elseif winCondition.winName == NS.PLAYER_FACTION then
        winMessage(frame.text, winCondition)
      else
        loseMessage(frame.text, winCondition)
      end
      return
    end

    if NS.IN_GAME and NS.BASE_TIMER_EXPIRED == false then
      NS.BASE_TIMER_EXPIRED = true

      if callbackFn and NS.CUR_MAP and NS.CUR_MAP.basesReset then
        callbackFn:BasePredictor(true, nil)
        return
      end

      return
    end

    -- Try next base count
    local nextKey = winCondition.bases + 1
    if not winTable[nextKey] then
      break
    end

    winCondition = winTable[nextKey]

    driftTime = nil
    if NS.IN_GAME and (not NS.CUR_MAP or not NS.CUR_MAP.basesReset) then
      driftTime = winCondition.driftTime
    end

    ownTime = winCondition.ownTime + (driftTime or 0) - t
  end
end

function Bases:Start(duration, winTable, callbackFn)
  self:Stop(self, self.timerAnimationGroup)

  local minDuration = 0
  local maxDuration = 10000
  local map = NS.CUR_MAP

  if map and not map.basesReset and map.baseResources[1] then
    local maxTicks = NS.getWinTicks(map.maxScore, 0, map.tickRate, map.baseResources[1])
    maxDuration = NS.getWinTime(maxTicks, map.tickRate)
  end

  self.remaining = mmin(mmax(minDuration, duration), maxDuration)
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetFont(self.text)

  -- Reset current state only (wasWin intentionally keeps previous value for transition detection)
  self.isWin = false

  local firstKey = next(winTable)
  if firstKey and winTable[firstKey] then
    local winCondition = winTable[firstKey]

    if NS.IN_GAME and NS.CUR_MAP and NS.CUR_MAP.basesReset then
      if winCondition.winName == NS.PLAYER_FACTION then
        blitzWinMessage(self.text, winCondition)
      else
        blitzLoseMessage(self.text, winCondition)
      end
    elseif winCondition.winName == NS.PLAYER_FACTION then
      winMessage(self.text, winCondition)
    else
      loseMessage(self.text, winCondition)
    end

    if NS.db.global.general.banner == false then
      self.frame:SetAlpha(1)
    else
      self.frame:SetAlpha(0)
    end

    -- if NS.IN_GAME then
    --   if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
    --     NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, Bases, NS.Flags }, "Bases:Start")
    --   end
    -- end

    NS.BASE_TIMER_EXPIRED = false

    -- Store state for the pre-created callback
    self.currentWinTable = winTable
    self.currentCallbackFn = callbackFn

    self.timerAnimationGroup:Play()
  end
end

-- Pre-created callback to avoid garbage generation
local function basesAnimationCallback(updatedGroup)
  if updatedGroup then
    animationUpdate(Bases, Bases.currentWinTable, updatedGroup, Bases.currentCallbackFn)
  end
end

function Bases:Create(anchor)
  if not Bases.text then
    local Text = BasesFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    BasesFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -5)
    BasesFrame:SetAlpha(0)

    -- local BG = BasesFrame:CreateTexture(nil, "BACKGROUND")
    -- BG:SetAllPoints()
    -- BG:SetColorTexture(1, 0, 1, 1)

    Bases.text = Text
    Bases.timerAnimationGroup = NS.CreateTimerAnimation(BasesFrame)
    Bases.timerAnimationGroup:SetScript("OnLoop", basesAnimationCallback)

    Bases.name = "Bases"
  end
end
