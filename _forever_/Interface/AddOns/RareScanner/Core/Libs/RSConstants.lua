-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSConstants = private.NewLib("RareScannerConstants")

-- Locales
local AL = LibStub("AceLocale-3.0"):GetLocale("RareScanner");

-- RareScanner general libraries
local RSTextTags = private.ImportLib("RareScannerTextTags")

---============================================================================
-- DEBUG MODE
---============================================================================

RSConstants.DEBUG_MODE = false
RSConstants.DEBUG_ATLAS_VIGNETTE = false


-- Use this constant to logger information about an specific entity while
-- displaying on the map. This is handy to find bugs in the POI filters
RSConstants.MAP_ENTITY_ID = nil

-- Use this constant to logger information about an specific item whie
-- displaying on the loot bar under the main button or the map. This is handy to find bugs
-- with the loot filters
RSConstants.LOOT_ITEM_ID = nil

---============================================================================
-- Current versions
---============================================================================

RSConstants.CURRENT_DB_VERSION = 10
RSConstants.CURRENT_LOOT_DB_VERSION = 13

---============================================================================
-- Current maps (newer)
---============================================================================

RSConstants.CURRENT_MAP_ID = 1414 -- Kalimndor
RSConstants.CURRENT_SUBMAP_ID = 1411 -- Durotar

---============================================================================
-- Default filtered entities by version
---============================================================================

RSConstants.DEFAULT_FILTERED_ENTITIES = {
	version = 1,
	containers = {}
}

---============================================================================
-- Special events
---============================================================================

RSConstants.EVENTS = {
	-- [RareScanner_EVENTID] = true|false|holidayTextureID;

}

---============================================================================
-- Mini events
---============================================================================

RSConstants.FACTION_LIBRARIAN_MINIEVENT = 1

-- Minievents that will have an option to filter/unfilter the icons from the worldmap
RSConstants.MINIEVENTS_WORLDMAP_FILTERS = {
	[RSConstants.FACTION_LIBRARIAN_MINIEVENT] = { active = true, containers = true, mapIDs = {1413,1416,1417,1418,1419,1420,1421,1422,1423,1425,1427,1428,1429,1431,1432,1434,1435,1436,1437,1439,1441,1442,1443,1444,1445,1446,1447,1448,1452,1455,2521}, atlas = "Class", text = AL["MAP_MENU_SHOW_FACTION_LIBRARIAN_CONTAINERS"] };
}

if (RSTextTags) then
	for _, minieventData in pairs (RSConstants.MINIEVENTS_WORLDMAP_FILTERS) do
		if (minieventData.text) then
			minieventData.text = RSTextTags.ParseText(minieventData.text)
		end
	end
end

---============================================================================
-- Timers
---============================================================================

RSConstants.CHECK_RESET_RECENTLY_SEEN_TIMER = 5 --5 seconds
RSConstants.RECENTLY_SEEN_RESET_TIMER = 120 --2 minutes
RSConstants.RECENTLY_SEEN_INSTANCE_RESET_TIMER = 120 * 15 --30 minutes
RSConstants.RECENTLY_SEEN_PING_ANIMATION_TIMER = 5 --5 seconds
RSConstants.CACHE_ALL_COMPLETED_QUEST_IDS_TIMER = 60 --1 minute
RSConstants.FIND_HIDDEN_QUESTS_TIMER = 5 --5 seconds after killing a NPC or opening a container
RSConstants.CHECK_RESPAWN_THRESHOLD = 150 --2.5 minutes
RSConstants.CHECK_RESPAWN_TIMER = 60 --1 minute
RSConstants.CHECK_RESET_NOTIFICATIONS_TIMER = 10 --10 seconds
RSConstants.CHECK_TARGETS_TIMER = 1 --1 seconds
RSConstants.BUTTON_TIMER = 1 --1 seconds
RSConstants.PREFOUND_TIMER = 5 --5 seconds

---============================================================================
-- Collections enumerators
---============================================================================

RSConstants.ITEM_SOURCE = {
	NPC = 1,
	CONTAINER = 2
}

RSConstants.ITEM_TYPE = {
	UNKNOWN = 0,
	APPEARANCE = 1,
	TOY = 2,
	PET = 3,
	MOUNT = 4,
	CUSTOM = "c%s"
}

---============================================================================
-- Types of entity by map (used in MapEntitiesTables)
---============================================================================

RSConstants.MAP_ENTITY_NPC = 1
RSConstants.MAP_ENTITY_CONTAINER = 2
RSConstants.MAP_ENTITY_EVENT = 3

---============================================================================
-- Types of entity filters
---============================================================================

RSConstants.ENTITY_FILTER_ALL = 1
RSConstants.ENTITY_FILTER_WORLDMAP = 2
RSConstants.ENTITY_FILTER_ALERTS = 3

---============================================================================
-- Events when adding animations to the world map
---============================================================================

RSConstants.MAP_ANIMATIONS_ON_FOUND = 1
RSConstants.MAP_ANIMATIONS_ON_CLICK = 2
RSConstants.MAP_ANIMATIONS_ON_BOTH = 3

---============================================================================
-- Tracking systems
---============================================================================

RSConstants.TRACKING_SYSTEM = {
	VIGNETTE = 1,
	NAMEPLATE_MOUSEOVER = 2,
	UNIT_TARGET = 3,
	CHAT_EMOTE = 4,
	AURA = 5,
	TOAST_EVENT = 6,
	SOFT_INTERACT = 7,
	CLASS_SKILL_TRACKING = 8
}

---============================================================================
-- Addons default settings
---============================================================================

