local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = _G.LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local QC = addon.QuickCast
local Editor = {
	CATEGORY_WIDTH = 344,
	TILE_SIZE = 38,
	TILE_SPACING = 8,
	TILE_STRIDE = 7,
	state = {
		collapsed = {},
		classLocked = false,
		classView = nil,
		layoutEdit = false,
		specView = "ALL",
	},
}
local M = {}

QC.Editor = Editor

M.POPUP_DELETE = "EQOL_QUICKCAST_DELETE_MENU"
M.POPUP_REPLACE = "EQOL_QUICKCAST_REPLACE_BINDING"
M.POPUP_ADD_BY_ID = "EQOL_QUICKCAST_ADD_BY_ID"
M.POPUP_MACRO_COMMAND = "EQOL_QUICKCAST_MACRO_COMMAND"
M.ADDON_ICON = "Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga"
M.COOLDOWN_PANEL_ICON = "Interface\\AddOns\\EnhanceQoL\\Assets\\NewSettings\\CastbarsCooldowns.tga"
M.QUICK_ACTIONS_ICON_ATLAS = "common-icon-undo"
M.PROFESSION_ACTION_SPELL_IDS = {
	2259, -- Alchemy
	2018, -- Blacksmithing
	2550, -- Cooking
	7411, -- Enchanting
	4036, -- Engineering
	131474, -- Fishing
	45357, -- Inscription
	25229, -- Jewelcrafting
	2108, -- Leatherworking
	53428, -- Runeforging
	80451, -- Survey
	3908, -- Tailoring
}

function M.isEditingAllowed()
	return not _G.InCombatLockdown()
end

function M.showError(message)
	if _G.UIErrorsFrame then _G.UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2) end
end

function M.trim(value)
	if type(value) ~= "string" then return "" end
	return value:match("^%s*(.-)%s*$") or ""
end

function M.copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, entry in pairs(value) do result[M.copy(key)] = M.copy(entry) end
	return result
end

function M.clampInteger(value, minimum, maximum, fallback)
	value = tonumber(value)
	if not value then value = fallback or minimum end
	value = math.floor(value + 0.5)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

function M.isAddOnLoaded(addonName)
	if not _G.C_AddOns or not _G.C_AddOns.IsAddOnLoaded then return false end
	local _, loaded = _G.C_AddOns.IsAddOnLoaded(addonName)
	return loaded == true
end

function M.areEditorAddOnsLoaded()
	return M.isAddOnLoaded("EnhanceQoLCooldownPanels")
		and M.isAddOnLoaded("EnhanceQoLQuickActions")
		and addon.Aura
		and addon.Aura.CooldownPanels
		and addon.QuickCast
		and addon.QuickCast.Editor ~= nil
end

function M.openCooldownPanelEditor()
	if not M.areEditorAddOnsLoaded() then return end
	local panels = addon.Aura.CooldownPanels
	if Editor.frame and Editor.frame.Hide then Editor.frame:Hide() end
	if panels.CloseEditor then panels:CloseEditor() end
	if panels.OpenBlizzardEditor then
		panels:OpenBlizzardEditor()
	elseif panels.OpenPreferredEditor then
		panels:OpenPreferredEditor()
	elseif panels.OpenEditor then
		panels:OpenEditor()
	end
end

function M.getMenu(menuID)
	return menuID and QC:GetMenu(menuID) or nil
end

function M.getSelectedMenu()
	return M.getMenu(Editor.state.selectedMenuID)
end

function M.getActionIndex(menuID, entryID)
	if not (menuID and entryID) then return nil end
	if QC.GetActionIndexByEntryID then
		local index = QC:GetActionIndexByEntryID(menuID, entryID)
		if index then return index end
	end
	local menu = M.getMenu(menuID)
	for index, action in ipairs(menu and menu.actions or {}) do
		if tostring(action.entryID) == tostring(entryID) then return index end
	end
	return nil
end

function M.getAction(menuID, entryID)
	local menu = M.getMenu(menuID)
	local index = M.getActionIndex(menuID, entryID)
	return menu and index and menu.actions[index] or nil, index, menu
end

function M.getEntryID(action, index)
	return action and action.entryID or (action and ("index:" .. tostring(index)) or nil)
end

function M.getSelectedAction()
	return M.getAction(Editor.state.selectedMenuID, Editor.state.selectedEntryID)
end

function M.resolveSpellAction(spellID)
	spellID = tonumber(spellID)
	if not spellID then return nil end
	local mountID = _G.C_MountJournal
		and _G.C_MountJournal.GetMountFromSpell
		and _G.C_MountJournal.GetMountFromSpell(spellID)
	if mountID then return { kind = "mount", id = mountID } end
	return { kind = "spell", id = spellID }
end

function M.resolveBattlePetAction(...)
	if not (_G.C_PetJournal and _G.C_PetJournal.GetPetInfoByPetID) then return nil end
	for index = 1, select("#", ...) do
		local candidate = select(index, ...)
		if _G.issecretvalue and _G.issecretvalue(candidate) then return nil end
		if type(candidate) == "string" and candidate ~= "" and _G.C_PetJournal.GetPetInfoByPetID(candidate) then
			return { kind = "battlepet", id = candidate }
		end
	end
	local numericID = tonumber((...))
	if numericID and _G.C_PetJournal.GetPetInfoByIndex then
		local petID = _G.C_PetJournal.GetPetInfoByIndex(numericID)
		if petID and _G.C_PetJournal.GetPetInfoByPetID(petID) then return { kind = "battlepet", id = petID } end
	end
	return nil
end

function M.resolveEquipmentSetAction(value)
	if _G.issecretvalue and _G.issecretvalue(value) then return nil end
	local equipmentSet = _G.C_EquipmentSet
	if not (equipmentSet and equipmentSet.GetEquipmentSetInfo) then return nil end
	local setID = tonumber(value)
	if not setID and type(value) == "string" and equipmentSet.GetEquipmentSetID then
		setID = equipmentSet.GetEquipmentSetID(value)
	end
	if _G.issecretvalue and _G.issecretvalue(setID) then return nil end
	if not setID then return nil end
	local name, icon, resolvedSetID = equipmentSet.GetEquipmentSetInfo(setID)
	local ownerGUID = _G.UnitGUID and _G.UnitGUID("player")
	if _G.issecretvalue
		and (
			_G.issecretvalue(name)
			or _G.issecretvalue(icon)
			or _G.issecretvalue(resolvedSetID)
			or _G.issecretvalue(ownerGUID)
		)
	then
		return nil
	end
	if type(name) ~= "string" or name == "" or type(ownerGUID) ~= "string" or ownerGUID == "" then return nil end
	return {
		kind = "equipmentset",
		id = tonumber(resolvedSetID) or setID,
		name = name,
		ownerGUID = ownerGUID,
	}
end

function M.resolveOutfitAction(value)
	if _G.issecretvalue and _G.issecretvalue(value) then return nil end
	local outfitAPI = _G.C_TransmogOutfitInfo
	if not (outfitAPI and outfitAPI.GetOutfitInfo) then return nil end
	local outfitID = tonumber(value)
	if _G.issecretvalue and _G.issecretvalue(outfitID) then return nil end
	if not outfitID or outfitID <= 0 then return nil end
	outfitID = math.floor(outfitID)
	local outfitInfo = outfitAPI.GetOutfitInfo(outfitID)
	if not outfitInfo or (_G.issecrettable and _G.issecrettable(outfitInfo)) then return nil end
	local resolvedOutfitID = outfitInfo.outfitID
	local name = outfitInfo.name
	local icon = outfitInfo.icon
	local isDisabled = outfitInfo.isDisabled
	if
		_G.issecretvalue
		and (
			_G.issecretvalue(resolvedOutfitID)
			or _G.issecretvalue(name)
			or _G.issecretvalue(icon)
			or _G.issecretvalue(isDisabled)
		)
	then
		return nil
	end
	resolvedOutfitID = tonumber(resolvedOutfitID)
	if
		not resolvedOutfitID
		or resolvedOutfitID <= 0
		or type(name) ~= "string"
		or name == ""
		or type(icon) ~= "number"
		or icon <= 0
		or isDisabled == true
	then
		return nil
	end
	return {
		kind = "outfit",
		id = math.floor(resolvedOutfitID),
		name = name,
		icon = icon,
	}
end

function M.resolveCursorAction()
	local cursorType, value1, value2, value3 = _G.GetCursorInfo()
	if cursorType == "spell" then
		return M.resolveSpellAction(tonumber(value3) or tonumber(value1) or tonumber(value2))
	elseif cursorType == "item" then
		local itemID = tonumber(value1)
		if not itemID and _G.C_Item and _G.C_Item.GetItemInfoInstant then itemID = _G.C_Item.GetItemInfoInstant(value1 or value2) end
		if itemID then return { kind = "item", id = itemID } end
	elseif cursorType == "mount" or cursorType == "summonmount" then
		local mountID = tonumber(value1)
		local collected = mountID
			and _G.C_MountJournal
			and _G.C_MountJournal.GetMountInfoByID
			and select(11, _G.C_MountJournal.GetMountInfoByID(mountID))
		if collected then return { kind = "mount", id = mountID } end
	elseif cursorType == "battlepet" or cursorType == "summonpet" then
		return M.resolveBattlePetAction(value1, value2, value3)
	elseif cursorType == "macro" then
		local macroIndex = tonumber(value1)
		local name = macroIndex and _G.GetMacroInfo(macroIndex)
		if name then return { kind = "macro", name = name, indexHint = macroIndex } end
	elseif cursorType == "equipmentset" then
		return M.resolveEquipmentSetAction(value1 or value2 or value3)
	elseif cursorType == "outfit" then
		return M.resolveOutfitAction(value1)
	elseif cursorType == "action" or cursorType == "actionbar" then
		local actionSlot = tonumber(value1) or tonumber(value2) or tonumber(value3)
		local actionType, id, subType
		if actionSlot then actionType, id, subType = _G.GetActionInfo(actionSlot) end
		if actionType == "spell" then
			return M.resolveSpellAction(id)
		elseif actionType == "item" then
			local itemID = tonumber(id)
			if not itemID and _G.C_Item and _G.C_Item.GetItemInfoInstant then itemID = _G.C_Item.GetItemInfoInstant(id) end
			if itemID then return { kind = "item", id = itemID } end
		elseif (actionType == "mount" or actionType == "summonmount") and tonumber(id) then
			return { kind = "mount", id = tonumber(id) }
		elseif actionType == "battlepet" or actionType == "summonpet" then
			return M.resolveBattlePetAction(id, subType)
		elseif actionType == "macro" then
			local macroIndex = tonumber(id)
			local name = actionSlot and _G.GetActionText and _G.GetActionText(actionSlot) or nil
			if name and _G.GetMacroIndexByName then
				local namedIndex = _G.GetMacroIndexByName(name)
				if namedIndex and namedIndex > 0 then macroIndex = namedIndex end
			end
			if not name and macroIndex then name = _G.GetMacroInfo(macroIndex) end
			if name then return { kind = "macro", name = name, indexHint = macroIndex } end
		elseif actionType == "equipmentset" then
			return M.resolveEquipmentSetAction(id or (actionSlot and _G.GetActionText and _G.GetActionText(actionSlot)))
		elseif actionType == "outfit" then
			return M.resolveOutfitAction(id)
		end
	end
	return nil
end

function M.getActionName(action)
	local name, icon, valid, _, iconAtlas = QC:ResolveAction(action)
	return action and action.managedLabel or name or "?",
		action and action.customIcon or icon or 134400,
		valid == true,
		action and not action.customIcon and (action.customIconAtlas or iconAtlas) or nil
end

function M.applyActionTexture(texture, action, icon, resolvedAtlas)
	local atlas = action and not action.customIcon and (action.customIconAtlas or resolvedAtlas)
	if atlas and texture.SetAtlas then
		local ok = pcall(texture.SetAtlas, texture, atlas, true)
		if ok then return end
	end
	texture:SetTexture(action and action.customIcon or icon or 134400)
end

function M.getEQOLActionName(actionID)
	local definition = QC.EQOL_ACTIONS and QC.EQOL_ACTIONS[actionID]
	return definition and (L[definition.labelKey] or definition.labelKey) or tostring(actionID or "")
end

function M.getActionIdentity(action)
	if not action then return "" end
	if action.kind == "macro" then return string.format("%s: %s", _G.MACRO or "Macro", action.name or "?") end
	if action.kind == "eqol" then return string.format("Enhance QoL: %s", M.getEQOLActionName(action.id)) end
	if action.kind == "menu" then
		local menu = M.getMenu(action.id)
		return string.format("%s: %s", L["QuickCastNestedMenu"] or "QuickActions ring", menu and menu.name or "?")
	end
	local kindLabel = action.kind == "spell" and (_G.SPELL or "Spell")
		or action.kind == "item" and (_G.ITEM or "Item")
		or action.kind == "mount" and (_G.MOUNT or "Mount")
		or action.kind == "battlepet" and (_G.BATTLE_PET or "Battle Pet")
		or action.kind == "equipmentset" and (L["Equipment Sets"] or "Equipment Set")
		or action.kind == "outfit" and (L["QuickCastOutfits"] or "Outfit")
		or action.kind == "raidtarget" and (L["RaidTargetIcon"] or "Target Marker")
		or action.kind == "worldmarker" and (L["WorldMarkers"] or "World Marker")
		or tostring(action.kind or "")
	local identity = string.format("%s ID: %s", kindLabel, tostring(action.id or "?"))
	if action.managedLabel then return string.format("%s - %s", action.managedLabel, identity) end
	return identity
end

function M.truncate(text, maximum)
	text = tostring(text or "")
	maximum = tonumber(maximum) or 28
	local length = _G.strlenutf8 and _G.strlenutf8(text) or #text
	if length <= maximum then return text end
	if _G.strsubutf8 then return _G.strsubutf8(text, 1, maximum - 3) .. "..." end
	return text:sub(1, maximum - 3) .. "..."
end

function M.showActionTooltip(owner, action)
	if not (_G.GameTooltip and action) then return end
	_G.GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	if action.kind == "spell" and _G.GameTooltip.SetSpellByID then
		_G.GameTooltip:SetSpellByID(action.id, false)
	elseif action.kind == "item"
		and _G.PlayerHasToy
		and _G.PlayerHasToy(action.id)
		and _G.GameTooltip.SetToyByItemID
	then
		_G.GameTooltip:SetToyByItemID(action.id)
	elseif action.kind == "item" and _G.GameTooltip.SetItemByID then
		_G.GameTooltip:SetItemByID(action.id)
	else
		local name = M.getActionName(action)
		_G.GameTooltip:SetText(name, 1, 0.82, 0)
	end
	_G.GameTooltip:AddLine(" ")
	_G.GameTooltip:AddLine(M.getActionIdentity(action), 0.65, 0.65, 0.65, true)
	_G.GameTooltip:Show()
end

function M.hideTooltip()
	if _G.GameTooltip then _G.GameTooltip:Hide() end
end

M.IconPickerMixin = {}

function M.iconMatchesSearch(icon, query, alternateQuery, numericQuery)
	local iconType = type(icon)
	if iconType == "number" then
		return numericQuery and tostring(icon):find(query, 1, true) ~= nil or false
	end
	if iconType ~= "string" then return false end
	local value = icon:lower()
	return value:find(query, 1, true) ~= nil
		or alternateQuery ~= query and value:find(alternateQuery, 1, true) ~= nil
end

function M.IconPickerMixin:GetIconByIndex(index)
	if self.filteredIcons then return self.filteredIcons[index] end
	return self.iconDataProvider and self.iconDataProvider:GetIconByIndex(index) or nil
end

function M.IconPickerMixin:GetNumIcons()
	if self.filteredIcons then return #self.filteredIcons end
	return self.iconDataProvider and self.iconDataProvider:GetNumIcons() or 0
end

function M.IconPickerMixin:GetIndexOfIcon(icon)
	if self.filteredIcons then
		for index, candidate in ipairs(self.filteredIcons) do
			if candidate == icon then return index end
		end
		return nil
	end
	return self.iconDataProvider and self.iconDataProvider:GetIndexOfIcon(icon) or nil
end

function M.IconPickerMixin:UpdateNoResults()
	if not self.NoResults then return end
	local noResults = self.filterQuery and self.filterQuery ~= "" and self:GetNumIcons() == 0
	local draggingIcon = self.BorderBox.IconDragArea:IsShown()
	self.NoResults:SetShown(noResults and not draggingIcon)
end

function M.IconPickerMixin:ApplySearch(force)
	if not self.iconDataProvider then return end
	local query = M.trim(self.SearchBox:GetText()):lower():gsub("\\", "/")
	if #query < 2 then query = "" end
	local searchKey = tostring(self.iconFilter) .. "\31" .. query
	if not force and self.appliedSearchKey == searchKey then return end
	self.appliedSearchKey = searchKey
	local selectedIcon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	self.filterQuery = query ~= "" and query or nil
	self.filteredIcons = nil

	if self.filterQuery then
		local alternateQuery = self.filterQuery:gsub("/", "\\")
		local numericQuery = self.filterQuery:match("^%d+$") ~= nil
		local filteredIcons = {}
		for index = 1, self.iconDataProvider:GetNumIcons() do
			local icon = self.iconDataProvider:GetIconByIndex(index)
			if M.iconMatchesSearch(icon, self.filterQuery, alternateQuery, numericQuery) then filteredIcons[#filteredIcons + 1] = icon end
		end
		self.filteredIcons = filteredIcons
	end

	self.IconSelector:UpdateSelections()
	local selectedIndex = self.filteredIcons and self:GetIndexOfIcon(selectedIcon) or nil
	self.IconSelector:SetSelectedIndex(selectedIndex)
	if selectedIndex then self.IconSelector:ScrollToSelectedIndex() end
	if self.filteredIcons then self:SetSelectedIconText() end
	self:UpdateNoResults()
end

function M.IconPickerMixin:ScheduleSearch()
	if self.suppressSearch then return end
	self.searchGeneration = (self.searchGeneration or 0) + 1
	local generation = self.searchGeneration
	if _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0.25, function()
			if self:IsShown() and self.searchGeneration == generation then self:ApplySearch() end
		end)
	else
		self:ApplySearch()
	end
end

function M.IconPickerMixin:SetIconFilterInternal(iconFilter)
	if self.iconFilter == iconFilter then return end
	self.filteredIcons = nil
	self.appliedSearchKey = nil
	self.iconFilter = iconFilter
	local filterTypes = _G.IconSelectorPopupFrameIconFilterTypes
	local iconTypes
	if filterTypes and iconFilter == filterTypes.Spell then
		iconTypes = { _G.IconDataProviderIconType.Spell }
	elseif filterTypes and iconFilter == filterTypes.Item then
		iconTypes = { _G.IconDataProviderIconType.Item }
	elseif _G.IconDataProvider_GetAllIconTypes then
		iconTypes = _G.IconDataProvider_GetAllIconTypes()
	end
	self.iconDataProvider:SetIconTypes(iconTypes)
	self:ApplySearch(true)
