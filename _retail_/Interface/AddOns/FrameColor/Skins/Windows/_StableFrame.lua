local _, private = ...

-- Specify the options.
local options = {
  name = "_StableFrame",
  displayedName = "",
  order = 35,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["borders"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.borders,
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
  self:Apply(self:GetColor("main"), self:GetColor("borders"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, 0)
end

function skin:Apply(mainColor, bordersColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(StableFrame, mainColor, desaturation)

  -- Borders.
  for _, frame in pairs({
    StableFrame.StabledPetList.Inset,
    StableFrame.PetModelScene.Inset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  self:SkinBorderOf(StableFrame.StabledPetList.ListCounter, bordersColor, desaturation)

  -- Controls.
  for _, texture in pairs({
    StableFrame.StabledPetList.FilterBar.FilterDropdown.Background,
    StableFrame.PetModelScene.PetInfo.Specialization.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  self:SkinBox(StableFrame.StabledPetList.FilterBar.SearchBox, controlsColor, desaturation)

  self:SkinScrollBarOf(StableFrame.StabledPetList, controlsColor, desaturation)
end
