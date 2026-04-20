local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local EditMode = addon.EditMode

local ResourceBars = addon.Aura and addon.Aura.ResourceBars
if not ResourceBars then return end

local MIN_RESOURCE_BAR_WIDTH = (ResourceBars and ResourceBars.MIN_RESOURCE_BAR_WIDTH) or 10
local THRESHOLD_THICKNESS = (ResourceBars and ResourceBars.THRESHOLD_THICKNESS) or 1
local THRESHOLD_DEFAULT = (ResourceBars and ResourceBars.THRESHOLD_DEFAULT) or { 1, 1, 1, 0.5 }
local DEFAULT_THRESHOLDS = (ResourceBars and ResourceBars.DEFAULT_THRESHOLDS) or { 25, 50, 75, 90 }
local DEFAULT_THRESHOLD_COUNT = (ResourceBars and ResourceBars.DEFAULT_THRESHOLD_COUNT) or 3
local ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS) or 10
local ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT) or 2
local ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP) or 10
local ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_VOID_METAMORPHOSIS = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_VOID_METAMORPHOSIS) or 50
local ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_CONTINUOUS = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_CONTINUOUS) or 200
local ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_PERCENT = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_PERCENT) or 100
local ABSOLUTE_THRESHOLD_COLOR_DEFAULTS = (ResourceBars and ResourceBars.ABSOLUTE_THRESHOLD_COLOR_DEFAULTS)
	or {
		{ value = 2, color = { 1.00, 0.78, 0.25, 1.0 } },
		{ value = 4, color = { 0.95, 0.55, 0.20, 1.0 } },
		{ value = 6, color = { 0.95, 0.90, 0.20, 1.0 } },
		{ value = 8, color = { 0.45, 0.90, 0.25, 1.0 } },
		{ value = 10, color = { 0.20, 0.90, 0.40, 1.0 } },
	}
local MAELSTROM_WEAPON_SEGMENTS = (ResourceBars and ResourceBars.MAELSTROM_WEAPON_SEGMENTS) or 5
local MAELSTROM_WEAPON_MAX_STACKS = (ResourceBars and ResourceBars.MAELSTROM_WEAPON_MAX_STACKS) or 10
local MAELSTROM_MID_STACK_DEFAULT = (ResourceBars and ResourceBars.MAELSTROM_WEAPON_MID_STACK_DEFAULT) or MAELSTROM_WEAPON_SEGMENTS
local MAELSTROM_MID_STACK_MAX = math.max(1, MAELSTROM_WEAPON_MAX_STACKS - 1)
local ROGUE_CHARGED_COMBO_DEFAULTS = (ResourceBars and ResourceBars.ROGUE_CHARGED_COMBO_DEFAULTS)
	or {
		enabled = true,
		affectFill = true,
		affectBackground = true,
		fillUseCustomColor = false,
		fillColor = { 1.0, 0.95, 0.45, 1.0 },
		fillLighten = 0.35,
		fillAlphaBoost = 0.10,
		backgroundUseCustomColor = false,
		backgroundColor = { 0.75, 0.60, 0.25, 0.75 },
		backgroundLighten = 0.30,
		backgroundAlphaBoost = 0.10,
	}
local STAGGER_EXTRA_THRESHOLD_HIGH = (ResourceBars and ResourceBars.STAGGER_EXTRA_THRESHOLD_HIGH) or 200
local STAGGER_EXTRA_THRESHOLD_VERY_HIGH = (ResourceBars and ResourceBars.STAGGER_EXTRA_THRESHOLD_VERY_HIGH) or 250
local STAGGER_EXTRA_THRESHOLD_EXTREME = (ResourceBars and ResourceBars.STAGGER_EXTRA_THRESHOLD_EXTREME) or 300
local STAGGER_EXTRA_THRESHOLD_CRITICAL = (ResourceBars and ResourceBars.STAGGER_EXTRA_THRESHOLD_CRITICAL) or 350
local STAGGER_LOW_THRESHOLD = (ResourceBars and ResourceBars.STAGGER_LOW_THRESHOLD) or 30
local STAGGER_MEDIUM_THRESHOLD = (ResourceBars and ResourceBars.STAGGER_MEDIUM_THRESHOLD) or 60
local STAGGER_THRESHOLD_MAX = (ResourceBars and ResourceBars.STAGGER_THRESHOLD_MAX) or 1000
local STAGGER_EXTRA_COLORS = (ResourceBars and ResourceBars.STAGGER_EXTRA_COLORS)
	or {
		high = { 0.62, 0.2, 1, 1 },
		veryHigh = { 0.85, 0.2, 1, 1 },
		extreme = { 1, 0.2, 0.8, 1 },
		critical = { 1, 0.1, 0.45, 1 },
	}
local STAGGER_FALLBACK_COLORS = (ResourceBars and ResourceBars.STAGGER_FALLBACK_COLORS)
	or {
		green = { 0.52, 1.0, 0.52, 1 },
		yellow = { 1.0, 0.98, 0.72, 1 },
		red = { 1.0, 0.42, 0.42, 1 },
	}
local SMF = addon.SharedMedia and addon.SharedMedia.functions
local EQOL_RUNES_BORDER = (ResourceBars and ResourceBars.RUNE_BORDER_ID) or "EQOL_BORDER_RUNES"
local EQOL_RUNES_BORDER_LABEL = (ResourceBars and ResourceBars.RUNE_BORDER_LABEL) or (SMF and SMF.GetCustomBorder and (SMF.GetCustomBorder(EQOL_RUNES_BORDER) or {}).label) or "EQOL: Runes"
local function customBorderOptions()
	if SMF and SMF.GetCustomBorderOptions then return SMF.GetCustomBorderOptions() end
	if ResourceBars and ResourceBars.GetCustomBorderOptions then return ResourceBars.GetCustomBorderOptions() end
	return nil
