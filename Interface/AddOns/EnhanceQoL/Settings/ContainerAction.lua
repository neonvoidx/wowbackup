local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cContainer = addon.SettingsLayout.rootGENERAL

local expandable = addon.functions.SettingsCreateExpandableSection(cContainer, {
	name = L["ContainerActions"],
	configPageKey = "ContainerActions",
	iconKey = "containeractions",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
})

local wOpen = false -- Variable to ignore multiple checks for openItems
local function isBankOpen()
	local bankAPI = _G.C_Bank
	if bankAPI and bankAPI.AreAnyBankTypesViewable and bankAPI.AreAnyBankTypesViewable() then return true end
	if BankFrame and BankFrame:IsShown() then return true end
	local guildBankFrame = _G.GuildBankFrame
	return guildBankFrame and guildBankFrame:IsShown() or false
end

local function stopContainerActions()
	if addon.ContainerActions and addon.ContainerActions.UpdateItems then addon.ContainerActions:UpdateItems({}) end
	wOpen = false
end

local function openItems(items)
	local madeProgress = false

	local function didItemProgress(beforeItemID, beforeCount, afterInfo)
		if not beforeItemID then return false end
		if not afterInfo or afterInfo.itemID ~= beforeItemID then return true end
		local afterCount = afterInfo.stackCount or 1
		return afterCount < beforeCount
	end

	local function openNextItem()
		if isBankOpen() then
			stopContainerActions()
			return
		end

		if #items == 0 then
			if madeProgress then
				addon.functions.checkForContainer()
			else
				wOpen = false
			end
			return
		end

		if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
			wOpen = false
			return
		end

		if MerchantFrame and MerchantFrame:IsShown() then
			wOpen = false
			return
		end

		local item = table.remove(items, 1)
		if not item then
			openNextItem()
			return
		end

		local beforeInfo = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(item.bag, item.slot)
		local beforeItemID = beforeInfo and beforeInfo.itemID
		local beforeCount = (beforeInfo and beforeInfo.stackCount) or 1
		if not beforeItemID then
			openNextItem()
			return
		end

		C_Timer.After(0.15, function()
			if isBankOpen() then
				stopContainerActions()
				return
			end
			C_Container.UseContainerItem(item.bag, item.slot)
			C_Timer.After(0.4, function()
				local afterInfo = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(item.bag, item.slot)
				if didItemProgress(beforeItemID, beforeCount, afterInfo) then madeProgress = true end
				openNextItem()
			end) -- 400ms Pause zwischen den boxen
		end)
	end
	openNextItem()
end
function addon.functions.checkForContainer(bags)
	if not addon.db["automaticallyOpenContainer"] then
		stopContainerActions()
		return
	end

	if isBankOpen() then
		stopContainerActions()
		return
	end

	local safeItems, secureItems = {}, {}
	if addon.ContainerActions and addon.ContainerActions.ScanBags then
		safeItems, secureItems = addon.ContainerActions:ScanBags(bags)
	end

	if addon.ContainerActions and addon.ContainerActions.UpdateItems then addon.ContainerActions:UpdateItems(secureItems, bags) end

	if #safeItems > 0 then
		openItems(safeItems)
	else
		wOpen = false
	end
end

local data = {

	var = "automaticallyOpenContainer",
	text = L["automaticallyOpenContainer"],
	func = function(value) addon.db["automaticallyOpenContainer"] = value and true or false end,
	desc = L["containerActionsFeatureDesc2"],
	modernDescription = (L["containerActionsFeatureDesc2"] or ""):match("^(.-[%.%!%?])%s+") or L["containerActionsFeatureDesc2"],
	parentSection = expandable,
}

addon.functions.SettingsCreateText(cContainer, L["containerActionsFeatureDesc2"], { parentSection = expandable })
addon.functions.SettingsCreateCheckbox(cContainer, data)

data = {
	var = "containerActionIncludeCosmeticItems",
	text = L["containerActionsIncludeCosmeticItems"],
	desc = L["containerActionsIncludeCosmeticItemsDesc"],
	newTagID = "containerActionIncludeCosmeticItems",
	func = function(value)
		addon.db.containerActionIncludeCosmeticItems = value and true or false
		if addon.functions and addon.functions.checkForContainer then addon.functions.checkForContainer() end
	end,
	parent = true,
	parentCheck = function()
		return addon.SettingsLayout.elements["automaticallyOpenContainer"].setting and addon.SettingsLayout.elements["automaticallyOpenContainer"].setting:GetValue() == true
	end,
	element = addon.SettingsLayout.elements["automaticallyOpenContainer"].element,
	parentSection = expandable,
}
addon.functions.SettingsCreateCheckbox(cContainer, data)

addon.functions.SettingsCreateText(cContainer, (L["containerActionsConfigCenterNote"] or L["containerActionsEditModeHint"]) .. "\n\n" .. "|cff99e599" .. L["containerActionsBlacklistHint"] .. "|r", { parentSection = expandable })

