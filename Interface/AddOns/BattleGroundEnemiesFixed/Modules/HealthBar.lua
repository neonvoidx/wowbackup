---@type string
local AddonName = ...
---@class Data
local Data = select(2, ...)
---@class BattleGroundEnemies
local BattleGroundEnemies = BattleGroundEnemies
local LSM = LibStub("LibSharedMedia-3.0")
local L = Data.L

local CompactUnitFrame_UpdateHealPrediction = CompactUnitFrame_UpdateHealPrediction

local HealthTextTypes = {
  health = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_HEALTH,
  losthealth = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_LOSTHEALTH,
  perc = COMPACT_UNIT_FRAME_PROFILE_HEALTHTEXT_PERC,
}

local generalDefaults = {
  Texture = "Solid",
  Background = { 0, 0, 0, 0.66 },
  HealthPrediction_Enabled = true,
}

local defaultSettings = {
  Parent = "Button",
  Enabled = true,
  ActivePoints = 1,
  Height = 30,
  Points = {
    {
      Point = "TOP",
      RelativeFrame = "Button",
      RelativePoint = "TOP",
    },
  },
  UseButtonWidthAsWidth = true,
}

local healthTextDefaultSettings = {
  Parent = "Button",
  Enabled = true,
  HealthTextType = "health",
  FontSize = 17,
  JustifyH = "RIGHT",
  JustifyV = "MIDDLE",
  ActivePoints = 1,
  Points = {
    {
      Point = "RIGHT",
      RelativeFrame = "healthBar",
      RelativePoint = "RIGHT",
      OffsetX = -4,
    },
  },
  Width = 500,
  UseButtonWidthAsWidth = true,
  UseButtonHeightAsHeight = true,
}

local generalOptions = function(location)
  return {
    Texture = {
      type = "select",
      name = L.BarTexture,
      desc = L.HealthBar_Texture_Desc,
      dialogControl = "LSM30_Statusbar",
      values = AceGUIWidgetLSMlists.statusbar,
      width = "normal",
      order = 1,
    },
    Background = {
      type = "color",
      name = L.BarBackground,
      desc = L.HealthBar_Background_Desc,
      hasAlpha = true,
      width = "normal",
      order = 2,
    },
    HealthPrediction_Enabled = {
      type = "toggle",
      name = COMPACT_UNIT_FRAME_PROFILE_DISPLAYHEALPREDICTION,
      width = "full",
      order = 3,
    },
  }
end

local options = function(location)
  return {}
end

local healthTextOptions = function(location)
  return {
    General = {
      type = "group",
      name = L.General,
      order = 1,
      args = {
        HealthTextType = {
          type = "select",
          name = L.HealthTextType,
          width = "normal",
          values = HealthTextTypes,
          order = 1,
        },
        TextSettings = {
          type = "group",
          name = L.HealthTextSettings,
          get = function(option)
            return Data.GetOption(location, option)
          end,
          set = function(option, ...)
            return Data.SetOption(location, option, ...)
          end,
          inline = true,
          order = 2,
          args = Data.AddNormalTextSettings(location),
        },
      },
    },
    HealthTextPosition = {
      type = "group",
      name = L.Position .. " " .. L.AND .. " " .. L.Size,
      get = function(option)
        return Data.GetOption(location, option)
      end,
      set = function(option, ...)
        return Data.SetOption(location, option, ...)
      end,
      order = 2,
      args = Data.AddPositionSetting(
        location,
        "healthBarText",
        BattleGroundEnemies.ButtonModules.healthBarText,
        "Enemies"
      ),
    },
  }
end

local healthBar = BattleGroundEnemies:NewButtonModule({
  moduleName = "healthBar",
  localizedModuleName = L.HealthBar,
  defaultSettings = defaultSettings,
  generalDefaults = generalDefaults,
  options = options,
  generalOptions = generalOptions,
  events = { "UpdateHealth" },
  flags = {},
  enabledInThisExpansion = true,
  attachSettingsToButton = false,
  order = 1,
})

