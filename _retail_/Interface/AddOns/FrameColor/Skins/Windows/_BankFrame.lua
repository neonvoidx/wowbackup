local _, private = ...

-- Specify the options.
local options = {
  name = "_BankFrame",
  displayedName = "",
  order = 6,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.background,
    },
    ["borders"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.borders,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    ["tabs"] = {
      order = 5,
      name = "",
      rgbaValues = private.colors.default.tabs,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)

  self:HookFunc(BankPanelTabMixin, "RefreshVisuals", function(button)
    button.Border:SetDesaturation(1)
    button.Border:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
  end)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(BankFrame, mainColor, desaturation)

  -- Background.
  BankFrameBg:SetDesaturation(desaturation)
  BankFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Inset border frames
  for _, frame in pairs({
    BankSlotsFrame,
    ReagentBankFrame,
    BankPanel,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls
  self:SkinBox(BankItemSearchBox, controlsColor, desaturation)

  -- Tabs
  self:SkinTabs(BankFrame, tabsColor, desaturation)

  for _, v in pairs({BankPanel:GetChildren()}) do
    if type(v) == "table" and v.Border and v.Border:GetObjectType() == "Texture" then
      v.Border:SetDesaturation(desaturation)
      v.Border:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
    end
  end

  -- Container frames.
  for i=7, 13 do
    local frame = _G["ContainerFrame"..i]
    if frame then
      frame.Bg.TopSection:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
      frame.Bg.BottomEdge:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
      frame.Bg.BottomLeft:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
      frame.Bg.BottomRight:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4]) -- It is an invisible square with SetVertexColor.
      self:SkinNineSliced(frame, mainColor, desaturation)
    end
  end
end




