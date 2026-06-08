local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.ClassBuffReminder = addon.ClassBuffReminder or {}
local Reminder = addon.ClassBuffReminder

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
local EditMode = addon.EditMode
local Glow = addon.Glow
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local issecretvalue = _G.issecretvalue
local UnitInPartyIsAI = _G.UnitInPartyIsAI
local UnitGUID = _G.UnitGUID
local GetTimePreciseSec = _G.GetTimePreciseSec
local C_PetBar = _G.C_PetBar

local EDITMODE_ID = "classBuffReminder"
local ICON_MISSING = "Interface\\Icons\\INV_Misc_QuestionMark"
local DISPLAY_MODE_FULL = "FULL"
local DISPLAY_MODE_ICON_ONLY = "ICON_ONLY"
local GROWTH_RIGHT = "RIGHT"
local GROWTH_LEFT = "LEFT"
local GROWTH_UP = "UP"
local GROWTH_DOWN = "DOWN"
local TEXT_OUTLINE_NONE = "NONE"
local TEXT_OUTLINE_OUTLINE = "OUTLINE"
local TEXT_OUTLINE_THICK = "THICKOUTLINE"
local TEXT_OUTLINE_MONO = "MONOCHROME_OUTLINE"
local SAMPLE_SPELL_IDS = { 1126, 1459, 21562, 6673, 381748 }
local SAMPLE_ICON_COUNT = 5
local AURA_FILTER_HELPFUL = "HELPFUL"
local AURA_SLOT_BATCH_SIZE = 32
local AURA_SLOT_SCAN_GUARD = 16
local REMINDER_GLOW_KEY = "CLASS_BUFF_REMINDER"
local SHARED_FOOD_AURA_ICON_ID = 136000
local CURRENT_EXPANSION_INSTANCE_CACHE = {}
Reminder.UPDATE_DELAY = 0.25
Reminder.AURA_UPDATE_DELAY = 0.5
Reminder.RUNTIME_UPDATE_DELAY = 0.5
Reminder.ROSTER_UPDATE_DELAY = 0.75

local DB_ENABLED = "classBuffReminderEnabled"
local DB_SHOW_PARTY = "classBuffReminderShowParty"
local DB_SHOW_RAID = "classBuffReminderShowRaid"
local DB_SHOW_SOLO = "classBuffReminderShowSolo"
local DB_HIDE_IN_RESTED_AREA = "classBuffReminderHideInRestedArea"
local DB_ONLY_OUT_OF_COMBAT = "classBuffReminderOnlyOutOfCombat"
local DB_ROLE_FILTER_ENABLED = "classBuffReminderRoleFilterEnabled"
local DB_ROLE_FILTER_CONTEXT = "classBuffReminderRoleFilterContext"
local DB_HIDE_FOR_HEALER = "classBuffReminderHideForHealer"
local DB_HIDE_FOR_TANK = "classBuffReminderHideForTank"
local DB_HIDE_FOR_DAMAGER = "classBuffReminderHideForDamager"
local DB_HIDE_FOR_NONE = "classBuffReminderHideForNoRole"
local DB_SHOW_IF_ONLY_PROVIDER = "classBuffReminderShowIfOnlyProvider"
local DB_GLOW = "classBuffReminderGlow"
local DB_GLOW_STYLE = "classBuffReminderGlowStyle"
local DB_GLOW_INSET = "classBuffReminderGlowInset"
local DB_GLOW_COLOR = "classBuffReminderGlowColor"
local DB_SOUND_ON_MISSING = "classBuffReminderSoundOnMissing"
local DB_MISSING_SOUND = "classBuffReminderMissingSound"
local DB_DISPLAY_MODE = "classBuffReminderDisplayMode"
local DB_GROWTH_DIRECTION = "classBuffReminderGrowthDirection"
local DB_GROWTH_FROM_CENTER = "classBuffReminderGrowthFromCenter"
local DB_TRACK_FLASKS = "classBuffReminderTrackFlasks"
local DB_TRACK_FLASKS_INSTANCE_ONLY = "classBuffReminderTrackFlasksInstanceOnly"
local DB_TRACK_FOOD = "classBuffReminderTrackFood"
local DB_TRACK_FOOD_INSTANCE_ONLY = "classBuffReminderTrackFoodInstanceOnly"
local DB_TRACK_WEAPON_BUFFS = "classBuffReminderTrackWeaponBuffs"
local DB_TRACK_WEAPON_BUFFS_INSTANCE_ONLY = "classBuffReminderTrackWeaponBuffsInstanceOnly"
local DB_SCALE = "classBuffReminderScale"
local DB_ICON_SIZE = "classBuffReminderIconSize"
local DB_FONT_SIZE = "classBuffReminderFontSize"
local DB_ICON_GAP = "classBuffReminderIconGap"
local DB_BORDER_ENABLED = "classBuffReminderBorderEnabled"
local DB_BORDER_TEXTURE = "classBuffReminderBorderTexture"
local DB_BORDER_SIZE = "classBuffReminderBorderSize"
local DB_BORDER_OFFSET = "classBuffReminderBorderOffset"
local DB_BORDER_COLOR = "classBuffReminderBorderColor"
local DB_XY_TEXT_SIZE = "classBuffReminderXYTextSize"
local DB_XY_TEXT_OUTLINE = "classBuffReminderXYTextOutline"
local DB_XY_TEXT_COLOR = "classBuffReminderXYTextColor"
local DB_XY_TEXT_OFFSET_X = "classBuffReminderXYTextOffsetX"
local DB_XY_TEXT_OFFSET_Y = "classBuffReminderXYTextOffsetY"
local BORDER_SIZE_MIN = 1
local BORDER_SIZE_MAX = 24
local BORDER_OFFSET_MIN = -20
local BORDER_OFFSET_MAX = 20

Reminder.runeTracking = Reminder.runeTracking or {
	auraIds = {
		1264426, -- Void-Touched Augment Rune
		1234969, -- Ethereal Augment Rune
		1242347, -- Soulgorged Augment Rune
		453250, -- Crystallized Augment Rune
		393438, -- Draconic/Dreambound Augment Rune
		347901, -- Veiled Augment Rune
	},
	enabledDb = "classBuffReminderTrackRunes",
	legacyDb = "classBuffReminderTrackRunesInstanceOnly",
}

local TRACKING_CONTENT = {
	OPEN_WORLD = "openWorld",
	SCENARIO = "scenario",
	PARTY_FOLLOWER = "partyFollower",
	PARTY_NORMAL = "partyNormal",
	PARTY_HEROIC = "partyHeroic",
	PARTY_MYTHIC = "partyMythic",
	PARTY_MYTHIC_PLUS = "partyMythicPlus",
	RAID_LFR = "raidLfr",
	RAID_NORMAL = "raidNormal",
	RAID_HEROIC = "raidHeroic",
	RAID_MYTHIC = "raidMythic",
}

TRACKING_CONTENT.db = {
	FLASKS = "classBuffReminderTrackFlasksContent",
	FOOD = "classBuffReminderTrackFoodContent",
	RUNES = "classBuffReminderTrackRunesContent",
	WEAPON_BUFFS = "classBuffReminderTrackWeaponBuffsContent",
	PETS = "classBuffReminderTrackPetsContent",
}

TRACKING_CONTENT.order = {
	TRACKING_CONTENT.OPEN_WORLD,
	TRACKING_CONTENT.SCENARIO,
	TRACKING_CONTENT.PARTY_FOLLOWER,
	TRACKING_CONTENT.PARTY_NORMAL,
	TRACKING_CONTENT.PARTY_HEROIC,
	TRACKING_CONTENT.PARTY_MYTHIC,
	TRACKING_CONTENT.PARTY_MYTHIC_PLUS,
	TRACKING_CONTENT.RAID_LFR,
	TRACKING_CONTENT.RAID_NORMAL,
	TRACKING_CONTENT.RAID_HEROIC,
	TRACKING_CONTENT.RAID_MYTHIC,
}

TRACKING_CONTENT.keys = {
	[TRACKING_CONTENT.OPEN_WORLD] = true,
	[TRACKING_CONTENT.SCENARIO] = true,
	[TRACKING_CONTENT.PARTY_FOLLOWER] = true,
	[TRACKING_CONTENT.PARTY_NORMAL] = true,
	[TRACKING_CONTENT.PARTY_HEROIC] = true,
	[TRACKING_CONTENT.PARTY_MYTHIC] = true,
	[TRACKING_CONTENT.PARTY_MYTHIC_PLUS] = true,
	[TRACKING_CONTENT.RAID_LFR] = true,
	[TRACKING_CONTENT.RAID_NORMAL] = true,
	[TRACKING_CONTENT.RAID_HEROIC] = true,
	[TRACKING_CONTENT.RAID_MYTHIC] = true,
}

TRACKING_CONTENT.difficulties = {
	party = {
		follower = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).FollowerDungeon or 205] = true,
		},
		normal = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).DungeonNormal or 1] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).DungeonTimewalker or 24] = true,
			[150] = true,
			[216] = true,
		},
		heroic = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).DungeonHeroic or 2] = true,
		},
		mythic = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).DungeonMythic or 23] = true,
		},
		mythicPlus = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).DungeonChallenge or 8] = true,
		},
	},
	raid = {
		lfr = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).RaidLFR or 7] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).PrimaryRaidLFR or 17] = true,
			[151] = true,
		},
		normal = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).Raid10Normal or 3] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).Raid25Normal or 4] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).Raid40 or 9] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).PrimaryRaidNormal or 14] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).RaidStory or 220] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).RaidTimewalker or 33] = true,
		},
		heroic = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).Raid10Heroic or 5] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).Raid25Heroic or 6] = true,
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).PrimaryRaidHeroic or 15] = true,
		},
		mythic = {
			[((_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}).PrimaryRaidMythic or 16] = true,
		},
	},
}

function Reminder.CopyTrackingContentSelection(selection)
	local copy = {}
	if type(selection) ~= "table" then return copy end
	for _, key in ipairs(TRACKING_CONTENT.order) do
		if selection[key] == true then copy[key] = true end
	end
	return copy
end

function Reminder.CreateDefaultTrackingContentSelection()
	return {
		[TRACKING_CONTENT.PARTY_MYTHIC] = true,
		[TRACKING_CONTENT.RAID_NORMAL] = true,
		[TRACKING_CONTENT.RAID_HEROIC] = true,
		[TRACKING_CONTENT.RAID_MYTHIC] = true,
	}
end

function Reminder.CreateDefaultPetTrackingContentSelection()
	local selection = Reminder.CreateDefaultTrackingContentSelection()
	selection[TRACKING_CONTENT.PARTY_MYTHIC_PLUS] = true
	return selection
end

function Reminder.CreateLegacyInstanceTrackingContentSelection()
	return {
		[TRACKING_CONTENT.PARTY_FOLLOWER] = true,
		[TRACKING_CONTENT.PARTY_NORMAL] = true,
		[TRACKING_CONTENT.PARTY_HEROIC] = true,
		[TRACKING_CONTENT.PARTY_MYTHIC] = true,
		[TRACKING_CONTENT.RAID_LFR] = true,
		[TRACKING_CONTENT.RAID_NORMAL] = true,
		[TRACKING_CONTENT.RAID_HEROIC] = true,
		[TRACKING_CONTENT.RAID_MYTHIC] = true,
	}
end

function Reminder.CreateAllTrackingContentSelection()
	local selection = Reminder.CreateLegacyInstanceTrackingContentSelection()
	selection[TRACKING_CONTENT.OPEN_WORLD] = true
	selection[TRACKING_CONTENT.SCENARIO] = true
	return selection
end

function Reminder.NormalizeTrackingContentSelection(value, legacyInstanceOnly, fallback)
	if type(value) == "table" then
		local normalized = {}
		local changed = false
		for key, selected in pairs(value) do
			if TRACKING_CONTENT.keys[key] and selected == true then
				normalized[key] = true
			else
				changed = true
			end
		end
		return normalized, changed
	end

	if legacyInstanceOnly == true then return Reminder.CreateLegacyInstanceTrackingContentSelection(), true end
	if legacyInstanceOnly == false then return Reminder.CreateAllTrackingContentSelection(), true end
	if type(fallback) == "table" then return Reminder.CopyTrackingContentSelection(fallback), true end
	return Reminder.CreateDefaultTrackingContentSelection(), true
end

Reminder.defaults = Reminder.defaults
	or {
		enabled = false,
		showParty = true,
		showRaid = true,
		showSolo = false,
		hideInRestedArea = false,
		onlyOutOfCombat = false,
		roleFilterEnabled = false,
		roleFilterContext = "RAID_ONLY",
		hideForHealer = false,
		hideForTank = false,
		hideForDamager = false,
		hideForNoRole = false,
		showIfOnlyProvider = true,
		glow = true,
		glowStyle = "MARCHING_ANTS",
		glowInset = 0,
		glowColor = { r = 0.95, g = 0.95, b = 0.2, a = 1 },
		soundOnMissing = false,
		missingSound = "",
		displayMode = DISPLAY_MODE_ICON_ONLY,
		growthDirection = GROWTH_RIGHT,
		growthFromCenter = false,
		trackFlasks = false,
		trackFlasksContent = Reminder.CreateDefaultTrackingContentSelection(),
		trackFlasksInstanceOnly = false,
		trackFood = false,
		trackFoodContent = Reminder.CreateDefaultTrackingContentSelection(),
		trackFoodInstanceOnly = false,
		trackRunes = false,
		trackRunesContent = Reminder.CreateDefaultTrackingContentSelection(),
		trackRunesInstanceOnly = false,
		trackWeaponBuffs = false,
		trackWeaponBuffsContent = Reminder.CreateDefaultTrackingContentSelection(),
		trackWeaponBuffsInstanceOnly = false,
		expirationWarningMinutes = 0,
		trackPets = false,
		trackPetsContent = Reminder.CreateDefaultPetTrackingContentSelection(),
		trackPetsInstanceOnly = false,
		ignorePetDefensive = false,
		ignorePetPassive = false,
		hidePetReminderText = false,
		scale = 1,
		iconSize = 64,
		fontSize = 13,
		iconGap = 6,
		borderEnabled = false,
		borderTexture = "DEFAULT",
		borderSize = 1,
		borderOffset = 0,
		borderColor = { r = 1, g = 1, b = 1, a = 1 },
		xyTextSize = 13,
		xyTextOutline = TEXT_OUTLINE_OUTLINE,
		xyTextColor = { r = 1, g = 1, b = 1, a = 1 },
		xyTextOffsetX = 0,
		xyTextOffsetY = 0,
	}

local defaults = Reminder.defaults
if defaults.glowStyle == nil then defaults.glowStyle = "MARCHING_ANTS" end
if defaults.glowInset == nil then defaults.glowInset = 0 end
if type(defaults.glowColor) ~= "table" then defaults.glowColor = { r = 0.95, g = 0.95, b = 0.2, a = 1 } end
if defaults.onlyOutOfCombat == nil then defaults.onlyOutOfCombat = false end
if defaults.roleFilterEnabled == nil then defaults.roleFilterEnabled = false end
if defaults.roleFilterContext == nil then defaults.roleFilterContext = "RAID_ONLY" end
if defaults.hideForHealer == nil then defaults.hideForHealer = false end
if defaults.hideForTank == nil then defaults.hideForTank = false end
if defaults.hideForDamager == nil then defaults.hideForDamager = false end
if defaults.hideForNoRole == nil then defaults.hideForNoRole = false end
if defaults.showIfOnlyProvider == nil then defaults.showIfOnlyProvider = true end
if defaults.trackFlasks == nil then defaults.trackFlasks = false end
if defaults.trackFlasksInstanceOnly == nil then defaults.trackFlasksInstanceOnly = false end
if defaults.trackFood == nil then defaults.trackFood = false end
if type(defaults.trackFlasksContent) ~= "table" then defaults.trackFlasksContent = Reminder.CreateDefaultTrackingContentSelection() end
if defaults.trackFoodInstanceOnly == nil then defaults.trackFoodInstanceOnly = false end
if type(defaults.trackFoodContent) ~= "table" then defaults.trackFoodContent = Reminder.CreateDefaultTrackingContentSelection() end
if defaults.trackRunes == nil then defaults.trackRunes = false end
if defaults.trackRunesInstanceOnly == nil then defaults.trackRunesInstanceOnly = false end
if type(defaults.trackRunesContent) ~= "table" then defaults.trackRunesContent = Reminder.CreateDefaultTrackingContentSelection() end
if defaults.trackWeaponBuffs == nil then defaults.trackWeaponBuffs = false end
if defaults.trackWeaponBuffsInstanceOnly == nil then defaults.trackWeaponBuffsInstanceOnly = false end
if type(defaults.trackWeaponBuffsContent) ~= "table" then defaults.trackWeaponBuffsContent = Reminder.CreateDefaultTrackingContentSelection() end
if defaults.expirationWarningMinutes == nil then defaults.expirationWarningMinutes = 0 end
if defaults.trackPets == nil then defaults.trackPets = false end
if defaults.trackPetsInstanceOnly == nil then defaults.trackPetsInstanceOnly = false end
if type(defaults.trackPetsContent) ~= "table" then defaults.trackPetsContent = Reminder.CreateDefaultPetTrackingContentSelection() end
if defaults.ignorePetDefensive == nil then defaults.ignorePetDefensive = false end
if defaults.ignorePetPassive == nil then defaults.ignorePetPassive = false end
if defaults.borderEnabled == nil then defaults.borderEnabled = false end
if defaults.borderTexture == nil or defaults.borderTexture == "" then defaults.borderTexture = "DEFAULT" end
if defaults.borderSize == nil then defaults.borderSize = 1 end
if defaults.borderOffset == nil then defaults.borderOffset = 0 end
if type(defaults.borderColor) ~= "table" then defaults.borderColor = { r = 1, g = 1, b = 1, a = 1 } end

local PROVIDER_SCOPE_GROUP = "GROUP"
local PROVIDER_SCOPE_SELF = "SELF"
local GROUP_UNIT_STATUS_INELIGIBLE = -1
local GROUP_UNIT_STATUS_PRESENT = 0
local GROUP_UNIT_STATUS_MISSING = 1
local GROUP_CONTEXT_SOLO = "SOLO"
local GROUP_CONTEXT_PARTY = "PARTY"
local GROUP_CONTEXT_RAID = "RAID"
local ROLE_FILTER_CONTEXT_ANY_GROUP = "ANY_GROUP"
local ROLE_FILTER_CONTEXT_PARTY_ONLY = "PARTY_ONLY"
local ROLE_FILTER_CONTEXT_RAID_ONLY = "RAID_ONLY"

Reminder.petTracking = Reminder.petTracking or {
	petSpecs = {
		[252] = true,
		[253] = true,
		[255] = true,
		[265] = true,
		[266] = true,
		[267] = true,
	},
	specMarksman = 254,
	marksPetTalent = 1223323,
	specFrostMage = 64,
	magePetTalent = 31687,
	grimoireOfSacrifice = 108503,
	grimoireOfSacrificeBuff = 196099,
	callPet = 883,
	raiseDead = 46584,
	summonImp = 688,
	petPassive = 26179,
	petDefensive = 61679,
	petAssist = 61680,
	stanceAssist = 1,
	stanceDefensive = 2,
	stancePassive = 3,
}

local EVOKER_BLESSING_OF_BRONZE_IDS = {
	381732,
	381741,
	381746,
	381748,
	381749,
	381750,
	381751,
	381752,
	381753,
	381754,
	381756,
	381757,
	381758,
}

local EVOKER_SOURCE_OF_MAGIC_IDS = {
	369459, -- Source of Magic
}

local EVOKER_BLISTERING_SCALES_IDS = {
	360827, -- Blistering Scales
}

-- Shared flask auras (TWW + Midnight). Used for reminder presence checks.
local SHARED_FLASK_AURA_IDS = {
	432021,
	431971,
	431972,
	431973,
	431974,
	1235057,
	1235108,
	1235110,
	1235111,
}

local PROVIDER_BY_CLASS = {
	DRUID = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = { 1126 },
		fallbackName = "Mark of the Wild",
	},
	MAGE = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = { 1459 },
		fallbackName = "Arcane Intellect",
	},
	PRIEST = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = { 21562 },
		fallbackName = "Power Word: Fortitude",
	},
	WARRIOR = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = { 6673 },
		fallbackName = "Battle Shout",
	},
	EVOKER = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = EVOKER_BLESSING_OF_BRONZE_IDS,
		fallbackName = "Blessing of the Bronze",
	},
	SHAMAN = {
		scope = PROVIDER_SCOPE_GROUP,
		spellIds = { 462854 },
		fallbackName = "Skyfury",
	},
}

local PALADIN_RITES = {
	adjuration = {
		spellId = 433583,
		buffIds = { 433583 },
		fallbackName = "Rite of Adjuration",
		enchantId = 7144,
	},
	sanctification = {
		spellId = 433568,
		buffIds = { 433568 },
		fallbackName = "Rite of Sanctification",
		enchantId = 7143,
	},
}

local ROGUE_POISON_LETHAL_IDS = {
	315584, -- Instant Poison
	2823, -- Deadly Poison
	8679, -- Wound Poison
	381664, -- Amplifying Poison
}

local ROGUE_POISON_UTILITY_IDS = {
	3408, -- Crippling Poison
	5761, -- Numbing Poison
	381637, -- Atrophic Poison
}

local PALADIN_SPEC_HOLY = 65

Reminder.shamanReminder = Reminder.shamanReminder or {
	elementalOrbitIds = {
		383010, -- Elemental Orbit
	},
	shieldBasicIds = {
		974, -- Earth Shield
		192106, -- Lightning Shield
		52127, -- Water Shield
	},
	shieldEarthIds = {
		974, -- Earth Shield
	},
	shieldEarthSelfIds = {
		383648, -- Elemental Orbit passive self Earth Shield
	},
	shieldLightningIds = {
		192106, -- Lightning Shield
	},
	shieldWaterIds = {
		52127, -- Water Shield
	},
	specElemental = 262,
	specEnhancement = 263,
	specRestoration = 264,
}

local DRUID_MARK_OF_THE_WILD_IDS = {
	1126,
}

local DRUID_SYMBIOTIC_RELATIONSHIP_SELF_IDS = {
	474754,
}

local DRUID_SYMBIOTIC_RELATIONSHIP_KNOWN_IDS = {
	474750,
}

local HOLY_PALADIN_BEACON_OF_LIGHT_IDS = {
	53563, -- Beacon of Light
}

local HOLY_PALADIN_BEACON_OF_FAITH_IDS = {
	156910, -- Beacon of Faith
}

local SHAMAN_ENHANCEMENT_WINDFURY_IDS = {
	319773, -- Windfury Weapon (modern aura id)
	33757, -- Windfury Weapon (legacy aura id)
}

local SHAMAN_ENHANCEMENT_FLAMETONGUE_IDS = {
	319778, -- Flametongue Weapon (modern aura id)
	318038, -- Flametongue Weapon (legacy aura id)
}

local SHAMAN_RESTORATION_EARTHLIVING_IDS = {
	382021,
	382022,
	382024, -- Earthliving Weapon (aura variant)
}

local SHAMAN_RESTORATION_TIDECALLER_IDS = {
	457481, -- Tidecaller's Guard
	457496, -- Tidecaller's Guard
}

local SHAMAN_RESTORATION_EARTHLIVING_AURA_NAMES = {
	"Earthliving Weapon",
}

local SHAMAN_RESTORATION_TIDECALLER_AURA_NAMES = {
	"Tidecaller's Guard",
}

local spellPresentationCache = {}
local spellDataLoadRequested = {}
local auraSlotResultBuffer = {}
local auraSlotResultCount = 0

local function normalizeCachedSpellId(value)
	local spellId = tonumber(value)
	if not spellId or spellId <= 0 then return nil end
	return spellId
end

local function getCachedSpellPresentation(spellId)
	spellId = normalizeCachedSpellId(spellId)
	if not spellId then return nil, nil end

	local cached = spellPresentationCache[spellId]
	if cached and cached.name and cached.icon then return cached.name, cached.icon end

	local name
	local icon

	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellId)
		if type(info) == "table" then
			if type(info.name) == "string" and info.name ~= "" then name = info.name end
			if info.iconID and info.iconID ~= "" then icon = info.iconID end
		end
	end

	if not name and C_Spell and C_Spell.GetSpellName then
		local directName = C_Spell.GetSpellName(spellId)
		if type(directName) == "string" and directName ~= "" then name = directName end
	end

	if not icon and C_Spell.GetSpellTexture then
		local fallbackIcon = C_Spell.GetSpellTexture(spellId)
		if fallbackIcon and fallbackIcon ~= "" then icon = fallbackIcon end
	end

	if not cached then
		cached = {}
		spellPresentationCache[spellId] = cached
	end
	if name and name ~= "" then cached.name = name end
	if icon and icon ~= "" then cached.icon = icon end

	return cached.name, cached.icon
end

local function captureAuraSlotResults(...)
	local count = select("#", ...)
	for i = 1, count do
		auraSlotResultBuffer[i] = select(i, ...)
	end
	if auraSlotResultCount > count then
		for i = count + 1, auraSlotResultCount do
			auraSlotResultBuffer[i] = nil
		end
	end
	auraSlotResultCount = count

	local nextToken = auraSlotResultBuffer[1]
	if issecretvalue and issecretvalue(nextToken) then nextToken = nil end
	return auraSlotResultBuffer, count, nextToken
end

local function getHelpfulAuraSlotBuffer(unit, continuationToken)
	if continuationToken ~= nil then return captureAuraSlotResults(C_UnitAuras.GetAuraSlots(unit, AURA_FILTER_HELPFUL, AURA_SLOT_BATCH_SIZE, continuationToken)) end
	return captureAuraSlotResults(C_UnitAuras.GetAuraSlots(unit, AURA_FILTER_HELPFUL, AURA_SLOT_BATCH_SIZE))
end

local function clamp(value, minValue, maxValue, fallback)
	local n = tonumber(value)
	if n == nil then return fallback end
	if minValue ~= nil and n < minValue then n = minValue end
	if maxValue ~= nil and n > maxValue then n = maxValue end
	return n
end

local function nowSeconds()
	if GetTimePreciseSec then return tonumber(GetTimePreciseSec()) or 0 end
	if GetTime then return tonumber(GetTime()) or 0 end
	return 0
end

function Reminder.GetAuraExpirationTime(aura)
	if not aura or (issecretvalue and issecretvalue(aura)) then return nil end
	local expirationTime = aura.expirationTime
	if issecretvalue and issecretvalue(expirationTime) then expirationTime = nil end
	expirationTime = tonumber(expirationTime)
	if not expirationTime or expirationTime <= 0 then return math.huge end
	return expirationTime
end

function Reminder.StoreBestExpiration(map, key, expirationTime)
	if type(map) ~= "table" or key == nil then return end
	expirationTime = expirationTime or math.huge
	local current = map[key]
	if current == nil or expirationTime > current then map[key] = expirationTime end
end

local function clamp01(value)
	local n = tonumber(value) or 1
	if n < 0 then return 0 end
	if n > 1 then return 1 end
	return n
end

local function normalizeColor(value, fallback)
	local fb = fallback or { r = 1, g = 1, b = 1, a = 1 }
	if type(value) == "table" then
		return clamp01(value.r or value[1] or fb.r), clamp01(value.g or value[2] or fb.g), clamp01(value.b or value[3] or fb.b), clamp01(value.a or value[4] or fb.a or 1)
	end
	return clamp01(fb.r), clamp01(fb.g), clamp01(fb.b), clamp01(fb.a or 1)
end

local function getValue(key, fallback)
	if not addon.db then return fallback end
	local value = addon.db[key]
	if value == nil then return fallback end
	return value
end

function Reminder:NormalizeExpirationWarningMinutes(value)
	local minutes = clamp(value, 0, 60, defaults.expirationWarningMinutes or 0)
	minutes = math.floor((tonumber(minutes) or 0) + 0.5)
	if minutes < 0 then minutes = 0 end
	if minutes > 60 then minutes = 60 end
	return minutes
end

function Reminder:GetExpirationWarningMinutes()
	return self:NormalizeExpirationWarningMinutes(getValue("classBuffReminderExpirationWarningMinutes", defaults.expirationWarningMinutes))
end

function Reminder:GetExpirationWarningSeconds()
	return self:GetExpirationWarningMinutes() * 60
end

function Reminder:IsExpirationWarningEnabled()
	return self:GetExpirationWarningSeconds() > 0
end

function Reminder:SetExpirationWarningMinutes(value)
	if addon.db then addon.db.classBuffReminderExpirationWarningMinutes = self:NormalizeExpirationWarningMinutes(value) end
	self:CancelExpirationWarningTimer()
	self:MarkAuraStatesDirty()
	self:RequestUpdate(true)
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

function Reminder:IsExpirationTimeUsable(expirationTime, thresholdSeconds, now)
	thresholdSeconds = tonumber(thresholdSeconds) or self:GetExpirationWarningSeconds()
	if thresholdSeconds <= 0 then return true end
	if expirationTime == nil or expirationTime == math.huge then return true end
	now = tonumber(now) or nowSeconds()
	local remaining = expirationTime - now
	if remaining <= thresholdSeconds then return false end
	self:QueueExpirationWarningAt(expirationTime - thresholdSeconds)
	return true
end

function Reminder:IsAuraUsableForReminder(aura, thresholdSeconds, now)
	return self:IsExpirationTimeUsable(Reminder.GetAuraExpirationTime(aura), thresholdSeconds, now)
end

function Reminder.GetTrackingContentSelection(dbKey, legacyKey, defaultSelection)
	local stored = addon.db and addon.db[dbKey] or nil
	local legacy = addon.db and addon.db[legacyKey] or nil
	local normalized, changed = Reminder.NormalizeTrackingContentSelection(stored, legacy, defaultSelection)
	if addon.db and changed then addon.db[dbKey] = Reminder.CopyTrackingContentSelection(normalized) end
	return normalized
end

function Reminder.BuildContentDifficultyLabel(contentLabel, difficultyLabel)
	local left = type(contentLabel) == "string" and contentLabel ~= "" and contentLabel or nil
	local right = type(difficultyLabel) == "string" and difficultyLabel ~= "" and difficultyLabel or nil
	if left and right then return left .. ": " .. right end
	return left or right or ""
end

function Reminder.GetTrackingContentLabel(key)
	if key == TRACKING_CONTENT.OPEN_WORLD then return _G.WORLD or "World" end
	if key == TRACKING_CONTENT.SCENARIO then return _G.SCENARIOS or _G.TRACKER_HEADER_SCENARIO or "Scenarios" end
	if key == TRACKING_CONTENT.PARTY_FOLLOWER then return L["timeoutReleaseGroupDungeonFollower"] or Reminder.BuildContentDifficultyLabel(_G.DUNGEONS or _G.LFG_TYPE_DUNGEON or "Dungeon", _G.FOLLOWER or "Follower") end
	if key == TRACKING_CONTENT.PARTY_NORMAL then return Reminder.BuildContentDifficultyLabel(_G.PARTY or "Party", _G.PLAYER_DIFFICULTY1 or _G.NORMAL or "Normal") end
	if key == TRACKING_CONTENT.PARTY_HEROIC then return Reminder.BuildContentDifficultyLabel(_G.PARTY or "Party", _G.PLAYER_DIFFICULTY2 or _G.HEROIC or "Heroic") end
	if key == TRACKING_CONTENT.PARTY_MYTHIC then return Reminder.BuildContentDifficultyLabel(_G.PARTY or "Party", _G.PLAYER_DIFFICULTY6 or "Mythic") end
	if key == TRACKING_CONTENT.PARTY_MYTHIC_PLUS then return L["ClassBuffReminderTrackingContentMythicPlus"] or Reminder.BuildContentDifficultyLabel(_G.PARTY or "Party", _G.PLAYER_DIFFICULTY_MYTHIC_PLUS or "Mythic+") end
	if key == TRACKING_CONTENT.RAID_LFR then return Reminder.BuildContentDifficultyLabel(_G.RAID or "Raid", _G.PLAYER_DIFFICULTY3 or "LFR") end
	if key == TRACKING_CONTENT.RAID_NORMAL then return Reminder.BuildContentDifficultyLabel(_G.RAID or "Raid", _G.PLAYER_DIFFICULTY1 or _G.NORMAL or "Normal") end
	if key == TRACKING_CONTENT.RAID_HEROIC then return Reminder.BuildContentDifficultyLabel(_G.RAID or "Raid", _G.PLAYER_DIFFICULTY2 or _G.HEROIC or "Heroic") end
	if key == TRACKING_CONTENT.RAID_MYTHIC then return Reminder.BuildContentDifficultyLabel(_G.RAID or "Raid", _G.PLAYER_DIFFICULTY6 or "Mythic") end
	return tostring(key or "")
end

local function isLikelyFilePath(value)
	if type(value) ~= "string" or value == "" then return false end
	return value:find("/", 1, true) ~= nil or value:find("\\", 1, true) ~= nil
end

local function isTrackedUnit(unit)
	if type(unit) ~= "string" then return false end
	if unit == "player" then return true end
	if unit:find("^party%d+$") then return true end
	if unit:find("^raid%d+$") then return true end
	return false
end

