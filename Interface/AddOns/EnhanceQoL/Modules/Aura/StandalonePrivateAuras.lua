local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.StandalonePrivateAuras = addon.Aura.StandalonePrivateAuras or {}
local PrivateAuras = addon.Aura.StandalonePrivateAuras

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local UFHelper = addon.Aura and addon.Aura.UFHelper
local SharedAnchors = addon.SharedAnchors
local DIRECTION_LEFT_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_LEFT
local DIRECTION_RIGHT_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_RIGHT
local DIRECTION_UP_LABEL = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_UP
local DIRECTION_DOWN_LABEL = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_DOWN

local DB_KEY = "standalonePrivateAuras"
local EDITMODE_ID = "standalonePrivateAuras"
local MAX_AMOUNT = 10
local MIN_SIZE = 10
local MAX_SIZE = 256
local MAX_SPACING = 64
local directionLabels = {
	LEFT = DIRECTION_LEFT_LABEL,
	RIGHT = DIRECTION_RIGHT_LABEL,
	UP = DIRECTION_UP_LABEL,
	DOWN = DIRECTION_DOWN_LABEL,
}

local directionOptions = {
	{ value = "LEFT", label = directionLabels.LEFT },
	{ value = "RIGHT", label = directionLabels.RIGHT },
	{ value = "UP", label = directionLabels.UP },
	{ value = "DOWN", label = directionLabels.DOWN },
}

local anchorOptions = {
	{ value = "TOPLEFT", label = "TOPLEFT" },
	{ value = "TOP", label = "TOP" },
	{ value = "TOPRIGHT", label = "TOPRIGHT" },
	{ value = "LEFT", label = "LEFT" },
	{ value = "CENTER", label = "CENTER" },
	{ value = "RIGHT", label = "RIGHT" },
	{ value = "BOTTOMLEFT", label = "BOTTOMLEFT" },
	{ value = "BOTTOM", label = "BOTTOM" },
	{ value = "BOTTOMRIGHT", label = "BOTTOMRIGHT" },
}

local function normalizeRelativeFrame(value, current)
	if SharedAnchors and SharedAnchors.ValidateTarget then return SharedAnchors:ValidateTarget(value, current, { includeCursor = false }) end
	if type(value) ~= "string" or value == "" then return "UIParent" end
	return value
end

local function resolveRelativeFrame(value)
	if SharedAnchors and SharedAnchors.ResolveFrame then return SharedAnchors:ResolveFrame(value) end
	return UIParent
end

local function anchorUsesUIParent(value)
	if SharedAnchors and SharedAnchors.IsUIParentTarget then return SharedAnchors:IsUIParentTarget(value) end
	return value == nil or value == "" or value == "UIParent"
end

local function getAnchorTargetEntries(current)
	if SharedAnchors and SharedAnchors.GetEntries then return SharedAnchors:GetEntries(current, { includeCursor = false }) end
	return {
		{ key = "UIParent", label = "UIParent" },
	}
end

local function getAnchorDefaults(target)
	if SharedAnchors and SharedAnchors.GetDefaultAnchorData then return SharedAnchors:GetDefaultAnchorData(target) end
	return {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0,
	}
end

local function refreshEditModeSettingValues()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then
		addon.EditModeLib.internal:RefreshSettingValues()
	end
end

local function createDefaultConfig()
	return {
		version = 1,
		enabled = false,
		anchor = {
			point = "CENTER",
			relativePoint = "CENTER",
			relativeFrame = "UIParent",
			x = 0,
			y = -140,
		},
		icon = {
			amount = 3,
			size = 64,
			minSize = MIN_SIZE,
			maxSize = 60,
			point = "RIGHT",
			offset = 4,
			borderScale = nil,
		},
		layout = {
			enabled = true,
			direction = "RIGHT",
			wrapCount = 0,
			wrapDirection = "DOWN",
		},
		countdownFrame = true,
		countdownNumbers = false,
		showTooltip = false,
		showDispelType = false,
		duration = {
			enable = false,
			point = "BOTTOM",
			offsetX = 0,
			offsetY = -1,
		},
	}
end

PrivateAuras.defaults = PrivateAuras.defaults or createDefaultConfig()
local defaults = PrivateAuras.defaults

local function clampNumber(value, minValue, maxValue, fallback)
	if UFHelper and UFHelper.ClampNumber then return UFHelper.ClampNumber(value, minValue, maxValue, fallback) end
	local v = tonumber(value)
	if v == nil then return fallback end
	if minValue ~= nil and v < minValue then v = minValue end
	if maxValue ~= nil and v > maxValue then v = maxValue end
	return v
