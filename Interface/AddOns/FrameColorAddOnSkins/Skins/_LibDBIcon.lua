local _, private = ...

-- Specify the options.
local options = {
  name = "_LibDBIcon",
  displayedName = "",
  order = 2,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

local skin = {}

function skin:OnEnable()
  self:Apply(self:GetColor("main"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, 0)
end

function skin:Apply(mainColor, desaturation)
  local lib = LibStub("LibDBIcon-1.0", true)

  if not lib then
    return
  end

  local function skinButton(button)
    for _, child in pairs({ button:GetRegions() }) do
      if child:GetDrawLayer() == "OVERLAY" then
        child:SetDesaturation(desaturation)
        child:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
      end
    end
  end

  local buttonList = lib:GetButtonList()

  for _, name in pairs(buttonList) do
    skinButton(lib:GetMinimapButton(name))
  end

  if desaturation == 1 then
    lib.RegisterCallback("FrameColor", "LibDBIcon_IconCreated", function(_, button)
      skinButton(button)
    end)
  else
    lib.UnregisterCallback("FrameColor", "LibDBIcon_IconCreated")
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
