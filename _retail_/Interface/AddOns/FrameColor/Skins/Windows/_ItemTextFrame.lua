local _, private = ...

-- Specify the options.
local options = {
  name = "_ItemTextFrame",
  displayedName = "",
  order = 29,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.background,
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(ItemTextFrame, mainColor, desaturation)

  -- Background.
  for _, texture in pairs({
    ItemTextFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  self:SkinNineSliced(ItemTextFrameInset, bordersColor, desaturation)

  -- Controls.
  self:SkinScrollBarOf(ItemTextScrollFrame, controlsColor, desaturation)
end
