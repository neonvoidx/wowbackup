local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CooldownPanels = addon.Aura.CooldownPanels
local Helper = CooldownPanels.helper or {}
local Api = Helper.Api or {}
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

CooldownPanels.CDMAuras = CooldownPanels.CDMAuras or {}
local CDMAuras = CooldownPanels.CDMAuras

local ENTRY_TYPE = "CDM_AURA"
local ICON_VIEWER = "BuffIconCooldownViewer"
local BAR_VIEWER = "BuffBarCooldownViewer"
local SOURCE_ICON = "icon"
local SOURCE_BAR = "bar"
local IMPORT_SOURCE_ICON = "BUFF_ICON"
local IMPORT_SOURCE_BAR = "BUFF_BAR"

local scanCache
local cooldownViewerInfoByID = {}
local spellNameByID = {}
local spellTextureByID = {}

local function isSecretValue(value)
	return Api.issecretvalue and Api.issecretvalue(value) or false
end

local function getPlainPositiveID(value)
	if value == nil or isSecretValue(value) then return nil end
	local numeric = tonumber(value)
	if not numeric or numeric <= 0 then return nil end
	return numeric
end

local function isValidCooldownID(value)
	if value == nil or isSecretValue(value) then return false end
	if type(value) == "number" then return value > 0 end
	if type(value) == "string" then return value ~= "" end
	return false
end

local function getCooldownKey(value)
	if not isValidCooldownID(value) then return nil end
	return tostring(value)
end

local function normalizeSourceType(value)
	if value == SOURCE_BAR then return SOURCE_BAR end
	return SOURCE_ICON
end

local function normalizeAlwaysShowMode(value, fallback)
	if CooldownPanels.NormalizeCDMAuraAlwaysShowMode then return CooldownPanels:NormalizeCDMAuraAlwaysShowMode(value, fallback) end
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == "SHOW" or mode == "DESATURATE" or mode == "DESATURATE_ACTIVE" or mode == "HIDE" or mode == "HIDE_DESATURATE_ACTIVE" then return mode end
	return fallback or "HIDE"
end

local function getImportSourceType(sourceKind)
	if sourceKind == IMPORT_SOURCE_BAR then return SOURCE_BAR end
	if sourceKind == IMPORT_SOURCE_ICON then return SOURCE_ICON end
	return nil
end

local function showErrorMessage(message)
	if UIErrorsFrame and message then UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2, 1) end
end

local function getSpellName(spellID)
	spellID = getPlainPositiveID(spellID)
	if not spellID then return nil end
	local cached = spellNameByID[spellID]
	if cached ~= nil then return cached ~= false and cached or nil end
	local name
	if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(spellID) end
	if (not name or name == "") and GetSpellInfo then name = GetSpellInfo(spellID) end
	spellNameByID[spellID] = name and name ~= "" and name or false
	return name and name ~= "" and name or nil
end

local function getSpellTexture(spellID)
	spellID = getPlainPositiveID(spellID)
	if not spellID then return nil end
	local cached = spellTextureByID[spellID]
	if cached ~= nil then return cached ~= false and cached or nil end
	local texture
	if C_Spell and C_Spell.GetSpellTexture then texture = C_Spell.GetSpellTexture(spellID) end
	if not texture and GetSpellTexture then texture = GetSpellTexture(spellID) end
	spellTextureByID[spellID] = texture or false
	return texture
end

local function getCooldownViewerInfo(cooldownID)
	local numericID = getPlainPositiveID(cooldownID)
	if not (numericID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo) then return nil end
	local cached = cooldownViewerInfoByID[numericID]
	if cached ~= nil then return cached ~= false and cached or nil end
	local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(numericID)
	cooldownViewerInfoByID[numericID] = info or false
	return info
end

local function getFirstSpellID(...)
	for index = 1, select("#", ...) do
		local spellID = getPlainPositiveID(select(index, ...))
		if spellID then return spellID end
	end
	return nil
end

local function getCooldownIDFromFrame(frame, sourceType)
	if not frame then return nil end
	local cooldownID = frame.cooldownID
	if not cooldownID and frame.cooldownInfo then cooldownID = frame.cooldownInfo.cooldownID end
	if not cooldownID and sourceType == SOURCE_BAR and frame.Icon then cooldownID = frame.Icon.cooldownID end
	if not isValidCooldownID(cooldownID) then return nil end
	return cooldownID
