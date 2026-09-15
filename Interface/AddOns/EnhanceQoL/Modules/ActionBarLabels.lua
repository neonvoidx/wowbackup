local addonName, addon = ...

addon.ActionBarLabels = addon.ActionBarLabels or {}
local Labels = addon.ActionBarLabels

local DEFAULT_ACTION_BUTTON_COUNT = _G.NUM_ACTIONBAR_BUTTONS or 12
local PET_ACTION_BUTTON_COUNT = _G.NUM_PET_ACTION_SLOTS or 10
local STANCE_ACTION_BUTTON_COUNT = _G.NUM_STANCE_SLOTS or _G.NUM_SHAPESHIFT_SLOTS or 10
local DEFAULT_BORDER_STYLE = "DEFAULT"
local BORDER_COLOR_MODE_DEFAULT = "DEFAULT"
local BORDER_COLOR_MODE_CUSTOM = "CUSTOM"
local BORDER_COLOR_MODE_CLASS = "CLASS"
local QUICK_SLOT_BORDER = "Interface\\Buttons\\UI-Quickslot2"
local DEFAULT_BORDER_EDGE_SIZE = 16
local DEFAULT_BORDER_PADDING = 0
local EXTRA_ACTION_BAR_NAME = "ExtraActionBar"
local ZONE_ABILITY_BAR_NAME = "ZoneAbilityBar"
local LSM = LibStub("LibSharedMedia-3.0", true)
local UnitClass = UnitClass

local function getDefaultFontFace()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
end

local function resolveFontFace(configured)
	local fallback = getDefaultFontFace()
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, fallback) or fallback end
	return fallback
end

local function normalizeFontStyleChoice(value, fallback)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, fallback, true)
	end
	if value ~= nil then return value end
	return fallback or "OUTLINE"
end

local function GetActionBarButtonPrefix(barName)
	if not barName then return nil, 0 end
	if barName == "MainMenuBar" or barName == "MainActionBar" then return "ActionButton", DEFAULT_ACTION_BUTTON_COUNT end
	if barName == "PetActionBar" then return "PetActionButton", PET_ACTION_BUTTON_COUNT end
	if barName == "StanceBar" then return "StanceButton", STANCE_ACTION_BUTTON_COUNT end
	return barName .. "Button", DEFAULT_ACTION_BUTTON_COUNT
end

local ACTION_BAR_NAME_LOOKUP
local function EnsureActionBarNameLookup()
	if ACTION_BAR_NAME_LOOKUP then return ACTION_BAR_NAME_LOOKUP end
	ACTION_BAR_NAME_LOOKUP = {}
	if addon.variables and addon.variables.actionBarNames then
		for _, info in ipairs(addon.variables.actionBarNames) do
			if info.name then ACTION_BAR_NAME_LOOKUP[info.name] = true end
		end
	end
	return ACTION_BAR_NAME_LOOKUP
end

local function IsExtraActionButton(button)
	if not button then return false end
	if button.isExtra == true then return true end
	if _G.ExtraActionButton1 and button == _G.ExtraActionButton1 then return true end
	return button.GetName and button:GetName() == "ExtraActionButton1"
end

local function IsZoneAbilityButton(button)
	if not button then return false end
	if button.EQOL_ActionBarName == ZONE_ABILITY_BAR_NAME then return true end
	local zoneAbilityFrame = _G.ZoneAbilityFrame
	local container = zoneAbilityFrame and zoneAbilityFrame.SpellButtonContainer
	if container and button.GetParent and button:GetParent() == container then
		button.EQOL_ActionBarName = ZONE_ABILITY_BAR_NAME
		return true
	end
	return false
end

local function DetermineButtonBarName(button)
	if not button then return nil end
	if IsExtraActionButton(button) then
		button.EQOL_ActionBarName = EXTRA_ACTION_BAR_NAME
		return EXTRA_ACTION_BAR_NAME
	end
	if IsZoneAbilityButton(button) then
		button.EQOL_ActionBarName = ZONE_ABILITY_BAR_NAME
		return ZONE_ABILITY_BAR_NAME
	end
	if button.EQOL_ActionBarName then return button.EQOL_ActionBarName end
	local lookup = EnsureActionBarNameLookup()
	local parent = button:GetParent()
	while parent do
		if parent.GetName then
			local pName = parent:GetName()
			if pName and lookup[pName] then
				button.EQOL_ActionBarName = pName
				return pName
			end
		end
		parent = parent:GetParent()
	end
	return nil
end

local function ForEachActionButton(callback)
	if type(callback) ~= "function" then return end
	local list = addon.variables and addon.variables.actionBarNames
	if not list then return end
	local seen = {}
	for _, info in ipairs(list) do
		local prefix, count = GetActionBarButtonPrefix(info.name)
		if prefix and count then
			for i = 1, count do
				local button = _G[prefix .. i]
				if button and not seen[button] then
					seen[button] = true
					if not button.EQOL_ActionBarName then button.EQOL_ActionBarName = info.name end
					callback(button, info, i)
				end
			end
		end
	end
end

local function ForEachZoneAbilityButton(callback)
	if type(callback) ~= "function" then return end
	local zoneAbilityFrame = _G.ZoneAbilityFrame
	local container = zoneAbilityFrame and zoneAbilityFrame.SpellButtonContainer
	if not container or not container.EnumerateActive then return end
	for spellButton in container:EnumerateActive() do
		if spellButton then
			spellButton.EQOL_ActionBarName = ZONE_ABILITY_BAR_NAME
			callback(spellButton)
		end
	end
end

local function ForEachHotkeyButton(callback)
	if type(callback) ~= "function" then return end
	local seen = {}
	ForEachActionButton(function(button, info, index)
		seen[button] = true
		callback(button, info, index)
	end)

	local extraActionButton = _G.ExtraActionButton1
	if extraActionButton and not seen[extraActionButton] then
		callback(extraActionButton, {
			name = EXTRA_ACTION_BAR_NAME,
			text = (addon.L and addon.L["actionBarExtraActionButton"]) or "Extra Action Button",
		}, 1)
	end
end

local function ForEachActionButtonBorderTarget(callback)
	if type(callback) ~= "function" then return end
	local seen = {}
	local function visit(button)
		if not button or seen[button] then return end
		seen[button] = true
		callback(button)
	end

	ForEachActionButton(function(button) visit(button) end)
	visit(_G.ExtraActionButton1)
	ForEachZoneAbilityButton(visit)
end

local function GetNormalTexture(button)
	if not button then return nil end
	if button.NormalTexture then return button.NormalTexture end
	if button.GetNormalTexture then return button:GetNormalTexture() end
	return nil
end

