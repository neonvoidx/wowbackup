local addon = _G.EnhanceQoL
local Reminder = addon.ClassBuffReminder
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Glow = addon.Glow
local GLOW_KEY = "CLASS_BUFF_REMINDER"
local M = {
	separate = "classBuffReminderExpiringGlow",
	style = "classBuffReminderExpiringGlowStyle",
	color = "classBuffReminderExpiringGlowColor",
	time = "classBuffReminderShowTimeLeft",
	count = "classBuffReminderShowItemCount",
	defaultColor = { r = 1, g = 0.5, b = 0, a = 1 },
}

local function now() return GetTime() end
local function packSlots(...) return { ... }, select("#", ...) end
local function plainNumber(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return type(value) == "number" and value or nil
end
local function defaultEnabled(key) return key == M.time or key == M.count end
local function enabled(key)
	local value = addon.db and addon.db[key]
	if value == nil then return defaultEnabled(key) end
	return value == true
end
local function latest(a, b)
	b = plainNumber(b)
	if b and (not a or b > a) then return b end
	return a
end
local function warningExpiration(expiration, threshold)
	expiration = plainNumber(expiration)
	if not expiration or expiration == math.huge then return nil end
	local remaining = expiration - now()
	if remaining > 0 and remaining <= threshold then return expiration end
end

function Reminder:GetWeaponWarningExpiration(milliseconds)
	milliseconds = plainNumber(milliseconds)
	if milliseconds and milliseconds > 0 then return now() + milliseconds / 1000 end
end

function Reminder:MakeSharedBuffWarningEntry(spellIds, spellId, label, missing, total)
	local entry = self:MakeSpellInteractionEntry(spellIds, spellId, label, missing, total)
	entry.warningCache = self:GetGroupBuffStateCache(spellIds, false)
	return entry
end

-- A unit may have several equivalent auras. The longest valid one provides coverage.
local function stateExpiration(state)
	local expiration
	for _, value in pairs(state and state.expirationByInstance or {}) do expiration = latest(expiration, value) end
	return expiration
end

local function groupExpiration(states, statuses, threshold)
	local earliest
	for unit, state in pairs(states or {}) do
		if not statuses or statuses[unit] == 1 then
			local expiration = warningExpiration(stateExpiration(state), threshold)
			-- An actually missing or unreadable buff takes priority over expiring buffs.
			if not expiration then return nil end
			if not earliest or expiration < earliest then earliest = expiration end
		end
	end
	-- Status entries without a corresponding aura state must not be called expiring.
	for unit, status in pairs(statuses or {}) do
		if status == 1 and not states[unit] then return nil end
	end
	return earliest
end

local function snapshotExpiration(snapshot, query)
	if not snapshot or snapshot.restricted or not snapshot.supported then return nil end
	local expiration
	for _, ids in ipairs({ query.spellIds or {}, query.extraSpellIds or {} }) do
		for _, id in ipairs(ids) do
			if snapshot.spellIds[id] then expiration = latest(expiration, snapshot.spellIdExpirations[id] or math.huge) end
		end
	end
	for _, name in ipairs(query.names or {}) do
		if snapshot.names[name] then expiration = latest(expiration, snapshot.nameExpirations[name] or math.huge) end
	end
	if query.icon and snapshot.icons[query.icon] then expiration = latest(expiration, snapshot.iconExpirations[query.icon] or math.huge) end
	return expiration
end

function Reminder:GetSnapshotWarningExpiration(snapshot, query)
	return warningExpiration(snapshotExpiration(snapshot, query), self:GetExpirationWarningSeconds(query.category))
end

function Reminder:WithWarningAuraUnits(entry, units, spellIds, names)
	entry.warningAuraQuery = { units = {}, spellIds = spellIds, names = names }
	for _, unit in ipairs(units) do entry.warningAuraQuery.units[#entry.warningAuraQuery.units + 1] = unit end
	return entry
end

function Reminder:GetAuraQueryWarningExpiration(query)
	if not query.units then return self:GetSnapshotWarningExpiration(self:GetPlayerAuraPresenceSnapshot(), query) end
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then return nil end
	local spellSet, nameSet = {}, {}
	for _, id in ipairs(query.spellIds or {}) do spellSet[id] = true end
	for _, name in ipairs(query.names or {}) do nameSet[name] = true end
	local expiration
	for _, unit in ipairs(query.units) do
		local continuation
		for _ = 1, 100 do
			local slots, slotCount = packSlots(C_UnitAuras.GetAuraSlots(unit, "HELPFUL", nil, continuation))
			continuation = slots[1]
			if issecretvalue and issecretvalue(continuation) then return nil end
			for i = 2, slotCount do
				local slot = plainNumber(slots[i])
				local aura = slot and C_UnitAuras.GetAuraDataBySlot(unit, slot)
				if aura and not (issecretvalue and issecretvalue(aura)) then
					local id = plainNumber(aura.spellId)
					local name = aura.name
					if issecretvalue and issecretvalue(name) then name = nil end
					if (id and spellSet[id]) or (name and nameSet[name]) then expiration = latest(expiration, self.GetAuraExpirationTime(aura)) end
				end
			end
			if continuation == nil then break end
		end
	end
	return warningExpiration(expiration, self:GetExpirationWarningSeconds(query.category))
end

function Reminder:GetEntryWarningExpiration(entry)
	if type(entry) ~= "table" or not self:CanReadAuraData() then return nil end
	local category = entry.warningCategory or (entry.selectionPoisonCategory and "POISONS") or "CLASS_BUFFS"
	local threshold = self:GetExpirationWarningSeconds(category)
	if entry.warningStates then return groupExpiration(entry.warningStates, nil, threshold) end
	if entry.warningCache then return groupExpiration(entry.warningCache.unitStates, entry.warningCache.unitStatus, threshold) end
	if entry.warningProvider then
		local state = self.groupMissingState
		if state and state.providerRef == entry.warningProvider then return groupExpiration(self.unitAuraStates or {}, state.unitStatus, threshold) end
		return nil
	end
	if entry.actionInventorySlot then
		if not entry.warningCategory then threshold = self:GetExpirationWarningSeconds("WEAPON_BUFFS") end
		return warningExpiration(entry.warningExpiration, threshold)
	end
	if entry.warningAuraQuery then return self:GetAuraQueryWarningExpiration(entry.warningAuraQuery) end
	if entry.countTotal or entry.targetCandidates or entry.actionCallback or entry.actionPetSlot or entry.sourceKind == "HEALTHSTONE" then return nil end
	if not entry.spellId then return nil end
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(entry.spellId)
	local name = info and info.name
	if issecretvalue and issecretvalue(name) then name = nil end
	return self:GetSnapshotWarningExpiration(self:GetPlayerAuraPresenceSnapshot(), {
		spellIds = entry.warningSpellIds or { entry.spellId }, names = name and { name } or nil, category = category,
	})
end

function Reminder:CancelIconPresentationTimer()
	if self.iconPresentationTimer then self.iconPresentationTimer:Cancel() end
	self.iconPresentationTimer = nil
end

local function formatTime(seconds)
	seconds = math.ceil(seconds)
	if seconds >= 3600 then return string.format("%d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60) end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function textStyleValue(prefix, field, default)
	local value = addon.db and addon.db[prefix .. field]
	if value == nil then return default end
	return value
end

local function textStyleNumber(prefix, field, default, minimum, maximum)
	local value = tonumber(textStyleValue(prefix, field, default)) or default
	return math.max(minimum, math.min(maximum, value))
end

local function textFontOptions()
	local options = {
		{ value = "DEFAULT", label = _G.DEFAULT },
		{ value = addon.functions.GetGlobalFontConfigKey(), label = addon.functions.GetGlobalFontConfigLabel() },
	}
	local media = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("font") or {}
	for _, option in ipairs(media) do options[#options + 1] = option end
	return options
end

local function textOutline(prefix)
	return addon.functions.GetFontFlagsForStyle(textStyleValue(prefix, "Outline", addon.functions.GetGlobalFontStyleConfigKey()), "OUTLINE")
end

local function ensureText(target, key, point)
	local overlay = target._eqolReminderTextOverlay
	if not overlay then
		overlay = CreateFrame("Frame", nil, target)
		overlay:SetAllPoints(target)
		overlay:EnableMouse(false)
		target._eqolReminderTextOverlay = overlay
	end
	-- The glow host and effect each add eight levels above the icon.
	overlay:SetFrameLevel((target:GetFrameLevel() or 0) + 20)
	local text = target[key]
	if not text then
		text = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetShadowOffset(1, -1)
		text:SetShadowColor(0, 0, 0, 1)
		target[key] = text
	end
	local prefix = key == "_eqolReminderTimeText" and "classBuffReminderTimeText" or "classBuffReminderItemCountText"
	local size = textStyleNumber(prefix, "Size", 0, 0, 64)
	if size == 0 then size = math.max(8, math.min(18, (target:GetWidth() or 40) * 0.28)) end
	local fallback = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local fontKey = textStyleValue(prefix, "Font", addon.functions.GetGlobalFontConfigKey())
	local font = fallback
	if fontKey ~= "DEFAULT" then font = addon.functions.ResolveFontFace(fontKey, addon.functions.GetGlobalDefaultFontFace()) end
	local outline = textOutline(prefix)
	if text._eqolFont ~= font or text._eqolSize ~= size or text._eqolOutline ~= outline then
		if text:SetFont(font, size, outline) == false then text:SetFont(fallback, size, outline) end
		text._eqolFont, text._eqolSize, text._eqolOutline = font, size, outline
	end
	addon.functions.ApplyFontStyleShadow(text, textStyleValue(prefix, "Outline", addon.functions.GetGlobalFontStyleConfigKey()), "OUTLINE")
	text:ClearAllPoints()
	text:SetPoint(point, target, point,
		(point == "BOTTOMRIGHT" and -2 or 0) + textStyleNumber(prefix, "OffsetX", 0, -100, 100),
		(point == "TOP" and -2 or 2) + textStyleNumber(prefix, "OffsetY", 0, -100, 100))
	local color = textStyleValue(prefix, "Color", {})
	text:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
	return text
end

function Reminder:UpdateReminderIconPresentation()
	self:CancelIconPresentationTimer()
	if not self.frame or not self.frame:IsShown() then return end
	local targets = self:GetGlowTargets() or {}
	local needsExpiration = enabled(M.time) or enabled(M.separate)
	for _, target in ipairs(targets) do
		local entry = target._eqolReminderInteractionEntry
		if self.editModeActive then
			target._eqolReminderProgressExpiration = nil
			target._eqolReminderWarningExpiration = needsExpiration and now() + 90 or nil
			if enabled(M.time) then ensureText(target, "_eqolReminderTimeText", "TOP"):SetText("1:30")
			elseif target._eqolReminderTimeText then target._eqolReminderTimeText:SetText("") end
			if enabled(M.count) then ensureText(target, "_eqolReminderItemText", "BOTTOMRIGHT"):SetText("20")
			elseif target._eqolReminderItemText then target._eqolReminderItemText:SetText("") end
		else
			target._eqolReminderWarningExpiration = needsExpiration and self:GetEntryWarningExpiration(entry) or nil
			target._eqolReminderProgressExpiration = entry and plainNumber(entry.progressExpiration) or nil
			if entry and entry.itemId and entry.icon and target == self.frame.iconHolder and (needsExpiration or enabled(M.count)) then
				self.frame.icon:SetTexture(entry.icon)
			end
			if enabled(M.count) and entry and entry.itemId and C_Item and C_Item.GetItemCount then
				local count = plainNumber(C_Item.GetItemCount(entry.itemId, false, false))
				ensureText(target, "_eqolReminderItemText", "BOTTOMRIGHT"):SetText(count and tostring(count) or "")
			elseif target._eqolReminderItemText then
				target._eqolReminderItemText:SetText("")
			end
		end
	end
	if not self.editModeActive then self:TickReminderIconPresentation() end
end

function Reminder:TickReminderIconPresentation()
	self.iconPresentationTimer = nil
	if not self.frame or not self.frame:IsShown() then return end
	local delay
	local expired = false
	for _, target in ipairs(self:GetGlowTargets() or {}) do
		local progress = target._eqolReminderProgressExpiration
		local expiration = progress or target._eqolReminderWarningExpiration
		local remaining = expiration and expiration - now()
		if remaining and remaining > 0 then
			if progress or enabled(M.time) then
				ensureText(target, "_eqolReminderTimeText", "TOP"):SetText(formatTime(remaining))
			elseif target._eqolReminderTimeText then
				target._eqolReminderTimeText:SetText("")
			end
			local nextDelay = (progress or enabled(M.time)) and math.min(1, remaining) or remaining
			if not delay or nextDelay < delay then delay = nextDelay end
		else
			if target._eqolReminderTimeText then target._eqolReminderTimeText:SetText("") end
			if expiration then
				target._eqolReminderWarningExpiration = nil
				target._eqolReminderProgressExpiration = nil
				expired = true
			end
		end
	end
	if expired then
		self:MarkAuraStatesDirty()
		self:InvalidateSelfProviderStatus()
		self:RequestUpdate(true)
		return
	end
	if delay and C_Timer and C_Timer.NewTimer then
		self.iconPresentationTimer = C_Timer.NewTimer(math.max(0.05, delay), function() Reminder:TickReminderIconPresentation() end)
	end
end

function Reminder:GetExpiringGlowColor()
	local color = addon.db and addon.db[M.color]
	if type(color) ~= "table" then color = M.defaultColor end
	return color.r or 1, color.g or 0.5, color.b or 0, color.a or 1
end

function Reminder:GetExpiringGlowStyle()
	return self.NormalizeGlowStyleForIconShape(addon.db and addon.db[M.style] or "PULSING", self:GetIconShape())
end

function Reminder:QueueGlowRefresh()
	if self.glowRefreshPending then return end
	self.glowRefreshPending = true
	RunNextFrame(function()
		self.glowRefreshPending = false
		if not Glow or not self.glowShown then return end
		for target, config in pairs(self.glowTargets or {}) do Glow.Refresh(target, GLOW_KEY, config.style, config) end
	end)
end

function Reminder:SetGlowShown(show)
	if not Glow then return end
	self.glowTargets = self.glowTargets or {}
	local nextTargets = {}
	local refresh = false
	if show then
		local style, inset, shape = self:GetGlowStyle(), self:GetGlowInset(), self:GetIconShape()
		local r, g, b, a = self:GetGlowColor()
		for _, target in ipairs(self:GetGlowTargets() or {}) do
			local targetStyle, cr, cg, cb, ca = style, r, g, b, a
			local showExpiring = target._eqolReminderWarningExpiration
			if self.editModeActive then showExpiring = self.editModeGlowPreviewExpiring == true end
			if enabled(M.separate) and showExpiring then
				targetStyle = self:GetExpiringGlowStyle()
				cr, cg, cb, ca = self:GetExpiringGlowColor()
			end
			local previous = self.glowTargets[target]
			local config = { style = targetStyle, inset = inset, shape = shape, color = { cr, cg, cb, ca }, hostFrameLevelOffset = 8, frameLevel = 8 }
			nextTargets[target] = config
			if not previous or previous.style ~= targetStyle or previous.inset ~= inset or previous.shape ~= shape
				or previous.color[1] ~= cr or previous.color[2] ~= cg or previous.color[3] ~= cb or previous.color[4] ~= ca then
				if previous then Glow.Stop(target, GLOW_KEY, true) end
				Glow.Start(target, GLOW_KEY, targetStyle, config)
				refresh = true
			end
		end
	end
	for target in pairs(self.glowTargets) do
		if not nextTargets[target] then Glow.Stop(target, GLOW_KEY, true) end
	end
	self.glowTargets = nextTargets
	self.glowShown = next(nextTargets) ~= nil
	if refresh then self:QueueGlowRefresh() end
end

function Reminder:SetGlowPreviewForSetting(key)
	if not self.editModeActive then return end
	if key == M.separate or key == M.style or key == M.color then
		self.editModeGlowPreviewExpiring = enabled(M.separate)
	elseif key == "classBuffReminderGlow" or key == "classBuffReminderGlowStyle" or key == "classBuffReminderGlowInset"
		or key == "classBuffReminderGlowColor" or key == "classBuffReminderGlowUseClassColor" then
		self.editModeGlowPreviewExpiring = nil
	end
end

function Reminder:SetIconPresentationSetting(key, value)
	if not addon.db then return end
	addon.db[key] = value
	self:SetGlowPreviewForSetting(key)
	self:StopAllGlowTargetsImmediate()
	self:RequestUpdate(true)
end

local function styleOptions()
	local options = {}
	for _, option in ipairs(Reminder.GetGlowStyleOptions(Reminder:GetIconShape())) do
		options[#options + 1] = { value = option.value, label = L[option.labelKey] or option.fallback }
	end
	return options
end

function Reminder:RegisterIconPresentationSettings(cat, section)
	for _, control in ipairs({
		{ key = M.separate, label = "ClassBuffReminderExpiringGlow" },
		{ key = M.time, label = "ClassBuffReminderShowTimeLeft" },
		{ key = M.count, label = "ClassBuffReminderShowItemCount" },
	}) do
		local key = control.key
		addon.functions.SettingsCreateCheckbox(cat, {
			var = key, text = L[control.label], desc = L[control.label .. "Desc"], default = defaultEnabled(key),
			get = function() return enabled(key) end,
			func = function(value) self:SetIconPresentationSetting(key, value == true) end,
			parentSection = section, newTagID = control.label,
		})
	end
	addon.functions.SettingsCreateDropdown(cat, {
		var = M.style, text = L["ClassBuffReminderExpiringGlowStyle"], default = "PULSING",
		get = function() return self:GetExpiringGlowStyle() end,
		func = function(value) self:SetIconPresentationSetting(M.style, self.NormalizeGlowStyleForIconShape(value, self:GetIconShape())) end,
		optionfunc = styleOptions, isEnabled = function() return enabled(M.separate) end,
		parentSection = section, newTagID = "ClassBuffReminderExpiringGlowStyle",
	})
	addon.functions.SettingsCreateColorPicker(cat, {
		var = M.color, text = L["ClassBuffReminderExpiringGlowColor"], default = M.defaultColor, hasOpacity = true,
		getColor = function() return self:GetExpiringGlowColor() end,
		setColor = function(_, r, g, b, a) self:SetIconPresentationSetting(M.color, { r = r, g = g, b = b, a = a or 1 }) end,
		isEnabled = function() return enabled(M.separate) end,
		parentSection = section, newTagID = "ClassBuffReminderExpiringGlowColor",
	})
end

local function appendTextStyleSettings(settings, SettingType, prefix, label, enabledKey)
	local parent = "iconPresentation"
	local function append(data, field, default)
		data.parentId, data.navigationField, data.default = parent, prefix .. field, default
		data.isEnabled = function() return enabled(enabledKey) end
		data.get = data.get or function() return textStyleValue(prefix, field, default) end
		data.set = function(_, value) Reminder:SetIconPresentationSetting(prefix .. field, value) end
		settings[#settings + 1] = data
	end
	settings[#settings + 1] = { name = L[label], kind = SettingType.Divider, parentId = parent }
	append({ name = L["Font"], kind = SettingType.Dropdown, values = textFontOptions }, "Font", "__EQOL_GLOBAL_FONT__")
	append({ name = _G.FONT_SIZE, kind = SettingType.Slider, minValue = 0, maxValue = 64, valueStep = 1,
		get = function() return textStyleNumber(prefix, "Size", 0, 0, 64) end,
		formatter = function(value) return value == 0 and _G.DEFAULT or tostring(value) end }, "Size", 0)
	append({ name = L["Font outline"], kind = SettingType.Dropdown,
		values = function() return addon.functions.GetFontStyleOptionList(true) end }, "Outline", "__EQOL_GLOBAL_FONT_STYLE__")
	append({ name = L["Color"], kind = SettingType.Color, hasOpacity = true }, "Color", { r = 1, g = 1, b = 1, a = 1 })
	for _, axis in ipairs({ "X", "Y" }) do
		local field = "Offset" .. axis
		append({ name = L["Offset " .. axis], kind = SettingType.Slider, minValue = -100, maxValue = 100, valueStep = 1,
			get = function() return textStyleNumber(prefix, field, 0, -100, 100) end }, field, 0)
	end
end

function Reminder:BuildIconPresentationEditModeSettings(SettingType)
	local settings = { { name = L["ClassBuffReminderIconOverlays"], kind = SettingType.Collapsible, id = "iconPresentation", defaultCollapsed = true } }
	for _, control in ipairs({
		{ key = M.time, label = "ClassBuffReminderShowTimeLeft", parent = "iconPresentation" },
		{ key = M.count, label = "ClassBuffReminderShowItemCount", parent = "iconPresentation" },
	}) do
		local key = control.key
		settings[#settings + 1] = {
			name = L[control.label], tooltip = L[control.label .. "Desc"], kind = SettingType.Checkbox, parentId = control.parent,
			default = defaultEnabled(key), get = function() return enabled(key) end,
			set = function(_, value) self:SetIconPresentationSetting(key, value == true) end,
		}
	end
	appendTextStyleSettings(settings, SettingType, "classBuffReminderTimeText", "ClassBuffReminderShowTimeLeft", M.time)
	appendTextStyleSettings(settings, SettingType, "classBuffReminderItemCountText", "ClassBuffReminderShowItemCount", M.count)
	settings[#settings + 1] = { name = L["Glow"], kind = SettingType.Divider, parentId = "iconPresentation" }
	settings[#settings + 1] = {
		name = L["ClassBuffReminderExpiringGlow"], tooltip = L["ClassBuffReminderExpiringGlowDesc"], kind = SettingType.Checkbox, parentId = "iconPresentation",
		default = defaultEnabled(M.separate), get = function() return enabled(M.separate) end,
		set = function(_, value) self:SetIconPresentationSetting(M.separate, value == true) end,
	}
	settings[#settings + 1] = {
		name = L["ClassBuffReminderExpiringGlowStyle"], kind = SettingType.Dropdown, parentId = "iconPresentation", default = "PULSING",
		get = function() return self:GetExpiringGlowStyle() end,
		set = function(_, value) self:SetIconPresentationSetting(M.style, self.NormalizeGlowStyleForIconShape(value, self:GetIconShape())) end,
		values = styleOptions, isEnabled = function() return enabled(M.separate) end,
	}
	settings[#settings + 1] = {
		name = L["ClassBuffReminderExpiringGlowColor"], kind = SettingType.Color, parentId = "iconPresentation", default = M.defaultColor,
		get = function() local r, g, b, a = self:GetExpiringGlowColor(); return { r = r, g = g, b = b, a = a } end,
		set = function(_, value) self:SetIconPresentationSetting(M.color, value) end,
		isEnabled = function() return enabled(M.separate) end,
	}
	return settings
end
