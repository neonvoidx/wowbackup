local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local CDP = addon.Aura.CooldownPanels
local SG = CDP.SpellGroups
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Editor = { state = { collapsed = {}, classID = nil }, TILE_SIZE = 38, TILE_SPACING = 8, TILE_STRIDE = 7, CONTENT_WIDTH = 344 }
CDP.SpellGroupsEditor = Editor

function Editor:IsEditingAllowed()
	return not ((UnitAffectingCombat and UnitAffectingCombat("player")) or (InCombatLockdown and InCombatLockdown()))
end

function Editor:ReportError(reason)
	local keys = {
		combat = "CDLSpellGroupsCombat",
		duplicate_spell = "CDLSpellGroupsDuplicateSpell",
		duplicate_item = "CDLSpellGroupsDuplicateSpell",
		duplicate_member = "CDLSpellGroupsDuplicateSpell",
		invalid_spell = "CDLSpellGroupsInvalidSpell",
		invalid_aura = "UFGlobalAuraIgnoreCustomInvalidSpell",
		invalid_item = "Item id does not exist",
		invalid_name = "CDLSpellGroupsInvalidName",
	}
	local message = L[keys[reason] or "CDLSpellGroupsOperationFailed"]
	if UIErrorsFrame then UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2) end
end

function Editor:Apply(method, ...)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return nil end
	local result, reason = SG[method](SG, ...)
	if not result then self:ReportError(reason); return nil end
	self:Refresh()
	return result
end

function Editor:RequestSpellData(spellID)
	if not C_Spell.RequestLoadSpellData then return end
	self.requestedSpells = self.requestedSpells or {}
	if not self.requestedSpells[spellID] then
		self.requestedSpells[spellID] = true
		C_Spell.RequestLoadSpellData(spellID)
	end
end

function Editor:RequestItemData(itemID)
	self.requestedItems = self.requestedItems or {}
	if not self.requestedItems[itemID] then
		self.requestedItems[itemID] = true
		C_Item.RequestLoadItemDataByID(itemID)
	end
end

function Editor:GetMemberName(member)
	if member.type == "ITEM" then
		local name = C_Item.GetItemNameByID(member.itemID)
		if not name then self:RequestItemData(member.itemID) end
		return name or tostring(member.itemID)
	end
	local name = C_Spell.GetSpellName(member.spellID)
	if not name then self:RequestSpellData(member.spellID) end
	name = name or tostring(member.spellID)
	return member.type == "CDM_AURA" and string.format(L["CDLSpellGroupsAuraName"], name) or name
end

function Editor:GetMemberIcon(member)
	if member.type == "ITEM" then
		local texture = C_Item.GetItemIconByID(member.itemID)
		if not texture then self:RequestItemData(member.itemID) end
		return texture or 134400
	end
	local texture = C_Spell.GetSpellTexture(member.spellID)
	if not texture then self:RequestSpellData(member.spellID) end
	return texture or 134400
end

function Editor:GetMemberIdentity(member)
	if member.type == "CDM_AURA" then return "AURA:" .. member.spellID end
	if member.type == "ITEM" then
		local canonical = CDP.GetCanonicalItemRankID and CDP:GetCanonicalItemRankID(member.itemID) or member.itemID
		return "ITEM:" .. canonical
	end
	return "SPELL:" .. member.spellID
end

function Editor:AddSpell(groupID, spellID, beforeKey)
	if not (type(spellID) == "number" and spellID > 0 and spellID == math.floor(spellID) and C_Spell.DoesSpellExist(spellID)) then
		self:ReportError("invalid_spell")
		return nil
	end
	return self:Apply("AddSpell", groupID, spellID, beforeKey)
end

function Editor:AddAura(groupID, spellID, beforeKey)
	if not (type(spellID) == "number" and spellID > 0 and spellID == math.floor(spellID) and C_Spell.DoesSpellExist(spellID)) then
		self:ReportError("invalid_aura")
		return nil
	end
	return self:Apply("AddAura", groupID, spellID, beforeKey)
end

function Editor:AddItem(groupID, itemID, beforeKey)
	if not (type(itemID) == "number" and itemID > 0 and itemID == math.floor(itemID) and C_Item.DoesItemExistByID(itemID)) then
		self:ReportError("invalid_item")
		return nil
	end
	return self:Apply("AddItem", groupID, itemID, beforeKey)
end

function Editor:GetPresetName(presetID)
	local preset = SG.Presets.byID[presetID]
	return preset and L[preset.nameKey] or tostring(presetID)
end

