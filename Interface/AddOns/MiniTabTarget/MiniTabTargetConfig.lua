local _, addon = ...
---@type MiniFramework
local mini = addon.Framework

local BRACKET_COLUMNS = 3

local function BuildPanel(panel)
	local header = mini:PanelHeader({
		Parent = panel,
		Description = "Tab targeting that makes sense.",
	})

	local divider = mini:Divider({
		Parent = panel,
		Text = "How it works",
	})
	divider:SetPoint("TOPLEFT", header.Anchor, "BOTTOMLEFT", 0, -mini.VerticalSpacing)
	divider:SetWidth(mini.TextMaxWidth)

	local desc = mini:TextBlock({
		Parent = panel,
		Lines = {
			"Automatically swaps your target and previous-target keys based on your current zone and PvP bracket.",
			" ",
			"In a bracket enabled below, your keys target the nearest enemy player.",
			"Everywhere else, and in a bracket turned off, your keys target the nearest enemy.",
			" ",
			"Your keys are auto-detected from your keybindings unless you have overridden them in the saved variables.",
		},
	})
	desc:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -mini.VerticalSpacing)

	local bracketsDivider = mini:Divider({
		Parent = panel,
		Text = "Where it applies",
	})
	bracketsDivider:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -mini.VerticalSpacing)
	bracketsDivider:SetWidth(mini.TextMaxWidth)

	local columnStep = mini:ColumnWidth(BRACKET_COLUMNS, 0, 0)

	local arena = mini:Checkbox({
		Parent = panel,
		LabelText = "Arena",
		Tooltip = "Rated arena and skirmish.",
		GetValue = function()
			return addon.Db.Arena
		end,
		SetValue = function(value)
			addon.Db.Arena = value
			addon.UpdateBindings()
		end,
	})
	arena:SetPoint("TOPLEFT", bracketsDivider, "BOTTOMLEFT", 0, -mini.VerticalSpacing)

	local soloShuffle = mini:Checkbox({
		Parent = panel,
		LabelText = "Solo Shuffle",
		Tooltip = "Rated solo shuffle.",
		GetValue = function()
			return addon.Db.SoloShuffle
		end,
		SetValue = function(value)
			addon.Db.SoloShuffle = value
			addon.UpdateBindings()
		end,
	})
	soloShuffle:SetPoint("LEFT", arena, "LEFT", columnStep, 0)

	local battleground = mini:Checkbox({
		Parent = panel,
		LabelText = "Battleground",
		Tooltip = "Rated/unrated/epic battlegrounds and Blitz.",
		GetValue = function()
			return addon.Db.Battleground
		end,
		SetValue = function(value)
			addon.Db.Battleground = value
			addon.UpdateBindings()
		end,
	})
	battleground:SetPoint("LEFT", soloShuffle, "LEFT", columnStep, 0)
end

local function Init()
	-- A styled button clashes with the stock Blizzard art around it in the settings screen.
	mini:SetCustomStyling(true, { Button = false })

	local panel = CreateFrame("Frame")
	panel.name = "MiniTabTarget"

	local category = mini:AddCategory(panel)
	mini:RegisterSlashCommand(category, panel, { "/mtt", "/minitt", "/minitabtarget" })

	BuildPanel(panel)
end

mini:WaitForAddonLoad(Init)
