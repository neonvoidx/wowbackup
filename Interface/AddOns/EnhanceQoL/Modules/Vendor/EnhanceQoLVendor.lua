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
local MainL = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local sellMoreButton
local hasMoreItems = false
local sellMarkLookup = {}
local destroyMarkLookup = {}
local updateSellMarks
local updateDestroyUI
local updateDestroyButtonState
local ensureDestroyButton
local ensureBaganatorIntegration
local applySellDestroyOverlayToItemButton
local applySellDestroyOverlaysToBaganatorButtons
local AltClickHook
local getTooltipInfo
local frameLoad
local tooltipCache = {}
local slotAnalysisCache = {}
local slotAnalysisScratch = {}
local slotAnalysisCacheVersion = 0
local destroyState = {
	queue = {},
	rows = {},
	pendingUpdate = false,
	pendingQueue = nil,
	hideTimer = nil,
}
local baganatorRegionRegistered = false
local baganatorSkinsListenerRegistered = false
local baganatorCallbacksRegistered = false
local baganatorTrackedItemButtons = setmetatable({}, { __mode = "k" })
local baganatorVisibleItemButtons = setmetatable({}, { __mode = "k" })
local baganatorVisibleBackpackButtonCount = 0
local BAGANATOR_REGION_LABEL = "Enhance QoL"
local BAGANATOR_REGION_ID = "enhanceqol_vendor_destroy_queue"
local BAGANATOR_CORNER_WIDGET_LABEL = "EnhanceQoL Sell/Destroy"
local BAGANATOR_CORNER_WIDGET_ID = "enhanceqol_vendor_mark"
local BAGANATOR_UPGRADE_WIDGET_LABEL = "Enhance QoL " .. (MainL["showUpgradeArrowOnBagItems"] or "Upgrade arrow")
local BAGANATOR_UPGRADE_WIDGET_ID = "enhanceqol_upgrade_arrow"
local ICON_TEXTURE_SELL = "Interface\\buttons\\ui-grouploot-coin-up"
local ICON_TEXTURE_DESTROY = "Interface\\Buttons\\UI-GroupLoot-DE-Up"
local ICON_TEXTURE_UPGRADE = "Interface\\AddOns\\EnhanceQoL\\Icons\\upgradeilvl.tga"
local baganatorCornerWidgetRegistered = false
local baganatorUpgradeCornerWidgetRegistered = false
local pendingBaganatorWidgetRefresh = false
local pendingBaganatorLayoutUpdate = false
local pendingBaganatorOverlaySweep = false
local baganatorDestroyRegionLastShown = nil
local baganatorDestroyRegionLastWidth = nil
local baganatorInitialFrameScanCompleted = false
local baganatorCornerWidgetActiveCache = {}
local baganatorOverlayContext = { useCornerIcons = false }
local vendorMarksRevision = 0
local lastBaganatorSellDestroyWidgetRefreshRevision = -1

local function ensureDestroyListFrame()
	if destroyState.list and destroyState.list:IsObjectType("Frame") then return destroyState.list end
	if InCombatLockdown and InCombatLockdown() then return nil end
	local button = destroyState.button
	if not button then return nil end

	local frame = CreateFrame("Frame", addonName .. "_DestroyList", button, "BackdropTemplate")
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel((destroyState.button and destroyState.button:GetFrameLevel() or 5) + 10)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0, 0, 0, 0.85)
	frame:SetBackdropBorderColor(0.9, 0.2, 0.2, 1)
	frame:SetSize(220, 40)
	frame:EnableMouse(true)
	frame:SetScript("OnLeave", function()
		C_Timer.After(0.05, function()
			if destroyState.button and destroyState.button:IsMouseOver() then return end
			if frame:IsMouseOver() then return end
			frame:Hide()
		end)
	end)
	destroyState.list = frame
	destroyState.rows = {}

	local emptyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	emptyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	emptyLabel:SetWidth(200)
	emptyLabel:SetJustifyH("LEFT")
	emptyLabel:SetText(L["vendorDestroyListEmpty"])
	frame.emptyLabel = emptyLabel

	return frame
end

local destroyProtected = {
	[169223] = true, -- Legion artifact weapon
	[200710] = true, -- Legion artifact weapon
}

local pendingSellMarksUpdate = false
local pendingSellMarksReset = false
local sellMarksDirty = true
local vendorMarksActive = false
local autoSellInProgress = false
local autoSellNeedsRefresh = false
local pendingDestroyButtonUpdate = false

local function scheduleDestroyButtonUpdate()
	if pendingDestroyButtonUpdate then return end
	pendingDestroyButtonUpdate = true
	C_Timer.After(0.1, function()
		pendingDestroyButtonUpdate = false
		updateDestroyButtonState()
	end)
end

local function getBagSlotFromItemButton(itemButton)
	if not itemButton then return nil, nil end
	local bag
	if itemButton.GetBagID then bag = itemButton:GetBagID() end
	if bag == nil and itemButton.GetParent then
		local parent = itemButton:GetParent()
		if parent and parent.GetID then bag = parent:GetID() end
	end
	local slot
	if itemButton.GetID then slot = itemButton:GetID() end
	if (bag == nil or slot == nil) and itemButton.BGR and itemButton.BGR.itemLocation then
		local loc = itemButton.BGR.itemLocation
		if bag == nil then bag = loc.bagID end
		if slot == nil then slot = loc.slotIndex end
	end
	return bag, slot
end

local function itemButtonMatchesSearch(itemButton)
	local matches = itemButton and itemButton.matchesSearch
	if matches == nil and itemButton and itemButton.BGR then matches = itemButton.BGR.matchesSearch end
	if matches == nil and itemButton and itemButton.searchOverlay and itemButton.searchOverlay.IsShown then matches = not itemButton.searchOverlay:IsShown() end
	if matches == nil then matches = true end
	return matches
end

local function hideSellDestroyOverlays(itemButton)
	if not itemButton then return end
	itemButton._enhanceQoLVendorOverlayKind = nil
	if itemButton.ItemMarkSell then itemButton.ItemMarkSell:Hide() end
	if itemButton.SellOverlay then itemButton.SellOverlay:Hide() end
	if itemButton.ItemMarkDestroy then itemButton.ItemMarkDestroy:Hide() end
	if itemButton.DestroyOverlay then itemButton.DestroyOverlay:Hide() end
end

local function applyItemButtonShapeMask(texture, itemButton)
	if not texture or not texture.AddMaskTexture then
		return
	end

	local mask = itemButton and itemButton.BagsShapeIconMask
	local previousMask = texture._enhanceQoLVendorShapeMask
	if previousMask == mask then
		return
	end

	if previousMask and texture.RemoveMaskTexture then
		texture:RemoveMaskTexture(previousMask)
	end

	if mask then
		texture:AddMaskTexture(mask)
	end

	texture._enhanceQoLVendorShapeMask = mask
end

local function itemButtonHasDefaultJunkMark(itemButton, bag, slot)
	if itemButton and itemButton.JunkIcon and itemButton.JunkIcon.IsShown and itemButton.JunkIcon:IsShown() then
		return true
	end

	local quality = itemButton and (itemButton._bagsRenderQuality or itemButton._bagsWarbandRenderQuality)
	if quality == nil and C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bag, slot)
		quality = info and info.quality
	end

	return quality == 0
end

local function isBaganatorBackpackItemButton(itemButton)
	local bag = getBagSlotFromItemButton(itemButton)
	return type(bag) == "number" and bag >= 0 and bag <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
end

local function isBaganatorBackpackShown()
	local api = _G.Baganator and _G.Baganator.API
	local skin = api and api.Skins and api.Skins.GetCurrentSkin and api.Skins.GetCurrentSkin()
	if not skin then return false end
	local singleView = _G["Baganator_SingleViewBackpackViewFrame" .. skin]
	if singleView and singleView.IsShown and singleView:IsShown() then return true end
	local categoryView = _G["Baganator_CategoryViewBackpackViewFrame" .. skin]
	return categoryView and categoryView.IsShown and categoryView:IsShown() or false
end

local function refreshBaganatorVisibleButtonState(itemButton)
	local shouldCount = itemButton and itemButton.IsShown and itemButton:IsShown() and isBaganatorBackpackItemButton(itemButton)
	local counted = baganatorVisibleItemButtons[itemButton] == true
	if shouldCount and not counted then
		baganatorVisibleItemButtons[itemButton] = true
		baganatorVisibleBackpackButtonCount = baganatorVisibleBackpackButtonCount + 1
	elseif counted and not shouldCount then
		baganatorVisibleItemButtons[itemButton] = nil
		baganatorVisibleBackpackButtonCount = math.max(0, baganatorVisibleBackpackButtonCount - 1)
	end
end

local function requestBaganatorLayoutUpdate()
	local api = _G.Baganator and _G.Baganator.API
	if not (api and api.RequestLayoutUpdate) then return end
	if pendingBaganatorLayoutUpdate then return end
	pendingBaganatorLayoutUpdate = true
	RunNextFrame(function()
		pendingBaganatorLayoutUpdate = false
		api.RequestLayoutUpdate()
	end)
end

local function requestBaganatorLayoutUpdateForDestroyRegion(force)
	if not baganatorRegionRegistered then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local button = destroyState.button
	if not button then return end

	local shown = button.IsShown and button:IsShown() == true or false
	local width = 0
	if shown and button.GetWidth then width = button:GetWidth() or 0 end

	if force or shown ~= baganatorDestroyRegionLastShown or width ~= baganatorDestroyRegionLastWidth then
		baganatorDestroyRegionLastShown = shown
		baganatorDestroyRegionLastWidth = width
		requestBaganatorLayoutUpdate()
	end
