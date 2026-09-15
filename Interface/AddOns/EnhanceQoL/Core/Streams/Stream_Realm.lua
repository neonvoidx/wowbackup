-- luacheck: globals EnhanceQoL GetRealmName NORMAL_FONT_COLOR
local addonName, addon = ...
local L = addon.L

local db
local cachedRealm
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
	addon.db.datapanel.realm = addon.db.datapanel.realm or {}
	db = addon.db.datapanel.realm
	db.fontSize = db.fontSize or 14
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
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_realm_fontSize")
	end
end

local function getRealm()
	if cachedRealm and cachedRealm ~= "" then return cachedRealm end
	local name = GetRealmName and GetRealmName() or ""
	if name and name ~= "" then cachedRealm = name end
	return name or ""
end

local function colorize(text, color)
	if not text or text == "" then return text end
	if color and color.r and color.g and color.b then return ("|cff%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, text) end
	return text
end

local function updateRealm(s)
	s = s or stream
	if not s then return end
	ensureDB()
	s.snapshot.text = colorize(getRealm(), db.textColor)
	s.snapshot.fontSize = db.fontSize or 14
	s.snapshot.tooltip = getOptionsHint()
end

local provider = {
	id = "realm",
	version = 1,
	title = L["Realm"] or "Realm",
	update = updateRealm,
	events = {
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

hooksecurefunc(addon.DataHub, "Subscribe", function(_, name)
	if name ~= provider.id then return end
	if not stream then return end
	if stream.snapshot and stream.snapshot.text and stream.snapshot.text ~= "" then
		addon.DataHub:Publish(stream, stream.snapshot)
	else
		addon.DataHub:RequestUpdate(stream)
	end
end)

return provider
