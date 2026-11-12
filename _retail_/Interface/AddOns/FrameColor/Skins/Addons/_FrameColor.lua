local _, private = ...

-- Specify the options.
local options = {
  name = "FrameColor",
  displayedName = "Frame Color",
  order = 1,
  category = "AddonSkins",
  colors = {
    ["main"] = {
      order = 1,
      name = "Main",
      lockedColor = true,
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "Background",
      hasAlpha = true,
      lockedColor = true,
      rgbaValues = private.colors.default.background,
    },
    ["borders"] = {
      name = "Borders",
      lockedColor = true,
      order = 3,
      rgbaValues = private.colors.default.borders,
    },
    ["controls"] = {
      name = "Controls",
      lockedColor = true,
      order = 4,
      rgbaValues = private.colors.default.controls,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local borderColor = self:GetColor("borders")
  local controlColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("FrameColorOptions") then
    self:Apply(mainColor, backgroundColor, borderColor, controlColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "FrameColorOptions" then
        self:Apply(mainColor, backgroundColor, borderColor, controlColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("FrameColorOptions") then
    local color = {1,1,1,1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, borderColor, controlColor, desaturation)
  local frame = FrameColorOptions

  -- Main frame.
  self:SkinNineSliced(frame, mainColor, desaturation)

  -- Inser borders.
  for _, nineSlicedFrame in pairs({
    frame.leftInset,
    frame.rightInset,
  }) do
    self:SkinNineSliced(nineSlicedFrame, borderColor, desaturation)
  end

  -- Background.
  frame.Bg:SetDesaturation(desaturation)
  frame.Bg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- box
  self:SkinBox(frame.searchBox, controlColor, desaturation)

  -- ScrollBar
  self:SkinScrollBarOf(frame.rightInset, controlColor, desaturation)
end



