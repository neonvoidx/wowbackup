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
CDMAuras._eqolPerf = CDMAuras._eqolPerf or {}
local cdm = CDMAuras._eqolPerf

local ENTRY_TYPE = "CDM_AURA"
local ICON_VIEWER = "BuffIconCooldownViewer"
local BAR_VIEWER = "BuffBarCooldownViewer"
local SOURCE_ICON = "icon"
local SOURCE_BAR = "bar"
local IMPORT_SOURCE_ICON = "BUFF_ICON"
local IMPORT_SOURCE_BAR = "BUFF_BAR"
local RESHUFFLE_REFRESH_DELAY = 0.05
local WEAK_KEYS = { __mode = "k" }
local NO_SCAN_INFO = false

local function isSecretValue(value) return Api.issecretvalue and Api.issecretvalue(value) end

local function showErrorMessage(msg)
	if UIErrorsFrame and msg then UIErrorsFrame:AddMessage(msg, 1, 0.2, 0.2, 1) end
end

local function createTrackedUnitBuckets()
	return {
		player = {},
		target = {},
		unknown = {},
	}
end

local function normalizeTrackedUnit(unit)
	if unit == "player" or unit == "target" then return unit end
	return nil
end

function cdm.EnsureWeakKeyTable(value)
	if type(value) == "table" then return value end
	return setmetatable({}, WEAK_KEYS)
end

function cdm.GetFrameEpoch(runtime, frame)
	if not (runtime and frame) then return 0 end
	return tonumber(runtime.frameEpochByFrame and runtime.frameEpochByFrame[frame]) or 0
end

function cdm.BumpFrameEpoch(runtime, frame)
	if not (runtime and frame) then return 0 end
	runtime.frameEpochByFrame = cdm.EnsureWeakKeyTable(runtime.frameEpochByFrame)
	local nextEpoch = (tonumber(runtime.frameEpochByFrame[frame]) or 0) + 1
	runtime.frameEpochByFrame[frame] = nextEpoch
	if runtime.frameAuraSnapshotByFrame then runtime.frameAuraSnapshotByFrame[frame] = nil end
	return nextEpoch
end

function cdm.GetUnitAuraEpoch(runtime, unit)
	unit = normalizeTrackedUnit(unit)
	if not (runtime and unit) then return 0 end
	return tonumber(runtime.unitAuraEpoch and runtime.unitAuraEpoch[unit]) or 0
end

function cdm.BumpUnitAuraEpoch(runtime, unit)
	unit = normalizeTrackedUnit(unit)
	if not (runtime and unit) then return 0 end
	runtime.unitAuraEpoch = runtime.unitAuraEpoch or { player = 0, target = 0 }
	local nextEpoch = (tonumber(runtime.unitAuraEpoch[unit]) or 0) + 1
	runtime.unitAuraEpoch[unit] = nextEpoch
	return nextEpoch
end

function cdm.ResetPersistentFrameCaches(runtime)
	if not runtime then return end
	if type(runtime.frameEpochByFrame) == "table" then
		wipe(runtime.frameEpochByFrame)
	else
		runtime.frameEpochByFrame = cdm.EnsureWeakKeyTable(nil)
	end
	if type(runtime.frameAuraSnapshotByFrame) == "table" then
		wipe(runtime.frameAuraSnapshotByFrame)
	else
		runtime.frameAuraSnapshotByFrame = cdm.EnsureWeakKeyTable(nil)
	end
end

local function getRuntime()
	CooldownPanels.runtime = CooldownPanels.runtime or {}
	local runtime = CooldownPanels.runtime.cdmAuras
	if runtime then
		if not (runtime.auraEntries and runtime.auraEntries.player and runtime.auraEntries.target and runtime.auraEntries.unknown) then runtime.auraEntries = createTrackedUnitBuckets() end
		if not (runtime.unitPanels and runtime.unitPanels.player and runtime.unitPanels.target and runtime.unitPanels.unknown) then runtime.unitPanels = createTrackedUnitBuckets() end
		runtime.frameEntries = runtime.frameEntries or {}
		runtime.pandemicFrameEntries = runtime.pandemicFrameEntries or {}
		runtime.cooldownViewerInfoByID = runtime.cooldownViewerInfoByID or {}
		runtime.spellNameByID = runtime.spellNameByID or {}
		runtime.spellTextureByID = runtime.spellTextureByID or {}
		runtime.scanInfoPoolByID = runtime.scanInfoPoolByID or {}
		runtime.scratchSeenFrames = runtime.scratchSeenFrames or {}
		runtime.scratchSeenInfo = runtime.scratchSeenInfo or {}
		runtime.scratchNumericKeys = runtime.scratchNumericKeys or {}
		runtime.scratchChildren = runtime.scratchChildren or {}
		runtime.scratchRefreshedPanels = runtime.scratchRefreshedPanels or {}
		runtime.frameEpochByFrame = cdm.EnsureWeakKeyTable(runtime.frameEpochByFrame)
		runtime.frameAuraSnapshotByFrame = cdm.EnsureWeakKeyTable(runtime.frameAuraSnapshotByFrame)
		runtime.unitAuraEpoch = runtime.unitAuraEpoch or { player = 0, target = 0 }
		runtime.scanEpoch = tonumber(runtime.scanEpoch) or 0
		return runtime
	end
	runtime = {
		scan = nil,
		entryStates = {},
		auraEntries = createTrackedUnitBuckets(),
		unitPanels = createTrackedUnitBuckets(),
		frameEntries = {},
		pandemicFrameEntries = {},
		hookedFrames = {},
		cooldownViewerInfoByID = {},
		spellNameByID = {},
		spellTextureByID = {},
		scanInfoPoolByID = {},
		scratchSeenFrames = {},
		scratchSeenInfo = {},
		scratchNumericKeys = {},
		scratchChildren = {},
		scratchRefreshedPanels = {},
		frameEpochByFrame = cdm.EnsureWeakKeyTable(nil),
		frameAuraSnapshotByFrame = cdm.EnsureWeakKeyTable(nil),
		unitAuraEpoch = { player = 0, target = 0 },
		scanEpoch = 0,
		targetEpoch = 0,
	}
	CooldownPanels.runtime.cdmAuras = runtime
	return runtime
end

function CDMAuras:BeginRuntimePass()
	local runtime = getRuntime()
	local depth = (runtime.runtimePassDepth or 0) + 1
	runtime.runtimePassDepth = depth
	if depth == 1 then runtime.runtimePass = (runtime.runtimePass or 0) + 1 end
	return runtime.runtimePass
end

function CDMAuras:EndRuntimePass()
	local runtime = getRuntime()
	local depth = tonumber(runtime.runtimePassDepth) or 0
	if depth <= 1 then
		runtime.runtimePassDepth = nil
	else
		runtime.runtimePassDepth = depth - 1
	end
end

local function getRuntimePassCacheTable(field)
	local runtime = getRuntime()
	local pass = runtime.runtimePass
	if not pass then return nil, runtime end
	local passField = field .. "Pass"
	local cache = runtime[field]
	if type(cache) ~= "table" then
		cache = setmetatable({}, WEAK_KEYS)
		runtime[field] = cache
	end
	if runtime[passField] ~= pass then
		wipe(cache)
		runtime[passField] = pass
	end
	return cache, runtime
end

local function getEntryKey(panelId, entryId) return Helper.GetEntryKey(panelId, entryId) end

local function requestPanelRefresh(panelId)
	if not panelId then return end
	if CooldownPanels.RequestPanelRefresh then
		CooldownPanels:RequestPanelRefresh(panelId)
	elseif CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) and CooldownPanels.RefreshPanel then
		CooldownPanels:RefreshPanel(panelId)
	end
end

local function getPanelEntry(panelId, entryId)
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	local entry = panel and panel.entries and panel.entries[entryId] or nil
	return panel, entry
end

local function isValidCooldownID(value)
	if type(value) == "number" then return value > 0 end
	if type(value) == "string" then return value ~= "" end
	return false
end

local function getCooldownCacheKey(cooldownID)
	local valueType = type(cooldownID)
	if valueType == "number" then return cooldownID > 0 and cooldownID or nil end
	if valueType == "string" then return cooldownID ~= "" and cooldownID or nil end
	return nil
end

local function cooldownIDsEqual(a, b)
	if a == b then return true end
	if not (isValidCooldownID(a) and isValidCooldownID(b)) then return false end
	return tostring(a) == tostring(b)
end

local function normalizeSourceType(value)
	if value == SOURCE_BAR then return SOURCE_BAR end
	return SOURCE_ICON
end

local function normalizeAlwaysShowMode(value, fallback)
	if CooldownPanels and CooldownPanels.NormalizeCDMAuraAlwaysShowMode then return CooldownPanels:NormalizeCDMAuraAlwaysShowMode(value, fallback) end
	local mode = type(value) == "string" and string.upper(value) or nil
	if mode == "SHOW" or mode == "DESATURATE" or mode == "DESATURATE_ACTIVE" or mode == "HIDE" or mode == "HIDE_DESATURATE_ACTIVE" then return mode end
	return fallback or "HIDE"
end

local function getImportSourceType(sourceKind)
	if sourceKind == IMPORT_SOURCE_BAR then return SOURCE_BAR end
	if sourceKind == IMPORT_SOURCE_ICON then return SOURCE_ICON end
	return nil
end

local function hasAuraInstanceID(value) return type(value) == "number" and not isSecretValue(value) and value > 0 end

local function resolveAuraStackCount(auraUnit, auraInstanceID, applications)
	local displayCount = applications
	if auraUnit and auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount then
		local count = C_UnitAuras.GetAuraApplicationDisplayCount(auraUnit, auraInstanceID, 2, 1000)
		if count ~= nil then displayCount = count end
	end
	if displayCount == nil then return nil end
	if isSecretValue(displayCount) then return displayCount end
	if type(displayCount) == "number" then
		if displayCount > 1 then return tostring(displayCount) end
		return nil
	end
	if type(displayCount) == "string" and displayCount ~= "" then return displayCount end
	return nil
end

local function getSpellName(spellId)
	if not spellId then return nil end
	local runtime = getRuntime()
	local cached = runtime.spellNameByID[spellId]
	if cached ~= nil then return cached ~= false and cached or nil end
	if C_Spell and C_Spell.GetSpellName then
		local name = C_Spell.GetSpellName(spellId)
		if name and name ~= "" then
			runtime.spellNameByID[spellId] = name
			return name
		end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(spellId)
		if name and name ~= "" then
			runtime.spellNameByID[spellId] = name
			return name
		end
	end
	runtime.spellNameByID[spellId] = false
	return nil
end

local function getSpellTexture(spellId)
	if not spellId then return nil end
	local runtime = getRuntime()
	local cached = runtime.spellTextureByID[spellId]
	if cached ~= nil then return cached ~= false and cached or nil end
	if C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellId)
		if texture then
			runtime.spellTextureByID[spellId] = texture
			return texture
		end
	end
	if GetSpellTexture then
		local texture = GetSpellTexture(spellId)
		if texture then
			runtime.spellTextureByID[spellId] = texture
			return texture
		end
	end
	runtime.spellTextureByID[spellId] = false
	return nil
end

local isUsableSpellID
local refreshAllTrackedPanels

local function getAuraInstanceID(auraData)
	local auraInstanceID = auraData and auraData.auraInstanceID
	if not hasAuraInstanceID(auraInstanceID) then return nil end
	return auraInstanceID
end

local function getAuraDataByAuraInstanceIDCached(auraUnit, auraInstanceID)
	if not (auraUnit and hasAuraInstanceID(auraInstanceID) and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID) then return nil end
	local runtime = getRuntime()
	local pass = runtime.runtimePass
	if not pass then return C_UnitAuras.GetAuraDataByAuraInstanceID(auraUnit, auraInstanceID) end
	if runtime.runtimePassAuraDataByInstancePass ~= pass or type(runtime.runtimePassAuraDataByInstance) ~= "table" then
		runtime.runtimePassAuraDataByInstance = {}
		runtime.runtimePassAuraDataByInstancePass = pass
	end
	local cache = runtime.runtimePassAuraDataByInstance
	local cacheKey = tostring(auraUnit) .. "\031" .. tostring(auraInstanceID)
	local cached = cache[cacheKey]
	if cached ~= nil then return cached ~= false and cached or nil end
	local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(auraUnit, auraInstanceID)
	cache[cacheKey] = auraData or false
	return auraData
end

local function getCooldownIDFromFrame(frame, sourceType)
	if not frame then return nil end
	local cooldownID = frame.cooldownID
	if not cooldownID and frame.cooldownInfo then cooldownID = frame.cooldownInfo.cooldownID end
	if not cooldownID and sourceType == SOURCE_BAR and frame.Icon and frame.Icon.cooldownID then cooldownID = frame.Icon.cooldownID end
	if not isValidCooldownID(cooldownID) then return nil end
	return cooldownID
end

local function isUsableTexture(texture)
	if texture == nil then return false end
	local textureType = type(texture)
	if textureType ~= "number" and textureType ~= "string" then return false end
	if isSecretValue(texture) then return false end
	if textureType == "number" then return texture ~= 0 end
	return texture ~= ""
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
	local passCache = frame and getRuntimePassCacheTable("runtimePassFrameIconTexture") or nil
	if passCache then
		local cached = passCache[frame]
		if cached ~= nil then return cached ~= false and cached or nil end
	end
	if not frame then return nil end
	local texture = readFrameTexture(frame.Icon and frame.Icon.Icon)
	if not texture then texture = readFrameTexture(frame.Icon) end
	if not texture then texture = readFrameTexture(frame) end
	if passCache then passCache[frame] = texture or false end
	return texture
end

local function getFrameCooldownValues(frame)
	if not (frame and frame.GetCooldownValues) then return nil, nil, nil, nil end
	local ok, expirationTime, duration, timeMod, paused = pcall(frame.GetCooldownValues, frame)
	if not ok then return nil, nil, nil, nil end
	return expirationTime, duration, timeMod, paused
end

local function getFrameApplications(frame)
	if not (frame and frame.GetApplicationsText) then return nil end
	local ok, applications = pcall(frame.GetApplicationsText, frame)
	if not ok or applications == "" then return nil end
	return applications
end

local function readTotemDataSlot(totemData) return totemData and totemData.slot end

local function areValuesEqual(left, right) return left == right end

local function getTotemSlot(frame)
	if not frame then return nil end
	if frame.preferredTotemUpdateSlot then return frame.preferredTotemUpdateSlot end
	if frame.totemData then
		local ok, slot = pcall(readTotemDataSlot, frame.totemData)
		if ok then return slot end
	end
	return nil
