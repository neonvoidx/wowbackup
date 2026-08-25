local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local ActionBarLabels = addon.ActionBarLabels
local constants = addon.constants or {}

local NormalizeActionBarVisibilityConfig = addon.functions.NormalizeActionBarVisibilityConfig or function() end
local NormalizeUnitFrameVisibilityConfig = addon.functions.NormalizeUnitFrameVisibilityConfig or function() end
local UpdateActionBarMouseover = addon.functions.UpdateActionBarMouseover or function() end
local UpdateUnitFrameMouseover = addon.functions.UpdateUnitFrameMouseover or function() end
local RefreshAllActionBarAnchors = addon.functions.RefreshAllActionBarAnchors or function() end
local RefreshAllActionBarVisibilityAlpha = addon.functions.RefreshAllActionBarVisibilityAlpha or function() end
local GetActionBarFadeStrength = addon.functions.GetActionBarFadeStrength or function() return 1 end
local GetFrameFadeStrength = addon.functions.GetFrameFadeStrength or function() return 1 end
local GetCooldownViewerFadeStrength = addon.functions.GetCooldownViewerFadeStrength or function() return 1 end
local RefreshAllFrameVisibilityAlpha = addon.functions.RefreshAllFrameVisibilityAlpha or function() end
local GetVisibilityRuleMetadata = addon.functions.GetVisibilityRuleMetadata or function() return {} end
local HasFrameVisibilityOverride = addon.functions.HasFrameVisibilityOverride or function() return false end
local SetCooldownViewerVisibility = addon.functions.SetCooldownViewerVisibility or function() end
local GetCooldownViewerVisibility = addon.functions.GetCooldownViewerVisibility or function() return nil end
local SetSpellActivationOverlayVisibility = addon.functions.SetSpellActivationOverlayVisibility or function() end
local GetSpellActivationOverlayVisibility = addon.functions.GetSpellActivationOverlayVisibility or function() return nil end
local getCVarOptionState = addon.functions.GetCVarOptionState or function() return false end
local setCVarOptionState = addon.functions.SetCVarOptionState or function() end

local ACTION_BAR_FRAME_NAMES = constants.ACTION_BAR_FRAME_NAMES or {}
local ACTION_BAR_ANCHOR_ORDER = constants.ACTION_BAR_ANCHOR_ORDER or {}
local ACTION_BAR_ANCHOR_CONFIG = constants.ACTION_BAR_ANCHOR_CONFIG or {}
local COOLDOWN_VIEWER_FRAMES = constants.COOLDOWN_VIEWER_FRAMES or {}
local COOLDOWN_VIEWER_VISIBILITY_MODES = constants.COOLDOWN_VIEWER_VISIBILITY_MODES
	or {
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
		NONE = "NONE",
		HIDE_WHILE_MOUNTED = "HIDE_WHILE_MOUNTED",
	}
local wipe = wipe
local fontOrder = {}
local borderOrder = {}
local focusInterruptSoundOrder = {}
local nameplateStatusbarOrder = {}
local QUICK_SLOT_BORDER = "Interface\\Buttons\\UI-Quickslot2"
local DEFAULT_NAMEPLATE_FEATURE_KEYS = constants.DEFAULT_NAMEPLATE_FEATURE_KEYS
	or {
		auraClickthrough = "nameplateAuraClickthrough",
		slugOutline = "nameplateSlugOutline",
		textCustomFont = "nameplateTextCustomFont",
		textFont = "nameplateTextFont",
		textOutline = "nameplateTextOutline",
		textSize = "nameplateTextSize",
		friendlyPlayerNamesOnly = "nameplateFriendlyPlayerNamesOnly",
		friendlyPlayerClassColorNames = "nameplateFriendlyPlayerClassColorNames",
		hideFriendlyPlayerRealms = "nameplateHideFriendlyPlayerRealms",
		eliteMarkers = "nameplateEliteMarkers",
		eliteMarkerAnchor = "nameplateEliteMarkerAnchor",
		eliteMarkerSize = "nameplateEliteMarkerSize",
		mobColors = "nameplateMobColors",
		questMarkers = "nameplateQuestMarkers",
		questMarkerAnchor = "nameplateQuestMarkerAnchor",
		questMarkerSize = "nameplateQuestMarkerSize",
		targetMarkers = "nameplateTargetMarkers",
		targetMarkerAtlas = "nameplateTargetMarkerAtlas",
		targetMarkerHideFriendly = "nameplateTargetMarkerHideFriendly",
		targetMarkerSize = "nameplateTargetMarkerSize",
		healthbarTexture = "nameplateHealthbarTexture",
		focusHealthbarTexture = "nameplateFocusHealthbarTexture",
		mobColorFocus = "nameplateMobColorFocus",
		mobColorFocusEnabled = "nameplateMobColorFocusEnabled",
		mobColorBoss = "nameplateMobColorBoss",
		mobColorBossEnabled = "nameplateMobColorBossEnabled",
		mobColorMiniboss = "nameplateMobColorMiniboss",
		mobColorMinibossEnabled = "nameplateMobColorMinibossEnabled",
		mobColorCaster = "nameplateMobColorCaster",
		mobColorCasterEnabled = "nameplateMobColorCasterEnabled",
		mobColorMelee = "nameplateMobColorMelee",
		mobColorMeleeEnabled = "nameplateMobColorMeleeEnabled",
		mobColorNeutral = "nameplateMobColorNeutral",
		mobColorNeutralEnabled = "nameplateMobColorNeutralEnabled",
		mobColorTapped = "nameplateMobColorTapped",
		mobColorTappedEnabled = "nameplateMobColorTappedEnabled",
		mobColorTankMode = "nameplateMobColorTankMode",
		mobColorThreatLost = "nameplateMobColorThreatLost",
		mobColorThreatLostEnabled = "nameplateMobColorThreatLostEnabled",
		mobColorThreatWarning = "nameplateMobColorThreatWarning",
		mobColorThreatWarningEnabled = "nameplateMobColorThreatWarningEnabled",
		mobColorTrivial = "nameplateMobColorTrivial",
		mobColorTrivialEnabled = "nameplateMobColorTrivialEnabled",
		mobColorsInDungeons = "nameplateMobColorsInDungeons",
		mobColorsOutsideDungeons = "nameplateMobColorsOutsideDungeons",
		mobTankMode = "nameplateMobTankMode",
	}

local function getCachedLSMMedia(mediaType)
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType)
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash(mediaType)
	if type(names) == "table" and type(hash) == "table" then return names, hash end
	return {}, {}
end

local function getGlobalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function getGlobalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

addon.db = addon.db or {}
addon.db.actionBarHiddenHotkeys = type(addon.db.actionBarHiddenHotkeys) == "table" and addon.db.actionBarHiddenHotkeys or {}

local function collectRuleOptions(kind)
	local options = {}
	for key, data in pairs(GetVisibilityRuleMetadata() or {}) do
		if data.appliesTo and data.appliesTo[kind] then table.insert(options, {
			value = key,
			text = data.label or key,
			order = data.order or 999,
		}) end
	end
	table.sort(options, function(a, b)
		if a.order == b.order then return a.text < b.text end
		return a.order < b.order
	end)
	return options
end

local function isEQoLUnitEnabled(unit)
	if addon.functions and addon.functions.IsEQoLUnitFrameEnabled then return addon.functions.IsEQoLUnitFrameEnabled(unit) end
	local db = addon.db and addon.db.ufFrames
	if not db then return false end
	if unit == "boss" then
		local bossCfg = db.boss
		if bossCfg and bossCfg.enabled then return true end
		for i = 1, 5 do
			local cfg = db["boss" .. i]
			if cfg and cfg.enabled then return true end
		end
		return false
	end
	local cfg = db[unit]
	return cfg and cfg.enabled == true
end

local function shouldShowBlizzardFrameVisibility(info)
	if not addon.Aura then return true end
	if not info or not info.name then return true end
	if info.name == "PlayerFrame" then return not isEQoLUnitEnabled("player") end
	if info.name == "TargetFrame" then return not isEQoLUnitEnabled("target") end
	if info.name == "FocusFrame" then return not isEQoLUnitEnabled("focus") end
	if info.name == "PetFrame" then return not isEQoLUnitEnabled("pet") end
	if info.name == "BossTargetFrameContainer" then return not isEQoLUnitEnabled("boss") end
	return true
end

local ACTIONBAR_RULE_OPTIONS = collectRuleOptions("actionbar")
local function notifyFrameRuleLocked(label)
	local base = L["visibilityRule_lockedByUF"] or "Visibility is controlled by Enhanced Unit Frames. Disable them to change this setting."
	if label and label ~= "" then base = base .. " (" .. tostring(label) .. ")" end
	print("|cff00ff98Enhance QoL|r: " .. base)
end

local function buildFontDropdown(targetOrder, includeGlobalOption)
	local map = {
		[addon.variables.defaultFont] = L["actionBarFontDefault"] or "Blizzard Font",
	}
	local globalKey = getGlobalFontConfigKey()
	if includeGlobalOption ~= false then map[globalKey] = getGlobalFontConfigLabel() end
	local names, hash = getCachedLSMMedia("font")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
	end
	local list, order = addon.functions.prepareListForDropdown(map)
	wipe(targetOrder)
	if includeGlobalOption ~= false and list[globalKey] then targetOrder[#targetOrder + 1] = globalKey end
	for _, key in ipairs(order) do
		if key ~= globalKey then targetOrder[#targetOrder + 1] = key end
	end
	return list
end

local function buildOverrideFontDropdown() return buildFontDropdown(fontOrder, true) end

local function buildBorderDropdown()
	local map = {}
	local order = {}
	local function add(key, label)
		if not key or key == "" or map[key] then return end
		map[key] = label
		order[#order + 1] = key
	end

	add("DEFAULT", L["actionBarBorderDefault"] or "Default (Blizzard)")
	add(QUICK_SLOT_BORDER, L["actionBarBorderQuickslot"] or "Quickslot (Bartender-style)")

	local names, hash = getCachedLSMMedia("border")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(path, tostring(name)) end
	end

	wipe(borderOrder)
	for i, key in ipairs(order) do
		borderOrder[i] = key
	end
	return map
end

local function buildFocusInterruptSoundDropdown()
	local list, order
	if addon.functions and addon.functions.GetLSMMediaDropdown then
		list, order = addon.functions.GetLSMMediaDropdown("sound", true, "")
	else
		list = { [""] = "" }
		order = { "" }
		local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("sound") or {}
		for i = 1, #names do
			local name = names[i]
			if type(name) == "string" and name ~= "" then
				list[name] = name
				order[#order + 1] = name
			end
		end
	end

	wipe(focusInterruptSoundOrder)
	for i = 1, #(order or {}) do
		focusInterruptSoundOrder[i] = order[i]
	end

	return list or {}, order or focusInterruptSoundOrder
end

local function previewFocusInterruptSound(value)
	if type(value) ~= "string" or value == "" then return end

	local numeric = tonumber(value)
	if numeric and PlaySound then
		PlaySound(numeric, "Master")
		return
	end

	local soundHash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("sound")
	local file = type(soundHash) == "table" and soundHash[value] or nil
	if type(file) == "string" and file ~= "" and PlaySoundFile then PlaySoundFile(file, "Master") end
end

local function getNormalizedFocusInterruptSoundValue()
	local cfg = addon.db and addon.db.focusInterruptTracker
	local sound = cfg and cfg.sound
	local value = sound and sound.file
	if type(value) ~= "string" or value == "" then return "" end

	local soundHash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("sound")
	if type(soundHash) == "table" and type(soundHash[value]) == "string" and soundHash[value] ~= "" then return value end

	return ""
end

local function suppressEventToastFrame(frame)
	if not frame then return end
	if frame.currentDisplayingToast and C_EventToastManager and C_EventToastManager.RemoveCurrentToast then pcall(C_EventToastManager.RemoveCurrentToast) end
	if frame.ReleaseToasts then pcall(frame.ReleaseToasts, frame) end
	frame.currentDisplayingToast = nil
	if frame.StopToasting then
		pcall(frame.StopToasting, frame)
	elseif frame.Hide then
		pcall(frame.Hide, frame)
	end
end

local function ensureEventToastVisibilityHooks()
	local frame = _G.EventToastManagerFrame
	if not frame or frame._eqolEventToastVisibilityHooked then return frame end
	frame._eqolEventToastVisibilityHooked = true
	hooksecurefunc(frame, "DisplayToast", function(self)
		if addon.db and addon.db.hideEventToasts == true then suppressEventToastFrame(self) end
	end)
	return frame
end

function addon.functions.ApplyEventToastVisibility()
	local frame = ensureEventToastVisibilityHooks()
	if not frame then return end

	if addon.db and addon.db.hideEventToasts == true then
		if frame.IsEventRegistered and frame:IsEventRegistered("DISPLAY_EVENT_TOASTS") then frame:UnregisterEvent("DISPLAY_EVENT_TOASTS") end
		suppressEventToastFrame(frame)
	else
		if frame.RegisterEvent and frame.IsEventRegistered and not frame:IsEventRegistered("DISPLAY_EVENT_TOASTS") then frame:RegisterEvent("DISPLAY_EVENT_TOASTS") end
	end
end

local function createActionBarVisibility(category, expandable)
	if #ACTIONBAR_RULE_OPTIONS == 0 then return end

	addon.functions.SettingsCreateHeadline(category, L["visibilityScenarioGroupTitle"] or ACTIONBARS_LABEL, { parentSection = expandable })

	local explain = L["ActionbarVisibilityExplain2"]
	if explain and _G["HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS"] and _G["HUD_EDIT_MODE_MENU"] then
		addon.functions.SettingsCreateText(category, explain:format(_G["HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS"], _G["HUD_EDIT_MODE_MENU"]), { parentSection = expandable })
	end

	local bars, seenVars = {}, {}
	for _, info in ipairs(addon.variables.actionBarNames or {}) do
		if info.var and not seenVars[info.var] then
			table.insert(bars, info)
			seenVars[info.var] = true
		end
	end

	table.sort(bars, function(a, b) return (a.text or a.name or "") < (b.text or b.name or "") end)

	for _, info in ipairs(bars) do
		if info.var and info.name then
			local exp = expandable
			local ABRule = collectRuleOptions("actionbar")

			addon.functions.SettingsCreateMultiDropdown(category, {
				var = info.var .. "_visibility",
				storage = false,
				text = info.text or info.name or info.var,
				desc = L["ActionbarVisibilityRuleSelectionDesc"],
				options = ABRule,
				isSelectedFunc = function(key)
					local cfg = NormalizeActionBarVisibilityConfig(info.var)
					return cfg and cfg[key] == true
				end,
				setSelectedFunc = function(key, shouldSelect)
					local working = addon.db[info.var]
					if type(working) ~= "table" then working = {} end
					if shouldSelect then
						working[key] = true
					else
						working[key] = nil
					end
					local normalized = NormalizeActionBarVisibilityConfig(info.var, working)
					UpdateActionBarMouseover(info.name, normalized, info.var)
				end,
				parentSection = exp,
			})
		end
	end

	addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarMouseoverShowAll",
		text = L["actionBarMouseoverShowAll"] or "Show all action bars on mouseover",
		desc = L["actionBarMouseoverShowAllDesc"] or "When any action bar is hovered, show every action bar that uses the Mouseover rule.",
		func = function(value)
			addon.db.actionBarMouseoverShowAll = value and true or false
			for _, info in ipairs(addon.variables.actionBarNames or {}) do
				if info.var and info.name then
					local normalized = NormalizeActionBarVisibilityConfig(info.var)
					UpdateActionBarMouseover(info.name, normalized, info.var)
				end
			end
			RefreshAllActionBarVisibilityAlpha()
		end,
		parentSection = expandable,
	})

	local function getFadePercent()
		local value = GetActionBarFadeStrength()
		if value < 0 then value = 0 end
		if value > 1 then value = 1 end
		return math.floor((value * 100) + 0.5)
	end

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarFadeStrength",
		text = L["Fade amount"] or "Fade amount",
		desc = L["actionBarFadeStrengthDesc"],
		min = 0,
		max = 100,
		step = 1,
		default = 100,
		get = getFadePercent,
		set = function(val)
			local pct = tonumber(val) or 0
			if pct < 0 then pct = 0 end
			if pct > 100 then pct = 100 end
			addon.db.actionBarFadeStrength = pct / 100
			RefreshAllActionBarVisibilityAlpha(true)
		end,
		parentSection = expandable,
	})