local healthBarText = BattleGroundEnemies:NewButtonModule({
  moduleName = "healthBarText",
  localizedModuleName = L.HealthTextSettings,
  defaultSettings = healthTextDefaultSettings,
  options = healthTextOptions,
  events = { "UpdateHealth" },
  enabledInThisExpansion = true,
  attachSettingsToButton = false,
  order = 1.1, -- This will sort it right after Healthbar
})

function healthBar:AttachToPlayerButton(playerButton)
  playerButton.healthBar = CreateFrame("StatusBar", nil, playerButton)
  playerButton.healthBar:SetMinMaxValues(0, 1)

  -- Changed to StatusBar to handle Secret/Restricted Health Values securely
  playerButton.myHealPrediction = CreateFrame("StatusBar", nil, playerButton.healthBar)
  playerButton.myHealPrediction:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  playerButton.myHealPrediction:GetStatusBarTexture():SetVertexColor(0.0, 0.659, 0.608)
  playerButton.myHealPrediction:SetFrameLevel(playerButton.healthBar:GetFrameLevel() + 1)

  -- Gradient Logic on the StatusBarTexture
  local predTex = playerButton.myHealPrediction:GetStatusBarTexture()
  if predTex.SetGradientAlpha then
    predTex:SetGradient("VERTICAL", 8 / 255, 93 / 255, 72 / 255, 11 / 255, 136 / 255, 105 / 255)
  else
    predTex:SetGradient(
      "VERTICAL",
      CreateColor(8 / 255, 93 / 255, 72 / 255, 1),
      CreateColor(11 / 255, 136 / 255, 105 / 255, 1)
    )
  end

  -- Fix for 11.0+ / 12.0.0 CompactUnitFrame compatibility
  -- Blizzard's UpdateHealPrediction expects this value to exist for height calculations
  playerButton.powerBarUsedHeight = 0

  playerButton.myHealAbsorb = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 3)
  playerButton.myHealAbsorb:ClearAllPoints()
  playerButton.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true)

  playerButton.myHealAbsorbLeftShadow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 3)
  playerButton.myHealAbsorbLeftShadow:ClearAllPoints()

  playerButton.myHealAbsorbRightShadow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 3)
  playerButton.myHealAbsorbRightShadow:ClearAllPoints()

  playerButton.otherHealPrediction = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
  playerButton.otherHealPrediction:SetColorTexture(1, 1, 1)
  if playerButton.otherHealPrediction.SetGradientAlpha then
    playerButton.otherHealPrediction:SetGradient("VERTICAL", 11 / 255, 53 / 255, 43 / 255, 21 / 255, 89 / 255, 72 / 255)
  else
    playerButton.otherHealPrediction:SetGradient(
      "VERTICAL",
      CreateColor(11 / 255, 53 / 255, 43 / 255, 1),
      CreateColor(21 / 255, 89 / 255, 72 / 255, 1)
    )
  end

  playerButton.totalAbsorbOverlay = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 4)
  playerButton.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true) --Tile both vertically and horizontally
  playerButton.totalAbsorbOverlay.tileSize = 20

  playerButton.totalAbsorb = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 3)
  playerButton.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill")
  playerButton.totalAbsorb.overlay = playerButton.totalAbsorbOverlay
  playerButton.totalAbsorbOverlay:SetAllPoints(playerButton.totalAbsorb)

  playerButton.overAbsorbGlow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
  playerButton.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
  playerButton.overAbsorbGlow:SetBlendMode("ADD")
  playerButton.overAbsorbGlow:SetPoint("BOTTOMLEFT", playerButton.healthBar, "BOTTOMRIGHT", -7, 0)
  playerButton.overAbsorbGlow:SetPoint("TOPLEFT", playerButton.healthBar, "TOPRIGHT", -7, 0)
  playerButton.overAbsorbGlow:SetWidth(16)
  playerButton.overAbsorbGlow:Hide()

  playerButton.overHealAbsorbGlow = playerButton.healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
  playerButton.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
  playerButton.overHealAbsorbGlow:SetBlendMode("ADD")
  playerButton.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", playerButton.healthBar, "BOTTOMLEFT", 7, 0)
  playerButton.overHealAbsorbGlow:SetPoint("TOPRIGHT", playerButton.healthBar, "TOPLEFT", 7, 0)
  playerButton.overHealAbsorbGlow:SetWidth(16)
  playerButton.overHealAbsorbGlow:Hide()

  playerButton.healthBar.Background = playerButton.healthBar:CreateTexture(nil, "BACKGROUND", nil, 2)
  playerButton.healthBar.Background:SetAllPoints()
  playerButton.healthBar.Background:SetTexture("Interface/Buttons/WHITE8X8")

  function playerButton.healthBar:UpdateHealth(unitID, health, healthMissing, healthPercent, maxHealth)
    -- Safety for nil values (can happen with secret units or delayed rosters)
    -- Safety: Fetch live health if arguments are missing (e.g. triggered by Absorb event)
    if not health and unitID then
      health = UnitHealth(unitID)
    end
    if not healthMissing and unitID then
      healthMissing = UnitHealthMissing(unitID)
    end
    if not healthPercent and unitID then
      healthPercent = UnitHealthPercent(unitID, true, CurveConstants.ScaleTo100)
    end
    if not maxHealth and unitID then
      maxHealth = UnitHealthMax(unitID)
    end

    health = health or 0
    healthMissing = healthMissing or 0
    healthPercent = healthPercent or 0
    maxHealth = maxHealth or 1

    -- If we have marked this player as dead manually, force health to 0 and ignore update
    if playerButton.isDead then
      self:SetMinMaxValues(0, maxHealth)
      self:SetValue(0)
      if playerButton.myHealPrediction then
        playerButton.myHealPrediction:Hide()
      end
      return
    end

    self:SetMinMaxValues(0, maxHealth)
    self:SetValue(health)

    -- Custom Secure Prediction Update
    if unitID and playerButton.myHealPrediction then
      local myIncomingHeal = 0
      if UnitGetIncomingHeals then
        local okH, val = pcall(UnitGetIncomingHeals, unitID, "player")
        if okH and type(val) == "number" then
          -- Validate it's not a secret impersonator (Restricted Number)
          local okMath = pcall(function()
            return val + 0
          end)
          if okMath then
            myIncomingHeal = val
          end
        end
      end

      if myIncomingHeal > 0 then
        playerButton.myHealPrediction:Show()
        playerButton.myHealPrediction:SetMinMaxValues(0, maxHealth)
        playerButton.myHealPrediction:SetValue(myIncomingHeal)
        playerButton.myHealPrediction:SetWidth(self:GetWidth()) -- Allow it to scale up to full width

        -- Anchor to the RIGHT edge of the current Health texture
        playerButton.myHealPrediction:ClearAllPoints()
        local mainTex = self:GetStatusBarTexture()
        if mainTex then
          playerButton.myHealPrediction:SetPoint("TOPLEFT", mainTex, "TOPRIGHT", 0, 0)
          playerButton.myHealPrediction:SetPoint("BOTTOMLEFT", mainTex, "BOTTOMRIGHT", 0, 0)
        else
          -- Fallback if texture is missing (health=0)
          playerButton.myHealPrediction:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
          playerButton.myHealPrediction:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
        end
      else
        playerButton.myHealPrediction:Hide()
      end
      -- Note: Skipping CompactUnitFrame_UpdateHealPrediction to avoid Secret Value crash
    end
  end

  function playerButton.healthBar:ApplyAllSettings()
    if not self.config then
      return
    end
    local config = self.config
    self:SetStatusBarTexture(LSM:Fetch("statusbar", config.Texture))
    self.Background:SetVertexColor(unpack(config.Background))

    local playerDetails = playerButton.PlayerDetails
    if not playerDetails then
      return
    end
    local color = playerDetails.PlayerClassColor
    self:SetStatusBarColor(color.r, color.g, color.b)
  end
  return playerButton.healthBar
