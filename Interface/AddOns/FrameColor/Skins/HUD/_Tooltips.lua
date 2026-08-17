local _, private = ...

-- Specify the options.
local options = {
  name = "_Tooltips",
  displayedName = "",
  order = 4,
  category = "HUD",
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
  self:Apply({1, 1, 1, 1}, 0)
end

function skin:Apply(mainColor, desaturation)
  -- Main frames.
  for _, tooltip in pairs({
    GameTooltip,
    ShoppingTooltip1,
    ShoppingTooltip2,
    ItemRefTooltip,
  }) do
    self:SkinNineSliced(tooltip, mainColor, desaturation)
  end

  -- I decided to not update the tooltip background because it has to be done after each Hide and for ShoppingTooltip1 & ShoppingTooltip2 even OnUpdate.
  -- Either implement own tooltips in the future or stick to default background.
end

