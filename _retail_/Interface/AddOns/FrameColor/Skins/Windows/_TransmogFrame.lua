local _, private = ...

-- Specify the options.
local options = {
  name = "_TransmogFrame",
  displayedName = "",
  order = 52,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_Transmog" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
        self:HookScript(TransmogFrame.WardrobeCollection.TabContent.SituationsFrame.Situations.Background, "OnShow", "SkinSituationsDropdown")
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_Transmog") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(TransmogFrame, mainColor, desaturation)

  -- Backgrounds.
  for _, texture in pairs({
    TransmogFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, texture in pairs({
    TransmogFrame.WardrobeCollection.TabContent.Border,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, texture in pairs({
    TransmogFrame.WardrobeCollection.TabContent.ItemsFrame.SearchBox.Background,
    TransmogFrame.WardrobeCollection.TabContent.ItemsFrame.FilterButton.Background,
    TransmogFrame.WardrobeCollection.TabContent.SetsFrame.SearchBox.Background,
    TransmogFrame.WardrobeCollection.TabContent.SetsFrame.FilterButton.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, scrollFrame in pairs({
    TransmogFrame.OutfitCollection.OutfitList,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, child in pairs({ TransmogFrame.WardrobeCollection.TabContent.SituationsFrame.Situations:GetChildren() }) do
    if type(child) == "table" and child.Dropdown then
      local textue = child.Dropdown.Background
      textue:SetDesaturation(0)
      textue:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end
  end

  -- Tabs.
  for _, tab in pairs({ TransmogFrame.WardrobeCollection.TabHeaders:GetChildren() }) do
    for _, texture in pairs({
      tab.Left,
      tab.Middle,
      tab.Right,
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
    end
  end
end

function skin:SkinSituationsDropdown()
  local controlsColor = self:GetColor("controls")
  for _, child in pairs({ TransmogFrame.WardrobeCollection.TabContent.SituationsFrame.Situations:GetChildren() }) do
    if type(child) == "table" and child.Dropdown then
      local textue = child.Dropdown.Background
      textue:SetDesaturation(0)
      textue:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end
  end
end
