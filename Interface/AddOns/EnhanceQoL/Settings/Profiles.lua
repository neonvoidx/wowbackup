-- luacheck: globals EnhanceQoLBagsDB
local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local wipe = wipe
local serializer = LibStub("AceSerializer-3.0")
local deflate = LibStub("LibDeflate")
local PROFILE_EXPORT_KIND = "EQOL_PROFILE"
local BAGS_CATEGORIES_EXPORT_KIND = "EQOL_BAGS_CATEGORIES"
local DAMAGE_METER_EXPORT_KIND = "EQOL_DAMAGE_METER"
local HBP_EXPORT_KIND = "EQOL_HBP"
local MYTHIC_PLUS_TIMER_EXPORT_KIND = "EQOL_MYTHIC_PLUS_TIMER"
local IMPORT_PROTECTION_KEY = "importProtection"
local IMPORT_PROTECTION = {
	ACTION_BARS = "actionBars",
	BAGS = "bags",
	CASTBARS = "castbars",
	CHAT_SOCIAL = "chatSocial",
	CLASS_BUFF_REMINDER = "classBuffReminder",
	COOLDOWN_PANELS = "cooldownPanels",
	DAMAGE_METER = "damageMeter",
	DATA_PANELS = "dataPanels",
	DUNGEON_COMBAT = "dungeonCombat",
	DUNGEON_RAID = "dungeonRaid",
	HBP = "hbp",
	INSTANCE_DIFFICULTY = "instanceDifficulty",
	MOUSE_ACCESSIBILITY = "mouseAccessibility",
	MOVER = "mover",
	QUICK_ACCEPT = "quickAccept",
	RESOURCE_BARS = "resourceBars",
	SKINNER = "skinner",
	SOUND = "sound",
	TELEPORT_COMPENDIUM = "teleportCompendium",
	TOOLTIP = "tooltip",
	UNIT_FRAMES = "unitFrames",
	VENDOR = "vendor",
}
local IMPORT_PROTECTION_DEFS = {
	{ key = IMPORT_PROTECTION.ACTION_BARS, labelKey = "ProfileImportProtectionActionBars", fallback = "Action Bars" },
	{ key = IMPORT_PROTECTION.BAGS, labelKey = "ProfileImportProtectionBags", fallback = "Bags" },
	{ key = IMPORT_PROTECTION.CASTBARS, labelKey = "ProfileImportProtectionCastbars", fallback = "Castbars" },
	{ key = IMPORT_PROTECTION.CHAT_SOCIAL, labelKey = "ProfileImportProtectionChatSocial", fallback = "Chat & Social" },
	{ key = IMPORT_PROTECTION.CLASS_BUFF_REMINDER, labelKey = "ProfileImportProtectionClassBuffReminder", fallback = "Class Buff Reminder" },
	{ key = IMPORT_PROTECTION.COOLDOWN_PANELS, labelKey = "ProfileImportProtectionCooldownPanels", fallback = "Cooldown Panels" },
	{ key = IMPORT_PROTECTION.DAMAGE_METER, labelKey = "ProfileImportProtectionDamageMeter", fallback = "Damage Meter" },
	{ key = IMPORT_PROTECTION.DATA_PANELS, labelKey = "ProfileImportProtectionDataPanels", fallback = "Data Panels" },
	{ key = IMPORT_PROTECTION.DUNGEON_COMBAT, labelKey = "ProfileImportProtectionDungeonCombat", fallback = "Dungeon & Combat Tools" },
	{ key = IMPORT_PROTECTION.DUNGEON_RAID, labelKey = "ProfileImportProtectionDungeonRaid", fallback = "Dungeon & Raid" },
	{ key = IMPORT_PROTECTION.HBP, labelKey = "ProfileImportProtectionHBP", fallback = "Buff Placement" },
	{ key = IMPORT_PROTECTION.INSTANCE_DIFFICULTY, labelKey = "ProfileImportProtectionInstanceDifficulty", fallback = "Instance Difficulty" },
	{ key = IMPORT_PROTECTION.MOUSE_ACCESSIBILITY, labelKey = "ProfileImportProtectionMouseAccessibility", fallback = "Mouse & Accessibility" },
	{ key = IMPORT_PROTECTION.MOVER, labelKey = "ProfileImportProtectionMover", fallback = "Mover" },
	{ key = IMPORT_PROTECTION.QUICK_ACCEPT, labelKey = "ProfileImportProtectionQuickAccept", fallback = "Quick Accept" },
	{ key = IMPORT_PROTECTION.RESOURCE_BARS, labelKey = "ProfileImportProtectionResourceBars", fallback = "Resource Bars" },
	{ key = IMPORT_PROTECTION.SKINNER, labelKey = "ProfileImportProtectionSkinner", fallback = "Skinner" },
	{ key = IMPORT_PROTECTION.SOUND, labelKey = "ProfileImportProtectionSound", fallback = "Sound" },
	{ key = IMPORT_PROTECTION.TELEPORT_COMPENDIUM, labelKey = "ProfileImportProtectionTeleportCompendium", fallback = "Teleport Compendium" },
	{ key = IMPORT_PROTECTION.TOOLTIP, labelKey = "ProfileImportProtectionTooltip", fallback = "Tooltip" },
	{ key = IMPORT_PROTECTION.UNIT_FRAMES, labelKey = "ProfileImportProtectionUnitFrames", fallback = "Unit Frames" },
	{ key = IMPORT_PROTECTION.VENDOR, labelKey = "ProfileImportProtectionVendor", fallback = "Vendor" },
}

local profilesCategory = nil

local expandable = addon.functions.SettingsCreateExpandableSection(profilesCategory, {
	name = L["AddOn"],
	configPageKey = "ProfilesAddOn",
	description = L["configCenterPageCardDescAddOn"],
	iconKey = "addonprofile",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesAddOn",
	modernCategory = "profiles",
	modernOnly = true,
})

local importProtectionExpandable
local fontExpandable

local profileOrderActive, profileOrderGlobal, profileOrderCopy, profileOrderDelete = {}, {}, {}, {}
local globalFontOrder = {}
local importProtectionOrder = {}

local function getCachedFontMedia()
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font")
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font")
	if type(names) == "table" and type(hash) == "table" then return names, hash end
	return {}, {}
end

