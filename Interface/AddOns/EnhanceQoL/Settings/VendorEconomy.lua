local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local wipe = wipe
local moneyTrackerOrder = {}
local warbandRemoveOrder = {}
local warbandTargetOrder = {}
local autoRepairGuildBankContextOptions = {
	{ value = "world", text = L["World"] or WORLD or "World" },
	{ value = "party", text = PARTY or "Party" },
	{ value = "dungeon", text = DUNGEONS or "Dungeons" },
	{ value = "mythicPlus", text = PLAYER_DIFFICULTY_MYTHIC_PLUS or "Mythic+" },
	{ value = "raid", text = RAID or "Raid" },
	{ value = "pvp", text = PVP or "PvP" },
}
local autoRepairGuildBankContextKeys = {}
for _, option in ipairs(autoRepairGuildBankContextOptions) do
	autoRepairGuildBankContextKeys[option.value] = true
end

local function getPrivateDB() return addon.functions.GetPrivateDB and addon.functions.GetPrivateDB() or addon.privateDB or {} end

local function applyParentSection(entries, section)
	for _, entry in ipairs(entries or {}) do
		entry.parentSection = section
		if entry.children then applyParentSection(entry.children, section) end
	end
end

local function getClassColoredCharacterLabel(info)
	local name = (info and info.name) or UNKNOWNOBJECT or "?"
	local realm = (info and info.realm) or GetRealmName() or "?"
	local class = info and info.class
	local col = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or ""] or { r = 1, g = 1, b = 1 }
	return string.format("|cff%02x%02x%02x%s-%s|r", (col.r or 1) * 255, (col.g or 1) * 255, (col.b or 1) * 255, name, realm)
end

local function listTrackedCharacters()
	local privateDB = getPrivateDB()
	local tracker = privateDB["moneyTracker"] or {}
	local entries = {}
	local seen = {}
	local playerGuid = UnitGUID("player")
	local playerInfo

	local function addEntry(guid, info)
		if not guid or guid == "" or seen[guid] then return end
		seen[guid] = true
		local rawSort = string.format("%s-%s", (info and info.name) or "", (info and info.realm) or ""):lower()
		entries[#entries + 1] = {
			key = guid,
			label = getClassColoredCharacterLabel(info),
			sortKey = rawSort,
		}
	end

	if playerGuid then playerInfo = {
		name = UnitName("player"),
		realm = GetRealmName(),
		class = select(2, UnitClass("player")),
	} end

	local function resolveCharacterInfo(guid)
		if guid and playerGuid and guid == playerGuid and playerInfo then return playerInfo end
		return tracker[guid] or {
			name = UNKNOWNOBJECT or "?",
			realm = GetRealmName(),
		}
	end

	for guid, info in pairs(tracker) do
		if type(info) == "table" then addEntry(guid, info) end
	end

	local selectedGuid = privateDB["autoWarbandGoldTargetCharacter"]
	if selectedGuid and selectedGuid ~= "" and not seen[selectedGuid] then addEntry(selectedGuid, resolveCharacterInfo(selectedGuid)) end

	local ignoredCharacters = privateDB["autoWarbandGoldIgnoredCharacters"]
	if type(ignoredCharacters) == "table" then
		for guid, isIgnored in pairs(ignoredCharacters) do
			if isIgnored then addEntry(guid, resolveCharacterInfo(guid)) end
		end
	end

	if playerGuid and playerInfo and not seen[playerGuid] then addEntry(playerGuid, playerInfo) end

	table.sort(entries, function(a, b)
		if a.sortKey == b.sortKey then return a.key < b.key end
		return a.sortKey < b.sortKey
	end)

	return entries
end

local function getSelectedWarbandTargetCharacter()
	local privateDB = getPrivateDB()
	local selected = privateDB["autoWarbandGoldTargetCharacter"]
	if selected and selected ~= "" then return selected end

	local playerGuid = UnitGUID("player")
	if playerGuid then privateDB["autoWarbandGoldTargetCharacter"] = playerGuid end
	return playerGuid or ""
end

