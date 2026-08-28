local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Vendor = addon.Vendor or {}
addon.Vendor.functions = addon.Vendor.functions or {}
addon.Vendor.variables = addon.Vendor.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local wipe = wipe
local listOrders = {
	vendorIncludeSellList = {},
	vendorExcludeSellList = {},
	vendorIncludeDestroyList = {},
}

local function applyParentSection(entries, section)
	for _, entry in ipairs(entries or {}) do
		entry.parentSection = section
		if entry.children then applyParentSection(entry.children, section) end
	end
end

local function isChecked(var)
	local entry = addon.SettingsLayout.elements and addon.SettingsLayout.elements[var]
	return entry and entry.setting and entry.setting:GetValue() == true
end

local function refreshSellMarks()
	if addon.Vendor and addon.Vendor.functions and addon.Vendor.functions.refreshSellMarks then addon.Vendor.functions.refreshSellMarks() end
end

local function refreshDestroyButton()
	if addon.Vendor and addon.Vendor.functions and addon.Vendor.functions.refreshDestroyButton then addon.Vendor.functions.refreshDestroyButton() end
end

local function syncBindFilters(quality, tabName)
	addon.Vendor.variables.itemBindTypeQualityFilter[quality] = addon.Vendor.variables.itemBindTypeQualityFilter[quality]
		or {
			[0] = true,
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = false,
			[5] = false,
			[6] = false,
			[7] = true,
			[8] = true,
			[9] = true,
		}
	local tbl = addon.Vendor.variables.itemBindTypeQualityFilter[quality]
	tbl[2] = not addon.db["vendor" .. tabName .. "IgnoreBoE"]
	local allowWarbound = not addon.db["vendor" .. tabName .. "IgnoreWarbound"]
	tbl[7] = allowWarbound
	tbl[8] = allowWarbound
	tbl[9] = allowWarbound
end

local function parseItemID(input)
	if type(input) == "number" then return input end
	if type(input) == "string" then
		local id = tonumber(input)
		if id then return id end
		local linkID = input:match("item:(%d+)")
		if linkID then return tonumber(linkID) end
	end
	return nil
end

local function buildList(listKey)
	local list = {}
	local order = listOrders[listKey]
	if order then
		wipe(order)
	else
		order = {}
	end
	for id, name in pairs(addon.db[listKey] or {}) do
		local key = tostring(id)
		list[key] = string.format("%s (%s)", name or key, key)
		table.insert(order, key)
	end
	table.sort(order, function(a, b) return list[a] < list[b] end)
	return list
end

local function listHasItems(listKey)
	return next(addon.db[listKey] or {}) ~= nil
end

local function buildRemoveList(listKey)
	local list = buildList(listKey)
	local order = listOrders[listKey]
	if not listHasItems(listKey) then
		list[""] = L["vendorNoItemsToRemove"]
		if order then table.insert(order, "") end
	end
	return list
end

local function addItemToList(listKey, id)
	if not id then return end
	addon.db[listKey] = addon.db[listKey] or {}
	local item = Item:CreateFromItemID(id)
	if not item or item:IsItemEmpty() then return end
	item:ContinueOnItemLoad(function()
		local resolvedID = item:GetItemID()
		local name = item:GetItemName() or ("Item #" .. tostring(resolvedID or id))
		addon.db[listKey][resolvedID] = name
		if listKey == "vendorIncludeSellList" and addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][resolvedID] = nil end
		if listKey == "vendorIncludeDestroyList" and addon.db["vendorIncludeSellList"] then addon.db["vendorIncludeSellList"][resolvedID] = nil end
		refreshSellMarks()
		refreshDestroyButton()
	end)
end

local function removeItemFromList(listKey, value)
	local id = tonumber(value)
	if not id then return end
	addon.db[listKey] = addon.db[listKey] or {}
	if addon.db[listKey][id] then
		addon.db[listKey][id] = nil
		refreshSellMarks()
		refreshDestroyButton()
	end
end