local function isPlayerUnit(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	if unit == "player" then return true end
	if UnitIsUnit then return UnitIsUnit(unit, "player") == true end
	return false
end

local function canEvaluateUnit(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	if not (UnitExists and UnitExists(unit)) then return false end
	if not (UnitIsConnected and UnitIsConnected(unit)) then return false end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then return false end
	return true
end

function Reminder.CanActOnMissingGroupBuffUnit(unit)
	if isPlayerUnit(unit) then return true end
	if UnitIsVisible and UnitIsVisible(unit) == false then return false end
	local unitPhaseReason = _G.UnitPhaseReason
	if unitPhaseReason and unitPhaseReason(unit) ~= nil then return false end
	return true
end

local function getUnitIdentity(unit)
	if type(unit) ~= "string" or unit == "" or not UnitGUID then return nil end
	local guid = UnitGUID(unit)
	if issecretvalue and issecretvalue(guid) then return nil end
	if type(guid) ~= "string" or guid == "" then return nil end
	return guid
end

local function isAIFollowerUnit(unit)
	if type(unit) ~= "string" or unit == "player" then return false end
	if not UnitInPartyIsAI then return false end
	local isAI = UnitInPartyIsAI(unit)
	return isAI == true
end

local function isUnitHealerRole(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	if not UnitGroupRolesAssigned then return false end
	local role = UnitGroupRolesAssigned(unit)
	if issecretvalue and issecretvalue(role) then return false end
	return role == "HEALER"
end

local function getPlayerEquippedItemEquipLoc(slot)
	if not (C_Item and C_Item.GetItemInfoInstant) then return nil end
	slot = tonumber(slot)
	if not slot or slot <= 0 then return nil end

	if GetInventoryItemID then
		local itemId = GetInventoryItemID("player", slot)
		if itemId then return select(4, C_Item.GetItemInfoInstant(itemId)) end
	end

	if not GetInventoryItemLink then return nil end
	local itemLink = GetInventoryItemLink("player", slot)
	if type(itemLink) ~= "string" or itemLink == "" then return nil end
	return select(4, C_Item.GetItemInfoInstant(itemLink))
end

function Reminder.NormalizeIconTexture(value)
	if value == nil then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	if type(value) == "number" then return value > 0 and value or nil end
	if type(value) == "string" and value ~= "" then return value end
	return nil
end

function Reminder.GetItemIcon(itemId)
	itemId = tonumber(itemId)
	if not itemId or itemId <= 0 then return nil end
	if C_Item and C_Item.GetItemIconByID then
		local icon = C_Item.GetItemIconByID(itemId)
		icon = Reminder.NormalizeIconTexture(icon)
		if icon then return icon end
	end
	if C_Item and C_Item.GetItemInfoInstant then
		local icon = select(5, C_Item.GetItemInfoInstant(itemId))
		icon = Reminder.NormalizeIconTexture(icon)
		if icon then return icon end
	end
	if GetItemIcon then
		local icon = GetItemIcon(itemId)
		icon = Reminder.NormalizeIconTexture(icon)
		if icon then return icon end
	end
	return nil
end

local function isEnchantableWeaponEquipLoc(equipLoc)
	return equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND"
		or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT"
end

local function isPlayerOffhandShield()
	local offhandSlot = INVSLOT_OFFHAND or 17
	return getPlayerEquippedItemEquipLoc(offhandSlot) == "INVTYPE_SHIELD"
end

local function isPlayerOffhandEnchantableWeapon()
	local offhandSlot = INVSLOT_OFFHAND or 17
	local equipLoc = getPlayerEquippedItemEquipLoc(offhandSlot)
	if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return false end
	return isEnchantableWeaponEquipLoc(equipLoc)
end

local function isPlayerMainhandEnchantableWeapon()
	local mainhandSlot = INVSLOT_MAINHAND or 16
	return isEnchantableWeaponEquipLoc(getPlayerEquippedItemEquipLoc(mainhandSlot))
end

local function safeGetSpellName(spellId)
	local name = getCachedSpellPresentation(spellId)
	return name
end

local function requestSpellDataLoad(spellId)
	spellId = normalizeCachedSpellId(spellId)
	if not spellId then return end
	if spellDataLoadRequested[spellId] == true then return end
	spellDataLoadRequested[spellId] = true
	if C_Spell and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(spellId) end
end

local function getSpellIconRaw(spellId)
	local _, icon = getCachedSpellPresentation(spellId)
	return icon
end

local function safeGetSpellIcon(spellId) return getSpellIconRaw(spellId) or ICON_MISSING end

local function normalizeSpellId(value)
	if value == nil then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	local spellId = tonumber(value)
	if not spellId or spellId <= 0 then return nil end
	return spellId
end

local function normalizeAuraInstanceId(value)
	if value == nil then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	local auraId = tonumber(value)
	if not auraId or auraId <= 0 then return nil end
	return auraId
end

local function wipeTable(target)
	if type(target) ~= "table" then return end
	if wipe then
		wipe(target)
		return
	end
	for key in pairs(target) do
		target[key] = nil
	end
end

function Reminder.IsRelevantHelpfulPlayerAura(aura)
	return aura and aura.isHelpful == true and aura.isFromPlayerOrPlayerPet == true
end

local function normalizeDisplayMode(value)
	if value == DISPLAY_MODE_ICON_ONLY then return DISPLAY_MODE_ICON_ONLY end
	return DISPLAY_MODE_FULL
end

local function normalizeGrowthDirection(value)
	if value == GROWTH_LEFT then return GROWTH_LEFT end
	if value == GROWTH_UP then return GROWTH_UP end
	if value == GROWTH_DOWN then return GROWTH_DOWN end
	return GROWTH_RIGHT
end

local function normalizeTextOutline(value)
	if value == TEXT_OUTLINE_NONE then return TEXT_OUTLINE_NONE end
	if value == TEXT_OUTLINE_THICK then return TEXT_OUTLINE_THICK end
	if value == TEXT_OUTLINE_MONO then return TEXT_OUTLINE_MONO end
	return TEXT_OUTLINE_OUTLINE
end

local function normalizeBorderTexture(value)
	if type(value) ~= "string" or value == "" then return defaults.borderTexture or "DEFAULT" end
	if value == "DEFAULT" or value == "SOLID" then return value end
	return value
end

local function resolveBorderTexture(value)
	local key = normalizeBorderTexture(value)
	if key == "DEFAULT" or key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
	if isLikelyFilePath(key) then return key end
	if LSM and LSM.Fetch then
		local texture = LSM:Fetch("border", key, true)
		if texture then return texture end
	end
	return "Interface\\Buttons\\WHITE8x8"
end

local function normalizeBorderSize(value)
	local size = tonumber(value) or defaults.borderSize or 1
	size = math.floor(size + 0.5)
	if size < BORDER_SIZE_MIN then size = BORDER_SIZE_MIN end
	if size > BORDER_SIZE_MAX then size = BORDER_SIZE_MAX end
	return size
end

local function normalizeBorderOffset(value)
	local offset = tonumber(value) or defaults.borderOffset or 0
	offset = math.floor(offset + 0.5)
	if offset < BORDER_OFFSET_MIN then offset = BORDER_OFFSET_MIN end
	if offset > BORDER_OFFSET_MAX then offset = BORDER_OFFSET_MAX end
	return offset
end

local function normalizeRoleFilterContext(value)
	if value == ROLE_FILTER_CONTEXT_ANY_GROUP then return ROLE_FILTER_CONTEXT_ANY_GROUP end
	if value == ROLE_FILTER_CONTEXT_PARTY_ONLY then return ROLE_FILTER_CONTEXT_PARTY_ONLY end
	return ROLE_FILTER_CONTEXT_RAID_ONLY
end

local function normalizeGroupRole(value)
	if value == "HEALER" then return "HEALER" end
	if value == "TANK" then return "TANK" end
	if value == "DAMAGER" then return "DAMAGER" end
	return "NONE"
end

Reminder.GLOW_INSET_RANGE = Reminder.GLOW_INSET_RANGE or 100
Reminder.GLOW_STYLE_OPTIONS = Reminder.GLOW_STYLE_OPTIONS
	or {
		{ value = "BLIZZARD", labelKey = "Blizzard", fallback = "Blizzard" },
		{ value = "MARCHING_ANTS", labelKey = "Marching ants", fallback = "Marching ants" },
		{ value = "FLASH", labelKey = "Flash", fallback = "Flash" },
	}

local function normalizeGlowStyle(value)
	local normalized = type(value) == "string" and string.upper(value) or nil
	if normalized == "BLIZZARD" or normalized == "CLASSIC" or normalized == "BUTTON_GLOW" then return "BLIZZARD" end
	if normalized == "MARCHING_ANTS" or normalized == "MARCHINGANTS" or normalized == "ANTS" then return "MARCHING_ANTS" end
	if normalized == "FLASH" then return "FLASH" end
	return "MARCHING_ANTS"
end

local function normalizeGlowInset(value)
	local inset = clamp(value, -(Reminder.GLOW_INSET_RANGE or 100), Reminder.GLOW_INSET_RANGE or 100, defaults.glowInset or 0)
	if inset == nil then inset = defaults.glowInset or 0 end
	if inset < 0 then return math.ceil(inset - 0.5) end
	return math.floor(inset + 0.5)
end

Reminder.NormalizeGlowStyle = normalizeGlowStyle
Reminder.NormalizeGlowInset = normalizeGlowInset
Reminder.NormalizeRoleFilterContext = normalizeRoleFilterContext

local function textOutlineFlags(value)
	local outline = normalizeTextOutline(value)
	if outline == TEXT_OUTLINE_NONE then return "" end
	if outline == TEXT_OUTLINE_THICK then return "THICKOUTLINE" end
	if outline == TEXT_OUTLINE_MONO then return "OUTLINE,MONOCHROME" end
	return "OUTLINE"
end

local function centeredAxisOffset(index, count, step)
	local idx = tonumber(index)
	local total = tonumber(count)
	local spacing = tonumber(step)
	if not idx or not total or not spacing then return 0 end
	return ((idx - 1) - ((total - 1) / 2)) * spacing
end

local function getBorderOptions()
	local options = {
		{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
		{ value = "SOLID", label = "Solid" },
	}
	local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("border") or {}
	for i = 1, #mediaOptions do
		options[#options + 1] = {
			value = mediaOptions[i].value,
			label = mediaOptions[i].label,
		}
	end
	return options
end

local function safeIsPlayerSpell(spellId)
	spellId = normalizeSpellId(spellId)
	if not spellId then return false end

	if IsPlayerSpell and IsPlayerSpell(spellId) then return true end
	if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellId) then return true end
	if C_SpellBook and C_SpellBook.IsSpellInSpellBook then return C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, true) == true end

	return false
end

local function hasKnownSpellInList(spellIds)
	if type(spellIds) ~= "table" then return false end
	for i = 1, #spellIds do
		if safeIsPlayerSpell(spellIds[i]) then return true end
	end
	return false
end

local function providerHasKnownSpells(provider)
	if type(provider) ~= "table" then return false end
	if provider.requiresKnownSpells == false then return true end
	return hasKnownSpellInList(provider.knownSpellIds or provider.spellIds)
end

local function unitHasAuraBySpellId(unit, spellId)
	spellId = normalizeSpellId(spellId)
	if not spellId then return false end
	if type(unit) ~= "string" or unit == "" then return false end

	if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
		local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId)
		if aura ~= nil and not (issecretvalue and issecretvalue(aura)) then
			if type(aura) ~= "table" or Reminder:IsAuraUsableForReminder(aura) then return true end
		end
	end

	if C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
		local continuationToken
		for _ = 1, AURA_SLOT_SCAN_GUARD do
			local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer(unit, continuationToken)
			for i = 2, slotCount do
				local slot = slots[i]
				if not (issecretvalue and issecretvalue(slot)) then
					local aura = C_UnitAuras.GetAuraDataBySlot(unit, slot)
					if aura and not (issecretvalue and issecretvalue(aura)) then
						local isHelpful = aura.isHelpful
						if issecretvalue and issecretvalue(isHelpful) then isHelpful = nil end
						if isHelpful ~= false then
							local auraSpellId = normalizeSpellId(aura.spellId)
							if auraSpellId and auraSpellId == spellId and Reminder:IsAuraUsableForReminder(aura) then return true end
						end
					end
				end
			end

			if nextToken == nil then break end
			continuationToken = nextToken
		end
	end

	-- Some weapon-imbue auras can surface with an alternate spellID but keep the same aura name.
	local spellName = safeGetSpellName(spellId)
	if type(spellName) == "string" and spellName ~= "" and Reminder and Reminder.UnitHasAnyAuraName then
		if Reminder:UnitHasAnyAuraName(unit, { spellName }) then return true end
	end

	return false
end

local function playerHasEnchantId(enchantId)
	enchantId = tonumber(enchantId)
	if not enchantId or enchantId <= 0 then return false end
	if not GetWeaponEnchantInfo then return false end

	local hasMain, _, _, mainEnchantId, hasOff, _, _, offEnchantId = GetWeaponEnchantInfo()
	if hasMain and tonumber(mainEnchantId) == enchantId then return true end
	if hasOff and tonumber(offEnchantId) == enchantId then return true end
	return false
end

local function playerHasAnyEnchantId(enchantIds)
	if type(enchantIds) == "table" then
		for i = 1, #enchantIds do
			if playerHasEnchantId(enchantIds[i]) then return true end
		end
		return false
	end
	return playerHasEnchantId(enchantIds)
end

local function resetProviderRuntimeCache(provider)
	if type(provider) ~= "table" then return end
	provider.stateVersion = (tonumber(provider.stateVersion) or 0) + 1
	provider.spellSet = nil
	provider.spellNameSet = nil
	provider.spellNameSetReady = nil
	provider.spellNameRefreshAttempts = nil
	provider.displaySpellId = nil
	provider.cachedName = nil
	provider.cachedIcon = nil
	provider._presentationReady = nil
	provider._presentationAttempted = nil
	provider.presentationRetryPending = nil
	provider.presentationRetryCount = nil
end

local function getProviderStateVersion(provider)
	if type(provider) ~= "table" then return 0 end
	local version = tonumber(provider.stateVersion)
	if not version or version <= 0 then
		provider.stateVersion = 1
		return 1
	end
	return version
end

local function setProviderDisplaySpellId(provider, spellId)
	if type(provider) ~= "table" then return end
	local sid = normalizeSpellId(spellId)
	if not sid then return end
	if provider.displaySpellId == sid and provider.cachedIcon and provider.cachedIcon ~= "" then return end
	provider.displaySpellId = sid
	provider.cachedName = nil
	provider.cachedIcon = nil
	provider._presentationReady = nil
	provider._presentationAttempted = nil
end

local function makeSelfMissingEntry(spellId, label, countMissing, countTotal, sourceKind, icon, shortText)
	return {
		spellId = normalizeSpellId(spellId),
		label = label,
		countMissing = tonumber(countMissing),
		countTotal = tonumber(countTotal),
		sourceKind = sourceKind,
		icon = Reminder.NormalizeIconTexture(icon),
		shortText = shortText,
	}
end

local function appendMissingEntries(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then return end
	for i = 1, #source do
		target[#target + 1] = source[i]
	end
end

local function buildSelfStatus(total, missingEntries)
	local entries = type(missingEntries) == "table" and missingEntries or {}
	local missing = #entries
	local normalizedTotal = tonumber(total) or 1
	if normalizedTotal < missing then normalizedTotal = missing end
	if normalizedTotal < 0 then normalizedTotal = 0 end
	return {
		total = normalizedTotal,
		missing = missing,
		missingEntries = entries,
	}
end

local function resolveProviderPresentation(provider, force)
	if not provider then return end
	if force ~= true then
		if provider._presentationReady == true then return end
		if provider._presentationAttempted == true then return end
		if provider.presentationRetryPending == true then return end
	end
	provider._presentationAttempted = true

	local resolvedId
	local resolvedName
	local resolvedIcon
	local preferredId = normalizeSpellId(provider.displaySpellId)
	local preferredIcon = Reminder.NormalizeIconTexture(provider.displayIcon)
	if preferredId then resolvedId = preferredId end
	if preferredIcon then resolvedIcon = preferredIcon end

	if preferredId then
		requestSpellDataLoad(preferredId)
		local preferredName = safeGetSpellName(preferredId)
		local preferredIcon = getSpellIconRaw(preferredId)
		if preferredName and preferredName ~= "" then
			resolvedName = preferredName
			resolvedId = preferredId
		end
		if preferredIcon and preferredIcon ~= "" then
			resolvedIcon = preferredIcon
			resolvedId = preferredId
		end
		if resolvedName and resolvedIcon then
			provider.displaySpellId = preferredId
			provider.cachedName = resolvedName
			provider.cachedIcon = resolvedIcon
			provider._presentationReady = true
			return
		end
	end

	for i = 1, #provider.spellIds do
		local sid = normalizeSpellId(provider.spellIds[i])
		if sid then
			if preferredId and sid == preferredId then
				if resolvedName and resolvedIcon then break end
				-- Continue with additional IDs only to fill missing name/icon fields.
			end
			requestSpellDataLoad(sid)
			if not resolvedId then resolvedId = sid end
			local name = safeGetSpellName(sid)
			local icon = getSpellIconRaw(sid)
			if name and not resolvedName then resolvedName = name end
			if icon and not resolvedIcon then resolvedIcon = icon end
			if name and icon then
				if not preferredId then resolvedId = sid end
				resolvedName = name
				resolvedIcon = icon
				break
			end
		end
	end

	provider.displaySpellId = resolvedId or preferredId or normalizeSpellId(provider.spellIds[1]) or provider.displaySpellId or provider.spellIds[1]
	provider.cachedName = resolvedName or provider.fallbackName or "Buff"
	provider.cachedIcon = resolvedIcon or Reminder.NormalizeIconTexture(provider.displayIcon) or ICON_MISSING
	provider._presentationReady = (provider.cachedName ~= nil and provider.cachedIcon ~= ICON_MISSING)
end

local function refreshProviderSpellNameSet(provider)
	if type(provider) ~= "table" then return end
	if type(provider.spellIds) ~= "table" then return end
	provider.spellNameSet = provider.spellNameSet or {}

	local resolvedAny = false
	for i = 1, #provider.spellIds do
		local sid = normalizeSpellId(provider.spellIds[i])
		if sid then
			requestSpellDataLoad(sid)
			local name = safeGetSpellName(sid)
			if type(name) == "string" and name ~= "" then
				provider.spellNameSet[name] = true
				resolvedAny = true
			end
		end
	end

	provider.spellNameRefreshAttempts = (tonumber(provider.spellNameRefreshAttempts) or 0) + 1
	if resolvedAny then
		provider.spellNameSetReady = true
		provider.spellNameRefreshAttempts = 0
	elseif provider.spellNameRefreshAttempts >= 8 then
		provider.spellNameSetReady = true
	end
end

function Reminder:GetClassToken() return (addon.variables and addon.variables.unitClass) or select(2, UnitClass("player")) end

function Reminder:GetCurrentSpecId()
	local sid = addon.variables and addon.variables.unitSpecId
	sid = tonumber(sid)
	if sid and sid > 0 then return sid end

	local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization() or nil
	if not specIndex or not (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) then return nil end
	local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	specId = tonumber(specId)
	if not specId or specId <= 0 then return nil end
	return specId
end

function Reminder:IsEnabled() return getValue(DB_ENABLED, defaults.enabled) == true end

function Reminder:GetTrackingContentOptions()
	local options = {}
	for _, key in ipairs(TRACKING_CONTENT.order) do
		options[#options + 1] = {
			value = key,
			text = Reminder.GetTrackingContentLabel(key),
		}
	end
	return options
end

function Reminder:IsFlaskTrackingEnabled() return getValue(DB_TRACK_FLASKS, defaults.trackFlasks) == true end

function Reminder:GetFlaskTrackingContentSelection()
	return Reminder.GetTrackingContentSelection(TRACKING_CONTENT.db.FLASKS, DB_TRACK_FLASKS_INSTANCE_ONLY, defaults.trackFlasksContent)
end

function Reminder:SetFlaskTrackingContentSelection(selection)
	if addon.db then addon.db[TRACKING_CONTENT.db.FLASKS] = select(1, Reminder.NormalizeTrackingContentSelection(selection, nil, defaults.trackFlasksContent)) end
	self:InvalidateFlaskCache()
	self:RequestUpdate(true)
end

function Reminder:IsFoodTrackingEnabled() return getValue(DB_TRACK_FOOD, defaults.trackFood) == true end

function Reminder:GetFoodTrackingContentSelection()
	return Reminder.GetTrackingContentSelection(TRACKING_CONTENT.db.FOOD, DB_TRACK_FOOD_INSTANCE_ONLY, defaults.trackFoodContent)
end

function Reminder:SetFoodTrackingContentSelection(selection)
	if addon.db then addon.db[TRACKING_CONTENT.db.FOOD] = select(1, Reminder.NormalizeTrackingContentSelection(selection, nil, defaults.trackFoodContent)) end
	self:InvalidateFoodCache()
	self:RequestUpdate(true)
end

function Reminder:IsRuneTrackingEnabled() return getValue(Reminder.runeTracking.enabledDb, defaults.trackRunes) == true end

function Reminder:GetRuneTrackingContentSelection()
	return Reminder.GetTrackingContentSelection(TRACKING_CONTENT.db.RUNES, Reminder.runeTracking.legacyDb, defaults.trackRunesContent)
end

function Reminder:SetRuneTrackingContentSelection(selection)
	if addon.db then addon.db[TRACKING_CONTENT.db.RUNES] = select(1, Reminder.NormalizeTrackingContentSelection(selection, nil, defaults.trackRunesContent)) end
	self:InvalidateRuneCache()
	self:RequestUpdate(true)
end

function Reminder:IsWeaponBuffTrackingEnabled() return getValue(DB_TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs) == true end

function Reminder:GetWeaponBuffTrackingContentSelection()
	return Reminder.GetTrackingContentSelection(TRACKING_CONTENT.db.WEAPON_BUFFS, DB_TRACK_WEAPON_BUFFS_INSTANCE_ONLY, defaults.trackWeaponBuffsContent)
end

function Reminder:SetWeaponBuffTrackingContentSelection(selection)
	if addon.db then addon.db[TRACKING_CONTENT.db.WEAPON_BUFFS] = select(1, Reminder.NormalizeTrackingContentSelection(selection, nil, defaults.trackWeaponBuffsContent)) end
	self:InvalidateWeaponBuffCache()
	self:RequestUpdate(true)
end

function Reminder:IsPetTrackingEnabled() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end

function Reminder:ShouldIgnorePetDefensiveReminder()
	return getValue("classBuffReminderIgnorePetDefensive", defaults.ignorePetDefensive) == true
end

function Reminder:ShouldIgnorePetPassiveReminder()
	return getValue("classBuffReminderIgnorePetPassive", defaults.ignorePetPassive) == true
end

function Reminder:GetPetTrackingContentSelection()
	local stored = addon.db and addon.db[TRACKING_CONTENT.db.PETS] or nil
	if addon.db and addon.db["classBuffReminderPetsMythicPlusContentMigrated"] ~= true then
		if type(stored) == "table" and stored[TRACKING_CONTENT.PARTY_MYTHIC] == true and stored[TRACKING_CONTENT.PARTY_MYTHIC_PLUS] == nil then
			stored[TRACKING_CONTENT.PARTY_MYTHIC_PLUS] = true
		end
		addon.db["classBuffReminderPetsMythicPlusContentMigrated"] = true
	end
	return Reminder.GetTrackingContentSelection(TRACKING_CONTENT.db.PETS, "classBuffReminderTrackPetsInstanceOnly", defaults.trackPetsContent)
end

function Reminder:SetPetTrackingContentSelection(selection)
	if addon.db then addon.db[TRACKING_CONTENT.db.PETS] = select(1, Reminder.NormalizeTrackingContentSelection(selection, nil, defaults.trackPetsContent)) end
	self:RequestUpdate(true)
end

function Reminder:GetConsumableTrackingContentToken()
	if not IsInInstance then return TRACKING_CONTENT.OPEN_WORLD end

	local inInstance, instanceType = IsInInstance()
	if inInstance ~= true then return TRACKING_CONTENT.OPEN_WORLD end
	if instanceType == "scenario" then return TRACKING_CONTENT.SCENARIO end

	local difficultyID = GetInstanceInfo and tonumber((select(3, GetInstanceInfo()))) or nil

	if instanceType == "party" then
		if difficultyID and TRACKING_CONTENT.difficulties.party.mythicPlus[difficultyID] then return TRACKING_CONTENT.PARTY_MYTHIC_PLUS end
		if difficultyID and TRACKING_CONTENT.difficulties.party.follower[difficultyID] then return TRACKING_CONTENT.PARTY_FOLLOWER end
		if difficultyID and TRACKING_CONTENT.difficulties.party.heroic[difficultyID] then return TRACKING_CONTENT.PARTY_HEROIC end
		if difficultyID and TRACKING_CONTENT.difficulties.party.mythic[difficultyID] then return TRACKING_CONTENT.PARTY_MYTHIC end
		return TRACKING_CONTENT.PARTY_NORMAL
	end

	if instanceType == "raid" then
		if difficultyID and TRACKING_CONTENT.difficulties.raid.lfr[difficultyID] then return TRACKING_CONTENT.RAID_LFR end
		if difficultyID and TRACKING_CONTENT.difficulties.raid.heroic[difficultyID] then return TRACKING_CONTENT.RAID_HEROIC end
		if difficultyID and TRACKING_CONTENT.difficulties.raid.mythic[difficultyID] then return TRACKING_CONTENT.RAID_MYTHIC end
		return TRACKING_CONTENT.RAID_NORMAL
	end

	return nil
end

function Reminder:IsDungeonOrRaidInstance()
	if not IsInInstance then return false end
	local inInstance, instanceType = IsInInstance()
	if inInstance ~= true then return false end
	return instanceType == "party" or instanceType == "raid"
end

function Reminder:GetCurrentExpansionLevel()
	local expansionLevel
	if type(LE_EXPANSION_LEVEL_CURRENT) == "number" then expansionLevel = LE_EXPANSION_LEVEL_CURRENT end
	if type(expansionLevel) ~= "number" and _G.GetServerExpansionLevel then expansionLevel = _G.GetServerExpansionLevel() end
	if issecretvalue and issecretvalue(expansionLevel) then expansionLevel = nil end
	if type(expansionLevel) ~= "number" and _G.GetMaximumExpansionLevel then expansionLevel = _G.GetMaximumExpansionLevel() end
	if type(expansionLevel) ~= "number" and GetExpansionLevel then expansionLevel = GetExpansionLevel() end
	if issecretvalue and issecretvalue(expansionLevel) then expansionLevel = nil end
	return type(expansionLevel) == "number" and expansionLevel or nil
end

function Reminder:GetCurrentExpansionInstanceCache()
	local expansionLevel = self:GetCurrentExpansionLevel()
	if not expansionLevel then return nil end
	local cache = CURRENT_EXPANSION_INSTANCE_CACHE[expansionLevel]
	if cache then return cache end

	if not (EJ_SelectTier and EJ_GetInstanceByIndex) then return nil end

	cache = {
		instances = {},
		maps = {},
	}
	CURRENT_EXPANSION_INSTANCE_CACHE[expansionLevel] = cache

	local previousTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
	EJ_SelectTier(expansionLevel + 1)

	for _, showRaid in ipairs({ false, true }) do
		local index = 1
		while true do
			local journalInstanceID, _, _, _, _, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(index, showRaid)
			if not journalInstanceID then break end
			cache.instances[journalInstanceID] = true
			if type(mapID) == "number" and mapID > 0 then cache.maps[mapID] = true end
			index = index + 1
		end
	end

	if previousTier then EJ_SelectTier(previousTier) end
	return cache
end

function Reminder:IsCurrentExpansionDungeonOrRaidInstance()
	if self:IsDungeonOrRaidInstance() ~= true then return true end
	if not GetInstanceInfo then return true end

	local _, _, difficultyID, _, _, _, _, instanceMapID, _, lfgDungeonID = GetInstanceInfo()
	local currentExpansionLevel = self:GetCurrentExpansionLevel()

	if GetLFGDungeonInfo and lfgDungeonID then
		local _, _, _, _, _, _, _, _, expansionLevel, _, _, _, _, _, _, _, _, isTimewalker = GetLFGDungeonInfo(lfgDungeonID)
		if issecretvalue and issecretvalue(expansionLevel) then expansionLevel = nil end
		if issecretvalue and issecretvalue(isTimewalker) then isTimewalker = nil end
		if isTimewalker == true then return false end
		if type(expansionLevel) == "number" and currentExpansionLevel then return expansionLevel >= currentExpansionLevel end
	end

	local ids = (_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}
	if difficultyID == (ids.DungeonTimewalker or 24) or difficultyID == (ids.RaidTimewalker or 33) then return false end

	local cache = self:GetCurrentExpansionInstanceCache()
	if type(cache) ~= "table" then return true end

	if type(instanceMapID) == "number" and cache.maps[instanceMapID] then return true end
	local journalInstanceID = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap and type(instanceMapID) == "number"
		and C_EncounterJournal.GetInstanceForGameMap(instanceMapID)
		or nil
	return journalInstanceID ~= nil and cache.instances[journalInstanceID] == true
end

function Reminder:IsCurrentSeasonMythicPlusDungeon()
	if not GetInstanceInfo then return false end

	local _, _, difficultyID, _, _, _, _, instanceMapID = GetInstanceInfo()
	local ids = (_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}
	if difficultyID ~= (ids.DungeonMythic or 23) then return false end
	if issecretvalue and issecretvalue(instanceMapID) then return false end
	if type(instanceMapID) ~= "number" then return false end

	local mythicPlus = addon.MythicPlus
	local variables = mythicPlus and mythicPlus.variables or nil
	if type(variables) ~= "table" then return false end

	if (type(variables.seasonMapHash) ~= "table" or not next(variables.seasonMapHash)) and mythicPlus.functions and type(mythicPlus.functions.createSeasonInfo) == "function" then
		mythicPlus.functions.createSeasonInfo()
	end

	local seasonMapHash = variables.seasonMapHash
	if type(seasonMapHash) ~= "table" then return false end
	if seasonMapHash[instanceMapID] then return true end

	local zoneID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
	if issecretvalue and issecretvalue(zoneID) then zoneID = nil end
	if type(zoneID) == "number" and seasonMapHash[instanceMapID .. "_" .. zoneID] then return true end
	return false
end

function Reminder:IsTrackingContentSelected(selection, requireCurrentExpansionInstance)
	local token = self:GetConsumableTrackingContentToken()
	if not token or type(selection) ~= "table" then return false end
	if requireCurrentExpansionInstance == true and self:IsCurrentExpansionDungeonOrRaidInstance() ~= true and self:IsCurrentSeasonMythicPlusDungeon() ~= true then return false end
	return selection[token] == true
end

function Reminder:IsHideInRestedAreaEnabled() return getValue(DB_HIDE_IN_RESTED_AREA, defaults.hideInRestedArea) == true end

function Reminder:IsPlayerInRestedArea()
	if not IsResting then return false end
	return IsResting() == true
end

function Reminder:IsFlaskEnvironmentRestricted()
	if self.consumableTrackingBlockedByCombat == true then return true end
	if InCombatLockdown and InCombatLockdown() then return true end
	-- Generic addon restrictions can include transient states unrelated to local consumable checks.
	-- Basic combat restrictions also cover Mythic+, which resolves to its own tracking content token.
	return false
end

function Reminder:CanCheckFlaskReminder()
	if self:IsFlaskEnvironmentRestricted() then return false end
	if not self:IsFlaskTrackingEnabled() then return false end
	return self:IsTrackingContentSelected(self:GetFlaskTrackingContentSelection(), true)
end

function Reminder:IsEarthenPlayer()
	local race = addon.variables and addon.variables.unitRace or select(2, UnitRace("player"))
	if issecretvalue and issecretvalue(race) then return false end
	return race == "EarthenDwarf"
end

function Reminder:CanCheckFoodReminder()
	if self:IsFlaskEnvironmentRestricted() then return false end
	if self:IsEarthenPlayer() then return false end
	if not self:IsFoodTrackingEnabled() then return false end
	return self:IsTrackingContentSelected(self:GetFoodTrackingContentSelection(), true)
end

function Reminder:CanCheckRuneReminder()
	if self:IsFlaskEnvironmentRestricted() then return false end
	if not self:IsRuneTrackingEnabled() then return false end
	return self:IsTrackingContentSelected(self:GetRuneTrackingContentSelection())
end

function Reminder:ShouldSuppressGenericWeaponBuffReminder()
	local classToken = self:GetClassToken()
	if classToken == "ROGUE" then return true end
	if classToken == "SHAMAN" then
		local specId = self:GetCurrentSpecId()
		return specId == Reminder.shamanReminder.specEnhancement or specId == Reminder.shamanReminder.specRestoration
	end
	if classToken == "PALADIN" then
		local provider = self:GetPaladinRitesProvider()
		return provider and provider.trackRites == true or false
	end
	return false
end

function Reminder:CanCheckWeaponBuffReminder()
	if self:IsFlaskEnvironmentRestricted() then return false end
	if self:ShouldSuppressGenericWeaponBuffReminder() then return false end
	if not self:IsWeaponBuffTrackingEnabled() then return false end
	return self:IsTrackingContentSelected(self:GetWeaponBuffTrackingContentSelection(), true)
end

function Reminder:CanCheckPetReminder()
	if not self:IsPetTrackingEnabled() then return false end
	return self:IsTrackingContentSelected(self:GetPetTrackingContentSelection(), true)
end

function Reminder:CanEvaluateFoodReminderNow()
	if not self:CanCheckFoodReminder() then return false end
	return true
end

function Reminder:CanEvaluateRuneReminderNow()
	if not self:CanCheckRuneReminder() then return false end
	return true
end

function Reminder:CanEvaluateWeaponBuffReminderNow()
	if not self:CanCheckWeaponBuffReminder() then return false end
	return true
end

function Reminder:CanEvaluateFlaskReminderNow()
	if not self:CanCheckFlaskReminder() then return false end
	return true
end

function Reminder:CanEvaluatePetReminderNow()
	if not self:CanCheckPetReminder() then return false end
	return true
end

function Reminder:GetGroupContext()
	if IsInRaid and IsInRaid() then return GROUP_CONTEXT_RAID end
	if IsInGroup and IsInGroup() then return GROUP_CONTEXT_PARTY end
	return GROUP_CONTEXT_SOLO
end

function Reminder:IsOnlyOutOfCombatEnabled() return getValue(DB_ONLY_OUT_OF_COMBAT, defaults.onlyOutOfCombat) == true end

function Reminder:IsRuntimeEvaluationBlockedByCombat()
	if self:IsOnlyOutOfCombatEnabled() ~= true then return false end
	if not InCombatLockdown then return false end
	return InCombatLockdown() == true
end

function Reminder:IsRoleFilterEnabled() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end

function Reminder:DoesRoleFilterApplyToCurrentContext()
	if self:IsRoleFilterEnabled() ~= true then return false end

	local context = self:GetGroupContext()
	if context == GROUP_CONTEXT_SOLO then return false end

	local filterContext = normalizeRoleFilterContext(getValue(DB_ROLE_FILTER_CONTEXT, defaults.roleFilterContext))
	if filterContext == ROLE_FILTER_CONTEXT_PARTY_ONLY then return context == GROUP_CONTEXT_PARTY end
	if filterContext == ROLE_FILTER_CONTEXT_RAID_ONLY then return context == GROUP_CONTEXT_RAID end
	return context == GROUP_CONTEXT_PARTY or context == GROUP_CONTEXT_RAID
end

function Reminder:GetPlayerSpecRoleToken()
	local role = addon.variables and addon.variables.unitRole or nil
	if issecretvalue and issecretvalue(role) then role = nil end
	role = normalizeGroupRole(role)
	if role ~= "NONE" then return role end

	if GetSpecializationRole and C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
		local specIndex = C_SpecializationInfo.GetSpecialization()
		if specIndex then
			role = GetSpecializationRole(specIndex)
			if issecretvalue and issecretvalue(role) then role = nil end
			role = normalizeGroupRole(role)
			if role ~= "NONE" then return role end
		end
	end

	return "NONE"
end

function Reminder:GetPlayerRoleToken()
	local role = nil
	if UnitGroupRolesAssigned then
		role = UnitGroupRolesAssigned("player")
		if issecretvalue and issecretvalue(role) then role = nil end
		role = normalizeGroupRole(role)
	end

	if role and role ~= "NONE" then return role end
	return self:GetPlayerSpecRoleToken()
end

function Reminder:IsPlayerRoleHiddenBySettings()
	if self:DoesRoleFilterApplyToCurrentContext() ~= true then return false end

	local role = self:GetPlayerRoleToken()
	if role == "HEALER" then return getValue(DB_HIDE_FOR_HEALER, defaults.hideForHealer) == true end
	if role == "TANK" then return getValue(DB_HIDE_FOR_TANK, defaults.hideForTank) == true end
	if role == "DAMAGER" then return getValue(DB_HIDE_FOR_DAMAGER, defaults.hideForDamager) == true end
	return getValue(DB_HIDE_FOR_NONE, defaults.hideForNoRole) == true
end

function Reminder:IsOnlyClassProvider()
	local classToken = self:GetClassToken()
	if type(classToken) ~= "string" or classToken == "" then return false end
	if self:GetGroupContext() == GROUP_CONTEXT_SOLO then return true end

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		if not isPlayerUnit(unit) and not isAIFollowerUnit(unit) and UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
			local _, unitClassToken = UnitClass(unit)
			if not (issecretvalue and issecretvalue(unitClassToken)) and unitClassToken == classToken then return false end
		end
	end

	return true
end

function Reminder:ShouldEvaluateGroupResponsibilities(provider)
	if type(provider) ~= "table" then return true end
	if self:IsPlayerRoleHiddenBySettings() ~= true then return true end
	if getValue(DB_SHOW_IF_ONLY_PROVIDER, defaults.showIfOnlyProvider) == true and self:IsOnlyClassProvider() then return true end
	return false
end

function Reminder:InvalidateFlaskCache()
	self.flaskCandidateCache = nil
	self.flaskCandidateCacheSpecId = nil
	self.flaskCandidateCacheTime = 0
	self.flaskCandidateCacheReady = false
	self.flaskCacheDirty = true
	self.preparedFlaskCandidateData = nil
end

function Reminder:InvalidateFoodCache()
	self.foodCandidateCache = nil
	self.foodCandidateCacheSpecId = nil
	self.foodCandidateCacheTime = 0
	self.foodCandidateCacheReady = false
	self.foodCacheDirty = true
	self.preparedFoodCandidateData = nil
end

function Reminder:InvalidateRuneCache()
	self.runeCandidateCache = nil
	self.runeCandidateCacheTime = 0
	self.runeCandidateCacheReady = false
	self.runeCacheDirty = true
	self.preparedRuneCandidateData = nil
end

function Reminder:InvalidateWeaponBuffCache()
	self.weaponBuffCandidateCache = nil
	self.weaponBuffCandidateCacheTime = 0
	self.weaponBuffCandidateCacheReady = false
	self.weaponBuffCacheDirty = true
	self.preparedWeaponBuffCandidateData = nil
end

function Reminder:InvalidateSelfProviderStatus()
	self.selfProviderStatusProvider = nil
	self.selfProviderStatus = nil
end

function Reminder:InvalidatePlayerAuraPresenceSnapshot()
	self.playerAuraPresenceSnapshot = nil
	self:InvalidateSelfProviderStatus()
end

function Reminder:PrepareConsumableCandidateAuraData(candidates, fallbackLabel)
	local prepared = {
		source = candidates,
		spellIds = {},
		auraNames = {},
		displaySpellId = nil,
		displayLabel = nil,
		displayIcon = nil,
	}
	local seenSpellIds = {}
	local seenAuraNames = {}
	local function appendUniquePreparedValue(list, seen, value)
		if type(value) ~= "string" or value == "" or seen[value] then return end
		seen[value] = true
		list[#list + 1] = value
	end
	local function appendUniquePreparedSpellId(list, seen, spellId)
		spellId = normalizeSpellId(spellId)
		if not spellId or seen[spellId] then return end
		seen[spellId] = true
		list[#list + 1] = spellId
	end

	if type(candidates) ~= "table" then
		if type(prepared.displayLabel) ~= "string" or prepared.displayLabel == "" then prepared.displayLabel = fallbackLabel end
		return prepared
	end

	for i = 1, #candidates do
		local candidate = candidates[i]
		local candidateSpellId = normalizeSpellId(candidate and (candidate.displaySpellId or candidate.spellId))
		local candidateIcon = Reminder.NormalizeIconTexture(candidate and (candidate.displayIcon or candidate.icon or candidate.iconId or candidate.iconID))
		if not prepared.displaySpellId and candidateSpellId then prepared.displaySpellId = candidateSpellId end
		if not prepared.displayIcon and candidateIcon then prepared.displayIcon = candidateIcon end
		appendUniquePreparedSpellId(prepared.spellIds, seenSpellIds, candidateSpellId)

		local itemId = tonumber(candidate and candidate.id)
		if itemId and itemId > 0 then
			if not prepared.displayIcon then prepared.displayIcon = Reminder.GetItemIcon(itemId) end

			local spellName, spellId
			if C_Item and C_Item.GetItemSpell then spellName, spellId = C_Item.GetItemSpell(itemId) end

			spellId = normalizeSpellId(spellId)
			if not prepared.displaySpellId and spellId then prepared.displaySpellId = spellId end
			appendUniquePreparedSpellId(prepared.spellIds, seenSpellIds, spellId)

			if type(spellName) == "string" and spellName ~= "" then
				appendUniquePreparedValue(prepared.auraNames, seenAuraNames, spellName)
				if not prepared.displayLabel then prepared.displayLabel = spellName end
			end

			local itemName
			if C_Item and C_Item.GetItemNameByID then itemName = C_Item.GetItemNameByID(itemId) end
			if (not itemName or itemName == "") and C_Item and C_Item.GetItemInfo then itemName = C_Item.GetItemInfo(itemId) end
			if type(itemName) == "string" and itemName ~= "" then
				appendUniquePreparedValue(prepared.auraNames, seenAuraNames, itemName)
				if not prepared.displayLabel then prepared.displayLabel = itemName end
			end
		end
	end

	if type(prepared.displayLabel) ~= "string" or prepared.displayLabel == "" then prepared.displayLabel = fallbackLabel end
	return prepared
end

function Reminder:GetPreparedFlaskCandidateData(candidates)
	local prepared = self.preparedFlaskCandidateData
	if prepared and prepared.source == candidates then return prepared end
	prepared = self:PrepareConsumableCandidateAuraData(candidates, "Flask")
	self.preparedFlaskCandidateData = prepared
	return prepared
end

function Reminder:GetPreparedFoodCandidateData(candidates)
	local prepared = self.preparedFoodCandidateData
	if prepared and prepared.source == candidates then return prepared end
	prepared = self:PrepareConsumableCandidateAuraData(candidates, L["Buff Food Macro"] or "Buff food")
	self.preparedFoodCandidateData = prepared
	return prepared
end

function Reminder:GetPreparedRuneCandidateData(candidates)
	local prepared = self.preparedRuneCandidateData
	if prepared and prepared.source == candidates then return prepared end
	prepared = self:PrepareConsumableCandidateAuraData(candidates, L["ClassBuffReminderAugmentRune"] or "Augment Rune")
	self.preparedRuneCandidateData = prepared
	return prepared
end

function Reminder:GetPreparedWeaponBuffCandidateData(candidates)
	local prepared = self.preparedWeaponBuffCandidateData
	if prepared and prepared.source == candidates then return prepared end

	prepared = {
		source = candidates,
		displaySpellId = nil,
		displayLabel = nil,
		displayIcon = nil,
	}

	local itemId = tonumber(candidates[1] and candidates[1].id)
	if itemId and itemId > 0 then
		prepared.displayIcon = Reminder.GetItemIcon(itemId)
		local spellName, spellId
		if C_Item and C_Item.GetItemSpell then spellName, spellId = C_Item.GetItemSpell(itemId) end
		prepared.displaySpellId = normalizeSpellId(spellId)
		if type(spellName) == "string" and spellName ~= "" then prepared.displayLabel = spellName end
		if not prepared.displayLabel and C_Item and C_Item.GetItemNameByID then prepared.displayLabel = C_Item.GetItemNameByID(itemId) end
		if (not prepared.displayLabel or prepared.displayLabel == "") and C_Item and C_Item.GetItemInfo then prepared.displayLabel = C_Item.GetItemInfo(itemId) end
	end

	if type(prepared.displayLabel) ~= "string" or prepared.displayLabel == "" then prepared.displayLabel = L["ClassBuffReminderWeaponBuff"] or "Weapon buff" end
	self.preparedWeaponBuffCandidateData = prepared
	return prepared
end

function Reminder:GetPlayerAuraPresenceSnapshot()
	local snapshot = self.playerAuraPresenceSnapshot
	if type(snapshot) == "table" then return snapshot end

	snapshot = {
		supported = false,
		restricted = false,
		spellIds = {},
		names = {},
		icons = {},
		spellIdExpirations = {},
		nameExpirations = {},
		iconExpirations = {},
		instanceSpellIds = {},
		instanceNames = {},
		instanceIcons = {},
	}

	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then
		self.playerAuraPresenceSnapshot = snapshot
		return snapshot
	end
	snapshot.supported = true

	local continuationToken
	for _ = 1, AURA_SLOT_SCAN_GUARD do
		local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer("player", continuationToken)
		for i = 2, slotCount do
			local slot = slots[i]
			local aura = C_UnitAuras.GetAuraDataBySlot("player", slot)
			if aura and Reminder.IsRelevantHelpfulPlayerAura(aura) then
				local auraName = aura.name
				if issecretvalue and issecretvalue(auraName) then
					snapshot.supported = false
					snapshot.restricted = true
					self.playerAuraPresenceSnapshot = snapshot
					return snapshot
				end

				local auraId = normalizeAuraInstanceId(aura.auraInstanceID)
				local expirationTime = Reminder.GetAuraExpirationTime(aura)
				local auraSpellId = normalizeSpellId(aura.spellId)
				if auraSpellId then
					snapshot.spellIds[auraSpellId] = true
					Reminder.StoreBestExpiration(snapshot.spellIdExpirations, auraSpellId, expirationTime)
					if auraId then snapshot.instanceSpellIds[auraId] = auraSpellId end
				end

				if type(auraName) == "string" and auraName ~= "" then
					snapshot.names[auraName] = true
					Reminder.StoreBestExpiration(snapshot.nameExpirations, auraName, expirationTime)
					if auraId then snapshot.instanceNames[auraId] = auraName end
				end

				local auraIcon = aura.icon
				if issecretvalue and issecretvalue(auraIcon) then auraIcon = nil end
				auraIcon = tonumber(auraIcon)
				if auraIcon and auraIcon > 0 then
					snapshot.icons[auraIcon] = true
					Reminder.StoreBestExpiration(snapshot.iconExpirations, auraIcon, expirationTime)
					if auraId then snapshot.instanceIcons[auraId] = auraIcon end
				end
			end
		end

		if nextToken == nil then break end
		continuationToken = nextToken
	end

	self.playerAuraPresenceSnapshot = snapshot
	return snapshot
end

function Reminder:IsPlayerAuraSnapshotRestricted(snapshot)
	return type(snapshot) == "table" and snapshot.restricted == true
end

function Reminder:AuraSnapshotHasAnySpellId(snapshot, spellIds)
	if type(snapshot) ~= "table" or type(spellIds) ~= "table" then return false end
	local present = snapshot.spellIds
	if type(present) ~= "table" then return false end
	local expirations = snapshot.spellIdExpirations
	local thresholdSeconds = self:GetExpirationWarningSeconds()
	local now = nowSeconds()
	for i = 1, #spellIds do
		local spellId = normalizeSpellId(spellIds[i])
		if spellId and present[spellId] then
			local expirationTime = type(expirations) == "table" and expirations[spellId] or math.huge
			if self:IsExpirationTimeUsable(expirationTime, thresholdSeconds, now) then return true end
		end
	end
	return false
end

function Reminder:AuraSnapshotHasAnyName(snapshot, auraNames)
	if type(snapshot) ~= "table" or type(auraNames) ~= "table" then return false end
	local present = snapshot.names
	if type(present) ~= "table" then return false end
	local expirations = snapshot.nameExpirations
	local thresholdSeconds = self:GetExpirationWarningSeconds()
	local now = nowSeconds()
	for i = 1, #auraNames do
		local auraName = auraNames[i]
		if type(auraName) == "string" and auraName ~= "" and present[auraName] then
			local expirationTime = type(expirations) == "table" and expirations[auraName] or math.huge
			if self:IsExpirationTimeUsable(expirationTime, thresholdSeconds, now) then return true end
		end
	end
	return false
end

function Reminder:AuraSnapshotHasIcon(snapshot, iconId)
	iconId = tonumber(iconId)
	if not iconId or iconId <= 0 or type(snapshot) ~= "table" then return false end
	local present = snapshot.icons
	if type(present) ~= "table" or present[iconId] ~= true then return false end
	local expirations = snapshot.iconExpirations
	local expirationTime = type(expirations) == "table" and expirations[iconId] or math.huge
	return self:IsExpirationTimeUsable(expirationTime)
end

function Reminder:GetFoodBagCacheVersion()
	if addon.functions and addon.functions.getFoodBagItemCountCacheVersion then return tonumber(addon.functions.getFoodBagItemCountCacheVersion()) or 0 end
	return 0
end

function Reminder:GetExpectedFlaskSharedSelection(specId)
	local db = addon.db or {}
	local funcs = addon.Flasks and addon.Flasks.functions or nil
	local normalizeType = funcs and funcs.normalizeTypeKey or nil
	local selectedPreference = "useRole"
	local selectedRoleKey = nil
	local selectedType = "none"

	if db.flaskPreferredBySpec and specId and db.flaskPreferredBySpec[specId] ~= nil then selectedPreference = db.flaskPreferredBySpec[specId] end
	if selectedPreference == "useRole" then
		local roleFunc = funcs and (funcs.getEffectiveRoleBucketForSpec or funcs.getRoleBucketForSpec) or nil
		if type(roleFunc) == "function" then selectedRoleKey = roleFunc(specId) end
		local roleSelection = db.flaskPreferredByRole and selectedRoleKey and db.flaskPreferredByRole[selectedRoleKey] or nil
		if type(normalizeType) == "function" then selectedType = normalizeType(roleSelection) else selectedType = roleSelection or "none" end
	else
		if type(normalizeType) == "function" then selectedType = normalizeType(selectedPreference) else selectedType = selectedPreference or "none" end
	end

	if type(selectedType) ~= "string" or selectedType == "" then selectedType = "none" end
	return selectedType, selectedRoleKey, selectedPreference
end

function Reminder:GetExpectedFoodSharedSelection(specId)
	local db = addon.db or {}
	local funcs = addon.BuffFoods and addon.BuffFoods.functions or nil
	local normalizeType = funcs and funcs.normalizeTypeKey or nil
	local selectedPreference = "useRole"
	local selectedRoleKey = nil
	local selectedType = "none"

	if db.buffFoodPreferredBySpec and specId and db.buffFoodPreferredBySpec[specId] ~= nil then selectedPreference = db.buffFoodPreferredBySpec[specId] end
	if selectedPreference == "useRole" then
		local roleFunc = funcs and funcs.getRoleBucketForSpec or nil
		if type(roleFunc) == "function" then selectedRoleKey = roleFunc(specId) end
		local roleSelection = db.buffFoodPreferredByRole and selectedRoleKey and db.buffFoodPreferredByRole[selectedRoleKey] or nil
		if type(normalizeType) == "function" then selectedType = normalizeType(roleSelection) else selectedType = roleSelection or "none" end
	else
		if type(normalizeType) == "function" then selectedType = normalizeType(selectedPreference) else selectedType = selectedPreference or "none" end
	end

	if type(selectedType) ~= "string" or selectedType == "" then selectedType = "none" end
	return selectedType, selectedRoleKey, selectedPreference
end

function Reminder:GetSharedFlaskCandidates(specId)
	if type(specId) ~= "number" then return nil, nil, false end
	if not addon.Flasks then return nil, nil, false end
	if addon.Flasks.lastSpecID ~= specId then return nil, nil, false end
	if tonumber(addon.Flasks.lastBagVersion) ~= self:GetFoodBagCacheVersion() then return nil, nil, false end

	local expectedType, expectedRoleKey, expectedPreference = self:GetExpectedFlaskSharedSelection(specId)
	if addon.Flasks.lastSelectedType ~= expectedType then return nil, nil, false end
	if addon.Flasks.lastSelectedRole ~= expectedRoleKey then return nil, nil, false end
	if addon.Flasks.lastSelectedPreference ~= expectedPreference then return nil, nil, false end

	local selectedType = addon.Flasks.lastSelectedType
	if type(selectedType) ~= "string" then selectedType = nil end
	if selectedType == "none" then return nil, selectedType, true end

	local shared = addon.Flasks.filteredFlasks
	if type(shared) ~= "table" then return nil, selectedType, false end
	if #shared <= 0 then return nil, selectedType, true end
	return shared, selectedType, true
end

function Reminder:GetSharedFoodCandidates(specId)
	if type(specId) ~= "number" then return nil, nil, false end
	if not addon.BuffFoods then return nil, nil, false end
	if addon.BuffFoods.lastSpecID ~= specId then return nil, nil, false end
	if tonumber(addon.BuffFoods.lastBagVersion) ~= self:GetFoodBagCacheVersion() then return nil, nil, false end

	local expectedType, expectedRoleKey, expectedPreference = self:GetExpectedFoodSharedSelection(specId)
	if addon.BuffFoods.lastSelectedType ~= expectedType then return nil, nil, false end
	if addon.BuffFoods.lastSelectedRole ~= expectedRoleKey then return nil, nil, false end
	if addon.BuffFoods.lastSelectedPreference ~= expectedPreference then return nil, nil, false end

	local selectedType = addon.BuffFoods.lastSelectedType
	if type(selectedType) ~= "string" then selectedType = nil end
	if selectedType == "none" then return nil, selectedType, true end

	local shared = addon.BuffFoods.filteredBuffFoods
	if type(shared) ~= "table" then return nil, selectedType, false end
	if #shared <= 0 then return nil, selectedType, true end
	return shared, selectedType, true
end

function Reminder:GetFlaskCandidatesForCurrentSpec()
	if not self:CanCheckFlaskReminder() then return nil, nil end
	if not (addon.Flasks and addon.Flasks.functions and addon.Flasks.functions.getAvailableCandidatesForSpec) then return nil, nil end

	local specId = self:GetCurrentSpecId()
	if self.flaskCacheDirty ~= true and self.flaskCandidateCacheReady == true and self.flaskCandidateCacheSpecId == specId then return self.flaskCandidateCache, self.flaskSelectedType end

	local now = nowSeconds()
	local canUseShared = addon.db and addon.db.flaskMacroEnabled == true
	local sharedCandidates, sharedType, sharedReady = self:GetSharedFlaskCandidates(specId)
	if canUseShared and sharedReady then
		self.flaskCandidateCache = sharedCandidates
		self.flaskCandidateCacheSpecId = specId
		self.flaskSelectedType = sharedType
		self.flaskCandidateCacheTime = now
		self.flaskCandidateCacheReady = true
		self.flaskCacheDirty = false
		return sharedCandidates, sharedType
	end

	local candidates, selectedType = addon.Flasks.functions.getAvailableCandidatesForSpec(specId)
	if type(selectedType) ~= "string" then selectedType = nil end
	if selectedType == "none" then
		candidates = nil
	elseif type(candidates) ~= "table" or #candidates <= 0 then
		candidates = nil
	end

	self.flaskCandidateCache = candidates
	self.flaskCandidateCacheSpecId = specId
	self.flaskSelectedType = selectedType
	self.flaskCandidateCacheTime = now
	self.flaskCandidateCacheReady = true
	self.flaskCacheDirty = false

	return candidates, selectedType
end

function Reminder:GetFoodCandidatesForCurrentSpec()
	if not self:CanCheckFoodReminder() then return nil, nil end
	if not (addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.getAvailableCandidatesForSpec) then return nil, nil end

	local specId = self:GetCurrentSpecId()
	if self.foodCacheDirty ~= true and self.foodCandidateCacheReady == true and self.foodCandidateCacheSpecId == specId then return self.foodCandidateCache, self.foodSelectedType end

	local now = nowSeconds()
	local canUseShared = addon.db and addon.db.buffFoodMacroEnabled == true
	local sharedCandidates, sharedType, sharedReady = self:GetSharedFoodCandidates(specId)
	if canUseShared and sharedReady then
		self.foodCandidateCache = sharedCandidates
		self.foodCandidateCacheSpecId = specId
		self.foodSelectedType = sharedType
		self.foodCandidateCacheTime = now
		self.foodCandidateCacheReady = true
		self.foodCacheDirty = false
		return sharedCandidates, sharedType
	end

	local candidates, selectedType = addon.BuffFoods.functions.getAvailableCandidatesForSpec(specId)
	if type(selectedType) ~= "string" then selectedType = nil end
	if selectedType == "none" then
		candidates = nil
	elseif type(candidates) ~= "table" or #candidates <= 0 then
		candidates = nil
	end

	self.foodCandidateCache = candidates
	self.foodCandidateCacheSpecId = specId
	self.foodSelectedType = selectedType
	self.foodCandidateCacheTime = now
	self.foodCandidateCacheReady = true
	self.foodCacheDirty = false

	return candidates, selectedType
end

function Reminder:GetRuneCandidates()
	if not self:CanCheckRuneReminder() then return nil end
	if not (addon.Runes and addon.Runes.functions and addon.Runes.functions.getAvailableCandidates) then return nil end

	if self.runeCacheDirty ~= true and self.runeCandidateCacheReady == true then return self.runeCandidateCache end

	local candidates = addon.Runes.functions.getAvailableCandidates()
	if type(candidates) ~= "table" or #candidates <= 0 then candidates = nil end

	self.runeCandidateCache = candidates
	self.runeCandidateCacheTime = nowSeconds()
	self.runeCandidateCacheReady = true
	self.runeCacheDirty = false

	return candidates
end

function Reminder:GetWeaponBuffCandidates()
	if not self:CanCheckWeaponBuffReminder() then return nil end
	if not (addon.WeaponBuffs and addon.WeaponBuffs.functions and addon.WeaponBuffs.functions.getAvailableCandidates) then return nil end

	if self.weaponBuffCacheDirty ~= true and self.weaponBuffCandidateCacheReady == true then return self.weaponBuffCandidateCache end

	local candidates = addon.WeaponBuffs.functions.getAvailableCandidates()
	if type(candidates) ~= "table" or #candidates <= 0 then candidates = nil end

	self.weaponBuffCandidateCache = candidates
	self.weaponBuffCandidateCacheTime = nowSeconds()
	self.weaponBuffCandidateCacheReady = true
	self.weaponBuffCacheDirty = false

	return candidates
end

function Reminder:GetFlaskMissingEntry(evalContext)
	local candidates = self:GetFlaskCandidatesForCurrentSpec()
	if type(candidates) ~= "table" or #candidates <= 0 then return nil end

	local context = type(evalContext) == "table" and evalContext or nil
	local prepared = context and context.flaskPreparedData or self:GetPreparedFlaskCandidateData(candidates)
	if context and not context.flaskPreparedData then context.flaskPreparedData = prepared end
	local snapshot = context and context.playerAuraSnapshot or self:GetPlayerAuraPresenceSnapshot()
	if context and not context.playerAuraSnapshot then context.playerAuraSnapshot = snapshot end
	if self:IsPlayerAuraSnapshotRestricted(snapshot) then return nil end

	local hasFlaskAura
	if snapshot and snapshot.supported == true then
		hasFlaskAura = self:AuraSnapshotHasAnySpellId(snapshot, SHARED_FLASK_AURA_IDS)
		if not hasFlaskAura and #prepared.spellIds > 0 and self:AuraSnapshotHasAnySpellId(snapshot, prepared.spellIds) then hasFlaskAura = true end
		if not hasFlaskAura and #prepared.auraNames > 0 and self:AuraSnapshotHasAnyName(snapshot, prepared.auraNames) then hasFlaskAura = true end
	else
		hasFlaskAura = self:UnitHasAnyAuraSpellId("player", SHARED_FLASK_AURA_IDS)
		if not hasFlaskAura and #prepared.spellIds > 0 and self:UnitHasAnyAuraSpellId("player", prepared.spellIds) then hasFlaskAura = true end
		if not hasFlaskAura and #prepared.auraNames > 0 and self:UnitHasAnyAuraName("player", prepared.auraNames) then hasFlaskAura = true end
	end
	if hasFlaskAura then return nil end

	local displaySpellId = prepared.displaySpellId or normalizeSpellId(SHARED_FLASK_AURA_IDS[1])
	local displayLabel = prepared.displayLabel
	if type(displayLabel) ~= "string" or displayLabel == "" then displayLabel = "Flask" end
	return makeSelfMissingEntry(displaySpellId, displayLabel, nil, nil, "FLASK", prepared.displayIcon)
end

function Reminder:GetFoodMissingEntry(evalContext)
	if self:IsEarthenPlayer() then return nil end

	local candidates = self:GetFoodCandidatesForCurrentSpec()
	if type(candidates) ~= "table" or #candidates <= 0 then return nil end

	local context = type(evalContext) == "table" and evalContext or nil
	local prepared = context and context.foodPreparedData or self:GetPreparedFoodCandidateData(candidates)
	if context and not context.foodPreparedData then context.foodPreparedData = prepared end
	local snapshot = context and context.playerAuraSnapshot or self:GetPlayerAuraPresenceSnapshot()
	if context and not context.playerAuraSnapshot then context.playerAuraSnapshot = snapshot end
	if self:IsPlayerAuraSnapshotRestricted(snapshot) then return nil end

	local hasFoodAura
	if snapshot and snapshot.supported == true then
		hasFoodAura = self:AuraSnapshotHasIcon(snapshot, SHARED_FOOD_AURA_ICON_ID)
		if not hasFoodAura and #prepared.spellIds > 0 and self:AuraSnapshotHasAnySpellId(snapshot, prepared.spellIds) then hasFoodAura = true end
		if not hasFoodAura and #prepared.auraNames > 0 and self:AuraSnapshotHasAnyName(snapshot, prepared.auraNames) then hasFoodAura = true end
	else
		hasFoodAura = self:UnitHasAuraIcon("player", SHARED_FOOD_AURA_ICON_ID)
		if not hasFoodAura and #prepared.spellIds > 0 and self:UnitHasAnyAuraSpellId("player", prepared.spellIds) then hasFoodAura = true end
		if not hasFoodAura and #prepared.auraNames > 0 and self:UnitHasAnyAuraName("player", prepared.auraNames) then hasFoodAura = true end
	end
	if hasFoodAura then return nil end

	local displaySpellId = prepared.displaySpellId
	local displayLabel = prepared.displayLabel
	if not displaySpellId and #prepared.spellIds > 0 then displaySpellId = normalizeSpellId(prepared.spellIds[1]) end
	if type(displayLabel) ~= "string" or displayLabel == "" then displayLabel = L["Buff Food Macro"] or "Buff food" end
	return makeSelfMissingEntry(displaySpellId, displayLabel, nil, nil, "FOOD", prepared.displayIcon or SHARED_FOOD_AURA_ICON_ID)
end

function Reminder:GetRuneMissingEntry(evalContext)
	local candidates = self:GetRuneCandidates()
	if type(candidates) ~= "table" or #candidates <= 0 then return nil end

	local context = type(evalContext) == "table" and evalContext or nil
	local prepared = context and context.runePreparedData or self:GetPreparedRuneCandidateData(candidates)
	if context and not context.runePreparedData then context.runePreparedData = prepared end
	local snapshot = context and context.playerAuraSnapshot or self:GetPlayerAuraPresenceSnapshot()
	if context and not context.playerAuraSnapshot then context.playerAuraSnapshot = snapshot end
	if self:IsPlayerAuraSnapshotRestricted(snapshot) then return nil end

	local hasRuneAura
	if snapshot and snapshot.supported == true then
		hasRuneAura = self:AuraSnapshotHasAnySpellId(snapshot, Reminder.runeTracking.auraIds)
		if not hasRuneAura and #prepared.spellIds > 0 and self:AuraSnapshotHasAnySpellId(snapshot, prepared.spellIds) then hasRuneAura = true end
		if not hasRuneAura and #prepared.auraNames > 0 and self:AuraSnapshotHasAnyName(snapshot, prepared.auraNames) then hasRuneAura = true end
	else
		hasRuneAura = self:UnitHasAnyAuraSpellId("player", Reminder.runeTracking.auraIds)
		if not hasRuneAura and #prepared.spellIds > 0 and self:UnitHasAnyAuraSpellId("player", prepared.spellIds) then hasRuneAura = true end
		if not hasRuneAura and #prepared.auraNames > 0 and self:UnitHasAnyAuraName("player", prepared.auraNames) then hasRuneAura = true end
	end
	if hasRuneAura then return nil end

	local displaySpellId = prepared.displaySpellId or normalizeSpellId(Reminder.runeTracking.auraIds[1])
	local displayLabel = prepared.displayLabel
	if type(displayLabel) ~= "string" or displayLabel == "" then displayLabel = L["ClassBuffReminderAugmentRune"] or "Augment Rune" end
	return makeSelfMissingEntry(displaySpellId, displayLabel, nil, nil, "RUNES", prepared.displayIcon)
end

function Reminder:IsWeaponEnchantUsable(expirationMS)
	local thresholdSeconds = self:GetExpirationWarningSeconds()
	if thresholdSeconds <= 0 then return true end
	expirationMS = tonumber(expirationMS)
	if not expirationMS or expirationMS <= 0 then return true end
	local remainingSeconds = expirationMS / 1000
	if remainingSeconds <= thresholdSeconds then return false end
	self:QueueExpirationWarningAt(nowSeconds() + remainingSeconds - thresholdSeconds)
	return true
end

function Reminder:GetWeaponBuffMissingEntry(evalContext)
	local candidates = self:GetWeaponBuffCandidates()
	if type(candidates) ~= "table" or #candidates <= 0 then return nil end
	if not GetWeaponEnchantInfo then return nil end

	local totalRequirements = 0
	local missingRequirements = 0
	local hasMainWeapon = isPlayerMainhandEnchantableWeapon()
	local hasOffhandWeapon = isPlayerOffhandEnchantableWeapon()
	local hasMainEnchant, mainExpirationMS, _, _, hasOffhandEnchant, offhandExpirationMS = GetWeaponEnchantInfo()

	if hasMainWeapon then
		totalRequirements = totalRequirements + 1
		if hasMainEnchant ~= true or not self:IsWeaponEnchantUsable(mainExpirationMS) then missingRequirements = missingRequirements + 1 end
	end

	if hasOffhandWeapon then
		totalRequirements = totalRequirements + 1
		if hasOffhandEnchant ~= true or not self:IsWeaponEnchantUsable(offhandExpirationMS) then missingRequirements = missingRequirements + 1 end
	end

	if totalRequirements <= 0 or missingRequirements <= 0 then return nil end

	local context = type(evalContext) == "table" and evalContext or nil
	local prepared = context and context.weaponBuffPreparedData or self:GetPreparedWeaponBuffCandidateData(candidates)
	if context and not context.weaponBuffPreparedData then context.weaponBuffPreparedData = prepared end

	return makeSelfMissingEntry(prepared.displaySpellId, prepared.displayLabel, nil, nil, "WEAPON_BUFF", prepared.displayIcon)
end

function Reminder:IsPetExpectedForPlayer()
	local pet = Reminder.petTracking
	local classToken = self:GetClassToken()
	local specId = self:GetCurrentSpecId()

	if classToken == "MAGE" then return specId == pet.specFrostMage and C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(pet.magePetTalent) == true end
	if classToken == "HUNTER" then
		if specId == pet.specMarksman then return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(pet.marksPetTalent) == true end
		return pet.petSpecs[specId] == true
	end
	if classToken == "DEATHKNIGHT" then return specId == 252 end
	if classToken == "WARLOCK" then return pet.petSpecs[specId] == true and not self:IsWarlockSacrificePetReminderSuppressed() end
	return false
end

function Reminder:IsWarlockSacrificePetReminderSuppressed()
	if self:GetClassToken() ~= "WARLOCK" then return false end
	local pet = Reminder.petTracking
	if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(pet.grimoireOfSacrifice) == true then return true end
	if IsPlayerSpell and IsPlayerSpell(pet.grimoireOfSacrifice) == true then return true end
	if InCombatLockdown and InCombatLockdown() then return false end
	if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
	if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(pet.grimoireOfSacrificeBuff) then return true end
	if AuraUtil and AuraUtil.FindAuraBySpellID and AuraUtil.FindAuraBySpellID(pet.grimoireOfSacrificeBuff, "player", "HELPFUL") then return true end
	return false
end

function Reminder:HasActivePet()
	if not UnitExists or not UnitExists("pet") then return false end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("pet") then return false end
	return true
end

function Reminder:IsPetReminderSuppressed()
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return true end
	if IsMounted and IsMounted() then return true end
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true end
	if UnitInVehicle and UnitInVehicle("player") then return true end
	if UnitOnTaxi and UnitOnTaxi("player") then return true end
	if IsFlying and IsFlying() then return true end
	return false
end

function Reminder:ClassifyPetStanceName(name)
	if name == "PET_MODE_ASSIST" or name == "PET_ACTION_ASSIST" then return Reminder.petTracking.stanceAssist end
	if name == "PET_MODE_DEFENSIVEASSIST" or name == "PET_ACTION_DEFENSIVE" then return Reminder.petTracking.stanceDefensive end
	if name == "PET_MODE_PASSIVE" or name == "PET_ACTION_MODE_PASSIVE" then return Reminder.petTracking.stancePassive end
	return nil
end

function Reminder:TryGetPetStanceWith(getInfoFunc)
	local inactiveStances = {}
	for i = 1, (_G.NUM_PET_ACTION_SLOTS or 10) do
		local name, _, _, isActive = getInfoFunc(i)
		if type(name) == "table" then
			isActive = name.isActive
			name = name.name
		end
		local stance = self:ClassifyPetStanceName(name)
		if stance then
			if isActive then return stance end
			inactiveStances[stance] = true
		end
	end

	local inactiveCount = 0
	for _ in pairs(inactiveStances) do inactiveCount = inactiveCount + 1 end
	if inactiveCount == 2 then
		local pet = Reminder.petTracking
		if not inactiveStances[pet.stanceAssist] then return pet.stanceAssist end
		if not inactiveStances[pet.stanceDefensive] then return pet.stanceDefensive end
		if not inactiveStances[pet.stancePassive] then return pet.stancePassive end
	end
	return nil
end

function Reminder:GetPetStance()
	local pet = Reminder.petTracking
	if not self:HasActivePet() then
		pet.cachedStance = nil
		return nil
	end
	if pet.cachedStance and GetTime and ((GetTime() - (pet.cachedStanceTime or 0)) < 0.5) then return pet.cachedStance end

	local apis = {}
	if C_PetBar and C_PetBar.GetPetActionInfo then apis[#apis + 1] = C_PetBar.GetPetActionInfo end
	if C_ActionBar and C_ActionBar.GetPetActionInfo then apis[#apis + 1] = C_ActionBar.GetPetActionInfo end
	if GetPetActionInfo then apis[#apis + 1] = GetPetActionInfo end
	for i = 1, #apis do
		local ok, stance = pcall(function() return Reminder:TryGetPetStanceWith(apis[i]) end)
		if ok and stance then
			pet.cachedStance = stance
			pet.cachedStanceTime = GetTime and GetTime() or 0
			return stance
		end
	end
	return pet.cachedStance
end

function Reminder:SetupPetTrackingHooks()
	local pet = Reminder.petTracking
	if pet.hooksInstalled then return end
	pet.hooksInstalled = true

	local function updateCachedStance(stance)
		pet.cachedStance = stance
		pet.cachedStanceTime = GetTime and GetTime() or 0
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if Reminder:IsPetTrackingEnabled() then Reminder:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true) end
			end)
		elseif Reminder:IsPetTrackingEnabled() then
			Reminder:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		end
	end

	local hooks = {
		{ func = "PetPassiveMode", stance = pet.stancePassive },
		{ func = "PetDefensiveMode", stance = pet.stanceDefensive },
		{ func = "PetAssistMode", stance = pet.stanceAssist },
	}
	for i = 1, #hooks do
		if _G[hooks[i].func] then
			local stance = hooks[i].stance
			pcall(hooksecurefunc, hooks[i].func, function() updateCachedStance(stance) end)
		end
	end
end

function Reminder:GetPetReminderIcon(state)
	local pet = Reminder.petTracking
	local spellId
	if state == "passive" then
		return 132311
	elseif state == "defensive" then
		return 132110
	else
		local classToken = self:GetClassToken()
		local specId = self:GetCurrentSpecId()
		if classToken == "MAGE" then
			spellId = pet.magePetTalent
		elseif classToken == "DEATHKNIGHT" then
			spellId = pet.raiseDead
		elseif classToken == "HUNTER" then
			spellId = pet.callPet
		elseif classToken == "WARLOCK" then
			spellId = pet.summonImp
		elseif specId == pet.specFrostMage then
			spellId = pet.magePetTalent
		end
	end
	return spellId and safeGetSpellIcon(spellId) or "Interface\\Icons\\Ability_Hunter_BeastCall"
end

function Reminder:GetPetReminderShortText(state)
	if getValue("classBuffReminderHidePetReminderText", defaults.hidePetReminderText) == true then return nil end
	if state == "passive" then return L["ClassBuffReminderPetPassiveShort"] or "Pet\nPassive" end
	if state == "defensive" then return L["ClassBuffReminderPetDefensiveShort"] or "Pet\nDefensive" end
	return nil
end

function Reminder:GetPetMissingEntry()
	if not self:IsPetExpectedForPlayer() then return nil end
	if self:IsPetReminderSuppressed() then return nil end

	if not self:HasActivePet() then
		return makeSelfMissingEntry(nil, L["ClassBuffReminderPetMissing"] or L["Pet Missing"] or "Pet Missing", nil, nil, "PET", self:GetPetReminderIcon("missing"))
	end

	local stance = self:GetPetStance()
	if stance == Reminder.petTracking.stancePassive and not self:ShouldIgnorePetPassiveReminder() then
		return makeSelfMissingEntry(nil, L["ClassBuffReminderPetPassive"] or "Pet Passive", nil, nil, "PET", self:GetPetReminderIcon("passive"), self:GetPetReminderShortText("passive"))
	end
	if stance == Reminder.petTracking.stanceDefensive and not self:ShouldIgnorePetDefensiveReminder() then
		return makeSelfMissingEntry(nil, L["ClassBuffReminderPetDefensive"] or "Pet Defensive", nil, nil, "PET", self:GetPetReminderIcon("defensive"), self:GetPetReminderShortText("defensive"))
	end
	return nil
end

function Reminder:GetSupplementalMissingEntries(evalContext)
	if not canEvaluateUnit("player") then return nil end

	local context = type(evalContext) == "table" and evalContext or nil
	local entries = {}
	if not (context and context.onlyPetReminder == true) and self:CanEvaluateFlaskReminderNow() then
		local flaskEntry = self:GetFlaskMissingEntry(context)
		if flaskEntry then entries[#entries + 1] = flaskEntry end
	end
	if not (context and context.onlyPetReminder == true) and self:CanEvaluateFoodReminderNow() then
		local foodEntry = self:GetFoodMissingEntry(context)
		if foodEntry then entries[#entries + 1] = foodEntry end
	end
	if not (context and context.onlyPetReminder == true) and self:CanEvaluateRuneReminderNow() then
		local runeEntry = self:GetRuneMissingEntry(context)
		if runeEntry then entries[#entries + 1] = runeEntry end
	end
	if not (context and context.onlyPetReminder == true) and self:CanEvaluateWeaponBuffReminderNow() then
		local weaponBuffEntry = self:GetWeaponBuffMissingEntry(context)
		if weaponBuffEntry then entries[#entries + 1] = weaponBuffEntry end
	end
	if self:CanEvaluatePetReminderNow() then
		local petEntry = self:GetPetMissingEntry()
		if petEntry then entries[#entries + 1] = petEntry end
	end
	if #entries <= 0 then return nil end
	return entries
end

function Reminder:UnitHasAnyAuraSpellId(unit, spellIds)
	if type(spellIds) ~= "table" then return false end
	for i = 1, #spellIds do
		local sid = normalizeSpellId(spellIds[i])
		if sid and unitHasAuraBySpellId(unit, sid) then return true end
	end
	return false
end

function Reminder:UnitHasAnyAuraName(unit, auraNames)
	if type(auraNames) ~= "table" then return false end
	if type(unit) ~= "string" or unit == "" then return false end
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then return false end

	local targetNames = {}
	for i = 1, #auraNames do
		local auraName = auraNames[i]
		if type(auraName) == "string" and auraName ~= "" then targetNames[auraName] = true end
	end
	if not next(targetNames) then return false end

	local continuationToken
	for _ = 1, AURA_SLOT_SCAN_GUARD do
		local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer(unit, continuationToken)
		for i = 2, slotCount do
			local slot = slots[i]
			if not (issecretvalue and issecretvalue(slot)) then
				local aura = C_UnitAuras.GetAuraDataBySlot(unit, slot)
				if aura and not (issecretvalue and issecretvalue(aura)) then
					local isHelpful = aura.isHelpful
					if issecretvalue and issecretvalue(isHelpful) then isHelpful = nil end
					if isHelpful ~= false then
						local activeName = aura.name
						if not (issecretvalue and issecretvalue(activeName)) and type(activeName) == "string" and targetNames[activeName] and self:IsAuraUsableForReminder(aura) then return true end
					end
				end
			end
		end

		if nextToken == nil then break end
		continuationToken = nextToken
	end

	return false
end

function Reminder:UnitHasAnyAuraSpellIdOrDerivedName(unit, spellIds)
	if self:UnitHasAnyAuraSpellId(unit, spellIds) then return true end
	if type(spellIds) ~= "table" then return false end

	local auraNames = {}
	local seen = {}
	for i = 1, #spellIds do
		local name = safeGetSpellName(spellIds[i])
		if type(name) == "string" and name ~= "" and not seen[name] then
			seen[name] = true
			auraNames[#auraNames + 1] = name
		end
	end

	if #auraNames <= 0 then return false end
	return self:UnitHasAnyAuraName(unit, auraNames)
end

function Reminder:UnitHasAuraIcon(unit, iconId)
	iconId = tonumber(iconId)
	if not iconId or iconId <= 0 then return false end
	if type(unit) ~= "string" or unit == "" then return false end
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then return false end

	local continuationToken
	for _ = 1, AURA_SLOT_SCAN_GUARD do
		local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer(unit, continuationToken)
		for i = 2, slotCount do
			local slot = slots[i]
			if not (issecretvalue and issecretvalue(slot)) then
				local aura = C_UnitAuras.GetAuraDataBySlot(unit, slot)
				if aura and not (issecretvalue and issecretvalue(aura)) then
					local isHelpful = aura.isHelpful
					if issecretvalue and issecretvalue(isHelpful) then isHelpful = nil end
					if isHelpful ~= false then
						local auraIcon = aura.icon
						if issecretvalue and issecretvalue(auraIcon) then auraIcon = nil end
						auraIcon = tonumber(auraIcon)
						if auraIcon and auraIcon == iconId and self:IsAuraUsableForReminder(aura) then return true end
					end
				end
			end
		end

		if nextToken == nil then break end
		continuationToken = nextToken
	end

	return false
end

function Reminder:GetGroupBuffMissingCountBySpellIds(spellIds, includeAIFollowers)
	local cache = self:GetGroupBuffStateCache(spellIds, includeAIFollowers)
	if not cache then return 0, 0 end

	local state = self:GetGroupBuffState(cache)
	if type(state) ~= "table" then return 0, 0 end
	return tonumber(state.missing) or 0, tonumber(state.total) or 0
end

function Reminder:GetSharedClassBuffMissingCountBySpellIds(spellIds)
	-- Shared class buffs should ignore follower dungeon AI companions.
	return self:GetGroupBuffMissingCountBySpellIds(spellIds, false)
end

local function anyUnitHasAnyAuraSpellId(reminder, units, spellIds)
	if type(reminder) ~= "table" or type(units) ~= "table" or type(spellIds) ~= "table" then return false end
	for i = 1, #units do
		if reminder:UnitHasAnyAuraSpellId(units[i], spellIds) then return true end
	end
	return false
end

local function paladinRitesHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	if type(reminder) ~= "table" then return false end
	if reminder:UnitHasAnyAuraSpellId(unit, provider and provider.spellIds) then return true end
	if not provider then return false end
	if type(provider.enchantIds) == "table" and #provider.enchantIds > 0 then return playerHasAnyEnchantId(provider.enchantIds) end
	return playerHasEnchantId(provider.enchantId)
end

local function paladinRitesGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(1, {}) end

	local totalRequirements = 0
	local activeSpellId = normalizeSpellId(provider.spellIds and provider.spellIds[1]) or normalizeSpellId(provider.displaySpellId)
	local hasRite = false
	if provider.trackRites == true then
		totalRequirements = totalRequirements + 1
		if reminder:UnitHasAnyAuraSpellId("player", provider.spellIds) then
			hasRite = true
		elseif type(provider.enchantIds) == "table" and #provider.enchantIds > 0 and playerHasAnyEnchantId(provider.enchantIds) then
			hasRite = true
		elseif provider.enchantId and playerHasEnchantId(provider.enchantId) then
			hasRite = true
		end
	end

	local missingEntries = {}
	if provider.trackRites == true and not hasRite then missingEntries[1] = makeSelfMissingEntry(activeSpellId, provider.fallbackName or "Rite") end

	if reminder:GetCurrentSpecId() == PALADIN_SPEC_HOLY then
		reminder.runtimeEligibleUnits = reminder.runtimeEligibleUnits or {}
		local eligibleUnits = reminder:CollectEligibleUnits(reminder.runtimeEligibleUnits, true)

		if #eligibleUnits > 1 then
			totalRequirements = totalRequirements + 1
			local beaconOfLightDisplaySpellId = normalizeSpellId(provider.beaconOfLightDisplaySpellId) or normalizeSpellId(provider.beaconOfLightSpellIds and provider.beaconOfLightSpellIds[1])
			if not anyUnitHasAnyAuraSpellId(reminder, eligibleUnits, provider.beaconOfLightSpellIds) then
				missingEntries[#missingEntries + 1] = makeSelfMissingEntry(beaconOfLightDisplaySpellId, provider.beaconOfLightLabel or "Beacon of Light")
			end
		end

		local shouldTrackSecondBeacon = #eligibleUnits > 1 and hasKnownSpellInList(provider.beaconOfFaithKnownSpellIds or provider.beaconOfFaithSpellIds)
		if shouldTrackSecondBeacon then
			totalRequirements = totalRequirements + 1
			local beaconOfFaithDisplaySpellId = normalizeSpellId(provider.beaconOfFaithDisplaySpellId) or normalizeSpellId(provider.beaconOfFaithSpellIds and provider.beaconOfFaithSpellIds[1])
			if not anyUnitHasAnyAuraSpellId(reminder, eligibleUnits, provider.beaconOfFaithSpellIds) then
				missingEntries[#missingEntries + 1] = makeSelfMissingEntry(beaconOfFaithDisplaySpellId, provider.beaconOfFaithLabel or "Beacon of Faith")
			end
		end
	end

	setProviderDisplaySpellId(provider, missingEntries[1] and missingEntries[1].spellId or activeSpellId)
	return buildSelfStatus(totalRequirements, missingEntries)
end

local function getRoguePoisonPresence(provider, reminder)
	local hasLethal = reminder:UnitHasAnyAuraSpellId("player", provider.lethalSpellIds)
	local hasUtility = reminder:UnitHasAnyAuraSpellId("player", provider.utilitySpellIds)

	return hasLethal, hasUtility
end

local function roguePoisonsGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(2, {}) end

	local lethalDisplayId = normalizeSpellId(provider.lethalDisplaySpellId) or normalizeSpellId(provider.lethalSpellIds and provider.lethalSpellIds[1])
	local utilityDisplayId = normalizeSpellId(provider.utilityDisplaySpellId) or normalizeSpellId(provider.utilitySpellIds and provider.utilitySpellIds[1])
	local trackLethal = hasKnownSpellInList(provider.lethalKnownSpellIds or provider.lethalSpellIds)
	local trackUtility = hasKnownSpellInList(provider.utilityKnownSpellIds or provider.utilitySpellIds)
	local hasLethal, hasUtility = getRoguePoisonPresence(provider, reminder)

	local missingEntries = {}
	if trackLethal and not hasLethal then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(lethalDisplayId, "Lethal Poison") end
	if trackUtility and not hasUtility then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(utilityDisplayId, "Non-lethal Poison") end

	if #missingEntries > 0 then
		setProviderDisplaySpellId(provider, missingEntries[1].spellId)
	else
		setProviderDisplaySpellId(provider, lethalDisplayId or utilityDisplayId)
	end

	local totalRequirements = (trackLethal and 1 or 0) + (trackUtility and 1 or 0)
	return buildSelfStatus(totalRequirements, missingEntries)
end

local function roguePoisonsHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = roguePoisonsGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

function Reminder:GetShamanPreferredShieldDisplaySpellId(provider)
	local specId = self and self.GetCurrentSpecId and self:GetCurrentSpecId() or nil
	if specId == Reminder.shamanReminder.specRestoration or isUnitHealerRole("player") then
		return normalizeSpellId(provider and provider.waterShieldDisplaySpellId) or normalizeSpellId(provider and provider.waterShieldSpellIds and provider.waterShieldSpellIds[1]) or 52127
	end
	return normalizeSpellId(provider and provider.lightningShieldDisplaySpellId) or normalizeSpellId(provider and provider.lightningShieldSpellIds and provider.lightningShieldSpellIds[1]) or 192106
end

function Reminder:ShouldIgnoreShamanBasicShieldsInRestrictedContent()
	return addon and addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true) == true
end

function Reminder:AppendShamanShieldMissingEntries(provider, missingEntries)
	if type(provider) ~= "table" or type(self) ~= "table" or type(missingEntries) ~= "table" then return 0 end
	if hasKnownSpellInList(provider.shieldKnownSpellIds or provider.shieldSpellIds) ~= true then return 0 end

	local totalRequirements = 0
	local hasElementalOrbit = hasKnownSpellInList(provider.elementalOrbitKnownSpellIds or provider.elementalOrbitSpellIds)
	local ignoreBasicShields = self:ShouldIgnoreShamanBasicShieldsInRestrictedContent()
	local preferredShieldDisplaySpellId = self:GetShamanPreferredShieldDisplaySpellId(provider)
	local preferredShieldLabel = safeGetSpellName(preferredShieldDisplaySpellId) or safeGetSpellName(52127) or safeGetSpellName(192106) or "Shield"
	local hasLightningShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.lightningShieldSpellIds)
	local hasWaterShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.waterShieldSpellIds)

	if hasElementalOrbit then
		local earthShieldDisplaySpellId = normalizeSpellId(provider.earthShieldDisplaySpellId) or normalizeSpellId(provider.earthShieldSpellIds and provider.earthShieldSpellIds[1]) or 974
		local earthShieldLabel = safeGetSpellName(earthShieldDisplaySpellId) or "Earth Shield"
		local hasEarthShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.earthShieldSelfSpellIds)
		if not hasEarthShield then hasEarthShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.earthShieldSpellIds) end

		totalRequirements = totalRequirements + 1
		if not hasEarthShield then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(earthShieldDisplaySpellId, earthShieldLabel) end

		if not ignoreBasicShields then
			totalRequirements = totalRequirements + 1
			if not (hasLightningShield or hasWaterShield) then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(preferredShieldDisplaySpellId, preferredShieldLabel) end
		end

		return totalRequirements
	end

	if ignoreBasicShields then return totalRequirements end

	totalRequirements = totalRequirements + 1
	local hasAnyShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.shieldSpellIds)
	if not hasAnyShield and provider.earthShieldSelfSpellIds then hasAnyShield = self:UnitHasAnyAuraSpellIdOrDerivedName("player", provider.earthShieldSelfSpellIds) end
	if not hasAnyShield then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(preferredShieldDisplaySpellId, preferredShieldLabel) end
	return totalRequirements
end

local function shamanEnhancementGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(0, {}) end

	local trackWindfury = hasKnownSpellInList(provider.windfuryKnownSpellIds or provider.windfurySpellIds)
	local trackFlametongue = hasKnownSpellInList(provider.flametongueKnownSpellIds or provider.flametongueSpellIds)
	local trackSkyfury = hasKnownSpellInList(provider.skyfuryKnownSpellIds or provider.skyfurySpellIds)
	local totalRequirements = (trackWindfury and 1 or 0) + (trackFlametongue and 1 or 0)
	local missingEntries = {}
	local shouldEvaluateGroupResponsibilities = reminder:ShouldEvaluateGroupResponsibilities(provider)

	local skyfuryDisplayId = normalizeSpellId(provider.skyfuryDisplaySpellId) or normalizeSpellId(provider.skyfurySpellIds and provider.skyfurySpellIds[1])
	local skyfuryMissingCount, skyfuryTotal = 0, 0
	if trackSkyfury and shouldEvaluateGroupResponsibilities then
		skyfuryMissingCount, skyfuryTotal = reminder:GetSharedClassBuffMissingCountBySpellIds(provider.skyfurySpellIds)
	end
	if shouldEvaluateGroupResponsibilities and skyfuryTotal > 0 then
		totalRequirements = totalRequirements + 1
		if skyfuryMissingCount > 0 then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(skyfuryDisplayId, provider.skyfuryLabel or "Skyfury", skyfuryMissingCount, skyfuryTotal) end
	end

	local windfuryDisplayId = normalizeSpellId(provider.windfuryDisplaySpellId) or normalizeSpellId(provider.windfurySpellIds and provider.windfurySpellIds[1])
	local flametongueDisplayId = normalizeSpellId(provider.flametongueDisplaySpellId) or normalizeSpellId(provider.flametongueSpellIds and provider.flametongueSpellIds[1])
	local hasWindfury = reminder:UnitHasAnyAuraSpellId("player", provider.windfurySpellIds)
	local hasFlametongue = reminder:UnitHasAnyAuraSpellId("player", provider.flametongueSpellIds)

	if GetWeaponEnchantInfo then
		local hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
		if not hasWindfury and hasMainHandEnchant then hasWindfury = true end
		if not hasFlametongue and hasOffHandEnchant then hasFlametongue = true end
	end

	if trackWindfury and not hasWindfury then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(windfuryDisplayId, "Windfury Weapon") end
	if trackFlametongue and not hasFlametongue then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(flametongueDisplayId, "Flametongue Weapon") end
	totalRequirements = totalRequirements + reminder:AppendShamanShieldMissingEntries(provider, missingEntries)

	if #missingEntries > 0 then
		setProviderDisplaySpellId(provider, missingEntries[1].spellId)
	else
		local shieldDisplaySpellId = reminder:GetShamanPreferredShieldDisplaySpellId(provider)
		local preferredDisplaySpellId = (trackSkyfury and skyfuryDisplayId) or (trackWindfury and windfuryDisplayId) or (trackFlametongue and flametongueDisplayId) or shieldDisplaySpellId
		setProviderDisplaySpellId(provider, preferredDisplaySpellId or skyfuryDisplayId or windfuryDisplayId or flametongueDisplayId)
	end

	return buildSelfStatus(totalRequirements, missingEntries)
end

local function shamanEnhancementImbuesHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = shamanEnhancementGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

local function shamanRestorationGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(0, {}) end

	local trackEarthliving = hasKnownSpellInList(provider.earthlivingKnownSpellIds or provider.earthlivingSpellIds or provider.spellIds)
	local trackSkyfury = hasKnownSpellInList(provider.skyfuryKnownSpellIds or provider.skyfurySpellIds)
	local totalRequirements = trackEarthliving and 1 or 0
	local missingEntries = {}
	local shouldEvaluateGroupResponsibilities = reminder:ShouldEvaluateGroupResponsibilities(provider)

	local skyfuryDisplayId = normalizeSpellId(provider.skyfuryDisplaySpellId) or normalizeSpellId(provider.skyfurySpellIds and provider.skyfurySpellIds[1])
	local skyfuryMissingCount, skyfuryTotal = 0, 0
	if trackSkyfury and shouldEvaluateGroupResponsibilities then
		skyfuryMissingCount, skyfuryTotal = reminder:GetSharedClassBuffMissingCountBySpellIds(provider.skyfurySpellIds)
	end
	if shouldEvaluateGroupResponsibilities and skyfuryTotal > 0 then
		totalRequirements = totalRequirements + 1
		if skyfuryMissingCount > 0 then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(skyfuryDisplayId, provider.skyfuryLabel or "Skyfury", skyfuryMissingCount, skyfuryTotal) end
	end

	local earthlivingDisplaySpellId = normalizeSpellId(provider.earthlivingDisplaySpellId)
		or normalizeSpellId(provider.primaryDisplaySpellId)
		or normalizeSpellId(provider.earthlivingSpellIds and provider.earthlivingSpellIds[1])
		or normalizeSpellId(provider.displaySpellId)
	local hasEarthliving = false
	if trackEarthliving then
		hasEarthliving = reminder:UnitHasAnyAuraSpellId("player", provider.earthlivingSpellIds or provider.spellIds)
		if not hasEarthliving then hasEarthliving = reminder:UnitHasAnyAuraName("player", provider.earthlivingAuraNames) end
		if not hasEarthliving and GetWeaponEnchantInfo then
			local hasMainHandEnchant, _, _, mainHandEnchantId = GetWeaponEnchantInfo()
			local expectedEnchantId = tonumber(provider.enchantId)
			if expectedEnchantId and tonumber(mainHandEnchantId) == expectedEnchantId then
				hasEarthliving = true
			elseif expectedEnchantId and mainHandEnchantId == nil and hasMainHandEnchant then
				hasEarthliving = true
			end
		end
	end

	if trackEarthliving and not hasEarthliving then
		missingEntries[#missingEntries + 1] = makeSelfMissingEntry(earthlivingDisplaySpellId, provider.earthlivingLabel or provider.fallbackName or "Earthliving Weapon")
	end

	local shouldTrackTidecaller = hasKnownSpellInList(provider.tidecallerKnownSpellIds or provider.tidecallerSpellIds)
	if shouldTrackTidecaller and provider.requireShieldForTidecaller == true and not isPlayerOffhandShield() then shouldTrackTidecaller = false end
	if shouldTrackTidecaller then
		totalRequirements = totalRequirements + 1

		local tidecallerDisplaySpellId = normalizeSpellId(provider.tidecallerDisplaySpellId) or normalizeSpellId(provider.tidecallerSpellIds and provider.tidecallerSpellIds[1])
		local hasTidecaller = reminder:UnitHasAnyAuraSpellId("player", provider.tidecallerSpellIds)
		if not hasTidecaller then hasTidecaller = reminder:UnitHasAnyAuraName("player", provider.tidecallerAuraNames) end
		if not hasTidecaller and GetWeaponEnchantInfo then
			local _, _, _, _, hasOffHandEnchant, _, _, offHandEnchantId = GetWeaponEnchantInfo()
			local expectedTidecallerEnchantId = tonumber(provider.tidecallerEnchantId)
			if expectedTidecallerEnchantId and tonumber(offHandEnchantId) == expectedTidecallerEnchantId then
				hasTidecaller = true
			elseif provider.acceptAnyOffhandEnchantWhenKnown == true and hasOffHandEnchant then
				hasTidecaller = true
			end
		end

		if not hasTidecaller then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(tidecallerDisplaySpellId, provider.tidecallerLabel or "Tidecaller's Guard") end
	end

	totalRequirements = totalRequirements + reminder:AppendShamanShieldMissingEntries(provider, missingEntries)

	local shieldDisplaySpellId = reminder:GetShamanPreferredShieldDisplaySpellId(provider)
	local preferredDisplaySpellId = (trackSkyfury and skyfuryDisplayId) or (trackEarthliving and earthlivingDisplaySpellId) or shieldDisplaySpellId
	setProviderDisplaySpellId(provider, missingEntries[1] and missingEntries[1].spellId or preferredDisplaySpellId or skyfuryDisplayId or earthlivingDisplaySpellId)
	return buildSelfStatus(totalRequirements, missingEntries)
end

local function shamanRestorationEarthlivingHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = shamanRestorationGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

function Reminder.ShamanGeneralGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(0, {}) end

	local trackSkyfury = hasKnownSpellInList(provider.skyfuryKnownSpellIds or provider.skyfurySpellIds)
	local totalRequirements = 0
	local missingEntries = {}
	local shouldEvaluateGroupResponsibilities = reminder:ShouldEvaluateGroupResponsibilities(provider)
	local skyfuryDisplayId = normalizeSpellId(provider.skyfuryDisplaySpellId) or normalizeSpellId(provider.skyfurySpellIds and provider.skyfurySpellIds[1])
	local skyfuryMissingCount, skyfuryTotal = 0, 0

	if trackSkyfury and shouldEvaluateGroupResponsibilities then
		skyfuryMissingCount, skyfuryTotal = reminder:GetSharedClassBuffMissingCountBySpellIds(provider.skyfurySpellIds)
	end
	if shouldEvaluateGroupResponsibilities and skyfuryTotal > 0 then
		totalRequirements = totalRequirements + 1
		if skyfuryMissingCount > 0 then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(skyfuryDisplayId, provider.skyfuryLabel or "Skyfury", skyfuryMissingCount, skyfuryTotal) end
	end

	totalRequirements = totalRequirements + reminder:AppendShamanShieldMissingEntries(provider, missingEntries)

	if #missingEntries > 0 then
		setProviderDisplaySpellId(provider, missingEntries[1].spellId)
	else
		local shieldDisplaySpellId = reminder:GetShamanPreferredShieldDisplaySpellId(provider)
		setProviderDisplaySpellId(provider, (trackSkyfury and skyfuryDisplayId) or shieldDisplaySpellId or skyfuryDisplayId)
	end

	return buildSelfStatus(totalRequirements, missingEntries)
end

function Reminder.ShamanGeneralHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = Reminder.ShamanGeneralGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

local function druidRestorationGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(0, {}) end

	local totalRequirements = 0
	local missingEntries = {}
	local shouldEvaluateGroupResponsibilities = reminder:ShouldEvaluateGroupResponsibilities(provider)

	local markDisplaySpellId = normalizeSpellId(provider.markDisplaySpellId) or normalizeSpellId(provider.markSpellIds and provider.markSpellIds[1])
	local trackMark = hasKnownSpellInList(provider.markKnownSpellIds or provider.markSpellIds)
	local markMissingCount, markTotal = 0, 0
	if trackMark and shouldEvaluateGroupResponsibilities then
		markMissingCount, markTotal = reminder:GetSharedClassBuffMissingCountBySpellIds(provider.markSpellIds)
	end
	if shouldEvaluateGroupResponsibilities and markTotal > 0 then
		totalRequirements = totalRequirements + 1
		if markMissingCount > 0 then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(markDisplaySpellId, provider.markLabel or "Mark of the Wild", markMissingCount, markTotal) end
	end

	local trackSymbiotic = hasKnownSpellInList(provider.symbioticKnownSpellIds or provider.symbioticSpellIds)
	if trackSymbiotic and reminder:GetGroupContext() ~= GROUP_CONTEXT_SOLO then
		reminder.runtimeEligibleUnits = reminder.runtimeEligibleUnits or {}
		local eligibleUnits = reminder:CollectOtherEligibleUnits(reminder.runtimeEligibleUnits, true)
		if #eligibleUnits > 0 then
			totalRequirements = totalRequirements + 1
			if not reminder:UnitHasAnyAuraSpellId("player", provider.symbioticSpellIds) then
				local symbioticDisplaySpellId = normalizeSpellId(provider.symbioticDisplaySpellId) or normalizeSpellId(provider.symbioticSpellIds and provider.symbioticSpellIds[1])
				missingEntries[#missingEntries + 1] = makeSelfMissingEntry(symbioticDisplaySpellId, provider.symbioticLabel or "Symbiotic Relationship")
			end
		end
	end

	setProviderDisplaySpellId(
		provider,
		missingEntries[1] and missingEntries[1].spellId or markDisplaySpellId or normalizeSpellId(provider.symbioticDisplaySpellId) or normalizeSpellId(provider.displaySpellId)
	)
	return buildSelfStatus(totalRequirements, missingEntries)
end

local function druidRestorationHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = druidRestorationGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

local function evokerSupportGetSelfStatus(provider, reminder)
	if type(provider) ~= "table" or type(reminder) ~= "table" then return buildSelfStatus(0, {}) end
	if reminder:ShouldEvaluateGroupResponsibilities(provider) ~= true then return buildSelfStatus(0, {}) end

	local totalRequirements = 0
	local missingEntries = {}

	local sourceDisplaySpellId = normalizeSpellId(provider.sourceDisplaySpellId) or normalizeSpellId(provider.sourceSpellIds and provider.sourceSpellIds[1])
	local shouldTrackSource = hasKnownSpellInList(provider.sourceKnownSpellIds or provider.sourceSpellIds)
	if shouldTrackSource then
		reminder.runtimeHealerUnits = reminder.runtimeHealerUnits or {}
		local healerUnits = reminder:CollectOtherHealerUnits(reminder.runtimeHealerUnits, true)
		if #healerUnits > 0 then
			totalRequirements = totalRequirements + 1
			local hasSourceOnTarget = false
			for i = 1, #healerUnits do
				local unit = healerUnits[i]
				if reminder:UnitHasAnyAuraSpellId(unit, provider.sourceSpellIds) then
					hasSourceOnTarget = true
					break
				end
				if reminder:UnitHasAnyAuraName(unit, provider.sourceAuraNames) then
					hasSourceOnTarget = true
					break
				end
			end

			if not hasSourceOnTarget then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(sourceDisplaySpellId, provider.sourceLabel or "Source of Magic") end
		end
	end

	local bronzeDisplaySpellId = normalizeSpellId(provider.bronzeDisplaySpellId) or normalizeSpellId(provider.bronzeSpellIds and provider.bronzeSpellIds[1])
	local shouldTrackBronze = hasKnownSpellInList(provider.bronzeKnownSpellIds or provider.bronzeSpellIds)
	if shouldTrackBronze then
		local bronzeMissingCount, bronzeTotal = reminder:GetSharedClassBuffMissingCountBySpellIds(provider.bronzeSpellIds)
		if bronzeTotal > 0 then
			totalRequirements = totalRequirements + 1
			if bronzeMissingCount > 0 then
				missingEntries[#missingEntries + 1] = makeSelfMissingEntry(bronzeDisplaySpellId, provider.bronzeLabel or "Blessing of the Bronze", bronzeMissingCount, bronzeTotal)
			end
		end
	end

	local blisteringDisplaySpellId = normalizeSpellId(provider.blisteringDisplaySpellId) or normalizeSpellId(provider.blisteringSpellIds and provider.blisteringSpellIds[1])
	local shouldTrackBlistering = hasKnownSpellInList(provider.blisteringKnownSpellIds or provider.blisteringSpellIds)
	if shouldTrackBlistering then
		reminder.runtimeEligibleUnits = reminder.runtimeEligibleUnits or {}
		local eligibleUnits = reminder:CollectEligibleUnits(reminder.runtimeEligibleUnits, true)
		if #eligibleUnits > 0 then
			totalRequirements = totalRequirements + 1
			local hasBlisteringOnTarget = false
			for i = 1, #eligibleUnits do
				local unit = eligibleUnits[i]
				if reminder:UnitHasAnyAuraSpellId(unit, provider.blisteringSpellIds) then
					hasBlisteringOnTarget = true
					break
				end
				if reminder:UnitHasAnyAuraName(unit, provider.blisteringAuraNames) then
					hasBlisteringOnTarget = true
					break
				end
			end

			if not hasBlisteringOnTarget then missingEntries[#missingEntries + 1] = makeSelfMissingEntry(blisteringDisplaySpellId, provider.blisteringLabel or "Blistering Scales") end
		end
	end

	setProviderDisplaySpellId(provider, missingEntries[1] and missingEntries[1].spellId or sourceDisplaySpellId or blisteringDisplaySpellId or bronzeDisplaySpellId)
	return buildSelfStatus(totalRequirements, missingEntries)
end

local function evokerSupportHasUnitBuff(provider, unit, reminder)
	if unit ~= "player" then return false end
	local status = evokerSupportGetSelfStatus(provider, reminder)
	return status and status.missing <= 0
end

function Reminder:GetEvokerSupportProvider()
	self.evokerSupportProvider = self.evokerSupportProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				369459,
				360827,
				381732,
				381741,
				381746,
				381748,
				381749,
				381750,
				381751,
				381752,
				381753,
				381754,
				381756,
				381757,
				381758,
			},
			sourceSpellIds = EVOKER_SOURCE_OF_MAGIC_IDS,
			sourceKnownSpellIds = EVOKER_SOURCE_OF_MAGIC_IDS,
			sourceAuraNames = { "Source of Magic" },
			sourceLabel = "Source of Magic",
			sourceDisplaySpellId = 369459,
			blisteringSpellIds = EVOKER_BLISTERING_SCALES_IDS,
			blisteringKnownSpellIds = EVOKER_BLISTERING_SCALES_IDS,
			blisteringAuraNames = { "Blistering Scales" },
			blisteringLabel = "Blistering Scales",
			blisteringDisplaySpellId = 360827,
			bronzeSpellIds = EVOKER_BLESSING_OF_BRONZE_IDS,
			bronzeKnownSpellIds = EVOKER_BLESSING_OF_BRONZE_IDS,
			bronzeLabel = "Blessing of the Bronze",
			bronzeDisplaySpellId = 381748,
			fallbackName = "Source of Magic",
			tracksExternalUnitAuras = true,
			hasUnitBuffFunc = evokerSupportHasUnitBuff,
			getSelfStatusFunc = evokerSupportGetSelfStatus,
		}

	return self.evokerSupportProvider
end

function Reminder:GetPaladinRitesProvider()
	local adjurationKnown = safeIsPlayerSpell(PALADIN_RITES.adjuration.spellId)
	local sanctificationKnown = safeIsPlayerSpell(PALADIN_RITES.sanctification.spellId)
	local holyPaladin = self:GetCurrentSpecId() == PALADIN_SPEC_HOLY
	local beaconOfLightKnown = holyPaladin and hasKnownSpellInList(HOLY_PALADIN_BEACON_OF_LIGHT_IDS) or false
	local beaconOfFaithKnown = holyPaladin and hasKnownSpellInList(HOLY_PALADIN_BEACON_OF_FAITH_IDS) or false
	local hasHolyBeaconSupport = holyPaladin and (beaconOfLightKnown or beaconOfFaithKnown)
	if not adjurationKnown and not sanctificationKnown and not hasHolyBeaconSupport then return nil end

	local spellIds
	local enchantIds
	local fallbackName
	local nextKey
	local displaySpellId
	local trackRites = adjurationKnown or sanctificationKnown

	if trackRites and adjurationKnown and not sanctificationKnown then
		spellIds = { PALADIN_RITES.adjuration.spellId }
		enchantIds = { PALADIN_RITES.adjuration.enchantId }
		fallbackName = PALADIN_RITES.adjuration.fallbackName
		nextKey = tostring(PALADIN_RITES.adjuration.spellId)
		displaySpellId = PALADIN_RITES.adjuration.spellId
	elseif trackRites and sanctificationKnown and not adjurationKnown then
		spellIds = { PALADIN_RITES.sanctification.spellId }
		enchantIds = { PALADIN_RITES.sanctification.enchantId }
		fallbackName = PALADIN_RITES.sanctification.fallbackName
		nextKey = tostring(PALADIN_RITES.sanctification.spellId)
		displaySpellId = PALADIN_RITES.sanctification.spellId
	elseif trackRites then
		spellIds = { PALADIN_RITES.adjuration.spellId, PALADIN_RITES.sanctification.spellId }
		enchantIds = { PALADIN_RITES.adjuration.enchantId, PALADIN_RITES.sanctification.enchantId }
		fallbackName = "Rite"
		nextKey = "both"
		displaySpellId = PALADIN_RITES.adjuration.spellId
		if self:UnitHasAnyAuraSpellId("player", { PALADIN_RITES.sanctification.spellId }) or playerHasEnchantId(PALADIN_RITES.sanctification.enchantId) then
			displaySpellId = PALADIN_RITES.sanctification.spellId
		elseif self:UnitHasAnyAuraSpellId("player", { PALADIN_RITES.adjuration.spellId }) or playerHasEnchantId(PALADIN_RITES.adjuration.enchantId) then
			displaySpellId = PALADIN_RITES.adjuration.spellId
		end
	else
		spellIds = {}
		if beaconOfLightKnown then spellIds[#spellIds + 1] = HOLY_PALADIN_BEACON_OF_LIGHT_IDS[1] end
		if beaconOfFaithKnown then spellIds[#spellIds + 1] = HOLY_PALADIN_BEACON_OF_FAITH_IDS[1] end
		enchantIds = {}
		fallbackName = "Beacon"
		nextKey = "holy_beacons"
		displaySpellId = spellIds[1] or HOLY_PALADIN_BEACON_OF_LIGHT_IDS[1]
	end

	self.paladinRitesProvider = self.paladinRitesProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = spellIds,
			fallbackName = fallbackName,
			enchantId = enchantIds[1],
			enchantIds = enchantIds,
			beaconOfLightSpellIds = HOLY_PALADIN_BEACON_OF_LIGHT_IDS,
			beaconOfLightDisplaySpellId = HOLY_PALADIN_BEACON_OF_LIGHT_IDS[1],
			beaconOfLightLabel = "Beacon of Light",
			beaconOfFaithSpellIds = HOLY_PALADIN_BEACON_OF_FAITH_IDS,
			beaconOfFaithKnownSpellIds = HOLY_PALADIN_BEACON_OF_FAITH_IDS,
			beaconOfFaithDisplaySpellId = HOLY_PALADIN_BEACON_OF_FAITH_IDS[1],
			beaconOfFaithLabel = "Beacon of Faith",
			hasUnitBuffFunc = paladinRitesHasUnitBuff,
			getSelfStatusFunc = paladinRitesGetSelfStatus,
			activeKey = nil,
		}

	local provider = self.paladinRitesProvider
	provider.spellIds = spellIds
	provider.fallbackName = fallbackName
	provider.enchantIds = enchantIds
	provider.trackRites = trackRites == true
	provider.enchantId = (#enchantIds == 1) and enchantIds[1] or nil
	provider.tracksExternalUnitAuras = holyPaladin == true

	local providerKey = string.format("%s|holy:%d|faith:%d", tostring(nextKey), holyPaladin and 1 or 0, beaconOfFaithKnown and 1 or 0)
	if provider.activeKey ~= providerKey then
		provider.activeKey = providerKey
		resetProviderRuntimeCache(provider)
	end

	setProviderDisplaySpellId(provider, displaySpellId)
	return provider
end

function Reminder:GetRoguePoisonsProvider()
	self.roguePoisonsProvider = self.roguePoisonsProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				315584,
				2823,
				8679,
				381664,
				3408,
				5761,
				381637,
			},
			lethalSpellIds = ROGUE_POISON_LETHAL_IDS,
			lethalKnownSpellIds = ROGUE_POISON_LETHAL_IDS,
			utilitySpellIds = ROGUE_POISON_UTILITY_IDS,
			utilityKnownSpellIds = ROGUE_POISON_UTILITY_IDS,
			lethalDisplaySpellId = 315584,
			utilityDisplaySpellId = 3408,
			fallbackName = "Poisons",
			hasUnitBuffFunc = roguePoisonsHasUnitBuff,
			getSelfStatusFunc = roguePoisonsGetSelfStatus,
		}
	return self.roguePoisonsProvider
end

function Reminder:GetShamanEnhancementProvider()
	self.shamanEnhancementProvider = self.shamanEnhancementProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				319773,
				33757,
				319778,
				318038,
			},
			knownSpellIds = {
				319773,
				33757,
				319778,
				318038,
				974,
				192106,
				52127,
				383010,
				462854,
			},
			windfurySpellIds = SHAMAN_ENHANCEMENT_WINDFURY_IDS,
			windfuryKnownSpellIds = SHAMAN_ENHANCEMENT_WINDFURY_IDS,
			flametongueSpellIds = SHAMAN_ENHANCEMENT_FLAMETONGUE_IDS,
			flametongueKnownSpellIds = SHAMAN_ENHANCEMENT_FLAMETONGUE_IDS,
			shieldSpellIds = Reminder.shamanReminder.shieldBasicIds,
			shieldKnownSpellIds = Reminder.shamanReminder.shieldBasicIds,
			earthShieldSpellIds = Reminder.shamanReminder.shieldEarthIds,
			earthShieldSelfSpellIds = Reminder.shamanReminder.shieldEarthSelfIds,
			earthShieldDisplaySpellId = 974,
			lightningShieldSpellIds = Reminder.shamanReminder.shieldLightningIds,
			lightningShieldDisplaySpellId = 192106,
			waterShieldSpellIds = Reminder.shamanReminder.shieldWaterIds,
			waterShieldDisplaySpellId = 52127,
			elementalOrbitSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			elementalOrbitKnownSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			windfuryDisplaySpellId = 319773,
			flametongueDisplaySpellId = 319778,
			skyfurySpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryKnownSpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryDisplaySpellId = 462854,
			skyfuryLabel = PROVIDER_BY_CLASS.SHAMAN.fallbackName or "Skyfury",
			fallbackName = "Weapon Imbues",
			tracksExternalUnitAuras = true,
			hasUnitBuffFunc = shamanEnhancementImbuesHasUnitBuff,
			getSelfStatusFunc = shamanEnhancementGetSelfStatus,
		}
	return self.shamanEnhancementProvider
end

function Reminder:GetShamanRestorationProvider()
	local earthlivingDisplaySpellId = 382021
	if safeIsPlayerSpell(382024) then
		earthlivingDisplaySpellId = 382024
	elseif safeIsPlayerSpell(382022) then
		earthlivingDisplaySpellId = 382022
	end

	local tidecallerDisplaySpellId = 457481
	if safeIsPlayerSpell(457496) then tidecallerDisplaySpellId = 457496 end

	self.shamanRestorationProvider = self.shamanRestorationProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				382021,
				382022,
				382024,
				457481,
				457496,
			},
			knownSpellIds = {
				382021,
				382022,
				382024,
				457481,
				457496,
				974,
				192106,
				52127,
				383010,
				462854,
			},
			earthlivingSpellIds = SHAMAN_RESTORATION_EARTHLIVING_IDS,
			earthlivingKnownSpellIds = SHAMAN_RESTORATION_EARTHLIVING_IDS,
			earthlivingAuraNames = SHAMAN_RESTORATION_EARTHLIVING_AURA_NAMES,
			earthlivingLabel = "Earthliving Weapon",
			enchantId = 6498,
			earthlivingDisplaySpellId = earthlivingDisplaySpellId,
			tidecallerSpellIds = SHAMAN_RESTORATION_TIDECALLER_IDS,
			tidecallerKnownSpellIds = SHAMAN_RESTORATION_TIDECALLER_IDS,
			tidecallerAuraNames = SHAMAN_RESTORATION_TIDECALLER_AURA_NAMES,
			tidecallerLabel = "Tidecaller's Guard",
			tidecallerDisplaySpellId = tidecallerDisplaySpellId,
			requireShieldForTidecaller = true,
			acceptAnyOffhandEnchantWhenKnown = true,
			shieldSpellIds = Reminder.shamanReminder.shieldBasicIds,
			shieldKnownSpellIds = Reminder.shamanReminder.shieldBasicIds,
			earthShieldSpellIds = Reminder.shamanReminder.shieldEarthIds,
			earthShieldSelfSpellIds = Reminder.shamanReminder.shieldEarthSelfIds,
			earthShieldDisplaySpellId = 974,
			lightningShieldSpellIds = Reminder.shamanReminder.shieldLightningIds,
			lightningShieldDisplaySpellId = 192106,
			waterShieldSpellIds = Reminder.shamanReminder.shieldWaterIds,
			waterShieldDisplaySpellId = 52127,
			elementalOrbitSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			elementalOrbitKnownSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			skyfurySpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryKnownSpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryDisplaySpellId = 462854,
			skyfuryLabel = PROVIDER_BY_CLASS.SHAMAN.fallbackName or "Skyfury",
			fallbackName = "Earthliving Weapon",
			tracksExternalUnitAuras = true,
			hasUnitBuffFunc = shamanRestorationEarthlivingHasUnitBuff,
			getSelfStatusFunc = shamanRestorationGetSelfStatus,
		}

	if self.shamanRestorationProvider.earthlivingDisplaySpellId ~= earthlivingDisplaySpellId or self.shamanRestorationProvider.tidecallerDisplaySpellId ~= tidecallerDisplaySpellId then
		self.shamanRestorationProvider.earthlivingDisplaySpellId = earthlivingDisplaySpellId
		self.shamanRestorationProvider.tidecallerDisplaySpellId = tidecallerDisplaySpellId
		resetProviderRuntimeCache(self.shamanRestorationProvider)
	end

	return self.shamanRestorationProvider
end

function Reminder:GetShamanGeneralProvider()
	self.shamanGeneralProvider = self.shamanGeneralProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				462854,
				974,
				383648,
				192106,
				52127,
			},
			knownSpellIds = {
				462854,
				974,
				192106,
				52127,
				383010,
			},
			shieldSpellIds = Reminder.shamanReminder.shieldBasicIds,
			shieldKnownSpellIds = Reminder.shamanReminder.shieldBasicIds,
			earthShieldSpellIds = Reminder.shamanReminder.shieldEarthIds,
			earthShieldSelfSpellIds = Reminder.shamanReminder.shieldEarthSelfIds,
			earthShieldDisplaySpellId = 974,
			lightningShieldSpellIds = Reminder.shamanReminder.shieldLightningIds,
			lightningShieldDisplaySpellId = 192106,
			waterShieldSpellIds = Reminder.shamanReminder.shieldWaterIds,
			waterShieldDisplaySpellId = 52127,
			elementalOrbitSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			elementalOrbitKnownSpellIds = Reminder.shamanReminder.elementalOrbitIds,
			skyfurySpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryKnownSpellIds = PROVIDER_BY_CLASS.SHAMAN.spellIds,
			skyfuryDisplaySpellId = 462854,
			skyfuryLabel = PROVIDER_BY_CLASS.SHAMAN.fallbackName or "Skyfury",
			fallbackName = PROVIDER_BY_CLASS.SHAMAN.fallbackName or "Skyfury",
			tracksExternalUnitAuras = true,
			hasUnitBuffFunc = Reminder.ShamanGeneralHasUnitBuff,
			getSelfStatusFunc = Reminder.ShamanGeneralGetSelfStatus,
		}
	return self.shamanGeneralProvider
end

function Reminder:GetShamanProvider()
	local specId = self:GetCurrentSpecId()
	if specId == Reminder.shamanReminder.specEnhancement then return self:GetShamanEnhancementProvider() or PROVIDER_BY_CLASS.SHAMAN end
	if specId == Reminder.shamanReminder.specRestoration then return self:GetShamanRestorationProvider() or PROVIDER_BY_CLASS.SHAMAN end
	if specId == Reminder.shamanReminder.specElemental then return self:GetShamanGeneralProvider() or PROVIDER_BY_CLASS.SHAMAN end
	return self:GetShamanGeneralProvider() or PROVIDER_BY_CLASS.SHAMAN
end

function Reminder:GetDruidProvider()
	self.druidRestorationProvider = self.druidRestorationProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = {
				1126,
				474754,
			},
			knownSpellIds = {
				1126,
				474750,
			},
			markSpellIds = DRUID_MARK_OF_THE_WILD_IDS,
			markKnownSpellIds = DRUID_MARK_OF_THE_WILD_IDS,
			markDisplaySpellId = 1126,
			markLabel = PROVIDER_BY_CLASS.DRUID and PROVIDER_BY_CLASS.DRUID.fallbackName or "Mark of the Wild",
			symbioticSpellIds = DRUID_SYMBIOTIC_RELATIONSHIP_SELF_IDS,
			symbioticKnownSpellIds = DRUID_SYMBIOTIC_RELATIONSHIP_KNOWN_IDS,
			symbioticDisplaySpellId = 474754,
			symbioticLabel = "Symbiotic Relationship",
			fallbackName = PROVIDER_BY_CLASS.DRUID and PROVIDER_BY_CLASS.DRUID.fallbackName or "Mark of the Wild",
			tracksExternalUnitAuras = true,
			hasUnitBuffFunc = druidRestorationHasUnitBuff,
			getSelfStatusFunc = druidRestorationGetSelfStatus,
		}

	return self.druidRestorationProvider
end

function Reminder:GetFlaskOnlyProvider()
	self.flaskOnlyProvider = self.flaskOnlyProvider
		or {
			scope = PROVIDER_SCOPE_SELF,
			spellIds = SHARED_FLASK_AURA_IDS,
			fallbackName = "Flask",
			displaySpellId = normalizeSpellId(SHARED_FLASK_AURA_IDS[1]),
			isSupplementalOnly = true,
		}
	return self.flaskOnlyProvider
end

function Reminder:GetFoodOnlyProvider()
	self.foodOnlyProvider = self.foodOnlyProvider or {
		scope = PROVIDER_SCOPE_SELF,
		spellIds = { 1 },
		fallbackName = L["Buff Food Macro"] or "Buff food",
		displaySpellId = 1,
		displayIcon = SHARED_FOOD_AURA_ICON_ID,
		isSupplementalOnly = true,
	}
	return self.foodOnlyProvider
end

function Reminder:GetRuneOnlyProvider()
	self.runeOnlyProvider = self.runeOnlyProvider or {
		scope = PROVIDER_SCOPE_SELF,
		spellIds = Reminder.runeTracking.auraIds,
		fallbackName = L["ClassBuffReminderAugmentRune"] or "Augment Rune",
		displaySpellId = normalizeSpellId(Reminder.runeTracking.auraIds[1]),
		isSupplementalOnly = true,
	}
	return self.runeOnlyProvider
end

function Reminder:GetWeaponBuffOnlyProvider()
	self.weaponBuffOnlyProvider = self.weaponBuffOnlyProvider or {
		scope = PROVIDER_SCOPE_SELF,
		spellIds = { 1 },
		fallbackName = L["ClassBuffReminderWeaponBuff"] or "Weapon buff",
		displaySpellId = 1,
		isSupplementalOnly = true,
	}
	return self.weaponBuffOnlyProvider
end

function Reminder:GetPetOnlyProvider()
	self.petOnlyProvider = self.petOnlyProvider or {
		scope = PROVIDER_SCOPE_SELF,
		spellIds = { 1 },
		fallbackName = L["ClassBuffReminderSectionPets"] or "Pets",
		displaySpellId = 1,
		displayIcon = "Interface\\Icons\\Ability_Hunter_BeastCall",
		isSupplementalOnly = true,
	}
	return self.petOnlyProvider
end

local function finalizeResolvedProvider(provider)
	if not provider then return nil end
	if provider.scope == nil then provider.scope = PROVIDER_SCOPE_GROUP end
	if type(provider.spellIds) ~= "table" or #provider.spellIds <= 0 then return nil end
	if not providerHasKnownSpells(provider) then return nil end
	if not tonumber(provider.stateVersion) or tonumber(provider.stateVersion) <= 0 then provider.stateVersion = 1 end

	if not provider.spellSet then
		provider.spellSet = {}
		for i = 1, #provider.spellIds do
			local sid = normalizeSpellId(provider.spellIds[i])
			if sid then provider.spellSet[sid] = true end
		end
	end
	if not provider.displaySpellId then provider.displaySpellId = normalizeSpellId(provider.spellIds[1]) or provider.spellIds[1] end

	return provider
end

function Reminder:RefreshProviderCache(force)
	if force ~= true and self.runtimeProviderValid == true then return self.activeProvider, self.hasProviderCached == true end

	local classToken = self:GetClassToken()
	local provider
	if classToken == "PALADIN" then
		provider = self:GetPaladinRitesProvider()
	elseif classToken == "ROGUE" then
		provider = self:GetRoguePoisonsProvider()
	elseif classToken == "EVOKER" then
		provider = self:GetEvokerSupportProvider()
	elseif classToken == "SHAMAN" then
		provider = self:GetShamanProvider()
	elseif classToken == "DRUID" then
		provider = self:GetDruidProvider()
	else
		provider = classToken and PROVIDER_BY_CLASS[classToken] or nil
	end

	provider = finalizeResolvedProvider(provider)
	self.activeProvider = provider
	self.hasProviderCached = provider ~= nil
	self.runtimeProviderValid = true
	return provider, self.hasProviderCached
end

function Reminder:GetProvider()
	local provider = self:RefreshProviderCache(false)
	return provider
end

function Reminder:GetProviderName(provider)
	if not provider then return L["Class Buff Reminder"] or "Class Buff Reminder" end
	if provider.cachedName and provider.cachedName ~= "" and provider.cachedName ~= provider.fallbackName then return provider.cachedName end
	if provider._presentationAttempted ~= true then resolveProviderPresentation(provider) end
	if provider.cachedName and provider.cachedName ~= "" then return provider.cachedName end
	local name = safeGetSpellName(provider.displaySpellId) or provider.fallbackName or (L["Class Buff Reminder"] or "Class Buff Reminder")
	provider.cachedName = name
	return name
end

function Reminder:GetProviderIcon(provider)
	if not provider then return ICON_MISSING end
	if provider.cachedIcon and provider.cachedIcon ~= "" and provider.cachedIcon ~= ICON_MISSING then return provider.cachedIcon end
	if provider._presentationAttempted ~= true then resolveProviderPresentation(provider) end
	if provider.cachedIcon and provider.cachedIcon ~= "" and provider.cachedIcon ~= ICON_MISSING then return provider.cachedIcon end
	self:RequestProviderPresentationRefresh(provider)
	return provider.cachedIcon or ICON_MISSING
end

function Reminder.RunPendingUpdateTimer()
	Reminder.updateTimer = nil
	Reminder.updatePending = false
	Reminder.updateDelay = nil
	Reminder:UpdateDisplay()
end

function Reminder.RunInitialSoundSyncTimer()
	Reminder.initialSoundSyncTimer = nil
	Reminder.initialSoundSyncPending = false
	if not Reminder:ShouldRegisterRuntimeEvents() then return end

	Reminder.initialSoundSyncDone = true
	Reminder:NormalizeMissingSoundSelection()
end

function Reminder.RunDeferredAuraResyncTimer()
	Reminder.deferredAuraResyncTimer = nil
	if not Reminder:ShouldRegisterRuntimeEvents() then return end

	Reminder:MarkAuraStatesDirty()
	Reminder:RequestUpdate(false, Reminder.ROSTER_UPDATE_DELAY, true)
end

function Reminder:RequestProviderPresentationRefresh(provider)
	if type(provider) ~= "table" then return end
	if provider.cachedIcon and provider.cachedIcon ~= "" and provider.cachedIcon ~= ICON_MISSING then
		provider.presentationRetryCount = 0
		return
	end
	if not (C_Timer and C_Timer.After) then return end
	if provider.presentationRetryPending then return end
	local retries = tonumber(provider.presentationRetryCount) or 0
	if retries >= 8 then return end

	provider.presentationRetryPending = true
	C_Timer.After(0.25, function()
		provider.presentationRetryPending = false
		provider.presentationRetryCount = (tonumber(provider.presentationRetryCount) or 0) + 1
		resolveProviderPresentation(provider, true)
		if provider.cachedIcon and provider.cachedIcon ~= "" and provider.cachedIcon ~= ICON_MISSING then provider.presentationRetryCount = 0 end
		Reminder:RequestUpdate(true)
	end)
end

function Reminder:InvalidateProviderAvailabilityCache()
	self:ClearPendingAuraUpdates()
	self.activeProvider = nil
	self.hasProviderCached = nil
	self.runtimeProviderValid = nil
	self:InvalidateSelfProviderStatus()
	self:InvalidateGroupMissingState()
	self:InvalidateGroupBuffStateCaches()
end

function Reminder:GetGrowthDirection() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) end

function Reminder:GetGlowStyle() return normalizeGlowStyle(getValue(DB_GLOW_STYLE, defaults.glowStyle)) end

function Reminder:GetGlowInset() return normalizeGlowInset(getValue(DB_GLOW_INSET, defaults.glowInset)) end
function Reminder:GetGlowColor() return normalizeColor(getValue(DB_GLOW_COLOR, defaults.glowColor), defaults.glowColor) end
function Reminder:GetGrowthFromCenter() return getValue(DB_GROWTH_FROM_CENTER, defaults.growthFromCenter) == true end
function Reminder:IsBorderEnabled() return getValue(DB_BORDER_ENABLED, defaults.borderEnabled) == true end
function Reminder:GetBorderTextureKey() return normalizeBorderTexture(getValue(DB_BORDER_TEXTURE, defaults.borderTexture)) end
function Reminder:GetBorderSize() return normalizeBorderSize(getValue(DB_BORDER_SIZE, defaults.borderSize)) end
function Reminder:GetBorderOffset() return normalizeBorderOffset(getValue(DB_BORDER_OFFSET, defaults.borderOffset)) end
function Reminder:GetBorderColor() return normalizeColor(getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor) end

function Reminder:GetIconCountTextStyle()
	local size = clamp(getValue(DB_XY_TEXT_SIZE, defaults.xyTextSize), 8, 64, defaults.xyTextSize)
	local outline = normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline))
	local r, g, b, a = normalizeColor(getValue(DB_XY_TEXT_COLOR, defaults.xyTextColor), defaults.xyTextColor)
	local offsetX = clamp(getValue(DB_XY_TEXT_OFFSET_X, defaults.xyTextOffsetX), -60, 60, defaults.xyTextOffsetX)
	local offsetY = clamp(getValue(DB_XY_TEXT_OFFSET_Y, defaults.xyTextOffsetY), -60, 60, defaults.xyTextOffsetY)
	return size, outline, r, g, b, a, offsetX, offsetY