end

local function invalidateBaganatorCornerWidgetActiveCache()
	if wipe then
		wipe(baganatorCornerWidgetActiveCache)
	else
		for key in pairs(baganatorCornerWidgetActiveCache) do
			baganatorCornerWidgetActiveCache[key] = nil
		end
	end
end

local function isBaganatorCornerWidgetActiveCached(widgetID)
	local cached = baganatorCornerWidgetActiveCache[widgetID]
	if cached ~= nil then return cached end
	local api = _G.Baganator and _G.Baganator.API
	local active = api and api.IsCornerWidgetActive and api.IsCornerWidgetActive(widgetID) == true or false
	baganatorCornerWidgetActiveCache[widgetID] = active
	return active
end

local function isBaganatorCornerWidgetActive()
	return isBaganatorCornerWidgetActiveCached(BAGANATOR_CORNER_WIDGET_ID)
end

local function getBaganatorOverlayContext()
	baganatorOverlayContext.useCornerIcons = isBaganatorCornerWidgetActiveCached(BAGANATOR_CORNER_WIDGET_ID)
	return baganatorOverlayContext
end

local function shouldUseBaganatorSellDestroyIntegration()
	if not addon.db then return false end
	return addon.db["vendorShowSellOverlay"]
		or addon.db["vendorAltClickInclude"]
		or (addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"])
end

local function shouldUseBaganatorDestroyRegion()
	return addon.db and addon.db["vendorDestroyEnable"] == true
end

local function shouldUseBaganatorUpgradeIntegration()
	return addon.db and addon.db["showUpgradeArrowOnBagItems"] == true
end

local function shouldUseBaganatorIntegration()
	return shouldUseBaganatorSellDestroyIntegration() or shouldUseBaganatorDestroyRegion() or shouldUseBaganatorUpgradeIntegration()
end

local function shouldUseVendorMarkUpdates()
	if not addon.db then return false end
	return addon.db["vendorShowSellOverlay"]
		or addon.db["vendorShowSellTooltip"]
		or addon.db["vendorDestroyEnable"]
end

local function requestBaganatorItemWidgetRefresh()
	local api = _G.Baganator and _G.Baganator.API
	local constants = _G.Baganator and _G.Baganator.Constants
	if not (api and api.RequestItemButtonsRefresh and constants and constants.RefreshReason and constants.RefreshReason.ItemWidgets) then return end
	if pendingBaganatorWidgetRefresh then return end
	pendingBaganatorWidgetRefresh = true
	RunNextFrame(function()
		pendingBaganatorWidgetRefresh = false
		api.RequestItemButtonsRefresh({ constants.RefreshReason.ItemWidgets })
	end)
end

local function bumpVendorMarksRevision()
	vendorMarksRevision = vendorMarksRevision + 1
end

local function requestBaganatorSellDestroyWidgetRefreshIfNeeded()
	if not baganatorCornerWidgetRegistered then return end
	if not isBaganatorCornerWidgetActiveCached(BAGANATOR_CORNER_WIDGET_ID) then return end
	if lastBaganatorSellDestroyWidgetRefreshRevision == vendorMarksRevision then return end
	lastBaganatorSellDestroyWidgetRefreshRevision = vendorMarksRevision
	requestBaganatorItemWidgetRefresh()
end

local function requestBaganatorOverlaySweep()
	if pendingBaganatorOverlaySweep then return end
	pendingBaganatorOverlaySweep = true
	RunNextFrame(function()
		pendingBaganatorOverlaySweep = false
		applySellDestroyOverlaysToBaganatorButtons()
	end)
end

local function shouldShowBaganatorUpgradeCornerWidget(itemLocation)
	if not (addon.db and addon.db["showUpgradeArrowOnBagItems"]) then return false end
	if not (itemLocation and itemLocation.bagID ~= nil and itemLocation.slotIndex ~= nil and C_Item.DoesItemExist(itemLocation)) then return false end

	local bag, slot = itemLocation.bagID, itemLocation.slotIndex
	if bag < 0 or bag > NUM_TOTAL_EQUIPPED_BAG_SLOTS then return false end

	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if not itemLink then return false end

	local _, _, _, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemLink)
	if not addon.functions.IsItemRecommendedForSpec or not addon.functions.IsItemRecommendedForSpec(itemLink, itemEquipLoc, classID, subclassID) then return false end
	if not addon.functions.IsBagItemUpgrade then return false end

	local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
	local itemLevel = location and C_Item.GetCurrentItemLevel(location)
	if not itemLevel or itemLevel <= 0 then itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) end
	return addon.functions.IsBagItemUpgrade(itemLink, itemEquipLoc, itemLevel) == true
end

function addon.Vendor.functions.refreshBaganatorWidgets()
	if not shouldUseBaganatorIntegration() then return end
	ensureBaganatorIntegration()
	requestBaganatorItemWidgetRefresh()
end

local function getDestroyProtectionReason(itemID, bagInfo, quality)
	if destroyProtected[itemID] then return L["vendorDestroyProtected"] end
	local q = quality
	if not q and bagInfo then q = bagInfo.quality end
	if not q and itemID then
		local _, _, itemQuality = C_Item.GetItemInfo(itemID)
		if not itemQuality then C_Item.RequestLoadItemDataByID(itemID) end
		q = itemQuality
	end
	if q == Enum.ItemQuality.Artifact or q == Enum.ItemQuality.WoWToken then return L["vendorDestroyProtectedQuality"] end
	return nil
end

local function notifyDestroyProtection(itemID, descriptor, reason)
	if addon.db and addon.db["vendorDestroyShowMessages"] == false then return end
	local label = descriptor or ("Item #" .. tostring(itemID or "?"))
	print(string.format("%s: %s", label, reason or L["vendorDestroyProtected"]))
end

local function inventoryOpen()
	if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then return true end
	local frames = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}
	for _, frame in ipairs(frames) do
		if frame and frame:IsShown() then return true end
	end
	if addon.Bags and addon.Bags.functions and addon.Bags.functions.IsInventoryOpenForVendor and addon.Bags.functions.IsInventoryOpenForVendor() then return true end
	if isBaganatorBackpackShown() then return true end
	if baganatorVisibleBackpackButtonCount > 0 then
		for itemButton in pairs(baganatorVisibleItemButtons) do
			if itemButton and itemButton.IsShown and itemButton:IsShown() and isBaganatorBackpackItemButton(itemButton) then return true end
		end
		baganatorVisibleBackpackButtonCount = 0
	end
	return false
end

local function wipeMap(target)
	if type(target) ~= "table" then return end
	if wipe then
		wipe(target)
		return
	end
	for key in pairs(target) do
		target[key] = nil
	end
end

local function invalidateVendorScanCaches(clearTooltip)
	slotAnalysisCacheVersion = slotAnalysisCacheVersion + 1
	wipeMap(slotAnalysisCache)
	if clearTooltip ~= false then wipeMap(tooltipCache) end
end

local function beginSlotAnalysisPass()
	wipeMap(slotAnalysisScratch)
	return slotAnalysisScratch
end

local function finishSlotAnalysisPass(activeKeys)
	if type(activeKeys) ~= "table" then return end
	for key in pairs(slotAnalysisCache) do
		if not activeKeys[key] then slotAnalysisCache[key] = nil end
	end
	for key in pairs(tooltipCache) do
		if not activeKeys[key] then tooltipCache[key] = nil end
	end
	wipeMap(activeKeys)
end

local function getSlotAnalysisState(bagInfo, itemLink)
	local itemID = bagInfo and bagInfo.itemID or 0
	local quality = bagInfo and bagInfo.quality or 0
	local hasNoValue = bagInfo and bagInfo.hasNoValue == true or false
	local link = itemLink or (bagInfo and bagInfo.hyperlink) or ""
	return itemID, quality, hasNoValue, link
end

local function getSlotAnalysisEntry(bag, slot, bagInfo, itemLink, activeKeys)
	local key = bag .. "_" .. slot
	if activeKeys then activeKeys[key] = true end
	local itemID, quality, hasNoValue, link = getSlotAnalysisState(bagInfo, itemLink)
	local cached = slotAnalysisCache[key]
	if cached and cached.cacheVersion == slotAnalysisCacheVersion and cached.itemID == itemID and cached.quality == quality and cached.hasNoValue == hasNoValue and cached.itemLink == link then
		return cached
	end
	tooltipCache[key] = nil
	cached = {
		cacheVersion = slotAnalysisCacheVersion,
		itemID = itemID,
		quality = quality,
		hasNoValue = hasNoValue,
		itemLink = link,
	}
	slotAnalysisCache[key] = cached
	return cached
end

local function getCachedItemInfo(cached, itemID, itemLink)
	if not cached.itemInfoLoaded then
		local itemName, _, quality, _, _, _, _, _, itemEquipLoc, _, sellPrice, classID, subclassID, bindType, expansionID = C_Item.GetItemInfo(itemLink)
		if not itemName then
			if itemID then C_Item.RequestLoadItemDataByID(itemID) end
			return nil
		end
		cached.itemInfoLoaded = true
		cached.itemName = itemName
		cached.quality = quality
		cached.sellPrice = sellPrice
		cached.classID = classID
		cached.subclassID = subclassID
		cached.bindType = bindType
		cached.expansionID = expansionID
		cached.itemEquipLoc = itemEquipLoc
	end
	return cached.itemName, cached.quality, cached.sellPrice, cached.classID, cached.subclassID, cached.bindType, cached.expansionID, cached.itemEquipLoc
end