end

local function createAnchorControls(category, expandable)
	if #ACTION_BAR_FRAME_NAMES == 0 then return end

	addon.functions.SettingsCreateHeadline(category, L["actionBarAnchorSectionTitle"] or "Button growth", { parentSection = expandable })

	local anchorToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarAnchorEnabled",
		text = L["actionBarAnchorEnable"] or "Modify Action Bar anchor",
		desc = L["actionBarAnchorEnableDesc"],
		func = function(value)
			addon.db["actionBarAnchorEnabled"] = value and true or false
			if value then
				RefreshAllActionBarAnchors()
			else
				addon.variables.requireReload = true
				addon.functions.checkReloadFrame()
			end
		end,
		parentSection = expandable,
	})
	local warning = L["actionBarAnchorWarning"] or "Warning: Enabling this can cause protected action errors when switching specs or opening Edit Mode."
	addon.functions.SettingsCreateText(category, "|cffff0000" .. warning .. "|r", { parentSection = expandable })

	local anchorOptions = {
		TOPLEFT = L["Top Left"] or "Top Left",
		TOPRIGHT = L["Top Right"] or "Top Right",
		BOTTOMLEFT = L["Bottom Left"] or "Bottom Left",
		BOTTOMRIGHT = L["Bottom Right"] or "Bottom Right",
	}
	local anchorOrder = ACTION_BAR_ANCHOR_ORDER

	for index = 1, #ACTION_BAR_FRAME_NAMES do
		local label
		if L["actionBarAnchorDropdown"] then
			label = L["actionBarAnchorDropdown"]:format(index)
		else
			label = string.format("Action Bar %d button anchor", index)
		end

		local dbKey = "actionBarAnchor" .. index
		local defaultKey = "actionBarAnchorDefault" .. index

		addon.functions.SettingsCreateDropdown(category, {
			var = dbKey,
			text = label,
			list = anchorOptions,
			order = anchorOrder,
			default = addon.db[defaultKey] or ACTION_BAR_ANCHOR_ORDER[1],
			get = function()
				local current = addon.db[dbKey]
				if not current or not ACTION_BAR_ANCHOR_CONFIG[current] then current = addon.db[defaultKey] end
				if not current or not ACTION_BAR_ANCHOR_CONFIG[current] then current = ACTION_BAR_ANCHOR_ORDER[1] end
				return current
			end,
			set = function(key)
				if not ACTION_BAR_ANCHOR_CONFIG[key] then return end
				addon.db[dbKey] = key
				RefreshAllActionBarAnchors()
			end,
			parent = true,
			element = anchorToggle.element,
			parentCheck = function() return anchorToggle.setting and anchorToggle.setting:GetValue() == true end,
			parentSection = expandable,
		})
	end
end

local function createButtonAppearanceControls(category, expandable)
	addon.functions.SettingsCreateHeadline(category, L["actionBarAppearanceHeader"] or "Button appearance", { parentSection = expandable })

	local hideBorders
	local borderColorModeOptions = {
		DEFAULT = L["actionBarBorderDefault"] or "Default (Blizzard)",
		CUSTOM = L["Use custom color"] or "Use custom color",
		CLASS = L["Use class color"] or "Use class color",
	}
	local borderColorModeOrder = { "DEFAULT", "CUSTOM", "CLASS" }
	local function getBorderStyle()
		local current = addon.db.actionBarBorderStyle or "DEFAULT"
		local list = buildBorderDropdown()
		if not list[current] then current = "DEFAULT" end
		return current
	end
	local function isDefaultBorderStyle() return getBorderStyle() == "DEFAULT" end
	local function getBorderColorMode()
		local current = addon.db.actionBarBorderColorMode
		if current == nil then current = addon.db.actionBarBorderColoring and "CUSTOM" or "DEFAULT" end
		if not borderColorModeOptions[current] then current = "DEFAULT" end
		return current
	end

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = "actionBarBorderStyle",
		text = L["actionBarBorderStyle"] or "Action button border",
		desc = L["actionBarBorderStyleDesc"] or "Pick a custom border for action buttons. Selecting a custom border hides the Blizzard border.",
		listFunc = buildBorderDropdown,
		order = borderOrder,
		default = "DEFAULT",
		get = getBorderStyle,
		set = function(key)
			local list = buildBorderDropdown()
			if not list[key] then key = "DEFAULT" end
			addon.db.actionBarBorderStyle = key
			if key ~= "DEFAULT" then
				if not addon.db.actionBarHideBorders then
					addon.db.actionBarHideBorders = true
					addon.db.actionBarHideBordersAuto = true
					if hideBorders and hideBorders.setting then hideBorders.setting:SetValue(true) end
				end
			elseif addon.db.actionBarHideBordersAuto then
				addon.db.actionBarHideBordersAuto = nil
				addon.db.actionBarHideBorders = false
				if hideBorders and hideBorders.setting then hideBorders.setting:SetValue(false) end
			end
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		parentSection = expandable,
	})

	hideBorders = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarHideBorders",
		text = L["actionBarHideBorders"] or "Hide button borders",
		desc = L["actionBarHideBordersDesc"] or "Remove the default border texture around action buttons.",
		func = function(value)
			addon.db.actionBarHideBorders = value and true or false
			addon.db.actionBarHideBordersAuto = nil
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		parentCheck = isDefaultBorderStyle,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarBorderEdgeSize",
		text = L["Border size"] or "Border size",
		desc = L["actionBarBorderEdgeSizeDesc"] or "Edge size for SharedMedia borders (e.g., Blizzard Tooltip).",
		min = 1,
		max = 32,
		step = 1,
		default = 16,
		get = function()
			local value = tonumber(addon.db.actionBarBorderEdgeSize) or 16
			if value < 1 then value = 1 end
			if value > 32 then value = 32 end
			return value
		end,
		set = function(val)
			val = math.floor(val + 0.5)
			if val < 1 then val = 1 end
			if val > 32 then val = 32 end
			addon.db.actionBarBorderEdgeSize = val
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		parentCheck = function() return not isDefaultBorderStyle() end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarBorderPadding",
		text = L["actionBarBorderPadding"] or "Border padding",
		desc = L["actionBarBorderPaddingDesc"] or "Adjust border padding (positive grows, negative shrinks).",
		min = -8,
		max = 12,
		step = 1,
		default = 0,
		get = function()
			local value = tonumber(addon.db.actionBarBorderPadding) or 0
			if value < -8 then value = -8 end
			if value > 12 then value = 12 end
			return value
		end,
		set = function(val)
			val = math.floor(val + 0.5)
			if val < -8 then val = -8 end
			if val > 12 then val = 12 end
			addon.db.actionBarBorderPadding = val
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		parentCheck = function() return not isDefaultBorderStyle() end,
		parentSection = expandable,
	})

	local borderColorMode = addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarBorderColorMode",
		text = L["actionBarBorderColoring"] or "Border coloring",
		desc = L["actionBarBorderColoringDesc"] or "Choose how custom action button borders are colored.",
		list = borderColorModeOptions,
		order = borderColorModeOrder,
		default = "DEFAULT",
		get = getBorderColorMode,
		set = function(key)
			if not borderColorModeOptions[key] then key = "DEFAULT" end
			addon.db.actionBarBorderColorMode = key
			addon.db.actionBarBorderColoring = key == "CUSTOM"
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "actionBarBorderColor",
		text = EMBLEM_BORDER_COLOR,
		callback = function()
			if ActionBarLabels and ActionBarLabels.RefreshActionButtonBorders then ActionBarLabels.RefreshActionButtonBorders() end
		end,
		element = borderColorMode.element,
		parentCheck = function() return getBorderColorMode() == "CUSTOM" end,
		colorizeLabel = false,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarHideAssistedRotation",
		text = L["actionBarHideAssistedRotation"] or "Hide assisted rotation overlay",
		desc = L["actionBarHideAssistedRotationDesc"] or "Hide the Assisted Combat Rotation glow/overlay that Blizzard adds to the action button.",
		func = function(value)
			addon.db.actionBarHideAssistedRotation = value and true or false
			if addon.functions.UpdateAssistedCombatFrameHiding then addon.functions.UpdateAssistedCombatFrameHiding() end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = "hideExtraActionArtwork",
		text = L["hideExtraActionArtwork"] or "Hide Extra Action/Zone Ability artwork",
		desc = L["hideExtraActionArtworkDesc"] or "Hide the decorative frame on the Extra Action Button and Zone Ability and disable mouse input on the Extra Action bar.",
		func = function(value)
			addon.db.hideExtraActionArtwork = value and true or false
			if addon.functions.ApplyExtraActionArtworkSetting then addon.functions.ApplyExtraActionArtworkSetting() end
		end,
		parentSection = expandable,
	})
end

