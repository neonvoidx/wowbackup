local _, private = ...

-- Specify the options.
local options = {
  name = "_SettingsPanel",
  displayedName = "",
  order = 44,
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
  for _, frame in pairs({
    SettingsPanel,
    PingSystemTutorial,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  self:SkinBorderOf(QuickKeybindFrame.BG, mainColor, desaturation)

  for _, texture in pairs({
    QuickKeybindFrame.Header.LeftBG,
    QuickKeybindFrame.Header.CenterBG,
    QuickKeybindFrame.Header.RightBG,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    SettingsPanel.Bg.TopSection,
    SettingsPanel.Bg.BottomEdge,
    PingSystemTutorialBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  for _, texture in pairs({
    SettingsPanel.Bg.BottomRight,
    SettingsPanel.Bg.BottomLeft
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    PingSystemTutorialInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, v in pairs({SettingsPanel:GetRegions()}) do
    if v:IsObjectType("Texture") then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end
  end

  -- Controls.
  for _, box in pairs({
    SettingsPanel.SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, scrollFrame in pairs({
    SettingsPanel.Container.SettingsList
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    SettingsPanel.GameTab,
    SettingsPanel.AddOnsTab,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
