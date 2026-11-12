local _, private = ...

-- Specify the options.
local options = {
  name = "_CooldownViewerSettings",
  displayedName = "",
  order = 49,
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), self:GetColor("tabs"),  1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(CooldownViewerSettings, mainColor, desaturation)

  -- Backgrounds.
  for _, texture in pairs({
    CooldownViewerSettingsBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    CooldownViewerSettingsInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls.
  self:SkinBox(CooldownViewerSettings.SearchBox, controlsColor, desaturation)
  self:SkinScrollBarOf(CooldownViewerSettings.CooldownScroll, controlsColor, desaturation)

  -- Side-Tabs.
  for _, texture in pairs({
    CooldownViewerSettings.SpellsTab.Background,
    CooldownViewerSettings.AurasTab.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
  end
end
