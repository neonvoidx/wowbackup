local _, private = ...

-- Specify the options.
local options = {
  name = "_WorldMapFrame",
  displayedName = "",
  order = 47,
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
  self:SkinNineSliced(WorldMapFrame.BorderFrame, mainColor, desaturation)

  for _, v in pairs({ QuestMapFrame.QuestsFrame.DetailsFrame.ShareButton:GetRegions() }) do
    if v:IsObjectType("Texture") and v:GetDebugName():match("%d") then -- Unnamed textures left and right to the share button.
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end

  -- Background.
  for _, texture in pairs({
    WorldMapFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, texture in pairs({ WorldMapFrame.NavBar:GetRegions() }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

    -- Navigationbar overlay texture.
  for _, texture in pairs({ WorldMapFrame.NavBar.overlay:GetRegions() }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    QuestScrollFrame,
    QuestMapFrame.EventsFrame,
    MapLegendScrollFrame,
    QuestMapDetailsScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  self:SkinBox(QuestScrollFrame.SearchBox, controlsColor, desaturation)

  -- Tabs.
  for _, texture in pairs({
    QuestMapFrame.QuestsTab.Background,
    QuestMapFrame.EventsTab.Background,
    QuestMapFrame.MapLegendTab.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
  end
end
