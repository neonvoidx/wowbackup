local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

addon.CooldownPulse = {}
local P = addon.CooldownPulse
P.L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
P.media = LibStub("LibSharedMedia-3.0", true)
P.frames, P.states, P.selectedSpells = {}, {}, {}
-- Forever uses restricted cooldowns and native duration objects like Retail.
P.classic = addon.variables.isTBC == true
P.defaults = {
	iconSize = 75, fadeInTime = 0.3, holdTime = 0, fadeOutTime = 0.7, maxAlpha = 0.7, animScale = 1.5,
	showName = true, customTextEnabled = false, customText = "", useAdvancedTracking = true,
	font = "DEFAULT", fontSize = 14, outline = "OUTLINE", textColor = { 1, 1, 1, 1 }, textX = 0, textY = 0,
	borderEnabled = false, border = "DEFAULT", borderSize = 2, borderOffset = 0, borderColor = { 1, 1, 1, 1 }, strata = "MEDIUM",
	aspectRatio = 1, iconColor = { 1, 1, 1, 1 }, desaturate = false,
	glowStyle = "NONE", glowColor = { 1, 0.82, 0, 1 }, glowSpeed = 0.25, glowThickness = 2, glowLines = 8,
	soundMode = "INHERIT", soundKey = "DEFAULT", soundChannel = "Master",
}
P.nativeGlowStyles = { NONE = true, BLIZZARD = true, MARCHING_ANTS = true, FLASH = true, PIXEL = true, PULSING = true, SOLID = true }
P.styleSections = {
	appearance = { "iconSize", "aspectRatio", "iconColor", "desaturate" },
	animation = { "fadeInTime", "holdTime", "fadeOutTime", "maxAlpha", "animScale" },
	text = { "showName", "customTextEnabled", "customText", "font", "fontSize", "outline", "textColor", "textX", "textY" },
	border = { "borderEnabled", "border", "borderSize", "borderOffset", "borderColor" },
	glow = { "glowStyle", "glowColor", "glowSpeed", "glowThickness", "glowLines" },
}
P.soundDefaults = { enabled = false, key = "DEFAULT", channel = "Master" }
P.channels = { Master = true, SFX = true, Music = true, Ambience = true, Dialog = true }
P.entryDefaults = {}
for section in pairs(P.styleSections) do P.entryDefaults["override_" .. section] = false end
for _, fields in pairs(P.styleSections) do for _, key in ipairs(fields) do P.entryDefaults[key] = P.defaults[key] end end
for _, key in ipairs({ "soundMode", "soundKey", "soundChannel" }) do P.entryDefaults[key] = P.defaults[key] end

function P.Copy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = P.Copy(v) end
	return copy
end

function P.Safe(value) return not (_G.issecretvalue and _G.issecretvalue(value)) end
function P.Number(value, fallback, low, high)
	value = tonumber(value)
	if not value or value ~= value then return fallback end
	return math.max(low, math.min(high, value))
end

function P:DB() return addon.db.cooldownPulse end
function P:Group(id) return self:DB().groups[id] end
function P:Enabled(id) return self:Group(id) and self:Group(id).enabled == true end
function P:FrameID(id) return "cooldownPulseGroup" .. id end

function P:NormalizeStyle(value, defaults)
	for key, fallback in pairs(defaults) do
		if type(value[key]) ~= type(fallback) then value[key] = self.Copy(fallback) end
	end
	local ranges = {
		iconSize = { 20, 200 }, aspectRatio = { 0.5, 2 }, fadeInTime = { 0, 3 }, fadeOutTime = { 0, 3 }, holdTime = { 0, 5 },
		maxAlpha = { 0, 1 }, animScale = { 0.5, 3 }, fontSize = { 6, 64 }, textX = { -300, 300 }, textY = { -300, 300 },
		borderSize = { 1, 50 }, borderOffset = { -50, 50 }, glowSpeed = { 0.05, 2 }, glowThickness = { 1, 8 }, glowLines = { 1, 16 },
	}
	for key, range in pairs(ranges) do value[key] = self.Number(value[key], self.defaults[key], range[1], range[2]) end
	value.glowLines = math.floor(value.glowLines)
	for _, key in ipairs({ "iconColor", "textColor", "borderColor", "glowColor" }) do value[key] = self.Color(value[key], self.defaults[key]) end
	if value.outline ~= "" and value.outline ~= "OUTLINE" and value.outline ~= "THICKOUTLINE" then value.outline = "OUTLINE" end
	if not self.nativeGlowStyles[value.glowStyle] then value.glowStyle = "NONE" end
	if not ({ INHERIT = true, OFF = true, CUSTOM = true })[value.soundMode] then value.soundMode = "INHERIT" end
	if not self.channels[value.soundChannel] then value.soundChannel = "Master" end
	value.customText = value.customText:sub(1, 128)
	return value
end

function P:Normalize(cat)
	self:NormalizeStyle(cat, self.defaults)
	cat.enabled = cat.enabled ~= false
	cat.name = type(cat.name) == "string" and cat.name:sub(1, 96) or self.L["CooldownPulse"]
	if not ({ BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true, DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true })[cat.strata] then cat.strata = "MEDIUM" end
	cat.anchor = type(cat.anchor) == "table" and cat.anchor or {}
	if not ({ CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true, TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true })[cat.anchor.point] then cat.anchor.point = "CENTER" end
	cat.anchor.x, cat.anchor.y = self.Number(cat.anchor.x, 0, -10000, 10000), self.Number(cat.anchor.y, 0, -10000, 10000)
	cat.spells = self.NormalizeIDs(cat.spells, true)
	cat.ignoredSpells = self.NormalizeIDs(cat.ignoredSpells, false)
	return cat
