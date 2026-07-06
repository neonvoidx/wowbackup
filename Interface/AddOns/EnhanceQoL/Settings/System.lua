local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function applyParentSection(entries, section)
	for _, entry in ipairs(entries or {}) do
		entry.parentSection = section
		if entry.children then applyParentSection(entry.children, section) end
	end
end

local cGeneral = addon.SettingsLayout.rootGENERAL
addon.SettingsLayout.systemCategory = cGeneral

local dialogExpandable = addon.functions.SettingsCreateExpandableSection(cGeneral, {
	name = L["DialogsAndConfirmations"] or "Dialogs & Confirmations",
	configPageKey = "DialogsConfirmations",
	iconKey = "dialogsconfirmations",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "deleteItemFillDialog",
	text = L["deleteItemFillDialog"]:format(DELETE_ITEM_CONFIRM_STRING),
	desc = L["deleteItemFillDialogDesc"],
	func = function(value) addon.db["deleteItemFillDialog"] = value end,
	parentSection = dialogExpandable,
})

local function isDialogConfirmSelected(key)
	if key == "trade" then return addon.db["confirmTimerRemovalTrade"] == true end
	if key == "socket" then return addon.db["confirmSocketReplace"] == true end
	if key == "token" then return addon.db["confirmPurchaseTokenItem"] == true end
	if key == "highcost" then return addon.db["confirmHighCostItem"] == true end
	return false
end

local function setDialogConfirmOption(key, value)
	local enabled = value and true or false
	if key == "trade" then
		addon.db["confirmTimerRemovalTrade"] = enabled
	elseif key == "socket" then
		addon.db["confirmSocketReplace"] = enabled
	elseif key == "token" then
		addon.db["confirmPurchaseTokenItem"] = enabled
	elseif key == "highcost" then
		addon.db["confirmHighCostItem"] = enabled
	end
end

local function applyDialogConfirmSelection(selection)
	selection = selection or {}
	addon.db["confirmTimerRemovalTrade"] = selection.trade == true
	addon.db["confirmSocketReplace"] = selection.socket == true
	addon.db["confirmPurchaseTokenItem"] = selection.token == true
	addon.db["confirmHighCostItem"] = selection.highcost == true
end

local dialogAutoConfirmOptions = {
	{
		value = "trade",
		text = L["confirmTimerRemovalTrade"],
		tooltip = L["confirmTimerRemovalTradeDesc"],
	},
	{
		value = "socket",
		text = L["confirmSocketReplace"],
		tooltip = L["confirmSocketReplaceDesc"],
	},
	{
		value = "token",
		text = L["confirmPurchaseTokenItem"],
		tooltip = L["confirmPurchaseTokenItemDesc"],
	},
	{
		value = "highcost",
		text = L["confirmHighCostItem"],
		tooltip = L["confirmHighCostItemDesc"],
	},
}

table.sort(dialogAutoConfirmOptions, function(a, b) return tostring(a.text) < tostring(b.text) end)

addon.functions.SettingsCreateMultiDropdown(cGeneral, {
	var = "dialogAutoConfirm",
	text = L["dialogAutoConfirm"] or "Auto-confirm dialogs",
	desc = L["dialogAutoConfirmDesc"],
	options = dialogAutoConfirmOptions,
	isSelectedFunc = function(key) return isDialogConfirmSelected(key) end,
	setSelectedFunc = function(key, selected) setDialogConfirmOption(key, selected) end,
	setSelection = applyDialogConfirmSelection,
	parentSection = dialogExpandable,
})

local utilitiesExpandable = addon.functions.SettingsCreateExpandableSection(cGeneral, {
	name = L["UIUtilities"] or "UI Utilities",
	configPageKey = "UIUtilities",
	description = L["configCenterPageCardDescUIUtilities"],
	iconKey = "uiutilities",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "autoUnwrapMounts",
	text = L["autoUnwrapMounts"],
	desc = L["autoUnwrapMountsDesc"],
	func = function(v)
		addon.db["autoUnwrapMounts"] = v
		if addon.functions.UpdateAutoUnwrapWatcher then addon.functions.UpdateAutoUnwrapWatcher() end
	end,
	parentSection = utilitiesExpandable,
})

addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "showTrainAllButton",
	text = L["showTrainAllButton"],
	desc = L["showTrainAllButtonDesc"],
	func = function(v)
		addon.db["showTrainAllButton"] = v
		if addon.functions.applyTrainAllButton then addon.functions.applyTrainAllButton() end
	end,
	parentSection = utilitiesExpandable,
})

addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "hideScreenshotStatus",
	text = L["hideScreenshotStatus"],
	desc = L["hideScreenshotStatusDesc"],
	func = function(v)
		addon.db["hideScreenshotStatus"] = v
		if addon.functions.toggleScreenshotStatus then addon.functions.toggleScreenshotStatus(v) end
	end,
	parentSection = utilitiesExpandable,
})

addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enableCooldownManagerSlashCommand",
	text = L["enableCooldownManagerSlashCommand"],
	desc = L["enableCooldownManagerSlashCommandDesc"],
	func = function(value)
		addon.db["enableCooldownManagerSlashCommand"] = value
		if value then
			addon.functions.registerCooldownManagerSlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})
addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enablePullTimerSlashCommand",
	text = L["enablePullTimerSlashCommand"],
	desc = L["enablePullTimerSlashCommandDesc"],
	func = function(value)
		addon.db["enablePullTimerSlashCommand"] = value
		if value then
			addon.functions.registerPullTimerSlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})
addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enableEditModeSlashCommand",
	text = L["enableEditModeSlashCommand"],
	desc = L["enableEditModeSlashCommandDesc"],
	func = function(value)
		addon.db["enableEditModeSlashCommand"] = value
		if value then
			addon.functions.registerEditModeSlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})
addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enableQuickKeybindSlashCommand",
	text = L["enableQuickKeybindSlashCommand"],
	desc = L["enableQuickKeybindSlashCommandDesc"],
	func = function(value)
		addon.db["enableQuickKeybindSlashCommand"] = value
		if value then
			addon.functions.registerQuickKeybindSlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})
addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enableClickCastSlashCommand",
	text = L["enableClickCastSlashCommand"],
	desc = L["enableClickCastSlashCommandDesc"],
	func = function(value)
		addon.db["enableClickCastSlashCommand"] = value
		if value then
			addon.functions.registerClickCastSlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})
addon.functions.SettingsCreateCheckbox(cGeneral, {
	var = "enableReloadUISlashCommand",
	text = L["enableReloadUISlashCommand"],
	desc = L["enableReloadUISlashCommandDesc"],
	func = function(value)
		addon.db["enableReloadUISlashCommand"] = value
		if value then
			addon.functions.registerReloadUISlashCommand()
		else
			addon.variables.requireReload = true
		end
	end,
	default = false,
	parentSection = utilitiesExpandable,
})

----- REGION END

function addon.functions.initSystem() end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
