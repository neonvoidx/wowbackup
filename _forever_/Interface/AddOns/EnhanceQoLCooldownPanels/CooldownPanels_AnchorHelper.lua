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

CooldownPanels.AnchorHelper = CooldownPanels.AnchorHelper or {}
local AnchorHelper = CooldownPanels.AnchorHelper

local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

AnchorHelper.providers = AnchorHelper.providers or {}
AnchorHelper.runtime = AnchorHelper.runtime or {}

local function providerAddonMatches(provider, addonName)
	if not provider then return false end
	if provider.addonName == addonName then return true end
	if provider.addonNames then
		for _, name in ipairs(provider.addonNames) do
			if name == addonName then return true end
		end
	end
	return false
end

local function providerAddonLoaded(provider)
	if not provider or not IsAddOnLoaded then return true end
	if provider.addonName and not IsAddOnLoaded(provider.addonName) then return false end
	if provider.addonNames then
		for _, name in ipairs(provider.addonNames) do
			if IsAddOnLoaded(name) then return true end
		end
		return false
	end
	return true
end

local function isProviderLoaded(provider)
	if not provider then return false end
	if not providerAddonLoaded(provider) then return false end
	if provider.isLoaded and provider.isLoaded() == false then return false end
	return true
end

local function providerHasAnchor(provider, value)
	if type(value) ~= "string" or value == "" then return false end
	if provider.isAnchorKey and provider.isAnchorKey(value) then return true end
	if provider.anchorLabelByKey and provider.anchorLabelByKey[value] then return true end
	if provider.anchors then
		for _, entry in ipairs(provider.anchors) do
			if entry.key == value then return true end
		end
	end
	return false
end

local function getRoot()
	if CooldownPanels and CooldownPanels.GetRoot then return CooldownPanels:GetRoot() end
	return nil
end

