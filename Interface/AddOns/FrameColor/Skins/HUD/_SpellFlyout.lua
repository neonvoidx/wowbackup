local _, private = ...

-- Specify the options.
local options = {
  name = "_SpellFlyout",
  displayedName = "",
  order = 12,
  category = "HUD",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
  toggles = {
    ["follow_parent_color"] = {
      order = 1,
      isChecked = true,
    },
  }
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local followParent = self:GetToggleState("follow_parent_color")
  self:HookScript(SpellFlyout, "OnSizeChanged", function()
    if followParent then
      skin:SetToParentColor(mainColor)
    else
      skin:Apply(mainColor, 1)
    end
  end)
end

function skin:OnDisable()
  self:Apply({1, 1, 1, 1}, 0)
end

function skin:Apply(mainColor, desaturation)
  -- Main frame.
  for _, texture in pairs({
    SpellFlyout.Background.Start,
    SpellFlyout.Background.VerticalMiddle,
    SpellFlyout.Background.HorizontalMiddle,
    SpellFlyout.Background.End,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Button borders.
  local i = 1
  while(true) do
    local btnTexture = _G["SpellFlyoutPopupButton" .. i .. "NormalTexture"]

    if not btnTexture then
      break
    end

    btnTexture:SetDesaturation(desaturation)
    btnTexture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])

    i = i + 1
  end
end

function skin:SetToParentColor(fallbackColor)
  local parent = SpellFlyout:GetParent()

  if parent then
    local parentName = parent:GetName()

    if parentName then
      local texture = _G[parentName .. "NormalTexture"]
      local r, g, b, a = texture:GetVertexColor()
      local color = {r, g, b, a}
      self:Apply(color, 1)
    else
      self:Apply(fallbackColor, 1)
    end
  else
    self:Apply(fallbackColor, 1)
  end
end

