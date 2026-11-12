local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local M = addon.MirrorTimers
if not M then return end
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local points = {
	{ value = "TOPLEFT", label = L["settingsAnchorTopLeft"] }, { value = "TOP", label = L["settingsAnchorTop"] },
	{ value = "TOPRIGHT", label = L["settingsAnchorTopRight"] }, { value = "LEFT", label = L["settingsAnchorLeft"] },
	{ value = "CENTER", label = L["settingsAnchorCenter"] }, { value = "RIGHT", label = L["settingsAnchorRight"] },
	{ value = "BOTTOMLEFT", label = L["settingsAnchorBottomLeft"] }, { value = "BOTTOM", label = L["settingsAnchorBottom"] },
	{ value = "BOTTOMRIGHT", label = L["settingsAnchorBottomRight"] },
}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local function idFor(timer) return "mirrorTimer:" .. timer end
local placementFields = { point = true, relativePoint = true, x = true, y = true }
local labels = { BREATH = L["mirrorTimerBreath"], EXHAUSTION = L["mirrorTimerFatigue"], FEIGNDEATH = L["mirrorTimerFeignDeath"], DEATH = L["mirrorTimerDeath"] }

local function invalidateSettingsReads()
	local internal = addon.EditModeLib and addon.EditModeLib.internal
	if internal and internal.InvalidateSettingsReadCache then internal:InvalidateSettingsReadCache(M) end
end

local function linkedPlacement(timer, forWrite)
	local anchors = addon.EditModeAnchors
	local entry = EditMode and EditMode.frames and EditMode.frames[idFor(timer)]
	local frame = entry and entry.frame
	local internal = addon.EditModeLib and addon.EditModeLib.internal
	local cache = not forWrite and internal and internal.GetSettingsReadCache and internal:GetSettingsReadCache(M)
	if cache and (cache.profile ~= addon.db or not cache.placements) then cache.profile, cache.placements = addon.db, {} end
	local cached = cache and cache.placements[timer]
	if cached and cached.anchors == anchors and cached.entry == entry and cached.frame == frame then
		return anchors, entry, cached.candidate, cached.context
	end
	local candidate = anchors and entry and anchors:Candidate(entry)
	local context = {}
	if cache then cache.placements[timer] = { anchors = anchors, entry = entry, frame = frame, candidate = candidate, context = context } end
	return anchors, entry, candidate, context
end

local function matchesWidth(anchors, entry, candidate)
	local record = anchors and entry and anchors:Store(entry.id)
	return candidate ~= nil and record ~= nil and record.widthTarget == candidate.targetId
end

local function refreshSettings()
	invalidateSettingsReads()
	local internal = addon.EditModeLib and addon.EditModeLib.internal
	if internal and internal.RequestRefreshSettings then internal:RequestRefreshSettings() end
end

function M:GetEditModeValue(timer, field)
	if field == "anchorTarget" or field == "matchWidth" or placementFields[field] then
		local anchors, entry, candidate = linkedPlacement(timer)
		if field == "anchorTarget" then return candidate and candidate.targetId or "UIParent" end
		if field == "matchWidth" then return matchesWidth(anchors, entry, candidate) end
		if candidate and candidate.placement then return candidate.placement[field] end
	end
	return self:GetConfig(timer)[field]
end