local function createLabelControls(category, expandable)
	addon.functions.SettingsCreateHeadline(category, L["actionBarLabelGroupTitle"] or "Button text", { parentSection = expandable })
	local globalFontKey = getGlobalFontConfigKey()
	local globalFontStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
	local globalFontStyleOptions, globalFontStyleOrder = addon.functions.GetFontStyleOptions and addon.functions.GetFontStyleOptions(true) or {
		NONE = NONE,
		OUTLINE = L["Outline"] or "Outline",
	}, { "NONE", "OUTLINE" }
	local function normalizeFontStyleChoice(value, fallback)
		if addon.functions and addon.functions.NormalizeFontStyleChoice then
			return addon.functions.NormalizeFontStyleChoice(value, fallback, true)
		end
		if value ~= nil then return value end
		return fallback or "OUTLINE"
	end
	local textAnchorOrder = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
	local textAnchorOptions = {
		TOPLEFT = L["Top Left"] or "Top Left",
		TOP = L["Top"] or "Top",
		TOPRIGHT = L["Top Right"] or "Top Right",
		LEFT = L["Left"] or "Left",
		CENTER = L["Center"] or "Center",
		RIGHT = L["Right"] or "Right",
		BOTTOMLEFT = L["Bottom Left"] or "Bottom Left",
		BOTTOM = L["Bottom"] or "Bottom",
		BOTTOMRIGHT = L["Bottom Right"] or "Bottom Right",
	}

	local macroOverride
	local hideMacro = addon.functions.SettingsCreateCheckbox(category, {
		var = "hideMacroNames",
		text = L["hideMacroNames"],
		desc = L["hideMacroNamesDesc"],
		func = function(value)
			addon.db["hideMacroNames"] = value and true or false
			if value then
				addon.db.actionBarMacroFontOverride = false
				if macroOverride and macroOverride.setting then macroOverride.setting:SetValue(false) end
			end
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
		end,
		parentSection = expandable,
	})

	macroOverride = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarMacroFontOverride",
		text = L["actionBarMacroFontOverride"] or "Change macro font",
		desc = L["actionBarMacroFontOverrideDesc"],
		func = function(value)
			if value then
				addon.db["hideMacroNames"] = false
				if hideMacro and hideMacro.setting then hideMacro.setting:SetValue(false) end
			end
			addon.db.actionBarMacroFontOverride = value and true or false
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parentSection = expandable,
	})

	local function macroParentCheck() return macroOverride.setting and macroOverride.setting:GetValue() == true and hideMacro.setting and hideMacro.setting:GetValue() ~= true end

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = "actionBarMacroFontFace",
		text = L["actionBarMacroFontLabel"] or "Macro name font",
		desc = L["actionBarMacroFontFaceDesc"],
		listFunc = buildOverrideFontDropdown,
		order = fontOrder,
		default = globalFontKey,
		get = function()
			local current = addon.db.actionBarMacroFontFace or globalFontKey
			local list = buildOverrideFontDropdown()
			if not list[current] then current = globalFontKey end
			return current
		end,
		set = function(key)
			addon.db.actionBarMacroFontFace = key
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = macroOverride.element,
		parentCheck = macroParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarMacroFontOutline",
		text = L["Font outline"] or "Font outline",
		desc = L["actionBarMacroFontOutlineDesc"],
		list = globalFontStyleOptions,
		order = globalFontStyleOrder,
		default = globalFontStyleKey,
		get = function() return normalizeFontStyleChoice(addon.db.actionBarMacroFontOutline, globalFontStyleKey) end,
		set = function(key)
			addon.db.actionBarMacroFontOutline = normalizeFontStyleChoice(key, globalFontStyleKey)
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = macroOverride.element,
		parentCheck = macroParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarMacroFontSize",
		text = L["actionBarMacroFontSize"] or "Macro font size",
		desc = L["actionBarMacroFontSizeDesc"],
		min = 8,
		max = 24,
		step = 1,
		default = 12,
		get = function()
			local value = tonumber(addon.db.actionBarMacroFontSize) or 12
			if value < 8 then value = 8 end
			if value > 24 then value = 24 end
			return value
		end,
		set = function(val)
			val = math.floor(val + 0.5)
			if val < 8 then val = 8 end
			if val > 24 then val = 24 end
			addon.db.actionBarMacroFontSize = val
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = macroOverride.element,
		parentCheck = macroParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "actionBarMacroFontColor",
		text = L["actionBarMacroFontColor"] or "Macro text color",
		desc = L["actionBarMacroFontColorDesc"],
		callback = function()
			if ActionBarLabels and ActionBarLabels.RefreshAllMacroNameVisibility then ActionBarLabels.RefreshAllMacroNameVisibility() end
		end,
		parent = true,
		element = macroOverride.element,
		parentCheck = macroParentCheck,
		colorizeLabel = false,
		parentSection = expandable,
	})

	local hotkeyOverride = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarHotkeyFontOverride",
		text = L["actionBarHotkeyFontOverride"] or "Change keybind font",
		desc = L["actionBarHotkeyFontOverrideDesc"],
		func = function(value)
			addon.db.actionBarHotkeyFontOverride = value and true or false
			if ActionBarLabels and ActionBarLabels.EnsureRangeIndicatorHook then ActionBarLabels.EnsureRangeIndicatorHook() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyVisibility then ActionBarLabels.RefreshAllHotkeyVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parentSection = expandable,
	})

	local function hotkeyParentCheck() return hotkeyOverride.setting and hotkeyOverride.setting:GetValue() == true end

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = "actionBarHotkeyFontFace",
		text = L["actionBarHotkeyFontLabel"] or "Keybind font",
		desc = L["actionBarHotkeyFontFaceDesc"],
		listFunc = buildOverrideFontDropdown,
		order = fontOrder,
		default = globalFontKey,
		get = function()
			local current = addon.db.actionBarHotkeyFontFace or globalFontKey
			local list = buildOverrideFontDropdown()
			if not list[current] then current = globalFontKey end
			return current
		end,
		set = function(key)
			addon.db.actionBarHotkeyFontFace = key
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyVisibility then ActionBarLabels.RefreshAllHotkeyVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarHotkeyFontOutline",
		text = L["Font outline"] or "Font outline",
		desc = L["actionBarHotkeyFontOutlineDesc"],
		list = globalFontStyleOptions,
		order = globalFontStyleOrder,
		default = globalFontStyleKey,
		get = function() return normalizeFontStyleChoice(addon.db.actionBarHotkeyFontOutline, globalFontStyleKey) end,
		set = function(key)
			addon.db.actionBarHotkeyFontOutline = normalizeFontStyleChoice(key, globalFontStyleKey)
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyVisibility then ActionBarLabels.RefreshAllHotkeyVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarHotkeyFontSize",
		text = L["actionBarHotkeyFontSize"] or "Keybind font size",
		desc = L["actionBarHotkeyFontSizeDesc"],
		min = 8,
		max = 24,
		step = 1,
		default = 12,
		get = function()
			local value = tonumber(addon.db.actionBarHotkeyFontSize) or 12
			if value < 8 then value = 8 end
			if value > 24 then value = 24 end
			return value
		end,
		set = function(val)
			val = math.floor(val + 0.5)
			if val < 8 then val = 8 end
			if val > 24 then val = 24 end
			addon.db.actionBarHotkeyFontSize = val
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyVisibility then ActionBarLabels.RefreshAllHotkeyVisibility() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "actionBarHotkeyFontColor",
		text = L["actionBarHotkeyFontColor"] or "Keybind text color",
		desc = L["actionBarHotkeyFontColorDesc"],
		callback = function()
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		colorizeLabel = false,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarHotkeyAnchor",
		text = L["actionBarHotkeyAnchor"] or "Keybind anchor",
		desc = L["actionBarHotkeyAnchorDesc"],
		list = textAnchorOptions,
		order = textAnchorOrder,
		default = "TOPRIGHT",
		get = function() return addon.db.actionBarHotkeyAnchor or "TOPRIGHT" end,
		set = function(key)
			addon.db.actionBarHotkeyAnchor = key
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarHotkeyOffsetX",
		text = L["actionBarHotkeyOffsetX"] or "Keybind offset X",
		desc = L["actionBarHotkeyOffsetXDesc"],
		min = -50,
		max = 50,
		step = 1,
		default = -2,
		get = function() return tonumber(addon.db.actionBarHotkeyOffsetX) or -2 end,
		set = function(val)
			addon.db.actionBarHotkeyOffsetX = math.floor(val + 0.5)
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarHotkeyOffsetY",
		text = L["actionBarHotkeyOffsetY"] or "Keybind offset Y",
		desc = L["actionBarHotkeyOffsetYDesc"],
		min = -50,
		max = 50,
		step = 1,
		default = -3,
		get = function() return tonumber(addon.db.actionBarHotkeyOffsetY) or -3 end,
		set = function(val)
			addon.db.actionBarHotkeyOffsetY = math.floor(val + 0.5)
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parent = true,
		element = hotkeyOverride.element,
		parentCheck = hotkeyParentCheck,
		parentSection = expandable,
	})

	local countOverride = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarCountFontOverride",
		text = L["actionBarCountFontOverride"] or "Change charge/stack font",
		desc = L["actionBarCountFontOverrideDesc"],
		func = function(value)
			addon.db.actionBarCountFontOverride = value and true or false
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parentSection = expandable,
	})

	local function countParentCheck() return countOverride.setting and countOverride.setting:GetValue() == true end

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = "actionBarCountFontFace",
		text = L["actionBarCountFontLabel"] or "Charge/stack font",
		desc = L["actionBarCountFontFaceDesc"],
		listFunc = buildOverrideFontDropdown,
		order = fontOrder,
		default = globalFontKey,
		get = function()
			local current = addon.db.actionBarCountFontFace or globalFontKey
			local list = buildOverrideFontDropdown()
			if not list[current] then current = globalFontKey end
			return current
		end,
		set = function(key)
			addon.db.actionBarCountFontFace = key
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarCountFontOutline",
		text = L["Font outline"] or "Font outline",
		desc = L["actionBarCountFontOutlineDesc"],
		list = globalFontStyleOptions,
		order = globalFontStyleOrder,
		default = globalFontStyleKey,
		get = function() return normalizeFontStyleChoice(addon.db.actionBarCountFontOutline, globalFontStyleKey) end,
		set = function(key)
			addon.db.actionBarCountFontOutline = normalizeFontStyleChoice(key, globalFontStyleKey)
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarCountFontSize",
		text = L["actionBarCountFontSize"] or "Charge/stack font size",
		desc = L["actionBarCountFontSizeDesc"],
		min = 8,
		max = 24,
		step = 1,
		default = 12,
		get = function()
			local value = tonumber(addon.db.actionBarCountFontSize) or 12
			if value < 8 then value = 8 end
			if value > 24 then value = 24 end
			return value
		end,
		set = function(val)
			val = math.floor(val + 0.5)
			if val < 8 then val = 8 end
			if val > 24 then val = 24 end
			addon.db.actionBarCountFontSize = val
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "actionBarCountFontColor",
		text = L["actionBarCountFontColor"] or "Charge/stack text color",
		desc = L["actionBarCountFontColorDesc"],
		callback = function()
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		colorizeLabel = false,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateDropdown(category, {
		var = "actionBarCountAnchor",
		text = L["actionBarCountAnchor"] or "Charge/stack anchor",
		desc = L["actionBarCountAnchorDesc"],
		list = textAnchorOptions,
		order = textAnchorOrder,
		default = "BOTTOMRIGHT",
		get = function() return addon.db.actionBarCountAnchor or "BOTTOMRIGHT" end,
		set = function(key)
			addon.db.actionBarCountAnchor = key
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarCountOffsetX",
		text = L["actionBarCountOffsetX"] or "Charge/stack offset X",
		desc = L["actionBarCountOffsetXDesc"],
		min = -50,
		max = 50,
		step = 1,
		default = -2,
		get = function() return tonumber(addon.db.actionBarCountOffsetX) or -2 end,
		set = function(val)
			addon.db.actionBarCountOffsetX = math.floor(val + 0.5)
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "actionBarCountOffsetY",
		text = L["actionBarCountOffsetY"] or "Charge/stack offset Y",
		desc = L["actionBarCountOffsetYDesc"],
		min = -50,
		max = 50,
		step = 1,
		default = 2,
		get = function() return tonumber(addon.db.actionBarCountOffsetY) or 2 end,
		set = function(val)
			addon.db.actionBarCountOffsetY = math.floor(val + 0.5)
			if ActionBarLabels and ActionBarLabels.RefreshAllCountStyles then ActionBarLabels.RefreshAllCountStyles() end
		end,
		parent = true,
		element = countOverride.element,
		parentCheck = countParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateHeadline(category, L["actionBarKeybindVisibilityHeader"] or "Keybind label visibility", { parentSection = expandable })

	local barOptions = {}
	for _, info in ipairs(addon.variables.actionBarNames or {}) do
		if info.name then table.insert(barOptions, { value = info.name, text = info.text or info.name }) end
	end
	if ActionBarLabels and ActionBarLabels.GetAdditionalHotkeyBarOptions then
		for _, info in ipairs(ActionBarLabels.GetAdditionalHotkeyBarOptions() or {}) do
			if info and info.value then table.insert(barOptions, info) end
		end
	end
	table.sort(barOptions, function(a, b) return tostring(a.text) < tostring(b.text) end)

	addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarShortHotkeys",
		text = L["actionBarShortHotkeys"] or "Shorten keybind text",
		desc = L["actionBarShortHotkeysDesc"],
		func = function(value)
			addon.db.actionBarShortHotkeys = value and true or false
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		parentSection = expandable,
	})

	local rangeToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = "actionBarFullRangeColoring",
		text = L["fullButtonRangeColoring"],
		desc = L["fullButtonRangeColoringDesc"],
		richNote = {
			title = L["fullButtonRangeColoring"],
			blocks = {
				{ text = L["fullButtonRangeColoringDesc"] },
				{
					image = "Interface\\AddOns\\EnhanceQoL\\Assets\\NewSettings\\Examples\\FullRangeColoring.tga",
					width = 172,
					height = 180,
				},
			},
		},
		func = function(value)
			addon.db["actionBarFullRangeColoring"] = value
			if ActionBarLabels and ActionBarLabels.UpdateRangeOverlayEvents then ActionBarLabels.UpdateRangeOverlayEvents() end
			if ActionBarLabels and ActionBarLabels.RefreshAllRangeOverlays then ActionBarLabels.RefreshAllRangeOverlays() end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "actionBarFullRangeColor",
		text = L["rangeOverlayColor"],
		hasOpacity = true,
		callback = function()
			if ActionBarLabels and ActionBarLabels.RefreshAllRangeOverlays then ActionBarLabels.RefreshAllRangeOverlays() end
		end,
		parent = true,
		element = rangeToggle.element,
		parentCheck = function() return rangeToggle.setting and rangeToggle.setting:GetValue() == true end,
		colorizeLabel = true,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateMultiDropdown(category, {
		var = "actionBarHiddenHotkeys",
		text = L["actionBarHideHotkeysGroup"] or "Hide keybinds per bar",
		options = barOptions,
		isSelectedFunc = function(key) return addon.db.actionBarHiddenHotkeys and addon.db.actionBarHiddenHotkeys[key] == true end,
		setSelectedFunc = function(key, shouldSelect)
			if type(addon.db.actionBarHiddenHotkeys) ~= "table" then addon.db.actionBarHiddenHotkeys = {} end
			if shouldSelect then
				addon.db.actionBarHiddenHotkeys[key] = true
			else
				addon.db.actionBarHiddenHotkeys[key] = nil
			end
			if ActionBarLabels and ActionBarLabels.EnsureRangeIndicatorHook then ActionBarLabels.EnsureRangeIndicatorHook() end
			if ActionBarLabels and ActionBarLabels.RefreshAllHotkeyStyles then ActionBarLabels.RefreshAllHotkeyStyles() end
		end,
		desc = L["actionBarHideHotkeysDesc"],
		parentSection = expandable,
	})
