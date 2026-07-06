-- luacheck: globals GetItemButtonIconTexture SetItemButtonTextureVertexColor ColorManager
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}

local Bags = addon.Bags
local L = addon.L or {}

local SKIN_PRESET_ORDER = {
	"default",
	"adventure",
	"midnight",
}

local ICON_SHAPE_ORDER = {
	"preset",
	"default",
	"square",
	"round",
	"hexagon",
}

local FRAME_BACKGROUND_ORDER = {
	"solid",
	"parchment",
	"warwithin",
}

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local DEFAULT_BUTTON_SIZE = 37
local DEFAULT_ITEM_COUNT_ANCHOR_Y = 2
local DEFAULT_ITEM_COUNT_DRAW_SUBLEVEL = 8
local DEFAULT_NORMAL_TEXTURE = "Interface\\Buttons\\UI-Quickslot2"
local DEFAULT_ICON_BORDER_TEXTURE = "Interface\\Common\\WhiteIconFrame"
local DEFAULT_PUSHED_TEXTURE = "Interface\\Buttons\\UI-Quickslot-Depress"
local DEFAULT_HIGHLIGHT_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"
local ROUND_MASK_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local HEXAGON_MASK_TEXTURE = "Interface\\AddOns\\Blizzard_SharedTalentUI\\talents-hexagon-mask.png"
local FRAME_BORDER_SKIN_VALUE = "__skin__"
local DEFAULT_FRAME_BORDER_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local ITEM_ICON_MASK_KEYS = {
	"icon",
	"Icon",
	"searchOverlay",
	"ItemContextOverlay",
	"IconOverlay",
	"IconOverlay2",
	"ReagentTint",
	"SellOverlay",
	"DestroyOverlay",
}

local ITEM_FRAME_MASK_KEYS = {
	"IconQuestTexture",
	"flash",
	"NewItemTexture",
	"BattlepayItemTexture",
	"BagIndicator",
	"ExtendedSlot",
}

local STACK_COUNT_ANCHOR_FALLBACKS = {
	TOPLEFT = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 2, y = -2, justifyH = "LEFT", justifyV = "TOP" },
	TOP = { point = "TOP", relativePoint = "TOP", x = 0, y = -2, justifyH = "CENTER", justifyV = "TOP" },
	TOPRIGHT = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -2, y = -2, justifyH = "RIGHT", justifyV = "TOP" },
	LEFT = { point = "LEFT", relativePoint = "LEFT", x = 2, y = 0, justifyH = "LEFT", justifyV = "MIDDLE" },
	CENTER = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, justifyH = "CENTER", justifyV = "MIDDLE" },
	RIGHT = { point = "RIGHT", relativePoint = "RIGHT", x = -2, y = 0, justifyH = "RIGHT", justifyV = "MIDDLE" },
	BOTTOMLEFT = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 2, y = DEFAULT_ITEM_COUNT_ANCHOR_Y, justifyH = "LEFT", justifyV = "BOTTOM" },
	BOTTOM = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = DEFAULT_ITEM_COUNT_ANCHOR_Y, justifyH = "CENTER", justifyV = "BOTTOM" },
	BOTTOMRIGHT = { point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -2, y = DEFAULT_ITEM_COUNT_ANCHOR_Y, justifyH = "RIGHT", justifyV = "BOTTOM" },
}

Bags.functions.IsRecipeUnusableByPlayer = Bags.functions.IsRecipeUnusableByPlayer
	or function(itemID, itemLink)
		local numericItemID = tonumber(itemID)
		local itemRef = itemLink or numericItemID
		if not numericItemID or not itemRef or not C_PlayerInfo or not C_PlayerInfo.CanUseItem then
			return false
		end

		local classID = select(6, GetItemInfoInstant(itemRef))
		if classID ~= (Enum and Enum.ItemClass and Enum.ItemClass.Recipe) then
			return false
		end

		return C_PlayerInfo.CanUseItem(numericItemID) == false
	end

Bags.functions.ApplyRecipeUsabilityVisual = Bags.functions.ApplyRecipeUsabilityVisual
	or function(button, isUnusableRecipe)
		if not button then
			return
		end

		local r, g, b = 1, 1, 1
		if isUnusableRecipe then
			r, g, b = 1, 0.18, 0.18
		end

		if SetItemButtonTextureVertexColor then
			SetItemButtonTextureVertexColor(button, r, g, b)
		else
			local icon = button.Icon or button.icon
			if icon and icon.SetVertexColor then
				icon:SetVertexColor(r, g, b)
			end
		end
	end

local function copyColor(color)
	return {
		color and color[1] or 0,
		color and color[2] or 0,
		color and color[3] or 0,
		color and color[4] or 1,
	}
end

local function colorToSignature(color)
	return string.format("%.3f,%.3f,%.3f,%.3f", color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1)
end

local function buildDefinition(label, colors)
	return {
		label = label,
		labelKey = "settingsSkinPreset" .. label,
		frame = {
			backdropAtlas = "questlog-frame",
			backdropColor = copyColor(colors.backdropColor),
			borderAtlas = "questlog-frame",
			borderColor = copyColor(colors.borderColor),
			dividerColor = copyColor(colors.dividerColor),
			titleColor = copyColor(colors.titleColor),
			accentColor = copyColor(colors.accentColor),
			sectionHighlightColor = copyColor(colors.sectionHighlightColor),
			assignButton = {
				backdropColor = copyColor(colors.assignBackdropColor),
				borderColor = copyColor(colors.assignBorderColor),
				plusColor = copyColor(colors.assignPlusColor),
			},
		},
		itemButton = {
			iconShape = colors.iconShape or "default",
			backgroundColor = copyColor(colors.itemBackgroundColor or { 0.07, 0.07, 0.09, 0.92 }),
			emptyBackgroundColor = copyColor(colors.itemEmptyBackgroundColor or { 0.03, 0.03, 0.04, 0.88 }),
			borderColor = copyColor(colors.itemBorderColor or colors.accentColor or { 1, 1, 1, 1 }),
			emptyBorderColor = copyColor(colors.itemEmptyBorderColor or colors.itemEmptyBackgroundColor or { 0.10, 0.10, 0.12, 0.95 }),
			highlightColor = copyColor(colors.itemHighlightColor or { 1, 1, 1, 0.16 }),
			pushedColor = copyColor(colors.itemPushedColor or { 0, 0, 0, 0.28 }),
		},
	}
end