end

function P:ResolveStyle(id, spellID)
	local group = self:Group(id)
	if not group then return end
	local entry, style = group.spells[spellID], {}
	for key, value in pairs(self.defaults) do style[key] = group[key] == nil and value or group[key] end
	for section, fields in pairs(self.styleSections) do
		if entry and entry["override_" .. section] then
			for _, key in ipairs(fields) do style[key] = entry[key] end
		end
	end
	style.name = group.name
	return style
end

function P:SetOverride(id, spellID, section, enabled)
	local group = self:Group(id)
	local entry = group and group.spells[spellID]
	if not entry or not self.styleSections[section] then return end
	entry.initializedOverrides = type(entry.initializedOverrides) == "table" and entry.initializedOverrides or {}
	if enabled and not entry.initializedOverrides[section] then
		entry.initializedOverrides[section] = true
		for _, key in ipairs(self.styleSections[section]) do entry[key] = self.Copy(group[key]) end
	end
	entry["override_" .. section] = enabled == true
end

function P:ResolveSound(id, spellID)
	local group = self:Group(id)
	if not group then return end
	local entry = group.spells[spellID]
	local source = entry and entry.soundMode ~= "INHERIT" and entry or group
	if source.soundMode == "OFF" then return end
	if source.soundMode == "CUSTOM" then return { key = source.soundKey, channel = source.soundChannel } end
	local global = self:DB().globalSound
	if global.enabled then return { key = global.key, channel = global.channel } end
end

function P.Color(value, fallback)
	value = type(value) == "table" and value or fallback
	return { P.Number(value.r or value[1], fallback[1], 0, 1), P.Number(value.g or value[2], fallback[2], 0, 1), P.Number(value.b or value[3], fallback[3], 0, 1), P.Number(value.a or value[4], fallback[4], 0, 1) }
end

function P.NormalizeIDs(values, entries)
	local result = {}
	for key, value in pairs(type(values) == "table" and values or {}) do
		local id = tonumber(key)
		if id and id == math.floor(id) and ((id > 0 and id < 10000000) or id == -13 or id == -14) and value then
			if entries then
				local entry = type(value) == "table" and value or {}
				P:NormalizeStyle(entry, P.entryDefaults)
				result[id] = entry
			else result[id] = true end
		end
	end
	return result
end

function P:InitDB()
	if type(addon.db.cooldownPulse) ~= "table" then addon.db.cooldownPulse = {} end
	local db = self:DB()
	db.version = 1
	if type(db.groups) ~= "table" then db.groups = {} end
	if type(db.globalSound) ~= "table" then db.globalSound = self.Copy(self.soundDefaults) end
	for key, value in pairs(self.soundDefaults) do if type(db.globalSound[key]) ~= type(value) then db.globalSound[key] = value end end
	if not self.channels[db.globalSound.channel] then db.globalSound.channel = "Master" end
	for id, cat in pairs(db.groups) do
		if type(id) == "number" and id > 0 and id == math.floor(id) and type(cat) == "table" then self:Normalize(cat)
		else db.groups[id] = nil end
	end
end

function P:IDs()
	local ids = {}
	for id, cat in pairs(self:DB().groups) do
		if type(id) == "number" and type(cat) == "table" then ids[#ids + 1] = id end
	end
	table.sort(ids)
	return ids
end

function P:AddGroup(cat)
	local id = 1
	while self:Group(id) do id = id + 1 end
	self:DB().groups[id] = self:Normalize(cat or { name = self.L["CooldownPulse"] .. " " .. id })
	self:DB().selectedGroup = id
	self:Refresh()
	return id
end

function P:DeleteGroup(id)
	if addon.EditModeLib then addon.EditModeLib:HideSettingsDialog(self.frames[id]) end
	if self.editGroup == id and self.FinishEditing then self:FinishEditing() end
	if self.frames[id] then self:Stop(self.frames[id]); self.frames[id]:Hide() end
	self.frames[id], self.states[id], self.selectedSpells[id] = nil, nil, nil
	self:DB().groups[id] = nil
	self:DB().selectedGroup = self:IDs()[1]
	self:Refresh()
end

function P:SpellInfo(id)
	if id < 0 then
		local itemID = GetInventoryItemID("player", -id)
		local name
		if itemID then
			if C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(itemID)
			elseif _G.GetItemInfo then name = _G.GetItemInfo(itemID) end
		end
		return name, GetInventoryItemTexture("player", -id), itemID
	end
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
	if info then return info.name, info.iconID, id end
	if _G.GetSpellInfo then local name, _, icon = _G.GetSpellInfo(id); return name, icon, id end
end

function P:Export(id)
	local cat = self:Group(id)
	if not cat then return end
	local data = { kind = "EQOL_COOLDOWN_PULSE_GROUP", version = 1, group = cat }
	local encoded = LibStub("AceSerializer-3.0"):Serialize(data)
	return LibStub("LibDeflate"):EncodeForPrint(LibStub("LibDeflate"):CompressDeflate(encoded))
end

function P:Import(encoded)
	if type(encoded) ~= "string" or #encoded > 100000 then return end
	local deflate = LibStub("LibDeflate")
	local decoded = deflate:DecodeForPrint(encoded)
	if not decoded then return end
	local raw = deflate:DecompressDeflate(decoded)
	if not raw or #raw > 1000000 then return end
	local ok, data = LibStub("AceSerializer-3.0"):Deserialize(raw)
	if not ok or type(data) ~= "table" or data.kind ~= "EQOL_COOLDOWN_PULSE_GROUP" or data.version ~= 1 or type(data.group) ~= "table" or type(data.group.spells) ~= "table" then return end
	return self:AddGroup(data.group)
end

P:InitDB()
