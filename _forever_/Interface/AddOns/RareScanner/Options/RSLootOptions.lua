-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LibStub = _G.LibStub
local RareScanner = LibStub("AceAddon-3.0"):GetAddon("RareScanner")
local AL = LibStub("AceLocale-3.0"):GetLocale("RareScanner", false)
local LibDialog = LibStub("LibDialog-1.0RS")

local RSLootOptions = private.NewLib("RareScannerLootOptions")

-- RareScanner database libraries
local RSConfigDB = private.ImportLib("RareScannerConfigDB")
local RSGeneralDB = private.ImportLib("RareScannerGeneralDB")
local RSCollectionsDB  = private.ImportLib("RareScannerCollectionsDB")

-- RareScanner internal libraries
local RSConstants = private.ImportLib("RareScannerConstants")
local RSUtils = private.ImportLib("RareScannerUtils")
local RSLogger = private.ImportLib("RareScannerLogger")

-- RareScanner service libraries
local RSMinimap = private.ImportLib("RareScannerMinimap")
local RSMap = private.ImportLib("RareScannerMap")

local options

-----------------------------------------------------------------------
-- Item qualities
-----------------------------------------------------------------------

private.ITEM_QUALITY = {
	[Enum.ItemQuality.Poor] = ITEM_QUALITY0_DESC,
	[Enum.ItemQuality.Common] = ITEM_QUALITY1_DESC,
	[Enum.ItemQuality.Uncommon] = ITEM_QUALITY2_DESC,
	[Enum.ItemQuality.Rare] = ITEM_QUALITY3_DESC,
	[Enum.ItemQuality.Epic] = ITEM_QUALITY4_DESC,
	[Enum.ItemQuality.Legendary] = ITEM_QUALITY5_DESC,
	[Enum.ItemQuality.Artifact] = ITEM_QUALITY6_DESC,
	[Enum.ItemQuality.Heirloom] = ITEM_QUALITY7_DESC,
}

-- Same qualities with the color of each one (used by the dropdowns)
local function GetColoredItemQualities()
	local qualities = {}
	for quality, name in pairs(private.ITEM_QUALITY) do
		qualities[quality] = ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(name)
	end

	return qualities
end

-----------------------------------------------------------------------
-- Item classes
-----------------------------------------------------------------------

private.ITEM_CLASSES = {
	[0] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 13, 14, 15 }, --Consumable
	[1] = { 0, 1, 2, 3, 4, 6, 7, 9, 10, 11, 12 }, --Container
	[2] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }, --Weapon
	-- [3] = { 0 }, --Jewelry (obsolete)
	[4] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, --Armor
	[5] = { 0 }, --Reagent
	[6] = { 2, 3 }, --Projectile
	[7] = { 1, 5, 6, 7, 8, 9, 10, 11, 12 }, --Trade Goods
	-- [8] = { 0 }, --Generic (obsolete)
	[9] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, --Recipe
	-- [10] = { 0 }, --Money (obsolete)
	[11] = { 2, 3 }, --Quiver
	[12] = { 0 }, --Quest
	[13] = { 0, 1 }, --Key
	-- [14] = { 0 }, --Permanent (obsolete)
	[15] = { 0, 1, 2, 3, 4, 5 }, --Miscellaneous
	-- [18] = { }, --WoW Token (no subcategories)
}

-----------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------

local main_categories

local function GetMainCategories()
	if (not main_categories) then
		main_categories = {}
		
		for k, v in pairs(private.ITEM_CLASSES) do
			main_categories[k] = C_Item.GetItemClassInfo(k)
		end
	end
	
	return main_categories
end

local function LoadSubcategoryCombo(mainClassID)
	options.args.filters.args.category_filters.args.lootFilters.values = {}
	for _, subcategoryID in ipairs(private.ITEM_CLASSES[mainClassID]) do
		options.args.filters.args.category_filters.args.lootFilters.values[subcategoryID] = C_Item.GetItemSubClassInfo(mainClassID, subcategoryID)
	end
end

-- Drop chance inputs: empty means no limit, otherwise a number between 0 and 100 (dot or comma as decimal separator)
local CHANCE_PATTERN = "^%d*[%.,]?%d*$"

