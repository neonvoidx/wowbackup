local _, private = ...

-- Specify the options.
local options = {
  name = "_FriendsFrame",
  displayedName = "",
  order = 22,
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
  toggles = {
    ["update_bg_to_online_status"] = {
      order = 1,
      name = "",
      isChecked = true,
    }
  }
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), self:GetColor("tabs"), 1)

  if self:GetToggleState("update_bg_to_online_status") then
    self:RegisterForEvent("BN_INFO_CHANGED", self.UpdateBgToOnlineStatus)
    self:UpdateBgToOnlineStatus()
  end
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frames.
  self:SkinNineSliced(FriendsFrame, mainColor, desaturation)

  for _, frame in pairs({
    FriendsFrameBattlenetFrame.BroadcastFrame,
    RecruitAFriendRewardsFrame,
    RaidInfoFrame.Border,
  }) do
    self:SkinBorderOf(frame, mainColor, desaturation)
  end

  for _, texture in pairs({
    RaidInfoFrame.Header.LeftBG,
    RaidInfoFrame.Header.CenterBG,
    RaidInfoFrame.Header.RightBG,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    FriendsFrameBg,
    RaidInfoDetailHeader,
    RaidInfoDetailFooter,
    RecruitAFriendFrame.RecruitList.Header.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    FriendsFrameInset,
    WhoFrameListInset,
    WhoFrameEditBoxInset,
    RecruitAFriendFrame.RecruitList.ScrollFrameInset,
    RecruitAFriendFrame.RewardClaiming.Inset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  self:SkinBorderOf(FriendsFrameBattlenetFrame.BroadcastFrame.EditBox, bordersColor, desaturation)

  for _, texture in pairs({
    WhoFrameColumnHeader1Left,
    WhoFrameColumnHeader1Middle,
    WhoFrameColumnHeader1Right,
    WhoFrameColumnHeader2Left,
    WhoFrameColumnHeader2Middle,
    WhoFrameColumnHeader2Right,
    WhoFrameColumnHeader3Left,
    WhoFrameColumnHeader3Middle,
    WhoFrameColumnHeader3Right,
    WhoFrameColumnHeader4Left,
    WhoFrameColumnHeader4Middle,
    WhoFrameColumnHeader4Right,
    RaidInfoInstanceLabelLeft,
    RaidInfoInstanceLabelMiddle,
    RaidInfoInstanceLabelRight,
    RaidInfoIDLabelLeft,
    RaidInfoIDLabelMiddle,
    RaidInfoIDLabelRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    FriendsListFrame,
    IgnoreListFrame,
    RecruitAFriendFrame.RecruitList,
    WhoFrame,
    QuickJoinFrame,
    RaidInfoFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    FriendsFrameStatusDropdown.Background,
    WhoFrameDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    FriendsFrameTab1,
    FriendsFrameTab2,
    FriendsFrameTab3,
    FriendsFrameTab4,
    FriendsTabHeaderTab1,
    FriendsTabHeaderTab2,
    FriendsTabHeaderTab3,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end

function skin:UpdateBgToOnlineStatus()
  local statusColors = {
    ["Online"] = {0, 1, 0, 1},
    ["AFK"] = {1, 1, 0, 1},
    ["DND"] = {1, 0, 0, 1},
  }

  local bnetAFK, bnetDND = select(5, BNGetInfo())
  local statusColor = bnetAFK and statusColors["AFK"] or bnetDND and statusColors["DND"] or statusColors["Online"]

  FriendsFrameBg:SetVertexColor(statusColor[1], statusColor[2], statusColor[3], statusColor[4])
end
