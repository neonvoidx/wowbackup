local _, private = ...

-- Specify the options.
local options = {
  name = "_CompactRaidFrameManager",
  displayedName = "",
  order = 10,
  category = "HUD",
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
  self:Apply(self:GetColor("main"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, 0)
end

function skin:Apply(mainColor, controlsColor, desaturation)
  -- Main frames.
  for _, texture in pairs({
    _G["CompactRaidFrameManagerBG-leads"],
    _G["CompactRaidFrameManagerBG-assists"],
    _G["CompactRaidFrameManagerBG-regulars"],
    _G["CompactRaidFrameManagerBG-party-leads"],
    _G["CompactRaidFrameManagerBG-party-regulars"],
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end


  -- Controls.
  for _, texture in pairs({
    CompactRaidFrameManagerDisplayFrameModeControlDropdown.Background,
    CompactRaidFrameManagerDisplayFrameRestrictPingsDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
