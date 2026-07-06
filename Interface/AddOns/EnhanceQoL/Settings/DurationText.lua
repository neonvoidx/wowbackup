local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local category = addon.SettingsLayout.rootUI
local DurationText = addon.DurationText
if not (category and DurationText) then return end

local function invalidate()
	if DurationText and DurationText.Invalidate then DurationText:Invalidate() end
end

local function setDurationTextValue(key, value)
	DurationText:InitDB()
	local oldValue = DurationText:GetProfileValue(DurationText:GetEditProfileKey(), key)
	DurationText:SetProfileValue(DurationText:GetEditProfileKey(), key, value)
	if oldValue ~= value then addon.variables.requireReload = true end
	invalidate()
end

local function getDurationTextValue(key)
	DurationText:InitDB()
	return DurationText:GetProfileValue(DurationText:GetEditProfileKey(), key)
end

local function setDurationTextBreakpointValue(index, field, value)
	DurationText:InitDB()
	local changed = DurationText:SetProfileColorBreakpointValue(DurationText:GetEditProfileKey(), index, field, value)
	if changed then addon.variables.requireReload = true end
	invalidate()
end

local function getDurationTextBreakpoint(index)
	DurationText:InitDB()
	return DurationText:GetProfileColorBreakpoint(DurationText:GetEditProfileKey(), index) or {}
end

local function getDurationTextBreakpointColor(index)
	local breakpoint = getDurationTextBreakpoint(index)
	local color = breakpoint.color or DurationText:GetDefaultTextColor()
	return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

local function setDurationTextBreakpointColor(index, r, g, b, a)
	setDurationTextBreakpointValue(index, "color", { r = r, g = g, b = b, a = a })
end

local function getDurationTextBreakpointDefaultColor()
	local color = DurationText:GetDefaultTextColor()
	return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

local function getProfileDropdownData()
	DurationText:InitDB()
	return DurationText:GetProfileDropdownData()
end

