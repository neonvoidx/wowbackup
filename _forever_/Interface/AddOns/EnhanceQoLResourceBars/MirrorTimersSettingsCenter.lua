local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local MirrorTimers = addon.MirrorTimers
if not MirrorTimers or not MirrorTimers:IsSupported(true) then return end
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local section = addon.SettingsLayout and addon.SettingsLayout.suitesResourceBarsSection
if not section then return end

addon.functions.SettingsCreateHeadline(nil, L["mirrorTimers"], { parentSection = section })
addon.functions.SettingsCreateCheckbox(nil, {
	var = "mirrorTimersEnabled",
	storage = false,
	default = false,
	text = L["mirrorTimersEnable"],
	desc = L["mirrorTimersDesc"],
	newTagID = "mirrorTimersEnabled",
	get = function() return addon.db and addon.db.mirrorTimers and addon.db.mirrorTimers.enabled == true or false end,
	func = function(value) MirrorTimers:SetEnabled(value == true) end,
	parentSection = section,
})
addon.functions.SettingsCreateText(nil, L["mirrorTimersDesc"], { parentSection = section })
