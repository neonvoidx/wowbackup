local addon = _G.EnhanceQoL
local P, L = addon.CooldownPulse, addon.CooldownPulse.L

-- Use the same native atlas regions and TBC fallback art as the other feature editors.
function P:SetEditorAtlas(texture, atlas, useSize)
	return addon.FeatureEditor:SetAtlas(texture, atlas, useSize)
end

function P:EditorTooltip(owner, title, body)
	owner:SetScript("OnEnter", function()
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT"); GameTooltip:SetText(title)
		if body then GameTooltip:AddLine(body, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function P:EditorIconButton(parent, atlas, tooltip, click)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(22, 22)
	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetPoint("CENTER"); button.Icon:SetSize(16, 16)
	self:SetEditorAtlas(button.Icon, atlas, false)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnClick", click)
	self:EditorTooltip(button, tooltip)
	return button
end

function P:TestGroup(id, spellID)
	if not self:Group(id) then return end
	if spellID then self:Pulse(id, spellID, true); return end
	local ids = {}
	for sid in pairs(self:Group(id).spells) do if not self:Group(id).ignoredSpells[sid] then ids[#ids + 1] = sid end end
	table.sort(ids)
	if #ids == 0 then ids[1] = 0 end
	for _, sid in ipairs(ids) do self:Pulse(id, sid, true) end
end

function P:AddSpell(id, spellID)
	if InCombatLockdown() then return end
	local group = self:Group(id)
	local normalized = self.NormalizeIDs({ [spellID] = true }, true)
	if not group or not normalized[spellID] then return end
	group.spells[spellID] = group.spells[spellID] or normalized[spellID]
	group.ignoredSpells[spellID] = nil
	self:Changed(id, true); self:RefreshOverview()
end

function P:ReceiveSpell(id)
	local kind, value, _, spellID = GetCursorInfo()
	if kind == "spell" then spellID = spellID or value end
	if kind ~= "spell" or not spellID or InCombatLockdown() then return false end
	self:AddSpell(id, spellID); ClearCursor(); return true
end

function P:GroupMenu(owner, id)
	MenuUtil.CreateContextMenu(owner, function(_, menu)
		menu:CreateTitle(P:Group(id).name)
		menu:CreateButton(EDIT, function() P:OpenSettings(id) end)
		menu:CreateButton(L["Test"], function() P:TestGroup(id) end)
		menu:CreateButton(ADD, function() StaticPopup_Show("EQOL_PULSE_ADD_SPELL", nil, nil, id) end)
		menu:CreateDivider()
		menu:CreateButton(L["CooldownPanelExportGroup"], function() P:ShowTransfer(id, false) end)
		menu:CreateButton(DELETE, function() StaticPopup_Show("EQOL_PULSE_DELETE", P:Group(id).name, nil, id) end)
	end)
end

function P:CreatePulseCategory(parent)
	local category = CreateFrame("Frame", nil, parent, "EQOLFeatureEditorCategoryTemplate")
	category:SetWidth(344); category.tiles = {}
	if not category.Header.SetHeaderText then
		category.Header.Text = category.Header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		category.Header.Text:SetPoint("LEFT", 8, 0)
		category.Header.Text:SetJustifyH("LEFT")
		category.Header.SetHeaderText = function(header, text) header.Text:SetText(text) end
	end
	category.Header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local function click(_, button)
		if button == "LeftButton" and P:ReceiveSpell(category.groupID) then return end
		P:GroupMenu(category.Header, category.groupID)
	end
	if category.Header.SetClickHandler then category.Header:SetClickHandler(click) else category.Header:SetScript("OnClick", click) end
	category.Header:SetScript("OnReceiveDrag", function() P:ReceiveSpell(category.groupID) end)
	category.edit = self:EditorIconButton(category.Header, "questlog-icon-setting", EDIT, function() P:OpenSettings(category.groupID) end)
	category.edit:SetPoint("RIGHT", -4, 0)
	category.test = self:EditorIconButton(category.Header, "common-icon-sound", L["Test"], function() P:TestGroup(category.groupID) end)
	category.test:SetPoint("RIGHT", category.edit, "LEFT", -4, 0)
	local label = category.Header.Name or category.Header.Text
	if label then
		label:ClearAllPoints(); label:SetPoint("LEFT", 8, 0)
		label:SetPoint("RIGHT", category.test, "LEFT", -6, 0)
		label:SetJustifyH("LEFT"); label:SetWordWrap(false)
	end
	self:EditorTooltip(category.Header, L["CooldownPulse"], L["CooldownPulseEditorHelp"])
	return category
end

function P:SetSpellIgnored(id, spellID, ignored)
	if InCombatLockdown() then return end
	local group = self:Group(id)
	if not group then return end
	group.ignoredSpells[spellID] = ignored and true or nil
	self:Changed(id, true)
	self:RefreshOverview()
end

function P:CreatePulseTile(parent)
	local tile = CreateFrame("Frame", nil, parent, "EQOLFeatureEditorItemTemplate")
	tile.ignoreOverlay = tile:CreateTexture(nil, "OVERLAY")
	tile.ignoreOverlay:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
	tile.ignoreOverlay:SetSize(22, 22); tile.ignoreOverlay:SetPoint("CENTER")
	tile.ignoreOverlay:Hide()
	tile:EnableMouse(true)
	tile:SetScript("OnReceiveDrag", function() P:ReceiveSpell(tile.groupID) end)
	tile:SetScript("OnMouseUp", function(_, button)
		if P:ReceiveSpell(tile.groupID) then return end
		local id, sid = tile.groupID, tile.spellID
		if not sid then StaticPopup_Show("EQOL_PULSE_ADD_SPELL", nil, nil, id); return end
		if button == "LeftButton" then P:OpenSettings(id, sid); return end
		MenuUtil.CreateContextMenu(tile, function(_, menu)
			menu:CreateTitle(P:SpellInfo(sid) or tostring(sid))
			menu:CreateButton(EDIT, function() P:OpenSettings(id, sid) end)
			menu:CreateButton(L["Test"], function() P:TestGroup(id, sid) end)
			menu:CreateCheckbox(L["CooldownPanelCDMQuickSetupIgnore"], function() return P:Group(id).ignoredSpells[sid] == true end,
				function() P:SetSpellIgnored(id, sid, not P:Group(id).ignoredSpells[sid]) end)
			menu:CreateButton(REMOVE, function()
				if InCombatLockdown() then return end
				if P.editGroup == id and P.editSpell == sid then addon.EditModeLib:HideSettingsDialog(P.frames[id]); P:FinishEditing() end
				local group = P:Group(id)
				group.spells[sid] = nil
				group.ignoredSpells[sid] = nil
				P:Changed(id, true); P:RefreshOverview()
			end)
		end)
	end)
	tile:SetScript("OnEnter", function()
		GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		local sid = tile.spellID
		if sid and sid > 0 then
			GameTooltip:SetSpellByID(sid)
			GameTooltip:AddLine(L["SpellID"] .. ": " .. sid, 0.65, 0.65, 0.65)
		elseif sid then
			GameTooltip:SetInventoryItem("player", -sid)
			GameTooltip:AddLine(L[sid == -13 and "CooldownPanelSlotTrinket1" or "CooldownPanelSlotTrinket2"], 0.65, 0.65, 0.65)
		else GameTooltip:SetText(ADD) end
		if sid and P:Group(tile.groupID).ignoredSpells[sid] then GameTooltip:AddLine(L["CooldownPanelCDMQuickSetupIgnore"], 1, 0.25, 0.25) end
		GameTooltip:AddLine(L["CooldownPulseEditorHelp"], 1, 1, 1, true); GameTooltip:Show()
	end)
	tile:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return tile
end

function P:RefreshOverview()
	local frame = self.overview
	if not frame or not frame:IsShown() then return end
	local filter = frame.SearchBox:GetText():lower()
	for _, category in ipairs(frame.categories) do category:Hide() end
	local offset, index = 0, 0
	for _, id in ipairs(self:IDs()) do
		local group, ids = self:Group(id), {}
		local groupMatches = group.name:lower():find(filter, 1, true)
		local visibleSpells = {}
		for sid in pairs(group.spells) do visibleSpells[sid] = true end
		for sid in pairs(group.ignoredSpells) do visibleSpells[sid] = true end
		for sid in pairs(visibleSpells) do
			local name = self:SpellInfo(sid) or ""
			if groupMatches or name:lower():find(filter, 1, true) or tostring(sid):find(filter, 1, true) then ids[#ids + 1] = sid end
		end
		table.sort(ids)
		if groupMatches or #ids > 0 then
			index = index + 1
			local category = frame.categories[index] or self:CreatePulseCategory(frame.content)
			frame.categories[index] = category; category.groupID = id
			category:ClearAllPoints(); category:SetPoint("TOPLEFT", 0, -offset)
			category.Header:SetHeaderText(group.name)
			for _, tile in ipairs(category.tiles) do tile:Hide() end
			for i = 1, #ids + 1 do
				local tile = category.tiles[i] or self:CreatePulseTile(category.Container)
				category.tiles[i] = tile; tile.groupID, tile.spellID = id, ids[i]
				tile:ClearAllPoints(); tile:SetPoint("TOPLEFT", (i - 1) % 7 * 46, -math.floor((i - 1) / 7) * 46)
				local _, icon = self:SpellInfo(ids[i] or 0)
				if ids[i] then tile.Icon:SetTexture(icon or 134400) else self:SetEditorAtlas(tile.Icon, "cdm-empty", true) end
				local ignored = ids[i] and group.ignoredSpells[ids[i]] == true or false
				tile.ignoreOverlay:SetShown(ignored)
				tile.Icon:SetDesaturated(ignored); tile.Icon:SetAlpha(ignored and 0.45 or 1)
				tile:Show()
			end
			local height = math.ceil((#ids + 1) / 7) * 46 - 8
			category.Container:SetSize(318, height); category:SetHeight(45 + height); category:Show()
			offset = offset + height + 53
		end
	end
	frame.content:SetHeight(math.max(offset, 80))
	frame.empty:SetShown(index == 0)
end

function P:CreateOverview()
	local frame = CreateFrame("Frame", "EQOLCooldownPulseEditor", UIParent, "EQOLFeatureEditorWindowTemplate")
	self.overview = frame
	frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); addon.functions.SaveSharedEditorPosition(frame) end)
	frame:SetPortraitTextureRaw("Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga")
	frame:SetPortraitTexCoord(0, 1, 0, 1); frame.TitleContainer.TitleText:SetText(L["CooldownPulse"])
	frame.content, frame.categories = frame.CooldownScroll.Content, {}
	frame.SearchBox.Instructions:SetText(SEARCH)
	frame.SearchBox:SetScript("OnTextChanged", function(box) SearchBoxTemplate_OnTextChanged(box); P:RefreshOverview() end)
	self:SetEditorAtlas(frame.SettingsDropdown.Icon, "questlog-icon-setting", true)
	self:EditorTooltip(frame.SettingsDropdown, SETTINGS)
	frame.SettingsDropdown:SetupMenu(function(_, menu)
		menu:CreateButton(L["CooldownPulseImport"], function() P:ShowTransfer(nil, true) end)
	end)
	frame.LayoutDropdown:Hide()
	frame.add = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.add:SetSize(126, 22); frame.add:SetPoint("BOTTOMRIGHT", -44, 4)
	local plus = addon.variables.isTBC and addon.FeatureEditorArt.Markup("communities-icon-addgroupplus", 16, 16) or CreateAtlasMarkup("communities-icon-addgroupplus", 16, 16, 0, -1)
	frame.add:SetText(plus .. " " .. L["CooldownPanelAddGroup"])
	frame.help = CreateFrame("Button", nil, frame)
	frame.help:SetSize(28, 28); frame.help:SetPoint("BOTTOMRIGHT", -10, 1)
	frame.help:SetNormalTexture("Interface\\common\\help-i")
	frame.help:SetHighlightTexture("Interface\\common\\help-i")
	self:EditorTooltip(frame.help, L["CooldownPulse"], L["CooldownPulseEditorHelp"])
	frame.add:SetScript("OnClick", function() if not InCombatLockdown() then local id = P:AddGroup(); P:RefreshOverview(); P:OpenSettings(id) end end)
	frame.empty = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.empty:SetPoint("TOPLEFT", 13, -20); frame.empty:SetWidth(318); frame.empty:SetText(L["CooldownPulseEditorHelp"])
	frame:SetScript("OnShow", function() P:RefreshOverview() end)
	frame:SetScript("OnHide", function()
		if P.editGroup then addon.EditModeLib:HideSettingsDialog(P.frames[P.editGroup]) end
		P:FinishEditing(); StaticPopup_Hide("EQOL_PULSE_ADD_SPELL"); GameTooltip:Hide()
	end)
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:SetScript("OnEvent", function() frame:Hide() end)
	addon.FeatureEditor:AttachTabs(frame, "pulse")
	return frame
end

function P:OpenEditor(id)
	if InCombatLockdown() then return end
	local frame = self.overview or self:CreateOverview()
	addon.functions.ApplySharedEditorPosition(frame); frame:Show(); self:RefreshOverview()
	if addon.functions.HideConfigCenterUntilFrameHidden then addon.functions.HideConfigCenterUntilFrameHidden(frame) end
	if id and self:Group(id) then self:DB().selectedGroup = id; self:OpenSettings(id) end
	return frame
end

StaticPopupDialogs.EQOL_PULSE_ADD_SPELL = {
	text = L["CooldownPulseSpellIDsHint"], button1 = ADD, button2 = CANCEL, hasEditBox = true, maxLetters = 2048,
	timeout = 0, whileDead = true, hideOnEscape = true,
	OnAccept = function(dialog, id)
		local box = dialog.editBox or dialog.EditBox
		for value in box:GetText():gmatch("%-?%d+") do P:AddSpell(id, tonumber(value)) end
	end,
	OnShow = function(dialog) local box = dialog.editBox or dialog.EditBox; box:SetText(""); box:SetFocus() end,
}
