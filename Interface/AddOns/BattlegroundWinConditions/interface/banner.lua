local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime

local mmin = math.min
local mmax = math.max

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Banner = {}
NS.Banner = Banner

local BannerFrame = CreateFrame("Frame", AddonName .. "BannerFrame", UIParent)
Banner.frame = BannerFrame

function Banner:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOP", anchor, "BOTTOM", x, y)
end

function Banner:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
end

function Banner:SetBackgroundColor(frame, color)
  frame:SetColorTexture(color.r, color.g, color.b, color.a)
end

function Banner:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Banner:SetFont(frame)
  frame:SetFont(SharedMedia:Fetch("font", NS.db.global.general.bannergroup.bannerfont), 12, "")
end

function Banner:SetScale(frame)
  frame:SetScale(NS.db.global.general.bannergroup.bannerscale)
end

function Banner:ToggleAlpha()
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

function Banner:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local bannerformat = "GG YOU %s IN %s"
local bannerformatWin = "GG YOU %s"
local bannerformatReset = "RESET IN %s"
local bannerformatResetComplete = "RESET COMPLETE"
local function animationUpdate(frame, text, animationGroup)
  local t = GetTime()

  if t >= frame.exp then
    if text == "RESET" then
      Banner:SetText(frame.text, bannerformatResetComplete, text)
    else
      Banner:SetText(frame.text, bannerformatWin, text)
    end

    if animationGroup then
      animationGroup:Stop()
    end

  -- frame.text:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time

    if text == "RESET" then
      if time <= 0 then
        Banner:SetText(frame.text, bannerformatResetComplete)
      else
        Banner:SetText(frame.text, bannerformatReset, NS.formatTime(time))
      end
    else
      if time <= 0 then
        Banner:SetText(frame.text, bannerformatWin, text)
      else
        Banner:SetText(frame.text, bannerformat, text, NS.formatTime(time))
      end
    end

    -- frame.text:Show()
  end
end

function Banner:Start(duration, text)
  self:Stop(self, self.timerAnimationGroup)

  local BGColor
  local TextColor
  if text == "TIE" then
    BGColor = NS.db.global.general.bannergroup.tiebgcolor
    TextColor = NS.db.global.general.bannergroup.tietextcolor
  elseif text == "WIN" then
    BGColor = NS.db.global.general.bannergroup.winbgcolor
    TextColor = NS.db.global.general.bannergroup.wintextcolor
  elseif text == "RESET" then
    BGColor = NS.db.global.general.bannergroup.resetbgcolor
    TextColor = NS.db.global.general.bannergroup.resettextcolor
  else
    BGColor = NS.db.global.general.bannergroup.losebgcolor
    TextColor = NS.db.global.general.bannergroup.losetextcolor
  end

  self:SetBackgroundColor(self.bg, BGColor)
  self:SetTextColor(self.text, TextColor)
  self:SetFont(self.text)
  BannerFrame:SetWidth(175)
  BannerFrame:SetHeight(25)
  self:SetScale(BannerFrame)

  self.remaining = mmin(mmax(0, duration), 1500)
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  if text == "RESET" then
    if time <= 0 then
      self:SetText(self.text, bannerformatResetComplete)
    else
      self:SetText(self.text, bannerformatReset, NS.formatTime(time))
    end
  else
    if time <= 0 then
      self:SetText(self.text, bannerformatWin, text)
    else
      self:SetText(self.text, bannerformat, text, NS.formatTime(time))
    end
  end

  if NS.db.global.general.info == false then
    self.frame:SetAlpha(1)
  else
    self.frame:SetAlpha(0)
  end

  -- Store state for the pre-created callback
  self.currentText = text

  self.timerAnimationGroup:Play()
end

-- Pre-created callback to avoid garbage generation
local function bannerAnimationCallback(updatedGroup)
  if updatedGroup then
    animationUpdate(Banner, Banner.currentText, updatedGroup)
  end
end

function Banner:Create(anchor)
  if not Banner.text then
    local BG = BannerFrame:CreateTexture(nil, "BACKGROUND")
    BG:SetAllPoints()

    local Text = BannerFrame:CreateFontString(nil, "ARTWORK")
    self:SetFont(Text)
    Text:SetShadowOffset(1, -1)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("CENTER")
    Text:SetJustifyV("MIDDLE")
    Text:SetPoint("CENTER", BG, "CENTER", 0, 0)

    BannerFrame:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
    BannerFrame:SetSize(1, 1) -- Start with a minimal size

    -- BG:SetColorTexture(1, 0, 1, 1)

    Banner.bg = BG
    Banner.text = Text
    Banner.timerAnimationGroup = NS.CreateTimerAnimation(BannerFrame)
    Banner.timerAnimationGroup:SetScript("OnLoop", bannerAnimationCallback)
  end
end