local function getCachedDetailedItemLevel(cached, itemLink)
	if cached.detailedItemLevelLoaded ~= true then
		cached.detailedItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
		cached.detailedItemLevelLoaded = true
	end
	return cached.detailedItemLevel
end

local function getCachedTooltipInfo(cached, bag, slot, quality, bagInfo, itemLink)
	if not cached.tooltipInfoLoaded then
		local bType, canUpgrade, isIgnoredUpgradeTrack = getTooltipInfo(bag, slot, quality, bagInfo, itemLink)
		cached.tooltipInfoLoaded = true
		cached.bType = bType
		cached.canUpgrade = canUpgrade
		cached.isIgnoredUpgradeTrack = isIgnoredUpgradeTrack
	end
	return cached.bType, cached.canUpgrade, cached.isIgnoredUpgradeTrack
end

local function shouldReadTooltipUpgradeInfo(quality)
	local tabName = quality and addon.Vendor.variables.tabNames[quality] or nil
	if not tabName or not addon.db then return false end
	if addon.db["vendor" .. tabName .. "IgnoreUpgradable"] then return true end
	if addon.db["vendor" .. tabName .. "IgnoreHeroicTrack"] then return true end
	if addon.db["vendor" .. tabName .. "IgnoreMythTrack"] then return true end
	return false
end

local function shouldReadTooltipInfo(quality, bindType)
	if shouldReadTooltipUpgradeInfo(quality) then return true end
	return type(bindType) ~= "number"
end

local function isCosmeticItem(itemID, itemLink, classID, subclassID)
	local armorClass = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
	local cosmeticSubclass = Enum and Enum.ItemArmorSubclass and Enum.ItemArmorSubclass.Cosmetic or 5
	if classID == armorClass and subclassID == cosmeticSubclass then return true end

	local itemInfo = itemLink or itemID
	if itemInfo and C_Item and C_Item.IsCosmeticItem then return C_Item.IsCosmeticItem(itemInfo) == true end
	return false
end

local function createDestroyEntry(bag, slot, itemID, itemName, info)
	info = info or C_Container.GetContainerItemInfo(bag, slot)
	local count = info and info.stackCount or 1
	local icon = info and info.iconFileID or nil
	if not itemName then
		local instantName = C_Item.GetItemInfoInstant and select(1, C_Item.GetItemInfoInstant(itemID))
		if instantName then itemName = instantName end
	end
	return {
		bag = bag,
		slot = slot,
		itemID = itemID,
		name = itemName or ("Item #" .. tostring(itemID)),
		count = count,
		icon = icon,
	}
end

local function copyDestroyQueue(source)
	local result = {}
	for index = 1, #source do
		local entry = source[index]
		result[index] = {
			bag = entry.bag,
			slot = entry.slot,
			itemID = entry.itemID,
			name = entry.name,
			count = entry.count,
			icon = entry.icon,
		}
	end
	return result
end

local function destroyQueuesEqual(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	if #a ~= #b then return false end
	for i = 1, #a do
		local lhs = a[i]
		local rhs = b[i]
		if not lhs or not rhs then return false end
		if lhs.itemID ~= rhs.itemID or lhs.bag ~= rhs.bag or lhs.slot ~= rhs.slot or lhs.count ~= rhs.count then return false end
	end
	return true
end

local function extractItemID(input, clearCursor)
	if type(input) == "number" then return input end
	if type(input) == "table" then
		if input.itemID then return tonumber(input.itemID) end
		if input.link then input = input.link end
	end
	if type(input) == "string" then
		local id = tonumber(input)
		if id then return id end
		local linkID = input:match("item:(%d+)")
		if linkID then return tonumber(linkID) end
	end
	if clearCursor then
		local cursorType, itemID = GetCursorInfo()
		if cursorType == "item" and itemID then
			ClearCursor()
			return tonumber(itemID)
		end
	end
	return nil
end

local function anchorDestroyButton(button)
	if not button then return end
	if baganatorRegionRegistered then
		return
	end
	local customBagAnchor = addon.Bags and addon.Bags.functions and addon.Bags.functions.GetVendorDestroyButtonAnchor and addon.Bags.functions.GetVendorDestroyButtonAnchor() or nil
	if customBagAnchor then
		button:SetParent(customBagAnchor:GetParent() or UIParent)
		button:ClearAllPoints()
		button:SetPoint("RIGHT", customBagAnchor, "LEFT", -8, 0)
		return
	end
	local searchBox = _G.BagItemSearchBox
	if searchBox and searchBox.GetParent then
		button:SetParent(searchBox:GetParent() or UIParent)
		button:ClearAllPoints()
		button:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
	elseif ContainerFrameCombinedBags then
		button:SetParent(ContainerFrameCombinedBags)
		button:ClearAllPoints()
		button:SetPoint("TOPRIGHT", ContainerFrameCombinedBags, "TOPRIGHT", -36, -32)
	else
		button:SetParent(UIParent)
		button:ClearAllPoints()
		button:SetPoint("CENTER")
	end
end

local function removeDestroyItem(itemID)
	if not itemID then return end
	local list = addon.db["vendorIncludeDestroyList"]
	if not list or not list[itemID] then return end
	local name = list[itemID]
	list[itemID] = nil
	print(string.format(L["vendorDestroyRemoved"], name or ("Item #" .. tostring(itemID)), itemID))
	updateSellMarks(nil, true)
end

local function destroyRefreshList()
	local listFrame = ensureDestroyListFrame()
	if not listFrame then return end
	local queue = destroyState.queue or {}
	local rows = destroyState.rows or {}
	local total = #queue

	if total == 0 then
		listFrame.emptyLabel:Show()
	else
		listFrame.emptyLabel:Hide()
	end

	for index = 1, math.max(total, #rows) do
		local row = rows[index]
		if index > total then
			if row then row:Hide() end
		else
			local entry = queue[index]
			if not row then
				row = CreateFrame("Button", nil, listFrame)
				row:SetSize(204, 20)
				row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 8, -6 - (index - 1) * 22)
				row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")

				row.icon = row:CreateTexture(nil, "ARTWORK")
				row.icon:SetSize(18, 18)
				row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)

				row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
				row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
				row.text:SetJustifyH("LEFT")

				row:SetScript("OnClick", function(self, button)
					if button == "RightButton" and self.entry and self.entry.itemID then removeDestroyItem(self.entry.itemID) end
				end)

				rows[index] = row
			end

			row.entry = entry
			row.icon:SetTexture(entry.icon or 134400)
			if entry.name then
				if (entry.count or 1) > 1 then
					row.text:SetText(string.format("%s x%d", entry.name, entry.count or 1))
				else
					row.text:SetText(entry.name)
				end
			else
				row.text:SetText(entry.itemID and ("Item #" .. entry.itemID) or "")
			end
			row:Show()
		end
	end

	local height = total > 0 and (total * 22 + 14) or 36
	listFrame:SetHeight(height)
	destroyState.rows = rows
end

local function destroyHideList()
	if destroyState.list and destroyState.list:IsShown() then destroyState.list:Hide() end
end

