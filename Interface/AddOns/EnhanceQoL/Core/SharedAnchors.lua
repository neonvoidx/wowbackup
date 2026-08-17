local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.SharedAnchors = addon.SharedAnchors or {}
local SharedAnchors = addon.SharedAnchors

local UIParent = _G.UIParent
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local COOLDOWN_VIEWER_LABELS = {
	EssentialCooldownViewer = L["cooldownViewerEssential"] or "Essential Cooldown Viewer",
	UtilityCooldownViewer = L["cooldownViewerUtility"] or "Utility Cooldown Viewer",
	BuffBarCooldownViewer = L["cooldownViewerBuffBar"] or "Buff Bar Cooldowns",
	BuffIconCooldownViewer = L["cooldownViewerBuffIcon"] or "Buff Icon Cooldowns",
}
local ACTION_BAR_ANCHORS = {
	{ key = "MainMenuBar", label = _G.BINDING_HEADER_ACTIONBAR or "Action Bar 1" },
	{ key = "MainActionBar", label = _G.BINDING_HEADER_ACTIONBAR or "Action Bar 1" },
	{ key = "MultiBarBottomLeft", label = _G.BINDING_HEADER_ACTIONBAR2 or "Action Bar 2" },
	{ key = "MultiBarBottomRight", label = _G.BINDING_HEADER_ACTIONBAR3 or "Action Bar 3" },
	{ key = "MultiBarRight", label = _G.BINDING_HEADER_ACTIONBAR4 or "Action Bar 4" },
	{ key = "MultiBarLeft", label = _G.BINDING_HEADER_ACTIONBAR5 or "Action Bar 5" },
	{ key = "MultiBar5", label = _G.BINDING_HEADER_ACTIONBAR6 or "Action Bar 6" },
	{ key = "MultiBar6", label = _G.BINDING_HEADER_ACTIONBAR7 or "Action Bar 7" },
	{ key = "MultiBar7", label = _G.BINDING_HEADER_ACTIONBAR8 or "Action Bar 8" },
	{ key = "MultiBar8", label = _G.BINDING_HEADER_ACTIONBAR8 and (_G.BINDING_HEADER_ACTIONBAR8 .. " 2") or "Action Bar 9" },
	{ key = "PetActionBar", label = _G.TUTORIAL_TITLE61_HUNTER or _G.PET or "Pet Action Bar" },
	{ key = "StanceBar", label = _G.HUD_EDIT_MODE_STANCE_BAR_LABEL or "Stance Bar" },
}
local GENERIC_ANCHORS = {
	EQOL_ANCHOR_PLAYER = {
		labelKey = "UFPlayerFrame",
		fallback = _G.HUD_EDIT_MODE_PLAYER_FRAME_LABEL or "Player Frame",
		blizz = "PlayerFrame",
		uf = "EQOLUFPlayerFrame",
		ufKey = "player",
	},
	EQOL_ANCHOR_TARGET = {
		labelKey = "UFTargetFrame",
		fallback = _G.HUD_EDIT_MODE_TARGET_FRAME_LABEL or "Target Frame",
		blizz = "TargetFrame",
		uf = "EQOLUFTargetFrame",
		ufKey = "target",
	},
	EQOL_ANCHOR_TARGETTARGET = {
		labelKey = "UFToTFrame",
		fallback = "Target of Target",
		blizz = "TargetFrameToT",
		uf = "EQOLUFToTFrame",
		ufKey = "targettarget",
	},
	EQOL_ANCHOR_FOCUS = {
		labelKey = "UFFocusFrame",
		fallback = _G.HUD_EDIT_MODE_FOCUS_FRAME_LABEL or "Focus Frame",
		blizz = "FocusFrame",
		uf = "EQOLUFFocusFrame",
		ufKey = "focus",
	},
	EQOL_ANCHOR_PET = {
		labelKey = "UFPetFrame",
		fallback = _G.HUD_EDIT_MODE_PET_FRAME_LABEL or "Pet Frame",
		blizz = "PetFrame",
		uf = "EQOLUFPetFrame",
		ufKey = "pet",
	},
	EQOL_ANCHOR_PARTY = {
		label = _G.PARTY or "Party",
		blizz = "CompactPartyFrame",
		uf = "EQOLUFPartyAnchor",
		ufKey = "party",
	},
	EQOL_ANCHOR_RAID = {
		label = _G.RAID or "Raid",
		blizz = "CompactRaidFrameContainer",
		uf = "EQOLUFRaidAnchor",
		ufKey = "raid",
	},
	EQOL_ANCHOR_BOSS = {
		labelKey = "UFBossFrame",
		fallback = _G.HUD_EDIT_MODE_BOSS_FRAMES_LABEL or "Boss Frame",
		blizz = "BossTargetFrameContainer",
		uf = "EQOLUFBossContainer",
		ufKey = "boss",
	},
}
local GENERIC_ANCHOR_ORDER = {
	"EQOL_ANCHOR_PLAYER",
	"EQOL_ANCHOR_TARGET",
	"EQOL_ANCHOR_TARGETTARGET",
	"EQOL_ANCHOR_FOCUS",
	"EQOL_ANCHOR_PET",
	"EQOL_ANCHOR_PARTY",
	"EQOL_ANCHOR_RAID",
	"EQOL_ANCHOR_BOSS",
}
local GENERIC_ANCHOR_BY_FRAME = {
	PlayerFrame = "EQOL_ANCHOR_PLAYER",
	EQOLUFPlayerFrame = "EQOL_ANCHOR_PLAYER",
	TargetFrame = "EQOL_ANCHOR_TARGET",
	EQOLUFTargetFrame = "EQOL_ANCHOR_TARGET",
	TargetFrameToT = "EQOL_ANCHOR_TARGETTARGET",
	EQOLUFToTFrame = "EQOL_ANCHOR_TARGETTARGET",
	FocusFrame = "EQOL_ANCHOR_FOCUS",
	EQOLUFFocusFrame = "EQOL_ANCHOR_FOCUS",
	PetFrame = "EQOL_ANCHOR_PET",
	EQOLUFPetFrame = "EQOL_ANCHOR_PET",
	CompactPartyFrame = "EQOL_ANCHOR_PARTY",
	EQOLUFPartyAnchor = "EQOL_ANCHOR_PARTY",
	CompactRaidFrameContainer = "EQOL_ANCHOR_RAID",
	EQOLUFRaidAnchor = "EQOL_ANCHOR_RAID",
	BossTargetFrameContainer = "EQOL_ANCHOR_BOSS",
	EQOLUFBossContainer = "EQOL_ANCHOR_BOSS",
}

