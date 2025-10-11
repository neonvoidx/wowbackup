local _, private = ...

-- Specify the options.
local options = {
  name = "_CollectionsJournal",
  displayedName = "",
  order = 12,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_Collections" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  for _, frame in pairs({
    CollectionsJournal,
    WardrobeFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Background.
  for _, texture in pairs({
    CollectionsJournalBg,
    WardrobeFrameBg
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    MountJournal.LeftInset,
    MountJournal.RightInset,
    MountJournal.BottomLeftInset,
    PetJournal.LeftInset,
    PetJournal.RightInset,
    PetJournalPetCardInset,
    ToyBox.iconsFrame,
    HeirloomsJournal.iconsFrame,
    WardrobeTransmogFrame.Inset,
    WardrobeCollectionFrame.ItemsCollectionFrame,
    WardrobeCollectionFrame.SetsTransmogFrame,
    WardrobeCollectionFrame.SetsCollectionFrame.RightInset,
    WardrobeCollectionFrame.SetsCollectionFrame.LeftInset,
    WarbandSceneJournal.IconsFrame,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    WardrobeCollectionFrame.progressBar.border,
    HeirloomsJournal.progressBar.border,
    ToyBox.progressBar.border,
    MountJournalSummonRandomFavoriteButtonBorder,
    PetJournalSummonRandomFavoritePetButtonBorder,
    PetJournalHealPetButtonBorder,
    MountJournal.ToggleDynamicFlightFlyoutButton.Border
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  for _, frame in pairs({
    PetJournal.PetCount,
    MountJournal.MountCount
  }) do
    self:SkinBorderOf(frame, bordersColor, desaturation)
  end

  -- Controls.
  for _, frame in pairs({
    MountJournal,
    PetJournal,
    WardrobeCollectionFrame.SetsCollectionFrame.ListContainer,
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end

  for _, box in pairs({
    WardrobeCollectionFrameSearchBox,
    HeirloomsJournalSearchBox,
    ToyBox.searchBox,
    PetJournalSearchBox,
    MountJournalSearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, texture in pairs({
    MountJournal.FilterDropdown.Background,
    PetJournal.FilterDropdown.Background,
    ToyBox.FilterDropdown.Background,
    HeirloomsJournal.FilterDropdown.Background,
    HeirloomsJournal.ClassDropdown.Background,
    WardrobeCollectionFrame.FilterButton.Background,
    WardrobeCollectionFrame.ClassDropdown.Background,
    WardrobeCollectionFrame.SetsCollectionFrame.DetailsFrame.VariantSetsDropdown.Background,
    WardrobeTransmogFrame.OutfitDropdown.Background,
    WardrobeCollectionFrame.ItemsCollectionFrame.WeaponDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs
  for _, tab in pairs({
    CollectionsJournalTab1,
    CollectionsJournalTab2,
    CollectionsJournalTab3,
    CollectionsJournalTab4,
    CollectionsJournalTab5,
    CollectionsJournalTab6,
    WardrobeCollectionFrameTab1,
    WardrobeCollectionFrameTab2,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