end

local function getTotemDurationObject(frame)
	local passCache = frame and getRuntimePassCacheTable("runtimePassTotemDurationByFrame") or nil
	if passCache then
		local cached = passCache[frame]
		if cached ~= nil then return cached ~= false and cached or nil end
	end
	if not (frame and frame.totemData ~= nil and GetTotemDuration) then return nil end
	local slot = getTotemSlot(frame)
	if not slot then return nil end
	local ok, durationObject = pcall(GetTotemDuration, slot)
	if not ok then return nil end
	if passCache then passCache[frame] = durationObject or false end
	return durationObject
end

isUsableSpellID = function(value) return type(value) == "number" and not isSecretValue(value) and value > 0 end

local function getFirstUsableSpellID(...)
	for i = 1, select("#", ...) do
		local spellID = select(i, ...)
		if isUsableSpellID(spellID) then return spellID end
	end
	return nil
end

local function getCooldownViewerInfo(cooldownID)
	if not (type(cooldownID) == "number" and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo) then return nil end
	local runtime = getRuntime()
	local key = getCooldownCacheKey(cooldownID)
	if not key then return nil end
	local cached = runtime.cooldownViewerInfoByID[key]
	if cached ~= nil then return cached ~= false and cached or nil end
	local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
	runtime.cooldownViewerInfoByID[key] = info or false
	return info
end

local function getCooldownInfoIsKnown(cooldownID, frame)
	local frameInfo = frame and frame.cooldownInfo or nil
	if type(frameInfo) == "table" and type(frameInfo.isKnown) == "boolean" then return frameInfo.isKnown end
	local apiInfo = getCooldownViewerInfo(cooldownID)
	if type(apiInfo) == "table" and type(apiInfo.isKnown) == "boolean" then return apiInfo.isKnown end
	return nil
end

