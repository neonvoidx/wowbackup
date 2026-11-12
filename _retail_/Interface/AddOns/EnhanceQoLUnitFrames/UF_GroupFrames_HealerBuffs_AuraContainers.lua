local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local UF = addon.Aura and addon.Aura.UF
local HB = UF and UF.GroupFramesHealerBuffs
if not HB then return end

local AuraUtil = UF.AuraUtil
local UFHelper = addon.Aura and addon.Aura.UFHelper
local floor = math.floor
local max = math.max
local tonumber = tonumber
local tostring = tostring
local type = type
local pairs = pairs

local EMPTY = {}
local OPPOSITE = {
	TOPLEFT = "BOTTOMRIGHT", TOP = "BOTTOM", TOPRIGHT = "BOTTOMLEFT",
	LEFT = "RIGHT", CENTER = "CENTER", RIGHT = "LEFT",
	BOTTOMLEFT = "TOPRIGHT", BOTTOM = "TOP", BOTTOMRIGHT = "TOPLEFT",
}
local GROWTH = {
	UPRIGHT = { "UP", "RIGHT" }, UPLEFT = { "UP", "LEFT" },
	RIGHTUP = { "RIGHT", "UP" }, RIGHTDOWN = { "RIGHT", "DOWN" },
	LEFTUP = { "LEFT", "UP" }, LEFTDOWN = { "LEFT", "DOWN" },
	DOWNLEFT = { "DOWN", "LEFT" }, DOWNRIGHT = { "DOWN", "RIGHT" },
}

local function call(object, method, ...)
	if not (object and type(object[method]) == "function") then return false end
	object[method](object, ...)
	return true
end

local function resolveColor(group, rule)
	local color = type(rule and rule.color) == "table" and rule.color or group and group.color
	if type(color) ~= "table" then return 1, 1, 1, 1 end
	return color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1
end

local function getRuleSpellIDs(rule, compiled)
	local ids
	if type(HB.GetRuleSpellIDs) == "function" then ids = HB.GetRuleSpellIDs(rule, compiled) end
	if type(ids) ~= "table" then ids = rule and (rule.spellIDs or rule.spellIds or rule.customSpellIDs) end
	if type(ids) ~= "table" and rule and rule.spellId then ids = { rule.spellId } end
	if type(ids) ~= "table" and rule and rule.spellFamilyId and type(HB.GetFamilyById) == "function" then
		local family = HB.GetFamilyById(rule.spellFamilyId)
		ids = family and family.spellIds
	end
	local map = {}
	if type(ids) == "table" then
		for key, value in pairs(ids) do
			local spellID = tonumber(value)
			if value == true then spellID = tonumber(key) end
			if spellID and spellID > 0 then map[floor(spellID)] = true end
		end
	end
	return map
end

local function hasSpellIDs(map)
	return type(map) == "table" and next(map) ~= nil
end

local function isRuleRelevantToPlayer(rule, compiled)
	return type(HB.CanPlayerProvideFamily) ~= "function" or HB.CanPlayerProvideFamily(rule.spellFamilyId, compiled) == true
end

local function getExpirationPulseSignature(rule)
	if not (rule and rule.expirationPulseEnabled == true) then return "0" end
	local color = type(rule.expirationPulseColor) == "table" and rule.expirationPulseColor or EMPTY
	return table.concat({
		"1",
		tostring(color[1] or color.r),
		tostring(color[2] or color.g),
		tostring(color[3] or color.b),
		tostring(color[4] or color.a),
	}, "\030")
end

local function getState(button)
	local state = button and button._eqolUFState
	if not state then return nil end
	state._healerBuffManaged = state._healerBuffManaged or {}
	return state._healerBuffManaged, state
end

local function ensureCommonRegions(button)
	if button._eqolHBPRegionsReady then return end
	button._eqolHBPRegionsReady = true
	button:EnableMouse(false)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints(button)
	button.square = button:CreateTexture(nil, "ARTWORK")
	button.square:SetAllPoints(button)
	button.tint = button:CreateTexture(nil, "ARTWORK")
	button.tint:SetAllPoints(button)
	button.nativeBorderLayer = CreateFrame("Frame", nil, button)
	button.nativeBorderLayer:EnableMouse(false)
	button.nativeBorderLayer:SetAllPoints(button)
	button.nativeForeground = CreateFrame("Frame", nil, button)
	button.nativeForeground:EnableMouse(false)
	button.nativeForeground:SetAllPoints(button)
	button.cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.cd:SetAllPoints(button)
	button.cd:SetHideCountdownNumbers(true)
	button.durationText = button.nativeForeground:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	button.durationText:SetPoint("CENTER")
	button.count = button.nativeForeground:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	button.count:SetPoint("BOTTOMRIGHT", -2, 2)
	button.bar = CreateFrame("StatusBar", nil, button)
	button.bar:SetAllPoints(button)
	button.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	button.bar:SetMinMaxValues(0, 1)
	button.bar:SetValue(1)
	button.border = CreateFrame("Frame", nil, button)
	button.border:EnableMouse(false)
	button.border:SetAllPoints(button)
end

local function roundInt(value)
	local number = tonumber(value) or 0
	if number >= 0 then return floor(number + 0.5) end
	return -floor(-number + 0.5)
end

