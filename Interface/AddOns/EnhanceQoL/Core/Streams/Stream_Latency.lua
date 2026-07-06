-- luacheck: globals EnhanceQoL GetFramerate GetNetStats GetCVarBool UpdateAddOnCPUUsage GetAddOnCPUUsage UpdateAddOnMemoryUsage GetAddOnMemoryUsage MAINMENUBAR_FPS_LABEL NORMAL_FONT_COLOR C_AddOns C_CVar
local addonName, addon = ...
local L = addon.L

local db
local stream

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

-- Micro-optimizations: localize frequently used globals
local floor = math.floor
local min = math.min
local format = string.format
local sort = table.sort
local wipe = wipe
local GetTime = GetTime
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local GetCVarBool = (C_CVar and C_CVar.GetCVarBool) or GetCVarBool
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local GetAddOnCPUUsage = GetAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local C_AddOns = C_AddOns

-- Runtime state for smoothing and cadence
local lastPingUpdate = 0
local pingHome, pingWorld = nil, nil
local emaFPS -- exponential moving average for FPS
-- Change detection cache (declare early so callbacks see locals, not globals)
local lastFps, lastHome, lastWorld, lastPingMode, lastDisplay, lastBaseHex
local addonRows = {}

-- Color helpers (hex without leading #)
local function fpsColorHex(v)
	if v >= 60 then
		return "00ff00" -- green
	elseif v >= 30 then
		return "ffff00" -- yellow
	else
		return "ff0000"
	end -- red
end

local function colorToHex(color)
	local r = (color and color.r) or 1
	local g = (color and color.g) or 1
	local b = (color and color.b) or 1
	return format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

local function pingColorHex(v)
	local low = tonumber(db and db.pingThresholdLow) or 50
	local mid = tonumber(db and db.pingThresholdMid) or 150
	if low < 0 then low = 0 end
	if mid < low then mid = low end

	if v <= low then return colorToHex(db and db.pingColorLow) end
	if v <= mid then return colorToHex(db and db.pingColorMid) end
	return colorToHex(db and db.pingColorHigh)
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.latency = addon.db.datapanel.latency or {}
	db = addon.db.datapanel.latency

	db.fontSize = db.fontSize or 14
	db.displayMode = db.displayMode or "both"
	if db.useTextColor == nil then db.useTextColor = false end
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	-- Cadence (seconds)
	db.fpsInterval = db.fpsInterval or 0.25 -- 4x/s
	db.pingInterval = db.pingInterval or 1.0 -- 1x/s
	-- Smoothing window (seconds); 0 disables smoothing
	if db.fpsSmoothWindow == nil then db.fpsSmoothWindow = 0.75 end
	-- Ping display mode: "max" or "split"
	db.pingMode = db.pingMode or "max"
	-- Ping thresholds + colors
	db.pingThresholdLow = db.pingThresholdLow or 50
	db.pingThresholdMid = db.pingThresholdMid or 150
	db.pingColorLow = db.pingColorLow or { r = 0, g = 1, b = 0 }
	db.pingColorMid = db.pingColorMid or { r = 1, g = 0.65, b = 0 }
	db.pingColorHigh = db.pingColorHigh or { r = 1, g = 0, b = 0 }
	if db.showCpuTooltip == nil then db.showCpuTooltip = true end
	db.cpuTooltipEntries = tonumber(db.cpuTooltipEntries) or 8
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_latency_fontSize")
	end
end

-- EMA-based smoothing (no tables, constant work per tick)
local function smoothFPS(current, interval, window)
	if (window or 0) <= 0 then
		emaFPS = current
		return current
	end
	local alpha = min(1, (interval or 0.25) / window)
	emaFPS = emaFPS and (emaFPS + alpha * (current - emaFPS)) or current
	return emaFPS
end

local function buildMinWidthText(displayMode)
	if displayMode == "fps" then return "FPS 999" end
	if displayMode == "ping" then
		if db.pingMode == "split" then return "H 999 / W 999 ms" end
		if db.pingMode == "split_vertical" then
			return ((_G["HOME"] or "Home") .. ": 999 ms\n" .. (_G["WORLD"] or "World") .. ": 999 ms")
		end
		return "999 ms"
	end
	if db.pingMode == "split" then return "FPS 999 | H 999 / W 999 ms" end
	if db.pingMode == "split_vertical" then
		return ("FPS 999\n" .. (_G["HOME"] or "Home") .. ": 999 ms\n" .. (_G["WORLD"] or "World") .. ": 999 ms")
	end
	return "FPS 999 | 999 ms"
end

local function formatMemory(kb)
	kb = tonumber(kb) or 0
	if kb >= 1024 then return format("%.2f MB", kb / 1024) end
	return format("%d KB", floor(kb + 0.5))
end

local function stripTextureAndColor(text)
	text = tostring(text or "")
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("|T.-|t", "")
	return text
end

local function formatFPSLabel(fps)
	local label = MAINMENUBAR_FPS_LABEL
	if type(label) == "string" and label:find("%%", 1, true) then
		local ok, text = pcall(format, label, fps)
		if ok and text then return text end
	end
	return (L["latencyTooltipFPS"] or "Framerate") .. ": " .. tostring(fps)
end

local function addonSortMemory(a, b) return (a.mem or 0) > (b.mem or 0) end

local function addColoredDoubleLine(tip, left, right, r, g, b)
	tip:AddDoubleLine(left, right, 1, 1, 1, r or 0.84, g or 0.75, b or 0.65)
end

local function addAddonUsageTooltip(tip)
	if not (db and db.showCpuTooltip) then return end
	if not (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetAddOnInfo and C_AddOns.IsAddOnLoaded and UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then return end

	local cpuProfiling = GetCVarBool and GetCVarBool("scriptProfile")
	UpdateAddOnMemoryUsage()
	if cpuProfiling and UpdateAddOnCPUUsage and GetAddOnCPUUsage then UpdateAddOnCPUUsage() end

	wipe(addonRows)
	local count = 0
	local totalMem = 0
	local totalCPU = 0
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.IsAddOnLoaded(i) then
			local mem = GetAddOnMemoryUsage(i) or 0
			local cpu = cpuProfiling and GetAddOnCPUUsage and (GetAddOnCPUUsage(i) or 0) or nil
			totalMem = totalMem + mem
			if cpu then totalCPU = totalCPU + cpu end
			count = count + 1
			local name, title = C_AddOns.GetAddOnInfo(i)
			addonRows[count] = {
				name = stripTextureAndColor(title or name or ("AddOn " .. i)),
				mem = mem,
				cpu = cpu,
			}
		end
	end

	tip:AddLine(" ")
	addColoredDoubleLine(tip, L["latencyAddonMemory"] or "AddOn Memory", formatMemory(totalMem))
	if cpuProfiling then
		addColoredDoubleLine(tip, L["latencyCpuUsage"] or "AddOn CPU usage", format("%.1f ms", totalCPU))
	end

	sort(addonRows, addonSortMemory)
	local limit = min(tonumber(db.cpuTooltipEntries) or 8, count)
	if limit > 0 then
		tip:AddLine(" ")
		tip:AddLine(L["latencyAddonMemoryHeader"] or "Largest AddOns in memory")
	end

	for i = 1, limit do
		local row = addonRows[i]
		if row then
			if cpuProfiling then
				addColoredDoubleLine(tip, row.name, format("%s | %.1f ms", formatMemory(row.mem), row.cpu or 0))
			else
				addColoredDoubleLine(tip, row.name, formatMemory(row.mem))
			end
		end
	end
end

local function showLatencyTooltip(btn)
	ensureDB()
	local tip = GameTooltip
	if not tip then return end
	tip:ClearLines()
	if addon.DataPanel and addon.DataPanel.SetTooltipOwner then
		addon.DataPanel.SetTooltipOwner(btn, tip)
	else
		tip:SetOwner(btn, "ANCHOR_TOPLEFT")
	end

	local fps = floor((GetFramerate() or 0) + 0.5)
	local _, _, home, world = GetNetStats()
	home = home or 0
	world = world or 0
	tip:AddLine(formatFPSLabel(fps), 1, 1, 1)
	addColoredDoubleLine(tip, L["latencyTooltipHome"] or (_G["HOME"] or "Home"), format("%d ms", home), 0.84, 0.75, 0.65)
	addColoredDoubleLine(tip, L["latencyTooltipWorld"] or (_G["WORLD"] or "World"), format("%d ms", world), 0.84, 0.75, 0.65)

	addAddonUsageTooltip(tip)

	local hint = getOptionsHint()
	if hint then
		tip:AddLine(" ")
		tip:AddLine(hint)
	end
	tip:Show()
end

local function latencyTooltipOnUpdate(btn, elapsed)
	if GameTooltip and GameTooltip.IsOwned and not GameTooltip:IsOwned(btn) then
		btn.eqolLatencyTooltipElapsed = nil
		if btn.SetScript then btn:SetScript("OnUpdate", nil) end
		return
	end
	btn.eqolLatencyTooltipElapsed = (btn.eqolLatencyTooltipElapsed or 0) + (elapsed or 0)
	if btn.eqolLatencyTooltipElapsed < 1 then return end
	btn.eqolLatencyTooltipElapsed = 0
	showLatencyTooltip(btn)
end

local function updateLatency(s)
	s = s or stream
	ensureDB()
	local baseHex = db and db.useTextColor and colorToHex(db.textColor) or nil
	local function base(text)
		text = text or ""
		if baseHex then return format("|cff%s%s|r", baseHex, text) end
		return text
	end

	local displayMode = db.displayMode or "both"
	local showFps = displayMode ~= "ping"
	local showPing = displayMode ~= "fps"

	-- Keep the hub driver cadence in sync with the current display mode
	local desiredInterval = db.fpsInterval
	if displayMode == "ping" then desiredInterval = db.pingInterval end
	if s and desiredInterval and s.interval ~= desiredInterval then s.interval = desiredInterval end

	local size = db.fontSize or 14
	s.snapshot.minWidthText = buildMinWidthText(displayMode)

	local now = GetTime()

	local fpsValue
	if showFps then
		-- FPS sampling + smoothing
		local fpsNow = GetFramerate() or 0
		local fpsAvg = smoothFPS(fpsNow, db.fpsInterval or 0.25, db.fpsSmoothWindow or 0)
		fpsValue = floor(fpsAvg + 0.5)
	end

	if showPing then
		-- Ping sampling (gated)
		if (now - (lastPingUpdate or 0)) >= (db.pingInterval or 1.0) or not pingHome or not pingWorld then
			local _, _, home, world = GetNetStats()
			pingHome, pingWorld = home or 0, world or 0
			lastPingUpdate = now
		end
	end

	s.snapshot.tooltip = nil

	local needsUpdate = displayMode ~= lastDisplay or baseHex ~= lastBaseHex
	if showFps and fpsValue ~= lastFps then needsUpdate = true end
	if showPing and ((pingHome or 0) ~= (lastHome or -1) or (pingWorld or 0) ~= (lastWorld or -1) or db.pingMode ~= lastPingMode) then needsUpdate = true end

	if needsUpdate then
		local pingText
		if showPing then
			if db.pingMode == "split" then
				local ph = pingHome or 0
				local pw = pingWorld or 0
				pingText = base("H ") .. format("|cff%s%d|r", pingColorHex(ph), ph) .. base(" / W ") .. format("|cff%s%d|r", pingColorHex(pw), pw) .. base(" ms")
			elseif db.pingMode == "split_vertical" then
				local ph = pingHome or 0
				local pw = pingWorld or 0
				local homeLabel = _G["HOME"] or "Home"
				local worldLabel = _G["WORLD"] or "World"
				pingText = base(homeLabel .. ": ")
					.. format("|cff%s%d|r", pingColorHex(ph), ph)
					.. base(" ms\n")
					.. base(worldLabel .. ": ")
					.. format("|cff%s%d|r", pingColorHex(pw), pw)
					.. base(" ms")
			elseif db.pingMode == "home" then
				local ph = pingHome or 0
				pingText = format("|cff%s%d|r", pingColorHex(ph), ph) .. base(" ms")
			elseif db.pingMode == "world" then
				local pw = pingWorld or 0
				pingText = format("|cff%s%d|r", pingColorHex(pw), pw) .. base(" ms")
			else
				local p = pingHome or 0
				if pingWorld and pingWorld > p then p = pingWorld end
				pingText = format("|cff%s%d|r", pingColorHex(p), p) .. base(" ms")
			end
		end

		local text
		if displayMode == "ping" then
			text = pingText or ""
		elseif displayMode == "fps" then
			text = base("FPS ") .. format("|cff%s%d|r", fpsColorHex(fpsValue or 0), fpsValue or 0)
		else
			local fpsText = base("FPS ") .. format("|cff%s%d|r", fpsColorHex(fpsValue or 0), fpsValue or 0)
			if pingText and pingText:find("\n", 1, true) then
				text = fpsText .. "\n" .. pingText
			else
				text = fpsText .. base(" | ") .. (pingText or "")
			end
		end

		s.snapshot.text = text
		lastDisplay = displayMode
		lastFps = showFps and fpsValue or nil
		lastHome = showPing and (pingHome or 0) or nil
		lastWorld = showPing and (pingWorld or 0) or nil
		lastPingMode = showPing and db.pingMode or nil
		lastBaseHex = baseHex
	end

	-- Only touch fontSize if actually changed
	if s.snapshot._fs ~= size then
		s.snapshot.fontSize = size
		s.snapshot._fs = size
	end
	s.snapshot.skipPanelClassColor = db and db.useTextColor == true or nil
end

local provider = {
	id = "latency",
	version = 1,
	title = L["Latency"] or "Latency",
	poll = 0.25, -- default FPS cadence; kept in sync with db.fpsInterval at runtime
	update = updateLatency,
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
	OnMouseEnter = function(btn)
		showLatencyTooltip(btn)
		btn.eqolLatencyTooltipElapsed = 0
		if btn.SetScript then btn:SetScript("OnUpdate", latencyTooltipOnUpdate) end
	end,
	OnMouseLeave = function(btn)
		if btn and btn.SetScript then btn:SetScript("OnUpdate", nil) end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
