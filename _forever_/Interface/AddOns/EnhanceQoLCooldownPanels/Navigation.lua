local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Panels = addon.Aura.CooldownPanels
local Helper = Panels.helper
local Navigation = {}
Panels.Navigation = Navigation

local function fields(text)
	local result = {}
	for field in text:gmatch("%S+") do result[#result + 1] = field end
	return result
end
local scopes = {
	Display = fields("requiredTalentSpellID"),
	Layout = fields("barPanelOrientation barPanelWidth barPanelHeight panelWidthMode panelWidth panelWidthSource panelWidthElement spacing direction wrapCount wrapDirection growthPoint radialRadius radialRotation radialArcDegrees strata rowSizes"),
	Icon = fields("barPanelIconSize iconSize iconSizeSeparate iconWidth iconHeight iconOffsetX iconOffsetY iconSizeUseGlobal showIconTexture showIconTextureUseGlobal hideIcon iconShape iconZoom showCraftingQuality showCraftingQualityUseGlobal craftingQualityScale"),
	Border = fields("iconBorderEnabled iconBorderTexture iconBorderSize iconBorderOffset iconBorderColor"),
	Visibility = fields("showTooltips tooltipUseEditModePosition hideOnCooldown showOnCooldown cdmAuraAlwaysShowMode cdmAuraMissingOnlyMyOwn cdmAuraAlwaysShowUseGlobal cooldownVisibilityUseGlobal hideBorderOnCooldown hideBorderOffCooldown visibility hideInVehicle hideInPetBattle hideInClientScene opacityOutOfCombat opacityInCombat specFilter heroSpecID heroSpecFilter heroSpecEnabled"),
	Availability = fields("rangeOverlayEnabled rangeOverlayColor noDesaturation noDesaturationUseGlobal checkPower checkPowerUseGlobal powerTintColor hideWhenNoResource hideWhenNoResourceUseGlobal"),
	CooldownText = fields("showCooldownText showCooldownTextUseGlobal cooldownTextUseGlobal cooldownTextFont cooldownTextSize cooldownTextStyle cooldownTextColor cooldownTextX cooldownTextY"),
	StaticText = fields("staticText staticTextShowOnCooldown staticTextUseGlobal staticTextFont staticTextSize staticTextStyle staticTextColor staticTextAnchor staticTextX staticTextY"),
	Stacks = fields("showItemCount showItemUses showStacks showStacksUseGlobal stackStyleUseGlobal stackAnchor stackX stackY stackFont stackFontSize stackFontStyle stackColor"),
	Charges = fields("showCharges showChargesUseGlobal chargesStyleUseGlobal chargesAnchor chargesX chargesY chargesFont chargesFontSize chargesFontStyle chargesColor chargesHideWhenZero"),
	Keybinds = fields("keybindsEnabled keybindsIgnoreItems keybindAnchor keybindX keybindY keybindFont keybindFontStyle keybindFontSize"),
	CooldownSwipe = fields("cooldownVisualsUseGlobal showChargesCooldown hideChargeCooldownText cooldownDrawEdge cooldownDrawBling cooldownDrawSwipe cooldownSwipeColor cooldownGcdDrawEdge cooldownGcdDrawBling cooldownGcdDrawSwipe"),
	Glow = fields("glowReady glowReadyUseGlobal glowUseGlobal readyGlowCheckPower readyGlowCheckPowerUseGlobal readyGlowStyle readyGlowInset readyGlowColor readyGlowUseClassColor glowUseClassColor glowStyle glowInset glowColor glowDuration readyGlowDuration hideGlowOutOfCombat interruptGlow glowOtherAura glowOtherAuraColor glowPixelCount glowPixelSpeed glowPixelThickness glowPixelBorder procGlowEnabled procGlowUseGlobal procGlowStyle procGlowInset procGlowColor pandemicGlow pandemicGlowStyle pandemicGlowInset pandemicGlowColor auraDurationThresholdGlowEnabled auraDurationThresholdAsSeconds auraDurationThresholdMaxDuration auraDurationThresholdValue auraDurationThresholdGlowStyle auraDurationThresholdGlowColor"),
	AuraBehavior = fields("cdmAuraOverlayEnabled cdmAuraOverlayColor activationOverlayReverse activationOverlayDesaturate activationOverlayOnly activationOverlayGlow activationOverlayGlowColor"),
	Activation = fields("cdmAuraOverlayEnabledUseGlobal cdmAuraOverlayEnabled cdmAuraOverlayUnit cdmAuraOverlayTargetPlayerOnly cdmAuraOverlaySpellIDs cdmAuraOverlayHideIcon autoCooldownDurationEnabled customCooldownDurationEnabled customCooldownDurationOnCooldownEnabled customCooldownDurationOnCooldownMultipleStacks customCooldownDuration customCooldownDurationTalentEnabled customCooldownDurationTalentSpellID customCooldownDurationTalentDuration activationOverlayBehaviorUseGlobal activationOverlayColor activationOverlayReverse activationOverlayDesaturate activationOverlayOnly activationOverlayGlow customCooldownDurationGlowStyle customCooldownDurationGlowThreshold activationOverlayGlowColor"),
	StateTexture = fields("stateTextureInput stateTextureShowWithoutProc stateTextureDouble stateTextureMirror stateTextureMirrorSecond stateTextureMirrorVertical stateTextureMirrorVerticalSecond stateTextureScale stateTextureWidth stateTextureHeight stateTextureAngle stateTextureSpacingX stateTextureSpacingY"),
	Sound = fields("soundReady soundReadyFile auraAppliedSound auraAppliedSoundFile auraApplicationsIncreasedSound auraApplicationsIncreasedSoundFile auraRemovedSound auraRemovedSoundFile"),
}
local glowTabs = {
	Proc = { name = L["CooldownPanelProcGlow"], fields = fields("procGlowEnabled procGlowUseGlobal procGlowStyle procGlowInset procGlowColor") },
	Pandemic = { name = L["CooldownPanelGlowPandemic"], fields = fields("pandemicGlow pandemicGlowStyle pandemicGlowInset pandemicGlowColor") },
	Threshold = { name = L["CooldownPanelBarDurationThresholdGlowEnabled"], fields = fields("auraDurationThresholdGlowEnabled auraDurationThresholdAsSeconds auraDurationThresholdMaxDuration auraDurationThresholdValue auraDurationThresholdGlowStyle auraDurationThresholdGlowColor") },
}
for suffix, spec in pairs(glowTabs) do
	scopes["Glow" .. suffix] = spec.fields
	for _, field in ipairs(spec.fields) do
		for index = #scopes.Glow, 1, -1 do if scopes.Glow[index] == field then table.remove(scopes.Glow, index) end end
	end
end
local barScopes = {
	Layout = fields("barWidth barHeight barOrientation barOffsetX barOffsetY barPanelOrientation barPanelWidth barPanelHeight barPanelOffsetX barPanelOffsetY"),
	Fill = fields("fillSparkEnabled fillSparkUseClassColor fillSparkColor fillSparkWidth fillSparkHeight fillSparkOffsetX fillSparkOffsetY barTexture barBackgroundTexture barColor barBackgroundColor barProcGlowColor"),
	Icon = fields("barShowIcon barIconSize barIconAnchorToBar barIconPosition barIconOffsetX barIconOffsetY"),
	Border = fields("barBorderEnabled barBorderSize barBorderOffset barBorderTexture barBorderColor"),
	Label = fields("barShowLabel barLabelAnchor barLabelOffsetX barLabelOffsetY barLabelFont barLabelStyle barLabelSize barLabelColor"),
	ValueText = fields("barValueAnchor barValueOffsetX barValueOffsetY barValueFont barValueStyle barValueSize barValueColor"),
	Charges = fields("barChargesSegmented barChargesGap barSegmentDirection barSegmentReverse barShowValueText barShowChargeDuration barDurationTextProfile"),
	Cooldown = fields("barShowValueText barDurationTextProfile barFillMode barReverseFill showStacks"),
	Stacks = fields("showStacks barShowStackText barStackMax barStackTalentMaxEnabled barStackTalentSpellID barStackTalentMax barStackMaxColorEnabled barStackMaxColor barStacksSegmented barStackSeparatedOffset barStackDividerColor barStackDividerThickness barStackAnchor barStackFont barStackStyle barStackSize barStackColor barStackOffsetX barStackOffsetY"),
	DurationColors = fields("barDurationColorEnabled barDurationThresholdAsSeconds barDurationThresholdMaxDuration barDurationThresholdGlowEnabled barDurationThresholdGlowIndex barDurationThresholdGlowStyle barDurationThresholdGlowColor"),
	Visibility = fields("alwaysShow cdmAuraAlwaysShowUseGlobal cdmAuraAlwaysShowMode cdmAuraMissingOnlyMyOwn cooldownVisibilityUseGlobal hideOnCooldown showOnCooldown"),
}
for index = 1, 3 do
	for _, suffix in ipairs({ "Enabled", "Value", "Color" }) do
		barScopes.Stacks[#barScopes.Stacks + 1] = "barStackThreshold" .. index .. suffix
		barScopes.DurationColors[#barScopes.DurationColors + 1] = "barDurationThreshold" .. index .. suffix
	end
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function category(id, name, groups) return { id = id, name = name, groups = groups } end
local function setHint(data, target)
	if not target or data == target then return end
	data.navigationHint = function()
		if target.isShown and not target.isShown() and target.navigationHint then return target.navigationHint() end
		return target.name, nil, target.parentId
	end
end
local function shorten(data)
	local names = {
		[L["Icon X"]] = L["Offset X"], [L["Icon Y"]] = L["Offset Y"],
		[L["Cooldown text font"]] = L["Font"], [L["Cooldown text size"]] = (_G.FONT_SIZE or L["Size"]),
		[L["Cooldown text outline"]] = L["Font outline"], [L["Cooldown text color"]] = L["Color"],
		[L["Cooldown text offset X"]] = L["Offset X"], [L["Cooldown text offset Y"]] = L["Offset Y"],
		[L["CooldownPanelCountAnchor"]] = L["Anchor"], [L["CooldownPanelCountOffsetX"]] = L["Offset X"], [L["CooldownPanelCountOffsetY"]] = L["Offset Y"],
		[L["CooldownPanelChargesAnchor"]] = L["Anchor"], [L["CooldownPanelChargesOffsetX"]] = L["Offset X"], [L["CooldownPanelChargesOffsetY"]] = L["Offset Y"],
		[L["CooldownPanelKeybindsAnchor"]] = L["Anchor"], [L["CooldownPanelKeybindsOffsetX"]] = L["Offset X"], [L["CooldownPanelKeybindsOffsetY"]] = L["Offset Y"],
		[L["Text X Offset"]] = L["Offset X"], [L["Text Y Offset"]] = L["Offset Y"],
		[L["CooldownPanelFontStyle"]] = L["Font outline"],
	}
	if data.parentId and data.parentId:find("Border", 1, true) then
		names[L["Border texture"]], names[L["Border size"]], names[L["Border offset"]] = L["Texture"], L["Size"], L["Offset"]
	end
	data.name = names[data.name] or data.name
end

local function refresh(kind, panelId, rebuildIndex)
	local panel = Panels:GetPanel(panelId)
	if panel and Helper.InvalidateFixedLayoutCache then Helper.InvalidateFixedLayoutCache(panel) end
	if panel and Panels.BumpFixedGroupEffectiveLayoutVersion then Panels.BumpFixedGroupEffectiveLayoutVersion(panel) end
	if rebuildIndex and Panels.RebuildSpellIndex then Panels:RebuildSpellIndex()
	else
		if Panels.UpdateEventRegistration then Panels:UpdateEventRegistration() end
		if Panels.RebuildPowerIndex then Panels:RebuildPowerIndex() end
	end
	Panels:RefreshPanel(panelId)
	Panels:RefreshEditor()
	if kind == "fixed" then Panels:RefreshLayoutFixedGroupStandaloneMenu()
	elseif kind == "panel" then Panels:RefreshLayoutPanelStandaloneMenu() end
end

function Navigation.CustomDurationTalentSettings(panelId, entryId)
	local types = addon.EditModeLib.SettingType
	local parentId = "cooldownPanelStandaloneActivation"
	local function entry()
		local panel = Panels:GetPanel(panelId)
		return panel and panel.entries and panel.entries[entryId]
	end
	local function shown()
		local current = entry()
		return current and Panels:SupportsEntryCustomCooldownDuration(current, current.type)
	end
	local function disabled()
		local current = entry()
		return not (current and (current.customCooldownDurationEnabled == true or current.customCooldownDurationOnCooldownEnabled == true))
	end
	local function ruleDisabled() return disabled() or not (entry() and entry().customCooldownDurationTalentEnabled == true) end
	local function set(field, value)
		if InCombatLockdown() then return end
		local current = entry()
		if not current or current[field] == value then return end
		current[field] = value
		if Panels.ClearEntryCustomCooldownDuration then Panels:ClearEntryCustomCooldownDuration(panelId, entryId, true) end
		Panels:RefreshPanel(panelId)
		Panels:RefreshEditor()
		Panels:RefreshLayoutEntryStandaloneMenu(true)
	end
	return {
		{ name = L["CooldownPanelCustomDurationTalentEnabled"], tooltip = L["CooldownPanelCustomDurationTalentTooltip"],
			kind = types.Checkbox, parentId = parentId, navigationField = "customCooldownDurationTalentEnabled",
			isShown = shown, disabled = disabled,
			get = function() return entry() and entry().customCooldownDurationTalentEnabled == true or false end,
			set = function(_, value)
				local current = entry()
				if not InCombatLockdown() and value == true and current and not ((tonumber(current.customCooldownDurationTalentDuration) or 0) > 0) then
					current.customCooldownDurationTalentDuration = Helper.ClampNumber(current.customCooldownDuration, 1, Helper.CUSTOM_COOLDOWN_DURATION_MAX or 300, 1)
				end
				set("customCooldownDurationTalentEnabled", value == true)
			end },
		{ name = L["Talent spell ID"], kind = types.Input, parentId = parentId, navigationField = "customCooldownDurationTalentSpellID",
			inputWidth = 120, numeric = true, maxChars = 10, isShown = shown, disabled = ruleDisabled,
			get = function() return entry() and entry().customCooldownDurationTalentSpellID or 0 end,
			set = function(_, value) set("customCooldownDurationTalentSpellID", Helper.ClampInt(value, 0, 2147483647, 0)) end },
		{ name = L["CooldownPanelCustomDurationTalentSeconds"], kind = types.Slider, parentId = parentId, navigationField = "customCooldownDurationTalentDuration",
			minValue = 1, maxValue = Helper.CUSTOM_COOLDOWN_DURATION_MAX or 300, valueStep = 1, allowInput = true,
			isShown = shown, disabled = ruleDisabled,
			get = function() return Helper.ClampNumber(entry() and entry().customCooldownDurationTalentDuration, 1, Helper.CUSTOM_COOLDOWN_DURATION_MAX or 300, 1) end,
			set = function(_, value) set("customCooldownDurationTalentDuration", Helper.ClampNumber(value, 1, Helper.CUSTOM_COOLDOWN_DURATION_MAX or 300, 1)) end },
	}
end

function Navigation.StructureSettings(settings, kind, panelId, entryId)
	if settings._eqolStructured then return end
	settings._eqolStructured = true
	local types = addon.EditModeLib.SettingType
	local rebuilt, sections, sectionTitles = {}, {}, {}
	local current
	local function divider(name, parentId)
		local rows = {}
		local data = { name = name, kind = types.Divider, parentId = parentId, navigationSearchExcluded = true,
			isShown = function()
				for _, row in ipairs(rows) do if not row.isShown or row.isShown() then return true end end
				return false
			end }
		rebuilt[#rebuilt + 1] = data
		sections[parentId] = rows
	end
	for _, data in ipairs(settings) do
		local parent = data.parentId
		local title
		if parent == "cooldownPanelStandaloneActivation" then
			if data.name == L["CooldownPanelOverwriteGlobalDefault"] then title = L["Auras"]
			elseif data.name == L["CooldownPanelAutoDuration"] then title = L["Duration"]
			elseif data.name == L["CooldownPanelOverwritePanelActivationBehavior"] then title = L["QuickCastCopyAppearance"] end
		elseif parent == "cooldownPanelStandaloneCooldownSwipe" or parent == "cooldownPanelCooldownSwipe" then
			if data.name == L["CooldownPanelShowChargesCooldown"] then title = L["Charges"]
			elseif data.name == L["CooldownPanelShowEdge"] or data.name == L["CooldownPanelDrawEdge"] then title = L["Cooldown"]
			elseif data.name == L["CooldownPanelShowEdgeGcd"] or data.name == L["CooldownPanelDrawEdgeGcd"] then title = L["CooldownPanelGlobalCooldownHeader"] end
		elseif parent == "cooldownPanelVisibility" then
			if data.name == L["CooldownPanelShowTooltips"] then title = L["CooldownPanelShowTooltips"]
			elseif data.name == L["CooldownPanelHideOnCooldown"] then title = L["Cooldown"]
			elseif data.name == L["Show when"] then title = L["CooldownPanelVisibilityRulesHeader"]
			elseif data.name == L["CooldownPanelOpacityOutOfCombat"] then title = L["CooldownPanelOpacityHeader"] end
		elseif parent == "cooldownPanelLayout" then
			if data.name == L["CooldownPanelWidthMode"] then title = L["Size"]
			elseif data.name == L["Spacing"] or data.name == "Spacing" then title = L["Layout"]
			elseif data.name == L["CooldownPanelRadialRadius"] then title = L["CooldownPanelLayoutModeRadial"] end
		elseif parent == "cooldownPanelAvailability" or parent == "cooldownPanelStandaloneAvailability" then
			if data.name == L["CooldownPanelRangeIndicator"] then title = L["CooldownPanelRangeIndicator"]
			elseif data.name == L["CooldownPanelRequireEnoughResource"] then title = L["CooldownPanelRequireEnoughResource"] end
		elseif parent == "cooldownPanelStandaloneVisibility" then
			if data.name == L["CooldownPanelSpecFilter"] then title = L["CooldownPanelSpecFilter"]
			elseif data.name == L["CooldownPanelOverwriteGlobalDefault"] then title = L["Cooldown"] end
		elseif parent == "cooldownPanelStandaloneDisplay" then
			if data.name == L["CooldownPanelTrackTalentChoiceSeparately"] then title = L["CooldownPanelTrackingHeader"]
			elseif data.name == L["CooldownPanelCDMAuraOverlayUnit"] then title = L["Auras"]
			elseif data.name == L["CooldownPanelShowItemCount"] then title = L["CooldownPanelCountersHeader"] end
		elseif parent and (parent == "cooldownPanelStandaloneIcon" or parent == "cooldownPanelIcon") then
			if data.name == L["CooldownPanelOverwriteGlobalSize"] or data.name == L["CooldownPanelUseCustomIconSize"] or data.name == L["Icon size"] or data.name == "Icon size" then title = L["Size"]
			elseif data.name == L["CooldownPanelShowIconTexture"] then title = L["QuickCastCopyAppearance"]
			elseif data.name == L["Icon X"] then title = L["Position"] end
		elseif parent and (parent:find("CooldownText", 1, true) or parent:find("StaticText", 1, true) or parent:find("Stacks", 1, true) or parent:find("Charges", 1, true)) and not parent:find("Bar", 1, true) then
			if data.name == L["Font"] or data.name == L["Cooldown text font"] then title = L["QuickCastCopyAppearance"]
			elseif data.name == L["Anchor"] or data.name == L["Cooldown text offset X"] or data.name == L["CooldownPanelCountAnchor"] or data.name == L["CooldownPanelChargesAnchor"] then title = L["Position"] end
		end
		if title and sectionTitles[parent] ~= title then
			divider(title, parent)
			sectionTitles[parent] = title
		end
		current = parent and sections[parent]
		if current then current[#current + 1] = data end
		rebuilt[#rebuilt + 1] = data
		if kind == "entry" and parent == "cooldownPanelStandaloneActivation" and data.name == L["CooldownPanelCustomDurationSeconds"] then
			for _, row in ipairs(Navigation.CustomDurationTalentSettings(panelId, entryId)) do
				rebuilt[#rebuilt + 1] = row
				if current then current[#current + 1] = row end
			end
		end
	end
	for index, data in ipairs(rebuilt) do settings[index] = data end
end

function Navigation.Build(settings, kind, panelId, entryId, groupId)
	Navigation.StructureSettings(settings, kind, panelId, entryId)
	local types = addon.EditModeLib.SettingType
	local headers, controls = {}, {}
	local borderStarted = false
	local addedHeaders = {}
	for _, data in ipairs(settings) do
		if data.kind == types.Collapsible then headers[data.id] = data else
			if data.parentId == "cooldownPanelIcon" then
				if data.name == L["CooldownPanelIconBorder"] then borderStarted = true end
				if borderStarted then data.parentId = "cooldownPanelBorder" end
			end
			if (data.parentId == "cooldownPanelGlow" or data.parentId == "cooldownPanelStandaloneGlow") and glowTabs[data.navigationGroup] then
				local spec = glowTabs[data.navigationGroup]
				local id = data.parentId .. data.navigationGroup
				data.parentId = id
				addedHeaders[id] = { id = id, name = spec.name, kind = types.Collapsible }
			end
			shorten(data)
			local id = data.parentId or "__general"
			controls[id] = controls[id] or {}
			if data.name then controls[id][data.name] = data end
		end
	end
	for id, header in pairs(addedHeaders) do
		if not headers[id] then
			header.isShown = function()
				for _, data in pairs(controls[id] or {}) do if not data.isShown or data.isShown() then return true end end
				return false
			end
			settings[#settings + 1], headers[id] = header, header
		end
	end
	if controls.cooldownPanelBorder and not headers.cooldownPanelBorder then
		local header = { kind = types.Collapsible, id = "cooldownPanelBorder", name = L["Border"] }
		settings[#settings + 1], headers[header.id] = header, header
	end
	local bars = Panels.Bars
	local barIds = bars and { [bars.STANDALONE_STACKS_SECTION_ID] = "Stacks", [bars.STANDALONE_DURATION_COLORS_SECTION_ID] = "DurationColors" } or {}
	for id, header in pairs(headers) do
		local suffix = id:gsub("^cooldownPanelStandalone", ""):gsub("^cooldownPanel", "")
		local barSuffix = barIds[id] or id:match("^eqolCooldownPanelStandaloneBar(.+)$")
		local resetFields = barSuffix and barScopes[barSuffix] or scopes[suffix]
		-- Tracking identity, layout mode and slot assignments are deliberately not reset.
		if kind == "panel" and suffix == "Anchor" then
			header.navigationReset = function()
				if InCombatLockdown() then return end
				local panel = Panels:GetPanel(panelId)
				if not panel then return end
				local defaults = Helper.CreatePanel(nil)
				panel.anchor, panel.dynamicAnchor = copy(defaults.anchor), nil
				panel.point, panel.x, panel.y = defaults.point, defaults.x, defaults.y
				if Panels.MarkRelativeFrameEntriesDirty then Panels.MarkRelativeFrameEntriesDirty() end
				if addon.DynamicAnchors then addon.DynamicAnchors:RefreshRaidSizeConsumerTracking() end
				if Panels.UpdateCursorAnchorState then Panels:UpdateCursorAnchorState() end
				refresh(kind, panelId)
			end
		elseif kind == "panel" and suffix == "General" then
			header.navigationReset = function()
				if InCombatLockdown() then return end
				local panel = Panels:GetPanel(panelId)
				if not panel then return end
				local defaults = Helper.CreatePanel(nil)
				panel.enabled, panel.specFilter = defaults.enabled, nil
				panel.foreverTalentFilter = nil
				panel.foreverUseSpecFilter = nil
				panel.layout.durationTextProfile = defaults.layout.durationTextProfile
				panel.barDurationTextProfile = defaults.layout.durationTextProfile
				refresh(kind, panelId, true)
			end
		elseif kind == "panel" and barSuffix and resetFields then
			header.navigationReset = function()
				if InCombatLockdown() then return end
				local panel = Panels:GetPanel(panelId)
				if not panel or not panel.layout then return end
				local target = panel.layout.barStyle
				if type(target) ~= "table" then return end
				for _, field in ipairs(resetFields) do
					-- Shared slot geometry remains in the panel's Layout/Icon tabs.
					if field ~= "barWidth" and field ~= "barHeight" and field ~= "barOrientation"
						and field ~= "barOffsetX" and field ~= "barOffsetY" and field ~= "barIconSize" then
						target[field] = nil
					end
				end
				if barSuffix == "Icon" then
					panel.layout.barPanelIconSize = bars and bars.DEFAULTS.barIconSize or 18
					panel.layout.showCraftingQuality = Helper.PANEL_LAYOUT_DEFAULTS.showCraftingQuality
					panel.layout.craftingQualityScale = Helper.PANEL_LAYOUT_DEFAULTS.craftingQualityScale
				end
				if Helper.InvalidateBarPanelStyle then Helper.InvalidateBarPanelStyle(panel.layout) end
				refresh(kind, panelId, barSuffix == "Charges" or barSuffix == "Stacks")
			end
		elseif resetFields then
			header.navigationReset = function()
				if InCombatLockdown() then return end
				local panel = Panels:GetPanel(panelId)
				if not panel then return end
				local target, defaults
				if kind == "panel" then
					target, defaults = panel.layout, Helper.CreatePanel(nil).layout
				else
					-- Detaching one style tab must preserve the inherited appearance of every other tab.
					if barSuffix and barSuffix ~= "Layout" and bars and bars.PrepareEntryStyleOverride then bars.PrepareEntryStyleOverride(panelId, entryId, barSuffix) end
					target = panel.entries and panel.entries[entryId]
					if not target then return end
					defaults = copy(Helper.ENTRY_DEFAULTS)
					if bars then
						for key, value in pairs(bars.DEFAULTS) do if defaults[key] == nil then defaults[key] = value end end
						if bars.COLORS then defaults.barColor = bars.COLORS[target.barMode] or bars.COLORS.COOLDOWN end
						-- New bars inherit their panel's duration format until explicitly overridden.
						defaults.barDurationTextProfile = nil
					end
					if target.type == "CDM_AURA" then defaults.alwaysShow = false end
					if target.type == "ITEM" then defaults.showItemCount = true end
					if target.type == "STANCE" then defaults.showCooldownText, defaults.showCooldownTextUseGlobal = false, false end
				end
				if not target then return end
				local fieldsToReset = resetFields
				if kind == "entry" and barSuffix == "Layout" and Helper.IsBarLayout(panel.layout) then
					fieldsToReset = { "barPanelOrientation", "barPanelWidth", "barPanelHeight", "barPanelOffsetX", "barPanelOffsetY" }
				end
				for _, field in ipairs(fieldsToReset) do target[field] = copy(defaults[field]) end
				if kind == "entry" and suffix == "Activation" and Panels.ClearEntryCustomCooldownDuration then Panels:ClearEntryCustomCooldownDuration(panelId, entryId, true) end
				if kind == "entry" and suffix == "Visibility" and Helper.UpdatePanelEntrySpecFilterState then Helper.UpdatePanelEntrySpecFilterState(panel) end
				if suffix == "Glow" and Panels.ClearReadyGlowEntryState then
					if kind == "entry" then Panels.ClearReadyGlowEntryState(panelId, entryId, true)
					else for id in pairs(panel.entries or {}) do Panels.ClearReadyGlowEntryState(panelId, id, true) end end
				end
				if suffix == "Keybinds" and Helper.Keybinds and Helper.Keybinds.MarkPanelsDirty then Helper.Keybinds.MarkPanelsDirty() end
				if kind == "panel" and suffix == "StaticText" then
					for _, entry in pairs(panel.entries or {}) do
						for _, field in ipairs(resetFields) do if field ~= "staticText" and field ~= "staticTextShowOnCooldown" then entry[field] = copy(defaults[field]) end end
					end
				end
				if kind == "entry" and bars and bars.HandleEntryStylePaste then
					bars.HandleEntryStylePaste(panelId, entryId, target, bars.IsBarDisplayModeValue(target.displayMode))
				end
				refresh(kind, panelId, suffix == "Activation" or suffix == "AuraBehavior" or suffix == "Sound" or suffix == "Charges" or suffix == "Stacks" or suffix == "Visibility" or suffix == "Glow")
			end
		elseif kind == "fixed" and id ~= "cooldownPanelStandaloneFixedGroupGeneral" then
			header.navigationReset = function()
				if InCombatLockdown() then return end
				local panel = Panels:GetPanel(panelId)
				local group = panel and Panels.GetFixedGroupById(panel, groupId)
				if not group then return end
				local overrides = group.layoutOverrides or {}
				if id == "cooldownPanelStandaloneFixedGroupLayout" then
					group.dynamicStartPoint, group.dynamicDirection, overrides.spacing = "TOPLEFT", nil, nil
				elseif id == "cooldownPanelStandaloneFixedGroupIcon" then
					group.iconSize, group.iconSizeSeparate, group.iconWidth, group.iconHeight = nil, false, nil, nil
					overrides.iconOffsetX, overrides.iconOffsetY = nil, nil
				elseif id == "cooldownPanelStandaloneFixedGroupGlow" then
					for _, field in ipairs(scopes.Glow) do overrides[field] = nil end
					for _, spec in pairs(glowTabs) do for _, field in ipairs(spec.fields) do overrides[field] = nil end end
				end
				if Panels.SyncEntryFixedGroupState then
					for _, entry in pairs(panel.entries or {}) do
						if entry.fixedGroupId == group.id then Panels:SyncEntryFixedGroupState(panel, entry) end
					end
				end
				refresh(kind, panelId)
			end
		else header.navigationReset = nil end
	end
	-- Hints are attached only to controls whose visibility can be changed here.
	for _, data in ipairs(settings) do
		local group = controls[data.parentId or data.id] or {}
		if data.isShown then
			local parentId = data.parentId or data.id or ""
			if parentId == "cooldownPanelAnchor" then setHint(data, group[L["Enable Dynamic Anchoring"]])
			elseif parentId == "cooldownPanelLayout" then setHint(data, group[L["CooldownPanelLayoutMode"]])
			elseif (parentId == "cooldownPanelIcon" or parentId == "cooldownPanelStandaloneIcon")
				and (data.name == L["Icon size"] or data.name == "Icon size" or data.name == L["CooldownPanelIconWidth"] or data.name == L["CooldownPanelIconHeight"] or data.name == L["CooldownPanelSeparateIconSize"]) then
				data.navigationHint = function()
					local override = group[L["CooldownPanelUseCustomIconSize"]] or group[L["CooldownPanelOverwriteGlobalSize"]]
					local target = override and override.get and not override.get() and override or group[L["CooldownPanelSeparateIconSize"]]
					if target and target ~= data then return target.name, nil, target.parentId end
				end
			elseif parentId == "cooldownPanelBorder" then setHint(data, group[L["CooldownPanelIconBorder"]])
			elseif parentId == "cooldownPanelStandaloneStateTexture" then
				if data.name == L["CooldownPanelStateTextureMirrorSecond"] or data.name == L["CooldownPanelStateTextureMirrorVerticalSecond"] or data.name == L["CooldownPanelStateTextureSpacingX"] or data.name == L["CooldownPanelStateTextureSpacingY"] then
					setHint(data, group[L["CooldownPanelStateTextureDouble"]])
				end
			elseif parentId == "cooldownPanelStandaloneGlowThreshold" then
				setHint(data, group[L["CooldownPanelBarDurationThresholdGlowEnabled"]])
			elseif parentId == "cooldownPanelStandaloneActivation" and data.name == L["CooldownPanelCustomDurationSeconds"] then
				setHint(data, group[L["CooldownPanelCustomDuration"]])
			elseif parentId == "cooldownPanelGlow" or parentId == "cooldownPanelStandaloneGlow" or parentId == "cooldownPanelStandaloneFixedGroupGlow" then
				if data.name == L["CooldownPanelPixelGlowLines"] or data.name == L["CooldownPanelPixelGlowSpeed"] or data.name == L["CooldownPanelPixelGlowBorder"] or data.name == L["CooldownPanelGlowThickness"] then
					setHint(data, group[L["Glow style"]])
				end
			elseif parentId == "eqolCooldownPanelStandaloneBarIcon" then setHint(data, group[L["Show icon"]])
			elseif parentId == "eqolCooldownPanelStandaloneBarLabel" then setHint(data, group[L["CooldownPanelBarShowLabel"]])
			elseif parentId == "eqolCooldownPanelStandaloneBarValueText" then
				data.navigationHint = function()
					local panel = Panels:GetPanel(panelId)
					if kind == "panel" then
						local values = controls.eqolCooldownPanelStandaloneBarCooldown or controls.eqolCooldownPanelStandaloneBarCharges or {}
						local target = values[L["CooldownPanelBarShowValueText"]]
						if target then return target.name, nil, target.parentId end
						return
					end
					local entry = panel and panel.entries and panel.entries[entryId]
					local mode = entry and entry.barMode or (bars and bars.DEFAULTS.barMode)
					local display = controls.eqolCooldownPanelStandaloneBar or {}
					local values = controls[mode == "CHARGES" and "eqolCooldownPanelStandaloneBarCharges" or "eqolCooldownPanelStandaloneBarCooldown"] or {}
					local target = (mode == "CHARGES" or mode == "COOLDOWN") and values[L["CooldownPanelBarShowValueText"]] or display[L["Mode"]]
					if bars and bars.ShouldShowBarValueTextSettings(entry) then target = display[L["Mode"]] end
					if target then return target.name, nil, target.parentId end
				end
			elseif bars and parentId == bars.STANDALONE_DURATION_COLORS_SECTION_ID then
				local panel = Panels:GetPanel(panelId)
				local entry = panel and panel.entries and panel.entries[entryId]
				if kind == "panel" then
					setHint(data, group[L["CooldownPanelBarDurationColorsEnabled"]])
				elseif bars.IsNativeAuraBarEntry and not bars.IsNativeAuraBarEntry(entry) then
					data.navigationHint, data.navigationSearchExcluded = nil, true
				else setHint(data, controls.eqolCooldownPanelStandaloneBar and controls.eqolCooldownPanelStandaloneBar[L["Mode"]]) end
			elseif parentId == "eqolCooldownPanelStandaloneBar" and data.name == L["CooldownPanelCDMAuraOverlayOnlyMyDebuffs"] then
				setHint(data, group[L["CooldownPanelCDMAuraOverlayUnit"]])
			elseif kind ~= "panel" and parentId:find("eqolCooldownPanelStandaloneBar", 1, true) and parentId ~= "eqolCooldownPanelStandaloneBar" and parentId ~= "eqolCooldownPanelStandaloneBarVisibility" then
				local display = controls.eqolCooldownPanelStandaloneBar or {}
				setHint(data, display[L["Mode"]])
			end
		end
	end
	local categories
	if kind == "panel" then categories = {
		category("general", L["General"], { "cooldownPanelGeneral", "cooldownPanelCopySettings" }),
		category("layout", L["Layout"], { "cooldownPanelLayout", "cooldownPanelAnchor", "eqolCooldownBarGroups" }),
		category("bar", L["Bar"], { "eqolCooldownPanelStandaloneBar", "eqolCooldownPanelStandaloneBarLayout", "eqolCooldownPanelStandaloneBarFill", "eqolCooldownPanelStandaloneBarBorder", "eqolCooldownPanelStandaloneBarIcon" }),
		category("icon", L["Icon"], { "cooldownPanelIcon", "cooldownPanelBorder" }),
		category("visibility", L["Visibility"], { "cooldownPanelVisibility", "cooldownPanelAvailability" }),
		category("text", L["Text"], { "cooldownPanelCooldownText", "cooldownPanelStaticText", "cooldownPanelStacks", "cooldownPanelCharges", "cooldownPanelKeybinds", "eqolCooldownPanelStandaloneBarLabel", "eqolCooldownPanelStandaloneBarValueText" }),
		category("behavior", L["Behavior"], { "eqolCooldownPanelStandaloneBarCooldown", "eqolCooldownPanelStandaloneBarCharges", bars and bars.STANDALONE_STACKS_SECTION_ID or "" }),
		category("effects", L["Effects"], { "cooldownPanelCooldownSwipe", "cooldownPanelAuraBehavior" }),
		category("glow", L["Glow"], { "cooldownPanelGlow", "cooldownPanelGlowProc", "cooldownPanelGlowPandemic", "cooldownPanelGlowThreshold" }),
	} elseif kind == "fixed" then categories = {
		category("general", L["General"], { "cooldownPanelStandaloneFixedGroupGeneral", "cooldownPanelStandaloneFixedGroupLayout" }),
		category("appearance", L["QuickCastCopyAppearance"], { "cooldownPanelStandaloneFixedGroupIcon", "cooldownPanelStandaloneFixedGroupGlow" }),
	} else categories = {
		category("general", L["General"], { "cooldownPanelStandaloneDisplay", "cooldownPanelStandaloneVisibility", "cooldownPanelStandaloneAvailability", "eqolCooldownPanelStandaloneBarVisibility" }),
		category("bar", L["Bar"], { "eqolCooldownPanelStandaloneBar", "eqolCooldownPanelStandaloneBarLayout", "eqolCooldownPanelStandaloneBarFill", "eqolCooldownPanelStandaloneBarBorder", "eqolCooldownPanelStandaloneBarIcon" }),
		category("icon", L["Icon"], { "cooldownPanelStandaloneIcon", "cooldownPanelStandaloneStateTexture" }),
		category("text", L["Text"], { "cooldownPanelStandaloneCooldownText", "cooldownPanelStandaloneStaticText", "cooldownPanelStandaloneStacks", "cooldownPanelStandaloneCharges", "eqolCooldownPanelStandaloneBarLabel", "eqolCooldownPanelStandaloneBarValueText" }),
		category("behavior", L["Behavior"], { "eqolCooldownPanelStandaloneBarCooldown", "eqolCooldownPanelStandaloneBarCharges", bars and bars.STANDALONE_STACKS_SECTION_ID or "" }),
		category("effects", L["Effects"], { "cooldownPanelStandaloneCooldownSwipe", "cooldownPanelStandaloneActivation", bars and bars.STANDALONE_DURATION_COLORS_SECTION_ID or "", "cooldownPanelStandaloneSound" }),
		category("glow", L["Glow"], { "cooldownPanelStandaloneGlow", "cooldownPanelStandaloneGlowProc", "cooldownPanelStandaloneGlowPandemic", "cooldownPanelStandaloneGlowThreshold" }),
	} end
	return { categories = categories, stateKey = kind == "entry" and "cooldownPanels:entries" or nil, scopeKey = "cooldownPanels:" .. kind .. ":" .. tostring(panelId) .. ":" .. tostring(entryId or groupId or ""),
		canReset = function(tab) return tab.header.navigationReset ~= nil end }
end
