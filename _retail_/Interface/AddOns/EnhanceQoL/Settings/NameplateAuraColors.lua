local _, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local runtime = addon.NameplateAuraColors
if not (runtime and runtime.IsSupported and runtime.IsSupported()) then return end
local function changed() runtime.Refresh() end
local A = { class = select(2, UnitClass("player")), visibleRows = 8, rowHeight = 40, tableHeight = 386 }
local presets = {
	DEATHKNIGHT = { 191587, 55078 }, DEMONHUNTER = { 1490 }, DRUID = { 164812, 164815, 155722, 1079 },
	EVOKER = { 357209 }, HUNTER = { 257284, 271788 }, MAGE = { 210824 }, MONK = { 123725 },
	PALADIN = { 197277 }, PRIEST = { 589, 34914 }, ROGUE = { 703, 1943 }, SHAMAN = { 188389 },
	WARLOCK = { 172, 980, 348, 316099, 48181 }, WARRIOR = { 772, 208086 },
}
-- Retail presets contain target aura IDs, including talent-specific alternatives.
-- Keep the classic list separate: identical spell IDs can have different meanings.
if not (addon.variables and addon.variables.isForever) then
	presets = {
		DEATHKNIGHT = { 55078, 55095, 191587, 1240996 }, -- Blood/Frost/Virulent/Dread Plague
		DEMONHUNTER = { 1490, 207771, 320338, 1241532 }, -- Chaos Brand, Fiery Brand, Essence Break, Devourer's Bite
		DRUID = { 164812, 164815, 155722, 1079, 192090 }, -- Moonfire (including Lunar Inspiration), Sunfire, Rake, Rip, Thrash
		EVOKER = { 357209, 409560 }, -- Fire Breath, Temporal Wound
		HUNTER = { 257284, 217200, 468572, 466872, 1253601, 269747 }, -- Hunter's Mark, Barbed Shot, Black Arrow, Spotter's/Sentinel's Mark, Wildfire Bomb (including Shrapnel Bomb)
		MAGE = { 210824, 12654, 1221389 }, -- Touch of the Magi, Ignite, Freezing
		MONK = { 123725, 113746 }, -- Breath of Fire, Mystic Touch
		PALADIN = { 197277, 383346 }, -- Judgment, Expurgation
		PRIEST = { 589, 34914, 335467, 14914 }, -- Shadow Word: Pain, Vampiric Touch, Shadow Word: Madness, Holy Fire
		ROGUE = { 703, 1943 }, -- Garrote, Rupture
		SHAMAN = { 188389, 334168 }, -- Flame Shock, Lashing Flames
		WARLOCK = { 146739, 980, 157736, 1259790, 48181, 445474, 460553 }, -- Corruption, Agony, Immolate, Unstable Affliction, Haunt, Wither, Doom
		WARRIOR = { 388539, 208086 }, -- Rend, Colossus Smash
	}
end
-- Presets must match the current client's spell database.
if C_Spell and C_Spell.DoesSpellExist then
	if addon.variables and addon.variables.isForever then
		for _, id in ipairs({ 316099, 30108 }) do
			if C_Spell.DoesSpellExist(id) then presets.WARLOCK[4] = id; break end
		end
	end
	for _, ids in pairs(presets) do
		for i = #ids, 1, -1 do if not C_Spell.DoesSpellExist(ids[i]) then table.remove(ids, i) end end
	end
end
local classOrder = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" }
if addon.variables and (addon.variables.isForever or addon.variables.isTBC) then
	classOrder = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
end
local function text(key) return L["nameplateAuraColors" .. key] end
local function spellLabel(id)
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
	local name, icon = info and info.name, info and info.iconID
	if not name and GetSpellInfo then
		local legacyName, _, legacyIcon = GetSpellInfo(id)
		name, icon = legacyName, legacyIcon
	end
	return (icon and ("|T" .. icon .. ":16|t ") or "") .. (name or tostring(id))
end
local function database()
	if type(addon.db.nameplateAuraColorRules) ~= "table" then addon.db.nameplateAuraColorRules = { version = 1, enabled = false, classes = {} } end
	local db = addon.db.nameplateAuraColorRules
	db.classes = db.classes or {}
	return db
end
local function newRule(ids)
	return { enabled = false, onlyMine = true, spells = ids, health = true, border = false, healthColor = { 0.2, 0.65, 1, 1 }, borderColor = { 1, 0.55, 0, 1 } }