local RAW_ANCHOR_POINTS = {
	"TOPLEFT",
	"TOP",
	"TOPRIGHT",
	"LEFT",
	"CENTER",
	"RIGHT",
	"BOTTOMLEFT",
	"BOTTOM",
	"BOTTOMRIGHT",
}

SharedAnchors.AnchorPointOptions = SharedAnchors.AnchorPointOptions or {}
SharedAnchors.AnchorPointSet = SharedAnchors.AnchorPointSet or {}

if #SharedAnchors.AnchorPointOptions == 0 then
	for i = 1, #RAW_ANCHOR_POINTS do
		local value = RAW_ANCHOR_POINTS[i]
		SharedAnchors.AnchorPointOptions[#SharedAnchors.AnchorPointOptions + 1] = {
			value = value,
			label = value,
		}
		SharedAnchors.AnchorPointSet[value] = true
	end
end

local function getCooldownPanels()
	local aura = addon and addon.Aura
	return aura and aura.CooldownPanels or nil
end

local function getCooldownPanelHelper()
	local cooldownPanels = getCooldownPanels()
	return cooldownPanels and cooldownPanels.helper or nil
end

local function frameNameToPanelId(frameName)
	if type(frameName) ~= "string" then return nil end
	local id = frameName:match("^EQOL_CooldownPanel(%d+)$")
	return id and tonumber(id) or nil
end

local function addEntry(entries, valid, seen, key, label)
	if type(key) ~= "string" or key == "" or seen[key] then return end
	seen[key] = true
	valid[key] = true
	entries[#entries + 1] = {
		key = key,
		label = label or key,
	}
end

local function getLocaleValue(key, fallback)
	if type(key) ~= "string" or key == "" then return fallback end
	local value = L and L[key]
	if type(value) == "string" and value ~= "" and value ~= key then return value end
	return fallback
end

local function getGenericAnchorLabel(key)
	local info = GENERIC_ANCHORS[key]
	if not info then return nil end
	return info.label or getLocaleValue(info.labelKey, info.fallback or key)
end

