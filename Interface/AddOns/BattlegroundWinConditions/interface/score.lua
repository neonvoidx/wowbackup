local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Info = NS.Info

local Score = {}
NS.Score = Score

local ScoreFrame = CreateFrame("Frame", AddonName .. "ScoreFrame", Info.frame)
Score.frame = ScoreFrame

local scoreformat = "Final Score: %s - %s"

function Score:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, y)
  self.frame:SetParent(Info.frame)
end

function Score:SetText(frame, aScore, hScore)
  local aScoreFormatted = NS.formatScore(NS.ALLIANCE_NAME, aScore)
  local hScoreFormatted = NS.formatScore(NS.HORDE_NAME, hScore)

  frame:SetFormattedText(scoreformat, aScoreFormatted, hScoreFormatted)
  NS.UpdateSize(ScoreFrame, frame)

  if NS.db.global.general.banner == false then
    ScoreFrame:SetAlpha(1)
  else
    ScoreFrame:SetAlpha(0)
  end
end

function Score:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Score:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(ScoreFrame, frame)
end

function Score:ToggleAlpha()
  local curAlpha = ScoreFrame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  ScoreFrame:SetAlpha(newAlpha)
end

function Score:Stop(frame)
  frame.frame:SetAlpha(0)

  if frame.text then
    frame.text:SetFormattedText("")
  end
end

function Score:Create(anchor)
  if not Score.text then
    local Text = ScoreFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    ScoreFrame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -5)
    ScoreFrame:SetParent(Info.frame)
    ScoreFrame:SetAlpha(0)

    -- local BG = ScoreFrame:CreateTexture(nil, "BACKGROUND")
    -- BG:SetAllPoints()
    -- BG:SetColorTexture(1, 0, 1, 1)

    Score.text = Text

    Score.name = "Score"
  end
end
