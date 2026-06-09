local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local GroupTools = addon.GroupTools

if
	not (
		GroupTools
		and GroupTools.DB
		and GroupTools.functions
		and addon.functions
		and addon.functions.SettingsCreateCheckbox
		and addon.functions.SettingsCreateDropdown
		and addon.functions.SettingsCreateInput
		and addon.functions.SettingsCreateButton
		and addon.functions.SettingsCreateExpandableSection
	)
then
	return
end

local DB = GroupTools.DB
local ENABLE_TEXT = _G.ENABLE or "Enable"
local FocusMarker = GroupTools.FocusMarker

local function isEnabled(key)
	return addon.db and addon.db[key] == true or false
end

local function setEnabled(feature, value)
	if GroupTools.functions.SetFeatureEnabled then
		GroupTools.functions.SetFeatureEnabled(feature, value == true)
	end
end

local function setFocusMarkerSetting(field, value, maybeValue)
	if maybeValue ~= nil then value = maybeValue end
	if GroupTools.functions.SetFocusMarkerSetting then GroupTools.functions.SetFocusMarkerSetting(field, value) end
end

local function buildFocusMarkerOptions()
	local list = {}
	for i = 1, 8 do
		if FocusMarker and FocusMarker.GetMarkerIcon and FocusMarker.GetMarkerLabel then
			list[i] = FocusMarker:GetMarkerIcon(i) .. " " .. FocusMarker:GetMarkerLabel(i)
		else
			list[i] = tostring(i)
		end
	end
	return list
end

local focusMarkerOrder = { 1, 2, 3, 4, 5, 6, 7, 8 }

local function createFeatureToggle(category, section, feature, dbKey, titleKey, titleFallback, hintKey, hintFallback, descKey, descFallback)
	addon.functions.SettingsCreateHeadline(category, L[titleKey] or titleFallback, { parentSection = section })
	local checkbox = addon.functions.SettingsCreateCheckbox(category, {
		var = dbKey,
		text = ENABLE_TEXT,
		desc = descKey and (L[descKey] or descFallback) or nil,
		get = function() return isEnabled(dbKey) end,
		func = function(value) setEnabled(feature, value) end,
		default = false,
		parentSection = section,
	})
	addon.functions.SettingsCreateText(category, "|cffffd700" .. (L[hintKey] or hintFallback) .. "|r", { parentSection = section })
	return checkbox
end

local unitFrameCategory = addon.SettingsLayout.rootUI
local unitFrameSection = addon.SettingsLayout.expUnitFrames
if unitFrameCategory and unitFrameSection then
	createFeatureToggle(
		unitFrameCategory,
		unitFrameSection,
		"healerMana",
		DB.healerEnabled,
		"groupToolsHealerManaIndicator",
		"Healer Mana Indicator",
		"groupToolsHealerManaEditModeHint",
		"Configure dungeon/raid visibility, font, color, and position in Edit Mode."
	)
end

local combatCategory = addon.SettingsLayout.rootGAMEPLAY
if combatCategory then
	local combatSection = addon.functions.SettingsCreateExpandableSection(combatCategory, {
		name = L["groupToolsCombatAlertsSection"] or "Combat Alerts",
		description = L["configCenterPageDescCombatAlerts"]
			or "Configure combat warnings such as death alerts and no-target reminders, including text, sound, TTS, role rules and Edit Mode placement.",
		expanded = false,
		colorizeTitle = false,
		newTagID = "GroupToolsCombatAlerts",
		iconKey = "combat",
		modernCategory = "gameplay",
		modernOnly = true,
	})
	addon.SettingsLayout.groupToolsCombatAlertsSection = combatSection

	createFeatureToggle(
		combatCategory,
		combatSection,
		"deathAlert",
		DB.deathEnabled,
		"groupToolsDeathAlert",
		"Death Alert",
		"groupToolsDeathAlertEditModeHint",
		"Configure text, sound, TTS, role overrides, font, and position in Edit Mode.",
		"groupToolsDeathAlertDesc",
		"Shows a configurable alert when a party or raid member dies, with optional text, sound and text-to-speech output."
	)
	createFeatureToggle(
		combatCategory,
		combatSection,
		"noTarget",
		DB.noTargetEnabled,
		"groupToolsNoTargetIndicator",
		"No Target Indicator",
		"groupToolsNoTargetEditModeHint",
		"Configure text, sound, font, target handling, and position in Edit Mode.",
		"groupToolsNoTargetDesc",
		"Shows a warning when you are in combat without a valid target, so target loss is easier to notice."
	)
