local _, private = ...

-- Specify the options.
local options = {
  name = "_HousingModelPreviewFrame",
  displayedName = "",
  order = 54,
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
local related_addon = "Blizzard_HousingModelPreview"

function skin:OnEnable()
  local mainColor = self:GetColor("main")

  if C_AddOns.IsAddOnLoaded(related_addon) then
    self:Apply(mainColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == related_addon then
        self:Apply(mainColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded(related_addon) then
    local color = {1, 1, 1, 1}
    self:Apply(color, 0)
  end
end

function skin:Apply(mainColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(HousingModelPreviewFrame, mainColor, desaturation)
end
