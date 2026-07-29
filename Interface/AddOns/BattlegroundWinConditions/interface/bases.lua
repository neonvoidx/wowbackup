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

local showCapTimeAwareness = false

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

local function winMessage(text, winCondition)
  local winTime = winCondition.winTime - GetTime()
  -- local winTicks = mceil(winTime / winCondition.tickRate)
  local ownTime = winCondition.ownTime - GetTime()
  -- local ownTicks = mceil(ownTime / winCondition.tickRate)
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local winMinBases = winCondition.minBases
  local maxBases = winCondition.maxBases
  local maxWinMinBases = winMinBases - 1 <= 0 and 1 or winMinBases - 1
  local capBases = winCondition.bases
  local loseBases = winCondition.loseBases
  -- defensive init; overwritten before any read (luacheck W311)
  -- luacheck: ignore 311
  local message = ""

  if winMinBases == 1 and ownTime <= 0 then
    message = sformat("%s win\n", NS.formatTeamName(winName, NS.PLAYER_FACTION))
    Bases.isWin = true
  else
    if NS.WIN_INC_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and capBases == winMinBases + 1 then
      message = sformat("%s win with %d after cap\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
    else
      message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
    end

    if
      winMinBases == 1 and capBases == winMinBases + 1 and loseBases == 0
      or (NS.WIN_INC_BASE_COUNT > 0 and capBases == winMinBases + 1)
      or (NS.ACTIVE_BASE_COUNT < maxBases and winMinBases == 1 and capBases < maxBases)
      or (NS.INCOMING_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and loseBases == 0)
    then
      message = message
        .. sformat("%s can still win with %d\n", NS.formatTeamName(loseName, NS.PLAYER_FACTION), capBases)
    end

    if winMinBases == 1 then
      message = message .. sformat("Hold %d for %s to win\n", winMinBases, NS.formatTime(winTime))
    else
      message = message
        .. sformat("Hold %d for %s to win with %d\n", winMinBases, NS.formatTime(ownTime), maxWinMinBases)
    end
  end

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
  local ownTime = winCondition.ownTime - GetTime()
  local capTime = winCondition.capTime - GetTime()
  -- local capTicks = mceil(capTime / winCondition.tickRate)
  local capBases = winCondition.bases
  local maxBases = winCondition.maxBases
  local capScore = winCondition.capScore
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local message = ""

  if capBases == maxBases and ownTime <= 0 then
    message = sformat("%s lose\n", NS.formatTeamName(loseName, NS.PLAYER_FACTION))
  else
    message = message
      .. sformat(
        "%s need %d by %s\n",
        NS.formatTeamName(loseName, NS.PLAYER_FACTION),
        capBases,
        NS.formatScore(winName, capScore)
      )

    if showCapTimeAwareness then
      if capTime <= 0 then
        message = message .. sformat("Not enough cap time\n")
      else
        message = message .. sformat("Cap within %s\n", NS.formatTime(capTime))
      end
    else
      message = message .. sformat("Cap within %s\n", NS.formatTime(ownTime))
    end
  end

  Bases:SetText(text, "%s", message)
end

local function animationUpdate(frame, winTable, animationGroup, callbackFn)
  local t = GetTime()

  if t >= frame.exp then
    if animationGroup then
      animationGroup:Stop()
    end
    -- frame.text:Hide()
    return
  end

  local time = frame.exp - t
  frame.remaining = time

  local currentKey = next(winTable)
  if not currentKey or not winTable[currentKey] then
    return
  end

  local winCondition = winTable[currentKey]
  local ownTime = winCondition.ownTime - t
  local isFirstIteration = true

  -- Check up to 5 win conditions (max bases)
  for _ = 1, 5 do
    if ownTime > 0 or winCondition.bases == winCondition.maxBases then
      if winCondition.winName == NS.PLAYER_FACTION then
        winMessage(frame.text, winCondition)
      else
        loseMessage(frame.text, winCondition)
      end
      return
    end

    -- Special handling for first iteration when timer expires
    if isFirstIteration then
      isFirstIteration = false
      if NS.IN_GAME and NS.BASE_TIMER_EXPIRED == false then
        NS.BASE_TIMER_EXPIRED = true
        NS.Debug(
          "OWNTIME EXPIRED -> triggering REFRESH, ownTime was:",
          winCondition.ownTime - t,
          "winTime was:",
          winCondition.winTime - t,
          "bases:",
          winCondition.bases
        )
        if callbackFn then
          callbackFn:BasePredictor(true)
        end
        return
      end
    end

    -- Try next base count
    local nextKey = winCondition.bases + 1
    if not winTable[nextKey] then
      break
    end

    winCondition = winTable[nextKey]
    ownTime = winCondition.ownTime - t
  end

  NS.Debug("NO OPTIONS LEFT")
end

function Bases:Start(duration, winTable, callbackFn)
  self:Stop(self, self.timerAnimationGroup)

  self.remaining = mmin(mmax(0, duration), 1500)
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetFont(self.text)

  -- Reset current state only (wasWin intentionally keeps previous value for transition detection)
  self.isWin = false

  local firstKey = next(winTable)
  if firstKey and winTable[firstKey] then
    local winCondition = winTable[firstKey]

    if winCondition.winName == NS.PLAYER_FACTION then
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
