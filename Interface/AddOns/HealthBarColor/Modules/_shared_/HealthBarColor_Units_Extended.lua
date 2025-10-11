--[[
  colorModes extended:
  1 = class/reaction
  2 = reaction
  3 = class/custom
  4 = custom
  5 = class/blizzard green (has no effect when also playing with custom textures and will then just default to 0,1,0)
  6 = blizzard green (has no effect when also playing with custom textures and will then just default to 0,1,0)
  7 = Health Value
]]
local _, addonTable = ...
local addon = addonTable.addon

local units
if addonTable.isVanilla then
  units = {"target", "targettarget"}
else
  units = {"target", "targettarget", "focus", "focustarget"}
end

for _, unit in pairs(units) do
  local module = addon:NewModule("HealthBarColor_" .. unit)
  function module:OnEnable()
    local dbObj = CopyTable(addon.db.profile["HealthBarColor_" .. unit])
    local hbc_unit = addon:GetUnit(unit)
    if dbObj.colorMode == 1 then
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        if hbc_unit.isPlayer then
          hbc_unit:SetHealthBarToClassColor()
        else
          hbc_unit:SetHealthBarToReactionColor()
        end
      end
    elseif dbObj.colorMode == 2 then
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        hbc_unit:SetHealthBarToReactionColor()
      end
    elseif dbObj.colorMode == 3 then
      local startColor = CreateColor(dbObj.customColorStart.r, dbObj.customColorStart.g, dbObj.customColorStart.b, dbObj.customColorStart.a)
      local endColor = CreateColor(dbObj.customColorEnd.r, dbObj.customColorEnd.g, dbObj.customColorEnd.b, dbObj.customColorEnd.a)
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        if hbc_unit.isPlayer then
          hbc_unit:SetHealthBarToClassColor()
        else
          hbc_unit:SetHealthBarToCustomColor(startColor, endColor)
        end
      end
    elseif dbObj.colorMode == 4 then
      local startColor = CreateColor(dbObj.customColorStart.r, dbObj.customColorStart.g, dbObj.customColorStart.b, dbObj.customColorStart.a)
      local endColor = CreateColor(dbObj.customColorEnd.r, dbObj.customColorEnd.g, dbObj.customColorEnd.b, dbObj.customColorEnd.a)
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        hbc_unit:SetHealthBarToCustomColor(startColor, endColor)
      end
    elseif dbObj.colorMode == 5 then
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        if hbc_unit.isPlayer then
          hbc_unit:SetHealthBarToClassColor()
        else
          hbc_unit:RestoreHealthBarToDefault()
        end
      end
    elseif dbObj.colorMode == 6 then
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        hbc_unit:RestoreHealthBarToDefault()
      end
    else -- 7
      hbc_unit.updateFullCallbacks["update_health_bar_color"] = function()
        hbc_unit:SetHealthBarToHealthValueColor()
      end
      hbc_unit.updateHealthCallbacks["update_health_bar_color"] = function()
        hbc_unit:SetHealthBarToHealthValueColor()
      end
      hbc_unit.eventFrame:RegisterUnitEvent("UNIT_HEALTH", hbc_unit.UnitId)
    end
    if addon:IsModuleEnabled("Textures") then
      addon:ReloadModule("Textures") --Textures will call update_health_bar_color
    else
      hbc_unit.updateFullCallbacks["update_health_bar_color"]()
    end
    if addonTable.isClassic then
      hbc_unit.healthBar.lockColor = true
    end
  end

  function module:OnDisable()
    local hbc_unit = addon:GetUnit(unit)
    hbc_unit.updateFullCallbacks["update_health_bar_color"] = function () end
    hbc_unit.updateHealthCallbacks["update_health_bar_color"] = nil
    hbc_unit:RestoreHealthBarToDefault()
    hbc_unit.eventFrame:UnregisterEvent("UNIT_HEALTH")
  end
end
