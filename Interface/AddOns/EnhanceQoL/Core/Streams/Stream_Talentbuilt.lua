-- luacheck: globals EnhanceQoL MenuResponse MenuUtil ClassTalentHelper PlayerSpellsMicroButton NORMAL_FONT_COLOR strcmputf8i
local addonName, addon = ...
local L = addon.L

local db
local provider
local TALENTS_PREFIX_DEFAULT = (TALENTS or "Talents") .. ":"
local floor = math.floor
local format = string.format
local sort = table.sort
local lower = string.lower

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
	addon.db.datapanel.talent = addon.db.datapanel.talent or {}
	db = addon.db.datapanel.talent
	db.prefix = db.prefix or TALENTS_PREFIX_DEFAULT
	db.fontSize = db.fontSize or 14
	db.hideIcon = db.hideIcon or false
	if db.useTextColor == nil then db.useTextColor = false end
	if db.usePrefixColor == nil then db.usePrefixColor = false end
	if not db.textColor then
		local r, g, b = 1, 1, 1
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
	if not db.prefixColor then db.prefixColor = { r = 0.75, g = 0.75, b = 0.75 } end
end

local function GetConfigName(configID)
	if configID then
		if type(configID) == "number" then
			local info = C_Traits.GetConfigInfo(configID)
			if info then return info.name end
		end
	end
	return UNKNOWN
end

local function switchToConfig(configID, index)
	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT) end
		return
	end
	if ClassTalentHelper and ClassTalentHelper.SwitchToLoadoutByIndex and index then
		ClassTalentHelper.SwitchToLoadoutByIndex(index)
		return
	end
	if C_ClassTalents and C_ClassTalents.SetActiveConfigID then
		C_ClassTalents.SetActiveConfigID(configID)
		return
	end
	if PlayerSpellsMicroButton then PlayerSpellsMicroButton:Click() end
end

local function compareLoadoutEntries(a, b)
	local aName = a.sortName or ""
	local bName = b.sortName or ""
	if strcmputf8i then
		local cmp = strcmputf8i(aName, bName)
		if cmp ~= 0 then return cmp < 0 end
	else
		local aLower = lower(aName)
		local bLower = lower(bName)
		if aLower ~= bLower then return aLower < bLower end
	end
	if a.originalIndex ~= b.originalIndex then return a.originalIndex < b.originalIndex end
	return (a.configID or 0) < (b.configID or 0)
end

local function showLoadoutMenu(owner)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end
	local specId = PlayerUtil.GetCurrentSpecID()
	if not specId then return end
	local configs = C_ClassTalents.GetConfigIDsBySpecID(specId) or {}
	local activeConfig = C_ClassTalents.GetLastSelectedSavedConfigID(specId)
	local inCombat = InCombatLockdown and InCombatLockdown()

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_TALENT_LOADOUTS")
		rootDescription:CreateTitle(TALENTS)

		if #configs == 0 then
			local row = rootDescription:CreateButton(L["No saved loadouts"] or "No saved loadouts")
			row:SetEnabled(false)
		else
			local entries = {}
			for index, configID in ipairs(configs) do
				local name = GetConfigName(configID)
				entries[#entries + 1] = {
					configID = configID,
					name = name,
					originalIndex = index,
					sortName = name ~= UNKNOWN and name or "",
				}
			end
			sort(entries, compareLoadoutEntries)
			for _, entry in ipairs(entries) do
				local configID = entry.configID
				local name = entry.name
				local radio = rootDescription:CreateRadio(name, function() return configID == activeConfig end, function()
					switchToConfig(configID, entry.originalIndex)
					return MenuResponse and MenuResponse.Close
				end, configID)
				if inCombat then radio:SetEnabled(false) end
			end
		end

		rootDescription:CreateDivider()
		rootDescription:CreateButton(L["Open Talents"] or "Open Talents", function()
			if PlayerSpellsMicroButton then PlayerSpellsMicroButton:Click() end
		end)
	end)
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_talent_prefix")
	end
end

local function colorizeText(text, color)
	if not text or text == "" then return text end
	if color and color.r and color.g and color.b then return format("|cff%02x%02x%02x%s|r", floor(color.r * 255 + 0.5), floor(color.g * 255 + 0.5), floor(color.b * 255 + 0.5), text) end
	return text
end

local function GetCurrentTalents(stream)
	ensureDB()
	local specId = PlayerUtil.GetCurrentSpecID()
	local name = UNKNOWN
	if specId then name = GetConfigName(C_ClassTalents.GetLastSelectedSavedConfigID(specId)) end
	local prefix = ""
	if db.prefix ~= "" then
		if db.prefix == TALENTS_PREFIX_DEFAULT then
			prefix = format("|cffc0c0c0%s|r ", TALENTS_PREFIX_DEFAULT)
		else
			prefix = db.prefix .. " "
		end
		if db.usePrefixColor and db.prefixColor then prefix = colorizeText(db.prefix .. " ", db.prefixColor) end
	end
	local icon = ""
	if not db.hideIcon then
		local size = db and db.fontSize or 14
		icon = format("|TInterface\\Addons\\EnhanceQoL\\Icons\\Talents:%d:%d:0:0|t ", size, size)
	end
	local nameText = name
	if db.useTextColor then nameText = colorizeText(name, db.textColor) end
	stream.snapshot.text = icon .. prefix .. nameText
	stream.snapshot.fontSize = db.fontSize
	local hint = getOptionsHint()
	local clickHint = L["Talent loadout click hint"] or "Left-click to switch loadout"
	if hint then
		stream.snapshot.tooltip = clickHint .. "\n" .. hint
	else
		stream.snapshot.tooltip = clickHint
	end
end

provider = {
	id = "talent",
	version = 3,
	title = TALENTS,
	update = GetCurrentTalents,
	events = {
		PLAYER_LOGIN = function(stream)
			C_Timer.After(1, function() addon.DataHub:RequestUpdate(stream) end)
		end,
		TRAIT_CONFIG_CREATED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		TRAIT_CONFIG_DELETED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		TRAIT_CONFIG_UPDATED = function(stream)
			C_Timer.After(0.02, function() addon.DataHub:RequestUpdate(stream) end)
		end,
		PLAYER_SPECIALIZATION_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ZONE_CHANGED_NEW_AREA = function(stream) addon.DataHub:RequestUpdate(stream) end,
	},
	OnClick = function(button, btn)
		if btn == "RightButton" then
			openSettings()
		else
			showLoadoutMenu(button)
		end
	end,
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