local function buildGlobalFontDropdown()
	local map = {
		[(addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT] = L["actionBarFontDefault"] or "Blizzard font",
	}
	local names, hash = getCachedFontMedia()
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
	end
	local list, order = addon.functions.prepareListForDropdown(map)
	wipe(globalFontOrder)
	for i, key in ipairs(order or {}) do
		globalFontOrder[i] = key
	end
	return list
end

local function ensureImportProtectionDB()
	EnhanceQoLDB = EnhanceQoLDB or {}
	if type(EnhanceQoLDB[IMPORT_PROTECTION_KEY]) ~= "table" then EnhanceQoLDB[IMPORT_PROTECTION_KEY] = {} end
	return EnhanceQoLDB[IMPORT_PROTECTION_KEY]
end

local function buildImportProtectionDropdown()
	local list = {}
	for _, def in ipairs(IMPORT_PROTECTION_DEFS) do
		list[def.key] = L[def.labelKey] or def.fallback
	end

	wipe(importProtectionOrder)
	local sorted = {}
	for key in pairs(list) do
		sorted[#sorted + 1] = key
	end
	table.sort(sorted, function(a, b) return tostring(list[a]) < tostring(list[b]) end)
	for i, key in ipairs(sorted) do
		importProtectionOrder[i] = key
	end
	return list
end

local function isImportSectionProtected(section)
	local protection = EnhanceQoLDB and EnhanceQoLDB[IMPORT_PROTECTION_KEY]
	return type(protection) == "table" and protection[section] == true
end

local function getImportProtectionSelection()
	return ensureImportProtectionDB()
end

local function setImportProtectionSelection(map)
	local target = ensureImportProtectionDB()
	wipe(target)
	if type(map) ~= "table" then return end
	for _, def in ipairs(IMPORT_PROTECTION_DEFS) do
		if map[def.key] == true then target[def.key] = true end
	end
end

local function refreshGlobalFonts()
	if addon.functions and addon.functions.RefreshGlobalFontConsumers then
		addon.functions.RefreshGlobalFontConsumers()
		return
	end
	local actionBarLabels = addon.ActionBarLabels
	if actionBarLabels and actionBarLabels.RefreshAllMacroNameVisibility then actionBarLabels.RefreshAllMacroNameVisibility() end
	if actionBarLabels and actionBarLabels.RefreshAllHotkeyStyles then actionBarLabels.RefreshAllHotkeyStyles() end
	if actionBarLabels and actionBarLabels.RefreshAllCountStyles then actionBarLabels.RefreshAllCountStyles() end
end

local SUPPORTED_GLOBAL_FONT_ROOT_KEYS = {
	cooldownPanels = true,
	dataPanels = true,
	focusInterruptTracker = true,
	globalResourceBarSettings = true,
	personalResourceBarSettings = true,
	ufFrames = true,
	ufGroupFrames = true,
}

local SUPPORTED_FLAT_FONT_KEYS = {
	actionBarCountFontFace = true,
	actionBarHotkeyFontFace = true,
	actionBarMacroFontFace = true,
	combatTextFont = true,
	honorBarTextFont = true,
	ilvlFontFace = true,
	mythicPlusBloodlustTrackerCooldownFontFace = true,
	mythicPlusBRTrackerChargesFontFace = true,
	mythicPlusBRTrackerCooldownFontFace = true,
	repBarTextFont = true,
	squareMinimapStatsFont = true,
	totalAbsorbTrackerTextFont = true,
	xpBarTextFont = true,
}

local SUPPORTED_FLAT_FONT_STYLE_KEYS = {
	actionBarCountFontOutline = true,
	actionBarHotkeyFontOutline = true,
	actionBarMacroFontOutline = true,
	combatTextFontOutline = true,
	honorBarTextOutline = true,
	ilvlFontOutline = true,
	mythicPlusBloodlustTrackerCooldownTextOutline = true,
	mythicPlusBRTrackerChargesTextOutline = true,
	mythicPlusBRTrackerCooldownTextOutline = true,
	repBarTextOutline = true,
	squareMinimapStatsOutline = true,
	totalAbsorbTrackerTextOutline = true,
	xpBarTextOutline = true,
}

local function isRecursiveFontFaceKey(key)
	if type(key) ~= "string" then return false end
	local lowered = string.lower(key)
	if lowered:find("outline", 1, true) or lowered:find("fontstyle", 1, true) or lowered:find("fontsize", 1, true) then return false end
	return lowered:find("font", 1, true) ~= nil
end

local function isRecursiveFontStyleKey(key)
	if type(key) ~= "string" then return false end
	local lowered = string.lower(key)
	if lowered:find("outline", 1, true) or lowered:find("fontstyle", 1, true) then return true end
	return lowered == "cooldowntextstyle" or lowered == "statictextstyle"
end

local function overwriteNestedFontSettings(node, mode, replacement, visited)
	if type(node) ~= "table" then return 0 end
	visited = visited or {}
	if visited[node] then return 0 end
	visited[node] = true

	local changed = 0
	if mode == "style" and node.fontStyle == nil and (type(node.fontOutline) == "boolean" or type(node.fontShadow) == "boolean") then
		node.fontStyle = replacement
		changed = changed + 1
	end

	for key, value in pairs(node) do
		if type(value) == "table" then
			changed = changed + overwriteNestedFontSettings(value, mode, replacement, visited)
		elseif type(value) == "string" then
			if mode == "font" then
				if isRecursiveFontFaceKey(key) and value ~= replacement then
					node[key] = replacement
					changed = changed + 1
				end
			elseif isRecursiveFontStyleKey(key) and value ~= replacement then
				node[key] = replacement
				changed = changed + 1
			end
		end
	end

	return changed
end

local function overwriteProfileFontSettings(mode)
	if type(addon.db) ~= "table" then return end

	local replacement
	if mode == "font" then
		replacement = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__"
	else
		replacement = addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
	end

	local changed = 0
	for key, value in pairs(addon.db) do
		if mode == "font" then
			if SUPPORTED_FLAT_FONT_KEYS[key] and addon.db[key] ~= replacement then
				addon.db[key] = replacement
				changed = changed + 1
			end
		elseif SUPPORTED_FLAT_FONT_STYLE_KEYS[key] and addon.db[key] ~= replacement then
			addon.db[key] = replacement
			changed = changed + 1
		end

		if SUPPORTED_GLOBAL_FONT_ROOT_KEYS[key] and type(value) == "table" then
			changed = changed + overwriteNestedFontSettings(value, mode, replacement)
		end
	end

	if changed > 0 then refreshGlobalFonts() end
end

local function markReloadRequired()
	addon.variables.requireReload = true
	if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
end

local function applyDefaultProfileToAllCharacters()
	if type(EnhanceQoLDB) ~= "table" then return 0 end
	local profileName = EnhanceQoLDB.profileGlobal
	if type(profileName) ~= "string" or profileName == "" then return 0 end

	EnhanceQoLDB.profileKeys = type(EnhanceQoLDB.profileKeys) == "table" and EnhanceQoLDB.profileKeys or {}
	local keys = EnhanceQoLDB.profileKeys
	local applied = 0
	for guid in pairs(keys) do
		keys[guid] = profileName
		applied = applied + 1
	end

	local currentGUID = UnitGUID("player")
	if currentGUID and keys[currentGUID] ~= profileName then
		keys[currentGUID] = profileName
		applied = applied + 1
	end

	markReloadRequired()
	return applied
end

local function showApplyDefaultProfileToAllPopup()
	local profileName = EnhanceQoLDB and EnhanceQoLDB.profileGlobal
	if type(profileName) ~= "string" or profileName == "" then return end

	StaticPopupDialogs["EQOL_APPLY_DEFAULT_PROFILE_TO_ALL"] = StaticPopupDialogs["EQOL_APPLY_DEFAULT_PROFILE_TO_ALL"]
		or {
			button1 = ACCEPT,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	StaticPopupDialogs["EQOL_APPLY_DEFAULT_PROFILE_TO_ALL"].text = (L["ProfileApplyDefaultToAllConfirm"] or 'Apply default profile "%s" to all known characters?'):format(profileName)
	StaticPopupDialogs["EQOL_APPLY_DEFAULT_PROFILE_TO_ALL"].OnAccept = function()
		local applied = applyDefaultProfileToAllCharacters()
		print("|cff00ff98Enhance QoL|r: " .. (L["ProfileApplyDefaultToAllDone"] or "Applied default profile to %d characters. Reload required."):format(applied))
	end
	StaticPopup_Show("EQOL_APPLY_DEFAULT_PROFILE_TO_ALL")
end

local function showOverwriteProfileFontSettingsPopup(mode)
	local popupKey = "EQOL_OVERWRITE_GLOBAL_FONT_SETTINGS"
	local text
	if mode == "style" then
		text = L["OverwriteAllFontStylingToGlobalConfirm"]
			or "Use global font styling for all supported settings in the active profile? Reload required."
	else
		text = L["OverwriteAllFontsToGlobalConfirm"]
			or "Use global font for all supported settings in the active profile? Reload required."
	end

	StaticPopupDialogs[popupKey] = StaticPopupDialogs[popupKey]
		or {
			text = "",
			button1 = YES,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnAccept = function(self)
				local selectedMode = self.data
				if selectedMode ~= "font" and selectedMode ~= "style" then return end
				overwriteProfileFontSettings(selectedMode)
				markReloadRequired()
			end,
		}
	StaticPopupDialogs[popupKey].text = text
	StaticPopup_Show(popupKey, nil, nil, mode)
end

local function createGlobalFontSettings(section)
	addon.functions.SettingsCreateScrollDropdown(profilesCategory, {
		var = "globalFontFace",
		text = L["globalFontConfigLabel"] or "Global font",
		listFunc = buildGlobalFontDropdown,
		order = globalFontOrder,
		default = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT,
		get = function()
			local current = addon.db and addon.db.globalFontFace or ((addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT)
			local list = buildGlobalFontDropdown()
			if not list[current] then current = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT end
			return current
		end,
		set = function(value)
			addon.db.globalFontFace = value
			refreshGlobalFonts()
		end,
		parentSection = section,
	})

	do
		local globalStyleOptions, globalStyleOrder = addon.functions.GetFontStyleOptions and addon.functions.GetFontStyleOptions(false) or {
			NONE = _G.NONE or "None",
			OUTLINE = L["Outline"] or "Outline",
		}, { "NONE", "OUTLINE" }
		addon.functions.SettingsCreateScrollDropdown(profilesCategory, {
			var = "globalFontStyle",
			text = L["globalFontStyleConfigLabel"] or "Global font style",
			list = globalStyleOptions,
			order = globalStyleOrder,
			height = 220,
			default = "OUTLINE",
			get = function()
				if addon.functions and addon.functions.GetGlobalDefaultFontStyle then return addon.functions.GetGlobalDefaultFontStyle() end
				return addon.db and addon.db.globalFontStyle or "OUTLINE"
			end,
			set = function(value)
				if addon.functions and addon.functions.NormalizeFontStyleChoice then
					addon.db.globalFontStyle = addon.functions.NormalizeFontStyleChoice(value, "OUTLINE", false)
				else
					addon.db.globalFontStyle = value
				end
				refreshGlobalFonts()
			end,
			parentSection = section,
		})
	end

	addon.functions.SettingsCreateButton(profilesCategory, {
		var = "overwriteAllFontsToGlobal",
		text = L["OverwriteAllFontsToGlobal"] or "Fonts global",
		func = function() showOverwriteProfileFontSettingsPopup("font") end,
		parentSection = section,
	})

	addon.functions.SettingsCreateButton(profilesCategory, {
		var = "overwriteAllFontStylingToGlobal",
		text = L["OverwriteAllFontStylingToGlobal"] or "Styles global",
		func = function() showOverwriteProfileFontSettingsPopup("style") end,
		parentSection = section,
	})
end

-- Build a sorted dropdown list, optionally keeping an empty entry pinned to the top
local function trimAddonProfileName(name)
	if type(name) ~= "string" then return nil end
	local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then return nil end
	return trimmed
end

local function buildSortedProfileList(orderTarget, excludeFunc, includeEmpty)
	local list = {}
	local order = orderTarget or {}
	if orderTarget then wipe(orderTarget) end

	if includeEmpty then
		list[""] = ""
		table.insert(order, "")
	end

	local entries = {}
	for name in pairs(EnhanceQoLDB.profiles) do
		local normalizedName = trimAddonProfileName(name)
		if normalizedName and not entries[normalizedName] and (not excludeFunc or not excludeFunc(normalizedName)) then
			entries[normalizedName] = true
			table.insert(entries, normalizedName)
		end
	end

	table.sort(entries, function(a, b)
		local la, lb = string.lower(a), string.lower(b)
		if la == lb then return a < b end
		return la < lb
	end)
	for _, name in ipairs(entries) do
		list[name] = name
		table.insert(order, name)
	end

	return list
end

local function getActiveProfileName()
	if not EnhanceQoLDB or type(EnhanceQoLDB.profileKeys) ~= "table" then return nil end
	local guid = UnitGUID("player")
	local profile = guid and EnhanceQoLDB.profileKeys[guid]
	if trimAddonProfileName(profile) and EnhanceQoLDB.profiles and type(EnhanceQoLDB.profiles[profile]) == "table" then return profile end
	if trimAddonProfileName(EnhanceQoLDB.profileGlobal) and EnhanceQoLDB.profiles and type(EnhanceQoLDB.profiles[EnhanceQoLDB.profileGlobal]) == "table" then return EnhanceQoLDB.profileGlobal end
	return nil
end

local function getValidProfileName(value)
	local name = trimAddonProfileName(value)
	if not name then return nil end
	if type(EnhanceQoLDB) ~= "table" or type(EnhanceQoLDB.profiles) ~= "table" then return nil end
	if type(EnhanceQoLDB.profiles[name]) ~= "table" then return nil end
	return name
end

local function getFallbackProfileName()
	return getValidProfileName(EnhanceQoLDB and EnhanceQoLDB.profileGlobal) or getValidProfileName("Default")
end

local function getSelectedActiveProfileName()
	local guid = UnitGUID and UnitGUID("player")
	local active = guid and type(EnhanceQoLDB) == "table" and type(EnhanceQoLDB.profileKeys) == "table" and EnhanceQoLDB.profileKeys[guid]
	return getValidProfileName(active) or getFallbackProfileName() or "Default"
end

local function setActiveProfileName(value)
	local name = getValidProfileName(value)
	if not name then return false end
	local guid = UnitGUID and UnitGUID("player")
	if type(guid) ~= "string" or guid == "" then return false end
	EnhanceQoLDB.profileKeys = type(EnhanceQoLDB.profileKeys) == "table" and EnhanceQoLDB.profileKeys or {}
	EnhanceQoLDB.profileKeys[guid] = name
	addon.variables.requireReload = true
	addon.functions.checkReloadFrame()
	return true
end

local function getSelectedGlobalProfileName()
	return getValidProfileName(EnhanceQoLDB and EnhanceQoLDB.profileGlobal) or getValidProfileName("Default") or "Default"
end

local function setGlobalProfileName(value)
	local name = getValidProfileName(value)
	if not name then return false end
	EnhanceQoLDB.profileGlobal = name
	return true
end

local function isProfileInUse(profileName)
	profileName = getValidProfileName(profileName)
	if not profileName then return false end
	if EnhanceQoLDB.profileGlobal == profileName then return true end
	if type(EnhanceQoLDB.profileKeys) == "table" then
		for _, assignedProfile in pairs(EnhanceQoLDB.profileKeys) do
			if assignedProfile == profileName then return true end
		end
	end
	return false
end

local function canDeleteProfile(profileName)
	profileName = getValidProfileName(profileName)
	return profileName ~= nil and not isProfileInUse(profileName)
end

local function getCurrentPlayerGUID()
	local guid = UnitGUID and UnitGUID("player")
	if issecretvalue and issecretvalue(guid) then guid = nil end
	if type(guid) == "string" and guid ~= "" then return guid end
	local fallback = addon and addon.variables and addon.variables.unitPlayerGUID
	if type(fallback) == "string" and fallback ~= "" then return fallback end
	return nil
end

local function trimUFProfileName(name)
	if type(name) ~= "string" then return nil end
	local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then return nil end
	return trimmed
end

local function getUFProfilesRoot(profileData)
	local ufProfiles = type(profileData) == "table" and profileData.ufProfiles or nil
	if type(ufProfiles) ~= "table" then return nil end
	return ufProfiles
end

local function normalizeUFProfileReference(profileData, profileName)
	profileName = trimUFProfileName(profileName)
	if not profileName then return nil end
	local ufProfiles = getUFProfilesRoot(profileData)
	if ufProfiles and type(ufProfiles[profileName]) ~= "table" then return nil end
	return profileName
end

local function normalizeUFSpecMappings(profileData, sourceMappings)
	if type(sourceMappings) ~= "table" then return nil end
	local normalized = {}
	for specKey, mappedProfile in pairs(sourceMappings) do
		local specID = tonumber(specKey)
		local profileName = normalizeUFProfileReference(profileData, mappedProfile)
		if specID and specID > 0 and profileName then normalized[specID] = profileName end
	end
	if not next(normalized) then return nil end
	return normalized
end

local function getCurrentUFSpecContext()
	local currentSpecID
	if PlayerUtil and PlayerUtil.GetCurrentSpecID then
		currentSpecID = PlayerUtil.GetCurrentSpecID()
	end
	if (not currentSpecID or currentSpecID <= 0) and GetSpecialization and GetSpecializationInfo then
		local specIndex = GetSpecialization()
		if specIndex then currentSpecID = select(1, GetSpecializationInfo(specIndex)) end
	end
	if type(currentSpecID) ~= "number" or currentSpecID <= 0 then currentSpecID = nil end

	local classSpecIDs
	local classID = UnitClass and select(3, UnitClass("player")) or nil
	if issecretvalue and issecretvalue(classID) then classID = nil end
	if type(classID) == "number" and classID > 0 and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
		local numSpecs = GetNumSpecializationsForClassID(classID)
		if type(numSpecs) == "number" and numSpecs > 0 then
			for index = 1, numSpecs do
				local specID = select(1, GetSpecializationInfoForClassID(classID, index))
				if type(specID) == "number" and specID > 0 then
					classSpecIDs = classSpecIDs or {}
					classSpecIDs[specID] = true
				end
			end
		end
	end
	if not classSpecIDs and currentSpecID then classSpecIDs = { [currentSpecID] = true } end
	return {
		currentSpecID = currentSpecID,
		classSpecIDs = classSpecIDs,
	}
end

local function getMappedUFProfileForSpec(profileData, specMappings, specID)
	if type(specMappings) ~= "table" or type(specID) ~= "number" or specID <= 0 then return nil end
	return normalizeUFProfileReference(profileData, specMappings[specID] or specMappings[tostring(specID)])
end

local function scoreUFSpecMappings(specMappings, specContext)
	if type(specMappings) ~= "table" then return nil end
	specContext = specContext or getCurrentUFSpecContext()
	local classSpecIDs = specContext.classSpecIDs
	local currentSpecID = specContext.currentSpecID
	local overlap = 0
	local foreign = 0
	local score = 0

	for specID in pairs(specMappings) do
		if classSpecIDs and classSpecIDs[specID] then
			overlap = overlap + 1
			score = score + 10
			if currentSpecID and specID == currentSpecID then score = score + 100 end
		elseif classSpecIDs then
			foreign = foreign + 1
			score = score - 5
		end
	end

	if classSpecIDs and overlap == 0 then return nil end
	return score, overlap, foreign
end

local function resolveLegacyUFCharacterState(profileData, currentGuid)
	local ufProfileKeys = type(profileData.ufProfileKeys) == "table" and profileData.ufProfileKeys or nil
	local ufProfileSpecKeys = type(profileData.ufProfileSpecKeys) == "table" and profileData.ufProfileSpecKeys or nil
	local specContext = getCurrentUFSpecContext()
	local currentSpecID = specContext.currentSpecID
	local selectedGuid
	local selectedMappings

	if ufProfileSpecKeys and currentGuid then
		selectedMappings = normalizeUFSpecMappings(profileData, ufProfileSpecKeys[currentGuid])
		if selectedMappings then selectedGuid = currentGuid end
	end

	if not selectedMappings and ufProfileSpecKeys then
		local bestScore, bestOverlap, bestForeign
		local fallbackGuid, fallbackMappings
		for guid, sourceMappings in pairs(ufProfileSpecKeys) do
			if guid ~= currentGuid then
				local normalized = normalizeUFSpecMappings(profileData, sourceMappings)
				if normalized then
					fallbackGuid = fallbackGuid or guid
					fallbackMappings = fallbackMappings or normalized
					local score, overlap, foreign = scoreUFSpecMappings(normalized, specContext)
					if score ~= nil then
						local isBetter = bestScore == nil
							or score > bestScore
							or (score == bestScore and (overlap or 0) > (bestOverlap or 0))
							or (score == bestScore and (overlap or 0) == (bestOverlap or 0) and (foreign or math.huge) < (bestForeign or math.huge))
						if isBetter then
							bestScore = score
							bestOverlap = overlap
							bestForeign = foreign
							selectedGuid = guid
							selectedMappings = normalized
						end
					end
				end
			end
		end
		if not selectedMappings then
			selectedGuid = fallbackGuid
			selectedMappings = fallbackMappings
		end
	end

	local activeProfile
	if ufProfileKeys and currentGuid then activeProfile = normalizeUFProfileReference(profileData, ufProfileKeys[currentGuid]) end
	if not activeProfile and selectedMappings and currentSpecID then
		activeProfile = getMappedUFProfileForSpec(profileData, selectedMappings, currentSpecID)
	end
	if not activeProfile and ufProfileKeys and selectedGuid then
		activeProfile = normalizeUFProfileReference(profileData, ufProfileKeys[selectedGuid])
	end
	if not activeProfile then activeProfile = normalizeUFProfileReference(profileData, profileData.ufProfileGlobal) end

	return {
		activeProfile = activeProfile,
		sourceGuid = selectedGuid,
		specMappings = selectedMappings,
		specScore = scoreUFSpecMappings(selectedMappings, specContext),
		specContext = specContext,
	}
end

local function captureUFCharacterImportState(profileData)
	if type(profileData) ~= "table" then return nil end
	local guid = getCurrentPlayerGUID()
	if not guid then return nil end

	local state = {
		hasActiveProfile = true,
		hasSpecMappings = true,
	}

	local resolved = resolveLegacyUFCharacterState(profileData, guid)
	local activeProfile = resolved and resolved.activeProfile or nil
	if activeProfile then state.activeProfile = activeProfile end

	local specMappings = resolved and resolved.specMappings or nil
	state.specMappings = specMappings or {}

	if not activeProfile and not next(state.specMappings) then return nil end
	return state
end

local function findLegacyUFCharacterActiveProfile(profileData, currentGuid)
	local resolved = resolveLegacyUFCharacterState(profileData, currentGuid)
	return resolved and resolved.activeProfile or nil
end

local function findLegacyUFCharacterSpecMappings(profileData, currentGuid)
	local resolved = resolveLegacyUFCharacterState(profileData, currentGuid)
	return resolved and resolved.specMappings or nil
end

local function remapImportedUFCharacterState(profileData, meta)
	if type(profileData) ~= "table" then return end
	if not getUFProfilesRoot(profileData) then return end

	local guid = getCurrentPlayerGUID()
	if not guid then return end

	local explicitState = type(meta) == "table" and type(meta.ufCharacter) == "table" and meta.ufCharacter or nil
	local legacyState = resolveLegacyUFCharacterState(profileData, guid)
	local legacySpecScore = legacyState and legacyState.specScore or nil
	local specContext = legacyState and legacyState.specContext or getCurrentUFSpecContext()
	local activeProfile
	local specMappings

	if explicitState then
		if explicitState.hasActiveProfile == true then
			activeProfile = normalizeUFProfileReference(profileData, explicitState.activeProfile)
		end
		if explicitState.hasSpecMappings == true then
			specMappings = normalizeUFSpecMappings(profileData, explicitState.specMappings)
		end
	end

	local explicitSpecScore = scoreUFSpecMappings(specMappings, specContext)
	if legacySpecScore and (not explicitSpecScore or legacySpecScore > explicitSpecScore) then
		specMappings = legacyState.specMappings
	end

	if specMappings and specContext.currentSpecID then
		activeProfile = getMappedUFProfileForSpec(profileData, specMappings, specContext.currentSpecID) or activeProfile
	end
	if not activeProfile and explicitState and explicitState.hasActiveProfile == true then
		activeProfile = normalizeUFProfileReference(profileData, explicitState.activeProfile)
	end
	if not activeProfile and legacyState then activeProfile = legacyState.activeProfile end

	if explicitState and explicitState.hasActiveProfile == true then
		profileData.ufProfileKeys = type(profileData.ufProfileKeys) == "table" and profileData.ufProfileKeys or {}
		profileData.ufProfileKeys[guid] = activeProfile
	elseif activeProfile then
		profileData.ufProfileKeys = type(profileData.ufProfileKeys) == "table" and profileData.ufProfileKeys or {}
		profileData.ufProfileKeys[guid] = activeProfile
	end

	if explicitState and explicitState.hasSpecMappings == true then
		profileData.ufProfileSpecKeys = type(profileData.ufProfileSpecKeys) == "table" and profileData.ufProfileSpecKeys or {}
		profileData.ufProfileSpecKeys[guid] = specMappings
		if not specMappings then profileData.ufProfileSpecKeys[guid] = nil end
	elseif specMappings then
		profileData.ufProfileSpecKeys = type(profileData.ufProfileSpecKeys) == "table" and profileData.ufProfileSpecKeys or {}
		profileData.ufProfileSpecKeys[guid] = specMappings
	end
end

local EXPORT_BLACKLIST = {
	-- runtime/session or external data that should never be shared
	chatChannelHistory = true,
	chatChannelFilters = true,
	chatChannelFiltersEnable = true,
	chatIMFrameData = true,
	-- Legacy EditMode stores are migrated on import/copy and should not be propagated.
	editModeLayouts = true,
	containerActionLayouts = true,
}

local SERIALIZABLE_KEY_TYPES = {
	boolean = true,
	number = true,
	string = true,
}

local SERIALIZABLE_VALUE_TYPES = {
	boolean = true,
	number = true,
	string = true,
}

local function sanitizeSerializableValue(value, activeTables)
	local valueType = type(value)
	if SERIALIZABLE_VALUE_TYPES[valueType] then return value end
	if valueType ~= "table" then return nil end
	if activeTables[value] then return nil end

	activeTables[value] = true

	local clone = {}
	for rawKey, rawValue in pairs(value) do
		local keyType = type(rawKey)
		if SERIALIZABLE_KEY_TYPES[keyType] then
			local sanitizedValue = sanitizeSerializableValue(rawValue, activeTables)
			if sanitizedValue ~= nil then clone[rawKey] = sanitizedValue end
		end
	end

	activeTables[value] = nil
	return clone
end

local function sanitizeProfileData(source)
	if type(source) ~= "table" then return {} end
	local filtered = {}
	local activeTables = {
		[source] = true,
	}
	for key, value in pairs(source) do
		if SERIALIZABLE_KEY_TYPES[type(key)] and not EXPORT_BLACKLIST[key]
			and not (addon.functions and addon.functions.IsPrivateProfileKey and addon.functions.IsPrivateProfileKey(key))
		then
			local sanitizedValue = sanitizeSerializableValue(value, activeTables)
			if sanitizedValue ~= nil then filtered[key] = sanitizedValue end
		end
	end
	return filtered
end

local function filterQuickActionsHotkeys(profileData, currentProfile)
	local quickCast = type(profileData) == "table" and profileData.quickCast or nil
	local menus = type(quickCast) == "table" and quickCast.menus or nil
	if type(menus) ~= "table" then return profileData end
	local currentQuickCast = type(currentProfile) == "table" and currentProfile.quickCast or nil
	local currentMenus = type(currentQuickCast) == "table" and currentQuickCast.menus or nil

	-- QuickActions hotkeys are local input state: exports omit them, while imports
	-- keep the target profile's binding for menu IDs that still exist after an update.
	for menuID, menu in pairs(menus) do
		if type(menu) == "table" then
			menu.hotkey = nil
			local currentMenu = type(currentMenus) == "table" and currentMenus[menuID] or nil
			if type(currentMenu) ~= "table" and type(currentMenus) == "table" then
				local numericMenuID = tonumber(menuID)
				if numericMenuID then currentMenu = currentMenus[numericMenuID] or currentMenus[tostring(numericMenuID)] end
			end
			if type(currentMenu) == "table" and type(currentMenu.hotkey) == "string" and currentMenu.hotkey ~= "" then
				menu.hotkey = currentMenu.hotkey
			end
		end
	end
	return profileData
end

local function copyProtectedProfileValue(target, key, value)
	if type(target) ~= "table" or key == nil then return end
	local sanitized = sanitizeProfileData({ [key] = value })
	if sanitized[key] ~= nil then
		target[key] = sanitized[key]
	else
		target[key] = nil
	end
end

local function preserveProtectedKeys(imported, current, predicate)
	if type(imported) ~= "table" or type(predicate) ~= "function" then return end
	for key in pairs(imported) do
		if predicate(key) then imported[key] = nil end
	end
	if type(current) ~= "table" then return end
	for key, value in pairs(current) do
		if predicate(key) then copyProtectedProfileValue(imported, key, value) end
	end
end

local function profileKeyStartsWith(key, prefix)
	return type(key) == "string" and key:sub(1, #prefix) == prefix
end

local function isActionBarProfileKey(key)
	return profileKeyStartsWith(key, "actionBar")
		or profileKeyStartsWith(key, "mouseoverActionBar")
		or key == "hideMacroNames"
		or key == "hideExtraActionArtwork"
end

local function isBagsProfileKey(key)
	return key == "bags" or key == "bagsProfile" or key == "enableBagsModule"
end

local function isCastbarProfileKey(key)
	return key == "castbar" or key == "castbarTarget"
end

local function isChatSocialProfileKey(key)
	return profileKeyStartsWith(key, "chat")
		or profileKeyStartsWith(key, "communityChat")
		or profileKeyStartsWith(key, "friendsListDecor")
		or profileKeyStartsWith(key, "ignore")
		or profileKeyStartsWith(key, "mailbox")
		or key == "blockDuelRequests"
		or key == "blockPartyInvites"
		or key == "blockPetBattleRequests"
		or key == "enableChatHistory"
		or key == "enableChatIM"
		or key == "enableIgnore"
		or key == "enableMailboxAddressBook"
		or key == "WholeChatWindowClickable"
end

local function isClassBuffReminderProfileKey(key)
	return profileKeyStartsWith(key, "classBuffReminder")
end

local function isCooldownPanelsProfileKey(key)
	return key == "cooldownPanels" or profileKeyStartsWith(key, "cooldownPanels")
end

local function isDataPanelsProfileKey(key)
	return key == "datapanel" or key == "dataPanels"
end

local function isDamageMeterProfileKey(key)
	return profileKeyStartsWith(key, "damageMeter")
end

local function isDungeonCombatProfileKey(key)
	return profileKeyStartsWith(key, "mythicPlus")
		or profileKeyStartsWith(key, "combatText")
		or profileKeyStartsWith(key, "gcdBar")
		or profileKeyStartsWith(key, "honorBar")
		or profileKeyStartsWith(key, "repBar")
		or profileKeyStartsWith(key, "xpBar")
		or profileKeyStartsWith(key, "actionTracker")
		or key == "focusInterruptTracker"
		or key == "mythicPlusBossAlertsConfig"
end

local function isDungeonRaidProfileKey(key)
	return profileKeyStartsWith(key, "mythicPlus")
		or profileKeyStartsWith(key, "talentReminder")
		or key == "autoInsertKeystone"
		or key == "autoKeyStart"
		or key == "closeBagsOnKeyInsert"
		or key == "debugDungeonFilter"
		or key == "dungeonScoreFrameData"
		or key == "dungeonScoreFrameLocked"
		or key == "enableKeystoneHelper"
		or key == "groupfinderShowDungeonScoreFrame"
		or key == "groupfinderShowPartyKeystone"
		or key == "noChatOnPullTimer"
		or key == "PullTimerType"
end

local function isInstanceDifficultyProfileKey(key)
	return profileKeyStartsWith(key, "instanceDifficulty")
end

local function isMouseAccessibilityProfileKey(key)
	return profileKeyStartsWith(key, "mouse")
end

local function isQuickAcceptProfileKey(key)
	return key == "autoAcceptGroupInvite"
		or key == "autoAcceptGroupInviteFriendOnly"
		or key == "autoAcceptGroupInviteGuildOnly"
		or key == "autoAcceptResurrection"
		or key == "autoAcceptResurrectionExcludeAfterlife"
		or key == "autoAcceptResurrectionExcludeCombat"
		or key == "autoAcceptSummon"
		or key == "autoChooseGossip"
		or key == "autoChooseGossipContexts"
		or key == "autoChooseGossipModifier"
		or key == "autoChooseQuest"
		or key == "autoChooseQuestModifier"
		or key == "autogossipID"
		or key == "autogossipInfo"
		or key == "autoQuickLoot"
		or key == "autoQuickLootWithShift"
		or key == "groupfinderSkipRoleSelect"
		or key == "groupfinderSkipRoleSelectOption"
		or key == "ignoreDailyQuests"
		or key == "ignoreCurrencyCostQuests"
		or key == "ignoreGoldCostQuests"
		or key == "ignoreTrivialQuests"
		or key == "ignoreWarbandCompleted"
		or key == "persistSignUpNote"
		or key == "skipSignUpDialog"
end

local function isResourceBarsProfileKey(key)
	return key == "enableResourceFrame"
		or profileKeyStartsWith(key, "gcdBar")
		or key == "personalResourceBarSettings"
		or key == "sharedResourceBarSettings"
		or key == "globalResourceBarSettings"
		or profileKeyStartsWith(key, "honorBar")
		or profileKeyStartsWith(key, "resourceBars")
		or profileKeyStartsWith(key, "repBar")
		or profileKeyStartsWith(key, "xpBar")
end

local function isSkinnerProfileKey(key)
	return profileKeyStartsWith(key, "skinner")
		or profileKeyStartsWith(key, "questTracker")
end

local function isSoundProfileKey(key)
	return profileKeyStartsWith(key, "sound")
		or key == "keepAudioSynced"
end

local function isTeleportCompendiumProfileKey(key)
	return profileKeyStartsWith(key, "portal")
		or profileKeyStartsWith(key, "teleport")
end

local function isTooltipProfileKey(key)
	return profileKeyStartsWith(key, "Tooltip")
end

local function isUnitFramesProfileKey(key)
	return profileKeyStartsWith(key, "uf")
end

local function isVendorProfileKey(key)
	return profileKeyStartsWith(key, "vendor")
		or key == "enableExtendedMerchant"
		or key == "sellAllJunk"
		or key == "showUpgradeArrowOnBagItems"
end

local function removeHealerBuffPlacementFromGroupFrames(groupFrames)
	if type(groupFrames) ~= "table" then return end
	for _, kind in ipairs({ "party", "raid" }) do
		if type(groupFrames[kind]) == "table" then groupFrames[kind].healerBuffPlacement = nil end
	end
end

local function copyHealerBuffPlacementToGroupFrames(importedGroups, currentGroups)
	if type(importedGroups) ~= "table" then return false end
	if type(currentGroups) ~= "table" then return false end
	local copied = false
	for _, kind in ipairs({ "party", "raid" }) do
		local placement = type(currentGroups[kind]) == "table" and currentGroups[kind].healerBuffPlacement or nil
		if type(placement) == "table" then
			importedGroups[kind] = type(importedGroups[kind]) == "table" and importedGroups[kind] or {}
			importedGroups[kind].healerBuffPlacement = sanitizeProfileData(placement)
			copied = true
		end
	end
	return copied
end

local function preserveHealerBuffPlacementGroupFrames(importedOwner, currentOwner)
	if type(importedOwner) ~= "table" then return end
	local importedGroups = type(importedOwner.ufGroupFrames) == "table" and importedOwner.ufGroupFrames or nil
	if importedGroups then removeHealerBuffPlacementFromGroupFrames(importedGroups) end

	local currentGroups = type(currentOwner) == "table" and type(currentOwner.ufGroupFrames) == "table" and currentOwner.ufGroupFrames or nil
	if currentGroups then
		importedOwner.ufGroupFrames = type(importedOwner.ufGroupFrames) == "table" and importedOwner.ufGroupFrames or {}
		copyHealerBuffPlacementToGroupFrames(importedOwner.ufGroupFrames, currentGroups)
	end
	if type(importedOwner.ufGroupFrames) == "table" and not next(importedOwner.ufGroupFrames) then importedOwner.ufGroupFrames = nil end
end

local function copyHealerBuffPlacement(imported, current)
	if type(imported) ~= "table" then return end
	preserveHealerBuffPlacementGroupFrames(imported, current)

	local importedProfiles = type(imported.ufProfiles) == "table" and imported.ufProfiles or nil
	if not importedProfiles then return end
	local currentProfiles = type(current) == "table" and type(current.ufProfiles) == "table" and current.ufProfiles or nil
	for profileName, importedProfile in pairs(importedProfiles) do
		if type(importedProfile) == "table" then
			local currentProfile = currentProfiles and currentProfiles[profileName] or nil
			preserveHealerBuffPlacementGroupFrames(importedProfile, currentProfile)
		end
	end
end

local function applyImportProtection(imported, current)
	if type(imported) ~= "table" then return imported end
	if isImportSectionProtected(IMPORT_PROTECTION.ACTION_BARS) then preserveProtectedKeys(imported, current, isActionBarProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.BAGS) then preserveProtectedKeys(imported, current, isBagsProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.CASTBARS) then preserveProtectedKeys(imported, current, isCastbarProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.CHAT_SOCIAL) then preserveProtectedKeys(imported, current, isChatSocialProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.CLASS_BUFF_REMINDER) then preserveProtectedKeys(imported, current, isClassBuffReminderProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.COOLDOWN_PANELS) then preserveProtectedKeys(imported, current, isCooldownPanelsProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.DAMAGE_METER) then preserveProtectedKeys(imported, current, isDamageMeterProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.DATA_PANELS) then preserveProtectedKeys(imported, current, isDataPanelsProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.DUNGEON_COMBAT) then preserveProtectedKeys(imported, current, isDungeonCombatProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.DUNGEON_RAID) then preserveProtectedKeys(imported, current, isDungeonRaidProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.INSTANCE_DIFFICULTY) then preserveProtectedKeys(imported, current, isInstanceDifficultyProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.MOUSE_ACCESSIBILITY) then preserveProtectedKeys(imported, current, isMouseAccessibilityProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.QUICK_ACCEPT) then preserveProtectedKeys(imported, current, isQuickAcceptProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.RESOURCE_BARS) then preserveProtectedKeys(imported, current, isResourceBarsProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.SKINNER) then preserveProtectedKeys(imported, current, isSkinnerProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.SOUND) then preserveProtectedKeys(imported, current, isSoundProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.TELEPORT_COMPENDIUM) then preserveProtectedKeys(imported, current, isTeleportCompendiumProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.TOOLTIP) then preserveProtectedKeys(imported, current, isTooltipProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.UNIT_FRAMES) then preserveProtectedKeys(imported, current, isUnitFramesProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.VENDOR) then preserveProtectedKeys(imported, current, isVendorProfileKey) end
	if isImportSectionProtected(IMPORT_PROTECTION.HBP) then copyHealerBuffPlacement(imported, current) end
	return imported
end

local function encodeExportPayload(payload)
	if not serializer or not deflate then return nil, "NO_LIB" end
	local ok, serialized = pcall(serializer.Serialize, serializer, payload)
	if not ok or type(serialized) ~= "string" or serialized == "" then return nil, "SERIALIZE" end
	local compressed = deflate:CompressDeflate(serialized)
	if not compressed then return nil, "COMPRESS" end
	return deflate:EncodeForPrint(compressed)
end

local function decodeExportPayload(encoded, expectedKind)
	if not serializer or not deflate then return nil, "NO_LIB" end
	encoded = tostring(encoded or "")
	encoded = encoded:gsub("^%s+", ""):gsub("%s+$", "")
	if encoded == "" then return nil, "NO_INPUT" end

	local decoded = deflate:DecodeForPrint(encoded) or deflate:DecodeForWoWChatChannel(encoded) or deflate:DecodeForWoWAddonChannel(encoded)
	if not decoded then return nil, "DECODE" end
	local decompressed = deflate:DecompressDeflate(decoded)
	if not decompressed then return nil, "DECOMPRESS" end
	local ok, payload = serializer:Deserialize(decompressed)
	if not ok or type(payload) ~= "table" then return nil, "DESERIALIZE" end

	local meta = payload.meta
	if type(meta) ~= "table" or meta.addon ~= addonName or meta.kind ~= expectedKind then return nil, "INVALID" end
	return payload
end

local function exportPayloadWithData(kind, data, version)
	if type(data) ~= "table" or not next(data) then return nil, "NO_DATA" end
	return encodeExportPayload({
		meta = {
			addon = addonName,
			kind = kind,
			version = tostring(C_AddOns.GetAddOnMetadata(addonName, "Version") or ""),
			profileVersion = version or 1,
		},
		data = data,
	})
end

local function captureBagsCategoriesState()
	if addon.InitializeSavedVariables then addon.InitializeSavedVariables() end
	local settings = addon.GetSettings and addon.GetSettings() or type(EnhanceQoLBagsDB) == "table" and EnhanceQoLBagsDB.settings or nil
	if type(settings) ~= "table" then return nil end
	local categoryModes = sanitizeProfileData(settings.categoryModes)
	local hasCategories = type(categoryModes) == "table" and next(categoryModes) ~= nil
	if not hasCategories then return nil end
	return {
		categoryModes = categoryModes,
	}
end

local function applyImportedBagsCategoriesState(data)
	if type(data) ~= "table" or type(data.categoryModes) ~= "table" then return false, "NO_DATA" end
	if addon.InitializeSavedVariables then addon.InitializeSavedVariables() end
	local settings = addon.GetSettings and addon.GetSettings() or type(EnhanceQoLBagsDB) == "table" and EnhanceQoLBagsDB.settings or nil
	if type(settings) ~= "table" then return false, "NO_DB" end

	settings.categoryModes = sanitizeProfileData(data.categoryModes)

	if addon.InitializeCategoryModeSettings then addon.InitializeCategoryModeSettings(false) end
	if addon.MarkCategoryModeStateDirty then addon.MarkCategoryModeStateDirty() end
	if addon.Bags and addon.Bags.functions then
		if addon.Bags.functions.RequestLayoutUpdate then addon.Bags.functions.RequestLayoutUpdate(true, true) end
		if addon.Bags.functions.RequestBankLayoutUpdate then addon.Bags.functions.RequestBankLayoutUpdate(true, true) end
	end
	if addon.RefreshSettingsFrame then addon.RefreshSettingsFrame("categories", true) end
	return true
end

local function exportBagsCategories()
	return exportPayloadWithData(BAGS_CATEGORIES_EXPORT_KIND, captureBagsCategoriesState(), 1)
end

local function importBagsCategories(encoded)
	local payload, reason = decodeExportPayload(encoded, BAGS_CATEGORIES_EXPORT_KIND)
	if not payload then return false, reason end
	return applyImportedBagsCategoriesState(payload.data)
end

local function captureDamageMeterState()
	local profileName = getActiveProfileName()
	local source = profileName and EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName] or nil
	if type(source) ~= "table" then return nil end
	local data = {}
	for key, value in pairs(source) do
		if isDamageMeterProfileKey(key) then copyProtectedProfileValue(data, key, value) end
	end
	return next(data) and data or nil
end

local function applyImportedDamageMeterState(data)
	if type(data) ~= "table" then return false, "NO_DATA" end
	local profileName = getActiveProfileName()
	local target = profileName and EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName] or nil
	if type(target) ~= "table" then return false, "NO_ACTIVE" end
	local sanitized = sanitizeProfileData(data)
	local applied = false
	for key in pairs(target) do
		if isDamageMeterProfileKey(key) then target[key] = nil end
	end
	for key, value in pairs(sanitized) do
		if isDamageMeterProfileKey(key) then
			target[key] = value
			applied = true
		end
	end
	if not applied then return false, "NO_DATA" end
	if addon.db == target and addon.DamageMeter then
		addon.DamageMeter.normalizedWindowsDB = nil
		if addon.DamageMeter.UpdateEventState then addon.DamageMeter:UpdateEventState() end
		if addon.DamageMeter.Refresh then addon.DamageMeter:Refresh() end
	end
	return true
end

local function exportDamageMeter()
	return exportPayloadWithData(DAMAGE_METER_EXPORT_KIND, captureDamageMeterState(), 1)
end

local function importDamageMeter(encoded)
	local payload, reason = decodeExportPayload(encoded, DAMAGE_METER_EXPORT_KIND)
	if not payload then return false, reason end
	return applyImportedDamageMeterState(payload.data)
end

local function captureMythicPlusTimerState()
	local profileName = getActiveProfileName()
	local source = profileName and EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName] or nil
	local config = type(source) == "table" and source.mythicPlusTimer or nil
	if type(config) ~= "table" then return nil end
	local data = sanitizeProfileData(config)
	return next(data) and { mythicPlusTimer = data } or nil
end

local function applyImportedMythicPlusTimerState(data)
	if type(data) ~= "table" or type(data.mythicPlusTimer) ~= "table" then return false, "NO_DATA" end
	local profileName = getActiveProfileName()
	local target = profileName and EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName] or nil
	if type(target) ~= "table" then return false, "NO_ACTIVE" end
	target.mythicPlusTimer = sanitizeProfileData(data.mythicPlusTimer)
	if target.mythicPlusTimer.layoutMode == nil then target.mythicPlusTimer.layoutMode = "PANEL" end
	if addon.db == target then
		local timer = addon.MythicPlus and addon.MythicPlus.MythicPlusTimer
		if timer then
			if timer.UpdateEventState then timer:UpdateEventState() end
			if timer.Refresh then timer:Refresh() end
		end
	end
	return true
end

local function exportMythicPlusTimer()
	return exportPayloadWithData(MYTHIC_PLUS_TIMER_EXPORT_KIND, captureMythicPlusTimerState(), 2)
end

local function importMythicPlusTimer(encoded)
	local payload, reason = decodeExportPayload(encoded, MYTHIC_PLUS_TIMER_EXPORT_KIND)
	if not payload then return false, reason end
	return applyImportedMythicPlusTimerState(payload.data)
end

local function captureHBPState()
	local GF = addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFrames
	if GF and GF.EnsureDB then GF:EnsureDB() end
	local groupFrames = addon.db and addon.db.ufGroupFrames
	if type(groupFrames) ~= "table" then return nil end

	local data = {}
	for _, kind in ipairs({ "party", "raid" }) do
		local cfg = type(groupFrames[kind]) == "table" and groupFrames[kind] or nil
		local placement = cfg and cfg.healerBuffPlacement
		if type(placement) == "table" then data[kind] = sanitizeProfileData(placement) end
	end
	return next(data) and data or nil
end

local function applyImportedHBPState(data)
	if type(data) ~= "table" then return false, "NO_DATA" end
	local GF = addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFrames
	if GF and GF.EnsureDB then GF:EnsureDB() end
	addon.db = addon.db or {}
	addon.db.ufGroupFrames = addon.db.ufGroupFrames or {}
	local groupFrames = addon.db.ufGroupFrames

	local applied = false
	for _, kind in ipairs({ "party", "raid" }) do
		local incoming = data[kind]
		if type(incoming) == "table" then
			groupFrames[kind] = type(groupFrames[kind]) == "table" and groupFrames[kind] or {}
			groupFrames[kind].healerBuffPlacement = sanitizeProfileData(incoming)
			applied = true
		end
	end
	if not applied then return false, "NO_DATA" end

	if GF and GF.ResetDBCache then GF:ResetDBCache() end
	if GF and GF.RefreshHealerBuffPlacement then GF:RefreshHealerBuffPlacement() end
	local editor = addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFramesHealerBuffEditor
	if editor and editor.IsShown and editor:IsShown() and editor.RefreshAll then editor:RefreshAll() end
	return true
end

local function exportHBP()
	return exportPayloadWithData(HBP_EXPORT_KIND, captureHBPState(), 1)
end

local function importHBP(encoded)
	local payload, reason = decodeExportPayload(encoded, HBP_EXPORT_KIND)
	if not payload then return false, reason end
	return applyImportedHBPState(payload.data)
end

local function normalizeProfileStorage(profileData, meta)
	if type(profileData) ~= "table" then return end
	if type(profileData.mythicPlusTimer) == "table" and profileData.mythicPlusTimer.layoutMode == nil then profileData.mythicPlusTimer.layoutMode = "PANEL" end
	if addon and addon.EditMode and addon.EditMode.MigrateProfileData then addon.EditMode:MigrateProfileData(profileData) end
	if addon and addon.ContainerActions and addon.ContainerActions.MigrateProfileData then addon.ContainerActions:MigrateProfileData(profileData) end
	if type(meta) == "table" then remapImportedUFCharacterState(profileData, meta) end
end

local function resolveExportProfileName(profileName)
	if type(profileName) == "string" and profileName ~= "" then return profileName end
	return getActiveProfileName()
end

local function resolveImportProfileName(meta)
	if type(meta) ~= "table" then return nil end
	local profileName = meta.profile
	if type(profileName) == "string" and profileName ~= "" then return profileName end
	return nil
end

local function captureMoverExportState()
	if type(EnhanceQoLMoverDB) ~= "table" or type(EnhanceQoLMoverDB.enabled) ~= "boolean" then return nil end
	return {
		enabled = EnhanceQoLMoverDB.enabled,
	}
end

local function captureBagsExportState()
	if type(EnhanceQoLBagsDB) ~= "table" or not next(EnhanceQoLBagsDB) then return nil end
	return sanitizeProfileData(EnhanceQoLBagsDB)
end

local function applyImportedMoverState(meta)
	local mover = type(meta) == "table" and meta.mover or nil
	if type(mover) ~= "table" or type(mover.enabled) ~= "boolean" then return end

	if type(EnhanceQoLMoverDB) ~= "table" then EnhanceQoLMoverDB = {} end
	EnhanceQoLMoverDB.enabled = mover.enabled

	if addon.Mover and addon.Mover.db then addon.Mover.db.enabled = mover.enabled end
	if addon.Mover and addon.Mover.functions then
		if addon.Mover.functions.ApplyAll then addon.Mover.functions.ApplyAll() end
		if addon.Mover.functions.UpdateScaleWheelCaptureState then addon.Mover.functions.UpdateScaleWheelCaptureState() end
	end
end

local function applyImportedBagsState(meta)
	local bags = type(meta) == "table" and meta.bags or nil
	if type(bags) ~= "table" then return end

	EnhanceQoLBagsDB = sanitizeProfileData(bags)
	if addon.Bags then
		addon.DB = EnhanceQoLBagsDB
		if addon.InitializeSavedVariables then addon.InitializeSavedVariables() end
	end
end

local function exportActiveProfile(profileName)
	if not serializer or not deflate then return nil, "NO_LIB" end
	profileName = resolveExportProfileName(profileName)
	if not profileName then return nil, "NO_ACTIVE" end
	local source = EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName]
	local moverState = captureMoverExportState()
	local bagsState = captureBagsExportState()
	if type(source) ~= "table" then return nil, "NO_DATA" end
	if not next(source) and not moverState and not bagsState then return nil, "NO_DATA" end
	if next(source) then normalizeProfileStorage(source) end

	local exportData = filterQuickActionsHotkeys(sanitizeProfileData(source))
	local payload = {
		meta = {
			addon = addonName,
			kind = PROFILE_EXPORT_KIND,
			version = tostring(C_AddOns.GetAddOnMetadata(addonName, "Version") or ""),
			profileVersion = 4,
			profile = profileName,
			ufCharacter = captureUFCharacterImportState(source),
			mover = moverState,
			bags = bagsState,
		},
		data = exportData,
	}

	return encodeExportPayload(payload)