local function collectActionBarEntries()
	local entries = {}
	local seen = {}

	local function add(key, label)
		if type(key) ~= "string" or key == "" or seen[key] then return end
		if not (_G and _G[key]) then return end
		seen[key] = true
		entries[#entries + 1] = {
			key = key,
			label = label or key,
		}
	end

	local configured = addon.variables and addon.variables.actionBarNames
	if type(configured) == "table" then
		for i = 1, #configured do
			local info = configured[i]
			if info then add(info.name, info.text) end
		end
	end

	for i = 1, #ACTION_BAR_ANCHORS do
		local entry = ACTION_BAR_ANCHORS[i]
		add(entry.key, entry.label)
	end

	return entries
end

function SharedAnchors:NormalizePoint(value, fallback)
	local helper = getCooldownPanelHelper()
	if helper and helper.NormalizeAnchor then return helper.NormalizeAnchor(value, fallback or "CENTER") end

	local point = type(value) == "string" and string.upper(value) or nil
	if point and self.AnchorPointSet[point] then return point end

	local fallbackPoint = type(fallback) == "string" and string.upper(fallback) or "CENTER"
	if self.AnchorPointSet[fallbackPoint] then return fallbackPoint end

	return "CENTER"
end

function SharedAnchors:NormalizeRelativeFrame(value)
	if type(value) ~= "string" or value == "" then return "UIParent" end
	if GENERIC_ANCHORS[value] then return value end
	if GENERIC_ANCHOR_BY_FRAME[value] then return GENERIC_ANCHOR_BY_FRAME[value] end
	local helper = getCooldownPanelHelper()
	if helper and helper.NormalizeRelativeFrameName then return helper.NormalizeRelativeFrameName(value) end
	return value
end

function SharedAnchors:GetDefaultAnchorData(target)
	if self:NormalizeRelativeFrame(target) == "UIParent" then
		return {
			point = "CENTER",
			relativePoint = "CENTER",
			x = 0,
			y = 0,
		}
	end

	return {
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		x = 0,
		y = 0,
	}
end

function SharedAnchors:GetTargetLabel(value)
	local target = self:NormalizeRelativeFrame(value)
	if target == "UIParent" then return "UIParent" end

	local helper = getCooldownPanelHelper()
	local generic = helper and helper.GENERIC_ANCHORS and helper.GENERIC_ANCHORS[target]
	local genericLabel = getGenericAnchorLabel(target)
	if genericLabel then return genericLabel end
	if generic and generic.label then return generic.label end

	local viewerLabel = COOLDOWN_VIEWER_LABELS[target]
	if viewerLabel then return viewerLabel end

	for i = 1, #ACTION_BAR_ANCHORS do
		local entry = ACTION_BAR_ANCHORS[i]
		if entry.key == target then return entry.label or target end
	end

	local panelId = frameNameToPanelId(target)
	if panelId then
		local cooldownPanels = getCooldownPanels()
		local panel = cooldownPanels and cooldownPanels.GetPanel and cooldownPanels:GetPanel(panelId)
			return (L["cooldownPanelReferenceLabel"]):format(tostring(panelId), panel and panel.name or L["cooldownPanelDefaultName"])
	end

	local cooldownPanels = getCooldownPanels()
	local anchorHelper = cooldownPanels and cooldownPanels.AnchorHelper
	if anchorHelper and anchorHelper.GetAnchorLabel then
		local label = anchorHelper:GetAnchorLabel(target)
		if type(label) == "string" and label ~= "" then return label end
	end

	return target
end

function SharedAnchors:GetEntries(currentTarget, opts)
	opts = type(opts) == "table" and opts or {}

	local entries = {}
	local valid = {}
	local seen = {}
	local cooldownPanels = getCooldownPanels()
	local current = self:NormalizeRelativeFrame(currentTarget)

	if cooldownPanels and cooldownPanels.GetRelativeFrameCache then
		local cache = cooldownPanels.GetRelativeFrameCache(nil, {
			anchor = {
				relativeFrame = current,
			},
		}, nil)

		if cache and cache.entries then
			for i = 1, #cache.entries do
				local entry = cache.entries[i]
				local key = entry and entry.key
				if key and not (opts.includeCursor == false and key == "EQOL_CooldownPanelsFakeCursor") then addEntry(entries, valid, seen, key, entry.label) end
			end
		end
	end

	if not seen.UIParent then addEntry(entries, valid, seen, "UIParent", "UIParent") end

	for i = 1, #GENERIC_ANCHOR_ORDER do
		local key = GENERIC_ANCHOR_ORDER[i]
		addEntry(entries, valid, seen, key, self:GetTargetLabel(key))
	end

	local actionBars = collectActionBarEntries()
	for i = 1, #actionBars do
		local entry = actionBars[i]
		addEntry(entries, valid, seen, entry.key, entry.label)
	end

	local extraEntries = opts.extraEntries
	if type(extraEntries) == "table" then
		for i = 1, #extraEntries do
			local entry = extraEntries[i]
			if entry and entry.key then addEntry(entries, valid, seen, self:NormalizeRelativeFrame(entry.key), entry.label) end
		end
	end

	if current ~= "" and not seen[current] then addEntry(entries, valid, seen, current, self:GetTargetLabel(current)) end

	return entries, valid
