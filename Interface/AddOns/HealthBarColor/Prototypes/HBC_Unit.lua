local _, addonTable = ...
local addon = addonTable.addon

--speed references
--WoW Api

--Lua
local math_min = math.min
local math_max = math.max
local math_ceil = math.ceil
--[[
  colorStart / colorEnd are used for Statusbar gradients while color is used when a gradient is not possible.
  Commented variables are expected to be added to a unit immediately after NewUnit() is called.
]]
local hbc_unit =
{
  UnitId = "player",
  isPlayer = true,
  class = "PRIEST",
  healthBarDesaturated = false,
  powerToken = "MANA",
  --healthBar
  --healthBarTexture
  --powerBar
  --powerBarTexture
  --nameText
  --healthTextLeft
  --healthTextMiddle
  --healthTextRight
  --powerBarTextLeft
  --powerBarTextMiddle
  --powerBarTextRight
  --frame
  healthBarPreparedForColoring = false,
}
hbc_unit.metatable = { __index = hbc_unit }

function addon:GetMetaUnit()
  return hbc_unit
end

function addon:NewUnit()
  local unit = setmetatable({}, hbc_unit.metatable)
  unit.updateFullCallbacks = {}
  unit.updateHealthCallbacks = {}
  unit.updatePowerCallbacks = {}
  return unit
end

--Fetch all the data the addon needs to know about a unit always called before hbc_unit:Update()
function hbc_unit:GetUnitDataFull()
  self.isPlayer = UnitIsPlayer(self.UnitId)
  if self.isPlayer then
    self.class = select(2, UnitClass(self.UnitId))
  end
  -- reaction
  local reaction = UnitReaction("player", self.UnitId)
  if reaction == 2 then
    self.reaction = "Hostile"
  elseif reaction == 4 then
    self.reaction = "Neutral"
  else
    self.reaction = "Friendly"
  end
  self:GetUnitPowerData(true)
  self:GetUnitHealthData()
end

local powerTypeIndex = addonTable.isClassic and 1 or 0
function hbc_unit:GetUnitPowerData(isFullUpdate)
  --powerColor
  local powerToken = select(2, UnitPowerType(self.UnitId, powerTypeIndex)) or "MANA"
  if self.powerToken == powerToken and not isFullUpdate then
    return true
  end
  self.powerToken = powerToken
end

--The Update function is called when a unit needs a full update, e.g. target changed / focus changed.
--Callbacks are added directly to the hbc_unit by accessing its callback table with ["key"] = callback.
function hbc_unit:FullUpdate()
  self:GetUnitDataFull()
  for _, callback in next, self.updateFullCallbacks do
    callback()
  end
  -- @TODO Change it so that all updatePowerCallbacks are also in updateFullCallbacks and remove.
  for _, callback in next, self.updatePowerCallbacks do
    callback()
  end
end

function hbc_unit:GetUnitHealthData()
  self.maxHealth = math_max(UnitHealthMax(self.UnitId), 1)
  self.currentHealth = UnitHealth(self.UnitId, false) or 1
  self.percentHealth = math_min(1, math_ceil((self.currentHealth / self.maxHealth) * 100) / 100) -- reduce to 2 decimals.
end

function hbc_unit:HealthUpdate()
  self:GetUnitHealthData()
  for _, callback in next, self.updateHealthCallbacks do
    callback()
  end
end

function hbc_unit:PowerUpdate()
  local skip = self:GetUnitPowerData()
  if skip then
    return
  end
  for _, callback in next, self.updatePowerCallbacks do
    callback()
  end
end

--[[
  The below functions are convenience functions to reduce code in the modules and being able to quickly
  adapt to changes made by Blizzard.
]]
function hbc_unit:PrepareHealthBarTexture()
  if addonTable.isRetail then
    local layer, sublayer = self.healthBarTexture:GetDrawLayer()
    for k, v in pairs(
    {
      self.overAbsorbGlow,
      self.tiledFillOverlay,
    }
    ) do
      v:SetDrawLayer(layer, ( sublayer + 1 ) )
    end
  end
end

function hbc_unit:PrepareHealthBarForColoring()
  self.healthBar:SetStatusBarDesaturated(true)
  if addonTable.isRetail then
    self:PrepareHealthBarTexture()
  end
  self.healthBarPreparedForColoring = true