end

local function createActionBarCategory()
	--local category = addon.functions.SettingsCreateCategory(nil, L["visibilityKindActionBars"] or ACTIONBARS_LABEL, nil, "ActionBar")
	--addon.SettingsLayout.actionBarCategory = category
	local category = addon.SettingsLayout.rootUI

	local expandable = addon.functions.SettingsCreateExpandableSection(category, {
		name = L["ActionBarsAndButtons"] or "Action Bars & Buttons",
		configPageKey = "ActionBarsAndButtons",
		iconKey = "actionbar",
		modernOnly = true,
		description = L["configCenterPageDescActionBars"]
			or "Configure action bar visibility, button growth, borders, keybind text, macro labels and cooldown text.",
		expanded = false,
		colorizeTitle = false,
	})

	createActionBarVisibility(category, expandable)
	createAnchorControls(category, expandable)
	createButtonAppearanceControls(category, expandable)
	createLabelControls(category, expandable)
end

local function setFrameRule(info, key, shouldSelect)
	if not info or not info.var then return end
	if HasFrameVisibilityOverride(info.var) then
		notifyFrameRuleLocked(info.text or info.name or info.var)
		return
	end
	local working = addon.db[info.var]
	if type(working) ~= "table" then working = {} end
	local wasAlwaysHidden = working.ALWAYS_HIDDEN == true

	if key == "ALWAYS_HIDDEN" and shouldSelect then
		working = { ALWAYS_HIDDEN = true }
	elseif shouldSelect then
		working[key] = true
		working.ALWAYS_HIDDEN = nil
	else
		working[key] = nil
	end

	local normalized = NormalizeUnitFrameVisibilityConfig(info.var, working)
	if wasAlwaysHidden and not (normalized and normalized.ALWAYS_HIDDEN == true) then
		addon.variables.requireReload = true
		if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
	end
	UpdateUnitFrameMouseover(info.name, info)
end

local function getFrameRuleOptions(info)
	local allowedRuleSet
	if info and type(info.visibilityRules) == "table" then
		for _, ruleKey in ipairs(info.visibilityRules) do
			if type(ruleKey) == "string" and ruleKey ~= "" then
				allowedRuleSet = allowedRuleSet or {}
				allowedRuleSet[ruleKey] = true
			end
		end
	end

	local options = {}
	for key, data in pairs(GetVisibilityRuleMetadata() or {}) do
		local allowed = data.appliesTo and data.appliesTo.frame
		if allowed and data.unitRequirement and data.unitRequirement ~= info.unitToken then allowed = false end
		if allowed and allowedRuleSet and not allowedRuleSet[key] then allowed = false end
		if allowed then table.insert(options, { value = key, text = data.label or key, order = data.order or 999 }) end
	end
	table.sort(options, function(a, b)
		if a.order == b.order then return a.text < b.text end
		return a.order < b.order
	end)
	return options
end

local function createCooldownViewerDropdowns(category, expandable)
	if not category or #COOLDOWN_VIEWER_FRAMES == 0 then return end

	addon.functions.SettingsCreateHeadline(category, L["Show when"] or "Show when", { parentSection = expandable })

	local options = {
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.IN_COMBAT, text = L["In combat"] or "In combat" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED, text = L["cooldownManagerShowMounted"] or "Mounted" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED, text = L["Not mounted"] or "Not mounted" },
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE,
			text = L["While skyriding"] or (L["While skyriding"] or "While skyriding"),
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE,
			text = L["Hide while skyriding"] or (L["Hide while skyriding"] or "Hide while skyriding"),
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE,
			text = L["visibilityRule_flying"] or "While flying",
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE,
			text = L["visibilityRule_hideFlying"] or "Hide while flying",
		},
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING, text = L["Player is casting"] or "Player is casting" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_IN_GROUP, text = L["In party/raid"] or "In party/raid" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE, text = L["Show in instance"] or "Show in instance" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.MOUSEOVER, text = L["cooldownManagerShowMouseover"] or "On mouseover" },
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS,
			text = L["When I have a focus"] or "When I have a focus",
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET,
			text = L["When I have a target"] or "When I have a target",
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.ALWAYS_HIDDEN,
			text = L["visibilityRule_alwaysHidden"] or "Always hidden",
		},
	}
	local labels = {
		EssentialCooldownViewer = L["cooldownViewerEssential"] or "Essential Cooldown Viewer",
		UtilityCooldownViewer = L["cooldownViewerUtility"] or "Utility Cooldown Viewer",
		BuffBarCooldownViewer = L["cooldownViewerBuffBar"] or "Buff Bar Cooldowns",
		BuffIconCooldownViewer = L["cooldownViewerBuffIcon"] or "Buff Icon Cooldowns",
	}

	local desc = L["cooldownManagerShowDesc"] or "Visible while any selected condition is true."

	for _, frameName in ipairs(COOLDOWN_VIEWER_FRAMES) do
		local exp = expandable
		local label = labels[frameName] or frameName
		addon.functions.SettingsCreateMultiDropdown(category, {
			var = "cooldownViewerVisibility_" .. tostring(frameName),
			text = label,
			options = options,
			hideSummary = true,
			isSelectedFunc = function(key)
				local cfg = GetCooldownViewerVisibility(frameName)
				return cfg and cfg[key] == true
			end,
			setSelectedFunc = function(key, shouldSelect) SetCooldownViewerVisibility(frameName, key, shouldSelect) end,
			getSelection = function() return GetCooldownViewerVisibility(frameName) or {} end,
			setSelection = function(map)
				for _, opt in ipairs(options) do
					local key = opt.value
					local desired = map and map[key] == true
					SetCooldownViewerVisibility(frameName, key, desired)
				end
			end,
			desc = desc,
			parentSection = exp,
		})
	end

	local function getCooldownViewerFadePercent()
		local value = GetCooldownViewerFadeStrength()
		if value < 0 then value = 0 end
		if value > 1 then value = 1 end
		return math.floor((value * 100) + 0.5)
	end

	addon.functions.SettingsCreateSlider(category, {
		var = "cooldownViewerFadeStrength",
		text = L["Fade amount"] or "Fade amount",
		desc = L["cooldownViewerFadeStrengthDesc"],
		min = 0,
		max = 100,
		step = 1,
		default = 100,
		get = getCooldownViewerFadePercent,
		set = function(val)
			local pct = tonumber(val) or 0
			if pct < 0 then pct = 0 end
			if pct > 100 then pct = 100 end
			addon.db.cooldownViewerFadeStrength = pct / 100
			if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = "cooldownViewerSharedHover",
		text = L["cooldownManagerSharedHover"],
		default = false,
		get = function() return addon.db and addon.db.cooldownViewerSharedHover end,
		set = function(value)
			addon.db.cooldownViewerSharedHover = value
			if addon.functions.ApplyCooldownViewerVisibility then addon.functions.ApplyCooldownViewerVisibility() end
		end,
		desc = L["cooldownManagerSharedHoverDesc"],
		parentSection = expandable,
	})
end

local function createSpellActivationOverlayDropdown(category, expandable)
	if not category then return end

	addon.functions.SettingsCreateHeadline(category, L["spellActivationOverlayHeader"] or "Spell activation overlay", { parentSection = expandable })

	local options = {
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_MOUNTED, text = L["cooldownManagerShowMounted"] or "Mounted" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.WHILE_NOT_MOUNTED, text = L["Not mounted"] or "Not mounted" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_ACTIVE, text = L["While skyriding"] or "While skyriding" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.SKYRIDING_INACTIVE, text = L["VisibilityCondNotSkyriding"] or "Not skyriding" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_ACTIVE, text = L["visibilityRule_flying"] or "While flying" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.FLYING_INACTIVE, text = L["VisibilityCondNotFlying"] or "Not flying" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_CASTING, text = L["Player is casting"] or "Player is casting" },
		{ value = COOLDOWN_VIEWER_VISIBILITY_MODES.SHOW_IN_INSTANCE, text = L["Show in instance"] or "Show in instance" },
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_FOCUS,
			text = L["When I have a focus"] or "When I have a focus",
		},
		{
			value = COOLDOWN_VIEWER_VISIBILITY_MODES.PLAYER_HAS_TARGET,
			text = L["When I have a target"] or "When I have a target",
		},
	}

	addon.functions.SettingsCreateMultiDropdown(category, {
		var = "spellActivationOverlayVisibility",
		text = L["spellActivationOverlayFrame"] or "Spell Activation Overlay",
		options = options,
		hideSummary = true,
		isSelectedFunc = function(key)
			local cfg = GetSpellActivationOverlayVisibility()
			return cfg and cfg[key] == true
		end,
		setSelectedFunc = function(key, shouldSelect) SetSpellActivationOverlayVisibility(key, shouldSelect) end,
		getSelection = function() return GetSpellActivationOverlayVisibility() or {} end,
		setSelection = function(map)
			for _, opt in ipairs(options) do
				local key = opt.value
				local desired = map and map[key] == true
				SetSpellActivationOverlayVisibility(key, desired)
			end
		end,
		desc = L["spellActivationOverlayDesc"],
		parentSection = expandable,
	})

	local customAlphaToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = "spellActivationOverlayUseCustomAlpha",
		text = L["spellActivationOverlayUseCustomAlpha"] or "Use custom alpha",
		desc = L["spellActivationOverlayUseCustomAlphaDesc"],
		default = false,
		get = function() return addon.db and addon.db.spellActivationOverlayUseCustomAlpha end,
		set = function(value)
			addon.db = addon.db or {}
			addon.db.spellActivationOverlayUseCustomAlpha = value and true or false
			if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
		end,
		parentSection = expandable,
	})
	local function customAlphaEnabled() return customAlphaToggle and customAlphaToggle.setting and customAlphaToggle.setting:GetValue() == true end

	local function getAlphaPercent(key, fallback)
		local value = addon.db and addon.db[key]
		if type(value) ~= "number" then value = fallback end
		if value < 0 then value = 0 end
		if value > 1 then value = 1 end
		return math.floor((value * 100) + 0.5)
	end

	local function setAlphaPercent(key, percent)
		addon.db = addon.db or {}
		local value = tonumber(percent) or 0
		if value < 0 then value = 0 end
		if value > 100 then value = 100 end
		addon.db[key] = value / 100
		if addon.functions.ApplySpellActivationOverlayVisibility then addon.functions.ApplySpellActivationOverlayVisibility() end
	end

	addon.functions.SettingsCreateSlider(category, {
		var = "spellActivationOverlayActiveAlpha",
		text = L["spellActivationOverlayActiveAlpha"] or "Active alpha",
		desc = L["spellActivationOverlayActiveAlphaDesc"],
		min = 0,
		max = 100,
		step = 1,
		default = 100,
		get = function() return getAlphaPercent("spellActivationOverlayActiveAlpha", 1) end,
		set = function(val) setAlphaPercent("spellActivationOverlayActiveAlpha", val) end,
		element = customAlphaToggle and customAlphaToggle.element,
		parentCheck = customAlphaEnabled,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = "spellActivationOverlayHiddenAlpha",
		text = L["spellActivationOverlayHiddenAlpha"] or "Hidden alpha",
		desc = L["spellActivationOverlayHiddenAlphaDesc"],
		min = 0,
		max = 100,
		step = 1,
		default = 0,
		get = function() return getAlphaPercent("spellActivationOverlayHiddenAlpha", 0) end,
		set = function(val) setAlphaPercent("spellActivationOverlayHiddenAlpha", val) end,
		element = customAlphaToggle and customAlphaToggle.element,
		parentCheck = customAlphaEnabled,
		parentSection = expandable,
	})
