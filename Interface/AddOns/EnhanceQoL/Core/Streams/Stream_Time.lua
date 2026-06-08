-- luacheck: globals EnhanceQoL GetGameTime TIMEMANAGER_AM TIMEMANAGER_PM NORMAL_FONT_COLOR ToggleTimeManager ToggleCalendar
local addonName, addon = ...
local L = addon.L

local db
local stream
local timeColorHex
local lastColorR, lastColorG, lastColorB

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.time = addon.db.datapanel.time or {}
	db = addon.db.datapanel.time
	db.fontSize = db.fontSize or 14
	db.displayMode = db.displayMode or "server"
	if db.use24Hour == nil then db.use24Hour = true end
	if db.showSeconds == nil then db.showSeconds = false end
	db.leftClickAction = db.leftClickAction or "clock"
	if db.leftClickAction ~= "clock" and db.leftClickAction ~= "calendar" then db.leftClickAction = "clock" end
	if not db.timeColor then
		local r, g, b = 1, 1, 1
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.timeColor = { r = r, g = g, b = b }
	end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_time_fontSize")
	end
end

local function formatTime(h, m, s)
	if h == nil or m == nil then return "" end
	local showSeconds = db and db.showSeconds
	local use24 = db and db.use24Hour
	local suffix = ""
	if not use24 then
		local isPM = h >= 12
		suffix = isPM and (TIMEMANAGER_PM or "PM") or (TIMEMANAGER_AM or "AM")
		h = h % 12
		if h == 0 then h = 12 end
	end

	if showSeconds then
		s = s or 0
		if use24 then return ("%02d:%02d:%02d"):format(h, m, s) end
		return ("%d:%02d:%02d %s"):format(h, m, s, suffix)
	end

	if use24 then return ("%02d:%02d"):format(h, m) end
	return ("%d:%02d %s"):format(h, m, suffix)
end

local function getLocalTimeParts()
	local t = date("*t")
	if not t then return nil end
	return t.hour, t.min, t.sec
end

local function getServerTimeParts(fallbackSec)
	if not GetGameTime then return nil end
	local h, m = GetGameTime()
	if h == nil or m == nil then return nil end
	return h, m, fallbackSec
end

local function updateColorCache()
	local c = db and db.timeColor
	local r = (c and c.r) or 1
	local g = (c and c.g) or 1
	local b = (c and c.b) or 1
	if timeColorHex and r == lastColorR and g == lastColorG and b == lastColorB then return end
	lastColorR, lastColorG, lastColorB = r, g, b
	timeColorHex = ("%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function colorize(text)
	if not text or text == "" then return "" end
	if not timeColorHex then updateColorCache() end
	if not timeColorHex then return text end
	return ("|cff%s%s|r"):format(timeColorHex, text)
end

local function getLeftClickAction()
	if db and db.leftClickAction == "calendar" then return "calendar" end
	return "clock"
end

local function buildCommonTooltip(baseText)
	local tooltip = baseText
	local clickHint
	if getLeftClickAction() == "calendar" then
		clickHint = L["Time left-click hint calendar"] or "Left-click to open calendar"
	else
		clickHint = L["Time left-click hint clock"] or "Left-click to open stopwatch"
	end
	local optionsHint = getOptionsHint()

	if clickHint and clickHint ~= "" then
		if tooltip and tooltip ~= "" then
			tooltip = tooltip .. "\n" .. clickHint
		else
			tooltip = clickHint
		end
	end

	if optionsHint and optionsHint ~= "" then
		if tooltip and tooltip ~= "" then
			tooltip = tooltip .. "\n" .. optionsHint
		else
			tooltip = optionsHint
		end
	end

	return tooltip
end

local function updateTime(s)
	s = s or stream
	ensureDB()
	updateColorCache()

	local lh, lm, ls = getLocalTimeParts()
	local interval
	if db.showSeconds then
		interval = 1
	else
		if ls == nil then
			interval = 30
		else
			local wait = 60 - (ls % 60)
			if wait <= 0 then wait = 60 end
			interval = wait
		end
	end
	if s.interval ~= interval then s.interval = interval end
	local sh, sm, ss = getServerTimeParts(ls)
	local mode = db.displayMode or "server"

	if mode == "localTime" then
		s.snapshot.text = colorize(formatTime(lh, lm, ls))
		s.snapshot.tooltip = buildCommonTooltip(nil)
	elseif mode == "both" then
		local serverText = formatTime(sh, sm, ss)
		local localText = formatTime(lh, lm, ls)
		s.snapshot.text = colorize(serverText .. " / " .. localText)
		local tooltip = (L["Server time"] or "Server time") .. ": " .. serverText
		tooltip = tooltip .. "\n" .. (L["Local time"] or "Local time") .. ": " .. localText
		s.snapshot.tooltip = buildCommonTooltip(tooltip)
	else
		s.snapshot.text = colorize(formatTime(sh, sm, ss))
		s.snapshot.tooltip = buildCommonTooltip(nil)
	end

	s.snapshot.fontSize = db.fontSize or 14
end

local provider = {
	id = "time",
	version = 2,
	title = L["Time"] or "Time",
	poll = 1,
	update = updateTime,
	events = {
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		ensureDB()
		if btn == "RightButton" then
			openSettings()
		elseif btn == "LeftButton" then
			if getLeftClickAction() == "calendar" then
				if ToggleCalendar then
					ToggleCalendar()
				elseif ToggleTimeManager then
					ToggleTimeManager()
				end
			elseif ToggleTimeManager then
				ToggleTimeManager()
			end
		end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
