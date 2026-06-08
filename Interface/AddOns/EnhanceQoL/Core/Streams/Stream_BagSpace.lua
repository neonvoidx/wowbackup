-- luacheck: globals EnhanceQoL NORMAL_FONT_COLOR Enum C_Container GetContainerNumSlots GetContainerNumFreeSlots
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
	addon.db.datapanel.bagspace = addon.db.datapanel.bagspace or {}
	db = addon.db.datapanel.bagspace
	db.fontSize = db.fontSize or 14
	db.displayMode = db.displayMode or "freeMax"
	if db.ignoreComponentsBag == nil then db.ignoreComponentsBag = false end
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
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_bagspace_fontSize")
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

local GetContainerNumSlotsFn = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local GetContainerNumFreeSlotsFn = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
local REAGENT_BAG = (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 5
local BAG_ICON = "Interface\\Icons\\INV_Misc_Bag_08"
local BAG_IDS = { 0, 1, 2, 3, 4, REAGENT_BAG }

local function getBagSpace(ignoreComponentsBag)
	if not GetContainerNumSlotsFn or not GetContainerNumFreeSlotsFn then return 0, 0 end
	local free, total = 0, 0
	for _, bag in ipairs(BAG_IDS) do
		if not (ignoreComponentsBag and bag == REAGENT_BAG) then
			local slots = GetContainerNumSlotsFn(bag)
			if slots and slots > 0 then
				total = total + slots
				local freeSlots = GetContainerNumFreeSlotsFn(bag)
				if freeSlots and freeSlots > 0 then free = free + freeSlots end
			end
		end
	end
	return free, total
end

local function updateBagSpace(s)
	s = s or stream
	ensureDB()

	local free, total = getBagSpace(db.ignoreComponentsBag)
	local current = total - free
	if current < 0 then current = 0 end
	local size = db.fontSize or 14
	local displayMode = db.displayMode or "freeMax"
	local text
	if displayMode == "free" then
		text = tostring(free)
	elseif displayMode == "currentMax" then
		text = ("%d/%d"):format(current, total)
	else
		text = ("%d/%d"):format(free, total)
	end
	text = colorize(text)
	if not db.hideIcon then text = ("|T%s:%d:%d:0:0|t %s"):format(BAG_ICON, size, size, text) end

	s.snapshot.text = text
	s.snapshot.fontSize = size

	local tooltip = (L["Bag Space"] or "Bag Space") .. ": " .. tostring(free) .. "/" .. tostring(total)
	tooltip = tooltip .. "\n" .. (L["Current/Max"] or "Current/Max") .. ": " .. tostring(current) .. "/" .. tostring(total)
	local hint = getOptionsHint()
	if hint then tooltip = tooltip .. "\n" .. hint end
	s.snapshot.tooltip = tooltip
end

local provider = {
	id = "bagspace",
	version = 2,
	title = L["Bag Space"] or "Bag Space",
	update = updateBagSpace,
	events = {
		BAG_UPDATE_DELAYED = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_ENTERING_WORLD = function(s) addon.DataHub:RequestUpdate(s) end,
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
