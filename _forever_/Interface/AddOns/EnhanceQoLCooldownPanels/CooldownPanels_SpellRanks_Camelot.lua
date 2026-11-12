local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end

local CP = addon.Aura.CooldownPanels
CP.SpellRankFamilies = addon.SpellRankFamilies
local M = { baseByRank = {}, player = {}, pet = {} }

-- The generated families are ordered by rank, not by numeric spell ID.
for baseID, family in pairs(CP.SpellRankFamilies or {}) do
	for _, rankID in ipairs(family) do M.baseByRank[rankID] = baseID end
end

function M.IsSpellID(spellID)
	if issecretvalue and issecretvalue(spellID) then return false end
	return type(spellID) == "number" and spellID > 0 and spellID < math.huge and spellID % 1 == 0
end

function CP:GetCanonicalSpellRankID(spellID)
	if not M.IsSpellID(spellID) then return nil end
	return M.baseByRank[spellID] or spellID
end

function CP:GetSpellRankFamily(spellID)
	local baseID = self:GetCanonicalSpellRankID(spellID)
	return baseID and self.SpellRankFamilies and self.SpellRankFamilies[baseID] or nil
end

function CP:InvalidateLearnedSpellRanks() M.player, M.pet = {}, {} end

function CP:ResolveLearnedSpellRank(spellID, pet)
	local baseID = self:GetCanonicalSpellRankID(spellID)
	if not baseID then return nil end
	local cache = pet and M.pet or M.player
	local cached = cache[baseID]
	if cached ~= nil then return cached or nil end
	local book = C_SpellBook
	local banks = Enum and Enum.SpellBookSpellBank
	if not (book and book.IsSpellKnown and banks) then return nil end
	local bank = pet and banks.Pet or banks.Player
	local family = self:GetSpellRankFamily(baseID)
	if family then
		for i = #family, 1, -1 do
			local rankID = family[i]
			if book.IsSpellKnown(rankID, bank) then
				cache[baseID] = rankID
				return rankID
			end
		end
	elseif book.IsSpellKnown(baseID, bank) then
		cache[baseID] = baseID
		return baseID
	end
	-- An existing DB2 row alone never makes a rank learned or usable.
	cache[baseID] = false
	return nil
end

M.events = CreateFrame("Frame")
M.events:RegisterEvent("SPELLS_CHANGED")
M.events:RegisterEvent("PLAYER_LOGIN")
M.events:RegisterEvent("UNIT_PET")
M.events:SetScript("OnEvent", function(_, event, unit)
	if event ~= "UNIT_PET" or unit == "player" then CP:InvalidateLearnedSpellRanks() end
end)