end

local function isUsableTexture(texture)
	if texture == nil or isSecretValue(texture) then return false end
	if type(texture) == "number" then return texture ~= 0 end
	if type(texture) == "string" then return texture ~= "" end
	return false
end

local function readFrameTexture(region)
	if not region then return nil end
	if region.GetTextureFileID then
		local ok, texture = pcall(region.GetTextureFileID, region)
		if ok and isUsableTexture(texture) then return texture end
	end
	if region.GetTexture then
		local ok, texture = pcall(region.GetTexture, region)
		if ok and isUsableTexture(texture) then return texture end
	end
	return nil
end

local function getFrameIconTexture(frame)
	if not frame then return nil end
	local texture = readFrameTexture(frame.Icon and frame.Icon.Icon)
	if not texture then texture = readFrameTexture(frame.Icon) end
	if not texture then texture = readFrameTexture(frame) end
	return texture
end

local function resolveSpellInfo(cooldownID, frame)
	local frameInfo = frame and frame.cooldownInfo or nil
	local apiInfo = getCooldownViewerInfo(cooldownID)
	local frameLinkedSpellIDs = frameInfo and frameInfo.linkedSpellIDs
	local apiLinkedSpellIDs = apiInfo and apiInfo.linkedSpellIDs
	local spellID = getFirstSpellID(
		frame and frame.auraSpellID,
		frameInfo and frameInfo.overrideTooltipSpellID,
		frameInfo and frameInfo.linkedSpellID,
		type(frameLinkedSpellIDs) == "table" and frameLinkedSpellIDs[1] or nil,
		frameInfo and frameInfo.overrideSpellID,
		frameInfo and frameInfo.spellID,
		apiInfo and apiInfo.overrideTooltipSpellID,
		apiInfo and apiInfo.linkedSpellID,
		type(apiLinkedSpellIDs) == "table" and apiLinkedSpellIDs[1] or nil,
		apiInfo and apiInfo.overrideSpellID,
		apiInfo and apiInfo.spellID
	)
	return spellID, getSpellName(spellID), getFrameIconTexture(frame) or getSpellTexture(spellID)
end

local function ensureScanInfo(scan, cooldownID)
	local key = getCooldownKey(cooldownID)
	if not key then return nil end
	local info = scan.byCooldownKey[key]
	if info then return info end
	info = {
		cooldownID = cooldownID,
		availableSources = {},
	}
	scan.byCooldownKey[key] = info
	scan.byCooldownID[cooldownID] = info
	return info
end

local function deriveScanInfo(info, frame, overwrite)
	if not info then return end
	if info.derived and not overwrite then return end
	local spellID, name, texture = resolveSpellInfo(info.cooldownID, frame)
	if spellID and (overwrite or not info.spellID) then info.spellID = spellID end
	if name and (overwrite or not info.buffName) then info.buffName = name end
	if texture and (overwrite or not info.iconTextureID) then info.iconTextureID = texture end
	info.spellID = getPlainPositiveID(info.spellID)
	info.buffName = info.buffName or getSpellName(info.spellID) or tostring(info.cooldownID)
	info.iconTextureID = info.iconTextureID or getSpellTexture(info.spellID) or Helper.PREVIEW_ICON
	info.sortName = string.lower(tostring(info.buffName or ""))
	info.derived = true
	if info.spellID then scanCache.bySpellID[info.spellID] = scanCache.bySpellID[info.spellID] or info end
end

local function seedCategory(scan, category, sourceType)
	if not (category and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet) then return false end
	local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(category, false)
	if type(cooldownIDs) ~= "table" then return false end
	local seeded = false
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = ensureScanInfo(scan, cooldownID)
		if info then
			seeded = true
			info.availableSources[sourceType] = true
			if sourceType == SOURCE_ICON or not info.sourceType then
				info.sourceType = sourceType
				info.sourceViewer = sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
			end
		end
	end
	return seeded
end

local function frameIsShown(frame)
	if not (frame and frame.IsShown) then return false end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and shown == true
end