end

function Reminder:BuildMissingSoundOptions()
	local version = (addon.functions and addon.functions.GetLSMMediaVersion and addon.functions.GetLSMMediaVersion("sound")) or 0
	if self.missingSoundCacheVersion == version and self.missingSoundKeys and self.missingSoundMap and self.missingSoundPathToKey then
		return self.missingSoundKeys, self.missingSoundMap, self.missingSoundPathToKey
	end

	local keys = {}
	local map = {}
	local pathToKey = {}

	local names = (addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("sound")) or nil
	local hash = (addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("sound")) or nil
	if type(names) == "table" and type(hash) == "table" then
		for i = 1, #names do
			local name = names[i]
			local path = hash[name]
			if type(name) == "string" and name ~= "" and type(path) == "string" and path ~= "" then
				keys[#keys + 1] = name
				map[name] = path
			end
		end
	end
	for i = 1, #keys do
		local name = keys[i]
		local path = map[name]
		if type(path) == "string" and path ~= "" and pathToKey[path] == nil then pathToKey[path] = name end
	end
	self.missingSoundCacheVersion = version
	self.missingSoundKeys = keys
	self.missingSoundMap = map
	self.missingSoundPathToKey = pathToKey
	return keys, map, pathToKey
end

function Reminder:GetMissingSoundOptions() return self:BuildMissingSoundOptions() end

function Reminder:ResolveMissingSound()
	local rawKey = getValue(DB_MISSING_SOUND, defaults.missingSound)
	if type(rawKey) ~= "string" then rawKey = "" end

	local keys, map, pathToKey = self:GetMissingSoundOptions()
	local resolvedKey = rawKey
	if resolvedKey ~= "" and type(pathToKey) == "table" and pathToKey[resolvedKey] and map[pathToKey[resolvedKey]] then resolvedKey = pathToKey[resolvedKey] end

	local soundFile
	if resolvedKey ~= "" and type(map) == "table" then soundFile = map[resolvedKey] end

	return rawKey, resolvedKey, soundFile, #keys
end

function Reminder:NormalizeMissingSoundSelection()
	if not addon.db then return end

	local _, map, pathToKey = self:GetMissingSoundOptions()
	local current = addon.db[DB_MISSING_SOUND]
	if type(current) ~= "string" then current = "" end

	local normalized = current
	if normalized ~= "" and type(pathToKey) == "table" and pathToKey[normalized] and type(map) == "table" and map[pathToKey[normalized]] then normalized = pathToKey[normalized] end

	if normalized ~= current then addon.db[DB_MISSING_SOUND] = normalized end
end

function Reminder:ScheduleInitialSoundSync()
	if self.initialSoundSyncDone == true or self.initialSoundSyncPending == true then return end
	if not (C_Timer and C_Timer.After) then return end

	self.initialSoundSyncPending = true
	self.initialSoundSyncTimer = C_Timer.NewTimer(1, Reminder.RunInitialSoundSyncTimer)
end

function Reminder:ScheduleDeferredAuraResync(delay)
	if not (C_Timer and C_Timer.After) then return end

	if self.deferredAuraResyncTimer then self.deferredAuraResyncTimer:Cancel() end
	self.deferredAuraResyncTimer = C_Timer.NewTimer(tonumber(delay) or 0.35, Reminder.RunDeferredAuraResyncTimer)
end

function Reminder:GetMissingSoundValue()
	local _, resolvedKey = self:ResolveMissingSound()
	if type(resolvedKey) ~= "string" then return "" end
	return resolvedKey
end

function Reminder:GetMissingSoundFile()
	local _, _, soundFile = self:ResolveMissingSound()
	if type(soundFile) ~= "string" or soundFile == "" then return nil end
	return soundFile
end

function Reminder:PlayMissingSound(force)
	if not force and getValue(DB_SOUND_ON_MISSING, defaults.soundOnMissing) ~= true then return end

	local _, _, soundFile = self:ResolveMissingSound()
	if soundFile and PlaySoundFile then PlaySoundFile(soundFile, "Master") end
end

function Reminder:UpdateMissingStateAndSound(missing)
	local isMissing = tonumber(missing) and tonumber(missing) > 0 or false
	local wasMissing = self.missingActive == true
	if isMissing and not wasMissing then
		if self.suppressNextMissingSound == true then
			self.suppressNextMissingSound = false
		else
			self:PlayMissingSound()
		end
	end
	self.missingActive = isMissing
end

function Reminder:GetUnitAuraState(unit)
	if type(unit) ~= "string" or unit == "" then return nil end
	self.unitAuraStates = self.unitAuraStates or {}
	local state = self.unitAuraStates[unit]
	if not state then
		state = {
			trackedByInstance = {},
			expirationByInstance = {},
			trackedCount = 0,
			hasBuff = false,
			hasUsableBuff = false,
			nextExpirationWarningAt = nil,
			initialized = false,
			unitIdentity = nil,
			providerRef = nil,
			providerVersion = nil,
		}
		self.unitAuraStates[unit] = state
	end
	if type(state.trackedByInstance) ~= "table" then state.trackedByInstance = {} end
	if type(state.expirationByInstance) ~= "table" then state.expirationByInstance = {} end
	if type(state.trackedCount) ~= "number" then state.trackedCount = 0 end
	return state
end

function Reminder:ResetUnitAuraState(state)
	if type(state) ~= "table" then return end
	self:ClearTrackedAuraState(state)
	state.unitIdentity = nil
end

function Reminder:ClearTrackedAuraState(state)
	if type(state) ~= "table" then return end
	if type(state.trackedByInstance) == "table" then wipeTable(state.trackedByInstance) end
	if type(state.expirationByInstance) == "table" then wipeTable(state.expirationByInstance) end
	state.trackedCount = 0
	state.hasBuff = false
	state.hasUsableBuff = false
	state.nextExpirationWarningAt = nil
	state.initialized = false
end

function Reminder:ClearPendingAuraUpdates() self.pendingAuraUpdates = nil end

function Reminder.IsFullAuraUpdate(updateInfo)
	if not updateInfo or (issecretvalue and issecretvalue(updateInfo)) then return true end
	local isFullUpdate = updateInfo.isFullUpdate
	if issecretvalue and issecretvalue(isFullUpdate) then return true end
	return isFullUpdate == true
end

function Reminder:GetPendingAuraUpdate(unit)
	if type(unit) ~= "string" or unit == "" then return nil end
	local pending = self.pendingAuraUpdates
	if type(pending) ~= "table" then
		pending = {}
		self.pendingAuraUpdates = pending
	end

	local entry = pending[unit]
	if type(entry) ~= "table" then
		entry = {}
		pending[unit] = entry
	end
	return entry
end

function Reminder:QueuePendingAuraReset(unit)
	local entry = self:GetPendingAuraUpdate(unit)
	if not entry then return end
	entry.reset = true
	entry.fullRefresh = false
	entry.updateInfo = nil
	entry.addedAurasById = nil
	entry.updatedAuraInstanceIDsById = nil
	entry.removedAuraInstanceIDsById = nil
end

function Reminder.GetPendingAuraMap(entry, key)
	local map = entry[key]
	if type(map) ~= "table" then
		map = {}
		entry[key] = map
	end
	return map
end

function Reminder.ClearPendingAuraDeltaMaps(entry)
	entry.addedAurasById = nil
	entry.updatedAuraInstanceIDsById = nil
	entry.removedAuraInstanceIDsById = nil
end

function Reminder.BuildPendingAuraUpdateInfo(entry)
	if type(entry) ~= "table" then return nil end
	local info = nil
	local addedMap = entry.addedAurasById
	if type(addedMap) == "table" then
		local added
		for _, aura in pairs(addedMap) do
			if aura then
				added = added or {}
				added[#added + 1] = aura
			end
		end
		if added then
			info = info or {}
			info.addedAuras = added
		end
	end
	local updatedMap = entry.updatedAuraInstanceIDsById
	if type(updatedMap) == "table" then
		local updated
		for auraId in pairs(updatedMap) do
			updated = updated or {}
			updated[#updated + 1] = auraId
		end
		if updated then
			info = info or {}
			info.updatedAuraInstanceIDs = updated
		end
	end
	local removedMap = entry.removedAuraInstanceIDsById
	if type(removedMap) == "table" then
		local removed
		for auraId in pairs(removedMap) do
			removed = removed or {}
			removed[#removed + 1] = auraId
		end
		if removed then
			info = info or {}
			info.removedAuraInstanceIDs = removed
		end
	end
	return info
end

function Reminder:QueuePendingAuraDelta(unit, updateInfo)
	local entry = self:GetPendingAuraUpdate(unit)
	if not entry then return end

	entry.reset = false
	if entry.fullRefresh == true then return end
	if Reminder.IsFullAuraUpdate(updateInfo) then
		entry.fullRefresh = true
		entry.updateInfo = nil
		Reminder.ClearPendingAuraDeltaMaps(entry)
		return
	end

	local unitStates = self.unitAuraStates
	local state = type(unitStates) == "table" and unitStates[unit] or nil
	local trackedByInstance = state and state.trackedByInstance
	local removed = updateInfo.removedAuraInstanceIDs
	if type(removed) == "table" then
		for i = 1, #removed do
			local auraId = normalizeAuraInstanceId(removed[i])
			if auraId then
				local addedMap = entry.addedAurasById
				local updatedMap = entry.updatedAuraInstanceIDsById
				if type(addedMap) == "table" then addedMap[auraId] = nil end
				if type(updatedMap) == "table" then updatedMap[auraId] = nil end
				if type(trackedByInstance) == "table" and trackedByInstance[auraId] ~= nil then Reminder.GetPendingAuraMap(entry, "removedAuraInstanceIDsById")[auraId] = true end
			end
		end
	end

	local added = updateInfo.addedAuras
	if type(added) == "table" then
		for i = 1, #added do
			local aura = added[i]
			local auraId = aura and normalizeAuraInstanceId(aura.auraInstanceID)
			if auraId and Reminder.IsRelevantHelpfulPlayerAura(aura) then
				local removedMap = entry.removedAuraInstanceIDsById
				local updatedMap = entry.updatedAuraInstanceIDsById
				if type(removedMap) == "table" then removedMap[auraId] = nil end
				if type(updatedMap) == "table" then updatedMap[auraId] = nil end
				Reminder.GetPendingAuraMap(entry, "addedAurasById")[auraId] = aura
			end
		end
	end

	local updated = updateInfo.updatedAuraInstanceIDs
	if type(updated) == "table" then
		for i = 1, #updated do
			local auraId = normalizeAuraInstanceId(updated[i])
			if auraId and type(trackedByInstance) == "table" and trackedByInstance[auraId] ~= nil and not (type(entry.addedAurasById) == "table" and entry.addedAurasById[auraId]) then Reminder.GetPendingAuraMap(entry, "updatedAuraInstanceIDsById")[auraId] = true end
		end
	end
end

function Reminder:FlushPendingAuraUpdates()
	local pending = self.pendingAuraUpdates
	if type(pending) ~= "table" or not next(pending) then return end
	self.pendingAuraUpdates = nil

	local provider = self:GetProvider()
	if not (provider and provider.scope == PROVIDER_SCOPE_GROUP and self:ShouldEvaluateGroupResponsibilities(provider) == true) then
		for unit, entry in pairs(pending) do
			if type(entry) == "table" and entry.reset == true then
				local state = self:GetUnitAuraState(unit)
				if state then self:ResetUnitAuraState(state) end
			end
		end
		return
	end

	local dirtyUnits
	local canRefreshGroupState = self:IsGroupMissingStateValid(provider, self.groupMissingState)
	for unit, entry in pairs(pending) do
		if type(entry) == "table" then
			local touched = false
			if entry.reset == true then
				local state = self:GetUnitAuraState(unit)
				if state then self:ResetUnitAuraState(state) end
				touched = true
			elseif entry.fullRefresh == true then
				self:FullRefreshUnitAuraState(unit, provider)
				touched = true
			else
				local mergedUpdateInfo = entry.updateInfo or Reminder.BuildPendingAuraUpdateInfo(entry)
				if mergedUpdateInfo then
					self:ApplyDeltaToUnitAuraState(unit, mergedUpdateInfo, provider)
					touched = true
				end
			end

			if touched == true and canRefreshGroupState == true then dirtyUnits = self:CollectGroupStateUnitsForUnit(dirtyUnits, unit) end
		end
	end

	if type(dirtyUnits) == "table" then
		for unit in pairs(dirtyUnits) do
			self:RefreshGroupMissingStateUnit(provider, unit)
		end
	end
end

function Reminder:PrepareUnitAuraState(unit, provider)
	local state = self:GetUnitAuraState(unit)
	if not state then return nil end
	local unitIdentity = getUnitIdentity(unit)

	-- Preserve hot unit caches across roster churn and only invalidate tokens that now point to a different unit.
	if state.unitIdentity ~= unitIdentity then
		self:ResetUnitAuraState(state)
		state.unitIdentity = unitIdentity
	end

	if type(provider) ~= "table" then return state end

	local providerVersion = getProviderStateVersion(provider)
	if state.providerRef ~= provider or state.providerVersion ~= providerVersion then
		self:ResetUnitAuraState(state)
		state.unitIdentity = unitIdentity
		state.providerRef = provider
		state.providerVersion = providerVersion
	end
	return state
end

function Reminder:InvalidateGroupMissingState() self.groupMissingState = nil end

function Reminder:InvalidateGroupBuffStateCaches()
	self.groupBuffStateCaches = nil
	self.groupBuffAggregateSpellSetSource = nil
	self.groupBuffAggregateSpellSetDirty = true
	self.groupBuffAggregateSpellSetHasAny = false
end

function Reminder:MarkAuraStatesDirty()
	self:ClearPendingAuraUpdates()
	self:InvalidatePlayerAuraPresenceSnapshot()
	if type(self.unitAuraStates) == "table" then
		for _, state in pairs(self.unitAuraStates) do
			if type(state) == "table" then state.initialized = false end
		end
	end
	self:InvalidateGroupMissingState()
	self:InvalidateGroupBuffStateCaches()
end

function Reminder:InvalidateAuraStates()
	self:ClearPendingAuraUpdates()
	self:InvalidatePlayerAuraPresenceSnapshot()
	self.unitAuraStates = {}
	self:InvalidateGroupMissingState()
	self:InvalidateGroupBuffStateCaches()
end

function Reminder:GetTrackableProviderAuraData(aura, provider)
	if not aura or (issecretvalue and issecretvalue(aura)) then return nil end
	if not (provider and provider.spellSet) then return nil end
	if not Reminder.IsRelevantHelpfulPlayerAura(aura) then return nil end

	local auraId = normalizeAuraInstanceId(aura.auraInstanceID)
	if not auraId then return nil end

	local spellId = normalizeSpellId(aura.spellId)
	if spellId and provider.spellSet[spellId] then return auraId, spellId end

	if type(provider.spellNameSet) ~= "table" or provider.spellNameSetReady ~= true then refreshProviderSpellNameSet(provider) end
	local auraName = aura.name
	if issecretvalue and issecretvalue(auraName) then auraName = nil end
	if type(auraName) == "string" and auraName ~= "" and provider.spellNameSet and provider.spellNameSet[auraName] then return auraId, spellId end

	return nil
end

function Reminder:RecomputeUsableAuraState(state)
	if type(state) ~= "table" then return end
	state.hasBuff = (tonumber(state.trackedCount) or 0) > 0
	local thresholdSeconds = self:GetExpirationWarningSeconds()
	if thresholdSeconds <= 0 then
		state.hasUsableBuff = state.hasBuff
		state.nextExpirationWarningAt = nil
		return
	end
	local expirationByInstance = state.expirationByInstance
	if type(expirationByInstance) ~= "table" then
		state.hasUsableBuff = state.hasBuff
		state.nextExpirationWarningAt = nil
		return
	end
	local now = nowSeconds()
	local usable = false
	local nextAt
	for _, expirationTime in pairs(expirationByInstance) do
		if self:IsExpirationTimeUsable(expirationTime, thresholdSeconds, now) then
			usable = true
			if expirationTime and expirationTime ~= math.huge then
				local warningAt = expirationTime - thresholdSeconds
				if warningAt > now and (not nextAt or warningAt < nextAt) then nextAt = warningAt end
			end
		end
	end
	state.hasUsableBuff = usable
	state.nextExpirationWarningAt = nextAt
	if nextAt then self:QueueExpirationWarningAt(nextAt) end
end

function Reminder:AddProviderAuraToState(state, aura, provider)
	if type(state) ~= "table" then return false end
	local auraId, spellId = self:GetTrackableProviderAuraData(aura, provider)
	if not auraId then return false end

	if state.trackedByInstance[auraId] == nil then
		state.trackedByInstance[auraId] = spellId
		state.trackedCount = (state.trackedCount or 0) + 1
	else
		state.trackedByInstance[auraId] = spellId
	end
	state.expirationByInstance[auraId] = Reminder.GetAuraExpirationTime(aura)
	self:RecomputeUsableAuraState(state)
	return true
end

function Reminder:RemoveProviderAuraFromState(state, auraId)
	if type(state) ~= "table" then return false end
	auraId = normalizeAuraInstanceId(auraId)
	if not auraId or state.trackedByInstance[auraId] == nil then return false end

	state.trackedByInstance[auraId] = nil
	if type(state.expirationByInstance) == "table" then state.expirationByInstance[auraId] = nil end
	state.trackedCount = (state.trackedCount or 0) - 1
	if state.trackedCount < 0 then state.trackedCount = 0 end
	self:RecomputeUsableAuraState(state)
	return true
end

function Reminder:FullRefreshUnitAuraState(unit, provider)
	local state = self:PrepareUnitAuraState(unit, provider)
	if not state then return nil end
	-- Keep unit identity intact so a fresh full scan does not immediately invalidate itself.
	self:ClearTrackedAuraState(state)
	if isAIFollowerUnit(unit) then
		state.initialized = true
		return state
	end

	if not (unit and UnitExists and UnitExists(unit) and provider and provider.spellSet) then
		state.initialized = true
		return state
	end
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then
		state.initialized = true
		return state
	end

	local continuationToken
	for _ = 1, AURA_SLOT_SCAN_GUARD do
		local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer(unit, continuationToken)
		for i = 2, slotCount do
			local slot = slots[i]
			if not (issecretvalue and issecretvalue(slot)) then
				local aura = C_UnitAuras.GetAuraDataBySlot(unit, slot)
				if aura then self:AddProviderAuraToState(state, aura, provider) end
			end
		end

		if nextToken == nil then break end
		continuationToken = nextToken
	end

	self:RecomputeUsableAuraState(state)
	state.initialized = true
	return state
end

function Reminder:ApplyDeltaToUnitAuraState(unit, updateInfo, provider)
	local state = self:PrepareUnitAuraState(unit, provider)
	if not state then return nil end
	if isAIFollowerUnit(unit) then
		self:ResetUnitAuraState(state)
		state.initialized = true
		return state
	end

	if not (provider and provider.spellSet) then
		self:ResetUnitAuraState(state)
		state.initialized = true
		return state
	end
	if not UnitExists or not UnitExists(unit) then
		self:ResetUnitAuraState(state)
		return state
	end

	if not updateInfo or (issecretvalue and issecretvalue(updateInfo)) then return self:FullRefreshUnitAuraState(unit, provider) end
	local isFullUpdate = updateInfo.isFullUpdate
	if issecretvalue and issecretvalue(isFullUpdate) then isFullUpdate = true end
	if isFullUpdate or not state.initialized then return self:FullRefreshUnitAuraState(unit, provider) end

	local removed = updateInfo.removedAuraInstanceIDs
	if type(removed) == "table" then
		for i = 1, #removed do
			local auraId = normalizeAuraInstanceId(removed[i])
			if auraId and state.trackedByInstance[auraId] ~= nil then self:RemoveProviderAuraFromState(state, auraId) end
		end
	end

	local added = updateInfo.addedAuras
	if type(added) == "table" then
		for i = 1, #added do
			self:AddProviderAuraToState(state, added[i], provider)
		end
	end

	local updated = updateInfo.updatedAuraInstanceIDs
	if type(updated) == "table" and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
		for i = 1, #updated do
			local auraId = normalizeAuraInstanceId(updated[i])
			if auraId and state.trackedByInstance[auraId] ~= nil then
				local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraId)
				if aura then
					local trackedAuraId = self:GetTrackableProviderAuraData(aura, provider)
					if trackedAuraId == auraId then
						state.expirationByInstance[auraId] = Reminder.GetAuraExpirationTime(aura)
						self:RecomputeUsableAuraState(state)
					else
						self:RemoveProviderAuraFromState(state, auraId)
					end
				else
					self:RemoveProviderAuraFromState(state, auraId)
				end
			end
		end
	end

	self:RecomputeUsableAuraState(state)
	state.initialized = true
	return state
end

function Reminder:IsGroupMissingStateValid(provider, state)
	if type(provider) ~= "table" or provider.scope == PROVIDER_SCOPE_SELF then return false end
	if type(state) ~= "table" then return false end
	if state.providerRef ~= provider then return false end
	if state.providerVersion ~= getProviderStateVersion(provider) then return false end
	return state.rosterVersion == (tonumber(self.rosterUnitsVersion) or 0)
end

function Reminder:GetGroupUnitMissingStatus(provider, unit)
	if isAIFollowerUnit(unit) then return GROUP_UNIT_STATUS_INELIGIBLE end
	if not (UnitExists and UnitExists(unit) and UnitIsConnected and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)) then return GROUP_UNIT_STATUS_INELIGIBLE end
	if self:UnitHasProviderBuff(unit, provider) then return GROUP_UNIT_STATUS_PRESENT end
	if not Reminder.CanActOnMissingGroupBuffUnit(unit) then return GROUP_UNIT_STATUS_INELIGIBLE end
	return GROUP_UNIT_STATUS_MISSING
end

function Reminder:ApplyGroupUnitMissingStatus(state, unit, nextStatus)
	if type(state) ~= "table" or type(unit) ~= "string" or unit == "" then return end
	state.unitStatus = state.unitStatus or {}
	local previous = state.unitStatus[unit]
	if previous == nextStatus then return end

	if previous == GROUP_UNIT_STATUS_PRESENT or previous == GROUP_UNIT_STATUS_MISSING then state.total = math.max(0, (tonumber(state.total) or 0) - 1) end
	if previous == GROUP_UNIT_STATUS_MISSING then state.missing = math.max(0, (tonumber(state.missing) or 0) - 1) end

	if nextStatus == GROUP_UNIT_STATUS_PRESENT or nextStatus == GROUP_UNIT_STATUS_MISSING then state.total = (tonumber(state.total) or 0) + 1 end
	if nextStatus == GROUP_UNIT_STATUS_MISSING then state.missing = (tonumber(state.missing) or 0) + 1 end

	state.unitStatus[unit] = nextStatus
end

function Reminder:RebuildGroupMissingState(provider)
	if type(provider) ~= "table" or provider.scope == PROVIDER_SCOPE_SELF then
		self.groupMissingState = nil
		return nil
	end

	local state = self.groupMissingState or {}
	state.providerRef = provider
	state.providerVersion = getProviderStateVersion(provider)
	state.rosterVersion = tonumber(self.rosterUnitsVersion) or 0
	state.total = 0
	state.missing = 0
	state.unitStatus = state.unitStatus or {}
	wipeTable(state.unitStatus)

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		self:ApplyGroupUnitMissingStatus(state, unit, self:GetGroupUnitMissingStatus(provider, unit))
	end

	self.groupMissingState = state
	return state
end

function Reminder:GetGroupMissingState(provider)
	local state = self.groupMissingState
	if self:IsGroupMissingStateValid(provider, state) then return state end
	return self:RebuildGroupMissingState(provider)
end

function Reminder:GetGroupBuffStateCache(spellIds, includeAIFollowers)
	if type(spellIds) ~= "table" then return nil end

	local meta = rawget(spellIds, "_eqolGroupBuffStateMeta")
	if type(meta) ~= "table" then
		meta = {
			normalizedIds = {},
			spellSet = {},
			keyBase = "",
		}
		for i = 1, #spellIds do
			local sid = normalizeSpellId(spellIds[i])
			if sid and meta.spellSet[sid] ~= true then
				meta.spellSet[sid] = true
				meta.normalizedIds[#meta.normalizedIds + 1] = sid
			end
		end
		if #meta.normalizedIds > 0 then
			meta.keyBase = table.concat(meta.normalizedIds, ",")
		end
		spellIds._eqolGroupBuffStateMeta = meta
	end

	if #meta.normalizedIds <= 0 then return nil end

	self.groupBuffStateCaches = self.groupBuffStateCaches or {}
	local key = meta.keyBase .. "|ai:" .. (includeAIFollowers == true and "1" or "0")
	local cache = self.groupBuffStateCaches[key]
	if type(cache) ~= "table" then
		cache = {
			key = key,
			spellIds = meta.normalizedIds,
			spellSet = meta.spellSet,
			includeAIFollowers = includeAIFollowers == true,
			rosterVersion = nil,
			total = 0,
			missing = 0,
			unitStatus = {},
			unitStates = {},
		}
		self.groupBuffStateCaches[key] = cache
		self.groupBuffAggregateSpellSetDirty = true
	else
		cache.includeAIFollowers = includeAIFollowers == true
	end

	return cache
end

function Reminder:GetGroupBuffAggregateSpellSet()
	local caches = self.groupBuffStateCaches
	if type(caches) ~= "table" then return nil end

	local aggregate = self.groupBuffAggregateSpellSet
	if type(aggregate) ~= "table" then
		aggregate = {}
		self.groupBuffAggregateSpellSet = aggregate
	end

	if self.groupBuffAggregateSpellSetSource == caches and self.groupBuffAggregateSpellSetDirty ~= true then
		return self.groupBuffAggregateSpellSetHasAny == true and aggregate or nil
	end

	wipeTable(aggregate)
	local hasAny = false
	for _, cache in pairs(caches) do
		if type(cache) == "table" and type(cache.spellSet) == "table" then
			for spellId in pairs(cache.spellSet) do
				aggregate[spellId] = true
				hasAny = true
			end
		end
	end

	self.groupBuffAggregateSpellSetSource = caches
	self.groupBuffAggregateSpellSetDirty = false
	self.groupBuffAggregateSpellSetHasAny = hasAny
	return hasAny and aggregate or nil
end

function Reminder:GetGroupBuffUnitState(cache, unit)
	if type(cache) ~= "table" or type(unit) ~= "string" or unit == "" then return nil end
	cache.unitStates = cache.unitStates or {}
	local state = cache.unitStates[unit]
	if type(state) ~= "table" then
		state = {
			trackedByInstance = {},
			expirationByInstance = {},
			trackedCount = 0,
			hasBuff = false,
			hasUsableBuff = false,
			nextExpirationWarningAt = nil,
			initialized = false,
			unitIdentity = nil,
		}
		cache.unitStates[unit] = state
	end
	if type(state.trackedByInstance) ~= "table" then state.trackedByInstance = {} end
	if type(state.expirationByInstance) ~= "table" then state.expirationByInstance = {} end
	if type(state.trackedCount) ~= "number" then state.trackedCount = 0 end
	return state
end

function Reminder:ClearGroupBuffUnitState(state)
	if type(state) ~= "table" then return end
	if type(state.trackedByInstance) == "table" then wipeTable(state.trackedByInstance) end
	if type(state.expirationByInstance) == "table" then wipeTable(state.expirationByInstance) end
	state.trackedCount = 0
	state.hasBuff = false
	state.hasUsableBuff = false
	state.nextExpirationWarningAt = nil
	state.initialized = false
end

function Reminder:ResetGroupBuffUnitState(state)
	if type(state) ~= "table" then return end
	self:ClearGroupBuffUnitState(state)
	state.unitIdentity = nil
end

function Reminder:PrepareGroupBuffUnitState(cache, unit)
	local state = self:GetGroupBuffUnitState(cache, unit)
	if not state then return nil end

	local unitIdentity = getUnitIdentity(unit)
	if state.unitIdentity ~= unitIdentity then
		self:ResetGroupBuffUnitState(state)
		state.unitIdentity = unitIdentity
	end

	return state
end

function Reminder:GetTrackableGroupBuffAuraData(aura, cache)
	if not aura or (issecretvalue and issecretvalue(aura)) then return nil end
	if type(cache) ~= "table" or type(cache.spellSet) ~= "table" then return nil end
	if not Reminder.IsRelevantHelpfulPlayerAura(aura) then return nil end

	local auraId = normalizeAuraInstanceId(aura.auraInstanceID)
	if not auraId then return nil end

	local spellId = normalizeSpellId(aura.spellId)
	if not spellId or cache.spellSet[spellId] ~= true then return nil end

	return auraId, spellId
end

function Reminder:AddGroupBuffAuraToState(state, aura, cache)
	if type(state) ~= "table" then return false end
	local auraId, spellId = self:GetTrackableGroupBuffAuraData(aura, cache)
	if not auraId then return false end

	if state.trackedByInstance[auraId] == nil then
		state.trackedByInstance[auraId] = spellId
		state.trackedCount = (state.trackedCount or 0) + 1
	else
		state.trackedByInstance[auraId] = spellId
	end
	state.expirationByInstance[auraId] = Reminder.GetAuraExpirationTime(aura)
	self:RecomputeUsableAuraState(state)
	return true
end

function Reminder:RemoveGroupBuffAuraFromState(state, auraId)
	if type(state) ~= "table" then return false end
	auraId = normalizeAuraInstanceId(auraId)
	if not auraId or state.trackedByInstance[auraId] == nil then return false end

	state.trackedByInstance[auraId] = nil
	if type(state.expirationByInstance) == "table" then state.expirationByInstance[auraId] = nil end
	state.trackedCount = (state.trackedCount or 0) - 1
	if state.trackedCount < 0 then state.trackedCount = 0 end
	self:RecomputeUsableAuraState(state)
	return true
end

function Reminder:FullRefreshGroupBuffUnitState(cache, unit)
	local state = self:PrepareGroupBuffUnitState(cache, unit)
	if not state then return nil end
	self:ClearGroupBuffUnitState(state)

	if isAIFollowerUnit(unit) then
		state.initialized = true
		return state
	end
	if not (unit and UnitExists and UnitExists(unit)) then
		state.initialized = true
		return state
	end
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then
		state.initialized = true
		return state
	end

	local continuationToken
	for _ = 1, AURA_SLOT_SCAN_GUARD do
		local slots, slotCount, nextToken = getHelpfulAuraSlotBuffer(unit, continuationToken)
		for i = 2, slotCount do
			local slot = slots[i]
			if not (issecretvalue and issecretvalue(slot)) then
				local aura = C_UnitAuras.GetAuraDataBySlot(unit, slot)
				if aura then self:AddGroupBuffAuraToState(state, aura, cache) end
			end
		end

		if nextToken == nil then break end
		continuationToken = nextToken
	end

	self:RecomputeUsableAuraState(state)
	state.initialized = true
	return state
end

function Reminder:ApplyDeltaToGroupBuffUnitState(cache, unit, updateInfo)
	local state = self:PrepareGroupBuffUnitState(cache, unit)
	if not state then return nil end

	if isAIFollowerUnit(unit) then
		local changed = state.initialized == true or (tonumber(state.trackedCount) or 0) > 0 or state.hasBuff == true
		self:ResetGroupBuffUnitState(state)
		state.initialized = true
		return state, changed
	end
	if not UnitExists or not UnitExists(unit) then
		local changed = state.initialized == true or (tonumber(state.trackedCount) or 0) > 0 or state.hasBuff == true
		self:ResetGroupBuffUnitState(state)
		return state, changed
	end

	if not updateInfo or (issecretvalue and issecretvalue(updateInfo)) then return self:FullRefreshGroupBuffUnitState(cache, unit), true end
	local isFullUpdate = updateInfo.isFullUpdate
	if issecretvalue and issecretvalue(isFullUpdate) then isFullUpdate = true end
	if isFullUpdate == true or state.initialized ~= true then return self:FullRefreshGroupBuffUnitState(cache, unit), true end

	local changed = false
	local removed = updateInfo.removedAuraInstanceIDs
	if type(removed) == "table" then
		for i = 1, #removed do
			if self:RemoveGroupBuffAuraFromState(state, removed[i]) then changed = true end
		end
	end

	local added = updateInfo.addedAuras
	if type(added) == "table" then
		for i = 1, #added do
			if self:AddGroupBuffAuraToState(state, added[i], cache) then changed = true end
		end
	end

	local updated = updateInfo.updatedAuraInstanceIDs
	if type(updated) == "table" and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
		for i = 1, #updated do
			local auraId = normalizeAuraInstanceId(updated[i])
			if auraId and state.trackedByInstance[auraId] ~= nil then
				local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraId)
				if aura then
					local trackedAuraId = self:GetTrackableGroupBuffAuraData(aura, cache)
					if trackedAuraId == auraId then
						state.expirationByInstance[auraId] = Reminder.GetAuraExpirationTime(aura)
						self:RecomputeUsableAuraState(state)
						changed = true
					elseif self:RemoveGroupBuffAuraFromState(state, auraId) then
						changed = true
					end
				else
					if self:RemoveGroupBuffAuraFromState(state, auraId) then changed = true end
				end
			end
		end
	end

	self:RecomputeUsableAuraState(state)
	state.initialized = true
	return state, changed
end

function Reminder:IsGroupBuffStateCacheValid(cache)
	if type(cache) ~= "table" then return false end
	return cache.rosterVersion == (tonumber(self.rosterUnitsVersion) or 0)
end

function Reminder:GetGroupBuffUnitMissingStatus(cache, unit)
	if type(cache) ~= "table" then return GROUP_UNIT_STATUS_INELIGIBLE end
	if isAIFollowerUnit(unit) and cache.includeAIFollowers ~= true then return GROUP_UNIT_STATUS_INELIGIBLE end
	if not (UnitExists and UnitExists(unit) and UnitIsConnected and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)) then return GROUP_UNIT_STATUS_INELIGIBLE end

	local state = self:PrepareGroupBuffUnitState(cache, unit)
	if not state then return GROUP_UNIT_STATUS_INELIGIBLE end
	if state.initialized ~= true then state = self:FullRefreshGroupBuffUnitState(cache, unit) end
	if state and state.hasUsableBuff == true then return GROUP_UNIT_STATUS_PRESENT end
	if not Reminder.CanActOnMissingGroupBuffUnit(unit) then return GROUP_UNIT_STATUS_INELIGIBLE end
	return GROUP_UNIT_STATUS_MISSING
end

function Reminder:ApplyGroupBuffUnitMissingStatus(cache, unit, nextStatus)
	if type(cache) ~= "table" or type(unit) ~= "string" or unit == "" then return false end
	cache.unitStatus = cache.unitStatus or {}
	local previous = cache.unitStatus[unit]
	if previous == nextStatus then return false end

	if previous == GROUP_UNIT_STATUS_PRESENT or previous == GROUP_UNIT_STATUS_MISSING then cache.total = math.max(0, (tonumber(cache.total) or 0) - 1) end
	if previous == GROUP_UNIT_STATUS_MISSING then cache.missing = math.max(0, (tonumber(cache.missing) or 0) - 1) end

	if nextStatus == GROUP_UNIT_STATUS_PRESENT or nextStatus == GROUP_UNIT_STATUS_MISSING then cache.total = (tonumber(cache.total) or 0) + 1 end
	if nextStatus == GROUP_UNIT_STATUS_MISSING then cache.missing = (tonumber(cache.missing) or 0) + 1 end

	cache.unitStatus[unit] = nextStatus
	return true
end

function Reminder:RebuildGroupBuffStateCache(cache)
	if type(cache) ~= "table" then return nil end

	cache.rosterVersion = tonumber(self.rosterUnitsVersion) or 0
	self.groupBuffAggregateSpellSetDirty = true
	cache.total = 0
	cache.missing = 0
	cache.unitStatus = cache.unitStatus or {}
	wipeTable(cache.unitStatus)

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		self:ApplyGroupBuffUnitMissingStatus(cache, unit, self:GetGroupBuffUnitMissingStatus(cache, unit))
	end

	return cache
end

function Reminder:GetGroupBuffState(cache)
	if self:IsGroupBuffStateCacheValid(cache) then return cache end
	return self:RebuildGroupBuffStateCache(cache)
end

function Reminder:RefreshGroupBuffStateCacheUnit(cache, unit)
	if type(cache) ~= "table" or type(unit) ~= "string" or unit == "" then return false end
	if self:IsGroupBuffStateCacheValid(cache) ~= true then return false end
	return self:ApplyGroupBuffUnitMissingStatus(cache, unit, self:GetGroupBuffUnitMissingStatus(cache, unit))
end

function Reminder:ApplyDeltaToGroupBuffStateCaches(unit, updateInfo)
	local caches = self.groupBuffStateCaches
	if type(caches) ~= "table" or type(unit) ~= "string" or unit == "" then return false end

	local touchedUnits = self:CollectGroupStateUnitsForUnit(nil, unit)
	if type(touchedUnits) ~= "table" then return false end

	local changed = false
	for _, cache in pairs(caches) do
		if type(cache) == "table" and self:IsGroupBuffStateCacheValid(cache) == true then
			for rosterUnit in pairs(touchedUnits) do
				local _, stateChanged = self:ApplyDeltaToGroupBuffUnitState(cache, rosterUnit, updateInfo)
				if stateChanged == true and self:RefreshGroupBuffStateCacheUnit(cache, rosterUnit) == true then changed = true end
			end
		end
	end
	return changed
end

function Reminder.AuraUpdateTouchesTrackedInstances(updateInfo, trackedByInstance)
	if type(trackedByInstance) ~= "table" then return false end
	local removed = updateInfo and updateInfo.removedAuraInstanceIDs
	if type(removed) == "table" then
		for i = 1, #removed do
			local auraId = normalizeAuraInstanceId(removed[i])
			if auraId and trackedByInstance[auraId] ~= nil then return true end
		end
	end
	local updated = updateInfo and updateInfo.updatedAuraInstanceIDs
	if type(updated) == "table" then
		for i = 1, #updated do
			local auraId = normalizeAuraInstanceId(updated[i])
			if auraId and trackedByInstance[auraId] ~= nil then return true end
		end
	end
	return false
end

function Reminder:ProviderAuraUpdateTouchesUnit(unit, updateInfo, provider)
	if not (provider and provider.spellSet and type(unit) == "string" and unit ~= "") then return false end
	if Reminder.IsFullAuraUpdate(updateInfo) then return true end

	local unitStates = self.unitAuraStates
	local state = type(unitStates) == "table" and unitStates[unit] or nil
	if Reminder.AuraUpdateTouchesTrackedInstances(updateInfo, state and state.trackedByInstance) then return true end

	local added = updateInfo.addedAuras
	if type(added) == "table" then
		for i = 1, #added do
			if self:GetTrackableProviderAuraData(added[i], provider) then return true end
		end
	end
	return false
end

function Reminder:GroupBuffCacheAuraUpdateTouchesUnit(unit, updateInfo)
	local caches = self.groupBuffStateCaches
	if type(caches) ~= "table" or type(unit) ~= "string" or unit == "" then return false end
	if Reminder.IsFullAuraUpdate(updateInfo) then return true end

	for _, cache in pairs(caches) do
		if type(cache) == "table" and self:IsGroupBuffStateCacheValid(cache) == true then
			local state = cache.unitStates and cache.unitStates[unit]
			if Reminder.AuraUpdateTouchesTrackedInstances(updateInfo, state and state.trackedByInstance) then return true end
		end
	end

	local added = updateInfo.addedAuras
	local aggregateSpellSet = self:GetGroupBuffAggregateSpellSet()
	if type(added) == "table" and type(aggregateSpellSet) == "table" then
		for i = 1, #added do
			local aura = added[i]
			if Reminder.IsRelevantHelpfulPlayerAura(aura) then
				local spellId = normalizeSpellId(aura.spellId)
				if spellId and aggregateSpellSet[spellId] == true then return true end
			end
		end
	end
	return false
end

function Reminder.PreparedAuraDataMatchesValues(prepared, spellId, auraName)
	if type(prepared) ~= "table" then return false end
	spellId = normalizeSpellId(spellId)
	if issecretvalue and issecretvalue(auraName) then auraName = nil end
	if spellId and type(prepared.spellIds) == "table" then
		for i = 1, #prepared.spellIds do
			if normalizeSpellId(prepared.spellIds[i]) == spellId then return true end
		end
	end
	if type(auraName) == "string" and auraName ~= "" and type(prepared.auraNames) == "table" then
		for i = 1, #prepared.auraNames do
			if prepared.auraNames[i] == auraName then return true end
		end
	end
	return false
end

function Reminder:SupplementalAuraMatches(aura)
	if not Reminder.IsRelevantHelpfulPlayerAura(aura) then return false end
	local spellId = normalizeSpellId(aura.spellId)
	local auraName = aura.name
	if issecretvalue and issecretvalue(auraName) then auraName = nil end

	if self:CanCheckFlaskReminder() then
		local candidates = self:GetFlaskCandidatesForCurrentSpec()
		if type(candidates) == "table" and Reminder.PreparedAuraDataMatchesValues(self:GetPreparedFlaskCandidateData(candidates), spellId, auraName) then return true end
	end
	if self:CanCheckFoodReminder() then
		local candidates = self:GetFoodCandidatesForCurrentSpec()
		if type(candidates) == "table" and Reminder.PreparedAuraDataMatchesValues(self:GetPreparedFoodCandidateData(candidates), spellId, auraName) then return true end
	end
	if self:CanCheckRuneReminder() then
		if spellId and type(Reminder.runeTracking.auraIds) == "table" then
			for i = 1, #Reminder.runeTracking.auraIds do
				if normalizeSpellId(Reminder.runeTracking.auraIds[i]) == spellId then return true end
			end
		end
		local candidates = self:GetRuneCandidates()
		if type(candidates) == "table" and Reminder.PreparedAuraDataMatchesValues(self:GetPreparedRuneCandidateData(candidates), spellId, auraName) then return true end
	end
	return false
end

function Reminder:SupplementalAuraUpdateTouchesPlayer(updateInfo)
	if not (self:CanCheckFlaskReminder() or self:CanCheckFoodReminder() or self:CanCheckRuneReminder()) then return false end
	if Reminder.IsFullAuraUpdate(updateInfo) then return true end

	local added = updateInfo.addedAuras
	if type(added) == "table" then
		for i = 1, #added do
			if self:SupplementalAuraMatches(added[i]) then return true end
		end
	end

	local snapshot = self.playerAuraPresenceSnapshot
	if type(snapshot) ~= "table" then return false end
	local function snapshotAuraIdMatches(auraId)
		auraId = normalizeAuraInstanceId(auraId)
		if not auraId then return false end
		local spellId = snapshot.instanceSpellIds and normalizeSpellId(snapshot.instanceSpellIds[auraId]) or nil
		local auraName = snapshot.instanceNames and snapshot.instanceNames[auraId] or nil
		if self:CanCheckFlaskReminder() and Reminder.PreparedAuraDataMatchesValues(self:GetPreparedFlaskCandidateData(self:GetFlaskCandidatesForCurrentSpec()), spellId, auraName) then return true end
		if self:CanCheckFoodReminder() and Reminder.PreparedAuraDataMatchesValues(self:GetPreparedFoodCandidateData(self:GetFoodCandidatesForCurrentSpec()), spellId, auraName) then return true end
		if self:CanCheckRuneReminder() then
			if spellId and type(Reminder.runeTracking.auraIds) == "table" then
				for i = 1, #Reminder.runeTracking.auraIds do
					if normalizeSpellId(Reminder.runeTracking.auraIds[i]) == spellId then return true end
				end
			end
			if Reminder.PreparedAuraDataMatchesValues(self:GetPreparedRuneCandidateData(self:GetRuneCandidates()), spellId, auraName) then return true end
		end
		return false
	end

	local removed = updateInfo.removedAuraInstanceIDs
	if type(removed) == "table" then
		for i = 1, #removed do
			if snapshotAuraIdMatches(removed[i]) then return true end
		end
	end
	local updated = updateInfo.updatedAuraInstanceIDs
	if type(updated) == "table" then
		for i = 1, #updated do
			if snapshotAuraIdMatches(updated[i]) then return true end
		end
	end
	return false
end

function Reminder:CollectGroupStateUnitsForUnit(target, unit)
	if type(unit) ~= "string" or unit == "" then return target end
	self:GetRosterUnits()

	if self.rosterUnitLookup and self.rosterUnitLookup[unit] == true then
		target = target or {}
		target[unit] = true
		return target
	end

	local units = self.rosterUnits
	if type(units) ~= "table" or #units <= 0 then return target end

	local matched
	local unitIdentity = getUnitIdentity(unit)
	local canCompareUnits = UnitExists and UnitExists(unit) and UnitIsUnit
	for i = 1, #units do
		local rosterUnit = units[i]
		if rosterUnit == unit then
			target = target or {}
			target[rosterUnit] = true
			matched = true
		elseif canCompareUnits and UnitExists(rosterUnit) and UnitIsUnit(rosterUnit, unit) then
			target = target or {}
			target[rosterUnit] = true
			matched = true
		elseif unitIdentity and unitIdentity == getUnitIdentity(rosterUnit) then
			target = target or {}
			target[rosterUnit] = true
			matched = true
		end
	end

	if matched == true then return target end
	return target
end

function Reminder:RefreshGroupMissingStateUnit(provider, unit)
	local state = self.groupMissingState
	if not self:IsGroupMissingStateValid(provider, state) then return nil end
	local matchedUnits = self:CollectGroupStateUnitsForUnit(nil, unit)
	if type(matchedUnits) ~= "table" then return state end
	for matchedUnit in pairs(matchedUnits) do
		self:ApplyGroupUnitMissingStatus(state, matchedUnit, self:GetGroupUnitMissingStatus(provider, matchedUnit))
	end
	return state
end

function Reminder:HasProvider()
	local _, hasProvider = self:RefreshProviderCache(false)
	return hasProvider == true
end

function Reminder:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "EQOL_ClassBuffReminderFrame", UIParent, "BackdropTemplate")
	frame:SetClampedToScreen(true)
	frame:SetMovable(false)
	frame:SetSize(220, 34)
	frame:SetFrameStrata("MEDIUM")

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(frame)
	bg:SetColorTexture(0, 0, 0, 0.45)
	frame.bg = bg

	local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	border:SetFrameStrata(frame:GetFrameStrata())
	border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)
	border:EnableMouse(false)
	border:Hide()
	frame.border = border

	local iconHolder = CreateFrame("Button", nil, frame)
	iconHolder:SetSize(defaults.iconSize, defaults.iconSize)
	iconHolder:SetPoint("LEFT", frame, "LEFT", 6, 0)
	frame.iconHolder = iconHolder

	local icon = iconHolder:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(iconHolder)
	icon:SetTexture(ICON_MISSING)
	frame.icon = icon

	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameText:SetJustifyH("LEFT")
	nameText:SetPoint("TOPLEFT", iconHolder, "TOPRIGHT", 6, -1)
	frame.nameText = nameText

	local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countText:SetJustifyH("LEFT")
	countText:SetPoint("BOTTOMLEFT", iconHolder, "BOTTOMRIGHT", 6, 1)
	frame.countText = countText

	local iconCountText = iconHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	iconCountText:SetPoint("CENTER", iconHolder, "CENTER", 0, 0)
	iconCountText:SetJustifyH("CENTER")
	iconCountText:SetShadowOffset(1, -1)
	iconCountText:SetShadowColor(0, 0, 0, 1)
	iconCountText:Hide()
	frame.iconCountText = iconCountText

	local missingIconContainer = CreateFrame("Frame", nil, frame)
	missingIconContainer:SetPoint("CENTER", frame, "CENTER", 0, 0)
	missingIconContainer:SetSize(defaults.iconSize, defaults.iconSize)
	missingIconContainer:Hide()
	frame.missingIconContainer = missingIconContainer
	frame.missingIcons = {}

	local sampleContainer = CreateFrame("Frame", nil, frame)
	sampleContainer:SetAllPoints(frame)
	sampleContainer:Hide()
	frame.sampleContainer = sampleContainer

	frame.sampleIcons = {}
	for i = 1, SAMPLE_ICON_COUNT do
		local sample = CreateFrame("Frame", nil, sampleContainer)
		sample:SetSize(defaults.iconSize, defaults.iconSize)
		local sampleIcon = sample:CreateTexture(nil, "ARTWORK")
		sampleIcon:SetAllPoints(sample)
		sampleIcon:SetTexture(safeGetSpellIcon(SAMPLE_SPELL_IDS[i]))
		sample.icon = sampleIcon
		sample:Hide()
		frame.sampleIcons[i] = sample
	end

	frame:Hide()

	self.frame = frame
	self:ApplyVisualSettings()

	return frame
