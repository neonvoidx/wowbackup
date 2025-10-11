local _, private = ...

-- Specify the options.
local options = {
  name = "_DressUpFrame",
  displayedName = "",
  order = 18,
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
  -- Main frames.
  self:SkinNineSliced(DressUpFrame, mainColor, desaturation)

    -- The right overlay.
  for _, v in pairs({DressUpFrame.OutfitDetailsPanel:GetRegions()}) do
    if v:GetDrawLayer() == "OVERLAY" then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
    end
  end

  -- Borders.
  self:SkinNineSliced(DressUpFrameInset, bordersColor, desaturation)

  -- Backgrounds.
  for _, texture in pairs({
    DressUpFrameBg,
    -- DressUpFrame.TitleBg, can't see any difference.
    -- DressUpFrameInset.Bg, can't see any difference.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Controls.
  for _, texture in pairs({
    DressUpFrameOutfitDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
