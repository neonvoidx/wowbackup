-- luacheck: globals EnhanceQoL NORMAL_FONT_COLOR
local addonName, addon = ...
local L = addon.L

local db
local stream

local floor = math.floor
local format = string.format
local GetMoney = GetMoney
local GetClassInfo = GetClassInfo
local UnitGUID = UnitGUID
local OpenAllBags = OpenAllBags
local ToggleAllBags = ToggleAllBags

local function getPrivateDB()
	return addon.functions.GetPrivateDB and addon.functions.GetPrivateDB() or addon.privateDB or {}
end

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
	addon.db.datapanel.gold = addon.db.datapanel.gold or {}
	db = addon.db.datapanel.gold
	db.fontSize = db.fontSize or 14
	db.displayMode = db.displayMode or "character"
	if db.displayMode == "account" then db.displayMode = "warband" end
	db.leftClickAction = db.leftClickAction or "toggleDisplay"
	if db.leftClickAction ~= "toggleDisplay" and db.leftClickAction ~= "openBags" then db.leftClickAction = "toggleDisplay" end
	if db.showSilverCopper == nil then db.showSilverCopper = false end
	if db.useTextColor == nil then db.useTextColor = false end
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
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_gold_fontSize")
	end
end

local COPPER_PER_GOLD = 10000
local COPPER_PER_SILVER = 100

local function colorizeValue(text, color)
	if not text or text == "" then return text end
	if color and color.r and color.g and color.b then return format("|cff%02x%02x%02x%s|r", floor(color.r * 255 + 0.5), floor(color.g * 255 + 0.5), floor(color.b * 255 + 0.5), text) end
	return text
end

