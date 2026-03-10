local _, private = ...

-- Specify the options.
local options = {
  name = "_CharacterMicroButton",
  displayedName = "",
  order = 1,
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

local btnTexture = CharacterMicroButton.Portrait

function skin:OnEnable()
  local normalColor = self:GetColor("btn_normal_color")
  local highlightColor = self:GetColor("btn_highlight_color")
  local pushedColor = self:GetColor("btn_pushed_color")

  self:HookScript(CharacterMicroButton, "OnEnter", function()
    self:Apply(highlightColor, 1)
  end)

  self:HookScript(CharacterMicroButton, "OnLeave", function()
    if CharacterMicroButton:GetButtonState() == "NORMAL" then
      self:Apply(normalColor, 1)
    else
      self:Apply(pushedColor, 1)
    end
  end)

  self:HookScript(CharacterMicroButton, "OnMouseDown", function()
    self:Apply(pushedColor, 1)
  end)

  self:HookScript(CharacterFrame, "OnShow", function()
    self:Apply(pushedColor, 1)
  end)

  self:HookScript(CharacterFrame, "OnHide", function()
    if MouseIsOver(CharacterMicroButton) then
      self:Apply(highlightColor, 1)
    else
      self:Apply(normalColor, 1)
    end
  end)

  self:Apply(normalColor, 1)
end

function skin:OnDisable()
  self:Apply({1, 1, 1, 1}, 0)
end

function skin:Apply(color, desaturation)
  for _, texture in pairs({
    btnTexture,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end