end

function Reminder:GetSelfProviderStatus(provider, forceRefresh)
	if type(provider) ~= "table" or provider.scope ~= PROVIDER_SCOPE_SELF then return nil end
	if not forceRefresh and self.selfProviderStatusProvider == provider and type(self.selfProviderStatus) == "table" then return self.selfProviderStatus end
	if type(provider.getSelfStatusFunc) ~= "function" then return nil end

	local status = provider.getSelfStatusFunc(provider, self)
	if type(status) ~= "table" then return nil end

	local entries = type(status.missingEntries) == "table" and status.missingEntries or {}
	local missing = tonumber(status.missing)
	if missing == nil then missing = #entries end
	if missing < 0 then missing = 0 end
	local total = tonumber(status.total)
	if total == nil then total = math.max(1, missing) end
	if total < missing then total = missing end
	if total < 0 then total = 0 end

	status.missingEntries = entries
	status.missing = missing
	status.total = total

	self.selfProviderStatusProvider = provider
	self.selfProviderStatus = status
	return status
end

function Reminder:GetSelfMissingEntries(provider)
	local status = self:GetSelfProviderStatus(provider, false)
	if not status then return nil end
	return status.missingEntries
end

function Reminder:GetSelfMissingSummaryText(entries)
	if type(entries) ~= "table" or #entries <= 0 then return "" end
	local parts = {}
	for i = 1, #entries do
		local entry = entries[i]
		local label = type(entry) == "table" and entry.label or nil
		if type(label) ~= "string" or label == "" then
			local sid = type(entry) == "table" and normalizeSpellId(entry.spellId) or nil
			label = sid and safeGetSpellName(sid) or nil
		end
		if type(label) ~= "string" or label == "" then label = L["ClassBuffReminderMissing"] or "Missing" end
		local cm = type(entry) == "table" and tonumber(entry.countMissing) or nil
		local ct = type(entry) == "table" and tonumber(entry.countTotal) or nil
			local shortText = type(entry) == "table" and entry.shortText or nil
		if cm and ct and ct > 0 then
			cm = math.max(0, math.floor(cm + 0.5))
			ct = math.max(0, math.floor(ct + 0.5))
			label = string.format("%s (%d/%d)", label, cm, ct)
		end
		parts[#parts + 1] = label
	end
	return table.concat(parts, ", ")
end

function Reminder:EnsureSelfMissingIconFrames(requiredCount)
	local frame = self:EnsureFrame()
	if not frame then return nil, nil end
	frame.missingIcons = frame.missingIcons or {}
	frame.missingIconContainer = frame.missingIconContainer or CreateFrame("Frame", nil, frame)
	local container = frame.missingIconContainer

	for i = 1, requiredCount do
		local iconFrame = frame.missingIcons[i]
		if not iconFrame then
			iconFrame = CreateFrame("Frame", nil, container)
			iconFrame:SetSize(defaults.iconSize, defaults.iconSize)
			local icon = iconFrame:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints(iconFrame)
			icon:SetTexture(ICON_MISSING)
			iconFrame.icon = icon

			local border = CreateFrame("Frame", nil, iconFrame, "BackdropTemplate")
			border:EnableMouse(false)
			border:Hide()
			iconFrame.border = border

			local countText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			countText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
			countText:SetJustifyH("CENTER")
			countText:SetShadowOffset(1, -1)
			countText:SetShadowColor(0, 0, 0, 1)
			countText:SetText("")
			iconFrame.countText = countText

			frame.missingIcons[i] = iconFrame
		end
	end

	return container, frame.missingIcons
end

function Reminder:HideSelfMissingIcons()
	local frame = self.frame
	if not frame then return end
	if frame.missingIconContainer then frame.missingIconContainer:Hide() end
	if frame.missingIcons then
		for i = 1, #frame.missingIcons do
			local iconFrame = frame.missingIcons[i]
			if iconFrame then iconFrame:Hide() end
		end
	end
	if frame.iconHolder then frame.iconHolder:Show() end
end

function Reminder:RenderSelfMissingIcons(missingEntries)
	local frame = self.frame
	if not frame then return false end
	if type(missingEntries) ~= "table" or #missingEntries <= 0 then
		self:HideSelfMissingIcons()
		return false
	end

	local scale = clamp(getValue(DB_SCALE, defaults.scale), 0.5, 2, defaults.scale)
	local iconSize = clamp(getValue(DB_ICON_SIZE, defaults.iconSize), 14, 120, defaults.iconSize)
	local iconGap = clamp(getValue(DB_ICON_GAP, defaults.iconGap), 0, 40, defaults.iconGap)
	local xyTextSize, xyTextOutline, xyTextR, xyTextG, xyTextB, xyTextA, xyOffsetX, xyOffsetY = self:GetIconCountTextStyle()
	local scaledIconSize = math.max(14, math.floor((iconSize * scale) + 0.5))
	local scaledIconGap = math.max(0, math.floor((iconGap * scale) + 0.5))
	local scaledXYTextSize = math.max(8, math.floor((xyTextSize * scale) + 0.5))
	local scaledXYOffsetX = math.floor((xyOffsetX * scale) + 0.5)
	local scaledXYOffsetY = math.floor((xyOffsetY * scale) + 0.5)
	local step = scaledIconSize + scaledIconGap
	local direction = self:GetGrowthDirection()
	local growFromCenter = self:GetGrowthFromCenter()
	local count = #missingEntries
	local fontPath = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local borderEnabled = self:IsBorderEnabled()
	local borderTexture = self:GetBorderTextureKey()
	local borderSize = self:GetBorderSize()
	local borderOffset = self:GetBorderOffset()
	local borderR, borderG, borderB, borderA = self:GetBorderColor()

	local width, height
	if direction == GROWTH_UP or direction == GROWTH_DOWN then
		width = scaledIconSize
		height = scaledIconSize + ((count - 1) * step)
	else
		width = scaledIconSize + ((count - 1) * step)
		height = scaledIconSize
	end

	local container, icons = self:EnsureSelfMissingIconFrames(count)
	if not (container and icons) then return false end

	container:ClearAllPoints()
	container:SetPoint("CENTER", frame, "CENTER", 0, 0)
	container:SetSize(width, height)

	for i = 1, #icons do
		if icons[i] then icons[i]:Hide() end
	end

	for i = 1, count do
		local iconFrame = icons[i]
		local entry = missingEntries[i]
		local sid = type(entry) == "table" and normalizeSpellId(entry.spellId) or nil
		local entryIcon = type(entry) == "table" and Reminder.NormalizeIconTexture(entry.icon) or nil
		local texture = entryIcon or (sid and safeGetSpellIcon(sid)) or ICON_MISSING

		iconFrame:SetSize(scaledIconSize, scaledIconSize)
		iconFrame:ClearAllPoints()

		local x = 0
		local y = 0
		if growFromCenter then
			local centeredOffset = centeredAxisOffset(i, count, step)
			if direction == GROWTH_UP or direction == GROWTH_DOWN then
				y = centeredOffset
			else
				x = centeredOffset
			end
		elseif direction == GROWTH_LEFT then
			x = (width / 2) - (scaledIconSize / 2) - ((i - 1) * step)
		elseif direction == GROWTH_UP then
			y = -(height / 2) + (scaledIconSize / 2) + ((i - 1) * step)
		elseif direction == GROWTH_DOWN then
			y = (height / 2) - (scaledIconSize / 2) - ((i - 1) * step)
		else
			x = -(width / 2) + (scaledIconSize / 2) + ((i - 1) * step)
		end

		iconFrame:SetPoint("CENTER", container, "CENTER", x, y)
		if iconFrame.icon then iconFrame.icon:SetTexture(texture) end
		if iconFrame.border and iconFrame.border.SetBackdrop then
			iconFrame.border:SetFrameStrata(iconFrame:GetFrameStrata())
			iconFrame.border:SetFrameLevel((iconFrame:GetFrameLevel() or 0) + 1)
			if borderEnabled then
				iconFrame.border:SetBackdrop({
					edgeFile = resolveBorderTexture(borderTexture),
					edgeSize = borderSize,
				})
				iconFrame.border:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
				iconFrame.border:SetBackdropColor(0, 0, 0, 0)
				iconFrame.border:ClearAllPoints()
				iconFrame.border:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -borderOffset, borderOffset)
				iconFrame.border:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", borderOffset, -borderOffset)
				iconFrame.border:Show()
			else
				iconFrame.border:SetBackdrop(nil)
				iconFrame.border:Hide()
			end
		end
		if iconFrame.countText then
			if iconFrame.countText.SetFont then iconFrame.countText:SetFont(fontPath, scaledXYTextSize, textOutlineFlags(xyTextOutline)) end
			iconFrame.countText:SetTextColor(xyTextR, xyTextG, xyTextB, xyTextA)
			iconFrame.countText:ClearAllPoints()
			iconFrame.countText:SetPoint("CENTER", iconFrame, "CENTER", scaledXYOffsetX, scaledXYOffsetY)
			local cm = type(entry) == "table" and tonumber(entry.countMissing) or nil
			local ct = type(entry) == "table" and tonumber(entry.countTotal) or nil
			local shortText = type(entry) == "table" and entry.shortText or nil
			if iconFrame.countText.SetWidth then iconFrame.countText:SetWidth(scaledIconSize + 2) end
			if cm and ct and ct > 0 then
				cm = math.max(0, math.floor(cm + 0.5))
				ct = math.max(0, math.floor(ct + 0.5))
				iconFrame.countText:SetText(string.format("%d/%d", cm, ct))
			elseif type(shortText) == "string" and shortText ~= "" then
				iconFrame.countText:SetText(shortText)
			else
				iconFrame.countText:SetText("")
			end
		end
		iconFrame:Show()
	end

	if frame.iconHolder then frame.iconHolder:Hide() end
	if frame.border then frame.border:Hide() end
	container:Show()
	frame:SetSize(width + 2, height + 2)
	return true
