-- luacheck: globals EnhanceQoL GetFramerate GetNetStats MAINMENUBAR_FPS_LABEL MAINMENUBAR_LATENCY_LABEL NORMAL_FONT_COLOR
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
local GetTime = GetTime
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats

-- Runtime state for smoothing and cadence
local lastPingUpdate = 0
local pingHome, pingWorld = nil, nil
local emaFPS -- exponential moving average for FPS
-- Change detection cache (declare early so callbacks see locals, not globals)
local lastFps, lastHome, lastWorld, lastPingMode, lastDisplay

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

-- (declared above)

local function updateLatency(s)
	s = s or stream
	ensureDB()
	local baseHex = colorToHex(db and db.textColor)
	local function base(text) return format("|cff%s%s|r", baseHex, text or "") end

	local displayMode = db.displayMode or "both"
	local showFps = displayMode ~= "ping"
	local showPing = displayMode ~= "fps"

	-- Keep the hub driver cadence in sync with the current display mode
	local desiredInterval = db.fpsInterval
	if displayMode == "ping" then desiredInterval = db.pingInterval end
	if s and desiredInterval and s.interval ~= desiredInterval then s.interval = desiredInterval end

	local size = db.fontSize or 14
	s.snapshot.tooltip = getOptionsHint()

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

	local needsUpdate = displayMode ~= lastDisplay
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
	end

	-- Only touch fontSize if actually changed
	if s.snapshot._fs ~= size then
		s.snapshot.fontSize = size
		s.snapshot._fs = size
	end
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
		ensureDB()
		local tip = GameTooltip
		tip:ClearLines()
		if addon.DataPanel and addon.DataPanel.SetTooltipOwner then
			addon.DataPanel.SetTooltipOwner(btn, tip)
		else
			tip:SetOwner(btn, "ANCHOR_TOPLEFT")
		end

		local displayMode = db.displayMode or "both"
		local showFps = displayMode ~= "ping"
		local showPing = displayMode ~= "fps"

		local lines = {}
		if showFps then
			local fps = floor((GetFramerate() or 0) + 0.5)
			-- Build FPS line using the global format, coloring only the value
			local fpsFmt = (MAINMENUBAR_FPS_LABEL or "Framerate: %.0f fps"):gsub("%%%.0f", "%%s")
			lines[#lines + 1] = fpsFmt:format(format("|cff%s%.0f|r", fpsColorHex(fps), fps))
		end

		if showPing then
			local _, _, home, world = GetNetStats()
			home = home or 0
			world = world or 0
			-- Build Latency block using the global format, coloring each value
			local latFmt = (MAINMENUBAR_LATENCY_LABEL or "Latency:\n%.0f ms (home)\n%.0f ms (world)")
			latFmt = latFmt:gsub("%%%.0f", "%%s")
			local latencyBlock = latFmt:format(format("|cff%s%.0f|r", pingColorHex(home), home), format("|cff%s%.0f|r", pingColorHex(world), world))
			for line in latencyBlock:gmatch("[^\n]+") do
				lines[#lines + 1] = line
			end
		end

		if lines[1] then
			tip:SetText(lines[1])
			for i = 2, #lines do
				tip:AddLine(lines[i])
			end
		end
		local hint = getOptionsHint()
		if hint then
			tip:AddLine(" ")
			tip:AddLine(hint)
		end
		tip:Show()
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