local function GetBorderEdgeSize()
	if not addon.db then return DEFAULT_BORDER_EDGE_SIZE end
	local value = tonumber(addon.db.actionBarBorderEdgeSize)
	if value == nil then value = DEFAULT_BORDER_EDGE_SIZE end
	if value < 1 then value = 1 end
	if value > 64 then value = 64 end
	return value
end

local function GetBorderPadding()
	if not addon.db then return DEFAULT_BORDER_PADDING end
	local value = tonumber(addon.db.actionBarBorderPadding)
	if value == nil then value = DEFAULT_BORDER_PADDING end
	if value < -32 then value = -32 end
	if value > 32 then value = 32 end
	return value
end

local function GetBorderColorMode()
	if not addon.db then return BORDER_COLOR_MODE_DEFAULT end
	local mode = addon.db.actionBarBorderColorMode
	if mode == nil then
		if addon.db.actionBarBorderColoring then return BORDER_COLOR_MODE_CUSTOM end
		return BORDER_COLOR_MODE_DEFAULT
	end
	if mode ~= BORDER_COLOR_MODE_CUSTOM and mode ~= BORDER_COLOR_MODE_CLASS then return BORDER_COLOR_MODE_DEFAULT end
	return mode
end

local function GetPlayerClassBorderColor()
	local classToken = UnitClass and select(2, UnitClass("player")) or nil
	if not classToken then return 1, 1, 1, 1 end

	local colorObj = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classToken)
	if colorObj and colorObj.r and colorObj.g and colorObj.b then return colorObj.r, colorObj.g, colorObj.b, 1 end

	local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classToken]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken])
	if color and color.r and color.g and color.b then return color.r, color.g, color.b, color.a or 1 end

	return 1, 1, 1, 1
end

local function GetBorderColor()
	local mode = GetBorderColorMode()
	if mode == BORDER_COLOR_MODE_CLASS then return GetPlayerClassBorderColor() end
	if mode ~= BORDER_COLOR_MODE_CUSTOM then return 1, 1, 1, 1 end

	local col = addon.db.actionBarBorderColor or {}
	local r = tonumber(col.r) or 1
	local g = tonumber(col.g) or 1
	local b = tonumber(col.b) or 1
	local a = tonumber(col.a) or 1
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
	if a < 0 then
		a = 0
	elseif a > 1 then
		a = 1
	end
	return r, g, b, a
end

local function MarkActionButtonBorderStateDirty()
	Labels._actionButtonBorderStateDirty = true
	Labels._actionButtonBorderStateVersion = (Labels._actionButtonBorderStateVersion or 0) + 1
end

function Labels.InvalidateActionButtonBorderState()
	MarkActionButtonBorderStateDirty()
end

local function BuildLSMBorderCache()
	local cache = {}
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("border") or {}
	for _, path in pairs(hash) do
		if type(path) == "string" and path ~= "" then cache[path] = true end
	end
	Labels._lsmBorderCache = cache
end

local function IsLSMBorderPath(path)
	if not path or path == "" then return false end
	if not Labels._lsmBorderCache then BuildLSMBorderCache() end
	return Labels._lsmBorderCache and Labels._lsmBorderCache[path] == true
end

function Labels.ResetBorderCache()
	Labels._lsmBorderCache = nil
	MarkActionButtonBorderStateDirty()
end

local function IsValidCustomBorderStyle(style)
	if style == QUICK_SLOT_BORDER then return true end
	return IsLSMBorderPath(style)
end

local function GetCustomBorderStyle()
	if not addon.db then return DEFAULT_BORDER_STYLE end
	local style = addon.db.actionBarBorderStyle
	if type(style) ~= "string" or style == "" then return DEFAULT_BORDER_STYLE end
	if style ~= DEFAULT_BORDER_STYLE and not IsValidCustomBorderStyle(style) then return DEFAULT_BORDER_STYLE end
	return style
end

local function IsCustomBorderStyle(style) return type(style) == "string" and style ~= "" and style ~= DEFAULT_BORDER_STYLE end

local function IsActionButtonBorderFeatureEnabled()
	if not addon.db then return false end
	return addon.db.actionBarHideBorders == true or IsCustomBorderStyle(GetCustomBorderStyle())
end

local function BuildActionButtonBorderState(state)
	state = state or {}
	local style = GetCustomBorderStyle()
	local hasCustom = IsCustomBorderStyle(style)
	local hide = addon.db and (addon.db.actionBarHideBorders or hasCustom) or hasCustom
	local usesBackdrop = hasCustom and IsLSMBorderPath(style) or false
	local padding = hasCustom and GetBorderPadding() or DEFAULT_BORDER_PADDING
	local edgeSize = usesBackdrop and GetBorderEdgeSize() or DEFAULT_BORDER_EDGE_SIZE
	local r, g, b, a = 1, 1, 1, 1
	if hasCustom then r, g, b, a = GetBorderColor() end
	state.style = style
	state.hasCustom = hasCustom
	state.hide = hide == true
	state.usesBackdrop = usesBackdrop == true
	state.padding = padding
	state.edgeSize = edgeSize
	state.colorR = r
	state.colorG = g
	state.colorB = b
	state.colorA = a
	state.enabled = state.hide or state.hasCustom
	state.version = Labels._actionButtonBorderStateVersion or 0
	return state
end

local function GetCachedActionButtonBorderState()
	if Labels._actionButtonBorderStateDirty ~= false or not Labels._actionButtonBorderState then
		Labels._actionButtonBorderState = BuildActionButtonBorderState(Labels._actionButtonBorderState)
		Labels._actionButtonBorderStateDirty = false
	end
	return Labels._actionButtonBorderState
end

local function EnsureCustomBorderTexture(button)
	if not button then return nil end
	local border = button.EQOL_CustomBorder
	if border then return border end
	border = button:CreateTexture(nil, "BORDER")
	border:SetBlendMode("BLEND")
	border:Hide()
	button.EQOL_CustomBorder = border
	return border
end

local function UpdateCustomBorderSizing(border, button, padding)
	if not border or not button then return end
	padding = tonumber(padding) or DEFAULT_BORDER_PADDING
	border:ClearAllPoints()
	border:SetPoint("CENTER", button, "CENTER", 0, 0)
	local normalTexture = GetNormalTexture(button)
	if normalTexture then
		local width, height = normalTexture:GetSize()
		if width and width > 0 and height and height > 0 then
			local newWidth = width + padding * 2
			local newHeight = height + padding * 2
			if newWidth < 1 then newWidth = 1 end
			if newHeight < 1 then newHeight = 1 end
			border:SetSize(newWidth, newHeight)
			return
		end
	end
	border:SetAllPoints()
end

