local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

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
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)

local Editor = {}
CooldownPanels.BlizzardEditor = Editor

Editor.CATEGORY_HEIGHT = 22
Editor.TILE_SIZE = 38
Editor.TILE_SPACING = 8
Editor.TILE_STRIDE = 7
Editor.BAR_ITEM_WIDTH = 317
Editor.BAR_ITEM_HEIGHT = 38
Editor.BAR_ITEM_SPACING = 10
Editor.CONTENT_WIDTH = 344
Editor.PANEL_HEADER_NAME_MAX_CHARS = 20
Editor.PANEL_HEADER_NAME_WIDTH = 150
Editor.ADDON_ICON = "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga"
Editor.COOLDOWN_PANEL_ICON = "Interface\\AddOns\\EnhanceQoL\\Assets\\NewSettings\\CastbarsCooldowns.tga"
Editor.QUICK_ACTIONS_ICON_ATLAS = "common-icon-undo"

local function normalizeSortMode(value)
	if value == "NAME_ASC" or value == "NAME_DESC" then return value end
	return "MANUAL"
end

Editor.state = {
	collapsed = {},
	classView = "ALL",
	sortMode = normalizeSortMode(addon.db and addon.db.cooldownPanelsBlizzardEditorSortMode),
}

local function normalizeId(value)
	local numeric = tonumber(value)
	if numeric then return numeric end
	return value
end

local function getRoot()
	if CooldownPanels.GetRoot then return CooldownPanels:GetRoot() end
	return nil
end

local function getPanel(panelId)
	if CooldownPanels.GetPanel then return CooldownPanels:GetPanel(panelId) end
	local root = getRoot()
	return root and root.panels and root.panels[normalizeId(panelId)] or nil
end

local function isFixedLayoutPanel(panel)
	return panel and Helper.IsFixedLayout and Helper.IsFixedLayout(panel.layout) or false
end

local function isBarGroupPanel(panel)
	return panel and Helper.IsBarLayout(panel.layout) and panel.layout.barGroupsEnabled == true or false
end

local function getPanelIds(root)
	if CooldownPanels.GetCachedPanelIds then return CooldownPanels.GetCachedPanelIds(root) end
	return root and root.order or {}
end