local SKIN_PRESET_DEFINITIONS = {
	default = buildDefinition("Default", {
		backdropColor = { 0.03, 0.03, 0.04, 0.58 },
		borderColor = { 0.42, 0.39, 0.27, 0.70 },
		dividerColor = { 1.00, 1.00, 1.00, 0.08 },
		titleColor = { 1.00, 0.82, 0.00, 1.00 },
		accentColor = { 0.42, 0.39, 0.27, 1.00 },
		sectionHighlightColor = { 1.00, 1.00, 1.00, 0.08 },
		assignBackdropColor = { 0.08, 0.08, 0.10, 0.92 },
		assignBorderColor = { 0.78, 0.64, 0.18, 0.90 },
		assignPlusColor = { 1.00, 0.82, 0.00, 1.00 },
		iconShape = "default",
		itemBackgroundColor = { 0.07, 0.07, 0.09, 0.92 },
		itemEmptyBackgroundColor = { 0.09, 0.09, 0.10, 0.90 },
		itemEmptyBorderColor = { 0.19, 0.19, 0.21, 0.95 },
		itemBorderColor = { 0.42, 0.39, 0.27, 1.00 },
		itemHighlightColor = { 1.00, 1.00, 1.00, 0.15 },
		itemPushedColor = { 0.00, 0.00, 0.00, 0.26 },
	}),
	adventure = buildDefinition("Adventure", {
		backdropColor = { 0.08, 0.06, 0.03, 0.60 },
		borderColor = { 0.59, 0.45, 0.22, 0.85 },
		dividerColor = { 0.92, 0.82, 0.59, 0.10 },
		titleColor = { 1.00, 0.90, 0.61, 1.00 },
		accentColor = { 0.78, 0.64, 0.18, 1.00 },
		sectionHighlightColor = { 1.00, 0.90, 0.61, 0.10 },
		assignBackdropColor = { 0.14, 0.10, 0.04, 0.94 },
		assignBorderColor = { 0.90, 0.74, 0.27, 0.92 },
		assignPlusColor = { 1.00, 0.90, 0.61, 1.00 },
		iconShape = "hexagon",
		itemBackgroundColor = { 0.14, 0.10, 0.05, 0.92 },
		itemEmptyBackgroundColor = { 0.10, 0.08, 0.06, 0.90 },
		itemEmptyBorderColor = { 0.18, 0.14, 0.10, 0.95 },
		itemBorderColor = { 0.90, 0.74, 0.27, 1.00 },
		itemHighlightColor = { 1.00, 0.90, 0.61, 0.18 },
		itemPushedColor = { 0.18, 0.12, 0.03, 0.28 },
	}),
	midnight = buildDefinition("Midnight", {
		backdropColor = { 0.03, 0.04, 0.07, 0.72 },
		borderColor = { 0.24, 0.36, 0.55, 0.88 },
		dividerColor = { 0.67, 0.78, 1.00, 0.10 },
		titleColor = { 0.76, 0.86, 1.00, 1.00 },
		accentColor = { 0.35, 0.55, 0.82, 1.00 },
		sectionHighlightColor = { 0.67, 0.78, 1.00, 0.10 },
		assignBackdropColor = { 0.06, 0.08, 0.13, 0.95 },
		assignBorderColor = { 0.44, 0.61, 0.86, 0.92 },
		assignPlusColor = { 0.76, 0.86, 1.00, 1.00 },
		iconShape = "round",
		itemBackgroundColor = { 0.05, 0.08, 0.13, 0.94 },
		itemEmptyBackgroundColor = { 0.06, 0.08, 0.12, 0.90 },
		itemEmptyBorderColor = { 0.14, 0.18, 0.25, 0.95 },
		itemBorderColor = { 0.44, 0.61, 0.86, 1.00 },
		itemHighlightColor = { 0.76, 0.86, 1.00, 0.16 },
		itemPushedColor = { 0.03, 0.05, 0.09, 0.34 },
	}),
}

local ICON_SHAPE_DEFINITIONS = {
	default = {
		label = "Default",
		labelKey = "settingsIconShapeDefault",
		useSystemStyle = true,
	},
	square = {
		label = "Square",
		labelKey = "settingsIconShapeSquare",
		maskTexture = WHITE_TEXTURE,
		frameInset = 1,
		iconInset = 2,
	},
	round = {
		label = "Round",
		labelKey = "settingsIconShapeRound",
		maskTexture = ROUND_MASK_TEXTURE,
		frameInset = 1,
		iconInset = 4,
	},
	hexagon = {
		label = "Hexagon",
		labelKey = "settingsIconShapeHexagon",
		maskTexture = HEXAGON_MASK_TEXTURE,
		frameInset = 1,
		iconInset = 3,
	},
}

local FRAME_BACKGROUND_DEFINITIONS = {
	solid = {
		label = "Solid",
		labelKey = "settingsFrameBackgroundSolid",
		backdropAlpha = 1,
	},
	parchment = {
		label = "Parchment",
		labelKey = "settingsFrameBackgroundParchment",
		backdropColor = { 0.24, 0.16, 0.07, 1 },
		texture = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
		textureColor = { 1, 1, 1, 1 },
		textureAlpha = 1,
		shadeColor = { 0.08, 0.05, 0.02, 0.24 },
	},
	warwithin = {
		label = "The War Within",
		labelKey = "settingsFrameBackgroundTheWarWithin",
		backdropColor = { 0.02, 0.02, 0.03, 1 },
		texture = "Interface\\Credits\\CreditsScreenBackground10TheWarWithin.blp",
		textureColor = { 1, 1, 1, 1 },
		textureAlpha = 1,
		shadeColor = { 0.02, 0.02, 0.03, 0.34 },
	},
}

local function getSettings()
	return addon.GetSettings and addon.GetSettings() or (addon.DB and addon.DB.settings) or nil
end

local function normalizePresetID(value)
	if type(value) ~= "string" then
		return nil
	end

	if SKIN_PRESET_DEFINITIONS[value] then
		return value
	end

	return nil
end

local function normalizeIconShapeID(value)
	if type(value) ~= "string" then
		return nil
	end

	if value == "preset" then
		return value
	end

	if ICON_SHAPE_DEFINITIONS[value] then
		return value
	end

	return nil
end

local function normalizeFrameBackgroundID(value)
	if type(value) ~= "string" then
		return nil
	end

	if FRAME_BACKGROUND_DEFINITIONS[value] then
		return value
	end

	return nil
end

local function normalizeFrameBorderTexture(value)
	if type(value) ~= "string" or value == "" then
		return FRAME_BORDER_SKIN_VALUE
	end
	return value
end

local function normalizeFrameBorderSize(value)
	value = math.floor((tonumber(value) or 1) + 0.5)
	if value < 0 then
		value = 0
	elseif value > 64 then
		value = 64
	end
	return value
end

local function normalizeFrameBorderOffset(value)
	value = math.floor((tonumber(value) or 0) + 0.5)
	if value < -32 then
		value = -32
	elseif value > 32 then
		value = 32
	end
	return value
end

local function normalizeFrameBorderColor(color)
	if type(color) ~= "table" then
		return nil
	end

	local r = tonumber(color[1]) or tonumber(color.r)
	local g = tonumber(color[2]) or tonumber(color.g)
	local b = tonumber(color[3]) or tonumber(color.b)
	local a = tonumber(color[4]) or tonumber(color.a) or 1
	if not r or not g or not b then
		return nil
	end

	r = math.max(0, math.min(1, r))
	g = math.max(0, math.min(1, g))
	b = math.max(0, math.min(1, b))
	a = math.max(0, math.min(1, a))
	return { r, g, b, a }
end

local function unpackColor(color, defaultAlpha)
	return color and color[1] or 1,
		color and color[2] or 1,
		color and color[3] or 1,
		color and color[4] or defaultAlpha or 1
end

local function getCompositeOpacity(layerAlphas, scale)
	local remainingTransparency = 1
	for index = 1, #layerAlphas do
		local alpha = layerAlphas[index]
		if alpha and alpha > 0 then
			local layerAlpha = math.min(1, alpha * scale)
			remainingTransparency = remainingTransparency * (1 - layerAlpha)
		end
	end

	return 1 - remainingTransparency
