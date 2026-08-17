local _, private = ...

-- Specify the options.
local options = {
  name = "_ChannelFrame",
  displayedName = "",
  order = 8,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_Communities" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(ChannelFrame, mainColor, desaturation)

  for _, texture in pairs({
    CreateChannelPopup.Header.LeftBG,
    CreateChannelPopup.Header.CenterBG,
    CreateChannelPopup.Header.RightBG,
    CreateChannelPopup.Name.Left,
    CreateChannelPopup.Name.Middle,
    CreateChannelPopup.Name.Right,
    CreateChannelPopup.Password.Left,
    CreateChannelPopup.Password.Middle,
    CreateChannelPopup.Password.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  self:SkinBorderOf(CreateChannelPopup.BG, mainColor, desaturation)

  -- Background.
  ChannelFrameBg:SetDesaturation(desaturation)
  ChannelFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Borders.
  for _, frame in pairs({
    ChannelFrame.RightInset,
    ChannelFrame.LeftInset,
    ChannelFrameInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  -- Controls
  self:SkinScrollBarOf(ChannelFrame.ChannelRoster, controlsColor, desaturation)
end