end

if addonTable.isRetail then
  function hbc_unit:RestoreHealthBarToDefault()
    self.healthBarTexture:SetDesaturation(0)
    self.healthBar:SetStatusBarColor(1, 1, 1)
    self.healthBarPreparedForColoring = false
  end
else
  function hbc_unit:RestoreHealthBarToDefault()
    self.healthBar:SetStatusBarColor(0, 1, 0)
  end
end

function hbc_unit:RestorePowerBarToDefault()
  self.powerBarTexture:SetDesaturation(0)
  self.powerBar:SetStatusBarColor(1, 1, 1)
  self.powerBarPreparedForColoring = false
end

function hbc_unit:BlockHealthBarColorUpdate(state)
  hbc_unit.colorUpdateBlocked = state
end

function hbc_unit:SetHealthBarToCustomColor(startColor, endColor)
  if hbc_unit.colorUpdateBlocked then
    return
  end
  if not self.healthBarPreparedForColoring then
    self:PrepareHealthBarForColoring()
  end
  self.healthBarTexture:SetGradient("HORIZONTAL", startColor, endColor)
end

function hbc_unit:SetHealthBarToClassColor()
  if hbc_unit.colorUpdateBlocked then
    return
  end
  if not self.healthBarPreparedForColoring then
    self:PrepareHealthBarForColoring()
  end
  self.healthBarTexture:SetGradient("HORIZONTAL", addonTable.colorMixins.classColors[self.class].classColorStart, addonTable.colorMixins.classColors[self.class].classColorEnd)
end

function hbc_unit:SetHealthBarToDebuffColor(debuffType)
  self:BlockHealthBarColorUpdate(true)
  if not self.healthBarPreparedForColoring then
    self:PrepareHealthBarForColoring()
  end
  self.healthBarTexture:SetGradient("HORIZONTAL", addonTable.colorMixins.debuffColors[debuffType].debuffColorStart, addonTable.colorMixins.debuffColors[debuffType].debuffColorEnd)
end

function hbc_unit:SetHealthBarToReactionColor()
  if hbc_unit.colorUpdateBlocked then
    return
  end
  if not self.healthBarPreparedForColoring then
    self:PrepareHealthBarForColoring()
  end
  self.healthBarTexture:SetGradient("HORIZONTAL", addonTable.colorMixins.reactionColors[self.reaction].reactionColorStart, addonTable.colorMixins.reactionColors[self.reaction].reactionColorEnd)
end

function hbc_unit:SetHealthBarToHealthValueColor()
  if hbc_unit.colorUpdateBlocked then
    return
  end
  if not self.healthBarPreparedForColoring then
    self:PrepareHealthBarForColoring()
  end
  self.healthBarTexture:SetVertexColor(addon:GetHealthValueColor(self.percentHealth))
end

function hbc_unit:SetPowerBarColor()
  if addonTable.colorMixins.powerColors[self.powerToken] then
    self.powerBarTexture:SetGradient("HORIZONTAL", addonTable.colorMixins.powerColors[self.powerToken].powerColorStart, addonTable.colorMixins.powerColors[self.powerToken].powerColorEnd)
  else
    self.powerBarTexture:SetGradient("HORIZONTAL", addonTable.colorMixins.powerColors["MANA"].powerColorStart, addonTable.colorMixins.powerColors["MANA"].powerColorEnd)
  end
end

--Path to a texture.
function hbc_unit:SetHealthBarTexture(path)
  self.healthBar:SetStatusBarTexture(path)
  if addonTable.isRetail then
    self:PrepareHealthBarTexture()
  end
end

--Path to a texture.
function hbc_unit:SetPowerBarTexture(path)
  self.powerBar:SetStatusBarTexture(path)
end

--[[
  Name Text
  ]]

function hbc_unit:SetNameFont(font, fontSize, outlinemode)
  self.nameText:SetFont(font, fontSize, outlinemode)
end

function hbc_unit:SetNameToClassColor()
  local color = addonTable.classColors[self.class].classColor
  self.nameText:SetTextColor(color.r, color.g, color.b, color.a)
end

function hbc_unit:SetNameToReactionColor()
  local color = addonTable.reactionColors[self.reaction].reactionColor
  self.nameText:SetTextColor(color.r, color.g, color.b, color.a)