end

function M.IconPickerMixin:UpdateStateFromCursorType()
	_G.IconSelectorPopupFrameTemplateMixin.UpdateStateFromCursorType(self)
	local draggingIcon = self.BorderBox.IconDragArea:IsShown()
	self.SearchBox:SetShown(not draggingIcon)
	self.BorderBox.EditBoxHeaderText:SetShown(not draggingIcon)
	self:UpdateNoResults()
end

function M.IconPickerMixin:OnShow()
	_G.IconSelectorPopupFrameTemplateMixin.OnShow(self)
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	if not self.iconDataProvider then
		self.iconDataProvider = _G.CreateAndInitFromMixin(
			_G.IconDataProviderMixin,
			_G.IconDataProviderExtraType.Spellbook
		)
	end
	self.filteredIcons = nil
	self.filterQuery = nil
	self.appliedSearchKey = nil
	self.suppressSearch = true
	self.SearchBox:SetText("")
	self.suppressSearch = nil
	self.IconSelector:SetSelectionsDataProvider(
		function(index) return self:GetIconByIndex(index) end,
		function() return self:GetNumIcons() end
	)
	self:SetIconFilter(_G.IconSelectorPopupFrameIconFilterTypes.All)

	local initialIcon = self.initialIcon or 134400
	self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(initialIcon)
	self.IconSelector:SetSelectedIndex(nil)
	local description = self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription
	description:SetText(_G.ICON_SELECTION_CLICK)
	description:SetFontObject(_G.GameFontHighlightSmall)
	self.BorderBox.SelectedIconArea.SelectedIconText:Layout()
	self.BorderBox.OkayButton:Enable()
	self.SearchBox:SetFocus()
	self:UpdateNoResults()

	self.IconSelector:SetSelectedCallback(function(_, icon)
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon)
		local description = self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription
		description:SetText(_G.ICON_SELECTION_CLICK)
		description:SetFontObject(_G.GameFontHighlightSmall)
		self.BorderBox.SelectedIconArea.SelectedIconText:Layout()
	end)
end

function M.IconPickerMixin:OnHide()
	_G.IconSelectorPopupFrameTemplateMixin.OnHide(self)
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self.searchGeneration = (self.searchGeneration or 0) + 1
	self.filteredIcons = nil
	self.filterQuery = nil
	self.appliedSearchKey = nil
	self.menuID = nil
	self.entryID = nil
	self.initialIcon = nil
end

function M.IconPickerMixin:OnEvent(eventName, ...)
	if eventName == "PLAYER_REGEN_DISABLED" then
		self:Hide()
		return
	end
	_G.IconSelectorPopupFrameTemplateMixin.OnEvent(self, eventName, ...)
end

function M.IconPickerMixin:OkayButton_OnClick()
	local menuID, entryID = self.menuID, self.entryID
	local icon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	if menuID and entryID and icon and M.isEditingAllowed() then
		M.mutateAction(menuID, entryID, function(action) action.customIcon = icon end, false)
	end
	_G.IconSelectorPopupFrameTemplateMixin.OkayButton_OnClick(self)
end

function M.IconPickerMixin:CancelButton_OnClick()
	_G.IconSelectorPopupFrameTemplateMixin.CancelButton_OnClick(self)
end

function M.createIconPicker()
	local frame = Editor.iconPicker or _G.EQOLQuickCastIconPicker
	if not frame then return nil end
	if frame.eqolQuickCastInitialized then return frame end
	frame.eqolQuickCastInitialized = true
	_G.Mixin(frame, M.IconPickerMixin)
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame.IconSelector:SetFrameStrata("FULLSCREEN_DIALOG")
	frame.BorderBox.IconSelectorEditBox:Hide()
	frame.BorderBox.EditBoxHeaderText:SetText(_G.SEARCH or "Search")
	frame.BorderBox.IconSelectionText:SetText(_G.MACRO_POPUP_CHOOSE_ICON or "Choose an icon")
	frame.NoResults:SetText(_G.NO_RESULTS_FOUND or "No results found.")
	if frame.SearchBox.Instructions then frame.SearchBox.Instructions:SetText(_G.SEARCH or "Search") end
	frame.SearchBox:SetScript("OnTextChanged", function(self)
		if _G.SearchBoxTemplate_OnTextChanged then _G.SearchBoxTemplate_OnTextChanged(self) end
		frame:ScheduleSearch()
	end)
	frame.SearchBox:SetScript("OnEnterPressed", function(self)
		frame:ApplySearch()
		self:ClearFocus()
	end)
	frame.SearchBox:SetScript("OnEscapePressed", function(self)
		if self:GetText() ~= "" then
			self:SetText("")
		else
			frame:Hide()
		end
	end)
	frame:SetScript("OnShow", function(self) self:OnShow() end)
	frame:SetScript("OnHide", function(self) self:OnHide() end)
	frame:SetScript("OnEvent", function(self, ...) self:OnEvent(...) end)
	if _G.UISpecialFrames then table.insert(_G.UISpecialFrames, frame:GetName()) end
	Editor.iconPicker = frame
	return frame
end

function M.openIconPicker(menuID, entryID)
	if not M.isEditingAllowed() then return end
	local action = M.getAction(menuID, entryID)
	if not action then return end
	local _, resolvedIcon = QC:ResolveAction(action)
	local frame = M.createIconPicker()
	if not frame then return end
	if frame:IsShown() then frame:Hide() end
	frame.menuID = menuID
	frame.entryID = entryID
	frame.initialIcon = action.customIcon or resolvedIcon or 134400
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
	frame:Show()
	if frame.Raise then frame:Raise() end
end

function M.resetCustomIcon(menuID, entryID)
	if not M.isEditingAllowed() then return end
	local frame = Editor.iconPicker
	if frame and frame:IsShown() and frame.menuID == menuID and frame.entryID == entryID then frame:Hide() end
	M.mutateAction(menuID, entryID, function(action) action.customIcon = nil end, false)
end

function M.suppressTileMouseUp(mouseButton)
	Editor.state.suppressNextTileMouseUp = mouseButton
	if _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0, function()
			if Editor.state.suppressNextTileMouseUp == mouseButton then Editor.state.suppressNextTileMouseUp = nil end
		end)
	end
end

function M.consumeSuppressedMouseUp(mouseButton)
	if not mouseButton then return false end
	if Editor.state.suppressNextTileMouseUp ~= mouseButton then return false end
	Editor.state.suppressNextTileMouseUp = nil
	return true
end

function M.formatBinding(binding)
	if not binding or binding == "" then return _G.NOT_BOUND or "Not bound" end
	return _G.GetBindingText(binding, "KEY_", 1) or binding
end

function M.modifierPrefix(key)
	local prefix = ""
	if _G.IsAltKeyDown() and key ~= "LALT" and key ~= "RALT" then prefix = prefix .. "ALT-" end
	if _G.IsControlKeyDown() and key ~= "LCTRL" and key ~= "RCTRL" then prefix = prefix .. "CTRL-" end
	if _G.IsShiftKeyDown() and key ~= "LSHIFT" and key ~= "RSHIFT" then prefix = prefix .. "SHIFT-" end
	return prefix
end

M.ignoredBindingKeys = {
	LALT = true,
	RALT = true,
	LCTRL = true,
	RCTRL = true,
	LSHIFT = true,
	RSHIFT = true,
	UNKNOWN = true,
}

M.mouseBindingKeys = {
	LeftButton = "BUTTON1",
	RightButton = "BUTTON2",
	MiddleButton = "BUTTON3",
	Button4 = "BUTTON4",
	Button5 = "BUTTON5",
}

function M.suppressCaptureClick()
	Editor.state.suppressNextCaptureClick = true
	if _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0, function() Editor.state.suppressNextCaptureClick = nil end)
	end
end

function M.refreshDialog()
	local dialog = Editor.state.dialog
	if not (dialog and dialog.IsShown and dialog:IsShown()) then return end
	if Editor.state.dialogKind == "menu" and dialog.context then
		local menu = M.getMenu(Editor.state.dialogMenuID)
		if menu then
			dialog.context.title = menu.name
			if dialog.Title then dialog.Title:SetText(menu.name) end
			local buttons = dialog.context.buttons
			if type(buttons) == "table" and buttons[1] then
				buttons[1].text = string.format(
					"%s: %s",
					L["QuickCastSetHotkey"] or L["QuickCastHotkey"] or "Hotkey",
					M.formatBinding(menu.hotkey)
				)
			end
		end
	end
	if dialog.UpdateSettings then dialog:UpdateSettings() end
	if dialog.UpdateButtons then dialog:UpdateButtons() end
	if dialog.Layout then dialog:Layout() end
end

function M.finishRefresh(refreshDialog, editorAlreadyRefreshed)
	if not editorAlreadyRefreshed then Editor:Refresh() end
	if refreshDialog and _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0, M.refreshDialog)
	end
end

function M.refreshEditorMenuPresentation(menuID)
	local frame = Editor.frame
	local menu = M.getMenu(menuID)
	if not (frame and frame:IsShown() and menu and type(frame.categories) == "table") then return end
	for _, category in ipairs(frame.categories) do
		if category.menuID == menu.id then
			if category.Header.SetHeaderText then
				category.Header:SetHeaderText(M.truncate(menu.name, 28))
			elseif category.Header.Name then
				category.Header.Name:SetText(M.truncate(menu.name, 28))
			end
			return
		end
	end
end

function M.refreshRuntime(refreshDialog)
	QC:QueueSecureRebuild()
	M.finishRefresh(refreshDialog, false)
end

function M.refreshMenuLayout(menuID, refreshDialog)
	if QC.QueueSecureLayoutRefresh then
		QC:QueueSecureLayoutRefresh(menuID)
	else
		QC:QueueSecureRebuild()
	end
	M.refreshEditorMenuPresentation(menuID)
	M.finishRefresh(refreshDialog, true)
end

function M.refreshMenuAppearance(menuID, refreshDialog)
	local editorAlreadyRefreshed = false
	if QC.RefreshVisibleMenuAppearance then
		QC:RefreshVisibleMenuAppearance(menuID)
	elseif QC.RefreshGlobalFont then
		QC:RefreshGlobalFont()
		editorAlreadyRefreshed = true
	elseif QC.RefreshLayoutPreview then
		QC:RefreshLayoutPreview()
	end
	if not editorAlreadyRefreshed then M.refreshEditorMenuPresentation(menuID) end
	M.finishRefresh(refreshDialog, true)
end

function M.setMenuField(menuID, field, value, refreshDialog)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu or menu[field] == value then return end
	menu[field] = value
	M.refreshRuntime(refreshDialog)
end

function M.setMenuLayoutField(menuID, field, value, refreshDialog)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu or menu[field] == value then return end
	menu[field] = value
	M.refreshMenuLayout(menuID, refreshDialog)
end

function M.setMenuAppearanceField(menuID, field, value, refreshDialog)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu or menu[field] == value then return end
	menu[field] = value
	M.refreshMenuAppearance(menuID, refreshDialog)
end

function M.setMenuEditorField(menuID, field, value, refreshDialog)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu or menu[field] == value then return end
	menu[field] = value
	M.finishRefresh(refreshDialog, false)
end

function M.setMenuName(menuID, value, refreshDialog)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu or menu.name == value then return end
	menu.name = value
	local frame = Editor.frame
	local filterText = frame and frame:IsShown() and frame.searchBox and M.trim(frame.searchBox:GetText()) or ""
	if filterText ~= "" then
		Editor:Refresh()
	else
		M.refreshEditorMenuPresentation(menuID)
	end
	if QC.RefreshVisibleMenuAppearance then QC:RefreshVisibleMenuAppearance(menuID) end
	M.finishRefresh(refreshDialog, true)
end

function M.ensureConditions(action)
	action.conditions = type(action.conditions) == "table" and action.conditions or {}
	action.conditions.specs = type(action.conditions.specs) == "table" and action.conditions.specs or {}
	action.conditions.cooldown = type(action.conditions.cooldown) == "table" and action.conditions.cooldown or {}
	action.conditions.inventory = type(action.conditions.inventory) == "table" and action.conditions.inventory or {}
	return action.conditions
end

function M.hasSpecFilter(specs)
	return type(specs) == "table" and next(specs) ~= nil
end

function M.isSpecFilterOptionSelected(specs, value)
	if value == "__all" then return not M.hasSpecFilter(specs) end
	local specID = tonumber(value)
	return specID and type(specs) == "table" and specs[specID] == true or false
end

function M.setSpecFilterOptionSelected(specs, value, selected)
	specs = type(specs) == "table" and specs or {}
	if value == "__all" then
		if selected then
			for specID in pairs(specs) do specs[specID] = nil end
		end
		return specs
	end
	local specID = tonumber(value)
	if specID then specs[specID] = selected and true or nil end
	return specs
end

function M.specFilterAllows(specs, specID)
	if not M.hasSpecFilter(specs) then return true end
	specID = tonumber(specID)
	return specID and specs[specID] == true or false
end

function M.mutateAction(menuID, entryID, callback, refreshDialog)
	if not M.isEditingAllowed() then return end
	local action = M.getAction(menuID, entryID)
	if not action then return end
	callback(action)
	M.refreshRuntime(refreshDialog)
end

function M.setDefaultAction(menuID, entryID, enabled)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	local action = M.getAction(menuID, entryID)
	if not (menu and action) or action.kind == "menu" then return end
	local normalizedEntryID = tonumber(action.entryID)
	if enabled then
		menu.defaultEntryID = normalizedEntryID
	elseif menu.defaultEntryID == normalizedEntryID then
		menu.defaultEntryID = nil
	else
		return
	end
	M.refreshRuntime(false)
end

function M.stopHotkeyCapture(refresh)
	local button = Editor.state.captureButton
	Editor.state.captureButton = nil
	Editor.state.captureMenuID = nil
	if button then
		button:EnableKeyboard(false)
		if button.SetPropagateKeyboardInput then button:SetPropagateKeyboardInput(true) end
		button:SetScript("OnKeyDown", nil)
		button:SetScript("OnMouseDown", nil)
	end
	if refresh then M.refreshDialog() end
end

function M.applyHotkey(menuID, hotkey)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu then return end
	local used, menuName = QC:IsHotkeyUsedByAnother(menu.id, hotkey)
	if used then
		M.showError((L["QuickCastHotkeyConflict"] or "This key is already used by %s."):format(menuName or "?"))
		return
	end
	menu.hotkey = hotkey
	M.refreshRuntime(false)
	M.refreshDialog()
end

function M.confirmHotkey(menuID, hotkey)
	local conflict = QC:GetBindingConflict(hotkey)
	if conflict then
		_G.StaticPopup_Show(M.POPUP_REPLACE, M.formatBinding(hotkey), _G.GetBindingName(conflict) or conflict, {
			menuID = menuID,
			hotkey = hotkey,
		})
	else
		M.applyHotkey(menuID, hotkey)
	end
end

function M.captureHotkey(key)
	if not (Editor.state.captureButton and key and not M.ignoredBindingKeys[key]) then return end
	local menuID = Editor.state.captureMenuID
	local binding = M.modifierPrefix(key) .. key
	M.stopHotkeyCapture(false)
	M.confirmHotkey(menuID, binding)
end

function M.startHotkeyCapture(button, menuID)
	if not (button and menuID and M.isEditingAllowed()) then return end
	if Editor.state.suppressNextCaptureClick then
		Editor.state.suppressNextCaptureClick = nil
		return
	end
	M.stopHotkeyCapture(false)
	Editor.state.captureButton = button
	Editor.state.captureMenuID = menuID
	button:SetText(L["QuickCastPressKey"] or "Press a key…")
	button:EnableKeyboard(true)
	if button.SetPropagateKeyboardInput then button:SetPropagateKeyboardInput(false) end
	button:SetScript("OnKeyDown", function(_, key)
		if key == "ESCAPE" then
			M.stopHotkeyCapture(true)
		else
			M.captureHotkey(key)
		end
	end)
	button:SetScript("OnMouseDown", function(_, mouseButton)
		local key = M.mouseBindingKeys[mouseButton]
		if key then
			M.suppressCaptureClick()
			M.captureHotkey(key)
		end
	end)
end

function M.getSpecializationOptions()
	local options = {}
	local getSpecCount = _G.C_SpecializationInfo and _G.C_SpecializationInfo.GetNumSpecializationsForClassID
	if not (getSpecCount and _G.GetSpecializationInfoForClassID and _G.GetNumClasses) then return options end
	local sex = _G.UnitSex and _G.UnitSex("player") or nil
	for classIndex = 1, (_G.GetNumClasses() or 0) do
		local className, _, classID
		if _G.GetClassInfo then
			className, _, classID = _G.GetClassInfo(classIndex)
		elseif _G.C_CreatureInfo and _G.C_CreatureInfo.GetClassInfo then
			local classInfo = _G.C_CreatureInfo.GetClassInfo(classIndex)
			if classInfo then className, classID = classInfo.className, classInfo.classID end
		end
		if classID then
			for specIndex = 1, (getSpecCount(classID) or 0) do
				local specID, specName, _, icon = _G.GetSpecializationInfoForClassID(classID, specIndex, sex)
				if specID then
					local label = string.format("%s - %s", className or tostring(classID), specName or tostring(specID))
					options[#options + 1] = {
						value = specID,
						text = label,
						label = label,
						icon = icon,
						classID = classID,
						className = className or tostring(classID),
						specName = specName or tostring(specID),
					}
				end
			end
		end
	end
	table.sort(options, function(a, b)
		if _G.strcmputf8i then return _G.strcmputf8i(a.text, b.text) < 0 end
		return a.text:lower() < b.text:lower()
	end)
	table.insert(options, 1, {
		value = "__all",
		text = _G.ALL_SPECS or "All specializations",
		label = _G.ALL_SPECS or "All specializations",
	})
	return options
end

function M.getPlayerClassInfo()
	local className, classFile, classID = "", nil, nil
	if _G.UnitClass then className, classFile, classID = _G.UnitClass("player") end
	return className or "", classFile, classID
end

function M.getClassInfo(classID)
	classID = tonumber(classID)
	if not classID then return nil end
	if _G.C_CreatureInfo and _G.C_CreatureInfo.GetClassInfo then
		local info = _G.C_CreatureInfo.GetClassInfo(classID)
		if info then return info.className, info.classFile, classID end
	end
	if _G.GetNumClasses and _G.GetClassInfo then
		for index = 1, _G.GetNumClasses() do
			local className, classFile, currentClassID = _G.GetClassInfo(index)
			if currentClassID == classID then return className, classFile, classID end
		end
	end
	local className, classFile, playerClassID = M.getPlayerClassInfo()
	if playerClassID == classID then return className, classFile, classID end
	return nil