end

local function createFrameCategory()
	local category = addon.SettingsLayout.rootUI

	local expandable = addon.functions.SettingsCreateExpandableSection(category, {
		name = L["VisibilityAndFadingFrames"] or "Visibility & Fading (Frames)",
		description = L["configCenterPageDescVisibilityFrames"]
			or "Control when supported Blizzard frames are shown, hidden or faded during combat, targeting and mouseover states.",
		newTagID = "VisibilityFrames",
		iconKey = "visibility",
		modernOnly = true,
		expanded = false,
		colorizeTitle = false,
	})
	addon.SettingsLayout.uiFramesExpandable = expandable

	addon.functions.SettingsCreateHeadline(category, L["visibilityScenarioGroupTitle"] or (L["Visibility"] or "Visibility"), { parentSection = expandable })
	if L["visibilityFrameExplain2"] then addon.functions.SettingsCreateText(category, L["visibilityFrameExplain2"], { parentSection = expandable }) end

	local frames = {}
	for _, info in ipairs(addon.variables.unitFrameNames or {}) do
		table.insert(frames, info)
	end
	table.sort(frames, function(a, b) return (a.text or a.name or "") < (b.text or b.name or "") end)

	for _, info in ipairs(frames) do
		if info.var and info.name then
			local options = getFrameRuleOptions(info)
			if #options > 0 then
				local function shouldShow() return shouldShowBlizzardFrameVisibility(info) end
				local init = addon.functions.SettingsCreateMultiDropdown(category, {
					var = info.var .. "_visibility",
					storage = false,
					text = info.text or info.name or info.var,
					desc = L["visibilityFrameRuleSelectionDesc"],
					options = options,
					isSelectedFunc = function(key)
						local cfg = NormalizeUnitFrameVisibilityConfig(info.var)
						return cfg and cfg[key] == true
					end,
					setSelectedFunc = function(key, shouldSelect) setFrameRule(info, key, shouldSelect) end,
					isEnabled = function() return shouldShow() end,
					hiddenWhen = function() return not shouldShow() end,
					richNote = {
						title = L["CustomUnitFrames"] or L["Unit Frames"] or "EQoL Unit Frames",
						text = L["visibilityRule_lockedByUF"]
							or "Visibility is controlled by Enhanced Unit Frames. Disable them to change this setting.",
						visible = function() return not shouldShow() end,
					},
					parentSection = expandable,
				})
			end
		end
	end

	local function getFrameFadePercent()
		local value = GetFrameFadeStrength()
		if value < 0 then value = 0 end
		if value > 1 then value = 1 end
		return math.floor((value * 100) + 0.5)
	end

	addon.functions.SettingsCreateSlider(category, {
		var = "frameVisibilityFadeStrength",
		text = L["Fade amount"] or "Fade amount",
		desc = L["frameFadeStrengthDesc"],
		min = 0,
		max = 100,
		step = 1,
		default = 100,
		get = getFrameFadePercent,
		set = function(val)
			local pct = tonumber(val) or 0
			if pct < 0 then pct = 0 end
			if pct > 100 then pct = 100 end
			addon.db.frameVisibilityFadeStrength = pct / 100
			RefreshAllFrameVisibilityAlpha()
		end,
		parentSection = expandable,
	})

end