end

function Reminder:GetGlowTargets()
	local frame = self.frame
	if not frame then return nil end

	if frame.missingIconContainer and frame.missingIconContainer:IsShown() and type(frame.missingIcons) == "table" then
		local targets = {}
		for i = 1, #frame.missingIcons do
			local iconFrame = frame.missingIcons[i]
			if iconFrame and iconFrame:IsShown() then targets[#targets + 1] = iconFrame end
		end
		if #targets > 0 then return targets end
	end

	if frame.iconHolder then return { frame.iconHolder } end
	return nil
end

function Reminder:SetGlowShown(show)
	if not Glow then return end

	self.glowTargets = self.glowTargets or {}
	if show ~= true then
		for target in pairs(self.glowTargets) do
			Glow.Stop(target, REMINDER_GLOW_KEY)
			self.glowTargets[target] = nil
		end
		self.glowShown = false
		self.glowActiveStyle = nil
		self.glowActiveInset = nil
		self.glowActiveColorR = nil
		self.glowActiveColorG = nil
		self.glowActiveColorB = nil
		self.glowActiveColorA = nil
		return
	end

	local style = self:GetGlowStyle()
	local inset = self:GetGlowInset()
	local colorR, colorG, colorB, colorA = self:GetGlowColor()
	local styleChanged = self.glowActiveStyle ~= style
	local insetChanged = self.glowActiveInset ~= inset
	local colorChanged = self.glowActiveColorR ~= colorR or self.glowActiveColorG ~= colorG or self.glowActiveColorB ~= colorB or self.glowActiveColorA ~= colorA
	local targets = self:GetGlowTargets() or {}
	local nextTargets = {}
	for i = 1, #targets do
		local target = targets[i]
		if target then nextTargets[target] = true end
	end

	for target in pairs(self.glowTargets) do
		if not nextTargets[target] then
			Glow.Stop(target, REMINDER_GLOW_KEY)
			self.glowTargets[target] = nil
		end
	end

	for target in pairs(nextTargets) do
		if styleChanged or insetChanged or colorChanged or not self.glowTargets[target] then
			Glow.Start(target, REMINDER_GLOW_KEY, style, {
				inset = inset,
				color = { colorR, colorG, colorB, colorA },
			})
		end
		self.glowTargets[target] = true
	end

	local hasGlow = next(self.glowTargets) ~= nil
	self.glowShown = hasGlow
	self.glowActiveStyle = hasGlow and style or nil
	self.glowActiveInset = hasGlow and inset or nil
	self.glowActiveColorR = hasGlow and colorR or nil
	self.glowActiveColorG = hasGlow and colorG or nil
	self.glowActiveColorB = hasGlow and colorB or nil
	self.glowActiveColorA = hasGlow and colorA or nil
end

function Reminder:HideSamplePreview()
	local frame = self.frame
	if not frame then return end
	if frame.sampleContainer then frame.sampleContainer:Hide() end
	if not frame.sampleIcons then return end
	for i = 1, #frame.sampleIcons do
		local sample = frame.sampleIcons[i]
		if sample then sample:Hide() end
	end
end

function Reminder:ApplySamplePreview(iconSize, scale, iconGap)
	local frame = self.frame
	if not frame or not frame.sampleIcons then return end
	if not self.editModeActive then
		self:HideSamplePreview()
		return
	end

	local direction = self:GetGrowthDirection()
	local growFromCenter = self:GetGrowthFromCenter()
	local spacing = iconGap
	if type(spacing) ~= "number" then spacing = math.floor((6 * (scale or 1)) + 0.5) end
	if spacing < 0 then spacing = 0 end
	local count = math.min(SAMPLE_ICON_COUNT, #frame.sampleIcons)

	for i = 1, count do
		local sample = frame.sampleIcons[i]
		local sid = SAMPLE_SPELL_IDS[((i - 1) % #SAMPLE_SPELL_IDS) + 1]
		sample:ClearAllPoints()
		sample:SetSize(iconSize, iconSize)
		if sample.icon then sample.icon:SetTexture(safeGetSpellIcon(sid)) end
		sample:SetAlpha(i == 1 and 1 or 0.85)
		sample:Show()

		if growFromCenter then
			local centeredOffset = centeredAxisOffset(i, count, spacing)
			if direction == GROWTH_UP or direction == GROWTH_DOWN then
				sample:SetPoint("CENTER", frame, "CENTER", 0, centeredOffset)
			else
				sample:SetPoint("CENTER", frame, "CENTER", centeredOffset, 0)
			end
		elseif i == 1 then
			if direction == GROWTH_LEFT then
				sample:SetPoint("RIGHT", frame, "LEFT", -spacing, 0)
			elseif direction == GROWTH_UP then
				sample:SetPoint("BOTTOM", frame, "TOP", 0, spacing)
			elseif direction == GROWTH_DOWN then
				sample:SetPoint("TOP", frame, "BOTTOM", 0, -spacing)
			else
				sample:SetPoint("LEFT", frame, "RIGHT", spacing, 0)
			end
		else
			local prev = frame.sampleIcons[i - 1]
			if direction == GROWTH_LEFT then
				sample:SetPoint("RIGHT", prev, "LEFT", -spacing, 0)
			elseif direction == GROWTH_UP then
				sample:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
			elseif direction == GROWTH_DOWN then
				sample:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
			else
				sample:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
			end
		end
	end

	if frame.sampleContainer then frame.sampleContainer:Show() end
end

function Reminder:ApplyVisualSettings()
	local frame = self:EnsureFrame()
	if not frame then return end

	local scale = clamp(getValue(DB_SCALE, defaults.scale), 0.5, 2, defaults.scale)
	local iconSize = clamp(getValue(DB_ICON_SIZE, defaults.iconSize), 14, 120, defaults.iconSize)
	local fontSize = clamp(getValue(DB_FONT_SIZE, defaults.fontSize), 9, 30, defaults.fontSize)
	local iconGap = clamp(getValue(DB_ICON_GAP, defaults.iconGap), 0, 40, defaults.iconGap)
	local displayMode = normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode))
	local growthDirection = normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection))
	local xyTextSize, xyTextOutline, xyTextR, xyTextG, xyTextB, xyTextA, xyOffsetX, xyOffsetY = self:GetIconCountTextStyle()
	local borderEnabled = self:IsBorderEnabled()
	local borderTexture = self:GetBorderTextureKey()
	local borderSize = self:GetBorderSize()
	local borderOffset = self:GetBorderOffset()
	local borderR, borderG, borderB, borderA = self:GetBorderColor()
	local scaledIconSize = math.max(14, math.floor((iconSize * scale) + 0.5))
	local scaledFontSize = math.max(9, math.floor((fontSize * scale) + 0.5))
	local scaledIconGap = math.max(0, math.floor((iconGap * scale) + 0.5))
	local scaledXYTextSize = math.max(8, math.floor((xyTextSize * scale) + 0.5))
	local scaledXYOffsetX = math.floor((xyOffsetX * scale) + 0.5)
	local scaledXYOffsetY = math.floor((xyOffsetY * scale) + 0.5)
	local textGap = scaledIconGap
	local framePadding = math.max(4, math.floor((6 * scale) + 0.5))

	if addon.db then
		if addon.db[DB_DISPLAY_MODE] ~= displayMode then addon.db[DB_DISPLAY_MODE] = displayMode end
		if addon.db[DB_SCALE] ~= scale then addon.db[DB_SCALE] = scale end
		if addon.db[DB_ICON_SIZE] ~= iconSize then addon.db[DB_ICON_SIZE] = iconSize end
		if addon.db[DB_FONT_SIZE] ~= fontSize then addon.db[DB_FONT_SIZE] = fontSize end
		if addon.db[DB_ICON_GAP] ~= iconGap then addon.db[DB_ICON_GAP] = iconGap end
		if addon.db[DB_GROWTH_DIRECTION] ~= growthDirection then addon.db[DB_GROWTH_DIRECTION] = growthDirection end
		if addon.db[DB_BORDER_ENABLED] ~= borderEnabled then addon.db[DB_BORDER_ENABLED] = borderEnabled end
		if addon.db[DB_BORDER_TEXTURE] ~= borderTexture then addon.db[DB_BORDER_TEXTURE] = borderTexture end
		if addon.db[DB_BORDER_SIZE] ~= borderSize then addon.db[DB_BORDER_SIZE] = borderSize end
		if addon.db[DB_BORDER_OFFSET] ~= borderOffset then addon.db[DB_BORDER_OFFSET] = borderOffset end
		if addon.db[DB_XY_TEXT_SIZE] ~= xyTextSize then addon.db[DB_XY_TEXT_SIZE] = xyTextSize end
		if addon.db[DB_XY_TEXT_OUTLINE] ~= xyTextOutline then addon.db[DB_XY_TEXT_OUTLINE] = xyTextOutline end
		if addon.db[DB_XY_TEXT_OFFSET_X] ~= xyOffsetX then addon.db[DB_XY_TEXT_OFFSET_X] = xyOffsetX end
		if addon.db[DB_XY_TEXT_OFFSET_Y] ~= xyOffsetY then addon.db[DB_XY_TEXT_OFFSET_Y] = xyOffsetY end
		local currentBorderColor = addon.db[DB_BORDER_COLOR]
		if type(currentBorderColor) ~= "table" or currentBorderColor.r ~= borderR or currentBorderColor.g ~= borderG or currentBorderColor.b ~= borderB or currentBorderColor.a ~= borderA then
			addon.db[DB_BORDER_COLOR] = { r = borderR, g = borderG, b = borderB, a = borderA }
		end
		local currentColor = addon.db[DB_XY_TEXT_COLOR]
		if type(currentColor) ~= "table" or currentColor.r ~= xyTextR or currentColor.g ~= xyTextG or currentColor.b ~= xyTextB or currentColor.a ~= xyTextA then
			addon.db[DB_XY_TEXT_COLOR] = { r = xyTextR, g = xyTextG, b = xyTextB, a = xyTextA }
		end
	end

	frame:SetScale(1)
	frame.iconHolder:SetSize(scaledIconSize, scaledIconSize)
	frame.iconHolder:ClearAllPoints()
	frame.iconHolder:SetShown(true)

	local fontPath = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	if frame.nameText and frame.nameText.SetFont then frame.nameText:SetFont(fontPath, scaledFontSize, "OUTLINE") end
	if frame.countText and frame.countText.SetFont then frame.countText:SetFont(fontPath, scaledFontSize, "OUTLINE") end
	if frame.iconCountText and frame.iconCountText.SetFont then frame.iconCountText:SetFont(fontPath, scaledXYTextSize, textOutlineFlags(xyTextOutline)) end
	if frame.iconCountText then
		frame.iconCountText:SetTextColor(xyTextR, xyTextG, xyTextB, xyTextA)
		frame.iconCountText:ClearAllPoints()
		frame.iconCountText:SetPoint("CENTER", frame.iconHolder, "CENTER", scaledXYOffsetX, scaledXYOffsetY)
		if frame.iconCountText.SetWidth then frame.iconCountText:SetWidth(scaledIconSize + 2) end
	end

	frame.nameText:ClearAllPoints()
	frame.countText:ClearAllPoints()
	if displayMode == DISPLAY_MODE_ICON_ONLY then
		if frame.bg then frame.bg:Hide() end
		frame.nameText:Hide()
		frame.countText:Hide()
		if frame.iconCountText then frame.iconCountText:Show() end
		frame.iconHolder:SetPoint("CENTER", frame, "CENTER", 0, 0)
		frame:SetSize(scaledIconSize + 2, scaledIconSize + 2)
	else
		if frame.bg then frame.bg:Show() end
		frame.nameText:Show()
		frame.countText:Show()
		if frame.iconCountText then frame.iconCountText:Hide() end
		frame.iconHolder:SetPoint("LEFT", frame, "LEFT", framePadding, 0)
		frame.nameText:SetPoint("TOPLEFT", frame.iconHolder, "TOPRIGHT", textGap, -1)
		frame.countText:SetPoint("BOTTOMLEFT", frame.iconHolder, "BOTTOMRIGHT", textGap, 1)
		local textWidth = math.max(frame.nameText:GetStringWidth() or 0, frame.countText:GetStringWidth() or 0)
		local width = (scaledIconSize + (framePadding * 2) + textGap) + textWidth + framePadding
		local minWidth = math.floor((120 * scale) + 0.5)
		if width < minWidth then width = minWidth end
		local height = math.max(scaledIconSize + (framePadding * 2), (scaledFontSize * 2) + (framePadding * 2))
		local minHeight = math.floor((30 * scale) + 0.5)
		if height < minHeight then height = minHeight end
		frame:SetSize(width, height)
	end

	if frame.border and frame.border.SetBackdrop then
		frame.border:SetFrameStrata(frame:GetFrameStrata())
		frame.border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)
		if borderEnabled then
			frame.border:SetBackdrop({
				edgeFile = resolveBorderTexture(borderTexture),
				edgeSize = borderSize,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			frame.border:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
			frame.border:SetBackdropColor(0, 0, 0, 0)
			frame.border:ClearAllPoints()
			frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderOffset, borderOffset)
			frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderOffset, -borderOffset)
			frame.border:Show()
		else
			frame.border:SetBackdrop(nil)
			frame.border:Hide()
		end
	end

	self:ApplySamplePreview(scaledIconSize, scale, scaledIconGap)
