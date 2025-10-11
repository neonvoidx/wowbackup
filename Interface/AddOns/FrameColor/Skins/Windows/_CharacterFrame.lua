local _, private = ...

-- Specify the options.
local options = {
  name = "_CharacterFrame",
  displayedName = "",
  order = 9,
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
      followClassColor = true,
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), self:GetColor("tabs"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    CharacterFrame,
    CurrencyTransferLog,
    CurrencyTransferMenu,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  for _, texture in pairs({
    CharacterStatsPane.ClassBackground,
    PaperDollInnerBorderTop,
    PaperDollInnerBorderTopRight,
    PaperDollInnerBorderRight,
    PaperDollInnerBorderBottom,
    PaperDollInnerBorderBottomRight,
    PaperDollInnerBorderBottomLeft,
    PaperDollInnerBorderLeft,
    PaperDollInnerBorderTopLeft,
    CharacterFrameInset.Bg,
    CharacterTrinket0SlotFrame,
    CharacterTrinket1SlotFrame,
    CharacterFinger0SlotFrame,
    CharacterFinger1SlotFrame,
    CharacterFeetSlotFrame,
    CharacterLegsSlotFrame,
    CharacterWaistSlotFrame,
    CharacterHandsSlotFrame,
    CharacterWristSlotFrame,
    CharacterSecondaryHandSlotFrame,
    CharacterMainHandSlotFrame,
    CharacterTabardSlotFrame,
    CharacterShirtSlotFrame,
    CharacterChestSlotFrame,
    CharacterBackSlotFrame,
    CharacterShoulderSlotFrame,
    CharacterNeckSlotFrame,
    CharacterHeadSlotFrame,
    CharacterFrame.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  self:SkinBorderOf(TokenFramePopup, mainColor, desaturation)

  -- Backgrounds.
  for _, texture in pairs({
    CharacterFrameBg,
    CurrencyTransferLogBg,
    CurrencyTransferMenuBg,
    CharacterFrameInset.Bg
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    CharacterFrameInset,
    CharacterFrameInsetRight,
    CurrencyTransferLogInset,
    CurrencyTransferMenuInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls.
  for _, frame in pairs({
    PaperDollFrame.TitleManagerPane,
    PaperDollFrame.EquipmentManagerPane,
    ReputationFrame,
    TokenFrame,
    CurrencyTransferLog,
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    ReputationFrame.filterDropdown.Background,
    TokenFrame.filterDropdown.Background,
    CurrencyTransferMenu.Content.SourceSelector.Dropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    CharacterFrameTab1,
    CharacterFrameTab2,
    CharacterFrameTab3,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