RSConstants.PROFILE_DEFAULTS = {
	profile = {
		general = {
			telemetry = true,
			rescanTimer = 5,
			scanRares = true,
			scanContainers = true,
			scanEvents = true,
			scanChatAlerts = true,
			scanInstances = false,
			scanOnTaxi = true,
			scanOnPetBattle = true,
			scanWorldmapVignette = true,
			scanWithMacro = true,
			scanWithMacroPerChar = false,
			macroGlow = true,
			scanSoftInteract = false,
			pingTarget = false,
			originalSoftInteractCVars = false,
			autoHideButtonInstances = false,
			ignoreCompletedEntities = true,
			showMaker = true,
			marker = 8,
			enableWaypointsSupport = false,
			autoWaypoints = false,
			enableTomtomSupport = false,
			autoTomtomWaypoints = false,
			showTomtomMinimapIcon = false,
			showTomtomWorldmapIcon = false,
			enableWaypointUISupport = false,
			autoWaypointUIWaypoints = false
		},
		sound = {
			soundDisabled = false,
			soundObjectDisabled = false,
			soundChannel = "Master",
			soundVolume = 4,
			soundPlayed = "Horn",
			soundObjectPlayed = "PVP Horde",
			soundCustomFolder = "RareScannerSounds"
		},
		display = {
			displayButton = true,
			displayMiniature = true,
			displayButtonContainers = true,
			autoHideButton = 0,
			scale = 0.8,
			lockPosition = false,
			displayRaidWarning = true,
			flashWindowsTaskBar = true,
			displayChatMessage = true,
			chatWindowName = nil,
			displayTimestampChatMessage = true,
			enableNavigation = true,
			navigationLockEntity = false,
			minimapButton = {
				hide = false
			},
			worldmapButton = true
		},
		rareFilters = {
			defaultNpcFilterType = RSConstants.ENTITY_FILTER_ALL,
			filterWeeklyRep = false
		},
		containerFilters = {
			defaultContainerFilterType = RSConstants.ENTITY_FILTER_ALL,
			filterAchievements = false,
			filterRepeatable = false
		},
		eventFilters = {
			defaultEventFilterType = RSConstants.ENTITY_FILTER_ALL
		},
		zoneFilters = {
			defaultZoneFilterType = RSConstants.ENTITY_FILTER_ALL
		},
		collections = {
			filteredOnlyOnWorldMap = false,
			autoFilteringOnCollect = false,
			createProfileBackup = true,
			searchingPets = true,
			searchingMounts = true,
			searchingToys = true,
			searchingAppearances = true,
			searchingClassAppearances = true,
			searchingDecors = true,
			searchingMissingAchievementCriteria = true,
			showFiltered = true,
			showDead = true,
			showWithoutCollectibles = false,
			ignoreMissingCollectibles = false,
			showNpcs = true,
			lootHideNonUpgrades = false,
			lootOnlyEquipable = false,
			lootCollapsed = false,
			lootOnlyUsable = false,
			lootOnlyMyLevel = false,
			lootShowFiltered = true,
			showContainers = true,
			lockingMap = false
		},
		map = {
			displayNpcIcons = true,
			displayNotDiscoveredNpcIcons = true,
			displayAlreadyKilledNpcIcons = false,
			displayAlreadyKilledNpcIconsReseteable = false,
			displayWeeklyRepNpcIcons = true,
			displayProfessionRaresNpcIcons = true,
			displayAchievementRaresNpcIcons = true,
			displayMinieventsNpcIcons = { false },
			displayCustomGroupNpcIcons = {},
			displayOtherRaresNpcIcons = true,
			displayRenownRaresNpcIcons = false,
			displayContainerIcons = true,
			displayAlreadyOpenedContainersIcons = false,
			displayNotDiscoveredContainerIcons = true,
			displayNotTrackeableContainerIcons = true,
			displayAchievementContainerIcons = true,
			displayProfessionContainerIcons = true,
			displayOtherContainerIcons = true,
			displayRenownContainerIcons = false,
			displayEventIcons = true,
			displayNotDiscoveredEventIcons = true,
			disableLastSeenFilter = false,
			displayFriendlyNpcIcons = false,
			displayOldNotDiscoveredMapIcons = true,
			displayAlreadyCompletedEventIcons = false,
			supportMapIcons = true,
			displayFilteredIngameMapIcons = true,
			playerPinOntop = false,
			maxSeenTime = 0,
			maxSeenTimeContainer = 0,
			maxSeenTimeEvent = 5,
			scale = 0.8,
			minimapscale = 0.7,
			showingWorldMapSearcher = true,
			cleanWorldMapSearcherOnChange = true,
			displayMinimapIcons = true,
			ignoreWmOnMinimap = false,
			waypointIngame = true,
			waypointTomtom = false,
			waypointWaypointUI = false,
			tooltipsScale = 1.0,
			tooltipsOnIngameIcons = true,
			tooltipsAchievements = true,
			tooltipsNotes = true,
			tooltipsState = true,
			tooltipsCounters = true,
			tooltipsSeen = true,
			tooltipsRespawn = false,
			tooltipsCommands = true,
			tooltipsExtraInfo = true,
			tooltipsFilterState = true,
			lootAchievTooltipsScale = 0.7,
			lootAchievementsPosition = "ANCHOR_LEFT",
			overlayMaxColours = 10,
			overlayColour1 = { 1, 0.2, 1 },
			overlayColour2 = { 0.23, 0.943, 1 },
			overlayColour3 = { 0.98, 0.99, 0.19 },
			overlayColour4 = { 0, 0.12, 1 },
			overlayColour5 = { 0.317, 1, 0.1 },
			overlayColour6 = { 1, 0.35, 0.11 },
			overlayColour7 = { 0.08, 0.55, 1 },
			overlayColour8 = { 0.18, 1, 0.42 },
			overlayColour9 = { 1, 0.04, 0.4 },
			overlayColour10 = { 0.4, 0.007, 1 },
			animationNpcs = true,
			animationNpcsType = RSConstants.MAP_ANIMATIONS_ON_BOTH,
			animationContainers = true,
			animationContainersType = RSConstants.MAP_ANIMATIONS_ON_CLICK,
			animationEvents = true,
			animationEventsType = RSConstants.MAP_ANIMATIONS_ON_CLICK,
			animationVignettes = true,
			highlightReputation = true,
			autoGuidanceIcons = true,
			displayMinimapRoute = true,
			displayRouteArrows = true,
			routeColour = { 0.2, 0.8, 1.0 },
			routeLineThickness = 2
		},
		loot = {
			filteredLootCategories = {},
			filteredItems = {},
			displayLoot = true,
			displayLootOnMap = true,
			lootTooltipPosition = "ANCHOR_LEFT",
			lootMinQuality = 0,
			filterNotEquipableItems = false,
			filterNotUsable = false,
			filterByExplorerResults = false,
			showingMissingMounts = true,
			showingMissingPets = true,
			showingMissingToys = true,
			showingMissingAppearances = true,
			showingMissingClassAppearances = true,
			showingMissingDecors = true,
			numItems = 10,
			numItemsPerRow = 10,
			tooltipsCommands = true,
			tooltipsCanImogit = false,
			tooltipsTSM = true,
			covenantRequirement = true
		},
		chat = {
			waypointIngame = true,
			waypointTomtom = false,
			waypointWaypointUI = false,
			tooltipsScale = 1,
			tooltipsCounters = true,
			tooltipsAchievements = true,
			tooltipsNotes = true,
			tooltipsLoot = true,
			tooltipsSeen = true,
			tooltipsCommands = true,
			tooltipsFilterScale = 0.75,
			colorNpc = "85c1e9",
			colorContainer = "d7dbdd",
			colorEvent = "f7dc6f",
		}
	}
}

