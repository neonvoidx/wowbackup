local _, private = ...

-- Specify the options.
local options = {
  name = "_ActionBar1",
  displayedName = "",
  order = 1,
  category = "ActionBars",
  colors = {
    ["main"] = {
      name = "",
      order = 1,
      rgbaValues = {0.22, 0.22, 0.22, 1},
    }
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  self:Apply(mainColor, 1)
end

function skin:OnDisable()
  self:Apply({1,1,1,1}, 0)
end

function skin:Apply(color, desaturation)
  local textures = {}

  for i = 1, 12 do
    local texture = _G["ActionButton" ..i.. "NormalTexture"]
    if texture then
      table.insert(textures, texture)
    end
  end

  for _ , texture in pairs({
    MainMenuBar.EndCaps.LeftEndCap,
    MainMenuBar.BorderArt,
    MainMenuBar.EndCaps.RightEndCap,
    ActionButton1.RightDivider,
    ActionButton2.RightDivider,
    ActionButton3.RightDivider,
    ActionButton4.RightDivider,
    ActionButton5.RightDivider,
    ActionButton6.RightDivider,
    ActionButton7.RightDivider,
    ActionButton8.RightDivider,
    ActionButton9.RightDivider,
    ActionButton10.RightDivider,
    ActionButton11.RightDivider,
  }) do
    table.insert(textures, texture)
  end

  for _, texture in pairs(textures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end