end

local function importProfile(encoded, options)
	options = options or {}
	local payload, decodeReason = decodeExportPayload(encoded, PROFILE_EXPORT_KIND)
	if not payload then return false, decodeReason end

	local meta = payload.meta
	local data = payload.data
	if type(data) ~= "table" then return false, "NO_DATA" end

	local activeTarget = getActiveProfileName()
	local importedTarget = resolveImportProfileName(meta)
	local useImportedTarget = options.preferImportedProfileName == true and importedTarget ~= nil
	local target = useImportedTarget and importedTarget or activeTarget
	if not target then return false, "NO_ACTIVE" end

	if not EnhanceQoLDB or type(EnhanceQoLDB.profiles) ~= "table" then return false, "NO_DB" end

	local current = EnhanceQoLDB.profiles[target]
	local sanitized = filterQuickActionsHotkeys(sanitizeProfileData(data), current)
	normalizeProfileStorage(sanitized, meta)
	applyImportProtection(sanitized, current)
	EnhanceQoLDB.profiles[target] = sanitized
	if not isImportSectionProtected(IMPORT_PROTECTION.MOVER) then applyImportedMoverState(meta) end
	if not isImportSectionProtected(IMPORT_PROTECTION.BAGS) then applyImportedBagsState(meta) end

	if useImportedTarget then
		if options.setImportedProfileActive == true then
			local guid = UnitGUID("player")
			EnhanceQoLDB.profileKeys = EnhanceQoLDB.profileKeys or {}
			if guid then EnhanceQoLDB.profileKeys[guid] = target end
		end
		if options.setImportedProfileGlobal == true then EnhanceQoLDB.profileGlobal = target end
	end

	if target == activeTarget or (useImportedTarget and options.setImportedProfileActive == true) then addon.db = EnhanceQoLDB.profiles[target] end

	return true
