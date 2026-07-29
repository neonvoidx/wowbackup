local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime
local ipairs = ipairs

local sformat = string.format

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Info = NS.Info

local Orbs = {}
NS.Orbs = Orbs

local OrbsFrame = CreateFrame("Frame", AddonName .. "OrbsFrame", Info.frame)
Orbs.frame = OrbsFrame

function Orbs:SetAnchor(anchor, x, y, pA, pB)
  local pointA = pA or "TOPLEFT"
  local pointB = pB or "BOTTOMLEFT"
  self.frame:SetPoint(pointA, anchor, pointB, x, y)
end

function Orbs:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  if self.orbTextFrame then
    NS.UpdateSize(self.orbTextFrame, self.orbText)
  end
  if self.buffTextFrame then
    NS.UpdateSize(self.buffTextFrame, self.buffText)
  end
  if self.frame and self.orbTextFrame and self.buffTextFrame then
    NS.UpdateContainerSize(self.frame)
  end
end

function Orbs:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Orbs:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  if self.orbTextFrame then
    NS.UpdateSize(self.orbTextFrame, self.orbText)
  end
  if self.buffTextFrame then
    NS.UpdateSize(self.buffTextFrame, self.buffText)
  end
  if self.frame and self.orbTextFrame and self.buffTextFrame then
    NS.UpdateContainerSize(self.frame)
  end
end

function Orbs:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

-- Define a table with orb colors and their respective color codes
local orbColors = {
  ["Blue"] = "|cFF01DFD7",
  ["Green"] = "|cFF01DF01",
  ["Orange"] = "|cFFFF8000",
  ["Purple"] = "|cFFBF00FF",
}
local orbNames = { "Blue", "Green", "Orange", "Purple" }

-- Function to format each orb entry based on its value
local function formatOrb(orbName, orbValue)
  local colorCode = orbColors[orbName]
  if orbValue == 0 then
    return sformat("%s%s|r orb is available\n", colorCode, orbName)
  else
    return sformat("%s%s|r orb has %d%%\n", colorCode, orbName, orbValue)
  end
end

function Orbs:StartOrbList(orbStacks)
  local orbList = ""

  if orbStacks then
    -- Iterate through each orb in the specified order and add to the list
    for _, orbName in ipairs(orbNames) do
      local orbValue = orbStacks[orbName] or 0 -- Get the value from orbStacks, default to 0 if not present
      orbList = orbList .. formatOrb(orbName, orbValue)
    end
  else
    orbList = orbList .. formatOrb("Blue", 0)
    orbList = orbList .. formatOrb("Green", 0)
    orbList = orbList .. formatOrb("Orange", 0)
    orbList = orbList .. formatOrb("Purple", 0)
  end

  self:SetText(self.orbText, "%s", orbList)
  self:SetFont(self.orbText)

  NS.UpdateSize(self.orbTextFrame, self.orbText)

  if NS.db.global.maps.templeofkotmogu.showorbinfo == false then
    self.orbTextFrame:SetAlpha(0)

    if NS.db.global.maps.templeofkotmogu.showbuffinfo == false then
      self.frame:SetAlpha(0)
    end
  else
    self.frame:SetAlpha(1)
    self.orbTextFrame:SetAlpha(1)
  end

  NS.UpdateContainerSize(self.frame)

  if NS.IN_GAME then
    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { Orbs }, "Orbs:StartOrbList")
    end
  end
end

local function stopAnimation(frame, animationGroup)
  if animationGroup then
    animationGroup:Stop()
  end

  if frame.buffTextFrame then
    frame.buffTextFrame:SetAlpha(0)
  end

  if frame.buffText then
    frame.buffText:SetFormattedText("")
  end
end

function Orbs:Stop(frame, animationGroup, everything)
  stopAnimation(frame, animationGroup)

  if everything then
    frame.frame:SetAlpha(0)

    if frame.orbText then
      frame.orbText:SetFormattedText("")
    end

    if NS.IN_GAME then
      Info.frame:SetSize(1, 1)
    end
  end
end

local orbsformat1 = "%s get 4x points in %s"
local orbsformat2 = "%s are earning 4x points"

