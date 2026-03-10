local _, private = ...

-- Specify the options.
local options = {
  name = "_CommunitiesFrame",
  displayedName = "",
  order = 14,
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
      rgbaValues = {1, 1, 1, 1},
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

  if C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, filligreeOverlayColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_Communities" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, filligreeOverlayColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, filligreeOverlayColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    CommunitiesFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  for _, frame in pairs({
    CommunitiesFrame.NotificationSettingsDialog.Selector,
    CommunitiesFrame.RecruitmentDialog.BG,
    CommunitiesFrame.GuildMemberDetailFrame,
    ClubFinderCommunityAndGuildFinderFrame.RequestToJoinFrame.BG,
    -- CommunitiesAddDialog.BG, appears to be protected.
    -- CommunitiesCreateDialog.BG, appears to be protected.
    "CommunitiesGuildNewsFiltersFrame",
    "CommunitiesGuildTextEditFrame",
  }) do
    self:SkinBorderOf(frame, mainColor, desaturation)
  end

  for _, texture in pairs({
    CommunitiesGuildLogFrameTopLeftCorner,
    CommunitiesGuildLogFrameTopBorder,
    CommunitiesGuildLogFrameTopRightCorner,
    CommunitiesGuildLogFrameRightBorder,
    CommunitiesGuildLogFrameBottomRightCorner,
    CommunitiesGuildLogFrameBottomBorder,
    CommunitiesGuildLogFrameBottomLeftCorner,
    CommunitiesGuildLogFrameLeftBorder,
    GuildControlUITopBorder,
    GuildControlUITopRightCorner,
    GuildControlUIRightBorder,
    GuildControlUIBottomRightCorner,
    GuildControlUIBottomBorder,
    GuildControlUIBottomLeftCorner,
    GuildControlUILeftBorder,
    GuildControlUITopLeftCorner,
    GuildControlUIHbarTopLeftCorner,
    GuildControlUIHbarBotLeftCorner,
    GuildControlUIHbarTopRightCorner,
    GuildControlUIHbarBotRightCorner,
    GuildControlUIHbarTopBorder,
    GuildControlUIHbarBottomBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Backgrounds.
  for _, texture in pairs({
    CommunitiesFrameBg,
    --CommunitiesFrame.TopTileStreaks, can't see a difference enabled or not.
    CommunitiesFrame.MemberList.ColumnDisplay.Background,
    -- CommunitiesFrame.MemberList.ColumnDisplay.TopTileStreaks, can't see a difference enabled or not.
    CommunitiesFrameCommunitiesList.Bg,
    GuildControlUITopBg,
    -- CommunitiesGuildLogFrameBg, can't be changed with SetVertexColor
    -- ClubFinderCommunityAndGuildFinderFrame.RequestToJoinFrame.BG.Bg, can't be changed with SetVertexColor
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    CommunitiesFrameInset,
    CommunitiesFrame.MemberList.InsetFrame,
    CommunitiesFrame.Chat.InsetFrame,
    CommunitiesFrameCommunitiesList.InsetFrame,
    ClubFinderCommunityAndGuildFinderFrame.InsetFrame,
    ClubFinderGuildFinderFrame.InsetFrame,
    CommunitiesGuildLogFrame.Container,
    CommunitiesGuildTextEditFrame.Container,
    CommunitiesFrame.GuildMemberDetailFrame.NoteBackground,
    CommunitiesFrame.GuildMemberDetailFrame.OfficerNoteBackground,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, frame in pairs({
    CommunitiesFrame.RecruitmentDialog.RecruitmentMessageFrame.RecruitmentMessageInput,
    ClubFinderCommunityAndGuildFinderFrame.RequestToJoinFrame.MessageFrame.MessageScroll,
  }) do
    self:SkinBorderOf(frame, bordersColor, desaturation)
  end

    -- The horizontal border textures.
  for _, v in pairs ({CommunitiesFrameGuildDetailsFrameInfo:GetRegions()}) do
    if v:IsObjectType("Texture") and v:GetDrawLayer() == "ARTWORK" then
      v:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
    end
  end

  for _, texture in pairs({
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderRight,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderLeft,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderLeft2,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderBottomLeft,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderBottomRight,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderTopLeft,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderTopLeft2,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderTopRight,
    CommunitiesFrame.GuildBenefitsFrame.InsetBorderBottomLeft2,
    CommunitiesFrameGuildDetailsFrame.InsetBorderRight,
    CommunitiesFrameGuildDetailsFrame.InsetBorderLeft,
    CommunitiesFrameGuildDetailsFrame.InsetBorderLeft2,
    CommunitiesFrameGuildDetailsFrame.InsetBorderBottomLeft,
    CommunitiesFrameGuildDetailsFrame.InsetBorderBottomRight,
    CommunitiesFrameGuildDetailsFrame.InsetBorderTopLeft,
    CommunitiesFrameGuildDetailsFrame.InsetBorderTopLeft2,
    CommunitiesFrameGuildDetailsFrame.InsetBorderTopRight,
    CommunitiesFrameGuildDetailsFrame.InsetBorderBottomLeft2,
    CommunitiesFrame.GuildBenefitsFrame.FactionFrame.Bar.Left,
    CommunitiesFrame.GuildBenefitsFrame.FactionFrame.Bar.Middle,
    CommunitiesFrame.GuildBenefitsFrame.FactionFrame.Bar.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    CommunitiesFrameCommunitiesList,
    CommunitiesFrame.Chat,
    CommunitiesFrame.MemberList,
    CommunitiesFrame.GuildBenefitsFrame.Rewards,
    CommunitiesFrameGuildDetailsFrameNews,
    CommunitiesGuildLogFrame.Container.ScrollFrame,
    ClubFinderCommunityAndGuildFinderFrame.CommunityCards,
    CommunitiesFrame.NotificationSettingsDialog.ScrollFrame,
    CommunitiesGuildTextEditFrame.Container.ScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    CommunitiesFrame.ChatEditBox.Left,
    CommunitiesFrame.ChatEditBox.Mid,
    CommunitiesFrame.ChatEditBox.Right,
    CommunitiesFrame.StreamDropdown.Background,
    CommunitiesFrame.GuildMemberListDropdown.Background,
    ClubFinderCommunityAndGuildFinderFrame.OptionsList.ClubFilterDropdown.Background,
    ClubFinderCommunityAndGuildFinderFrame.OptionsList.SortByDropdown.Background,
    ClubFinderGuildFinderFrame.OptionsList.ClubFilterDropdown.Background,
    ClubFinderGuildFinderFrame.OptionsList.ClubSizeDropdown.Background,
    CommunitiesFrame.NotificationSettingsDialog.CommunitiesListDropdown.Background,
    GuildControlUINavigationDropdown.Background,
    CommunitiesFrame.RecruitmentDialog.ClubFocusDropdown.Background,
    CommunitiesFrame.RecruitmentDialog.LookingForDropdown.Background,
    CommunitiesFrame.RecruitmentDialog.LanguageDropdown.Background,
    CommunitiesFrame.CommunitiesListDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    ClubFinderCommunityAndGuildFinderFrame.OptionsList.SearchBox,
    ClubFinderGuildFinderFrame.OptionsList.SearchBox,
    CommunitiesFrame.RecruitmentDialog.MinIlvlOnly.EditBox,
    --CommunitiesAddDialog.lnviteLinkBox, appears to be protected.
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  -- Tabs.
  for _,v in pairs ({
    CommunitiesFrame.ChatTab:GetRegions(),
    CommunitiesFrame.RosterTab:GetRegions(),
    CommunitiesFrame.GuildBenefitsTab:GetRegions(),
    CommunitiesFrame.GuildInfoTab:GetRegions(),
    ClubFinderCommunityAndGuildFinderFrame.ClubFinderSearchTab:GetRegions(),
    ClubFinderCommunityAndGuildFinderFrame.ClubFinderPendingTab:GetRegions(),
    ClubFinderGuildFinderFrame.ClubFinderSearchTab:GetRegions(),
    ClubFinderGuildFinderFrame.ClubFinderPendingTab:GetRegions(),
  }) do
    if v:GetDrawLayer() == "BORDER" then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
    end
  end

  -- Filligree Overlay.
  for _, texture in pairs({
    CommunitiesFrameCommunitiesList.TopFiligree,
    CommunitiesFrameCommunitiesList.BottomFiligree,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.TopBar,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.TLCorner,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.TRCorner,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.BottomBar,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.BLCorner,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.BRCorner,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.RightBar,
    CommunitiesFrameCommunitiesList.FilligreeOverlay.LeftBar,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(filligreeOverlayColor[1], filligreeOverlayColor[2], filligreeOverlayColor[3], filligreeOverlayColor[4])
  end
end
