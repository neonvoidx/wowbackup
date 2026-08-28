local addonName, addon = ...

local SharedMedia = LibStub("LibSharedMedia-3.0", true)

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetItemInfoInstantFn = C_Item.GetItemInfoInstant
local GetItemInfoFn = C_Item.GetItemInfo
local GetBagItem = C_TooltipInfo.GetBagItem
local IsEquippableItemFn = C_Item.IsEquippableItem
addon.functions = addon.functions or {}
addon.PixelUtil = addon.PixelUtil or {}

local PixelUtil = addon.PixelUtil
local BAGS_ADDON_NAME = "EnhanceQoLBags"
local RESOURCE_BARS_ADDON_NAME = "EnhanceQoLResourceBars"
local TOOLTIP_ADDON_NAME = "EnhanceQoLTooltip"

local function isAddonLoaded(addonName)
	if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(addonName) == true end
	if IsAddOnLoaded then return IsAddOnLoaded(addonName) == true end
	return nil
end

function addon.functions.IsBagsAddonLoaded()
	local loaded = isAddonLoaded(BAGS_ADDON_NAME)
	if loaded ~= nil then return loaded end
	return addon.Bags and type(addon.Bags.IsEnabled) == "function" or false
end

function addon.functions.IsBagsModuleActive()
	if not addon.functions.IsBagsAddonLoaded() then return false end
	if addon.Bags and type(addon.Bags.IsEnabled) == "function" then return addon.Bags.IsEnabled() == true end
	return addon.db and addon.db.enableBagsModule == true or false
end

function addon.functions.IsResourceBarsAddonLoaded()
	local loaded = isAddonLoaded(RESOURCE_BARS_ADDON_NAME)
	if loaded ~= nil then return loaded end
	return addon.Aura and addon.Aura.ResourceBars ~= nil or false
end

function addon.functions.IsTooltipAddonLoaded()
	local loaded = isAddonLoaded(TOOLTIP_ADDON_NAME)
	if loaded ~= nil then return loaded end
	return addon.Tooltip ~= nil or false
end

function PixelUtil.ApplyTexturePixelSnapping(texture, bias)
	if not texture then return nil end
	if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
	if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(bias or 0) end
	return texture
end

function PixelUtil.Round(value)
	value = tonumber(value) or 0
	if value >= 0 then return math.floor(value + 0.5) end
	return math.ceil(value - 0.5)
end

function PixelUtil.GetPixelScale(region)
	local scale
	if region and region.GetEffectiveScale then
		scale = region:GetEffectiveScale()
	elseif UIParent and UIParent.GetEffectiveScale then
		scale = UIParent:GetEffectiveScale()
	elseif UIParent and UIParent.GetScale then
		scale = UIParent:GetScale()
	end
	scale = tonumber(scale) or 1
	if scale <= 0 then scale = 1 end

	local _, physicalHeight
	if GetPhysicalScreenSize then
		_, physicalHeight = GetPhysicalScreenSize()
	end
	if (not physicalHeight or physicalHeight <= 0) and GetScreenHeight then
		physicalHeight = GetScreenHeight()
	end
	physicalHeight = tonumber(physicalHeight) or 768
	if physicalHeight <= 0 then physicalHeight = 768 end

	local factor = 768 / physicalHeight
	if factor <= 0 then factor = 1 end
	return scale, factor
end

function PixelUtil.PixelsToUi(pixels, scale, factor)
	scale = tonumber(scale) or 1
	factor = tonumber(factor) or 1
	if scale <= 0 then scale = 1 end
	if factor <= 0 then factor = 1 end
	return ((tonumber(pixels) or 0) * factor) / scale
end

function PixelUtil.UiToPixels(value, region, minPixels)
	local scale, factor = PixelUtil.GetPixelScale(region)
	local pixels = PixelUtil.Round(((tonumber(value) or 0) * scale) / factor)
	minPixels = tonumber(minPixels)
	if minPixels and minPixels > 0 then
		if pixels > 0 and pixels < minPixels then pixels = minPixels end
		if pixels < 0 and pixels > -minPixels then pixels = -minPixels end
	end
	return pixels, scale, factor
end

function PixelUtil.OnePixel(region)
	local scale, factor = PixelUtil.GetPixelScale(region)
	return PixelUtil.PixelsToUi(1, scale, factor)
end

function PixelUtil.SizeFromPixels(region, pixels, minPixels)
	pixels = tonumber(pixels) or 0
	minPixels = tonumber(minPixels) or 0
	if pixels > 0 and pixels < minPixels then pixels = minPixels end
	if pixels < 0 and pixels > -minPixels then pixels = -minPixels end
	local scale, factor = PixelUtil.GetPixelScale(region)
	return PixelUtil.PixelsToUi(PixelUtil.Round(pixels), scale, factor)
end

function PixelUtil.Snap(value, region)
	value = tonumber(value) or 0
	if value == 0 then return 0 end
	local onePixel = PixelUtil.OnePixel(region)
	if onePixel <= 0 then return value end
	return PixelUtil.Round(value / onePixel) * onePixel
end

function PixelUtil.Scale(value, region)
	value = tonumber(value) or 0
	if value == 0 then return 0 end
	local onePixel = PixelUtil.OnePixel(region)
	if onePixel <= 0 then return value end
	local pixels = value / onePixel
	if value > 0 then
		pixels = math.floor(pixels)
	else
		pixels = math.ceil(pixels)
	end
	return pixels * onePixel
end

function PixelUtil.Size(frame, width, height)
	if not (frame and frame.SetSize) then return end
	width = PixelUtil.Snap(width, frame)
	height = height ~= nil and PixelUtil.Snap(height, frame) or width
	frame:SetSize(width, height)
end

function PixelUtil.Width(frame, width)
	if not (frame and frame.SetWidth) then return end
	frame:SetWidth(PixelUtil.Snap(width, frame))
end

function PixelUtil.Height(frame, height)
	if not (frame and frame.SetHeight) then return end
	frame:SetHeight(PixelUtil.Snap(height, frame))
end

function PixelUtil.Point(frame, point, relativeTo, relativePoint, x, y)
	if not (frame and frame.SetPoint) then return end
	relativeTo = relativeTo or (frame.GetParent and frame:GetParent()) or UIParent
	x = PixelUtil.Snap(x or 0, relativeTo)
	y = PixelUtil.Snap(y or 0, relativeTo)
	frame:SetPoint(point, relativeTo, relativePoint or point, x, y)
end

function PixelUtil.SetInside(region, anchor, xOffset, yOffset)
	if not (region and region.ClearAllPoints and region.SetPoint) then return end
	anchor = anchor or (region.GetParent and region:GetParent()) or UIParent
	xOffset = PixelUtil.Snap(xOffset or 0, anchor)
	yOffset = PixelUtil.Snap(yOffset or xOffset, anchor)
	region:ClearAllPoints()
	PixelUtil.ApplyTexturePixelSnapping(region, 0)
	region:SetPoint("TOPLEFT", anchor, "TOPLEFT", xOffset, -yOffset)
	region:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -xOffset, yOffset)
end

function PixelUtil.SetOutside(region, anchor, xOffset, yOffset)
	if not (region and region.ClearAllPoints and region.SetPoint) then return end
	anchor = anchor or (region.GetParent and region:GetParent()) or UIParent
	xOffset = PixelUtil.Snap(xOffset or 0, anchor)
	yOffset = PixelUtil.Snap(yOffset or xOffset, anchor)
	region:ClearAllPoints()
	PixelUtil.ApplyTexturePixelSnapping(region, 0)
	region:SetPoint("TOPLEFT", anchor, "TOPLEFT", -xOffset, yOffset)
	region:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", xOffset, -yOffset)
end

function PixelUtil.SetInset(region, anchor, left, right, top, bottom)
	if not (region and region.ClearAllPoints and region.SetPoint) then return end
	anchor = anchor or (region.GetParent and region:GetParent()) or UIParent
	left = PixelUtil.Snap(left or 0, anchor)
	right = PixelUtil.Snap(right or 0, anchor)
	top = PixelUtil.Snap(top or 0, anchor)
	bottom = PixelUtil.Snap(bottom or 0, anchor)
	region:ClearAllPoints()
	PixelUtil.ApplyTexturePixelSnapping(region, 0)
	region:SetPoint("TOPLEFT", anchor, "TOPLEFT", left, -top)
	region:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -right, bottom)
end

function PixelUtil.ApplyStatusBarTexturePixelSnapping(bar, bias)
	if not (bar and bar.GetStatusBarTexture) then return nil end
	local texture = PixelUtil.ApplyTexturePixelSnapping(bar:GetStatusBarTexture(), bias)
	if texture and texture.ClearAllPoints and texture.SetPoint then PixelUtil.SetInside(texture, bar, 0, 0) end
	return texture
end

function PixelUtil.ApplySafeBorderTextureSnapping(frame, stateKey, bias)
	local state = frame and frame[stateKey or "_eqolSafeBorder"]
	if not state then return end
	PixelUtil.ApplyTexturePixelSnapping(state.top, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.bottom, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.left, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.right, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.topLeft, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.topRight, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.bottomLeft, bias or 0)
	PixelUtil.ApplyTexturePixelSnapping(state.bottomRight, bias or 0)
end

function PixelUtil.ResolveBorderContentInset(edgeSize, outset, alpha)
	if issecretvalue and issecretvalue(alpha) then return 0 end
	alpha = tonumber(alpha) or 0
	if alpha <= 0 then return 0 end
	edgeSize = tonumber(edgeSize) or 0
	if edgeSize <= 0 then return 0 end
	outset = tonumber(outset) or 0
	if outset < 0 then outset = 0 end
	local inset = edgeSize - outset
	if inset <= 0 then return 0 end
	return math.max(1, math.ceil(inset))
end

function PixelUtil.ResolveColorAlpha(color)
	if type(color) ~= "table" then return 0 end
	return color[4] or color.a or 0
end

function addon.functions.IsMinigameClientScene(sceneType)
	if Enum and Enum.ClientSceneType and Enum.ClientSceneType.MinigameSceneType ~= nil then
		return sceneType == Enum.ClientSceneType.MinigameSceneType
	end
	return sceneType == 1
end

