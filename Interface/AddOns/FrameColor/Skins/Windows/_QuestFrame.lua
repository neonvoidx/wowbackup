local _, private = ...

-- Specify the options.
local options = {
  name = "_QuestFrame",
  displayedName = "",
  order = 41,
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
  self:SkinNineSliced(QuestFrame, mainColor, desaturation)

    -- NPC Model.
  for _, texture in pairs({
    QuestModelScene.TopBarBg,
    QuestModelScene.Border,
    QuestModelScene.ModelNameDivider,
    QuestModelScene.ModelNameBackground,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    QuestFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  self:SkinNineSliced(QuestFrameInset, bordersColor, desaturation)

  -- Controls.
  for _, scrollFrame in pairs({
    QuestDetailScrollFrame,
    QuestNPCModelTextScrollFrame,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end
end