end

function healthBarText:AttachToPlayerButton(playerButton)
  local container = CreateFrame("Frame", nil, playerButton)
  container:SetSize(60, 20)
  container:SetFrameLevel(playerButton:GetFrameLevel() + 20) -- Ensure it's clickable

  container.fs = BattleGroundEnemies.MyCreateFontString(container)
  container.fs:SetWordWrap(false)
  container.fs:SetAllPoints()

  container.GetOptionsPath = function(self)
    local optionsPath = CopyTable(playerButton.basePath)
    table.insert(optionsPath, "ModuleSettings")
    table.insert(optionsPath, "healthBarText")
    return optionsPath
  end

  container.GetConfig = function(self)
    local modules = playerButton.playerCountConfig.ButtonModules
    if not modules.healthBarText then
      modules.healthBarText = CopyTable(healthTextDefaultSettings)
    end
    return modules.healthBarText
  end

  function container:UpdateHealthText(unitID, health, healthMissing, healthPercent, maxHealth)
    local config = self.config
    if not config or not config.Enabled then
      self.fs:Hide()
      return
    end

    local ok, err = pcall(function()
      -- Test mode: Use fake health values (old math-based approach works here)
      if BattleGroundEnemies:IsTestmodeOrEditmodeActive() then
        if not health or not maxHealth then
          health = 50000
          healthPercent = 50
          healthMissing = 50000
          maxHealth = 100000
        end
      end

      if health and maxHealth then
        if config.HealthTextType == "health" then
          health = AbbreviateNumbers(health)
          self.fs:SetText(health)
          self.fs:Show()
        elseif config.HealthTextType == "losthealth" then
          healthMissing = AbbreviateNumbers(healthMissing)
          self.fs:SetText(healthMissing)
          self.fs:Show()
        elseif config.HealthTextType == "perc" then
          self.fs:SetFormattedText("%d%%", healthPercent)
          self.fs:Show()
        else
          self.fs:Hide()
        end
      else
        self.fs:Hide()
      end
    end)

    if not ok then
      -- Verification failed (likely secret value math), hide text
      self.fs:Hide()
    end
  end

  function container:UpdateHealth(unitID, health, healthMissing, healthPercent, maxHealth)
    self:UpdateHealthText(unitID, health, healthMissing, healthPercent, maxHealth)
  end

  function container:ApplyAllSettings()
    if not self.config then
      return
    end
    local config = self.config

    -- Force default for existing profiles
    if config.UseButtonWidthAsWidth == nil then
      config.UseButtonWidthAsWidth = true
    end

    -- Migration Logic: If this is a new setup, try to copy from the old healthBar.HealthText sub-table
    local oldBarConfig = playerButton.healthBar and playerButton.healthBar.config
    if oldBarConfig and oldBarConfig.HealthText and not self.hasMigrated then
      -- Only migrate if the new config matches defaults (meaning it hasn't been touched yet)
      if config.FontSize == healthTextDefaultSettings.FontSize then
        Mixin(config, oldBarConfig.HealthText)
        self.hasMigrated = true
      end
    end

    if config.Enabled then
      self.fs:Show()
    else
      self.fs:Hide()
    end

    self.fs:ApplyFontStringSettings(config)

    self:ClearAllPoints()
    for j = 1, config.ActivePoints or 1 do
      local pointConfig = config.Points[j]
      if pointConfig and pointConfig.RelativeFrame then
        local relativeFrame = playerButton:GetAnchor(pointConfig.RelativeFrame)
        if relativeFrame then
          local effectiveScale = self:GetEffectiveScale()
          self:SetPoint(
            pointConfig.Point,
            relativeFrame,
            pointConfig.RelativePoint,
            (pointConfig.OffsetX or 0) / effectiveScale,
            (pointConfig.OffsetY or 0) / effectiveScale
          )
        end
      end
    end
    if config.Parent then
      self:SetParent(playerButton:GetAnchor(config.Parent))
    end
    local width = config.Width or 500
    if config.UseButtonHeightAsWidth then
      width = playerButton:GetHeight()
    elseif config.UseButtonWidthAsWidth then
      width = (playerButton.playerCountConfig and playerButton.playerCountConfig.BarWidth) or playerButton:GetWidth()
    end

    local height = config.Height or 20
    if config.UseButtonHeightAsHeight then
      height = playerButton:GetHeight()
    end

    self:SetSize(width, height)

    if self.AnchorSelectionFrame then
      self:AnchorSelectionFrame()
    end

    self:UpdateHealthText(nil, nil, nil, nil, nil)
  end

  playerButton.healthBarText = container
  return playerButton.healthBarText
end
