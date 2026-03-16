---@type string
local AddonName = ...
---@class Data
local Data = select(2, ...)
---@class BattleGroundEnemies
local BattleGroundEnemies = BattleGroundEnemies
local L = Data.L
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local GetClassAtlas = GetClassAtlas

local locTypePriority = {
  STUN = 8,
  STUN_MECHANIC = 8,
  FEAR = 7,
  FEAR_MECHANIC = 7,
  DISORIENT = 7,
  CONFUSE = 7,
  INCAPACITATE = 6,
  SILENCE = 5,
  PACIFYSILENCE = 5,
  ROOT = 3,
  PACIFY = 2,
  DISARM = 2,
  POSSESS = 9,
}

local generalDefaults = {
  showSpecIfExists = true,
  showHighestPriority = true,
}

local defaultSettings = {
  Enabled = true,
  Parent = "Button",
  Cooldown = {
    ShowNumber = true,
    FontSize = 12,
    FontOutline = "OUTLINE",
    EnableShadow = false,
    DrawSwipe = true,
    ShadowColor = { 0, 0, 0, 1 },
  },
  Width = 36,
  ActivePoints = 1,
  Points = {
    {
      Point = "TOPRIGHT",
      RelativeFrame = "Button",
      RelativePoint = "TOPLEFT",
    },
  },
  UseButtonHeightAsHeight = true,
}

local generalOptions = function(location)
  return {
    showSpecIfExists = {
      type = "toggle",
      name = L.ShowSpecIfExists,
      desc = L.ShowSpecIfExists_Desc,
      width = "full",
      order = 1,
    },
    showHighestPriority = {
      type = "toggle",
      name = L.ShowHighestPriority,
      desc = L.ShowHighestPriority_Desc,
      width = "full",
      order = 2,
    },
  }
end

local options = function(location)
  return {
    CooldownTextSettings = {
      type = "group",
      name = L.Countdowntext,
      inline = true,
      get = function(option)
        return Data.GetOption(location.Cooldown, option)
      end,
      set = function(option, ...)
        return Data.SetOption(location.Cooldown, option, ...)
      end,
      order = 3,
      args = Data.AddCooldownSettings(location.Cooldown),
    },
  }
end

local SpecClassPriority = BattleGroundEnemies:NewButtonModule({
  moduleName = "SpecClassPriority",
  localizedModuleName = L.SpecClassPriority,
  defaultSettings = defaultSettings,
  generalDefaults = generalDefaults,
  options = options,
  generalOptions = generalOptions,
  events = {
    "GotInterrupted",
    "UnitDied",
  },
  enabledInThisExpansion = true,
  flags = {
    SetZeroWidthWhenDisabled = true,
  },
})

