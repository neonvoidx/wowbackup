local _, private = ...

-- Specify the options.
local options = {
  name = "_LFDMicroButton",
  displayedName = "",
  order = 7,
  category = "MicroMenu",
  colors = {
    ["btn_normal_color"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["btn_highlight_color"] = {
      order = 2,
      name = "",
      rgbaValues = {1, 1, 1, 1},
    },
    ["btn_pushed_color"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("btn_normal_color"), self:GetColor("btn_highlight_color"), self:GetColor("btn_pushed_color"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, 0)
end

function skin:Apply(normalColor, highlightColor, pushedColor, desaturation)
  local textures = {
    ["normalTexture"] = LFDMicroButton:GetNormalTexture(),
    ["highlightTexture"] = LFDMicroButton:GetHighlightTexture(),
    ["pushedTexture"] = LFDMicroButton:GetPushedTexture(),
  }

  for _, texture in pairs(textures) do
    texture:SetDesaturation(desaturation)
  end

  textures.normalTexture:SetVertexColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4])
  textures.highlightTexture:SetVertexColor(highlightColor[1], highlightColor[2], highlightColor[3], highlightColor[4])
  textures.pushedTexture:SetVertexColor(pushedColor[1], pushedColor[2], pushedColor[3], pushedColor[4])
end
