local _, private = ...

-- Specify the options.
local options = {
  name = "_SecondaryStatusTrackingBarContainer",
  displayedName = "",
  order = 8,
  category = "HUD",
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
  self:Apply(self:GetColor("main"), 1)
end

function skin:OnDisable()
  self:Apply({1, 1, 1, 1},  0)
end

function skin:Apply(mainColor, desaturation)
  for _, texture in pairs({
    SecondaryStatusTrackingBarContainer.BarFrameTexture,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end
end
