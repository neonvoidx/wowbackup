local _, private = ...

-- Specify the options.
local options = {
  name = "_MerchantFrame",
  displayedName = "",
  order = 34,
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), self:GetColor("tabs"),  1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(MerchantFrame, mainColor, desaturation)

  -- Backgrounds.
  for _, texture in pairs({
    MerchantFrameBg,
    MerchantMoneyInset.Bg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    MerchantFrameInset,
    MerchantMoneyInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    MerchantFrameBottomRightBorder,
    MerchantFrameBottomLeftBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  for _, texture in pairs({
    MerchantMoneyBgLeft,
    MerchantMoneyBgMiddle,
    MerchantMoneyBgRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, texture in pairs({
    MerchantFrame.FilterDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    MerchantFrameTab1,
    MerchantFrameTab2,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
