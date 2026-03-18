local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local SettingsLib = LibStub("LibEQOLSettingsMode-1.0")

local rootCategories = {
	{ id = "UI", label = _G["INTERFACE_LABEL"] },
	{ id = "GENERAL", label = _G["GENERAL"] },
	{ id = "GAMEPLAY", label = _G["SETTING_GROUP_GAMEPLAY"] },
	{ id = "SOCIAL", label = _G["SOCIAL_LABEL"] },
	{ id = "ECONOMY", label = L["Economy"] or "Economy" },
	{ id = "SOUND", label = _G["SOUND"] },
	{ id = "PROFILES", label = L["Profiles"] },
}

local function buildSlashCommandHint(commands, desc, usage, note)
	local commandText = table.concat(commands, ", ")
	if usage and usage ~= "" then commandText = commandText .. usage end
	local text = ("|cff00ff98%s|r %s"):format(commandText, desc)
	if note and note ~= "" then text = ("%s |cff909090- %s|r"):format(text, note) end
	return text
end

local function createRootSlashCommandHints(category)
	addon.functions.SettingsCreateHeadline(category, L["rootSlashCommandsHeader"] or "Slash Commands")
	addon.functions.SettingsCreateText(category, L["rootSlashCommandsDesc"] or "Type these in chat.")
	addon.functions.SettingsCreateText(category, L["rootSlashCommandsConflictDesc"] or "Aliases may be taken by another add-on.")

	local sections = {
		{
			title = L["rootSlashCommandsGeneralHeader"] or "General",
			entries = {
				{
					commands = { "/eqol" },
					desc = L["rootSlashCommandSettingsDesc"] or "Open the EnhanceQoL settings.",
				},
				{
					commands = { "/rl" },
					desc = L["rootSlashCommandReloadUIDesc"] or "Reload UI.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
			},
		},
		{
			title = L["rootSlashCommandsUIHeader"] or "UI & Editors",
			entries = {
				{
					commands = { "/ecd", "/cpe" },
					desc = L["rootSlashCommandCooldownPanelsDesc"] or "Open the Cooldown Panels editor.",
				},
				{
					commands = { "/cdm", "/wa" },
					desc = L["rootSlashCommandCooldownViewerDesc"] or "Open the Blizzard Cooldown Viewer settings.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
				{
					commands = { "/em", "/edit", "/editmode" },
					desc = L["rootSlashCommandEditModeDesc"] or "Open Edit Mode.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
				{
					commands = { "/kb" },
					desc = L["rootSlashCommandQuickKeybindDesc"] or "Open Quick Keybind Mode.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
				{
					commands = { "/ccb", "/clickcast" },
					desc = L["rootSlashCommandClickCastDesc"] or "Open Click Cast Bindings.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
			},
		},
		{
			title = L["rootSlashCommandsUnitFramesHeader"] or "Unit Frames",
			entries = {
				{
					commands = { "/eqol hbp" },
					desc = L["rootSlashCommandHealerBuffPlacementDesc"] or "Open the healer buff placement editor for party or raid frames.",
				},
			},
		},
		{
			title = L["rootSlashCommandsNavigationHeader"] or "Navigation & Group",
			entries = {
				{
					commands = { "/way" },
					usage = " [mapID] 37.8 61.2",
					desc = L["rootSlashCommandWayDesc"] or "Set a waypoint on the world map.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
				{
					commands = { "/pull" },
					usage = " [seconds]",
					desc = L["rootSlashCommandPullTimerDesc"] or "Start the Blizzard pull countdown.",
					note = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings.",
				},
			},
		},
		{
			title = L["rootSlashCommandsSocialHeader"] or "Chat & Social",
			entries = {
				{
					commands = { "/eim" },
					desc = L["rootSlashCommandInstantMessengerDesc"] or "Open the Instant Messenger window.",
					note = L["rootSlashCommandNoteChatIMEnabled"] or "Only if Instant Messenger is enabled.",
				},
				{
					commands = { "/eil" },
					desc = L["rootSlashCommandIgnoreDesc"] or "Open the enhanced ignore list.",
					note = L["rootSlashCommandNoteIgnoreEnabled"] or "Only if Ignore is enabled.",
				},
			},
		},
		{
			title = L["rootSlashCommandsDiagnosticsHeader"] or "Diagnostics & Utilities",
			entries = {
				{
					commands = { "/eqol aag" },
					usage = " <gossipOptionID>",
					desc = L["rootSlashCommandAutoGossipAddDesc"] or "Add a gossip option ID to the auto-select list.",
				},
				{
					commands = { "/eqol rag" },
					usage = " <gossipOptionID>",
					desc = L["rootSlashCommandAutoGossipRemoveDesc"] or "Remove a gossip option ID from the auto-select list.",
				},
				{
					commands = { "/eqol lag" },
					desc = L["rootSlashCommandAutoGossipListDesc"] or "List the gossip option IDs from the current gossip window.",
				},
			},
		},
	}

	for _, section in ipairs(sections) do
		addon.functions.SettingsCreateHeadline(category, section.title)
		for _, entry in ipairs(section.entries) do
			addon.functions.SettingsCreateText(category, buildSlashCommandHint(entry.commands, entry.desc, entry.usage, entry.note))
		end
	end
end

createRootSlashCommandHints(addon.SettingsLayout.rootCategory)

for _, entry in ipairs(rootCategories) do
	addon.SettingsLayout["root" .. entry.id] = addon.functions.SettingsCreateCategory(nil, entry.label, nil, entry.id)
end
