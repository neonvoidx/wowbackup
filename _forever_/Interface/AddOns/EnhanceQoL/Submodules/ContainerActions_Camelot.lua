local _, addon = ...
local ContainerActions = addon.ContainerActions
local L = addon.L
local COMPREHEND_SCROLL = 1296017

-- ItemSparse / SkillLine, build 1.60.1.69913: item ID -> required Comprehension (3012) rank.
-- Translated and quest scrolls are excluded.
local scrolls = {
	[211780] = 1, -- Scroll: KWYJIBO
	[211784] = 15, -- Scroll: WUBBA WUBBA
	[211785] = 1, -- Scroll: CWAL
	[211786] = 1, -- Scroll: CHAP BALK WELLES
	[211787] = 1, -- Scroll: LOWER PING WHOMEVER
	[211853] = 15, -- Scroll: VOCE WELL
	[211854] = 15, -- Scroll: OMIT KESA
	[211855] = 15, -- Scroll: STHENIC LUNATE
	[213543] = 50, -- Scroll: UPDOG
	[213544] = 50, -- Scroll: TOPAZ YORAK
	[213545] = 50, -- Scroll: PEATCHY ATTAX
	[213546] = 50, -- Scroll: SHOOBEEDOOP
	[213547] = 50, -- Scroll: THAW WORDS
	[281015] = 175, -- Scroll: DOST OREM
	[281016] = 175, -- Scroll: FORGOT HOOF THUD
	[281017] = 175, -- Scroll: KEEP CLEF FOCI
	[281018] = 175, -- Scroll: RARE SERVICHI RADAR
}

-- nil: not a spell-target item; false: recognized but unavailable; number: cast spell ID.
function ContainerActions:GetItemSpellAction(itemID, bag, slot)
	local requiredRank = scrolls[itemID]
	if not requiredRank then return nil end
	if not addon.db or addon.db.containerActionComprehendScrolls ~= true then return false end
	if select(2, UnitClass("player")) ~= "MAGE" then return false end
	local known = C_SpellBook.IsSpellKnown(COMPREHEND_SCROLL, Enum.SpellBookSpellBank.Player)
	if (issecretvalue and issecretvalue(known)) or known ~= true then return false end
	local skill = C_SkillInfo.GetSkillLineInfoByID(3012)
	if (issecretvalue and issecretvalue(skill)) or type(skill) ~= "table" then return false end
	local rank = skill.rank
	if (issecretvalue and issecretvalue(rank)) or type(rank) ~= "number" or rank < requiredRank then return false end
	if self:HasUnmetUsageRequirement(bag, slot) then return false end
	return COMPREHEND_SCROLL
end

function ContainerActions:RegisterExtraSettings(category, section)
	if select(2, UnitClass("player")) ~= "MAGE" then return end
	addon.functions.SettingsCreateCheckbox(category, {
		var = "containerActionComprehendScrolls",
		default = false,
		text = L["containerActionsComprehendScrolls"],
		desc = L["containerActionsComprehendScrollsDesc"],
		newTagID = "containerActionComprehendScrolls",
		func = function(value)
			addon.db.containerActionComprehendScrolls = value == true
			if addon.functions.checkForContainer then addon.functions.checkForContainer() end
		end,
		parent = true,
		parentCheck = function() return addon.db and addon.db.automaticallyOpenContainer == true end,
		element = addon.SettingsLayout.elements.automaticallyOpenContainer.element,
		parentSection = section,
	})
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:SetScript("OnEvent", function()
	if addon.db and addon.db.automaticallyOpenContainer and addon.functions.checkForContainer then addon.functions.checkForContainer() end
end)