function addon.functions.initUIOptions()
	addon.functions.InitDBValue("hideEventToasts", false)
	if addon.functions.ApplyEventToastVisibility then addon.functions.ApplyEventToastVisibility() end
	addon.functions.InitDBValue("totalAbsorbTrackerEnabled", false)
	addon.functions.InitDBValue("totalAbsorbTrackerTextOnly", false)
	addon.functions.InitDBValue("totalAbsorbTrackerRelativeFrame", "UIParent")
	if addon.Aura and addon.Aura.TotalAbsorbTracker and addon.Aura.TotalAbsorbTracker.OnSettingChanged then addon.Aura.TotalAbsorbTracker:OnSettingChanged(addon.db["totalAbsorbTrackerEnabled"]) end
	addon.db.focusInterruptTracker = type(addon.db.focusInterruptTracker) == "table" and addon.db.focusInterruptTracker or {}
	if addon.db.focusInterruptTracker.enabled == nil then addon.db.focusInterruptTracker.enabled = false end
	if addon.Aura and addon.Aura.FocusInterruptTracker and addon.Aura.FocusInterruptTracker.OnSettingChanged then
		addon.Aura.FocusInterruptTracker:OnSettingChanged(addon.db.focusInterruptTracker.enabled)
	end

	local combatDefaults = (addon.CombatText and addon.CombatText.defaults) or {}
	local combatAlwaysModeCombatOnly = addon.CombatText and addon.CombatText.ALWAYS_VISIBLE_MODE_COMBAT_ONLY or "COMBAT_ONLY"
	local combatAlwaysModeStatus = addon.CombatText and addon.CombatText.ALWAYS_VISIBLE_MODE_STATUS or "STATUS"
	local combatFont = combatDefaults.fontFace or (addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__")
	local function cloneColor(value, fallback)
		local source = type(value) == "table" and value or fallback
		source = type(source) == "table" and source or { r = 1, g = 1, b = 1, a = 1 }
		return {
			r = source.r or source[1] or 1,
			g = source.g or source[2] or 1,
			b = source.b or source[3] or 1,
			a = source.a or source[4],
		}
	end
	addon.functions.InitDBValue("combatTextEnabled", false)
	addon.functions.InitDBValue("combatTextDuration", combatDefaults.duration or 3)
	addon.functions.InitDBValue("combatTextAlwaysVisible", combatDefaults.alwaysVisible == true)
	local alwaysVisibleMode = combatDefaults.alwaysVisibleMode
	if alwaysVisibleMode ~= combatAlwaysModeCombatOnly and alwaysVisibleMode ~= combatAlwaysModeStatus then alwaysVisibleMode = combatAlwaysModeStatus end
	addon.functions.InitDBValue("combatTextAlwaysVisibleMode", alwaysVisibleMode)
	addon.functions.InitDBValue("combatTextEnterText", combatDefaults.enterText or "")
	addon.functions.InitDBValue("combatTextLeaveText", combatDefaults.leaveText or "")
	addon.functions.InitDBValue("combatTextFont", combatFont)
	addon.functions.InitDBValue("combatTextFontSize", combatDefaults.fontSize or 32)
	addon.functions.InitDBValue("combatTextAnchorTarget", "UIParent")
	local defaultCombatColor = cloneColor(addon.db["combatTextColor"], combatDefaults.enterColor or combatDefaults.color or { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("combatTextColor", cloneColor(defaultCombatColor, defaultCombatColor))
	addon.functions.InitDBValue("combatTextEnterColor", cloneColor(defaultCombatColor, defaultCombatColor))
	addon.functions.InitDBValue("combatTextLeaveColor", cloneColor(defaultCombatColor, combatDefaults.leaveColor or defaultCombatColor))

	if addon.CombatText and addon.CombatText.OnSettingChanged then addon.CombatText:OnSettingChanged(addon.db["combatTextEnabled"]) end
end

local function createNameplatesCategory()
	local category = addon.SettingsLayout.rootUI
	local label = L["NameplatesAndNames"] or "Nameplates & Names"

	local expandable = addon.functions.SettingsCreateExpandableSection(category, {
		name = label,
		description = L["configCenterPageDescNameplates"]
			or "Adjust player names, nameplate text, markers, mob colors and dungeon-specific nameplate behavior.",
		configPageID = "interface.nameplates",
		configPageKey = "Nameplates",
		expanded = false,
		colorizeTitle = false,
		newTagID = "Nameplates",
		iconKey = "nameplate",
		sortGroups = false,
	})
	addon.SettingsLayout.uiNameplatesExpandable = expandable

	addon.functions.SettingsCreateHeadline(category, L["Friendly"] or "Friendly", {
		parentSection = expandable,
		groupID = "friendly",
		order = 1,
	})

	local nameplateData = {
		{
			var = "UnitNamePlayerGuild",
			text = L["UnitNamePlayerGuild"],
			desc = L["UnitNamePlayerGuildDesc"],
			get = function() return getCVarOptionState("UnitNamePlayerGuild") end,
			func = function(value) setCVarOptionState("UnitNamePlayerGuild", value) end,
			default = false,
			parentSection = expandable,
		},
		{
			var = "UnitNamePlayerPVPTitle",
			text = L["UnitNamePlayerPVPTitle"],
			desc = L["UnitNamePlayerPVPTitleDesc"],
			get = function() return getCVarOptionState("UnitNamePlayerPVPTitle") end,
			func = function(value) setCVarOptionState("UnitNamePlayerPVPTitle", value) end,
			default = false,
			parentSection = expandable,
		},
	}

	table.sort(nameplateData, function(a, b) return a.text < b.text end)
	addon.functions.SettingsCreateCheckboxes(category, nameplateData)

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.friendlyPlayerNamesOnly,
		text = L["nameplateFriendlyPlayerNamesOnly"] or "Show only names for friendly player nameplates",
		desc = L["nameplateFriendlyPlayerNamesOnlyDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateFriendlyPlayerNamesOnlyEnabled then
				addon.functions.SetDefaultNameplateFriendlyPlayerNamesOnlyEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.friendlyPlayerNamesOnly] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.friendlyPlayerClassColorNames,
		text = L["nameplateFriendlyPlayerClassColorNames"] or "Use class colors for friendly player names",
		desc = L["nameplateFriendlyPlayerClassColorNamesDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateFriendlyPlayerClassColorNamesEnabled then
				addon.functions.SetDefaultNameplateFriendlyPlayerClassColorNamesEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.friendlyPlayerClassColorNames] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.hideFriendlyPlayerRealms,
		text = L["nameplateHideFriendlyPlayerRealms"] or "Hide realms on friendly player nameplates",
		desc = L["nameplateHideFriendlyPlayerRealmsDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateHideFriendlyPlayerRealmsEnabled then
				addon.functions.SetDefaultNameplateHideFriendlyPlayerRealmsEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.hideFriendlyPlayerRealms] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.auraClickthrough,
		text = L["nameplateAuraClickthrough"] or "Make nameplate auras click-through",
		desc = L["nameplateAuraClickthroughDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateAuraClickthroughEnabled then
				addon.functions.SetDefaultNameplateAuraClickthroughEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.auraClickthrough] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateHeadline(category, L["Text"] or "Text", {
		parentSection = expandable,
		groupID = "text",
		order = 20,
	})

	local nameplateTextToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.slugOutline,
		text = L["nameplateSlugOutline"] or "Customize default nameplate text",
		desc = L["nameplateSlugOutlineDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateSlugOutlineEnabled then
				addon.functions.SetDefaultNameplateSlugOutlineEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.slugOutline] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	local function isNameplateTextEnabled() return nameplateTextToggle and nameplateTextToggle.setting and nameplateTextToggle.setting:GetValue() == true end
	local function isNameplateCustomFontEnabled()
		if not isNameplateTextEnabled() then return false end
		if addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textCustomFont] ~= nil then return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textCustomFont] == true end
		return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textFont] ~= nil
	end
	local globalFontStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
		local nameplateTextOutlineOptions, nameplateTextOutlineOrder = addon.functions.GetFontStyleOptions and addon.functions.GetFontStyleOptions(true) or {
			[globalFontStyleKey] = L["useGlobalFontStyleConfig"] or "Use global font styling",
			OUTLINE = L["Outline"] or "Outline",
		}, { globalFontStyleKey, "OUTLINE" }
		nameplateTextOutlineOptions.NONE = nil
		for i = #nameplateTextOutlineOrder, 1, -1 do
			if nameplateTextOutlineOrder[i] == "NONE" then table.remove(nameplateTextOutlineOrder, i) end
		end
		local function normalizeNameplateTextOutline(value)
			if value == "NONE" then return globalFontStyleKey end
			if addon.functions.NormalizeFontStyleChoice then
				local normalized = addon.functions.NormalizeFontStyleChoice(value, globalFontStyleKey, true)
				if normalized == "NONE" then normalized = globalFontStyleKey end
				return normalized
			end
			return value or globalFontStyleKey
		end
		local function refreshNameplateTextStyle()
			if addon.functions.RefreshDefaultNameplateTextStyle then addon.functions.RefreshDefaultNameplateTextStyle() end
		end

		addon.functions.SettingsCreateCheckbox(category, {
			var = DEFAULT_NAMEPLATE_FEATURE_KEYS.textCustomFont,
			text = L["nameplateTextCustomFont"] or "Override nameplate text font",
			desc = L["nameplateTextCustomFontDesc"] or "Changes the font used by default nameplate text. Disable this to keep Blizzard's locale font while still applying outline or size changes.",
			default = false,
			get = function() return isNameplateCustomFontEnabled() end,
			set = function(value)
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textCustomFont] = value and true or false
				refreshNameplateTextStyle()
			end,
			parent = true,
			element = nameplateTextToggle.element,
			parentCheck = isNameplateTextEnabled,
			parentSection = expandable,
		})

		addon.functions.SettingsCreateScrollDropdown(category, {
			var = DEFAULT_NAMEPLATE_FEATURE_KEYS.textFont,
			text = L["nameplateTextFont"] or "Nameplate text font",
			desc = L["nameplateTextFontDesc"],
			listFunc = buildOverrideFontDropdown,
			order = fontOrder,
			default = getGlobalFontConfigKey(),
			get = function()
				local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textFont] or getGlobalFontConfigKey()
				local list = buildOverrideFontDropdown()
				if not list[current] then current = getGlobalFontConfigKey() end
				return current
			end,
			set = function(value)
				local list = buildOverrideFontDropdown()
				if not list[value] then value = getGlobalFontConfigKey() end
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textFont] = value
				refreshNameplateTextStyle()
			end,
			parent = true,
			element = nameplateTextToggle.element,
			parentCheck = isNameplateCustomFontEnabled,
			parentSection = expandable,
		})

		addon.functions.SettingsCreateDropdown(category, {
			var = DEFAULT_NAMEPLATE_FEATURE_KEYS.textOutline,
		text = L["nameplateTextOutline"] or "Nameplate text outline",
		desc = L["nameplateTextOutlineDesc"],
		list = nameplateTextOutlineOptions,
		order = nameplateTextOutlineOrder,
		default = globalFontStyleKey,
		get = function() return normalizeNameplateTextOutline(addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textOutline]) end,
		set = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textOutline] = normalizeNameplateTextOutline(value)
			refreshNameplateTextStyle()
		end,
		parent = true,
		element = nameplateTextToggle.element,
		parentCheck = isNameplateTextEnabled,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.textSize,
		text = L["nameplateTextSize"] or "Nameplate text size",
		desc = L["nameplateTextSizeDesc"],
		min = 0,
		max = 32,
		step = 1,
		default = 0,
		get = function() return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textSize] or 0 end,
		set = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.textSize] = value
			refreshNameplateTextStyle()
		end,
		parent = true,
		element = nameplateTextToggle.element,
		parentCheck = isNameplateTextEnabled,
		parentSection = expandable,
	})

	local nameplateMarkerAnchorOptions = {
		TOPLEFT = L["Top Left"] or "Top Left",
		TOP = L["Top"] or "Top",
		TOPRIGHT = L["Top Right"] or "Top Right",
		LEFT = L["Left"] or "Left",
		CENTER = _G.CENTER or "Center",
		RIGHT = L["Right"] or "Right",
		BOTTOMLEFT = L["Bottom Left"] or "Bottom Left",
		BOTTOM = L["Bottom"] or "Bottom",
		BOTTOMRIGHT = L["Bottom Right"] or "Bottom Right",
	}
	local nameplateMarkerAnchorOrder = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

	addon.functions.SettingsCreateHeadline(category, L["Markers"] or "Markers", {
		parentSection = expandable,
		groupID = "markers",
		order = 30,
	})

	local targetMarkersToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkers,
		text = L["nameplateTargetMarkers"] or "Show target markers on default nameplates",
		desc = L["nameplateTargetMarkersDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateTargetMarkersEnabled then
				addon.functions.SetDefaultNameplateTargetMarkersEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkers] = value and true or false
			end
		end,
		parentSection = expandable,
		order = 10,
	})

	local function areTargetMarkersEnabled() return targetMarkersToggle and targetMarkersToggle.setting and targetMarkersToggle.setting:GetValue() == true end

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerHideFriendly,
		text = L["nameplateTargetMarkerHideFriendly"] or "Hide target markers on friendly targets",
		desc = L["nameplateTargetMarkerHideFriendlyDesc"],
		newTagID = DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerHideFriendly,
		func = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerHideFriendly] = value and true or false
			if addon.functions.RefreshDefaultNameplateTargetMarkers then addon.functions.RefreshDefaultNameplateTargetMarkers() end
		end,
		parent = true,
		element = targetMarkersToggle.element,
		parentCheck = areTargetMarkersEnabled,
		parentSection = expandable,
		order = 15,
	})

	local function formatTargetMarkerAtlasOption(atlas)
		return ("|A:%s:18:18|a"):format(atlas)
	end

	local targetMarkerAtlasOptions = {
		["common-icon-forwardarrow"] = formatTargetMarkerAtlasOption("common-icon-forwardarrow"),
		["CovenantSanctum-Renown-Arrow"] = formatTargetMarkerAtlasOption("CovenantSanctum-Renown-Arrow"),
		["CovenantSanctum-Renown-DoubleArrow"] = formatTargetMarkerAtlasOption("CovenantSanctum-Renown-DoubleArrow"),
		["CovenantSanctum-Renown-DoubleArrow-Hover"] = formatTargetMarkerAtlasOption("CovenantSanctum-Renown-DoubleArrow-Hover"),
		["gearupdate-arrow-bullet-point"] = formatTargetMarkerAtlasOption("gearupdate-arrow-bullet-point"),
		["pvptalents-selectedarrow"] = formatTargetMarkerAtlasOption("pvptalents-selectedarrow"),
		["shop-header-arrow-hover"] = formatTargetMarkerAtlasOption("shop-header-arrow-hover"),
		["wowlabs-spectatecycling-arrowright"] = formatTargetMarkerAtlasOption("wowlabs-spectatecycling-arrowright"),
	}
	local targetMarkerAtlasOrder = {
		"shop-header-arrow-hover",
		"CovenantSanctum-Renown-DoubleArrow-Hover",
		"common-icon-forwardarrow",
		"CovenantSanctum-Renown-Arrow",
		"CovenantSanctum-Renown-DoubleArrow",
		"wowlabs-spectatecycling-arrowright",
		"gearupdate-arrow-bullet-point",
		"pvptalents-selectedarrow",
	}
		local function buildNameplateStatusbarDropdown()
			local map = {
				[addon.variables.nameplateFocusHealthbarDefaultTexture or "Interface\\TargetingFrame\\UI-StatusBar"] = "Blizzard Unit Frame",
				["Interface\\Buttons\\WHITE8x8"] = "Solid",
			}
			local names, hash = getCachedLSMMedia("statusbar")
			for i = 1, #names do
				local name = names[i]
				local path = hash[name]
				if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
			end

			local list, order = addon.functions.prepareListForDropdown(map)
			list[""] = _G.NONE or "None"

			wipe(nameplateStatusbarOrder)
			nameplateStatusbarOrder[1] = ""
			for i = 1, #order do
				nameplateStatusbarOrder[#nameplateStatusbarOrder + 1] = order[i]
			end

			return list
	end

	addon.functions.SettingsCreateDropdown(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerAtlas,
		text = L["nameplateTargetMarkerAtlas"] or "Target marker style",
		desc = L["nameplateTargetMarkerAtlasDesc"],
		list = targetMarkerAtlasOptions,
		order = targetMarkerAtlasOrder,
		default = "shop-header-arrow-hover",
		get = function()
			local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerAtlas]
			if type(current) ~= "string" or not targetMarkerAtlasOptions[current] then current = "shop-header-arrow-hover" end
			return current
		end,
		set = function(value)
			if type(value) ~= "string" or not targetMarkerAtlasOptions[value] then value = "shop-header-arrow-hover" end
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerAtlas] = value
			if addon.functions.RefreshDefaultNameplateTargetMarkers then addon.functions.RefreshDefaultNameplateTargetMarkers() end
		end,
		parent = true,
		element = targetMarkersToggle.element,
		parentCheck = areTargetMarkersEnabled,
		parentSection = expandable,
		order = 20,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerSize,
		text = L["nameplateTargetMarkerSize"] or "Target marker size",
		desc = L["nameplateTargetMarkerSizeDesc"],
		min = 8,
		max = 64,
		step = 1,
		default = 18,
		get = function() return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerSize] or 18 end,
		set = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.targetMarkerSize] = value
			if addon.functions.RefreshDefaultNameplateTargetMarkers then addon.functions.RefreshDefaultNameplateTargetMarkers() end
		end,
		parent = true,
		element = targetMarkersToggle.element,
		parentCheck = areTargetMarkersEnabled,
		parentSection = expandable,
		order = 30,
	})

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.healthbarTexture,
		text = L["nameplateHealthbarTexture"] or "Healthbar texture",
		desc = L["nameplateHealthbarTextureDesc"],
		listFunc = buildNameplateStatusbarDropdown,
		order = nameplateStatusbarOrder,
		height = 240,
		default = "",
		get = function()
			local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.healthbarTexture] or ""
			local list = buildNameplateStatusbarDropdown()
			if not list[current] then current = "" end
			return current
		end,
		set = function(value)
			local list = buildNameplateStatusbarDropdown()
			if not list[value] then value = "" end
			if addon.functions.SetDefaultNameplateHealthbarTexture then
				addon.functions.SetDefaultNameplateHealthbarTexture(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.healthbarTexture] = value
			end
		end,
		newTagID = DEFAULT_NAMEPLATE_FEATURE_KEYS.healthbarTexture,
		parentSection = expandable,
		order = 40,
	})

	addon.functions.SettingsCreateScrollDropdown(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.focusHealthbarTexture,
		text = L["nameplateFocusHealthbarTexture"] or "Focus healthbar texture",
		desc = L["nameplateFocusHealthbarTextureDesc"],
		listFunc = buildNameplateStatusbarDropdown,
		order = nameplateStatusbarOrder,
		height = 240,
		default = "",
		get = function()
			local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.focusHealthbarTexture] or ""
			local list = buildNameplateStatusbarDropdown()
			if not list[current] then current = "" end
			return current
		end,
		set = function(value)
			local list = buildNameplateStatusbarDropdown()
			if not list[value] then value = "" end
			if addon.functions.SetDefaultNameplateFocusHealthbarTexture then
				addon.functions.SetDefaultNameplateFocusHealthbarTexture(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.focusHealthbarTexture] = value
			end
		end,
		newTagID = DEFAULT_NAMEPLATE_FEATURE_KEYS.focusHealthbarTexture,
		parentSection = expandable,
		order = 50,
	})

	local eliteMarkersToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkers,
		text = L["nameplateEliteMarkers"] or "Show elite markers on default nameplates",
		desc = L["nameplateEliteMarkersDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateEliteMarkersEnabled then
				addon.functions.SetDefaultNameplateEliteMarkersEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkers] = value and true or false
			end
		end,
		parentSection = expandable,
		order = 50,
	})

	local function areEliteMarkersEnabled() return eliteMarkersToggle and eliteMarkersToggle.setting and eliteMarkersToggle.setting:GetValue() == true end

	local function refreshNameplateEliteMarkers()
		if addon.functions.RefreshDefaultNameplateEliteMarkers then addon.functions.RefreshDefaultNameplateEliteMarkers() end
	end

	addon.functions.SettingsCreateDropdown(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerAnchor,
		text = L["nameplateEliteMarkerAnchor"] or "Elite marker anchor",
		desc = L["nameplateEliteMarkerAnchorDesc"],
		list = nameplateMarkerAnchorOptions,
		order = nameplateMarkerAnchorOrder,
		default = "LEFT",
		get = function()
			local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerAnchor]
			if type(current) ~= "string" or not nameplateMarkerAnchorOptions[current] then current = "LEFT" end
			return current
		end,
		set = function(value)
			if type(value) ~= "string" or not nameplateMarkerAnchorOptions[value] then value = "LEFT" end
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerAnchor] = value
			refreshNameplateEliteMarkers()
		end,
		parent = true,
		element = eliteMarkersToggle.element,
		parentCheck = areEliteMarkersEnabled,
		parentSection = expandable,
		order = 60,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerSize,
		text = L["nameplateEliteMarkerSize"] or "Elite marker size",
		desc = L["nameplateEliteMarkerSizeDesc"],
		min = 8,
		max = 48,
		step = 1,
		default = 18,
		get = function() return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerSize] or 18 end,
		set = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.eliteMarkerSize] = value
			refreshNameplateEliteMarkers()
		end,
		parent = true,
		element = eliteMarkersToggle.element,
		parentCheck = areEliteMarkersEnabled,
		parentSection = expandable,
		order = 70,
	})

	addon.functions.SettingsCreateHeadline(category, L["Quest"] or "Quest", {
		parentSection = expandable,
		groupID = "quest",
		order = 40,
	})

	local questMarkersToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkers,
		text = L["nameplateQuestMarkers"] or "Show quest icons on default nameplates",
		desc = L["nameplateQuestMarkersDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateQuestMarkersEnabled then
				addon.functions.SetDefaultNameplateQuestMarkersEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkers] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	local function areQuestMarkersEnabled() return questMarkersToggle and questMarkersToggle.setting and questMarkersToggle.setting:GetValue() == true end

	local function refreshNameplateQuestMarkers()
		if addon.functions.RefreshDefaultNameplateQuestMarkers then addon.functions.RefreshDefaultNameplateQuestMarkers() end
	end

	addon.functions.SettingsCreateDropdown(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerAnchor,
		text = L["nameplateQuestMarkerAnchor"] or "Quest icon anchor",
		desc = L["nameplateQuestMarkerAnchorDesc"],
		list = nameplateMarkerAnchorOptions,
		order = nameplateMarkerAnchorOrder,
		default = "RIGHT",
		get = function()
			local current = addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerAnchor]
			if type(current) ~= "string" or not nameplateMarkerAnchorOptions[current] then current = "RIGHT" end
			return current
		end,
		set = function(value)
			if type(value) ~= "string" or not nameplateMarkerAnchorOptions[value] then value = "RIGHT" end
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerAnchor] = value
			refreshNameplateQuestMarkers()
		end,
		parent = true,
		element = questMarkersToggle.element,
		parentCheck = areQuestMarkersEnabled,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateSlider(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerSize,
		text = L["nameplateQuestMarkerSize"] or "Quest icon size",
		desc = L["nameplateQuestMarkerSizeDesc"],
		min = 8,
		max = 48,
		step = 1,
		default = 18,
		get = function() return addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerSize] or 18 end,
		set = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.questMarkerSize] = value
			refreshNameplateQuestMarkers()
		end,
		parent = true,
		element = questMarkersToggle.element,
		parentCheck = areQuestMarkersEnabled,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateHeadline(category, L["Colors"] or "Colors", {
		parentSection = expandable,
		groupID = "colors",
		order = 50,
	})

	local mobColorsToggle = addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColors,
		text = L["nameplateMobColors"] or "Color default nameplates",
		desc = L["nameplateMobColorsDesc"],
		func = function(value)
			if addon.functions.SetDefaultNameplateMobColorsEnabled then
				addon.functions.SetDefaultNameplateMobColorsEnabled(value)
			else
				addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColors] = value and true or false
			end
		end,
		parentSection = expandable,
	})

	local function areMobColorsEnabled() return mobColorsToggle and mobColorsToggle.setting and mobColorsToggle.setting:GetValue() == true end

	local function refreshNameplateMobColorScope()
		if addon.functions.RefreshDefaultNameplateMobColors then addon.functions.RefreshDefaultNameplateMobColors() end
	end

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorsInDungeons,
		text = L["nameplateMobColorsInDungeons"] or "Apply in dungeons",
		desc = L["nameplateMobColorsInDungeonsDesc"],
		func = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorsInDungeons] = value and true or false
			refreshNameplateMobColorScope()
		end,
		parent = true,
		element = mobColorsToggle.element,
		parentCheck = areMobColorsEnabled,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorsOutsideDungeons,
		text = L["nameplateMobColorsOutsideDungeons"] or "Also apply outside dungeons",
		desc = L["nameplateMobColorsOutsideDungeonsDesc"],
		func = function(value)
			addon.db[DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorsOutsideDungeons] = value and true or false
			refreshNameplateMobColorScope()
		end,
		parent = true,
		element = mobColorsToggle.element,
		parentCheck = areMobColorsEnabled,
		parentSection = expandable,
	})

	local function createNameplateMobColorSourceToggle(enabledVar, colorVar, text, newTagID, desc)
		addon.functions.SettingsCreateCheckbox(category, {
			var = enabledVar,
			newTagID = newTagID,
			text = text,
			desc = desc,
			func = function(value)
				addon.db[enabledVar] = value and true or false
				refreshNameplateMobColorScope()
			end,
			getColor = function()
				local color = addon.db[colorVar] or (addon.dbDefaults and addon.dbDefaults[colorVar]) or { r = 1, g = 1, b = 1, a = 1 }
				return color.r or 1, color.g or 1, color.b or 1, color.a or 1
			end,
			setColor = function(_, r, g, b, a)
				addon.db[colorVar] = { r = r, g = g, b = b, a = a }
				refreshNameplateMobColorScope()
			end,
			getDefaultColor = function()
				local color = addon.dbDefaults and addon.dbDefaults[colorVar]
				return color and color.r or 1, color and color.g or 1, color and color.b or 1, color and color.a or 1
			end,
			parent = true,
			element = mobColorsToggle.element,
			parentCheck = areMobColorsEnabled,
			parentSection = expandable,
		})
	end

	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorFocusEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorFocus, L["nameplateMobColorFocus"] or "Focus color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorFocusEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorBossEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorBoss, L["nameplateMobColorBoss"] or "Boss color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorBossEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMinibossEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMiniboss, L["nameplateMobColorMiniboss"] or "Mini-boss color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMinibossEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorCasterEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorCaster, L["nameplateMobColorCaster"] or "Caster color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorCasterEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMeleeEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMelee, L["nameplateMobColorMelee"] or "Melee color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorMeleeEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorNeutralEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorNeutral, L["nameplateMobColorNeutral"] or "Neutral color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorNeutralEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTappedEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTapped, L["nameplateMobColorTapped"] or "Tapped color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTappedEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTrivialEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTrivial, L["nameplateMobColorTrivial"] or "Trivial color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTrivialEnabled)

	addon.functions.SettingsCreateSectionHeader(category, L["nameplateMobThreatColors"] or "Threat colors", {
		parentSection = expandable,
	})

	createNameplateMobColorSourceToggle(
		DEFAULT_NAMEPLATE_FEATURE_KEYS.mobTankMode,
		DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorTankMode,
		L["nameplateMobTankMode"] or "Tank mode color",
		nil,
		L["nameplateMobTankModeDesc"] or "When you are tanking, colors enemies currently in combat with you using a dedicated color instead of the normal mob coloring."
	)

	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatWarningEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatWarning, L["nameplateMobColorThreatWarning"] or "Threat warning color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatWarningEnabled)
	createNameplateMobColorSourceToggle(DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatLostEnabled, DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatLost, L["nameplateMobColorThreatLost"] or "Threat lost color", DEFAULT_NAMEPLATE_FEATURE_KEYS.mobColorThreatLostEnabled)
