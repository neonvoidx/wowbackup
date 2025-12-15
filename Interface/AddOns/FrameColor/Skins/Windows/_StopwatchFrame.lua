local _, private = ...

-- Specify the options.
local options = {
  name = "_StopwatchFrame",
  displayedName = "",
  order = 45,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_TimeManager") then
    self:Apply(mainColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_TimeManager" then
        self:Apply(mainColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_TimeManager") then
    local color = {1, 1, 1, 1}
    self:Apply(color, 0)
  end
end

function skin:Apply(mainColor, desaturation)
  -- Main frame.
  for _, v in pairs({ StopwatchFrame:GetRegions() }) do
    if v:IsObjectType("Texture") then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end
end

