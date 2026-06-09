-- SettingsUI.lua (modern LibEQOLConfig based)
local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local ConfigLib = LibStub("LibEQOLConfig-1.0", true)
local ConfigUILib = LibStub("LibEQOLConfigUI-1.0", true)

-- Optional: Prefix für Settings-Variablen
local prefix = "EQOL_"

addon.SettingsLayout = addon.SettingsLayout or {}
addon.functions = addon.functions or {}
addon.ConfigCurrentGroupByPageID = addon.ConfigCurrentGroupByPageID or {}
addon.ConfigGroupTitleByPageID = addon.ConfigGroupTitleByPageID or {}
addon.ConfigGroupOrderByPageID = addon.ConfigGroupOrderByPageID or {}
addon.ConfigCurrentGroupBySection = addon.ConfigCurrentGroupBySection or {}
addon.ConfigGroupTitleBySection = addon.ConfigGroupTitleBySection or {}
addon.ConfigSectionByParentCheck = addon.ConfigSectionByParentCheck or {}
addon.ConfigControlOrder = addon.ConfigControlOrder or 0
addon.ConfigLastControlByPageID = addon.ConfigLastControlByPageID or {}
addon.ConfigLastControlBySection = addon.ConfigLastControlBySection or {}
addon.ConfigModernOnlySections = addon.ConfigModernOnlySections or {}
addon.ConfigModernOnlySettings = true

local rootCategoryMap = {
	UI = "interface",
	GENERAL = "general",
	GAMEPLAY = "gameplay",
	SOCIAL = "social",
	ECONOMY = "economy",
	SOUND = "sound",
	SUITES = "suites",
	PROFILES = "profiles",
}

local function createModernCategory(id, name)
	local category = {
		id = tostring(id or name or "modern"),
		name = name or id or "Modern",
		modernOnly = true,
	}
	function category:GetID()
		return self.id
	end
	function category:GetName()
		return self.name
	end
	return category
end

local newSettingsAssetRoot = "Interface\\AddOns\\EnhanceQoL\\Assets\\NewSettings\\"
local function newSettingsAsset(fileName)
	return newSettingsAssetRoot .. fileName
end

local function getLocaleKeyForText(text)
	if type(text) ~= "string" or text == "" then return nil end
	for key, value in pairs(L) do
		if type(key) == "string" and value == text then
			return key
		end
	end
	return nil
end

local pageIconKeysByStableID = {
	ActionBarsAndButtons = "actionbar",
	AutoSellRules = "autosell",
	BagsInventory = "bags",
	Bank = "bank",
	BarsAndResources = "resource",
	CastbarsAndCooldowns = "castbar",
	ChatBubbles = "chatbubbles",
	ChatHistory = "chathistory",
	ChatWindow = "chatwindow",
	ClassBuffReminder = "buff",
	CombatLogging = "combatlogging",
	ContainerActions = "containeractions",
	CooldownPanels = "cooldownpanels",
	CustomUnitFrames = "unitframes",
	DataPanel = "data",
	DamageMeter = "damagemeterprofile",
	DialogsConfirmations = "dialogsconfirmations",
	DungeonsMythicPlus = "dungeons",
	EconomyCraftingOrders = "crafting",
	EQoLCastbar = "castbar",
	GearUpgrades = "gearupgrades",
	GroupToolsCombatAlerts = "combat",
	GroupToolsFocusMarker = "focus",
	InstantMessenger = "instantmessenger",
	Loot = "loot",
	MacrosConsumables = "macros",
	Mailbox = "mailbox",
	MapNavigation = "map",
	MouseAccessibility = "mouseaccessibility",
	MovementInput = "movementinput",
	Mover = "mover",
	Nameplates = "nameplate",
	PopupsAndUITweaks = "popups",
	PrivacyBlockingIgnore = "privacy",
	ProfilesAddOn = "addonprofile",
	ProfilesBagsCategories = "bagscategories",
	ProfilesDamageMeter = "damagemeterprofile",
	ProfilesGlobalFont = "settingspage",
	ProfilesHBP = "healerbuffplacementprofile",
	ProfilesImportProtection = "importexport",
	ProfilesResourceBars = "resource",
	Questing = "questing",
	ResourceBars = "resource",
	SharedMedia = "soundsettings",
	SharedMediaDeepVoiceSounds = "soundsettings",
	SocialGeneral = "privacy",
	SystemAndDebug = "systemdebug",
	TalentReminder = "talentreminder",
	Teleports = "teleports",
	Tooltip = "tooltip",
	UFProfiles = "unitframes",
	ufStandalonePrivateAurasExpandable = "privateaura",
	UnitFrames = "unitframes",
	VendorDestroyQueue = "includelists",
	VendorIncludeExclude = "includelists",
	VendorQuickActions = "vendor",
	VisibilityFrames = "visibility",
}

local pageDescriptionKeysByStableID = {
	ActionBarsAndButtons = "configCenterPageCardDescActionBars",
	ActionTracker = "configCenterPageCardDescActionTracker",
	AuctionHouse = "configCenterPageCardDescAuctionHouse",
	AutoSellRules = "configCenterPageCardDescAutoSell",
	BagsInventory = "configCenterPageCardDescBagsInventory",
	Bank = "configCenterPageCardDescBank",
	BarsAndResources = "configCenterPageCardDescBarsResources",
	CastbarsAndCooldowns = "configCenterPageCardDescCastbarsCooldowns",
	ChatBubbles = "configCenterPageCardDescChatBubbles",
	ChatHistory = "configCenterPageCardDescChatHistory",
	ChatWindow = "configCenterPageCardDescChatWindow",
	ClassBuffReminder = "configCenterPageCardDescClassBuffReminder",
	CombatLogging = "configCenterPageCardDescCombatLogging",
	ContainerActions = "configCenterPageCardDescContainerActions",
	CooldownPanels = "configCenterPageCardDescCooldownPanels",
	CustomUnitFrames = "configCenterPageCardDescUnitFrames",
	DataPanel = "configCenterPageCardDescDataPanels",
	DeathResurrect = "configCenterPageCardDescDeath",
	DialogsConfirmations = "configCenterPageCardDescDialogsConfirmations",
	DungeonsMythicPlus = "configCenterPageCardDescDungeons",
	EconomyCraftingOrders = "configCenterPageCardDescCraftingOrders",
	EQoLCastbar = "configCenterPageCardDescEQoLCastbar",
	FriendsCommunities = "configCenterPageCardDescFriendsCommunities",
	GearUpgrades = "configCenterPageCardDescGearUpgrades",
	GoldTracking = "configCenterPageCardDescTrackingMoney",
	GroupFinder = "configCenterPageCardDescGroupFinder",
	GroupToolsCombatAlerts = "configCenterPageCardDescCombatAlerts",
	GroupToolsFocusMarker = "configCenterPageCardDescFocusMarker",
	InstantMessenger = "configCenterPageCardDescInstantMessenger",
	Loot = "configCenterPageCardDescLoot",
	MacrosConsumables = "configCenterPageCardDescMacrosConsumables",
	Mailbox = "configCenterPageCardDescMailbox",
	MapNavigation = "configCenterPageCardDescMapNavigation",
	Merchant = "configCenterPageCardDescMerchant",
	MouseAccessibility = "configCenterPageCardDescMovementInput",
	MovementInput = "configCenterPageCardDescMovementInput",
	Mover = "configCenterPageCardDescMover",
	Nameplates = "configCenterPageCardDescNameplates",
	PopupsAndUITweaks = "configCenterPageCardDescPopupsUITweaks",
	PrivacyBlockingIgnore = "configCenterPageCardDescPrivacyBlockingIgnore",
	ProfilesAddOn = "configCenterPageCardDescAddOn",
	ProfilesBagsCategories = "configCenterPageCardDescBagsCategories",
	ProfilesDamageMeter = "configCenterPageCardDescProfilesDamageMeter",
	ProfilesGlobalFont = "configCenterPageCardDescProfilesGlobalFont",
	ProfilesHBP = "configCenterPageCardDescProfilesHealerBuffPlacement",
	ProfilesImportProtection = "configCenterPageCardDescProfilesImportProtection",
	ProfilesResourceBars = "configCenterPageCardDescProfilesResourceBars",
	Questing = "configCenterPageCardDescQuesting",
	ResourceBars = "configCenterPageCardDescBarsResources",
	Skinner = "configCenterPageCardDescSkinner",
	SharedMedia = "configCenterPageCardDescSharedMedia",
	SharedMediaDeepVoiceSounds = "configCenterPageCardDescSharedMediaDeepVoiceSounds",
	SoundAudioDevice = "configCenterPageCardDescSoundAudioDevice",
	SoundExtra = "configCenterPageCardDescSoundExtra",
	SoundMute = "configCenterPageCardDescSoundMute",
	SystemAndDebug = "configCenterPageCardDescSystemDebug",
	Teleports = "configCenterPageCardDescDungeons",
	Tooltip = "configCenterPageCardDescTooltip",
	UFProfiles = "configCenterPageCardDescProfilesUnitFrames",
	ufStandalonePrivateAurasExpandable = "configCenterPageCardDescStandalonePrivateAuras",
	UnitFrames = "configCenterPageCardDescUnitFrames",
	VendorDestroyQueue = "configCenterPageCardDescVendorDestroyQueue",
	VendorIncludeExclude = "configCenterPageCardDescVendorIncludeExclude",
	VendorQuickActions = "configCenterPageCardDescVendor",
	VendorsServices = "configCenterPageCardDescRepairOptions",
	VisibilityFrames = "configCenterPageCardDescVisibilityFrames",
}