data = {
	listFunc = function()
		if not addon.ContainerActions then return end
		local entries = addon.ContainerActions:GetBlacklistEntries()
		local list = {}
		list[""] = ""
		local entryFormat = L["containerActionsBlacklistEntry"] or "%s - %d"
		for _, data in ipairs(entries) do
			local displayName = data.name or ("item:" .. data.itemID)
			local ok, line = pcall(string.format, entryFormat, displayName, data.itemID)
			if not ok then line = ("%s - %d"):format(displayName, data.itemID) end
			local key = tostring(data.itemID)
			list[key] = line
		end
		return list
	end,
	parentSection = expandable,
	text = L["Blacklisted Items"],
	parentCheck = function() return addon.SettingsLayout.elements["automaticallyOpenContainer"].setting and addon.SettingsLayout.elements["automaticallyOpenContainer"].setting:GetValue() == true end,
	element = addon.SettingsLayout.elements["automaticallyOpenContainer"].element,
	get = function() return "" end,
	set = function(value)
		if not addon.ContainerActions then return end
		local itemID = tonumber(value)
		if not itemID then return end

		local dialogKey = "EQOL_CONTAINER_BLACKLIST_REMOVE"
		local itemName = addon.ContainerActions:GetItemDisplayName(itemID)

		StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
			or {
				text = L["containerActionsBlacklistRemoveConfirm"],
				button1 = ACCEPT,
				button2 = CANCEL,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}

		StaticPopupDialogs[dialogKey].OnAccept = function()
			local ok, reason = addon.ContainerActions:RemoveItemFromBlacklist(itemID)
			if not ok then addon.ContainerActions:HandleBlacklistError(reason, itemID) end
		end

		StaticPopup_Show(dialogKey, itemName or ("item:" .. itemID), itemID)
	end,
	parent = true,
	default = "",
	var = "containerActionsBlacklistLabel",
}

addon.functions.SettingsCreateDropdown(cContainer, data)

local eventHandlers = {
	["BAG_UPDATE"] = function(bag)
		addon._bagsDirty = addon._bagsDirty or {}
		if type(bag) == "number" then addon._bagsDirty[bag] = true end
	end,
	["BAG_UPDATE_DELAYED"] = function()
		if addon.functions.clearTooltipCache then
			local now = GetTime()
			if not addon._ttCacheLastClear or (now - addon._ttCacheLastClear) > 0.25 then
				addon._ttCacheLastClear = now
				addon.functions.clearTooltipCache()
			end
		end

		if not addon.db["automaticallyOpenContainer"] then return end
		if isBankOpen() then
			stopContainerActions()
			return
		end
		if wOpen or addon._bagScanScheduled then return end

		addon._bagScanScheduled = true
		RunNextFrame(function()
			addon._bagScanScheduled = nil
			if wOpen or not addon.db["automaticallyOpenContainer"] then return end
			if isBankOpen() then
				stopContainerActions()
				return
			end

			wOpen = true

			local bags
			if addon._bagsDirty and next(addon._bagsDirty) then
				bags = {}
				for b in pairs(addon._bagsDirty) do
					if type(b) == "number" then table.insert(bags, b) end
				end
				addon._bagsDirty = nil
			end

			addon.functions.checkForContainer(bags)
		end)
	end,
}

function addon.functions.initContainerAction()
	local defaults = addon.ContainerActions and addon.ContainerActions.defaults or {}
	if addon.ContainerActions and addon.ContainerActions.MigrateProfileData then addon.ContainerActions:MigrateProfileData(addon.db) end
	addon.functions.InitDBValue("automaticallyOpenContainer", false)
	addon.functions.InitDBValue("containerActionAnchor", { point = "CENTER", relativePoint = "CENTER", x = 0, y = -200 })
	addon.functions.InitDBValue("containerAutoOpenDisabled", {})
	addon.functions.InitDBValue("containerActionAreaBlocks", {})
	addon.functions.InitDBValue("containerActionButtonSize", defaults.buttonSize or 48)
	addon.functions.InitDBValue("containerActionIconZoom", defaults.iconZoom or 8)
	addon.functions.InitDBValue("containerActionBorderEnabled", defaults.borderEnabled ~= false)
	addon.functions.InitDBValue("containerActionBorderTexture", defaults.borderTexture or "DEFAULT")
	addon.functions.InitDBValue("containerActionBorderSize", defaults.borderSize or 2)
	addon.functions.InitDBValue("containerActionBorderOffset", defaults.borderOffset or 0)
	addon.functions.InitDBValue("containerActionBorderColor", defaults.borderColor or { r = 1, g = 0.82, b = 0, a = 1 })
	addon.functions.InitDBValue("containerActionGlowEnabled", defaults.glowEnabled == true)
	addon.functions.InitDBValue("containerActionGlowStyle", defaults.glowStyle or "BLIZZARD")
	addon.functions.InitDBValue("containerActionGlowColor", defaults.glowColor or { r = 1, g = 0.82, b = 0.2, a = 1 })
	addon.functions.InitDBValue("containerActionGlowInset", defaults.glowInset or 0)
	addon.functions.InitDBValue("containerActionGlowThickness", defaults.glowThickness or 2)
	addon.functions.InitDBValue("containerActionIncludeCosmeticItems", false)

	if addon.ContainerActions and addon.ContainerActions.Init then
		addon.ContainerActions:Init()
		if addon.ContainerActions.OnSettingChanged then addon.ContainerActions:OnSettingChanged(addon.db["automaticallyOpenContainer"]) end
	end
end

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
