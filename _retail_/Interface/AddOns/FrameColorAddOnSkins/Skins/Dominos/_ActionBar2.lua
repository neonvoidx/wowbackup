if not C_AddOns.IsAddOnLoaded("Dominos") then
  return
end

local _, private = ...

-- Specify the options.
local options = {
  name = "_ActionBar2",
  displayedName = "",
  order = 2,
  category = "ActionBars",
  colors = {
    ["main"] = {
      name = "",
      order = 1,
      rgbaValues = private.colors.default.main,
    }
  },
}

local skin = {}

function skin:OnEnable()
  self:Apply(self:GetColor("main"), 1)
end

function skin:OnDisable()
  self:Apply({1,1,1,1}, 0)
end

function skin:Apply(color, desaturation)
  local textures = {}

  for i = 13, 24 do
    local texture = _G["DominosActionButton" .. i .. "NormalTexture"]
    if texture then
      table.insert(textures, texture)
    end
  end

  for _, texture in pairs(textures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options, true)