end

function M.getPlayerClassID()
	return select(3, M.getPlayerClassInfo())
end

function M.getSelectedClassID()
	return tonumber(Editor.state.classView) or M.getPlayerClassID()
end

function M.getClassColorText(classID, text)
	local _, classFile = M.getClassInfo(classID)
	local color = classFile and _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[classFile]
	return color and color.WrapTextInColorCode and color:WrapTextInColorCode(text) or text
end

function Editor:GetClassOptions()
	local classes = {}
	local seen = {}
	for _, option in ipairs(M.getSpecializationOptions()) do
		if option.value ~= "__all" and option.classID and not seen[option.classID] then
			seen[option.classID] = true
			classes[#classes + 1] = {
				value = option.classID,
				label = option.className,
			}
		end
	end
	table.sort(classes, function(a, b)
		if _G.strcmputf8i then return _G.strcmputf8i(a.label, b.label) < 0 end
		return tostring(a.label):lower() < tostring(b.label):lower()
	end)
	return classes
end

function Editor:GetClassSpecOptions(classID)
	local specs = {}
	classID = tonumber(classID) or M.getPlayerClassID()
	for _, option in ipairs(M.getSpecializationOptions()) do
		if option.value ~= "__all" and tonumber(option.classID) == classID then specs[#specs + 1] = option end
	end
	return specs
end

function Editor:GetPreviewSpecID()
	return tonumber(self.state.specView)
end

function Editor:GetPreviewSpecIDs()
	if self.state.specView == "ALL" then return nil end
	local specID = self:GetPreviewSpecID()
	if specID then return { [specID] = true } end
	if self.state.specView == "CLASS" then
		local specs = {}
		for _, option in ipairs(self:GetClassSpecOptions(M.getSelectedClassID())) do specs[option.value] = true end
		return specs
	end
	return nil
end

function Editor:FilterAllowsView(specs)
	if not M.hasSpecFilter(specs) or self.state.specView == "ALL" then return true end
	local viewSpecs = self:GetPreviewSpecIDs()
	if not viewSpecs then return true end
	for specID in pairs(viewSpecs) do
		if specs[specID] == true then return true end
	end
	return false
end

function Editor:MenuMatchesSpecView(menu)
	return type(menu) == "table" and self:FilterAllowsView(menu.specFilter)
end

function Editor:EnsureInitialSpecView()
	if self.state.didInitializeSpecView then return end
	self.state.didInitializeSpecView = true
	self.state.classView = M.getPlayerClassID()
	self.state.specView = QC.GetCurrentSpecID and QC:GetCurrentSpecID() or "ALL"
end

function Editor:GetSpecViewLabel()
	if self.state.specView == "ALL" then return _G.ALL_CLASSES or "All classes" end
	local classID = M.getSelectedClassID()
	local className = M.getClassInfo(classID) or M.getPlayerClassInfo()
	if self.state.specView == "CLASS" then return M.getClassColorText(classID, className) end
	for _, option in ipairs(self:GetClassSpecOptions(classID)) do
		if tostring(option.value) == tostring(self.state.specView) then return option.label end
	end
	return className or (_G.ALL_CLASSES or "All classes")
end

function Editor:SetClassView(value)
	if value == "ALL" then
		self.state.specView = "ALL"
		self.state.classView = nil
		self.state.classLocked = false
	else
		local classID = tonumber(value)
		self.state.specView = "CLASS"
		self.state.classView = classID
		self.state.classLocked = classID ~= M.getPlayerClassID()
	end
	self:Refresh()
	if self.state.layoutEdit and QC.RefreshLayoutPreview then QC:RefreshLayoutPreview() end
end

function Editor:SetClassSpecView(classID, value)
	classID = tonumber(classID) or M.getPlayerClassID()
	self.state.classView = classID
	self.state.specView = tonumber(value) or "CLASS"
	self.state.classLocked = classID ~= M.getPlayerClassID()
	self:Refresh()
	if self.state.layoutEdit and QC.RefreshLayoutPreview then QC:RefreshLayoutPreview() end
end

function Editor:SyncSpecViewToCurrentSpec()
	if self.state.classLocked or not tonumber(self.state.specView) then return false end
	local currentSpecID = QC.GetCurrentSpecID and QC:GetCurrentSpecID()
	if not currentSpecID or currentSpecID == tonumber(self.state.specView) then return false end
	self.state.classView = M.getPlayerClassID()
	self.state.specView = currentSpecID
	self:Refresh()
	if self.state.layoutEdit and QC.RefreshLayoutPreview then QC:RefreshLayoutPreview() end
	return true
end

function Editor:UpdateSpecDropdown()
	local frame = self.frame
	if not (frame and frame.SpecDropdown) then return end
	if frame.SpecDropdown.SetDefaultText then frame.SpecDropdown:SetDefaultText(self:GetSpecViewLabel()) end
	if frame.SpecDropdown.GenerateMenu then frame.SpecDropdown:GenerateMenu() end
end

function M.getAnchorText(anchor)
	if anchor == "TOPLEFT" then return L["Top Left"] or "Top Left" end
	if anchor == "TOPRIGHT" then return L["Top Right"] or "Top Right" end
	if anchor == "BOTTOMLEFT" then return L["Bottom Left"] or "Bottom Left" end
	if anchor == "BOTTOMRIGHT" then return L["Bottom Right"] or "Bottom Right" end
	if anchor == "LEFT" then return L["QuickCastPlacementLeft"] or "Left" end
	if anchor == "RIGHT" then return L["QuickCastPlacementRight"] or "Right" end
	if anchor == "TOP" then return L["QuickCastPlacementAbove"] or "Above" end
	if anchor == "BOTTOM" then return L["QuickCastPlacementBelow"] or "Below" end
	return L["QuickCastPlacementCentered"] or "Centered"
end

function M.getDirectionText(direction)
	if direction == "LEFT" then return L["QuickCastPlacementLeft"] or "Left" end
	if direction == "RIGHT" then return L["QuickCastPlacementRight"] or "Right" end
	if direction == "UP" then return L["QuickCastPlacementAbove"] or "Up" end
	return L["QuickCastPlacementBelow"] or "Down"
end

function M.isLinear(menu)
	return menu and (menu.layout == "horizontal" or menu.layout == "vertical") or false
end

function M.menuSetting(menuID, data)
	local previousDisabled = data.disabled
	data.disabled = function(...)
		if not M.isEditingAllowed() then return true end
		return previousDisabled and previousDisabled(...) == true or false
	end
	return data
end

function M.menuLabelsDisabled(menuID)
	local menu = M.getMenu(menuID)
	return not menu or menu.showLabels == false
end

function M.menuTitleVisible(menuID)
	local menu = M.getMenu(menuID)
	return menu and menu.showTitle == true or false
end

function M.menuTitleCustomColorVisible(menuID)
	local menu = M.getMenu(menuID)
	return menu and menu.showTitle == true and menu.titleUseClassColor ~= true or false
end

function M.actionSetting(menuID, entryID, data)
	local previousDisabled = data.disabled
	data.disabled = function(...)
		if not M.isEditingAllowed() then return true end
		if not M.getAction(menuID, entryID) then return true end
		return previousDisabled and previousDisabled(...) == true or false
	end
	return data
end

function M.normalizeColor(value, fallback)
	value = type(value) == "table" and value or fallback
	fallback = type(fallback) == "table" and fallback or { 1, 1, 1, 1 }
	local color = {}
	for index, key in ipairs({ "r", "g", "b", "a" }) do
		local channel = tonumber(value[index] or value[key])
		if channel == nil then channel = tonumber(fallback[index] or fallback[key]) or 1 end
		color[index] = math.max(0, math.min(1, channel))
	end
	return color
end

function M.getColorSettingValue(value, fallback)
	local color = M.normalizeColor(value, fallback)
	return { r = color[1], g = color[2], b = color[3], a = color[4] }
end

function M.getQuickCastIconShapeOptions()
	if addon.IconShape and addon.IconShape.GetOptions then
		return addon.IconShape.GetOptions(L, { exclude = { STAR = true } })
	end
	return {
		{ value = "DEFAULT", label = L["settingsIconShapeDefault"] or _G.DEFAULT or "Default" },
		{ value = "SQUARE", label = L["settingsIconShapeSquare"] or "Square" },
		{ value = "ROUND", label = L["settingsIconShapeRound"] or "Round" },
		{ value = "ROUND_STAR", label = L["settingsIconShapeRoundStar"] or "Round star" },
		{ value = "HEXAGON", label = L["settingsIconShapeHexagon"] or "Hexagon" },
		{ value = "DIAMOND", label = L["settingsIconShapeDiamond"] or "Diamond" },
	}
end

function M.getQuickCastIconBorderOptions(shape)
	if addon.IconShape and addon.IconShape.GetBorderOptions then
		return addon.IconShape.GetBorderOptions(L, shape, { includeLSM = true })
	end
	local options = {
		{ value = QC.DEFAULT_ICON_BORDER_TEXTURE, label = _G.DEFAULT or "Default" },
	}
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or {}
	for _, name in ipairs(names) do options[#options + 1] = { value = name, label = name } end
	return options
end

function M.getQuickCastFontOptions()
	local options = {}
	local seen = {}
	local functions = addon.functions
	local globalFontKey = functions and functions.GetGlobalFontConfigKey and functions.GetGlobalFontConfigKey()
	local globalFontLabel = functions and functions.GetGlobalFontConfigLabel and functions.GetGlobalFontConfigLabel()
	if type(globalFontKey) == "string" and globalFontKey ~= "" then
		seen[globalFontKey] = true
		options[#options + 1] = {
			value = globalFontKey,
			text = globalFontLabel or globalFontKey,
		}
	end
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font") or {}
	for _, name in ipairs(names) do
		if type(name) == "string" and name ~= "" and not seen[name] then
			seen[name] = true
			options[#options + 1] = { value = name, text = name }
		end
	end
	if not seen[QC.DEFAULT_LABEL_FONT] then
		options[#options + 1] = { value = QC.DEFAULT_LABEL_FONT, text = QC.DEFAULT_LABEL_FONT }
	end
	return options
end

function M.getQuickCastFontOutlineOptions()
	local source = addon.functions
		and addon.functions.GetFontStyleOptionList
		and addon.functions.GetFontStyleOptionList(true)
		or {
			{ value = "NONE", label = _G.NONE or "None" },
			{ value = "OUTLINE", label = L["Outline"] or "Outline" },
			{ value = "THICKOUTLINE", label = "Thick outline" },
			{ value = "MONOCHROME", label = "Monochrome" },
			{ value = "MONOCHROMEOUTLINE", label = "Monochrome outline" },
		}
	local options = {}
	for _, option in ipairs(source) do
		options[#options + 1] = {
			value = option.value,
			text = option.label or option.text or tostring(option.value),
		}
	end
	return options
end

function M.setQuickCastIconShape(menuID, value)
	if not M.isEditingAllowed() then return end
	local menu = M.getMenu(menuID)
	if not menu then return end
	local iconShape = addon.IconShape
	local shape = iconShape and iconShape.Normalize and iconShape.Normalize(value, QC.DEFAULT_ICON_SHAPE) or tostring(value or QC.DEFAULT_ICON_SHAPE)
	if shape == "STAR" then shape = QC.DEFAULT_ICON_SHAPE end
	menu.iconShape = shape
	if iconShape and iconShape.NormalizeBorder then
		menu.iconBorderTexture = iconShape.NormalizeBorder(
			menu.iconBorderTexture,
			QC.DEFAULT_ICON_BORDER_TEXTURE,
			shape,
			{ allowNone = true }
		)
	end
	M.refreshMenuAppearance(menuID, true)
end

function M.buildMenuSettings(menuID)
	local SettingType = addon.EditModeLib and addon.EditModeLib.SettingType
	if not SettingType then return nil end
	local settings = {
		{
			name = L["QuickCastMenuSettings"] or "Menu settings",
			kind = SettingType.Collapsible,
			id = "quickCastMenuGeneral",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = _G.NAME or "Name",
			kind = SettingType.Input,
			parentId = "quickCastMenuGeneral",
			maxChars = 48,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.name or ""
			end,
			set = function(_, value)
				value = M.trim(value)
				if value ~= "" then M.setMenuName(menuID, value, true) end
			end,
		}),
		M.menuSetting(menuID, {
			name = _G.ENABLE or "Enable",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuGeneral",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.enabled ~= false or false
			end,
			set = function(_, value) M.setMenuField(menuID, "enabled", value == true, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastShowTooltips"] or "Show tooltips",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuGeneral",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.showTooltips ~= false or false
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "showTooltips", value == true, false) end,
		}),
		{
			name = L["QuickCastTitle"] or "Title",
			kind = SettingType.Collapsible,
			id = "quickCastMenuTitle",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["QuickCastShowTitle"] or "Show menu title",
			tooltip = L["QuickCastShowTitleDesc"] or "Displays the menu name above its actions.",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuTitle",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.showTitle == true or QC.DEFAULT_SHOW_TITLE
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "showTitle", value == true, true) end,
		}),
		M.menuSetting(menuID, {
			name = L["Font"] or "Font",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuTitle",
			height = 240,
			values = M.getQuickCastFontOptions(),
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleFont or QC.DEFAULT_TITLE_FONT
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "titleFont", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["Anchor"] or "Anchor",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuTitle",
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleAnchor or QC.DEFAULT_TITLE_ANCHOR
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "titleAnchor", value, false) end,
			values = {
				{ text = L["Top"] or "Top", value = QC.TITLE_ANCHOR_TOP },
				{ text = L["Center"] or "Center", value = QC.TITLE_ANCHOR_CENTER },
				{ text = L["Bottom"] or "Bottom", value = QC.TITLE_ANCHOR_BOTTOM },
			},
		}),
		M.menuSetting(menuID, {
			name = _G.FONT_SIZE or "Font size",
			kind = SettingType.Slider,
			parentId = "quickCastMenuTitle",
			minValue = QC.MIN_TITLE_FONT_SIZE,
			maxValue = QC.MAX_TITLE_FONT_SIZE,
			valueStep = 1,
			allowInput = true,
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleFontSize or QC.DEFAULT_TITLE_FONT_SIZE
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"titleFontSize",
					M.clampInteger(value, QC.MIN_TITLE_FONT_SIZE, QC.MAX_TITLE_FONT_SIZE, QC.DEFAULT_TITLE_FONT_SIZE),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Font outline"] or L["Outline"] or "Outline",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuTitle",
			height = 160,
			values = M.getQuickCastFontOutlineOptions(),
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleFontOutline or QC.DEFAULT_TITLE_FONT_OUTLINE
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "titleFontOutline", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["Use class color"] or "Use class color",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuTitle",
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleUseClassColor == true or QC.DEFAULT_TITLE_USE_CLASS_COLOR
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "titleUseClassColor", value == true, true) end,
		}),
		M.menuSetting(menuID, {
			name = L["Font color"] or _G.COLOR or "Color",
			kind = SettingType.Color,
			parentId = "quickCastMenuTitle",
			hasOpacity = true,
			isShown = function() return M.menuTitleCustomColorVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return M.getColorSettingValue(menu and menu.titleColor, QC.DEFAULT_TITLE_COLOR)
			end,
			set = function(_, value)
				M.setMenuAppearanceField(menuID, "titleColor", M.normalizeColor(value, QC.DEFAULT_TITLE_COLOR), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Offset X"] or "Offset X",
			kind = SettingType.Slider,
			parentId = "quickCastMenuTitle",
			minValue = QC.MIN_TITLE_OFFSET,
			maxValue = QC.MAX_TITLE_OFFSET,
			valueStep = 1,
			allowInput = true,
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleOffsetX or QC.DEFAULT_TITLE_OFFSET_X
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"titleOffsetX",
					M.clampInteger(value, QC.MIN_TITLE_OFFSET, QC.MAX_TITLE_OFFSET, QC.DEFAULT_TITLE_OFFSET_X),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Offset Y"] or "Offset Y",
			kind = SettingType.Slider,
			parentId = "quickCastMenuTitle",
			minValue = QC.MIN_TITLE_OFFSET,
			maxValue = QC.MAX_TITLE_OFFSET,
			valueStep = 1,
			allowInput = true,
			isShown = function() return M.menuTitleVisible(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.titleOffsetY or QC.DEFAULT_TITLE_OFFSET_Y
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"titleOffsetY",
					M.clampInteger(value, QC.MIN_TITLE_OFFSET, QC.MAX_TITLE_OFFSET, QC.DEFAULT_TITLE_OFFSET_Y),
					false
				)
			end,
		}),
		{
			name = _G.VISIBILITY or "Visibility",
			kind = SettingType.Collapsible,
			id = "quickCastMenuVisibility",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["QuickCastSpecializations"] or _G.SPECIALIZATIONS or "Specializations",
			kind = SettingType.MultiDropdown,
			parentId = "quickCastMenuVisibility",
			customText = _G.ALL_SPECS or "All specializations",
			height = 300,
			values = M.getSpecializationOptions(),
			refreshOnSelect = false,
			get = function() return nil end,
			set = function() end,
			isSelected = function(_, value)
				local menu = M.getMenu(menuID)
				return M.isSpecFilterOptionSelected(menu and menu.specFilter, value)
			end,
			setSelected = function(_, value, selected)
				local menu = M.getMenu(menuID)
				if not menu then return end
				menu.specFilter = M.setSpecFilterOptionSelected(menu.specFilter, value, selected)
				M.refreshRuntime(false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastHideOnCooldown"] or "Hide actions while on cooldown",
			tooltip = L["QuickCastCooldownConditionHelp"],
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuVisibility",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.hideOnCooldown == true or false
			end,
			set = function(_, value) M.setMenuField(menuID, "hideOnCooldown", value == true, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastHideMissingItems"] or "Hide items not in bags",
			tooltip = L["QuickCastHideMissingItemsDesc"]
				or "Non-toy item actions are omitted when their quantity in character bags is zero. Items in the bank do not count; learned toys stay visible.",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuVisibility",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.hideMissingItems == true or false
			end,
			set = function(_, value) M.setMenuField(menuID, "hideMissingItems", value == true, false) end,
		}),
		{
			name = L["QuickCastLayout"] or "Layout",
			kind = SettingType.Collapsible,
			id = "quickCastMenuLayout",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["QuickCastShowAtCursor"] or "Show ring at cursor",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuLayout",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.showAtCursor == true or false
			end,
			set = function(_, value) M.setMenuLayoutField(menuID, "showAtCursor", value == true, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastLayout"] or "Layout",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLayout",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.layout or "radial"
			end,
			set = function(_, value)
				if value == "horizontal" or value == "vertical" then
					M.setMenuLayoutField(menuID, "layout", value, true)
				else
					M.setMenuLayoutField(menuID, "layout", "radial", true)
				end
			end,
			values = {
				{ text = L["QuickCastLayoutRadial"] or "Radial", value = "radial" },
				{ text = L["QuickCastLayoutHorizontal"] or "Horizontal", value = "horizontal" },
				{ text = L["QuickCastLayoutVertical"] or "Vertical", value = "vertical" },
			},
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastDirection"] or "Direction",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLayout",
			isShown = function() return M.isLinear(M.getMenu(menuID)) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.direction or "RIGHT"
			end,
			set = function(_, value) M.setMenuLayoutField(menuID, "direction", value, false) end,
			generator = function(_, root)
				local menu = M.getMenu(menuID)
				local directions = menu and menu.layout == "vertical" and { "UP", "DOWN" } or { "LEFT", "RIGHT" }
				for _, direction in ipairs(directions) do
					root:CreateRadio(M.getDirectionText(direction), function()
						local current = M.getMenu(menuID)
						return current and current.direction == direction
					end, function()
						M.setMenuLayoutField(menuID, "direction", direction, false)
					end)
				end
			end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastAnchor"] or L["QuickCastPlacement"] or "Anchor",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLayout",
			isShown = function() return M.isLinear(M.getMenu(menuID)) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.anchor or "CENTER"
			end,
			set = function(_, value) M.setMenuLayoutField(menuID, "anchor", value, false) end,
			values = {
				{ text = M.getAnchorText("CENTER"), value = "CENTER" },
				{ text = M.getAnchorText("LEFT"), value = "LEFT" },
				{ text = M.getAnchorText("RIGHT"), value = "RIGHT" },
				{ text = M.getAnchorText("TOP"), value = "TOP" },
				{ text = M.getAnchorText("BOTTOM"), value = "BOTTOM" },
			},
		}),
		M.menuSetting(menuID, {
			name = L["Spacing"] or "Spacing",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLayout",
			minValue = 0,
			maxValue = QC.MAX_SPACING,
			valueStep = 1,
			allowInput = true,
			isShown = function() return M.isLinear(M.getMenu(menuID)) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.spacing or QC.DEFAULT_SPACING
			end,
			set = function(_, value)
				M.setMenuLayoutField(menuID, "spacing", M.clampInteger(value, 0, QC.MAX_SPACING, QC.DEFAULT_SPACING), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastSpacingOffset"] or "Spacing offset",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLayout",
			minValue = QC.MIN_RADIAL_SPACING_OFFSET or -100,
			maxValue = QC.MAX_RADIAL_SPACING_OFFSET or 300,
			valueStep = 1,
			allowInput = true,
			isShown = function()
				local menu = M.getMenu(menuID)
				return menu and menu.layout == "radial" or false
			end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.radialSpacingOffset or QC.DEFAULT_RADIAL_SPACING_OFFSET or 0
			end,
			set = function(_, value)
				M.setMenuLayoutField(
					menuID,
					"radialSpacingOffset",
					M.clampInteger(
						value,
						QC.MIN_RADIAL_SPACING_OFFSET or -100,
						QC.MAX_RADIAL_SPACING_OFFSET or 300,
						QC.DEFAULT_RADIAL_SPACING_OFFSET or 0
					),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastOffsetX"] or "Offset X",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLayout",
			minValue = -300,
			maxValue = 300,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.offsetX or 0
			end,
			set = function(_, value)
				M.setMenuLayoutField(menuID, "offsetX", M.clampInteger(value, -300, 300, 0), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastOffsetY"] or "Offset Y",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLayout",
			minValue = -300,
			maxValue = 300,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.offsetY or 0
			end,
			set = function(_, value)
				M.setMenuLayoutField(menuID, "offsetY", M.clampInteger(value, -300, 300, 0), false)
			end,
		}),
		{
			name = L["QuickCastIconAppearance"] or L["Icon"] or "Icon appearance",
			kind = SettingType.Collapsible,
			id = "quickCastMenuIcon",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["Icon size"] or "Icon size",
			kind = SettingType.Slider,
			parentId = "quickCastMenuIcon",
			minValue = 32,
			maxValue = 64,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconSize or QC.DEFAULT_ICON_SIZE
			end,
			set = function(_, value)
				M.setMenuLayoutField(menuID, "iconSize", M.clampInteger(value, 32, 64, QC.DEFAULT_ICON_SIZE), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["settingsIconShapeLabel"] or "Icon shape",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuIcon",
			height = 180,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconShape or QC.DEFAULT_ICON_SHAPE
			end,
			set = function(_, value) M.setQuickCastIconShape(menuID, value) end,
			generator = function(_, root)
				for _, option in ipairs(M.getQuickCastIconShapeOptions()) do
					local optionValue = option.value
					root:CreateRadio(option.label, function()
						local menu = M.getMenu(menuID)
						return menu and menu.iconShape == optionValue or false
					end, function()
						M.setQuickCastIconShape(menuID, optionValue)
					end)
				end
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Icon zoom"] or "Icon zoom",
			kind = SettingType.Slider,
			parentId = "quickCastMenuIcon",
			minValue = 0,
			maxValue = 35,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconZoom or QC.DEFAULT_ICON_ZOOM
			end,
			set = function(_, value)
				M.setMenuAppearanceField(menuID, "iconZoom", M.clampInteger(value, 0, 35, QC.DEFAULT_ICON_ZOOM), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Border"] or "Border",
			kind = SettingType.CheckboxColor,
			parentId = "quickCastMenuIcon",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconBorderEnabled == true or false
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "iconBorderEnabled", value == true, true) end,
			colorDefault = M.getColorSettingValue(QC.DEFAULT_ICON_BORDER_COLOR, QC.DEFAULT_ICON_BORDER_COLOR),
			colorGet = function()
				local menu = M.getMenu(menuID)
				return M.getColorSettingValue(menu and menu.iconBorderColor, QC.DEFAULT_ICON_BORDER_COLOR)
			end,
			colorSet = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"iconBorderColor",
					M.normalizeColor(value, QC.DEFAULT_ICON_BORDER_COLOR),
					false
				)
			end,
			hasOpacity = true,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastUseItemQualityColor"] or "Use item quality color",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuIcon",
			disabled = function()
				local menu = M.getMenu(menuID)
				return not menu or menu.iconBorderEnabled ~= true
			end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconBorderUseItemQualityColor ~= false or false
			end,
			set = function(_, value)
				M.setMenuAppearanceField(menuID, "iconBorderUseItemQualityColor", value == true, false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Border texture"] or "Border texture",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuIcon",
			height = 220,
			disabled = function()
				local menu = M.getMenu(menuID)
				return not menu or menu.iconBorderEnabled ~= true
			end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconBorderTexture or QC.DEFAULT_ICON_BORDER_TEXTURE
			end,
			set = function(_, value)
				local menu = M.getMenu(menuID)
				if not menu then return end
				local iconShape = addon.IconShape
				local texture = iconShape and iconShape.NormalizeBorder
					and iconShape.NormalizeBorder(value, QC.DEFAULT_ICON_BORDER_TEXTURE, menu.iconShape, { allowNone = true })
					or value
				M.setMenuAppearanceField(menuID, "iconBorderTexture", texture, false)
			end,
			generator = function(_, root)
				local menu = M.getMenu(menuID)
				if not menu then return end
				for _, option in ipairs(M.getQuickCastIconBorderOptions(menu.iconShape)) do
					local optionValue = option.value
					root:CreateRadio(option.label, function()
						local current = M.getMenu(menuID)
						return current and current.iconBorderTexture == optionValue or false
					end, function()
						M.setMenuAppearanceField(menuID, "iconBorderTexture", optionValue, false)
					end)
				end
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Border size"] or "Border size",
			kind = SettingType.Slider,
			parentId = "quickCastMenuIcon",
			minValue = QC.MIN_ICON_BORDER_SIZE,
			maxValue = QC.MAX_ICON_BORDER_SIZE,
			valueStep = 1,
			allowInput = true,
			disabled = function()
				local menu = M.getMenu(menuID)
				return not menu or menu.iconBorderEnabled ~= true
			end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconBorderSize or QC.DEFAULT_ICON_BORDER_SIZE
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"iconBorderSize",
					M.clampInteger(value, QC.MIN_ICON_BORDER_SIZE, QC.MAX_ICON_BORDER_SIZE, QC.DEFAULT_ICON_BORDER_SIZE),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Border offset"] or "Border offset",
			kind = SettingType.Slider,
			parentId = "quickCastMenuIcon",
			minValue = QC.MIN_ICON_BORDER_OFFSET,
			maxValue = QC.MAX_ICON_BORDER_OFFSET,
			valueStep = 1,
			allowInput = true,
			disabled = function()
				local menu = M.getMenu(menuID)
				return not menu or menu.iconBorderEnabled ~= true
			end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.iconBorderOffset or QC.DEFAULT_ICON_BORDER_OFFSET
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"iconBorderOffset",
					M.clampInteger(value, QC.MIN_ICON_BORDER_OFFSET, QC.MAX_ICON_BORDER_OFFSET, QC.DEFAULT_ICON_BORDER_OFFSET),
					false
				)
			end,
		}),
		{
			name = L["QuickCastCountsCharges"] or "Counts & charges",
			kind = SettingType.Collapsible,
			id = "quickCastMenuCounts",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["Font"] or "Font",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuCounts",
			height = 240,
			values = M.getQuickCastFontOptions(),
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countFont or QC.DEFAULT_COUNT_FONT
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "countFont", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = _G.FONT_SIZE or "Font size",
			kind = SettingType.Slider,
			parentId = "quickCastMenuCounts",
			minValue = 6,
			maxValue = 32,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countFontSize or QC.DEFAULT_COUNT_FONT_SIZE
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"countFontSize",
					M.clampInteger(value, 6, 32, QC.DEFAULT_COUNT_FONT_SIZE),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Font outline"] or L["Outline"] or "Outline",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuCounts",
			height = 160,
			values = M.getQuickCastFontOutlineOptions(),
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countFontOutline or QC.DEFAULT_COUNT_FONT_OUTLINE
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "countFontOutline", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["Font color"] or _G.COLOR or "Color",
			kind = SettingType.Color,
			parentId = "quickCastMenuCounts",
			hasOpacity = true,
			get = function()
				local menu = M.getMenu(menuID)
				return M.getColorSettingValue(menu and menu.countColor, QC.DEFAULT_COUNT_COLOR)
			end,
			set = function(_, value)
				M.setMenuAppearanceField(menuID, "countColor", M.normalizeColor(value, QC.DEFAULT_COUNT_COLOR), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Anchor"] or "Anchor",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuCounts",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countAnchor or QC.DEFAULT_COUNT_ANCHOR
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "countAnchor", value, false) end,
			values = {
				{ text = M.getAnchorText("TOPLEFT"), value = "TOPLEFT" },
				{ text = M.getAnchorText("TOP"), value = "TOP" },
				{ text = M.getAnchorText("TOPRIGHT"), value = "TOPRIGHT" },
				{ text = M.getAnchorText("LEFT"), value = "LEFT" },
				{ text = M.getAnchorText("CENTER"), value = "CENTER" },
				{ text = M.getAnchorText("RIGHT"), value = "RIGHT" },
				{ text = M.getAnchorText("BOTTOMLEFT"), value = "BOTTOMLEFT" },
				{ text = M.getAnchorText("BOTTOM"), value = "BOTTOM" },
				{ text = M.getAnchorText("BOTTOMRIGHT"), value = "BOTTOMRIGHT" },
			},
		}),
		M.menuSetting(menuID, {
			name = L["Offset X"] or "Offset X",
			kind = SettingType.Slider,
			parentId = "quickCastMenuCounts",
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countOffsetX or QC.DEFAULT_COUNT_OFFSET_X
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"countOffsetX",
					M.clampInteger(value, -100, 100, QC.DEFAULT_COUNT_OFFSET_X),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Offset Y"] or "Offset Y",
			kind = SettingType.Slider,
			parentId = "quickCastMenuCounts",
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			allowInput = true,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.countOffsetY or QC.DEFAULT_COUNT_OFFSET_Y
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"countOffsetY",
					M.clampInteger(value, -100, 100, QC.DEFAULT_COUNT_OFFSET_Y),
					false
				)
			end,
		}),
		{
			name = L["QuickCastLabels"] or "Labels",
			kind = SettingType.Collapsible,
			id = "quickCastMenuLabels",
			defaultCollapsed = false,
		},
		M.menuSetting(menuID, {
			name = L["QuickCastShowLabels"] or "Show labels",
			kind = SettingType.Checkbox,
			parentId = "quickCastMenuLabels",
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.showLabels ~= false or false
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "showLabels", value == true, true) end,
		}),
		M.menuSetting(menuID, {
			name = L["QuickCastLabelCharacterLimit"] or "Label character limit",
			tooltip = L["QuickCastLabelCharacterLimitDesc"] or "Limits labels to this many characters. Set to 0 for no limit.",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLabels",
			minValue = 0,
			maxValue = QC.MAX_LABEL_CHARACTER_LIMIT,
			valueStep = 1,
			allowInput = true,
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelCharacterLimit or QC.DEFAULT_LABEL_CHARACTER_LIMIT
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"labelCharacterLimit",
					M.clampInteger(value, 0, QC.MAX_LABEL_CHARACTER_LIMIT, QC.DEFAULT_LABEL_CHARACTER_LIMIT),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Font"] or "Font",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLabels",
			height = 240,
			values = M.getQuickCastFontOptions(),
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelFont or QC.DEFAULT_LABEL_FONT
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "labelFont", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = _G.FONT_SIZE or "Font size",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLabels",
			minValue = 8,
			maxValue = 28,
			valueStep = 1,
			allowInput = true,
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelFontSize or QC.DEFAULT_LABEL_FONT_SIZE
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"labelFontSize",
					M.clampInteger(value, 8, 28, QC.DEFAULT_LABEL_FONT_SIZE),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Font outline"] or L["Outline"] or "Outline",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLabels",
			height = 160,
			values = M.getQuickCastFontOutlineOptions(),
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelFontOutline or QC.DEFAULT_LABEL_FONT_OUTLINE
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "labelFontOutline", value, false) end,
		}),
		M.menuSetting(menuID, {
			name = L["Font color"] or _G.COLOR or "Color",
			kind = SettingType.Color,
			parentId = "quickCastMenuLabels",
			hasOpacity = true,
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return M.getColorSettingValue(menu and menu.labelColor, QC.DEFAULT_LABEL_COLOR)
			end,
			set = function(_, value)
				M.setMenuAppearanceField(menuID, "labelColor", M.normalizeColor(value, QC.DEFAULT_LABEL_COLOR), false)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Anchor"] or "Anchor",
			kind = SettingType.Dropdown,
			parentId = "quickCastMenuLabels",
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelAnchor or QC.DEFAULT_LABEL_ANCHOR
			end,
			set = function(_, value) M.setMenuAppearanceField(menuID, "labelAnchor", value, false) end,
			values = {
				{ text = M.getAnchorText("TOP"), value = "TOP" },
				{ text = M.getAnchorText("BOTTOM"), value = "BOTTOM" },
				{ text = M.getAnchorText("LEFT"), value = "LEFT" },
				{ text = M.getAnchorText("RIGHT"), value = "RIGHT" },
				{ text = M.getAnchorText("CENTER"), value = "CENTER" },
			},
		}),
		M.menuSetting(menuID, {
			name = L["Offset X"] or "Offset X",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLabels",
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			allowInput = true,
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelOffsetX or QC.DEFAULT_LABEL_OFFSET_X
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"labelOffsetX",
					M.clampInteger(value, -100, 100, QC.DEFAULT_LABEL_OFFSET_X),
					false
				)
			end,
		}),
		M.menuSetting(menuID, {
			name = L["Offset Y"] or "Offset Y",
			kind = SettingType.Slider,
			parentId = "quickCastMenuLabels",
			minValue = -100,
			maxValue = 100,
			valueStep = 1,
			allowInput = true,
			disabled = function() return M.menuLabelsDisabled(menuID) end,
			get = function()
				local menu = M.getMenu(menuID)
				return menu and menu.labelOffsetY or QC.DEFAULT_LABEL_OFFSET_Y
			end,
			set = function(_, value)
				M.setMenuAppearanceField(
					menuID,
					"labelOffsetY",
					M.clampInteger(value, -100, 100, QC.DEFAULT_LABEL_OFFSET_Y),
					false
				)
			end,
		}),
	}
	return settings
