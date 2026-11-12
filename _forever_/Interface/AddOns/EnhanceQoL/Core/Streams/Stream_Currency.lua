-- luacheck: globals EnhanceQoL C_CurrencyInfo ITEM_QUALITY_COLORS HIGHLIGHT_FONT_COLOR_CODE RED_FONT_COLOR_CODE FONT_COLOR_CODE_CLOSE CURRENCY_SEASON_TOTAL_MAXIMUM CURRENCY_SEASON_TOTAL CURRENCY_TOTAL CURRENCY_TOTAL_CAP BreakUpLargeNumbers NORMAL_FONT_COLOR
local addonName, addon = ...
local L = addon.L

local db
local stream
local tracked = {}
local trackedDirty = true
local displayIDs = {}

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local format = string.format

local MAX_DECIMALS = 3
local SHORT_SUFFIXES = { "K", "M", "B", "T", "P", "E" }
local EMPTY_TRACKING_TEXT = L["No currency tracking"] or "No currency tracking"

local checkCurrencies
local updateCurrency
local fullUpdate

local function markTrackedDirty()
	trackedDirty = true
end

addon.DataPanelCurrency = addon.DataPanelCurrency or {}
addon.DataPanelCurrency.MarkTrackedDirty = markTrackedDirty
addon.DataPanelCurrency.RequestFullUpdate = function()
	markTrackedDirty()
	fullUpdate(stream)
end

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function publish(s)
	s = s or stream
	if s then addon.DataHub:Publish(s, s.snapshot) end
end

fullUpdate = function(s)
	s = s or stream
	if not s then return end
	checkCurrencies(s)
	publish(s)
end

local function rebuildTracked()
	if not db then return end
	for k in pairs(tracked) do
		tracked[k] = nil
	end
	for _, id in ipairs(displayIDs) do
		tracked[id] = true
	end
	trackedDirty = false
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.currency = addon.db.datapanel.currency or {}
	db = addon.db.datapanel.currency
	db.fontSize = db.fontSize or 14
	db.ids = db.ids or {}
	db.currencyOptions = db.currencyOptions or {}
	db.tooltipPerCurrency = db.tooltipPerCurrency or false
	if db.showDescription == nil then db.showDescription = true end
	if db.useTextColor == nil then db.useTextColor = false end
	if db.includeBlizzardTracked == nil then db.includeBlizzardTracked = false end
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	if trackedDirty then rebuildTracked() end
end

