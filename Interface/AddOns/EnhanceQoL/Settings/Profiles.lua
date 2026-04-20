local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local wipe = wipe
local serializer = LibStub("AceSerializer-3.0")
local deflate = LibStub("LibDeflate")
local PROFILE_EXPORT_KIND = "EQOL_PROFILE"

local cProfiles = addon.SettingsLayout.rootPROFILES

local expandable = addon.functions.SettingsCreateExpandableSection(cProfiles, {
	name = L["AddOn"],
	expanded = false,
	colorizeTitle = false,
	newTagID = "ProfilesAddOn",
})

local profileOrderActive, profileOrderGlobal, profileOrderCopy, profileOrderDelete = {}, {}, {}, {}
local globalFontOrder = {}

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
	ilvlFontFace = true,
	mythicPlusBloodlustTrackerCooldownFontFace = true,
	mythicPlusBRTrackerChargesFontFace = true,
	mythicPlusBRTrackerCooldownFontFace = true,
	squareMinimapStatsFont = true,
	totalAbsorbTrackerTextFont = true,
	xpBarTextFont = true,
}

local SUPPORTED_FLAT_FONT_STYLE_KEYS = {
	actionBarCountFontOutline = true,
	actionBarHotkeyFontOutline = true,
	actionBarMacroFontOutline = true,
	combatTextFontOutline = true,
	ilvlFontOutline = true,
	mythicPlusBloodlustTrackerCooldownTextOutline = true,
	mythicPlusBRTrackerChargesTextOutline = true,
	mythicPlusBRTrackerCooldownTextOutline = true,
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
	addon.functions.SettingsCreateScrollDropdown(cProfiles, {
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
		addon.functions.SettingsCreateScrollDropdown(cProfiles, {
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

	addon.functions.SettingsCreateButton(cProfiles, {
		var = "overwriteAllFontsToGlobal",
		text = L["OverwriteAllFontsToGlobal"] or "Fonts global",
		func = function() showOverwriteProfileFontSettingsPopup("font") end,
		parentSection = section,
	})

	addon.functions.SettingsCreateButton(cProfiles, {
		var = "overwriteAllFontStylingToGlobal",
		text = L["OverwriteAllFontStylingToGlobal"] or "Styles global",
		func = function() showOverwriteProfileFontSettingsPopup("style") end,
		parentSection = section,
	})
end

-- Build a sorted dropdown list, optionally keeping an empty entry pinned to the top
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
		if not excludeFunc or not excludeFunc(name) then table.insert(entries, name) end
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
	if not EnhanceQoLDB or not EnhanceQoLDB.profileKeys then return nil end
	local guid = UnitGUID("player")
	local profile = guid and EnhanceQoLDB.profileKeys[guid]
	if profile and profile ~= "" then return profile end
	if EnhanceQoLDB.profileGlobal and EnhanceQoLDB.profileGlobal ~= "" then return EnhanceQoLDB.profileGlobal end
	return nil
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

local function normalizeProfileStorage(profileData, meta)
	if type(profileData) ~= "table" then return end
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

local function exportActiveProfile(profileName)
	if not serializer or not deflate then return nil, "NO_LIB" end
	profileName = resolveExportProfileName(profileName)
	if not profileName then return nil, "NO_ACTIVE" end
	local source = EnhanceQoLDB and EnhanceQoLDB.profiles and EnhanceQoLDB.profiles[profileName]
	if type(source) ~= "table" or not next(source) then return nil, "NO_DATA" end
	normalizeProfileStorage(source)

	local payload = {
		meta = {
			addon = addonName,
			kind = PROFILE_EXPORT_KIND,
			version = tostring(C_AddOns.GetAddOnMetadata(addonName, "Version") or ""),
			profileVersion = 3,
			profile = profileName,
			ufCharacter = captureUFCharacterImportState(source),
		},
		data = sanitizeProfileData(source),
	}

	local ok, serialized = pcall(serializer.Serialize, serializer, payload)
	if not ok or type(serialized) ~= "string" or serialized == "" then return nil, "SERIALIZE" end
	local compressed = deflate:CompressDeflate(serialized)
	if not compressed then return nil, "COMPRESS" end
	return deflate:EncodeForPrint(compressed)
end

local function importProfile(encoded, options)
	if not serializer or not deflate then return false, "NO_LIB" end
	options = options or {}
	encoded = tostring(encoded or "")
	encoded = encoded:gsub("^%s+", ""):gsub("%s+$", "")
	if encoded == "" then return false, "NO_INPUT" end

	local decoded = deflate:DecodeForPrint(encoded) or deflate:DecodeForWoWChatChannel(encoded) or deflate:DecodeForWoWAddonChannel(encoded)
	if not decoded then return false, "DECODE" end
	local decompressed = deflate:DecompressDeflate(decoded)
	if not decompressed then return false, "DECOMPRESS" end
	local ok, payload = serializer:Deserialize(decompressed)
	if not ok or type(payload) ~= "table" then return false, "DESERIALIZE" end

	local meta = payload.meta
	local data = payload.data
	if type(meta) ~= "table" or meta.addon ~= addonName or meta.kind ~= PROFILE_EXPORT_KIND then return false, "INVALID" end
	if type(data) ~= "table" then return false, "NO_DATA" end

	local activeTarget = getActiveProfileName()
	local importedTarget = resolveImportProfileName(meta)
	local useImportedTarget = options.preferImportedProfileName == true and importedTarget ~= nil
	local target = useImportedTarget and importedTarget or activeTarget
	if not target then return false, "NO_ACTIVE" end

	if not EnhanceQoLDB or type(EnhanceQoLDB.profiles) ~= "table" then return false, "NO_DB" end

	local sanitized = sanitizeProfileData(data)
	normalizeProfileStorage(sanitized, meta)
	EnhanceQoLDB.profiles[target] = sanitized

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

local data = {
	listFunc = function() return buildSortedProfileList(profileOrderActive) end,
	order = profileOrderActive,
	text = L["Active profile"],
	get = function() return EnhanceQoLDB.profileKeys[UnitGUID("player")] or EnhanceQoLDB.profileGlobal end,
	set = function(value)
		EnhanceQoLDB.profileKeys[UnitGUID("player")] = value
		addon.variables.requireReload = true
		addon.functions.checkReloadFrame()
	end,
	default = "",
	var = "profiledata",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(cProfiles, data)

data = {
	listFunc = function() return buildSortedProfileList(profileOrderGlobal) end,
	order = profileOrderGlobal,
	text = L["Global profile"],
	get = function() return EnhanceQoLDB.profileGlobal end,
	set = function(value) EnhanceQoLDB.profileGlobal = value end,
	default = "",
	var = "profilefirststart",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(cProfiles, data)
addon.functions.SettingsCreateText(cProfiles, L["ProfileUseGlobalDesc"], { parentSection = expandable })

data = {
	listFunc = function()
		local currentProfile = EnhanceQoLDB.profileKeys[UnitGUID("player")]
		return buildSortedProfileList(profileOrderCopy, function(name) return name == currentProfile end, true)
	end,
	order = profileOrderCopy,
	text = L["Copy settings from profile"],
	get = function() return "" end,
	set = function(value)
		if value ~= "" then
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
						local source = self.data
						if not source or source == "" then return end
						local target = EnhanceQoLDB.profileKeys[UnitGUID("player")]
						if not target then return end
						local copied = sanitizeProfileData(EnhanceQoLDB.profiles[source])
						normalizeProfileStorage(copied)
						EnhanceQoLDB.profiles[target] = copied
						C_UI.Reload()
					end,
				}
			StaticPopupDialogs["EQOL_COPY_PROFILE"].text = L["ProfileCopyDesc"]:format(value)
			StaticPopup_Show("EQOL_COPY_PROFILE", nil, nil, value)
		end
	end,
	default = "",
	var = "profilecopy",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(cProfiles, data)

data = {
	listFunc = function()
		local currentProfile = EnhanceQoLDB.profileKeys[UnitGUID("player")]
		local globalProfile = EnhanceQoLDB.profileGlobal
		return buildSortedProfileList(profileOrderDelete, function(name) return name == currentProfile or name == globalProfile end, true)
	end,
	order = profileOrderDelete,
	text = L["Delete profile"],
	get = function() return "" end,
	set = function(value)
		if value ~= "" then
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
						local profile = self.data
						if profile and profile ~= "" then EnhanceQoLDB.profiles[profile] = nil end
					end,
				}
			StaticPopupDialogs["EQOL_DELETE_PROFILE"].text = L["ProfileDeleteDesc"]:format(value)
			StaticPopup_Show("EQOL_DELETE_PROFILE", nil, nil, value)
		end
	end,
	desc = L["ProfileDeleteDesc2"],
	default = "",
	var = "profiledelete",
	parentSection = expandable,
}

addon.functions.SettingsCreateDropdown(cProfiles, data)

data = {
	var = "AddProfile",
	text = L["ProfileName"],
	func = function() StaticPopup_Show("EQOL_CREATE_PROFILE") end,
	parentSection = expandable,
}
addon.functions.SettingsCreateButton(cProfiles, data)

addon.functions.SettingsCreateHeadline(cProfiles, L["Export / Import"] or "Export / Import", { parentSection = expandable })

addon.functions.SettingsCreateButton(cProfiles, {
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

addon.functions.SettingsCreateButton(cProfiles, {
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

addon.functions.SettingsCreateHeadline(cProfiles, L["Font"] or "Font", { parentSection = expandable })
createGlobalFontSettings(expandable)

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
				local id = self:GetEditBox():GetText()
				if id and id ~= "" then
					if not EnhanceQoLDB.profiles[id] or type(EnhanceQoLDB.profiles[id]) ~= "table" then EnhanceQoLDB.profiles[id] = {} end
				end
			end,
		}
end