---============================================================================
-- Macro settings
---============================================================================

RSConstants.RARESCANNER_MACRO_NAME = "RS_MACRO"
RSConstants.RARESCANNER_MACRO_ICON = "Interface/Icons/Icon_upgradestone_rare"
RSConstants.RARESCANNER_MACRO_TARGET_DISTANCE_YARDS = 140
RSConstants.RARESCANNER_MACRO_UPDATE_NPCS_DISTANCE_YARDS = 40
RSConstants.RARESCANNER_MACRO_REFRESH_TIMER = 2 --seconds

---============================================================================
-- Name of the RareScanner's button
---============================================================================

RSConstants.RS_BUTTON_NAME = "RARESCANNER_BUTTON"

---============================================================================
-- Sounds
---============================================================================

RSConstants.DEFAULT_SOUNDS = {
	["Achievement Sound"] = "Interface\\AddOns\\RareScanner\\Media\\achievmentsound1-4.ogg",
	["Alarm Clock"] = "Interface\\AddOns\\RareScanner\\Media\\alarmclockwarning2-4.ogg",
	["Boat Docking"] = "Interface\\AddOns\\RareScanner\\Media\\boatdockedwarning-4.ogg",
	["Siege Engineer Weapon"] = "Interface\\AddOns\\RareScanner\\Media\\fx_ograid_siege_weaponmachine_warning-4.ogg",
	["PVP Alliance"] = "Interface\\AddOns\\RareScanner\\Media\\pvpwarningalliance-4.ogg",
	["PVP Horde"] = "Interface\\AddOns\\RareScanner\\Media\\pvpwarninghorde-4.ogg",
	["Ready Check"] = "Interface\\AddOns\\RareScanner\\Media\\readycheck-4.ogg",
	["Horn"] = "Interface\\AddOns\\RareScanner\\Media\\gruntling_horn_bb-4.ogg",
	["Event Wardrum Ogre"] = "Interface\\AddOns\\RareScanner\\Media\\Event_wardrum_ogre-4.ogg",
	["Level Up"] = "Interface\\AddOns\\RareScanner\\Media\\levelup2-4.ogg",
}

RSConstants.EXTERNAL_SOUND_FOLDER = "Interface\\AddOns\\%s\\%s"
RSConstants.ERROR_SOUND_CLOSE_ID = 567464 --(close), 567490 (open)
RSConstants.ERROR_SOUND_OPEN_ID = 567490 --(close), 567490 (open)

---============================================================================
-- CMD commands
---============================================================================

RSConstants.CMD_HELP = "help"
RSConstants.CMD_TOGGLE_MAP_ICONS = "tmi"
RSConstants.CMD_TOGGLE_ALERTS = "ta"
RSConstants.CMD_TOGGLE_RARES = "tr"
RSConstants.CMD_TOGGLE_RARES_ALERTS = "tra"
RSConstants.CMD_TOGGLE_EVENTS = "te"
RSConstants.CMD_TOGGLE_EVENTS_ALERTS = "tea"
RSConstants.CMD_TOGGLE_TREASURES = "tt"
RSConstants.CMD_TOGGLE_TREASURES_ALERTS = "tta"
RSConstants.CMD_TOGGLE_FILTER_REPEATABLE_TREASURES = "frt"
RSConstants.CMD_TOGGLE_SCANNING_WORLD_MAP_VIGNETTES = "swmv"
RSConstants.CMD_TOMTOM_WAYPOINT = "waypoint"
RSConstants.CMD_OPEN_EXPLORER = "explorer"
RSConstants.CMD_RECENTLY_SEEN = "rseen"
RSConstants.CMD_IMPORT = "import"
RSConstants.CMD_MIDNIGHT_PRE_PATCH = "midnight"
RSConstants.CMD_ROUTE = "route"
RSConstants.CMD_ROUTE_CANCEL = "croute"
RSConstants.CMD_TELEMETRY = "telemetry"
RSConstants.CMD_TELEMETRY_STATS = "stats"
RSConstants.CMD_TELEMETRY_STATS_RESET = "stats reset"
RSConstants.CMD_TELEMETRY_PROPOSALS = "proposals"
RSConstants.CMD_TELEMETRY_SIMSYNC = "simsync"
RSConstants.CMD_TELEMETRY_SIMSYNC_CLEAR = "simsync clear"
RSConstants.CMD_TELEMETRY_SYNC = "sync"
RSConstants.CMD_TELEMETRY_EXPORT = "export"

