local _, private = ...

-- Specify the options.
local options = {
  name = "_FlightMapFrame",
  displayedName = "",
  order = 21,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_FlightMap") then
    self:Apply(mainColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_FlightMap" then
        self:Apply(mainColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_FlightMap") then
    self:Apply({1, 1, 1, 1}, 0)
  end
end

function skin:Apply(mainColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(FlightMapFrame.BorderFrame, mainColor, desaturation)
end
