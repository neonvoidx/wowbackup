local _, addon = ...
local P = addon.RangeDisplay

local function public(v)
	return not (issecretvalue and issecretvalue(v))
end

-- Shared by the distance display and the Forever crosshair; independent of display state.
function P.GetLearnedSpellRanks()
	if P.learnedSpellRanks then return P.learnedSpellRanks end
	local learned = {}
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		if info then
			for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local entry = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
				if entry and not entry.isPassive and not entry.isOffSpec and entry.spellID and public(entry.name) and entry.name then
					learned[entry.name] = entry.spellID
				end
			end
		end
	end
	P.learnedSpellRanks = learned
	return learned
end

-- One listener invalidates before notifying either consumer, regardless of frame event order.
function P.InvalidateLearnedSpells()
	P.learnedSpellRanks = nil
end

function P.SetSpellCacheConsumer(id, callback)
	P.spellCacheConsumers = P.spellCacheConsumers or {}
	P.spellCacheConsumers[id] = callback
	if not next(P.spellCacheConsumers) then
		if P.spellCacheEvents then
			P.spellCacheEvents:UnregisterAllEvents()
			P.spellCacheEvents:SetScript("OnEvent", nil)
		end
		P.spellCacheListening = false
		P.InvalidateLearnedSpells()
	elseif not P.spellCacheListening then
		P.InvalidateLearnedSpells()
		P.spellCacheListening = true
		P.spellCacheEvents = P.spellCacheEvents or CreateFrame("Frame")
		P.spellCacheEvents:SetScript("OnEvent", function()
			P.InvalidateLearnedSpells()
			for _, refresh in pairs(P.spellCacheConsumers) do refresh() end
		end)
		for _, event in ipairs({ "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE", "UPDATE_SHAPESHIFT_FORM", "PLAYER_ENTERING_WORLD" }) do
			P.spellCacheEvents:RegisterEvent(event)
		end
	end
end

function P.ResolveLearnedSpell(baseID)
	local info = baseID and C_Spell.GetSpellInfo(baseID)
	if not info or not public(info.name) or not info.name then return nil end
	return P.GetLearnedSpellRanks()[info.name]
end

function P.RebuildSpells()
	P.spells = {}
	local flavor = P.flavors[P.flavor]
	local profile = flavor and flavor.classes and flavor.classes[P.playerClass]
	if not profile then return end
	local learned = P.GetLearnedSpellRanks()
	-- Profile order stays deterministic. Never infer melee from a generic 0/0 range.
	local seen = {}
	for _, kind in ipairs({ "melee", "ranged" }) do
		for _, baseID in ipairs(profile[kind] or {}) do
			local base = C_Spell.GetSpellInfo(baseID)
			local id = base and learned[base.name]
			local info = id and C_Spell.GetSpellInfo(id)
			if info and not seen[id] and public(info.minRange) and public(info.maxRange) then
				local minimum, maximum = info.minRange, info.maxRange
				if kind == "melee" or (type(minimum) == "number" and type(maximum) == "number" and maximum > minimum and maximum > 0) then
					P.spells[#P.spells + 1] = { id = id, name = info.name, kind = kind, minRange = minimum, maxRange = maximum, result = "unused" }
					seen[id] = true
				end
			end
		end
	end
end

function P.RefineWithSpells(lower, upper)
	local melee = false
	for _, spell in ipairs(P.spells or {}) do
		spell.result = "unused"
		-- Melee checks provide a label only, never a numeric lower bound.
		local relevant = spell.kind == "melee" or not upper or spell.minRange > lower or spell.maxRange < upper
		if relevant then
			local result = C_Spell.IsSpellInRange(spell.id, "target")
			spell.result = not public(result) and "SECRET" or (result == nil and "nil") or result
			if public(result) and type(result) == "boolean" then
				if spell.kind == "melee" then
					if result then melee = true end
				elseif result then
					lower = math.max(lower, spell.minRange)
					upper = upper and math.min(upper, spell.maxRange) or spell.maxRange
				elseif spell.minRange == 0 then
					lower = math.max(lower, spell.maxRange)
				elseif upper and upper < spell.maxRange then
					-- Only the near side is possible inside a verified upper bracket.
					upper = math.min(upper, spell.minRange)
				elseif lower >= spell.minRange then
					lower = math.max(lower, spell.maxRange)
				end
			end
		end
	end
	return lower, upper, melee
end