end

local function resolveBackgroundOpacityScale(layerAlphas, targetOpacity)
	if targetOpacity <= 0 then
		return 0
	end
	if targetOpacity >= 1 then
		return 1
	end

	local maxOpacity = getCompositeOpacity(layerAlphas, 1)
	if maxOpacity <= 0 then
		return 0
	end

	local desiredOpacity = maxOpacity * targetOpacity
	local low, high = 0, 1
	for _ = 1, 10 do
		local mid = (low + high) * 0.5
		if getCompositeOpacity(layerAlphas, mid) < desiredOpacity then
			low = mid
		else
			high = mid
		end
	end

	return (low + high) * 0.5
end

local function setTextureInsets(texture, parent, inset)
	if not texture or not parent then
		return
	end

	inset = inset or 0
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
	texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
end

local function ensureTextureMask(texture, maskTexture)
	if not texture or not maskTexture or not texture.AddMaskTexture then
		return
	end

	local previousMask = texture._bagsAppliedMaskTexture
	if previousMask == maskTexture then
		return
	end

	if previousMask and texture.RemoveMaskTexture then
		texture:RemoveMaskTexture(previousMask)
	end

	texture:AddMaskTexture(maskTexture)
	texture._bagsAppliedMaskTexture = maskTexture
end

local function clearTextureMask(texture)
	if not texture or not texture._bagsAppliedMaskTexture or not texture.RemoveMaskTexture then
		return
	end

	texture:RemoveMaskTexture(texture._bagsAppliedMaskTexture)
	texture._bagsAppliedMaskTexture = nil
end

local function hideTextureRegion(texture)
	if not texture then
		return
	end

	if texture.SetAtlas then
		texture:SetAtlas(nil)
	end
	texture:SetTexture(nil)
	texture:SetAlpha(0)
	texture:Hide()
	clearTextureMask(texture)
end

local function applyCooldownRegionMask(button, maskTexture)
	local cooldown = button and button.Cooldown
	if not cooldown or not cooldown.GetRegions or not cooldown.GetNumRegions then
		return
	end

	for index = 1, cooldown:GetNumRegions() do
		local region = select(index, cooldown:GetRegions())
		if region and region.AddMaskTexture then
			if maskTexture then
				ensureTextureMask(region, maskTexture)
			else
				clearTextureMask(region)
			end
		end
	end
end

local function applyCooldownSwipeShape(button, swipeTexture)
	local cooldown = button and button.Cooldown
	if not cooldown or not cooldown.SetSwipeTexture then
		return
	end

	swipeTexture = swipeTexture or WHITE_TEXTURE
	if cooldown._bagsSwipeShapeTexture == swipeTexture then
		return
	end

	cooldown:SetSwipeTexture(swipeTexture, 0, 0, 0, 0.8)
	cooldown._bagsSwipeShapeTexture = swipeTexture
end

local function getButtonTexture(button, key)
	if not button then
		return nil
	end

	return button[key]
end

local function ensureDefaultRegionAnchor(region)
	if not region or region._bagsDefaultAnchorCaptured then
		return
	end

	local point, _, relativePoint, x, y = region:GetPoint(1)
	region._bagsDefaultAnchorPoint = point
	region._bagsDefaultRelativePoint = relativePoint or point
	region._bagsDefaultAnchorX = x or 0
	region._bagsDefaultAnchorY = y or 0
	region._bagsDefaultAnchorCaptured = true
end

local function restoreRegionAnchor(region, parent)
	if not region or not region._bagsDefaultAnchorCaptured or not parent then
		return
	end

	region:ClearAllPoints()
	region:SetPoint(
		region._bagsDefaultAnchorPoint or "CENTER",
		parent,
		region._bagsDefaultRelativePoint or region._bagsDefaultAnchorPoint or "CENTER",
		region._bagsDefaultAnchorX or 0,
		region._bagsDefaultAnchorY or 0
	)
end

local function getStackCountAnchorTarget(button, shapeDefinition)
	if not button then
		return nil
	end

	if shapeDefinition and not shapeDefinition.useSystemStyle and button.BagsShapeBackground then
		return button.BagsShapeBackground
	end

	local icon = GetItemButtonIconTexture and GetItemButtonIconTexture(button) or button.Icon or button.icon
	return icon or button
end

local function resetFontStringAutoSize(fontString)
	if not fontString then
		return
	end

	if fontString.SetWidth then
		fontString:SetWidth(0)
	end
	if fontString.SetHeight then
		fontString:SetHeight(0)
	end
end

local function reflowFontStringText(fontString)
	if not fontString or not fontString.GetText or not fontString.SetText then
		return
	end

	local text = fontString:GetText()
	if text and text ~= "" then
		fontString:SetText(text)
	end
end

local function applyCountAnchorForShape(button, shapeDefinition)
	if not button or not button.Count then
		return
	end

	local count = button.Count
	local target = getStackCountAnchorTarget(button, shapeDefinition) or button
	local anchorID = addon.GetStackCountAnchor and addon.GetStackCountAnchor() or "BOTTOMRIGHT"
	local anchorInfo = addon.GetOverlayAnchorInfo and addon.GetOverlayAnchorInfo(anchorID) or STACK_COUNT_ANCHOR_FALLBACKS[anchorID] or STACK_COUNT_ANCHOR_FALLBACKS.BOTTOMRIGHT

	count:ClearAllPoints()
	resetFontStringAutoSize(count)
	if count.SetMaxLines then
		count:SetMaxLines(1)
	end
	if count.SetWordWrap then
		count:SetWordWrap(false)
	end
	if count.SetNonSpaceWrap then
		count:SetNonSpaceWrap(false)
	end
	if count.SetIndentedWordWrap then
		count:SetIndentedWordWrap(false)
	end
	if count.SetSpacing then
		count:SetSpacing(0)
	end
	if count.SetJustifyH then
		count:SetJustifyH(anchorInfo.justifyH or "RIGHT")
	end
	if count.SetJustifyV then
		count:SetJustifyV(anchorInfo.justifyV or "BOTTOM")
	end
	if count.SetScale then
		count:SetScale(1)
	end
	if count.SetDrawLayer then
		count:SetDrawLayer("OVERLAY", DEFAULT_ITEM_COUNT_DRAW_SUBLEVEL)
	end

	count:SetPoint(
		anchorInfo.point or "BOTTOMRIGHT",
		target,
		anchorInfo.relativePoint or anchorInfo.point or "BOTTOMRIGHT",
		anchorInfo.x or 0,
		anchorInfo.y or DEFAULT_ITEM_COUNT_ANCHOR_Y
	)

	reflowFontStringText(count)
	if count.IsTruncated and count:IsTruncated() and count.GetUnboundedStringWidth and count.SetWidth then
		local unboundedWidth = tonumber(count:GetUnboundedStringWidth()) or 0
		if unboundedWidth > 0 then
			count:SetWidth(math.ceil(unboundedWidth + 2))
			reflowFontStringText(count)
		end
	end

	count._bagsStackCountLayoutSignature = addon.GetStackCountLayoutSignature and addon.GetStackCountLayoutSignature() or anchorID
