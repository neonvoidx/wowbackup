local _, addon = ...
---@type MiniFramework
local mini = addon.Framework

local function BuildPanel(panel)
	local title = mini:TextLine({
		Parent = panel,
		Text = "MiniTabTarget",
		Font = "GameFontNormalHuge",
	})
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)

	local divider = mini:Divider({
		Parent = panel,
		Text = "How it works",
	})
	divider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -mini.VerticalSpacing)
	divider:SetWidth(mini.TextMaxWidth)

	local desc = mini:TextBlock({
		Parent = panel,
		Lines = {
			"Automatically swaps your target and previous-target keys based on your current zone.",
			" ",
			"In battlegrounds and arenas, your keys target the nearest enemy player.",
			"Everywhere else, your keys target the nearest enemy.",
			" ",
			"Your keys are auto-detected from your keybindings unless you have overridden them in the saved variables.",
		},
	})
	desc:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -mini.VerticalSpacing)
end

local function Init()
	local panel = CreateFrame("Frame")
	panel.name = "MiniTabTarget"

	local category = mini:AddCategory(panel)
	mini:RegisterSlashCommand(category, panel, { "/mtt", "/minitt", "/minitabtarget" })

	BuildPanel(panel)
end

mini:WaitForAddonLoad(Init)
