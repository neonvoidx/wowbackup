local _, private = ...

-- Specify the options.
local options = {
  name = "_MacroFrame",
  displayedName = "",
  order = 32,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_MacroUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_MacroUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_MacroUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Main frames.
  self:SkinNineSliced(MacroFrame, mainColor, desaturation)

  self:SkinBorderOf(MacroPopupFrame.BorderBox, mainColor, desaturation)

    -- Mainly for the MacroHorizonalBarRight which unlike Left has no global reference or key name.
  local ignore = {
    ["MacroFramePortrait"] = true,
    ["MacroFrameBg"] = true,
  }

  for _, v in pairs({ MacroFrame:GetRegions() }) do
    if v:IsObjectType("texture") and not ignore[v:GetName()] then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end

  -- Backgrounds.
  for _, texture in pairs({
    MacroFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    MacroFrameInset,
    MacroFrameTextBackground,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls.
  for _, texture in pairs({
    MacroPopupFrame.BorderBox.IconTypeDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, scrollFrame in pairs({
    MacroFrame.MacroSelector,
    MacroPopupFrame.IconSelector,
    MacroFrameScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    MacroFrameTab1,
    MacroFrameTab2,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