end

function SharedAnchors:ValidateTarget(value, currentTarget, opts)
	local normalized = self:NormalizeRelativeFrame(value)
	local _, valid = self:GetEntries(currentTarget, opts)
	if valid and valid[normalized] then return normalized end
	return "UIParent"
end

function SharedAnchors:ResolveFrame(value)
	local target = self:NormalizeRelativeFrame(value)
	if target == "UIParent" then return UIParent end

	local helper = getCooldownPanelHelper()
	local generic = GENERIC_ANCHORS[target] or (helper and helper.GENERIC_ANCHORS and helper.GENERIC_ANCHORS[target])
	if generic then
		local isEQoLFrameEnabled = addon.functions and addon.functions.IsEQoLUnitOrGroupFrameEnabled
		if generic.ufKey and isEQoLFrameEnabled and isEQoLFrameEnabled(generic.ufKey) then
			local ufFrame = _G[generic.uf]
			if ufFrame then return ufFrame end
		end

		if generic.blizz then
			local blizzFrame = _G[generic.blizz]
			if blizzFrame then return blizzFrame end
		end
	end

	local cooldownPanels = getCooldownPanels()
	local anchorHelper = cooldownPanels and cooldownPanels.AnchorHelper
	if anchorHelper and anchorHelper.ResolveExternalFrame then
		local externalFrame = anchorHelper:ResolveExternalFrame(target)
		if externalFrame then return externalFrame end
	end

	local frame = _G[target]
	if frame then return frame end

	self:MaybeScheduleRefresh(target)
	return UIParent
end

function SharedAnchors:IsPreferredFramePending(value)
	local target = self:NormalizeRelativeFrame(value)
	local helper = getCooldownPanelHelper()
	local generic = GENERIC_ANCHORS[target] or (helper and helper.GENERIC_ANCHORS and helper.GENERIC_ANCHORS[target])
	if not generic or not generic.ufKey or not generic.uf then return false end

	local isEQoLFrameEnabled = addon.functions and addon.functions.IsEQoLUnitOrGroupFrameEnabled
	return isEQoLFrameEnabled and isEQoLFrameEnabled(generic.ufKey) and _G[generic.uf] == nil or false
end

function SharedAnchors:IsUIParentTarget(value) return self:NormalizeRelativeFrame(value) == "UIParent" end

function SharedAnchors:MaybeScheduleRefresh(target)
	local cooldownPanels = getCooldownPanels()
	local anchorHelper = cooldownPanels and cooldownPanels.AnchorHelper
	if anchorHelper and anchorHelper.MaybeScheduleRefresh then anchorHelper:MaybeScheduleRefresh(target) end
end

function SharedAnchors:GetAnchorPointOptions()
	local helper = getCooldownPanelHelper()
	if helper and helper.AnchorOptions then return helper.AnchorOptions end
	return self.AnchorPointOptions
end

function SharedAnchors:GetActionBarEntries()
	return collectActionBarEntries()
end

function SharedAnchors:GetUnitFrameEntries()
	local entries = {}
	for i = 1, #GENERIC_ANCHOR_ORDER do
		local key = GENERIC_ANCHOR_ORDER[i]
		entries[#entries + 1] = { key = key, label = self:GetTargetLabel(key) }
	end
	return entries
end

function SharedAnchors:GetUnitFrameDynamicAnchorConsumerId(key)
	local generic = GENERIC_ANCHORS[key]
	if not (generic and generic.ufKey and generic.uf) then return nil end
	local isEQoLFrameEnabled = addon.functions and addon.functions.IsEQoLUnitOrGroupFrameEnabled
	if not (isEQoLFrameEnabled and isEQoLFrameEnabled(generic.ufKey)) then return nil end
	return _G[generic.uf] and ("unitFrame:" .. key) or nil
end