end

local function clampInt(value, minValue, maxValue, fallback)
	local v = clampNumber(value, minValue, maxValue, fallback)
	if v == nil then return fallback end
	return math.floor(v + 0.5)
end

local function normalizeDirection(value, fallback)
	if UFHelper and UFHelper.PrivateAuraNormalizeDirection then return UFHelper.PrivateAuraNormalizeDirection(value, fallback) end
	local direction = tostring(value or fallback or "RIGHT"):upper()
	if direction == "LEFT" or direction == "RIGHT" or direction == "UP" or direction == "DOWN" then return direction end
	return tostring(fallback or "RIGHT"):upper()
end

local function isHorizontal(direction)
	local value = normalizeDirection(direction, "RIGHT")
	return value == "LEFT" or value == "RIGHT"
end

local function normalizeWrapDirection(direction, primaryDirection)
	local horizontal = isHorizontal(primaryDirection)
	local value = normalizeDirection(direction, horizontal and "DOWN" or "RIGHT")
	if horizontal then
		if value ~= "UP" and value ~= "DOWN" then return "DOWN" end
		return value
	end
	if value ~= "LEFT" and value ~= "RIGHT" then return "RIGHT" end
	return value
end

local function normalizeAnchorPoint(value, fallback)
	local point = tostring(value or fallback or "CENTER"):upper()
	for i = 1, #anchorOptions do
		if anchorOptions[i].value == point then return point end
	end
	return tostring(fallback or "CENTER"):upper()
end