end

function addon.GetStackCountLayoutSignature()
	local anchorID = addon.GetStackCountAnchor and addon.GetStackCountAnchor() or "BOTTOMRIGHT"
	local shapeID = addon.GetResolvedIconShapeID and addon.GetResolvedIconShapeID() or "default"
	local shapeDefinition = ICON_SHAPE_DEFINITIONS[shapeID] or ICON_SHAPE_DEFINITIONS.default

	return table.concat({
		"stackCountLayout:v2",
		tostring(anchorID),
		tostring(shapeID),
		tostring(shapeDefinition and shapeDefinition.iconInset or ""),
		tostring(shapeDefinition and shapeDefinition.frameInset or ""),
		tostring(addon.GetItemScale and addon.GetItemScale() or 100),
	}, "|")
end

function addon.ApplyStackCountLayout(button)
	local shapeDefinition = addon.GetActiveIconShapeDefinition and addon.GetActiveIconShapeDefinition() or ICON_SHAPE_DEFINITIONS.default
	if shapeDefinition and shapeDefinition.useSystemStyle then
		shapeDefinition = nil
	end

	applyCountAnchorForShape(button, shapeDefinition)
end

local function applyProfessionQualityOverlayLayout(button, shapeDefinition)
	local overlay = button and button.ProfessionQualityOverlay
	if not overlay then
		return
	end

	ensureDefaultRegionAnchor(overlay)
	overlay:SetScale(math.max(0.8, (button.GetWidth and button:GetWidth() or DEFAULT_BUTTON_SIZE) / DEFAULT_BUTTON_SIZE))

	if not shapeDefinition or shapeDefinition.useSystemStyle then
		clearTextureMask(overlay)
		restoreRegionAnchor(overlay, button)
		return
	end

	local iconInset = shapeDefinition.iconInset or shapeDefinition.frameInset or 0
	clearTextureMask(overlay)
	if overlay.SetDrawLayer then
		overlay:SetDrawLayer("OVERLAY", 7)
	end
	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", button, "TOPLEFT", (iconInset - 3), (2 - iconInset))
end

local function ensureItemButtonShapeElements(button)
	if not button then
		return
	end

	if button._bagsDefaultEmptyBackgroundAtlas == nil then
		button._bagsDefaultEmptyBackgroundAtlas = button.emptyBackgroundAtlas
	end
	if button._bagsDefaultEmptyBackgroundTexture == nil then
		button._bagsDefaultEmptyBackgroundTexture = button.emptyBackgroundTexture
	end

	if not button.BagsShapeBackground then
		local background = button:CreateTexture(nil, "BACKGROUND", nil, -8)
		background:SetTexture(WHITE_TEXTURE)
		button.BagsShapeBackground = background
	end

	if not button.BagsShapeOutline then
		local outline = button:CreateTexture(nil, "BACKGROUND", nil, -7)
		outline:SetTexture(WHITE_TEXTURE)
		button.BagsShapeOutline = outline
	end

	if not button.BagsShapeBorder then
		local border = button:CreateTexture(nil, "BACKGROUND", nil, -6)
		border:SetTexture(WHITE_TEXTURE)
		button.BagsShapeBorder = border
	end

	if not button.BagsShapeFrameMask then
		button.BagsShapeFrameMask = button:CreateMaskTexture(nil, "BACKGROUND")
	end

	if not button.BagsShapeIconMask then
		button.BagsShapeIconMask = button:CreateMaskTexture(nil, "BACKGROUND")
	end
end

local function resetItemButtonShape(button, qualityOverride, qualityOverrideProvided)
	if not button then
		return
	end

	local icon = GetItemButtonIconTexture and GetItemButtonIconTexture(button) or button.Icon or button.icon
	local normalTexture = button.GetNormalTexture and button:GetNormalTexture() or button.NormalTexture
	local pushedTexture = button.GetPushedTexture and button:GetPushedTexture() or button.PushedTexture
	local highlightTexture = button.GetHighlightTexture and button:GetHighlightTexture() or button.HighlightTexture
	local parent = button.GetParent and button:GetParent() or nil
	local isCombined = parent and parent.IsCombinedBagContainer and parent:IsCombinedBagContainer() or false
	local buttonWidth = math.max(1, math.floor((button.GetWidth and button:GetWidth() or DEFAULT_BUTTON_SIZE) + 0.5))
	local buttonHeight = math.max(1, math.floor((button.GetHeight and button:GetHeight() or DEFAULT_BUTTON_SIZE) + 0.5))
	local normalScale = buttonWidth / DEFAULT_BUTTON_SIZE

	if button.BagsShapeBackground then
		button.BagsShapeBackground:Hide()
	end
	if button.BagsShapeOutline then
		button.BagsShapeOutline:Hide()
	end
	if button.BagsShapeBorder then
		button.BagsShapeBorder:Hide()
	end
	button._bagsShapeMaskTexture = nil

	if button.BagsDefaultFreeSlotBackground then
		button.BagsDefaultFreeSlotBackground:Hide()
	end

	button.emptyBackgroundAtlas = button._bagsDefaultEmptyBackgroundAtlas
	button.emptyBackgroundTexture = button._bagsDefaultEmptyBackgroundTexture

	local freeSlotColor = button._bagsFreeSlotDisplayMode == "colors" and button._bagsFreeSlotColor or nil
	if button.ItemSlotBackground then
		clearTextureMask(button.ItemSlotBackground)
		if freeSlotColor then
			button.ItemSlotBackground:SetVertexColor(freeSlotColor[1] or 1, freeSlotColor[2] or 1, freeSlotColor[3] or 1)
			button.ItemSlotBackground:SetShown(true)
		else
			button.ItemSlotBackground:SetVertexColor(1, 1, 1)
			button.ItemSlotBackground:SetShown(isCombined)
		end
	end

	if freeSlotColor then
		if not button.BagsDefaultFreeSlotBackground then
			local background = button:CreateTexture(nil, "BACKGROUND", nil, -6)
			background:SetTexture(WHITE_TEXTURE)
			button.BagsDefaultFreeSlotBackground = background
		end
		button.BagsDefaultFreeSlotBackground:ClearAllPoints()
		button.BagsDefaultFreeSlotBackground:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
		button.BagsDefaultFreeSlotBackground:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
		button.BagsDefaultFreeSlotBackground:SetTexture(WHITE_TEXTURE)
		button.BagsDefaultFreeSlotBackground:SetVertexColor(freeSlotColor[1] or 1, freeSlotColor[2] or 1, freeSlotColor[3] or 1, 1)
		button.BagsDefaultFreeSlotBackground:Show()
	end

	if normalTexture then
		if button.SetNormalTexture then
			button:SetNormalTexture(DEFAULT_NORMAL_TEXTURE)
			normalTexture = button.GetNormalTexture and button:GetNormalTexture() or normalTexture
		end
		if normalTexture then
			normalTexture:ClearAllPoints()
			normalTexture:SetPoint("CENTER", button, "CENTER", 0, -1)
			normalTexture:SetSize(64 * normalScale, 64 * normalScale)
			normalTexture:SetTexture(DEFAULT_NORMAL_TEXTURE)
			normalTexture:SetAlpha(1)
			normalTexture:Show()
		end
		clearTextureMask(normalTexture)
	end

	if pushedTexture then
		pushedTexture:SetTexture(DEFAULT_PUSHED_TEXTURE)
		pushedTexture:SetVertexColor(1, 1, 1, 1)
		pushedTexture:SetBlendMode("BLEND")
		pushedTexture:ClearAllPoints()
		pushedTexture:SetAllPoints(button)
		clearTextureMask(pushedTexture)
	end

	if highlightTexture then
		highlightTexture:SetTexture(DEFAULT_HIGHLIGHT_TEXTURE)
		highlightTexture:SetVertexColor(1, 1, 1, 1)
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:ClearAllPoints()
		highlightTexture:SetAllPoints(button)
		clearTextureMask(highlightTexture)
	end

	if icon then
		icon:ClearAllPoints()
		icon:SetAllPoints(button)
		icon:SetAlpha(1)
		icon:Show()
	end

	for _, key in ipairs(ITEM_ICON_MASK_KEYS) do
		local texture = getButtonTexture(button, key)
		if texture then
			clearTextureMask(texture)
			if texture ~= icon then
				texture:ClearAllPoints()
				texture:SetAllPoints(button)
			end
		end
	end

	for _, key in ipairs(ITEM_FRAME_MASK_KEYS) do
		local texture = getButtonTexture(button, key)
		if texture then
			clearTextureMask(texture)
			if texture == button.IconQuestTexture then
				setTextureInsets(texture, button, 0)
			else
				restoreRegionAnchor(texture, button)
			end
		end
	end

	if button.IconBorder then
		button.IconBorder:ClearAllPoints()
		button.IconBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.IconBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
		button.IconBorder:SetSize(buttonWidth, buttonHeight)
		button.IconBorder:SetTexture(DEFAULT_ICON_BORDER_TEXTURE)
		button.IconBorder:SetAlpha(1)
		local quality = qualityOverride
		if quality == nil and not qualityOverrideProvided then
			quality = button._bagsRenderQuality
		end
		if quality == nil and not qualityOverrideProvided then
			quality = button._bagsWarbandRenderQuality
		end
		local hasQualityColor = ColorManager and ColorManager.GetColorDataForBagItemQuality and ColorManager.GetColorDataForBagItemQuality(quality)
		button.IconBorder:SetShown(hasQualityColor ~= nil)
	end

	if button.Cooldown then
		button.Cooldown:ClearAllPoints()
		button.Cooldown:SetAllPoints(button)
		applyCooldownRegionMask(button, nil)
		applyCooldownSwipeShape(button, nil)
	end

	applyProfessionQualityOverlayLayout(button, nil)
	applyCountAnchorForShape(button, nil)

	button._bagsAppliedIconShapeID = "default"