local function animationUpdate(frame, text, animationGroup)
  local t = GetTime()
  if t >= frame.exp then
    if animationGroup then
      animationGroup:Stop()
    end

    Orbs:SetText(frame.buffText, orbsformat2, text)
    -- frame.buffText:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time
    Orbs:SetText(frame.buffText, orbsformat1, text, NS.formatTime(time))
    -- frame.buffText:Show()
  end
end

function Orbs:Start(duration, text)
  self:Stop(self, self.timerAnimationGroup)

  self.remaining = duration
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetText(self.buffText, orbsformat1, text, NS.formatTime(time))
  self:SetFont(self.buffText)

  NS.UpdateSize(self.buffTextFrame, self.buffText)

  if NS.db.global.maps.templeofkotmogu.showbuffinfo == false then
    if NS.db.global.maps.templeofkotmogu.showorbinfo == false then
      self.frame:SetAlpha(0)
    end
  else
    self.frame:SetAlpha(1)
    self.buffTextFrame:SetAlpha(1)
  end

  NS.UpdateContainerSize(self.frame)

  if NS.IN_GAME then
    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { Orbs }, "Orbs:Start")
    end
  end

  -- Store state for the pre-created callback
  self.currentText = text

  self.timerAnimationGroup:Play()
end

-- Pre-created callback to avoid garbage generation
local function orbsAnimationCallback(updatedGroup)
  if updatedGroup then
    animationUpdate(Orbs, Orbs.currentText, updatedGroup)
  end
end

function Orbs:Create(anchor)
  if not Orbs.orbTextFrame then
    OrbsFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    OrbsFrame:SetWidth(1)
    OrbsFrame:SetHeight(1)
    OrbsFrame:SetAlpha(0)

    local OrbTextFrame = CreateFrame("Frame", AddonName .. "OrbsFrameGroupFrame", OrbsFrame)
    OrbTextFrame:SetPoint("TOPLEFT", OrbsFrame, "TOPLEFT", 0, 0)
    if NS.db.global.maps.templeofkotmogu.showorbinfo then
      OrbTextFrame:SetAlpha(1)
    else
      OrbTextFrame:SetAlpha(0)
    end

    local OrbText = OrbTextFrame:CreateFontString(nil, "ARTWORK")
    OrbText:SetAllPoints()
    self:SetFont(OrbText)
    self:SetTextColor(OrbText, NS.db.global.general.infogroup.infotextcolor)
    OrbText:SetShadowOffset(0, 0)
    OrbText:SetShadowColor(0, 0, 0, 1)
    OrbText:SetJustifyH("LEFT")
    OrbText:SetJustifyV("TOP")

    local BuffTextFrame = CreateFrame("Frame", AddonName .. "OrbsFrameGroupFrame", OrbsFrame)
    if NS.db.global.maps.templeofkotmogu.showorbinfo then
      BuffTextFrame:SetPoint("TOPLEFT", OrbTextFrame, "BOTTOMLEFT", 0, -5)
    else
      BuffTextFrame:SetPoint("TOPLEFT", OrbsFrame, "TOPLEFT", 0, 0)
    end

    if NS.db.global.maps.templeofkotmogu.showbuffinfo then
      BuffTextFrame:SetAlpha(1)
    else
      BuffTextFrame:SetAlpha(0)
    end

    local BuffText = BuffTextFrame:CreateFontString(nil, "ARTWORK")
    BuffText:SetAllPoints()
    self:SetFont(BuffText)
    self:SetTextColor(BuffText, NS.db.global.general.infogroup.infotextcolor)
    BuffText:SetShadowOffset(0, 0)
    BuffText:SetShadowColor(0, 0, 0, 1)
    BuffText:SetJustifyH("LEFT")
    BuffText:SetJustifyV("TOP")

    -- local BG = OrbsFrame:CreateTexture(nil, "BACKGROUND")
    -- BG:SetAllPoints()
    -- BG:SetColorTexture(1, 0, 1, 1)

    Orbs.orbTextFrame = OrbTextFrame
    Orbs.buffTextFrame = BuffTextFrame
    Orbs.orbText = OrbText
    Orbs.buffText = BuffText
    Orbs.timerAnimationGroup = NS.CreateTimerAnimation(OrbsFrame)
    Orbs.timerAnimationGroup:SetScript("OnLoop", orbsAnimationCallback)

    Orbs.name = "Orbs"
  end
end
