local _, private = ...

-- Specify the options.
local options = {
  name = "_TargetFrameToT",
  displayedName = "",
  order = 3,
  category = "UnitFrames",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
  toggles = {
    ["follow_unit_class_or_reaction_color"] = {
      name = "",
      isChecked = false,
    }
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  if self:GetToggleState("follow_unit_class_or_reaction_color") then
    local function setToUnitColor()
      self:Apply(self:GetUnitColor("targettarget"), 1)
    end
    self:RegisterForEvent("PLAYER_TARGET_CHANGED", setToUnitColor)
    self:RegisterForUnitEvent("UNIT_TARGET", "target", setToUnitColor)
    setToUnitColor()
  else
    local mainColor = self:GetColor("main")
    skin:Apply(mainColor, 1)
  end
end

function skin:OnDisable()
  self:Apply({1,1,1,1}, 0)
end

function skin:Apply(color, desaturation)
  local texture = TargetFrameToT.FrameTexture
  texture:SetDesaturation(desaturation)
  texture:SetVertexColor(color[1], color[2], color[3], color[4])
end


