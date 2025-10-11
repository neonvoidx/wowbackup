if not C_AddOns.IsAddOnLoaded("Bartender4") then
  return
end

local _, private = ...

-- Specify the options.
local options = {
  name = "_Bartender4ClassBar2",
  displayedName = "Bartender 4 Class Bar 2",
  order = 13,
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

  for i = 85, 96 do
    local texture = _G["BT4Button" .. i .. "NormalTexture"]
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
FrameColor.API:RegisterSkin(skin, options)