local function addDisplayID(id, seen)
	id = tonumber(id)
	if not id or id <= 0 or seen[id] then return end
	displayIDs[#displayIDs + 1] = id
	seen[id] = true
end

local function addBlizzardTrackedCurrencies(seen)
	if not (db and db.includeBlizzardTracked and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo) then return end
	local currencyCount = tonumber(C_CurrencyInfo.GetCurrencyListSize()) or 0
	for index = 1, currencyCount do
		local info = C_CurrencyInfo.GetCurrencyListInfo(index)
		local id = info and (info.currencyTypesID or info.currencyID or info.id)
		if id and info.isShowInBackpack then addDisplayID(id, seen) end
	end
end

local function rebuildDisplayIDs()
	for index = #displayIDs, 1, -1 do
		displayIDs[index] = nil
	end
	local seen = {}
	for _, id in ipairs(db.ids or {}) do addDisplayID(id, seen) end
	addBlizzardTrackedCurrencies(seen)
	markTrackedDirty()
	rebuildTracked()
	return displayIDs
end

local function clampDecimals(value)
	local decimals = tonumber(value) or 0
	if decimals < 0 then
		decimals = 0
	elseif decimals > MAX_DECIMALS then
		decimals = MAX_DECIMALS
	end
	return floor(decimals + 0.5)
end

local function getCurrencyOptions(id)
	db.currencyOptions[id] = db.currencyOptions[id] or {}
	local opts = db.currencyOptions[id]
	opts.mode = opts.mode == "short" and "short" or "full"
	opts.decimals = clampDecimals(opts.decimals)
	return opts
end

local function trimDecimals(text)
	local trimmed = text:gsub("(%..-)0+$", "%1")
	return trimmed:gsub("%.$", "")
end

local function truncateDecimals(value, decimals)
	decimals = decimals or 0
	if decimals <= 0 then return value >= 0 and floor(value) or ceil(value) end
	local factor = 10 ^ decimals
	if value >= 0 then
		return floor(value * factor) / factor
	else
		return ceil(value * factor) / factor
	end
end

local function abbreviateNumber(value, decimals)
	local absValue = abs(value)
	local suffix = ""
	local scaled = value
	for i = 1, #SHORT_SUFFIXES do
		if absValue >= 1000 then
			absValue = absValue / 1000
			scaled = scaled / 1000
			suffix = SHORT_SUFFIXES[i]
		else
			break
		end
	end
	if suffix == "" then
		if BreakUpLargeNumbers then return BreakUpLargeNumbers(value) end
		return tostring(value)
	end
	local truncated = truncateDecimals(scaled, decimals)
	local text
	if decimals > 0 then
		text = trimDecimals(("%." .. decimals .. "f"):format(truncated))
	else
		text = ("%d"):format(truncated)
	end
	return text .. suffix
end

local function formatCurrencyAmount(id, amount)
	local opts = getCurrencyOptions(id)
	if opts.mode == "short" then return abbreviateNumber(amount, opts.decimals or 0) end
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(amount) end
	return tostring(amount)
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_currency_fontSize")
	end
end

local function colorToCode(color)
	local r = floor(((color and color.r) or 1) * 255 + 0.5)
	local g = floor(((color and color.g) or 1) * 255 + 0.5)
	local b = floor(((color and color.b) or 1) * 255 + 0.5)
	return format("|cff%02x%02x%02x", r, g, b)
end

local function resolveQuantityColorCode(info, qty)
	if db and db.useTextColor and db.textColor then return colorToCode(db.textColor) end
	local colorCode = HIGHLIGHT_FONT_COLOR_CODE
	if info.useTotalEarnedForMaxQty and info.maxQuantity and info.maxQuantity > 0 then
		local earnedRaw = info.totalEarned or info.trackedQuantity or 0
		if earnedRaw >= info.maxQuantity then colorCode = RED_FONT_COLOR_CODE end
	elseif info.maxQuantity and info.maxQuantity > 0 and qty >= info.maxQuantity then
		colorCode = RED_FONT_COLOR_CODE
	end
	return colorCode
end

local iconCache = {} -- [currencyID] = texturePath or fileID
local idToIndex = {} -- [currencyID] = index in parts
local tooltipParts = {} -- [currencyID] = { lines }

local function rebuildTooltip(s)
	s = s or stream
	if db.tooltipPerCurrency then
		s.snapshot.tooltip = nil
		s.snapshot.perCurrency = true
		s.snapshot.showDescription = db.showDescription
		return
	end
	local tips = {}
	for _, id in ipairs(db.ids) do
		local lines = tooltipParts[id]
		if lines then
			for i = 1, #lines do
				tips[#tips + 1] = lines[i]
			end
		end
	end
	if #tips > 0 then
		if tips[#tips] == "" then tips[#tips] = nil end
		local hint = getOptionsHint()
		if hint then
			tips[#tips + 1] = ""
			tips[#tips + 1] = hint
		end
		if #tips > 0 then
			s.snapshot.tooltip = table.concat(tips, "\n")
		else
			s.snapshot.tooltip = hint
		end
	else
		s.snapshot.tooltip = EMPTY_TRACKING_TEXT
	end
	s.snapshot.perCurrency = false
	s.snapshot.showDescription = db.showDescription
end

checkCurrencies = function(s)
	s = s or stream
	ensureDB()
	rebuildDisplayIDs()
	local size = db.fontSize or 14
	local parts = {}
	for k in pairs(idToIndex) do
		idToIndex[k] = nil
	end
	for k in pairs(tooltipParts) do
		tooltipParts[k] = nil
	end
	for _, id in ipairs(displayIDs) do
		local info = C_CurrencyInfo.GetCurrencyInfo(id)
		if info then
			if not iconCache[id] and info.iconFileID then iconCache[id] = info.iconFileID end
			local icon = iconCache[id] or info.iconFileID
			local qty = info.quantity or 0
			local colorCode = resolveQuantityColorCode(info, qty)
			local qtyText = formatCurrencyAmount(id, qty)
			parts[#parts + 1] = {
				id = id,
				text = format("|T%s:%d:%d:0:0|t %s%s%s", icon or 0, size, size, colorCode, qtyText, FONT_COLOR_CODE_CLOSE),
			}
			idToIndex[id] = #parts
			if not db.tooltipPerCurrency then
				local lines = {}
				local color = ITEM_QUALITY_COLORS[info.quality]
				local name = (color and color.hex or "|cffffffff") .. (info.name or ("ID %d"):format(id)) .. "|r"
				lines[#lines + 1] = name
				if db.showDescription and info.description and info.description ~= "" then lines[#lines + 1] = info.description end
				lines[#lines + 1] = ""
				lines[#lines + 1] = CURRENCY_TOTAL:format(HIGHLIGHT_FONT_COLOR_CODE, BreakUpLargeNumbers(qty)) .. FONT_COLOR_CODE_CLOSE
				if info.useTotalEarnedForMaxQty then
					local earnedRaw = info.totalEarned or info.trackedQuantity or 0
					local earned = BreakUpLargeNumbers(earnedRaw)
					if info.maxQuantity and info.maxQuantity > 0 then
						local colorCode2 = earnedRaw >= info.maxQuantity and RED_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
						lines[#lines + 1] = CURRENCY_SEASON_TOTAL_MAXIMUM:format(colorCode2, earned, BreakUpLargeNumbers(info.maxQuantity)) .. FONT_COLOR_CODE_CLOSE
					else
						lines[#lines + 1] = CURRENCY_SEASON_TOTAL:format(HIGHLIGHT_FONT_COLOR_CODE, earned) .. FONT_COLOR_CODE_CLOSE
					end
				elseif info.maxQuantity and info.maxQuantity > 0 then
					local colorCode2 = qty >= info.maxQuantity and RED_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
					lines[#lines + 1] = CURRENCY_TOTAL_CAP:format(colorCode2, BreakUpLargeNumbers(qty), BreakUpLargeNumbers(info.maxQuantity)) .. FONT_COLOR_CODE_CLOSE
				end
				lines[#lines + 1] = ""
				tooltipParts[id] = lines
			end
		end
	end
	if #parts > 0 then
		s.snapshot.parts = parts
		s.snapshot.text = nil
	else
		s.snapshot.parts = nil
		local emptyText = EMPTY_TRACKING_TEXT
		if db and db.useTextColor and db.textColor then emptyText = format("%s%s%s", colorToCode(db.textColor), EMPTY_TRACKING_TEXT, FONT_COLOR_CODE_CLOSE) end
		s.snapshot.text = emptyText
	end
	s.snapshot.fontSize = size
	rebuildTooltip(s)
end

updateCurrency = function(s, id)
	s = s or stream
	ensureDB()
	local idx = idToIndex[id]
	if not idx then
		fullUpdate(s)
		return
	end
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	if not info then return end
	if not iconCache[id] and info.iconFileID then iconCache[id] = info.iconFileID end
	local icon = iconCache[id] or info.iconFileID
	local qty = info.quantity or 0
	local colorCode = resolveQuantityColorCode(info, qty)
	local size = db.fontSize or 14
	local qtyText = formatCurrencyAmount(id, qty)
	s.snapshot.parts[idx].text = format("|T%s:%d:%d:0:0|t %s%s%s", icon or 0, size, size, colorCode, qtyText, FONT_COLOR_CODE_CLOSE)
	if not db.tooltipPerCurrency then
		local lines = {}
		local color = ITEM_QUALITY_COLORS[info.quality]
		local name = (color and color.hex or "|cffffffff") .. (info.name or ("ID %d"):format(id)) .. "|r"
		lines[#lines + 1] = name
		if db.showDescription and info.description and info.description ~= "" then lines[#lines + 1] = info.description end
		lines[#lines + 1] = ""
		lines[#lines + 1] = CURRENCY_TOTAL:format(HIGHLIGHT_FONT_COLOR_CODE, BreakUpLargeNumbers(qty)) .. FONT_COLOR_CODE_CLOSE
		if info.useTotalEarnedForMaxQty then
			local earnedRaw = info.totalEarned or info.trackedQuantity or 0
			local earned = BreakUpLargeNumbers(earnedRaw)
			if info.maxQuantity and info.maxQuantity > 0 then
				local colorCode2 = earnedRaw >= info.maxQuantity and RED_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
				lines[#lines + 1] = CURRENCY_SEASON_TOTAL_MAXIMUM:format(colorCode2, earned, BreakUpLargeNumbers(info.maxQuantity)) .. FONT_COLOR_CODE_CLOSE
			else
				lines[#lines + 1] = CURRENCY_SEASON_TOTAL:format(HIGHLIGHT_FONT_COLOR_CODE, earned) .. FONT_COLOR_CODE_CLOSE
			end
		elseif info.maxQuantity and info.maxQuantity > 0 then
			local colorCode2 = qty >= info.maxQuantity and RED_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
			lines[#lines + 1] = CURRENCY_TOTAL_CAP:format(colorCode2, BreakUpLargeNumbers(qty), BreakUpLargeNumbers(info.maxQuantity)) .. FONT_COLOR_CODE_CLOSE
		end
		lines[#lines + 1] = ""
		tooltipParts[id] = lines
		rebuildTooltip(s)
	end
	publish(s)
end

local provider = {
	id = "currency",
	version = 3,
	title = CURRENCY,
	update = checkCurrencies,
	events = {
		PLAYER_LOGIN = function(s) fullUpdate(s) end,
		CURRENCY_DISPLAY_UPDATE = function(s, _, currencyType)
			if db and db.includeBlizzardTracked then
				fullUpdate(s)
			elseif tracked[currencyType] then
				updateCurrency(s, currencyType)
			end
		end,
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