local function shouldReplaceFrame(current, candidate)
	if current == candidate then return false end
	if not current then return true end
	if not candidate then return false end
	return frameIsShown(candidate) and not frameIsShown(current)
end

local function collectFrame(scan, frame, sourceType, viewerName, seenFrames)
	if not frame or seenFrames[frame] then return end
	local cooldownID = getCooldownIDFromFrame(frame, sourceType)
	if not cooldownID then return end
	seenFrames[frame] = true
	local key = getCooldownKey(cooldownID)
	local info = key and scan.byCooldownKey[key] or nil
	if not info then
		if scan.hasAuthoritativeSeed then return end
		info = ensureScanInfo(scan, cooldownID)
	end
	if not info then return end
	info.availableSources[sourceType] = true
	local replace
	if sourceType == SOURCE_ICON then
		replace = shouldReplaceFrame(info.iconFrame, frame)
		if replace then info.iconFrame = frame end
	else
		replace = shouldReplaceFrame(info.barFrame, frame)
		if replace then info.barFrame = frame end
	end
	if sourceType == SOURCE_ICON or not info.sourceType then
		info.sourceType = sourceType
		info.sourceViewer = viewerName
	end
	deriveScanInfo(info, frame, replace)
end

local function collectFramesFromContainer(scan, container, sourceType, viewerName, seenFrames)
	local children = container and container.layoutChildren
	if type(children) ~= "table" then return end
	if #children > 0 then
		for index = 1, #children do collectFrame(scan, children[index], sourceType, viewerName, seenFrames) end
		return
	end
	local numericKeys = {}
	for key in pairs(children) do if type(key) == "number" then numericKeys[#numericKeys + 1] = key end end
	table.sort(numericKeys)
	for _, key in ipairs(numericKeys) do collectFrame(scan, children[key], sourceType, viewerName, seenFrames) end
end

local function collectViewer(scan, viewerName, sourceType, seenFrames)
	local viewer = _G[viewerName]
	if not viewer then return end
	collectFramesFromContainer(scan, viewer.oldGridSettings, sourceType, viewerName, seenFrames)
end

local function sortTrackedBuffs(left, right)
	local leftName = tostring(left and (left.sortName or left.buffName) or "")
	local rightName = tostring(right and (right.sortName or right.buffName) or "")
	if leftName ~= rightName then return leftName < rightName end
	return tostring(left and left.cooldownID or "") < tostring(right and right.cooldownID or "")
end

function CDMAuras:InvalidateScan(clearCooldownViewerInfo)
	scanCache = nil
	if clearCooldownViewerInfo then wipe(cooldownViewerInfoByID) end
end

function CDMAuras:ScanTrackedBuffs(force)
	if not force and scanCache then return scanCache.list, scanCache.byCooldownID, scanCache.bySpellID, scanCache.byCooldownKey end
	local scan = {
		list = {},
		byCooldownID = {},
		byCooldownKey = {},
		bySpellID = {},
	}
	scanCache = scan
	local trackedBuffCategory = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory.TrackedBuff
	local trackedBarCategory = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory.TrackedBar
	if seedCategory(scan, trackedBuffCategory, SOURCE_ICON) then scan.hasAuthoritativeSeed = true end
	if seedCategory(scan, trackedBarCategory, SOURCE_BAR) then scan.hasAuthoritativeSeed = true end
	local seenFrames = {}
	collectViewer(scan, ICON_VIEWER, SOURCE_ICON, seenFrames)
	collectViewer(scan, BAR_VIEWER, SOURCE_BAR, seenFrames)
	for _, info in pairs(scan.byCooldownKey) do
		deriveScanInfo(info, info.iconFrame or info.barFrame, false)
		info.sourceType = normalizeSourceType(info.sourceType or (info.availableSources[SOURCE_ICON] and SOURCE_ICON or SOURCE_BAR))
		info.sourceViewer = info.sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
		scan.list[#scan.list + 1] = info
	end
	table.sort(scan.list, sortTrackedBuffs)
	return scan.list, scan.byCooldownID, scan.bySpellID, scan.byCooldownKey
end

-- This normalizer is intentionally kept as the first pass for saved pre-12.1
-- entries. CooldownPanels_AuraContainers then converts the stable Spell ID to
-- the native AuraSlot representation and removes the obsolete Cooldown ID.
function CDMAuras:NormalizeEntry(entry)
	if type(entry) ~= "table" then return end
	entry.type = ENTRY_TYPE
	if not isValidCooldownID(entry.cooldownID) then entry.cooldownID = nil end
	entry.spellID = getPlainPositiveID(entry.spellID)
	entry.buffName = type(entry.buffName) == "string" and entry.buffName or nil
	entry.iconTextureID = entry.iconTextureID or getSpellTexture(entry.spellID)
	entry.sourceType = normalizeSourceType(entry.sourceType)
	entry.sourceViewer = entry.sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
	local legacyAlwaysShow = entry.alwaysShow == true
	local hadExplicitMode = entry.cdmAuraAlwaysShowMode ~= nil
	if type(entry.cdmAuraAlwaysShowUseGlobal) ~= "boolean" then entry.cdmAuraAlwaysShowUseGlobal = not (legacyAlwaysShow or hadExplicitMode) end
	entry.cdmAuraAlwaysShowMode = normalizeAlwaysShowMode(entry.cdmAuraAlwaysShowMode, legacyAlwaysShow and "SHOW" or "HIDE")
	entry.alwaysShow = entry.cdmAuraAlwaysShowMode ~= "HIDE" and entry.cdmAuraAlwaysShowMode ~= "HIDE_DESATURATE_ACTIVE"
	entry.showCooldown = entry.showCooldown ~= false
	entry.showCooldownText = entry.showCooldownText ~= false
	entry.showStacks = entry.showStacks == true
	entry.showCharges = false
	entry.showItemCount = false
	entry.showItemUses = false
	entry.showWhenEmpty = false
	entry.showWhenNoCooldown = false
	entry.showWhenMissing = false
	entry.useHighestRank = false
	entry.glowReady = entry.glowReady == true
	entry.pandemicGlow = entry.pandemicGlow == true
	entry.soundReady = false
end

function CDMAuras:GetEntryIcon(entry)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end
	return entry.iconTextureID or getSpellTexture(entry.auraSpellID or entry.spellID) or Helper.PREVIEW_ICON
end

function CDMAuras:GetEntryName(entry)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end
	return entry.buffName or getSpellName(entry.auraSpellID or entry.spellID) or (L["CooldownPanelCDMAuraType"] or "Tracked Aura")
end

function CDMAuras:GetEntryTypeLabel(entryType)
	if entryType ~= ENTRY_TYPE then return nil end
	return L["CooldownPanelCDMAuraType"] or "Tracked Aura"
end

function CDMAuras:ApplyPreview(icon, entry)
	if not (icon and entry and entry.type == ENTRY_TYPE) then return end
	if entry.showStacks and icon.count then
		icon.count:SetText("2")
		icon.count:Show()
	end
end

function CDMAuras:GetImportSourceLabel(sourceKind)
	if sourceKind == IMPORT_SOURCE_BAR then return L["CooldownPanelImportCDMBuffBar"] or "Buff Bar" end
	if sourceKind == IMPORT_SOURCE_ICON then return L["CooldownPanelImportCDMBuffIcon"] or "Buff Icon" end
	return nil
end

local function getEntrySyncCooldownID(entry)
	if type(entry) ~= "table" then return nil end
	if isValidCooldownID(entry.cdmSyncCooldownID) then return entry.cdmSyncCooldownID end
	if entry.cdmSyncManaged == true and isValidCooldownID(entry.cdmSyncKey) then return entry.cdmSyncKey end
	if isValidCooldownID(entry.cooldownID) then return entry.cooldownID end
	return nil
end

function CDMAuras:ImportEntries(panelId, sourceKind)
	local sourceType = getImportSourceType(sourceKind)
	local sourceLabel = self:GetImportSourceLabel(sourceKind)
	if not sourceType then return nil, "SOURCE_NOT_FOUND", sourceLabel end
	local viewerName = sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
	if type(_G[viewerName]) ~= "table" then return nil, "SOURCE_NOT_FOUND", sourceLabel end
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId)
	if not panel then return nil, "PANEL_NOT_FOUND", sourceLabel end
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot()
	if not root then return nil, "NO_DB", sourceLabel end
	panel.entries = panel.entries or {}
	panel.order = panel.order or {}
	local existingByCooldownID = {}
	local existingBySpellID = {}
	for _, entry in pairs(panel.entries) do
		if entry and entry.type == ENTRY_TYPE then
			local cooldownKey = getCooldownKey(getEntrySyncCooldownID(entry))
			if cooldownKey then existingByCooldownID[cooldownKey] = true end
			local spellID = getPlainPositiveID(entry.auraSpellID or entry.spellID)
			if spellID then existingBySpellID[spellID] = true end
		end
	end
	local list = self:ScanTrackedBuffs(true)
	local stats = { added = 0, duplicates = 0, invalid = 0, seen = 0, sourceLabel = sourceLabel }
	for _, info in ipairs(list or {}) do
		local sourceFrame = info and (sourceType == SOURCE_ICON and info.iconFrame or info.barFrame)
		local spellID = info and getPlainPositiveID(info.spellID)
		if info and info.availableSources and info.availableSources[sourceType] and sourceFrame then
			stats.seen = stats.seen + 1
			local cooldownKey = getCooldownKey(info.cooldownID)
			if not cooldownKey or not spellID then
				stats.invalid = stats.invalid + 1
			elseif existingByCooldownID[cooldownKey] or existingBySpellID[spellID] then
				stats.duplicates = stats.duplicates + 1
			else
				local entryInfo = {
					cooldownID = info.cooldownID,
					spellID = spellID,
					buffName = info.buffName,
					iconTextureID = info.iconTextureID,
					sourceType = sourceType,
					sourceViewer = viewerName,
				}
				local entryId = Helper.GetNextNumericId(panel.entries)
				local entry = Helper.CreateEntry(ENTRY_TYPE, entryInfo, root.defaults)
				if entry and getPlainPositiveID(entry.auraSpellID or entry.spellID) then
					entry.id = entryId
					panel.entries[entryId] = entry
					panel.order[#panel.order + 1] = entryId
					existingByCooldownID[cooldownKey] = true
					existingBySpellID[spellID] = true
					stats.added = stats.added + 1
				else
					stats.invalid = stats.invalid + 1
				end
			end
		end
	end
	if stats.added > 0 then
		Helper.SyncOrder(panel.order, panel.entries)
		if CooldownPanels.RebuildSpellIndex then CooldownPanels:RebuildSpellIndex() end
		if CooldownPanels.RefreshPanel then CooldownPanels:RefreshPanel(panelId) end
	end
	return stats
end

function CDMAuras:SyncEntries(panelId, sourceKind)
	local sourceType = getImportSourceType(sourceKind)
	local sourceLabel = self:GetImportSourceLabel(sourceKind)
	if sourceType ~= SOURCE_ICON then return nil, "SOURCE_NOT_FOUND", sourceLabel end
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId)
	if not panel then return nil, "PANEL_NOT_FOUND", sourceLabel end
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot()
	if not root then return nil, "NO_DB", sourceLabel end
	panel.entries = panel.entries or {}
	panel.order = panel.order or {}
	local wantedByCooldownID = {}
	local wantedOrder = {}
	local stats = { added = 0, removed = 0, updated = 0, invalid = 0, seen = 0, sourceLabel = sourceLabel }
	local list = self:ScanTrackedBuffs(true)
	for _, info in ipairs(list or {}) do
		local spellID = info and getPlainPositiveID(info.spellID)
		local cooldownKey = info and getCooldownKey(info.cooldownID)
		if info and info.availableSources and info.availableSources[SOURCE_ICON] and info.iconFrame then
			stats.seen = stats.seen + 1
			if not cooldownKey or not spellID then
				stats.invalid = stats.invalid + 1
			elseif not wantedByCooldownID[cooldownKey] then
				wantedByCooldownID[cooldownKey] = {
					cooldownID = info.cooldownID,
					spellID = spellID,
					buffName = info.buffName,
					iconTextureID = info.iconTextureID,
					sourceType = SOURCE_ICON,
					sourceViewer = ICON_VIEWER,
				}
				wantedOrder[#wantedOrder + 1] = cooldownKey
			end
		end
	end
	local existingByCooldownID = {}
	local otherOrder = {}
	for _, entryId in ipairs(panel.order) do
		local entry = panel.entries[entryId]
		local cooldownKey = entry and entry.type == ENTRY_TYPE and getCooldownKey(getEntrySyncCooldownID(entry))
		if cooldownKey and wantedByCooldownID[cooldownKey] and not existingByCooldownID[cooldownKey] then
			existingByCooldownID[cooldownKey] = entryId
		elseif entry then
			otherOrder[#otherOrder + 1] = entryId
		end
	end
	for entryId, entry in pairs(panel.entries) do
		if entry and entry.cdmSyncManaged == true then
			local cooldownKey = entry.type == ENTRY_TYPE and getCooldownKey(getEntrySyncCooldownID(entry))
			if entry.cdmSyncSource ~= IMPORT_SOURCE_ICON or not (cooldownKey and wantedByCooldownID[cooldownKey]) then
				if CooldownPanels.SaveCooldownManagerSyncEntryOverride then
					CooldownPanels:SaveCooldownManagerSyncEntryOverride(panel, entry.cdmSyncSource or IMPORT_SOURCE_ICON, entry.cdmSyncKey or cooldownKey, entry)
				end
				panel.entries[entryId] = nil
				stats.removed = stats.removed + 1
			end
		end
	end
	for _, cooldownKey in ipairs(wantedOrder) do
		local entryId = existingByCooldownID[cooldownKey]
		local entryInfo = wantedByCooldownID[cooldownKey]
		local entry = entryId and panel.entries[entryId]
		local syncManaged = entry and entry.cdmSyncManaged == true or false
		if not entry then
			if CooldownPanels.GetFixedEntryAddError and CooldownPanels:GetFixedEntryAddError(panel, nil) then
				stats.invalid = stats.invalid + 1
			else
				entryId = Helper.GetNextNumericId(panel.entries)
				entry = Helper.CreateEntry(ENTRY_TYPE, entryInfo, root.defaults)
				if entry and getPlainPositiveID(entry.auraSpellID or entry.spellID) then
					entry.id = entryId
					if CooldownPanels.ApplyCooldownManagerSyncEntryOverride then
						CooldownPanels:ApplyCooldownManagerSyncEntryOverride(panel, IMPORT_SOURCE_ICON, cooldownKey, entry)
					end
					panel.entries[entryId] = entry
					existingByCooldownID[cooldownKey] = entryId
					syncManaged = true
					stats.added = stats.added + 1
				else
					entry = nil
					stats.invalid = stats.invalid + 1
				end
			end
		end
		if entry and syncManaged then
			entry.spellID = entryInfo.spellID
			entry.auraSpellID = entryInfo.spellID
			entry.buffName = entryInfo.buffName
			entry.iconTextureID = entryInfo.iconTextureID
			entry.sourceType = entryInfo.sourceType
			entry.sourceViewer = entryInfo.sourceViewer
			entry.cdmSyncManaged = true
			entry.cdmSyncSource = IMPORT_SOURCE_ICON
			entry.cdmSyncKey = cooldownKey
			entry.cdmSyncCooldownID = entryInfo.cooldownID
			stats.updated = stats.updated + 1
		end
	end
	local nextOrder = {}
	for _, cooldownKey in ipairs(wantedOrder) do
		local entryId = existingByCooldownID[cooldownKey]
		if entryId and panel.entries[entryId] then nextOrder[#nextOrder + 1] = entryId end
	end
	for _, entryId in ipairs(otherOrder) do if panel.entries[entryId] then nextOrder[#nextOrder + 1] = entryId end end
	panel.order = nextOrder
	Helper.SyncOrder(panel.order, panel.entries)
	Helper.InvalidateFixedLayoutCache(panel)
	if stats.added > 0 or stats.removed > 0 then
		if CooldownPanels.RebuildSpellIndex then CooldownPanels:RebuildSpellIndex() end
	end
	if CooldownPanels.RefreshPanel then CooldownPanels:RefreshPanel(panelId) end
	if CooldownPanels.BlizzardEditor and CooldownPanels.BlizzardEditor.RefreshPanel then CooldownPanels.BlizzardEditor:RefreshPanel(panelId) end
	return stats
end