local function ensureIndicatorBorderFrame(button)
	local parent = button.nativeBorderLayer or button
	local border = button._eqolHBPManagedIndicatorBorderFrame
	if not border then
		border = CreateFrame("Frame", nil, parent, "DisableUntrustedLayoutScriptsTemplate")
		border:EnableMouse(false)
		button._eqolHBPManagedIndicatorBorderFrame = border
	end
	border:SetParent(parent)
	if parent.GetFrameStrata then border:SetFrameStrata(parent:GetFrameStrata()) end
	if parent.GetFrameLevel then border:SetFrameLevel(max(0, (parent:GetFrameLevel() or 0) + 2)) end
	return border
end

local function configureIndicatorBorder(button, group)
	if not (group and group.indicatorBorderEnabled == true and addon.functions and addon.functions.SetSafeBorder) then return end
	local border = ensureIndicatorBorderFrame(button)
	local size = max(1, roundInt(group.indicatorBorderSize or 1))
	if size > 24 then size = 24 end
	local offset = roundInt(group.indicatorBorderOffset or 0)
	if offset < -12 then offset = -12 end
	if offset > 12 then offset = 12 end
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", button, "TOPLEFT", -offset, offset)
	border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", offset, -offset)
	local textureKey = group.indicatorBorderTexture
	if type(textureKey) ~= "string" or textureKey == "" or textureKey:upper() == "SOLID" then textureKey = "DEFAULT" end
	local color = type(group.indicatorBorderColor) == "table" and group.indicatorBorderColor or EMPTY
	local r = color[1] or color.r or 1
	local g = color[2] or color.g or 1
	local b = color[3] or color.b or 1
	local a = color[4] or color.a or 1
	addon.functions.SetSafeBorder(border, true, textureKey, size, r, g, b, a, {
		stateKey = "_eqolHBPManagedIndicatorBorder",
		defaultTexture = "Interface\\Buttons\\WHITE8x8",
		mediaType = "border",
		drawLayer = "OVERLAY",
	})
end

