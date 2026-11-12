local _, private = ...

-- Specify the options.
local options = {
  name = "_MirrorTimerContainer",
  displayedName = "",
  order = 9,
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
  self:Apply({1, 1, 1, 1}, 0)
end

function skin:Apply(mainColor, desaturation)
  -- Main frames.
  for _, child in pairs({ MirrorTimerContainer:GetChildren() }) do
    if child.Border then
      child.Border:SetDesaturation(desaturation)
      child.Border:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end
end
