local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local wipe = wipe

local function isCheckboxEnabled(var)
	local entry = addon.SettingsLayout.elements and addon.SettingsLayout.elements[var]
	return entry and entry.setting and entry.setting:GetValue() == true
end

local function refreshDrinks()
	if addon.functions.updateAllowedDrinks then addon.functions.updateAllowedDrinks() end
	if addon.functions.updateAvailableDrinks then addon.functions.updateAvailableDrinks(false) end
end

local function refreshHealthMacro()
	if addon.Health and addon.Health.functions and addon.Health.functions.syncEventRegistration then addon.Health.functions.syncEventRegistration() end
	if addon.Health and addon.Health.functions and addon.Health.functions.updateHealthMacro then addon.Health.functions.updateHealthMacro(false) end
end

local function buildDrinkMacroSettings()
	local cDrink = addon.SettingsLayout.rootGAMEPLAY
	if not cDrink then return end

	local convenienceSection = addon.SettingsLayout.gameplayConvenienceSection
	if not convenienceSection then
		convenienceSection = addon.functions.SettingsCreateExpandableSection(cDrink, {
			name = L["MacrosAndConsumables"] or "Macros & Consumables",
			newTagID = "MacrosAndConsumables",
			configPageKey = "MacrosConsumables",
			iconKey = "macros",
			expanded = false,
			colorizeTitle = false,
			modernOnly = true,
		})
		addon.SettingsLayout.gameplayConvenienceSection = convenienceSection
	end

	addon.SettingsLayout.drinkMacroCategory = cDrink

	addon.functions.SettingsCreateHeadline(cDrink, L["foodDrinkMacroForever"], { parentSection = convenienceSection })

	addon.functions.SettingsCreateInlineHint(cDrink, L["foodDrinkMacroRecoveryHint"], {
		id = "drinkMacroPurposeHint",
		parentSection = convenienceSection,
	})
	addon.functions.SettingsCreateInlineHint(cDrink, string.format(L["macroActionBarHint"], "EnhanceQoLDrinkMacro"), {
		id = "drinkMacroActionBarHint",
		parentSection = convenienceSection,
	})

	local drinkData = {
		{
			var = "drinkMacroEnabled",
			text = L["macroAutoUpdateEnabled"],
			desc = L["foodDrinkMacroEnabledForeverDesc"],
			newTagID = "foodDrinkMacroForever",
			func = function(value)
				addon.db.drinkMacroEnabled = value and true or false
				refreshDrinks()
			end,
			default = false,
			children = {
				{
					var = "drinkMacroIncludeFood",
					text = L["drinkMacroIncludeFood"],
					desc = L["drinkMacroIncludeFoodDesc"],
					newTagID = "drinkMacroIncludeFood",
					func = function(value)
						addon.db.drinkMacroIncludeFood = value and true or false
						refreshDrinks()
					end,
					parentCheck = function() return isCheckboxEnabled("drinkMacroEnabled") end,
					parent = true,
					default = false,
					type = Settings.VarType.Boolean,
					sType = "checkbox",
				},
				{
					var = "preferMageFood",
					text = L["preferConjuredFoodForever"],
					desc = L["preferConjuredFoodForeverDesc"],
					func = function(value)
						addon.db.preferMageFood = value and true or false
						refreshDrinks()
						refreshHealthMacro()
					end,
					parentCheck = function() return isCheckboxEnabled("drinkMacroEnabled") end,
					parent = true,
					default = true,
					type = Settings.VarType.Boolean,
					sType = "checkbox",
				},
				{
					var = "useManaPotionInCombat",
					text = L["useManaPotionInCombatForever"],
					func = function(value)
						addon.db.useManaPotionInCombat = value and true or false
						if addon.functions.updateAvailableDrinks then addon.functions.updateAvailableDrinks(false) end
					end,
					desc = L["useManaPotionInCombatForeverDesc"],
					parentCheck = function() return isCheckboxEnabled("drinkMacroEnabled") end,
					parent = true,
					default = false,
					type = Settings.VarType.Boolean,
					sType = "checkbox",
				},
				{
					var = "minManaFoodValue",
					text = L["minimumManaRestoreForever"],
					desc = L["minimumManaRestoreForeverDesc"],
					get = function() return addon.db.minManaFoodValue or 0 end,
					set = function(value)
						value = tonumber(value) or 0
						if value < 0 then value = 0 end
						if value > 100 then value = 100 end
						addon.db.minManaFoodValue = value
						refreshDrinks()
					end,
					min = 0,
					max = 100,
					step = 1,
					parentCheck = function() return isCheckboxEnabled("drinkMacroEnabled") end,
					parent = true,
					default = 0,
					sType = "slider",
				},
			},
		},
	}
	local function applyParentSection(entry)
		entry.parentSection = convenienceSection
		if entry.children then
			for _, child in pairs(entry.children) do
				applyParentSection(child)
			end
		end
	end
	for _, entry in ipairs(drinkData) do
		applyParentSection(entry)
	end
	local drinkToggle = drinkData[1]
	local drinkSettings = drinkToggle.children
	drinkToggle.children = nil
	local drinkEnable = addon.functions.SettingsCreateCheckbox(cDrink, drinkToggle)

	addon.functions.SettingsCreateInlineHint(cDrink, L["macroAutoUpdateHint"], {
		id = "drinkMacroAutoUpdateHint",
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateSectionHeader(cDrink, L["Out of combat"], { parentSection = convenienceSection })
	for _, entry in ipairs(drinkSettings) do
		entry.element = drinkEnable
		if entry.var ~= "useManaPotionInCombat" then
			if entry.sType == "slider" then
				addon.functions.SettingsCreateSlider(cDrink, entry)
			else
				addon.functions.SettingsCreateCheckbox(cDrink, entry)
			end
		end
	end
	addon.functions.SettingsCreateSectionHeader(cDrink, L["In combat"], { parentSection = convenienceSection })
	for _, entry in ipairs(drinkSettings) do
		if entry.var == "useManaPotionInCombat" then addon.functions.SettingsCreateCheckbox(cDrink, entry) end
	end

	addon.functions.SettingsCreateHeadline(cDrink, L["Bandage Macro"], { parentSection = convenienceSection })
	addon.functions.SettingsCreateCheckbox(cDrink, {
		var = "bandageMacroEnabled",
		text = L["Enable Bandage Macro"],
		desc = L["Enable Bandage Macro Desc"],
		richNote = {
			blocks = {
				{ text = string.format(L["%s - place on your bar (updates outside combat)"], "EnhanceQoLBandageMacro") },
			},
		},
		func = function(value)
			addon.db.bandageMacroEnabled = value and true or false
			addon.Bandages.functions.updateBandageMacro()
		end,
		default = false,
		newTagID = "bandageMacroEnabled",
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateHeadline(cDrink, L["Health Macro"], { parentSection = convenienceSection })

	addon.functions.SettingsCreateInlineHint(cDrink, L["healingMacroPurposeHint"], {
		id = "healthMacroPurposeHint",
		parentSection = convenienceSection,
	})
	addon.functions.SettingsCreateInlineHint(cDrink, string.format(L["macroActionBarHint"], "EnhanceQoLHealthMacro"), {
		id = "healthMacroActionBarHint",
		parentSection = convenienceSection,
	})

	local function defaultPriority() return { "stone", "potion", "none", "none" } end

	local function ensureHealthPriority()
		if addon.Health and addon.Health.functions and addon.Health.functions.ensurePriorityOrder then addon.Health.functions.ensurePriorityOrder() end
	end

	local function notifyPriorityDropdowns()
		local vars = { "EQOL_healthPrioritySlot1", "EQOL_healthPrioritySlot2", "EQOL_healthPrioritySlot3", "EQOL_healthPrioritySlot4" }
		for _, var in ipairs(vars) do
			if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate(var) end
		end
	end

	local function setCustomSpellsUsage(value)
		addon.db.healthUseCustomSpells = value and true or false
		addon.db.healthPriorityOrder = addon.db.healthPriorityOrder or defaultPriority()
		if value then
			local exists = false
			for i = 1, 4 do
				if addon.db.healthPriorityOrder[i] == "spell" then
					exists = true
					break
				end
			end
			if not exists then
				for i = 1, 4 do
					if addon.db.healthPriorityOrder[i] == "none" then
						addon.db.healthPriorityOrder[i] = "spell"
						break
					end
				end
			end
		else
			for i = 1, 4 do
				if addon.db.healthPriorityOrder[i] == "spell" then addon.db.healthPriorityOrder[i] = "none" end
			end
		end
		ensureHealthPriority()
		refreshHealthMacro()
		notifyPriorityDropdowns()
	end

	ensureHealthPriority()

	local healthEnable = addon.functions.SettingsCreateCheckbox(cDrink, {
		var = "healthMacroEnabled",
		text = L["macroAutoUpdateEnabled"],
		func = function(value)
			addon.db.healthMacroEnabled = value and true or false
			refreshHealthMacro()
		end,
		default = false,
		notify = "healthUseCustomSpells",
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateInlineHint(cDrink, L["macroAutoUpdateHint"], {
		id = "healthMacroAutoUpdateHint",
		parentSection = convenienceSection,
	})

	local function healthParentCheck() return isCheckboxEnabled("healthMacroEnabled") end

	addon.functions.SettingsCreateSectionHeader(cDrink, L["Out of combat"], { parentSection = convenienceSection })

	addon.functions.SettingsCreateCheckbox(cDrink, {
		var = "healthUseFood",
		text = L["healthUseFoodForever"],
		desc = L["healthUseFoodForeverDesc"],
		func = function(value)
			addon.db.healthUseFood = value and true or false
			refreshHealthMacro()
		end,
		parentCheck = healthParentCheck,
		parent = true,
		element = healthEnable.element,
		default = true,
		type = Settings.VarType.Boolean,
		newTagID = "healthUseFoodForever",
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateSectionHeader(cDrink, L["healingMacroOptions"], { parentSection = convenienceSection })

	addon.functions.SettingsCreateCheckbox(cDrink, {
		var = "healthStopCasting",
		text = L["healthStopCasting"],
		desc = L["healthStopCastingDesc"],
		func = function(value)
			addon.db.healthStopCasting = value and true or false
			refreshHealthMacro()
		end,
		parentCheck = healthParentCheck,
		parent = true,
		element = healthEnable.element,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateSectionHeader(cDrink, L["PriorityOrder"], { parentSection = convenienceSection })

	local priorityLabels = {
		spell = L["Custom Spells"] or (L["Custom Spells"] or "Custom Spells"),
		stone = L["CategoryHealthstones"] or (L["Prefer Healthstone first"] or "Healthstones"),
		potion = L["CategoryPotions"] or "Potions",
		none = NONE,
	}

	local basePriorityOrder = { "stone", "potion", "spell" }
	local priorityOrders = { {}, {}, {}, {} }

	local function priorityOptions(slot)
		local used = {}
		for i = 1, slot - 1 do
			local current = addon.db.healthPriorityOrder and addon.db.healthPriorityOrder[i]
			if current and current ~= "none" then used[current] = true end
		end
		local list = {}
		local order = priorityOrders[slot] or {}
		wipe(order)
		priorityOrders[slot] = order
		for _, key in ipairs(basePriorityOrder) do
			if not used[key] then
				if key == "spell" and not addon.db.healthUseCustomSpells then
				else
					list[key] = priorityLabels[key]
					table.insert(order, key)
				end
			end
		end
		list["none"] = priorityLabels.none
		table.insert(order, "none")
		return list
	end

	for i = 1, 4 do
		local defaultOrder = defaultPriority()
		addon.functions.SettingsCreateDropdown(cDrink, {
			var = "healthPrioritySlot" .. i,
			text = (L["PrioritySlot"] or "Priority %d"):format(i),
			parentCheck = healthParentCheck,
			parent = true,
			element = healthEnable.element,
			listFunc = function() return priorityOptions(i) end,
			order = priorityOrders[i],
			default = defaultOrder[i] or "none",
			get = function()
				ensureHealthPriority()
				local cur = addon.db.healthPriorityOrder and addon.db.healthPriorityOrder[i] or "none"
				local list = priorityOptions(i)
				if not list[cur] then cur = "none" end
				return cur
			end,
			set = function(value)
				ensureHealthPriority()
				addon.db.healthPriorityOrder = addon.db.healthPriorityOrder or defaultPriority()
				addon.db.healthPriorityOrder[i] = value
				if value ~= "none" then
					for j = 1, 4 do
						if j ~= i and addon.db.healthPriorityOrder[j] == value then addon.db.healthPriorityOrder[j] = "none" end
					end
				end
				ensureHealthPriority()
				if addon.Health and addon.Health.functions and addon.Health.functions.updateHealthMacro then addon.Health.functions.updateHealthMacro(false) end
				notifyPriorityDropdowns()
			end,
			parentSection = convenienceSection,
		})
	end

	addon.Health.PotionPriority.RegisterSettings(cDrink, convenienceSection, healthParentCheck)

	addon.functions.SettingsCreateSectionHeader(cDrink, L["Reset condition"], { parentSection = convenienceSection })
	addon.Health.Reset.RegisterSettings(cDrink, convenienceSection, healthParentCheck)

	addon.functions.SettingsCreateSectionHeader(cDrink, L["Custom Spells"], { parentSection = convenienceSection })

	addon.functions.SettingsCreateCheckbox(cDrink, {
		var = "healthUseCustomSpells",
		text = L["Use custom spells"] or "Use custom spells",
		desc = L["healthUseCustomSpellsDesc"],
		func = setCustomSpellsUsage,
		parentCheck = healthParentCheck,
		parent = true,
		element = healthEnable.element,
		default = false,
		type = Settings.VarType.Boolean,
		parentSection = convenienceSection,
	})

	local function customSpellsEnabled() return healthParentCheck() and addon.db.healthUseCustomSpells == true end
	local customSpellsParent = addon.SettingsLayout.elements["healthUseCustomSpells"] and addon.SettingsLayout.elements["healthUseCustomSpells"].element or healthEnable.element

	local customSpellOrder = {}

	StaticPopupDialogs["EQOL_ADD_HEALTH_SPELL"] = StaticPopupDialogs["EQOL_ADD_HEALTH_SPELL"]
		or {
			text = L["Add SpellID"] or "Add SpellID",
			button1 = OKAY,
			button2 = CANCEL,
			hasEditBox = true,
			EditBoxOnEscapePressed = addon.functions.CancelPopupOnEscape,
			EditBoxOnEnterPressed = addon.functions.AcceptPopupOnEnter,
			maxLetters = 10,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnAccept = function(self)
				local input = self.editBox or self.GetEditBox and self:GetEditBox()
				local text = input and input:GetText() or nil
				local sid = tonumber(text)
				if not sid then return end
				local info = C_Spell.GetSpellInfo(sid)
				if not info or not info.name then return end
				addon.db.healthCustomSpells = addon.db.healthCustomSpells or {}
				for _, v in ipairs(addon.db.healthCustomSpells) do
					if v == sid then return end
				end
				table.insert(addon.db.healthCustomSpells, sid)
				if addon.Health and addon.Health.functions and addon.Health.functions.updateHealthMacro then addon.Health.functions.updateHealthMacro(false) end
				if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate("EQOL_healthCustomRemove") end
			end,
		}

	addon.functions.SettingsCreateButton(cDrink, {
		var = "healthCustomAdd",
		text = L["Add SpellID"] or "Add SpellID",
		desc = L["healthCustomAddDesc"],
		func = function()
			if not customSpellsEnabled() then return end
			local dialog = StaticPopupDialogs["EQOL_ADD_HEALTH_SPELL"]
			if dialog and dialog.OnShow == nil then
				dialog.OnShow = function(self)
					local editBox = self.editBox or self.GetEditBox and self:GetEditBox()
					if editBox then
						editBox:SetText("")
						editBox:SetFocus()
					end
				end
			end
			StaticPopup_Show("EQOL_ADD_HEALTH_SPELL")
		end,
		parent = true,
		element = customSpellsParent,
		parentCheck = customSpellsEnabled,
		parentSection = convenienceSection,
	})

	local function customSpellList()
		local list = { [""] = "" }
		wipe(customSpellOrder)
		table.insert(customSpellOrder, "")
		local spells = addon.db.healthCustomSpells or {}
		for _, sid in ipairs(spells) do
			local info = C_Spell.GetSpellInfo(sid)
			local name = info and info.name or tostring(sid)
			local key = tostring(sid)
			list[key] = string.format("%s (%s)", name, key)
			table.insert(customSpellOrder, key)
		end
		table.sort(customSpellOrder, function(a, b) return list[a] < list[b] end)
		return list
	end

	addon.functions.SettingsCreateDropdown(cDrink, {
		var = "healthCustomRemove",
		text = L["Custom Spells"] or "Custom Spells",
		desc = L["healthCustomRemoveDesc"],
		parentCheck = customSpellsEnabled,
		parent = true,
		element = customSpellsParent,
		listFunc = customSpellList,
		order = customSpellOrder,
		default = "",
		get = function() return "" end,
		set = function(value)
			local sid = tonumber(value)
			if not sid or not addon.db.healthCustomSpells then return end
			for i, v in ipairs(addon.db.healthCustomSpells) do
				if v == sid then
					table.remove(addon.db.healthCustomSpells, i)
					if addon.Health and addon.Health.functions and addon.Health.functions.updateHealthMacro then addon.Health.functions.updateHealthMacro(false) end
					if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate("EQOL_healthCustomRemove") end
					return
				end
			end
		end,
		parentSection = convenienceSection,
	})

	addon.functions.SettingsCreateText(
		cDrink,
		L["healthCustomSpellsHint"] or "Selecting a spell in the dropdown removes it (the field stays blank by design). The macro uses any custom spells you know.",
		{
			parent = customSpellsParent,
			parentCheck = customSpellsEnabled,
			parentSection = convenienceSection,
		}
	)
end

function addon.functions.initDrinkMacro()
	if addon.SettingsLayout and addon.SettingsLayout.drinkMacroSettingsReady then return end
	if not (addon.functions and addon.functions.SettingsCreateCategory) then return end
	if not (addon.SettingsLayout and addon.SettingsLayout.rootGAMEPLAY) then return end
	buildDrinkMacroSettings()
	addon.SettingsLayout.drinkMacroSettingsReady = true
end