local function EnsureCustomBorderFrame(button)
	if not button then return nil end
	local frame = button.EQOL_CustomBorderFrame
	if frame then return frame end
	frame = CreateFrame("Frame", nil, button, "BackdropTemplate")
	frame:SetFrameStrata(button:GetFrameStrata())
	frame:SetFrameLevel((button:GetFrameLevel() or 0) + 1)
	frame:EnableMouse(false)
	frame:Hide()
	button.EQOL_CustomBorderFrame = frame
	return frame
end

local function UpdateCustomBorderFrame(frame, button, padding)
	if not frame or not button then return end
	padding = tonumber(padding) or DEFAULT_BORDER_PADDING
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", button, "TOPLEFT", -padding, padding)
	frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", padding, -padding)
end

local function ApplyBackdropBorder(button, borderState)
	if not borderState then return end
	local frame = EnsureCustomBorderFrame(button)
	if not frame then return end
	UpdateCustomBorderFrame(frame, button, borderState.padding)
	local style = borderState.style
	local edgeSize = borderState.edgeSize
	if frame.EQOL_BorderStyle ~= style or frame.EQOL_BorderEdgeSize ~= edgeSize then
		frame:SetBackdrop({ edgeFile = style, edgeSize = edgeSize })
		frame.EQOL_BorderStyle = style
		frame.EQOL_BorderEdgeSize = edgeSize
	end
	local r, g, b, a = borderState.colorR, borderState.colorG, borderState.colorB, borderState.colorA
	frame:SetBackdropBorderColor(r, g, b, a)
	frame:Show()
end

local function ApplyCustomBorder(button, borderState)
	local border = button and button.EQOL_CustomBorder
	local borderFrame = button and button.EQOL_CustomBorderFrame
	if not (borderState and borderState.hasCustom) then
		if border then border:Hide() end
		if borderFrame then borderFrame:Hide() end
		return
	end

	local style = borderState.style
	if borderState.usesBackdrop then
		if border then border:Hide() end
		ApplyBackdropBorder(button, borderState)
		return
	end

	if borderFrame then borderFrame:Hide() end
	border = EnsureCustomBorderTexture(button)
	if not border then return end
	UpdateCustomBorderSizing(border, button, borderState.padding)
	if border.EQOL_BorderStyle ~= style then
		border:SetTexture(style)
		border.EQOL_BorderStyle = style
	end
	if style == QUICK_SLOT_BORDER then
		border:SetTexCoord(0.2, 0.8, 0.2, 0.8)
	else
		border:SetTexCoord(0, 1, 0, 1)
	end
	local r, g, b, a = borderState.colorR, borderState.colorG, borderState.colorB, borderState.colorA
	border:SetVertexColor(r, g, b, a)
	border:Show()
end

local function ApplyBorderVisibility(button, hide)
	local normalTexture = GetNormalTexture(button)
	if not normalTexture then return end

	if hide then
		if not normalTexture.EQOL_OriginalBorderState then normalTexture.EQOL_OriginalBorderState = {
			alpha = normalTexture:GetAlpha(),
			shown = normalTexture:IsShown() ~= false,
		} end
		normalTexture:SetAlpha(0)
		normalTexture:Hide()
		normalTexture.EQOL_BorderHiddenByEQOL = true
	elseif normalTexture.EQOL_BorderHiddenByEQOL then
		local restore = normalTexture.EQOL_OriginalBorderState or {}
		normalTexture:SetAlpha(restore.alpha or 1)
		if restore.shown == false then
			normalTexture:Hide()
		else
			normalTexture:Show()
		end
		normalTexture.EQOL_BorderHiddenByEQOL = nil
		normalTexture.EQOL_OriginalBorderState = nil
	end
end

local function RefreshButtonBorder(button, borderState)
	if not addon.db then return end
	borderState = borderState or GetCachedActionButtonBorderState()
	local isActionButton = DetermineButtonBarName(button) ~= nil
	if not isActionButton then
		ApplyBorderVisibility(button, false)
		ApplyCustomBorder(button, nil)
		return
	end
	ApplyBorderVisibility(button, borderState.hide)
	ApplyCustomBorder(button, borderState)
end

function Labels.RefreshActionButtonBorders(reason)
	local wasActive = Labels._actionButtonBorderFeatureActive == true
	local isActive = IsActionButtonBorderFeatureEnabled()
	Labels._actionButtonBorderFeatureActive = isActive
	if not isActive and not wasActive then return end
	if isActive then
		if Labels.EnsureActionButtonArtHook then Labels.EnsureActionButtonArtHook() end
		if Labels.EnsureZoneAbilityBorderHook then Labels.EnsureZoneAbilityBorderHook() end
	end
	MarkActionButtonBorderStateDirty()
	local borderState = GetCachedActionButtonBorderState()
	if reason == "PLAYER_LOGIN" and Labels._actionBarBorderFullRefreshVersion == borderState.version then return end
	ForEachActionButtonBorderTarget(function(button) RefreshButtonBorder(button, borderState) end)
	Labels._actionBarBorderFullRefreshVersion = borderState.version
end

function Labels.RefreshActionButtonBorder(button)
	if Labels._actionButtonBorderFeatureActive ~= true then return end
	RefreshButtonBorder(button)
end

