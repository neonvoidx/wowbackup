local _, addon = ...
addon = _G.EnhanceQoL or addon
local ResourceBars = addon.Aura and addon.Aura.ResourceBars
if not ResourceBars then return end
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

function ResourceBars.AddFillSparkSettings(settings, types, getConfig, refresh, getBarType, possiblePowerTypes)
	local available = false
	for _, pType in ipairs(possiblePowerTypes or {}) do
		if ResourceBars.SupportsFillSpark and ResourceBars.SupportsFillSpark(pType) then available = true; break end
	end
	if not available then return end
	local function supported() return ResourceBars.SupportsFillSpark(getBarType()) end
	local function enabled() local cfg = getConfig(); return supported() and cfg and cfg.fillSparkEnabled == true end
	local toggle = {
		name = L["barFillSpark"], tooltip = L["barFillSparkDesc"], kind = types.Checkbox, field = "fillSparkEnabled", navigationField = "fillSparkEnabled",
		parentId = "frame", default = false, isEnabled = supported,
		get = function() local cfg = getConfig(); return cfg and cfg.fillSparkEnabled == true or false end,
		set = function(_, value) local cfg = getConfig(); if not cfg then return end; cfg.fillSparkEnabled = value == true; refresh() end,
	}
	settings[#settings + 1] = toggle
	for _, spec in ipairs({
		{ "fillSparkWidth", "barFillSparkWidth", 3, 1, 64 },
		{ "fillSparkHeight", "barFillSparkHeight", 0, 0, 256 },
		{ "fillSparkOffsetX", "barFillSparkOffsetX", 0, -100, 100 },
		{ "fillSparkOffsetY", "barFillSparkOffsetY", 0, -100, 100 },
	}) do
		local field, label, factory, minimum, maximum = spec[1], spec[2], spec[3], spec[4], spec[5]
		settings[#settings + 1] = {
			name = L[label], kind = types.Slider, field = field, navigationField = field, parentId = "frame",
			default = factory, minValue = minimum, maxValue = maximum, valueStep = 1, isEnabled = enabled,
			get = function() local cfg = getConfig(); return cfg and cfg[field] or factory end,
			set = function(_, value) local cfg = getConfig(); if not cfg then return end; cfg[field] = value; refresh() end,
		}
	end
	settings[#settings + 1] = {
		name = L["Use class color"], tooltip = L["barFillSparkClassColorDesc"], kind = types.Checkbox,
		field = "fillSparkUseClassColor", navigationField = "fillSparkUseClassColor", parentId = "frame", default = false, isEnabled = enabled,
		get = function() local cfg = getConfig(); return cfg and cfg.fillSparkUseClassColor == true or false end,
		set = function(_, value) local cfg = getConfig(); if not cfg then return end; cfg.fillSparkUseClassColor = value == true; refresh() end,
	}
	settings[#settings + 1] = {
		name = L["barFillSparkColor"], kind = types.Color,
		field = "fillSparkColor", navigationField = "fillSparkColor", parentId = "frame",
		default = { r = 1, g = 1, b = 1, a = 1 }, hasOpacity = true,
		isEnabled = function() local cfg = getConfig(); return enabled() and not cfg.fillSparkUseClassColor end,
		get = function()
			local cfg = getConfig()
			local c = cfg and cfg.fillSparkColor or {}
			return { r = c.r or c[1] or 1, g = c.g or c[2] or 1, b = c.b or c[3] or 1, a = c.a or c[4] or 1 }
		end,
		set = function(_, value)
			local cfg = getConfig(); if not cfg then return end
			cfg.fillSparkColor = { value.r or value[1] or 1, value.g or value[2] or 1, value.b or value[3] or 1, value.a or value[4] or 1 }
			refresh()
		end,
	}
end

function ResourceBars.PrepareNavigationSettings(settings, types, barType, possiblePowerTypes)
	local defaults = addon.EditModeNavigationDefaults
	if not defaults then return end
	-- Organize the shared power editor without changing its saved fields or callbacks.
	local powerGroups = { selection = {}, base = {}, activation = {}, bar = {}, colors = {}, text = {}, thresholds = {} }
	local powerHeader
	for _, data in ipairs(settings or {}) do
		if data.id == "powercolorsetting" then powerHeader = data end
		if data.parentId == "powercolorsetting" then
			local field = data.field or ""
			local group = "colors"
			if field:match("^threshold") or field == "showThresholds" or field == "useAbsoluteThresholds" then group = "thresholds"
			elseif field == "powerTypeOverrideType" then group = "selection"
			elseif field == "defaultPowerColor" then group = "base"
			elseif field == "powerTypeOverrideEnabled" then group = "activation"
			elseif field == "powerTypeOverrideBarTexture" or field == "separatedOffset" then group = "bar"
			elseif field:match("^powerTypeOverride.*Text") or field == "powerTypeOverrideShortNumbers"
				or field == "powerTypeOverridePercentRounding" or field == "powerTypeOverrideHidePercentSign" then group = "text" end
			powerGroups[group][#powerGroups[group] + 1] = data
		end
	end
	if powerHeader then
		local rebuilt = {}
		local function appendGroup(key, title)
			local entries = powerGroups[key]
			if #entries == 0 then return end
			if title then rebuilt[#rebuilt + 1] = { kind = types.Divider, name = title, parentId = "powercolorsetting" } end
			for _, data in ipairs(entries) do
				if key == "bar" or key == "colors" or key == "text" or key == "thresholds" then
					local originalEnabled = data.isEnabled
					data.isEnabled = function(...)
						local toggle = powerGroups.activation[1]
						return toggle and toggle.get() == true and (not originalEnabled or originalEnabled(...)) or false
					end
				end
				rebuilt[#rebuilt + 1] = data
			end
		end
		for _, data in ipairs(settings) do
			if data.parentId ~= "powercolorsetting" then rebuilt[#rebuilt + 1] = data end
			if data == powerHeader then
				appendGroup("selection")
				appendGroup("base", L["ResourceBarsDefaultPowerColor"])
				appendGroup("activation", L["ResourceBarsPowerColor"])
				rebuilt[#rebuilt + 1] = { kind = types.Label, name = L["ResourceBarsOverrideLayoutHint"], parentId = "powercolorsetting" }
				appendGroup("bar", L["Bar"])
				appendGroup("colors", L["Colors"])
				appendGroup("text", L["Text"])
				appendGroup("thresholds", L["EditModeNavThresholds"])
			end
		end
		for i = #settings, 1, -1 do settings[i] = nil end
		for i, data in ipairs(rebuilt) do settings[i] = data end
	end
	local fields = {}
	local sections, section = {}, nil
	local labels = {
		anchorPoint = L["Anchor point"], anchorRelativePoint = L["Relative point"],
		anchorOffsetX = L["Offset X"], anchorOffsetY = L["Offset Y"],
		frameLevelOffset = L["UFDetachedPowerLevelOffset"], strata = L["Strata"],
		barTexture = L["Texture"], fontFace = L["Font"], fontOutline = L["Font outline"],
		fontSize = _G.FONT_SIZE or L["Font Size"], cooldownTextFontSize = _G.FONT_SIZE or L["Font Size"],
		textAnchor = L["Anchor"], textOffsetX = L["Offset X"], textOffsetY = L["Offset Y"],
		textLeftOffsetX = L["Offset X"], textLeftOffsetY = L["Offset Y"],
		textRightOffsetX = L["Offset X"], textRightOffsetY = L["Offset Y"],
		backdropBackground = L["Texture"], backdropBorder = L["Texture"],
		backdropEdgeSize = L["Size"], backdropOutset = L["Offset"], backdropBackgroundInset = L["Inset"],
	}
	for _, data in ipairs(settings or {}) do
		if data.kind == types.Collapsible then section = nil
		elseif data.kind == types.Divider then section = data.name
		else sections[data] = section end
		if data.field then fields[data.field] = data end
		if data.parentId == "profiles" or data.field == "powerTypeOverrideType" then
			-- Profile actions and the editor's power selector are not saved style.
			data.navigationResetExcluded = true
		elseif data.field == "powerTypeOverrideEnabled" then
			defaults.Set(data, false)
		elseif data.default ~= nil or data.colorDefault ~= nil then
			data.navigationDefaultVerified = true
		end
		if labels[data.field] then data.name = labels[data.field] end
	end
	local function powerFactoryValue(pType, maxColor)
		local aura = ResourceBars.GetAuraPowerConfig and ResourceBars.GetAuraPowerConfig(pType)
		if maxColor then return pType == "MAELSTROM_WEAPON" or (aura and aura.useMaxColorDefault == true) or false end
		return aura and aura.defaultTextStyle or ((pType == "HEALTH" or pType == "MANA" or pType == "STAGGER") and "PERCENT" or "CURMAX")
	end
	for _, field in ipairs({ "textStyle", "powerTypeOverrideTextStyle", "useMaxColor" }) do
		local data = fields[field]
		if data then
			local isMaxColor = field == "useMaxColor"
			defaults.Set(data, powerFactoryValue(barType, isMaxColor))
			if fields.powerTypeOverrideType and field ~= "textStyle" then
				data.navigationReset = function()
					data.set(nil, powerFactoryValue(fields.powerTypeOverrideType.get(), isMaxColor), addon.EditModeLib:GetActiveLayoutIndex())
				end
			end
		end
	end
	local links = {
		visibilityFadeStrength = "separateCombatOpacity", opacityInCombat = "separateCombatOpacity", opacityOutOfCombat = "separateCombatOpacity",
		textAnchor = "textStyle", textOffsetX = "textStyle", textOffsetY = "textStyle",
		textLeftOffsetX = "textLeft", textLeftOffsetY = "textLeft", textRightOffsetX = "textRight", textRightOffsetY = "textRight",
		separatedOffset = "powerTypeOverrideType", durationTextProfile = "powerTypeOverrideType",
		powerTypeOverrideDurationTextProfile = "powerTypeOverrideType", useClassColor = "powerTypeOverrideType",
		powerTypeOverrideTextStyle = "powerTypeOverrideType", powerTypeOverrideShortNumbers = "powerTypeOverrideType",
		powerTypeOverridePercentRounding = "powerTypeOverrideType", powerTypeOverrideHidePercentSign = "powerTypeOverrideType",
		useHolyThreeColor = "powerTypeOverrideType", useMaxColor = "powerTypeOverrideType",
		useMaelstromFiveColor = "powerTypeOverrideType", maelstromMidStack = "powerTypeOverrideType",
		useMaelstromCarryFill = "powerTypeOverrideType", powerTypeOverrideUseMaelstromTenStacks = "powerTypeOverrideType",
		runeCooldownColor = "powerTypeOverrideType",
	}
	-- These predicates describe the registered frame type, not a setting the
	-- user can change. Keep impossible controls out of the hidden-result list.
	local fixedFrameFields = {
		clickThrough = true, textUsePowerColor = true, hideTextAtFullHealth = true,
		hideTextAtZeroHealth = true, hideTextAtFullPower = true, hideTextAtZeroPower = true,
		visibility = true,
	}
	local fixedPowerType = not fields.powerTypeOverrideType
	local unavailableThresholds = fixedPowerType and fields.thresholdCount and fields.thresholdCount.isShown and not fields.thresholdCount.isShown()
	local allowed = {}
	for _, pType in ipairs(possiblePowerTypes or { barType }) do
		allowed[pType] = true
		if ResourceBars.IsDurationPowerType and ResourceBars.IsDurationPowerType(pType) then allowed.duration = true else allowed.nonDuration = true end
		if pType ~= "RUNES" then allowed.nonRunes = true end
		if ResourceBars.separatorEligible and ResourceBars.separatorEligible[pType] then allowed.separators = true end
		if ResourceBars.SupportsThresholdLines and ResourceBars.SupportsThresholdLines(pType) then allowed.thresholds = true end
	end
	local requiredPowerTypes = {
		runeCooldownColor = "RUNES", useHolyThreeColor = "HOLY_POWER",
		useMaelstromFiveColor = "MAELSTROM_WEAPON", maelstromMidStack = "MAELSTROM_WEAPON",
		useMaelstromCarryFill = "MAELSTROM_WEAPON", powerTypeOverrideUseMaelstromTenStacks = "MAELSTROM_WEAPON",
		durationTextProfile = "duration", powerTypeOverrideDurationTextProfile = "duration", useMaxColor = "nonDuration",
		useClassColor = "nonRunes", powerTypeOverrideTextStyle = "nonRunes", powerTypeOverrideShortNumbers = "nonRunes",
		powerTypeOverridePercentRounding = "nonRunes", powerTypeOverrideHidePercentSign = "nonRunes", separatedOffset = "separators",
	}
	for _, data in ipairs(settings or {}) do
		local field = data.field or ""
		local fixed = fixedFrameFields[field] or (fixedPowerType and field == "durationTextProfile")
		local threshold = field:match("^threshold") or field == "showThresholds" or field == "useAbsoluteThresholds"
		local required = requiredPowerTypes[field]
		if field:match("^chargedCombo") or field == "useChargedComboStyling" then required = "COMBO_POINTS" end
		local unavailablePowerType = required and not allowed[required]
		if (fixed and data.isShown and not data.isShown()) or ((unavailableThresholds or (ResourceBars.SupportsThresholdLines and not allowed.thresholds)) and threshold)
			or unavailablePowerType then data.navigationSearchExcluded = true end
	end
	local function targetHint(target)
		if not target then return end
		if target.isShown and not target.isShown() and target.navigationHint then return target.navigationHint() end
		return target.name, sections[target], target.parentId
	end
	for field, targetField in pairs(links) do
		local data, target = fields[field], fields[targetField]
		if data and target and data.isShown then data.navigationHint = function() return targetHint(target) end end
	end
	local lastPoint
	for _, data in ipairs(settings or {}) do
		local field = data.field or ""
		if field:match("^threshold%d+$") then
			data.navigationHint = function() return targetHint(fields.thresholdCount) end
		elseif data.isShown and (field:match("^threshold") or field == "showThresholds" or field == "useAbsoluteThresholds" or field:match("^chargedCombo") or field == "useChargedComboStyling") then
			data.navigationHint = function() return targetHint(fields.powerTypeOverrideType) end
		elseif field:match("^textThresholdPointValue") or field:match("^absoluteThresholdPointValue") then
			local text = field:match("^text") ~= nil
			local toggle = fields[text and "useTextThresholdColors" or "useAbsoluteThresholdColors"]
			local count = fields[text and "textThresholdColorPointCount" or "absoluteThresholdColorPointCount"]
			data.navigationHint = function()
				if toggle and toggle.get and not toggle.get() then return targetHint(toggle) end
				return targetHint(count)
			end
			lastPoint = data
		elseif data.kind == types.Color and lastPoint and data.parentId == lastPoint.parentId then
			data.navigationHint = lastPoint.navigationHint
			lastPoint = nil
		else
			lastPoint = nil
		end
	end
end