local function getProvidersInUse()
	local root = getRoot()
	if not root or not root.panels then return nil end
	local used = {}
	for _, panel in pairs(root.panels) do
		local anchor = panel.anchor
		local key = anchor and anchor.relativeFrame
		if key then
			for _, provider in pairs(AnchorHelper.providers) do
				if providerHasAnchor(provider, key) then
					used[provider.key] = provider
					break
				end
			end
		end
	end
	local list = {}
	for _, provider in pairs(used) do
		list[#list + 1] = provider
	end
	if #list == 0 then return nil end
	return list
end

local function providersReady(providers)
	for _, provider in ipairs(providers) do
		if not isProviderLoaded(provider) then return false end
		if provider.framesAvailable and not provider.framesAvailable() then return false end
	end
	return true
end

local function reapplyAnchors(providers)
	local root = getRoot()
	if not root or not root.panels then return end
	if not (CooldownPanels and CooldownPanels.ApplyPanelPosition) then return end
	for panelId, panel in pairs(root.panels) do
		local anchor = panel.anchor
		local key = anchor and anchor.relativeFrame
		if key then
			for _, provider in ipairs(providers) do
				if providerHasAnchor(provider, key) then
					CooldownPanels:ApplyPanelPosition(panelId)
					break
				end
			end
		end
	end
end

function AnchorHelper:RegisterProvider(key, provider)
	if type(key) ~= "string" or key == "" then return end
	if type(provider) ~= "table" then return end
	provider.key = key
	provider.anchorLabelByKey = provider.anchorLabelByKey or {}
	if provider.anchors then
		for _, entry in ipairs(provider.anchors) do
			if entry.key and provider.anchorLabelByKey[entry.key] == nil then provider.anchorLabelByKey[entry.key] = entry.label end
		end
	end
	if provider.anchorLabels then
		for anchorKey, label in pairs(provider.anchorLabels) do
			if provider.anchorLabelByKey[anchorKey] == nil then provider.anchorLabelByKey[anchorKey] = label end
		end
	end
	AnchorHelper.providers[key] = provider
end

function AnchorHelper:IsExternalAnchorKey(value)
	for _, provider in pairs(self.providers) do
		if providerHasAnchor(provider, value) then return true end
	end
	return false
end

function AnchorHelper:GetAnchorLabel(value)
	for _, provider in pairs(self.providers) do
		if provider.anchorLabelByKey and provider.anchorLabelByKey[value] then return provider.anchorLabelByKey[value] end
	end
	return nil
end

function AnchorHelper:CollectAnchorEntries(entries, seen)
	if type(entries) ~= "table" then return end
	if type(seen) ~= "table" then seen = {} end
	for _, provider in pairs(self.providers) do
		if isProviderLoaded(provider) and provider.anchors then
			for _, entry in ipairs(provider.anchors) do
				local key = entry.key
				if key and not seen[key] then
					entries[#entries + 1] = { key = key, label = entry.label or (provider.anchorLabelByKey and provider.anchorLabelByKey[key]) or key, menuGroup = entry.menuGroup }
					seen[key] = true
				end
			end
		end
	end
end

function AnchorHelper:ResolveExternalFrame(relativeName)
	if type(relativeName) ~= "string" or relativeName == "" then return nil end
	for _, provider in pairs(self.providers) do
		if isProviderLoaded(provider) and providerHasAnchor(provider, relativeName) then
			if provider.resolveFrame then
				local frame = provider.resolveFrame(relativeName)
				if frame then return frame end
			end
			if provider.anchorFrames and provider.anchorFrames[relativeName] then
				local frame = _G[provider.anchorFrames[relativeName]]
				if frame then return frame end
			end
			local frame = _G[relativeName]
			if frame then return frame end
		end
	end
	return nil
end

-- Resource anchors use stable shared-slot identities across specialization changes.
function AnchorHelper:IsResourceBarAnchorKey(name)
	if name == "EQOLSharedHealthBar" or name == "EQOLSharedMainBar" or name == "EQOLSharedSecondaryBar" or name == "EQOLSharedTertiaryBar" or name == "EQOLHealthBar" then return true end
	local bars = addon.Aura and addon.Aura.ResourceBars
	for _, powerType in ipairs(bars and bars.classPowerTypes or {}) do
		if name == "EQOL" .. powerType .. "Bar" then return true end
	end
	return false
end

function AnchorHelper:GetResourceBarAnchorEntries()
	if not (addon.functions and addon.functions.IsResourceBarsAddonLoaded and addon.functions.IsResourceBarsAddonLoaded()) then return {} end
	local bars = addon.Aura and addon.Aura.ResourceBars
	if not bars then return {} end
	local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
	local variables = addon.variables or {}
	local shared = bars.SpecUsesSharedMode and bars.SpecUsesSharedMode(variables.unitSpec)
	local root = shared and addon.db and addon.db.sharedResourceBarSettings
		or (addon.db and addon.db.personalResourceBarSettings and addon.db.personalResourceBarSettings[variables.unitClass] and addon.db.personalResourceBarSettings[variables.unitClass][variables.unitSpec])
	local entries = {}
	local slots = shared and { "HEALTH", "MAIN", "SECONDARY", "TERTIARY" } or { "HEALTH" }
	if not shared then
		for _, powerType in ipairs(bars.GetClassPowerTypes and bars.GetClassPowerTypes() or {}) do
			if powerType ~= "HEALTH" then slots[#slots + 1] = powerType end
		end
	end
	for _, token in ipairs(slots) do
		local frameName = shared and bars.GetSharedSlotFrameName and bars.GetSharedSlotFrameName(token) or (token == "HEALTH" and "EQOLHealthBar" or "EQOL" .. token .. "Bar")
		local frame = shared and bars.GetSharedSlotLiveFrame and bars.GetSharedSlotLiveFrame(token)
			or (token == "HEALTH" and _G.EQOLHealthBar or (not shared and bars.GetPowerBar and bars.GetPowerBar(token)))
		local label = shared and L["ResourceBars" .. token:sub(1, 1) .. token:sub(2):lower()]
			or (bars.PowerLabels and bars.PowerLabels[token]) or _G[token] or token
		local cfg = root and root[token]
		local powerType = shared and bars.GetResolvedBarTypeForSharedSlot and bars.GetResolvedBarTypeForSharedSlot(token) or token
		local alias = powerType and (powerType == "HEALTH" and "EQOLHealthBar" or "EQOL" .. powerType .. "Bar")
		entries[#entries + 1] = { key = frameName, label = label, groupLabel = L["Resource Bars"], frame = frame, alias = alias,
			anchor = cfg and cfg.anchor, dynamicId = shared and bars.GetSharedSlotDynamicAnchorId and bars.GetSharedSlotDynamicAnchorId(token) or nil }
	end
	return entries
end

function AnchorHelper:GetResourceBarAnchorCacheToken()
	local parts = {}
	for _, entry in ipairs(self:GetResourceBarAnchorEntries()) do
		local assignment = entry.dynamicId and addon.DynamicAnchors and addon.DynamicAnchors.GetFrameAssignment and addon.DynamicAnchors:GetFrameAssignment(entry.dynamicId, false)
		parts[#parts + 1] = entry.key .. ":" .. tostring(entry.frame) .. ":" .. tostring(entry.anchor and entry.anchor.relativeFrame) .. ":" .. tostring(assignment and assignment.enabled) .. ":" .. tostring(assignment and assignment.profileId)
		local profile = assignment and assignment.profileId and addon.DynamicAnchors.GetProfile and addon.DynamicAnchors:GetProfile(assignment.profileId)
		for _, candidate in ipairs(profile and profile.candidates or {}) do parts[#parts + 1] = tostring(candidate.targetId) end
	end
	return table.concat(parts, "|")
end

function AnchorHelper:ResolveResourceBarAnchorFrame(name)
	for _, entry in ipairs(self:GetResourceBarAnchorEntries()) do if entry.key == name or entry.alias == name then return entry.frame end end
	return nil
end

function AnchorHelper:GetResourceBarAnchorParents(name, panelKey)
	for _, entry in ipairs(self:GetResourceBarAnchorEntries()) do
		if entry.key == name or entry.alias == name then
			local dynamic = addon.DynamicAnchors
			if entry.dynamicId and dynamic and dynamic.IsFrameAssignmentEnabled and dynamic:IsFrameAssignmentEnabled(entry.dynamicId) then
				if dynamic.WouldCreateCycle and dynamic:WouldCreateCycle("cooldownPanel:" .. tostring(panelKey), entry.dynamicId) then return { "EQOL_CooldownPanel" .. tostring(panelKey) } end
				return {}
			end
			return { entry.anchor and entry.anchor.relativeFrame or "UIParent" }
		end
	end
	return nil
end

function AnchorHelper:MaybeScheduleRefresh(anchorKey)
	if self:IsExternalAnchorKey(anchorKey) then self:ScheduleRefresh() end
end

function AnchorHelper:ScheduleRefresh()
	local providers = getProvidersInUse()
	if not providers then return end
	local active = {}
	for _, provider in ipairs(providers) do
		if isProviderLoaded(provider) then active[#active + 1] = provider end
	end
	if #active == 0 then return end
	if providersReady(active) then
		reapplyAnchors(active)
		if CooldownPanels and CooldownPanels.RefreshAllPanels then CooldownPanels:RefreshAllPanels() end
		return
	end
	if not (C_Timer and C_Timer.NewTicker) then return end
	if self.runtime.refreshTicker then return end
	local tries = 0
	self.runtime.refreshTicker = C_Timer.NewTicker(0.2, function()
		tries = tries + 1
		if providersReady(active) then
			self.runtime.refreshTicker:Cancel()
			self.runtime.refreshTicker = nil
			reapplyAnchors(active)
			if CooldownPanels and CooldownPanels.RefreshAllPanels then CooldownPanels:RefreshAllPanels() end
		elseif tries >= 25 then
			self.runtime.refreshTicker:Cancel()
			self.runtime.refreshTicker = nil
		end
	end)
end

function AnchorHelper:HandleAddonLoaded(addonName)
	if type(addonName) ~= "string" or addonName == "" then return end
	for _, provider in pairs(self.providers) do
		if providerAddonMatches(provider, addonName) then
			self:ScheduleRefresh()
			return
		end
	end
end

function AnchorHelper:HandlePlayerLogin() self:ScheduleRefresh() end

-- Target nameplates are transient; keep the saved anchor key independent of pooled frames.
AnchorHelper.TARGET_NAMEPLATE = "EQOL_ANCHOR_TARGET_NAMEPLATE"

function AnchorHelper:GetTargetNameplateFrame()
	local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit("target")
	if not plate or plate == self.removedTargetPlate then return nil end
	if plate.IsForbidden and plate:IsForbidden() then return nil end
	if not plate:IsShown() then return nil end
	return plate
end

function AnchorHelper:TrackTargetNameplatePanel(panelId, enabled)
	if not enabled and not self.targetNameplatePanels then return end
	self.targetNameplatePanels = self.targetNameplatePanels or {}
	self.targetNameplatePanels[panelId] = enabled and true or nil
	if not next(self.targetNameplatePanels) then
		if self.targetNameplateWatcher then self.targetNameplateWatcher:UnregisterAllEvents() end
		self.targetNameplateWatching = nil
		self.removedTargetPlate = nil
		return
	end
	if self.targetNameplateWatching then return end
	if not self.targetNameplateWatcher then
		self.targetNameplateWatcher = CreateFrame("Frame")
		self.targetNameplateWatcher:SetScript("OnEvent", function(_, event, unit)
			if event == "NAME_PLATE_UNIT_REMOVED" then
				local removed = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
				if removed and removed == self.targetNameplateFrame then self.removedTargetPlate = removed end
			else
				self.removedTargetPlate = nil
			end
			local plate = self:GetTargetNameplateFrame()
			if plate == self.targetNameplateFrame and (event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED") then return end
			self.targetNameplateFrame = plate
			for id in pairs(self.targetNameplatePanels) do
				if CooldownPanels:GetPanel(id) then
					CooldownPanels:ApplyPanelPosition(id)
					CooldownPanels:UpdateVisibility(id)
				else
					self:TrackTargetNameplatePanel(id, false)
				end
			end
		end)
	end
	for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }) do
		self.targetNameplateWatcher:RegisterEvent(event)
	end
	self.targetNameplateWatching = true
	self.targetNameplateFrame = self:GetTargetNameplateFrame()
end

function AnchorHelper:ApplyTargetNameplateAnchor(panelId, runtime, anchor, dynamicWinner)
	local selected = not dynamicWinner and anchor and anchor.relativeFrame == self.TARGET_NAMEPLATE
	self:TrackTargetNameplatePanel(panelId, selected)
	runtime.targetNameplateMissing = nil
	if not selected then return nil end
	if CooldownPanels:IsPanelLayoutEditActive(panelId) then return UIParent end
	local plate = self:GetTargetNameplateFrame()
	runtime.targetNameplateMissing = not plate
	return plate or UIParent
end

AnchorHelper:RegisterProvider("targetNameplate", {
	anchors = { { key = AnchorHelper.TARGET_NAMEPLATE, menuGroup = "nameplates", label = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")["Target Nameplate"] } },
})

AnchorHelper:RegisterProvider("msuf", {
	addonName = "MidnightSimpleUnitFrames",
	anchors = {
		{ key = "MSUF_player", label = "MSUF: Player Frame" },
		{ key = "MSUF_target", label = "MSUF: Target Frame" },
		{ key = "MSUF_targettarget", label = "MSUF: Target of Target" },
		{ key = "MSUF_focus", label = "MSUF: Focus Frame" },
		{ key = "MSUF_pet", label = "MSUF: Pet Frame" },
		{ key = "MSUF_boss1", label = "MSUF: Boss Frame 1" },
		{ key = "MSUF_boss2", label = "MSUF: Boss Frame 2" },
		{ key = "MSUF_boss3", label = "MSUF: Boss Frame 3" },
		{ key = "MSUF_boss4", label = "MSUF: Boss Frame 4" },
		{ key = "MSUF_boss5", label = "MSUF: Boss Frame 5" },
	},
	framesAvailable = function()
		local frames = _G and _G.MSUF_UnitFrames
		if frames and (frames.player or frames.target or frames.targettarget or frames.focus or frames.pet or frames.boss1) then return true end
		return _G and (_G.MSUF_player or _G.MSUF_target or _G.MSUF_targettarget or _G.MSUF_focus or _G.MSUF_pet or _G.MSUF_boss1) and true or false
	end,
	resolveFrame = function(relativeName) return _G[relativeName] end,
})

AnchorHelper:RegisterProvider("uuf", {
	addonName = "UnhaltedUnitFrames",
	anchors = {
		{ key = "UUF_Player", label = "UUF: Player Frame" },
		{ key = "UUF_Target", label = "UUF: Target Frame" },
		{ key = "UUF_TargetTarget", label = "UUF: Target of Target" },
		{ key = "UUF_Focus", label = "UUF: Focus Frame" },
		{ key = "UUF_FocusTarget", label = "UUF: Focus Target" },
		{ key = "UUF_Pet", label = "UUF: Pet Frame" },
		{ key = "UUF_Boss1", label = "UUF: Boss Frame 1" },
		{ key = "UUF_Boss2", label = "UUF: Boss Frame 2" },
		{ key = "UUF_Boss3", label = "UUF: Boss Frame 3" },
		{ key = "UUF_Boss4", label = "UUF: Boss Frame 4" },
		{ key = "UUF_Boss5", label = "UUF: Boss Frame 5" },
		{ key = "UUF_Boss6", label = "UUF: Boss Frame 6" },
		{ key = "UUF_Boss7", label = "UUF: Boss Frame 7" },
		{ key = "UUF_Boss8", label = "UUF: Boss Frame 8" },
		{ key = "UUF_Boss9", label = "UUF: Boss Frame 9" },
		{ key = "UUF_Boss10", label = "UUF: Boss Frame 10" },
	},
	framesAvailable = function()
		local g = _G
		if not g then return false end
		if g.UUF_Player or g.UUF_Target or g.UUF_TargetTarget or g.UUF_Focus or g.UUF_FocusTarget or g.UUF_Pet then return true end
		return g.UUF_Boss1 and true or false
	end,
	resolveFrame = function(relativeName) return _G[relativeName] end,
})

AnchorHelper:RegisterProvider("elvui", {
	addonName = "ElvUI",
	anchors = {
		{ key = "ElvUF_Player", label = "ElvUI: Player Frame" },
		{ key = "ElvUF_Target", label = "ElvUI: Target Frame" },
		{ key = "ElvUF_TargetTarget", label = "ElvUI: Target of Target" },
		{ key = "ElvUF_Focus", label = "ElvUI: Focus Frame" },
		{ key = "ElvUF_FocusTarget", label = "ElvUI: Focus Target" },
		{ key = "ElvUF_Pet", label = "ElvUI: Pet Frame" },
		{ key = "ElvUF_Boss1", label = "ElvUI: Boss Frame 1" },
		{ key = "ElvUF_Boss2", label = "ElvUI: Boss Frame 2" },
		{ key = "ElvUF_Boss3", label = "ElvUI: Boss Frame 3" },
		{ key = "ElvUF_Boss4", label = "ElvUI: Boss Frame 4" },
		{ key = "ElvUF_Boss5", label = "ElvUI: Boss Frame 5" },
		{ key = "ElvUF_Arena1", label = "ElvUI: Arena Frame 1" },
		{ key = "ElvUF_Arena2", label = "ElvUI: Arena Frame 2" },
		{ key = "ElvUF_Arena3", label = "ElvUI: Arena Frame 3" },
		{ key = "ElvUF_Arena4", label = "ElvUI: Arena Frame 4" },
		{ key = "ElvUF_Arena5", label = "ElvUI: Arena Frame 5" },
	},
	framesAvailable = function()
		local g = _G
		if not g then return false end
		if g.ElvUF_Player or g.ElvUF_Target or g.ElvUF_TargetTarget or g.ElvUF_Focus or g.ElvUF_FocusTarget or g.ElvUF_Pet then return true end
		if g.ElvUF_Boss1 or g.ElvUF_Arena1 then return true end
		return false
	end,
	resolveFrame = function(relativeName) return _G[relativeName] end,
})

AnchorHelper:RegisterProvider("ellesmereui", {
	addonNames = { "EllesmereUI", "EllesmereUIUnitFrames", "EllesmereUICooldownManager" },
	anchors = {
		{ key = "EllesmereUIUnitFrames_Player", label = "EllesmereUI: Player Frame" },
		{ key = "EllesmereUIUnitFrames_Target", label = "EllesmereUI: Target Frame" },
		{ key = "EllesmereUIUnitFrames_TargetTarget", label = "EllesmereUI: Target of Target" },
		{ key = "EllesmereUIUnitFrames_Focus", label = "EllesmereUI: Focus Frame" },
		{ key = "EllesmereUIUnitFrames_FocusTarget", label = "EllesmereUI: Focus Target" },
		{ key = "EllesmereUIUnitFrames_Pet", label = "EllesmereUI: Pet Frame" },
		{ key = "EllesmereUIUnitFrames_Boss1", label = "EllesmereUI: Boss Frame 1" },
		{ key = "EllesmereUIUnitFrames_Boss2", label = "EllesmereUI: Boss Frame 2" },
		{ key = "EllesmereUIUnitFrames_Boss3", label = "EllesmereUI: Boss Frame 3" },
		{ key = "EllesmereUIUnitFrames_Boss4", label = "EllesmereUI: Boss Frame 4" },
		{ key = "EllesmereUIUnitFrames_Boss5", label = "EllesmereUI: Boss Frame 5" },
		{ key = "ECME_CDMBar_cooldowns", label = "EllesmereUI: Cooldowns" },
		{ key = "ECME_CDMBar_utility", label = "EllesmereUI: Utility" },
		{ key = "ECME_CDMBar_buffs", label = "EllesmereUI: Buffs" },
		{ key = "ECME_CDMBar_focuskick", label = "EllesmereUI: Focus Kick" },
		{ key = "ECME_CDMBar_ghost_cd", label = "EllesmereUI: Ghost Cooldowns" },
	},
	framesAvailable = function()
		local g = _G
		if not g then return false end
		if g.EllesmereUIUnitFrames_Player or g.EllesmereUIUnitFrames_Target or g.EllesmereUIUnitFrames_TargetTarget or g.EllesmereUIUnitFrames_Focus or g.EllesmereUIUnitFrames_FocusTarget or g.EllesmereUIUnitFrames_Pet then return true end
		if g.EllesmereUIUnitFrames_Boss1 or g.ECME_CDMBar_cooldowns or g.ECME_CDMBar_utility or g.ECME_CDMBar_buffs or g.ECME_CDMBar_focuskick or g.ECME_CDMBar_ghost_cd then return true end
		return g._ECME_GetBarFrame and (g._ECME_GetBarFrame("cooldowns") or g._ECME_GetBarFrame("utility") or g._ECME_GetBarFrame("buffs") or g._ECME_GetBarFrame("focuskick") or g._ECME_GetBarFrame("ghost_cd")) and true or false
	end,
	resolveFrame = function(relativeName)
		local g = _G
		if not g then return nil end
		local frame = g[relativeName]
		if frame then return frame end
		local barKey = relativeName:match("^ECME_CDMBar_(.+)$")
		if barKey and g._ECME_GetBarFrame then return g._ECME_GetBarFrame(barKey) end
		return nil
	end,
})

AnchorHelper:RegisterProvider("dragonrider", {
	addonName = "DragonRider",
	anchors = {
		{ key = "DragonRider_Vigor", label = "DragonRider: Vigor Bar" },
		{ key = "DragonRider_Speedometer", label = "DragonRider: Speedometer" },
	},
	framesAvailable = function()
		local g = _G
		if not g then return false end
		return (g.DragonRider_Vigor or g.DragonRider_Speedometer) and true or false
	end,
	resolveFrame = function(relativeName) return _G[relativeName] end,
})