local function SyncRangeOverlayMask(btn, icon, overlay)
	if not (btn and icon and overlay) then return end
	if not overlay.AddMaskTexture then return end

	local currentMasks = overlay.EQOL_IconMasks
	local currentCount = type(currentMasks) == "table" and #currentMasks or 0
	local iconMaskCount = 0
	if icon.GetNumMaskTextures and icon.GetMaskTexture then iconMaskCount = icon:GetNumMaskTextures() or 0 end
	local fallbackMask = btn.IconMask
	local wantedCount = iconMaskCount
	if wantedCount == 0 and fallbackMask then wantedCount = 1 end

	local same = currentCount == wantedCount
	if same then
		for i = 1, wantedCount do
			local wantedMask
			if iconMaskCount > 0 then
				wantedMask = icon:GetMaskTexture(i)
			else
				wantedMask = fallbackMask
			end
			if currentMasks[i] ~= wantedMask then
				same = false
				break
			end
		end
	end
	if same then return end

	if type(currentMasks) == "table" and overlay.RemoveMaskTexture then
		for i = 1, #currentMasks do
			local mask = currentMasks[i]
			if mask then overlay:RemoveMaskTexture(mask) end
		end
	end

	if wantedCount > 0 then
		local newMasks = {}
		for i = 1, wantedCount do
			local wantedMask
			if iconMaskCount > 0 then
				wantedMask = icon:GetMaskTexture(i)
			else
				wantedMask = fallbackMask
			end
			if wantedMask then
				overlay:AddMaskTexture(wantedMask)
				newMasks[#newMasks + 1] = wantedMask
			end
		end
		overlay.EQOL_IconMasks = newMasks
	else
		overlay.EQOL_IconMasks = nil
	end
end

local function EnsureRangeOverlay(btn, icon)
	if not (btn and icon and btn.CreateTexture) then return nil end
	local overlay = btn.EQOL_RangeOverlay
	if not overlay then
		overlay = btn:CreateTexture(nil, "OVERLAY")
		overlay:Hide()
		btn.EQOL_RangeOverlay = overlay
	end
	if overlay.EQOL_AnchorIcon ~= icon then
		overlay:ClearAllPoints()
		overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
		overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
		overlay.EQOL_AnchorIcon = icon
	end
	SyncRangeOverlayMask(btn, icon, overlay)
	return overlay
end

local function ShowRangeOverlay(btn, show)
	local icon = btn and (btn.icon or btn.Icon)
	if not icon or not btn then return end
	btn.EQOL_RangeOverlayActive = show
	local overlay = EnsureRangeOverlay(btn, icon)
	if not overlay then return end
	if show and addon.db and addon.db.actionBarFullRangeColoring then
		local col = addon.db.actionBarFullRangeColor or { r = 1, g = 0.1, b = 0.1 }
		local alpha = col.a
		if alpha == nil then alpha = 0.45 end
		overlay:SetColorTexture(col.r or 1, col.g or 0.1, col.b or 0.1, alpha)
		overlay:Show()
	else
		overlay:Hide()
	end
end

function Labels.RefreshAllRangeOverlays()
	ForEachActionButton(function(button) ActionButton_UpdateRangeIndicator(button) end)
end

local function UpdateMacroNameVisibility(button, hide)
	if not button or not button.GetName then return end

	local nameFrame = button.Name or _G[button:GetName() .. "Name"]
	if not nameFrame then return end

	if hide then
		if not nameFrame.EQOL_IsHiddenByEQOL then
			nameFrame.EQOL_OriginalAlpha = nameFrame:GetAlpha()
			nameFrame:SetAlpha(0)
			nameFrame.EQOL_IsHiddenByEQOL = true
		end
	elseif nameFrame.EQOL_IsHiddenByEQOL then
		nameFrame:SetAlpha(nameFrame.EQOL_OriginalAlpha or 1)
		nameFrame.EQOL_IsHiddenByEQOL = nil
	end
end

local ApplyTextColorOverride
local RestoreTextColorOverride
local ApplyFontWithFallback

function Labels.RefreshAllMacroNameVisibility()
	local hide = addon.db and addon.db.hideMacroNames
	local overrideEnabled = addon.db and addon.db.actionBarMacroFontOverride and not hide
	local fontFace = resolveFontFace(addon.db and addon.db.actionBarMacroFontFace)
	local fontSize = tonumber(addon.db and addon.db.actionBarMacroFontSize) or 12
	local fontOutline = addon.db and addon.db.actionBarMacroFontOutline or "OUTLINE"
	local fontColor = addon.db and addon.db.actionBarMacroFontColor
	if fontSize < 6 then fontSize = 6 end
	if fontSize > 32 then fontSize = 32 end
	ForEachActionButton(function(button, info)
		if info.name ~= "PetActionBar" and info.name ~= "StanceBar" then
			UpdateMacroNameVisibility(button, hide)
			local nameFrame = button.Name or (button.GetName and _G[button:GetName() .. "Name"])
			if nameFrame and nameFrame.SetFont then
				if overrideEnabled then
					if not nameFrame.EQOL_OriginalMacroFont then
						local face, size, outline = nameFrame:GetFont()
						nameFrame.EQOL_OriginalMacroFont = { face = face, size = size, outline = outline }
					end
					ApplyFontWithFallback(nameFrame, fontFace or getDefaultFontFace(), fontSize, normalizeFontStyleChoice(fontOutline, "OUTLINE"))
					nameFrame.EQOL_UsingMacroOverride = true
					ApplyTextColorOverride(nameFrame, fontColor, "EQOL_OriginalMacroColor", "EQOL_UsingMacroColorOverride")
				else
					if nameFrame.EQOL_UsingMacroOverride then
						local orig = nameFrame.EQOL_OriginalMacroFont or {}
						local face = orig.face or getDefaultFontFace()
						local size = orig.size or 12
						local outline = orig.outline or "OUTLINE"
						ApplyFontWithFallback(nameFrame, face, size, outline)
						nameFrame.EQOL_UsingMacroOverride = nil
						nameFrame.EQOL_OriginalMacroFont = nil
					end
					RestoreTextColorOverride(nameFrame, "EQOL_OriginalMacroColor", "EQOL_UsingMacroColorOverride")
				end
			end
		end
	end)
end

local function GetActionButtonHotkey(button)
	if not button then return nil end
	if button.HotKey then return button.HotKey end
	if button.GetName then return _G[button:GetName() .. "HotKey"] end
	return nil
end

local function GetActionButtonCount(button)
	if not button then return nil end
	if button.Count then return button.Count end
	if button.GetName then return _G[button:GetName() .. "Count"] end
	return nil
end

local VALID_TEXT_ANCHORS = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local function NormalizeTextAnchor(anchor, fallback)
	local value = type(anchor) == "string" and string.upper(anchor) or nil
	if VALID_TEXT_ANCHORS[value] then return value end
	return fallback
end

local function NormalizeTextOffset(value, fallback)
	local number = tonumber(value)
	if number == nil then number = fallback or 0 end
	if number < -50 then
		number = -50
	elseif number > 50 then
		number = 50
	end
	return math.floor(number + 0.5)
end

local function StoreRegionAnchorPoints(region, key)
	if not region then return end
	local numPoints = region.GetNumPoints and region:GetNumPoints() or 0
	local points = {}
	for index = 1, numPoints do
		local point, relativeTo, relativePoint, xOfs, yOfs = region:GetPoint(index)
		points[#points + 1] = {
			point = point,
			relativeTo = relativeTo,
			relativePoint = relativePoint,
			xOfs = xOfs,
			yOfs = yOfs,
		}
	end
	region[key] = points
end

local function RestoreRegionAnchorPoints(region, key)
	if not region then return end
	local points = region[key]
	region:ClearAllPoints()
	if type(points) == "table" and #points > 0 then
		for _, info in ipairs(points) do
			region:SetPoint(info.point, info.relativeTo, info.relativePoint, info.xOfs, info.yOfs)
		end
	end
	region[key] = nil
end

local function GetActionButtonAnchorTarget(region, button)
	if region and region.GetParent then
		local parent = region:GetParent()
		if parent and parent ~= button and parent.GetParent and parent:GetParent() == button then return parent end
	end
	return button
end

local function ApplyRegionPositionOverride(region, button, enabled, anchor, offsetX, offsetY, stateKey, originalKey, collapseWidth, originalWidthKey)
	if not (region and button) then return end
	if enabled then
		if not region[stateKey] then StoreRegionAnchorPoints(region, originalKey) end
		if collapseWidth and originalWidthKey and not region[originalWidthKey] and region.GetWidth then region[originalWidthKey] = region:GetWidth() end
		local target = GetActionButtonAnchorTarget(region, button)
		local point = NormalizeTextAnchor(anchor, "CENTER")
		region:ClearAllPoints()
		if collapseWidth and region.SetWidth then region:SetWidth(0) end
		region:SetPoint(point, target, point, NormalizeTextOffset(offsetX, 0), NormalizeTextOffset(offsetY, 0))
		region[stateKey] = true
	else
		if region[stateKey] then
			RestoreRegionAnchorPoints(region, originalKey)
			if originalWidthKey and region[originalWidthKey] and region.SetWidth then region:SetWidth(region[originalWidthKey]) end
			if originalWidthKey then region[originalWidthKey] = nil end
			region[stateKey] = nil
		else
			StoreRegionAnchorPoints(region, originalKey)
		end
	end
end

local function NormalizeFontSize(size, minValue, maxValue)
	local value = tonumber(size) or minValue
	if value < minValue then value = minValue end
	if value > maxValue then value = maxValue end
	return value
end

Labels.NormalizeFontSize = NormalizeFontSize

ApplyFontWithFallback = function(region, face, size, outline)
	if not region or not region.SetFont then return end
	local styleChoice = normalizeFontStyleChoice(outline, "OUTLINE")
	if addon.functions and addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(region, face, size, styleChoice, getDefaultFontFace(), "OUTLINE")
		return
	end
	local resolvedFace = resolveFontFace(face)
	local ok = region:SetFont(resolvedFace or getDefaultFontFace(), size, styleChoice or "OUTLINE")
	if not ok then region:SetFont(getDefaultFontFace(), size, styleChoice or "OUTLINE") end
end

local function NormalizeColorComponent(value, fallback)
	local number = tonumber(value)
	if number == nil then number = fallback or 1 end
	if number < 0 then
		number = 0
	elseif number > 1 then
		number = 1
	end
	return number
end

local function NormalizeTextColor(color, fallbackR, fallbackG, fallbackB, fallbackA)
	if type(color) ~= "table" then return fallbackR or 1, fallbackG or 1, fallbackB or 1, fallbackA or 1 end
	local r = NormalizeColorComponent(color.r, fallbackR or 1)
	local g = NormalizeColorComponent(color.g, fallbackG or 1)
	local b = NormalizeColorComponent(color.b, fallbackB or 1)
	local a = NormalizeColorComponent(color.a, fallbackA or 1)
	return r, g, b, a
end

ApplyTextColorOverride = function(region, configuredColor, originalKey, activeKey)
	if not region or not region.SetTextColor then return end
	if not region[originalKey] then
		local r, g, b, a = region:GetTextColor()
		region[originalKey] = { r = r or 1, g = g or 1, b = b or 1, a = a or 1 }
	end
	local fallback = region[originalKey] or {}
	local r, g, b, a = NormalizeTextColor(configuredColor, fallback.r or 1, fallback.g or 1, fallback.b or 1, fallback.a or 1)
	region:SetTextColor(r, g, b, a)
	region[activeKey] = true
end

RestoreTextColorOverride = function(region, originalKey, activeKey)
	if not region or not region.SetTextColor then return end
	if not region[activeKey] then return end
	local original = region[originalKey] or {}
	local r, g, b, a = NormalizeTextColor(original, 1, 1, 1, 1)
	region:SetTextColor(r, g, b, a)
	region[activeKey] = nil
	region[originalKey] = nil
end

local function ApplyImmediateTextColor(region, color, fallbackR, fallbackG, fallbackB, fallbackA)
	if not region or not region.SetTextColor then return end
	local r, g, b, a = NormalizeTextColor(color, fallbackR or 1, fallbackG or 1, fallbackB or 1, fallbackA or 1)
	region:SetTextColor(r, g, b, a)
end

local function ApplyCountStyling(button)
	if not addon.db then return end
	local count = GetActionButtonCount(button)
	if not count then return end
	local positionOverride = addon.db.actionBarCountFontOverride == true
	ApplyRegionPositionOverride(
		count,
		button,
		positionOverride,
		addon.db.actionBarCountAnchor,
		addon.db.actionBarCountOffsetX,
		addon.db.actionBarCountOffsetY,
		"EQOL_UsingCountPositionOverride",
		"EQOL_OriginalCountPoints"
	)
	local face = resolveFontFace(addon.db.actionBarCountFontFace)
	local size = NormalizeFontSize(addon.db.actionBarCountFontSize, 6, 32)
	local outline = addon.db.actionBarCountFontOutline or "OUTLINE"
	local fontColor = addon.db.actionBarCountFontColor
	if addon.db.actionBarCountFontOverride then
		if not count.EQOL_OriginalCountFont then
			local oface, osize, ooutline = count:GetFont()
			count.EQOL_OriginalCountFont = { face = oface, size = osize, outline = ooutline }
		end
		ApplyFontWithFallback(count, face, size, outline)
		count.EQOL_UsingCountOverride = true
		ApplyTextColorOverride(count, fontColor, "EQOL_OriginalCountColor", "EQOL_UsingCountColorOverride")
	else
		if count.EQOL_UsingCountOverride then
			local orig = count.EQOL_OriginalCountFont or {}
			local restoreFace = resolveFontFace(orig.face)
			local restoreSize = orig.size or size
			local restoreOutline = orig.outline or "OUTLINE"
			ApplyFontWithFallback(count, restoreFace, restoreSize, restoreOutline)
			count.EQOL_UsingCountOverride = nil
			count.EQOL_OriginalCountFont = nil
		end
		RestoreTextColorOverride(count, "EQOL_OriginalCountColor", "EQOL_UsingCountColorOverride")
	end
end

local function ShouldHideHotkey(barName, button)
	if not addon.db then return false end
	if not barName then return false end
	local overrides = addon.db.actionBarHiddenHotkeys
	if type(overrides) ~= "table" then return false end
	return overrides[barName] == true
end

local function UpdateHotkeyVisibility(hotkey, hide)
	if not hotkey or not hotkey.SetAlpha then return end
	if hide then
		if not hotkey.EQOL_PreviousAlpha or hotkey.EQOL_PreviousAlpha <= 0 then hotkey.EQOL_PreviousAlpha = hotkey:GetAlpha() end
		if not hotkey.EQOL_PreviousAlpha or hotkey.EQOL_PreviousAlpha <= 0 then hotkey.EQOL_PreviousAlpha = 1 end
		hotkey:SetAlpha(0)
		hotkey.EQOL_Hidden = true
	else
		if hotkey.EQOL_Hidden then
			hotkey:SetAlpha(hotkey.EQOL_PreviousAlpha or 1)
			hotkey.EQOL_PreviousAlpha = nil
			hotkey.EQOL_Hidden = nil
		end
	end
end

local function RefreshHotkeyVisibility(button, barNameOverride)
	if not button then return end
	local hotkey = GetActionButtonHotkey(button)
	if not hotkey then return end
	local barName = barNameOverride or DetermineButtonBarName(button)
	UpdateHotkeyVisibility(hotkey, ShouldHideHotkey(barName, button))
end

local HOTKEY_SHORT_REPLACEMENTS = {
	{ "MOUSE WHEEL DOWN", "MWD" },
	{ "MOUSE WHEEL UP", "MWU" },
	{ "MOUSE WHEEL", "MW" },
	{ "MOUSE BUTTON", "M" },
	{ "MOUSEBUTTON", "M" },
	{ "MOUSE", "M" },
	{ "BUTTON", "M" },
	{ "NUM PAD ", "N" },
	{ "NUMPAD", "N" },
	{ "PAGEUP", "PU" },
	{ "PAGEDOWN", "PD" },
	{ "SPACEBAR", "SP" },
	{ "BACKSPACE", "BS" },
	{ "DELETE", "DEL" },
	{ "INSERT", "INS" },
	{ "HOME", "HM" },
	{ "ARROW", "" },
	{ "CAPSLOCK", "CAPS" },
}

local function EscapePattern(text)
	if type(text) ~= "string" or text == "" then return "" end
	return text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function GetGlobalUpper(key, fallback)
	local value = _G[key]
	if type(value) ~= "string" or value == "" then value = fallback end
	if type(value) ~= "string" or value == "" then return nil end
	return string.upper(value)
end

local mouseButtonShortcutPatterns
local function EnsureMouseButtonShortcuts()
	if mouseButtonShortcutPatterns then return mouseButtonShortcutPatterns end
	mouseButtonShortcutPatterns = {}
	for i = 1, 31 do
		local label = GetGlobalUpper("KEY_BUTTON" .. i)
		if label then table.insert(mouseButtonShortcutPatterns, { pattern = EscapePattern(label), replacement = "M" .. i }) end
	end
	local mwDown = GetGlobalUpper("KEY_MOUSEWHEELDOWN")
	if mwDown then table.insert(mouseButtonShortcutPatterns, { pattern = EscapePattern(mwDown), replacement = "MWD" }) end
	local mwUp = GetGlobalUpper("KEY_MOUSEWHEELUP")
	if mwUp then table.insert(mouseButtonShortcutPatterns, { pattern = EscapePattern(mwUp), replacement = "MWU" }) end
	return mouseButtonShortcutPatterns
end

local modifierShortcutPatterns
local function EnsureModifierShortcutPatterns()
	if modifierShortcutPatterns then return modifierShortcutPatterns end
	modifierShortcutPatterns = {}
	local function addModifier(globalKey, replacement, fallback)
		local text = GetGlobalUpper(globalKey, fallback)
		if text and text ~= "" then table.insert(modifierShortcutPatterns, { pattern = EscapePattern(text) .. "%-", replacement = replacement }) end
	end
	addModifier("SHIFT_KEY_TEXT", "S", "SHIFT")
	addModifier("CTRL_KEY_TEXT", "C", "CTRL")
	addModifier("ALT_KEY_TEXT", "A", "ALT")
	return modifierShortcutPatterns
end

local keyShortcutPatterns
local function EnsureKeyShortcutPatterns()
	if keyShortcutPatterns then return keyShortcutPatterns end
	keyShortcutPatterns = {}
	local function addKeyShortcut(globalKey, replacement, fallback)
		local text = GetGlobalUpper(globalKey, fallback)
		if text and text ~= "" then table.insert(keyShortcutPatterns, { pattern = EscapePattern(text), replacement = replacement }) end
	end
	addKeyShortcut("KEY_SPACE", "SP", "SPACEBAR")
	addKeyShortcut("KEY_BACKSPACE", "BS", "BACKSPACE")
	return keyShortcutPatterns
end

local function ShortenHotkeyText(text)
	if type(text) ~= "string" or text == "" then return text end
	local isMinusKeybind
	if string.sub(text, -1) == "-" then isMinusKeybind = true end
	if _G.RANGE_INDICATOR and text == _G.RANGE_INDICATOR then return text end
	local short = text:upper()
	for _, data in ipairs(EnsureMouseButtonShortcuts()) do
		short = short:gsub(data.pattern, data.replacement)
	end
	for _, data in ipairs(EnsureModifierShortcutPatterns()) do
		short = short:gsub(data.pattern, data.replacement)
	end
	for _, data in ipairs(EnsureKeyShortcutPatterns()) do
		short = short:gsub(data.pattern, data.replacement)
	end
	for _, repl in ipairs(HOTKEY_SHORT_REPLACEMENTS) do
		short = short:gsub(repl[1], repl[2])
	end
	short = short:gsub("CTRL%-", "C")
	short = short:gsub("CONTROL%-", "C")
	short = short:gsub("ALT%-", "A")
	short = short:gsub("SHIFT%-", "S")
	short = short:gsub("OPTION%-", "O")
	short = short:gsub("COMMAND%-", "CM")
	short = short:gsub("PLUS", "+")
	short = short:gsub("MINUS", "-")
	short = short:gsub("MULTIPLY", "*")
	short = short:gsub("DIVIDE", "/")
	short = short:gsub("[%s%-]", "")
	if isMinusKeybind then short = short .. "-" end
	return short
end
Labels.ShortenHotkeyText = ShortenHotkeyText

local function ApplyHotkeyStyling(button, barNameOverride)
	if not addon.db then return end
	local hotkey = GetActionButtonHotkey(button)
	if not hotkey then return end
	local positionOverride = addon.db.actionBarHotkeyFontOverride == true
	ApplyRegionPositionOverride(
		hotkey,
		button,
		positionOverride,
		addon.db.actionBarHotkeyAnchor,
		addon.db.actionBarHotkeyOffsetX,
		addon.db.actionBarHotkeyOffsetY,
		"EQOL_UsingHotkeyPositionOverride",
		"EQOL_OriginalHotkeyPoints",
		true,
		"EQOL_OriginalHotkeyWidth"
	)
	local originalText = hotkey:GetText()
	if hotkey.EQOL_ShortApplied and originalText ~= hotkey.EQOL_ShortValue then
		hotkey.EQOL_ShortApplied = nil
		hotkey.EQOL_ShortValue = nil
	end

	local face = resolveFontFace(addon.db.actionBarHotkeyFontFace)
	local size = NormalizeFontSize(addon.db.actionBarHotkeyFontSize, 6, 32)
	local outline = addon.db.actionBarHotkeyFontOutline or "OUTLINE"
	local fontColor = addon.db.actionBarHotkeyFontColor
	if addon.db.actionBarHotkeyFontOverride then
		if not hotkey.EQOL_OriginalHotkeyFont then
			local oface, osize, ooutline = hotkey:GetFont()
			hotkey.EQOL_OriginalHotkeyFont = { face = oface, size = osize, outline = ooutline }
		end
		ApplyFontWithFallback(hotkey, face, size, outline)
		hotkey.EQOL_UsingHotkeyOverride = true
		ApplyTextColorOverride(hotkey, fontColor, "EQOL_OriginalHotkeyColor", "EQOL_UsingHotkeyColorOverride")
	else
		if hotkey.EQOL_UsingHotkeyOverride then
			local orig = hotkey.EQOL_OriginalHotkeyFont or {}
			local restoreFace = resolveFontFace(orig.face)
			local restoreSize = orig.size or size
			local restoreOutline = orig.outline or "OUTLINE"
			ApplyFontWithFallback(hotkey, restoreFace, restoreSize, restoreOutline)
			hotkey.EQOL_UsingHotkeyOverride = nil
			hotkey.EQOL_OriginalHotkeyFont = nil
		end
		RestoreTextColorOverride(hotkey, "EQOL_OriginalHotkeyColor", "EQOL_UsingHotkeyColorOverride")
	end

	-- Preserve Blizzard's range color when the button is out of range.
	if button.EQOL_RangeOutOfRange then ApplyImmediateTextColor(hotkey, RED_FONT_COLOR, 1, 0.1, 0.1, 1) end

	if addon.db.actionBarShortHotkeys then
		if not hotkey.EQOL_ShortApplied then hotkey.EQOL_OriginalHotkeyText = originalText end
		local baseText = hotkey.EQOL_OriginalHotkeyText or originalText
		local shortText = ShortenHotkeyText(baseText)
		if shortText and shortText ~= hotkey:GetText() then
			hotkey:SetText(shortText)
			hotkey.EQOL_ShortApplied = true
			hotkey.EQOL_ShortValue = shortText
		end
	else
		if hotkey.EQOL_ShortApplied and hotkey.EQOL_OriginalHotkeyText then hotkey:SetText(hotkey.EQOL_OriginalHotkeyText) end
		hotkey.EQOL_ShortApplied = nil
		hotkey.EQOL_ShortValue = nil
	end

	-- Keep per-bar hide as the final authority, even after font/text updates.
	RefreshHotkeyVisibility(button, barNameOverride)
end

local function InstallHotkeyHook()
	if Labels.hotkeyHookInstalled then return end
	local hooked = false
	if ActionBarActionButtonMixin and type(ActionBarActionButtonMixin.UpdateHotkeys) == "function" then
		hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", ApplyHotkeyStyling)
		hooked = true
	end
	if hooked then
		Labels.hotkeyHookInstalled = true
		if Labels.hotkeyHookFrame then
			Labels.hotkeyHookFrame:UnregisterEvent("PLAYER_LOGIN")
			Labels.hotkeyHookFrame:SetScript("OnEvent", nil)
			Labels.hotkeyHookFrame = nil
		end
	end
end

InstallHotkeyHook()
if not Labels.hotkeyHookInstalled then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function(self)
		InstallHotkeyHook()
		if Labels.hotkeyHookInstalled then
			self:UnregisterEvent("PLAYER_LOGIN")
			self:SetScript("OnEvent", nil)
		end
	end)
	Labels.hotkeyHookFrame = frame
