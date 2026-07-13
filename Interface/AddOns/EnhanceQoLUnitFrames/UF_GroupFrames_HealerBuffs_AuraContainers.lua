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
local EMPTY_SPELL_FILTER = { includeSpellIDs = {} }
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

local function getVisualSignature(group, rule, config)
	local values = {}
	local fields = {
		"style", "size", "iconZoom", "barOrientation", "barAlpha", "barDrainAnimation", "barFillFrame", "barReverseFill", "borderSize", "showCooldownSwipe",
		"showCooldownEdge", "showCooldownBling", "hideCooldownText", "hideChargeText", "cooldownTextSize", "chargeTextSize",
	}
	for i = 1, #fields do values[#values + 1] = tostring(group[fields[i]]) end
	local auraConfig = config and config.auras and config.auras.buff or EMPTY
	for _, field in ipairs({ "showTooltip", "showCooldown", "showCooldownText", "showStacks", "cooldownAnchor", "cooldownFont", "cooldownFontSize", "cooldownFontOutline", "durationTextProfile", "countAnchor", "countFont", "countFontSize", "countFontOutline" }) do
		values[#values + 1] = tostring(auraConfig[field])
	end
	local color = type(rule and rule.color) == "table" and rule.color or group.color
	local colorKeys = { "r", "g", "b", "a" }
	for i = 1, 4 do values[#values + 1] = tostring(type(color) == "table" and (color[i] or color[colorKeys[i]]) or nil) end
	return table.concat(values, "\031")
end

local function getFilterSignature(filterString, includeSpellIDs)
	local values = { tostring(filterString) }
	local spellIDs = {}
	for spellID, enabled in pairs(includeSpellIDs) do
		if enabled == true then spellIDs[#spellIDs + 1] = spellID end
	end
	table.sort(spellIDs)
	for i = 1, #spellIDs do values[#values + 1] = tostring(spellIDs[i]) end
	return table.concat(values, "\031")
end

local function getLayoutSignature(group, root, index, priority)
	return table.concat({
		tostring(root and root:GetWidth()), tostring(root and root:GetHeight()), tostring(group.style), tostring(group.anchorPoint),
		tostring(group.anchorOutside), tostring(group.x), tostring(group.y), tostring(group.growth), tostring(group.perRow),
		tostring(group.spacing), tostring(group.size), tostring(group.iconMode), tostring(group.barThickness), tostring(group.barWidth),
		tostring(group.barHeight), tostring(group.barStrata), tostring(group.barFrameLevelOffset), tostring(group.inset),
		tostring(group.borderStrata), tostring(group.borderFrameLevelOffset), tostring(index), tostring(priority),
	}, "\031")
end

local function getState(button)
	local state = button and button._eqolUFState
	if not state then return nil end
	state._healerBuffManaged = state._healerBuffManaged or { slots = {}, ruleSlots = {}, activeKeys = {} }
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

local function clearBindings(button)
	call(button, "ClearIcon")
	call(button, "ClearDurationCooldown")
	call(button, "ClearDurationText")
	call(button, "ClearDurationBar")
	call(button, "ClearApplicationCount")
	button.icon:Hide()
	button.square:Hide()
	button.tint:Hide()
	button.cd:Hide()
	button.durationText:Hide()
	button.count:Hide()
	button.bar:Hide()
	if addon.functions and addon.functions.SetSafeBorder then
		addon.functions.SetSafeBorder(button.border, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolHBPManagedBorder" })
	else
		button.border:Hide()
	end
end

local function getIconStyle(config, group)
	local auraConfig = config and config.auras and config.auras.buff or EMPTY
	return {
		size = group.size,
		iconZoom = group.iconZoom,
		showTooltip = auraConfig.showTooltip == true,
		showCooldown = auraConfig.showCooldown ~= false,
		showCooldownSwipe = group.showCooldownSwipe ~= false,
		showCooldownEdge = group.showCooldownEdge ~= false,
		showCooldownBling = group.showCooldownBling ~= false,
		showCooldownText = group.hideCooldownText ~= true and auraConfig.showCooldownText ~= false,
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

local function configureIcon(button, config, group)
	local style = getIconStyle(config, group)
	button._eqolNativeAuraStyleKey = nil
	if AuraUtil and AuraUtil.PrepareNativeAuraButton then AuraUtil.PrepareNativeAuraButton(button, style, false) end
	button.icon:Show()
end

local function configureSquare(button, group, rule)
	local r, g, b, a = resolveColor(group, rule)
	button.square:SetColorTexture(r, g, b, a)
	button.square:Show()
	if group.showCooldownSwipe ~= false then
		button.cd:SetDrawSwipe(true)
		button.cd:SetDrawEdge(group.showCooldownEdge ~= false)
		button.cd:SetDrawBling(group.showCooldownBling ~= false)
		button.cd:SetReverse(true)
		button.cd:Show()
		call(button, "SetDurationCooldown", button.cd)
	end
end

local function configureBar(button, group, rule)
	local r, g, b, a = resolveColor(group, rule)
	button.bar:SetStatusBarColor(r, g, b, group.barAlpha or a)
	button.bar:SetOrientation(group.barOrientation == "VERTICAL" and "VERTICAL" or "HORIZONTAL")
	if UFHelper and UFHelper.applyStatusBarReverseFill then UFHelper.applyStatusBarReverseFill(button.bar, group.barReverseFill == true) end
	button.bar:Show()
	if group.barDrainAnimation == true then
		local interpolation = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
		local direction = Enum and Enum.StatusBarTimerDirection
			and (group.barReverseFill == true and Enum.StatusBarTimerDirection.ElapsedTime or Enum.StatusBarTimerDirection.RemainingTime)
		call(button, "SetDurationBar", button.bar, { interpolation = interpolation, direction = direction })
	else
		button.bar:SetValue(1)
	end
end

local function configureTint(button, group, rule)
	local r, g, b, a = resolveColor(group, rule)
	button.tint:SetColorTexture(r, g, b, a)
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

local function configureSlotFrame(button, config, group, rule)
	ensureCommonRegions(button)
	clearBindings(button)
	local style = tostring(group.style or "ICON"):upper()
	if style == "ICON" then
		configureIcon(button, config, group)
	elseif style == "SQUARE" then
		configureSquare(button, group, rule)
	elseif style == "BAR" then
		configureBar(button, group, rule)
	elseif style == "BORDER" then
		configureBorder(button, group, rule)
	elseif style == "TINT" then
		configureTint(button, group, rule)
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
	elseif style == "BORDER" or style == "TINT" then
		local inset = max(0, tonumber(group.inset) or 0)
		width, height = max(1, root:GetWidth() - (inset * 2)), max(1, root:GetHeight() - (inset * 2))
	end
	frame:SetSize(width or 1, height or 1)
	frame:SetPoint(ownPoint, root, anchor, x, y)
	if root.GetFrameStrata then frame:SetFrameStrata(group.barStrata or group.borderStrata or root:GetFrameStrata()) end
	if root.GetFrameLevel then
		local offset = style == "BAR" and (tonumber(group.barFrameLevelOffset) or 3)
			or style == "BORDER" and (tonumber(group.borderFrameLevelOffset) or 4) or 30
		frame:SetFrameLevel(max(0, (root:GetFrameLevel() or 0) + offset + (priority or 0)))
	end
end

local function getIconGroupFilter(ruleIDs, compiled)
	local includeSpellIDs = {}
	local groupFilter
	for i = 1, #(ruleIDs or EMPTY) do
		local rule = compiled.ruleById and compiled.ruleById[ruleIDs[i]]
		if rule and rule.enabled ~= false and rule["not"] ~= true then
			local ruleSpellIDs = getRuleSpellIDs(rule, compiled)
			local filterString = type(HB.GetRuleAuraFilter) == "function" and HB.GetRuleAuraFilter(rule, compiled) or nil
			if not filterString then
				local scanAll = type(HB.GetFamilyScanAllCasters) == "function" and HB.GetFamilyScanAllCasters(rule.spellFamilyId, compiled) == true
				filterString = scanAll and "HELPFUL" or "HELPFUL|PLAYER"
			end
			if hasSpellIDs(ruleSpellIDs) and groupFilter and groupFilter ~= filterString then return nil, nil end
			if hasSpellIDs(ruleSpellIDs) then groupFilter = filterString end
			for spellID, enabled in pairs(ruleSpellIDs) do
				if enabled == true then includeSpellIDs[spellID] = true end
			end
		end
	end
	return groupFilter, includeSpellIDs
end

local function getIconGroupLayout(group)
	local size = max(1, tonumber(group.size) or 16)
	local spacing = max(0, tonumber(group.spacing) or 0)
	return { elementSpacingX = spacing, elementSpacingY = spacing, elementWidth = size, elementHeight = size }
end

local function getIconGroupFlow(group)
	local axes = GROWTH[tostring(group.growth or "RIGHTDOWN"):upper()] or GROWTH.RIGHTDOWN
	local primary, secondary = axes[1], axes[2]
	local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
	local horizontal = primaryHorizontal and primary or secondary
	local vertical = primaryHorizontal and secondary or primary
	local flow = AnchorUtil and AnchorUtil.FlowDirection
	if not flow then return nil end
	local perRow = max(1, floor(tonumber(group.perRow) or 1))
	if not primaryHorizontal then perRow = max(1, math.ceil(max(1, tonumber(group.max) or 1) / perRow)) end
	local size = max(1, tonumber(group.size) or 16)
	local spacing = max(0, tonumber(group.spacing) or 0)
	local anchor = tostring(group.anchorPoint or "CENTER"):upper()
	local ownPoint = group.anchorOutside == true and (OPPOSITE[anchor] or anchor) or anchor
	return {
		anchorPoint = ownPoint,
		horizontalGrowthDirection = horizontal == "LEFT" and flow.Left or flow.Right,
		verticalGrowthDirection = vertical == "UP" and flow.Up or flow.Down,
		rowWidth = (perRow * size) + (max(0, perRow - 1) * spacing),
	}
end

local function getIconGroupLayoutSignature(group, root)
	return table.concat({
		tostring(root:GetWidth()), tostring(root:GetHeight()), tostring(group.anchorPoint), tostring(group.anchorOutside), tostring(group.x),
		tostring(group.y), tostring(group.growth), tostring(group.perRow), tostring(group.spacing), tostring(group.size), tostring(group.max),
	}, "\031")
end

local function layoutIconGroupContainer(entry, root, group)
	local container = entry and entry.container
	local flow = getIconGroupFlow(group)
	if not (container and flow) then return false end
	local anchor = tostring(group.anchorPoint or "CENTER"):upper()
	local ownPoint = group.anchorOutside == true and (OPPOSITE[anchor] or anchor) or anchor
	container:ClearAllPoints()
	container:SetPoint(ownPoint, root, anchor, tonumber(group.x) or 0, tonumber(group.y) or 0)
	if root.GetFrameStrata then container:SetFrameStrata(root:GetFrameStrata()) end
	if root.GetFrameLevel then container:SetFrameLevel(max(0, (root:GetFrameLevel() or 0) + 30)) end
	return addon.AuraCompat:ConfigureAuraContainerLayout(container, flow)
end

local function applyIconAllGroup(managed, root, unit, config, groupID, group, filterString, includeSpellIDs, prepareOnly)
	managed.iconGroups = managed.iconGroups or {}
	local entry = managed.iconGroups[groupID]
	local maxCount = max(0, floor(tonumber(group.max) or 0))
	if maxCount < 1 or not hasSpellIDs(includeSpellIDs) then return false end
	local generationSignature = getVisualSignature(group, nil, config) .. "\030" .. getFilterSignature(filterString, includeSpellIDs)
	if not entry then
		if InCombatLockdown and InCombatLockdown() then return nil, "combat" end
		entry = { generation = 0, container = addon.AuraCompat:CreateAuraContainer(root) }
		if not entry.container then return false end
		entry.container:SetEnabled(false)
		entry.container:Hide()
		managed.iconGroups[groupID] = entry
	end
	if entry.unit ~= unit then
		entry.unit = unit
		entry.container:SetUnit(unit)
	end
	if entry.generationSignature ~= generationSignature then
		if InCombatLockdown and InCombatLockdown() then return nil, "combat" end
		if entry.groupKey then addon.AuraCompat:UpdateAuraGroup(entry.container, entry.groupKey, { maxFrameCount = 0 }) end
		entry.generation = entry.generation + 1
		entry.groupKey = "hbp-icons:" .. tostring(groupID) .. ":" .. tostring(entry.generation)
		local initialGroup = group
		if not addon.AuraCompat:RegisterAuraGroup(entry.container, entry.groupKey, filterString, {
			maxFrameCount = maxCount,
			candidateFilters = { includeSpellIDs = includeSpellIDs },
			layout = getIconGroupLayout(group),
			initializeFrame = function(frame)
				ensureCommonRegions(frame)
				configureSlotFrame(frame, config, initialGroup, nil)
			end,
		}) then
			return false
		end
		entry.generationSignature = generationSignature
		entry.layoutSignature = nil
	end
	local layoutSignature = getIconGroupLayoutSignature(group, root)
	if entry.layoutSignature ~= layoutSignature then
		if not addon.AuraCompat:UpdateAuraGroup(entry.container, entry.groupKey, {
			maxFrameCount = maxCount,
			candidateFilters = { includeSpellIDs = includeSpellIDs },
			layout = getIconGroupLayout(group),
		}) or not layoutIconGroupContainer(entry, root, group) then
			return false
		end
		entry.layoutSignature = layoutSignature
	end
	if prepareOnly then
		entry.container:SetEnabled(false)
		entry.container:Hide()
	else
		entry.container:Show()
		entry.container:SetEnabled(true)
	end
	return true
end

function HB.PrecreateManagedAuraContainer(button)
	if not (button and addon.AuraCompat and addon.AuraCompat.CreateAuraContainer) then return nil end
	local managed, state = getState(button)
	if not (managed and state) then return nil end
	if managed.container then return managed.container end
	if InCombatLockdown and InCombatLockdown() then
		managed.pending = true
		HB._managedAuraContainerPending = true
		return nil
	end
	local parent = state.healerBuffRoot or state.barGroup or button
	managed.container = addon.AuraCompat:CreateAuraContainer(parent)
	if not managed.container then return nil end
	managed.container:SetAllPoints(parent)
	managed.container:SetEnabled(false)
	managed.container:Hide()
	if not (InCombatLockdown and InCombatLockdown()) and not managed.preparing then
		managed.preparing = true
		HB.ApplyManagedAuraContainer(button, true)
		managed.preparing = nil
	end
	return managed.container
end

function HB.HideManagedAuraContainer(button)
	local managed = getState(button)
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
end

function HB.ApplyManagedAuraContainer(button, prepareOnly)
	if not (button and addon.AuraCompat and addon.AuraCompat.RegisterAuraSlot and addon.AuraCompat.UpdateAuraSlot) then return false end
	local managed, state = getState(button)
	local root = state and (state.healerBuffRoot or state.barGroup or button)
	local unit = button.unit or (prepareOnly and "player")
	local config = button._eqolCfg
	local kind = button._eqolGroupKind or "party"
	local compiled = config and type(HB.GetCompiled) == "function" and HB.GetCompiled(kind, config) or nil
	if not (managed and root and unit and compiled and compiled.enabled) then
		HB.HideManagedAuraContainer(button)
		if state then state._healerBuffPlacementActive = nil end
		return false
	end
	local container = HB.PrecreateManagedAuraContainer(button)
	if not container then return false end
	local dirty = managed.unit ~= unit
	if dirty then
		managed.unit = unit
		container:SetUnit(unit)
	end
	local previousActiveKeys = managed.activeKeys
	managed.activeKeys = {}
	local activeIconGroups = {}
	local anyActiveSlots = false

	for groupIndex = 1, #(compiled.groupOrder or EMPTY) do
		local groupID = compiled.groupOrder[groupIndex]
		local group = compiled.groupsById and compiled.groupsById[groupID]
		local ruleIDs = compiled.groupToEnabledRuleIds and compiled.groupToEnabledRuleIds[groupID]
		local limit = group and max(0, floor(tonumber(group.max) or 0)) or 0
		local compactIcons = group and tostring(group.style or ""):upper() == "ICON" and tostring(group.iconMode or "ALL"):upper() == "ALL"
		local compactFilter, compactSpellIDs
		if compactIcons then
			compactFilter, compactSpellIDs = getIconGroupFilter(ruleIDs, compiled)
			if not compactFilter or not hasSpellIDs(compactSpellIDs) then compactIcons = false end
		end
		if compactIcons then
			local applied, reason = applyIconAllGroup(managed, root, unit, config, groupID, group, compactFilter, compactSpellIDs, prepareOnly)
			if reason == "combat" then
				managed.pending = true
				HB._managedAuraContainerPending = true
				HB.HideManagedAuraContainer(button)
				return false
			end
			if applied then activeIconGroups[groupID] = true end
		else
			local used = 0
			for ruleIndex = 1, #(ruleIDs or EMPTY) do
			local ruleID = ruleIDs[ruleIndex]
			local rule = compiled.ruleById and compiled.ruleById[ruleID]
			if limit > 0 and rule and rule.enabled ~= false and rule["not"] ~= true then
				local includeSpellIDs = getRuleSpellIDs(rule, compiled)
				if hasSpellIDs(includeSpellIDs) then
					used = used + 1
					local baseSlotKey = "hbp:" .. tostring(ruleID)
					local filterString = type(HB.GetRuleAuraFilter) == "function" and HB.GetRuleAuraFilter(rule, compiled) or nil
					if not filterString then
						local scanAll = type(HB.GetFamilyScanAllCasters) == "function" and HB.GetFamilyScanAllCasters(rule.spellFamilyId, compiled) == true
						filterString = scanAll and "HELPFUL" or "HELPFUL|PLAYER"
					end
					local visualSignature = getVisualSignature(group, rule, config)
					local filterSignature = getFilterSignature(filterString, includeSpellIDs)
					local slotState = managed.ruleSlots[baseSlotKey]
					if slotState and slotState.visualSignature ~= visualSignature then
						if InCombatLockdown and InCombatLockdown() then
							managed.pending = true
							HB._managedAuraContainerPending = true
							HB.HideManagedAuraContainer(button)
							return false
						end
						addon.AuraCompat:UpdateAuraSlot(container, slotState.slotKey, { candidateFilters = EMPTY_SPELL_FILTER })
						managed.activeKeys[slotState.slotKey] = nil
						dirty = true
						slotState = nil
					end
					if not slotState then
						if InCombatLockdown and InCombatLockdown() then
							managed.pending = true
							HB._managedAuraContainerPending = true
							HB.HideManagedAuraContainer(button)
							return false
						end
						local generation = (managed.slotGeneration or 0) + 1
						managed.slotGeneration = generation
						local slotKey = baseSlotKey .. ":" .. tostring(generation)
						local initialGroup, initialRule = group, rule
						local slot = addon.AuraCompat:RegisterAuraSlot(container, slotKey, filterString, {
							candidateFilters = { includeSpellIDs = includeSpellIDs },
							initializeFrame = function(frame)
								ensureCommonRegions(frame)
								configureSlotFrame(frame, config, initialGroup, initialRule)
							end,
						})
						managed.slots[slotKey] = slot
						slotState = slot and {
							slotKey = slotKey,
							frame = slot,
							visualSignature = visualSignature,
							filterSignature = filterSignature,
						} or nil
						managed.ruleSlots[baseSlotKey] = slotState
						dirty = slot ~= nil or dirty
					end
					if slotState then
						if slotState.filterSignature ~= filterSignature then
							addon.AuraCompat:UpdateAuraSlot(container, slotState.slotKey, { filterString = filterString, candidateFilters = { includeSpellIDs = includeSpellIDs } })
							slotState.filterSignature = filterSignature
							dirty = true
						end
						local positionIndex = math.min(used, limit)
						local priority = #ruleIDs - ruleIndex
						local layoutSignature = getLayoutSignature(group, root, positionIndex, priority)
						if slotState.layoutSignature ~= layoutSignature then
							layoutSlot(slotState.frame, root, group, positionIndex, priority)
							slotState.layoutSignature = layoutSignature
						end
						managed.activeKeys[slotState.slotKey] = true
						anyActiveSlots = true
					end
				end
			end
		end
		end
	end

	for iconGroupID, entry in pairs(managed.iconGroups or EMPTY) do
		if not activeIconGroups[iconGroupID] and entry.container and entry.generationSignature ~= nil then
			if entry.groupKey then addon.AuraCompat:UpdateAuraGroup(entry.container, entry.groupKey, { maxFrameCount = 0 }) end
			entry.generationSignature = nil
			entry.container:SetEnabled(false)
			entry.container:Hide()
		end
	end

	for slotKey in pairs(previousActiveKeys or EMPTY) do
		if not managed.activeKeys[slotKey] then
			addon.AuraCompat:UpdateAuraSlot(container, slotKey, { candidateFilters = EMPTY_SPELL_FILTER })
			for _, slotState in pairs(managed.ruleSlots) do
				if slotState.slotKey == slotKey then slotState.filterSignature = nil end
			end
			dirty = true
		end
	end
	managed.pending = nil
	if prepareOnly then
		HB.HideManagedAuraContainer(button)
	else
		if anyActiveSlots then
			container:Show()
			container:SetEnabled(true)
			if dirty then addon.AuraCompat:UpdateAuraContainer(container) end
		else
			container:SetEnabled(false)
			container:Hide()
		end
		state._healerBuffPlacementActive = true
	end
	return true
end

function HB.ConsumeManagedAuraContainerPending()
	local pending = HB._managedAuraContainerPending == true
	HB._managedAuraContainerPending = nil
	return pending
end