local function formatSliderValue(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end

local function isInEditMode() return EditMode and EditMode.IsInEditMode and EditMode:IsInEditMode() == true end

local function seedMissing(record, key, value)
	if type(record) ~= "table" then return end
	if record[key] == nil then record[key] = value end
end

function PrivateAuras:GetDefaults() return defaults end

function PrivateAuras:GetConfig()
	addon.db = addon.db or {}
	if addon.db[DB_KEY] == nil then
		if addon.functions and addon.functions.InitDBValue then
			addon.functions.InitDBValue(DB_KEY, createDefaultConfig())
		else
			addon.db[DB_KEY] = createDefaultConfig()
		end
	end

	local cfg = addon.db[DB_KEY]
	if type(cfg) ~= "table" then
		cfg = createDefaultConfig()
		addon.db[DB_KEY] = cfg
	end

	cfg.anchor = type(cfg.anchor) == "table" and cfg.anchor or {}
	cfg.icon = type(cfg.icon) == "table" and cfg.icon or {}
	cfg.layout = type(cfg.layout) == "table" and cfg.layout or {}
	cfg.duration = type(cfg.duration) == "table" and cfg.duration or {}

	if cfg.enabled == nil then cfg.enabled = defaults.enabled == true end
	if cfg.countdownFrame == nil then cfg.countdownFrame = defaults.countdownFrame ~= false end
	if cfg.countdownNumbers == nil then cfg.countdownNumbers = defaults.countdownNumbers == true end
	if cfg.showTooltip == nil then cfg.showTooltip = defaults.showTooltip == true end
	if cfg.showDispelType == nil then cfg.showDispelType = defaults.showDispelType == true end

	local anchor = cfg.anchor
	anchor.point = normalizeAnchorPoint(anchor.point, defaults.anchor.point)
	anchor.relativePoint = normalizeAnchorPoint(anchor.relativePoint or anchor.point, defaults.anchor.relativePoint or anchor.point)
	anchor.relativeFrame = normalizeRelativeFrame(anchor.relativeFrame or defaults.anchor.relativeFrame, anchor.relativeFrame or defaults.anchor.relativeFrame)
	anchor.x = clampInt(anchor.x, -4096, 4096, defaults.anchor.x)
	anchor.y = clampInt(anchor.y, -4096, 4096, defaults.anchor.y)

	local icon = cfg.icon
	icon.amount = clampInt(icon.amount, 1, MAX_AMOUNT, defaults.icon.amount)
	icon.size = clampInt(icon.size, MIN_SIZE, MAX_SIZE, defaults.icon.size)
	icon.minSize = MIN_SIZE
	icon.maxSize = MAX_SIZE
	icon.offset = clampInt(icon.offset, 0, MAX_SPACING, defaults.icon.offset)

	local layout = cfg.layout
	layout.enabled = true
	layout.direction = normalizeDirection(layout.direction or icon.point, defaults.layout.direction or defaults.icon.point)
	icon.point = layout.direction

	layout.wrapCount = clampInt(layout.wrapCount or icon.wrapAfter, 0, icon.amount, defaults.layout.wrapCount or 0)
	icon.wrapAfter = layout.wrapCount
	layout.wrapDirection = normalizeWrapDirection(layout.wrapDirection or icon.wrapDirection, layout.direction)
	icon.wrapDirection = layout.wrapDirection

	local duration = cfg.duration
	if duration.enable == nil then duration.enable = defaults.duration.enable == true end
	duration.point = normalizeAnchorPoint(duration.point, defaults.duration.point)
	duration.offsetX = clampInt(duration.offsetX, -100, 100, defaults.duration.offsetX)
	duration.offsetY = clampInt(duration.offsetY, -100, 100, defaults.duration.offsetY)

	return cfg
end

function PrivateAuras:IsEnabled() return self:GetConfig().enabled == true end

function PrivateAuras:GetEditModeValue(field)
	local cfg = self:GetConfig()
	if field == "amount" then return cfg.icon.amount end
	if field == "anchorTarget" then return cfg.anchor.relativeFrame end
	if field == "point" then return cfg.anchor.point end
	if field == "relativePoint" then return cfg.anchor.relativePoint end
	if field == "x" then return cfg.anchor.x end
	if field == "y" then return cfg.anchor.y end
	if field == "size" then return cfg.icon.size end
	if field == "spacing" then return cfg.icon.offset end
	if field == "direction" then return cfg.layout.direction end
	if field == "wrapAfter" then return cfg.layout.wrapCount end
	if field == "wrapDirection" then return cfg.layout.wrapDirection end
	if field == "countdownFrame" then return cfg.countdownFrame ~= false end
	if field == "countdownNumbers" then return cfg.countdownNumbers == true end
	if field == "showTooltip" then return cfg.showTooltip == true end
	if field == "showDispelType" then return cfg.showDispelType == true end
	if field == "durationEnabled" then return cfg.duration.enable == true end
	if field == "durationPoint" then return cfg.duration.point end
	if field == "durationOffsetX" then return cfg.duration.offsetX or 0 end
	if field == "durationOffsetY" then return cfg.duration.offsetY or 0 end
	return nil
end

function PrivateAuras:BuildRuntimeConfig()
	local cfg = self:GetConfig()
	return {
		enabled = true,
		countdownFrame = cfg.countdownFrame ~= false,
		countdownNumbers = cfg.countdownNumbers == true,
		showTooltip = cfg.showTooltip == true,
		showDispelType = cfg.showDispelType == true,
		icon = {
			amount = cfg.icon.amount,
			size = cfg.icon.size,
			minSize = MIN_SIZE,
			maxSize = MAX_SIZE,
			point = cfg.layout.direction,
			offset = cfg.icon.offset,
			borderScale = cfg.icon.borderScale,
		},
		parent = {
			point = "CENTER",
			offsetX = 0,
			offsetY = 0,
		},
		layout = {
			enabled = true,
			direction = cfg.layout.direction,
			wrapCount = cfg.layout.wrapCount,
			wrapDirection = cfg.layout.wrapDirection,
		},
		duration = {
			enable = cfg.duration.enable == true,
			point = cfg.duration.point,
			offsetX = cfg.duration.offsetX or 0,
			offsetY = cfg.duration.offsetY or 0,
		},
	}
end

function PrivateAuras:EnsureFrame()
	if self.frame then return self.frame end
	local frame = CreateFrame("Frame", "EnhanceQoLStandalonePrivateAuraAnchor", UIParent)
	frame:SetSize(defaults.icon.size, defaults.icon.size)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(false)

	frame.container = CreateFrame("Frame", nil, frame)
	frame.container:EnableMouse(false)
	frame.container:SetPoint("CENTER", frame, "CENTER", 0, 0)

	self.frame = frame
	return frame
end

function PrivateAuras:Refresh()
	local cfg = self:GetConfig()
	local previewMode = isInEditMode()
	local visible = cfg.enabled == true or previewMode
	if not visible and not self.frame then return end

	local frame = self:EnsureFrame()
	local anchorFrame = resolveRelativeFrame(cfg.anchor.relativeFrame)
	frame:ClearAllPoints()
	frame:SetPoint(cfg.anchor.point, anchorFrame, cfg.anchor.relativePoint, cfg.anchor.x or 0, cfg.anchor.y or 0)

	if not visible then
		if UFHelper and UFHelper.RemovePrivateAuras then UFHelper.RemovePrivateAuras(frame.container) end
		frame:SetSize(cfg.icon.size or defaults.icon.size, cfg.icon.size or defaults.icon.size)
		frame:Hide()
		return
	end

	if UFHelper and UFHelper.ApplyPrivateAuras then UFHelper.ApplyPrivateAuras(frame.container, "player", self:BuildRuntimeConfig(), frame, frame, previewMode) end

	local width = frame.container._eqolPrivateAuraLayoutWidth or frame.container:GetWidth() or cfg.icon.size or defaults.icon.size
	local height = frame.container._eqolPrivateAuraLayoutHeight or frame.container:GetHeight() or cfg.icon.size or defaults.icon.size
	if width < 1 then width = cfg.icon.size or defaults.icon.size end
	if height < 1 then height = cfg.icon.size or defaults.icon.size end
	frame:SetSize(width, height)
	frame:Show()
end

function PrivateAuras:RebuildAnchors()
	if self.frame and UFHelper and UFHelper.RemovePrivateAuras then UFHelper.RemovePrivateAuras(self.frame.container) end
	self:Refresh()
end

function PrivateAuras:RequestStartupRefresh()
	if self.startupRefreshQueued then return end
	self.startupRefreshQueued = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			self.startupRefreshQueued = nil
			if self:IsEnabled() then self:RebuildAnchors() end
		end)
	else
		self.startupRefreshQueued = nil
		if self:IsEnabled() then self:RebuildAnchors() end
	end
