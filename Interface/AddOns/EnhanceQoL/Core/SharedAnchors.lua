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
	local helper = getCooldownPanelHelper()
	if helper and helper.NormalizeRelativeFrameName then return helper.NormalizeRelativeFrameName(value) end
	if type(value) ~= "string" or value == "" then return "UIParent" end
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
	if generic and generic.label then return generic.label end

	local viewerLabel = COOLDOWN_VIEWER_LABELS[target]
	if viewerLabel then return viewerLabel end

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
	local generic = helper and helper.GENERIC_ANCHORS and helper.GENERIC_ANCHORS[target]
	if generic then
		local ufCfg = addon.db and addon.db.ufFrames
		if ufCfg and generic.ufKey and ufCfg[generic.ufKey] and ufCfg[generic.ufKey].enabled then
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