local function splitVersionBadge(version)
	version = tostring(version or "")
	local base, suffix = version:match("^(.-)%-beta([%w%.%-]*)$")
	if base and base ~= "" then
		local number = tostring(suffix or ""):match("^(%d+)")
		return base, number and ("Beta " .. number) or "Beta"
	end
	base, suffix = version:match("^(.-)%-alpha([%w%.%-]*)$")
	if base and base ~= "" then
		local number = tostring(suffix or ""):match("^(%d+)")
		return base, number and ("Alpha " .. number) or "Alpha"
	end
	return version, nil
end

local function showConfigCenterCopyURL(url)
	if not StaticPopupDialogs["ENHANCEQOL_COPY_URL"] then
		StaticPopupDialogs["ENHANCEQOL_COPY_URL"] = {
			text = L["copyUrlPopupText"],
			button1 = OKAY,
			hasEditBox = true,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self, data)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if not editBox then return end
				editBox:SetAutoFocus(true)
				editBox:SetText(data or "")
				editBox:HighlightText()
				editBox:SetCursorPosition(0)
			end,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		}
	end
	StaticPopup_Show("ENHANCEQOL_COPY_URL", nil, nil, url)
end

local function getConfigCenterSlashCommandContent()
	local settingEnabledNote = L["rootSlashCommandNoteSettingEnabled"] or "Only if enabled in settings."
	local macroNote = L["rootSlashCommandNoteUseInMacro"] or "Use this in a macro."
	return {
		{
			title = L["rootSlashCommandsHeader"] or "Slash Commands",
			entries = {
				{ type = "text", text = L["rootSlashCommandsDesc"] or "Type these in chat." },
				{ type = "text", text = L["rootSlashCommandsConflictDesc"] or "Aliases may be taken by another add-on." },
			},
		},
		{
			title = L["General"] or "General",
			entries = {
				{ type = "command", commands = { "/eqol" }, desc = L["rootSlashCommandSettingsDesc"] or "Open the EnhanceQoL settings." },
				{ type = "command", commands = { "/rl" }, desc = L["rootSlashCommandReloadUIDesc"] or "Reload UI.", note = settingEnabledNote },
			},
		},
		{
			title = L["rootSlashCommandsUIHeader"] or "UI & Editors",
			entries = {
				{ type = "command", commands = { "/ecd", "/cpe" }, desc = L["rootSlashCommandCooldownPanelsDesc"] or "Open the Cooldown Panels editor." },
				{ type = "command", commands = { "/cdm", "/wa" }, desc = L["rootSlashCommandCooldownViewerDesc"] or "Open the Blizzard Cooldown Viewer settings.", note = settingEnabledNote },
				{ type = "command", commands = { "/em", "/edit", "/editmode" }, desc = L["rootSlashCommandEditModeDesc"] or "Open Edit Mode.", note = settingEnabledNote },
				{ type = "command", commands = { "/kb" }, desc = L["rootSlashCommandQuickKeybindDesc"] or "Open Quick Keybind Mode.", note = settingEnabledNote },
				{ type = "command", commands = { "/ccb", "/clickcast" }, desc = L["rootSlashCommandClickCastDesc"] or "Open Click Cast Bindings.", note = settingEnabledNote },
			},
		},
		{
			title = L["Unit Frames"] or "Unit Frames",
			entries = {
				{ type = "command", commands = { "/eqol hbp" }, desc = L["rootSlashCommandHealerBuffPlacementDesc"] or "Open the healer buff placement editor for party or raid frames." },
			},
		},
		{
			title = L["rootSlashCommandsNavigationHeader"] or "Navigation & Group",
			entries = {
				{ type = "command", commands = { "/way" }, usage = " [mapID] 37.8 61.2", desc = L["rootSlashCommandWayDesc"] or "Set a waypoint on the world map.", note = settingEnabledNote },
				{ type = "command", commands = { "/pull" }, usage = " [seconds]", desc = L["rootSlashCommandPullTimerDesc"] or "Start the Blizzard pull countdown.", note = settingEnabledNote },
			},
		},
		{
			title = L["rootSlashCommandsMacroHeader"] or "Macro Examples",
			entries = {
				{ type = "command", commands = { "/click EQOLRandomHearthstoneButton LeftButton 1" }, desc = L["rootSlashCommandRandomHearthstoneDesc"] or "Use random hearthstone." },
				{ type = "command", commands = { "/click EQOLRandomMountButton LeftButton 1" }, desc = L["rootSlashCommandRandomMountDesc"] or "Use random mount." },
				{ type = "command", commands = { "/click EQOLRepairMountButton LeftButton 1" }, desc = L["rootSlashCommandRepairMountDesc"] or "Use repair mount.", note = macroNote },
				{ type = "command", commands = { "/click EQOLAuctionMountButton LeftButton 1" }, desc = L["rootSlashCommandAuctionMountDesc"] or "Use Auction House mount.", note = macroNote },
			},
		},
		{
			title = L["rootSlashCommandsSocialHeader"] or "Chat & Social",
			entries = {
				{ type = "command", commands = { "/eim" }, desc = L["rootSlashCommandInstantMessengerDesc"] or "Open the Instant Messenger window.", note = L["rootSlashCommandNoteChatIMEnabled"] or "Only if Instant Messenger is enabled." },
				{ type = "command", commands = { "/eil" }, desc = L["rootSlashCommandIgnoreDesc"] or "Open the enhanced ignore list.", note = L["rootSlashCommandNoteIgnoreEnabled"] or "Only if Ignore is enabled." },
			},
		},
		{
			title = L["rootSlashCommandsDiagnosticsHeader"] or "Diagnostics & Utilities",
			entries = {
				{ type = "command", commands = { "/eqol aag" }, usage = " <gossipOptionID>", desc = L["rootSlashCommandAutoGossipAddDesc"] or "Add a gossip option ID to the auto-select list." },
				{ type = "command", commands = { "/eqol rag" }, usage = " <gossipOptionID>", desc = L["rootSlashCommandAutoGossipRemoveDesc"] or "Remove a gossip option ID from the auto-select list." },
				{ type = "command", commands = { "/eqol lag" }, desc = L["rootSlashCommandAutoGossipListDesc"] or "List the gossip option IDs from the current gossip window." },
			},
		},
	}