local function notifySettingsUpdate(var)
	if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate("EQOL_" .. var) end
end

local function clearSettingsSelection(var)
	local entry = addon.SettingsLayout and addon.SettingsLayout.elements and addon.SettingsLayout.elements[var]
	if entry and entry.setting and entry.setting.SetValue then entry.setting:SetValue("") end
end

local function removeWarbandGoldCharacter(guid)
	if not guid or guid == "" or guid == UnitGUID("player") then return end

	local privateDB = getPrivateDB()
	if type(privateDB["moneyTracker"]) == "table" then privateDB["moneyTracker"][guid] = nil end
	if type(privateDB["autoWarbandGoldIgnoredCharacters"]) == "table" then privateDB["autoWarbandGoldIgnoredCharacters"][guid] = nil end
	if type(privateDB["autoWarbandGoldPerCharacter"]) == "table" then privateDB["autoWarbandGoldPerCharacter"][guid] = nil end
	if privateDB["autoWarbandGoldTargetCharacter"] == guid then privateDB["autoWarbandGoldTargetCharacter"] = UnitGUID("player") or "" end

	notifySettingsUpdate("autoWarbandGoldRemoveCharacter")
	notifySettingsUpdate("autoWarbandGoldTargetCharacter")
	notifySettingsUpdate("autoWarbandGoldTargetGoldPerCharacter")
	notifySettingsUpdate("autoWarbandGoldIgnoredCharacters")
	clearSettingsSelection("autoWarbandGoldRemoveCharacter")
end

local function getAutoRepairGuildBankContexts()
	if type(addon.db["autoRepairGuildBankContexts"]) ~= "table" then
		addon.db["autoRepairGuildBankContexts"] = {
			world = true,
			party = true,
			dungeon = true,
			mythicPlus = true,
			raid = true,
			pvp = true,
		}
	end
	return addon.db["autoRepairGuildBankContexts"]
end

local function setAutoRepairGuildBankContexts(selection)
	local nextSelection = {}
	if type(selection) == "table" then
		for key, enabled in pairs(selection) do
			if autoRepairGuildBankContextKeys[key] and enabled == true then nextSelection[key] = true end
		end
	end
	addon.db["autoRepairGuildBankContexts"] = nextSelection
end

local function isAutoRepairEnabled()
	return addon.SettingsLayout.elements["autoRepair"]
		and addon.SettingsLayout.elements["autoRepair"].setting
		and addon.SettingsLayout.elements["autoRepair"].setting:GetValue() == true
end

local function isAutoRepairGuildBankEnabled()
	return isAutoRepairEnabled()
		and addon.SettingsLayout.elements["autoRepairGuildBank"]
		and addon.SettingsLayout.elements["autoRepairGuildBank"].setting
		and addon.SettingsLayout.elements["autoRepairGuildBank"].setting:GetValue() == true
end

local cVendorEconomy = nil
addon.SettingsLayout.vendorEconomyCategory = cVendorEconomy

local vendorsExpandable = addon.functions.SettingsCreateExpandableSection(cVendorEconomy, {
	name = L["VendorsServices"],
	configPageKey = "VendorsServices",
	modernCategory = "economy",
	modernOnly = true,
	iconKey = "vendorsservices",
	expanded = false,
	colorizeTitle = false,
})

