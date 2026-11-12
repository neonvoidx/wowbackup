local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local IsInInstance = IsInInstance
local issecretvalue = issecretvalue or function(_)
  return false
end

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local Anchor = {}
NS.Anchor = Anchor

local function CanInteractWithFrame(frame)
  if not frame or not frame.IsVisible or not frame:IsVisible() then
    return false
  end
  local alpha = frame:GetAlpha()
  return (not issecretvalue(alpha)) and alpha ~= 0
end

local AnchorFrame = CreateFrame("Frame", AddonName .. "AnchorFrame", UIParent)
Anchor.frame = AnchorFrame

function Anchor:SetAnchor()
  AnchorFrame:SetPoint(
    NS.db.global.position[1],
    UIParent,
    NS.db.global.position[2],
    NS.db.global.position[3],
    NS.db.global.position[4]
  )
end

function Anchor:MakeUnmovable(frame)
  frame:SetMovable(false)
  frame:RegisterForDrag()
  frame:SetScript("OnDragStart", nil)
  frame:SetScript("OnDragStop", nil)
end

function Anchor:MakeUnhoverable()
  AnchorFrame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  AnchorFrame:SetScript("OnLeave", function(f)
    f:SetAlpha(1)
  end)
end

function Anchor:MakeHoverable()
  AnchorFrame:SetScript("OnEnter", function(f)
    f:SetAlpha(1)
  end)
  AnchorFrame:SetScript("OnLeave", function(f)
    f:SetAlpha(0)
  end)
end

function Anchor:MakeMoveable(frame)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f)
    if NS.db.global.general.lock == false and CanInteractWithFrame(frame) then
      f:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(f)
    if NS.db.global.general.lock == false and CanInteractWithFrame(frame) then
      f:StopMovingOrSizing()
      local a, _, b, c, d = f:GetPoint()
      NS.db.global.position[1] = a
      NS.db.global.position[2] = b
      NS.db.global.position[3] = c
      NS.db.global.position[4] = d
    end
  end)
end

function Anchor:ToggleShow(show)
  if show then
    AnchorFrame:Show()
  else
    AnchorFrame:Hide()
  end
end

function Anchor:RemoveControls(frame)
  frame:EnableMouse(false)
  frame:SetScript("OnMouseUp", nil)
end

function Anchor:AddControls(frame)
  frame:EnableMouse(true)
  frame:SetScript("OnMouseUp", function(_, _)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function(_, btn)
      if NS.db.global.general.lock == false and not IsInInstance() and frame:IsVisible() and frame:GetAlpha() ~= 0 then
        if btn == "RightButton" then
          AceConfigDialog:Open(AddonName)
        end
      end
    end)
  end)
end

function Anchor:Lock(frame)
  self:RemoveControls(frame)
  self:MakeUnmovable(frame)
  self:ToggleShow(false)
end

function Anchor:Unlock(frame)
  self:AddControls(frame)
  self:MakeMoveable(frame)
  self:ToggleShow(true)
end

function Anchor:Create()
  if not Anchor.header then
    local bg = AnchorFrame:CreateTexture()
    bg:SetAllPoints(AnchorFrame)
    bg:SetColorTexture(0, 1, 0, 0.2)

    local header = AnchorFrame:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    header:SetAllPoints(AnchorFrame)
    header:SetFormattedText("anchor")
    header:SetJustifyH("CENTER")
    header:SetJustifyV("MIDDLE")
    header:SetPoint("CENTER", bg, "CENTER", 0, 0)

    Anchor:SetAnchor()
    AnchorFrame:SetWidth(175)
    AnchorFrame:SetHeight(15)
    AnchorFrame:SetClampedToScreen(true)

    if NS.db.global.general.lock then
      self:Lock(AnchorFrame)
    else
      self:Unlock(AnchorFrame)
    end

    Anchor.header = header
  end
end
