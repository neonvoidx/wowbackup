local _, private = ...

-- Specify the options.
local options = {
  name = "_OrderHallMissionFrame",
  displayedName = "",
  order = 50,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
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
    ["corner_textures"] = {
      order = 5,
      name = "",
      rgbaValues = {0.8, 0.8, 0.8, 1},
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local borderColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  local cornerTextureColor = self:GetColor("corner_textures")

  if C_AddOns.IsAddOnLoaded("Blizzard_GarrisonUI") then
    self:Apply(mainColor, borderColor, controlsColor, cornerTextureColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_GarrisonUI" then
        self:Apply(mainColor, borderColor, controlsColor, cornerTextureColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_GarrisonUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, borderColor, controlsColor, cornerTextureColor, desaturation)
  -- Main frame.
    for _, texture in pairs({
    OrderHallMissionFrame.Top,
    OrderHallMissionFrame.Right,
    OrderHallMissionFrame.Bottom,
    OrderHallMissionFrame.Left,
    --AdventureMapQuestChoiceDialog.Background, -- The Quest text background is also part of the texture. This would render it unreadable.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Borders.
  for _, texture in pairs({
    --OrderHallMissionFrame.ClassHallIcon.Icon, -- Sadly the border and the Icon are one texture.
    OrderHallMissionFrame.TopBorder,
    OrderHallMissionFrame.TopRightCorner,
    OrderHallMissionFrame.RightBorder,
    OrderHallMissionFrame.BotRightCorner,
    OrderHallMissionFrame.BottomBorder,
    OrderHallMissionFrame.BotLeftCorner,
    OrderHallMissionFrame.LeftBorder,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
  end

  -- Controls.
  self:SkinScrollBarOf(AdventureMapQuestChoiceDialog.Details, controlsColor, desaturation)

  -- Corner textures.
    for _, texture in pairs({
    OrderHallMissionFrame.GarrCorners.TopLeftGarrCorner, -- Hidden behinde the icon.
    OrderHallMissionFrame.GarrCorners.TopRightGarrCorner,
    OrderHallMissionFrame.GarrCorners.BottomRightGarrCorner,
    OrderHallMissionFrame.GarrCorners.BottomLeftGarrCorner,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(cornerTextureColor[1], cornerTextureColor[2], cornerTextureColor[3], cornerTextureColor[4])
  end
end
