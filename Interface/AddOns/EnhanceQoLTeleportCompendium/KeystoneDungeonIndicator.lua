local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.KeystoneDungeonIndicator = addon.MythicPlus.KeystoneDungeonIndicator or {}

local Indicator = addon.MythicPlus.KeystoneDungeonIndicator
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local EDITMODE_ID = "partyKeystoneDungeonIndicator"
local MAX_ENTRIES = 5
local DEFAULT_POSITION = { point = "CENTER", relativePoint = "CENTER", x = 360, y = 100 }
local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

local function clamp(value, minimum, maximum, fallback)
	value = tonumber(value) or fallback
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function copyColor(value, fallback)
	if type(value) ~= "table" then value = fallback end
	return {
		r = tonumber(value.r) or fallback.r,
		g = tonumber(value.g) or fallback.g,
		b = tonumber(value.b) or fallback.b,
		a = tonumber(value.a) or fallback.a,
	}
end

local function colorSignature(value, fallback)
	local color = copyColor(value, fallback)
	return table.concat({ color.r, color.g, color.b, color.a }, ":")
end

local function setShown(region, shown)
	if shown then
		if not region:IsShown() then region:Show() end
	elseif region:IsShown() then
		region:Hide()
	end
end

function Indicator:IsEnabled()
	return addon.db and addon.db.groupfinderShowPartyKeystone == true and addon.db.partyKeystoneDungeonIndicatorEnabled == true
end

function Indicator:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "EQOLPartyKeystoneDungeonIndicator", UIParent)
	frame:SetSize(220, 60)
	frame:SetPoint(DEFAULT_POSITION.point, UIParent, DEFAULT_POSITION.relativePoint, DEFAULT_POSITION.x, DEFAULT_POSITION.y)
	frame:SetClampedToScreen(true)
	frame:Hide()

	frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.header:SetText(L["keystoneDungeonIndicatorHeader"])
	frame.rows = {}
	for index = 1, MAX_ENTRIES do
		local row = CreateFrame("Frame", nil, frame)
		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.level = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.rows[index] = row
	end

	self.frame = frame
	return frame
end

function Indicator:GetFontConfig()
	local fallback = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local configured = addon.db.partyKeystoneDungeonIndicatorFont or fallback
	local face = addon.functions.ResolveFontFace and addon.functions.ResolveFontFace(configured, fallback) or fallback
	local style = addon.db.partyKeystoneDungeonIndicatorFontStyle or "OUTLINE"
	return face, style
end

function Indicator:GetStyleSignature()
	local db = addon.db
	local globalVersion = addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	return table.concat({
		tostring(globalVersion),
		tostring(db.partyKeystoneDungeonIndicatorFont),
		tostring(db.partyKeystoneDungeonIndicatorFontStyle),
		tostring(db.partyKeystoneDungeonIndicatorHeaderFontSize),
		tostring(db.partyKeystoneDungeonIndicatorEntryFontSize),
		tostring(db.partyKeystoneDungeonIndicatorRowSpacing),
		tostring(db.partyKeystoneDungeonIndicatorAlignment),
		tostring(db.partyKeystoneDungeonIndicatorGrowth),
		tostring(db.partyKeystoneDungeonIndicatorNameOffsetX),
		tostring(db.partyKeystoneDungeonIndicatorNameOffsetY),
		db.partyKeystoneDungeonIndicatorShowHeader == false and "0" or "1",
		db.partyKeystoneDungeonIndicatorUseClassColor == false and "0" or "1",
		db.partyKeystoneDungeonIndicatorUseRarityColor == false and "0" or "1",
		colorSignature(db.partyKeystoneDungeonIndicatorHeaderColor, { r = 1, g = 1, b = 1, a = 1 }),
		colorSignature(db.partyKeystoneDungeonIndicatorNameColor, { r = 1, g = 1, b = 1, a = 1 }),
		colorSignature(db.partyKeystoneDungeonIndicatorLevelColor, { r = 1, g = 1, b = 1, a = 1 }),
	}, "\031")
end