end

local gameplayCategory = addon.SettingsLayout.rootGAMEPLAY
if gameplayCategory then
	local focusSection = addon.functions.SettingsCreateExpandableSection(gameplayCategory, {
		name = L["groupToolsFocusMarkerSection"] or "Focus Marker",
		expanded = false,
		colorizeTitle = false,
		newTagID = "GroupToolsFocusMarker",
		iconKey = "focus",
		modernOnly = true,
	})
	addon.SettingsLayout.groupToolsFocusMarkerSection = focusSection

	local focusToggle = createFeatureToggle(
		gameplayCategory,
		focusSection,
		"focusMarker",
		DB.focusMarkerEnabled,
		"groupToolsFocusMarker",
		"Focus marker macro",
		"groupToolsFocusMarkerEditModeHint",
		"Configure marker, ready-check announcement, and update the secure macro below."
	)
	local function isFocusMarkerEnabled() return isEnabled(DB.focusMarkerEnabled) end
	local parentElement = focusToggle and focusToggle.element
	addon.functions.SettingsCreateDropdown(gameplayCategory, {
		var = DB.focusMarker,
		text = L["groupToolsFocusMarkerMarker"] or "Focus marker",
		desc = L["groupToolsFocusMarkerMarkerDesc"],
		listFunc = buildFocusMarkerOptions,
		order = focusMarkerOrder,
		default = 5,
		get = function() return FocusMarker and FocusMarker.GetMarker and FocusMarker:GetMarker() or 5 end,
		set = function(value, maybeValue) setFocusMarkerSetting("marker", value, maybeValue) end,
		parent = true,
		element = parentElement,
		parentCheck = isFocusMarkerEnabled,
		parentSection = focusSection,
	})
	addon.functions.SettingsCreateCheckbox(gameplayCategory, {
		var = DB.focusMarkerAnnounce,
		text = L["groupToolsFocusMarkerAnnounce"] or "Announce on ready check",
		desc = L["groupToolsFocusMarkerAnnounceDesc"],
		get = function() return addon.db and addon.db[DB.focusMarkerAnnounce] == true end,
		func = function(value) setFocusMarkerSetting("announce", value) end,
		default = true,
		parent = true,
		element = parentElement,
		parentCheck = isFocusMarkerEnabled,
		parentSection = focusSection,
	})
	addon.functions.SettingsCreateInput(gameplayCategory, {
		var = DB.focusMarkerMessage,
		text = L["groupToolsFocusMarkerAnnounceMessage"] or "Ready check message",
		desc = L["groupToolsFocusMarkerAnnounceMessageDesc"],
		default = "",
		get = function() return addon.db and addon.db[DB.focusMarkerMessage] or "" end,
		set = function(value) setFocusMarkerSetting("message", value) end,
		maxChars = 160,
		inputWidth = 240,
		placeholder = (L["groupToolsFocusMarkerReadyTemplate"] or "My focus marker: {%s}"):format("moon"),
		selectAllOnFocus = true,
		parent = true,
		element = parentElement,
		parentCheck = isFocusMarkerEnabled,
		parentSection = focusSection,
	})
	addon.functions.SettingsCreateButton(gameplayCategory, {
		var = "groupToolsFocusMarkerUpdateMacroButton",
		text = L["groupToolsFocusMarkerUpdateMacro"] or "Update macro",
		desc = L["groupToolsFocusMarkerUpdateMacroDesc"],
		func = function()
			if FocusMarker and FocusMarker.WriteMacro then FocusMarker:WriteMacro(true) end
		end,
		parent = true,
		element = parentElement,
		parentCheck = isFocusMarkerEnabled,
		parentSection = focusSection,
	})
end