end
function addon.functions.ResetNameplateAuraColors()
	local db = addon.db.nameplateAuraColorRules
	if type(db) ~= "table" or type(db.classes) ~= "table" then return end
	local function resetProfile(p)
		if type(p) ~= "table" or type(p.rules) ~= "table" then return end
		for _, rule in ipairs(p.rules) do
			if type(rule) == "table" then
				local defaults = newRule({})
				rule.healthColor, rule.borderColor = defaults.healthColor, defaults.borderColor
			end
		end
	end
	for _, p in pairs(db.classes) do
		resetProfile(p)
		if type(p) == "table" and type(p.specs) == "table" then
			for _, spec in pairs(p.specs) do resetProfile(spec) end
		end
	end
	changed()
	if A.root then A.root:Refresh() end
end
local function classProfile()
	local db = database()
	if not db.classes[A.class] then
		local p = { rules = {}, custom = {} }
		for _, id in ipairs(presets[A.class] or {}) do p.rules[#p.rules + 1] = newRule({ id }) end
		db.classes[A.class] = p
	end
	local p = db.classes[A.class]
	runtime.MigrateProfile(p)
	return p
end
local function profile()
	local p = classProfile()
	local spec = A.spec and p.specs and p.specs[A.spec]
	if spec and spec.useOwn then runtime.MigrateProfile(spec); return spec end
	return p
end
function A.CanEdit()
	local p = classProfile()
	return not not (database().enabled == true and (not A.spec or p.specs and p.specs[A.spec] and p.specs[A.spec].useOwn == true))
end
function A.SetSpecEnabled(enabled)
	if not A.spec then return end
	local p = classProfile()
	p.specs = p.specs or {}
	if enabled and not p.specs[A.spec] then
		local function copy(value)
			if type(value) ~= "table" then return value end
			local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
		end
		p.specs[A.spec] = {rules = copy(p.rules), custom = copy(p.custom)}
	end
	if p.specs[A.spec] then p.specs[A.spec].useOwn = enabled == true end
	changed()
end
function A.SpecOptions(token)
	local result = {}
	if addon.variables and addon.variables.isForever then return result end
	if not (GetClassInfo and GetSpecializationInfoForClassID and C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID) then return result end
	for classID = 1, 13 do
		local _, classToken = GetClassInfo(classID)
		if classToken == token then
			for index = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
				local id, name, _, icon = GetSpecializationInfoForClassID(classID, index)
				if id and name then result[#result + 1] = {id = id, name = name, label = (icon and ("|T" .. icon .. ":16|t ") or "") .. name} end
			end
			break
		end
	end
	table.sort(result, function(a, b) return a.name < b.name end)
	return result
end
function A.CanEnable(p, r)
	if not r or #r.spells == 0 then return false end
	if r.enabled then return true end
	local count = 0
	for _, entry in ipairs(p.rules) do if entry.enabled then count = count + 1 end end
	return count < 16
end
function A.Enable(p, r, value)
	r.enabled = value and A.CanEnable(p, r) or false
	changed()
end
function A.SelectSpell(r, id, selected)
	id = runtime.CanonicalSpellID(id)
	local index
	for i, value in ipairs(r.spells) do if value == id then index = i end end
	if selected and not index and #r.spells < 5 then r.spells[#r.spells + 1] = id
	elseif not selected and index then table.remove(r.spells, index) end
	if #r.spells == 0 then r.enabled = false end
	changed()
end
function A.AddSpell(p, r, value)
	local id = tonumber(value)
	if not id or id < 1 or id % 1 ~= 0 or not (C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id) or GetSpellInfo and GetSpellInfo(id)) then return false end
	id = runtime.CanonicalSpellID(id)
	for _, known in ipairs(r.spells) do if known == id then return true end end
	if #r.spells >= 5 then return false end
	local found = false
	for _, known in ipairs(p.custom) do if known == id then found = true end end
	if not found then p.custom[#p.custom + 1] = id end
	A.SelectSpell(r, id, true)
	return true
end
function A.Move(p, from, to)
	if not p.rules[from] or not p.rules[to] or from == to then return end
	table.insert(p.rules, to, table.remove(p.rules, from))
	changed()
end
function A.Delete(p, index) table.remove(p.rules, index); changed() end
function A.Add(p) p.rules[#p.rules + 1] = newRule({}); changed() end
function A.Candidates(p, class)
	local list, order, seen = {}, {}, {}
	local function add(id)
		id = runtime.CanonicalSpellID(id)
		if not seen[id] then seen[id] = true; list[id] = spellLabel(id); order[#order + 1] = id end
	end
	for _, id in ipairs(presets[class] or {}) do add(id) end
	for _, id in ipairs(p.custom) do add(id) end
	for _, r in ipairs(p.rules) do for _, id in ipairs(r.spells) do add(id) end end
	return list, order
end
function A.UnusedCustom(p, class)
	local used, list, order = {}, {}, {}
	for _, id in ipairs(presets[class] or {}) do used[id] = true end
	for _, r in ipairs(p.rules) do for _, id in ipairs(r.spells) do used[id] = true end end
	for _, id in ipairs(p.custom) do
		if not used[id] then used[id] = true; list[id] = spellLabel(id); order[#order + 1] = id end
	end
	return list, order
end
function A.DeleteCustom(p, class, id)
	local unused = A.UnusedCustom(p, class)
	if not unused[id] then return false end
	for i = #p.custom, 1, -1 do if p.custom[i] == id then table.remove(p.custom, i) end end
	changed()
	return true
end
local function label(r)
	local names = {}
	for _, id in ipairs(r.spells) do names[#names + 1] = spellLabel(id) end
	return #names > 0 and table.concat(names, " + ") or text("EmptyRule")
end
local function tooltip(frame, title)
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(type(title) == "function" and title() or title, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local function button(parent, width, caption)
	local ui = addon.LibSettingsDesigner.UI
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(width, 26)
	b.Text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.Text:SetPoint("LEFT", 4, 0); b.Text:SetPoint("RIGHT", -4, 0)
	b.Text:SetWordWrap(false)
	function b:SetText(value) self.Text:SetText(value) end
	b:SetText(caption or "")
	b._eqolOwner, b._eqolNormalBg, b._eqolNormalBorder = parent, ui.ThemeColors.buttonBg, ui.ThemeColors.buttonBorder
	b._eqolBorderStyleKey = "button"
	ui.ApplyFlatButtonVisual(b)
	b:SetScript("OnEnable", function(self) ui.ApplyFlatButtonVisual(self) end)
	b:SetScript("OnDisable", function(self) ui.ApplyFlatButtonVisual(self) end)
	return b
end
local function toggle(parent, title)
	local b = button(parent, 26)
	b.mark = b:CreateTexture(nil, "OVERLAY")
	b.mark:SetSize(20, 20); b.mark:SetPoint("CENTER")
	b.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	function b:SetChecked(value) self.mark:SetShown(value == true) end
	tooltip(b, title)
	return b
end
local function colorButton(parent, channel, title)
	local b = button(parent, 28)
	b.fill = b:CreateTexture(nil, "ARTWORK")
	b.fill:SetPoint("TOPLEFT", 4, -4); b.fill:SetPoint("BOTTOMRIGHT", -4, 4)
	tooltip(b, title)
	b:SetScript("OnClick", function()
		local r = parent.rule
		if not (database().enabled and r.enabled and r[channel]) then return end
		local key = channel .. "Color"
		local c = r[key]
		local function apply(red, green, blue, alpha) r[key] = { red, green, blue, alpha or c[4] or 1 }; changed(); if parent:IsShown() and parent.rule == r then parent:Refresh() end end
		ColorPickerFrame:SetupColorPickerAndShow({ r = c[1], g = c[2], b = c[3], hasOpacity = false,
			swatchFunc = function() apply(ColorPickerFrame:GetColorRGB()) end,
			cancelFunc = function() apply(c[1], c[2], c[3], c[4]) end,
		})
	end)
	return b
end
local popupID = "EQOL_NAMEPLATE_AURA_RULE_SPELL"
StaticPopupDialogs[popupID] = {
	text = text("SpellID"), button1 = _G.ADD, button2 = _G.CANCEL,
	hasEditBox = true, editBoxWidth = 180, timeout = 0, whileDead = true, hideOnEscape = true,
	OnShow = function(self)
		local input = self.editBox or self.EditBox
		input:SetText(""); input:SetNumeric(true); input:SetMaxLetters(10); input:SetFocus()
	end,
	OnAccept = function(self, data)
		local input = self.editBox or self.EditBox
		if not data or not data.root:IsShown() or data.root.profile ~= data.profile then return end
		if not A.AddSpell(data.profile, data.rule, input:GetText()) then
			local caption = self.text or self.Text
			if caption then caption:SetText(text("Invalid") .. "\n" .. text("ComboHint")) end
			return true
		end
		data.root:Refresh()
	end,
}
function A.CreateRow(root)
	local row = CreateFrame("Frame", nil, root.tableArea)
	row:SetHeight(36)
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints(); row.bg:SetColorTexture(0, 0, 0, 0.20)
	row.drag = button(row, 36, "=")
	row.drag.Text:ClearAllPoints(); row.drag.Text:SetPoint("LEFT", 2, 0); row.drag.Text:SetPoint("RIGHT", -2, 0)
	row.drag:SetPoint("TOPLEFT", 2, -6)
	row.drag:RegisterForDrag("LeftButton")
	tooltip(row.drag, text("Drag"))
	row.drag:SetScript("OnDragStart", function()
		if not database().enabled then return end
		GameTooltip:Hide()
		root.dragIndex = row.index
		root.dragPreview.Text:SetText(label(row.rule))
		root.dragPreview:Show()
		root.dragPreview:SetScript("OnUpdate", function(self)
			local x, y = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			self:ClearAllPoints(); self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 12, y / scale - 12)
		end)
		root.dragPreview:GetScript("OnUpdate")(root.dragPreview)
	end)
	row.drag:SetScript("OnDragStop", function()
		local from = root.dragIndex; root:StopDrag()
		if not from or not database().enabled then return end
		for _, target in ipairs(root.rows) do
			if target:IsShown() and target:IsMouseOver() then A.Move(root.profile, from, target.index); root:Refresh(); break end
		end
	end)
	row.enabled = toggle(row, function() return text("Enabled") .. "\n" .. text("RuleLimit") end)
	row.enabled:SetPoint("TOPLEFT", 42, -6)
	row.enabled:SetScript("OnClick", function() A.Enable(root.profile, row.rule, not row.rule.enabled); root:Refresh() end)
	row.onlyMine = toggle(row, text("OwnOnly"))
	row.onlyMine:SetPoint("TOPLEFT", 106, -6)
	row.onlyMine:SetScript("OnClick", function()
		if not (database().enabled and row.rule.enabled) then return end
		row.rule.onlyMine = not row.rule.onlyMine; changed(); row:Refresh()
	end)
	row.spells = button(row, 200)
	row.spells.Text:SetJustifyH("LEFT")
	row.spells:SetPoint("TOPLEFT", 172, -6)
	row.spells:SetPoint("RIGHT", row, "RIGHT", -260, 0)
	row.spells:SetScript("OnClick", function(owner)
		GameTooltip:Hide()
		local r, p, class = row.rule, root.profile, root.class
		MenuUtil.CreateContextMenu(owner, function(_, menu)
			local list, ids = A.Candidates(p, class)
			menu:SetScrollMode(280)
			menu:CreateButton(text("AddID"), function()
				StaticPopup_Show(popupID, nil, nil, { root = root, profile = p, rule = r })
			end)
			menu:CreateDivider()
			for _, id in ipairs(ids) do
				local entry = menu:CreateCheckbox(list[id], function()
					for _, value in ipairs(r.spells) do if value == id then return true end end
					return false
				end, function()
					local selected = false
					for _, value in ipairs(r.spells) do if value == id then selected = true end end
					A.SelectSpell(r, id, not selected)
					-- Keep the menu alive; only refresh existing row widgets after the click.
					C_Timer.After(0, function() if root:IsShown() and root.profile == p then root:Refresh() end end)
				end)
				local selected = false
				for _, value in ipairs(r.spells) do if value == id then selected = true end end
				entry:SetEnabled(selected or #r.spells < 5)
			end
		end)
	end)
	row.health = toggle(row, text("Health")); row.health:SetPoint("TOPRIGHT", -225, -6)
	row.healthColor = colorButton(row, "health", text("Health")); row.healthColor:SetPoint("LEFT", row.health, "RIGHT", 3, 0)
	row.border = toggle(row, text("Border")); row.border:SetPoint("TOPRIGHT", -153, -6)
	row.borderColor = colorButton(row, "border", text("Border")); row.borderColor:SetPoint("LEFT", row.border, "RIGHT", 3, 0)
	for _, channel in ipairs({ "health", "border" }) do
		row[channel]:SetScript("OnClick", function() if not row.rule.enabled then return end; row.rule[channel] = not row.rule[channel]; changed(); row:Refresh() end)
	end
	row.up = button(row, 22); row.up:SetPoint("TOPRIGHT", -51, -6); tooltip(row.up, text("Up"))
	row.down = button(row, 22); row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0); tooltip(row.down, text("Down"))
	for _, direction in ipairs({ "up", "down" }) do
		local action = row[direction]
		action.icon = action:CreateTexture(nil, "ARTWORK")
		action.icon:SetSize(20, 20)
		action.icon:SetPoint("CENTER")
		action.icon:SetTexture(direction == "up" and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
	end
	row.delete = button(row, 22, "x"); row.delete:SetPoint("TOPRIGHT", -3, -6); tooltip(row.delete, text("Delete"))
	row.up:SetScript("OnClick", function() A.Move(root.profile, row.index, row.index - 1); root:Refresh() end)
	row.down:SetScript("OnClick", function() A.Move(root.profile, row.index, row.index + 1); root:Refresh() end)
	row.delete:SetScript("OnClick", function() A.Delete(root.profile, row.index); root:Refresh() end)
	function row:Refresh()
		local r = self.rule
		local master = A.CanEdit()
		self.drag:SetEnabled(master)
		self.spells:SetEnabled(master)
		self.delete:SetEnabled(master)
		self.drag:SetText(tostring(self.index))
		self.enabled:SetChecked(r.enabled); self.enabled:SetEnabled(master and A.CanEnable(root.profile, r))
		self.spells:SetText(label(r))
		self.onlyMine:SetChecked(r.onlyMine ~= false); self.onlyMine:SetEnabled(master and r.enabled == true)
		self.health:SetChecked(r.health); self.border:SetChecked(r.border)
		for _, channel in ipairs({ "health", "border" }) do
			local c = r[channel .. "Color"]
			self[channel]:SetEnabled(master and r.enabled == true)
			local active = master and r.enabled == true and r[channel] == true
			self[channel .. "Color"]:SetEnabled(active)
			self[channel .. "Color"]:SetAlpha(active and 1 or 0.35)
			self[channel .. "Color"].fill:SetColorTexture(c[1], c[2], c[3], 1)
		end
		self.up:SetEnabled(master and self.index > 1); self.down:SetEnabled(master and self.index < #root.profile.rules)
		self.up.icon:SetAlpha(master and self.index > 1 and 1 or 0.35)
		self.down.icon:SetAlpha(master and self.index < #root.profile.rules and 1 or 0.35)
	end
	return row
end
function A.ClassOptions()
		local list, order = {}, {}
		for _, token in ipairs(classOrder) do
			local icon = ""
			local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
			if coords then
				icon = ("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t "):format(
					math.floor(coords[1] * 256 + 0.5), math.floor(coords[2] * 256 + 0.5), math.floor(coords[3] * 256 + 0.5), math.floor(coords[4] * 256 + 0.5))
			end
			list[token] = icon .. (LOCALIZED_CLASS_NAMES_MALE[token] or token)
			order[#order + 1] = token
		end
		table.sort(order, function(a, b) return (LOCALIZED_CLASS_NAMES_MALE[a] or a) < (LOCALIZED_CLASS_NAMES_MALE[b] or b) end)
		return list, order
	end
function A.IsConfigured(token, specID, includeSpecs)
	local p = database().classes[token]
	if not p then return false end
	if specID then return type(p.specs) == "table" and type(p.specs[specID]) == "table" and p.specs[specID].useOwn == true end
	if includeSpecs and type(p.specs) == "table" then
		for _, spec in pairs(p.specs) do if type(spec) == "table" and spec.useOwn == true then return true end end
	end
	if type(p.custom) == "table" and #p.custom > 0 then return true end
	local rules, defaults = p.rules or {}, presets[token] or {}
	if #rules ~= #defaults then return true end
	local function same(a, b)
		if type(a) ~= type(b) then return false end
		if type(a) ~= "table" then return a == b end
		for key, value in pairs(a) do if not same(value, b[key]) then return false end end
		for key in pairs(b) do if a[key] == nil then return false end end
		return true
	end
	for i, rule in ipairs(rules) do
		local expected = newRule({defaults[i]})
		for key, value in pairs(expected) do if not same(rule[key], value) then return true end end
	end
	return false
end
function A.MarkedLabel(label, configured)
	return label .. (configured and " |TInterface\\Buttons\\UI-CheckBox-Check:16:16|t" or "")
end
function A.SelectClass(value, spec) A.class, A.spec = value, spec end
function A.Render(parent)
	local root = A.root
	if not root then
		root = CreateFrame("Frame", nil, parent); A.root = root; root.rows = {}; root.offset = 0
		root.dragPreview = CreateFrame("Frame", nil, root)
		root.dragPreview:SetSize(260, 28); root.dragPreview:SetFrameStrata("TOOLTIP")
		root.dragPreview:EnableMouse(false)
		root.dragPreview.bg = root.dragPreview:CreateTexture(nil, "BACKGROUND")
		root.dragPreview.bg:SetAllPoints(); root.dragPreview.bg:SetColorTexture(0.12, 0.35, 0.22, 0.8)
		root.dragPreview.Text = root.dragPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		root.dragPreview.Text:SetPoint("LEFT", 8, 0); root.dragPreview.Text:SetPoint("RIGHT", -8, 0)
		root.dragPreview.Text:SetJustifyH("LEFT"); root.dragPreview.Text:SetWordWrap(false)
		function root:StopDrag()
			self.dragIndex = nil
			self.dragPreview:SetScript("OnUpdate", nil); self.dragPreview:Hide()
		end
		root:StopDrag()
		root:SetScript("OnHide", function(self) self:StopDrag() end)
		root.classButton = button(root, 220)
		root.classButton:SetPoint("TOPLEFT", 0, 0)
		root.classButton.Text:SetJustifyH("LEFT")
		tooltip(root.classButton, text("ScopeHint"))
		root.classButton:SetScript("OnClick", function(owner)
			if not database().enabled then return end
			GameTooltip:Hide()
			MenuUtil.CreateContextMenu(owner, function(_, menu)
				menu:SetScrollMode(280)
				local list, classes = A.ClassOptions()
				local function option(parent, caption, token, spec)
					parent:CreateRadio(A.MarkedLabel(caption, A.IsConfigured(token, spec)), function() return A.class == token and A.spec == spec end, function()
						A.SelectClass(token, spec)
						C_Timer.After(0, function()
							if not root:IsShown() then return end
							local frame = addon.ConfigCenterFrame
							local state = frame and frame._LibSettingsDesignerState
							if state and state.RenderContent then state:RenderContent() end
							root:Refresh()
						end)
					end)
				end
				for _, token in ipairs(classes) do
					local specs = A.SpecOptions(token)
					if #specs > 0 then
						local submenu = menu:CreateButton(A.MarkedLabel(list[token], A.IsConfigured(token, nil, true)))
						option(submenu, list[token], token)
						submenu:CreateDivider()
						for _, spec in ipairs(specs) do option(submenu, spec.label, token, spec.id) end
					else option(menu, list[token], token) end
				end
			end)
		end)
		root.add = button(root, 140, text("AddRule")); root.add:SetPoint("LEFT", root.classButton, "RIGHT", 8, 0)
		root.add:SetScript("OnClick", function()
			if not A.CanEdit() then return end
			A.Add(root.profile)
			root.offset = math.max(0, #root.profile.rules - A.visibleRows)
			root:Refresh()
		end)
		root.deleteCustom = button(root, 30)
		root.deleteCustom:SetPoint("LEFT", root.add, "RIGHT", 8, 0)
		root.deleteCustom.icon = root.deleteCustom:CreateTexture(nil, "ARTWORK")
		root.deleteCustom.icon:SetSize(24, 24); root.deleteCustom.icon:SetPoint("CENTER")
		root.deleteCustom.icon:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		tooltip(root.deleteCustom, text("DeleteUnused") .. "\n" .. text("DeleteUnusedHint"))
		root.deleteCustom:SetScript("OnClick", function(owner)
			if not A.CanEdit() then return end
			GameTooltip:Hide()
			local p, class = root.profile, root.class
			MenuUtil.CreateContextMenu(owner, function(_, menu)
				menu:SetScrollMode(280)
				local list, ids = A.UnusedCustom(p, class)
				if #ids == 0 then menu:CreateButton(text("NoUnused")):SetEnabled(false) end
				for _, id in ipairs(ids) do
					menu:CreateButton(list[id], function()
						-- Recheck usage because another edit may have changed this rule set.
						A.DeleteCustom(p, class, id)
						C_Timer.After(0, function() if root:IsShown() and root.profile == p then root:Refresh() end end)
					end)
				end
			end)
		end)
		root.specToggle = toggle(root, text("SpecOwn"))
		root.specToggle:SetPoint("TOPLEFT", 0, -34)
		root.specToggle.Text:SetText("")
		root.specLabel = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		root.specLabel:SetPoint("LEFT", root.specToggle, "RIGHT", 8, 0)
		root.specLabel:SetText(text("SpecOwn"))
		root.specHint = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		root.specHint:SetPoint("TOPLEFT", 0, -65); root.specHint:SetPoint("RIGHT", -24, 0)
		root.specHint:SetText(text("SpecHint")); root.specHint:SetJustifyH("LEFT"); root.specHint:SetWordWrap(true)
		root.specHint:SetHeight(40)
		root.specToggle:SetScript("OnClick", function() A.SetSpecEnabled(not A.CanEdit()); root:Refresh() end)
		root.tableArea = CreateFrame("Frame", nil, root)
		root.tableArea:SetPoint("TOPLEFT", 0, -40); root.tableArea:SetPoint("TOPRIGHT", -24, -40)
		root.tableArea:SetHeight(346); root.tableArea:EnableMouseWheel(true)
		root.tableArea:SetScript("OnMouseWheel", function(_, delta) root:SetOffset(root.offset - delta) end)
		root.scrollbar = CreateFrame("Slider", nil, root, "UIPanelScrollBarTemplate")
		root.scrollbar:SetPoint("TOPRIGHT", -2, -72); root.scrollbar:SetPoint("BOTTOMRIGHT", -2, 16)
		root.scrollbar:SetWidth(16); root.scrollbar:SetValueStep(1); root.scrollbar.scrollStep = 1
		if root.scrollbar.SetObeyStepOnDrag then root.scrollbar:SetObeyStepOnDrag(true) end
		root.scrollbar:SetScript("OnValueChanged", function(_, value)
			if not root.syncingScroll then root:SetOffset(value) end
		end)
		root.headers = {}
		for _, def in ipairs({ { "Enabled", 40 }, { "OwnOnly", 76 }, { "Spells", 172 }, { "HealthColumn", -251 }, { "BorderColumn", -179 }, { "Order", -73 } }) do
			local h = root.tableArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			h:SetText(def[1] == "Enabled" and "|TInterface\\Buttons\\UI-CheckBox-Check:20:20|t" or text(def[1])); h:SetPoint("TOPLEFT", root.tableArea, def[2] < 0 and "TOPRIGHT" or "TOPLEFT", def[2], 0)
			h:SetHeight(18); h:SetWordWrap(false); h:SetJustifyH("LEFT")
			if def[1] == "Spells" then h:SetPoint("RIGHT", root.tableArea, "RIGHT", -260, 0)
			else h:SetWidth(def[1] == "Enabled" and 26 or (def[1] == "OwnOnly" and 90 or 68)) end
			if def[1] == "OwnOnly" then
				root.ownHeader = CreateFrame("Frame", nil, root.tableArea)
				root.ownHeader:SetPoint("TOPLEFT", h, "TOPLEFT"); root.ownHeader:SetSize(90, 18)
				root.ownHeader:EnableMouse(true); tooltip(root.ownHeader, text("OwnOnly"))
			end
			root.headers[#root.headers + 1] = h
		end
		function root:SetOffset(value)
			local nextOffset = math.max(0, math.min(math.floor(value + 0.5), math.max(0, #self.profile.rules - A.visibleRows)))
			if nextOffset ~= self.offset then self.offset = nextOffset; self:StopDrag(); self:Refresh() end
		end
		function root:Refresh()
			if not A.CanEdit() then self:StopDrag() end
			self:SetAlpha(database().enabled and 1 or 0.4)
			local p = profile()
			if self.class ~= A.class or self.spec ~= A.spec or self.profile ~= p then self.offset = 0; self:StopDrag() end
			self.profile, self.class, self.spec = p, A.class, A.spec
			local maxOffset = math.max(0, #p.rules - A.visibleRows)
			self.offset = math.max(0, math.min(self.offset, maxOffset))
			self.classButton:SetEnabled(database().enabled == true)
			local classes = A.ClassOptions()
			local caption = classes[A.class] or A.class
			if A.spec then
				for _, spec in ipairs(A.SpecOptions(A.class)) do if spec.id == A.spec then caption = spec.label end end
			end
			self.classButton:SetText(caption)
			self.specToggle:SetShown(A.spec ~= nil); self.specLabel:SetShown(A.spec ~= nil); self.specHint:SetShown(A.spec ~= nil)
			self.specToggle:SetEnabled(database().enabled == true)
			local cp = classProfile()
			self.specToggle:SetChecked(A.spec and cp.specs and cp.specs[A.spec] and cp.specs[A.spec].useOwn == true)
			self.tableArea:ClearAllPoints()
			local top = A.spec and 110 or 40
			self.tableArea:SetPoint("TOPLEFT", 0, -top); self.tableArea:SetPoint("TOPRIGHT", -24, -top)
			self.tableArea:SetAlpha(A.CanEdit() and 1 or 0.4)
			self.scrollbar:ClearAllPoints(); self.scrollbar:SetPoint("TOPRIGHT", -2, -top - 32); self.scrollbar:SetPoint("BOTTOMRIGHT", -2, 16)
			self.add:SetEnabled(A.CanEdit()); self.deleteCustom:SetEnabled(A.CanEdit())
			self.syncingScroll = true
			self.scrollbar:SetMinMaxValues(0, maxOffset); self.scrollbar:SetValue(self.offset)
			self.scrollbar:SetShown(maxOffset > 0)
			self.syncingScroll = nil
			for slot = 1, math.min(A.visibleRows, #p.rules) do
				local index = self.offset + slot
				local row = self.rows[slot]
				if not row then row = A.CreateRow(self); self.rows[slot] = row end
				row.rule, row.index = p.rules[index], index
				row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -24 - (slot - 1) * A.rowHeight); row:SetPoint("RIGHT", self.tableArea, "RIGHT", 0, 0)
				row:Refresh(); row:Show()
			end
			for slot = math.min(A.visibleRows, #p.rules) + 1, #self.rows do self.rows[slot]:Hide() end
			self:SetHeight(A.tableHeight + (A.spec and 70 or 0))
		end
		function root:Release()
			self:StopDrag()
			StaticPopup_Hide(popupID)
			self:Hide()
		end
	end
	root:SetParent(parent); root:ClearAllPoints(); root:SetPoint("TOPLEFT"); root:SetPoint("TOPRIGHT")
	root:Refresh(); root:Show()
	return root
end
local app = addon.ConfigApp
local pageID = "interface.nameplates"
if not (app and app:GetPage(pageID)) then return end
app:RegisterGroup(pageID, { id = "aura-colors", title = text("Title"), order = 60, newTagID = "nameplateAuraColors" })
local order = 0
local function control(id, kind, title, data)
	data = data or {}; order = order + 10
	data.id, data.type, data.label = "nameplateAuraColors" .. id, kind, title
	data.groupID, data.groupTitle, data.order = "aura-colors", text("Title"), order
	data.storage, data.trackCustomized = false, false
	if id ~= "Enable" then data.isEnabled = function() return database().enabled == true end end
	app:RegisterControl(pageID, data)
end
control("Enable", "toggle", text("Enable"), { default = false, getValue = function() return database().enabled end, setValue = function(value) database().enabled = value; changed(); if not value then runtime.Apply() end; if A.root then A.root:Refresh() end end })
control("Hint", "inlinehint", text("Hint"), { newTagID = "nameplateAuraColors" })
control("Apply", "button", text("Apply"), { buttonText = text("Apply"), onClick = function() runtime.Apply() end })
control("Priority", "inlinehint", text("Priority"))
control("ComboHint", "inlinehint", text("ComboHint"))
control("Rules", "custom", text("Rules"), {
	hideHeader = true, editor = A, getProfile = profile, newTagID = not (addon.variables and addon.variables.isForever) and "nameplateAuraColorSpecs" or nil,
	getHeight = function() return A.tableHeight + 26 + (A.spec and 70 or 0) end,
	render = A.Render, refresh = function(handle) if handle then handle:Refresh() end end,
	release = function(handle) if handle then handle:Release() end end,
})
