local addonName, addon = ...

addon.functions = addon.functions or {}

-- Collapse verified Retail cast/aura variants into one selectable debuff.
function addon.functions.CanonicalNameplateAuraSpellID(id)
	if addon.variables and addon.variables.isForever then return id end
	local aliases = { [8921] = 164812, [155625] = 164812, [93402] = 164815, [1822] = 155722,
		[172] = 146739, [348] = 157736, [772] = 388539, [1253171] = 269747 }
	local canonical = aliases[id]
	if canonical and (not C_Spell or not C_Spell.DoesSpellExist or C_Spell.DoesSpellExist(canonical)) then return canonical end
	return id
end

function addon.functions.MigrateNameplateAuraColorProfile(profile)
	if type(profile) ~= "table" then return end
	if type(profile.custom) ~= "table" then profile.custom = {} end
	if type(profile.rules) ~= "table" then
		profile.rules = {}
		-- Preserve the former priority: combinations before individual debuffs.
		for _, key in ipairs({ "combos", "singles" }) do
			for _, rule in ipairs(type(profile[key]) == "table" and profile[key] or {}) do
				profile.rules[#profile.rules + 1] = rule
			end
		end
	end
	for _, rule in ipairs(profile.rules) do
		if type(rule) == "table" and rule.onlyMine == nil then rule.onlyMine = profile.ownOnly ~= false end
	end
	-- Correct the unavailable Unstable Affliction preset using this client's spell database.
	if C_Spell and C_Spell.DoesSpellExist and not C_Spell.DoesSpellExist(316099) then
		local replacement
		for _, id in ipairs({ 1259790, 30108 }) do if C_Spell.DoesSpellExist(id) then replacement = id; break end end
		if replacement then
			local function replace(ids)
				if type(ids) ~= "table" then return end
				local seen = {}
				for i = #ids, 1, -1 do
					local id = ids[i] == 316099 and replacement or ids[i]
					if seen[id] then table.remove(ids, i) else ids[i], seen[id] = id, true end
				end
			end
			for _, rule in ipairs(profile.rules) do if type(rule) == "table" then replace(rule.spells) end end
			replace(profile.custom)
		end
	end
	if not (addon.variables and addon.variables.isForever) then
		local function correct(ids)
			if type(ids) ~= "table" then return end
			local seen = {}
			for i = #ids, 1, -1 do
				local id = addon.functions.CanonicalNameplateAuraSpellID(ids[i])
				if seen[id] then table.remove(ids, i) else ids[i], seen[id] = id, true end
			end
		end
		for _, rule in ipairs(profile.rules) do if type(rule) == "table" then correct(rule.spells) end end
		correct(profile.custom)
		local customSerpent = false
		for _, id in ipairs(profile.custom or {}) do if id == 271788 then customSerpent = true end end
		-- Retire only an untouched, disabled Serpent Sting default; retain edited rules.
		for i = #profile.rules, 1, -1 do
			local r = profile.rules[i]
			local h, b = type(r) == "table" and r.healthColor, type(r) == "table" and r.borderColor
			if not customSerpent and type(r) == "table" and type(r.spells) == "table" and #r.spells == 1 and r.spells[1] == 271788
				and r.enabled == false and r.onlyMine == true and r.health == true and r.border == false
				and type(h) == "table" and h[1] == 0.2 and h[2] == 0.65 and h[3] == 1 and h[4] == 1
				and type(b) == "table" and b[1] == 1 and b[2] == 0.55 and b[3] == 0 and b[4] == 1 then
				table.remove(profile.rules, i)
			end
		end
	end
	if type(profile.specs) == "table" then
		for _, spec in pairs(profile.specs) do addon.functions.MigrateNameplateAuraColorProfile(spec) end
	end
	profile.combos, profile.singles, profile.ownOnly = nil, nil, nil
	return profile
end

function addon.functions.CleanupNameplateAuraColorRules()
	local function migrate(profile)
		local cfg = type(profile) == "table" and profile.nameplateAuraColorRules
		local classes = type(cfg) == "table" and cfg.classes
		if type(classes) ~= "table" then return end
		for _, classProfile in pairs(classes) do addon.functions.MigrateNameplateAuraColorProfile(classProfile) end
	end
	local db = _G.EnhanceQoLDB
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do migrate(profile) end
	end
	migrate(addon.db)
end

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
	"_playerChoiceTrace",
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
	ESSENCE = true,
	HOLY_POWER = true,
	ICICLES = true,
	MAELSTROM_WEAPON = true,
	RUNES = true,
	SOUL_FRAGMENTS_VENGEANCE = true,
	SOUL_SHARDS = true,
	TIP_OF_THE_SPEAR = true,
	VOID_METAMORPHOSIS = true,
	WHIRLWIND = true,
}

local RESOURCE_BAR_REMOVED_SEGMENT_THRESHOLD_LINE_KEYS = {
	"showThresholds",
	"useAbsoluteThresholds",
	"thresholds",
	"thresholdColor",
	"thresholdThickness",
	"thresholdCount",
}

local BOSS_RANGE_FADE_MIGRATION_FLAG = "_bossRangeFadeSettingInitializedV1"

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

-- Preserve allowRecuperate, healthUseRecuperate, healthUseMageFood, and
-- healthUseCombatPotions: Retail still owns these options, including profiles
-- imported between game flavors. Forever ignores them and uses healthUseFood
-- independently, so a disabled Retail mage-food option cannot disable general food.
local LEGACY_PROFILE_KEYS = {
	"queryAddonProfilerEnabled",
	"queryAddonProfilerDelay",
	"queryFollowupEnabled",
	"classBuffReminderSpellSelections", -- Retired shared Mage protection selection.
	"classBuffReminderMageMagic", -- Replaced by the per-class buff catalogue.
	"teleportNameCache", -- Map names now live only in the session cache.
	-- The new Cooldown Pulse starts with a separate schema; never migrate old notification data.
	"cooldownNotify",
	"cooldownNotifyCategories",
	"cooldownNotifyEnabled",
	"cooldownNotifySounds",
	"cooldownNotifySoundsEnabled",
	"cooldownNotifyDefaultSound",
	"cooldownNotifySelectedCategory",
	"cooldownNotifyLocked",
	"cooldownNotifyOrder",
	"stickyNotes",
	"TooltipDebuffHideType",
	"TooltipDebuffHideInCombat",
	"TooltipDebuffHideInDungeon",
	"mythicPlusCurrentPull",
	"mythicPlusCurrentPullLocked",
	"mythicPlusCurrentPullFontSize",
	"mythicPlusCurrentPullPoint",
	"mythicPlusCurrentPullX",
	"mythicPlusCurrentPullY",
	"mythicPlusObjectiveTrackerSetting",
	"mythicPlusShowChestTimers",
	"talentReminderActiveBuildLocked",
	"soundMutedSounds",
	"unclampDamageMeter",
	"confirmPatronOrderDialog",
	"confirmReplaceEnchant",
	"optionsFrameScale",
	"persistAuctionHouseFilter",
	"showLeaderIconRaidFrame",
	"unitFrameMaxNameLength",
	"unitFrameTruncateNames",
	"enhancedWaypoint",
	"enhancedWaypointGlow",
	"enhancedWaypointScale",
	"groupfinderMoveResetButton",
	"showWorldMapCoordinates",
	"standalonePrivateAuras",
	"worldMapCoordinatesHideCursor",
	"worldMapCoordinatesUpdateInterval",
	"partyKeystoneDungeonIndicatorIconSize",
	"partyKeystoneDungeonIndicatorShowIcon",
	"partyKeystoneDungeonIndicatorShowRealm",
}