function Indicator:ApplyStyle()
	local frame = self:EnsureFrame()
	local db = addon.db
	local face, style = self:GetFontConfig()
	local headerSize = clamp(db.partyKeystoneDungeonIndicatorHeaderFontSize, 8, 40, 20)
	local entrySize = clamp(db.partyKeystoneDungeonIndicatorEntryFontSize, 8, 40, 18)
	local headerColor = copyColor(db.partyKeystoneDungeonIndicatorHeaderColor, { r = 1, g = 1, b = 1, a = 1 })
	local levelColor = copyColor(db.partyKeystoneDungeonIndicatorLevelColor, { r = 1, g = 1, b = 1, a = 1 })

	if addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(frame.header, face, headerSize, style, face, "OUTLINE")
	else
		frame.header:SetFont(face, headerSize, "OUTLINE")
	end
	frame.header:SetTextColor(headerColor.r, headerColor.g, headerColor.b, headerColor.a)
	for index = 1, MAX_ENTRIES do
		local row = frame.rows[index]
		if addon.functions.ApplyFontString then
			addon.functions.ApplyFontString(row.name, face, entrySize, style, face, "OUTLINE")
			addon.functions.ApplyFontString(row.level, face, entrySize, style, face, "OUTLINE")
		else
			row.name:SetFont(face, entrySize, "OUTLINE")
			row.level:SetFont(face, entrySize, "OUTLINE")
		end
		row.level:SetTextColor(levelColor.r, levelColor.g, levelColor.b, levelColor.a)
	end
	self.styleSignature = self:GetStyleSignature()
end

