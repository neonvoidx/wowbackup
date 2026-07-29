-- luacheck: globals BackdropTemplate CreateFrame UIParent MinimapCluster InCombatLockdown RegisterAttributeDriver GameTooltip C_UnitAuras CooldownFrame_Set GetTime GetInventoryItemTexture GetInventoryItemID GetInventoryItemLink GetInventorySlotInfo GetWeaponEnchantInfo C_Item C_DurationUtil C_CurveUtil Enum AnchorUtil AuraContainerItemEnchantmentSlot AuraContainerItemEnchantmentSortMethod AuraContainerSortMethod AuraContainerSortDirection CustomAuraContainerItemEnchantmentPlacement DEBUFF_TYPE_MAGIC_COLOR DEBUFF_TYPE_CURSE_COLOR DEBUFF_TYPE_DISEASE_COLOR DEBUFF_TYPE_POISON_COLOR DEBUFF_TYPE_BLEED_COLOR DEBUFF_TYPE_NONE_COLOR GetFrameHandleFrame
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
local _, _, _, interfaceVersion = GetBuildInfo()
local useNativeAuraContainers = (tonumber(interfaceVersion) or 0) >= 120100

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.DefaultAuraContainers = addon.DefaultAuraContainers or {}
addon.DefaultAuraContainers.functions = addon.DefaultAuraContainers.functions or {}
addon.DefaultAuraContainers.variables = addon.DefaultAuraContainers.variables or {}
local DAC = addon.DefaultAuraContainers

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local issecretvalue = _G.issecretvalue

local DEFAULT_AURA_INITIAL_CONFIG = [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("config-width"))
	self:SetHeight(header:GetAttribute("config-height"))
]]

local function isDefaultAuraIconSkinEnabled()
	return addon.db and (addon.db.skinnerDefaultBuffIconsEnabled == true or addon.db.skinnerDefaultDebuffIconsEnabled == true)
end

local DEFAULT_AURA_DB_PREFIX = "skinnerDefaultAura"
local DEFAULT_DEBUFF_AURA_DB_PREFIX = "skinnerDefaultDebuffAura"

local function normalizeDefaultAuraKind(kind)
	return kind == "debuff" and "debuff" or "buff"
end

local function getDefaultAuraSyncEnabled()
	return not addon.db or addon.db.skinnerDefaultAuraSyncBuffDebuff ~= false
end

local function getDefaultAuraDBPrefix(kind)
	kind = normalizeDefaultAuraKind(kind)
	if kind == "debuff" and not getDefaultAuraSyncEnabled() then return DEFAULT_DEBUFF_AURA_DB_PREFIX end
	return DEFAULT_AURA_DB_PREFIX
end

local function getDefaultAuraDBValue(kind, suffix)
	if not addon.db then return nil end
	local value = addon.db[getDefaultAuraDBPrefix(kind) .. suffix]
	if value == nil and normalizeDefaultAuraKind(kind) == "debuff" then value = addon.db[DEFAULT_AURA_DB_PREFIX .. suffix] end
	return value
end

local function setDefaultAuraDBValue(kind, suffix, value)
	if not addon.db then return end
	addon.db[getDefaultAuraDBPrefix(kind) .. suffix] = value
end

local function getDefaultAuraStyleVersion()
	return DAC.variables.defaultAuraStyleVersion or 0
end

local function invalidateDefaultAuraStyleCache()
	DAC.variables.defaultAuraStyleVersion = (DAC.variables.defaultAuraStyleVersion or 0) + 1
	DAC.variables.defaultAuraStyleConfigCache = nil
	DAC.variables.defaultAuraTextStyleCache = nil
end

local DEFAULT_AURA_CONFIG_SUFFIXES = {
	"IconShape",
	"IconAlpha",
	"IconSize",
	"IconSpacing",
	"HorizontalSpacing",
	"VerticalSpacing",
	"IconsPerRow",
	"MaxRows",
	"Growth",
	"FrameStrata",
	"FrameLevel",
	"SortMethod",
	"SortDirection",
	"IncludeWeapons",
	"IconZoom",
	"IconDarkMode",
	"IconDarkness",
	"IconDesaturate",
	"CooldownDrawSwipe",
	"CooldownDrawEdge",
	"CooldownReverse",
	"BorderTexture",
	"BorderSize",
	"BorderOffset",
	"UseOriginalBorderColor",
	"UseDebuffTypeBorderColor",
	"BorderColor",
	"DurationEnabled",
	"DurationFontFace",
	"DurationFontOutline",
	"DurationFontSize",
	"DurationColor",
	"DurationAnchor",
	"DurationOffset",
	"DurationTextProfile",
	"CountEnabled",
	"CountFontFace",
	"CountFontOutline",
	"CountFontSize",
	"CountColor",
	"CountAnchor",
	"CountOffset",
}

