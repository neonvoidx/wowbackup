local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local UnitAffectingCombat = UnitAffectingCombat
local InCombatLockdown = InCombatLockdown
local GetItemCooldownFn = C_Item.GetItemCooldown
local GetTime = GetTime
local GetMacroInfo = GetMacroInfo
local EditMacro = EditMacro

local healthMacroName = "EnhanceQoLHealthMacro"

function addon.Health.functions.InitHealthMacro()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue
	-- DB defaults
	init("healthMacroEnabled", false)
	init("healthUseBoth", false)
	init("healthPreferStoneFirst", true)
	init("healthReset", { combat = true })
	init("healthResetSeconds", 60)
	init("healthResetByClass", {})
	addon.Health.Reset.Normalize(addon.db)
	init("healthPotionPriority", {})
	init("healthReorderByCooldown", true)
	init("healthUseFood", true)
	init("healthStopCasting", false)
	-- Custom spells support
	init("healthUseCustomSpells", false)
	init("healthCustomSpells", {})
	-- Multiselect preference for ordering (spells, stones)
	-- Fallback to legacy healthPreferStoneFirst when not initialized yet
	init("healthPreferFirstPrefs", nil)
	-- New priority-based ordering (overrides legacy prefs if set)
	init("healthPriorityOrder", nil)
end

local function IsSecretValue(value)
	if issecretvalue then
		local ok, result = pcall(issecretvalue, value)
		if ok and result then return true end
	end
	if issecrettable and type(value) == "table" then
		local ok, result = pcall(issecrettable, value)
		if ok and result then return true end
	end
	return false
end

local function IsCombatLocked() return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) end

local function GetSpellCooldownSafe(spellId)
	local cd = C_Spell.GetSpellCooldown(spellId)
	if IsSecretValue(cd) then return nil, nil, true end
	if not cd then return 0, 0, false end
	local start = cd.startTime
	local duration = cd.duration
	if IsSecretValue(start) or IsSecretValue(duration) then return nil, nil, true end
	return start or 0, duration or 0, false
end

local function GetItemCooldownSafe(itemID)
	local start, duration, enabled = GetItemCooldownFn(itemID)
	if IsSecretValue(start) or IsSecretValue(duration) or IsSecretValue(enabled) then return nil, nil, true end
	if enabled == 0 then return nil, nil, true end
	return start or 0, duration or 0, false
end

local function createMacroIfMissing()
	if not addon.db.healthMacroEnabled then return false end
	if GetMacroInfo(healthMacroName) ~= nil then return true end
	-- Avoid protected calls during combat lockdown
	if InCombatLockdown and InCombatLockdown() then return false end

	local body = "#showtooltip"

	return addon.functions.EnsureGlobalMacro(
		healthMacroName,
		"INV_Misc_QuestionMark",
		body,
		"healthMacroLimitReached",
		L["healthMacroLimitReached"] or "Health Macro: Macro limit reached. Please free a slot."
	)
end

local lastMacroKey
local wipe = table and table.wipe or nil
local function clearTable(tbl)
	if wipe then
		wipe(tbl)
	else
		for k in pairs(tbl) do
			tbl[k] = nil
		end
	end
end

local spellKnownCache = {}
local spellCooldownCache = {}
local itemCooldownCache = {}
local spellNameCache = {}
local SyncEventRegistration

local function resetCooldownCaches()
	clearTable(spellKnownCache)
	clearTable(spellCooldownCache)
	clearTable(itemCooldownCache)
end

local function numericId(v)
	if not v then return nil end
	if v.id then return tonumber(v.id) end
	if not v.getId then return nil end
	local s = v.getId()
	if not s then return nil end
	return tonumber(string.match(s, "%d+"))
end