local NAMEPLATE_MOB_COLOR_SOURCE_KEYS = {
	"nameplateMobColorFocusEnabled",
	"nameplateMobColorBossEnabled",
	"nameplateMobColorMinibossEnabled",
	"nameplateMobColorCasterEnabled",
	"nameplateMobColorMeleeEnabled",
	"nameplateMobColorNeutralEnabled",
	"nameplateMobColorTappedEnabled",
	"nameplateMobColorTrivialEnabled",
}

local function migrateNameplateMobColorSources(profile)
	if type(profile) ~= "table" then return end
	for _, key in ipairs(NAMEPLATE_MOB_COLOR_SOURCE_KEYS) do
		if profile[key] == nil then profile[key] = true end
	end

	local legacyThreatColors = profile.nameplateMobThreatColors
	if profile.nameplateMobColorThreatWarningEnabled == nil then profile.nameplateMobColorThreatWarningEnabled = legacyThreatColors ~= false end
	if profile.nameplateMobColorThreatLostEnabled == nil then profile.nameplateMobColorThreatLostEnabled = legacyThreatColors ~= false end
	profile.nameplateMobThreatColors = nil
end

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

local REMOVED_MYTHIC_PLUS_TIMER_KEYS = {
	"panelAutoLayout",
	"updateRate",
}

local function cleanupListedProfileKeys(profile, keys)
	if type(profile) ~= "table" then return end
	for i = 1, #keys do
		profile[keys[i]] = nil
	end
end

local function cleanupRemovedMythicPlusTimerKeys(profile)
	if type(profile) ~= "table" then return end
	cleanupListedProfileKeys(profile.mythicPlusTimer, REMOVED_MYTHIC_PLUS_TIMER_KEYS)
end

local function migrateMythicPlusTimerLayout(profile)
	if type(profile) ~= "table" or type(profile.mythicPlusTimer) ~= "table" then return end
	if profile.mythicPlusTimer.layoutMode == nil then profile.mythicPlusTimer.layoutMode = "PANEL" end
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
	if treeKey == "EBON_MIGHT" or root._rbType == "EBON_MIGHT" then root.separatedOffset = nil end
	if RESOURCE_BAR_SEGMENTED_POWER_TYPES[treeKey] or RESOURCE_BAR_SEGMENTED_POWER_TYPES[root._rbType] then cleanupResourceBarRemovedSegmentThresholdLineKeys(root) end
	for key, value in pairs(root) do
		if type(value) == "table" then cleanupResourceBarConfigTree(value, key) end
	end
end

local function migrateSharedMaelstromSegmentSettings(slotCfg)
	if type(slotCfg) ~= "table" then return end
	local legacyVisualSegments = tonumber(slotCfg.visualSegments)
	local legacyTenStacks = slotCfg.useMaelstromTenStacks
	if legacyVisualSegments ~= nil or legacyTenStacks ~= nil then
		slotCfg.powerTypeOverrides = slotCfg.powerTypeOverrides or {}
		local override = slotCfg.powerTypeOverrides.MAELSTROM_WEAPON
		if type(override) ~= "table" then
			override = {}
			slotCfg.powerTypeOverrides.MAELSTROM_WEAPON = override
		end
		if override.useMaelstromTenStacks == nil then override.useMaelstromTenStacks = legacyTenStacks == true or legacyVisualSegments == 10 end
		if override.visualSegments == nil then override.visualSegments = override.useMaelstromTenStacks and 10 or 5 end
		override.enabled = true
	end
	slotCfg.useMaelstromTenStacks = nil
	slotCfg.visualSegments = nil
end

local function cleanupResourceBarProfile(profile)
	if type(profile) ~= "table" then return end
	if addon.variables and addon.variables.isTBC then
		for key in pairs(profile) do
			if type(key) == "string" and key:match("^honorBar") then profile[key] = nil end
		end
		if type(profile.editModeData) == "table" then profile.editModeData.honorBar = nil end
	end
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
		for _, slotCfg in pairs(shared) do
			migrateSharedMaelstromSegmentSettings(slotCfg)
			local overrides = type(slotCfg) == "table" and slotCfg.powerTypeOverrides or nil
			if type(overrides) == "table" then cleanupStaggerHiddenColorOverrides(overrides.STAGGER) end
		end
		cleanupResourceBarConfigTree(shared)
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

local function cleanupForeverLootSpec(profile)
	if not (addon.variables and addon.variables.isForever) or type(profile) ~= "table" then return end
	profile.enableLootspecQuickswitch = nil
	profile.lootspec_quickswitch = nil
	if type(profile.datapanel) == "table" then profile.datapanel.lootspec = nil end
	if type(profile.dataPanels) ~= "table" then return end
	for _, panel in pairs(profile.dataPanels) do
		if type(panel) == "table" then
			if type(panel.streams) == "table" then
				for i = #panel.streams, 1, -1 do
					if panel.streams[i] == "lootspec" then table.remove(panel.streams, i) end
				end
			end
			if type(panel.streamSet) == "table" then panel.streamSet.lootspec = nil end
		end
	end
end

local function cleanupDataPanelIndividualStatLabels(profile)
	local stats = type(profile) == "table" and type(profile.datapanel) == "table" and profile.datapanel.stats
	if type(stats) ~= "table" then return end
	for _, key in ipairs({ "primary", "haste", "mastery", "crit", "lifesteal", "block", "parry", "dodge", "avoidance", "speed" }) do
		if type(stats[key]) == "table" then stats[key].labelMode = nil end
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

local function migrateGroupFrameHighlightLayer(highlight, aboveBorderLevel)
	if type(highlight) ~= "table" then return end
	local layer = rawget(highlight, "layer")
	if layer == nil then return end
	if rawget(highlight, "frameLevelOffset") == nil then
		highlight.frameLevelOffset = tostring(layer):upper() == "BEHIND_BORDER" and 2 or aboveBorderLevel
	end
	highlight.layer = nil
end