local function getDeleteProfileDropdownData()
	DurationText:InitDB()
	local list, order = {}, {}
	for _, option in ipairs(DurationText:GetProfileOptions()) do
		if not DurationText:IsProfileProtected(option.value) then
			list[option.value] = option.label
			order[#order + 1] = option.value
		end
	end
	return list, order
end

local function notifyDurationTextSettings()
	if not (Settings and Settings.NotifyUpdate) then return end
	Settings.NotifyUpdate("EQOL_durationTextEditProfile")
	Settings.NotifyUpdate("EQOL_durationTextProfileCopy")
	Settings.NotifyUpdate("EQOL_durationTextProfileDelete")
	Settings.NotifyUpdate("EQOL_durationText")
end

local function refreshConfigCenterDurationTextSettings(rebuild)
	local frame = addon.ConfigCenterFrame
	local state = frame and frame._LibSettingsDesignerState
	if not (frame and frame.IsShown and frame:IsShown() and state) then return end
	if rebuild and state.RenderContent then
		state:RenderContent()
		return
	end
	local designer = addon.LibSettingsDesigner and addon.LibSettingsDesigner.UI
	if designer and designer.RefreshVisibleRows then designer.RefreshVisibleRows(state) end
end

local function refreshDurationTextSettings(rebuild)
	invalidate()
	if DurationText and DurationText.RefreshConsumers then DurationText:RefreshConsumers() end
	notifyDurationTextSettings()
	refreshConfigCenterDurationTextSettings(rebuild)
	local timer = _G.C_Timer
	if timer and timer.After then
		timer.After(0, function()
			notifyDurationTextSettings()
			refreshConfigCenterDurationTextSettings(rebuild)
		end)
	end
end

local function printDurationTextProfileError(reason)
	local text = reason == "EXISTS" and (L["durationTextProfileErrorExists"] or "A duration text profile with that name already exists.")
		or reason == "INVALID_NAME" and (L["durationTextProfileErrorInvalidName"] or "Enter a profile name.")
		or reason == "LAST_PROFILE" and (L["durationTextProfileErrorLastProfile"] or "The last duration text profile cannot be deleted.")
		or reason == "PROTECTED_PROFILE" and (L["durationTextProfileErrorProtected"] or "Built-in duration text profiles cannot be deleted.")
		or (L["durationTextProfileErrorGeneric"] or "Duration text profile action failed.")
	print("|cff00ff98Enhance QoL|r: " .. text)
end

local function formatUsageSummary(usages)
	if type(usages) ~= "table" or (usages.count or 0) <= 0 then return L["durationTextProfileDeleteNoUsage"] or "It is not currently used by any configured module." end
	local lines = {
		(L["durationTextProfileDeleteUsageHeader"] or "Used by %d setting(s):"):format(usages.count or 0),
	}
	local order = usages.order
	local byLabel = usages.byLabel
	if type(order) == "table" and type(byLabel) == "table" then
		for i = 1, #order do
			local label = order[i]
			local count = tonumber(byLabel[label]) or 0
			local text = L[label] or label
			lines[#lines + 1] = count > 1 and ("- " .. tostring(text) .. " (" .. count .. ")") or ("- " .. tostring(text))
		end
	else
		for i = 1, #usages do
			lines[#lines + 1] = "- " .. tostring(usages[i])
		end
	end
	return table.concat(lines, "\n")
end

local function showCreateProfileDialog(sourceProfileKey)
	StaticPopupDialogs["EQOL_DURATION_TEXT_PROFILE_CREATE"] = StaticPopupDialogs["EQOL_DURATION_TEXT_PROFILE_CREATE"]
		or {
			text = L["durationTextProfileCreatePrompt"] or "Enter a name for the new duration text profile.",
			hasEditBox = true,
			button1 = OKAY,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if editBox then
					editBox:SetText("")
					editBox:SetFocus()
					editBox:HighlightText()
				end
			end,
			EditBoxOnEnterPressed = function(editBox)
				local parent = editBox:GetParent()
				if parent and parent.button1 then parent.button1:Click() end
			end,
			OnAccept = function(self)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				local ok, result = DurationText:CreateProfile(editBox and editBox:GetText() or "", self.data)
				if not ok then
					printDurationTextProfileError(result)
					return
				end
				DurationText:SetEditProfileKey(result)
				refreshDurationTextSettings(true)
			end,
		}
	StaticPopup_Show("EQOL_DURATION_TEXT_PROFILE_CREATE", nil, nil, sourceProfileKey)
end

local function showDeleteProfileDialog(profileKey)
	DurationText:InitDB()
	profileKey = DurationText:GetProfileKey(profileKey)
	local replacementKey = DurationText:GetReplacementProfileKey(profileKey)
	if not replacementKey then
		printDurationTextProfileError("LAST_PROFILE")
		return
	end
	local usage = DurationText:GetProfileUsage(profileKey)
	local profileLabel = DurationText:GetProfileLabel(profileKey)
	local replacementLabel = DurationText:GetProfileLabel(replacementKey)
	StaticPopupDialogs["EQOL_DURATION_TEXT_PROFILE_DELETE"] = StaticPopupDialogs["EQOL_DURATION_TEXT_PROFILE_DELETE"]
		or {
			text = "",
			button1 = DELETE,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnAccept = function(self)
				local data = self.data
				local ok, reason = DurationText:DeleteProfile(data and data.profileKey, data and data.replacementKey)
				if not ok then
					printDurationTextProfileError(reason)
					return
				end
				refreshDurationTextSettings(true)
			end,
		}
	StaticPopupDialogs["EQOL_DURATION_TEXT_PROFILE_DELETE"].text = (L["durationTextProfileDeleteConfirm"] or 'Delete duration text profile "%s"? References will be moved to "%s".'):format(profileLabel, replacementLabel)
		.. "\n\n"
		.. formatUsageSummary(usage)
	StaticPopup_Show("EQOL_DURATION_TEXT_PROFILE_DELETE", nil, nil, { profileKey = profileKey, replacementKey = replacementKey })
end

local expandable = addon.functions.SettingsCreateExpandableSection(category, {
	name = L["durationTextTitle"],
	description = L["configCenterPageCardDescDurationText"],
	expanded = false,
	colorizeTitle = false,
	newTagID = "DurationText",
	configPageKey = "DurationText",
	iconKey = "castbar",
	modernCategory = "suites",
	modernOnly = true,
})
addon.SettingsLayout.durationTextSection = expandable

addon.functions.SettingsCreateHeadline(category, L["durationTextProfile"], { parentSection = expandable, order = 10 })

addon.functions.SettingsCreateDropdown(category, {
	var = "durationTextEditProfile",
	text = L["durationTextProfile"],
	desc = L["durationTextProfileDesc"],
	listFunc = getProfileDropdownData,
	order = 10,
	default = DurationText.defaultProfileKey,
	storage = false,
	get = function() return DurationText:GetEditProfileKey() end,
	func = function(value)
		DurationText:SetEditProfileKey(value)
		refreshDurationTextSettings()
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(category, {
	var = "durationTextProfileCreate",
	text = L["durationTextProfileCreate"],
	desc = L["durationTextProfileCreateDesc"],
	buttonText = ADD,
	order = 11,
	func = function() showCreateProfileDialog(nil) end,
	parentSection = expandable,
})

addon.functions.SettingsCreateDropdown(category, {
	var = "durationTextProfileCopy",
	text = L["durationTextProfileCopy"],
	desc = L["durationTextProfileCopyDesc"],
	listFunc = getProfileDropdownData,
	order = 12,
	default = "",
	storage = false,
	get = function() return "" end,
	func = function(value)
		if value and value ~= "" then showCreateProfileDialog(value) end
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateDropdown(category, {
	var = "durationTextProfileDelete",
	text = L["durationTextProfileDelete"],
	desc = L["durationTextProfileDeleteDesc"],
	listFunc = getDeleteProfileDropdownData,
	order = 13,
	default = "",
	storage = false,
	get = function() return "" end,
	func = function(value)
		if value and value ~= "" then showDeleteProfileDialog(value) end
	end,
	parentSection = expandable,
})

addon.functions.SettingsCreateText(category, L["durationTextIntro"], { parentSection = expandable, order = 20 })

addon.functions.SettingsCreateHeadline(category, L["durationTextFormattingHeader"], { parentSection = expandable, order = 20 })

addon.functions.SettingsCreateSlider(category, {
	var = "durationText",
	subvar = "millisecondsThreshold",
	text = L["durationTextMillisecondsThreshold"],
	desc = L["durationTextMillisecondsThresholdDesc"],
	min = 0,
	max = 60,
	step = 0.5,
	default = DurationText.defaults.millisecondsThreshold,
	get = function() return getDurationTextValue("millisecondsThreshold") end,
	func = function(value) setDurationTextValue("millisecondsThreshold", value) end,
	order = 20,
	parentSection = expandable,
})

addon.functions.SettingsCreateHeadline(category, L["durationTextColorBreakpointHeader"], { parentSection = expandable, order = 30 })

local breakpointCountElement = addon.functions.SettingsCreateSlider(category, {
	var = "durationText",
	subvar = "colorBreakpointCount",
	text = L["durationTextColorBreakpointCount"],
	desc = L["durationTextColorBreakpointCountDesc"],
	min = 0,
	max = DurationText:GetMaxColorBreakpoints(),
	step = 1,
	default = DurationText.defaults.colorBreakpointCount,
	get = function() return getDurationTextValue("colorBreakpointCount") end,
	func = function(value)
		value = math.floor((tonumber(value) or 0) + 0.5)
		setDurationTextValue("colorBreakpointCount", value)
		refreshDurationTextSettings(true)
	end,
	order = 30,
	parentSection = expandable,
})

for i = 1, DurationText:GetMaxColorBreakpoints() do
	addon.functions.SettingsCreateSlider(category, {
		var = "durationTextColorBreakpoint" .. i .. "Seconds",
		text = (L["durationTextColorBreakpointSeconds"] or "Breakpoint %d below seconds"):format(i),
		desc = L["durationTextColorBreakpointSecondsDesc"],
		min = 1,
		max = 3600,
		step = 1,
		default = i * 5,
		get = function()
			local breakpoint = getDurationTextBreakpoint(i)
			return breakpoint.seconds or i * 5
		end,
		func = function(value)
			setDurationTextBreakpointValue(i, "seconds", value)
			refreshDurationTextSettings()
		end,
		order = 30 + i * 2 - 1,
		element = breakpointCountElement,
		parentCheck = function() return (tonumber(getDurationTextValue("colorBreakpointCount")) or 0) >= i end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateColorPicker(category, {
		var = "durationTextColorBreakpoint" .. i .. "Color",
		text = (L["durationTextColorBreakpointColor"] or "Breakpoint %d color"):format(i),
		desc = L["durationTextColorBreakpointColorDesc"],
		getColor = function() return getDurationTextBreakpointColor(i) end,
		setColor = function(_, r, g, b, a)
			setDurationTextBreakpointColor(i, r, g, b, a)
			refreshDurationTextSettings()
		end,
		getDefaultColor = getDurationTextBreakpointDefaultColor,
		order = 30 + i * 2,
		element = breakpointCountElement,
		parentCheck = function() return (tonumber(getDurationTextValue("colorBreakpointCount")) or 0) >= i end,
		colorizeLabel = false,
		parentSection = expandable,
	})
end

addon.functions.SettingsCreateHeadline(category, L["durationTextFallbackTextHeader"], { parentSection = expandable, order = 40 })

addon.functions.SettingsCreateInput(category, {
	var = "durationText",
	subvar = "zeroDurationText",
	text = L["durationTextZeroDurationText"],
	desc = L["durationTextZeroDurationTextDesc"],
	default = DurationText.defaults.zeroDurationText,
	get = function() return getDurationTextValue("zeroDurationText") end,
	func = function(value) setDurationTextValue("zeroDurationText", value or "") end,
	order = 130,
	parentSection = expandable,
})

addon.functions.SettingsCreateInput(category, {
	var = "durationText",
	subvar = "expiredText",
	text = L["durationTextExpiredText"],
	desc = L["durationTextExpiredTextDesc"],
	default = DurationText.defaults.expiredText,
	get = function() return getDurationTextValue("expiredText") end,
	func = function(value) setDurationTextValue("expiredText", value or "") end,
	order = 140,
	parentSection = expandable,
})

addon.functions.SettingsCreateButton(category, {
	id = "durationTextResetDefaults",
	text = L["durationTextResetDefaults"],
	desc = L["durationTextResetDefaultsDesc"],
	buttonText = RESET_TO_DEFAULT,
	order = 150,
	func = function()
		DurationText:InitDB()
		DurationText:ResetProfile(DurationText:GetEditProfileKey())
		refreshDurationTextSettings()
	end,
	parentSection = expandable,
})
