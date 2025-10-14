local _, private = ...

-- Specify the options.
local options = {
  name = "_ProfessionsFrame",
  displayedName = "",
  order = 39,
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

  local function handleSpecTabs()
    self:HookFunc(ProfessionsFrame, "UpdateTabs", skin.UpdateSpecTabs)
  end

  if C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
    handleSpecTabs()
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_Professions" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        handleSpecTabs()
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  for _, frame in pairs({
    ProfessionsFrame,
    ProfessionsFrame.CraftingPage.SchematicForm.QualityDialog,
    ProfessionsFrame.CraftingPage.CraftingOutputLog,
    ProfessionsFrame.OrdersPage.OrderView.CraftingOutputLog,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

    -- Bottom bar.
  for _, v in pairs({ProfessionsFrame.SpecPage.PanelFooter:GetRegions()}) do
    if v:IsObjectType("Texture") then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end

  -- Backgrounds.
  for _, texture in pairs({
    ProfessionsFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    ProfessionsFrame.CraftingPage.SchematicForm,
    ProfessionsFrame.OrdersPage.BrowseFrame.OrderList,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    -- Left Inset CraftingPage
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.TopEdge,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.BottomEdge,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.TopRightCorner,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.TopLeftCorner,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.RightEdge,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.LeftEdge,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.BottomRightCorner,
    ProfessionsFrame.CraftingPage.RecipeList.BackgroundNineSlice.BottomLeftCorner,
    -- Left Inset OrdersPage
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.TopEdge,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.BottomEdge,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.TopRightCorner,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.TopLeftCorner,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.RightEdge,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.LeftEdge,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.BottomRightCorner,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.BackgroundNineSlice.BottomLeftCorner,
    --
    ProfessionsFrame.OrdersPage.BrowseFrame.OrdersRemainingDisplay.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  for _, v in pairs({
    ProfessionsFrame.SpecPage.TopDivider:GetRegions(),
    ProfessionsFrame.SpecPage.VerticalDivider:GetRegions()
  }) do
    if v:IsObjectType("Texture") then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end

  -- Controls.
  for _, scrollFrame in pairs({
    ProfessionsFrame.CraftingPage.RecipeList,
    ProfessionsFrame.CraftingPage.CraftingOutputLog,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList,
    ProfessionsFrame.OrdersPage.BrowseFrame.OrderList,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, box in pairs({
    ProfessionsFrame.CraftingPage.RecipeList.SearchBox,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, texture in pairs({
    ProfessionsFrame.CraftingPage.RecipeList.FilterDropdown.Background,
    ProfessionsFrame.OrdersPage.BrowseFrame.RecipeList.FilterDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    ProfessionsFrame,
    ProfessionsFrame.OrdersPage.BrowseFrame.PublicOrdersButton,
    ProfessionsFrame.OrdersPage.BrowseFrame.NpcOrdersButton,
    ProfessionsFrame.OrdersPage.BrowseFrame.PersonalOrdersButton,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end

  self:UpdateSpecTabs(tabsColor)
end

-- Spec tabs are updated during profession load.
function skin:UpdateSpecTabs(tabsColor)
  local tabsColor = tabsColor or skin:GetColor("tabs")

  for _, v in pairs({ProfessionsFrame.SpecPage:GetChildren()}) do
    if type(v) == "table" and v.RightActive then
      for _, texture in pairs({
        v["Left"],
        v["Middle"],
        v["Right"],
      }) do
        texture:SetDesaturation(1)
        texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
      end
    end
  end
end
