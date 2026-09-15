-- luacheck: globals EnhanceQoL GetZoneText GetSubZoneText GetRealZoneText C_PvP GetZonePVPInfo
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

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.location = addon.db.datapanel.location or {}
	db = addon.db.datapanel.location
	db.fontSize = db.fontSize or 14
	if db.showSubzone == nil then db.showSubzone = true end
	if db.useZoneColor == nil then db.useZoneColor = true end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_location_fontSize")
	end
end

local function getLocationText()
	local zone = GetZoneText and GetZoneText()
	if not zone or zone == "" then zone = GetRealZoneText and GetRealZoneText() end
	local subzone = GetSubZoneText and GetSubZoneText()
	if db and db.showSubzone and subzone and subzone ~= "" and subzone ~= zone then
		if zone and zone ~= "" then return zone .. " - " .. subzone end
		return subzone
	end
	if zone and zone ~= "" then return zone end
	return subzone or ""
end

local function getZoneColor()
	local pvpType = (C_PvP.GetZonePVPInfo())

	if pvpType == "sanctuary" then
		return 0.41, 0.8, 0.94
	elseif pvpType == "arena" then
		return 1.0, 0.1, 0.1
	elseif pvpType == "friendly" then
		return 0.1, 1.0, 0.1
	elseif pvpType == "hostile" then
		return 1.0, 0.1, 0.1
	elseif pvpType == "contested" then
		return 1.0, 0.7, 0.0
	end
	return _G.NORMAL_FONT_COLOR.r, _G.NORMAL_FONT_COLOR.g, _G.NORMAL_FONT_COLOR.b
end

local function colorize(text, r, g, b)
	if not text or text == "" then return "" end
	local rr = math.floor((r or 1) * 255 + 0.5)
	local gg = math.floor((g or 1) * 255 + 0.5)
	local bb = math.floor((b or 1) * 255 + 0.5)
	return ("|cff%02x%02x%02x%s|r"):format(rr, gg, bb, text)
end

local function updateLocation(s)
	s = s or stream
	ensureDB()

	local text = getLocationText() or ""
	if text ~= "" then
		if db.useZoneColor then
			text = colorize(text, getZoneColor())
		else
			text = colorize(text, _G.NORMAL_FONT_COLOR.r, _G.NORMAL_FONT_COLOR.g, _G.NORMAL_FONT_COLOR.b)
		end
	end
	s.snapshot.text = text
	s.snapshot.fontSize = db.fontSize or 14
	s.snapshot.tooltip = getOptionsHint()
end

local provider = {
	id = "location",
	version = 1,
	title = L["Location"] or "Location",
	update = updateLocation,
	events = {
		ZONE_CHANGED = function(s) addon.DataHub:RequestUpdate(s) end,
		ZONE_CHANGED_INDOORS = function(s) addon.DataHub:RequestUpdate(s) end,
		ZONE_CHANGED_NEW_AREA = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