end

function M.buildEntrySettings(menuID, entryID)
	local SettingType = addon.EditModeLib and addon.EditModeLib.SettingType
	if not SettingType then return nil end
	local settings = {
		{
			name = L["QuickCastActionSettings"] or "Action settings",
			kind = SettingType.Collapsible,
			id = "quickCastActionGeneral",
			defaultCollapsed = false,
		},
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastActionEnabled"] or _G.ENABLE or "Enable",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionGeneral",
			get = function()
				local action = M.getAction(menuID, entryID)
				return action and action.enabled ~= false or false
			end,
			set = function(_, value)
				M.mutateAction(menuID, entryID, function(action) action.enabled = value == true end, false)
			end,
		}),
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastDefaultAction"] or "Default action",
			tooltip = L["QuickCastDefaultActionDesc"]
				or "Use this action when the menu is confirmed without moving outside the neutral center.",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionGeneral",
			isShown = function()
				local action = M.getAction(menuID, entryID)
				return action and action.kind ~= "menu" or false
			end,
			get = function()
				local action, _, menu = M.getAction(menuID, entryID)
				return action and action.kind ~= "menu" and menu and menu.defaultEntryID == action.entryID or false
			end,
			set = function(_, value) M.setDefaultAction(menuID, entryID, value == true) end,
		}),
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastLabelMode"] or "Label",
			kind = SettingType.Dropdown,
			parentId = "quickCastActionGeneral",
			get = function()
				local action = M.getAction(menuID, entryID)
				if not action or action.showLabel == nil then return "inherit" end
				return action.showLabel and "show" or "hide"
			end,
			set = function(_, value)
				M.mutateAction(menuID, entryID, function(action)
					action.showLabel = value == "show" and true or value == "hide" and false or nil
				end, false)
			end,
			values = {
				{ text = L["QuickCastLabelInherit"] or "Inherit", value = "inherit" },
				{ text = L["QuickCastLabelShow"] or "Show", value = "show" },
				{ text = L["QuickCastLabelHide"] or "Hide", value = "hide" },
			},
		}),
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastCustomLabel"] or "Custom label",
			kind = SettingType.Input,
			parentId = "quickCastActionGeneral",
			maxChars = 48,
			get = function()
				local action = M.getAction(menuID, entryID)
				return action and action.customLabel or ""
			end,
			set = function(_, value)
				M.mutateAction(menuID, entryID, function(action)
					value = M.trim(value)
					action.customLabel = value ~= "" and value or nil
				end, false)
			end,
		}),
		{
			name = _G.VISIBILITY or "Visibility",
			kind = SettingType.Collapsible,
			id = "quickCastActionVisibility",
			defaultCollapsed = false,
		},
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastSpecializations"] or _G.SPECIALIZATIONS or "Specializations",
			kind = SettingType.MultiDropdown,
			parentId = "quickCastActionVisibility",
			customText = _G.ALL_SPECS or "All specializations",
			height = 300,
			values = M.getSpecializationOptions(),
			refreshOnSelect = false,
			get = function() return nil end,
			set = function() end,
			isSelected = function(_, specID)
				local action = M.getAction(menuID, entryID)
				local conditions = action and action.conditions
				return M.isSpecFilterOptionSelected(conditions and conditions.specs, specID)
			end,
			setSelected = function(_, specID, selected)
				M.mutateAction(menuID, entryID, function(action)
					local conditions = M.ensureConditions(action)
					conditions.specs = M.setSpecFilterOptionSelected(conditions.specs, specID, selected)
				end, false)
			end,
		}),
		{
			name = L["QuickCastItemAvailability"] or "Item availability",
			kind = SettingType.Collapsible,
			id = "quickCastActionInventory",
			defaultCollapsed = true,
			isShown = function()
				local action = M.getAction(menuID, entryID)
				return action and action.kind == "item" and not QC:IsOwnedToyAction(action) or false
			end,
		},
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastOverrideMenuSetting"] or "Override menu setting",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionInventory",
			isShown = function()
				local action = M.getAction(menuID, entryID)
				return action and action.kind == "item" and not QC:IsOwnedToyAction(action) or false
			end,
			get = function()
				local action = M.getAction(menuID, entryID)
				return action
					and action.conditions
					and action.conditions.inventory
					and action.conditions.inventory.useMenu == false
					or false
			end,
			set = function(_, value)
				local action = M.getAction(menuID, entryID)
				local effective = QC:GetEffectiveHideMissingItems(M.getMenu(menuID), action)
				M.mutateAction(menuID, entryID, function(current)
					local inventory = M.ensureConditions(current).inventory
					inventory.useMenu = value ~= true
					if value == true then inventory.enabled = effective == true end
				end, false)
			end,
		}),
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastHideMissingItems"] or "Hide items not in bags",
			tooltip = L["QuickCastHideMissingItemsDesc"]
				or "Non-toy item actions are omitted when their quantity in character bags is zero. Items in the bank do not count; learned toys stay visible.",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionInventory",
			isShown = function()
				local action = M.getAction(menuID, entryID)
				return action and action.kind == "item" and not QC:IsOwnedToyAction(action) or false
			end,
			disabled = function()
				local action = M.getAction(menuID, entryID)
				return not (
					action
					and action.conditions
					and action.conditions.inventory
					and action.conditions.inventory.useMenu == false
				)
			end,
			get = function()
				local action = M.getAction(menuID, entryID)
				return QC:GetEffectiveHideMissingItems(M.getMenu(menuID), action)
			end,
			set = function(_, value)
				M.mutateAction(menuID, entryID, function(action)
					M.ensureConditions(action).inventory.enabled = value == true
				end, false)
			end,
		}),
		{
			name = L["QuickCastCooldownCondition"] or "Cooldown condition",
			kind = SettingType.Collapsible,
			id = "quickCastActionCooldown",
			defaultCollapsed = true,
		},
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastOverrideMenuSetting"] or "Override menu setting",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionCooldown",
			get = function()
				local action = M.getAction(menuID, entryID)
				return action
					and action.conditions
					and action.conditions.cooldown
					and action.conditions.cooldown.useMenu == false
					or false
			end,
			set = function(_, value)
				local action = M.getAction(menuID, entryID)
				local effective = QC:GetEffectiveHideOnCooldown(M.getMenu(menuID), action)
				M.mutateAction(menuID, entryID, function(current)
					local cooldown = M.ensureConditions(current).cooldown
					cooldown.useMenu = value ~= true
					if value == true then cooldown.enabled = effective == true end
				end, false)
			end,
		}),
		M.actionSetting(menuID, entryID, {
			name = L["QuickCastCooldownCondition"] or "Hide while on cooldown",
			tooltip = L["QuickCastCooldownConditionHelp"]
				or "The action is omitted while its own cooldown is active. Secret cooldown state is applied after combat.",
			kind = SettingType.Checkbox,
			parentId = "quickCastActionCooldown",
			disabled = function()
				local action = M.getAction(menuID, entryID)
				return not (
					action
					and action.conditions
					and action.conditions.cooldown
					and action.conditions.cooldown.useMenu == false
				)
			end,
			get = function()
				local action = M.getAction(menuID, entryID)
				return QC:GetEffectiveHideOnCooldown(M.getMenu(menuID), action)
			end,
			set = function(_, value)
				M.mutateAction(menuID, entryID, function(action)
					M.ensureConditions(action).cooldown.enabled = value == true
				end, false)
			end,
		}),
	}
	return settings