local function cooldownRemaining(entry)
	if not entry then return math.huge end
	if entry.isSpell then
		local spellId = entry.id
		if not spellId then return math.huge end
		local isKnown = spellKnownCache[spellId]
		if isKnown == nil then
			isKnown = C_SpellBook.IsSpellInSpellBook(spellId) and true or false
			spellKnownCache[spellId] = isKnown
		end
		if not isKnown then return math.huge end
		local cached = spellCooldownCache[spellId]
		local start, duration
		if cached then
			start, duration = cached.start, cached.duration
		else
			local safeStart, safeDuration, blocked = GetSpellCooldownSafe(spellId)
			if blocked then return math.huge end
			start = safeStart
			duration = safeDuration
			spellCooldownCache[spellId] = { start = start, duration = duration }
		end
		if start == 0 or duration == 0 then return 0 end
		local remain = (start + duration) - GetTime()
		if remain < 0 then return 0 end
		return remain
	end
	local itemID = numericId(entry)
	if not itemID then return 0 end
	local cached = itemCooldownCache[itemID]
	local start, duration
	if cached then
		start, duration = cached.start, cached.duration
	else
		local blocked
		start, duration, blocked = GetItemCooldownSafe(itemID)
		if blocked then return math.huge end
		itemCooldownCache[itemID] = { start = start or 0, duration = duration or 0 }
	end
	if not start or start == 0 or not duration or duration == 0 then return 0 end
	local remain = (start + duration) - GetTime()
	if remain < 0 then return 0 end
	return remain
end

local function createNeedsTable() return { talent = false, allowed = false, macro = false, macroSkipAllowed = false } end

local bucketWindow = 0.20
local bucketPending = false
local needs = createNeedsTable()

local function BucketSchedule(reason)
	if not addon.db or not addon.db.healthMacroEnabled then return end
	if reason == "macroOnly" then
		needs.macro = true
		needs.macroSkipAllowed = true
	elseif reason then
		if needs[reason] ~= nil then
			needs[reason] = true
		else
			needs.macro = true
		end
	end
	if bucketPending then return end
	bucketPending = true
	C_Timer.After(bucketWindow, function()
		bucketPending = false
		local currentNeeds = needs
		needs = createNeedsTable()

		if not addon.db or not addon.db.healthMacroEnabled or IsCombatLocked() then return end
		local runTalent = currentNeeds.talent
		local runAllowed = currentNeeds.allowed
		local runMacro = currentNeeds.macro
		local skipAllowed = runAllowed or currentNeeds.macroSkipAllowed

		if runTalent then clearTable(spellNameCache) end
		if runAllowed and addon.Health and addon.Health.functions and addon.Health.functions.updateAllowedHealth then addon.Health.functions.updateAllowedHealth() end
		if runMacro and addon.Health and addon.Health.functions and addon.Health.functions.updateHealthMacro then addon.Health.functions.updateHealthMacro(false, skipAllowed) end
	end)
end

local function getKnownCustomSpells()
	local list = {}
	if not addon.db.healthUseCustomSpells then return list end
	local ids = addon.db.healthCustomSpells or {}
	for _, sid in ipairs(ids) do
		local inBook = spellKnownCache[sid]
		if inBook == nil then
			inBook = C_SpellBook.IsSpellInSpellBook(sid) and true or false
			spellKnownCache[sid] = inBook
		end
		if inBook then
			local spellName = spellNameCache[sid]
			if spellName == nil then
				local info = C_Spell.GetSpellInfo(sid)
				spellName = info and info.name or false
				spellNameCache[sid] = spellName
			end
			if spellName and spellName ~= false then
				local obj = addon.functions.newItem(sid, spellName, true)
				obj.type = "spell"
				obj.heal = 0 -- unknown; ordering handled by preferences
				table.insert(list, obj)
			end
		else
			if spellNameCache[sid] ~= nil then spellNameCache[sid] = nil end
		end
	end
	return list
end

local function normalizeOrder(order)
	local seen, out = {}, {}
	for i = 1, 4 do
		local c = order and order[i] or nil
		if (c == "stone" or c == "potion" or c == "spell") and not seen[c] then
			table.insert(out, c)
			seen[c] = true
		end
	end
	for i = #out + 1, 4 do
		out[i] = "none"
	end
	return out
end

local function defaultPriorityOrder() return { "stone", "potion", "none", "none" } end

