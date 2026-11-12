local _, addon = ...
local M = addon.AutoRankUp
if not M then return end
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

function M:RenderEditor(parent)
 local root = self.editor
 if not root then
  root = CreateFrame("Frame", nil, parent)
  self.editor = root
  root:SetHeight(300)
  root:EnableMouse(true)
  local input = CreateFrame("EditBox", nil, root, "InputBoxTemplate")
  input:SetSize(130, 28)
  input:SetPoint("TOPLEFT", 8, -8)
  input:SetAutoFocus(false)
  input:SetNumeric(true)
  input:SetMaxLetters(10)
  input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  root.input = input
  local add = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  add:SetSize(140, 26)
  add:SetPoint("LEFT", input, "RIGHT", 12, 0)
  add:SetText(L["Add SpellID"])
  local hint = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -10)
  hint:SetPoint("RIGHT", root, "RIGHT", -12, 0)
  hint:SetJustifyH("LEFT")
  hint:SetText(L["autoRankUpDropHint"])
  root.hint = hint
  local scroll = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
  scroll.scrollBarHideable = true
  scroll.ScrollBar:Hide()
  scroll:SetPoint("TOPLEFT", 4, -76)
  scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(400, 1)
  scroll:SetScrollChild(content)
  scroll:SetScript("OnSizeChanged", function(self, width) content:SetWidth(math.max(1, width)) end)
  root.rows = {}
  function root:Refresh()
   local ids = M:GetIgnoredIDs()
   for _, row in ipairs(self.rows) do row:Hide() end
   for index, id in ipairs(ids) do
    local row = self.rows[index]
    if not row then
     row = CreateFrame("Frame", nil, content)
     row:SetHeight(30)
     row:SetPoint("TOPLEFT", 0, -(index - 1) * 32)
     row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
     row.icon = row:CreateTexture(nil, "ARTWORK")
     row.icon:SetSize(24, 24)
     row.icon:SetPoint("LEFT", 0, 0)
     row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
     row.remove:SetSize(85, 24)
     row.remove:SetPoint("RIGHT")
     row.remove:SetText(_G.REMOVE or _G.DELETE)
     row.remove:SetScript("OnClick", function() M:RemoveIgnore(row.spellID); root:Refresh() end)
     row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
     row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
     row.text:SetPoint("RIGHT", row.remove, "LEFT", -8, 0)
     row.text:SetJustifyH("LEFT")
     self.rows[index] = row
    end
    row.spellID = id
    local info = C_Spell.GetSpellInfo(id)
    local rank = C_Spell.GetSpellSubtext(id)
    row.icon:SetTexture(info and info.iconID or 134400)
    row.text:SetText(string.format("%s%s  |cffaaaaaa[%d]|r", info and info.name or L["SpellID"], rank and rank ~= "" and (" (" .. rank .. ")") or "", id))
    row:Show()
   end
   content:SetHeight(math.max(1, #ids * 32))
  end
  local function addID(id, fromCursor)
   if not M:AddIgnore(id) then hint:SetText(L["autoRankUpInvalidSpell"]); return end
   hint:SetText(L["autoRankUpDropHint"])
   input:SetText("")
   input:ClearFocus()
   if fromCursor then ClearCursor() end
   root:Refresh()
  end
  local function drop()
   local id = M:GetCursorSpellID()
   if id then addID(id, true) end
  end
  root:SetScript("OnReceiveDrag", drop)
  root:SetScript("OnMouseUp", drop)
  content:EnableMouse(true)
  content:SetScript("OnReceiveDrag", drop)
  content:SetScript("OnMouseUp", drop)
  scroll:SetScript("OnReceiveDrag", drop)
  input:SetScript("OnReceiveDrag", drop)
  input:SetScript("OnEnterPressed", function() addID(input:GetText()) end)
  add:SetScript("OnClick", function() if M:GetCursorSpellID() then drop() else addID(input:GetText()) end end)
  function root:Release() self.input:ClearFocus(); self:Hide() end
 end
 root:SetParent(parent)
 root:ClearAllPoints()
 root:SetPoint("TOPLEFT")
 root:SetPoint("TOPRIGHT")
 root.hint:SetText(L["autoRankUpDropHint"])
 root:Refresh()
 root:Show()
 return root
end

function M:RegisterSettings(category)
 local section = addon.functions.SettingsClassicUtilityBlock(L["autoRankUpEnabled"], "ranks", 500, "autoRankUp")
 addon.functions.SettingsCreateCheckbox(category, {
  var = "autoRankUpEnabled", order = 510, text = L["autoRankUpEnabled"], desc = L["autoRankUpDesc"], default = false,
  parentSection = section, newTagID = "autoRankUpEnabled",
  func = function(value) addon.db.autoRankUpEnabled = value == true; M:RequestUpdate() end,
 })
 addon.functions.SettingsCreateButton(category, {
  var = "autoRankUpNow", order = 520, text = L["autoRankUpNow"], buttonText = L["autoRankUpNow"], desc = L["autoRankUpNowDesc"],
  parentSection = section, newTagID = "autoRankUpNow",
  isEnabled = function() return addon.db and addon.db.autoRankUpEnabled == true end,
  func = function() M:RequestUpdate() end,
 })
 addon.functions.SettingsCreateCustom(category, {
  var = "autoRankUpIgnored", order = 530, text = L["autoRankUpIgnored"], parentSection = section, newTagID = "autoRankUpIgnored",
  get = function() return addon.db.autoRankUpIgnored or {} end,
  set = function(value) addon.db.autoRankUpIgnored = type(value) == "table" and value or {}; M:RequestUpdate() end,
  default = {}, getHeight = function() return 300 end,
  render = function(parent) return M:RenderEditor(parent) end,
 })
end