local data = {
	{
		var = "autoRepair",
		text = L["autoRepair"],
		func = function(v) addon.db["autoRepair"] = v end,
		desc = L["autoRepairDesc"],
		children = {
			{

				var = "autoRepairGuildBank",
				text = L["autoRepairGuildBank"],
				func = function(v) addon.db["autoRepairGuildBank"] = v end,
				desc = L["autoRepairGuildBankDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["autoRepair"]
						and addon.SettingsLayout.elements["autoRepair"].setting
						and addon.SettingsLayout.elements["autoRepair"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				children = {
					{
						var = "autoRepairGuildBankContexts",
						text = L["autoRepairGuildBankContexts"],
						desc = L["autoRepairGuildBankContextsDesc"],
						options = autoRepairGuildBankContextOptions,
						getSelection = getAutoRepairGuildBankContexts,
						setSelection = setAutoRepairGuildBankContexts,
						customDefaultText = L["All"] or ALL or "All",
						sType = "multidropdown",
						parent = true,
						parentCheck = isAutoRepairGuildBankEnabled,
					},
				},
			},
		},
	},
}

applyParentSection(data, vendorsExpandable)
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cVendorEconomy, data)

local bankExpandable = addon.functions.SettingsCreateExpandableSection(cVendorEconomy, {
	name = BANK,
	newTagID = "Bank",
	modernCategory = "economy",
	modernOnly = true,
	iconKey = "bank",
	expanded = false,
	colorizeTitle = false,
})

data = {
	{
		var = "autoWarbandGold",
		text = L["autoWarbandGold"],
		get = function() return getPrivateDB()["autoWarbandGold"] == true end,
		func = function(v) getPrivateDB()["autoWarbandGold"] = v and true or false end,
		desc = L["autoWarbandGoldDesc"],
		children = {
			{
				var = "autoWarbandGoldTargetGold",
				text = L["autoWarbandGoldTargetDefaultGold"] or L["autoWarbandGoldTargetGold"],
				desc = L["autoWarbandGoldTargetDefaultGoldDesc"] or L["autoWarbandGoldTargetGoldDesc"],
				get = function() return getPrivateDB()["autoWarbandGoldTargetGold"] or 10000 end,
				set = function(value) getPrivateDB()["autoWarbandGoldTargetGold"] = value end,
				min = 0,
				max = 1000000,
				step = 1000,
				default = 10000,
				sType = "slider",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
			},
			{
				var = "autoWarbandGoldTargetCharacter",
				text = L["autoWarbandGoldTargetCharacter"] or CHARACTER,
				desc = L["autoWarbandGoldTargetCharacterDesc"],
				listFunc = function()
					local tList = {}
					wipe(warbandTargetOrder)

					for _, entry in ipairs(listTrackedCharacters()) do
						tList[entry.key] = entry.label
						table.insert(warbandTargetOrder, entry.key)
					end

					if #warbandTargetOrder == 0 then
						tList[""] = NONE
						table.insert(warbandTargetOrder, "")
					end
					return tList
				end,
				order = warbandTargetOrder,
				get = function() return getSelectedWarbandTargetCharacter() end,
				set = function(key, maybeKey)
					local resolved = maybeKey or key
					if not resolved or resolved == "" then resolved = UnitGUID("player") or "" end
					getPrivateDB()["autoWarbandGoldTargetCharacter"] = resolved

					local sliderEntry = addon.SettingsLayout and addon.SettingsLayout.elements and addon.SettingsLayout.elements["autoWarbandGoldTargetGoldPerCharacter"]
					local sliderVariable = sliderEntry and sliderEntry.setting and sliderEntry.setting.GetVariable and sliderEntry.setting:GetVariable()
					if sliderVariable and Settings and Settings.NotifyUpdate then Settings.NotifyUpdate(sliderVariable) end
				end,
				default = "",
				type = Settings.VarType.String,
				sType = "scrolldropdown",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
			},
			{
				var = "autoWarbandGoldTargetGoldPerCharacter",
				text = L["autoWarbandGoldTargetGoldPerCharacter"] or L["autoWarbandGoldTargetGold"],
				desc = L["autoWarbandGoldTargetGoldPerCharacterDesc"] or L["autoWarbandGoldTargetGoldDesc"],
				get = function()
					local guid = getSelectedWarbandTargetCharacter()
					local privateDB = getPrivateDB()
					if not guid or guid == "" then return privateDB["autoWarbandGoldTargetGold"] or 10000 end
					local perChar = privateDB["autoWarbandGoldPerCharacter"]
					local value = perChar and perChar[guid]
					if value == nil then return privateDB["autoWarbandGoldTargetGold"] or 10000 end
					return value
				end,
				set = function(value)
					local guid = getSelectedWarbandTargetCharacter()
					if not guid or guid == "" then return end
					local privateDB = getPrivateDB()
					privateDB["autoWarbandGoldPerCharacter"] = privateDB["autoWarbandGoldPerCharacter"] or {}
					privateDB["autoWarbandGoldPerCharacter"][guid] = value
				end,
				min = 0,
				max = 1000000,
				step = 1000,
				default = 10000,
				sType = "slider",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
			},
			{
				var = "autoWarbandGoldIgnoredCharacters",
				text = L["autoWarbandGoldIgnoredCharacters"] or "Ignored characters",
				desc = L["autoWarbandGoldIgnoredCharactersDesc"],
				optionfunc = function()
					local options = {}
					for _, entry in ipairs(listTrackedCharacters()) do
						options[#options + 1] = { value = entry.key, text = entry.label }
					end
					return options
				end,
				getSelection = function()
					local ignored = getPrivateDB()["autoWarbandGoldIgnoredCharacters"]
					if type(ignored) ~= "table" then return {} end
					return ignored
				end,
				setSelection = function(selection) getPrivateDB()["autoWarbandGoldIgnoredCharacters"] = type(selection) == "table" and selection or {} end,
				db = getPrivateDB(),
				customDefaultText = NONE,
				sType = "multidropdown",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
			},
			{
				var = "autoWarbandGoldRemoveCharacter",
				text = L["autoWarbandGoldRemoveCharacter"] or ((REMOVE or "Remove") .. " " .. (CHARACTER or "Character")),
				desc = L["autoWarbandGoldRemoveCharacterDesc"],
				listFunc = function()
					local tList = { [""] = "" }
					local playerGuid = UnitGUID("player")
					wipe(warbandRemoveOrder)
					table.insert(warbandRemoveOrder, "")

					for _, entry in ipairs(listTrackedCharacters()) do
						if entry.key ~= playerGuid then
							tList[entry.key] = entry.label
							table.insert(warbandRemoveOrder, entry.key)
						end
					end

					return tList
				end,
				order = warbandRemoveOrder,
				get = function() return "" end,
				set = function(key)
					if not key or key == "" or key == UnitGUID("player") then return end
					local privateDB = getPrivateDB()
					local contact = privateDB["moneyTracker"] and privateDB["moneyTracker"][key]
					local displayName = getClassColoredCharacterLabel(contact)

					local dialogKey = "EQOL_WARBAND_GOLD_CHARACTER_REMOVE"
					StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
						or {
							text = L["autoWarbandGoldRemoveCharacterConfirm"],
							button1 = ACCEPT,
							button2 = CANCEL,
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}

					StaticPopupDialogs[dialogKey].OnAccept = function(_, guid) removeWarbandGoldCharacter(guid) end

					StaticPopup_Show(dialogKey, displayName or key, nil, key)
					clearSettingsSelection("autoWarbandGoldRemoveCharacter")
				end,
				default = "",
				type = Settings.VarType.String,
				sType = "scrolldropdown",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
			},
			{
				var = "autoWarbandGoldWithdraw",
				text = L["autoWarbandGoldWithdraw"],
				get = function() return getPrivateDB()["autoWarbandGoldWithdraw"] == true end,
				func = function(v) getPrivateDB()["autoWarbandGoldWithdraw"] = v and true or false end,
				desc = L["autoWarbandGoldWithdrawDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["autoWarbandGold"]
						and addon.SettingsLayout.elements["autoWarbandGold"].setting
						and addon.SettingsLayout.elements["autoWarbandGold"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
		},
	},
}

applyParentSection(data, bankExpandable)
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cVendorEconomy, data)

local merchantExpandable = addon.functions.SettingsCreateExpandableSection(cVendorEconomy, {
	name = L["MerchantUI"],
	configPageKey = "Merchant",
	modernCategory = "economy",
	modernOnly = true,
	iconKey = "vendor",
	expanded = false,
	colorizeTitle = false,
})

data = {
	{
		var = "enableExtendedMerchant",
		text = L["enableExtendedMerchant"],
		func = function(v)
			addon.db["enableExtendedMerchant"] = v
			if addon.Merchant then
				if v and addon.Merchant.Enable then
					addon.Merchant:Enable()
				elseif not v and addon.Merchant.Disable then
					addon.Merchant:Disable()
					addon.variables.requireReload = true
					addon.functions.checkReloadFrame()
				end
			end
		end,
		desc = L["enableExtendedMerchantDesc"],
	},
	{
		var = "markKnownOnMerchant",
		text = L["markKnownOnMerchant"],
		func = function(v)
			addon.db["markKnownOnMerchant"] = v
			if MerchantFrame and MerchantFrame:IsShown() then
				if MerchantFrame.selectedTab == 2 then
					if MerchantFrame_UpdateBuybackInfo then MerchantFrame_UpdateBuybackInfo() end
				else
					if MerchantFrame_UpdateMerchantInfo then MerchantFrame_UpdateMerchantInfo() end
				end
			end
		end,
		desc = L["markKnownOnMerchantDesc"],
	},
	{
		var = "markCollectedPetsOnMerchant",
		text = L["markCollectedPetsOnMerchant"],
		func = function(v)
			addon.db["markCollectedPetsOnMerchant"] = v
			if MerchantFrame and MerchantFrame:IsShown() then
				if MerchantFrame.selectedTab == 2 then
					if MerchantFrame_UpdateBuybackInfo then MerchantFrame_UpdateBuybackInfo() end
				else
					if MerchantFrame_UpdateMerchantInfo then MerchantFrame_UpdateMerchantInfo() end
				end
			end
		end,
		desc = L["markCollectedPetsOnMerchantDesc"],
	},
}

applyParentSection(data, merchantExpandable)
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cVendorEconomy, data)

local auctionHouseExpandable = addon.functions.SettingsCreateExpandableSection(cVendorEconomy, {
	name = BUTTON_LAG_AUCTIONHOUSE,
	configPageKey = "AuctionHouse",
	modernCategory = "economy",
	modernOnly = true,
	iconKey = "auction",
	expanded = false,
	colorizeTitle = false,
})

data = {
	{
		text = L["persistAuctionHouseFilter"],
		var = "persistAuctionHouseFilter",
		-- TODO 12.1 cleanup: remove this setting after confirming Blizzard native Auction House filter persistence.
		func = function(value) addon.db["persistAuctionHouseFilter"] = value end,
	},
	{
		text = L["closeBagsOnAuctionHouse"],
		desc = L["closeBagsOnAuctionHouseDesc"],
		var = "closeBagsOnAuctionHouse",
		func = function(value) addon.db["closeBagsOnAuctionHouse"] = value end,
	},
	{
		text = (function()
			local label = _G["AUCTION_HOUSE_FILTER_CURRENTEXPANSION_ONLY"]
			return L["alwaysUserCurExpAuctionHouse"]:format(label)
		end)(),
		var = "alwaysUserCurExpAuctionHouse",
		func = function(value) addon.db["alwaysUserCurExpAuctionHouse"] = value end,
	},
}

applyParentSection(data, auctionHouseExpandable)
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cVendorEconomy, data)

local craftTitle = L["vendorCraftShopperTitle"] or "Craft Shopper"
local craftEnableText = L["vendorCraftShopperEnable"] or "Enable Craft Shopper"
local craftEnableDesc = L["vendorCraftShopperEnableDesc"]
local craftWarbandText = L["vendorCraftShopperIncludeWarbandBank"] or "Include Warband Bank"
local craftWarbandDesc = L["vendorCraftShopperIncludeWarbandBankDesc"]
local craftQualityText = L["vendorCraftShopperReagentQuality"] or (_G["PROFESSIONS_QUALITY_DIALOG_TITLE"] or "Reagent Quality")
local craftQualityDesc = L["vendorCraftShopperReagentQualityDesc"]
local craftQualityList = {
	lowest = L["vendorCraftShopperReagentQualityLowest"] or "Lowest quality",
	highest = L["vendorCraftShopperReagentQualityHighest"] or "Highest quality",
}
local craftQualityOrder = { "lowest", "highest" }

local function getCraftShopperQualityValue()
	if addon.db["vendorCraftShopperReagentQuality"] == "lowest" then return "lowest" end
	return "highest"
end

local function setCraftShopperQualityValue(value)
	local quality = value == "lowest" and "lowest" or "highest"
	if addon.Vendor and addon.Vendor.CraftShopper and addon.Vendor.CraftShopper.SetReagentQualityMode then
		addon.Vendor.CraftShopper.SetReagentQualityMode(quality)
	else
		addon.db["vendorCraftShopperReagentQuality"] = quality
	end
end

addon.functions.SettingsCreateHeadline(cVendorEconomy, craftTitle, { parentSection = auctionHouseExpandable })
local craftEnable = addon.functions.SettingsCreateCheckbox(cVendorEconomy, {
	var = "vendorCraftShopperEnable",
	text = craftEnableText,
	desc = craftEnableDesc,
	func = function(value)
		addon.db["vendorCraftShopperEnable"] = value and true or false
		if addon.Vendor and addon.Vendor.CraftShopper then
			if value and addon.Vendor.CraftShopper.EnableCraftShopper then
				addon.Vendor.CraftShopper.EnableCraftShopper()
			elseif not value and addon.Vendor.CraftShopper.DisableCraftShopper then
				addon.Vendor.CraftShopper.DisableCraftShopper()
			end
		end
	end,
	default = false,
	parentSection = auctionHouseExpandable,
})

local function craftShopperParentCheck() return craftEnable and craftEnable.setting and craftEnable.setting:GetValue() == true end

addon.functions.SettingsCreateCheckbox(cVendorEconomy, {
	var = "vendorCraftShopperIncludeWarbandBank",
	text = craftWarbandText,
	desc = craftWarbandDesc,
	func = function(value)
		if addon.Vendor and addon.Vendor.CraftShopper and addon.Vendor.CraftShopper.SetIncludeWarbandBank then
			addon.Vendor.CraftShopper.SetIncludeWarbandBank(value)
		else
			addon.db["vendorCraftShopperIncludeWarbandBank"] = value and true or false
		end
	end,
	default = false,
	parent = true,
	element = craftEnable.element,
	parentCheck = craftShopperParentCheck,
	parentSection = auctionHouseExpandable,
})

addon.functions.SettingsCreateDropdown(cVendorEconomy, {
	var = "vendorCraftShopperReagentQuality",
	text = craftQualityText,
	desc = craftQualityDesc,
	list = craftQualityList,
	order = craftQualityOrder,
	default = "highest",
	get = function() return getCraftShopperQualityValue() end,
	set = function(key, maybeValue) setCraftShopperQualityValue(maybeValue or key) end,
	parent = true,
	element = craftEnable.element,
	parentCheck = craftShopperParentCheck,
	parentSection = auctionHouseExpandable,
})

local craftingOrdersExpandable = addon.functions.SettingsCreateExpandableSection(cVendorEconomy, {
	name = _G["PLACE_CRAFTING_ORDERS"] or "Crafting Orders",
	newTagID = "EconomyCraftingOrders",
	modernCategory = "economy",
	modernOnly = true,
	iconKey = "crafting",
	expanded = false,
	colorizeTitle = false,
})

data = {
	{
		text = (function()
			local label = _G["AUCTION_HOUSE_FILTER_CURRENTEXPANSION_ONLY"] or "Current expansion"
			return L["alwaysUserCurExpCraftingOrders"]:format(label)
		end)(),
		var = "alwaysUserCurExpCraftingOrders",
		func = function(value) addon.db["alwaysUserCurExpCraftingOrders"] = value end,
	},
}

applyParentSection(data, craftingOrdersExpandable)
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cVendorEconomy, data)

function addon.functions.settingsAddGold()
	local goldExpandable = addon.functions.SettingsCreateExpandableSection(addon.SettingsLayout.rootGENERAL, {
		name = L["GoldTracking"],
		configPageKey = "GoldTracking",
		modernCategory = "economy",
		iconKey = "goldtracking",
		modernOnly = true,
		expanded = false,
		colorizeTitle = false,
	})
	-- ! Still bugging as of 2026-01-21 - need to disable it

	-- data = {
	-- 	{
	-- 		var = "enableMoneyTracker",
	-- 		text = L["enableMoneyTracker"],
	-- 		func = function(v) addon.db["enableMoneyTracker"] = v end,
	-- 		desc = L["enableMoneyTrackerDesc"],
	-- 		children = {
	-- 			{

	-- 				var = "showOnlyGoldOnMoney",
	-- 				text = L["showOnlyGoldOnMoney"],
	-- 				func = function(v) addon.db["showOnlyGoldOnMoney"] = v end,
	-- 				parentCheck = function()
	-- 					return addon.SettingsLayout.elements["enableMoneyTracker"]
	-- 						and addon.SettingsLayout.elements["enableMoneyTracker"].setting
	-- 						and addon.SettingsLayout.elements["enableMoneyTracker"].setting:GetValue() == true
	-- 				end,
	-- 				parent = true,
	-- 				default = false,
	-- 				type = Settings.VarType.Boolean,
	-- 				sType = "checkbox",
	-- 			},
	-- 		},
	-- 	},
	-- }

	-- applyParentSection(data, goldExpandable)
	-- table.sort(data, function(a, b) return a.text < b.text end)
	-- addon.functions.SettingsCreateCheckboxes(addon.SettingsLayout.rootGENERAL, data)

	addon.functions.SettingsCreateScrollDropdown(addon.SettingsLayout.rootGENERAL, {
		parentSection = goldExpandable,
		listFunc = function()
			local tracker = getPrivateDB()["moneyTracker"] or {}
			local entries = {}
			local tList = { [""] = "" }
			wipe(moneyTrackerOrder)
			table.insert(moneyTrackerOrder, "")

			for guid, v in pairs(tracker) do
				if guid ~= UnitGUID("player") then
					local col = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[v.class] or { r = 1, g = 1, b = 1 }
					local displayName = string.format("|cff%02x%02x%02x%s-%s|r", (col.r or 1) * 255, (col.g or 1) * 255, (col.b or 1) * 255, v.name or "?", v.realm or "?")
					local rawSort = string.format("%s-%s", v.name or "", v.realm or ""):lower()
					entries[#entries + 1] = { key = guid, label = displayName, sortKey = rawSort }
				end
			end

			table.sort(entries, function(a, b)
				if a.sortKey == b.sortKey then return a.key < b.key end
				return a.sortKey < b.sortKey
			end)

			for _, entry in ipairs(entries) do
				tList[entry.key] = entry.label
				table.insert(moneyTrackerOrder, entry.key)
			end
			return tList
		end,
		order = moneyTrackerOrder,
		text = L["mailboxRemoveHeader"],
		get = function() return "" end,
		set = function(key)
			if not key or key == "" then return end
			local privateDB = getPrivateDB()
			if not privateDB["moneyTracker"] or not privateDB["moneyTracker"][key] then return end

			local contact = privateDB["moneyTracker"][key]
			local classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[contact.class or ""] or { r = 1, g = 1, b = 1 }
			local displayName = string.format("|cff%02x%02x%02x%s-%s|r", (classColor.r or 1) * 255, (classColor.g or 1) * 255, (classColor.b or 1) * 255, contact.name or "?", contact.realm or "?")

			local dialogKey = "EQOL_MONEY_TRACKER_REMOVE"
			StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
				or {
					text = L["moneyTrackerRemoveConfirm"],
					button1 = ACCEPT,
					button2 = CANCEL,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}

			StaticPopupDialogs[dialogKey].OnAccept = function(_, guid)
				local confirmDB = getPrivateDB()
				if not guid or not confirmDB["moneyTracker"] then return end
				confirmDB["moneyTracker"][guid] = nil
			end

			StaticPopup_Show(dialogKey, displayName or key, nil, key)
		end,
		default = "",
		var = "moneyTracker",
		type = Settings.VarType.String,
	})
end
addon.functions.settingsAddGold()
----- REGION END

function addon.functions.initVendorEconomy() end

local eventHandlers = {}

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
