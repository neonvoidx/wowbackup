local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Shared = { instances = {}, sources = {}, dirty = {} }
addon.EntryPicker = Shared
local Picker = {}
Shared.Methods = Picker

function Shared:Create(key, options)
	local instance = setmetatable(options or {}, { __index = Picker })
	instance.frameName = "EQOLEntryPicker" .. key
	instance.category, instance.query, instance.rows, instance.catalog = "ALL", "", {}, {}
	instance.idTypes = instance.idTypes or { "SPELL", "ITEM" }
	self.instances[key] = instance
	return instance
end

function Shared.GetTypeLabel(kind)
	if kind == "SPELL" then return _G.STAT_CATEGORY_SPELL or _G.SPELLS or L["CooldownPanelAddSpellID"] end
	if kind == "ITEM" then return _G.AUCTION_HOUSE_HEADER_ITEM or _G.ITEMS or L["CooldownPanelAddItemID"] end
	if kind == "MACRO" then return _G.MACRO or L["Macros"] end
	if kind == "CDM_AURA" then return L["CooldownPanelCDMAuraType"] end
	return kind
end

function Shared.GetClassMenuLabel(classTag, label)
	if not classTag then return label end
	local atlas = "classicon-" .. classTag:lower()
	if CreateAtlasMarkup and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then return CreateAtlasMarkup(atlas, 16, 16) .. " " .. label end
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classTag:upper()]
	if coords then return string.format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t %s", coords[1]*256, coords[2]*256, coords[3]*256, coords[4]*256, label) end
	return label
end

function Shared.CopyRow(row)
	local copy = {}
	for key, value in pairs(row) do copy[key] = value end
	return copy
end

function Picker.NormalizeSearch(text)
	text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	if _G.CaseAccentInsensitiveParse then return _G.CaseAccentInsensitiveParse(text) end
	return (_G.strlower or string.lower)(text)
end

function Picker:GetClassLabel(classTag)
	if not classTag then return _G.ALL_CLASSES or _G.ALL end
	return (_G.LOCALIZED_CLASS_NAMES_MALE or {})[classTag] or classTag
end

function Picker.PlainID(value)
	if issecretvalue and issecretvalue(value) then return nil end
	if type(value) ~= "number" or value <= 0 or value ~= math.floor(value) then return nil end
	return value
end

function Shared:BuildSpells(append)
	local _, playerClass = UnitClass("player")
	local book = C_SpellBook
	local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
	local itemTypes = Enum and Enum.SpellBookItemType or {}
	local seen = {}
	local function spell(id, name, icon, passive, subName)
		id = Picker.PlainID(id)
		if not id or seen[id] then return end
		name = name or C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
		if subName and subName ~= "" then name = (name or tostring(id)) .. " (" .. subName .. ")" end
		local row = { key = "spell:" .. id, kind = "SPELL", value = id, category = "SPELLS", classTag = playerClass, name = name,
			icon = icon or C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id),
			overrides = passive and { trackPassiveSpell = true } or nil, description = Shared.GetTypeLabel("SPELL") }
		seen[id] = row
		append(row)
	end
	local function flyout(id)
		if not (GetFlyoutInfo and GetFlyoutSlotInfo) then return end
		local _, _, count = GetFlyoutInfo(id)
		for index = 1, count or 0 do
			local spellID, overrideID, known = GetFlyoutSlotInfo(id, index)
			if known then spell(overrideID or spellID) end
		end
	end
	if book and bank and book.GetNumSpellBookSkillLines and book.GetSpellBookSkillLineInfo and book.GetSpellBookItemInfo then
		for line = 1, book.GetNumSpellBookSkillLines() do
			local info = book.GetSpellBookSkillLineInfo(line)
			if info and not info.offSpecID then
				for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
					local item = book.GetSpellBookItemInfo(slot, bank)
					if item and not item.isOffSpec then
						if itemTypes.Flyout and item.itemType == itemTypes.Flyout then flyout(item.actionID)
						elseif not itemTypes.Spell or item.itemType == itemTypes.Spell then spell(item.spellID or item.actionID, item.name, item.iconID, item.isPassive, item.subName) end
					end
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
		for line = 1, GetNumSpellTabs() do
			local _, _, offset, count = GetSpellTabInfo(line)
			for slot = (offset or 0) + 1, (offset or 0) + (count or 0) do
				local kind, id = GetSpellBookItemInfo(slot, _G.BOOKTYPE_SPELL or "spell")
				if kind == "SPELL" then spell(id) elseif kind == "FLYOUT" then flyout(id) end
			end
		end
	end
	for _, row in ipairs(self:GetSource("TALENT")) do
		if seen[row.value] then
			seen[row.value].description = row.description
		else
			local copy = Shared.CopyRow(row)
			copy.key, copy.category = "spell:" .. row.value, "SPELLS"
			if C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(row.value) then copy.overrides = { trackPassiveSpell = true } end
			append(copy)
		end
	end
