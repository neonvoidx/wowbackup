local _, private = ...

-- Specify the options.
local options = {
  name = "_CompactPartyFrame",
  displayedName = "",
  order = 9,
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
  for _, texture in pairs({
    CompactPartyFrameBorderFrameBorderRight,
    CompactPartyFrameBorderFrameBorderLeft,
    CompactPartyFrameBorderFrameBorderTop,
    CompactPartyFrameBorderFrameBorderBottom,
    CompactPartyFrameBorderFrameBorderTopRight,
    CompactPartyFrameBorderFrameBorderBottomRight,
    CompactPartyFrameBorderFrameBorderTopLeft,
    CompactPartyFrameBorderFrameBorderBottomLeft,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
  for i=1, 5 do
    for _, v in pairs({
      _G["CompactPartyFrameMember"..i.."HorizBottomBorder"],
      _G["CompactPartyFrameMember"..i.."HorizTopBorder"],
      _G["CompactPartyFrameMember"..i.."VertRightBorder"],
      _G["CompactPartyFrameMember"..i.."VertLeftBorder"],
    }) do
      v:SetDesaturation(desaturation)
      v:SetVertexColor(color[1], color[2], color[3], color[4])
    end
  end
end


