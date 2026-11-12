-- luacheck: globals C_EventUtils
local addonName = ...
local addon = _G.EnhanceQoL
local I = addon.Inventory
local frame = CreateFrame("Frame")
local function registerSearchSettings()
 local section = addon.SettingsLayout and addon.SettingsLayout.bagsInventorySection
 if not section or not addon.functions.SettingsCreateButton then return end
 addon.functions.SettingsCreateButton(addon.SettingsLayout.rootGENERAL, {
  var = "itemSearchOpen", text = addon.L["InventorySearchTitle"], desc = addon.L["itemSearchHint"],
  parentSection = section, newTagID = "Items_search", func = function() I.SearchWindow.Open() end,
 })
end
for _, event in ipairs({ "ADDON_LOADED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYERBANKSLOTS_CHANGED", "BANK_TABS_CHANGED" }) do
 if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then frame:RegisterEvent(event) end
end
frame:SetScript("OnEvent", function(_, event, name)
 if event == "ADDON_LOADED" then
  if name ~= addonName then return end
  I.Initialize(); registerSearchSettings(); frame:UnregisterEvent("ADDON_LOADED")
 elseif event == "BANKFRAME_OPENED" then I.state.bankOpen = true
 elseif event == "BANKFRAME_CLOSED" then I.state.bankOpen = false end
 I.state.revision = (I.state.revision or 0) + 1
 if I.SearchWindow.frame and I.SearchWindow.frame:IsShown() then I.SearchWindow.Schedule() end
end)
if addon.Items then
 I.itemSubscription = addon.Items.Subscribe(function()
  if I.SearchWindow.frame and I.SearchWindow.frame:IsShown() then I.SearchWindow.Schedule() end
 end)
end