applySellDestroyOverlayToItemButton = function(itemButton, overlaySell, overlayDestroy, baganatorContext)
	if not itemButton or not itemButton.CreateTexture then return end
	overlaySell = overlaySell == nil and addon.db["vendorShowSellOverlay"] or overlaySell
	overlayDestroy = overlayDestroy == nil and (addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"]) or overlayDestroy

	local bag, slot = getBagSlotFromItemButton(itemButton)
	if type(bag) ~= "number" or slot == nil or bag < 0 or bag > NUM_TOTAL_EQUIPPED_BAG_SLOTS then
		hideSellDestroyOverlays(itemButton)
		return
	end

	local key = bag .. "_" .. slot
	local isDestroy = destroyMarkLookup[key]
	local showSell = overlaySell and sellMarkLookup[key] and not isDestroy
	local showDestroy = overlayDestroy and isDestroy
	local overlayKind = showDestroy and "destroy" or (showSell and "sell" or nil)
	local matchesSearch = itemButtonMatchesSearch(itemButton)
	local useBaganatorCornerIcons = false
	if itemButton.BGR ~= nil then
		if baganatorContext ~= nil then
			useBaganatorCornerIcons = baganatorContext.useCornerIcons == true
		else
			useBaganatorCornerIcons = isBaganatorCornerWidgetActive()
		end
	end
	local hasDefaultJunkMark = false
	if showSell and not useBaganatorCornerIcons then
		hasDefaultJunkMark = itemButtonHasDefaultJunkMark(itemButton, bag, slot)
	end
	itemButton._enhanceQoLVendorOverlayKind = overlayKind

	if showSell then
		if not itemButton.SellOverlay then
			itemButton.SellOverlay = itemButton:CreateTexture(nil, "OVERLAY", nil, 6)
			itemButton.SellOverlay:SetAllPoints()
			itemButton.SellOverlay:SetColorTexture(1, 0, 0, 0.45)
		end
		applyItemButtonShapeMask(itemButton.SellOverlay, itemButton)
		if useBaganatorCornerIcons or hasDefaultJunkMark then
			if itemButton.ItemMarkSell then itemButton.ItemMarkSell:Hide() end
		else
			if not itemButton.ItemMarkSell then
				itemButton.ItemMarkSell = itemButton:CreateTexture(nil, "OVERLAY", nil, 7)
				itemButton.ItemMarkSell:SetTexture(ICON_TEXTURE_SELL)
				itemButton.ItemMarkSell:SetSize(16, 16)
				itemButton.ItemMarkSell:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMLEFT", 0, -1)
			end
			itemButton.ItemMarkSell:Show()
		end
		if addon.db["vendorShowSellHighContrast"] and matchesSearch then
			itemButton.SellOverlay:Show()
		else
			itemButton.SellOverlay:Hide()
		end
		if itemButton.ItemMarkSell then
			if not matchesSearch then
				itemButton.ItemMarkSell:SetAlpha(0.1)
				itemButton.SellOverlay:Hide()
			else
				itemButton.ItemMarkSell:SetAlpha(1)
			end
		end
	else
		if itemButton.ItemMarkSell then itemButton.ItemMarkSell:Hide() end
		if itemButton.SellOverlay then itemButton.SellOverlay:Hide() end
	end

	if showDestroy then
		if not itemButton.DestroyOverlay then
			itemButton.DestroyOverlay = itemButton:CreateTexture(nil, "OVERLAY", nil, 6)
			itemButton.DestroyOverlay:SetAllPoints()
			itemButton.DestroyOverlay:SetColorTexture(0.85, 0.1, 0.1, 0.45)
		end
		applyItemButtonShapeMask(itemButton.DestroyOverlay, itemButton)
		if useBaganatorCornerIcons then
			if itemButton.ItemMarkDestroy then itemButton.ItemMarkDestroy:Hide() end
		else
			if not itemButton.ItemMarkDestroy then
				itemButton.ItemMarkDestroy = itemButton:CreateTexture(nil, "OVERLAY", nil, 7)
				itemButton.ItemMarkDestroy:SetTexture(ICON_TEXTURE_DESTROY)
				itemButton.ItemMarkDestroy:SetSize(16, 16)
				itemButton.ItemMarkDestroy:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMLEFT", 0, -1)
			end
			itemButton.ItemMarkDestroy:Show()
		end
		if addon.db["vendorShowSellHighContrast"] and itemButton.DestroyOverlay and matchesSearch then
			itemButton.DestroyOverlay:Show()
		elseif itemButton.DestroyOverlay then
			itemButton.DestroyOverlay:Hide()
		end
		if itemButton.ItemMarkDestroy then
			if not matchesSearch then
				itemButton.ItemMarkDestroy:SetAlpha(0.1)
				if itemButton.DestroyOverlay then itemButton.DestroyOverlay:Hide() end
			else
				itemButton.ItemMarkDestroy:SetAlpha(1)
			end
		end
		if itemButton.ItemMarkSell then
			itemButton.ItemMarkSell:Hide()
			if itemButton.SellOverlay then itemButton.SellOverlay:Hide() end
		end
	else
		if itemButton.ItemMarkDestroy then itemButton.ItemMarkDestroy:Hide() end
		if itemButton.DestroyOverlay then itemButton.DestroyOverlay:Hide() end
	end
end

local function refreshSellDestroyOverlaySearchState(itemButton)
	if not itemButton then return end
	local overlayKind = itemButton._enhanceQoLVendorOverlayKind
	if not overlayKind then
		if itemButton.SellOverlay then itemButton.SellOverlay:Hide() end
		if itemButton.DestroyOverlay then itemButton.DestroyOverlay:Hide() end
		return
	end

	local matchesSearch = itemButtonMatchesSearch(itemButton)
	local highContrast = addon.db and addon.db["vendorShowSellHighContrast"]

	if overlayKind == "sell" then
		if itemButton.ItemMarkSell then itemButton.ItemMarkSell:SetAlpha(matchesSearch and 1 or 0.1) end
		if itemButton.SellOverlay then
			if highContrast and matchesSearch then
				itemButton.SellOverlay:Show()
			else
				itemButton.SellOverlay:Hide()
			end
		end
		if itemButton.ItemMarkDestroy then itemButton.ItemMarkDestroy:Hide() end
		if itemButton.DestroyOverlay then itemButton.DestroyOverlay:Hide() end
	elseif overlayKind == "destroy" then
		if itemButton.ItemMarkDestroy then itemButton.ItemMarkDestroy:SetAlpha(matchesSearch and 1 or 0.1) end
		if itemButton.DestroyOverlay then
			if highContrast and matchesSearch then
				itemButton.DestroyOverlay:Show()
			else
				itemButton.DestroyOverlay:Hide()
			end
		end
		if itemButton.ItemMarkSell then itemButton.ItemMarkSell:Hide() end
		if itemButton.SellOverlay then itemButton.SellOverlay:Hide() end
	else
		hideSellDestroyOverlays(itemButton)
	end
end

local function refreshSellDestroyOverlaySearchStateForFrame(frame)
	if not frame or not frame:IsShown() then return end
	for _, itemButton in frame:EnumerateValidItems() do
		refreshSellDestroyOverlaySearchState(itemButton)
	end
end

local function applySellDestroyOverlaysToFrame(frame)
	if not frame or not frame:IsShown() then return end
	local overlaySell = addon.db["vendorShowSellOverlay"]
	local overlayDestroy = addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"]

	for _, itemButton in frame:EnumerateValidItems() do
		applySellDestroyOverlayToItemButton(itemButton, overlaySell, overlayDestroy)
	end
end

applySellDestroyOverlaysToBaganatorButtons = function()
	local overlaySell = addon.db["vendorShowSellOverlay"]
	local overlayDestroy = addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"]
	local context = getBaganatorOverlayContext()
	for button in pairs(baganatorVisibleItemButtons) do
		if button and button.IsShown and button:IsShown() and isBaganatorBackpackItemButton(button) then
			applySellDestroyOverlayToItemButton(button, overlaySell, overlayDestroy, context)
		else
			baganatorVisibleItemButtons[button] = nil
			baganatorVisibleBackpackButtonCount = math.max(0, baganatorVisibleBackpackButtonCount - 1)
		end
	end
end

local function applyCurrentVendorMarksToVisibleUI()
	local overlaySell = addon.db["vendorShowSellOverlay"]
	local overlayDestroy = addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"]
	local frames = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}

	applySellDestroyOverlaysToFrame(ContainerFrameCombinedBags)
	for _, frame in ipairs(frames) do
		applySellDestroyOverlaysToFrame(frame)
	end
	if addon.Bags and addon.Bags.functions and addon.Bags.functions.ApplyVendorMarks then
		addon.Bags.functions.ApplyVendorMarks(overlaySell, overlayDestroy)
	end
	requestBaganatorOverlaySweep()
end

local function refreshSellDestroyOverlaySearchStateForBaganatorButtons()
	for button in pairs(baganatorTrackedItemButtons) do
		refreshSellDestroyOverlaySearchState(button)
	end
end

function addon.Vendor.functions.ApplySellDestroyOverlayToItemButton(itemButton, overlaySell, overlayDestroy)
	applySellDestroyOverlayToItemButton(itemButton, overlaySell, overlayDestroy)
end

function addon.Vendor.functions.RefreshSellDestroyOverlaySearchState(itemButton)
	refreshSellDestroyOverlaySearchState(itemButton)
end

function addon.Vendor.functions.HideSellDestroyOverlays(itemButton)
	hideSellDestroyOverlays(itemButton)
end

function addon.Vendor.functions.RefreshIntegratedBagsVendorMarks(searchOnly)
	if addon.Bags and addon.Bags.functions and addon.Bags.functions.ApplyVendorMarks then
		addon.Bags.functions.ApplyVendorMarks(nil, nil, searchOnly == true)
	end
end

local function setDestroyButtonVisibility(button, visible)
	if not button then return end
	local inCombat = InCombatLockdown and InCombatLockdown() or false
	local wasShown = button:IsShown()
	if visible then
		button:SetAlpha(1)
		if not inCombat then
			button:Show()
			button:Enable()
			button:EnableMouse(true)
		end
	else
		button:SetAlpha(0)
		if not inCombat then
			button:Disable()
			button:EnableMouse(false)
			button:Hide()
		end
		destroyHideList()
	end
	if baganatorRegionRegistered and not inCombat then requestBaganatorLayoutUpdateForDestroyRegion(false) end
end

local function hookBaganatorItemButton(itemButton)
	if not itemButton then return end
	if not baganatorTrackedItemButtons[itemButton] then
		baganatorTrackedItemButtons[itemButton] = true

		if itemButton.SetItemDetails then
			hooksecurefunc(itemButton, "SetItemDetails", function(self)
				refreshBaganatorVisibleButtonState(self)
				applySellDestroyOverlayToItemButton(self)
			end)
		end
		if itemButton.SetItemFiltered then hooksecurefunc(itemButton, "SetItemFiltered", function(self) refreshSellDestroyOverlaySearchState(self) end) end
		if itemButton.HookScript then
			if not itemButton.GetSlotAndBagID then itemButton:HookScript("OnClick", AltClickHook) end
			itemButton:HookScript("OnShow", function(self)
				refreshBaganatorVisibleButtonState(self)
				applySellDestroyOverlayToItemButton(self)
			end)
			itemButton:HookScript("OnHide", function(self)
				refreshBaganatorVisibleButtonState(self)
				hideSellDestroyOverlays(self)
				if baganatorVisibleBackpackButtonCount == 0 then destroyHideList() end
			end)
		end
	end

	refreshBaganatorVisibleButtonState(itemButton)
	applySellDestroyOverlayToItemButton(itemButton)
end