function Indicator:GetDisplayEntries()
	if self.preview then
		local sampleName = L["Sample"] or "Sample"
		return {
			{ name = UnitName("player") or PLAYER, level = 18, classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))] or { r = 1, g = 1, b = 1 } },
			{ name = sampleName .. " 2", level = 15, classColor = RAID_CLASS_COLORS.MAGE or { r = 0.25, g = 0.78, b = 0.92 } },
			{ name = sampleName .. " 3", level = 12, classColor = RAID_CLASS_COLORS.DRUID or { r = 1, g = 0.49, b = 0.04 } },
			{ name = sampleName .. " 4", level = 8, classColor = RAID_CLASS_COLORS.PRIEST or { r = 1, g = 1, b = 1 } },
			{ name = sampleName .. " 5", level = 4, classColor = RAID_CLASS_COLORS.ROGUE or { r = 1, g = 0.96, b = 0.41 } },
		}
	end
	if not self:IsEnabled() then return nil end

	local functions = addon.MythicPlus.functions
	local challengeMapID = functions.GetCurrentDungeonChallengeMapID and functions.GetCurrentDungeonChallengeMapID()
	if not challengeMapID then return nil end
	local source = functions.GetPartyKeystoneEntries and functions.GetPartyKeystoneEntries(false) or {}
	local entries = {}
	for index = 1, #source do
		local entry = source[index]
		local level = entry.data and tonumber(entry.data.level)
		if entry.data and entry.data.challengeMapID == challengeMapID and level and level > 0 then
			entries[#entries + 1] = { name = entry.name, level = level, classColor = entry.classColor }
		end
	end
	if #entries == 0 then return nil end
	table.sort(entries, function(left, right)
		if left.level ~= right.level then return left.level > right.level end
		return tostring(left.name) < tostring(right.name)
	end)
	return entries
end

function Indicator:GetContentSignature(entries)
	local parts = { self.preview and "preview" or "runtime" }
	for index = 1, #entries do
		local entry = entries[index]
		parts[#parts + 1] = tostring(entry.name)
		parts[#parts + 1] = tostring(entry.level)
		local color = entry.classColor or {}
		parts[#parts + 1] = table.concat({ color.r or 1, color.g or 1, color.b or 1 }, ":")
	end
	return table.concat(parts, "\031")
end

function Indicator:ApplyContent(entries)
	local frame = self:EnsureFrame()
	local db = addon.db
	local showHeader = db.partyKeystoneDungeonIndicatorShowHeader ~= false
	local alignment = db.partyKeystoneDungeonIndicatorAlignment
	if alignment ~= "CENTER" and alignment ~= "RIGHT" then alignment = "LEFT" end
	local growth = db.partyKeystoneDungeonIndicatorGrowth == "UP" and "UP" or "DOWN"
	local rowSpacing = clamp(db.partyKeystoneDungeonIndicatorRowSpacing, 0, 20, 2)
	local nameOffsetX = clamp(db.partyKeystoneDungeonIndicatorNameOffsetX, -200, 200, 0)
	local nameOffsetY = clamp(db.partyKeystoneDungeonIndicatorNameOffsetY, -200, 200, 0)
	local nameColor = copyColor(db.partyKeystoneDungeonIndicatorNameColor, { r = 1, g = 1, b = 1, a = 1 })
	local levelColor = copyColor(db.partyKeystoneDungeonIndicatorLevelColor, { r = 1, g = 1, b = 1, a = 1 })

	frame.header:SetText(L["keystoneDungeonIndicatorHeader"])
	setShown(frame.header, showHeader)
	local headerWidth = showHeader and frame.header:GetStringWidth() or 0
	local headerHeight = showHeader and frame.header:GetStringHeight() or 0
	local maxWidth = headerWidth
	local rowWidths = {}
	local rowHeights = {}

	for index = 1, MAX_ENTRIES do
		local row = frame.rows[index]
		local entry = entries[index]
		if entry then
			row.name:SetText((entry.name or "") .. ":")
			row.level:SetText("+" .. tostring(entry.level))
			local color = db.partyKeystoneDungeonIndicatorUseClassColor ~= false and entry.classColor or nameColor
			row.name:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
			local levelR, levelG, levelB, levelA = levelColor.r, levelColor.g, levelColor.b, levelColor.a
			if db.partyKeystoneDungeonIndicatorUseRarityColor ~= false and C_ChallengeMode.GetKeystoneLevelRarityColor then
				local rarityColor = C_ChallengeMode.GetKeystoneLevelRarityColor(entry.level)
				if rarityColor and rarityColor.GetRGB then levelR, levelG, levelB = rarityColor:GetRGB() end
				levelA = 1
			end
			row.level:SetTextColor(levelR, levelG, levelB, levelA)
			rowWidths[index] = row.name:GetStringWidth() + 6 + row.level:GetStringWidth()
			rowHeights[index] = math.max(row.name:GetStringHeight(), row.level:GetStringHeight())
			maxWidth = math.max(maxWidth, rowWidths[index])
			setShown(row, true)
		else
			setShown(row, false)
		end
	end

	maxWidth = math.max(1, math.ceil(maxWidth))
	local function alignedX(width)
		return alignment == "RIGHT" and (maxWidth - width) or (alignment == "CENTER" and (maxWidth - width) / 2 or 0)
	end
	local function anchorRow(index, point, relativePoint, x, y)
		local row = frame.rows[index]
		local width = rowWidths[index]
		local height = rowHeights[index]
		row:ClearAllPoints()
		row:SetPoint(point, frame, relativePoint, x, y)
		row:SetSize(width, height)
		row.name:ClearAllPoints()
		row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
		row.level:ClearAllPoints()
		row.level:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
	end

	frame.header:ClearAllPoints()
	local height
	if growth == "UP" then
		local y = 0
		if showHeader then
			frame.header:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", alignedX(headerWidth), y)
			y = y + headerHeight + rowSpacing
		end
		y = y + nameOffsetY
		for index = #entries, 1, -1 do
			anchorRow(index, "BOTTOMLEFT", "BOTTOMLEFT", alignedX(rowWidths[index]) + nameOffsetX, y)
			y = y + rowHeights[index]
			if index > 1 then y = y + rowSpacing end
		end
		height = y
	else
		local y = 0
		if showHeader then
			frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", alignedX(headerWidth), y)
			y = y - headerHeight - rowSpacing
		end
		y = y + nameOffsetY
		for index = 1, #entries do
			anchorRow(index, "TOPLEFT", "TOPLEFT", alignedX(rowWidths[index]) + nameOffsetX, y)
			y = y - rowHeights[index]
			if index < #entries then y = y - rowSpacing end
		end
		height = -y
	end
	frame:SetSize(maxWidth, math.max(1, math.ceil(height)))
	self.contentSignature = self:GetContentSignature(entries)
end

function Indicator:Refresh(force)
	local frame = self:EnsureFrame()
	local entries = self:GetDisplayEntries()
	if not entries then
		self.contentSignature = nil
		setShown(frame, false)
		return
	end

	local styleSignature = self:GetStyleSignature()
	local styleChanged = force == true or styleSignature ~= self.styleSignature
	if styleChanged then self:ApplyStyle() end
	local contentSignature = self:GetContentSignature(entries)
	if styleChanged or force == true or contentSignature ~= self.contentSignature then self:ApplyContent(entries) end
	setShown(frame, true)
end

function Indicator:ScheduleRefresh()
	if self.refreshPending then return end
	self.refreshPending = true
	C_Timer.After(0, function()
		self.refreshPending = false
		self:Refresh()
	end)
end

function Indicator:UpdateEvents()
	local frame = self:EnsureFrame()
	frame:UnregisterAllEvents()
	if self:IsEnabled() then
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
		frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
	end
end

function Indicator:GetPositionValue(field)
	if EditMode and EditMode.GetValue then return EditMode:GetValue(EDITMODE_ID, field) end
	return DEFAULT_POSITION[field]
end

function Indicator:SetPositionValue(field, value)
	if not (EditMode and EditMode.SetValue) then return end
	EditMode:SetValue(EDITMODE_ID, field, value, nil, true)
	if EditMode.ApplyLayout then EditMode:ApplyLayout(EDITMODE_ID) end
end

function Indicator:GetFontOptions()
	local options = {}
	local globalKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey()
	if globalKey then options[#options + 1] = { value = globalKey, label = addon.functions.GetGlobalFontConfigLabel() } end
	local defaultFont = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	options[#options + 1] = { value = defaultFont, label = L["actionBarFontDefault"] or "Blizzard font" }
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	local hash = addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font") or {}
	for index = 1, #names do
		local path = hash[names[index]]
		if type(path) == "string" and path ~= "" and path ~= defaultFont then options[#options + 1] = { value = path, label = tostring(names[index]) } end
	end
	return options
end

function Indicator:BuildSettings()
	if not SettingType then return nil end
	local function setValue(key, value)
		addon.db[key] = value
		Indicator:Refresh()
	end
	local function colorSetting(name, key, parentId, fallback, isEnabled)
		return {
			name = name,
			kind = SettingType.Color,
			parentId = parentId,
			hasOpacity = true,
			get = function() return copyColor(addon.db[key], fallback) end,
			set = function(_, value) setValue(key, copyColor(value, fallback)) end,
			isEnabled = isEnabled,
		}
	end

	local settings = {
		{ name = L["Frame"], kind = SettingType.Collapsible, id = "keystoneDungeonIndicatorFrame", defaultCollapsed = false },
		{
			name = L["Anchor point"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFrame", height = 220, default = DEFAULT_POSITION.point,
			get = function() return Indicator:GetPositionValue("point") or DEFAULT_POSITION.point end,
			set = function(_, value) Indicator:SetPositionValue("point", value) end,
			generator = function(_, root)
				for index = 1, #ANCHOR_POINTS do
					local point = ANCHOR_POINTS[index]
					root:CreateRadio(point, function() return Indicator:GetPositionValue("point") == point end, function() Indicator:SetPositionValue("point", point) end)
				end
			end,
		},
		{
			name = L["Relative point"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFrame", height = 220, default = DEFAULT_POSITION.relativePoint,
			get = function() return Indicator:GetPositionValue("relativePoint") or DEFAULT_POSITION.relativePoint end,
			set = function(_, value) Indicator:SetPositionValue("relativePoint", value) end,
			generator = function(_, root)
				for index = 1, #ANCHOR_POINTS do
					local point = ANCHOR_POINTS[index]
					root:CreateRadio(point, function() return Indicator:GetPositionValue("relativePoint") == point end, function() Indicator:SetPositionValue("relativePoint", point) end)
				end
			end,
		},
		{
			name = L["X Offset"], kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFrame", minValue = -2000, maxValue = 2000, valueStep = 1, default = DEFAULT_POSITION.x, allowInput = true,
			get = function() return Indicator:GetPositionValue("x") or DEFAULT_POSITION.x end,
			set = function(_, value) Indicator:SetPositionValue("x", clamp(value, -2000, 2000, DEFAULT_POSITION.x)) end,
		},
		{
			name = L["Y Offset"], kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFrame", minValue = -2000, maxValue = 2000, valueStep = 1, default = DEFAULT_POSITION.y, allowInput = true,
			get = function() return Indicator:GetPositionValue("y") or DEFAULT_POSITION.y end,
			set = function(_, value) Indicator:SetPositionValue("y", clamp(value, -2000, 2000, DEFAULT_POSITION.y)) end,
		},
		{
			name = L["keystoneDungeonIndicatorShowHeader"], kind = SettingType.Checkbox, parentId = "keystoneDungeonIndicatorFrame", default = true,
			get = function() return addon.db.partyKeystoneDungeonIndicatorShowHeader ~= false end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorShowHeader", value == true) end,
		},
		{
			name = L["mythicPlusTimerAlign"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFrame", height = 140,
			get = function() return addon.db.partyKeystoneDungeonIndicatorAlignment or "LEFT" end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorAlignment", value) end,
			generator = function(_, root)
				for _, option in ipairs({ { value = "LEFT", label = L["Left"] }, { value = "CENTER", label = L["Center"] }, { value = "RIGHT", label = L["Right"] } }) do
					root:CreateRadio(option.label, function() return addon.db.partyKeystoneDungeonIndicatorAlignment == option.value end, function() setValue("partyKeystoneDungeonIndicatorAlignment", option.value) end)
				end
			end,
		},
		{
			name = L["Growth direction"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFrame", height = 120, default = "DOWN",
			get = function() return addon.db.partyKeystoneDungeonIndicatorGrowth or "DOWN" end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorGrowth", value == "UP" and "UP" or "DOWN") end,
			generator = function(_, root)
				for _, option in ipairs({ { value = "DOWN", label = L["Down"] }, { value = "UP", label = L["Up"] } }) do
					root:CreateRadio(option.label, function() return addon.db.partyKeystoneDungeonIndicatorGrowth == option.value end, function() setValue("partyKeystoneDungeonIndicatorGrowth", option.value) end)
				end
			end,
		},
		{
			name = L["Vertical spacing"], kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFrame", minValue = 0, maxValue = 20, valueStep = 1, default = 2,
			get = function() return addon.db.partyKeystoneDungeonIndicatorRowSpacing end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorRowSpacing", clamp(value, 0, 20, 2)) end,
		},
		{
			name = L["Name"] .. " - " .. L["X Offset"], kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFrame", minValue = -200, maxValue = 200, valueStep = 1, default = 0,
			get = function() return addon.db.partyKeystoneDungeonIndicatorNameOffsetX end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorNameOffsetX", clamp(value, -200, 200, 0)) end,
		},
		{
			name = L["Name"] .. " - " .. L["Y Offset"], kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFrame", minValue = -200, maxValue = 200, valueStep = 1, default = 0,
			get = function() return addon.db.partyKeystoneDungeonIndicatorNameOffsetY end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorNameOffsetY", clamp(value, -200, 200, 0)) end,
		},
		{ name = L["Font"], kind = SettingType.Collapsible, id = "keystoneDungeonIndicatorFont", defaultCollapsed = true },
		{
			name = L["Font"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFont", height = 260,
			get = function() return addon.db.partyKeystoneDungeonIndicatorFont end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorFont", value) end,
			generator = function(_, root)
				local current = addon.db.partyKeystoneDungeonIndicatorFont
				for _, option in ipairs(Indicator:GetFontOptions()) do root:CreateRadio(option.label, function() return current == option.value end, function() setValue("partyKeystoneDungeonIndicatorFont", option.value) end) end
			end,
		},
		{
			name = L["Font outline"], kind = SettingType.Dropdown, parentId = "keystoneDungeonIndicatorFont", height = 180,
			get = function() return addon.db.partyKeystoneDungeonIndicatorFontStyle end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorFontStyle", value) end,
			generator = function(_, root)
				local current = addon.db.partyKeystoneDungeonIndicatorFontStyle
				local options = addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true) or {}
				for _, option in ipairs(options) do root:CreateRadio(option.label, function() return current == option.value end, function() setValue("partyKeystoneDungeonIndicatorFontStyle", option.value) end) end
			end,
		},
		{
			name = L["Header"] .. " - " .. (_G.FONT_SIZE or "Font size"), kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFont", minValue = 8, maxValue = 40, valueStep = 1, default = 20,
			get = function() return addon.db.partyKeystoneDungeonIndicatorHeaderFontSize end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorHeaderFontSize", clamp(value, 8, 40, 20)) end,
			isEnabled = function() return addon.db.partyKeystoneDungeonIndicatorShowHeader ~= false end,
		},
		{
			name = L["Name"] .. " - " .. (_G.FONT_SIZE or "Font size"), kind = SettingType.Slider, parentId = "keystoneDungeonIndicatorFont", minValue = 8, maxValue = 40, valueStep = 1, default = 18,
			get = function() return addon.db.partyKeystoneDungeonIndicatorEntryFontSize end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorEntryFontSize", clamp(value, 8, 40, 18)) end,
		},
		{
			name = L["Use class color"], kind = SettingType.Checkbox, parentId = "keystoneDungeonIndicatorFont", default = true,
			get = function() return addon.db.partyKeystoneDungeonIndicatorUseClassColor ~= false end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorUseClassColor", value == true) end,
		},
		{
			name = L["keystoneDungeonIndicatorUseRarityColor"], kind = SettingType.Checkbox, parentId = "keystoneDungeonIndicatorFont", default = true,
			get = function() return addon.db.partyKeystoneDungeonIndicatorUseRarityColor ~= false end,
			set = function(_, value) setValue("partyKeystoneDungeonIndicatorUseRarityColor", value == true) end,
		},
	}
	settings[#settings + 1] = colorSetting(L["Header"] .. " - " .. L["Text color"], "partyKeystoneDungeonIndicatorHeaderColor", "keystoneDungeonIndicatorFont", { r = 1, g = 1, b = 1, a = 1 }, function() return addon.db.partyKeystoneDungeonIndicatorShowHeader ~= false end)
	settings[#settings + 1] = colorSetting(L["Name"] .. " - " .. L["Text color"], "partyKeystoneDungeonIndicatorNameColor", "keystoneDungeonIndicatorFont", { r = 1, g = 1, b = 1, a = 1 }, function() return addon.db.partyKeystoneDungeonIndicatorUseClassColor == false end)
	settings[#settings + 1] = colorSetting(L["Level"] .. " - " .. L["Text color"], "partyKeystoneDungeonIndicatorLevelColor", "keystoneDungeonIndicatorFont", { r = 1, g = 1, b = 1, a = 1 }, function() return addon.db.partyKeystoneDungeonIndicatorUseRarityColor == false end)
	return settings
end

function Indicator:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame) then return end
	EditMode:RegisterFrame(EDITMODE_ID, {
		frame = self:EnsureFrame(),
		title = L["keystoneDungeonIndicator"],
		layoutDefaults = DEFAULT_POSITION,
		onEnter = function()
			Indicator.preview = true
			Indicator:Refresh()
		end,
		onExit = function()
			Indicator.preview = false
			Indicator:Refresh()
		end,
		onPositionChanged = function()
			local internal = EditMode and EditMode.lib and EditMode.lib.internal
			if internal and internal.RequestRefreshSettingValues then internal:RequestRefreshSettingValues() end
		end,
		isEnabled = function() return Indicator:IsEnabled() end,
		managePosition = true,
		manageVisibilityOutsideEditMode = false,
		showOutsideEditMode = false,
		settings = self:BuildSettings(),
		settingsMaxHeight = 620,
		collapseExclusive = true,
	})
	self.editModeRegistered = true
end

function addon.MythicPlus.functions.RefreshKeystoneDungeonIndicator(force)
	if Indicator.initialized then Indicator:Refresh(force) end
end

function addon.MythicPlus.functions.UpdateKeystoneDungeonIndicator()
	if not Indicator.initialized then return end
	Indicator:UpdateEvents()
	if Indicator:IsEnabled() and addon.MythicPlus.triggerRequest then addon.MythicPlus.triggerRequest() end
	Indicator:Refresh()
end

function addon.MythicPlus.functions.InitKeystoneDungeonIndicator()
	if Indicator.initialized then return end
	Indicator.initialized = true
	local frame = Indicator:EnsureFrame()
	frame:SetScript("OnEvent", function() Indicator:ScheduleRefresh() end)
	Indicator:RegisterEditMode()
	Indicator:UpdateEvents()
	Indicator:Refresh()
end