local function mediaOptions(kind)
	local options = {}
	local seen = {}
	local function add(value, label)
		if type(value) ~= "string" or value == "" or seen[value] then return end
		seen[value] = true
		options[#options + 1] = { value = value, label = type(label) == "string" and label or value }
	end
	local helpers = addon.functions or {}
	if kind == "font" and helpers.GetGlobalFontConfigKey and helpers.GetGlobalFontConfigLabel then
		add(helpers.GetGlobalFontConfigKey(), helpers.GetGlobalFontConfigLabel())
	end
	add("DEFAULT", _G.DEFAULT)
	local names = helpers.GetLSMMediaNames and helpers.GetLSMMediaNames(kind) or {}
	for _, name in ipairs(names) do add(name) end
	return options
end

function M:SetEditModeValue(timer, field, value)
	invalidateSettingsReads()
	if field == "anchorTarget" or field == "matchWidth" or placementFields[field] then
		local anchors, entry, candidate = linkedPlacement(timer, true)
		if field == "matchWidth" then
			local changed
			if anchors and entry and candidate then
				if value == true then
					if not anchors:WouldCycle(entry, candidate.targetId) then changed = anchors:SetSizeLink(entry, "width", candidate.targetId) end
				elseif matchesWidth(anchors, entry, candidate) then
					changed = anchors:SetSizeLink(entry, "width", nil)
				end
			end
			invalidateSettingsReads()
			if changed and not self._settingsBatch then refreshSettings() end
			return changed
		elseif field == "anchorTarget" then
			local changed
			if anchors and entry then
				local matchWidth = matchesWidth(anchors, entry, candidate)
				if value == "UIParent" then
					if candidate then
						if matchWidth then anchors:SetSizeLink(entry, "width", nil) end
						changed = anchors:Detach(entry)
					end
				elseif value ~= "editMode:" .. idFor(timer) then
					local allowed = false
					for _, target in ipairs(self.types) do if value == "editMode:" .. idFor(target) then allowed = true; break end end
					if allowed and not anchors:WouldCycle(entry, value) then
						changed = anchors:SetAnchor(entry, value)
						if changed then
							anchors:ChangePlacement(entry, "TOP", "BOTTOM", 0, 0, false)
							if matchWidth then anchors:SetSizeLink(entry, "width", value) end
						end
					end
				end
			end
			invalidateSettingsReads()
			if changed and not self._settingsBatch then refreshSettings() end
			return changed
		elseif candidate and candidate.placement then
			local placement = candidate.placement
			local changed = anchors:ChangePlacement(entry,
				field == "point" and value or placement.point, field == "relativePoint" and value or placement.relativePoint,
				field == "x" and value or nil, field == "y" and value or nil,
				field == "point" or field == "relativePoint")
			invalidateSettingsReads()
			if changed and not self._settingsBatch then refreshSettings() end
			return changed
		end
	end
	local config = self:GetConfig(timer)
	if not self._settingsBatch then
		if field == "warningThreshold" then value = math.max((config.criticalThreshold or 10) + 1, math.min(100, value)) end
		if field == "criticalThreshold" then value = math.max(0, math.min((config.warningThreshold or 30) - 1, value)) end
	end
	if EditMode and EditMode.frames and EditMode.frames[idFor(timer)] then
		EditMode:SetValue(idFor(timer), field, copy(value))
	else
		config[field] = copy(value)
		if not self._settingsBatch then self:Refresh() end
	end
	invalidateSettingsReads()
end

local function validTimer(timer)
	for _, name in ipairs(M.types) do if timer == name then return true end end
	return false
end

function M:CopySettings(target, source)
	invalidateSettingsReads()
	if target == source or not validTimer(target) or not validTimer(source) or (InCombatLockdown and InCombatLockdown()) then return false end
	local config, sourceConfig = self:GetConfig(target), self:GetConfig(source)
	local id = idFor(target)
	local registered = EditMode and EditMode.frames and EditMode.frames[id]
	for field in pairs(self:GetDefaults(target)) do
		if not placementFields[field] then
			config[field] = copy(sourceConfig[field])
			if registered then EditMode:SetValue(id, field, copy(config[field]), nil, true) end
		end
	end
	if registered then EditMode:ApplyLayout(id) else self:Refresh() end
	refreshSettings()
	return true
end

function M:ShowCopySettingsMenu(timer, owner)
	if not validTimer(timer) or (InCombatLockdown and InCombatLockdown()) or not (MenuUtil and MenuUtil.CreateContextMenu) then return false end
	local ownerType = type(owner)
	if (ownerType ~= "table" and ownerType ~= "userdata") or type(owner.GetObjectType) ~= "function" then owner = self.frames[timer] end
	if not owner then return false end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		for _, source in ipairs(self.types) do
			local button = root:CreateButton(labels[source], function() self:CopySettings(timer, source) end)
			button:SetEnabled(source ~= timer)
		end
	end)
	return true
