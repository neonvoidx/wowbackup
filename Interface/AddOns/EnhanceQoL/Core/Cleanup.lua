local addonName, addon = ...

addon.functions = addon.functions or {}

local PROFILE_DEBUG_KEYS = {
	"_combatTextTraceEnabled",
	"_combatTextTrace",
	"_cooldownPanelsDebugLog",
	"debugCooldownPanelsSession",
	"xpBarDebug",
	"xpBarDebugLast",
	"classBuffReminderSoundDebugTrace",
	"_focusInterruptTrackerTraceEnabled",
	"_focusInterruptTrackerTrace",
	"resourceBarsDebugTraceEnabled",
	"resourceBarsDebugTraceMaxEntries",
}

local TRANSIENT_PROFILE_KEYS = {
	["_eqolFixedLayoutCache"] = true,
	["_eqolDynamicTargetIndices"] = true,
	["_eqolIsStatic"] = true,
	["_eqolCapacity"] = true,
	["_eqolAbsoluteThresholdColorCache"] = true,
	["_eqolAbsoluteThresholdCurveCache"] = true,
	["_eqolRuntimePrepareStamp"] = true,
	["_rbType"] = true,
	["_rbSourceMode"] = true,
	["_rbSourceSlot"] = true,
	["_resolvedDefaultPowerColor"] = true,
	["_autoEnabledRuntime"] = true,
	["_autoEnableInProgress"] = true,
}

local STAGGER_HIDDEN_COLOR_OVERRIDE_KEYS = {
	"useBarColor",
	"barColor",
	"useClassColor",
	"useMaxColor",
	"maxColor",
	"useGradient",
	"gradientStartColor",
	"gradientEndColor",
	"gradientDirection",
}

local RESOURCE_BAR_REMOVED_SEGMENT_SEPARATOR_KEYS = {
	"showSeparator",
	"separatorColor",
	"separatorThickness",
}

local RESOURCE_BAR_SEGMENTED_POWER_TYPES = {
	ARCANE_CHARGES = true,
	CHI = true,
	COMBO_POINTS = true,
	EBON_MIGHT = true,
	ESSENCE = true,
	HOLY_POWER = true,
	ICICLES = true,
	MAELSTROM_WEAPON = true,
	RUNES = true,
	SOUL_FRAGMENTS_VENGEANCE = true,
	SOUL_SHARDS = true,
	TIP_OF_THE_SPEAR = true,
	VOID_METAMORPHOSIS = true,
}

local RESOURCE_BAR_REMOVED_SEGMENT_THRESHOLD_LINE_KEYS = {
	"showThresholds",
	"useAbsoluteThresholds",
	"thresholds",
	"thresholdColor",
	"thresholdThickness",
	"thresholdCount",
}

local LEGACY_RESOURCE_BAR_EDIT_MODE_IDS = {
	resourceBar_ARCANE_CHARGES = true,
	resourceBar_CHI = true,
	resourceBar_COMBO_POINTS = true,
	resourceBar_EBON_MIGHT = true,
	resourceBar_ENERGY = true,
	resourceBar_ESSENCE = true,
	resourceBar_FOCUS = true,
	resourceBar_FURY = true,
	resourceBar_HEALTH = true,
	resourceBar_HOLY_POWER = true,
	resourceBar_ICICLES = true,
	resourceBar_INSANITY = true,
	resourceBar_LUNAR_POWER = true,
	resourceBar_MAELSTROM = true,
	resourceBar_MAELSTROM_WEAPON = true,
	resourceBar_MANA = true,
	resourceBar_RAGE = true,
	resourceBar_RUNES = true,
	resourceBar_RUNIC_POWER = true,
	resourceBar_SOUL_SHARDS = true,
	resourceBar_STAGGER = true,
	resourceBar_TIP_OF_THE_SPEAR = true,
	resourceBar_VOID_METAMORPHOSIS = true,
}

local LEGACY_PROFILE_KEYS = {
	"TooltipDebuffHideType",
	"TooltipDebuffHideInCombat",
	"TooltipDebuffHideInDungeon",
	"mythicPlusCurrentPull",
	"mythicPlusCurrentPullLocked",
	"mythicPlusCurrentPullFontSize",
	"mythicPlusCurrentPullPoint",
	"mythicPlusCurrentPullX",
	"mythicPlusCurrentPullY",
	"talentReminderActiveBuildLocked",
	"soundMutedSounds",
	"unclampDamageMeter",
	"confirmPatronOrderDialog",
	"confirmReplaceEnchant",
	"optionsFrameScale",
	"showLeaderIconRaidFrame",
	"unitFrameMaxNameLength",
	"unitFrameTruncateNames",
	"enhancedWaypoint",
	"enhancedWaypointGlow",
	"enhancedWaypointScale",
}