end

function PrivateAuras:RegisterStartupEvents()
	if self.startupEventsRegistered then return end
	local frame = self.startupEventFrame or CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", function()
		if PrivateAuras:IsEnabled() then PrivateAuras:RequestStartupRefresh() end
	end)
	self.startupEventFrame = frame
	self.startupEventsRegistered = true
end

function PrivateAuras:ApplyLayoutData(data)
	if type(data) ~= "table" then
		self:Refresh()
		return
	end

	local cfg = self:GetConfig()
	local anchor = cfg.anchor
	local icon = cfg.icon
	local layout = cfg.layout
	local duration = cfg.duration

	if data.point ~= nil then anchor.point = normalizeAnchorPoint(data.point, anchor.point or defaults.anchor.point) end
	if data.relativePoint ~= nil then anchor.relativePoint = normalizeAnchorPoint(data.relativePoint, anchor.relativePoint or anchor.point or defaults.anchor.relativePoint) end
	if data.anchorTarget ~= nil then anchor.relativeFrame = normalizeRelativeFrame(data.anchorTarget, anchor.relativeFrame or defaults.anchor.relativeFrame) end
	if data.x ~= nil then anchor.x = clampInt(data.x, -4096, 4096, anchor.x or defaults.anchor.x) end
	if data.y ~= nil then anchor.y = clampInt(data.y, -4096, 4096, anchor.y or defaults.anchor.y) end

	if data.amount ~= nil then icon.amount = clampInt(data.amount, 1, MAX_AMOUNT, icon.amount or defaults.icon.amount) end
	if data.size ~= nil then icon.size = clampInt(data.size, MIN_SIZE, MAX_SIZE, icon.size or defaults.icon.size) end
	if data.spacing ~= nil then icon.offset = clampInt(data.spacing, 0, MAX_SPACING, icon.offset or defaults.icon.offset) end
	if data.direction ~= nil then
		layout.direction = normalizeDirection(data.direction, layout.direction or defaults.layout.direction)
		icon.point = layout.direction
	end
	if data.wrapAfter ~= nil then layout.wrapCount = clampInt(data.wrapAfter, 0, icon.amount, layout.wrapCount or defaults.layout.wrapCount or 0) end
	icon.wrapAfter = layout.wrapCount or 0
	layout.wrapDirection = normalizeWrapDirection(data.wrapDirection ~= nil and data.wrapDirection or layout.wrapDirection, layout.direction or icon.point)
	icon.wrapDirection = layout.wrapDirection

	if data.countdownFrame ~= nil then cfg.countdownFrame = data.countdownFrame and true or false end
	if data.countdownNumbers ~= nil then cfg.countdownNumbers = data.countdownNumbers and true or false end
	if data.showTooltip ~= nil then cfg.showTooltip = data.showTooltip and true or false end
	if data.showDispelType ~= nil then cfg.showDispelType = data.showDispelType and true or false end
	if data.durationEnabled ~= nil then duration.enable = data.durationEnabled and true or false end
	if data.durationPoint ~= nil then duration.point = normalizeAnchorPoint(data.durationPoint, duration.point or defaults.duration.point) end
	if data.durationOffsetX ~= nil then duration.offsetX = clampInt(data.durationOffsetX, -100, 100, duration.offsetX or defaults.duration.offsetX) end
	if data.durationOffsetY ~= nil then duration.offsetY = clampInt(data.durationOffsetY, -100, 100, duration.offsetY or defaults.duration.offsetY) end

	layout.wrapCount = clampInt(layout.wrapCount, 0, icon.amount, defaults.layout.wrapCount or 0)
	icon.wrapAfter = layout.wrapCount
	self:Refresh()