ensureBaganatorIntegration = function(existingButton)
	local api = _G.Baganator and _G.Baganator.API
	if not api then return end
	if not shouldUseBaganatorIntegration() then return end

	local useSellDestroy = shouldUseBaganatorSellDestroyIntegration()
	local useDestroyRegion = shouldUseBaganatorDestroyRegion()
	local useUpgrade = shouldUseBaganatorUpgradeIntegration()

	if useSellDestroy and not baganatorCornerWidgetRegistered and api.RegisterCornerWidget then
		local ok = pcall(api.RegisterCornerWidget, BAGANATOR_CORNER_WIDGET_LABEL, BAGANATOR_CORNER_WIDGET_ID, function(cornerFrame, details)
			local itemLocation = details and details.itemLocation
			if not (itemLocation and itemLocation.bagID ~= nil and itemLocation.slotIndex ~= nil and C_Item.DoesItemExist(itemLocation)) then return false end
			local bag, slot = itemLocation.bagID, itemLocation.slotIndex
			if bag < 0 or bag > NUM_TOTAL_EQUIPPED_BAG_SLOTS then return false end
			local key = bag .. "_" .. slot
			if destroyMarkLookup[key] then
				cornerFrame:SetTexture(ICON_TEXTURE_DESTROY)
				return true
			end
			if sellMarkLookup[key] then
				cornerFrame:SetTexture(ICON_TEXTURE_SELL)
				return true
			end
			return false
		end, function(itemButton)
			local icon = itemButton:CreateTexture(nil, "OVERLAY")
			icon:SetSize(15, 15)
			icon.padding = 0
			return icon
		end, { corner = "bottom_left", priority = 2 }, true)
		if ok then
			baganatorCornerWidgetRegistered = true
			requestBaganatorItemWidgetRefresh()
		end
	end

	if useUpgrade and not baganatorUpgradeCornerWidgetRegistered and api.RegisterCornerWidget then
		local ok = pcall(api.RegisterCornerWidget, BAGANATOR_UPGRADE_WIDGET_LABEL, BAGANATOR_UPGRADE_WIDGET_ID, function(cornerFrame, details)
			local itemLocation = details and details.itemLocation
			if not shouldShowBaganatorUpgradeCornerWidget(itemLocation) then return false end
			cornerFrame:SetTexture(ICON_TEXTURE_UPGRADE)
			cornerFrame:SetVertexColor(0, 1, 0, 1)
			return true
		end, function(itemButton)
			local icon = itemButton:CreateTexture(nil, "OVERLAY")
			icon:SetSize(15, 15)
			icon.padding = 0
			icon:SetTexture(ICON_TEXTURE_UPGRADE)
			icon:SetVertexColor(0, 1, 0, 1)
			return icon
		end, { corner = "bottom_right", priority = 2 }, true)
		if ok then
			baganatorUpgradeCornerWidgetRegistered = true
			requestBaganatorItemWidgetRefresh()
		end
	end

	if useSellDestroy and not baganatorSkinsListenerRegistered and api.Skins and api.Skins.RegisterListener then
		api.Skins.RegisterListener(function(details)
			if details and details.regionType == "ItemButton" and details.region then hookBaganatorItemButton(details.region) end
		end)
		baganatorSkinsListenerRegistered = true
	end

	if (useSellDestroy or useDestroyRegion) and not baganatorCallbacksRegistered and _G.Baganator and _G.Baganator.CallbackRegistry and _G.Baganator.CallbackRegistry.RegisterCallback then
		local callbackRegistry = _G.Baganator.CallbackRegistry
		callbackRegistry:RegisterCallback("BagShow", function()
			RunNextFrame(function()
				if vendorMarksActive then
					applyCurrentVendorMarksToVisibleUI()
				else
					updateSellMarks(nil, false)
				end
				if addon.db and addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
			end)
		end)
		callbackRegistry:RegisterCallback("BackpackFrameChanged", function()
			RunNextFrame(function()
				if vendorMarksActive then
					applyCurrentVendorMarksToVisibleUI()
				else
					updateSellMarks(nil, false)
				end
				if addon.db and addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
			end)
		end)
		callbackRegistry:RegisterCallback("ViewComplete", function()
			requestBaganatorOverlaySweep()
			if destroyState.button and not baganatorRegionRegistered and (not InCombatLockdown or not InCombatLockdown()) then anchorDestroyButton(destroyState.button) end
		end)
		callbackRegistry:RegisterCallback("SettingChanged", function()
			invalidateBaganatorCornerWidgetActiveCache()
			requestBaganatorOverlaySweep()
		end)
		callbackRegistry:RegisterCallback("BagHide", function()
			destroyHideList()
			if addon.db and addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
		end)
		baganatorCallbacksRegistered = true
	end

	if useSellDestroy and not baganatorInitialFrameScanCompleted and api.Skins and api.Skins.GetAllFrames then
		local allFrames = api.Skins.GetAllFrames()
		if type(allFrames) == "table" then
			for _, details in ipairs(allFrames) do
				if details and details.regionType == "ItemButton" and details.region then hookBaganatorItemButton(details.region) end
			end
		end
		baganatorInitialFrameScanCompleted = true
	end

	local button = existingButton or destroyState.button
	if button and button._EnhanceQoLVendorBaganatorRegionRegistered then baganatorRegionRegistered = true end
	if useDestroyRegion and not baganatorRegionRegistered and button and api.RegisterRegion then
		api.RegisterRegion(BAGANATOR_REGION_LABEL, BAGANATOR_REGION_ID, "backpack", "bottom_left", button)
		button._EnhanceQoLVendorBaganatorRegionRegistered = true
		baganatorRegionRegistered = true
		requestBaganatorLayoutUpdateForDestroyRegion(true)
	end
end

ensureDestroyButton = function()
	if destroyState.button and destroyState.button:IsObjectType("Button") then return destroyState.button end
	if InCombatLockdown and InCombatLockdown() then
		destroyState.pendingUpdate = true
		return nil
	end

	local button = CreateFrame("Button", addonName .. "_DestroyButton", UIParent, "InsecureActionButtonTemplate")
	button:SetSize(28, 28)
	button:RegisterForClicks("LeftButtonUp")
	button:SetNormalTexture(ICON_TEXTURE_DESTROY)
	button:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-DE-Down")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnEnter", function(self)
		if not addon.db["vendorDestroyEnable"] then return end
		local queue = destroyState.queue or {}
		if #queue > 0 then
			destroyRefreshList()
			local list = ensureDestroyListFrame()
			if list then
				list:ClearAllPoints()
				list:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
				list:Show()
			end
		else
			destroyHideList()
		end
		if GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(L["vendorDestroyButtonTooltip"])
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function(self)
		if GameTooltip then GameTooltip:Hide() end
		C_Timer.After(0.05, function()
			if self:IsMouseOver() then return end
			if destroyState.list and destroyState.list:IsShown() and destroyState.list:IsMouseOver() then return end
			destroyHideList()
		end)
	end)
	button:SetScript("OnHide", destroyHideList)
	button:SetScript("OnClick", function()
		if not addon.db["vendorDestroyEnable"] then return end
		local queue = destroyState.queue or {}
		local entry = queue[1]
		if not entry then
			print(L["vendorDestroyEmpty"] or "Nothing queued for destruction.")
			return
		end
		if InCombatLockdown and InCombatLockdown() then
			print(L["vendorDestroyCombat"] or "Cannot destroy items while in combat.")
			return
		end

		local bag, slot = entry.bag, entry.slot
		if bag == nil or slot == nil then
			table.remove(queue, 1)
			updateDestroyUI(copyDestroyQueue(queue))
			return
		end

		local info = C_Container.GetContainerItemInfo(bag, slot)
		if not info then
			print(L["vendorDestroyMissing"] or "Queued item is no longer in your bags.")
			table.remove(queue, 1)
			updateDestroyUI(copyDestroyQueue(queue))
			scheduleDestroyButtonUpdate()
			return
		end

		local link = C_Container.GetContainerItemLink(bag, slot)
		if not link and entry.itemID then link = C_Item.GetItemLink(entry.itemID) end
		if not link then link = entry.name or ("Item #" .. tostring(entry.itemID or "?")) end
		link = tostring(link)

		local reason = getDestroyProtectionReason(entry.itemID, info)
		if reason then
			notifyDestroyProtection(entry.itemID, link, reason)
			if addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][entry.itemID] = nil end
			table.remove(queue, 1)
			updateDestroyUI(copyDestroyQueue(queue))
			scheduleDestroyButtonUpdate()
			return
		end

		if info.isLocked then
			print(L["vendorDestroyLocked"] or "Item is locked.")
			return
		end

		local count = info.stackCount or entry.count or 1

		C_Container.PickupContainerItem(bag, slot)
		if not CursorHasItem() then
			print(L["vendorDestroyFailed"] or "Unable to pick up item for deletion.")
			return
		end

		DeleteCursorItem()
		if CursorHasItem() then
			ClearCursor()
			print(L["vendorDestroyConfirm"] or "Item requires manual confirmation to delete.")
			return
		end

		table.remove(queue, 1)
		if addon.db["vendorDestroyShowMessages"] ~= false then print(string.format(L["vendorDestroyDestroyed"] or "Destroyed: %s", link .. (count > 1 and (" x" .. count) or ""))) end
		updateDestroyUI(copyDestroyQueue(queue))
		updateSellMarks(nil, true)
	end)
	setDestroyButtonVisibility(button, false)
	anchorDestroyButton(button)

	local count = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
	count:SetJustifyH("RIGHT")
	button.count = count

	destroyState.button = button
	ensureBaganatorIntegration(button)
	return button
end

