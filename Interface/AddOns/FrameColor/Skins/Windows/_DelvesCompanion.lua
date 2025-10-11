local _, private = ...

-- Specify the options.
local options = {
  name = "_DelvesCompanion",
  displayedName = "",
  order = 16,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.background,
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, controlsColor, desaturation)
  -- Main frames.
  self:SkinBorderOf(DelvesCompanionConfigurationFrame, mainColor, desaturation)
  self:SkinNineSliced(DelvesCompanionAbilityListFrame, mainColor, desaturation)

  -- Background.
  DelvesCompanionAbilityListFrameBg:SetDesaturation(desaturation)
  DelvesCompanionAbilityListFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Controls.
  for _, texture in pairs({
    DelvesCompanionAbilityListFrame.DelvesCompanionRoleDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
