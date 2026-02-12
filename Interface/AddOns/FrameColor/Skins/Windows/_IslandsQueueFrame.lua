local _, private = ...

-- Specify the options.
local options = {
  name = "_IslandsQueueFrame",
  displayedName = "",
  order = 26,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")

  if C_AddOns.IsAddOnLoaded("Blizzard_IslandsQueueUI") then
    self:Apply(mainColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_IslandsQueueUI" then
        self:Apply(mainColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_IslandsQueueUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, 0)
  end
end

function skin:Apply(mainColor, desaturation)
  -- Main Frame.
  self:SkinNineSliced(IslandsQueueFrame, mainColor, desaturation)

  for _, texture in pairs({
    IslandsQueueFrame.ArtOverlayFrame.PortraitFrame,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end
end