end

local function createTotalAbsorbTrackerSettings(category, expandable)
	if not category or not expandable then return end
	if addon.SettingsLayout._eqolTotalAbsorbTrackerSettingsBuilt then return end
	addon.SettingsLayout._eqolTotalAbsorbTrackerSettingsBuilt = true

	addon.functions.SettingsCreateHeadline(category, L["TotalAbsorbTracker"] or "Total Absorb Tracker", {
		parentSection = expandable,
	})
	addon.functions.SettingsCreateCheckbox(category, {
		var = "totalAbsorbTrackerEnabled",
		text = L["totalAbsorbTrackerEnabled"] or "Enable Total Absorb tracker",
		desc = L["totalAbsorbTrackerDesc"] or "Shows your current player absorb amount in a standalone icon tracker.",
		func = function(value)
			addon.db["totalAbsorbTrackerEnabled"] = value and true or false
			if addon.Aura and addon.Aura.TotalAbsorbTracker and addon.Aura.TotalAbsorbTracker.OnSettingChanged then
				addon.Aura.TotalAbsorbTracker:OnSettingChanged(addon.db["totalAbsorbTrackerEnabled"])
			end
		end,
		parentSection = expandable,
	})
	addon.functions.SettingsCreateText(category, "|cffffd700" .. (L["totalAbsorbTrackerEditModeHint"] or "Configure icon, text, text-only mode, anchor, and offsets in Edit Mode.") .. "|r", {
		parentSection = expandable,
	})
end