local function ensurePriorityOrder()
	local order = addon.db.healthPriorityOrder
	if not order or #order == 0 then order = defaultPriorityOrder() end
	addon.db.healthPriorityOrder = normalizeOrder(order)
end

local function isBetterMacroCandidate(candidate, current, candidateRemain, currentRemain, candidateRank, currentRank)
	if not current then return true end
	if candidateRemain ~= currentRemain then return candidateRemain < currentRemain end
	candidateRank, currentRank = candidateRank or math.huge, currentRank or math.huge
	if candidateRank ~= currentRank then return candidateRank < currentRank end
	local candidateHeal = candidate and candidate.heal or 0
	local currentHeal = current and current.heal or 0
	return candidateHeal > currentHeal
end

local function collectBestMacroCandidates(spells)
	local potionRanks = addon.Health.PotionPriority.GetRanks()
	local bestByCategory = {}
	local bestRemainByCategory = {}

	local function assignBest(category, candidate)
		if not category or not candidate then return end
		local candidateRemain = cooldownRemaining(candidate)
		if candidateRemain == math.huge then return end
		local current = bestByCategory[category]
		local currentRemain = bestRemainByCategory[category]
		if isBetterMacroCandidate(
			candidate,
			current,
			candidateRemain,
			currentRemain,
			candidate.type == "potion" and potionRanks[candidate.id],
			current and current.type == "potion" and potionRanks[current.id]
		) then
			bestByCategory[category] = candidate
			bestRemainByCategory[category] = candidateRemain
		end
	end

	if addon.db.healthUseCustomSpells and spells and #spells > 0 then
		for i = 1, #spells do
			assignBest("spell", spells[i])
		end
	end

	local list = addon.Health.filteredHealth
	if list and #list > 0 then
		for i = 1, #list do
			local item = list[i]
			if item.getCount() > 0 then
				if item.type == "stone" then
					assignBest("stone", item)
				elseif item.type == "potion" then
					assignBest("potion", item)
				end
			end
		end
	end

	return bestByCategory
end

addon.Health.cooldownWatch = addon.Health.cooldownWatch or {}
local cooldownWatch = addon.Health.cooldownWatch
cooldownWatch.entries = cooldownWatch.entries or {}
cooldownWatch.state = cooldownWatch.state or {}
cooldownWatch.nextPollAt = cooldownWatch.nextPollAt or 0

local function clearCooldownTimers()
	if cooldownWatch.debounce then
		cooldownWatch.debounce:Cancel()
		cooldownWatch.debounce = nil
	end
	if cooldownWatch.timer then
		cooldownWatch.timer:Cancel()
		cooldownWatch.timer = nil
	end
end

local function resetCooldownWatch()
	clearCooldownTimers()
	cooldownWatch.nextPollAt = 0
	cooldownWatch.running = false
	cooldownWatch.rebuilding = false
	cooldownWatch.secretBlocked = nil
	wipe(cooldownWatch.entries)
	wipe(cooldownWatch.state)
end