-- TODO 12.1 cleanup: when removing native-replaced PTR workarounds, add their stored keys here
-- or to a dedicated cleanup helper. Expected keys: persistAuctionHouseFilter, groupfinderMoveResetButton.
local MULTIDROPDOWN_SCRATCH_PROFILE_KEYS = {
	"bagDisplayOptions",
	"bagItemLevelTargets",
	"lootToastFilters_3",
	"lootToastFilters_4",
	"lootToastFilters_5",
	"resourceBarsSharedEnabled",
	"rb_spec_1",
	"rb_spec_2",
	"rb_spec_3",
	"rb_spec_4",
	"TooltipPlayerDetailsLabel",
	"mouseoverActionBar1_visibility",
	"mouseoverActionBar2_visibility",
	"mouseoverActionBar3_visibility",
	"mouseoverActionBar4_visibility",
	"mouseoverActionBar5_visibility",
	"mouseoverActionBar6_visibility",
	"mouseoverActionBar7_visibility",
	"mouseoverActionBar8_visibility",
	"mouseoverActionBarPet_visibility",
	"mouseoverActionBarStanceBar_visibility",
	"unitframeSettingBagsBar_visibility",
	"unitframeSettingBuffFrame_visibility",
	"unitframeSettingDebuffFrame_visibility",
	"unitframeSettingFocusFrame_visibility",
	"unitframeSettingMicroMenu_visibility",
	"unitframeSettingMinimap_visibility",
	"unitframeSettingPlayerFrame_visibility",
	"unitframeSettingTargetFrame_visibility",
}

local MIGRATED_DATAPANEL_STREAM_OPTION_POSITION_KEYS = {
	bagspace = true,
	combatTime = true,
	coordinates = true,
	currency = true,
	difficulty = true,
	durability = true,
	equipmentsets = true,
	friends = true,
	gold = true,
	hearthstone = true,
	itemlevel = true,
	latency = true,
	location = true,
	lootspec = true,
	microbar = true,
	mythickey = true,
	pettracker = true,
	playername = true,
	realm = true,
	stats = true,
	talent = true,
	time = true,
	volume = true,
}

local REMOVED_DURATION_TEXT_PROFILE_KEYS = {
	"abbreviation",
	"approximationSeconds",
	"bindingUpdateInterval",
	"canRoundUpIntervals",
	"canRoundUpLastUnit",
	"convertToLower",
	"countdownAbbrevThreshold",
	"desiredUnitCount",
	"formatStyle",
	"maxInterval",
	"minInterval",
	"stripIntervalWhitespace",
}

local function cleanupListedProfileKeys(profile, keys)
	if type(profile) ~= "table" then return end
	for i = 1, #keys do
		profile[keys[i]] = nil
	end
end

local function cleanupDebugArtifactsProfile(profile)
	if type(profile) ~= "table" then return end

	for i = 1, #PROFILE_DEBUG_KEYS do
		profile[PROFILE_DEBUG_KEYS[i]] = nil
	end

	if type(profile.cooldownPanels) == "table" then profile.cooldownPanels._eqolBarsDebug = nil end

	if type(profile._temp) == "table" then
		profile._temp.ufProfileDebug = nil
		profile._temp.ufProfileTrace = nil
		if not next(profile._temp) then profile._temp = nil end
	end
end

local function cleanupCombatMeterProfile(profile)
	if type(profile) ~= "table" then return end
	for key in pairs(profile) do
		if type(key) == "string" and key:lower():find("^combatmeter") then profile[key] = nil end
	end

	local editData = profile.editModeData
	if type(editData) == "table" then
		for id in pairs(editData) do
			if type(id) == "string" and id:lower():find("^combatmeter") then editData[id] = nil end
		end
	end

	-- Legacy fallback for profile versions that still carry layout-keyed data.
	local layouts = profile.editModeLayouts
	if type(layouts) ~= "table" then return end
	for layoutName, layout in pairs(layouts) do
		if type(layout) == "table" then
			for id in pairs(layout) do
				if type(id) == "string" and id:lower():find("^combatmeter") then layout[id] = nil end
			end
			if not next(layout) then layouts[layoutName] = nil end
		end
	end
end