end

local function getConfigCenterChangelogContent()
	local data = addon.GeneratedChangelog
	local releases = data and data.releases
	if type(releases) ~= "table" or #releases == 0 then
		return {
			{
				title = L["configCenterChangelog"] or "Changelog",
				entries = {
					{ type = "text", text = L["configCenterChangelogEmpty"] or "No changelog information is available for this build." },
				},
			},
		}
	end

	local content = {}
	for _, release in ipairs(releases) do
		local title = tostring(release.tag or "")
		if release.date and release.date ~= "" then title = title .. " - " .. tostring(release.date) end
		local entries = {}
		for _, section in ipairs(release.sections or {}) do
			local sectionTitle = tostring(section.title or "")
			if sectionTitle ~= "" then
				entries[#entries + 1] = { type = "text", text = "|cffffd700" .. sectionTitle .. "|r" }
			end
			for _, item in ipairs(section.items or {}) do
				entries[#entries + 1] = { type = "text", text = "|cffffd700- |r" .. tostring(item or "") }
			end
			entries[#entries + 1] = { type = "spacer", height = 6 }
		end
		content[#content + 1] = {
			title = title ~= "" and title or (L["configCenterChangelog"] or "Changelog"),
			entries = entries,
		}
	end
	return content
end

local function ensureConfigApp()
	if addon.ConfigApp or not ConfigLib then return addon.ConfigApp end

	local app = ConfigLib:RegisterAddOn(addonName, {
		title = "Enhance QoL",
		settingsTitle = L["configCenterTitle"] or "EnhanceQoL Settings",
		dashboardTitle = L["configCenterDashboard"] or "Dashboard",
		icon = "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga",
		blizzardSettingsRoot = true,
		openSettings = function()
			addon.functions.OpenConfigCenter()
		end,
		pageDescriptionKeys = pageDescriptionKeysByStableID,
		addonFolder = addonName,
		assetRoot = "Interface\\AddOns\\EnhanceQoL\\libs\\LibSettingsDesigner\\Assets\\",
		density = "compact",
		showDensityButton = false,
		getSize = function()
			local size = addon.db and addon.db.configCenterSize
			if type(size) == "table" then
				return size.width, size.height
			end
		end,
		setSize = function(width, height)
			if not addon.db then return end
			addon.db.configCenterSize = {
				width = width,
				height = height,
			}
		end,
		categoryIconTextures = {
			dashboard = newSettingsAsset("Cogwheel.tga"),
			economy = newSettingsAsset("Economy.tga"),
			gameplay = newSettingsAsset("Gameplay.tga"),
			general = newSettingsAsset("General.tga"),
			interface = newSettingsAsset("Interface.tga"),
			profiles = newSettingsAsset("Profiles.tga"),
			social = newSettingsAsset("Social.tga"),
			sound = newSettingsAsset("SoundSettings.tga"),
			suites = newSettingsAsset("AddonProfile.tga"),
		},
		iconTextures = {
			actionbar = newSettingsAsset("ActionBarsButtons.tga"),
			actiontracker = newSettingsAsset("ActionTracker.tga"),
			addonprofile = newSettingsAsset("AddonProfile.tga"),
			auction = newSettingsAsset("Auction.tga"),
			autosell = newSettingsAsset("AutoSell.tga"),
			bags = newSettingsAsset("BagsCategories.tga"),
			bagscategories = newSettingsAsset("BagsCategories.tga"),
			bars = newSettingsAsset("BarsResources.tga"),
			bank = newSettingsAsset("Bank.tga"),
			buff = newSettingsAsset("ClassBuffReminder.tga"),
			castbar = newSettingsAsset("CastbarsCooldowns.tga"),
			chat = newSettingsAsset("ChatWindow.tga"),
			chatbubbles = newSettingsAsset("ChatBubbles.tga"),
			chathistory = newSettingsAsset("ChatHistory.tga"),
			chatwindow = newSettingsAsset("ChatWindow.tga"),
			combat = newSettingsAsset("CombatAlerts.tga"),
			combatlogging = newSettingsAsset("CombatLogging.tga"),
			community = newSettingsAsset("FriendsCommunities.tga"),
			containeractions = newSettingsAsset("ContainerActions.tga"),
			cooldown = newSettingsAsset("CastbarsCooldowns.tga"),
			cooldownpanels = newSettingsAsset("CastbarsCooldowns.tga"),
			crafting = newSettingsAsset("CraftingOrders.tga"),
			damagemeterprofile = newSettingsAsset("DamageMeterProfile.tga"),
			dashboard = newSettingsAsset("Cogwheel.tga"),
			data = newSettingsAsset("DataPanels.tga"),
			death = newSettingsAsset("DeathResurrection.tga"),
			diagnostics = newSettingsAsset("SystemDebug.tga"),
			dialogsconfirmations = newSettingsAsset("DialogsConfirmations.tga"),
			dungeons = newSettingsAsset("DungeonsMythic.tga"),
			economy = newSettingsAsset("Economy.tga"),
			focus = newSettingsAsset("FocusMarker.tga"),
			gameplay = newSettingsAsset("Gameplay.tga"),
			gearupgrades = newSettingsAsset("GearUpgrades.tga"),
			general = newSettingsAsset("General.tga"),
			goldtracking = newSettingsAsset("GoldTracking.tga"),
			groupfinder = newSettingsAsset("GroupFinder.tga"),
			healerbuffplacementprofile = newSettingsAsset("HealerBuffPlacementProfile.tga"),
			help = newSettingsAsset("QuickReference.tga"),
			importexport = newSettingsAsset("ExportImport.tga"),
			includelists = newSettingsAsset("IncludeExcludeLists.tga"),
			instantmessenger = newSettingsAsset("InstantMessenger.tga"),
			interface = newSettingsAsset("Interface.tga"),
			loot = newSettingsAsset("LootRewards.tga"),
			macros = newSettingsAsset("MacrosConsumables.tga"),
			mailbox = newSettingsAsset("Mailbox.tga"),
			map = newSettingsAsset("MapMinimap.tga"),
			markers = newSettingsAsset("Markers.tga"),
			mouseaccessibility = newSettingsAsset("MouseAccessibility.tga"),
			movementinput = newSettingsAsset("MovementInput.tga"),
			mover = newSettingsAsset("Mover.tga"),
			nameplate = newSettingsAsset("NameplatesNames.tga"),
			popups = newSettingsAsset("PopupsUITweaks.tga"),
			privateaura = newSettingsAsset("StandalonePrivateAuras.tga"),
			privacy = newSettingsAsset("PrivacyBlockingIgnore.tga"),
			profiles = newSettingsAsset("Profiles.tga"),
			questing = newSettingsAsset("QuestingCinematics.tga"),
			reset = newSettingsAsset("Revert.tga"),
			resource = newSettingsAsset("BarsResources.tga"),
			repair = newSettingsAsset("RepairOptions.tga"),
			settingspage = newSettingsAsset("SettingsPage.tga"),
			skinner = newSettingsAsset("Skinner.tga"),
			social = newSettingsAsset("Social.tga"),
			sound = newSettingsAsset("Sound.tga"),
			soundsettings = newSettingsAsset("SoundSettings.tga"),
			support = newSettingsAsset("Question.tga"),
			systemdebug = newSettingsAsset("SystemDebug.tga"),
			talentreminder = newSettingsAsset("TalentReminder.tga"),
			teleports = newSettingsAsset("Teleports.tga"),
			tooltip = newSettingsAsset("Tooltip.tga"),
			unitframes = newSettingsAsset("UnitFrames.tga"),
			uiutilities = newSettingsAsset("UIUtilities.tga"),
			vendor = newSettingsAsset("VendorsServices.tga"),
			vendorsservices = newSettingsAsset("VendorsServices.tga"),
			visibility = newSettingsAsset("VisibilityFading.tga"),
		},
		db = function() return addon.db end,
		profile = function() return addon.db end,
		locale = L,
		dashboard = function()
			return {
				hero = {
					title = L["configCenterTitle"] or "EnhanceQoL Settings",
					subtitle = L["configCenterIntro"],
					iconKey = "dashboard",
				},
				cards = {
					{
						title = L["configCenterQuickReference"],
						description = L["configCenterQuickReferenceDesc"],
						iconKey = "help",
						pageID = "help.quick-reference",
					},
					{
						title = L["configCenterSupportFeedback"],
						description = L["configCenterSupportFeedbackDesc"],
						iconKey = "support",
						pageID = "help.support-feedback",
					},
				},
				status = {
					title = L["configCenterAddOnStatus"] or (_G.STATUS or "Status"),
					tiles = function(_, stats)
						local tiles = {
							{
								icon = "Interface\\RaidFrame\\ReadyCheck-Ready",
								title = L["configCenterCustomized"] or "Customized",
								value = tostring(stats.customized or 0) .. " / " .. tostring(stats.customizable or stats.controls or 0),
							},
						}
						local profileCount = 0
						if EnhanceQoLDB and type(EnhanceQoLDB.profiles) == "table" then
							for profileName in pairs(EnhanceQoLDB.profiles) do
								if type(profileName) == "string" and profileName ~= "" then profileCount = profileCount + 1 end
							end
						end
						if profileCount > 0 then
							tiles[#tiles + 1] = {
								icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
								title = L["Profiles"] or "Profiles",
								value = tostring(profileCount),
							}
						end
						local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")
						if version then
							local versionValue, versionBadge = splitVersionBadge(version)
							tiles[#tiles + 1] = {
								atlas = "worldquest-tracker-questmarker",
								title = _G.GAME_VERSION_LABEL or L["configCenterVersion"] or "Version",
								value = versionValue,
								badge = versionBadge,
								onClick = function(state)
									if state and state.SetPage then state:SetPage("help.changelog") end
								end,
							}
						end
						local newCount = tonumber(stats and stats.newControls) or 0
						if newCount > 0 then
							tiles[#tiles + 1] = {
								atlas = "collections-icon-favorites",
								title = L["configCenterNewInVersion"] or "New in this Version",
								value = tostring(newCount),
								searchQuery = "tag:new",
							}
						end
						return tiles
					end,
				},
				features = {
					enabledTitle = L["configCenterEnabledFeatures"],
					customizedTitle = L["configCenterCustomizedFeatures"],
					enabledBadge = _G.ENABLED,
					customizedBadge = L["configCenterCustomized"],
					limit = 5,
				},
				newEntries = {
					title = L["configCenterNewInVersion"],
					limit = 5,
				},
			}
		end,
		version = function()
			return C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")
		end,
		newCount = function()
			local appInstance = addon.ConfigApp
			local stats = appInstance and appInstance.GetStats and appInstance:GetStats()
			return stats and stats.newControls or 0
		end,
		isNewTag = function(tagID)
			local newTags = addon.variables and addon.variables.NewVersionTableEQOL
			if not tagID or type(newTags) ~= "table" then return false end
			local key = tostring(tagID)
			return newTags[key] == true or newTags[prefix .. key] == true or newTags[prefix .. "_" .. key] == true
		end,
		profileCount = function()
			local count = 0
			if EnhanceQoLDB and type(EnhanceQoLDB.profiles) == "table" then
				for profileName in pairs(EnhanceQoLDB.profiles) do
					if type(profileName) == "string" and profileName ~= "" then count = count + 1 end
				end
			end
			return count
		end,
		openLegacySettings = function(control)
			if not (control and control.type == "keybind") then
				return
			end
			if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
				local scrollToElementName
				if control.bindingIndex and GetBinding then
					local _, bindingCategory = GetBinding(control.bindingIndex)
					if bindingCategory then
						scrollToElementName = _G[bindingCategory] or bindingCategory
					end
				end
				Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, scrollToElementName)
			end
		end,
	})

	app:RegisterCategory({ id = "interface", title = _G["INTERFACE_LABEL"] or "Interface", order = 100, iconAtlas = "hud-microbutton-character-up" })
	app:RegisterCategory({ id = "general", title = _G["GENERAL"] or "General", order = 200, iconAtlas = "communities-icon-chat" })
	app:RegisterCategory({ id = "gameplay", title = _G["SETTING_GROUP_GAMEPLAY"] or "Gameplay", order = 300, iconAtlas = "bags-button-autosort-up" })
	app:RegisterCategory({ id = "social", title = _G["SOCIAL_LABEL"] or L["configCenterChatSocial"] or "Chat & Social", order = 400, iconAtlas = "socialqueuing-icon-group" })
	app:RegisterCategory({ id = "economy", title = L["Economy"] or "Economy", order = 500, iconAtlas = "auctionhouse-icon-favorite" })
	app:RegisterCategory({ id = "sound", title = _G["SOUND"] or "Sound", order = 600, iconAtlas = "poi-door-arrow-down" })
	app:RegisterCategory({ id = "suites", title = L["configCenterSuites"] or "EQoL Suites", order = 700, iconAtlas = "communities-icon-notification" })
	app:RegisterCategory({ id = "profiles", title = L["Profiles"] or "Profiles", order = 800, iconAtlas = "services-icon-warning" })
	app:RegisterPage({
		id = "help.quick-reference",
		title = L["configCenterQuickReference"],
		description = L["configCenterQuickReferenceDesc"],
		iconKey = "help",
		layout = "info",
		content = getConfigCenterSlashCommandContent(),
	})
	app:RegisterPage({
		id = "help.support-feedback",
		title = L["configCenterSupportFeedback"],
		description = L["configCenterSupportFeedbackDesc"],
		iconKey = "support",
		layout = "info",
		content = {
			{
				title = L["configCenterSupportDiscordTitle"],
				entries = {
					{ type = "text", text = L["configCenterSupportDiscordDesc"] },
					{
						type = "button",
						text = L["configCenterSupportDiscordButton"],
						width = 220,
						onClick = function()
							showConfigCenterCopyURL(L["configCenterSupportDiscordURL"] or "https://discord.gg/kqQfG9YhVn")
						end,
					},
				},
			},
		},
	})
	app:RegisterPage({
		id = "help.changelog",
		title = L["configCenterChangelog"] or "Changelog",
		description = L["configCenterChangelogDesc"] or "Review the release notes included with this build.",
		iconKey = "settingspage",
		layout = "info",
		content = getConfigCenterChangelogContent(),
	})
	app:SetDefaultPage("dashboard")

	addon.ConfigApp = app
	return app
end

local function resolveLegacyPageID(app, cbData, category)
	if not app then return nil end
	if cbData and cbData.pageID then return cbData.pageID end
	if cbData and cbData.parentSection and app.legacySections then
		local pageID = app.legacySections[cbData.parentSection]
		if pageID then return pageID end
	end
	if cbData and cbData.parentSection and addon.ConfigSectionByParentCheck and app.legacySections then
		local section = addon.ConfigSectionByParentCheck[cbData.parentSection]
		if section then return app.legacySections[section] end
	end
	if category and app.legacyCategories then
		local key
		if type(category) == "table" and category.GetID then
			local ok, id = pcall(category.GetID, category)
			if ok and id ~= nil then key = "id:" .. tostring(id) end
		end
		if not key and type(category) == "table" and category.GetName then
			local ok, name = pcall(category.GetName, category)
			if ok and name ~= nil then key = "name:" .. tostring(name) end
		end
		key = key or tostring(category)
		local categoryID = app.legacyCategories[key]
		if categoryID then return categoryID .. ".settings" end
	end
	return nil
end

function addon.functions.RegisterConfigParentSection(parentCheck, section)
	if type(parentCheck) ~= "function" or not section then return parentCheck end
	addon.ConfigSectionByParentCheck = addon.ConfigSectionByParentCheck or {}
	addon.ConfigSectionByParentCheck[parentCheck] = section
	return parentCheck
end

local function resolveConfigSection(sectionOrParentCheck)
	if addon.ConfigSectionByParentCheck and addon.ConfigSectionByParentCheck[sectionOrParentCheck] then
		return addon.ConfigSectionByParentCheck[sectionOrParentCheck]
	end
	return sectionOrParentCheck
end

local function isModernOnlySection(sectionOrParentCheck)
	if addon.ConfigModernOnlySettings == true then return true end
	local section = resolveConfigSection(sectionOrParentCheck)
	return section and addon.ConfigModernOnlySections and addon.ConfigModernOnlySections[section] == true
end

local function createModernOnlySection(data)
	local section = {
		data = {
			expanded = data and data.expanded ~= false,
			name = data and (data.name or data.text) or "Section",
		},
		modernOnly = true,
	}
	function section:IsExpanded()
		return self.data and self.data.expanded ~= false
	end
	function section:GetExtent()
		return data and data.extent or 25
	end
	return section
end

local function createModernOnlySetting(key, cbData)
	local setting = {}
	local function valuesMatch(left, right)
		if left == right then return true end
		if type(left) == "number" or type(right) == "number" then
			left = tonumber(left)
			right = tonumber(right)
			return left ~= nil and right ~= nil and math.abs(left - right) < 0.000001
		end
		return false
	end
	local function readValue()
		if cbData and type(cbData.get) == "function" then
			local ok, value = pcall(cbData.get)
			if ok then return value, true end
		end
		if cbData and cbData.var and addon.db then
			local value = addon.db[cbData.var]
			if cbData.subvar then
				if type(value) == "table" and value[cbData.subvar] ~= nil then
					return value[cbData.subvar], true
				end
			elseif value ~= nil then
				return value, true
			end
		end
		if cbData and cbData.default ~= nil then
			return cbData.default, true
		end
		return nil, false
	end
	local function writeValue(value)
		if not (cbData and cbData.var) then return false end
		addon.db = addon.db or {}
		if cbData.subvar then
			addon.db[cbData.var] = type(addon.db[cbData.var]) == "table" and addon.db[cbData.var] or {}
			addon.db[cbData.var][cbData.subvar] = value
		else
			addon.db[cbData.var] = value
		end
		return true
	end
	local function didPersist(value)
		local current, known = readValue()
		return known and valuesMatch(current, value)
	end
	local function setValue(value)
		if cbData and type(cbData.func) == "function" then
			local ok = pcall(cbData.func, value)
			if ok and didPersist(value) then return end
			if ok and not (cbData.get or cbData.var) then return end
			writeValue(value)
		elseif cbData and type(cbData.set) == "function" then
			local ok = pcall(cbData.set, value, value)
			if ok and didPersist(value) then return end
			if ok and not (cbData.get or cbData.var) then return end
			writeValue(value)
		else
			writeValue(value)
		end
	end
	function setting:GetValue()
		local value = readValue()
		return value
	end
	function setting:SetValue(value) setValue(value) end
	function setting:GetVariable()
		return prefix .. tostring(key or (cbData and cbData.var) or "setting")
	end
	return setting
end

local function rememberModernOnlyElement(key, setting)
	addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
	if key then
		addon.SettingsLayout.elements[key] = { setting = setting, element = nil, modernOnly = true }
	end
	return addon.SettingsLayout.elements[key]
end

local function getDefaultGroupID(app, pageID)
	if not app or not pageID then return nil end
	local groupID = "settings"
	if not app:GetPage(pageID).groupsByID[groupID] then
		app:RegisterGroup(pageID, {
			id = groupID,
			title = _G.SETTINGS or "Settings",
			order = 100000,
		})
	end
	return groupID, _G.SETTINGS or "Settings"
end

local function getLegacyControlGroup(app, category, cbData)
	local pageID = resolveLegacyPageID(app, cbData, category)
	if not pageID or not app:GetPage(pageID) then return nil, nil, pageID end
	if cbData.groupID or cbData.modernGroup then
		local groupID = cbData.groupID or cbData.modernGroup
		local groupTitle = cbData.groupTitle or cbData.groupName or groupID
		app:RegisterGroup(pageID, {
			id = groupID,
			title = groupTitle,
			order = cbData.groupOrder,
		})
		return groupID, groupTitle, pageID
	end
	if cbData.parentSection and addon.ConfigCurrentGroupBySection[cbData.parentSection] then
		local groupID = addon.ConfigCurrentGroupBySection[cbData.parentSection]
		return groupID, addon.ConfigGroupTitleBySection[cbData.parentSection], pageID
	end
	if cbData.parentSection and addon.ConfigSectionByParentCheck then
		local section = addon.ConfigSectionByParentCheck[cbData.parentSection]
		if section and addon.ConfigCurrentGroupBySection[section] then
			local groupID = addon.ConfigCurrentGroupBySection[section]
			return groupID, addon.ConfigGroupTitleBySection[section], pageID
		end
	end
	local groupID = addon.ConfigCurrentGroupByPageID[pageID]
	if groupID then return groupID, addon.ConfigGroupTitleByPageID[pageID], pageID end
	local groupTitle
	groupID, groupTitle = getDefaultGroupID(app, pageID)
	return groupID, groupTitle, pageID
end

function addon.functions.OpenConfigCenter(pageID, focusControlID)
	local app = ensureConfigApp()
	if ConfigUILib and app then
		addon.ConfigCenterFrame = ConfigUILib:Open(app, pageID, focusControlID)
		return
	end
end

function addon.functions.HideConfigCenterUntilFrameHidden(externalFrame)
	if not (ConfigUILib and externalFrame and externalFrame.HookScript) then return end
	local app = ensureConfigApp()
	if not app then return end
	local frame = ConfigUILib.GetFrame and ConfigUILib:GetFrame(app) or addon.ConfigCenterFrame
	if not (frame and frame.IsShown and frame:IsShown()) then return end
	local state = frame._LibEQOLConfigState
	local restorePageID = state and state.view == "page" and state.selectedPageID or nil
	frame:Hide()
	externalFrame._eqolConfigCenterRestore = {
		app = app,
		pageID = restorePageID,
	}
	if externalFrame._eqolConfigCenterRestoreHooked then return end
	externalFrame._eqolConfigCenterRestoreHooked = true
	externalFrame:HookScript("OnHide", function(self)
		local restore = self._eqolConfigCenterRestore
		self._eqolConfigCenterRestore = nil
		if restore and ConfigUILib and restore.app then
			addon.ConfigCenterFrame = ConfigUILib:Open(restore.app, restore.pageID)
		end
	end)
end

local function registerLegacyCategory(category, title, newTagID)
	local app = ensureConfigApp()
	if not app then return end
	local categoryID = rootCategoryMap[newTagID] or ConfigLib:NormalizeID(title or newTagID or "advanced")
	app:RegisterLegacyCategory(category, {
		categoryID = categoryID,
		title = title,
		order = categoryID == "advanced" and 800 or nil,
	})
end

local function registerLegacyControl(category, cbData, controlType, setting)
	local app = ensureConfigApp()
	if not app or type(cbData) ~= "table" then return end
	local key = cbData.var or cbData.key
	local id = cbData.id or (key and cbData.subvar and (tostring(key) .. "." .. tostring(cbData.subvar))) or key or cbData.text or cbData.label or cbData.name
	if not id then return end
	addon.ConfigControlOrder = (addon.ConfigControlOrder or 0) + 1
	local groupID, groupTitle, pageID = getLegacyControlGroup(app, category, cbData)
	local explicitDefault = cbData.modernDefault
	if explicitDefault == nil then explicitDefault = cbData.default end
	local registryDefault = key and function()
		local defaults = addon.dbDefaults
		if type(defaults) == "table" and defaults[key] ~= nil then
			if cbData.subvar and type(defaults[key]) == "table" then
				return defaults[key][cbData.subvar]
			end
			return defaults[key]
		end
		if type(explicitDefault) == "function" then
			return explicitDefault()
		end
		return explicitDefault
	end or explicitDefault
	local control = app:RegisterLegacyControl({
		legacyCategory = category,
		parentSection = cbData.parentSection,
		pageID = pageID,
		id = id,
		key = key,
		subvar = cbData.subvar,
		type = controlType,
		label = cbData.text or cbData.label or cbData.name,
		description = cbData.modernDescription or cbData.desc,
		default = registryDefault,
		dbDefault = key and function()
			local defaults = addon.dbDefaults
			if type(defaults) == "table" and defaults[key] ~= nil then
				if cbData.subvar and type(defaults[key]) == "table" then
					return defaults[key][cbData.subvar], defaults[key][cbData.subvar] ~= nil
				end
				return defaults[key], true
			end
			return nil, false
		end or nil,
		keywords = cbData.searchtags,
		level = cbData.level,
		trackCustomized = cbData.trackCustomized,
		order = type(cbData.order) == "number" and cbData.order or addon.ConfigControlOrder,
		newTagID = cbData.newTagID,
		groupID = groupID,
		groupTitle = groupTitle,
		setting = setting,
		getValue = cbData.get,
		setValue = cbData.func or cbData.set,
		parentCheck = cbData.parentCheck,
		isEnabled = cbData.isEnabled,
		hidden = cbData.hidden,
		visible = cbData.visible,
		isVisible = cbData.isVisible,
		visibleWhen = cbData.visibleWhen,
		hiddenWhen = cbData.hiddenWhen,
		refreshOnChange = cbData.refreshOnChange,
		isMainToggle = cbData.isMainToggle,
		uiRole = cbData.uiRole,
		min = cbData.min,
		max = cbData.max,
		step = cbData.step,
		formatter = cbData.formatter,
		suffix = cbData.suffix,
		valueFormatter = cbData.valueFormatter,
		values = cbData.values,
		options = cbData.options,
		list = cbData.list,
		optionfunc = cbData.optionfunc,
		listFunc = cbData.listFunc,
		orderList = cbData.orderList or cbData.listOrder or (type(cbData.order) == "table" and cbData.order or nil),
		customText = cbData.customText,
		customDefaultText = cbData.customDefaultText,
		menuHeight = cbData.menuHeight or cbData.height,
		dropdownDefault = cbData.dropdownDefault,
		dropdownDesc = cbData.dropdownDesc,
		dropdownFormatter = cbData.dropdownFormatter,
		dropdownGet = cbData.dropdownGet,
		dropdownKey = cbData.dropdownKey or cbData.dropdownVar,
		dropdownList = cbData.dropdownList,
		dropdownListFunc = cbData.dropdownListFunc,
		dropdownName = cbData.dropdownName,
		dropdownOptionfunc = cbData.dropdownOptionfunc,
		dropdownOptions = cbData.dropdownOptions,
		dropdownOrder = cbData.dropdownOrder,
		dropdownSet = cbData.dropdownSet,
		dropdownSetting = cbData.dropdownSetting,
		dropdownSuffix = cbData.dropdownSuffix,
		dropdownText = cbData.dropdownText,
		dropdownValueFormatter = cbData.dropdownValueFormatter,
		dropdownValues = cbData.dropdownValues,
		generator = cbData.generator,
		numeric = cbData.numeric,
		placeholder = cbData.placeholder,
		placeholderText = cbData.placeholderText,
		maxChars = cbData.maxChars,
		readOnly = cbData.readOnly,
		multiline = cbData.multiline,
		multilineHeight = cbData.multilineHeight,
		inputWidth = cbData.inputWidth,
		clampToRange = cbData.clampToRange,
		height = cbData.height,
		buttonText = cbData.buttonText or cbData.buttonLabel or cbData.label,
		onClick = cbData.onClick or cbData.func,
		entries = cbData.entries,
		getColor = cbData.getColor,
		setColor = cbData.setColor,
		getDefaultColor = cbData.getDefaultColor,
		hasOpacity = cbData.hasOpacity,
		colorizeLabel = cbData.colorizeLabel,
		addEntry = cbData.addEntry,
		addButtonText = cbData.addButtonText,
		addPopupText = cbData.addPopupText,
		addPopupTitle = cbData.addPopupTitle,
		emptyText = cbData.emptyText,
		formatOptions = cbData.formatOptions,
		formatOrder = cbData.formatOrder,
		getEntries = cbData.getEntries,
		moveEntry = cbData.moveEntry,
		removeEntry = cbData.removeEntry,
		setEntryFormat = cbData.setEntryFormat,
		isSelectedFunc = cbData.isSelectedFunc,
		setSelectedFunc = cbData.setSelectedFunc,
		getSelection = cbData.getSelection,
		setSelection = cbData.setSelection,
		selectionSource = cbData.selectionSource,
		summary = cbData.summary,
		soundResolver = cbData.soundResolver,
		previewSoundFunc = cbData.previewSoundFunc,
		previewTooltip = cbData.previewTooltip,
		playbackChannel = cbData.playbackChannel,
		getPlaybackChannel = cbData.getPlaybackChannel,
		callback = cbData.callback,
		note = cbData.note,
		notes = cbData.notes,
		richNote = cbData.richNote,
		richNotes = cbData.richNotes,
		bindingIndex = cbData.bindingIndex,
	})
	if control and pageID then
		addon.ConfigLastControlByPageID[pageID] = control.id
		if cbData.parentSection then
			addon.ConfigLastControlBySection[cbData.parentSection] = control.id
		end
	end
	return control
end

local function getCVarOptionData(cvarKey) return addon.variables and addon.variables.cvarOptions and addon.variables.cvarOptions[cvarKey] end

function addon.functions.GetCVarOptionState(cvarKey)
	local optionData = getCVarOptionData(cvarKey)
	if not optionData or not C_CVar or not C_CVar.GetCVar then return false end
	local ok, value = pcall(C_CVar.GetCVar, cvarKey)
	if not ok then return false end
	return tostring(value) == tostring(optionData.trueValue)
end

function addon.functions.SetCVarOptionState(cvarKey, enabled)
	local optionData = getCVarOptionData(cvarKey)
	if not optionData then return end
	local newValue = enabled and optionData.trueValue or optionData.falseValue
	if newValue == nil then return end
	if addon.functions.setCVarValue then addon.functions.setCVarValue(cvarKey, newValue) end
end

---------------------------------------------------------
-- Kategorien
---------------------------------------------------------
function addon.functions.SettingsCreateCategory(parent, treeName, sort, newTagID)
	if nil == parent then parent = addon.SettingsLayout.rootCategory end
	local cat = createModernCategory(newTagID or treeName, treeName)
	addon.SettingsLayout.knownCategoryID = addon.SettingsLayout.knownCategoryID or {}
	addon.SettingsLayout.knownCategoryID[cat:GetID()] = true
	registerLegacyCategory(cat, treeName, newTagID)
	return cat, nil
end

function addon.functions.SettingsCreateKeybind(cat, bindingIndex, parentSection)
	registerLegacyControl(cat, {
		id = "Binding_" .. tostring(bindingIndex),
		text = _G.KEY_BINDINGS or "Key Bindings",
		desc = _G.KEY_BINDINGS_TOOLTIP or _G.KEY_BINDINGS or "Configure key bindings.",
		bindingIndex = bindingIndex,
		parentSection = parentSection,
		buttonText = _G.KEY_BINDINGS or "Key Bindings",
		level = "advanced",
	}, "keybind", nil)
	return nil
end

local function createChildSetting(cat, parentElement, parentData, childData)
	childData.element = childData.element or parentElement
	childData.parentCheck = childData.parentCheck or parentData.parentCheck
	childData.isVisible = childData.isVisible or parentData.isVisible
	childData.visibleWhen = childData.visibleWhen or parentData.visibleWhen
	childData.hiddenWhen = childData.hiddenWhen or parentData.hiddenWhen
	local sType = childData.sType or childData.type
	if sType == "dropdown" then
		addon.functions.SettingsCreateDropdown(cat, childData)
	elseif sType == "scrolldropdown" then
		addon.functions.SettingsCreateScrollDropdown(cat, childData)
	elseif sType == "checkbox" then
		addon.functions.SettingsCreateCheckbox(cat, childData)
	elseif sType == "multidropdown" then
		addon.functions.SettingsCreateMultiDropdown(cat, childData)
	elseif sType == "slider" then
		addon.functions.SettingsCreateSlider(cat, childData)
	elseif sType == "hint" then
		addon.functions.SettingsCreateText(cat, childData.text, { parentSection = childData.parentSection })
	elseif sType == "colorpicker" then
		addon.functions.SettingsCreateColorPicker(cat, childData)
	elseif sType == "button" then
		addon.functions.SettingsCreateButton(cat, childData)
	elseif sType == "reorderlist" then
		addon.functions.SettingsCreateReorderList(cat, childData)
	elseif sType == "sounddropdown" then
		addon.functions.SettingsCreateSoundDropdown(cat, childData)
	end
end

---------------------------------------------------------
-- Checkbox
---------------------------------------------------------
function addon.functions.SettingsCreateCheckbox(cat, cbData)
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	registerLegacyControl(cat, cbData, "toggle", setting)
	if cbData.children then
		for _, v in pairs(cbData.children) do
			createChildSetting(cat, element, cbData, v)
		end
	end
	return element
end

function addon.functions.SettingsCreateCheckboxes(cat, data)
	local rData = {}
	for _, cbData in ipairs(data) do
		rData[cbData.var] = addon.functions.SettingsCreateCheckbox(cat, cbData)
	end
	return rData
end

---------------------------------------------------------
-- Checkbox + Dropdown
---------------------------------------------------------
function addon.functions.SettingsCreateCheckboxDropdown(cat, cbData)
	local dropdownKey = cbData.dropdownVar or cbData.dropdownKey
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	if dropdownKey then rememberModernOnlyElement(dropdownKey, createModernOnlySetting(dropdownKey, cbData)) end
	local modernData = {}
	for key, value in pairs(cbData) do
		modernData[key] = value
	end
	modernData.dropdownKey = dropdownKey
	modernData.dropdownValues = cbData.dropdownList or cbData.dropdownValues or cbData.list or cbData.values
	modernData.dropdownOptions = modernData.dropdownValues
	modernData.dropdownOrder = cbData.dropdownOrder or cbData.order
	modernData.dropdownOptionfunc = cbData.dropdownOptionfunc or cbData.dropdownListFunc or cbData.listFunc or cbData.optionfunc
	modernData.dropdownName = cbData.dropdownText or cbData.dropdownName
	modernData.dropdownDesc = cbData.dropdownDesc
	modernData.dropdownGet = cbData.dropdownGet or function() return addon.db[dropdownKey] end
	modernData.dropdownSet = cbData.dropdownSet or function(v) addon.db[dropdownKey] = v end
	registerLegacyControl(cat, modernData, "checkboxdropdown", setting)
	return element
end

---------------------------------------------------------
-- Slider
---------------------------------------------------------
function addon.functions.SettingsCreateSlider(cat, cbData)
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	registerLegacyControl(cat, cbData, "slider", setting)
	return element
end

---------------------------------------------------------
-- Input
---------------------------------------------------------
function addon.functions.SettingsCreateInput(cat, cbData)
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	registerLegacyControl(cat, cbData, "input", setting)
	return element
end

---------------------------------------------------------
-- Dropdown
---------------------------------------------------------
function addon.functions.SettingsCreateDropdown(cat, cbData)
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	registerLegacyControl(cat, cbData, "dropdown", setting)
	return element
end

---------------------------------------------------------
-- Scroll Dropdown
---------------------------------------------------------
function addon.functions.SettingsCreateScrollDropdown(cat, cbData)
	local key = cbData.var or cbData.key
	local setting = createModernOnlySetting(key, cbData)
	local element = rememberModernOnlyElement(key, setting)
	registerLegacyControl(cat, cbData, "dropdown", setting)
	return element
end

function addon.functions.SettingsAttachNotify(setting, notify)
	local _ = setting
	_ = notify
end

---------------------------------------------------------
-- MultiDropdown
---------------------------------------------------------
function addon.functions.SettingsCreateMultiDropdown(cat, cbData)
	addon.db = addon.db or {}
	local explicitStorageDB = type(cbData.db) == "table" and cbData.db or nil
	local storageDisabled = cbData.storage == false

	-- Resolve addon.db lazily so profile-backed settings do not capture the pre-init placeholder table.
	local function resolveStorageDB()
		if explicitStorageDB then return explicitStorageDB end
		addon.db = addon.db or {}
		return addon.db
	end

	local function ensureRootContainer()
		local storageDB = resolveStorageDB()
		if type(storageDB[cbData.var]) ~= "table" then storageDB[cbData.var] = {} end
		return storageDB
	end

	local function getSelection()
		local storageDB = ensureRootContainer()
		local container = storageDB[cbData.var]
		if cbData.subvar then
			if type(container[cbData.subvar]) ~= "table" then container[cbData.subvar] = {} end
			container = container[cbData.subvar]
		end
		return container
	end

	local function setSelection(map)
		local storageDB = ensureRootContainer()
		if type(map) ~= "table" then map = {} end
		if cbData.subvar then
			storageDB[cbData.var][cbData.subvar] = map
		else
			storageDB[cbData.var] = map
		end
		if cbData.callback then cbData.callback(map) end
	end

	local function iterateOptionValues(func)
		local values = nil
		if cbData.optionfunc or cbData.listFunc then
			local ok, result = pcall(cbData.optionfunc or cbData.listFunc)
			if ok then values = result end
		end
		values = values or cbData.options or cbData.list
		if type(values) ~= "table" then return end

		for key, option in pairs(values) do
			local value = key
			if type(option) == "table" then value = option.value or option.key or option[1] or key end
			if value ~= nil then func(value) end
		end
	end

	local function getSelectionFromSelected()
		local selection = {}
		if type(cbData.isSelectedFunc) ~= "function" then return selection end
		iterateOptionValues(function(value)
			local ok, selected = pcall(cbData.isSelectedFunc, value)
			if ok and selected == true then selection[value] = true end
		end)
		return selection
	end

	local function setSelectionFromSelected(map)
		if type(cbData.setSelectedFunc) ~= "function" then return end
		if type(map) ~= "table" then map = {} end
		local seen = {}
		iterateOptionValues(function(value)
			seen[value] = true
			cbData.setSelectedFunc(value, map[value] == true)
		end)
		for value, selected in pairs(map) do
			if selected == true and not seen[value] then cbData.setSelectedFunc(value, true) end
		end
		if cbData.callback then cbData.callback(map) end
	end

	addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
	addon.SettingsLayout.elements[cbData.var] = { initializer = nil, modernOnly = true }
	local modernData = {}
	for key, value in pairs(cbData) do
		modernData[key] = value
	end
	local hasExplicitSelectionGetter = type(cbData.getSelection) == "function" or type(cbData.get) == "function"
	local hasPerOptionSelection = type(cbData.isSelectedFunc) == "function"
	if hasExplicitSelectionGetter then
		modernData.getSelection = cbData.getSelection or cbData.get
	elseif hasPerOptionSelection then
		modernData.getSelection = getSelectionFromSelected
		modernData.selectionSource = "perOption"
	else
		modernData.getSelection = storageDisabled and getSelectionFromSelected or getSelection
	end
	if cbData.setSelection or cbData.set then
		modernData.setSelection = cbData.setSelection or cbData.set
	elseif type(cbData.setSelectedFunc) == "function" then
		modernData.setSelection = setSelectionFromSelected
	else
		modernData.setSelection = storageDisabled and setSelectionFromSelected or setSelection
	end
	modernData.values = cbData.options or cbData.list
	modernData.optionfunc = cbData.optionfunc or cbData.listFunc
	modernData.menuHeight = cbData.menuHeight or 200
	registerLegacyControl(cat, modernData, "multidropdown", nil)
	return nil
end

---------------------------------------------------------
-- Sound Dropdown
---------------------------------------------------------
function addon.functions.SettingsCreateSoundDropdown(cat, cbData)
	local setting = createModernOnlySetting(cbData.var, cbData)
	local element = rememberModernOnlyElement(cbData.var, setting)
	registerLegacyControl(cat, cbData, "sounddropdown", setting)
	return element
end

---------------------------------------------------------
-- Color Overrides Panel
---------------------------------------------------------
function addon.functions.SettingsCreateColorOverrides(cat, cbData)
	rememberModernOnlyElement(cbData.var or cbData.key or "ColorOverrides")
	addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
	registerLegacyControl(cat, cbData, "coloroverrides", nil)
	return nil
end

-- Text / Header / Button / Notify
---------------------------------------------------------
function addon.functions.SettingsCreateHeadline(cat, text, extra)
	local data = type(text) == "table" and text or extra
	local headerText = type(text) == "table" and (text.name or text.text or text.label or text.title) or text
	local app = ensureConfigApp()
	if app and data and data.parentSection then
		local resolvedSection = resolveConfigSection(data.parentSection)
		local pageID = app.legacySections and app.legacySections[resolvedSection]
		if pageID and app:GetPage(pageID) then
			addon.ConfigGroupOrderByPageID[pageID] = (addon.ConfigGroupOrderByPageID[pageID] or 0) + 10
			local groupID = data.groupID or data.modernGroup or ConfigLib:NormalizeID(headerText or "settings")
			local groupTitle = headerText or groupID
			app:RegisterGroup(pageID, {
				id = groupID,
				title = groupTitle,
				order = data.order or addon.ConfigGroupOrderByPageID[pageID],
			})
			addon.ConfigCurrentGroupByPageID[pageID] = groupID
			addon.ConfigGroupTitleByPageID[pageID] = groupTitle
			addon.ConfigCurrentGroupBySection[resolvedSection] = groupID
			addon.ConfigGroupTitleBySection[resolvedSection] = groupTitle
		end
	end
	return nil
end

function addon.functions.SettingsCreateText(cat, text, extra)
	local app = ensureConfigApp()
	if app and app.RegisterControlNote and extra and extra.parentSection and type(text) == "string" then
		local resolvedSection = resolveConfigSection(extra.parentSection)
		local pageID = app.legacySections and app.legacySections[resolvedSection]
		local controlID = extra.controlID or extra.attachToControlID or addon.ConfigLastControlBySection[resolvedSection] or (pageID and addon.ConfigLastControlByPageID[pageID])
		if pageID and app:GetPage(pageID) and controlID then
			app:RegisterControlNote(controlID, {
				text = text,
				order = extra.order or addon.ConfigControlOrder or 0,
			})
		elseif pageID and app:GetPage(pageID) and app.RegisterPageNote then
			app:RegisterPageNote(pageID, {
				text = text,
				order = extra.order or 1000,
			})
		end
	end
	return nil
end

function addon.functions.SettingsCreateButton(cat, cbData)
	local btn = rememberModernOnlyElement(cbData.var or cbData.text)
	registerLegacyControl(cat, cbData, "button", nil)
	return btn
end

function addon.functions.SettingsCreateReorderList(cat, cbData)
	local key = cbData.var or cbData.id or cbData.text
	addon.SettingsLayout = addon.SettingsLayout or {}
	addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
	addon.SettingsLayout.elements[key] = { initializer = nil, modernOnly = true }
	registerLegacyControl(cat, cbData, "reorderlist", nil)
	return nil
end

function addon.functions.SettingsCreateColorPicker(cat, cbData)
	if type(cbData.getColor) == "function" and type(cbData.setColor) == "function" then
		local key = cbData.var or cbData.id or cbData.text
		cbData.entries = cbData.entries or { { key = key, label = cbData.text, tooltip = cbData.tooltip } }
		addon.SettingsLayout = addon.SettingsLayout or {}
		addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
		addon.SettingsLayout.elements[key] = { initializer = nil, modernOnly = true }
		registerLegacyControl(cat, cbData, "colorpicker", nil)
		return nil
	end

	local entries = { { key = cbData.var, label = cbData.text, tooltip = cbData.tooltip } }
	local function getColor(_)
		local db = addon.db[cbData.var]
		if cbData.subvar and db then db = db[cbData.subvar] end
		local default = type(cbData.default) == "function" and cbData.default() or cbData.default
		local col = db or default or { r = 0, g = 0, b = 0, a = 1 }
		return col.r or 0, col.g or 0, col.b or 0, col.a or 1
	end
	local function setColor(_, r, g, b, a)
		addon.db[cbData.var] = addon.db[cbData.var] or {}
		if cbData.subvar then
			addon.db[cbData.var][cbData.subvar] = { r = r, g = g, b = b, a = a }
		else
			addon.db[cbData.var] = { r = r, g = g, b = b, a = a }
		end
		if cbData.callback then cbData.callback(r, g, b, a) end
	end
	local function getDefaultColor()
		local default = type(cbData.default) == "function" and cbData.default() or cbData.default
		return default and default.r or 1, default and default.g or 1, default and default.b or 1, default and default.a or 1
	end
	addon.SettingsLayout = addon.SettingsLayout or {}
	addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
	addon.SettingsLayout.elements[cbData.var] = { initializer = nil, modernOnly = true }
	cbData.entries = entries
	cbData.getColor = getColor
	cbData.setColor = setColor
	cbData.getDefaultColor = getDefaultColor
	registerLegacyControl(cat, cbData, "colorpicker", nil)
	return nil
end

function addon.functions.SettingsCreateExpandableSection(cat, cbData)
	local section = createModernOnlySection(cbData)
	addon.ConfigModernOnlySections[section] = true
	if cbData.var then
		addon.SettingsLayout = addon.SettingsLayout or {}
		addon.SettingsLayout.elements = addon.SettingsLayout.elements or {}
		addon.SettingsLayout.elements[cbData.var] = { initializer = section }
	end
	local app = ensureConfigApp()
	if app then
		local pageKey = cbData.configPageKey or cbData.newTagID or getLocaleKeyForText(cbData.name)
		local pageID = app:RegisterLegacySection(section, {
			category = cat,
			categoryID = cbData.categoryID or cbData.modernCategory,
			title = cbData.name,
			pageID = cbData.configPageID,
			pageKey = pageKey,
			order = cbData.order,
			description = cbData.description or cbData.desc,
			icon = cbData.icon,
			iconAtlas = cbData.iconAtlas,
			iconKey = cbData.iconKey or pageIconKeysByStableID[pageKey] or pageIconKeysByStableID[cbData.newTagID],
			mainToggleID = cbData.mainToggleID,
			newTagID = cbData.newTagID,
			visible = cbData.visible,
			isVisible = cbData.isVisible,
			visibleWhen = cbData.visibleWhen,
			hiddenWhen = cbData.hiddenWhen,
		})
		if pageID then
			addon.ConfigCurrentGroupByPageID[pageID] = nil
			addon.ConfigGroupTitleByPageID[pageID] = nil
			addon.ConfigGroupOrderByPageID[pageID] = 0
			addon.ConfigCurrentGroupBySection[section] = nil
			addon.ConfigGroupTitleBySection[section] = nil
		end
	end
	return section
end

addon.SettingsLayout.rootCategory = createModernCategory(addonName, addonName)
addon.SettingsLayout.rootLayout = nil

ensureConfigApp()
