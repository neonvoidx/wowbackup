local _, private = ...

-- Specify the options.
local options = {
  name = "_CooldownViewer",
  displayedName = "",
  order = 1.1,
  category = "HUD",
  colors = {
    ["bar_border_color"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local color = self:GetColor("bar_border_color")

  self:Apply(color, 1)

  self:RegisterForEvent("PLAYER_SPECIALIZATION_CHANGED", function()
    self:Apply(color, 1)
  end)
end

function skin:OnDisable()
  self:Apply({1, 1, 1, 1}, 0)
end

function skin:Apply(barBorderColor, desaturation)
  local regions = self:GetAllChildRegionsOf(BuffBarCooldownViewer, {["Texture"] = true})
  for _, texture in pairs(regions) do
    local name = texture:GetDebugName() or ""
    if not issecretvalue(name) and not name:match("Icon") and texture:GetDrawLayer() == "BACKGROUND" then
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(barBorderColor[1], barBorderColor[2], barBorderColor[3], barBorderColor[4])
    end
  end
end
