-- luacheck: globals EnhanceQoL GetGameTime TIMEMANAGER_AM TIMEMANAGER_PM NORMAL_FONT_COLOR CUSTOM_CLASS_COLORS RAID_CLASS_COLORS UnitClass ToggleTimeManager ToggleCalendar RequestRaidInfo GetNumSavedInstances GetSavedInstanceInfo GetDifficultyInfo SecondsToTime C_DateAndTime C_Timer WEEKLY RESET wipe
local addonName, addon = ...
local L = addon.L

local db
local stream
local timeColorHex
local lastColorR, lastColorG, lastColorB
local classColorHex
local lastClassToken
local lockoutTooltipReady
local lockoutRefreshQueued

local lockedRaids = {}
local lockedDungeons = {}
local tinsert = table.insert
local sort = table.sort
local format = string.format
local floor = math.floor

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
	if db.useClassColor == nil then db.useClassColor = false end
	if db.showLockouts == nil then db.showLockouts = true end
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
	if db and db.useClassColor then
		local classToken = UnitClass and select(2, UnitClass("player"))
		if classColorHex and classToken == lastClassToken then
			timeColorHex = classColorHex
			return
		end
		lastClassToken = classToken
		local color = classToken and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
		if color then
			classColorHex = ("%02x%02x%02x"):format(floor((color.r or 1) * 255 + 0.5), floor((color.g or 1) * 255 + 0.5), floor((color.b or 1) * 255 + 0.5))
			timeColorHex = classColorHex
			return
		end
	end

	if classColorHex then
		timeColorHex = nil
		lastColorR, lastColorG, lastColorB = nil, nil, nil
	end
	classColorHex = nil
	lastClassToken = nil
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

local function formatResetTime(seconds)
	seconds = tonumber(seconds) or 0
	if seconds <= 0 then return _G.EXPIRED or "Expired" end
	if SecondsToTime then return SecondsToTime(seconds, false, false, 1) end
	local days = floor(seconds / 86400)
	if days > 0 then return format("%dd %dh", days, floor((seconds % 86400) / 3600)) end
	local hours = floor(seconds / 3600)
	if hours > 0 then return format("%dh %dm", hours, floor((seconds % 3600) / 60)) end
	return format("%dm", floor(seconds / 60))
end

local function getDifficultyLabel(difficultyID, fallback)
	if not GetDifficultyInfo then return fallback or "" end
	local name, _, isHeroic, _, displayHeroic, displayMythic = GetDifficultyInfo(difficultyID)
	if displayMythic then return _G.PLAYER_DIFFICULTY6 or "Mythic" end
	if isHeroic or displayHeroic then return _G.PLAYER_DIFFICULTY2 or "Heroic" end
	if difficultyID == 7 or difficultyID == 17 then return _G.RAID_FINDER or "Raid Finder" end
	return name or fallback or ""
end

local function getDifficultyTag(difficultyID, fallback)
	if difficultyID == 7 or difficultyID == 17 then return "LFR" end
	if not GetDifficultyInfo then return fallback or "" end
	local name, _, isHeroic, _, displayHeroic, displayMythic = GetDifficultyInfo(difficultyID)
	if displayMythic then return "M" end
	if isHeroic or displayHeroic then return "H" end
	if name == _G.PLAYER_DIFFICULTY1 then return "N" end
	local text = fallback or name or ""
	return text ~= "" and text:sub(1, 1) or ""
end

local function lockoutSort(a, b)
	if a.name == b.name then return (a.difficulty or "") < (b.difficulty or "") end
	return (a.name or "") < (b.name or "")
end

local function rebuildLockoutTooltip()
	lockoutRefreshQueued = nil
	wipe(lockedRaids)
	wipe(lockedDungeons)

	if GetNumSavedInstances and GetSavedInstanceInfo then
		for i = 1, GetNumSavedInstances() do
			local name, _, reset, difficulty, locked, extended, _, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
			if name and (locked or extended) then
				local entry = {
					name = name,
					reset = reset,
					extended = extended,
					difficulty = getDifficultyLabel(difficulty, difficultyName),
					difficultyTag = getDifficultyTag(difficulty, difficultyName),
					maxPlayers = tonumber(maxPlayers) or 0,
					progress = tonumber(encounterProgress) or 0,
					total = tonumber(numEncounters) or 0,
				}
				tinsert(isRaid and lockedRaids or lockedDungeons, entry)
			end
		end
	end

	sort(lockedRaids, lockoutSort)
	sort(lockedDungeons, lockoutSort)
	lockoutTooltipReady = true
	if stream then addon.DataHub:RequestUpdate(stream) end
end