---============================================================================
-- AtlasNames
---============================================================================

RSConstants.NPC_VIGNETTE = "VignetteKill"
RSConstants.NPC_VIGNETTE_ELITE = "VignetteKillElite"
RSConstants.NPC_LEGION_VIGNETTE = "DemonInvasion5"
RSConstants.NPC_NAZJATAR_VIGNETTE = "nazjatar-nagaevent"
RSConstants.NPC_WARFRONT_NEUTRAL_HERO_VIGNETTE = "Warfront-NeutralHero"
RSConstants.NPC_TORMENTORS_VIGNETTE = "Tormentors-Boss"
RSConstants.NPC_DIABLO_GOBLIN = "BuildanAbomination-32x32"
RSConstants.NPC_WARLOCK_PORTAL_GOBLIN = "WarlockPortal-Yellow-32x32"
RSConstants.NPC_VIGNETTE_BOSS = "vignettekillboss"

RSConstants.CONTAINER_VIGNETTE = "VignetteLoot"
RSConstants.CONTAINER_ELITE_VIGNETTE = "VignetteLootElite"
RSConstants.CONTAINER_LOCKED_VIGNETTE = "vignetteloot-locked"
RSConstants.CONTAINER_ELITE_LOCKED_VIGNETTE = "vignettelootelite-locked"
RSConstants.CONTAINER_LORE_OBJECT = "loreobject-32x32"
RSConstants.CONTAINER_PVP_AIRPLANE_OBJECT = "Vehicle-Air-Occupied"
RSConstants.CONTAINER_PVP_FLAGS_OBJECT = "CrossedFlags"

RSConstants.EVENT_VIGNETTE = "VignetteEvent"
RSConstants.EVENT_ELITE_VIGNETTE = "VignetteEventElite"
RSConstants.EVENT_TORMENTORS_VIGNETTE = "Tormentors-Event"
RSConstants.EVENT_HORN = "minimap-genericevent-hornicon-small"

---============================================================================
-- SpellIDs
---============================================================================


---============================================================================
-- MapIDS
---============================================================================

RSConstants.ALL_ZONES_CUSTOM_NPC = 0
RSConstants.ALL_ZONES = "all"
RSConstants.UNKNOWN_ZONE_ID = 0
RSConstants.IGNORE_MAPS = { }
RSConstants.COSMIC = 946
RSConstants.AZEROTH = 947
RSConstants.MAPS_WITHOUT_WARBAND_REPUTATION = { }
RSConstants.CONTINENTS_WARBAND_REPUTATION = { }
RSConstants.MAPS_TRACK_EVENT_HORNS = { }
RSConstants.INSTANCE_CONTINENTS = { 9997 } -- Dungeons and raids
RSConstants.EXPLORER_OWN_SECTION_CONTINENTS = { 9997 } -- Dungeons

---============================================================================
-- Entity IDs
---============================================================================

RSConstants.CONTAINERS_WITHOUT_VIGNETTE = { }
RSConstants.CONTAINER_WITH_NPC_VIGNETTE = { }
RSConstants.IGNORE_NPCS_REPUTATION = { }
RSConstants.WORLDBOSSES = { }

-- NPCs that spawn after completing an event
RSConstants.NPCS_WITH_PRE_EVENT = {
	-- EVENTID = NPCID
}

-- Contains that spawn after completing an event
RSConstants.CONTAINERS_WITH_PRE_EVENT = {
	-- EVENTID = CONTAINERID
}

-- NPCs that spawn after killing another NPC
RSConstants.NPCS_WITH_PRE_NPCS = {

}

RSConstants.IGNORED_VIGNETTES_NPCS = { 471 }
RSConstants.IGNORED_VIGNETTES_CONTAINERS = {  }
RSConstants.IGNORED_FRIENDLY_NPCS = { }
RSConstants.NPCS_WITH_EVENT_VIGNETTE = { }
RSConstants.NPCS_WITH_CONTAINER_VIGNETTE = { }
RSConstants.CONTAINERS_WITH_NPC_VIGNETTE = { }
RSConstants.CONTAINERS_WITH_EVENT_VIGNETTE = { }
RSConstants.EVENTS_WITH_NPC_VIGNETTE = { }
RSConstants.NPCS_WITH_MULTIPLE_SPAWNS = { }
RSConstants.IGNORED_TRACKING_SYSTEMS_NOT_VIGNETTE = { }
RSConstants.CONTAINERS_BATTERED_CHESTS = {106318,106319,2843,2849}
RSConstants.CONTAINERS_LIBRARIAN_FACTIONS = {207972,386691,386759,405879,407566,408014,409496,409501,409562,409692,409700,409711,409717,409731,409735,410299,421526,423895,423896,423897,423898,423899,423900}
RSConstants.CONTAINERS_SOLID_CHESTS = {2852,2855,153454,2850,153453,4149,2857,153451}