local function frameTrackedSpellMatchesCandidate(candidateSpellID, source, trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if not candidateSpellID then return false, sawAssociatedSpellID, sawSecretLinkedSpellID end
	sawAssociatedSpellID = true
	local ok, matches = pcall(areValuesEqual, candidateSpellID, trackedSpellID)
	if ok then return matches, sawAssociatedSpellID, sawSecretLinkedSpellID end
	if source == "linkedSpellID" then sawSecretLinkedSpellID = true end
	return false, sawAssociatedSpellID, sawSecretLinkedSpellID
end

local function frameTrackedSpellMatchesCooldownInfo(info, trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if not info then return false, sawAssociatedSpellID, sawSecretLinkedSpellID end
	local matched = false
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(info.linkedSpellID, "linkedSpellID", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then return true, sawAssociatedSpellID, sawSecretLinkedSpellID end
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID =
		frameTrackedSpellMatchesCandidate(info.overrideTooltipSpellID, "overrideTooltipSpellID", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then return true, sawAssociatedSpellID, sawSecretLinkedSpellID end
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(info.overrideSpellID, "overrideSpellID", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then return true, sawAssociatedSpellID, sawSecretLinkedSpellID end
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(info.spellID, "spellID", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then return true, sawAssociatedSpellID, sawSecretLinkedSpellID end
	local linkedSpellIDs = info.linkedSpellIDs
	if type(linkedSpellIDs) == "table" then
		for i = 1, #linkedSpellIDs do
			matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(linkedSpellIDs[i], "linkedSpellIDs", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
			if matched then return true, sawAssociatedSpellID, sawSecretLinkedSpellID end
		end
	end
	return false, sawAssociatedSpellID, sawSecretLinkedSpellID
end

local function resolveSpellFromCooldownID(cooldownID, frame)
	local spellID = nil
	local buffName = nil
	local iconTextureID

	local frameInfo = frame and frame.cooldownInfo or nil
	local apiInfo = getCooldownViewerInfo(cooldownID)
	if frameInfo or apiInfo then
		local auraSpellID = frame and frame.auraSpellID or nil
		local frameLinkedSpellIDs = frameInfo and frameInfo.linkedSpellIDs or nil
		local apiLinkedSpellIDs = apiInfo and apiInfo.linkedSpellIDs or nil
		local frameFirstLinkedSpellID = type(frameLinkedSpellIDs) == "table" and frameLinkedSpellIDs[1] or nil
		local apiFirstLinkedSpellID = type(apiLinkedSpellIDs) == "table" and apiLinkedSpellIDs[1] or nil
		local frameLinkedSpellID = frameInfo and frameInfo.linkedSpellID or nil
		local apiLinkedSpellID = apiInfo and apiInfo.linkedSpellID or nil
		local frameOverrideTooltipSpellID = frameInfo and frameInfo.overrideTooltipSpellID or nil
		local apiOverrideTooltipSpellID = apiInfo and apiInfo.overrideTooltipSpellID or nil
		local frameOverrideSpellID = frameInfo and frameInfo.overrideSpellID or nil
		local apiOverrideSpellID = apiInfo and apiInfo.overrideSpellID or nil
		local frameBaseSpellID = frameInfo and frameInfo.spellID or nil
		local apiBaseSpellID = apiInfo and apiInfo.spellID or nil

		spellID = getFirstUsableSpellID(
			auraSpellID,
			frameOverrideTooltipSpellID,
			frameLinkedSpellID,
			frameFirstLinkedSpellID,
			frameOverrideSpellID,
			frameBaseSpellID,
			apiOverrideTooltipSpellID,
			apiLinkedSpellID,
			apiFirstLinkedSpellID,
			apiOverrideSpellID,
			apiBaseSpellID
		)

		local nameSpellID = getFirstUsableSpellID(
			auraSpellID,
			frameOverrideTooltipSpellID,
			frameLinkedSpellID,
			frameFirstLinkedSpellID,
			spellID,
			frameOverrideSpellID,
			frameBaseSpellID,
			apiOverrideTooltipSpellID,
			apiLinkedSpellID,
			apiFirstLinkedSpellID,
			apiOverrideSpellID,
			apiBaseSpellID
		)
		if nameSpellID then buffName = getSpellName(nameSpellID) end

		iconTextureID = getFrameIconTexture(frame)
		if not iconTextureID and isUsableSpellID(frameOverrideTooltipSpellID) then iconTextureID = getSpellTexture(frameOverrideTooltipSpellID) end
		if not iconTextureID and isUsableSpellID(apiOverrideTooltipSpellID) then iconTextureID = getSpellTexture(apiOverrideTooltipSpellID) end
		if not iconTextureID and isUsableSpellID(auraSpellID) then iconTextureID = getSpellTexture(auraSpellID) end
		if not iconTextureID and isUsableSpellID(frameLinkedSpellID) then iconTextureID = getSpellTexture(frameLinkedSpellID) end
		if not iconTextureID and isUsableSpellID(frameFirstLinkedSpellID) then iconTextureID = getSpellTexture(frameFirstLinkedSpellID) end
		if not iconTextureID and isUsableSpellID(spellID) then iconTextureID = getSpellTexture(spellID) end
		if not iconTextureID and isUsableSpellID(frameOverrideSpellID) then iconTextureID = getSpellTexture(frameOverrideSpellID) end
		if not iconTextureID and isUsableSpellID(frameBaseSpellID) then iconTextureID = getSpellTexture(frameBaseSpellID) end
		if not iconTextureID and isUsableSpellID(apiLinkedSpellID) then iconTextureID = getSpellTexture(apiLinkedSpellID) end
		if not iconTextureID and isUsableSpellID(apiFirstLinkedSpellID) then iconTextureID = getSpellTexture(apiFirstLinkedSpellID) end
		if not iconTextureID and isUsableSpellID(apiOverrideSpellID) then iconTextureID = getSpellTexture(apiOverrideSpellID) end
		if not iconTextureID and isUsableSpellID(apiBaseSpellID) then iconTextureID = getSpellTexture(apiBaseSpellID) end

		if not buffName and isUsableSpellID(frameOverrideTooltipSpellID) then buffName = getSpellName(frameOverrideTooltipSpellID) end
		if not buffName and isUsableSpellID(apiOverrideTooltipSpellID) then buffName = getSpellName(apiOverrideTooltipSpellID) end
		if not buffName and isUsableSpellID(frameOverrideSpellID) then buffName = getSpellName(frameOverrideSpellID) end
		if not buffName and isUsableSpellID(frameBaseSpellID) then buffName = getSpellName(frameBaseSpellID) end
		if not buffName and isUsableSpellID(apiOverrideSpellID) then buffName = getSpellName(apiOverrideSpellID) end
		if not buffName and isUsableSpellID(apiBaseSpellID) then buffName = getSpellName(apiBaseSpellID) end
	end

	iconTextureID = iconTextureID or getFrameIconTexture(frame)
	return spellID, buffName, iconTextureID
end

local ensureScanInfoDerived
local ensureScanInfoSpellLookup
local rememberScanInfoSpellLookup

local function resolveEntryScanInfo(entry, byCooldownID, bySpellID, byCooldownKey)
	if type(entry) ~= "table" then return nil, nil end

	local storedCooldownID = isValidCooldownID(entry.cooldownID) and entry.cooldownID or nil
	local storedCooldownKey = getCooldownCacheKey(storedCooldownID)
	local scanInfo = storedCooldownID and byCooldownID and byCooldownID[storedCooldownID] or nil
	if not scanInfo and storedCooldownKey and byCooldownKey then
		scanInfo = byCooldownKey[storedCooldownKey]
		if not scanInfo and type(storedCooldownKey) == "string" then scanInfo = byCooldownKey[tonumber(storedCooldownKey)] end
	end
	if scanInfo then
		local resolvedCooldownID = isValidCooldownID(scanInfo.cooldownID) and scanInfo.cooldownID or storedCooldownID
		return scanInfo, resolvedCooldownID
	end

	local spellID = tonumber(entry.spellID)
	if isUsableSpellID(spellID) and bySpellID then
		local spellInfo = bySpellID[spellID]
		if type(spellInfo) == "table" then
			local resolvedCooldownID = isValidCooldownID(spellInfo.cooldownID) and spellInfo.cooldownID or storedCooldownID
			return spellInfo, resolvedCooldownID
		end
	end

	return nil, storedCooldownID
end

local function findRuntimeScanInfoBySpellID(scan, spellID)
	spellID = tonumber(spellID)
	if not (scan and isUsableSpellID(spellID)) then return nil, nil end
	local bySpellID = scan.bySpellID
	local cached = bySpellID and bySpellID[spellID] or nil
	if type(cached) == "table" then
		local resolvedCooldownID = isValidCooldownID(cached.cooldownID) and cached.cooldownID or nil
		return cached, resolvedCooldownID
	end
	local list = scan.list
	if type(list) ~= "table" then return nil, nil end
	local startIndex = cached == false and 1 or ((tonumber(scan.spellLookupCursor) or 0) + 1)
	if scan.spellLookupComplete == true then startIndex = 1 end
	for i = startIndex, #list do
		if scan.spellLookupComplete ~= true and cached ~= false then scan.spellLookupCursor = i end
		local info = list[i]
		local cooldownID = info and info.cooldownID or nil
		if isValidCooldownID(cooldownID) then
			ensureScanInfoSpellLookup(scan, info, cooldownID)
			local matched = bySpellID and bySpellID[spellID] or nil
			if type(matched) == "table" then
				local resolvedCooldownID = isValidCooldownID(matched.cooldownID) and matched.cooldownID or cooldownID
				return matched, resolvedCooldownID
			end
			local frame = info.iconFrame or info.barFrame
			local sawAssociatedSpellID = false
			local sawSecretLinkedSpellID = false
			local directMatched
			directMatched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(frame and frame.auraSpellID, "auraSpellID", spellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
			if not directMatched then directMatched = frameTrackedSpellMatchesCooldownInfo(frame and frame.cooldownInfo, spellID, sawAssociatedSpellID, sawSecretLinkedSpellID) end
			if not directMatched then directMatched = frameTrackedSpellMatchesCooldownInfo(getCooldownViewerInfo(cooldownID), spellID, sawAssociatedSpellID, sawSecretLinkedSpellID) end
			if directMatched then
				if bySpellID then bySpellID[spellID] = info end
				return info, cooldownID
			end
		end
	end
	if cached ~= false then scan.spellLookupComplete = true end
	if bySpellID and bySpellID[spellID] == nil then bySpellID[spellID] = false end
	return nil, nil
end

local function resolveRuntimeEntryScanInfo(entry, scan, byCooldownID, byCooldownKey)
	local scanInfo, resolvedCooldownID = resolveEntryScanInfo(entry, byCooldownID, nil, byCooldownKey)
	if scanInfo then return scanInfo, resolvedCooldownID end
	local spellID = tonumber(entry and entry.spellID)
	local trackedSpellIDs = CooldownPanels.runtime and CooldownPanels.runtime.cdmAuraSpellIds or nil
	if isUsableSpellID(spellID) and (not trackedSpellIDs or trackedSpellIDs[spellID] == true) then
		local spellInfo, spellCooldownID = findRuntimeScanInfoBySpellID(scan, spellID)
		if spellInfo then return spellInfo, spellCooldownID or resolvedCooldownID end
	end
	return nil, resolvedCooldownID
end

local function getScanInfoMatchingFrame(scanInfo, preferredSource, expectedCooldownID)
	if not (scanInfo and isValidCooldownID(expectedCooldownID)) then return nil, nil end
	preferredSource = normalizeSourceType(preferredSource)

	local preferredFrame = preferredSource == SOURCE_BAR and scanInfo.barFrame or scanInfo.iconFrame
	if preferredFrame and cooldownIDsEqual(getCooldownIDFromFrame(preferredFrame, preferredSource), expectedCooldownID) then
		return preferredFrame, preferredSource
	end

	local fallbackSource = preferredSource == SOURCE_BAR and SOURCE_ICON or SOURCE_BAR
	local fallbackFrame = fallbackSource == SOURCE_BAR and scanInfo.barFrame or scanInfo.iconFrame
	if fallbackFrame and cooldownIDsEqual(getCooldownIDFromFrame(fallbackFrame, fallbackSource), expectedCooldownID) then
		return fallbackFrame, fallbackSource
	end

	return nil, nil
end

local function scanInfoHasOnlyMismatchedFrames(scanInfo, preferredSource, expectedCooldownID)
	if not (scanInfo and isValidCooldownID(expectedCooldownID)) then return false end
	local hasAnyFrame = scanInfo.iconFrame ~= nil or scanInfo.barFrame ~= nil
	if not hasAnyFrame then return false end
	local matchingFrame = getScanInfoMatchingFrame(scanInfo, preferredSource, expectedCooldownID)
	return matchingFrame == nil
end

local function selectScanInfoFrame(scanInfo, preferredSource, expectedCooldownID)
	preferredSource = normalizeSourceType(preferredSource)

	local preferredFrame = preferredSource == SOURCE_BAR and scanInfo and scanInfo.barFrame or scanInfo and scanInfo.iconFrame or nil
	local fallbackFrame = preferredSource == SOURCE_BAR and scanInfo and scanInfo.iconFrame or scanInfo and scanInfo.barFrame or nil
	local chosenFrame = preferredFrame
	local chosenSource = preferredSource

	if chosenFrame and not cooldownIDsEqual(getCooldownIDFromFrame(chosenFrame, chosenSource), expectedCooldownID) then chosenFrame = nil end
	if not chosenFrame and fallbackFrame then
		local fallbackSource = preferredSource == SOURCE_BAR and SOURCE_ICON or SOURCE_BAR
		if cooldownIDsEqual(getCooldownIDFromFrame(fallbackFrame, fallbackSource), expectedCooldownID) then
			chosenFrame = fallbackFrame
			chosenSource = fallbackSource
		end
	end

	return chosenFrame, chosenSource, preferredFrame, fallbackFrame
end

local function ensureScanInfo(scan, cooldownID)
	local info = scan.byCooldownID[cooldownID]
	if info then return info end
	local runtime = getRuntime()
	local key = getCooldownCacheKey(cooldownID) or cooldownID
	info = runtime.scanInfoPoolByID[key]
	if not info then
		info = { availableSources = {} }
		runtime.scanInfoPoolByID[key] = info
	end
	info.cooldownID = cooldownID
	wipe(info.availableSources)
	info.sourceType = nil
	info.sourceViewer = nil
	info.iconFrame = nil
	info.barFrame = nil
	info.spellID = nil
	info.buffName = nil
	info.iconTextureID = nil
	info.isActive = false
	info.isKnown = nil
	info.auraUnit = nil
	info.sortName = nil
	info.derived = nil
	scan.byCooldownID[cooldownID] = info
	return info
end

local function mergeResolvedScanInfo(info, spellID, buffName, iconTextureID, overwrite)
	if spellID and (overwrite or not info.spellID) then info.spellID = spellID end
	if buffName and buffName ~= "" and (overwrite or not info.buffName or info.buffName == "") then info.buffName = buffName end
	if iconTextureID and (overwrite or not info.iconTextureID) then info.iconTextureID = iconTextureID end
end

local function populateScanInfoDerivedFields(info, cooldownID, frame, overwrite)
	if not (info and isValidCooldownID(cooldownID)) then return end
	local isKnown = getCooldownInfoIsKnown(cooldownID, frame)
	if isKnown ~= nil and (overwrite or info.isKnown == nil) then info.isKnown = isKnown end
	if not overwrite and info.spellID and info.buffName and info.iconTextureID then return end
	local spellID, buffName, iconTextureID = resolveSpellFromCooldownID(cooldownID, frame)
	mergeResolvedScanInfo(info, spellID, buffName, iconTextureID, overwrite)
end

ensureScanInfoDerived = function(info, cooldownID, frame, overwrite, runtimeOnly)
	if not (info and isValidCooldownID(cooldownID)) then return end
	if info.derived == true and not overwrite then return end
	populateScanInfoDerivedFields(info, cooldownID, frame, overwrite)
	info.spellID = tonumber(info.spellID)
	info.buffName = info.buffName or getSpellName(info.spellID) or tostring(cooldownID)
	info.iconTextureID = info.iconTextureID or getSpellTexture(info.spellID) or Helper.PREVIEW_ICON
	if not runtimeOnly then info.sortName = string.lower(tostring(info.buffName or "")) end
	info.derived = true
end

local function resolveSpellIDOnlyFromCooldownID(cooldownID, frame)
	local frameInfo = frame and frame.cooldownInfo or nil
	local auraSpellID = frame and frame.auraSpellID or nil
	if isUsableSpellID(auraSpellID) then return auraSpellID end
	if type(frameInfo) == "table" then
		local linkedSpellIDs = frameInfo.linkedSpellIDs
		local firstLinkedSpellID = type(linkedSpellIDs) == "table" and linkedSpellIDs[1] or nil
		local spellID = getFirstUsableSpellID(
			frameInfo.overrideTooltipSpellID,
			frameInfo.linkedSpellID,
			firstLinkedSpellID,
			frameInfo.overrideSpellID,
			frameInfo.spellID
		)
		if isUsableSpellID(spellID) then return spellID end
	end
	local apiInfo = getCooldownViewerInfo(cooldownID)
	if type(apiInfo) == "table" then
		local linkedSpellIDs = apiInfo.linkedSpellIDs
		local firstLinkedSpellID = type(linkedSpellIDs) == "table" and linkedSpellIDs[1] or nil
		return getFirstUsableSpellID(
			apiInfo.overrideTooltipSpellID,
			apiInfo.linkedSpellID,
			firstLinkedSpellID,
			apiInfo.overrideSpellID,
			apiInfo.spellID
		)
	end
	return nil
end

ensureScanInfoSpellLookup = function(scan, info, cooldownID)
	if not (scan and info and isValidCooldownID(cooldownID)) then return nil end
	local spellID = tonumber(info.spellID)
	if not isUsableSpellID(spellID) then
		spellID = resolveSpellIDOnlyFromCooldownID(cooldownID, info.iconFrame or info.barFrame)
		if isUsableSpellID(spellID) then info.spellID = spellID end
	end
	if isUsableSpellID(spellID) then
		rememberScanInfoSpellLookup(scan, info)
		return spellID
	end
	return nil
end

local function frameHasActiveAuraOrTotem(frame)
	if not frame then return false end
	return hasAuraInstanceID(frame.auraInstanceID) or frame.totemData ~= nil
end

local function frameIsShown(frame)
	if not (frame and frame.IsShown) then return false end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and shown == true
end

local function shouldPreferCollectedFrame(existingFrame, candidateFrame)
	if candidateFrame == existingFrame then return false end
	if not existingFrame then return true end
	if not candidateFrame then return false end

	local existingActive = frameHasActiveAuraOrTotem(existingFrame)
	local candidateActive = frameHasActiveAuraOrTotem(candidateFrame)
	if existingActive ~= candidateActive then return candidateActive end

	local existingShown = frameIsShown(existingFrame)
	local candidateShown = frameIsShown(candidateFrame)
	if existingShown ~= candidateShown then return candidateShown end

	return false
end

local function shouldPreferSpellLookupInfo(primary, candidate)
	if not primary then return true end
	local primaryActive = primary.isActive == true
	local candidateActive = candidate.isActive == true
	if primaryActive ~= candidateActive then return candidateActive end
	local primaryIcon = primary.sourceType == SOURCE_ICON
	local candidateIcon = candidate.sourceType == SOURCE_ICON
	if primaryIcon ~= candidateIcon then return candidateIcon end
	local primaryFrame = primary.iconFrame or primary.barFrame
	local candidateFrame = candidate.iconFrame or candidate.barFrame
	if (primaryFrame ~= nil) ~= (candidateFrame ~= nil) then return candidateFrame ~= nil end
	local primaryAura = primary.auraUnit ~= nil
	local candidateAura = candidate.auraUnit ~= nil
	if primaryAura ~= candidateAura then return candidateAura end
	return tostring(candidate.cooldownID or "") < tostring(primary.cooldownID or "")
end

rememberScanInfoSpellLookup = function(scan, info)
	local spellID = tonumber(info and info.spellID)
	if not isUsableSpellID(spellID) then return end
	local trackedSpellIDs = scan and scan.runtimeMode and CooldownPanels.runtime and CooldownPanels.runtime.cdmAuraSpellIds or nil
	if trackedSpellIDs and trackedSpellIDs[spellID] ~= true then return end
	local current = scan.bySpellID[spellID]
	if current == nil or shouldPreferSpellLookupInfo(current, info) then scan.bySpellID[spellID] = info end
end

local function captureValues(buffer, ...)
	wipe(buffer)
	local count = select("#", ...)
	for i = 1, count do
		buffer[i] = select(i, ...)
	end
	return buffer, count
end

local function seedScanFromCategorySet(scan, category, sourceType)
	if not (scan and category and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCategorySet) then return false end
	local ok, cooldownIDs = pcall(C_CooldownViewer.GetCooldownViewerCategorySet, category, true)
	if not ok or type(cooldownIDs) ~= "table" then return false end
	local seeded = false
	for _, cooldownID in ipairs(cooldownIDs) do
		if isValidCooldownID(cooldownID) then
			seeded = true
			local info = ensureScanInfo(scan, cooldownID)
			info.availableSources[sourceType] = true
			if sourceType == SOURCE_ICON or not info.sourceType then
				info.sourceType = sourceType
				info.sourceViewer = sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
			end
		end
	end
	return seeded
end

local function collectFrame(scan, frame, sourceType, viewerName, seenFrames)
	if not frame or seenFrames[frame] then return end
	local cooldownID = getCooldownIDFromFrame(frame, sourceType)
	if not cooldownID then return end
	seenFrames[frame] = true
	frame._eqolLastTrackedCooldownID = cooldownID

	local info = scan.byCooldownID[cooldownID]
	if not info then
		if scan.hasAuthoritativeSeed then return end
		info = ensureScanInfo(scan, cooldownID)
	end
	info.availableSources[sourceType] = true
	local replaceFrame = false
	if sourceType == SOURCE_ICON then
		replaceFrame = shouldPreferCollectedFrame(info.iconFrame, frame)
		if replaceFrame then info.iconFrame = frame end
	else
		replaceFrame = shouldPreferCollectedFrame(info.barFrame, frame)
		if replaceFrame then info.barFrame = frame end
	end
	if sourceType == SOURCE_ICON or not info.sourceType then
		info.sourceType = sourceType
		info.sourceViewer = viewerName
	end
	local auraUnit = nil
	if type(frame.GetAuraDataUnit) == "function" then
		local ok, frameAuraUnit = pcall(frame.GetAuraDataUnit, frame)
		if ok then auraUnit = normalizeTrackedUnit(frameAuraUnit) end
	end
	if not auraUnit then auraUnit = normalizeTrackedUnit(frame.auraDataUnit) end
	if auraUnit and not info.auraUnit then info.auraUnit = auraUnit end

		if not scan.runtimeMode then ensureScanInfoDerived(info, cooldownID, frame, replaceFrame) end
		if frameHasActiveAuraOrTotem(frame) then info.isActive = true end
	end

local function collectFramesFromContainer(scan, container, sourceType, viewerName, seenFrames)
	if not container then return end
	if container.GetChildren then
		local children, childCount = captureValues(getRuntime().scratchChildren, container:GetChildren())
		for i = 1, childCount do
			collectFrame(scan, children[i], sourceType, viewerName, seenFrames)
		end
	end

	local layoutChildren = container.layoutChildren
	if type(layoutChildren) == "table" then
		if #layoutChildren > 0 then
			for i = 1, #layoutChildren do
				collectFrame(scan, layoutChildren[i], sourceType, viewerName, seenFrames)
			end
		else
			local numericKeys = getRuntime().scratchNumericKeys
			wipe(numericKeys)
			for key in pairs(layoutChildren) do
				if type(key) == "number" then numericKeys[#numericKeys + 1] = key end
			end
			table.sort(numericKeys)
			for _, key in ipairs(numericKeys) do
				collectFrame(scan, layoutChildren[key], sourceType, viewerName, seenFrames)
			end
		end
	end
end

local function collectViewer(scan, viewerName, sourceType, seenFrames)
	local viewer = _G[viewerName]
	if not viewer then return end
	collectFramesFromContainer(scan, viewer, sourceType, viewerName, seenFrames)
	collectFramesFromContainer(scan, viewer.oldGridSettings, sourceType, viewerName, seenFrames)
	collectFramesFromContainer(scan, viewer.gridSettings, sourceType, viewerName, seenFrames)
	collectFramesFromContainer(scan, viewer.currentGridSettings, sourceType, viewerName, seenFrames)
	collectFramesFromContainer(scan, viewer.settings, sourceType, viewerName, seenFrames)
end

local function sortTrackedBuffs(a, b)
	local leftName = tostring(a and (a.sortName or a.buffName) or "")
	local rightName = tostring(b and (b.sortName or b.buffName) or "")
	if leftName ~= rightName then return leftName < rightName end
	return tostring(a and a.cooldownID or "") < tostring(b and b.cooldownID or "")
end

function CDMAuras:InvalidateScan(clearCooldownViewerInfo, reason)
	local runtime = getRuntime()
	runtime.scan = nil
	runtime.forcedRescanEpoch = nil
	runtime.scanEpoch = (tonumber(runtime.scanEpoch) or 0) + 1
	if clearCooldownViewerInfo then wipe(runtime.cooldownViewerInfoByID) end
end

function CDMAuras:ScanTrackedBuffs(force, mode)
	local runtime = getRuntime()
	local runtimeMode = mode == "runtime"
	if not force and runtime.scan and runtime.scan.list and runtime.scan.byCooldownID then
		if runtimeMode or runtime.scan.fullDerived == true then return runtime.scan.list, runtime.scan.byCooldownID, runtime.scan.bySpellID, runtime.scan.byCooldownKey end
	end

	local scan = runtime.scan or {}
	scan.list = scan.list or {}
	scan.byCooldownID = scan.byCooldownID or {}
	scan.byCooldownKey = scan.byCooldownKey or {}
	scan.bySpellID = scan.bySpellID or {}
	wipe(scan.list)
	wipe(scan.byCooldownID)
	wipe(scan.byCooldownKey)
	wipe(scan.bySpellID)
	scan.hasAuthoritativeSeed = false
	scan.runtimeMode = runtimeMode
	scan.fullDerived = false
	scan.sorted = false
	scan.spellLookupCursor = 0
	scan.spellLookupComplete = false
	local seenFrames = runtime.scratchSeenFrames
	local seenInfo = runtime.scratchSeenInfo
	wipe(seenFrames)
	wipe(seenInfo)

	local trackedBuffCategory = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory.TrackedBuff or nil
	local trackedBarCategory = Enum and Enum.CooldownViewerCategory and Enum.CooldownViewerCategory.TrackedBar or nil
	if seedScanFromCategorySet(scan, trackedBuffCategory, SOURCE_ICON) then scan.hasAuthoritativeSeed = true end
	if seedScanFromCategorySet(scan, trackedBarCategory, SOURCE_BAR) then scan.hasAuthoritativeSeed = true end

	collectViewer(scan, ICON_VIEWER, SOURCE_ICON, seenFrames)
	collectViewer(scan, BAR_VIEWER, SOURCE_BAR, seenFrames)

	for cooldownID, info in pairs(scan.byCooldownID) do
		if not seenInfo[info] then
			seenInfo[info] = true
			if not runtimeMode then ensureScanInfoDerived(info, cooldownID, info.iconFrame or info.barFrame, false) end
			info.sourceType = normalizeSourceType(info.sourceType or (info.availableSources[SOURCE_ICON] and SOURCE_ICON or SOURCE_BAR))
			info.sourceViewer = info.sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
			local cooldownKey = getCooldownCacheKey(info.cooldownID or cooldownID)
			if cooldownKey then scan.byCooldownKey[cooldownKey] = info end
			if not runtimeMode then rememberScanInfoSpellLookup(scan, info) end
			scan.list[#scan.list + 1] = info
		end
	end

	if not runtimeMode then
		table.sort(scan.list, sortTrackedBuffs)
		scan.sorted = true
		scan.fullDerived = true
	end
	runtime.scan = scan
	return scan.list, scan.byCooldownID, scan.bySpellID, scan.byCooldownKey
end

local function clearAuraMapping(runtime, key, state, clearTrackedAura)
	local auraID = state and state.mappedAuraInstanceID
	local auraUnit = normalizeTrackedUnit(state and state.mappedAuraUnit)
	if auraID and auraUnit then
		local auraEntries = runtime.auraEntries[auraUnit]
		local mapped = auraEntries and auraEntries[auraID]
		if mapped then
			mapped[key] = nil
			if not next(mapped) then auraEntries[auraID] = nil end
		end
		state.mappedAuraInstanceID = nil
		state.mappedAuraUnit = nil
	end
	if clearTrackedAura and state then
		state.trackedAuraInstanceID = nil
		state.trackedAuraUnit = nil
		state.pandemicActive = nil
		if auraUnit == "target" or normalizeTrackedUnit(state.trackUnit) == "target" then state.targetAuraEpoch = nil end
	end
end

local function registerAuraMapping(runtime, key, state, auraID, auraUnit)
	if not state then return false end
	auraUnit = normalizeTrackedUnit(auraUnit)
	local mapped = auraUnit and auraID and runtime.auraEntries[auraUnit] and runtime.auraEntries[auraUnit][auraID] or nil
	local mappingRegistered = mapped and mapped[key] == true or false
	local changed = state.mappedAuraInstanceID ~= auraID or state.mappedAuraUnit ~= auraUnit or not mappingRegistered
	if auraID and state.mappedAuraInstanceID == auraID and state.mappedAuraUnit == auraUnit and mappingRegistered then return false end
	clearAuraMapping(runtime, key, state, false)
	if not (auraID and auraUnit) then return changed end
	runtime.auraEntries[auraUnit][auraID] = runtime.auraEntries[auraUnit][auraID] or {}
	runtime.auraEntries[auraUnit][auraID][key] = true
	state.mappedAuraInstanceID = auraID
	state.mappedAuraUnit = auraUnit
	return changed
end

local function unregisterFrameBinding(runtime, key, frame)
	if not (runtime and key and frame) then return end
	local keys = runtime.frameEntries[frame]
	if not keys then return end
	keys[key] = nil
	if not next(keys) then runtime.frameEntries[frame] = nil end
	local pandemicKeys = runtime.pandemicFrameEntries and runtime.pandemicFrameEntries[frame]
	if pandemicKeys then
		pandemicKeys[key] = nil
		if not next(pandemicKeys) then
			runtime.pandemicFrameEntries[frame] = nil
			frame._eqolCdmPandemicTracked = nil
		end
	end
end

local function hookFrame(frame)
	if not frame then return end
	local runtime = getRuntime()
	if runtime.hookedFrames[frame] then return end
	runtime.hookedFrames[frame] = true

	if frame.SetAuraInstanceInfo then hooksecurefunc(frame, "SetAuraInstanceInfo", function(self) CDMAuras:HandleFrameAuraMutation(self, false) end) end
	if frame.ClearAuraInstanceInfo then hooksecurefunc(frame, "ClearAuraInstanceInfo", function(self) CDMAuras:HandleFrameAuraMutation(self, true) end) end
	if frame.RefreshTotemData then hooksecurefunc(frame, "RefreshTotemData", function(self) CDMAuras:HandleFrameTotemMutation(self) end) end
	if frame.ShowPandemicStateFrame then hooksecurefunc(frame, "ShowPandemicStateFrame", function(self) CDMAuras:HandleFramePandemicStateChanged(self, true) end) end
	if frame.HidePandemicStateFrame then hooksecurefunc(frame, "HidePandemicStateFrame", function(self) CDMAuras:HandleFramePandemicStateChanged(self, false) end) end
end

local function registerFrameBinding(runtime, key, frame)
	if not (runtime and key and frame) then return end
	local keys = runtime.frameEntries[frame]
	if not keys then
		keys = {}
		runtime.frameEntries[frame] = keys
	end
	keys[key] = true
	hookFrame(frame)
end

local function updatePandemicFrameBinding(runtime, key, frame, wantsPandemic)
	if not (runtime and key and frame) then return end
	local pandemicKeys = runtime.pandemicFrameEntries[frame]
	if wantsPandemic then
		if not pandemicKeys then
			pandemicKeys = {}
			runtime.pandemicFrameEntries[frame] = pandemicKeys
		end
		pandemicKeys[key] = true
		frame._eqolCdmPandemicTracked = true
	elseif pandemicKeys then
		pandemicKeys[key] = nil
		if not next(pandemicKeys) then
			runtime.pandemicFrameEntries[frame] = nil
			frame._eqolCdmPandemicTracked = nil
		end
	end
end

local function clearEntryState(key, state, clearTrackedAura)
	if not state then return end
	local runtime = getRuntime()
	clearAuraMapping(runtime, key, state, clearTrackedAura == true)
	if state.boundFrame then
		unregisterFrameBinding(runtime, key, state.boundFrame)
		state.boundFrame = nil
	end
	state.boundSource = nil
	state.lastActive = nil
	state.pandemicActive = nil
	state.targetAuraEpoch = nil
	state.cachedScanEpoch = nil
	state.cachedScanCooldownID = nil
	state.cachedScanSpellID = nil
	state.cachedScanSourceType = nil
	state.cachedScanInfo = nil
	state.cachedResolvedCooldownID = nil
	state.cachedFrameMatchFrame = nil
	state.cachedFrameMatchFrameEpoch = nil
	state.cachedFrameMatchTargetEpoch = nil
	state.cachedFrameMatchTrackedUnit = nil
	state.cachedFrameMatchSpellID = nil
	state.cachedFrameMatchCooldownID = nil
	state.cachedFrameMatchResult = nil
	state.frameReacquirePass = nil
end

function CDMAuras:SweepInvalidStates()
	local runtime = getRuntime()
	local valid = runtime.validEntryScratch
	if not valid then
		valid = {}
		runtime.validEntryScratch = valid
	else
		wipe(valid)
	end
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	local sharedRuntime = CooldownPanels.runtime
	local cdmAuraPanelIds = sharedRuntime and sharedRuntime.cdmAuraPanelIds or nil
	local cdmAuraEntryIdsByPanel = sharedRuntime and sharedRuntime.cdmAuraEntryIdsByPanel or nil
	local enabledPanels = sharedRuntime and sharedRuntime.enabledPanels or nil
	local enabledPanelIds = sharedRuntime and sharedRuntime.enabledPanelIds or nil
	if cdmAuraPanelIds and cdmAuraEntryIdsByPanel then
		if root and root.panels then
			for i = 1, #cdmAuraPanelIds do
				local panelId = cdmAuraPanelIds[i]
				local panel = root.panels[panelId]
				local entries = panel and panel.entries
				local entryIds = cdmAuraEntryIdsByPanel[panelId]
				if entries and entryIds then
					for j = 1, #entryIds do
						local entryId = entryIds[j]
						local entry = entries[entryId]
						if entry and entry.type == ENTRY_TYPE then valid[getEntryKey(panelId, entryId)] = true end
					end
				end
			end
		end
	elseif root and root.panels and enabledPanels then
		if enabledPanelIds and #enabledPanelIds > 0 then
			for i = 1, #enabledPanelIds do
				local panelId = enabledPanelIds[i]
				local panel = enabledPanels[panelId] == true and root.panels[panelId] or nil
				local entries = panel and panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then valid[getEntryKey(panelId, entryId)] = true end
					end
				end
			end
		else
			for panelId in pairs(enabledPanels) do
				local panel = root.panels[panelId]
				local entries = panel and panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then valid[getEntryKey(panelId, entryId)] = true end
					end
				end
			end
		end
	elseif root and root.panels then
		for panelId, panel in pairs(root.panels) do
			if panel and panel.enabled ~= false then
				local entries = panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then valid[getEntryKey(panelId, entryId)] = true end
					end
				end
			end
		end
	end
	for key, state in pairs(runtime.entryStates) do
		if not valid[key] then
			clearEntryState(key, state, true)
			runtime.entryStates[key] = nil
		end
	end
	for _, auraEntries in pairs(runtime.auraEntries) do
		for auraID, mapped in pairs(auraEntries) do
			for key in pairs(mapped) do
				if not valid[key] then mapped[key] = nil end
			end
			if not next(mapped) then auraEntries[auraID] = nil end
		end
	end
end

local function getEntryTrackedUnit(scanInfo, state, frame, expectedCooldownID, preferredSource)
	local trackedUnit = nil
	if frame and type(frame.GetAuraDataUnit) == "function" then
		local ok, auraUnit = pcall(frame.GetAuraDataUnit, frame)
		if ok then trackedUnit = normalizeTrackedUnit(auraUnit) end
	end
	if not trackedUnit and frame then trackedUnit = normalizeTrackedUnit(frame.auraDataUnit) end
	if not trackedUnit and scanInfo and not scanInfoHasOnlyMismatchedFrames(scanInfo, preferredSource, expectedCooldownID) then trackedUnit = normalizeTrackedUnit(scanInfo.auraUnit) end
	if not trackedUnit and state then trackedUnit = normalizeTrackedUnit(state.trackUnit) or normalizeTrackedUnit(state.trackedAuraUnit) or normalizeTrackedUnit(state.mappedAuraUnit) end
	return trackedUnit
end

local function clearTrackedPanelIndex(runtime)
	if not runtime then return end
	runtime.unitPanels = runtime.unitPanels or createTrackedUnitBuckets()
	runtime.unitPanels.player = runtime.unitPanels.player or {}
	runtime.unitPanels.target = runtime.unitPanels.target or {}
	runtime.unitPanels.unknown = runtime.unitPanels.unknown or {}
	wipe(runtime.unitPanels.player)
	wipe(runtime.unitPanels.target)
	wipe(runtime.unitPanels.unknown)
end

local function registerTrackedPanel(runtime, unit, panelId)
	if not (runtime and panelId) then return end
	unit = normalizeTrackedUnit(unit) or "unknown"
	runtime.unitPanels = runtime.unitPanels or createTrackedUnitBuckets()
	runtime.unitPanels[unit] = runtime.unitPanels[unit] or {}
	runtime.unitPanels[unit][panelId] = true
end

local function clearRuntimeTrackingState()
	local runtime = getRuntime()
	for _, state in pairs(runtime.entryStates) do
		clearEntryState(getEntryKey(state.panelId, state.entryId), state, true)
		state.trackUnit = nil
	end
	clearTrackedPanelIndex(runtime)
	wipe(runtime.auraEntries.player)
	wipe(runtime.auraEntries.target)
	wipe(runtime.auraEntries.unknown)
end

function CDMAuras:HasActiveTrackedPanels()
	local cdmAuraPanelIds = CooldownPanels.runtime and CooldownPanels.runtime.cdmAuraPanelIds or nil
	if cdmAuraPanelIds then return #cdmAuraPanelIds > 0 end
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	if not (root and root.panels) then return false end
	local enabledPanels = CooldownPanels.runtime and CooldownPanels.runtime.enabledPanels or nil
	local enabledPanelIds = CooldownPanels.runtime and CooldownPanels.runtime.enabledPanelIds or nil
	if enabledPanels then
		if enabledPanelIds and #enabledPanelIds > 0 then
			for i = 1, #enabledPanelIds do
				local panelId = enabledPanelIds[i]
				local panel = enabledPanels[panelId] == true and root.panels[panelId] or nil
				local entries = panel and panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then return true end
					end
				end
			end
		else
			for panelId in pairs(enabledPanels) do
				local panel = root.panels[panelId]
				local entries = panel and panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then return true end
					end
				end
			end
		end
	else
		for _, panel in pairs(root.panels) do
			if panel and panel.enabled ~= false then
				local entries = panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then return true end
					end
				end
			end
		end
	end
	return false
end

function CDMAuras:UpdateEventRegistration()
	local shouldRegister = self:HasActiveTrackedPanels()
	local frame = self.eventFrame

	if not shouldRegister then
		if frame and self.eventsRegistered then
			frame:UnregisterAllEvents()
			self.eventsRegistered = nil
		end
		clearRuntimeTrackingState()
		return false
	end

	self:EnsureEventFrame()
	frame = self.eventFrame
	self:EnsureCooldownViewerHooks()
	if not self.eventsRegistered then
		frame:RegisterEvent("ADDON_LOADED")
		frame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
		frame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
		frame:RegisterEvent("PLAYER_LOGIN")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("PLAYER_TARGET_CHANGED")
		frame:RegisterEvent("PLAYER_TOTEM_UPDATE")
		frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
		frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		frame:RegisterEvent("PLAYER_TALENT_UPDATE")
		frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
		frame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
		frame:RegisterUnitEvent("UNIT_AURA", "player", "target")
		frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		self.eventsRegistered = true
	end

	return true
end

function CDMAuras:RebuildTrackedPanelIndex()
	local runtime = getRuntime()
	clearTrackedPanelIndex(runtime)
	if not self:HasActiveTrackedPanels() then return end

	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	if not (root and root.panels) then return end
	local sharedRuntime = CooldownPanels.runtime
	local cdmAuraPanelIds = sharedRuntime and sharedRuntime.cdmAuraPanelIds or nil
	local cdmAuraEntryIdsByPanel = sharedRuntime and sharedRuntime.cdmAuraEntryIdsByPanel or nil
	local _, byCooldownID, bySpellID, byCooldownKey = self:ScanTrackedBuffs(false)

	if cdmAuraPanelIds and cdmAuraEntryIdsByPanel then
		for i = 1, #cdmAuraPanelIds do
			local panelId = cdmAuraPanelIds[i]
			local panel = root.panels[panelId]
			local entries = panel and panel.entries
			local entryIds = cdmAuraEntryIdsByPanel[panelId]
			if entries and entryIds then
				for j = 1, #entryIds do
					local entryId = entryIds[j]
					local entry = entries[entryId]
					if entry and entry.type == ENTRY_TYPE then
						local key = getEntryKey(panelId, entryId)
						local state = runtime.entryStates[key]
						local scanInfo, resolvedCooldownID = resolveEntryScanInfo(entry, byCooldownID, bySpellID, byCooldownKey)
						local expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
						local matchingFrame = getScanInfoMatchingFrame(scanInfo, entry.sourceType, expectedCooldownID)
						local trackedUnit = getEntryTrackedUnit(scanInfo, state, matchingFrame, expectedCooldownID, entry.sourceType)
						if state then state.trackUnit = trackedUnit end
						registerTrackedPanel(runtime, trackedUnit, panelId)
					end
				end
			end
		end
		return
	end

	local enabledPanels = sharedRuntime and sharedRuntime.enabledPanels or nil
	local enabledPanelIds = sharedRuntime and sharedRuntime.enabledPanelIds or nil
	if enabledPanels then
		if enabledPanelIds and #enabledPanelIds > 0 then
			for i = 1, #enabledPanelIds do
				local panelId = enabledPanelIds[i]
				local panel = enabledPanels[panelId] == true and root.panels[panelId] or nil
				local entries = panel and panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							local key = getEntryKey(panelId, entryId)
							local state = runtime.entryStates[key]
							local scanInfo, resolvedCooldownID = resolveEntryScanInfo(entry, byCooldownID, bySpellID, byCooldownKey)
							local expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
							local matchingFrame = getScanInfoMatchingFrame(scanInfo, entry.sourceType, expectedCooldownID)
							local trackedUnit = getEntryTrackedUnit(scanInfo, state, matchingFrame, expectedCooldownID, entry.sourceType)
							if state then state.trackUnit = trackedUnit end
							registerTrackedPanel(runtime, trackedUnit, panelId)
						end
					end
				end
			end
		else
			for panelId in pairs(enabledPanels) do
				local panel = root.panels[panelId]
				local entries = panel and panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							local key = getEntryKey(panelId, entryId)
							local state = runtime.entryStates[key]
							local scanInfo, resolvedCooldownID = resolveEntryScanInfo(entry, byCooldownID, bySpellID, byCooldownKey)
							local expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
							local matchingFrame = getScanInfoMatchingFrame(scanInfo, entry.sourceType, expectedCooldownID)
							local trackedUnit = getEntryTrackedUnit(scanInfo, state, matchingFrame, expectedCooldownID, entry.sourceType)
							if state then state.trackUnit = trackedUnit end
							registerTrackedPanel(runtime, trackedUnit, panelId)
						end
					end
				end
			end
		end
	else
		for panelId, panel in pairs(root.panels) do
			if panel and panel.enabled ~= false then
				local entries = panel.entries
				if entries then
					for entryId, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							local key = getEntryKey(panelId, entryId)
							local state = runtime.entryStates[key]
							local scanInfo, resolvedCooldownID = resolveEntryScanInfo(entry, byCooldownID, bySpellID, byCooldownKey)
							local expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
							local matchingFrame = getScanInfoMatchingFrame(scanInfo, entry.sourceType, expectedCooldownID)
							local trackedUnit = getEntryTrackedUnit(scanInfo, state, matchingFrame, expectedCooldownID, entry.sourceType)
							if state then state.trackUnit = trackedUnit end
							registerTrackedPanel(runtime, trackedUnit, panelId)
						end
					end
				end
			end
		end
	end
end

local function isFrameShowingTrackedSpell(frame, entry, trackedUnit)
	local trackedSpellID = entry and (entry.signatureSpellID or entry.spellID)
	local trackedCooldownID = entry and (entry.signatureCooldownID or entry.cooldownID)
	if not (frame and trackedSpellID) then return true end
	local strictMatch = normalizeTrackedUnit(trackedUnit) == "target"
	local framePassCache = getRuntimePassCacheTable("runtimePassFrameSpellMatches")
	local frameCache
	local matchKey
	if framePassCache then
		frameCache = framePassCache[frame]
		if not frameCache then
			frameCache = {}
			framePassCache[frame] = frameCache
		end
		matchKey = tostring(normalizeTrackedUnit(trackedUnit) or "") .. "\031" .. tostring(trackedSpellID or "") .. "\031" .. tostring(trackedCooldownID or "")
		if frameCache[matchKey] ~= nil then return frameCache[matchKey] end
	end
	if type(frame.SpellIDMatchesAnyAssociatedSpellIDs) == "function" then
		local ok, matches = pcall(frame.SpellIDMatchesAnyAssociatedSpellIDs, frame, trackedSpellID)
		if ok then
			local result = matches == true
			if frameCache and matchKey then frameCache[matchKey] = result end
			return result
		end
	end
	local sawAssociatedSpellID = false
	local sawSecretLinkedSpellID = false
	local matched
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCandidate(frame.auraSpellID, "auraSpellID", trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then
		if frameCache and matchKey then frameCache[matchKey] = true end
		return true
	end
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCooldownInfo(frame.cooldownInfo, trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then
		if frameCache and matchKey then frameCache[matchKey] = true end
		return true
	end
	matched, sawAssociatedSpellID, sawSecretLinkedSpellID = frameTrackedSpellMatchesCooldownInfo(getCooldownViewerInfo(trackedCooldownID), trackedSpellID, sawAssociatedSpellID, sawSecretLinkedSpellID)
	if matched then
		if frameCache and matchKey then frameCache[matchKey] = true end
		return true
	end
	local result
	if sawSecretLinkedSpellID then
		result = true
	elseif strictMatch then
		result = false
	else
		result = not sawAssociatedSpellID
	end
	if frameCache and matchKey then frameCache[matchKey] = result end
	return result
end

function cdm.GetCachedFrameSpellMatch(runtime, state, frame, trackedUnit)
	if not (runtime and state and frame) then return false end
	local normalizedTrackedUnit = normalizeTrackedUnit(trackedUnit)
	local targetEpoch = runtime.targetEpoch or 0
	local frameEpoch = cdm.GetFrameEpoch(runtime, frame)
	if
		state.cachedFrameMatchFrame == frame
		and state.cachedFrameMatchFrameEpoch == frameEpoch
		and state.cachedFrameMatchTargetEpoch == targetEpoch
		and state.cachedFrameMatchTrackedUnit == normalizedTrackedUnit
		and state.cachedFrameMatchSpellID == state.signatureSpellID
		and cooldownIDsEqual(state.cachedFrameMatchCooldownID, state.signatureCooldownID)
	then
		return state.cachedFrameMatchResult == true
	end
	local result = isFrameShowingTrackedSpell(frame, state, trackedUnit) == true
	state.cachedFrameMatchFrame = frame
	state.cachedFrameMatchFrameEpoch = frameEpoch
	state.cachedFrameMatchTargetEpoch = targetEpoch
	state.cachedFrameMatchTrackedUnit = normalizedTrackedUnit
	state.cachedFrameMatchSpellID = state.signatureSpellID
	state.cachedFrameMatchCooldownID = state.signatureCooldownID
	state.cachedFrameMatchResult = result
	return result
end

local function getFrameAuraUnit(frame)
	if not frame then return nil end
	if type(frame.GetAuraDataUnit) == "function" then
		local ok, auraUnit = pcall(frame.GetAuraDataUnit, frame)
		if ok and type(auraUnit) == "string" and auraUnit ~= "" then return auraUnit end
	end
	if type(frame.auraDataUnit) == "string" and frame.auraDataUnit ~= "" then return frame.auraDataUnit end
	return nil
end

local function getFrameAuraData(frame)
	local passCache = frame and getRuntimePassCacheTable("runtimePassFrameAuraData") or nil
	if passCache then
		local cached = passCache[frame]
		if cached then
			local currentAuraInstanceID = frame and hasAuraInstanceID(frame.auraInstanceID) and frame.auraInstanceID or nil
			local canReuseCachedNil = cached.auraData ~= nil or currentAuraInstanceID == nil or cached.auraInstanceID == currentAuraInstanceID
			if canReuseCachedNil then return cached.auraData, cached.auraUnit, cached.auraInstanceID end
		end
	end
	if not frame then return nil, nil, nil end
	local runtime = getRuntime()
	local auraUnit = getFrameAuraUnit(frame)
	local auraInstanceID = hasAuraInstanceID(frame.auraInstanceID) and frame.auraInstanceID or nil
	local frameEpoch = cdm.GetFrameEpoch(runtime, frame)
	local unitAuraEpoch = cdm.GetUnitAuraEpoch(runtime, auraUnit)
	local persistentCache = runtime.frameAuraSnapshotByFrame and runtime.frameAuraSnapshotByFrame[frame] or nil
	if
		persistentCache
		and persistentCache.frameEpoch == frameEpoch
		and persistentCache.unitAuraEpoch == unitAuraEpoch
		and persistentCache.auraUnit == auraUnit
		and persistentCache.auraInstanceID == auraInstanceID
	then
		local canReuseCachedNil = persistentCache.auraData ~= nil or auraInstanceID == nil
		if canReuseCachedNil then
			if passCache then
				passCache[frame] = passCache[frame] or {}
				passCache[frame].auraData = persistentCache.auraData
				passCache[frame].auraUnit = persistentCache.auraUnit
				passCache[frame].auraInstanceID = persistentCache.auraInstanceID
			end
			return persistentCache.auraData, persistentCache.auraUnit, persistentCache.auraInstanceID
		end
	end
	local auraData = nil
	if auraUnit and auraInstanceID then auraData = getAuraDataByAuraInstanceIDCached(auraUnit, auraInstanceID) end
	runtime.frameAuraSnapshotByFrame = cdm.EnsureWeakKeyTable(runtime.frameAuraSnapshotByFrame)
	local snapshot = runtime.frameAuraSnapshotByFrame[frame]
	if not snapshot then
		snapshot = {}
		runtime.frameAuraSnapshotByFrame[frame] = snapshot
	end
	snapshot.auraData = auraData
	snapshot.auraUnit = auraUnit
	snapshot.auraInstanceID = auraInstanceID
	snapshot.frameEpoch = frameEpoch
	snapshot.unitAuraEpoch = unitAuraEpoch
	if passCache then
		passCache[frame] = passCache[frame] or {}
		passCache[frame].auraData = auraData
		passCache[frame].auraUnit = auraUnit
		passCache[frame].auraInstanceID = auraInstanceID
	end
	if auraData then return auraData, auraUnit, auraInstanceID end
	return nil, auraUnit, auraInstanceID
end

local function frameHasPandemicState(frame)
	local pandemicIcon = frame and frame.PandemicIcon
	if not (pandemicIcon and pandemicIcon.IsShown) then return false end
	local ok, shown = pcall(pandemicIcon.IsShown, pandemicIcon)
	return ok and shown == true
end

local function clearTrackedAuraState(runtime, key, state)
	if not state then return false end
	local hadTrackedState = state.trackedAuraInstanceID ~= nil or state.trackedAuraUnit ~= nil or state.pandemicActive ~= nil or state.targetAuraEpoch ~= nil
	local hadMappedState = state.mappedAuraInstanceID ~= nil or state.mappedAuraUnit ~= nil
	clearAuraMapping(runtime, key, state, false)
	state.trackedAuraInstanceID = nil
	state.trackedAuraUnit = nil
	state.pandemicActive = nil
	state.targetAuraEpoch = nil
	return hadTrackedState or hadMappedState
end

function CDMAuras:HandleFrameAuraMutation(frame, wasCleared)
	if not frame then return end
	local runtime = getRuntime()
	cdm.BumpFrameEpoch(runtime, frame)
	local keys = runtime.frameEntries[frame]
	if not keys then return end
	local auraData, auraUnit, newAuraID = getFrameAuraData(frame)
	local normalizedAuraUnit = normalizeTrackedUnit(auraUnit)
	local refreshedPanels = runtime.scratchRefreshedPanels
	wipe(refreshedPanels)

	for key in pairs(keys) do
		local state = runtime.entryStates[key]
		if state then
			local changed = false
			local _, entry = getPanelEntry(state.panelId, state.entryId)
			if not entry or entry.type ~= ENTRY_TYPE then
				clearEntryState(key, state, true)
				changed = true
			else
				local frameMatchesTrackedSpell = newAuraID and cdm.GetCachedFrameSpellMatch(runtime, state, frame, state.trackUnit or auraUnit) or false
				if wasCleared or (newAuraID and not frameMatchesTrackedSpell) or (not newAuraID and not auraData) then
					changed = clearTrackedAuraState(runtime, key, state)
				elseif frameMatchesTrackedSpell then
					local nextTrackUnit = normalizedAuraUnit or state.trackUnit
					local nextTrackedAuraUnit = auraUnit or state.trackedAuraUnit
					local nextPandemicActive = normalizedAuraUnit == "target" and frameHasPandemicState(frame) or nil
					local nextTargetAuraEpoch = normalizedAuraUnit == "target" and (runtime.targetEpoch or 0) or nil

					if state.trackUnit ~= nextTrackUnit then
						state.trackUnit = nextTrackUnit
						changed = true
					end
					if state.trackedAuraInstanceID ~= newAuraID then
						state.trackedAuraInstanceID = newAuraID
						changed = true
					end
					if state.trackedAuraUnit ~= nextTrackedAuraUnit then
						state.trackedAuraUnit = nextTrackedAuraUnit
						changed = true
					end
					if state.pandemicActive ~= nextPandemicActive then
						state.pandemicActive = nextPandemicActive
						changed = true
					end
					if state.targetAuraEpoch ~= nextTargetAuraEpoch then
						state.targetAuraEpoch = nextTargetAuraEpoch
						changed = true
					end
					if registerAuraMapping(runtime, key, state, newAuraID, auraUnit) then changed = true end
				end
			end
			if changed then refreshedPanels[state.panelId] = true end
		end
	end

	for panelId in pairs(refreshedPanels) do
		requestPanelRefresh(panelId)
		refreshedPanels[panelId] = nil
	end
end

function CDMAuras:HandleFrameTotemMutation(frame)
	if not frame then return end
	local runtime = getRuntime()
	cdm.BumpFrameEpoch(runtime, frame)
	local keys = runtime.frameEntries[frame]
	if not keys then return end

	-- Totem-backed tracked buffs can change state on an existing viewer frame without
	-- touching aura instance data or cooldownID. Force the next runtime build to rescan.
	self:InvalidateScan(false, "HandleFrameTotemMutation")

	local refreshedPanels = runtime.scratchRefreshedPanels
	wipe(refreshedPanels)
	for key in pairs(keys) do
		local state = runtime.entryStates[key]
		if state then refreshedPanels[state.panelId] = true end
	end

	for panelId in pairs(refreshedPanels) do
		requestPanelRefresh(panelId)
		refreshedPanels[panelId] = nil
	end
end

function CDMAuras:HandleFramePandemicStateChanged(frame, isActive)
	if not (frame and frame._eqolCdmPandemicTracked == true) then return end
	local runtime = getRuntime()
	local keys = runtime.pandemicFrameEntries[frame]
	if not keys then
		frame._eqolCdmPandemicTracked = nil
		return
	end

	local auraUnit = normalizeTrackedUnit(getFrameAuraUnit(frame))
	local pandemicActive = isActive == true and frameHasPandemicState(frame) and auraUnit == "target"
	local refreshedPanels = runtime.scratchRefreshedPanels
	wipe(refreshedPanels)

	for key in pairs(keys) do
		local state = runtime.entryStates[key]
		if state then
			local nextPandemicActive = false
			if pandemicActive and cdm.GetCachedFrameSpellMatch(runtime, state, frame, state.trackUnit or auraUnit) then nextPandemicActive = true end
			if (state.pandemicActive == true) ~= nextPandemicActive then
				state.pandemicActive = nextPandemicActive or nil
				refreshedPanels[state.panelId] = true
			end
		end
	end

	for panelId in pairs(refreshedPanels) do
		requestPanelRefresh(panelId)
		refreshedPanels[panelId] = nil
	end
end

function CDMAuras:NormalizeEntry(entry)
	if type(entry) ~= "table" then return end
	entry.type = ENTRY_TYPE
	local numericCooldownID = tonumber(entry.cooldownID)
	if numericCooldownID and numericCooldownID > 0 then
		entry.cooldownID = numericCooldownID
	elseif not isValidCooldownID(entry.cooldownID) then
		entry.cooldownID = nil
	end
	entry.spellID = tonumber(entry.spellID)
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
	if entry.showStacks == nil then
		entry.showStacks = false
	else
		entry.showStacks = entry.showStacks == true
	end
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

function CDMAuras:CreateEntryData(idValue, overrides, defaults)
	local info = idValue
	if type(info) ~= "table" then
		local _, byCooldownID = self:ScanTrackedBuffs(false)
		info = byCooldownID and byCooldownID[idValue] or nil
	end
	if type(info) ~= "table" or not isValidCooldownID(info.cooldownID) then return nil end

	defaults = defaults or {}
	local entryDefaults = defaults.entry or Helper.ENTRY_DEFAULTS or {}
	local entry = Helper.CopyTableShallow(entryDefaults)
	for key, value in pairs(Helper.ENTRY_DEFAULTS or {}) do
		if entry[key] == nil then entry[key] = value end
	end

	entry.type = ENTRY_TYPE
	entry.cooldownID = info.cooldownID
	entry.spellID = tonumber(info.spellID)
	entry.buffName = info.buffName or getSpellName(entry.spellID) or tostring(info.cooldownID)
	entry.iconTextureID = info.iconTextureID or getSpellTexture(entry.spellID) or Helper.PREVIEW_ICON
	entry.sourceType = normalizeSourceType(info.sourceType)
	entry.sourceViewer = info.sourceViewer or (entry.sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER)
	entry.cdmAuraAlwaysShowUseGlobal = true
	entry.cdmAuraAlwaysShowMode = "HIDE"
	entry.alwaysShow = false
	entry.showCooldown = true
	entry.showCooldownText = true
	entry.showStacks = false
	entry.glowReady = false
	entry.pandemicGlow = false
	entry.soundReady = false

	if type(overrides) == "table" then
		for key, value in pairs(overrides) do
			entry[key] = value
		end
	end

	self:NormalizeEntry(entry)
	return entry
end

function CDMAuras:FindEntryByValue(panel, idValue)
	if not panel or not panel.entries then return nil end
	local lookup = type(idValue) == "table" and idValue.cooldownID or idValue
	if not isValidCooldownID(lookup) then return nil end
	for entryId, entry in pairs(panel.entries) do
		if entry and entry.type == ENTRY_TYPE then
			if isValidCooldownID(lookup) and cooldownIDsEqual(entry.cooldownID, lookup) then return entryId, entry end
		end
	end
	return nil
end

function CDMAuras:GetEntryIcon(entry)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end
	if entry.iconTextureID then return entry.iconTextureID end
	return getSpellTexture(entry.spellID) or Helper.PREVIEW_ICON
end

function CDMAuras:GetEntryName(entry)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end
	return entry.buffName or getSpellName(entry.spellID) or (L["CooldownPanelCDMAuraType"] or "Tracked Aura")
end

function CDMAuras:GetEntryTypeLabel(entryType)
	if entryType ~= ENTRY_TYPE then return nil end
	return L["CooldownPanelCDMAuraType"] or "Tracked Aura"
end

function CDMAuras:GetEntryIdText(entry)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end
	return tostring(entry.cooldownID or "")
end

function CDMAuras:EntryIsAvailableForPreview(entry) return entry and entry.type == ENTRY_TYPE and isValidCooldownID(entry.cooldownID) end

function CDMAuras:ApplyPreview(icon, entry)
	if not (icon and entry and entry.type == ENTRY_TYPE) then return end
	if entry.showStacks and icon.count then
		icon.count:SetText("2")
		icon.count:Show()
	end
end

function CDMAuras:AttachEditor(editor)
	if not (editor and editor.inspector and editor.inspector.content) then return end
	local inspector = editor.inspector
	if inspector.cdmAuraCooldownIDLabel then return end

	local idLabel = inspector.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	idLabel:SetJustifyH("LEFT")
	idLabel:SetWidth(200)
	idLabel:SetTextColor(0.85, 0.85, 0.85, 1)

	inspector.cdmAuraCooldownIDLabel = idLabel
end

function CDMAuras:RefreshInspector(editor, _, entry)
	local inspector = editor and editor.inspector
	if not inspector then return end

	local isEntry = entry and entry.type == ENTRY_TYPE
	local idLabel = inspector.cdmAuraCooldownIDLabel
	if not idLabel then return end

	if not isEntry then
		idLabel:Hide()
		return
	end

	idLabel:SetText(string.format(L["CooldownPanelCDMAuraCooldownID"] or "Cooldown ID: %s", tostring(entry.cooldownID or "")))
end

function CDMAuras:LayoutInspector(inspector, entry, prev)
	local idLabel = inspector and inspector.cdmAuraCooldownIDLabel
	if not idLabel then return prev end

	if not (entry and entry.type == ENTRY_TYPE) then
		idLabel:Hide()
		return prev
	end

	idLabel:ClearAllPoints()
	idLabel:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -8)
	idLabel:Show()
	return idLabel
end

function CDMAuras:AppendAddMenu(rootDescription, panelId)
	if not (rootDescription and panelId) then return end
	local buffsMenu = rootDescription:CreateButton(L["CooldownPanelCDMAuraAdd"] or "Tracked Aura (CDM)")
	if not buffsMenu then return end
	if buffsMenu.SetScrollMode then buffsMenu:SetScrollMode(340) end
	buffsMenu:CreateTitle(L["CooldownPanelCDMAuraPickerTitle"] or "Tracked Auras from Cooldown Manager")

	local buffs = self:ScanTrackedBuffs(true)
	local list = buffs
	if not list or #list == 0 then
		buffsMenu:CreateTitle(L["CooldownPanelCDMAuraNoBuffs"] or "No tracked auras found.")
		return
	end

	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	local existingCooldownIDs = {}
	for _, entry in pairs(panel and panel.entries or {}) do
		if entry and entry.type == ENTRY_TYPE then
			if isValidCooldownID(entry.cooldownID) then existingCooldownIDs[tostring(entry.cooldownID)] = true end
		end
	end
	local duplicateNames = {}
	for _, info in ipairs(list) do
		local nameKey = string.lower(tostring(info and (info.buffName or info.cooldownID) or ""))
		duplicateNames[nameKey] = (duplicateNames[nameKey] or 0) + 1
	end

	local availableCount = 0
	buffsMenu:CreateTitle(L["CooldownPanelCDMAuraPickerNote"] or "Auras set to Always Display can be added while inactive. Others only appear while active.")
	for _, info in ipairs(list) do
		if not existingCooldownIDs[tostring(info.cooldownID)] then
			availableCount = availableCount + 1
			local icon = tostring(info.iconTextureID or Helper.PREVIEW_ICON)
			local nameText = tostring(info.buffName or info.cooldownID)
			local label = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, nameText)
			local sourceType = normalizeSourceType(info.sourceType or (info.availableSources and info.availableSources[SOURCE_ICON] and SOURCE_ICON or SOURCE_BAR))
			local addInfo = {
				cooldownID = info.cooldownID,
				spellID = info.spellID,
				buffName = info.buffName,
				iconTextureID = info.iconTextureID,
				sourceType = sourceType,
				sourceViewer = info.sourceViewer or (sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER),
			}
			if (duplicateNames[string.lower(nameText)] or 0) > 1 then
				label = string.format("%s |cff888888(CD:%s, Spell:%s)|r", label, tostring(info.cooldownID or "?"), tostring(info.spellID or "?"))
			end
			buffsMenu:CreateButton(label, function()
				if CooldownPanels.AddEntrySafe then
					CooldownPanels:AddEntrySafe(panelId, ENTRY_TYPE, addInfo)
					CooldownPanels:RefreshEditor()
				end
			end)
		end
	end
	if availableCount == 0 then buffsMenu:CreateTitle(L["CooldownPanelCDMAuraAllAdded"] or "All tracked auras are already in this panel.") end
end

function CDMAuras:GetImportSourceLabel(sourceKind)
	if sourceKind == IMPORT_SOURCE_BAR then return L["CooldownPanelImportCDMBuffBar"] or "Buff Bar" end
	if sourceKind == IMPORT_SOURCE_ICON then return L["CooldownPanelImportCDMBuffIcon"] or "Buff Icon" end
	return nil
end

function CDMAuras:ImportEntries(panelId, sourceKind)
	local sourceType = getImportSourceType(sourceKind)
	local sourceLabel = self:GetImportSourceLabel(sourceKind)
	if not sourceType then return nil, "SOURCE_NOT_FOUND", sourceLabel end

	local viewerName = sourceType == SOURCE_BAR and BAR_VIEWER or ICON_VIEWER
	if type(_G[viewerName]) ~= "table" then return nil, "SOURCE_NOT_FOUND", sourceLabel end

	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if not panel then return nil, "PANEL_NOT_FOUND", sourceLabel end
	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	if not root then return nil, "NO_DB", sourceLabel end

	panel.entries = panel.entries or {}
	panel.order = panel.order or {}

	local existingByCooldownID = {}
	for _, entry in pairs(panel.entries) do
		if entry and entry.type == ENTRY_TYPE then
			if isValidCooldownID(entry.cooldownID) then existingByCooldownID[tostring(entry.cooldownID)] = true end
		end
	end

	local list = self:ScanTrackedBuffs(true)
	local stats = { added = 0, duplicates = 0, invalid = 0, seen = 0, sourceLabel = sourceLabel }

	for _, info in ipairs(list or {}) do
		if info and info.availableSources and info.availableSources[sourceType] then
			stats.seen = stats.seen + 1
			if not isValidCooldownID(info.cooldownID) then
				stats.invalid = stats.invalid + 1
			else
				local cooldownKey = tostring(info.cooldownID)
				if existingByCooldownID[cooldownKey] then
					stats.duplicates = stats.duplicates + 1
				else
					local entryInfo = {
						cooldownID = info.cooldownID,
						spellID = info.spellID,
						buffName = info.buffName,
						iconTextureID = info.iconTextureID,
						sourceType = sourceType,
						sourceViewer = viewerName,
					}
					local entryId = Helper.GetNextNumericId(panel.entries)
					local entry = Helper.CreateEntry(ENTRY_TYPE, entryInfo, root.defaults)
					if entry and entry.cooldownID then
						entry.id = entryId
						panel.entries[entryId] = entry
						panel.order[#panel.order + 1] = entryId
						existingByCooldownID[cooldownKey] = true
						stats.added = stats.added + 1
					else
						stats.invalid = stats.invalid + 1
					end
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

function CDMAuras:AddEntrySafe(panelId, idValue, overrides)
	local lookupCooldownID = type(idValue) == "table" and idValue.cooldownID or idValue
	local info = nil
	local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
	if isValidCooldownID(lookupCooldownID) then
		local _, byCooldownID = self:ScanTrackedBuffs(false)
		info = byCooldownID and byCooldownID[lookupCooldownID] or nil
	end
	if type(info) ~= "table" and type(idValue) == "table" and isValidCooldownID(idValue.cooldownID) then
		info = {
			cooldownID = idValue.cooldownID,
			spellID = idValue.spellID,
			buffName = idValue.buffName,
			iconTextureID = idValue.iconTextureID,
			sourceType = normalizeSourceType(idValue.sourceType),
			sourceViewer = idValue.sourceViewer,
		}
	end
	if type(info) ~= "table" or not isValidCooldownID(info.cooldownID) then
		showErrorMessage(L["CooldownPanelCDMAuraNotFound"] or "Tracked aura not found in Cooldown Manager.")
		return nil
	end
	local effectiveOverrides = overrides
	if panel and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) and CooldownPanels.ResolveFixedEntryAddOverrides then
		local resolvedOverrides, fixedError = CooldownPanels:ResolveFixedEntryAddOverrides(panel, overrides)
		if fixedError then
			showErrorMessage(fixedError)
			return nil
		end
		effectiveOverrides = resolvedOverrides
	end
	local existingEntryId = CooldownPanels.FindEntryByValue and CooldownPanels:FindEntryByValue(panelId, ENTRY_TYPE, info.cooldownID) or nil
	if existingEntryId then
		showErrorMessage("Entry already exists.")
		return nil
	end
	if not CooldownPanels.AddEntry then return nil end
	return CooldownPanels:AddEntry(panelId, ENTRY_TYPE, info, effectiveOverrides)
end

function CDMAuras:HandleRootRefresh()
	local runtime = getRuntime()
	self:SweepInvalidStates()
	clearTrackedPanelIndex(runtime)
	if not self:UpdateEventRegistration() then return end
	self:InvalidateScan(false, "HandleRootRefresh")
	refreshAllTrackedPanels()
end

function CDMAuras:HandleRuntimeIndexChanged(reason, clearCooldownViewerInfo)
	local runtime = getRuntime()
	self:SweepInvalidStates()
	clearTrackedPanelIndex(runtime)
	if not self:UpdateEventRegistration() then return end
	self:InvalidateScan(clearCooldownViewerInfo == true, reason or "RuntimeIndexChanged")
	refreshAllTrackedPanels()
end

function CDMAuras:BuildRuntimeData(panelId, entryId, entry, entryLayout, alwaysShowMode)
	if not (entry and entry.type == ENTRY_TYPE) then return nil end

	local runtime = getRuntime()
	local key = getEntryKey(panelId, entryId)
	local state = runtime.entryStates[key]
	if not state then
		state = {
			panelId = panelId,
			entryId = entryId,
			signatureCooldownID = nil,
			signatureSpellID = nil,
			signatureSourceType = nil,
			boundFrame = nil,
			boundSource = nil,
			mappedAuraInstanceID = nil,
			mappedAuraUnit = nil,
			trackedAuraInstanceID = nil,
			trackedAuraUnit = nil,
			pandemicActive = nil,
			targetAuraEpoch = nil,
			trackUnit = nil,
			lastActive = nil,
			runtimeData = { availableSources = {} },
		}
		runtime.entryStates[key] = state
	end

	local scanInfo
	local resolvedCooldownID
	local scanEpoch = runtime.scanEpoch or 0
	local cachedScanInfo = state.cachedScanInfo
	if
		state.cachedScanEpoch == scanEpoch
		and state.cachedScanCooldownID == entry.cooldownID
		and state.cachedScanSpellID == entry.spellID
		and state.cachedScanSourceType == entry.sourceType
		and cachedScanInfo ~= nil
	then
		scanInfo = cachedScanInfo ~= NO_SCAN_INFO and cachedScanInfo or nil
		resolvedCooldownID = state.cachedResolvedCooldownID
	else
			local scan, byCooldownID, _, byCooldownKey = self:ScanTrackedBuffs(false, "runtime")
			scanInfo, resolvedCooldownID = resolveRuntimeEntryScanInfo(entry, scan, byCooldownID, byCooldownKey)
		local expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
		local staleFrameScanInfo = scanInfoHasOnlyMismatchedFrames(scanInfo, entry.sourceType, expectedCooldownID)
		if not scanInfo or staleFrameScanInfo then
			local rescanEpoch = runtime.scanEpoch or scanEpoch
				local rescanned
				local rescannedByCooldownKey
				if runtime.forcedRescanEpoch == rescanEpoch then
					local _, rescannedByCooldownID, _rescannedBySpellID, rescannedCooldownLookup = self:ScanTrackedBuffs(false, "runtime")
					rescanned = rescannedByCooldownID
					rescannedByCooldownKey = rescannedCooldownLookup
				else
					-- A negative first lookup can happen before Cooldown Viewer data or frames are ready.
					-- Clear cached viewer info too so the forced rescan can recover once Blizzard finishes initialization.
					self:InvalidateScan(true, "BuildRuntimeData:ForcedRescan")
					local _, rescannedByCooldownID, rescannedBySpellLookup, rescannedCooldownLookup = self:ScanTrackedBuffs(true, "runtime")
					rescanned = rescannedByCooldownID
					rescannedByCooldownKey = rescannedCooldownLookup
					runtime.forcedRescanEpoch = runtime.scanEpoch or rescanEpoch
				end
				scanInfo, resolvedCooldownID = resolveRuntimeEntryScanInfo(entry, runtime.scan, rescanned, rescannedByCooldownKey)
			expectedCooldownID = isValidCooldownID(resolvedCooldownID) and resolvedCooldownID or entry.cooldownID
			if scanInfoHasOnlyMismatchedFrames(scanInfo, entry.sourceType, expectedCooldownID) then scanInfo = nil end
		end
		state.cachedScanEpoch = runtime.scanEpoch or 0
		state.cachedScanCooldownID = entry.cooldownID
		state.cachedScanSpellID = entry.spellID
		state.cachedScanSourceType = entry.sourceType
		state.cachedScanInfo = scanInfo or NO_SCAN_INFO
		state.cachedResolvedCooldownID = resolvedCooldownID
	end
	if not isValidCooldownID(resolvedCooldownID) then resolvedCooldownID = entry.cooldownID end

	local signatureSourceType = tostring(entry.sourceType or SOURCE_ICON)
	if state.signatureCooldownID ~= resolvedCooldownID or state.signatureSpellID ~= entry.spellID or state.signatureSourceType ~= signatureSourceType then
		clearEntryState(key, state, true)
		state.signatureCooldownID = resolvedCooldownID
		state.signatureSpellID = entry.spellID
		state.signatureSourceType = signatureSourceType
	end
	state.panelId = panelId
	state.entryId = entryId

	local data = state.runtimeData or { availableSources = {} }
	state.runtimeData = data
	local availableSources = data.availableSources or {}
	data.availableSources = availableSources
	wipe(availableSources)
	if scanInfo and scanInfo.availableSources then
		for sourceType in pairs(scanInfo.availableSources) do
			availableSources[sourceType] = true
		end
	end
	if not next(availableSources) then availableSources[normalizeSourceType(entry.sourceType)] = true end

	local preferredSource = normalizeSourceType(entry.sourceType)
	local chosenFrame, chosenSource, _, fallbackFrame = selectScanInfoFrame(scanInfo, preferredSource, resolvedCooldownID)
	if scanInfo then ensureScanInfoDerived(scanInfo, resolvedCooldownID, chosenFrame or fallbackFrame, false, true) end
	local trackedUnit = getEntryTrackedUnit(scanInfo, state, chosenFrame or fallbackFrame, resolvedCooldownID or entry.cooldownID, preferredSource)

	if state.lastActive == true and chosenFrame then
		local chosenFrameLooksActive = frameHasActiveAuraOrTotem(chosenFrame)
		local chosenFrameMatchesTrackedSpell = chosenFrameLooksActive and cdm.GetCachedFrameSpellMatch(runtime, state, chosenFrame, trackedUnit)
		local runtimePass = runtime.runtimePass
		if not chosenFrameLooksActive or not chosenFrameMatchesTrackedSpell then
			local rescannedByCooldownID
				local rescannedByCooldownKey
				if runtimePass and runtime.reacquireRescanPass == runtimePass then
					local _, latestByCooldownID, _latestBySpellID, latestByCooldownKey = self:ScanTrackedBuffs(false, "runtime")
					rescannedByCooldownID = latestByCooldownID
					rescannedByCooldownKey = latestByCooldownKey
				else
					self:InvalidateScan(false, "BuildRuntimeData:Reacquire")
					local _, latestByCooldownID, _latestBySpellID, latestByCooldownKey = self:ScanTrackedBuffs(true, "runtime")
					rescannedByCooldownID = latestByCooldownID
					rescannedByCooldownKey = latestByCooldownKey
					if runtimePass then runtime.reacquireRescanPass = runtimePass end
				end
				scanInfo, resolvedCooldownID = resolveRuntimeEntryScanInfo(entry, runtime.scan, rescannedByCooldownID, rescannedByCooldownKey)
				if not isValidCooldownID(resolvedCooldownID) then resolvedCooldownID = entry.cooldownID end
			state.cachedScanEpoch = runtime.scanEpoch or 0
			state.cachedScanCooldownID = entry.cooldownID
			state.cachedScanSpellID = entry.spellID
			state.cachedScanSourceType = entry.sourceType
			state.cachedScanInfo = scanInfo or NO_SCAN_INFO
			state.cachedResolvedCooldownID = resolvedCooldownID
				local reacquiredChosenFrame, reacquiredChosenSource, _, reacquiredFallbackFrame = selectScanInfoFrame(scanInfo, preferredSource, resolvedCooldownID)
				chosenFrame, chosenSource, fallbackFrame = reacquiredChosenFrame, reacquiredChosenSource, reacquiredFallbackFrame
				if scanInfo then ensureScanInfoDerived(scanInfo, resolvedCooldownID, chosenFrame or fallbackFrame, false, true) end
				trackedUnit = getEntryTrackedUnit(scanInfo, state, chosenFrame or fallbackFrame, resolvedCooldownID or entry.cooldownID, preferredSource)
			if runtimePass then state.frameReacquirePass = runtimePass end
		end
	end

	if state.boundFrame ~= chosenFrame then
		if state.boundFrame then unregisterFrameBinding(runtime, key, state.boundFrame) end
		state.boundFrame = chosenFrame
		state.boundSource = chosenSource
		if chosenFrame then registerFrameBinding(runtime, key, chosenFrame) end
	end
	if state.boundFrame then updatePandemicFrameBinding(runtime, key, state.boundFrame, entry.pandemicGlow == true) end
	state.trackUnit = trackedUnit
	registerTrackedPanel(runtime, state.trackUnit, panelId)

	local auraData
	local auraUnit
	local auraInstanceID
	local targetEpoch = runtime.targetEpoch or 0
	local normalizedTrackUnit = normalizeTrackedUnit(state.trackUnit)
	local canUseTargetAuraCache = normalizedTrackUnit ~= "target" or state.targetAuraEpoch == targetEpoch
	local canAcquireFromChosenTargetFrame = normalizedTrackUnit ~= "target"
		or canUseTargetAuraCache
		or (state.targetAuraEpoch == nil and state.trackedAuraInstanceID == nil and state.mappedAuraInstanceID == nil)
	local frameMatchesTrackedSpell = false

	if chosenFrame and canAcquireFromChosenTargetFrame then frameMatchesTrackedSpell = cdm.GetCachedFrameSpellMatch(runtime, state, chosenFrame, state.trackUnit) end

	if chosenFrame and canAcquireFromChosenTargetFrame and frameMatchesTrackedSpell then
		local currentAuraData, currentAuraUnit, currentAuraID = getFrameAuraData(chosenFrame)
		if currentAuraData then
			auraData = currentAuraData
			auraUnit = currentAuraUnit
			auraInstanceID = currentAuraID or getAuraInstanceID(currentAuraData)
			if auraInstanceID then
				state.trackUnit = normalizeTrackedUnit(auraUnit) or state.trackUnit
				state.trackedAuraInstanceID = auraInstanceID
				state.trackedAuraUnit = auraUnit
				if normalizeTrackedUnit(auraUnit) == "target" then state.targetAuraEpoch = targetEpoch end
			end
		end
	end

	if not auraData and canUseTargetAuraCache and hasAuraInstanceID(state.trackedAuraInstanceID) and state.trackedAuraUnit then
		local cachedAuraData = getAuraDataByAuraInstanceIDCached(state.trackedAuraUnit, state.trackedAuraInstanceID)
		if cachedAuraData then
			auraData = cachedAuraData
			auraUnit = state.trackedAuraUnit
			auraInstanceID = state.trackedAuraInstanceID
			state.trackUnit = normalizeTrackedUnit(auraUnit) or state.trackUnit
		else
			state.trackedAuraInstanceID = nil
			state.trackedAuraUnit = nil
			state.targetAuraEpoch = nil
		end
	end

	registerAuraMapping(runtime, key, state, auraInstanceID, auraUnit)

	local hasTotemData = chosenFrame and chosenFrame.totemData ~= nil
	local active = auraData ~= nil or hasTotemData
	local trackedAuraUnit = normalizeTrackedUnit(auraUnit) or normalizedTrackUnit or normalizeTrackedUnit(state.trackedAuraUnit) or normalizeTrackedUnit(state.mappedAuraUnit)
	local pandemicActive = false
	if active and trackedAuraUnit == "target" then
		if chosenFrame and canUseTargetAuraCache and frameMatchesTrackedSpell then
			pandemicActive = frameHasPandemicState(chosenFrame)
		else
			pandemicActive = state.pandemicActive == true
		end
	end
	state.pandemicActive = pandemicActive or nil
	local iconTextureID = auraData and auraData.icon
		or getFrameIconTexture(chosenFrame)
		or entry.iconTextureID
		or (scanInfo and scanInfo.iconTextureID)
		or getSpellTexture(entry.spellID)
		or Helper.PREVIEW_ICON
	local applications = auraData and auraData.applications or nil
	local stackCount = resolveAuraStackCount(auraUnit, auraInstanceID, applications)
	local rawDuration = auraData and auraData.duration or nil
	local rawExpirationTime = auraData and auraData.expirationTime or nil
	local rawTimeMod = auraData and auraData.timeMod or 1
	local cooldownStart = 0
	local cooldownDuration = 0
	local cooldownRate = 1
	local cooldownDurationObject
	local durationActive = false

	auraInstanceID = getAuraInstanceID(auraData) or auraInstanceID
	if auraData and active and auraUnit and hasAuraInstanceID(auraInstanceID) and Api.GetAuraDuration then
		cooldownDurationObject = Api.GetAuraDuration(auraUnit, auraInstanceID)
		durationActive = cooldownDurationObject ~= nil
	end

	if not cooldownDurationObject and auraData and active and rawDuration ~= nil and rawExpirationTime ~= nil then
		if not isSecretValue(rawDuration) and not isSecretValue(rawExpirationTime) then
			local duration = tonumber(rawDuration) or 0
			local expirationTime = tonumber(rawExpirationTime) or 0
			if duration > 0 and expirationTime > 0 then
				cooldownStart = expirationTime - duration
				cooldownDuration = duration
				if cooldownStart < 0 then cooldownStart = 0 end
				cooldownRate = tonumber(rawTimeMod) or 1
			end
		end
	end

	if not cooldownDurationObject and hasTotemData then
		cooldownDurationObject = getTotemDurationObject(chosenFrame)
		if cooldownDurationObject then durationActive = true end
	end

	local fallbackAlwaysShowMode = normalizeAlwaysShowMode(entry.cdmAuraAlwaysShowMode, entry.alwaysShow == true and "SHOW" or "HIDE")
	if alwaysShowMode == nil then
		local resolvedLayout = entryLayout
		if resolvedLayout == nil then
			local panel = CooldownPanels.GetPanel and CooldownPanels:GetPanel(panelId) or nil
			resolvedLayout = panel and panel.layout or nil
		end
		alwaysShowMode = CooldownPanels.ResolveEntryCDMAuraAlwaysShowMode and CooldownPanels:ResolveEntryCDMAuraAlwaysShowMode(resolvedLayout, entry) or fallbackAlwaysShowMode
	end
	alwaysShowMode = normalizeAlwaysShowMode(alwaysShowMode, fallbackAlwaysShowMode)
	local isKnown = scanInfo and scanInfo.isKnown
	if isKnown == nil then isKnown = getCooldownInfoIsKnown(resolvedCooldownID or entry.cooldownID, chosenFrame or fallbackFrame) end
	local hideWhenInactive = alwaysShowMode == "HIDE" or alwaysShowMode == "HIDE_DESATURATE_ACTIVE"
	local show = active or (isKnown ~= false and not hideWhenInactive)
	data.show = show
	data.active = active
	data.isKnown = isKnown ~= false
	data.inactiveDesaturate = alwaysShowMode == "DESATURATE" and not active
	data.activeDesaturate = (alwaysShowMode == "DESATURATE_ACTIVE" or alwaysShowMode == "HIDE_DESATURATE_ACTIVE") and active
	data.durationActive = durationActive
	data.cooldownStart = cooldownStart
	data.cooldownDuration = cooldownDuration
	data.cooldownEnabled = durationActive
	data.cooldownRate = cooldownRate
	data.cooldownDurationObject = cooldownDurationObject
	data.cooldownID = resolvedCooldownID or entry.cooldownID
	data.spellID = entry.spellID
	data.buffName = entry.buffName or (scanInfo and scanInfo.buffName) or getSpellName(entry.spellID) or tostring(resolvedCooldownID or entry.cooldownID)
	data.iconTextureID = iconTextureID
	data.rawApplications = applications
	data.stackCount = stackCount
	data.pandemicActive = pandemicActive
	data.auraInstanceID = auraInstanceID
	data.auraUnit = auraUnit
	data.sourceType = chosenSource or preferredSource

	if state.lastActive == true and not active then requestPanelRefresh(panelId) end
	state.lastActive = active
	return data
end

function CDMAuras:GetSpellAuraOverlayInfo(spellID)
	spellID = tonumber(spellID)
	if not isUsableSpellID(spellID) then return nil end
	self:ScanTrackedBuffs(false)
	local scan = getRuntime().scan
	local info, resolvedCooldownID = findRuntimeScanInfoBySpellID(scan, spellID)
	if not (info and isValidCooldownID(resolvedCooldownID or info.cooldownID)) then return nil end
	return info, resolvedCooldownID or info.cooldownID
end

function CDMAuras:SupportsSpellAuraOverlay(spellID)
	local info = self:GetSpellAuraOverlayInfo(spellID)
	return info ~= nil
end

function CDMAuras:BuildSpellAuraOverlayData(panelId, entryId, sourceEntry, spellID, entryLayout)
	local info, resolvedCooldownID = self:GetSpellAuraOverlayInfo(spellID)
	if not (info and isValidCooldownID(resolvedCooldownID or info.cooldownID)) then return nil end
	local entry = {
		type = ENTRY_TYPE,
		cooldownID = resolvedCooldownID or info.cooldownID,
		spellID = tonumber(info.spellID) or tonumber(spellID),
		buffName = info.buffName or (sourceEntry and sourceEntry.name) or getSpellName(spellID),
		iconTextureID = info.iconTextureID or getSpellTexture(spellID),
		sourceType = normalizeSourceType(info.sourceType),
		sourceViewer = info.sourceViewer,
		cdmAuraAlwaysShowMode = "HIDE",
		cdmAuraAlwaysShowUseGlobal = false,
		alwaysShow = false,
		showCooldown = true,
		showCooldownText = sourceEntry and sourceEntry.showCooldownText ~= false,
		showStacks = sourceEntry and sourceEntry.showStacks == true,
		glowReady = false,
		pandemicGlow = false,
	}
	return self:BuildRuntimeData(panelId, entryId, entry, entryLayout, "HIDE")
end

refreshAllTrackedPanels = function(unit)
	unit = normalizeTrackedUnit(unit)
	local runtime = getRuntime()
	local refreshed = false
	if unit and runtime.unitPanels then
		local unitPanels = runtime.unitPanels[unit]
		if unitPanels then
			for panelId in pairs(unitPanels) do
				requestPanelRefresh(panelId)
				refreshed = true
			end
		end
		local unknownPanels = runtime.unitPanels.unknown
		if unknownPanels then
			for panelId in pairs(unknownPanels) do
				requestPanelRefresh(panelId)
				refreshed = true
			end
		end
	end
	if refreshed then return end

	local cdmAuraPanelIds = CooldownPanels.runtime and CooldownPanels.runtime.cdmAuraPanelIds or nil
	if cdmAuraPanelIds then
		for i = 1, #cdmAuraPanelIds do
			requestPanelRefresh(cdmAuraPanelIds[i])
		end
		return
	end

	local root = CooldownPanels.GetRoot and CooldownPanels:GetRoot() or nil
	if not (root and root.panels) then return end
	local enabledPanels = CooldownPanels.runtime and CooldownPanels.runtime.enabledPanels or nil
	local enabledPanelIds = CooldownPanels.runtime and CooldownPanels.runtime.enabledPanelIds or nil
	if enabledPanels then
		if enabledPanelIds and #enabledPanelIds > 0 then
			for i = 1, #enabledPanelIds do
				local panelId = enabledPanelIds[i]
				local panel = enabledPanels[panelId] == true and root.panels[panelId] or nil
				local entries = panel and panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							requestPanelRefresh(panelId)
							break
						end
					end
				end
			end
		else
			for panelId in pairs(enabledPanels) do
				local panel = root.panels[panelId]
				local entries = panel and panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							requestPanelRefresh(panelId)
							break
						end
					end
				end
			end
		end
	else
		for panelId, panel in pairs(root.panels) do
			if panel and panel.enabled ~= false then
				local entries = panel.entries
				if entries then
					for _, entry in pairs(entries) do
						if entry and entry.type == ENTRY_TYPE then
							requestPanelRefresh(panelId)
							break
						end
					end
				end
			end
		end
	end
end

function CDMAuras:ScheduleTrackedPanelsRescan(reason)
	local runtime = getRuntime()
	runtime.pendingRescanRefresh = runtime.pendingRescanRefresh or {}
	local pending = runtime.pendingRescanRefresh
	pending.reason = pending.reason or reason
	if pending.queued == true then return end
	pending.queued = true
	RunNextFrame(function()
		local latestRuntime = getRuntime()
		local latestPending = latestRuntime.pendingRescanRefresh
		latestRuntime.pendingRescanRefresh = nil
		if not CDMAuras:HasActiveTrackedPanels() then return end
		CDMAuras:InvalidateScan(false, latestPending and latestPending.reason or reason or "TrackedPanelsRescan")
		clearTrackedPanelIndex(latestRuntime)
		refreshAllTrackedPanels()
	end)
end

function CDMAuras:SchedulePostResetSettlement(event, reason)
	if event ~= "ADDON_LOADED" and event ~= "PLAYER_LOGIN" and event ~= "PLAYER_ENTERING_WORLD" then return end
	local runtime = getRuntime()
	runtime.pendingPostResetSettlement = runtime.pendingPostResetSettlement or {}
	local pending = runtime.pendingPostResetSettlement
	pending.reason = pending.reason or reason
	if pending.queued == true then return end
	pending.queued = true
	C_Timer.After(0.5, function()
		local latestRuntime = getRuntime()
		local latestPending = latestRuntime.pendingPostResetSettlement
		latestRuntime.pendingPostResetSettlement = nil
		if not CDMAuras:HasActiveTrackedPanels() then return end
		CDMAuras:InvalidateScan(true, latestPending and latestPending.reason or reason or "PostResetSettlement")
		clearTrackedPanelIndex(latestRuntime)
		refreshAllTrackedPanels()
	end)
end

function CDMAuras:EnsureCooldownViewerHooks()
	local runtime = getRuntime()
	local installed = false
	local cooldownViewerItemDataMixin = _G.CooldownViewerItemDataMixin
	if cooldownViewerItemDataMixin and cooldownViewerItemDataMixin.SetCooldownID and not runtime.cooldownViewerSetHookInstalled then
		hooksecurefunc(cooldownViewerItemDataMixin, "SetCooldownID", function(itemFrame, cooldownID)
			local previousCooldownID = itemFrame and itemFrame._eqolLastTrackedCooldownID or nil
			itemFrame._eqolLastTrackedCooldownID = cooldownID
			if not self:HasActiveTrackedPanels() then return end
			if previousCooldownID ~= nil and cooldownIDsEqual(previousCooldownID, cooldownID) then return end
			self:ScheduleTrackedPanelsRescan("SetCooldownID", itemFrame)
		end)
		runtime.cooldownViewerSetHookInstalled = true
		installed = true
	end
	if cooldownViewerItemDataMixin and cooldownViewerItemDataMixin.ClearCooldownID and not runtime.cooldownViewerClearHookInstalled then
		hooksecurefunc(cooldownViewerItemDataMixin, "ClearCooldownID", function(itemFrame)
			local previousCooldownID = itemFrame and itemFrame._eqolLastTrackedCooldownID or itemFrame and itemFrame.cooldownID or nil
			if itemFrame then itemFrame._eqolLastTrackedCooldownID = nil end
			if not self:HasActiveTrackedPanels() then return end
			if previousCooldownID == nil then return end
			self:ScheduleTrackedPanelsRescan("ClearCooldownID", itemFrame)
		end)
		runtime.cooldownViewerClearHookInstalled = true
		installed = true
	end
	if EventRegistry and EventRegistry.RegisterCallback and not runtime.cooldownViewerDataChangedHookInstalled then
		EventRegistry:RegisterCallback("CooldownViewerSettings.OnDataChanged", function()
			if not self:HasActiveTrackedPanels() then return end
			self:ScheduleTrackedPanelsRescan("CooldownViewerSettings.OnDataChanged")
		end, "EnhanceQoL.CDMAuras")
		runtime.cooldownViewerDataChangedHookInstalled = true
		installed = true
	end
	runtime.cooldownViewerHooksInstalled = installed == true
		or runtime.cooldownViewerSetHookInstalled == true
		or runtime.cooldownViewerClearHookInstalled == true
		or runtime.cooldownViewerDataChangedHookInstalled == true
	return runtime.cooldownViewerHooksInstalled == true
end

local function clearTrackedUnitAuraIndex(unit)
	unit = normalizeTrackedUnit(unit)
	if not unit then return end
	local runtime = getRuntime()
	wipe(runtime.auraEntries[unit])
end

function CDMAuras:HandleUnitAura(_, unit, updateInfo)
	unit = normalizeTrackedUnit(unit)
	if not unit then return end
	local runtime = getRuntime()
	cdm.BumpUnitAuraEpoch(runtime, unit)
	local auraEntries = runtime.auraEntries[unit]
	if not (auraEntries and next(auraEntries) ~= nil) then return end

	if not updateInfo or updateInfo.isFullUpdate then
		refreshAllTrackedPanels(unit)
		return
	end

	local panelsToRefresh = runtime.scratchRefreshedPanels
	wipe(panelsToRefresh)

	if updateInfo.updatedAuraInstanceIDs then
		for _, auraID in ipairs(updateInfo.updatedAuraInstanceIDs) do
			local mapped = auraEntries[auraID]
			if mapped then
				for key in pairs(mapped) do
					local state = runtime.entryStates[key]
					if state then panelsToRefresh[state.panelId] = true end
				end
			end
		end
	end

	if updateInfo.removedAuraInstanceIDs then
		for _, auraID in ipairs(updateInfo.removedAuraInstanceIDs) do
			local mapped = auraEntries[auraID]
			if mapped then
				for key in pairs(mapped) do
					local state = runtime.entryStates[key]
					if state then
						if state.trackedAuraInstanceID == auraID and normalizeTrackedUnit(state.trackedAuraUnit) == unit then
							state.trackedAuraInstanceID = nil
							state.trackedAuraUnit = nil
							state.pandemicActive = nil
							if unit == "target" then state.targetAuraEpoch = nil end
						end
						state.mappedAuraInstanceID = nil
						state.mappedAuraUnit = nil
						panelsToRefresh[state.panelId] = true
					end
				end
				auraEntries[auraID] = nil
			end
		end
	end

	for panelId in pairs(panelsToRefresh) do
		requestPanelRefresh(panelId)
		panelsToRefresh[panelId] = nil
	end
end

function CDMAuras:HandleTargetChanged()
	local runtime = getRuntime()
	runtime.targetEpoch = (runtime.targetEpoch or 0) + 1
	cdm.BumpUnitAuraEpoch(runtime, "target")
	clearTrackedUnitAuraIndex("target")
	refreshAllTrackedPanels("target")
end

function CDMAuras:HandleResetEvent(event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= "Blizzard_CooldownViewer" then return end
	end
	if event == "PLAYER_SPECIALIZATION_CHANGED" then
		local unit = ...
		if unit and unit ~= "player" then return end
	end
	if not self:HasActiveTrackedPanels() then return end
	local runtime = getRuntime()
	local reason = "HandleResetEvent:" .. tostring(event)
	self:EnsureCooldownViewerHooks()
	self:InvalidateScan(true, reason)
	self:SweepInvalidStates()
	cdm.BumpUnitAuraEpoch(runtime, "player")
	cdm.BumpUnitAuraEpoch(runtime, "target")
	cdm.ResetPersistentFrameCaches(runtime)
	for key, state in pairs(runtime.entryStates) do
		clearEntryState(key, state, true)
	end
	clearTrackedPanelIndex(runtime)
	refreshAllTrackedPanels()
	self:SchedulePostResetSettlement(event, reason)
end

function CDMAuras:HandleTotemUpdate() refreshAllTrackedPanels("player") end

function CDMAuras:EnsureEventFrame()
	if self.eventFrame then return end
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(_, event, ...)
		if event == "UNIT_AURA" then
			CDMAuras:HandleUnitAura(event, ...)
		elseif event == "PLAYER_TARGET_CHANGED" then
			CDMAuras:HandleTargetChanged(event, ...)
		elseif event == "PLAYER_TOTEM_UPDATE" then
			CDMAuras:HandleTotemUpdate(event, ...)
		else
			CDMAuras:HandleResetEvent(event, ...)
		end
	end)
	self.eventFrame = frame
end
