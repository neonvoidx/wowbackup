local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end
local CP = addon.Aura.CooldownPanels
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Shared = addon.EntryPicker
local Picker = Shared:Create("CooldownPanelTalent", {
	sourceKinds = { "TALENT" },
	idTypes = { "SPELL" },
	titleFormat = L["CooldownPanelTalentPickerTitle"],
	actionText = _G.CHOOSE or _G.OKAY,
})
CP.TalentPicker = Picker
Picker.categories = {
	{ id = "ALL", label = _G.TALENTS or L["CooldownPanelRequiredTalentSpellID"] },
	{ id = "PVP_TALENTS", label = _G.PVP or "PvP" },
	{ id = "ID", label = L["CooldownPanelPickerByID"] },
}

function Picker:GetTarget(target)
	local panel = target and CP:GetPanel(target.panelId)
	local entry = panel and panel.entries and panel.entries[target.entryId]
	if not entry or entry ~= target.entry then return nil end
	return { name = CP:GetEntryStandaloneTitle(entry) }
end

function Picker:IsAdded(row)
	return self:GetTarget(self.targetId) and tonumber(self.targetId.entry.requiredTalentSpellID) == row.value or false
end

function Picker:PrepareRow(row)
	row.keepVisible = true
	return Shared.Methods.PrepareRow(self, row)
end

function Picker:GetButtonText(row)
	return self:IsAdded(row) and (_G.SELECTED or _G.OKAY) or self.actionText
end

function Picker:ExtendCatalog(append)
	append({ key = "none", kind = "NONE", value = 0, name = _G.NONE, category = "TALENTS", keepVisible = true })
end

function Picker:TryAdd(row)
	if not self:GetTarget(self.targetId) then return false end
	local selected = CP:SetEntryRequiredTalent(self.targetId.panelId, self.targetId.entryId, row.value)
	if selected and self.frame then self.frame:Hide() end
	return selected
end

function CP:GetRequiredTalentText(entry)
	local spellID = tonumber(entry and entry.requiredTalentSpellID)
	if not spellID or spellID <= 0 then return _G.NONE end
	local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or tostring(spellID)
	local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
	return icon and ("|T" .. tostring(icon) .. ":16:16|t " .. name) or name
end

function CP:SetEntryRequiredTalent(panelId, entryId, spellID)
	if not Picker:CanEdit() then return false end
	local panel = self:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId]
	if not entry or (entry.type ~= "SPELL" and entry.type ~= "MACRO") then return false end
	local id = tonumber(spellID)
	if not id or id < 0 or id > 2147483647 or id ~= math.floor(id) then return false end
	entry.requiredTalentSpellID = id
	self:RefreshPanel(panelId)
	self:RefreshEditor()
	if self.BlizzardEditor and self.BlizzardEditor.RefreshPanel then self.BlizzardEditor:RefreshPanel(panelId) end
	self:RefreshLayoutEntryStandaloneMenu()
	return true
end

function CP:BuildRequiredTalentMenu(root, panelId, entryId)
	local panel = self:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId]
	if not entry then return end
	local id = tonumber(entry.requiredTalentSpellID) or 0
	root:CreateRadio(_G.NONE, function() return id == 0 end, function() self:SetEntryRequiredTalent(panelId, entryId, 0) end)
	if id > 0 then root:CreateRadio(self:GetRequiredTalentText(entry), function() return true end, function() end) end
	root:CreateDivider()
	root:CreateButton(_G.SEARCH, function() self:ShowRequiredTalentPicker(panelId, entryId) end)
end

function CP:ShowRequiredTalentPicker(panelId, entryId)
	local panel = self:GetPanel(panelId)
	local entry = panel and panel.entries and panel.entries[entryId]
	if not entry or (entry.type ~= "SPELL" and entry.type ~= "MACRO") then return nil end
	return Picker:Open({ panelId = panelId, entryId = entryId, entry = entry })
end