local function createCastbarCategory()
	local category = addon.SettingsLayout.rootUI
	local label = L["CastbarsAndCooldowns"] or "Castbars & Cooldowns"

	local expandable = addon.functions.SettingsCreateExpandableSection(category, {
		name = label,
		description = L["configCenterPageDescCastbarsCooldowns"]
			or "Configure cast bars, GCD and cooldown displays, combat text, focus interrupt alerts and timing helpers.",
		expanded = false,
		colorizeTitle = false,
		newTagID = "CastbarsAndCooldowns",
		iconKey = "castbar",
	})
	addon.SettingsLayout.uiCastbarsExpandable = expandable

	addon.functions.SettingsCreateHeadline(category, L["FocusInterruptTracker"] or "Focus Interrupt Tracker", {
		parentSection = expandable,
	})
	local focusInterruptTrackerEnabled = addon.functions.SettingsCreateCheckbox(category, {
		var = "focusInterruptTrackerEnabled",
		text = L["focusInterruptTrackerEnabled"] or "Enable Focus interrupt tracker",
		desc = L["focusInterruptTrackerDesc"] or "Shows an interrupt indicator near the focus frame when your interrupt is ready and the focus cast can be interrupted.",
		get = function()
			local cfg = addon.db and addon.db.focusInterruptTracker
			return cfg and cfg.enabled == true or false
		end,
		func = function(value)
			addon.db.focusInterruptTracker = type(addon.db.focusInterruptTracker) == "table" and addon.db.focusInterruptTracker or {}
			addon.db.focusInterruptTracker.enabled = value and true or false
			local tracker = addon.Aura and addon.Aura.FocusInterruptTracker
			if tracker and tracker.OnSettingChanged then tracker:OnSettingChanged(addon.db.focusInterruptTracker.enabled) end
		end,
		parentSection = expandable,
	})
	local focusInterruptSound = addon.functions.SettingsCreateCheckbox(category, {
		var = "focusInterruptTrackerSoundEnabled",
		text = L["focusInterruptTrackerSoundEnabled"] or "Play sound on focus cast",
		desc = L["focusInterruptTrackerSoundEnabledDesc"] or "Plays a sound when your focus starts casting while your interrupt is ready.",
		get = function()
			local cfg = addon.db and addon.db.focusInterruptTracker
			local sound = cfg and cfg.sound
			return sound and sound.enabled == true or false
		end,
		func = function(value)
			addon.db.focusInterruptTracker = type(addon.db.focusInterruptTracker) == "table" and addon.db.focusInterruptTracker or {}
			addon.db.focusInterruptTracker.sound = type(addon.db.focusInterruptTracker.sound) == "table" and addon.db.focusInterruptTracker.sound or {}
			addon.db.focusInterruptTracker.sound.enabled = value and true or false
		end,
		parent = true,
		element = focusInterruptTrackerEnabled and focusInterruptTrackerEnabled.element,
		parentCheck = function()
			local cfg = addon.db and addon.db.focusInterruptTracker
			return cfg and cfg.enabled == true or false
		end,
		parentSection = expandable,
	})
	addon.functions.SettingsCreateSoundDropdown(category, {
		var = "focusInterruptTrackerSoundFile",
		text = SOUND,
		desc = L["focusInterruptTrackerSoundFileDesc"] or "SharedMedia sound to play for new focus casts.",
		listFunc = buildFocusInterruptSoundDropdown,
		order = focusInterruptSoundOrder,
		default = "",
		get = function() return getNormalizedFocusInterruptSoundValue() end,
		set = function(value)
			addon.db.focusInterruptTracker = type(addon.db.focusInterruptTracker) == "table" and addon.db.focusInterruptTracker or {}
			addon.db.focusInterruptTracker.sound = type(addon.db.focusInterruptTracker.sound) == "table" and addon.db.focusInterruptTracker.sound or {}
			addon.db.focusInterruptTracker.sound.file = type(value) == "string" and value or ""
		end,
		callback = function(value) previewFocusInterruptSound(value) end,
		parent = true,
		element = focusInterruptSound and focusInterruptSound.element,
		parentCheck = function()
			local cfg = addon.db and addon.db.focusInterruptTracker
			local sound = cfg and cfg.sound
			return cfg and cfg.enabled == true and sound and sound.enabled == true or false
		end,
		parentSection = expandable,
		placeholderText = NONE,
		playbackChannel = "Master",
	})
	addon.functions.SettingsCreateText(category, "|cffffd700" .. (L["focusInterruptTrackerEditModeHint"] or "Configure display mode, icon, font, anchor, and border in Edit Mode.") .. "|r", {
		parentSection = expandable,
	})
	addon.functions.SettingsCreateText(
		category,
		"|cffffd700" .. (L["focusInterruptTrackerSoundWarning"] or "Sound also plays for non-interruptible casts because the interruptibility flag is secret.") .. "|r",
		{
			parentSection = expandable,
		}
	)

	local combatTextGroupID = "combat-indicators"
	local combatTextGroupTitle = L["CombatText"] or "Combat text"
	addon.functions.SettingsCreateHeadline(category, combatTextGroupTitle, {
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	local combatTextEnabled = addon.functions.SettingsCreateCheckbox(category, {
		var = "combatTextEnabled",
		text = L["combatTextEnabled"] or "Enable combat text",
		desc = L["combatTextDesc"],
		func = function(value)
			addon.db["combatTextEnabled"] = value and true or false
			if addon.CombatText and addon.CombatText.OnSettingChanged then addon.CombatText:OnSettingChanged(addon.db["combatTextEnabled"]) end
		end,
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	local function isCombatTextEnabled()
		return combatTextEnabled and combatTextEnabled.setting and combatTextEnabled.setting:GetValue() == true
	end
	local combatAlwaysVisible = addon.functions.SettingsCreateCheckbox(category, {
		var = "combatTextAlwaysVisible",
		text = L["combatTextAlwaysVisible"] or "Always show combat text",
		desc = L["combatTextAlwaysVisibleDesc"] or "Keeps the combat text visible until the next combat state change.",
		func = function(value)
			addon.db["combatTextAlwaysVisible"] = value and true or false
			if addon.CombatText then
				if addon.CombatText.RefreshDisplayMode then
					addon.CombatText:RefreshDisplayMode()
				elseif addon.CombatText.RefreshHideTimer then
					addon.CombatText:RefreshHideTimer()
				end
			end
		end,
		parent = true,
		element = combatTextEnabled and combatTextEnabled.element,
		parentCheck = isCombatTextEnabled,
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	local combatAlwaysModeCombatOnly = addon.CombatText and addon.CombatText.ALWAYS_VISIBLE_MODE_COMBAT_ONLY or "COMBAT_ONLY"
	local combatAlwaysModeStatus = addon.CombatText and addon.CombatText.ALWAYS_VISIBLE_MODE_STATUS or "STATUS"
	local combatAlwaysModeOptions = {
		[combatAlwaysModeCombatOnly] = L["combatTextAlwaysVisibleModeCombatOnly"] or "Only while in combat (+Combat)",
		[combatAlwaysModeStatus] = L["combatTextAlwaysVisibleModeStatus"] or "Always show status (+/-Combat)",
	}
	addon.functions.SettingsCreateDropdown(category, {
		var = "combatTextAlwaysVisibleMode",
		text = L["combatTextAlwaysVisibleMode"] or "Always-show mode",
		desc = L["combatTextAlwaysVisibleModeDesc"] or "Choose whether always-show mode is only active in combat, or shows + and - permanently.",
		list = combatAlwaysModeOptions,
		order = { combatAlwaysModeCombatOnly, combatAlwaysModeStatus },
		default = combatAlwaysModeStatus,
		get = function()
			local mode = addon.db["combatTextAlwaysVisibleMode"]
			if mode ~= combatAlwaysModeCombatOnly and mode ~= combatAlwaysModeStatus then mode = combatAlwaysModeStatus end
			return mode
		end,
		set = function(mode)
			if mode ~= combatAlwaysModeCombatOnly and mode ~= combatAlwaysModeStatus then mode = combatAlwaysModeStatus end
			addon.db["combatTextAlwaysVisibleMode"] = mode
			if addon.CombatText and addon.CombatText.RefreshDisplayMode then addon.CombatText:RefreshDisplayMode() end
		end,
		parent = true,
		element = combatAlwaysVisible and combatAlwaysVisible.element,
		parentCheck = function() return isCombatTextEnabled() and combatAlwaysVisible and combatAlwaysVisible.setting and combatAlwaysVisible.setting:GetValue() == true end,
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	addon.functions.SettingsCreateInput(category, {
		var = "combatTextEnterText",
		text = L["combatTextEnterText"] or "Entering combat text",
		desc = L["combatTextEnterTextDesc"] or "Custom text shown when entering combat. Leave empty to use the localized default.",
		default = "",
		get = function()
			return addon.CombatText and addon.CombatText.GetEnterText and addon.CombatText:GetEnterText() or addon.db["combatTextEnterText"] or ""
		end,
		set = function(value)
			addon.db["combatTextEnterText"] = type(value) == "string" and value or ""
			if addon.CombatText and addon.CombatText.ApplyLayoutData then addon.CombatText:ApplyLayoutData({ enterText = addon.db["combatTextEnterText"] }) end
		end,
		maxChars = 64,
		inputWidth = 180,
		placeholder = addon.CombatText and addon.CombatText.GetDefaultEnterText and addon.CombatText:GetDefaultEnterText() or L["combatTextEnter"] or "+Combat",
		selectAllOnFocus = true,
		parent = true,
		element = combatTextEnabled and combatTextEnabled.element,
		parentCheck = isCombatTextEnabled,
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	addon.functions.SettingsCreateInput(category, {
		var = "combatTextLeaveText",
		text = L["combatTextLeaveText"] or "Leaving combat text",
		desc = L["combatTextLeaveTextDesc"] or "Custom text shown when leaving combat. Leave empty to use the localized default.",
		default = "",
		get = function()
			return addon.CombatText and addon.CombatText.GetLeaveText and addon.CombatText:GetLeaveText() or addon.db["combatTextLeaveText"] or ""
		end,
		set = function(value)
			addon.db["combatTextLeaveText"] = type(value) == "string" and value or ""
			if addon.CombatText and addon.CombatText.ApplyLayoutData then addon.CombatText:ApplyLayoutData({ leaveText = addon.db["combatTextLeaveText"] }) end
		end,
		maxChars = 64,
		inputWidth = 180,
		placeholder = addon.CombatText and addon.CombatText.GetDefaultLeaveText and addon.CombatText:GetDefaultLeaveText() or L["combatTextLeave"] or "-Combat",
		selectAllOnFocus = true,
		parent = true,
		element = combatTextEnabled and combatTextEnabled.element,
		parentCheck = isCombatTextEnabled,
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	addon.functions.SettingsCreateSectionHeader(category, _G.COMBAT_TEXT_LABEL or combatTextGroupTitle, {
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})
	addon.functions.SettingsCreateCheckboxes(category, {
		{
			var = "floatingCombatTextCombatDamage_v2",
			text = L["floatingCombatTextCombatDamage_v2"],
			get = function() return getCVarOptionState("floatingCombatTextCombatDamage_v2") end,
			func = function(value) setCVarOptionState("floatingCombatTextCombatDamage_v2", value) end,
			default = false,
			parentSection = expandable,
			groupID = combatTextGroupID,
			groupTitle = combatTextGroupTitle,
		},
		{
			var = "floatingCombatTextCombatHealing_v2",
			text = L["floatingCombatTextCombatHealing_v2"],
			get = function() return getCVarOptionState("floatingCombatTextCombatHealing_v2") end,
			func = function(value) setCVarOptionState("floatingCombatTextCombatHealing_v2", value) end,
			default = false,
			parentSection = expandable,
			groupID = combatTextGroupID,
			groupTitle = combatTextGroupTitle,
		},
	})
	addon.functions.SettingsCreateText(category, "|cffffd700" .. (L["combatTextEditModeHint"] or "Configure text size, font, color, and position in Edit Mode.") .. "|r", {
		parentSection = expandable,
		groupID = combatTextGroupID,
		groupTitle = combatTextGroupTitle,
	})

	local function isCustomCastbarEnabled()
		local castbar = addon.Aura and (addon.Aura.Castbar or addon.Aura.UFStandaloneCastbar)
		local cfg = castbar and castbar.GetConfig and castbar.GetConfig()
		return type(cfg) == "table" and cfg.enabled == true
	end

	local function getCastbarOptions()
		local options = {}
		if not isCustomCastbarEnabled() then table.insert(options, { value = "PlayerCastingBarFrame", text = PLAYER }) end
		if not isEQoLUnitEnabled("target") then table.insert(options, { value = "TargetFrameSpellBar", text = TARGET }) end
		if not isEQoLUnitEnabled("focus") then table.insert(options, { value = "FocusFrameSpellBar", text = FOCUS }) end
		return options
	end
	local function shouldShowCastbarDropdown() return #getCastbarOptions() > 0 end
	local function expandWith(predicate)
		local parentCheck = function()
			if expandable and expandable.IsExpanded and expandable:IsExpanded() == false then return false end
			return predicate()
		end
		return addon.functions.RegisterConfigParentSection(parentCheck, expandable)
	end

	addon.functions.SettingsCreateHeadline(category, L["CastBars2"], {
		parentSection = expandable,
	})

	addon.functions.SettingsCreateMultiDropdown(category, {
		var = "hiddenCastBars",
		text = L["castBarsToHide2"],
		desc = L["hiddenCastBarsDesc"],
		optionfunc = getCastbarOptions,
		isSelectedFunc = function(key)
			if not key then return false end
			if addon.db.hiddenCastBars and addon.db.hiddenCastBars[key] then return true end
			return false
		end,
		setSelectedFunc = function(key, shouldSelect)
			addon.db.hiddenCastBars = addon.db.hiddenCastBars or {}
			addon.db.hiddenCastBars[key] = shouldSelect and true or false
			addon.functions.ApplyCastBarVisibility()
		end,
		isEnabled = shouldShowCastbarDropdown,
		parentSection = expandWith(shouldShowCastbarDropdown),
	})

	createCooldownViewerDropdowns(category, expandable)
	createSpellActivationOverlayDropdown(category, expandable)
end

local function ensureBarsResourcesCategory()
	local category = addon.SettingsLayout.rootUI
	local expandable = addon.SettingsLayout.uiBarsResourcesExpandable
	if not expandable then
		expandable = addon.functions.SettingsCreateExpandableSection(category, {
			name = L["BarsAndResources"] or "XP, Reputation & Absorb Bars",
			description = L["configCenterPageDescBarsResources"]
				or "Configure the default XP and reputation bars plus the standalone absorb tracker.",
			expanded = false,
			colorizeTitle = false,
			iconKey = "resource",
		})
		addon.SettingsLayout.uiBarsResourcesExpandable = expandable
	end

	createTotalAbsorbTrackerSettings(category, expandable)
end

createActionBarCategory()
createFrameCategory()
createNameplatesCategory()
createCastbarCategory()
ensureBarsResourcesCategory()