end

local function getResolvedItemButtonBorderColor(skinDefinition, quality)
	local commonQuality = (Enum and Enum.ItemQuality and Enum.ItemQuality.Common) or 1
	if quality ~= nil and quality ~= commonQuality and C_Item and C_Item.GetItemQualityColor then
		local r, g, b = C_Item.GetItemQualityColor(quality)
		if r and g and b then
			return r, g, b, 1
		end
	end

	local itemButton = skinDefinition and skinDefinition.itemButton or nil
	return unpackColor((itemButton and itemButton.borderColor) or (skinDefinition and skinDefinition.frame and skinDefinition.frame.accentColor) or nil, 1)
end

local function getResolvedEmptyItemButtonBorderColor(skinDefinition)
	local itemButton = skinDefinition and skinDefinition.itemButton or nil
	return unpackColor((itemButton and itemButton.emptyBorderColor) or (itemButton and itemButton.emptyBackgroundColor) or nil, 1)
end

local function applyCustomItemButtonShape(button, skinDefinition, shapeDefinition, quality)
	if not button or not skinDefinition or not shapeDefinition then
		return
	end

	ensureItemButtonShapeElements(button)
	if button.BagsDefaultFreeSlotBackground then
		button.BagsDefaultFreeSlotBackground:Hide()
	end

	local icon = GetItemButtonIconTexture and GetItemButtonIconTexture(button) or button.Icon or button.icon
	if not icon then
		return
	end

	local maskTexture = shapeDefinition.maskTexture
	local frameInset = shapeDefinition.frameInset or 0
	local iconInset = shapeDefinition.iconInset or frameInset or 0
	local itemButton = skinDefinition.itemButton or {}
	local normalTexture = button.GetNormalTexture and button:GetNormalTexture() or button.NormalTexture
	local pushedTexture = button.GetPushedTexture and button:GetPushedTexture() or button.PushedTexture
	local highlightTexture = button.GetHighlightTexture and button:GetHighlightTexture() or button.HighlightTexture
	local hasPendingRenderTexture = button._bagsHasPendingRenderTexture
	local hasWarbandPendingRenderTexture = button._bagsWarbandHasPendingRenderTexture
	local renderTexture
	if hasPendingRenderTexture then
		renderTexture = button._bagsPendingRenderTexture
	elseif hasWarbandPendingRenderTexture then
		renderTexture = button._bagsWarbandPendingRenderTexture
	else
		renderTexture = button._bagsRenderTexture
		if renderTexture == nil then
			renderTexture = button._bagsWarbandRenderTexture
		end
	end
	local freeSlotColor = not renderTexture and button._bagsFreeSlotDisplayMode == "colors" and button._bagsFreeSlotColor or nil
	local backgroundColor = freeSlotColor or (renderTexture and itemButton.backgroundColor or itemButton.emptyBackgroundColor or itemButton.backgroundColor)
	local bgR, bgG, bgB, bgA = unpackColor(backgroundColor, freeSlotColor and 1 or 0.92)
	local borderR, borderG, borderB, borderA
	if renderTexture then
		borderR, borderG, borderB, borderA = getResolvedItemButtonBorderColor(skinDefinition, quality)
	elseif freeSlotColor then
		borderR, borderG, borderB = unpackColor(freeSlotColor, 1)
		borderA = 0.9
	else
		borderR, borderG, borderB, borderA = getResolvedEmptyItemButtonBorderColor(skinDefinition)
	end
	local pushedR, pushedG, pushedB, pushedA = unpackColor(itemButton.pushedColor, 0.28)
	local highlightR, highlightG, highlightB, highlightA = unpackColor(itemButton.highlightColor, 0.16)

	button.BagsShapeFrameMask:SetTexture(maskTexture)
	setTextureInsets(button.BagsShapeFrameMask, button, frameInset)
	button.BagsShapeIconMask:SetTexture(maskTexture)
	setTextureInsets(button.BagsShapeIconMask, button, iconInset)
	button._bagsShapeMaskTexture = maskTexture

	setTextureInsets(button.BagsShapeBackground, button, iconInset)
	button.BagsShapeBackground:SetTexture(WHITE_TEXTURE)
	button.BagsShapeBackground:SetVertexColor(bgR, bgG, bgB, bgA)
	ensureTextureMask(button.BagsShapeBackground, button.BagsShapeIconMask)
	button.BagsShapeBackground:Show()

	setTextureInsets(button.BagsShapeOutline, button, math.max(0, frameInset - 1))
	button.BagsShapeOutline:SetTexture(WHITE_TEXTURE)
	button.BagsShapeOutline:SetVertexColor(0, 0, 0, renderTexture and 0 or 0.95)
	ensureTextureMask(button.BagsShapeOutline, button.BagsShapeFrameMask)
	button.BagsShapeOutline:SetShown(not renderTexture)

	setTextureInsets(button.BagsShapeBorder, button, frameInset)
	button.BagsShapeBorder:SetTexture(WHITE_TEXTURE)
	button.BagsShapeBorder:SetVertexColor(borderR, borderG, borderB, borderA)
	ensureTextureMask(button.BagsShapeBorder, button.BagsShapeFrameMask)
	button.BagsShapeBorder:Show()

	button.emptyBackgroundAtlas = nil
	button.emptyBackgroundTexture = nil

	if button.ItemSlotBackground then
		button.ItemSlotBackground:Hide()
		clearTextureMask(button.ItemSlotBackground)
	end

	if normalTexture then
		if button.ClearNormalTexture then
			button:ClearNormalTexture()
			normalTexture = button.GetNormalTexture and button:GetNormalTexture() or nil
		else
			hideTextureRegion(normalTexture)
		end
	end
	if normalTexture then
		hideTextureRegion(normalTexture)
	end
	if button.NormalTexture and button.NormalTexture ~= normalTexture then
		hideTextureRegion(button.NormalTexture)
	end

	if renderTexture then
		if icon.SetAtlas then
			icon:SetAtlas(nil)
		end
		if icon:GetTexture() ~= renderTexture then
			icon:SetTexture(renderTexture)
		end
		icon:SetAlpha(1)
		setTextureInsets(icon, button, iconInset)
		icon:SetShown(true)
		ensureTextureMask(icon, button.BagsShapeIconMask)
	else
		if icon.SetAtlas then
			icon:SetAtlas(nil)
		end
		icon:SetTexture(nil)
		icon:SetAlpha(0)
		icon:Hide()
		clearTextureMask(icon)
	end

	for _, key in ipairs(ITEM_ICON_MASK_KEYS) do
		local texture = getButtonTexture(button, key)
		if texture then
			if texture ~= icon or renderTexture then
				setTextureInsets(texture, button, iconInset)
				ensureTextureMask(texture, button.BagsShapeIconMask)
			end
		end
	end

	for _, key in ipairs(ITEM_FRAME_MASK_KEYS) do
		local texture = getButtonTexture(button, key)
		if texture then
			ensureDefaultRegionAnchor(texture)
			setTextureInsets(texture, button, frameInset)
			ensureTextureMask(texture, button.BagsShapeFrameMask)
		end
	end

	if pushedTexture then
		pushedTexture:SetTexture(WHITE_TEXTURE)
		pushedTexture:SetVertexColor(pushedR, pushedG, pushedB, pushedA)
		pushedTexture:SetBlendMode("BLEND")
		setTextureInsets(pushedTexture, button, iconInset)
		ensureTextureMask(pushedTexture, button.BagsShapeIconMask)
	end

	if highlightTexture then
		highlightTexture:SetTexture(WHITE_TEXTURE)
		highlightTexture:SetVertexColor(highlightR, highlightG, highlightB, highlightA)
		highlightTexture:SetBlendMode("ADD")
		setTextureInsets(highlightTexture, button, iconInset)
		ensureTextureMask(highlightTexture, button.BagsShapeIconMask)
	end

	if button.IconBorder then
		if button.IconBorder.SetAtlas then
			button.IconBorder:SetAtlas(nil)
		end
		button.IconBorder:SetTexture(nil)
		button.IconBorder:SetAlpha(0)
		button.IconBorder:Hide()
	end

	if button.Cooldown then
		button.Cooldown:ClearAllPoints()
		button.Cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", iconInset, -iconInset)
		button.Cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -iconInset, iconInset)
		applyCooldownRegionMask(button, button.BagsShapeIconMask)
		applyCooldownSwipeShape(button, maskTexture)
	end

	applyProfessionQualityOverlayLayout(button, shapeDefinition)
	applyCountAnchorForShape(button, shapeDefinition)

	button._bagsAppliedIconShapeID = shapeDefinition.labelKey or shapeDefinition.label or "custom"
