--[[
  colorModes health basic:
  1 = class
  2 = blizzard green
  3 = custom
  4 = Health Value
]]
local _, addonTable = ...
local addon = addonTable.addon
local Media = LibStub("LibSharedMedia-3.0")

local module = addon:NewModule("PersonalResourceDisplay")
Mixin(module, addonTable.hooks)

local health_texture = PersonalResourceDisplayFrame.HealthBarsContainer.healthBar.barTexture
local power_texture = PersonalResourceDisplayFrame.PowerBar.Texture

-- health bar
local function set_health_texture(path)
  health_texture:SetTexture(path)
end

-- class
local function set_health_bar_to_class_color()
  health_texture:SetGradient("HORIZONTAL", addonTable.colorMixins.classColors[addonTable.playerClass].classColorStart, addonTable.colorMixins.classColors[addonTable.playerClass].classColorEnd)
end

-- green
local function set_health_bar_to_default_color()
  health_texture:SetVertexColor(0, 0.8, 0, 1)
end

-- custom
local function set_health_bar_to_custom_color(startColor, endColor)
  health_texture:SetGradient("HORIZONTAL", startColor, endColor)
end

-- health value
local function set_health_bar_to_health_value_color()
  local color = UnitHealthPercent("player", true, addonTable.healthColorCurve)
  health_texture:SetVertexColor(color:GetRGB())
end

-- power bar
local function set_power_texture(path)
  power_texture:SetTexture(path)
end

local function set_power_bar_to_power_color(powerToken)
  local powerColor = addonTable.colorMixins.powerColors[powerToken] or addonTable.colorMixins.powerColors["MANA"]
  power_texture:SetGradient("HORIZONTAL", powerColor.powerColorStart, powerColor.powerColorEnd)
end

function module:OnEnable()
  -- PersonalResourceDisplayFrame.HealthBarsContainer:SetHeight(100) @TODO works, add size settings.
  local dbObj = CopyTable(addon.db.profile["PersonalResourceDisplay"])
  local pathToHealthBarTexture = Media:Fetch("statusbar", dbObj.healthBarTexture)
  local pathToPowerBarTexture = Media:Fetch("statusbar", dbObj.powerBarTexture)
  local hbc_unit = addon:GetUnit("player")
  -- Set textues
  set_health_texture(pathToHealthBarTexture)
  set_power_texture(pathToPowerBarTexture)
  -- Set the health bar color
  local health_bar_color_callback = function () end
  if dbObj.colorMode == 1 then
    set_health_bar_to_class_color()
    health_bar_color_callback = set_health_bar_to_class_color
  elseif dbObj.colorMode == 2 then
    set_health_bar_to_default_color()
    health_bar_color_callback = set_health_bar_to_default_color
  elseif dbObj.colorMode == 3 then
    local startColor = CreateColor(dbObj.customColorStart.r, dbObj.customColorStart.g, dbObj.customColorStart.b, dbObj.customColorStart.a)
    local endColor = CreateColor(dbObj.customColorEnd.r, dbObj.customColorEnd.g, dbObj.customColorEnd.b, dbObj.customColorEnd.a)
    set_health_bar_to_custom_color(startColor, endColor)
    health_bar_color_callback = function ()
      set_health_bar_to_custom_color(startColor, endColor)
    end
  else  -- 4
    hbc_unit.updateFullCallbacks["update_personal_resource_display_health_bar_color"] = function()
      set_health_bar_to_health_value_color()
    end
    hbc_unit.updateHealthCallbacks["update_personal_resource_display_health_bar_color"] = function()
      set_health_bar_to_health_value_color()
    end
    hbc_unit.eventFrame:RegisterUnitEvent("UNIT_HEALTH", hbc_unit.UnitId)
    set_health_bar_to_health_value_color()
    health_bar_color_callback = set_health_bar_to_health_value_color
  end
  self:HookFunc(PersonalResourceDisplayFrame, "SetupHealthBar", health_bar_color_callback)
  -- Set power bar color
  hbc_unit.updatePowerCallbacks["update_personal_resource_display_power_bar_color"] = function ()
    set_power_bar_to_power_color(hbc_unit.powerToken)
  end
  set_power_bar_to_power_color(hbc_unit.powerToken)
  self:HookFunc(PersonalResourceDisplayFrame, "SetupPowerBar", function()
    set_power_bar_to_power_color(hbc_unit.powerToken)
  end)
end

function module:OnDisable()
  self:DisableHooks()
  local default_textue = Media:Fetch("statusbar", "Blizzard")
  set_health_texture(default_textue)
  set_health_bar_to_default_color()
  set_power_texture(default_textue)
  -- Remove callbacks
  local hbc_unit = addon:GetUnit("player")
  hbc_unit.updateFullCallbacks["update_personal_resource_display_health_bar_color"] = nil
  hbc_unit.updateHealthCallbacks["update_personal_resource_display_health_bar_color"] = nil
  hbc_unit.updatePowerCallbacks["update_personal_resource_display_power_bar_color"] = nil
end