local function attachToPlayerButton(playerButton)
  local frame = CreateFrame("frame", nil, playerButton)
  frame.Background = frame:CreateTexture(nil, "BACKGROUND")
  frame.Background:SetAllPoints()
  frame.Background:SetColorTexture(0, 0, 0, 0.8)
  frame.PriorityAuras = {}
  frame.ActiveInterrupt = false
  frame.ShowsSpec = false
  frame.SpecClassIcon = frame:CreateTexture(nil, "BORDER", nil, 2)
  frame.SpecClassIcon:SetAllPoints()
  frame.PriorityIcon = frame:CreateTexture(nil, "BORDER", nil, 3)
  frame.PriorityIcon:SetAllPoints()
  frame.Cooldown = BattleGroundEnemies.MyCreateCooldown(frame)
  frame.Cooldown:SetScript("OnCooldownDone", function(self)
    frame:Update()
  end)

  frame:HookScript("OnLeave", function(self)
    if GameTooltip:IsOwned(self) then
      GameTooltip:Hide()
    end
  end)

  frame:HookScript("OnEnter", function(self)
    BattleGroundEnemies:ShowTooltip(self, function()
      if frame.DisplayedAura and frame.DisplayedAura.spellId then
        GameTooltip:SetSpellByID(frame.DisplayedAura.spellId)
      elseif not frame.DisplayedAura then
        local playerDetails = playerButton.PlayerDetails
        if not playerDetails.PlayerClass then
          return
        end
        local numClasses = GetNumClasses()
        local localizedClass
        for i = 1, numClasses do -- we could also just save the localized class name it into the button itself, but since its only used for this tooltip no need for that
          local className, classFile, classID = GetClassInfo(i)
          if classFile and classFile == playerDetails.PlayerClass then
            localizedClass = className
          end
        end
        if not localizedClass then
          return
        end

        if playerDetails.PlayerSpecName then
          GameTooltip:SetText(localizedClass .. " " .. playerDetails.PlayerSpecName)
        else
          return GameTooltip:SetText(localizedClass)
        end
      end
    end)
  end)

  frame:SetScript("OnSizeChanged", function(self, width, height)
    self:CropImage()
  end)

  frame:Hide()

  function frame:MakeSureWeAreOnTop()
    if true then
      return
    end
    local numPoints = self:GetNumPoints()
    local highestLevel = 0
    for i = 1, numPoints do
      local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(i)
      if relativeTo then
        local level = relativeTo:GetFrameLevel()
        if level and level > highestLevel then
          highestLevel = level
        end
      end
    end
    self:SetFrameLevel(highestLevel + 1)
  end

  function frame:Update()
    self:MakeSureWeAreOnTop()
    local highestPrioritySpell
    local currentTime = GetTime()

    local priorityAuras = self.PriorityAuras
    for i = 1, #priorityAuras do
      local priorityAura = priorityAuras[i]
      if priorityAura.expirationTime > currentTime then
        if not highestPrioritySpell or (priorityAura.Priority > highestPrioritySpell.Priority) then
          highestPrioritySpell = priorityAura
        end
      end
    end
    if frame.ActiveInterrupt then
      if frame.ActiveInterrupt.expirationTime < currentTime then
        frame.ActiveInterrupt = false
      else
        if not highestPrioritySpell or (frame.ActiveInterrupt.Priority > highestPrioritySpell.Priority) then
          highestPrioritySpell = frame.ActiveInterrupt
        end
      end
    end

    if highestPrioritySpell then
      frame.SpecClassIcon:Hide()
      frame.DisplayedAura = highestPrioritySpell
      frame.PriorityIcon:Show()
      frame.PriorityIcon:SetTexture(highestPrioritySpell.icon)
      frame.Cooldown:SetCooldown(
        highestPrioritySpell.expirationTime - highestPrioritySpell.duration,
        highestPrioritySpell.duration
      )
    else
      frame.SpecClassIcon:Show()
      frame.DisplayedAura = false
      frame.PriorityIcon:Hide()
      frame.Cooldown:Clear()
    end
  end

  function frame:ResetPriorityData()
    self.ActiveInterrupt = false
    wipe(self.PriorityAuras)
    if self._locExpiryTimer then
      self._locExpiryTimer:Cancel()
      self._locExpiryTimer = nil
    end
    self:Update()
  end

  function frame:GotInterrupted(spellId, interruptDuration)
    self.ActiveInterrupt = {
      spellId = spellId,
      icon = GetSpellTexture(spellId),
      expirationTime = GetTime() + interruptDuration,
      duration = interruptDuration,
      Priority = BattleGroundEnemies:GetSpellPriority(spellId) or 4,
    }
    self:Update()
  end

  function frame:UpdateLossOfControl(unitID)
    if not self.config or not self.config.showHighestPriority then
      return
    end
    wipe(self.PriorityAuras)
    local highestRemaining = 0
    local hasSecretTiming = false
    local count = C_LossOfControl.GetActiveLossOfControlDataCountByUnit(unitID) or 0
    for i = 1, count do
      local data = C_LossOfControl.GetActiveLossOfControlDataByUnit(unitID, i)
      if data and data.locType and not issecretvalue(data.locType) and data.locType ~= "SCHOOL_INTERRUPT" then
        local priority = locTypePriority[data.locType]
        if priority then
          -- 12.0: timeRemaining/duration/spellID/iconTexture can be secret values.
          -- Use auraInstanceID (NeverSecret) to get non-secret aura data.
          local icon, duration, expirationTime
          if data.auraInstanceID then
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unitID, data.auraInstanceID)
            if auraData then
              icon = auraData.icon
              -- 12.0: auraData fields can also be secret — guard before arithmetic
              if auraData.expirationTime and auraData.duration
                and not issecretvalue(auraData.expirationTime)
                and not issecretvalue(auraData.duration) then
                duration = auraData.duration
                expirationTime = auraData.expirationTime
              else
                hasSecretTiming = true
              end
            end
          end
          -- Fallback: try LoC fields directly if auraInstanceID didn't work
          if not expirationTime and not hasSecretTiming then
            local ok, remaining, dur = pcall(function()
              local r = data.timeRemaining or 0
              local d = data.duration or r
              return r + 0, d + 0
            end)
            if ok and remaining and remaining > 0 then
              local currentTime = GetTime()
              expirationTime = currentTime + remaining
              duration = dur
              icon = icon or data.iconTexture or GetSpellTexture(data.spellID)
            else
              hasSecretTiming = true
            end
          end
          if not icon then
            icon = data.iconTexture or GetSpellTexture(data.spellID)
          end
          if expirationTime and duration then
            local remaining = expirationTime - GetTime()
            if remaining > 0 then
              if remaining > highestRemaining then
                highestRemaining = remaining
              end
              self.PriorityAuras[#self.PriorityAuras + 1] = {
                spellId = data.spellID,
                icon = icon,
                expirationTime = expirationTime,
                duration = duration,
                Priority = priority,
              }
            end
          elseif hasSecretTiming then
            -- Secret values prevented timing — add with dummy timing so icon shows
            self.PriorityAuras[#self.PriorityAuras + 1] = {
              spellId = data.spellID,
              icon = icon,
              expirationTime = GetTime() + 30,
              duration = 30,
              Priority = priority,
            }
          end
        end
      end
    end

    -- Cancel any pending expiry timer
    if self._locExpiryTimer then
      self._locExpiryTimer:Cancel()
      self._locExpiryTimer = nil
    end

    if hasSecretTiming and #self.PriorityAuras > 0 then
      -- Can't compute exact expiry — poll every second until CC clears
      self._locExpiryTimer = C_Timer.NewTicker(1, function(ticker)
        local activeCount = C_LossOfControl.GetActiveLossOfControlDataCountByUnit(unitID) or 0
        local stillActive = false
        for j = 1, activeCount do
          local d = C_LossOfControl.GetActiveLossOfControlDataByUnit(unitID, j)
          if d and d.locType and not issecretvalue(d.locType) and d.locType ~= "SCHOOL_INTERRUPT" and locTypePriority[d.locType] then
            stillActive = true
            break
          end
        end
        if not stillActive then
          ticker:Cancel()
          self._locExpiryTimer = nil
          wipe(self.PriorityAuras)
          self:Update()
        end
      end)
    elseif highestRemaining > 0 then
      -- Schedule re-check after the longest CC should expire
      self._locExpiryTimer = C_Timer.NewTimer(highestRemaining + 0.1, function()
        self._locExpiryTimer = nil
        self:Update()
      end)
    end

    self:Update()
  end

  function frame:UnitDied()
    self:ResetPriorityData()
  end

  frame.CropImage = function(self)
    local width = self:GetWidth()
    local height = self:GetHeight()
    if width and height and width > 0 and height > 0 then
      if self.ShowsSpec then
        BattleGroundEnemies.CropImage(self.SpecClassIcon, width, height)
      end
      BattleGroundEnemies.CropImage(self.PriorityIcon, width, height)
    end
  end

  frame.ApplyAllSettings = function(self)
    if not self.config then
      return
    end
    local moduleSettings = self.config
    self:Show()
    local playerDetails = playerButton.PlayerDetails
    if not playerDetails then
      return
    end
    self.ShowsSpec = false

    local specData = playerButton:GetSpecData()
    if specData and self.config.showSpecIfExists then
      self.SpecClassIcon:SetTexture(specData.specIcon)
      self.ShowsSpec = true
    else
      local classIconAtlas = GetClassAtlas and GetClassAtlas(playerDetails.PlayerClass)
      if classIconAtlas then
        self.SpecClassIcon:SetAtlas(classIconAtlas)
      else
        local coords = CLASS_ICON_TCOORDS[playerDetails.PlayerClass]
        if playerDetails.PlayerClass and coords then
          self.SpecClassIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
          self.SpecClassIcon:SetTexCoord(unpack(coords))
        else
          self.SpecClassIcon:SetTexture(nil)
        end
      end
    end
    self:CropImage()
    self.Cooldown:ApplyCooldownSettings(moduleSettings.Cooldown, true, { 0, 0, 0, 0.5 })
    if not moduleSettings.showHighestPriority then
      self:ResetPriorityData()
    end
    self:MakeSureWeAreOnTop()
  end
  return frame
end

function SpecClassPriority:AttachToPlayerButton(playerButton)
  playerButton.SpecClassPriority = attachToPlayerButton(playerButton)
  return playerButton.SpecClassPriority
end