end

function Labels.RefreshAllHotkeyStyles()
	ForEachHotkeyButton(function(button, info) ApplyHotkeyStyling(button, info and info.name) end)
end

function Labels.RefreshAllHotkeyVisibility()
	ForEachHotkeyButton(function(button, info) RefreshHotkeyVisibility(button, info and info.name) end)
end

local function InstallCountHook()
	if Labels.countHookInstalled then return end
	local hooked = false
	if ActionBarActionButtonMixin and type(ActionBarActionButtonMixin.UpdateCount) == "function" then
		hooksecurefunc(ActionBarActionButtonMixin, "UpdateCount", ApplyCountStyling)
		hooked = true
	end
	if hooked then
		Labels.countHookInstalled = true
		if Labels.countHookFrame then
			Labels.countHookFrame:UnregisterEvent("PLAYER_LOGIN")
			Labels.countHookFrame:SetScript("OnEvent", nil)
			Labels.countHookFrame = nil
		end
	end
end

InstallCountHook()
if not Labels.countHookInstalled then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function(self)
		InstallCountHook()
		if Labels.countHookInstalled then
			self:UnregisterEvent("PLAYER_LOGIN")
			self:SetScript("OnEvent", nil)
		end
	end)
	Labels.countHookFrame = frame
end

function Labels.RefreshAllCountStyles()
	ForEachActionButton(function(button) ApplyCountStyling(button) end)