end

function M.getDialogPosition()
	return {
		point = "TOPLEFT",
		relativePoint = "TOPRIGHT",
		relativeTo = Editor.frame,
		x = 58,
		y = -8,
	}
end

function M.showStandalone(title, settings, buttons, kind, menuID, entryID)
	local lib = addon.EditModeLib
	local frame = Editor.frame
	if not (lib and lib.ShowStandaloneSettingsDialog and frame and settings) then return nil end
	M.stopHotkeyCapture(false)
	local pos = M.getDialogPosition()
	local dialog
	dialog = lib:ShowStandaloneSettingsDialog(frame, {
		title = title,
		settings = settings,
		buttons = buttons,
		showReset = false,
		showSettingsReset = false,
		settingsMaxHeight = 500,
		point = pos.point,
		relativePoint = pos.relativePoint,
		relativeTo = pos.relativeTo,
		x = pos.x,
		y = pos.y,
		onHide = function()
			M.stopHotkeyCapture(false)
			local ownsDialog = Editor.state.dialog == dialog
				and Editor.state.dialogKind == kind
				and Editor.state.dialogMenuID == menuID
				and Editor.state.dialogEntryID == entryID
			if ownsDialog and (kind == "menu" or kind == "entry") then Editor:SetLayoutEditEnabled(false) end
			if not ownsDialog then return end
			Editor.state.dialog = nil
			Editor.state.dialogKind = nil
			Editor.state.dialogMenuID = nil
			Editor.state.dialogEntryID = nil
		end,
	})
	if dialog then
		Editor.state.dialog = dialog
		Editor.state.dialogKind = kind
		Editor.state.dialogMenuID = menuID
		Editor.state.dialogEntryID = entryID
	end
	return dialog
end

function M.openMenuSettings(menuID)
	local menu = M.getMenu(menuID)
	if not menu then return end
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = nil
	if Editor.state.layoutEdit and QC.ShowLayoutPreview then QC:ShowLayoutPreview(menuID) end
	local buttons = {
		{
			text = string.format("%s: %s", L["QuickCastSetHotkey"] or L["QuickCastHotkey"] or "Hotkey", M.formatBinding(menu.hotkey)),
			layout = "compact",
			click = function(button) M.startHotkeyCapture(button, menuID) end,
		},
		{
			text = _G.CLEAR or "Clear",
			layout = "compact",
			click = function() M.applyHotkey(menuID, nil) end,
		},
		{
			text = L["QuickCastMacroCommand"] or "Macro command",
			layout = "compact",
			click = function() M.showMenuMacroPopup(menuID) end,
		},
	}
	M.showStandalone(menu.name, M.buildMenuSettings(menuID), buttons, "menu", menuID)
	Editor:Refresh()
end

function M.ensureMenuMacroPopup()
	if _G.StaticPopupDialogs[M.POPUP_MACRO_COMMAND] then return end
	_G.StaticPopupDialogs[M.POPUP_MACRO_COMMAND] = {
		text = L["QuickCastMacroCommandHelp"] or "Copy this command into a macro. The macro opens this QuickActions menu.",
		button1 = _G.CLOSE,
		hasEditBox = true,
		editBoxWidth = 320,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnShow = function(popup)
			popup:SetFrameStrata("TOOLTIP")
			local editBox = popup.editBox or popup:GetEditBox()
			local macroText = popup.data and popup.data.macroText or ""
			if editBox then
				editBox:SetNumeric(false)
				editBox:SetText(macroText)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:HighlightText()
		end,
	}
end

function M.showMenuMacroPopup(menuID)
	local macroText = QC.GetMenuMacroText and QC:GetMenuMacroText(menuID)
	if not macroText then return false end
	M.ensureMenuMacroPopup()
	_G.StaticPopup_Show(M.POPUP_MACRO_COMMAND, nil, nil, { macroText = macroText })
	return true
end

function M.editMenu(menuID)
	if not M.getMenu(menuID) then return end
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = nil
	Editor:SetLayoutEditEnabled(true)
	M.openMenuSettings(menuID)
end

function M.removeAction(menuID, entryID)
	if not M.isEditingAllowed() then return end
	local iconPicker = Editor.iconPicker
	if iconPicker and iconPicker:IsShown() and iconPicker.menuID == menuID and iconPicker.entryID == entryID then iconPicker:Hide() end
	local index = M.getActionIndex(menuID, entryID)
	if not index or not QC:RemoveAction(menuID, index) then return end
	if Editor.state.selectedEntryID == entryID then Editor.state.selectedEntryID = nil end
	if addon.EditModeLib and addon.EditModeLib.HideStandaloneSettingsDialog and Editor.frame then
		addon.EditModeLib:HideStandaloneSettingsDialog(Editor.frame)
	end
	M.refreshRuntime(false)
end

function M.openEntrySettings(menuID, entryID)
	local action, _, menu = M.getAction(menuID, entryID)
	if not (action and menu) then return end
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = entryID
	local name = M.getActionName(action)
	local buttons = {
		{
			text = _G.MACRO_POPUP_CHOOSE_ICON or L["FocusInterruptTrackerCustomIcon"] or "Choose an icon",
			layout = "compact",
			click = function() M.openIconPicker(menuID, entryID) end,
		},
		{
			text = _G.RESET or "Reset",
			layout = "compact",
			click = function() M.resetCustomIcon(menuID, entryID) end,
		},
		{
			text = L["QuickCastRemoveAction"] or _G.REMOVE or "Remove action",
			click = function() M.removeAction(menuID, entryID) end,
		},
	}
	M.showStandalone(name, M.buildEntrySettings(menuID, entryID), buttons, "entry", menuID, entryID)
	Editor:SetLayoutEditEnabled(true)
	Editor:Refresh()
end

function M.addActionByID(menuID, kind, value)
	if not M.isEditingAllowed() then return false end
	local menu = M.getMenu(menuID)
	local id = tonumber(value)
	id = id and id > 0 and math.floor(id) or nil
	if not (menu and id and (kind == "spell" or kind == "item")) then
		M.showError(L["QuickCastActionInvalid"] or "This action is not supported.")
		return false
	end

	local action
	if kind == "spell" then
		local spellInfo = _G.C_Spell and _G.C_Spell.GetSpellInfo and _G.C_Spell.GetSpellInfo(id)
		if not spellInfo and _G.GetSpellInfo then spellInfo = _G.GetSpellInfo(id) end
		if not spellInfo then
			M.showError(L["CooldownPanelSpellInvalid"] or "Spell does not exist.")
			return false
		end
		action = M.resolveSpellAction(id)
	else
		local itemID = _G.C_Item and _G.C_Item.GetItemInfoInstant and _G.C_Item.GetItemInfoInstant(id)
		if not itemID then
			M.showError(L["Item id does not exist"] or "Item ID does not exist.")
			return false
		end
		action = { kind = "item", id = itemID }
	end

	local targetIndex = #menu.actions + 1
	if not action or not QC:SetAction(menu.id, nil, action) then
		M.showError(L["QuickCastActionInvalid"] or "This action is not supported.")
		return false
	end
	menu = M.getMenu(menuID)
	local storedAction = menu and menu.actions[targetIndex]
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = M.getEntryID(storedAction, targetIndex)
	M.refreshRuntime(false)
	return true
end

function M.ensureAddByIDPopup()
	if _G.StaticPopupDialogs[M.POPUP_ADD_BY_ID] then return end
	_G.StaticPopupDialogs[M.POPUP_ADD_BY_ID] = {
		text = "%s",
		button1 = _G.ADD or _G.OKAY,
		button2 = _G.CANCEL,
		hasEditBox = true,
		editBoxWidth = 160,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnShow = function(popup)
			popup:SetFrameStrata("TOOLTIP")
			local editBox = popup.editBox or popup:GetEditBox()
			if editBox then
				editBox:SetText("")
				editBox:SetNumeric(true)
				editBox:SetFocus()
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			local popup = editBox:GetParent()
			if popup and popup.button1 then popup.button1:Click() end
		end,
		OnAccept = function(popup, data)
			local editBox = popup.editBox or popup:GetEditBox()
			M.addActionByID(data and data.menuID, data and data.kind, editBox and editBox:GetText())
		end,
	}
end

function M.showAddByIDPopup(menuID, kind)
	if not M.isEditingAllowed() or not M.getMenu(menuID) then return false end
	if kind ~= "spell" and kind ~= "item" then return false end
	M.ensureAddByIDPopup()
	local label = kind == "item"
		and (L["CooldownPanelAddItemID"] or "Add Item ID")
		or (L["CooldownPanelAddSpellID"] or "Add Spell ID")
	_G.StaticPopup_Show(M.POPUP_ADD_BY_ID, label, nil, {
		menuID = menuID,
		kind = kind,
	})
	return true
end