end

function addon.RefreshItemButtonCooldownMask(button)
	if not button then
		return
	end

	if button.BagsShapeIconMask and button._bagsAppliedIconShapeID and button._bagsAppliedIconShapeID ~= "default" then
		applyCooldownRegionMask(button, button.BagsShapeIconMask)
		applyCooldownSwipeShape(button, button._bagsShapeMaskTexture)
	else
		applyCooldownRegionMask(button, nil)
		applyCooldownSwipeShape(button, nil)
	end
end

function addon.GetSkinPreset()
	local settings = getSettings()
	if not settings then
		return "default"
	end

	return normalizePresetID(settings.skinPreset) or "default"
end

function addon.GetIconShape()
	local settings = getSettings()
	if not settings then
		return "preset"
	end

	return normalizeIconShapeID(settings.iconShape) or "preset"
end

function addon.GetFrameBackground()
	local settings = getSettings()
	if not settings then
		return "solid"
	end

	return normalizeFrameBackgroundID(settings.frameBackground) or "solid"
end

function addon.GetFrameBackgroundOpacity()
	local settings = getSettings()
	local value = tonumber(settings and settings.frameBackgroundOpacity) or 60
	value = math.floor(value + 0.5)
	if value < 0 then
		value = 0
	elseif value > 100 then
		value = 100
	end
	return value
end

function addon.GetFrameBackgroundColor()
	local settings = getSettings()
	local color = settings and settings.frameBackgroundColor
	if type(color) ~= "table" then
		color = { 0.03, 0.03, 0.04 }
		if settings then
			settings.frameBackgroundColor = color
		end
	end

	local r = tonumber(color[1]) or 0.03
	local g = tonumber(color[2]) or 0.03
	local b = tonumber(color[3]) or 0.04
	if r < 0 then
		r = 0
	elseif r > 1 then
		r = 1
	end
	if g < 0 then
		g = 0
	elseif g > 1 then
		g = 1
	end
	if b < 0 then
		b = 0
	elseif b > 1 then
		b = 1
	end
	color[1], color[2], color[3] = r, g, b
	return color
end

function addon.GetFrameBorderTexture()
	local settings = getSettings()
	if not settings then
		return FRAME_BORDER_SKIN_VALUE
	end
	settings.frameBorderTexture = normalizeFrameBorderTexture(settings.frameBorderTexture)
	return settings.frameBorderTexture
end

function addon.GetFrameBorderSize()
	local settings = getSettings()
	if not settings then
		return 1
	end
	settings.frameBorderSize = normalizeFrameBorderSize(settings.frameBorderSize)
	return settings.frameBorderSize
end

function addon.GetFrameBorderOffset()
	local settings = getSettings()
	if not settings then
		return 0
	end
	settings.frameBorderOffset = normalizeFrameBorderOffset(settings.frameBorderOffset)
	return settings.frameBorderOffset
end

function addon.HasCustomFrameBorderColor()
	local settings = getSettings()
	return normalizeFrameBorderColor(settings and settings.frameBorderColor) ~= nil
end