end

local function RefreshHotkeyColorOverride(button)
	if not addon.db then return end
	local hotkey = GetActionButtonHotkey(button)
	if not hotkey then return end
	local barName = DetermineButtonBarName(button)
	if ShouldHideHotkey(barName, button) then
		RefreshHotkeyVisibility(button, barName)
		return
	end
	if button.EQOL_RangeOutOfRange then
		ApplyImmediateTextColor(hotkey, RED_FONT_COLOR, 1, 0.1, 0.1, 1)
	elseif addon.db.actionBarHotkeyFontOverride then
		local fontColor = addon.db.actionBarHotkeyFontColor
		ApplyTextColorOverride(hotkey, fontColor, "EQOL_OriginalHotkeyColor", "EQOL_UsingHotkeyColorOverride")
	elseif hotkey.EQOL_UsingHotkeyColorOverride then
		RestoreTextColorOverride(hotkey, "EQOL_OriginalHotkeyColor", "EQOL_UsingHotkeyColorOverride")
	end
	RefreshHotkeyVisibility(button, barName)
end

function Labels.GetAdditionalHotkeyBarOptions()
	return {
		{
			value = EXTRA_ACTION_BAR_NAME,
			text = (addon.L and addon.L["actionBarExtraActionButton"]) or "Extra Action Button",
		},
	}