local function cleanupBuffTrackerProfile(profile)
	if type(profile) ~= "table" then return end
	for key in pairs(profile) do
		if type(key) == "string" and key:lower():find("^bufftracker") then profile[key] = nil end
	end
end

local function cleanupTransientProfileCaches(root, seen)
	if type(root) ~= "table" then return end
	seen = seen or {}
	if seen[root] then return end
	seen[root] = true

	for key, value in pairs(root) do
		if TRANSIENT_PROFILE_KEYS[key] then
			root[key] = nil
		elseif type(value) == "table" then
			cleanupTransientProfileCaches(value, seen)
		end
	end
end

local function cleanupStaggerHiddenColorOverrides(cfg)
	if type(cfg) ~= "table" then return end
	for i = 1, #STAGGER_HIDDEN_COLOR_OVERRIDE_KEYS do
		cfg[STAGGER_HIDDEN_COLOR_OVERRIDE_KEYS[i]] = nil
	end
end

local function cleanupResourceBarRemovedSegmentSeparatorKeys(cfg)
	if type(cfg) ~= "table" then return end
	for i = 1, #RESOURCE_BAR_REMOVED_SEGMENT_SEPARATOR_KEYS do
		cfg[RESOURCE_BAR_REMOVED_SEGMENT_SEPARATOR_KEYS[i]] = nil
	end
end

local function cleanupResourceBarRemovedSegmentThresholdLineKeys(cfg)
	if type(cfg) ~= "table" then return end
	for i = 1, #RESOURCE_BAR_REMOVED_SEGMENT_THRESHOLD_LINE_KEYS do
		cfg[RESOURCE_BAR_REMOVED_SEGMENT_THRESHOLD_LINE_KEYS[i]] = nil
	end
end

local function cleanupResourceBarConfigTree(root, treeKey)
	if type(root) ~= "table" then return end
	cleanupResourceBarRemovedSegmentSeparatorKeys(root)
	if RESOURCE_BAR_SEGMENTED_POWER_TYPES[treeKey] or RESOURCE_BAR_SEGMENTED_POWER_TYPES[root._rbType] then cleanupResourceBarRemovedSegmentThresholdLineKeys(root) end
	for key, value in pairs(root) do
		if type(value) == "table" then cleanupResourceBarConfigTree(value, key) end
	end
end

local function cleanupResourceBarProfile(profile)
	if type(profile) ~= "table" then return end
	profile.personalResourceBarAnchors = nil

	local editData = profile.editModeData
	if type(editData) == "table" then
		for id in pairs(LEGACY_RESOURCE_BAR_EDIT_MODE_IDS) do
			editData[id] = nil
		end
	end

	local personal = profile.personalResourceBarSettings
	if type(personal) == "table" then
		cleanupResourceBarConfigTree(personal)
		for _, classCfg in pairs(personal) do
			if type(classCfg) == "table" then
				for _, specCfg in pairs(classCfg) do
					if type(specCfg) == "table" then cleanupStaggerHiddenColorOverrides(specCfg.STAGGER) end
				end
			end
		end
	end

	local global = profile.globalResourceBarSettings
	if type(global) == "table" then
		cleanupResourceBarConfigTree(global)
		cleanupStaggerHiddenColorOverrides(global.STAGGER)
	end

	local shared = profile.sharedResourceBarSettings
	if type(shared) == "table" then
		cleanupResourceBarConfigTree(shared)
		for _, slotCfg in pairs(shared) do
			local overrides = type(slotCfg) == "table" and slotCfg.powerTypeOverrides or nil
			if type(overrides) == "table" then cleanupStaggerHiddenColorOverrides(overrides.STAGGER) end
		end
	end
end

local CVAR_PERSISTENCE_REMOVAL_KEYS = {
	"cvarPersistenceEnabled",
	"cvarOverrides",
	"AutoPushSpellToActionBar",
}

local function cleanupRemovedCVarPersistenceKeys(profile)
	if type(profile) ~= "table" then return end
	for i = 1, #CVAR_PERSISTENCE_REMOVAL_KEYS do
		profile[CVAR_PERSISTENCE_REMOVAL_KEYS[i]] = nil
	end
end

local function cleanupMigratedDataPanelStreamOptionPositions(profile)
	if type(profile) ~= "table" then return end
	local dataPanel = profile.datapanel
	if type(dataPanel) ~= "table" then return end
	for streamKey in pairs(MIGRATED_DATAPANEL_STREAM_OPTION_POSITION_KEYS) do
		local streamConfig = dataPanel[streamKey]
		if type(streamConfig) == "table" then
			streamConfig.point = nil
			streamConfig.x = nil
			streamConfig.y = nil
			streamConfig._windowStatus = nil
		end
	end
