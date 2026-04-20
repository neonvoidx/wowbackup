if not C_AddOns.IsAddOnLoaded("Baganator") then
  return
end

local _, private = ...

-- Specify the options.
local options = {
  name = "_BaganatorBlizzardTheme",
  displayedName = "Baganator Blizzard Theme - Experimental",
  order = 1,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      name = "",
      order = 1,
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      name = "",
      order = 2,
      rgbaValues = private.colors.default.background,
      hasAlpha = true,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    --[[
    ["tabs"] = {
      order = 5,
      name = "",
      rgbaValues = private.colors.default.tabs,
    },
    ]]
  },
}

local skin = {}


function skin:OnEnable()
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("controls"), self:GetColor("tabs"), 1)

  
  Baganator.CallbackRegistry:RegisterCallback("ShowCustomise", function ()
    -- @Todo Skin options window.
  end)



end

function skin:OnDisable()
  local color = {1,1,1,1}
  self:Apply(color, color, color, color, 0)

  Baganator.CallbackRegistry:UnregisterCallback("ShowCustomise", coolesDIng)
end

function skin:Apply(mainColor, backgroundColor, controlsColor, tabsColor, desaturation)
  -- Main Frame.
  for _, frame in pairs({
    Baganator_CategoryViewBackpackViewFrameblizzard,
    Baganator_CurrencyPanelFrameblizzard,
    Baganator_CategoryViewBankViewFrameblizzard,
    BaganatorCustomiseDialogFrameblizzard,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Backgrounds.
  for _, texture in pairs({
    Baganator_CategoryViewBackpackViewFrameblizzardBg,
    Baganator_CurrencyPanelFrameblizzardBg,
    Baganator_CategoryViewBankViewFrameblizzardBg,
    BaganatorCustomiseDialogFrameblizzardBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Controls.
  for _, box in pairs({
    Baganator_CategoryViewBackpackViewFrameblizzard.SearchWidget.SearchBox,
    Baganator_CurrencyPanelFrameblizzard.searchBox,
    Baganator_CategoryViewBankViewFrameblizzard.SearchWidget.SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  for _, frame in pairs({
    -- Scroll bar is from a pool
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end

  for _, child in pairs({Baganator_CurrencyPanelFrameblizzard:GetChildren()}) do
    if type(child) == "table" and child.Track then
      for _, texture in pairs({
        child.Track.Thumb.Begin,
        child.Track.Thumb.Middle,
        child.Track.Thumb.End,
        child.Back.Texture,
        child.Forward.Texture,
      }) do
        texture:SetDesaturation(desaturation)
        texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
      end
    end
  end

  --[[
  Needs more work!
  -- Tabs.
  -- Bank Tabs.
  for _, child in pairs({Baganator_CategoryViewBankViewFrameblizzard:GetChildren()}) do
    if type(child) == "table" and child.Left then
      for _, texture in pairs({
        child.Left,
        child.Middle,
        child.Right,
      }) do
        texture:SetDesaturation(desaturation)
        texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
      end
    end
  end

  -- Bank Side Tabs.
  for i=1, 15 do
    for _, texture in pairs({
      _G["BGRItemViewCommonTabButton" .. i]
    }) do
      texture.Background:SetDesaturation(desaturation)
      texture.Background:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
    end
  end
  -- Warband Purchase Side Tab.
  for _, texture in pairs({
    Baganator_CategoryViewBankViewFrameblizzard.Warband.purchaseButton.Background
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
  end
  ]]
end


-- Register the Skin
FrameColor.API:RegisterSkin(skin, options, true)



