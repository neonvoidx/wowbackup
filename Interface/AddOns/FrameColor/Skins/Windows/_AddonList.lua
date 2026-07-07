local _, private = ...

-- Specify the options.
local options = {
  name = "_AddonList",
  displayedName = "",
  order = 2,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["borders"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.borders,
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
  self:Apply(self:GetColor("main"), self:GetColor("borders"), self:GetColor("background"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, 0)
end

function skin:Apply(mainColor, bordersColor, backgroundColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(AddonList, mainColor, desaturation)

  -- Borders.
  self:SkinNineSliced(AddonListInset, bordersColor, desaturation)

  -- Background.
  AddonListBg:SetDesaturation(desaturation)
  AddonListBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Controls.
  for _, texture in pairs({
    AddonList.Dropdown.Background,
    -- AddonList.Dropdown.Arrow -- Button looks like disabled with this.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  self:SkinBox(AddonList.SearchBox, controlsColor, desaturation)

  self:SkinScrollBarOf(AddonList, controlsColor, desaturation)
end