local function getSortedPanelIds(root)
	local panelIds = {}
	for _, panelId in ipairs(getPanelIds(root)) do
		panelIds[#panelIds + 1] = panelId
	end
	local sortMode = Editor.state.sortMode
	if sortMode == "NAME_ASC" or sortMode == "NAME_DESC" then
		table.sort(panelIds, function(leftId, rightId)
			local leftPanel = getPanel(leftId)
			local rightPanel = getPanel(rightId)
			local leftName = tostring(leftPanel and leftPanel.name or ""):lower()
			local rightName = tostring(rightPanel and rightPanel.name or ""):lower()
			if leftName == rightName then return tostring(leftId) < tostring(rightId) end
			if sortMode == "NAME_DESC" then return leftName > rightName end
			return leftName < rightName
		end)
	end
	return panelIds
end

local function isSortModeSelected(value)
	return Editor.state.sortMode == value
end

local function setSortMode(value)
	Editor.state.sortMode = normalizeSortMode(value)
	if addon.db then addon.db.cooldownPanelsBlizzardEditorSortMode = Editor.state.sortMode end
	Editor:Refresh()
end

-- Forever has classes but no specializations. Use the runtime's effective
-- class filter so imported Retail assignments remain visible without mutation.
local function panelMatchesClassView(panel)
	if Editor.state.classView == "ALL" then return true end
	return CooldownPanels:PanelAllowsClass(panel, tonumber(Editor.state.classView))
end

local function panelMatchesSpecificClassView(panel)
	if Editor.state.classView == "ALL" or not CooldownPanels:HasPanelClassFilter(panel) then return false end
	return CooldownPanels:PanelAllowsClass(panel, tonumber(Editor.state.classView))
end

local function getPlayerClassName()
	local className, classFile, classID = "", nil, nil
	if UnitClass then className, classFile, classID = UnitClass("player") end
	return className or "", classFile, classID
end

local function getPlayerClassID()
	local _, _, classID = getPlayerClassName()
	return classID
end

local function getClassInfoByClassID(classID)
	classID = tonumber(classID)
	if not classID then return nil end
	if C_CreatureInfo and C_CreatureInfo.GetClassInfo then
		local classInfo = C_CreatureInfo.GetClassInfo(classID)
		if classInfo then return classInfo.className, classInfo.classFile, classID end
	end
	if GetNumClasses and GetClassInfo then
		for index = 1, GetNumClasses() do
			local className, classFile, currentClassID = GetClassInfo(index)
			if currentClassID == classID then return className, classFile, classID end
		end
	end
	local playerClassName, playerClassFile, playerClassID = getPlayerClassName()
	if playerClassID == classID then return playerClassName, playerClassFile, classID end
	return nil
end

local function getClassFileByClassID(classID)
	local _, classFile = getClassInfoByClassID(classID)
	return classFile
end

local function getSelectedClassID()
	return tonumber(Editor.state.classView) or getPlayerClassID()
end

local function getClassColorTextByClassID(classID, text)
	local _, classFile = getClassInfoByClassID(classID)
	local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	return color and color.WrapTextInColorCode and color:WrapTextInColorCode(text) or text
end

function Editor:GetClassOptions()
	local options = {}
	for _, option in ipairs(CooldownPanels:GetPanelClassFilterOptions()) do
		if type(option.value) == "number" then options[#options + 1] = { value = option.value, label = option.text, classFile = option.classFile } end
	end
	return options
end

-- The shared spell-group editor also queries this method. Forever has no
-- specialization entries; class choices are supplied by GetClassOptions.
function Editor:GetClassSpecOptions() return {} end

local function getClassViewLabel()
	if Editor.state.classView == "ALL" then return ALL_CLASSES or L["All classes"] end
	local classID = getSelectedClassID()
	local className = getClassInfoByClassID(classID) or getPlayerClassName()
	return getClassColorTextByClassID(classID, className)
end

local function isClassViewSelected(value)
	return (tonumber(value) or value) == Editor.state.classView
end

local function setClassView(value)
	Editor.state.classView = tonumber(value) or "ALL"
	Editor:Refresh()
end

function Editor:EnsureInitialClassView()
	if self.state.didInitializeClassView then return end
	self.state.didInitializeClassView = true
	self.state.classView = getPlayerClassID() or "ALL"
end

function Editor:UpdateClassDropdown()
	local frame = self.frame
	if not (frame and frame.classDropdown) then return end
	if frame.classDropdown.SetDefaultText then frame.classDropdown:SetDefaultText(getClassViewLabel()) end
	if frame.classDropdown.GenerateMenu then frame.classDropdown:GenerateMenu() end
end

function Editor:CreatePanelFromDropdown()
	local newName = L["CooldownPanelNewPanel"] or "New Panel"
	local panelId, panel = CooldownPanels:CreatePanel(newName)
	if not panelId then return end
	if panel then
		panel.classFilter = {}
		CooldownPanels:SetPanelClassFilterOptionSelected(panelId, tonumber(self.state.classView) or "__all", true)
	end
	if CooldownPanels.SelectPanel then CooldownPanels:SelectPanel(panelId) end
	self:Refresh()
end

function Editor:ShowImportPanelPopup()
	if CooldownPanels.EnsureImportPanelPopup then CooldownPanels.EnsureImportPanelPopup() end
	StaticPopup_Show("EQOL_COOLDOWN_PANEL_IMPORT")
end

function Editor:GetCurrentViewPanelIds()
	local root = getRoot()
	local panelIds = {}
	for _, panelId in ipairs(getSortedPanelIds(root)) do
		local panel = getPanel(panelId)
		if panel and panelMatchesClassView(panel) then panelIds[#panelIds + 1] = panelId end
	end
	return panelIds
end

function Editor:GetCurrentSpecificViewPanelIds()
	local root = getRoot()
	local panelIds = {}
	for _, panelId in ipairs(getSortedPanelIds(root)) do
		local panel = getPanel(panelId)
		if panel and panelMatchesSpecificClassView(panel) then panelIds[#panelIds + 1] = panelId end
	end
	return panelIds
end

function Editor:ExportView(panelIds)
	if CooldownPanels.ShowExportPanelsPopup then
		return CooldownPanels:ShowExportPanelsPopup(panelIds, L["CooldownPanelExportView"] or "Export View")
	end
	return false
end

local function getFrameTitle()
	return "EQOL " .. tostring(_G.COOLDOWN_VIEWER_SETTINGS_TITLE or "Cooldown Settings")
end

local function getAdvancedPanelLabel(panel)
	if isBarGroupPanel(panel) then return L["CooldownPanelBarGroupLabel"] end
	if panel and Helper.IsBarLayout(panel.layout) then return L["Bar"] end
	return L["settingsCategoryModeAdvanced"] or "Advanced"
end

local function truncatePanelHeaderText(text)
	text = tostring(text or "")
	local maxChars = Editor.PANEL_HEADER_NAME_MAX_CHARS
	if not maxChars or maxChars <= 3 then return text end
	local length = _G.strlenutf8 and _G.strlenutf8(text) or #text
	if length <= maxChars then return text end
	if _G.strsubutf8 then return _G.strsubutf8(text, 1, maxChars - 3) .. "..." end
	return text:sub(1, maxChars - 3) .. "..."
end

local function getEntryIcon(entry)
	if CooldownPanels.GetEntryIcon then return CooldownPanels:GetEntryIcon(entry) end
	return Helper.PREVIEW_ICON or 134400
end

local function getEntryName(entry)
	if CooldownPanels.GetEntryName then return CooldownPanels:GetEntryName(entry) end
	return L["CooldownPanelEntry"] or "Entry"
end

local function getEntryTypeLabel(entry)
	if CooldownPanels.GetEntryTypeLabel then return CooldownPanels:GetEntryTypeLabel(entry and entry.type) end
	return entry and entry.type or ""
end

local function getEntryTooltipIdentityLine(entry)
	if not entry then return nil end
	local typeLabel = getEntryTypeLabel(entry)
	local entryType = entry.type and tostring(entry.type):upper() or ""
	local primaryId = nil
	local extraId = nil
	if entryType == "SPELL" then
		primaryId = entry.spellID
	elseif entryType == "ITEM" then
		primaryId = CooldownPanels.ResolveEntryItemID(entry, entry.itemID)
	elseif entryType == "TOTEM" then
		primaryId = entry.totemSlot
	elseif entryType == "SLOT" then
		primaryId = entry.slotID
	elseif entryType == "CDM_AURA" then
		primaryId = entry.cooldownID
		if entry.spellID then extraId = string.format("%s ID: %s", _G.SPELL or "Spell", tostring(entry.spellID)) end
	elseif entryType == "STANCE" then
		local stanceDef = CooldownPanels.GetStanceDefinition and CooldownPanels:GetStanceDefinition(entry) or nil
		primaryId = entry.spellID or (stanceDef and stanceDef.spellID)
		typeLabel = string.format("%s %s", typeLabel ~= "" and typeLabel or (_G.STANCE or "Stance"), _G.SPELL or "Spell")
	elseif entryType == "MACRO" then
		primaryId = entry.macroID or entry.macroName
		local macro = CooldownPanels.ResolveMacroEntry and CooldownPanels.ResolveMacroEntry(entry) or nil
		if macro and macro.kind == "SPELL" and macro.spellID then
			extraId = string.format("%s ID: %s", _G.SPELL or "Spell", tostring(macro.spellID))
		elseif macro and macro.kind == "ITEM" and macro.itemID then
			extraId = string.format("%s ID: %s", _G.ITEM or "Item", tostring(macro.itemID))
		end
	end
	if not primaryId or primaryId == "" then return nil end
	local line = string.format("%s ID: %s", typeLabel ~= "" and typeLabel or entryType, tostring(primaryId))
	if extraId then line = string.format("%s  |  %s", line, extraId) end
	return line
end

local function setFrameText(frame, text)
	if frame.Text then
		frame.Text:SetText(text)
	elseif frame.text then
		frame.text:SetText(text)
	end
end

local function setRegionAlpha(region, alpha)
	if region and region.SetAlpha then region:SetAlpha(alpha) end
end

-- The editor uses a fixed-size horizontal list row, with the effective bar style.
function Editor:ApplyBarTileStyle(tile, panel, entry, isDisabled)
	local bar = tile and tile.Bar
	if not (bar and entry) then return end
	local bars = CooldownPanels.Bars
	local defaults = bars and bars.DEFAULTS or {}
	local style = Helper.GetBarPanelStyleEntry and Helper.GetBarPanelStyleEntry(entry, panel and panel.layout) or entry
	local showIcon = style.barShowIcon
	if showIcon == nil then showIcon = defaults.barShowIcon ~= false end
	if tile.icon and tile.icon.SetShown then tile.icon:SetShown(showIcon == true) end
	if bar.Name then
		local showLabel = style.barShowLabel
		if showLabel == nil then showLabel = defaults.barShowLabel ~= false end
		bar.Name:SetText(getEntryName(entry))
		bar.Name:SetShown(showLabel == true)
		local color = Helper.NormalizeColor(style.barLabelColor, defaults.barLabelColor or { 1, 1, 1, 1 })
		bar.Name:SetTextColor(color[1], color[2], color[3], color[4])
		setRegionAlpha(bar.Name, isDisabled and 0.65 or 1)
	end
	local textureKey = style.barTexture or defaults.barTexture or "DEFAULT"
	local texture = textureKey == "SOLID" and "Interface\\Buttons\\WHITE8x8" or "Interface\\TargetingFrame\\UI-StatusBar"
	if textureKey ~= "SOLID" and textureKey ~= "DEFAULT" then
		local media = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("statusbar") or {}
		texture = media[textureKey] or (type(textureKey) == "string" and textureKey:find("[/\\]") and textureKey) or texture
	end
	if bar.SetStatusBarTexture then bar:SetStatusBarTexture(texture) end
	local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture() or bar.FillTexture
	if fill then
		local modeColor = bars and bars.COLORS and bars.COLORS[style.barMode]
		local color = Helper.NormalizeColor(style.barColor, modeColor or defaults.barColor or { 1, 0.5, 0.25, 1 })
		fill:SetVertexColor(color[1], color[2], color[3], color[4])
		fill:SetAlpha(isDisabled and 0.35 or 1)
	end
end

local function setTextureDesaturated(texture, desaturated)
	if texture and texture.SetDesaturated then texture:SetDesaturated(desaturated == true) end
end

local function setPortraitTexture(frame, texture)
	if frame.SetPortraitTexCoord then frame:SetPortraitTexCoord(0, 1, 0, 1) end
	if frame.SetPortraitToTexture then
		frame:SetPortraitToTexture(texture)
		return
	end
	if frame.SetPortraitTextureRaw then
		frame:SetPortraitTextureRaw(texture)
		return
	end
	local portrait = frame.PortraitContainer and frame.PortraitContainer.portrait
	if portrait and portrait.SetTexture then
		portrait:SetTexCoord(0, 1, 0, 1)
		portrait:SetTexture(texture)
	end
end

local function setPortraitToClass(frame, classID)
	local classFile = getClassFileByClassID(classID)
	if not classFile then
		setPortraitTexture(frame, Editor.ADDON_ICON)
		return
	end
	if frame.SetPortraitToClassIcon then
		frame:SetPortraitToClassIcon(classFile)
		return
	end
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[string.upper(classFile)]
	if frame.SetPortraitTextureRaw and frame.SetPortraitTexCoord and coords then
		frame:SetPortraitTextureRaw("Interface/TargetingFrame/UI-Classes-Circles")
		frame:SetPortraitTexCoord(unpack(coords))
		return
	end
	local portrait = frame.PortraitContainer and frame.PortraitContainer.portrait
	if portrait and coords then
		portrait:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
		portrait:SetTexCoord(unpack(coords))
		return
	end
	setPortraitTexture(frame, Editor.ADDON_ICON)
end

local function setupFramePortrait(frame)
	if _G.ButtonFrameTemplate_ShowPortrait then _G.ButtonFrameTemplate_ShowPortrait(frame) end
	if Editor.state.classView == "ALL" then
		setPortraitTexture(frame, Editor.ADDON_ICON)
	else
		setPortraitToClass(frame, getSelectedClassID())
	end
end

local function createEditorHelpButton(frame)
	local helpButton = CreateFrame("Button", nil, frame)
	helpButton:SetSize(28, 28)
	helpButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 1)
	helpButton:SetNormalTexture("Interface\\common\\help-i")
	helpButton:SetHighlightTexture("Interface\\common\\help-i")
	if helpButton:GetHighlightTexture() then helpButton:GetHighlightTexture():SetAlpha(0.7) end
	helpButton:SetScript("OnEnter", function(button)
		if not GameTooltip then return end
		GameTooltip:SetOwner(button, "ANCHOR_LEFT", -6, 0)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(L["CooldownPanelEditorHelpTitle"] or (HELP_LABEL or "Help"), 1, 0.82, 0)
		GameTooltip:AddLine(L["CooldownPanelEditorHelpIntro"] or "", 1, 1, 1, true)
		GameTooltip:AddLine(" ", 1, 1, 1, true)
		GameTooltip:AddLine(L["CooldownPanelEditorHelpStyleClipboard"] or "", 1, 1, 1, true)
		GameTooltip:AddLine(" ", 1, 1, 1, true)
		local auraHelpKey = CooldownPanels.AuraContainers and "CooldownPanelEditorHelpAuras121" or "CooldownPanelEditorHelpAuras"
		GameTooltip:AddLine(L[auraHelpKey] or L["CooldownPanelEditorHelpAuras"] or "", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	helpButton:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)
	return helpButton
end

local function saveFramePosition(frame)
	addon.functions.SaveSharedEditorPosition(frame)
end

local function resetFramePosition(frame)
	if not (frame and UIParent) then return end
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 32, -72)
	saveFramePosition(frame)
end

local function positionFrameForOpen(frame)
	if not (frame and UIParent) then return end
	addon.functions.ApplySharedEditorPosition(frame)
	if CooldownPanels.IsEditorFrameTooFarOffscreen and CooldownPanels:IsEditorFrameTooFarOffscreen(frame) then
		resetFramePosition(frame)
		return
	end
	saveFramePosition(frame)
end

local function applyTooltip(owner, title, body)
	owner:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title or "")
		if body and body ~= "" then GameTooltip:AddLine(body, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function showAdvancedPanelTooltip(owner)
	local panel = owner and owner:GetParent() and getPanel(owner:GetParent().panelId) or nil
	if not isFixedLayoutPanel(panel) then return end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(panel and panel.name or (L["CooldownPanelNewPanel"] or "New Panel"), 1, 0.82, 0)
	if isFixedLayoutPanel(panel) then
		GameTooltip:AddLine(getAdvancedPanelLabel(), 1, 0.82, 0, true)
		GameTooltip:AddLine(L["CooldownPanelAdvancedEditTooltip"] or "Edit this panel through Panel Edit. Right-click the header and choose Edit.", 0.85, 0.85, 0.85, true)
	end
	GameTooltip:Show()
end

local function getTooltip()
	return _G.GetAppropriateTooltip and _G.GetAppropriateTooltip() or GameTooltip
end

local function setDefaultTooltipAnchor(tooltip, owner)
	if _G.GameTooltip_SetDefaultAnchor then
		_G.GameTooltip_SetDefaultAnchor(tooltip, owner)
	else
		tooltip:SetOwner(owner, "ANCHOR_RIGHT")
	end
end

local function showEntryTooltip(owner, entry)
	local tooltip = getTooltip()
	setDefaultTooltipAnchor(tooltip, owner)
	if entry and entry.type == "SLOT" then
		local slotID = tonumber(entry.slotID)
		local itemLink = slotID and GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
		tooltip:SetText(getEntryName(entry))
		tooltip:AddLine(getEntryTypeLabel(entry), 1, 0.82, 0, true)
		tooltip:AddLine(string.format("%s: %s", _G.ITEM or "Item", itemLink or _G.NONE or "None"), 1, 1, 1, true)
	elseif entry and entry.type == "CDM_AURA" and entry.auraPresetKey then
		tooltip:SetText(getEntryName(entry), 1, 0.82, 0)
		tooltip:AddLine(getEntryTypeLabel(entry), 1, 1, 1, true)
	elseif entry and entry.spellID and tooltip.SetSpellByID then
		tooltip:SetSpellByID(entry.spellID, false)
	elseif entry and entry.itemID and tooltip.SetItemByID then
		local itemID = CooldownPanels.ResolveEntryItemID(entry, entry.itemID)
		if itemID then
			tooltip:SetItemByID(itemID)
		else
			tooltip:SetText(getEntryName(entry))
		end
		if CooldownPanels.Potions and CooldownPanels.Potions:GetEntryResource(entry) then
			tooltip:AddLine(getEntryName(entry), 1, 0.82, 0, true)
			tooltip:AddLine(L["CooldownPanelBestPotionTooltip"], 1, 1, 1, true)
		end
	else
		tooltip:SetText(getEntryName(entry))
	end
	local identityLine = getEntryTooltipIdentityLine(entry)
	if identityLine then
		tooltip:AddLine(" ")
		tooltip:AddLine(identityLine, 0.65, 0.65, 0.65, true)
	end
	tooltip:Show()
end

local function releasePool(pool)
	for i = 1, #pool do
		local frame = pool[i]
		frame:Hide()
		frame:ClearAllPoints()
	end
	pool.active = 0
end

local function getPooled(pool, parent, createFunc)
	pool.active = (pool.active or 0) + 1
	local frame = pool[pool.active]
	if frame then return frame end
	frame = createFunc(parent)
	pool[pool.active] = frame
	return frame
end

local function getPooledEntryFrame(pool, parent, templateKind)
	pool.active = (pool.active or 0) + 1
	local frame = pool[pool.active]
	if frame and frame._eqolTemplateKind ~= templateKind then
		frame:Hide()
		frame:ClearAllPoints()
		frame = nil
	end
	if not frame then
		frame = Editor:CreateTile(parent, templateKind)
		pool[pool.active] = frame
	end
	return frame
end

local function getCursorPositionForFrame(frame)
	local x, y = GetCursorPosition()
	local scale = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or UIParent:GetEffectiveScale()
	return x / scale, y / scale
end

local function getFrameSides(frame)
	if not frame or not frame.GetLeft then return nil end
	local left, right, bottom, top = frame:GetLeft(), frame:GetRight(), frame:GetBottom(), frame:GetTop()
	if not (left and right and bottom and top) then return nil end
	return left, right, bottom, top
end

local function isPointInsideFrame(frame, cursorX, cursorY)
	local left, right, bottom, top = getFrameSides(frame)
	return left and cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

local function isPointInsideCategoryLayout(category, cursorX, cursorY)
	local left, right, _, top = getFrameSides(category)
	local height = tonumber(category and category._eqolLayoutHeight)
	if not (left and right and top and height) then return isPointInsideFrame(category, cursorX, cursorY) end
	return cursorX >= left and cursorX <= right and cursorY <= top and cursorY >= (top - height)
end

local function getDistanceToFrame(frame, cursorX, cursorY)
	local left, right, bottom, top = getFrameSides(frame)
	if not left then return nil end
	local verticalDistance = cursorY >= bottom and cursorY <= top and 0 or math.min(math.abs(cursorY - bottom), math.abs(cursorY - top))
	local horizontalDistance = cursorX >= left and cursorX <= right and 0 or math.min(math.abs(cursorX - left), math.abs(cursorX - right))
	return verticalDistance * 3 + horizontalDistance
end

local function getOrderEntryAfter(panel, entryId)
	if not (panel and panel.order) then return nil end
	for index, orderedEntryId in ipairs(panel.order) do
		if tostring(orderedEntryId) == tostring(entryId) then return panel.order[index + 1] end
	end
	return nil
end

local function clearReorderMarker(frame)
	if frame and frame.ReorderMarker then frame.ReorderMarker:Hide() end
	Editor.state.reorderTarget = nil
end

local function playCursorDropSound()
	if PlaySound and SOUNDKIT and SOUNDKIT.UI_CURSOR_DROP_OBJECT then PlaySound(SOUNDKIT.UI_CURSOR_DROP_OBJECT) end
end

local function updateAlertTypesOverlay(tile, entry, layout)
	if not tile then return end
	local alerts = {}
	local entryType = entry and tostring(entry.type or ""):upper() or nil
	if entryType == "CDM_AURA" then alerts[#alerts + 1] = "AURA" end
	if entry and CooldownPanels.EntryHasConfiguredSound and CooldownPanels:EntryHasConfiguredSound(layout, entry) then
		alerts[#alerts + 1] = Enum and Enum.CooldownViewerAlertType and Enum.CooldownViewerAlertType.Sound or "SOUND"
	end
	local glowReady = false
	if entry and entryType ~= "MACRO" then
		if entryType == "CDM_AURA" and not CooldownPanels.AuraContainers then
			glowReady = entry.glowReady == true
		elseif CooldownPanels.ResolveEntryGlowReady then
			glowReady = CooldownPanels:ResolveEntryGlowReady(layout, entry) == true
		else
			glowReady = entry.glowReady == true
		end
	end
	if glowReady then alerts[#alerts + 1] = Enum and Enum.CooldownViewerAlertType and Enum.CooldownViewerAlertType.Visual or "VISUAL" end

	if #alerts == 0 then
		if tile.AlertTypesOverlay then tile.AlertTypesOverlay:Hide() end
		return
	end

	local overlay = tile.AlertTypesOverlay
	if not overlay then
		overlay = CreateFrame("Frame", nil, tile)
		tile.AlertTypesOverlay = overlay
		overlay:SetPoint("BOTTOM", tile.Icon or tile.icon or tile, "BOTTOM", 0, 2)
		overlay:SetSize(34, 14)
		overlay.BG = overlay:CreateTexture(nil, "BACKGROUND")
		overlay.BG:SetAllPoints(overlay)
		overlay.BG:SetColorTexture(0, 0, 0, 0.7)
		overlay.icons = {}
	end

	for _, icon in ipairs(overlay.icons) do
		icon:Hide()
	end
	overlay.visibleIcons = overlay.visibleIcons or {}
	for index = #overlay.visibleIcons, 1, -1 do
		overlay.visibleIcons[index] = nil
	end

	for index, alertType in ipairs(alerts) do
		local icon = overlay.icons[index]
		if not icon then
			icon = overlay:CreateTexture(nil, "ARTWORK")
			overlay.icons[index] = icon
		end
		local atlas
		if alertType == "AURA" then
			atlas = "icon_trackedbuffs"
		else
			local getTypeAtlas = _G.CooldownViewerAlert_GetTypeAtlas
			atlas = getTypeAtlas and getTypeAtlas(alertType)
			if not atlas then atlas = alertType == "SOUND" and "common-icon-sound" or "common-icon-visual" end
			if atlas == "common-icon-visual" then atlas = "UI_Editor_Eye_Icon" end
		end
		local iconSize = alertType == "AURA" and overlay:GetHeight() or overlay:GetHeight() - 2
		icon:SetSize(iconSize, iconSize)
		icon.eqolOverlayWidth = iconSize
		addon.FeatureEditor:SetAtlas(icon, atlas)
		icon:Show()
		overlay.visibleIcons[#overlay.visibleIcons + 1] = icon
	end

	local totalIconsWidth = math.max(0, (#overlay.visibleIcons - 1) * 2)
	for _, icon in ipairs(overlay.visibleIcons) do
		totalIconsWidth = totalIconsWidth + (icon.eqolOverlayWidth or overlay:GetHeight() - 2)
	end
	overlay:SetWidth(math.max(34, totalIconsWidth + 4))
	local firstIconOffset = (overlay:GetWidth() - totalIconsWidth) / 2
	local previous
	for index, icon in ipairs(overlay.visibleIcons) do
		icon:ClearAllPoints()
		if index == 1 then
			icon:SetPoint("LEFT", overlay, "LEFT", firstIconOffset, 0)
		else
			icon:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = icon
	end
	overlay:Show()
end

local function syncOrder(order, entries)
	if type(order) ~= "table" or type(entries) ~= "table" then return end
	local index = 1
	while index <= #order do
		if not entries[order[index]] then
			table.remove(order, index)
		else
			index = index + 1
		end
	end
end

local function getNextNumericId(entries)
	local nextId = 1
	if type(entries) ~= "table" then return nextId end
	for key in pairs(entries) do
		local numeric = tonumber(key)
		if numeric and numeric >= nextId then nextId = numeric + 1 end
	end
	return nextId
end

local function insertOrder(order, entryId, beforeEntryId)
	order = order or {}
	for index = #order, 1, -1 do
		if order[index] == entryId then table.remove(order, index) end
	end
	local insertIndex = #order + 1
	if beforeEntryId then
		for index, currentId in ipairs(order) do
			if currentId == beforeEntryId then
				insertIndex = index
				break
			end
		end
	end
	table.insert(order, insertIndex, entryId)
end

function Editor:RefreshRuntime(panelId)
	if CooldownPanels.RebuildSpellIndex then CooldownPanels:RebuildSpellIndex() end
	if panelId and CooldownPanels.RefreshPanel then CooldownPanels:RefreshPanel(panelId) end
	if CooldownPanels.RefreshEditor then CooldownPanels:RefreshEditor() end
	self:Refresh()
end

function Editor:SetSourceTileDesaturated(desaturated)
	local tile = self.state.sourceTile
	if tile and tile.icon and tile.icon.SetDesaturated then tile.icon:SetDesaturated(desaturated == true) end
	if desaturated ~= true then self.state.sourceTile = nil end
end

function Editor:MoveEntry(sourcePanelId, sourceEntryId, targetPanelId, beforeEntryId)
	sourcePanelId = normalizeId(sourcePanelId)
	sourceEntryId = normalizeId(sourceEntryId)
	targetPanelId = normalizeId(targetPanelId)
	beforeEntryId = normalizeId(beforeEntryId)
	local sourcePanel = getPanel(sourcePanelId)
	local targetPanel = getPanel(targetPanelId)
	if not (sourcePanel and targetPanel and sourcePanel.entries and targetPanel.entries) then return end
	if isFixedLayoutPanel(sourcePanel) or isFixedLayoutPanel(targetPanel) then
		self.state.drag = nil
		self:SetSourceTileDesaturated(false)
		self:HideDraggedIcon()
		return
	end
	local entry = sourcePanel.entries[sourceEntryId]
	if not entry then return end
	if sourcePanel == targetPanel and tostring(beforeEntryId) == tostring(sourceEntryId) then
		self.state.drag = nil
		self:SetSourceTileDesaturated(false)
		self:HideDraggedIcon()
		return
	end

	sourcePanel.order = sourcePanel.order or {}
	targetPanel.order = targetPanel.order or {}
	if sourcePanel == targetPanel then
		insertOrder(sourcePanel.order, sourceEntryId, beforeEntryId)
	else
		sourcePanel.entries[sourceEntryId] = nil
		syncOrder(sourcePanel.order, sourcePanel.entries)
		local targetEntryId = sourceEntryId
		if targetPanel.entries[targetEntryId] then targetEntryId = getNextNumericId(targetPanel.entries) end
		entry.id = targetEntryId
		targetPanel.entries[targetEntryId] = entry
		insertOrder(targetPanel.order, targetEntryId, beforeEntryId)
	end

	self.state.drag = nil
	self.state.eatNextGlobalMouseUp = nil
	if self.frame then self.frame:UnregisterEvent("GLOBAL_MOUSE_UP") end
	self:SetSourceTileDesaturated(false)
	self:HideDraggedIcon()
	self:RefreshRuntime(sourcePanelId)
	if targetPanelId ~= sourcePanelId and CooldownPanels.RefreshPanel then CooldownPanels:RefreshPanel(targetPanelId) end
end

function Editor:HandleExternalDrop(panelId)
	if not CooldownPanels.HandleCursorDrop then return false end
	local added = CooldownPanels:HandleCursorDrop(panelId)
	if added then
		local frame = self.frame
		if frame then clearReorderMarker(frame) end
		self.state.reorderTarget = nil
		self:Refresh()
		return true
	end
	return false
end

function Editor:HandleExternalDropAtButton(button)
	return button and button.panelId and self:HandleExternalDrop(button.panelId) or false
end

function Editor:UpdateExternalDropPulse(elapsed)
	local frame = self.frame
	if not frame or self.state.drag then return end
	self.state.externalDropPulseElapsed = (self.state.externalDropPulseElapsed or 0) + (elapsed or 0)
	if self.state.externalDropPulseElapsed < 0.08 then return end
	self.state.externalDropPulseElapsed = 0
	local cursorType = Api.GetCursorInfo and Api.GetCursorInfo() or nil
	local pulse = cursorType and (0.18 + (math.sin((GetTime and GetTime() or 0) * 5) + 1) * 0.18) or 0
	for categoryIndex = 1, (frame.categories and frame.categories.active or 0) do
		local category = frame.categories[categoryIndex]
		if category then
			if category.addTile and category.addTile.dropGlow then category.addTile.dropGlow:SetAlpha(pulse) end
		end
	end
end

function Editor:CreateDraggedIcon()
	if self.draggedIcon then return self.draggedIcon end
	local frame = CreateFrame("Frame", nil, UIParent, "EQOLCooldownPanelsBlizzardEditorDraggedItemTemplate")
	frame:SetFrameStrata("TOOLTIP")
	frame:SetSize(self.TILE_SIZE, self.TILE_SIZE)
	frame.icon = frame.Icon
	frame:Hide()
	self.draggedIcon = frame
	return frame
end

function Editor:ShowDraggedIcon(texture)
	local frame = self:CreateDraggedIcon()
	frame:SetToCursor(texture or Helper.PREVIEW_ICON or 134400)
end

function Editor:HideDraggedIcon()
	if self.draggedIcon then
		self.draggedIcon:StopMovingOrSizing()
		self.draggedIcon:Hide()
	end
end

function Editor:FindReorderTarget(cursorX, cursorY)
	local frame = self.frame
	if not frame then return nil end
	if frame.scroll and not isPointInsideFrame(frame.scroll, cursorX, cursorY) then return nil end
	local best, bestDistance
	local cursorCategory
	for categoryIndex = 1, (frame.categories.active or 0) do
		local category = frame.categories[categoryIndex]
		if category and category:IsShown() and isPointInsideCategoryLayout(category, cursorX, cursorY) then
			cursorCategory = category
			break
		end
	end
	local function considerTile(category, tile, append)
		if not (tile and tile:IsShown()) then return end
		local tileDistance = getDistanceToFrame(tile, cursorX, cursorY)
		if not tileDistance then return end
		local categoryDistance = getDistanceToFrame(category, cursorX, cursorY) or 0
		local distance = tileDistance + categoryDistance
		if not bestDistance or distance < bestDistance then
			bestDistance = distance
			best = { category = category, tile = tile, append = append == true, cursorX = cursorX, cursorY = cursorY }
		end
	end
	for categoryIndex = 1, (frame.categories.active or 0) do
		local category = frame.categories[categoryIndex]
		if category and category:IsShown() and (not cursorCategory or category == cursorCategory) and category.container and category.container:IsShown() then
			local panel = getPanel(category.panelId)
			if not isFixedLayoutPanel(panel) and not isBarGroupPanel(panel) then
				for tileIndex = 1, (category.tiles.active or 0) do
					local tile = category.tiles[tileIndex]
					if tile and tile:IsShown() and tile.entryId then
						considerTile(category, tile, false)
					end
				end
				considerTile(category, category.addTile, true)
			end
		end
	end
	return best
end

function Editor:UpdateReorderMarker(force)
	local frame = self.frame
	if not (frame and frame.ReorderMarker and (force == true or self.state.drag)) then return end
	local cursorX, cursorY = getCursorPositionForFrame(frame)
	local target = self:FindReorderTarget(cursorX, cursorY)
	self.state.reorderTarget = nil
	if not target then
		frame.ReorderMarker:Hide()
		return
	end

	local panel = getPanel(target.category.panelId)
	local beforeEntryId = nil
	local marker = frame.ReorderMarker
	marker:ClearAllPoints()
	if target.append then
		marker:SetVertical()
		marker:SetPoint("CENTER", target.tile, "LEFT", -4, 0)
	else
		local isBar = target.tile._eqolTemplateKind == "BAR"
		if isBar then
			marker:SetHorizontal()
			local _, centerY = target.tile:GetCenter()
			if cursorY < centerY then
				marker:SetPoint("CENTER", target.tile, "BOTTOM", 0, -5)
				beforeEntryId = getOrderEntryAfter(panel, target.tile.entryId)
			else
				marker:SetPoint("CENTER", target.tile, "TOP", 0, 5)
				beforeEntryId = target.tile.entryId
			end
		else
			marker:SetVertical()
			local centerX, centerY = target.tile:GetCenter()
			if cursorY < centerY then
				marker:SetPoint("CENTER", target.tile, "RIGHT", 4, 0)
				beforeEntryId = getOrderEntryAfter(panel, target.tile.entryId)
			elseif cursorX < centerX then
				marker:SetPoint("CENTER", target.tile, "LEFT", -4, 0)
				beforeEntryId = target.tile.entryId
			else
				marker:SetPoint("CENTER", target.tile, "RIGHT", 4, 0)
				beforeEntryId = getOrderEntryAfter(panel, target.tile.entryId)
			end
		end
	end
	self.state.reorderTarget = {
		panelId = target.category.panelId,
		beforeEntryId = beforeEntryId,
	}
	marker:Show()
end

function Editor:BeginDrag(button, eatNextGlobalMouseUp)
	if not (button.panelId and button.entryId) then return end
	if isFixedLayoutPanel(getPanel(button.panelId)) or isBarGroupPanel(getPanel(button.panelId)) then return end
	self:SetSourceTileDesaturated(false)
	if PlaySound and SOUNDKIT and SOUNDKIT.UI_CURSOR_PICKUP_OBJECT then PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT) end
	self.state.drag = {
		panelId = button.panelId,
		entryId = button.entryId,
	}
	self.state.eatNextGlobalMouseUp = eatNextGlobalMouseUp
	self.state.sourceTile = button
	self:SetSourceTileDesaturated(true)
	self:ShowDraggedIcon(button.icon:GetTexture())
	self:GetFrame()
	if self.frame then self.frame:RegisterEvent("GLOBAL_MOUSE_UP") end
end

function Editor:EndDrag(defaultPanelId, defaultBeforeEntryId)
	local drag = self.state.drag
	if not drag then return false end
	playCursorDropSound()
	local target = self.state.reorderTarget
	local targetPanelId = target and target.panelId or defaultPanelId
	if targetPanelId then self:MoveEntry(drag.panelId, drag.entryId, targetPanelId, target and target.beforeEntryId or defaultBeforeEntryId) end
	local frame = self.frame
	if frame then
		clearReorderMarker(frame)
	end
	if not targetPanelId then
		self.state.drag = nil
		self.state.eatNextGlobalMouseUp = nil
		if frame then frame:UnregisterEvent("GLOBAL_MOUSE_UP") end
		self:SetSourceTileDesaturated(false)
		self:HideDraggedIcon()
	end
	return true
end

function Editor:CancelDrag()
	if not self.state.drag then return false end
	playCursorDropSound()
	local frame = self.frame
	self.state.drag = nil
	self.state.eatNextGlobalMouseUp = nil
	self:SetSourceTileDesaturated(false)
	self:HideDraggedIcon()
	if frame then
		frame:UnregisterEvent("GLOBAL_MOUSE_UP")
		clearReorderMarker(frame)
	end
	return true
end

function Editor:IsDirectEditModifierDown()
	if _G.IsModifierKeyDown then return _G.IsModifierKeyDown() == true end
	return (_G.IsAltKeyDown and _G.IsAltKeyDown() == true)
		or (_G.IsControlKeyDown and _G.IsControlKeyDown() == true)
		or (_G.IsShiftKeyDown and _G.IsShiftKeyDown() == true)
end

function Editor:CreateTile(parent, templateKind)
	templateKind = templateKind == "BAR" and "BAR" or "GRID"
	local template = templateKind == "BAR" and "EQOLCooldownPanelsBlizzardEditorBarItemTemplate" or "EQOLCooldownPanelsBlizzardEditorItemTemplate"
	local button = CreateFrame("Frame", nil, parent, template)
	button._eqolTemplateKind = templateKind
	if templateKind == "BAR" then
		button:SetSize(self.BAR_ITEM_WIDTH, self.BAR_ITEM_HEIGHT)
	else
		button:SetSize(self.TILE_SIZE, self.TILE_SIZE)
	end
	button:EnableMouse(true)
	if button.RegisterForClicks then button:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
	button:RegisterForDrag("LeftButton")
	if button.SetNormalTexture then button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2") end
	if button.SetPushedTexture then button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress") end
	if button.SetHighlightTexture then button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD") end

	button.icon = button.Icon

	button:SetScript("OnDragStart", function(selfButton)
		if Editor:IsDirectEditModifierDown() then return end
		Editor:BeginDrag(selfButton)
	end)
	button:SetScript("OnMouseUp", function(selfButton, buttonName)
		if buttonName == "RightButton" then
			if Editor:CancelDrag() then return end
			Editor:ShowEntryMenu(selfButton, selfButton.panelId, selfButton.entryId)
			return
		end
		if Editor:EndDrag(selfButton.panelId, selfButton.entryId) then return end
		if buttonName == "LeftButton" and Editor:IsDirectEditModifierDown() and CooldownPanels.OpenBlizzardEditorEntrySettings then
			CooldownPanels:OpenBlizzardEditorEntrySettings(selfButton.panelId, selfButton.entryId, selfButton)
			return
		end
		Editor:BeginDrag(selfButton, buttonName)
		if CooldownPanels.SelectPanel then CooldownPanels:SelectPanel(selfButton.panelId) end
	end)
	button:SetScript("OnReceiveDrag", function(selfButton)
		if Editor.state.drag then Editor:EndDrag(selfButton.panelId, selfButton.entryId) end
	end)
	button:SetScript("OnEnter", function(selfButton)
		if CooldownPanels.SetEntryStyleClipboardHotkeyFocus then
			CooldownPanels:SetEntryStyleClipboardHotkeyFocus(selfButton, true, selfButton.panelId, selfButton.entryId)
		end
		local panel = getPanel(selfButton.panelId)
		local entry = panel and panel.entries and panel.entries[selfButton.entryId] or nil
		showEntryTooltip(selfButton, entry)
	end)
	button:SetScript("OnLeave", function(selfButton)
		if CooldownPanels.SetEntryStyleClipboardHotkeyFocus then CooldownPanels:SetEntryStyleClipboardHotkeyFocus(selfButton, false) end
		getTooltip():Hide()
	end)
	if CooldownPanels.ConfigureEntryStyleClipboardHotkeys then CooldownPanels:ConfigureEntryStyleClipboardHotkeys(button) end
	return button
end

function Editor:CreateCenterWarning(category)
	local button = CreateFrame("Button", nil, category.header)
	button:SetSize(20, 20)
	-- Leave the header collapse control at the far right unobstructed.
	button:SetPoint("RIGHT", category.header, "RIGHT", -28, -3)
	button:SetFrameLevel(category.header:GetFrameLevel() + 2)
	button:RegisterForClicks("LeftButtonUp")
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints()
	button.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnEnter", function(selfButton)
		local text = Helper.GetCenterWarningTooltip(category.panelId)
		if not text then return end
		GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["CooldownPanelCenterWarning"], 1, 0.82, 0)
		GameTooltip:AddLine(text, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnHide", function(selfButton)
		if GameTooltip:IsOwned(selfButton) then GameTooltip:Hide() end
	end)
	button:SetScript("OnClick", function()
		GameTooltip:Hide()
		Helper.ConfirmRemoveCenterWarningEntries(category.panelId)
	end)
	button:Hide()
	return button
end

function Editor:CreateCategory(parent)
	local category = CreateFrame("Frame", nil, parent, "EQOLCooldownPanelsBlizzardEditorCategoryTemplate")
	category:SetWidth(self.CONTENT_WIDTH)
	category.header = category.Header
	category.container = category.Container
	category.header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local function handleHeaderClick(selfHeader, buttonName)
		if buttonName == "RightButton" then
			Editor:ShowPanelMenu(selfHeader, selfHeader:GetParent().panelId)
			return
		end
		local panelId = selfHeader:GetParent().panelId
		if Editor:HandleExternalDrop(panelId) then return end
		if buttonName == "LeftButton" and Editor:IsDirectEditModifierDown() and CooldownPanels.OpenBlizzardEditorPanelSettings then
			CooldownPanels:OpenBlizzardEditorPanelSettings(panelId, selfHeader)
			return
		end
		Editor.state.collapsed[panelId] = not Editor.state.collapsed[panelId]
		Editor:Refresh()
	end
	if category.header.SetClickHandler then
		category.header:SetClickHandler(handleHeaderClick)
	else
		category.header:SetScript("OnClick", handleHeaderClick)
	end
	if category.header.SetTitleColor then
		category.header:SetTitleColor(false, NORMAL_FONT_COLOR)
		category.header:SetTitleColor(true, NORMAL_FONT_COLOR)
	end
	if category.header.Name then
		category.header.Name:SetWidth(self.PANEL_HEADER_NAME_WIDTH)
		category.header.Name:SetJustifyH("LEFT")
		if category.header.Name.SetMaxLines then category.header.Name:SetMaxLines(1) end
		if category.header.Name.SetWordWrap then category.header.Name:SetWordWrap(false) end
	end
	category.centerWarning = self:CreateCenterWarning(category)
	category.header:SetScript("OnEnter", showAdvancedPanelTooltip)
	category.header:SetScript("OnLeave", function() GameTooltip:Hide() end)
	category.advancedLabel = category.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	category.advancedLabel:SetPoint("CENTER", category.header, "CENTER", 0, 0)
	category.advancedLabel:SetWidth(90)
	category.advancedLabel:SetJustifyH("CENTER")
	category.advancedLabel:SetTextColor(1, 0.55, 0.15, 1)
	if category.advancedLabel.SetMaxLines then category.advancedLabel:SetMaxLines(1) end
	if category.advancedLabel.SetWordWrap then category.advancedLabel:SetWordWrap(false) end
	category.advancedLabel:Hide()
	category.disabledLabel = category.header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	category.disabledLabel:SetPoint("CENTER", category.header, "CENTER", 0, 0)
	category.disabledLabel:SetWidth(130)
	category.disabledLabel:SetJustifyH("CENTER")
	category.disabledLabel:SetText(_G.DISABLED or "Disabled")
	if category.disabledLabel.SetMaxLines then category.disabledLabel:SetMaxLines(1) end
	if category.disabledLabel.SetWordWrap then category.disabledLabel:SetWordWrap(false) end
	category.disabledLabel:Hide()
	category.header:SetScript("OnReceiveDrag", function(selfHeader)
		local panelId = selfHeader:GetParent().panelId
		if not Editor:HandleExternalDrop(panelId) then
			Editor:EndDrag(panelId)
		end
	end)

	category.dropCatcher = CreateFrame("Button", nil, category)
	category.dropCatcher:RegisterForClicks("LeftButtonUp")
	category.dropCatcher:SetScript("OnMouseUp", function(selfButton)
		local panelId = selfButton:GetParent().panelId
		Editor:EndDrag(panelId)
	end)
	category.dropCatcher:SetScript("OnReceiveDrag", function(selfButton)
		local panelId = selfButton:GetParent().panelId
		if Editor.state.drag then Editor:EndDrag(panelId) end
	end)

	category.tiles = {}
	category.addTile = self:CreateTile(category.container, "GRID")
	category.addTile:Hide()
	category.addTile.dropGlow = category.addTile:CreateTexture(nil, "OVERLAY")
	category.addTile.dropGlow:SetAllPoints(category.addTile)
	category.addTile.dropGlow:SetColorTexture(0.1, 1, 0.25, 1)
	category.addTile.dropGlow:SetBlendMode("ADD")
	category.addTile.dropGlow:SetAlpha(0)
	category.addTile:SetScript("OnDragStart", nil)
	category.addTile:SetScript("OnReceiveDrag", function(selfButton)
		Editor:HandleExternalDropAtButton(selfButton)
	end)
	category.addTile:SetScript("OnMouseUp", function(selfButton)
		if Editor:HandleExternalDropAtButton(selfButton) then return end
		if Editor:EndDrag(selfButton.panelId) then return end
		if CooldownPanels.ShowAddEntryMenu then CooldownPanels:ShowAddEntryMenu(selfButton, selfButton.panelId) end
	end)
	applyTooltip(category.addTile, L["CooldownPanelAddSlot"] or "Add more")
	return category
end

function Editor:LayoutCategory(category, panelId, panel, yOffset, filterText)
	category.panelId = panelId
	category:SetPoint("TOPLEFT", category:GetParent(), "TOPLEFT", 0, -yOffset)
	category.header:GetParent().panelId = panelId
	category.centerWarning:SetShown(#Helper.GetCenterWarningEntries(panelId) > 0)
	category.container:SetShown(false)
	local rawTitle = panel.name or (L["CooldownPanelNewPanel"] or "New Panel")
	local title = truncatePanelHeaderText(rawTitle)
	if category.header.SetHeaderText then
		category.header:SetHeaderText(title)
	elseif category.header.Name then
		category.header.Name:SetText(title)
	end
	local isDisabled = panel.enabled == false
	local disabledColor = _G.DISABLED_FONT_COLOR or _G.GRAY_FONT_COLOR or NORMAL_FONT_COLOR
	if category.header.SetTitleColor then
		category.header:SetTitleColor(false, isDisabled and disabledColor or NORMAL_FONT_COLOR)
		category.header:SetTitleColor(true, isDisabled and disabledColor or NORMAL_FONT_COLOR)
		if category.header.CheckHighlightTitle then category.header:CheckHighlightTitle(nil) end
	end
	if category.header.Name and category.header.Name.SetTextColor then
		local color = isDisabled and disabledColor or NORMAL_FONT_COLOR
		category.header.Name:SetTextColor(color:GetRGB())
	end
	if category.advancedLabel then
		local showAdvancedLabel = not isDisabled and (isFixedLayoutPanel(panel) or Helper.IsBarLayout(panel and panel.layout))
		category.advancedLabel:SetText(getAdvancedPanelLabel(panel))
		category.advancedLabel:ClearAllPoints()
		category.advancedLabel:SetPoint("CENTER", category.header, "CENTER", 0, 0)
		if showAdvancedLabel then
			category.advancedLabel:Show()
		else
			category.advancedLabel:Hide()
		end
	end
	if category.disabledLabel then category.disabledLabel:SetShown(isDisabled) end

	local collapsed = self.state.collapsed[panelId] == true
	if category.header.UpdateCollapsedState then category.header:UpdateCollapsedState(collapsed) end
	releasePool(category.tiles)
	category.addTile:Hide()
	category.addTile:ClearAllPoints()

	local height = self.CATEGORY_HEIGHT
	if not collapsed then
		category.container:SetShown(true)
		local visibleEntries = {}
		local lowerFilter = filterText and filterText:lower() or nil
		syncOrder(panel.order, panel.entries)
		for _, entryId in ipairs(panel.order or {}) do
			local entry = panel.entries and panel.entries[entryId] or nil
			if entry and (not CooldownPanels.ShouldShowEntryInPanelEditor or CooldownPanels:ShouldShowEntryInPanelEditor(panel, entry)) then
				local name = getEntryName(entry)
				local typeLabel = getEntryTypeLabel(entry)
				local search = (tostring(name or "") .. " " .. tostring(typeLabel or "") .. " " .. tostring(entry.spellID or entry.itemID or entry.slotID or entry.macroID or entryId)):lower()
				if not lowerFilter or search:find(lowerFilter, 1, true) then visibleEntries[#visibleEntries + 1] = { id = entryId, entry = entry } end
			end
		end

		local cursorX = 0
		local cursorY = 0
		local gridColumn = 0
		local maxBottom = cursorY
		for index, data in ipairs(visibleEntries) do
			local tile = getPooledEntryFrame(category.tiles, category.container, "GRID")
			tile:SetPoint("TOPLEFT", category.container, "TOPLEFT", cursorX + gridColumn * (self.TILE_SIZE + self.TILE_SPACING), -cursorY)
			gridColumn = gridColumn + 1
			maxBottom = math.max(maxBottom, cursorY + self.TILE_SIZE)
			if gridColumn >= self.TILE_STRIDE then
				cursorY = cursorY + self.TILE_SIZE + self.TILE_SPACING
				gridColumn = 0
			end
			if isBarGroupPanel(panel) then tile:RegisterForDrag() else tile:RegisterForDrag("LeftButton") end
			tile.panelId = panelId
			tile.entryId = data.id
			tile.icon:SetTexture(getEntryIcon(data.entry))
			setTextureDesaturated(tile.icon, isDisabled)
			tile:SetAlpha(isDisabled and 0.45 or 1)
			local entryLayout = CooldownPanels.GetEntryEffectiveLayout and CooldownPanels:GetEntryEffectiveLayout(panelId, data.entry, nil, panel) or panel.layout
			updateAlertTypesOverlay(tile, data.entry, entryLayout)
			tile:Show()
		end

		local addTile = category.addTile
		if gridColumn >= self.TILE_STRIDE then
			cursorY = cursorY + self.TILE_SIZE + self.TILE_SPACING
			gridColumn = 0
		end
		addTile.panelId = panelId
		addTile.entryId = nil
		addTile:SetPoint("TOPLEFT", category.container, "TOPLEFT", cursorX + gridColumn * (self.TILE_SIZE + self.TILE_SPACING), -cursorY)
		addTile.icon:SetAtlas("cdm-empty", true)
		setTextureDesaturated(addTile.icon, isDisabled)
		addTile:SetAlpha(isDisabled and 0.35 or 1)
		if addTile.AlertTypesOverlay then addTile.AlertTypesOverlay:Hide() end
		addTile:Show()
		maxBottom = math.max(maxBottom, cursorY + self.TILE_SIZE)
		category.container:SetSize(self.CONTENT_WIDTH - 26, math.max(1, maxBottom))
		height = math.max(height, self.CATEGORY_HEIGHT + 15 + maxBottom + 8)
	else
		category.container:SetSize(self.CONTENT_WIDTH - 26, 1)
	end

	category.dropCatcher:ClearAllPoints()
	category.dropCatcher:SetPoint("TOPLEFT", category, "TOPLEFT", 0, -self.CATEGORY_HEIGHT)
	category.dropCatcher:SetPoint("BOTTOMRIGHT", category, "BOTTOMRIGHT")
	category.dropCatcher:SetShown(not collapsed)
	category:SetHeight(height)
	category._eqolLayoutHeight = height
	category:Show()
	return height
end

function Editor:ShowEntryMenu(owner, panelId, entryId)
	local panel = getPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId] or nil
	if not (owner and entry and Api.MenuUtil and Api.MenuUtil.CreateContextMenu) then return end
	Api.MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_COOLDOWN_PANEL_BLIZZARD_ENTRY")
		rootDescription:CreateTitle(getEntryName(entry))
		if entry.type ~= "MACRO" then
			rootDescription:CreateCheckbox(L["CooldownPanelGlowReady"] or "Glow when ready", function()
				return entry.glowReady == true
			end, function()
				entry.glowReady = entry.glowReady ~= true
				Editor:RefreshRuntime(panelId)
			end)
		end
		local soundEnabledField
		if CooldownPanels.GetEntrySoundConfig then
			_, soundEnabledField = CooldownPanels:GetEntrySoundConfig(entry)
		end
		if soundEnabledField then
			rootDescription:CreateCheckbox(L["CooldownPanelSoundReady"] or "Sound when ready", function()
				return entry[soundEnabledField] == true
			end, function()
				entry[soundEnabledField] = entry[soundEnabledField] ~= true
				Editor:RefreshRuntime(panelId)
			end)
			if CooldownPanels.ShowEntrySoundMenu then
				rootDescription:CreateButton(SOUND_LABEL or SOUND or (L["CooldownPanelSoundReady"] or "Sound when ready"), function()
					CooldownPanels:ShowEntrySoundMenu(owner, panelId, entryId)
				end)
			end
		end
		rootDescription:CreateDivider()
		rootDescription:CreateButton(EDIT or (L["CooldownPanelEntry"] or "Entry"), function()
			if CooldownPanels.OpenBlizzardEditorEntrySettings then CooldownPanels:OpenBlizzardEditorEntrySettings(panelId, entryId, owner) end
		end)
		rootDescription:CreateDivider()
		rootDescription:CreateButton(REMOVE or DELETE or (L["CooldownPanelRemoveEntry"] or "Remove entry"), function()
			if CooldownPanels.RemoveEntry then CooldownPanels:RemoveEntry(panelId, entryId) end
			Editor:Refresh()
		end)
	end)
end

function Editor:ShowPanelMenu(owner, panelId)
	if not (owner and Api.MenuUtil and Api.MenuUtil.CreateContextMenu) then return end
	local panel = getPanel(panelId)
	Api.MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_COOLDOWN_PANEL_BLIZZARD_PANEL")
		rootDescription:CreateTitle(panel and panel.name or (L["CooldownPanelNewPanel"] or "New Panel"))
		local isEnabled = not (panel and panel.enabled == false)
		rootDescription:CreateButton(isEnabled and (_G.DISABLE or "Disable") or (_G.ENABLE or "Enable"), function()
			if CooldownPanels.SetPanelEditorEnabled then
				CooldownPanels:SetPanelEditorEnabled(panelId, not isEnabled)
			else
				local currentPanel = getPanel(panelId)
				if currentPanel then currentPanel.enabled = not isEnabled end
			end
			Editor:Refresh()
		end)
		if panel then
			rootDescription:CreateCheckbox(L["CooldownPanelHideUnavailableEntriesInEditor"] or "Hide unavailable entries in editor", function()
				return panel.hideUnavailableEntriesInEditor == true
			end, function()
				if CooldownPanels.SetPanelHideUnavailableEntriesInEditor then
					CooldownPanels:SetPanelHideUnavailableEntriesInEditor(panelId, panel.hideUnavailableEntriesInEditor ~= true)
				else
					panel.hideUnavailableEntriesInEditor = panel.hideUnavailableEntriesInEditor ~= true or nil
					Editor:RefreshPanel(panelId)
				end
			end)
		end
		rootDescription:CreateDivider()
		rootDescription:CreateButton(EDIT or (L["CooldownPanelPanelName"] or "Panel name"), function()
			if CooldownPanels.OpenBlizzardEditorPanelSettings then CooldownPanels:OpenBlizzardEditorPanelSettings(panelId, owner) end
		end)
		rootDescription:CreateButton(L["CooldownPanelDuplicate"] or "Duplicate", function()
			local duplicatedPanelId = CooldownPanels.DuplicatePanel and CooldownPanels:DuplicatePanel(panelId) or nil
			if duplicatedPanelId then
				if CooldownPanels.SelectPanel then CooldownPanels:SelectPanel(duplicatedPanelId) end
				Editor:Refresh()
			end
		end)
		local importMenu = rootDescription:CreateButton(_G.IMPORT or L["Import"] or "Import")
		if CooldownPanels.AppendImportMenu then
			CooldownPanels:AppendImportMenu(importMenu, panelId)
		elseif CooldownPanels.ShowImportCDMMenu then
			importMenu:CreateButton("CDM", function()
				CooldownPanels:ShowImportCDMMenu(owner, panelId)
			end)
		end
		if CooldownPanels.GetPanelCooldownManagerSyncSource and CooldownPanels.SetPanelCooldownManagerSyncSource then
			local syncMenu = rootDescription:CreateButton(L["CooldownPanelSyncCDM"] or "Sync with Cooldown Manager")
			syncMenu:CreateRadio(_G.NONE or "None", function()
				return CooldownPanels:GetPanelCooldownManagerSyncSource(panelId) == nil
			end, function()
				CooldownPanels:SetPanelCooldownManagerSyncSource(panelId, nil)
			end)
			for _, sourceKind in ipairs({ "ESSENTIAL", "UTILITY", "BUFF_ICON" }) do
				syncMenu:CreateRadio(CooldownPanels:GetCooldownManagerSourceLabel(sourceKind), function(value)
					return CooldownPanels:GetPanelCooldownManagerSyncSource(panelId) == value
				end, function(value)
					CooldownPanels:SetPanelCooldownManagerSyncSource(panelId, value)
				end, sourceKind)
			end
		end
		if CooldownPanels.SpellGroups then CooldownPanels.SpellGroups:AppendPanelMenu(rootDescription, panelId) end
		rootDescription:CreateButton(L["CooldownPanelExportPanel"] or "Export Panel", function()
			if CooldownPanels.ShowExportPanelPopup then CooldownPanels:ShowExportPanelPopup(panelId) end
		end)
		rootDescription:CreateDivider()
		if panel and panel.entries and next(panel.entries) then
			rootDescription:CreateButton(L["CooldownPanelRemoveAllEntries"] or "Remove all entries", function()
				if CooldownPanels.ShowRemoveAllEntriesPopup then CooldownPanels:ShowRemoveAllEntriesPopup(panelId) end
			end)
		end
		rootDescription:CreateButton(REMOVE or DELETE or (L["CooldownPanelDeletePanel"] or "Delete Panel"), function()
			if CooldownPanels.ShowDeletePanelPopup then CooldownPanels:ShowDeletePanelPopup(panelId) end
		end)
	end)
end

function Editor:AreSwitcherAddOnsLoaded()
	if not (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded) then return false end
	local _, cooldownPanelsLoaded = _G.C_AddOns.IsAddOnLoaded("EnhanceQoLCooldownPanels")
	local _, quickActionsLoaded = _G.C_AddOns.IsAddOnLoaded("EnhanceQoLQuickActions")
	return cooldownPanelsLoaded == true
		and quickActionsLoaded == true
		and addon.Aura
		and addon.Aura.CooldownPanels
		and addon.QuickCast
		and addon.QuickCast.Editor ~= nil
end

function Editor:OpenQuickActionsEditor()
	if not self:AreSwitcherAddOnsLoaded() then return end
	local blizzardEditorFrame = self:GetFrame()
	if blizzardEditorFrame and blizzardEditorFrame.Hide then blizzardEditorFrame:Hide() end
	if CooldownPanels.CloseEditor then CooldownPanels:CloseEditor() end
	addon.QuickCast.Editor:Open()
end

function Editor:SetSideTabSelected(tab, selected)
	if not tab then return end
	if tab.SelectedTexture then tab.SelectedTexture:SetShown(selected == true) end
	if tab.Icon then tab.Icon:SetAlpha(selected == true and 1 or 0.55) end
end

function Editor:CreateSideTab(parent, data)
	local tab = _G.CreateFrame("Button", nil, parent, "LargeSideTabButtonTemplate")
	tab:SetFrameLevel(parent:GetFrameLevel() + 10)
	tab.tooltipText = data.tooltipText
	if data.iconAtlas then
		tab.Icon:SetAtlas(data.iconAtlas, false)
	else
		tab.Icon:SetTexture(data.iconTexture)
		tab.Icon:SetTexCoord(0, 1, 0, 1)
	end
	tab.Icon:SetSize(26, 26)
	if tab.SelectedTexture then tab.SelectedTexture:SetAlpha(1) end
	self:SetSideTabSelected(tab, data.selected)
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside and data.onClick then data.onClick() end
	end)
	return tab
end

function Editor:CreateSwitcherTabs(frame) addon.FeatureEditor:AttachTabs(frame, "panels") end
function Editor:UpdateSwitcherTabs(frame) addon.FeatureEditor:UpdateTabs(frame) end

function Editor:CreateFrame()
	local frame = _G.EQOLCooldownPanelsBlizzardEditor
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(selfFrame)
		selfFrame:StopMovingOrSizing()
		saveFramePosition(selfFrame)
	end)
	self:CreateSwitcherTabs(frame)
	frame:SetScript("OnShow", function(selfFrame)
		Editor:UpdateSwitcherTabs(selfFrame)
	end)
	frame:SetScript("OnHide", function(selfFrame)
		selfFrame:UnregisterEvent("GLOBAL_MOUSE_UP")
		Editor.state.drag = nil
		Editor.state.reorderTarget = nil
		Editor.state.eatNextGlobalMouseUp = nil
		Editor:SetSourceTileDesaturated(false)
		if selfFrame.ReorderMarker then selfFrame.ReorderMarker:Hide() end
		Editor:HideDraggedIcon()
		if CooldownPanels.SetEditorLayoutEditEnabled then CooldownPanels:SetEditorLayoutEditEnabled(false) end
		if CooldownPanels.HideLayoutEntryStandaloneMenu then CooldownPanels:HideLayoutEntryStandaloneMenu() end
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		if Editor.state.drag then
			Editor:UpdateReorderMarker()
		else
			Editor:UpdateExternalDropPulse(elapsed)
		end
	end)
	frame:SetScript("OnMouseUp", function(_, buttonName)
		if buttonName == "RightButton" then Editor:CancelDrag() end
	end)
	frame:SetScript("OnEvent", function(_, eventName, unitTarget)
		if eventName == "GLOBAL_MOUSE_UP" then
			local buttonName = unitTarget
			if Editor.state.eatNextGlobalMouseUp == buttonName then
				Editor.state.eatNextGlobalMouseUp = nil
				return
			end
			if buttonName == "RightButton" then
				Editor:CancelDrag()
			elseif buttonName == "LeftButton" then
				Editor:EndDrag()
			end
			return
		end
	end)
	setupFramePortrait(frame)
	if frame.TitleContainer and frame.TitleContainer.TitleText then
		frame.TitleContainer.TitleText:SetText(getFrameTitle())
	elseif frame.TitleText then
		frame.TitleText:SetText(getFrameTitle())
	end

	frame.helpButton = frame.helpButton or createEditorHelpButton(frame)
	frame.addPanelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.addPanelButton:SetSize(126, 22)
	frame.addPanelButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -44, 4)
	local addPanelIcon = CreateAtlasMarkup and CreateAtlasMarkup("communities-icon-addgroupplus", 16, 16, 0, -1) or "+"
	frame.addPanelButton:SetText(string.format("%s %s", addPanelIcon, L["Add Panel"] or "Add Panel"))
	frame.addPanelButton:SetScript("OnClick", function()
		Editor:CreatePanelFromDropdown()
	end)
	frame.searchBox = frame.SearchBox
	if frame.searchBox.Instructions then frame.searchBox.Instructions:SetText(_G.COOLDOWN_VIEWER_SETTINGS_SEARCH_INSTRUCTIONS or SEARCH) end
	frame.searchBox:SetScript("OnTextChanged", function(selfBox)
		SearchBoxTemplate_OnTextChanged(selfBox)
		Editor:Refresh()
	end)

	frame.gear = frame.SettingsDropdown
	frame.gear.Icon:SetAtlas("questlog-icon-setting", true)
	applyTooltip(frame.gear, SETTINGS or "Settings")
	frame.gear:SetupMenu(function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_COOLDOWN_PANEL_BLIZZARD_VIEW")
		rootDescription:CreateTitle(SETTINGS or "Settings")
		rootDescription:CreateButton(L["CooldownPanelImportPanel"] or "Import Panel", function()
			Editor:ShowImportPanelPopup()
		end)
		local sortMenu = rootDescription:CreateButton(L["CooldownPanelSortMode"] or "Sort")
		sortMenu:CreateRadio(L["CooldownPanelSortManual"] or "Manual", isSortModeSelected, setSortMode, "MANUAL")
		sortMenu:CreateRadio(L["CooldownPanelSortNameAsc"] or "Name A-Z", isSortModeSelected, setSortMode, "NAME_ASC")
		sortMenu:CreateRadio(L["CooldownPanelSortNameDesc"] or "Name Z-A", isSortModeSelected, setSortMode, "NAME_DESC")
		if Editor.state.classView == "ALL" then
			rootDescription:CreateButton(L["CooldownPanelExportView"] or "Export View", function()
				Editor:ExportView(Editor:GetCurrentViewPanelIds())
			end)
		else
			local exportViewMenu = rootDescription:CreateButton(L["CooldownPanelExportView"] or "Export View")
			exportViewMenu:CreateButton(L["CooldownPanelExportViewAll"] or "All in View", function()
				Editor:ExportView(Editor:GetCurrentViewPanelIds())
			end)
			exportViewMenu:CreateButton(L["CooldownPanelExportViewClassSpecific"] or "Class Specific", function()
				Editor:ExportView(Editor:GetCurrentSpecificViewPanelIds())
			end)
		end
		if CooldownPanels.OpenEditor then
			rootDescription:CreateDivider()
			rootDescription:CreateButton(L["CooldownPanelSwitchToClassicView"] or "Switch to Classic View", function()
				if CooldownPanels.SwitchEditorView then
					CooldownPanels:SwitchEditorView("classic")
				else
					local editorFrame = Editor:GetFrame()
					if editorFrame then editorFrame:Hide() end
					CooldownPanels:OpenEditor()
				end
			end)
		end
	end)

	frame.scroll = frame.CooldownScroll
	frame.content = frame.CooldownScroll.Content
	frame.categories = {}

	frame.classDropdown = frame.LayoutDropdown
	frame.classDropdown:SetWidth(220)
	frame.classDropdown:SetupMenu(function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_COOLDOWN_PANEL_BLIZZARD_CLASS_VIEW")
		rootDescription:CreateRadio(ALL_CLASSES or L["All classes"], isClassViewSelected, setClassView, "ALL")
		for _, option in ipairs(Editor:GetClassOptions()) do
			rootDescription:CreateRadio(option.label, isClassViewSelected, setClassView, option.value)
		end
	end)
	if frame.classDropdown.SetDefaultText then frame.classDropdown:SetDefaultText(getClassViewLabel()) end

	self.frame = frame
	return frame
end

function Editor:GetFrame()
	return self.frame or self:CreateFrame()
end

function Editor:Refresh()
	local frame = self:GetFrame()
	if not frame:IsShown() then return end
	setupFramePortrait(frame)
	local root = getRoot()
	if not root then return end
	local filterText = frame.searchBox and frame.searchBox:GetText() or nil
	if filterText == "" then filterText = nil end

	releasePool(frame.categories)
	local yOffset = 0
	local categoryIndex = 0
	for _, panelId in ipairs(getSortedPanelIds(root)) do
		local panel = getPanel(panelId)
		if panel and panelMatchesClassView(panel) then
			categoryIndex = categoryIndex + 1
			local category = getPooled(frame.categories, frame.content, function(parent) return Editor:CreateCategory(parent) end)
			local height = self:LayoutCategory(category, panelId, panel, yOffset, filterText)
			yOffset = yOffset + height + 8
		end
	end
	frame.content:SetHeight(math.max(1, yOffset))
	if frame.classDropdown and frame.classDropdown.SetDefaultText then frame.classDropdown:SetDefaultText(getClassViewLabel()) end
	if frame.classDropdown and frame.classDropdown.GenerateMenu then frame.classDropdown:GenerateMenu() end
end

function Editor:RefreshPanel(panelId)
	local frame = self.frame
	if not (frame and frame:IsShown()) then return end
	panelId = normalizeId(panelId)
	local filterText = frame.searchBox and frame.searchBox:GetText() or nil
	if filterText == "" then filterText = nil end
	local yOffset = 0
	local found = false
	for categoryIndex = 1, (frame.categories.active or 0) do
		local category = frame.categories[categoryIndex]
		local categoryPanelId = normalizeId(category and category.panelId)
		local panel = categoryPanelId and getPanel(categoryPanelId) or nil
		if panel and panelMatchesClassView(panel) then
			local height = self:LayoutCategory(category, categoryPanelId, panel, yOffset, filterText)
			if categoryPanelId == panelId then found = true end
			yOffset = yOffset + height + 8
		end
	end
	frame.content:SetHeight(math.max(1, yOffset))
	if not found then self:Refresh() end
end

function Editor:RefreshEntryAlert(panelId, entryId)
	local frame = self.frame
	if not (frame and frame:IsShown()) then return false end
	panelId = normalizeId(panelId)
	entryId = normalizeId(entryId)
	local panel = panelId and getPanel(panelId) or nil
	local entry = panel and panel.entries and panel.entries[entryId] or nil
	if not entry then return false end
	local entryLayout = CooldownPanels.GetEntryEffectiveLayout and CooldownPanels:GetEntryEffectiveLayout(panelId, entry, nil, panel) or panel.layout

	for categoryIndex = 1, (frame.categories.active or 0) do
		local category = frame.categories[categoryIndex]
		if normalizeId(category and category.panelId) == panelId then
			for tileIndex = 1, (category.tiles.active or 0) do
				local tile = category.tiles[tileIndex]
				if normalizeId(tile and tile.entryId) == entryId then
					updateAlertTypesOverlay(tile, entry, entryLayout)
					return true
				end
			end
			return false
		end
	end
	return false
end

function Editor:Open()
	self:EnsureInitialClassView()
	local frame = self:GetFrame()
	positionFrameForOpen(frame)
	frame:Show()
	if frame.Raise then frame:Raise() end
	self:Refresh()
	return frame
end

function Editor:Toggle()
	local frame = self:GetFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		self:Open()
	end
end

function CooldownPanels:OpenBlizzardEditor() return Editor:Open() end

function CooldownPanels:ToggleBlizzardEditor() return Editor:Toggle() end