updateDestroyButtonState = function()
	if destroyState.pendingQueue then
		destroyState.queue = destroyState.pendingQueue
		destroyState.pendingQueue = nil
	end

	if not addon.db["vendorDestroyEnable"] or not inventoryOpen() then
		if destroyState.button then setDestroyButtonVisibility(destroyState.button, false) end
		destroyHideList()
		destroyState.pendingUpdate = false
		return
	end

	if InCombatLockdown and InCombatLockdown() then
		destroyState.pendingUpdate = true
		return
	end

	local button = ensureDestroyButton()
	if not button then
		destroyState.pendingUpdate = true
		return
	end
	ensureBaganatorIntegration(button)

	local queue = destroyState.queue or {}
	while #queue > 0 do
		local first = queue[1]
		local info = first and C_Container.GetContainerItemInfo(first.bag, first.slot)
		local reason = first and getDestroyProtectionReason(first.itemID, info)
		if not reason then break end
		local descriptor = (info and C_Container.GetContainerItemLink(first.bag, first.slot)) or first.name or ("Item #" .. tostring(first.itemID or "?"))
		descriptor = tostring(descriptor)
		notifyDestroyProtection(first.itemID, descriptor, reason)
		if addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][first.itemID] = nil end
		table.remove(queue, 1)
	end
	if not inventoryOpen() or #queue == 0 then
		setDestroyButtonVisibility(button, false)
		if button.count then button.count:SetText("") end
		destroyHideList()
		destroyState.pendingUpdate = false
		return
	end

	local entry = queue[1]
	local info = entry and C_Container.GetContainerItemInfo(entry.bag, entry.slot)
	local inCombat = InCombatLockdown and InCombatLockdown() or false
	if not inCombat then
		if info and info.isLocked then
			button:Disable()
		else
			button:Enable()
		end
	end

	setDestroyButtonVisibility(button, true)
	if button.count then button.count:SetText(#queue) end
	if destroyState.list and destroyState.list:IsShown() then
		destroyRefreshList()
		destroyState.list:ClearAllPoints()
		destroyState.list:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -4)
	end
	destroyState.pendingUpdate = false
end

function updateDestroyUI(queue)
	queue = queue or {}
	if destroyQueuesEqual(destroyState.queue, queue) then
		if destroyState.pendingUpdate then scheduleDestroyButtonUpdate() end
		return
	end

	destroyState.pendingQueue = copyDestroyQueue(queue)
	if InCombatLockdown and InCombatLockdown() then
		destroyState.pendingUpdate = true
		return
	end

	scheduleDestroyButtonUpdate()
end

local function updateSellMoreButton()
	if not sellMoreButton then return end
	if addon.db["vendorOnly12Items"] and hasMoreItems and MerchantFrame:IsShown() then
		sellMoreButton:ClearAllPoints()
		if MerchantRepairItemButton and MerchantRepairItemButton:IsShown() then
			sellMoreButton:SetPoint("TOPLEFT", MerchantRepairItemButton, "BOTTOMLEFT", 5, -5)
		elseif MerchantSellAllJunkButton and MerchantSellAllJunkButton:IsShown() then
			sellMoreButton:SetPoint("TOPRIGHT", MerchantSellAllJunkButton, "BOTTOMLEFT", -5, -5)
		else
			sellMoreButton:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 60, 60)
		end
		sellMoreButton:Show()
	else
		sellMoreButton:Hide()
	end
end

frameLoad = CreateFrame("Frame")

local function sellItems(items)
	autoSellInProgress = true
	autoSellNeedsRefresh = false
	local index = 1

	local function finishAutoSell()
		autoSellInProgress = false
		updateSellMoreButton()
		if addon.functions and addon.functions.FlushDeferredItemInventoryAutoSellUpdates then addon.functions.FlushDeferredItemInventoryAutoSellUpdates() end
		if autoSellNeedsRefresh and inventoryOpen() then
			autoSellNeedsRefresh = false
			updateSellMarks()
			if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
		else
			autoSellNeedsRefresh = false
		end
	end

	local function sellNextItem()
		if not MerchantFrame:IsShown() then
			autoSellInProgress = false
			autoSellNeedsRefresh = false
			print(L["MerchantWindowClosed"])
			return
		end
		if index > #items then
			finishAutoSell()
			return
		end

		local item = items[index]
		index = index + 1
		C_Container.UseContainerItem(item.bag, item.slot)
		C_Timer.After(0.1, sellNextItem) -- 100ms Pause zwischen den Verkäufen
	end
	sellNextItem()
end

local function getVendorUpgradeInfo(itemLink)
	if not itemLink then return nil, nil, nil end

	local trackKey
	local currentLevel
	local maxLevel

	if addon.functions then
		local info = addon.functions.GetItemUpgradeInfoForLink and addon.functions.GetItemUpgradeInfoForLink(itemLink)
		if type(info) == "table" then
			trackKey = info.key
			currentLevel = tonumber(info.currentLevel)
			maxLevel = tonumber(info.maxLevel)
		elseif addon.functions.GetUpgradeTrackKeyFromItemLink then
			trackKey = addon.functions.GetUpgradeTrackKeyFromItemLink(itemLink)
		end
	end

	if currentLevel == nil or maxLevel == nil then
		local rawInfo = C_Item and C_Item.GetItemUpgradeInfo and C_Item.GetItemUpgradeInfo(itemLink)
		if type(rawInfo) == "table" then
			currentLevel = tonumber(rawInfo.currentLevel)
			maxLevel = tonumber(rawInfo.maxLevel)
		end
	end

	return trackKey, currentLevel, maxLevel
end

getTooltipInfo = function(bag, slot, quality, bagInfo, itemLink)
	local key = bag .. "_" .. slot
	local resolvedItemLink = itemLink or (bagInfo and bagInfo.hyperlink) or C_Container.GetContainerItemLink(bag, slot)
	local cacheItemKey = resolvedItemLink or (bagInfo and bagInfo.itemID) or C_Container.GetContainerItemID(bag, slot)
	local cacheQuality = quality or (bagInfo and bagInfo.quality) or false
	local cached = tooltipCache[key]
	if cached and cached.itemKey == cacheItemKey and cached.quality == cacheQuality then return cached.bType, cached.canUpgrade, cached.isIgnoredUpgradeTrack end

	local effectiveQuality = quality or (bagInfo and bagInfo.quality)
	local tabName = addon.Vendor.variables.tabNames[effectiveQuality]
	local bType
	local canUpgrade = false
	local isIgnoredUpgradeTrack = false
	local ignoreUpgradable = tabName and addon.db["vendor" .. tabName .. "IgnoreUpgradable"]
	local ignoreMythTrack = tabName and addon.db["vendor" .. tabName .. "IgnoreMythTrack"]
	local ignoreHeroicTrack = tabName and addon.db["vendor" .. tabName .. "IgnoreHeroicTrack"]
	local trackKey, currentLevel, maxLevel = getVendorUpgradeInfo(resolvedItemLink)

	if ignoreUpgradable and currentLevel and maxLevel and maxLevel > 0 and currentLevel < maxLevel then canUpgrade = true end
	if (ignoreMythTrack and trackKey == "myth") or (ignoreHeroicTrack and trackKey == "hero") then isIgnoredUpgradeTrack = true end

	local data = C_TooltipInfo.GetBagItem(bag, slot)
	if data then
		local lines = data.lines
		for i = 1, lines and #lines or 0 do
			local v = lines[i]
			if v.type == 20 then
				if not bType and v.leftText == ITEM_BIND_ON_EQUIP then
					bType = 2
				elseif not bType and (v.leftText == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or v.leftText == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP) then
					bType = 8
				elseif not bType and (v.leftText == ITEM_ACCOUNTBOUND or v.leftText == ITEM_BIND_TO_BNETACCOUNT) then
					bType = 7
				end
			elseif v.type == 42 then
				local text = v.rightText or v.leftText
				if text then
					if ignoreUpgradable and not canUpgrade then
						local color = v.leftColor
						if color and color.r and color.g and color.b then
							if not (color.r > 0.5 and color.g > 0.5 and color.b > 0.5) then canUpgrade = true end
						end
					end
					if not isIgnoredUpgradeTrack and (ignoreMythTrack or ignoreHeroicTrack) then
						local tier = text:gsub(".+:%s?", ""):gsub("%s?%d/%d", "")
						if tier then
							local tierLower = string.lower(tier)
							if (ignoreMythTrack and string.lower(L["upgradeLevelMythic"]) == tierLower) or (ignoreHeroicTrack and string.lower(L["upgradeLevelHero"]) == tierLower) then
								isIgnoredUpgradeTrack = true
							end
						end
					end
				end
			end
		end
	end

	tooltipCache[key] = {
		itemKey = cacheItemKey,
		quality = cacheQuality,
		bType = bType,
		canUpgrade = canUpgrade,
		isIgnoredUpgradeTrack = isIgnoredUpgradeTrack,
	}
	return bType, canUpgrade, isIgnoredUpgradeTrack
end

local function isItemInEquipmentSet(bag, slot, quality)
	if quality == nil or quality < 2 or quality > 4 then return false end
	local tabName = addon.Vendor.variables.tabNames[quality]
	if not tabName then return false end
	if not addon.db["vendor" .. tabName .. "IgnoreEquipmentSets"] then return false end
	if not (C_Container and C_Container.GetContainerItemEquipmentSetInfo) then return false end
	local inSet = C_Container.GetContainerItemEquipmentSetInfo(bag, slot)
	return inSet == true
end

local function lookupDestroyItemsFast()
	local itemsToDestroy = {}
	local includeDestroy = addon.db["vendorIncludeDestroyList"]
	local includeSell = addon.db["vendorIncludeSellList"]

	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		local numSlots = C_Container.GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				local itemID = info and info.itemID or C_Container.GetContainerItemID(bag, slot)
				if itemID and info then
					local inDestroy = includeDestroy and includeDestroy[itemID]
					local inSell = includeSell and includeSell[itemID]

					if isCosmeticItem(itemID, info.hyperlink) then
						-- Cosmetics are never auto-vendored or queued by vendor helpers.
					elseif info.hasNoValue and (inDestroy or inSell) then
						if not getDestroyProtectionReason(itemID, info, info.quality) then table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, info.itemName, info)) end
					elseif inDestroy then
						if not getDestroyProtectionReason(itemID, info, info.quality) then table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, info.itemName, info)) end
					elseif inSell then
						local sellPrice = select(11, C_Item.GetItemInfo(itemID)) or 0
						if sellPrice <= 0 and not getDestroyProtectionReason(itemID, info, info.quality) then
							table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, info.itemName, info))
						end
					end
				end
			end
		end
	end

	return itemsToDestroy
