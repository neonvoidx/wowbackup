local _, addon = ...
addon = _G.EnhanceQoL or addon
addon.Aura = addon.Aura or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Navigation = {}
addon.Aura.GroupFrameNavigation = Navigation

local function isBarTextField(field, prefix)
	if type(field) ~= "string" or field:sub(1, #prefix) ~= prefix then return false end
	local suffix = field:sub(#prefix + 1)
	return suffix:match("^Text%u") ~= nil
		or suffix:match("^Font") ~= nil
		or suffix:match("^Delimiter") ~= nil
		or suffix:match("^Left[XY]$") ~= nil
		or suffix:match("^Center[XY]$") ~= nil
		or suffix:match("^Right[XY]$") ~= nil
		or suffix == "HidePercent"
		or suffix == "RoundPercent"
		or suffix == "ShortNumbers"
		or suffix == "NameMaxChars"
		or suffix == "NameFirstWord"
end

local function barTextSplit(id)
	return function(data)
		local field = data.navigationField or data.field or ""
		if id == "health" then
			if field:match("^healthBackdrop") or field:match("^healthDeadBackdrop") then return "healthBackdrop", L["Background"] end
			if field:match("^healthGradient") or field == "healthColor" or field == "healthUseCustomColor" or field == "healthClassColor" then return "healthColors", L["Colors"] end
		end
		if isBarTextField(data.navigationField or data.field, id) then return id .. "Text", L["Text"] end
		return id, L["Bar"]
	end
end

function Navigation.Build(kind)
	return {
		categories = {
			{ id = "frame", name = L["Frame"], groups = { "frame", "layout", "border", "partyGroupBorder", "portrait" } },
			{ id = "highlight", name = L["Highlight"], groups = { "hoverHighlight", "aggroHighlight", "targetHighlight", "rangeFade" } },
			{ id = "health", name = L["Health"], groups = { "health", "incomingheal", "absorb", "healabsorb" } },
			{ id = "power", name = L["Power"], groups = { "power" } },
			{ id = "text", name = L["UFNavNameStatus"], groups = { "text", "level", "statustext" } },
			{ id = "dataBar", name = L["UFDataBar"], groups = { "dataBar" } },
			{ id = "auras", name = L["Auras"], groups = { "buffs", "debuffs", "externals" } },
			{ id = "indicators", name = L["UFNavIndicators"], groups = { "groupicons", "statusicons", "roleicons", "raidmarker", "dispeltint" } },
			{ id = "group", name = L["Group"], groups = { "party", "raid" } },
			{ id = "pets", name = L["UFPartyPetFrames"], groups = { "partyPets", "petBuffs", "petDebuffs", "petExternals" } },
			{ id = "raidBlocks", name = L["UFRaidBlocks"], groups = { "raidBlocks", "raidBlock1", "raidBlock2", "raidBlock3", "raidBlock4", "raidBlock5", "raidBlock6", "raidBlock7", "raidBlock8" } },
			{ id = "other", name = L["Other"], groups = { "utility" } },
		},
		tabNames = { frame = L["General"], partyPets = L["General"], text = _G.NAME or L["Name"], utility = _G.SETTINGS or L["Settings"] },
		splitGroups = {
			health = barTextSplit("health"),
			power = barTextSplit("power"),
			dataBar = barTextSplit("dataBar"),
			statustext = function(data)
				local field = data.navigationField or data.field or ""
				if kind ~= "party" and (field:match("^groupNumber") or field == "statusTextShowGroup" or field == "statusTextGroupFormat") then return "groupNumber", L["Group number"] end
				return "statustext", L["Status text"]
			end,
		},
		canReset = function(tab)
			for _, data in ipairs(tab.settings) do
				if not data.navigationSearchExcluded and not data.navigationResetExcluded and data.kind ~= addon.EditModeLib.SettingType.Divider
					and data.kind ~= addon.EditModeLib.SettingType.Label and not data.navigationDefaultVerified and not data.navigationReset then return false end
			end
			return true
		end,
		reset = function(tab, apply)
			local blocks = addon.Aura.UF.RaidBlocks
			if blocks and tab.sourceGroup and tab.sourceGroup:match("^raidBlock") then blocks.RunSettingsReset(apply) else apply() end
		end,
		visibilityHint = function(data) return data.navigationHint end,
	}
end

-- Keep the legacy shared texture authoritative until the user changes the mode.
function Navigation.ConfigureTextureSettings(settings, kind, editModeId, getCfg, defaults, textureOptions)
	local types = addon.EditModeLib.SettingType
	local function shared()
		local cfg = getCfg(kind)
		return cfg and cfg.barTexture ~= nil and cfg.barTexture ~= "" and cfg.barTexture ~= "__PER_BAR__"
	end
	local function individual(cfg, bar)
		return cfg[bar] and cfg[bar].texture or defaults[bar] and defaults[bar].texture or "DEFAULT"
	end
	local function split(cfg)
		if not shared() then return end
		for _, bar in ipairs({ "health", "power" }) do
			local previous = individual(cfg, bar)
			cfg[bar] = cfg[bar] or {}
			if previous ~= cfg.barTexture then cfg[bar].previousTexture = previous end
			cfg[bar].texture = cfg.barTexture
		end
		cfg.barTexture = "__PER_BAR__"
	end
	local function refresh()
		local cfg = getCfg(kind)
		local editMode = addon.EditMode
		if editMode and editMode.SetValue then
			editMode:SetValue(editModeId, "barTexture", cfg.barTexture or "__PER_BAR__", nil, true)
			for _, bar in ipairs({ "health", "power" }) do editMode:SetValue(editModeId, bar .. "Texture", individual(cfg, bar), nil, true) end
		end
		addon.Aura.UF.GroupFrames:ApplyHeaderAttributes(kind)
		local internal = addon.EditModeLib.internal
		if internal and internal.RequestRefreshSettings then internal:RequestRefreshSettings() end
	end
	for i = #settings, 1, -1 do
		local row = settings[i]
		local bar = row.field == "healthTexture" and "health" or row.field == "powerTexture" and "power"
		if bar then
			row.isEnabled = nil
			row.isShown = function() return not shared() end
			row.navigationHint = function() return L["UFGroupSharedTexture"], nil, bar end
			row.get = function() return individual(getCfg(kind), bar) end
			row.set = function(_, value)
				local cfg = getCfg(kind)
				if not cfg then return end
				split(cfg)
				cfg[bar] = cfg[bar] or {}
				cfg[bar].texture = value or "DEFAULT"
				refresh()
			end
			row.navigationReset = function() row.set(nil, defaults[bar] and defaults[bar].texture or "DEFAULT") end
			row.generator = function(_, root)
				for _, option in ipairs(textureOptions()) do
					root:CreateRadio(option.label, function() return row.get() == option.value end, function() row.set(nil, option.value) end)
				end
				local cfg = getCfg(kind)
				local previous = cfg and cfg[bar] and cfg[bar].previousTexture
				if previous and previous ~= row.get() then
					root:CreateButton(L["UFGroupRestoreTexture"], function() row.set(nil, previous) end)
				end
			end
			local common = {
				name = L["UFGroupSharedTexture"], kind = types.Dropdown,
				field = bar .. "SharedTexture", parentId = bar, height = row.height,
				navigationResetExcluded = true, isShown = shared,
				navigationHint = function() return row.name, nil, bar end,
				get = function() return getCfg(kind).barTexture end,
				set = function(_, value)
					local cfg = getCfg(kind)
					if not cfg then return end
					cfg.barTexture = value or "DEFAULT"
					refresh()
				end,
			}
			common.generator = function(_, root)
				for _, option in ipairs(textureOptions()) do
					root:CreateRadio(option.label, function() return common.get() == option.value end, function() common.set(nil, option.value) end)
				end
			end
			table.insert(settings, i, common)
			table.insert(settings, i, {
				name = L["UFGroupSharedTextureHint"], kind = types.Divider, parentId = bar,
				navigationSearchExcluded = true, navigationResetExcluded = true, isShown = shared,
			})
			table.insert(settings, i, {
				name = L["UFGroupLinkTextures"], kind = types.Checkbox, field = bar .. "LinkTextures", parentId = bar,
				navigationResetExcluded = true, get = shared,
				set = function(_, value)
					local cfg = getCfg(kind)
					if not cfg then return end
					if value then cfg.barTexture = shared() and cfg.barTexture or individual(cfg, bar) else split(cfg) end
					refresh()
				end,
			})
		end
	end
end

function Navigation.Prepare(settings, kind, factoryValues, factoryConfig)
	if factoryValues and factoryConfig then
		factoryValues.overallAlpha = 1
		local portrait, bar = factoryConfig.portrait or {}, factoryConfig.dataBar or {}
		local separator, border = portrait.separator or {}, factoryConfig.border or {}
		for field, key in pairs({
			portraitEnabled = "enabled", portraitMode = "mode", portraitShape = "shape", portraitSide = "side",
			portraitSquareBackground = "squareBackground", portraitBorderWithFrame = "borderWithFrame", portraitDetached = "detached",
		}) do factoryValues[field] = portrait[key] end
		factoryValues.portraitDetachedSize = portrait.detachedSize or factoryConfig.height or 24
		factoryValues.portraitDetachedOffsetX, factoryValues.portraitDetachedOffsetY = addon.Aura.UF.GroupFrames.GetDefaultDetachedPortraitOffset(factoryConfig, kind, factoryConfig.width, factoryConfig.height, factoryValues.portraitDetachedSize)
		factoryValues.portraitDetachedBorderOffset = portrait.detachedBorderOffset or border.offset or border.inset or border.edgeSize or 1
		factoryValues.portraitDetachedStrata = portrait.detachedStrata or ""
		factoryValues.portraitDetachedFrameLevelOffset = portrait.detachedFrameLevelOffset or 1
		factoryValues.portraitSeparatorEnabled = separator.enabled ~= false
		factoryValues.portraitSeparatorSize = separator.size or border.edgeSize or 1
		factoryValues.portraitSeparatorUseCustomColor = separator.useCustomColor == true
		for field, key in pairs({
			dataBarEnabled = "enabled", dataBarPosition = "position", dataBarHeight = "height", dataBarGap = "gap",
			dataBarDetached = "detached", dataBarDetachedMatchHealthWidth = "detachedMatchHealthWidth", dataBarDetachedGrowFromCenter = "detachedGrowFromCenter",
			dataBarDetachedFrameLevelOffset = "detachedFrameLevelOffset", dataBarClassColor = "useClassColor", dataBarTexture = "texture", dataBarCustomAtlas = "customAtlas",
			dataBarTextLeft = "textLeft", dataBarTextCenter = "textCenter", dataBarTextRight = "textRight", dataBarTextClassColor = "useTextClassColor",
			dataBarFontSize = "fontSize", dataBarFont = "font", dataBarFontOutline = "fontOutline", dataBarShortNumbers = "useShortNumbers",
			dataBarRoundPercent = "roundPercent", dataBarHidePercent = "hidePercentSymbol",
		}) do factoryValues[field] = bar[key] end
		factoryValues.dataBarDetachedWidth = bar.detachedWidth or factoryConfig.width or 100
		factoryValues.dataBarDetachedOffsetX = bar.detachedOffset and bar.detachedOffset.x or 0
		factoryValues.dataBarDetachedOffsetY = bar.detachedOffset and bar.detachedOffset.y or 0
		factoryValues.dataBarDetachedStrata = bar.detachedStrata or ""
		factoryValues.incomingHealTexture = factoryConfig.health and factoryConfig.health.incomingHealTexture or "DEFAULT"
		factoryValues.showBuffPlacementPreview = false
		factoryValues.debuffHidePermanentAuras = factoryConfig.auras and factoryConfig.auras.debuff and factoryConfig.auras.debuff.hidePermanentAuras == true
		factoryValues.groupBorderEnabled = factoryConfig.groupBorder and factoryConfig.groupBorder.enabled == true
		factoryValues.combatIndicatorIcon = factoryConfig.status and factoryConfig.status.combatIndicator and factoryConfig.status.combatIndicator.icon or addon.Aura.UF.COMBAT_INDICATOR_DEFAULT_ICON or "DEFAULT"
		factoryValues.externalDrFont = factoryConfig.auras and factoryConfig.auras.externals and factoryConfig.auras.externals.drFont or "__EQOL_GLOBAL_FONT__"
	end
	if addon.EditModeNavigationDefaults then addon.EditModeNavigationDefaults.Prepare(settings, factoryValues, true) end
	local inheritedFonts = {
		healthFont = true, powerFont = true, statusTextFont = true, groupNumberFont = true,
		buffCooldownTextFont = true, buffStackFont = true, debuffCooldownTextFont = true, debuffStackFont = true,
		externalCooldownTextFont = true, externalStackFont = true,
	}
	local unavailable = (addon.AuraCompat and addon.AuraCompat:HasNativeAuraAnimationSupport()) and {} or {
		dispelTintGlowEffect = true, dispelTintGlowFrequency = true, dispelTintGlowX = true,
		dispelTintGlowY = true, dispelTintGlowLines = true, dispelTintGlowThickness = true,
	}
	local fields = {}
	for _, data in ipairs(settings) do
		if data.field then fields[data.field] = data end
	end
	local function hint(data, targetField, tabId, explanation, enableField)
		local target = fields[targetField]
		if not target or not data.isShown then return end
		data.navigationHint = function()
			local enable = enableField and fields[enableField]
			if enable and enable.get and not enable.get() then return enable.name, nil, enable.parentId end
			if target.isShown and not target.isShown() and target.navigationHint then return target.navigationHint() end
			return target.name, nil, tabId or target.parentId, explanation
		end
	end
	for _, data in ipairs(settings) do
		local field = data.field or ""
		-- The checkbox or tab already identifies the indicator/text being edited.
		if field:match("^leaderIcon") or field:match("^raidAssignmentIcon") or field:match("^assistIcon") then
			if field:match("Size$") then data.name = L["Icon size"]
			elseif field:match("Point$") then data.name = L["Anchor"]
			elseif field:match("OffsetX$") then data.name = L["Offset X"]
			elseif field:match("OffsetY$") then data.name = L["Offset Y"] end
		elseif data.parentId == "level" or field:match("^groupNumber") or field:match("^portraitDetached") then
			if field:match("FontSize$") or field:match("Size$") then data.name = field:match("^portrait") and L["Size"] or (_G.FONT_SIZE or L["Font"])
			elseif field:match("Font$") then data.name = L["Font"]
			elseif field:match("FontOutline$") then data.name = L["Font outline"]
			elseif field:match("Strata$") then data.name = L["Strata"]
			elseif field:match("OffsetX$") then data.name = L["Offset X"]
			elseif field:match("OffsetY$") then data.name = L["Offset Y"] end
		end
		if factoryValues and inheritedFonts[field] and addon.EditModeNavigationDefaults then addon.EditModeNavigationDefaults.Set(data, factoryValues[field]) end
		local partyOnly = field:match("^powerDetached") or field:match("^portraitDetached") or field:match("^groupBorder")
			or field == "buffAnchorOutside" or field == "debuffAnchorOutside" or field == "externalAnchorOutside"
		local raidOnly = field:match("^raidAssignmentIcon") or field:match("^groupIndicator") or field:match("^raidGroup%d+$") or field == "groupGrowth" or field == "groupsPerRow"
		local raidLikeOnly = field:match("^groupNumber") or field:match("^assistIcon") or field == "statusTextShowGroup" or field == "statusTextGroupFormat"
		local primaryOnly = field == "anchorTarget" or field == "showBuffPlacementPreview" or field == "groupBy" or field == "sortMethod"
			or field == "sortDir" or field:match("^customSort") or field == "dynamicScaleMin"
		local compatOnly = field == "dispelTintFilterMode" or field == "debuffBossAuraSize"
		if field == "copyFrom" or unavailable[field] or (kind ~= "party" and partyOnly) or (kind ~= "raid" and raidOnly)
			or (kind == "party" and raidLikeOnly) or (kind ~= "party" and kind ~= "raid" and primaryOnly) or (not addon.AuraCompat and compatOnly) then
			data.navigationSearchExcluded = true
		end
		if field == "dynamicAnchorProfile" or ((kind == "party" or kind == "raid") and data.parentId == "frame" and (field == "anchorTarget" or field == "point" or field == "relativePoint" or field == "x" or field == "y")) then
			hint(data, "dynamicAnchorEnabled", "frame")
		elseif kind == "party" and field:match("^portraitDetached") and field ~= "portraitDetached" then
			hint(data, "portraitDetached", "portrait")
		elseif kind == "party" and field:match("^powerDetached") and field ~= "powerDetached" then
			hint(data, "powerDetached", "power")
		elseif field == "dataBarDetached" then
			hint(data, "dataBarEnabled", "dataBar")
		elseif field:match("^dataBarDetached") then
			hint(data, "dataBarDetached", "dataBar")
		elseif field == "dataBarNameMaxChars" or field == "dataBarNameFirstWord" then
			hint(data, "dataBarTextLeft", "dataBarText", nil, "dataBarEnabled")
		elseif field:match("^healthDelimiter") then
			hint(data, "healthTextLeft", "healthText", L["UFNavTextFormatHint"])
		elseif field:match("^powerDelimiter") then
			hint(data, "powerTextLeft", "powerText", L["UFNavTextFormatHint"])
		elseif field == "absorbGlow" or field == "absorbGlowClampToHealth" then
			hint(data, "healthOrientation", "health")
		elseif kind == "raid" and (field:match("^groupIndicator") or field:match("^raidGroup%d+$") or field == "groupsPerRow") then
			hint(data, "groupBy", "raid")
		end
	end
	return settings
end
