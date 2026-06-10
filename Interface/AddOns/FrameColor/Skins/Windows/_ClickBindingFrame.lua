local _, private = ...

-- Specify the options.
local options = {
  name = "_ClickBindingFrame",
  displayedName = "",
  order = 11,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.background,
    },
    ["borders"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.borders,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("Blizzard_ClickBindingUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_ClickBindingUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_ClickBindingUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    ClickBindingFrame,
    ClickBindingFrame.TutorialFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Background.
  ClickBindingFrameBg:SetDesaturation(desaturation)
  ClickBindingFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Borders.
  self:SkinNineSliced(ClickBindingFrame.ScrollBoxBackground, bordersColor, desaturation)

  -- Controls.
  self:SkinScrollBarOf(ClickBindingFrame, controlsColor, desaturation)

  for _, texture in pairs({
    ClickBindingFrame.MouseoverCastKeyDropdown.Background
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