local function ParseChance(value)
	if (not value or value == "") then
		return nil
	end

	return tonumber((value:gsub(",", ".")))
end

local function GetChanceText(chance)
	return chance and tostring(chance) or ""
end

-- Returns true if valid, or the error message to show
local function ValidateChance(value, otherChance, isMin)
	if (value == "") then
		return true
	end

	local chance = ParseChance(value)
	if (not chance or chance < 0 or chance > 100) then
		return AL["LOOT_FILTER_CHANCE_RANGE_ERROR"]
	end

	if (otherChance) then
		if (isMin and chance > otherChance) then
			return AL["LOOT_FILTER_CHANCE_MIN_ERROR"]
		elseif (not isMin and chance < otherChance) then
			return AL["LOOT_FILTER_CHANCE_MAX_ERROR"]
		end
	end

	return true
end

-- Items filtered individually (from the explorer, the tooltips or this panel) matching the search
local function GetFilteredItems()
	local items = {}
	local search = private.loot_individual_filter_input
	for itemID, _ in pairs(RSConfigDB.GetAllFilteredItems()) do
		local itemName, itemLink, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
		if (itemLink) then
			if (not search or search == "" or RSUtils.Contains(itemName, search)) then
				items[itemID] = string.format("|T%s:16|t %s", icon or 134400, itemLink)
			end
		else
			-- Not cached yet, it will be shown the next time the panel is refreshed
			C_Item.RequestLoadItemDataByID(itemID)
			if (not search or search == "") then
				items[itemID] = string.format("[%s]", itemID)
			end
		end
	end

	return items
end

-----------------------------------------------------------------------
-- Options tab: Display
-----------------------------------------------------------------------

local customLine = "custom_%s_line"