local function requestLockoutRefresh()
	if RequestRaidInfo then RequestRaidInfo() end
	if lockoutRefreshQueued then return end
	lockoutRefreshQueued = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0.5, rebuildLockoutTooltip)
	else
		rebuildLockoutTooltip()
	end
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

local function addLockoutGroup(tip, title, entries)
	if #entries == 0 then return false end
	if tip:NumLines() > 0 then tip:AddLine(" ") end
	tip:AddLine(title, 1, 1, 1)
	for _, entry in ipairs(entries) do
		local progress = ""
		if entry.total and entry.total > 0 and entry.progress and entry.progress > 0 then
			progress = format(", %d/%d", entry.progress, entry.total)
		end
		local size = entry.maxPlayers and entry.maxPlayers > 0 and tostring(entry.maxPlayers) or "?"
		local tag = entry.difficultyTag and entry.difficultyTag ~= "" and entry.difficultyTag or entry.difficulty
		local left = format("%s (%s) %s%s", size, tag, entry.name, progress)
		if entry.extended then left = left .. " - " .. (L["timeLockoutsExtended"] or "Extended") end
		tip:AddDoubleLine(left, formatResetTime(entry.reset), 1, 1, 1, 0.84, 0.75, 0.65)
	end
	return true
end

local function showTimeTooltip(btn)
	ensureDB()
	if db.showLockouts and not lockoutTooltipReady then requestLockoutRefresh() end

	local tip = GameTooltip
	if not tip then return end
	tip:ClearLines()
	if addon.DataPanel and addon.DataPanel.SetTooltipOwner then
		addon.DataPanel.SetTooltipOwner(btn, tip)
	else
		tip:SetOwner(btn, "ANCHOR_TOPLEFT")
	end

	local lh, lm, ls = getLocalTimeParts()
	local sh, sm, ss = getServerTimeParts(ls)
	local mode = db.displayMode or "server"
	if mode == "both" then
		tip:AddDoubleLine(L["Server time"] or "Server time", formatTime(sh, sm, ss), 1, 1, 1, 0.84, 0.75, 0.65)
		tip:AddDoubleLine(L["Local time"] or "Local time", formatTime(lh, lm, ls), 1, 1, 1, 0.84, 0.75, 0.65)
	end

	if db.showLockouts then
		addLockoutGroup(tip, L["timeLockoutsRaids"] or "Saved raids", lockedRaids)
		addLockoutGroup(tip, L["timeLockoutsDungeons"] or "Saved dungeons", lockedDungeons)
		if #lockedRaids == 0 and #lockedDungeons == 0 then
			if tip:NumLines() > 0 then tip:AddLine(" ") end
			tip:AddLine(L["timeLockoutsNone"] or "No saved instances", 0.8, 0.8, 0.8)
		end
	end

	local dailyReset = C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset and C_DateAndTime.GetSecondsUntilDailyReset()
	local weeklyReset = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
	if dailyReset or weeklyReset then
		if tip:NumLines() > 0 then tip:AddLine(" ") end
		if dailyReset then tip:AddDoubleLine(L["timeLockoutsDailyReset"] or "Daily reset", formatResetTime(dailyReset), 1, 1, 1, 0.84, 0.75, 0.65) end
		if weeklyReset then tip:AddDoubleLine(WEEKLY and RESET and (WEEKLY .. " " .. RESET) or (L["timeLockoutsWeeklyReset"] or "Weekly reset"), formatResetTime(weeklyReset), 1, 1, 1, 0.84, 0.75, 0.65) end
	end

	if mode ~= "both" then
		if tip:NumLines() > 0 then tip:AddLine(" ") end
		tip:AddDoubleLine(L["Local time"] or "Local time", formatTime(lh, lm, ls), 1, 1, 1, 0.84, 0.75, 0.65)
		tip:AddDoubleLine(L["Server time"] or "Server time", formatTime(sh, sm, ss), 1, 1, 1, 0.84, 0.75, 0.65)
	end

	local clickHint = getLeftClickAction() == "calendar" and (L["Time left-click hint calendar"] or "Left-click to open calendar") or (L["Time left-click hint clock"] or "Left-click to open stopwatch")
	if clickHint and clickHint ~= "" then tip:AddLine(clickHint, 1, 1, 1) end
	local optionsHint = getOptionsHint()
	if optionsHint then tip:AddLine(optionsHint, 1, 1, 1) end
	tip:Show()
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
		BOSS_KILL = function(s) requestLockoutRefresh(); addon.DataHub:RequestUpdate(s) end,
		PLAYER_ENTERING_WORLD = function(s) requestLockoutRefresh(); addon.DataHub:RequestUpdate(s) end,
		UPDATE_INSTANCE_INFO = function(s) rebuildLockoutTooltip(); addon.DataHub:RequestUpdate(s) end,
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
	OnMouseEnter = function(btn)
		showTimeTooltip(btn)
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
