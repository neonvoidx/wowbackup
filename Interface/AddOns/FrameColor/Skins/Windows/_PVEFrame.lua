local _, private = ...

-- Specify the options.
local options = {
  name = "_PVEFrame",
  displayedName = "",
  order = 40,
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
    ["filligree_overlay"] = {
      order = 6,
      name = "",
      rgbaValues = {0, 0, 0, 1},
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
  local filligreeOverlayColor = self:GetColor("filligree_overlay")

  -- PVE
  self:ApplyPVE(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, filligreeOverlayColor, 1)

  -- PVP
  if C_AddOns.IsAddOnLoaded("Blizzard_PVPUI") then
    self:ApplyPVP(bordersColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_PVPUI" then
        self:ApplyPVP(bordersColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end

  -- Challenges
  if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
    self:ApplyChallnges(bordersColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_ChallengesUI" then
        self:ApplyChallnges(bordersColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}

  -- PVE
  self:ApplyPVE(color, color, color, color, color, color, 0)

  -- PVP
  if C_AddOns.IsAddOnLoaded("Blizzard_PVPUI") then
    self:ApplyPVP(color, color, 0)
  end

  -- Challenges
  if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
    self:ApplyChallnges(color, 0)
  end
end

function skin:ApplyPVE(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, filligreeOverlayColor, desaturation)
  -- Main frame.
  for _, frame in pairs({
    PVEFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  for _, v in pairs({
    LFGListApplicationDialog,
    LFGListFrame.SearchPanel.AutoCompleteFrame,
  }) do
    self:SkinBorderOf(v, mainColor, desaturation)
  end

  -- Backgrounds.
  for _, texture in pairs({
    PVEFrameBg,
    PVEFrameLeftInset.Bg,
    PVEFrame.TopTileStreaks,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    PVEFrameLeftInset,
    LFDParentFrameInset,
    RaidFinderFrameRoleInset,
    RaidFinderFrameBottomInset,
    LFGListFrame.CategorySelection.Inset,
    LFGListFrame.SearchPanel.ResultsInset,
    LFGListFrame.EntryCreation.Inset,
    LFGListFrame.ApplicationViewer.Inset
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    LFDParentFrameRoleBackground,
    PVEFrameBRCorner,
    PVEFrameTRCorner,
    PVEFrameBLCorner,
    PVEFrameTLCorner,
    PVEFrameBottomLine,
    PVEFrameLLVert,
    PVEFrameRLVert,
    PVEFrameTopLine,
    LFGListFrame.ApplicationViewer.InfoBackground,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  if desaturation == 1 then
    RaidFinderFrameRoleBackground:Hide()
  else
    RaidFinderFrameRoleBackground:Show()
  end

  for _, v in pairs({
    LFGListApplicationDialogDescription,
    LFGListCreationDescription,
  }) do
    self:SkinBorderOf(v, bordersColor, desaturation)
  end

  -- Controls.
  for _, texture in pairs({
    LFDQueueFrameTypeDropdown.Background,
    RaidFinderQueueFrameSelectionDropdown.Background,
    LFGListFrame.SearchPanel.FilterButton.Background,
    LFGListEntryCreationGroupDropdown.Background,
    LFGListEntryCreationActivityDropdown.Background,
    LFGListEntryCreationPlayStyleDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    LFGListFrame.SearchPanel.SearchBox,
    LFGListFrame.EntryCreation.Name,
    LFGListFrame.EntryCreation.ItemLevel.EditBox,
    LFGListFrame.EntryCreation.VoiceChat.EditBox,
    LFGListFrame.EntryCreation.MythicPlusRating.EditBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, scrollFrame in pairs({
    LFGListFrame.SearchPanel,
    LFGListFrame.ApplicationViewer
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    PVEFrameTab1,
    PVEFrameTab2,
    PVEFrameTab3,
    PVEFrameTab4
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end

  -- Filligree Overlay.
  for _, texture in pairs({
    PVEFrameTopFiligree,
    PVEFrameBottomFiligree,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(filligreeOverlayColor[1], filligreeOverlayColor[2], filligreeOverlayColor[3], filligreeOverlayColor[4])
  end
end

function skin:ApplyPVP(bordersColor, controlsColor, desaturation)
  -- Borders.
  for _, frame in pairs({
    HonorFrame.Inset,
    ConquestFrame.Inset,
    PVPQueueFrame.HonorInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls.
  for _, texture in pairs({
    HonorFrameTypeDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    LFGListFrame.EntryCreation.PVPRating.EditBox,
    LFGListFrame.EntryCreation.PvpItemLevel.EditBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end
end

function skin:ApplyChallnges(bordersColor, desaturation)
  -- Border.
  self:SkinNineSliced(ChallengesFrameInset, bordersColor, desaturation)
end