function RSLootOptions.GetLootOptions()	
	local customItemsPosition = 10
	
	if (not options) then
		private.loot_toggle_all = true
		private.loot_main_category_ID = nil
		
		options = {
			type = "group",
			name = AL["LOOT_OPTIONS"],
			handler = RareScanner,
			desc = AL["LOOT_OPTIONS"],
			args = {
				displayLoot = {
					order = 0,
					type = "toggle",
					name = AL["DISPLAY_LOOT_PANEL"],
					desc = AL["DISPLAY_LOOT_PANEL_DESC"],
					get = function() return RSConfigDB.IsDisplayingLootBar() end,
					set = function(_, value)
						RSConfigDB.SetDisplayingLootBar(value)
					end,
					width = "full",
				},
				display_options = {
					type = "group",
					order = 1,
					name = AL["LOOT_DISPLAY_OPTIONS"],
					handler = RareScanner,
					desc = AL["LOOT_DISPLAY_OPTIONS_DESC"],
					args = {
						lootTooltipPosition = {
							order = 0,
							type = "select",
							name = AL["LOOT_TOOLTIP_POSITION"],
							desc = AL["LOOT_TOOLTIP_POSITION_DESC"],
							values = private.TOOLTIP_POSITIONS,
							get = function() return RSConfigDB:GetLootTooltipPosition() end,
							set = function(_, value)
								RSConfigDB:SetLootTooltipPosition(value)
							end,
							width = "double",
							disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
						},
						itemsToShow = {
							order = 1,
							type = "range",
							name = AL["LOOT_MAX_ITEMS"],
							desc = AL["LOOT_MAX_ITEMS_DESC"],
							min	= 1,
							max	= 30,
							step	= 1,
							bigStep = 1,
							get = function() return RSConfigDB.GetMaxNumItemsToShow() end,
							set = function(_, value)
								RSConfigDB.SetMaxNumItemsToShow(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
						},
						itemsPerRow = {
							order = 2,
							type = "range",
							name = AL["LOOT_ITEMS_PER_ROW"],
							desc = AL["LOOT_ITEMS_PER_ROW_DESC"],
							min	= 1,
							max	= 30,
							step	= 1,
							bigStep = 1,
							get = function() return RSConfigDB.GetNumItemsPerRow() end,
							set = function(_, value)
								RSConfigDB.SetNumItemsPerRow(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
						}
					},
				},
				tooltips = {
					type = "group",
					order = 2,
					name = AL["MAP_TOOLTIPS"],
					handler = RareScanner,
					desc = AL["MAP_TOOLTIPS"],
					args = {
						commands = {
							order = 0,
							type = "toggle",
							name = AL["MAP_TOOLTIPS_COMMANDS"],
							desc = AL["MAP_TOOLTIPS_COMMANDS_DESC"],
							get = function() return RSConfigDB.IsShowingLootTooltipsCommands() end,
							set = function(_, value)
								RSConfigDB.SetShowingLootTooltipsCommands(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
						},
						covenantRequirement = {
							order = 1,
							type = "toggle",
							name = AL["LOOT_TOOLTIPS_COVENANT"],
							desc = AL["LOOT_TOOLTIPS_COVENANT_DESC"],
							get = function() return RSConfigDB.IsShowingCovenantRequirement() end,
							set = function(_, value)
								RSConfigDB.SetShowingCovenantRequirement(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
						},
						canImogit = {
							order = 2,
							type = "toggle",
							name = AL["LOOT_TOOLTIPS_CANIMOGIT"],
							desc = AL["LOOT_TOOLTIPS_CANIMOGIT_DESC"],
							get = function() return RSConfigDB.IsShowingLootCanimogitTooltip() end,
							set = function(_, value)
								RSConfigDB.SetShowingLootCanimogitTooltip(value)
							end,
							width = "full",
							disabled = function() return (not CanIMogIt or (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap())) end,
						},
						tsm = {
							order = 3,
							type = "toggle",
							name = AL["LOOT_TOOLTIPS_TSM"],
							desc = AL["LOOT_TOOLTIPS_TSM_DESC"],
							get = function() return RSConfigDB.IsShowingLootTSMTooltip() end,
							set = function(_, value)
								RSConfigDB.SetShowingLootTSMTooltip(value)
							end,
							width = "full",
							disabled = function() return (not TSM_APITSM_API or not TSM_API.GetCustomPriceValue or (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap())) end,
						}
					},
					disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
				},
				filters = {
					type = "group",
					order = 3,
					name = AL["LOOT_FILTERS"],
					handler = RareScanner,
					desc = AL["LOOT_FILTERS_DESC"],
					args = {
						separator_explorer = {
							order = 0,
							type = "header",
							name = AL["LOOT_EXPLORER"],
						},
						filter_explorer_desc = {
							order = 1,
							type = "description",
							name = AL["LOOT_EXPLORER_FILTER_LONG_DESC"]
						},
						filter_explorer = {
							order = 2,
							type = "toggle",
							name = AL["LOOT_EXPLORER_FILTER"],
							desc = AL["LOOT_EXPLORER_FILTER_DESC"],
							get = function() return RSConfigDB.IsFilteringByExplorerResults() end,
							set = function(_, value)
								if (value and RSUtils.GetTableLength(RSCollectionsDB.GetAllEntitiesCollectionsLoot()) == 0) then
									LibDialog:Spawn(RSConstants.EXPLORER_SCAN_NOT_DONE)
								else
									RSConfigDB.SetFilteringByExplorerResults(value)
								end
							end,
							width = "full"
						},
						show_mounts = {
							order = 3,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_MOUNTS"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_MOUNTS_DESC"],
							get = function() return RSConfigDB.IsShowingMissingMounts() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingMounts(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						show_pets = {
							order = 4,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_PETS"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_PETS_DESC"],
							get = function() return RSConfigDB.IsShowingMissingPets() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingPets(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						show_toys = {
							order = 5,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_TOYS"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_TOYS_DESC"],
							get = function() return RSConfigDB.IsShowingMissingToys() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingToys(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						show_appearances = {
							order = 6,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_APPEARANCES"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_APPEARANCES_DESC"],
							get = function() return RSConfigDB.IsShowingMissingAppearances() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingAppearances(value)
								if (not value) then
									RSConfigDB.SetShowingMissingClassAppearances(value)
								end
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						show_class_appearances = {
							order = 7,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_CLASS_APPEARANCES"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_CLASS_APPEARANCES_DESC"],
							get = function() return RSConfigDB.IsShowingMissingClassAppearances() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingClassAppearances(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults() or not RSConfigDB.IsShowingMissingAppearances()) end,
						},
						show_decor = {
							order = 9,
							type = "toggle",
							name = AL["LOOT_EXPLORER_SHOW_MISSING_DECOR"],
							desc = AL["LOOT_EXPLORER_SHOW_MISSING_DECOR_DESC"],
							get = function() return RSConfigDB.IsShowingMissingDecors() end,
							set = function(_, value)
								RSConfigDB.SetShowingMissingDecors(value)
							end,
							width = "full",
							disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						open_explorer = {
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition,
							name = AL["LOOT_EXPLORER_OPEN"],
							desc = AL["LOOT_EXPLORER_OPEN"],
							type = "execute",
							func = function() 
								RSExplorerFrame:Show()
							end,
							width = "normal",
						},
						separator_reset = {
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition + 1,
							type = "header",
							name = AL["LOOT_RESET"],
						},
						reset = {
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition + 2,
							name = AL["LOOT_RESET"],
							desc = AL["LOOT_RESET_DESC"],
							type = "execute",
							func = function() 
								RSConfigDB.ResetLootFilters() 
								RSLogger:PrintMessage(AL["LOOT_RESET_DONE"])
							end,
							width = "normal",
						},
						category_filters = {
							type = "group",
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition + 3,
							name = AL["LOOT_CATEGORY_FILTERS"],
							handler = RareScanner,
							desc = AL["LOOT_CATEGORY_FILTERS_DESC"],
							args = {
								categories = {
									order = 0,
									type = "select",
									name = AL["LOOT_MAIN_CATEGORY"],
									desc = AL["LOOT_MAIN_CATEGORY"],
									values = GetMainCategories(),
									get = function(_, key)
										-- initialize
										if (not private.loot_main_category_ID) then
											private.loot_main_category_ID = 0
											LoadSubcategoryCombo(private.loot_main_category_ID)
										end
		
										return private.loot_main_category_ID
									end,
									set = function(_, key, value)
										private.loot_main_category_ID = key
		
										-- load subcategory combo
										LoadSubcategoryCombo(key)
									end,
									width = "normal",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								separator = {
									order = 1,
									type = "header",
									name = AL["LOOT_SUBCATEGORY_FILTERS"],
								},
								lootFiltersToogleAll = {
									order = 2,
									name = AL["TOGGLE_FILTERS"],
									desc = AL["TOGGLE_FILTERS_DESC"],
									type = "execute",
									func = function()
										if (private.loot_toggle_all) then
											private.loot_toggle_all = false
										else
											private.loot_toggle_all = true
										end
		
										for k, _ in pairs(options.args.filters.args.category_filters.args.lootFilters.values) do
											RSConfigDB.SetLootFilterByCategory(private.loot_main_category_ID, k, private.loot_toggle_all)
										end
									end,
									width = "full",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								lootFilters = {
									order = 3,
									type = "multiselect",
									name = AL["LOOT_FILTER_SUBCATEGORY_LIST"],
									desc = AL["LOOT_FILTER_SUBCATEGORY_DESC"],
									values = {},
									get = function(_, key) return RSConfigDB.GetLootFilterByCategory(private.loot_main_category_ID, key) end,
									set = function(_, key, value)
										RSLogger:PrintDebugMessage(string.format("Cambiando el valor de ClassID [%s], SubClassID [%s]", private.loot_main_category_ID, key))
										RSConfigDB.SetLootFilterByCategory(private.loot_main_category_ID, key, value);
									end,
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								}
							},
							disabled = function() return (RSConfigDB.IsFilteringByExplorerResults()) end,
						},
						individual = {
							type = "group",
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition + 4,
							name = AL["LOOT_INDIVIDUAL_FILTERS"],
							handler = RareScanner,
							desc = AL["LOOT_INDIVIDUAL_FILTERS_DESC"],
							args = {
								search = {
									order = 0,
									type = "input",
									name = AL["FILTERS_SEARCH"],
									desc = AL["LOOT_SEARCH_ITEMS_DESC"],
									get = function(_, value) return private.loot_individual_filter_input end,
									set = function(_, value)
										private.loot_individual_filter_input = value
									end,
									width = "full",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								filteredItems = {
									order = 1,
									type = "multiselect",
									name = AL["LOOT_FILTER_ITEM_LIST"],
									desc = nil,
									values = function() return GetFilteredItems() end,
									get = function(_, itemID) return RSConfigDB.GetItemFiltered(itemID) end,
									set = function(_, itemID, value)
										RSConfigDB.SetItemFiltered(itemID, value)
									end,
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								}
							}
						},
						other_filters = {
							type = "group",
							order = RSUtils.GetTableLength(RSCollectionsDB.GetItemGroups()) + customItemsPosition + 5,
							name = AL["LOOT_OTHER_FILTERS"],
							handler = RareScanner,
							desc = AL["LOOT_OTHER_FILTERS_DESC"],
							args = {
								lootMinQuality = {
									order = 0,
									type = "select",
									name = AL["LOOT_MIN_QUALITY"],
									desc = AL["LOOT_MIN_QUALITY_DESC"],
									values = GetColoredItemQualities(),
									get = function() return RSConfigDB.GetLootFilterMinQuality() end,
									set = function(_, value)
										RSConfigDB.SetLootFilterMinQuality(value)
									end,
									width = "double",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								filterNotEquipableItems = {
									order = 1,
									type = "toggle",
									name = AL["LOOT_FILTER_NOT_EQUIPABLE"],
									desc = AL["LOOT_FILTER_NOT_EQUIPABLE_ITEMS_DESC"],
									get = function() return RSConfigDB.IsFilteringLootByNotEquipableItems() end,
									set = function(_, value)
										RSConfigDB.SetFilteringLootByNotEquipableItems(value)
									end,
									width = "full",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								filterNotUsable = {
									order = 2,
									type = "toggle",
									name = AL["LOOT_FILTER_NOT_USABLE"],
									desc = AL["LOOT_FILTER_NOT_USABLE_DESC"],
									get = function() return RSConfigDB.IsFilteringLootByNotUsable() end,
									set = function(_, value)
										RSConfigDB.SetFilteringLootByNotUsable(value)
									end,
									width = "full",
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								filterMinChance = {
									order = 5,
									type = "input",
									name = AL["LOOT_FILTER_CHANCE_MIN"],
									desc = AL["LOOT_FILTER_CHANCE_DESC"],
									pattern = CHANCE_PATTERN,
									usage = AL["LOOT_FILTER_CHANCE_RANGE_ERROR"],
									validate = function(_, value) return ValidateChance(value, RSConfigDB.GetLootFilterMaxChance(), true) end,
									get = function() return GetChanceText(RSConfigDB.GetLootFilterMinChance()) end,
									set = function(_, value)
										RSConfigDB.SetLootFilterMinChance(ParseChance(value))
									end,
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
								filterMaxChance = {
									order = 6,
									type = "input",
									name = AL["LOOT_FILTER_CHANCE_MAX"],
									desc = AL["LOOT_FILTER_CHANCE_DESC"],
									pattern = CHANCE_PATTERN,
									usage = AL["LOOT_FILTER_CHANCE_RANGE_ERROR"],
									validate = function(_, value) return ValidateChance(value, RSConfigDB.GetLootFilterMinChance(), false) end,
									get = function() return GetChanceText(RSConfigDB.GetLootFilterMaxChance()) end,
									set = function(_, value)
										RSConfigDB.SetLootFilterMaxChance(ParseChance(value))
									end,
									disabled = function() return (not RSConfigDB.IsDisplayingLootBar() and not RSConfigDB.IsShowingLootOnWorldMap()) end,
								},
							},
						},
					},
				},
			},
		}
	end
		
	-- Load custom item filters
	for groupKey, groupName in pairs(RSCollectionsDB.GetItemGroups()) do
		options.args.filters.args[string.format(customLine, groupKey)] = {
			order = customItemsPosition,
			type = "toggle",
			name = string.format(AL["LOOT_EXPLORER_SHOW_MISSING_CUSTOM"], groupName),
			desc = string.format(AL["LOOT_EXPLORER_SHOW_MISSING_CUSTOM_DESC"], groupName),
			get = function() return RSConfigDB.IsShowingCustomItems(groupKey) end,
			set = function(_, value)
				RSConfigDB.SetShowingCustomItems(groupKey, value)
			end,
			width = "full",
			disabled = function() return (not RSConfigDB.IsFilteringByExplorerResults()) end,
		}
		customItemsPosition = customItemsPosition + 1
	end
	
	return options
end