end

function Labels.HasRangeIndicatorRuntimeFeatures()
	local db = addon.db
	if not db then return false end
	local hiddenHotkeys = db and db.actionBarHiddenHotkeys
	return db.actionBarFullRangeColoring == true or db.actionBarHotkeyFontOverride == true or (type(hiddenHotkeys) == "table" and next(hiddenHotkeys) ~= nil)
end

function Labels.EnsureRangeIndicatorHook()
	if Labels._rangeIndicatorHooked then return end
	if not Labels.HasRangeIndicatorRuntimeFeatures() then return end
	hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
		local db = addon.db
		local hiddenHotkeys = db and db.actionBarHiddenHotkeys
		if not db or (not db.actionBarFullRangeColoring and not db.actionBarHotkeyFontOverride and (type(hiddenHotkeys) ~= "table" or not next(hiddenHotkeys))) then return end
		if not self or not self.action then return end
		self.EQOL_RangeOutOfRange = checksRange and inRange == false
		if checksRange and inRange == false then
			ShowRangeOverlay(self, true)
		else
			ShowRangeOverlay(self, false)
		end
		RefreshHotkeyColorOverride(self)
	end)
	Labels._rangeIndicatorHooked = true
end

local function EnsureRangeUsableHook()
	if Labels._rangeUsableHooked then return end
	local mixin = _G.ActionBarActionButtonMixin
	if not (mixin and mixin.UpdateUsable) then return end
	hooksecurefunc(mixin, "UpdateUsable", function(self)
		if not addon.db or not addon.db.actionBarFullRangeColoring then return end
		if not self or not self.action then return end
		if self.EQOL_RangeOutOfRange then
			ShowRangeOverlay(self, true)
		else
			ShowRangeOverlay(self, false)
		end
	end)
	Labels._rangeUsableHooked = true
