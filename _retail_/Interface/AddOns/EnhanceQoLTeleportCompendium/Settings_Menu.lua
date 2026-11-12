local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local Menu = {}

function Menu.Refresh()
	if Menu.refreshPending then return end
	Menu.refreshPending = true
	C_Timer.After(0, function()
		Menu.refreshPending = nil
		local functions = addon.MythicPlus.functions
		functions.setRandomHearthstone(true)
		functions.NotifyTeleportFavoritesChanged()
		functions.toggleFrame()
		functions.RefreshWorldMapTeleportPanel()
	end)
end

function Menu.AddCheckbox(root, key, label, description)
	local entry = root:CreateCheckbox(label, function() return addon.db[key] == true end, function()
		if InCombatLockdown() then return end
		addon.db[key] = not addon.db[key]
		Menu.Refresh()
	end)
	entry:SetEnabled(not InCombatLockdown())
	if description then
		entry:SetTooltip(function(tooltip)
			tooltip:SetText(label)
			tooltip:AddLine(description, 1, 1, 1, true)
		end)
	end
	return entry
end

function Menu.IsRandom()
	local selection = addon.db.teleportsPreferredHearthstone
	return type(selection) ~= "table" or next(selection) == nil
end

function addon.MythicPlus.functions.BuildTeleportSettingsMenu(_, root)
	root:SetTag("MENU_EQOL_TELEPORT_COMPENDIUM_SETTINGS")
	Menu.AddCheckbox(root, "teleportFrame", L["teleportEnabled"], L["teleportEnabledDesc"])
	Menu.AddCheckbox(root, "teleportsWorldMapShowSeason", L["teleportsWorldMapShowSeason"], L["teleportsWorldMapShowSeasonDesc"])
	Menu.AddCheckbox(root, "portalHideMissing", L["portalHideMissing"], L["portalHideMissingDesc"])
	Menu.AddCheckbox(root, "portalShowTooltip", L["portalShowTooltip"], L["portalShowTooltipDesc"])

	local hearthstones = root:CreateButton(L["teleportsPreferredHearthstone"])
	hearthstones:SetScrollMode(400)
	hearthstones:CreateCheckbox(L["teleportsPreferredHearthstoneRandom"], Menu.IsRandom, function()
		if InCombatLockdown() then return end
		addon.db.teleportsPreferredHearthstone = {}
		Menu.Refresh()
	end):SetEnabled(not InCombatLockdown())
	hearthstones:CreateDivider()
	local options = addon.MythicPlus.functions.GetHearthstoneSelectionOptions(true)
	for _, option in ipairs(options) do
		local key = option.value
		hearthstones:CreateCheckbox(option.text, function()
			local selection = addon.db.teleportsPreferredHearthstone
			return Menu.IsRandom() or (type(selection) == "table" and selection[key] == true)
		end, function()
			if InCombatLockdown() then return end
			if Menu.IsRandom() then
				local selection = {}
				for _, owned in ipairs(options) do selection[owned.value] = true end
				addon.db.teleportsPreferredHearthstone = selection
			end
			local selection = addon.db.teleportsPreferredHearthstone
			selection[key] = not selection[key] or nil
			local allSelected = #options > 0
			for _, owned in ipairs(options) do
				if selection[owned.value] ~= true then allSelected = false; break end
			end
			if allSelected then addon.db.teleportsPreferredHearthstone = {} end
			Menu.Refresh()
		end):SetEnabled(not InCombatLockdown())
	end
end