end

function Reminder:InvalidateRosterCache()
	self:ClearPendingAuraUpdates()
	self:InvalidateSelfProviderStatus()
	self.rosterUnitsValid = nil
	self.rosterUnitsVersion = (tonumber(self.rosterUnitsVersion) or 0) + 1
	self:InvalidateGroupMissingState()
	self:InvalidateGroupBuffStateCaches()
end

function Reminder:GetRosterUnits()
	if self.rosterUnitsValid == true and type(self.rosterUnits) == "table" then return self.rosterUnits end

	self.rosterUnits = self.rosterUnits or {}
	self.rosterUnitLookup = self.rosterUnitLookup or {}
	local units = self.rosterUnits
	local lookup = self.rosterUnitLookup
	for i = #units, 1, -1 do
		units[i] = nil
	end
	wipeTable(lookup)

	if IsInRaid and IsInRaid() then
		local total = (GetNumGroupMembers and GetNumGroupMembers()) or 0
		for i = 1, total do
			local unit = "raid" .. i
			units[#units + 1] = unit
			lookup[unit] = true
		end
	elseif IsInGroup and IsInGroup() then
		units[#units + 1] = "player"
		lookup.player = true
		local total = (GetNumSubgroupMembers and GetNumSubgroupMembers()) or math.max(0, ((GetNumGroupMembers and GetNumGroupMembers()) or 1) - 1)
		for i = 1, total do
			local unit = "party" .. i
			units[#units + 1] = unit
			lookup[unit] = true
		end
	else
		units[#units + 1] = "player"
		lookup.player = true
	end

	self.rosterUnitsValid = true
	return units
end

function Reminder:IsRosterUnit(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	self:GetRosterUnits()
	return self.rosterUnitLookup and self.rosterUnitLookup[unit] == true
end

function Reminder:CollectUnits(target)
	local units = self:GetRosterUnits()
	if not target or target == units then return units end
	for i = #target, 1, -1 do
		target[i] = nil
	end
	for i = 1, #units do
		target[i] = units[i]
	end
	return target
end

function Reminder:CollectOtherHealerUnits(target, includeAIFollowers)
	if not target then target = {} end
	for i = #target, 1, -1 do
		target[i] = nil
	end

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		if
			not isPlayerUnit(unit)
			and (includeAIFollowers == true or not isAIFollowerUnit(unit))
			and UnitExists(unit)
			and UnitIsConnected(unit)
			and not UnitIsDeadOrGhost(unit)
			and isUnitHealerRole(unit)
		then
			target[#target + 1] = unit
		end
	end

	return target
end

function Reminder:CollectEligibleUnits(target, includeAIFollowers)
	if not target then target = {} end
	for i = #target, 1, -1 do
		target[i] = nil
	end

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		if (includeAIFollowers == true or not isAIFollowerUnit(unit)) and UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then target[#target + 1] = unit end
	end

	return target
end

function Reminder:CollectOtherEligibleUnits(target, includeAIFollowers)
	if not target then target = {} end
	for i = #target, 1, -1 do
		target[i] = nil
	end

	local units = self:GetRosterUnits()
	for i = 1, #units do
		local unit = units[i]
		if not isPlayerUnit(unit) and (includeAIFollowers == true or not isAIFollowerUnit(unit)) and UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
			target[#target + 1] = unit
		end
	end

	return target
end

function Reminder:UnitHasProviderBuff(unit, provider)
	if not (unit and provider) then return false end
	if provider.scope == PROVIDER_SCOPE_SELF then
		local status = self:GetSelfProviderStatus(provider, false)
		if status then return status.missing <= 0 end
	end
	if type(provider.hasUnitBuffFunc) == "function" then return provider.hasUnitBuffFunc(provider, unit, self) == true end
	if not provider.spellSet then return false end
	local state = self:PrepareUnitAuraState(unit, provider)
	if not state then return false end
	if not state.initialized then state = self:FullRefreshUnitAuraState(unit, provider) end
	return state and state.hasUsableBuff == true
end

function Reminder:ComputeMissing(provider)
	if provider and provider.scope == PROVIDER_SCOPE_SELF then
		if not canEvaluateUnit("player") then return 0, 0 end

		local status = self:GetSelfProviderStatus(provider, false)
		if status then return status.missing, status.total end

		if self:UnitHasProviderBuff("player", provider) then return 0, 1 end
		return 1, 1
	end

	local state = self:GetGroupMissingState(provider)
	if not state then return 0, 0 end
	return tonumber(state.missing) or 0, tonumber(state.total) or 0
end

function Reminder:IsGroupModeAllowed()
	local context = self:GetGroupContext()
	if context == GROUP_CONTEXT_RAID then return getValue(DB_SHOW_RAID, defaults.showRaid) == true end
	if context == GROUP_CONTEXT_PARTY then return getValue(DB_SHOW_PARTY, defaults.showParty) == true end
	return getValue(DB_SHOW_SOLO, defaults.showSolo) == true
end

function Reminder:ShouldRegisterRuntimeEvents()
	if getValue(DB_ENABLED, defaults.enabled) ~= true then return false end
	if self.runtimeProviderValid ~= true then self:RefreshProviderCache(false) end
	if self.hasProviderCached == true then return true end
	return self:IsFlaskTrackingEnabled() or self:IsFoodTrackingEnabled() or self:IsRuneTrackingEnabled() or self:IsWeaponBuffTrackingEnabled() or self:IsPetTrackingEnabled()
end

function Reminder:Render(provider, missing, total, supplementalEntries, effectiveMissing)
	local frame = self:EnsureFrame()
	if not frame then return end

	local displayMode = normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode))
	local title = self:GetProviderName(provider)
	local selfMissingEntries = self:GetSelfMissingEntries(provider)
	local supplemental = type(supplementalEntries) == "table" and supplementalEntries or nil
	local iconEntries
	local summaryEntries

	if provider and provider.scope == PROVIDER_SCOPE_SELF then
		summaryEntries = {}
		if type(selfMissingEntries) == "table" and #selfMissingEntries > 0 then appendMissingEntries(summaryEntries, selfMissingEntries) end
		if supplemental and #supplemental > 0 then appendMissingEntries(summaryEntries, supplemental) end
		if #summaryEntries <= 0 then summaryEntries = nil end
		iconEntries = summaryEntries
	elseif supplemental and #supplemental > 0 then
		summaryEntries = supplemental
		iconEntries = {}
		if tonumber(missing) and missing > 0 then iconEntries[#iconEntries + 1] = makeSelfMissingEntry(provider and provider.displaySpellId, title, missing, total) end
		appendMissingEntries(iconEntries, supplemental)
	end

	self:HideSelfMissingIcons()
	if displayMode == DISPLAY_MODE_ICON_ONLY then
		if iconEntries and #iconEntries > 0 then
			if frame.iconCountText then frame.iconCountText:SetText("") end
		else
			local shortFmt = L["ClassBuffReminderCountOnlyFmt"] or "%d/%d"
			if frame.iconCountText then frame.iconCountText:SetText(string.format(shortFmt, missing, total)) end
		end
	else
		frame.nameText:SetText(title)
		if provider and provider.scope == PROVIDER_SCOPE_SELF then
			frame.countText:SetText(self:GetSelfMissingSummaryText(summaryEntries))
		elseif summaryEntries and #summaryEntries > 0 then
			if tonumber(missing) and missing > 0 then
				local missingText = L["ClassBuffReminderMissingFmt"] or "%d/%d missing"
				local buffMissingText = string.format(missingText, missing, total)
				local supplementalText = self:GetSelfMissingSummaryText(summaryEntries)
				if supplementalText and supplementalText ~= "" then
					frame.countText:SetText(buffMissingText .. ", " .. supplementalText)
				else
					frame.countText:SetText(buffMissingText)
				end
			else
				frame.countText:SetText(self:GetSelfMissingSummaryText(summaryEntries))
			end
		else
			local missingText = L["ClassBuffReminderMissingFmt"] or "%d/%d missing"
			frame.countText:SetText(string.format(missingText, missing, total))
		end
	end

	local providerIcon = self:GetProviderIcon(provider)
	local canRenderSupplementalIcons = provider and provider.isSupplementalOnly == true and iconEntries and #iconEntries > 0
	if providerIcon == ICON_MISSING and self.editModeActive ~= true and canRenderSupplementalIcons ~= true then
		self:SetGlowShown(false)
		frame:Hide()
		self:RequestProviderPresentationRefresh(provider)
		return
	end
	frame.icon:SetTexture(providerIcon)
	self:ApplyVisualSettings()
	if displayMode == DISPLAY_MODE_ICON_ONLY and iconEntries and #iconEntries > 0 and self.editModeActive ~= true then self:RenderSelfMissingIcons(iconEntries) end
	if displayMode ~= DISPLAY_MODE_ICON_ONLY then
		local hasVisibleMissing = (tonumber(effectiveMissing) or tonumber(missing) or 0) > 0
		if hasVisibleMissing then
			if frame.countText then frame.countText:SetTextColor(1, 0.25, 0.25, 1) end
		else
			if frame.countText then frame.countText:SetTextColor(0.35, 1, 0.35, 1) end
		end
	end
	frame:Show()

	local showGlow = getValue(DB_GLOW, defaults.glow) == true and ((tonumber(effectiveMissing) or tonumber(missing) or 0) > 0)
	self:SetGlowShown(showGlow)
end

function Reminder:RenderEditModePreview()
	local frame = self:EnsureFrame()
	if not frame then return end

	local displayMode = normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode))
	local provider = self:GetProvider()
	if provider then
		self:Render(provider, 2, 5)
		if displayMode ~= DISPLAY_MODE_ICON_ONLY then frame.countText:SetTextColor(1, 0.82, 0, 1) end
	else
		frame.icon:SetTexture(ICON_MISSING)
		if displayMode == DISPLAY_MODE_ICON_ONLY then
			if frame.iconCountText then frame.iconCountText:SetText("0/0") end
		else
			frame.nameText:SetText(L["Class Buff Reminder"] or "Class Buff Reminder")
			frame.countText:SetText(L["ClassBuffReminderNoProvider"] or "No class buff configured for this class")
			frame.countText:SetTextColor(1, 0.82, 0, 1)
		end
		self:ApplyVisualSettings()
		frame:Show()
		self:SetGlowShown(false)
	end
end

function Reminder:ResetExpirationWarningCandidate()
	self.nextExpirationWarningAt = nil
end

function Reminder:QueueExpirationWarningAt(timestamp)
	local thresholdSeconds = self:GetExpirationWarningSeconds()
	if thresholdSeconds <= 0 then return end
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then return end
	local now = nowSeconds()
	if timestamp <= now then return end
	if not self.nextExpirationWarningAt or timestamp < self.nextExpirationWarningAt then self.nextExpirationWarningAt = timestamp end
end

function Reminder:CancelExpirationWarningTimer()
	if self.expirationWarningTimer then
		self.expirationWarningTimer:Cancel()
		self.expirationWarningTimer = nil
	end
	self.expirationWarningTimerAt = nil
end

function Reminder.RunExpirationWarningTimer()
	Reminder.expirationWarningTimer = nil
	Reminder.expirationWarningTimerAt = nil
	Reminder:MarkAuraStatesDirty()
	Reminder:RequestUpdate(true)
end

function Reminder:ScheduleExpirationWarningTimer()
	if self:GetExpirationWarningSeconds() <= 0 then
		self:CancelExpirationWarningTimer()
		return
	end
	local at = tonumber(self.nextExpirationWarningAt)
	if not at then
		self:CancelExpirationWarningTimer()
		return
	end
	local delay = at - nowSeconds()
	if delay < 0.05 then delay = 0.05 end
	if self.expirationWarningTimer and self.expirationWarningTimerAt and math.abs(self.expirationWarningTimerAt - at) < 0.05 then return end
	self:CancelExpirationWarningTimer()
	if C_Timer and C_Timer.NewTimer then
		self.expirationWarningTimerAt = at
		self.expirationWarningTimer = C_Timer.NewTimer(delay, Reminder.RunExpirationWarningTimer)
	end
end

function Reminder:UpdateDisplay()
	self:FlushPendingAuraUpdates()
	local frame = self:EnsureFrame()
	if not frame then return end

	if self.editModeActive == true then
		self:CancelExpirationWarningTimer()
		self.missingActive = false
		self:RenderEditModePreview()
		return
	end

	self:ResetExpirationWarningCandidate()

	if frame.iconCountText then frame.iconCountText:SetText("") end
	if frame.countText then frame.countText:SetText("") end
	self:HideSamplePreview()
	self:HideSelfMissingIcons()

	if getValue(DB_ENABLED, defaults.enabled) ~= true then
		self:CancelExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	local groupModeAllowed = self:IsGroupModeAllowed()
	local petSoloModeAllowed = groupModeAllowed ~= true and self:GetGroupContext() == GROUP_CONTEXT_SOLO and self:CanCheckPetReminder()
	if groupModeAllowed ~= true and petSoloModeAllowed ~= true then
		self:CancelExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	if self:IsHideInRestedAreaEnabled() == true and self:IsPlayerInRestedArea() == true then
		self:CancelExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	if not canEvaluateUnit("player") then
		self:CancelExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	if self:IsRuntimeEvaluationBlockedByCombat() then
		self:CancelExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	local classProvider = self:GetProvider()
	if groupModeAllowed ~= true then classProvider = nil end
	if classProvider and classProvider.scope == PROVIDER_SCOPE_GROUP and self:ShouldEvaluateGroupResponsibilities(classProvider) ~= true then classProvider = nil end

	local provider = classProvider
	if not provider then
		if petSoloModeAllowed == true then
			provider = self:GetPetOnlyProvider()
		elseif self:CanCheckFlaskReminder() then
			provider = self:GetFlaskOnlyProvider()
		elseif self:CanCheckFoodReminder() then
			provider = self:GetFoodOnlyProvider()
		elseif self:CanCheckRuneReminder() then
			provider = self:GetRuneOnlyProvider()
		elseif self:CanCheckWeaponBuffReminder() then
			provider = self:GetWeaponBuffOnlyProvider()
		elseif self:CanCheckPetReminder() then
			provider = self:GetPetOnlyProvider()
		else
			self:CancelExpirationWarningTimer()
			self:SetGlowShown(false)
			self.missingActive = false
			frame:Hide()
			return
		end
	end

	local missing, total = 0, 0
	if classProvider then
		missing, total = self:ComputeMissing(classProvider)
	end
	local supplementalContext = { onlyPetReminder = petSoloModeAllowed == true }
	local supplementalEntries = self:GetSupplementalMissingEntries(supplementalContext)
	local supplementalMissing = type(supplementalEntries) == "table" and #supplementalEntries or 0
	local primarySupplementalEntry = type(supplementalEntries) == "table" and supplementalEntries[1] or nil
	if total <= 0 and primarySupplementalEntry then
		if primarySupplementalEntry.sourceKind == "FLASK" then
			provider = self:GetFlaskOnlyProvider() or provider
		elseif primarySupplementalEntry.sourceKind == "FOOD" then
			provider = self:GetFoodOnlyProvider() or provider
		elseif primarySupplementalEntry.sourceKind == "RUNES" then
			provider = self:GetRuneOnlyProvider() or provider
		elseif primarySupplementalEntry.sourceKind == "WEAPON_BUFF" then
			provider = self:GetWeaponBuffOnlyProvider() or provider
		elseif primarySupplementalEntry.sourceKind == "PET" then
			provider = self:GetPetOnlyProvider() or provider
		end
		if provider then
			local entrySpellId = normalizeSpellId(primarySupplementalEntry.spellId)
			local entryIcon = Reminder.NormalizeIconTexture(primarySupplementalEntry.icon)
			if entrySpellId then provider.displaySpellId = entrySpellId end
			provider.displayIcon = entryIcon or Reminder.NormalizeIconTexture(provider.displayIcon)
			provider.cachedIcon = Reminder.NormalizeIconTexture(provider.displayIcon)
			provider.cachedName = primarySupplementalEntry.label or provider.fallbackName or (L["ClassBuffReminderWeaponBuff"] or "Weapon buff")
			provider._presentationReady = provider.cachedIcon ~= nil
			provider._presentationAttempted = provider.cachedIcon ~= nil
		end
	end
	if total <= 0 and supplementalMissing <= 0 then
		self:ScheduleExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	local effectiveMissing = (tonumber(missing) or 0) + supplementalMissing

	if self.suppressNextMissingSound == true and effectiveMissing <= 0 then self.suppressNextMissingSound = false end

	if effectiveMissing <= 0 then
		self:ScheduleExpirationWarningTimer()
		self:SetGlowShown(false)
		self.missingActive = false
		frame:Hide()
		return
	end

	self:UpdateMissingStateAndSound(effectiveMissing)

	self:Render(provider, missing, total, supplementalEntries, effectiveMissing)
	self:ScheduleExpirationWarningTimer()
end

function Reminder:RequestUpdate(immediate, delay, reschedule)
	if immediate or not (C_Timer and C_Timer.After) then
		if self.updateTimer then
			self.updateTimer:Cancel()
			self.updateTimer = nil
		end
		self.updatePending = false
		self.updateDelay = nil
		self:UpdateDisplay()
		return
	end

	local updateDelay = tonumber(delay) or Reminder.UPDATE_DELAY
	if updateDelay < 0 then updateDelay = Reminder.UPDATE_DELAY end

	if self.updatePending then
		if reschedule == true and self.updateTimer then
			self.updateTimer:Cancel()
			self.updateDelay = updateDelay
			self.updateTimer = C_Timer.NewTimer(updateDelay, Reminder.RunPendingUpdateTimer)
		end
		return
	end
	self.updatePending = true
	self.updateDelay = updateDelay
	self.updateTimer = C_Timer.NewTimer(updateDelay, Reminder.RunPendingUpdateTimer)
end

function Reminder:HandleEvent(event, unit, updateInfo)
	if not self:ShouldRegisterRuntimeEvents() then return end

	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		self.consumableTrackingBlockedByCombat = InCombatLockdown and InCombatLockdown() == true or false
		self:ScheduleInitialSoundSync()
		self:InvalidateProviderAvailabilityCache()
		self:InvalidateRosterCache()
		self:MarkAuraStatesDirty()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false)
		self:ScheduleDeferredAuraResync(0.35)
		return
	end

	if event == "GROUP_ROSTER_UPDATE" then
		self:InvalidateRosterCache()
		self:RequestUpdate(false, Reminder.ROSTER_UPDATE_DELAY, true)
		self:ScheduleDeferredAuraResync(1.0)
		return
	end

	if event == "UNIT_PHASE" then
		self:MarkAuraStatesDirty()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "PLAYER_ROLES_ASSIGNED" or event == "ROLE_CHANGED_INFORM" then
		self:InvalidateSelfProviderStatus()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "READY_CHECK" then
		self:MarkAuraStatesDirty()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		self:ScheduleDeferredAuraResync(0.2)
		self:ScheduleDeferredAuraResync(1.0)
		return
	end

	if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		self.consumableTrackingBlockedByCombat = (event == "PLAYER_REGEN_DISABLED")
		if self:IsOnlyOutOfCombatEnabled() == true then self:MarkAuraStatesDirty() end
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "PLAYER_UPDATE_RESTING" then
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if
		event == "ZONE_CHANGED"
		or event == "ZONE_CHANGED_INDOORS"
		or event == "ZONE_CHANGED_NEW_AREA"
		or event == "CHALLENGE_MODE_START"
		or event == "CHALLENGE_MODE_COMPLETED"
		or event == "CHALLENGE_MODE_RESET"
		or event == "ENCOUNTER_START"
		or event == "ENCOUNTER_END"
	then
		self:MarkAuraStatesDirty()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "SPELLS_CHANGED" then
		self:InvalidateProviderAvailabilityCache()
		self:InvalidateSelfProviderStatus()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "UNIT_INVENTORY_CHANGED" then
		if unit == "player" then
			self:InvalidateSelfProviderStatus()
			self:InvalidateFlaskCache()
			self:InvalidateFoodCache()
			self:InvalidateRuneCache()
			self:InvalidateWeaponBuffCache()
			self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY)
		end
		return
	end

	if event == "PLAYER_EQUIPMENT_CHANGED" then
		self:InvalidateSelfProviderStatus()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY)
		return
	end

	if event == "BAG_UPDATE_DELAYED" then
		self:InvalidateSelfProviderStatus()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY)
		return
	end

	if event == "PLAYER_LEVEL_UP" then
		self:InvalidateProviderAvailabilityCache()
		self:InvalidateSelfProviderStatus()
		self:InvalidateFlaskCache()
		self:InvalidateFoodCache()
		self:InvalidateRuneCache()
		self:InvalidateWeaponBuffCache()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
		self:MarkAuraStatesDirty()
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "UNIT_PET" or event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_USABLE" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" or (event == "UNIT_FLAGS" and unit == "pet") then
		Reminder.petTracking.cachedStance = nil
		self:RequestUpdate(false, Reminder.RUNTIME_UPDATE_DELAY, true)
		return
	end

	if event == "UNIT_AURA" then
		if not isTrackedUnit(unit) then return end
		if self:IsRuntimeEvaluationBlockedByCombat() then return end
		local playerUnit = isPlayerUnit(unit)
		if playerUnit and self:IsPetTrackingEnabled() then self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY) end
		local provider = self:GetProvider()
		local supplementalTouches = playerUnit and self:SupplementalAuraUpdateTouchesPlayer(updateInfo) or false
		if provider and provider.scope == PROVIDER_SCOPE_GROUP and self:ShouldEvaluateGroupResponsibilities(provider) ~= true then
			if supplementalTouches then
				self.playerAuraPresenceSnapshot = nil
				self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY)
			end
			return
			end
			if provider and provider.scope == PROVIDER_SCOPE_SELF then
				local needsUpdate = false
				local providerTouches = playerUnit and self:ProviderAuraUpdateTouchesUnit(unit, updateInfo, provider) or false
				local groupCacheTouches = provider.tracksExternalUnitAuras == true and self:GroupBuffCacheAuraUpdateTouchesUnit(unit, updateInfo) or false
				if groupCacheTouches then
					if self:ApplyDeltaToGroupBuffStateCaches(unit, updateInfo) == true then
						self:InvalidateSelfProviderStatus()
						needsUpdate = true
					end
				end
				if providerTouches then
					self:InvalidateSelfProviderStatus()
					needsUpdate = true
			end
			if supplementalTouches then
				self.playerAuraPresenceSnapshot = nil
				needsUpdate = true
			end
			if needsUpdate then self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY) end
			return
		end
		if provider and isAIFollowerUnit(unit) then
			self:QueuePendingAuraReset(unit)
			self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY)
			return
		end
		if provider and self:ProviderAuraUpdateTouchesUnit(unit, updateInfo, provider) then
			self:QueuePendingAuraDelta(unit, updateInfo)
			self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY)
			return
		end
		if supplementalTouches then
			self.playerAuraPresenceSnapshot = nil
			self:RequestUpdate(false, Reminder.AURA_UPDATE_DELAY)
		end
		return
	end