---============================================================================
-- Custom NPCs
---============================================================================

RSConstants.DEFAULT_GROUP = 0

---============================================================================
-- TSM
---============================================================================

RSConstants.TSM_SOURCES = { "DBMinBuyout", "DBMarket", "DBRegionMarketAvg" }

---============================================================================
-- Eternal states
---============================================================================

RSConstants.ETERNAL_DEATH = -1
RSConstants.ETERNAL_OPENED = -1
RSConstants.ETERNAL_COMPLETED = -1
RSConstants.ETERNAL_COLLECTED = -1

---============================================================================
-- Textures
---============================================================================

RSConstants.TEXTURE_PATH = "Interface\\AddOns\\RareScanner\\Media\\Icons\\%s.blp"
RSConstants.DUNGEON_MAP_TEXTURE_PATH = "Interface\\AddOns\\RareScanner\\Media\\DungeonMaps\\%s.blp"
RSConstants.DUNGEON_MAP_MAX_SIZE = 0.8 -- part of the explorer map that the dungeon maps can fill
RSConstants.DUNGEON_MAP_MAX_SCALE = 2 -- the small dungeon maps aren't enlarged more than this
RSConstants.GROUP_TOP_TEXTURE_FILE = "GroupT"
RSConstants.GROUP_RIGHT_TEXTURE_FILE = "GroupR"
RSConstants.GROUP_LEFT_TEXTURE_FILE = "GroupL"
RSConstants.NORMAL_NPC_TEXTURE_FILE = "OriginalSkull"
RSConstants.RED_NPC_TEXTURE_FILE = "RedSkullDark"
RSConstants.PINK_NPC_TEXTURE_FILE = "PinkSkullDark"
RSConstants.BLUE_NPC_TEXTURE_FILE = "BlueSkullDark"
RSConstants.PURPLE_NPC_TEXTURE_FILE = "CustomSkull"
RSConstants.LIGHT_BLUE_NPC_TEXTURE_FILE = "BlueSkullLight"
RSConstants.NORMAL_CONTAINER_TEXTURE_FILE = "OriginalChest"
RSConstants.RED_CONTAINER_TEXTURE_FILE = "RedChest"
RSConstants.PINK_CONTAINER_TEXTURE_FILE = "PinkChest"
RSConstants.BLUE_CONTAINER_TEXTURE_FILE = "BlueChest"
RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE_FILE = "LightGreenChest"
RSConstants.NORMAL_EVENT_TEXTURE_FILE = "OriginalStar"
RSConstants.RED_EVENT_TEXTURE_FILE = "RedStar"
RSConstants.PINK_EVENT_TEXTURE_FILE = "PinkStar"
RSConstants.BLUE_EVENT_TEXTURE_FILE = "BlueStar"
RSConstants.OVERLAY_SPOT_TEXTURE_FILE = "Overlay"
RSConstants.GUIDE_TRANSPORT_FILE = "Transport"
RSConstants.GUIDE_ENTRANCE_FILE = "Entrance"
RSConstants.GUIDE_FLAG_FILE = "Flag"
RSConstants.GUIDE_DOT_FILE = "Dot"
RSConstants.GUIDE_STEP1_FILE = "Number1"
RSConstants.GUIDE_STEP2_FILE = "Number2"
RSConstants.GUIDE_STEP3_FILE = "Number3"
RSConstants.GUIDE_STEP4_FILE = "Number4"
RSConstants.GUIDE_STEP5_FILE = "Number5"
RSConstants.GUIDE_STEP6_FILE = "Number6"
RSConstants.GUIDE_STEP7_FILE = "Number7"
RSConstants.GUIDE_STEP8_FILE = "Number8"
RSConstants.GUIDE_STEP9_FILE = "Number9"
RSConstants.PROFFESION_ICON_ATLAS = "Professions-Crafting-Orders-Icon"
RSConstants.ACHIEVEMENT_ICON_ATLAS = "UI-Achievement-Shield-2"
RSConstants.PRIMAL_STORM_ICON_ATLAS = "ElementalStorm-Lesser-Water"
RSConstants.NOT_TRACKABLE_ICON_ATLAS = "Islands-MarkedArea"