end

-- Talent catalogs include unlearned entries so requirements can be configured
-- before spending points. Keep definition spell IDs rather than cast overrides.
function Shared:BuildTalents(append)
	local _, classTag = UnitClass("player")
	local seen = {}
	local function talent(spellID, name, icon, isPvP)
		spellID = Picker.PlainID(spellID)
		if not spellID or seen[spellID] then return end
		seen[spellID] = true
		append({ key = "talent:" .. spellID, kind = "SPELL", value = spellID, category = isPvP and "PVP_TALENTS" or "TALENTS", classTag = classTag,
			name = name or C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID),
			icon = icon or C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID),
			description = isPvP and ((_G.PVP or "PvP") .. " - " .. (_G.TALENTS or Shared.GetTypeLabel("SPELL"))) or (_G.TALENTS or Shared.GetTypeLabel("SPELL")) })
	end
	local traits = C_Traits
	local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	if configID and traits and traits.GetConfigInfo and traits.GetTreeNodes and traits.GetNodeInfo and traits.GetEntryInfo and traits.GetDefinitionInfo then
		local config = traits.GetConfigInfo(configID)
		for _, treeID in ipairs(config and config.treeIDs or {}) do
			for _, nodeID in ipairs(traits.GetTreeNodes(treeID) or {}) do
				local node = traits.GetNodeInfo(configID, nodeID)
				for _, entryID in ipairs(node and node.entryIDs or {}) do
					local entry = traits.GetEntryInfo(configID, entryID)
					local definition = entry and entry.definitionID and traits.GetDefinitionInfo(entry.definitionID)
					if definition then talent(definition.spellID, definition.overrideName, definition.overrideIcon) end
				end
			end
		end
	elseif GetNumTalentTabs and GetNumTalents and C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
		for tab = 1, GetNumTalentTabs(false, false) do
			for index = 1, GetNumTalents(tab, false, false) do
				local info = C_SpecializationInfo.GetTalentInfo({ specializationIndex = tab, talentIndex = index, isInspect = false, isPet = false })
				if info then talent(info.spellID, info.name, info.icon) end
			end
		end
	end
	local spec = C_SpecializationInfo
	if spec and spec.GetPvpTalentSlotInfo and spec.GetPvpTalentInfo then
		-- Enumerate all offers in each of the three PvP slots, including locked
		-- and unselected talents, independently of War Mode or PvP activation.
		for slot = 1, 3 do
			local info = spec.GetPvpTalentSlotInfo(slot)
			for _, talentID in ipairs(info and info.availableTalentIDs or {}) do
				local entry = spec.GetPvpTalentInfo(talentID)
				if entry then talent(entry.spellID, entry.name, entry.icon, true) end
			end
		end
	end
end

function Shared:IsPlayerAura(info, auraSpellID)
	local selfAura = info.selfAura ~= false
	-- Cast targeting can confirm a friendly buff, but an offensive cast can
	-- also grant a player buff. Keep the viewer assignment for other cases.
	local spells = C_Spell
	if not (spells and spells.IsSpellHelpful and spells.IsSpellHarmful) then return selfAura end
	local okHelpful, helpful = pcall(spells.IsSpellHelpful, auraSpellID)
	local okHarmful, harmful = pcall(spells.IsSpellHarmful, auraSpellID)
	if not okHelpful or not okHarmful then return selfAura end
	if issecretvalue and (issecretvalue(helpful) or issecretvalue(harmful)) then return selfAura end
	if helpful == true and harmful == false then return true end
	return selfAura
end