end

function hbc_unit:SetNameToCustomColor(color)
  self.nameText:SetTextColor(color.r, color.g, color.b, color.a)
end

--[[
  Health Text
  ]]

function hbc_unit:SetHealthTextFont(font, fontSize, outlinemode)
  for _, text in pairs(
    {
      self.healthTextLeft,
      self.healthTextMiddle,
      self.healthTextRight
    }
  ) do
    text:SetFont(font, fontSize, outlinemode)
  end
end

function hbc_unit:SetHealthTextToClassColor()
  local color = addonTable.classColors[self.class].classColor
  for _, text in pairs(
    {
      self.healthTextLeft,
      self.healthTextMiddle,
      self.healthTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

function hbc_unit:SetHealthTextToReactionColor()
  local color = addonTable.reactionColors[self.reaction].reactionColor
  for _, text in pairs(
    {
      self.healthTextLeft,
      self.healthTextMiddle,
      self.healthTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

function hbc_unit:SetHealthTextToCustomColor(color)
  for _, text in pairs(
    {
      self.healthTextLeft,
      self.healthTextMiddle,
      self.healthTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

--[[
  Power Text
  ]]

function hbc_unit:SetPowerTextFont(font, fontSize, outlinemode)
  for _, text in pairs(
    {
      self.powerBarTextLeft,
      self.powerBarTextMiddle,
      self.powerBarTextRight
    }
  ) do
    text:SetFont(font, fontSize, outlinemode)
  end
end

function hbc_unit:SetPowerTextToClassColor()
  local color = addonTable.classColors[self.class].classColor
  for _, text in pairs(
    {
      self.powerBarTextLeft,
      self.powerBarTextMiddle,
      self.powerBarTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

function hbc_unit:SetPowerTextToReactionColor()
  local color = addonTable.reactionColors[self.reaction].reactionColor
  for _, text in pairs(
    {
      self.powerBarTextLeft,
      self.powerBarTextMiddle,
      self.powerBarTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

function hbc_unit:SetPowerTextToPowerColor()
  local color = addonTable.powerColors[self.powerToken].powerColor
  for _, text in pairs(
    {
      self.powerBarTextLeft,
      self.powerBarTextMiddle,
      self.powerBarTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

function hbc_unit:SetPowerTextToCustomColor(color)
  for _, text in pairs(
    {
      self.powerBarTextLeft,
      self.powerBarTextMiddle,
      self.powerBarTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

--[[
  Alternate Power Text
  This currently only affects the PlayerFrame
  ]]

function hbc_unit:SetAlternatePowerTextFont(font, fontSize, outlinemode)
  for _, text in pairs(
    {
      self.alternatePowerBarTextLeft,
      self.alternatePowerBarTextMiddle,
      self.alternatePowerBarTextRight
    }
  ) do
    text:SetFont(font, fontSize, outlinemode)
  end
end

function hbc_unit:SetAlternatePowerTextToAlternatePowerColor()
  for _, text in pairs(
    {
      self.alternatePowerBarTextLeft,
      self.alternatePowerBarTextMiddle,
      self.alternatePowerBarTextRight
    }
  ) do
    text:SetTextColor(self.alternatePowerColor.r, self.alternatePowerColor.g, self.alternatePowerColor.b, self.alternatePowerColor.a)
  end
end

function hbc_unit:SetAlternatePowerTextToCustomColor(color)
  for _, text in pairs(
    {
      self.alternatePowerBarTextLeft,
      self.alternatePowerBarTextMiddle,
      self.alternatePowerBarTextRight
    }
  ) do
    text:SetTextColor(color.r, color.g, color.b, color.a)
  end
end

--Glow
function hbc_unit:SetGlowToClassColor()
  local color = addonTable.classColors[self.class].classColor
  self.glowTexture:SetVertexColor(color.r, color.g, color.b, color.a)
end

function hbc_unit:SetGlowToReactionColor()
  local color = addonTable.reactionColors[self.reaction].reactionColor
  self.glowTexture:SetVertexColor(color.r, color.g, color.b, color.a)
end

function hbc_unit:SetGlowToCustomColor(color)
  self.glowTexture:SetVertexColor(color.r, color.g, color.b, color.a)
end
