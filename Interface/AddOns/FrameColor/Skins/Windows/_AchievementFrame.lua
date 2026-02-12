local _, private = ...

-- Specify the options.
local options = {
  name = "_AchievementFrame",
  displayedName = "",
  order = 1,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["controls"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    ["tabs"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.tabs,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  if C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI") then
    self:Apply(mainColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_AchievementUI" then
        self:Apply(mainColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, 0)
  end
end

function skin:Apply(mainColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(AchievementFrameCategories, mainColor, desaturation)

  for _, texture in pairs({
    AchievementFrameMetalBorderRight,
    AchievementFrameMetalBorderBottomRight,
    AchievementFrameMetalBorderBottom,
    AchievementFrameMetalBorderBottomLeft,
    AchievementFrameMetalBorderLeft,
    AchievementFrameMetalBorderTopLeft,
    AchievementFrameMetalBorderTop,
    AchievementFrameMetalBorderTopRight,
    AchievementFrame.Header.Left,
    AchievementFrame.Header.Right,
    AchievementFrameCategoriesBG,
    AchievementFrame.Header.PointBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    AchievementFrameTab1,
    AchievementFrameTab2,
    AchievementFrameTab3,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end

  -- ScrollBars
  for _, scrollFrame in pairs({
    AchievementFrameCategories,
    AchievementFrameAchievements,
    AchievementFrameStats,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, box in pairs({
    AchievementFrame.SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, texture in pairs({
    AchievementFrameFilterDropdown.Background,
    AchievementFrameSummaryCategoriesStatusBarLeft,
    AchievementFrameSummaryCategoriesStatusBarMiddle,
    AchievementFrameSummaryCategoriesStatusBarRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for i=1, 11 do
    for _, region in pairs({
      "Left",
      "Middle",
      "Right",
    }) do
      local texture = _G["AchievementFrameSummaryCategoriesCategory" .. i .. region]
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end
  end
end