function Shared:BuildAuras(append)
	local _, playerClass = UnitClass("player")
	local api = C_CooldownViewer
	local categories = Enum and Enum.CooldownViewerCategory
	if not (api and categories and api.GetCooldownViewerCategorySet and api.GetCooldownViewerCooldownInfo) then return end
	for _, categoryKey in ipairs({ "TrackedBuff", "TrackedBar", "SpecAgnosticTracked", "EquipSlotTracked" }) do
		local category = categories[categoryKey]
		if category ~= nil then
			local ok, cooldownIDs = pcall(api.GetCooldownViewerCategorySet, category, false)
			if ok and type(cooldownIDs) == "table" then
				for _, cooldownID in ipairs(cooldownIDs) do
					if Picker.PlainID(cooldownID) then
						local infoOK, info = pcall(api.GetCooldownViewerCooldownInfo, cooldownID)
						if infoOK and type(info) == "table" and info.isKnown ~= false then
							-- Follow the existing CDM import's aura-first identity. A
							-- talent/cast ID can differ from the actual aura Spell ID.
							local ids, seen = {}, {}
							local function candidate(value)
								local id = Picker.PlainID(value)
								if id and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
							end
							candidate(info.overrideTooltipSpellID)
							for _, id in ipairs(info.linkedSpellIDs or {}) do candidate(id) end
							if #ids == 0 then candidate(info.overrideSpellID); candidate(info.spellID) end
							local id = ids[1]
							if id then
								local selfAura = self:IsPlayerAura(info, id)
								append({ key = "cdm-aura:" .. id .. (selfAura and ":player" or ":target"), kind = "CDM_AURA", value = id, category = "AURAS", classTag = playerClass,
									name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id),
									icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id), description = Shared.GetTypeLabel("CDM_AURA") .. " - " .. tostring(id), searchIDs = table.concat({ tostring(Picker.PlainID(info.spellID) or ""), tostring(Picker.PlainID(info.overrideSpellID) or ""), table.concat(ids, " ") }, " "),
									overrides = { auraUnit = selfAura and "player" or "target", auraFilter = selfAura and "HELPFUL" or "HARMFUL|PLAYER", cdmAuraOverlaySpellIDs = ids } })
							end
						end
					end
				end
			end
		end
	end
end

function Shared:BuildMacros(append)
	-- Read names and icons only; adding a macro stores its identity, never runs it.
	if GetNumMacros and GetMacroInfo then
		local account, character = GetNumMacros()
		local offset = Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS or _G.MAX_ACCOUNT_MACROS or 120
		for _, bank in ipairs({ { count = account, offset = 0, label = L["CooldownPanelPickerAccountMacro"] }, { count = character, offset = offset, label = L["CooldownPanelPickerCharacterMacro"] } }) do
			for index = 1, bank.count or 0 do
				local macroID = bank.offset + index
				local name, icon = GetMacroInfo(macroID)
				if name then
					append({ key = "macro:" .. macroID, kind = "MACRO", value = macroID, category = "MACROS", name = name, icon = icon,
						overrides = { macroName = name }, description = bank.label })
				end
			end
		end
	end
end

function Shared:BuildItems(append)
	local seen = {}
	local function item(id)
		id = Picker.PlainID(id)
		if not id or seen[id] then return end
		seen[id] = true
		local name, icon
		local info = C_Item and C_Item.GetItemInfo or GetItemInfo
		if info then local values = { info(id) }; name, icon = values[1], values[10] end
		local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
		if not icon and instant then local _, _, _, _, texture = instant(id); icon = texture end
		append({ key = "item:" .. id, kind = "ITEM", value = id, category = "ITEMS", name = name or tostring(id), icon = icon, description = tostring(id) })
	end
	local count = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
	local getID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
	if count and getID then
		for bag = 0, _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4 do for slot = 1, count(bag) or 0 do item(getID(bag, slot)) end end
	end
	if GetInventoryItemID then for slot = 1, 19 do item(GetInventoryItemID("player", slot)) end end
end