function addon.GetFrameBorderColor(fallbackColor)
	local settings = getSettings()
	local color = normalizeFrameBorderColor(settings and settings.frameBorderColor)
	if color then
		settings.frameBorderColor = color
		return color
	end
	return copyColor(fallbackColor or { 0.35, 0.35, 0.42, 1 })
end

function addon.SetIconShape(value)
	local shapeID = normalizeIconShapeID(value)
	if not shapeID then
		return false
	end

	local settings = getSettings()
	if not settings then
		return false
	end

	if settings.iconShape == shapeID then
		return false
	end

	settings.iconShape = shapeID
	return true
end

function addon.SetFrameBackground(value)
	local backgroundID = normalizeFrameBackgroundID(value)
	if not backgroundID then
		return false
	end

	local settings = getSettings()
	if not settings then
		return false
	end

	if settings.frameBackground == backgroundID then
		return false
	end

	settings.frameBackground = backgroundID
	return true
end

function addon.SetFrameBackgroundOpacity(value)
	local settings = getSettings()
	if not settings then
		return false
	end

	value = math.floor((tonumber(value) or 60) + 0.5)
	if value < 0 then
		value = 0
	elseif value > 100 then
		value = 100
	end

	if tonumber(settings.frameBackgroundOpacity) == value then
		return false
	end

	settings.frameBackgroundOpacity = value
	return true
end

function addon.SetFrameBackgroundColor(r, g, b)
	local settings = getSettings()
	if not settings then
		return false
	end

	r = tonumber(r) or 0.03
	g = tonumber(g) or 0.03
	b = tonumber(b) or 0.04
	if r < 0 then
		r = 0
	elseif r > 1 then
		r = 1
	end
	if g < 0 then
		g = 0
	elseif g > 1 then
		g = 1
	end
	if b < 0 then
		b = 0
	elseif b > 1 then
		b = 1
	end

	local color = addon.GetFrameBackgroundColor and addon.GetFrameBackgroundColor() or {}
	if math.abs((color[1] or 0) - r) < 0.001
		and math.abs((color[2] or 0) - g) < 0.001
		and math.abs((color[3] or 0) - b) < 0.001
	then
		return false
	end

	settings.frameBackgroundColor = { r, g, b }
	return true
end

function addon.SetFrameBorderTexture(value)
	local settings = getSettings()
	if not settings then
		return false
	end

	value = normalizeFrameBorderTexture(value)
	if settings.frameBorderTexture == value then
		return false
	end

	settings.frameBorderTexture = value
	return true
end

function addon.SetFrameBorderSize(value)
	local settings = getSettings()
	if not settings then
		return false
	end

	value = normalizeFrameBorderSize(value)
	if tonumber(settings.frameBorderSize) == value then
		return false
	end

	settings.frameBorderSize = value
	return true
end

function addon.SetFrameBorderOffset(value)
	local settings = getSettings()
	if not settings then
		return false
	end

	value = normalizeFrameBorderOffset(value)
	if tonumber(settings.frameBorderOffset) == value then
		return false
	end

	settings.frameBorderOffset = value
	return true
end

function addon.SetFrameBorderColor(r, g, b, a)
	local settings = getSettings()
	if not settings then
		return false
	end

	local color = normalizeFrameBorderColor({ r, g, b, a or 1 })
	if not color then
		return false
	end

	local current = normalizeFrameBorderColor(settings.frameBorderColor)
	if current
		and math.abs((current[1] or 0) - color[1]) < 0.001
		and math.abs((current[2] or 0) - color[2]) < 0.001
		and math.abs((current[3] or 0) - color[3]) < 0.001
		and math.abs((current[4] or 1) - color[4]) < 0.001
	then
		return false
	end

	settings.frameBorderColor = color
	return true
end

function addon.ClearFrameBorderColor()
	local settings = getSettings()
	if not settings or settings.frameBorderColor == nil then
		return false
	end

	settings.frameBorderColor = nil
	return true
end

function addon.GetIconShapeOptions()
	local options = {}
	for index, shapeID in ipairs(ICON_SHAPE_ORDER) do
		if shapeID == "preset" then
			options[index] = {
				value = shapeID,
				label = L["settingsIconShapePreset"] or "Follow skin",
			}
		else
			local definition = ICON_SHAPE_DEFINITIONS[shapeID]
			options[index] = {
				value = shapeID,
				label = (definition and definition.labelKey and L[definition.labelKey]) or (definition and definition.label) or shapeID,
			}
		end
	end

	return options
end

function addon.GetFrameBackgroundOptions()
	local options = {}
	for index, backgroundID in ipairs(FRAME_BACKGROUND_ORDER) do
		local definition = FRAME_BACKGROUND_DEFINITIONS[backgroundID]
		options[index] = {
			value = backgroundID,
			label = (definition and definition.labelKey and L[definition.labelKey]) or (definition and definition.label) or backgroundID,
		}
	end

	return options
end

function addon.GetFrameBorderTextureOptions()
	local options = {
		{
			value = FRAME_BORDER_SKIN_VALUE,
			label = L["settingsFrameBorderTextureSkin"] or "Follow skin",
		},
	}
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or {}
	for i = 1, #names do
		local name = names[i]
		if type(name) == "string" and name ~= "" then
			options[#options + 1] = {
				value = name,
				label = name,
			}
		end
	end
	return options
end

function addon.GetResolvedIconShapeID()
	local shapeID = addon.GetIconShape()
	if shapeID == "preset" then
		local definition = addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or nil
		shapeID = definition and definition.itemButton and normalizeIconShapeID(definition.itemButton.iconShape) or "default"
	end

	return (shapeID and ICON_SHAPE_DEFINITIONS[shapeID] and shapeID) or "default"
end

function addon.GetActiveIconShapeDefinition()
	return ICON_SHAPE_DEFINITIONS[addon.GetResolvedIconShapeID()] or ICON_SHAPE_DEFINITIONS.default
end

function addon.SetSkinPreset(value)
	local presetID = normalizePresetID(value)
	if not presetID then
		return false
	end

	local settings = getSettings()
	if not settings then
		return false
	end

	if settings.skinPreset == presetID then
		return false
	end

	settings.skinPreset = presetID
	return true
end

function addon.GetSkinPresetOptions()
	local options = {}
	for index, presetID in ipairs(SKIN_PRESET_ORDER) do
		local definition = SKIN_PRESET_DEFINITIONS[presetID]
		options[index] = {
			value = presetID,
			label = (definition and definition.labelKey and L[definition.labelKey]) or (definition and definition.label) or presetID,
		}
	end
	return options
end

function addon.GetActiveSkinDefinition()
	local presetID = addon.GetSkinPreset() or "default"
	return SKIN_PRESET_DEFINITIONS[presetID] or SKIN_PRESET_DEFINITIONS.default
end