end

function PrivateAuras:SetLayoutField(field, value)
	self:ApplyLayoutData({ [field] = value })
	if EditMode and EditMode.SetValue then
		EditMode:SetValue(EDITMODE_ID, field, self:GetEditModeValue(field), nil, true)
		if field == "direction" then EditMode:SetValue(EDITMODE_ID, "wrapDirection", self:GetEditModeValue("wrapDirection"), nil, true) end
		if field == "amount" then EditMode:SetValue(EDITMODE_ID, "wrapAfter", self:GetEditModeValue("wrapAfter"), nil, true) end
	end
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

function PrivateAuras:OpenEditMode()
	if EditModeManagerFrame and ShowUIPanel then
		ShowUIPanel(EditModeManagerFrame)
	elseif EditModeManagerFrame and EditModeManagerFrame.Show then
		EditModeManagerFrame:Show()
	end
end

function PrivateAuras:RegisterSettings()
	if self.settingsRegistered then return end
	self.settingsRegistered = true
end

function PrivateAuras:RegisterEditModeCallbacks()
	if self.editModeCallbacksRegistered then return end
	if not (EditMode and EditMode.lib and EditMode.lib.RegisterCallback) then return end
	EditMode.lib:RegisterCallback("enter", function() PrivateAuras:Refresh() end, self)
	EditMode.lib:RegisterCallback("exit", function() PrivateAuras:Refresh() end, self)
	self.editModeCallbacksRegistered = true
end

function PrivateAuras:UnregisterEditMode()
	if not self.editModeRegistered then return end
	if EditMode and EditMode.UnregisterFrame then EditMode:UnregisterFrame(EDITMODE_ID, false) end
	self.editModeRegistered = false
end

