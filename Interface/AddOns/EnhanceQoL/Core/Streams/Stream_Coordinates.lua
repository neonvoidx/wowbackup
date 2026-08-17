-- luacheck: globals EnhanceQoL C_Map IsInInstance
local addonName, addon = ...
local L = addon.L

local db
local stream
local coordinateFormatCache = {}

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function clampDecimals(value)
	local decimals = tonumber(value) or 2
	if decimals < 0 then
		decimals = 0
	elseif decimals > 2 then
		decimals = 2
	end
	return math.floor(decimals + 0.5)
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.coordinates = addon.db.datapanel.coordinates or {}
	db = addon.db.datapanel.coordinates
	db.fontSize = db.fontSize or 14
	db.updateInterval = db.updateInterval or 0.2
	db.decimals = clampDecimals(db.decimals)
	if db.hideInInstance == nil then db.hideInInstance = true end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_coordinates_fontSize")
	end
end

local format = string.format

local function getCoordinateFormat(decimals)
	local fmt = coordinateFormatCache[decimals]
	if not fmt then
		fmt = ("%%.%df, %%.%df"):format(decimals, decimals)
		coordinateFormatCache[decimals] = fmt
	end
	return fmt
end

local function formatCoords(x, y)
	if not x or not y then return nil end
	local decimals = db and db.decimals or 2
	return format(getCoordinateFormat(clampDecimals(decimals)), x * 100, y * 100)
end

local function getPlayerCoords()
	if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return nil end
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return nil end
	return pos.x, pos.y
end

local function updateCoordinates(s)
	s = s or stream
	ensureDB()

	if s and s.interval ~= db.updateInterval then s.interval = db.updateInterval end

	if db.hideInInstance and IsInInstance and IsInInstance() then
		s.snapshot.text = " "
	else
		local px, py = getPlayerCoords()
		local playerText = formatCoords(px, py)
		s.snapshot.text = playerText or "0, 0"
	end

	s.snapshot.fontSize = db.fontSize or 14
	s.snapshot.tooltip = getOptionsHint()
end

local provider = {
	id = "coordinates",
	version = 1,
	title = L["Coordinates"] or "Coordinates",
	poll = 0.2,
	update = updateCoordinates,
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