RSConstants.NORMAL_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.NORMAL_NPC_TEXTURE_FILE);
RSConstants.GROUP_NORMAL_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.RED_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.RED_NPC_TEXTURE_FILE);
RSConstants.GROUP_RED_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_RED_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_RED_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.PINK_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.PINK_NPC_TEXTURE_FILE);
RSConstants.GROUP_PINK_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_PINK_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_PINK_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.BLUE_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.BLUE_NPC_TEXTURE_FILE);
RSConstants.GROUP_BLUE_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_BLUE_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_BLUE_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.LIGHT_BLUE_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.LIGHT_BLUE_NPC_TEXTURE_FILE);
RSConstants.GROUP_LIGHT_BLUE_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_LIGHT_BLUE_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_LIGHT_BLUE_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_BLUE_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.PURPLE_NPC_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.PURPLE_NPC_TEXTURE_FILE);
RSConstants.GROUP_PURPLE_NPC_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PURPLE_NPC_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_PURPLE_NPC_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PURPLE_NPC_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_PURPLE_NPC_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PURPLE_NPC_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.NORMAL_CONTAINER_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.NORMAL_CONTAINER_TEXTURE_FILE);
RSConstants.GROUP_NORMAL_CONTAINER_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_CONTAINER_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_CONTAINER_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.RED_CONTAINER_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.RED_CONTAINER_TEXTURE_FILE);
RSConstants.GROUP_RED_CONTAINER_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_RED_CONTAINER_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_RED_CONTAINER_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.PINK_CONTAINER_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.PINK_CONTAINER_TEXTURE_FILE);
RSConstants.GROUP_PINK_CONTAINER_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_PINK_CONTAINER_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_PINK_CONTAINER_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.BLUE_CONTAINER_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.BLUE_CONTAINER_TEXTURE_FILE);
RSConstants.GROUP_BLUE_CONTAINER_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_BLUE_CONTAINER_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_BLUE_CONTAINER_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE_FILE);
RSConstants.GROUP_LIGHT_GREEN_CONTAINER_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_LIGHT_GREEN_CONTAINER_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_LIGHT_GREEN_CONTAINER_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.LIGHT_GREEN_CONTAINER_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.NORMAL_EVENT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.NORMAL_EVENT_TEXTURE_FILE);
RSConstants.GROUP_NORMAL_EVENT_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_EVENT_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_EVENT_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_EVENT_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_NORMAL_EVENT_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.NORMAL_EVENT_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.RED_EVENT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.RED_EVENT_TEXTURE_FILE);
RSConstants.GROUP_RED_EVENT_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_EVENT_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_RED_EVENT_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_EVENT_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_RED_EVENT_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.RED_EVENT_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.PINK_EVENT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.PINK_EVENT_TEXTURE_FILE);
RSConstants.GROUP_PINK_EVENT_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_EVENT_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_PINK_EVENT_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_EVENT_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_PINK_EVENT_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.PINK_EVENT_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.BLUE_EVENT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.BLUE_EVENT_TEXTURE_FILE);
RSConstants.GROUP_BLUE_EVENT_T_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_EVENT_TEXTURE_FILE, RSConstants.GROUP_TOP_TEXTURE_FILE));
RSConstants.GROUP_BLUE_EVENT_L_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_EVENT_TEXTURE_FILE, RSConstants.GROUP_LEFT_TEXTURE_FILE));
RSConstants.GROUP_BLUE_EVENT_R_TEXTURE = string.format(RSConstants.TEXTURE_PATH, string.format("%s%s", RSConstants.BLUE_EVENT_TEXTURE_FILE, RSConstants.GROUP_RIGHT_TEXTURE_FILE));
RSConstants.OVERLAY_SPOT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.OVERLAY_SPOT_TEXTURE_FILE);
RSConstants.GUIDE_TRANSPORT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_TRANSPORT_FILE);
RSConstants.GUIDE_ENTRANCE_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_ENTRANCE_FILE);
RSConstants.GUIDE_FLAG_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_FLAG_FILE);
RSConstants.GUIDE_DOT_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_DOT_FILE);
RSConstants.GUIDE_STEP1_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP1_FILE);
RSConstants.GUIDE_STEP2_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP2_FILE);
RSConstants.GUIDE_STEP3_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP3_FILE);
RSConstants.GUIDE_STEP4_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP4_FILE);
RSConstants.GUIDE_STEP5_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP5_FILE);
RSConstants.GUIDE_STEP6_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP6_FILE);
RSConstants.GUIDE_STEP7_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP7_FILE);
RSConstants.GUIDE_STEP8_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP8_FILE);
RSConstants.GUIDE_STEP9_TEXTURE = string.format(RSConstants.TEXTURE_PATH, RSConstants.GUIDE_STEP9_FILE);

---============================================================================
-- Guide constants
---============================================================================

RSConstants.TRANSPORT = "T"
RSConstants.ENTRANCE = "E"
RSConstants.PATH_START = "P"
RSConstants.FLAG = "F"
RSConstants.DOT = "D"
RSConstants.STEP1 = "1"
RSConstants.STEP2 = "2"
RSConstants.STEP3 = "3"
RSConstants.STEP4 = "4"
RSConstants.STEP5 = "5"
RSConstants.STEP6 = "6"
RSConstants.STEP7 = "7"

---============================================================================
-- Dialogs
---============================================================================

RSConstants.APPLY_COLLECTIONS_LOOT_FILTERS = "RARESCANNER_APPLY_COLLECTIONS_LOOT_FILTERS"
RSConstants.EXPLORER_FILTERING_DIALOG = "RARESCANNER_EXPLORER_FILTERING_DIALOG"
RSConstants.EXPLORER_SCAN_NOT_DONE = "RARESCANNER_EXPLORER_SCAN_NOT_DONE"
RSConstants.ITEM_LIST_VALIDATION_ERROR = "RARESCANNER_INFO_DIALOG"
RSConstants.ITEM_LIST_WRONG_IDS_ERROR = "RARESCANNER_ITEM_LIST_WRONG_IDS_ERROR"
RSConstants.DELETE_GROUP_CONFIRMATION = "RARESCANNER_DELETE_GROUP_CONFIRMATION"
RSConstants.RESET_ROUTE_CONFIRMATION = "RARESCANNER_RESET_ROUTE_CONFIRMATION"

---============================================================================
-- Explorer filters
---============================================================================

RSConstants.EXPLORER_FILTER_DROP_MOUNTS = 1
RSConstants.EXPLORER_FILTER_DROP_PETS = 2
RSConstants.EXPLORER_FILTER_DROP_TOYS = 3
RSConstants.EXPLORER_FILTER_DROP_APPEARANCES = 4
RSConstants.EXPLORER_FILTER_DROP_CLASS_APPEARANCES = 10
RSConstants.EXPLORER_FILTER_DROP_DECOR = 11
RSConstants.EXPLORER_FILTER_DROP_CUSTOM = "c%s"
RSConstants.EXPLORER_FILTER_ACHIEVEMENT_CRITERIA = 5
RSConstants.EXPLORER_FILTER_DEAD = 6
RSConstants.EXPLORER_FILTER_FILTERED = 7
RSConstants.EXPLORER_FILTER_WITHOUT_COLLECTIBLES = 8
RSConstants.EXPLORER_FILTER_IGNORE_COLLECTIBLES = 14
RSConstants.EXPLORER_FILTER_TYPE_NPC = 12
RSConstants.EXPLORER_FILTER_TYPE_CONTAINER = 13

