local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local UIErrors = addon.UIErrors
local category = addon.SettingsLayout.rootGENERAL

local section = addon.functions.SettingsCreateExpandableSection(category, {
	name = L["UIErrorMessages"],
	configPageKey = "UIErrorMessages",
	modernCategory = "general",
	expanded = false,
	colorizeTitle = false,
})

local function isEnabled() return addon.db and addon.db.uiErrorFilterEnabled == true end

addon.functions.SettingsCreateCheckbox(category, {
	var = "uiErrorFilterEnabled",
	text = L["uiErrorFilterEnabled"],
	desc = L["uiErrorFilterDesc"],
	default = false,
	get = isEnabled,
	func = function(value) UIErrors:SetEnabled(value) end,
	newTagID = "uiErrorFilterEnabled",
	parentSection = section,
})

-- Group only identical localized messages; keep every stored error key intact.
local groups = {}
for _, entry in ipairs(UIErrors.entries) do
 local label = _G[entry.label]
 local groupKey = label or entry.key
 local group = groups[groupKey]
 if not group then group = {}; groups[groupKey] = group end
 group[#group + 1] = entry.key
end

for _, entry in ipairs(UIErrors.entries) do
 local key = entry.key
 local label = _G[entry.label]
 local keys = groups[label or key]
 if #keys > 1 and keys[1] == key then
  addon.functions.SettingsCreateDropdown(category, {
   id = "uiErrorFilterMessages." .. key,
   key = false,
   storage = false,
   var = "uiErrorFilterMessages_" .. key,
   text = label,
   desc = L["uiErrorFilterGroupDesc"],
   default = "hide",
   list = { hide = L["uiErrorFilterHideAll"], show = L["uiErrorFilterShowAll"], mixed = L["uiErrorFilterMixed"] },
   order = { "hide", "show", "mixed" },
   get = function()
    local enabled = UIErrors:IsMessageEnabled(keys[1])
    for i = 2, #keys do
     if UIErrors:IsMessageEnabled(keys[i]) ~= enabled then return "mixed" end
    end
    return enabled and "hide" or "show"
   end,
   func = function(value)
    if value ~= "hide" and value ~= "show" then return end
    for _, errorKey in ipairs(keys) do UIErrors:SetMessageEnabled(errorKey, value == "hide") end
   end,
   newTagID = "uiErrorFilterMessages_" .. key,
   parent = true,
   parentCheck = isEnabled,
   parentSection = section,
  })
 else
  addon.functions.SettingsCreateCheckbox(category, {
   var = "uiErrorFilterMessages",
   subvar = key,
   text = label,
   default = true,
   get = function() return UIErrors:IsMessageEnabled(key) end,
   func = function(value) UIErrors:SetMessageEnabled(key, value) end,
   newTagID = "uiErrorFilterMessages_" .. key,
   hidden = #keys > 1,
   parent = true,
   parentCheck = isEnabled,
   parentSection = section,
  })
 end
end