local function clearBindings(button)
	call(button, "ClearIcon")
	call(button, "ClearDurationCooldown")
	call(button, "ClearDurationText")
	call(button, "ClearDurationBar")
	call(button, "ClearApplicationCount")
	call(button, "ClearPandemicRegions")
	button.icon:Hide()
	button.square:Hide()
	button.tint:Hide()
	button.cd:Hide()
	button.durationText:Hide()
	button.count:Hide()
	button.bar:Hide()
	if button._eqolHBPPandemicGlow then
		addon.AuraCompat:UnbindRestrictedAuraGlowAnimations(button._eqolHBPPandemicGlow)
		button._eqolHBPPandemicGlow:Hide()
		button._eqolHBPPandemicGlow = nil
	end
	if addon.functions and addon.functions.SetSafeBorder then
		addon.functions.SetSafeBorder(button.border, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolHBPManagedBorder" })
	else
		button.border:Hide()
	end
	local indicatorBorder = button._eqolHBPManagedIndicatorBorderFrame
	if indicatorBorder then
		if addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(indicatorBorder, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolHBPManagedIndicatorBorder" })
		else
			indicatorBorder:Hide()
		end
	end
end

local function getIconStyle(config, group, auraType)
	local auraKey = (auraType or (config and config.auraType)) == "HARMFUL" and "debuff" or "buff"
	local auraConfig = config and config.auras and config.auras[auraKey] or EMPTY
	return {
		size = group.size,
		iconZoom = group.iconZoom,
		showTooltip = auraConfig.showTooltip == true,
		tooltipAnchor = auraConfig.tooltipAnchor,
		tooltipOffset = auraConfig.tooltipOffset,
		hideTooltipInCombat = auraConfig.hideTooltipInCombat == true,
		showCooldown = group.showCooldown ~= false,
		showCooldownSwipe = group.showCooldownSwipe ~= false,
		showCooldownEdge = group.showCooldownEdge ~= false,
		showCooldownBling = group.showCooldownBling ~= false,
		showCooldownText = group.showCooldown ~= false and group.hideCooldownText ~= true,
		showStacks = group.hideChargeText ~= true and auraConfig.showStacks ~= false,
		cooldownAnchor = auraConfig.cooldownAnchor,
		cooldownOffset = auraConfig.cooldownOffset,
		cooldownFont = auraConfig.cooldownFont,
		cooldownFontSize = group.cooldownTextSize or auraConfig.cooldownFontSize,
		cooldownFontOutline = auraConfig.cooldownFontOutline,
		durationTextProfile = auraConfig.durationTextProfile,
		countAnchor = auraConfig.countAnchor,
		countOffset = auraConfig.countOffset,
		countFont = auraConfig.countFont,
		countFontSize = group.chargeTextSize or auraConfig.countFontSize,
		countFontOutline = auraConfig.countFontOutline,
	}
end

local function configureNativeForeground(button)
	if button.cd and button.nativeBorderLayer then
		button.nativeBorderLayer:SetFrameStrata(button.cd:GetFrameStrata())
		button.nativeBorderLayer:SetFrameLevel(button.cd:GetFrameLevel() + 5)
		button.nativeBorderLayer:Show()
	end
	if button.cd and button.nativeForeground then
		button.nativeForeground:SetFrameStrata(button.cd:GetFrameStrata())
		button.nativeForeground:SetFrameLevel(button.cd:GetFrameLevel() + 10)
		button.nativeForeground:Show()
	end
end

local function configurePandemicPulse(button, group, rule)
	if not (rule and rule.expirationPulseEnabled == true and addon.AuraCompat and addon.AuraCompat.CreateRestrictedAuraGlow and type(button.AddPandemicRegion) == "function") then return end
	configureNativeForeground(button)
	local color = type(rule.expirationPulseColor) == "table" and rule.expirationPulseColor or { 1, 0.2, 0.2, 1 }
	local borderLayer = button.nativeBorderLayer or button
	local glow = addon.AuraCompat:CreateRestrictedAuraGlow(borderLayer, borderLayer, {
		color = color,
		style = "PULSING",
		inset = tonumber(group.indicatorBorderOffset) or 0,
		thickness = group.indicatorBorderEnabled == true and (tonumber(group.indicatorBorderSize) or 1) or 2,
		frameLevelOffset = 1,
	})
	if glow then
		addon.AuraCompat:BindRestrictedAuraGlowAnimations(button, glow, "PandemicActive")
		button:AddPandemicRegion(glow)
		button._eqolHBPPandemicGlow = glow
	end
end

local function configureIcon(button, config, group, rule)
	local style = getIconStyle(config, group)
	button._eqolNativeAuraStyleKey = nil
	if AuraUtil and AuraUtil.PrepareNativeAuraButton then AuraUtil.PrepareNativeAuraButton(button, style, config.auraType == "HARMFUL") end
	button.icon:Show()
	configurePandemicPulse(button, group, rule)
end

local function configureDurationText(button, style)
	configureNativeForeground(button)
	if style.showCooldownText ~= false then
		button.durationText:ClearAllPoints()
		button.durationText:SetDrawLayer("OVERLAY", 3)
		button.durationText:SetPoint(
			style.cooldownAnchor or "CENTER",
			button.nativeForeground or button,
			style.cooldownAnchor or "CENTER",
			(style.cooldownOffset and style.cooldownOffset.x) or 0,
			(style.cooldownOffset and style.cooldownOffset.y) or 0
		)
		if UFHelper and UFHelper.applyFont then UFHelper.applyFont(button.durationText, style.cooldownFont, style.cooldownFontSize or 12, style.cooldownFontOutline) end
		button.durationText:Show()
		local options = addon.functions and addon.functions.GetAuraButtonDurationTextOptions and addon.functions.GetAuraButtonDurationTextOptions(style.durationTextProfile)
		call(button, "SetDurationText", button.durationText, options)
	else
		call(button, "ClearDurationText")
		button.durationText:Hide()
	end
end

local function configureApplicationCount(button, style)
	configureNativeForeground(button)
	if style.showStacks ~= false then
		button.count:ClearAllPoints()
		button.count:SetDrawLayer("OVERLAY", 4)
		button.count:SetPoint(
			style.countAnchor or "BOTTOMRIGHT",
			button.nativeForeground or button,
			style.countAnchor or "BOTTOMRIGHT",
			(style.countOffset and style.countOffset.x) or -2,
			(style.countOffset and style.countOffset.y) or 2
		)
		if UFHelper and UFHelper.applyFont then UFHelper.applyFont(button.count, style.countFont, style.countFontSize or 14, style.countFontOutline) end
		button.count:Show()
		call(button, "SetApplicationCount", button.count, {})
	else
		call(button, "ClearApplicationCount")
		button.count:Hide()
	end
end

local function configureSquare(button, config, group, rule)
	local style = getIconStyle(config, group)
	local size = max(1, tonumber(group.size) or 16)
	local r, g, b, a = resolveColor(group, rule)
	button:SetSize(size, size)
	button.square:SetColorTexture(r, g, b, a)
	button.square:Show()
	if group.showCooldown ~= false then
		button.cd:SetDrawSwipe(group.showCooldownSwipe ~= false)
		button.cd:SetDrawEdge(group.showCooldownEdge ~= false)
		button.cd:SetDrawBling(group.showCooldownBling ~= false)
		button.cd:SetReverse(true)
		button.cd:Show()
		call(button, "SetDurationCooldown", button.cd)
	else
		call(button, "ClearDurationCooldown")
		button.cd:Hide()
	end
	configureDurationText(button, style)
	configureApplicationCount(button, style)
	configurePandemicPulse(button, group, rule)
end

local function configureBar(button, group, rule)
	local r, g, b, a = resolveColor(group, rule)
	button.bar:SetStatusBarColor(r, g, b, group.barAlpha or a)
	button.bar:SetOrientation(group.barOrientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL")
	if UFHelper and UFHelper.applyStatusBarReverseFill then UFHelper.applyStatusBarReverseFill(button.bar, group.barReverseFill == true) end
	button.bar:Show()
	if group.barDrainAnimation == true then
		local interpolation = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
		local direction = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
		call(button, "SetDurationBar", button.bar, { interpolation = interpolation, direction = direction })
	else
		button.bar:SetValue(1)
	end
end

local function configureTint(button, group, rule, healthBar)
	local r, g, b, a = resolveColor(group, rule)
	-- Aura slot buttons become inaccessible after initializeFrame returns.
	-- Clone the health texture here and let native slot/fill visibility propagate.
	if healthBar and healthBar.GetFrameStrata then button:SetFrameStrata(healthBar:GetFrameStrata()) end
	if healthBar and healthBar.GetFrameLevel then button:SetFrameLevel(max(0, healthBar:GetFrameLevel() or 0)) end
	local healthTexture = healthBar and healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
	button.tint:ClearAllPoints()
	button.tint:SetAllPoints(healthTexture or button)
	local atlas = healthTexture and healthTexture.GetAtlas and healthTexture:GetAtlas()
	if atlas and atlas ~= "" and button.tint.SetAtlas then
		button.tint:SetAtlas(atlas, false)
	else
		local texture = healthTexture and healthTexture.GetTexture and healthTexture:GetTexture()
		button.tint:SetTexture(texture or "Interface\\Buttons\\WHITE8x8")
		if button.tint.SetTexCoord then button.tint:SetTexCoord(0, 1, 0, 1) end
	end
	if button.tint.SetHorizTile then button.tint:SetHorizTile(false) end
	if button.tint.SetVertTile then button.tint:SetVertTile(false) end
	if button.tint.SetDesaturated then button.tint:SetDesaturated(true) end
	if button.tint.SetBlendMode then button.tint:SetBlendMode("BLEND") end
	if button.tint.SetDrawLayer then button.tint:SetDrawLayer("OVERLAY", 0) end
	button.tint:SetVertexColor(r, g, b, a)
	button.tint:Show()
end

local function configureBorder(button, group, rule)
	local r, g, b, a = resolveColor(group, rule)
	if addon.functions and addon.functions.SetSafeBorder then
		addon.functions.SetSafeBorder(button.border, true, "Interface\\Buttons\\WHITE8x8", max(1, tonumber(group.borderSize) or 1), r, g, b, a, {
			stateKey = "_eqolHBPManagedBorder",
			defaultTexture = "Interface\\Buttons\\WHITE8x8",
			drawLayer = "OVERLAY",
		})
	else
		button.border:Show()
	end
end

local function configureSlotFrame(button, config, group, rule, tintTarget)
	ensureCommonRegions(button)
	clearBindings(button)
	local style = tostring(group.style or "ICON"):upper()
	if style == "ICON" then
		configureIcon(button, config, group, rule)
		configureIndicatorBorder(button, group)
	elseif style == "SQUARE" then
		configureSquare(button, config, group, rule)
		configureIndicatorBorder(button, group)
	elseif style == "BAR" then
		configureBar(button, group, rule)
	elseif style == "BORDER" then
		configureBorder(button, group, rule)
	elseif style == "TINT" then
		configureTint(button, group, rule, tintTarget)
	end
end

local function getBarSize(group, root)
	local width, height = root:GetWidth(), root:GetHeight()
	if type(HB.GetBarDisplaySize) == "function" then
		local barWidth, barHeight, sized = HB.GetBarDisplaySize(group, width, height)
		if sized then return max(1, barWidth), max(1, barHeight) end
	end
	local thickness = max(1, tonumber(group.barThickness) or 6)
	local inset = max(0, tonumber(group.inset) or 0)
	if group.barOrientation == "VERTICAL" then return thickness, max(1, height - (inset * 2)) end
	return max(1, width - (inset * 2)), thickness
end

local function getGridOffset(group, index)
	if group.iconMode == "PRIORITY" then return 0, 0 end
	local axes = GROWTH[tostring(group.growth or "RIGHTDOWN"):upper()] or GROWTH.RIGHTDOWN
	local primary, secondary = axes[1], axes[2]
	local perRow = max(1, floor(tonumber(group.perRow) or 1))
	local primaryIndex = (index - 1) % perRow
	local secondaryIndex = floor((index - 1) / perRow)
	local step = max(1, tonumber(group.size) or 16) + max(0, tonumber(group.spacing) or 0)
	local function delta(direction, amount)
		if direction == "LEFT" then return -amount, 0 end
		if direction == "RIGHT" then return amount, 0 end
		if direction == "UP" then return 0, amount end
		return 0, -amount
	end
	local x1, y1 = delta(primary, primaryIndex * step)
	local x2, y2 = delta(secondary, secondaryIndex * step)
	return x1 + x2, y1 + y2
end

local function layoutSlot(frame, root, group, index, priority)
	frame:ClearAllPoints()
	local style = tostring(group.style or "ICON"):upper()
	if style == "TINT" then
		frame:SetAllPoints(root)
		if root.GetFrameStrata then frame:SetFrameStrata(root:GetFrameStrata()) end
		if root.GetFrameLevel then frame:SetFrameLevel(max(0, root:GetFrameLevel() or 0)) end
		return
	end
	local anchor = tostring(group.anchorPoint or "CENTER"):upper()
	local ownPoint = group.anchorOutside == true and (OPPOSITE[anchor] or anchor) or anchor
	local x, y = tonumber(group.x) or 0, tonumber(group.y) or 0
	local width, height
	if style == "ICON" or style == "SQUARE" then
		local dx, dy = getGridOffset(group, index)
		x, y = x + dx, y + dy
		width = max(1, tonumber(group.size) or 16)
		height = width
	elseif style == "BAR" then
		width, height = getBarSize(group, root)
	elseif style == "BORDER" then
		local inset = max(0, tonumber(group.inset) or 0)
		width, height = max(1, root:GetWidth() - (inset * 2)), max(1, root:GetHeight() - (inset * 2))
	end
	frame:SetSize(width or 1, height or 1)
	frame:SetPoint(ownPoint, root, anchor, x, y)
	local layerBase = style == "BORDER" and root.GetParent and root:GetParent() or root
	if layerBase and layerBase.GetFrameStrata then frame:SetFrameStrata(group.barStrata or group.borderStrata or layerBase:GetFrameStrata()) end
	if layerBase and layerBase.GetFrameLevel then
		local offset = style == "BAR" and (tonumber(group.barFrameLevelOffset) or 3)
			or style == "BORDER" and (tonumber(group.borderFrameLevelOffset) or 16) or 30
		frame:SetFrameLevel(max(0, (layerBase:GetFrameLevel() or 0) + offset + (priority or 0)))
	end
end

local function getIconGroupFilters(ruleIDs, compiled, maxCount, auraType)
	local filters = {}
	local filtersByString = {}
	for i = 1, #(ruleIDs or EMPTY) do
		local rule = compiled.ruleById and compiled.ruleById[ruleIDs[i]]
		if rule and rule.enabled ~= false and rule["not"] ~= true and isRuleRelevantToPlayer(rule, compiled) then
			local ruleSpellIDs = getRuleSpellIDs(rule, compiled)
			local filterString = type(HB.GetRuleAuraFilter) == "function" and HB.GetRuleAuraFilter(rule, compiled, auraType) or nil
			if not filterString then
				local scanAll = type(HB.GetFamilyScanAllCasters) == "function" and HB.GetFamilyScanAllCasters(rule.spellFamilyId, compiled) == true
				filterString = scanAll and auraType or (auraType .. "|PLAYER")
			end
			if hasSpellIDs(ruleSpellIDs) then
				local pulseSignature = getExpirationPulseSignature(rule)
				local filterKey = filterString .. "\031" .. pulseSignature
				local filter = filtersByString[filterKey]
				if not filter then
					filter = {
						filterString = filterString,
						includeSpellIDs = {},
						maxFrameCount = 0,
						pulseSignature = pulseSignature,
						rule = rule.expirationPulseEnabled == true and rule or nil,
						ruleCount = 0,
					}
					filtersByString[filterKey] = filter
					filters[#filters + 1] = filter
				end
				filter.ruleCount = filter.ruleCount + 1
				for spellID, enabled in pairs(ruleSpellIDs) do
					if enabled == true then filter.includeSpellIDs[spellID] = true end
				end
			end
		end
	end

	-- Native limits apply per AuraGroup, so share the indicator limit across
	-- caster-filter groups while preserving one dense container flow.
	local remaining = max(0, floor(tonumber(maxCount) or 0))
	while remaining > 0 do
		local allocated
		for i = 1, #filters do
			local filter = filters[i]
			if filter.maxFrameCount < filter.ruleCount then
				filter.maxFrameCount = filter.maxFrameCount + 1
				remaining = remaining - 1
				allocated = true
				if remaining == 0 then break end
			end
		end
		if not allocated then break end
	end

	return filters
end

local function getFixedIconGroupFilters(ruleIDs, compiled, auraType)
	local filters = {}
	for i = 1, #(ruleIDs or EMPTY) do
		local ruleID = ruleIDs[i]
		local rule = compiled.ruleById and compiled.ruleById[ruleID]
		if rule and rule.enabled ~= false and rule["not"] ~= true and isRuleRelevantToPlayer(rule, compiled) then
			local includeSpellIDs = getRuleSpellIDs(rule, compiled)
			if hasSpellIDs(includeSpellIDs) then
				local filterString = type(HB.GetRuleAuraFilter) == "function" and HB.GetRuleAuraFilter(rule, compiled, auraType) or (auraType .. "|PLAYER")
				filters[#filters + 1] = {
					filterString = filterString,
					includeSpellIDs = includeSpellIDs,
					maxFrameCount = 1,
					rule = rule,
					ruleID = ruleID,
				}
			end
		end
	end
	return filters
end

local function getIconGroupLayout(group, layoutIndex, fixedSquareGroup)
	local size = max(1, tonumber(group.size) or 16)
	local spacing = max(0, tonumber(group.spacing) or 0)
	return {
		elementSpacing = spacing,
		lineSpacing = spacing,
		groupSpacing = fixedSquareGroup and 0 or spacing,
		groupLineSpacing = fixedSquareGroup and 0 or spacing,
		elementWidth = size,
		elementHeight = size,
		layoutIndex = layoutIndex,
	}
end

local function getIconGroupFlow(group, root)
	local axes = GROWTH[tostring(group.growth or "RIGHTDOWN"):upper()] or GROWTH.RIGHTDOWN
	local primary, secondary = axes[1], axes[2]
	local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
	local horizontal = primaryHorizontal and primary or secondary
	local vertical = primaryHorizontal and secondary or primary
	local flow = AnchorUtil and AnchorUtil.FlowDirection
	local flowAxes = AnchorUtil and AnchorUtil.FlowLayoutAxis
	if not (flow and flowAxes) then return nil end
	local perRow = max(1, floor(tonumber(group.perRow) or 1))
	local size = max(1, tonumber(group.size) or 16)
	local spacing = max(0, tonumber(group.spacing) or 0)
	local anchor = tostring(group.anchorPoint or "CENTER"):upper()
	local ownPoint = group.anchorOutside == true and (OPPOSITE[anchor] or anchor) or anchor
	return {
		axis = primaryHorizontal and flowAxes.Horizontal or flowAxes.Vertical,
		anchorPoint = ownPoint,
		horizontalGrowthDirection = horizontal == "LEFT" and flow.Left or flow.Right,
		verticalGrowthDirection = vertical == "UP" and flow.Up or flow.Down,
		maximumLineSize = addon.AuraCompat:GetSafeFlowLayoutMaximumLineSize(root, size, spacing, perRow),
	}
end

local function layoutIconGroupContainer(entry, root, group)
	local container = entry and entry.container
	local flow = getIconGroupFlow(group, root)
	if not (container and flow) then return false end
	local anchor = tostring(group.anchorPoint or "CENTER"):upper()
	local ownPoint = group.anchorOutside == true and (OPPOSITE[anchor] or anchor) or anchor
	container:ClearAllPoints()
	container:SetPoint(ownPoint, root, anchor, tonumber(group.x) or 0, tonumber(group.y) or 0)
	if root.GetFrameStrata then container:SetFrameStrata(root:GetFrameStrata()) end
	if root.GetFrameLevel then container:SetFrameLevel(max(0, (root:GetFrameLevel() or 0) + 30)) end
	return addon.AuraCompat:ConfigureAuraContainerLayout(container, flow)
end

local function copySettings(value)
	if type(value) ~= "table" then return value end
	local copied = {}
	for key, child in pairs(value) do copied[key] = copySettings(child) end
	return copied
end

local function settingsMatch(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, value in pairs(left) do
		if not settingsMatch(value, right[key]) then return false end
	end
	for key in pairs(right) do
		if left[key] == nil then return false end
	end
	return true
end

local function appendSettingsSignature(value, parts)
	local valueType = type(value)
	if valueType == "table" then
		local keys = {}
		for key in pairs(value) do keys[#keys + 1] = key end
		table.sort(keys, function(left, right) return type(left) .. tostring(left) < type(right) .. tostring(right) end)
		parts[#parts + 1] = "{"
		for i = 1, #keys do
			appendSettingsSignature(keys[i], parts)
			appendSettingsSignature(value[keys[i]], parts)
		end
		parts[#parts + 1] = "}"
	else
		local text = tostring(value)
		parts[#parts + 1] = valueType .. ":" .. tostring(#text) .. ":" .. text
	end
end

local function supportsMissing(group)
	local style = group and tostring(group.style or "ICON"):upper()
	return (style == "ICON" or style == "SQUARE") and addon.AuraCompat.CreateInverseAuraClip ~= nil
end

local function hasMissingRules(group, ruleIDs, compiled)
	if not supportsMissing(group) then return false end
	for _, ruleID in ipairs(ruleIDs or EMPTY) do
		local rule = compiled.ruleById and compiled.ruleById[ruleID]
		if rule and rule.enabled ~= false and rule["not"] == true and isRuleRelevantToPlayer(rule, compiled) then return true end
	end
	return false
end

-- Missing indicators have no native duration or stacks. Keep their fixed visuals
-- outside the restricted AuraButton; native group geometry controls the clip.
local function configureMissingFrame(frame, group, rule, spellID)
	local texture = frame:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints(frame)
	if tostring(group.style or "ICON"):upper() == "SQUARE" then
		texture:SetColorTexture(resolveColor(group, rule))
	else
		texture:SetTexture(C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID) or 134400)
		if addon.IconShape and addon.IconShape.ApplyTextureZoom then
			addon.IconShape.ApplyTextureZoom(texture, group.iconZoom, "_eqolHBPMissingZoom", 0)
		else
			texture:SetTexCoord(0, 1, 0, 1)
		end
		texture:SetDesaturated(rule.desaturateMissing == true)
	end
	configureIndicatorBorder(frame, group)
end

local function getManagedPlan(config, compiled, root, state, auraType)
	local auraConfig = getIconStyle(config, EMPTY, auraType)
	auraConfig.hideTooltipInCombat = AuraUtil and AuraUtil.ShouldHideNativeAuraTooltipInCombat
		and AuraUtil.ShouldHideNativeAuraTooltipInCombat(auraConfig) or auraConfig.hideTooltipInCombat
	local auraKey = auraType == "HARMFUL" and "debuff" or "buff"
	local plan = {
		config = { auraType = auraType, auras = { [auraKey] = auraConfig }, health = { texture = config.health and config.health.texture }, barTexture = config.barTexture },
		groups = {},
		width = root:GetWidth(),
		height = root:GetHeight(),
		strata = root:GetFrameStrata(),
		level = root:GetFrameLevel(),
		root = tostring(root),
		health = tostring(state.health),
		fontVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0,
		durationVersion = addon.DurationText and addon.DurationText.version or 0,
	}
	for groupIndex = 1, #(compiled.groupOrder or EMPTY) do
		local groupID = compiled.groupOrder[groupIndex]
		local group = compiled.groupsById and compiled.groupsById[groupID]
		local ruleIDs = compiled.groupToEnabledRuleIds and compiled.groupToEnabledRuleIds[groupID]
		local style = group and tostring(group.style or ""):upper() or ""
		local layerBase = style == "TINT" and state.health or style == "BORDER" and root:GetParent() or nil
		if layerBase then
			plan[style .. "Layer"] = { frame = tostring(layerBase), strata = layerBase:GetFrameStrata(), level = layerBase:GetFrameLevel() }
		end
		local showAll = group and tostring(group.iconMode or "ALL"):upper() == "ALL"
		local limit = group and max(0, floor(tonumber(group.max) or 0)) or 0
		if limit > 0 and ((style ~= "ICON" and style ~= "SQUARE") or not showAll) then limit = #(ruleIDs or EMPTY) end
		local fixedIconOrder = style == "ICON" and tostring(group.iconLayoutMode or "MAX"):upper() == "FIXED_SORT"
		local squareFlow = showAll and style == "SQUARE"
		local missingRules = hasMissingRules(group, ruleIDs, compiled)
		local compactFlow = not missingRules and (squareFlow or (showAll and style == "ICON" and (fixedIconOrder or limit > 0)))
		if missingRules and (squareFlow or fixedIconOrder) and limit > 0 then limit = #(ruleIDs or EMPTY) end
		local filters
		if compactFlow then
			if squareFlow or fixedIconOrder then
				filters = getFixedIconGroupFilters(ruleIDs, compiled, auraType)
			elseif limit > 0 then
				filters = getIconGroupFilters(ruleIDs, compiled, limit, auraType)
			end
			if not (filters and filters[1]) then compactFlow = false end
		end
		if compactFlow then
			plan.groups[#plan.groups + 1] = { id = groupID, group = group, filters = filters, fixedSquare = squareFlow }
		elseif not squareFlow or missingRules then
			local slots = {}
			for ruleIndex = 1, #(ruleIDs or EMPTY) do
				local ruleID = ruleIDs[ruleIndex]
				local rule = compiled.ruleById and compiled.ruleById[ruleID]
				if limit > 0 and rule and rule.enabled ~= false and (rule["not"] ~= true or supportsMissing(group)) and isRuleRelevantToPlayer(rule, compiled) then
					local includeSpellIDs = getRuleSpellIDs(rule, compiled)
					if hasSpellIDs(includeSpellIDs) then
						if #slots >= limit then break end
						local filterString = type(HB.GetRuleAuraFilter) == "function" and HB.GetRuleAuraFilter(rule, compiled, auraType) or nil
						if not filterString then
							local scanAll = type(HB.GetFamilyScanAllCasters) == "function" and HB.GetFamilyScanAllCasters(rule.spellFamilyId, compiled) == true
							filterString = scanAll and auraType or (auraType .. "|PLAYER")
						end
						slots[#slots + 1] = {
							key = "hbp:" .. tostring(groupID) .. ":" .. tostring(ruleID),
							rule = rule,
							filterString = filterString,
							includeSpellIDs = includeSpellIDs,
							priority = #ruleIDs - ruleIndex,
							missing = rule["not"] == true,
							spellID = (HB.GetRuleSpellIDs(rule, compiled) or EMPTY)[1],
						}
					end
				end
			end
			if slots[1] then plan.groups[#plan.groups + 1] = { id = groupID, group = group, slots = slots } end
		end
	end
	return plan
end

local function hideManagedVariant(managed)
	if not managed then return end
	if managed.container then
		managed.container:SetEnabled(false)
		managed.container:Hide()
	end
	for _, entry in pairs(managed.iconGroups or EMPTY) do
		if entry.container then
			entry.container:SetEnabled(false)
			entry.container:Hide()
		end
	end
	for _, slot in pairs(managed.ruleSlots or EMPTY) do
		if slot.gate then slot.gate:SetEnabled(false) end
	end
	managed.active = nil
end

local function createDisabledContainer(parent)
	local container = addon.AuraCompat:CreateAuraContainer(parent)
	if container then
		container:SetEnabled(false)
		container:Hide()
	end
	return container
end

local function prepareManagedVariant(managed, root, state)
	if managed.ready then return true end
	if not managed.container then
		managed.container = createDisabledContainer(root)
		if not managed.container then return false end
		managed.container:SetAllPoints(root)
	end
	local config = managed.plan.config
	for groupIndex = 1, #managed.plan.groups do
		local planned = managed.plan.groups[groupIndex]
		local group = planned.group
		if planned.filters then
			local entry = managed.iconGroups[planned.id]
			if not entry then
				entry = { groups = {}, container = createDisabledContainer(root) }
				if not entry.container then return false end
				managed.iconGroups[planned.id] = entry
			end
			for index = 1, #planned.filters do
				if not entry.groups[index] then
					local filter = planned.filters[index]
					local rule = filter.rule
					local groupKey = "hbp-flow:" .. tostring(planned.id) .. ":" .. tostring(index)
					if not addon.AuraCompat:RegisterAuraGroup(entry.container, groupKey, filter.filterString, {
						maxFrameCount = filter.maxFrameCount,
						candidateFilters = { includeSpellIDs = filter.includeSpellIDs },
						layout = getIconGroupLayout(group, index, planned.fixedSquare),
						initializeFrame = function(frame)
							ensureCommonRegions(frame)
							configureSlotFrame(frame, config, group, rule)
						end,
					}) then return false end
					entry.groups[index] = { key = groupKey }
				end
			end
			if not layoutIconGroupContainer(entry, root, group) then return false end
		else
			for index = 1, #planned.slots do
				local plannedSlot = planned.slots[index]
				local rule = plannedSlot.rule
				local slotState = managed.ruleSlots[plannedSlot.key]
				if not slotState then
					local host = CreateFrame("Frame", nil, plannedSlot.missing and root or managed.container, "DisableUntrustedLayoutScriptsTemplate")
					host:SetSize(1, 1)
					host:SetPoint("TOPLEFT", managed.container, "BOTTOMLEFT", -64, -64)
					slotState = { host = host }
					managed.ruleSlots[plannedSlot.key] = slotState
				end
				if plannedSlot.missing then
					layoutSlot(slotState.host, root, group, index, plannedSlot.priority)
					if not slotState.gate then
						local size = max(1, tonumber(group.size) or 16)
						local padding = max(0, tonumber(group.indicatorBorderOffset) or 0) + max(1, tonumber(group.indicatorBorderSize) or 1) + 2
						slotState.gate = addon.AuraCompat:CreateInverseAuraClip(root, slotState.host, {
							width = size, height = size, paddingLeft = padding, paddingRight = padding,
							paddingTop = padding, paddingBottom = padding, enabled = false,
							frameLevel = slotState.host:GetFrameLevel(), frameStrata = slotState.host:GetFrameStrata(), filterString = plannedSlot.filterString,
							candidateFilters = { includeSpellIDs = plannedSlot.includeSpellIDs },
						})
						if not slotState.gate then return false end
						configureMissingFrame(slotState.gate.content, group, rule, plannedSlot.spellID)
					end
				elseif not slotState.frame then
					local tintTarget = tostring(group.style or ""):upper() == "TINT" and state.health or nil
					slotState.frame = addon.AuraCompat:RegisterAuraSlot(managed.container, plannedSlot.key, plannedSlot.filterString, {
						anchorFrame = slotState.host,
						candidateFilters = { includeSpellIDs = plannedSlot.includeSpellIDs },
						initializeFrame = function(frame)
							ensureCommonRegions(frame)
							configureSlotFrame(frame, config, group, rule, tintTarget)
						end,
					})
					if not slotState.frame then return false end
				end
				local layoutRoot = tostring(group.style or ""):upper() == "TINT" and (state.health or root) or root
				layoutSlot(slotState.host, layoutRoot, group, index, plannedSlot.priority)
				if not plannedSlot.missing then managed.hasSlots = true end
			end
		end
	end
	managed.ready = true
	return true
end

function HB.PrecreateManagedAuraContainer(button)
	if not (button and addon.AuraCompat and addon.AuraCompat.CreateAuraContainer) then return nil end
	local managed = getState(button)
	if managed and managed.container then return managed.container end
	if not HB.ApplyManagedAuraContainer(button, true) then return nil end
	managed = getState(button)
	return managed and managed.container
end

function HB.HideManagedAuraContainer(button)
	hideManagedVariant(getState(button))
end

function HB.ApplyManagedAuraContainer(button, prepareOnly, forceRefresh)
	if not (button and addon.AuraCompat and addon.AuraCompat.RegisterAuraSlot and addon.AuraCompat.RegisterAuraGroup) then return false end
	local managed, state = getState(button)
	local root = state and (state.healerBuffRoot or state.barGroup or button)
	local unit = button._eqolUnit or (prepareOnly and "player")
	local config = button._eqolCfg
	local kind = button._eqolGroupKind or "party"
	local compiled = config and type(HB.GetCompiled) == "function" and HB.GetCompiled(kind, config) or nil
	local auraType = type(HB.GetUnitAuraType) == "function" and HB.GetUnitAuraType(unit) or nil
	if state then state._healerBuffPlacementAuraType = auraType end
	if not (managed and root and unit and auraType and compiled and compiled.enabled) then
		HB.HideManagedAuraContainer(button)
		if state then state._healerBuffPlacementActive = nil end
		return false
	end

	local plan = getManagedPlan(config, compiled, root, state, auraType)
	local variant = managed.plan and settingsMatch(managed.plan, plan) and managed or nil
	if not variant then
		local parts = {}
		appendSettingsSignature(plan, parts)
		local signature = table.concat(parts, "\031")
		state._healerBuffManagedVariants = state._healerBuffManagedVariants or {}
		variant = state._healerBuffManagedVariants[signature]
		if not variant then
			-- Deferred button initializers must retain this configuration even after
			-- settings tables change or another layout becomes active on the frame.
			variant = { signature = signature, plan = copySettings(plan), iconGroups = {}, ruleSlots = {} }
			state._healerBuffManagedVariants[signature] = variant
		end
	end
	if variant ~= managed then hideManagedVariant(managed) end
	if not prepareManagedVariant(variant, root, state) then
		hideManagedVariant(variant)
		state._healerBuffPlacementActive = nil
		return false
	end
	state._healerBuffManaged = variant
	if prepareOnly then
		hideManagedVariant(variant)
		return true
	end

	local refresh = forceRefresh == true or variant.active ~= true or variant.unit ~= unit
	local function activate(container)
		if refresh then container:SetUnit(unit) end
		container:Show()
		container:SetEnabled(true)
		if refresh then addon.AuraCompat:UpdateAuraContainer(container) end
	end
	if variant.hasSlots then activate(variant.container) end
	for _, entry in pairs(variant.iconGroups) do activate(entry.container) end
	local suppressMissing = HB.ShouldSuppressMissingForUnit and HB.ShouldSuppressMissingForUnit(unit) == true
	for _, slot in pairs(variant.ruleSlots) do
		if slot.gate then
			if refresh then slot.gate:Configure({ unit = unit }) end
			slot.gate:SetEnabled(not suppressMissing)
			if forceRefresh and not suppressMissing then slot.gate:Refresh() end
		end
	end
	variant.unit = unit
	variant.active = true
	state._healerBuffPlacementActive = true
	return true
end

function HB.ConsumeManagedAuraContainerPending()
	local pending = HB._managedAuraContainerPending == true
	HB._managedAuraContainerPending = nil
	return pending
end
