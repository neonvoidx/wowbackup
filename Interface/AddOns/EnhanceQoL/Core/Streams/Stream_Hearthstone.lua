-- luacheck: globals EnhanceQoL GetBindLocation NORMAL_FONT_COLOR UNKNOWN C_Item GetItemInfoInstant GetItemIcon
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
	addon.db.datapanel.hearthstone = addon.db.datapanel.hearthstone or {}
	db = addon.db.datapanel.hearthstone
	db.fontSize = db.fontSize or 14
	if db.hideIcon == nil then db.hideIcon = false end
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_hearthstone_fontSize")
	end
end

local floor = math.floor
local function colorize(text)
	if not text or text == "" then return "" end
	local c = db and db.textColor
	local r = (c and c.r) or 1
	local g = (c and c.g) or 1
	local b = (c and c.b) or 1
	return ("|cff%02x%02x%02x%s|r"):format(floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5), text)
end

local HEARTHSTONE_ITEM_ID = 6948
local DEFAULT_HEARTHSTONE_ICON = 134414
local hearthstoneIcon
local function getHearthstoneIcon()
	if hearthstoneIcon then return hearthstoneIcon end
	if C_Item and C_Item.GetItemIconByID then
		hearthstoneIcon = C_Item.GetItemIconByID(HEARTHSTONE_ITEM_ID)
	end
	if not hearthstoneIcon and C_Item and C_Item.GetItemInfoInstant then
		local icon = select(5, C_Item.GetItemInfoInstant(HEARTHSTONE_ITEM_ID))
		if icon then hearthstoneIcon = icon end
	end
	if not hearthstoneIcon then hearthstoneIcon = DEFAULT_HEARTHSTONE_ICON end
	return hearthstoneIcon
end

local function updateHearthstone(s)
	s = s or stream
	ensureDB()

	local location = GetBindLocation and GetBindLocation() or ""
	if not location or location == "" then location = UNKNOWN or "Unknown" end
	local size = db.fontSize or 14
	local text = colorize(location)
	if not db.hideIcon then text = ("|T%d:%d:%d:0:0|t %s"):format(getHearthstoneIcon(), size, size, text) end

	s.snapshot.text = text
	s.snapshot.fontSize = size

	local tooltip = (L["Hearthstone"] or "Hearthstone") .. ": " .. location
	local hint = getOptionsHint()
	if hint then tooltip = tooltip .. "\n" .. hint end
	s.snapshot.tooltip = tooltip
end

local provider = {
	id = "hearthstone",
	version = 1,
	title = L["Hearthstone"] or "Hearthstone",
	update = updateHearthstone,
	events = {
		HEARTHSTONE_BOUND = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
