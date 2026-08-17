-- luacheck: globals BackdropTemplateMixin CreateFrame LibStub

local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or { functions = {} }
addon.MythicPlus.MythicPlusTimer = addon.MythicPlus.MythicPlusTimer or {}

local Timer = addon.MythicPlus.MythicPlusTimer
local Flow = Timer.PanelFlow or {}
Timer.PanelFlow = Flow

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local GLOBAL_FONT_KEY = "__EQOL_GLOBAL_FONT__"
local GLOBAL_STYLE_KEY = "__EQOL_GLOBAL_STYLE__"
local DEATH_ICON_ATLAS = "poi-graveyard-neutral"
local CONTENT_OFFSET_LIMIT = 400

Flow.defaults = {
	schemaVersion = 1,
	width = 368,
	paddingLeft = 1,
	paddingRight = 1,
	paddingTop = 1,
	paddingBottom = 1,
	backgroundEnabled = true,
	backgroundTexture = "",
	backgroundColor = { r = 0, g = 0, b = 0, a = 0.43 },
	borderEnabled = true,
	borderTexture = "EQOL: Solid",
	borderColor = { r = 0, g = 0, b = 0, a = 1 },
	borderSize = 1,
	fontFace = GLOBAL_FONT_KEY,
	fontOutline = GLOBAL_STYLE_KEY,
	textColor = { r = 1, g = 1, b = 1, a = 1 },
	dungeonColor = { r = 1, g = 0.82, b = 0, a = 1 },
	deathColor = { r = 1, g = 0.2, b = 0.2, a = 1 },
	objectiveColor = { r = 1, g = 1, b = 1, a = 1 },
	objectiveCompleteColor = { r = 0.55, g = 0.55, b = 0.55, a = 1 },
	headerEnabled = true,
	headerHeight = 22,
	headerGap = 0,
	headerInsetLeft = 0,
	headerInsetRight = 0,
	headerBackgroundEnabled = true,
	headerBackgroundTexture = "",
	headerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.42 },
	headerFontSize = 18,
	affixFontSize = 18,
	deathFontSize = 18,
	headerSlotLeft = "DUNGEON",
	headerSlotCenter = "AFFIXES",
	headerSlotRight = "DEATHS",
	headerSlotLeftOffsetX = 0,
	headerSlotLeftOffsetY = 0,
	headerSlotCenterOffsetX = 0,
	headerSlotCenterOffsetY = 0,
	headerSlotRightOffsetX = 0,
	headerSlotRightOffsetY = 0,
	timerEnabled = true,
	timerHeight = 24,
	timerGap = 0,
	timerInsetLeft = 0,
	timerInsetRight = 0,
	timerTexture = "",
	timerColor = { r = 0, g = 1, b = 0.12549, a = 1 },
	timerExpiredColor = { r = 1, g = 0.12, b = 0.12, a = 1 },
	timerBackgroundTexture = "",
	timerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.4 },
	timerBorderEnabled = false,
	timerBorderTexture = "EQOL: Solid",
	timerBorderColor = { r = 0, g = 0, b = 0, a = 1 },
	timerBorderSize = 1,
	timerFontSize = 18,
	timerFillUp = true,
	timerChestMarkers = true,
	timerSlotLeft = "TIMER",
	timerSlotCenter = "CHEST_2",
	timerSlotRight = "CHEST_3",
	timerSlotLeftOffsetX = 0,
	timerSlotLeftOffsetY = 0,
	timerSlotCenterOffsetX = 0,
	timerSlotCenterOffsetY = 0,
	timerSlotRightOffsetX = 0,
	timerSlotRightOffsetY = 0,
	timerDisplay = "TIME_LEFT_TOTAL",
	objectivesEnabled = true,
	objectivesRowHeight = 22,
	objectivesSpacing = 0,
	objectivesGap = 0,
	objectivesInsetLeft = 0,
	objectivesInsetRight = 0,
	objectivesPaddingLeft = 3,
	objectivesPaddingRight = 3,
	objectivesColumnGap = 4,
	objectivesLabelOffsetX = 0,
	objectivesLabelOffsetY = 0,
	objectivesValueOffsetX = 0,
	objectivesValueOffsetY = 0,
	objectivesSingleLine = true,
	objectivesFontSize = 18,
	objectivesShowValues = true,
	objectivesShowTimes = true,
	objectivesShowBestTimes = false,
	objectivesHideNonBoss = false,
	enemyEnabled = true,
	enemyHeight = 21,
	enemyGap = 0,
	enemyInsetLeft = 0,
	enemyInsetRight = 0,
	enemyTexture = "",
	enemyColor = { r = 1, g = 0.760784, b = 0.172549, a = 1 },
	enemyBackgroundTexture = "",
	enemyBackgroundColor = { r = 0, g = 0, b = 0, a = 0.25 },
	enemyBorderEnabled = false,
	enemyBorderTexture = "EQOL: Solid",
	enemyBorderColor = { r = 0, g = 0, b = 0, a = 1 },
	enemyBorderSize = 1,
	enemyFontSize = 18,
	enemySlotLeft = "COUNT",
	enemySlotRight = "PERCENT",
	enemySlotLeftOffsetX = 0,
	enemySlotLeftOffsetY = 0,
	enemySlotRightOffsetX = 0,
	enemySlotRightOffsetY = 0,
	footerEnabled = false,
	footerHeight = 18,
	footerGap = 0,
	footerInsetLeft = 0,
	footerInsetRight = 0,
	footerBackgroundEnabled = true,
	footerBackgroundTexture = "",
	footerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.35 },
	footerFontSize = 16,
	footerSlotLeft = "BEST_TIME",
	footerSlotCenter = "NONE",
	footerSlotRight = "ENEMY_PERCENT",
	footerSlotLeftOffsetX = 0,
	footerSlotLeftOffsetY = 0,
	footerSlotCenterOffsetX = 0,
	footerSlotCenterOffsetY = 0,
	footerSlotRightOffsetX = 0,
	footerSlotRightOffsetY = 0,
	dungeonDisplay = "SHORT_LEVEL",
	affixDisplay = "ICON",
	deathDisplay = "ICON",
}

local SLOT_SECTIONS = { "header", "timer", "footer" }
local SLOT_POSITIONS = { "Left", "Center", "Right" }
local SLOT_CONTENT = {
	"NONE",
	"DUNGEON",
	"KEY_LEVEL",
	"AFFIXES",
	"DEATHS",
	"TIMER",
	"CHEST_2",
	"CHEST_3",
	"BEST_TIME",
	"ENEMY_PERCENT",
}

local function copyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, entry in pairs(value) do result[key] = copyTable(entry) end
	return result
end

local function clamp(value, minimum, maximum, fallback)
	value = tonumber(value) or fallback or minimum
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function normalizeColor(color, fallback)
	color = type(color) == "table" and color or fallback or {}
	return {
		r = clamp(color.r or color[1], 0, 1, fallback and fallback.r or 1),
		g = clamp(color.g or color[2], 0, 1, fallback and fallback.g or 1),
		b = clamp(color.b or color[3], 0, 1, fallback and fallback.b or 1),
		a = clamp(color.a or color[4], 0, 1, fallback and fallback.a or 1),
	}
end

local function resolveMedia(mediaType, key, fallback)
	if type(key) == "string" and key ~= "" then
		if addon.functions.ResolveLSMMedia then
			local resolved = addon.functions.ResolveLSMMedia(mediaType, key, fallback, true)
			if resolved then return resolved end
		end
		if LSM and LSM.Fetch then
			local resolved = LSM:Fetch(mediaType, key, true)
			if resolved then return resolved end
		end
	end
	return fallback
end

local function resolveFont(key)
	if key == GLOBAL_FONT_KEY then key = addon.db and addon.db.globalFontFace end
	return resolveMedia("font", key, DEFAULT_FONT)
end

local function resolveFontStyle(value)
	if value == GLOBAL_STYLE_KEY then value = addon.db and addon.db.globalFontStyle or "OUTLINE" end
	if addon.functions.GetFontFlagsForStyle then return addon.functions.GetFontFlagsForStyle(value, "OUTLINE") end
	if value == "NONE" then return "" end
	return value == "THICKOUTLINE" and "THICKOUTLINE" or "OUTLINE"
end