end
local AUTO_ENABLE_OPTIONS = {
	HEALTH = L["Health"] or "Health",
	MAIN = L["AutoEnableMain"] or "Main resource",
	SECONDARY = L["AutoEnableSecondary"] or "Secondary resources",
}
local AUTO_ENABLE_ORDER = { "HEALTH", "MAIN", "SECONDARY" }
local RESOURCE_MODE_OPTIONS = {
	SPEC = L["ResourceBarsModeSpec"] or "Classic",
	SHARED = L["ResourceBarsModeShared"] or "Shared",
}
local RESOURCE_MODE_ORDER = { "SPEC", "SHARED" }
local FRAME_STRATA_ORDER = (ResourceBars and ResourceBars.STRATA_ORDER)
	or { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local MAX_FRAME_LEVEL_OFFSET = (ResourceBars and ResourceBars.MAX_FRAME_LEVEL_OFFSET) or 50
local VALID_FRAME_STRATA = {}
local FRAME_STRATA_VALUES = { { value = "", text = DEFAULT or "Default" } }
for _, strata in ipairs(FRAME_STRATA_ORDER) do
	VALID_FRAME_STRATA[strata] = true
	FRAME_STRATA_VALUES[#FRAME_STRATA_VALUES + 1] = { value = strata, text = strata }
end

local function getCachedLSMMedia(mediaType)
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType)
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash(mediaType)
	if type(names) == "table" and type(hash) == "table" then return names, hash end
	return {}, {}
end

local specSettingVars = {}
local specModeSettingVars = {}
local function getActiveSpecIndex()
	local apiSpec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	if apiSpec and apiSpec > 0 then return apiSpec end
	return addon.variables and addon.variables.unitSpec
end

local function getSpecMode(specIndex)
	if ResourceBars and ResourceBars.GetSpecMode then return ResourceBars.GetSpecMode(specIndex) end
	return "SPEC"
end

local function setSpecMode(specIndex, mode)
	if not (ResourceBars and ResourceBars.SetSpecMode) then return false end
	return ResourceBars.SetSpecMode(specIndex, mode)
end

local function setSpecModeForClass(classTag, specIndex, mode)
	if ResourceBars and ResourceBars.SetClassMode then return ResourceBars.SetClassMode(classTag, mode) end
	if not classTag then return false end
	addon.db.personalResourceBarSettings = addon.db.personalResourceBarSettings or {}
	addon.db.personalResourceBarSettings[classTag] = addon.db.personalResourceBarSettings[classTag] or {}
	addon.db.personalResourceBarSettings[classTag]._mode = (ResourceBars and ResourceBars.NormalizeSpecMode and ResourceBars.NormalizeSpecMode(mode)) or mode or "SPEC"
	return true
end

local function autoEnableSelection()
	addon.db.resourceBarsAutoEnable = addon.db.resourceBarsAutoEnable or {}
	-- Migrate legacy boolean flag into the new selection map
	if addon.db.resourceBarsAutoEnableAll ~= nil then
		if addon.db.resourceBarsAutoEnableAll == true and not next(addon.db.resourceBarsAutoEnable) then addon.db.resourceBarsAutoEnable = { HEALTH = true, MAIN = true, SECONDARY = true } end
		addon.db.resourceBarsAutoEnableAll = nil
	end
	return addon.db.resourceBarsAutoEnable
end

local function shouldAutoEnableBar(pType, specInfo, selection)
	if not selection then return false end
	if pType == "HEALTH" then return selection.HEALTH == true end
	if specInfo and specInfo.MAIN == pType then return selection.MAIN == true end
	if specInfo and pType ~= specInfo.MAIN and pType ~= "HEALTH" then return specInfo[pType] == true and selection.SECONDARY == true end
	return false
end

local function maybeAutoEnableBars(specIndex, specCfg)
	if not specCfg or specCfg._autoEnabled then return end
	if getSpecMode(specIndex) == "SHARED" then return end
	local selection = autoEnableSelection()
	if not selection or not (selection.HEALTH or selection.MAIN or selection.SECONDARY) then return end

	-- Skip if user already touched enable state
	for _, cfg in pairs(specCfg) do
		if type(cfg) == "table" and cfg.enabled ~= nil then return end
	end

	local class = addon.variables.unitClass
	if not class or not specIndex then return end
	local specInfo = ResourceBars and ResourceBars.powertypeClasses and ResourceBars.powertypeClasses[class] and ResourceBars.powertypeClasses[class][specIndex]
	if not specInfo then return end

	local bars = {}
	local mainType = specInfo.MAIN
	if selection.HEALTH then bars[#bars + 1] = "HEALTH" end
	if selection.MAIN and mainType then bars[#bars + 1] = mainType end
	if selection.SECONDARY then
		for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
			if specInfo[pType] and pType ~= mainType and pType ~= "HEALTH" then bars[#bars + 1] = pType end
		end
	end
	if #bars == 0 then return end

	local function frameNameFor(typeId)
		if typeId == "HEALTH" then return "EQOLHealthBar" end
		return "EQOL" .. tostring(typeId) .. "Bar"
	end

	local prevFrame = selection.HEALTH and frameNameFor("HEALTH") or nil
	local mainFrame = frameNameFor(mainType or "HEALTH")
	local applied = 0
	for _, pType in ipairs(bars) do
		if shouldAutoEnableBar(pType, specInfo, selection) then
			specCfg[pType] = specCfg[pType] or {}
			local ok = false
			if ResourceBars.ApplyGlobalProfile then ok = ResourceBars.ApplyGlobalProfile(pType, specIndex, false) end
			-- Fallback for fresh profiles/new chars without any saved global template yet.
			if not ok then
				specCfg[pType]._rbType = pType
				ok = true
			end
			if ok then
				applied = applied + 1
				specCfg[pType].enabled = true
				if pType == mainType and pType ~= "HEALTH" then
					local a = specCfg[pType].anchor or {}
					local explicitRelative = type(a.relativeFrame) == "string" and a.relativeFrame ~= ""
					local targetFrame = explicitRelative and a.relativeFrame or frameNameFor("HEALTH")
					if not selection.HEALTH and targetFrame == frameNameFor("HEALTH") and not explicitRelative then targetFrame = nil end
					if not explicitRelative and targetFrame and targetFrame ~= "" and targetFrame ~= "UIParent" then
						a.point = "TOPLEFT"
						a.relativePoint = "BOTTOMLEFT"
						a.relativeFrame = targetFrame
						a.x = 0
						a.y = (ResourceBars and ResourceBars.DEFAULT_STACK_SPACING) or 0
						a.autoSpacing = true
						a.matchRelativeWidth = a.matchRelativeWidth or true
					else
						a.point = a.point or "CENTER"
						a.relativePoint = a.relativePoint or "CENTER"
						a.relativeFrame = targetFrame
						a.x = a.x or 0
						a.y = a.y or -2
						a.autoSpacing = a.autoSpacing or nil
						a.matchRelativeWidth = a.matchRelativeWidth or true
					end
					specCfg[pType].anchor = a
					prevFrame = frameNameFor(pType)
				elseif pType ~= "HEALTH" then
					local a = specCfg[pType].anchor or {}
					local explicitRelative = type(a.relativeFrame) == "string" and a.relativeFrame ~= ""
					local targetFrame = explicitRelative and a.relativeFrame or nil
					if not explicitRelative then
						targetFrame = frameNameFor("HEALTH")
						if class == "DRUID" then
							if pType == "COMBO_POINTS" then
								targetFrame = frameNameFor("ENERGY")
							else
								targetFrame = prevFrame
							end
							if not targetFrame or targetFrame == "" then targetFrame = prevFrame or (selection.MAIN and mainFrame or nil) end
						else
							targetFrame = prevFrame
						end
					end
					local chained = (not explicitRelative) and targetFrame and targetFrame ~= "" and targetFrame ~= "UIParent"
					if chained then
						a.point = "TOPLEFT"
						a.relativePoint = "BOTTOMLEFT"
						a.relativeFrame = targetFrame
						a.x = 0
						a.y = (ResourceBars and ResourceBars.DEFAULT_STACK_SPACING) or 0
						a.autoSpacing = true
						a.matchRelativeWidth = a.matchRelativeWidth or true
					else
						a.point = a.point or "CENTER"
						a.relativePoint = a.relativePoint or "CENTER"
						a.x = a.x or 0
						if not explicitRelative then a.relativeFrame = targetFrame end
						a.autoSpacing = a.autoSpacing or nil
					end
					specCfg[pType].anchor = a
					if class ~= "DRUID" then prevFrame = frameNameFor(pType) end
				else
					prevFrame = frameNameFor(pType)
				end
			end
		end
	end

	if applied > 0 then specCfg._autoEnabled = true end
end

local function toColorComponents(c, fallback)
	c = c or fallback or {}
	if c.r then return c.r or 1, c.g or 1, c.b or 1, c.a or 1 end
	return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
end

local function toColorArray(value, fallback)
	local r, g, b, a = toColorComponents(value, fallback)
	return { r, g, b, a }
end

local function toUIColor(value, fallback)
	local r, g, b, a = toColorComponents(value, fallback)
	return { r = r, g = g, b = b, a = a }
end

local function globalFontDefaultPath()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
end

local function globalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function globalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

local function normalizeFontStyleChoice(value, fallback)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, fallback, true)
	end
	if value ~= nil then return value end
	return fallback or "OUTLINE"
end

local function getFontStyleEntries()
	local list = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true) or {
		{ value = "NONE", label = NONE },
		{ value = "OUTLINE", label = L["Outline"] or "Outline" },
	}
	local entries = {}
	for i = 1, #list do
		entries[#entries + 1] = {
			key = list[i].value,
			label = list[i].label,
		}
	end
	return entries
end

local function resolveStatusbarPreviewPath(key)
	if not key then return nil end
	if key == "DEFAULT" then return (ResourceBars and ResourceBars.DEFAULT_RB_TEX) or "Interface\\Buttons\\WHITE8x8" end
	return type(key) == "string" and key or nil
end

local function ensureDropdownTexturePreview(dropdown)
	if not dropdown then return end
	dropdown.texturePool = dropdown.texturePool or {}
	if dropdown._eqolTexturePreviewHooked or not dropdown.OnMenuClosed then return end
	hooksecurefunc(dropdown, "OnMenuClosed", function()
		for _, texture in pairs(dropdown.texturePool) do
			texture:Hide()
		end
	end)
	dropdown._eqolTexturePreviewHooked = true
end

local function attachDropdownTexturePreview(dropdown, button, index, texturePath)
	if not dropdown or not button or not texturePath then return end
	local tex = dropdown.texturePool[index]
	if not tex then
		tex = dropdown:CreateTexture(nil, "BACKGROUND")
		dropdown.texturePool[index] = tex
	end
	tex:SetParent(button)
	tex:SetAllPoints(button)
	tex:SetTexture(texturePath)
	tex:Show()
end

local function setIfChanged(tbl, key, value)
	if not tbl then return false end
	if tbl[key] == value then return false end
	tbl[key] = value
	return true
end

local function normalizeFrameStrataValue(value)
	if type(value) ~= "string" or value == "" then return "" end
	local upper = string.upper(value)
	if VALID_FRAME_STRATA[upper] then return upper end
	return ""
end

local function notifyResourceBarSettings()
	if not Settings or not Settings.NotifyUpdate then return end
	Settings.NotifyUpdate("EQOL_enableResourceFrame")
	Settings.NotifyUpdate("EQOL_resourceBarsSharedEnabled")
	Settings.NotifyUpdate("EQOL_resourceBarsHideOutOfCombat")
	Settings.NotifyUpdate("EQOL_resourceBarsHideMounted")
	Settings.NotifyUpdate("EQOL_resourceBarsHideVehicle")
	Settings.NotifyUpdate("EQOL_resourceBarsHidePetBattle")
	Settings.NotifyUpdate("EQOL_resourceBarsHideClientScene")
	for var in pairs(specSettingVars) do
		Settings.NotifyUpdate("EQOL_" .. var)
	end
	for var in pairs(specModeSettingVars) do
		Settings.NotifyUpdate("EQOL_" .. var)
	end
end

local function applyResourceBarsVisibility(context)
	if ResourceBars and ResourceBars.ApplyVisibilityPreference then ResourceBars.ApplyVisibilityPreference(context or "settings") end
end
local function ensureSpecCfg(specIndex)
	local class = addon.variables.unitClass
	if not class or not specIndex then return end
	addon.db.personalResourceBarSettings = addon.db.personalResourceBarSettings or {}
	addon.db.personalResourceBarSettings[class] = addon.db.personalResourceBarSettings[class] or {}
	addon.db.personalResourceBarSettings[class][specIndex] = addon.db.personalResourceBarSettings[class][specIndex] or {}
	local specCfg = addon.db.personalResourceBarSettings[class][specIndex]
	specCfg._mode = (ResourceBars and ResourceBars.GetSpecMode and ResourceBars.GetSpecMode(specIndex)) or specCfg._mode or "SHARED"
	maybeAutoEnableBars(specIndex, specCfg)
	return specCfg
end

local function refreshSettingsUI()
	local lib = addon.EditModeLib
	if lib and lib.internal and lib.internal.RefreshSettings then lib.internal:RefreshSettings() end
	if lib and lib.internal and lib.internal.RefreshSettingValues then lib.internal:RefreshSettingValues() end
end

local registerEditModeBars
local unregisterEditModeBars

local function hideSharedSlotProxyFrames()
	if not (ResourceBars and ResourceBars.GetSharedSlotFrameName) then return end
	for _, slot in ipairs(ResourceBars.SHARED_SLOT_ORDER or {}) do
		local frameName = ResourceBars.GetSharedSlotFrameName(slot)
		local frame = frameName and _G[frameName]
		if frame then
			frame._rbDesiredVisible = false
			frame._rbManualVisibilityHidden = nil
			frame:Hide()
		end
	end
end

unregisterEditModeBars = function()
	local registeredFrames = ResourceBars and ResourceBars._editModeRegisteredFrames or {}
	local registeredByBar = ResourceBars and ResourceBars._editModeRegisteredFrameByBar or {}
	local registeredFrameNameByBar = ResourceBars and ResourceBars._editModeRegisteredFrameNameByBar or {}

	if EditMode and EditMode.UnregisterFrame then
		local seen = {}
		for _, frameId in pairs(registeredByBar) do
			if frameId and not seen[frameId] then
				EditMode:UnregisterFrame(frameId, false)
				seen[frameId] = true
			end
		end
	end

	for key in pairs(registeredFrames) do
		registeredFrames[key] = nil
	end
	for key in pairs(registeredByBar) do
		registeredByBar[key] = nil
	end
	for key in pairs(registeredFrameNameByBar) do
		registeredFrameNameByBar[key] = nil
	end

	if ResourceBars then ResourceBars._editModeRegistered = false end
	hideSharedSlotProxyFrames()
end

local function setBarEnabled(specIndex, barType, enabled)
	local specCfg = ensureSpecCfg(specIndex)
	if not specCfg then return end
	specCfg[barType] = specCfg[barType] or {}
	local cfg = specCfg[barType]
	if enabled and not cfg._init and ResourceBars and ResourceBars.ApplyGlobalProfile then
		local ok = ResourceBars.ApplyGlobalProfile(barType, specIndex)
		if ok then cfg._appliedFromGlobal = true end
		cfg._init = true
	end
	specCfg[barType].enabled = enabled and true or false
	if barType == "HEALTH" then
		if enabled then
			ResourceBars.SetHealthBarSize(specCfg[barType].width or ResourceBars.DEFAULT_HEALTH_WIDTH or 200, specCfg[barType].height or ResourceBars.DEFAULT_HEALTH_HEIGHT or 20)
		else
			ResourceBars.DetachAnchorsFrom("HEALTH", specIndex)
		end
	else
		if enabled then
			ResourceBars.SetPowerBarSize(specCfg[barType].width or ResourceBars.DEFAULT_POWER_WIDTH or 200, specCfg[barType].height or ResourceBars.DEFAULT_POWER_HEIGHT or 20, barType)
		else
			ResourceBars.DetachAnchorsFrom(barType, specIndex)
		end
	end
	if ResourceBars.QueueRefresh then ResourceBars.QueueRefresh(specIndex) end
	if ResourceBars.MaybeRefreshActive then ResourceBars.MaybeRefreshActive(specIndex) end
	if EditMode and EditMode.RefreshFrame then
		local curSpec = tonumber(specIndex or getActiveSpecIndex()) or 0
		local id = (ResourceBars.GetEditModeFrameId and ResourceBars.GetEditModeFrameId(barType, addon.variables.unitClass, curSpec))
			or ("resourceBar_" .. tostring(addon.variables.unitClass or "UNKNOWN") .. "_" .. tostring(curSpec) .. "_" .. tostring(barType))
		local layout = EditMode.GetActiveLayoutName and EditMode:GetActiveLayoutName()
		EditMode:RefreshFrame(id, layout)
	end
	if EditMode and EditMode:IsInEditMode() then
		if ResourceBars.Refresh then ResourceBars.Refresh() end
		if ResourceBars.ReanchorAll then ResourceBars.ReanchorAll() end
	end
end

local function isSharedSlotEnabled(slot)
	if not ResourceBars or not ResourceBars.EnsureSharedSlotStore then return true end
	local cfg = ResourceBars.EnsureSharedSlotStore(slot)
	return cfg and cfg.enabled == true or false
end

local function setSharedSlotEnabled(slot, enabled)
	if not ResourceBars or not ResourceBars.EnsureSharedSlotStore then return end
	local cfg = ResourceBars.EnsureSharedSlotStore(slot)
	if not cfg then return end
	cfg.enabled = enabled and true or false

	local specIndex = getActiveSpecIndex()
	if specIndex then
		if ResourceBars.QueueRefresh then ResourceBars.QueueRefresh(specIndex) end
		if ResourceBars.MaybeRefreshActive then ResourceBars.MaybeRefreshActive(specIndex) end
		if specIndex == addon.variables.unitSpec and ResourceBars.Refresh then ResourceBars.Refresh() end
		if EditMode and EditMode.RefreshFrame then
			local frameId = (ResourceBars.GetEditModeFrameId and ResourceBars.GetEditModeFrameId(slot, addon.variables.unitClass, specIndex))
				or ("resourceBar_" .. tostring(addon.variables.unitClass or "UNKNOWN") .. "_" .. tostring(specIndex) .. "_" .. tostring(slot))
			local layout = EditMode.GetActiveLayoutName and EditMode:GetActiveLayoutName()
			EditMode:RefreshFrame(frameId, layout)
		end
	end

	if EditMode and EditMode:IsInEditMode() then
		if ResourceBars.Refresh then ResourceBars.Refresh() end
		if ResourceBars.ReanchorAll then ResourceBars.ReanchorAll() end
	end

	refreshSettingsUI()
	registerEditModeBars()
end

registerEditModeBars = function()
	if not EditMode or not EditMode.RegisterFrame then return end
	if addon and addon.db and addon.db.enableResourceFrame == false then
		unregisterEditModeBars()
		return
	end
	local registered = 0
	local registeredFrames = ResourceBars._editModeRegisteredFrames or {}
	local registeredByBar = ResourceBars._editModeRegisteredFrameByBar or {}
	local registeredFrameNameByBar = ResourceBars._editModeRegisteredFrameNameByBar or {}
	ResourceBars._editModeRegisteredFrames = registeredFrames
	ResourceBars._editModeRegisteredFrameByBar = registeredByBar
	ResourceBars._editModeRegisteredFrameNameByBar = registeredFrameNameByBar

	local function registerBar(idSuffix, frameName, barType, widthDefault, heightDefault, opts)
		opts = opts or {}
		local sharedSlot = opts.sharedSlot
		local genericSharedPowerEditor = sharedSlot and sharedSlot ~= "HEALTH"
		local frame
		if sharedSlot and sharedSlot ~= "HEALTH" and ResourceBars and ResourceBars.SyncSharedSlotProxyFrame then
			ResourceBars.SyncSharedSlotProxyFrame(sharedSlot, getActiveSpecIndex())
		end
		if sharedSlot and sharedSlot ~= "HEALTH" and ResourceBars and ResourceBars.EnsureSharedSlotProxyFrame then
			frame = ResourceBars.EnsureSharedSlotProxyFrame(sharedSlot)
		else
			frame = _G[frameName]
		end
		if not frame then return end
		local actualFrameName = (frame.GetName and frame:GetName()) or frameName
		local curSpec = tonumber(getActiveSpecIndex()) or 0
		local registeredSpec = curSpec
		local frameId = (ResourceBars.GetEditModeFrameId and ResourceBars.GetEditModeFrameId(idSuffix, addon.variables.unitClass, registeredSpec))
			or ("resourceBar_" .. tostring(addon.variables.unitClass or "UNKNOWN") .. "_" .. tostring(curSpec) .. "_" .. tostring(idSuffix))
		local prevId = registeredByBar[idSuffix]
		local prevFrameName = registeredFrameNameByBar[idSuffix]
		local existingEntry = EditMode and EditMode.frames and EditMode.frames[frameId] or nil
		local existingFrame = existingEntry and existingEntry.frame or nil
		if prevId and prevId ~= frameId and EditMode and EditMode.UnregisterFrame then
			EditMode:UnregisterFrame(prevId, false)
			registeredFrames[prevId] = nil
		end
		if prevId == frameId and EditMode and EditMode.UnregisterFrame and ((prevFrameName and prevFrameName ~= actualFrameName) or (existingFrame and existingFrame ~= frame)) then
			EditMode:UnregisterFrame(frameId, false)
			registeredFrames[frameId] = nil
		end
		if registeredFrames[frameId] and existingFrame == frame then return end
		registeredByBar[idSuffix] = frameId
		registeredFrameNameByBar[idSuffix] = actualFrameName
		local function currentLiveBarType()
			local spec = registeredSpec or getActiveSpecIndex()
			if sharedSlot and ResourceBars and ResourceBars.GetResolvedBarTypeForSharedSlot then return ResourceBars.GetResolvedBarTypeForSharedSlot(sharedSlot, spec) end
			return barType
		end
		local specCfg = ensureSpecCfg(registeredSpec) or {}
		local cfg = sharedSlot and ResourceBars and ResourceBars.EnsureSharedSlotStore and ResourceBars.EnsureSharedSlotStore(sharedSlot) or specCfg[barType]
		if not cfg and ResourceBars and ResourceBars.getBarSettings then cfg = ResourceBars.getBarSettings(barType) end
		if not cfg and ResourceBars and ResourceBars.GetBarSettings then cfg = ResourceBars.GetBarSettings(barType) end
		local anchorTargetType = sharedSlot or currentLiveBarType() or barType
		local anchor = ResourceBars and ResourceBars.getAnchor and ResourceBars.getAnchor(anchorTargetType, registeredSpec)
		local titleLabel = opts.titleLabel
			or ((barType == "HEALTH") and (HEALTH or "Health") or (ResourceBars.PowerLabels and ResourceBars.PowerLabels[barType]) or _G["POWER_TYPE_" .. barType] or _G[barType] or barType)
		local function currentSpecInfo()
			local uc = addon.variables.unitClass
			local us = registeredSpec or getActiveSpecIndex()
			return ResourceBars and ResourceBars.powertypeClasses and ResourceBars.powertypeClasses[uc] and ResourceBars.powertypeClasses[uc][us]
		end

		-- Ensure backdrop defaults for current spec view
		cfg = cfg or {}
		cfg.backdrop = cfg.backdrop or {}
		if cfg.backdrop.enabled == nil then cfg.backdrop.enabled = true end
		cfg.backdrop.backgroundTexture = cfg.backdrop.backgroundTexture or "Interface\\DialogFrame\\UI-DialogBox-Background"
		cfg.backdrop.backgroundColor = cfg.backdrop.backgroundColor or { 0, 0, 0, 0.8 }
		cfg.backdrop.borderTexture = cfg.backdrop.borderTexture or "Interface\\Tooltips\\UI-Tooltip-Border"
		cfg.backdrop.borderColor = cfg.backdrop.borderColor or { 0, 0, 0, 0 }
		cfg.backdrop.edgeSize = cfg.backdrop.edgeSize or 3
		cfg.backdrop.outset = cfg.backdrop.outset or 0
		cfg.backdrop.backgroundInset = max(0, cfg.backdrop.backgroundInset or 0)
		local function curSpecCfg()
			local spec = registeredSpec or getActiveSpecIndex()
			local specCfg = ensureSpecCfg(spec)
			if not specCfg then return nil end
			if sharedSlot and ResourceBars and ResourceBars.EnsureSharedSlotStore then return ResourceBars.EnsureSharedSlotStore(sharedSlot) end
			specCfg[barType] = specCfg[barType] or {}
			return specCfg[barType]
		end
		local selectedSharedPowerType
		local function powerTypeLabel(pType)
			if pType == "HEALTH" then return HEALTH or "Health" end
			local label = (ResourceBars.PowerLabels and ResourceBars.PowerLabels[pType]) or _G["POWER_TYPE_" .. tostring(pType or "")] or _G[pType]
			if type(label) == "string" and label ~= "" then return label end
			return tostring(pType or "")
		end
		local function sharedPowerTypeBaseColor(pType)
			if ResourceBars and ResourceBars.GetBasePowerColor then return ResourceBars.GetBasePowerColor(pType) end
			return { 1, 1, 1, 1 }
		end
		local function collectSharedPowerTypes()
			local liveType = currentLiveBarType()
			if not genericSharedPowerEditor then return liveType and { liveType } or {} end
			if ResourceBars and ResourceBars.GetSharedSlotPossibleTypes then
				local wanted = {}
				local out = {}
				local seen = {}
				for _, pType in ipairs(ResourceBars.GetSharedSlotPossibleTypes(sharedSlot, addon.variables.unitClass) or {}) do
					if pType then wanted[pType] = true end
				end
				if liveType then wanted[liveType] = true end
				for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
					if wanted[pType] and not seen[pType] then
						out[#out + 1] = pType
						seen[pType] = true
					end
				end
				for pType in pairs(wanted) do
					if not seen[pType] then out[#out + 1] = pType end
				end
				return out
			end

			local class = addon.variables.unitClass
			local specTable = ResourceBars and ResourceBars.powertypeClasses and ResourceBars.powertypeClasses[class] or {}
			local wanted = {}
			if sharedSlot == "MAIN" then
				if class == "DRUID" then
					wanted.LUNAR_POWER = true
					wanted.MANA = true
					wanted.RAGE = true
					wanted.ENERGY = true
				else
					for _, info in pairs(specTable) do
						if info and info.MAIN then wanted[info.MAIN] = true end
					end
				end
			else
				if class == "DRUID" then
					wanted.MANA = true
					wanted.COMBO_POINTS = true
				end
				for _, info in pairs(specTable) do
					for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
						if info and pType ~= info.MAIN and info[pType] then wanted[pType] = true end
					end
				end
			end
			if liveType then wanted[liveType] = true end

			local out = {}
			local seen = {}
			for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
				if wanted[pType] and not seen[pType] then
					out[#out + 1] = pType
					seen[pType] = true
				end
			end
			for pType in pairs(wanted) do
				if not seen[pType] then out[#out + 1] = pType end
			end
			return out
		end
		local function selectedSharedPowerTypeTarget()
			local options = collectSharedPowerTypes()
			if not options[1] then
				selectedSharedPowerType = currentLiveBarType() or barType
				return selectedSharedPowerType
			end
			for _, pType in ipairs(options) do
				if pType == selectedSharedPowerType then return pType end
			end
			local liveType = currentLiveBarType()
			for _, pType in ipairs(options) do
				if pType == liveType then
					selectedSharedPowerType = pType
					return pType
				end
			end
			selectedSharedPowerType = options[1]
			return selectedSharedPowerType
		end
		local function getPowerTypeOverrideEntry(pType)
			local c = curSpecCfg()
			return c and c.powerTypeOverrides and pType and c.powerTypeOverrides[pType] or nil
		end
		local function ensurePowerTypeOverrideEntry(pType)
			local c = curSpecCfg()
			if not c or not pType then return nil end
			c.powerTypeOverrides = c.powerTypeOverrides or {}
			c.powerTypeOverrides[pType] = c.powerTypeOverrides[pType] or {}
			return c.powerTypeOverrides[pType]
		end
		local function getDefaultPowerColorEntry(pType)
			local c = curSpecCfg()
			return c and c.defaultPowerColors and pType and c.defaultPowerColors[pType] or nil
		end
		local function ensureDefaultPowerColorEntry(pType)
			local c = curSpecCfg()
			if not c or not pType then return nil end
			c.defaultPowerColors = c.defaultPowerColors or {}
			if type(c.defaultPowerColors[pType]) ~= "table" then c.defaultPowerColors[pType] = {} end
			return c.defaultPowerColors[pType]
		end
		local function clearDefaultPowerColorEntry(pType)
			local c = curSpecCfg()
			if not c or not c.defaultPowerColors or not pType then return end
			c.defaultPowerColors[pType] = nil
			if not next(c.defaultPowerColors) then c.defaultPowerColors = nil end
		end
		local function isPowerTypeOverrideEnabled()
			local pType = selectedSharedPowerTypeTarget()
			local entry = getPowerTypeOverrideEntry(pType)
			return entry and entry.enabled == true or false
		end
			local function currentEditorPowerType()
				if genericSharedPowerEditor then return selectedSharedPowerTypeTarget() end
				return currentLiveBarType() or barType
			end
			local function currentEditorSupportsSeparators()
				local pType = currentEditorPowerType()
				return ResourceBars and ResourceBars.separatorEligible and pType and ResourceBars.separatorEligible[pType] == true
			end
			local function currentPowerConfigTarget()
			if genericSharedPowerEditor and isPowerTypeOverrideEnabled() then
				return ensurePowerTypeOverrideEntry(selectedSharedPowerTypeTarget())
			end
			return curSpecCfg()
		end
		local function readPowerConfigField(field, fallback)
			if genericSharedPowerEditor then
				local entry = getPowerTypeOverrideEntry(selectedSharedPowerTypeTarget())
				if entry and entry.enabled == true and entry[field] ~= nil then return entry[field] end
			end
			local c = curSpecCfg()
			if c and c[field] ~= nil then return c[field] end
			if cfg and cfg[field] ~= nil then return cfg[field] end
			return fallback
		end
		local function queueRefresh()
			local targetSpec = registeredSpec or getActiveSpecIndex()
			if ResourceBars.QueueRefresh then ResourceBars.QueueRefresh(targetSpec) end
			if ResourceBars.MaybeRefreshActive then ResourceBars.MaybeRefreshActive(targetSpec) end
			if EditMode and EditMode:IsInEditMode() and targetSpec then
				if ResourceBars.Refresh then ResourceBars.Refresh() end
				if ResourceBars.ReanchorAll then ResourceBars.ReanchorAll() end
			end
		end
		local visibilityGlobalKeys = {
			hideOutOfCombat = "resourceBarsHideOutOfCombat",
			hideMounted = "resourceBarsHideMounted",
			hideVehicle = "resourceBarsHideVehicle",
			hidePetBattle = "resourceBarsHidePetBattle",
			hideClientScene = "resourceBarsHideClientScene",
		}
		local visibilityDefaults = {
			hideOutOfCombat = false,
			hideMounted = false,
			hideVehicle = false,
			hidePetBattle = false,
			hideClientScene = true,
		}
		local function getGlobalVisibilityFallback(field)
			local dbKey = visibilityGlobalKeys[field]
			local defaultValue = visibilityDefaults[field] == true
			if not dbKey then return defaultValue end
			local db = addon and addon.db
			if db and db[dbKey] ~= nil then return db[dbKey] == true end
			return defaultValue
		end
		local visibilityRuleOptions = (ResourceBars.GetVisibilityRuleOptions and ResourceBars.GetVisibilityRuleOptions()) or {}
		local function getBarVisibilitySelection()
			local c = curSpecCfg()
			if not c then return nil end
			local normalized = ResourceBars.NormalizeVisibilityConfig and ResourceBars.NormalizeVisibilityConfig(c.visibility, c) or nil
			if not normalized then
				local fallbackLegacy = nil
				local function ensureFallbackLegacy()
					if fallbackLegacy == nil then fallbackLegacy = {} end
				end
				if getGlobalVisibilityFallback("hideOutOfCombat") then
					ensureFallbackLegacy()
					fallbackLegacy.ALWAYS_IN_COMBAT = true
				end
				if getGlobalVisibilityFallback("hideMounted") then
					ensureFallbackLegacy()
					fallbackLegacy.PLAYER_NOT_MOUNTED = true
				end
				if fallbackLegacy and ResourceBars.NormalizeVisibilityConfig then normalized = ResourceBars.NormalizeVisibilityConfig(fallbackLegacy) end
			end
			if ResourceBars.CopyVisibilitySelection then return ResourceBars.CopyVisibilitySelection(normalized) end
			return normalized and CopyTable(normalized) or nil
		end
		local function setBarVisibilityRule(rule, state)
			local c = curSpecCfg()
			if not c then return end
			local normalized = getBarVisibilitySelection() or {}
			c.visibilityExplicit = true
			if rule == "ALWAYS_HIDDEN" and state then
				normalized = { ALWAYS_HIDDEN = true }
			elseif state then
				normalized[rule] = true
				normalized.ALWAYS_HIDDEN = nil
			else
				normalized[rule] = nil
			end
			if not next(normalized) then
				c.visibility = nil
			elseif ResourceBars.CopyVisibilitySelection then
				c.visibility = ResourceBars.CopyVisibilitySelection(normalized)
			else
				c.visibility = CopyTable(normalized)
			end
			-- Keep legacy flags removed once a per-bar visibility selection is set.
			c.hideOutOfCombat = nil
			c.hideMounted = nil
			queueRefresh()
		end
		local function getBarVisibilitySetting(field)
			local c = curSpecCfg()
			if c and c[field] ~= nil then return c[field] == true end
			return getGlobalVisibilityFallback(field)
		end
		local function setBarVisibilitySetting(field, value)
			local c = curSpecCfg()
			if not c then return end
			c[field] = value and true or false
			queueRefresh()
		end
		local function applyBarSize()
			local c = curSpecCfg()
			if not c then return end
			local liveBarType = currentLiveBarType()
			if liveBarType == "HEALTH" then
				ResourceBars.SetHealthBarSize(c.width or widthDefault, c.height or heightDefault)
			elseif liveBarType then
				ResourceBars.SetPowerBarSize(c.width or widthDefault, c.height or heightDefault, liveBarType)
			end
			if sharedSlot and ResourceBars and ResourceBars.SyncSharedSlotProxyFrame then ResourceBars.SyncSharedSlotProxyFrame(sharedSlot, registeredSpec) end
		end
		local function syncEditModeSizeValues(width, height)
			if not (EditMode and EditMode.SetValue and frameId) then return end
			EditMode:SetValue(frameId, "width", width, nil, true)
			EditMode:SetValue(frameId, "height", height, nil, true)
		end
		local function ensureBackdropTable(target)
			if not target then return nil end
			target.backdrop = target.backdrop or {}
			local bd = target.backdrop
			local base = (cfg and cfg.backdrop) or {}
			if bd.enabled == nil then
				if base.enabled ~= nil then
					bd.enabled = base.enabled
				else
					bd.enabled = true
				end
			end
			bd.backgroundTexture = bd.backgroundTexture or base.backgroundTexture or "Interface\\DialogFrame\\UI-DialogBox-Background"
			bd.backgroundColor = bd.backgroundColor or toColorArray(base.backgroundColor, { 0, 0, 0, 0.8 })
			bd.borderTexture = bd.borderTexture or base.borderTexture or "Interface\\Tooltips\\UI-Tooltip-Border"
			bd.borderColor = bd.borderColor or toColorArray(base.borderColor, { 0, 0, 0, 0 })
			bd.edgeSize = bd.edgeSize or base.edgeSize or 3
			bd.outset = bd.outset or base.outset or 0
			bd.backgroundInset = max(0, bd.backgroundInset or base.backgroundInset or 0)
			bd.innerPadding = nil
			return bd
		end
		local function ensureAnchorTable()
			local c = curSpecCfg()
			if not c then return nil end
			c.anchor = c.anchor or {}
			local a = c.anchor
			if not a.point then a.point = "CENTER" end
			if not a.relativePoint then a.relativePoint = a.point end
			if a.x == nil then a.x = 0 end
			if a.y == nil then a.y = 0 end
			if not a.relativeFrame or a.relativeFrame == "" then a.relativeFrame = "UIParent" end
			return a
		end
		local function syncEditModeLayoutFromAnchor()
			if not (EditMode and EditMode.EnsureLayoutData and EditMode.GetActiveLayoutName) then return end
			local a = ensureAnchorTable()
			if not a or (a.relativeFrame or "UIParent") ~= "UIParent" then return end
			local layout = EditMode:GetActiveLayoutName()
			local point = a.point or "CENTER"
			local relativePoint = a.relativePoint or point
			local x = a.x or 0
			local y = a.y or 0
			if EditMode.SetValue then
				EditMode:SetValue(frameId, "point", point, layout, true)
				EditMode:SetValue(frameId, "relativePoint", relativePoint, layout, true)
				EditMode:SetValue(frameId, "x", x, layout, true)
				EditMode:SetValue(frameId, "y", y, layout, true)
				return
			end
			local data = EditMode:EnsureLayoutData(frameId, layout)
			if not data then return end
			data.point = point
			data.relativePoint = relativePoint
			data.x = x
			data.y = y
		end
		local function anchorUsesUIParent()
			local a = ensureAnchorTable()
			return not a or (a.relativeFrame or "UIParent") == "UIParent"
		end
		local function notify(msg)
			if not msg or msg == "" then return end
			print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
		end
		local function hasGlobalProfile(targetKey)
			local store = addon.db and addon.db.globalResourceBarSettings
			if not store then return false end
			if targetKey == "MAIN" then return store.MAIN end
			if targetKey == "SECONDARY" then return store.SECONDARY end
			return store[targetKey or barType]
		end
		local function confirmSaveGlobal(targetKey, doSave)
			local specInfo = currentSpecInfo()
			if hasGlobalProfile(targetKey) then
				local key = "EQOL_SAVE_GLOBAL_RB_" .. tostring(targetKey or barType)
				local popupText
				if targetKey == "MAIN" or (not targetKey and specInfo and specInfo.MAIN == barType) then
					popupText = L["OverwriteGlobalMainProfile"] or "Overwrite global main profile?"
				else
					popupText = (L["OverwriteGlobalProfile"] or "Overwrite global profile for %s?"):format(titleLabel)
				end
				StaticPopupDialogs[key] = StaticPopupDialogs[key]
					or {
						text = popupText,
						button1 = OKAY,
						button2 = CANCEL,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
						OnAccept = function()
							if doSave then doSave() end
						end,
					}
				StaticPopup_Show(key)
			else
				if doSave then doSave() end
			end
		end
		local buttons = {}
		local function forceUIParentAnchor()
			local a = ensureAnchorTable()
			if not a then return end
			if (a.relativeFrame or "UIParent") ~= "UIParent" then
				a.relativeFrame = "UIParent"
				a.point = "CENTER"
				a.relativePoint = "CENTER"
				a.x = 0
				a.y = 0
				a.autoSpacing = nil
				a.matchRelativeWidth = nil
				refreshSettingsUI()
			end
		end
		local settingType = EditMode.lib and EditMode.lib.SettingType
		local settingsList
		if settingType then
			local function backgroundDropdownData()
				local map = {
					["Interface\\DialogFrame\\UI-DialogBox-Background"] = "Dialog Background",
					["Interface\\Buttons\\WHITE8x8"] = "Solid (tintable)",
				}
				local statusbarNames, statusbarHash = getCachedLSMMedia("statusbar")
				for i = 1, #statusbarNames do
					local name = statusbarNames[i]
					local path = statusbarHash[name]
					if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
				end
				local names, hash = getCachedLSMMedia("background")
				for i = 1, #names do
					local name = names[i]
					local path = hash[name]
					if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
				end
				return addon.functions.prepareListForDropdown(map)
			end

			local function borderDropdownData()
				local map = { ["Interface\\Tooltips\\UI-Tooltip-Border"] = "Tooltip Border" }
				for id, label in pairs(customBorderOptions() or {}) do
					map[id] = label
				end
				local names, hash = getCachedLSMMedia("border")
				for i = 1, #names do
					local name = names[i]
					local path = hash[name]
					if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
				end
				return addon.functions.prepareListForDropdown(map)
			end

			settingsList = {
				{
					name = L["Frame"] or "Frame",
					kind = settingType.Collapsible,
					id = "frame",
					defaultCollapsed = false,
				},
				{
					name = HUD_EDIT_MODE_SETTING_CHAT_FRAME_WIDTH,
					kind = settingType.Slider,
					allowInput = true,
					field = "width",
					minValue = 10,
					maxValue = 600,
					valueStep = 1,
					default = widthDefault or 200,
					parentId = "frame",
					get = function()
						local c = curSpecCfg()
						return c and c.width or widthDefault or 200
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						if not setIfChanged(c, "width", value) then return end
						if EditMode and EditMode.SetValue then EditMode:SetValue(frameId, "width", value, nil, true) end
						applyBarSize()
						queueRefresh()
					end,
					isEnabled = function()
						if anchorUsesUIParent() then return true end
						local c = curSpecCfg()
						local a = c and c.anchor
						return not (a and a.matchRelativeWidth == true)
					end,
				},
				{
					name = HUD_EDIT_MODE_SETTING_CHAT_FRAME_HEIGHT,
					kind = settingType.Slider,
					allowInput = true,
					field = "height",
					minValue = 6,
					maxValue = 600,
					valueStep = 1,
					default = heightDefault or 20,
					parentId = "frame",
					get = function()
						local c = curSpecCfg()
						return c and c.height or heightDefault or 20
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						if not setIfChanged(c, "height", value) then return end
						if EditMode and EditMode.SetValue then EditMode:SetValue(frameId, "height", value, nil, true) end
						applyBarSize()
						queueRefresh()
					end,
				},
				{
					name = L["Frame strata"] or "Frame strata",
					kind = settingType.Dropdown,
					height = 180,
					field = "strata",
					parentId = "frame",
					values = FRAME_STRATA_VALUES,
					default = "",
					get = function()
						local c = curSpecCfg()
						return normalizeFrameStrataValue((c and c.strata) or (cfg and cfg.strata))
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local normalized = normalizeFrameStrataValue(value)
						if not setIfChanged(c, "strata", normalized ~= "" and normalized or nil) then return end
						queueRefresh()
					end,
				},
				{
					name = L["UFDetachedPowerLevelOffset"] or "Frame level offset",
					kind = settingType.Slider,
					allowInput = true,
					field = "frameLevelOffset",
					minValue = 0,
					maxValue = MAX_FRAME_LEVEL_OFFSET,
					valueStep = 1,
					default = 0,
					parentId = "frame",
					get = function()
						local c = curSpecCfg()
						local value = (c and c.frameLevelOffset)
						if value == nil then value = cfg and cfg.frameLevelOffset end
						value = tonumber(value) or 0
						if value < 0 then
							value = 0
						elseif value > MAX_FRAME_LEVEL_OFFSET then
							value = MAX_FRAME_LEVEL_OFFSET
						end
						return math.floor(value + 0.5)
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local normalized = tonumber(value) or 0
						if normalized < 0 then
							normalized = 0
						elseif normalized > MAX_FRAME_LEVEL_OFFSET then
							normalized = MAX_FRAME_LEVEL_OFFSET
						end
						normalized = math.floor(normalized + 0.5)
						if not setIfChanged(c, "frameLevelOffset", normalized > 0 and normalized or nil) then return end
						queueRefresh()
					end,
				},
				{
					name = L["Click-through"] or "Click-through",
					kind = settingType.Checkbox,
					field = "clickThrough",
					default = cfg and cfg.clickThrough == true,
					parentId = "frame",
					get = function()
						local c = curSpecCfg()
						return c and c.clickThrough == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.clickThrough = value and true or false
						queueRefresh()
					end,
					isShown = function() return barType ~= "HEALTH" end,
				},
				{
					name = L["Show when"] or "Show when",
					kind = settingType.MultiDropdown,
					field = "visibility",
					parentId = "frame",
					height = 220,
					values = visibilityRuleOptions,
					hideSummary = true,
					default = getBarVisibilitySelection(),
					isSelected = function(_, value)
						local selection = getBarVisibilitySelection()
						return selection and selection[value] == true or false
					end,
					setSelected = function(_, value, state) setBarVisibilityRule(value, state and true or false) end,
					isShown = function() return visibilityRuleOptions and #visibilityRuleOptions > 0 end,
					isEnabled = function() return visibilityRuleOptions and #visibilityRuleOptions > 0 end,
				},
				{
					name = L["Hide in vehicles"],
					kind = settingType.Checkbox,
					parentId = "frame",
					get = function() return getBarVisibilitySetting("hideVehicle") end,
					set = function(_, value) setBarVisibilitySetting("hideVehicle", value) end,
					default = getGlobalVisibilityFallback("hideVehicle"),
				},
				{
					name = L["Hide in pet battles"] or "Hide in pet battles",
					kind = settingType.Checkbox,
					parentId = "frame",
					get = function() return getBarVisibilitySetting("hidePetBattle") end,
					set = function(_, value) setBarVisibilitySetting("hidePetBattle", value) end,
					default = getGlobalVisibilityFallback("hidePetBattle"),
				},
				{
					name = L["Hide in client scenes"] or "Hide in client scenes",
					kind = settingType.Checkbox,
					parentId = "frame",
					get = function() return getBarVisibilitySetting("hideClientScene") end,
					set = function(_, value) setBarVisibilitySetting("hideClientScene", value) end,
					default = getGlobalVisibilityFallback("hideClientScene"),
				},
			}
			if barType == "MAELSTROM_WEAPON" then
				settingsList[#settingsList + 1] = {
					name = "Use 10-stack bar",
					kind = settingType.Checkbox,
					field = "useMaelstromTenStacks",
					default = false,
					parentId = "frame",
					get = function()
						local c = curSpecCfg()
						return c and c.useMaelstromTenStacks == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.useMaelstromTenStacks = value and true or false
						if c.useMaelstromTenStacks then
							c.visualSegments = MAELSTROM_WEAPON_MAX_STACKS
						elseif c.visualSegments == MAELSTROM_WEAPON_MAX_STACKS or c.visualSegments == nil then
							c.visualSegments = MAELSTROM_WEAPON_SEGMENTS
						end
						queueRefresh()
					end,
				}
			end

			do -- Anchoring
				local points = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
				local logicalBarToken = sharedSlot or barType
				local function displayNameForBarType(pType)
					if pType == "MAIN" then return L["AutoEnableMain"] or "Main resource" end
					if pType == "SECONDARY" then return L["AutoEnableSecondary"] or "Secondary" end
					if pType == "HEALTH" then return HEALTH or "Health" end
					local s = (ResourceBars.PowerLabels and ResourceBars.PowerLabels[pType]) or _G["POWER_TYPE_" .. pType] or _G[pType]
					if type(s) == "string" and s ~= "" then return s end
					return pType
				end
				local function frameNameToBarType(fname)
					if ResourceBars and ResourceBars.GetSharedSlotFromFrameName then
						local slot = ResourceBars.GetSharedSlotFromFrameName(fname)
						if slot then return slot end
					end
					if fname == "EQOLHealthBar" then return "HEALTH" end
					return type(fname) == "string" and fname:match("^EQOL(.+)Bar$") or nil
				end
				local function wouldCauseLoop(fromType, candidateName)
					if candidateName == "UIParent" then return false end
					local candType = frameNameToBarType(candidateName)
					if not candType then return false end
					if candType == fromType then return true end
					local targetFrameName = (sharedSlot and ResourceBars and ResourceBars.GetSharedSlotFrameName and ResourceBars.GetSharedSlotFrameName(fromType))
						or ((fromType == "HEALTH") and "EQOLHealthBar" or ("EQOL" .. fromType .. "Bar"))
					local seen = {}
					local name = candidateName
					local spec = addon.variables.unitSpec
					local limit = 10
					while name and name ~= "UIParent" and limit > 0 do
						if seen[name] then break end
						seen[name] = true
						if name == targetFrameName then return true end
						local bt = frameNameToBarType(name)
						if not bt then break end
						local anch
						if ResourceBars and ResourceBars.GetSharedSlotFrameName and ResourceBars.GetSharedSlotFrameName(bt) then
							local slotCfg = ResourceBars.EnsureSharedSlotStore and ResourceBars.EnsureSharedSlotStore(bt)
							anch = slotCfg and slotCfg.anchor
						else
							local specCfg = ensureSpecCfg(spec)
							anch = specCfg and specCfg[bt] and specCfg[bt].anchor
						end
						name = anch and anch.relativeFrame or "UIParent"
						limit = limit - 1
					end
					return false
				end
				local function isBarEnabled(pType)
					if ResourceBars and ResourceBars.GetSharedSlotFrameName and ResourceBars.GetSharedSlotFrameName(pType) then
						local cfg = ResourceBars.EnsureSharedSlotStore and ResourceBars.EnsureSharedSlotStore(pType)
						return cfg and cfg.enabled == true
					end
					local spec = addon.variables.unitSpec
					local specCfg = ensureSpecCfg(spec)
					return specCfg and specCfg[pType] and specCfg[pType].enabled == true
				end
				local function enforceMinWidth()
					local c = curSpecCfg()
					if not c then return end
					local minWidth = MIN_RESOURCE_BAR_WIDTH or 10
					c.width = minWidth
					if barType == "HEALTH" then
						ResourceBars.SetHealthBarSize(c.width or minWidth, c.height or heightDefault or 20)
					else
						ResourceBars.SetPowerBarSize(c.width or minWidth, c.height or heightDefault or 20, barType)
					end
				end

				local function relativeFrameEntries()
					local entries = {}
					local seen = {}
					local function add(key, label)
						if not key or key == "" or seen[key] then return end
						if wouldCauseLoop(barType, key) then return end
						seen[key] = true
						entries[#entries + 1] = { key = key, label = label or key }
					end

					add("UIParent", "UIParent")
					add("PlayerFrame", "PlayerFrame")
					add("TargetFrame", "TargetFrame")
					add("EssentialCooldownViewer", "EssentialCooldownViewer")
					add("UtilityCooldownViewer", "UtilityCooldownViewer")
					add("BuffBarCooldownViewer", "BuffBarCooldownViewer")
					add("BuffIconCooldownViewer", "BuffIconCooldownViewer")

					local cooldownPanels = addon.Aura and addon.Aura.CooldownPanels
					if cooldownPanels and cooldownPanels.GetRoot then
						local root = cooldownPanels:GetRoot()
						if root and root.panels then
							local order = root.order or {}
							local function addPanelEntry(panelId, panel)
								if not panel or panel.enabled == false then return end
								local label = string.format("Panel %s: %s", tostring(panelId), panel.name or "Cooldown Panel")
								add("EQOL_CooldownPanel" .. tostring(panelId), label)
							end
							if #order > 0 then
								for _, panelId in ipairs(order) do
									addPanelEntry(panelId, root.panels[panelId])
								end
							else
								for panelId, panel in pairs(root.panels) do
									addPanelEntry(panelId, panel)
								end
							end
						end
					end

					if addon.variables and addon.variables.actionBarNames then
						for _, info in ipairs(addon.variables.actionBarNames) do
							if info.name then add(info.name, info.text or info.name) end
						end
					end

					if sharedSlot then
						local sharedOrder = ResourceBars.SHARED_SLOT_ORDER or { "HEALTH", "MAIN", "SECONDARY" }
						for _, slotKey in ipairs(sharedOrder) do
							local fname = ResourceBars.GetSharedSlotFrameName and ResourceBars.GetSharedSlotFrameName(slotKey)
							if fname and isBarEnabled(slotKey) then add(fname, displayNameForBarType(slotKey)) end
						end
					else
						if isBarEnabled("HEALTH") then add("EQOLHealthBar", displayNameForBarType("HEALTH")) end
						for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
							if isBarEnabled(pType) then
								local fname = "EQOL" .. pType .. "Bar"
								add(fname, displayNameForBarType(pType))
							end
						end
					end

					local a = ensureAnchorTable()
					local cur = a and a.relativeFrame
					if cur and not seen[cur] and not wouldCauseLoop(logicalBarToken, cur) then add(cur, cur) end

					return entries
				end
				local function validateRelativeFrame(a)
					if not a then return "UIParent" end
					local cur = a.relativeFrame or "UIParent"
					local entries = relativeFrameEntries()
					local ok = false
					for _, e in ipairs(entries) do
						if e.key == cur then
							ok = true
							break
						end
					end
					if not ok then
						cur = "UIParent"
						a.relativeFrame = cur
					end
					return cur
				end
				local function applyAnchorDefaults(a, target)
					if not a then return end
					if target == "UIParent" then
						a.point = "CENTER"
						a.relativePoint = "CENTER"
						a.x = 0
						a.y = 0
						a.autoSpacing = nil
						a.matchRelativeWidth = nil
					else
						a.point = "TOPLEFT"
						a.relativePoint = "BOTTOMLEFT"
						a.x = 0
						a.y = 0
						a.autoSpacing = nil
					end
				end
				settingsList[#settingsList + 1] = {
					name = "Relative frame",
					kind = settingType.Dropdown,
					height = 180,
					field = "anchorRelativeFrame",
					generator = function(_, root)
						local entries = relativeFrameEntries()
						for _, entry in ipairs(entries) do
							root:CreateRadio(entry.label, function()
								local a = ensureAnchorTable()
								local cur = validateRelativeFrame(a)
								return cur == entry.key
							end, function()
								local a = ensureAnchorTable()
								if not a then return end
								local target = entry.key
								if wouldCauseLoop(logicalBarToken, target) then target = "UIParent" end
								a.relativeFrame = target
								applyAnchorDefaults(a, target)
								if target ~= "UIParent" and a.matchRelativeWidth == true then enforceMinWidth() end
								syncEditModeLayoutFromAnchor()
								queueRefresh()
								refreshSettingsUI()
							end)
						end
					end,
					get = function()
						local a = ensureAnchorTable()
						return validateRelativeFrame(a)
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						local target = value or "UIParent"
						if wouldCauseLoop(logicalBarToken, target) then target = "UIParent" end
						a.relativeFrame = target
						applyAnchorDefaults(a, target)
						if target ~= "UIParent" and a.matchRelativeWidth == true then enforceMinWidth() end
						syncEditModeLayoutFromAnchor()
						queueRefresh()
						refreshSettingsUI()
					end,
					default = "UIParent",
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = "Anchor point",
					kind = settingType.Dropdown,
					height = 180,
					field = "anchorPoint",
					generator = function(_, root)
						for _, p in ipairs(points) do
							root:CreateRadio(p, function()
								local a = ensureAnchorTable()
								return a and (a.point or "CENTER") == p
							end, function()
								local a = ensureAnchorTable()
								if not a then return end
								a.point = p
								if not a.relativePoint then a.relativePoint = p end
								syncEditModeLayoutFromAnchor()
								queueRefresh()
							end)
						end
					end,
					get = function()
						local a = ensureAnchorTable()
						return a and a.point or "CENTER"
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						a.point = value
						if not a.relativePoint then a.relativePoint = value end
						syncEditModeLayoutFromAnchor()
						queueRefresh()
					end,
					default = "CENTER",
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = "Relative point",
					kind = settingType.Dropdown,
					height = 180,
					field = "anchorRelativePoint",
					generator = function(_, root)
						for _, p in ipairs(points) do
							root:CreateRadio(p, function()
								local a = ensureAnchorTable()
								return a and (a.relativePoint or "CENTER") == p
							end, function()
								local a = ensureAnchorTable()
								if not a then return end
								a.relativePoint = p
								syncEditModeLayoutFromAnchor()
								queueRefresh()
							end)
						end
					end,
					get = function()
						local a = ensureAnchorTable()
						return a and a.relativePoint or "CENTER"
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						a.relativePoint = value
						syncEditModeLayoutFromAnchor()
						queueRefresh()
					end,
					default = "CENTER",
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = L["MatchRelativeFrameWidth"] or "Match Relative Frame width",
					kind = settingType.Checkbox,
					field = "matchRelativeWidth",
					get = function()
						local a = ensureAnchorTable()
						return a and a.matchRelativeWidth == true
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						a.matchRelativeWidth = value and true or nil
						if a.matchRelativeWidth then enforceMinWidth() end
						queueRefresh()
						refreshSettingsUI()
					end,
					isEnabled = function() return not anchorUsesUIParent() end,
					default = false,
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = "X Offset",
					kind = settingType.Slider,
					allowInput = true,
					field = "anchorOffsetX",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					get = function()
						local a = ensureAnchorTable()
						return a and a.x or 0
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						local new = value or 0
						if a.x == new then return end
						a.x = new
						a.autoSpacing = false
						syncEditModeLayoutFromAnchor()
						queueRefresh()
					end,
					default = 0,
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = "Y Offset",
					kind = settingType.Slider,
					allowInput = true,
					field = "anchorOffsetY",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					get = function()
						local a = ensureAnchorTable()
						return a and a.y or 0
					end,
					set = function(_, value)
						local a = ensureAnchorTable()
						if not a then return end
						local new = value or 0
						if a.y == new then return end
						a.y = new
						a.autoSpacing = false
						syncEditModeLayoutFromAnchor()
						queueRefresh()
					end,
					default = 0,
					parentId = "frame",
				}
			end

			settingsList[#settingsList + 1] = {
				name = L["Bar Texture"] or "Bar Texture",
				kind = settingType.Dropdown,
				height = 180,
				field = "barTexture",
				parentId = "frame",
				generator = function(dropdown, root)
					local listTex, orderTex = addon.Aura.functions.getStatusbarDropdownLists(true)
					if not listTex or not orderTex then
						listTex, orderTex = { DEFAULT = DEFAULT }, { "DEFAULT" }
					end
					if not listTex or not orderTex then return end
					ensureDropdownTexturePreview(dropdown)
					for index, key in ipairs(orderTex) do
						local label = listTex[key] or key
						local previewIndex = index
						local previewPath = resolveStatusbarPreviewPath(key)
						local checkbox = root:CreateCheckbox(label, function()
							local c = curSpecCfg()
							local cur = c and c.barTexture or cfg.barTexture or "DEFAULT"
							return cur == key
						end, function()
							local c = curSpecCfg()
							if not c then return end
							local cur = c.barTexture or cfg.barTexture or "DEFAULT"
							if cur == key then return end
							c.barTexture = key
							queueRefresh()
						end)
						if previewPath then checkbox:AddInitializer(function(button) attachDropdownTexturePreview(dropdown, button, previewIndex, previewPath) end) end
					end
				end,
				get = function()
					local c = curSpecCfg()
					return (c and c.barTexture) or cfg.barTexture or "DEFAULT"
				end,
				set = function(_, value)
					local c = curSpecCfg()
					if not c then return end
					c.barTexture = value
					queueRefresh()
				end,
				default = cfg and cfg.barTexture or "DEFAULT",
			}

			do -- Behavior
				local behaviorBarType = genericSharedPowerEditor and "MANA" or currentLiveBarType()
				local behaviorValues = ResourceBars.BehaviorOptionsForType and ResourceBars.BehaviorOptionsForType(behaviorBarType)
				if not behaviorValues then
					behaviorValues = {
						{ value = "reverseFill", text = L["Reverse fill"] or "Reverse fill" },
					}
					if behaviorBarType ~= "RUNES" then
						behaviorValues[#behaviorValues + 1] = { value = "verticalFill", text = L["Vertical orientation"] or "Vertical orientation" }
						behaviorValues[#behaviorValues + 1] = { value = "smoothFill", text = L["Smooth fill"] or "Smooth fill" }
					end
				end

				local function currentBehaviorSelection()
					if ResourceBars and ResourceBars.BehaviorSelectionFromConfig then return ResourceBars.BehaviorSelectionFromConfig(curSpecCfg(), behaviorBarType) end
					local c = curSpecCfg()
					local map = {}
					if c then
						if c.reverseFill == true then map.reverseFill = true end
						if behaviorBarType ~= "RUNES" then
							if c.verticalFill == true then map.verticalFill = true end
							if c.smoothFill == true then map.smoothFill = true end
						end
					end
					return map
				end

				local function applyBehaviorFlag(key, enabled)
					local cfg = curSpecCfg()
					if not cfg then return end
					local selection = currentBehaviorSelection()
					if key then selection[key] = enabled and true or nil end
					local swapped = false
					if ResourceBars and ResourceBars.ApplyBehaviorSelection then
						swapped = ResourceBars.ApplyBehaviorSelection(cfg, selection, behaviorBarType, addon.variables.unitSpec) and true or false
					else
						cfg.reverseFill = selection.reverseFill == true
						if behaviorBarType ~= "RUNES" then
							cfg.verticalFill = selection.verticalFill == true
							cfg.smoothFill = selection.smoothFill == true
						else
							cfg.verticalFill = nil
							cfg.smoothFill = nil
						end
					end
					if swapped then syncEditModeSizeValues(cfg.width or widthDefault or 200, cfg.height or heightDefault or 20) end
					queueRefresh()
					if swapped then refreshSettingsUI() end
				end

				if settingType.MultiDropdown and behaviorValues and #behaviorValues > 0 then
					settingsList[#settingsList + 1] = {
						name = L["Behavior"] or "Behavior",
						kind = settingType.MultiDropdown,
						height = 180,
						field = "behavior",
						default = currentBehaviorSelection(),
						values = behaviorValues,
						hideSummary = true,
						parentId = "frame",
						isSelected = function(_, value)
							local selection = currentBehaviorSelection()
							return selection[value] == true
						end,
						setSelected = function(_, value, state) applyBehaviorFlag(value, state) end,
					}
				end
			end

			-- Separator controls (eligible bars only)
			if (ResourceBars.separatorEligible and ResourceBars.separatorEligible[barType]) or genericSharedPowerEditor then
				settingsList[#settingsList + 1] = {
					name = L["Show separator"] or "Show separator",
					kind = settingType.CheckboxColor,
					field = "showSeparator",
					default = cfg and cfg.showSeparator == true,
					get = function()
						local c = curSpecCfg()
						return c and c.showSeparator == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.showSeparator = value and true or false
						queueRefresh()
					end,
					colorDefault = toUIColor(cfg and cfg.separatorColor, SEP_DEFAULT),
					colorGet = function()
						local c = curSpecCfg()
						local col = (c and c.separatorColor) or (cfg and cfg.separatorColor) or SEP_DEFAULT
						local r, g, b, a = toColorComponents(col, SEP_DEFAULT)
						return { r = r, g = g, b = b, a = a }
					end,
						colorSet = function(_, value)
							local c = curSpecCfg()
							if not c then return end
							c.separatorColor = toColorArray(value, SEP_DEFAULT)
							queueRefresh()
						end,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorSupportsSeparators()
						end,
						hasOpacity = true,
						parentId = "frame",
					}

				settingsList[#settingsList + 1] = {
					name = L["Separator thickness"] or "Separator thickness",
					kind = settingType.Slider,
					allowInput = true,
					field = "separatorThickness",
					minValue = 1,
					maxValue = 10,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						return (c and c.separatorThickness) or SEPARATOR_THICKNESS
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local new = value or SEPARATOR_THICKNESS
						if c.separatorThickness == new then return end
						c.separatorThickness = new
						queueRefresh()
					end,
					default = (cfg and cfg.separatorThickness) or SEPARATOR_THICKNESS,
						isEnabled = function()
							local c = curSpecCfg()
							return c and c.showSeparator == true
						end,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorSupportsSeparators()
						end,
						parentId = "frame",
					}

				settingsList[#settingsList + 1] = {
					name = L["Separated offset"] or "Separated offset",
					kind = settingType.Slider,
					allowInput = true,
					field = "separatedOffset",
					minValue = 0,
					maxValue = 30,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						return (c and c.separatedOffset) or 0
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local new = tonumber(value) or 0
						if new < 0 then new = 0 end
						new = math.floor(new + 0.5)
						if c.separatedOffset == new then return end
						c.separatedOffset = new
						queueRefresh()
					end,
						default = (cfg and cfg.separatedOffset) or 0,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorSupportsSeparators()
						end,
						isEnabled = function()
							local c = curSpecCfg()
							if not c then return false end
						return c.showSeparator == true or c.useGradient == true
					end,
					parentId = "frame",
				}
			end

			-- Threshold controls (all non-health bars)
			if barType ~= "HEALTH" then
				settingsList[#settingsList + 1] = {
					name = L["Show threshold lines"] or "Show threshold lines",
					kind = settingType.CheckboxColor,
					field = "showThresholds",
					default = cfg and cfg.showThresholds == true,
					get = function()
						local c = curSpecCfg()
						return c and c.showThresholds == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.showThresholds = value and true or false
						queueRefresh()
					end,
					colorDefault = toUIColor(cfg and cfg.thresholdColor, THRESHOLD_DEFAULT),
					colorGet = function()
						local c = curSpecCfg()
						local col = (c and c.thresholdColor) or (cfg and cfg.thresholdColor) or THRESHOLD_DEFAULT
						local r, g, b, a = toColorComponents(col, THRESHOLD_DEFAULT)
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.thresholdColor = toColorArray(value, THRESHOLD_DEFAULT)
						queueRefresh()
					end,
					hasOpacity = true,
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = L["Use absolute values"] or "Use absolute values",
					kind = settingType.Checkbox,
					field = "useAbsoluteThresholds",
					default = cfg and cfg.useAbsoluteThresholds == true,
					get = function()
						local c = curSpecCfg()
						return c and c.useAbsoluteThresholds == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.useAbsoluteThresholds = value and true or false
						queueRefresh()
						refreshSettingsUI()
					end,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.showThresholds == true
					end,
					parentId = "frame",
				}

				settingsList[#settingsList + 1] = {
					name = L["Number of thresholds"] or "Number of thresholds",
					kind = settingType.Dropdown,
					height = 120,
					field = "thresholdCount",
					parentId = "frame",
					values = {
						{ value = 1, text = "1" },
						{ value = 2, text = "2" },
						{ value = 3, text = "3" },
						{ value = 4, text = "4" },
					},
					get = function()
						local c = curSpecCfg()
						local count = (c and c.thresholdCount) or DEFAULT_THRESHOLD_COUNT
						return tostring(count)
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local new = tonumber(value) or DEFAULT_THRESHOLD_COUNT
						if new < 1 then new = 1 end
						if new > 4 then new = 4 end
						if c.thresholdCount == new then return end
						c.thresholdCount = new
						queueRefresh()
					end,
					default = tostring(DEFAULT_THRESHOLD_COUNT),
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.showThresholds == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Threshold line thickness"] or "Threshold line thickness",
					kind = settingType.Slider,
					allowInput = true,
					field = "thresholdThickness",
					minValue = 1,
					maxValue = 10,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						return (c and c.thresholdThickness) or THRESHOLD_THICKNESS
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local new = value or THRESHOLD_THICKNESS
						if c.thresholdThickness == new then return end
						c.thresholdThickness = new
						queueRefresh()
					end,
					default = (cfg and cfg.thresholdThickness) or THRESHOLD_THICKNESS,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.showThresholds == true
					end,
					parentId = "frame",
				}

				local thresholdMaxValue = (curSpecCfg() and curSpecCfg().useAbsoluteThresholds == true) and 1000 or 100
				local function thresholdValue(index)
					local c = curSpecCfg()
					local list = (c and c.thresholds)
					if type(list) ~= "table" then list = (cfg and cfg.thresholds) end
					if type(list) == "table" then return tonumber(list[index]) or 0 end
					return DEFAULT_THRESHOLDS[index] or 0
				end

				local function thresholdCount()
					local c = curSpecCfg()
					local count = tonumber(c and c.thresholdCount) or DEFAULT_THRESHOLD_COUNT
					if count < 1 then count = 1 end
					if count > 4 then count = 4 end
					return count
				end

				local function setThresholdValue(index, value)
					local c = curSpecCfg()
					if not c then return end
					if type(c.thresholds) ~= "table" then c.thresholds = { DEFAULT_THRESHOLDS[1], DEFAULT_THRESHOLDS[2], DEFAULT_THRESHOLDS[3], DEFAULT_THRESHOLDS[4] } end
					c.thresholds[index] = value or 0
					queueRefresh()
				end

				local thresholdLabels = {
					L["Threshold 1"] or "Threshold 1",
					L["Threshold 2"] or "Threshold 2",
					L["Threshold 3"] or "Threshold 3",
					L["Threshold 4"] or "Threshold 4",
				}

				for i = 1, #thresholdLabels do
					settingsList[#settingsList + 1] = {
						name = thresholdLabels[i],
						kind = settingType.Slider,
						allowInput = true,
						field = "threshold" .. i,
						minValue = 0,
						maxValue = thresholdMaxValue,
						valueStep = 1,
						get = function() return thresholdValue(i) end,
						set = function(_, value) setThresholdValue(i, value) end,
						default = DEFAULT_THRESHOLDS[i] or 0,
						isEnabled = function()
							local c = curSpecCfg()
							return c and c.showThresholds == true
						end,
						isShown = function() return i <= thresholdCount() end,
						parentId = "frame",
					}
				end
			end

			-- Druid: Show in (forms) is only available for classic/spec bars, not shared slots.
			if addon.variables.unitClass == "DRUID" and not sharedSlot and barType ~= "HEALTH" and barType ~= "COMBO_POINTS" then
				local forms = { "HUMANOID", "BEAR", "CAT", "TRAVEL", "MOONKIN", "STAG" }
				local formLabels = {
					HUMANOID = L["Humanoid"] or "Humanoid",
					BEAR = L["Bear"] or "Bear",
					CAT = L["Cat"] or "Cat",
					TRAVEL = L["Travel"] or "Travel",
					MOONKIN = L["Moonkin"] or "Moonkin",
					STAG = L["Stag"] or "Stag",
				}

				local function ensureShowForms()
					local c = curSpecCfg()
					if not c then return nil end
					c.showForms = c.showForms or {}
					local sf = c.showForms
					if barType == "COMBO_POINTS" then
						if sf.CAT == nil then sf.CAT = true end
						if sf.HUMANOID == nil then sf.HUMANOID = false end
						if sf.BEAR == nil then sf.BEAR = false end
						if sf.TRAVEL == nil then sf.TRAVEL = false end
						if sf.MOONKIN == nil then sf.MOONKIN = false end
						if sf.STAG == nil then sf.STAG = false end
					else
						local specInfo = currentSpecInfo()
						local isSecondaryMana = barType == "MANA" and specInfo and specInfo.MAIN ~= "MANA"
						local isSecondaryEnergy = barType == "ENERGY" and specInfo and specInfo.MAIN ~= "ENERGY"
						if isSecondaryMana then
							if sf.HUMANOID == nil then sf.HUMANOID = true end
							if sf.BEAR == nil then sf.BEAR = false end
							if sf.CAT == nil then sf.CAT = false end
							if sf.TRAVEL == nil then sf.TRAVEL = false end
							if sf.MOONKIN == nil then sf.MOONKIN = false end
							if sf.STAG == nil then sf.STAG = false end
						elseif isSecondaryEnergy then
							if sf.HUMANOID == nil then sf.HUMANOID = false end
							if sf.BEAR == nil then sf.BEAR = false end
							if sf.CAT == nil then sf.CAT = true end
							if sf.TRAVEL == nil then sf.TRAVEL = false end
							if sf.MOONKIN == nil then sf.MOONKIN = false end
							if sf.STAG == nil then sf.STAG = false end
						else
							if sf.HUMANOID == nil then sf.HUMANOID = true end
							if sf.BEAR == nil then sf.BEAR = true end
							if sf.CAT == nil then sf.CAT = true end
							if sf.TRAVEL == nil then sf.TRAVEL = true end
							if sf.MOONKIN == nil then sf.MOONKIN = true end
							if sf.STAG == nil then sf.STAG = true end
						end
					end
					return sf
				end

				local dropdownValues = {}
				for _, key in ipairs(forms) do
					if barType ~= "COMBO_POINTS" or key == "CAT" then dropdownValues[#dropdownValues + 1] = { value = key, text = formLabels[key] or key } end
				end

				if settingType.MultiDropdown then
					settingsList[#settingsList + 1] = {
						name = L["Show in"] or "Show in",
						kind = settingType.MultiDropdown,
						field = "showForms",
						values = dropdownValues,
						hideSummary = true,
						isSelected = function(_, value)
							local sf = ensureShowForms()
							if not sf then return false end
							local cur = sf[value]
							if cur == nil then return true end
							return cur ~= false
						end,
						setSelected = function(_, value, state)
							local sf = ensureShowForms()
							if not sf then return end
							sf[value] = state and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						default = ensureShowForms(),
						parentId = "frame",
					}
				end
			end

			if barType == "HEALTH" then
				local absorbDefaultColor = { 0.8, 0.8, 0.8, 0.8 }
				settingsList[#settingsList + 1] = {
					name = L["AbsorbBar"] or "Absorb Bar",
					kind = settingType.Collapsible,
					id = "absorb",
					defaultCollapsed = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Enable absorb bar"] or "Enable absorb bar",
					kind = settingType.Checkbox,
					field = "absorbEnabled",
					parentId = "absorb",
					get = function()
						local c = curSpecCfg()
						return c and c.absorbEnabled ~= false
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbEnabled = value and true or false
						queueRefresh()
					end,
					default = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Use custom absorb color"] or "Use custom absorb color",
					kind = settingType.CheckboxColor,
					field = "absorbUseCustomColor",
					parentId = "absorb",
					default = false,
					get = function()
						local c = curSpecCfg()
						return c and c.absorbUseCustomColor == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbUseCustomColor = value and true or false
						queueRefresh()
					end,
					colorDefault = toUIColor(cfg and cfg.absorbColor, absorbDefaultColor),
					colorGet = function()
						local c = curSpecCfg()
						local col = (c and c.absorbColor) or (cfg and cfg.absorbColor) or absorbDefaultColor
						local r, g, b, a = toColorComponents(col, absorbDefaultColor)
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbColor = toColorArray(value, absorbDefaultColor)
						c.absorbUseCustomColor = true
						queueRefresh()
					end,
					hasOpacity = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Absorb texture"] or "Absorb texture",
					kind = settingType.Dropdown,
					height = 180,
					field = "absorbTexture",
					parentId = "absorb",
					generator = function(dropdown, root)
						local listTex, orderTex = addon.Aura.functions.getStatusbarDropdownLists(true)
						if not listTex or not orderTex then
							listTex, orderTex = { DEFAULT = DEFAULT }, { "DEFAULT" }
						end
						if not listTex or not orderTex then return end
						ensureDropdownTexturePreview(dropdown)
						for index, key in ipairs(orderTex) do
							local label = listTex[key] or key
							local previewIndex = index
							local previewPath = resolveStatusbarPreviewPath(key)
							local checkbox = root:CreateCheckbox(label, function()
								local c = curSpecCfg()
								local cur = c and c.absorbTexture or cfg.absorbTexture or cfg.barTexture or "DEFAULT"
								return cur == key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								local cur = c.absorbTexture or cfg.absorbTexture or cfg.barTexture or "DEFAULT"
								if cur == key then return end
								c.absorbTexture = key
								queueRefresh()
							end)
							if previewPath then checkbox:AddInitializer(function(button) attachDropdownTexturePreview(dropdown, button, previewIndex, previewPath) end) end
						end
					end,
					get = function()
						local c = curSpecCfg()
						return (c and c.absorbTexture) or cfg.absorbTexture or cfg.barTexture or "DEFAULT"
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbTexture = value
						queueRefresh()
					end,
					default = cfg and (cfg.absorbTexture or cfg.barTexture) or "DEFAULT",
				}

				settingsList[#settingsList + 1] = {
					name = L["Reverse absorb fill"] or "Reverse absorb fill",
					kind = settingType.Checkbox,
					field = "absorbReverseFill",
					parentId = "absorb",
					get = function()
						local c = curSpecCfg()
						return c and c.absorbReverseFill == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbReverseFill = value and true or false
						if c.absorbReverseFill then c.absorbOverfill = false end
						queueRefresh()
						refreshSettingsUI()
					end,
					default = false,
				}

				settingsList[#settingsList + 1] = {
					name = L["Absorb overfill"] or "Absorb overfill",
					kind = settingType.Checkbox,
					field = "absorbOverfill",
					parentId = "absorb",
					get = function()
						local c = curSpecCfg()
						return c and c.absorbOverfill == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbOverfill = value and true or false
						if c.absorbOverfill then c.absorbReverseFill = false end
						queueRefresh()
						refreshSettingsUI()
					end,
					default = false,
				}

				settingsList[#settingsList + 1] = {
					name = L["Show sample absorb"] or "Show sample absorb",
					kind = settingType.Checkbox,
					field = "absorbSample",
					parentId = "absorb",
					get = function()
						local c = curSpecCfg()
						return c and c.absorbSample == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.absorbSample = value and true or false
						queueRefresh()
					end,
					default = false,
				}
			end

			settingsList[#settingsList + 1] = {
				name = LOCALE_TEXT_LABEL,
				kind = settingType.Collapsible,
				id = "textsettings",
				defaultCollapsed = true,
			}

			if barType == "RUNES" then
				settingsList[#settingsList + 1] = {
					name = L["Show cooldown text"] or "Show cooldown text",
					kind = settingType.Checkbox,
					field = "showCooldownText",
					parentId = "textsettings",
					get = function()
						local class, specIndex = addon.variables.unitClass, addon.variables.unitSpec
						local specCfg = addon.db.personalResourceBarSettings[class][specIndex]

						return addon.db.personalResourceBarSettings[class][specIndex].RUNES.showCooldownText
					end,
					set = function(_, value)
						local class, specIndex = addon.variables.unitClass, addon.variables.unitSpec
						local specCfg = addon.db.personalResourceBarSettings[class][specIndex]

						addon.db.personalResourceBarSettings[class][specIndex].RUNES.showCooldownText = value and true or false
						queueRefresh()
					end,
					default = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Cooldown Text Size"] or "Cooldown Text Size",
					kind = settingType.Slider,
					allowInput = true,
					field = "cooldownTextFontSize",
					minValue = 6,
					maxValue = 64,
					valueStep = 1,
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return c and c.cooldownTextFontSize or 16
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						if not setIfChanged(c, "cooldownTextFontSize", value) then return end
						queueRefresh()
					end,
					default = 16,
				}

				settingsList[#settingsList + 1] = {
					name = L["Font"] or "Font",
					kind = settingType.DropdownColor,
					height = 180,
					field = "fontFace",
					parentId = "textsettings",
					generator = function(_, root)
						local function currentFontSetting()
							local c = curSpecCfg()
							return (c and c.fontFace) or cfg.fontFace or globalFontConfigKey()
						end
						local function currentFontPath()
							local configured = currentFontSetting()
							if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, globalFontDefaultPath()) end
							return configured or globalFontDefaultPath()
						end
						local currentPath = currentFontPath()
						local globalFontValue = globalFontConfigKey()
						local function isGlobalSelected() return currentFontSetting() == globalFontValue end
						root:CreateCheckbox(globalFontConfigLabel(), function() return currentFontSetting() == globalFontValue end, function()
							local c = curSpecCfg()
							if not c then return end
							c.fontFace = globalFontValue
							queueRefresh()
						end)
						local seen = {}
						local names, hash = getCachedLSMMedia("font")
						for i = 1, #names do
							local name = names[i]
							local path = hash[name] or name
							seen[path] = name
							root:CreateCheckbox(name, function() return (not isGlobalSelected()) and currentFontPath() == path end, function()
								local c = curSpecCfg()
								if not c then return end
								if (not isGlobalSelected()) and currentFontPath() == path then return end
								c.fontFace = path
								queueRefresh()
							end)
						end
						if currentPath and not seen[currentPath] then
							local label = tostring(currentPath)
							root:CreateCheckbox(label, function() return (not isGlobalSelected()) and currentFontPath() == currentPath end, function()
								local c = curSpecCfg()
								if not c then return end
								if (not isGlobalSelected()) and currentFontPath() == currentPath then return end
								c.fontFace = currentPath
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						return (c and c.fontFace) or cfg.fontFace or globalFontConfigKey()
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontFace = value
						queueRefresh()
					end,
					colorDefault = { r = 1, g = 1, b = 1, a = 1 },
					colorGet = function()
						local c = curSpecCfg()
						local col = (c and c.fontColor) or (cfg and cfg.fontColor) or { 1, 1, 1, 1 }
						local r, g, b, a = toColorComponents(col, { 1, 1, 1, 1 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontColor = toColorArray(value, { 1, 1, 1, 1 })
						queueRefresh()
					end,
					hasOpacity = true,
					default = globalFontConfigKey(),
				}

				local outlineOptions = getFontStyleEntries()
				settingsList[#settingsList + 1] = {
					name = L["Outline"],
					kind = settingType.Dropdown,
					height = 180,
					field = "fontOutline",
					parentId = "textsettings",
					generator = function(_, root)
						for _, entry in ipairs(outlineOptions) do
							root:CreateCheckbox(entry.label, function()
								local c = curSpecCfg()
								local cur = normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
								return cur == entry.key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								local cur = normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
								if cur == entry.key then return end
								c.fontOutline = normalizeFontStyleChoice(entry.key, "OUTLINE")
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						return normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontOutline = normalizeFontStyleChoice(value, "OUTLINE")
						queueRefresh()
					end,
					default = "OUTLINE",
				}
			end

			if barType ~= "RUNES" then
				local function defaultStyle()
					if barType == "HEALTH" then return "PERCENT" end
					if barType == "MANA" or barType == "STAGGER" then return "PERCENT" end
					return "CURMAX"
				end
				local textOptions = {
					{ key = "PERCENT", label = STATUS_TEXT_PERCENT },
					{ key = "CURMAX", label = L["Current/Max"] or "Current/Max" },
					{ key = "CURRENT", label = L["Current"] or "Current" },
					{ key = "CURPERCENT", label = L["Current - Percent"] or "Current - Percent" },
					{ key = "NONE", label = NONE },
				}
				settingsList[#settingsList + 1] = {
					name = LOCALE_TEXT_LABEL,
					kind = settingType.Dropdown,
					height = 220,
					field = "textStyle",
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return (c and c.textStyle) or defaultStyle()
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.textStyle = value
						queueRefresh()
					end,
					generator = function(_, root)
						for _, entry in ipairs(textOptions) do
							root:CreateRadio(entry.label, function()
								local c = curSpecCfg()
								return ((c and c.textStyle) or defaultStyle()) == entry.key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								c.textStyle = entry.key
								queueRefresh()
							end)
						end
					end,
					default = defaultStyle(),
				}

				settingsList[#settingsList + 1] = {
					name = L["Use short numbers"] or "Use short numbers",
					kind = settingType.Checkbox,
					field = "shortNumbers",
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return (not c) or c.shortNumbers ~= false
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.shortNumbers = value and true or false
						queueRefresh()
					end,
					default = true,
				}

				local roundingOptions = {
					{ key = "ROUND", label = L["Round to nearest"] or "Round to nearest" },
					{ key = "FLOOR", label = L["Round down"] or "Round down" },
				}
				settingsList[#settingsList + 1] = {
					name = L["Percent rounding"] or "Percent rounding",
					kind = settingType.Dropdown,
					height = 120,
					field = "percentRounding",
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return (c and c.percentRounding) or "ROUND"
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.percentRounding = value
						queueRefresh()
					end,
					generator = function(_, root)
						for _, entry in ipairs(roundingOptions) do
							root:CreateRadio(entry.label, function()
								local c = curSpecCfg()
								return ((c and c.percentRounding) or "ROUND") == entry.key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								c.percentRounding = entry.key
								queueRefresh()
							end)
						end
					end,
					default = "ROUND",
				}

				settingsList[#settingsList + 1] = {
					name = L["Hide percent (%)"] or "Hide percent (%)",
					kind = settingType.Checkbox,
					field = "hidePercentSign",
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return c and c.hidePercentSign == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.hidePercentSign = value and true or false
						queueRefresh()
					end,
					default = false,
				}

				settingsList[#settingsList + 1] = {
					name = HUD_EDIT_MODE_SETTING_OBJECTIVE_TRACKER_TEXT_SIZE,
					kind = settingType.Slider,
					allowInput = true,
					field = "fontSize",
					minValue = 6,
					maxValue = 64,
					valueStep = 1,
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						return c and c.fontSize or 16
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						if not setIfChanged(c, "fontSize", value) then return end
						queueRefresh()
					end,
					default = 16,
				}

				settingsList[#settingsList + 1] = {
					name = L["Text X Offset"] or "Text Offset X",
					kind = settingType.Slider,
					allowInput = true,
					field = "textOffsetX",
					minValue = -500,
					maxValue = 500,
					valueStep = 1,
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						local off = c and c.textOffset
						return off and off.x or 0
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.textOffset = c.textOffset or { x = 0, y = 0 }
						local new = value or 0
						if c.textOffset.x == new then return end
						c.textOffset.x = new
						queueRefresh()
					end,
					default = 0,
				}

				settingsList[#settingsList + 1] = {
					name = L["Text Y Offset"] or "Text Offset Y",
					kind = settingType.Slider,
					allowInput = true,
					field = "textOffsetY",
					minValue = -500,
					maxValue = 500,
					valueStep = 1,
					parentId = "textsettings",
					get = function()
						local c = curSpecCfg()
						local off = c and c.textOffset
						return off and off.y or 0
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.textOffset = c.textOffset or { x = 0, y = 0 }
						local new = value or 0
						if c.textOffset.y == new then return end
						c.textOffset.y = new
						queueRefresh()
					end,
					default = 0,
				}

				settingsList[#settingsList + 1] = {
					name = L["Font"] or "Font",
					kind = settingType.DropdownColor,
					height = 180,
					field = "fontFace",
					parentId = "textsettings",
					generator = function(_, root)
						local function currentFontSetting()
							local c = curSpecCfg()
							return (c and c.fontFace) or cfg.fontFace or globalFontConfigKey()
						end
						local function currentFontPath()
							local configured = currentFontSetting()
							if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, globalFontDefaultPath()) end
							return configured or globalFontDefaultPath()
						end
						local currentPath = currentFontPath()
						local globalFontValue = globalFontConfigKey()
						local function isGlobalSelected() return currentFontSetting() == globalFontValue end
						root:CreateCheckbox(globalFontConfigLabel(), function() return currentFontSetting() == globalFontValue end, function()
							local c = curSpecCfg()
							if not c then return end
							c.fontFace = globalFontValue
							queueRefresh()
						end)
						local seen = {}
						local names, hash = getCachedLSMMedia("font")
						for i = 1, #names do
							local name = names[i]
							local path = hash[name] or name
							seen[path] = name
							root:CreateCheckbox(name, function() return (not isGlobalSelected()) and currentFontPath() == path end, function()
								local c = curSpecCfg()
								if not c then return end
								if (not isGlobalSelected()) and currentFontPath() == path then return end
								c.fontFace = path
								queueRefresh()
							end)
						end
						if currentPath and not seen[currentPath] then
							local label = tostring(currentPath)
							root:CreateCheckbox(label, function() return (not isGlobalSelected()) and currentFontPath() == currentPath end, function()
								local c = curSpecCfg()
								if not c then return end
								if (not isGlobalSelected()) and currentFontPath() == currentPath then return end
								c.fontFace = currentPath
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						return (c and c.fontFace) or cfg.fontFace or globalFontConfigKey()
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontFace = value
						queueRefresh()
					end,
					colorDefault = { r = 1, g = 1, b = 1, a = 1 },
					colorGet = function()
						local c = curSpecCfg()
						local col = (c and c.fontColor) or (cfg and cfg.fontColor) or { 1, 1, 1, 1 }
						local r, g, b, a = toColorComponents(col, { 1, 1, 1, 1 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontColor = toColorArray(value, { 1, 1, 1, 1 })
						queueRefresh()
					end,
					hasOpacity = true,
					default = globalFontConfigKey(),
				}

				local outlineOptions = getFontStyleEntries()
				settingsList[#settingsList + 1] = {
					name = L["Outline"],
					kind = settingType.Dropdown,
					height = 180,
					field = "fontOutline",
					parentId = "textsettings",
					generator = function(_, root)
						for _, entry in ipairs(outlineOptions) do
							root:CreateCheckbox(entry.label, function()
								local c = curSpecCfg()
								local cur = normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
								return cur == entry.key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								local cur = normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
								if cur == entry.key then return end
								c.fontOutline = normalizeFontStyleChoice(entry.key, "OUTLINE")
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						return normalizeFontStyleChoice((c and c.fontOutline) or cfg.fontOutline, "OUTLINE")
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.fontOutline = normalizeFontStyleChoice(value, "OUTLINE")
						queueRefresh()
					end,
					default = "OUTLINE",
				}
			end

			if not sharedSlot then
			do -- Global profile helpers
				local function syncSizeFromConfig()
					local c = curSpecCfg()
					if not c then return end
					local w = c.width or widthDefault or 200
					local h = c.height or heightDefault or 20
					if EditMode and EditMode.SetValue and frameId then
						EditMode:SetValue(frameId, "width", w, nil, true)
						EditMode:SetValue(frameId, "height", h, nil, true)
					end
					if barType == "HEALTH" then
						ResourceBars.SetHealthBarSize(w, h)
					else
						ResourceBars.SetPowerBarSize(w, h, barType)
					end
				end

				local function saveGlobal(targetKey, label)
					local specInfo = currentSpecInfo()
					if ResourceBars.SaveGlobalProfile then
						confirmSaveGlobal(targetKey, function()
							local ok = ResourceBars.SaveGlobalProfile(barType, addon.variables.unitSpec, targetKey)
							if ok then
								if targetKey == "MAIN" or (not targetKey and specInfo and specInfo.MAIN == barType) then
									notify(L["SavedGlobalMainProfile"] or "Saved global main profile")
								else
									notify((L["SavedGlobalProfile"] or "Saved global profile for %s"):format(label or titleLabel))
								end
							else
								notify(L["GlobalProfileSaveFailed"] or "Could not save global profile.")
							end
						end)
					end
				end

				local function applyGlobal(targetKey, label)
					local specInfo = currentSpecInfo()
					if ResourceBars.ApplyGlobalProfile then
						local ok, reason = ResourceBars.ApplyGlobalProfile(barType, addon.variables.unitSpec, nil, targetKey)
						if ok then
							syncSizeFromConfig()
							queueRefresh()
							refreshSettingsUI()
							if targetKey == "MAIN" or (not targetKey and specInfo and specInfo.MAIN == barType) then
								notify(L["AppliedGlobalMainProfile"] or "Applied global main profile")
							else
								notify((L["AppliedGlobalProfile"] or "Applied global profile for %s"):format(label or titleLabel))
							end
						else
							if reason == "NO_GLOBAL" then
								notify(L["GlobalProfileMissing"] or "No global profile saved for this bar.")
							else
								notify(L["GlobalProfileApplyFailed"] or "Could not apply global profile.")
							end
						end
					end
				end

				local function globalProfileOptions()
					local opts = {}
					local specInfo = currentSpecInfo()
					local isMain = specInfo and specInfo.MAIN == barType
					local powerLabel = titleLabel
					if isMain then opts[#opts + 1] = { label = L["UseAsGlobalMainProfile"] or "Use as global main profile", action = function() saveGlobal("MAIN", powerLabel) end } end
					opts[#opts + 1] = { label = (L["UseAsGlobalProfile"] or "Use as global %s profile"):format(powerLabel), action = function() saveGlobal(barType, powerLabel) end }
					opts[#opts + 1] = { label = L["ApplyGlobalMainProfile"] or "Apply global main profile", action = function() applyGlobal("MAIN", powerLabel) end }
					opts[#opts + 1] = { label = (L["ApplyGlobalProfile"] or "Apply global %s profile"):format(powerLabel), action = function() applyGlobal(barType, powerLabel) end }
					return opts
				end

				table.insert(settingsList, 1, {
					name = SETTINGS or L["Settings"] or "Settings",
					kind = settingType.Collapsible,
					id = "profiles",
					defaultCollapsed = true,
				})

				table.insert(settingsList, 2, {
					name = SETTINGS or L["Settings"] or "Settings",
					kind = settingType.Dropdown,
					height = 180,
					hideSummary = true,
					parentId = "profiles",
					generator = function(_, root)
						for _, opt in ipairs(globalProfileOptions()) do
							root:CreateRadio(opt.label, function() return false end, opt.action)
						end
					end,
				})
			end
			end

			if barType ~= "STAGGER" then
				local powerColorParentId = "colorsetting"

				if genericSharedPowerEditor then
					powerColorParentId = "powercolorsetting"

					settingsList[#settingsList + 1] = {
						name = L["ResourceBarsPowerColor"] or "Power color",
						kind = settingType.Collapsible,
						id = powerColorParentId,
						defaultCollapsed = true,
					}

					settingsList[#settingsList + 1] = {
						name = L["ResourceBarsPowerColorType"] or "Power type",
						kind = settingType.Dropdown,
						height = 180,
						field = "powerTypeOverrideType",
						parentId = powerColorParentId,
						generator = function(_, root)
							for _, pType in ipairs(collectSharedPowerTypes()) do
								root:CreateRadio(powerTypeLabel(pType), function()
									return selectedSharedPowerTypeTarget() == pType
								end, function()
									if selectedSharedPowerType == pType then return end
									selectedSharedPowerType = pType
									if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
								end)
							end
						end,
						get = function() return selectedSharedPowerTypeTarget() end,
						set = function(_, value)
							selectedSharedPowerType = value
							if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
						end,
						default = currentEditorPowerType() or barType,
					}

					settingsList[#settingsList + 1] = {
						name = L["ResourceBarsOverridePowerColor"] or "Override power type styling",
						kind = settingType.Checkbox,
						field = "powerTypeOverrideEnabled",
						parentId = powerColorParentId,
						get = function()
							return isPowerTypeOverrideEnabled()
						end,
						set = function(_, value)
							local base = curSpecCfg()
							local entry = ensurePowerTypeOverrideEntry(selectedSharedPowerTypeTarget())
							if not entry then return end
							entry.enabled = value and true or false
							if value and base then
								local hasStoredFields = false
								for _, key in ipairs((ResourceBars and ResourceBars.POWER_TYPE_STYLE_OVERRIDE_KEYS) or {}) do
									if entry[key] ~= nil then
										hasStoredFields = true
										break
									end
								end
								if not hasStoredFields then
									for _, key in ipairs((ResourceBars and ResourceBars.POWER_TYPE_STYLE_OVERRIDE_KEYS) or {}) do
										if entry[key] == nil and base[key] ~= nil then
											entry[key] = type(base[key]) == "table" and CopyTable(base[key]) or base[key]
										end
									end
								end
							end
							queueRefresh()
							if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
						end,
					}

					settingsList[#settingsList + 1] = {
						name = L["ResourceBarsDefaultPowerColor"] or "Default power color",
						kind = settingType.CheckboxColor,
						field = "defaultPowerColor",
						parentId = powerColorParentId,
						default = false,
						get = function()
							local pType = selectedSharedPowerTypeTarget()
							return getDefaultPowerColorEntry(pType) ~= nil
						end,
						set = function(_, value)
							local pType = selectedSharedPowerTypeTarget()
							if not pType then return end
							if value then
								local baseColor = getDefaultPowerColorEntry(pType) or sharedPowerTypeBaseColor(pType) or { 1, 1, 1, 1 }
								local entry = ensureDefaultPowerColorEntry(pType)
								if not entry then return end
								entry[1], entry[2], entry[3], entry[4] = baseColor[1] or 1, baseColor[2] or 1, baseColor[3] or 1, baseColor[4] or 1
							else
								clearDefaultPowerColorEntry(pType)
							end
							queueRefresh()
							refreshSettingsUI()
						end,
						colorDefault = { r = 1, g = 1, b = 1, a = 1 },
						colorGet = function()
							local pType = selectedSharedPowerTypeTarget()
							local col = getDefaultPowerColorEntry(pType) or sharedPowerTypeBaseColor(pType) or { 1, 1, 1, 1 }
							return toUIColor(col, { 1, 1, 1, 1 })
						end,
						colorSet = function(_, value)
							local pType = selectedSharedPowerTypeTarget()
							local fallback = sharedPowerTypeBaseColor(pType) or { 1, 1, 1, 1 }
							local entry = ensureDefaultPowerColorEntry(pType)
							if not entry then return end
							local col = toColorArray(value, fallback)
							entry[1], entry[2], entry[3], entry[4] = col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1
							queueRefresh()
						end,
							hasOpacity = true,
						}
				else
					settingsList[#settingsList + 1] = {
						name = COLOR,
						kind = settingType.Collapsible,
						id = "colorsetting",
						defaultCollapsed = true,
					}
				end

				settingsList[#settingsList + 1] = {
					name = L["Custom bar color"] or "Custom bar color",
					kind = settingType.CheckboxColor,
					field = "useBarColor",
					default = false,
					get = function()
						return readPowerConfigField("useBarColor", false) == true
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.useBarColor = value and true or false
						if c.useBarColor then c.useClassColor = false end
						queueRefresh()
						if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
					end,
					colorDefault = toUIColor(readPowerConfigField("barColor", { 1, 1, 1, 1 }), { 1, 1, 1, 1 }),
					colorGet = function()
						local col = readPowerConfigField("barColor", { 1, 1, 1, 1 })
						local r, g, b, a = toColorComponents(col, { 1, 1, 1, 1 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.barColor = toColorArray(value, { 1, 1, 1, 1 })
						queueRefresh()
					end,
					isEnabled = function()
						return readPowerConfigField("useClassColor", false) ~= true
					end,
					hasOpacity = true,
					parentId = powerColorParentId,
				}

				if barType ~= "RUNES" or genericSharedPowerEditor then
					settingsList[#settingsList + 1] = {
						name = L["Use class color"] or "Use class color",
						kind = settingType.Checkbox,
						field = "useClassColor",
						get = function()
							return readPowerConfigField("useClassColor", false) == true
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.useClassColor = value and true or false
							if c.useClassColor then c.useBarColor = false end
							queueRefresh()
							if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
						end,
						isEnabled = function()
							return readPowerConfigField("useBarColor", false) ~= true
						end,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() ~= "RUNES"
						end,
						hasOpacity = true,
						default = false,
						parentId = powerColorParentId,
					}
				end

				settingsList[#settingsList + 1] = {
					name = L["Use gradient"] or "Use gradient",
					kind = settingType.Checkbox,
					field = "useGradient",
					get = function()
						return readPowerConfigField("useGradient", false) == true
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.useGradient = value and true or false
						queueRefresh()
						refreshSettingsUI()
					end,
					default = false,
					parentId = powerColorParentId,
				}

				settingsList[#settingsList + 1] = {
					name = L["Gradient start color"] or "Gradient start color",
					kind = settingType.Color,
					parentId = powerColorParentId,
					get = function()
						return toUIColor(readPowerConfigField("gradientStartColor", { 1, 1, 1, 1 }), { 1, 1, 1, 1 })
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.gradientStartColor = toColorArray(value, { 1, 1, 1, 1 })
						queueRefresh()
					end,
					default = { r = 1, g = 1, b = 1, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						return readPowerConfigField("useGradient", false) == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Gradient end color"] or "Gradient end color",
					kind = settingType.Color,
					parentId = powerColorParentId,
					get = function()
						return toUIColor(readPowerConfigField("gradientEndColor", { 1, 1, 1, 1 }), { 1, 1, 1, 1 })
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.gradientEndColor = toColorArray(value, { 1, 1, 1, 1 })
						queueRefresh()
					end,
					default = { r = 1, g = 1, b = 1, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						return readPowerConfigField("useGradient", false) == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Gradient direction"] or "Gradient direction",
					kind = settingType.Dropdown,
					height = 80,
					field = "gradientDirection",
					parentId = powerColorParentId,
					generator = function(_, root)
						local function getDir()
							local v = readPowerConfigField("gradientDirection", "VERTICAL")
							if type(v) == "string" then v = v:upper() end
							return v == "HORIZONTAL" and "HORIZONTAL" or "VERTICAL"
						end
						local function setDir(value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.gradientDirection = value == "HORIZONTAL" and "HORIZONTAL" or "VERTICAL"
							queueRefresh()
						end
						root:CreateRadio(L["Vertical"] or "Vertical", function() return getDir() == "VERTICAL" end, function() setDir("VERTICAL") end)
						root:CreateRadio(L["Horizontal"] or "Horizontal", function() return getDir() == "HORIZONTAL" end, function() setDir("HORIZONTAL") end)
					end,
					get = function()
						local v = readPowerConfigField("gradientDirection", "VERTICAL")
						if type(v) == "string" then v = v:upper() end
						return v == "HORIZONTAL" and "HORIZONTAL" or "VERTICAL"
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						if type(value) == "string" then value = value:upper() end
						c.gradientDirection = value == "HORIZONTAL" and "HORIZONTAL" or "VERTICAL"
						queueRefresh()
					end,
					default = "VERTICAL",
					isEnabled = function()
						return readPowerConfigField("useGradient", false) == true
					end,
				}

				if barType == "RUNES" or genericSharedPowerEditor then
					settingsList[#settingsList + 1] = {
						name = L["Rune cooldown color"] or "Rune cooldown color",
						kind = settingType.Color,
						parentId = powerColorParentId,
						get = function()
							return toUIColor(readPowerConfigField("runeCooldownColor", { 0.35, 0.35, 0.35, 1 }), { 0.35, 0.35, 0.35, 1 })
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.runeCooldownColor = toColorArray(value, { 0.35, 0.35, 0.35, 1 })
							queueRefresh()
						end,
						default = { r = 0.35, g = 0.35, b = 0.35, a = 1 },
						hasOpacity = true,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() == "RUNES"
						end,
					}
				end

				if barType == "HOLY_POWER" or genericSharedPowerEditor then
					settingsList[#settingsList + 1] = {
						name = L["Use 3 HP color"] or "Use custom color at 3 Holy Power",
						kind = settingType.CheckboxColor,
						field = "useHolyThreeColor",
						default = false,
						get = function()
							return readPowerConfigField("useHolyThreeColor", false) == true
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.useHolyThreeColor = value and true or false
							queueRefresh()
						end,
						colorDefault = toUIColor(readPowerConfigField("holyThreeColor", { 1, 0.8, 0.2, 1 }), { 1, 0.8, 0.2, 1 }),
						colorGet = function()
							local col = readPowerConfigField("holyThreeColor", { 1, 0.8, 0.2, 1 })
							local r, g, b, a = toColorComponents(col, { 1, 0.8, 0.2, 1 })
							return { r = r, g = g, b = b, a = a }
						end,
						colorSet = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.holyThreeColor = toColorArray(value, { 1, 0.8, 0.2, 1 })
							queueRefresh()
						end,
						hasOpacity = true,
						parentId = powerColorParentId,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() == "HOLY_POWER"
						end,
					}
				end

				if addon.variables.unitClass == "ROGUE" and (barType == "COMBO_POINTS" or genericSharedPowerEditor) then
					local function chargedCfg()
						local c = currentPowerConfigTarget()
						if not c then return nil end
						if ResourceBars and ResourceBars.EnsureRogueChargedComboDefaults then ResourceBars.EnsureRogueChargedComboDefaults(c, currentEditorPowerType() or "COMBO_POINTS") end
						return c
					end
					local function isChargedComboEditorShown()
						return not genericSharedPowerEditor or currentEditorPowerType() == "COMBO_POINTS"
					end

					local function percentFromUnit(value, fallback)
						local n = tonumber(value)
						if n == nil then n = tonumber(fallback) or 0 end
						if n < 0 then
							n = 0
						elseif n > 1 then
							n = 1
						end
						return math.floor((n * 100) + 0.5)
					end

					local function unitFromPercent(value, fallback)
						local n = tonumber(value)
						if n == nil then n = tonumber(fallback) or 0 end
						n = n / 100
						if n < 0 then
							n = 0
						elseif n > 1 then
							n = 1
						end
						return n
					end

					settingsList[#settingsList + 1] = {
						name = L["Charged combo point styling"] or "Charged combo point styling",
						kind = settingType.Checkbox,
						field = "useChargedComboStyling",
						default = ROGUE_CHARGED_COMBO_DEFAULTS.enabled ~= false,
						get = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.useChargedComboStyling = value and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Affect charged fill"] or "Affect charged fill",
						kind = settingType.Checkbox,
						field = "chargedComboAffectFill",
						default = ROGUE_CHARGED_COMBO_DEFAULTS.affectFill ~= false,
						get = function()
							local c = chargedCfg()
							return c and c.chargedComboAffectFill ~= false
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboAffectFill = value and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Custom charged fill color"] or "Custom charged fill color",
						kind = settingType.CheckboxColor,
						field = "chargedComboUseCustomFillColor",
						default = ROGUE_CHARGED_COMBO_DEFAULTS.fillUseCustomColor == true,
						get = function()
							local c = chargedCfg()
							return c and c.chargedComboUseCustomFillColor == true
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboUseCustomFillColor = value and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						colorDefault = toUIColor(ROGUE_CHARGED_COMBO_DEFAULTS.fillColor, { 1.0, 0.95, 0.45, 1.0 }),
						colorGet = function()
							local c = chargedCfg()
							local col = (c and c.chargedComboFillColor) or ROGUE_CHARGED_COMBO_DEFAULTS.fillColor or { 1.0, 0.95, 0.45, 1.0 }
							local r, g, b, a = toColorComponents(col, { 1.0, 0.95, 0.45, 1.0 })
							return { r = r, g = g, b = b, a = a }
						end,
						colorSet = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboFillColor = toColorArray(value, ROGUE_CHARGED_COMBO_DEFAULTS.fillColor or { 1.0, 0.95, 0.45, 1.0 })
							queueRefresh()
						end,
						hasOpacity = true,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectFill ~= false
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Auto charged fill highlight"] or "Auto charged fill highlight (%)",
						kind = settingType.Slider,
						allowInput = true,
						field = "chargedComboFillLighten",
						minValue = 0,
						maxValue = 100,
						valueStep = 1,
						default = percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.fillLighten, 0.35),
						get = function()
							local c = chargedCfg()
							return percentFromUnit(c and c.chargedComboFillLighten, ROGUE_CHARGED_COMBO_DEFAULTS.fillLighten or 0.35)
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboFillLighten = unitFromPercent(value, percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.fillLighten, 0.35))
							queueRefresh()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectFill ~= false and c.chargedComboUseCustomFillColor ~= true
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Auto charged fill alpha"] or "Auto charged fill alpha boost (%)",
						kind = settingType.Slider,
						allowInput = true,
						field = "chargedComboFillAlphaBoost",
						minValue = 0,
						maxValue = 100,
						valueStep = 1,
						default = percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.fillAlphaBoost, 0.10),
						get = function()
							local c = chargedCfg()
							return percentFromUnit(c and c.chargedComboFillAlphaBoost, ROGUE_CHARGED_COMBO_DEFAULTS.fillAlphaBoost or 0.10)
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboFillAlphaBoost = unitFromPercent(value, percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.fillAlphaBoost, 0.10))
							queueRefresh()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectFill ~= false and c.chargedComboUseCustomFillColor ~= true
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Affect charged background"] or "Affect charged background",
						kind = settingType.Checkbox,
						field = "chargedComboAffectBackground",
						default = ROGUE_CHARGED_COMBO_DEFAULTS.affectBackground ~= false,
						get = function()
							local c = chargedCfg()
							return c and c.chargedComboAffectBackground ~= false
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboAffectBackground = value and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Custom charged background color"] or "Custom charged background color",
						kind = settingType.CheckboxColor,
						field = "chargedComboUseCustomBackgroundColor",
						default = ROGUE_CHARGED_COMBO_DEFAULTS.backgroundUseCustomColor == true,
						get = function()
							local c = chargedCfg()
							return c and c.chargedComboUseCustomBackgroundColor == true
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboUseCustomBackgroundColor = value and true or false
							queueRefresh()
							refreshSettingsUI()
						end,
						colorDefault = toUIColor(ROGUE_CHARGED_COMBO_DEFAULTS.backgroundColor, { 0.75, 0.60, 0.25, 0.75 }),
						colorGet = function()
							local c = chargedCfg()
							local col = (c and c.chargedComboBackgroundColor) or ROGUE_CHARGED_COMBO_DEFAULTS.backgroundColor or { 0.75, 0.60, 0.25, 0.75 }
							local r, g, b, a = toColorComponents(col, { 0.75, 0.60, 0.25, 0.75 })
							return { r = r, g = g, b = b, a = a }
						end,
						colorSet = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboBackgroundColor = toColorArray(value, ROGUE_CHARGED_COMBO_DEFAULTS.backgroundColor or { 0.75, 0.60, 0.25, 0.75 })
							queueRefresh()
						end,
						hasOpacity = true,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectBackground ~= false
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Auto charged background highlight"] or "Auto charged background highlight (%)",
						kind = settingType.Slider,
						allowInput = true,
						field = "chargedComboBackgroundLighten",
						minValue = 0,
						maxValue = 100,
						valueStep = 1,
						default = percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.backgroundLighten, 0.30),
						get = function()
							local c = chargedCfg()
							return percentFromUnit(c and c.chargedComboBackgroundLighten, ROGUE_CHARGED_COMBO_DEFAULTS.backgroundLighten or 0.30)
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboBackgroundLighten = unitFromPercent(value, percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.backgroundLighten, 0.30))
							queueRefresh()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectBackground ~= false and c.chargedComboUseCustomBackgroundColor ~= true
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}

					settingsList[#settingsList + 1] = {
						name = L["Auto charged background alpha"] or "Auto charged background alpha boost (%)",
						kind = settingType.Slider,
						allowInput = true,
						field = "chargedComboBackgroundAlphaBoost",
						minValue = 0,
						maxValue = 100,
						valueStep = 1,
						default = percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.backgroundAlphaBoost, 0.10),
						get = function()
							local c = chargedCfg()
							return percentFromUnit(c and c.chargedComboBackgroundAlphaBoost, ROGUE_CHARGED_COMBO_DEFAULTS.backgroundAlphaBoost or 0.10)
						end,
						set = function(_, value)
							local c = chargedCfg()
							if not c then return end
							c.chargedComboBackgroundAlphaBoost = unitFromPercent(value, percentFromUnit(ROGUE_CHARGED_COMBO_DEFAULTS.backgroundAlphaBoost, 0.10))
							queueRefresh()
						end,
						isEnabled = function()
							local c = chargedCfg()
							return c and c.useChargedComboStyling ~= false and c.chargedComboAffectBackground ~= false and c.chargedComboUseCustomBackgroundColor ~= true
						end,
						parentId = powerColorParentId,
						isShown = isChargedComboEditorShown,
					}
				end

				if barType == "MAELSTROM_WEAPON" or genericSharedPowerEditor then
					settingsList[#settingsList + 1] = {
						name = "Use stack-threshold color",
						kind = settingType.CheckboxColor,
						field = "useMaelstromFiveColor",
						default = true,
						get = function()
							return readPowerConfigField("useMaelstromFiveColor", true) ~= false
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.useMaelstromFiveColor = value and true or false
							queueRefresh()
						end,
						colorDefault = toUIColor(readPowerConfigField("maelstromFiveColor", { 0.2, 0.7, 1, 1 }), { 0.2, 0.7, 1, 1 }),
						colorGet = function()
							local col = readPowerConfigField("maelstromFiveColor", { 0.2, 0.7, 1, 1 })
							local r, g, b, a = toColorComponents(col, { 0.2, 0.7, 1, 1 })
							return { r = r, g = g, b = b, a = a }
						end,
						colorSet = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.maelstromFiveColor = toColorArray(value, { 0.2, 0.7, 1, 1 })
							queueRefresh()
						end,
						hasOpacity = true,
						parentId = powerColorParentId,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() == "MAELSTROM_WEAPON"
						end,
					}

					settingsList[#settingsList + 1] = {
						name = "Stack threshold for color",
						kind = settingType.Slider,
						allowInput = true,
						field = "maelstromMidStack",
						minValue = 1,
						maxValue = MAELSTROM_MID_STACK_MAX,
						valueStep = 1,
						default = MAELSTROM_MID_STACK_DEFAULT,
						parentId = powerColorParentId,
						get = function()
							local c = currentPowerConfigTarget()
							local cur = tonumber(c and c.maelstromMidStack) or MAELSTROM_MID_STACK_DEFAULT
							cur = math.floor(cur + 0.5)
							if cur < 1 then cur = 1 end
							if cur > MAELSTROM_MID_STACK_MAX then cur = MAELSTROM_MID_STACK_MAX end
							return cur
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							local new = tonumber(value) or MAELSTROM_MID_STACK_DEFAULT
							new = math.floor(new + 0.5)
							if new < 1 then new = 1 end
							if new > MAELSTROM_MID_STACK_MAX then new = MAELSTROM_MID_STACK_MAX end
							if c.maelstromMidStack == new then return end
							c.maelstromMidStack = new
							queueRefresh()
						end,
						isEnabled = function()
							return readPowerConfigField("useMaelstromFiveColor", true) ~= false
						end,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() == "MAELSTROM_WEAPON"
						end,
					}

					settingsList[#settingsList + 1] = {
						name = "Carry threshold color above trigger",
						kind = settingType.Checkbox,
						field = "useMaelstromCarryFill",
						default = false,
						parentId = powerColorParentId,
						get = function()
							return readPowerConfigField("useMaelstromCarryFill", false) == true
						end,
						set = function(_, value)
							local c = currentPowerConfigTarget()
							if not c then return end
							c.useMaelstromCarryFill = value and true or false
							queueRefresh()
						end,
						isEnabled = function()
							return readPowerConfigField("useMaelstromFiveColor", true) ~= false
						end,
						isShown = function()
							return not genericSharedPowerEditor or currentEditorPowerType() == "MAELSTROM_WEAPON"
						end,
					}
				end

				settingsList[#settingsList + 1] = {
					name = L["Use max color"] or "Use max color",
					kind = settingType.CheckboxColor,
					field = "useMaxColor",
					default = barType == "MAELSTROM_WEAPON",
					get = function()
						return readPowerConfigField("useMaxColor", barType == "MAELSTROM_WEAPON") == true
					end,
					set = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.useMaxColor = value and true or false
						queueRefresh()
					end,
					colorDefault = toUIColor(readPowerConfigField("maxColor", { 0, 1, 0, 1 }), { 0, 1, 0, 1 }),
					colorGet = function()
						local col = readPowerConfigField("maxColor", { 0, 1, 0, 1 })
						local r, g, b, a = toColorComponents(col, { 0, 1, 0, 1 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = currentPowerConfigTarget()
						if not c then return end
						c.maxColor = toColorArray(value, { 0, 1, 0, 1 })
						queueRefresh()
					end,
					hasOpacity = true,
					parentId = powerColorParentId,
				}
			end

			if barType == "STAGGER" then
				local staggerLowDefaultColor = (STAGGER_FALLBACK_COLORS and STAGGER_FALLBACK_COLORS.green) or { 0.52, 1.0, 0.52, 1 }
				local staggerMediumDefaultColor = (STAGGER_FALLBACK_COLORS and STAGGER_FALLBACK_COLORS.yellow) or { 1.0, 0.98, 0.72, 1 }
				local staggerHighDefaultColor = (STAGGER_FALLBACK_COLORS and STAGGER_FALLBACK_COLORS.red) or { 1.0, 0.42, 0.42, 1 }

				settingsList[#settingsList + 1] = {
					name = L["Colors"] or "Stagger colors",
					kind = settingType.Collapsible,
					id = "staggercolors",
					defaultCollapsed = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Use stagger max override"] or "Use stagger max override (200%+)",
					kind = settingType.Checkbox,
					field = "useStaggerMaxOverride",
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return c and c.useStaggerMaxOverride == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.useStaggerMaxOverride = value and true or false
						if c.useStaggerMaxOverride == true and tonumber(c.staggerMaxPercent) == nil then c.staggerMaxPercent = 200 end
						queueRefresh()
					end,
					default = false,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger bar max value"] or "Stagger bar max value (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerMaxPercent",
					minValue = 100,
					maxValue = 400,
					valueStep = 10,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerMaxPercent) or 200
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerMaxPercent = value
						queueRefresh()
					end,
					default = 200,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.useStaggerMaxOverride == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger low threshold"] or "Stagger low threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerLowThreshold",
					minValue = 0,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 1,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerLowThreshold) or STAGGER_LOW_THRESHOLD
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local low = math.max(0, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_LOW_THRESHOLD))
						c.staggerLowThreshold = low
						local medium = tonumber(c.staggerMediumThreshold) or STAGGER_MEDIUM_THRESHOLD
						if medium < low then
							medium = low
							c.staggerMediumThreshold = medium
						end
						local high = tonumber(c.staggerHighThreshold) or STAGGER_EXTRA_THRESHOLD_HIGH
						if high < medium then c.staggerHighThreshold = medium end
						queueRefresh()
					end,
					default = STAGGER_LOW_THRESHOLD,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger low color"] or "Stagger low color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerLowColor) or staggerLowDefaultColor, staggerLowDefaultColor)
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerLowColor = toColorArray(value, staggerLowDefaultColor)
						queueRefresh()
					end,
					default = { r = 0.52, g = 1.0, b = 0.52, a = 1 },
					hasOpacity = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger medium threshold"] or "Stagger medium threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerMediumThreshold",
					minValue = 0,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 1,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerMediumThreshold) or STAGGER_MEDIUM_THRESHOLD
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local low = tonumber(c.staggerLowThreshold) or STAGGER_LOW_THRESHOLD
						low = math.max(0, math.min(STAGGER_THRESHOLD_MAX, low))
						local medium = math.max(low, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_MEDIUM_THRESHOLD))
						c.staggerMediumThreshold = medium
						local high = tonumber(c.staggerHighThreshold) or STAGGER_EXTRA_THRESHOLD_HIGH
						if high < medium then c.staggerHighThreshold = medium end
						queueRefresh()
					end,
					default = STAGGER_MEDIUM_THRESHOLD,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger medium color"] or "Stagger medium color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerMediumColor) or staggerMediumDefaultColor, staggerMediumDefaultColor)
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerMediumColor = toColorArray(value, staggerMediumDefaultColor)
						queueRefresh()
					end,
					default = { r = 1.0, g = 0.98, b = 0.72, a = 1 },
					hasOpacity = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger high threshold"] or "Stagger high threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerHighThreshold",
					minValue = 100,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 10,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerHighThreshold) or STAGGER_EXTRA_THRESHOLD_HIGH
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local medium = tonumber(c.staggerMediumThreshold) or STAGGER_MEDIUM_THRESHOLD
						medium = math.max(0, math.min(STAGGER_THRESHOLD_MAX, medium))
						local high = math.max(medium, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_EXTRA_THRESHOLD_HIGH))
						c.staggerHighThreshold = high
						local veryHigh = tonumber(c.staggerVeryHighThreshold) or STAGGER_EXTRA_THRESHOLD_VERY_HIGH
						if veryHigh < high then c.staggerVeryHighThreshold = high end
						queueRefresh()
					end,
					default = STAGGER_EXTRA_THRESHOLD_HIGH,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger high color"] or "Stagger high color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerBaseHighColor) or staggerHighDefaultColor, staggerHighDefaultColor)
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerBaseHighColor = toColorArray(value, staggerHighDefaultColor)
						queueRefresh()
					end,
					default = { r = 1.0, g = 0.42, b = 0.42, a = 1 },
					hasOpacity = true,
				}

				settingsList[#settingsList + 1] = {
					name = L["Use extended stagger colors"] or "Use extended stagger colors",
					kind = settingType.Checkbox,
					field = "staggerHighColors",
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerHighColors = value and true or false
						queueRefresh()
					end,
					default = false,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger very high threshold"] or "Stagger very high threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerVeryHighThreshold",
					minValue = 100,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 10,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerVeryHighThreshold) or STAGGER_EXTRA_THRESHOLD_VERY_HIGH
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local high = tonumber(c.staggerHighThreshold) or STAGGER_EXTRA_THRESHOLD_HIGH
						high = math.max(0, math.min(STAGGER_THRESHOLD_MAX, high))
						local veryHigh = math.max(high, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_EXTRA_THRESHOLD_VERY_HIGH))
						c.staggerVeryHighThreshold = veryHigh
						local extreme = tonumber(c.staggerExtremeThreshold) or STAGGER_EXTRA_THRESHOLD_EXTREME
						if extreme < veryHigh then c.staggerExtremeThreshold = veryHigh end
						queueRefresh()
					end,
					default = STAGGER_EXTRA_THRESHOLD_VERY_HIGH,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger very high color"] or "Stagger very high color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerHighColor) or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.high) or { 0.62, 0.2, 1, 1 }, { 0.62, 0.2, 1, 1 })
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerHighColor = toColorArray(value, (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.high) or { 0.62, 0.2, 1, 1 })
						queueRefresh()
					end,
					default = { r = 0.62, g = 0.2, b = 1, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger extreme threshold"] or "Stagger extreme threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerExtremeThreshold",
					minValue = 100,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 10,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerExtremeThreshold) or STAGGER_EXTRA_THRESHOLD_EXTREME
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local veryHigh = tonumber(c.staggerVeryHighThreshold) or STAGGER_EXTRA_THRESHOLD_VERY_HIGH
						veryHigh = math.max(0, math.min(STAGGER_THRESHOLD_MAX, veryHigh))
						local extreme = math.max(veryHigh, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_EXTRA_THRESHOLD_EXTREME))
						c.staggerExtremeThreshold = extreme
						local critical = tonumber(c.staggerCriticalThreshold) or STAGGER_EXTRA_THRESHOLD_CRITICAL
						if critical < extreme then c.staggerCriticalThreshold = extreme end
						queueRefresh()
					end,
					default = STAGGER_EXTRA_THRESHOLD_EXTREME,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger extreme color"] or "Stagger extreme color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerVeryHighColor) or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.veryHigh) or { 0.85, 0.2, 1, 1 }, { 0.85, 0.2, 1, 1 })
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerVeryHighColor = toColorArray(value, (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.veryHigh) or { 0.85, 0.2, 1, 1 })
						queueRefresh()
					end,
					default = { r = 0.85, g = 0.2, b = 1, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger critical threshold"] or "Stagger critical threshold (%)",
					kind = settingType.Slider,
					allowInput = true,
					field = "staggerCriticalThreshold",
					minValue = 100,
					maxValue = STAGGER_THRESHOLD_MAX,
					valueStep = 10,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return (c and c.staggerCriticalThreshold) or STAGGER_EXTRA_THRESHOLD_CRITICAL
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local extreme = tonumber(c.staggerExtremeThreshold) or STAGGER_EXTRA_THRESHOLD_EXTREME
						extreme = math.max(0, math.min(STAGGER_THRESHOLD_MAX, extreme))
						local critical = math.max(extreme, math.min(STAGGER_THRESHOLD_MAX, tonumber(value) or STAGGER_EXTRA_THRESHOLD_CRITICAL))
						c.staggerCriticalThreshold = critical
						queueRefresh()
					end,
					default = STAGGER_EXTRA_THRESHOLD_CRITICAL,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger critical color"] or "Stagger critical color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerExtremeColor) or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.extreme) or { 1, 0.2, 0.8, 1 }, { 1, 0.2, 0.8, 1 })
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerExtremeColor = toColorArray(value, (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.extreme) or { 1, 0.2, 0.8, 1 })
						queueRefresh()
					end,
					default = { r = 1, g = 0.2, b = 0.8, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Stagger deadly color"] or "Stagger deadly color",
					kind = settingType.Color,
					parentId = "staggercolors",
					get = function()
						local c = curSpecCfg()
						return toUIColor((c and c.staggerCriticalColor) or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.critical) or { 1, 0.1, 0.45, 1 }, { 1, 0.1, 0.45, 1 })
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.staggerCriticalColor = toColorArray(value, (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.critical) or { 1, 0.1, 0.45, 1 })
						queueRefresh()
					end,
					default = { r = 1, g = 0.1, b = 0.45, a = 1 },
					hasOpacity = true,
					isEnabled = function()
						local c = curSpecCfg()
						return c and c.staggerHighColors == true
					end,
				}
			end

			if barType ~= "HEALTH" and barType ~= "STAGGER" then
				local function thresholdColorModeAndCap()
					if barType == "VOID_METAMORPHOSIS" then return "ABSOLUTE", ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_VOID_METAMORPHOSIS, 1 end
					if barType == "MANA" or barType == "ENERGY" or barType == "RAGE" or barType == "FURY" or barType == "FOCUS" or barType == "INSANITY" or barType == "LUNAR_POWER" then
						return "PERCENT", ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_PERCENT, 0
					end
					if ResourceBars and ResourceBars.GetThresholdColorModeAndCap then
						local mode, cap, minValue = ResourceBars.GetThresholdColorModeAndCap(barType)
						return mode or "ABSOLUTE", tonumber(cap) or ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP, tonumber(minValue) or 1
					end
					if ResourceBars and ResourceBars.separatorEligible and ResourceBars.separatorEligible[barType] then return "ABSOLUTE", ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP, 1 end
					return "ABSOLUTE", ABSOLUTE_THRESHOLD_COLOR_VALUE_CAP_CONTINUOUS, 1
				end

				local thresholdMode, thresholdValueCap, thresholdValueMin = thresholdColorModeAndCap()
				local isPercentThresholdMode = thresholdMode == "PERCENT"

				local function clampAbsoluteThresholdValue(value)
					local n = tonumber(value)
					if n == nil then return nil end
					if isPercentThresholdMode then
						n = math.floor((n * 10) + 0.5) / 10
					else
						n = math.floor(n + 0.5)
					end
					if n < thresholdValueMin then n = thresholdValueMin end
					if n > thresholdValueCap then n = thresholdValueCap end
					return n
				end

				local function getDefaultAbsoluteThresholdPoint(index)
					if ResourceBars and ResourceBars.GetDefaultAbsoluteThresholdColorPoint then
						local value, color = ResourceBars.GetDefaultAbsoluteThresholdColorPoint(index, barType)
						local r, g, b, a = toColorComponents(color, { 1, 1, 1, 1 })
						return clampAbsoluteThresholdValue(value) or clampAbsoluteThresholdValue(index) or thresholdValueMin, { r, g, b, a }
					end
					local fallback = ABSOLUTE_THRESHOLD_COLOR_DEFAULTS[index] or ABSOLUTE_THRESHOLD_COLOR_DEFAULTS[#ABSOLUTE_THRESHOLD_COLOR_DEFAULTS] or { value = index, color = { 1, 1, 1, 1 } }
					local value = clampAbsoluteThresholdValue(fallback.value or fallback[1]) or clampAbsoluteThresholdValue(index) or 1
					local color = fallback.color or fallback[2] or { 1, 1, 1, 1 }
					local r, g, b, a = toColorComponents(color, { 1, 1, 1, 1 })
					return value, { r, g, b, a }
				end

				local function isAbsoluteThresholdColorsEnabled()
					local c = curSpecCfg()
					return c and c.useAbsoluteThresholdColors == true
				end

				local function getAbsoluteThresholdPointCount()
					local c = curSpecCfg()
					local count = tonumber(c and c.absoluteThresholdColorPointCount) or tonumber(cfg and cfg.absoluteThresholdColorPointCount) or ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT
					if count < 1 then count = 1 end
					if count > ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS then count = ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS end
					return math.floor(count + 0.5)
				end

				local function ensureAbsoluteThresholdPoint(index)
					local c = curSpecCfg()
					if not c then return nil end
					if type(c.absoluteThresholdColorPoints) ~= "table" then c.absoluteThresholdColorPoints = {} end
					local point = c.absoluteThresholdColorPoints[index]
					if type(point) ~= "table" then
						point = {}
						c.absoluteThresholdColorPoints[index] = point
					end
					local defaultValue, defaultColor = getDefaultAbsoluteThresholdPoint(index)
					local value = clampAbsoluteThresholdValue(point.value or point[1]) or defaultValue
					point.value = value
					local color = point.color or point[2]
					local r, g, b, a = toColorComponents(color, defaultColor)
					point.color = { r, g, b, a }
					return point, defaultValue, defaultColor
				end

				local function getAbsoluteThresholdPointValue(index)
					local c = curSpecCfg()
					local points = (c and c.absoluteThresholdColorPoints)
					if type(points) ~= "table" then points = cfg and cfg.absoluteThresholdColorPoints end
					local point = type(points) == "table" and points[index] or nil
					local defaultValue = select(1, getDefaultAbsoluteThresholdPoint(index))
					return clampAbsoluteThresholdValue(point and (point.value or point[1])) or defaultValue
				end

				local function setAbsoluteThresholdPointValue(index, value)
					local c = curSpecCfg()
					if not c then return end
					local point, defaultValue = ensureAbsoluteThresholdPoint(index)
					if not point then return end
					point.value = clampAbsoluteThresholdValue(value) or defaultValue
					queueRefresh()
				end

				local function getAbsoluteThresholdPointUIColor(index)
					local c = curSpecCfg()
					local points = (c and c.absoluteThresholdColorPoints)
					if type(points) ~= "table" then points = cfg and cfg.absoluteThresholdColorPoints end
					local point = type(points) == "table" and points[index] or nil
					local _, defaultColor = getDefaultAbsoluteThresholdPoint(index)
					local color = point and (point.color or point[2]) or defaultColor
					local r, g, b, a = toColorComponents(color, defaultColor)
					return { r = r, g = g, b = b, a = a }
				end

				local function setAbsoluteThresholdPointColor(index, value)
					local c = curSpecCfg()
					if not c then return end
					local point, _, defaultColor = ensureAbsoluteThresholdPoint(index)
					if not point then return end
					point.color = toColorArray(value, defaultColor)
					queueRefresh()
				end

				settingsList[#settingsList + 1] = {
					name = (isPercentThresholdMode and (L["Threshold colors"] or "Threshold colors")) or (L["Absolute threshold colors"] or "Absolute threshold colors"),
					kind = settingType.Collapsible,
					id = "absolutethresholdcolors",
					defaultCollapsed = true,
				}

				settingsList[#settingsList + 1] = {
					name = (isPercentThresholdMode and (L["Use threshold colors"] or "Use threshold colors")) or (L["Use absolute threshold colors"] or "Use absolute threshold colors"),
					kind = settingType.Checkbox,
					field = "useAbsoluteThresholdColors",
					parentId = "absolutethresholdcolors",
					default = false,
					get = isAbsoluteThresholdColorsEnabled,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						c.useAbsoluteThresholdColors = value and true or false
						if c.useAbsoluteThresholdColors then
							if c.absoluteThresholdColorPointCount == nil then c.absoluteThresholdColorPointCount = ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT end
							local count = getAbsoluteThresholdPointCount()
							for i = 1, count do
								ensureAbsoluteThresholdPoint(i)
							end
						end
						queueRefresh()
						refreshSettingsUI()
					end,
				}

				settingsList[#settingsList + 1] = {
					name = L["Threshold points"] or "Threshold points",
					kind = settingType.Dropdown,
					height = 180,
					field = "absoluteThresholdColorPointCount",
					parentId = "absolutethresholdcolors",
					values = (function()
						local values = {}
						for i = 1, ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS do
							values[#values + 1] = { value = i, label = tostring(i), text = tostring(i) }
						end
						return values
					end)(),
					get = function() return getAbsoluteThresholdPointCount() end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local count = tonumber(value) or ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT
						if count < 1 then count = 1 end
						if count > ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS then count = ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS end
						c.absoluteThresholdColorPointCount = math.floor(count + 0.5)
						for i = 1, c.absoluteThresholdColorPointCount do
							ensureAbsoluteThresholdPoint(i)
						end
						queueRefresh()
						refreshSettingsUI()
					end,
					default = ABSOLUTE_THRESHOLD_COLOR_DEFAULT_COUNT,
					isEnabled = isAbsoluteThresholdColorsEnabled,
				}

				for i = 1, ABSOLUTE_THRESHOLD_COLOR_MAX_POINTS do
					local defaultValue, defaultColor = getDefaultAbsoluteThresholdPoint(i)

					settingsList[#settingsList + 1] = {
						name = string.format((isPercentThresholdMode and (L["Threshold point %d value (%%)"] or "Point %d value (%%)")) or (L["Threshold point %d value"] or "Point %d value"), i),
						kind = settingType.Slider,
						allowInput = true,
						field = "absoluteThresholdPointValue" .. i,
						parentId = "absolutethresholdcolors",
						minValue = thresholdValueMin,
						maxValue = thresholdValueCap,
						valueStep = isPercentThresholdMode and 0.1 or 1,
						get = function() return getAbsoluteThresholdPointValue(i) end,
						set = function(_, value) setAbsoluteThresholdPointValue(i, value) end,
						default = defaultValue,
						formatter = function(value)
							local n = tonumber(value) or 0
							if isPercentThresholdMode then
								n = math.floor((n * 10) + 0.5) / 10
								return string.format("%.1f", n)
							end
							return tostring(math.floor(n + 0.5))
						end,
						isEnabled = isAbsoluteThresholdColorsEnabled,
						isShown = function() return isAbsoluteThresholdColorsEnabled() and i <= getAbsoluteThresholdPointCount() end,
					}

					settingsList[#settingsList + 1] = {
						name = string.format(L["Point %d color"] or "Point %d color", i),
						kind = settingType.Color,
						parentId = "absolutethresholdcolors",
						default = { r = defaultColor[1] or 1, g = defaultColor[2] or 1, b = defaultColor[3] or 1, a = defaultColor[4] or 1 },
						get = function() return getAbsoluteThresholdPointUIColor(i) end,
						set = function(_, value) setAbsoluteThresholdPointColor(i, value) end,
						colorGet = function() return getAbsoluteThresholdPointUIColor(i) end,
						colorSet = function(_, value) setAbsoluteThresholdPointColor(i, value) end,
						hasOpacity = true,
						isEnabled = isAbsoluteThresholdColorsEnabled,
						isShown = function() return isAbsoluteThresholdColorsEnabled() and i <= getAbsoluteThresholdPointCount() end,
					}
				end
			end

			do -- Backdrop
				local function backdropEnabled()
					local c = curSpecCfg()
					local bd = ensureBackdropTable(c)
					return not (bd and bd.enabled == false)
				end

				settingsList[#settingsList + 1] = {
					name = "Backdrop",
					kind = settingType.Collapsible,
					id = "CheckboxGroup",
					defaultCollapsed = true,
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Show backdrop"] or "Show backdrop",
					kind = settingType.Checkbox,
					field = "backdropEnabled",
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.enabled ~= false
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.enabled = value and true or false
						queueRefresh()
						if addon.EditModeLib and addon.EditModeLib.internal then addon.EditModeLib.internal:RefreshSettings() end
					end,
					default = cfg and cfg.backdrop and cfg.backdrop.enabled ~= false,
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Background texture"],
					kind = settingType.DropdownColor,
					height = 180,
					field = "backdropBackground",
					generator = function(_, root)
						local list, order = backgroundDropdownData()
						if not list or not order then return end
						for _, key in ipairs(order) do
							local label = list[key] or key
							root:CreateCheckbox(label, function()
								local c = curSpecCfg()
								local bd = ensureBackdropTable(c)
								return bd and bd.backgroundTexture == key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								local bd = ensureBackdropTable(c)
								if bd and bd.backgroundTexture == key then return end
								bd.backgroundTexture = key
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.backgroundTexture or (cfg and cfg.backdrop and cfg.backdrop.backgroundTexture) or "Interface\\DialogFrame\\UI-DialogBox-Background"
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.backgroundTexture = value
						queueRefresh()
					end,
					colorDefault = toUIColor(cfg and cfg.backdrop and cfg.backdrop.backgroundColor, { 0, 0, 0, 0.8 }),
					colorGet = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						local col = bd and bd.backgroundColor or { 0, 0, 0, 0.8 }
						local r, g, b, a = toColorComponents(col, { 0, 0, 0, 0.8 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.backgroundColor = toColorArray(value, { 0, 0, 0, 0.8 })
						queueRefresh()
					end,
					hasOpacity = true,
					isEnabled = backdropEnabled,
					default = (cfg and cfg.backdrop and cfg.backdrop.backgroundTexture) or "Interface\\DialogFrame\\UI-DialogBox-Background",
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Border texture"],
					kind = settingType.DropdownColor,
					height = 180,
					field = "backdropBorder",
					generator = function(_, root)
						local list, order = borderDropdownData()
						if not list or not order then return end
						for _, key in ipairs(order) do
							local label = list[key] or key
							root:CreateCheckbox(label, function()
								local c = curSpecCfg()
								local bd = ensureBackdropTable(c)
								return bd and bd.borderTexture == key
							end, function()
								local c = curSpecCfg()
								if not c then return end
								local bd = ensureBackdropTable(c)
								if bd and bd.borderTexture == key then return end
								if customBorderOptions() and customBorderOptions()[key] then
									local col = bd.borderColor
									if not col or (col[4] or 0) <= 0 then bd.borderColor = { 1, 1, 1, 1 } end
								end
								bd.borderTexture = key
								queueRefresh()
							end)
						end
					end,
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.borderTexture or (cfg and cfg.backdrop and cfg.backdrop.borderTexture) or "Interface\\Tooltips\\UI-Tooltip-Border"
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						if customBorderOptions() and customBorderOptions()[value] then
							local col = bd.borderColor
							if not col or (col[4] or 0) <= 0 then bd.borderColor = { 1, 1, 1, 1 } end
						end
						bd.borderTexture = value
						queueRefresh()
					end,
					colorDefault = toUIColor(cfg and cfg.backdrop and cfg.backdrop.borderColor, { 0, 0, 0, 0 }),
					colorGet = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						local col = bd and bd.borderColor or { 0, 0, 0, 0 }
						local r, g, b, a = toColorComponents(col, { 0, 0, 0, 0 })
						return { r = r, g = g, b = b, a = a }
					end,
					colorSet = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.borderColor = toColorArray(value, { 0, 0, 0, 0 })
						queueRefresh()
					end,
					hasOpacity = true,
					isEnabled = backdropEnabled,
					default = (cfg and cfg.backdrop and cfg.backdrop.borderTexture) or "Interface\\Tooltips\\UI-Tooltip-Border",
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Border size"] or "Border size",
					kind = settingType.Slider,
					allowInput = true,
					field = "backdropEdgeSize",
					minValue = 0,
					maxValue = 64,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.edgeSize or 3
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.edgeSize = value or 0
						queueRefresh()
					end,
					default = (cfg and cfg.backdrop and cfg.backdrop.edgeSize) or 3,
					isEnabled = backdropEnabled,
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Border offset"] or "Border offset",
					kind = settingType.Slider,
					allowInput = true,
					field = "backdropOutset",
					minValue = 0,
					maxValue = 64,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.outset or 0
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.outset = value or 0
						queueRefresh()
					end,
					default = (cfg and cfg.backdrop and cfg.backdrop.outset) or 0,
					isEnabled = backdropEnabled,
				}

				settingsList[#settingsList + 1] = {
					parentId = "CheckboxGroup",
					name = L["Background inset"] or "Background inset",
					kind = settingType.Slider,
					allowInput = true,
					field = "backdropBackgroundInset",
					minValue = 0,
					maxValue = 128,
					valueStep = 1,
					get = function()
						local c = curSpecCfg()
						local bd = ensureBackdropTable(c)
						return bd and bd.backgroundInset or 0
					end,
					set = function(_, value)
						local c = curSpecCfg()
						if not c then return end
						local bd = ensureBackdropTable(c)
						bd.backgroundInset = max(0, value or 0)
						queueRefresh()
					end,
					default = (cfg and cfg.backdrop and cfg.backdrop.backgroundInset) or 0,
					isEnabled = backdropEnabled,
				}
			end
		end

		EditMode:RegisterFrame(frameId, {
			frame = frame,
			title = titleLabel,
			enableOverlayToggle = true,
			allowDrag = function() return anchorUsesUIParent() end,
			managePosition = false,
			persistPosition = false,
			layoutDefaults = {
				point = anchor and anchor.point or "CENTER",
				relativePoint = anchor and anchor.relativePoint or "CENTER",
				x = anchor and anchor.x or 0,
				y = anchor and anchor.y or 0,
				width = cfg and cfg.width or widthDefault or frame:GetWidth() or 200,
				height = cfg and cfg.height or heightDefault or frame:GetHeight() or 20,
			},
			onApply = function(_, _, data)
				data = data or {}
				local spec = registeredSpec or addon.variables.unitSpec
				local activeSpec = getActiveSpecIndex()
				if activeSpec and spec and spec ~= activeSpec then return end
				local bcfg = curSpecCfg()
				if not bcfg then return end
				bcfg.anchor = bcfg.anchor or {}
				local oldPoint = bcfg.anchor.point
				local oldRelativePoint = bcfg.anchor.relativePoint
				local oldX = bcfg.anchor.x
				local oldY = bcfg.anchor.y
				local oldRelativeFrame = bcfg.anchor.relativeFrame
				local oldWidth = bcfg.width
				local oldHeight = bcfg.height
				local hydrationToken = tostring(addon.db) .. ":" .. tostring(frameId)
				if frame._eqolEditModeHydratedToken ~= hydrationToken then
					frame._eqolEditModeHydratedToken = hydrationToken
					local seedAnchor = bcfg.anchor or {}
					local seedRelativeFrame = seedAnchor.relativeFrame or "UIParent"
					if seedRelativeFrame == "UIParent" then
						data.point = seedAnchor.point or data.point or anchor and anchor.point or "CENTER"
						data.relativePoint = seedAnchor.relativePoint or data.relativePoint or anchor and anchor.relativePoint or data.point
						data.x = seedAnchor.x ~= nil and seedAnchor.x or (data.x ~= nil and data.x or (anchor and anchor.x or 0))
						data.y = seedAnchor.y ~= nil and seedAnchor.y or (data.y ~= nil and data.y or (anchor and anchor.y or 0))
						syncEditModeLayoutFromAnchor()
					end
					data.width = bcfg.width or data.width or widthDefault or frame:GetWidth() or 200
					data.height = bcfg.height or data.height or heightDefault or frame:GetHeight() or 20
				end
				if data.point then
					local relFrame = bcfg.anchor.relativeFrame or "UIParent"
					-- Nur UIParent-Anker von Edit Mode übernehmen; externe Anker behalten ihre Werte
					if relFrame == "UIParent" then
						bcfg.anchor.point = data.point
						bcfg.anchor.relativePoint = data.relativePoint or data.point
						bcfg.anchor.x = data.x or 0
						bcfg.anchor.y = data.y or 0
					end
					bcfg.anchor.relativeFrame = relFrame
				end
				bcfg.width = data.width or bcfg.width
				bcfg.height = data.height or bcfg.height
				local anchorChanged = oldPoint ~= bcfg.anchor.point
					or oldRelativePoint ~= bcfg.anchor.relativePoint
					or oldRelativeFrame ~= bcfg.anchor.relativeFrame
					or oldX ~= bcfg.anchor.x
					or oldY ~= bcfg.anchor.y
				local sizeChanged = (oldWidth ~= nil or bcfg.width ~= nil) and math.abs((tonumber(oldWidth) or 0) - (tonumber(bcfg.width) or 0)) >= 0.5
					or (oldHeight ~= nil or bcfg.height ~= nil) and math.abs((tonumber(oldHeight) or 0) - (tonumber(bcfg.height) or 0)) >= 0.5
				local liveLayoutChanged = anchorChanged or sizeChanged
				local isBarEnabled = addon.db["enableResourceFrame"] == true and bcfg.enabled == true
				if spec == addon.variables.unitSpec then
					local liveBarType = currentLiveBarType()
					if liveLayoutChanged and isBarEnabled and liveBarType == "HEALTH" then
						ResourceBars.SetHealthBarSize(bcfg.width, bcfg.height)
					elseif liveLayoutChanged and isBarEnabled and liveBarType then
						ResourceBars.SetPowerBarSize(bcfg.width, bcfg.height, liveBarType)
					end
					if liveLayoutChanged and isBarEnabled then
						if ResourceBars.ReanchorAll then ResourceBars.ReanchorAll() end
						if ResourceBars.Refresh then ResourceBars.Refresh() end
						if sharedSlot and ResourceBars and ResourceBars.SyncSharedSlotProxyFrame then ResourceBars.SyncSharedSlotProxyFrame(sharedSlot, spec) end
						if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RefreshSettingValues then addon.EditModeLib.internal:RefreshSettingValues() end
					end
				end
			end,
			isEnabled = function()
				local c = curSpecCfg()
				return addon.db["enableResourceFrame"] == true and c and c.enabled == true
			end,
			settings = settingsList,
			buttons = buttons,
			showOutsideEditMode = true,
			collapseExclusive = true,
		})
		if addon.EditModeLib and addon.EditModeLib.SetFrameResetVisible then addon.EditModeLib:SetFrameResetVisible(frame, false) end
		registeredFrames[frameId] = true
		registered = registered + 1
	end

	local activeSpec = tonumber(getActiveSpecIndex()) or tonumber(addon.variables.unitSpec) or 0
	local sharedMode = getSpecMode(activeSpec) == "SHARED"
	local function clearUnusedRegistrations(allowed)
		for key, oldId in pairs(registeredByBar) do
			if not allowed[key] then
				if oldId and EditMode and EditMode.UnregisterFrame then EditMode:UnregisterFrame(oldId, false) end
				if oldId then registeredFrames[oldId] = nil end
				registeredByBar[key] = nil
				registeredFrameNameByBar[key] = nil
			end
		end
	end
	if sharedMode then
		local assignments = ResourceBars.ResolveSharedSlotAssignments and ResourceBars.ResolveSharedSlotAssignments(activeSpec) or {}
		if ResourceBars and ResourceBars.SyncSharedSlotProxyFrames then ResourceBars.SyncSharedSlotProxyFrames(activeSpec) end
		local allowed = { HEALTH = true, MAIN = true, SECONDARY = true }
		clearUnusedRegistrations(allowed)
		registerBar("HEALTH", "EQOLHealthBar", "HEALTH", ResourceBars.DEFAULT_HEALTH_WIDTH, ResourceBars.DEFAULT_HEALTH_HEIGHT, {
			sharedSlot = "HEALTH",
			titleLabel = HEALTH or "Health",
		})
		local sharedEntries = {
			{ slot = "MAIN", label = L["AutoEnableMain"] or "Main resource" },
			{ slot = "SECONDARY", label = L["AutoEnableSecondary"] or "Secondary" },
		}
		for _, entry in ipairs(sharedEntries) do
			local resolvedType = assignments and assignments[entry.slot]
			registerBar(
				entry.slot,
				ResourceBars.GetSharedSlotFrameName and ResourceBars.GetSharedSlotFrameName(entry.slot) or ("EQOLShared" .. entry.slot .. "Bar"),
				resolvedType or "MANA",
				ResourceBars.DEFAULT_POWER_WIDTH,
				ResourceBars.DEFAULT_POWER_HEIGHT,
				{
					sharedSlot = entry.slot,
					titleLabel = entry.label,
				}
			)
		end
	else
		local allowed = { HEALTH = true }
		local classTypes = (ResourceBars.GetClassPowerTypes and ResourceBars.GetClassPowerTypes(addon.variables.unitClass)) or ResourceBars.classPowerTypes or {}
		for _, pType in ipairs(classTypes) do
			allowed[pType] = true
		end
		clearUnusedRegistrations(allowed)
		registerBar("HEALTH", "EQOLHealthBar", "HEALTH", ResourceBars.DEFAULT_HEALTH_WIDTH, ResourceBars.DEFAULT_HEALTH_HEIGHT)
		for _, pType in ipairs(classTypes) do
			local frameName = "EQOL" .. pType .. "Bar"
			registerBar(pType, frameName, pType, ResourceBars.DEFAULT_POWER_WIDTH, ResourceBars.DEFAULT_POWER_HEIGHT)
		end
	end

	ResourceBars._editModeRegistered = registered > 0
end

ResourceBars.RegisterEditModeFrames = registerEditModeBars
ResourceBars.UnregisterEditModeFrames = unregisterEditModeBars

local function buildSpecToggles(specIndex, specName, available, expandable)
	local specCfg = ensureSpecCfg(specIndex)
	if not specCfg then return nil end

	local options = {}
	local added = {}

	-- Main resource from spec definition (e.g., LUNAR_POWER for Balance)
	local mainType = available.MAIN
	if mainType then
		specCfg[mainType] = specCfg[mainType] or {}
		local cfg = specCfg[mainType]
		options[#options + 1] = {
			value = mainType,
			text = (ResourceBars.PowerLabels and ResourceBars.PowerLabels[mainType]) or _G["POWER_TYPE_" .. mainType] or _G[mainType] or mainType,
			enabled = cfg.enabled == true,
		}
		added[mainType] = true
	end

	for _, pType in ipairs(ResourceBars.classPowerTypes or {}) do
		if available[pType] and not added[pType] then
			specCfg[pType] = specCfg[pType] or {}
			local cfg = specCfg[pType]
			local label = (ResourceBars.PowerLabels and ResourceBars.PowerLabels[pType]) or _G["POWER_TYPE_" .. pType] or _G[pType] or pType
			options[#options + 1] = {
				value = pType,
				text = label,
				enabled = cfg.enabled == true,
			}
			added[pType] = true
		end
	end

	-- Add health entry first
	local hCfg = specCfg.HEALTH or {}
	table.insert(options, 1, { value = "HEALTH", text = HEALTH, enabled = hCfg.enabled == true })

	if #options == 0 then return nil end

	local varKey = ("rb_spec_%s"):format(specIndex)
	specSettingVars[varKey] = true

	return {
		sType = "multidropdown",
		var = varKey,
		text = specName,
		options = options,
		isSelectedFunc = function(key)
			local class = addon.variables.unitClass
			if not class or not specIndex then return false end
			return addon.db.personalResourceBarSettings
					and addon.db.personalResourceBarSettings[class]
					and addon.db.personalResourceBarSettings[class][specIndex]
					and addon.db.personalResourceBarSettings[class][specIndex]
					and addon.db.personalResourceBarSettings[class][specIndex][key]
					and addon.db.personalResourceBarSettings[class][specIndex][key].enabled
				or false
		end,
		setSelectedFunc = function(key, shouldSelect)
			local specCfg = ensureSpecCfg(specIndex)
			if not specCfg then return end
			specCfg[key] = specCfg[key] or {}
			specCfg[key].enabled = shouldSelect and true or false
			setBarEnabled(specIndex, key, shouldSelect)
		end,
		parent = true,
		parentCheck = function() return addon.db["enableResourceFrame"] == true and getSpecMode(specIndex) ~= "SHARED" end,
		parentSection = expandable,
	}
end

local settingsBuilt = false
local function buildSettings()
	if settingsBuilt then return end
	local cat = addon.SettingsLayout.rootUI

	if not cat then return end

	local expandable = addon.SettingsLayout.uiBarsResourcesExpandable
	if not expandable then return end

	settingsBuilt = true

	addon.functions.SettingsCreateHeadline(cat, L["Resource Bars"], { parentSection = expandable })
	local specRows = {}

	local data = {
		{
			var = "enableResourceFrame",
			text = L["Resource Bars"],
			desc = L["Resource Bars"],
			get = function() return addon.db["enableResourceFrame"] end,
			func = function(val)
				addon.db["enableResourceFrame"] = val and true or false
				if val and ResourceBars.EnableResourceBars then
					ResourceBars.EnableResourceBars()
				elseif ResourceBars.DisableResourceBars then
					ResourceBars.DisableResourceBars()
				end
				notifyResourceBarSettings()
				refreshSettingsUI()
				if val then
					registerEditModeBars()
				elseif ResourceBars and ResourceBars.UnregisterEditModeFrames then
					ResourceBars.UnregisterEditModeFrames()
				end
			end,
			parentSection = expandable,
				default = false,
			},
		}

	local classID = addon.variables and addon.variables.unitClassID
	local classTag = addon.variables and addon.variables.unitClass
	if (not classID) or not classTag then
		local _, tag, id = UnitClass("player")
		if not classTag then classTag = tag end
		if not classID then classID = id end
	end
	classID = tonumber(classID)
	if classID and classID > 0 and classTag and ResourceBars.powertypeClasses and ResourceBars.powertypeClasses[classTag] then
		local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
		for specIndex = 1, (specCount or 0) do
			local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
			local available = ResourceBars.powertypeClasses[classTag][specIndex] or {}
			if specID and specName then
				specRows[#specRows + 1] = { index = specIndex, name = specName, available = available }
			end
		end
	end

	local function currentClassMode()
		local activeSpec = tonumber(getActiveSpecIndex()) or tonumber(addon.variables and addon.variables.unitSpec) or 0
		if activeSpec > 0 then return getSpecMode(activeSpec) end
		return "SPEC"
	end
	local resourceBarSettings = addon.functions.SettingsCreateCheckboxes(cat, data)
	local resourceBarsParent = resourceBarSettings and resourceBarSettings.enableResourceFrame and resourceBarSettings.enableResourceFrame.element or nil
	local function sharedModeParentCheck()
		return addon.db["enableResourceFrame"] == true and currentClassMode() == "SHARED"
	end
	local function specModeParentCheck()
		return addon.db["enableResourceFrame"] == true and currentClassMode() ~= "SHARED"
	end

	do
		local modeVar = "rb_mode_class"
		specModeSettingVars[modeVar] = true
		addon.functions.SettingsCreateDropdown(cat, {
			var = modeVar,
			text = _G.MODE or "Mode",
			values = RESOURCE_MODE_OPTIONS,
			order = RESOURCE_MODE_ORDER,
			get = function() return currentClassMode() end,
			set = function(value)
				local activeSpec = tonumber(getActiveSpecIndex()) or tonumber(addon.variables and addon.variables.unitSpec) or 0
				local previousMode = currentClassMode()
				if previousMode == value then return end
				if activeSpec <= 0 or not setSpecMode(activeSpec, value) then return end
				if value == "SHARED" and ResourceBars and ResourceBars.EnsureSharedSlotStore then
					for _, slot in ipairs(ResourceBars.SHARED_SLOT_ORDER or {}) do
						ResourceBars.EnsureSharedSlotStore(slot)
					end
				end
				notifyResourceBarSettings()
				refreshSettingsUI()
				addon.variables.requireReload = true
				if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
			end,
			default = "SHARED",
			parent = resourceBarsParent,
			parentSection = expandable,
			parentCheck = function() return addon.db["enableResourceFrame"] == true end,
		})
	end

	addon.functions.SettingsCreateText(cat, "", {
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = sharedModeParentCheck,
	})

	addon.functions.SettingsCreateText(cat, "|cff99e599" .. (L["ResourceBarsModeShared"] or "Shared") .. "|r", {
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = sharedModeParentCheck,
	})

	addon.functions.SettingsCreateMultiDropdown(cat, {
		var = "resourceBarsSharedEnabled",
		text = L["ResourceBarsModeShared"] or "Shared",
		options = AUTO_ENABLE_OPTIONS,
		order = AUTO_ENABLE_ORDER,
		isSelectedFunc = function(key)
			return isSharedSlotEnabled(key)
		end,
		setSelectedFunc = function(key, shouldSelect)
			setSharedSlotEnabled(key, shouldSelect)
		end,
		parent = resourceBarsParent,
		parentCheck = sharedModeParentCheck,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateButton(cat, {
		var = "resourceBarsSharedAllClasses",
		text = L["ResourceBarsEnableSharedAllClasses"] or "Enable Shared for all classes",
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = sharedModeParentCheck,
		func = function()
			local popupKey = "EQOL_RESOURCEBARS_ENABLE_SHARED_ALL_CLASSES"
			StaticPopupDialogs[popupKey] = StaticPopupDialogs[popupKey]
				or {
					text = L["ResourceBarsEnableSharedAllClassesConfirm"] or "Enable Shared mode for all specs of all classes?",
					button1 = OKAY,
					button2 = CANCEL,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
			StaticPopupDialogs[popupKey].OnAccept = function()
				for classKey, classSpecs in pairs((ResourceBars and ResourceBars.powertypeClasses) or {}) do
					if type(classSpecs) == "table" then setSpecModeForClass(classKey, next(classSpecs), "SHARED") end
				end
				if ResourceBars and ResourceBars.EnsureSharedSlotStore then
					for _, slot in ipairs(ResourceBars.SHARED_SLOT_ORDER or {}) do
						ResourceBars.EnsureSharedSlotStore(slot)
					end
				end
				if ReloadUI then
					ReloadUI()
					return
				end
				local activeSpec = getActiveSpecIndex()
				if activeSpec then addon.Aura.functions.requestActiveRefresh(activeSpec) end
				refreshSettingsUI()
				registerEditModeBars()
			end
			StaticPopup_Show(popupKey)
		end,
	})

	addon.functions.SettingsCreateMultiDropdown(cat, {
		var = "resourceBarsAutoEnable",
		text = L["AutoEnableAllBars"] or "Auto-enable bars for new characters",
		options = AUTO_ENABLE_OPTIONS,
		order = AUTO_ENABLE_ORDER,
		isSelectedFunc = function(key)
			local selection = autoEnableSelection()
			return selection and selection[key] == true
		end,
		setSelectedFunc = function(key, shouldSelect)
			local selection = autoEnableSelection()
			if shouldSelect then
				selection[key] = true
			else
				selection[key] = nil
			end
			local spec = addon.variables.unitSpec
			if spec then
				local cfg = ensureSpecCfg(spec)
				if cfg then addon.Aura.functions.requestActiveRefresh(spec) end
			end
		end,
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = specModeParentCheck,
	})

	addon.functions.SettingsCreateText(cat, "", {
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = specModeParentCheck,
	})

	addon.functions.SettingsCreateText(cat, "|cff99e599" .. (L["ResourceBarsModeSpec"] or "Classic") .. "|r", {
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = specModeParentCheck,
	})

	addon.functions.SettingsCreateText(cat, "|cff99e599" .. L["ResourceBarsSpecHint"] .. "|r", {
		parent = resourceBarsParent,
		parentSection = expandable,
		parentCheck = specModeParentCheck,
	})

	for _, row in ipairs(specRows) do
		local entry = buildSpecToggles(row.index, row.name, row.available or {}, expandable)
		if entry then
			entry.parent = resourceBarsParent
			addon.functions.SettingsCreateMultiDropdown(cat, entry)
		end
	end

	registerEditModeBars()
end

addon.Aura.functions = addon.Aura.functions or {}
addon.Aura.functions.AddResourceBarsSettings = buildSettings
addon.Aura.functions.AddResourceBarsProfileSettings = function()
	if addon.SettingsLayout.resourceBarsProfileBuilt then return end
	addon.SettingsLayout.resourceBarsProfileBuilt = true

	local classKey = addon.variables.unitClass or "UNKNOWN"
	local function ensureProfileScope()
		addon.db = addon.db or {}
		if type(addon.db.resourceBarsProfileScope) ~= "table" then addon.db.resourceBarsProfileScope = {} end
		return addon.db.resourceBarsProfileScope
	end
	local function getScope()
		local scope = ensureProfileScope()
		local cur = scope and scope[classKey]
		if not cur then cur = "ALL" end
		return cur
	end
	local function setScope(val)
		local scope = ensureProfileScope()
		if scope then scope[classKey] = val end
	end

	local scopeList = {
		ALL = L["All specs"] or "All specs",
		ALL_CLASSES = L["All classes"] or "All classes",
	}
	local scopeOrder = { "ALL" }
	local classID = addon.variables and addon.variables.unitClassID
	local classTag = addon.variables and addon.variables.unitClass
	if (not classID) or not classTag then
		local _, tag, id = UnitClass("player")
		if not classTag then classTag = tag end
		if not classID then classID = id end
	end
	classID = tonumber(classID)
	if
		classID
		and classID > 0
		and classTag
		and C_SpecializationInfo
		and C_SpecializationInfo.GetNumSpecializationsForClassID
		and ResourceBars.powertypeClasses
		and ResourceBars.powertypeClasses[classTag]
	then
		local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
		for specIndex = 1, (specCount or 0) do
			local _, specName = GetSpecializationInfoForClassID(classID, specIndex)
			if specName then
				scopeList[tostring(specIndex)] = specName
				scopeOrder[#scopeOrder + 1] = tostring(specIndex)
			end
		end
	end
	scopeOrder[#scopeOrder + 1] = "ALL_CLASSES"

	local cProfiles = addon.SettingsLayout.rootPROFILES

	local expandableProfile = addon.functions.SettingsCreateExpandableSection(cProfiles, {
		name = L["Resource Bars"],
		expanded = false,
		colorizeTitle = false,
	})

	addon.functions.SettingsCreateDropdown(cProfiles, {
		var = "resourceBarsProfileScope",
		text = L["ProfileScope"] or (L["Apply to"] or "Apply to"),
		list = scopeList,
		get = getScope,
		set = setScope,
		default = "ALL",
		parentSection = expandableProfile,
	})

	addon.functions.SettingsCreateButton(cProfiles, {
		var = "resourceBarsExport",
		text = L["Export"] or "Export",
		func = function()
			local code
			local reason
			local scopeKey = getScope() or "ALL"
			if ResourceBars and ResourceBars.ExportProfile then
				code, reason = ResourceBars.ExportProfile(scopeKey)
			end
			if not code then
				local msg = ResourceBars.ExportErrorMessage and ResourceBars.ExportErrorMessage(reason) or (L["ExportProfileFailed"] or "Export failed.")
				print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
				return
			end
			StaticPopupDialogs["EQOL_RESOURCEBAR_EXPORT_SETTINGS"] = StaticPopupDialogs["EQOL_RESOURCEBAR_EXPORT_SETTINGS"]
				or {
					text = L["ExportProfileTitle"] or "Export Resource Bars",
					button1 = CLOSE,
					hasEditBox = true,
					editBoxWidth = 320,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
			StaticPopupDialogs["EQOL_RESOURCEBAR_EXPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText(code)
				editBox:HighlightText()
				editBox:SetFocus()
			end
			StaticPopup_Show("EQOL_RESOURCEBAR_EXPORT_SETTINGS")
		end,
		parentSection = expandableProfile,
	})

	addon.functions.SettingsCreateButton(cProfiles, {
		var = "resourceBarsImport",
		text = L["Import"] or "Import",
		func = function()
			StaticPopupDialogs["EQOL_RESOURCEBAR_IMPORT_SETTINGS"] = StaticPopupDialogs["EQOL_RESOURCEBAR_IMPORT_SETTINGS"]
				or {
					text = L["ImportProfileTitle"] or "Import Resource Bars",
					button1 = OKAY,
					button2 = CANCEL,
					hasEditBox = true,
					editBoxWidth = 320,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
			StaticPopupDialogs["EQOL_RESOURCEBAR_IMPORT_SETTINGS"].OnShow = function(self)
				self:SetFrameStrata("TOOLTIP")
				local editBox = self.editBox or self:GetEditBox()
				editBox:SetText("")
				editBox:SetFocus()
			end
			StaticPopupDialogs["EQOL_RESOURCEBAR_IMPORT_SETTINGS"].EditBoxOnEnterPressed = function(editBox)
				local parent = editBox:GetParent()
				if parent and parent.button1 then parent.button1:Click() end
			end
			StaticPopupDialogs["EQOL_RESOURCEBAR_IMPORT_SETTINGS"].OnAccept = function(self)
				local editBox = self.editBox or self:GetEditBox()
				local input = editBox:GetText() or ""
				local scopeKey = getScope() or "ALL"
				local ok, applied, enableState, appliedMode = addon.Aura.functions.importResourceProfile(input, scopeKey)
				if not ok then
					local msg = ResourceBars.ImportErrorMessage and ResourceBars.ImportErrorMessage(applied, enableState) or (L["ImportProfileFailed"] or "Import failed.")
					print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
					return
				end
				local isAllClasses = appliedMode == "ALL_CLASSES"
				if enableState ~= nil and (scopeKey == "ALL" or scopeKey == "ALL_CLASSES" or isAllClasses) then
					local prev = addon.db["enableResourceFrame"]
					addon.db["enableResourceFrame"] = enableState and true or false
					if enableState and prev ~= true and addon.Aura.ResourceBars and addon.Aura.ResourceBars.EnableResourceBars then
						addon.Aura.ResourceBars.EnableResourceBars()
					elseif not enableState and prev ~= false and addon.Aura.ResourceBars and addon.Aura.ResourceBars.DisableResourceBars then
						addon.Aura.ResourceBars.DisableResourceBars()
					end
				end
				if applied then
					for _, specIndex in ipairs(applied) do
						addon.Aura.functions.requestActiveRefresh(specIndex)
					end
				end
				applyResourceBarsVisibility("import")
				notifyResourceBarSettings()
				if applied and #applied > 0 then
					local specNames = {}
					for _, specIndex in ipairs(applied) do
						specNames[#specNames + 1] = ResourceBars.SpecNameByIndex and ResourceBars.SpecNameByIndex(specIndex) or tostring(specIndex)
					end
					local msg = (L["ImportProfileSuccess"] or "Resource Bars updated for: %s"):format(table.concat(specNames, ", "))
					print("|cff00ff98Enhance QoL|r: " .. msg)
				else
					local msg = L["ImportProfileSuccessGeneric"] or "Resource Bars profile imported."
					print("|cff00ff98Enhance QoL|r: " .. msg)
				end
				Settings.NotifyUpdate("EQOL_" .. "enableResourceFrame")
				if (scopeKey == "ALL_CLASSES" or isAllClasses) and ReloadUI then ReloadUI() end
			end
			StaticPopup_Show("EQOL_RESOURCEBAR_IMPORT_SETTINGS")
		end,
		parentSection = expandableProfile,
	})
end