---============================================================================
-- Others
---============================================================================

RSConstants.RAID_WARNING_SHOWING_TIME = 3
RSConstants.MINIMUM_DISTANCE_PINS_WORLD_MAP = 0.005
RSConstants.TOOLTIP_MAX_WIDTH = 300
RSConstants.NPC_BOSS_LEVEL = -1 -- NPCs without level (bosses)
-- Creature type (same IDs as the game) -> suffix of the battle pet icon. Types without icon (demon, giant) show nothing
RSConstants.NPC_CREATURE_TYPE_ICONS = {
	[1] = "Beast",
	[2] = "Dragon",
	[4] = "Elemental",
	[6] = "Undead",
	[7] = "Humanoid",
	[8] = "Critter",
	[9] = "Mechanical",
}
RSConstants.LOOT_DEFAULT_DROP_CHANCE = 0.1 -- Drop chance (%) of the items without a known one
RSConstants.TOOLTIP_MIN_WIDTH = 100

---============================================================================
-- Auxiliar functions
---============================================================================

function RSConstants.IsScanneableAtlas(atlasName)
	return RSConstants.IsEventAtlas(atlasName) or RSConstants.IsNpcAtlas(atlasName) or RSConstants.IsContainerAtlas(atlasName)
end

function RSConstants.IsEventAtlas(atlasName)
	return atlasName == RSConstants.EVENT_VIGNETTE or atlasName == RSConstants.EVENT_ELITE_VIGNETTE or atlasName == RSConstants.EVENT_TORMENTORS_VIGNETTE or atlasName == RSConstants.EVENT_HORN
end

function RSConstants.IsNpcAtlas(atlasName)
	return atlasName == RSConstants.NPC_VIGNETTE or atlasName == RSConstants.NPC_LEGION_VIGNETTE or atlasName == RSConstants.NPC_VIGNETTE_ELITE or atlasName == RSConstants.NPC_NAZJATAR_VIGNETTE or atlasName == RSConstants.NPC_WARFRONT_NEUTRAL_HERO_VIGNETTE or atlasName == RSConstants.NPC_TORMENTORS_VIGNETTE or atlasName == RSConstants.NPC_WARLOCK_PORTAL_GOBLIN
end

function RSConstants.IsContainerAtlas(atlasName)
	return atlasName == RSConstants.CONTAINER_VIGNETTE or atlasName == RSConstants.CONTAINER_ELITE_VIGNETTE or atlasName == RSConstants.CONTAINER_LOCKED_VIGNETTE or atlasName == RSConstants.CONTAINER_ELITE_LOCKED_VIGNETTE or atlasName == RSConstants.CONTAINER_LORE_OBJECT or atlasName == RSConstants.CONTAINER_PVP_AIRPLANE_OBJECT or atlasName == RSConstants.CONTAINER_PVP_FLAGS_OBJECT
end

function RSConstants.IsContainerPvpAtlas(atlasName)
	return atlasName == RSConstants.CONTAINER_PVP_AIRPLANE_OBJECT or atlasName == RSConstants.CONTAINER_PVP_FLAGS_OBJECT
end

---============================================================================
-- Telemetry. These values are not meant to be changed
---============================================================================

RSConstants.DEBUG_TELEMETRY_LOOPBACK = false -- Processes the own messages, to test the communications without other players

-- Telemetry limits (in seconds, except the sample limits)
RSConstants.TELEMETRY_VERSION = 4 -- 4: the samples with the offline gap are marked, so the data of the version 3 (without the mark) is discarded
RSConstants.TELEMETRY_MIN_RESPAWN_SECONDS = 30
RSConstants.TELEMETRY_MAX_RESPAWN_SECONDS = 604800 -- 7 days
RSConstants.TELEMETRY_MAX_SAMPLES_PER_NPC = 50
RSConstants.TELEMETRY_MIN_SAMPLES_MAX_FILTER = 6 -- respawns needed to ignore the maximums that are too far from the median
RSConstants.TELEMETRY_MAX_FILTER_FACTOR = 1.5 -- the maximums above the median multiplied by this are ignored
RSConstants.TELEMETRY_MIN_FILTER_DIVISOR = 3 -- the minimums below the median divided by this are ignored
RSConstants.TELEMETRY_IGNORED_CONTINENTS = { 9997, 9996, 9994, 9993 } -- Dungeons, raids, expedition islands and delves: their rares don't have a respawn time
RSConstants.TELEMETRY_SESSION_BREAK_SECONDS = 15 -- the time offline that ends a session of the game (a reload is shorter, a restart is longer)
RSConstants.TELEMETRY_MAX_SEEN_GUIDS = 300 -- creatures remembered in a session to know which ones are new
RSConstants.TELEMETRY_OFFLINE_MIN_SECONDS = 60 -- the offline time shorter than this is not saved (quick reconnections)
RSConstants.TELEMETRY_OFFLINE_GAP_SECONDS = 1800 -- offline time between a death and a spawn that always makes the respawn unreliable (the samples are marked and not used for the estimation)
RSConstants.TELEMETRY_OFFLINE_GAP_RATIO = 0.5 -- it is also unreliable if the player was offline at least this part of the respawn measured
RSConstants.TELEMETRY_HEARTBEAT_SECONDS = 300 -- the last time online is saved every 5 minutes, in case the game closes badly
RSConstants.TELEMETRY_MAX_SAMPLES_PER_SENDER = 5 -- samples of a NPC in an answer of the sync, so it carries several NPCs
RSConstants.TELEMETRY_MAX_SAMPLES_PER_SENDER_SAVED = 15 -- samples of a NPC that are saved from the same sender (live samples never create exact respawns or schedules)
RSConstants.TELEMETRY_OVERDUE_GRACE_SECONDS = 300
RSConstants.TELEMETRY_STALE_RESPAWN_FACTOR = 2
RSConstants.TELEMETRY_STATIC_TOLERANCE_FACTOR = 2 -- samples must be between min / 2 and max * 2 of the database
RSConstants.TELEMETRY_MIN_SAMPLES_PROPOSAL = 5
RSConstants.TELEMETRY_CLOCK_TOLERANCE_SECONDS = 60 -- a creature that just spawned can be a bit ahead of the clock of the player
RSConstants.TELEMETRY_SHARD_UPDATE_SECONDS = 1

