local _, private = ...

-- Specify the options.
local options = {
  name = "_WeakAurasOptions",
  displayedName = "WeakAuras Options",
  order = 1,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      name = "",
      order = 1,
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      name = "",
      order = 1,
      rgbaValues = private.colors.default.background,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
  },
}

local skin = {}

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local controlsColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("WeakAurasOptions") then
    self:Apply(mainColor, backgroundColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      -- The frame is not created directly after ADDON_LOADED.
      if addOnName == "WeakAurasOptions" then
        RunNextFrame(function()
          self:Apply(mainColor, backgroundColor, controlsColor, 1)
        end)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("WeakAurasOptions") then
    local color = {1,1,1,1}
    self:Apply(color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, controlsColor, desaturation)
  -- Main Frame.
  for _, frame in pairs({
    WeakAurasOptions,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Backgrounds.
  for _, texture in pairs({
    WeakAurasOptionsBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Controls.
  for _, box in pairs({
    WeakAurasFilterInput,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end
end

-- Register the Skin
FrameColor.API:RegisterSkin(skin, options)