function M.acceptCursorAction(menuID, index)
	if not M.isEditingAllowed() then return false end
	local menu = M.getMenu(menuID)
	local action = M.resolveCursorAction()
	if not (menu and action) then
		M.showError(L["QuickCastActionInvalid"] or "This cursor action is not supported.")
		return false
	end
	local targetIndex = index or (#menu.actions + 1)
	if not QC:SetAction(menu.id, index, action) then return false end
	_G.ClearCursor()
	menu = M.getMenu(menuID)
	local storedAction = menu and menu.actions[targetIndex]
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = M.getEntryID(storedAction, targetIndex)
	M.refreshRuntime(false)
	return true
end

function M.handleExternalCursorDrop(menuID, suppressMouseUp)
	if not _G.GetCursorInfo() then return false end
	local accepted = M.acceptCursorAction(menuID)
	if accepted and suppressMouseUp then M.suppressTileMouseUp("LeftButton") end
	return accepted
end

function M.duplicateMenu(menuID)
	if not M.isEditingAllowed() then return end
	local source = M.getMenu(menuID)
	if not source then return end
	local copiedMenu = M.copy(source)
	local defaultActionIndex = source.defaultEntryID and M.getActionIndex(menuID, source.defaultEntryID) or nil
	local duplicate, reason = QC:CreateMenu()
	if not duplicate then
		if reason == "limit" then M.showError(L["QuickCastMenuLimitReached"] or "The QuickActions menu limit has been reached.") end
		return
	end
	local duplicateID = duplicate.id
	copiedMenu.id = duplicateID
	copiedMenu.name = string.format("%s %s", source.name, _G.COPY or "Copy")
	copiedMenu.hotkey = nil
	copiedMenu.nextEntryID = 1
	copiedMenu.actions = type(copiedMenu.actions) == "table" and copiedMenu.actions or {}
	for _, action in ipairs(copiedMenu.actions) do action.entryID = nil end
	local config = QC:GetConfig()
	config.menus[duplicateID] = copiedMenu
	QC:Normalize()
	duplicate = M.getMenu(duplicateID)
	duplicate.defaultEntryID = defaultActionIndex and duplicate.actions[defaultActionIndex] and duplicate.actions[defaultActionIndex].entryID or nil
	Editor.state.selectedMenuID = duplicate.id
	Editor.state.selectedEntryID = nil
	Editor.state.collapsed[duplicate.id] = false
	M.refreshRuntime(false)
	M.editMenu(duplicate.id)
end

function M.requestDeleteMenu(menuID)
	local menu = M.getMenu(menuID)
	if menu and M.isEditingAllowed() then _G.StaticPopup_Show(M.POPUP_DELETE, menu.name, nil, { menuID = menuID }) end
end

function M.showMenuContext(owner, menuID)
	local menu = M.getMenu(menuID)
	if not (menu and _G.MenuUtil and _G.MenuUtil.CreateContextMenu) then return end
	_G.MenuUtil.CreateContextMenu(owner, function(_, root)
		root:SetTag("MENU_EQOL_QUICKCAST_MENU")
		root:CreateTitle(menu.name)
		root:CreateCheckbox(_G.ENABLE or "Enable", function()
			local current = M.getMenu(menuID)
			return current and current.enabled ~= false or false
		end, function()
			local current = M.getMenu(menuID)
			if current then M.setMenuField(menuID, "enabled", current.enabled == false, false) end
		end)
		root:CreateCheckbox(L["QuickCastHideOtherSpecializations"] or "Hide actions for other specializations", function()
			local current = M.getMenu(menuID)
			return current and current.hideOtherSpecs == true or false
		end, function()
			local current = M.getMenu(menuID)
			if current then M.setMenuEditorField(menuID, "hideOtherSpecs", current.hideOtherSpecs ~= true, false) end
		end)
		root:CreateButton(L["QuickCastMenuSettings"] or _G.EDIT or "Edit", function() M.editMenu(menuID) end)
		root:CreateButton(L["QuickCastDuplicateMenu"] or _G.DUPLICATE or "Duplicate", function() M.duplicateMenu(menuID) end)
		root:CreateDivider()
		root:CreateButton(_G.DELETE or "Delete", function() M.requestDeleteMenu(menuID) end)
	end)
end

function M.showActionContext(owner, menuID, entryID)
	local action = M.getAction(menuID, entryID)
	if not (action and _G.MenuUtil and _G.MenuUtil.CreateContextMenu) then return end
	local name = M.getActionName(action)
	_G.MenuUtil.CreateContextMenu(owner, function(_, root)
		root:SetTag("MENU_EQOL_QUICKCAST_ACTION")
		root:CreateTitle(name)
		root:CreateButton(action.enabled == false and (_G.ENABLE or "Enable") or (_G.DISABLE or "Disable"), function()
			M.mutateAction(menuID, entryID, function(current) current.enabled = current.enabled == false end, false)
		end)
		if action.kind ~= "menu" then
			root:CreateCheckbox(L["QuickCastDefaultAction"] or "Default action", function()
				local current, _, menu = M.getAction(menuID, entryID)
				return current and menu and menu.defaultEntryID == current.entryID or false
			end, function()
				local current, _, menu = M.getAction(menuID, entryID)
				if current and menu then M.setDefaultAction(menuID, entryID, menu.defaultEntryID ~= current.entryID) end
			end)
		end
		root:CreateButton(L["QuickCastActionSettings"] or _G.EDIT or "Edit", function() M.openEntrySettings(menuID, entryID) end)
		root:CreateDivider()
		root:CreateButton(L["QuickCastRemoveAction"] or _G.REMOVE or "Remove", function() M.removeAction(menuID, entryID) end)
	end)
end

function M.setManagedSource(menuID, source, enabled)
	if not M.isEditingAllowed() then return false end
	local ok = QC:SetManagedSource(menuID, source, enabled)
	if not ok then return false end
	if Editor.state.selectedMenuID == menuID and Editor.state.selectedEntryID and not M.getAction(menuID, Editor.state.selectedEntryID) then
		Editor.state.selectedEntryID = nil
	end
	M.refreshRuntime(false)
	return true
end

function M.addEQOLAction(menuID, actionID)
	if not M.isEditingAllowed() then return false end
	local ok = QC:AddEQOLAction(menuID, actionID)
	if not ok then return false end
	local menu = M.getMenu(menuID)
	for index, action in ipairs(menu and menu.actions or {}) do
		if action.kind == "eqol" and action.id == actionID then
			Editor.state.selectedMenuID = menuID
			Editor.state.selectedEntryID = M.getEntryID(action, index)
			break
		end
	end
	M.refreshRuntime(false)
	return true
end

function M.addMenuAction(menuID, childMenuID)
	if not M.isEditingAllowed() then return false end
	local menu = M.getMenu(menuID)
	local childMenu = M.getMenu(childMenuID)
	if not (menu and childMenu) or QC:WouldCreateMenuCycle(menuID, childMenuID) then
		M.showError(L["QuickCastActionInvalid"] or "This action is not supported.")
		return false
	end
	local targetIndex = #menu.actions + 1
	if not QC:SetAction(menuID, nil, { kind = "menu", id = childMenuID }) then return false end
	menu = M.getMenu(menuID)
	local storedAction = menu and menu.actions[targetIndex]
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = M.getEntryID(storedAction, targetIndex)
	M.refreshRuntime(false)
	return true
end

function M.addMarkerPreset(menuID, kind)
	if not M.isEditingAllowed() or (kind ~= "worldmarker" and kind ~= "raidtarget") then return false end
	local menu = M.getMenu(menuID)
	if not menu then return false end
	local existing = {}
	for _, action in ipairs(menu.actions or {}) do
		if action.kind == kind and tonumber(action.id) then existing[tonumber(action.id)] = true end
	end
	local markerOrder = kind == "worldmarker" and { 8, 4, 1, 7, 2, 3, 6, 5, 0 } or { 1, 2, 3, 4, 5, 6, 7, 8 }
	local added = 0
	for _, markerID in ipairs(markerOrder) do
		if not existing[markerID] then
			menu.actions[#menu.actions + 1] = { kind = kind, id = markerID }
			existing[markerID] = true
			added = added + 1
		end
	end
	if added < 1 then return true end
	QC:Normalize()
	M.refreshRuntime(false)
	return true
end

function M.getOutfitActions()
	local outfitAPI = _G.C_TransmogOutfitInfo
	if not (outfitAPI and outfitAPI.GetOutfitsInfo) then return {} end
	local outfitsInfo = outfitAPI.GetOutfitsInfo()
	if type(outfitsInfo) ~= "table" or (_G.issecrettable and _G.issecrettable(outfitsInfo)) then return {} end
	local actions = {}
	local seenOutfitIDs = {}
	for _, outfitInfo in ipairs(outfitsInfo) do
		if type(outfitInfo) == "table" and not (_G.issecrettable and _G.issecrettable(outfitInfo)) then
			local outfitID = outfitInfo.outfitID
			if not (_G.issecretvalue and _G.issecretvalue(outfitID)) then
				local action = M.resolveOutfitAction(outfitID)
				if action and not seenOutfitIDs[action.id] then
					seenOutfitIDs[action.id] = true
					actions[#actions + 1] = action
				end
			end
		end
	end
	table.sort(actions, function(left, right)
		if left.name ~= right.name then return left.name < right.name end
		return left.id < right.id
	end)
	return actions
end

function M.addOutfitAction(menuID, outfitID)
	if not M.isEditingAllowed() then return false end
	local menu = M.getMenu(menuID)
	local action = M.resolveOutfitAction(outfitID)
	if not (menu and action) then
		M.showError(L["QuickCastActionInvalid"] or "This action is not supported.")
		return false
	end
	local targetIndex = #menu.actions + 1
	if not QC:SetAction(menu.id, nil, action) then
		M.showError(L["QuickCastActionInvalid"] or "This action is not supported.")
		return false
	end
	menu = M.getMenu(menuID)
	local storedAction = menu and menu.actions[targetIndex]
	Editor.state.selectedMenuID = menuID
	Editor.state.selectedEntryID = M.getEntryID(storedAction, targetIndex)
	M.refreshRuntime(false)
	return true
end

function M.appendProfessionAction(actions, seenSpellIDs, spellID, spellName)
	if
		not (_G.issecretvalue and _G.issecretvalue(spellID))
		and type(spellID) == "number"
		and spellID > 0
		and not seenSpellIDs[spellID]
	then
		if spellName == nil and _G.C_Spell and _G.C_Spell.GetSpellInfo then
			local spellInfo = _G.C_Spell.GetSpellInfo(spellID)
			local spellInfoIsSecret = spellInfo and _G.issecrettable and _G.issecrettable(spellInfo)
			if spellInfo and not spellInfoIsSecret then spellName = spellInfo.name end
		end
		if
			not (_G.issecretvalue and _G.issecretvalue(spellName))
			and type(spellName) == "string"
			and spellName ~= ""
		then
			seenSpellIDs[spellID] = true
			actions[#actions + 1] = {
				name = spellName,
				spellID = math.floor(spellID),
			}
		end
	end
end

function M.getProfessionActions()
	local actions = {}
	local seenSpellIDs = {}
	for _, spellID in ipairs(M.PROFESSION_ACTION_SPELL_IDS) do
		M.appendProfessionAction(actions, seenSpellIDs, spellID)
	end

	local spellBook = _G.C_SpellBook
	local spellBookEnum = _G.Enum and _G.Enum.SpellBookSpellBank
	local itemTypeEnum = _G.Enum and _G.Enum.SpellBookItemType
	if not (
		_G.GetProfessions
		and _G.GetProfessionInfo
		and spellBook
		and spellBook.GetSpellBookItemInfo
		and spellBookEnum
		and itemTypeEnum
	) then
		table.sort(actions, function(left, right) return left.name < right.name end)
		return actions
	end

	local professionIndices = { _G.GetProfessions() }
	for professionSlot = 1, 5 do
		local professionIndex = professionIndices[professionSlot]
		if professionIndex and not (_G.issecretvalue and _G.issecretvalue(professionIndex)) then
			local professionName, _, _, _, numSpells, spellOffset = _G.GetProfessionInfo(professionIndex)
			local professionInfoIsSecret = _G.issecretvalue
				and (
					_G.issecretvalue(professionName)
					or _G.issecretvalue(numSpells)
					or _G.issecretvalue(spellOffset)
				)
			if not professionInfoIsSecret and type(numSpells) == "number" and type(spellOffset) == "number" then
				for spellOffsetIndex = 1, numSpells do
					local itemInfo = spellBook.GetSpellBookItemInfo(
						spellOffset + spellOffsetIndex,
						spellBookEnum.Player
					)
					local itemInfoIsSecret = itemInfo
						and _G.issecrettable
						and _G.issecrettable(itemInfo)
					if itemInfo and not itemInfoIsSecret then
						local itemType = itemInfo.itemType
						local isPassive = itemInfo.isPassive
						local spellID = itemInfo.spellID
						local spellName = itemInfo.name
						local itemFieldsAreSecret = _G.issecretvalue
							and (
								_G.issecretvalue(itemType)
								or _G.issecretvalue(isPassive)
								or _G.issecretvalue(spellID)
								or _G.issecretvalue(spellName)
							)
						if
							not itemFieldsAreSecret
							and itemType == itemTypeEnum.Spell
							and isPassive ~= true
							and type(spellID) == "number"
							and spellID > 0
							and type(spellName) == "string"
							and spellName ~= ""
							and not seenSpellIDs[spellID]
						then
							M.appendProfessionAction(actions, seenSpellIDs, spellID, spellName)
						end
					end
				end
			end
		end
	end
	table.sort(actions, function(left, right) return left.name < right.name end)
	return actions
end

function M.addProfessionActions(menuID, professionActions)
	if not M.isEditingAllowed() then return false end
	local menu = M.getMenu(menuID)
	if not (menu and type(professionActions) == "table") then return false end
	local existing = {}
	for _, action in ipairs(menu.actions or {}) do
		if action.kind == "spell" and type(action.id) == "number" then existing[action.id] = true end
	end
	local added = 0
	for _, professionAction in ipairs(professionActions) do
		local spellID = professionAction and professionAction.spellID
		if
			not (_G.issecretvalue and _G.issecretvalue(spellID))
			and type(spellID) == "number"
			and spellID > 0
			and not existing[spellID]
		then
			menu.actions[#menu.actions + 1] = {
				kind = "spell",
				id = math.floor(spellID),
			}
			existing[spellID] = true
			added = added + 1
		end
	end
	if added < 1 then return true end
	QC:Normalize()
	M.refreshRuntime(false)
	return true
end

function M.showAddActionMenu(owner, menuID)
	if not (_G.MenuUtil and _G.MenuUtil.CreateContextMenu) then return end
	local cursorAction = M.resolveCursorAction()
	local outfitActions = M.getOutfitActions()
	local professionActions = M.getProfessionActions()
	local nestedMenus = {}
	local config = QC:GetConfig()
	for _, candidateMenuID in ipairs(config.order or {}) do
		local candidateMenu = config.menus[candidateMenuID]
		if candidateMenu and candidateMenu.enabled ~= false and not QC:WouldCreateMenuCycle(menuID, candidateMenuID) then
			nestedMenus[#nestedMenus + 1] = candidateMenu
		end
	end
	_G.MenuUtil.CreateContextMenu(owner, function(_, root)
		root:SetTag("MENU_EQOL_QUICKCAST_ADD_ACTION")
		root:CreateTitle(L["QuickCastActions"] or "Actions")
		if cursorAction then
			local name = M.getActionName(cursorAction)
			root:CreateButton(name, function() M.acceptCursorAction(menuID) end)
			root:CreateDivider()
		end
		root:CreateButton(L["CooldownPanelAddSpellID"] or "Add Spell ID", function()
			M.showAddByIDPopup(menuID, "spell")
		end)
		root:CreateButton(L["CooldownPanelAddItemID"] or "Add Item ID", function()
			M.showAddByIDPopup(menuID, "item")
		end)
		if #nestedMenus > 0 then
			local nestedMenu = root:CreateButton(L["QuickCastNestedMenu"] or "QuickActions ring")
			for _, childMenu in ipairs(nestedMenus) do
				local currentChildMenu = childMenu
				nestedMenu:CreateButton(currentChildMenu.name, function()
					M.addMenuAction(menuID, currentChildMenu.id)
				end)
			end
		end
		root:CreateDivider()
		if #outfitActions > 0 then
			local outfitsMenu = root:CreateButton(L["QuickCastOutfits"] or "Outfits")
			for _, outfitAction in ipairs(outfitActions) do
				local currentOutfitAction = outfitAction
				outfitsMenu:CreateButton(currentOutfitAction.name, function()
					M.addOutfitAction(menuID, currentOutfitAction.id)
				end)
			end
		end
		local teleportFunctions = addon.MythicPlus and addon.MythicPlus.functions
		if teleportFunctions and teleportFunctions.BuildCurrentSeasonTeleportSection then
			local teleportsMenu = root:CreateButton(L["Teleports"] or "Teleports")
			teleportsMenu:CreateCheckbox(L["QuickCastCurrentSeasonMythicPlus"] or "Current Season Mythic+ teleports", function()
				local menu = M.getMenu(menuID)
				return menu
					and type(menu.managedSources) == "table"
					and menu.managedSources[QC.MANAGED_SOURCE_CURRENT_SEASON] == true
					or false
			end, function()
				local menu = M.getMenu(menuID)
				local enabled = menu
					and type(menu.managedSources) == "table"
					and menu.managedSources[QC.MANAGED_SOURCE_CURRENT_SEASON] == true
				M.setManagedSource(menuID, QC.MANAGED_SOURCE_CURRENT_SEASON, not enabled)
			end)
			if teleportFunctions.BuildTeleportCompendiumSections and QC.MANAGED_SOURCE_TELEPORT_FAVORITES then
				teleportsMenu:CreateCheckbox(L["QuickCastTeleportFavorites"] or "Favorite teleports", function()
					local menu = M.getMenu(menuID)
					return menu
						and type(menu.managedSources) == "table"
						and menu.managedSources[QC.MANAGED_SOURCE_TELEPORT_FAVORITES] == true
						or false
				end, function()
					local menu = M.getMenu(menuID)
					local enabled = menu
						and type(menu.managedSources) == "table"
						and menu.managedSources[QC.MANAGED_SOURCE_TELEPORT_FAVORITES] == true
					M.setManagedSource(menuID, QC.MANAGED_SOURCE_TELEPORT_FAVORITES, not enabled)
				end)
			end
		end
		if #professionActions > 0 then
			local professionsMenu = root:CreateButton(L["Professions"] or "Professions")
			professionsMenu:CreateButton(_G.ALL or "All", function()
				M.addProfessionActions(menuID, professionActions)
			end)
			professionsMenu:CreateDivider()
			for _, professionAction in ipairs(professionActions) do
				local currentProfessionAction = professionAction
				professionsMenu:CreateButton(currentProfessionAction.name, function()
					M.addProfessionActions(menuID, { currentProfessionAction })
				end)
			end
		end
		root:CreateButton(L["WorldMarkers"] or "World Markers", function() M.addMarkerPreset(menuID, "worldmarker") end)
		root:CreateButton(L["RaidTargetIcon"] or "Target Markers", function() M.addMarkerPreset(menuID, "raidtarget") end)
		local eqolMenu = root:CreateButton(L["QuickCastEnhanceQoLActions"] or "Enhance QoL actions")
		for _, actionID in ipairs({ "auctionMount", "hearthstone", "randomMount", "repairMount" }) do
			local currentActionID = actionID
			eqolMenu:CreateButton(M.getEQOLActionName(currentActionID), function()
				M.addEQOLAction(menuID, currentActionID)
			end)
		end
	end)
end

function M.createTile(parent)
	local button = _G.CreateFrame("Button", nil, parent, "EQOLQuickCastEditorItemTemplate")
	button.icon = button.Icon
	button.highlight = button.Highlight
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		if not self.isAddTile then Editor:BeginDrag(self) end
	end)
	button:SetScript("OnMouseUp", function(self, mouseButton)
		if M.consumeSuppressedMouseUp(mouseButton) then return end
		if mouseButton == "RightButton" then
			if Editor:CancelDrag() then return end
			if self.isAddTile then
				M.showAddActionMenu(self, self.menuID)
			else
				M.showActionContext(self, self.menuID, self.entryID)
			end
			return
		end
		if Editor.state.drag then
			Editor:EndDrag(self.menuID, self.isAddTile and nil or self.actionIndex)
			return
		end
		if self.isAddTile then
			if M.handleExternalCursorDrop(self.menuID) then return end
			M.showAddActionMenu(self, self.menuID)
		else
			if _G.GetCursorInfo() then return end
			Editor.state.selectedMenuID = self.menuID
			Editor.state.selectedEntryID = self.entryID
			M.openEntrySettings(self.menuID, self.entryID)
		end
	end)
	button:SetScript("OnReceiveDrag", function(self)
		if Editor.state.drag then
			Editor:EndDrag(self.menuID, self.isAddTile and nil or self.actionIndex, true)
		elseif self.isAddTile then
			M.handleExternalCursorDrop(self.menuID, true)
		end
	end)
	button:SetScript("OnEnter", function(self)
		if self.isAddTile then return end
		local action, _, menu = M.getAction(self.menuID, self.entryID)
		if QC.ShowActionTooltip then
			QC:ShowActionTooltip(self, action, menu, true)
		else
			M.showActionTooltip(self, action)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if QC.HideActionTooltip then
			QC:HideActionTooltip(self)
		else
			M.hideTooltip()
		end
	end)
	return button
end

function M.releaseTile(tile)
	tile:Hide()
	tile:ClearAllPoints()
	tile.menuID = nil
	tile.entryID = nil
	tile.actionIndex = nil
	tile.isAddTile = nil
	tile:SetAlpha(1)
	tile.Icon:SetDesaturated(false)
	tile.Disabled:Hide()
	if tile.SubmenuMarker then tile.SubmenuMarker:Hide() end
	if tile.DefaultMarker then tile.DefaultMarker:Hide() end
	if tile.dropGlow then tile.dropGlow:SetAlpha(0) end
end

function M.getTile(category)
	category.tileActive = (category.tileActive or 0) + 1
	local tile = category.tiles[category.tileActive]
	if not tile then
		tile = M.createTile(category.Container)
		category.tiles[category.tileActive] = tile
	end
	return tile
end

function M.releaseCategory(category)
	for _, tile in ipairs(category.tiles) do M.releaseTile(tile) end
	category.tileActive = 0
	if category.addTile then M.releaseTile(category.addTile) end
	category:Hide()
	category:ClearAllPoints()
end

function M.createCategory(parent)
	local category = _G.CreateFrame("Frame", nil, parent, "EQOLQuickCastEditorCategoryTemplate")
	category:SetWidth(Editor.CATEGORY_WIDTH)
	category.tiles = {}
	category.tileActive = 0
	category.Header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	if category.Header.Name then
		category.Header.Name:SetWidth(245)
		category.Header.Name:SetJustifyH("LEFT")
		category.Header.Name:SetMaxLines(1)
		category.Header.Name:SetWordWrap(false)
	end
	local function headerClick(header, mouseButton)
		local owner = header:GetParent()
		if M.consumeSuppressedMouseUp(mouseButton) then return end
		if mouseButton == "RightButton" then
			if Editor:CancelDrag() then return end
			M.showMenuContext(header, owner.menuID)
			return
		end
		if Editor.state.drag then
			Editor:EndDrag(owner.menuID)
			return
		end
		if M.handleExternalCursorDrop(owner.menuID) then return end
		Editor.state.selectedMenuID = owner.menuID
		Editor.state.selectedEntryID = nil
		Editor.state.collapsed[owner.menuID] = not Editor.state.collapsed[owner.menuID]
		Editor:Refresh()
	end
	if category.Header.SetClickHandler then
		category.Header:SetClickHandler(headerClick)
	else
		category.Header:SetScript("OnClick", headerClick)
	end
	category.Header:SetScript("OnReceiveDrag", function(header)
		local menuID = header:GetParent().menuID
		if Editor.state.drag then
			Editor:EndDrag(menuID, nil, true)
		else
			M.handleExternalCursorDrop(menuID, true)
		end
	end)
	category.dropCatcher = _G.CreateFrame("Button", nil, category)
	category.dropCatcher:RegisterForClicks("LeftButtonUp")
	category.dropCatcher:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton ~= "LeftButton" or M.consumeSuppressedMouseUp(mouseButton) then return end
		local menuID = self:GetParent().menuID
		if Editor.state.drag then
			Editor:EndDrag(menuID)
			return
		end
		M.handleExternalCursorDrop(menuID)
	end)
	category.dropCatcher:SetScript("OnReceiveDrag", function(self)
		local menuID = self:GetParent().menuID
		if Editor.state.drag then
			Editor:EndDrag(menuID, nil, true)
		else
			M.handleExternalCursorDrop(menuID, true)
		end
	end)
	category.addTile = M.createTile(category.Container)
	category.addTile.isAddTile = true
	category.addTile.Icon:SetAtlas("cdm-empty", true)
	category.addTile.dropGlow = category.addTile:CreateTexture(nil, "OVERLAY")
	category.addTile.dropGlow:SetAllPoints()
	category.addTile.dropGlow:SetColorTexture(0.1, 1, 0.25, 1)
	category.addTile.dropGlow:SetBlendMode("ADD")
	category.addTile.dropGlow:SetAlpha(0)
	category.disabledLabel = category.Header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	category.disabledLabel:SetPoint("RIGHT", category.Header, "RIGHT", -12, 0)
	category.disabledLabel:SetText(_G.DISABLED or "Disabled")
	category.disabledLabel:Hide()
	return category
end

function M.getCategory(frame)
	frame.categoryActive = (frame.categoryActive or 0) + 1
	local category = frame.categories[frame.categoryActive]
	if not category then
		category = M.createCategory(frame.content)
		frame.categories[frame.categoryActive] = category
	end
	return category
end

function M.releaseCategories(frame)
	for _, category in ipairs(frame.categories) do M.releaseCategory(category) end
	frame.categoryActive = 0
end

function M.actionSearchText(action)
	local name = M.getActionName(action)
	return string.format(
		"%s %s %s %s %s %s %s %s",
		tostring(name or ""),
		M.getActionIdentity(action),
		tostring(action.customLabel or ""),
		tostring(action.managedLabel or ""),
		tostring(action.kind or ""),
		tostring(action.id or action.name or ""),
		tostring(action.managedSource or ""),
		tostring(action.managedKey or "")
	):lower()
end

function M.getVisibleActions(menu, filterText, menuMatches)
	local result = {}
	for index, action in ipairs(menu.actions or {}) do
		local matchesSpec = menu.hideOtherSpecs ~= true or Editor:FilterAllowsView(action.conditions and action.conditions.specs)
		local matchesCharacter = not QC.ActionBelongsToCurrentCharacter or QC:ActionBelongsToCurrentCharacter(action)
		if matchesCharacter and matchesSpec and (not filterText or menuMatches or M.actionSearchText(action):find(filterText, 1, true)) then
			result[#result + 1] = { index = index, action = action }
		end
	end
	return result
end

function M.layoutCategory(category, menu, yOffset, filterText)
	category.menuID = menu.id
	category:SetPoint("TOPLEFT", category:GetParent(), "TOPLEFT", 0, -yOffset)
	if category.Header.SetHeaderText then
		category.Header:SetHeaderText(M.truncate(menu.name, 28))
	elseif category.Header.Name then
		category.Header.Name:SetText(M.truncate(menu.name, 28))
	end
	if menu.id == Editor.state.selectedMenuID then
		category.Header:LockHighlight()
	else
		category.Header:UnlockHighlight()
	end
	local disabled = menu.enabled == false
	category.disabledLabel:SetShown(disabled)
	local collapsed = Editor.state.collapsed[menu.id] == true and not filterText
	if category.Header.UpdateCollapsedState then category.Header:UpdateCollapsedState(collapsed) end
	for _, tile in ipairs(category.tiles) do M.releaseTile(tile) end
	category.tileActive = 0
	M.releaseTile(category.addTile)

	local height = 22
	if not collapsed then
		category.Container:Show()
		local menuMatches = filterText and menu.name:lower():find(filterText, 1, true) ~= nil
		local visibleActions = M.getVisibleActions(menu, filterText, menuMatches)
		local column, row = 0, 0
		for _, data in ipairs(visibleActions) do
			local tile = M.getTile(category)
			local action = data.action
			local _, icon, valid, iconAtlas = M.getActionName(action)
			tile.menuID = menu.id
			tile.actionIndex = data.index
			tile.entryID = M.getEntryID(action, data.index)
			tile.isAddTile = nil
			tile.Icon._eqolQuickActionsTexCoords = nil
			if not iconAtlas then
				M.applyActionTexture(tile.Icon, action, icon)
				tile.Icon:SetTexCoord(0, 1, 0, 1)
			end
			if iconAtlas then M.applyActionTexture(tile.Icon, action, icon, iconAtlas) end
			tile.Icon:SetDesaturated(disabled or action.enabled == false or not valid)
			tile:SetAlpha(disabled and 0.45 or action.enabled == false and 0.55 or 1)
			tile.Disabled:SetShown(not valid)
			if tile.SubmenuMarker then tile.SubmenuMarker:SetShown(action.kind == "menu") end
			if tile.DefaultMarker then tile.DefaultMarker:SetShown(menu.defaultEntryID == action.entryID) end
			tile:SetPoint("TOPLEFT", category.Container, "TOPLEFT", column * (Editor.TILE_SIZE + Editor.TILE_SPACING), -row * (Editor.TILE_SIZE + Editor.TILE_SPACING))
			tile:Show()
			column = column + 1
			if column >= Editor.TILE_STRIDE then
				column = 0
				row = row + 1
			end
		end
		if not filterText then
			local addTile = category.addTile
			addTile.menuID = menu.id
			addTile.isAddTile = true
			addTile.actionIndex = nil
			addTile.entryID = nil
			addTile.Icon:SetAtlas("cdm-empty", true)
			addTile.Icon:SetDesaturated(disabled)
			addTile:SetAlpha(disabled and 0.45 or 1)
			addTile.Disabled:Hide()
			addTile:SetPoint("TOPLEFT", category.Container, "TOPLEFT", column * (Editor.TILE_SIZE + Editor.TILE_SPACING), -row * (Editor.TILE_SIZE + Editor.TILE_SPACING))
			addTile:Show()
			column = column + 1
			if column >= Editor.TILE_STRIDE then
				column = 0
				row = row + 1
			end
		end
		local occupiedRows = row + (column > 0 and 1 or 0)
		local containerHeight = math.max(1, occupiedRows * Editor.TILE_SIZE + math.max(0, occupiedRows - 1) * Editor.TILE_SPACING)
		category.Container:SetSize(Editor.CATEGORY_WIDTH - 26, containerHeight)
		height = 22 + 15 + containerHeight + 8
	else
		category.Container:Hide()
		category.Container:SetHeight(1)
	end
	category.dropCatcher:ClearAllPoints()
	category.dropCatcher:SetPoint("TOPLEFT", category, "TOPLEFT", 0, -22)
	category.dropCatcher:SetPoint("BOTTOMRIGHT", category, "BOTTOMRIGHT")
	category.dropCatcher:SetShown(not collapsed)
	category:SetHeight(height)
	category.layoutHeight = height
	category:Show()
	return height
end

function M.getCursorPosition(frame)
	local x, y = _G.GetCursorPosition()
	local scale = frame and frame:GetEffectiveScale() or _G.UIParent:GetEffectiveScale()
	return x / scale, y / scale
end

function M.getFrameSides(frame)
	if not (frame and frame.GetLeft) then return nil end
	local left, right, bottom, top = frame:GetLeft(), frame:GetRight(), frame:GetBottom(), frame:GetTop()
	if not (left and right and bottom and top) then return nil end
	return left, right, bottom, top
end

function M.pointInside(frame, x, y)
	if not (frame and frame:IsShown()) then return false end
	local left, right, bottom, top = M.getFrameSides(frame)
	return left and right and bottom and top and x >= left and x <= right and y >= bottom and y <= top
end

function M.pointInsideCategoryLayout(category, x, y)
	local left, right, _, top = M.getFrameSides(category)
	local height = tonumber(category and category.layoutHeight)
	if not (left and right and top and height) then return M.pointInside(category, x, y) end
	return x >= left and x <= right and y <= top and y >= (top - height)
end

function M.getDistanceToFrame(frame, x, y)
	local left, right, bottom, top = M.getFrameSides(frame)
	if not left then return nil end
	local verticalDistance = y >= bottom and y <= top and 0 or math.min(math.abs(y - bottom), math.abs(y - top))
	local horizontalDistance = x >= left and x <= right and 0 or math.min(math.abs(x - left), math.abs(x - right))
	return verticalDistance * 3 + horizontalDistance
end

function M.showDraggedIcon(texture, atlas)
	if not Editor.draggedItem then
		Editor.draggedItem = _G.CreateFrame("Frame", nil, _G.UIParent, "EQOLQuickCastEditorDraggedItemTemplate")
	end
	Editor.draggedItem:SetToCursor(texture, atlas)
end

function M.hideDraggedIcon()
	if Editor.draggedItem then
		Editor.draggedItem:Hide()
		Editor.draggedItem:ClearAllPoints()
	end
end

function Editor:BeginDrag(tile)
	if not (tile and tile.menuID and tile.entryID and M.isEditingAllowed()) then return end
	local action = M.getAction(tile.menuID, tile.entryID)
	if not action then return end
	self:CancelDrag()
	self.state.drag = {
		menuID = tile.menuID,
		entryID = tile.entryID,
		sourceTile = tile,
	}
	tile.Icon:SetDesaturated(true)
	M.showDraggedIcon(tile.Icon:GetTexture(), tile.Icon.GetAtlas and tile.Icon:GetAtlas())
	local frame = self:GetFrame()
	frame:RegisterEvent("GLOBAL_MOUSE_UP")
	if _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.UI_CURSOR_PICKUP_OBJECT then _G.PlaySound(_G.SOUNDKIT.UI_CURSOR_PICKUP_OBJECT) end
end

function Editor:FindReorderTarget(x, y)
	local frame = self.frame
	local drag = self.state.drag
	if not (frame and drag) then return nil end
	if frame.scroll and not M.pointInside(frame.scroll, x, y) then return nil end

	local cursorCategory
	for categoryIndex = 1, frame.categoryActive or 0 do
		local category = frame.categories[categoryIndex]
		if category and category:IsShown() and M.pointInsideCategoryLayout(category, x, y) then
			cursorCategory = category
			break
		end
	end
	if cursorCategory and cursorCategory.menuID ~= drag.menuID then return nil end

	local best, bestDistance
	local function considerTile(category, tile, append)
		if not (tile and tile:IsShown()) then return end
		local tileDistance = M.getDistanceToFrame(tile, x, y)
		if not tileDistance then return end
		local categoryDistance = M.getDistanceToFrame(category, x, y) or 0
		local distance = tileDistance + categoryDistance
		if not bestDistance or distance < bestDistance then
			bestDistance = distance
			best = {
				append = append == true,
				category = category,
				tile = tile,
			}
		end
	end

	for categoryIndex = 1, frame.categoryActive or 0 do
		local category = frame.categories[categoryIndex]
		if
			category
			and category.menuID == drag.menuID
			and category:IsShown()
			and (not cursorCategory or category == cursorCategory)
			and category.Container:IsShown()
		then
			for tileIndex = 1, category.tileActive or 0 do
				local tile = category.tiles[tileIndex]
				if tile and tile:IsShown() and tile.entryID then considerTile(category, tile, false) end
			end
			considerTile(category, category.addTile, true)
		end
	end

	return best
end

function Editor:UpdateReorderMarker(force)
	local drag = self.state.drag
	local frame = self.frame
	if not (drag and frame and frame.ReorderMarker and (force == true or self.state.drag)) then return end
	local x, y = M.getCursorPosition(frame)
	local target = self:FindReorderTarget(x, y)
	self.state.reorderTarget = nil
	frame.ReorderMarker:Hide()
	if not target then return end

	local menu = M.getMenu(drag.menuID)
	if not menu then return end
	local marker = frame.ReorderMarker
	local after = false
	local insertion
	marker:ClearAllPoints()
	marker:SetVertical()
	if target.append then
		insertion = #menu.actions + 1
		marker:SetPoint("CENTER", target.tile, "LEFT", -4, 0)
	else
		local centerX, centerY = target.tile:GetCenter()
		if not (centerX and centerY and target.tile.actionIndex) then return end
		if y < centerY then
			after = true
		elseif x >= centerX then
			after = true
		end
		insertion = target.tile.actionIndex + (after and 1 or 0)
		marker:SetPoint("CENTER", target.tile, after and "RIGHT" or "LEFT", after and 4 or -4, 0)
	end
	self.state.reorderTarget = {
		insertion = insertion,
		menuID = target.category.menuID,
	}
	marker:Show()
end

function Editor:UpdateExternalDropPulse(elapsed)
	local frame = self.frame
	if not frame then return end
	self.state.externalDropPulseElapsed = (self.state.externalDropPulseElapsed or 0) + (elapsed or 0)
	if self.state.externalDropPulseElapsed < 0.08 then return end
	self.state.externalDropPulseElapsed = 0
	local cursorAction = not self.state.drag and M.isEditingAllowed() and M.resolveCursorAction() or nil
	local pulse = cursorAction and (0.18 + (math.sin((_G.GetTime and _G.GetTime() or 0) * 5) + 1) * 0.18) or 0
	for categoryIndex = 1, (frame.categoryActive or 0) do
		local category = frame.categories[categoryIndex]
		local addTile = category and category.addTile
		local canAdd = false
		if cursorAction and addTile then
			local menu = M.getMenu(category.menuID)
			canAdd = menu ~= nil and addTile:IsShown()
		end
		if addTile and addTile.dropGlow then
			addTile.dropGlow:SetAlpha(canAdd and pulse or 0)
		end
	end
end

function Editor:EndDrag(defaultMenuID, defaultInsertion, suppressMouseUp)
	local drag = self.state.drag
	if not drag then return false end
	self:UpdateReorderMarker(true)
	local target = self.state.reorderTarget
	if target and target.menuID ~= drag.menuID then target = nil end
	if not target and defaultMenuID == drag.menuID then
		local menu = M.getMenu(drag.menuID)
		target = {
			insertion = defaultInsertion or (#(menu and menu.actions or {}) + 1),
			menuID = drag.menuID,
		}
	end

	local sourceIndex = M.getActionIndex(drag.menuID, drag.entryID)
	local moved = false
	if sourceIndex and target and target.insertion then
		local targetIndex = target.insertion
		if sourceIndex < targetIndex then targetIndex = targetIndex - 1 end
		local menu = M.getMenu(drag.menuID)
		targetIndex = M.clampInteger(targetIndex, 1, #(menu and menu.actions or {}), sourceIndex)
		if targetIndex ~= sourceIndex then moved = QC:MoveAction(drag.menuID, sourceIndex, targetIndex) == true end
	end
	if suppressMouseUp then M.suppressTileMouseUp("LeftButton") end
	self:CancelDrag(false)
	if moved then
		self.state.selectedMenuID = drag.menuID
		self.state.selectedEntryID = drag.entryID
		M.refreshRuntime(false)
	end
	return true
end

function Editor:CancelDrag(skipSound)
	local drag = self.state.drag
	if not drag then return false end
	if drag.sourceTile and drag.sourceTile.Icon then
		local action, _, menu = M.getAction(drag.menuID, drag.entryID)
		local _, _, valid = M.getActionName(action)
		drag.sourceTile.Icon:SetDesaturated(not action or not valid or action.enabled == false or (menu and menu.enabled == false))
	end
	self.state.drag = nil
	self.state.reorderTarget = nil
	if self.frame then
		self.frame:UnregisterEvent("GLOBAL_MOUSE_UP")
		self.frame.ReorderMarker:Hide()
	end
	M.hideDraggedIcon()
	if not skipSound and _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.UI_CURSOR_DROP_OBJECT then
		_G.PlaySound(_G.SOUNDKIT.UI_CURSOR_DROP_OBJECT)
	end
	return true
end

function Editor:SetLayoutEditEnabled(enabled)
	enabled = enabled == true
	if enabled and not M.isEditingAllowed() then
		self.state.layoutEdit = false
		return false
	end
	if enabled and not M.getSelectedMenu() then
		local config = QC:GetConfig()
		self.state.selectedMenuID = config.order[1]
	end
	if enabled and not M.getSelectedMenu() then enabled = false end
	self.state.layoutEdit = enabled
	if enabled then
		if QC.ShowLayoutPreview then QC:ShowLayoutPreview(self.state.selectedMenuID) end
	else
		if QC.HideLayoutPreview then QC:HideLayoutPreview() end
	end
	return enabled
end

function Editor:SelectMenu(menuID, openSettings)
	if not M.getMenu(menuID) then return end
	self.state.selectedMenuID = menuID
	self.state.selectedEntryID = nil
	if self.state.layoutEdit and QC.ShowLayoutPreview then QC:ShowLayoutPreview(menuID) end
	if openSettings then M.openMenuSettings(menuID) end
	self:Refresh()
end

function Editor:SelectAction(actionIndex, menuID)
	menuID = menuID or self.state.selectedMenuID
	local menu = M.getMenu(menuID)
	actionIndex = tonumber(actionIndex)
	local action = menu and actionIndex and menu.actions[actionIndex]
	if not action then return false end
	local entryID = M.getEntryID(action, actionIndex)
	self.state.selectedMenuID = menuID
	self.state.selectedEntryID = entryID
	M.openEntrySettings(menuID, entryID)
	return true
end

function Editor:IsOpen()
	return self.frame and self.frame:IsShown() or false
end

function Editor:AddMenu()
	if not M.isEditingAllowed() then return nil end
	local menu, reason = QC:CreateMenu()
	if not menu then
		if reason == "limit" then M.showError(L["QuickCastMenuLimitReached"] or "The QuickActions menu limit has been reached.") end
		return nil
	end
	self.state.selectedMenuID = menu.id
	self.state.selectedEntryID = nil
	self.state.collapsed[menu.id] = false
	self:SetLayoutEditEnabled(true)
	self:Refresh()
	M.openMenuSettings(menu.id)
	return menu
end

function M.getCurrentSpecIcon()
	if _G.GetSpecialization and _G.GetSpecializationInfo then
		local specIndex = _G.GetSpecialization()
		if specIndex then
			local _, _, _, icon = _G.GetSpecializationInfo(specIndex)
			if icon then return icon end
		end
	end
	return M.ADDON_ICON
end

function M.getSelectedSpecIcon()
	if not tonumber(Editor.state.specView) then return nil end
	for _, option in ipairs(Editor:GetClassSpecOptions(M.getSelectedClassID())) do
		if tostring(option.value) == tostring(Editor.state.specView) and option.icon then return option.icon end
	end
	return M.getCurrentSpecIcon()
end

function M.setPortraitTexture(frame, texture)
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

function M.setPortraitToClass(frame, classID)
	local _, classFile = M.getClassInfo(classID)
	if not classFile then
		M.setPortraitTexture(frame, M.ADDON_ICON)
		return
	end
	if frame.SetPortraitToClassIcon then
		frame:SetPortraitToClassIcon(classFile)
		return
	end
	local coords = _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[string.upper(classFile)]
	if frame.SetPortraitTextureRaw and frame.SetPortraitTexCoord and coords then
		frame:SetPortraitTextureRaw("Interface/TargetingFrame/UI-Classes-Circles")
		frame:SetPortraitTexCoord(_G.unpack(coords))
		return
	end
	local portrait = frame.PortraitContainer and frame.PortraitContainer.portrait
	if portrait and coords then
		portrait:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
		portrait:SetTexCoord(_G.unpack(coords))
		return
	end
	M.setPortraitTexture(frame, M.ADDON_ICON)
end

function M.setupPortrait(frame)
	if _G.ButtonFrameTemplate_ShowPortrait then _G.ButtonFrameTemplate_ShowPortrait(frame) end
	if Editor.state.specView == "ALL" then
		M.setPortraitTexture(frame, M.ADDON_ICON)
	elseif Editor.state.specView == "CLASS" then
		M.setPortraitToClass(frame, M.getSelectedClassID())
	else
		M.setPortraitTexture(frame, M.getSelectedSpecIcon() or M.ADDON_ICON)
	end
end

function M.setEditorSideTabSelected(tab, selected)
	if not tab then return end
	if tab.SelectedTexture then tab.SelectedTexture:SetShown(selected == true) end
	if tab.Icon then tab.Icon:SetAlpha(selected == true and 1 or 0.55) end
end

function M.createEditorSideTab(parent, data)
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
	M.setEditorSideTabSelected(tab, data.selected)
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside and data.onClick then data.onClick() end
	end)
	return tab
end

function M.createEditorSwitcherTabs(frame)
	if frame.editorSwitcherTabs then return end
	local cooldownTab = M.createEditorSideTab(frame, {
		iconTexture = M.COOLDOWN_PANEL_ICON,
		tooltipText = L["CooldownPanelOpenEditor"] or "Open Cooldown Panel Editor",
		selected = false,
		onClick = M.openCooldownPanelEditor,
	})
	cooldownTab:SetPoint("TOPLEFT", frame, "TOPRIGHT", 3, -28)
	local quickActionsTab = M.createEditorSideTab(frame, {
		iconAtlas = M.QUICK_ACTIONS_ICON_ATLAS,
		tooltipText = L["QuickCastOpenEditor"] or "Open QuickActions editor",
		selected = true,
	})
	quickActionsTab:SetPoint("TOPLEFT", cooldownTab, "BOTTOMLEFT", 0, -3)
	frame.editorSwitcherTabs = { cooldownTab, quickActionsTab }
	M.updateEditorSwitcherTabs(frame)
end

function M.updateEditorSwitcherTabs(frame)
	local tabs = frame and frame.editorSwitcherTabs
	if not tabs then return end
	local shown = M.areEditorAddOnsLoaded()
	for _, tab in ipairs(tabs) do tab:SetShown(shown) end
end

function M.saveFramePosition(frame)
	if not (frame and addon.db) then return end
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if not point then return end
	addon.db.quickCastEditorPosition = {
		point = point,
		relativePoint = relativePoint or point,
		x = x or 0,
		y = y or 0,
	}
end

function M.positionFrame(frame)
	frame:ClearAllPoints()
	local pos = addon.db and addon.db.quickCastEditorPosition
	if type(pos) == "table" and pos.point then
		frame:SetPoint(pos.point, _G.UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
	else
		frame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 32, -72)
	end
end

function M.applyTooltip(owner, title, body)
	owner:SetScript("OnEnter", function(self)
		_G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		_G.GameTooltip:SetText(title or "")
		if body and body ~= "" then _G.GameTooltip:AddLine(body, 1, 1, 1, true) end
		_G.GameTooltip:Show()
	end)
	owner:SetScript("OnLeave", M.hideTooltip)
end

function M.createEditorHelpButton(frame)
	local helpButton = _G.CreateFrame("Button", nil, frame)
	helpButton:SetSize(28, 28)
	helpButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 1)
	helpButton:SetNormalTexture("Interface\\common\\help-i")
	helpButton:SetHighlightTexture("Interface\\common\\help-i")
	if helpButton:GetHighlightTexture() then helpButton:GetHighlightTexture():SetAlpha(0.7) end
	helpButton:SetScript("OnEnter", function(button)
		if not _G.GameTooltip then return end
		_G.GameTooltip:SetOwner(button, "ANCHOR_LEFT", -6, 0)
		_G.GameTooltip:ClearLines()
		_G.GameTooltip:AddLine(L["QuickCast"] or "QuickActions", 1, 0.82, 0)
		_G.GameTooltip:AddLine(L["QuickCastDescription"] or "", 1, 1, 1, true)
		_G.GameTooltip:AddLine(" ", 1, 1, 1, true)
		_G.GameTooltip:AddLine(L["QuickCastEditorHelpAdd"] or "", 1, 1, 1, true)
		_G.GameTooltip:AddLine(" ", 1, 1, 1, true)
		_G.GameTooltip:AddLine(L["QuickCastEditorHelpEdit"] or "", 1, 1, 1, true)
		_G.GameTooltip:Show()
	end)
	helpButton:SetScript("OnLeave", M.hideTooltip)
	return helpButton
end

function M.isSlashCommandRegistered(command)
	if addon.functions and addon.functions.IsSlashCommandRegistered then return addon.functions.IsSlashCommandRegistered(command) end
	if not command then return false end
	command = command:lower()
	for key, value in pairs(_G) do
		if type(key) == "string" and key:match("^SLASH_") and type(value) == "string" and value:lower() == command then return true end
	end
	return false
end

function M.setSlashCommandAlias(slot, command)
	if addon.functions and addon.functions.SetSlashCommandAlias then
		return addon.functions.SetSlashCommandAlias("EQOLQC", slot, command)
	end
	command = type(command) == "string" and command:lower() or nil
	_G["SLASH_EQOLQC" .. slot] = command
	return command
end

function M.registerSlashCommands()
	if not _G.SlashCmdList then return end
	local command = "/eqa"
	local owned = false
	if _G.SlashCmdList.EQOLQC then
		for index = 1, 4 do
			local existing = _G["SLASH_EQOLQC" .. index]
			if type(existing) == "string" and existing:lower() == command then
				owned = true
				break
			end
		end
	end
	for index = 2, 4 do M.setSlashCommandAlias(index, nil) end
	if M.isSlashCommandRegistered(command) and not owned then
		M.setSlashCommandAlias(1, nil)
		return
	end
	M.setSlashCommandAlias(1, command)
	_G.SlashCmdList.EQOLQC = function(message)
		message = type(message) == "string" and message:match("^%s*(.-)%s*$"):lower() or ""
		if message == "trace" and QC.ToggleRuntimeTrace then
			QC:ToggleRuntimeTrace()
			return
		end
		Editor:Toggle()
	end
end

function Editor:GetSlashCommandHint()
	return "/eqa"
end

function Editor:CreateFrame()
	local frame = _G.EQOLQuickCastEditor
	if not frame then return nil end
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		M.saveFramePosition(self)
	end)
	M.setupPortrait(frame)
	if frame.TitleContainer and frame.TitleContainer.TitleText then
		frame.TitleContainer.TitleText:SetText(L["QuickCast"] or "QuickActions")
	elseif frame.TitleText then
		frame.TitleText:SetText(L["QuickCast"] or "QuickActions")
	end

	frame.searchBox = frame.SearchBox
	if frame.searchBox.Instructions then frame.searchBox.Instructions:SetText(_G.SEARCH or "Search") end
	frame.searchBox:SetScript("OnTextChanged", function(self)
		if _G.SearchBoxTemplate_OnTextChanged then _G.SearchBoxTemplate_OnTextChanged(self) end
		Editor:Refresh()
	end)

	frame.addMenuButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.addMenuButton:SetSize(100, 22)
	frame.addMenuButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -42, 4)
	local addMenuIcon = _G.CreateAtlasMarkup and _G.CreateAtlasMarkup("communities-icon-addgroupplus", 16, 16, 0, -1) or "+"
	frame.addMenuButton:SetText(string.format("%s %s", addMenuIcon, _G.ADD or "Add"))
	frame.addMenuButton:SetScript("OnClick", function() Editor:AddMenu() end)
	M.applyTooltip(frame.addMenuButton, L["QuickCastAddMenu"] or "Create QuickActions menu")
	frame.helpButton = frame.helpButton or M.createEditorHelpButton(frame)

	frame.gear = frame.SettingsDropdown
	frame.gear.Icon:SetAtlas("questlog-icon-setting", true)
	M.applyTooltip(frame.gear, _G.SETTINGS or "Settings")
	frame.gear:SetupMenu(function(_, root)
		root:SetTag("MENU_EQOL_QUICKCAST_EDITOR")
		root:CreateTitle(L["QuickCast"] or "QuickActions")
		root:CreateButton(L["QuickCastOpenSettings"] or _G.SETTINGS or "Settings", function()
			frame:Hide()
			if addon.functions and addon.functions.OpenConfigCenter then
				addon.functions.OpenConfigCenter("interface.quickactions", "quickactions.animationStyle")
			end
		end)
		root:CreateDivider()
		root:CreateButton(_G.EXPAND_ALL or "Expand all", function()
			for menuID in pairs(QC:GetConfig().menus) do Editor.state.collapsed[menuID] = false end
			Editor:Refresh()
		end)
		root:CreateButton(_G.COLLAPSE_ALL or "Collapse all", function()
			for menuID in pairs(QC:GetConfig().menus) do Editor.state.collapsed[menuID] = true end
			Editor:Refresh()
		end)
	end)

	frame.SpecDropdown:SetWidth(220)
	frame.SpecDropdown:SetupMenu(function(_, root)
		root:SetTag("MENU_EQOL_QUICKCAST_SPEC_VIEW")
		local classMenu = root:CreateButton(_G.CLASS or "Class")
		classMenu:CreateRadio(_G.ALL_CLASSES or "All classes", function()
			return Editor.state.specView == "ALL"
		end, function()
			Editor:SetClassView("ALL")
		end)
		for _, option in ipairs(Editor:GetClassOptions()) do
			classMenu:CreateRadio(option.label, function()
				return Editor.state.specView ~= "ALL" and tonumber(Editor.state.classView) == tonumber(option.value)
			end, function()
				Editor:SetClassView(option.value)
			end)
		end

		local classID = M.getSelectedClassID()
		local className = M.getClassInfo(classID) or M.getPlayerClassInfo()
		root:CreateTitle(M.getClassColorText(classID, className))
		for _, option in ipairs(Editor:GetClassSpecOptions(classID)) do
			root:CreateRadio(option.specName, function()
				return tostring(Editor.state.specView) == tostring(option.value)
			end, function()
				Editor:SetClassSpecView(classID, option.value)
			end)
		end
		root:CreateRadio(_G.ALL_SPECS or "All specializations", function()
			return Editor.state.specView == "CLASS" and tonumber(Editor.state.classView) == tonumber(classID)
		end, function()
			Editor:SetClassSpecView(classID, "CLASS")
		end)
	end)
	frame.CombatWarning:SetText(L["QuickCastEditCombat"] or "QuickActions menus cannot be edited during combat.")

	frame.scroll = frame.MenuScroll
	frame.content = frame.MenuScroll.Content
	frame.categories = {}
	frame.categoryActive = 0
	frame.emptyText = frame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.emptyText:SetPoint("TOPLEFT", 6, -6)
	frame.emptyText:SetWidth(320)
	frame.emptyText:SetJustifyH("LEFT")
	M.createEditorSwitcherTabs(frame)

	frame:SetScript("OnShow", function(self)
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("UPDATE_MACROS")
		self:RegisterEvent("SPELLS_CHANGED")
		if self.RegisterUnitEvent then
			self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		else
			self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		end
		self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
		M.updateEditorSwitcherTabs(self)
		Editor:Refresh()
	end)
	frame:SetScript("OnHide", function(self)
		self:UnregisterAllEvents()
		if Editor.iconPicker and Editor.iconPicker:IsShown() then Editor.iconPicker:Hide() end
		if Editor.iconPicker and Editor.iconPicker.iconDataProvider then
			Editor.iconPicker.iconDataProvider:Release()
			Editor.iconPicker.iconDataProvider = nil
		end
		Editor:CancelDrag(true)
		M.stopHotkeyCapture(false)
		Editor:SetLayoutEditEnabled(false)
		if addon.EditModeLib and addon.EditModeLib.HideStandaloneSettingsDialog then
			addon.EditModeLib:HideStandaloneSettingsDialog(self)
		end
	end)
	frame:SetScript("OnEvent", function(_, eventName, arg1)
		if eventName == "GLOBAL_MOUSE_UP" then
			if arg1 == "RightButton" then
				M.suppressTileMouseUp("RightButton")
				Editor:CancelDrag()
			elseif arg1 == "LeftButton" then
				Editor:EndDrag(nil, nil, true)
			end
			return
		end
		if eventName == "PLAYER_SPECIALIZATION_CHANGED" and arg1 and arg1 ~= "player" then return end
		if eventName == "PLAYER_REGEN_DISABLED" then
			Editor:CancelDrag(true)
			M.stopHotkeyCapture(true)
			Editor:SetLayoutEditEnabled(false)
		end
		if eventName == "PLAYER_SPECIALIZATION_CHANGED" or eventName == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
			if Editor:SyncSpecViewToCurrentSpec() then
				M.refreshDialog()
				return
			end
		end
		Editor:Refresh()
		if eventName == "PLAYER_REGEN_DISABLED"
			or eventName == "PLAYER_REGEN_ENABLED"
			or eventName == "PLAYER_SPECIALIZATION_CHANGED"
			or eventName == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
		then
			M.refreshDialog()
		end
	end)
	frame:SetScript("OnUpdate", function(_, elapsed)
		if Editor.state.drag then
			Editor:UpdateReorderMarker()
		else
			Editor:UpdateExternalDropPulse(elapsed)
		end
	end)
	frame:SetScript("OnMouseUp", function(_, mouseButton)
		if mouseButton == "RightButton" then Editor:CancelDrag() end
	end)
	self.frame = frame
	return frame
end

function Editor:GetFrame()
	return self.frame or self:CreateFrame()
end

function Editor:Refresh()
	local frame = self.frame
	if not (frame and frame:IsShown()) then return end
	M.setupPortrait(frame)
	local config = QC:GetConfig()
	if not M.getSelectedMenu() then
		self.state.selectedMenuID = config.order[1]
		self.state.selectedEntryID = nil
	end
	frame.CombatWarning:SetShown(not M.isEditingAllowed())
	M.releaseCategories(frame)

	local filterText = M.trim(frame.searchBox:GetText()):lower()
	if filterText == "" then filterText = nil end
	local yOffset, visibleMenus = 0, 0
	for _, menuID in ipairs(config.order) do
		local menu = config.menus[menuID]
		local menuMatches = not filterText or menu.name:lower():find(filterText, 1, true) ~= nil
		local hasActionMatch = false
		if filterText and not menuMatches then
			hasActionMatch = #M.getVisibleActions(menu, filterText, false) > 0
		end
		if self:MenuMatchesSpecView(menu) and (menuMatches or hasActionMatch) then
			visibleMenus = visibleMenus + 1
			local category = M.getCategory(frame)
			local height = M.layoutCategory(category, menu, yOffset, filterText)
			yOffset = yOffset + height + 8
		end
	end
	frame.content:SetHeight(math.max(1, yOffset))
	frame.emptyText:SetShown(visibleMenus == 0)
	frame.emptyText:SetText(filterText and (_G.NO_RESULTS_FOUND or "No results found.") or (L["QuickCastNoMenus"] or "Create a menu to begin."))
	frame.addMenuButton:SetEnabled(M.isEditingAllowed())
	self:UpdateSpecDropdown()
end

function Editor:Open(focusID)
	local frame = self:GetFrame()
	if not frame then return nil end
	self:EnsureInitialSpecView()
	M.positionFrame(frame)
	frame:Show()
	if focusID == "create" and not QC:GetConfig().order[1] then self:AddMenu() end
	if frame.Raise then frame:Raise() end
	self:Refresh()
	return frame
end

function Editor:Toggle()
	local frame = self:GetFrame()
	if not frame then return nil end
	if frame:IsShown() then
		frame:Hide()
	else
		self:Open()
	end
	return frame
end

function Editor:Render(parent, _, _, _, focusID)
	local frame = self:Open(focusID)
	if frame and addon.functions and addon.functions.HideConfigCenterUntilFrameHidden then
		addon.functions.HideConfigCenterUntilFrameHidden(frame)
	end
	return self
end

function Editor:Release()
	-- The editor is an independent window. Releasing the launcher page must not
	-- close it because the Config Center is intentionally hidden while it is open.
end

_G.StaticPopupDialogs[M.POPUP_DELETE] = {
	text = L["QuickCastConfirmDelete"] or "Delete QuickActions menu %s?",
	button1 = _G.DELETE,
	button2 = _G.CANCEL,
	OnAccept = function(_, data)
		if not (data and QC:DeleteMenu(data.menuID)) then return end
		if Editor.state.selectedMenuID == data.menuID then
			Editor.state.selectedMenuID = nil
			Editor.state.selectedEntryID = nil
		end
		if addon.EditModeLib and addon.EditModeLib.HideStandaloneSettingsDialog and Editor.frame then
			addon.EditModeLib:HideStandaloneSettingsDialog(Editor.frame)
		end
		M.refreshRuntime(false)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

_G.StaticPopupDialogs[M.POPUP_REPLACE] = {
	text = L["QuickCastReplaceBinding"] or "%s is assigned to %s. Replace it for this QuickActions menu?",
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	OnAccept = function(_, data)
		if data then M.applyHotkey(data.menuID, data.hotkey) end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3,
}

M.registerSlashCommands()
