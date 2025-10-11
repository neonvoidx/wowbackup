local _, private = ...

-- Specify the options.
local options = {
  name = "_MenuStyle1Mixin",
  displayedName = "",
  order = 5,
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
  local mainColor = self:GetColor("main")

  -- BlizzardInterfaceCode/Interface/AddOns/Blizzard_Menu/Mainline/MenuTemplates.lua
  self:HookFunc(MenuStyle1Mixin, "Generate", function(self)
    for _, v in pairs({ self:GetRegions() }) do
      if v:IsObjectType("Texture") then
        v:SetDesaturation(1)
        v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
      end
    end
  end)
end