-- Telemetry communications
RSConstants.TELEMETRY_COMM_PREFIX = "RSTelemetry2"
RSConstants.TELEMETRY_COMM_SEND_DELAY = 3 -- seconds before sending, to group several items in one message
RSConstants.TELEMETRY_COMM_SEND_JITTER = 6 -- random seconds added, so players that see the same event don't all send it at once
RSConstants.TELEMETRY_COMM_MAX_LENGTH = 230 -- the limit of a message is 255 characters
RSConstants.TELEMETRY_COMM_MAX_QUEUE = 40
RSConstants.TELEMETRY_COMM_MAX_ITEMS_PER_MINUTE = 40 -- per sender
RSConstants.TELEMETRY_COMM_MAX_ITEMS_PER_SECOND = 60 -- in total, no matter how many players send them
RSConstants.TELEMETRY_COMM_MAX_ERRORS = 5
RSConstants.TELEMETRY_HOOK_MAX_ERRORS = 5
RSConstants.TELEMETRY_MAX_RECENT_KILLS = 300

-- Synchronization with the guild when the player connects
RSConstants.TELEMETRY_SYNC_START_DELAY = 30 -- seconds after connecting before asking, to not ask while loading
RSConstants.TELEMETRY_SYNC_COOLDOWN = 1800 -- the player asks at most once every 30 minutes
RSConstants.TELEMETRY_SYNC_GROUP_DELAY = 5 -- seconds after joining a group before asking its members
RSConstants.TELEMETRY_SYNC_GROUP_COOLDOWN = 60 -- seconds between the requests to groups
RSConstants.TELEMETRY_SYNC_GROUP_DEBUG_COOLDOWN = 5 -- the same in debug mode
RSConstants.TELEMETRY_SYNC_GROUP_RETRY_INTERVAL = 10 -- seconds to try again if the chat is restricted when joining a group
RSConstants.TELEMETRY_SYNC_GROUP_MAX_ATTEMPTS = 6
RSConstants.TELEMETRY_SYNC_RESPONSE_DELAY = 1 -- the guild members wait a random time before answering, so only a few of them answer
RSConstants.TELEMETRY_SYNC_RESPONSE_JITTER = 5 -- the members with more samples answer in the first half of this time, the rest in the second half
RSConstants.TELEMETRY_SYNC_SECOND_CHANCE_DELAY = 12 -- seconds that a member that was not chosen waits to answer if nobody has claimed the request
RSConstants.TELEMETRY_SYNC_SECOND_CHANCE_MAX_JITTER = 60 -- maximum seconds that the second chance is spread when many members are online
RSConstants.TELEMETRY_SYNC_MAX_ITEMS = 30 -- samples sent in an answer
RSConstants.TELEMETRY_SYNC_EXPECTED_RESPONDERS = 3 -- members that should answer, no matter how many are online
RSConstants.TELEMETRY_SYNC_MESSAGE_INTERVAL = 2 -- seconds between the messages of an answer
RSConstants.TELEMETRY_SYNC_MAX_RESPONSES_PER_MINUTE = 2
RSConstants.TELEMETRY_SYNC_REQUEST_MEMORY = 600 -- a player can't ask again to the same member in 10 minutes
RSConstants.TELEMETRY_SYNC_RECEIVE_WINDOW = 180 -- seconds after asking where the answers are accepted
RSConstants.TELEMETRY_MIN_SAMPLES_SCHEDULE = 6 -- more than the samples that a sender can add to a NPC
RSConstants.TELEMETRY_SCHEDULE_MATCH_RATIO = 0.8
RSConstants.TELEMETRY_MAX_SCHEDULE_MINUTES = 8
RSConstants.TELEMETRY_MIN_SAMPLES_PERIOD = 8
RSConstants.TELEMETRY_MIN_SAMPLES_EXACT = 6 -- more than the samples that a sender can add to a NPC
RSConstants.TELEMETRY_MIN_SAMPLES_RELIABLE = 6 -- respawns needed to trust the maximum and discard the lost cycles (more than the samples that one sender can add)
RSConstants.TELEMETRY_EXACT_TOLERANCE_SECONDS = 60
RSConstants.TELEMETRY_PORTAL_URL = "https://rarescanner-telemetry.pages.dev/"
RSConstants.TELEMETRY_GAME = "forever" -- game of the data in the export, so the portal can filter the data of each game
RSConstants.TELEMETRY_EXPORT_VERSION = 2 -- version of the format that the portal reads
RSConstants.TELEMETRY_EXPORT_MAX_LINES = 200000 -- 50 samples x all the rares fit (the portal accepts 200000); the newest ones go first if there are more