local function cleanupGroupFrameHighlightLayersInConfig(groupFrames)
	if type(groupFrames) ~= "table" then return end
	for _, config in pairs(groupFrames) do
		if type(config) == "table" then
			migrateGroupFrameHighlightLayer(config.highlightAggro, 6)
			migrateGroupFrameHighlightLayer(config.highlightTarget, 5)
		end
	end
end

local function cleanupGroupFrameHighlightLayers(profile)
	if type(profile) ~= "table" then return end
	cleanupGroupFrameHighlightLayersInConfig(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then cleanupGroupFrameHighlightLayersInConfig(ufProfile.ufGroupFrames) end
		end
	end
end

local function migrateBossRangeFadeSettingInFrames(frames)
	if type(frames) ~= "table" then return end
	for unit, config in pairs(frames) do
		if type(unit) == "string" and (unit == "boss" or unit:match("^boss%d+$")) and type(config) == "table" and type(config.rangeFade) == "table" then
			config.rangeFade.enabled = false
		end
	end
end

local function migrateBossRangeFadeSetting(profile)
	if type(profile) ~= "table" then return end
	migrateBossRangeFadeSettingInFrames(profile.ufFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then migrateBossRangeFadeSettingInFrames(ufProfile.ufFrames) end
		end
	end
end

local function migrateBossRangeFadeSettingAllProfiles()
	local db = _G.EnhanceQoLDB
	if type(db) ~= "table" or db[BOSS_RANGE_FADE_MIGRATION_FLAG] == true then return end
	migrateBossRangeFadeSetting(db)
	if type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			migrateBossRangeFadeSetting(profile)
		end
	end
	if addon.db and addon.db ~= db then migrateBossRangeFadeSetting(addon.db) end
	db[BOSS_RANGE_FADE_MIGRATION_FLAG] = true
end

local function cleanupPartyPetFramePrototypeKeysInConfig(groupFrames)
	local party = type(groupFrames) == "table" and groupFrames.party or nil
	local petFrames = type(party) == "table" and party.petFrames or nil
	if type(petFrames) == "table" then
		petFrames.size = nil
		petFrames.spacing = nil
	end
end

local function cleanupPartyPetFramePrototypeKeys(profile)
	if type(profile) ~= "table" then return end
	cleanupPartyPetFramePrototypeKeysInConfig(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then cleanupPartyPetFramePrototypeKeysInConfig(ufProfile.ufGroupFrames) end
		end
	end
end

local function cleanupGroupFramePermanentBuffOptionInConfig(groupFrames)
	if type(groupFrames) ~= "table" then return end
	for _, kind in ipairs({ "party", "raid" }) do
		local config = groupFrames[kind]
		local buff = type(config) == "table" and type(config.auras) == "table" and config.auras.buff or nil
		if type(buff) == "table" then buff.hidePermanentAuras = nil end
	end
end

local function cleanupGroupFramePermanentBuffOption(profile)
	if type(profile) ~= "table" then return end
	cleanupGroupFramePermanentBuffOptionInConfig(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then cleanupGroupFramePermanentBuffOptionInConfig(ufProfile.ufGroupFrames) end
		end
	end
end

local function cleanupHealerBuffPlacementSquareLayoutModeInConfig(groupFrames)
	if type(groupFrames) ~= "table" then return end
	for _, config in pairs(groupFrames) do
		local placement = type(config) == "table" and config.healerBuffPlacement or nil
		local groupsById = type(placement) == "table" and placement.groupsById or nil
		if type(groupsById) == "table" then
			for _, group in pairs(groupsById) do
				if type(group) == "table" then
					group.squareLayoutMode = nil
					group.squareOrderMode = nil
				end
			end
		end
	end
end

local function cleanupHealerBuffPlacementSquareLayoutMode(profile)
	if type(profile) ~= "table" then return end
	cleanupHealerBuffPlacementSquareLayoutModeInConfig(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then cleanupHealerBuffPlacementSquareLayoutModeInConfig(ufProfile.ufGroupFrames) end
		end
	end
end

local function cleanupHealerBuffPlacementGlobalScopesInConfig(groupFrames)
	if type(groupFrames) ~= "table" then return end
	for _, config in pairs(groupFrames) do
		local placement = type(config) == "table" and config.healerBuffPlacement or nil
		if type(placement) == "table" then
			placement.includeTarget = nil
			placement.includeFocus = nil
			placement.includeBoss = nil
		end
	end
end

local function cleanupHealerBuffPlacementGlobalScopes(profile)
	if type(profile) ~= "table" then return end
	cleanupHealerBuffPlacementGlobalScopesInConfig(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then cleanupHealerBuffPlacementGlobalScopesInConfig(ufProfile.ufGroupFrames) end
		end
	end
end

local function cleanupPrivateAuraFrameConfig(config)
	if type(config) ~= "table" then return end
	config.privateAuras = nil

	local function cleanupAuraConfig(auraConfig)
		if type(auraConfig) == "table" then
			auraConfig.renderer = nil
			auraConfig.blizzardTypes = nil
			auraConfig.blizzardIconSize = nil
			auraConfig.blizzardShowCooldownText = nil
			auraConfig.blizzardOrganizationType = nil
			auraConfig.blizzardDispelIndicatorMode = nil
			if type(auraConfig.debuff) == "table" then auraConfig.debuff.displayLargerRoleSpecificDebuffs = nil end
		end
	end
	cleanupAuraConfig(config.auraIcons)
	cleanupAuraConfig(config.auras)

	local dispelTint = type(config.status) == "table" and config.status.dispelTint or nil
	if type(dispelTint) == "table" then
		dispelTint.blizzardPrivateAuraDispels = nil
		dispelTint.blizzardDispelIndicatorMode = nil
	end
end

local function cleanupPrivateAuraFrameConfigs(configs)
	if type(configs) ~= "table" then return end
	for _, config in pairs(configs) do
		cleanupPrivateAuraFrameConfig(config)
	end
end

local function cleanupPrivateAuraEditModeRecord(record)
	if type(record) ~= "table" then return end
	for field in pairs(record) do
		if type(field) == "string" and field:find("^privateAuras") then record[field] = nil end
	end
	record.dispelTintBlizzardPrivateAuraDispels = nil
	record.dispelTintBlizzardDispelMode = nil
	record.auraRenderer = nil
	record.auraRendererBlizzardTypes = nil
	record.auraRendererBlizzardIconSize = nil
	record.auraRendererBlizzardCooldownText = nil
	record.auraRendererBlizzardOrganization = nil
	record.auraRendererBlizzardDispelMode = nil
	record.debuffDisplayLargerRoleSpecific = nil
end

local function cleanupPrivateAuraEditModeStore(store)
	if type(store) ~= "table" then return end
	store.standalonePrivateAuras = nil
	for id, record in pairs(store) do
		if type(record) == "table" then
			cleanupPrivateAuraEditModeRecord(record)
			if not next(record) then store[id] = nil end
		end
	end
end

local function cleanupPrivateAuraStorage(profile)
	if type(profile) ~= "table" then return end
	cleanupPrivateAuraFrameConfigs(profile.ufFrames)
	cleanupPrivateAuraFrameConfigs(profile.ufGroupFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then
				cleanupPrivateAuraFrameConfigs(ufProfile.ufFrames)
				cleanupPrivateAuraFrameConfigs(ufProfile.ufGroupFrames)
			end
		end
	end

	cleanupPrivateAuraEditModeStore(profile.editModeData)
	if type(profile.editModeLayouts) == "table" then
		for layoutName, layout in pairs(profile.editModeLayouts) do
			cleanupPrivateAuraEditModeStore(layout)
			if type(layout) == "table" and not next(layout) then profile.editModeLayouts[layoutName] = nil end
		end
	end
end

local function migrateUnitFrameTextColors(profile)
	if type(profile) ~= "table" then return end
	local function migrate(frames)
		if type(frames) ~= "table" then return end
		for _, config in pairs(frames) do
			if type(config) == "table" then
				for _, key in ipairs({ "health", "power", "secondaryPower" }) do
					local bar = config[key]
					if type(bar) == "table" and bar.textColor ~= nil then
						if type(bar.textColor) == "table" then
							for _, slot in ipairs({ "textLeftColor", "textCenterColor", "textRightColor" }) do
								if bar[slot] == nil then
									bar[slot] = { bar.textColor[1] or 1, bar.textColor[2] or 1, bar.textColor[3] or 1, bar.textColor[4] or 1 }
								end
							end
						end
						bar.textColor = nil
					end
				end
			end
		end
	end
	migrate(profile.ufFrames)
	if type(profile.ufProfiles) == "table" then
		for _, ufProfile in pairs(profile.ufProfiles) do
			if type(ufProfile) == "table" then migrate(ufProfile.ufFrames) end
		end
	end
end

local function cleanupForeverRetailOptions(profile)
	if type(profile) ~= "table" or not addon.variables then return end
	if addon.variables.isForever or addon.variables.isTBC then profile.hideGemHelperTracker = nil end
	if not addon.variables.isForever or addon.variables.isTBC then return end
	for _, key in ipairs({
		"nameplateAuraClickthrough", "experimentalNameplateAuraClickthrough",
		"hideAzeriteToast", "enableMajorFactionsRenownToastAnchor", "majorFactionsRenownToastAnchor",
		"enableLandingPageMenu", "landingPageButtonCustomPosition", "landingPageButtonAnchor",
		"landingPageButtonOffsetX", "landingPageButtonOffsetY", "landingPageButtonScale", "hiddenLandingPages",
		"TooltipHousingAutoPreview",
		"autoReleasePvPExcludeWintergrasp", "autoReleasePvPExcludeTolBarad", "autoReleasePvPExcludeAshran",
		"showInstanceDifficulty", "instanceDifficultyAnchor", "instanceDifficultyOffsetX", "instanceDifficultyOffsetY",
		"instanceDifficultyFontSize", "instanceDifficultyUseColors", "instanceDifficultyColors", "instanceDifficultyUseIcon",
	}) do
		profile[key] = nil
	end

	if type(profile.importProtection) == "table" then profile.importProtection.instanceDifficulty = nil end

	local function cleanupRemovedBlessingRules(groupFrames)
		if type(groupFrames) ~= "table" then return end
		for _, config in pairs(groupFrames) do
			local placement = type(config) == "table" and config.healerBuffPlacement
			local rules = type(placement) == "table" and placement.rulesById
			if type(rules) == "table" then
				local removed = {}
				for id, rule in pairs(rules) do
					if type(rule) == "table" and (rule.spellFamilyId == "paladin_blessing_of_light" or rule.spellFamilyId == "paladin_blessing_of_salvation") then
						rules[id] = nil
						removed[tostring(id)] = true
					end
				end
				if next(removed) then
					if type(placement.ruleOrder) == "table" then
						for index = #placement.ruleOrder, 1, -1 do
							if removed[tostring(placement.ruleOrder[index])] then table.remove(placement.ruleOrder, index) end
						end
					end
					placement._eqolDirty = true
					placement._eqolNormalized = nil
				end
			end
		end
	end
	cleanupRemovedBlessingRules(profile.ufGroupFrames)
	for _, unitProfile in pairs(type(profile.ufProfiles) == "table" and profile.ufProfiles or {}) do
		if type(unitProfile) == "table" then cleanupRemovedBlessingRules(unitProfile.ufGroupFrames) end
	end

	-- Visibility rules are also stored in feature profiles and per-layout settings.
	local seen = {}
	local function removeSkyridingRules(config, isVisibility, isViewerMap)
		if type(config) ~= "table" or seen[config] then return end
		seen[config] = true
		local removed = false
		if isVisibility then
			for _, key in ipairs({ "SKYRIDING_ACTIVE", "SKYRIDING_INACTIVE" }) do
				if type(config[key]) == "boolean" then
					config[key] = nil
					removed = true
				end
			end
		end
		for key, value in pairs(config) do
			if type(value) == "table" then
				local visibilityKey = type(key) == "string" and (key:lower():find("visibility", 1, true) or key:match("^mouseoverActionBar") or key:match("^unitframeSetting"))
				if removeSkyridingRules(value, isViewerMap or visibilityKey, key == "cooldownViewerVisibility") then config[key] = nil end
			end
		end
		return removed and next(config) == nil
	end
	removeSkyridingRules(profile)
	if profile.spellActivationOverlayVisibility == "SKYRIDING_ACTIVE" or profile.spellActivationOverlayVisibility == "SKYRIDING_INACTIVE" then
		profile.spellActivationOverlayVisibility = nil
	end
	if type(profile.cooldownViewerVisibility) == "table" then
		for key, value in pairs(profile.cooldownViewerVisibility) do
			if value == "SKYRIDING_ACTIVE" or value == "SKYRIDING_INACTIVE" then profile.cooldownViewerVisibility[key] = nil end
		end
	end
	for _, window in pairs(type(profile.damageMeterWindows) == "table" and profile.damageMeterWindows or {}) do
		if type(window) == "table" and type(window.visibility) == "table" then
			window.visibility.IN_MYTHIC_PLUS = nil
			if next(window.visibility) == nil then window.visibility = nil end
		end
	end
	local function cleanSecondaryPower(frames)
		local player = type(frames) == "table" and frames.player
		local power = type(player) == "table" and player.secondaryPower
		if type(power) ~= "table" then return end
		if type(power.allowedTypes) == "table" then
			power.allowedTypes.STAGGER = nil
			power.allowedTypes.VOID_METAMORPHOSIS = nil
		end
		for _, key in ipairs({ "staggerHighColors", "staggerHighThreshold", "staggerExtremeThreshold", "staggerHighColor", "staggerExtremeColor" }) do
			power[key] = nil
		end
	end
	cleanSecondaryPower(profile.ufFrames)
	for _, saved in pairs(type(profile.ufProfiles) == "table" and profile.ufProfiles or {}) do
		if type(saved) == "table" then cleanSecondaryPower(saved.ufFrames) end
	end
end

function addon.functions.CleanupForeverBagPresets()
	if not (addon.variables and addon.variables.isForever) or addon.variables.isTBC then return end
	local db = _G.EnhanceQoLBagsDB
	local modes = type(db) == "table" and type(db.settings) == "table" and db.settings.categoryModes
	local basic = type(modes) == "table" and modes.basic
	local categories = type(basic) == "table" and basic.customCategories
	if type(categories) ~= "table" then return end
	local housingName = C_Item and C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(20) or "Housing"
	for index = #categories, 1, -1 do
		local category = categories[index]
		local tree = type(category) == "table" and category.ruleTree
		local children = type(tree) == "table" and tree.children
		local rule = type(children) == "table" and #children == 1 and children[1]
		local color = type(category) == "table" and category.color
		-- Only remove the unmodified built-in seed; preserve custom Housing rules.
		if type(rule) == "table" and tree.nodeType == "group" and tree.operator == "AND"
			and rule.nodeType == "rule" and rule.field == "classID" and rule.operator == "EQUALS" and rule.value == 20
			and (category.name == housingName or category.name == "Housing") and not category.hidden and not category.desaturateItems
			and category.priority == 31 and category.sortMode == "quality"
			and type(color) == "table" and color[1] == 0.9 and color[2] == 0.82 and color[3] == 0.98
			and type(category.itemIDs) == "table" and next(category.itemIDs) == nil
		then
			table.remove(categories, index)
		end
	end
end

local function cleanupLegacyProfileKeys(profile)
	if type(profile) == "table" then
		profile.movementSpeedStatEnabled = nil
		if type(profile.charDisplayOptions) == "table" then profile.charDisplayOptions.movementspeed = nil end
		profile.nameplateHideFriendlyPlayerRealms = nil
		profile.nameplateFriendlyPlayerNamesOnly = nil
		profile.nameplateFriendlyPlayerClassColorNames = nil
	end
	cleanupForeverRetailOptions(profile)
	if addon.variables and addon.variables.isForever and not addon.variables.isTBC and type(profile) == "table" then
		profile.TooltipShowMythicScore = nil
		profile.TooltipMythicScoreRequireModifier = nil
		profile.TooltipMythicScoreParts = nil
		-- TooltipMythicScoreModifier is also used by inspect details.
	end
	local pulse = type(profile) == "table" and profile.cooldownPulse
	if type(pulse) == "table" and type(pulse.groups) == "table" then
		local removed = { BUTTON = true, PROC = true, AUTOCAST = true, SHINE = true }
		for _, group in pairs(pulse.groups) do
			if type(group) == "table" then
				if removed[group.glowStyle] then group.glowStyle = "NONE" end
				for _, entry in pairs(type(group.spells) == "table" and group.spells or {}) do
					if type(entry) == "table" and removed[entry.glowStyle] then entry.glowStyle = "NONE" end
				end
			end
		end
	end
	migrateUnitFrameTextColors(profile)
	cleanupListedProfileKeys(profile, LEGACY_PROFILE_KEYS)
	cleanupListedProfileKeys(profile, MULTIDROPDOWN_SCRATCH_PROFILE_KEYS)
	cleanupRemovedCVarPersistenceKeys(profile)
	cleanupDataPanelIndividualStatLabels(profile)
	cleanupMigratedDataPanelStreamOptionPositions(profile)
	cleanupForeverLootSpec(profile)
	cleanupGroupFrameHighlightLayers(profile)
	cleanupPartyPetFramePrototypeKeys(profile)
	cleanupGroupFramePermanentBuffOption(profile)
	cleanupHealerBuffPlacementSquareLayoutMode(profile)
	cleanupHealerBuffPlacementGlobalScopes(profile)
	cleanupPrivateAuraStorage(profile)
	migrateMythicPlusTimerLayout(profile)
	cleanupRemovedMythicPlusTimerKeys(profile)
end

local function cleanupCooldownPanelsStorageProfile(profile)
	if type(profile) ~= "table" then return end
	local root = profile.cooldownPanels
	if type(root) ~= "table" then return end
	local function clearPanelDurationColors(layout)
		local style = type(layout) == "table" and layout.barStyle
		if type(style) ~= "table" then return end
		for field in pairs(style) do
			if type(field) == "string" and (field == "barDurationColorEnabled" or field:match("^barDurationThreshold")) then style[field] = nil end
		end
	end
	clearPanelDurationColors(type(root.defaults) == "table" and root.defaults.layout)
	if type(root.panels) == "table" then
		for _, panel in pairs(root.panels) do
			if type(panel) == "table" then
				clearPanelDurationColors(panel.layout)
				local layout = panel.layout
				if type(layout) == "table" then
					layout.barGroupNextId = nil
					-- Older free groups retain migration input until the owning addon converts them.
					if layout.barGroupsVersion == 2 and type(layout.barGroups) == "table" then
						for _, group in pairs(layout.barGroups) do
							if type(group) == "table" then
								group.name, group.point, group.relativePoint = nil, nil, nil
								if group.barStyleVersion ~= 1 and group.usePanelStyle == false then
									group.barStyleOverrides = group.barStyleOverrides or {}
									for _, scope in ipairs({ "Icon", "Fill", "Border", "Label", "ValueText", "Cooldown", "Charges", "Stacks" }) do group.barStyleOverrides[scope] = true end
								end
								if group.barStyleVersion ~= 1 and type(group.layout) == "table" and group.layout.barPanelIconSize ~= nil then
									group.barStyleOverrides = group.barStyleOverrides or {}
									group.barStyleOverrides.Icon = true
								end
								group.usePanelStyle, group.barStyleVersion = nil, 1
							end
						end
					end
				end
				panel.cdmSyncActiveSpecBySource = nil
				if type(panel.entries) == "table" then
					for _, entry in pairs(panel.entries) do
						if type(entry) == "table" then
							if type(entry.barStyleOverrides) == "table" then
								entry.barStyleOverrides.DurationColors = nil
								if not next(entry.barStyleOverrides) then entry.barStyleOverrides = nil end
							end
							if entry.heroSpecID ~= nil then
								local id = tonumber(entry.heroSpecID)
								if entry.heroSpecFilter == nil and id and id > 0 and id == math.floor(id) then entry.heroSpecFilter = { [id] = true } end
								entry.heroSpecID = nil
							end
							local thresholdStyle = type(entry.auraDurationThresholdGlowStyle) == "string" and string.upper(entry.auraDurationThresholdGlowStyle)
							if thresholdStyle == "PROC" or thresholdStyle == "PROC_GLOW" or thresholdStyle == "ACTION_BUTTON_PROC" then
								entry.auraDurationThresholdGlowStyle = "PIXEL"
							end
							entry.cdmAuraPartyShowNames = nil
							entry.auraPresetActivationFilters = nil
							entry.auraPresetEffectFilters = nil
							if type(entry.auraPresetExcludedActivations) == "table" then
								entry.auraPresetExcludedActivations.OTHER = nil
								if not next(entry.auraPresetExcludedActivations) then entry.auraPresetExcludedActivations = nil end
							end
							if type(entry.auraPresetExcludedEffects) == "table" then
								entry.auraPresetExcludedEffects.OTHER = nil
								if not next(entry.auraPresetExcludedEffects) then entry.auraPresetExcludedEffects = nil end
							end
						end
					end
				end
				if type(panel.dynamicAnchor) == "table" and type(panel.dynamicAnchor.profileId) == "string" then
					panel.dynamicAnchor = { enabled = panel.dynamicAnchor.enabled == true, profileId = panel.dynamicAnchor.profileId }
				end
			end
		end
	end
	local helper = addon.Aura and addon.Aura.CooldownPanels and addon.Aura.CooldownPanels.helper or nil
	if type(helper) == "table" and type(helper.PruneRootForStorage) == "function" then helper.PruneRootForStorage(root) end
end

local function cleanupQuickActionsStorageProfile(profile)
	if type(profile) ~= "table" then return end
	local root = profile.quickCast
	local menus = type(root) == "table" and root.menus or nil
	if type(menus) ~= "table" then return end
	for _, menu in pairs(menus) do
		if type(menu) == "table" and type(menu.actions) == "table" then
			if addon.variables and (addon.variables.isForever or addon.variables.isTBC) then
				for index = #menu.actions, 1, -1 do
					local action = menu.actions[index]
					local unsupportedMicroMenu = type(action) == "table" and action.kind == "microMenu"
						and (action.id == "achievements" or action.id == "adventureGuide" or action.id == "housing"
							or addon.variables.isTBC and (action.id == "groupFinder" or action.id == "collections" or action.id == "professions" or action.id == "calendar" or action.id == "shop" or action.id == "gameMenu"))
					if type(action) == "table" and (action.kind == "eqol" or unsupportedMicroMenu) then
						if menu.defaultEntryID == action.entryID then menu.defaultEntryID = nil end
						table.remove(menu.actions, index)
					end
				end
			end
			for _, action in pairs(menu.actions) do
				local conditions = type(action) == "table" and action.conditions or nil
				if type(conditions) == "table" then conditions.onlyWhenKnown = nil end
			end
		end
	end
end

local function cleanupDynamicAnchorProfiles(profile)
	if type(profile) ~= "table" or type(profile.dynamicAnchorProfiles) ~= "table" then return end
	if not (addon.DynamicAnchors and addon.DynamicAnchors.NormalizeRule) then return end
	for profileId, dynamicProfile in pairs(profile.dynamicAnchorProfiles) do
		if type(profileId) ~= "string" or type(dynamicProfile) ~= "table" then
			profile.dynamicAnchorProfiles[profileId] = nil
		else
			local name = dynamicProfile.name
			local normalized = addon.DynamicAnchors:NormalizeRule(dynamicProfile)
			normalized.name = type(name) == "string" and name ~= "" and name or profileId
			profile.dynamicAnchorProfiles[profileId] = normalized
		end
	end
end

local function cleanupDynamicAnchorAssignments(profile)
	if type(profile) ~= "table" then return end
	profile._resourceBarSelfAnchorTrace = nil
	if type(profile.dynamicAnchorAssignments) ~= "table" then return end
	for consumerId, assignment in pairs(profile.dynamicAnchorAssignments) do
		if type(consumerId) ~= "string" or type(assignment) ~= "table" then
			profile.dynamicAnchorAssignments[consumerId] = nil
		else
			assignment.enabled = assignment.enabled == true
			assignment.profileId = type(assignment.profileId) == "string" and assignment.profileId or nil
			for key in pairs(assignment) do if key ~= "enabled" and key ~= "profileId" then assignment[key] = nil end end
		end
	end
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
	if addon.variables and addon.variables.isForever and not addon.variables.isTBC then
		local privateDB = _G.EnhanceQoLDBPrivate or addon.privateDB
		local selections = type(privateDB) == "table" and privateDB.classBuffReminderForeverBlessingSelection
		if type(selections) == "table" then
			for guid, key in pairs(selections) do
				if key == "LIGHT" or key == "SALVATION" then selections[guid] = nil end
			end
		end
	end
end

function addon.functions.CleanupCooldownPanelsStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function prune(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupCooldownPanelsStorageProfile(profile)
		cleanupDynamicAnchorProfiles(profile)
		cleanupDynamicAnchorAssignments(profile)
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

function addon.functions.CleanupQuickActionsStorage()
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function cleanup(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		cleanupQuickActionsStorageProfile(profile)
		addon.functions.GetSharedEditorPosition(profile)
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

function addon.functions.CleanupMoverStorage()
	local moverDB = _G.EnhanceQoLMoverDB
	if type(moverDB) ~= "table" then return end
	moverDB.macroPopupFrame = nil
	if type(moverDB.frames) == "table" then
		moverDB.frames.MacroPopupFrame = nil
		if addon.variables.isForever then
			moverDB.frames.QueueStatusButton = nil
			if not addon.variables.isTBC then
				for _, key in ipairs({ "HousingControlsFrame", "HousingDashboardFrame", "HouseFinderFrame", "HouseListFrame", "HousingHouseSettingsFrame", "AbandonHouseConfirmationDialog", "HousingCornerstoneVisitorFrame", "HousingModelPreviewFrame" }) do
					moverDB.frames[key] = nil
				end
			end
		end
		local gameMenu = moverDB.frames.GameMenuFrame
		if type(gameMenu) == "table" then
			local mode = gameMenu.positionPersistence
			if mode ~= "lockout" and mode ~= "reset" then
				if mode ~= "close" and mode ~= "off" then mode = moverDB.positionPersistence or "reset" end
				gameMenu.positionPersistence = (mode == "close" or mode == "off" or mode == "lockout") and "lockout" or "reset"
			end
		end
	end
end

function addon.functions.CleanupContainerActionStorage()
	if not (addon.ContainerActions and addon.ContainerActions.MigrateProfileData) then return end
	local db = _G.EnhanceQoLDB
	local seen = {}
	local function cleanup(profile)
		if type(profile) ~= "table" or seen[profile] then return end
		seen[profile] = true
		addon.ContainerActions:MigrateProfileData(profile)
	end
	if type(db) == "table" then
		cleanup(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do cleanup(profile) end
		end
	end
	if addon.db and addon.db ~= db then cleanup(addon.db) end
end

function addon.functions.CleanupSharedMediaFontStorage(cleanTransientCaches)
	local seen = {}
	local function migrate(settings, fontContext)
		if type(settings) ~= "table" or seen[settings] then return end
		seen[settings] = true
		for key, value in pairs(settings) do
			if cleanTransientCaches and TRANSIENT_PROFILE_KEYS[key] then
				settings[key] = nil
			elseif type(value) == "table" then
				local isFont = fontContext or (type(key) == "string" and key:lower():find("font", 1, true) ~= nil)
				migrate(value, isFont)
			elseif value == "EQOL: Expressway" or value == "Interface\\AddOns\\EnhanceQoLSharedMedia\\Fonts\\ExpresswayRegular.ttf" then
				if fontContext or (type(key) == "string" and key:lower():find("font", 1, true) ~= nil) then
					settings[key] = value == "EQOL: Expressway" and "EQOL: R41z0r" or "Interface\\AddOns\\EnhanceQoLSharedMedia\\Fonts\\R41z0r-Regular.ttf"
				end
			end
		end
	end
	migrate(_G.EnhanceQoLDB)
	migrate(addon.db)
end

function addon.functions.CleanupUnavailableSoundSettings()
	local isTBC = addon.variables and addon.variables.isTBC
	local isClassic = addon.variables and (addon.variables.isForever or isTBC)
	local removed = {
		"sounds_mounts_soundMutePterodactyl",
		"sounds_mounts_banlu",
		"sounds_mounts_grand_expedition_yak",
		"sounds_mounts_peafowl",
		"sounds_mounts_wonderwing_20",
		"sounds_mounts_mount_chopper",
		"sounds_mounts_mount_mimiron_head",
		"sounds_mounts_mount_the_dreadwake",
		"sounds_mounts_mount_storm_gryphon",
		"sounds_mounts_mount_g99_breakneck",
		"sounds_trinkets_soundMuteGazeOfTheAlnseer",
		"sounds_dungeon_xalatath",
		"sounds_dungeon_rookery_npc",
		"sounds_dungeon_priory_of_the_sacred_flame_npc",
		"sounds_dungeon_cinderbrew_meadery_npc",
		"sounds_dungeon_murder_row_belath_dawnblade",
		"sounds_dungeon_windrunner_spire_lirath_windrunner",
		"sounds_dungeon_den_of_nalorakk_zuljarra",
		"sounds_dungeon_mechagon_npc",
		"sounds_dungeon_stonevault",
		"sounds_dungeon_dundun",
		"sounds_dungeon_valeera",
		"sounds_dungeon_nekzali_voice",
	}
	local removedPings = { "sounds_interface_ping_ping_warning", "sounds_interface_ping_ping_ping", "sounds_interface_ping_ping_assist", "sounds_interface_ping_ping_omw", "sounds_interface_ping_ping_attack" }
	local function cleanup(profile)
		if type(profile) ~= "table" then return end
		profile.sounds_class_T33_Jackpot_Sound = nil
		profile.soundMuteCombatOnly = nil
		if type(profile.sharedMediaSounds) == "table" then profile.sharedMediaSounds["DeepVoice:Berserking Tazdingo"] = nil end
		if isTBC then
			for _, key in ipairs(removedPings) do profile[key] = nil end
		end
		if not isClassic then return end
		for _, key in ipairs(removed) do profile[key] = nil end
		if type(profile.soundExtraEvents) == "table" then
			profile.soundExtraEvents.CHALLENGE_MODE_LEAVER_TIMER_STARTED = nil
			profile.soundExtraEvents.CHALLENGE_MODE_DEATH_COUNT_UPDATED = nil
		end
	end
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do cleanup(profile) end
	end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

-- The classResource container remains solely for existing totem settings.
function addon.functions.CleanupUnitFrameClassResourceConfig(config)
	if not (addon.variables and (addon.variables.isForever or addon.variables.isTBC)) then return end
	if type(config) ~= "table" or type(config.classResource) ~= "table" then return end
	for key in pairs(config.classResource) do
		if key ~= "totemFrame" then config.classResource[key] = nil end
	end
	if next(config.classResource) == nil then config.classResource = nil end
end

function addon.functions.CleanupUnitFrameClassResources()
	if not (addon.variables and (addon.variables.isForever or addon.variables.isTBC)) then return end
	local function frames(configs)
		if type(configs) ~= "table" then return end
		for _, config in pairs(configs) do addon.functions.CleanupUnitFrameClassResourceConfig(config) end
	end
	local function profile(config)
		if type(config) ~= "table" then return end
		frames(config.ufFrames)
		if type(config.ufProfiles) == "table" then
			for _, ufProfile in pairs(config.ufProfiles) do
				if type(ufProfile) == "table" then frames(ufProfile.ufFrames) end
			end
		end
	end
	profile(_G.EnhanceQoLDB)
	if type(_G.EnhanceQoLDB) == "table" and type(_G.EnhanceQoLDB.profiles) == "table" then
		for _, config in pairs(_G.EnhanceQoLDB.profiles) do profile(config) end
	end
	profile(addon.db)
	profile(addon.dbDefaults)
end

function addon.functions.CleanupClassicResourceProfile(profile)
	if type(profile) ~= "table" then return end
	local resources = profile.classicResources
	if type(resources) == "table" and resources.fontSize ~= nil then
		for _, key in ipairs({ "ammoStyle", "talentsStyle" }) do
			resources[key] = type(resources[key]) == "table" and resources[key] or {}
			if resources[key].fontSize == nil then resources[key].fontSize = resources.fontSize end
			if resources[key].fontStyle == nil then resources[key].fontStyle = "__EQOL_GLOBAL_FONT_STYLE__" end
		end
		resources.fontSize = nil
	end
	local function migratePosition(data)
		if type(data) ~= "table" or type(data.classicResourceReminder) ~= "table" then return end
		local old = data.classicResourceReminder
		for _, id in ipairs({ "lowAmmoReminder", "unspentTalentReminder" }) do
			if data[id] == nil then
				data[id] = { point = old.point, relativePoint = old.relativePoint, x = old.x, y = old.y }
				if id == "unspentTalentReminder" and type(old.y) == "number" then data[id].y = old.y + 60 end
			end
		end
		data.classicResourceReminder = nil
	end
	migratePosition(profile.editModeData)
	if type(profile.editModeLayouts) == "table" then for _, data in pairs(profile.editModeLayouts) do migratePosition(data) end end
	if type(profile.editModeHiddenFrames) == "table" then
		local old = profile.editModeHiddenFrames.classicResourceReminder
		if old ~= nil then
			if profile.editModeHiddenFrames.lowAmmoReminder == nil then profile.editModeHiddenFrames.lowAmmoReminder = old end
			if profile.editModeHiddenFrames.unspentTalentReminder == nil then profile.editModeHiddenFrames.unspentTalentReminder = old end
			profile.editModeHiddenFrames.classicResourceReminder = nil
		end
	end
end

function addon.functions.CleanupClassicResourceReminders()
	local cleanup = addon.functions.CleanupClassicResourceProfile
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupGroupToolsProfile(profile)
	if type(profile) ~= "table" then return end
	if type(profile.groupTools) == "table" and profile.groupTools.design == "transparent" then profile.groupTools.design = "simple" end
	local volume = tonumber(profile.groupToolsDeathAlertTTSVolume)
	if volume then
		volume = math.max(0, math.min(100, volume))
		local roles = type(profile.groupToolsDeathAlertRoleConfig) == "table" and profile.groupToolsDeathAlertRoleConfig or {}
		profile.groupToolsDeathAlertRoleConfig = roles
		for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
			if type(roles[role]) ~= "table" then roles[role] = {} end
			if roles[role].ttsVolume == nil then roles[role].ttsVolume = volume end
		end
	end
	profile.groupToolsDeathAlertTTSVolume = nil
end

function addon.functions.CleanupGroupToolsDesigns()
	local cleanup = addon.functions.CleanupGroupToolsProfile
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupLootJunkButtonSettings()
	local function cleanup(profile)
		if type(profile) ~= "table" then return end
		if addon.variables.isForever and not addon.variables.isTBC and profile.vendorLootJunkButton == nil and profile.vendorAutoDeleteJunk ~= nil then
			profile.vendorLootJunkButton = profile.vendorAutoDeleteJunk == true
		end
		profile.vendorAutoDeleteJunk = nil
	end
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupDataPanelAnchorWidths()
	local function cleanup(profile)
		if type(profile) ~= "table" or type(profile.editModeAnchorLinks) ~= "table" then return end
		for id, record in pairs(profile.editModeAnchorLinks) do
			if type(id) == "string" and id:sub(1, 10) == "dataPanel:" and type(record) == "table" then
				if record.matchRelativeWidth == true then record.widthTarget = nil end
				record.matchRelativeWidth = nil
				record.matchRelativeWidthOffset = nil
			end
		end
	end
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupHealthMacroReset()
	local reset = addon.Health and addon.Health.Reset
	if not reset then return end
	local function cleanup(profile)
		if type(profile) == "table" and (profile.healthReset ~= nil or profile.healthResetOnCombatEnd ~= nil) then reset.Normalize(profile) end
	end
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupProfessionTextAnchors()
	local replacements = { TOPLEFT = "LEFT", BOTTOMLEFT = "LEFT", TOP = "CENTER", BOTTOM = "CENTER", TOPRIGHT = "RIGHT", BOTTOMRIGHT = "RIGHT" }
	local function cleanup(profile)
		if type(profile) ~= "table" then return end
		local anchor = profile.professionTextAnchor
		if anchor ~= nil and anchor ~= "LEFT" and anchor ~= "CENTER" and anchor ~= "RIGHT" then
			profile.professionTextAnchor = replacements[anchor] or "CENTER"
		end
	end
	local db = _G.EnhanceQoLDB
	cleanup(db)
	if type(db) == "table" and type(db.profiles) == "table" then for _, profile in pairs(db.profiles) do cleanup(profile) end end
	cleanup(addon.db)
	cleanup(addon.dbDefaults)
end

function addon.functions.CleanupItemSearchData(saved)
	if type(saved) ~= "table" then return end
	-- Retire development inventory snapshots and derived catalogs. Saved queries
	-- remain portable and are validated when opened by the new live search.
	saved.owners, saved.itemKnowledge, saved.searchKnowledge = nil, nil, nil
	saved.schemaVersion, saved.revision = nil, nil
end

-- Keep legacy history only until the owning addon can load and save it.
function addon.functions.StageLegacyChatHistory()
	if addon.variables and addon.variables.chatSocialSavedVariablesReady then return end
	for _, name in ipairs({ "EnhanceQoL_IMHistory", "EnhanceQoL_ChannelHistory" }) do
		if type(_G[name]) == "table" then
			local privateDB = addon.functions.GetPrivateDB()
			privateDB.chatSocialHistoryMigration = privateDB.chatSocialHistoryMigration or {}
			if privateDB.chatSocialHistoryMigration[name] == nil then privateDB.chatSocialHistoryMigration[name] = _G[name] end
		end
	end
end

function addon.functions.CleanupOldStuff()
	addon.functions.StageLegacyChatHistory()
	local function clearRetiredInventoryOptions(profile)
		if type(profile) == "table" then profile.TooltipInventoryShowGuild = nil end
	end
	clearRetiredInventoryOptions(addon.db)
	for _, profile in pairs(_G.EnhanceQoLDB and _G.EnhanceQoLDB.profiles or {}) do clearRetiredInventoryOptions(profile) end
	addon.functions.CleanupProfessionTextAnchors()
	addon.functions.CleanupHealthMacroReset()
	addon.functions.CleanupDataPanelAnchorWidths()
	addon.functions.CleanupLootJunkButtonSettings()
	addon.functions.CleanupGroupToolsDesigns()
	addon.functions.CleanupClassicResourceReminders()
	addon.functions.CleanupUnitFrameClassResources()
	addon.functions.CleanupUnavailableSoundSettings()
	local db = _G.EnhanceQoLDB
	migrateBossRangeFadeSettingAllProfiles()
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			migrateNameplateMobColorSources(profile)
		end
	else
		migrateNameplateMobColorSources(addon.db)
	end
	addon.functions.CleanupNameplateAuraColorRules()
	addon.functions.CleanupCombatMeterSettings()
	addon.functions.CleanupBuffTrackerSettings()
	addon.functions.CleanupContainerActionStorage()
	addon.functions.CleanupDebugArtifacts()
	addon.functions.CleanupDurationTextStorage()
	addon.functions.CleanupLegacyProfileStorage()
	addon.functions.CleanupForeverBagPresets()
	addon.functions.CleanupMoverStorage()
	addon.functions.CleanupQuickActionsStorage()
	addon.functions.CleanupResourceBarStorage()
	-- Migrate fonts and discard transient caches in one traversal of stored profiles.
	addon.functions.CleanupSharedMediaFontStorage(true)
end

local cleanupFrame = CreateFrame and CreateFrame("Frame", nil, UIParent or nil)
if cleanupFrame then
	cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
	cleanupFrame:SetScript("OnEvent", function()
		if addon.functions and addon.functions.CleanupTransientProfileCaches then addon.functions.CleanupTransientProfileCaches() end
		if addon.functions and addon.functions.CleanupCooldownPanelsStorage then addon.functions.CleanupCooldownPanelsStorage() end
	end)
end
