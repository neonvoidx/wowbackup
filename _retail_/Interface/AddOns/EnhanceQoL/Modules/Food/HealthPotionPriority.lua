local addon = _G.EnhanceQoL
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local P = {}
addon.Health.PotionPriority = P

function P.GetFamily(item)
	-- Quality variants share a stable catalog key apart from their trailing rank.
	return item.key and item.key:gsub("%d+$", "") or tostring(item.id)
end

function P.GetFamilies()
	local families = {}
	for _, item in ipairs(addon.Health.healthList or {}) do
		if item.type == "potion" then families[item.id] = P.GetFamily(item) end
	end
	return families
end

function P.GetSelection()
	local families, seen, selection = P.GetFamilies(), {}, {}
	for _, id in ipairs(addon.db.healthPotionPriority or {}) do
		local family = families[id] or tostring(id)
		if not seen[family] then
			selection[#selection + 1] = id
			seen[family] = true
		end
	end
	return selection
end

function P.GetRanks()
	local families, familyRanks, ranks = P.GetFamilies(), {}, {}
	for index, id in ipairs(P.GetSelection()) do
		familyRanks[families[id] or tostring(id)] = index
	end
	for id, family in pairs(families) do
		ranks[id] = familyRanks[family]
	end
	return ranks
end

function P.IsPotion(id)
	for _, item in ipairs(addon.Health.healthList or {}) do
		if item.id == id and item.type == "potion" then return true end
	end
	return false
end

function P.Refresh()
	addon.Health.functions.updateHealthMacro(false)
end

function P.Add(id)
	id = tonumber(id)
	if not id or not P.IsPotion(id) or P.GetRanks()[id] then return end
	addon.db.healthPotionPriority = P.GetSelection()
	table.insert(addon.db.healthPotionPriority, id)
	P.Refresh()
end

function P.Remove(id)
	local list = P.GetSelection()
	for index, value in ipairs(list) do
		if value == id then
			table.remove(list, index)
			addon.db.healthPotionPriority = list
			P.Refresh()
			return
		end
	end
end

function P.Move(fromIndex, toIndex)
	local list = P.GetSelection()
	if not list[fromIndex] or toIndex < 1 or toIndex > #list then return end
	table.insert(list, toIndex, table.remove(list, fromIndex))
	addon.db.healthPotionPriority = list
	P.Refresh()
end

function P.GetLabel(id)
	local name = C_Item.GetItemInfo(id)
	if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
	if not name then return ("item:%d"):format(id) end
	return name:gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
end

function P.GetRepresentative(id)
	local families = P.GetFamilies()
	local family, best = families[id], nil
	local list = addon.Health.filteredHealth
	if not list or #list == 0 then list = addon.Health.healthList end
	for _, item in ipairs(list or {}) do
		if family and families[item.id] == family and (item.requiredLevel or 0) <= UnitLevel("player") then
			local owned = item.getCount and item.getCount() > 0 or false
			local bestOwned = best and best.getCount and best.getCount() > 0 or false
			if not best or (owned and not bestOwned) or (owned == bestOwned and (item.heal or 0) > (best.heal or 0)) then best = item end
		end
	end
	return best and best.id or id
end

function P.GetEntries()
	local entries = {}
	for _, id in ipairs(P.GetSelection()) do
		local itemID = P.GetRepresentative(id)
		entries[#entries + 1] = { id = id, itemID = itemID, label = P.GetLabel(itemID), icon = C_Item.GetItemIconByID(itemID), showID = false }
	end
	return entries
end

function P.GetHealing(id)
	for _, item in ipairs(addon.Health.filteredHealth or {}) do
		if item.id == id then
			if issecretvalue and issecretvalue(item.heal) then return 0 end
			return item.heal or 0
		end
	end
	for _, item in ipairs(addon.Health.healthList or {}) do
		if item.id == id then
			if item.healFunc and not InCombatLockdown() then
				local maxHP = UnitHealthMax("player")
				if not issecretvalue or not issecretvalue(maxHP) then return item.healFunc(maxHP) end
			end
			return item.heal or 0
		end
	end
	return 0
end

function P.GetOptions()
	local ranks, seen, options = P.GetRanks(), {}, {}
	for _, item in ipairs(addon.Health.healthList or {}) do
		local family = P.GetFamily(item)
		if item.type == "potion" and not ranks[item.id] and not seen[family] and (item.requiredLevel or 0) <= UnitLevel("player") then
			seen[family] = true
			local id = P.GetRepresentative(item.id)
			options[#options + 1] = {
				id = id,
				label = P.GetLabel(id),
				icon = C_Item.GetItemIconByID(id) or 134400,
				expansion = select(15, C_Item.GetItemInfo(id)) or -1,
				healing = P.GetHealing(id),
			}
		end
	end
	table.sort(options, function(a, b)
		if a.expansion ~= b.expansion then return a.expansion > b.expansion end
		if a.healing ~= b.healing then return a.healing > b.healing end
		if a.label ~= b.label then return a.label < b.label end
		return a.id < b.id
	end)
	return options
end

function P.ShowTooltip(owner, id)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetItemByID(id)
	GameTooltip:Show()
end

function P.HideTooltip(owner)
	if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

function P.RenderSettings(parent, app, control, state)
	local UI = addon.LibSettingsDesigner.UI
	parent._state = state
	UI.AddReorderListWidget(parent, app, control, { startY = 0 })
	local entries = P.GetEntries()
	for index, row in ipairs(parent.reorderRows or {}) do
		local entry = entries[index]
		if entry then
			row:SetScript("OnEnter", function(owner) P.ShowTooltip(owner, entry.itemID) end)
			row:SetScript("OnLeave", P.HideTooltip)
			row:SetScript("OnHide", P.HideTooltip)
		end
	end
	local picker = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	picker:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, 0)
	picker:SetWidth(260)
	picker:SetDefaultText(L["healthPotionPriorityAdd"])
	picker:SetEnabled(app:IsControlEnabled(control))
	picker:SetupMenu(function(_, root)
		root:SetScrollMode(360)
		local submenu, expansion
		for _, option in ipairs(P.GetOptions()) do
			if expansion ~= option.expansion then
				expansion = option.expansion
				local name = _G["EXPANSION_NAME" .. expansion] or _G.OTHER
				submenu = root:CreateButton(name)
				submenu:SetScrollMode(360)
			end
			local text = ("|T%d:18:18:0:0|t %s"):format(option.icon, option.label)
			local entry = submenu:CreateButton(text, function()
				if not app:IsControlEnabled(control) then return end
				P.Add(option.id)
				C_Timer.After(0, function()
					if parent:IsShown() and state.frame:IsShown() then state:RenderContent() end
				end)
			end)
			entry:SetTooltip(function(tooltip) tooltip:SetItemByID(option.id) end)
		end
	end)
	return picker
end

function P.RegisterSettings(category, section, parentCheck)
	addon.functions.SettingsCreateCustom(category, {
		var = "healthPotionPriority",
		text = L["healthPotionPriority"],
		desc = L["healthPotionPriorityDesc"],
		newTagID = "healthPotionPriority",
		parentCheck = parentCheck,
		parentSection = section,
		default = {},
		get = function() return addon.db.healthPotionPriority or {} end,
		set = function(value)
			addon.db.healthPotionPriority = value
			P.Refresh()
		end,
		getEntries = P.GetEntries,
		removeEntry = P.Remove,
		moveEntry = P.Move,
		emptyText = L["healthPotionPriorityEmpty"],
		refreshOnChange = true,
		getHeight = function() return 150 + #P.GetSelection() * 32 end,
		render = P.RenderSettings,
	})
end