local function clearDropdownSelection(var)
	local entry = addon.SettingsLayout.elements and addon.SettingsLayout.elements[var]
	if entry and entry.setting then entry.setting:SetValue("") end
end

local function showAddPopup(dialogKey, prompt, listKey)
	StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
		or {
			text = prompt,
			button1 = OKAY,
			button2 = CANCEL,
			hasEditBox = true,
			maxLetters = 10,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				if editBox then
					editBox:SetText("")
					editBox:SetFocus()
				end
			end,
			OnAccept = function(self)
				local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
				local text = editBox and editBox:GetText()
				local id = parseItemID(text)
				if not id then return end
				addItemToList(listKey, id)
			end,
		}
	StaticPopupDialogs[dialogKey].text = prompt
	StaticPopup_Show(dialogKey)
end

local function showRemovePopup(dialogKey, prompt, listKey, label, id)
	StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
		or {
			text = prompt,
			button1 = ACCEPT,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	StaticPopupDialogs[dialogKey].text = prompt
	StaticPopupDialogs[dialogKey].OnAccept = function(_, data) removeItemFromList(listKey, data) end

	StaticPopup_Show(dialogKey, label, nil, id)
end

local function buildSettings()
	local cVendor = nil
	addon.SettingsLayout.vendorCategory = cVendor

	local merchantSection = addon.SettingsLayout.vendorEconomyMerchantSection
	if merchantSection then
		addon.functions.SettingsCreateCheckbox(cVendor, {
			var = "enableExtendedMerchant",
			text = L["enableExtendedMerchant"],
			desc = L["enableExtendedMerchantDesc"],
			parentSection = merchantSection,
			func = function(value)
				addon.db["enableExtendedMerchant"] = value and true or false
				if value and addon.Merchant and addon.Merchant.Enable then
					addon.Merchant:Enable()
				elseif not value and addon.Merchant and addon.Merchant.Disable then
					addon.Merchant:Disable()
					addon.variables.requireReload = true
					addon.functions.checkReloadFrame()
				end
			end,
		})
	end

	local auctionHouseSection = addon.SettingsLayout.vendorEconomyAuctionHouseSection
	if auctionHouseSection then
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

		addon.functions.SettingsCreateHeadline(cVendor, craftTitle, { parentSection = auctionHouseSection, order = 10 })
		local craftEnable = addon.functions.SettingsCreateCheckbox(cVendor, {
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
			order = 10,
			parentSection = auctionHouseSection,
		})

		local function craftShopperParentCheck() return craftEnable and craftEnable.setting and craftEnable.setting:GetValue() == true end

		addon.functions.SettingsCreateCheckbox(cVendor, {
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
			order = 20,
			parent = true,
			element = craftEnable.element,
			parentCheck = craftShopperParentCheck,
			parentSection = auctionHouseSection,
		})

		addon.functions.SettingsCreateDropdown(cVendor, {
			var = "vendorCraftShopperReagentQuality",
			text = craftQualityText,
			desc = craftQualityDesc,
			list = craftQualityList,
			order = 30,
			orderList = craftQualityOrder,
			default = "highest",
			get = function() return getCraftShopperQualityValue() end,
			set = function(key, maybeValue) setCraftShopperQualityValue(maybeValue or key) end,
			parent = true,
			element = craftEnable.element,
			parentCheck = craftShopperParentCheck,
			parentSection = auctionHouseSection,
		})
	end

	local quickActionsExpandable = addon.functions.SettingsCreateExpandableSection(cVendor, {
		name = L["vendorQuickActions"] or "Vendor - Quick Actions",
		configPageKey = "VendorQuickActions",
		modernCategory = "economy",
		modernOnly = true,
		iconKey = "vendor",
		expanded = false,
		colorizeTitle = false,
	})

	local generalCheckboxes = {
		{
			var = "sellAllJunk",
			text = L["sellAllJunk"] or "Automatically sell all junk items",
			desc = L["sellAllJunkDesc"] or "Sells all poor-quality items whenever a merchant window opens",
			func = function(value)
				addon.db["sellAllJunk"] = value and true or false
				if value and addon.Vendor.functions.CheckBagIgnoreJunk then addon.Vendor.functions.CheckBagIgnoreJunk() end
			end,
		},
		{
			var = "vendorAltClickInclude",
			text = L["vendorAltClickInclude"],
			desc = L["vendorAltClickIncludeDesc"],
			func = function(value)
				addon.db["vendorAltClickInclude"] = value and true or false
				if value and addon.Vendor.functions.refreshBaganatorWidgets then addon.Vendor.functions.refreshBaganatorWidgets() end
			end,
		},
		{
			var = "vendorShowSellTooltip",
			text = L["vendorShowSellTooltip"],
			func = function(value) addon.db["vendorShowSellTooltip"] = value and true or false end,
		},
		{
			var = "vendorShowSellOverlay",
			text = L["vendorShowSellOverlay"],
			func = function(value)
				addon.db["vendorShowSellOverlay"] = value and true or false
				refreshSellMarks()
			end,
			children = {
				{
					var = "vendorShowSellHighContrast",
					text = L["vendorShowSellHighContrast"],
					func = function(value)
						addon.db["vendorShowSellHighContrast"] = value and true or false
						refreshSellMarks()
					end,
					parentCheck = function() return isChecked("vendorShowSellOverlay") end,
					parent = true,
					type = Settings.VarType.Boolean,
					sType = "checkbox",
				},
			},
		},
	}
	applyParentSection(generalCheckboxes, quickActionsExpandable)
	addon.functions.SettingsCreateCheckboxes(cVendor, generalCheckboxes)

	local autoSellExpandable = addon.functions.SettingsCreateExpandableSection(cVendor, {
		name = L["vendorAutoSellRules"] or "Vendor - Auto-Sell Rules",
		newTagID = "AutoSellRules",
		modernCategory = "economy",
		modernOnly = true,
		iconKey = "autosell",
		expanded = false,
		colorizeTitle = false,
	})

	addon.functions.SettingsCreateSectionHeader(cVendor, L["Behavior"] or "Behavior", {
		parentSection = quickActionsExpandable,
		order = 10,
	})
	addon.functions.SettingsCreateCheckboxes(cVendor, {
		{
			var = "vendorSwapAutoSellShift",
			text = L["vendorSwapAutoSellShift"],
			func = function(value) addon.db["vendorSwapAutoSellShift"] = value and true or false end,
			parentSection = quickActionsExpandable,
		},
		{
			var = "vendorOnly12Items",
			text = L["vendorOnly12Items"],
			desc = L["vendorOnly12ItemsDesc"],
			func = function(value) addon.db["vendorOnly12Items"] = value and true or false end,
			parentSection = quickActionsExpandable,
		},
	})

	local qualities = {
		{ q = 0, key = "Poor" },
		{ q = 1, key = "Common" },
		{ q = 2, key = "Uncommon" },
		{ q = 3, key = "Rare" },
		{ q = 4, key = "Epic" },
	}

	local expansions = {}
	for i = 0, LE_EXPANSION_LEVEL_CURRENT do
		table.insert(expansions, { value = i, text = _G["EXPANSION_NAME" .. i] or tostring(i) })
	end

	for _, info in ipairs(qualities) do
		local quality = info.q
		local tabName = addon.Vendor.variables.tabNames[quality]
		local colorHex = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or ""
		local label = _G["ITEM_QUALITY" .. quality .. "_DESC"] or tabName
		addon.functions.SettingsCreateSectionHeader(cVendor, string.format("%s%s|r", colorHex, label), {
			parentSection = autoSellExpandable,
		})

		local enable = addon.functions.SettingsCreateCheckbox(cVendor, {
			var = "vendor" .. tabName .. "Enable",
			text = L["vendorEnable"]:format(colorHex .. label .. "|r"),
			func = function(value)
				addon.db["vendor" .. tabName .. "Enable"] = value and true or false
				addon.Vendor.variables.itemQualityFilter[quality] = addon.db["vendor" .. tabName .. "Enable"]
				if quality == 0 and addon.db["vendor" .. tabName .. "Enable"] then
					addon.db["sellAllJunk"] = false
					local sellAllJunkEntry = addon.SettingsLayout and addon.SettingsLayout.elements and addon.SettingsLayout.elements["sellAllJunk"]
					if sellAllJunkEntry and sellAllJunkEntry.setting then sellAllJunkEntry.setting:SetValue(false) end
				end
				refreshSellMarks()
			end,
			default = addon.db["vendor" .. tabName .. "Enable"],
			parentSection = autoSellExpandable,
		})

		local function parentCheck() return isChecked("vendor" .. tabName .. "Enable") end

		local qualityCheckboxes = {
			{
				var = "vendor" .. tabName .. "AbsolutIlvl",
				text = L["vendorAbsolutIlvl"],
				func = function(value)
					addon.db["vendor" .. tabName .. "AbsolutIlvl"] = value and true or false
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			},
			{
				var = "vendor" .. tabName .. "IgnoreBoE",
				text = L["vendorIgnoreBoE"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreBoE"] = value and true or false
					syncBindFilters(quality, tabName)
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			},
			{
				var = "vendor" .. tabName .. "IgnoreWarbound",
				text = L["vendorIgnoreWarbound"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreWarbound"] = value and true or false
					syncBindFilters(quality, tabName)
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			},
		}

		addon.functions.SettingsCreateSlider(cVendor, {
			var = "vendor" .. tabName .. "MinIlvlDif",
			text = addon.db["vendor" .. tabName .. "AbsolutIlvl"] and L["vendorMinIlvl"] or L["vendorMinIlvlDif"],
			get = function() return addon.db["vendor" .. tabName .. "MinIlvlDif"] or 200 end,
			set = function(value)
				value = math.floor(tonumber(value) or 0)
				addon.db["vendor" .. tabName .. "MinIlvlDif"] = value
				refreshSellMarks()
			end,
			min = 1,
			max = 700,
			step = 1,
			parent = true,
			element = enable.element,
			parentCheck = parentCheck,
			default = 200,
			parentSection = autoSellExpandable,
		})

		if quality > 1 then
			table.insert(qualityCheckboxes, {
				var = "vendor" .. tabName .. "IgnoreUpgradable",
				text = L["vendorIgnoreUpgradable"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreUpgradable"] = value and true or false
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			})
			table.insert(qualityCheckboxes, {
				var = "vendor" .. tabName .. "IgnoreEquipmentSets",
				text = L["vendorIgnoreEquipmentSets"],
				desc = L["vendorIgnoreEquipmentSetsDesc"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreEquipmentSets"] = value and true or false
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			})
		end

		if quality == 4 then
			table.insert(qualityCheckboxes, {
				var = "vendor" .. tabName .. "IgnoreHeroicTrack",
				text = L["vendorIgnoreHeroicTrack"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreHeroicTrack"] = value and true or false
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			})
			table.insert(qualityCheckboxes, {
				var = "vendor" .. tabName .. "IgnoreMythTrack",
				text = L["vendorIgnoreMythTrack"],
				func = function(value)
					addon.db["vendor" .. tabName .. "IgnoreMythTrack"] = value and true or false
					refreshSellMarks()
				end,
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
			})
		end

		applyParentSection(qualityCheckboxes, autoSellExpandable)
		addon.functions.SettingsCreateCheckboxes(cVendor, qualityCheckboxes)

		if quality > 0 then
			addon.functions.SettingsCreateMultiDropdown(cVendor, {
				var = "vendor" .. tabName .. "CraftingExpansions",
				text = L["vendorCraftingExpansions"],
				parent = true,
				element = enable.element,
				parentCheck = parentCheck,
				options = expansions,
				isSelectedFunc = function(value)
					local store = addon.db["vendor" .. tabName .. "CraftingExpansions"]
					return store and store[value] == true
				end,
				setSelectedFunc = function(value, selected)
					addon.db["vendor" .. tabName .. "CraftingExpansions"] = addon.db["vendor" .. tabName .. "CraftingExpansions"] or {}
					addon.db["vendor" .. tabName .. "CraftingExpansions"][value] = selected or nil
					refreshSellMarks()
				end,
				parentSection = autoSellExpandable,
			})
		end

		syncBindFilters(quality, tabName)
		addon.Vendor.variables.itemQualityFilter[quality] = addon.db["vendor" .. tabName .. "Enable"]
	end

	local includeExcludeExpandable = addon.functions.SettingsCreateExpandableSection(cVendor, {
		name = L["vendorIncludeExclude"] or "Vendor - Include / Exclude",
		configPageKey = "VendorIncludeExclude",
		modernCategory = "economy",
		modernOnly = true,
		iconKey = "includelists",
		expanded = false,
		colorizeTitle = false,
	})

	addon.functions.SettingsCreateSectionHeader(cVendor, L["Include"] or "Include", { parentSection = includeExcludeExpandable })
	addon.functions.SettingsCreateButton(cVendor, {
		var = "vendorIncludeAdd",
		text = L["vendorIncludeAdd"],
		desc = L["vendorIncludeAddDesc"],
		buttonText = ADD,
		func = function() showAddPopup("EQOL_VENDOR_INCLUDE_ADD", L["vendorAddItemToInclude"], "vendorIncludeSellList") end,
		parentSection = includeExcludeExpandable,
	})

	addon.functions.SettingsCreateScrollDropdown(cVendor, {
		var = "vendorIncludeRemove",
		text = L["vendorIncludeRemove"],
		desc = L["vendorIncludeRemoveDesc"],
		listFunc = function() return buildRemoveList("vendorIncludeSellList") end,
		order = listOrders.vendorIncludeSellList,
		default = "",
		get = function() return "" end,
		set = function(value)
			if not value or value == "" then return end
			local id = tonumber(value)
			if not id then return end
			addon.db.vendorIncludeSellList = addon.db.vendorIncludeSellList or {}
			local label = addon.db.vendorIncludeSellList[id] or tostring(id)
			showRemovePopup("EQOL_VENDOR_INCLUDE_REMOVE", L["vendorIncludeRemoveConfirm"], "vendorIncludeSellList", label, id)
			clearDropdownSelection("vendorIncludeRemove")
		end,
		isEnabled = function() return listHasItems("vendorIncludeSellList") end,
		parentSection = includeExcludeExpandable,
	})

	addon.functions.SettingsCreateSectionHeader(cVendor, L["Exclude"] or "Exclude", { parentSection = includeExcludeExpandable })
	addon.functions.SettingsCreateButton(cVendor, {
		var = "vendorExcludeAdd",
		text = L["vendorExcludeAdd"],
		desc = L["vendorExcludeAddDesc"],
		buttonText = ADD,
		func = function() showAddPopup("EQOL_VENDOR_EXCLUDE_ADD", L["vendorAddItemToExclude"], "vendorExcludeSellList") end,
		parentSection = includeExcludeExpandable,
	})

	addon.functions.SettingsCreateScrollDropdown(cVendor, {
		var = "vendorExcludeRemove",
		text = L["vendorExcludeRemove"],
		desc = L["vendorExcludeRemoveDesc"],
		listFunc = function() return buildRemoveList("vendorExcludeSellList") end,
		order = listOrders.vendorExcludeSellList,
		default = "",
		get = function() return "" end,
		set = function(value)
			if not value or value == "" then return end
			local id = tonumber(value)
			if not id then return end
			addon.db.vendorExcludeSellList = addon.db.vendorExcludeSellList or {}
			local label = addon.db.vendorExcludeSellList[id] or tostring(id)
			showRemovePopup("EQOL_VENDOR_EXCLUDE_REMOVE", L["vendorExcludeRemoveConfirm"], "vendorExcludeSellList", label, id)
			clearDropdownSelection("vendorExcludeRemove")
		end,
		isEnabled = function() return listHasItems("vendorExcludeSellList") end,
		parentSection = includeExcludeExpandable,
	})

	local destroyQueueExpandable = addon.functions.SettingsCreateExpandableSection(cVendor, {
		name = L["vendorDestroyQueue"] or "Vendor - Destroy Queue",
		configPageKey = "VendorDestroyQueue",
		modernCategory = "economy",
		modernOnly = true,
		iconKey = "includelists",
		expanded = false,
		colorizeTitle = false,
	})

	local destroySection = destroyQueueExpandable

	local destroyChildren = {
		{
			var = "vendorShowDestroyOverlay",
			text = L["vendorShowDestroyOverlay"],
			func = function(value)
				addon.db["vendorShowDestroyOverlay"] = value and true or false
				refreshSellMarks()
			end,
			parent = true,
			parentCheck = function() return isChecked("vendorDestroyEnable") end,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
		},
		{
			var = "vendorDestroyShowMessages",
			text = L["vendorDestroyShowMessages"],
			desc = L["vendorDestroyShowMessagesDesc"],
			func = function(value) addon.db["vendorDestroyShowMessages"] = value and true or false end,
			parent = true,
			parentCheck = function() return isChecked("vendorDestroyEnable") end,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
		},
		{
			sType = "hint",
			text = L["vendorDestroyManualHint"],
			parent = true,
			parentCheck = function() return isChecked("vendorDestroyEnable") end,
		},
		{
			var = "vendorDestroyAdd",
			text = L["vendorDestroyAdd"],
			desc = L["vendorDestroyAddDesc"],
			buttonText = ADD,
			sType = "button",
			parent = true,
			parentCheck = function() return isChecked("vendorDestroyEnable") end,
			isEnabled = function() return isChecked("vendorDestroyEnable") end,
			func = function()
				if not isChecked("vendorDestroyEnable") then return end
				showAddPopup("EQOL_VENDOR_DESTROY_ADD", L["vendorDestroyManualHint"], "vendorIncludeDestroyList")
			end,
		},
		{
			var = "vendorDestroyRemove",
			text = L["vendorDestroyRemove"],
			desc = L["vendorDestroyRemoveDesc"],
			sType = "scrolldropdown",
			parent = true,
			parentCheck = function() return isChecked("vendorDestroyEnable") end,
			listFunc = function() return buildRemoveList("vendorIncludeDestroyList") end,
			order = listOrders.vendorIncludeDestroyList,
			default = "",
			get = function() return "" end,
			set = function(value) removeItemFromList("vendorIncludeDestroyList", value) end,
			isEnabled = function() return isChecked("vendorDestroyEnable") and listHasItems("vendorIncludeDestroyList") end,
		},
	}
	local destroyEntries = {
		{
			var = "vendorDestroyEnable",
			text = L["vendorDestroyEnable"],
			desc = L["vendorDestroyEnableDesc"],
			func = function(value)
				addon.db["vendorDestroyEnable"] = value and true or false
				refreshSellMarks()
				refreshDestroyButton()
			end,
			default = false,
			children = destroyChildren,
		},
	}
	applyParentSection(destroyEntries, destroySection)
	addon.functions.SettingsCreateCheckboxes(cVendor, destroyEntries)
end

function addon.Vendor.functions.InitSettings()
	if addon.Vendor.variables.settingsBuilt then return end
	if not addon.db or not addon.functions or not addon.functions.SettingsCreateCategory then return end
	buildSettings()
	addon.Vendor.variables.settingsBuilt = true
end

if addon.Vendor.functions.InitDB then addon.Vendor.functions.InitDB() end
if addon.Vendor.functions.InitState then addon.Vendor.functions.InitState() end
if addon.Vendor.functions.InitSettings then addon.Vendor.functions.InitSettings() end
