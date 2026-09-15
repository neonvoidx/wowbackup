-- luacheck: globals EnhanceQoL UnitFullName UnitName UnitClass UnitFactionGroup GetRealmName NORMAL_FONT_COLOR CUSTOM_CLASS_COLORS RAID_CLASS_COLORS
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
	addon.db.datapanel.playername = addon.db.datapanel.playername or {}
	db = addon.db.datapanel.playername
	db.fontSize = db.fontSize or 14
	if db.showRealm == nil then db.showRealm = false end
	if db.useClassColor == nil then db.useClassColor = true end
	if db.useFactionColor == nil then db.useFactionColor = false end
	if db.useTextColor == nil then db.useTextColor = false end
	if db.separateRealmColor == nil then db.separateRealmColor = false end
	if db.realmUseClassColor == nil then db.realmUseClassColor = false end
	if db.realmUseFactionColor == nil then db.realmUseFactionColor = true end
	if db.realmUseTextColor == nil then db.realmUseTextColor = false end
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	if not db.realmTextColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.realmTextColor = { r = r, g = g, b = b }
	end
	db.allianceColor = db.allianceColor or { r = 0.345, g = 0.702, b = 1, a = 1 }
	db.hordeColor = db.hordeColor or { r = 1, g = 0.267, b = 0.267, a = 1 }
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_playername_fontSize")
	end
end

local function getPlayerNameParts()
	local name, realm
	if UnitFullName then name, realm = UnitFullName("player") end
	if not name or name == "" then name = UnitName and UnitName("player") end
	if not name or name == "" then return "", nil end
	if db and db.showRealm then
		if not realm or realm == "" then realm = GetRealmName and GetRealmName() end
		if realm and realm ~= "" then return name, realm end
	end
	return name, nil
end

local function getClassColor()
	local classToken = UnitClass and select(2, UnitClass("player"))
	local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	return classToken and colors and colors[classToken]
end

local function getFactionColor()
	local factionGroup = UnitFactionGroup and UnitFactionGroup("player")
	if factionGroup == "Alliance" then return db and db.allianceColor end
	if factionGroup == "Horde" then return db and db.hordeColor end
end

local function colorizeWithColor(text, color)
	if not text or text == "" then return "" end
	if not color then return text end
	local r = math.floor((color.r or 1) * 255 + 0.5)
	local g = math.floor((color.g or 1) * 255 + 0.5)
	local b = math.floor((color.b or 1) * 255 + 0.5)
	return ("|cff%02x%02x%02x%s|r"):format(r, g, b, text)
end

local function getMainColor()
	if db and db.useTextColor then
		return db.textColor
	elseif db and db.useFactionColor then
		return getFactionColor()
	elseif db and db.useClassColor then
		return getClassColor()
	end
end

local function getRealmColor()
	if db and db.realmUseTextColor then
		return db.realmTextColor
	elseif db and db.realmUseFactionColor then
		return getFactionColor()
	elseif db and db.realmUseClassColor then
		return getClassColor()
	end
end

local function getPlayerNameText()
	local name, realm = getPlayerNameParts()
	if not realm then return colorizeWithColor(name, getMainColor()) end
	if db and db.separateRealmColor then
		return colorizeWithColor(name, getMainColor()) .. "-" .. colorizeWithColor(realm, getRealmColor())
	end
	return colorizeWithColor(name .. "-" .. realm, getMainColor())
end

local function updatePlayerName(s)
	s = s or stream
	if not s then return end
	ensureDB()
	s.snapshot.text = getPlayerNameText()
	s.snapshot.fontSize = db.fontSize or 14
	s.snapshot.tooltip = getOptionsHint()
	s.snapshot.skipPanelClassColor = true
end

local provider = {
	id = "playername",
	version = 1,
	title = (PLAYER or "Player") .. " " .. (NAME or "Name"),
	update = updatePlayerName,
	events = {
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
