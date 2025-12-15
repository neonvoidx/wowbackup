local _, private = ...

-- Specify the options.
local options = {
  name = "_GuildBankFrame",
  displayedName = "",
  order = 48,
  category = "Windows",
  colors = {
    ["emblem"] = {
      order = 0.1,
      name = "",
      rgbaValues = {1.0, 0.843, 0.0},
    },
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
  local emblemColor = self:GetColor("emblem")

  if C_AddOns.IsAddOnLoaded("Blizzard_GuildBankUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, emblemColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_GuildBankUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, emblemColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_GuildBankUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, emblemColor, desaturation)
  -- Emblem.
  for _, texture in pairs({
    GuildBankFrame.Emblem.Left,
    GuildBankFrame.Emblem.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(emblemColor[1], emblemColor[2], emblemColor[3], emblemColor[4])
  end

  -- Main frame.
  for _, texture in pairs({
    GuildBankFrame.TopLeftCorner,
    GuildBankFrame.LeftBorder,
    GuildBankFrame.BotLeftCorner,
    GuildBankFrame.BottomBorder,
    GuildBankFrame.BotRightCorner,
    GuildBankFrame.RightBorder,
    GuildBankFrame.TopRightCorner,
    GuildBankFrame.TopBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  GuildBankFrame.RedMarbleBG:SetDesaturation(desaturation)
  GuildBankFrame.RedMarbleBG:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Inset border frames
  for _, texture in pairs({
    GuildBankFrameTopLeftOuter,
    GuildBankFrameTopOuter,
    GuildBankFrameTopRightOuter,
    GuildBankFrameRightOuter,
    GuildBankFrameBottomRightOuter,
    GuildBankFrameBottomOuter,
    GuildBankFrameBottomLeftOuter,
    GuildBankFrameLeftOuter,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  for _, texture in pairs({
    GuildBankFrameTopLeftInner,
    GuildBankFrameTopInner,
    GuildBankFrameTopRightInner,
    GuildBankFrameRightInner,
    GuildBankFrameBottomRightInner,
    GuildBankFrameBottomInner,
    GuildBankFrameBottomLeftInner,
    GuildBankFrameLeftInner,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls
  self:SkinBox(GuildItemSearchBox, controlsColor, desaturation)

  for _, scrollFrame in pairs({
    GuildBankFrame.Log,
    GuildBankInfoScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  -- Tabs
  for _, tab in pairs({
    GuildBankFrameTab1,
    GuildBankFrameTab2,
    GuildBankFrameTab3,
    GuildBankFrameTab4,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end

  -- Side-Tabs
  local i = 0
  while(true) do
    i = i+1
    local tab = _G["GuildBankTab" .. i]
    if not tab then
      break
    end
    -- Dynamicly created texture.
    for k, v in pairs({tab:GetRegions()}) do
      if type(v) == "table" and v.GetObjectType and v:GetObjectType() == "Texture" then
        v:SetDesaturation(desaturation)
        v:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
      end
    end
  end
end