end

function Reminder:RegisterEvents()
	if not self:ShouldRegisterRuntimeEvents() then
		self:UnregisterEvents()
		return
	end

	if self.eventsRegistered then return end

	self.eventFrame = self.eventFrame or CreateFrame("Frame")
	self.eventFrame:RegisterEvent("PLAYER_LOGIN")
	self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	self.eventFrame:RegisterEvent("UNIT_PHASE")
	self.eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	self.eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
	self.eventFrame:RegisterEvent("READY_CHECK")
	self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	self.eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
	self.eventFrame:RegisterEvent("ZONE_CHANGED")
	self.eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self.eventFrame:RegisterEvent("CHALLENGE_MODE_START")
	self.eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	self.eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
	self.eventFrame:RegisterEvent("ENCOUNTER_START")
	self.eventFrame:RegisterEvent("ENCOUNTER_END")
	self.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
	self.eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	self.eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self.eventFrame:RegisterEvent("SPELLS_CHANGED")
	self.eventFrame:RegisterEvent("UNIT_AURA")
	self.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self.eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	self.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
	self.eventFrame:RegisterEvent("PLAYER_DEAD")
	self.eventFrame:RegisterEvent("PLAYER_ALIVE")
	self.eventFrame:RegisterEvent("PLAYER_UNGHOST")
	self.eventFrame:RegisterEvent("PET_BAR_UPDATE")
	self.eventFrame:RegisterEvent("PET_BAR_UPDATE_USABLE")
	self.eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	self.eventFrame:RegisterUnitEvent("UNIT_PET", "player")
	self.eventFrame:RegisterUnitEvent("UNIT_FLAGS", "pet")
	self.eventFrame:SetScript("OnEvent", function(_, event, ...) Reminder:HandleEvent(event, ...) end)

	self.eventsRegistered = true
	self:SetupPetTrackingHooks()
	self:ScheduleInitialSoundSync()
end

function Reminder:UnregisterEvents()
	if not self.eventFrame then return end
	self.eventFrame:UnregisterAllEvents()
	self.eventFrame:SetScript("OnEvent", nil)
	self.eventsRegistered = false
end

local function editModeSetBool(key, value)
	if addon.db then addon.db[key] = value == true end
	Reminder:RequestUpdate(true)