end

-- Refresh range overlays when the bar changes (mount/vehicle/override/stance swaps)
do
	local refreshPending = false
	local function RequestRangeRefresh()
		if refreshPending then return end
		if not addon.db or not addon.db.actionBarFullRangeColoring then return end
		refreshPending = true
		RunNextFrame(function()
			refreshPending = false
			if Labels.RefreshAllRangeOverlays then Labels.RefreshAllRangeOverlays() end
		end)
	end

	local events = {
		"UPDATE_OVERRIDE_ACTIONBAR",
		"UPDATE_VEHICLE_ACTIONBAR",
		"UPDATE_BONUS_ACTIONBAR",
		"UPDATE_SHAPESHIFT_FORM",
		"PLAYER_MOUNT_DISPLAY_CHANGED",
	}
	local rangeFrame
	local function EnsureRangeFrame()
		if rangeFrame then return rangeFrame end
		rangeFrame = CreateFrame("Frame")
		rangeFrame:SetScript("OnEvent", RequestRangeRefresh)
		return rangeFrame
	end

	function Labels.UpdateRangeOverlayEvents()
		if Labels.EnsureRangeIndicatorHook then Labels.EnsureRangeIndicatorHook() end
		local frame = EnsureRangeFrame()
		frame:UnregisterAllEvents()
		if addon.db and addon.db.actionBarFullRangeColoring then
			for _, evt in ipairs(events) do
				frame:RegisterEvent(evt)
			end
		end
	end
end

-- Debounced hotkey refresh for bindings changes (quick keybind mode)
do
	local refreshPending = false
	local function RequestHotkeyRefresh()
		if refreshPending then return end
		refreshPending = true
		C_Timer.After(0.05, function()
			refreshPending = false
			if Labels.RefreshAllHotkeyStyles then Labels.RefreshAllHotkeyStyles() end
		end)
	end

	local hotkeyFrame
	local function EnsureHotkeyFrame()
		if hotkeyFrame then return hotkeyFrame end
		hotkeyFrame = CreateFrame("Frame")
		hotkeyFrame:SetScript("OnEvent", RequestHotkeyRefresh)
		return hotkeyFrame
	end

	function Labels.UpdateHotkeyRefreshEvents()
		local frame = EnsureHotkeyFrame()
		frame:UnregisterAllEvents()
		frame:RegisterEvent("UPDATE_BINDINGS")
	end
end

local function OnPlayerLogin(self, event)
	if event ~= "PLAYER_LOGIN" then return end
	EnsureRangeUsableHook()
	if Labels.RefreshAllMacroNameVisibility then Labels.RefreshAllMacroNameVisibility() end
	if Labels.RefreshAllHotkeyStyles then Labels.RefreshAllHotkeyStyles() end
	if Labels.RefreshAllCountStyles then Labels.RefreshAllCountStyles() end
	if Labels.RefreshAllRangeOverlays then Labels.RefreshAllRangeOverlays() end
	if Labels.RefreshActionButtonBorders then Labels.RefreshActionButtonBorders("PLAYER_LOGIN") end
	if Labels.UpdateRangeOverlayEvents then Labels.UpdateRangeOverlayEvents() end
	if Labels.UpdateHotkeyRefreshEvents then Labels.UpdateHotkeyRefreshEvents() end
	if self then
		self:UnregisterEvent("PLAYER_LOGIN")
		self:SetScript("OnEvent", nil)
	end
end

function Labels.EnsureActionButtonArtHook()
	if Labels._actionBarArtHooked then return end
	local mixin = _G.BaseActionButtonMixin
	if not mixin or not mixin.UpdateButtonArt then return end
	hooksecurefunc(mixin, "UpdateButtonArt", function(button)
		if Labels.RefreshActionButtonBorder then Labels.RefreshActionButtonBorder(button) end
	end)
	Labels._actionBarArtHooked = true
end

function Labels.EnsureZoneAbilityBorderHook()
	if Labels._zoneAbilityBorderHooked then return true end

	local mixin = _G.ZoneAbilityFrameSpellButtonMixin
	if mixin and type(mixin.Refresh) == "function" then
		hooksecurefunc(mixin, "Refresh", function(button)
			if Labels.RefreshActionButtonBorder then Labels.RefreshActionButtonBorder(button) end
		end)
		Labels._zoneAbilityBorderHooked = true
		if Labels._zoneAbilityBorderLoadWatcher then
			Labels._zoneAbilityBorderLoadWatcher:UnregisterEvent("ADDON_LOADED")
			Labels._zoneAbilityBorderLoadWatcher:SetScript("OnEvent", nil)
			Labels._zoneAbilityBorderLoadWatcher = nil
		end
		return true
	end

	if not Labels._zoneAbilityBorderLoadWatcher then
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(self, _, loadedAddonName)
			if loadedAddonName ~= "Blizzard_ZoneAbility" then return end
			if Labels.EnsureZoneAbilityBorderHook and Labels.EnsureZoneAbilityBorderHook() then
				if Labels.RefreshActionButtonBorders then Labels.RefreshActionButtonBorders() end
			end
		end)
		Labels._zoneAbilityBorderLoadWatcher = frame
	end

	return false
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", OnPlayerLogin)