end

local function cleanupLegacyProfileKeys(profile)
	cleanupListedProfileKeys(profile, LEGACY_PROFILE_KEYS)
	cleanupListedProfileKeys(profile, MULTIDROPDOWN_SCRATCH_PROFILE_KEYS)
	cleanupRemovedCVarPersistenceKeys(profile)
	cleanupMigratedDataPanelStreamOptionPositions(profile)
end

local function cleanupCooldownPanelsStorageProfile(profile)
	if type(profile) ~= "table" then return end
	local root = profile.cooldownPanels
	if type(root) ~= "table" then return end
	local helper = addon.Aura and addon.Aura.CooldownPanels and addon.Aura.CooldownPanels.helper or nil
	if type(helper) == "table" and type(helper.PruneRootForStorage) == "function" then helper.PruneRootForStorage(root) end
end

local function cleanupDurationTextStorageProfile(profile)
	if type(profile) ~= "table" then return end
	local root = profile.durationText
	local profiles = type(root) == "table" and root.profiles or nil
	if type(profiles) ~= "table" then return end
	for _, durationProfile in pairs(profiles) do
		if type(durationProfile) == "table" then
			cleanupListedProfileKeys(durationProfile, REMOVED_DURATION_TEXT_PROFILE_KEYS)
		end
	end
end

function addon.functions.CleanupCombatMeterSettings()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			cleanupCombatMeterProfile(profile)
		end
	elseif addon.db then
		cleanupCombatMeterProfile(addon.db)
	end
end

function addon.functions.CleanupBuffTrackerSettings()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			cleanupBuffTrackerProfile(profile)
		end
	elseif addon.db then
		cleanupBuffTrackerProfile(addon.db)
	end
end

function addon.functions.CleanupDebugArtifacts()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" then
		cleanupDebugArtifactsProfile(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				cleanupDebugArtifactsProfile(profile)
			end
		end
	end

	if addon.db and addon.db ~= db then cleanupDebugArtifactsProfile(addon.db) end
end

function addon.functions.CleanupTransientProfileCaches()
	local db = _G.EnhanceQoLDB
	local seen = {}
	if type(db) == "table" then cleanupTransientProfileCaches(db, seen) end
	if addon.db and addon.db ~= db then cleanupTransientProfileCaches(addon.db, seen) end
end

function addon.functions.CleanupResourceBarStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function cleanup(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupResourceBarProfile(profile)
	end
	if type(db) == "table" then
		cleanup(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				cleanup(profile)
			end
		end
	end
	if addon.db and addon.db ~= db then cleanup(addon.db) end
end

function addon.functions.CleanupLegacyProfileStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function cleanup(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupLegacyProfileKeys(profile)
	end
	if type(db) == "table" then
		cleanup(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				cleanup(profile)
			end
		end
	end
	if addon.db and addon.db ~= db then cleanup(addon.db) end
end

function addon.functions.CleanupCooldownPanelsStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function prune(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupCooldownPanelsStorageProfile(profile)
	end
	if type(db) == "table" then
		prune(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				prune(profile)
			end
		end
	end
	if addon.db and addon.db ~= db then prune(addon.db) end
end

function addon.functions.CleanupDurationTextStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function cleanup(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupDurationTextStorageProfile(profile)
	end
	if type(db) == "table" then
		cleanup(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				cleanup(profile)
			end
		end
	end
	if addon.db and addon.db ~= db then cleanup(addon.db) end
end

function addon.functions.CleanupOldStuff()
	addon.functions.CleanupCombatMeterSettings()
	addon.functions.CleanupBuffTrackerSettings()
	addon.functions.CleanupDebugArtifacts()
	addon.functions.CleanupDurationTextStorage()
	addon.functions.CleanupLegacyProfileStorage()
	addon.functions.CleanupResourceBarStorage()
	addon.functions.CleanupTransientProfileCaches()
end

local cleanupFrame = CreateFrame and CreateFrame("Frame", nil, UIParent or nil)
if cleanupFrame then
	cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
	cleanupFrame:SetScript("OnEvent", function()
		if addon.functions and addon.functions.CleanupTransientProfileCaches then addon.functions.CleanupTransientProfileCaches() end
		if addon.functions and addon.functions.CleanupCooldownPanelsStorage then addon.functions.CleanupCooldownPanelsStorage() end
	end)
end
