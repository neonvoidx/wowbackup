local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local sformat = string.format

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Info = NS.Info

local Flags = {}
NS.Flags = Flags

local FlagsFrame = CreateFrame("Frame", AddonName .. "FlagsFrame", Info.frame)
Flags.frame = FlagsFrame

local flagFormat = "%s by %d %s"
local flagFormat2 = "Flag Value: %d"

function Flags:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Flags:SetText(frame, faction, winName, flagsNeeded, flagValue, allyFlags, hordeFlags)
  local label = faction == winName and "Ahead" or "Behind"
  local noun = flagsNeeded == 1 and "flag" or "flags"
  local lineOne = sformat(flagFormat, label, flagsNeeded, noun)
  local lineTwo = sformat(flagFormat2, flagValue)
  local text = ""

  if NS.db.global.maps.eyeofthestorm.showflaginfo and NS.db.global.maps.eyeofthestorm.showflagvalue then
    if flagsNeeded == 0 then
      if
        (allyFlags > 0 and NS.PLAYER_FACTION == NS.ALLIANCE_NAME)
        or (hordeFlags > 0 and NS.PLAYER_FACTION == NS.HORDE_NAME)
      then
        text = lineTwo
      end
    else
      if
        (allyFlags > 0 and NS.PLAYER_FACTION == NS.ALLIANCE_NAME)
        or (hordeFlags > 0 and NS.PLAYER_FACTION == NS.HORDE_NAME)
      then
        text = lineOne .. "\n" .. lineTwo
      else
        text = lineOne
      end
    end
  elseif NS.db.global.maps.eyeofthestorm.showflaginfo then
    if flagsNeeded > 0 then
      text = lineOne
    end
  elseif NS.db.global.maps.eyeofthestorm.showflagvalue then
    if
      (allyFlags > 0 and NS.PLAYER_FACTION == NS.ALLIANCE_NAME)
      or (hordeFlags > 0 and NS.PLAYER_FACTION == NS.HORDE_NAME)
    then
      text = lineTwo
    end
  end

  frame.text:SetFormattedText(text)

  NS.UpdateSize(FlagsFrame, frame.text)

  if NS.db.global.general.banner then
    FlagsFrame:SetAlpha(0)
  elseif NS.db.global.maps.eyeofthestorm.showflaginfo or NS.db.global.maps.eyeofthestorm.showflagvalue then
    FlagsFrame:SetAlpha(1)
  end

  -- if NS.IN_GAME then
  --   if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
  --     NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, NS.Bases, Flags }, "Flags:SetText")
  --   end
  -- end
end

function Flags:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Flags:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(FlagsFrame, frame)
end

function Flags:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

function Flags:Stop(frame)
  frame.frame:SetAlpha(0)

  if frame.text then
    frame.text:SetFormattedText("")
  end
end

function Flags:Create(anchor)
  if not Flags.text then
    local Text = FlagsFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    FlagsFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    FlagsFrame:SetAlpha(0)

    -- local BG = FlagsFrame:CreateTexture(nil, "BACKGROUND")
    -- BG:SetAllPoints()
    -- BG:SetColorTexture(1, 0, 1, 1)

    Flags.text = Text

    Flags.name = "Flags"
  end
end
