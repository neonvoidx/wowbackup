-- luacheck: globals BAGS EQUIPPED
local addon = _G.EnhanceQoL
local I, API, L = addon.Inventory, addon.Inventory.API, addon.L
local W = { rows = {}, offset = 0, generation = 0, suggestions = {} }
I.SearchWindow = W
local function finish(box) if addon.BufferedPaste then addon.BufferedPaste:Finish(box) end end
local function button(parent, text, width, callback)
 local frame = CreateFrame("Button", nil, parent)
 frame:SetSize(width or 100, 24)
 local texture = frame:CreateTexture(nil, "BACKGROUND"); texture:SetAllPoints(); texture:SetColorTexture(0.12, 0.17, 0.23, 1)
 local hover = frame:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints(); hover:SetColorTexture(0.25, 0.55, 0.85, 0.25)
 local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); label:SetPoint("LEFT", 6, 0); label:SetPoint("RIGHT", -6, 0)
 label:SetWordWrap(false); label:SetText(text or ""); frame.Text = label
 frame:SetScript("OnClick", callback)
 return frame
end
local function sourceLabel(source)
 return source == "bags" and BAGS or source == "equipped" and EQUIPPED or source == "bank" and BANK or L["itemSearchInspect"]
end
local function fieldLabel(field)
 return field.labelKey and L[field.labelKey] or field.label or field.name or field.id or ""