function addon.GetSkinSignature()
	local presetID = addon.GetSkinPreset() or "default"
	local definition = SKIN_PRESET_DEFINITIONS[presetID] or SKIN_PRESET_DEFINITIONS.default
	local frame = definition.frame or {}
	local assignButton = frame.assignButton or {}
	local itemButton = definition.itemButton or {}
	local iconShapeSetting = addon.GetIconShape() or "preset"
	local resolvedIconShapeID = addon.GetResolvedIconShapeID() or "default"

	return table.concat({
		presetID,
		iconShapeSetting,
		resolvedIconShapeID,
		tostring(addon.GetItemScale and addon.GetItemScale() or 100),
		addon.GetFrameBackground and addon.GetFrameBackground() or "solid",
		colorToSignature(addon.GetFrameBackgroundColor and addon.GetFrameBackgroundColor() or {}),
		tostring(addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 60),
		addon.GetFrameBorderTexture and addon.GetFrameBorderTexture() or FRAME_BORDER_SKIN_VALUE,
		tostring(addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1),
		tostring(addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0),
		(addon.HasCustomFrameBorderColor and addon.HasCustomFrameBorderColor()) and "custom" or "skin",
		colorToSignature(addon.GetFrameBorderColor and addon.GetFrameBorderColor(frame.borderColor) or frame.borderColor or {}),
		frame.backdropAtlas or "",
		colorToSignature(frame.backdropColor or {}),
		frame.borderAtlas or "",
		colorToSignature(frame.borderColor or {}),
		colorToSignature(frame.dividerColor or {}),
		colorToSignature(frame.titleColor or {}),
		colorToSignature(frame.accentColor or {}),
		colorToSignature(frame.sectionHighlightColor or {}),
		colorToSignature(assignButton.backdropColor or {}),
		colorToSignature(assignButton.borderColor or {}),
		colorToSignature(assignButton.plusColor or {}),
		itemButton.iconShape or "",
		colorToSignature(itemButton.backgroundColor or {}),
		colorToSignature(itemButton.borderColor or {}),
		colorToSignature(itemButton.highlightColor or {}),
		colorToSignature(itemButton.pushedColor or {}),
	}, "|")
end

function addon.ApplyFrameBackgroundSkin(frame, skin)
	if not frame or not skin then
		return
	end

	local definition = FRAME_BACKGROUND_DEFINITIONS[addon.GetFrameBackground and addon.GetFrameBackground() or "solid"] or FRAME_BACKGROUND_DEFINITIONS.solid
	local backdropR, backdropG, backdropB, backdropA = unpackColor(skin.backdropColor, 0.94)
	local backingR, backingG, backingB, backingA = backdropR, backdropG, backdropB, 0
	if definition == FRAME_BACKGROUND_DEFINITIONS.solid and addon.GetFrameBackgroundColor then
		local color = addon.GetFrameBackgroundColor()
		backdropR, backdropG, backdropB = color[1] or backdropR, color[2] or backdropG, color[3] or backdropB
	elseif definition and definition.texture and definition.backdropColor then
		backingR, backingG, backingB, backingA = unpackColor(definition.backdropColor, 1)
	end
	local requestedOpacity = (addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 60) / 100
	local textureBaseAlpha = 0
	local shadeBaseAlpha = 0

	if definition and definition.texture then
		local _, _, _, textureAlpha = unpackColor(definition.textureColor, 1)
		textureBaseAlpha = (textureAlpha or 1) * (definition.textureAlpha or 1)
		local _, _, _, resolvedShadeAlpha = unpackColor(definition.shadeColor, 0.24)
		shadeBaseAlpha = resolvedShadeAlpha or 0
	end

	local hasTextureBackground = definition and definition.texture
	local backdropBaseAlpha = hasTextureBackground and 0 or (definition.backdropAlpha or backdropA)
	local backingBaseAlpha = hasTextureBackground and backingA or 0
	local opacityScale = resolveBackgroundOpacityScale({
		backingBaseAlpha,
		backdropBaseAlpha,
		textureBaseAlpha,
		shadeBaseAlpha,
	}, requestedOpacity)

	frame:SetBackdropColor(backdropR, backdropG, backdropB, backdropBaseAlpha * opacityScale)
	local borderColor = addon.GetFrameBorderColor and addon.GetFrameBorderColor(skin.borderColor) or skin.borderColor
	frame:SetBackdropBorderColor(unpackColor(borderColor, 1))

	local backing = frame.BackgroundBackingTexture
	if not backing and hasTextureBackground then
		backing = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.BackgroundBackingTexture = backing
	end
	if backing then
		backing:ClearAllPoints()
		backing:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		backing:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		if hasTextureBackground then
			backing:SetColorTexture(backingR, backingG, backingB, backingBaseAlpha * opacityScale)
			backing:Show()
		else
			backing:SetColorTexture(0, 0, 0, 0)
			backing:Hide()
		end
	end

	local texture = frame.BackgroundTexture
	if texture then
		texture:ClearAllPoints()
		texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		if texture.SetAtlas then
			texture:SetAtlas(nil)
		end
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetBlendMode("BLEND")
		texture:SetDesaturated(false)

		if definition and definition.texture then
			texture:SetTexture(definition.texture)
			local tr, tg, tb, ta = unpackColor(definition.textureColor, 1)
			texture:SetVertexColor(tr, tg, tb, ((ta or 1) * (definition.textureAlpha or 1)) * opacityScale)
			texture:Show()
		else
			texture:SetTexture(nil)
			texture:Hide()
		end
	end

	local shade = frame.BackgroundShade
	if shade then
		shade:ClearAllPoints()
		if texture then
			shade:SetAllPoints(texture)
		else
			shade:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
			shade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		end

		if definition and definition.texture then
			local sr, sg, sb, sa = unpackColor(definition.shadeColor, 0.24)
			shade:SetColorTexture(sr, sg, sb, sa * opacityScale)
			shade:Show()
		else
			shade:SetColorTexture(0, 0, 0, 0)
			shade:Hide()
		end
	end

	local border = frame.CustomBorderFrame
	if border then
		local borderTextureSetting = addon.GetFrameBorderTexture and addon.GetFrameBorderTexture() or FRAME_BORDER_SKIN_VALUE
		local borderSize = addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1
		if borderTextureSetting == FRAME_BORDER_SKIN_VALUE then
			borderTextureSetting = DEFAULT_FRAME_BORDER_TEXTURE
		elseif addon.functions and addon.functions.ResolveLSMMedia then
			borderTextureSetting = addon.functions.ResolveLSMMedia("border", borderTextureSetting, DEFAULT_FRAME_BORDER_TEXTURE, true) or DEFAULT_FRAME_BORDER_TEXTURE
		end

		if borderSize <= 0 then
			border:Hide()
		else
			local borderOffset = addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0
			border:ClearAllPoints()
			border:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderOffset, borderOffset)
			border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderOffset, -borderOffset)
			border:SetBackdrop({
				edgeFile = borderTextureSetting,
				edgeSize = borderSize,
			})
			border:SetBackdropBorderColor(unpackColor(borderColor, 1))
			border:Show()
		end
	end
end

function addon.ApplyItemButtonSkin(button, ...)
	local qualityProvided = select("#", ...) >= 1
	local quality = ...
	local shapeDefinition = addon.GetActiveIconShapeDefinition and addon.GetActiveIconShapeDefinition() or ICON_SHAPE_DEFINITIONS.default
	if not shapeDefinition or shapeDefinition.useSystemStyle then
		resetItemButtonShape(button, quality, qualityProvided)
		return
	end

	applyCustomItemButtonShape(button, addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or SKIN_PRESET_DEFINITIONS.default, shapeDefinition, quality)
end
