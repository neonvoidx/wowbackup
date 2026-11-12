local _, addon = ...
local F = {}
addon.Mouse.foreverCrosshairRange = F
F.classes = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST", [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }

local function public(value) return not (issecretvalue and issecretvalue(value)) end

function F.GetOptions()
	local options = {}
	for id, token in pairs(F.classes) do
		local name = LOCALIZED_CLASS_NAMES_MALE[token] or token
		options[#options + 1] = { value = id, label = name, classToken = token, className = name }
	end
	table.sort(options, function(a, b) return a.label < b.label end)
	return options
end

function F.GetSpell(classID)
	local saved = addon.db and addon.db.mouseCrosshairRangeSpellsByClass
	local value = saved and saved[classID]
	if value == false then return nil, true end
	value = tonumber(value)
	if value and value > 0 then return math.floor(value), true end
	local profile = addon.RangeDisplay.flavors.forever.classes[F.classes[classID]]
	return profile and profile.crosshair, false
end

function F.SetSpell(classID, value)
	if not addon.db or not F.classes[classID] then return end
	local saved = addon.db.mouseCrosshairRangeSpellsByClass or {}
	addon.db.mouseCrosshairRangeSpellsByClass = saved
	if value == "DEFAULT" then saved[classID] = nil
	elseif value == "NONE" then saved[classID] = false
	else saved[classID] = tonumber(value) end
	if not next(saved) then addon.db.mouseCrosshairRangeSpellsByClass = nil end
end

function F.StopTimer()
	if F.ticker then F.ticker:Cancel(); F.ticker = nil end
end

function F.HasTarget()
	local exists, attack, dead = UnitExists("target"), UnitCanAttack("player", "target"), UnitIsDeadOrGhost("target")
	return public(exists) and exists and public(attack) and attack and public(dead) and not dead
end

function F.Tick(force)
	local result
	if F.active and F.spellID and F.HasTarget() then
		local visible = UnitIsVisible("target")
		if public(visible) and visible then
			local value = C_Spell.IsSpellInRange(F.spellID, "target")
			if public(value) and type(value) == "boolean" then result = value end
		end
	else
		F.StopTimer()
	end
	if force or result ~= F.inRange then
		F.inRange = result
		if F.notify then F.notify(result) end
	end
end

function F.RefreshTarget()
	F.Tick(true)
	if F.active and F.spellID and F.HasTarget() and not F.ticker then
		F.ticker = C_Timer.NewTicker(0.1, function() F.Tick() end)
	end
end

function F.Refresh(notify)
	F.notify = notify or F.notify
	F.active = addon.db and addon.db.mouseCrosshairEnabled == true and addon.db.mouseCrosshairMeleeRange == true
	addon.RangeDisplay.SetSpellCacheConsumer("crosshair", F.active and F.Refresh or nil)
	F.spellID = nil
	if F.active then
		local _, _, classID = UnitClass("player")
		F.spellID = addon.RangeDisplay.ResolveLearnedSpell(F.GetSpell(classID))
		if not F.events then
			F.events = CreateFrame("Frame")
			F.events:SetScript("OnEvent", function(_, event, unit)
				if event == "UNIT_FACTION" or event == "UNIT_FLAGS" then
					if unit == "target" then F.RefreshTarget() end
				else F.Refresh() end
			end)
		end
		for _, event in ipairs({ "UNIT_FACTION", "UNIT_FLAGS" }) do
			F.events:RegisterEvent(event)
		end
	elseif F.events then
		F.events:UnregisterAllEvents()
	end
	F.RefreshTarget()
end