end

local function lookupItems()
	local _, avgItemLevelEquipped = GetAverageItemLevel()
	local itemsToSell = {}
	local itemsToDestroy = {}
	local activeKeys = beginSlotAnalysisPass()
	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			if itemID then
				local bagInfo = C_Container.GetContainerItemInfo(bag, slot)
				local itemLink = (bagInfo and bagInfo.hyperlink) or C_Container.GetContainerItemLink(bag, slot)
				local itemNameFromBag = bagInfo and bagInfo.itemName
				local hasNoValue = bagInfo and bagInfo.hasNoValue
				local qualityFromBag = bagInfo and bagInfo.quality
				local cached = getSlotAnalysisEntry(bag, slot, bagInfo, itemLink, activeKeys)

				local inDestroyList = addon.db["vendorIncludeDestroyList"] and addon.db["vendorIncludeDestroyList"][itemID]
				local inSellList = addon.db["vendorIncludeSellList"] and addon.db["vendorIncludeSellList"][itemID]

				local processed = false
				if isCosmeticItem(itemID, itemLink) then
					processed = true
				end
				if not processed and hasNoValue and (inDestroyList or inSellList) then
					local reason = getDestroyProtectionReason(itemID, bagInfo, qualityFromBag)
					if reason then
						notifyDestroyProtection(itemID, itemLink or itemNameFromBag, reason)
						if inDestroyList and addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][itemID] = nil end
						if inSellList and addon.db["vendorIncludeSellList"] then addon.db["vendorIncludeSellList"][itemID] = nil end
					else
						local displayName = itemNameFromBag or (itemLink and itemLink:match("%[(.+)%]")) or ("Item #" .. tostring(itemID))
						table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, displayName, bagInfo))
					end
					processed = true
				end

				if not processed then
					local itemName, quality, sellPrice, classID, subclassID, bindType, expansionID, itemEquipLoc = getCachedItemInfo(cached, itemID, itemLink)
					if not itemName then
						-- Item data is still loading. Keep the slot cache warm so the next refresh
						-- can reuse any unchanged slot state instead of rebuilding from scratch.
					else
						local resolvedName = itemNameFromBag or itemName
						local reason

						if isCosmeticItem(itemID, itemLink, classID, subclassID) then
							-- Cosmetics can have a vendor price, but should never be auto-vendored.
						elseif inDestroyList then
							reason = getDestroyProtectionReason(itemID, bagInfo, quality)
							if reason then
								notifyDestroyProtection(itemID, itemLink or resolvedName, reason)
								if addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][itemID] = nil end
							else
								table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, resolvedName, bagInfo))
							end
						elseif addon.db["vendorExcludeSellList"][itemID] then
							-- skip
						elseif inSellList then
							if sellPrice and sellPrice > 0 then
								table.insert(itemsToSell, { bag = bag, slot = slot, itemID = itemID })
							else
								reason = getDestroyProtectionReason(itemID, bagInfo, quality)
								if reason then
									notifyDestroyProtection(itemID, itemLink or resolvedName, reason)
									if addon.db["vendorIncludeSellList"] then addon.db["vendorIncludeSellList"][itemID] = nil end
								else
									table.insert(itemsToDestroy, createDestroyEntry(bag, slot, itemID, resolvedName, bagInfo))
								end
							end
						elseif sellPrice and sellPrice > 0 then
							if isItemInEquipmentSet(bag, slot, quality) then
								-- Keep items that are assigned to an equipment set.
							elseif itemEquipLoc == "INVTYPE_TABARD" then
								-- Tabards often have very low item levels but should not be auto-vendored.
							elseif quality == 0 and addon.Vendor.variables.itemQualityFilter[quality] then
								local effectiveBindType = bindType or 0
								if shouldReadTooltipInfo(quality, bindType) then
									local bType = select(1, getCachedTooltipInfo(cached, bag, slot, quality, bagInfo, itemLink))
									if bType and effectiveBindType < bType then effectiveBindType = bType end
								end
								local bindFilter = addon.Vendor.variables.itemBindTypeQualityFilter[quality]
								if bindFilter and bindFilter[effectiveBindType] then table.insert(itemsToSell, { bag = bag, slot = slot, itemID = itemID }) end
							elseif classID == 7 and addon.Vendor.variables.itemQualityFilter[quality] then
								local expTable = addon.db["vendor" .. addon.Vendor.variables.tabNames[quality] .. "CraftingExpansions"]
								if expTable and expTable[expansionID] then table.insert(itemsToSell, { bag = bag, slot = slot, itemID = itemID }) end
							elseif addon.Vendor.variables.itemQualityFilter[quality] then
								local effectiveILvl = getCachedDetailedItemLevel(cached, itemLink)
								local effectiveBindType = bindType or 0
								local canUpgrade = false
								local isIgnoredUpgradeTrack = false
								if shouldReadTooltipInfo(quality, bindType) then
									local bType, tooltipCanUpgrade, tooltipIgnoredUpgradeTrack = getCachedTooltipInfo(cached, bag, slot, quality, bagInfo, itemLink)
									if bType and effectiveBindType < bType then effectiveBindType = bType end
									canUpgrade = tooltipCanUpgrade == true
									isIgnoredUpgradeTrack = tooltipIgnoredUpgradeTrack == true
								end
								if
									addon.Vendor.variables.itemTypeFilter[classID]
									and (not addon.Vendor.variables.itemSubTypeFilter[classID] or (addon.Vendor.variables.itemSubTypeFilter[classID] and addon.Vendor.variables.itemSubTypeFilter[classID][subclassID]))
									and addon.Vendor.variables.itemBindTypeQualityFilter[quality][effectiveBindType]
								then
									if not canUpgrade and not isIgnoredUpgradeTrack then
										local rIlvl = (avgItemLevelEquipped - addon.db["vendor" .. addon.Vendor.variables.tabNames[quality] .. "MinIlvlDif"])
										if addon.db["vendor" .. addon.Vendor.variables.tabNames[quality] .. "AbsolutIlvl"] then
											rIlvl = addon.db["vendor" .. addon.Vendor.variables.tabNames[quality] .. "MinIlvlDif"]
										end
										if effectiveILvl <= rIlvl then table.insert(itemsToSell, { bag = bag, slot = slot, itemID = itemID }) end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	finishSlotAnalysisPass(activeKeys)
	return itemsToSell, itemsToDestroy
end

local function checkItem()
	hasMoreItems = false
	updateSellMoreButton()
	local _, avgItemLevelEquipped = GetAverageItemLevel()
	local itemsToSell = select(1, lookupItems()) or {}

	if #itemsToSell > 0 then
		if addon.db["vendorOnly12Items"] then
			if #itemsToSell > 12 then hasMoreItems = true end

			local limitedItems = {}
			for i = 1, math.min(12, #itemsToSell) do
				table.insert(limitedItems, itemsToSell[i])
			end
			itemsToSell = limitedItems
		end
		C_Timer.After(0.1, function() sellItems(itemsToSell) end)
	end
end

local function createSellMoreButton()
	if sellMoreButton then return end
	sellMoreButton = CreateFrame("Button", nil, MerchantFrame, "GameMenuButtonTemplate")
	sellMoreButton:SetSize(120, 25)

	sellMoreButton:SetText(L["vendorSellNext"])
	sellMoreButton:SetScript("OnClick", function(self)
		checkItem()
		self:Hide()
	end)
	sellMoreButton:Hide()
end

local eventHandlers = {
	["MERCHANT_SHOW"] = function()
		createSellMoreButton()
		if (IsShiftKeyDown() and addon.db["vendorSwapAutoSellShift"] == false) or (addon.db["vendorSwapAutoSellShift"] and not IsShiftKeyDown()) then
			updateSellMoreButton()
			return
		end
		checkItem()
	end,
	["MERCHANT_CLOSED"] = function()
		autoSellInProgress = false
		autoSellNeedsRefresh = false
		if addon.functions and addon.functions.FlushDeferredItemInventoryAutoSellUpdates then addon.functions.FlushDeferredItemInventoryAutoSellUpdates() end
		hasMoreItems = false
		updateSellMoreButton()
		updateSellMarks()
		if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
	end,
	["BAG_UPDATE_DELAYED"] = function()
		if autoSellInProgress then
			autoSellNeedsRefresh = true
			return
		end
		updateSellMarks()
		if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
	end,
	["EQUIPMENT_SETS_CHANGED"] = function() updateSellMarks() end,
	["ADDON_LOADED"] = function(loadedAddonName)
		if loadedAddonName ~= "Baganator" then return end
		ensureBaganatorIntegration()
		updateSellMarks()
		if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
	end,
	["PLAYER_AVG_ITEM_LEVEL_UPDATE"] = function()
		local _, avgItemLevelEquipped = GetAverageItemLevel()
		addon.Vendor.variables.avgItemLevelEquipped = avgItemLevelEquipped
	end,
	["INVENTORY_SEARCH_UPDATE"] = function()
		refreshSellDestroyOverlaySearchStateForFrame(ContainerFrameCombinedBags)
		local frames = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}
		for _, frame in ipairs(frames) do
			refreshSellDestroyOverlaySearchStateForFrame(frame)
		end
		if addon.Bags and addon.Bags.functions and addon.Bags.functions.ApplyVendorMarks then
			addon.Bags.functions.ApplyVendorMarks(nil, nil, true)
		end
		refreshSellDestroyOverlaySearchStateForBaganatorButtons()
	end,
	["PLAYER_REGEN_ENABLED"] = function()
		if destroyState.pendingQueue then
			destroyState.queue = destroyState.pendingQueue
			destroyState.pendingQueue = nil
		end
		destroyState.pendingUpdate = false
		if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
	end,
	["PLAYER_REGEN_DISABLED"] = function() destroyHideList() end,
}
local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