local function copyValue(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = copyValue(v) end
	return copy
end

local function copyDefaultAuraConfig(fromKind, toKind)
	if not addon.db then return end
	fromKind = normalizeDefaultAuraKind(fromKind)
	toKind = normalizeDefaultAuraKind(toKind)
	local targetPrefix = toKind == "debuff" and DEFAULT_DEBUFF_AURA_DB_PREFIX or DEFAULT_AURA_DB_PREFIX
	for _, suffix in ipairs(DEFAULT_AURA_CONFIG_SUFFIXES) do
		addon.db[targetPrefix .. suffix] = copyValue(getDefaultAuraDBValue(fromKind, suffix))
	end
end

local DEFAULT_AURA_BORDER_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local DEFAULT_AURA_BACKDROP_BORDER = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_AURA_DURATION_COLOR = { r = 1, g = 0.82, b = 0, a = 1 }
local DEFAULT_AURA_COUNT_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local DEFAULT_AURA_DEBUFF_TYPE_COLORS = {
	[1] = DEBUFF_TYPE_MAGIC_COLOR,
	[2] = DEBUFF_TYPE_CURSE_COLOR,
	[3] = DEBUFF_TYPE_DISEASE_COLOR,
	[4] = DEBUFF_TYPE_POISON_COLOR,
	[5] = DEBUFF_TYPE_BLEED_COLOR,
	[0] = DEBUFF_TYPE_NONE_COLOR,
}
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local GLOBAL_FONT_KEY = "__EQOL_GLOBAL_FONT__"
local GLOBAL_STYLE_KEY = "__EQOL_GLOBAL_FONT_STYLE__"
local refreshDefaultAuraIconSkin
local getDefaultAuraStyleConfig
local isNoAuraBorder
local configureDefaultNativeAuraContainer

local function normalizeDefaultAuraDurationTextProfile(value)
	local durationText = addon.DurationText
	if durationText and durationText.GetProfileKey then return durationText:GetProfileKey(value or "MINIMAL") end
	return type(value) == "string" and value ~= "" and value or "MINIMAL"
end

local function normalizeAuraIconShape(value)
	if addon.IconShape and addon.IconShape.Normalize then return addon.IconShape.Normalize(value, "DEFAULT") end
	value = type(value) == "string" and strupper(value) or "DEFAULT"
	if value == "SQUARE" or value == "ROUND" or value == "HEXAGON" or value == "DIAMOND" then return value end
	if value == "ROUND_STAR" or value == "STAR" then return value end
	return "DEFAULT"
end

local function normalizeAuraIconZoom(value)
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then return addon.IconShape.NormalizeIconZoom(value) end
	value = tonumber(value) or 0
	if value < 0 then value = 0 end
	if value > 35 then value = 35 end
	return math.floor(value + 0.5)
end

local function normalizeAuraIconDarkness(value)
	value = tonumber(value) or 35
	if value < 0 then value = 0 end
	if value > 100 then value = 100 end
	return math.floor(value + 0.5)
end

local function normalizeAuraIconAlpha(value)
	value = tonumber(value)
	if value == nil then value = 1 end
	if value < 0 then value = 0 end
	if value > 1 then value = 1 end
	return value
end

local function applyDefaultAuraIconDarkMode(button, config)
	local icon = button and (button.Icon or button.icon)
	if not icon then return end
	config = config or getDefaultAuraStyleConfig(button and button.eqolDefaultAuraKind)
	local alpha = config.iconAlpha or 1
	if config.iconDarkMode == true then
		local darkness = config.iconDarkness
		local value = 1 - (darkness / 100)
		if icon.SetDesaturated then icon:SetDesaturated(config.iconDesaturate == true) end
		if icon.SetVertexColor then icon:SetVertexColor(value, value, value, alpha) end
	else
		if icon.SetDesaturated then icon:SetDesaturated(false) end
		if icon.SetVertexColor then icon:SetVertexColor(1, 1, 1, alpha) end
	end
end

local function normalizeAuraBorder(value, shape)
	if addon.IconShape and addon.IconShape.NormalizeBorder then
		return addon.IconShape.NormalizeBorder(value, addon.IconShape.BORDER and addon.IconShape.BORDER.NONE or "NONE", shape, {
			allowNone = true,
			emptyValue = addon.IconShape.BORDER and addon.IconShape.BORDER.NONE or "NONE",
		})
	end
	return value == "NONE" and "NONE" or "NONE"
end

local function getDefaultAuraBorderColor(kind)
	local col = getDefaultAuraDBValue(kind, "BorderColor")
	if type(col) ~= "table" then col = DEFAULT_AURA_BORDER_COLOR end
	return {
		col.r or DEFAULT_AURA_BORDER_COLOR.r,
		col.g or DEFAULT_AURA_BORDER_COLOR.g,
		col.b or DEFAULT_AURA_BORDER_COLOR.b,
		col.a ~= nil and col.a or DEFAULT_AURA_BORDER_COLOR.a,
	}
end

local function getDefaultAuraUseOriginalBorderColor(kind)
	return getDefaultAuraDBValue(kind, "UseOriginalBorderColor") == true
end

local function getDefaultAuraUseDebuffTypeBorderColor(kind)
	return normalizeDefaultAuraKind(kind) == "debuff" and getDefaultAuraDBValue(kind, "UseDebuffTypeBorderColor") == true
end

local function getDefaultAuraOriginalBorderColor(button)
	local border = button and (button.Border or button.border)
	if border and border.GetVertexColor then
		return { border:GetVertexColor() }
	end
	return nil
end

local function ensureDefaultAuraDispelColorCurve()
	local curve = DAC.variables.dispelColorCurve
	if curve ~= nil then return curve end
	curve = C_CurveUtil and C_CurveUtil.CreateColorCurve and C_CurveUtil.CreateColorCurve() or false
	if curve and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
		curve:SetType(Enum.LuaCurveType.Step)
		for dispelType, color in pairs(DEFAULT_AURA_DEBUFF_TYPE_COLORS) do
			if color then curve:AddPoint(dispelType, color) end
		end
	end
	DAC.variables.dispelColorCurve = curve
	return curve
end

local function getDefaultAuraDebuffTypeBorderColor(button)
	if not (button and button.eqolAuraUnit and button.eqolAuraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor) then return nil end
	local curve = ensureDefaultAuraDispelColorCurve()
	if not curve then return nil end
	local color = C_UnitAuras.GetAuraDispelTypeColor(button.eqolAuraUnit, button.eqolAuraInstanceID, curve)
	if color and color.GetRGBA then
		return { color:GetRGBA() }
	elseif color and color.r then
		return { color.r, color.g, color.b, color.a }
	end
	return nil
end

local function resolveDefaultAuraBorderColor(button, kind)
	if getDefaultAuraUseDebuffTypeBorderColor(kind) then
		return getDefaultAuraDebuffTypeBorderColor(button) or getDefaultAuraOriginalBorderColor(button) or getDefaultAuraBorderColor(kind)
	end
	if getDefaultAuraUseOriginalBorderColor(kind) then
		return getDefaultAuraOriginalBorderColor(button) or getDefaultAuraBorderColor(kind)
	end
	return getDefaultAuraBorderColor(kind)
end

local function resolveDefaultAuraBorderColorFromConfig(button, config)
	if config.useDebuffTypeBorderColor then
		return getDefaultAuraDebuffTypeBorderColor(button) or getDefaultAuraOriginalBorderColor(button) or config.color or getDefaultAuraBorderColor(config.kind)
	end
	if config.useOriginalBorderColor then
		return getDefaultAuraOriginalBorderColor(button) or config.color or getDefaultAuraBorderColor(config.kind)
	end
	return config.color
end

local function shouldUpdateDefaultAuraStyleForAura(config)
	return config and config.kind == "debuff" and config.useDebuffTypeBorderColor == true
end

local function normalizeAuraTextColor(value, fallback)
	fallback = fallback or DEFAULT_AURA_DURATION_COLOR
	if type(value) ~= "table" then value = fallback end
	return {
		r = tonumber(value.r or value[1]) or fallback.r or 1,
		g = tonumber(value.g or value[2]) or fallback.g or 1,
		b = tonumber(value.b or value[3]) or fallback.b or 1,
		a = value.a ~= nil and value.a or value[4] or fallback.a or 1,
	}
end

local function getAuraTextColorComponents(value, fallback)
	fallback = fallback or DEFAULT_AURA_DURATION_COLOR
	if type(value) ~= "table" then value = fallback end
	return tonumber(value.r or value[1]) or fallback.r or 1, tonumber(value.g or value[2]) or fallback.g or 1, tonumber(value.b or value[3]) or fallback.b or 1, value.a ~= nil and value.a or value[4] or fallback.a or 1
end

local function getGlobalFontKey()
	return addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or GLOBAL_FONT_KEY
end

local function getGlobalFontLabel()
	return addon.functions and addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or (L["useGlobalFontConfig"] or "Use global font config")
end

local function getGlobalStyleKey()
	return addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or GLOBAL_STYLE_KEY
end

local function getGlobalStyleLabel()
	return addon.functions and addon.functions.GetGlobalFontStyleConfigLabel and addon.functions.GetGlobalFontStyleConfigLabel() or (L["useGlobalFontStyleConfig"] or "Use global font styling")
end

local function normalizeAuraFontKey(value)
	if type(value) == "string" and value ~= "" then return value end
	return getGlobalFontKey()
end

local function normalizeAuraFontStyle(value)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then return addon.functions.NormalizeFontStyleChoice(value, getGlobalStyleKey(), true) end
	if value == getGlobalStyleKey() then return value end
	if value == "NONE" or value == "OUTLINE" or value == "THICKOUTLINE" or value == "MONOCHROME" or value == "MONOCHROMEOUTLINE" then return value end
	return getGlobalStyleKey()
end

local function resolveAuraFont(key)
	key = normalizeAuraFontKey(key)
	if key == getGlobalFontKey() then key = addon.db and addon.db.globalFontFace or key end
	if addon.functions and addon.functions.ResolveLSMMedia then
		local resolved = addon.functions.ResolveLSMMedia("font", key, DEFAULT_FONT, true)
		if resolved then return resolved end
	end
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font")
	if type(hash) == "table" and type(hash[key]) == "string" and hash[key] ~= "" then return hash[key] end
	return DEFAULT_FONT
end

local function resolveAuraFontStyle(style)
	if addon.functions and addon.functions.ResolveFontStyleChoice then return addon.functions.ResolveFontStyleChoice(style, "OUTLINE") end
	style = normalizeAuraFontStyle(style)
	if style == getGlobalStyleKey() then style = addon.db and addon.db.globalFontStyle or "OUTLINE" end
	if style == "NONE" then return "" end
	return style
end

local function buildAuraFontOptions()
	local options = {
		{ value = getGlobalFontKey(), label = getGlobalFontLabel() },
	}
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	for _, name in ipairs(names) do
		options[#options + 1] = { value = name, label = name }
	end
	return options
end

local function buildAuraFontStyleOptions()
	if addon.functions and addon.functions.GetFontStyleOptionList then return addon.functions.GetFontStyleOptionList(true) end
	return {
		{ value = getGlobalStyleKey(), label = getGlobalStyleLabel() },
		{ value = "NONE", label = _G.NONE or "None" },
		{ value = "OUTLINE", label = L["Font outline"] or "Font outline" },
		{ value = "THICKOUTLINE", label = L["Thick outline"] or "Thick outline" },
		{ value = "MONOCHROME", label = "Monochrome" },
		{ value = "MONOCHROMEOUTLINE", label = "Monochrome Outline" },
	}
end

local function getDefaultAuraBorderSize(value, kind)
	local size = tonumber(value)
	if size == nil then size = tonumber(getDefaultAuraDBValue(kind, "BorderSize")) end
	size = size or 1
	if size < 1 then size = 1 end
	if size > 24 then size = 24 end
	return size
end

local function getDefaultAuraBorderOffset(value, kind)
	local offset = tonumber(value)
	if offset == nil then offset = tonumber(getDefaultAuraDBValue(kind, "BorderOffset")) end
	offset = offset or 0
	if offset < -20 then offset = -20 end
	if offset > 100 then offset = 100 end
	return offset
end

local function getDefaultAuraIconSize(value, kind)
	local size = tonumber(value)
	if size == nil then size = tonumber(getDefaultAuraDBValue(kind, "IconSize")) end
	size = size or 32
	if size < 16 then size = 16 end
	if size > 80 then size = 80 end
	return size
end

local function getDefaultAuraIconSpacing(value, kind)
	local spacing = tonumber(value)
	if spacing == nil then spacing = tonumber(getDefaultAuraDBValue(kind, "IconSpacing")) end
	spacing = spacing or 4
	if spacing < 0 then spacing = 0 end
	if spacing > 24 then spacing = 24 end
	return spacing
end

local function getDefaultAuraHorizontalSpacing(value, kind)
	local spacing = tonumber(value)
	if spacing == nil then spacing = tonumber(getDefaultAuraDBValue(kind, "HorizontalSpacing")) end
	if spacing == nil then spacing = getDefaultAuraIconSpacing(nil, kind) end
	if spacing < 0 then spacing = 0 end
	if spacing > 100 then spacing = 100 end
	return spacing
end

local function getDefaultAuraVerticalSpacing(value, kind)
	local spacing = tonumber(value)
	if spacing == nil then spacing = tonumber(getDefaultAuraDBValue(kind, "VerticalSpacing")) end
	if spacing == nil then spacing = getDefaultAuraIconSpacing(nil, kind) + 12 end
	if spacing < 0 then spacing = 0 end
	if spacing > 100 then spacing = 100 end
	return spacing
end

local function getDefaultAuraDrawSwipe(kind)
	return getDefaultAuraDBValue(kind, "CooldownDrawSwipe") ~= false
end

local function getDefaultAuraDrawEdge(kind)
	return getDefaultAuraDBValue(kind, "CooldownDrawEdge") == true
end

local function getDefaultAuraCooldownReverse(kind)
	return getDefaultAuraDBValue(kind, "CooldownReverse") == true
end

local function getDefaultAuraDurationTextProfile(kind)
	return normalizeDefaultAuraDurationTextProfile(getDefaultAuraDBValue(kind, "DurationTextProfile"))
end

local function applyDefaultAuraDurationTextProfile(button, config)
	if not (button and button.Cooldown and addon.functions and addon.functions.ApplyDurationTextProfileToCooldownFrame) then return false end
	config = config or getDefaultAuraStyleConfig(button.eqolDefaultAuraKind)
	return addon.functions.ApplyDurationTextProfileToCooldownFrame(button.Cooldown, config.durationTextProfile)
end

local function getDefaultAuraIconsPerRow(value, kind)
	local perRow = tonumber(value)
	if perRow == nil then perRow = tonumber(getDefaultAuraDBValue(kind, "IconsPerRow")) end
	perRow = perRow or 8
	if perRow < 1 then perRow = 1 end
	if perRow > 32 then perRow = 32 end
	return perRow
end

local function getDefaultAuraMaxRows(value, kind)
	local rows = tonumber(value)
	if rows == nil then rows = tonumber(getDefaultAuraDBValue(kind, "MaxRows")) end
	rows = rows or 4
	if rows < 1 then rows = 1 end
	if rows > 10 then rows = 10 end
	return rows
end

local function normalizeDefaultAuraFrameStrata(value)
	value = type(value) == "string" and strupper(value) or "MEDIUM"
	if value == "BACKGROUND" or value == "LOW" or value == "MEDIUM" or value == "HIGH" or value == "DIALOG" or value == "FULLSCREEN" or value == "FULLSCREEN_DIALOG" or value == "TOOLTIP" then return value end
	return "MEDIUM"
end

local function getDefaultAuraFrameLevel(value, kind)
	local level = tonumber(value)
	if level == nil then level = tonumber(getDefaultAuraDBValue(kind, "FrameLevel")) end
	level = level or 50
	if level < 0 then level = 0 end
	if level > 100 then level = 100 end
	return math.floor(level + 0.5)
end

local function normalizeDefaultAuraSortMethod(value)
	value = type(value) == "string" and strupper(value) or "TIME"
	if value == "INDEX" or value == "NAME" or value == "TIME" then return value end
	return "TIME"
end

local function normalizeDefaultAuraSortDirection(value)
	value = type(value) == "string" and value or "-"
	if value == "+" or value == "-" then return value end
	return "-"
end

local DEFAULT_AURA_GROWTH_OPTIONS = {
	"LEFTDOWN",
	"LEFTUP",
	"RIGHTDOWN",
	"RIGHTUP",
	"DOWNLEFT",
	"DOWNRIGHT",
	"UPLEFT",
	"UPRIGHT",
}

local function parseDefaultAuraGrowth(value)
	local raw = type(value) == "string" and strupper(value):gsub("[%s_%-]+", "") or ""
	local first, second = raw:match("^(LEFT)(UP)$")
	if not first then first, second = raw:match("^(LEFT)(DOWN)$") end
	if not first then first, second = raw:match("^(RIGHT)(UP)$") end
	if not first then first, second = raw:match("^(RIGHT)(DOWN)$") end
	if not first then first, second = raw:match("^(UP)(LEFT)$") end
	if not first then first, second = raw:match("^(UP)(RIGHT)$") end
	if not first then first, second = raw:match("^(DOWN)(LEFT)$") end
	if not first then first, second = raw:match("^(DOWN)(RIGHT)$") end
	if not first then first, second = "LEFT", "DOWN" end
	return first, second
end

local function normalizeDefaultAuraGrowth(value)
	local first, second = parseDefaultAuraGrowth(value)
	return first .. second
end

local function getDefaultAuraGrowth(kind)
	return normalizeDefaultAuraGrowth(getDefaultAuraDBValue(kind, "Growth"))
end

local function getDefaultAuraGrowthLayout(kind)
	local primary, secondary = parseDefaultAuraGrowth(getDefaultAuraGrowth(kind))
	local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
	local horizontal = primaryHorizontal and primary or secondary
	local vertical = primaryHorizontal and secondary or primary
	local startPoint = (vertical == "UP" and "BOTTOM" or "TOP") .. (horizontal == "LEFT" and "RIGHT" or "LEFT")
	return primary, secondary, primaryHorizontal, startPoint
end

local function getDefaultAuraLayoutSize(kind, size, horizontalSpacing, verticalSpacing, perRow, maxRows)
	return perRow * size + (perRow - 1) * horizontalSpacing, maxRows * size + (maxRows - 1) * verticalSpacing
end

local function getAuraTextSize(key, fallback)
	local size = tonumber(addon.db and addon.db[key]) or fallback
	if size < 6 then size = 6 end
	if size > 64 then size = 64 end
	return size
end

local function getAuraTextOffset(key, axis, fallback)
	local value = addon.db and addon.db[key]
	if type(value) == "table" then value = value[axis] end
	value = tonumber(value) or fallback or 0
	if value < -100 then value = -100 end
	if value > 100 then value = 100 end
	return value
end

local function normalizeAuraAnchorPoint(value, fallback)
	value = type(value) == "string" and strupper(value) or fallback
	if value == "TOPLEFT" or value == "TOP" or value == "TOPRIGHT" or value == "LEFT" or value == "CENTER" or value == "RIGHT" or value == "BOTTOMLEFT" or value == "BOTTOM" or value == "BOTTOMRIGHT" then return value end
	return fallback or "CENTER"
end

local function getDefaultAuraTextStyleCache()
	local cache = DAC.variables.defaultAuraTextStyleCache
	if not cache then
		cache = {}
		DAC.variables.defaultAuraTextStyleCache = cache
	end
	return cache
end

local function getDefaultAuraTextStyleConfig(kind, prefix, fallbackColor)
	kind = normalizeDefaultAuraKind(kind)
	prefix = prefix or "Duration"
	local cache = getDefaultAuraTextStyleCache()
	local cacheKey = kind .. ":" .. prefix
	local entry = cache[cacheKey]
	if not entry then
		entry = {}
		cache[cacheKey] = entry
	end

	local styleVersion = getDefaultAuraStyleVersion()
	local fontVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	if entry.styleVersion == styleVersion and entry.fontVersion == fontVersion and entry.key then return entry end

	local offset = getDefaultAuraDBValue(kind, prefix .. "Offset")
	local r, g, b, a = getAuraTextColorComponents(getDefaultAuraDBValue(kind, prefix .. "Color"), fallbackColor)
	local fontKey = normalizeAuraFontKey(getDefaultAuraDBValue(kind, prefix .. "FontFace"))
	local outlineKey = normalizeAuraFontStyle(getDefaultAuraDBValue(kind, prefix .. "FontOutline"))
	local size = getAuraTextSize(nil, tonumber(getDefaultAuraDBValue(kind, prefix .. "FontSize")) or (prefix == "Duration" and 10 or 12))
	local point = normalizeAuraAnchorPoint(getDefaultAuraDBValue(kind, prefix .. "Anchor"), prefix == "Duration" and "BOTTOM" or "TOPRIGHT")
	local x = getAuraTextOffset(nil, "x", type(offset) == "table" and offset.x or (prefix == "Duration" and 0 or -1))
	local y = getAuraTextOffset(nil, "y", type(offset) == "table" and offset.y or -1)
	local enabled = getDefaultAuraDBValue(kind, prefix .. "Enabled") ~= false

	if
		entry.styleVersion == styleVersion
		and entry.enabled == enabled
		and entry.fontKey == fontKey
		and entry.outlineKey == outlineKey
		and entry.size == size
		and entry.r == r
		and entry.g == g
		and entry.b == b
		and entry.a == a
		and entry.point == point
		and entry.x == x
		and entry.y == y
		and entry.fontVersion == fontVersion
		and entry.key
	then
		return entry
	end

	entry.styleVersion = styleVersion
	entry.enabled = enabled
	entry.fontKey = fontKey
	entry.outlineKey = outlineKey
	entry.size = size
	entry.r = r
	entry.g = g
	entry.b = b
	entry.a = a
	entry.point = point
	entry.x = x
	entry.y = y
	entry.fontVersion = fontVersion
	entry.font = resolveAuraFont(fontKey)
	entry.outline = resolveAuraFontStyle(outlineKey)
	entry.fontStyleKey = tostring(fontVersion) .. ":" .. tostring(entry.font) .. ":" .. tostring(size) .. ":" .. tostring(entry.outline)
	entry.colorKey = tostring(r) .. ":" .. tostring(g) .. ":" .. tostring(b) .. ":" .. tostring(a)
	entry.positionKey = tostring(point) .. ":" .. tostring(x) .. ":" .. tostring(y)
	entry.key = table.concat({
		tostring(enabled),
		tostring(fontKey),
		tostring(outlineKey),
		tostring(size),
		tostring(r),
		tostring(g),
		tostring(b),
		tostring(a),
		tostring(point),
		tostring(x),
		tostring(y),
		tostring(fontVersion),
	}, ":")
	return entry
end

local function buildAuraAnchorOptions()
	return {
		{ value = "TOPLEFT", label = "Top left" },
		{ value = "TOP", label = "Top" },
		{ value = "TOPRIGHT", label = "Top right" },
		{ value = "LEFT", label = "Left" },
		{ value = "CENTER", label = "Center" },
		{ value = "RIGHT", label = "Right" },
		{ value = "BOTTOMLEFT", label = "Bottom left" },
		{ value = "BOTTOM", label = "Bottom" },
		{ value = "BOTTOMRIGHT", label = "Bottom right" },
	}
end

local function setAuraFontStringStyle(fontString, prefix, fallbackColor, kind)
	if not fontString then return end
	local config = getDefaultAuraTextStyleConfig(kind, prefix, fallbackColor)
	if fontString.eqolDefaultAuraFontStyleKey ~= config.fontStyleKey then
		if addon.functions and addon.functions.SetFontWithFallback then
			addon.functions.SetFontWithFallback(fontString, config.font, config.size, config.outline, DEFAULT_FONT)
		else
			fontString:SetFont(config.font, config.size, config.outline)
		end
		fontString.eqolDefaultAuraFontStyleKey = config.fontStyleKey
	end
	if fontString.eqolDefaultAuraColorKey ~= config.colorKey then
		fontString:SetTextColor(config.r, config.g, config.b, config.a)
		fontString.eqolDefaultAuraColorKey = config.colorKey
	end
end

local function ensureDefaultAuraTextLayer(button)
	if not button then return nil end
	local layer = button.eqolDefaultAuraTextLayer
	if not layer then
		layer = CreateFrame("Frame", nil, button)
		button.eqolDefaultAuraTextLayer = layer
	end
	local level = (button:GetFrameLevel() or 1) + 10
	if layer.eqolDefaultAuraTextLayerOwner ~= button then
		layer:ClearAllPoints()
		layer:SetAllPoints(button)
		layer.eqolDefaultAuraTextLayerOwner = button
	end
	if layer.eqolDefaultAuraTextLayerLevel ~= level then
		layer:SetFrameLevel(level)
		layer.eqolDefaultAuraTextLayerLevel = level
	end
	return layer
end

local function positionAuraFontString(fontString, owner, prefix, defaultPoint, defaultX, defaultY, kind)
	if not (fontString and owner) then return end
	local point = normalizeAuraAnchorPoint(getDefaultAuraDBValue(kind, prefix .. "Anchor"), defaultPoint)
	local offset = getDefaultAuraDBValue(kind, prefix .. "Offset")
	local x = getAuraTextOffset(nil, "x", type(offset) == "table" and offset.x or defaultX)
	local y = getAuraTextOffset(nil, "y", type(offset) == "table" and offset.y or defaultY)
	if fontString.eqolDefaultAuraPositionOwner ~= owner or fontString.eqolDefaultAuraPositionPoint ~= point or fontString.eqolDefaultAuraPositionX ~= x or fontString.eqolDefaultAuraPositionY ~= y then
		fontString:ClearAllPoints()
		fontString:SetPoint(point, owner, point, x, y)
		fontString.eqolDefaultAuraPositionOwner = owner
		fontString.eqolDefaultAuraPositionPoint = point
		fontString.eqolDefaultAuraPositionX = x
		fontString.eqolDefaultAuraPositionY = y
	end
	if fontString.SetDrawLayer and fontString.eqolDefaultAuraDrawLayerKey ~= "OVERLAY:7" then
		fontString:SetDrawLayer("OVERLAY", 7)
		fontString.eqolDefaultAuraDrawLayerKey = "OVERLAY:7"
	end
end

local function buildDefaultAuraTextStyleKey(kind, prefix, fallbackColor)
	return getDefaultAuraTextStyleConfig(kind, prefix, fallbackColor).key
end

getDefaultAuraStyleConfig = function(kind)
	kind = normalizeDefaultAuraKind(kind)
	local cache = DAC.variables.defaultAuraStyleConfigCache
	if not cache then
		cache = {}
		DAC.variables.defaultAuraStyleConfigCache = cache
	end

	local styleVersion = getDefaultAuraStyleVersion()
	local fontVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	local entry = cache[kind]
	if entry and entry.styleVersion == styleVersion and entry.fontVersion == fontVersion then return entry end

	entry = entry or {}
	cache[kind] = entry

	local size = getDefaultAuraIconSize(nil, kind)
	local shape = normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape"))
	local zoom = normalizeAuraIconZoom(getDefaultAuraDBValue(kind, "IconZoom"))
	local borderKey = normalizeAuraBorder(getDefaultAuraDBValue(kind, "BorderTexture"), shape)
	local useDebuffTypeBorderColor = getDefaultAuraUseDebuffTypeBorderColor(kind)
	local useOriginalBorderColor = getDefaultAuraUseOriginalBorderColor(kind)
	local dynamicBorderColor = kind == "debuff" and useDebuffTypeBorderColor
	local color = dynamicBorderColor and nil or getDefaultAuraBorderColor(kind)
	local colorKey = dynamicBorderColor and "dynamic" or (tostring(color[1]) .. ":" .. tostring(color[2]) .. ":" .. tostring(color[3]) .. ":" .. tostring(color[4]))
	local iconDarkMode = getDefaultAuraDBValue(kind, "IconDarkMode") == true
	local iconDarkness = normalizeAuraIconDarkness(getDefaultAuraDBValue(kind, "IconDarkness"))
	local iconAlpha = normalizeAuraIconAlpha(getDefaultAuraDBValue(kind, "IconAlpha"))
	local iconDesaturate = getDefaultAuraDBValue(kind, "IconDesaturate") == true
	local durationTextKey = buildDefaultAuraTextStyleKey(kind, "Duration", DEFAULT_AURA_DURATION_COLOR)
	local countTextKey = buildDefaultAuraTextStyleKey(kind, "Count", DEFAULT_AURA_COUNT_COLOR)

	entry.styleVersion = styleVersion
	entry.fontVersion = fontVersion
	entry.kind = kind
	entry.size = size
	entry.shape = shape
	entry.zoom = zoom
	entry.borderKey = borderKey
	entry.borderSize = getDefaultAuraBorderSize(nil, kind)
	entry.borderOffset = getDefaultAuraBorderOffset(nil, kind)
	entry.drawSwipe = getDefaultAuraDrawSwipe(kind)
	entry.drawEdge = getDefaultAuraDrawEdge(kind)
	entry.cooldownReverse = getDefaultAuraCooldownReverse(kind)
	entry.durationTextProfile = getDefaultAuraDurationTextProfile(kind)
	entry.durationTextVersion = addon.DurationText and addon.DurationText.version or 0
	entry.countEnabled = getDefaultAuraDBValue(kind, "CountEnabled") ~= false
	entry.useDebuffTypeBorderColor = useDebuffTypeBorderColor
	entry.useOriginalBorderColor = useOriginalBorderColor
	entry.dynamicBorderColor = dynamicBorderColor
	entry.updateStyleOnAura = shouldUpdateDefaultAuraStyleForAura(entry)
	entry.color = color
	entry.colorKey = colorKey
	entry.iconDarkMode = iconDarkMode
	entry.iconDarkness = iconDarkness
	entry.iconAlpha = iconAlpha
	entry.iconDesaturate = iconDesaturate
	entry.hasCustomBorder = not isNoAuraBorder(borderKey)
	entry.hideCountdownNumbers = getDefaultAuraDBValue(kind, "DurationEnabled") == false
	entry.durationTextKey = durationTextKey
	entry.countTextKey = countTextKey
	entry.styleKey = tostring(kind) .. ":" .. tostring(size) .. ":" .. tostring(shape) .. ":" .. tostring(zoom) .. ":" .. tostring(borderKey) .. ":" .. tostring(entry.borderSize) .. ":" .. tostring(entry.borderOffset) .. ":" .. tostring(entry.drawSwipe) .. ":" .. tostring(entry.drawEdge) .. ":" .. tostring(entry.cooldownReverse) .. ":" .. tostring(entry.durationTextProfile) .. ":" .. tostring(entry.durationTextVersion) .. ":" .. tostring(useDebuffTypeBorderColor) .. ":" .. colorKey .. ":" .. tostring(iconDarkMode) .. ":" .. tostring(iconDarkness) .. ":" .. tostring(iconAlpha) .. ":" .. tostring(iconDesaturate) .. ":" .. durationTextKey .. ":" .. countTextKey
	return entry
end

local function applyDefaultAuraTextStyle(button, config)
	if not button then return end
	local kind = button.eqolDefaultAuraKind
	config = config or getDefaultAuraStyleConfig(kind)
	local textLayer = ensureDefaultAuraTextLayer(button)
	if textLayer then
		if button.Duration and button.Duration.SetParent and button.Duration:GetParent() ~= textLayer then button.Duration:SetParent(textLayer) end
		if button.Count and button.Count.SetParent and button.Count:GetParent() ~= textLayer then button.Count:SetParent(textLayer) end
	end
	local durationEnabled = not config.hideCountdownNumbers
	applyDefaultAuraDurationTextProfile(button, config)
	if button.Cooldown and button.Cooldown.SetHideCountdownNumbers and button.eqolDefaultAuraHideCountdownNumbers ~= config.hideCountdownNumbers then
		button.Cooldown:SetHideCountdownNumbers(config.hideCountdownNumbers)
		button.eqolDefaultAuraHideCountdownNumbers = config.hideCountdownNumbers
	end
	local internalCooldownText = button.Cooldown and button.Cooldown.GetCountdownFontString and button.Cooldown:GetCountdownFontString()
	if internalCooldownText then
		if not durationEnabled then
			if internalCooldownText:IsShown() then internalCooldownText:Hide() end
		else
			setAuraFontStringStyle(internalCooldownText, "Duration", DEFAULT_AURA_DURATION_COLOR, kind)
			positionAuraFontString(internalCooldownText, button, "Duration", "BOTTOM", 0, -1, kind)
		end
	end

	setAuraFontStringStyle(button.Duration, "Duration", DEFAULT_AURA_DURATION_COLOR, kind)
	positionAuraFontString(button.Duration, button, "Duration", "BOTTOM", 0, -1, kind)
	if button.Duration:IsShown() then button.Duration:Hide() end

	setAuraFontStringStyle(button.Count, "Count", DEFAULT_AURA_COUNT_COLOR, kind)
	positionAuraFontString(button.Count, button, "Count", "TOPRIGHT", -1, -1, kind)
end

local function setDefaultAuraCooldownDuration(button, startTime, duration)
	if not (button and button.Cooldown and startTime and duration) then return false end
	local kind = button.eqolDefaultAuraKind
	if button.Cooldown.SetReverse then button.Cooldown:SetReverse(getDefaultAuraCooldownReverse(kind)) end
	if button.Cooldown.SetDrawEdge then button.Cooldown:SetDrawEdge(getDefaultAuraDrawEdge(kind)) end
	if button.Cooldown.SetCooldownFromDurationObject and C_DurationUtil and C_DurationUtil.CreateDuration then
		local durationObject = button.eqolDefaultAuraDurationObject
		if not durationObject then
			durationObject = C_DurationUtil.CreateDuration()
			button.eqolDefaultAuraDurationObject = durationObject
		end
		durationObject:SetTimeFromStart(startTime, duration)
		button.Cooldown:SetCooldownFromDurationObject(durationObject)
		return true
	end
	CooldownFrame_Set(button.Cooldown, startTime, duration, true, getDefaultAuraDrawEdge(kind))
	return true
end

isNoAuraBorder = function(value)
	if addon.IconShape and addon.IconShape.IsNoBorder then return addon.IconShape.IsNoBorder(value) end
	return type(value) == "string" and strupper(value) == "NONE"
end

local function isBackdropAuraBorderCompatible(shape)
	if addon.IconShape and addon.IconShape.IsBackdropBorderCompatible then return addon.IconShape.IsBackdropBorderCompatible(shape) end
	shape = normalizeAuraIconShape(shape)
	return shape == "DEFAULT" or shape == "SQUARE"
end

local function resolveAuraBackdropBorder(borderKey)
	if not borderKey or borderKey == "" or isNoAuraBorder(borderKey) then return nil end
	if borderKey == "DEFAULT" then return DEFAULT_AURA_BACKDROP_BORDER end
	if addon.functions and addon.functions.GetLSMMediaHash then
		local media = addon.functions.GetLSMMediaHash("border")
		if type(media) == "table" and type(media[borderKey]) == "string" and media[borderKey] ~= "" then return media[borderKey] end
	end
	return borderKey
end

local function ensureDefaultAuraWatcher()
	if DAC.variables.defaultAuraWatcher then return DAC.variables.defaultAuraWatcher end
	local watcher = CreateFrame("Frame")
	watcher:SetScript("OnEvent", function()
		if DAC.variables.pendingDefaultAuraCombat then
			DAC.variables.pendingDefaultAuraCombat = nil
			if DAC.functions and DAC.functions.RefreshDefaultAuraIconSkin then DAC.functions.RefreshDefaultAuraIconSkin() end
		end
		if not DAC.variables.pendingDefaultAuraCombat then watcher:UnregisterEvent("PLAYER_REGEN_ENABLED") end
	end)
	DAC.variables.defaultAuraWatcher = watcher
	return watcher
end

local function applyDefaultAuraBackdropBorder(button, icon, borderKey, color, config)
	if not (button and icon and addon.functions and addon.functions.SetSafeBorder) then return false end
	if not resolveAuraBackdropBorder(borderKey) then return false end
	config = config or getDefaultAuraStyleConfig(button.eqolDefaultAuraKind)
	local size = config.borderSize
	local offset = config.borderOffset
	local border = button.eqolDefaultAuraBackdropBorder
	if not border then
		border = CreateFrame("Frame", nil, button)
		button.eqolDefaultAuraBackdropBorder = border
	end
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", icon, "TOPLEFT", -offset, offset)
	border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", offset, -offset)
	border:SetFrameLevel((button:GetFrameLevel() or 1) + 4)

	addon.functions.SetSafeBorder(border, true, borderKey, size, color[1], color[2], color[3], color[4], {
		defaultTexture = DEFAULT_AURA_BACKDROP_BORDER,
		mediaType = "border",
		stateKey = "_eqolDefaultAuraSafeBorder",
	})
	ensureDefaultAuraTextLayer(button)
	return true
end

local function applyDefaultAuraShapeBorder(button, icon, borderKey, shape, color, config)
	if not (addon.IconShape and addon.IconShape.ApplyBorder and button and icon) then return false end
	config = config or getDefaultAuraStyleConfig(button.eqolDefaultAuraKind)
	local applied = addon.IconShape.ApplyBorder(button, borderKey, shape, {
		allowNone = true,
		emptyValue = addon.IconShape.BORDER and addon.IconShape.BORDER.NONE or "NONE",
		pointFrame = icon,
		borderSize = config.borderSize,
		borderOffset = config.borderOffset,
		color = color,
		texturesKey = "_eqolDefaultAuraShapeBorderTextures",
		drawLayer = "OVERLAY",
		subLevel = 6,
	})
	ensureDefaultAuraTextLayer(button)
	return applied
end

local function ensureDefaultAuraButtonVisuals(button)
	if not button or button.eqolDefaultAuraVisualsReady then return end
	button.eqolDefaultAuraVisualsReady = true
	button:SetScript("OnEnter", function(self)
		local targetSlot = self:GetAttribute("target-slot")
		if targetSlot then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetInventoryItem("player", targetSlot)
			return
		end
		local unit = self.eqolAuraUnit or "player"
		local auraInstanceID = self.eqolAuraInstanceID
		if not auraInstanceID then return end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)

	button.Icon = button.Icon or button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetAllPoints(button)
	if not button.Icon.GetTexture or not button.Icon:GetTexture() then button.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end

	button.Cooldown = button.Cooldown or CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.Cooldown:SetAllPoints(button)
	if button.Cooldown.SetDrawEdge then button.Cooldown:SetDrawEdge(getDefaultAuraDrawEdge(button.eqolDefaultAuraKind)) end
	if button.Cooldown.SetReverse then button.Cooldown:SetReverse(getDefaultAuraCooldownReverse(button.eqolDefaultAuraKind)) end
	if button.Cooldown.SetDrawSwipe then button.Cooldown:SetDrawSwipe(getDefaultAuraDrawSwipe(button.eqolDefaultAuraKind)) end
	if button.Cooldown.SetHideCountdownNumbers then button.Cooldown:SetHideCountdownNumbers(false) end
	button.Cooldown:SetSwipeColor(0, 0, 0, 0.65)

	local textLayer = ensureDefaultAuraTextLayer(button) or button
	button.Count = button.Count or textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	button.Duration = button.Duration or textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Duration:SetPoint("TOP", button, "BOTTOM", 0, -1)
	button.Duration:SetTextColor(1, 0.82, 0)
	applyDefaultAuraTextStyle(button)
end

local function clearDefaultAuraCustomBorder(button)
	if not button then return end
	if button.eqolDefaultAuraBackdropBorder then
		if addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(button.eqolDefaultAuraBackdropBorder, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolDefaultAuraSafeBorder" })
		else
			button.eqolDefaultAuraBackdropBorder:Hide()
		end
	end
	if addon.IconShape and addon.IconShape.HideBorderTextures then
		addon.IconShape.HideBorderTextures(button, { texturesKey = "_eqolDefaultAuraShapeBorderTextures" })
	end
end

local function applyDefaultAuraCooldownSwipeVisual(button, config, force)
	if not (button and addon.IconShape and addon.IconShape.ApplyCooldownSwipeVisual) then return end
	local key = config and config.styleKey or button.eqolDefaultAuraStyleKey
	if not force and button.eqolDefaultAuraCooldownSwipeVisualKey == key then return end
	addon.IconShape.ApplyCooldownSwipeVisual(button.Cooldown, button, nil, nil, { customColor = false })
	button.eqolDefaultAuraCooldownSwipeVisualKey = key
end

local function applyDefaultAuraButtonStyle(button, force, config)
	if not button then return end
	ensureDefaultAuraButtonVisuals(button)
	local icon = button.Icon or button.icon
	if not icon then return end

	config = config or getDefaultAuraStyleConfig(button.eqolDefaultAuraKind)
	local color = resolveDefaultAuraBorderColorFromConfig(button, config)
	local styleKey = config.styleKey
	if not force and button.eqolDefaultAuraStyleKey == styleKey then return end
	button.eqolDefaultAuraStyleKey = styleKey

	if force and not (InCombatLockdown and InCombatLockdown()) then button:SetSize(config.size, config.size) end
	button.Icon:SetAllPoints(button)
	button.Cooldown:SetAllPoints(button)
	if button.Cooldown.SetDrawSwipe then button.Cooldown:SetDrawSwipe(config.drawSwipe) end
	if button.Cooldown.SetDrawEdge then button.Cooldown:SetDrawEdge(config.drawEdge) end
	if button.Cooldown.SetReverse then button.Cooldown:SetReverse(config.cooldownReverse) end
	if button.Cooldown.SetHideCountdownNumbers then button.Cooldown:SetHideCountdownNumbers(config.hideCountdownNumbers) end
	applyDefaultAuraTextStyle(button, config)

	if addon.IconShape and addon.IconShape.ApplyFrameShape then
		addon.IconShape.ApplyFrameShape(button, config.shape, {
			textures = { icon },
			cooldown = button.Cooldown or button.cooldown,
			iconZoom = config.zoom,
			textureMaskKey = "_eqolDefaultAuraIconMask",
			textureTexCoordKey = "_eqolDefaultAuraIconTexCoord",
			maskKey = "_eqolDefaultAuraMask",
			refreshSwipe = function(owner)
				applyDefaultAuraCooldownSwipeVisual(owner, config, true)
			end,
		})
	elseif icon.SetTexCoord then
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
	applyDefaultAuraIconDarkMode(button, config)

	clearDefaultAuraCustomBorder(button)
	if config.hasCustomBorder then
		if isBackdropAuraBorderCompatible(config.shape) then
			applyDefaultAuraBackdropBorder(button, icon, config.borderKey, color, config)
		else
			applyDefaultAuraShapeBorder(button, icon, config.borderKey, config.shape, color, config)
		end
	end
end

local function updateDefaultAuraDynamicBorderColor(button, config)
	if not (button and config and config.updateStyleOnAura and config.hasCustomBorder) then return end
	local icon = button.Icon or button.icon
	if not icon then return end
	local color = resolveDefaultAuraBorderColorFromConfig(button, config)
	if isBackdropAuraBorderCompatible(config.shape) then
		local border = button.eqolDefaultAuraBackdropBorder
		if border and addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(border, true, config.borderKey, config.borderSize, color[1], color[2], color[3], color[4], {
				defaultTexture = DEFAULT_AURA_BACKDROP_BORDER,
				mediaType = "border",
				stateKey = "_eqolDefaultAuraSafeBorder",
			})
		end
	elseif addon.IconShape and addon.IconShape.ApplyBorder then
		applyDefaultAuraShapeBorder(button, icon, config.borderKey, config.shape, color, config)
	end
end

local function resolveDefaultTempEnchantIcon(slot)
	local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", slot)
	if texture then return texture end
	local itemLink = GetInventoryItemLink and GetInventoryItemLink("player", slot)
	if itemLink and C_Item then
		if C_Item.GetItemIconByID then
			texture = C_Item.GetItemIconByID(itemLink)
			if texture then return texture end
		end
		if C_Item.GetItemInfoInstant then
			texture = select(5, C_Item.GetItemInfoInstant(itemLink))
			if texture then return texture end
		end
	end
	local itemID = GetInventoryItemID and GetInventoryItemID("player", slot)
	if itemID and C_Item then
		if C_Item.GetItemIconByID then
			texture = C_Item.GetItemIconByID(itemID)
			if texture then return texture end
		end
		if C_Item.GetItemInfoInstant then
			texture = select(5, C_Item.GetItemInfoInstant(itemID))
			if texture then return texture end
		end
	end
	return nil
end

local function updateDefaultTempEnchantButton(button, kind, slot)
	if not button or not button:IsShown() then return end
	button.eqolDefaultAuraKind = normalizeDefaultAuraKind(kind)
	ensureDefaultAuraButtonVisuals(button)
	if not button.eqolDefaultAuraStyleKey then applyDefaultAuraButtonStyle(button, true) end

	slot = slot or button.eqolDefaultAuraTargetSlot or button:GetAttribute("target-slot")
	if not slot then return end

	local mainSlot = GetInventorySlotInfo and GetInventorySlotInfo("MainHandSlot")
	local offSlot = GetInventorySlotInfo and GetInventorySlotInfo("SecondaryHandSlot")
	local hasEnchant, expirationMS, charges
	if slot == mainSlot then
		hasEnchant, expirationMS, charges = GetWeaponEnchantInfo()
	elseif slot == offSlot then
		hasEnchant, expirationMS, charges = select(5, GetWeaponEnchantInfo())
	else
		hasEnchant, expirationMS, charges = false, nil, nil
	end
	if issecretvalue and issecretvalue(expirationMS) then expirationMS = nil end
	if issecretvalue and issecretvalue(charges) then charges = nil end

	if not hasEnchant then
		button.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		button.Count:Hide()
		button.Duration:Hide()
		button.Cooldown:Hide()
		button.eqolAuraInstanceID = nil
		return
	end

	local texture = resolveDefaultTempEnchantIcon(slot)
	button.Icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
	button.eqolAuraUnit = "player"
	button.eqolAuraInstanceID = nil
	local config = getDefaultAuraStyleConfig(kind)
	local chargeText = charges and charges > 0 and tostring(charges) or ""
	button.Count:SetText(chargeText)
	button.Count:SetShown(config.countEnabled and chargeText ~= "")

	local timeLeft = (tonumber(expirationMS) or 0) / 1000
	if timeLeft > 0 then
		setDefaultAuraCooldownDuration(button, GetTime(), timeLeft)
		applyDefaultAuraCooldownSwipeVisual(button, config)
		button.Cooldown:Show()
	else
		button.Cooldown:Hide()
		button.Duration:Hide()
	end

	if GameTooltip:IsOwned(button) then GameTooltip:SetInventoryItem("player", slot) end
end

local function applyDefaultAuraDataToButton(button, unit, kind, aura)
	if not (button and aura) then return end
	ensureDefaultAuraButtonVisuals(button)
	local config = getDefaultAuraStyleConfig(kind)
	button.eqolAuraUnit = unit
	button.eqolAuraInstanceID = aura.auraInstanceID
	if not button.eqolDefaultAuraStyleKey then
		applyDefaultAuraButtonStyle(button, true, config)
	elseif config.updateStyleOnAura then
		updateDefaultAuraDynamicBorderColor(button, config)
	end

	button.Icon:SetTexture(aura.icon)

	local countText = ""
	if C_UnitAuras.GetAuraApplicationDisplayCount and aura.auraInstanceID then
		countText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, aura.auraInstanceID, 2) or ""
	end
	button.Count:SetText(countText)
	button.Count:SetShown(config.countEnabled)

	local auraDuration
	if C_UnitAuras.GetAuraDuration and aura.auraInstanceID then
		auraDuration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
	end
	if auraDuration and button.Cooldown.SetCooldownFromDurationObject then
		button.Duration:Hide()
		button.Cooldown:SetCooldownFromDurationObject(auraDuration)
		applyDefaultAuraCooldownSwipeVisual(button, config)
		button.Cooldown:Show()
	else
		button.Cooldown:Hide()
		button.Duration:Hide()
	end

	if GameTooltip:IsOwned(button) and aura.auraInstanceID then GameTooltip:SetUnitAuraByAuraInstanceID(unit, aura.auraInstanceID) end
end

local function updateDefaultAuraButton(button, index)
	if not button or not button:IsShown() then return end
	local kind = button.eqolDefaultAuraKind or "buff"
	local unit = button.eqolDefaultAuraUnit or "player"
	local filter = button.eqolDefaultAuraFilter or (kind == "debuff" and "HARMFUL" or "HELPFUL")
	if button.eqolDefaultAuraTargetSlot then
		updateDefaultTempEnchantButton(button, kind, button.eqolDefaultAuraTargetSlot)
		return
	end
	ensureDefaultAuraButtonVisuals(button)
	if not button.eqolDefaultAuraStyleKey then applyDefaultAuraButtonStyle(button, true) end

	index = index or button.eqolDefaultAuraIndex or button:GetAttribute("index") or button:GetID()
	local aura
	if index and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
	end
	if not aura then
		button.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		button.Count:Hide()
		button.Duration:Hide()
		button.eqolAuraInstanceID = nil
		return
	end

	applyDefaultAuraDataToButton(button, unit, kind, aura)
end

local function forEachDefaultAuraHeaderChild(header, func, ...)
	if not (header and func) then return end
	local index = 1
	local child = header:GetAttribute("child" .. index)
	while child do
		func(child, ...)
		index = index + 1
		child = header:GetAttribute("child" .. index)
	end
	index = 1
	child = header:GetAttribute("tempEnchant" .. index)
	while child do
		func(child, ...)
		index = index + 1
		child = header:GetAttribute("tempEnchant" .. index)
	end
end

local function applyDefaultAuraHeaderContextToButton(button, header)
	if not (button and header) then return end
	button.eqolDefaultAuraKind = header.eqolDefaultAuraKind
	button.eqolDefaultAuraFilter = header.eqolDefaultAuraFilter
	button.eqolDefaultAuraUnit = header.eqolDefaultAuraUnit or "player"
	button.eqolDefaultAuraTargetSlot = button:GetAttribute("target-slot")
end

local function updateDefaultAuraButtonFromAttribute(button, attr, value)
	if not button then return end
	if attr == "index" then
		button.eqolDefaultAuraIndex = value
		button.eqolDefaultAuraTargetSlot = nil
		updateDefaultAuraButton(button, value)
	elseif attr == "target-slot" then
		button.eqolAuraInstanceID = nil
		button.eqolDefaultAuraTargetSlot = value
		button.eqolDefaultAuraIndex = nil
		updateDefaultTempEnchantButton(button, button.eqolDefaultAuraKind, value)
	end
end

local function ensureDefaultAuraButtonAttributeHook(button, header)
	if not button then return end
	applyDefaultAuraHeaderContextToButton(button, header)
	if button.eqolDefaultAuraAttributeHooked then return end
	button.eqolDefaultAuraAttributeHooked = true
	ensureDefaultAuraButtonVisuals(button)
	button:HookScript("OnAttributeChanged", updateDefaultAuraButtonFromAttribute)
end

local function handleDefaultAuraHeaderAttributeChanged(header, attr, value)
	if type(attr) ~= "string" then return end
	if attr == "unit" then
		header.eqolDefaultAuraUnit = value or "player"
		forEachDefaultAuraHeaderChild(header, applyDefaultAuraHeaderContextToButton, header)
		return
	end
	if not (attr:match("^child%d+$") or attr:match("^temp[Ee]nchant%d+$")) then return end
	if type(value) == "userdata" and GetFrameHandleFrame then value = GetFrameHandleFrame(value) end
	if value then
		ensureDefaultAuraButtonAttributeHook(value, header)
		if value:GetAttribute("index") then
			updateDefaultAuraButtonFromAttribute(value, "index", value:GetAttribute("index"))
		elseif value:GetAttribute("target-slot") then
			updateDefaultAuraButtonFromAttribute(value, "target-slot", value:GetAttribute("target-slot"))
		end
	end
end

local function applyDefaultAuraHeaderButtonStyles(header, force)
	if not header then return end
	forEachDefaultAuraHeaderChild(header, function(child)
		ensureDefaultAuraButtonAttributeHook(child, header)
		applyDefaultAuraButtonStyle(child, force)
	end)
end

local function updateDefaultAuraHeaderButtons(header)
	if not header then return end
	forEachDefaultAuraHeaderChild(header, function(child)
		ensureDefaultAuraButtonAttributeHook(child, header)
		updateDefaultAuraButton(child, child:GetAttribute("index"))
	end)
end

local function configureDefaultAuraHeader(header, filter, kind)
	kind = normalizeDefaultAuraKind(kind)
	header.eqolDefaultAuraKind = kind
	header.eqolDefaultAuraFilter = filter
	header.eqolDefaultAuraUnit = "player"
	local size = getDefaultAuraIconSize(nil, kind)
	local horizontalSpacing = getDefaultAuraHorizontalSpacing(nil, kind)
	local verticalSpacing = getDefaultAuraVerticalSpacing(nil, kind)
	local perRow = getDefaultAuraIconsPerRow(nil, kind)
	local maxRows = getDefaultAuraMaxRows(nil, kind)
	local primary, _, primaryHorizontal, startPoint = getDefaultAuraGrowthLayout(kind)
	local layoutWidth, layoutHeight = getDefaultAuraLayoutSize(kind, size, horizontalSpacing, verticalSpacing, perRow, maxRows)
	local wrapAfter = primaryHorizontal and perRow or maxRows
	local maxWraps = primaryHorizontal and maxRows or perRow
	header:SetAttribute("unit", "player")
	header.eqolDefaultAuraUnit = "player"
	header:SetAttribute("filter", filter)
	header:SetAttribute("template", "SecureAuraButtonTemplate")
	header:SetAttribute("weaponTemplate", filter == "HELPFUL" and "SecureAuraButtonTemplate" or nil)
	header:SetAttribute("config-width", size)
	header:SetAttribute("config-height", size)
	header:SetAttribute("initialConfigFunction", DEFAULT_AURA_INITIAL_CONFIG)
	header:SetAttribute("sortMethod", normalizeDefaultAuraSortMethod(getDefaultAuraDBValue(kind, "SortMethod")))
	header:SetAttribute("sortDirection", normalizeDefaultAuraSortDirection(getDefaultAuraDBValue(kind, "SortDirection")))
	header:SetAttribute("wrapAfter", wrapAfter)
	header:SetAttribute("maxWraps", maxWraps)
	header:SetAttribute("point", startPoint)
	header:SetAttribute("xOffset", primaryHorizontal and ((primary == "LEFT" and -1 or 1) * (size + horizontalSpacing)) or 0)
	header:SetAttribute("yOffset", primaryHorizontal and 0 or ((primary == "UP" and 1 or -1) * (size + verticalSpacing)))
	header:SetAttribute("wrapXOffset", primaryHorizontal and 0 or ((startPoint:find("RIGHT", 1, true) and -1 or 1) * (size + horizontalSpacing)))
	header:SetAttribute("wrapYOffset", primaryHorizontal and ((startPoint:find("BOTTOM", 1, true) and 1 or -1) * (size + verticalSpacing)) or 0)
	header:SetAttribute("minWidth", layoutWidth)
	header:SetAttribute("minHeight", layoutHeight)
	if filter == "HELPFUL" then
		header:SetAttribute("includeWeapons", getDefaultAuraDBValue(kind, "IncludeWeapons") == true and 1 or 0)
	end
	header:SetSize(layoutWidth, layoutHeight)
	applyDefaultAuraHeaderButtonStyles(header, true)
	updateDefaultAuraHeaderButtons(header)
end

local function createDefaultAuraHeader(kind, filter)
	local name = kind == "buff" and "EnhanceQoLCustomBuffFrame" or "EnhanceQoLCustomDebuffFrame"
	local header = _G[name] or CreateFrame("Frame", name, UIParent, "SecureAuraHeaderTemplate")
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	if tonumber((select(4, GetBuildInfo()))) >= 120100 and type(header.SetRolesets) == "function" then header:SetRolesets("buffs") end
	header:SetClampedToScreen(true)
	if RegisterAttributeDriver then RegisterAttributeDriver(header, "unit", "[vehicleui] vehicle; player") end
	if not header.eqolDefaultAuraHooksInstalled then
		header.eqolDefaultAuraHooksInstalled = true
		header:HookScript("OnAttributeChanged", handleDefaultAuraHeaderAttributeChanged)
		header:HookScript("OnShow", updateDefaultAuraHeaderButtons)
	end
	configureDefaultAuraHeader(header, filter, kind)
	return header
end

local function ensureDefaultAuraAnchor(kind)
	local isBuff = kind == "buff"
	local key = isBuff and "defaultBuffAnchor" or "defaultDebuffAnchor"
	local name = isBuff and "EnhanceQoLCustomBuffFrameAnchor" or "EnhanceQoLCustomDebuffFrameAnchor"
	local anchor = DAC.variables[key] or _G[name] or CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	if tonumber((select(4, GetBuildInfo()))) >= 120100 and type(anchor.SetRolesets) == "function" then anchor:SetRolesets("buffs") end
	DAC.variables[key] = anchor
	local size = getDefaultAuraIconSize(nil, kind)
	local horizontalSpacing = getDefaultAuraHorizontalSpacing(nil, kind)
	local verticalSpacing = getDefaultAuraVerticalSpacing(nil, kind)
	local perRow = getDefaultAuraIconsPerRow(nil, kind)
	local maxRows = getDefaultAuraMaxRows(nil, kind)
	anchor:SetSize(getDefaultAuraLayoutSize(kind, size, horizontalSpacing, verticalSpacing, perRow, maxRows))
	anchor:SetFrameStrata(normalizeDefaultAuraFrameStrata(getDefaultAuraDBValue(kind, "FrameStrata")))
	anchor:SetFrameLevel(getDefaultAuraFrameLevel(nil, kind))
	if anchor.SetClampedToScreen then anchor:SetClampedToScreen(true) end
	if anchor.SetClampRectInsets then anchor:SetClampRectInsets(0, 0, 0, 0) end
	anchor:SetMovable(true)
	anchor:EnableMouse(false)
	return anchor
end

local function attachDefaultAuraHeaderToAnchor(header, anchor)
	if not (header and anchor) then return end
	if header:GetParent() ~= anchor then header:SetParent(anchor) end
	header:ClearAllPoints()
	if header.eqolNativeAuraContainer then
		header:SetAllPoints(anchor)
		header:SetFrameStrata(anchor:GetFrameStrata())
		header:SetFrameLevel((anchor:GetFrameLevel() or 1) + 1)
		return
	end
	local kind = header.eqolDefaultAuraKind or "buff"
	local _, _, _, startPoint = getDefaultAuraGrowthLayout(kind)
	header:SetPoint(startPoint, anchor, startPoint, 0, 0)
	header:SetFrameStrata(anchor:GetFrameStrata())
	header:SetFrameLevel((anchor:GetFrameLevel() or 1) + 1)
end

local SAMPLE_AURA_ICONS = {
	"Interface\\Icons\\Spell_Holy_WordFortitude",
	"Interface\\Icons\\Spell_Nature_Rejuvenation",
	"Interface\\Icons\\Spell_Holy_Renew",
	"Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	"Interface\\Icons\\Spell_Fire_FlameShock",
	"Interface\\Icons\\Spell_Nature_Regeneration",
	"Interface\\Icons\\Spell_Holy_PrayerOfMendingtga",
	"Interface\\Icons\\Spell_Nature_ResistNature",
	"Interface\\Icons\\Spell_Holy_SealOfSalvation",
	"Interface\\Icons\\Spell_Magic_GreaterBlessingOfKings",
	"Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
	"Interface\\Icons\\Spell_Shadow_CurseOfTounges",
	"Interface\\Icons\\Spell_Shadow_AbominationExplosion",
	"Interface\\Icons\\Spell_Frost_ChainsOfIce",
	"Interface\\Icons\\Spell_Nature_StrangleVines",
	"Interface\\Icons\\Ability_Creature_Cursed_02",
	"Interface\\Icons\\Spell_Shadow_Possession",
	"Interface\\Icons\\Spell_Shadow_PlagueCloud",
	"Interface\\Icons\\Spell_Fire_Incinerate",
	"Interface\\Icons\\Spell_Nature_CorrosiveBreath",
}

local function hideDefaultAuraSamples(kind)
	kind = normalizeDefaultAuraKind(kind)
	local anchor = DAC.variables[kind == "debuff" and "defaultDebuffAnchor" or "defaultBuffAnchor"]
	local samples = anchor and anchor.eqolDefaultAuraSamples
	if samples then
		for i = 1, #samples do samples[i]:Hide() end
	end
	local header = DAC.variables[kind == "debuff" and "defaultDebuffHeader" or "defaultBuffHeader"]
	local enabled = addon.db and ((kind == "debuff" and addon.db.skinnerDefaultDebuffIconsEnabled == true) or (kind == "buff" and addon.db.skinnerDefaultBuffIconsEnabled == true))
	if header and enabled then header:Show() end
end

local function refreshDefaultAuraSamples(kind)
	kind = normalizeDefaultAuraKind(kind)
	local anchor = DAC.variables[kind == "debuff" and "defaultDebuffAnchor" or "defaultBuffAnchor"]
	if not (anchor and anchor.eqolDefaultAuraSamplesEnabled) then return end
	local header = DAC.variables[kind == "debuff" and "defaultDebuffHeader" or "defaultBuffHeader"]
	if header then header:Hide() end
	local samples = anchor.eqolDefaultAuraSamples
	if not samples then
		samples = {}
		anchor.eqolDefaultAuraSamples = samples
	end

	local size = getDefaultAuraIconSize(nil, kind)
	local horizontalSpacing = getDefaultAuraHorizontalSpacing(nil, kind)
	local perRow = getDefaultAuraIconsPerRow(nil, kind)
	local verticalSpacing = getDefaultAuraVerticalSpacing(nil, kind)
	local maxRows = getDefaultAuraMaxRows(nil, kind)
	local primary, _, primaryHorizontal, startPoint = getDefaultAuraGrowthLayout(kind)
	local count = perRow * maxRows
	for i = 1, count do
		local sample = samples[i]
		if not sample then
			sample = CreateFrame("Frame", nil, anchor)
			sample.Icon = sample:CreateTexture(nil, "ARTWORK")
			sample.Icon:SetAllPoints(sample)
			sample.Cooldown = CreateFrame("Cooldown", nil, sample, "CooldownFrameTemplate")
			sample.Cooldown:SetAllPoints(sample)
			sample.Count = sample:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			sample.Duration = sample:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			samples[i] = sample
		end
		sample.eqolDefaultAuraKind = kind
		sample.eqolAuraUnit = nil
		sample.eqolAuraInstanceID = nil
		if sample.SetFrameStrata then sample:SetFrameStrata(anchor:GetFrameStrata()) end
		if sample.SetFrameLevel then sample:SetFrameLevel((anchor:GetFrameLevel() or 1) + 1) end
		sample.Icon:SetTexture(SAMPLE_AURA_ICONS[((i - 1) % #SAMPLE_AURA_ICONS) + 1] or "Interface\\Icons\\INV_Misc_QuestionMark")
		local showCount = getDefaultAuraDBValue(kind, "CountEnabled") ~= false and (i == 1 or i == 6 or i == 13)
		sample.Count:SetText(showCount and tostring((i % 4) + 2) or "")
		sample.Count:SetShown(showCount)
		setDefaultAuraCooldownDuration(sample, GetTime() - i, 30 + i * 8)
		sample:ClearAllPoints()
		sample:SetSize(size, size)
		local column, row
		if primaryHorizontal then
			column = (i - 1) % perRow
			row = math.floor((i - 1) / perRow)
		else
			column = math.floor((i - 1) / maxRows)
			row = (i - 1) % maxRows
		end
		local xOffset, yOffset
		if primaryHorizontal then
			xOffset = column * (primary == "LEFT" and -1 or 1) * (size + horizontalSpacing)
			yOffset = row * (startPoint:find("BOTTOM", 1, true) and 1 or -1) * (size + verticalSpacing)
		else
			xOffset = column * (startPoint:find("RIGHT", 1, true) and -1 or 1) * (size + horizontalSpacing)
			yOffset = row * (primary == "UP" and 1 or -1) * (size + verticalSpacing)
		end
		sample:SetPoint(startPoint, anchor, startPoint, xOffset, yOffset)
		applyDefaultAuraButtonStyle(sample, true)
		sample:Show()
	end
	for i = count + 1, #samples do samples[i]:Hide() end
end

local function toggleDefaultAuraSamples(kind)
	kind = normalizeDefaultAuraKind(kind)
	local anchor = DAC.variables[kind == "debuff" and "defaultDebuffAnchor" or "defaultBuffAnchor"]
	if not anchor then return end
	anchor.eqolDefaultAuraSamplesEnabled = not anchor.eqolDefaultAuraSamplesEnabled
	if anchor.eqolDefaultAuraSamplesEnabled then
		refreshDefaultAuraSamples(kind)
	else
		hideDefaultAuraSamples(kind)
	end
end

local function hideBlizzardAuraFrame(frame)
	if not (frame and frame.Hide) then return end
	if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end
	frame.eqolDefaultAuraHiddenByDefaultAuraContainers = true
	frame:Hide()
end

local function markDefaultAuraReloadRequired()
	addon.variables = addon.variables or {}
	addon.variables.requireReload = true
	if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
end

local function applyDefaultAuraEditModeSetting(kind, field, value)
	kind = normalizeDefaultAuraKind(kind)
	if field == "shape" then
		local shape = normalizeAuraIconShape(value)
		setDefaultAuraDBValue(kind, "IconShape", shape)
		setDefaultAuraDBValue(kind, "BorderTexture", normalizeAuraBorder(getDefaultAuraDBValue(kind, "BorderTexture"), shape))
	elseif field == "zoom" then
		setDefaultAuraDBValue(kind, "IconZoom", normalizeAuraIconZoom(value))
	elseif field == "iconDarkMode" then
		setDefaultAuraDBValue(kind, "IconDarkMode", value == true)
	elseif field == "iconDarkness" then
		setDefaultAuraDBValue(kind, "IconDarkness", normalizeAuraIconDarkness(value))
	elseif field == "iconAlpha" then
		setDefaultAuraDBValue(kind, "IconAlpha", normalizeAuraIconAlpha(value))
	elseif field == "iconDesaturate" then
		setDefaultAuraDBValue(kind, "IconDesaturate", value == true)
	elseif field == "size" then
		setDefaultAuraDBValue(kind, "IconSize", getDefaultAuraIconSize(value, kind))
	elseif field == "horizontalSpacing" then
		setDefaultAuraDBValue(kind, "HorizontalSpacing", getDefaultAuraHorizontalSpacing(value, kind))
	elseif field == "verticalSpacing" then
		setDefaultAuraDBValue(kind, "VerticalSpacing", getDefaultAuraVerticalSpacing(value, kind))
	elseif field == "drawSwipe" then
		local enabled = value == true
		setDefaultAuraDBValue(kind, "CooldownDrawSwipe", enabled)
		if not enabled then setDefaultAuraDBValue(kind, "CooldownReverse", false) end
	elseif field == "drawEdge" then
		setDefaultAuraDBValue(kind, "CooldownDrawEdge", value == true)
	elseif field == "cooldownReverse" then
		setDefaultAuraDBValue(kind, "CooldownReverse", value == true and getDefaultAuraDrawSwipe(kind))
	elseif field == "perRow" then
		setDefaultAuraDBValue(kind, "IconsPerRow", getDefaultAuraIconsPerRow(value, kind))
	elseif field == "maxRows" then
		setDefaultAuraDBValue(kind, "MaxRows", getDefaultAuraMaxRows(value, kind))
	elseif field == "growth" then
		setDefaultAuraDBValue(kind, "Growth", normalizeDefaultAuraGrowth(value))
	elseif field == "frameStrata" then
		setDefaultAuraDBValue(kind, "FrameStrata", normalizeDefaultAuraFrameStrata(value))
	elseif field == "frameLevel" then
		setDefaultAuraDBValue(kind, "FrameLevel", getDefaultAuraFrameLevel(value, kind))
	elseif field == "sortMethod" then
		setDefaultAuraDBValue(kind, "SortMethod", normalizeDefaultAuraSortMethod(value))
	elseif field == "sortDirection" then
		setDefaultAuraDBValue(kind, "SortDirection", normalizeDefaultAuraSortDirection(value))
	elseif field == "includeWeapons" then
		setDefaultAuraDBValue(kind, "IncludeWeapons", value == true)
	elseif field == "border" then
		local shape = normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape"))
		setDefaultAuraDBValue(kind, "BorderTexture", normalizeAuraBorder(value, shape))
	elseif field == "borderSize" then
		setDefaultAuraDBValue(kind, "BorderSize", getDefaultAuraBorderSize(value, kind))
	elseif field == "borderOffset" then
		setDefaultAuraDBValue(kind, "BorderOffset", getDefaultAuraBorderOffset(value, kind))
	elseif field == "useOriginalBorderColor" then
		setDefaultAuraDBValue(kind, "UseOriginalBorderColor", value == true)
	elseif field == "useDebuffTypeBorderColor" then
		setDefaultAuraDBValue(kind, "UseDebuffTypeBorderColor", value == true)
	elseif field == "borderColor" then
		setDefaultAuraDBValue(kind, "BorderColor", value)
	elseif field == "durationEnabled" then
		setDefaultAuraDBValue(kind, "DurationEnabled", value == true)
	elseif field == "durationFont" then
		setDefaultAuraDBValue(kind, "DurationFontFace", normalizeAuraFontKey(value))
	elseif field == "durationOutline" then
		setDefaultAuraDBValue(kind, "DurationFontOutline", normalizeAuraFontStyle(value))
	elseif field == "durationSize" then
		setDefaultAuraDBValue(kind, "DurationFontSize", getAuraTextSize(nil, tonumber(value) or 10))
	elseif field == "durationColor" then
		setDefaultAuraDBValue(kind, "DurationColor", normalizeAuraTextColor(value, DEFAULT_AURA_DURATION_COLOR))
	elseif field == "durationAnchor" then
		setDefaultAuraDBValue(kind, "DurationAnchor", normalizeAuraAnchorPoint(value, "BOTTOM"))
	elseif field == "durationOffsetX" then
		local offset = copyValue(getDefaultAuraDBValue(kind, "DurationOffset"))
		if type(offset) ~= "table" then offset = {} end
		offset.x = getAuraTextOffset(nil, nil, tonumber(value) or 0)
		setDefaultAuraDBValue(kind, "DurationOffset", offset)
	elseif field == "durationOffsetY" then
		local offset = copyValue(getDefaultAuraDBValue(kind, "DurationOffset"))
		if type(offset) ~= "table" then offset = {} end
		offset.y = getAuraTextOffset(nil, nil, tonumber(value) or -1)
		setDefaultAuraDBValue(kind, "DurationOffset", offset)
	elseif field == "durationTextProfile" then
		setDefaultAuraDBValue(kind, "DurationTextProfile", normalizeDefaultAuraDurationTextProfile(value))
	elseif field == "countEnabled" then
		setDefaultAuraDBValue(kind, "CountEnabled", value == true)
	elseif field == "countFont" then
		setDefaultAuraDBValue(kind, "CountFontFace", normalizeAuraFontKey(value))
	elseif field == "countOutline" then
		setDefaultAuraDBValue(kind, "CountFontOutline", normalizeAuraFontStyle(value))
	elseif field == "countSize" then
		setDefaultAuraDBValue(kind, "CountFontSize", getAuraTextSize(nil, tonumber(value) or 12))
	elseif field == "countColor" then
		setDefaultAuraDBValue(kind, "CountColor", normalizeAuraTextColor(value, DEFAULT_AURA_COUNT_COLOR))
	elseif field == "countAnchor" then
		setDefaultAuraDBValue(kind, "CountAnchor", normalizeAuraAnchorPoint(value, "TOPRIGHT"))
	elseif field == "countOffsetX" then
		local offset = copyValue(getDefaultAuraDBValue(kind, "CountOffset"))
		if type(offset) ~= "table" then offset = {} end
		offset.x = getAuraTextOffset(nil, nil, tonumber(value) or -1)
		setDefaultAuraDBValue(kind, "CountOffset", offset)
	elseif field == "countOffsetY" then
		local offset = copyValue(getDefaultAuraDBValue(kind, "CountOffset"))
		if type(offset) ~= "table" then offset = {} end
		offset.y = getAuraTextOffset(nil, nil, tonumber(value) or -1)
		setDefaultAuraDBValue(kind, "CountOffset", offset)
	elseif field == "sync" then
		addon.db["skinnerDefaultAuraSyncBuffDebuff"] = value == true
	end
	-- Runtime-created PTR7 AuraButtons become access constrained after
	-- initializeFrame returns, and registered children can no longer be
	-- re-parented. Layout and ordering live on the container and can update
	-- immediately; visual relationships are rebuilt by a reload.
	if useNativeAuraContainers and field ~= "size" and field ~= "horizontalSpacing" and field ~= "verticalSpacing" and field ~= "perRow" and field ~= "maxRows" and field ~= "growth" and field ~= "frameStrata" and field ~= "frameLevel" and field ~= "sortMethod" and field ~= "sortDirection" then
		markDefaultAuraReloadRequired()
	end
	refreshDefaultAuraIconSkin()
end

local function createDefaultAuraEditModeSettings(kind)
	kind = normalizeDefaultAuraKind(kind)
	local EditMode = addon.EditMode
	local SettingType = (EditMode and EditMode.lib and EditMode.lib.SettingType) or (addon.EditModeLib and addon.EditModeLib.SettingType)
	if not SettingType then return nil end

	local function dropdown(name, getValue, setValue, buildOptions, height, enabled, parentId)
		local function refreshSettings()
			local internal = addon.EditModeLib and addon.EditModeLib.internal
			if internal and internal.RequestRefreshSettings then internal:RequestRefreshSettings() end
		end
		return {
			name = name,
			kind = SettingType.Dropdown,
			parentId = parentId,
			height = height or 180,
			get = function() return getValue() end,
			set = function(_, value)
				setValue(value)
				refreshSettings()
			end,
			generator = function(_, root)
				for _, option in ipairs(buildOptions()) do
					root:CreateRadio(option.label, function() return getValue() == option.value end, function()
						setValue(option.value)
						refreshSettings()
					end)
				end
			end,
			isEnabled = enabled,
		}
	end

	local function slider(name, getValue, setValue, minValue, maxValue, step, enabled, parentId)
		return {
			name = name,
			kind = SettingType.Slider,
			parentId = parentId,
			minValue = minValue,
			maxValue = maxValue,
			valueStep = step or 1,
			allowInput = true,
			get = function() return getValue() end,
			set = function(_, value) setValue(value) end,
			formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
			isEnabled = enabled,
		}
	end
	local function checkbox(name, getValue, setValue, enabled, parentId)
		return {
			name = name,
			kind = SettingType.Checkbox,
			parentId = parentId,
			get = function() return getValue() end,
			set = function(_, value) setValue(value) end,
			isEnabled = enabled,
		}
	end
	local function color(name, getValue, setValue, enabled, parentId)
		return {
			name = name,
			kind = SettingType.Color,
			parentId = parentId,
			hasOpacity = true,
			get = function() return getValue() end,
			set = function(_, value) setValue(value) end,
			isEnabled = enabled,
		}
	end

	local function shapeOptions()
		return addon.IconShape and addon.IconShape.GetOptions and addon.IconShape.GetOptions(L) or {
			{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
			{ value = "SQUARE", label = "Square" },
			{ value = "ROUND", label = "Round" },
			{ value = "HEXAGON", label = "Hexagon" },
			{ value = "DIAMOND", label = "Diamond" },
		}
	end
	local function borderOptions()
		local shape = normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape"))
		return addon.IconShape and addon.IconShape.GetBorderOptions and addon.IconShape.GetBorderOptions(L, shape, {
			includeDefault = true,
			defaultValue = "DEFAULT",
			defaultLabel = _G.DEFAULT or "Default",
			includeNone = true,
			noneLabel = _G.NONE or "None",
			sort = false,
		}) or {
			{ value = "NONE", label = _G.NONE or "None" },
			{ value = "DEFAULT", label = _G.DEFAULT or "Default" },
		}
	end
	local function borderEnabled()
		local shape = normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape"))
		local borderKey = normalizeAuraBorder(getDefaultAuraDBValue(kind, "BorderTexture"), shape)
		return not isNoAuraBorder(borderKey)
	end
	local function borderColorEnabled()
		return borderEnabled() and not getDefaultAuraUseOriginalBorderColor(kind) and not getDefaultAuraUseDebuffTypeBorderColor(kind)
	end
	local function durationEnabled() return getDefaultAuraDBValue(kind, "DurationEnabled") ~= false end
	local function countEnabled() return getDefaultAuraDBValue(kind, "CountEnabled") ~= false end
	local function cooldownSwipeEnabled() return getDefaultAuraDrawSwipe(kind) end
	local function iconDarkModeEnabled() return getDefaultAuraDBValue(kind, "IconDarkMode") == true end
	local function anchorOptions() return buildAuraAnchorOptions() end
	local function growthOptions()
		local labels = {
			LEFT = _G.HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_LEFT or _G.LEFT or L["Left"] or "Left",
			RIGHT = _G.HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_RIGHT or _G.RIGHT or L["Right"] or "Right",
			UP = _G.HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_UP or _G.UP or L["Up"] or "Up",
			DOWN = _G.HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_DOWN or _G.DOWN or L["Down"] or "Down",
		}
		local options = {}
		for i = 1, #DEFAULT_AURA_GROWTH_OPTIONS do
			local value = DEFAULT_AURA_GROWTH_OPTIONS[i]
			local first, second = parseDefaultAuraGrowth(value)
			options[#options + 1] = { value = value, label = ("%s %s"):format(labels[first] or first, labels[second] or second) }
		end
		return options
	end
	local function sortMethodOptions()
		return {
			{ value = "TIME", label = L["Time"] or "Time" },
			{ value = "INDEX", label = L["Index"] or "Index" },
			{ value = "NAME", label = _G.NAME or "Name" },
		}
	end
	local function sortDirectionOptions()
		return {
			{ value = "-", label = L["Descending"] or "Descending" },
			{ value = "+", label = L["Ascending"] or "Ascending" },
		}
	end
	local function frameStrataOptions()
		return {
			{ value = "BACKGROUND", label = "BACKGROUND" },
			{ value = "LOW", label = "LOW" },
			{ value = "MEDIUM", label = "MEDIUM" },
			{ value = "HIGH", label = "HIGH" },
			{ value = "DIALOG", label = "DIALOG" },
			{ value = "FULLSCREEN", label = "FULLSCREEN" },
			{ value = "FULLSCREEN_DIALOG", label = "FULLSCREEN_DIALOG" },
			{ value = "TOOLTIP", label = "TOOLTIP" },
		}
	end

	local layoutSectionId = "default-aura-containers-layout"
	local borderSectionId = "default-aura-containers-border"
	local durationSectionId = "default-aura-containers-duration"
	local stackSectionId = "default-aura-containers-stacks"

	return {
		{ name = L["Layout"] or "Layout", kind = SettingType.Collapsible, id = layoutSectionId, defaultCollapsed = false },
		checkbox(L["Sync buff and debuff settings"] or "Sync buff and debuff settings", getDefaultAuraSyncEnabled, function(value) applyDefaultAuraEditModeSetting(kind, "sync", value) end, nil, layoutSectionId),
		dropdown(L["settingsIconShapeLabel"] or "Icon shape", function() return normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape")) end, function(value) applyDefaultAuraEditModeSetting(kind, "shape", value) end, shapeOptions, 180, nil, layoutSectionId),
		slider(L["Icon zoom"] or "Icon zoom", function() return normalizeAuraIconZoom(getDefaultAuraDBValue(kind, "IconZoom")) end, function(value) applyDefaultAuraEditModeSetting(kind, "zoom", value) end, 0, 35, 1, nil, layoutSectionId),
		checkbox(L["Icon dark mode"] or "Icon dark mode", function() return getDefaultAuraDBValue(kind, "IconDarkMode") == true end, function(value) applyDefaultAuraEditModeSetting(kind, "iconDarkMode", value) end, nil, layoutSectionId),
		slider(L["Icon darkness"] or "Icon darkness", function() return normalizeAuraIconDarkness(getDefaultAuraDBValue(kind, "IconDarkness")) end, function(value) applyDefaultAuraEditModeSetting(kind, "iconDarkness", value) end, 0, 100, 1, iconDarkModeEnabled, layoutSectionId),
		slider(L["Alpha"] or "Alpha", function() return math.floor((normalizeAuraIconAlpha(getDefaultAuraDBValue(kind, "IconAlpha")) * 100) + 0.5) end, function(value) applyDefaultAuraEditModeSetting(kind, "iconAlpha", (tonumber(value) or 100) / 100) end, 0, 100, 1, nil, layoutSectionId),
		checkbox(L["Desaturate icon"] or "Desaturate icon", function() return getDefaultAuraDBValue(kind, "IconDesaturate") == true end, function(value) applyDefaultAuraEditModeSetting(kind, "iconDesaturate", value) end, iconDarkModeEnabled, layoutSectionId),
		slider(L["Icon size"] or "Icon size", function() return getDefaultAuraIconSize(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "size", value) end, 16, 80, 1, nil, layoutSectionId),
		slider(L["Horizontal spacing"] or "Horizontal spacing", function() return getDefaultAuraHorizontalSpacing(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "horizontalSpacing", value) end, 0, 100, 1, nil, layoutSectionId),
		slider(L["Vertical spacing"] or "Vertical spacing", function() return getDefaultAuraVerticalSpacing(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "verticalSpacing", value) end, 0, 100, 1, nil, layoutSectionId),
		checkbox(L["Draw cooldown swipe"] or "Draw cooldown swipe", function() return getDefaultAuraDrawSwipe(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "drawSwipe", value) end, nil, layoutSectionId),
		checkbox(L["Draw cooldown edge"] or "Draw cooldown edge", function() return getDefaultAuraDrawEdge(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "drawEdge", value) end, nil, layoutSectionId),
		checkbox(L["Reverse cooldown swipe"] or "Reverse cooldown swipe", function() return getDefaultAuraCooldownReverse(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "cooldownReverse", value) end, cooldownSwipeEnabled, layoutSectionId),
		slider(L["Aura per row"] or "Auras per row", function() return getDefaultAuraIconsPerRow(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "perRow", value) end, 1, 32, 1, nil, layoutSectionId),
		slider(L["Max rows"] or "Max rows", function() return getDefaultAuraMaxRows(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "maxRows", value) end, 1, 10, 1, nil, layoutSectionId),
		dropdown(L["Growth direction"] or "Growth direction", function() return getDefaultAuraGrowth(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "growth", value) end, growthOptions, 180, nil, layoutSectionId),
		dropdown(L["Frame strata"] or "Frame strata", function() return normalizeDefaultAuraFrameStrata(getDefaultAuraDBValue(kind, "FrameStrata")) end, function(value) applyDefaultAuraEditModeSetting(kind, "frameStrata", value) end, frameStrataOptions, 180, nil, layoutSectionId),
		slider(L["UFFrameLevel"] or "Frame level", function() return getDefaultAuraFrameLevel(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "frameLevel", value) end, 0, 100, 1, nil, layoutSectionId),
		dropdown(L["Sort method"] or "Sort method", function() return normalizeDefaultAuraSortMethod(getDefaultAuraDBValue(kind, "SortMethod")) end, function(value) applyDefaultAuraEditModeSetting(kind, "sortMethod", value) end, sortMethodOptions, 120, nil, layoutSectionId),
		dropdown(L["Sort direction"] or "Sort direction", function() return normalizeDefaultAuraSortDirection(getDefaultAuraDBValue(kind, "SortDirection")) end, function(value) applyDefaultAuraEditModeSetting(kind, "sortDirection", value) end, sortDirectionOptions, 100, nil, layoutSectionId),
		checkbox(L["Include weapon enchants"] or "Include weapon enchants", function() return getDefaultAuraDBValue(kind, "IncludeWeapons") == true end, function(value) applyDefaultAuraEditModeSetting(kind, "includeWeapons", value) end, function() return kind == "buff" end, layoutSectionId),
		{ name = L["Border"] or "Border", kind = SettingType.Collapsible, id = borderSectionId, defaultCollapsed = true },
		dropdown(L["Aura border texture"] or "Aura border texture", function()
			local shape = normalizeAuraIconShape(getDefaultAuraDBValue(kind, "IconShape"))
			return normalizeAuraBorder(getDefaultAuraDBValue(kind, "BorderTexture"), shape)
		end, function(value) applyDefaultAuraEditModeSetting(kind, "border", value) end, borderOptions, 220, nil, borderSectionId),
		slider(L["Border Size"] or "Border Size", function() return getDefaultAuraBorderSize(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "borderSize", value) end, 1, 24, 1, borderEnabled, borderSectionId),
		slider(L["Border offset"] or "Border offset", function() return getDefaultAuraBorderOffset(nil, kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "borderOffset", value) end, -20, 100, 1, borderEnabled, borderSectionId),
		checkbox(L["Use debuff type border color"] or "Use debuff type border color", function() return getDefaultAuraUseDebuffTypeBorderColor(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "useDebuffTypeBorderColor", value) end, function() return kind == "debuff" and borderEnabled() end, borderSectionId),
		checkbox(L["Use original border color"] or "Use original border color", function() return getDefaultAuraUseOriginalBorderColor(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "useOriginalBorderColor", value) end, borderEnabled, borderSectionId),
		{
			name = L["Border color"] or "Border color",
			kind = SettingType.Color,
			parentId = borderSectionId,
			hasOpacity = true,
			get = function()
				local color = getDefaultAuraDBValue(kind, "BorderColor") or DEFAULT_AURA_BORDER_COLOR
				return {
					r = color.r or DEFAULT_AURA_BORDER_COLOR.r,
					g = color.g or DEFAULT_AURA_BORDER_COLOR.g,
					b = color.b or DEFAULT_AURA_BORDER_COLOR.b,
					a = color.a ~= nil and color.a or DEFAULT_AURA_BORDER_COLOR.a,
				}
			end,
			set = function(_, value) applyDefaultAuraEditModeSetting(kind, "borderColor", value) end,
			isEnabled = borderColorEnabled,
		},
		{ name = L["Cooldown text"] or "Cooldown text", kind = SettingType.Collapsible, id = durationSectionId, defaultCollapsed = true },
		checkbox(L["Show cooldown text"] or "Show cooldown text", durationEnabled, function(value) applyDefaultAuraEditModeSetting(kind, "durationEnabled", value) end, nil, durationSectionId),
		dropdown(L["durationTextProfile"] or "Duration text profile", function() return getDefaultAuraDurationTextProfile(kind) end, function(value) applyDefaultAuraEditModeSetting(kind, "durationTextProfile", value) end, function()
			return addon.DurationText and addon.DurationText.GetProfileOptions and addon.DurationText:GetProfileOptions() or {}
		end, 180, durationEnabled, durationSectionId),
		dropdown(L["Font"] or "Font", function() return normalizeAuraFontKey(getDefaultAuraDBValue(kind, "DurationFontFace")) end, function(value) applyDefaultAuraEditModeSetting(kind, "durationFont", value) end, buildAuraFontOptions, 220, durationEnabled, durationSectionId),
		dropdown(L["Font outline"] or "Font outline", function() return normalizeAuraFontStyle(getDefaultAuraDBValue(kind, "DurationFontOutline")) end, function(value) applyDefaultAuraEditModeSetting(kind, "durationOutline", value) end, buildAuraFontStyleOptions, 220, durationEnabled, durationSectionId),
		slider(_G.FONT_SIZE or "Font size", function() return getAuraTextSize(nil, tonumber(getDefaultAuraDBValue(kind, "DurationFontSize")) or 10) end, function(value) applyDefaultAuraEditModeSetting(kind, "durationSize", value) end, 6, 64, 1, durationEnabled, durationSectionId),
		color(_G.COLOR or "Color", function() return normalizeAuraTextColor(getDefaultAuraDBValue(kind, "DurationColor"), DEFAULT_AURA_DURATION_COLOR) end, function(value) applyDefaultAuraEditModeSetting(kind, "durationColor", value) end, durationEnabled, durationSectionId),
		dropdown(L["Anchor point"] or "Anchor point", function() return normalizeAuraAnchorPoint(getDefaultAuraDBValue(kind, "DurationAnchor"), "BOTTOM") end, function(value) applyDefaultAuraEditModeSetting(kind, "durationAnchor", value) end, anchorOptions, 180, durationEnabled, durationSectionId),
		slider(L["X Offset"] or "X Offset", function()
			local offset = getDefaultAuraDBValue(kind, "DurationOffset")
			return getAuraTextOffset(nil, "x", type(offset) == "table" and offset.x or 0)
		end, function(value) applyDefaultAuraEditModeSetting(kind, "durationOffsetX", value) end, -100, 100, 1, durationEnabled, durationSectionId),
		slider(L["Y Offset"] or "Y Offset", function()
			local offset = getDefaultAuraDBValue(kind, "DurationOffset")
			return getAuraTextOffset(nil, "y", type(offset) == "table" and offset.y or -1)
		end, function(value) applyDefaultAuraEditModeSetting(kind, "durationOffsetY", value) end, -100, 100, 1, durationEnabled, durationSectionId),
		{ name = L["Stacks"] or "Stacks", kind = SettingType.Collapsible, id = stackSectionId, defaultCollapsed = true },
		checkbox(L["Show stacks"] or "Show stacks", countEnabled, function(value) applyDefaultAuraEditModeSetting(kind, "countEnabled", value) end, nil, stackSectionId),
		dropdown(L["Font"] or "Font", function() return normalizeAuraFontKey(getDefaultAuraDBValue(kind, "CountFontFace")) end, function(value) applyDefaultAuraEditModeSetting(kind, "countFont", value) end, buildAuraFontOptions, 220, countEnabled, stackSectionId),
		dropdown(L["Font outline"] or "Font outline", function() return normalizeAuraFontStyle(getDefaultAuraDBValue(kind, "CountFontOutline")) end, function(value) applyDefaultAuraEditModeSetting(kind, "countOutline", value) end, buildAuraFontStyleOptions, 220, countEnabled, stackSectionId),
		slider(_G.FONT_SIZE or "Font size", function() return getAuraTextSize(nil, tonumber(getDefaultAuraDBValue(kind, "CountFontSize")) or 12) end, function(value) applyDefaultAuraEditModeSetting(kind, "countSize", value) end, 6, 64, 1, countEnabled, stackSectionId),
		color(_G.COLOR or "Color", function() return normalizeAuraTextColor(getDefaultAuraDBValue(kind, "CountColor"), DEFAULT_AURA_COUNT_COLOR) end, function(value) applyDefaultAuraEditModeSetting(kind, "countColor", value) end, countEnabled, stackSectionId),
		dropdown(L["Anchor point"] or "Anchor point", function() return normalizeAuraAnchorPoint(getDefaultAuraDBValue(kind, "CountAnchor"), "TOPRIGHT") end, function(value) applyDefaultAuraEditModeSetting(kind, "countAnchor", value) end, anchorOptions, 180, countEnabled, stackSectionId),
		slider(L["X Offset"] or "X Offset", function()
			local offset = getDefaultAuraDBValue(kind, "CountOffset")
			return getAuraTextOffset(nil, "x", type(offset) == "table" and offset.x or -1)
		end, function(value) applyDefaultAuraEditModeSetting(kind, "countOffsetX", value) end, -100, 100, 1, countEnabled, stackSectionId),
		slider(L["Y Offset"] or "Y Offset", function()
			local offset = getDefaultAuraDBValue(kind, "CountOffset")
			return getAuraTextOffset(nil, "y", type(offset) == "table" and offset.y or 1)
		end, function(value) applyDefaultAuraEditModeSetting(kind, "countOffsetY", value) end, -100, 100, 1, countEnabled, stackSectionId),
	}
end

local function registerDefaultAuraHeaderEditMode(kind, header, anchor)
	if not (header and anchor) then return false end
	local EditMode = addon.EditMode
	if not (EditMode and EditMode.RegisterFrame and EditMode:IsAvailable()) then return false end

	local isBuff = kind == "buff"
	local id = isBuff and "DefaultAuraBuffContainer" or "DefaultAuraDebuffContainer"
	local flag = isBuff and "defaultBuffHeaderEditModeRegistered" or "defaultDebuffHeaderEditModeRegistered"
	if DAC.variables[flag] then
		attachDefaultAuraHeaderToAnchor(header, anchor)
		return true
	end
	if InCombatLockdown and InCombatLockdown() then return false end

	attachDefaultAuraHeaderToAnchor(header, anchor)

	EditMode:RegisterFrame(id, {
		frame = anchor,
		title = isBuff and (L["Buff Frame"] or "Buff Frame") or (L["Debuff Frame"] or "Debuff Frame"),
		layoutDefaults = isBuff and { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -260, y = -120 } or { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -260, y = -220 },
		showOutsideEditMode = true,
		isEnabled = function()
			return addon.db and ((isBuff and addon.db.skinnerDefaultBuffIconsEnabled == true) or (not isBuff and addon.db.skinnerDefaultDebuffIconsEnabled == true))
		end,
		onApply = function()
			attachDefaultAuraHeaderToAnchor(header, anchor)
			if header.eqolNativeAuraContainer then
				configureDefaultNativeAuraContainer(kind, header, anchor)
			else
				applyDefaultAuraHeaderButtonStyles(header, true)
				updateDefaultAuraHeaderButtons(header)
			end
		end,
		onPositionChanged = function()
			attachDefaultAuraHeaderToAnchor(header, anchor)
			if header.eqolNativeAuraContainer then
				configureDefaultNativeAuraContainer(kind, header, anchor)
			else
				applyDefaultAuraHeaderButtonStyles(header, true)
				updateDefaultAuraHeaderButtons(header)
			end
		end,
		settings = createDefaultAuraEditModeSettings(kind),
		settingsMaxHeight = 700,
		collapseExclusive = true,
		showReset = false,
		showSettingsReset = false,
	})

	if EditMode.RegisterButtons then
		local otherKind = isBuff and "debuff" or "buff"
		local buttons = {}
		-- PTR5's Edit Mode aura provider populates broad HELPFUL/HARMFUL
		-- AuraGroups directly. Keep manual samples only for the legacy header.
		if not useNativeAuraContainers then
			buttons[#buttons + 1] = {
				text = L["Toggle sample auras"] or "Toggle sample auras",
				layout = "compact",
				click = function() toggleDefaultAuraSamples(kind) end,
			}
		end
		buttons[#buttons + 1] = {
				text = isBuff and (L["Copy settings to debuffs"] or "Copy settings to debuffs") or (L["Copy settings to buffs"] or "Copy settings to buffs"),
				layout = "compact",
				click = function()
					copyDefaultAuraConfig(kind, otherKind)
					if useNativeAuraContainers then markDefaultAuraReloadRequired() end
					refreshDefaultAuraIconSkin()
				end,
			}
		EditMode:RegisterButtons(id, buttons)
	end

	DAC.variables[flag] = true
	attachDefaultAuraHeaderToAnchor(header, anchor)
	return true
end

local function updateBlizzardAuraFrameVisibility()
	if addon.db and addon.db.skinnerDefaultBuffIconsEnabled == true then hideBlizzardAuraFrame(_G.BuffFrame) end
	if addon.db and addon.db.skinnerDefaultDebuffIconsEnabled == true then hideBlizzardAuraFrame(_G.DebuffFrame) end
end

local function ensureDefaultAuraContainerHooks()
	if DAC.variables.defaultAuraContainerHooksInstalled then return end
	DAC.variables.defaultAuraContainerHooksInstalled = true
	if _G.BuffFrame and _G.BuffFrame.HookScript then _G.BuffFrame:HookScript("OnShow", updateBlizzardAuraFrameVisibility) end
	if _G.DebuffFrame and _G.DebuffFrame.HookScript then _G.DebuffFrame:HookScript("OnShow", updateBlizzardAuraFrameVisibility) end
end

local function getNativeAuraSortOptions(kind)
	local method = normalizeDefaultAuraSortMethod(getDefaultAuraDBValue(kind, "SortMethod"))
	local direction = normalizeDefaultAuraSortDirection(getDefaultAuraDBValue(kind, "SortDirection"))
	local nativeMethod = AuraContainerSortMethod and AuraContainerSortMethod.Default or 0
	if method == "TIME" and AuraContainerSortMethod then
		nativeMethod = AuraContainerSortMethod.Expiration
	elseif method == "NAME" and AuraContainerSortMethod then
		nativeMethod = AuraContainerSortMethod.Name
	elseif method == "INDEX" and AuraContainerSortMethod and AuraContainerSortMethod.AuraInstanceIDOnly then
		nativeMethod = AuraContainerSortMethod.AuraInstanceIDOnly
	end
	local nativeDirection = AuraContainerSortDirection and AuraContainerSortDirection.Normal or 0
	if direction == "-" and AuraContainerSortDirection then nativeDirection = AuraContainerSortDirection.Reverse end
	return nativeMethod, nativeDirection
end

local function initializeDefaultNativeAuraButton(button, kind)
	local config = getDefaultAuraStyleConfig(kind)
	button.eqolDefaultAuraKind = kind
	button:SetSize(config.size, config.size)
	button:SetCancelAuraButtons(kind == "buff" and "RightButtonUp" or nil)
	button:EnableMouse(true)
	if button.SetMouseClickEnabled then button:SetMouseClickEnabled(kind == "buff") end
	if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(true) end
	if addon.AuraCompat and addon.AuraCompat.RegisterAuraButtonTooltipPolicy then
		addon.AuraCompat:RegisterAuraButtonTooltipPolicy(button, false, true)
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	button:SetIcon(icon)

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetDrawSwipe(config.drawSwipe)
	cooldown:SetDrawEdge(config.drawEdge)
	cooldown:SetReverse(config.cooldownReverse)
	cooldown:SetHideCountdownNumbers(true)
	if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
	button:SetDurationCooldown(cooldown)

	if not config.hideCountdownNumbers then
		local duration = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		setAuraFontStringStyle(duration, "Duration", DEFAULT_AURA_DURATION_COLOR, kind)
		positionAuraFontString(duration, button, "Duration", "BOTTOM", 0, -1, kind)
		local options = addon.functions and addon.functions.GetAuraButtonDurationTextOptions
			and addon.functions.GetAuraButtonDurationTextOptions(config.durationTextProfile)
			or nil
		button:SetDurationText(duration, options)
	end

	if config.countEnabled then
		local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		setAuraFontStringStyle(count, "Count", DEFAULT_AURA_COUNT_COLOR, kind)
		positionAuraFontString(count, button, "Count", "TOPRIGHT", -1, -1, kind)
		button:SetApplicationCount(count)
	end

	if addon.IconShape and addon.IconShape.ApplyFrameShape then
		addon.IconShape.ApplyFrameShape(button, config.shape, {
			textures = { icon },
			cooldown = cooldown,
			iconZoom = config.zoom,
			textureMaskKey = "_eqolDefaultAuraIconMask",
			textureTexCoordKey = "_eqolDefaultAuraIconTexCoord",
			maskKey = "_eqolDefaultAuraMask",
		})
	elseif icon.SetTexCoord then
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
	applyDefaultAuraIconDarkMode(button, config)

	-- DispelTypeTexture is a dispel-color binding. Applying it to helpful auras
	-- colors their no-dispel fallback as a red debuff border and bypasses the
	-- configured EnhanceQoL border. Helpful auras keep the normal style path.
	if config.kind == "debuff" and (config.useDebuffTypeBorderColor or config.useOriginalBorderColor) then
		local registeredDispelTexture = false
		local function registerDispelTexture(texture)
			if not texture then return end
			button:AddDispelTypeTexture(texture, {
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				showWhenHarmful = true,
				showWhenHelpful = false,
				showWithoutDispelType = true,
				customDispelColorCurve = config.useDebuffTypeBorderColor and ensureDefaultAuraDispelColorCurve() or nil,
			})
			registeredDispelTexture = true
		end

		-- PTR7 supports multiple dispel textures, so the selected multi-part
		-- border can now retain its configured shape instead of falling back to
		-- one rectangular Blizzard overlay.
		if config.hasCustomBorder then
			local initialColor = config.color or { 1, 1, 1, 1 }
			if isBackdropAuraBorderCompatible(config.shape) then
				if applyDefaultAuraBackdropBorder(button, icon, config.borderKey, initialColor, config) then
					local borderState = button.eqolDefaultAuraBackdropBorder and button.eqolDefaultAuraBackdropBorder._eqolDefaultAuraSafeBorder
					if borderState then
						for _, key in ipairs({ "top", "bottom", "left", "right", "topLeft", "topRight", "bottomLeft", "bottomRight" }) do
							registerDispelTexture(borderState[key])
						end
					end
				end
			elseif applyDefaultAuraShapeBorder(button, icon, config.borderKey, config.shape, initialColor, config) then
				for _, texture in ipairs(button._eqolDefaultAuraShapeBorderTextures or {}) do registerDispelTexture(texture) end
			end
		end

		if not registeredDispelTexture then
			local border = button:CreateTexture(nil, "OVERLAY", nil, 6)
			border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
			local offset = tonumber(config.borderOffset) or 0
			border:SetPoint("TOPLEFT", icon, "TOPLEFT", -offset, offset)
			border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", offset, -offset)
			border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
			registerDispelTexture(border)
		end
	elseif config.hasCustomBorder then
		local color = resolveDefaultAuraBorderColorFromConfig(button, config)
		if isBackdropAuraBorderCompatible(config.shape) then
			applyDefaultAuraBackdropBorder(button, icon, config.borderKey, color, config)
		else
			applyDefaultAuraShapeBorder(button, icon, config.borderKey, config.shape, color, config)
		end
	end
end

local function getNativeAuraLayout(kind)
	local size = getDefaultAuraIconSize(nil, kind)
	local spacingX = getDefaultAuraHorizontalSpacing(nil, kind)
	local spacingY = getDefaultAuraVerticalSpacing(nil, kind)
	local perRow = getDefaultAuraIconsPerRow(nil, kind)
	local maxRows = getDefaultAuraMaxRows(nil, kind)
	local _, _, primaryHorizontal, startPoint = getDefaultAuraGrowthLayout(kind)
	local horizontal = startPoint:find("RIGHT", 1, true) and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right
	local vertical = startPoint:find("BOTTOM", 1, true) and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down
	local elementSpacing = primaryHorizontal and spacingX or spacingY
	local lineSpacing = primaryHorizontal and spacingY or spacingX
	local maximumLineCount = primaryHorizontal and perRow or maxRows
	return {
		axis = primaryHorizontal and AnchorUtil.FlowLayoutAxis.Horizontal or AnchorUtil.FlowLayoutAxis.Vertical,
		anchorPoint = startPoint,
		horizontalGrowthDirection = horizontal,
		verticalGrowthDirection = vertical,
		maximumLineSize = maximumLineCount * size + (maximumLineCount - 1) * elementSpacing,
		group = {
			elementSpacing = elementSpacing,
			lineSpacing = lineSpacing,
			groupSpacing = 0,
			groupLineSpacing = lineSpacing,
			forceNewLine = false,
			elementWidth = size,
			elementHeight = size,
			layoutIndex = 1,
		},
	}
end

configureDefaultNativeAuraContainer = function(kind, container, anchor)
	local AuraCompat = addon.AuraCompat
	if not (AuraCompat and container and anchor) then return false end
	local layout = getNativeAuraLayout(kind)
	local perRow = getDefaultAuraIconsPerRow(nil, kind)
	local maxRows = getDefaultAuraMaxRows(nil, kind)
	local sortMethod, sortDirection = getNativeAuraSortOptions(kind)
	anchor:SetFrameStrata(normalizeDefaultAuraFrameStrata(getDefaultAuraDBValue(kind, "FrameStrata")))
	anchor:SetFrameLevel(getDefaultAuraFrameLevel(nil, kind))
	container:SetFrameStrata(anchor:GetFrameStrata())
	container:SetFrameLevel((anchor:GetFrameLevel() or 1) + 1)
	container:ClearAllPoints()
	container:SetAllPoints(anchor)
	if not AuraCompat:ConfigureAuraContainerLayout(container, layout) then return false end
	if not AuraCompat:RegisterAuraGroup(container, "default", kind == "debuff" and "HARMFUL" or "HELPFUL", {
		maxFrameCount = perRow * maxRows,
		initializeFrame = function(button) initializeDefaultNativeAuraButton(button, kind) end,
		sortMethod = sortMethod,
		sortDirection = sortDirection,
		layout = layout.group,
	}) then
		return false
	end

	if kind == "buff" and getDefaultAuraDBValue(kind, "IncludeWeapons") == true and AuraContainerItemEnchantmentSlot then
		local init = function(button) initializeDefaultNativeAuraButton(button, kind) end
		AuraCompat:RegisterItemEnchantment(container, AuraContainerItemEnchantmentSlot.MainHand, { initializeFrame = init, cancelAuraButtons = "RightButtonUp" })
		AuraCompat:RegisterItemEnchantment(container, AuraContainerItemEnchantmentSlot.OffHand, { initializeFrame = init, cancelAuraButtons = "RightButtonUp" })
		AuraCompat:RegisterItemEnchantment(container, AuraContainerItemEnchantmentSlot.Ranged, { initializeFrame = init, cancelAuraButtons = "RightButtonUp" })
		AuraCompat:ConfigureItemEnchantmentLayout(container, {
			placement = CustomAuraContainerItemEnchantmentPlacement.BeforeAuraGroups,
			elementSpacing = layout.group.elementSpacing,
			lineSpacing = layout.group.lineSpacing,
			groupSpacing = 0,
			groupLineSpacing = layout.group.lineSpacing,
			forceNewLine = false,
			elementWidth = getDefaultAuraIconSize(nil, kind),
			elementHeight = getDefaultAuraIconSize(nil, kind),
			layoutIndex = 0,
		})
		AuraCompat:SetItemEnchantmentSortMethod(container, AuraContainerItemEnchantmentSortMethod.Slot, sortDirection)
	end
	return AuraCompat:RefreshAuraContainer(container, "player")
end

local function createDefaultNativeAuraContainer(kind, anchor)
	local AuraCompat = addon.AuraCompat
	if not (AuraCompat and AuraCompat.CreateAuraContainer) then return nil end
	local name = kind == "buff" and "EnhanceQoLCustomBuffFrame" or "EnhanceQoLCustomDebuffFrame"
	local container = AuraCompat:CreateAuraContainer(anchor, name)
	if not container then return nil end
	container.eqolDefaultAuraKind = kind
	container.eqolNativeAuraContainer = true
	if container.SetRolesets then container:SetRolesets("buffs") end
	return container
end

local function refreshDefaultNativeAuraContainers()
	ensureDefaultAuraContainerHooks()
	for _, kind in ipairs({ "buff", "debuff" }) do
		local isBuff = kind == "buff"
		local enabled = addon.db and addon.db[isBuff and "skinnerDefaultBuffIconsEnabled" or "skinnerDefaultDebuffIconsEnabled"] == true
		local anchorKey = isBuff and "defaultBuffAnchor" or "defaultDebuffAnchor"
		local containerKey = isBuff and "defaultBuffHeader" or "defaultDebuffHeader"
		if enabled then
			local anchor = ensureDefaultAuraAnchor(kind)
			local container = DAC.variables[containerKey] or createDefaultNativeAuraContainer(kind, anchor)
			DAC.variables[containerKey] = container
			if container and configureDefaultNativeAuraContainer(kind, container, anchor) then
				-- Blizzard owns the 12.1 Edit Mode aura provider. Never hide the
				-- native container behind the legacy manually-created sample frames.
				anchor.eqolDefaultAuraSamplesEnabled = nil
				hideDefaultAuraSamples(kind)
				if not registerDefaultAuraHeaderEditMode(kind, container, anchor) then
					anchor:ClearAllPoints()
					if isBuff then
						anchor:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "TOPLEFT", -8, -8)
					else
						anchor:SetPoint("TOPRIGHT", DAC.variables.defaultBuffAnchor or MinimapCluster or UIParent, "BOTTOMRIGHT", 0, -20)
					end
				end
				anchor:Show()
				container:Show()
			end
		else
			if DAC.variables[anchorKey] then DAC.variables[anchorKey]:Hide() end
			if DAC.variables[containerKey] then addon.AuraCompat:DisableAuraContainer(DAC.variables[containerKey]) end
		end
	end
	updateBlizzardAuraFrameVisibility()
end

function DAC.functions.RefreshDefaultAuraIconSkin()
	if useNativeAuraContainers then
		local inCombat = InCombatLockdown and InCombatLockdown()
		invalidateDefaultAuraStyleCache()
		refreshDefaultNativeAuraContainers()
		-- Protected Blizzard-frame visibility and first-time Edit Mode
		-- registration still wait for combat to end; native AuraContainer
		-- creation and configuration no longer need to.
		if inCombat then
			DAC.variables.pendingDefaultAuraCombat = true
			local watcher = ensureDefaultAuraWatcher()
			watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end

	if InCombatLockdown and InCombatLockdown() then
		DAC.variables.pendingDefaultAuraCombat = true
		local watcher = ensureDefaultAuraWatcher()
		watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	invalidateDefaultAuraStyleCache()

	if not isDefaultAuraIconSkinEnabled() then
		if DAC.variables.defaultBuffHeader then DAC.variables.defaultBuffHeader:Hide() end
		if DAC.variables.defaultDebuffHeader then DAC.variables.defaultDebuffHeader:Hide() end
		return
	end

	ensureDefaultAuraContainerHooks()

	if addon.db and addon.db.skinnerDefaultBuffIconsEnabled == true then
		local header = DAC.variables.defaultBuffHeader or createDefaultAuraHeader("buff", "HELPFUL")
		local anchor = ensureDefaultAuraAnchor("buff")
		DAC.variables.defaultBuffHeader = header
		configureDefaultAuraHeader(header, "HELPFUL", "buff")
		if not registerDefaultAuraHeaderEditMode("buff", header, anchor) then
			anchor:ClearAllPoints()
			anchor:SetPoint("TOPRIGHT", MinimapCluster or UIParent, "TOPLEFT", -8, -8)
			attachDefaultAuraHeaderToAnchor(header, anchor)
		end
		refreshDefaultAuraSamples("buff")
		anchor:Show()
		header:SetShown(not anchor.eqolDefaultAuraSamplesEnabled)
	else
		if DAC.variables.defaultBuffAnchor then DAC.variables.defaultBuffAnchor:Hide() end
		if DAC.variables.defaultBuffHeader then DAC.variables.defaultBuffHeader:Hide() end
	end

	if addon.db and addon.db.skinnerDefaultDebuffIconsEnabled == true then
		local header = DAC.variables.defaultDebuffHeader or createDefaultAuraHeader("debuff", "HARMFUL")
		local anchor = ensureDefaultAuraAnchor("debuff")
		DAC.variables.defaultDebuffHeader = header
		configureDefaultAuraHeader(header, "HARMFUL", "debuff")
		if not registerDefaultAuraHeaderEditMode("debuff", header, anchor) then
			anchor:ClearAllPoints()
			anchor:SetPoint("TOPRIGHT", DAC.variables.defaultBuffAnchor or MinimapCluster or UIParent, "BOTTOMRIGHT", 0, -20)
			attachDefaultAuraHeaderToAnchor(header, anchor)
		end
		refreshDefaultAuraSamples("debuff")
		anchor:Show()
		header:SetShown(not anchor.eqolDefaultAuraSamplesEnabled)
	else
		if DAC.variables.defaultDebuffAnchor then DAC.variables.defaultDebuffAnchor:Hide() end
		if DAC.variables.defaultDebuffHeader then DAC.variables.defaultDebuffHeader:Hide() end
	end

	updateBlizzardAuraFrameVisibility()
end

refreshDefaultAuraIconSkin = function()
	if DAC.functions.RefreshDefaultAuraIconSkin then DAC.functions.RefreshDefaultAuraIconSkin() end
end

local function migrateDefaultAuraTextAnchor(prefix)
	if not addon.db then return end
	local durationAnchorKey = prefix .. "DurationAnchor"
	local durationRelativeKey = prefix .. "DurationRelativePoint"
	local countAnchorKey = prefix .. "CountAnchor"
	local countOffsetKey = prefix .. "CountOffset"
	if addon.db[durationAnchorKey] == "TOP" and addon.db[durationRelativeKey] == "BOTTOM" then
		addon.db[durationAnchorKey] = "BOTTOM"
	end
	local countOffset = addon.db[countOffsetKey]
	if addon.db[countAnchorKey] == "BOTTOMRIGHT" and type(countOffset) == "table" and (tonumber(countOffset.x) or -1) == -1 and (tonumber(countOffset.y) or 1) == 1 then
		addon.db[countAnchorKey] = "TOPRIGHT"
		addon.db[countOffsetKey] = { x = -1, y = -1 }
	end
	addon.db[durationRelativeKey] = nil
	addon.db[prefix .. "CountRelativePoint"] = nil
end

function DAC.functions.InitDB()
	if not (addon.functions and addon.functions.InitDBValue) then return end
	local init = addon.functions.InitDBValue
	init("skinnerDefaultBuffIconsEnabled", false)
	init("skinnerDefaultDebuffIconsEnabled", false)
	init("skinnerDefaultAuraSyncBuffDebuff", true)
	init("skinnerDefaultAuraIconShape", "DEFAULT")
	init("skinnerDefaultAuraIconAlpha", 1)
	init("skinnerDefaultAuraIconSize", 32)
	init("skinnerDefaultAuraIconSpacing", 4)
	init("skinnerDefaultAuraHorizontalSpacing", getDefaultAuraIconSpacing())
	init("skinnerDefaultAuraVerticalSpacing", getDefaultAuraIconSpacing() + 12)
	init("skinnerDefaultAuraIconsPerRow", 8)
	init("skinnerDefaultAuraMaxRows", 4)
	init("skinnerDefaultAuraGrowth", "LEFTDOWN")
	init("skinnerDefaultAuraFrameStrata", "MEDIUM")
	init("skinnerDefaultAuraFrameLevel", 50)
	init("skinnerDefaultAuraSortMethod", "TIME")
	init("skinnerDefaultAuraSortDirection", "-")
	init("skinnerDefaultAuraIncludeWeapons", true)
	init("skinnerDefaultAuraIconZoom", 0)
	init("skinnerDefaultAuraIconDarkMode", false)
	init("skinnerDefaultAuraIconDarkness", 35)
	init("skinnerDefaultAuraIconDesaturate", true)
	init("skinnerDefaultAuraCooldownDrawSwipe", true)
	init("skinnerDefaultAuraCooldownDrawEdge", false)
	init("skinnerDefaultAuraCooldownReverse", false)
	init("skinnerDefaultAuraBorderTexture", addon.IconShape and addon.IconShape.BORDER and addon.IconShape.BORDER.NONE or "NONE")
	init("skinnerDefaultAuraBorderSize", 1)
	init("skinnerDefaultAuraBorderOffset", 0)
	init("skinnerDefaultAuraUseOriginalBorderColor", false)
	init("skinnerDefaultAuraUseDebuffTypeBorderColor", false)
	init("skinnerDefaultAuraBorderColor", {
		r = DEFAULT_AURA_BORDER_COLOR.r,
		g = DEFAULT_AURA_BORDER_COLOR.g,
		b = DEFAULT_AURA_BORDER_COLOR.b,
		a = DEFAULT_AURA_BORDER_COLOR.a,
	})
	init("skinnerDefaultAuraDurationEnabled", true)
	init("skinnerDefaultAuraDurationFontFace", getGlobalFontKey())
	init("skinnerDefaultAuraDurationFontOutline", getGlobalStyleKey())
	init("skinnerDefaultAuraDurationFontSize", 10)
	init("skinnerDefaultAuraDurationColor", {
		r = DEFAULT_AURA_DURATION_COLOR.r,
		g = DEFAULT_AURA_DURATION_COLOR.g,
		b = DEFAULT_AURA_DURATION_COLOR.b,
		a = DEFAULT_AURA_DURATION_COLOR.a,
	})
	init("skinnerDefaultAuraDurationAnchor", "BOTTOM")
	init("skinnerDefaultAuraDurationOffset", { x = 0, y = -1 })
	init("skinnerDefaultAuraDurationTextProfile", "MINIMAL")
	init("skinnerDefaultAuraCountEnabled", true)
	init("skinnerDefaultAuraCountFontFace", getGlobalFontKey())
	init("skinnerDefaultAuraCountFontOutline", getGlobalStyleKey())
	init("skinnerDefaultAuraCountFontSize", 12)
	init("skinnerDefaultAuraCountColor", {
		r = DEFAULT_AURA_COUNT_COLOR.r,
		g = DEFAULT_AURA_COUNT_COLOR.g,
		b = DEFAULT_AURA_COUNT_COLOR.b,
		a = DEFAULT_AURA_COUNT_COLOR.a,
	})
	init("skinnerDefaultAuraCountAnchor", "TOPRIGHT")
	init("skinnerDefaultAuraCountOffset", { x = -1, y = -1 })
	migrateDefaultAuraTextAnchor(DEFAULT_AURA_DB_PREFIX)
	migrateDefaultAuraTextAnchor(DEFAULT_DEBUFF_AURA_DB_PREFIX)
	if isDefaultAuraIconSkinEnabled() then refreshDefaultAuraIconSkin() end
end

local function ensureDefaultAuraContainersSuiteSection(category)
	local expandable = addon.SettingsLayout and addon.SettingsLayout.suitesDefaultAuraContainersSection
	if expandable then return expandable end
	if not (addon.functions and addon.functions.SettingsCreateExpandableSection) then return nil end
	expandable = addon.functions.SettingsCreateExpandableSection(category, {
		name = L["skinnerDefaultAuraIconsSection"],
		configPageKey = "DefaultAuraContainers",
		description = L["skinnerDefaultAuraIconsSectionDesc"],
		iconKey = "buff",
		modernCategory = "interface",
		modernOnly = true,
		expanded = false,
		colorizeTitle = false,
	})
	addon.SettingsLayout.suitesDefaultAuraContainersSection = expandable
	return expandable
end

function DAC.functions.InitSettings()
	if DAC.variables.settingsBuilt then return end
	if not addon.SettingsLayout or not addon.SettingsLayout.rootUI then return end
	if not addon.functions or not addon.functions.SettingsCreateExpandableSection then return end

	local category = addon.SettingsLayout.rootUI
	local expandable = ensureDefaultAuraContainersSuiteSection(category)
	if not expandable then return end
	DAC.variables.settingsBuilt = true

	addon.functions.SettingsCreateHeadline(category, L["skinnerDefaultAuraIconsSection"], { parentSection = expandable })

	addon.functions.SettingsCreateCheckbox(category, {
		var = "skinnerDefaultBuffIconsEnabled",
		text = L["skinnerDefaultBuffIconsEnabled"],
		default = false,
		func = function(value)
			local wasEnabled = addon.db["skinnerDefaultBuffIconsEnabled"] == true
			addon.db["skinnerDefaultBuffIconsEnabled"] = value == true
			if wasEnabled and value ~= true then markDefaultAuraReloadRequired() end
			refreshDefaultAuraIconSkin()
		end,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(category, {
		var = "skinnerDefaultDebuffIconsEnabled",
		text = L["skinnerDefaultDebuffIconsEnabled"],
		default = false,
		func = function(value)
			local wasEnabled = addon.db["skinnerDefaultDebuffIconsEnabled"] == true
			addon.db["skinnerDefaultDebuffIconsEnabled"] = value == true
			if wasEnabled and value ~= true then markDefaultAuraReloadRequired() end
			refreshDefaultAuraIconSkin()
		end,
		parentSection = expandable,
	})

	if isDefaultAuraIconSkinEnabled() then refreshDefaultAuraIconSkin() end
end