end

local function importActiveProfile(encoded) return importProfile(encoded) end

local function importExternalProfile(encoded)
	return importProfile(encoded, {
		preferImportedProfileName = true,
		setImportedProfileActive = true,
		setImportedProfileGlobal = true,
	})
end

-- Public API for external installers (e.g. WagoInstaller).
addon.exportProfile = exportActiveProfile
addon.importProfile = importExternalProfile

local function exportErrorMessage(reason)
	if reason == "NO_ACTIVE" then return L["ProfileExportNoActive"] or "No active profile found." end
	if reason == "NO_DATA" then return L["ProfileExportEmpty"] or "Active profile has no saved settings to export." end
	return L["ProfileExportFailed"] or "Profile export failed."
end

local function importErrorMessage(reason)
	if reason == "NO_INPUT" then return L["ProfileImportEmpty"] or "Please paste a code to import." end
	if reason == "INVALID" or reason == "DECODE" or reason == "DECOMPRESS" or reason == "DESERIALIZE" then return L["The code could not be read."] or "The code could not be read." end
	if reason == "NO_ACTIVE" or reason == "NO_DB" then return L["ProfileExportNoActive"] or "No active profile found." end
	return L["ProfileImportFailed"] or "Profile import failed."
end

local function dataExportErrorMessage(reason)
	if reason == "NO_DATA" then return L["DataExportEmpty"] or "No saved data to export." end
	return L["DataExportFailed"] or "Export failed."