Shared.builders = { TALENT = Shared.BuildTalents, SPELL = Shared.BuildSpells, ITEM = Shared.BuildItems, MACRO = Shared.BuildMacros, CDM_AURA = Shared.BuildAuras }
function Shared:GetSource(kind)
	if not self.sources[kind] or self.dirty[kind] then
		local rows = {}
		self.builders[kind](self, function(row) rows[#rows + 1] = row end)
		self.sources[kind], self.dirty[kind] = rows, false
	end
	return self.sources[kind]
end
function Shared:InvalidateSources(kinds)
	-- The spell catalog also contains the talent catalog.
	for _, kind in ipairs(kinds or {}) do if kind == "TALENT" then self.dirty.SPELL = true end end
	for _, kind in ipairs(kinds or { "SPELL", "ITEM", "MACRO", "CDM_AURA", "TALENT" }) do self.dirty[kind] = true end
	for _, instance in pairs(self.instances) do instance:InvalidateCatalog() end
end
function Picker:AppendSource(kind, append)
	for _, row in ipairs(Shared:GetSource(kind)) do append(Shared.CopyRow(row)) end
end
function Picker:IndexPlayerSpells(append) self:AppendSource("SPELL", append) end
function Picker:IndexCDMAuras(append) self:AppendSource("CDM_AURA", append) end
function Picker:GetTypeLabel(kind) return Shared.GetTypeLabel(kind) end
function Picker:CanEdit() return not (InCombatLockdown and InCombatLockdown()) end
function Picker:PrepareRow(row)
	row.name = row.name or tostring(row.value or row.key)
	row.search = self.NormalizeSearch(table.concat({ row.name, tostring(row.value or ""), row.description or "", row.searchIDs or "", self:GetClassLabel(row.classTag) or "" }, " "))
	return row
end
function Picker:BuildCatalog()
	local rows, seen = {}, {}
	local function append(row)
		if self.GetRowKey then row.key = self:GetRowKey(row) end
		local old = seen[row.key]
		if old then
			old.categories = old.categories or { [old.category] = true }
			old.categories[row.category] = true
		else seen[row.key] = row; rows[#rows + 1] = self:PrepareRow(row) end
	end
	for _, kind in ipairs(self.sourceKinds or {}) do self:AppendSource(kind, append) end
	if self.ExtendCatalog then self:ExtendCatalog(append) end
	table.sort(rows, function(a,b)
		local left, right = self.NormalizeSearch(a.name), self.NormalizeSearch(b.name)
		return left ~= right and left < right or left == right and a.key < b.key
	end)
	self.catalog = rows
end
function Picker:EnsureCatalog()
	if self.catalogDirty or not self.catalogBuilt then
		self:BuildCatalog()
		self.catalogDirty = false
		self.catalogBuilt = true
	end
end

function Picker:QueueRefresh()
	if not (self.frame and self.frame:IsShown()) or self.refreshPending then return end
	self.refreshPending = true
	C_Timer.After(0, function()
		self.refreshPending = false
		if self.frame and self.frame:IsShown() then self:Refresh() end
	end)
end

function Picker:InvalidateCatalog()
	self.catalogDirty = true
	self:QueueRefresh()
end

function Picker:GetFilteredRows()
	local query = self.NormalizeSearch(self.query)
	local rows = {}
	for _, row in ipairs(self.catalog) do
		local matches = not self.classTag or not row.classTag or self.classTag == row.classTag
		if query == "" then matches = matches and (self.category == "ALL" or row.category == self.category or row.categories and row.categories[self.category]) end
		for term in query:gmatch("%S+") do if not row.search:find(term, 1, true) then matches = false; break end end
		if matches and (self.showAddedEntries or row.keepVisible or not self:IsAdded(row)) then rows[#rows + 1] = row end
	end
	return rows
end

function Picker:ShowClassMenu(button)
	local menu = _G.MenuUtil
	if not menu then return end
	menu.CreateContextMenu(button, function(_, root)
		root:CreateRadio(self:GetClassLabel(), function() return not self.classTag end, function() self.classTag = nil; self:Refresh() end)
		local classes = {}
		local seen = {}
		for _, row in ipairs(self.catalog) do
			local classTag = row.classTag
			if classTag and not seen[classTag] then seen[classTag] = true; classes[#classes + 1] = { tag = classTag, name = self:GetClassLabel(classTag) } end
		end
		table.sort(classes, function(a, b) return self.NormalizeSearch(a.name) < self.NormalizeSearch(b.name) end)
		for _, class in ipairs(classes) do
			local classTag = class.tag
			root:CreateRadio(Shared.GetClassMenuLabel(classTag, class.name), function() return self.classTag == classTag end, function() self.classTag = classTag; self:Refresh() end)
		end
	end)
end

function Picker:UpdateButtonPixels()
	local pixel = addon.PixelUtil
	if not (pixel and pixel.OnePixel and self.frame) then return end
	local size = pixel.OnePixel(self.frame)
	if self.buttonPixelSize == size then return end
	self.buttonPixelSize = size
	for _, button in ipairs(self.pixelButtons or {}) do self:ApplyButtonPixels(button) end
end

function Picker:ApplyButtonPixels(button)
	local pixel = addon.PixelUtil
	local size = pixel and pixel.OnePixel and pixel.OnePixel(button) or 1
	if pixel and pixel.Size then pixel.Size(button, button.pickerWidth, button.pickerHeight) end
	if button.pickerPixelSize == size then return end
	button.pickerPixelSize = size
	button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = size, tileEdge = false })
	if pixel and pixel.ApplyTexturePixelSnapping then
		for _, key in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }) do
			pixel.ApplyTexturePixelSnapping(button[key], 0)
		end
	end
	if button.Paint then button:Paint() end
end

function Picker:CreateButton(parent, text, width, height)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button.pickerWidth, button.pickerHeight = width, height
	button:SetSize(width, height)
	self:ApplyButtonPixels(button)
	self.pixelButtons = self.pixelButtons or {}
	self.pixelButtons[#self.pixelButtons + 1] = button
	local font = button:CreateFontString(nil, "OVERLAY")
	font:SetFont(_G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 12, "")
	font:SetPoint("LEFT", 8, 0)
	font:SetPoint("RIGHT", -8, 0)
	button:SetFontString(font)
	button:SetText(text)
	function button:Paint()
		local active = self.selected or self.hovered
		self:SetBackdropColor(active and 0.22 or 0.09, active and 0.20 or 0.10, active and 0.13 or 0.09, 1)
		self:SetBackdropBorderColor(active and 0.54 or 0.23, active and 0.45 or 0.24, active and 0.25 or 0.22, 1)
		font:SetTextColor(self.selected and 1 or 0.88, self.selected and 0.82 or 0.87, self.selected and 0.40 or 0.80)
	end
	function button:SetSelected(selected) self.selected = selected; self:Paint() end
	button:SetScript("OnEnter", function() button.hovered = true; button:Paint() end)
	button:SetScript("OnLeave", function() button.hovered = false; button:Paint() end)
	button:Paint()
	return button
end

function Picker:CreateRow(index)
	local row = CreateFrame("Frame", nil, self.frame.content)
	row:SetHeight(54)
	row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -(index - 1) * 54)
	row:SetPoint("RIGHT", self.frame.content, "RIGHT", 0, 0)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(34, 34)
	row.icon:SetPoint("LEFT", 4, 0)
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	row.add = self:CreateButton(row, _G.ADD or _G.OKAY, 88, 24)
	row.add:SetPoint("RIGHT", -4, 0)
	if row.add.SetMotionScriptsWhileDisabled then row.add:SetMotionScriptsWhileDisabled(true) end
	row.addedCheck = row.add:CreateTexture(nil, "OVERLAY")
	row.addedCheck:SetSize(20, 20)
	row.addedCheck:SetPoint("CENTER")
	row.addedCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	row.addedCheck:SetVertexColor(0.2, 1, 0.3)
	row.addedCheck:Hide()
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
	row.name:SetPoint("RIGHT", row.add, "LEFT", -10, 0)
	row.name:SetTextColor(0.94, 0.90, 0.76)
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)
	row.description = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.description:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -5)
	row.description:SetPoint("RIGHT", row.add, "LEFT", -10, 0)
	row.description:SetTextColor(0.61, 0.64, 0.58)
	row.description:SetJustifyH("LEFT")
	row.description:SetWordWrap(false)
	row.add:SetScript("OnClick", function() if row.data then self:Add(row.data) end end)
	row:EnableMouse(true)
	row:SetScript("OnEnter", function() self:ShowRowTooltip(row) end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.add:HookScript("OnEnter", function()
		if row.alreadyAdded then
			GameTooltip:SetOwner(row.add, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["CooldownPanelPickerAlreadyAdded"])
			GameTooltip:Show()
		else self:ShowRowTooltip(row) end
	end)
	row.add:HookScript("OnLeave", function() GameTooltip:Hide() end)
	self.rows[index] = row
	return row
end

function Picker:Refresh(rebuild)
	self:UpdateButtonPixels()
	local frame = self.frame
	if not frame or not frame:IsShown() then return end
	if not self:GetTarget(self.targetId) then frame:Hide(); return end
	if rebuild then self.catalogDirty = true end
	self:EnsureCatalog()
	local byID = self.category == "ID"
	frame.idArea:SetShown(byID)
	frame.scroll:SetShown(not byID)
	frame.search:SetEnabled(not byID)
	frame.classButton:SetEnabled(not byID)
	frame.idAdd:SetEnabled(self:CanEdit())
	frame.classButton:SetText(Shared.GetClassMenuLabel(self.classTag, self:GetClassLabel(self.classTag)))
	for _, button in ipairs(frame.categoryButtons) do
		button:SetSelected(button.category == self.category)
	end
	local label = _G.SEARCH or ""
	if self.query == "" then for _, category in ipairs(self.categories) do if category.id == self.category then label = category.label end end end
	local rows = byID and {} or self:GetFilteredRows()
	frame.resultLabel:SetText(label .. " (" .. #rows .. ")")
	frame.empty:SetShown(not byID and #rows == 0)
	for index, data in ipairs(rows) do
		local row = self.rows[index] or self:CreateRow(index)
		row.data = data
		if data.atlas then row.icon:SetAtlas(data.atlas) else row.icon:SetTexture(data.icon or 134400) end
		local alreadyAdded = self.showAddedEntries and not data.keepVisible and self:IsAdded(data)
		row.add:SetEnabled(self:CanEdit() and data.disabled ~= true and not alreadyAdded)
		row.alreadyAdded = alreadyAdded
		if addon.PixelUtil and addon.PixelUtil.Width then addon.PixelUtil.Width(row.add, 88) else row.add:SetWidth(88) end
		row.addedCheck:SetShown(alreadyAdded)
		row.add:SetText(alreadyAdded and "" or (self.GetButtonText and self:GetButtonText(data) or (_G.ADD or _G.OKAY)))
		row.name:SetText(data.name)
		row.description:SetText(data.description or "")
		row:Show()
	end
	for index = #rows + 1, #self.rows do self.rows[index].data = nil; self.rows[index]:Hide() end
	frame.content:SetHeight(math.max(1, #rows * 54))
	frame.content:SetWidth(math.max(1, frame.scroll:GetWidth() - 6))
end

function Picker:CreateWindow()
	local frame = CreateFrame("Frame", self.frameName, UIParent, "BackdropTemplate")
	self.frame = frame
	frame:SetSize(780, 570)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropColor(0.065, 0.07, 0.06, 1)
	frame:SetBackdropBorderColor(0.37, 0.35, 0.28, 1)
	frame.header = frame:CreateTexture(nil, "BACKGROUND")
	frame.header:SetColorTexture(0.11, 0.12, 0.10, 1)
	frame.header:SetPoint("TOPLEFT", 1, -1)
	frame.header:SetPoint("TOPRIGHT", -1, -1)
	frame.header:SetHeight(32)
	frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.TitleText:SetPoint("TOPLEFT", 16, -9)
	frame.TitleText:SetPoint("RIGHT", frame, "RIGHT", -40, 0)
	frame.TitleText:SetJustifyH("LEFT")
	frame.TitleText:SetTextColor(0.94, 0.90, 0.76)
	frame.topClose = self:CreateButton(frame, "×", 26, 24)
	frame.topClose:SetPoint("TOPRIGHT", -5, -4)
	frame.topClose:SetScript("OnClick", function() frame:Hide() end)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame.TitleText:SetText("")
	_G.UISpecialFrames = _G.UISpecialFrames or {}
	table.insert(_G.UISpecialFrames, self.frameName)
	frame.categoryButtons = {}
	frame.search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	frame.search:SetSize(365, 24)
	frame.search:SetPoint("TOPLEFT", 180, -42)
	frame.search:SetAutoFocus(false)
	frame.search.Instructions:SetText(L["CooldownPanelPickerSearch"])
	frame.search:SetScript("OnTextChanged", function(box)
		if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(box) end
		self.query = box:GetText() or ""
		frame.scroll:SetVerticalScroll(0)
		self:Refresh()
	end)
	frame.search:SetScript("OnEscapePressed", function(box) box:ClearFocus(); frame:Hide() end)
	frame.classButton = self:CreateButton(frame, "", 170, 24)
	frame.classButton:SetPoint("TOPRIGHT", -14, -40)
	frame.classButton:SetScript("OnClick", function(button) self:ShowClassMenu(button) end)
	for index, category in ipairs(self.categories) do
		local button = self:CreateButton(frame, category.label, 148, 27)
		button:SetPoint("TOPLEFT", 15, -43 - (index - 1) * 32)
		button.category = category.id
		button:SetScript("OnClick", function()
			self.category = button.category
			self.query = ""
			frame.search:SetText("")
			frame.scroll:SetVerticalScroll(0)
			self:Refresh()
		end)
		frame.categoryButtons[#frame.categoryButtons + 1] = button
	end
	frame.resultLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.resultLabel:SetPoint("TOPLEFT", 180, -79)
	frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	frame.scroll:SetPoint("TOPLEFT", 178, -102)
	frame.scroll:SetPoint("BOTTOMRIGHT", -33, 47)
	frame.content = CreateFrame("Frame", nil, frame.scroll)
	frame.content:SetSize(515, 1)
	frame.scroll:SetScrollChild(frame.content)
	frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.empty:SetPoint("CENTER", frame.scroll)
	frame.empty:SetText(L["CooldownPanelPickerNoResults"])
	frame.idArea = CreateFrame("Frame", nil, frame)
	frame.idArea:SetPoint("TOPLEFT", 180, -103)
	frame.idArea:SetPoint("BOTTOMRIGHT", -30, 50)
	frame.idButtons = {}
	for index, entryType in ipairs(self.idTypes) do
		local button = self:CreateButton(frame.idArea, self:GetTypeLabel(entryType), 155, 25)
		button:SetPoint("TOPLEFT", (index - 1) * 165, 0)
		button.entryType = entryType
		button:SetScript("OnClick", function()
			self.idType = entryType
			for _, other in ipairs(frame.idButtons) do other:SetSelected(other.entryType == entryType) end
		end)
		frame.idButtons[#frame.idButtons + 1] = button
	end
	frame.idInput = CreateFrame("EditBox", nil, frame.idArea, "InputBoxTemplate")
	frame.idInput:SetSize(220, 26)
	frame.idInput:SetAutoFocus(false)
	frame.idInput:SetPoint("TOPLEFT", 5, -46)
	frame.idInput:SetNumeric(true)
	frame.idInput:SetScript("OnEnterPressed", function() self:AddByID() end)
	frame.idInput:SetScript("OnEscapePressed", function(box) box:ClearFocus(); frame:Hide() end)
	frame.idAdd = self:CreateButton(frame.idArea, self.actionText or _G.ADD or _G.OKAY, 100, 26)
	frame.idAdd:SetPoint("LEFT", frame.idInput, "RIGHT", 15, 0)
	frame.idAdd:SetScript("OnClick", function() self:AddByID() end)
	frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.status:SetPoint("BOTTOMLEFT", 16, 18)
	frame.status:SetPoint("RIGHT", frame, "RIGHT", -120, 0)
	frame.status:SetJustifyH("LEFT")
	frame.close = self:CreateButton(frame, _G.CLOSE, 90, 24)
	frame.close:SetPoint("BOTTOMRIGHT", -14, 10)
	frame.close:SetScript("OnClick", function() frame:Hide() end)

	frame:SetScript("OnEvent", function(_, event) if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then self:UpdateButtonPixels() end end)

	frame:SetScript("OnHide", function()
		frame:UnregisterAllEvents()
		frame.search:ClearFocus()
		frame.idInput:ClearFocus()
		GameTooltip:Hide()
	end)

	frame:Hide()
	return frame
end

function Picker:Open(targetId)
	local panel = self:GetTarget(targetId)
	if not panel or not self:CanEdit() then return nil end
	for _, instance in pairs(Shared.instances) do if instance ~= self and instance.frame then instance.frame:Hide() end end
	local frame = self.frame or self:CreateWindow()
	self.targetId = targetId
	frame.TitleText:SetText(string.format(self.titleFormat or L["CooldownPanelPickerTitle"], panel.name or tostring(targetId)))
	if not self.initialized then
		local _, classTag = UnitClass("player")
		self.classTag = classTag
		self.initialized = true
	end
	self.query = ""
	self.idType = self.idType or "SPELL"
	frame.search:SetText("")
	frame.idInput:SetText("")
	frame.status:SetText(string.format(L["CooldownPanelPickerTarget"], panel.name or tostring(targetId)))
	for _, button in ipairs(frame.idButtons) do button:SetSelected(button.entryType == self.idType) end
	self.catalogDirty = true
	self:EnsureCatalog()
	frame:RegisterEvent("UI_SCALE_CHANGED")
	frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	frame:Show()
	frame:Raise()
	self:Refresh()
	return frame
end

function Picker:ShowRowTooltip(row)
	local data = row.data
	if not data then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	local spellID = data.tooltipSpellID or data.spellID
	if data.kind == "SPELL" or data.kind == "CDM_AURA" or data.kind == "RACIAL" then spellID = spellID or data.value end
	local itemID = data.kind == "ITEM" and data.value or nil
	if data.kind == "SLOT" and GetInventoryItemID then itemID = GetInventoryItemID("player", data.value) end
	if data.kind == "MACRO" then
		spellID = GetMacroSpell and self.PlainID(GetMacroSpell(data.value)) or nil
		if not spellID and GetMacroItem then
			local _, link = GetMacroItem(data.value)
			if not (issecretvalue and issecretvalue(link)) and type(link) == "string" then itemID = tonumber(link:match("item:(%d+)")) end
		end
	end
	if data.category == "SPECIAL" then
		GameTooltip:SetText(data.name)
	elseif spellID then
		GameTooltip:SetSpellByID(spellID)
	elseif itemID then
		GameTooltip:SetItemByID(itemID)
	else
		GameTooltip:SetText(data.name)
	end
	if data.tooltipDescription then
		GameTooltip:AddLine(data.tooltipDescription, 0.88, 0.87, 0.80, true)
	elseif data.kind == "MACRO" or data.kind == "STANCE" or data.kind == "SLOT" or data.kind == "ACTION" then
		GameTooltip:AddLine(data.description or "", 0.75, 0.75, 0.75, true)
	end
	if self.AppendTooltip then self:AppendTooltip(data) end
	if data.trackingID then spellID = data.trackingID end
	if data.kind == "PRESET" then spellID = data.spellID end
	if spellID then GameTooltip:AddLine(tostring(spellID), 0.55, 0.55, 0.55) end
	GameTooltip:Show()
end

function Picker:Add(row)
	if not self:CanEdit() or not self:GetTarget(self.targetId) or (self:IsAdded(row) and not row.keepVisible) or row.disabled then return false end
	if row.kind == "MACRO" and (not GetMacroInfo or GetMacroInfo(row.value) ~= row.name) then Shared:InvalidateSources({ "MACRO" }); return false end
	local added = self:TryAdd(row)
	self:Refresh()
	if self.frame then self.frame.status:SetText(added and (row.keepVisible and row.name or string.format(L["CooldownPanelPickerAdded"], row.name or tostring(row.value))) or L["CooldownPanelPickerAddFailed"]) end
	return added and true or false
end
function Picker:AddByID()
	local value = tonumber(self.frame.idInput:GetText())
	if not value or value <= 0 or value ~= math.floor(value) then self.frame.status:SetText(L["CooldownPanelPickerInvalidID"]); return false end
	local added = self:Add({ key = "id:" .. value, kind = self.idType or self.idTypes[1], value = value, name = tostring(value) })
	if added then self.frame.idInput:SetText("") end
	return added
end
function Picker:NotifyChanged(targetId, rebuild)
	if targetId == nil or tostring(targetId) == tostring(self.targetId) then
		if rebuild then self.catalogDirty = true end
		self:QueueRefresh()
	end
end

-- Catalogs are shared by all consumers and only populated on first use.
Shared.driver = CreateFrame("Frame")
Shared.driver:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		for _, instance in pairs(Shared.instances) do instance:QueueRefresh() end
	elseif event == "UPDATE_MACROS" then Shared:InvalidateSources({ "MACRO" })
	elseif event == "SPELL_DATA_LOAD_RESULT" then Shared:InvalidateSources({ "SPELL", "CDM_AURA", "TALENT" })
	elseif event == "BAG_UPDATE_DELAYED" or event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then Shared:InvalidateSources({ "ITEM" })
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then Shared:InvalidateSources({ "ITEM", "CDM_AURA" })
	elseif event:find("COOLDOWN_VIEWER", 1, true) then Shared:InvalidateSources({ "CDM_AURA" })
	else Shared:InvalidateSources() end
end)
for _, event in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "SPELL_TEXT_UPDATE", "UPDATE_MACROS", "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "TRAIT_CONFIG_UPDATED", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_PVP_TALENT_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "COOLDOWN_VIEWER_DATA_LOADED", "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED", "COOLDOWN_VIEWER_TABLE_HOTFIXED", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "SPELL_DATA_LOAD_RESULT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
	pcall(Shared.driver.RegisterEvent, Shared.driver, event)
end