end

function M:BuildSettings(timer)
	if not SettingType then return {} end
	local settings = {}
	local defaults = self:GetDefaults(timer)
	defaults.anchorTarget = "UIParent"
	defaults.matchWidth = false
	local function config() return self:GetConfig(timer) end
	local function group(id, name)
		settings[#settings + 1] = { id = id, name = name, kind = SettingType.Collapsible, defaultCollapsed = false }
	end
	local function row(parent, field, name, kind, extra)
		local data = {
			parentId = parent, field = field, navigationField = field, name = name, kind = kind,
			get = function() return self:GetEditModeValue(timer, field) end,
			set = function(_, value) self:SetEditModeValue(timer, field, value) end,
		}
		for key, value in pairs(extra or {}) do data[key] = value end
		if addon.EditModeNavigationDefaults then addon.EditModeNavigationDefaults.Set(data, defaults[field])
		else data.default = copy(defaults[field]) end
		settings[#settings + 1] = data
		return data
	end
	local function checkbox(parent, field, name) return row(parent, field, name, SettingType.Checkbox) end
	local function slider(parent, field, name, minimum, maximum, step, shown)
		return row(parent, field, name, SettingType.Slider, {
			minValue = minimum, maxValue = maximum, valueStep = step or 1, allowInput = true, isShown = shown,
			formatter = function(value) return string.format((step or 1) < 1 and "%.2f" or "%.0f", value) end,
		})
	end
	local function color(parent, field, name, shown)
		return row(parent, field, name, SettingType.Color, { hasOpacity = true, isShown = shown })
	end
	local function dropdown(parent, field, name, options, shown)
		return row(parent, field, name, SettingType.Dropdown, {
			height = 200, isShown = shown,
			generator = function(_, root)
				local entries = type(options) == "function" and options() or options
				for _, option in ipairs(entries) do
					local value, label
					if type(option) == "table" then
						value = option.value
						label = option.label or option.text or value
					else
						value, label = option, option
					end
					if (type(value) == "string" or type(value) == "number") and (type(label) == "string" or type(label) == "number") then
						local radio = root:CreateRadio(tostring(label), function() return self:GetEditModeValue(timer, field) == value end, function() self:SetEditModeValue(timer, field, value) end)
						if type(option) == "table" and option.isEnabled ~= nil and radio and radio.SetEnabled then
							local enabled = type(option.isEnabled) == "function" and option.isEnabled() or option.isEnabled
							radio:SetEnabled(enabled == true)
						end
					end
				end
			end,
		})
	end

	group("mirrorLayout", L["Position"])
	dropdown("mirrorLayout", "anchorTarget", L["Anchor to"], function()
		local options = { { value = "UIParent", label = L["Screen (UIParent)"] } }
		local anchors, entry, candidate, context = linkedPlacement(timer)
		local current = candidate and candidate.targetId or "UIParent"
		local known = current == "UIParent"
		for _, target in ipairs(self.types) do
			if current == "editMode:" .. idFor(target) then known = true end
			options[#options + 1] = {
				value = "editMode:" .. idFor(target), label = labels[target],
				isEnabled = target ~= timer and anchors ~= nil and entry ~= nil and not anchors:WouldCycle(entry, "editMode:" .. idFor(target), context),
			}
		end
		if not known and type(current) == "string" then
			local dynamic = addon.DynamicAnchors
			local label = dynamic and dynamic.GetTargetLabel and dynamic:GetTargetLabel(current)
			options[#options + 1] = { value = current, label = type(label) == "string" and label or current, isEnabled = false }
		end
		return options
	end)
	row("mirrorLayout", "matchWidth", L["EditModeAnchorMatchWidth"], SettingType.Checkbox, {
		isShown = function()
			local anchors, _, candidate, context = linkedPlacement(timer)
			return candidate ~= nil and anchors:ResolveTarget(candidate.targetId, context) ~= nil
		end,
	})
	dropdown("mirrorLayout", "point", L["Anchor point"], points)
	dropdown("mirrorLayout", "relativePoint", L["Relative point"], points)
	slider("mirrorLayout", "x", L["Offset X"], -2000, 2000)
	slider("mirrorLayout", "y", L["Offset Y"], -2000, 2000)
	local width = slider("mirrorLayout", "width", L["Width"], 40, 1200)
	width.isEnabled = function() return not self:GetEditModeValue(timer, "matchWidth") end
	slider("mirrorLayout", "height", L["Height"], 4, 160)
	slider("mirrorLayout", "alpha", L["Alpha"], 0, 1, 0.01)
	dropdown("mirrorLayout", "strata", L["Frame strata"], { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG" })
	group("mirrorBar", L["Bar"])
	dropdown("mirrorBar", "texture", L["Bar texture"], function() return mediaOptions("statusbar") end)
	color("mirrorBar", "color", L["Bar color"])
	color("mirrorBar", "bgColor", L["Background color"])
	dropdown("mirrorBar", "fillDirection", L["mirrorTimerFillOrigin"], {
		{ value = "LEFT", label = L["Left"] }, { value = "RIGHT", label = L["Right"] },
		{ value = "UP", label = L["Bottom"] }, { value = "DOWN", label = L["Top"] },
	})
	group("mirrorBorder", L["Border"])
	checkbox("mirrorBorder", "borderEnabled", L["Show border"])
	local borderShown = function() return config().borderEnabled == true end
	dropdown("mirrorBorder", "borderTexture", L["Border texture"], function() return mediaOptions("border") end, borderShown)
	slider("mirrorBorder", "borderSize", L["Border size"], 1, 20, 1, borderShown)
	slider("mirrorBorder", "borderOffset", L["Border offset"], -20, 20, 1, borderShown)
	color("mirrorBorder", "borderColor", L["Border color"], borderShown)

	local function typography(prefix, title, showLabel)
		local parent = prefix == "label" and "mirrorLabel" or "mirrorText"
		group(parent, title)
		checkbox(parent, prefix .. "Enabled", showLabel)
		local shown = function() return config()[prefix .. "Enabled"] == true end
		dropdown(parent, prefix .. "Font", L["Font"], function() return mediaOptions("font") end, shown)
		slider(parent, prefix .. "Size", L["Size"], 6, 64, 1, shown)
		dropdown(parent, prefix .. "Outline", L["Outline"], function()
			return addon.functions.GetFontStyleOptionList(true)
		end, shown)
		color(parent, prefix .. "Color", L["Color"], shown)
		dropdown(parent, prefix .. "Anchor", L["Text anchor"], points, shown)
		slider(parent, prefix .. "OffsetX", L["Offset X"], -500, 500, 1, shown)
		slider(parent, prefix .. "OffsetY", L["Offset Y"], -500, 500, 1, shown)
		return shown
	end
	typography("label", L["mirrorTimerLabel"], L["mirrorTimerShowLabel"])
	local textShown = typography("text", L["Time"], L["mirrorTimerShowTime"])
	dropdown("mirrorText", "textFormat", L["Format"], {
		{ value = "CURRENT", label = L["Current"] },
		{ value = "CURRENT_MAX", label = L["Current/Max"] },
		{ value = "PERCENT", label = L["Percent"] },
		{ value = "CURRENT_MAX_PERCENT", label = L["Current/Max Percent"] },
		{ value = "TIME_TO_FULL", label = L["mirrorTimerTimeToFull"] },
	}, textShown)
	dropdown("mirrorText", "timeStyle", L["mirrorTimerTimeStyle"], {
		{ value = "SECONDS", label = L["mirrorTimerSeconds"] }, { value = "CLOCK", label = L["mirrorTimerClock"] },
	}, textShown)
	slider("mirrorText", "decimals", L["mirrorTimerDecimals"], 0, 3, 1, textShown)
	group("mirrorGradient", L["Colors"])
	checkbox("mirrorGradient", "gradientEnabled", L["mirrorTimerGradient"])
	local gradientShown = function() return config().gradientEnabled == true end
	slider("mirrorGradient", "warningThreshold", L["mirrorTimerWarningThreshold"], 1, 100, 1, gradientShown)
	color("mirrorGradient", "warningColor", L["mirrorTimerWarningColor"], gradientShown)
	slider("mirrorGradient", "criticalThreshold", L["mirrorTimerCriticalThreshold"], 0, 99, 1, gradientShown)
	color("mirrorGradient", "criticalColor", L["mirrorTimerCriticalColor"], gradientShown)
	if addon.EditModeNavigationDefaults then
		local links = { matchWidth = "anchorTarget" }
		for _, data in ipairs(settings) do
			if data.isShown then
				if data.parentId == "mirrorBorder" then links[data.field] = "borderEnabled"
				elseif data.parentId == "mirrorLabel" then links[data.field] = "labelEnabled"
				elseif data.parentId == "mirrorText" then links[data.field] = "textEnabled"
				elseif data.parentId == "mirrorGradient" then links[data.field] = "gradientEnabled" end
			end
		end
		addon.EditModeNavigationDefaults.Link(settings, links)
	end
	return settings
end

function M:UnregisterEditMode()
	if not self._editModeRegistered then return end
	self._editModeRegistered = nil
	self._editModeProfiles = nil
	for _, timer in ipairs(self.types) do EditMode:UnregisterFrame(idFor(timer)) end
end

function M:RegisterEditMode()
	if self._editModeRegistered or not EditMode or not EditMode.RegisterFrame or not SettingType or not self:IsEnabled() then return end
	self:EnsureFrames()
	self._editModeRegistered = true
	self._editModeProfiles = {}
	for _, timer in ipairs(self.types) do
		local id = idFor(timer)
		local settings = self:BuildSettings(timer)
		EditMode:RegisterFrame(id, {
			frame = self.frames[timer], title = L["mirrorTimers"] .. ": " .. labels[timer],
			anchorAdapter = {
				inheritSizeSettings = true,
				setWidth = function(value)
					local widthValue = self.Number(value, nil, 40, 1200)
					if not widthValue then return false end
					self:SetEditModeValue(timer, "width", widthValue)
					return true
				end,
			},
			managerCategory = "resourceBars", layoutDefaults = copy(self:GetConfig(timer)),
			isEnabled = function() return self:IsEnabled() end,
			onApply = function(_, _, data)
				invalidateSettingsReads()
				local config = self:GetConfig(timer)
				if self._editModeProfiles[timer] ~= addon.db then
					-- Core persists positions; all appearance settings belong to the profile.
					for field, value in pairs(config) do
						if field ~= "point" and field ~= "relativePoint" and field ~= "x" and field ~= "y" then data[field] = copy(value) end
					end
					self._editModeProfiles[timer] = addon.db
				end
				for field in pairs(self:GetDefaults(timer)) do if data[field] ~= nil then config[field] = copy(data[field]) end end
				if not self._settingsBatch then self:Refresh() end
				invalidateSettingsReads()
			end,
			onEnter = function() self:SetPreview(true) end,
			onExit = function() self:SetPreview(false) end,
			manageVisibilityOutsideEditMode = false, normalizePosition = true,
			showReset = false, showSettingsReset = false, enableOverlayToggle = true,
			settings = settings,
			buttons = {
				{ text = L["Sample"], click = function() self:CyclePreviewSample(timer) end },
				{ text = L["Copy settings"], click = function(owner) self:ShowCopySettingsMenu(timer, owner) end },
			},
			settingsNavigation = {
				categories = {
					{ id = "frame", name = L["Frame"], groups = { "mirrorLayout", "mirrorBar", "mirrorBorder" } },
					{ id = "text", name = L["Text"], groups = { "mirrorLabel", "mirrorText" } },
					{ id = "colors", name = L["Colors"], groups = { "mirrorGradient" } },
				},
				reset = function(_, applyDefaults)
					self._settingsBatch = true
					local ok, err = pcall(applyDefaults)
					self._settingsBatch = nil
					self:Refresh()
					if not ok then error(err) end
				end,
			},
		})
	end
end