end

local function dataImportErrorMessage(reason)
	if reason == "NO_INPUT" then return L["ProfileImportEmpty"] or "Please paste a code to import." end
	if reason == "INVALID" or reason == "DECODE" or reason == "DECOMPRESS" or reason == "DESERIALIZE" then return L["The code could not be read."] or "The code could not be read." end
	return L["DataImportFailed"] or "Import failed."
end

local function showExportCodeDialog(dialogKey, title, code)
	StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
		or {
			text = title,
			button1 = CLOSE,
			hasEditBox = true,
			editBoxWidth = 320,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	StaticPopupDialogs[dialogKey].text = title
	StaticPopupDialogs[dialogKey].OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
		local editBox = self.editBox or self:GetEditBox()
		editBox:SetText(code)
		editBox:HighlightText()
		editBox:SetFocus()
	end
	StaticPopup_Show(dialogKey)
end

local function showImportCodeDialog(dialogKey, title, confirmText, importFunc, successText, reloadOnSuccess)
	StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
		or {
			text = confirmText,
			button1 = OKAY,
			button2 = CANCEL,
			hasEditBox = true,
			editBoxWidth = 320,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	StaticPopupDialogs[dialogKey].text = confirmText
	StaticPopupDialogs[dialogKey].OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
		local editBox = self.editBox or self:GetEditBox()
		editBox:SetText("")
		editBox:SetFocus()
	end
	StaticPopupDialogs[dialogKey].EditBoxOnEnterPressed = function(editBox)
		local parent = editBox:GetParent()
		if parent and parent.button1 then parent.button1:Click() end
	end
	StaticPopupDialogs[dialogKey].OnAccept = function(self)
		local editBox = self.editBox or self:GetEditBox()
		local input = editBox:GetText() or ""
		local ok, reason = importFunc(input)
		if not ok then
			print("|cff00ff98Enhance QoL|r: " .. tostring(dataImportErrorMessage(reason)))
			return
		end
		print("|cff00ff98Enhance QoL|r: " .. successText)
		if reloadOnSuccess then C_UI.Reload() end
	end
	StaticPopupDialogs[dialogKey].text = title and (title .. "\n\n" .. confirmText) or confirmText
	StaticPopup_Show(dialogKey)
end

addon.ProfileTools = addon.ProfileTools or {}
addon.ProfileTools.ExportBagsCategories = exportBagsCategories
addon.ProfileTools.ImportBagsCategories = importBagsCategories
addon.ProfileTools.ExportDamageMeter = exportDamageMeter
addon.ProfileTools.ImportDamageMeter = importDamageMeter
addon.ProfileTools.ExportMythicPlusTimer = exportMythicPlusTimer
addon.ProfileTools.ImportMythicPlusTimer = importMythicPlusTimer
addon.ProfileTools.ExportHBP = exportHBP
addon.ProfileTools.ImportHBP = importHBP
addon.ProfileTools.ShowExportCodeDialog = showExportCodeDialog
addon.ProfileTools.ShowImportCodeDialog = showImportCodeDialog
addon.ProfileTools.DataExportErrorMessage = dataExportErrorMessage

local data = {
	listFunc = function() return buildSortedProfileList(profileOrderActive) end,
	order = profileOrderActive,
	text = L["Active profile"],
	desc = L["ProfileActiveDesc"] or "Profile used by this character. This overrides the default profile.",
	get = getSelectedActiveProfileName,
	set = setActiveProfileName,
	default = "Default",
	storage = false,
	var = "profiledata",
	parentSection = expandable,
}

addon.functions.SettingsCreateHeadline(profilesCategory, L["ProfileManagement"] or "Profile management", { parentSection = expandable })
addon.functions.SettingsCreateDropdown(profilesCategory, data)

data = {
	listFunc = function() return buildSortedProfileList(profileOrderGlobal) end,
	order = profileOrderGlobal,
	text = L["Global profile"],
	desc = L["ProfileDefaultDesc"] or "Profile used for new characters that do not have an active profile assigned yet.",
	get = getSelectedGlobalProfileName,
	set = setGlobalProfileName,
	default = "Default",
	storage = false,
	var = "profilefirststart",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(profilesCategory, data)
addon.functions.SettingsCreateText(profilesCategory, L["ProfileUseGlobalDesc"], { parentSection = expandable })
addon.functions.SettingsCreateButton(profilesCategory, {
	var = "profileApplyDefaultToAll",
	text = L["ProfileApplyDefaultToAll"] or "Apply default profile to all characters",
	desc = L["ProfileApplyDefaultToAllDesc"] or "Sets the active profile of every known character to the default profile. Reload required.",
	func = showApplyDefaultProfileToAllPopup,
	parentSection = expandable,
})

data = {
	listFunc = function()
		local currentProfile = getSelectedActiveProfileName()
		return buildSortedProfileList(profileOrderCopy, function(name) return name == currentProfile end, true)
	end,
	order = profileOrderCopy,
	text = L["Copy settings from profile"],
	get = function() return "" end,
	set = function(value)
		if value ~= "" then
			local sourceProfile = getValidProfileName(value)
			if not sourceProfile then return false end
			StaticPopupDialogs["EQOL_COPY_PROFILE"] = StaticPopupDialogs["EQOL_COPY_PROFILE"]
				or {
					text = "",
					button1 = YES,
					button2 = CANCEL,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
					OnAccept = function(self)
						local source = getValidProfileName(self.data)
						if not source then return end
						local target = getSelectedActiveProfileName()
						if not target then return end
						local copied = sanitizeProfileData(EnhanceQoLDB.profiles[source])
						normalizeProfileStorage(copied)
						EnhanceQoLDB.profiles[target] = copied
						C_UI.Reload()
					end,
				}
			StaticPopupDialogs["EQOL_COPY_PROFILE"].text = L["ProfileCopyDesc"]:format(value)
			StaticPopup_Show("EQOL_COPY_PROFILE", nil, nil, sourceProfile)
			return true
		end
		return false
	end,
	default = "",
	storage = false,
	var = "profilecopy",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(profilesCategory, data)

data = {
	listFunc = function()
		return buildSortedProfileList(profileOrderDelete, function(name) return not canDeleteProfile(name) end, true)
	end,
	order = profileOrderDelete,
	text = L["Delete profile"],
	get = function() return "" end,
	set = function(value)
		if value ~= "" then
			local deleteProfile = getValidProfileName(value)
			if not deleteProfile or not canDeleteProfile(deleteProfile) then return false end
			StaticPopupDialogs["EQOL_DELETE_PROFILE"] = StaticPopupDialogs["EQOL_DELETE_PROFILE"]
				or {
					text = "",
					button1 = YES,
					button2 = CANCEL,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
					OnAccept = function(self)
						local profile = getValidProfileName(self.data)
						if canDeleteProfile(profile) then EnhanceQoLDB.profiles[profile] = nil end
					end,
				}
			StaticPopupDialogs["EQOL_DELETE_PROFILE"].text = L["ProfileDeleteDesc"]:format(value)
			StaticPopup_Show("EQOL_DELETE_PROFILE", nil, nil, deleteProfile)
			return true
		end
		return false
	end,
	desc = L["ProfileDeleteDesc2"],
	default = "",
	storage = false,
	var = "profiledelete",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(profilesCategory, data)

data = {
	var = "AddProfile",
	text = L["ProfileName"],
	func = function() StaticPopup_Show("EQOL_CREATE_PROFILE") end,
	parentSection = expandable,
}
addon.functions.SettingsCreateButton(profilesCategory, data)

addon.functions.SettingsCreateHeadline(profilesCategory, L["Export / Import"] or "Export / Import", { parentSection = expandable })

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "profileExport",
	text = L["Export profile"] or (L["Export"] or "Export"),
	func = function()
		local code, reason = exportActiveProfile()
		if not code then
			print("|cff00ff98Enhance QoL|r: " .. tostring(exportErrorMessage(reason)))
			return
		end
		StaticPopupDialogs["EQOL_PROFILE_EXPORT"] = StaticPopupDialogs["EQOL_PROFILE_EXPORT"]
			or {
				text = L["Export profile"] or "Export profile",
				button1 = CLOSE,
				hasEditBox = true,
				editBoxWidth = 320,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
		StaticPopupDialogs["EQOL_PROFILE_EXPORT"].OnShow = function(self)
			self:SetFrameStrata("TOOLTIP")
			local editBox = self.editBox or self:GetEditBox()
			editBox:SetText(code)
			editBox:HighlightText()
			editBox:SetFocus()
		end
		StaticPopup_Show("EQOL_PROFILE_EXPORT")
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(profilesCategory, {
	var = "profileImport",
	text = L["Import profile"] or (L["Import"] or "Import"),
	func = function()
		StaticPopupDialogs["EQOL_PROFILE_IMPORT"] = StaticPopupDialogs["EQOL_PROFILE_IMPORT"]
			or {
				text = L["ProfileImportConfirm"] or "Importing will overwrite your active profile and reload the UI.",
				button1 = OKAY,
				button2 = CANCEL,
				hasEditBox = true,
				editBoxWidth = 320,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
		StaticPopupDialogs["EQOL_PROFILE_IMPORT"].text = L["ProfileImportConfirm"] or "Importing will overwrite your active profile and reload the UI."
		StaticPopupDialogs["EQOL_PROFILE_IMPORT"].OnShow = function(self)
			self:SetFrameStrata("TOOLTIP")
			local editBox = self.editBox or self:GetEditBox()
			editBox:SetText("")
			editBox:SetFocus()
		end
		StaticPopupDialogs["EQOL_PROFILE_IMPORT"].EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			if parent and parent.button1 then parent.button1:Click() end
		end
		StaticPopupDialogs["EQOL_PROFILE_IMPORT"].OnAccept = function(self)
			local editBox = self.editBox or self:GetEditBox()
			local input = editBox:GetText() or ""
			local ok, reason = importActiveProfile(input)
			if not ok then
				print("|cff00ff98Enhance QoL|r: " .. tostring(importErrorMessage(reason)))
				return
			end
			print("|cff00ff98Enhance QoL|r: " .. (L["ProfileImportSuccess"] or "Profile imported. Reloading UI..."))
			C_UI.Reload()
		end
		StaticPopup_Show("EQOL_PROFILE_IMPORT")
	end,
	parentSection = expandable,
})

importProtectionExpandable = addon.functions.SettingsCreateExpandableSection(profilesCategory, {
	name = L["ProfileImportProtection"] or "Import Protection",
	configPageKey = "ProfilesImportProtection",
	description = L["configCenterPageCardDescProfilesImportProtection"] or L["ProfileImportProtectionDesc"],
	iconKey = "importexport",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesImportProtection",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateHeadline(profilesCategory, L["ProfileImportProtection"] or "Import Protection", { parentSection = importProtectionExpandable })

addon.functions.SettingsCreateMultiDropdown(profilesCategory, {
	var = IMPORT_PROTECTION_KEY,
	text = L["ProfileImportProtection"] or "Protected import sections",
	desc = L["ProfileImportProtectionDesc"] or "Selected sections stay unchanged when importing full profiles or external installer profiles.",
	listFunc = buildImportProtectionDropdown,
	order = importProtectionOrder,
	getSelection = getImportProtectionSelection,
	setSelection = setImportProtectionSelection,
	parentSection = importProtectionExpandable,
})

fontExpandable = addon.functions.SettingsCreateExpandableSection(profilesCategory, {
	name = L["Font"] or "Font",
	configPageKey = "ProfilesGlobalFont",
	description = L["configCenterPageCardDescProfilesGlobalFont"],
	iconKey = "settingspage",
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesGlobalFont",
	modernCategory = "profiles",
	modernOnly = true,
})

addon.functions.SettingsCreateHeadline(profilesCategory, L["Font"] or "Font", { parentSection = fontExpandable })
createGlobalFontSettings(fontExpandable)

----- REGION END
function addon.functions.initProfile()
	StaticPopupDialogs["EQOL_CREATE_PROFILE"] = StaticPopupDialogs["EQOL_CREATE_PROFILE"]
		or {
			text = L["ProfileName"],
			hasEditBox = true,
			button1 = OKAY,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self, data)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if editBox then
					editBox:SetText(data or "")
					editBox:SetFocus()
					editBox:HighlightText()
				end
			end,
			OnAccept = function(self)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				local id = trimAddonProfileName(editBox and editBox:GetText())
				if id then
					if not EnhanceQoLDB.profiles[id] or type(EnhanceQoLDB.profiles[id]) ~= "table" then EnhanceQoLDB.profiles[id] = {} end
				end
			end,
		}
end
