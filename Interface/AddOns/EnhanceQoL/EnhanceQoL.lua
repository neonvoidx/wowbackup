-- luacheck: globals DefaultCompactUnitFrameSetup CompactUnitFrame_UpdateAuras CompactUnitFrame_UpdateName UnitTokenFromGUID C_Bank CompactRaidFrameContainer
-- luacheck: globals HUD_EDIT_MODE_MINIMAP_LABEL
-- luacheck: globals Menu MenuResponse GameTooltip_SetTitle GameTooltip_AddNormalLine EnhanceQoL
-- luacheck: globals GenericTraitUI_LoadUI GenericTraitFrame
-- luacheck: globals CancelDuel DeclineGroup C_PetBattles
-- luacheck: globals ExpansionLandingPage ExpansionLandingPageMinimapButton ShowGarrisonLandingPage GarrisonLandingPage GarrisonLandingPage_Toggle GarrisonLandingPageMinimapButton CovenantSanctumFrame CovenantSanctumFrame_LoadUI EasyMenu
-- luacheck: globals ActionButton_UpdateRangeIndicator MAINMENU_BUTTON PlayerCastingBarFrame TargetFrameSpellBar FocusFrameSpellBar ChatBubbleFont
-- luacheck: globals ChatFrame1Tab ChatFrame2 ChatFrame2Tab FCF_SetWindowName FCFDock_UpdateTabs GENERAL_CHAT_DOCK EventUtil ClassTrainerFrame ClassTrainerTrainButton ClassTrainerFrameMoneyBg
local addonName, addon = ...

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LSM = LibStub("LibSharedMedia-3.0", true)

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

addon.functions = addon.functions or {}
addon.ActionBarLabels = addon.ActionBarLabels or {}
local ActionBarLabels = addon.ActionBarLabels

addon.constants = addon.constants or {}

local UNIT_FRAMES_ADDON_NAME = "EnhanceQoLUnitFrames"
local CHAT_SOCIAL_ADDON_NAME = "EnhanceQoLChatSocial"

function addon.functions.IsUnitFramesAddonLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(UNIT_FRAMES_ADDON_NAME) == true end
	if IsAddOnLoaded then return IsAddOnLoaded(UNIT_FRAMES_ADDON_NAME) == true end
	return addon.Aura and addon.Aura.UF ~= nil
end

function addon.functions.IsChatSocialAddonLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(CHAT_SOCIAL_ADDON_NAME) == true end
	if IsAddOnLoaded then return IsAddOnLoaded(CHAT_SOCIAL_ADDON_NAME) == true end
	return addon.ChatIM ~= nil or addon.Ignore ~= nil or addon.ChatIcons ~= nil
end

function addon.functions.IsAdvancedIgnoreEnabled()
	if not addon.functions.IsChatSocialAddonLoaded() then return false end
	return addon.db and addon.db.enableIgnore == true and addon.Ignore and addon.Ignore.CheckIgnore ~= nil
end

function addon.functions.IsEQoLUnitFrameEnabled(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	if not addon.functions.IsUnitFramesAddonLoaded() then return false end

	local uf = addon.Aura and addon.Aura.UF
	if uf and uf.GetConfig then
		local cfg = uf.GetConfig(unit)
		if cfg and cfg.enabled == true then return true end
	end

	local frames = addon.db and addon.db.ufFrames
	if not frames then return false end
	if unit == "boss" then
		local bossCfg = frames.boss
		if bossCfg and bossCfg.enabled == true then return true end
		for i = 1, 5 do
			local cfg = frames["boss" .. i]
			if cfg and cfg.enabled == true then return true end
		end
		return false
	end
	local cfg = frames[unit]
	return cfg and cfg.enabled == true
end

function addon.functions.IsEQoLGroupFrameEnabled(kind)
	if type(kind) ~= "string" or kind == "" then return false end
	if not addon.functions.IsUnitFramesAddonLoaded() then return false end

	local groupFrames = addon.Aura and addon.Aura.UF and addon.Aura.UF.GroupFrames
	if groupFrames and groupFrames.GetConfig then
		local cfg = groupFrames:GetConfig(kind)
		if cfg and cfg.enabled == true then return true end
	end

	local groups = addon.db and addon.db.ufGroupFrames
	local cfg = groups and groups[kind]
	return cfg and cfg.enabled == true
end

function addon.functions.IsEQoLUnitOrGroupFrameEnabled(key)
	return addon.functions.IsEQoLUnitFrameEnabled(key) or addon.functions.IsEQoLGroupFrameEnabled(key)
end

local function getPrivateDB() return addon.functions.GetPrivateDB and addon.functions.GetPrivateDB() or addon.privateDB or {} end

local LFGListFrame = _G.LFGListFrame
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local StaticPopup_Visible = StaticPopup_Visible
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local IsInGroup = IsInGroup
local math = math
local TooltipUtil = _G.TooltipUtil
local GetTime = GetTime
local GetActiveQuestID = _G.GetActiveQuestID

local function MouseIsOver(region, topOffset, bottomOffset, leftOffset, rightOffset)
	if not region then return false end
	if _G.MouseIsOver then return _G.MouseIsOver(region, topOffset, bottomOffset, leftOffset, rightOffset) end
	if region.IsMouseOver then return region:IsMouseOver(topOffset, bottomOffset, leftOffset, rightOffset) end
	return false
end
addon.functions.MouseIsOver = MouseIsOver

local AUTO_REPAIR_GUILD_BANK_CONTEXT_DEFAULTS = {
	world = true,
	party = true,
	dungeon = true,
	mythicPlus = true,
	raid = true,
	pvp = true,
}

local EQOL = select(2, ...)
EQOL.C = {}

local ACTION_BAR_FRAME_NAMES = {
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"MultiBarRight",
	"MultiBarLeft",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
}

if _G.MainMenuBar then table.insert(ACTION_BAR_FRAME_NAMES, 1, "MainMenuBar") end
if _G.MainActionBar then table.insert(ACTION_BAR_FRAME_NAMES, 1, "MainActionBar") end
addon.constants.ACTION_BAR_FRAME_NAMES = ACTION_BAR_FRAME_NAMES

local ACTION_BAR_ANCHOR_ORDER = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
addon.constants.ACTION_BAR_ANCHOR_ORDER = ACTION_BAR_ANCHOR_ORDER

local ACTION_BAR_ANCHOR_CONFIG = {
	TOPLEFT = { addButtonsToTop = false, addButtonsToRight = true },
	TOPRIGHT = { addButtonsToTop = false, addButtonsToRight = false },
	BOTTOMLEFT = { addButtonsToTop = true, addButtonsToRight = true },
	BOTTOMRIGHT = { addButtonsToTop = true, addButtonsToRight = false },
}
addon.constants.ACTION_BAR_ANCHOR_CONFIG = ACTION_BAR_ANCHOR_CONFIG

local COOLDOWN_VIEWER_FRAMES = {
	"EssentialCooldownViewer",
	"UtilityCooldownViewer",
	"BuffBarCooldownViewer",
	"BuffIconCooldownViewer",
}
addon.constants.COOLDOWN_VIEWER_FRAMES = COOLDOWN_VIEWER_FRAMES

local COOLDOWN_VIEWER_VISIBILITY_MODES = {
	IN_COMBAT = "IN_COMBAT",
	WHILE_MOUNTED = "WHILE_MOUNTED",
	WHILE_NOT_MOUNTED = "WHILE_NOT_MOUNTED",
	SKYRIDING_ACTIVE = "SKYRIDING_ACTIVE",
	SKYRIDING_INACTIVE = "SKYRIDING_INACTIVE",
	FLYING_ACTIVE = "FLYING_ACTIVE",
	FLYING_INACTIVE = "FLYING_INACTIVE",
	MOUSEOVER = "MOUSEOVER",
	PLAYER_HAS_FOCUS = "PLAYER_HAS_FOCUS",
	PLAYER_HAS_TARGET = "PLAYER_HAS_TARGET",
	PLAYER_CASTING = "PLAYER_CASTING",
	PLAYER_IN_GROUP = "PLAYER_IN_GROUP",
	SHOW_IN_INSTANCE = "SHOW_IN_INSTANCE",
	ALWAYS_HIDDEN = "ALWAYS_HIDDEN",
}
addon.constants.COOLDOWN_VIEWER_VISIBILITY_MODES = COOLDOWN_VIEWER_VISIBILITY_MODES

addon.visibilityRuntime = addon.visibilityRuntime or {}
addon.visibilityRuntime.cooldownViewerConfigKeys = {
	COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT,
	COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED,
	COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED,
	COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE,
	COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE,
	COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE,
	COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE,
	COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER,
	COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS,
	COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET,
	COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING,
	COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP,
	COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE,
	COOLDOWN_VIEWER_VISIBILITY_MODES.ALWAYS_HIDDEN,
}

local SPELL_ACTIVATION_OVERLAY_FRAME_NAME = "SpellActivationOverlayFrame"
addon.constants.SPELL_ACTIVATION_OVERLAY_FRAME_NAME = SPELL_ACTIVATION_OVERLAY_FRAME_NAME
local SPELL_ACTIVATION_OVERLAY_VISIBILITY_KEYS = {
	[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET] = true,
	[COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE] = true,
}
addon.constants.SPELL_ACTIVATION_OVERLAY_VISIBILITY_KEYS = SPELL_ACTIVATION_OVERLAY_VISIBILITY_KEYS

local DEFAULT_BUTTON_SINK_COLUMNS = 4

local ACTION_BUTTON_COUNTS = {
	default = _G.NUM_ACTIONBAR_BUTTONS or 12,
	pet = _G.NUM_PET_ACTION_SLOTS or 10,
	stance = _G.NUM_STANCE_SLOTS or _G.NUM_SHAPESHIFT_SLOTS or 10,
}

local ACTION_BAR_FRAME_ALIASES = {
	PetActionBar = { "PetActionBarFrame" },
	StanceBar = { "StanceBarFrame" },
}

local function ResolveActionBarFrame(barName)
	if type(barName) ~= "string" or barName == "" then return nil end
	local frame = _G[barName]
	if frame then return frame end
	local aliases = ACTION_BAR_FRAME_ALIASES[barName]
	if not aliases then return nil end
	for _, alias in ipairs(aliases) do
		frame = _G[alias]
		if frame then return frame end
	end
	return nil
end

local function GetActionBarButtonPrefix(barName)
	if not barName then return nil, 0 end
	if barName == "MainMenuBar" or barName == "MainActionBar" then return "ActionButton", ACTION_BUTTON_COUNTS.default end
	if barName == "PetActionBar" or barName == "PetActionBarFrame" then return "PetActionButton", ACTION_BUTTON_COUNTS.pet end
	if barName == "StanceBar" or barName == "StanceBarFrame" then return "StanceButton", ACTION_BUTTON_COUNTS.stance end
	return barName .. "Button", ACTION_BUTTON_COUNTS.default
end

local function ForEachActionButton(callback)
	if type(callback) ~= "function" then return end
	local list = addon.variables and addon.variables.actionBarNames
	if not list then return end
	local seen = {}
	for _, info in ipairs(list) do
		local prefix, count = GetActionBarButtonPrefix(info.name)
		if prefix and count then
			for i = 1, count do
				local button = _G[prefix .. i]
				if button and not seen[button] then
					seen[button] = true
					if not button.EQOL_ActionBarName then button.EQOL_ActionBarName = info.name end
					callback(button, info, i)
				end
			end
		end
	end
end

local function GetActionBarFrame(index)
	local name = ACTION_BAR_FRAME_NAMES[index]
	if not name then return nil, nil end
	return _G[name], name
end

local function DetermineAnchorFromBar(bar)
	if not bar then return "TOPLEFT" end
	local addTop = bar.addButtonsToTop == true
	local addRight = bar.addButtonsToRight == true
	if addTop and addRight then
		return "BOTTOMLEFT"
	elseif addTop and not addRight then
		return "BOTTOMRIGHT"
	elseif not addTop and addRight then
		return "TOPLEFT"
	else
		return "TOPRIGHT"
	end
end

local function ApplyActionBarAnchor(index, anchorKey)
	local bar = GetActionBarFrame(index)
	if not bar then return end
	local config = ACTION_BAR_ANCHOR_CONFIG[anchorKey]
	if not config then return end
	bar.addButtonsToTop = config.addButtonsToTop
	bar.addButtonsToRight = config.addButtonsToRight
	if bar.UpdateGridLayout then bar:UpdateGridLayout() end
end

function addon.functions.GetActionBarAnchor(index) return DetermineAnchorFromBar(select(1, GetActionBarFrame(index))) end

function addon.functions.SetActionBarAnchor(index, anchorKey) ApplyActionBarAnchor(index, anchorKey) end

local function RefreshAllActionBarAnchors()
	local enabled = addon.db and addon.db.actionBarAnchorEnabled
	if not enabled then
		if addon.variables then addon.variables.pendingActionBarAnchorRefresh = nil end
		return
	end

	if InCombatLockdown and InCombatLockdown() then
		addon.variables = addon.variables or {}
		addon.variables.pendingActionBarAnchorRefresh = true
		return
	end

	if addon.variables then addon.variables.pendingActionBarAnchorRefresh = nil end
	addon.variables.actionBarAnchorDefaults = addon.variables.actionBarAnchorDefaults or {}
	for i = 1, #ACTION_BAR_FRAME_NAMES do
		local defaultKey = "actionBarAnchorDefault" .. i
		local storedDefault = addon.db and addon.db[defaultKey]
		if not storedDefault or not ACTION_BAR_ANCHOR_CONFIG[storedDefault] then
			storedDefault = addon.functions.GetActionBarAnchor(i)
			if addon.db then addon.db[defaultKey] = storedDefault end
		end
		addon.variables.actionBarAnchorDefaults[i] = storedDefault

		local key = "actionBarAnchor" .. i
		local stored = addon.db and addon.db[key]
		if not stored or not ACTION_BAR_ANCHOR_CONFIG[stored] then
			stored = storedDefault
			if addon.db then addon.db[key] = stored end
		end

		ApplyActionBarAnchor(i, stored)
	end
end
addon.functions.RefreshAllActionBarAnchors = RefreshAllActionBarAnchors

-- localeadditions
local hookedATT = false -- need to hook ATT because of the way the minimap button is created

hooksecurefunc("LFGListSearchEntry_OnClick", function(s, button)
	if not addon.db.skipSignUpDialog then return end
	if addon.functions.isRestrictedContent(true) then return end
	local panel = LFGListFrame.SearchPanel
	if button ~= "RightButton" and LFGListSearchPanelUtil_CanSelectResult(s.resultID) and panel.SignUpButton:IsEnabled() then
		if panel.selectedResult ~= s.resultID then LFGListSearchPanel_SelectResult(panel, s.resultID) end
		LFGListSearchPanel_SignUp(panel)
	end
end)

local function checkBagIgnoreJunk()
	if addon.db["sellAllJunk"] then
		local counter = 0
		for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
			if C_Container.GetBagSlotFlag(bag, Enum.BagSlotFlags.ExcludeJunkSell) then counter = counter + 1 end
		end
		if counter > 0 then
			local message = string.format(L["SellJunkIgnoredBag"], counter)

			StaticPopupDialogs["SellJunkIgnoredBag"] = {
				text = message,
				button1 = OKAY,
				timeout = 15,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
				OnShow = function(self) self:SetFrameStrata("TOOLTIP") end,
			}
			StaticPopup_Show("SellJunkIgnoredBag")
		end
	end
end
addon.functions.checkBagIgnoreJunk = checkBagIgnoreJunk

local function skipRolecheck()
	if addon.db["groupfinderSkipRoleSelectOption"] == 1 then
		local tank, healer, dps = false, false, false
		local role = UnitGroupRolesAssigned("player")
		if role == "NONE" then role = GetSpecializationRole(C_SpecializationInfo.GetSpecialization()) end
		if role == "TANK" then
			tank = true
		elseif role == "DAMAGER" then
			dps = true
		elseif role == "HEALER" then
			healer = true
		end
		if LFDRoleCheckPopupRoleButtonTank.checkButton:IsEnabled() then LFDRoleCheckPopupRoleButtonTank.checkButton:SetChecked(tank) end
		if LFDRoleCheckPopupRoleButtonHealer.checkButton:IsEnabled() then LFDRoleCheckPopupRoleButtonHealer.checkButton:SetChecked(healer) end
		if LFDRoleCheckPopupRoleButtonDPS.checkButton:IsEnabled() then LFDRoleCheckPopupRoleButtonDPS.checkButton:SetChecked(dps) end
	elseif addon.db["groupfinderSkipRoleSelectOption"] == 2 then
		if LFDQueueFrameRoleButtonTank and LFDQueueFrameRoleButtonTank:IsEnabled() then
			LFGListApplicationDialog.TankButton.CheckButton:SetChecked(LFDQueueFrameRoleButtonTank.checkButton:GetChecked())
		end
		if LFDQueueFrameRoleButtonHealer and LFDQueueFrameRoleButtonHealer:IsEnabled() then
			LFGListApplicationDialog.HealerButton.CheckButton:SetChecked(LFDQueueFrameRoleButtonHealer.checkButton:GetChecked())
		end
		if LFDQueueFrameRoleButtonDPS and LFDQueueFrameRoleButtonDPS:IsEnabled() then
			LFGListApplicationDialog.DamagerButton.CheckButton:SetChecked(LFDQueueFrameRoleButtonDPS.checkButton:GetChecked())
		end
	else
		return
	end

	LFDRoleCheckPopupAcceptButton:Enable()
	LFDRoleCheckPopupAcceptButton:Click()
end

LFGListApplicationDialog:HookScript("OnShow", function(self)
	if not addon.db.skipSignUpDialog then return end
	if self.SignUpButton:IsEnabled() and not IsShiftKeyDown() then self.SignUpButton:Click() end
end)

local lfgListPatchState = {
	applied = false,
	original = LFGListApplicationDialog_Show,
}
function lfgListPatchState.patched(self, resultID)
	if resultID then
		local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

		self.resultID = resultID
		self.activityID = searchResultInfo.activityID
	end
	LFGListApplicationDialog_UpdateRoles(self)
	StaticPopupSpecial_Show(self)
end

function EQOL.PersistSignUpNote()
	if addon.db.persistSignUpNote then
		-- overwrite function with patched func missing the call to ClearApplicationTextFields
		LFGListApplicationDialog_Show = lfgListPatchState.patched
		lfgListPatchState.applied = true
	elseif lfgListPatchState.applied then
		-- restore previously overwritten function
		LFGListApplicationDialog_Show = lfgListPatchState.original
	end
end

local function GameTooltipActionButton(button)
	button:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent) -- Use default positioning
		GameTooltip.default = 1

		if self.action then
			GameTooltip:SetAction(self.action) -- Displays the action of the button (spell, item, etc.)
		else
			GameTooltip:Hide() -- Hide the tooltip if no action is assigned
		end

		GameTooltip:Show()
	end)
	button:HookScript("OnLeave", function(self) GameTooltip:Hide() end)
end

local visibilityRuleMetadata = {
	MOUSEOVER = {
		key = "MOUSEOVER",
		label = L["Mouseover"] or (L["Mouseover"] or "Mouseover"),
		description = L["visibilityRule_mouseover_desc"],
		appliesTo = { actionbar = true, frame = true },
		order = 10,
	},
	ALWAYS_IN_COMBAT = {
		key = "ALWAYS_IN_COMBAT",
		label = L["Always in combat"] or (L["Always in combat"] or "Always in combat"),
		description = L["visibilityRule_inCombat_desc"],
		appliesTo = { actionbar = true, frame = true },
		contextKey = "inCombat",
		order = 20,
	},
	ALWAYS_OUT_OF_COMBAT = {
		key = "ALWAYS_OUT_OF_COMBAT",
		label = L["Always out of combat"] or (L["Always out of combat"] or "Always out of combat"),
		description = L["visibilityRule_outCombat_desc"],
		appliesTo = { actionbar = true, frame = true },
		contextKey = "outOfCombat",
		order = 30,
	},
	PLAYER_CASTING = {
		key = "PLAYER_CASTING",
		label = L["Player is casting"] or "Player is casting",
		description = L["visibilityRule_playerCasting_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 35,
	},
	PLAYER_MOUNTED = {
		key = "PLAYER_MOUNTED",
		label = L["Mounted"] or "Mounted",
		description = L["visibilityRule_playerMounted_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 36,
	},
	PLAYER_NOT_MOUNTED = {
		key = "PLAYER_NOT_MOUNTED",
		label = L["Not mounted"] or "Not mounted",
		description = L["visibilityRule_playerNotMounted_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 37,
	},
	PLAYER_HAS_FOCUS = {
		key = "PLAYER_HAS_FOCUS",
		label = L["When I have a focus"] or "When I have a focus",
		description = L["visibilityRule_playerHasFocus_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 44,
	},
	PLAYER_HAS_TARGET = {
		key = "PLAYER_HAS_TARGET",
		label = L["When I have a target"] or "When I have a target",
		description = L["visibilityRule_playerHasTarget_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 45,
	},
	SHOW_IN_INSTANCE = {
		key = "SHOW_IN_INSTANCE",
		label = L["Show in instance"] or "Show in instance",
		description = L["visibilityRule_showInInstance_desc"],
		appliesTo = { actionbar = true, frame = true },
		contextKey = "inInstance",
		order = 46,
	},
	PLAYER_IN_GROUP = {
		key = "PLAYER_IN_GROUP",
		label = L["In party/raid"] or "In party/raid",
		description = L["visibilityRule_inGroup_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 47,
	},
	PLAYER_IN_PARTY = {
		key = "PLAYER_IN_PARTY",
		label = L["In party"] or (L["In party"] or "In party"),
		description = L["visibilityRule_inParty_desc"],
		appliesTo = { frame = true },
		unitRequirement = "player",
		order = 48,
	},
	PLAYER_IN_RAID = {
		key = "PLAYER_IN_RAID",
		label = L["In raid"] or (L["In raid"] or "In raid"),
		description = L["visibilityRule_inRaid_desc"],
		appliesTo = { frame = true },
		unitRequirement = "player",
		order = 49,
	},
	ALWAYS_HIDE_IN_GROUP = {
		key = "ALWAYS_HIDE_IN_GROUP",
		label = L["visibilityRule_groupedHide"] or "Always hide in party/raid",
		description = L["visibilityRule_groupedHide_desc"]
			or "Hides the player frame whenever you are in a party or raid. While grouped, only this rule (and Mouseover, if enabled) is evaluated; other visibility rules are ignored.",
		appliesTo = { frame = true },
		unitRequirement = "player",
		order = 50,
	},
	ALWAYS_HIDE_IN_PARTY = {
		key = "ALWAYS_HIDE_IN_PARTY",
		label = L["visibilityRule_hideInParty"] or "Always hide in party",
		description = L["visibilityRule_hideInParty_desc"]
			or "Hide the player frame whenever you are in a party, but not in a raid. While in a party, only this rule (and Mouseover, if enabled) is evaluated; other visibility rules are ignored.",
		appliesTo = { frame = true },
		unitRequirement = "player",
		order = 51,
	},
	ALWAYS_HIDE_IN_RAID = {
		key = "ALWAYS_HIDE_IN_RAID",
		label = L["visibilityRule_hideInRaid"] or "Always hide in raid",
		description = L["visibilityRule_hideInRaid_desc"]
			or "Hide the player frame whenever you are in a raid. While in a raid, only this rule (and Mouseover, if enabled) is evaluated; other visibility rules are ignored.",
		appliesTo = { frame = true },
		unitRequirement = "player",
		order = 52,
	},
	SKYRIDING_ACTIVE = {
		key = "SKYRIDING_ACTIVE",
		label = L["While skyriding"] or "While skyriding",
		description = L["visibilityRule_skyriding_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 25,
	},
	SKYRIDING_INACTIVE = {
		key = "SKYRIDING_INACTIVE",
		label = L["Hide while skyriding"] or "Hide while skyriding",
		description = L["visibilityRule_hideSkyriding_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 26,
	},
	FLYING_ACTIVE = {
		key = "FLYING_ACTIVE",
		label = L["visibilityRule_flying"] or "While flying",
		description = L["visibilityRule_flying_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 27,
	},
	FLYING_INACTIVE = {
		key = "FLYING_INACTIVE",
		label = L["visibilityRule_hideFlying"] or "Hide while flying",
		description = L["visibilityRule_hideFlying_desc"],
		appliesTo = { actionbar = true, frame = true },
		unitRequirement = "player",
		order = 28,
	},
	ALWAYS_HIDDEN = {
		key = "ALWAYS_HIDDEN",
		label = L["visibilityRule_alwaysHidden"] or "Always hidden",
		description = L["visibilityRule_alwaysHidden_desc"],
		appliesTo = { actionbar = true, frame = true },
		advanced = true,
		order = 100,
	},
}
addon.constants = addon.constants or {}
addon.constants.VISIBILITY_RULES = visibilityRuleMetadata
function addon.functions.GetVisibilityRuleMetadata() return visibilityRuleMetadata end

local FRAME_VISIBILITY_KEYS = {}
local ACTIONBAR_VISIBILITY_KEYS = {}
for key, meta in pairs(visibilityRuleMetadata) do
	if meta.appliesTo then
		if meta.appliesTo.frame then FRAME_VISIBILITY_KEYS[key] = true end
		if meta.appliesTo.actionbar then ACTIONBAR_VISIBILITY_KEYS[key] = true end
	end
end
addon.constants.FRAME_VISIBILITY_KEYS = FRAME_VISIBILITY_KEYS
addon.constants.ACTIONBAR_VISIBILITY_KEYS = ACTIONBAR_VISIBILITY_KEYS

addon.variables = addon.variables or {}
addon.variables.frameVisibilityOverrides = addon.variables.frameVisibilityOverrides or {}

local function copyVisibilityFlags(source, allowedKeys)
	if type(source) ~= "table" then return nil end
	local result
	for key in pairs(allowedKeys) do
		if source[key] then
			result = result or {}
			result[key] = true
		end
	end
	return result
end

local function normalizeVisibilityConfigForAllowedKeys(source, allowedKeys)
	local config
	if type(source) == "table" then
		config = copyVisibilityFlags(source, allowedKeys)
	elseif source == true or source == "MOUSEOVER" then
		if allowedKeys.MOUSEOVER then config = { MOUSEOVER = true } end
	elseif source == "hide" then
		if allowedKeys.ALWAYS_HIDDEN then config = { ALWAYS_HIDDEN = true } end
	elseif source == "[combat] show; hide" then
		if allowedKeys.ALWAYS_IN_COMBAT then config = { ALWAYS_IN_COMBAT = true } end
	elseif source == "[combat] hide; show" then
		if allowedKeys.ALWAYS_OUT_OF_COMBAT then config = { ALWAYS_OUT_OF_COMBAT = true } end
	elseif source == false or source == "" then
		config = nil
	end

	if config and not next(config) then config = nil end
	return config
end

local function NormalizeUnitFrameVisibilityConfig(varName, incoming, opts)
	local source = incoming
	local skipSave = opts and opts.skipSave
	local ignoreOverride = opts and opts.ignoreOverride
	if source == nil then
		if not ignoreOverride and addon.variables.frameVisibilityOverrides and addon.variables.frameVisibilityOverrides[varName] then
			source = addon.variables.frameVisibilityOverrides[varName]
			skipSave = true
		elseif addon.db then
			source = addon.db[varName]
		end
	end
	local config = normalizeVisibilityConfigForAllowedKeys(source, FRAME_VISIBILITY_KEYS)

	if not skipSave and addon.db and varName then addon.db[varName] = config end
	return config
end
addon.functions.NormalizeUnitFrameVisibilityConfig = NormalizeUnitFrameVisibilityConfig

addon.functions.NormalizeActionbarVisibilityConfig = function(incoming) return normalizeVisibilityConfigForAllowedKeys(incoming, ACTIONBAR_VISIBILITY_KEYS) end

addon.functions.GetActionbarVisibilityRuleOptions = function()
	local options = {}
	for key, data in pairs(visibilityRuleMetadata) do
		if ACTIONBAR_VISIBILITY_KEYS[key] and key ~= "MOUSEOVER" then
			options[#options + 1] = {
				value = key,
				label = data.label or key,
				text = data.label or key,
				order = data.order or 999,
			}
		end
	end
	table.sort(options, function(a, b)
		if a.order == b.order then
			local left = tostring(a.label or a.value or "")
			local right = tostring(b.label or b.value or "")
			if strcmputf8i then return strcmputf8i(left, right) < 0 end
			return left:lower() < right:lower()
		end
		return a.order < b.order
	end)
	return options
end

local function SetFrameVisibilityOverride(varName, config)
	if not varName then return nil end
	addon.variables.frameVisibilityOverrides = addon.variables.frameVisibilityOverrides or {}
	if config == nil then
		addon.variables.frameVisibilityOverrides[varName] = nil
		return nil
	end
	local normalized = NormalizeUnitFrameVisibilityConfig(varName, config, { skipSave = true, ignoreOverride = true })
	addon.variables.frameVisibilityOverrides[varName] = normalized
	return normalized
end
addon.functions.SetFrameVisibilityOverride = SetFrameVisibilityOverride

local function HasFrameVisibilityOverride(varName) return varName ~= nil and addon.variables.frameVisibilityOverrides ~= nil and addon.variables.frameVisibilityOverrides[varName] ~= nil end
addon.functions.HasFrameVisibilityOverride = HasFrameVisibilityOverride

local function MigrateLegacyVisibilityFlag(oldKey, targetVar)
	if not addon.db or addon.db[oldKey] == nil then return end
	local legacy = addon.db[oldKey]
	addon.db[oldKey] = nil
	if legacy then addon.db[targetVar] = "hide" end
end

local function MigrateLegacyVisibilityFlags()
	if not addon.db then return end
	MigrateLegacyVisibilityFlag("hidePlayerFrame", "unitframeSettingPlayerFrame")
	MigrateLegacyVisibilityFlag("hideMicroMenu", "unitframeSettingMicroMenu")
	MigrateLegacyVisibilityFlag("hideBagsBar", "unitframeSettingBagsBar")
	MigrateLegacyVisibilityFlag("hideBuffFrame", "unitframeSettingBuffFrame")
	MigrateLegacyVisibilityFlag("hideDebuffFrame", "unitframeSettingDebuffFrame")
end

local function StopFrameFade(target)
	local group = target and target.EQOL_FadeGroup
	if group and group.Stop then group:Stop() end
	if group then group.targetAlpha = nil end
end

local function ApplyAlphaToRegion(target, alpha, _useFade)
	if not target or not target.SetAlpha then return end
	-- Keep visibility alpha behavior, but apply immediately (no animated fade).
	StopFrameFade(target)
	if target.GetAlpha then
		local currentAlpha = target:GetAlpha()
		if not (issecretvalue and issecretvalue(currentAlpha)) and currentAlpha and math.abs(currentAlpha - alpha) <= 0.001 then return end
	end
	target:SetAlpha(alpha)
end

local function RestoreItemButtonIconAlpha(button)
	if not button then return end
	local icon
	if _G.GetItemButtonIconTexture and button.GetName and button:GetName() then icon = _G.GetItemButtonIconTexture(button) end
	icon = icon or button.Icon or button.icon
	if icon and icon.SetAlpha then ApplyAlphaToRegion(icon, 1, false) end
end

local function RestoreUnitFrameVisibility(frame, cbData)
	ApplyAlphaToRegion(frame, 1, false)
	if cbData and cbData.children then
		for _, child in pairs(cbData.children) do
			ApplyAlphaToRegion(child, 1, false)
			RestoreItemButtonIconAlpha(child)
		end
	end
	if cbData and cbData.hideChildren then
		for _, child in pairs(cbData.hideChildren) do
			ApplyAlphaToRegion(child, 1, false)
			RestoreItemButtonIconAlpha(child)
		end
	end
end

local BOSS_FRAME_CONTAINER_NAME = "BossTargetFrameContainer"
local bossFrameForceHidden
local bossFramePrevSelectionAlpha
local bossFrameAlphaHooked

local function IsBossFrameContainer(frame)
	if not frame then return false end
	if frame == _G[BOSS_FRAME_CONTAINER_NAME] then return true end
	if frame.GetName and frame:GetName() == BOSS_FRAME_CONTAINER_NAME then return true end
	return false
end

local function EnsureBossFrameHideHook(container)
	if bossFrameAlphaHooked or not container or not hooksecurefunc then return end
	bossFrameAlphaHooked = true
	hooksecurefunc(container, "SetAlpha", function(self)
		if bossFrameForceHidden and self.GetAlpha and self:GetAlpha() ~= 0 then self:SetAlpha(0) end
	end)
end

local function SetBossFrameHidden(shouldHide)
	local container = _G[BOSS_FRAME_CONTAINER_NAME]
	if not container or not container.SetAlpha then return end

	EnsureBossFrameHideHook(container)

	local selection = container.Selection
	local hide = shouldHide and true or false

	if hide then
		if not bossFrameForceHidden then
			if selection and selection.GetAlpha then bossFramePrevSelectionAlpha = selection:GetAlpha() end
		end
		bossFrameForceHidden = true
		if container.GetAlpha and container:GetAlpha() ~= 0 then container:SetAlpha(0) end
		if selection and selection.SetAlpha then selection:SetAlpha(0) end
		return
	end

	if container.GetAlpha and container:GetAlpha() ~= 1 then container:SetAlpha(1) end
	if bossFrameForceHidden and selection and selection.SetAlpha then
		local selectionAlpha = bossFramePrevSelectionAlpha
		if selectionAlpha == nil then selectionAlpha = 1 end
		selection:SetAlpha(selectionAlpha)
	end

	bossFrameForceHidden = false
	bossFramePrevSelectionAlpha = nil
end

local UpdateUnitFrameMouseover -- forward declaration

local frameVisibilityContext = {
	inCombat = false,
	hasFocus = false,
	hasTarget = false,
	inGroup = false,
	inParty = false,
	inRaid = false,
	isFlying = false,
	isSkyriding = false,
	isCasting = false,
	isMounted = false,
	inInstance = false,
}
local frameVisibilityStates = {}
local hookedUnitFrames = {}
local ApplyFrameVisibilityState -- forward declaration
local IsInDruidTravelForm
local GetDruidTravelStanceIndexes
local EnsureSkyridingStateDriver
local EnsureSpellActivationOverlayWatcher

local function IsPlayerCasting()
	if UnitCastingInfo and UnitCastingInfo("player") then return true end
	if UnitChannelInfo and UnitChannelInfo("player") then return true end
	return false
end

local function IsPlayerDeadOrGhost()
	if UnitIsDeadOrGhost then return UnitIsDeadOrGhost("player") == true end
	if UnitIsDead and UnitIsDead("player") then return true end
	if UnitIsGhost and UnitIsGhost("player") then return true end
	return false
end

local function IsPlayerMounted()
	if IsMounted and IsMounted() then return true end
	if IsInDruidTravelForm and IsInDruidTravelForm() then return true end
	return false
end

local function IsPlayerFlying()
	if IsPlayerDeadOrGhost() then return false end
	if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
		local isGliding = C_PlayerInfo.GetGlidingInfo()
		if isGliding ~= nil then return isGliding == true end
	end
	if IsFlying and IsFlying() then return true end
	return false
end

local function IsPlayerMountedOrInVehicleUI()
	if IsPlayerMounted() then return true end
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true end
	if UnitInVehicle and UnitInVehicle("player") then return true end
	if C_ActionBar and C_ActionBar.HasVehicleActionBar and C_ActionBar.HasVehicleActionBar() then return true end
	return false
end

local function UpdateFrameVisibilityContext()
	local inCombat = false
	if InCombatLockdown and InCombatLockdown() then
		inCombat = true
	elseif UnitAffectingCombat then
		inCombat = UnitAffectingCombat("player") and true or false
	end
	frameVisibilityContext.inCombat = inCombat

	local hasFocus = UnitExists and UnitExists("focus") and true or false
	local hasTarget = UnitExists and UnitExists("target") and true or false
	local inRaid = (IsInRaid and IsInRaid()) and true or false
	local inGroup = (IsInGroup and IsInGroup()) and true or false
	frameVisibilityContext.hasFocus = hasFocus
	frameVisibilityContext.hasTarget = hasTarget
	frameVisibilityContext.inGroup = inGroup
	frameVisibilityContext.inParty = inGroup and not inRaid
	frameVisibilityContext.inRaid = inRaid
	local deadOrGhost = IsPlayerDeadOrGhost()
	frameVisibilityContext.isFlying = IsPlayerFlying()
	frameVisibilityContext.isSkyriding = not deadOrGhost and addon.variables and addon.variables.isPlayerSkyriding and true or false
	frameVisibilityContext.isCasting = IsPlayerCasting()
	frameVisibilityContext.isMounted = IsPlayerMounted()
	frameVisibilityContext.inInstance = IsInInstance and IsInInstance() and true or false
end

local function SafeRegisterUnitEvent(frame, event, ...)
	if not frame or not frame.RegisterUnitEvent or type(event) ~= "string" then return false end
	local ok = pcall(frame.RegisterUnitEvent, frame, event, ...)
	return ok
end

addon.visibilityRuntime.playerCastingEvents = {
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP",
}

function addon.visibilityRuntime:SetPlayerCastingEventInterest(watcher, enabled)
	if not watcher then return end
	enabled = enabled == true
	if watcher._eqolPlayerCastingEventsRegistered == enabled then return end
	for _, event in ipairs(self.playerCastingEvents) do
		if enabled then
			SafeRegisterUnitEvent(watcher, event, "player")
		elseif watcher.UnregisterEvent then
			watcher:UnregisterEvent(event)
		end
	end
	watcher._eqolPlayerCastingEventsRegistered = enabled
end

addon.functions.VisibilityConfigUsesManualEvaluation = function(config, opts)
	if type(config) ~= "table" or not next(config) then return false end
	local allowMouseover = not (opts and opts.allowMouseover == false)
	local allowCasting = not (opts and opts.allowCasting == false)
	if allowMouseover and config.MOUSEOVER then return true end
	if allowCasting and config.PLAYER_CASTING then return true end
	if config.SHOW_IN_INSTANCE then return true end
	return false
end

local function BuildUnitFrameDriverExpression(config, opts)
	if type(config) ~= "table" or not next(config) then return nil end
	if addon.functions.VisibilityConfigUsesManualEvaluation(config) then return nil end
	if config.ALWAYS_HIDDEN then return "hide" end

	local hideClauses = {}
	local hideSeen = {}
	local inactiveClauses = {}
	local inactiveSeen = {}
	local showClauses = {}
	local showSeen = {}

	local function addClause(target, seen, clause)
		if type(clause) ~= "string" or clause == "" or seen[clause] then return end
		seen[clause] = true
		target[#target + 1] = clause
	end

	local function addSkyridingClauses(target, seen)
		addClause(target, seen, "nodead,advflyable,flyable,mounted,flying")
		if addon.variables and addon.variables.unitClass == "DRUID" and GetDruidTravelStanceIndexes then
			for _, idx in ipairs(GetDruidTravelStanceIndexes()) do
				addClause(target, seen, ("nodead,advflyable,flyable,stance:%d,flying"):format(idx))
			end
		end
	end

	local function addMountedClauses(target, seen)
		addClause(target, seen, "mounted")
		if addon.variables and addon.variables.unitClass == "DRUID" and GetDruidTravelStanceIndexes then
			for _, idx in ipairs(GetDruidTravelStanceIndexes()) do
				addClause(target, seen, ("stance:%d"):format(idx))
			end
		end
	end

	local function addNotMountedClauses(target, seen)
		if addon.variables and addon.variables.unitClass == "DRUID" and GetDruidTravelStanceIndexes then
			local stanceIndexes = GetDruidTravelStanceIndexes()
			if #stanceIndexes > 0 then
				local clause = "nomounted"
				for _, idx in ipairs(stanceIndexes) do
					clause = ("%s,nostance:%d"):format(clause, idx)
				end
				addClause(target, seen, clause)
			else
				addClause(target, seen, "nomounted")
			end
		else
			addClause(target, seen, "nomounted")
		end
	end

	if config.ALWAYS_HIDE_IN_GROUP then addClause(hideClauses, hideSeen, "group") end
	if config.ALWAYS_HIDE_IN_PARTY then addClause(hideClauses, hideSeen, "group:party") end
	if config.ALWAYS_HIDE_IN_RAID then addClause(hideClauses, hideSeen, "group:raid") end
	if config.SKYRIDING_INACTIVE then addSkyridingClauses(inactiveClauses, inactiveSeen) end
	if config.FLYING_INACTIVE then addClause(inactiveClauses, inactiveSeen, "nodead,flying") end

	if config.ALWAYS_IN_COMBAT then addClause(showClauses, showSeen, "combat") end
	if config.ALWAYS_OUT_OF_COMBAT then addClause(showClauses, showSeen, "nocombat") end
	if config.SKYRIDING_ACTIVE then addSkyridingClauses(showClauses, showSeen) end
	if config.FLYING_ACTIVE then addClause(showClauses, showSeen, "nodead,flying") end
	if config.PLAYER_HAS_FOCUS then addClause(showClauses, showSeen, "@focus,exists") end
	if config.PLAYER_HAS_TARGET then addClause(showClauses, showSeen, "@target,exists") end
	if config.PLAYER_MOUNTED then addMountedClauses(showClauses, showSeen) end
	if config.PLAYER_NOT_MOUNTED then addNotMountedClauses(showClauses, showSeen) end
	if config.PLAYER_IN_GROUP then addClause(showClauses, showSeen, "group") end
	if config.PLAYER_IN_PARTY then addClause(showClauses, showSeen, "group:party") end
	if config.PLAYER_IN_RAID then addClause(showClauses, showSeen, "group:raid") end

	if #hideClauses == 0 and #inactiveClauses == 0 and #showClauses == 0 then return nil end

	local expressions = {}
	local function appendConditionalClauses(clauses, action, prefix)
		for _, clause in ipairs(clauses) do
			local condition = clause
			if type(prefix) == "string" and prefix ~= "" and prefix ~= condition then condition = prefix .. "," .. condition end
			expressions[#expressions + 1] = ("[%s] %s"):format(condition, action)
		end
	end

	local showPrefix = nil
	if opts and type(opts.showPrefix) == "string" and opts.showPrefix ~= "" then showPrefix = opts.showPrefix end
	local inactiveState = "hide"
	if opts and (opts.inactiveState == "fade" or opts.inactiveState == "show") then inactiveState = opts.inactiveState end
	appendConditionalClauses(opts and opts.prependHideClauses or {}, "hide")
	appendConditionalClauses(hideClauses, "hide")
	appendConditionalClauses(inactiveClauses, inactiveState, showPrefix)
	appendConditionalClauses(showClauses, "show", showPrefix)

	local defaultState = (#showClauses == 0 and (#hideClauses > 0 or #inactiveClauses > 0)) and "show" or inactiveState
	if defaultState == "show" and showPrefix then
		expressions[#expressions + 1] = ("[%s] show"):format(showPrefix)
		expressions[#expressions + 1] = "hide"
	elseif defaultState == "fade" and showPrefix then
		expressions[#expressions + 1] = ("[%s] fade"):format(showPrefix)
		expressions[#expressions + 1] = "hide"
	else
		expressions[#expressions + 1] = defaultState
	end

	return table.concat(expressions, "; ")
end
addon.functions.BuildUnitFrameDriverExpression = BuildUnitFrameDriverExpression

local function EnsureUnitFrameDriverWatcher()
	addon.variables = addon.variables or {}
	if addon.variables.unitFrameDriverWatcher then return end
	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:SetScript("OnEvent", function()
		local pending = addon.variables.pendingUnitFrameDriverUpdates
		if not pending then return end
		addon.variables.pendingUnitFrameDriverUpdates = nil
		for frame, data in pairs(pending) do
			if frame then
				if not data or not data.expression then
					if UnregisterStateDriver then pcall(UnregisterStateDriver, frame, "visibility") end
					frame.EQOL_VisibilityStateDriver = nil
					if data and data.showWhenCleared and frame.Show then pcall(frame.Show, frame) end
				elseif RegisterStateDriver then
					local ok = pcall(RegisterStateDriver, frame, "visibility", data.expression)
					if ok then frame.EQOL_VisibilityStateDriver = data.expression end
				end
			end
		end
	end)
	addon.variables.unitFrameDriverWatcher = watcher
end

local function ApplyUnitFrameStateDriver(frame, expression, showWhenCleared)
	if not frame then return end
	if frame.EQOL_VisibilityStateDriver == expression then return end
	if InCombatLockdown and InCombatLockdown() then
		addon.variables = addon.variables or {}
		addon.variables.pendingUnitFrameDriverUpdates = addon.variables.pendingUnitFrameDriverUpdates or {}
		addon.variables.pendingUnitFrameDriverUpdates[frame] = { expression = expression, showWhenCleared = showWhenCleared == true }
		EnsureUnitFrameDriverWatcher()
		return
	end
	if not expression then
		if UnregisterStateDriver then pcall(UnregisterStateDriver, frame, "visibility") end
		frame.EQOL_VisibilityStateDriver = nil
		if showWhenCleared and frame.Show then pcall(frame.Show, frame) end
		return
	end
	if RegisterStateDriver then
		local ok = pcall(RegisterStateDriver, frame, "visibility", expression)
		if ok then frame.EQOL_VisibilityStateDriver = expression end
	end
end

local function RefreshAllFrameVisibilities()
	UpdateFrameVisibilityContext()
	for _, state in pairs(frameVisibilityStates) do
		ApplyFrameVisibilityState(state)
	end
end
addon.functions.RefreshAllFrameVisibilityAlpha = RefreshAllFrameVisibilities

function addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
	local watcher = addon.variables and addon.variables.frameVisibilityWatcher
	if not watcher then return end
	local needsPlayerCasting = false
	for _, state in pairs(frameVisibilityStates) do
		local cfg = state and state.config
		if not state.driverActive and state.supportsPlayerCastingRule == true and cfg and cfg.PLAYER_CASTING == true then
			needsPlayerCasting = true
			break
		end
	end
	self:SetPlayerCastingEventInterest(watcher, needsPlayerCasting)
end

local function EnsureFrameVisibilityWatcher()
	addon.variables = addon.variables or {}
	if addon.variables.frameVisibilityWatcher then return end

	local watcher = CreateFrame("Frame")
	watcher:SetScript("OnEvent", RefreshAllFrameVisibilities)
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("PLAYER_DEAD")
	watcher:RegisterEvent("PLAYER_ALIVE")
	watcher:RegisterEvent("PLAYER_UNGHOST")
	watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
	watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
	watcher:RegisterEvent("PLAYER_FLAGS_CHANGED")
	watcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	watcher:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
	watcher:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
	watcher:RegisterEvent("UPDATE_INSTANCE_INFO")
	watcher:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
	addon.variables.frameVisibilityWatcher = watcher
	addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
	UpdateFrameVisibilityContext()
end

local function clampVisibilityAlpha(value)
	if type(value) ~= "number" then return nil end
	if value < 0 then return 0 end
	if value > 1 then return 1 end
	return value
end

local function GetManualFrameVisibilityInactiveAlpha()
	local strength = addon.db and tonumber(addon.db.frameVisibilityFadeStrength) or nil
	if strength == nil then strength = 1 end
	if strength < 0 then strength = 0 end
	if strength > 1 then strength = 1 end
	return 1 - strength
end

local function HasFrameVisibilityInactiveHideRule(cfg)
	if type(cfg) ~= "table" then return false end
	return (cfg.SKYRIDING_INACTIVE or cfg.FLYING_INACTIVE or cfg.ALWAYS_HIDE_IN_GROUP or cfg.ALWAYS_HIDE_IN_PARTY or cfg.ALWAYS_HIDE_IN_RAID) and true or false
end

local function EvaluateFrameVisibility(state)
	local cfg = state.config
	if not cfg or not next(cfg) then return false, nil end

	if cfg.ALWAYS_HIDDEN then return false, "ALWAYS_HIDDEN" end
	local context = frameVisibilityContext

	if state.supportsGroupRule then
		local activeGroupedHideRule
		if cfg.ALWAYS_HIDE_IN_GROUP and context.inGroup then
			activeGroupedHideRule = "ALWAYS_HIDE_IN_GROUP"
		elseif cfg.ALWAYS_HIDE_IN_PARTY and context.inParty then
			activeGroupedHideRule = "ALWAYS_HIDE_IN_PARTY"
		elseif cfg.ALWAYS_HIDE_IN_RAID and context.inRaid then
			activeGroupedHideRule = "ALWAYS_HIDE_IN_RAID"
		end
		if activeGroupedHideRule then
			if cfg.MOUSEOVER and state.isMouseOver then return true, "MOUSEOVER" end
			return false, activeGroupedHideRule
		end
	end

	if state.supportsPlayerMountedRule then
		if cfg.SKYRIDING_INACTIVE and context.isSkyriding then return false, "SKYRIDING_INACTIVE" end
		if cfg.FLYING_INACTIVE and context.isFlying then return false, "FLYING_INACTIVE" end
	end

	-- If only hide-type rules are active, keep the frame visible while none of
	-- those hide conditions currently match.
	local hasShowRule = (
		cfg.MOUSEOVER
		or cfg.ALWAYS_IN_COMBAT
		or cfg.ALWAYS_OUT_OF_COMBAT
		or cfg.SKYRIDING_ACTIVE
		or cfg.FLYING_ACTIVE
		or cfg.PLAYER_HAS_FOCUS
		or cfg.PLAYER_HAS_TARGET
		or cfg.PLAYER_CASTING
		or cfg.PLAYER_MOUNTED
		or cfg.PLAYER_NOT_MOUNTED
		or cfg.PLAYER_IN_GROUP
		or cfg.PLAYER_IN_PARTY
		or cfg.PLAYER_IN_RAID
		or cfg.SHOW_IN_INSTANCE
	)
			and true
		or false
	if not hasShowRule and HasFrameVisibilityInactiveHideRule(cfg) then return true, "HIDE_RULES_INACTIVE" end

	if cfg.SHOW_IN_INSTANCE and context.inInstance then return true, "SHOW_IN_INSTANCE" end
	if cfg.ALWAYS_IN_COMBAT and context.inCombat then return true, "ALWAYS_IN_COMBAT" end
	if cfg.ALWAYS_OUT_OF_COMBAT and not context.inCombat then return true, "ALWAYS_OUT_OF_COMBAT" end
	if cfg.SKYRIDING_ACTIVE and state.supportsPlayerMountedRule and context.isSkyriding then return true, "SKYRIDING_ACTIVE" end
	if cfg.FLYING_ACTIVE and state.supportsPlayerMountedRule and context.isFlying then return true, "FLYING_ACTIVE" end
	if cfg.PLAYER_HAS_FOCUS and state.supportsPlayerFocusRule and context.hasFocus then return true, "PLAYER_HAS_FOCUS" end
	if cfg.PLAYER_HAS_TARGET and state.supportsPlayerTargetRule and context.hasTarget then return true, "PLAYER_HAS_TARGET" end
	if cfg.PLAYER_CASTING and state.supportsPlayerCastingRule and context.isCasting then return true, "PLAYER_CASTING" end
	if cfg.PLAYER_MOUNTED and state.supportsPlayerMountedRule and context.isMounted then return true, "PLAYER_MOUNTED" end
	if cfg.PLAYER_NOT_MOUNTED and state.supportsPlayerMountedRule and not context.isMounted then return true, "PLAYER_NOT_MOUNTED" end
	if cfg.PLAYER_IN_GROUP and state.supportsGroupRule and context.inGroup then return true, "PLAYER_IN_GROUP" end
	if cfg.PLAYER_IN_PARTY and state.supportsGroupRule and context.inParty then return true, "PLAYER_IN_PARTY" end
	if cfg.PLAYER_IN_RAID and state.supportsGroupRule and context.inRaid then return true, "PLAYER_IN_RAID" end
	if cfg.MOUSEOVER and state.isMouseOver then return true, "MOUSEOVER" end

	return false, nil
end

addon.functions.ShouldShowVisibilityConfig = function(config, opts)
	if type(config) ~= "table" or not next(config) then return true, nil end
	if config.SKYRIDING_ACTIVE or config.SKYRIDING_INACTIVE then EnsureSkyridingStateDriver() end
	UpdateFrameVisibilityContext()
	local state = {
		config = config,
		isMouseOver = opts and opts.isMouseOver == true or false,
		supportsPlayerFocusRule = not (opts and opts.supportsPlayerFocusRule == false),
		supportsPlayerTargetRule = not (opts and opts.supportsPlayerTargetRule == false),
		supportsPlayerCastingRule = not (opts and opts.supportsPlayerCastingRule == false),
		supportsPlayerMountedRule = not (opts and opts.supportsPlayerMountedRule == false),
		supportsGroupRule = not (opts and opts.supportsGroupRule == false),
	}
	return EvaluateFrameVisibility(state)
end

local function ApplyToFrameAndChildren(state, alpha, useFade)
	local frame = state.frame
	local cbData = state.cbData
	local hasChildren = cbData and (cbData.children or cbData.hideChildren)
	local restoreChildAlpha = hasChildren and alpha > 0 and alpha < 1

	-- Parent alpha already multiplies child alpha on container-style Blizzard frames.
	-- During partial fade, keep children at 1 so the configured alpha is not squared.
	if frame then ApplyAlphaToRegion(frame, alpha, useFade) end

	local childAlpha = restoreChildAlpha and 1 or alpha
	if cbData and cbData.children then
		for _, child in pairs(cbData.children) do
			ApplyAlphaToRegion(child, childAlpha, useFade)
			if restoreChildAlpha then RestoreItemButtonIconAlpha(child) end
		end
	end

	if cbData and cbData.hideChildren then
		for _, child in pairs(cbData.hideChildren) do
			ApplyAlphaToRegion(child, childAlpha, useFade)
			if restoreChildAlpha then RestoreItemButtonIconAlpha(child) end
		end
	end
end

local function genericHoverOutCheck(state)
	if not state or not state.frame then return end
	if not state.config or not state.config.MOUSEOVER then return end

	C_Timer.After(0.05, function()
		if not state.frame or frameVisibilityStates[state.frame] ~= state then return end
		if not state.frame:IsVisible() then return end

		local hovered = MouseIsOver(state.frame)
		if not hovered and state.cbData and state.cbData.revealAllChilds and state.cbData.children then
			for _, child in pairs(state.cbData.children) do
				if child and child:IsVisible() and MouseIsOver(child) then
					hovered = true
					break
				end
			end
		end

		state.isMouseOver = hovered
		if hovered then
			C_Timer.After(0.3, function()
				if frameVisibilityStates[state.frame] == state then genericHoverOutCheck(state) end
			end)
		else
			ApplyFrameVisibilityState(state)
		end
	end)
end

ApplyFrameVisibilityState = function(state)
	if state.isBossFrame then
		local cfg = state.config
		if not cfg or not next(cfg) then
			if state.visible ~= nil then SetBossFrameHidden(false) end
			frameVisibilityStates[state.frame] = nil
			addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
			return
		end

		EnsureFrameVisibilityWatcher()
		local shouldShow = EvaluateFrameVisibility(state)
		SetBossFrameHidden(not shouldShow)
		state.visible = shouldShow
		return
	end

	local cfg = state.config
	if not cfg or not next(cfg) then
		if state.visible ~= nil then RestoreUnitFrameVisibility(state.frame, state.cbData) end
		frameVisibilityStates[state.frame] = nil
		addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
		return
	end

	if state.driverActive then return end

	EnsureFrameVisibilityWatcher()
	UpdateFrameVisibilityContext()
	local shouldShow, activeRule = EvaluateFrameVisibility(state)
	local forcedHidden = activeRule == "ALWAYS_HIDDEN" or activeRule == "ALWAYS_HIDE_IN_GROUP" or activeRule == "ALWAYS_HIDE_IN_PARTY" or activeRule == "ALWAYS_HIDE_IN_RAID"
	local targetAlpha = 1
	if forcedHidden then
		targetAlpha = 0
	elseif not shouldShow then
		targetAlpha = GetManualFrameVisibilityInactiveAlpha()
	end
	targetAlpha = clampVisibilityAlpha(targetAlpha) or 0

	local lastAlpha = state.lastAlpha
	local actualAlpha
	if state.frame and state.frame.GetAlpha then actualAlpha = state.frame:GetAlpha() end
	local alphaAlreadyApplied = lastAlpha ~= nil and math.abs(lastAlpha - targetAlpha) <= 0.001 and (actualAlpha == nil or math.abs(actualAlpha - targetAlpha) <= 0.001)
	if
		state.visible == shouldShow
		and state.activeRule == activeRule
		and alphaAlreadyApplied
	then
		return
	end

	ApplyToFrameAndChildren(state, targetAlpha, true)
	state.visible = shouldShow
	state.activeRule = activeRule
	state.lastAlpha = targetAlpha
end

local function HookFrameForMouseover(frame, cbData)
	if hookedUnitFrames[frame] then return end

	local function handleEnter()
		local state = frameVisibilityStates[frame]
		if not state or not state.config or not state.config.MOUSEOVER then return end
		state.isMouseOver = true
		ApplyFrameVisibilityState(state)
	end

	local function handleLeave()
		local state = frameVisibilityStates[frame]
		if not state then return end
		genericHoverOutCheck(state)
	end

	if frame.OnEnter or frame:GetScript("OnEnter") then
		frame:HookScript("OnEnter", handleEnter)
	else
		frame:SetScript("OnEnter", handleEnter)
	end

	if frame.OnLeave or frame:GetScript("OnLeave") then
		frame:HookScript("OnLeave", handleLeave)
	else
		frame:SetScript("OnLeave", handleLeave)
	end

	if cbData and cbData.children and cbData.revealAllChilds then
		for _, child in pairs(cbData.children) do
			if child and not child.EQOL_MouseoverHooked then
				child:HookScript("OnEnter", function()
					local state = frameVisibilityStates[frame]
					if not state or not state.config or not state.config.MOUSEOVER then return end
					state.isMouseOver = true
					ApplyFrameVisibilityState(state)
				end)
				child:HookScript("OnLeave", function()
					local state = frameVisibilityStates[frame]
					if not state then return end
					genericHoverOutCheck(state)
				end)
				child.EQOL_MouseoverHooked = true
			end
		end
	end

	hookedUnitFrames[frame] = true
end

local function EnsureFrameState(frame, cbData)
	local state = frameVisibilityStates[frame]
	if not state then
		state = { frame = frame, cbData = cbData, isMouseOver = false }
		frameVisibilityStates[frame] = state
		HookFrameForMouseover(frame, cbData)
	else
		state.cbData = cbData
	end
	return state
end

local function ClearUnitFrameState(frame, cbData, opts)
	if not frame then return end
	if IsBossFrameContainer(frame) then
		ApplyUnitFrameStateDriver(frame, nil, cbData and cbData.showWhenNoRule)
		SetBossFrameHidden(false)
		frameVisibilityStates[frame] = nil
		addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
		return
	end
	local hasDriver = frame.EQOL_VisibilityStateDriver ~= nil or (frame.GetAttribute and frame:GetAttribute("state-visibility") ~= nil)
	if not (opts and opts.noStateDriver) or hasDriver then ApplyUnitFrameStateDriver(frame, nil, cbData and cbData.showWhenNoRule) end
	RestoreUnitFrameVisibility(frame, cbData)
	frameVisibilityStates[frame] = nil
	addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
end

local function ApplyVisibilityToUnitFrame(frameName, cbData, config, opts)
	if type(frameName) ~= "string" or frameName == "" then return false end
	local frame = _G[frameName]
	if not frame then return false end

	if not config then
		ClearUnitFrameState(frame, cbData, opts)
		return true
	end

	local state = EnsureFrameState(frame, cbData)
	state.config = config
	state.isBossFrame = frameName == BOSS_FRAME_CONTAINER_NAME
	local unitToken = cbData.unitToken
	local isPlayerUnit = (unitToken == "player")
	local supportsPlayerScopedRules = isPlayerUnit or unitToken == "target" or unitToken == "targettarget" or unitToken == "focus" or unitToken == "pet"
	state.supportsPlayerTargetRule = supportsPlayerScopedRules
	state.supportsPlayerCastingRule = supportsPlayerScopedRules
	state.supportsPlayerMountedRule = supportsPlayerScopedRules
	state.supportsGroupRule = supportsPlayerScopedRules

	local driverExpression = BuildUnitFrameDriverExpression(config)
	local usesManualRules = config
		and (
			config.MOUSEOVER
			or config.PLAYER_CASTING
			or config.SKYRIDING_ACTIVE
			or config.SKYRIDING_INACTIVE
			or config.FLYING_ACTIVE
			or config.FLYING_INACTIVE
		)
	local useDriver = driverExpression and not usesManualRules and not (opts and opts.noStateDriver) and not state.isBossFrame

	if not useDriver and config and (config.SKYRIDING_ACTIVE or config.SKYRIDING_INACTIVE) then EnsureSkyridingStateDriver() end

	if useDriver then
		state.driverActive = true
		addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
		ApplyUnitFrameStateDriver(frame, driverExpression)
		ApplyToFrameAndChildren(state, 1, false)
		return true
	end

	local hadDriver = state.driverActive == true or frame.EQOL_VisibilityStateDriver ~= nil or (frame.GetAttribute and frame:GetAttribute("state-visibility") ~= nil)
	state.driverActive = false
	addon.visibilityRuntime:UpdateFrameWatcherEventInterest()
	if not (opts and opts.noStateDriver) or state.isBossFrame or hadDriver then ApplyUnitFrameStateDriver(frame, nil, state.cbData and state.cbData.showWhenNoRule) end

	if config.MOUSEOVER then
		state.isMouseOver = MouseIsOver(frame)
	else
		state.isMouseOver = false
	end
	ApplyFrameVisibilityState(state)
	return true
end

UpdateUnitFrameMouseover = function(barName, cbData)
	if not cbData or not cbData.var then return end

	local config = NormalizeUnitFrameVisibilityConfig(cbData.var)
	local manualOpts = { noStateDriver = not (config and config.ALWAYS_HIDDEN == true) }
	-- local handled = false

	if barName == BOSS_FRAME_CONTAINER_NAME then
		local onlyChildren = cbData.onlyChildren
		local children = {}
		if type(onlyChildren) == "table" then
			local seen = {}
			for _, child in ipairs(onlyChildren) do
				if type(child) == "string" and child ~= "" and not seen[child] then
					local frame = _G[child]
					if frame then
						table.insert(children, frame)
						seen[child] = true
					end
				end
			end
			for _, child in pairs(onlyChildren) do
				if type(child) == "string" and child ~= "" and not seen[child] then
					local frame = _G[child]
					if frame then
						table.insert(children, frame)
						seen[child] = true
					end
				end
			end
		end

		if #children > 0 then
			cbData.children = children
			cbData.revealAllChilds = true
		else
			cbData.children = nil
			cbData.revealAllChilds = nil
		end

		ApplyVisibilityToUnitFrame(barName, cbData, config, manualOpts)
		return
	end

	local function processTarget(name)
		if ApplyVisibilityToUnitFrame(name, cbData, config, manualOpts) then
			-- handled = true
		end
	end

	local onlyChildren = cbData.onlyChildren
	local hasChildTargets = false
	if type(onlyChildren) == "table" then
		local seen = {}
		for _, child in ipairs(onlyChildren) do
			if type(child) == "string" and child ~= "" and not seen[child] then
				processTarget(child)
				seen[child] = true
				hasChildTargets = true
			end
		end
		for _, child in pairs(onlyChildren) do
			if type(child) == "string" and child ~= "" and not seen[child] then
				processTarget(child)
				seen[child] = true
				hasChildTargets = true
			end
		end
		if hasChildTargets then
			local container = _G[barName]
			ClearUnitFrameState(container, cbData)
		end
	end

	if not hasChildTargets then processTarget(barName) end
end
addon.functions.UpdateUnitFrameMouseover = UpdateUnitFrameMouseover

local function ApplyFrameVisibilityConfig(frameName, cbData, config, opts) return ApplyVisibilityToUnitFrame(frameName, cbData, config, opts) end
addon.functions.ApplyFrameVisibilityConfig = ApplyFrameVisibilityConfig

local function ApplyUnitFrameSettingByVar(varName)
	if not varName then return end
	for _, data in ipairs(addon.variables.unitFrameNames) do
		if data.var == varName and data.name then
			UpdateUnitFrameMouseover(data.name, data)
			break
		end
	end
end
addon.functions.ApplyUnitFrameSettingByVar = ApplyUnitFrameSettingByVar

local function IsCooldownViewerEnabled()
	if not C_CVar or not C_CVar.GetCVar then return false end
	addon.variables = addon.variables or {}
	if addon.variables.cooldownViewerEnabledCache ~= nil and not addon.variables.cooldownViewerEnabledDirty then return addon.variables.cooldownViewerEnabledCache end
	local ok, value = pcall(C_CVar.GetCVar, "cooldownViewerEnabled")
	local enabled = ok and tonumber(value) == 1
	addon.variables.cooldownViewerEnabledCache = enabled
	addon.variables.cooldownViewerEnabledDirty = nil
	return enabled
end
addon.functions.IsCooldownViewerEnabled = IsCooldownViewerEnabled

local function normalizeCooldownViewerConfigValue(val, acc)
	acc = acc or {}
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE] = true end
	if val == COOLDOWN_VIEWER_VISIBILITY_MODES.ALWAYS_HIDDEN then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.ALWAYS_HIDDEN] = true end
	-- Legacy mapping: "hide while mounted" -> show while not mounted
	if val == "HIDE_WHILE_MOUNTED" then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED] = true end
	if val == "HIDE_IN_COMBAT" then acc[COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT] = nil end
	return acc
end

local function sanitizeCooldownViewerConfig(cfg)
	if type(cfg) == "table" then
		local result
		for key, value in pairs(cfg) do
			if value == true then result = normalizeCooldownViewerConfigValue(key, result or {}) end
		end
		return result
	end
	if type(cfg) == "string" then return normalizeCooldownViewerConfigValue(cfg, {}) end
	return nil
end

function addon.visibilityRuntime:GetConfigSignature(cfg, allowedKeys)
	local cfgType = type(cfg)
	if cfgType == "string" then return cfg end
	if cfgType ~= "table" then return cfgType end
	local signature = 0
	local bitValue = 1
	for _, key in ipairs(self.cooldownViewerConfigKeys) do
		if (not allowedKeys or allowedKeys[key]) and cfg[key] == true then signature = signature + bitValue end
		bitValue = bitValue * 2
	end
	return signature
end

function addon.visibilityRuntime:GetCachedCooldownViewerVisibility(frameName)
	addon.variables = addon.variables or {}
	local db = addon.db and addon.db.cooldownViewerVisibility
	local source = type(db) == "table" and db[frameName] or nil
	local signature = self:GetConfigSignature(source)
	if type(source) == "table" and source.HIDE_WHILE_MOUNTED == true then signature = signature + 16384 end
	local cache = addon.variables.cooldownViewerVisibilityConfigCache
	if not cache then
		cache = {}
		addon.variables.cooldownViewerVisibilityConfigCache = cache
	end
	local cached = cache[frameName]
	if cached and cached.source == source and cached.signature == signature then return cached.config end
	local sanitized = sanitizeCooldownViewerConfig(source)
	cache[frameName] = { source = source, signature = signature, config = sanitized }
	return sanitized
end

local function HasCooldownViewerVisibilityConfig()
	for _, frameName in ipairs(COOLDOWN_VIEWER_FRAMES) do
		local cfg = addon.visibilityRuntime:GetCachedCooldownViewerVisibility(frameName)
		if cfg and next(cfg) then return true end
	end
	return false
end

function addon.visibilityRuntime:CooldownViewerUsesPlayerCasting()
	for _, frameName in ipairs(COOLDOWN_VIEWER_FRAMES) do
		local cfg = self:GetCachedCooldownViewerVisibility(frameName)
		if cfg and cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] == true then return true end
	end
	return false
end

local DRUID_TRAVEL_FORM_SPELL_IDS = {
	[783] = true, -- Travel Form
	[1066] = true, -- Aquatic Form
	[33943] = true, -- Flight Form
	[40120] = true, -- Swift Flight Form
	[210053] = true, -- Mount Form (Stag)
}

GetDruidTravelStanceIndexes = function()
	local indexes = {}
	if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return indexes end
	for idx = 1, GetNumShapeshiftForms() do
		local _, _, _, spellID = GetShapeshiftFormInfo(idx)
		if spellID and DRUID_TRAVEL_FORM_SPELL_IDS[spellID] then indexes[#indexes + 1] = idx end
	end
	return indexes
end
addon.functions.GetDruidTravelStanceIndexes = GetDruidTravelStanceIndexes

IsInDruidTravelForm = function()
	local class = addon.variables and addon.variables.unitClass
	if not class and UnitClass then
		local _, eng = UnitClass("player")
		class = eng
	end
	if not class or class ~= "DRUID" then return false end
	if not GetShapeshiftForm then return false end
	local form = GetShapeshiftForm()
	if not form or form == 0 then return false end
	if GetShapeshiftFormID then
		local formID = GetShapeshiftFormID()
		if formID == DRUID_TRAVEL_FORM or formID == DRUID_ACQUATIC_FORM or formID == DRUID_FLIGHT_FORM or formID == 29 then return true end
	end
	local spellID = select(4, GetShapeshiftFormInfo(form))
	if spellID and DRUID_TRAVEL_FORM_SPELL_IDS[spellID] then return true end
	return false
end

local function computeCooldownViewerTargetAlpha(cfg, state)
	if not cfg or not next(cfg) then return 1 end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.ALWAYS_HIDDEN] then return 0 end

	local mounted = IsPlayerMountedOrInVehicleUI()
	local inCombat = (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player"))

	local hovered = state and state.hovered
	local sharedHover = addon.db and addon.db.cooldownViewerSharedHover
	local viewerStates = addon.variables and addon.variables.cooldownViewerStates
	if not hovered and sharedHover and viewerStates then
		for _, otherState in pairs(addon.variables.cooldownViewerStates) do
			if otherState.hovered then
				hovered = true
				break
			end
		end
	end

	local hasFocus = UnitExists and UnitExists("focus")
	local hasTarget = UnitExists and UnitExists("target")
	local isCasting = cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] and IsPlayerCasting() or false
	local inGroup = IsInGroup and IsInGroup() and true or false
	local inInstance = IsInInstance and IsInInstance() and true or false
	local isSkyriding = addon.variables and addon.variables.isPlayerSkyriding
	local isFlying = IsPlayerFlying()
	local fadedAlpha = (addon.functions and addon.functions.GetCooldownViewerFadedAlpha and addon.functions.GetCooldownViewerFadedAlpha()) or 0
	local hideSkyriding = cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE] == true
	local hideFlying = cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE] == true
	local hasShowRules = cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP]
		or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE]

	if hideSkyriding and isSkyriding then return fadedAlpha end
	if hideFlying and isFlying then return fadedAlpha end
	if not hasShowRules then return 1 end

	local shouldShow = false
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT] and inCombat then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED] and mounted then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED] and not mounted then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE] and isSkyriding then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE] and isFlying then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER] and hovered then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS] and hasFocus then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET] and hasTarget then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] and isCasting then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP] and inGroup then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE] and inInstance then shouldShow = true end

	if shouldShow then return 1 end
	return fadedAlpha
end

local function IsCooldownViewerInEditMode()
	if addon.variables and addon.variables.cooldownViewerEditMode ~= nil then return addon.variables.cooldownViewerEditMode end
	if addon.EditMode and addon.EditMode.IsInEditMode then
		local ok, result = pcall(addon.EditMode.IsInEditMode, addon.EditMode)
		if ok then return result end
	end
	return false
end

addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK = addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK or {
	frames = {
		"EssentialCooldownViewer",
		"UtilityCooldownViewer",
		"BuffIconCooldownViewer",
	},
	ufKeys = {
		"player",
		"target",
		"targettarget",
		"focus",
		"pet",
		"boss",
	},
	groupKinds = {
		"party",
		"raid",
		"mt",
		"ma",
	},
}

function addon.functions.IsFrameAnchoredToTarget(frame, target, visited)
	if not (frame and target and frame.GetNumPoints) then return false end
	if frame == target then return true end

	visited = visited or {}
	if visited[frame] then return false end
	visited[frame] = true

	local numPoints = frame:GetNumPoints() or 0
	for pointIndex = 1, numPoints do
		local _, relativeTo = frame:GetPoint(pointIndex)
		local relativeFrame = type(relativeTo) == "string" and _G[relativeTo] or relativeTo
		if relativeFrame then
			if relativeFrame == target then return true end
			if relativeFrame ~= UIParent and addon.functions.IsFrameAnchoredToTarget(relativeFrame, target, visited) then return true end
		end
	end

	return false
end

function addon.functions.CooldownViewerHasSecureDependents(viewerFrame)
	if not viewerFrame then return false end

	local uf = addon.Aura and addon.Aura.UF
	if uf and uf.GetAnchorFrameName then
		for _, unit in ipairs(addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK.ufKeys) do
			local frameName = uf.GetAnchorFrameName(unit)
			local anchorFrame = frameName and _G[frameName] or nil
			if anchorFrame and addon.functions.IsFrameAnchoredToTarget(anchorFrame, viewerFrame) then return true end
		end
	end

	local groupFrames = uf and uf.GroupFrames
	local anchors = groupFrames and groupFrames.anchors
	if anchors then
		for _, kind in ipairs(addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK.groupKinds) do
			local anchorFrame = anchors[kind]
			if anchorFrame and addon.functions.IsFrameAnchoredToTarget(anchorFrame, viewerFrame) then return true end
		end
	end

	return false
end

function addon.functions.EnsureCooldownViewerCombatLockOverlay(frameName)
	addon.variables = addon.variables or {}
	addon.variables.cooldownViewerCombatLockOverlays = addon.variables.cooldownViewerCombatLockOverlays or {}
	local overlay = addon.variables.cooldownViewerCombatLockOverlays[frameName]
	if overlay then return overlay end

	overlay = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
	overlay:Hide()
	overlay:EnableMouse(true)
	if overlay.SetPropagateMouseClicks then overlay:SetPropagateMouseClicks(false) end
	if overlay.SetPropagateMouseMotion then overlay:SetPropagateMouseMotion(false) end
	overlay:SetScript("OnMouseDown", function() end)
	overlay:SetScript("OnMouseUp", function() end)
	overlay:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	overlay:SetBackdropColor(0.05, 0.05, 0.05, 0.72)
	overlay:SetBackdropBorderColor(0.95, 0.3, 0.3, 0.9)
	overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	overlay.label:SetPoint("CENTER")
	overlay.label:SetJustifyH("CENTER")
	overlay.label:SetJustifyV("MIDDLE")
	overlay.label:SetWordWrap(true)
	overlay.label:SetTextColor(1, 0.85, 0.24, 1)
	addon.variables.cooldownViewerCombatLockOverlays[frameName] = overlay
	return overlay
end

function addon.functions.SyncCooldownViewerCombatLockOverlay(frameName, overlay, frame)
	frame = frame or (frameName and _G[frameName]) or nil
	overlay = overlay or (addon.variables and addon.variables.cooldownViewerCombatLockOverlays and addon.variables.cooldownViewerCombatLockOverlays[frameName]) or nil
	if not (frame and overlay) then return overlay end

	local targetFrame = frame.Selection or frame

	overlay:ClearAllPoints()
	overlay:SetAllPoints(targetFrame)

	if targetFrame.GetFrameStrata then overlay:SetFrameStrata(targetFrame:GetFrameStrata()) end
	overlay:SetFrameLevel(((targetFrame.GetFrameLevel and targetFrame:GetFrameLevel()) or 0) + 10)

	if overlay.label then
		local width = targetFrame.GetWidth and targetFrame:GetWidth() or 0
		overlay.label:SetWidth(math.max(48, width - 12))
		overlay.label:SetText(string.format("%s\n%s", LOCKED or "Locked", COMBAT or "Combat"))
	end

	return overlay
end

function addon.functions.UpdateCooldownViewerCombatLockOverlay(frameName)
	local frame = frameName and _G[frameName]
	local overlay = addon.variables and addon.variables.cooldownViewerCombatLockOverlays and addon.variables.cooldownViewerCombatLockOverlays[frameName]
	local inCombat = InCombatLockdown and InCombatLockdown()
	local locked = false

	if frame and not inCombat then
		overlay = overlay or addon.functions.EnsureCooldownViewerCombatLockOverlay(frameName)
		overlay = addon.functions.SyncCooldownViewerCombatLockOverlay(frameName, overlay, frame)
	end

	if frame and frame.IsShown and frame:IsShown() and IsCooldownViewerInEditMode() and inCombat then
		locked = addon.functions.CooldownViewerHasSecureDependents(frame) == true
	end

	if not locked then
		if overlay then overlay:Hide() end
		return
	end

	overlay = overlay or addon.functions.EnsureCooldownViewerCombatLockOverlay(frameName)
	if not inCombat then overlay = addon.functions.SyncCooldownViewerCombatLockOverlay(frameName, overlay, frame) end

	overlay:Show()
end

function addon.functions.UpdateCooldownViewerCombatLocks()
	for _, frameName in ipairs(addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK.frames) do
		addon.functions.UpdateCooldownViewerCombatLockOverlay(frameName)
	end
end

function addon.functions.EnsureCooldownViewerCombatLockWatcher()
	addon.variables = addon.variables or {}
	if addon.variables.cooldownViewerCombatLockWatcher then return end

	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
	watcher:SetScript("OnEvent", function()
		if addon.functions.UpdateCooldownViewerCombatLocks then addon.functions.UpdateCooldownViewerCombatLocks() end
	end)

	addon.variables.cooldownViewerCombatLockWatcher = watcher
	for _, frameName in ipairs(addon.constants.COOLDOWN_VIEWER_COMBAT_LOCK.frames) do
		if _G[frameName] then
			local overlay = addon.functions.EnsureCooldownViewerCombatLockOverlay(frameName)
			addon.functions.SyncCooldownViewerCombatLockOverlay(frameName, overlay, _G[frameName])
		end
	end
end

local function applyCooldownViewerMode(frameName, cfg)
	local frame = frameName and _G[frameName]
	if not frame then return false end

	local hasActiveConfig = false
	if type(cfg) == "table" then
		for _, v in pairs(cfg) do
			if v then
				hasActiveConfig = true
				break
			end
		end
	end

	local hoverEnabled = hasActiveConfig and cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER] == true

	addon.variables = addon.variables or {}
	addon.variables.cooldownViewerStates = addon.variables.cooldownViewerStates or {}
	local states = addon.variables.cooldownViewerStates

	local state = states[frame]

	if not hasActiveConfig and not state then return true end

	if not state then
		state = {
			frame = frame,
			frameName = frameName,

			hovered = false,
			applied = false,

			hoverEnabled = false,
			hoverPollInitialized = false,
			hoverPollRunning = false,

			prevOnUpdate = nil,
			onUpdateWrapper = nil,
			hoverHandlers = nil,
		}
		states[frame] = state
	end

	state.hoverEnabled = hoverEnabled

	if hoverEnabled and not state.hoverPollInitialized and frame.HookScript then
		state.hoverPollInitialized = true
		state.hoverHooked = false

		local function setHovered(v)
			if state.hovered == v then return end
			state.hovered = v
			if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
		end

		local function hoverUpdate(self, elapsed)
			self._eqolHoverElapsed = (self._eqolHoverElapsed or 0) + (elapsed or 0)
			if self._eqolHoverElapsed < 0.05 then return end -- ~20 Hz
			self._eqolHoverElapsed = 0
			setHovered(MouseIsOver(self))
		end

		local function startHoverPoll(self)
			if not state.hoverEnabled then return end
			if state.hoverPollRunning then return end
			state.hoverPollRunning = true

			self._eqolHoverElapsed = 0

			if not state.hoverHooked then
				self:HookScript("OnUpdate", hoverUpdate)
				state.hoverHooked = true
			end
		end

		local function stopHoverPoll(self)
			if not state.hoverPollRunning then return end
			state.hoverPollRunning = false

			setHovered(false)
		end

		state.hoverHandlers = { start = startHoverPoll, stop = stopHoverPoll }

		frame:HookScript("OnShow", startHoverPoll)
		frame:HookScript("OnHide", stopHoverPoll)

		-- Wenn er gerade sichtbar ist: direkt starten
		if frame.IsShown and frame:IsShown() then startHoverPoll(frame) end
	end

	-- Sicherstellen: ohne hoverEnabled wird NIE ein OnUpdate gesetzt.
	if state.hoverHandlers then
		if hoverEnabled then
			if frame.IsShown and frame:IsShown() then
				state.hoverHandlers.start(frame)
			else
				state.hoverHandlers.stop(frame)
			end
		else
			state.hoverHandlers.stop(frame)
			state.hovered = false
		end
	end

	-- Wenn nichts aktiv ist: Defaults herstellen, Polling stoppen und ggf. State komplett entfernen.
	if not hasActiveConfig then
		if state.hoverHandlers then state.hoverHandlers.stop(frame) end

		if state.applied and frame.GetAlpha and frame.SetAlpha and frame:GetAlpha() ~= 1 then frame:SetAlpha(1) end

		state.applied = false
		state.hoverEnabled = false
		state.hovered = false

		-- Wenn wir nie Hooks installiert haben, können wir den State komplett vergessen.
		-- (WICHTIG: wenn hoverPollInitialized true war, NICHT löschen, sonst hängen die Hook-Closures am alten state.)
		if not state.hoverPollInitialized then states[frame] = nil end

		return true
	end

	-- Ab hier: aktive Config -> normales Verhalten
	local targetAlpha = computeCooldownViewerTargetAlpha(cfg, state)
	if IsCooldownViewerInEditMode() then targetAlpha = 1 end
	if frame.GetAlpha and frame.SetAlpha then
		if issecretvalue(targetAlpha) or issecretvalue(frame:GetAlpha()) then
			frame:SetAlpha(targetAlpha)
		elseif frame:GetAlpha() ~= targetAlpha then
			frame:SetAlpha(targetAlpha)
		end
	end

	state.applied = true
	return true
end

local function ensureCooldownViewerDb()
	addon.db = addon.db or {}
	if type(addon.db.cooldownViewerVisibility) ~= "table" then addon.db.cooldownViewerVisibility = {} end
	return addon.db.cooldownViewerVisibility
end

function addon.functions.GetCooldownViewerVisibility(frameName)
	ensureCooldownViewerDb()
	local sanitized = addon.visibilityRuntime:GetCachedCooldownViewerVisibility(frameName)
	if not sanitized then return nil end
	local copy = {}
	for k, v in pairs(sanitized) do
		if v == true then copy[k] = true end
	end
	return copy
end

function addon.functions.SetCooldownViewerVisibility(frameName, key, shouldSelect)
	local db = ensureCooldownViewerDb()
	local current = sanitizeCooldownViewerConfig(db[frameName]) or {}
	if shouldSelect then
		current = normalizeCooldownViewerConfigValue(key, current)
	else
		current[key] = nil
	end
	if current and next(current) then
		db[frameName] = current
	else
		db[frameName] = nil
	end
	if addon.functions.EnsureCooldownViewerWatcher then addon.functions.EnsureCooldownViewerWatcher() end
	if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
end

local function scheduleCooldownViewerReapply()
	addon.variables = addon.variables or {}
	if addon.variables.cooldownViewerReapplyPending then return end
	if not C_Timer or not C_Timer.After then return end

	local attempts = (addon.variables.cooldownViewerRetryCount or 0) + 1
	addon.variables.cooldownViewerRetryCount = attempts
	if attempts > 10 then return end

	addon.variables.cooldownViewerReapplyPending = true
	C_Timer.After(1, function()
		addon.variables.cooldownViewerReapplyPending = nil
		if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
	end)
end

function addon.functions.ApplyCooldownViewerVisibility()
	addon.db = addon.db or {}
	addon.variables = addon.variables or {}
	local enabled = IsCooldownViewerEnabled()
	local missingFrame = false

	for _, frameName in ipairs(COOLDOWN_VIEWER_FRAMES) do
		local cfg = addon.visibilityRuntime:GetCachedCooldownViewerVisibility(frameName)
		if not enabled then cfg = nil end
		if not applyCooldownViewerMode(frameName, cfg) and cfg and next(cfg) then missingFrame = true end
	end

	if addon.functions.UpdateCooldownViewerCombatLocks then addon.functions.UpdateCooldownViewerCombatLocks() end

	if enabled and missingFrame then
		scheduleCooldownViewerReapply()
	elseif addon.variables then
		addon.variables.cooldownViewerRetryCount = nil
	end
	if addon.functions.EnsureCooldownViewerWatcher then addon.functions.EnsureCooldownViewerWatcher() end
end

local COOLDOWN_VIEWER_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"COOLDOWN_VIEWER_DATA_LOADED",
	"CVAR_UPDATE",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	"UPDATE_SHAPESHIFT_FORM",
	"PLAYER_FOCUS_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"GROUP_ROSTER_UPDATE",
	"ZONE_CHANGED_NEW_AREA",
	"PLAYER_DIFFICULTY_CHANGED",
	"INSTANCE_GROUP_SIZE_CHANGED",
	"UPDATE_INSTANCE_INFO",
	"UPDATE_BONUS_ACTIONBAR",
	"UPDATE_VEHICLE_ACTIONBAR",
	"UPDATE_OVERRIDE_ACTIONBAR",
	"UPDATE_POSSESS_BAR",
	"VEHICLE_UPDATE",
}

local COOLDOWN_VIEWER_UNIT_EVENTS = {
	"UNIT_ENTERING_VEHICLE",
	"UNIT_ENTERED_VEHICLE",
	"UNIT_EXITING_VEHICLE",
	"UNIT_EXITED_VEHICLE",
}

local function setCooldownViewerWatcherEnabled(watcher, enabled, wantsPlayerCasting)
	if not watcher then return end
	if enabled then
		if not watcher._eqolEventsRegistered then
			for _, event in ipairs(COOLDOWN_VIEWER_EVENTS) do
				watcher:RegisterEvent(event)
			end
			for _, event in ipairs(COOLDOWN_VIEWER_UNIT_EVENTS) do
				SafeRegisterUnitEvent(watcher, event, "player")
			end
			watcher._eqolEventsRegistered = true
		end
		addon.visibilityRuntime:SetPlayerCastingEventInterest(watcher, wantsPlayerCasting)
	else
		if not watcher._eqolEventsRegistered then return end
		watcher:UnregisterAllEvents()
		watcher._eqolEventsRegistered = false
		watcher._eqolPlayerCastingEventsRegistered = false
	end
end

local function EnsureCooldownViewerWatcher()
	addon.variables = addon.variables or {}
	local enable = HasCooldownViewerVisibilityConfig()
	local wantsPlayerCasting = enable and IsCooldownViewerEnabled() and addon.visibilityRuntime:CooldownViewerUsesPlayerCasting()
	local watcher = addon.variables.cooldownViewerWatcher

	if not watcher then
		if not enable then return false end
		EnsureSkyridingStateDriver()
		watcher = CreateFrame("Frame")
		watcher:SetScript("OnEvent", function(_, event, name)
			if event == "CVAR_UPDATE" and name ~= "cooldownViewerEnabled" then return end
			if addon.variables then
				addon.variables.cooldownViewerRetryCount = nil
				if event == "CVAR_UPDATE" and name == "cooldownViewerEnabled" then addon.variables.cooldownViewerEnabledDirty = true end
			end
			if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
		end)
		addon.variables.cooldownViewerWatcher = watcher
	end

	if not enable then
		setCooldownViewerWatcherEnabled(watcher, false)
		return false
	end

	EnsureSkyridingStateDriver()
	setCooldownViewerWatcherEnabled(watcher, true, wantsPlayerCasting)
	return true
end
addon.functions.EnsureCooldownViewerWatcher = EnsureCooldownViewerWatcher

local function EnsureCooldownViewerEditCallbacks()
	addon.variables = addon.variables or {}
	if addon.variables.cooldownViewerEditHooked then return end
	if not addon.EditMode or not addon.EditMode.lib or not addon.EditMode.lib.RegisterCallback then return end

	local owner = addon.variables.cooldownViewerEditOwner or {}
	addon.variables.cooldownViewerEditOwner = owner
	local function refreshEditModeFlag(active)
		addon.variables.cooldownViewerEditMode = active and true or false
		if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
	end

	addon.EditMode.lib:RegisterCallback("enter", function() refreshEditModeFlag(true) end, owner)
	addon.EditMode.lib:RegisterCallback("exit", function() refreshEditModeFlag(false) end, owner)

	addon.variables.cooldownViewerEditMode = addon.EditMode:IsInEditMode()
	addon.variables.cooldownViewerEditHooked = true
end
addon.functions.EnsureCooldownViewerEditCallbacks = EnsureCooldownViewerEditCallbacks

local function normalizeSpellActivationOverlayConfigValue(val, acc)
	if not SPELL_ACTIVATION_OVERLAY_VISIBILITY_KEYS[val] then return acc end
	acc = acc or {}
	acc[val] = true
	return acc
end

local function sanitizeSpellActivationOverlayConfig(cfg)
	if type(cfg) == "table" then
		local result
		for key, value in pairs(cfg) do
			if value == true then result = normalizeSpellActivationOverlayConfigValue(key, result) end
		end
		return result
	end
	if type(cfg) == "string" then return normalizeSpellActivationOverlayConfigValue(cfg, {}) end
	return nil
end

function addon.visibilityRuntime:GetCachedSpellActivationOverlayVisibility()
	addon.variables = addon.variables or {}
	local source = addon.db and addon.db.spellActivationOverlayVisibility
	local signature = self:GetConfigSignature(source, SPELL_ACTIVATION_OVERLAY_VISIBILITY_KEYS)
	local cached = addon.variables.spellActivationOverlayVisibilityConfigCache
	if cached and cached.source == source and cached.signature == signature then return cached.config end
	local sanitized = sanitizeSpellActivationOverlayConfig(source)
	addon.variables.spellActivationOverlayVisibilityConfigCache = { source = source, signature = signature, config = sanitized }
	return sanitized
end

function addon.functions.GetSpellActivationOverlayVisibility()
	local cfg = addon.visibilityRuntime:GetCachedSpellActivationOverlayVisibility()
	if not cfg then return nil end
	local copy = {}
	for key, value in pairs(cfg) do
		if value == true then copy[key] = true end
	end
	return copy
end

function addon.functions.SetSpellActivationOverlayVisibility(key, shouldSelect)
	addon.db = addon.db or {}
	local current = sanitizeSpellActivationOverlayConfig(addon.db.spellActivationOverlayVisibility) or {}
	if shouldSelect then
		current = normalizeSpellActivationOverlayConfigValue(key, current)
	else
		current[key] = nil
	end
	if current and next(current) then
		addon.db.spellActivationOverlayVisibility = current
	else
		addon.db.spellActivationOverlayVisibility = nil
	end
	if EnsureSpellActivationOverlayWatcher then EnsureSpellActivationOverlayWatcher() end
	if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
end

local function getSpellActivationOverlayAlphaValue(key, fallback)
	if not addon.db then return fallback end
	local value = clampVisibilityAlpha(addon.db[key])
	if value == nil then return fallback end
	return value
end

local function computeSpellActivationOverlayTargetAlpha(cfg, activeAlpha, hiddenAlpha)
	local mounted = IsPlayerMountedOrInVehicleUI()
	local isSkyriding = addon.variables and addon.variables.isPlayerSkyriding and true or false
	local isFlying = IsPlayerFlying()
	local hasFocus = UnitExists and UnitExists("focus") and true or false
	local hasTarget = UnitExists and UnitExists("target") and true or false
	local isCasting = cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] and IsPlayerCasting() or false
	local inInstance = IsInInstance and IsInInstance() and true or false

	local shouldShow = false
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED] and mounted then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED] and not mounted then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE] and isSkyriding then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE] and not isSkyriding then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE] and isFlying then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE] and not isFlying then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] and isCasting then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS] and hasFocus then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET] and hasTarget then shouldShow = true end
	if cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE] and inInstance then shouldShow = true end

	if shouldShow then return activeAlpha end
	return hiddenAlpha
end

local function applySpellActivationOverlayMode(cfg)
	local frame = _G[SPELL_ACTIVATION_OVERLAY_FRAME_NAME]
	if not frame then return false end
	addon.variables = addon.variables or {}
	local vars = addon.variables

	if not cfg or not next(cfg) then
		if vars.spellActivationOverlayApplied then
			local baseAlpha = vars.spellActivationOverlayBaseAlpha
			if type(baseAlpha) ~= "number" then baseAlpha = 1 end
			ApplyAlphaToRegion(frame, baseAlpha, false)
		end
		vars.spellActivationOverlayApplied = nil
		vars.spellActivationOverlayBaseAlpha = nil
		return true
	end

	if vars.spellActivationOverlayBaseAlpha == nil and frame.GetAlpha then
		local baseAlpha = frame:GetAlpha()
		if type(baseAlpha) == "number" then
			vars.spellActivationOverlayBaseAlpha = baseAlpha
		else
			vars.spellActivationOverlayBaseAlpha = 1
		end
	end

	local useCustomAlpha = addon.db and addon.db.spellActivationOverlayUseCustomAlpha == true
	local activeAlpha = 1
	local hiddenAlpha = 0
	if useCustomAlpha then
		activeAlpha = getSpellActivationOverlayAlphaValue("spellActivationOverlayActiveAlpha", 1)
		hiddenAlpha = getSpellActivationOverlayAlphaValue("spellActivationOverlayHiddenAlpha", 0)
	end

	local targetAlpha = computeSpellActivationOverlayTargetAlpha(cfg, activeAlpha, hiddenAlpha)
	ApplyAlphaToRegion(frame, targetAlpha, false)
	vars.spellActivationOverlayApplied = true
	return true
end

local function scheduleSpellActivationOverlayReapply()
	addon.variables = addon.variables or {}
	if addon.variables.spellActivationOverlayReapplyPending then return end
	if not C_Timer or not C_Timer.After then return end

	local attempts = (addon.variables.spellActivationOverlayRetryCount or 0) + 1
	addon.variables.spellActivationOverlayRetryCount = attempts
	if attempts > 10 then return end

	addon.variables.spellActivationOverlayReapplyPending = true
	C_Timer.After(1, function()
		addon.variables.spellActivationOverlayReapplyPending = nil
		if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
	end)
end

function addon.functions.ApplySpellActivationOverlayVisibility()
	addon.db = addon.db or {}
	addon.variables = addon.variables or {}

	local cfg = addon.visibilityRuntime:GetCachedSpellActivationOverlayVisibility()
	if cfg and (cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE] or cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE]) then EnsureSkyridingStateDriver() end
	local ok = applySpellActivationOverlayMode(cfg)

	if cfg and not ok then
		scheduleSpellActivationOverlayReapply()
	elseif addon.variables then
		addon.variables.spellActivationOverlayRetryCount = nil
	end
	if EnsureSpellActivationOverlayWatcher then EnsureSpellActivationOverlayWatcher() end
end

addon.visibilityRuntime.spellActivationOverlayEvents = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_FOCUS_CHANGED",
	"PLAYER_TARGET_CHANGED",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	"ZONE_CHANGED_NEW_AREA",
	"PLAYER_DIFFICULTY_CHANGED",
	"INSTANCE_GROUP_SIZE_CHANGED",
	"UPDATE_INSTANCE_INFO",
	"UPDATE_SHAPESHIFT_FORM",
	"UPDATE_BONUS_ACTIONBAR",
	"UPDATE_VEHICLE_ACTIONBAR",
	"UPDATE_OVERRIDE_ACTIONBAR",
	"UPDATE_POSSESS_BAR",
	"VEHICLE_UPDATE",
}

function addon.visibilityRuntime:SetSpellActivationOverlayWatcherEnabled(watcher, enabled, wantsPlayerCasting)
	if not watcher then return end
	if enabled then
		if not watcher._eqolEventsRegistered then
			for _, event in ipairs(self.spellActivationOverlayEvents) do
				watcher:RegisterEvent(event)
			end
			for _, event in ipairs(COOLDOWN_VIEWER_UNIT_EVENTS) do
				SafeRegisterUnitEvent(watcher, event, "player")
			end
			watcher._eqolEventsRegistered = true
		end
		addon.visibilityRuntime:SetPlayerCastingEventInterest(watcher, wantsPlayerCasting)
	else
		if not watcher._eqolEventsRegistered then return end
		watcher:UnregisterAllEvents()
		watcher._eqolEventsRegistered = false
		watcher._eqolPlayerCastingEventsRegistered = false
	end
end

EnsureSpellActivationOverlayWatcher = function()
	addon.variables = addon.variables or {}
	local cfg = addon.visibilityRuntime:GetCachedSpellActivationOverlayVisibility()
	local enable = cfg and next(cfg) ~= nil
	local watcher = addon.variables.spellActivationOverlayWatcher
	if not watcher then
		if not enable then return false end
		watcher = CreateFrame("Frame")
		watcher:SetScript("OnEvent", function()
			if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
		end)
		addon.variables.spellActivationOverlayWatcher = watcher
	end
	addon.visibilityRuntime:SetSpellActivationOverlayWatcherEnabled(watcher, enable, enable and cfg[COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING] == true)
	return enable
end
addon.functions.EnsureSpellActivationOverlayWatcher = EnsureSpellActivationOverlayWatcher

local hookedButtons = {}

-- Keep action bars visible while interacting with SpellFlyout
local EQOL_LastMouseoverBar
local EQOL_LastMouseoverVar

local function EQOL_ShouldKeepVisibleByFlyout() return _G.SpellFlyout and _G.SpellFlyout:IsShown() and MouseIsOver(_G.SpellFlyout) end
local ACTIONBAR_VISIBILITY_MOUSEOVER_ONLY = { MOUSEOVER = true }
local function IsActionBarMouseoverGroupEnabled() return addon.db and addon.db.actionBarMouseoverShowAll == true end

local function ShouldFadeActionBar(skipFade)
	if skipFade then return false end
	return not IsActionBarMouseoverGroupEnabled()
end

local function IsActionBarGroupHoverActive()
	local vars = addon.variables
	return vars and vars._eqolActionBarGroupHoverActive == true
end

local function UpdateActionBarGroupHoverState(frame, isEnter)
	if not IsActionBarMouseoverGroupEnabled() then return end
	addon.variables = addon.variables or {}
	local vars = addon.variables
	local hovered = vars._eqolActionBarHoverFrames
	if not hovered then
		hovered = {}
		vars._eqolActionBarHoverFrames = hovered
	end

	if isEnter then
		if frame then hovered[frame] = true end
		if vars._eqolActionBarGroupHoverActive == true then return end
		vars._eqolActionBarGroupHoverActive = true
		if addon.functions and addon.functions.RefreshAllActionBarVisibilityAlpha then addon.functions.RefreshAllActionBarVisibilityAlpha() end
		return
	end

	if frame then hovered[frame] = nil end
	if vars._eqolActionBarHoverUpdatePending then return end
	vars._eqolActionBarHoverUpdatePending = true
	RunNextFrame(function()
		local state = addon.variables
		if not state then return end
		state._eqolActionBarHoverUpdatePending = nil

		local active = EQOL_ShouldKeepVisibleByFlyout()
		local set = state._eqolActionBarHoverFrames
		if set then
			for target in pairs(set) do
				if target and target.IsShown and target:IsShown() and MouseIsOver(target) then
					active = true
					break
				else
					set[target] = nil
				end
			end
		end

		if state._eqolActionBarGroupHoverActive == active then return end
		state._eqolActionBarGroupHoverActive = active
		if addon.functions and addon.functions.RefreshAllActionBarVisibilityAlpha then addon.functions.RefreshAllActionBarVisibilityAlpha() end
	end)
end

local function ShouldShowActionBarOnMouseover(bar)
	if MouseIsOver(bar) or EQOL_ShouldKeepVisibleByFlyout() then return true end
	if IsActionBarMouseoverGroupEnabled() then return IsActionBarGroupHoverActive() end
	return false
end

local function GetActionBarVisibilityConfig(variable, incoming, persistLegacy)
	local source = incoming
	if source == nil and addon.db then source = addon.db[variable] end

	if not persistLegacy and incoming == nil then
		if type(source) == "table" then
			if
				source.MOUSEOVER == true
				or source.ALWAYS_IN_COMBAT == true
				or source.ALWAYS_OUT_OF_COMBAT == true
				or source.SKYRIDING_ACTIVE == true
				or source.SKYRIDING_INACTIVE == true
				or source.FLYING_ACTIVE == true
				or source.FLYING_INACTIVE == true
				or source.PLAYER_CASTING == true
				or source.PLAYER_MOUNTED == true
				or source.PLAYER_NOT_MOUNTED == true
				or source.PLAYER_HAS_FOCUS == true
				or source.PLAYER_HAS_TARGET == true
				or source.PLAYER_IN_GROUP == true
				or source.SHOW_IN_INSTANCE == true
				or source.ALWAYS_HIDDEN == true
			then
				return source
			end
			return nil
		end
		if source == true then return ACTIONBAR_VISIBILITY_MOUSEOVER_ONLY end
	end

	local config
	if type(source) == "table" then
		config = {
			MOUSEOVER = source.MOUSEOVER == true,
			ALWAYS_IN_COMBAT = source.ALWAYS_IN_COMBAT == true,
			ALWAYS_OUT_OF_COMBAT = source.ALWAYS_OUT_OF_COMBAT == true,
			SKYRIDING_ACTIVE = source.SKYRIDING_ACTIVE == true,
			SKYRIDING_INACTIVE = source.SKYRIDING_INACTIVE == true,
			FLYING_ACTIVE = source.FLYING_ACTIVE == true,
			FLYING_INACTIVE = source.FLYING_INACTIVE == true,
			PLAYER_CASTING = source.PLAYER_CASTING == true,
			PLAYER_MOUNTED = source.PLAYER_MOUNTED == true,
			PLAYER_NOT_MOUNTED = source.PLAYER_NOT_MOUNTED == true,
			PLAYER_HAS_FOCUS = source.PLAYER_HAS_FOCUS == true,
			PLAYER_HAS_TARGET = source.PLAYER_HAS_TARGET == true,
			PLAYER_IN_GROUP = source.PLAYER_IN_GROUP == true,
			SHOW_IN_INSTANCE = source.SHOW_IN_INSTANCE == true,
			ALWAYS_HIDDEN = source.ALWAYS_HIDDEN == true,
		}
	elseif source == true then
		config = {
			MOUSEOVER = true,
			ALWAYS_IN_COMBAT = false,
			ALWAYS_OUT_OF_COMBAT = false,
			SKYRIDING_ACTIVE = false,
			SKYRIDING_INACTIVE = false,
			FLYING_ACTIVE = false,
			FLYING_INACTIVE = false,
			PLAYER_CASTING = false,
			PLAYER_MOUNTED = false,
			PLAYER_NOT_MOUNTED = false,
			PLAYER_HAS_FOCUS = false,
			PLAYER_HAS_TARGET = false,
			PLAYER_IN_GROUP = false,
			SHOW_IN_INSTANCE = false,
			ALWAYS_HIDDEN = false,
		}
	elseif source == "hide" then
		config = {
			ALWAYS_HIDDEN = true,
		}
	else
		config = nil
	end

	if
		config
		and not (
			config.MOUSEOVER
			or config.ALWAYS_IN_COMBAT
			or config.ALWAYS_OUT_OF_COMBAT
			or config.SKYRIDING_ACTIVE
			or config.SKYRIDING_INACTIVE
			or config.FLYING_ACTIVE
			or config.FLYING_INACTIVE
			or config.PLAYER_CASTING
			or config.PLAYER_MOUNTED
			or config.PLAYER_NOT_MOUNTED
			or config.PLAYER_HAS_FOCUS
			or config.PLAYER_HAS_TARGET
			or config.PLAYER_IN_GROUP
			or config.SHOW_IN_INSTANCE
			or config.ALWAYS_HIDDEN
		)
	then
		config = nil
	end

	if persistLegacy and addon.db then
		if not config then
			addon.db[variable] = nil
		else
			local stored = {}
			if config.MOUSEOVER then stored.MOUSEOVER = true end
			if config.ALWAYS_IN_COMBAT then stored.ALWAYS_IN_COMBAT = true end
			if config.ALWAYS_OUT_OF_COMBAT then stored.ALWAYS_OUT_OF_COMBAT = true end
			if config.SKYRIDING_ACTIVE then stored.SKYRIDING_ACTIVE = true end
			if config.SKYRIDING_INACTIVE then stored.SKYRIDING_INACTIVE = true end
			if config.FLYING_ACTIVE then stored.FLYING_ACTIVE = true end
			if config.FLYING_INACTIVE then stored.FLYING_INACTIVE = true end
			if config.PLAYER_CASTING then stored.PLAYER_CASTING = true end
			if config.PLAYER_MOUNTED then stored.PLAYER_MOUNTED = true end
			if config.PLAYER_NOT_MOUNTED then stored.PLAYER_NOT_MOUNTED = true end
			if config.PLAYER_HAS_FOCUS then stored.PLAYER_HAS_FOCUS = true end
			if config.PLAYER_HAS_TARGET then stored.PLAYER_HAS_TARGET = true end
			if config.PLAYER_IN_GROUP then stored.PLAYER_IN_GROUP = true end
			if config.SHOW_IN_INSTANCE then stored.SHOW_IN_INSTANCE = true end
			if config.ALWAYS_HIDDEN then stored.ALWAYS_HIDDEN = true end
			addon.db[variable] = stored
		end
	end

	return config
end

local function NormalizeActionBarVisibilityConfig(variable, incoming) return GetActionBarVisibilityConfig(variable, incoming, true) end
addon.functions.NormalizeActionBarVisibilityConfig = NormalizeActionBarVisibilityConfig

local function GetActionBarVisibilityContext(combatOverride)
	local inCombat = combatOverride
	if inCombat == nil then
		if InCombatLockdown and InCombatLockdown() then
			inCombat = true
		elseif UnitAffectingCombat then
			inCombat = UnitAffectingCombat("player") and true or false
		else
			inCombat = false
		end
	end

	return {
		inCombat = inCombat,
		hasFocus = UnitExists and UnitExists("focus") and true or false,
		hasTarget = UnitExists and UnitExists("target") and true or false,
		inGroup = IsInGroup and IsInGroup() and true or false,
		mounted = IsPlayerMounted(),
		isFlying = IsPlayerFlying(),
		isCasting = IsPlayerCasting(),
		inInstance = IsInInstance and IsInInstance() and true or false,
		isSkyriding = not IsPlayerDeadOrGhost() and addon.variables and addon.variables.isPlayerSkyriding,
	}
end

local function ActionBarShouldForceShowByConfig(config, context, combatOverride)
	if not config then return false end
	if config.ALWAYS_HIDDEN then return false end
	local ctx = context or GetActionBarVisibilityContext(combatOverride)
	if config.SKYRIDING_ACTIVE and ctx.isSkyriding then return true end
	if config.FLYING_ACTIVE and ctx.isFlying then return true end
	if config.ALWAYS_IN_COMBAT and ctx.inCombat then return true end
	if config.ALWAYS_OUT_OF_COMBAT and not ctx.inCombat then return true end
	if config.PLAYER_CASTING and ctx.isCasting then return true end
	if config.PLAYER_MOUNTED and ctx.mounted then return true end
	if config.PLAYER_NOT_MOUNTED and not ctx.mounted then return true end
	if config.PLAYER_HAS_FOCUS and ctx.hasFocus then return true end
	if config.PLAYER_HAS_TARGET and ctx.hasTarget then return true end
	if config.PLAYER_IN_GROUP and ctx.inGroup then return true end
	if config.SHOW_IN_INSTANCE and ctx.inInstance then return true end
	return false
end

local function IsActionBarMouseoverEnabled(variable)
	local cfg = GetActionBarVisibilityConfig(variable)
	return cfg and cfg.MOUSEOVER == true
end

local function HasActionBarVisibilityConfig()
	local list = addon.variables and addon.variables.actionBarNames
	if not list then return false end
	for _, info in ipairs(list) do
		if info.var and GetActionBarVisibilityConfig(info.var) then return true end
	end
	return false
end

local function GetActionBarFadeStrength()
	if not addon.db then return 1 end
	local strength = tonumber(addon.db.actionBarFadeStrength)
	if not strength then strength = 1 end
	if strength < 0 then strength = 0 end
	if strength > 1 then strength = 1 end
	return strength
end
addon.functions.GetActionBarFadeStrength = GetActionBarFadeStrength

local function GetActionBarFadedAlpha() return 1 - GetActionBarFadeStrength() end

local function GetActionBarBaseAlpha(cfg, fadeAlpha)
	if type(fadeAlpha) ~= "number" then fadeAlpha = GetActionBarFadedAlpha() end
	return fadeAlpha
end

local function GetFrameFadeStrength()
	if not addon.db then return 1 end
	local strength = tonumber(addon.db.frameVisibilityFadeStrength)
	if not strength then strength = 1 end
	if strength < 0 then strength = 0 end
	if strength > 1 then strength = 1 end
	return strength
end
addon.functions.GetFrameFadeStrength = GetFrameFadeStrength

local function GetFrameFadedAlpha() return 1 - GetFrameFadeStrength() end
addon.functions.GetFrameFadedAlpha = GetFrameFadedAlpha

local function GetCooldownViewerFadeStrength()
	if not addon.db then return 1 end
	local strength = tonumber(addon.db.cooldownViewerFadeStrength)
	if not strength then strength = 1 end
	if strength < 0 then strength = 0 end
	if strength > 1 then strength = 1 end
	return strength
end
addon.functions.GetCooldownViewerFadeStrength = GetCooldownViewerFadeStrength

local function GetCooldownViewerFadedAlpha() return 1 - GetCooldownViewerFadeStrength() end
addon.functions.GetCooldownViewerFadedAlpha = GetCooldownViewerFadedAlpha

local function ApplyActionBarAlpha(bar, variable, config, combatOverride, skipFade, context)
	if not bar then return end
	if addon.variables and addon.variables.actionBarShowGrid then
		ApplyAlphaToRegion(bar, 1, false)
		return
	end
	local cfg
	if type(config) == "table" then
		cfg = NormalizeActionBarVisibilityConfig(variable, config)
	elseif config ~= nil then
		cfg = NormalizeActionBarVisibilityConfig(variable, config)
	else
		cfg = GetActionBarVisibilityConfig(variable)
	end
	if not cfg then return end
	local useFade = ShouldFadeActionBar(skipFade)
	if cfg.ALWAYS_HIDDEN then
		ApplyAlphaToRegion(bar, 0, useFade)
		return
	end
	local ctx = context or GetActionBarVisibilityContext(combatOverride)
	local fadedAlpha = GetActionBarFadedAlpha()
	local baseAlpha = GetActionBarBaseAlpha(cfg, fadedAlpha)
	local hasShowRules = cfg.MOUSEOVER
		or cfg.ALWAYS_IN_COMBAT
		or cfg.ALWAYS_OUT_OF_COMBAT
		or cfg.SKYRIDING_ACTIVE
		or cfg.FLYING_ACTIVE
		or cfg.PLAYER_CASTING
		or cfg.PLAYER_MOUNTED
		or cfg.PLAYER_NOT_MOUNTED
		or cfg.PLAYER_HAS_FOCUS
		or cfg.PLAYER_HAS_TARGET
		or cfg.PLAYER_IN_GROUP
		or cfg.SHOW_IN_INSTANCE

	if cfg.SKYRIDING_INACTIVE then
		if ctx.isSkyriding then
			ApplyAlphaToRegion(bar, baseAlpha, useFade)
			return
		elseif not hasShowRules then
			ApplyAlphaToRegion(bar, 1, useFade)
			return
		end
	end
	if cfg.FLYING_INACTIVE then
		if ctx.isFlying then
			ApplyAlphaToRegion(bar, baseAlpha, useFade)
			return
		elseif not hasShowRules then
			ApplyAlphaToRegion(bar, 1, useFade)
			return
		end
	end

	if ActionBarShouldForceShowByConfig(cfg, ctx, combatOverride) then
		ApplyAlphaToRegion(bar, 1, useFade)
		return
	end
	if cfg.MOUSEOVER then
		if ShouldShowActionBarOnMouseover(bar) then
			ApplyAlphaToRegion(bar, 1, useFade)
		else
			ApplyAlphaToRegion(bar, baseAlpha, useFade)
		end
	else
		ApplyAlphaToRegion(bar, baseAlpha, useFade)
	end
end

local function EQOL_HideBarIfNotHovered(bar, variable)
	local cfg = GetActionBarVisibilityConfig(variable)
	if not cfg then return end
	RunNextFrame(function()
		if addon.variables and addon.variables.actionBarShowGrid then
			ApplyAlphaToRegion(bar, 1, false)
			return
		end
		local current = GetActionBarVisibilityConfig(variable)
		if not current then return end
		local useFade = ShouldFadeActionBar()
		local context = GetActionBarVisibilityContext()
		local fadedAlpha = GetActionBarFadedAlpha()
		local baseAlpha = GetActionBarBaseAlpha(current, fadedAlpha)
		if current.ALWAYS_HIDDEN then
			ApplyAlphaToRegion(bar, 0, useFade)
			return
		end
		if ActionBarShouldForceShowByConfig(current, context) then
			ApplyAlphaToRegion(bar, 1, useFade)
			return
		end
		if not current.MOUSEOVER then
			ApplyAlphaToRegion(bar, baseAlpha, useFade)
			return
		end
		-- Only hide if neither the bar nor other hover targets are under the mouse
		if not ShouldShowActionBarOnMouseover(bar) then
			ApplyAlphaToRegion(bar, baseAlpha, useFade)
		else
			ApplyAlphaToRegion(bar, 1, useFade)
		end
	end)
end
local function EQOL_HookSpellFlyout()
	local flyout = _G.SpellFlyout
	if not flyout or flyout.EQOL_MouseoverHooked then return end

	flyout:HookScript("OnEnter", function()
		if IsActionBarMouseoverGroupEnabled() then
			UpdateActionBarGroupHoverState(flyout, true)
			return
		end
		if EQOL_LastMouseoverBar and IsActionBarMouseoverEnabled(EQOL_LastMouseoverVar) then EQOL_LastMouseoverBar:SetAlpha(1) end
	end)

	flyout:HookScript("OnLeave", function()
		if IsActionBarMouseoverGroupEnabled() then
			UpdateActionBarGroupHoverState(flyout, false)
			return
		end
		if EQOL_LastMouseoverBar and IsActionBarMouseoverEnabled(EQOL_LastMouseoverVar) then EQOL_HideBarIfNotHovered(EQOL_LastMouseoverBar, EQOL_LastMouseoverVar) end
	end)

	flyout:HookScript("OnHide", function()
		if IsActionBarMouseoverGroupEnabled() then
			UpdateActionBarGroupHoverState(flyout, false)
			return
		end
		if EQOL_LastMouseoverBar and IsActionBarMouseoverEnabled(EQOL_LastMouseoverVar) then EQOL_HideBarIfNotHovered(EQOL_LastMouseoverBar, EQOL_LastMouseoverVar) end
	end)

	flyout.EQOL_MouseoverHooked = true
end
-- Action Bars
local EnsureActionBarVisibilityWatcher
local function UpdateActionBarMouseover(barName, config, variable)
	local bar = ResolveActionBarFrame(barName)
	if not bar then return end

	local btnPrefix
	if barName == "MainMenuBar" or barName == "MainActionBar" then
		-- we have to change the Vehice Leave Button behaviour
		local leave = _G.MainMenuBarVehicleLeaveButton
		if leave then
			leave:SetIgnoreParentAlpha(true)
			leave:SetAlpha(1)
		end
		btnPrefix = "ActionButton"
	elseif barName == "PetActionBar" or barName == "PetActionBarFrame" then
		btnPrefix = "PetActionButton"
	elseif barName == "StanceBar" or barName == "StanceBarFrame" then
		btnPrefix = "StanceButton"
	else
		btnPrefix = barName .. "Button"
	end

	local cfg = NormalizeActionBarVisibilityConfig(variable, config)

	if not cfg then
		bar:SetScript("OnEnter", nil)
		bar:SetScript("OnLeave", nil)
		bar:SetAlpha(1)
		if EQOL_LastMouseoverVar == variable then
			if EQOL_LastMouseoverBar == bar then EQOL_LastMouseoverBar = nil end
			EQOL_LastMouseoverVar = nil
		end
		if EnsureActionBarVisibilityWatcher then EnsureActionBarVisibilityWatcher() end
		return
	end

	if cfg.MOUSEOVER then
		bar:SetScript("OnEnter", function()
			local current = GetActionBarVisibilityConfig(variable)
			if not current or not current.MOUSEOVER then return end
			if IsActionBarMouseoverGroupEnabled() then
				UpdateActionBarGroupHoverState(bar, true)
			else
				bar:SetAlpha(1)
			end
			EQOL_LastMouseoverBar = bar
			EQOL_LastMouseoverVar = variable
		end)
		bar:SetScript("OnLeave", function()
			if IsActionBarMouseoverGroupEnabled() then
				UpdateActionBarGroupHoverState(bar, false)
			else
				EQOL_HideBarIfNotHovered(bar, variable)
			end
		end)
	else
		bar:SetScript("OnEnter", nil)
		bar:SetScript("OnLeave", nil)
	end

	local function handleButtonEnter(self)
		local current = GetActionBarVisibilityConfig(variable)
		if not current then return end
		if current.MOUSEOVER then
			if IsActionBarMouseoverGroupEnabled() then
				UpdateActionBarGroupHoverState(self, true)
			else
				bar:SetAlpha(1)
			end
			EQOL_LastMouseoverBar = bar
			EQOL_LastMouseoverVar = variable
		elseif ActionBarShouldForceShowByConfig(current) then
			bar:SetAlpha(1)
		end
	end

	local function handleButtonLeave(self)
		local current = GetActionBarVisibilityConfig(variable)
		if not current then return end
		if current.MOUSEOVER then
			if IsActionBarMouseoverGroupEnabled() then
				UpdateActionBarGroupHoverState(self, false)
			else
				EQOL_HideBarIfNotHovered(bar, variable)
			end
			return
		end
		ApplyActionBarAlpha(bar, variable, current)
	end

	for i = 1, 12 do
		local button = _G[btnPrefix .. i]
		if button and not hookedButtons[button] then
			if button.OnEnter then
				button:HookScript("OnEnter", handleButtonEnter)
				hookedButtons[button] = true
			else
				button:SetScript("OnEnter", handleButtonEnter)
			end
			if button.OnLeave then
				button:HookScript("OnLeave", handleButtonLeave)
			else
				button:EnableMouse(true)
				button:SetScript("OnLeave", function(self)
					handleButtonLeave(self)
					GameTooltip:Hide()
				end)
			end
			if not hookedButtons[button] then GameTooltipActionButton(button) end
		end
	end

	if cfg.MOUSEOVER then RunNextFrame(EQOL_HookSpellFlyout) end

	ApplyActionBarAlpha(bar, variable, cfg)
	if EnsureActionBarVisibilityWatcher then EnsureActionBarVisibilityWatcher() end
end
addon.functions.UpdateActionBarMouseover = UpdateActionBarMouseover

local function EnsureAssistedCombatFrameHidden(button)
	if not addon.db then return end
	local frame = button and button.AssistedCombatRotationFrame
	if not frame then return end

	if not frame.EQOL_AssistedHideHooked then
		frame.EQOL_AssistedHideHooked = true
		frame:HookScript("OnShow", function(self)
			if addon.db and addon.db.actionBarHideAssistedRotation then
				self:SetAlpha(0)
			elseif self:GetAlpha() ~= 1 then
				self:SetAlpha(1)
			end
		end)
	end

	if addon.db.actionBarHideAssistedRotation then frame:SetAlpha(0) end
end

local function UpdateAssistedCombatFrameHiding()
	addon.variables = addon.variables or {}
	local enabled = addon.db and addon.db.actionBarHideAssistedRotation

	if enabled then
		if not addon.variables.assistedCombatCallbackOwner then
			addon.variables.assistedCombatCallbackOwner = {}
			EventRegistry:RegisterCallback("ActionButton.OnAssistedCombatRotationFrameChanged", function(_, button, added)
				if not addon.db or not addon.db.actionBarHideAssistedRotation then return end
				if added then EnsureAssistedCombatFrameHidden(button) end
			end, addon.variables.assistedCombatCallbackOwner)
		end
		ForEachActionButton(function(button) EnsureAssistedCombatFrameHidden(button) end)
	else
		if addon.variables.assistedCombatCallbackOwner then
			EventRegistry:UnregisterCallback("ActionButton.OnAssistedCombatRotationFrameChanged", addon.variables.assistedCombatCallbackOwner)
			addon.variables.assistedCombatCallbackOwner = nil
		end
	end
end
addon.functions.UpdateAssistedCombatFrameHiding = UpdateAssistedCombatFrameHiding

local function ApplyExtraActionArtworkSetting()
	if not addon.db then return end

	local shouldHide = addon.db.hideExtraActionArtwork == true
	addon.variables = addon.variables or {}
	local applied = addon.variables.extraActionArtworkApplied == true

	-- Only act when we need to apply or explicitly undo our own change.
	if InCombatLockdown and InCombatLockdown() and (shouldHide or applied) then
		addon.variables.pendingExtraActionArtwork = true
		return
	end
	if not shouldHide and not applied then
		addon.variables.pendingExtraActionArtwork = nil
		return
	end

	local extraActionButton = _G.ExtraActionButton1
	local extraStyle = extraActionButton and extraActionButton.style
	if extraStyle then
		if shouldHide then
			extraStyle:SetAlpha(0)
			extraStyle:Hide()
		else
			extraStyle:SetAlpha(1)
			extraStyle:Show()
		end
	end

	local zoneAbilityFrame = _G.ZoneAbilityFrame
	local zoneStyle = zoneAbilityFrame and zoneAbilityFrame.Style
	if zoneStyle then
		if shouldHide then
			zoneStyle:SetAlpha(0)
			zoneStyle:Hide()
		else
			zoneStyle:SetAlpha(1)
			zoneStyle:Show()
		end
	end

	local extraActionBarFrame = _G.ExtraActionBarFrame
	if extraActionBarFrame and extraActionBarFrame.EnableMouse then extraActionBarFrame:EnableMouse(not shouldHide) end

	addon.variables.extraActionArtworkApplied = shouldHide
	addon.variables.pendingExtraActionArtwork = nil
end
addon.functions.ApplyExtraActionArtworkSetting = ApplyExtraActionArtworkSetting

local function ApplyActionBarVisibilityAlpha(skipFade, event)
	if addon.variables then
		if not IsActionBarMouseoverGroupEnabled() then
			addon.variables._eqolActionBarGroupHoverActive = nil
			addon.variables._eqolActionBarHoverFrames = nil
			addon.variables._eqolActionBarHoverUpdatePending = nil
		elseif addon.variables._eqolActionBarGroupHoverActive == nil then
			addon.variables._eqolActionBarGroupHoverActive = EQOL_ShouldKeepVisibleByFlyout() and true or false
		end
	end
	local combatOverride
	if event == "PLAYER_REGEN_DISABLED" then
		combatOverride = true
	elseif event == "PLAYER_REGEN_ENABLED" then
		combatOverride = false
	end
	local context = GetActionBarVisibilityContext(combatOverride)
	for _, info in ipairs(addon.variables.actionBarNames or {}) do
		local bar = ResolveActionBarFrame(info.name)
		if bar then ApplyActionBarAlpha(bar, info.var, nil, combatOverride, skipFade, context) end
	end
end
local function RefreshAllActionBarVisibilityAlpha(skipFade, event)
	if type(skipFade) == "string" and event == nil then
		event = skipFade
		skipFade = nil
	end
	addon.variables = addon.variables or {}
	local vars = addon.variables
	if EnsureActionBarVisibilityWatcher and not EnsureActionBarVisibilityWatcher() then
		vars._eqolActionBarRefreshSkipFade = nil
		vars._eqolActionBarRefreshEvent = nil
		vars._eqolActionBarRefreshPending = nil
		return
	end
	if skipFade then vars._eqolActionBarRefreshSkipFade = true end
	if event then vars._eqolActionBarRefreshEvent = event end
	if vars._eqolActionBarRefreshPending then return end
	vars._eqolActionBarRefreshPending = true
	RunNextFrame(function()
		local state = addon.variables
		if not state then return end
		local pendingSkipFade = state._eqolActionBarRefreshSkipFade
		local pendingEvent = state._eqolActionBarRefreshEvent
		state._eqolActionBarRefreshSkipFade = nil
		state._eqolActionBarRefreshEvent = nil
		state._eqolActionBarRefreshPending = nil
		ApplyActionBarVisibilityAlpha(pendingSkipFade, pendingEvent)
	end)
end
addon.functions.RefreshAllActionBarVisibilityAlpha = RefreshAllActionBarVisibilityAlpha
addon.functions.RequestActionBarRefresh = RefreshAllActionBarVisibilityAlpha

EnsureSkyridingStateDriver = function()
	addon.variables = addon.variables or {}
	if addon.variables.skyridingDriver then return end
	local driver = CreateFrame("Frame")
	driver:Hide()
	local function refreshSkyridingDependents()
		UpdateFrameVisibilityContext()
		RefreshAllFrameVisibilities()
		RefreshAllActionBarVisibilityAlpha()
		if addon.functions and addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
		if addon.functions and addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
	end
	driver:SetScript("OnShow", function()
		addon.variables.isPlayerSkyriding = true
		refreshSkyridingDependents()
	end)
	driver:SetScript("OnHide", function()
		addon.variables.isPlayerSkyriding = false
		refreshSkyridingDependents()
	end)
	local expr
	if addon.variables.unitClass == "DRUID" then
		local clauses = { "[nodead,advflyable,flyable,mounted,flying] show" }
		if GetDruidTravelStanceIndexes then
			for _, idx in ipairs(GetDruidTravelStanceIndexes()) do
				clauses[#clauses + 1] = ("[nodead,advflyable,flyable,stance:%d,flying] show"):format(idx)
			end
		end
		clauses[#clauses + 1] = "hide"
		expr = table.concat(clauses, "; ")
	else
		expr = "[nodead,advflyable,flyable,mounted,flying] show; hide"
	end
	local function registerDriver()
		if addon.variables.skyridingDriverRegistered then return end
		if RegisterStateDriver then
			RegisterStateDriver(driver, "visibility", expr)
			addon.variables.skyridingDriverRegistered = true
			addon.variables.isPlayerSkyriding = driver:IsShown()
		end
	end
	if InCombatLockdown and InCombatLockdown() then
		addon.variables.pendingSkyridingDriverRegister = registerDriver
		local watcher = addon.variables.skyridingDriverWatcher
		if not watcher then
			watcher = CreateFrame("Frame")
			watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
			watcher:SetScript("OnEvent", function(self)
				if InCombatLockdown and InCombatLockdown() then return end
				local cb = addon.variables and addon.variables.pendingSkyridingDriverRegister
				addon.variables.pendingSkyridingDriverRegister = nil
				if cb then cb() end
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				addon.variables.skyridingDriverWatcher = nil
			end)
			addon.variables.skyridingDriverWatcher = watcher
		end
	else
		registerDriver()
	end
	addon.variables.skyridingDriver = driver
end

local ACTIONBAR_VISIBILITY_BASE_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"ACTIONBAR_SHOWGRID",
	"ACTIONBAR_HIDEGRID",
}

local function setActionBarVisibilityWatcherEnabled(watcher, enabled)
	if not watcher then return end
	if enabled then
		local flags = {
			combat = false,
			focus = false,
			target = false,
			group = false,
			casting = false,
			mountState = false,
			skyriding = false,
			instance = false,
		}
		local list = addon.variables and addon.variables.actionBarNames
		if list then
			for _, info in ipairs(list) do
				local cfg = info.var and GetActionBarVisibilityConfig(info.var)
				if cfg then
					if cfg.ALWAYS_IN_COMBAT or cfg.ALWAYS_OUT_OF_COMBAT then flags.combat = true end
					if cfg.PLAYER_HAS_FOCUS then flags.focus = true end
					if cfg.PLAYER_HAS_TARGET then flags.target = true end
					if cfg.PLAYER_IN_GROUP then flags.group = true end
					if cfg.PLAYER_CASTING then flags.casting = true end
					if cfg.SHOW_IN_INSTANCE then flags.instance = true end
					if cfg.PLAYER_MOUNTED or cfg.PLAYER_NOT_MOUNTED or cfg.FLYING_ACTIVE or cfg.FLYING_INACTIVE or cfg.SKYRIDING_ACTIVE or cfg.SKYRIDING_INACTIVE then
						flags.mountState = true
					end
					if cfg.SKYRIDING_ACTIVE or cfg.SKYRIDING_INACTIVE then flags.skyriding = true end
					if flags.combat and flags.focus and flags.target and flags.group and flags.casting and flags.mountState and flags.skyriding and flags.instance then break end
				end
			end
		end
		local signature = table.concat({
			flags.combat and "1" or "0",
			flags.focus and "1" or "0",
			flags.target and "1" or "0",
			flags.group and "1" or "0",
			flags.casting and "1" or "0",
			flags.mountState and "1" or "0",
			flags.skyriding and "1" or "0",
			flags.instance and "1" or "0",
		}, ":")
		if watcher._eqolEventsRegistered and watcher._eqolEventSignature == signature then return end
		watcher._eqolWantsSkyriding = flags.skyriding == true
		if watcher._eqolWantsSkyriding then EnsureSkyridingStateDriver() end
		watcher:UnregisterAllEvents()
		for _, event in ipairs(ACTIONBAR_VISIBILITY_BASE_EVENTS) do
			watcher:RegisterEvent(event)
		end
		if flags.combat then
			watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
			watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		if flags.mountState then
			watcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
			watcher:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		end
		if flags.group then watcher:RegisterEvent("GROUP_ROSTER_UPDATE") end
		if flags.focus then watcher:RegisterEvent("PLAYER_FOCUS_CHANGED") end
		if flags.target then watcher:RegisterEvent("PLAYER_TARGET_CHANGED") end
		if flags.instance then
			watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			watcher:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
			watcher:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
			watcher:RegisterEvent("UPDATE_INSTANCE_INFO")
		end
		if flags.casting then
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_START", "player")
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_STOP", "player")
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_FAILED", "player")
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_INTERRUPTED", "player")
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_CHANNEL_START", "player")
			SafeRegisterUnitEvent(watcher, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
		end
		watcher._eqolEventsRegistered = true
		watcher._eqolEventSignature = signature
	else
		if not watcher._eqolEventsRegistered then return end
		watcher:UnregisterAllEvents()
		watcher._eqolEventsRegistered = false
		watcher._eqolEventSignature = nil
		watcher._eqolWantsSkyriding = nil
	end
end

EnsureActionBarVisibilityWatcher = function()
	addon.variables = addon.variables or {}
	local enable = HasActionBarVisibilityConfig()
	local watcher = addon.variables.actionBarVisibilityWatcher
	if not watcher then
		if not enable then
			addon.variables.actionBarShowGrid = nil
			addon.variables._eqolActionBarGroupHoverActive = nil
			addon.variables._eqolActionBarHoverFrames = nil
			addon.variables._eqolActionBarHoverUpdatePending = nil
			return false
		end
		watcher = CreateFrame("Frame")
		watcher:SetScript("OnEvent", function(_, event)
			if event == "ACTIONBAR_SHOWGRID" then
				addon.variables = addon.variables or {}
				addon.variables.actionBarShowGrid = true
				RefreshAllActionBarVisibilityAlpha(true, event)
				return
			end
			if event == "ACTIONBAR_HIDEGRID" then
				if addon.variables then addon.variables.actionBarShowGrid = nil end
				RefreshAllActionBarVisibilityAlpha(true, event)
				return
			end
			RefreshAllActionBarVisibilityAlpha(nil, event)
		end)
		addon.variables.actionBarVisibilityWatcher = watcher
	end

	if not enable then
		setActionBarVisibilityWatcherEnabled(watcher, false)
		addon.variables.actionBarShowGrid = nil
		addon.variables._eqolActionBarGroupHoverActive = nil
		addon.variables._eqolActionBarHoverFrames = nil
		addon.variables._eqolActionBarHoverUpdatePending = nil
		return false
	end

	setActionBarVisibilityWatcherEnabled(watcher, true)
	return true
end
addon.functions.UpdateActionBarVisibilityWatcher = EnsureActionBarVisibilityWatcher

local CHAT_BUBBLE_FONT = {
	defaultSize = 13,
	min = 1,
	max = 36,
}

function addon.functions.ApplyChatBubbleFontSize(size)
	local desired = tonumber(size) or (addon.db and addon.db["chatBubbleFontSize"]) or CHAT_BUBBLE_FONT.defaultSize
	if desired < CHAT_BUBBLE_FONT.min then desired = CHAT_BUBBLE_FONT.min end
	if desired > CHAT_BUBBLE_FONT.max then desired = CHAT_BUBBLE_FONT.max end

	if ChatBubbleFont then
		addon.variables = addon.variables or {}
		if not addon.variables.defaultChatBubbleFont then
			local defaultFont, defaultSize, defaultFlags = ChatBubbleFont:GetFont()
			addon.variables.defaultChatBubbleFont = {
				font = defaultFont or STANDARD_TEXT_FONT,
				size = defaultSize or CHAT_BUBBLE_FONT.defaultSize,
				flags = defaultFlags or "",
			}
		end

		local override = addon.db and addon.db["chatBubbleFontOverride"]
		if override then
			local fontInfo = addon.variables.defaultChatBubbleFont or {}
			local font = STANDARD_TEXT_FONT or fontInfo.font
			local flags = fontInfo.flags or ""
			ChatBubbleFont:SetFont(font, desired, flags)
		else
			local defaults = addon.variables.defaultChatBubbleFont
				if defaults and defaults.font then
					ChatBubbleFont:SetFont(defaults.font, defaults.size, defaults.flags)
				elseif STANDARD_TEXT_FONT then
					ChatBubbleFont:SetFont(STANDARD_TEXT_FONT, CHAT_BUBBLE_FONT.defaultSize, "")
				end
			end
		end

	return desired
end

-- New modular Unit Frames UI builder
-- New modular Vendor & Economy UI builder

local function setCVarValue(cvarKey, newValue)
	if newValue == nil then return end

	newValue = tostring(newValue)
	local currentValue = C_CVar.GetCVar(cvarKey)
	if currentValue ~= nil then currentValue = tostring(currentValue) end

	if currentValue == newValue then return end

	C_CVar.SetCVar(cvarKey, newValue)
end
addon.functions.setCVarValue = setCVarValue

-- removed: addPartyFrame (party settings relocated to Social/UI sections)

local function initActionBars()
	local globalFontKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or addon.variables.defaultFont
	local globalFontStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
	addon.functions.InitDBValue("globalFontFace", addon.variables.defaultFont)
	addon.functions.InitDBValue("globalFontStyle", "OUTLINE")
	if addon.DurationText and addon.DurationText.InitDB then addon.DurationText:InitDB() end
	addon.functions.InitDBValue("actionBarAnchorEnabled", false)
	addon.functions.InitDBValue("actionBarFadeStrength", 1)
	addon.functions.InitDBValue("actionBarFullRangeColoring", false)
	addon.functions.InitDBValue("actionBarFullRangeColor", { r = 1, g = 0.1, b = 0.1, a = 0.45 })
	if type(addon.db.actionBarFullRangeColor) == "table" and addon.db.actionBarFullRangeColor.a == nil then addon.db.actionBarFullRangeColor.a = 0.45 end
	addon.functions.InitDBValue("actionBarHideBorders", false)
	addon.functions.InitDBValue("actionBarHideBordersAuto", false)
	addon.functions.InitDBValue("actionBarBorderStyle", "DEFAULT")
	addon.functions.InitDBValue("actionBarBorderEdgeSize", 16)
	addon.functions.InitDBValue("actionBarBorderPadding", 0)
	addon.functions.InitDBValue("actionBarBorderColoring", false)
	if addon.db.actionBarBorderColorMode == nil then addon.db.actionBarBorderColorMode = addon.db.actionBarBorderColoring and "CUSTOM" or "DEFAULT" end
	addon.functions.InitDBValue("actionBarBorderColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("actionBarHideAssistedRotation", false)
	addon.functions.InitDBValue("hideExtraActionArtwork", false)
	addon.functions.InitDBValue("hideMacroNames", false)
	addon.functions.InitDBValue("actionBarMacroFontOverride", false)
	addon.functions.InitDBValue("actionBarHotkeyFontOverride", false)
	addon.functions.InitDBValue("actionBarMacroFontFace", globalFontKey)
	addon.functions.InitDBValue("actionBarMacroFontSize", 12)
	addon.functions.InitDBValue("actionBarMacroFontOutline", globalFontStyleKey)
	addon.functions.InitDBValue("actionBarMacroFontColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("actionBarHotkeyFontFace", globalFontKey)
	addon.functions.InitDBValue("actionBarHotkeyFontSize", 12)
	addon.functions.InitDBValue("actionBarHotkeyFontOutline", globalFontStyleKey)
	addon.functions.InitDBValue("actionBarHotkeyFontColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("actionBarHotkeyAnchor", "TOPRIGHT")
	addon.functions.InitDBValue("actionBarHotkeyOffsetX", -2)
	addon.functions.InitDBValue("actionBarHotkeyOffsetY", -3)
	addon.functions.InitDBValue("actionBarCountFontOverride", false)
	addon.functions.InitDBValue("actionBarCountFontFace", globalFontKey)
	addon.functions.InitDBValue("actionBarCountFontSize", 12)
	addon.functions.InitDBValue("actionBarCountFontOutline", globalFontStyleKey)
	addon.functions.InitDBValue("actionBarCountFontColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("actionBarCountAnchor", "BOTTOMRIGHT")
	addon.functions.InitDBValue("actionBarCountOffsetX", -2)
	addon.functions.InitDBValue("actionBarCountOffsetY", 2)
	addon.functions.InitDBValue("actionBarShortHotkeys", false)
	addon.functions.InitDBValue("actionBarHiddenHotkeys", {})
	if type(addon.db.actionBarHiddenHotkeys) ~= "table" then addon.db.actionBarHiddenHotkeys = {} end
	local normalizeFontSize = ActionBarLabels and ActionBarLabels.NormalizeFontSize
	local function clampFontSize(value)
		if normalizeFontSize then return normalizeFontSize(value, 6, 32) end
		local num = tonumber(value) or 6
		if num < 6 then num = 6 end
		if num > 32 then num = 32 end
		return num
	end
	addon.db.actionBarMacroFontSize = clampFontSize(addon.db.actionBarMacroFontSize)
	addon.db.actionBarHotkeyFontSize = clampFontSize(addon.db.actionBarHotkeyFontSize)
	addon.db.actionBarCountFontSize = clampFontSize(addon.db.actionBarCountFontSize)
	addon.db.actionBarFadeStrength = GetActionBarFadeStrength()
	for _, cbData in ipairs(addon.variables.actionBarNames) do
		if cbData.var and cbData.name then
			local cfg = NormalizeActionBarVisibilityConfig(cbData.var, addon.db[cbData.var])
			UpdateActionBarMouseover(cbData.name, cfg, cbData.var)
		end
	end
	RefreshAllActionBarVisibilityAlpha()
	EnsureActionBarVisibilityWatcher()
	if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
	addon.variables.actionBarAnchorDefaults = addon.variables.actionBarAnchorDefaults or {}
	for index = 1, #ACTION_BAR_FRAME_NAMES do
		local dbKey = "actionBarAnchor" .. index
		local defaultAnchor = addon.functions.GetActionBarAnchor(index)
		if not addon.variables.actionBarAnchorDefaults[index] then addon.variables.actionBarAnchorDefaults[index] = defaultAnchor end
		local defaultKey = "actionBarAnchorDefault" .. index
		addon.functions.InitDBValue(defaultKey, addon.variables.actionBarAnchorDefaults[index])
		addon.functions.InitDBValue(dbKey, addon.db[defaultKey])
		local stored = addon.db[dbKey]
		if not ACTION_BAR_ANCHOR_CONFIG[stored] then
			stored = addon.db[defaultKey] or defaultAnchor
			addon.db[dbKey] = stored
		end
	end
	RefreshAllActionBarAnchors()
	if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
	if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
	UpdateAssistedCombatFrameHiding()
	if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
	ApplyExtraActionArtworkSetting()
end

local function initParty()
	addon.functions.InitDBValue("autoAcceptGroupInvite", false)
	addon.functions.InitDBValue("autoAcceptGroupInviteFriendOnly", false)
	addon.functions.InitDBValue("autoAcceptGroupInviteGuildOnly", false)
	addon.functions.InitDBValue("autoAcceptSummon", false)
end

local function setupQuickSkipCinematic()
	addon.variables = addon.variables or {}
	if addon.variables.quickSkipCinematicHooked then return end
	if not CinematicFrame or not CinematicFrame.HookScript then return end

	CinematicFrame:HookScript("OnKeyDown", function(_, key)
		if not addon.db or not addon.db["quickSkipCinematic"] then return end
		if key == "ESCAPE" then
			if CinematicFrame:IsShown() and CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then CinematicFrame.closeDialog:Hide() end
		end
	end)

	CinematicFrame:HookScript("OnKeyUp", function(_, key)
		if not addon.db or not addon.db["quickSkipCinematic"] then return end
		if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
			if CinematicFrame:IsShown() and CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then _G.CinematicFrameCloseDialogConfirmButton:Click() end
		end
	end)

	if MovieFrame and MovieFrame.HookScript then
		MovieFrame:HookScript("OnKeyUp", function(_, key)
			if not addon.db or not addon.db["quickSkipCinematic"] then return end
			if key == "SPACE" or key == "ESCAPE" or key == "ENTER" then
				if MovieFrame:IsShown() and MovieFrame.CloseDialog and MovieFrame.CloseDialog.ConfirmButton then MovieFrame.CloseDialog.ConfirmButton:Click() end
			end
		end)
	end

	addon.variables.quickSkipCinematicHooked = true
end

local AUTO_RELEASE_PVP_WORLD_MAPS = {
	[123] = true, -- Wintergrasp
	[244] = true, -- Tol Barad (PvP)
	[588] = true, -- Ashran
	[622] = true, -- Stormshield
	[624] = true, -- Warspear
}

local AUTO_RELEASE_PVP_EXCLUDE_ALTERAC = {
	[91] = true, -- Alterac Valley
	[1537] = true, -- Alterac Valley (legacy)
}

local AUTO_RELEASE_PVP_EXCLUDE_WINTERGRASP = {
	[123] = true, -- Wintergrasp
	[1334] = true, -- Wintergrasp (instanced)
}

local AUTO_RELEASE_PVP_EXCLUDE_TOLBARAD = {
	[244] = true, -- Tol Barad (PvP)
}

local AUTO_RELEASE_PVP_EXCLUDE_ASHRAN = {
	[588] = true, -- Ashran
	[622] = true, -- Stormshield
	[624] = true, -- Warspear
	[1478] = true, -- Ashran (instanced)
}

local function hasUsableSelfResurrection()
	local deathInfo = _G.C_DeathInfo
	local options = deathInfo and deathInfo.GetSelfResurrectOptions and deathInfo.GetSelfResurrectOptions()
	if not options then return false end
	for _, option in ipairs(options) do
		if option and option.canUse then return true end
	end
	return false
end

local function isAutoReleasePvPExcluded(mapID)
	if not mapID then return false end
	if addon.db["autoReleasePvPExcludeAlterac"] and AUTO_RELEASE_PVP_EXCLUDE_ALTERAC[mapID] then return true end
	if addon.db["autoReleasePvPExcludeWintergrasp"] and AUTO_RELEASE_PVP_EXCLUDE_WINTERGRASP[mapID] then return true end
	if addon.db["autoReleasePvPExcludeTolBarad"] and AUTO_RELEASE_PVP_EXCLUDE_TOLBARAD[mapID] then return true end
	if addon.db["autoReleasePvPExcludeAshran"] and AUTO_RELEASE_PVP_EXCLUDE_ASHRAN[mapID] then return true end
	return false
end

local function shouldAutoReleasePvP(mapID, inInstance, instanceType)
	if not addon.db or not addon.db["autoReleasePvP"] then return false end
	if hasUsableSelfResurrection() then return false end
	if inInstance and instanceType == "pvp" then return not isAutoReleasePvPExcluded(mapID) end
	if mapID and AUTO_RELEASE_PVP_WORLD_MAPS[mapID] then return not isAutoReleasePvPExcluded(mapID) end
	return false
end

local function scheduleAutoReleasePvP(popup)
	if not popup or not popup.GetButton then return end
	if not addon.db or not addon.db["autoReleasePvP"] then return end

	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local inInstance, instanceType = IsInInstance()
	if not shouldAutoReleasePvP(mapID, inInstance, instanceType) then return end

	local delayMs = tonumber(addon.db["autoReleasePvPDelay"] or 0) or 0
	if delayMs < 0 then delayMs = 0 end
	local delay = delayMs / 1000

	if popup._eqolAutoReleaseTimer then
		popup._eqolAutoReleaseTimer:Cancel()
		popup._eqolAutoReleaseTimer = nil
	end

	local function tryRelease()
		if not popup:IsShown() or popup.which ~= "DEATH" then return end
		local currentMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		local inInstanceNow, instanceTypeNow = IsInInstance()
		if not shouldAutoReleasePvP(currentMapID, inInstanceNow, instanceTypeNow) then return end
		local button = popup:GetButton(1)
		if button then button:Click() end
	end

	if delay <= 0 then
		RunNextFrame(tryRelease)
	else
		popup._eqolAutoReleaseTimer = C_Timer.NewTimer(delay, function()
			popup._eqolAutoReleaseTimer = nil
			tryRelease()
		end)
	end
end

local function resolveResurrectOffererUnit(offerer)
	if issecretvalue and issecretvalue(offerer) then return nil end
	if not offerer or offerer == "" then return nil end
	if UnitExists(offerer) then return offerer end

	local function matches(unit)
		local name, realm = UnitName(unit)
		if not name then return false end
		if realm and realm ~= "" and offerer == (name .. "-" .. realm) then return true end
		return offerer == name
	end

	if matches("player") then return "player" end
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local unit = "raid" .. i
			if matches(unit) then return unit end
		end
	elseif IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do
			local unit = "party" .. i
			if matches(unit) then return unit end
		end
	end

	return nil
end

local function shouldAutoAcceptResurrection(offerer)
	if not addon.db or not addon.db["autoAcceptResurrection"] then return false end
	local unit = resolveResurrectOffererUnit(offerer)
	if addon.db["autoAcceptResurrectionExcludeCombat"] then
		if unit and UnitAffectingCombat(unit) then return false end
	end
	if addon.db["autoAcceptResurrectionExcludeAfterlife"] then
		if unit and UnitIsDeadOrGhost(unit) then return false end
	end
	return true
end

local function initMisc()
	local globalFontKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or addon.variables.defaultFont
	local globalFontStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"

	addon.functions.InitDBValue("confirmTimerRemovalTrade", false)
	addon.functions.InitDBValue("deleteItemFillDialog", false)
	addon.functions.InitDBValue("confirmSocketReplace", false)
	addon.functions.InitDBValue("confirmHighCostItem", false)
	addon.functions.InitDBValue("confirmPurchaseTokenItem", false)
	addon.functions.InitDBValue("timeoutRelease", false)
	addon.functions.InitDBValue("timeoutReleaseModifier", "SHIFT")
	addon.functions.InitDBValue("autoAcceptResurrection", false)
	addon.functions.InitDBValue("autoAcceptResurrectionExcludeCombat", true)
	addon.functions.InitDBValue("autoAcceptResurrectionExcludeAfterlife", true)
	addon.functions.InitDBValue("autoReleasePvP", false)
	addon.functions.InitDBValue("autoReleasePvPDelay", 0)
	addon.functions.InitDBValue("autoReleasePvPExcludeAlterac", false)
	addon.functions.InitDBValue("autoReleasePvPExcludeWintergrasp", false)
	addon.functions.InitDBValue("autoReleasePvPExcludeTolBarad", false)
	addon.functions.InitDBValue("autoReleasePvPExcludeAshran", false)
	addon.functions.InitDBValue("hideRaidTools", false)
	addon.functions.InitDBValue("autoRepair", false)
	addon.functions.InitDBValue("autoRepairGuildBank", false)
	addon.functions.InitDBValue("autoRepairGuildBankContexts", AUTO_REPAIR_GUILD_BANK_CONTEXT_DEFAULTS)
	addon.functions.InitPrivateDBValue("autoWarbandGold", false)
	addon.functions.InitPrivateDBValue("autoWarbandGoldTargetGold", 10000)
	addon.functions.InitPrivateDBValue("autoWarbandGoldPerCharacter", {})
	addon.functions.InitPrivateDBValue("autoWarbandGoldTargetCharacter", "")
	addon.functions.InitPrivateDBValue("autoWarbandGoldIgnoredCharacters", {})
	addon.functions.InitPrivateDBValue("autoWarbandGoldWithdraw", false)
	addon.functions.InitDBValue("sellAllJunk", false)
	addon.functions.InitDBValue("autoCancelCinematic", false)
	addon.functions.InitDBValue("quickSkipCinematic", false)
	addon.functions.InitDBValue("ignoreTalkingHead", false)
	addon.functions.InitDBValue("autoHideBossBanner", false)
	addon.functions.InitDBValue("autoQuickLoot", false)
	addon.functions.InitDBValue("autoQuickLootWithShift", false)
	addon.functions.InitDBValue("hideAzeriteToast", false)
	addon.functions.InitDBValue("hiddenLandingPages", {})
	addon.functions.InitDBValue("enableLandingPageMenu", false)
	addon.functions.InitDBValue("landingPageButtonCustomPosition", false)
	addon.functions.InitDBValue("landingPageButtonAnchor", "BOTTOMLEFT")
	addon.functions.InitDBValue("landingPageButtonOffsetX", -16)
	addon.functions.InitDBValue("landingPageButtonOffsetY", -16)
	addon.functions.InitDBValue("landingPageButtonScale", 1)
	addon.functions.InitDBValue("hideMinimapButton", false)
	addon.functions.InitDBValue("hideZoneText", false)
	addon.functions.InitDBValue("instantCatalystEnabled", false)

	if addon.db["autoCancelCinematic"] and addon.db["quickSkipCinematic"] then addon.db["quickSkipCinematic"] = false end

	setupQuickSkipCinematic()

	-- Hook all static popups, because not the first one has to be the one for sell all junk if another popup is already shown
	for i = 1, 4 do
		local popup = _G["StaticPopup" .. i]
		if popup then
			hooksecurefunc(popup, "Show", function(self)
				if self then
					if self.which == "RECOVER_CORPSE" then
						local acceptbtn = self:GetButton(1)
						if acceptbtn then
							if acceptbtn:GetAlpha() ~= 1 then acceptbtn:SetAlpha(1) end
						end
						return
					end
					if self.GetButton then
						local btn = self:GetButton(1)
						if btn:GetAlpha() ~= 1 then btn:SetAlpha(1) end
					end
					local isDeathPopup = (self.which == "DEATH") and (self.numButtons or 0) > 0 and self.GetButton
					if isDeathPopup then
						local releaseButton = self:GetButton(1)
						local shouldGateRelease = addon.db["timeoutRelease"] and addon.functions.shouldUseTimeoutReleaseForCurrentContext()

						if shouldGateRelease then
							local modifierKey = addon.functions.getTimeoutReleaseModifierKey()
							local modifierDisplayName = addon.functions.getTimeoutReleaseModifierDisplayName(modifierKey)
							local isModifierDown = addon.functions.isTimeoutReleaseModifierDown(modifierKey)
							if releaseButton then releaseButton:SetAlpha(isModifierDown and 1 or 0) end
							addon.functions.showTimeoutReleaseHint(self, modifierDisplayName)
						else
							if releaseButton then releaseButton:SetAlpha(1) end
							addon.functions.hideTimeoutReleaseHint(self)
						end

						scheduleAutoReleasePvP(self)
					else
						addon.functions.hideTimeoutReleaseHint(self)
					end

					if addon.db["sellAllJunk"] and self.data and type(self.data) == "table" and self.data.text == SELL_ALL_JUNK_ITEMS_POPUP and self.button1 then
						self.button1:Click()
					elseif
						addon.db["deleteItemFillDialog"]
						and (self.which == "DELETE_GOOD_ITEM" or self.which == "DELETE_GOOD_QUEST_ITEM")
						and (self.editBox or self.GetEditBox and self:GetEditBox())
					then
						local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
						editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
						editBox:ClearFocus()
						editBox:SetAutoFocus(false)
					elseif addon.db["confirmTimerRemovalTrade"] and self.which == "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL" and self.GetButton then
						self:GetButton(1):Click()
					elseif addon.db["confirmSocketReplace"] and self.which == "CONFIRM_ACCEPT_SOCKETS" and self.numButtons > 0 and self.GetButton then
						self:GetButton(1):Click()
					elseif addon.db["confirmPurchaseTokenItem"] and self.which == "CONFIRM_PURCHASE_TOKEN_ITEM" and self.numButtons > 0 and self.GetButton then
						self:GetButton(1):Click()
					elseif addon.db["confirmHighCostItem"] and self.which == "CONFIRM_HIGH_COST_ITEM" and self.numButtons > 0 and self.GetButton then
						RunNextFrame(function() self:GetButton(1):Click() end)
					end
				end
			end)
			if not popup._eqolTimeoutReleaseOnHideHooked then
				popup:HookScript("OnHide", function(self) addon.functions.hideTimeoutReleaseHint(self) end)
				popup._eqolTimeoutReleaseOnHideHooked = true
			end
		end
	end

	local function getCurrentAutoRepairGuildBankContext()
		local inInstance, instanceType = false, nil
		if IsInInstance then inInstance, instanceType = IsInInstance() end
		local difficultyID = GetInstanceInfo and select(3, GetInstanceInfo()) or nil

		if inInstance then
			if instanceType == "raid" then return "raid" end
			if instanceType == "party" then return difficultyID == 8 and "mythicPlus" or "dungeon" end
			if instanceType == "pvp" or instanceType == "arena" then return "pvp" end
		end

		if IsInRaid and IsInRaid() then return "raid" end
		if IsInGroup and IsInGroup() then return "party" end
		return "world"
	end

	function addon.functions.ShouldUseGuildBankAutoRepairForCurrentContext()
		local selection = addon.db and addon.db["autoRepairGuildBankContexts"]
		if type(selection) ~= "table" then return true end
		local context = getCurrentAutoRepairGuildBankContext()
		return selection[context] == true
	end

	hooksecurefunc(MerchantFrame, "Show", function(self, button)
		if addon.db["autoRepair"] and CanMerchantRepair() then
			local repairAllCost = GetRepairAllCost()
			if repairAllCost and repairAllCost > 0 then
				local usedGuildBank = addon.db["autoRepairGuildBank"] and CanGuildBankRepair() and addon.functions.ShouldUseGuildBankAutoRepairForCurrentContext()
				if usedGuildBank then
					RepairAllItems(true)
				else
					RepairAllItems()
				end
				PlaySound(SOUNDKIT.ITEM_REPAIR)
				print(L["repairCost"] .. addon.functions.formatMoney(repairAllCost))
				if usedGuildBank then print(L["repairFromGuildBank"] or "Repaired from guild bank.") end
			end
		end
		if addon.db["sellAllJunk"] and C_MerchantFrame.IsSellAllJunkEnabled() then C_MerchantFrame.SellAllJunkItems() end
	end)

	hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function(self)
		if addon.db["ignoreTalkingHead"] then self:Hide() end
	end)
	hooksecurefunc(BossBanner, "PlayBanner", function(self)
		if addon.db["autoHideBossBanner"] then self:Hide() end
	end)
	if addon.db["hideAzeriteToast"] and AzeriteLevelUpToast then
		AzeriteLevelUpToast:UnregisterAllEvents()
		AzeriteLevelUpToast:Hide()
	end
	addon.functions.updateRaidToolsHook()
	addon.variables = addon.variables or {}

	local function clampNumber(value, minValue, maxValue, fallback)
		value = tonumber(value) or fallback
		if value < minValue then return minValue end
		if value > maxValue then return maxValue end
		return value
	end

	local function normalizeLandingPageButtonAnchor(anchor)
		if anchor == "TOPLEFT" or anchor == "TOP" or anchor == "TOPRIGHT" or anchor == "LEFT" or anchor == "CENTER" or anchor == "RIGHT" or anchor == "BOTTOMLEFT" or anchor == "BOTTOM" or anchor == "BOTTOMRIGHT" then return anchor end
		return "BOTTOMLEFT"
	end

	local function resetLandingPageButtonPlacement(button)
		button:SetScale(1)
		if button.ResetLandingPageIconOffset then
			button:ClearAllPoints()
			button:ResetLandingPageIconOffset()
		end
	end

	local function applyLandingPageButtonPlacement(button, resetDefault)
		if not button or not addon.db then return end

		if addon.db["landingPageButtonCustomPosition"] == true then
			local anchor = normalizeLandingPageButtonAnchor(addon.db["landingPageButtonAnchor"])
			local offsetX = tonumber(addon.db["landingPageButtonOffsetX"]) or -16
			local offsetY = tonumber(addon.db["landingPageButtonOffsetY"]) or -16
			local scale = clampNumber(addon.db["landingPageButtonScale"], 0.5, 2, 1)
			button:ClearAllPoints()
			button:SetPoint(anchor, Minimap, anchor, offsetX, offsetY)
			button:SetScale(scale)
			return
		end

		if not addon.db["enableSquareMinimap"] then
			if resetDefault then resetLandingPageButtonPlacement(button) end
			return
		end

		local reverse = addon.variables and addon.variables.landingPageReverse
		local id = reverse and reverse[button.title]
		button:ClearAllPoints()
		button:SetScale(1)
		if id == 20 then
			button:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -25, -25)
		else
			button:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -16, -16)
		end
	end

	local function refreshLandingPageButtonFix()
		local button = _G.ExpansionLandingPageMinimapButton
		if not button then return end

		applyLandingPageButtonPlacement(button)

		local reverse = addon.variables and addon.variables.landingPageReverse
		local id = reverse and reverse[button.title]
		if addon.db and addon.db["hiddenLandingPages"] and id and addon.db["hiddenLandingPages"][id] then button:Hide() end
	end

	function addon.functions.applyLandingPageButtonPlacement()
		refreshLandingPageButtonFix()
	end

	function addon.functions.resetLandingPageButtonPlacement()
		local button = _G.ExpansionLandingPageMinimapButton
		if not button then return end
		applyLandingPageButtonPlacement(button, true)
	end

	if ExpansionLandingPageMinimapButton and not addon.variables._eqolLandingPageButtonHooked then
		ExpansionLandingPageMinimapButton:HookScript("OnShow", refreshLandingPageButtonFix)
		ExpansionLandingPageMinimapButton:RegisterEvent("COVENANT_CHOSEN")
		ExpansionLandingPageMinimapButton:HookScript("OnEvent", function(_, event)
			if event ~= "COVENANT_CHOSEN" then return end
			RunNextFrame(refreshLandingPageButtonFix)
		end)
		if ExpansionLandingPageMinimapButton.RefreshButton then
			hooksecurefunc(ExpansionLandingPageMinimapButton, "RefreshButton", function() RunNextFrame(refreshLandingPageButtonFix) end)
		end
		if ExpansionLandingPageMinimapButton.UpdateIcon then
			hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", function() RunNextFrame(refreshLandingPageButtonFix) end)
		end
		addon.variables._eqolLandingPageButtonHooked = true
	end

	RunNextFrame(refreshLandingPageButtonFix)

	-- Right-click context menu for expansion/garrison minimap buttons
	local MU = MenuUtil

	local function ShowLandingMenu(owner)
		if MU and MU.CreateContextMenu then
			MU.CreateContextMenu(owner, function(_, root)
				if ShowGarrisonLandingPage and Enum and Enum.GarrisonType then
					root:CreateButton(GARRISON_TYPE_9_0_LANDING_PAGE_TITLE, function() ShowGarrisonLandingPage(Enum.GarrisonType.Type_9_0) end)
					root:CreateButton(ORDER_HALL_LANDING_PAGE_TITLE, function() ShowGarrisonLandingPage(3) end)
					root:CreateButton(GARRISON_LANDING_PAGE_TITLE, function() ShowGarrisonLandingPage(2) end)
					root:CreateButton(ADVENTURE_MAP_TITLE, function() ShowGarrisonLandingPage(9) end)
				end
			end)
		end
	end

	local function AttachRightClickMenu(button)
		if not button or button._eqolMenuHooked then return end
		button:HookScript("OnMouseUp", function(self, btn)
			if btn == "RightButton" and addon.db["enableLandingPageMenu"] then ShowLandingMenu(self) end
		end)
		button._eqolMenuHooked = true
	end

	RunNextFrame(function()
		if ExpansionLandingPageMinimapButton then AttachRightClickMenu(ExpansionLandingPageMinimapButton) end
		if GarrisonLandingPageMinimapButton then AttachRightClickMenu(GarrisonLandingPageMinimapButton) end
	end)
end

local function initLoot()
	addon.functions.InitDBValue("enableLootToastAnchor", false)
	addon.functions.InitDBValue("enableMajorFactionsRenownToastAnchor", false)
	addon.functions.InitDBValue("enableLootToastFilter", false)
	addon.functions.InitDBValue("lootToastItemLevels", {
		[Enum.ItemQuality.Rare] = 0,
		[Enum.ItemQuality.Epic] = 0,
		[Enum.ItemQuality.Legendary] = 0,
	})
	if addon.db.lootToastItemLevel then
		local v = addon.db.lootToastItemLevel
		addon.db.lootToastItemLevels[Enum.ItemQuality.Rare] = v
		addon.db.lootToastItemLevels[Enum.ItemQuality.Epic] = v
		addon.db.lootToastItemLevels[Enum.ItemQuality.Legendary] = v
		addon.db.lootToastItemLevel = nil
	end
	addon.functions.InitDBValue("lootToastFilters", {
		[Enum.ItemQuality.Rare] = { ilvl = true, mounts = true, pets = true, upgrade = false },
		[Enum.ItemQuality.Epic] = { ilvl = true, mounts = true, pets = true, upgrade = false },
		[Enum.ItemQuality.Legendary] = { ilvl = true, mounts = true, pets = true, upgrade = false },
	})
	for _, quality in ipairs({ Enum.ItemQuality.Rare, Enum.ItemQuality.Epic, Enum.ItemQuality.Legendary }) do
		local filter = addon.db.lootToastFilters[quality]
		if filter.upgrade == nil then filter.upgrade = false end
	end
	addon.functions.InitDBValue("lootToastIncludeIDs", {})
	addon.functions.InitDBValue("lootToastUseCustomSound", false)
	addon.functions.InitDBValue("lootToastCustomSoundFile", "")
	addon.functions.InitDBValue("lootToastAnchor", { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 240 })
	addon.functions.InitDBValue("majorFactionsRenownToastAnchor", { point = "TOP", relativePoint = "TOP", x = 0, y = -250 })
	-- migrate legacy LootRollMover-inspired settings to the new group-loot anchor keys
	if addon.db.enableLootRollAnchor ~= nil then
		if addon.db.enableGroupLootAnchor == nil then addon.db.enableGroupLootAnchor = addon.db.enableLootRollAnchor == true end
		addon.db.enableLootRollAnchor = nil
	end
	if addon.db.lootRollAnchor then
		addon.db.groupLootAnchor = addon.db.lootRollAnchor
		addon.db.lootRollAnchor = nil
	end
	if addon.db.lootRollLayout then
		addon.db.groupLootLayout = addon.db.lootRollLayout
		addon.db.lootRollLayout = nil
	end

	addon.functions.InitDBValue("enableGroupLootAnchor", false)
	addon.functions.InitDBValue("groupLootAnchor", { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 300 })
	addon.functions.InitDBValue("groupLootLayout", { scale = 1, offsetX = 0, offsetY = 0, spacing = 4 })

	local layout = addon.db.groupLootLayout
	if type(layout) ~= "table" then
		layout = { scale = 1, offsetX = 0, offsetY = 0, spacing = 4 }
		addon.db.groupLootLayout = layout
	end
	if type(layout.scale) ~= "number" then layout.scale = 1 end
	if layout.scale < 0.5 then layout.scale = 0.5 end
	if layout.scale > 3 then layout.scale = 3 end
	if layout.offsetX == nil then layout.offsetX = 0 end
	if layout.offsetY == nil then layout.offsetY = 0 end
	if layout.spacing == nil then layout.spacing = 4 end
	if addon.ChatIM and addon.ChatIM.BuildSoundTable and not addon.ChatIM.availableSounds then addon.ChatIM:BuildSoundTable() end
end

local function initUnitFrame()
	MigrateLegacyVisibilityFlags()
	addon.functions.InitDBValue("hideHitIndicatorPlayer", false)
	addon.functions.InitDBValue("hideHitIndicatorPet", false)
	-- Player resting visuals (ZZZ + glow)
	addon.functions.InitDBValue("hideRestingGlow", false)
	addon.functions.InitDBValue("hidePartyFrameTitle", false)
	addon.functions.InitDBValue("unitFrameScaleEnabled", false)
	addon.functions.InitDBValue("unitFrameScale", addon.variables.unitFrameScale)
	addon.functions.InitDBValue("ufUseCustomClassColors", false)
	addon.functions.InitDBValue("ufUseCustomPowerColors", false)
	addon.functions.InitDBValue("ufClassColors", {})
	addon.functions.InitDBValue("hiddenCastBars", addon.db["hiddenCastBars"] or {})
	addon.functions.InitDBValue("cooldownViewerVisibility", addon.db["cooldownViewerVisibility"] or {})
	-- Health text settings (player/target/boss)
	addon.functions.InitDBValue("healthTextPlayerMode", addon.db["healthTextPlayerMode"] or "OFF")
	addon.functions.InitDBValue("healthTextTargetMode", addon.db["healthTextTargetMode"] or "OFF")
	addon.functions.InitDBValue("healthTextBossMode", addon.db["healthTextBossMode"] or addon.db["bossHealthMode"] or "OFF")
	-- No separate CVar-override flags; OFF means follow Blizzard statusText
	if addon.db["hideHitIndicatorPlayer"] then PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator:Hide() end

	if PetHitIndicator then hooksecurefunc(PetHitIndicator, "Show", function(self)
		if addon.db["hideHitIndicatorPet"] then PetHitIndicator:Hide() end
	end) end

	-- Hide resting ZZZ texture and resting glow loop (opt-in, perf-safe)
	local function ApplyRestingVisuals()
		if not PlayerFrame or not PlayerFrame.PlayerFrameContent then return end
		local content = PlayerFrame.PlayerFrameContent
		local main = content.PlayerFrameContentMain
		local contextual = content.PlayerFrameContentContextual
		local statusTexture = main and main.StatusTexture
		local playerRestLoop = contextual and contextual.PlayerRestLoop
		if addon.db["hideRestingGlow"] and IsResting() then
			if statusTexture and statusTexture.Hide then statusTexture:Hide() end
			if playerRestLoop and playerRestLoop.Hide then
				playerRestLoop:Hide()
				if playerRestLoop.PlayerRestLoopAnim and playerRestLoop.PlayerRestLoopAnim.Stop then playerRestLoop.PlayerRestLoopAnim:Stop() end
			end
		else
			-- Let Blizzard refresh according to current resting state
			if PlayerFrame_UpdateStatus then PlayerFrame_UpdateStatus(PlayerFrame) end
		end
	end

	if PlayerFrame_UpdateStatus then
		hooksecurefunc("PlayerFrame_UpdateStatus", function(self)
			if not addon.db or not addon.db["hideRestingGlow"] then return end
			if IsResting() then
				local content = PlayerFrame.PlayerFrameContent
				local main = content and content.PlayerFrameContentMain
				local statusTexture = main and main.StatusTexture
				if statusTexture and statusTexture.Hide then statusTexture:Hide() end
				if PlayerFrame_UpdatePlayerRestLoop then PlayerFrame_UpdatePlayerRestLoop(true) end
			end
		end)
	end

	if PlayerFrame_UpdatePlayerRestLoop then
		hooksecurefunc("PlayerFrame_UpdatePlayerRestLoop", function(state)
			if not addon.db or not addon.db["hideRestingGlow"] then return end
			if state then
				local content = PlayerFrame.PlayerFrameContent
				local contextual = content and content.PlayerFrameContentContextual
				local playerRestLoop = contextual and contextual.PlayerRestLoop
				if playerRestLoop and playerRestLoop.Hide then
					playerRestLoop:Hide()
					if playerRestLoop.PlayerRestLoopAnim and playerRestLoop.PlayerRestLoopAnim.Stop then playerRestLoop.PlayerRestLoopAnim:Stop() end
				end
			end
		end)
	end

	addon.functions.ApplyRestingVisuals = ApplyRestingVisuals

	function addon.functions.togglePartyFrameTitle(value)
		if InCombatLockdown and InCombatLockdown() then
			addon.variables = addon.variables or {}
			addon.variables.pendingPartyFrameTitle = value
			return
		end
		if not CompactPartyFrameTitle then return end
		if value then
			CompactPartyFrameTitle:Hide()
		else
			CompactPartyFrameTitle:Show()
		end
	end
	if CompactPartyFrameTitle then CompactPartyFrameTitle:HookScript("OnShow", function(self)
		if addon.db["hidePartyFrameTitle"] then self:Hide() end
	end) end
	addon.functions.togglePartyFrameTitle(addon.db["hidePartyFrameTitle"])

	-- Name truncation was removed to avoid touching CompactUnitFrame name update flows.
	-- Keep no-op functions for compatibility with any lingering callers.
	addon.functions.EnsureUnitFrameNameHooks = function() end
	addon.functions.updateUnitFrameNames = function() end

	function addon.functions.updatePartyFrameScale()
		if not addon.db["unitFrameScaleEnabled"] then return end
		if not addon.db["unitFrameScale"] then return end
		if InCombatLockdown and InCombatLockdown() then
			addon.variables = addon.variables or {}
			addon.variables.pendingPartyFrameScale = true
			return
		end
		if addon.variables then addon.variables.pendingPartyFrameScale = nil end
		local scale = addon.db["unitFrameScale"]
		if CompactPartyFrame and CompactPartyFrame.SetScale then CompactPartyFrame:SetScale(scale) end
		if CompactRaidFrameContainer and CompactRaidFrameContainer.SetScale then
			CompactRaidFrameContainer:SetScale(scale)
		end
	end

	-- Cast bar visibility handling
	local castBarFrames = {
		PlayerCastingBarFrame = function() return _G.PlayerCastingBarFrame end,
		TargetFrameSpellBar = function() return _G.TargetFrameSpellBar end,
		FocusFrameSpellBar = function() return _G.FocusFrameSpellBar end,
	}

	local function getStandaloneCastbarModule()
		local castbarModule = addon.Aura and (addon.Aura.Castbar or addon.Aura.UFStandaloneCastbar)
		if type(castbarModule) ~= "table" then return nil end
		if type(castbarModule.GetConfig) ~= "function" then return nil end
		return castbarModule
	end

	local function isCustomPlayerCastbarEnabled()
		local standaloneEnabled = false
		local castbarModule = getStandaloneCastbarModule()
		if castbarModule and castbarModule.GetConfig then
			local cfg = castbarModule.GetConfig()
			if type(cfg) == "table" and cfg.enabled ~= nil then standaloneEnabled = cfg.enabled == true end
		end

		if standaloneEnabled then return true end

		-- Fallback gate: if UF player castbar is active, Blizzard player castbar must be hidden too.
		local uf = addon.Aura and addon.Aura.UF
		local playerCfg = uf and uf.GetConfig and uf.GetConfig("player")
		if type(playerCfg) ~= "table" or playerCfg.enabled ~= true then return false end
		local playerCast = playerCfg.cast
		return type(playerCast) == "table" and playerCast.enabled == true
	end

	local function EnsureCastbarHook(frame)
		if not frame or frame.EQOL_CastbarHooked then return end
		frame:HookScript("OnShow", function(self)
			local frameName = self:GetName()
			local hideByList = addon.db and addon.db.hiddenCastBars and addon.db.hiddenCastBars[frameName]
			local hidePlayerForCustom = frameName == "PlayerCastingBarFrame" and isCustomPlayerCastbarEnabled()
			if hideByList or hidePlayerForCustom then self:Hide() end
		end)
		frame.EQOL_CastbarHooked = true
	end

	function addon.functions.ApplyCastBarVisibility()
		if not addon.db then return end
		if type(addon.db.hiddenCastBars) ~= "table" then addon.db.hiddenCastBars = {} end
		local hidePlayerForCustom = isCustomPlayerCastbarEnabled()
		for key, getter in pairs(castBarFrames) do
			local frame = getter and getter() or _G[key]
			if frame then
				EnsureCastbarHook(frame)
				if addon.db.hiddenCastBars[key] or (key == "PlayerCastingBarFrame" and hidePlayerForCustom) then frame:Hide() end
			end
		end
	end

	if addon.db["unitFrameScaleEnabled"] then addon.functions.updatePartyFrameScale() end
	-- Apply resting visuals if option is enabled
	if addon.db["hideRestingGlow"] and addon.functions.ApplyRestingVisuals then addon.functions.ApplyRestingVisuals() end
	-- Initialize HealthText module
	if addon.HealthText then
		if addon.HealthText.SetMode then
			addon.HealthText:SetMode("player", addon.db["healthTextPlayerMode"])
			addon.HealthText:SetMode("target", addon.db["healthTextTargetMode"])
			addon.HealthText:SetMode("boss", addon.db["healthTextBossMode"])
		end
	end
	addon.functions.ApplyCastBarVisibility()

	for _, cbData in ipairs(addon.variables.unitFrameNames) do
		if cbData.var and cbData.name then UpdateUnitFrameMouseover(cbData.name, cbData) end
	end

	if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
	if addon.functions.EnsureCooldownViewerWatcher then addon.functions.EnsureCooldownViewerWatcher() end
	if addon.functions.EnsureCooldownViewerEditCallbacks then addon.functions.EnsureCooldownViewerEditCallbacks() end
	if addon.functions.EnsureCooldownViewerCombatLockWatcher then addon.functions.EnsureCooldownViewerCombatLockWatcher() end
	if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
	if addon.functions.EnsureSpellActivationOverlayWatcher then addon.functions.EnsureSpellActivationOverlayWatcher() end
end

local function initBagsFrame()
	local privateDB = getPrivateDB()
	addon.functions.InitPrivateDBValue("moneyTracker", {})
	addon.functions.InitPrivateDBValue("enableMoneyTracker", false)
	addon.functions.InitPrivateDBValue("showOnlyGoldOnMoney", false)
	addon.functions.InitPrivateDBValue("warbandGold", 0)
	if privateDB["moneyTracker"][UnitGUID("player")] == nil or type(privateDB["moneyTracker"][UnitGUID("player")]) ~= "table" then privateDB["moneyTracker"][UnitGUID("player")] = {} end

	local moneyFrame = ContainerFrameCombinedBags.MoneyFrame
	local otherMoney = {}

	local function ShowBagMoneyTooltip(self)
		if not privateDB["enableMoneyTracker"] then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()

		local list, total = {}, 0
		for _, info in pairs(privateDB["moneyTracker"]) do
			total = total + (info.money or 0)
			table.insert(list, info)
		end
		table.sort(list, function(a, b) return (a.money or 0) > (b.money or 0) end)

		GameTooltip:AddDoubleLine(L["warbandGold"], addon.functions.formatMoney(privateDB["warbandGold"] or 0, "tracker"))
		GameTooltip:AddLine(" ")

		for _, info in ipairs(list) do
			local col = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info.class] or { r = 1, g = 1, b = 1 }
			local displayName
			if info.realm == GetRealmName() or not info.realm or info.realm == "" then
				displayName = string.format("|cff%02x%02x%02x%s|r", col.r * 255, col.g * 255, col.b * 255, info.name)
			else
				displayName = string.format("|cff%02x%02x%02x%s-%s|r", col.r * 255, col.g * 255, col.b * 255, info.name, info.realm)
			end
			GameTooltip:AddDoubleLine(displayName, addon.functions.formatMoney(info.money, "tracker"))
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(TOTAL, addon.functions.formatMoney(total, "tracker"))
		GameTooltip:Show()
	end

	local function HideBagMoneyTooltip()
		if not privateDB["enableMoneyTracker"] then return end
		GameTooltip:Hide()
	end

	-- ! Still bugging as of 2026-01-21 - need to disable it
	-- moneyFrame:HookScript("OnEnter", ShowBagMoneyTooltip)
	-- moneyFrame:HookScript("OnLeave", HideBagMoneyTooltip)
	-- for _, coin in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do
	-- 	local btn = moneyFrame[coin]
	-- 	if btn then
	-- 		btn:HookScript("OnEnter", ShowBagMoneyTooltip)
	-- 		btn:HookScript("OnLeave", HideBagMoneyTooltip)
	-- 	end
	-- end

	-- moneyFrame = ContainerFrame1.MoneyFrame
	-- moneyFrame:HookScript("OnEnter", ShowBagMoneyTooltip)
	-- moneyFrame:HookScript("OnLeave", HideBagMoneyTooltip)
	-- for _, coin in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do
	-- 	local btn = moneyFrame[coin]
	-- 	if btn then
	-- 		btn:HookScript("OnEnter", ShowBagMoneyTooltip)
	-- 		btn:HookScript("OnLeave", HideBagMoneyTooltip)
	-- 	end
	-- end
end

local function initMap()
	addon.functions.InitDBValue("enableWayCommand", false)
	if addon.db["enableWayCommand"] then addon.functions.registerWayCommand() end
	addon.functions.InitDBValue("enableCooldownManagerSlashCommand", false)
	if addon.db["enableCooldownManagerSlashCommand"] then addon.functions.registerCooldownManagerSlashCommand() end
	addon.functions.InitDBValue("enablePullTimerSlashCommand", false)
	if addon.db["enablePullTimerSlashCommand"] then addon.functions.registerPullTimerSlashCommand() end
	addon.functions.InitDBValue("enableEditModeSlashCommand", false)
	if addon.db["enableEditModeSlashCommand"] then addon.functions.registerEditModeSlashCommand() end
	addon.functions.InitDBValue("enableQuickKeybindSlashCommand", false)
	if addon.db["enableQuickKeybindSlashCommand"] then addon.functions.registerQuickKeybindSlashCommand() end
	addon.functions.InitDBValue("enableClickCastSlashCommand", false)
	if addon.db["enableClickCastSlashCommand"] then addon.functions.registerClickCastSlashCommand() end
	addon.functions.InitDBValue("enableReloadUISlashCommand", false)
	if addon.db["enableReloadUISlashCommand"] then addon.functions.registerReloadUISlashCommand() end
end

local initLootToast

initLootToast = function()
	if
		(addon.db.enableLootToastFilter or addon.db.enableLootToastAnchor or addon.db.enableGroupLootAnchor or addon.db.enableMajorFactionsRenownToastAnchor)
		and addon.LootToast
		and addon.LootToast.Enable
	then
		addon.LootToast:Enable()
	elseif addon.LootToast and addon.LootToast.Disable then
		addon.LootToast:Disable()
	end
end
addon.functions.initLootToast = initLootToast

local function initUI()
	MigrateLegacyVisibilityFlags()
	addon.functions.InitDBValue("enableMinimapButtonBin", false)
	addon.functions.InitDBValue("frameVisibilityFadeStrength", 1)
	addon.functions.InitDBValue("buttonsink", {})
	addon.functions.InitDBValue("useDetachedMinimapButtonBinIcon", false)
	addon.functions.InitDBValue("detachedButtonSinkScale", 1)
	addon.functions.InitDBValue("detachedButtonSinkMoveModifier", "ALT")
	addon.functions.InitDBValue("buttonSinkAnchorPreference", "AUTO")
	addon.functions.InitDBValue("minimapButtonBinIconClickToggle", false)
	addon.functions.InitDBValue("minimapButtonBinColumns", DEFAULT_BUTTON_SINK_COLUMNS)
	addon.functions.InitDBValue("minimapButtonBinHideBackground", false)
	addon.functions.InitDBValue("minimapButtonBinHideBorder", false)
	addon.functions.InitDBValue("hideMinimapButtonBinToggle", false)
	addon.functions.InitDBValue("enableLootspecQuickswitch", false)
	addon.functions.InitDBValue("lootspec_quickswitch", {})
	addon.functions.InitDBValue("minimapSinkHoleData", {})
	addon.functions.InitDBValue("detachedButtonSinkData", {})
	addon.functions.InitDBValue("hideQuickJoinToast", false)
	addon.functions.InitDBValue("hideScreenshotStatus", false)
	addon.functions.InitDBValue("showTrainAllButton", false)
	addon.functions.InitDBValue("autoCancelDruidFlightForm", false)
	addon.functions.InitDBValue("mountBindingDismountWhileMounted", false)
	addon.functions.InitDBValue("randomMountDruidNoShiftWhileMounted", false)
	addon.functions.InitDBValue("randomMountDracthyrVisageBeforeMount", false)
	addon.functions.InitDBValue("randomMountCastSlowFallWhenFalling", false)
	addon.functions.InitDBValue("cooldownViewerFadeStrength", 1)
	addon.functions.InitDBValue("enableSquareMinimap", false)
	addon.functions.InitDBValue("enableSquareMinimapBorder", false)
	addon.functions.InitDBValue("enableSquareMinimapLayout", false)
	addon.functions.InitDBValue("enableSquareMinimapBackground", false)
	addon.functions.InitDBValue("squareMinimapBackgroundOffset", 8)
	addon.functions.InitDBValue("squareMinimapBackgroundColor", { r = 0, g = 0, b = 0, a = 0.65 })
	addon.functions.InitDBValue("squareMinimapBorderTexture", "DEFAULT")
	addon.functions.InitDBValue("squareMinimapBorderSize", 1)
	addon.functions.InitDBValue("squareMinimapBorderOffset", 0)
	addon.functions.InitDBValue("squareMinimapBorderColor", { r = 0, g = 0, b = 0 })
	addon.functions.InitDBValue("enableSquareMinimapStats", false)
	addon.functions.InitDBValue("squareMinimapStatsFont", addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__")
	addon.functions.InitDBValue("squareMinimapStatsOutline", addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__")
	addon.functions.InitDBValue("squareMinimapStatsTime", true)
	addon.functions.InitDBValue("squareMinimapStatsTimeAnchor", "BOTTOMLEFT")
	addon.functions.InitDBValue("squareMinimapStatsTimeOffsetX", 3)
	addon.functions.InitDBValue("squareMinimapStatsTimeOffsetY", 17)
	addon.functions.InitDBValue("squareMinimapStatsTimeFontSize", 18)
	addon.functions.InitDBValue("squareMinimapStatsTimeColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsTimeUseClassColor", false)
	addon.functions.InitDBValue("squareMinimapStatsTimeDisplayMode", "server")
	addon.functions.InitDBValue("squareMinimapStatsTimeUse24Hour", true)
	addon.functions.InitDBValue("squareMinimapStatsTimeShowSeconds", false)
	addon.functions.InitDBValue("squareMinimapStatsTimeLeftClickAction", "calendar")
	addon.functions.InitDBValue("squareMinimapStatsFPS", true)
	addon.functions.InitDBValue("squareMinimapStatsFPSAnchor", "BOTTOMLEFT")
	addon.functions.InitDBValue("squareMinimapStatsFPSOffsetX", 3)
	addon.functions.InitDBValue("squareMinimapStatsFPSOffsetY", 3)
	addon.functions.InitDBValue("squareMinimapStatsFPSFontSize", 12)
	addon.functions.InitDBValue("squareMinimapStatsFPSColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsFPSUseClassColor", false)
	addon.functions.InitDBValue("squareMinimapStatsFPSThresholdMedium", 30)
	addon.functions.InitDBValue("squareMinimapStatsFPSThresholdHigh", 60)
	addon.functions.InitDBValue("squareMinimapStatsFPSColorLow", { r = 1, g = 0, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsFPSColorMid", { r = 1, g = 1, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsFPSColorHigh", { r = 0, g = 1, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsFPSUpdateInterval", 0.25)
	addon.functions.InitDBValue("squareMinimapStatsLatency", true)
	addon.functions.InitDBValue("squareMinimapStatsLatencyAnchor", "BOTTOMRIGHT")
	addon.functions.InitDBValue("squareMinimapStatsLatencyOffsetX", -3)
	addon.functions.InitDBValue("squareMinimapStatsLatencyOffsetY", 3)
	addon.functions.InitDBValue("squareMinimapStatsLatencyFontSize", 12)
	addon.functions.InitDBValue("squareMinimapStatsLatencyColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLatencyUseClassColor", false)
	addon.functions.InitDBValue("squareMinimapStatsLatencyMode", "max")
	addon.functions.InitDBValue("squareMinimapStatsLatencyThresholdLow", 50)
	addon.functions.InitDBValue("squareMinimapStatsLatencyThresholdMid", 150)
	addon.functions.InitDBValue("squareMinimapStatsLatencyColorLow", { r = 0, g = 1, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLatencyColorMid", { r = 1, g = 0.65, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLatencyColorHigh", { r = 1, g = 0, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLatencyUpdateInterval", 1.0)
	addon.functions.InitDBValue("squareMinimapStatsDurability", false)
	addon.functions.InitDBValue("squareMinimapStatsDurabilityAnchor", "BOTTOM")
	addon.functions.InitDBValue("squareMinimapStatsDurabilityOffsetX", 0)
	addon.functions.InitDBValue("squareMinimapStatsDurabilityOffsetY", 3)
	addon.functions.InitDBValue("squareMinimapStatsDurabilityFontSize", 12)
	addon.functions.InitDBValue("squareMinimapStatsDurabilityColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsDurabilityShowIcon", true)
	addon.functions.InitDBValue("squareMinimapStatsDurabilityColorLow", { r = 1, g = 0, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsDurabilityColorMid", { r = 1, g = 1, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsDurabilityColorHigh", { r = 0, g = 1, b = 0, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLocation", true)
	addon.functions.InitDBValue("squareMinimapStatsLocationAnchor", "TOP")
	addon.functions.InitDBValue("squareMinimapStatsLocationOffsetX", 0)
	addon.functions.InitDBValue("squareMinimapStatsLocationOffsetY", -3)
	addon.functions.InitDBValue("squareMinimapStatsLocationFontSize", 12)
	addon.functions.InitDBValue("squareMinimapStatsLocationColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsLocationUseClassColor", false)
	addon.functions.InitDBValue("squareMinimapStatsLocationShowZone", true)
	addon.functions.InitDBValue("squareMinimapStatsLocationShowSubzone", false)
	addon.functions.InitDBValue("squareMinimapStatsLocationSubzoneBelowZone", false)
	addon.functions.InitDBValue("squareMinimapStatsLocationUseZoneColor", true)
	addon.functions.InitDBValue("squareMinimapStatsCoordinates", true)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesAnchor", "TOP")
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesOffsetX", 0)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesOffsetY", -17)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesFontSize", 12)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesUseClassColor", false)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesHideInInstance", true)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesDecimals", 2)
	addon.functions.InitDBValue("squareMinimapStatsCoordinatesUpdateInterval", 0.2)
	addon.functions.InitDBValue("squareMinimapStatsTrackingButton", false)
	addon.functions.InitDBValue("squareMinimapStatsTrackingButtonAnchor", "TOPRIGHT")
	addon.functions.InitDBValue("squareMinimapStatsTrackingButtonOffsetX", -3)
	addon.functions.InitDBValue("squareMinimapStatsTrackingButtonOffsetY", -3)
	addon.functions.InitDBValue("squareMinimapStatsTrackingButtonShowBackground", true)
	addon.functions.InitDBValue("squareMinimapStatsTrackingButtonScale", 1.0)
	addon.functions.InitDBValue("minimapButtonsMouseover", false)
	addon.functions.InitDBValue("unclampMinimapCluster", false)
	addon.functions.InitDBValue("enableMinimapClusterScale", false)
	addon.functions.InitDBValue("minimapClusterScale", 1)
	addon.functions.InitDBValue("hiddenMinimapElements", addon.db["hiddenMinimapElements"] or {})
	addon.functions.InitDBValue("alwaysUserCurExpAuctionHouse", false)
	addon.functions.InitDBValue("alwaysUserCurExpCraftingOrders", false)
	addon.functions.InitDBValue("enableExtendedMerchant", false)
	addon.functions.InitDBValue("configCenterDensity", "comfortable")
	addon.functions.InitDBValue("configCenterLocked", false)
	addon.functions.InitDBValue("configCenterSize", { width = 1080, height = 700 })
	addon.functions.InitDBValue("showInstanceDifficulty", false)
	addon.functions.InitDBValue("instanceDifficultyAnchor", "CENTER")
	addon.functions.InitDBValue("instanceDifficultyOffsetX", 0)
	addon.functions.InitDBValue("instanceDifficultyOffsetY", 0)
	addon.functions.InitDBValue("instanceDifficultyFontSize", 14)
	addon.functions.InitDBValue("instanceDifficultyUseColors", false)
	if type(addon.db["instanceDifficultyColors"]) ~= "table" then addon.db["instanceDifficultyColors"] = {} end
	-- Ensure default color entries exist
	local defaultColors = {
		NM = { r = 0.20, g = 0.95, b = 0.20 }, -- Normal: Green
		HC = { r = 0.25, g = 0.55, b = 1.00 }, -- Heroic: Blue
		M = { r = 0.80, g = 0.40, b = 1.00 }, -- Mythic: Violet
		MPLUS = { r = 0.80, g = 0.40, b = 1.00 }, -- Mythic+: Violet
		LFR = { r = 1.00, g = 1.00, b = 1.00 }, -- LFR: White (editable)
		TW = { r = 1.00, g = 1.00, b = 1.00 }, -- Timewalking: White (editable)
	}
	addon.dbDefaults = addon.dbDefaults or {}
	if type(addon.dbDefaults["instanceDifficultyColors"]) ~= "table" then addon.dbDefaults["instanceDifficultyColors"] = {} end
	for k, v in pairs(defaultColors) do
		if type(addon.dbDefaults["instanceDifficultyColors"][k]) ~= "table" then addon.dbDefaults["instanceDifficultyColors"][k] = { r = v.r, g = v.g, b = v.b, a = v.a or 1 } end
		if type(addon.db["instanceDifficultyColors"][k]) ~= "table" then addon.db["instanceDifficultyColors"][k] = v end
	end
	-- addon.functions.InitDBValue("instanceDifficultyUseIcon", false)

	addon.functions.InitDBValue("dungeonJournalLootSpecIcons", false)
	addon.functions.InitDBValue("dungeonJournalLootSpecAnchor", 1)
	addon.functions.InitDBValue("dungeonJournalLootSpecOffsetX", 0)
	addon.functions.InitDBValue("dungeonJournalLootSpecOffsetY", 0)
	addon.functions.InitDBValue("dungeonJournalLootSpecSpacing", 0)
	addon.functions.InitDBValue("dungeonJournalLootSpecScale", 1)
	addon.functions.InitDBValue("dungeonJournalLootSpecIconPadding", 0)
	addon.functions.InitDBValue("dungeonJournalLootSpecShowAll", false)

	-- Mailbox address book
	addon.functions.InitDBValue("enableMailboxAddressBook", false)
	addon.functions.InitDBValue("mailboxContacts", {})

	local function suppressMinimapBlobRings()
		if not Minimap then return end

		local setters = {
			{ name = "SetArchBlobRingAlpha", value = 0 },
			{ name = "SetArchBlobRingScalar", value = 0 },
			{ name = "SetQuestBlobRingAlpha", value = 0 },
			{ name = "SetQuestBlobRingScalar", value = 0 },
			{ name = "SetTaskBlobRingAlpha", value = 0 },
			{ name = "SetTaskBlobRingScalar", value = 0 },
		}

		for _, setter in ipairs(setters) do
			local fn = Minimap[setter.name]
			if type(fn) == "function" then fn(Minimap, setter.value) end
		end
	end

	local function makeSquareMinimap()
		MinimapCompassTexture:Hide()
		Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
		suppressMinimapBlobRings()

		addon.variables = addon.variables or {}
		if not addon.variables.squareMinimapBlobRingHooked and Minimap.HookScript then
			Minimap:HookScript("OnEvent", function(_, event)
				if event == "PLAYER_ENTERING_WORLD" and addon.db and addon.db["enableSquareMinimap"] then suppressMinimapBlobRings() end
			end)
			addon.variables.squareMinimapBlobRingHooked = true
		end

		function GetMinimapShape() return "SQUARE" end
	end
	if addon.db["enableSquareMinimap"] then makeSquareMinimap() end

	local SQUARE_MINIMAP_BORDER_DEFAULT_TEXTURE = "Interface\\Buttons\\WHITE8x8"
	local SQUARE_MINIMAP_BORDER_SIZE_MIN = 1
	local SQUARE_MINIMAP_BORDER_SIZE_MAX = 60
	local SQUARE_MINIMAP_BORDER_OFFSET_MIN = -30
	local SQUARE_MINIMAP_BORDER_OFFSET_MAX = 30
	local SQUARE_MINIMAP_BACKGROUND_DEFAULT_TEXTURE = "Interface\\Buttons\\WHITE8x8"
	local SQUARE_MINIMAP_BACKGROUND_OFFSET_MIN = -30
	local SQUARE_MINIMAP_BACKGROUND_OFFSET_MAX = 30

	local function isLikelyMinimapBorderPath(value)
		if type(value) ~= "string" or value == "" then return false end
		if value:find("\\", 1, true) or value:find("/", 1, true) then return true end
		return value:find("%.blp$", 1) or value:find("%.tga$", 1) or value:find("%.dds$", 1)
	end

	local function normalizeSquareMinimapBorderTexture(value)
		if type(value) ~= "string" or value == "" then return "DEFAULT" end
		return value
	end

	local function resolveSquareMinimapBorderTexture(value)
		local key = normalizeSquareMinimapBorderTexture(value)
		if key == "DEFAULT" or key == "SOLID" then return SQUARE_MINIMAP_BORDER_DEFAULT_TEXTURE end
		if LSM and LSM.Fetch then
			local texture = LSM:Fetch("border", key, true)
			if texture then return texture end
		end
		if isLikelyMinimapBorderPath(key) then return key end
		return SQUARE_MINIMAP_BORDER_DEFAULT_TEXTURE
	end

	local function normalizeSquareMinimapBorderSize(value)
		local size = tonumber(value) or 1
		size = math.floor(size + 0.5)
		if size < SQUARE_MINIMAP_BORDER_SIZE_MIN then return SQUARE_MINIMAP_BORDER_SIZE_MIN end
		if size > SQUARE_MINIMAP_BORDER_SIZE_MAX then return SQUARE_MINIMAP_BORDER_SIZE_MAX end
		return size
	end

	local function normalizeSquareMinimapBorderOffset(value)
		local offset = tonumber(value) or 0
		if offset < SQUARE_MINIMAP_BORDER_OFFSET_MIN then return SQUARE_MINIMAP_BORDER_OFFSET_MIN end
		if offset > SQUARE_MINIMAP_BORDER_OFFSET_MAX then return SQUARE_MINIMAP_BORDER_OFFSET_MAX end
		return offset
	end

	local function normalizeSquareMinimapBackgroundOffset(value)
		local offset = tonumber(value) or 0
		if offset < SQUARE_MINIMAP_BACKGROUND_OFFSET_MIN then return SQUARE_MINIMAP_BACKGROUND_OFFSET_MIN end
		if offset > SQUARE_MINIMAP_BACKGROUND_OFFSET_MAX then return SQUARE_MINIMAP_BACKGROUND_OFFSET_MAX end
		return offset
	end

	local function isFarmHudMinimapActive()
		local farmHud = _G.FarmHud
		if not farmHud or not farmHud.IsShown or not Minimap or not Minimap.GetParent then return false end
		return farmHud:IsShown() and Minimap:GetParent() == farmHud
	end

	local function hookFarmHudSquareMinimapBackground()
		addon.variables = addon.variables or {}
		if addon.variables.squareMinimapFarmHudBackgroundHooked then return end

		local farmHud = _G.FarmHud
		if not farmHud or not farmHud.HookScript then return end

		farmHud:HookScript("OnShow", function()
			if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
		end)
		farmHud:HookScript("OnHide", function()
			if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
		end)

		addon.variables.squareMinimapFarmHudBackgroundHooked = true
	end
	addon.functions.hookFarmHudSquareMinimapBackground = hookFarmHudSquareMinimapBackground

	function addon.functions.applySquareMinimapBackground()
		if not Minimap then return end
		local enableBackground = addon.db and addon.db["enableSquareMinimapBackground"]
		local isSquare = addon.db and addon.db["enableSquareMinimap"]

		if not addon.general.squareMinimapBackgroundFrame then
			local parent = Minimap:GetParent() or Minimap
			local f = CreateFrame("Frame", "EQOLMINIMAPBACKGROUND", parent, "BackdropTemplate")
			f:SetFrameStrata(Minimap:GetFrameStrata() or "LOW")
			f:SetFrameLevel(math.max(0, (Minimap:GetFrameLevel() or 1) - 1))
			f:EnableMouse(false)
			f:SetBackdrop({
				bgFile = SQUARE_MINIMAP_BACKGROUND_DEFAULT_TEXTURE,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			addon.general.squareMinimapBackgroundFrame = f
		end

		local f = addon.general.squareMinimapBackgroundFrame
		local offset = normalizeSquareMinimapBackgroundOffset(addon.db and addon.db.squareMinimapBackgroundOffset)
		local col = (addon.db and addon.db.squareMinimapBackgroundColor) or { r = 0, g = 0, b = 0, a = 0.65 }
		local r = col.r or col[1] or 0
		local g = col.g or col[2] or 0
		local b = col.b or col[3] or 0
		local a = col.a or col[4] or 0.65

		if not (enableBackground and isSquare) or a <= 0 or isFarmHudMinimapActive() then
			f:Hide()
			return
		end

		f:SetFrameStrata(Minimap:GetFrameStrata() or "LOW")
		f:SetFrameLevel(math.max(0, (Minimap:GetFrameLevel() or 1) - 1))
		f:SetBackdropColor(r, g, b, a)
		f:SetBackdropBorderColor(0, 0, 0, 0)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -offset, offset)
		f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", offset, -offset)
		f:Show()
	end

	-- Border for square minimap
	function addon.functions.applySquareMinimapBorder()
		if not Minimap then return end
		local enableBorder = addon.db and addon.db["enableSquareMinimapBorder"]
		local isSquare = addon.db and addon.db["enableSquareMinimap"]

		if not addon.general.squareMinimapBorderFrame then
			local f = CreateFrame("Frame", "EQOLBORDER", Minimap, "BackdropTemplate")
			f:SetFrameStrata("LOW")
			f:SetFrameLevel((Minimap:GetFrameLevel() or 2))
			f:EnableMouse(false)
			addon.general.squareMinimapBorderFrame = f
		end

		local f = addon.general.squareMinimapBorderFrame
		local texture = resolveSquareMinimapBorderTexture(addon.db and addon.db.squareMinimapBorderTexture)
		local size = normalizeSquareMinimapBorderSize(addon.db and addon.db.squareMinimapBorderSize)
		local offset = normalizeSquareMinimapBorderOffset(addon.db and addon.db.squareMinimapBorderOffset)
		local col = (addon.db and addon.db.squareMinimapBorderColor) or { r = 0, g = 0, b = 0, a = 1 }
		local r, g, b, a = col.r or 0, col.g or 0, col.b or 0, col.a or 1

		if not (enableBorder and isSquare) then
			f:Hide()
			return
		end

		local cache = f._squareMinimapBorderCache
		if not cache then
			cache = {}
			f._squareMinimapBorderCache = cache
		end
		if cache.edgeFile ~= texture or cache.edgeSize ~= size then
			f:SetBackdrop({
				edgeFile = texture,
				edgeSize = size,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			cache.edgeFile = texture
			cache.edgeSize = size
		end

		f:SetFrameLevel((Minimap:GetFrameLevel() or 2))
		f:SetBackdropColor(0, 0, 0, 0)
		f:SetBackdropBorderColor(r, g, b, a)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -offset, offset)
		f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", offset, -offset)
		f:Show()
	end

	-- Fill square minimap corners when the housing static overlay is shown
	function addon.functions.applySquareMinimapHousingBackdrop()
		if not Minimap or not MinimapBackdrop or not MinimapBackdrop.StaticOverlayTexture or not addon.db.enableSquareMinimap then return end

		if not addon.general.squareMinimapHousingBackdropFrame then
			local f = CreateFrame("Frame", nil, Minimap)
			f:SetAllPoints(Minimap)
			f:SetFrameStrata("LOW")
			f:SetFrameLevel(4)
			f.texture = f:CreateTexture(nil, "BACKGROUND")
			f.texture:SetAllPoints(f)
			f.texture:SetColorTexture(0, 0, 0, 1)
			f:Hide()
			addon.general.squareMinimapHousingBackdropFrame = f
		end

		local show = addon.db and addon.db.enableSquareMinimap and MinimapBackdrop.StaticOverlayTexture:IsShown()
		addon.general.squareMinimapHousingBackdropFrame:SetShown(show)
		if show then
			if _G.EQOLBORDER then _G.EQOLBORDER:SetFrameLevel(5) end
		else
			if _G.EQOLBORDER then _G.EQOLBORDER:SetFrameLevel(Minimap:GetFrameLevel() or 2) end
		end

		if not addon.variables.squareMinimapHousingBackdropHooked then
			MinimapBackdrop.StaticOverlayTexture:HookScript("OnShow", addon.functions.applySquareMinimapHousingBackdrop)
			MinimapBackdrop.StaticOverlayTexture:HookScript("OnHide", addon.functions.applySquareMinimapHousingBackdrop)
			addon.variables.squareMinimapHousingBackdropHooked = true
		end
	end

	-- Apply border at startup
	RunNextFrame(function()
		if addon.functions.hookFarmHudSquareMinimapBackground then addon.functions.hookFarmHudSquareMinimapBackground() end
		if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
		if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
		if addon.functions.applySquareMinimapHousingBackdrop then addon.functions.applySquareMinimapHousingBackdrop() end
	end)

	function addon.functions.applyMinimapClusterClamp()
		if not MinimapCluster or not MinimapCluster.SetClampedToScreen then return end
		if addon.db and addon.db.unclampMinimapCluster then
			MinimapCluster:SetClampedToScreen(false)
		else
			MinimapCluster:SetClampedToScreen(true)
		end
	end

	if addon.functions.applyMinimapClusterClamp then addon.functions.applyMinimapClusterClamp() end

	local function setMinimapClusterScaleKeepingPosition(scale)
		if not MinimapCluster or not MinimapCluster.SetScale then return end

		local point, relativeTo, relativePoint, xOfs, yOfs = MinimapCluster:GetPoint(1)
		local beforeX, beforeY = MinimapCluster:GetCenter()

		MinimapCluster:SetScale(scale)

		if not point or not beforeX or not beforeY then return end
		if InCombatLockdown and InCombatLockdown() and MinimapCluster.IsProtected and MinimapCluster:IsProtected() then return end

		local afterX, afterY = MinimapCluster:GetCenter()
		if not afterX or not afterY then return end

		local deltaX = beforeX - afterX
		local deltaY = beforeY - afterY
		if math.abs(deltaX) < 0.01 and math.abs(deltaY) < 0.01 then return end

		local relative = relativeTo or UIParent
		local relativeScale = (relative and relative.GetEffectiveScale and relative:GetEffectiveScale()) or (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
		if relativeScale == 0 then relativeScale = 1 end

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint(point, relative, relativePoint or point, (xOfs or 0) + (deltaX / relativeScale), (yOfs or 0) + (deltaY / relativeScale))
	end

	function addon.functions.applyMinimapClusterScale()
		if not MinimapCluster or not MinimapCluster.SetScale then return end
		if addon.db and addon.db.enableMinimapClusterScale then
			local scale = tonumber(addon.db.minimapClusterScale) or 1
			if scale < 0.5 then
				scale = 0.5
			elseif scale > 2 then
				scale = 2
			end
			setMinimapClusterScaleKeepingPosition(scale)
		else
			setMinimapClusterScaleKeepingPosition(1)
		end
	end

	if addon.functions.applyMinimapClusterScale then addon.functions.applyMinimapClusterScale() end

	function addon.functions.toggleMinimapButton(value)
		if value == false then
			LDBIcon:Show(addonName)
		else
			LDBIcon:Hide(addonName)
		end
	end
	function addon.functions.toggleZoneText(value, ignore)
		if value then
			ZoneTextFrame:UnregisterAllEvents()
			ZoneTextFrame:Hide()
		elseif not ignore then
			addon.variables.requireReload = true
		end
	end
	addon.functions.toggleZoneText(addon.db["hideZoneText"], true)

	function addon.functions.toggleScreenshotStatus(value)
		local actionStatus = _G.ActionStatus
		if not actionStatus or not actionStatus.UnregisterEvent or not actionStatus.RegisterEvent then return end
		if value then
			actionStatus:UnregisterEvent("SCREENSHOT_STARTED")
			actionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
			actionStatus:UnregisterEvent("SCREENSHOT_FAILED")
			if actionStatus.Hide then actionStatus:Hide() end
		else
			actionStatus:RegisterEvent("SCREENSHOT_STARTED")
			actionStatus:RegisterEvent("SCREENSHOT_SUCCEEDED")
			actionStatus:RegisterEvent("SCREENSHOT_FAILED")
		end
	end
	addon.functions.toggleScreenshotStatus(addon.db["hideScreenshotStatus"])

	function addon.functions.toggleQuickJoinToastButton(value)
		if value == false then
			QuickJoinToastButton:Show()
		else
			QuickJoinToastButton:Hide()
		end
	end
	addon.functions.toggleQuickJoinToastButton(addon.db["hideQuickJoinToast"])

	local function getAvailablePrimaryProfessionSlots()
		if not GetProfessions then return 2 end
		local profession1, profession2 = GetProfessions()
		local remainingSlots = 2
		if profession1 then remainingSlots = remainingSlots - 1 end
		if profession2 then remainingSlots = remainingSlots - 1 end
		return remainingSlots
	end

	local function canTrainAllService(index, remainingMoney, remainingProfessionSlots)
		if not GetTrainerServiceInfo or not GetTrainerServiceCost then return false, 0, false end
		local _, serviceType = GetTrainerServiceInfo(index)
		if serviceType ~= "available" then return false, 0, false end

		local price, isProfession = GetTrainerServiceCost(index)
		price = price or 0

		if isProfession and remainingProfessionSlots and remainingProfessionSlots <= 0 then return false, price, isProfession end

		if remainingMoney and price > remainingMoney then return false, price, isProfession end

		return true, price, isProfession
	end

	local function getTrainAllSummary()
		if not GetNumTrainerServices then return 0, 0 end
		local count, cost = 0, 0
		local numServices = GetNumTrainerServices() or 0
		local remainingMoney = GetMoney and GetMoney() or 0
		local remainingProfessionSlots = getAvailablePrimaryProfessionSlots()
		for i = 1, numServices do
			local canTrain, price, isProfession = canTrainAllService(i, remainingMoney, remainingProfessionSlots)
			if canTrain then
				count = count + 1
				cost = cost + price
				remainingMoney = remainingMoney - price
				if isProfession then remainingProfessionSlots = remainingProfessionSlots - 1 end
			end
		end
		return count, cost
	end

	local function updateTrainAllButtonState()
		local button = addon.variables and addon.variables.trainAllButton
		if not button then return end
		if not addon.db or not addon.db.showTrainAllButton then
			button:Hide()
			return
		end
		local count = select(1, getTrainAllSummary())
		button:SetEnabled(count > 0)
		if button:IsMouseOver() then
			if count > 0 then
				local onEnter = button:GetScript("OnEnter")
				if onEnter then onEnter(button) end
			elseif GameTooltip and GameTooltip:IsOwned(button) then
				GameTooltip_Hide()
			end
		end
	end

	function addon.functions.applyTrainAllButton()
		if not addon.db or not addon.db.showTrainAllButton then
			if addon.variables and addon.variables.trainAllButton then addon.variables.trainAllButton:Hide() end
			return
		end

		EventUtil.ContinueOnAddOnLoaded("Blizzard_TrainerUI", function()
			if not addon.db or not addon.db.showTrainAllButton then return end
			if not ClassTrainerFrame or not ClassTrainerTrainButton then return end
			addon.variables = addon.variables or {}
			local button = addon.variables.trainAllButton
			if not button then
				button = CreateFrame("Button", "EQOLTrainAllButton", ClassTrainerFrame, "MagicButtonTemplate")
				button:SetText((L and L["trainAllButtonLabel"]) or "Train All")
				button:SetHeight(ClassTrainerTrainButton:GetHeight() or 22)
				button:SetScript("OnClick", function()
					local remainingMoney = GetMoney and GetMoney() or 0
					local remainingProfessionSlots = getAvailablePrimaryProfessionSlots()
					for i = 1, GetNumTrainerServices() do
						local canTrain, price, isProfession = canTrainAllService(i, remainingMoney, remainingProfessionSlots)
						if canTrain then
							BuyTrainerService(i)
							remainingMoney = remainingMoney - price
							if isProfession then remainingProfessionSlots = remainingProfessionSlots - 1 end
						end
					end
				end)
				button:SetScript("OnEnter", function(self)
					local count, cost = getTrainAllSummary()
					if count <= 0 then return end
					GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
					GameTooltip:ClearLines()
					local template = (count == 1 and L and L["trainAllButtonTooltipSingle"]) or (L and L["trainAllButtonTooltipMulti"])
					if template then
						local moneyString = C_CurrencyInfo.GetCoinTextureString(cost)
						GameTooltip:AddLine(template:format(count, moneyString))
						GameTooltip:Show()
					end
				end)
				button:SetScript("OnLeave", GameTooltip_Hide)
				addon.variables.trainAllButton = button
			end

			button:ClearAllPoints()
			button:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -1, 0)

			local fontString = button.GetFontString and button:GetFontString()
			if fontString then fontString:SetWordWrap(false) end
			local baseWidth = (fontString and fontString:GetStringWidth() or 0) + 20
			local minWidth = 80
			if baseWidth < minWidth then baseWidth = minWidth end
			button:SetWidth(baseWidth)

			if ClassTrainerFrameMoneyBg then
				local gap = ClassTrainerFrame:GetWidth() - ClassTrainerFrameMoneyBg:GetWidth() - ClassTrainerTrainButton:GetWidth() - 13
				if gap > 0 and button:GetWidth() > gap then
					button:SetWidth(gap)
					if fontString then fontString:SetWidth(gap - 10) end
				end
			end

			button:Show()

			if not addon.variables.trainAllButtonHooked then
				hooksecurefunc("ClassTrainerFrame_Update", updateTrainAllButtonState)
				addon.variables.trainAllButtonHooked = true
			end
			updateTrainAllButtonState()
		end)
	end

	if addon.functions.applyTrainAllButton then addon.functions.applyTrainAllButton() end

	-- Hide/show specific minimap elements based on multi-select
	local function getMinimapElementFrames()
		local t = {}
		-- Tracking icon
		t.Tracking = {}
		if MinimapCluster and MinimapCluster.Tracking then table.insert(t.Tracking, MinimapCluster.Tracking) end
		if _G["MiniMapTracking"] then table.insert(t.Tracking, _G["MiniMapTracking"]) end
		-- Zone info (package)
		t.ZoneInfo = {}
		if MinimapCluster then
			if MinimapCluster.BorderTop then table.insert(t.ZoneInfo, MinimapCluster.BorderTop) end
			if MinimapCluster.ZoneTextButton then table.insert(t.ZoneInfo, MinimapCluster.ZoneTextButton) end
		end
		-- Clock
		t.Clock = {}
		if _G["TimeManagerClockButton"] then table.insert(t.Clock, _G["TimeManagerClockButton"]) end
		-- Calendar
		t.Calendar = {}
		if _G["GameTimeFrame"] then table.insert(t.Calendar, _G["GameTimeFrame"]) end
		-- Mail
		t.Mail = {}
		if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then table.insert(t.Mail, MinimapCluster.IndicatorFrame.MailFrame) end
		if _G["MiniMapMailFrame"] then table.insert(t.Mail, _G["MiniMapMailFrame"]) end
		if _G["MinimapMailFrame"] then table.insert(t.Mail, _G["MinimapMailFrame"]) end
		-- Addon compartment
		t.AddonCompartment = {}
		if _G["AddonCompartmentFrame"] then table.insert(t.AddonCompartment, _G["AddonCompartmentFrame"]) end
		return t
	end

	function addon.functions.ApplyMinimapElementVisibility()
		local cfg = addon.db and addon.db.hiddenMinimapElements or {}
		local elems = getMinimapElementFrames()
		local trackingDisabled = C_GameRules and C_GameRules.IsGameRuleActive and Enum and Enum.GameRule and C_GameRules.IsGameRuleActive(Enum.GameRule.IngameTrackingDisabled)
		local customTrackingButtonEnabled = addon.db
			and addon.db.enableSquareMinimap
			and addon.db.enableSquareMinimapStats
			and addon.db.squareMinimapStatsTrackingButton == true
			and not trackingDisabled
		for key, frames in pairs(elems) do
			local shouldHide = cfg and cfg[key]
			if key == "Tracking" then shouldHide = shouldHide or customTrackingButtonEnabled end
			for _, f in ipairs(frames) do
				if shouldHide then
					f:Hide()
					f._eqolMinimapHidden = true
				elseif f._eqolMinimapHidden then
					f._eqolMinimapHidden = nil
					if key ~= "Tracking" or not trackingDisabled then f:Show() end
				end
				if not f._eqolMinimapHideHooked then
					f._eqolMinimapHideHooked = true
					local hookKey = key
					f:HookScript("OnShow", function(self)
						local c = addon.db and addon.db.hiddenMinimapElements
						local hideForConfig = c and c[hookKey]
						local hideForCustomTracking = hookKey == "Tracking"
							and addon.db
							and addon.db.enableSquareMinimap
							and addon.db.enableSquareMinimapStats
							and addon.db.squareMinimapStatsTrackingButton == true
							and not (C_GameRules and C_GameRules.IsGameRuleActive and Enum and Enum.GameRule and C_GameRules.IsGameRuleActive(Enum.GameRule.IngameTrackingDisabled))
						if hideForConfig or hideForCustomTracking then self:Hide() end
					end)
				end
			end
		end
		if addon.functions.applySquareMinimapTrackingButton then addon.functions.applySquareMinimapTrackingButton() end
	end

	-- Apply on load with a tiny delay to ensure frames exist
	RunNextFrame(function()
		if addon.functions.ApplyMinimapElementVisibility then addon.functions.ApplyMinimapElementVisibility() end
	end)

	local eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnUpdate", function(self)
		addon.functions.toggleMinimapButton(addon.db["hideMinimapButton"])
		self:SetScript("OnUpdate", nil)
	end)

	local ICON_SIZE = 32
	local PADDING = 4
	local BUTTON_SINK_FRAME_STRATA = "MEDIUM"
	local BUTTON_SINK_FRAME_LEVEL = 7
	local BUTTON_SINK_BUTTON_LEVEL = BUTTON_SINK_FRAME_LEVEL + 1
	local BUTTON_SINK_ANCHORS = {
		TOPLEFT = { bag = "BOTTOMRIGHT", button = "TOPLEFT" },
		TOPRIGHT = { bag = "BOTTOMLEFT", button = "TOPRIGHT" },
		BOTTOMLEFT = { bag = "TOPRIGHT", button = "BOTTOMLEFT" },
		BOTTOMRIGHT = { bag = "TOPLEFT", button = "BOTTOMRIGHT" },
		TOP = { bag = "BOTTOM", button = "TOP" },
		BOTTOM = { bag = "TOP", button = "BOTTOM" },
		LEFT = { bag = "RIGHT", button = "LEFT" },
		RIGHT = { bag = "LEFT", button = "RIGHT" },
	}
	addon.variables.bagButtons = {}
	addon.variables.bagButtonState = {}
	addon.variables.bagButtonPoint = {}
	addon.variables.buttonSink = nil

	local function clearTrackedMinimapButton(btnName)
		if not btnName then return end
		addon.variables.bagButtons[btnName] = nil
		addon.variables.bagButtonState[btnName] = nil
	end

	local function shouldIgnoreMinimapButton(btnName)
		if not btnName then return true end
		return btnName == "MinimapZoomIn"
			or btnName == "MinimapZoomOut"
			or btnName == "MiniMapWorldMapButton"
			or btnName == "MiniMapTracking"
			or btnName == "GameTimeFrame"
			or btnName == "MinimapMailFrame"
			or btnName == "PlumberLandingPageMinimapButton"
			or btnName:match("^GatherMatePin")
			or btnName:match("^HandyNotesPin")
			or btnName:match("^TTMinimapButton")
			or btnName == addonName .. "_ButtonSinkMap"
			or btnName == "ZygorGuidesViewerMapIcon"
	end

	local function isFrameAnchoredThrough(frame, ancestor)
		while frame do
			if frame == ancestor then return true end
			frame = frame.GetParent and frame:GetParent() or nil
		end
		return false
	end

	local function isButtonSinkMinimapToggleEnabled() return addon.db and addon.db["useMinimapButtonBinIcon"] == true end

	local function isButtonSinkDetachedToggleEnabled() return addon.db and addon.db["useDetachedMinimapButtonBinIcon"] == true end

	local function getButtonSinkAnchorButton()
		if addon.variables and addon.variables.buttonSinkDetachedToggle then return addon.variables.buttonSinkDetachedToggle end
		if LDBIcon and LDBIcon.objects then return LDBIcon.objects[addonName .. "_ButtonSinkMap"] end
	end

	local function saveSimpleFramePoint(frame, dbKey)
		if not frame or not dbKey or not addon.db then return end
		addon.db[dbKey] = addon.db[dbKey] or {}
		local point, _, _, xOfs, yOfs = frame:GetPoint()
		addon.db[dbKey].point = point
		addon.db[dbKey].x = xOfs
		addon.db[dbKey].y = yOfs
	end

	local function restoreSimpleFramePoint(frame, dbKey, defaultPoint, defaultX, defaultY)
		if not frame then return end
		local data = addon.db and addon.db[dbKey] or nil
		local point = data and data.point or defaultPoint or "CENTER"
		local x = data and data.x or defaultX or 0
		local y = data and data.y or defaultY or 0
		frame:ClearAllPoints()
		frame:SetPoint(point, UIParent, point, x, y)
	end

	local function migrateDetachedButtonSinkPointData(button)
		if not button then return end
		local data = addon.db and addon.db["detachedButtonSinkData"] or nil
		if not data or data.point or type(data.centerX) ~= "number" or type(data.centerY) ~= "number" then return end
		button:ClearAllPoints()
		button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", data.centerX, data.centerY)
		saveSimpleFramePoint(button, "detachedButtonSinkData")
		data.centerX = nil
		data.centerY = nil
	end

	local function getDetachedButtonSinkScale()
		local scale = tonumber(addon.db and addon.db["detachedButtonSinkScale"]) or 1
		if scale < 0.5 then
			scale = 0.5
		elseif scale > 3 then
			scale = 3
		end
		return scale
	end

	local function getDetachedButtonSinkMoveModifier()
		local modifier = addon.db and addon.db["detachedButtonSinkMoveModifier"] or "ALT"
		modifier = type(modifier) == "string" and string.upper(modifier) or "ALT"
		if modifier ~= "NONE" and modifier ~= "ALT" and modifier ~= "SHIFT" and modifier ~= "CTRL" then modifier = "ALT" end
		return modifier
	end

	local function isDetachedButtonSinkMoveModifierActive()
		local modifier = getDetachedButtonSinkMoveModifier()
		if modifier == "NONE" then return true end
		if modifier == "ALT" then return IsAltKeyDown() end
		if modifier == "SHIFT" then return IsShiftKeyDown() end
		if modifier == "CTRL" then return IsControlKeyDown() end
		return false
	end

	local function canStartDetachedButtonDrag(mouseButton)
		if addon.db["lockMinimapButtonBin"] then return false end
		if mouseButton == "MiddleButton" then return true end
		return mouseButton == "LeftButton" and isDetachedButtonSinkMoveModifierActive()
	end

	local function applyDetachedButtonSinkScale(button)
		button = button or (addon.variables and addon.variables.buttonSinkDetachedToggle)
		if not button then return end
		local scale = getDetachedButtonSinkScale()
		local buttonSize = math.max(1, math.floor((31 * scale) + 0.5))
		local overlaySize = math.max(1, math.floor((50 * scale) + 0.5))
		local backgroundSize = math.max(1, math.floor((24 * scale) + 0.5))
		local iconSize = math.max(1, math.floor((18 * scale) + 0.5))

		button:SetScale(1)
		button:SetSize(buttonSize, buttonSize)
		if button.eqolOverlay then button.eqolOverlay:SetSize(overlaySize, overlaySize) end
		if button.eqolBackground then button.eqolBackground:SetSize(backgroundSize, backgroundSize) end
		if button.icon then button.icon:SetSize(iconSize, iconSize) end
	end
	addon.functions.applyDetachedButtonSinkScale = applyDetachedButtonSinkScale

	local function hoverOutFrame()
		local anchorButton = getButtonSinkAnchorButton()
		if addon.variables.buttonSink and anchorButton then
			if not MouseIsOver(addon.variables.buttonSink) and not MouseIsOver(anchorButton) then
				addon.variables.buttonSink:Hide()
			elseif addon.variables.buttonSink:IsShown() then
				C_Timer.After(1, function() hoverOutFrame() end)
			end
		end
	end
	local function hoverOutCheck(frame)
		if frame and frame:IsVisible() then
			if not MouseIsOver(frame) then
				frame:SetAlpha(0)
			else
				C_Timer.After(1, function() hoverOutCheck(frame) end)
			end
		end
	end

	local function positionBagFrame(bagFrame, anchorButton)
		bagFrame:ClearAllPoints()

		local bLeft = anchorButton:GetLeft() or 0
		local bRight = anchorButton:GetRight() or 0
		local bTop = anchorButton:GetTop() or 0
		local bBottom = anchorButton:GetBottom() or 0
		local bCenterX = (bLeft + bRight) / 2
		local bCenterY = (bTop + bBottom) / 2

		local screenWidth = GetScreenWidth()
		local screenHeight = GetScreenHeight()

		local bagWidth = bagFrame:GetWidth()
		local bagHeight = bagFrame:GetHeight()

		local preferredAnchor = "AUTO"
		if bagFrame == addon.variables.buttonSink and addon.db and type(addon.db.buttonSinkAnchorPreference) == "string" then preferredAnchor = string.upper(addon.db.buttonSinkAnchorPreference) end

		local function getButtonPointCoords(point)
			if point == "TOPLEFT" then return bLeft, bTop end
			if point == "TOPRIGHT" then return bRight, bTop end
			if point == "BOTTOMLEFT" then return bLeft, bBottom end
			if point == "BOTTOMRIGHT" then return bRight, bBottom end
			if point == "TOP" then return bCenterX, bTop end
			if point == "BOTTOM" then return bCenterX, bBottom end
			if point == "LEFT" then return bLeft, bCenterY end
			if point == "RIGHT" then return bRight, bCenterY end
		end

		local function calculateBounds(bagPoint, btnPoint)
			local anchorX, anchorY = getButtonPointCoords(btnPoint)
			if not anchorX then return end
			if bagPoint == "TOPLEFT" then return anchorX, anchorX + bagWidth, anchorY, anchorY - bagHeight end
			if bagPoint == "TOPRIGHT" then return anchorX - bagWidth, anchorX, anchorY, anchorY - bagHeight end
			if bagPoint == "BOTTOMLEFT" then return anchorX, anchorX + bagWidth, anchorY + bagHeight, anchorY end
			if bagPoint == "BOTTOMRIGHT" then return anchorX - bagWidth, anchorX, anchorY + bagHeight, anchorY end
			if bagPoint == "TOP" then return anchorX - bagWidth / 2, anchorX + bagWidth / 2, anchorY, anchorY - bagHeight end
			if bagPoint == "BOTTOM" then return anchorX - bagWidth / 2, anchorX + bagWidth / 2, anchorY + bagHeight, anchorY end
			if bagPoint == "LEFT" then return anchorX, anchorX + bagWidth, anchorY + bagHeight / 2, anchorY - bagHeight / 2 end
			if bagPoint == "RIGHT" then return anchorX - bagWidth, anchorX, anchorY + bagHeight / 2, anchorY - bagHeight / 2 end
		end

		local function fitsOnScreen(left, right, top, bottom)
			if not left then return false end
			return left >= 0 and right <= screenWidth and top <= screenHeight and bottom >= 0
		end

		local pointOnBag, pointOnButton
		local anchorConfig = BUTTON_SINK_ANCHORS[preferredAnchor]
		if anchorConfig then
			local left, right, top, bottom = calculateBounds(anchorConfig.bag, anchorConfig.button)
			if fitsOnScreen(left, right, top, bottom) then
				pointOnBag = anchorConfig.bag
				pointOnButton = anchorConfig.button
			end
		end

		if not pointOnBag or not pointOnButton then
			pointOnBag = "BOTTOMRIGHT"
			pointOnButton = "TOPLEFT"

			if (bTop + bagHeight) > screenHeight then
				pointOnBag = "TOPRIGHT"
				pointOnButton = "BOTTOMLEFT"
			end

			if (bLeft - bagWidth) < 0 then
				if pointOnBag == "BOTTOMRIGHT" then
					pointOnBag = "BOTTOMLEFT"
					pointOnButton = "TOPRIGHT"
				else
					pointOnBag = "TOPLEFT"
					pointOnButton = "BOTTOMRIGHT"
				end
			end
		end

		-- Jetzt setzen wir den finalen Anker
		if isFrameAnchoredThrough(anchorButton, bagFrame) then
			local anchorX, anchorY = getButtonPointCoords(pointOnButton)
			bagFrame:SetPoint(pointOnBag, UIParent, "BOTTOMLEFT", anchorX or 0, anchorY or 0)
		else
			bagFrame:SetPoint(pointOnBag, anchorButton, pointOnButton, 0, 0)
		end
	end

	local function removeButtonSink()
		if addon.variables.buttonSink then
			addon.variables.buttonSink:SetParent(nil)
			addon.variables.buttonSink:SetScript("OnLeave", nil)
			addon.variables.buttonSink:SetScript("OnDragStart", nil)
			addon.variables.buttonSink:SetScript("OnDragStop", nil)
			addon.variables.buttonSink:SetScript("OnEnter", nil)
			addon.variables.buttonSink:SetScript("OnLeave", nil)
			addon.variables.buttonSink:Hide()
			addon.variables.buttonSink = nil
		end
		if addon.variables.buttonSinkDetachedToggle then
			addon.variables.buttonSinkDetachedToggle:SetScript("OnEnter", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnLeave", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnClick", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnMouseDown", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnMouseUp", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnDragStart", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnDragStop", nil)
			addon.variables.buttonSinkDetachedToggle:SetScript("OnHide", nil)
			addon.variables.buttonSinkDetachedToggle:Hide()
			addon.variables.buttonSinkDetachedToggle:SetParent(nil)
			addon.variables.buttonSinkDetachedToggle = nil
		end
		addon.functions.LayoutButtons()
		if _G[addonName .. "_ButtonSinkMap"] then
			_G[addonName .. "_ButtonSinkMap"]:SetParent(nil)
			_G[addonName .. "_ButtonSinkMap"]:SetScript("OnEnter", nil)
			_G[addonName .. "_ButtonSinkMap"]:SetScript("OnLeave", nil)
			_G[addonName .. "_ButtonSinkMap"]:Hide()
			_G[addonName .. "_ButtonSinkMap"] = nil
		end
		if LDBIcon:IsRegistered(addonName .. "_ButtonSinkMap") then
			local button = LDBIcon.objects[addonName .. "_ButtonSinkMap"]
			if button then button:Hide() end
			LDBIcon.objects[addonName .. "_ButtonSinkMap"] = nil
		end
	end

	local function applyButtonSinkAppearance(frame)
		frame = frame or (addon.variables and addon.variables.buttonSink)
		if not frame or not frame.SetBackdrop then return end
		local hideBg = addon.db["minimapButtonBinHideBackground"]
		local hideBorder = addon.db["minimapButtonBinHideBorder"]
		if hideBg and hideBorder then
			frame:SetBackdrop(nil)
			return
		end
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		if hideBg then
			frame:SetBackdropColor(0, 0, 0, 0)
		else
			frame:SetBackdropColor(0, 0, 0, 0.4)
		end
		if hideBorder then
			frame:SetBackdropBorderColor(1, 1, 1, 0)
		else
			frame:SetBackdropBorderColor(1, 1, 1, 1)
		end
	end
	addon.functions.applyButtonSinkAppearance = applyButtonSinkAppearance

	local function createDetachedButtonSinkToggle()
		local button = CreateFrame("Button", nil, UIParent)
		button:SetFrameStrata("MEDIUM")
		button:SetFrameLevel(8)
		button:SetScale(1)
		button:SetSize(31, 31)
		button:SetMovable(true)
		button:SetClampedToScreen(true)
		button:EnableMouse(true)
		button:RegisterForClicks("AnyUp")
		button:RegisterForDrag("LeftButton", "MiddleButton")
		button:SetHighlightTexture(136477)

		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(50, 50)
		overlay:SetTexture(136430)
		overlay:SetPoint("TOPLEFT", button, "TOPLEFT")
		button.eqolOverlay = overlay

		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(24, 24)
		background:SetTexture(136467)
		background:SetPoint("CENTER", button, "CENTER")
		button.eqolBackground = background

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(18, 18)
		icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Icons\\SinkHole.tga")
		icon:SetPoint("CENTER", button, "CENTER")
		button.icon = icon

		migrateDetachedButtonSinkPointData(button)
		restoreSimpleFramePoint(button, "detachedButtonSinkData", "CENTER", 0, 0)
		applyDetachedButtonSinkScale(button)

		local function stopDetachedDrag(self)
			if not self._eqolDragging then return end
			self:StopMovingOrSizing()
			self._eqolDragging = nil
			self._eqolPressedButton = nil
			saveSimpleFramePoint(self, "detachedButtonSinkData")
			RunNextFrame(function()
				if self then self._eqolSuppressClick = nil end
			end)
		end

		button:SetScript("OnEnter", function(self)
			if addon.db["minimapButtonBinIconClickToggle"] then return end
			if not addon.variables.buttonSink then return end
			positionBagFrame(addon.variables.buttonSink, self)
			addon.variables.buttonSink:Show()
		end)
		button:SetScript("OnLeave", function()
			if addon.db["minimapButtonBinIconClickToggle"] then return end
			C_Timer.After(1, function() hoverOutFrame() end)
		end)
		button:SetScript("OnClick", function(self, mouseButton)
			if self._eqolSuppressClick or addon.db["minimapButtonBinIconClickToggle"] ~= true then return end
			if mouseButton and mouseButton ~= "LeftButton" then return end
			if not addon.variables.buttonSink then return end
			if addon.variables.buttonSink:IsShown() then
				addon.variables.buttonSink:Hide()
			else
				positionBagFrame(addon.variables.buttonSink, self)
				addon.variables.buttonSink:Show()
			end
		end)
		button:SetScript("OnMouseDown", function(self, mouseButton) self._eqolPressedButton = mouseButton end)
		button:SetScript("OnMouseUp", function(self, mouseButton)
			if mouseButton == self._eqolPressedButton then self._eqolPressedButton = nil end
			stopDetachedDrag(self)
		end)
		button:SetScript("OnDragStart", function(self)
			if not canStartDetachedButtonDrag(self._eqolPressedButton) then return end
			self._eqolSuppressClick = true
			self._eqolDragging = true
			if addon.variables.buttonSink then addon.variables.buttonSink:Hide() end
			self:StartMoving()
		end)
		button:SetScript("OnDragStop", stopDetachedDrag)
		button:SetScript("OnHide", stopDetachedDrag)

		return button
	end

	local function firstStartButtonSink(counter)
		if hookedATT then return end
		if C_AddOns.IsAddOnLoadable("AllTheThings") then
			if _G["AllTheThings-Minimap"] then
				addon.functions.gatherMinimapButtons()
				addon.functions.LayoutButtons()
				return
			end
			if _G["AllTheThings"] and _G["AllTheThings"].SetMinimapButtonSettings then
				hooksecurefunc(_G["AllTheThings"], "SetMinimapButtonSettings", function(self, visible)
					addon.functions.gatherMinimapButtons()
					addon.functions.LayoutButtons()
				end)
				hookedATT = true
				return
			end
			if counter < 30 then C_Timer.After(0.5, function() firstStartButtonSink(counter + 1) end) end
		end
	end

	function addon.functions.toggleButtonSink()
		if addon.db["enableMinimapButtonBin"] then
			removeButtonSink()
			local useMinimapToggle = isButtonSinkMinimapToggleEnabled()
			local useDetachedToggle = isButtonSinkDetachedToggleEnabled()
			local useLauncherToggle = useMinimapToggle or useDetachedToggle
			local hideLauncherToggle = addon.db["hideMinimapButtonBinToggle"] == true and useLauncherToggle

			firstStartButtonSink(0)
			C_Timer.After(2, function()
				addon.functions.gatherMinimapButtons()
				addon.functions.LayoutButtons()
			end)
			local buttonBag = CreateFrame("Frame", addonName .. "_ButtonSink", UIParent, "BackdropTemplate")
			buttonBag:SetSize(150, 150)
			buttonBag:SetFrameStrata(BUTTON_SINK_FRAME_STRATA)
			buttonBag:SetFrameLevel(BUTTON_SINK_FRAME_LEVEL)

			if useLauncherToggle then
				buttonBag:SetScript("OnLeave", function()
					if addon.db["minimapButtonBinIconClickToggle"] ~= true then C_Timer.After(1, function() hoverOutFrame() end) end
				end)
			else
				if not addon.db["lockMinimapButtonBin"] then
					buttonBag:SetMovable(true)
					buttonBag:EnableMouse(true)
					buttonBag:RegisterForDrag("LeftButton")
					buttonBag:SetScript("OnDragStart", buttonBag.StartMoving)
					buttonBag:SetScript("OnDragStop", function(self)
						self:StopMovingOrSizing()
						saveSimpleFramePoint(self, "minimapSinkHoleData")
					end)
				end
				restoreSimpleFramePoint(buttonBag, "minimapSinkHoleData", "CENTER", 0, 0)
				if addon.db["useMinimapButtonBinMouseover"] then
					buttonBag:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
					buttonBag:SetScript("OnLeave", function(self) hoverOutCheck(self) end)
					buttonBag:SetAlpha(0)
				end
			end
			addon.variables.buttonSink = buttonBag
			applyButtonSinkAppearance(buttonBag)
			addon.functions.gatherMinimapButtons()
			addon.functions.LayoutButtons()

			-- create ButtonSink Button
			if useMinimapToggle and not hideLauncherToggle then
				local iconData = {
					type = "launcher",
					icon = "Interface\\AddOns\\" .. addonName .. "\\Icons\\SinkHole.tga" or "Interface\\ICONS\\INV_Misc_QuestionMark", -- irgendein Icon
					label = addonName .. "_ButtonSinkMap",
					OnEnter = function(self)
						if addon.db["minimapButtonBinIconClickToggle"] then return end
						local anchorButton = LDBIcon.objects[addonName .. "_ButtonSinkMap"] or self
						if not anchorButton then return end
						positionBagFrame(addon.variables.buttonSink, anchorButton)
						addon.variables.buttonSink:Show()
					end,
					OnClick = function(self, button)
						if addon.db["minimapButtonBinIconClickToggle"] ~= true then return end
						if button and button ~= "LeftButton" then return end
						if not addon.variables.buttonSink then return end
						if addon.variables.buttonSink:IsShown() then
							addon.variables.buttonSink:Hide()
						else
							local anchorButton = LDBIcon.objects[addonName .. "_ButtonSinkMap"] or self
							if anchorButton then positionBagFrame(addon.variables.buttonSink, anchorButton) end
							addon.variables.buttonSink:Show()
						end
					end,
					OnLeave = function(self)
						if addon.db["minimapButtonBinIconClickToggle"] ~= true then C_Timer.After(1, function() hoverOutFrame() end) end
					end,
				}
				-- Registriere das Icon bei LibDBIcon
				LDB:NewDataObject(addonName .. "_ButtonSinkMap", iconData)
				LDBIcon:Register(addonName .. "_ButtonSinkMap", iconData, addon.db["buttonsink"])
				buttonBag:Hide()
			elseif useDetachedToggle and not hideLauncherToggle then
				addon.variables.buttonSinkDetachedToggle = createDetachedButtonSinkToggle()
				buttonBag:Hide()
			elseif hideLauncherToggle then
				buttonBag:Hide()
			else
				buttonBag:Show()
			end
		elseif addon.variables.buttonSink then
			removeButtonSink()
		end
	end

	local function setLibDBIconMouseover(name, enable, button)
		if not name then return end
		addon.variables = addon.variables or {}

		local function getManualMouseoverButtons()
			if not addon.variables.eqolManualMouseoverButtons then addon.variables.eqolManualMouseoverButtons = setmetatable({}, { __mode = "k" }) end
			return addon.variables.eqolManualMouseoverButtons
		end

		local function ensureManualMouseoverHooks()
			if addon.variables.eqolManualMouseoverHooked or not Minimap or not Minimap.HookScript then return end
			addon.variables.eqolManualMouseoverHooked = true
			Minimap:HookScript("OnEnter", function()
				local buttons = addon.variables.eqolManualMouseoverButtons
				if not buttons then return end
				for btn in pairs(buttons) do
					if btn and btn.eqolShowOnMouseover then
						if btn.eqolFadeOut then btn.eqolFadeOut:Stop() end
						btn:SetAlpha(1)
					end
				end
			end)
			Minimap:HookScript("OnLeave", function()
				local buttons = addon.variables.eqolManualMouseoverButtons
				if not buttons then return end
				for btn in pairs(buttons) do
					if btn and btn.eqolShowOnMouseover then
						if btn.eqolFadeOut then
							btn.eqolFadeOut:Play()
						else
							btn:SetAlpha(0)
						end
					end
				end
			end)
		end

		local function ensureManualFade(btn)
			if not btn or btn.eqolFadeOut then return end
			local fade = btn:CreateAnimationGroup()
			local animOut = fade:CreateAnimation("Alpha")
			animOut:SetOrder(1)
			animOut:SetDuration(0.2)
			animOut:SetFromAlpha(1)
			animOut:SetToAlpha(0)
			animOut:SetStartDelay(1)
			fade:SetToFinalAlpha(true)
			btn.eqolFadeOut = fade
		end

		local function setManualMinimapMouseover(btn, on)
			if not btn or not btn.SetAlpha then return end
			local list = getManualMouseoverButtons()
			btn.eqolShowOnMouseover = on and true or false
			if on then
				ensureManualFade(btn)
				list[btn] = true
				if btn.eqolFadeOut then btn.eqolFadeOut:Stop() end
				btn:SetAlpha(0)
			else
				list[btn] = nil
				if btn.eqolFadeOut then btn.eqolFadeOut:Stop() end
				btn:SetAlpha(1)
			end
			if not btn.eqolMouseoverHooked then
				btn:HookScript("OnEnter", function(self)
					if self.eqolShowOnMouseover then
						if self.eqolFadeOut then self.eqolFadeOut:Stop() end
						self:SetAlpha(1)
					end
				end)
				btn:HookScript("OnLeave", function(self)
					if self.eqolShowOnMouseover then
						if self.eqolFadeOut then
							self.eqolFadeOut:Play()
						else
							self:SetAlpha(0)
						end
					end
				end)
				btn.eqolMouseoverHooked = true
			end
			ensureManualMouseoverHooks()
		end

		if LDBIcon and LDBIcon.ShowOnEnter then
			local ldbButton = LDBIcon.GetMinimapButton and LDBIcon:GetMinimapButton(name)
			if ldbButton then
				LDBIcon:ShowOnEnter(name, enable)
			else
				setManualMinimapMouseover(button, enable)
			end
			return
		end

		if not button then return end
		button.showOnMouseover = enable and true or false
		if button.fadeOut then button.fadeOut:Stop() end
		if enable then
			button:SetAlpha(0)
		else
			button:SetAlpha(1)
		end
	end
	function addon.functions.LayoutButtons()
		if addon.db["enableMinimapButtonBin"] then
			local columns = tonumber(addon.db["minimapButtonBinColumns"]) or DEFAULT_BUTTON_SINK_COLUMNS
			columns = math.floor(columns + 0.5)
			if columns < 1 then
				columns = 1
			elseif columns > 99 then
				columns = 99
			end
			if addon.variables.buttonSink then
				local index = 0
				local orderedNames = {}
				for name in pairs(addon.variables.bagButtons) do
					orderedNames[#orderedNames + 1] = name
				end
				table.sort(orderedNames, function(a, b)
					local aKey = string.lower(a or "")
					local bKey = string.lower(b or "")
					if aKey == bKey then return (a or "") < (b or "") end
					return aKey < bKey
				end)
				for _, name in ipairs(orderedNames) do
					local button = addon.variables.bagButtons[name]
					if shouldIgnoreMinimapButton(name) then
						button:ClearAllPoints()
						button:SetParent(Minimap)
						if addon.variables.bagButtonPoint[name] then
							local pData = addon.variables.bagButtonPoint[name]
							if pData.point and pData.relativePoint and pData.relativeTo and pData.xOfs and pData.yOfs then
								button:SetPoint(pData.point, pData.relativeTo, pData.relativePoint, pData.xOfs, pData.yOfs)
							end
							button:SetFrameStrata(pData.strata or "MEDIUM")
							if pData.level then button:SetFrameLevel(pData.level) end
						end
						clearTrackedMinimapButton(name)
					elseif addon.db["ignoreMinimapButtonBin_" .. name] then
						if addon.db.minimapButtonsMouseover then setLibDBIconMouseover(name, true, button) end
						button:ClearAllPoints()
						button:SetParent(Minimap)
						if addon.variables.bagButtonPoint[name] then
							local pData = addon.variables.bagButtonPoint[name]
							if pData.point and pData.relativePoint and pData.relativeTo and pData.xOfs and pData.yOfs then
								button:SetPoint(pData.point, pData.relativeTo, pData.relativePoint, pData.xOfs, pData.yOfs)
							end
							button:SetFrameStrata(pData.strata or "MEDIUM")
							if pData.level then button:SetFrameLevel(pData.level) end
						end
					elseif addon.variables.bagButtonState[name] then
						if addon.db.minimapButtonsMouseover then setLibDBIconMouseover(name, false, button) end
						index = index + 1
						button:ClearAllPoints()
						local col = (index - 1) % columns
						local row = math.floor((index - 1) / columns)

						button:SetParent(addon.variables.buttonSink)
						button:SetFrameStrata(BUTTON_SINK_FRAME_STRATA)
						button:SetFrameLevel(BUTTON_SINK_BUTTON_LEVEL)
						button:SetSize(ICON_SIZE, ICON_SIZE)
						button:SetPoint("TOPLEFT", addon.variables.buttonSink, "TOPLEFT", col * (ICON_SIZE + PADDING) + PADDING, -row * (ICON_SIZE + PADDING) - PADDING)
						button:Show()
					else
						button:Hide()
					end
				end

				local totalRows = math.ceil(index / columns)
				local tmpColumns = min(index, columns)
				local width = (ICON_SIZE + PADDING) * tmpColumns + PADDING
				local height = (ICON_SIZE + PADDING) * totalRows + PADDING
				if index == 0 then
					addon.variables.buttonSink:SetSize(0, 0)
				else
					addon.variables.buttonSink:SetSize(width, height)
				end
			end
		else
			for name, button in pairs(addon.variables.bagButtons) do
				button:ClearAllPoints()
				button:SetParent(Minimap)
				addon.variables.bagButtons[name] = nil
				addon.variables.bagButtonState[name] = nil
				if addon.variables.bagButtonPoint[name] then
					local pData = addon.variables.bagButtonPoint[name]
					if pData.point and pData.relativePoint and pData.relativeTo and pData.xOfs and pData.yOfs then
						button:SetPoint(pData.point, pData.relativeTo, pData.relativePoint, pData.xOfs, pData.yOfs)
					else
						LDBIcon:Show(name)
					end
					button:SetFrameStrata(pData.strata or "MEDIUM")
					if pData.level then button:SetFrameLevel(pData.level) end
					addon.variables.bagButtonPoint[name] = nil
				end
			end
		end
	end

	function addon.functions.gatherMinimapButtons()
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType("Button") and child:GetName() then
				local btnName = child:GetName():gsub("^LibDBIcon10_", ""):gsub(".*_LibDBIcon_", "")
				if shouldIgnoreMinimapButton(btnName) then
					clearTrackedMinimapButton(btnName)
				else
					local pData = addon.variables.bagButtonPoint[btnName] or {}
					if not pData.point then
						local point, relativeTo, relativePoint, xOfs, yOfs = child:GetPoint()
						pData.point = point
						pData.relativeTo = relativeTo
						pData.relativePoint = relativePoint
						pData.xOfs = xOfs
						pData.yOfs = yOfs
					end
					pData.strata = pData.strata or child:GetFrameStrata()
					pData.level = pData.level or child:GetFrameLevel()
					addon.variables.bagButtonPoint[btnName] = pData
					if (child.db and child.db.hide) or not child:IsVisible() then
						addon.variables.bagButtonState[btnName] = false
					else
						addon.variables.bagButtonState[btnName] = true
						addon.variables.bagButtons[btnName] = child
					end
				end
			end
		end
	end

	local function shouldEnableMinimapButtonMouseover() return addon.db and addon.db.minimapButtonsMouseover end
	function addon.functions.applyMinimapButtonMouseover()
		if not LDBIcon then return end

		addon.functions.gatherMinimapButtons()

		addon.variables = addon.variables or {}
		local enable = shouldEnableMinimapButtonMouseover()
		for name, button in pairs(addon.variables.bagButtons) do
			local enableit = enable
			if addon.db["enableMinimapButtonBin"] and not addon.db["ignoreMinimapButtonBin_" .. name] then enableit = false end
			setLibDBIconMouseover(name, enableit, button)
		end
		if not addon.variables.minimapButtonMouseoverHooked then
			if LDBIcon.RegisterCallback then
				LDBIcon.RegisterCallback(addon, "LibDBIcon_IconCreated", function(_, button, name)
					if shouldEnableMinimapButtonMouseover() then setLibDBIconMouseover(name, true) end
				end)
			else
				hooksecurefunc(LDBIcon, "Register", function(self, name)
					if shouldEnableMinimapButtonMouseover() then setLibDBIconMouseover(name, true) end
				end)
			end
			addon.variables.minimapButtonMouseoverHooked = true
		end
	end
	if addon.functions.applyMinimapButtonMouseover then addon.functions.applyMinimapButtonMouseover() end

	hooksecurefunc(LDBIcon, "Show", function(self, name)
		if addon.db["enableMinimapButtonBin"] then
			if nil ~= addon.variables.bagButtonState[name] then addon.variables.bagButtonState[name] = true end
			addon.functions.gatherMinimapButtons()
			addon.functions.LayoutButtons()
		end
	end)

	hooksecurefunc(LDBIcon, "Hide", function(self, name)
		if addon.db["enableMinimapButtonBin"] then
			addon.variables.bagButtonState[name] = false
			addon.functions.gatherMinimapButtons()
			addon.functions.LayoutButtons()
		end
	end)

	local radioRows = {}
	local maxTextWidth = 0
	local rowHeight = 28 -- Höhe pro Zeile (Font + etwas Puffer)
	local totalRows = 0

	function addon.functions.updateLootspecIcon()
		if not LDBIcon or not LDBIcon:IsRegistered(addonName .. "_LootSpec") then return end

		local _, specIcon

		local curSpec = C_SpecializationInfo.GetSpecialization()

		if GetLootSpecialization() == 0 and curSpec then
			_, _, _, specIcon = GetSpecializationInfoForClassID(addon.variables.unitClassID, curSpec)
		else
			_, _, _, specIcon = GetSpecializationInfoByID(GetLootSpecialization())
		end

		local button = LDBIcon.objects[addonName .. "_LootSpec"]
		if button and button.icon and specIcon then button.icon:SetTexture(specIcon) end
	end

	local function UpdateRadioSelection()
		local lootSpecID = GetLootSpecialization() or 0
		for _, row in ipairs(radioRows) do
			row.radio:SetChecked(row.specId == lootSpecID)
		end
	end

	local function CreateRadioRow(parent, specId, specName, index)
		totalRows = totalRows + 1

		local row = CreateFrame("Button", "MyRadioRow" .. index, parent, "BackdropTemplate")
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		row:GetHighlightTexture():SetAlpha(0.3)

		row.radio = CreateFrame("CheckButton", "$parentRadio", row, "UIRadioButtonTemplate")
		row.radio:SetPoint("LEFT", row, "LEFT", 4, 0)
		row.radio:SetChecked(false)

		row.radio.text:SetFontObject(GameFontNormalLarge)
		row.radio.text:SetText(specName)

		row:RegisterForClicks("AnyUp")
		row.radio:RegisterForClicks("AnyUp")

		local textWidth = row.radio.text:GetStringWidth()
		if textWidth > maxTextWidth then maxTextWidth = textWidth end

		row.specId = specId

		row:SetScript("OnClick", function(self, button)
			if button == "LeftButton" then
				SetLootSpecialization(specId)
			else
				local cur = C_SpecializationInfo.GetSpecialization()
				if index > 0 and cur and cur == index then return end
				C_SpecializationInfo.SetSpecialization(index)
			end
		end)

		row.radio:SetScript("OnClick", function(self, button)
			if button == "LeftButton" then
				SetLootSpecialization(specId)
			else
				local cur = C_SpecializationInfo.GetSpecialization()
				if index > 0 and cur and cur == index then return end
				C_SpecializationInfo.SetSpecialization(index)
			end
		end)

		table.insert(radioRows, row)
		return row
	end

	function addon.functions.removeLootspecframe()
		if LDBIcon:IsRegistered(addonName .. "_LootSpec") then
			local button = LDBIcon.objects[addonName .. "_LootSpec"]
			if button then button:Hide() end
			LDBIcon.objects[addonName .. "_LootSpec"] = nil
		end
		if addon.variables.lootSpec then
			addon.variables.lootSpec:SetParent(nil)
			addon.variables.lootSpec:SetScript("OnEvent", nil)
			addon.variables.lootSpec:Hide()
			addon.variables.lootSpec = nil
		end
	end

	local function hoverCheckHide(frame)
		if frame and frame:IsVisible() then
			if not MouseIsOver(frame) then
				frame:Hide()
			else
				C_Timer.After(1, function() hoverCheckHide(frame) end)
			end
		end
	end

	function addon.functions.createLootspecFrame()
		totalRows = 0
		radioRows = {}
		local lootSpec = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		lootSpec:SetPoint("CENTER")
		lootSpec:SetSize(200, 200) -- Erstmal ein Dummy-Wert, wir passen es später an
		lootSpec:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		lootSpec:SetBackdropColor(0, 0, 0, 0.4)
		lootSpec:SetBackdropBorderColor(1, 1, 1, 1)
		addon.variables.lootSpec = lootSpec
		lootSpec:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
		lootSpec:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		lootSpec:SetScript("OnEvent", function(self, event)
			if event == "ACTIVE_TALENT_GROUP_CHANGED" then
				addon.functions.removeLootspecframe()
				addon.functions.createLootspecFrame()
			end
			addon.functions.updateLootspecIcon()
			UpdateRadioSelection()
		end)

		local container = CreateFrame("Frame", nil, lootSpec, "BackdropTemplate")
		container:SetPoint("TOPLEFT", 10, -10)
		if nil == C_SpecializationInfo.GetSpecialization() then return end

		local _, curSpecName = GetSpecializationInfoForClassID(addon.variables.unitClassID, C_SpecializationInfo.GetSpecialization())
		local totalSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(addon.variables.unitClassID)
		local row = CreateRadioRow(container, 0, string.format(LOOT_SPECIALIZATION_DEFAULT, curSpecName), 0)
		for i = 1, totalSpecs do
			local specID, specName, _, specIcon = GetSpecializationInfoForClassID(addon.variables.unitClassID, i)
			CreateRadioRow(container, specID, specName, i)
		end

		for i, row in ipairs(radioRows) do
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(i - 1) * rowHeight)
			row:SetSize(maxTextWidth + 40, rowHeight)
		end

		local finalHeight = #radioRows * rowHeight + 20
		local finalWidth = math.max(maxTextWidth + 40, 150)

		container:SetSize(finalWidth, finalHeight)
		lootSpec:SetSize(finalWidth + 20, finalHeight + 20)
		lootSpec:SetClampedToScreen(true)

		local iconData = {
			type = "launcher",
			icon = "Interface\\ICONS\\INV_Misc_QuestionMark", -- irgendein Icon
			label = addonName .. "_LootSpec",
			OnEnter = function(self)
				if addon.variables.lootSpec then
					positionBagFrame(addon.variables.lootSpec, LDBIcon.objects[addonName .. "_LootSpec"])
					addon.variables.lootSpec:Show()
				end
			end,
			OnLeave = function(self)
				C_Timer.After(1, function() hoverCheckHide(addon.variables.lootSpec) end)
			end,
		}

		LDB:NewDataObject(addonName .. "_LootSpec", iconData)
		LDBIcon:Register(addonName .. "_LootSpec", iconData, addon.db["lootspec_quickswitch"])

		UpdateRadioSelection()
		lootSpec:Hide()
		addon.functions.updateLootspecIcon()
	end

	if addon.db["enableLootspecQuickswitch"] then addon.functions.createLootspecFrame() end
	if addon.InstanceDifficulty and addon.InstanceDifficulty.SetEnabled then addon.InstanceDifficulty:SetEnabled(addon.db["showInstanceDifficulty"]) end
	if addon.DungeonJournalLootSpec and addon.DungeonJournalLootSpec.SetEnabled then addon.DungeonJournalLootSpec:SetEnabled(addon.db["dungeonJournalLootSpecIcons"]) end
end

function addon.functions.createInstantCatalystButton()
	if not ItemInteractionFrame or EnhanceQoLInstantCatalyst then return end

	local parent = ItemInteractionFrame.ButtonFrame or ItemInteractionFrame
	local anchor = ItemInteractionFrame.TopTileStreaks

	local button = CreateFrame("Button", "EnhanceQoLInstantCatalyst", parent, "BackdropTemplate")
	button:SetSize(32, 32)
	button:SetEnabled(false)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexture("Interface\\AddOns\\EnhanceQoL\\Icons\\InstantCatalyst.tga")
	button.icon = icon

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(L["Instant Catalyst"])
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

	if anchor then
		button:SetPoint("RIGHT", anchor, "RIGHT", -2, 0)
	else
		button:SetPoint("BOTTOM", parent, "BOTTOM", 0, 4)
	end

	button:SetScript("OnClick", function() C_ItemInteraction.PerformItemInteraction() end)

	ItemInteractionFrame:HookScript("OnShow", function()
		button:SetEnabled(false)
		button.icon:SetDesaturated(true)
	end)
end

function addon.functions.toggleInstantCatalystButton(value)
	if not C_AddOns.IsAddOnLoaded("Blizzard_ItemInteractionUI") then return end
	if not ItemInteractionFrame then return end

	if value then
		if not EnhanceQoLInstantCatalyst then addon.functions.createInstantCatalystButton() end
		if EnhanceQoLInstantCatalyst then
			EnhanceQoLInstantCatalyst:Show()
			if ItemInteractionFrame:IsShown() then
				if not ItemInteractionFrame.ButtonFrame.ActionButton:IsEnabled() then
					EnhanceQoLInstantCatalyst:SetEnabled(false)
					EnhanceQoLInstantCatalyst.icon:SetDesaturated(true)
				else
					EnhanceQoLInstantCatalyst:SetEnabled(true)
					EnhanceQoLInstantCatalyst.icon:SetDesaturated(false)
				end
			end
		end
	elseif EnhanceQoLInstantCatalyst then
		EnhanceQoLInstantCatalyst:Hide()
	end
end

local function initCharacter() addon.functions.initItemInventory() end

local function OpenSettingsRoot()
	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter() end
end

addon.functions.OpenSettingsRoot = OpenSettingsRoot

function addon.functions.checkReloadFrame()
	if addon.variables.requireReload == false then return end
	local reloadReason = L["bReloadInterface"] or L["tReloadInterface"] or (_G.RELOADUI or "Reload UI")
	local configApp = addon.ConfigApp
	if configApp and configApp.MarkReloadPending then configApp:MarkReloadPending(reloadReason) end
	if addon.variables.reloadPopupDismissed and configApp and configApp.IsReloadPending and configApp:IsReloadPending() then return end
	if _G["ReloadUIPopup"] and _G["ReloadUIPopup"]:IsShown() then return end

	if _G["ReloadUIPopup"] then
		_G["ReloadUIPopup"]:Show()
		return
	end
	local reloadFrame = CreateFrame("Frame", "ReloadUIPopup", UIParent, "BasicFrameTemplateWithInset")
	reloadFrame:SetFrameStrata("TOOLTIP")
	reloadFrame:SetSize(500, 120) -- Breite und Höhe
	reloadFrame:SetPoint("TOP", UIParent, "TOP", 0, -200) -- Zentriert auf dem Bildschirm

	reloadFrame.title = reloadFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	reloadFrame.title:SetPoint("TOP", reloadFrame, "TOP", 0, -6)
	reloadFrame.title:SetText(L["tReloadInterface"])

	reloadFrame.infoText = reloadFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	reloadFrame.infoText:SetPoint("CENTER", reloadFrame, "CENTER", 0, 10)
	reloadFrame.infoText:SetText(L["bReloadInterface"])

	local reloadButton = CreateFrame("Button", nil, reloadFrame, "GameMenuButtonTemplate")
	reloadButton:SetSize(120, 30)
	reloadButton:SetPoint("BOTTOMLEFT", reloadFrame, "BOTTOMLEFT", 10, 10)
	reloadButton:SetText(RELOADUI)
	reloadButton:SetScript("OnClick", function() ReloadUI() end)

	local cancelButton = CreateFrame("Button", nil, reloadFrame, "GameMenuButtonTemplate")
	cancelButton:SetSize(120, 30)
	cancelButton:SetPoint("BOTTOMRIGHT", reloadFrame, "BOTTOMRIGHT", -10, 10)
	cancelButton:SetText(CANCEL)
	cancelButton:SetScript("OnClick", function()
		reloadFrame:Hide()
		addon.variables.requireReload = false -- Keep the requirement visible through the config-center reload button.
		addon.variables.reloadPopupDismissed = true
		if configApp and configApp.MarkReloadPending then configApp:MarkReloadPending(reloadReason) end
	end)

	reloadFrame:Show()
end

local function CreateUI()
	local function QuickMenuGenerator(_, root)
		local first = true
		local function DoDevider()
			if not first then
				root:CreateDivider()
			else
				first = false
			end
		end
		if addon.db["enableLootToastFilter"] then
			first = false
			root:CreateTitle(L["SettingsLootHeaderToasts"])
			root:CreateButton(L["SettingsLootAddInclude"], function() local dialog = StaticPopup_Show("EQOL_LOOT_INCLUDE_ADD") end)
			root:CreateButton(OPTIONS, function()
				if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter("general.loot", "enableLootToastFilter") end
			end)
		end

		DoDevider()
		root:CreateTitle(L["DataPanel"])
		root:CreateButton(L["SettingsDataPanelCreate"], function() local dialog = StaticPopup_Show("EQOL_CREATE_DATAPANEL") end)

		if addon.db["enableChatHistory"] and addon.ChatIM and addon.ChatIM.ChannelHistory then
			DoDevider()
			root:CreateButton(L["CH_TITLE_HISTORY"], function()
				if addon.ChatIM.ChannelHistory.ToggleWindow then addon.ChatIM.ChannelHistory:ToggleWindow() end
			end)
		end

		if addon.db["enableChatIM"] and addon.ChatIM and addon.ChatIM.GetOpenTabs then
			DoDevider()
			local chatLabel = L["Instant Chats"] or "Instant Chats"
			local chatMenu = root:CreateButton(chatLabel)
			local openTabs = addon.ChatIM:GetOpenTabs()
			local windowShown = addon.ChatIM.widget and addon.ChatIM.widget.frame and addon.ChatIM.widget.frame:IsShown()

			if #openTabs > 0 then
				local toggleLabel = ((windowShown and (HIDE or "Hide")) or (SHOW or "Show")) .. " " .. chatLabel
				chatMenu:CreateButton(toggleLabel, function()
					if addon.ChatIM.widget and addon.ChatIM.widget.frame and addon.ChatIM.widget.frame:IsShown() then
						addon.ChatIM:HideWindow()
					else
						addon.ChatIM:FocusConversation(openTabs[1].value)
					end
					return MenuResponse and MenuResponse.Close
				end)
				if chatMenu.CreateDivider then chatMenu:CreateDivider() end
				for _, tab in ipairs(openTabs) do
					chatMenu:CreateButton(tab.label, function()
						addon.ChatIM:FocusConversation(tab.value, true)
						return MenuResponse and MenuResponse.Close
					end)
				end
			else
				local emptyButton = chatMenu:CreateButton(L["ChatIMMenuNoOpenChats"] or "No open chats")
				if emptyButton and emptyButton.SetEnabled then emptyButton:SetEnabled(false) end
			end
		end

		local addonProfileNames = {}
		if EnhanceQoLDB and type(EnhanceQoLDB.profiles) == "table" then
			for profileName in pairs(EnhanceQoLDB.profiles) do
				if type(profileName) == "string" and profileName ~= "" then addonProfileNames[#addonProfileNames + 1] = profileName end
			end
			table.sort(addonProfileNames)
		end

		local ufProfiles = addon.Aura and addon.Aura.UF and addon.Aura.UF.Profiles
		local ufProfileNames = {}
		if ufProfiles and ufProfiles.GetSortedNames then ufProfileNames = ufProfiles.GetSortedNames() end

		if #addonProfileNames > 0 or #ufProfileNames > 0 then
			DoDevider()
			root:CreateTitle(L["Profiles"] or "Profiles")

			if #addonProfileNames > 0 then
				local menu = root:CreateButton(L["ProfileMenuTitle"] or "Addon profile")
				local guid = UnitGUID("player")
				local activeName = guid and EnhanceQoLDB.profileKeys and EnhanceQoLDB.profileKeys[guid] or EnhanceQoLDB.profileGlobal
				if activeName and activeName ~= "" then
					local activeLabel = (L["UFProfileMenuActive"] or "Active: %s"):format(activeName)
					local activeButton = menu:CreateButton(activeLabel)
					if activeButton and activeButton.SetEnabled then activeButton:SetEnabled(false) end
					if menu.CreateDivider then menu:CreateDivider() end
				end
				for _, profileName in ipairs(addonProfileNames) do
					menu:CreateRadio(profileName, function()
						local currentGUID = UnitGUID("player")
						local currentName = currentGUID and EnhanceQoLDB.profileKeys and EnhanceQoLDB.profileKeys[currentGUID] or EnhanceQoLDB.profileGlobal
						return currentName == profileName
					end, function()
						local currentGUID = UnitGUID("player")
						if currentGUID then
							EnhanceQoLDB.profileKeys = EnhanceQoLDB.profileKeys or {}
							EnhanceQoLDB.profileKeys[currentGUID] = profileName
							print("|cff00ff98Enhance QoL|r: " .. (L["ProfileSetActiveReload"] or "Switched addon profile to %s. Reloading UI..."):format(profileName))
							ReloadUI()
						end
						return MenuResponse and MenuResponse.Close
					end)
				end
			end

			if #ufProfileNames > 0 then
				local menu = root:CreateButton(L["UFProfileMenuTitle"] or "Unit Frames profile")
				local activeName = ufProfiles.GetActiveName and ufProfiles.GetActiveName()
				if activeName and activeName ~= "" then
					local activeLabel = (L["UFProfileMenuActive"] or "Active: %s"):format(activeName)
					local activeButton = menu:CreateButton(activeLabel)
					if activeButton and activeButton.SetEnabled then activeButton:SetEnabled(false) end
					if menu.CreateDivider then menu:CreateDivider() end
				end
				for _, profileName in ipairs(ufProfileNames) do
					menu:CreateRadio(profileName, function() return (ufProfiles.GetActiveName and ufProfiles.GetActiveName()) == profileName end, function()
						local ok = ufProfiles.SetActiveName and ufProfiles.SetActiveName(profileName, "MINIMAP_MENU")
						if not ok then print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileSetActiveFailed"] or "Could not switch the active Unit Frames profile.")) end
						return MenuResponse and MenuResponse.Close
					end)
				end
			end
		end

		DoDevider()
		root:CreateButton(L["CooldownPanelEditor"] or "Cooldown Panel Editor", function()
			local panels = addon.Aura and addon.Aura.CooldownPanels
			if panels and panels.OpenPreferredEditor then
				panels:OpenPreferredEditor()
			elseif panels and panels.OpenBlizzardEditor then
				panels:OpenBlizzardEditor()
			end
		end)
	end

	-- Datenobjekt fr den Minimap-Button
	local EnhanceQoLLDB = LDB:NewDataObject("EnhanceQoL", {
		type = "launcher",
		text = addonName,
		icon = "Interface\\AddOns\\" .. addonName .. "\\Icons\\Icon.tga", -- Hier kannst du dein eigenes Icon verwenden
		OnClick = function(_, msg)
			if msg == "LeftButton" then
				OpenSettingsRoot()
			else
				MenuUtil.CreateContextMenu(UIParent, QuickMenuGenerator)
			end
		end,
		OnTooltipShow = function(tt)
			tt:AddLine(addonName)
			tt:AddLine(L["Left-Click to show options"])
		end,
	})
	-- Toggle Minimap Button based on settings
	LDBIcon:Register(addonName, EnhanceQoLLDB, EnhanceQoLDB)

	-- Register to addon compartment
	AddonCompartmentFrame:RegisterAddon({
		text = "Enhance QoL",
		icon = "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga",
		notCheckable = true,
		func = function(button, menuInputData, menu) OpenSettingsRoot() end,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip) tooltip:SetText(L["Left-Click to show options"]) end)
		end,
		funcOnLeave = function(button) MenuUtil.HideTooltip(button) end,
	})
end

local ensureClassResourceHideHook

local function updateClassResourceVisibility()
	if not addon.db then return end
	local ufActive = addon.functions.IsEQoLUnitFrameEnabled and addon.functions.IsEQoLUnitFrameEnabled("player")
	local _, classTag = UnitClass("player")
	if not classTag then return end
	if ensureClassResourceHideHook then ensureClassResourceHideHook() end

	local function apply(frame, hideKey)
		if not frame then return end
		if addon.db[hideKey] and not ufActive then frame:Hide() end
	end

	if classTag == "DEATHKNIGHT" then
		apply(RuneFrame, "deathknight_HideRuneFrame")
	elseif classTag == "DRUID" then
		apply(DruidComboPointBarFrame, "druid_HideComboPoint")
	elseif classTag == "EVOKER" then
		apply(EssencePlayerFrame, "evoker_HideEssence")
	elseif classTag == "MONK" then
		apply(MonkHarmonyBarFrame, "monk_HideHarmonyBar")
	elseif classTag == "ROGUE" then
		apply(RogueComboPointBarFrame, "rogue_HideComboPoint")
	elseif classTag == "PALADIN" then
		apply(PaladinPowerBarFrame, "paladin_HideHolyPower")
	elseif classTag == "WARLOCK" then
		apply(WarlockPowerFrame, "warlock_HideSoulShardBar")
	end
end

addon.functions.UpdateClassResourceVisibility = updateClassResourceVisibility

local classResourceHideHooks = {}
local classResourceHideConfig = {
	DEATHKNIGHT = { frameName = "RuneFrame", hideKey = "deathknight_HideRuneFrame" },
	DRUID = { frameName = "DruidComboPointBarFrame", hideKey = "druid_HideComboPoint" },
	EVOKER = { frameName = "EssencePlayerFrame", hideKey = "evoker_HideEssence" },
	MONK = { frameName = "MonkHarmonyBarFrame", hideKey = "monk_HideHarmonyBar" },
	ROGUE = { frameName = "RogueComboPointBarFrame", hideKey = "rogue_HideComboPoint" },
	PALADIN = { frameName = "PaladinPowerBarFrame", hideKey = "paladin_HideHolyPower" },
	WARLOCK = { frameName = "WarlockPowerFrame", hideKey = "warlock_HideSoulShardBar" },
}

local function isPlayerUFActive() return addon.functions.IsEQoLUnitFrameEnabled and addon.functions.IsEQoLUnitFrameEnabled("player") end

local function shouldHideClassResource(hideKey) return addon.db and addon.db[hideKey] and not isPlayerUFActive() end

ensureClassResourceHideHook = function()
	local _, classTag = UnitClass("player")
	local cfg = classTag and classResourceHideConfig[classTag]
	if not cfg or not addon.db or not addon.db[cfg.hideKey] then return end
	if classResourceHideHooks[cfg.hideKey] then return end
	local frame = _G[cfg.frameName]
	if not frame then return end
	classResourceHideHooks[cfg.hideKey] = true
	hooksecurefunc(frame, "Show", function(self)
		if shouldHideClassResource(cfg.hideKey) then self:Hide() end
	end)
end

local function setAllHooks()
	updateClassResourceVisibility()

	if TotemFrame then
		local _, classTag = UnitClass("player")
		local classname = classTag and string.lower(classTag)
		local hideKey = classname and (classname .. "_HideTotemBar")
		TotemFrame:HookScript("OnShow", function(self)
			if hideKey and addon.db and addon.db[hideKey] then self:Hide() end
		end)
		if hideKey and addon.db and addon.db[hideKey] then TotemFrame:Hide() end
	end

	local ignoredApplicants = {}
	local function isSecret(value)
		local issecretvalue = _G.issecretvalue
		local issecrettable = _G.issecrettable
		if issecretvalue and issecretvalue(value) then return true end
		if issecrettable and issecrettable(value) then return true end
		return false
	end

	local function hasApplicantRestrictions()
		return addon.functions
			and addon.functions.isRestrictedContent
			and addon.functions.isRestrictedContent() == true
	end

	local function getApplicantPrimaryName(applicantID)
		if hasApplicantRestrictions() then return nil end
		if isSecret(applicantID) or not (C_LFGList and C_LFGList.GetApplicantMemberInfo) then return nil end
		local name = C_LFGList.GetApplicantMemberInfo(applicantID, 1)
		if isSecret(name) or type(name) ~= "string" or name == "" then return nil end
		return name
	end

	local function getApplicantDungeonScore(applicantID)
		if hasApplicantRestrictions() then return nil end
		if isSecret(applicantID) or not (C_LFGList and C_LFGList.GetApplicantMemberInfo) then return nil end
		local _, _, _, _, _, _, _, _, _, _, _, dungeonScore = C_LFGList.GetApplicantMemberInfo(applicantID, 1)
		if isSecret(dungeonScore) or type(dungeonScore) ~= "number" then return nil end
		return dungeonScore
	end

	local function decorateIgnoredFontString(fs)
		if not (fs and fs.GetText and fs.SetText) then return end
		local ok, text = pcall(fs.GetText, fs)
		if not ok or isSecret(text) or type(text) ~= "string" or text == "" then return end
		if text:find("!!!", 1, true) then return end
		fs:SetText("!!! " .. text .. " !!!")
	end

	local function FlagIgnoredApplicants(applicantIDs)
		if hasApplicantRestrictions() or not addon.functions.IsAdvancedIgnoreEnabled() or isSecret(applicantIDs) then return end
		wipe(ignoredApplicants)
		for _, applicantID in ipairs(applicantIDs) do
			if not isSecret(applicantID) then
				local name = getApplicantPrimaryName(applicantID)
				if name then
					local entry = addon.Ignore:CheckIgnore(name)
					if entry then ignoredApplicants[applicantID] = entry end
				end
			end
		end
	end

	local function ApplyIgnoreHighlight(memberFrame, applicantID)
		if hasApplicantRestrictions() then return end
		if isSecret(applicantID) then return end
		local entry = ignoredApplicants[applicantID]
		if not entry or not memberFrame or not memberFrame.Name then return end
		memberFrame.Name:SetTextColor(1, 0, 0, 1)
		decorateIgnoredFontString(memberFrame.Name)
	end

	local function SortApplicants(applicants)
		if hasApplicantRestrictions() or type(applicants) ~= "table" or isSecret(applicants) then return end
		if addon.db.lfgSortByRio then
			local order = {}
			local scores = {}
			local hasSortableScore = false
			local hasSecretApplicant = false

			for index, applicantID in ipairs(applicants) do
				if isSecret(applicantID) then
					hasSecretApplicant = true
				else
					order[applicantID] = index
					local dungeonScore = getApplicantDungeonScore(applicantID)
					if dungeonScore ~= nil then
						scores[applicantID] = dungeonScore
						hasSortableScore = true
					end
				end
			end

			if not hasSecretApplicant and hasSortableScore then
				table.sort(applicants, function(applicantID1, applicantID2)
					local dungeonScore1 = scores[applicantID1]
					local dungeonScore2 = scores[applicantID2]

					if dungeonScore1 ~= nil and dungeonScore2 ~= nil and dungeonScore1 ~= dungeonScore2 then return dungeonScore1 > dungeonScore2 end
					if dungeonScore1 ~= nil and dungeonScore2 == nil then return true end
					if dungeonScore1 == nil and dungeonScore2 ~= nil then return false end

					return (order[applicantID1] or 0) < (order[applicantID2] or 0)
				end)
			end
		end

		FlagIgnoredApplicants(applicants)
	end

	hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(memberFrame, appID, memberIdx)
		if addon.functions.IsAdvancedIgnoreEnabled() then ApplyIgnoreHighlight(memberFrame, appID) end
	end)

	hooksecurefunc("LFGListApplicationViewer_UpdateResults", function()
		if hasApplicantRestrictions() or not addon.functions.IsAdvancedIgnoreEnabled() or addon.db.lfgSortByRio then return end
		local applicants = C_LFGList.GetApplicants() or {}
		FlagIgnoredApplicants(applicants)
	end)

	-- Highlight group listings where the leader is on the ignore list
	local function ApplyIgnoreHighlightSearch(entry)
		if hasApplicantRestrictions() then return end
		if not addon.functions.IsAdvancedIgnoreEnabled() then return end
		if not entry or not entry.resultID or isSecret(entry.resultID) then return end

		local info = C_LFGList.GetSearchResultInfo(entry.resultID)
		if not info or isSecret(info) or isSecret(info.leaderName) or not info.leaderName then return end

		local ignoreEntry = addon.Ignore:CheckIgnore(info.leaderName)
		if not ignoreEntry then return end

		local function colorString(fs)
			if fs and fs.SetTextColor then fs:SetTextColor(1, 0, 0, 1) end
		end

		colorString(entry.Name)
		colorString(entry.ActivityName)
		decorateIgnoredFontString(entry.Name)
	end

	hooksecurefunc("LFGListSearchEntry_Update", function(entry) ApplyIgnoreHighlightSearch(entry) end)

	hooksecurefunc("LFGListUtil_SortApplicants", SortApplicants)

	initCharacter()
	initMisc()
	initLoot()
	addon.functions.initDungeonFrame()
	addon.functions.initGearUpgrade()
	addon.functions.initUIInput()
	addon.functions.initQuest()
	addon.functions.initDataPanel()
	addon.functions.initProfile()
	addon.functions.initMapNav()
	addon.functions.initUIOptions()
	addon.functions.initActionTracker()
	if addon.GroupTools and addon.GroupTools.functions and addon.GroupTools.functions.InitDB then addon.GroupTools.functions.InitDB() end
	initParty()
	initActionBars()
	initUI()
	initUnitFrame()
	initMap()
	initLootToast()
	initBagsFrame()

	local LSM = LibStub("LibSharedMedia-3.0")
	local lsmSoundDirty = false
	local lsmFontDirty = false
	local lsmStatusbarDirty = false
	local function refreshProgressBarForMedia(bar, mediaType, mediaKey)
		if not (bar and bar.IsEnabled and bar:IsEnabled()) then return end
		if not bar.frame then return end

		local shouldRefresh = false
		if mediaType == "statusbar" then
			local textureKey = bar.GetTextureKey and bar:GetTextureKey() or nil
			local bgTextureKey = bar.GetBackgroundTextureKey and bar:GetBackgroundTextureKey() or nil
			shouldRefresh = mediaKey == textureKey or mediaKey == bgTextureKey
		elseif mediaType == "border" then
			local borderKey = bar.GetBorderTextureKey and bar:GetBorderTextureKey() or nil
			shouldRefresh = mediaKey == borderKey
		elseif mediaType == "font" then
			local fontKey = bar.GetTextFont and bar:GetTextFont() or nil
			shouldRefresh = mediaKey == fontKey
		end

		if shouldRefresh then
			if bar.ApplyAppearance then bar:ApplyAppearance() end
			if bar.UpdateSoon then bar:UpdateSoon() end
		end
	end

	local function refreshExperienceBarForMedia(mediaType, mediaKey) refreshProgressBarForMedia(addon.Aura and addon.Aura.ExperienceBar, mediaType, mediaKey) end

	local function refreshReputationBarForMedia(mediaType, mediaKey) refreshProgressBarForMedia(addon.Aura and addon.Aura.ReputationBar, mediaType, mediaKey) end

	local function refreshHonorBarForMedia(mediaType, mediaKey) refreshProgressBarForMedia(addon.Aura and addon.Aura.HonorBar, mediaType, mediaKey) end

	local function refreshTotalAbsorbTrackerForMedia(mediaType, mediaKey)
		local tracker = addon.Aura and addon.Aura.TotalAbsorbTracker
		if not (tracker and tracker.IsEnabled and tracker:IsEnabled()) then return end
		if not tracker.RefreshAppearance then return end
		local shouldRefresh = false
		if mediaType == "font" then
			local fontKey = tracker.GetTextFontKey and tracker:GetTextFontKey() or nil
			shouldRefresh = mediaKey == fontKey
		elseif mediaType == "border" then
			local borderKey = tracker.GetBorderTextureKey and tracker:GetBorderTextureKey() or nil
			shouldRefresh = mediaKey == borderKey
		end
		if not shouldRefresh then return end
		tracker:RefreshAppearance()
		if tracker.Refresh then tracker:Refresh() end
	end

	local function refreshGCDBarForMedia(mediaType, mediaKey)
		local gcdBar = addon.GCDBar
		if not (gcdBar and gcdBar.OnMediaRegistered) then return end
		gcdBar:OnMediaRegistered(mediaType, mediaKey)
	end

	local function refreshActionTrackerForMedia(mediaType, mediaKey)
		local tracker = addon.ActionTracker
		if not (tracker and tracker.OnMediaRegistered) then return end
		tracker:OnMediaRegistered(mediaType, mediaKey)
	end

	local function refreshContainerActionsForMedia(mediaType, mediaKey)
		local containerActions = addon.ContainerActions
		if not (containerActions and containerActions.OnMediaRegistered) then return end
		containerActions:OnMediaRegistered(mediaType, mediaKey)
	end

	local function refreshBRTrackerForMedia(mediaType)
		if not (addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBRMedia) then return end
		addon.MythicPlus.functions.refreshBRMedia(mediaType)
	end

	local function refreshClassBuffReminderForMedia(mediaType, mediaKey)
		if mediaType ~= "border" then return end
		local reminder = addon.ClassBuffReminder
		if not (reminder and reminder.frame and reminder.GetBorderTextureKey and reminder.InvalidateVisualSettingsCache and reminder.ApplyVisualSettings and reminder.RequestUpdate) then return end
		if reminder:GetBorderTextureKey() ~= mediaKey then return end
		reminder:InvalidateVisualSettingsCache()
		reminder:ApplyVisualSettings()
		reminder:RequestUpdate(true)
	end

	local function refreshDefaultAuraContainersForMedia(mediaType, mediaKey)
		if mediaType ~= "border" and mediaType ~= "font" then return end
		if not (addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions and addon.DefaultAuraContainers.functions.RefreshDefaultAuraIconSkin) then return end
		if not addon.db then return end
		if not (addon.db.skinnerDefaultBuffIconsEnabled == true or addon.db.skinnerDefaultDebuffIconsEnabled == true) then return end

		local sync = addon.db.skinnerDefaultAuraSyncBuffDebuff ~= false
		local function uses(prefix, suffix)
			return addon.db[prefix .. suffix] == mediaKey
		end

		local shouldRefresh
		if mediaType == "border" then
			shouldRefresh = uses("skinnerDefaultAura", "BorderTexture") or (not sync and uses("skinnerDefaultDebuffAura", "BorderTexture"))
		else
			shouldRefresh = uses("skinnerDefaultAura", "DurationFontFace")
				or uses("skinnerDefaultAura", "CountFontFace")
				or (not sync and (uses("skinnerDefaultDebuffAura", "DurationFontFace") or uses("skinnerDefaultDebuffAura", "CountFontFace")))
		end
		if shouldRefresh then addon.DefaultAuraContainers.functions.RefreshDefaultAuraIconSkin() end
	end

	local function refreshSquareMinimapBorderForMedia(mediaType, mediaKey)
		if mediaType ~= "border" then return end
		if not (addon and addon.db and addon.functions and addon.functions.applySquareMinimapBorder) then return end
		local borderTexture = addon.db.squareMinimapBorderTexture
		if type(borderTexture) ~= "string" or borderTexture == "" then borderTexture = "DEFAULT" end
		if borderTexture ~= mediaKey then return end
		addon.functions.applySquareMinimapBorder()
	end

	local function refreshCooldownPanelsForMedia(mediaType)
		if mediaType ~= "statusbar" and mediaType ~= "border" then return end
		local panels = addon.Aura and addon.Aura.CooldownPanels
		if not (panels and panels.RefreshAllPanels) then return end
		if mediaType == "border" and panels.InvalidateAllPanelLayoutShapeCaches then panels:InvalidateAllPanelLayoutShapeCaches() end
		panels:RefreshAllPanels()
		if panels.IsEditorOpen and panels:IsEditorOpen() and panels.RefreshEditor then panels:RefreshEditor() end
	end

	local function refreshGlobalFontConsumers()
		if addon.functions and addon.functions.BumpGlobalFontStateVersion then addon.functions.BumpGlobalFontStateVersion() end
		if ActionBarLabels then
			if ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
			if ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
			if ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end
		if addon.functions and addon.functions.refreshItemLevelDisplays then addon.functions.refreshItemLevelDisplays() end
		if addon.functions and addon.functions.refreshCharacterFrameElementFonts then addon.functions.refreshCharacterFrameElementFonts() end
		if addon.functions and addon.functions.RefreshDefaultNameplateTextStyle then addon.functions.RefreshDefaultNameplateTextStyle() end
		if addon.functions and addon.functions.RefreshQuestTrackerTextStyle then addon.functions.RefreshQuestTrackerTextStyle(true) end
		if addon.CombatText then
			if addon.CombatText.ApplyStyle then addon.CombatText:ApplyStyle() end
			if addon.CombatText.UpdateFrameSize then addon.CombatText:UpdateFrameSize() end
		end
		if addon.GroupTools and addon.GroupTools.functions and addon.GroupTools.functions.RefreshGlobalFont then addon.GroupTools.functions.RefreshGlobalFont() end
		if addon.DataPanel and addon.DataPanel.List and addon.DataPanel.Get then
			for id in pairs(addon.DataPanel.List() or {}) do
				local panel = addon.DataPanel.Get(id)
				if panel and panel.ApplyTextStyle then panel:ApplyTextStyle() end
			end
		end
		if addon.Bags and addon.Bags.functions and addon.Bags.functions.RefreshGlobalFont then addon.Bags.functions.RefreshGlobalFont() end
		if addon.QuickCast and addon.QuickCast.RefreshGlobalFont then addon.QuickCast:RefreshGlobalFont() end
		if addon.InstanceDifficulty and addon.InstanceDifficulty.Update then addon.InstanceDifficulty:Update() end
		if addon.Aura then
			local xpBar = addon.Aura.ExperienceBar
			if xpBar and xpBar.ApplyAppearance then
				xpBar:ApplyAppearance()
				if xpBar.UpdateSoon then xpBar:UpdateSoon() end
			end
			local repBar = addon.Aura.ReputationBar
			if repBar and repBar.ApplyAppearance then
				repBar:ApplyAppearance()
				if repBar.UpdateSoon then repBar:UpdateSoon() end
			end
			local honorBar = addon.Aura.HonorBar
			if honorBar and honorBar.ApplyAppearance then
				honorBar:ApplyAppearance()
				if honorBar.UpdateSoon then honorBar:UpdateSoon() end
			end
			local focusTracker = addon.Aura.FocusInterruptTracker
			if focusTracker and focusTracker.Refresh then focusTracker:Refresh() end
			local tracker = addon.Aura.TotalAbsorbTracker
			if tracker and tracker.IsEnabled and tracker:IsEnabled() and tracker.RefreshAppearance then
				tracker:RefreshAppearance()
				if tracker.Refresh then tracker:Refresh() end
			end
			if addon.Aura.ResourceBars and addon.Aura.ResourceBars.Refresh then addon.Aura.ResourceBars.Refresh() end
			if addon.Aura.CooldownPanels and addon.Aura.CooldownPanels.RefreshAllPanels then addon.Aura.CooldownPanels:RefreshAllPanels() end
			if addon.Aura.UF and addon.Aura.UF.Refresh then addon.Aura.UF.Refresh() end
			if addon.Aura.UF and addon.Aura.UF.GroupFrames and addon.Aura.UF.GroupFrames.RefreshTextStyles then addon.Aura.UF.GroupFrames:RefreshTextStyles() end
		end
		if addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions and addon.DefaultAuraContainers.functions.RefreshDefaultAuraIconSkin then addon.DefaultAuraContainers.functions.RefreshDefaultAuraIconSkin() end
		if addon.functions and addon.functions.applySquareMinimapStats then addon.functions.applySquareMinimapStats(true) end
		if addon.MythicPlus and addon.MythicPlus.functions then
			if addon.MythicPlus.functions.refreshBRMedia then addon.MythicPlus.functions.refreshBRMedia("font") end
			if addon.MythicPlus.functions.refreshBloodlustMedia then addon.MythicPlus.functions.refreshBloodlustMedia("font") end
		end
	end

	addon.functions.RefreshGlobalFontConsumers = refreshGlobalFontConsumers

	local function queueGlobalFontRefresh()
		if lsmFontDirty then return end
		lsmFontDirty = true
		local trigger = C_Timer and C_Timer.After
		if trigger then
			trigger(0.2, function()
				lsmFontDirty = false
				if addon.functions and addon.functions.RefreshGlobalFontConsumers then addon.functions.RefreshGlobalFontConsumers() end
			end)
		else
			lsmFontDirty = false
			if addon.functions and addon.functions.RefreshGlobalFontConsumers then addon.functions.RefreshGlobalFontConsumers() end
		end
	end

	local function refreshResourceBarsForRegisteredStatusbars()
		lsmStatusbarDirty = false
		local resourceBars = addon.Aura and addon.Aura.ResourceBars
		if resourceBars then
			if resourceBars.MarkTextureListDirty then resourceBars.MarkTextureListDirty() end
			if resourceBars.RefreshTextureDropdown then resourceBars.RefreshTextureDropdown() end
			if resourceBars.Refresh then resourceBars.Refresh() end
			local internal = addon.EditModeLib and addon.EditModeLib.internal
			if internal and internal.RequestRefreshSettings then
				internal:RequestRefreshSettings()
			elseif internal and internal.RefreshSettings then
				internal:RefreshSettings()
			end
		end
	end

	local function queueResourceBarStatusbarRefresh()
		if lsmStatusbarDirty then return end
		lsmStatusbarDirty = true
		local trigger = C_Timer and C_Timer.After
		if trigger then
			trigger(0.2, refreshResourceBarsForRegisteredStatusbars)
		else
			refreshResourceBarsForRegisteredStatusbars()
		end
	end

	LSM:RegisterCallback("LibSharedMedia_Registered", function(event, mediaType, ...)
		local mediaKey = ...
		if addon.functions and addon.functions.InvalidateLSMMediaCache and mediaType then addon.functions.InvalidateLSMMediaCache(mediaType) end
		if mediaType == "sound" then
			if not lsmSoundDirty then
				lsmSoundDirty = true
				C_Timer.After(1, function()
					lsmSoundDirty = false
					if addon.ChatIM and addon.ChatIM.BuildSoundTable then addon.ChatIM:BuildSoundTable() end
				end)
			end
		elseif mediaType == "statusbar" then
			-- When new statusbar textures are registered, refresh any UI using them
			queueResourceBarStatusbarRefresh()
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.RefreshPotionTextureDropdown then addon.MythicPlus.functions.RefreshPotionTextureDropdown() end
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.applyPotionBarTexture then addon.MythicPlus.functions.applyPotionBarTexture() end
			refreshExperienceBarForMedia(mediaType, mediaKey)
			refreshReputationBarForMedia(mediaType, mediaKey)
			refreshHonorBarForMedia(mediaType, mediaKey)
			refreshGCDBarForMedia(mediaType, mediaKey)
			refreshCooldownPanelsForMedia(mediaType)
		elseif mediaType == "border" then
			if ActionBarLabels and ActionBarLabels.ResetBorderCache then ActionBarLabels.ResetBorderCache() end
			refreshExperienceBarForMedia(mediaType, mediaKey)
			refreshReputationBarForMedia(mediaType, mediaKey)
			refreshHonorBarForMedia(mediaType, mediaKey)
			refreshTotalAbsorbTrackerForMedia(mediaType, mediaKey)
			refreshGCDBarForMedia(mediaType, mediaKey)
			refreshActionTrackerForMedia(mediaType, mediaKey)
			refreshContainerActionsForMedia(mediaType, mediaKey)
			refreshBRTrackerForMedia(mediaType)
			refreshClassBuffReminderForMedia(mediaType, mediaKey)
			refreshDefaultAuraContainersForMedia(mediaType, mediaKey)
			refreshSquareMinimapBorderForMedia(mediaType, mediaKey)
			refreshCooldownPanelsForMedia(mediaType)
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBloodlustMedia then addon.MythicPlus.functions.refreshBloodlustMedia(mediaType, mediaKey) end
		elseif mediaType == "font" then
			refreshExperienceBarForMedia(mediaType, mediaKey)
			refreshReputationBarForMedia(mediaType, mediaKey)
			refreshHonorBarForMedia(mediaType, mediaKey)
			refreshTotalAbsorbTrackerForMedia(mediaType, mediaKey)
			refreshDefaultAuraContainersForMedia(mediaType, mediaKey)
			refreshBRTrackerForMedia(mediaType)
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.refreshBloodlustMedia then addon.MythicPlus.functions.refreshBloodlustMedia(mediaType, mediaKey) end
			queueGlobalFontRefresh()
		end
	end)

	-- Init modules
	if addon.Aura and addon.Aura.functions then
		if addon.Aura.functions.InitDB then addon.Aura.functions.InitDB() end
	end
	if addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions and addon.DefaultAuraContainers.functions.InitDB then addon.DefaultAuraContainers.functions.InitDB() end
	if addon.Drinks and addon.Drinks.functions then
		if addon.Drinks.functions.InitDrinkMacro then addon.Drinks.functions.InitDrinkMacro() end
		if addon.Drinks.functions.InitFoodReminder then addon.Drinks.functions.InitFoodReminder() end
	end
	if addon.GroupTools and addon.GroupTools.functions and addon.GroupTools.functions.InitState then addon.GroupTools.functions.InitState() end
	if addon.Health and addon.Health.functions and addon.Health.functions.InitHealthMacro then addon.Health.functions.InitHealthMacro() end
	if addon.Flasks and addon.Flasks.functions and addon.Flasks.functions.InitFlaskMacro then addon.Flasks.functions.InitFlaskMacro() end
	if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.InitBuffFoodMacro then addon.BuffFoods.functions.InitBuffFoodMacro() end
	if addon.Mouse and addon.Mouse.functions then
		if addon.Mouse.functions.InitDB then addon.Mouse.functions.InitDB() end
		if addon.Mouse.functions.InitState then addon.Mouse.functions.InitState() end
	end
	if addon.Skinner and addon.Skinner.functions then
		if addon.Skinner.functions.InitDB then addon.Skinner.functions.InitDB() end
	end
	if addon.MythicPlus and addon.MythicPlus.functions then
		if addon.MythicPlus.functions.InitDB then addon.MythicPlus.functions.InitDB() end
		if addon.MythicPlus.functions.InitState then addon.MythicPlus.functions.InitState() end
	end
	if addon.Tooltip and addon.Tooltip.functions then
		if addon.Tooltip.functions.InitDB then addon.Tooltip.functions.InitDB() end
		if addon.Tooltip.functions.InitState then addon.Tooltip.functions.InitState() end
	end
	if addon.Vendor and addon.Vendor.functions then
		if addon.Vendor.functions.InitDB then addon.Vendor.functions.InitDB() end
		if addon.Vendor.functions.InitState then addon.Vendor.functions.InitState() end
		if addon.Vendor.functions.InitSettings then addon.Vendor.functions.InitSettings() end
	end
	if addon.DamageMeter and addon.DamageMeter.InitDB then addon.DamageMeter:InitDB() end
end

addon.variables.gossipClicked = addon.variables.gossipClicked or {}

function addon.functions.isQuestAutomationModifierHeld(modifier)
	if modifier == "SHIFT" then return IsShiftKeyDown() end
	if modifier == "CTRL" then return IsControlKeyDown() end
	if modifier == "ALT" then return IsAltKeyDown() end
	return false
end

function addon.functions.shouldAutoChooseQuest()
	if not addon.db or not addon.db["autoChooseQuest"] then return false end
	local modifier = addon.db["autoChooseQuestModifier"]
	if modifier == "SHIFT" or modifier == "CTRL" or modifier == "ALT" then return addon.functions.isQuestAutomationModifierHeld(modifier) end
	-- Legacy behavior: allow auto questing unless Shift is held
	return not IsShiftKeyDown()
end

function addon.functions.selectGossipOption(optionInfo)
	if not optionInfo then return false end
	if optionInfo.orderIndex then
		C_GossipInfo.SelectOptionByIndex(optionInfo.orderIndex)
		return true
	end
	if optionInfo.gossipOptionID then
		C_GossipInfo.SelectOption(optionInfo.gossipOptionID)
		return true
	end
	return false
end

function addon.functions.isQuestAutomationIgnoredNPC()
	local ignored = addon.db and addon.db["ignoredQuestNPC"]
	local npcId = addon.functions.getIDFromGUID(UnitGUID("npc"))
	return npcId and type(ignored) == "table" and ignored[npcId] ~= nil
end

function addon.functions.shouldSkipAutoAcceptQuest(questID)
	if not questID or not addon.db then return true end
	if addon.db["ignoreDailyQuests"] and addon.functions.IsQuestRepeatableType(questID) then return true end
	if addon.db["ignoreTrivialQuests"] and C_QuestLog.IsQuestTrivial(questID) then return true end
	if addon.db["ignoreWarbandCompleted"] and C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then return true end
	return false
end

function addon.functions.autoAcceptQuestDataRequired()
	return addon.db and (addon.db["ignoreDailyQuests"] or addon.db["ignoreTrivialQuests"] or addon.db["ignoreWarbandCompleted"])
end

function addon.functions.isQuestDataReady(questID)
	if not questID then return false end
	local questLevel = C_QuestLog.GetQuestDifficultyLevel(questID)
	return questLevel ~= nil and questLevel ~= 0
end

function addon.functions.tryAutoAcceptQuest(questID)
	if not questID or not addon.functions.shouldAutoChooseQuest() then return false end
	if GetQuestID() ~= questID then return false end
	if addon.functions.isQuestAutomationIgnoredNPC() then return false end
	if addon.functions.shouldSkipAutoAcceptQuest(questID) then return false end

	AcceptQuest()
	if QuestFrame:IsShown() then QuestFrame:Hide() end
	return true
end

function loadMain()
	CreateUI()

	-- Schleife zur Erzeugung der Checkboxen
	addon.checkboxes = {}
	-- addon.db = EnhanceQoLDB
	addon.variables.acceptQuestID = {}

	setAllHooks()

	-- Slash-Command hinzufügen
	if addon.functions and addon.functions.SetSlashCommandAlias then
		addon.functions.SetSlashCommandAlias("ENHANCEQOL", 1, "/eqol")
	else
		SLASH_ENHANCEQOL1 = "/eqol"
	end
	SlashCmdList["ENHANCEQOL"] = function(msg)
		msg = tostring(msg or "")
		if msg:match("^aag%s*(%d+)$") then
			local id = tonumber(msg:match("^aag%s*(%d+)$")) -- Extrahiere die ID
			if id then
				addon.db["autogossipID"][id] = true
				print(ADD, "ID: ", id)
			else
				print("|cffff0000Invalid input! Please provide a ID|r")
			end
		elseif msg:match("^rag%s*(%d+)$") then
			local id = tonumber(msg:match("^rag%s*(%d+)$")) -- Extrahiere die ID
			if id then
				if addon.db["autogossipID"][id] then
					addon.db["autogossipID"][id] = nil
					print(REMOVE, "ID: ", id)
				end
			else
				print("|cffff0000Invalid input! Please provide a ID|r")
			end
		elseif msg == "lag" then
			local options = C_GossipInfo.GetOptions()
			if #options > 0 then
				for _, v in pairs(options) do
					print(v.gossipOptionID, v.name)
				end
			end
		elseif msg == "lcid" then
			for i = 1, 600, 1 do
				local name, id = C_ChallengeMode.GetMapUIInfo(i)
				if name then print(name, id) end
			end
		elseif msg == "cid" then
			if not (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo) then return end
			local ids = C_ChallengeMode.GetMapTable() or {}
			table.sort(ids)
			for _, challengeMapID in ipairs(ids) do
				local name = C_ChallengeMode.GetMapUIInfo(challengeMapID)
				if name then print(challengeMapID, name) end
			end
		elseif msg == "rq" then
			if addon.Query and addon.Query.frame then addon.Query.frame:Show() end
		elseif msg:match("^hbp") then
			if InCombatLockdown and InCombatLockdown() then return end

			local kind = "raid"
			local arg = msg:match("^hbp%s+(%S+)")
			arg = arg and arg:lower() or ""
			if arg == "party" or arg == "p" then kind = "party" end
			if arg == "raid" or arg == "r" then kind = "raid" end

			local function openHealerBuffEditor()
				local UF = addon.Aura and addon.Aura.UF
				local editor = UF and UF.GroupFramesHealerBuffEditor
				if editor and editor.Toggle then
					editor:Toggle(kind)
					return
				end
				local GF = UF and UF.GroupFrames
				if GF and GF.ToggleHealerBuffPlacementEditor then GF:ToggleHealerBuffPlacementEditor(kind) end
			end

			openHealerBuffEditor()
		else
			OpenSettingsRoot()
		end
	end
end

-- Erstelle ein Frame f��r Events
local frameLoad = CreateFrame("Frame")
local COPPER_PER_GOLD = 10000

function addon.functions.AutoSyncWarbandGold()
	local privateDB = getPrivateDB()
	if not privateDB["autoWarbandGold"] then return end
	if not C_Bank or not Enum or not Enum.BankType or not Enum.BankType.Account then return end

	local bankType = Enum.BankType.Account
	if not C_Bank.DoesBankTypeSupportMoneyTransfer or not C_Bank.DoesBankTypeSupportMoneyTransfer(bankType) then return end
	if not C_Bank.CanUseBank or not C_Bank.CanUseBank(bankType) then return end

	local targetGold = tonumber(privateDB["autoWarbandGoldTargetGold"]) or 0
	local playerGuid = UnitGUID("player")
	local ignoredCharacters = privateDB["autoWarbandGoldIgnoredCharacters"]
	if type(ignoredCharacters) == "table" and playerGuid and ignoredCharacters[playerGuid] == true then return end
	local perCharacterTargets = privateDB["autoWarbandGoldPerCharacter"]
	if type(perCharacterTargets) == "table" and playerGuid and perCharacterTargets[playerGuid] ~= nil then targetGold = tonumber(perCharacterTargets[playerGuid]) or targetGold end
	if targetGold < 0 then targetGold = 0 end
	local targetCopper = math.floor((targetGold * COPPER_PER_GOLD) + 0.5)
	local playerMoney = GetMoney() or 0

	if playerMoney > targetCopper then
		if not (C_Bank.CanDepositMoney and C_Bank.DepositMoney and C_Bank.CanDepositMoney(bankType)) then return end
		local amountToDeposit = playerMoney - targetCopper
		if amountToDeposit <= 0 then return end
		C_Bank.DepositMoney(bankType, amountToDeposit)
		print((L["autoWarbandGoldDeposited"] or "Deposited %s to Warband bank."):format(addon.functions.formatMoney(amountToDeposit)))
		return
	end

	if not privateDB["autoWarbandGoldWithdraw"] then return end
	if playerMoney >= targetCopper then return end
	if not (C_Bank.CanWithdrawMoney and C_Bank.WithdrawMoney and C_Bank.CanWithdrawMoney(bankType)) then return end

	local warbandMoney = C_Bank.FetchDepositedMoney and C_Bank.FetchDepositedMoney(bankType) or 0
	local amountToWithdraw = math.min(targetCopper - playerMoney, warbandMoney)
	if amountToWithdraw <= 0 then return end

	C_Bank.WithdrawMoney(bankType, amountToWithdraw)
	print((L["autoWarbandGoldWithdrawn"] or "Withdrew %s from Warband bank."):format(addon.functions.formatMoney(amountToWithdraw)))
end

local function loadSubAddon(name)
	if not name or name == "" then return false end
	if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name) then return true end

	local loadable, reason = C_AddOns.IsAddOnLoadable(name)
	if loadable or reason == "DEMAND_LOADED" then
		local loaded = C_AddOns.LoadAddOn(name)
		return loaded == true
	end

	return false, reason
end
addon.functions.LoadSubAddon = loadSubAddon

local function applyCurrentExpansionCraftingOrdersFilter(remainingRetries)
	if not addon.db["alwaysUserCurExpCraftingOrders"] then return end
	if not (Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly) then return end

	RunNextFrame(function()
		local frame = _G["ProfessionsCustomerOrdersFrame"]
		local browseOrders = frame and frame.BrowseOrders
		local searchBar = browseOrders and browseOrders.SearchBar
		local filterDropdown = searchBar and searchBar.FilterDropdown

		if not filterDropdown or type(filterDropdown.filters) ~= "table" then
			if (remainingRetries or 0) > 0 then applyCurrentExpansionCraftingOrdersFilter((remainingRetries or 0) - 1) end
			return
		end

		filterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
		if filterDropdown.ValidateResetState then filterDropdown:ValidateResetState() end
	end)
end

local eventHandlers = {
	["ACTIVE_PLAYER_SPECIALIZATION_CHANGED"] = function(arg1)
		addon.variables.unitSpec = C_SpecializationInfo.GetSpecialization()
		if addon.variables.unitSpec then
			local specId, specName = C_SpecializationInfo.GetSpecializationInfo(addon.variables.unitSpec)
			addon.variables.unitSpecName = specName
			addon.variables.unitRole = GetSpecializationRole(addon.variables.unitSpec)
			addon.variables.unitSpecId = specId
		end

			if addon.db["enableBagsModule"] ~= true and (addon.db["showIlvlOnBagItems"] or addon.db["showUpgradeArrowOnBagItems"]) then
				addon.functions.updateBags(ContainerFrameCombinedBags)
				for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do
				addon.functions.updateBags(frame)
			end
			if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end
			if addon.Vendor and addon.Vendor.functions and addon.Vendor.functions.refreshBaganatorWidgets then addon.Vendor.functions.refreshBaganatorWidgets() end
		end
	end,
	["ACTIVE_TALENT_GROUP_CHANGED"] = function(arg1)
		local uSpec = C_SpecializationInfo.GetSpecialization()
		if uSpec and uSpec > 0 then
			addon.variables.unitSpec = uSpec
			local specId, specName = C_SpecializationInfo.GetSpecializationInfo(addon.variables.unitSpec)
			addon.variables.unitSpecName = specName
			addon.variables.unitRole = GetSpecializationRole(addon.variables.unitSpec)
			addon.variables.unitSpecId = specId
		end
		if addon.db["enableBagsModule"] ~= true and (addon.db["showIlvlOnBagItems"] or addon.db["showUpgradeArrowOnBagItems"]) then
			addon.functions.updateBags(ContainerFrameCombinedBags)
			for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do
				addon.functions.updateBags(frame)
			end
			if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end
			if addon.Vendor and addon.Vendor.functions and addon.Vendor.functions.refreshBaganatorWidgets then addon.Vendor.functions.refreshBaganatorWidgets() end
		end
	end,
	["ADDON_LOADED"] = function(arg1)
		if arg1 == addonName then
			local legacy = {}
			EnhanceQoLDB = EnhanceQoLDB or {}
			if EnhanceQoLDB and not EnhanceQoLDB.profiles then
				for k, v in pairs(EnhanceQoLDB) do
					legacy[k] = v
				end
				EnhanceQoLDB.profiles = {
					["Default"] = {},
				}
			end

			local function trimProfileName(profileName)
				if type(profileName) ~= "string" then return nil end
				local trimmed = profileName:gsub("^%s+", ""):gsub("%s+$", "")
				if trimmed == "" then return nil end
				return trimmed
			end

			if type(EnhanceQoLDB.profiles) ~= "table" then EnhanceQoLDB.profiles = {} end
			local renamedProfiles = nil
			local function profileHasSavedData(profileData)
				return type(profileData) == "table" and next(profileData) ~= nil
			end
			local function getUniqueProfileName(baseName)
				baseName = trimProfileName(baseName) or "Recovered Profile"
				if not profileHasSavedData(EnhanceQoLDB.profiles[baseName]) then return baseName end
				local index = 2
				local candidate = baseName .. " " .. index
				while profileHasSavedData(EnhanceQoLDB.profiles[candidate]) do
					index = index + 1
					candidate = baseName .. " " .. index
				end
				return candidate
			end
			local function getProfileMigrationTarget(profileName, profileData, normalizedName)
				if normalizedName then
					if normalizedName == profileName then return profileName end
					if not profileHasSavedData(EnhanceQoLDB.profiles[normalizedName]) then return normalizedName end
					return getUniqueProfileName(normalizedName)
				end
				if type(profileData) ~= "table" then return nil end
				if not profileHasSavedData(EnhanceQoLDB.profiles.Default) then return "Default" end
				return getUniqueProfileName("Recovered Profile")
			end
			local function resolveProfileReference(profileName)
				local normalizedName = renamedProfiles and renamedProfiles[profileName] or trimProfileName(profileName)
				if normalizedName and type(EnhanceQoLDB.profiles[normalizedName]) == "table" then return normalizedName end
				return nil
			end
			local function chooseFallbackProfile()
				if type(EnhanceQoLDB.profiles.Default) == "table" then
					if profileHasSavedData(EnhanceQoLDB.profiles.Default) then return "Default" end
				else
					EnhanceQoLDB.profiles.Default = {}
				end

				local foundProfile = nil
				for profileName, profileData in pairs(EnhanceQoLDB.profiles) do
					if profileName ~= "Default" and type(profileName) == "string" and profileName == trimProfileName(profileName) and profileHasSavedData(profileData) then
						if foundProfile then return "Default" end
						foundProfile = profileName
					end
				end
				return foundProfile or "Default"
			end
			local profileNames = {}
			for profileName in pairs(EnhanceQoLDB.profiles) do
				profileNames[#profileNames + 1] = profileName
			end
			for i = 1, #profileNames do
				local profileName = profileNames[i]
				local profileData = EnhanceQoLDB.profiles[profileName]
				local normalizedName = trimProfileName(profileName)
				if type(profileData) ~= "table" and not normalizedName then
					EnhanceQoLDB.profiles[profileName] = nil
				elseif type(profileData) ~= "table" then
					local targetName = getProfileMigrationTarget(profileName, {}, normalizedName)
					EnhanceQoLDB.profiles[targetName] = {}
					EnhanceQoLDB.profiles[profileName] = nil
					renamedProfiles = renamedProfiles or {}
					renamedProfiles[profileName] = targetName
				else
					local targetName = getProfileMigrationTarget(profileName, profileData, normalizedName)
					if targetName and targetName ~= profileName then
						EnhanceQoLDB.profiles[targetName] = profileData
						EnhanceQoLDB.profiles[profileName] = nil
						renamedProfiles = renamedProfiles or {}
						renamedProfiles[profileName] = targetName
					end
				end
			end
			if not next(EnhanceQoLDB.profiles) then EnhanceQoLDB.profiles.Default = {} end

			local defaultProfile = "Default"

			if type(EnhanceQoLDB.profileKeys) ~= "table" then EnhanceQoLDB.profileKeys = {} end
			for key, profileName in pairs(EnhanceQoLDB.profileKeys) do
				local normalizedName = resolveProfileReference(profileName)
				if type(key) == "string" and key ~= "" and normalizedName then
					EnhanceQoLDB.profileKeys[key] = normalizedName
				else
					EnhanceQoLDB.profileKeys[key] = nil
				end
			end
			local name, realm = UnitName("player"), GetRealmName()

			-- check for global profile
			local globalProfile = resolveProfileReference(EnhanceQoLDB.profileGlobal) or chooseFallbackProfile()
			if globalProfile and type(EnhanceQoLDB.profiles[globalProfile]) == "table" then
				EnhanceQoLDB.profileGlobal = globalProfile
				defaultProfile = globalProfile
			else
				EnhanceQoLDB.profileGlobal = defaultProfile
			end

			local playerGUID = UnitGUID("player")
			local legacyProfileKey = name and realm and name .. " - " .. realm
			if playerGUID and EnhanceQoLDB.profileKeys[playerGUID] and type(EnhanceQoLDB.profiles[EnhanceQoLDB.profileKeys[playerGUID]]) == "table" then
				defaultProfile = EnhanceQoLDB.profileKeys[playerGUID]
			elseif legacyProfileKey and EnhanceQoLDB.profileKeys[legacyProfileKey] and type(EnhanceQoLDB.profiles[EnhanceQoLDB.profileKeys[legacyProfileKey]]) == "table" then
				-- Legacy AceDB transform to new model
				if playerGUID then EnhanceQoLDB.profileKeys[playerGUID] = EnhanceQoLDB.profileKeys[legacyProfileKey] end
				EnhanceQoLDB.profileKeys[legacyProfileKey] = nil
				defaultProfile = playerGUID and EnhanceQoLDB.profileKeys[playerGUID] or EnhanceQoLDB.profileGlobal
			else
				defaultProfile = EnhanceQoLDB.profileGlobal
				if playerGUID then EnhanceQoLDB.profileKeys[playerGUID] = defaultProfile end
			end

			if not EnhanceQoLDB.profiles[defaultProfile] or type(EnhanceQoLDB.profiles[defaultProfile]) ~= "table" then EnhanceQoLDB.profiles[defaultProfile] = {} end

			addon.db = EnhanceQoLDB.profiles[defaultProfile]
			if type(EnhanceQoLDB._temp) == "table" then
				EnhanceQoLDB._temp.ufProfileDebug = nil
				EnhanceQoLDB._temp.ufProfileTrace = nil
				if not next(EnhanceQoLDB._temp) then EnhanceQoLDB._temp = nil end
			end
			if type(addon.db._temp) == "table" then
				addon.db._temp.ufProfileDebug = nil
				addon.db._temp.ufProfileTrace = nil
				if not next(addon.db._temp) then addon.db._temp = nil end
			end

			if next(legacy) then
				for k, v in pairs(legacy) do
					if addon.db[k] == nil then addon.db[k] = v end
					EnhanceQoLDB[k] = nil
				end
			end

			if addon.functions.CleanupOldStuff then addon.functions.CleanupOldStuff() end
			if addon.functions.MigratePrivateProfileData then addon.functions.MigratePrivateProfileData(addon.db) end
			if addon.functions.CleanupPrivateProfileData then addon.functions.CleanupPrivateProfileData() end

			loadSubAddon("EnhanceQoLTeleportCompendium")
			loadSubAddon("EnhanceQoLDungeonRaid")
			loadSubAddon("EnhanceQoLChatSocial")
			loadSubAddon("EnhanceQoLSkinner")
			loadSubAddon("EnhanceQoLDamageMeter")
			loadMain()
			EQOL.PersistSignUpNote()
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.InitTeleportCompendium then addon.MythicPlus.functions.InitTeleportCompendium() end

			loadSubAddon("EnhanceQoLResourceBars")
			-- PTR 12.1: Load Blizzard's AuraContainer implementation before the
			-- Unit Frames and Cooldown Panels child-addon runtimes initialize.
			if addon.AuraCompat and addon.AuraCompat.EnsureAuraContainerLoaded then addon.AuraCompat:EnsureAuraContainerLoaded() end
			loadSubAddon("EnhanceQoLUnitFrames")
			loadSubAddon("EnhanceQoLCooldownPanels")
			loadSubAddon("EnhanceQoLBags")
			loadSubAddon("EnhanceQoLVendor")
			loadSubAddon("EnhanceQoLTooltip")
			loadSubAddon("EnhanceQoLSound")
			loadSubAddon("EnhanceQoLClassBuffReminder")
			loadSubAddon("EnhanceQoLMover")
			loadSubAddon("EnhanceQoLQuickActions")
			--[==[@debug@
			loadSubAddon("EnhanceQoLQuery")
			--@end-debug@]==]
			loadSubAddon("EnhanceQoLSharedMedia")

			checkBagIgnoreJunk()
		end
		if arg1 == "FarmHud" then
			if addon.functions.hookFarmHudSquareMinimapBackground then addon.functions.hookFarmHudSquareMinimapBackground() end
			if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
		end
		if arg1 == "Blizzard_ItemInteractionUI" then addon.functions.toggleInstantCatalystButton(addon.db["instantCatalystEnabled"]) end
	end,
	["GOSSIP_CLOSED"] = function()
		addon.variables.gossipClicked = {} -- clear all already clicked gossips
	end,
	["GOSSIP_SHOW"] = function()
		if addon.functions.shouldAutoChooseQuest() then
			if addon.functions.isQuestAutomationIgnoredNPC() then return end

			local options = C_GossipInfo.GetOptions()
			local aQuests = C_GossipInfo.GetAvailableQuests()
			local activeQuests = C_GossipInfo.GetActiveQuests()

			if activeQuests then
				for _, quest in ipairs(activeQuests) do
					if quest.isComplete then
						C_GossipInfo.SelectActiveQuest(quest.questID)
						return
					end
				end
			end

			if #aQuests > 0 then
				for _, quest in ipairs(aQuests) do
					if addon.db["ignoreTrivialQuests"] and quest.isTrivial then
					-- ignore trivial
					elseif addon.db["ignoreDailyQuests"] and (quest.frequency > 0) then
						-- ignore daily/weekly
					elseif addon.db["ignoreWarbandCompleted"] and C_QuestLog.IsQuestFlaggedCompletedOnAccount(quest.questID) then
						-- ignore warband completed
					else
						C_GossipInfo.SelectAvailableQuest(quest.questID)
						return
					end
				end
			end

			if options and #options > 0 then
				for _, optionInfo in ipairs(options) do
					if optionInfo.gossipOptionID and addon.db["autogossipID"][optionInfo.gossipOptionID] then
						addon.functions.selectGossipOption(optionInfo)
						return
					end
				end

				local questOption
				local questOptionCount = 0
				for _, optionInfo in ipairs(options) do
					if _G.FlagsUtil.IsSet(optionInfo.flags, Enum.GossipOptionRecFlags.QuestLabelPrepend) then
						questOption = optionInfo
						questOptionCount = questOptionCount + 1
					end
				end
				if questOptionCount == 1 then
					addon.functions.selectGossipOption(questOption)
					return
				end

				if #options == 1 then
					local onlyOption = options[1]
					local clickKey = onlyOption and (onlyOption.gossipOptionID or onlyOption.orderIndex)
					if onlyOption and clickKey and not addon.variables.gossipClicked[clickKey] then
						addon.variables.gossipClicked[clickKey] = true
						addon.functions.selectGossipOption(onlyOption)
					end
				end
			end
		end
	end,

	["LFG_ROLE_CHECK_SHOW"] = function()
		if addon.db["groupfinderSkipRoleSelect"] and UnitInParty("player") then skipRolecheck() end
	end,
	["LOOT_READY"] = function()
		if addon.db["autoQuickLoot"] then
			local requireShift = addon.db["autoQuickLootWithShift"]
			if (requireShift and IsShiftKeyDown()) or (not requireShift and not IsShiftKeyDown()) then
				for i = 1, GetNumLootItems() do
					C_Timer.After(0.1, function() LootSlot(i) end)
				end
			end
		end
	end,
	["ITEM_INTERACTION_ITEM_SELECTION_UPDATED"] = function(arg1)
		if not ItemInteractionFrame or not ItemInteractionFrame:IsShown() then return end
		if not EnhanceQoLInstantCatalyst then return end
		EnhanceQoLInstantCatalyst:SetEnabled(false)
		EnhanceQoLInstantCatalyst.icon:SetDesaturated(true)
		if arg1 ~= nil then
			local item
			if arg1.bagID and arg1.slotIndex then
				item = ItemLocation:CreateFromBagAndSlot(arg1.bagID, arg1.slotIndex)
			elseif arg1.equipmentSlotIndex then
				item = ItemLocation:CreateFromEquipmentSlot(arg1.equipmentSlotIndex)
			end
			if not item then return end
			local conversionCost = C_ItemInteraction.GetItemConversionCurrencyCost(item)
			if not conversionCost then return end
			if conversionCost.amount > 0 and conversionCost.currencyID ~= 0 then
				local cInfo = C_CurrencyInfo.GetCurrencyInfo(conversionCost.currencyID)
				if not cInfo then return end
				if cInfo.quantity == 0 then return end
			end
			EnhanceQoLInstantCatalyst:SetEnabled(true)
			EnhanceQoLInstantCatalyst.icon:SetDesaturated(false)
		end
	end,
	["DUEL_REQUESTED"] = function()
		if addon.db["blockDuelRequests"] then
			CancelDuel()
			StaticPopup_Hide("DUEL_REQUESTED")
		end
	end,
	["PET_BATTLE_PVP_DUEL_REQUESTED"] = function()
		if addon.db["blockPetBattleRequests"] then
			C_PetBattles.CancelPVPDuel()
			StaticPopup_Hide("PET_BATTLE_PVP_DUEL_REQUESTED")
		end
	end,
	["INVENTORY_SEARCH_UPDATE"] = function()
		if addon.db["enableBagsModule"] ~= true and addon.db["showBagFilterMenu"] then
			RunNextFrame(function()
				addon.functions.updateBags(ContainerFrameCombinedBags)
				for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do
					addon.functions.updateBags(frame)
				end
				if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end
			end)
		end
	end,
	["CONFIRM_SUMMON"] = function()
		if not addon.db["autoAcceptSummon"] then return end
		if UnitAffectingCombat("player") then return end
		local summonInfo = _G.C_SummonInfo
		if not summonInfo or not summonInfo.ConfirmSummon then return end

		RunNextFrame(function()
			if not addon.db or not addon.db["autoAcceptSummon"] then return end
			if UnitAffectingCombat("player") then return end
			local info = _G.C_SummonInfo
			if not info then return end
			if not info.GetSummonConfirmTimeLeft or info.GetSummonConfirmTimeLeft() <= 0 then return end
			if not info.GetSummonConfirmSummoner or not info.GetSummonConfirmSummoner() then return end

			info.ConfirmSummon()
			StaticPopup_Hide("CONFIRM_SUMMON")
			StaticPopup_Hide("CONFIRM_SUMMON_SCENARIO")
			StaticPopup_Hide("CONFIRM_SUMMON_STARTING_AREA")
		end)
	end,
	["RESURRECT_REQUEST"] = function(offerer)
		if not shouldAutoAcceptResurrection(offerer) then return end
		AcceptResurrect()
		StaticPopup_Hide("RESURRECT")
		StaticPopup_Hide("RESURRECT_NO_SICKNESS")
		StaticPopup_Hide("RESURRECT_NO_TIMER")
	end,
	["PARTY_INVITE_REQUEST"] = function(unitName, arg2, arg3, arg4, arg5, arg6, inviterGUID, arg8)
		if addon.db["autoAcceptGroupInvite"] then
			if addon.db["autoAcceptGroupInviteGuildOnly"] then
				local playerRealm = _G.GetNormalizedRealmName and _G.GetNormalizedRealmName()
				if not playerRealm or playerRealm == "" then playerRealm = select(2, UnitFullName("player")) end

				local function normalizeCharacterName(name)
					if type(name) ~= "string" or name == "" then return nil end
					local characterName, realmName = strsplit("-", name, 2)
					if not characterName or characterName == "" then return nil end
					if not realmName or realmName == "" then realmName = playerRealm end
					if not realmName or realmName == "" then return nil end
					return characterName .. "-" .. realmName
				end

				local normalizedInviterName = normalizeCharacterName(unitName)
				local gMember = GetNumGuildMembers()
				if gMember then
					for i = 1, gMember do
						local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
						local matchesGuildMember
						if inviterGUID and guid then
							matchesGuildMember = inviterGUID == guid
						else
							matchesGuildMember = normalizedInviterName ~= nil and normalizeCharacterName(name) == normalizedInviterName
						end
						if matchesGuildMember then
							AcceptGroup()
							StaticPopup_Hide("PARTY_INVITE")
							return
						end
					end
				end
			end
			if addon.db["autoAcceptGroupInviteFriendOnly"] then
				if C_BattleNet.GetGameAccountInfoByGUID(inviterGUID) then
					AcceptGroup()
					StaticPopup_Hide("PARTY_INVITE")
					return
				end
				for i = 1, C_FriendList.GetNumFriends() do
					local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
					if friendInfo.guid == inviterGUID then
						AcceptGroup()
						StaticPopup_Hide("PARTY_INVITE")
						return
					end
				end
			end
			if not addon.db["autoAcceptGroupInviteGuildOnly"] and not addon.db["autoAcceptGroupInviteFriendOnly"] then
				AcceptGroup()
				StaticPopup_Hide("PARTY_INVITE")
				return
			end
		end
		if addon.db["blockPartyInvites"] then
			DeclineGroup()
			StaticPopup_Hide("PARTY_INVITE")
		end
	end,
	["PLAYER_INTERACTION_MANAGER_FRAME_SHOW"] = function(arg1)
		if arg1 == 53 and addon.db["openCharframeOnUpgrade"] then
			if CharacterFrame:IsShown() == false then ToggleCharacter("PaperDollFrame") end
		end
	end,
	["BANKFRAME_OPENED"] = function()
		RunNextFrame(function()
			if addon.functions and addon.functions.AutoSyncWarbandGold then addon.functions.AutoSyncWarbandGold() end
		end)
	end,
	["PLAYER_LOGIN"] = function()
		addon.functions.applyUIScalePreset()

		addon.variables.screenHeight = GetScreenHeight()

		if addon.db["enableMinimapButtonBin"] and addon.functions.toggleButtonSink then addon.functions.toggleButtonSink() end
		if addon.db["actionBarAnchorEnabled"] then RefreshAllActionBarAnchors() end
		addon.variables.unitSpec = C_SpecializationInfo.GetSpecialization()
		if addon.variables.unitSpec then
			local specId, specName = C_SpecializationInfo.GetSpecializationInfo(addon.variables.unitSpec)
			addon.variables.unitSpecName = specName
			addon.variables.unitRole = GetSpecializationRole(addon.variables.unitSpec)
			addon.variables.unitSpecId = specId
		end
		if not addon.variables.maxLevel then addon.variables.maxLevel = GetMaxLevelForPlayerExpansion() end
		addon.variables.isMaxLevel = {}
		addon.variables.isMaxLevel[addon.variables.maxLevel] = true

		local privateDB = getPrivateDB()
		if privateDB["moneyTracker"] then
			privateDB["moneyTracker"][UnitGUID("player")] = {
				name = UnitName("player"),
				realm = GetRealmName(),
				money = GetMoney(),
				class = select(2, UnitClass("player")),
			}
		end
		privateDB["warbandGold"] = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		if addon.ChatIM then addon.ChatIM:BuildSoundTable() end

		-- Timerunner cleanup: remove Durability stream from all DataPanels
		if addon.functions and addon.functions.IsTimerunner and addon.functions.IsTimerunner() then
			if addon.DataPanel and addon.DataPanel.List and addon.DataPanel.RemoveStream then
				local panels = addon.DataPanel.List()
				for id, streams in pairs(panels or {}) do
					for _, s in ipairs(streams or {}) do
						if s == "durability" then pcall(function() addon.DataPanel.RemoveStream(id, "durability") end) end
					end
				end
			end
		end
		if addon.MythicPlus and addon.MythicPlus.functions then
			if addon.MythicPlus.functions.InitSettings then addon.MythicPlus.functions.InitSettings() end
			if addon.MythicPlus.functions.ScheduleTrackerAnchorReapply then addon.MythicPlus.functions.ScheduleTrackerAnchorReapply("PLAYER_LOGIN") end
		end
		if addon.CombatText and addon.CombatText.RefreshAnchor then addon.CombatText:RefreshAnchor() end
	end,
	["PLAYER_MONEY"] = function()
		local privateDB = getPrivateDB()
		if privateDB["moneyTracker"] and privateDB["moneyTracker"][UnitGUID("player")] and privateDB["moneyTracker"][UnitGUID("player")]["money"] then
			privateDB["moneyTracker"][UnitGUID("player")]["money"] = GetMoney()
		end
	end,
	["ACCOUNT_MONEY"] = function()
		local privateDB = getPrivateDB()
		privateDB["warbandGold"] = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
	end,
	["PLAYER_REGEN_ENABLED"] = function()
		if addon.variables then
			if addon.variables.pendingActionBarAnchorRefresh then
				addon.variables.pendingActionBarAnchorRefresh = nil
				RefreshAllActionBarAnchors()
			end
			if addon.variables.pendingPartyFrameScale then
				addon.variables.pendingPartyFrameScale = nil
				addon.functions.updatePartyFrameScale()
			end
			if addon.variables.pendingPartyFrameTitle ~= nil then
				local pending = addon.variables.pendingPartyFrameTitle
				addon.variables.pendingPartyFrameTitle = nil
				addon.functions.togglePartyFrameTitle(pending)
			end
			if addon.variables.pendingExtraActionArtwork then
				addon.variables.pendingExtraActionArtwork = nil
				if addon.functions.ApplyExtraActionArtworkSetting then addon.functions.ApplyExtraActionArtworkSetting() end
			end
		end
	end,
	["QUEST_COMPLETE"] = function()
		if addon.functions.shouldAutoChooseQuest() then
			local numQuestRewards = GetNumQuestChoices()
			if numQuestRewards > 1 then
			elseif numQuestRewards == 1 then
				GetQuestReward(1)
			else
				GetQuestReward()
			end
		end
	end,
	["QUEST_DATA_LOAD_RESULT"] = function(questID, success)
		if not questID or not addon.variables.acceptQuestID[questID] then return end
		addon.variables.acceptQuestID[questID] = nil
		if success == false then return end
		addon.functions.tryAutoAcceptQuest(questID)
	end,
	["QUEST_DETAIL"] = function()
		if addon.functions.shouldAutoChooseQuest() then
			if addon.functions.isQuestAutomationIgnoredNPC() then return end

			local id = GetQuestID()
			if id and id > 0 then
				if addon.functions.autoAcceptQuestDataRequired() and not addon.functions.isQuestDataReady(id) then
					if not addon.variables.acceptQuestID[id] then
						addon.variables.acceptQuestID[id] = true
						C_QuestLog.RequestLoadQuestByID(id)
					end
					return
				end
				addon.functions.tryAutoAcceptQuest(id)
			end
		end
	end,
	["QUEST_GREETING"] = function()
		if addon.functions.shouldAutoChooseQuest() then
			if addon.functions.isQuestAutomationIgnoredNPC() then return end
			for i = 1, GetNumActiveQuests() do
				if select(2, GetActiveTitle(i)) then
					SelectActiveQuest(i)
					return
				end
			end
			for i = 1, GetNumAvailableQuests() do
				if not (addon.db["ignoreTrivialQuests"] and IsAvailableQuestTrivial(i)) then
					SelectAvailableQuest(i)
					return
				end
			end
		end
	end,
	["QUEST_PROGRESS"] = function()
		if addon.functions.shouldAutoChooseQuest() and IsQuestCompletable() then
			if addon.db["ignoreGoldCostQuests"] and GetQuestMoneyToGet() > 0 then return end
			if addon.db["ignoreCurrencyCostQuests"] and GetNumQuestCurrencies() > 0 then return end
			CompleteQuest()
		end
	end,
	["AUCTION_HOUSE_SHOW"] = function()
		addon.variables.auctionHouseOpen = true
		if addon.db["closeBagsOnAuctionHouse"] and not addon.functions.isRestrictedContent() then CloseAllBags() end
		if addon.functions.RefreshAuctionHouseBagFade then addon.functions.RefreshAuctionHouseBagFade() end
		if addon.db["alwaysUserCurExpAuctionHouse"] then
			RunNextFrame(function()
				local filterButton = AuctionHouseFrame.SearchBar.FilterButton
				local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly
				if not filterButton:GetFilters()[filter] then filterButton:ToggleFilter(filter) end
			end)
		end
	end,
	["AUCTION_HOUSE_CLOSED"] = function()
		addon.variables.auctionHouseOpen = false
		if addon.functions.RefreshAuctionHouseBagFade then addon.functions.RefreshAuctionHouseBagFade() end
	end,
	["CRAFTINGORDERS_SHOW_CUSTOMER"] = function() applyCurrentExpansionCraftingOrdersFilter(3) end,
	["CINEMATIC_START"] = function()
		if addon.db["autoCancelCinematic"] and not addon.db["quickSkipCinematic"] then
			if CinematicFrame.isRealCinematic then
				StopCinematic()
			elseif CanCancelScene() then
				CancelScene()
			end
		end
	end,
	["PLAY_MOVIE"] = function()
		if addon.db["autoCancelCinematic"] and not addon.db["quickSkipCinematic"] then MovieFrame:Hide() end
	end,
}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
