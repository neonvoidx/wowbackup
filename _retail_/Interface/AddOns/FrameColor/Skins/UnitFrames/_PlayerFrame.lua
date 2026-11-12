local _, private = ...

-- Specify the options.
local options = {
  name = "_PlayerFrame",
  displayedName = "",
  order = 1,
  category = "UnitFrames",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["corner_icon"] = {
      name = "",
      order = 2,
      followClassColor = true,
      hasAlpha = true,
      rgbaValues = private.colors.default.main,
    },
    ["class_power_bar"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["cast_bar"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
  toggles = {
    ["hide_pulsing_resting"] = {
      name = "Hide the pulsing restsing Animation.",
      isChecked = true,
    }
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local cornerIconColor = self:GetColor("corner_icon")
  local classPowerBarColor = self:GetColor("class_power_bar")
  local castBarColor = self:GetColor("cast_bar")

  if self:GetToggleState("hide_pulsing_resting") then
    local hideResting = function()
      if IsResting() then
        _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:Hide()
      end
    end
    self:HookFunc("PlayerFrame_UpdateStatus", hideResting)
    hideResting()
  end

  self:ApplySkin(mainColor, cornerIconColor, classPowerBarColor, castBarColor, 1)
end

function skin:OnDisable()
  if IsResting() then
    _G.PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:Show()
  end
  local color = {1,1,1,1}
  self:ApplySkin(color, color, color, color, 0)
end

-- List of all class power bars.
local classPowerBars = {
  ["PALADIN"] = function(color, desaturation)
    for _, texture in pairs({
      PaladinPowerBarFrame.Background,
      PaladinPowerBarFrame.ActiveTexture,
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
  end,
  ["DEATHKNIGHT"] = function(color, desaturation)
    local runes = _G.RuneFrame
    if runes then
      for i = 1, 6 do
        local rune_active = runes["Rune" .. i].BG_Active
        local rune_inactive = runes["Rune" .. i].BG_Inactive
        if rune_active then
          rune_active:SetDesaturation(desaturation)
          rune_active:SetVertexColor(color[1], color[2], color[3], color[4])
        end
        if rune_inactive then
          rune_inactive:SetDesaturation(desaturation)
          rune_inactive:SetVertexColor(color[1], color[2], color[3], color[4])
        end
      end
    end
  end,
  ["WARLOCK"] = function(color, desaturation)
    local soulShards = _G.WarlockPowerFrame
    if soulShards then
      for _, shard in pairs({soulShards:GetChildren()}) do
        if shard.Background then
          shard.Background:SetDesaturation(desaturation)
          shard.Background:SetVertexColor(color[1], color[2], color[3], color[4])
        end
      end
    end
  end,
}

function skin:ApplySkin(mainColor, cornerIconColor, classPowerBarColor, castBarColor, desaturation)
  -- Frame Textures.
  for _,frameTexture in pairs({
    PlayerFrame.PlayerFrameContainer.FrameTexture,
    PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
    PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
    PlayerFrameGroupIndicatorLeft,
    PlayerFrameGroupIndicatorMiddle,
    PlayerFrameGroupIndicatorRight,
  }) do
    frameTexture:SetDesaturation(desaturation)
    frameTexture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Class Power Bars.
  if classPowerBars[private.playerInfo.class] then
    classPowerBars[private.playerInfo.class](classPowerBarColor, desaturation)
  end

  -- Player Corner Icon.
  local cornerIcon = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon
  cornerIcon:SetDesaturation(desaturation)
  cornerIcon:SetVertexColor(cornerIconColor[1], cornerIconColor[2], cornerIconColor[3], cornerIconColor[4])

  -- Player Castbar.
  for _,texture in pairs({
    PlayerCastingBarFrame.Border,
    PlayerCastingBarFrame.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(castBarColor[1], castBarColor[2], castBarColor[3], castBarColor[4])
  end
end