function Editor:GetSortedPresetIDs()
	local ids = {}
	for _, id in ipairs(SG.Presets.order) do ids[#ids + 1] = id end
	table.sort(ids, function(left, right)
		local leftName, rightName = self:GetPresetName(left), self:GetPresetName(right)
		if strcmputf8i then
			local comparison = strcmputf8i(leftName, rightName)
			if comparison ~= 0 then return comparison < 0 end
		else
			leftName, rightName = leftName:lower(), rightName:lower()
			if leftName ~= rightName then return leftName < rightName end
		end
		return left < right
	end)
	return ids
end

function Editor:MemberMatchesView(member, filter)
	if self.state.classID and not CDP:SpellGroupMemberAllowsClass(member, self.state.classID) then return false end
	if not filter or filter == "" then return true end
	return (self:GetMemberName(member) .. " " .. tostring(member.itemID or member.spellID)):lower():find(filter:lower(), 1, true) ~= nil
end

function Editor:GetVisibleMembers(groupID, filter)
	local members = {}
	local group = SG:GetGroup(groupID)
	local groupMatches = group and filter and filter ~= "" and group.name:lower():find(filter:lower(), 1, true)
	local memberFilter = filter
	if groupMatches then memberFilter = nil end
	for _, member in ipairs(SG:GetMembers(groupID)) do
		if self:MemberMatchesView(member, memberFilter) then members[#members + 1] = member end
	end
	return members
end

function Editor:ShowPrompt(text, initial, callback, numeric)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	StaticPopupDialogs.EQOL_SPELL_GROUPS_INPUT = StaticPopupDialogs.EQOL_SPELL_GROUPS_INPUT or {
		text = "%s", button1 = OKAY, button2 = CANCEL, hasEditBox = true, editBoxWidth = 320,
		EditBoxOnEscapePressed = addon.functions.CancelPopupOnEscape,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		OnShow = function(popup, data)
			popup:SetFrameStrata("TOOLTIP")
			local editBox = popup.editBox or popup:GetEditBox()
			editBox:SetNumeric(data.numeric == true)
			editBox:SetMaxLetters(data.numeric and 12 or 100)
			editBox:SetText(data.initial or "")
			editBox:HighlightText()
			editBox:SetFocus()
		end,
		OnAccept = function(popup, data)
			if not Editor:IsEditingAllowed() then Editor:ReportError("combat"); return end
			local editBox = popup.editBox or popup:GetEditBox()
			data.callback(editBox:GetText())
		end,
		EditBoxOnEnterPressed = function(editBox)
			local popup = editBox:GetParent()
			local button = popup.button1 or (popup.GetButton1 and popup:GetButton1())
			if button then button:Click() end
		end,
	}
	StaticPopup_Show("EQOL_SPELL_GROUPS_INPUT", text, nil, { initial = initial, callback = callback, numeric = numeric })
end

function Editor:Confirm(text, callback)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	StaticPopupDialogs.EQOL_SPELL_GROUPS_CONFIRM = StaticPopupDialogs.EQOL_SPELL_GROUPS_CONFIRM or {
		text = "%s", button1 = YES, button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		OnShow = function(popup) popup:SetFrameStrata("TOOLTIP") end,
		OnAccept = function(_, data)
			if Editor:IsEditingAllowed() then data.callback() else Editor:ReportError("combat") end
		end,
	}
	StaticPopup_Show("EQOL_SPELL_GROUPS_CONFIRM", text, nil, { callback = callback })
end

function Editor:Export(groupIDs)
	local code, reason = SG:ExportGroups(groupIDs)
	if not code then self:ReportError(reason); return end
	StaticPopupDialogs.EQOL_SPELL_GROUPS_EXPORT = StaticPopupDialogs.EQOL_SPELL_GROUPS_EXPORT or {
		text = L["CDLSpellGroupsExport"], button1 = CLOSE, hasEditBox = true, editBoxWidth = 320,
		EditBoxOnEscapePressed = addon.functions.CancelPopupOnEscape,
		EditBoxOnEnterPressed = addon.functions.AcceptPopupOnEnter,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		OnShow = function(popup, data)
			popup:SetFrameStrata("TOOLTIP")
			local editBox = popup.editBox or popup:GetEditBox()
			editBox:SetMaxLetters(0)
			editBox:SetText(data.code)
			editBox:HighlightText()
			editBox:SetFocus()
		end,
	}
	StaticPopup_Show("EQOL_SPELL_GROUPS_EXPORT", nil, nil, { code = code })
end

function Editor:Import()
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	StaticPopupDialogs.EQOL_SPELL_GROUPS_IMPORT = StaticPopupDialogs.EQOL_SPELL_GROUPS_IMPORT or {
		text = L["CDLSpellGroupsImportPrompt"], button1 = _G.IMPORT or L["Import"], button2 = CANCEL, hasEditBox = true, editBoxWidth = 320,
		EditBoxOnEscapePressed = addon.functions.CancelPopupOnEscape,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		OnShow = function(popup)
			popup:SetFrameStrata("TOOLTIP")
			local editBox = popup.editBox or popup:GetEditBox()
			editBox:SetMaxLetters(0)
			editBox:SetText("")
			editBox:SetFocus()
		end,
		OnAccept = function(popup)
			local editBox = popup.editBox or popup:GetEditBox()
			Editor:Apply("ImportEncodedGroups", editBox:GetText())
		end,
		EditBoxOnEnterPressed = function(editBox)
			local popup = editBox:GetParent()
			local button = popup.button1 or (popup.GetButton1 and popup:GetButton1())
			if button then button:Click() end
		end,
	}
	StaticPopup_Show("EQOL_SPELL_GROUPS_IMPORT")
end

function Editor:ShowAddMenu(owner)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	MenuUtil.CreateContextMenu(owner, function(_, menu)
		menu:CreateTitle(L["CDLSpellGroupsTitle"])
		menu:CreateButton(L["CDLSpellGroupsOwnGroup"], function()
			Editor:ShowPrompt(L["CDLSpellGroupsName"], L["CDLSpellGroupsNewGroup"], function(name) Editor:Apply("CreateGroup", name) end)
		end)
		local presets = menu:CreateButton(L["CDLSpellGroupsPreset"])
		for _, presetID in ipairs(Editor:GetSortedPresetIDs()) do
			local preset = SG.Presets.byID[presetID]
			local name = Editor:GetPresetName(presetID)
			local label = name
			if preset.icon and CreateTextureMarkup then label = CreateTextureMarkup(preset.icon, 64, 64, 16, 16, 0, 1, 0, 1) .. " " .. name end
			local entry = presets:CreateButton(label, function()
				Editor:Apply("CreateGroup", name, presetID)
			end)
			entry:SetTooltip(function(tooltip)
				tooltip:SetText(name)
				if preset.descriptionKey then tooltip:AddLine(L[preset.descriptionKey], 1, 1, 1, true) end
			end)
		end
	end)
end

function Editor:ShowAddSpell(groupID, beforeKey)
	self:ShowPrompt(L["CDLSpellGroupsAddSpellID"], "", function(text)
		Editor:AddSpell(groupID, tonumber(text), beforeKey)
	end, true)
end

function Editor:ShowAddMemberMenu(owner, groupID, beforeKey)
	if self.ShowMemberPicker then return self:ShowMemberPicker(groupID, beforeKey) end
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	MenuUtil.CreateContextMenu(owner, function(_, menu)
		menu:CreateButton(L["CDLSpellGroupsAddSpellID"], function() Editor:ShowAddSpell(groupID, beforeKey) end)
		menu:CreateButton(L["CooldownPanelAddItemID"], function()
			Editor:ShowPrompt(L["CooldownPanelAddItemID"], "", function(text)
				Editor:AddItem(groupID, tonumber(text), beforeKey)
			end, true)
		end)
		local auraButton = menu:CreateButton(L["CooldownPanelAddAuraSpellID"], function()
			Editor:ShowPrompt(L["CooldownPanelAddAuraSpellID"], "", function(text)
				Editor:AddAura(groupID, tonumber(text), beforeKey)
			end, true)
		end)
		auraButton:SetTooltip(function(tooltip)
			tooltip:SetText(L["CooldownPanelAddAuraSpellID"])
			tooltip:AddLine(L["CDLSpellGroupsAuraHelp"], 1, 1, 1, true)
		end)
	end)
end

function Editor:ShowMemberMenu(owner)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	local groupID, member = owner.groupID, owner.member
	if not (member and SG:GetGroup(groupID)) then return end
	MenuUtil.CreateContextMenu(owner, function(_, menu)
		menu:CreateTitle(Editor:GetMemberName(member))
		local copies = menu:CreateButton(L["CDLSpellGroupsCopyTo"])
		local available = 0
		for _, targetID in ipairs(SG:GetGroupIDs()) do
			if targetID ~= groupID then
				local exists = false
				for _, targetMember in ipairs(SG:GetMembers(targetID)) do
					if Editor:GetMemberIdentity(targetMember) == Editor:GetMemberIdentity(member) then exists = true; break end
				end
				if not exists then
					available = available + 1
					copies:CreateButton(SG:GetGroup(targetID).name, function() Editor:Apply("CopySpell", groupID, member.key, targetID) end)
				end
			end
		end
		copies:SetEnabled(available > 0)
		menu:CreateButton(REMOVE, function() Editor:Apply("RemoveSpell", groupID, member.key) end)
	end)
end

function Editor:ShowGroupMenu(owner, groupID)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	local group = SG:GetGroup(groupID)
	if not group then return end
	MenuUtil.CreateContextMenu(owner, function(_, menu)
		menu:CreateTitle(group.name)
		menu:CreateButton(L["CDLSpellGroupsRename"], function()
			Editor:ShowPrompt(L["CDLSpellGroupsName"], group.name, function(name) Editor:Apply("RenameGroup", groupID, name) end)
		end)
		menu:CreateButton(L["CooldownPanelDuplicate"], function() Editor:Apply("DuplicateGroup", groupID) end)
		local order = SG:GetGroupIDs()
		for index, id in ipairs(order) do
			if id == groupID then
				if index > 1 then menu:CreateButton(L["CDLSpellGroupsMoveUp"], function() Editor:Apply("ReorderGroup", groupID, order[index - 1]) end) end
				if index < #order then menu:CreateButton(L["CDLSpellGroupsMoveDown"], function() Editor:Apply("ReorderGroup", groupID, order[index + 2]) end) end
				break
			end
		end
		menu:CreateButton(L["CDLSpellGroupsExport"], function() Editor:Export({ groupID }) end)
		if group.presetID then
			menu:CreateButton(L["CDLSpellGroupsResetPreset"], function()
				Editor:Confirm(string.format(L["CDLSpellGroupsResetPrompt"], group.name), function() Editor:Apply("ResetPreset", groupID) end)
			end)
		end
		menu:CreateDivider()
		menu:CreateButton(DELETE, function()
			local text = string.format(L["CDLSpellGroupsDeletePrompt"], group.name)
			local names = {}
			for _, panel in ipairs(SG:GetReferencingPanels(groupID)) do
				local name = type(panel) == "table" and panel.name or tostring(panel)
				names[#names + 1] = name
			end
			if #names > 0 then text = text .. "\n\n" .. string.format(L["CDLSpellGroupsUsedBy"], table.concat(names, ", ")) end
			Editor:Confirm(text, function() Editor:Apply("DeleteGroup", groupID) end)
		end)
	end)
end

function Editor:HandleExternalDrop(groupID, beforeKey)
	local cursorType, value, _, spellID = GetCursorInfo()
	if not cursorType then return false end
	if not self:IsEditingAllowed() then self:ReportError("combat"); return true end
	local itemID
	if cursorType == "action" then
		spellID = nil
		local actionType, actionID = GetActionInfo(value)
		if actionType == "spell" then spellID = actionID elseif actionType == "item" then itemID = actionID end
	elseif cursorType == "spell" then
		spellID = spellID or value
	elseif cursorType == "item" then
		itemID, spellID = value, nil
	end
	local added
	if itemID then added = self:AddItem(groupID, itemID, beforeKey)
	elseif spellID and (cursorType == "spell" or cursorType == "action") then added = self:AddSpell(groupID, spellID, beforeKey)
	else self:ReportError("invalid_spell"); return true end
	if added then ClearCursor() end
	return true
end

function Editor:CancelDrag()
	if not self.state.drag then return false end
	self.state.drag = nil
	self.state.reorderTarget = nil
	self.state.ignoreMouseUp = nil
	if self.state.sourceTile then self.state.sourceTile:SetAlpha(1); self.state.sourceTile = nil end
	if self.draggedIcon then self.draggedIcon:Hide() end
	if self.frame then
		self.frame:UnregisterEvent("GLOBAL_MOUSE_UP")
		self.frame:SetScript("OnUpdate", nil)
		self.frame.ReorderMarker:Hide()
	end
	if self.state.refreshAfterDrag then self.state.refreshAfterDrag = nil; self:Refresh() end
	return true
end

function Editor:BeginDrag(tile, ignoreMouseUp)
	if not self:IsEditingAllowed() then self:ReportError("combat"); return end
	if not tile.member then return end
	self:CancelDrag()
	self.state.drag = { groupID = tile.groupID, key = tile.member.key }
	self.state.sourceTile = tile
	self.state.ignoreMouseUp = ignoreMouseUp
	tile:SetAlpha(0.35)
	if not self.draggedIcon then self.draggedIcon = CreateFrame("Frame", nil, UIParent, "EQOLCooldownPanelsBlizzardEditorDraggedItemTemplate") end
	self.draggedIcon:SetToCursor(tile.Icon:GetTexture())
	self.frame:RegisterEvent("GLOBAL_MOUSE_UP")
	self.frame:SetScript("OnUpdate", function() Editor:UpdateReorderTarget() end)
	GameTooltip:Hide()
end

function Editor:FinishDrag(groupID, beforeKey)
	local drag = self.state.drag
	if not drag then return false end
	if self.state.reorderTarget then groupID, beforeKey = self.state.reorderTarget.groupID, self.state.reorderTarget.beforeKey end
	self:CancelDrag()
	if groupID then self:Apply("MoveSpell", drag.groupID, drag.key, groupID, beforeKey) end
	return true
end

function Editor:GetMemberAfter(groupID, key)
	local members = SG:GetMembers(groupID)
	for index, member in ipairs(members) do
		if member.key == key then return members[index + 1] and members[index + 1].key end
	end
end

function Editor:UpdateReorderTarget()
	local frame = self.frame
	self.state.reorderTarget = nil
	frame.ReorderMarker:Hide()
	if not frame.scroll:IsMouseOver() then return end
	local x, y = GetCursorPosition()
	local scale = frame:GetEffectiveScale()
	x, y = x / scale, y / scale
	for _, category in ipairs(frame.categories) do
		if category:IsShown() and category:IsMouseOver() then
			if self.state.collapsed[category.groupID] then
				self.state.reorderTarget = { groupID = category.groupID }
				return
			end
			local best, distance
			for _, tile in ipairs(category.tiles) do
				if tile:IsShown() then
					local cx, cy = tile:GetCenter()
					local current = (x - cx) ^ 2 + (y - cy) ^ 2
					if not distance or current < distance then best, distance = tile, current end
				end
			end
			if best then
				local beforeKey = best.member and best.member.key
				local cx = best:GetCenter()
				local after = best.member and x > cx
				if after then beforeKey = self:GetMemberAfter(category.groupID, beforeKey) end
				self.state.reorderTarget = { groupID = category.groupID, beforeKey = beforeKey }
				local marker = frame.ReorderMarker
				marker:ClearAllPoints()
				marker:SetVertical()
				marker:SetPoint("CENTER", best, after and "RIGHT" or "LEFT", after and 4 or -4, 0)
				marker:Show()
			end
			return
		end
	end
end

function Editor:CreateTile(parent)
	local tile = CreateFrame("Frame", nil, parent, "EQOLCooldownPanelsBlizzardEditorItemTemplate")
	tile:EnableMouse(true)
	tile:RegisterForDrag("LeftButton")
	tile:SetScript("OnDragStart", function(selfTile) Editor:BeginDrag(selfTile) end)
	tile:SetScript("OnMouseUp", function(selfTile, button)
		if button == "RightButton" then
			if not Editor:CancelDrag() and selfTile.member then Editor:ShowMemberMenu(selfTile) end
			return
		end
		if button ~= "LeftButton" then return end
		if Editor:FinishDrag(selfTile.groupID, selfTile.member and selfTile.member.key) then return end
		if Editor:HandleExternalDrop(selfTile.groupID, selfTile.member and selfTile.member.key) then return end
		if selfTile.member then Editor:BeginDrag(selfTile, true) else Editor:ShowAddMemberMenu(selfTile, selfTile.groupID) end
	end)
	tile:SetScript("OnReceiveDrag", function(selfTile)
		if Editor:FinishDrag(selfTile.groupID, selfTile.member and selfTile.member.key) then return end
		Editor:HandleExternalDrop(selfTile.groupID, selfTile.member and selfTile.member.key)
	end)
	tile:SetScript("OnEnter", function(selfTile)
		if Editor.state.drag then return end
		GameTooltip:SetOwner(selfTile, "ANCHOR_RIGHT")
		if selfTile.member then
			if selfTile.member.type == "ITEM" then GameTooltip:SetItemByID(selfTile.member.itemID)
			else GameTooltip:SetSpellByID(selfTile.member.spellID) end
			if selfTile.member.type == "CDM_AURA" then GameTooltip:AddLine(L["CooldownPanelCDMAuraHelpTitle"], 0.6, 0.8, 1) end
			if selfTile.member.preset then GameTooltip:AddLine(L["CDLSpellGroupsPresetMember"], 0.6, 0.8, 1) end
			local kind = selfTile.member.dispelKind
			if kind == "FRIENDLY" or kind == "BOTH" then GameTooltip:AddLine(L["CDLSpellGroupsFriendlyDispel"], 0.6, 0.8, 1) end
			if kind == "OFFENSIVE" or kind == "BOTH" then GameTooltip:AddLine(L["CDLSpellGroupsOffensiveDispel"], 0.6, 0.8, 1) end
			GameTooltip:AddLine(L["CDLSpellGroupsSpellHelp"], 1, 1, 1, true)
		else
			GameTooltip:SetText(ADD)
			GameTooltip:AddLine(L["CDLSpellGroupsDropHelp"], 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	tile:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return tile
end

function Editor:CreateCategory(parent)
	local category = CreateFrame("Frame", nil, parent, "EQOLCooldownPanelsBlizzardEditorCategoryTemplate")
	category:SetWidth(self.CONTENT_WIDTH)
	category.tiles = {}
	category.Header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local function click(header, button)
		local groupID = header:GetParent().groupID
		if button == "RightButton" then
			if not Editor:CancelDrag() then Editor:ShowGroupMenu(header, groupID) end
			return
		end
		if Editor:FinishDrag(groupID) or Editor:HandleExternalDrop(groupID) then return end
		Editor.state.collapsed[groupID] = not Editor.state.collapsed[groupID]
		Editor:Refresh()
	end
	if category.Header.SetClickHandler then category.Header:SetClickHandler(click) else category.Header:SetScript("OnClick", click) end
	category.Header:SetScript("OnReceiveDrag", function(header)
		local groupID = header:GetParent().groupID
		if not Editor:FinishDrag(groupID) then Editor:HandleExternalDrop(groupID) end
	end)
	category.Header:SetScript("OnEnter", function(header)
		local group = SG:GetGroup(header:GetParent().groupID)
		if not group then return end
		GameTooltip:SetOwner(header, "ANCHOR_RIGHT")
		GameTooltip:SetText(group.name)
		if group.presetID then GameTooltip:AddLine(string.format(L["CDLSpellGroupsLinkedPreset"], Editor:GetPresetName(group.presetID)), 0.6, 0.8, 1, true) end
		GameTooltip:AddLine(L["CDLSpellGroupsGroupHelp"], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	category.Header:SetScript("OnLeave", function() GameTooltip:Hide() end)
	category.dropCatcher = CreateFrame("Frame", nil, category)
	category.dropCatcher:EnableMouse(true)
	category.dropCatcher:SetPoint("TOPLEFT", category.Header, "BOTTOMLEFT")
	category.dropCatcher:SetPoint("BOTTOMRIGHT")
	category.dropCatcher:SetFrameLevel(category:GetFrameLevel())
	category.dropCatcher:SetScript("OnMouseUp", function(selfFrame, button)
		if button == "LeftButton" then Editor:FinishDrag(selfFrame:GetParent().groupID) elseif button == "RightButton" then Editor:CancelDrag() end
	end)
	category.dropCatcher:SetScript("OnReceiveDrag", function(selfFrame)
		local groupID = selfFrame:GetParent().groupID
		if not Editor:FinishDrag(groupID) then Editor:HandleExternalDrop(groupID) end
	end)
	return category
end

function Editor:LayoutCategory(category, groupID, members, offset)
	local group = SG:GetGroup(groupID)
	category.groupID = groupID
	category:ClearAllPoints()
	category:SetPoint("TOPLEFT", category:GetParent(), "TOPLEFT", 0, -offset)
	category.Header:SetHeaderText(group.name)
	local collapsed = self.state.collapsed[groupID] == true
	if category.Header.UpdateCollapsedState then category.Header:UpdateCollapsedState(collapsed) end
	category.Container:SetShown(not collapsed)
	category.dropCatcher:SetShown(not collapsed)
	for _, tile in ipairs(category.tiles) do tile:Hide() end
	local height = 22
	if not collapsed then
		for index = 1, #members + 1 do
			local tile = category.tiles[index]
			if not tile then tile = self:CreateTile(category.Container); category.tiles[index] = tile end
			tile.groupID, tile.member = groupID, members[index]
			tile:ClearAllPoints()
			local column, row = (index - 1) % self.TILE_STRIDE, math.floor((index - 1) / self.TILE_STRIDE)
			tile:SetPoint("TOPLEFT", category.Container, "TOPLEFT", column * (self.TILE_SIZE + self.TILE_SPACING), -row * (self.TILE_SIZE + self.TILE_SPACING))
			if tile.member then tile.Icon:SetTexture(self:GetMemberIcon(tile.member)) else tile.Icon:SetAtlas("cdm-empty", true) end
			tile:SetAlpha(1)
			tile:Show()
		end
		local rows = math.ceil((#members + 1) / self.TILE_STRIDE)
		local gridHeight = rows * (self.TILE_SIZE + self.TILE_SPACING) - self.TILE_SPACING
		category.Container:SetSize(self.CONTENT_WIDTH - 26, gridHeight)
		height = 22 + 15 + gridHeight + 8
	end
	category:SetHeight(height)
	category:Show()
	return height
end

function Editor:GetViewLabel()
	if not self.state.classID then return ALL_CLASSES end
	for _, option in ipairs(CDP.BlizzardEditor:GetClassOptions()) do
		if option.value == self.state.classID then return option.label end
	end
	return ALL_CLASSES
end

function Editor:CreateSwitcherTabs(frame) addon.FeatureEditor:AttachTabs(frame, "groups") end

function Editor:CreateFrame()
	local frame = CreateFrame("Frame", "EQOLSpellGroupsEditor", UIParent, "EQOLCooldownPanelsBlizzardEditorWindowTemplate")
	self.frame = frame
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(selfFrame)
		selfFrame:StopMovingOrSizing()
		addon.functions.SaveSharedEditorPosition(selfFrame)
	end)
	frame:SetPortraitTextureRaw(CDP.BlizzardEditor.ADDON_ICON)
	frame:SetPortraitTexCoord(0, 1, 0, 1)
	frame.TitleContainer.TitleText:SetText(L["CDLSpellGroupsTitle"])
	frame.searchBox, frame.scroll, frame.content = frame.SearchBox, frame.CooldownScroll, frame.CooldownScroll.Content
	frame.categories = {}
	frame.searchBox.Instructions:SetText(SEARCH)
	frame.searchBox:SetScript("OnTextChanged", function(editBox) SearchBoxTemplate_OnTextChanged(editBox); Editor:Refresh() end)
	frame.addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.addButton:SetSize(126, 22)
	frame.addButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -44, 4)
	frame.addButton:SetText((CreateAtlasMarkup("communities-icon-addgroupplus", 16, 16, 0, -1) or "+") .. " " .. ADD)
	frame.addButton:SetScript("OnClick", function(button) Editor:ShowAddMenu(button) end)
	frame.helpButton = CreateFrame("Button", nil, frame)
	frame.helpButton:SetSize(28, 28)
	frame.helpButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 1)
	frame.helpButton:SetNormalTexture("Interface\\common\\help-i")
	frame.helpButton:SetHighlightTexture("Interface\\common\\help-i")
	frame.helpButton:GetHighlightTexture():SetAlpha(0.7)
	frame.helpButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_LEFT", -6, 0)
		GameTooltip:SetText(L["CDLSpellGroupsTitle"])
		GameTooltip:AddLine(L["CDLSpellGroupsDescription"], 1, 1, 1, true)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["CDLSpellGroupsGroupHelp"], 1, 1, 1, true)
		GameTooltip:AddLine(L["CDLSpellGroupsSpellHelp"], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	frame.helpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame.SettingsDropdown.Icon:SetAtlas("questlog-icon-setting", true)
	frame.SettingsDropdown:SetupMenu(function(_, menu)
		menu:CreateTitle(SETTINGS)
		menu:CreateButton(L["CDLSpellGroupsImport"], function() Editor:Import() end)
		menu:CreateButton(L["CDLSpellGroupsExport"], function() Editor:Export(SG:GetGroupIDs()) end)
	end)
	frame.LayoutDropdown:SetWidth(220)
	frame.LayoutDropdown:SetupMenu(function(_, menu)
		menu:CreateRadio(ALL_CLASSES, function() return not Editor.state.classID end, function()
			Editor:CancelDrag(); Editor.state.classID = nil; Editor:Refresh()
		end)
		for _, class in ipairs(CDP.BlizzardEditor:GetClassOptions()) do
			menu:CreateRadio(class.label, function() return Editor.state.classID == class.value end, function()
				Editor:CancelDrag(); Editor.state.classID = class.value; Editor:Refresh()
			end)
		end
	end)
	frame.emptyText = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.emptyText:SetPoint("TOPLEFT", 13, -24)
	frame.emptyText:SetWidth(self.CONTENT_WIDTH - 26)
	frame.emptyText:SetJustifyH("LEFT")
	frame.emptyText:SetText(L["CDLSpellGroupsEmpty"])
	frame.combatWarning = frame:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
	frame.combatWarning:SetPoint("TOPLEFT", 18, -62)
	frame.combatWarning:SetWidth(344)
	frame.combatWarning:SetJustifyH("LEFT")
	frame.combatWarning:SetText(L["CDLSpellGroupsCombat"])
	self:CreateSwitcherTabs(frame)
	frame:SetScript("OnShow", function(selfFrame)
		selfFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		selfFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		selfFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
		selfFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
		addon.FeatureEditor:UpdateTabs(selfFrame)
		Editor:Refresh()
	end)
	frame:SetScript("OnHide", function(selfFrame)
		Editor:CancelDrag()
		selfFrame:UnregisterAllEvents()
		GameTooltip:Hide()
		StaticPopup_Hide("EQOL_SPELL_GROUPS_INPUT")
		StaticPopup_Hide("EQOL_SPELL_GROUPS_CONFIRM")
		StaticPopup_Hide("EQOL_SPELL_GROUPS_IMPORT")
	end)
	frame:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then Editor:CancelDrag() end end)
	frame:SetScript("OnEvent", function(_, event, button, success)
		if event == "GLOBAL_MOUSE_UP" then
			if Editor.state.ignoreMouseUp then Editor.state.ignoreMouseUp = nil; return end
			if button == "RightButton" then Editor:CancelDrag() elseif button == "LeftButton" then Editor:FinishDrag() end
		elseif event == "SPELL_DATA_LOAD_RESULT" or event == "ITEM_DATA_LOAD_RESULT" then
			local isItem = event == "ITEM_DATA_LOAD_RESULT"
			local requested = isItem and Editor.requestedItems or Editor.requestedSpells
			if not (requested and requested[button]) or success == false then return end
			for _, category in ipairs(frame.categories) do
				for _, tile in ipairs(category.tiles) do
					local member = tile.member
					if member and ((isItem and member.type == "ITEM" and member.itemID == button)
						or (not isItem and member.type ~= "ITEM" and member.spellID == button)) then tile.Icon:SetTexture(Editor:GetMemberIcon(member)) end
				end
			end
			if frame.searchBox:GetText() ~= "" then Editor:Refresh() end
		else
			if event == "PLAYER_REGEN_DISABLED" then Editor:CancelDrag() end
			Editor:Refresh()
		end
	end)
	return frame
end

function Editor:Refresh()
	if self.AddEntryPicker then self.AddEntryPicker:NotifyChanged() end
	local frame = self.frame
	if not (frame and frame:IsShown()) then return end
	if self.state.drag then self.state.refreshAfterDrag = true; return end
	local allowed = self:IsEditingAllowed()
	frame.addButton:SetEnabled(allowed)
	frame.combatWarning:SetShown(not allowed)
	frame.scroll:ClearAllPoints()
	frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, allowed and -72 or -88)
	frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 29)
	local groups = SG:GetGroupIDs()
	local filter = frame.searchBox:GetText()
	local offset, categoryIndex = 0, 0
	for _, category in ipairs(frame.categories) do category:Hide() end
	for _, groupID in ipairs(groups) do
		local members = self:GetVisibleMembers(groupID, filter)
		local group = SG:GetGroup(groupID)
		local show = filter == "" or #members > 0 or group.name:lower():find(filter:lower(), 1, true)
		if show then
			categoryIndex = categoryIndex + 1
			local category = frame.categories[categoryIndex]
			if not category then category = self:CreateCategory(frame.content); frame.categories[categoryIndex] = category end
			offset = offset + self:LayoutCategory(category, groupID, members, offset) + 8
		end
	end
	frame.emptyText:SetText(#groups == 0 and L["CDLSpellGroupsEmpty"] or L["CDLSpellGroupsNoResults"])
	frame.emptyText:SetShown(categoryIndex == 0)
	frame.content:SetHeight(math.max(categoryIndex == 0 and 120 or 1, offset))
	frame.LayoutDropdown:SetDefaultText(self:GetViewLabel())
end

function Editor:RefreshGroup()
	self:Refresh()
end

function Editor:Open()
	if CDP.BlizzardEditor.frame then CDP.BlizzardEditor.frame:Hide() end
	if CDP.CloseEditor then CDP:CloseEditor() end
	if addon.QuickCast and addon.QuickCast.Editor and addon.QuickCast.Editor.frame then addon.QuickCast.Editor.frame:Hide() end
	local frame = self.frame or self:CreateFrame()
	addon.functions.ApplySharedEditorPosition(frame)
	frame:Show()
	frame:Raise()
	self:Refresh()
	return frame
end

function CDP:OpenSpellGroupsEditor()
	return Editor:Open()
end
