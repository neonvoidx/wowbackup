local _, private = ...

-- Specify the options.
local options = {
  name = "_ItemUpgradeFrame",
  displayedName = "",
  order = 30,
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
  },
  toggles = {
    ["follow_item_quality"] = {
      order = 1,
      name = "",
      isChecked = true,
    }
  }
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("Blizzard_ItemUpgradeUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_ItemUpgradeUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end

  if self:GetToggleState("follow_item_quality") then
    self:RegisterForEvent("ITEM_UPGRADE_MASTER_SET_ITEM", skin.UpdateBgColorToItemQuality)
    self:RegisterForEvent("ITEM_INTERACTION_ITEM_SELECTION_UPDATED", skin.UpdateBgColorToItemQuality)
    self:UpdateBgColorToItemQuality()
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_ItemUpgradeUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(ItemUpgradeFrame, mainColor, desaturation)

  -- Background.
  for _, texture in pairs({
    ItemUpgradeFrame.BottomBG,
    ItemUpgradeFrame.TopBG
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, texture in pairs({
    ItemUpgradeFrame.UpgradeItemButton.ButtonFrame,
    ItemUpgradeFramePlayerCurrenciesBorderLeft,
    ItemUpgradeFramePlayerCurrenciesBorderMiddle,
    ItemUpgradeFramePlayerCurrenciesBorderRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, texture in pairs({
    ItemUpgradeFrame.ItemInfo.Dropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end

local qualityColors = {
  [0] = {0.62, 0.62, 0.62, 1},  -- Gray (Poor / Junk)
  [1] = {1, 1, 1, 1},           -- White (Common)
  [2] = {0.12, 1, 0, 1},        -- Green (Uncommon)
  [3] = {0, 0.44, 0.87, 1},     -- Blue (Rare)
  [4] = {0.64, 0.21, 0.93, 1},  -- Purple (Epic)
  [5] = {1, 0.5, 0, 1},         -- Orange (Legendary)
  [6] = {0.9, 0.8, 0.5, 1},     -- Gold (Artifact)
  [7] = {0.8, 0.8, 0.8, 1},     -- Light Gray (Heirloom)
}

function skin:UpdateBgColorToItemQuality()
  if not ItemUpgradeFrame then
    return
  end

  local itemInfo = C_ItemUpgrade.GetItemUpgradeItemInfo()
  local displayQuality = itemInfo and itemInfo.displayQuality
  local color = displayQuality and qualityColors[displayQuality] or skin:GetColor("background")

  for _, texture in pairs({
    ItemUpgradeFrame.BottomBG,
    --ItemUpgradeFrame.TopBG
  }) do
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end