local function cooldownCheck(force, suppressRebuild)
	if IsCombatLocked() then return end
	if cooldownWatch.secretBlocked and not IsCombatLocked() then cooldownWatch.secretBlocked = nil end
	if cooldownWatch.running then return end
	if not addon.db or addon.db.healthReorderByCooldown ~= true then
		resetCooldownWatch()
		return
	end
	if not addon.db.healthMacroEnabled then
		resetCooldownWatch()
		return
	end
	if #cooldownWatch.entries == 0 then
		resetCooldownWatch()
		return
	end

	local now = GetTime()
	if not force then
		local nextPoll = cooldownWatch.nextPollAt or 0
		if nextPoll > 0 and now < nextPoll - 0.05 then return end
	end

	cooldownWatch.running = true
	local changed = false
	local soonest = math.huge

	for i = 1, #cooldownWatch.entries do
		local entry = cooldownWatch.entries[i]
		local ready = true
		local endsAt

		if entry.kind == "item" then
			local start, duration, blocked = GetItemCooldownSafe(entry.id)
			if blocked then
				cooldownWatch.running = false
				return
			end
			if duration and duration > 0 and start and start > 0 and start + duration > now then
				ready = false
				endsAt = start + duration
			end
		elseif entry.kind == "spell" then
			local start, duration, blocked = GetSpellCooldownSafe(entry.id)
			if blocked then
				if IsCombatLocked() then
					cooldownWatch.secretBlocked = true
					cooldownWatch.running = false
					return
				end
				start, duration = 0, 0
			end
			if start ~= 0 and duration ~= 0 and start + duration > now then
				ready = false
				endsAt = start + duration
			end
		end

		local key = entry.key
		if cooldownWatch.state[key] ~= ready then
			cooldownWatch.state[key] = ready
			changed = true
		end

		if not ready and endsAt and endsAt > now and endsAt < soonest then soonest = endsAt end
	end

	if soonest < math.huge then
		cooldownWatch.nextPollAt = soonest
		if cooldownWatch.timer then cooldownWatch.timer:Cancel() end
		local delay = math.max(0.05, soonest - now + 0.05)
		cooldownWatch.timer = C_Timer.NewTimer(delay, function()
			cooldownWatch.timer = nil
			cooldownCheck(true, false)
		end)
	else
		cooldownWatch.nextPollAt = 0
		if cooldownWatch.timer then
			cooldownWatch.timer:Cancel()
			cooldownWatch.timer = nil
		end
	end

	cooldownWatch.running = false

	if changed and not suppressRebuild then
		if cooldownWatch.rebuilding then return end
		cooldownWatch.rebuilding = true
		addon.Health.functions.updateHealthMacro(false, true)
		cooldownWatch.rebuilding = false
	end
end

local function updateCooldownWatch(entries)
	resetCooldownWatch()
	if not addon.db or addon.db.healthReorderByCooldown ~= true then return end
	if not addon.db.healthMacroEnabled then return end
	if not entries or #entries == 0 then return end

	for i = 1, #entries do
		local entry = entries[i]
		local kind = entry.isSpell and "spell" or "item"
		local key = kind .. ":" .. entry.id
		cooldownWatch.entries[i] = cooldownWatch.entries[i] or {}
		cooldownWatch.entries[i].kind = kind
		cooldownWatch.entries[i].id = entry.id
		cooldownWatch.entries[i].key = key
	end
	for i = #entries + 1, #cooldownWatch.entries do
		cooldownWatch.entries[i] = nil
	end
	wipe(cooldownWatch.state)
	cooldownCheck(true, true)
end

local function handleCooldownEvent()
	if IsCombatLocked() then return end
	if not addon.db or addon.db.healthReorderByCooldown ~= true then return end
	if not addon.db.healthMacroEnabled then return end
	if #cooldownWatch.entries == 0 then return end

	if cooldownWatch.debounce then return end
	cooldownWatch.debounce = C_Timer.NewTimer(0.25, function()
		cooldownWatch.debounce = nil
		cooldownCheck(true, false)
	end)
end

local function buildResetToken() return addon.Health.Reset.BuildToken(addon.db) end

local function getAvailableFood()
	if not addon.db.healthUseFood then return nil end
	local food = addon.ForeverConsumables.GetBest("food", "health", addon.db.preferMageFood)
	return food and food.id
end

