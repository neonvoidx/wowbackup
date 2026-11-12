local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Editor = {
	keys = { "vendorIncludeSellList", "vendorExcludeSellList", "vendorIncludeDestroyList" },
	labels = { "vendorListSell", "vendorListKeep", "vendorListDestroy" },
	colors = { { 0.95, 0.75, 0.2 }, { 0.3, 0.85, 0.5 }, { 0.95, 0.35, 0.25 } },
}

function Editor.RefreshRuntime()
	addon.Vendor.functions.refreshSellMarks()
	addon.Vendor.functions.refreshDestroyButton()
end

function Editor.Refresh()
	if not Editor.frame or not Editor.frame:IsShown() then return end
	for _, column in ipairs(Editor.columns) do
		local entries = {}
		local total = 0
		local query = Editor.query or ""
		for id, name in pairs(addon.db[column.key] or {}) do
			total = total + 1
			name = name or tostring(id)
			if query == "" or name:lower():find(query, 1, true) or tostring(id):find(query, 1, true) then
				entries[#entries + 1] = { id = id, name = name }
			end
		end
		table.sort(entries, function(a, b)
			if a.name == b.name then return a.id < b.id end
			return a.name < b.name
		end)
		column.offset = math.max(0, math.min(column.offset, math.max(0, #entries - #column.rows)))
		if query == "" then
			column.title:SetText(string.format("%s (%d)", L[column.label], total))
		else
			column.title:SetText(string.format("%s (%d/%d)", L[column.label], #entries, total))
		end
		for index, row in ipairs(column.rows) do
			local entry = entries[index + column.offset]
			row.itemID = entry and entry.id
			if entry then
				row.icon:SetTexture(C_Item.GetItemIconByID(entry.id))
				row.text:SetText(entry.name)
				row:Show()
			else
				row:Hide()
			end
		end
	end
end

function Editor.Assign(db, key, itemID, name)
	if addon.db ~= db then return end
	for _, listKey in ipairs(Editor.keys) do
		if db[listKey] then db[listKey][itemID] = nil end
	end
	db[key] = db[key] or {}
	db[key][itemID] = name
	Editor.RefreshRuntime()
	Editor.Refresh()
end

function Editor.SetDropTarget(column)
	if Editor.dropTarget == column then return end
	if Editor.dropTarget then
		Editor.dropTarget.DropHighlight:Hide()
		Editor.dropTarget:SetBackdropColor(0.06, 0.07, 0.09, 0.95)
	end
	Editor.dropTarget = column
	if column then
		local color = column.color
		column.DropHighlight:Show()
		column:SetBackdropColor(color[1] * 0.2, color[2] * 0.2, color[3] * 0.2, 0.95)
	end
end

function Editor.UpdateDropTarget()
	local cursorType = GetCursorInfo()
	if not Editor.drag and cursorType ~= "item" then
		Editor.SetDropTarget(nil)
		return
	end
	for _, column in ipairs(Editor.columns) do
		if addon.functions.MouseIsOver(column) then
			Editor.SetDropTarget(column)
			return
		end
	end
	Editor.SetDropTarget(nil)
end

function Editor.CancelDrag()
	Editor.SetDropTarget(nil)
	Editor.drag = nil
	if Editor.dragIcon then Editor.dragIcon:Hide() end
end

function Editor.UpdateDragIcon()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	Editor.dragIcon:ClearAllPoints()
	Editor.dragIcon:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + 14, y / scale - 14)
end

function Editor.StartDrag(row, column)
	if not row.itemID or CursorHasItem() then return end
	local source = addon.db[column.key]
	if not source or not source[row.itemID] then return end
	Editor.drag = { itemID = row.itemID, sourceKey = column.key, db = addon.db }
	GameTooltip:Hide()
	if not Editor.dragIcon then
		local icon = CreateFrame("Frame", nil, UIParent)
		Editor.dragIcon = icon
		icon:SetSize(28, 28)
		icon:SetFrameStrata("TOOLTIP")
		icon:EnableMouse(false)
		icon.texture = icon:CreateTexture(nil, "OVERLAY")
		icon.texture:SetAllPoints()
		icon:SetScript("OnUpdate", Editor.UpdateDragIcon)
	end
	Editor.dragIcon.texture:SetTexture(C_Item.GetItemIconByID(row.itemID))
	Editor.UpdateDragIcon()
	Editor.dragIcon:Show()
end

function Editor.StopDrag()
	if not Editor.drag then return end
	for _, column in ipairs(Editor.columns) do
		if addon.functions.MouseIsOver(column) then
			Editor.Receive(column)
			break
		end
	end
	Editor.CancelDrag()
end

function Editor.Receive(column)
	if Editor.drag then
		local drag = Editor.drag
		Editor.CancelDrag()
		local source = drag.db[drag.sourceKey]
		if addon.db == drag.db and source and source[drag.itemID] then
			Editor.Assign(drag.db, column.key, drag.itemID, source[drag.itemID])
		end
		return
	end
	local cursorType, itemID = GetCursorInfo()
	if cursorType ~= "item" or not itemID then return end
	local item = Item:CreateFromItemID(itemID)
	if not item or item:IsItemEmpty() then return end
	-- Return the carried item to its bag; list assignments never consume items.
	ClearCursor()
	local db = addon.db
	item:ContinueOnItemLoad(function()
		Editor.Assign(db, column.key, itemID, item:GetItemName() or tostring(itemID))
	end)
end

function Editor.CreateColumn(frame, index)
	local color = Editor.colors[index]
	local column = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	column:SetSize(270, 374)
	column:SetPoint("TOPLEFT", 18 + (index - 1) * 282, -104)
	column:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	column:SetBackdropColor(0.06, 0.07, 0.09, 0.95)
	column:SetBackdropBorderColor(color[1], color[2], color[3], 0.7)
	column.color = color
	column.DropHighlight = CreateFrame("Frame", nil, column, "BackdropTemplate")
	column.DropHighlight:SetAllPoints()
	column.DropHighlight:EnableMouse(false)
	column.DropHighlight:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 3 })
	column.DropHighlight:SetBackdropBorderColor(color[1], color[2], color[3], 1)
	column.DropHighlight:Hide()
	column.key, column.label, column.offset, column.rows = Editor.keys[index], Editor.labels[index], 0, {}
	column.title = column:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	column.title:SetPoint("TOP", 0, -12)
	column.title:SetTextColor(color[1], color[2], color[3])
	column:EnableMouse(true)
	column:EnableMouseWheel(true)
	column:SetScript("OnReceiveDrag", function() Editor.Receive(column) end)
	column:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then Editor.Receive(column) end
	end)
	column:SetScript("OnMouseWheel", function(_, delta)
		column.offset = math.max(0, column.offset - delta * 3)
		Editor.Refresh()
	end)
	for rowIndex = 1, 10 do
		local row = CreateFrame("Button", nil, column)
		row:SetSize(250, 30)
		row:SetPoint("TOPLEFT", 10, -36 - (rowIndex - 1) * 32)
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function(self) Editor.StartDrag(self, column) end)
		row:SetScript("OnDragStop", Editor.StopDrag)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(26, 26)
		row.icon:SetPoint("LEFT")
		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.text:SetPoint("RIGHT", -2, 0)
		row.text:SetJustifyH("LEFT")
		row:SetScript("OnReceiveDrag", function() Editor.Receive(column) end)
		row:SetScript("OnClick", function(self, button)
			if button == "LeftButton" then
				Editor.Receive(column)
			elseif self.itemID and addon.db[column.key] then
				addon.db[column.key][self.itemID] = nil
				GameTooltip:Hide()
				Editor.RefreshRuntime()
				Editor.Refresh()
			end
		end)
		row:SetScript("OnEnter", function(self)
			if not self.itemID then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:" .. self.itemID)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		column.rows[rowIndex] = row
	end
	return column
end

function addon.Vendor.functions.OpenListEditor()
	if not Editor.frame then
		local frame = CreateFrame("Frame", "EQOLVendorListEditor", UIParent, "BackdropTemplate")
		Editor.frame = frame
		frame:SetSize(870, 498)
		frame:SetPoint("CENTER")
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame:SetBackdropColor(0.025, 0.03, 0.045, 0.98)
		frame:SetBackdropBorderColor(0.3, 0.32, 0.38, 1)
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame.title:SetPoint("TOPLEFT", 18, -16)
		frame.title:SetText(L["vendorListEditor"])
		frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		frame.hint:SetPoint("TOPLEFT", 18, -42)
		frame.hint:SetPoint("TOPRIGHT", -18, -42)
		frame.hint:SetJustifyH("LEFT")
		frame.hint:SetText(L["vendorListEditorHint"])
		frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		frame.close:SetPoint("TOPRIGHT", -3, -3)
		Editor.columns = {}
		for index = 1, #Editor.keys do Editor.columns[index] = Editor.CreateColumn(frame, index) end
		frame.searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.searchLabel:SetPoint("LEFT", frame, "TOPLEFT", 18, -78)
		frame.searchLabel:SetText(_G.SEARCH)
		frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		frame.search:SetSize(650, 24)
		frame.search:SetPoint("LEFT", frame, "TOPLEFT", 196, -78)
		frame.search:SetAutoFocus(false)
		frame.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		frame.search:SetScript("OnTextChanged", function(self)
			Editor.CancelDrag()
			Editor.query = (self:GetText() or ""):lower()
			for _, column in ipairs(Editor.columns) do column.offset = 0 end
			Editor.Refresh()
		end)
		frame:SetScript("OnHide", Editor.CancelDrag)
		frame:SetScript("OnShow", Editor.Refresh)
		frame:SetScript("OnEvent", Editor.Refresh)
		frame:SetScript("OnUpdate", Editor.UpdateDropTarget)
		frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		table.insert(UISpecialFrames, "EQOLVendorListEditor")
	end
	Editor.frame:Show()
	Editor.Refresh()
end

hooksecurefunc(addon.Vendor.functions, "refreshSellMarks", Editor.Refresh)
