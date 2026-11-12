if not C_AddOns.DoesAddOnExist("WorldQuestTab") then
  return
end

-- Specify the options.
local options = {
  name = "_WorldQuestTab",
  displayedName = "World Quest Tab",
  order = 1,
  category = "AddonSkins",
  followSkin = "_WorldMapFrame",
}

local skin = {}

function skin:OnEnable()
  local tabsColor = self:GetLeaderColor("tabs")
  local controlsColor = self:GetLeaderColor("controls")
  self:Apply(tabsColor, controlsColor, 1)
end

function skin:OnDisable()
  local color = {1,1,1,1}
  self:Apply(color, color, 0)
end

function skin:Apply(tabsColor, controlsColor, desaturation)
  -- Controls.
  for _, scrollFrame in pairs({
    WQT_ListContainer,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    WQT_ListContainer.SortDropdown.Background,
    WQT_ListContainer.FilterDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, texture in pairs({
    WQT_QuestMapTab.Background
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
