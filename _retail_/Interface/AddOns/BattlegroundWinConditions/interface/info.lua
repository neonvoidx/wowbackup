local AddonName, NS = ...

local CreateFrame = CreateFrame

local Info = {}
NS.Info = Info

local InfoFrame = CreateFrame("Frame", AddonName .. "InfoFrame", UIParent)
Info.frame = InfoFrame

function Info:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Info:SetBackgroundColor(frame, color)
  frame:SetColorTexture(color.r, color.g, color.b, color.a)
end

function Info:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

function Info:Start()
  if NS.db.global.general.banner == false then
    self.frame:SetAlpha(1)
  else
    self.frame:SetAlpha(0)
  end
end

function Info:Create(anchor)
  if not Info.bg then
    local BG = InfoFrame:CreateTexture(nil, "BACKGROUND")
    BG:SetAllPoints()
    self:SetBackgroundColor(BG, NS.db.global.general.infogroup.infobgcolor)

    InfoFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    InfoFrame:SetSize(1, 1) -- Start with a minimal size

    if NS.db.global.general.infogroup.infobg then
      BG:SetAlpha(1)
    else
      BG:SetAlpha(0)
    end

    Info.bg = BG

    Info.name = "Info"
  end
end