local function applyFont(fontString, face, size, style)
	local fontKey = table.concat({ tostring(face or DEFAULT_FONT), tostring(size or 12), tostring(style or "") }, "\031")
	if fontString._eqolFlowFontKey == fontKey then return end
	if addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(fontString, face, size, style, DEFAULT_FONT, "OUTLINE")
	else
		fontString:SetFont(face or DEFAULT_FONT, size or 12, resolveFontStyle(style))
	end
	fontString:SetWordWrap(false)
	fontString:SetNonSpaceWrap(false)
	if fontString.SetMaxLines then fontString:SetMaxLines(1) end
	fontString._eqolFlowFontKey = fontKey
end

local function applyTexture(texture, mediaType, key, fallback)
	if not texture then return end
	texture:SetTexture(resolveMedia(mediaType, key, fallback))
	texture:SetTexCoord(0, 1, 0, 1)
	if addon.PixelUtil and addon.PixelUtil.ApplyTexturePixelSnapping then addon.PixelUtil.ApplyTexturePixelSnapping(texture, 0) end
end

local function setTextureColor(texture, color)
	color = normalizeColor(color)
	texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

local function secondsText(value)
	value = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
	return string.format("%d:%02d", math.floor(value / 60), value % 60)
end

local function getConfig(create)
	if not addon.db then return nil end
	local root = addon.db.mythicPlusTimer
	if type(root) ~= "table" then
		if not create then return nil end
		root = { layoutMode = "FLOW" }
		addon.db.mythicPlusTimer = root
	end
	local config = root.panelFlow
	if type(config) ~= "table" and create then
		config = { schemaVersion = Flow.defaults.schemaVersion }
		root.panelFlow = config
	end
	return config
end

function Flow:Get(key)
	local config = getConfig(false)
	local value = config and config[key]
	if value == nil then return Flow.defaults[key] end
	return value
end

function Flow:Set(key, value)
	if Flow.defaults[key] == nil then return end
	local config = getConfig(true)
	config[key] = type(value) == "table" and copyTable(value) or value
	config.schemaVersion = Flow.defaults.schemaVersion
	if addon.db and addon.db.mythicPlusTimer then addon.db.mythicPlusTimer.layoutMode = "FLOW" end
	if Timer.Refresh then Timer:Refresh() end
end

function Flow:EnsureConfig()
	local config = getConfig(true)
	if config.schemaVersion == nil then config.schemaVersion = Flow.defaults.schemaVersion end
	return config
end

local function slotKey(section, position)
	return section .. "Slot" .. position
end

function Flow:SetSlot(section, position, content)
	local destinationKey = slotKey(section, position)
	if Flow.defaults[destinationKey] == nil then return end
	local valid = false
	for _, entry in ipairs(SLOT_CONTENT) do
		if entry == content then valid = true break end
	end
	if not valid then content = "NONE" end
	local config = getConfig(true)
	local previous = self:Get(destinationKey)
	if content ~= "NONE" then
		for _, candidateSection in ipairs(SLOT_SECTIONS) do
			for _, candidatePosition in ipairs(SLOT_POSITIONS) do
				local candidateKey = slotKey(candidateSection, candidatePosition)
				if candidateKey ~= destinationKey and self:Get(candidateKey) == content then
					config[candidateKey] = previous ~= content and previous or "NONE"
				end
			end
		end
	end
	config[destinationKey] = content
	config.schemaVersion = Flow.defaults.schemaVersion
	if addon.db and addon.db.mythicPlusTimer then addon.db.mythicPlusTimer.layoutMode = "FLOW" end
	if Timer.Refresh then Timer:Refresh() end
end

local function ensureBorder(parent)
	local border = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	border:SetAllPoints(parent)
	border:EnableMouse(false)
	border:Hide()
	return border
end

local function ensureBackground(parent, layer, subLevel)
	local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
	texture:SetDrawLayer(layer or "BACKGROUND", subLevel or 0)
	texture:SetAllPoints(parent)
	return texture
end

local function ensureSlotRow(parent)
	local row = { frame = parent, slots = {} }
	for index, position in ipairs({ "Left", "Center", "Right" }) do
		local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetDrawLayer("OVERLAY", 7)
		text:SetJustifyH(index == 1 and "LEFT" or index == 2 and "CENTER" or "RIGHT")
		text:SetJustifyV("MIDDLE")
		row.slots[position] = text
	end
	return row
end

local function ensureSeparator(frames, index)
	local separator = frames.separators[index]
	if separator then return separator end
	separator = frames.separatorLayer:CreateTexture(nil, "ARTWORK")
	frames.separators[index] = separator
	return separator
end

function Flow:EnsureFrames()
	local root = Timer:EnsureFrame()
	if self.frames and self.frames.root == root then return self.frames end
	local frames = { root = root }
	local container = CreateFrame("Frame", nil, root)
	container:SetAllPoints(root)
	container:SetFrameLevel(root:GetFrameLevel() + 1)
	container:EnableMouse(false)
	frames.container = container
	frames.background = ensureBackground(container, "BACKGROUND", -8)
	frames.outerBorder = ensureBorder(container)
	frames.separatorLayer = CreateFrame("Frame", nil, container)
	frames.separatorLayer:SetAllPoints(container)
	frames.separatorLayer:SetFrameLevel(container:GetFrameLevel() + 50)
	frames.separatorLayer:EnableMouse(false)
	frames.separators = {}

	local header = CreateFrame("Frame", nil, container)
	header.background = ensureBackground(header, "BACKGROUND", -4)
	frames.header = ensureSlotRow(header)
	frames.header.background = header.background

	local timerBar = CreateFrame("StatusBar", nil, container)
	timerBar.bg = ensureBackground(timerBar, "BACKGROUND", -4)
	timerBar.border = ensureBorder(timerBar)
	timerBar.markers = {}
	for index = 1, 2 do
		local marker = timerBar:CreateTexture(nil, "OVERLAY")
		marker:SetColorTexture(1, 1, 1, 0.85)
		timerBar.markers[index] = marker
	end
	frames.timer = ensureSlotRow(timerBar)
	frames.timer.bar = timerBar

	local objectives = CreateFrame("Frame", nil, container)
	objectives.rows = {}
	frames.objectives = objectives

	local enemyBar = CreateFrame("StatusBar", nil, container)
	enemyBar.bg = ensureBackground(enemyBar, "BACKGROUND", -4)
	enemyBar.border = ensureBorder(enemyBar)
	enemyBar.textLeft = enemyBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	enemyBar.textRight = enemyBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	enemyBar.textLeft:SetJustifyH("LEFT")
	enemyBar.textRight:SetJustifyH("RIGHT")
	frames.enemy = enemyBar

	local footer = CreateFrame("Frame", nil, container)
	footer.background = ensureBackground(footer, "BACKGROUND", -4)
	frames.footer = ensureSlotRow(footer)
	frames.footer.background = footer.background

	self.frames = frames
	return frames
end

local function ensureObjectiveRow(frames, index)
	local row = frames.objectives.rows[index]
	if row then return row end
	row = CreateFrame("Frame", nil, frames.objectives)
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.text:SetJustifyH("LEFT")
	row.value:SetJustifyH("RIGHT")
	row.text:SetJustifyV("MIDDLE")
	row.value:SetJustifyV("MIDDLE")
	frames.objectives.rows[index] = row
	return row
end

local function toPixels(value, region, minimum)
	local pixels = addon.PixelUtil.UiToPixels(value, region, minimum)
	return pixels
end

local function fromPixels(value, region)
	return addon.PixelUtil.SizeFromPixels(region, value)
end

local function setRect(frame, root, left, top, right, bottom)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", root, "TOPLEFT", fromPixels(left, root), -fromPixels(top, root))
	frame:SetPoint("BOTTOMRIGHT", root, "TOPLEFT", fromPixels(right, root), -fromPixels(bottom, root))
end

local function applyBorder(frame, enabled, textureKey, color, sizePixels)
	if not frame then return end
	if not enabled then
		frame:SetBackdrop(nil)
		frame:Hide()
		return
	end
	local edgeFile = resolveMedia("border", textureKey, WHITE_TEXTURE)
	frame:SetBackdrop({ edgeFile = edgeFile, edgeSize = fromPixels(clamp(sizePixels, 1, 32, 1), frame) })
	color = normalizeColor(color)
	frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
	frame:Show()
end

