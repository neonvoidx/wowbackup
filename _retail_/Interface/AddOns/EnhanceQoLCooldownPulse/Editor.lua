local addon = _G.EnhanceQoL
local P = addon.CooldownPulse
local L = P.L

function P:MediaOptions(kind)
	local values = { { text = _G.DEFAULT, value = "DEFAULT" } }
	for _, name in ipairs(self.media and self.media:List(kind) or {}) do values[#values + 1] = { text = name, value = name } end
	return values
end

function P:Entry(id)
	local cat = self:Group(id)
	return cat and cat.spells[self.selectedSpells[id]]
end

function P:RefreshEditor(id)
	if self.editorRefreshPending then return end
	self.editorRefreshPending = true
	C_Timer.After(0, function()
		P.editorRefreshPending = nil
		if not P:Group(id) then return end
		local frame = P.frames[id]
		local standalone = addon.EditModeLib:IsStandaloneSettingsDialogShown(frame)
		P:RegisterGroup(id, true)
		if standalone then P:OpenSettings(id, P.editSpell) end
		if P.RefreshOverview then P:RefreshOverview() end
	end)
end

function P:Changed(id, tracking)
	if self.resetting then self.resetTracking = self.resetTracking or tracking; return end
	if tracking then self.states[id] = nil; self:Refresh() end
	if self.RefreshOverview then self:RefreshOverview() end
	local frame = self.frames[id]
	if frame and (frame.editing or addon.EditModeLib:IsStandaloneSettingsDialogShown(frame)) then self:Preview(id) end
end

function P:BuildSettings(id, spellID)
	local entry = spellID ~= nil
	local T = addon.EditModeLib.SettingType
	local settings = {}
	local row
	local function group(key, name)
		settings[#settings + 1] = { kind = T.Collapsible, id = key, name = name, defaultCollapsed = false }
		if entry and P.styleSections[key] then
			row(key, "override_" .. key, L["CooldownPulseOverride"], T.Checkbox, { set = function(_, value)
				P:SetOverride(id, spellID, key, value); P:Changed(id); P:RefreshEditor(id)
			end })
		end
	end
	row = function(tab, field, name, kind, options)
		local data = options or {}
		data.parentId, data.name, data.kind, data.navigationField = tab, name, kind, field
		data.get = data.get or function()
			local source
			if entry then source = P:Group(id).spells[spellID] else source = P:Group(id) end
			local value = source and source[field]
			if kind == T.Color then value = value or P.entryDefaults[field] or P.defaults[field]; return { r = value[1], g = value[2], b = value[3], a = value[4] } end
			if value == nil then value = entry and P.entryDefaults[field] or P.defaults[field] end
			return value
		end
		data.set = data.set or function(_, value)
			local source
			if entry then source = P:Group(id).spells[spellID] else source = P:Group(id) end
			if not source then return end
			if kind == T.Color then value = P.Color(value, entry and P.entryDefaults[field] or P.defaults[field]) end
			source[field] = value
			P:Changed(id, field == "useAdvancedTracking")
		end
		if entry and P.styleSections[tab] and not field:match("^override_") then
			data.isEnabled = function() local value = P:Group(id).spells[spellID]; return value and value["override_" .. tab] == true end
		end
		local default
		if entry then default = P.entryDefaults[field] else default = P.defaults[field] end
		if default ~= nil then addon.EditModeNavigationDefaults.Set(data, default) else data.navigationResetExcluded = true end
		settings[#settings + 1] = data
		return data
	end
	local function slider(tab, field, name, low, high, step)
		return row(tab, field, name, T.Slider, { minValue = low, maxValue = high, valueStep = step, allowInput = true })
	end
	if not entry then
	group("general", L["General"])
	row("general", "name", _G.NAME, T.Input, { maxChars = 96, set = function(_, value)
		if value ~= "" then P:Group(id).name = value; P:Changed(id) end
	end })
	row("general", "enabled", _G.ENABLE, T.Checkbox, {
		get = function() return P:Enabled(id) end,
		set = function(_, value) P:Group(id).enabled = value; P:Changed(id, true) end,
	})
	row("general", "useAdvancedTracking", L["UseAdvancedTracking"], T.Checkbox, { tooltip = L["advancedTrackingInfo"] })
	for _, slot in ipairs({ 13, 14 }) do
		local sid = -slot
		row("general", "trinket" .. slot, L[slot == 13 and "CooldownPanelSlotTrinket1" or "CooldownPanelSlotTrinket2"], T.Checkbox, {
			get = function()
				local cat = P:Group(id)
				if not cat.useAdvancedTracking then return not cat.ignoredSpells[sid] end
				return cat.spells[sid] ~= nil and not cat.ignoredSpells[sid]
			end,
			set = function(_, value)
				local cat = P:Group(id)
				if value then
					cat.spells[sid] = cat.spells[sid] or P.Copy(P.entryDefaults)
					cat.ignoredSpells[sid] = nil
				else
					cat.spells[sid] = nil
					if not cat.useAdvancedTracking then cat.ignoredSpells[sid] = true end
				end
				P:Changed(id, true); P:RefreshEditor(id)
			end,
		})
	end
	group("position", L["Position"])
	settings[#settings].navigationReset = function()
		local cat = P:Group(id)
		cat.anchor = { point = "CENTER", x = 0, y = 0 }; cat.strata = P.defaults.strata
		P:ApplyPosition(id)
		P:Changed(id)
	end
	for _, axis in ipairs({ "x", "y" }) do
		row("position", "anchor" .. axis, L[axis == "x" and "Offset X" or "Offset Y"], T.Slider, {
			minValue = -2000, maxValue = 2000, valueStep = 1, allowInput = true,
			get = function() return P:Group(id).anchor[axis] end,
			set = function(_, value)
				local anchor = P:Group(id).anchor; anchor[axis] = value
				P:ApplyPosition(id)
			end,
		})
	end
	row("position", "strata", L["Frame strata"], T.Dropdown, { values = {
		{ text = "LOW", value = "LOW" }, { text = "MEDIUM", value = "MEDIUM" }, { text = "HIGH", value = "HIGH" }, { text = "DIALOG", value = "DIALOG" },
	} })
	end
	group("appearance", L["CooldownPulseAppearance"])
	slider("appearance", "iconSize", HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE, 20, 200, 1)
	slider("appearance", "aspectRatio", L["CooldownPulseAspectRatio"], 0.5, 2, 0.05)
	row("appearance", "iconColor", L["Color"], T.Color, { hasOpacity = true })
	row("appearance", "desaturate", L["Desaturate icon"], T.Checkbox)
	group("animation", L["CooldownPulseAnimation"])
	slider("animation", "fadeInTime", L["Fade In"], 0, 3, 0.05)
	slider("animation", "holdTime", L["Hold Time"], 0, 5, 0.05)
	slider("animation", "fadeOutTime", L["Fade Out"], 0, 3, 0.05)
	slider("animation", "animScale", L["Scale"], 0.5, 3, 0.05)
	slider("animation", "maxAlpha", L["Alpha"], 0, 1, 0.05)
	group("text", L["Text"])
	row("text", "showName", L["ShowCooldownName"], T.Checkbox)
	row("text", "customTextEnabled", L["Show custom text"], T.Checkbox)
	row("text", "customText", L["Text"], T.Input, { maxChars = 128 })
	row("text", "font", L["Font"], T.Dropdown, { values = self:MediaOptions("font"), height = 240 })
	slider("text", "fontSize", _G.FONT_SIZE, 6, 64, 1)
	row("text", "outline", L["Font outline"], T.Dropdown, { values = { { text = _G.NONE, value = "" }, { text = L["Outline"], value = "OUTLINE" }, { text = L["Thick outline"], value = "THICKOUTLINE" } } })
	row("text", "textColor", L["Font color"], T.Color, { hasOpacity = true })
	slider("text", "textX", L["Offset X"], -300, 300, 1)
	slider("text", "textY", L["Offset Y"], -300, 300, 1)
	group("border", L["Border"])
	row("border", "borderEnabled", L["Border"], T.Checkbox)
	row("border", "border", L["Border texture"], T.Dropdown, { values = self:MediaOptions("border"), height = 240 })
	slider("border", "borderSize", L["Border size"], 1, 50, 1)
	slider("border", "borderOffset", L["Border offset"], -50, 50, 1)
	row("border", "borderColor", L["Border color"], T.Color, { hasOpacity = true })
	group("glow", L["Glow style"])
	row("glow", "glowStyle", L["Glow style"], T.Dropdown, { values = {
		{ text = _G.NONE, value = "NONE" }, { text = L["Blizzard"], value = "BLIZZARD" },
		{ text = L["Marching ants"], value = "MARCHING_ANTS" }, { text = L["Flash"], value = "FLASH" },
		{ text = L["Pixel"], value = "PIXEL" }, { text = L["Pulsing"], value = "PULSING" }, { text = L["Solid"], value = "SOLID" },
	} })
	row("glow", "glowColor", L["Glow color"], T.Color, { hasOpacity = true })
	slider("glow", "glowSpeed", L["CooldownPanelPixelGlowSpeed"], 0.05, 2, 0.05)
	slider("glow", "glowThickness", L["CooldownPanelPixelGlowThickness"], 1, 8, 1)
	slider("glow", "glowLines", L["CooldownPanelPixelGlowLines"], 1, 16, 1)
	group("sound", _G.SOUND)
	local function customSoundEnabled()
		local cat = P:Group(id)
		local source = cat and (entry and cat.spells[spellID] or cat)
		return source and source.soundMode == "CUSTOM" or false
	end
	row("sound", "soundMode", _G.SOUND, T.Dropdown, { values = {
		{ text = L["CooldownPulseInherit"], value = "INHERIT" }, { text = _G.NONE, value = "OFF" }, { text = L["CooldownPulseCustom"], value = "CUSTOM" },
	} })
	row("sound", "soundKey", _G.SOUND, T.SoundDropdown, {
		values = self:MediaOptions("sound"), height = 240,
		isEnabled = customSoundEnabled,
		previewSoundFunc = function(value)
			local cat = P:Group(id)
			local source = entry and cat.spells[spellID] or cat
			P:PlaySoundConfig({ key = value, channel = source.soundChannel })
		end,
	})
	local channels = {}
	for _, channel in ipairs({ "Master", "SFX", "Music", "Ambience", "Dialog" }) do channels[#channels + 1] = { text = channel, value = channel } end
	row("sound", "soundChannel", L["CooldownPulseSoundChannel"], T.Dropdown, { values = channels, isEnabled = customSoundEnabled })
	if not entry then
		group("globalSound", L["CooldownPulseGlobalSound"])
		for _, field in ipairs({ "enabled", "key", "channel" }) do
			local data = row("globalSound", "global_" .. field, field == "enabled" and _G.ENABLE or field == "key" and _G.SOUND or L["CooldownPulseSoundChannel"], field == "enabled" and T.Checkbox or field == "key" and T.SoundDropdown or T.Dropdown, {
				values = field == "key" and self:MediaOptions("sound") or channels,
				get = function() return P:DB().globalSound[field] end,
				set = function(_, value) P:DB().globalSound[field] = value end,
			})
			if field == "key" then
				data.height = 240
				data.previewSoundFunc = function(value) P:PlaySoundConfig({ key = value, channel = P:DB().globalSound.channel }) end
			end
			data.navigationResetExcluded = nil
			addon.EditModeNavigationDefaults.Set(data, P.soundDefaults[field])
		end
	end
	return settings
end

function P:IDsText(values)
	local ids = {}
	for id in pairs(values) do ids[#ids + 1] = id end
	table.sort(ids)
	for index, id in ipairs(ids) do ids[index] = tostring(id) end
	return table.concat(ids, ", ")
end

function P:Navigation(id, spellID)
	local groups = spellID and { "appearance", "animation", "text", "border", "glow", "sound" } or { "general", "position", "appearance", "animation", "text", "border", "glow", "sound", "globalSound" }
	return {
		scopeKey = "cooldownPulse:" .. id .. ":" .. tostring(spellID or "group"), direct = true, hideCategoryTitle = spellID ~= nil,
		categories = { { id = "pulse", name = L["CooldownPulse"], groups = groups } },
		reset = function(_, applyDefaults)
			P.resetting, P.resetTracking = true, false
			local ok, err = pcall(applyDefaults)
			P.resetting = false
			P:Changed(id, P.resetTracking)
			if not ok then error(err) end
		end,
	}
end

function P:Buttons(id, spellID)
	local test = { text = L["Test"], click = function() P:TestGroup(id, spellID) end }
	if spellID then return { test } end
	return {
		test,
		{ text = L["CooldownPanelExportGroup"], click = function() P:ShowTransfer(id, false) end },
		{ text = _G.DELETE, click = function()
			StaticPopup_Show("EQOL_PULSE_DELETE", P:Group(id).name, nil, id)
		end },
	}
end

function P:ApplyPosition(id)
	local frame, group = self:EnsureFrame(id), self:Group(id)
	frame:ClearAllPoints()
	frame:SetPoint(group.anchor.point, UIParent, group.anchor.point, group.anchor.x, group.anchor.y)
end

function P:RegisterGroup(id)
	local frame = self:EnsureFrame(id)
	if frame.registered then return end
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() if frame.editing and not InCombatLockdown() then frame:StartMoving() end end)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		local x, y = frame:GetCenter()
		local px, py = UIParent:GetCenter()
		local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
		P:Group(id).anchor = { point = "CENTER", x = x * scale - px, y = y * scale - py }
		P:ApplyPosition(id); P:RefreshEditor(id)
	end)
	frame:EnableMouse(false)
	self:ApplyPosition(id)
	frame.registered = true
end

function P:FinishEditing()
	local id = self.editGroup
	self.editGroup, self.editSpell = nil, nil
	local frame = id and self.frames[id]
	if frame then
		frame:StopMovingOrSizing(); frame.editing = false; frame:EnableMouse(false); self:Stop(frame)
	end
end

function P:OpenSettings(id, spellID)
	if InCombatLockdown() or not self:Group(id) then return end
	if self.editGroup and self.editGroup ~= id then self:FinishEditing() end
	if spellID and not self:Group(id).spells[spellID] then self:Group(id).spells[spellID] = self.Copy(self.entryDefaults) end
	self:RegisterGroup(id)
	local frame = self:EnsureFrame(id)
	self.selectedSpells[id] = spellID
	self.editGroup, self.editSpell = id, spellID
	local title = spellID and (self:SpellInfo(spellID) or tostring(spellID)) or self:Group(id).name
	local dialog = addon.EditModeLib:ShowStandaloneSettingsDialog(frame, {
		title = spellID and title or L["CooldownPulse"] .. ": " .. title, settings = self:BuildSettings(id, spellID),
		settingsNavigation = self:Navigation(id, spellID), buttons = self:Buttons(id, spellID), showReset = false,
		onHide = function() if P.editGroup == id then P:FinishEditing() end end,
	})
	if dialog then
		self.editGroup, self.editSpell = id, spellID
		frame.editing = true; frame:EnableMouse(true)
		self:Preview(id)
		if self.overview and self.overview:IsShown() then
			dialog:ClearAllPoints(); dialog:SetPoint("TOPLEFT", self.overview, "TOPRIGHT", 58, -8)
		end
	end
	return dialog
end

StaticPopupDialogs.EQOL_PULSE_DELETE = {
	text = L["CooldownPulseDeletePrompt"], button1 = _G.DELETE, button2 = _G.CANCEL, timeout = 0, whileDead = true, hideOnEscape = true,
	OnAccept = function(_, id) P:DeleteGroup(id); P:RefreshOverview() end,
}

function P:ShowTextDialog(title, text, accept)
	local frame = self.textDialog
	if not frame then
		frame = CreateFrame("Frame", "EQOLCooldownPulseTextDialog", UIParent, "EQOLFeatureEditorWindowTemplate")
		self.textDialog = frame
		frame:SetSize(850, 500); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
		frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		frame:SetPortraitTextureRaw("Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga")
		frame.SearchBox:Hide(); frame.SettingsDropdown:Hide(); frame.LayoutDropdown:Hide(); frame.CooldownScroll:Hide()
		frame.input = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
		frame.input:SetPoint("TOPLEFT", 24, -70); frame.input:SetPoint("BOTTOMRIGHT", -38, 44)
		frame.input.EditBox:SetMaxLetters(0)
		frame.input.EditBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		frame.accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.accept:SetSize(160, 22); frame.accept:SetPoint("BOTTOMRIGHT", -20, 10)
		frame.accept:SetText(_G.IMPORT)
		frame.accept:SetScript("OnClick", function() if frame.onAccept then frame.onAccept(frame.input.EditBox:GetText(), frame) end end)
		tinsert(UISpecialFrames, "EQOLCooldownPulseTextDialog")
	end
	frame.TitleContainer.TitleText:SetText(title)
	frame.onAccept = accept; frame.accept:SetShown(accept ~= nil)
	frame:Show(); frame.input.EditBox:SetText(text or ""); frame.input.EditBox:HighlightText(); frame.input.EditBox:SetFocus()
	return frame
end

function P:ShowTransfer(id, importing)
	return self:ShowTextDialog(importing and L["CooldownPulseImport"] or L["CooldownPanelExportGroup"], importing and "" or self:Export(id), importing and function(text, frame)
		local newID = P:Import(text)
		if newID then frame:Hide(); P:OpenEditor(newID) else frame.TitleContainer.TitleText:SetText(L["CooldownPulseInvalidImport"]) end
	end or nil)
end
