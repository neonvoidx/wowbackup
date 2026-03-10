local _, private = ...

-- Specify the options.
local options = {
  name = "_ReadyCheckListenerFrame",
  displayedName = "",
  order = 42,
  category = "Windows",
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
  self:Apply(self:GetColor("main"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, 0)
end

function skin:Apply(mainColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(ReadyCheckListenerFrame, mainColor, desaturation)
end
