-- luacheck: globals C_Bank ACCOUNT_BANK_TITLE
local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

local CHARACTER_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Character or 0
local ACCOUNT_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Account or 2

local CHARACTER_BANK_TAB_START = Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 or 6
local CHARACTER_BANK_TAB_END = Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_6 or 11
local ACCOUNT_BANK_TAB_START = Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_1 or 12
local ACCOUNT_BANK_TAB_END = Enum and Enum.BagIndex and Enum.BagIndex.AccountBankTab_5 or 16

addon.Bags = addon.Bags or {}
addon.Bags.variables = addon.Bags.variables or {}

local state = addon.Bags.variables.bankViewState or {}
addon.Bags.variables.bankViewState = state
state.contextsByType = state.contextsByType or {}
state.visibleContexts = state.visibleContexts or {}

local function isBankTypeViewable(bankType)
	if not C_Bank then
		return false
	end

	if C_Bank.FetchViewableBankTypes then
		for _, viewableBankType in ipairs(C_Bank.FetchViewableBankTypes() or {}) do
			if viewableBankType == bankType then
				return true
			end
		end
	end

	if C_Bank.CanViewBank then
		return C_Bank.CanViewBank(bankType)
	end

	return false
end

local function addBankTabIDs(tabIDs, startBagID, endBagID)
	for bagID = startBagID, endBagID do
		if (C_Container.GetContainerNumSlots(bagID) or 0) > 0 then
			tabIDs[#tabIDs + 1] = bagID
		end
	end
end

local function canPurchaseBankTab(bankType)
	if not bankType or not C_Bank or not C_Bank.CanPurchaseBankTab or not C_Bank.HasMaxBankTabs then
		return false
	end

	return C_Bank.CanPurchaseBankTab(bankType) and not C_Bank.HasMaxBankTabs(bankType)
end

local function getPurchasedBankTabIDs(bankType, fallbackStartBagID, fallbackEndBagID)
	local tabIDs = {}
	local seen = {}

	if C_Bank and C_Bank.FetchPurchasedBankTabIDs then
		for _, bagID in ipairs(C_Bank.FetchPurchasedBankTabIDs(bankType) or {}) do
			if type(bagID) == "number" and not seen[bagID] and (C_Container.GetContainerNumSlots(bagID) or 0) > 0 then
				seen[bagID] = true
				tabIDs[#tabIDs + 1] = bagID
			end
		end
	end

	if #tabIDs == 0 then
		addBankTabIDs(tabIDs, fallbackStartBagID, fallbackEndBagID)
	end

	table.sort(tabIDs)
	return tabIDs
end

local function buildBankContextSignature(contextID, bagIDs)
	local parts = { tostring(contextID or "") }
	local totalSlotCount = 0

	for _, bagID in ipairs(bagIDs or {}) do
		local slotCount = C_Container.GetContainerNumSlots(bagID) or 0
		totalSlotCount = totalSlotCount + slotCount
		parts[#parts + 1] = string.format("%d:%d", bagID, slotCount)
	end

	return table.concat(parts, "|"), totalSlotCount
end

local function getContextCache(bankType)
	local cache = state.contextsByType[bankType]
	if not cache then
		cache = {}
		state.contextsByType[bankType] = cache
	end

	return cache
end

local function getCachedBankContext(bankType, contextID, label, color, columnCount, fallbackStartBagID, fallbackEndBagID)
	local canPurchaseTabs = canPurchaseBankTab(bankType)
	if not isBankTypeViewable(bankType) and not canPurchaseTabs then
		return nil
	end

	local bagIDs = getPurchasedBankTabIDs(bankType, fallbackStartBagID, fallbackEndBagID)
	if #bagIDs == 0 and not canPurchaseTabs then
		return nil
	end

	local signature, totalSlotCount = buildBankContextSignature(contextID, bagIDs)
	if canPurchaseTabs then
		signature = signature .. "|purchase"
	end
	local cache = getContextCache(bankType)
	local context = cache.context
	if context and context.signature == signature and context.label == label then
		return context
	end

	context = context or {}
	context.id = contextID
	context.label = label
	context.color = color
	context.columnCount = columnCount
	context.bagIDs = bagIDs
	context.signature = signature
	context.totalSlotCount = totalSlotCount
	context.canPurchaseTabs = canPurchaseTabs
	cache.context = context
	return context
end

function addon.AreAnyBankContextsViewable()
	return C_Bank and C_Bank.AreAnyBankTypesViewable and C_Bank.AreAnyBankTypesViewable() or false
end

function addon.IsCharacterBankViewable()
	return isBankTypeViewable(CHARACTER_BANK_TYPE)
end

function addon.IsWarbandBankViewable()
	return isBankTypeViewable(ACCOUNT_BANK_TYPE)
end

function addon.GetBankAnchorTargetFrame()
	if BankFrame and BankFrame:IsShown() then
		return BankFrame
	end

	if BankPanel and BankPanel:IsShown() then
		return BankPanel
	end

	return nil
end

function addon.GetVisibleFlatBankContexts()
	return addon.GetVisibleBankContexts and addon.GetVisibleBankContexts() or {}
end

function addon.GetVisibleCharacterBankContext()
	return getCachedBankContext(
		CHARACTER_BANK_TYPE,
		"characterBank",
		BANK or "Bank",
		{ 0.72, 0.82, 1 },
		18,
		CHARACTER_BANK_TAB_START,
		CHARACTER_BANK_TAB_END
	)
end

function addon.GetVisibleWarbandBankContext()
	return getCachedBankContext(
		ACCOUNT_BANK_TYPE,
		"accountBank",
		ACCOUNT_BANK_PANEL_TITLE or ACCOUNT_BANK_TITLE or "Warband Bank",
		{ 0.58, 0.92, 0.86 },
		18,
		ACCOUNT_BANK_TAB_START,
		ACCOUNT_BANK_TAB_END
	)
end

function addon.GetVisibleBankContexts()
	local contexts = state.visibleContexts
	for index = #contexts, 1, -1 do
		contexts[index] = nil
	end

	local characterContext = addon.GetVisibleCharacterBankContext and addon.GetVisibleCharacterBankContext()
	if characterContext then
		contexts[#contexts + 1] = characterContext
	end

	local warbandContext = addon.GetVisibleWarbandBankContext and addon.GetVisibleWarbandBankContext()
	if warbandContext then
		contexts[#contexts + 1] = warbandContext
	end

	return contexts
end
