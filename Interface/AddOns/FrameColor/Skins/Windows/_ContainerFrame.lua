local _, private = ...

-- Specify the options.
local options = {
  name = "_ContainerFrame",
  displayedName = "",
  order = 15,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    --[[ @ TODO add icon borders.
    ["borders"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.borders,
    },
    ]]
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
  self:SkinNineSliced(ContainerFrameCombinedBags, mainColor, desaturation)

  -- Backgrounds
  for _, texture in pairs({
    ContainerFrameCombinedBags.Bg.TopSection,
    ContainerFrameCombinedBags.Bg.BottomEdge,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

    -- Calling SetVertexColor on them will render them opaque.
  for _, texture in pairs({
    ContainerFrameCombinedBags.Bg.BottomLeft,
    ContainerFrameCombinedBags.Bg.BottomRight
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.

  -- Controls.
  for _, texture in pairs({
    ContainerFrameCombinedBags.MoneyFrame.Border.Middle,
    ContainerFrameCombinedBags.MoneyFrame.Border.Left,
    ContainerFrameCombinedBags.MoneyFrame.Border.Right,
    BagItemSearchBox.Left,
    BagItemSearchBox.Middle,
    BagItemSearchBox.Right,
    ContainerFrame1MoneyFrame.Border.Left,
    ContainerFrame1MoneyFrame.Border.Middle,
    ContainerFrame1MoneyFrame.Border.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Separated bags.
  for bag_num = 1, 6 do
    local container = _G["ContainerFrame" .. bag_num]

    -- Main frame.
    self:SkinNineSliced(container, mainColor, desaturation)

    -- Background.
    container.Bg.TopSection:SetDesaturation(desaturation)
    container.Bg.TopSection:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    container.Bg.BottomEdge:SetDesaturation(desaturation)
    container.Bg.BottomEdge:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    container.Bg.BottomLeft:SetDesaturation(desaturation)
    container.Bg.BottomLeft:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    container.Bg.BottomRight:SetDesaturation(desaturation)
    container.Bg.BottomRight:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end
end