end
local function valueText(value)
 if not I.Safe(value) then return L["itemFilterUnavailable"] end
 if value == true then return YES elseif value == false then return NO elseif value == nil then return "nil" end
 if type(value) == "table" then
  local values = {}; for key, child in pairs(value) do if I.Safe(key) and I.Safe(child) and type(child) ~= "table" then values[#values + 1] = tostring(key) .. "=" .. tostring(child) end end
  table.sort(values); return table.concat(values, ", ")
 end
 return tostring(value)
end
function W.UpdateInspector()
 local frame, selected = W.frame, W.selected
 if not frame or not selected or not frame:IsShown() then return end
 local facts, statuses, fields = API.Inspect(selected)
 local lines = {}
 for _, name in ipairs(fields) do
  local definition = addon.Items.GetField(name) or { name = name }
  local status = statuses and statuses[name]
  local value = status == "unsupported" and L["itemFilterUnavailable"] or status == "pending" and L["itemFilterPending"] or status == "missing" and L["itemSearchMissing"] or valueText(facts[name])
  lines[#lines + 1] = fieldLabel(definition) .. " (" .. name .. "): " .. value
 end
 frame.details:SetText(table.concat(lines, "\n\n"))
 frame.details:SetHeight(math.max(1, frame.details:GetStringHeight() + 12))
 frame.detailContent:SetHeight(frame.details:GetHeight())
end
function W.Select(item)
 W.selected = item
 W.frame.detailTitle:SetText(L["itemSearchInspect"] .. " · " .. tostring(item.itemID))
 W.frame.inspector:Show()
 W.Layout()
 API.Inspect(item, function() if W.selected == item then W.UpdateInspector() end end)
 W.UpdateInspector()
end
function W.RenderRows()
 local frame = W.frame
 if not frame then return end
 local first = math.floor(W.offset)
 for index, row in ipairs(frame.rows) do
  local data = W.rows[first + index]
  row.data = data
  row:SetShown(data ~= nil and index <= W.visibleRows)
  if data then
   local item = data.item
   local facts = addon.Items.Get(item, { "name", "quality", "icon" }, I.Context(item))
   row.Icon:SetTexture(facts.icon or 134400)
   row.Name:SetText(facts.name or item.link or tostring(item.itemID))
   row.Count:SetText(tostring(item.count or 1))
   row.Location:SetText(sourceLabel(item.source))
  end
 end
end
local function row(parent, index)
 local frame = button(parent, "", 100, function(self) if self.data then W.Select(self.data.item) end end)
 frame:SetHeight(36); frame:SetPoint("TOPLEFT", 0, -(index - 1) * 38); frame:SetPoint("TOPRIGHT", -18, -(index - 1) * 38)
 frame.Icon = frame:CreateTexture(nil, "ARTWORK"); frame.Icon:SetSize(28, 28); frame.Icon:SetPoint("LEFT", 4, 0)
 frame.Name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.Name:SetPoint("LEFT", 40, 0); frame.Name:SetPoint("RIGHT", -160, 0); frame.Name:SetJustifyH("LEFT"); frame.Name:SetWordWrap(false)
 frame.Location = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); frame.Location:SetPoint("RIGHT", -40, 0); frame.Location:SetWidth(112); frame.Location:SetJustifyH("RIGHT"); frame.Location:SetWordWrap(false)
 frame.Count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.Count:SetPoint("RIGHT", -8, 0)
 frame:SetScript("OnEnter", function(self)
  if not self.data then return end
  local item = self.data.item
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if item.link then GameTooltip:SetHyperlink(item.link) elseif GameTooltip.SetItemByID then GameTooltip:SetItemByID(item.itemID) end
  GameTooltip:Show()
 end)
 frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
 return frame
end
function W.Layout()
 local frame = W.frame
 if not frame then return end
 local inspectorWidth = frame.inspector:IsShown() and 300 or 0
 frame.resultArea:ClearAllPoints(); frame.resultArea:SetPoint("TOPLEFT", 18, -158); frame.resultArea:SetPoint("BOTTOMRIGHT", -18 - inspectorWidth, 55)
 W.visibleRows = math.max(1, math.floor(frame.resultArea:GetHeight() / 38))
 for index = #frame.rows + 1, W.visibleRows do frame.rows[index] = row(frame.resultArea, index) end
 frame.scroll:SetMinMaxValues(0, math.max(0, #W.rows - W.visibleRows))
 frame.scroll:SetShown(#W.rows > W.visibleRows)
 W.offset = math.min(W.offset, math.max(0, #W.rows - W.visibleRows)); frame.scroll:SetValue(W.offset)
 frame.detailContent:SetWidth(math.max(1, frame.detailScroll:GetWidth() - 4)); frame.details:SetWidth(math.max(1, frame.detailContent:GetWidth() - 8))
 W.RenderRows()
end
function W.Refresh()
 local frame = W.frame
 if not frame or not frame:IsShown() or not addon.Items then return end
 W.generation = W.generation + 1
 local generation = W.generation
 finish(frame.search)
 local function ready()
  if generation ~= W.generation or not frame:IsShown() or W.refreshScheduled then return end
  W.refreshScheduled = true
  C_Timer.After(0.05, function() W.refreshScheduled = nil; if generation == W.generation then W.Refresh() end end)
 end
 local result = API.Search(frame.search:GetText(), { source = W.source or "all", inspect = W.inspect, request = true, onReady = ready })
 if result.error then
  frame.status:SetText(L["itemFilterError"]:format(result.error.position or 1, rawget(L, "ItemsError_" .. (result.error.code or "")) or L["itemFilterInvalid"]))
  W.rows = {}
 else
  W.rows = result.matches
  frame.status:SetText(L["itemSearchSummary"]:format(#result.matches, result.total or 0, #result.unresolved))
  if W.source == "bank" and not I.state.bankOpen then frame.status:SetText(L["itemSearchBankClosed"]) end
  -- Result names are display metadata, not dependencies of an ID-only filter.
  for _, data in ipairs(W.rows) do
   local _, statuses = addon.Items.Get(data.item, { "name", "icon" }, I.Context(data.item))
   if statuses.name == "pending" or statuses.name == "missing" then
    addon.Items.Request(data.item, { "name", "icon" }, I.Context(data.item), function(_, updated)
     if updated and updated.name == "known" then ready() end
    end)
   end
  end
 end
 if W.selected and W.selected.source ~= "inspect" then
  local previous = W.selected; W.selected = nil
  for _, data in ipairs(W.rows) do
   local item = data.item
   if item.itemID == previous.itemID and item.link == previous.link and item.source == previous.source
    and item.bagID == previous.bagID and item.slotID == previous.slotID and item.inventorySlot == previous.inventorySlot then W.selected = item; break end
  end
  if not W.selected then frame.inspector:Hide() end
 end
 W.Layout(); W.UpdateInspector()
end
function W.Schedule()
 if W.timer then W.timer:Cancel() end
 W.timer = C_Timer.NewTimer(0.15, function() W.timer = nil; W.Refresh() end)
end
function W.AcceptSuggestion(index)
 local suggestion = W.suggestions[index]
 if not suggestion then return end
 local box = W.frame.search; finish(box)
 local text = box:GetText(); local first, last = suggestion.from or box:GetCursorPosition(), suggestion.to or box:GetCursorPosition()
 local inserted = suggestion.insertText or suggestion.label
 W.settingText = true; box:SetText(text:sub(1, first) .. inserted .. text:sub(last + 1)); box:SetCursorPosition(first + #inserted); W.settingText = nil
 box:SetFocus(); W.UpdateSuggestions(); W.Schedule()
end
function W.UpdateSuggestions()
 local frame = W.frame
 W.suggestions = frame.search:HasFocus() and addon.Items.Complete(frame.search:GetText(), frame.search:GetCursorPosition(), {}) or {}
 for index, entry in ipairs(frame.suggestions) do
  local suggestion = W.suggestions[index]
  entry:SetShown(suggestion ~= nil)
  if suggestion then entry.Text:SetText(suggestion.label or suggestion.insertText) end
 end
end
local function menu(anchor, build)
 if MenuUtil and MenuUtil.CreateContextMenu then MenuUtil.CreateContextMenu(anchor, build); return end
 if not UIDropDownMenu_Initialize then return end
 local options = {}
 local root = { SetScrollMode = function() end }
 function root:CreateButton(text, callback) options[#options + 1] = { text = text, callback = callback }; return {} end
 function root:CreateRadio(text, checked, callback) options[#options + 1] = { text = text, checked = checked, callback = callback }; return {} end
 build(nil, root)
 if not anchor.menu then anchor.menu = CreateFrame("Frame", nil, anchor, "UIDropDownMenuTemplate") end
 UIDropDownMenu_Initialize(anchor.menu, function()
  for _, entry in ipairs(options) do
   local info = UIDropDownMenu_CreateInfo(); info.text = entry.text; info.func = entry.callback
   info.notCheckable = entry.checked == nil; info.checked = entry.checked and entry.checked() or false
   UIDropDownMenu_AddButton(info)
  end
 end)
 ToggleDropDownMenu(1, nil, anchor.menu, anchor, 0, 0)
end
function W.Create()
 if W.frame then return W.frame end
 local frame = CreateFrame("Frame", "EQOLItemSearch", UIParent, "BackdropTemplate")
 W.frame = frame; frame:SetSize(920, 650); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:Hide()
 frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }); frame:SetBackdropColor(0.025, 0.035, 0.055, 1); frame:SetBackdropBorderColor(0.2, 0.3, 0.42, 1)
 frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
 local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 18, -14); title:SetText(L["InventorySearchTitle"])
 local close = button(frame, CLOSE, 60, function() frame:Hide() end); close:SetPoint("TOPRIGHT", -12, -10)
 local search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate"); search:SetPoint("TOPLEFT", 22, -50); search:SetPoint("TOPRIGHT", -112, -50); search:SetHeight(28); search:SetAutoFocus(false); search:SetFontObject("GameFontHighlightSmall")
 frame.search = search
 local execute = button(frame, SEARCH, 80, function() finish(search); W.Refresh() end); execute:SetPoint("TOPRIGHT", -18, -50)
 local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); hint:SetPoint("TOPLEFT", 18, -84); hint:SetPoint("TOPRIGHT", -18, -84); hint:SetJustifyH("LEFT"); hint:SetText(L["itemSearchHint"])
 local source = button(frame, L["itemSearchCurrent"], 150, function(self)
  menu(self, function(_, root)
   for _, entry in ipairs(API.GetSources()) do
    root:CreateRadio(entry.label or entry.value, function() return (W.source or "all") == entry.value end, function() W.source = entry.value; self.Text:SetText(entry.label); W.offset = 0; W.Refresh() end)
   end
  end)
 end); source:SetPoint("TOPLEFT", 18, -115)
 -- Declaration precedes closure use on legacy Lua clients.
 frame.source = source
 local fields = button(frame, L["itemFilterAdd"], 140, function(self)
  menu(self, function(_, root)
   if root.SetScrollMode then root:SetScrollMode(350) end
   for _, definition in ipairs(addon.Items.ListFields()) do
    if definition.supported ~= false and not definition.hidden then
     root:CreateButton(fieldLabel(definition), function()
      finish(search); local text = search:GetText(); search:SetText(text .. (text ~= "" and " AND " or "") .. (definition.name or definition.id) .. " = "); search:SetFocus(); W.UpdateSuggestions()
     end)
    end
   end
  end)
 end); fields:SetPoint("LEFT", source, "RIGHT", 8, 0)
 local inspect = button(frame, L["itemSearchInspect"], 160, function(self) W.inspect = not W.inspect; self.Text:SetText((W.inspect and "[x] " or "") .. L["itemSearchInspect"]); W.Refresh() end); inspect:SetPoint("LEFT", fields, "RIGHT", 8, 0)
 local saved = button(frame, L["InventorySearchSaved"], 170, function(self)
  menu(self, function(_, root)
   for _, entry in ipairs(API.ListSavedSearches()) do
    root:CreateButton(entry.name, function()
     if entry.unavailable then frame.status:SetText(L["itemFilterReadOnly"]); return end
     W.savedID = entry.id; frame.saveName:SetText(entry.name)
     search:SetText(addon.Items.Format(entry.query)); W.offset = 0; W.Refresh()
    end)
   end
  end)
 end); saved:SetPoint("LEFT", inspect, "RIGHT", 8, 0)
 frame.resultArea = CreateFrame("Frame", nil, frame); frame.resultArea:EnableMouseWheel(true); frame.resultArea:SetScript("OnMouseWheel", function(_, delta) frame.scroll:SetValue(math.max(0, math.min(#W.rows - W.visibleRows, W.offset - delta * 3))) end)
 frame.rows = {}
 frame.scroll = CreateFrame("Slider", nil, frame.resultArea); frame.scroll:SetWidth(12); frame.scroll:SetPoint("TOPRIGHT", 0, 0); frame.scroll:SetPoint("BOTTOMRIGHT", 0, 0); frame.scroll:SetOrientation("VERTICAL"); frame.scroll:SetMinMaxValues(0, 1); frame.scroll:SetValueStep(1)
 frame.scroll:SetThumbTexture("Interface\\Buttons\\WHITE8x8"); frame.scroll:GetThumbTexture():SetSize(12, 28); frame.scroll:GetThumbTexture():SetVertexColor(0.4, 0.75, 1, 1)
 frame.scroll:SetScript("OnValueChanged", function(_, value) W.offset = math.floor(value); W.RenderRows() end)
 frame.inspector = CreateFrame("Frame", nil, frame); frame.inspector:SetWidth(285); frame.inspector:SetPoint("TOPRIGHT", -18, -158); frame.inspector:SetPoint("BOTTOMRIGHT", -18, 55); frame.inspector:Hide()
 frame.detailTitle = frame.inspector:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.detailTitle:SetPoint("TOPLEFT", 0, 0)
 local dismiss = button(frame.inspector, CLOSE, 50, function() W.selected = nil; frame.inspector:Hide(); W.Layout() end); dismiss:SetPoint("TOPRIGHT", 0, 0)
 frame.detailScroll = CreateFrame("ScrollFrame", nil, frame.inspector); frame.detailScroll:SetPoint("TOPLEFT", 0, -32); frame.detailScroll:SetPoint("BOTTOMRIGHT"); frame.detailScroll:SetClipsChildren(true); frame.detailScroll:EnableMouseWheel(true)
 frame.detailContent = CreateFrame("Frame", nil, frame.detailScroll); frame.detailContent:SetSize(270, 1); frame.detailScroll:SetScrollChild(frame.detailContent)
 frame.details = frame.detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.details:SetPoint("TOPLEFT", 4, 0); frame.details:SetJustifyH("LEFT"); frame.details:SetWordWrap(true)
 frame.detailScroll:SetScript("OnMouseWheel", function(self, delta) self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 30))) end)
 frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); frame.status:SetPoint("BOTTOMLEFT", 18, 37); frame.status:SetPoint("RIGHT", -18, 0); frame.status:SetJustifyH("LEFT")
 frame.saveName = CreateFrame("EditBox", nil, frame, "InputBoxTemplate"); frame.saveName:SetSize(210, 24); frame.saveName:SetPoint("BOTTOMLEFT", 22, 8); frame.saveName:SetAutoFocus(false)
 local save = button(frame, SAVE, 75, function() finish(search); local id = API.SaveSearch(frame.saveName:GetText(), search:GetText(), nil, W.savedID); if id then W.savedID = id; frame.status:SetText(L["itemFilterSaved"]) else frame.status:SetText(L["InventorySearchSaveFailed"]) end end); save:SetPoint("LEFT", frame.saveName, "RIGHT", 8, 0)
 local delete = button(frame, DELETE, 75, function() if W.savedID and API.DeleteSavedSearch(W.savedID) then W.savedID = nil; frame.saveName:SetText("") end end); delete:SetPoint("LEFT", save, "RIGHT", 8, 0)
 frame.suggestions = {}
 for index = 1, 6 do
  local entry = button(frame, "", 360, function() W.AcceptSuggestion(index) end); entry:SetFrameLevel(frame:GetFrameLevel() + 10); entry:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -(index - 1) * 25); entry:Hide(); frame.suggestions[index] = entry
 end
 search:SetScript("OnTextChanged", function() if not W.settingText then W.offset = 0; W.UpdateSuggestions(); W.Schedule() end end)
 search:SetScript("OnCursorChanged", function() W.UpdateSuggestions() end)
 search:SetScript("OnEnterPressed", function(self) finish(self); self:ClearFocus(); W.UpdateSuggestions(); W.Refresh() end)
 search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); W.UpdateSuggestions() end)
 search:SetScript("OnTabPressed", function() W.AcceptSuggestion(1) end)
 search:SetScript("OnEditFocusLost", function() W.UpdateSuggestions() end)
 if addon.BufferedPaste then addon.BufferedPaste:Attach(search); addon.BufferedPaste:Attach(frame.saveName) end
 frame:SetScript("OnShow", function() W.Layout(); W.Refresh() end)
 frame:SetScript("OnHide", function() W.generation = W.generation + 1; if W.timer then W.timer:Cancel(); W.timer = nil end; finish(search); search:ClearFocus(); frame.saveName:ClearFocus(); GameTooltip:Hide() end)
 if UISpecialFrames then UISpecialFrames[#UISpecialFrames + 1] = "EQOLItemSearch" end
 return frame
end
function W.Open(query)
 if not addon.Items then return false end
 local frame = W.Create()
 if query ~= nil then finish(frame.search); frame.search:SetText(query) end
 frame:Show(); frame.search:SetFocus(); return true
end
function W.Toggle() if W.frame and W.frame:IsShown() then W.frame:Hide() else W.Open() end end
SLASH_EQOLINVENTORYSEARCH1 = "/eqolinv"
SLASH_EQOLINVENTORYSEARCH2 = "/eqolitems"
SlashCmdList.EQOLINVENTORYSEARCH = function(query) if not query or query:match("^%s*$") then W.Toggle() else W.Open(query) end end
