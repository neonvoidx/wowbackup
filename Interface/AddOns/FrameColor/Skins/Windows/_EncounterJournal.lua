local _, private = ...

-- Specify the options.
local options = {
  name = "_EncounterJournal",
  displayedName = "",
  order = 19,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_EncounterJournal" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(EncounterJournal, mainColor, desaturation)

  -- Background.
  for _, texture in pairs({
    EncounterJournalBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    EncounterJournalInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    EncounterJournalNavBarInsetBottomBorder,
    EncounterJournalNavBarInsetRightBorder,
    EncounterJournalNavBarInsetLeftBorder,
    EncounterJournalNavBarInsetBotRightCorner,
    EncounterJournalNavBarInsetBotLeftCorner,
    EncounterJournalMonthlyActivitiesFrame.Divider,
    EncounterJournalMonthlyActivitiesFrame.DividerVertical,
    EncounterJournalMonthlyActivitiesFrame.FilterList.Bg -- No mistake, this is a fake border.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

    -- Navigationbar overlay texture.
  for _, texture in pairs({ EncounterJournalNavBar.overlay:GetRegions() }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    EncounterJournalMonthlyActivitiesFrame,
    EncounterJournalMonthlyActivitiesFrame.FilterList,
    EncounterJournalInstanceSelect,
    EncounterJournal.LootJournalItems.ItemSetsFrame,
    EncounterJournalEncounterFrameInfo.LootContainer,
    EncounterJournalEncounterFrameInfoDetailsScrollFrame,
    EncounterJournalEncounterFrameInfoOverviewScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

    -- differs from the default.
  for _, texture in pairs({
    EncounterJournalEncounterFrameInfo.BossesScrollBar.Track.Thumb.Begin,
    EncounterJournalEncounterFrameInfo.BossesScrollBar.Track.Thumb.Middle,
    EncounterJournalEncounterFrameInfo.BossesScrollBar.Track.Thumb.End,
    EncounterJournalEncounterFrameInfo.BossesScrollBar.Back.Texture,
    EncounterJournalEncounterFrameInfo.BossesScrollBar.Forward.Texture,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, texture in pairs({
    EncounterJournalEncounterFrameInfoDifficulty.Background,
    EncounterJournalEncounterFrameInfo.LootContainer.slotFilter.Background,
    EncounterJournalEncounterFrameInfo.LootContainer.filter.Background,
    EncounterJournalInstanceSelect.ExpansionDropdown.Background,
    EncounterJournal.LootJournalItems.ItemSetsFrame.ClassDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    EncounterJournalSearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    EncounterJournalDungeonTab,
    EncounterJournalRaidTab,
    EncounterJournalSuggestTab,
    EncounterJournalLootJournalTab,
    EncounterJournalMonthlyActivitiesTab,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