local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local GLOBAL_FONT_CONFIG_KEY = "__EQOL_GLOBAL_FONT__"
local GLOBAL_FONT_CONFIG_LABEL = "Use global font config"
local GLOBAL_FONT_STYLE_CONFIG_KEY = "__EQOL_GLOBAL_FONT_STYLE__"
local GLOBAL_FONT_STYLE_CONFIG_LABEL = "Use global font styling"
local FONT_STYLE_NONE = "NONE"
local FONT_STYLE_OUTLINE = "OUTLINE"
local FONT_STYLE_THICKOUTLINE = "THICKOUTLINE"
local FONT_STYLE_MONOCHROME = "MONOCHROME"
local FONT_STYLE_MONOCHROMEOUTLINE = "MONOCHROMEOUTLINE"
local FONT_STYLE_MONOCHROMETHICKOUTLINE = "MONOCHROMETHICKOUTLINE"
local FONT_STYLE_SLUG = "SLUG"
local FONT_STYLE_SLUGOUTLINE = "SLUGOUTLINE"
local FONT_STYLE_SLUGTHICKOUTLINE = "SLUGTHICKOUTLINE"
local FONT_STYLE_SLUGMONOCHROME = "SLUGMONOCHROME"
local FONT_STYLE_SLUGMONOCHROMEOUTLINE = "SLUGMONOCHROMEOUTLINE"
local FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE = "SLUGMONOCHROMETHICKOUTLINE"
local FONT_STYLE_SHADOW = "SHADOW"
local FONT_STYLE_SHADOWOUTLINE = "SHADOWOUTLINE"
local FONT_STYLE_SHADOWTHICKOUTLINE = "SHADOWTHICKOUTLINE"
local FONT_STYLE_SLUGSHADOW = "SLUGSHADOW"
local FONT_STYLE_SLUGSHADOWOUTLINE = "SLUGSHADOWOUTLINE"
local FONT_STYLE_SLUGSHADOWTHICKOUTLINE = "SLUGSHADOWTHICKOUTLINE"
local EMPTY_TABLE = {}
local GLOBAL_FONT_STATE_VERSION = 0
local LSM_CACHE = {}
local LSM_DROPDOWN_CACHE = {}
local FONT_STYLE_ORDER = {
	FONT_STYLE_NONE,
	FONT_STYLE_OUTLINE,
	FONT_STYLE_THICKOUTLINE,
	FONT_STYLE_MONOCHROME,
	FONT_STYLE_MONOCHROMEOUTLINE,
	FONT_STYLE_MONOCHROMETHICKOUTLINE,
	FONT_STYLE_SLUG,
	FONT_STYLE_SLUGOUTLINE,
	FONT_STYLE_SLUGTHICKOUTLINE,
	FONT_STYLE_SLUGMONOCHROME,
	FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	FONT_STYLE_SHADOW,
	FONT_STYLE_SHADOWOUTLINE,
	FONT_STYLE_SHADOWTHICKOUTLINE,
	FONT_STYLE_SLUGSHADOW,
	FONT_STYLE_SLUGSHADOWOUTLINE,
	FONT_STYLE_SLUGSHADOWTHICKOUTLINE,
}
local FONT_STYLE_ALIASES = {
	[""] = FONT_STYLE_NONE,
	NONE = FONT_STYLE_NONE,
	OUTLINE = FONT_STYLE_OUTLINE,
	THICKOUTLINE = FONT_STYLE_THICKOUTLINE,
	MONOCHROME = FONT_STYLE_MONOCHROME,
	MONOCHROMEOUTLINE = FONT_STYLE_MONOCHROMEOUTLINE,
	MONOCHROMETHICKOUTLINE = FONT_STYLE_MONOCHROMETHICKOUTLINE,
	SLUG = FONT_STYLE_SLUG,
	SLUGOUTLINE = FONT_STYLE_SLUGOUTLINE,
	SLUGTHICKOUTLINE = FONT_STYLE_SLUGTHICKOUTLINE,
	SLUGMONOCHROME = FONT_STYLE_SLUGMONOCHROME,
	SLUGMONOCHROMEOUTLINE = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	SLUGMONOCHROMETHICKOUTLINE = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["OUTLINE,MONOCHROME"] = FONT_STYLE_MONOCHROMEOUTLINE,
	["MONOCHROME,OUTLINE"] = FONT_STYLE_MONOCHROMEOUTLINE,
	["THICKOUTLINE,MONOCHROME"] = FONT_STYLE_MONOCHROMETHICKOUTLINE,
	["MONOCHROME,THICKOUTLINE"] = FONT_STYLE_MONOCHROMETHICKOUTLINE,
	["OUTLINE,SLUG"] = FONT_STYLE_SLUGOUTLINE,
	["SLUG,OUTLINE"] = FONT_STYLE_SLUGOUTLINE,
	["THICKOUTLINE,SLUG"] = FONT_STYLE_SLUGTHICKOUTLINE,
	["SLUG,THICKOUTLINE"] = FONT_STYLE_SLUGTHICKOUTLINE,
	["MONOCHROME,SLUG"] = FONT_STYLE_SLUGMONOCHROME,
	["SLUG,MONOCHROME"] = FONT_STYLE_SLUGMONOCHROME,
	["OUTLINE,MONOCHROME,SLUG"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["OUTLINE,SLUG,MONOCHROME"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["MONOCHROME,OUTLINE,SLUG"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["MONOCHROME,SLUG,OUTLINE"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["SLUG,OUTLINE,MONOCHROME"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["SLUG,MONOCHROME,OUTLINE"] = FONT_STYLE_SLUGMONOCHROMEOUTLINE,
	["THICKOUTLINE,MONOCHROME,SLUG"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["THICKOUTLINE,SLUG,MONOCHROME"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["MONOCHROME,THICKOUTLINE,SLUG"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["MONOCHROME,SLUG,THICKOUTLINE"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["SLUG,THICKOUTLINE,MONOCHROME"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	["SLUG,MONOCHROME,THICKOUTLINE"] = FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE,
	DROPSHADOW = FONT_STYLE_SHADOW,
	STRONGDROPSHADOW = FONT_STYLE_SHADOW,
	SHADOW = FONT_STYLE_SHADOW,
	SHADOWOUTLINE = FONT_STYLE_SHADOWOUTLINE,
	SHADOWTHICKOUTLINE = FONT_STYLE_SHADOWTHICKOUTLINE,
	SLUGSHADOW = FONT_STYLE_SLUGSHADOW,
	SLUGSHADOWOUTLINE = FONT_STYLE_SLUGSHADOWOUTLINE,
	SLUGSHADOWTHICKOUTLINE = FONT_STYLE_SLUGSHADOWTHICKOUTLINE,
}
local FONT_STYLE_DESCRIPTORS = {
	[FONT_STYLE_NONE] = { flags = nil, shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_OUTLINE] = { flags = "OUTLINE", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_THICKOUTLINE] = { flags = "THICKOUTLINE", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_MONOCHROME] = { flags = "MONOCHROME", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_MONOCHROMEOUTLINE] = { flags = "OUTLINE,MONOCHROME", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_MONOCHROMETHICKOUTLINE] = { flags = "THICKOUTLINE,MONOCHROME", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUG] = { flags = "SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUGOUTLINE] = { flags = "OUTLINE,SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUGTHICKOUTLINE] = { flags = "THICKOUTLINE,SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUGMONOCHROME] = { flags = "MONOCHROME,SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUGMONOCHROMEOUTLINE] = { flags = "OUTLINE,MONOCHROME,SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE] = { flags = "THICKOUTLINE,MONOCHROME,SLUG", shadowAlpha = 0, shadowX = 0, shadowY = 0 },
	[FONT_STYLE_SHADOW] = { flags = nil, shadowAlpha = 1, shadowX = 1, shadowY = -1 },
	[FONT_STYLE_SHADOWOUTLINE] = { flags = "OUTLINE", shadowAlpha = 0.6, shadowX = 1, shadowY = -1 },
	[FONT_STYLE_SHADOWTHICKOUTLINE] = { flags = "THICKOUTLINE", shadowAlpha = 0.6, shadowX = 1, shadowY = -1 },
	[FONT_STYLE_SLUGSHADOW] = { flags = "SLUG", shadowAlpha = 1, shadowX = 1, shadowY = -1 },
	[FONT_STYLE_SLUGSHADOWOUTLINE] = { flags = "OUTLINE,SLUG", shadowAlpha = 0.6, shadowX = 1, shadowY = -1 },
	[FONT_STYLE_SLUGSHADOWTHICKOUTLINE] = { flags = "THICKOUTLINE,SLUG", shadowAlpha = 0.6, shadowX = 1, shadowY = -1 },
}
local upgradeTrackMeta = {
	explorer = { label = "Explorer", quality = Enum.ItemQuality.Poor, aliases = { "explorer" } },
	adventurer = { label = "Adventurer", quality = Enum.ItemQuality.Common, aliases = { "adventurer" } },
	veteran = { labelKey = "upgradeLevelVeteran", quality = Enum.ItemQuality.Uncommon, ids = { 972 }, aliases = { "veteran" } },
	champion = { labelKey = "upgradeLevelChampion", quality = Enum.ItemQuality.Rare, ids = { 973 }, aliases = { "champion" } },
	hero = { labelKey = "upgradeLevelHero", quality = Enum.ItemQuality.Epic, ids = { 974 }, aliases = { "hero" } },
	myth = { labelKey = "upgradeLevelMythic", quality = Enum.ItemQuality.Legendary, ids = { 975 }, aliases = { "myth", "mythic" } },
}
local upgradeTrackAliasMap = nil
local upgradeTrackIDMap = nil

local function trimUpgradeTrackText(text)
	if type(text) ~= "string" then return nil end
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return nil end
	return text
end

local function getFirstUtf8Char(text)
	if type(text) ~= "string" or text == "" then return nil end
	return text:match("[%z\1-\127\194-\244][\128-\191]*")
end

local function getUpgradeTrackLabelText(info)
	if not info then return nil end
	if info.labelKey then return trimUpgradeTrackText(L[info.labelKey]) end
	return trimUpgradeTrackText(info.label)
end

local function getUpgradeTrackAliasMap()
	if upgradeTrackAliasMap then return upgradeTrackAliasMap end
	upgradeTrackAliasMap = {}
	for key, info in pairs(upgradeTrackMeta) do
		upgradeTrackAliasMap[key] = key
		local localized = getUpgradeTrackLabelText(info)
		if localized then upgradeTrackAliasMap[string.lower(localized)] = key end
		if info.aliases then
			for i = 1, #info.aliases do
				local alias = trimUpgradeTrackText(info.aliases[i])
				if alias then upgradeTrackAliasMap[string.lower(alias)] = key end
			end
		end
	end
	return upgradeTrackAliasMap
end

local function getUpgradeTrackIDMap()
	if upgradeTrackIDMap then return upgradeTrackIDMap end
	upgradeTrackIDMap = {}
	for key, info in pairs(upgradeTrackMeta) do
		if info.ids then
			for i = 1, #info.ids do
				upgradeTrackIDMap[info.ids[i]] = key
			end
		end
	end
	return upgradeTrackIDMap
end

local function getUpgradeTrackCanonicalKey(trackID, trackKey)
	if type(trackID) == "number" then
		local canonicalByID = getUpgradeTrackIDMap()[trackID]
		if canonicalByID then return canonicalByID end
	end
	trackKey = trimUpgradeTrackText(trackKey)
	if trackKey then
		local canonicalByString = getUpgradeTrackAliasMap()[string.lower(trackKey)]
		if canonicalByString then return canonicalByString end
	end
	return nil
end

local function normalizeMediaType(mediaType)
	if type(mediaType) ~= "string" or mediaType == "" then return nil end
	return string.lower(mediaType)
end

local function getSharedMedia()
	if SharedMedia and SharedMedia.HashTable then return SharedMedia end
	SharedMedia = LibStub("LibSharedMedia-3.0", true)
	return SharedMedia
end

local function ensureLSMCache(mediaType)
	local key = normalizeMediaType(mediaType)
	if not key then return nil end
	local cache = LSM_CACHE[key]
	if not cache then
		cache = {
			dirty = true,
			version = 0,
			hash = EMPTY_TABLE,
			names = EMPTY_TABLE,
			options = EMPTY_TABLE,
			resolved = {},
		}
		LSM_CACHE[key] = cache
	end
	return cache, key
end

local function sortMediaNames(names)
	table.sort(names, function(a, b)
		local al = string.lower(a)
		local bl = string.lower(b)
		if al == bl then return a < b end
		return al < bl
	end)
end

local function rebuildLSMCache(mediaType)
	local cache, key = ensureLSMCache(mediaType)
	if not cache or not key then return nil end

	local lsm = getSharedMedia()
	local hash = (lsm and lsm.HashTable and lsm:HashTable(key)) or EMPTY_TABLE

	local names = {}
	for name in pairs(hash or EMPTY_TABLE) do
		if type(name) == "string" and name ~= "" then names[#names + 1] = name end
	end
	sortMediaNames(names)

	local options = {}
	for i = 1, #names do
		local name = names[i]
		options[i] = {
			value = name,
			label = name,
		}
	end

	cache.hash = hash
	cache.names = names
	cache.options = options
	cache.dirty = false
	return cache
end

local function getLSMCache(mediaType)
	local cache = ensureLSMCache(mediaType)
	if not cache then return nil end
	if cache.dirty then cache = rebuildLSMCache(mediaType) end
	return cache
end

function addon.functions.InvalidateLSMMediaCache(mediaType)
	if mediaType == nil then
		for _, cache in pairs(LSM_CACHE) do
			cache.dirty = true
			cache.version = (cache.version or 0) + 1
			cache.resolved = {}
		end
		LSM_DROPDOWN_CACHE = {}
		return
	end

	local cache, key = ensureLSMCache(mediaType)
	if not cache or not key then return end
	cache.dirty = true
	cache.version = (cache.version or 0) + 1
	cache.resolved = {}
	for cacheKey in pairs(LSM_DROPDOWN_CACHE) do
		if type(cacheKey) == "string" and cacheKey:find(key .. "|", 1, true) == 1 then LSM_DROPDOWN_CACHE[cacheKey] = nil end
	end
end

function addon.functions.GetLSMMediaVersion(mediaType)
	local cache = ensureLSMCache(mediaType)
	if not cache then return 0 end
	return cache.version or 0
end

function addon.functions.GetLSMMediaHash(mediaType)
	local cache = getLSMCache(mediaType)
	return (cache and cache.hash) or EMPTY_TABLE
end

function addon.functions.GetLSMMediaNames(mediaType)
	local cache = getLSMCache(mediaType)
	return (cache and cache.names) or EMPTY_TABLE
end

function addon.functions.GetLSMMediaOptions(mediaType)
	local cache = getLSMCache(mediaType)
	return (cache and cache.options) or EMPTY_TABLE
end

function addon.functions.GetLSMMediaDropdown(mediaType, includeEmptyOption, emptyLabel)
	local key = normalizeMediaType(mediaType)
	if not key then return EMPTY_TABLE, EMPTY_TABLE end

	local cache = getLSMCache(key)
	local version = cache and cache.version or 0
	local noneLabel = (type(emptyLabel) == "string" and emptyLabel) or ""
	local includeEmpty = includeEmptyOption == true
	local cacheKey = key .. "|" .. (includeEmpty and "1" or "0") .. "|" .. noneLabel
	local cached = LSM_DROPDOWN_CACHE[cacheKey]
	if cached and cached.version == version then return cached.list, cached.order end

	local names = cache and cache.names or EMPTY_TABLE
	local list = {}
	local order = {}
	if includeEmpty then
		list[""] = noneLabel
		order[#order + 1] = ""
	end
	for i = 1, #names do
		local name = names[i]
		list[name] = name
		order[#order + 1] = name
	end

	LSM_DROPDOWN_CACHE[cacheKey] = {
		version = version,
		list = list,
		order = order,
	}
	return list, order
end

function addon.functions.SetSafeBorder(frame, enabled, textureKey, size, r, g, b, a, options)
	if not frame then return false end
	options = type(options) == "table" and options or EMPTY_TABLE
	local stateKey = options.stateKey or "_eqolSafeBorder"
	local state = frame[stateKey]
	if not state then
		state = {}
		frame[stateKey] = state
	end

	if not enabled then
		state.enabled = false
		if state.top then state.top:Hide() end
		if state.bottom then state.bottom:Hide() end
		if state.left then state.left:Hide() end
		if state.right then state.right:Hide() end
		if state.topLeft then state.topLeft:Hide() end
		if state.topRight then state.topRight:Hide() end
		if state.bottomLeft then state.bottomLeft:Hide() end
		if state.bottomRight then state.bottomRight:Hide() end
		frame:Hide()
		return true
	end

	local defaultTexture = options.defaultTexture or "Interface\\Buttons\\WHITE8x8"
	local texture = textureKey
	if type(texture) ~= "string" or texture == "" or texture == "DEFAULT" then
		texture = defaultTexture
	elseif options.mediaType then
		local media = addon.functions.GetLSMMediaHash(options.mediaType)
		if type(media) == "table" and type(media[texture]) == "string" and media[texture] ~= "" then texture = media[texture] end
	end

	if options.pixelPerfect == true then
		size = PixelUtil.SizeFromPixels(frame, size, 1)
	else
		size = tonumber(size) or 1
		if size < 1 then size = 1 end
	end
	local useSlices = options.useSlices
	if useSlices == nil then useSlices = texture ~= defaultTexture end
	local layer = options.drawLayer or "BORDER"

	if not state.top then
		state.top = frame:CreateTexture(nil, layer)
		state.bottom = frame:CreateTexture(nil, layer)
		state.left = frame:CreateTexture(nil, layer)
		state.right = frame:CreateTexture(nil, layer)
		state.topLeft = frame:CreateTexture(nil, layer)
		state.topRight = frame:CreateTexture(nil, layer)
		state.bottomLeft = frame:CreateTexture(nil, layer)
		state.bottomRight = frame:CreateTexture(nil, layer)
	end

	if state.texture ~= texture or state.size ~= size or state.useSlices ~= useSlices or not state.top:GetTexture() then
		state.texture = texture
		state.size = size
		state.useSlices = useSlices

		state.top:SetTexture(texture)
		state.bottom:SetTexture(texture)
		state.left:SetTexture(texture)
		state.right:SetTexture(texture)
		state.topLeft:SetTexture(texture)
		state.topRight:SetTexture(texture)
		state.bottomLeft:SetTexture(texture)
		state.bottomRight:SetTexture(texture)

		if useSlices then
			state.topLeft:SetTexCoord(0.5078125, 0.0625, 0.5078125, 0.9375, 0.6171875, 0.0625, 0.6171875, 0.9375)
			state.topRight:SetTexCoord(0.6328125, 0.0625, 0.6328125, 0.9375, 0.7421875, 0.0625, 0.7421875, 0.9375)
			state.bottomLeft:SetTexCoord(0.7578125, 0.0625, 0.7578125, 0.9375, 0.8671875, 0.0625, 0.8671875, 0.9375)
			state.bottomRight:SetTexCoord(0.8828125, 0.0625, 0.8828125, 0.9375, 0.9921875, 0.0625, 0.9921875, 0.9375)
			state.top:SetTexCoord(0.2578125, 0.9375, 0.3671875, 0.9375, 0.2578125, 0.0625, 0.3671875, 0.0625)
			state.bottom:SetTexCoord(0.3828125, 0.9375, 0.4921875, 0.9375, 0.3828125, 0.0625, 0.4921875, 0.0625)
			state.left:SetTexCoord(0.0078125, 0.0625, 0.0078125, 0.9375, 0.1171875, 0.0625, 0.1171875, 0.9375)
			state.right:SetTexCoord(0.1328125, 0.0625, 0.1328125, 0.9375, 0.2421875, 0.0625, 0.2421875, 0.9375)
		else
			state.top:SetTexCoord(0, 1, 0, 1)
			state.bottom:SetTexCoord(0, 1, 0, 1)
			state.left:SetTexCoord(0, 1, 0, 1)
			state.right:SetTexCoord(0, 1, 0, 1)
			state.topLeft:SetTexCoord(0, 1, 0, 1)
			state.topRight:SetTexCoord(0, 1, 0, 1)
			state.bottomLeft:SetTexCoord(0, 1, 0, 1)
			state.bottomRight:SetTexCoord(0, 1, 0, 1)
		end
		if options.pixelPerfect == true then PixelUtil.ApplySafeBorderTextureSnapping(frame, stateKey, options.texelSnappingBias or 0) end

		state.topLeft:ClearAllPoints()
		state.topLeft:SetPoint("TOPLEFT", frame, "TOPLEFT")
		state.topLeft:SetSize(size, size)
		state.topRight:ClearAllPoints()
		state.topRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
		state.topRight:SetSize(size, size)
		state.bottomLeft:ClearAllPoints()
		state.bottomLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
		state.bottomLeft:SetSize(size, size)
		state.bottomRight:ClearAllPoints()
		state.bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		state.bottomRight:SetSize(size, size)
		state.top:ClearAllPoints()
		state.top:SetPoint("TOPLEFT", state.topLeft, "TOPRIGHT")
		state.top:SetPoint("TOPRIGHT", state.topRight, "TOPLEFT")
		state.top:SetHeight(size)
		state.bottom:ClearAllPoints()
		state.bottom:SetPoint("BOTTOMLEFT", state.bottomLeft, "BOTTOMRIGHT")
		state.bottom:SetPoint("BOTTOMRIGHT", state.bottomRight, "BOTTOMLEFT")
		state.bottom:SetHeight(size)
		state.left:ClearAllPoints()
		state.left:SetPoint("TOPLEFT", state.topLeft, "BOTTOMLEFT")
		state.left:SetPoint("BOTTOMLEFT", state.bottomLeft, "TOPLEFT")
		state.left:SetWidth(size)
		state.right:ClearAllPoints()
		state.right:SetPoint("TOPRIGHT", state.topRight, "BOTTOMRIGHT")
		state.right:SetPoint("BOTTOMRIGHT", state.bottomRight, "TOPRIGHT")
		state.right:SetWidth(size)
	end

	state.top:SetVertexColor(r, g, b, a)
	state.bottom:SetVertexColor(r, g, b, a)
	state.left:SetVertexColor(r, g, b, a)
	state.right:SetVertexColor(r, g, b, a)
	state.topLeft:SetVertexColor(r, g, b, a)
	state.topRight:SetVertexColor(r, g, b, a)
	state.bottomLeft:SetVertexColor(r, g, b, a)
	state.bottomRight:SetVertexColor(r, g, b, a)
	if options.pixelPerfect == true then PixelUtil.ApplySafeBorderTextureSnapping(frame, stateKey, options.texelSnappingBias or 0) end

	state.top:Show()
	state.bottom:Show()
	state.left:Show()
	state.right:Show()
	state.topLeft:Show()
	state.topRight:Show()
	state.bottomLeft:Show()
	state.bottomRight:Show()
	frame:Show()
	state.enabled = true
	return true
end

local function normalizeMediaValue(value)
	if type(value) ~= "string" or value == "" then return nil end
	return value
end

local function isMediaPath(value)
	return type(value) == "string" and (value:find("\\", 1, true) or value:find("/", 1, true)) ~= nil
end

local function getUIFileAssetAPI() return _G.C_UIFileAsset end

local function hasFileAssetValue(value)
	if type(value) == "number" then return value > 0 end
	return type(value) == "string" and value ~= ""
end

local function isKnownFileAsset(value)
	if not hasFileAssetValue(value) then return false end
	local fileAssetAPI = _G.C_UIFileAsset
	if not (fileAssetAPI and fileAssetAPI.IsKnownFile) then return true end
	local ok, known = pcall(fileAssetAPI.IsKnownFile, value)
	return ok and known == true
end

local function isLooseFileAsset(value)
	if not hasFileAssetValue(value) then return false end
	local fileAssetAPI = getUIFileAssetAPI()
	if not (fileAssetAPI and fileAssetAPI.IsLooseFile) then return false end
	local ok, isLoose = pcall(fileAssetAPI.IsLooseFile, value)
	return ok and isLoose == true
end

local function getFileAssetID(value)
	if not hasFileAssetValue(value) then return nil end
	local fileAssetAPI = getUIFileAssetAPI()
	if not (fileAssetAPI and fileAssetAPI.GetFileID) then return type(value) == "number" and value or nil end
	local ok, fileID = pcall(fileAssetAPI.GetFileID, value)
	if not ok then return nil end
	fileID = tonumber(fileID)
	if not fileID or fileID <= 0 then return nil end
	if math.floor(fileID) ~= fileID then return nil end
	return fileID
end

local function shouldUseFileAsset(value, requireKnown)
	if not hasFileAssetValue(value) then return false end
	if requireKnown == false then return true end
	return isKnownFileAsset(value)
end

local function isGlobalFontConfigValue(value) return normalizeMediaValue(value) == GLOBAL_FONT_CONFIG_KEY end
local function isGlobalFontStyleConfigValue(value) return normalizeMediaValue(value) == GLOBAL_FONT_STYLE_CONFIG_KEY end
local function normalizeFontStyleValue(value)
	if type(value) ~= "string" then return nil end
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	if value == "" then return FONT_STYLE_NONE end
	return FONT_STYLE_ALIASES[string.upper(value)]
end

function addon.functions.GetGlobalFontConfigKey() return GLOBAL_FONT_CONFIG_KEY end

function addon.functions.GetGlobalFontConfigLabel()
	if L and L["useGlobalFontConfig"] then return L["useGlobalFontConfig"] end
	return GLOBAL_FONT_CONFIG_LABEL
end

function addon.functions.IsGlobalFontConfigValue(value) return isGlobalFontConfigValue(value) end

function addon.functions.IsKnownFileAsset(value) return isKnownFileAsset(value) end

function addon.functions.IsLooseFileAsset(value) return isLooseFileAsset(value) end

function addon.functions.GetFileAssetID(value) return getFileAssetID(value) end

function addon.functions.IsKnownFontAsset(value) return isKnownFileAsset(value) end

function addon.functions.GetLocaleDefaultFontFace() return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT end

function addon.functions.GetGlobalDefaultFontFace()
	local localeDefault = addon.functions.GetLocaleDefaultFontFace()
	local configured = addon.db and addon.db.globalFontFace
	return addon.functions.ResolveLSMMedia("font", configured, localeDefault, false) or localeDefault
end

local function defaultFontFace() return addon.functions.GetGlobalDefaultFontFace() end

local function getFontStyleLabel(style)
	if style == FONT_STYLE_NONE then return _G.NONE or "None" end
	if style == FONT_STYLE_OUTLINE then return L["Outline"] or "Outline" end
	if style == FONT_STYLE_THICKOUTLINE then return L["Thick Outline"] or "Thick Outline" end
	if style == FONT_STYLE_MONOCHROME then return L["Monochrome"] or "Monochrome" end
	if style == FONT_STYLE_MONOCHROMEOUTLINE then return L["Monochrome Outline"] or "Monochrome Outline" end
	if style == FONT_STYLE_MONOCHROMETHICKOUTLINE then return L["Monochrome Thick"] or "Monochrome Thick" end
	if style == FONT_STYLE_SLUG then return L["Slug"] or "Slug" end
	if style == FONT_STYLE_SLUGOUTLINE then return L["Slug Outline"] or "Slug Outline" end
	if style == FONT_STYLE_SLUGTHICKOUTLINE then return L["Slug Thick Outline"] or "Slug Thick Outline" end
	if style == FONT_STYLE_SLUGMONOCHROME then return L["Slug Monochrome"] or "Slug Monochrome" end
	if style == FONT_STYLE_SLUGMONOCHROMEOUTLINE then return L["Slug Monochrome Outline"] or "Slug Monochrome Outline" end
	if style == FONT_STYLE_SLUGMONOCHROMETHICKOUTLINE then return L["Slug Monochrome Thick"] or "Slug Monochrome Thick" end
	if style == FONT_STYLE_SHADOW then return L["Drop shadow"] or "Drop shadow" end
	if style == FONT_STYLE_SHADOWOUTLINE then return L["Shadow Outline"] or "Shadow Outline" end
	if style == FONT_STYLE_SHADOWTHICKOUTLINE then return L["Shadow Thick"] or "Shadow Thick" end
	if style == FONT_STYLE_SLUGSHADOW then return L["Slug Shadow"] or "Slug Shadow" end
	if style == FONT_STYLE_SLUGSHADOWOUTLINE then return L["Slug Shadow Outline"] or "Slug Shadow Outline" end
	if style == FONT_STYLE_SLUGSHADOWTHICKOUTLINE then return L["Slug Shadow Thick"] or "Slug Shadow Thick" end
	return tostring(style or "")
end

function addon.functions.ResolveLSMMedia(mediaType, configured, fallback, allowPath)
	local mediaKind = normalizeMediaType(mediaType)
	local fallbackValue = normalizeMediaValue(fallback)
	local configuredValue = normalizeMediaValue(configured)
	if isGlobalFontConfigValue(configuredValue) then return fallbackValue end
	if not configuredValue then return fallbackValue end
	if configuredValue == fallbackValue then return configuredValue end
	if not mediaKind then
		if allowPath ~= false and isMediaPath(configuredValue) then return configuredValue end
		return fallbackValue
	end
	local cache = ensureLSMCache(mediaKind)
	local resolvedByConfigured = cache and cache.resolved and cache.resolved[configuredValue]
	local fallbackKey = fallbackValue or false
	local allowPathKey = allowPath ~= false
	local resolvedByFallback = resolvedByConfigured and resolvedByConfigured[fallbackKey]
	local cached = resolvedByFallback and resolvedByFallback[allowPathKey]
	if cached then return cached end
	local function cacheResolved(value)
		if type(value) ~= "string" or value == "" or not cache then return value end
		resolvedByConfigured = resolvedByConfigured or {}
		cache.resolved[configuredValue] = resolvedByConfigured
		resolvedByFallback = resolvedByFallback or {}
		resolvedByConfigured[fallbackKey] = resolvedByFallback
		resolvedByFallback[allowPathKey] = value
		return value
	end
	local lsm = getSharedMedia()
	if lsm then
		if lsm.IsValid and lsm:IsValid(mediaKind, configuredValue) then
			local fetched = lsm.Fetch and lsm:Fetch(mediaKind, configuredValue, true)
			if type(fetched) == "string" and fetched ~= "" then
				if mediaKind == "font" then
					if isKnownFileAsset(fetched) then return cacheResolved(fetched) end
				elseif not isMediaPath(fetched) or shouldUseFileAsset(fetched, true) then
					return cacheResolved(fetched)
				end
			end
			return fallbackValue
		end
		if lsm.HashTable then
			local hash = lsm:HashTable(mediaKind) or {}
			local byName = hash[configuredValue]
			if type(byName) == "string" and byName ~= "" then
				if mediaKind == "font" then
					if isKnownFileAsset(byName) then return cacheResolved(byName) end
				elseif not isMediaPath(byName) or shouldUseFileAsset(byName, true) then
					return cacheResolved(byName)
				end
				return fallbackValue
			end
			for _, path in pairs(hash) do
				if path == configuredValue then
					if mediaKind == "font" then
						if isKnownFileAsset(configuredValue) then return cacheResolved(configuredValue) end
					elseif not isMediaPath(configuredValue) or shouldUseFileAsset(configuredValue, true) then
						return cacheResolved(configuredValue)
					end
					return fallbackValue
				end
			end
		end
	end
	if allowPath ~= false and mediaKind ~= "font" and isMediaPath(configuredValue) and shouldUseFileAsset(configuredValue, true) then return cacheResolved(configuredValue) end
	return fallbackValue
end

function addon.functions.ResolveFontFace(configured, fallback)
	local defaultFace = defaultFontFace()
	local fallbackFace = normalizeMediaValue(fallback)
	if isGlobalFontConfigValue(fallbackFace) then fallbackFace = nil end
	fallbackFace = addon.functions.ResolveLSMMedia("font", fallbackFace, defaultFace, false) or defaultFace
	if isGlobalFontConfigValue(configured) then return fallbackFace end
	return addon.functions.ResolveLSMMedia("font", configured, fallbackFace, false) or fallbackFace
end

function addon.functions.GetGlobalFontStyleConfigKey() return GLOBAL_FONT_STYLE_CONFIG_KEY end

function addon.functions.GetGlobalFontStyleConfigLabel()
	if L and L["useGlobalFontStyleConfig"] then return L["useGlobalFontStyleConfig"] end
	return GLOBAL_FONT_STYLE_CONFIG_LABEL
end

function addon.functions.GetGlobalFontStateVersion() return GLOBAL_FONT_STATE_VERSION end

function addon.functions.BumpGlobalFontStateVersion()
	GLOBAL_FONT_STATE_VERSION = GLOBAL_FONT_STATE_VERSION + 1
	return GLOBAL_FONT_STATE_VERSION
end

function addon.functions.IsGlobalFontStyleConfigValue(value) return isGlobalFontStyleConfigValue(value) end

function addon.functions.GetFontStyleLabel(style)
	local normalized = normalizeFontStyleValue(style)
	if normalized then return getFontStyleLabel(normalized) end
	if isGlobalFontStyleConfigValue(style) then return addon.functions.GetGlobalFontStyleConfigLabel() end
	return getFontStyleLabel(FONT_STYLE_NONE)
end

function addon.functions.GetFontStyleOptions(includeGlobalOption)
	local list = {}
	local order = {}
	if includeGlobalOption == true then
		local key = addon.functions.GetGlobalFontStyleConfigKey()
		list[key] = addon.functions.GetGlobalFontStyleConfigLabel()
		order[#order + 1] = key
	end
	for i = 1, #FONT_STYLE_ORDER do
		local key = FONT_STYLE_ORDER[i]
		list[key] = getFontStyleLabel(key)
		order[#order + 1] = key
	end
	return list, order
end

function addon.functions.GetFontStyleOptionList(includeGlobalOption)
	local list = {}
	if includeGlobalOption == true then
		list[#list + 1] = {
			value = addon.functions.GetGlobalFontStyleConfigKey(),
			label = addon.functions.GetGlobalFontStyleConfigLabel(),
		}
	end
	for i = 1, #FONT_STYLE_ORDER do
		local key = FONT_STYLE_ORDER[i]
		list[#list + 1] = {
			value = key,
			label = getFontStyleLabel(key),
		}
	end
	return list
end

function addon.functions.NormalizeFontStyleChoice(style, fallback, keepGlobalOption)
	local configured = normalizeMediaValue(style)
	if keepGlobalOption ~= false and isGlobalFontStyleConfigValue(configured) then return configured end
	local normalized = normalizeFontStyleValue(configured)
	if normalized then return normalized end

	local fallbackValue = normalizeMediaValue(fallback)
	if keepGlobalOption ~= false and isGlobalFontStyleConfigValue(fallbackValue) then return fallbackValue end
	normalized = normalizeFontStyleValue(fallbackValue)
	if normalized then return normalized end
	return FONT_STYLE_NONE
end

function addon.functions.GetGlobalDefaultFontStyle()
	local configured = addon.db and addon.db.globalFontStyle
	return addon.functions.NormalizeFontStyleChoice(configured, FONT_STYLE_OUTLINE, false)
end

function addon.functions.ResolveFontStyleChoice(style, fallback)
	local choice = addon.functions.NormalizeFontStyleChoice(style, fallback, true)
	if isGlobalFontStyleConfigValue(choice) then return addon.functions.GetGlobalDefaultFontStyle() end
	return addon.functions.NormalizeFontStyleChoice(choice, addon.functions.GetGlobalDefaultFontStyle(), false)
end

function addon.functions.ResolveFontStyle(style, fallback)
	local choice = addon.functions.ResolveFontStyleChoice(style, fallback)
	local descriptor = FONT_STYLE_DESCRIPTORS[choice] or FONT_STYLE_DESCRIPTORS[FONT_STYLE_NONE]
	return choice, descriptor.flags, descriptor.shadowAlpha or 0, descriptor.shadowX or 0, descriptor.shadowY or 0
end

function addon.functions.GetFontFlagsForStyle(style, fallback)
	local _, flags = addon.functions.ResolveFontStyle(style, fallback)
	return flags
end

function addon.functions.ApplyFontStyleShadow(fontString, style, fallback)
	if not (fontString and fontString.SetShadowColor and fontString.SetShadowOffset) then return end
	local _, _, shadowAlpha, shadowX, shadowY = addon.functions.ResolveFontStyle(style, fallback)
	if shadowAlpha and shadowAlpha > 0 then
		fontString:SetShadowColor(0, 0, 0, shadowAlpha)
		fontString:SetShadowOffset(shadowX or 1, shadowY or -1)
	else
		fontString:SetShadowColor(0, 0, 0, 0)
		fontString:SetShadowOffset(0, 0)
	end
end

local function setFontStringFont(fontString, fontFace, size, flags)
	if not (fontString and fontString.SetFont and fontFace) then return false end
	if not isKnownFileAsset(fontFace) then return false end
	local ok, applied = pcall(fontString.SetFont, fontString, fontFace, size, flags)
	return ok and applied ~= false
end

function addon.functions.SetFontWithFallback(fontString, fontFace, size, flags, fallbackFace)
	if not (fontString and fontString.SetFont) then return false end
	local resolvedFallback = addon.functions.ResolveFontFace(fallbackFace, defaultFontFace())
	local resolvedFace = addon.functions.ResolveFontFace(fontFace, resolvedFallback)
	local fontSize = tonumber(size) or 12
	local ok = setFontStringFont(fontString, resolvedFace, fontSize, flags)
	if not ok and resolvedFallback ~= resolvedFace then ok = setFontStringFont(fontString, resolvedFallback, fontSize, flags) end
	return ok
end

function addon.functions.ApplyFontString(fontString, fontFace, size, style, fallbackFace, fallbackStyle)
	if not (fontString and fontString.SetFont) then return false end
	local resolvedFallback = addon.functions.ResolveFontFace(fallbackFace, defaultFontFace())
	local resolvedFace = addon.functions.ResolveFontFace(fontFace, resolvedFallback)
	local fontSize = tonumber(size) or 12
	local _, flags = addon.functions.ResolveFontStyle(style, fallbackStyle)
	local ok = setFontStringFont(fontString, resolvedFace, fontSize, flags)
	if not ok then ok = setFontStringFont(fontString, resolvedFallback, fontSize, flags) end
	addon.functions.ApplyFontStyleShadow(fontString, style, fallbackStyle)
	return ok
end

local PRIVATE_PROFILE_KEYS = {
	autoWarbandGold = true,
	autoWarbandGoldTargetGold = true,
	autoWarbandGoldPerCharacter = true,
	autoWarbandGoldTargetCharacter = true,
	autoWarbandGoldIgnoredCharacters = true,
	autoWarbandGoldWithdraw = true,
	enableMoneyTracker = true,
	showOnlyGoldOnMoney = true,
	moneyTracker = true,
	warbandGold = true,
}

function addon.functions.GetPrivateDB()
	local privateDB = _G.EnhanceQoLDBPrivate
	if type(privateDB) ~= "table" then
		privateDB = {}
		_G.EnhanceQoLDBPrivate = privateDB
	end
	addon.privateDB = privateDB
	return privateDB
end

function addon.functions.InitPrivateDBValue(key, defaultValue)
	local privateDB = addon.functions.GetPrivateDB()
	if privateDB[key] == nil then privateDB[key] = defaultValue end
end

function addon.functions.IsPrivateProfileKey(key) return PRIVATE_PROFILE_KEYS[key] == true end

function addon.functions.MigratePrivateProfileData(sourceProfile)
	if type(sourceProfile) ~= "table" then return end
	local privateDB = addon.functions.GetPrivateDB()
	for key in pairs(PRIVATE_PROFILE_KEYS) do
		if privateDB[key] == nil and sourceProfile[key] ~= nil then privateDB[key] = sourceProfile[key] end
		sourceProfile[key] = nil
	end
end

function addon.functions.CleanupPrivateProfileData()
	local profileDB = _G.EnhanceQoLDB
	if type(profileDB) ~= "table" then return end

	for key in pairs(PRIVATE_PROFILE_KEYS) do
		profileDB[key] = nil
	end

	if type(profileDB.profiles) ~= "table" then return end
	for _, profile in pairs(profileDB.profiles) do
		if type(profile) == "table" then
			for key in pairs(PRIVATE_PROFILE_KEYS) do
				profile[key] = nil
			end
		end
	end
end

local function copyDefaultValue(value, depth)
	depth = (depth or 0) + 1
	if depth > 8 or type(value) ~= "table" then
		return value
	end
	local copy = {}
	for childKey, childValue in pairs(value) do
		copy[childKey] = copyDefaultValue(childValue, depth)
	end
	return copy
end

function addon.functions.InitDBValue(key, defaultValue)
	addon.dbDefaults = addon.dbDefaults or {}
	if addon.dbDefaults[key] == nil and defaultValue ~= nil then addon.dbDefaults[key] = copyDefaultValue(defaultValue) end
	if addon.db[key] == nil then addon.db[key] = defaultValue end
end

function addon.functions.getIDFromGUID(unitId)
	if not unitId then return nil end
	if issecretvalue(unitId) then return nil end
	if type(unitId) ~= "string" then return nil end
	local _, _, _, _, _, npcID = strsplit("-", unitId)
	return tonumber(npcID)
end

-- Global helper: detect Timerunner (Timerunning Season active)
-- Safe-guard for older clients without the API
function addon.functions.IsTimerunner()
	local fn = _G and _G.PlayerGetTimerunningSeasonID
	if type(fn) == "function" then return fn() ~= nil end
	return false
end

local hiddenParent

local function getHiddenParent()
	if hiddenParent then return hiddenParent end
	hiddenParent = CreateFrame("Frame")
	hiddenParent:Hide()
	return hiddenParent
end

local function hideFrameLocked(frame)
	if not frame or frame._eqolHidden then return end

	local function enforceHidden(target)
		if not target then return end
		local canHide = true
		if InCombatLockdown and InCombatLockdown() then
			if target.IsProtected and target:IsProtected() then canHide = false end
		end
		if canHide then
			if target.Hide then pcall(target.Hide, target) end
		elseif target.SetAlpha then
			target:SetAlpha(0)
			target._eqolAlphaHidden = true
		end
	end

	if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
	enforceHidden(frame)
	frame._eqolHidden = true
	if frame.SetParent then pcall(frame.SetParent, frame, getHiddenParent()) end
	if not frame._eqolHiddenHooks then
		frame._eqolHiddenHooks = true
		if frame.Show then hooksecurefunc(frame, "Show", function(f) enforceHidden(f) end) end
		if frame.SetShown then hooksecurefunc(frame, "SetShown", function(f, shown)
			if shown then enforceHidden(f) end
		end) end
	end
end

function addon.functions.toggleRaidTools(value, self)
	if value ~= true then return end
	local manager = self or _G.CompactRaidFrameManager
	hideFrameLocked(manager)
	if CompactRaidFrameManager_SetSetting then pcall(CompactRaidFrameManager_SetSetting, "IsShown", "0") end
end

function addon.functions.updateRaidToolsHook()
	if addon.db and addon.db["hideRaidTools"] then addon.functions.toggleRaidTools(true, _G.CompactRaidFrameManager) end
end

function addon.functions.GetHealthPercent(unit, cur, max, usePredicted, curve)
	if not unit then return 0 end
	curve = curve or (CurveConstants and CurveConstants.ScaleTo100)
	return UnitHealthPercent(unit, usePredicted, curve)
end

function addon.functions.GetPowerPercent(unit, powerType, cur, max, useUnmodified, curve)
	if not unit then return 0 end
	powerType = powerType or 0

	curve = curve or (CurveConstants and CurveConstants.ScaleTo100)
	return UnitPowerPercent(unit, powerType, useUnmodified, curve)
end

local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

function addon.functions.formatMoney(copper, type)
	local COPPER_PER_SILVER = 100
	local COPPER_PER_GOLD = 10000
	local privateDB = addon.functions.GetPrivateDB and addon.functions.GetPrivateDB() or addon.privateDB or {}

	local gold = math.floor(copper / COPPER_PER_GOLD)
	local silver = math.floor((copper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
	local bronze = copper % COPPER_PER_SILVER

	local parts = {}

	if gold > 0 then table.insert(parts, string.format("%s%s", BreakUpLargeNumbers(gold), GOLD_ICON)) end
	if nil == type or (type and type == "tracker" and privateDB["showOnlyGoldOnMoney"] ~= true) then
		if gold > 0 or silver > 0 then table.insert(parts, string.format("%02d%s", silver, SILVER_ICON)) end
		table.insert(parts, string.format("%02d%s", bronze, COPPER_ICON))
	end

	return table.concat(parts, " ")
end

function addon.functions.toggleLandingPageButton(title, state)
	local button = _G["ExpansionLandingPageMinimapButton"] -- Hole den Button
	if not button then return end

	-- Prüfen, ob der Button zu der gewünschten ID passt
	if button.title == title then
		if state then
			button:Hide()
		else
			button:Show()
		end
	end
end

function addon.functions.prepareListForDropdown(tList, sortKey)
	local order = {}
	local sortedList = {}
	-- Tabelle in eine Liste umwandeln
	for key, value in pairs(tList) do
		table.insert(sortedList, { key = key, value = value })
	end
	-- Sortieren nach `value`
	if sortKey then
		table.sort(sortedList, function(a, b) return a.key < b.key end)
	else
		table.sort(sortedList, function(a, b) return a.value < b.value end)
	end
	-- Zurückkonvertieren für SetList
	local dropdownList = {}
	for _, item in ipairs(sortedList) do
		dropdownList[item.key] = item.value
		table.insert(order, item.key)
	end
	return dropdownList, order
end

function addon.functions.getHeightOffset(element)
	local _, _, _, _, headerY = element:GetPoint()
	return headerY - element:GetHeight()
end

local tooltipCache = {}
function addon.functions.clearTooltipCache() wipe(tooltipCache) end

local function getUpgradeTrackKeyFromUpgradeInfo(itemUpgradeInfo)
	if type(itemUpgradeInfo) ~= "table" then return nil end
	return getUpgradeTrackCanonicalKey(itemUpgradeInfo.trackStringID, itemUpgradeInfo.trackString)
end

local function buildItemUpgradeDisplayText(itemUpgradeInfo, trackKey)
	if type(itemUpgradeInfo) ~= "table" or not trackKey then return nil end
	local shortLabel = addon.functions.GetUpgradeTrackAbbreviation(trackKey)
	if not shortLabel then
		local trackString = trimUpgradeTrackText(itemUpgradeInfo.trackString)
		shortLabel = trackString and getFirstUtf8Char(trackString) or nil
	end
	if not shortLabel then return nil end
	local currentLevel = tonumber(itemUpgradeInfo.currentLevel)
	local maxLevel = tonumber(itemUpgradeInfo.maxLevel)
	if currentLevel and maxLevel and currentLevel >= 0 and maxLevel > 0 then return string.format("%s(%d/%d)", shortLabel, currentLevel, maxLevel) end
	return shortLabel
end

local function getItemUpgradeInfo(itemInfo)
	if not itemInfo or not (C_Item and C_Item.GetItemUpgradeInfo) then return nil end
	return C_Item.GetItemUpgradeInfo(itemInfo)
end

function addon.functions.ExtractUpgradeTrackKeyFromTooltipData(data)
	if type(data) == "table" and (data.trackStringID ~= nil or data.trackString ~= nil) then return getUpgradeTrackKeyFromUpgradeInfo(data) end
	return nil
end

function addon.functions.GetUpgradeTrackKeyFromBagSlot(bag, slot)
	if bag == nil or slot == nil then return nil end
	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if not itemLink then return nil end
	return getUpgradeTrackKeyFromUpgradeInfo(getItemUpgradeInfo(itemLink))
end

function addon.functions.GetUpgradeTrackKeyFromItemLink(itemLink)
	if not itemLink then return nil end
	return getUpgradeTrackKeyFromUpgradeInfo(getItemUpgradeInfo(itemLink))
end

function addon.functions.GetItemUpgradeInfoForLink(itemLink)
	if not itemLink then return nil end
	local itemUpgradeInfo = getItemUpgradeInfo(itemLink)
	local trackKey = getUpgradeTrackKeyFromUpgradeInfo(itemUpgradeInfo)
	if not trackKey then return nil end
	return {
		key = trackKey,
		currentLevel = itemUpgradeInfo.currentLevel,
		maxLevel = itemUpgradeInfo.maxLevel,
		maxItemLevel = itemUpgradeInfo.maxItemLevel,
		trackString = trimUpgradeTrackText(itemUpgradeInfo.trackString),
		trackStringID = itemUpgradeInfo.trackStringID,
		label = addon.functions.GetUpgradeTrackLabel(trackKey),
		abbreviation = addon.functions.GetUpgradeTrackAbbreviation(trackKey),
		displayText = buildItemUpgradeDisplayText(itemUpgradeInfo, trackKey),
	}
end

function addon.functions.GetItemUpgradeDisplayText(itemInfo)
	local itemUpgradeInfo = getItemUpgradeInfo(itemInfo)
	local trackKey = getUpgradeTrackKeyFromUpgradeInfo(itemUpgradeInfo)
	return buildItemUpgradeDisplayText(itemUpgradeInfo, trackKey)
end

function addon.functions.GetUpgradeTrackLabel(trackKey)
	local canonical = getUpgradeTrackCanonicalKey(nil, trackKey)
	if not canonical then return nil end
	local info = upgradeTrackMeta[canonical]
	return getUpgradeTrackLabelText(info)
end

function addon.functions.GetUpgradeTrackAbbreviation(trackKey)
	local label = addon.functions.GetUpgradeTrackLabel(trackKey)
	if not label then return nil end
	return getFirstUtf8Char(label)
end

function addon.functions.GetUpgradeTrackColor(trackKey)
	local canonical = getUpgradeTrackCanonicalKey(nil, trackKey)
	if not canonical then return 1, 1, 1, 1 end
	local quality = upgradeTrackMeta[canonical] and upgradeTrackMeta[canonical].quality
	if quality ~= nil then
		local r, g, b = C_Item.GetItemQualityColor(quality)
		if r and g and b then return r, g, b, 1 end
	end
	return 1, 1, 1, 1
end

local function getTooltipInfo(bag, slot, classID, tBindType)
	local key = bag .. "_" .. slot
	local cached = tooltipCache[key]
	if cached then return cached[1], cached[2], cached[3], cached[4] end

	local bType, bKey, upgradeKey, bAuc
	local data = C_TooltipInfo.GetBagItem(bag, slot)
	if data and data.lines then
		upgradeKey = addon.functions.GetUpgradeTrackKeyFromBagSlot(bag, slot)
		for i, v in pairs(data.lines) do
			if v.type == 20 then
				bAuc = true
				if v.leftText == ITEM_BIND_ON_EQUIP then
					bType = "BoE"
					bKey = "boe"
					bAuc = false
				elseif v.leftText == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or v.leftText == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP then
					bType = "WuE"
					bKey = "wue"
				elseif v.leftText == ITEM_ACCOUNTBOUND or v.leftText == ITEM_BIND_TO_BNETACCOUNT then
					bType = "WB"
					bKey = "wb"
				end
			elseif v.type == 0 and v.leftText == ITEM_CONJURED then
				bAuc = true
			end
		end
	end

	-- Check for recipe
	if classID == 9 and (bAuc == true and tBindType == 0) then bAuc = false end

	tooltipCache[key] = { bType, bKey, upgradeKey, bAuc }
	return bType, bKey, upgradeKey, bAuc
end

local function normalizeItemLevelOutline(outline)
	return addon.functions.GetFontFlagsForStyle(outline, FONT_STYLE_OUTLINE)
end

local function getItemLevelFontFace()
	local configured = addon.db and addon.db["ilvlFontFace"]
	return addon.functions.ResolveFontFace(configured, defaultFontFace())
end

local function getItemLevelFontSize()
	local value = tonumber(addon.db and addon.db["ilvlFontSize"])
	if not value then return 14 end
	value = math.floor(value + 0.5)
	if value < 8 then value = 8 end
	if value > 32 then value = 32 end
	return value
end

local function getItemLevelCustomColor()
	local color = addon.db and addon.db["ilvlTextColor"]
	local r = (color and color.r) or 1
	local g = (color and color.g) or 1
	local b = (color and color.b) or 1
	local a = color and color.a
	if a == nil then a = 1 end
	return r, g, b, a
end

local function applyBagUpgradeTrackStyle(fontString)
	if not fontString then return end
	local face = getItemLevelFontFace()
	local style = addon.db and addon.db["ilvlFontOutline"]
	local outline = normalizeItemLevelOutline(style)
	local size = math.max(8, getItemLevelFontSize() - 4)
	local ok = setFontStringFont(fontString, face, size, outline)
	if not ok then setFontStringFont(fontString, addon.variables.defaultFont, size, outline) end
	addon.functions.ApplyFontStyleShadow(fontString, style, FONT_STYLE_OUTLINE)
end

function addon.functions.GetItemLevelTextColor(itemQuality)
	if addon.db and addon.db["ilvlUseItemQualityColor"] ~= false then
		if type(itemQuality) == "number" then
			local r, g, b = C_Item.GetItemQualityColor(itemQuality)
			if r and g and b then return r, g, b, 1 end
		elseif type(itemQuality) == "table" then
			local r = itemQuality.r or itemQuality[1]
			local g = itemQuality.g or itemQuality[2]
			local b = itemQuality.b or itemQuality[3]
			local a = itemQuality.a or itemQuality[4] or 1
			if r and g and b then return r, g, b, a end
		end
	end
	return getItemLevelCustomColor()
end

function addon.functions.ApplyItemLevelTextStyle(fontString)
	if not fontString then return end
	local face = getItemLevelFontFace()
	local size = getItemLevelFontSize()
	local style = addon.db and addon.db["ilvlFontOutline"]
	local outline = normalizeItemLevelOutline(style)
	local ok = setFontStringFont(fontString, face, size, outline)
	if not ok then setFontStringFont(fontString, addon.variables.defaultFont, size, outline) end
	addon.functions.ApplyFontStyleShadow(fontString, style, FONT_STYLE_OUTLINE)
end

function addon.functions.ApplyItemLevelTextColor(fontString, itemQuality)
	if not fontString then return end
	local r, g, b, a = addon.functions.GetItemLevelTextColor(itemQuality)
	fontString:SetTextColor(r, g, b, a or 1)
end

local bagIlvlAnchors = {
	TOPLEFT = { point = "TOPLEFT", x = 2, y = -2 },
	TOP = { point = "TOP", x = 0, y = -2 },
	TOPRIGHT = { point = "TOPRIGHT", x = 0, y = -2 },
	LEFT = { point = "LEFT", x = 2, y = 0 },
	CENTER = { point = "CENTER", x = 0, y = 0 },
	RIGHT = { point = "RIGHT", x = 0, y = 0 },
	BOTTOMLEFT = { point = "BOTTOMLEFT", x = 2, y = 2 },
	BOTTOM = { point = "BOTTOM", x = 0, y = 2 },
	BOTTOMRIGHT = { point = "BOTTOMRIGHT", x = 0, y = 2 },
	OUTSIDE = { point = "TOPLEFT", relativePoint = "TOPRIGHT", x = 2, y = -2 },
}

local bagUpgradeAnchors = {
	TOPLEFT = { point = "TOPLEFT", x = 1, y = -1 },
	TOPRIGHT = { point = "TOPRIGHT", x = -1, y = -1 },
	BOTTOMLEFT = { point = "BOTTOMLEFT", x = 1, y = 1 },
	BOTTOMRIGHT = { point = "BOTTOMRIGHT", x = -1, y = 1 },
}

local UPGRADE_ICON_PATH = "Interface\\AddOns\\EnhanceQoL\\Icons\\upgradeilvl.tga"
local UPGRADE_ICON_SIZE = 22
local UPGRADE_ICON_GLOW_SIZE = 24

function addon.functions.ApplyBagItemLevelPosition(target, anchorFrame, position)
	if not target or not anchorFrame then return end
	local anchor = bagIlvlAnchors[position] or bagIlvlAnchors.TOPRIGHT
	local relativePoint = anchor.relativePoint or anchor.point
	target:ClearAllPoints()
	target:SetPoint(anchor.point, anchorFrame, relativePoint, anchor.x, anchor.y)
end

function addon.functions.ApplyBagUpgradeTrackPosition(target, anchorFrame, position)
	if not target or not anchorFrame then return end
	addon.functions.ApplyBagItemLevelPosition(target, anchorFrame, position or "OUTSIDE")
end

local function resolveBoundAnchor(position)
	if position == "BOTTOMLEFT" then
		return "TOPLEFT"
	elseif position == "BOTTOMRIGHT" then
		return "TOPRIGHT"
	elseif position == "BOTTOM" then
		return "TOP"
	elseif position == "LEFT" then
		return "TOPRIGHT"
	elseif position == "TOPLEFT" or position == "TOPRIGHT" or position == "TOP" then
		return "BOTTOMLEFT"
	elseif position == "RIGHT" then
		return "BOTTOMLEFT"
	else
		return "BOTTOMLEFT"
	end
end

function addon.functions.ApplyBagBoundPosition(target, anchorFrame, position)
	if not target or not anchorFrame then return end
	local anchor = bagIlvlAnchors[resolveBoundAnchor(position)] or bagIlvlAnchors.BOTTOMLEFT
	target:ClearAllPoints()
	target:SetPoint(anchor.point, anchorFrame, anchor.point, anchor.x, anchor.y)
end

function addon.functions.ApplyBagUpgradeIconPosition(target, anchorFrame, position)
	if not target or not anchorFrame then return end
	local anchor = bagUpgradeAnchors[position] or bagUpgradeAnchors.BOTTOMRIGHT
	target:ClearAllPoints()
	target:SetPoint(anchor.point, anchorFrame, anchor.point, anchor.x, anchor.y)
end

function addon.functions.AlignUpgradeIconGlow(glow, icon)
	if not glow or not icon then return end
	glow:ClearAllPoints()
	glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
end

function addon.functions.EnsureBagUpgradeIcon(button)
	if not button then return end
	if not button.ItemUpgradeIcon then
		button.ItemUpgradeIcon = button:CreateTexture(nil, "ARTWORK")
		button.ItemUpgradeIcon:SetDrawLayer("ARTWORK", 2)
	end
	if not button.ItemUpgradeIconGlow then
		button.ItemUpgradeIconGlow = button:CreateTexture(nil, "ARTWORK")
		button.ItemUpgradeIconGlow:SetDrawLayer("ARTWORK", 1)
	end
	button.ItemUpgradeIcon:SetTexture(UPGRADE_ICON_PATH)
	button.ItemUpgradeIcon:SetSize(UPGRADE_ICON_SIZE, UPGRADE_ICON_SIZE)
	button.ItemUpgradeIcon:SetVertexColor(0, 1, 0, 1)
	button.ItemUpgradeIconGlow:SetTexture(UPGRADE_ICON_PATH)
	button.ItemUpgradeIconGlow:SetSize(UPGRADE_ICON_GLOW_SIZE, UPGRADE_ICON_GLOW_SIZE)
	button.ItemUpgradeIconGlow:SetVertexColor(0, 0, 0, 0.9)
end

local function getEquipSlotsFor(equipLoc)
	if equipLoc == "INVTYPE_FINGER" then
		return { 11, 12 }
	elseif equipLoc == "INVTYPE_TRINKET" then
		return { 13, 14 }
	elseif equipLoc == "INVTYPE_HEAD" then
		return { 1 }
	elseif equipLoc == "INVTYPE_NECK" then
		return { 2 }
	elseif equipLoc == "INVTYPE_SHOULDER" then
		return { 3 }
	elseif equipLoc == "INVTYPE_CLOAK" then
		return { 15 }
	elseif equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE" then
		return { 5 }
	elseif equipLoc == "INVTYPE_WRIST" then
		return { 9 }
	elseif equipLoc == "INVTYPE_HAND" then
		return { 10 }
	elseif equipLoc == "INVTYPE_WAIST" then
		return { 6 }
	elseif equipLoc == "INVTYPE_LEGS" then
		return { 7 }
	elseif equipLoc == "INVTYPE_FEET" then
		return { 8 }
	elseif equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" then
		return { 16 }
	elseif equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_SHIELD" then
		return { 17 }
	elseif equipLoc == "INVTYPE_WEAPON" then
		-- One-hand weapon: compare against both if present
		return { 16, 17 }
	end
	return nil
end

local cachedUnitClass, cachedUnitSpec, cachedSpecFilters
local function getCurrentSpecFilters()
	local unitClass = addon.variables.unitClass
	local unitSpec = addon.variables.unitSpec
	if not unitClass or not unitSpec then
		cachedUnitClass, cachedUnitSpec, cachedSpecFilters = nil, nil, nil
		return nil
	end
	if unitClass ~= cachedUnitClass or unitSpec ~= cachedUnitSpec then
		cachedUnitClass, cachedUnitSpec = unitClass, unitSpec
		local classFilters = addon.itemBagFilterTypes and addon.itemBagFilterTypes[unitClass]
		cachedSpecFilters = classFilters and classFilters[unitSpec] or nil
	end
	return cachedSpecFilters
end

function addon.functions.IsItemRecommendedForSpec(itemLink, itemEquipLoc, classID, subclassID)
	if not itemLink then return false end
	if not IsEquippableItemFn(itemLink) then return false end

	if itemEquipLoc == nil or classID == nil or subclassID == nil then
		local _, _, _, equipLoc, _, instantClassID, instantSubclassID = GetItemInfoInstantFn(itemLink)
		itemEquipLoc = itemEquipLoc or equipLoc
		if classID == nil then classID = instantClassID end
		if subclassID == nil then subclassID = instantSubclassID end
	end

	if not itemEquipLoc or classID == nil or subclassID == nil then return false end
	if itemEquipLoc == "INVTYPE_TABARD" then return false end
	if itemEquipLoc == "INVTYPE_CLOAK" then return true end

	local specFilters = getCurrentSpecFilters()
	if not specFilters then return false end
	local classEntry = specFilters[classID]
	local value = classEntry and classEntry[subclassID]
	return value ~= nil and value ~= false
end

local function isBagItemUpgrade(itemLink, itemEquipLoc, itemLevel)
	if not itemLink or not itemEquipLoc then return false end
	local slots = getEquipSlotsFor(itemEquipLoc)
	if not slots or #slots == 0 then return false end

	local itemLevelText = itemLevel
	if itemLevelText == nil then itemLevelText = C_Item.GetDetailedItemLevelInfo(itemLink) end
	local numericLevel = tonumber(itemLevelText)
	if not numericLevel then return false end

	local baseline
	for _, invSlot in ipairs(slots) do
		local link = GetInventoryItemLink("player", invSlot)
		local eqIlvl = link and (C_Item.GetDetailedItemLevelInfo(link) or 0) or 0
		if baseline == nil then
			baseline = eqIlvl
		else
			baseline = math.min(baseline, eqIlvl) -- favor upgrade vs the worse of two (rings/trinkets/1H weapons)
		end
	end

	if baseline == nil then return false end
	return numericLevel > baseline
end

function addon.functions.IsBagItemUpgrade(itemLink, itemEquipLoc, itemLevel) return isBagItemUpgrade(itemLink, itemEquipLoc, itemLevel) end

local function updateBagRarityGlow(itemButton, itemQuality, dimmed)
	if not itemButton then return end
	if not addon.db or addon.db["enhancedRarityGlow"] ~= true then
		if itemButton.EQOLRarityGlow then itemButton.EQOLRarityGlow:Hide() end
		return
	end
	if not itemQuality or itemQuality < 2 then
		if itemButton.EQOLRarityGlow then itemButton.EQOLRarityGlow:Hide() end
		return
	end
	local glow = itemButton.EQOLRarityGlow
	if not glow then
		glow = itemButton:CreateTexture(nil, "BORDER")
		glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		glow:SetBlendMode("ADD")
		glow:SetPoint("CENTER", itemButton, "CENTER", 0, 0)
		itemButton.EQOLRarityGlow = glow
	end
	local w, h = itemButton:GetSize()
	if w and h and w > 0 and h > 0 then
		glow:SetSize(w + 20, h + 20)
	else
		glow:SetSize(64, 64)
	end
	local r, g, b = C_Item.GetItemQualityColor(itemQuality)
	glow:SetVertexColor(r, g, b)
	glow:SetAlpha(dimmed and 0.1 or 0.9)
	glow:Show()
end

local function clearBagButtonInfo(itemButton)
	if not itemButton then return end
	itemButton:SetAlpha(1)
	if itemButton.EQOLFilterOverlay then
		itemButton.EQOLFilterOverlay:SetAlpha(1)
		itemButton.EQOLFilterOverlay:Hide()
	end
	if itemButton.ItemLevelText then
		itemButton.ItemLevelText:SetAlpha(1)
		itemButton.ItemLevelText:Hide()
	end
	if itemButton.ItemBoundType then
		itemButton.ItemBoundType:SetAlpha(1)
		itemButton.ItemBoundType:Hide()
	end
	if itemButton.ItemUpgradeTrackText then
		itemButton.ItemUpgradeTrackText:SetAlpha(1)
		itemButton.ItemUpgradeTrackText:Hide()
	end
	if itemButton.ItemUpgradeArrow then
		itemButton.ItemUpgradeArrow:SetAlpha(1)
		itemButton.ItemUpgradeArrow:Hide()
	end
	if itemButton.ItemUpgradeIcon then
		itemButton.ItemUpgradeIcon:SetAlpha(1)
		itemButton.ItemUpgradeIcon:Hide()
	end
	if itemButton.ItemUpgradeIconGlow then
		itemButton.ItemUpgradeIconGlow:SetAlpha(1)
		itemButton.ItemUpgradeIconGlow:Hide()
	end
	if itemButton.ProfessionQualityOverlay and addon.db and addon.db["fadeBagQualityIcons"] then itemButton.ProfessionQualityOverlay:SetAlpha(1) end
	updateBagRarityGlow(itemButton, nil, false)
end

local function shouldUpdateBagButtonInfo()
	if addon.functions.IsBagsModuleActive() then return false end
	if addon.filterFrame then return true end
	if not addon.db then return false end
	return addon.db["showIlvlOnBagItems"] or addon.db["showBindOnBagItems"] or addon.db["showUpgradeArrowOnBagItems"] or addon.db["showUpgradeTrackOnBagItems"] or addon.db["enhancedRarityGlow"]
end

local function updateButtonInfo(itemButton, bag, slot, frameName)
	itemButton:SetAlpha(1)
	if itemButton.EQOLFilterOverlay then
		itemButton.EQOLFilterOverlay:SetAlpha(1)
		itemButton.EQOLFilterOverlay:Hide()
	end

	if itemButton.ItemLevelText then
		itemButton.ItemLevelText:SetAlpha(1)
		itemButton.ItemLevelText:Hide()
	end
	if itemButton.ItemBoundType then
		itemButton.ItemBoundType:SetAlpha(1)
		itemButton.ItemBoundType:SetText("")
	end
	if itemButton.ItemUpgradeTrackText then
		itemButton.ItemUpgradeTrackText:SetAlpha(1)
		itemButton.ItemUpgradeTrackText:SetText("")
		itemButton.ItemUpgradeTrackText:Hide()
	end
	-- Reset upgrade marker each update to avoid stale icons when buttons are recycled
	if itemButton.ItemUpgradeArrow then
		itemButton.ItemUpgradeArrow:SetAlpha(1)
		itemButton.ItemUpgradeArrow:Hide()
	end
	if itemButton.ItemUpgradeIcon then
		itemButton.ItemUpgradeIcon:SetAlpha(1)
		itemButton.ItemUpgradeIcon:Hide()
	end
	if itemButton.ItemUpgradeIconGlow then
		itemButton.ItemUpgradeIconGlow:SetAlpha(1)
		itemButton.ItemUpgradeIconGlow:Hide()
	end
	local isBankFrame = frameName == "BankPanel" or frameName == "BankFrame"
	local showItemLevel = isBankFrame and addon.db["showIlvlOnBankFrame"] or addon.db["showIlvlOnBagItems"]
	local itemLink = C_Container.GetContainerItemLink(bag, slot)
	if itemLink then
		local _, _, itemQuality, _, _, _, _, _, itemEquipLoc, _, sellPrice, classID, subclassID, tBindType, expId = GetItemInfoFn(itemLink)
		if itemQuality == nil and GetContainerItemInfo then
			local containerInfo = GetContainerItemInfo(bag, slot)
			if containerInfo and containerInfo.quality ~= nil then itemQuality = containerInfo.quality end
		end

		local bType, bKey, upgradeKey, bAuc
		local data
		if
			addon.db["showBindOnBagItems"]
			or addon.db["showUpgradeTrackOnBagItems"]
			or addon.itemBagFilters["bind"]
			or addon.itemBagFilters["upgrade"]
			or addon.itemBagFilters["misc_auctionhouse_sellable"]
		then
			bType, bKey, upgradeKey, bAuc = getTooltipInfo(bag, slot, classID, tBindType)
		end
		local setVisibility
		local isUpgrade = nil
		local isRecommended = nil

		if addon.filterFrame then
			if classID == 15 and subclassID == 0 then bAuc = true end -- ignore lockboxes etc.
			if not itemButton.matchesSearch then setVisibility = true end
			if addon.filterFrame:IsVisible() then
				if addon.itemBagFilters["rarity"] then
					if nil == addon.itemBagFiltersQuality[itemQuality] or addon.itemBagFiltersQuality[itemQuality] == false then setVisibility = true end
				end
				local cilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
				if addon.itemBagFilters["minLevel"] and (not cilvl or cilvl < addon.itemBagFilters["minLevel"] or (nil == itemEquipLoc or addon.variables.ignoredEquipmentTypes[itemEquipLoc])) then
					setVisibility = true
				end
				if addon.itemBagFilters["maxLevel"] and (not cilvl or cilvl > addon.itemBagFilters["maxLevel"] or (nil == itemEquipLoc or addon.variables.ignoredEquipmentTypes[itemEquipLoc])) then
					setVisibility = true
				end
				if addon.itemBagFilters["currentExpension"] and LE_EXPANSION_LEVEL_CURRENT ~= expId then setVisibility = true end
				if addon.itemBagFilters["equipment"] and (nil == itemEquipLoc or addon.variables.ignoredEquipmentTypes[itemEquipLoc]) then setVisibility = true end
				if addon.itemBagFilters["upgradeOnly"] then
					if isRecommended == nil then isRecommended = addon.functions.IsItemRecommendedForSpec(itemLink, itemEquipLoc, classID, subclassID) end
					if not isRecommended then
						setVisibility = true
					else
						if isUpgrade == nil then isUpgrade = isBagItemUpgrade(itemLink, itemEquipLoc) end
						if not isUpgrade then setVisibility = true end
					end
				end
				if addon.itemBagFilters["bind"] then
					if nil == addon.itemBagFiltersBound[bKey] or addon.itemBagFiltersBound[bKey] == false then setVisibility = true end
				end
				if addon.itemBagFilters["misc_auctionhouse_sellable"] then
					if bAuc then setVisibility = true end
				end
				if addon.itemBagFilters["upgrade"] then
					if nil == addon.itemBagFiltersUpgrade[upgradeKey] or addon.itemBagFiltersUpgrade[upgradeKey] == false then setVisibility = true end
				end
				if addon.itemBagFilters["misc_sellable"] then
					if addon.itemBagFilters["misc_sellable"] == true and (not sellPrice or sellPrice == 0) then setVisibility = true end
				end
				if
					addon.itemBagFilters["usableOnly"]
					and (
						IsEquippableItemFn(itemLink) == false
						or (
							(
								nil == addon.itemBagFilterTypes[addon.variables.unitClass]
								or nil == addon.itemBagFilterTypes[addon.variables.unitClass][addon.variables.unitSpec]
								or nil == addon.itemBagFilterTypes[addon.variables.unitClass][addon.variables.unitSpec][classID]
								or nil == addon.itemBagFilterTypes[addon.variables.unitClass][addon.variables.unitSpec][classID][subclassID]
								or itemEquipLoc == "INVTYPE_TABARD" -- ignore Tabards
							) and itemEquipLoc ~= "INVTYPE_CLOAK" -- ignore Cloaks
						)
					)
				then
					setVisibility = true
				end
			end
		end

		if
			(itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" or (classID == 4 and subclassID == 0)) and not (classID == 4 and subclassID == 5) -- Cosmetic
		then
			if not itemButton.OverlayFilter then itemButton.OverlayFilter = itemButton:CreateFontString(nil, "ARTWORK") end
			if not itemButton.ItemLevelText then
				-- Create behind Blizzard's search overlay so it fades automatically
				itemButton.ItemLevelText = itemButton:CreateFontString(nil, "ARTWORK")
				itemButton.ItemLevelText:SetDrawLayer("ARTWORK", 1)
				itemButton.ItemLevelText:SetFont(addon.variables.defaultFont, 13, "OUTLINE")
				itemButton.ItemLevelText:SetShadowOffset(2, -2)
				itemButton.ItemLevelText:SetShadowColor(0, 0, 0, 1)
			end
			addon.functions.ApplyItemLevelTextStyle(itemButton.ItemLevelText)

			itemButton.ItemLevelText:ClearAllPoints()
			local pos = addon.db["bagIlvlPosition"] or "TOPRIGHT"
			addon.functions.ApplyBagItemLevelPosition(itemButton.ItemLevelText, itemButton, pos)
			if nil ~= addon.variables.allowedEquipSlotsBagIlvl[itemEquipLoc] then
				local itemLevelText = C_Item.GetCurrentItemLevel(ItemLocation:CreateFromBagAndSlot(bag, slot))

				itemButton.ItemLevelText:SetFormattedText(itemLevelText)
				addon.functions.ApplyItemLevelTextColor(itemButton.ItemLevelText, itemQuality)

				if showItemLevel then
					itemButton.ItemLevelText:Show()
				else
					itemButton.ItemLevelText:Hide()
				end

				if addon.db["showUpgradeTrackOnBagItems"] and upgradeKey then
					if not itemButton.ItemUpgradeTrackText then
						itemButton.ItemUpgradeTrackText = itemButton:CreateFontString(nil, "ARTWORK")
						itemButton.ItemUpgradeTrackText:SetDrawLayer("ARTWORK", 1)
					end
					applyBagUpgradeTrackStyle(itemButton.ItemUpgradeTrackText)
					addon.functions.ApplyBagUpgradeTrackPosition(itemButton.ItemUpgradeTrackText, itemButton, addon.db["bagTrackPosition"])
					itemButton.ItemUpgradeTrackText:SetText(addon.functions.GetItemUpgradeDisplayText(itemLink) or addon.functions.GetUpgradeTrackAbbreviation(upgradeKey) or "")
					itemButton.ItemUpgradeTrackText:SetTextColor(addon.functions.GetUpgradeTrackColor(upgradeKey))
					itemButton.ItemUpgradeTrackText:Show()
				elseif itemButton.ItemUpgradeTrackText then
					itemButton.ItemUpgradeTrackText:Hide()
				end

				-- Upgrade arrow (bag): indicate if this item is higher ilvl than equipped
				if addon.db["showUpgradeArrowOnBagItems"] then
					if isRecommended == nil then isRecommended = addon.functions.IsItemRecommendedForSpec(itemLink, itemEquipLoc, classID, subclassID) end
					if isRecommended and isUpgrade == nil then isUpgrade = isBagItemUpgrade(itemLink, itemEquipLoc, itemLevelText) end
					if isRecommended and isUpgrade then
						addon.functions.EnsureBagUpgradeIcon(itemButton)
						local posUp = addon.db["bagUpgradeIconPosition"] or "BOTTOMRIGHT"
						addon.functions.ApplyBagUpgradeIconPosition(itemButton.ItemUpgradeIcon, itemButton, posUp)
						addon.functions.AlignUpgradeIconGlow(itemButton.ItemUpgradeIconGlow, itemButton.ItemUpgradeIcon)
						itemButton.ItemUpgradeIconGlow:Show()
						itemButton.ItemUpgradeIcon:Show()
					else
						if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:Hide() end
						if itemButton.ItemUpgradeIconGlow then itemButton.ItemUpgradeIconGlow:Hide() end
					end
				else
					if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:Hide() end
					if itemButton.ItemUpgradeIconGlow then itemButton.ItemUpgradeIconGlow:Hide() end
				end

				if addon.db["showBindOnBagItems"] and bType then
					if not itemButton.ItemBoundType then
						-- Position behind Blizzard's overlay
						itemButton.ItemBoundType = itemButton:CreateFontString(nil, "ARTWORK")
						itemButton.ItemBoundType:SetDrawLayer("ARTWORK", 1)
						itemButton.ItemBoundType:SetFont(addon.variables.defaultFont, 10, "OUTLINE")
						itemButton.ItemBoundType:SetShadowOffset(2, 2)
						itemButton.ItemBoundType:SetShadowColor(0, 0, 0, 1)
					end

					itemButton.ItemBoundType:ClearAllPoints()
					addon.functions.ApplyBagBoundPosition(itemButton.ItemBoundType, itemButton, addon.db["bagIlvlPosition"])
					itemButton.ItemBoundType:SetFormattedText(bType)
					itemButton.ItemBoundType:Show()
				elseif itemButton.ItemBoundType then
					itemButton.ItemBoundType:Hide()
				end
			elseif itemButton.ItemLevelText then
				if itemButton.ItemBoundType then itemButton.ItemBoundType:Hide() end
				if itemButton.ItemUpgradeTrackText then itemButton.ItemUpgradeTrackText:Hide() end
				if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:Hide() end
				itemButton.ItemLevelText:Hide()
			end
		end

		if setVisibility then
			itemButton:SetAlpha(0.1)
			if not itemButton.EQOLFilterOverlay then
				itemButton.EQOLFilterOverlay = itemButton:CreateTexture(nil, "ARTWORK")
				itemButton.EQOLFilterOverlay:SetColorTexture(0, 0, 0, 0.8)
				itemButton.EQOLFilterOverlay:SetAllPoints()
			end
			itemButton.EQOLFilterOverlay:Show()

			if itemButton.ItemLevelText then itemButton.ItemLevelText:SetAlpha(0.1) end
			if itemButton.ItemBoundType then itemButton.ItemBoundType:SetAlpha(0.1) end
			if itemButton.ItemUpgradeTrackText then itemButton.ItemUpgradeTrackText:SetAlpha(0.1) end
			if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:SetAlpha(0.1) end
			if itemButton.ProfessionQualityOverlay and addon.db["fadeBagQualityIcons"] then itemButton.ProfessionQualityOverlay:SetAlpha(0.1) end
		else
			itemButton:SetAlpha(1)
			if itemButton.EQOLFilterOverlay then itemButton.EQOLFilterOverlay:Hide() end
			if itemButton.ItemLevelText then itemButton.ItemLevelText:SetAlpha(1) end
			if itemButton.ItemBoundType then itemButton.ItemBoundType:SetAlpha(1) end
			if itemButton.ItemUpgradeTrackText then itemButton.ItemUpgradeTrackText:SetAlpha(1) end
			if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:SetAlpha(1) end
			if itemButton.ProfessionQualityOverlay and addon.db["fadeBagQualityIcons"] then itemButton.ProfessionQualityOverlay:SetAlpha(1) end
		end
		updateBagRarityGlow(itemButton, itemQuality, setVisibility == true)
		-- end)
	else
		if itemButton.ItemBoundType then itemButton.ItemBoundType:Hide() end
		if itemButton.ItemUpgradeTrackText then itemButton.ItemUpgradeTrackText:Hide() end
		if itemButton.ItemUpgradeIcon then itemButton.ItemUpgradeIcon:Hide() end
		if itemButton.ItemLevelText then itemButton.ItemLevelText:Hide() end
		updateBagRarityGlow(itemButton, nil, false)
	end
end

function addon.functions.updateBank(itemButton, bag, slot) updateButtonInfo(itemButton, bag, slot, "BankFrame") end

local filterData = {
	{
		label = BAG_FILTER_EQUIPMENT,
		child = {
			{ type = "CheckBox", key = "equipment", label = L["bagFilterEquip"] },
			{ type = "CheckBox", key = "upgradeOnly", label = L["bagFilterUpgradeOnly"] },
			{ type = "CheckBox", key = "usableOnly", label = L["bagFilterSpec"] },
		},
	},
	{
		label = AUCTION_HOUSE_FILTER_DROP_DOWN_LEVEL_RANGE,
		child = {
			{ type = "EditBox", key = "minLevel", label = MINIMUM },
			{ type = "EditBox", key = "maxLevel", label = MAXIMUM },
		},
		ignoreSort = true,
	},
	{
		label = EXPANSION_FILTER_TEXT,
		child = {
			{ type = "CheckBox", key = "currentExpension", label = REFORGE_CURRENT, tooltip = L["currentExpensionMythicPlusWarning"] },
		},
	},
	{
		label = L["bagFilterBindType"],
		child = {
			{ type = "CheckBox", key = "boe", label = ITEM_BIND_ON_EQUIP, bFilter = "boe" },
			{ type = "CheckBox", key = "wue", label = ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP, bFilter = "wue" },
			{ type = "CheckBox", key = "wb", label = ITEM_BIND_TO_ACCOUNT, bFilter = "wb" },
		},
	},
	{
		label = L["bagFilterUpgradeLevel"],
		child = {
			{ type = "CheckBox", key = "upgrade_explorer", label = "Explorer", uFilter = "explorer" },
			{ type = "CheckBox", key = "upgrade_adventurer", label = "Adventurer", uFilter = "adventurer" },
			{ type = "CheckBox", key = "upgrade_veteran", label = L["upgradeLevelVeteran"], uFilter = "veteran" },
			{ type = "CheckBox", key = "upgrade_champion", label = L["upgradeLevelChampion"], uFilter = "champion" },
			{ type = "CheckBox", key = "upgrade_hero", label = L["upgradeLevelHero"], uFilter = "hero" },
			{ type = "CheckBox", key = "upgrade_mythic", label = L["upgradeLevelMythic"], uFilter = "myth" },
		},
	},
	{
		label = RARITY,
		child = {
			{ type = "CheckBox", key = "poor", label = "|cff9d9d9d" .. ITEM_QUALITY0_DESC, qFilter = 0 },
			{ type = "CheckBox", key = "common", label = "|cffffffff" .. ITEM_QUALITY1_DESC, qFilter = 1 },
			{ type = "CheckBox", key = "uncommon", label = "|cff1eff00" .. ITEM_QUALITY2_DESC, qFilter = 2 },
			{ type = "CheckBox", key = "rare", label = "|cff0070dd" .. ITEM_QUALITY3_DESC, qFilter = 3 },
			{ type = "CheckBox", key = "epic", label = "|cffa335ee" .. ITEM_QUALITY4_DESC, qFilter = 4 },
			{ type = "CheckBox", key = "legendary", label = "|cffff8000" .. ITEM_QUALITY5_DESC, qFilter = 5 },
			{ type = "CheckBox", key = "artifact", label = "|cffe6cc80" .. ITEM_QUALITY6_DESC, qFilter = 6 },
			{ type = "CheckBox", key = "heirloom", label = "|cff00ccff" .. ITEM_QUALITY7_DESC, qFilter = 7 },
		},
	},
	{
		label = HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_MISC,
		child = {
			{ type = "CheckBox", key = "misc_sellable", label = L["misc_sellable"] },
			{ type = "CheckBox", key = "misc_auctionhouse_sellable", label = L["misc_auctionhouse_sellable"] },
		},
	},
}
table.sort(filterData, function(a, b)
	if a.ignoreSort and not b.ignoreSort then return true end
	if b.ignoreSort and not a.ignoreSort then return false end
	return a.label < b.label
end)

local function checkActiveQualityFilter()
	for _, value in pairs(addon.itemBagFiltersQuality) do
		if value == true then
			addon.itemBagFilters["rarity"] = true
			return
		end
	end
	addon.itemBagFilters["rarity"] = false
end

local function checkActiveBindFilter()
	for _, value in pairs(addon.itemBagFiltersBound) do
		if value == true then
			addon.itemBagFilters["bind"] = true
			return
		end
	end
	addon.itemBagFilters["bind"] = false
end

local function checkActiveUpgradeFilter()
	for _, value in pairs(addon.itemBagFiltersUpgrade) do
		if value == true then
			addon.itemBagFilters["upgrade"] = true
			return
		end
	end
	addon.itemBagFilters["upgrade"] = false
end

local function CreateFilterMenu()
	local frame = CreateFrame("Frame", "InventoryFilterPanel", ContainerFrameCombinedBags, "BackdropTemplate")
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:Hide() -- Standardmäßig ausblenden
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if addon.db["bagFilterDockFrame"] then return end
		if not IsShiftKeyDown() then return end
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		-- Position speichern
		local point, _, parentPoint, xOfs, yOfs = self:GetPoint()
		addon.db["bagFilterFrameData"].point = point
		addon.db["bagFilterFrameData"].parentPoint = parentPoint
		addon.db["bagFilterFrameData"].x = xOfs
		addon.db["bagFilterFrameData"].y = yOfs
	end)
	if
		not addon.db["bagFilterDockFrame"]
		and addon.db["bagFilterFrameData"].point
		and addon.db["bagFilterFrameData"].parentPoint
		and addon.db["bagFilterFrameData"].x
		and addon.db["bagFilterFrameData"].y
	then
		frame:SetPoint(addon.db["bagFilterFrameData"].point, UIParent, addon.db["bagFilterFrameData"].parentPoint, addon.db["bagFilterFrameData"].x, addon.db["bagFilterFrameData"].y)
	else
		frame:SetPoint("TOPRIGHT", ContainerFrameCombinedBags, "TOPLEFT", -10, 0)
	end

	local scrollFrame = CreateFrame("ScrollFrame", "InventoryFilterPanelScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 10)
	local scrollContainer = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollContainer)
	scrollContainer:SetPoint("TOPLEFT")
	scrollContainer:SetSize(220, 1)
	scrollFrame:Show()
	frame.widgets = {}

	local function AnyFilterActive()
		for _, v in pairs(addon.itemBagFilters) do
			if v then return true end
		end
		for _, tbl in ipairs({ addon.itemBagFiltersQuality, addon.itemBagFiltersBound, addon.itemBagFiltersUpgrade }) do
			for _, v in pairs(tbl) do
				if v then return true end
			end
		end
		return false
	end

	local function UpdateResetButton()
		if frame.btnReset then
			if AnyFilterActive() then
				frame.btnReset:Show()
			else
				frame.btnReset:Hide()
			end
		end
	end

	local longestWidth = 200
	local math_max = math.max
	local yOffset = 0
	local rowHeight = 24
	local rowGap = 4
	local rowInset = 6

	local function refreshBags()
		addon.functions.updateBags(ContainerFrameCombinedBags)
		for _, bagFrame in ipairs(ContainerFrameContainer.ContainerFrames) do
			addon.functions.updateBags(bagFrame)
		end
		if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end
	end

	local function addRow(widget, height, xOffset)
		height = height or rowHeight
		xOffset = xOffset or rowInset
		widget:SetParent(scrollContainer)
		widget:ClearAllPoints()
		widget:SetPoint("TOPLEFT", scrollContainer, "TOPLEFT", xOffset, -yOffset)
		yOffset = yOffset + height + rowGap
		scrollContainer:SetHeight(math.max(1, yOffset))
		return widget
	end

	-- Dynamisch die UI-Elemente aus `filterData` erstellen
	for _, section in ipairs(filterData) do
		-- Überschrift für jede Sektion
		local label = scrollContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		label:SetText("|cffffd100" .. section.label .. "|r") -- Goldene Überschrift
		label:SetFont(addon.variables.defaultFont, 12, "OUTLINE")
		label:SetJustifyH("LEFT")
		label:SetSize(220, 18)
		addRow(label, 18)

		longestWidth = math_max(label:GetStringWidth(), longestWidth)

		-- Füge die Kind-Elemente hinzu
		for _, item in ipairs(section.child) do
			local widget

			if item.type == "CheckBox" then
				widget = CreateFrame("CheckButton", nil, scrollContainer, "UICheckButtonTemplate")
				widget:SetSize(22, 22)
				widget.text = widget.Text or widget:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				widget.text:SetPoint("LEFT", widget, "RIGHT", 2, 0)
				widget.text:SetText(item.label)
				widget:SetChecked(addon.itemBagFilters[item.key] == true)
				widget.SetValue = widget.SetChecked
				widget:SetScript("OnClick", function(self)
					local value = self:GetChecked() == true
					addon.itemBagFilters[item.key] = value
					if item.qFilter then
						addon.itemBagFiltersQuality[item.qFilter] = value
						checkActiveQualityFilter()
					end
					if item.bFilter then
						addon.itemBagFiltersBound[item.bFilter] = value
						checkActiveBindFilter()
					end
					if item.uFilter then
						addon.itemBagFiltersUpgrade[item.uFilter] = value
						checkActiveUpgradeFilter()
					end
					refreshBags()
					UpdateResetButton()
				end)
				if item.tooltip then
					widget:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:ClearLines()
						GameTooltip:AddLine(item.tooltip)
						GameTooltip:Show()
					end)
					widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
				end
			elseif item.type == "EditBox" then
				-- separate label so it aligns nicely above half‑width boxes
				local eLabel = scrollContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				eLabel:SetText(item.label)
				eLabel:SetJustifyH("LEFT")
				eLabel:SetSize(220, 16)
				addRow(eLabel, 16)
				widget = CreateFrame("EditBox", nil, scrollContainer, "InputBoxTemplate")
				widget:SetSize(70, 22)
				widget:SetAutoFocus(false)
				widget:SetText(addon.itemBagFilters[item.key] or "")

				widget:SetScript("OnTextChanged", function(self)
					local text = self:GetText() or ""
					local caret = self:GetCursorPosition()
					local numeric = text:gsub("%D", "")
					if numeric ~= text then
						self:SetText(numeric)
						local newPos = math.max(0, caret - (text:len() - numeric:len()))
						self:SetCursorPosition(newPos)
					end
				end)

				widget:SetScript("OnEnterPressed", function(self)
					addon.itemBagFilters[item.key] = tonumber(self:GetText())
					refreshBags()
					UpdateResetButton()
					self:ClearFocus()
				end)
			end

			if widget then
				addRow(widget, rowHeight, item.type == "EditBox" and 10 or nil)
				table.insert(frame.widgets, widget)
				if widget.text and widget.text.GetStringWidth then longestWidth = math_max(widget.text:GetStringWidth(), longestWidth) end
			end
		end
	end
	scrollContainer:SetWidth(longestWidth + 30)
	frame:SetSize(longestWidth + 70, 280) -- Feste Größe

	local btnDock = CreateFrame("Button", "InventoryFilterPanelDock", frame)
	btnDock:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -5)
	btnDock:SetText("Dock")
	btnDock.isDocked = addon.db["bagFilterDockFrame"]
	btnDock:SetScript("OnClick", function(self)
		self.isDocked = not self.isDocked
		addon.db["bagFilterDockFrame"] = self.isDocked
		if self.isDocked then
			frame:ClearAllPoints()
			frame:SetPoint("TOPRIGHT", ContainerFrameCombinedBags, "TOPLEFT", -10, 0)
			self.icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\ClosedLock.tga")
		else
			self.icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\OpenLock.tga")
		end
	end)
	btnDock:SetSize(16, 16)
	btnDock:Show()

	local icon = btnDock:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(btnDock)
	if addon.db["bagFilterDockFrame"] then
		icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\ClosedLock.tga")
	else
		icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\OpenLock.tga")
	end
	btnDock.icon = icon
	-- Tooltip: zeigt dem Spieler, was der Button macht
	btnDock:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.isDocked then
			GameTooltip:SetText(L["bagFilterDockFrameUnlock"])
		else
			GameTooltip:SetText(L["bagFilterDockFrameLock"])
		end
		GameTooltip:Show()
	end)
	btnDock:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local btnReset = CreateFrame("Button", "InventoryFilterPanelReset", frame)
	btnReset:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -50, -5)
	btnReset:SetSize(16, 16)
	btnReset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
	btnReset:Hide()
	frame.btnReset = btnReset
	btnReset:SetScript("OnClick", function()
		addon.itemBagFilters = {}
		addon.itemBagFiltersQuality = {}
		addon.itemBagFiltersBound = {}
		addon.itemBagFiltersUpgrade = {}

		for _, widget in ipairs(frame.widgets) do
			if widget.SetValue then widget:SetValue(false) end
			if widget.SetText then widget:SetText("") end
		end

		addon.functions.updateBags(ContainerFrameCombinedBags)
		for _, cframe in ipairs(ContainerFrameContainer.ContainerFrames) do
			addon.functions.updateBags(cframe)
		end

		if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end

		UpdateResetButton()
	end)
	btnReset:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["bagFilterResetFilters"])
		GameTooltip:Show()
	end)
	btnReset:SetScript("OnLeave", function() GameTooltip:Hide() end)

	UpdateResetButton()
	return frame
end

local function ToggleFilterMenu(self)
	if not addon.filterFrame then addon.filterFrame = CreateFilterMenu() end
	addon.filterFrame:Show()

	addon.functions.updateBags(ContainerFrameCombinedBags)
	for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do
		addon.functions.updateBags(frame)
	end

	if _G.BankPanel and _G.BankPanel:IsShown() then addon.functions.updateBags(_G.BankPanel) end
end

local function InitializeFilterUI()
	if nil == addon.filterFrame then ToggleFilterMenu() end
end

function addon.functions.updateBags(frame)
	if addon.functions.IsBagsModuleActive() then
		if addon.filterFrame then
			addon.filterFrame:SetParent(nil)
			addon.filterFrame:Hide()
			addon.filterFrame = nil
			addon.itemBagFilters = {}
			addon.itemBagFiltersQuality = {}
			addon.itemBagFiltersBound = {}
			addon.itemBagFiltersUpgrade = {}
		end
		return
	end

	if addon.db["showBagFilterMenu"] then
		InitializeFilterUI()
	elseif addon.filterFrame then
		addon.filterFrame:SetParent(nil)
		addon.filterFrame:Hide()
		addon.filterFrame = nil
		addon.itemBagFilters = {}
		addon.itemBagFiltersQuality = {}
		addon.itemBagFiltersBound = {}
		addon.itemBagFiltersUpgrade = {}
	end
	if not frame:IsShown() then return end

	if frame:GetName() == "BankPanel" then
		for itemButton in frame:EnumerateValidItems() do
			if addon.db["showIlvlOnBankFrame"] then
				local bag = itemButton:GetBankTabID()
				local slot = itemButton:GetContainerSlotID()
				if bag and slot then updateButtonInfo(itemButton, bag, slot, frame:GetName()) end
			elseif itemButton.ItemLevelText then
				itemButton.ItemLevelText:Hide()
			end
		end
	else
		for _, itemButton in frame:EnumerateValidItems() do
			if itemButton then
				if shouldUpdateBagButtonInfo() then
					updateButtonInfo(itemButton, itemButton:GetBagID(), itemButton:GetID(), frame:GetName())
				else
					clearBagButtonInfo(itemButton)
				end
			end
		end
	end
end

function addon.functions.IsQuestRepeatableType(questID)
	if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then return true end
	if C_QuestLog.IsRepeatableQuest and C_QuestLog.IsRepeatableQuest(questID) then return true end
	local classification
	if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then classification = C_QuestInfoSystem.GetQuestClassification(questID) end
	return classification == Enum.QuestClassification.Recurring or classification == Enum.QuestClassification.Calling
end

local function handleWayCommand(msg)
	local args = {}
	msg = (msg or ""):gsub(",", " ")
	for token in string.gmatch(msg, "%S+") do
		table.insert(args, token)
	end

	local mapID, x, y
	if #args >= 2 then
		local first = args[1]
		if first:sub(1, 1) == "#" then first = first:sub(2) end
		local firstNumber = tonumber(first)
		local secondNumber = tonumber(args[2])
		local thirdNumber = tonumber(args[3])

		if firstNumber and secondNumber and thirdNumber then
			mapID = firstNumber
			x = secondNumber
			y = thirdNumber
		else
			x = firstNumber
			y = secondNumber
			mapID = C_Map.GetBestMapForUnit("player")
		end
	end

	if not mapID or not x or not y then
		print("|cff00ff98Enhance QoL|r: " .. L["wayUsage"])
		return
	end

	local mInfo = C_Map.GetMapInfo(mapID)
	if not mInfo or nil == mInfo then
		print("|cff00ff98Enhance QoL|r: " .. L["wayError"]:format(mapID))
		return
	end

	if not C_Map.CanSetUserWaypointOnMap(mapID) then
		print("|cff00ff98Enhance QoL|r: " .. L["wayErrorPlacePing"])
		return
	end

	x = x / 100
	y = y / 100

	local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
	C_Map.SetUserWaypoint(point)
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	print("|cff00ff98Enhance QoL|r: " .. string.format(L["waySet"], mInfo.name, x * 100, y * 100))
end

function addon.functions.registerWayCommand()
	if SlashCmdList["WAY"] or _G.SLASH_WAY1 then return end
	addon.functions.SetSlashCommandAlias("EQOLWAY", 1, "/way")
	SlashCmdList["EQOLWAY"] = handleWayCommand
end

local slashCommandRegistry

local function normalizeSlashCommand(command)
	if type(command) ~= "string" then return nil end
	command = command:lower()
	if command == "" then return nil end
	return command
end

local function updateSlashCommandRegistryCount(command, delta)
	local normalized = normalizeSlashCommand(command)
	if not (normalized and slashCommandRegistry) then return normalized end
	local nextCount = (slashCommandRegistry[normalized] or 0) + (delta or 0)
	if nextCount > 0 then
		slashCommandRegistry[normalized] = nextCount
	else
		slashCommandRegistry[normalized] = nil
	end
	return normalized
end

local function rebuildSlashCommandRegistry()
	local registry = {}
	for key, value in pairs(_G) do
		if type(key) == "string" and key:match("^SLASH_") and type(value) == "string" then
			local normalized = normalizeSlashCommand(value)
			if normalized then registry[normalized] = (registry[normalized] or 0) + 1 end
		end
	end
	slashCommandRegistry = registry
	return registry
end

local function getSlashCommandRegistry()
	if slashCommandRegistry then return slashCommandRegistry end
	return rebuildSlashCommandRegistry()
end

function addon.functions.IsSlashCommandRegistered(command)
	local normalized = normalizeSlashCommand(command)
	if not normalized then return false end
	return getSlashCommandRegistry()[normalized] ~= nil
end

function addon.functions.SetSlashCommandAlias(prefix, index, command)
	if type(prefix) ~= "string" or prefix == "" then return nil end
	local key = "SLASH_" .. prefix .. tostring(index)
	local previous = normalizeSlashCommand(_G[key])
	local normalized = normalizeSlashCommand(command)
	_G[key] = normalized
	if previous ~= normalized then
		updateSlashCommandRegistryCount(previous, -1)
		updateSlashCommandRegistryCount(normalized, 1)
	end
	return normalized
end

local function isSlashCommandRegistered(command)
	return addon.functions.IsSlashCommandRegistered(command)
end

local function isSlashCommandOwnedByEQOL(command, listName, prefix, maxIndex)
	if not SlashCmdList or not listName or not prefix then return false end
	if not SlashCmdList[listName] then return false end
	local cmd = command and command:lower()
	if not cmd then return false end
	for i = 1, maxIndex or 1 do
		local val = _G["SLASH_" .. prefix .. i]
		if type(val) == "string" and val:lower() == cmd then return true end
	end
	return false
end

local function getPullCountdownSeconds(msg)
	local number = tonumber(msg and msg:match("(%d+)") or "")
	if not number then number = (addon.db and addon.db["pullTimerLongTime"]) or 10 end
	if number < 0 then number = 0 end
	local maxSeconds = (Constants and Constants.PartyCountdownConstants and Constants.PartyCountdownConstants.MaxCountdownSeconds) or 3600
	if number > maxSeconds then number = maxSeconds end
	return number
end

local function toggleCooldownViewerSettings()
	if InCombatLockdown and InCombatLockdown() then return end
	local frame = _G.CooldownViewerSettings
	if not frame then
		local loader = (C_AddOns and C_AddOns.LoadAddOn) or _G.UIParentLoadAddOn
		if loader then
			loader("Blizzard_CooldownViewer")
			frame = _G.CooldownViewerSettings
		end
	end
	if not frame then return end
	if frame.TogglePanel then
		frame:TogglePanel()
	elseif frame.ShowUIPanel then
		if frame:IsShown() then
			frame:Hide()
		else
			frame:ShowUIPanel()
		end
	else
		frame:SetShown(not frame:IsShown())
	end
end

local function toggleEditMode()
	if InCombatLockdown and InCombatLockdown() then return end
	local frame = _G.EditModeManagerFrame
	if not frame then
		local loader = (C_AddOns and C_AddOns.LoadAddOn) or _G.UIParentLoadAddOn
		if loader then
			loader("Blizzard_EditMode")
			frame = _G.EditModeManagerFrame
		end
	end
	if not frame then return end
	if frame.CanEnterEditMode and not frame:CanEnterEditMode() then return end
	if frame:IsShown() then
		if HideUIPanel then
			HideUIPanel(frame)
		else
			frame:Hide()
		end
	else
		if ShowUIPanel then
			ShowUIPanel(frame)
		else
			frame:Show()
		end
	end
end

local function toggleQuickKeybindMode()
	if InCombatLockdown and InCombatLockdown() then return end
	local frame = _G.QuickKeybindFrame
	if not frame then
		local loader = (C_AddOns and C_AddOns.LoadAddOn) or _G.UIParentLoadAddOn
		if loader then
			loader("Blizzard_QuickKeybind")
			frame = _G.QuickKeybindFrame
		end
	end
	if not frame then return end
	frame:SetShown(not frame:IsShown())
end

local function toggleClickCastBindings()
	if InCombatLockdown and InCombatLockdown() then return end
	if C_GameRules and C_GameRules.IsPlunderstorm and C_GameRules.IsPlunderstorm() then return end
	local toggleFrame = _G.ToggleClickBindingFrame
	if toggleFrame then toggleFrame() end
end

function addon.functions.registerCooldownManagerSlashCommand()
	if not SlashCmdList then return end
	local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
	local waLoaded = isLoaded and isLoaded("WeakAuras") or false

	local commands = {}
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLCDMSC", "EQOLCDMSC", 2) or not isSlashCommandRegistered(command) end
	if canClaim("/cdm") then commands[#commands + 1] = "/cdm" end
	if not waLoaded and canClaim("/wa") then commands[#commands + 1] = "/wa" end

	if #commands == 0 then return end
	addon.functions.SetSlashCommandAlias("EQOLCDMSC", 1, commands[1])
	addon.functions.SetSlashCommandAlias("EQOLCDMSC", 2, commands[2])
	SlashCmdList["EQOLCDMSC"] = function() toggleCooldownViewerSettings() end
end

function addon.functions.registerPullTimerSlashCommand()
	if not SlashCmdList then return end
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLPULL", "EQOLPULL", 1) or not isSlashCommandRegistered(command) end
	if not canClaim("/pull") then return end
	addon.functions.SetSlashCommandAlias("EQOLPULL", 1, "/pull")
	SlashCmdList["EQOLPULL"] = function(msg)
		local seconds = getPullCountdownSeconds(msg)
		if InCombatLockdown and InCombatLockdown() then
			if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(L["pullSlashUnavailableInCombat"], 1, 0.1, 0.1) end
			return
		end
		if C_PartyInfo and C_PartyInfo.DoCountdown then C_PartyInfo.DoCountdown(seconds) end
	end
end

function addon.functions.registerEditModeSlashCommand()
	if not SlashCmdList then return end
	local commands = {}
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLEM", "EQOLEM", 3) or not isSlashCommandRegistered(command) end
	if canClaim("/em") then commands[#commands + 1] = "/em" end
	if canClaim("/edit") then commands[#commands + 1] = "/edit" end
	if canClaim("/editmode") then commands[#commands + 1] = "/editmode" end
	if #commands == 0 then return end
	addon.functions.SetSlashCommandAlias("EQOLEM", 1, commands[1])
	addon.functions.SetSlashCommandAlias("EQOLEM", 2, commands[2])
	addon.functions.SetSlashCommandAlias("EQOLEM", 3, commands[3])
	SlashCmdList["EQOLEM"] = function() toggleEditMode() end
end

function addon.functions.registerQuickKeybindSlashCommand()
	if not SlashCmdList then return end
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLKB", "EQOLKB", 1) or not isSlashCommandRegistered(command) end
	if not canClaim("/kb") then return end
	addon.functions.SetSlashCommandAlias("EQOLKB", 1, "/kb")
	SlashCmdList["EQOLKB"] = function() toggleQuickKeybindMode() end
end

function addon.functions.registerClickCastSlashCommand()
	if not SlashCmdList then return end
	local commands = {}
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLCCB", "EQOLCCB", 2) or not isSlashCommandRegistered(command) end
	if canClaim("/ccb") then commands[#commands + 1] = "/ccb" end
	if canClaim("/clickcast") then commands[#commands + 1] = "/clickcast" end
	if #commands == 0 then return end
	addon.functions.SetSlashCommandAlias("EQOLCCB", 1, commands[1])
	addon.functions.SetSlashCommandAlias("EQOLCCB", 2, commands[2])
	SlashCmdList["EQOLCCB"] = function() toggleClickCastBindings() end
end

function addon.functions.registerReloadUISlashCommand()
	if not SlashCmdList then return end
	local function canClaim(command) return isSlashCommandOwnedByEQOL(command, "EQOLRL", "EQOLRL", 1) or not isSlashCommandRegistered(command) end
	if not canClaim("/rl") then return end
	addon.functions.SetSlashCommandAlias("EQOLRL", 1, "/rl")
	SlashCmdList["EQOLRL"] = function()
		if ReloadUI then ReloadUI() end
	end
end

function addon.functions.catalystChecks()
	-- No catalyst charges exist for Timerunners; ensure hidden
	if addon.functions.IsTimerunner() then
		addon.variables.catalystID = nil
		if addon.general and addon.general.iconFrame then addon.general.iconFrame:Hide() end
		return
	end

	local mId = C_MythicPlus.GetCurrentSeason()
	if mId == -1 then
		C_MythicPlus.RequestMapInfo()
		C_Timer.After(0.1, function() addon.functions.catalystChecks() end)
		return
	end
	if not mId or mId < 0 then
		-- Patch fallback (if the season ID is unavailable):
		-- 1) Add timestamps in addon.variables.patchInformations (Init.lua).
		-- 2) Use addon.functions.IsPatchLive(...) here to map to a season ID.
		addon.variables.catalystID = nil
		return
	end

	if mId == 15 then
		-- TWW Season 3 - Ethereal Voidsplinter
		addon.variables.catalystID = 3269
	elseif mId == 17 then
		addon.variables.catalystID = 3378
	elseif mId == 18 then
		-- Midnight Season 2 PTR
		addon.variables.catalystID = 3465
	end
	addon.functions.createCatalystFrame()
end

function addon.functions.fmtToPattern(fmt)
	local pat = fmt:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	pat = pat:gsub("%%%%d", "%%d+") -- "%d" -> "%d+"
	pat = pat:gsub("%%%%s", ".+") -- "%s" -> ".+"
	return "^" .. pat .. "$"
end

addon.functions.FindBindingIndex = function(data)
	local found = {}
	if not type(data) == "table" then return end

	for i = 1, GetNumBindings() do
		local command = GetBinding(i)
		if data[command] then found[command] = i end
	end
	return found
end

function addon.functions.isRestrictedContent(ignoreMap)
	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	local restrictedActions = _G.C_RestrictedActions
	if not (restrictionTypes and restrictedActions and restrictedActions.GetAddOnRestrictionState) then return false end
	for _, v in pairs(restrictionTypes) do
		if ignoreMap and v ~= 4 or not ignoreMap then
			if restrictedActions.GetAddOnRestrictionState(v) == 2 then return true end
		end
	end
	return false
end
