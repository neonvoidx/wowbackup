local _, private = ...

-- Specify the options.
local options = {
  name = "_DelvesDifficultyPicker",
  displayedName = "",
  order = 17,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local controlsColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("Blizzard_DelvesDifficultyPicker") then
    self:Apply(mainColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_DelvesDifficultyPicker" then
        self:Apply(mainColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_DelvesDifficultyPicker") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, 0)
  end
end

function skin:Apply(mainColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinBorderOf(DelvesDifficultyPickerFrame, mainColor, desaturation)

  -- Controls.
  for _, texture in pairs({
    DelvesDifficultyPickerFrame.Dropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
