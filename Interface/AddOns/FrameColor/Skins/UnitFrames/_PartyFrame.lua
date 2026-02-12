local _, private = ...

-- Specify the options.
local options = {
  name = "_PartyFrame",
  displayedName = "",
  order = 7,
  category = "UnitFrames",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  skin:Apply(mainColor, 1)
end

function skin:OnDisable()
  self:Apply({1,1,1,1}, 0)
end

function skin:Apply(color, desaturation)
  for i=1,4 do
    local frameTexture = PartyFrame["MemberFrame"..i].Texture
    frameTexture:SetDesaturation(desaturation)
    frameTexture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end