local function buildMacro()
	resetCooldownCaches()
	local spells = getKnownCustomSpells()
	local bestByCategory = collectBestMacroCandidates(spells)

	-- Priority-based sequence (always)
	local seqCandidates = {}
	local macroEntries = {}

	local order = addon.db.healthPriorityOrder
	if not order or #order == 0 then
		order = normalizeOrder(defaultPriorityOrder())
	else
		order = normalizeOrder(order)
	end

	-- Build according to priority order (ignore legacy useBoth/other)
	for i = 1, 4 do
		local cat = order[i]
		if cat and cat ~= "none" then
			local cand = bestByCategory[cat]
			if cat == "spell" and not addon.db.healthUseCustomSpells then
				cand = nil
			end
			if cand then table.insert(seqCandidates, cand) end
		end
	end

	-- Deduplicate by actual macro token (getId)
	local seen, seqList = {}, {}
	local function toUse(v) return v and v.getId() or nil end
	for _, v in ipairs(seqCandidates) do
		local t = toUse(v)
		if t and not seen[t] then
			table.insert(seqList, t)
			seen[t] = true
			table.insert(macroEntries, v)
		end
	end

	-- Keep sequence reasonably short (max 4)
	while #seqList > 4 do
		table.remove(seqList)
		table.remove(macroEntries)
	end

	local resetType = buildResetToken()
	local resetClause = resetType ~= "" and (" reset=" .. resetType) or ""

	local macroBody
	local key

	-- Ordinary food and combined food/drink can both restore health outside combat.
	local foodLine, foodKey = "", ""
	local foodID = getAvailableFood()
	if foodID then
		foodLine = string.format("/use [nocombat] item:%d", foodID)
		foodKey = "|food:" .. foodID
	end
	if #seqList >= 1 then
		local parts = { "#showtooltip" }
		if addon.db.healthStopCasting then table.insert(parts, "/stopcasting") end
		if foodLine ~= "" then table.insert(parts, foodLine) end
		local seqStr = table.concat(seqList, ", ")
		if foodLine ~= "" then
			table.insert(parts, string.format("/castsequence [combat]%s %s", resetClause, seqStr))
		else
			table.insert(parts, string.format("/castsequence%s %s", resetClause, seqStr))
		end
		macroBody = table.concat(parts, "\n")
		key = string.format("seq:%s|%s%s", table.concat(seqList, "|"), resetType, foodKey)
	else
		local parts = { "#showtooltip" }
		if addon.db.healthStopCasting then table.insert(parts, "/stopcasting") end
		if foodLine ~= "" then table.insert(parts, foodLine) end
		macroBody = table.concat(parts, "\n")
		key = "empty" .. foodKey
	end

	if addon.db.healthStopCasting then key = key .. "|stopcasting" end

	local _, _, currentBody = GetMacroInfo(healthMacroName)
	if key ~= lastMacroKey or currentBody ~= macroBody then
		-- Final safety check to avoid protected EditMacro during combat lockdown
		if InCombatLockdown and InCombatLockdown() then return end
		if not GetMacroInfo(healthMacroName) and not createMacroIfMissing() then return end
		if GetMacroInfo(healthMacroName) then EditMacro(healthMacroName, healthMacroName, nil, macroBody) end
		lastMacroKey = key
	end

	if addon.db.healthReorderByCooldown then
		local watched = {}
		local enabledCategories = {}
		for _, category in ipairs(order) do enabledCategories[category] = true end
		for _, item in ipairs(addon.Health.filteredHealth or {}) do
			if enabledCategories[item.type] and item.getCount() > 0 and cooldownRemaining(item) < math.huge then watched[#watched + 1] = item end
		end
		if enabledCategories.spell then
			for _, spell in ipairs(spells) do watched[#watched + 1] = spell end
		end
		updateCooldownWatch(watched)
	else
		resetCooldownWatch()
	end
end

function addon.Health.functions.updateHealthMacro(ignoreCombat, skipAllowedRefresh)
	if not addon.db.healthMacroEnabled then
		resetCooldownWatch()
		SyncEventRegistration()
		return
	end
	if IsCombatLocked() then return end
	if not createMacroIfMissing() then return end
	if not skipAllowedRefresh then addon.Health.functions.updateAllowedHealth() end
	buildMacro()
end

-- Events + throttle similar to drinks
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
-- Optional spell/cooldown events are registered dynamically

SyncEventRegistration = function()
	if not addon.db then return end
	if not addon.db.healthMacroEnabled then
		frame:UnregisterEvent("SPELLS_CHANGED")
		frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
		frame:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		frame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		frame:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
		resetCooldownWatch()
		return
	end

	frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	if addon.db.healthUseCustomSpells then
		frame:RegisterEvent("SPELLS_CHANGED")
		frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	else
		frame:UnregisterEvent("SPELLS_CHANGED")
		frame:UnregisterEvent("PLAYER_TALENT_UPDATE")
	end

	if addon.db.healthReorderByCooldown then
		frame:RegisterEvent("BAG_UPDATE_COOLDOWN")
		if addon.db.healthUseCustomSpells then frame:RegisterEvent("SPELL_UPDATE_COOLDOWN") else frame:UnregisterEvent("SPELL_UPDATE_COOLDOWN") end
	else
		frame:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		frame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		resetCooldownWatch()
	end
end

addon.Health.functions.syncEventRegistration = SyncEventRegistration
addon.Health.functions.ensurePriorityOrder = ensurePriorityOrder

frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "PLAYER_LOGIN" then
		-- Migrate old settings to new priority model
		local function migrateOldPriority()
			if addon.db.healthPriorityOrder ~= nil then return end
			local hasSpells = addon.db.healthUseCustomSpells == true
			local prefer = addon.db.healthPreferFirstPrefs
			local preferSpells = false
			if prefer == nil then
				-- legacy: healthPreferStoneFirst not used anymore
			else
				preferSpells = prefer.spells == true
			end
			local tmp = {}
			local function addOnce(cat)
				if not cat or cat == "none" then return end
				for _, v in ipairs(tmp) do
					if v == cat then return end
				end
				table.insert(tmp, cat)
			end
			-- Order from legacy prefs: preferSpells puts spell first
			if preferSpells and hasSpells then addOnce("spell") end
			-- default: stones, then potions
			addOnce("stone")
			addOnce("potion")
			-- include spells somewhere if enabled but not preferred first
			if hasSpells and not preferSpells then addOnce("spell") end
			-- clamp to 4 slots and pad with none
			while #tmp > 4 do
				table.remove(tmp)
			end
			for i = #tmp + 1, 4 do
				tmp[i] = "none"
			end
			addon.db.healthPriorityOrder = tmp
		end
		migrateOldPriority()
		ensurePriorityOrder()
		SyncEventRegistration()
		if not addon.db.healthMacroEnabled then return end
		if addon.db.healthUseCustomSpells then BucketSchedule("talent") end
		BucketSchedule("allowed")
		BucketSchedule("macro")
		return
	elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		if not addon.db.healthMacroEnabled then return end
		cooldownWatch.secretBlocked = nil
		if addon.db.healthUseCustomSpells then BucketSchedule("talent") end
		BucketSchedule("allowed")
		BucketSchedule("macro")
	elseif event == "BAG_UPDATE_DELAYED" then
		if not addon.db.healthMacroEnabled then return end
		BucketSchedule("allowed")
		BucketSchedule("macro")
	elseif event == "ITEM_DATA_LOAD_RESULT" then
		if not addon.db.healthMacroEnabled then return end
		local requestedItems = addon.ForeverConsumables and addon.ForeverConsumables.requestedItems
		if not requestedItems or not requestedItems[arg1] then return end
		BucketSchedule("allowed")
		BucketSchedule("macro")
	elseif event == "PLAYER_LEVEL_UP" then
		if not addon.db.healthMacroEnabled then return end
		BucketSchedule("allowed")
		if not UnitAffectingCombat("player") then BucketSchedule("macro") end
	elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
		if not addon.db.healthMacroEnabled then return end
		if addon.db.healthUseCustomSpells then
			BucketSchedule("talent")
			BucketSchedule("allowed")
			BucketSchedule("macro")
		end
	elseif event == "UNIT_MAXHEALTH" then
		if not addon.db.healthMacroEnabled then return end
		if arg1 == "player" and not UnitAffectingCombat("player") then
			BucketSchedule("allowed")
			BucketSchedule("macro")
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if not addon.db.healthMacroEnabled then return end
		BucketSchedule("allowed")
		BucketSchedule("macro")
	elseif event == "BAG_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
		if not addon.db.healthMacroEnabled then return end
		if addon.db.healthReorderByCooldown then handleCooldownEvent() end
	end
end)