local function splitMoney(copper)
	copper = floor(copper or 0)
	local g = floor(copper / COPPER_PER_GOLD)
	local s = floor((copper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
	local c = copper % COPPER_PER_SILVER
	local gText = (BreakUpLargeNumbers and BreakUpLargeNumbers(g)) or tostring(g)
	return g, s, c, gText
end

local function formatGoldString(copper)
	local _, s, c, gText = splitMoney(copper)
	return gText, s, c
end

local function formatMoney(value)
	local amount = value or 0
	if db and db.showSilverCopper then
		local g, s, c, gText = splitMoney(amount)
		local parts = {}
		if g > 0 then parts[#parts + 1] = ("%s|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"):format(gText) end
		if g > 0 or s > 0 then parts[#parts + 1] = ("%02d|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"):format(s) end
		parts[#parts + 1] = ("%02d|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"):format(c)
		return table.concat(parts, " ")
	end
	if addon.functions and addon.functions.formatMoney then return addon.functions.formatMoney(amount, "tracker") end
	return tostring(value or 0)
end

local function resolveClassColor(classInfo)
	local classToken = classInfo
	if type(classInfo) == "number" and GetClassInfo then classToken = select(2, GetClassInfo(classInfo)) end
	return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
end

local function collectCharacterMoneyFromTracker()
	local list, total, currentMoney = {}, 0, nil
	local playerGUID = UnitGUID("player")
	local privateDB = getPrivateDB()
	local dedupedByCharacter = {}

	local function buildCharacterKey(info, guid)
		if type(info) ~= "table" then return guid end
		local name = type(info.name) == "string" and info.name or ""
		local realm = type(info.realm) == "string" and info.realm or ""
		if name ~= "" then return string.lower(name) .. "|" .. string.lower(realm) end
		return guid
	end

	local function shouldReplaceCharacter(existing, candidate)
		if not existing then return true end
		if candidate.isPlayer and not existing.isPlayer then return true end
		if existing.isPlayer and not candidate.isPlayer then return false end
		return (candidate.money or 0) > (existing.money or 0)
	end

	if type(privateDB.moneyTracker) == "table" then
		for guid, info in pairs(privateDB.moneyTracker) do
			if type(info) == "table" and type(info.money) == "number" then
				local candidate = {
					name = info.name,
					realm = info.realm,
					class = info.class,
					money = info.money,
					isPlayer = guid == playerGUID,
				}
				local key = buildCharacterKey(info, guid)
				if shouldReplaceCharacter(dedupedByCharacter[key], candidate) then dedupedByCharacter[key] = candidate end
			end
		end
	end
	for _, info in pairs(dedupedByCharacter) do
		total = total + info.money
		if info.isPlayer then currentMoney = info.money end
		info.isPlayer = nil
		list[#list + 1] = info
	end
	table.sort(list, function(a, b)
		local am = a.money or 0
		local bm = b.money or 0
		if am == bm then return (a.name or "") < (b.name or "") end
		return am > bm
	end)
	return list, total, currentMoney
end

local function collectCharacterMoney()
	local list, total, currentMoney = collectCharacterMoneyFromTracker()
	return list, total, currentMoney
end

local function formatPanelMoney(copper, size)
	local gText, s, c = formatGoldString(copper)
	if not db or not db.showSilverCopper then return ("|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:0:0|t %s"):format(size, size, gText) end
	return ("%s|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:0:0|t %02d|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:0:0|t %02d|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:0:0|t"):format(
		gText,
		size,
		size,
		s,
		size,
		size,
		c,
		size,
		size
	)
end

local function getDisplayLabel()
	if db and db.displayMode == "warband" then return L["warbandGold"] or "Warband gold" end
	return CHARACTER
end

local function getLeftClickAction()
	if db and db.leftClickAction == "openBags" then return "openBags" end
	return "toggleDisplay"
end

local function getLeftClickHint()
	if getLeftClickAction() == "openBags" then return L["goldPanelClickHintOpenBags"] or "Left-click to open bags" end
	return L["Left-click to toggle warband/character gold"] or "Left-click to toggle warband/character gold"
end

local function toggleDisplayMode()
	ensureDB()
	if db.displayMode == "warband" then
		db.displayMode = "character"
	else
		db.displayMode = "warband"
	end
	addon.DataHub:RequestUpdate(stream)
end

local function openBags()
	if OpenAllBags then
		OpenAllBags()
	elseif ToggleAllBags then
		ToggleAllBags()
	end
end

local function checkMoney(stream)
	ensureDB()
	if db.displayMode == "account" then db.displayMode = "warband" end
	local privateDB = getPrivateDB()
	local money = GetMoney() or 0
	if db.displayMode == "warband" then money = privateDB.warbandGold or 0 end
	if db.displayMode ~= "warband" then
		local _, _, currentMoney = collectCharacterMoney()
		if type(currentMoney) == "number" then money = currentMoney end
	end
	local size = db and db.fontSize or 12
	stream.snapshot.fontSize = size
	local text = formatPanelMoney(money, size)
	if db and db.useTextColor and db.textColor then text = colorizeValue(text, db.textColor) end
	stream.snapshot.text = text
	stream.snapshot.tooltip = nil
end

local provider = {
	id = "gold",
	version = 3,
	title = WORLD_QUEST_REWARD_FILTERS_GOLD,
	update = checkMoney,
	events = {
		PLAYER_MONEY = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_LOGIN = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ACCOUNT_MONEY = function(stream) addon.DataHub:RequestUpdate(stream) end,
	},
	OnClick = function(_, btn)
		if btn == "LeftButton" then
			ensureDB()
			if getLeftClickAction() == "openBags" then
				openBags()
			else
				toggleDisplayMode()
			end
		elseif btn == "RightButton" then
			openSettings()
		end
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

		local warband = getPrivateDB().warbandGold
		if warband ~= nil then tip:AddDoubleLine(L["warbandGold"] or "Warband gold", formatMoney(warband)) end

		local list, total = collectCharacterMoney()
		if #list > 0 then
			if warband ~= nil then tip:AddLine(" ") end
			tip:AddLine((CHARACTER) .. ":")
			for _, info in ipairs(list) do
				local name = info.name or UNKNOWN
				local color = resolveClassColor(info.class)
				if color then name = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name) end
				tip:AddDoubleLine(name, formatMoney(info.money))
			end
			tip:AddLine(" ")
			tip:AddDoubleLine(TOTAL or "Total", formatMoney(total))
		end

		local clickHint = getLeftClickHint()
		local modeHint = (L["goldPanelDisplay"] or "Gold display") .. ": " .. getDisplayLabel()
		local hint = getOptionsHint()
		if clickHint or modeHint or hint then
			tip:AddLine(" ")
			if clickHint then tip:AddLine(clickHint, 0.7, 0.7, 0.7) end
			if modeHint then tip:AddLine(modeHint, 0.7, 0.7, 0.7) end
			if hint then tip:AddLine(hint, 0.7, 0.7, 0.7) end
		end
		tip:Show()
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