function PrivateAuras:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end

	local settings = {
		{
			name = L["Anchor"] or "Anchor",
			kind = SettingType.Collapsible,
			id = "standalonePrivateAurasAnchor",
			defaultCollapsed = false,
		},
		{
			name = L["Anchor to"] or "Anchor to",
			kind = SettingType.Dropdown,
			field = "anchorTarget",
			parentId = "standalonePrivateAurasAnchor",
			height = 220,
			get = function() return self:GetEditModeValue("anchorTarget") end,
			set = function(_, value)
				local current = self:GetEditModeValue("anchorTarget") or "UIParent"
				local target = normalizeRelativeFrame(value, current)
				local defaults = getAnchorDefaults(target)
				self:ApplyLayoutData({
					anchorTarget = target,
					point = defaults.point,
					relativePoint = defaults.relativePoint,
					x = defaults.x,
					y = defaults.y,
				})
				if EditMode and EditMode.SetValue then
					EditMode:SetValue(EDITMODE_ID, "anchorTarget", self:GetEditModeValue("anchorTarget"), nil, true)
					EditMode:SetValue(EDITMODE_ID, "point", self:GetEditModeValue("point"), nil, true)
					EditMode:SetValue(EDITMODE_ID, "relativePoint", self:GetEditModeValue("relativePoint"), nil, true)
					EditMode:SetValue(EDITMODE_ID, "x", self:GetEditModeValue("x"), nil, true)
					EditMode:SetValue(EDITMODE_ID, "y", self:GetEditModeValue("y"), nil, true)
				end
				refreshEditModeSettingValues()
				if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
			end,
			generator = function(_, root)
				local entries = getAnchorTargetEntries(self:GetEditModeValue("anchorTarget") or "UIParent")
				local current = self:GetEditModeValue("anchorTarget")
				for i = 1, #entries do
					local option = entries[i]
					root:CreateRadio(option.label, function() return current == option.key end, function()
						local defaults = getAnchorDefaults(option.key)
						self:ApplyLayoutData({
							anchorTarget = option.key,
							point = defaults.point,
							relativePoint = defaults.relativePoint,
							x = defaults.x,
							y = defaults.y,
						})
						if EditMode and EditMode.SetValue then
							EditMode:SetValue(EDITMODE_ID, "anchorTarget", self:GetEditModeValue("anchorTarget"), nil, true)
							EditMode:SetValue(EDITMODE_ID, "point", self:GetEditModeValue("point"), nil, true)
							EditMode:SetValue(EDITMODE_ID, "relativePoint", self:GetEditModeValue("relativePoint"), nil, true)
							EditMode:SetValue(EDITMODE_ID, "x", self:GetEditModeValue("x"), nil, true)
							EditMode:SetValue(EDITMODE_ID, "y", self:GetEditModeValue("y"), nil, true)
						end
						refreshEditModeSettingValues()
						if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
					end)
				end
			end,
		},
		{
			name = L["Anchor point"] or "Anchor point",
			kind = SettingType.Dropdown,
			field = "point",
			parentId = "standalonePrivateAurasAnchor",
			height = 180,
			get = function() return self:GetEditModeValue("point") end,
			set = function(_, value) self:SetLayoutField("point", value) end,
			generator = function(_, root)
				for i = 1, #anchorOptions do
					local option = anchorOptions[i]
					root:CreateRadio(option.label, function() return self:GetEditModeValue("point") == option.value end, function() self:SetLayoutField("point", option.value) end)
				end
			end,
		},
		{
			name = L["Relative point"] or "Relative point",
			kind = SettingType.Dropdown,
			field = "relativePoint",
			parentId = "standalonePrivateAurasAnchor",
			height = 180,
			get = function() return self:GetEditModeValue("relativePoint") end,
			set = function(_, value) self:SetLayoutField("relativePoint", value) end,
			generator = function(_, root)
				for i = 1, #anchorOptions do
					local option = anchorOptions[i]
					root:CreateRadio(option.label, function() return self:GetEditModeValue("relativePoint") == option.value end, function() self:SetLayoutField("relativePoint", option.value) end)
				end
			end,
		},
		{
			name = L["X Offset"] or "X Offset",
			kind = SettingType.Slider,
			field = "x",
			parentId = "standalonePrivateAurasAnchor",
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			allowInput = true,
			get = function() return self:GetEditModeValue("x") end,
			set = function(_, value) self:SetLayoutField("x", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["Y Offset"] or "Y Offset",
			kind = SettingType.Slider,
			field = "y",
			parentId = "standalonePrivateAurasAnchor",
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			allowInput = true,
			get = function() return self:GetEditModeValue("y") end,
			set = function(_, value) self:SetLayoutField("y", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["UFPrivateAurasAmount"] or "Private aura amount",
			kind = SettingType.Slider,
			field = "amount",
			default = self:GetEditModeValue("amount"),
			minValue = 1,
			maxValue = MAX_AMOUNT,
			valueStep = 1,
			get = function() return self:GetEditModeValue("amount") end,
			set = function(_, value) self:SetLayoutField("amount", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["UFPrivateAurasSize"] or "Private aura size",
			kind = SettingType.Slider,
			field = "size",
			default = self:GetEditModeValue("size"),
			minValue = MIN_SIZE,
			maxValue = MAX_SIZE,
			valueStep = 1,
			get = function() return self:GetEditModeValue("size") end,
			set = function(_, value) self:SetLayoutField("size", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["Icon spacing"] or "Icon spacing",
			kind = SettingType.Slider,
			field = "spacing",
			default = self:GetEditModeValue("spacing"),
			minValue = 0,
			maxValue = MAX_SPACING,
			valueStep = 1,
			get = function() return self:GetEditModeValue("spacing") end,
			set = function(_, value) self:SetLayoutField("spacing", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["Icon direction"] or "Icon direction",
			kind = SettingType.Dropdown,
			field = "direction",
			height = 120,
			get = function() return self:GetEditModeValue("direction") end,
			set = function(_, value) self:SetLayoutField("direction", value) end,
			generator = function(_, root)
				for i = 1, #directionOptions do
					local option = directionOptions[i]
					root:CreateRadio(option.label, function() return self:GetEditModeValue("direction") == option.value end, function() self:SetLayoutField("direction", option.value) end)
				end
			end,
		},
		{
			name = L["UFPrivateAurasWrapAfter"] or "Wrap after",
			kind = SettingType.Slider,
			field = "wrapAfter",
			default = self:GetEditModeValue("wrapAfter"),
			minValue = 0,
			maxValue = MAX_AMOUNT,
			valueStep = 1,
			get = function() return self:GetEditModeValue("wrapAfter") end,
			set = function(_, value) self:SetLayoutField("wrapAfter", value) end,
			formatter = formatSliderValue,
		},
		{
			name = L["UFPrivateAurasWrapDirection"] or "Wrap direction",
			kind = SettingType.Dropdown,
			field = "wrapDirection",
			height = 90,
			get = function() return self:GetEditModeValue("wrapDirection") end,
			set = function(_, value) self:SetLayoutField("wrapDirection", value) end,
			isEnabled = function() return (self:GetEditModeValue("wrapAfter") or 0) > 0 end,
			generator = function(_, root)
				local options
				if isHorizontal(self:GetEditModeValue("direction")) then
					options = {
						{ value = "DOWN", label = directionLabels.DOWN },
						{ value = "UP", label = directionLabels.UP },
					}
				else
					options = {
						{ value = "RIGHT", label = directionLabels.RIGHT },
						{ value = "LEFT", label = directionLabels.LEFT },
					}
				end
				for i = 1, #options do
					local option = options[i]
					root:CreateRadio(option.label, function() return self:GetEditModeValue("wrapDirection") == option.value end, function() self:SetLayoutField("wrapDirection", option.value) end)
				end
			end,
		},
		{
			name = L["Show countdown frame"] or "Show countdown frame",
			kind = SettingType.Checkbox,
			field = "countdownFrame",
			default = self:GetEditModeValue("countdownFrame"),
			get = function() return self:GetEditModeValue("countdownFrame") end,
			set = function(_, value) self:SetLayoutField("countdownFrame", value) end,
		},
		{
			name = L["Show countdown numbers"] or "Show countdown numbers",
			kind = SettingType.Checkbox,
			field = "countdownNumbers",
			default = self:GetEditModeValue("countdownNumbers"),
			get = function() return self:GetEditModeValue("countdownNumbers") end,
			set = function(_, value) self:SetLayoutField("countdownNumbers", value) end,
			isEnabled = function() return self:GetEditModeValue("countdownFrame") == true end,
		},
		{
			name = L["Show tooltip"] or "Show tooltip",
			kind = SettingType.Checkbox,
			field = "showTooltip",
			default = self:GetEditModeValue("showTooltip"),
			get = function() return self:GetEditModeValue("showTooltip") end,
			set = function(_, value) self:SetLayoutField("showTooltip", value) end,
		},
		{
			name = L["Show dispel type"] or "Show dispel type",
			kind = SettingType.Checkbox,
			field = "showDispelType",
			default = self:GetEditModeValue("showDispelType"),
			get = function() return self:GetEditModeValue("showDispelType") end,
			set = function(_, value) self:SetLayoutField("showDispelType", value) end,
		},
		{
			name = L["Show duration"] or "Show duration",
			kind = SettingType.Checkbox,
			field = "durationEnabled",
			default = self:GetEditModeValue("durationEnabled"),
			get = function() return self:GetEditModeValue("durationEnabled") end,
			set = function(_, value) self:SetLayoutField("durationEnabled", value) end,
		},
		{
			name = L["Duration anchor"] or "Duration anchor",
			kind = SettingType.Dropdown,
			field = "durationPoint",
			height = 180,
			get = function() return self:GetEditModeValue("durationPoint") end,
			set = function(_, value) self:SetLayoutField("durationPoint", value) end,
			isEnabled = function() return self:GetEditModeValue("durationEnabled") == true end,
			generator = function(_, root)
				for i = 1, #anchorOptions do
					local option = anchorOptions[i]
					root:CreateRadio(option.label, function() return self:GetEditModeValue("durationPoint") == option.value end, function() self:SetLayoutField("durationPoint", option.value) end)
				end
			end,
		},
		{
			name = L["Duration offset X"] or "Duration offset X",
			kind = SettingType.Slider,
			field = "durationOffsetX",
			default = self:GetEditModeValue("durationOffsetX"),
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			get = function() return self:GetEditModeValue("durationOffsetX") end,
			set = function(_, value) self:SetLayoutField("durationOffsetX", value) end,
			formatter = formatSliderValue,
			isEnabled = function() return self:GetEditModeValue("durationEnabled") == true end,
		},
		{
			name = L["Duration offset Y"] or "Duration offset Y",
			kind = SettingType.Slider,
			field = "durationOffsetY",
			default = self:GetEditModeValue("durationOffsetY"),
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			get = function() return self:GetEditModeValue("durationOffsetY") end,
			set = function(_, value) self:SetLayoutField("durationOffsetY", value) end,
			formatter = formatSliderValue,
			isEnabled = function() return self:GetEditModeValue("durationEnabled") == true end,
		},
	}

	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["UFStandalonePrivateAuras"] or "Standalone Private Auras",
		layoutDefaults = {
			point = self:GetConfig().anchor.point,
			relativePoint = self:GetConfig().anchor.relativePoint,
			anchorTarget = self:GetConfig().anchor.relativeFrame,
			x = self:GetConfig().anchor.x,
			y = self:GetConfig().anchor.y,
			amount = self:GetEditModeValue("amount"),
			size = self:GetEditModeValue("size"),
			spacing = self:GetEditModeValue("spacing"),
			direction = self:GetEditModeValue("direction"),
			wrapAfter = self:GetEditModeValue("wrapAfter"),
			wrapDirection = self:GetEditModeValue("wrapDirection"),
			countdownFrame = self:GetEditModeValue("countdownFrame"),
			countdownNumbers = self:GetEditModeValue("countdownNumbers"),
			showTooltip = self:GetEditModeValue("showTooltip"),
			showDispelType = self:GetEditModeValue("showDispelType"),
			durationEnabled = self:GetEditModeValue("durationEnabled"),
			durationPoint = self:GetEditModeValue("durationPoint"),
			durationOffsetX = self:GetEditModeValue("durationOffsetX"),
			durationOffsetY = self:GetEditModeValue("durationOffsetY"),
		},
		onApply = function(_, _, data)
			local record = type(data) == "table" and data or {}
			local cfg = self:GetConfig()
			seedMissing(record, "point", cfg.anchor.point)
			seedMissing(record, "relativePoint", cfg.anchor.relativePoint)
			seedMissing(record, "anchorTarget", cfg.anchor.relativeFrame)
			seedMissing(record, "x", cfg.anchor.x)
			seedMissing(record, "y", cfg.anchor.y)
			seedMissing(record, "amount", self:GetEditModeValue("amount"))
			seedMissing(record, "size", self:GetEditModeValue("size"))
			seedMissing(record, "spacing", self:GetEditModeValue("spacing"))
			seedMissing(record, "direction", self:GetEditModeValue("direction"))
			seedMissing(record, "wrapAfter", self:GetEditModeValue("wrapAfter"))
			seedMissing(record, "wrapDirection", self:GetEditModeValue("wrapDirection"))
			seedMissing(record, "countdownFrame", self:GetEditModeValue("countdownFrame"))
			seedMissing(record, "countdownNumbers", self:GetEditModeValue("countdownNumbers"))
			seedMissing(record, "showTooltip", self:GetEditModeValue("showTooltip"))
			seedMissing(record, "showDispelType", self:GetEditModeValue("showDispelType"))
			seedMissing(record, "durationEnabled", self:GetEditModeValue("durationEnabled"))
			seedMissing(record, "durationPoint", self:GetEditModeValue("durationPoint"))
			seedMissing(record, "durationOffsetX", self:GetEditModeValue("durationOffsetX"))
			seedMissing(record, "durationOffsetY", self:GetEditModeValue("durationOffsetY"))
			self:ApplyLayoutData(record)
		end,
		onEnter = function() self:Refresh() end,
		onExit = function() self:Refresh() end,
		isEnabled = function() return self:IsEnabled() end,
		settings = settings,
		relativeTo = function() return resolveRelativeFrame(self:GetConfig().anchor.relativeFrame) end,
		allowDrag = function() return anchorUsesUIParent(self:GetConfig().anchor.relativeFrame) end,
		managePosition = false,
		persistPosition = false,
		showOutsideEditMode = true,
		enableOverlayToggle = true,
	})

	self.editModeRegistered = true
end

function PrivateAuras:OnSettingChanged(enabled)
	local cfg = self:GetConfig()
	cfg.enabled = enabled and true or false
	self:RegisterSettings()
	if cfg.enabled == true then
		self:RegisterEditMode()
		self:RegisterEditModeCallbacks()
		self:Refresh()
	else
		self:UnregisterEditMode()
		if self.frame then
			if UFHelper and UFHelper.RemovePrivateAuras then UFHelper.RemovePrivateAuras(self.frame.container) end
			self.frame:Hide()
		end
	end
	if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
end

function PrivateAuras:Initialize()
	self:GetConfig()
	self:RegisterSettings()
	self:RegisterStartupEvents()
	if self:IsEnabled() then
		self:RegisterEditMode()
		self:RegisterEditModeCallbacks()
		self:RequestStartupRefresh()
	else
		self:UnregisterEditMode()
	end
end

addon.Aura.functions = addon.Aura.functions or {}
addon.Aura.functions.InitStandalonePrivateAuras = function()
	if PrivateAuras and PrivateAuras.Initialize then PrivateAuras:Initialize() end
end
