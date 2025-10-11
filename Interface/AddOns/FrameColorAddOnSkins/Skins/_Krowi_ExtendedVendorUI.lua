if not C_AddOns.DoesAddOnExist("Krowi_ExtendedVendorUI") then
  return
end

-- Specify the options.
local options = {
  name = "_Krowi_ExtendedVendorUI",
  displayedName = "Krowi's Extended Vendor UI",
  order = 1,
  category = "AddonSkins",
  followSkin = "_MerchantFrame",
}

local skin = {}

function skin:OnEnable()
  local bordersColor = self:GetLeaderColor("borders")
  local controlsColor = self:GetLeaderColor("controls")
  self:Apply(bordersColor, controlsColor, 1)
end

function skin:OnDisable()
  local color = {1,1,1,1}
  self:Apply(color, color, 0)
end

function skin:Apply(bordersColor, controlsColor, desaturation)
  -- Bottom border.
  for _, texture in pairs({
    KrowiEVU_BottomExtensionLeftBorder,
    KrowiEVU_BottomExtensionMidBorder,
    KrowiEVU_BottomExtensionRightBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, texture in pairs({
    KrowiEVU_OptionsButtonTopMiddle,
    KrowiEVU_OptionsButtonTopRight,
    KrowiEVU_OptionsButtonMiddleRight,
    KrowiEVU_OptionsButtonBottomRight,
    KrowiEVU_OptionsButtonBottomMiddle,
    KrowiEVU_OptionsButtonBottomLeft,
    KrowiEVU_OptionsButtonMiddleLeft,
    KrowiEVU_OptionsButtonTopLeft,

    KrowiEVU_FilterButtonTopMiddle,
    KrowiEVU_FilterButtonTopRight,
    KrowiEVU_FilterButtonMiddleRight,
    KrowiEVU_FilterButtonBottomRight,
    KrowiEVU_FilterButtonBottomMiddle,
    KrowiEVU_FilterButtonBottomLeft,
    KrowiEVU_FilterButtonMiddleLeft,
    KrowiEVU_FilterButtonTopLeft,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    KrowiEVU_SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