local function sectionDefinition(flow, name, enabled, root)
	if not enabled then return nil end
	return {
		name = name,
		height = toPixels(flow:Get(name .. "Height"), root, 1),
		gap = toPixels(flow:Get(name .. "Gap"), root),
		insetLeft = toPixels(flow:Get(name .. "InsetLeft"), root),
		insetRight = toPixels(flow:Get(name .. "InsetRight"), root),
	}
end

function Flow:BuildGeometry(state, objectiveHeights)
	local root = Timer:EnsureFrame()
	local width = math.max(20, toPixels(clamp(self:Get("width"), 120, 800, self.defaults.width), root, 20))
	local paddingLeft = math.max(0, toPixels(self:Get("paddingLeft"), root))
	local paddingRight = math.max(0, toPixels(self:Get("paddingRight"), root))
	local paddingTop = math.max(0, toPixels(self:Get("paddingTop"), root))
	local paddingBottom = math.max(0, toPixels(self:Get("paddingBottom"), root))
	local sections = {}
	sections[#sections + 1] = sectionDefinition(self, "header", self:Get("headerEnabled") == true, root)
	sections[#sections + 1] = sectionDefinition(self, "timer", self:Get("timerEnabled") == true, root)
	if self:Get("objectivesEnabled") == true and objectiveHeights and #objectiveHeights > 0 then
		local height = 0
		local spacing = math.max(0, toPixels(self:Get("objectivesSpacing"), root))
		for index, rowHeight in ipairs(objectiveHeights) do
			height = height + rowHeight
			if index > 1 then height = height + spacing end
		end
		sections[#sections + 1] = {
			name = "objectives",
			height = height,
			gap = toPixels(self:Get("objectivesGap"), root),
			insetLeft = toPixels(self:Get("objectivesInsetLeft"), root),
			insetRight = toPixels(self:Get("objectivesInsetRight"), root),
		}
	end
	sections[#sections + 1] = sectionDefinition(self, "enemy", self:Get("enemyEnabled") == true and state and state.enemyForces ~= nil, root)
	sections[#sections + 1] = sectionDefinition(self, "footer", self:Get("footerEnabled") == true, root)

	local compact = {}
	for _, section in ipairs(sections) do if section then compact[#compact + 1] = section end end
	local cursor = paddingTop
	for index, section in ipairs(compact) do
		section.left = paddingLeft + math.max(0, section.insetLeft)
		section.right = width - paddingRight - math.max(0, section.insetRight)
		if section.right <= section.left then section.right = section.left + 1 end
		section.top = cursor
		section.bottom = cursor + math.max(1, section.height)
		cursor = section.bottom
		if index < #compact then cursor = cursor + math.max(0, section.gap) end
	end
	return { width = width, height = cursor + paddingBottom, paddingLeft = paddingLeft, paddingRight = paddingRight, sections = compact }
end

local function getSection(geometry, name)
	for _, section in ipairs(geometry.sections) do if section.name == name then return section end end
	return nil
end

local function affixText(flow, state, size)
	local names = state and state.affixNames
	if type(names) ~= "table" then return "" end
	local parts = {}
	local mode = flow:Get("affixDisplay")
	for index, name in ipairs(names) do
		local icon = state.affixIcons and state.affixIcons[index]
		if mode == "ICON" and icon then
			parts[#parts + 1] = string.format("|T%s:%d:%d:0:0|t", tostring(icon), size, size)
		elseif mode == "ICON_TEXT" and icon then
			parts[#parts + 1] = string.format("|T%s:%d:%d:0:0|t %s", tostring(icon), size, size, name)
		else
			parts[#parts + 1] = name
		end
	end
	return table.concat(parts, mode == "ICON" and " " or " - ")
end

local function dungeonText(flow, timer, state)
	local name = state.mapName or (L["mythicPlusTimerUnknownDungeon"] or "Mythic+ Dungeon")
	local short = timer:GetDungeonAbbreviation(state) or name
	local level = tonumber(state.level) or 0
	local mode = flow:Get("dungeonDisplay")
	if mode == "LEVEL" then return string.format("+%d", level) end
	if mode == "NAME" then return name end
	if mode == "SHORT" then return short end
	if mode == "SHORT_LEVEL" then return string.format("+%d - %s", level, short) end
	return string.format("+%d - %s", level, name)
end

local function timerText(flow, state, timeLeft)
	local elapsed = tonumber(state.elapsed) or 0
	local total = tonumber(state.timeLimit) or 0
	local mode = flow:Get("timerDisplay")
	if state.completed then
		if mode == "TOTAL" then return secondsText(total) end
		if mode == "TIME_LEFT_TOTAL" or mode == "ELAPSED_TOTAL" then return string.format("%s / %s", secondsText(elapsed), secondsText(total)) end
		return secondsText(elapsed)
	end
	if mode == "TOTAL" then return secondsText(total) end
	if mode == "ELAPSED_TOTAL" then return string.format("%s / %s", secondsText(elapsed), secondsText(total)) end
	if mode == "TIME_LEFT_TOTAL" then return string.format("%s / %s", secondsText(timeLeft), secondsText(total)) end
	return secondsText(timeLeft)
end

local function slotText(flow, timer, content, state, timeLeft, twoChest, threeChest, iconSize)
	if content == "DUNGEON" then return dungeonText(flow, timer, state) end
	if content == "KEY_LEVEL" then return string.format("+%d", tonumber(state.level) or 0) end
	if content == "AFFIXES" then return affixText(flow, state, iconSize) end
	if content == "DEATHS" then
		local deaths = tonumber(state.deaths) or 0
		if deaths <= 0 and not state.preview then return "" end
		if flow:Get("deathDisplay") == "TEXT" then return string.format("%d %s", deaths, L["mythicPlusTimerDeaths"] or "Deaths") end
		if flow:Get("deathDisplay") == "ICON_TEXT" then return string.format("|A:%s:%d:%d|a %d %s", DEATH_ICON_ATLAS, iconSize, iconSize, deaths, L["mythicPlusTimerDeaths"] or "Deaths") end
		return string.format("|A:%s:%d:%d|a %d", DEATH_ICON_ATLAS, iconSize, iconSize, deaths)
	end
	if content == "TIMER" then return timerText(flow, state, timeLeft) end
	if content == "CHEST_2" then
		local remaining = (tonumber(twoChest) or 0) - (tonumber(state.elapsed) or 0)
		return remaining >= 0 and secondsText(remaining) or ""
	end
	if content == "CHEST_3" then
		local remaining = (tonumber(threeChest) or 0) - (tonumber(state.elapsed) or 0)
		return remaining >= 0 and secondsText(remaining) or ""
	end
	if content == "BEST_TIME" then
		local best = timer:GetBestTime(state)
		if state.preview then best = 1612 end
		return best and secondsText(best) or ""
	end
	if content == "ENEMY_PERCENT" then return string.format("%.2f%%", tonumber(state.enemyForces and state.enemyForces.percent) or 0) end
	return ""
end

local function contentColor(flow, content)
	if content == "DUNGEON" or content == "KEY_LEVEL" then return normalizeColor(flow:Get("dungeonColor"), flow.defaults.dungeonColor) end
	if content == "DEATHS" then return normalizeColor(flow:Get("deathColor"), flow.defaults.deathColor) end
	return normalizeColor(flow:Get("textColor"), flow.defaults.textColor)
end

local function layoutSlotRow(flow, timer, row, section, sectionName, state, timeLeft, twoChest, threeChest)
	local frame = row.frame
	setRect(frame, flow.frames.root, section.left, section.top, section.right, section.bottom)
	local width = section.right - section.left
	local face = resolveFont(flow:Get("fontFace"))
	local style = resolveFontStyle(flow:Get("fontOutline"))
	local fontSize = clamp(flow:Get(sectionName .. "FontSize"), 8, 56, 16)
	for index, position in ipairs({ "Left", "Center", "Right" }) do
		local text = row.slots[position]
		local left = math.floor(width * (index - 1) / 3)
		local right = math.floor(width * index / 3)
		local inset = math.min(2, math.max(0, math.floor((right - left - 1) / 2)))
		local offsetX = toPixels(flow:Get(sectionName .. "Slot" .. position .. "OffsetX"), frame)
		local offsetY = toPixels(flow:Get(sectionName .. "Slot" .. position .. "OffsetY"), frame)
		text:ClearAllPoints()
		if position == "Left" then
			text:SetPoint("LEFT", frame, "LEFT", fromPixels(left + inset + offsetX, frame), fromPixels(offsetY, frame))
		elseif position == "Center" then
			text:SetPoint("CENTER", frame, "LEFT", fromPixels(math.floor((left + right) / 2) + offsetX, frame), fromPixels(offsetY, frame))
		else
			text:SetPoint("RIGHT", frame, "LEFT", fromPixels(right - inset + offsetX, frame), fromPixels(offsetY, frame))
		end
		local content = flow:Get(slotKey(sectionName, position))
		local slotFontSize = fontSize
		if content == "AFFIXES" then
			slotFontSize = clamp(flow:Get("affixFontSize"), 8, 56, fontSize)
		elseif content == "DEATHS" then
			slotFontSize = clamp(flow:Get("deathFontSize"), 8, 56, fontSize)
		end
		applyFont(text, face, slotFontSize, style)
		local actualText = slotText(flow, timer, content, state, timeLeft, twoChest, threeChest, math.max(8, slotFontSize - 2))
		text:SetText(actualText)
		local color = contentColor(flow, content)
		text:SetTextColor(color.r, color.g, color.b, color.a)
		text:Show()
	end
	frame:Show()
end

function Flow:LayoutSeparators(geometry)
	local frames = self.frames
	local enabled = self:Get("borderEnabled") == true
	local color = normalizeColor(self:Get("borderColor"), self.defaults.borderColor)
	local size = math.max(1, toPixels(self:Get("borderSize"), frames.root, 1))
	local count = enabled and math.max(0, #geometry.sections - 1) or 0
	for index = 1, count do
		local section = geometry.sections[index]
		local y = section.bottom + math.floor(math.max(0, section.gap or 0) / 2)
		local separator = ensureSeparator(frames, index)
		separator:SetColorTexture(color.r, color.g, color.b, color.a)
		setRect(separator, frames.root, geometry.paddingLeft, y, geometry.width - geometry.paddingRight, y + size)
		separator:Show()
	end
	for index = count + 1, #frames.separators do frames.separators[index]:Hide() end
	frames.separatorLayer:SetShown(count > 0)
end

local function objectiveDeltaText(delta)
	local numeric = tonumber(delta) or 0
	local seconds = math.floor(math.abs(numeric) + 0.5)
	local sign = numeric < 0 and "-" or "+"
	if seconds >= 60 then return string.format("%s%d:%02d", sign, math.floor(seconds / 60), seconds % 60) end
	return string.format("%s%ds", sign, seconds)
end

local function objectiveValue(flow, timer, state, objective)
	local parts = {}
	if flow:Get("objectivesShowValues") == true and objective.total and objective.total > 0 then parts[#parts + 1] = string.format("%d/%d", objective.quantity or 0, objective.total) end
	if flow:Get("objectivesShowTimes") == true and objective.splitTime then
		local timeText = secondsText(objective.splitTime)
		if flow:Get("objectivesShowBestTimes") == true then
			local best = state and state.preview and objective.bestTime or objective.previousBestTime
			if not best and not (state and state.active) then best = timer:GetBestObjectiveTime(state, objective.text) end
			if best then timeText = string.format("%s (%s)", timeText, objectiveDeltaText(objective.splitTime - best)) end
		end
		parts[#parts + 1] = timeText
	end
	return table.concat(parts, " - ")
end

function Flow:PrepareObjectives(state)
	local frames = self:EnsureFrames()
	local source = state and state.objectives or {}
	local visible = {}
	for _, objective in ipairs(source) do
		if self:Get("objectivesHideNonBoss") ~= true or objective.isBoss == true then visible[#visible + 1] = objective end
	end
	local root = frames.root
	local baseHeight = math.max(1, toPixels(self:Get("objectivesRowHeight"), root, 1))
	local rowHeights = {}
	local valueWidth = 0
	local face = resolveFont(self:Get("fontFace"))
	local style = resolveFontStyle(self:Get("fontOutline"))
	local fontSize = clamp(self:Get("objectivesFontSize"), 8, 56, 18)
	for index, objective in ipairs(visible) do
		local row = ensureObjectiveRow(frames, index)
		applyFont(row.text, face, fontSize, style)
		applyFont(row.value, face, fontSize, style)
		local value = objectiveValue(self, Timer, state, objective)
		row.value:SetText(value)
		valueWidth = math.max(valueWidth, toPixels((row.value.GetUnboundedStringWidth and row.value:GetUnboundedStringWidth() or row.value:GetStringWidth() or 0) + 2, root))
		rowHeights[index] = baseHeight
	end
	if self:Get("objectivesSingleLine") ~= true and #visible > 0 then
		local width = math.max(20, toPixels(clamp(self:Get("width"), 120, 800, self.defaults.width), root, 20))
		local available = width - math.max(0, toPixels(self:Get("paddingLeft"), root)) - math.max(0, toPixels(self:Get("paddingRight"), root))
		available = available - math.max(0, toPixels(self:Get("objectivesInsetLeft"), root)) - math.max(0, toPixels(self:Get("objectivesInsetRight"), root))
		available = math.max(1, available - math.max(0, toPixels(self:Get("objectivesPaddingLeft"), root)) - math.max(0, toPixels(self:Get("objectivesPaddingRight"), root)))
		valueWidth = math.min(math.floor(available * 0.65), math.max(0, valueWidth))
		local textWidth = math.max(1, available - valueWidth - math.max(0, toPixels(self:Get("objectivesColumnGap"), root)))
		for index, objective in ipairs(visible) do
			local row = ensureObjectiveRow(frames, index)
			row.text:SetWidth(fromPixels(textWidth, row))
			row.text:SetWordWrap(true)
			row.text:SetNonSpaceWrap(false)
			if row.text.SetMaxLines then row.text:SetMaxLines(0) end
			row.text:SetText(objective.text or "")
			local measured = toPixels((row.text.GetStringHeight and row.text:GetStringHeight() or fontSize) + 2, root, baseHeight)
			rowHeights[index] = math.max(baseHeight, measured)
		end
	end
	return visible, rowHeights, valueWidth
end

function Flow:LayoutObjectives(state, geometry, objectives, rowHeights, valueWidth)
	local frames = self.frames
	local section = getSection(geometry, "objectives")
	if not section then
		frames.objectives:Hide()
		for _, row in ipairs(frames.objectives.rows) do row:Hide() end
		return
	end
	setRect(frames.objectives, frames.root, section.left, section.top, section.right, section.bottom)
	local root = frames.root
	local spacing = math.max(0, toPixels(self:Get("objectivesSpacing"), root))
	local paddingLeft = math.max(0, toPixels(self:Get("objectivesPaddingLeft"), root))
	local paddingRight = math.max(0, toPixels(self:Get("objectivesPaddingRight"), root))
	local columnGap = math.max(0, toPixels(self:Get("objectivesColumnGap"), root))
	local available = math.max(1, section.right - section.left - paddingLeft - paddingRight)
	valueWidth = math.min(math.floor(available * 0.65), math.max(0, valueWidth))
	local rowWidth = section.right - section.left
	local labelRight = math.max(paddingLeft + 1, rowWidth - paddingRight - valueWidth - columnGap)
	local labelOffsetX = toPixels(self:Get("objectivesLabelOffsetX"), root)
	local labelOffsetY = toPixels(self:Get("objectivesLabelOffsetY"), root)
	local valueOffsetX = toPixels(self:Get("objectivesValueOffsetX"), root)
	local valueOffsetY = toPixels(self:Get("objectivesValueOffsetY"), root)
	local face = resolveFont(self:Get("fontFace"))
	local style = resolveFontStyle(self:Get("fontOutline"))
	local fontSize = clamp(self:Get("objectivesFontSize"), 8, 56, 18)
	local cursor = 0
	for index, objective in ipairs(objectives) do
		local row = ensureObjectiveRow(frames, index)
		local height = rowHeights[index]
		setRect(row, frames.objectives, 0, cursor, section.right - section.left, cursor + height)
		applyFont(row.text, face, fontSize, style)
		applyFont(row.value, face, fontSize, style)
		row.text:SetText(objective.text or "")
		row.value:SetText(objectiveValue(self, Timer, state, objective))
		local color = normalizeColor(objective.completed and self:Get("objectiveCompleteColor") or self:Get("objectiveColor"), self.defaults.objectiveColor)
		row.text:SetTextColor(color.r, color.g, color.b, color.a)
		row.value:SetTextColor(color.r, color.g, color.b, color.a)
		row.text:ClearAllPoints()
		row.value:ClearAllPoints()
		row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", fromPixels(-paddingRight + valueOffsetX, row), fromPixels(valueOffsetY, row))
		row.value:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", fromPixels(-paddingRight + valueOffsetX, row), fromPixels(valueOffsetY, row))
		row.value:SetWidth(fromPixels(valueWidth, row))
		row.text:SetPoint("TOPLEFT", row, "TOPLEFT", fromPixels(paddingLeft + labelOffsetX, row), fromPixels(labelOffsetY, row))
		row.text:SetPoint("BOTTOMRIGHT", row, "BOTTOMLEFT", fromPixels(labelRight + labelOffsetX, row), fromPixels(labelOffsetY, row))
		row.text:SetWordWrap(self:Get("objectivesSingleLine") ~= true)
		if row.text.SetMaxLines then row.text:SetMaxLines(self:Get("objectivesSingleLine") == true and 1 or 0) end
		row:Show()
		cursor = cursor + height + spacing
	end
	for index = #objectives + 1, #frames.objectives.rows do frames.objectives.rows[index]:Hide() end
	frames.objectives:Show()
end

function Flow:Render(state, timeLeft, twoChest, threeChest)
	local frames = self:EnsureFrames()
	self:EnsureConfig()
	local objectives, rowHeights, valueWidth = self:PrepareObjectives(state)
	local geometry = self:BuildGeometry(state, rowHeights)
	frames.root:SetSize(fromPixels(geometry.width, frames.root), fromPixels(geometry.height, frames.root))
	frames.container:SetAllPoints(frames.root)

	frames.background:SetShown(self:Get("backgroundEnabled") == true)
	if frames.background:IsShown() then
		applyTexture(frames.background, "statusbar", self:Get("backgroundTexture"), WHITE_TEXTURE)
		setTextureColor(frames.background, self:Get("backgroundColor"))
	end
	applyBorder(frames.outerBorder, self:Get("borderEnabled") == true, self:Get("borderTexture"), self:Get("borderColor"), self:Get("borderSize"))
	self:LayoutSeparators(geometry)

	local header = getSection(geometry, "header")
	if header then
		layoutSlotRow(self, Timer, frames.header, header, "header", state, timeLeft, twoChest, threeChest)
		frames.header.background:SetShown(self:Get("headerBackgroundEnabled") == true)
		if frames.header.background:IsShown() then
			applyTexture(frames.header.background, "statusbar", self:Get("headerBackgroundTexture"), WHITE_TEXTURE)
			setTextureColor(frames.header.background, self:Get("headerBackgroundColor"))
		end
	else
		frames.header.frame:Hide()
	end

	local timerSection = getSection(geometry, "timer")
	if timerSection then
		local bar = frames.timer.bar
		layoutSlotRow(self, Timer, frames.timer, timerSection, "timer", state, timeLeft, twoChest, threeChest)
		bar:SetStatusBarTexture(resolveMedia("statusbar", self:Get("timerTexture"), WHITE_TEXTURE))
		if addon.PixelUtil and addon.PixelUtil.ApplyStatusBarTexturePixelSnapping then addon.PixelUtil.ApplyStatusBarTexturePixelSnapping(bar, 0) end
		applyTexture(bar.bg, "statusbar", self:Get("timerBackgroundTexture"), WHITE_TEXTURE)
		setTextureColor(bar.bg, self:Get("timerBackgroundColor"))
		local expired = (tonumber(timeLeft) or 0) <= 0
		local color = normalizeColor(expired and self:Get("timerExpiredColor") or self:Get("timerColor"), self.defaults.timerColor)
		bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
		bar:SetMinMaxValues(0, math.max(1, tonumber(state.timeLimit) or 1))
		bar:SetValue(self:Get("timerFillUp") == true and math.max(0, tonumber(state.elapsed) or 0) or math.max(0, tonumber(timeLeft) or 0))
		applyBorder(bar.border, self:Get("timerBorderEnabled") == true, self:Get("timerBorderTexture"), self:Get("timerBorderColor"), self:Get("timerBorderSize"))
		local markerTimes = { threeChest, twoChest }
		for index, marker in ipairs(bar.markers) do
			local duration = tonumber(state.timeLimit) or 0
			local markerTime = tonumber(markerTimes[index]) or 0
			local show = self:Get("timerChestMarkers") == true and duration > 0 and markerTime > 0
			marker:SetShown(show)
			if show then
				local width = timerSection.right - timerSection.left
				local x = math.floor(width * math.max(0, math.min(1, markerTime / duration)) + 0.5)
				marker:ClearAllPoints()
				marker:SetPoint("TOPLEFT", bar, "TOPLEFT", fromPixels(x, bar), 0)
				marker:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", fromPixels(x, bar), 0)
				marker:SetWidth(fromPixels(1, bar))
			end
		end
		bar:Show()
	else
		frames.timer.frame:Hide()
	end

	self:LayoutObjectives(state, geometry, objectives, rowHeights, valueWidth)

	local enemySection = getSection(geometry, "enemy")
	if enemySection then
		local bar = frames.enemy
		setRect(bar, frames.root, enemySection.left, enemySection.top, enemySection.right, enemySection.bottom)
		bar:SetStatusBarTexture(resolveMedia("statusbar", self:Get("enemyTexture"), WHITE_TEXTURE))
		if addon.PixelUtil and addon.PixelUtil.ApplyStatusBarTexturePixelSnapping then addon.PixelUtil.ApplyStatusBarTexturePixelSnapping(bar, 0) end
		applyTexture(bar.bg, "statusbar", self:Get("enemyBackgroundTexture"), WHITE_TEXTURE)
		setTextureColor(bar.bg, self:Get("enemyBackgroundColor"))
		local color = normalizeColor(self:Get("enemyColor"), self.defaults.enemyColor)
		bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
		bar:SetMinMaxValues(0, 100)
		bar:SetValue(math.max(0, math.min(100, tonumber(state.enemyForces and state.enemyForces.percent) or 0)))
		applyBorder(bar.border, self:Get("enemyBorderEnabled") == true, self:Get("enemyBorderTexture"), self:Get("enemyBorderColor"), self:Get("enemyBorderSize"))
		local face = resolveFont(self:Get("fontFace"))
		local style = resolveFontStyle(self:Get("fontOutline"))
		local fontSize = clamp(self:Get("enemyFontSize"), 8, 56, 18)
		local enemy = state.enemyForces or {}
		local count = enemy.total and enemy.total > 0 and string.format("%d/%d", enemy.quantity or 0, enemy.total) or ""
		local percent = string.format("%.2f%%", tonumber(enemy.percent) or 0)
		bar.textLeft:SetText(self:Get("enemySlotLeft") == "PERCENT" and percent or count)
		bar.textRight:SetText(self:Get("enemySlotRight") == "COUNT" and count or percent)
		for _, text in ipairs({ bar.textLeft, bar.textRight }) do
			applyFont(text, face, fontSize, style)
			local textColor = normalizeColor(self:Get("textColor"), self.defaults.textColor)
			text:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
		end
		local leftOffsetX = toPixels(self:Get("enemySlotLeftOffsetX"), bar)
		local leftOffsetY = toPixels(self:Get("enemySlotLeftOffsetY"), bar)
		local rightOffsetX = toPixels(self:Get("enemySlotRightOffsetX"), bar)
		local rightOffsetY = toPixels(self:Get("enemySlotRightOffsetY"), bar)
		bar.textLeft:ClearAllPoints()
		bar.textLeft:SetPoint("LEFT", bar, "LEFT", fromPixels(3 + leftOffsetX, bar), fromPixels(leftOffsetY, bar))
		bar.textLeft:SetPoint("RIGHT", bar, "CENTER", fromPixels(leftOffsetX, bar), fromPixels(leftOffsetY, bar))
		bar.textRight:ClearAllPoints()
		bar.textRight:SetPoint("LEFT", bar, "CENTER", fromPixels(rightOffsetX, bar), fromPixels(rightOffsetY, bar))
		bar.textRight:SetPoint("RIGHT", bar, "RIGHT", fromPixels(-3 + rightOffsetX, bar), fromPixels(rightOffsetY, bar))
		bar:Show()
	else
		frames.enemy:Hide()
	end

	local footer = getSection(geometry, "footer")
	if footer then
		layoutSlotRow(self, Timer, frames.footer, footer, "footer", state, timeLeft, twoChest, threeChest)
		frames.footer.background:SetShown(self:Get("footerBackgroundEnabled") == true)
		if frames.footer.background:IsShown() then
			applyTexture(frames.footer.background, "statusbar", self:Get("footerBackgroundTexture"), WHITE_TEXTURE)
			setTextureColor(frames.footer.background, self:Get("footerBackgroundColor"))
		end
	else
		frames.footer.frame:Hide()
	end

	frames.container:Show()
	return fromPixels(geometry.height, frames.root)
end

function Flow:Hide()
	if self.frames and self.frames.container then self.frames.container:Hide() end
end

local function buildMediaOptions(mediaType, includeGlobal)
	local options = {}
	if includeGlobal and mediaType == "font" then options[#options + 1] = { value = GLOBAL_FONT_KEY, label = L["useGlobalFontConfig"] or "Use global font config" } end
	options[#options + 1] = { value = "", label = _G.DEFAULT or "Default" }
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType) or {}
	for _, name in ipairs(names) do options[#options + 1] = { value = name, label = name } end
	return options
end

local function buildStyleOptions()
	return {
		{ value = GLOBAL_STYLE_KEY, label = L["useGlobalFontConfig"] or "Use global font config" },
		{ value = "NONE", label = _G.NONE or "None" },
		{ value = "OUTLINE", label = L["Font outline"] or "Font outline" },
		{ value = "THICKOUTLINE", label = "Thick outline" },
	}
end

function Flow:BuildEditModeSettings(SettingType)
	if not SettingType then return {} end
	local function visible() return Timer.GetLayoutMode and Timer:GetLayoutMode() == "FLOW" end
	local function get(key) return function() return Flow:Get(key) end end
	local function checkbox(name, key, parentId, newTagID)
		return { name = name, kind = SettingType.Checkbox, parentId = parentId, isShown = visible, newTagID = newTagID, get = get(key), set = function(_, value) Flow:Set(key, value == true) end }
	end
	local function formatterForStep(step)
		local numericStep = tonumber(step)
		if numericStep and numericStep < 1 then
			return function(value)
				local formatted = string.format("%.1f", tonumber(value) or 0)
				return (formatted:gsub("%.0$", ""))
			end
		end
		return nil
	end
	local function slider(name, key, minimum, maximum, step, parentId, newTagID)
		-- All local content anchors intentionally share one range, including future
		-- X/Y offset controls added to the Flow schema.
		if type(key) == "string" and Flow.defaults[key] ~= nil and key:match("Offset[XY]$") then
			minimum = -CONTENT_OFFSET_LIMIT
			maximum = CONTENT_OFFSET_LIMIT
		end
		return { name = name, kind = SettingType.Slider, parentId = parentId, isShown = visible, newTagID = newTagID, minValue = minimum, maxValue = maximum, valueStep = step or 1, allowInput = true, formatter = formatterForStep(step), get = get(key), set = function(_, value) Flow:Set(key, clamp(value, minimum, maximum, Flow.defaults[key])) end }
	end
	local function pairedSlider(name, firstKey, secondKey, minimum, maximum, step, parentId, newTagID)
		return {
			name = name,
			kind = SettingType.Slider,
			parentId = parentId,
			isShown = visible,
			newTagID = newTagID,
			minValue = minimum,
			maxValue = maximum,
			valueStep = step or 1,
			allowInput = true,
			formatter = formatterForStep(step),
			get = get(firstKey),
			set = function(_, value)
				value = clamp(value, minimum, maximum, Flow.defaults[firstKey])
				local config = getConfig(true)
				config[firstKey] = value
				config[secondKey] = value
				Timer:Refresh()
			end,
		}
	end
	local function dropdown(name, key, options, parentId, newTagID, setter)
		return {
			name = name,
			kind = SettingType.Dropdown,
			parentId = parentId,
			isShown = visible,
			newTagID = newTagID,
			get = get(key),
			set = function(_, value) (setter or function(entry) Flow:Set(key, entry) end)(value) end,
			generator = function(_, root)
				for _, option in ipairs(type(options) == "function" and options() or options) do
					root:CreateRadio(option.label, function() return Flow:Get(key) == option.value end, function() (setter or function(entry) Flow:Set(key, entry) end)(option.value) end)
				end
			end,
		}
	end
	local function color(name, key, parentId, newTagID)
		return { name = name, kind = SettingType.Color, parentId = parentId, isShown = visible, newTagID = newTagID, hasOpacity = true, default = Flow.defaults[key], get = get(key), set = function(_, value) Flow:Set(key, normalizeColor(value, Flow.defaults[key])) end }
	end
	local function section(name, id, newTagID, collapsed)
		return { name = name, kind = SettingType.Collapsible, id = id, defaultCollapsed = collapsed ~= false, isShown = visible, newTagID = newTagID }
	end
	local slotOptions = {
		{ value = "NONE", label = _G.NONE or "None" },
		{ value = "DUNGEON", label = L["mythicPlusTimerPanelDungeonAndKey"] or "Dungeon and key" },
		{ value = "KEY_LEVEL", label = L["mythicPlusTimerDungeonDisplayLevel"] or "Key level" },
		{ value = "AFFIXES", label = L["mythicPlusTimerPanelAffixes"] or "Affixes" },
		{ value = "DEATHS", label = L["mythicPlusTimerDeaths"] or "Deaths" },
		{ value = "TIMER", label = L["mythicPlusTimerPanelTimerAndTiers"] or "Timer" },
		{ value = "CHEST_2", label = "+2" },
		{ value = "CHEST_3", label = "+3" },
		{ value = "BEST_TIME", label = L["mythicPlusTimerPanelBestTime"] or "Best time" },
		{ value = "ENEMY_PERCENT", label = L["mythicPlusTimerEnemyForces"] or "Enemy Forces" },
	}
	local alignOptions = {
		{ value = "COUNT", label = L["mythicPlusTimerEnemyForcesCount"] or "Count" },
		{ value = "PERCENT", label = _G.STATUS_TEXT_PERCENT or "Percentage" },
	}
	local timerDisplayOptions = {
		{ value = "TIME_LEFT", label = L["mythicPlusTimerTimerDisplayTimeLeft"] or "Time left" },
		{ value = "TIME_LEFT_TOTAL", label = L["mythicPlusTimerTimerDisplayTimeLeftTotal"] or "Time left / total time" },
		{ value = "ELAPSED_TOTAL", label = L["mythicPlusTimerTimerDisplayElapsedTotal"] or "Time elapsed / total time" },
		{ value = "TOTAL", label = L["mythicPlusTimerTimerDisplayTotal"] or "Total time" },
	}
	local slotLabels = {
		Left = L["mythicPlusTimerFlowSlotLeft"] or "Left slot",
		Center = L["mythicPlusTimerFlowSlotCenter"] or "Center slot",
		Right = L["mythicPlusTimerFlowSlotRight"] or "Right slot",
	}
	local function slotOffsetLabel(position, axis)
		return string.format("%s: %s", slotLabels[position], axis == "X" and (L["Offset X"] or "Offset X") or (L["Offset Y"] or "Offset Y"))
	end
	local function contentFontSizeLabel(contentLabel)
		return string.format("%s: %s", contentLabel, L["Text size"] or "Text size")
	end
	local settings = {
		section(L["mythicPlusTimerFlowLayout"] or "Flow layout", "mpt-flow-layout", "mythicPlusTimerFlowLayoutSection", false),
		slider(L["mythicPlusTimerWidth"] or "Width", "width", 120, 800, 0.1, "mpt-flow-layout", "mythicPlusTimerFlowWidth"),
		pairedSlider(L["mythicPlusTimerFlowPaddingHorizontal"] or "Horizontal padding", "paddingLeft", "paddingRight", 0, 100, 0.1, "mpt-flow-layout", "mythicPlusTimerFlowPaddingHorizontal"),
		pairedSlider(L["mythicPlusTimerFlowPaddingVertical"] or "Vertical padding", "paddingTop", "paddingBottom", 0, 100, 0.1, "mpt-flow-layout", "mythicPlusTimerFlowPaddingVertical"),
		checkbox(L["mythicPlusTimerBackdropEnabled"] or "Use background", "backgroundEnabled", "mpt-flow-layout", "mythicPlusTimerFlowBackground"),
		dropdown(L["mythicPlusTimerBackdropTexture"] or "Background texture", "backgroundTexture", function() return buildMediaOptions("statusbar", false) end, "mpt-flow-layout", "mythicPlusTimerFlowBackgroundTexture"),
		color(L["mythicPlusTimerBackdropColor"] or "Background color", "backgroundColor", "mpt-flow-layout", "mythicPlusTimerFlowBackgroundColor"),
		checkbox(L["mythicPlusTimerBorderEnabled"] or "Use border", "borderEnabled", "mpt-flow-layout", "mythicPlusTimerFlowBorder"),
		dropdown(L["mythicPlusTimerBorderTexture"] or "Border texture", "borderTexture", function() return buildMediaOptions("border", false) end, "mpt-flow-layout", "mythicPlusTimerFlowBorderTexture"),
		color(L["mythicPlusTimerBorderColor"] or "Border color", "borderColor", "mpt-flow-layout", "mythicPlusTimerFlowBorderColor"),
		slider(L["mythicPlusTimerBorderSize"] or "Border size", "borderSize", 1, 32, 1, "mpt-flow-layout", "mythicPlusTimerFlowBorderSize"),

		section(L["Header"] or "Header", "mpt-flow-header", "mythicPlusTimerFlowHeaderSection"),
		checkbox(L["Enabled"] or "Enabled", "headerEnabled", "mpt-flow-header", "mythicPlusTimerFlowHeaderEnabled"),
		slider(L["Height"] or "Height", "headerHeight", 8, 100, 0.1, "mpt-flow-header", "mythicPlusTimerFlowHeaderHeight"),
		slider(L["Text size"] or "Text size", "headerFontSize", 8, 56, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderFontSize"),
		slider(L["Spacing"] or "Spacing", "headerGap", 0, 50, 0.1, "mpt-flow-header", "mythicPlusTimerFlowHeaderGap"),
		dropdown(L["mythicPlusTimerFlowSlotLeft"] or "Left slot", "headerSlotLeft", slotOptions, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotLeft", function(value) Flow:SetSlot("header", "Left", value) end),
		slider(slotOffsetLabel("Left", "X"), "headerSlotLeftOffsetX", -50, 50, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotLeftOffsetX"),
		slider(slotOffsetLabel("Left", "Y"), "headerSlotLeftOffsetY", -20, 20, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotLeftOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotCenter"] or "Center slot", "headerSlotCenter", slotOptions, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotCenter", function(value) Flow:SetSlot("header", "Center", value) end),
		slider(slotOffsetLabel("Center", "X"), "headerSlotCenterOffsetX", -50, 50, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotCenterOffsetX"),
		slider(slotOffsetLabel("Center", "Y"), "headerSlotCenterOffsetY", -20, 20, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotCenterOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotRight"] or "Right slot", "headerSlotRight", slotOptions, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotRight", function(value) Flow:SetSlot("header", "Right", value) end),
		slider(slotOffsetLabel("Right", "X"), "headerSlotRightOffsetX", -50, 50, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotRightOffsetX"),
		slider(slotOffsetLabel("Right", "Y"), "headerSlotRightOffsetY", -20, 20, 1, "mpt-flow-header", "mythicPlusTimerFlowHeaderSlotRightOffsetY"),
		color(L["damageMeterHeaderBackgroundColor"] or "Color", "headerBackgroundColor", "mpt-flow-header", "mythicPlusTimerFlowHeaderColor"),
		dropdown(L["mythicPlusTimerBackdropTexture"] or "Background texture", "headerBackgroundTexture", function() return buildMediaOptions("statusbar", false) end, "mpt-flow-header", "mythicPlusTimerFlowHeaderTexture"),

		section(L["mythicPlusTimerPanelTimerAndTiers"] or "Timer", "mpt-flow-timer", "mythicPlusTimerFlowTimerSection"),
		checkbox(L["Enabled"] or "Enabled", "timerEnabled", "mpt-flow-timer", "mythicPlusTimerFlowTimerEnabled"),
		slider(L["Height"] or "Height", "timerHeight", 4, 100, 0.1, "mpt-flow-timer", "mythicPlusTimerFlowTimerHeight"),
		slider(L["Text size"] or "Text size", "timerFontSize", 8, 56, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerFontSize"),
		slider(L["Spacing"] or "Spacing", "timerGap", 0, 50, 0.1, "mpt-flow-timer", "mythicPlusTimerFlowTimerGap"),
		dropdown(L["mythicPlusTimerFlowSlotLeft"] or "Left slot", "timerSlotLeft", slotOptions, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotLeft", function(value) Flow:SetSlot("timer", "Left", value) end),
		slider(slotOffsetLabel("Left", "X"), "timerSlotLeftOffsetX", -50, 50, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotLeftOffsetX"),
		slider(slotOffsetLabel("Left", "Y"), "timerSlotLeftOffsetY", -20, 20, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotLeftOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotCenter"] or "Center slot", "timerSlotCenter", slotOptions, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotCenter", function(value) Flow:SetSlot("timer", "Center", value) end),
		slider(slotOffsetLabel("Center", "X"), "timerSlotCenterOffsetX", -50, 50, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotCenterOffsetX"),
		slider(slotOffsetLabel("Center", "Y"), "timerSlotCenterOffsetY", -20, 20, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotCenterOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotRight"] or "Right slot", "timerSlotRight", slotOptions, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotRight", function(value) Flow:SetSlot("timer", "Right", value) end),
		slider(slotOffsetLabel("Right", "X"), "timerSlotRightOffsetX", -50, 50, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotRightOffsetX"),
		slider(slotOffsetLabel("Right", "Y"), "timerSlotRightOffsetY", -20, 20, 1, "mpt-flow-timer", "mythicPlusTimerFlowTimerSlotRightOffsetY"),
		dropdown(L["mythicPlusTimerTimerDisplay"] or "Timer display", "timerDisplay", timerDisplayOptions, "mpt-flow-timer", "mythicPlusTimerFlowTimerDisplay"),
		color(L["mythicPlusTimerPanelTimerBarColor"] or "Timer bar color", "timerColor", "mpt-flow-timer", "mythicPlusTimerFlowTimerColor"),
		dropdown(L["Texture"] or "Texture", "timerTexture", function() return buildMediaOptions("statusbar", false) end, "mpt-flow-timer", "mythicPlusTimerFlowTimerTexture"),
		checkbox(L["mythicPlusTimerPanelTimerBarChestMarkers"] or "Show chest markers", "timerChestMarkers", "mpt-flow-timer", "mythicPlusTimerFlowTimerMarkers"),

		section(L["mythicPlusTimerPanelObjectives"] or "Objectives", "mpt-flow-objectives", "mythicPlusTimerFlowObjectivesSection"),
		checkbox(L["Enabled"] or "Enabled", "objectivesEnabled", "mpt-flow-objectives", "mythicPlusTimerFlowObjectivesEnabled"),
		slider(L["Height"] or "Height", "objectivesRowHeight", 8, 80, 0.1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveHeight"),
		slider(L["Text size"] or "Text size", "objectivesFontSize", 8, 56, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveFontSize"),
		slider(L["Spacing"] or "Spacing", "objectivesSpacing", 0, 24, 0.1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveSpacing"),
		pairedSlider(L["mythicPlusTimerFlowPaddingHorizontal"] or "Horizontal padding", "objectivesPaddingLeft", "objectivesPaddingRight", 0, 50, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectivePaddingHorizontal"),
		slider(L["mythicPlusTimerTextOffsetX"] or "Label X offset", "objectivesLabelOffsetX", -50, 50, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveLabelOffsetX"),
		slider(L["mythicPlusTimerTextOffsetY"] or "Label Y offset", "objectivesLabelOffsetY", -20, 20, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveLabelOffsetY"),
		slider(L["mythicPlusTimerValueOffsetX"] or "Value X offset", "objectivesValueOffsetX", -50, 50, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveValueOffsetX"),
		slider(L["mythicPlusTimerValueOffsetY"] or "Value Y offset", "objectivesValueOffsetY", -20, 20, 1, "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveValueOffsetY"),
		checkbox(L["mythicPlusTimerFlowObjectiveSingleLine"] or "Keep objectives on one line", "objectivesSingleLine", "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveSingleLine"),
		checkbox(L["mythicPlusTimerShowObjectiveValues"] or "Show objective values", "objectivesShowValues", "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveValues"),
		checkbox(L["mythicPlusTimerShowObjectiveTimes"] or "Show objective times", "objectivesShowTimes", "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveTimes"),
		checkbox(L["mythicPlusTimerShowObjectiveBestTimes"] or "Show objective best deltas", "objectivesShowBestTimes", "mpt-flow-objectives", "mythicPlusTimerFlowObjectiveBestTimes"),

		section(L["mythicPlusTimerPanelEnemyForces"] or "Enemy forces", "mpt-flow-enemy", "mythicPlusTimerFlowEnemySection"),
		checkbox(L["Enabled"] or "Enabled", "enemyEnabled", "mpt-flow-enemy", "mythicPlusTimerFlowEnemyEnabled"),
		slider(L["Height"] or "Height", "enemyHeight", 4, 100, 0.1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemyHeight"),
		slider(L["Text size"] or "Text size", "enemyFontSize", 8, 56, 1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemyFontSize"),
		slider(L["Spacing"] or "Spacing", "enemyGap", 0, 50, 0.1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemyGap"),
		color(L["mythicPlusTimerPanelEnemyBarColor"] or "Enemy bar color", "enemyColor", "mpt-flow-enemy", "mythicPlusTimerFlowEnemyColor"),
		dropdown(L["Texture"] or "Texture", "enemyTexture", function() return buildMediaOptions("statusbar", false) end, "mpt-flow-enemy", "mythicPlusTimerFlowEnemyTexture"),
		dropdown(L["mythicPlusTimerFlowSlotLeft"] or "Left slot", "enemySlotLeft", alignOptions, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotLeft"),
		slider(slotOffsetLabel("Left", "X"), "enemySlotLeftOffsetX", -50, 50, 1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotLeftOffsetX"),
		slider(slotOffsetLabel("Left", "Y"), "enemySlotLeftOffsetY", -20, 20, 1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotLeftOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotRight"] or "Right slot", "enemySlotRight", alignOptions, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotRight"),
		slider(slotOffsetLabel("Right", "X"), "enemySlotRightOffsetX", -50, 50, 1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotRightOffsetX"),
		slider(slotOffsetLabel("Right", "Y"), "enemySlotRightOffsetY", -20, 20, 1, "mpt-flow-enemy", "mythicPlusTimerFlowEnemySlotRightOffsetY"),

		section(L["settingsCategoryFooter"] or "Footer", "mpt-flow-footer", "mythicPlusTimerFlowFooterSection"),
		checkbox(L["Enabled"] or "Enabled", "footerEnabled", "mpt-flow-footer", "mythicPlusTimerFlowFooterEnabled"),
		slider(L["Height"] or "Height", "footerHeight", 8, 100, 0.1, "mpt-flow-footer", "mythicPlusTimerFlowFooterHeight"),
		slider(L["Text size"] or "Text size", "footerFontSize", 8, 56, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterFontSize"),
		dropdown(L["mythicPlusTimerFlowSlotLeft"] or "Left slot", "footerSlotLeft", slotOptions, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotLeft", function(value) Flow:SetSlot("footer", "Left", value) end),
		slider(slotOffsetLabel("Left", "X"), "footerSlotLeftOffsetX", -50, 50, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotLeftOffsetX"),
		slider(slotOffsetLabel("Left", "Y"), "footerSlotLeftOffsetY", -20, 20, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotLeftOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotCenter"] or "Center slot", "footerSlotCenter", slotOptions, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotCenter", function(value) Flow:SetSlot("footer", "Center", value) end),
		slider(slotOffsetLabel("Center", "X"), "footerSlotCenterOffsetX", -50, 50, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotCenterOffsetX"),
		slider(slotOffsetLabel("Center", "Y"), "footerSlotCenterOffsetY", -20, 20, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotCenterOffsetY"),
		dropdown(L["mythicPlusTimerFlowSlotRight"] or "Right slot", "footerSlotRight", slotOptions, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotRight", function(value) Flow:SetSlot("footer", "Right", value) end),
		slider(slotOffsetLabel("Right", "X"), "footerSlotRightOffsetX", -50, 50, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotRightOffsetX"),
		slider(slotOffsetLabel("Right", "Y"), "footerSlotRightOffsetY", -20, 20, 1, "mpt-flow-footer", "mythicPlusTimerFlowFooterSlotRightOffsetY"),
		dropdown(L["mythicPlusTimerBackdropTexture"] or "Background texture", "footerBackgroundTexture", function() return buildMediaOptions("statusbar", false) end, "mpt-flow-footer", "mythicPlusTimerFlowFooterTexture"),

		section(L["mythicPlusTimerSectionFont"] or "Font", "mpt-flow-font", "mythicPlusTimerFlowFontSection"),
		dropdown(L["mythicPlusTimerFont"] or "Font", "fontFace", function() return buildMediaOptions("font", true) end, "mpt-flow-font", "mythicPlusTimerFlowFont"),
		dropdown(L["mythicPlusTimerFontOutline"] or "Font outline", "fontOutline", buildStyleOptions, "mpt-flow-font", "mythicPlusTimerFlowFontOutline"),
		slider(contentFontSizeLabel(L["mythicPlusTimerPanelAffixes"] or "Affixes"), "affixFontSize", 8, 56, 1, "mpt-flow-font", "mythicPlusTimerFlowAffixFontSize"),
		slider(contentFontSizeLabel(L["mythicPlusTimerDeaths"] or "Deaths"), "deathFontSize", 8, 56, 1, "mpt-flow-font", "mythicPlusTimerFlowDeathFontSize"),
		color(L["mythicPlusTimerTextColor"] or "Text color", "textColor", "mpt-flow-font", "mythicPlusTimerFlowTextColor"),
		color(L["mythicPlusTimerDungeonColor"] or "Dungeon color", "dungeonColor", "mpt-flow-font", "mythicPlusTimerFlowDungeonColor"),
		color(L["mythicPlusTimerDeathColor"] or "Death color", "deathColor", "mpt-flow-font", "mythicPlusTimerFlowDeathColor"),
		color(L["mythicPlusTimerObjectiveColor"] or "Objective color", "objectiveColor", "mpt-flow-font", "mythicPlusTimerFlowObjectiveColor"),
		color(L["mythicPlusTimerObjectiveCompleteColor"] or "Completed objective color", "objectiveCompleteColor", "mpt-flow-font", "mythicPlusTimerFlowObjectiveCompleteColor"),
	}
	local sectionEnabledKeys = {
		["mpt-flow-header"] = "headerEnabled",
		["mpt-flow-timer"] = "timerEnabled",
		["mpt-flow-objectives"] = "objectivesEnabled",
		["mpt-flow-enemy"] = "enemyEnabled",
		["mpt-flow-footer"] = "footerEnabled",
	}
	local enabledControlTags = {
		mythicPlusTimerFlowHeaderEnabled = true,
		mythicPlusTimerFlowTimerEnabled = true,
		mythicPlusTimerFlowObjectivesEnabled = true,
		mythicPlusTimerFlowEnemyEnabled = true,
		mythicPlusTimerFlowFooterEnabled = true,
	}
	local controlRequirements = {
		mythicPlusTimerFlowBackgroundColor = "backgroundEnabled",
		mythicPlusTimerFlowBackgroundTexture = "backgroundEnabled",
		mythicPlusTimerFlowBorderColor = "borderEnabled",
		mythicPlusTimerFlowBorderSize = "borderEnabled",
		mythicPlusTimerFlowBorderTexture = "borderEnabled",
		mythicPlusTimerFlowObjectiveBestTimes = "objectivesShowTimes",
	}
	local function buildIsEnabled(sectionEnabledKey, controlRequirementKey, ownIsEnabled)
		return function(...)
			if sectionEnabledKey and Flow:Get(sectionEnabledKey) ~= true then return false end
			if controlRequirementKey and Flow:Get(controlRequirementKey) ~= true then return false end
			return ownIsEnabled == nil or ownIsEnabled(...) ~= false
		end
	end
	for _, setting in ipairs(settings) do
		local sectionEnabledKey = not enabledControlTags[setting.newTagID] and sectionEnabledKeys[setting.parentId]
		local controlRequirementKey = controlRequirements[setting.newTagID]
		if sectionEnabledKey or controlRequirementKey then
			setting.isEnabled = buildIsEnabled(sectionEnabledKey, controlRequirementKey, setting.isEnabled)
		end
	end
	return settings
end
