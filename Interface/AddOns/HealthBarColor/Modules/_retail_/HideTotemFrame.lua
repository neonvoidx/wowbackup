local _, addonTable = ...
local addon = addonTable.addon

local module = addon:NewModule("HideTotemFrame")
Mixin(module, addonTable.hooks)

function module:OnEnable()
  local totemFrame = TotemFrame
  if not totemFrame then
    return
  end
  self:HookScript(totemFrame, "OnShow", function()
    totemFrame:Hide()
  end)
  totemFrame:Hide()
end

function module:OnDisable()
  self:DisableHooks()
  local totemFrame = TotemFrame
  if totemFrame then
    TotemFrame:Show()
  end
end