-- Expose helpers for external settings UI
function addon.Vendor.functions.refreshSellMarks(resetCache)
	if updateSellMarks then updateSellMarks(nil, resetCache ~= false) end
end

function addon.Vendor.functions.refreshDestroyButton()
	if updateDestroyButtonState then updateDestroyButtonState() end
end

function addon.Vendor.functions.IsAutoSellInProgress()
	return autoSellInProgress == true
end

-- Integrate Vendor into Items -> Vendors & Economy -> Selling (Auto‑Sell)
-- addon.variables.statusTable.groups["items\001economy"] = true
-- addon.variables.statusTable.groups["items\001economy\001selling"] = true
local function performUpdateSellMarks(resetCache)
	if resetCache then invalidateVendorScanCaches() end

	local overlaySell = addon.db["vendorShowSellOverlay"]
	local overlayDestroy = addon.db["vendorDestroyEnable"] and addon.db["vendorShowDestroyOverlay"]
	local tooltip = addon.db["vendorShowSellTooltip"]
	local frames = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}
	local inventoryVisible = inventoryOpen()

	local function clearFrame(frame)
		if frame and frame:IsShown() then
			for _, itemButton in frame:EnumerateValidItems() do
				hideSellDestroyOverlays(itemButton)
			end
		end
	end

	if not inventoryVisible then
		updateDestroyUI({})
		wipe(sellMarkLookup)
		wipe(destroyMarkLookup)
		return
	end

	if not overlaySell and not overlayDestroy and not tooltip then
		-- Keep the destroy queue in sync even when overlays/tooltips are off
		if addon.db["vendorDestroyEnable"] and inventoryOpen() then
			local itemsToDestroy = lookupDestroyItemsFast()
			updateDestroyUI(itemsToDestroy or {})
		else
			-- No need to scan; make sure the button hides
			updateDestroyUI({})
		end

		clearFrame(ContainerFrameCombinedBags)
		for _, frame in ipairs(frames) do
			clearFrame(frame)
		end
		if addon.Bags and addon.Bags.functions and addon.Bags.functions.ApplyVendorMarks then
			addon.Bags.functions.ApplyVendorMarks(false, false)
		end
		requestBaganatorOverlaySweep()
		wipe(sellMarkLookup)
		wipe(destroyMarkLookup)
		if vendorMarksActive then
			bumpVendorMarksRevision()
			requestBaganatorSellDestroyWidgetRefreshIfNeeded()
		end
		vendorMarksActive = false
		return
	end

	vendorMarksActive = true
	wipe(sellMarkLookup)
	wipe(destroyMarkLookup)

	local itemsToSell, itemsToDestroy = lookupItems()
	itemsToSell = itemsToSell or {}
	itemsToDestroy = itemsToDestroy or {}
	updateDestroyUI(itemsToDestroy)

	for _, v in ipairs(itemsToSell) do
		sellMarkLookup[v.bag .. "_" .. v.slot] = true
	end
	for _, v in ipairs(itemsToDestroy) do
		destroyMarkLookup[v.bag .. "_" .. v.slot] = v
	end
	bumpVendorMarksRevision()

	applyCurrentVendorMarksToVisibleUI()
	requestBaganatorSellDestroyWidgetRefreshIfNeeded()
end

function updateSellMarks(_, resetCache)
	if not shouldUseVendorMarkUpdates() and not vendorMarksActive then return end
	sellMarksDirty = true
	if resetCache then pendingSellMarksReset = true end
	if not inventoryOpen() then return end
	if pendingSellMarksUpdate then return end
	pendingSellMarksUpdate = true
	C_Timer.After(0.05, function()
		pendingSellMarksUpdate = false
		if not inventoryOpen() then return end
		if not sellMarksDirty and not pendingSellMarksReset then return end
		local doReset = pendingSellMarksReset
		pendingSellMarksReset = false
		performUpdateSellMarks(doReset)
		sellMarksDirty = false
	end)
end

AltClickHook = function(self, button)
	if not addon.db["vendorAltClickInclude"] then return end
	if not IsAltKeyDown() or not (button == "LeftButton" or button == "RightButton") then return end
	local bag, slot
	if self and self.GetSlotAndBagID then
		slot, bag = self:GetSlotAndBagID()
	else
		bag, slot = getBagSlotFromItemButton(self)
	end
	if type(bag) == "number" and slot and bag >= 0 and bag <= NUM_TOTAL_EQUIPPED_BAG_SLOTS then
		local eItem = Item:CreateFromBagAndSlot(bag, slot)
		if eItem and not eItem:IsItemEmpty() then
			eItem:ContinueOnItemLoad(function()
				local name = eItem:GetItemName()
				local id = eItem:GetItemID()
				if not name or not id then return end
				if button == "LeftButton" then
					local info = C_Container.GetContainerItemInfo(bag, slot)
					local shouldDestroy = info and info.hasNoValue
					if not shouldDestroy then
						local sellPrice = select(11, C_Item.GetItemInfo(eItem:GetItemLink()))
						if (sellPrice or 0) <= 0 then shouldDestroy = true end
					end
					if shouldDestroy then
						local reason = getDestroyProtectionReason(id, info)
						if reason then
							local linkText = eItem:GetItemLink() or name
							notifyDestroyProtection(id, linkText, reason)
							return
						end
						if not addon.db["vendorIncludeDestroyList"][id] then
							addon.db["vendorIncludeDestroyList"][id] = name
							if addon.db["vendorIncludeSellList"] then addon.db["vendorIncludeSellList"][id] = nil end
							print(string.format(L["vendorDestroyAdded"], name, id))
						end
					else
						if not addon.db["vendorIncludeSellList"][id] then
							addon.db["vendorIncludeSellList"][id] = name
							if addon.db["vendorIncludeDestroyList"] then addon.db["vendorIncludeDestroyList"][id] = nil end
							print(ADD .. ":", id, name)
							if MerchantFrame and MerchantFrame:IsShown() then
								hasMoreItems = true
								updateSellMoreButton()
							end
						end
					end
				elseif button == "RightButton" then
					if addon.db["vendorIncludeSellList"][id] then
						addon.db["vendorIncludeSellList"][id] = nil
						print(REMOVE .. ":", id, name)
					end
					if addon.db["vendorIncludeDestroyList"] and addon.db["vendorIncludeDestroyList"][id] then
						addon.db["vendorIncludeDestroyList"][id] = nil
						print(string.format(L["vendorDestroyRemoved"], name or ("Item #" .. tostring(id)), id))
					end
				end
				updateSellMarks(nil, true)
			end)
		end
	end
end

function addon.Vendor.functions.HandleItemButtonClick(self, button)
	if AltClickHook then AltClickHook(self, button) end
end

local function hookBagFrame(frame)
	if not frame then return end
	if frame._EnhanceQoLVendorDestroyHook then return end
	frame._EnhanceQoLVendorDestroyHook = true
	hooksecurefunc(frame, "UpdateItems", function(self) applySellDestroyOverlaysToFrame(self) end)
	frame:HookScript("OnShow", function()
		if destroyState.button and (not InCombatLockdown or not InCombatLockdown()) then anchorDestroyButton(destroyState.button) end
		updateSellMarks()
		if addon.db["vendorDestroyEnable"] then scheduleDestroyButtonUpdate() end
	end)
	frame:HookScript("OnHide", function() destroyHideList() end)
end

function addon.Vendor.functions.InitState()
	if addon.Vendor.variables.vendorInitialized then return end
	if not addon.db then return end
	addon.Vendor.variables.vendorInitialized = true

	registerEvents(frameLoad)
	frameLoad:SetScript("OnEvent", eventHandler)

	if _G.ContainerFrameItemButtonMixin then hooksecurefunc(_G.ContainerFrameItemButtonMixin, "OnModifiedClick", AltClickHook) end

	if ContainerFrameCombinedBags then hookBagFrame(ContainerFrameCombinedBags) end
	local frames = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames or {}
	for _, frame in ipairs(frames) do
		hookBagFrame(frame)
	end

	ensureBaganatorIntegration()

	-- ! STILL BUGGY 2026-01-25
	-- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
	-- 	if not addon.db or not addon.db["vendorShowSellTooltip"] then return end
	-- 	if not data or not tooltip.GetOwner then return end
	-- 	local oTooltip = tooltip.GetOwner and tooltip:GetOwner()
	-- 	if not oTooltip or not oTooltip.GetBagID or not oTooltip.GetID then return end
	-- 	local bagID = oTooltip:GetBagID()
	-- 	local slotIndex = oTooltip:GetID()
	-- 	if bagID and slotIndex then
	-- 		local key = bagID .. "_" .. slotIndex
	-- 		if sellMarkLookup[key] then
	-- 			tooltip:AddLine(L["vendorWillBeSold"], 1, 0, 0)
	-- 		elseif destroyMarkLookup[key] then
	-- 			tooltip:AddLine(L["vendorWillBeDestroyed"], 1, 0.3, 0.1)
	-- 		end
	-- 	end
	-- end)
end