end

local function editModeSetNumber(key, value, minValue, maxValue, fallback)
	if not addon.db then return end
	addon.db[key] = clamp(value, minValue, maxValue, fallback)
	Reminder:ApplyVisualSettings()
	Reminder:RequestUpdate(true)
end

local function editModeSetColor(key, value, fallback)
	if not addon.db then return end
	local r, g, b, a = normalizeColor(value, fallback)
	addon.db[key] = { r = r, g = g, b = b, a = a }
	Reminder:ApplyVisualSettings()
	Reminder:RequestUpdate(true)
end

local function editModeSetGlowStyle(value)
	if addon.db then addon.db[DB_GLOW_STYLE] = normalizeGlowStyle(value) end
	Reminder:RequestUpdate(true)
end

local function editModeSetGlowInset(value)
	if addon.db then addon.db[DB_GLOW_INSET] = normalizeGlowInset(value) end
	Reminder:RequestUpdate(true)
end

local function editModeSetDisplayMode(value)
	if addon.db then addon.db[DB_DISPLAY_MODE] = normalizeDisplayMode(value) end
	Reminder:ApplyVisualSettings()
	Reminder:RequestUpdate(true)
end

local function editModeSetGrowthDirection(value)
	if addon.db then addon.db[DB_GROWTH_DIRECTION] = normalizeGrowthDirection(value) end
	Reminder:ApplyVisualSettings()
	Reminder:RequestUpdate(true)
end

local function editModeSetGrowthFromCenter(value)
	if addon.db then addon.db[DB_GROWTH_FROM_CENTER] = value == true end
	Reminder:ApplyVisualSettings()
	Reminder:RequestUpdate(true)
end

function Reminder.EditModeRefreshRuntimeAfterTrackingChange()
	if Reminder.OnSettingChanged then
		Reminder:OnSettingChanged()
	else
		Reminder:RequestUpdate(true)
	end
end

local function editModeSetTrackFlasks(value)
	if addon.db then addon.db[DB_TRACK_FLASKS] = value == true end
	Reminder:InvalidateFlaskCache()
	Reminder.EditModeRefreshRuntimeAfterTrackingChange()
end

local function editModeSetTrackFood(value)
	if addon.db then addon.db[DB_TRACK_FOOD] = value == true end
	Reminder:InvalidateFoodCache()
	Reminder.EditModeRefreshRuntimeAfterTrackingChange()
end

local function editModeSetRoleFilterContext(value)
	if addon.db then addon.db[DB_ROLE_FILTER_CONTEXT] = normalizeRoleFilterContext(value) end
	Reminder:RequestUpdate(true)
end

function Reminder:EditModeSetMissingSound(value)
	if addon.db then
		local _, map, pathToKey = self:GetMissingSoundOptions()
		local chosen = type(value) == "string" and value or ""
		if chosen ~= "" and map and map[chosen] then
			-- keep chosen key
		elseif chosen ~= "" and pathToKey and pathToKey[chosen] and map[pathToKey[chosen]] then
			chosen = pathToKey[chosen]
		else
			chosen = ""
		end
		addon.db[DB_MISSING_SOUND] = chosen or ""
	end
	self.initialSoundSyncDone = false
	self:NormalizeMissingSoundSelection()
	self:ScheduleInitialSoundSync()
	self:RequestUpdate(true)
end

function Reminder:IsEditModeIconOnlyModeActive() return normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode)) == DISPLAY_MODE_ICON_ONLY end

local editModeSettingsBuilders = {}

function editModeSettingsBuilders.appendEntries(target, entries)
	if type(target) ~= "table" or type(entries) ~= "table" then return end
	for i = 1, #entries do
		target[#target + 1] = entries[i]
	end
end

function editModeSettingsBuilders.buildClassBuffs()
	return {
		{
			name = L["ClassBuffReminderSectionClassBuffs"] or "Class Buffs",
			kind = SettingType.Collapsible,
			id = "classBuffs",
			defaultCollapsed = false,
		},
		{
			name = L["ClassBuffReminderShowParty"] or "Track in party",
			kind = SettingType.Checkbox,
			parentId = "classBuffs",
			default = defaults.showParty,
			get = function() return getValue(DB_SHOW_PARTY, defaults.showParty) == true end,
			set = function(_, value) editModeSetBool(DB_SHOW_PARTY, value) end,
		},
		{
			name = L["ClassBuffReminderShowRaid"] or "Track in raid",
			kind = SettingType.Checkbox,
			parentId = "classBuffs",
			default = defaults.showRaid,
			get = function() return getValue(DB_SHOW_RAID, defaults.showRaid) == true end,
			set = function(_, value) editModeSetBool(DB_SHOW_RAID, value) end,
		},
		{
			name = L["ClassBuffReminderShowSolo"] or "Show while solo",
			kind = SettingType.Checkbox,
			parentId = "classBuffs",
			default = defaults.showSolo,
			get = function() return getValue(DB_SHOW_SOLO, defaults.showSolo) == true end,
			set = function(_, value) editModeSetBool(DB_SHOW_SOLO, value) end,
		},
		{
			name = L["ClassBuffReminderExpirationWarningMinutes"] or "Show before expiration",
			kind = SettingType.Slider,
			parentId = "classBuffs",
			default = defaults.expirationWarningMinutes or 0,
			minValue = 0,
			maxValue = 60,
			valueStep = 1,
			get = function() return Reminder:GetExpirationWarningMinutes() end,
			set = function(_, value) Reminder:SetExpirationWarningMinutes(value) end,
			formatter = function(value)
				local minutes = Reminder:NormalizeExpirationWarningMinutes(value)
				if minutes <= 0 then return L["ClassBuffReminderExpirationWarningOff"] or "Missing only" end
				return string.format(L["ClassBuffReminderExpirationWarningMinutesFmt"] or "%d min", minutes)
			end,
			tooltip = L["ClassBuffReminderExpirationWarningMinutesDesc"] or "0 keeps the current behavior. Higher values show the reminder when a tracked buff has this many minutes or less remaining.",
		},
		{
			name = L["ClassBuffReminderHideInRestedArea"] or "Don't show in rested areas",
			kind = SettingType.Checkbox,
			parentId = "classBuffs",
			default = defaults.hideInRestedArea == true,
			get = function() return getValue(DB_HIDE_IN_RESTED_AREA, defaults.hideInRestedArea) == true end,
			set = function(_, value) editModeSetBool(DB_HIDE_IN_RESTED_AREA, value) end,
		},
		{
			name = L["ClassBuffReminderGlow"] or "Glow when missing",
			kind = SettingType.Checkbox,
			parentId = "classBuffs",
			default = defaults.glow,
			get = function() return getValue(DB_GLOW, defaults.glow) == true end,
			set = function(_, value) editModeSetBool(DB_GLOW, value) end,
		},
		{
			name = L["Glow style"] or "Glow style",
			kind = SettingType.Dropdown,
			parentId = "classBuffs",
			height = 180,
			default = defaults.glowStyle,
			get = function() return normalizeGlowStyle(getValue(DB_GLOW_STYLE, defaults.glowStyle)) end,
			set = function(_, value) editModeSetGlowStyle(value) end,
			generator = function(_, root)
				for _, option in ipairs(Reminder.GLOW_STYLE_OPTIONS or {}) do
					local label = L[option.labelKey] or option.fallback
					root:CreateRadio(label, function() return normalizeGlowStyle(getValue(DB_GLOW_STYLE, defaults.glowStyle)) == option.value end, function() editModeSetGlowStyle(option.value) end)
				end
			end,
			isEnabled = function() return getValue(DB_GLOW, defaults.glow) == true end,
		},
		{
			name = L["Glow inset"] or "Glow inset",
			kind = SettingType.Slider,
			parentId = "classBuffs",
			default = defaults.glowInset,
			minValue = -(Reminder.GLOW_INSET_RANGE or 20),
			maxValue = Reminder.GLOW_INSET_RANGE or 20,
			valueStep = 1,
			get = function() return normalizeGlowInset(getValue(DB_GLOW_INSET, defaults.glowInset)) end,
			set = function(_, value) editModeSetGlowInset(value) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.glowInset or 0) + 0.5)) end,
			isEnabled = function() return getValue(DB_GLOW, defaults.glow) == true end,
		},
		{
			name = L["Glow color"] or "Glow color",
			kind = SettingType.Color,
			parentId = "classBuffs",
			default = defaults.glowColor,
			get = function()
				local r, g, b, a = Reminder:GetGlowColor()
				return { r = r, g = g, b = b, a = a }
			end,
			set = function(_, value) editModeSetColor("classBuffReminderGlowColor", value, defaults.glowColor) end,
			isEnabled = function() return getValue(DB_GLOW, defaults.glow) == true end,
		},
	}
end

function editModeSettingsBuilders.buildFilters()
	return {
		{
			name = L["ClassBuffReminderSectionFilters"] or "Tracking Filters",
			kind = SettingType.Collapsible,
			id = "filters",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderOnlyOutOfCombat"] or "Only show out of combat",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.onlyOutOfCombat == true,
			get = function() return getValue(DB_ONLY_OUT_OF_COMBAT, defaults.onlyOutOfCombat) == true end,
			set = function(_, value) editModeSetBool(DB_ONLY_OUT_OF_COMBAT, value) end,
		},
		{
			name = L["ClassBuffReminderRoleFilterEnabled"] or "Enable role responsibility filter",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.roleFilterEnabled == true,
			get = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
			set = function(_, value) editModeSetBool(DB_ROLE_FILTER_ENABLED, value) end,
		},
		{
			name = L["ClassBuffReminderRoleFilterContext"] or "Apply role filter in",
			kind = SettingType.Dropdown,
			parentId = "filters",
			height = 120,
			default = defaults.roleFilterContext,
			get = function() return normalizeRoleFilterContext(getValue(DB_ROLE_FILTER_CONTEXT, defaults.roleFilterContext)) end,
			set = function(_, value) editModeSetRoleFilterContext(value) end,
			generator = function(_, root)
				root:CreateRadio(
					L["ClassBuffReminderRoleFilterContextAnyGroup"] or "Any group",
					function() return normalizeRoleFilterContext(getValue(DB_ROLE_FILTER_CONTEXT, defaults.roleFilterContext)) == ROLE_FILTER_CONTEXT_ANY_GROUP end,
					function() editModeSetRoleFilterContext(ROLE_FILTER_CONTEXT_ANY_GROUP) end
				)
				root:CreateRadio(
					L["ClassBuffReminderRoleFilterContextRaidOnly"] or "Raid only",
					function() return normalizeRoleFilterContext(getValue(DB_ROLE_FILTER_CONTEXT, defaults.roleFilterContext)) == ROLE_FILTER_CONTEXT_RAID_ONLY end,
					function() editModeSetRoleFilterContext(ROLE_FILTER_CONTEXT_RAID_ONLY) end
				)
				root:CreateRadio(
					L["ClassBuffReminderRoleFilterContextPartyOnly"] or "Party only",
					function() return normalizeRoleFilterContext(getValue(DB_ROLE_FILTER_CONTEXT, defaults.roleFilterContext)) == ROLE_FILTER_CONTEXT_PARTY_ONLY end,
					function() editModeSetRoleFilterContext(ROLE_FILTER_CONTEXT_PARTY_ONLY) end
				)
			end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
		{
			name = L["ClassBuffReminderHideForHealer"] or "Hide reminder for healers",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.hideForHealer == true,
			get = function() return getValue(DB_HIDE_FOR_HEALER, defaults.hideForHealer) == true end,
			set = function(_, value) editModeSetBool(DB_HIDE_FOR_HEALER, value) end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
		{
			name = L["ClassBuffReminderHideForTank"] or "Hide reminder for tanks",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.hideForTank == true,
			get = function() return getValue(DB_HIDE_FOR_TANK, defaults.hideForTank) == true end,
			set = function(_, value) editModeSetBool(DB_HIDE_FOR_TANK, value) end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
		{
			name = L["ClassBuffReminderHideForDamager"] or "Hide reminder for damage dealers",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.hideForDamager == true,
			get = function() return getValue(DB_HIDE_FOR_DAMAGER, defaults.hideForDamager) == true end,
			set = function(_, value) editModeSetBool(DB_HIDE_FOR_DAMAGER, value) end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
		{
			name = L["ClassBuffReminderHideForNoRole"] or "Hide reminder for unassigned roles",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.hideForNoRole == true,
			get = function() return getValue(DB_HIDE_FOR_NONE, defaults.hideForNoRole) == true end,
			set = function(_, value) editModeSetBool(DB_HIDE_FOR_NONE, value) end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
		{
			name = L["ClassBuffReminderShowIfOnlyProvider"] or "Show when I am the only class provider",
			kind = SettingType.Checkbox,
			parentId = "filters",
			default = defaults.showIfOnlyProvider ~= false,
			get = function() return getValue(DB_SHOW_IF_ONLY_PROVIDER, defaults.showIfOnlyProvider) == true end,
			set = function(_, value) editModeSetBool(DB_SHOW_IF_ONLY_PROVIDER, value) end,
			isShown = function() return getValue(DB_ROLE_FILTER_ENABLED, defaults.roleFilterEnabled) == true end,
		},
	}
end

function editModeSettingsBuilders.buildConsumables()
	return {
		{
			name = L["ClassBuffReminderSectionFlasks"] or "Flasks",
			kind = SettingType.Collapsible,
			id = "flasks",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderTrackFlasks"] or "Track missing flask buff",
			kind = SettingType.Checkbox,
			parentId = "flasks",
			default = defaults.trackFlasks == true,
			get = function() return getValue(DB_TRACK_FLASKS, defaults.trackFlasks) == true end,
			set = function(_, value) editModeSetTrackFlasks(value) end,
		},
		{
			name = L["ClassBuffReminderTrackingContent"] or "Active in content",
			kind = SettingType.MultiDropdown,
			parentId = "flasks",
			height = 260,
			default = defaults.trackFlasksContent,
			options = Reminder:GetTrackingContentOptions(),
			get = function() return Reminder:GetFlaskTrackingContentSelection() end,
			set = function(_, value) Reminder:SetFlaskTrackingContentSelection(value) end,
			tooltip = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
			customDefaultText = _G.NONE or "None",
			hideSummary = true,
			isShown = function() return getValue(DB_TRACK_FLASKS, defaults.trackFlasks) == true end,
		},
		{
			name = L["ClassBuffReminderSectionFood"] or "Food",
			kind = SettingType.Collapsible,
			id = "food",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderTrackFood"] or "Track missing food buff",
			kind = SettingType.Checkbox,
			parentId = "food",
			default = defaults.trackFood == true,
			get = function() return getValue(DB_TRACK_FOOD, defaults.trackFood) == true end,
			set = function(_, value) editModeSetTrackFood(value) end,
		},
		{
			name = L["ClassBuffReminderTrackingContent"] or "Active in content",
			kind = SettingType.MultiDropdown,
			parentId = "food",
			height = 260,
			default = defaults.trackFoodContent,
			options = Reminder:GetTrackingContentOptions(),
			get = function() return Reminder:GetFoodTrackingContentSelection() end,
			set = function(_, value) Reminder:SetFoodTrackingContentSelection(value) end,
			tooltip = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
			customDefaultText = _G.NONE or "None",
			hideSummary = true,
			isShown = function() return getValue(DB_TRACK_FOOD, defaults.trackFood) == true end,
		},
		{
			name = L["ClassBuffReminderSectionRunes"] or "Augment Runes",
			kind = SettingType.Collapsible,
			id = "runes",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderTrackRunes"] or "Track missing augment rune",
			kind = SettingType.Checkbox,
			parentId = "runes",
			default = defaults.trackRunes == true,
			get = function() return getValue(Reminder.runeTracking.enabledDb, defaults.trackRunes) == true end,
			set = function(_, value)
				if addon.db then addon.db[Reminder.runeTracking.enabledDb] = value == true end
				Reminder:InvalidateRuneCache()
				Reminder.EditModeRefreshRuntimeAfterTrackingChange()
			end,
		},
		{
			name = L["ClassBuffReminderTrackingContent"] or "Active in content",
			kind = SettingType.MultiDropdown,
			parentId = "runes",
			height = 260,
			default = defaults.trackRunesContent,
			options = Reminder:GetTrackingContentOptions(),
			get = function() return Reminder:GetRuneTrackingContentSelection() end,
			set = function(_, value) Reminder:SetRuneTrackingContentSelection(value) end,
			tooltip = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
			customDefaultText = _G.NONE or "None",
			hideSummary = true,
			isShown = function() return getValue(Reminder.runeTracking.enabledDb, defaults.trackRunes) == true end,
		},
		{
			name = L["ClassBuffReminderSectionWeaponBuffs"] or "Weapon Buffs",
			kind = SettingType.Collapsible,
			id = "weaponBuffs",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderTrackWeaponBuffs"] or "Track missing weapon oil/stone",
			kind = SettingType.Checkbox,
			parentId = "weaponBuffs",
			default = defaults.trackWeaponBuffs == true,
			get = function() return getValue(DB_TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs) == true end,
			set = function(_, value)
				if addon.db then addon.db[DB_TRACK_WEAPON_BUFFS] = value == true end
				Reminder:InvalidateWeaponBuffCache()
				Reminder.EditModeRefreshRuntimeAfterTrackingChange()
			end,
		},
		{
			name = L["ClassBuffReminderTrackingContent"] or "Active in content",
			kind = SettingType.MultiDropdown,
			parentId = "weaponBuffs",
			height = 260,
			default = defaults.trackWeaponBuffsContent,
			options = Reminder:GetTrackingContentOptions(),
			get = function() return Reminder:GetWeaponBuffTrackingContentSelection() end,
			set = function(_, value) Reminder:SetWeaponBuffTrackingContentSelection(value) end,
			tooltip = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
			customDefaultText = _G.NONE or "None",
			hideSummary = true,
			isShown = function() return getValue(DB_TRACK_WEAPON_BUFFS, defaults.trackWeaponBuffs) == true end,
		},
		{
			name = L["ClassBuffReminderSectionPets"] or "Pets",
			kind = SettingType.Collapsible,
			id = "pets",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderTrackPets"] or "Track pet reminders",
			kind = SettingType.Checkbox,
			parentId = "pets",
			default = defaults.trackPets == true,
			get = function() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderTrackPets"] = value == true end
				Reminder.EditModeRefreshRuntimeAfterTrackingChange()
			end,
		},
		{
			name = L["ClassBuffReminderIgnorePetPassive"] or "Ignore passive pet stance",
			kind = SettingType.Checkbox,
			parentId = "pets",
			default = defaults.ignorePetPassive,
			get = function() return getValue("classBuffReminderIgnorePetPassive", defaults.ignorePetPassive) == true end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderIgnorePetPassive"] = value == true end
				Reminder:RequestUpdate(true, 0, true)
			end,
			isShown = function() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end,
		},
		{
			name = L["ClassBuffReminderIgnorePetDefensive"] or "Ignore defensive pet stance",
			kind = SettingType.Checkbox,
			parentId = "pets",
			default = defaults.ignorePetDefensive,
			get = function() return getValue("classBuffReminderIgnorePetDefensive", defaults.ignorePetDefensive) == true end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderIgnorePetDefensive"] = value == true end
				Reminder:RequestUpdate(true, 0, true)
			end,
			isShown = function() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end,
		},
		{
			name = L["ClassBuffReminderHidePetReminderText"] or "Hide pet reminder text",
			kind = SettingType.Checkbox,
			parentId = "pets",
			default = defaults.hidePetReminderText,
			get = function() return getValue("classBuffReminderHidePetReminderText", defaults.hidePetReminderText) == true end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderHidePetReminderText"] = value == true end
				Reminder:RequestUpdate(true, 0, true)
			end,
			isShown = function() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end,
		},
		{
			name = L["ClassBuffReminderTrackingContent"] or "Active in content",
			kind = SettingType.MultiDropdown,
			parentId = "pets",
			height = 260,
			default = defaults.trackPetsContent,
			options = Reminder:GetTrackingContentOptions(),
			get = function() return Reminder:GetPetTrackingContentSelection() end,
			set = function(_, value) Reminder:SetPetTrackingContentSelection(value) end,
			tooltip = L["ClassBuffReminderTrackingContentDesc"] or "Choose where this reminder should be active. Multiple entries can be selected.",
			customDefaultText = _G.NONE or "None",
			hideSummary = true,
			isShown = function() return getValue("classBuffReminderTrackPets", defaults.trackPets) == true end,
		},
	}
end

function editModeSettingsBuilders.buildSound()
	return {
		{
			name = SOUND,
			kind = SettingType.Collapsible,
			id = "sound",
			defaultCollapsed = true,
		},
		{
			name = L["ClassBuffReminderSoundOnMissing"] or "Play sound when missing",
			kind = SettingType.Checkbox,
			parentId = "sound",
			default = defaults.soundOnMissing,
			get = function() return getValue(DB_SOUND_ON_MISSING, defaults.soundOnMissing) == true end,
			set = function(_, value) editModeSetBool(DB_SOUND_ON_MISSING, value) end,
		},
		{
			name = L["ClassBuffReminderMissingSound"] or "Missing sound",
			kind = SettingType.Dropdown,
			parentId = "sound",
			height = 260,
			get = function()
				Reminder:BuildMissingSoundOptions()
				return Reminder:GetMissingSoundValue()
			end,
			set = function(_, value) Reminder:EditModeSetMissingSound(value) end,
			generator = function(_, root)
				local keys = Reminder:BuildMissingSoundOptions()
				for i = 1, #keys do
					local soundName = keys[i]
					root:CreateRadio(soundName, function() return Reminder:GetMissingSoundValue() == soundName end, function()
						Reminder:EditModeSetMissingSound(soundName)
						Reminder:PlayMissingSound(true)
					end)
				end
			end,
			isEnabled = function() return getValue(DB_SOUND_ON_MISSING, defaults.soundOnMissing) == true end,
		},
	}
end

function editModeSettingsBuilders.buildLayout()
	return {
		{
			name = L["ClassBuffReminderSectionAnchorSize"] or "Anchor & Size",
			kind = SettingType.Collapsible,
			id = "anchorSize",
			defaultCollapsed = true,
		},
		{
			name = DISPLAY_MODE,
			kind = SettingType.Dropdown,
			parentId = "anchorSize",
			height = 80,
			get = function() return normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode)) end,
			set = function(_, value) editModeSetDisplayMode(value) end,
			generator = function(_, root)
				root:CreateRadio(
					L["ClassBuffReminderDisplayModeFull"] or "Full",
					function() return normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode)) == DISPLAY_MODE_FULL end,
					function() editModeSetDisplayMode(DISPLAY_MODE_FULL) end
				)
				root:CreateRadio(
					L["ClassBuffReminderDisplayModeIconOnly"] or "Icon only (X/Y)",
					function() return normalizeDisplayMode(getValue(DB_DISPLAY_MODE, defaults.displayMode)) == DISPLAY_MODE_ICON_ONLY end,
					function() editModeSetDisplayMode(DISPLAY_MODE_ICON_ONLY) end
				)
			end,
		},
		{
			name = L["Growth direction"] or "Growth direction",
			kind = SettingType.Dropdown,
			parentId = "anchorSize",
			height = 120,
			get = function() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) end,
			set = function(_, value) editModeSetGrowthDirection(value) end,
			generator = function(_, root)
				root:CreateRadio(
					L["Right"] or "Right",
					function() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) == GROWTH_RIGHT end,
					function() editModeSetGrowthDirection(GROWTH_RIGHT) end
				)
				root:CreateRadio(
					L["Left"] or "Left",
					function() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) == GROWTH_LEFT end,
					function() editModeSetGrowthDirection(GROWTH_LEFT) end
				)
				root:CreateRadio(
					L["Up"] or "Up",
					function() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) == GROWTH_UP end,
					function() editModeSetGrowthDirection(GROWTH_UP) end
				)
				root:CreateRadio(
					L["Down"] or "Down",
					function() return normalizeGrowthDirection(getValue(DB_GROWTH_DIRECTION, defaults.growthDirection)) == GROWTH_DOWN end,
					function() editModeSetGrowthDirection(GROWTH_DOWN) end
				)
			end,
		},
		{
			name = L["Grow from center"] or "Grow from center",
			kind = SettingType.Checkbox,
			parentId = "anchorSize",
			default = defaults.growthFromCenter == true,
			get = function() return getValue(DB_GROWTH_FROM_CENTER, defaults.growthFromCenter) == true end,
			set = function(_, value) editModeSetGrowthFromCenter(value) end,
		},
		{
			name = L["Scale"] or "Scale",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.scale,
			minValue = 0.5,
			maxValue = 2,
			valueStep = 0.05,
			get = function() return clamp(getValue(DB_SCALE, defaults.scale), 0.5, 2, defaults.scale) end,
			set = function(_, value) editModeSetNumber(DB_SCALE, value, 0.5, 2, defaults.scale) end,
			formatter = function(value) return string.format("%.2f", tonumber(value) or defaults.scale) end,
		},
		{
			name = L["Icon size"] or "Icon size",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.iconSize,
			minValue = 14,
			maxValue = 120,
			valueStep = 1,
			get = function() return clamp(getValue(DB_ICON_SIZE, defaults.iconSize), 14, 120, defaults.iconSize) end,
			set = function(_, value) editModeSetNumber(DB_ICON_SIZE, value, 14, 120, defaults.iconSize) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.iconSize) + 0.5)) end,
		},
		{
			name = L["Icon gap"] or "Icon gap",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.iconGap,
			minValue = 0,
			maxValue = 40,
			valueStep = 1,
			get = function() return clamp(getValue(DB_ICON_GAP, defaults.iconGap), 0, 40, defaults.iconGap) end,
			set = function(_, value) editModeSetNumber(DB_ICON_GAP, value, 0, 40, defaults.iconGap) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.iconGap) + 0.5)) end,
		},
		{
			name = FONT_SIZE,
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.fontSize,
			minValue = 9,
			maxValue = 30,
			valueStep = 1,
			get = function() return clamp(getValue(DB_FONT_SIZE, defaults.fontSize), 9, 30, defaults.fontSize) end,
			set = function(_, value) editModeSetNumber(DB_FONT_SIZE, value, 9, 30, defaults.fontSize) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.fontSize) + 0.5)) end,
			isShown = function() return not Reminder:IsEditModeIconOnlyModeActive() end,
		},
		{
			name = L["ClassBuffReminderXYTextSize"] or "X/Y text size",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.xyTextSize,
			minValue = 8,
			maxValue = 64,
			valueStep = 1,
			get = function() return clamp(getValue(DB_XY_TEXT_SIZE, defaults.xyTextSize), 8, 64, defaults.xyTextSize) end,
			set = function(_, value) editModeSetNumber(DB_XY_TEXT_SIZE, value, 8, 64, defaults.xyTextSize) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.xyTextSize) + 0.5)) end,
			isShown = function() return Reminder:IsEditModeIconOnlyModeActive() end,
		},
		{
			name = L["ClassBuffReminderXYTextOutline"] or "X/Y text outline",
			kind = SettingType.Dropdown,
			parentId = "anchorSize",
			height = 120,
			get = function() return normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)) end,
			set = function(_, value)
				if addon.db then addon.db[DB_XY_TEXT_OUTLINE] = normalizeTextOutline(value) end
				Reminder:ApplyVisualSettings()
				Reminder:RequestUpdate(true)
			end,
			generator = function(_, root)
				root:CreateRadio(
					NONE,
					function() return normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)) == TEXT_OUTLINE_NONE end,
					function()
						if addon.db then addon.db[DB_XY_TEXT_OUTLINE] = normalizeTextOutline(TEXT_OUTLINE_NONE) end
						Reminder:ApplyVisualSettings()
						Reminder:RequestUpdate(true)
					end
				)
				root:CreateRadio(
					L["Outline"] or "Outline",
					function() return normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)) == TEXT_OUTLINE_OUTLINE end,
					function()
						if addon.db then addon.db[DB_XY_TEXT_OUTLINE] = normalizeTextOutline(TEXT_OUTLINE_OUTLINE) end
						Reminder:ApplyVisualSettings()
						Reminder:RequestUpdate(true)
					end
				)
				root:CreateRadio(
					L["Thick outline"] or "Thick outline",
					function() return normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)) == TEXT_OUTLINE_THICK end,
					function()
						if addon.db then addon.db[DB_XY_TEXT_OUTLINE] = normalizeTextOutline(TEXT_OUTLINE_THICK) end
						Reminder:ApplyVisualSettings()
						Reminder:RequestUpdate(true)
					end
				)
				root:CreateRadio(
					L["Monochrome outline"] or "Monochrome outline",
					function() return normalizeTextOutline(getValue(DB_XY_TEXT_OUTLINE, defaults.xyTextOutline)) == TEXT_OUTLINE_MONO end,
					function()
						if addon.db then addon.db[DB_XY_TEXT_OUTLINE] = normalizeTextOutline(TEXT_OUTLINE_MONO) end
						Reminder:ApplyVisualSettings()
						Reminder:RequestUpdate(true)
					end
				)
			end,
			isShown = function() return Reminder:IsEditModeIconOnlyModeActive() end,
		},
		{
			name = L["ClassBuffReminderXYTextColor"] or "X/Y text color",
			kind = SettingType.Color,
			parentId = "anchorSize",
			default = defaults.xyTextColor,
			hasOpacity = true,
			get = function()
				local r, g, b, a = normalizeColor(getValue(DB_XY_TEXT_COLOR, defaults.xyTextColor), defaults.xyTextColor)
				return { r = r, g = g, b = b, a = a }
			end,
			set = function(_, value) editModeSetColor(DB_XY_TEXT_COLOR, value, defaults.xyTextColor) end,
			isShown = function() return Reminder:IsEditModeIconOnlyModeActive() end,
		},
		{
			name = L["ClassBuffReminderXYTextOffsetX"] or "X/Y offset X",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.xyTextOffsetX,
			minValue = -60,
			maxValue = 60,
			valueStep = 1,
			get = function() return clamp(getValue(DB_XY_TEXT_OFFSET_X, defaults.xyTextOffsetX), -60, 60, defaults.xyTextOffsetX) end,
			set = function(_, value) editModeSetNumber(DB_XY_TEXT_OFFSET_X, value, -60, 60, defaults.xyTextOffsetX) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.xyTextOffsetX) + 0.5)) end,
			isShown = function() return Reminder:IsEditModeIconOnlyModeActive() end,
		},
		{
			name = L["ClassBuffReminderXYTextOffsetY"] or "X/Y offset Y",
			kind = SettingType.Slider,
			parentId = "anchorSize",
			default = defaults.xyTextOffsetY,
			minValue = -60,
			maxValue = 60,
			valueStep = 1,
			get = function() return clamp(getValue(DB_XY_TEXT_OFFSET_Y, defaults.xyTextOffsetY), -60, 60, defaults.xyTextOffsetY) end,
			set = function(_, value) editModeSetNumber(DB_XY_TEXT_OFFSET_Y, value, -60, 60, defaults.xyTextOffsetY) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or defaults.xyTextOffsetY) + 0.5)) end,
			isShown = function() return Reminder:IsEditModeIconOnlyModeActive() end,
		},
	}
end

function editModeSettingsBuilders.buildBorder()
	return {
		{
			name = EMBLEM_BORDER,
			kind = SettingType.Collapsible,
			id = "border",
			defaultCollapsed = true,
		},
		{
			name = L["Use border"] or "Use border",
			kind = SettingType.Checkbox,
			parentId = "border",
			default = defaults.borderEnabled == true,
			get = function() return Reminder:IsBorderEnabled() end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderBorderEnabled"] = value == true end
				Reminder:ApplyVisualSettings()
				Reminder:RequestUpdate(true)
			end,
		},
		{
			name = L["Border texture"] or "Border texture",
			kind = SettingType.Dropdown,
			parentId = "border",
			height = 220,
			get = function() return Reminder:GetBorderTextureKey() end,
			set = function(_, value)
				if addon.db then addon.db["classBuffReminderBorderTexture"] = (type(value) == "string" and value ~= "" and value) or "DEFAULT" end
				Reminder:ApplyVisualSettings()
				Reminder:RequestUpdate(true)
			end,
			generator = function(_, root)
				local options = {
					{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
					{ value = "SOLID", label = "Solid" },
				}
				local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("border") or {}
				for i = 1, #mediaOptions do
					options[#options + 1] = {
						value = mediaOptions[i].value,
						label = mediaOptions[i].label,
					}
				end
				for i = 1, #options do
					local option = options[i]
					root:CreateRadio(option.label, function() return Reminder:GetBorderTextureKey() == option.value end, function()
						if addon.db then addon.db["classBuffReminderBorderTexture"] = option.value end
						Reminder:ApplyVisualSettings()
						Reminder:RequestUpdate(true)
					end)
				end
			end,
			isEnabled = function() return Reminder:IsBorderEnabled() end,
		},
		{
			name = L["Border size"] or "Border size",
			kind = SettingType.Slider,
			parentId = "border",
			minValue = 1,
			maxValue = 24,
			valueStep = 1,
			default = defaults.borderSize,
			get = function() return Reminder:GetBorderSize() end,
			set = function(_, value) editModeSetNumber("classBuffReminderBorderSize", value, 1, 24, defaults.borderSize) end,
			isEnabled = function() return Reminder:IsBorderEnabled() end,
		},
		{
			name = L["Border offset"] or "Border offset",
			kind = SettingType.Slider,
			parentId = "border",
			minValue = -20,
			maxValue = 20,
			valueStep = 1,
			default = defaults.borderOffset,
			get = function() return Reminder:GetBorderOffset() end,
			set = function(_, value) editModeSetNumber("classBuffReminderBorderOffset", value, -20, 20, defaults.borderOffset) end,
			isEnabled = function() return Reminder:IsBorderEnabled() end,
		},
		{
			name = EMBLEM_BORDER_COLOR,
			kind = SettingType.Color,
			parentId = "border",
			default = defaults.borderColor,
			hasOpacity = true,
			get = function()
				local r, g, b, a = Reminder:GetBorderColor()
				return { r = r, g = g, b = b, a = a }
			end,
			set = function(_, value) editModeSetColor("classBuffReminderBorderColor", value, defaults.borderColor) end,
			isEnabled = function() return Reminder:IsBorderEnabled() end,
		},
	}
end

function editModeSettingsBuilders.buildAll()
	if not SettingType then return nil end

	local settings = {}
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildClassBuffs())
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildFilters())
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildConsumables())
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildSound())
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildLayout())
	editModeSettingsBuilders.appendEntries(settings, editModeSettingsBuilders.buildBorder())
	return settings
end

function Reminder:RegisterEditMode()
	if self.editModeRegistered then return end
	if not (EditMode and EditMode.RegisterFrame) then return end

	local settings = editModeSettingsBuilders.buildAll()

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["Class Buff Reminder"] or "Class Buff Reminder",
		layoutDefaults = {
			point = "CENTER",
			relativePoint = "CENTER",
			x = 0,
			y = 240,
		},
		onApply = function()
			Reminder:ApplyVisualSettings()
			Reminder:UpdateDisplay()
		end,
		onEnter = function()
			Reminder.editModeActive = true
			Reminder:UpdateDisplay()
		end,
		onExit = function()
			Reminder.editModeActive = false
			Reminder.missingActive = false
			Reminder:HideSamplePreview()
			Reminder:SetGlowShown(false)
			if Reminder.frame then
				if Reminder.frame.iconCountText then Reminder.frame.iconCountText:SetText("") end
				if Reminder.frame.countText then Reminder.frame.countText:SetText("") end
				Reminder.frame:Hide()
			end
			Reminder:RequestUpdate(true)
			RunNextFrame(function() Reminder:RequestUpdate(true) end)
		end,
		isEnabled = function() return addon.db and addon.db[DB_ENABLED] == true end,
		settings = settings,
		collapseExclusive = true,
		-- Runtime visibility is controlled by UpdateDisplay/Render.
		-- Keep this false so EditMode doesn't force-show the frame on login.
		showOutsideEditMode = false,
	})

	self.editModeRegistered = true
end

function Reminder:UnregisterEditMode()
	if not self.editModeRegistered then return end
	if not (EditMode and EditMode.UnregisterFrame) then return end
	EditMode:UnregisterFrame(EDITMODE_ID, false)
	self.editModeRegistered = false
end

function Reminder:OnSettingChanged()
	local enabled = getValue(DB_ENABLED, defaults.enabled) == true
	local runtimeActive = self:ShouldRegisterRuntimeEvents()
	if runtimeActive and not self.eventsRegistered then self.suppressNextMissingSound = true end
	if runtimeActive then
		self:NormalizeMissingSoundSelection()
		self:ScheduleInitialSoundSync()
	end

	if enabled then
		self:RegisterEditMode()
	else
		self:UnregisterEditMode()
	end
	self:ApplyVisualSettings()
	self:InvalidateProviderAvailabilityCache()
	self:InvalidateRosterCache()
	self:InvalidateFlaskCache()
	self:InvalidateFoodCache()
	self:InvalidateRuneCache()
	self:InvalidateWeaponBuffCache()
	self:MarkAuraStatesDirty()

	if runtimeActive then
		self:RegisterEvents()
	else
		self:UnregisterEvents()
		self.initialSoundSyncDone = false
	end

	self:RequestUpdate(true)

	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end
