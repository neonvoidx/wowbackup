local _, addon = ...
local M = { bundles = {}, units = {}, plan = {}, signature = "", dirty = false }
addon.NameplateAuraColors = M
M.MigrateProfile = addon.functions.MigrateNameplateAuraColorProfile
M.CanonicalSpellID = addon.functions.CanonicalNameplateAuraSpellID

local function secret(value) return issecretvalue and issecretvalue(value) end
function M.IsSupported()
	return C_NamePlate and C_NamePlate.GetNamePlates and addon.AuraCompat and addon.AuraCompat:HasAuraContainerSupport() or false
end

local function color(source)
	local result = {}
	for i = 1, 4 do
		local v = type(source) == "table" and tonumber(source[i]) or nil
		result[i] = v and v == v and math.max(0, math.min(1, v)) or 1
	end
	return result
end

local function spellIDs(id)
	local result = { [id] = true }
	-- Aura IDs and cast IDs differ for these rank families.
	local aliases = { [164812] = 8921, [164815] = 93402, [155722] = 1822 }
	local base = aliases[id] or id
	if not (addon.variables and addon.variables.isForever) and (base == 8921 or id == 155625) then
		result[164812], result[155625], result[8921] = true, true, true
	end
	if not (addon.variables and addon.variables.isForever) and (id == 269747 or id == 1253171) then
		result[269747], result[1253171] = true, true
	end
	for auraID, castID in pairs(aliases) do
		if id == castID then result[auraID] = true end
	end
	result[base] = true
	for _, family in pairs(addon.SpellRankFamilies or {}) do
		local found = false
		for _, rank in ipairs(family) do if rank == base then found = true; break end end
		if found then for _, rank in ipairs(family) do result[rank] = true end; break end
	end
	return result
end

function M.ActiveSpecID()
	if addon.variables and addon.variables.isForever then return end
	if not (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecializationInfo) then return end
	local index = C_SpecializationInfo.GetSpecialization()
	if index then return C_SpecializationInfo.GetSpecializationInfo(index) end
end

local function compile()
	local db = addon.db and addon.db.nameplateAuraColorRules
	local class = select(2, UnitClass("player"))
	local profile = type(db) == "table" and type(db.classes) == "table" and db.classes[class]
	if not (type(db) == "table" and db.enabled and type(profile) == "table") then return {}, "" end
	local specID = M.ActiveSpecID()
	local spec = specID and profile.specs and profile.specs[specID]
	if type(spec) == "table" and spec.useOwn == true then profile = spec end
	local plan, signature = {}, { class }
	M.MigrateProfile(profile)
	for _, rule in ipairs(profile.rules) do
		if type(rule) == "table" and rule.enabled and (rule.health or rule.border) and type(rule.spells) == "table" and #plan < 16 then
			local ids, seen = {}, {}
			for _, id in ipairs(rule.spells) do
				if type(id) == "number" and id > 0 and id < math.huge and id % 1 == 0 and not seen[id] then
					ids[#ids + 1], seen[id] = id, true
				end
			end
			if #ids >= 1 and #ids <= 5 then
				local entry = { filters = {}, filter = rule.onlyMine ~= false and "HARMFUL|PLAYER" or "HARMFUL", health = rule.health == true, border = rule.border == true,
					healthColor = color(rule.healthColor), borderColor = color(rule.borderColor), priority = 7 - #plan }
				for _, id in ipairs(ids) do entry.filters[#entry.filters + 1] = spellIDs(id) end
				plan[#plan + 1] = entry
				signature[#signature + 1] = table.concat(ids, ",") .. ":" .. entry.filter .. ":" .. tostring(entry.health) .. ":" .. tostring(entry.border)
				signature[#signature + 1] = table.concat(entry.healthColor, ",") .. ":" .. table.concat(entry.borderColor, ",")
			end
		end
	end
	return plan, table.concat(signature, ";")
end

local function disable(variant)
	for _, container in ipairs(variant.containers) do container:SetEnabled(false) end
	variant.host:Hide()
	variant.unit = nil
end

local function container(variant, parent)
	local c = addon.AuraCompat:CreateAuraContainer(parent)
	c:SetEnabled(false)
	c:SetFrameStrata(variant.strata)
	c:SetSize(1, 1)
	c:SetPoint("TOPLEFT", variant.host, "TOPLEFT")
	variant.containers[#variant.containers + 1] = c
	return c
end

local function decorate(button, variant, rule)
	button:SetFrameLevel(variant.level)
	if rule.health then
		local fill = button:CreateTexture(nil, "ARTWORK", nil, rule.priority)
		fill:SetAllPoints(variant.fill)
		-- Preserve the native artwork's alpha at rounded corners.
		local atlas = variant.fill:GetAtlas()
		if not secret(atlas) and atlas and atlas ~= "" then
			fill:SetAtlas(atlas, false)
		else
			local texture = variant.fill:GetTexture()
			if secret(texture) then return end
			fill:SetTexture(texture or "Interface\\Buttons\\WHITE8x8")
		end
		fill:SetDesaturated(true)
		fill:SetVertexColor(unpack(rule.healthColor))
	end
	if rule.border and variant.border and variant.borderAtlas then
		-- Use native border artwork and geometry, gated by this aura slot.
		-- A separate child level keeps the tint above the native selection texture
		-- without raising the health fill above Blizzard's text.
		local host = CreateFrame("Frame", nil, button)
		host:SetFrameStrata(variant.strata)
		host:SetFrameLevel(variant.level + 1)
		host:SetAllPoints(variant.border)
		host:EnableMouse(false)
		local border = host:CreateTexture(nil, "OVERLAY", nil, rule.priority)
		border:SetAtlas(variant.borderAtlas, false)
		border:SetAllPoints(variant.border)
		border:SetVertexColor(unpack(rule.borderColor))
	end
end

local function chain(variant, root, rule, key, stage)
	root:AddAuraSlot(key, rule.filter, {
		candidateFilters = { includeSpellIDs = rule.filters[stage] },
		initializeFrame = function(button)
			-- Never retain or access a slot button after this initialization window.
			button:SetSize(1, 1)
			button:SetPoint("TOPLEFT", variant.host, "TOPLEFT")
			button:SetFrameStrata(variant.strata)
			button:EnableMouse(false)
			if stage == #rule.filters then
				decorate(button, variant, rule)
			else
				local nested = container(variant, button)
				chain(variant, nested, rule, key .. "n", stage + 1)
			end
		end,
	})
end

local function createVariant(bar, fill)
	local level, strata = bar:GetFrameLevel(), bar:GetFrameStrata()
	if secret(level) or secret(strata) then return nil end
	local border = bar.selectedBorder
	local atlas
	if secret(border) then border = nil end
	if border then atlas = border:GetAtlas() end
	if secret(atlas) then atlas = nil end
	local variant = { bar = bar, fill = fill, border = border, borderAtlas = atlas, containers = {}, level = level, strata = strata }
	variant.host = CreateFrame("Frame", nil, bar)
	variant.host:SetAllPoints(bar)
	variant.host:EnableMouse(false)
	variant.host:Hide()
	local root = container(variant, variant.host)
	for i = #M.plan, 1, -1 do chain(variant, root, M.plan[i], "rule" .. i, 1) end
	return variant
end

local function detach(unit)
	local variant = M.units[unit]
	if variant then disable(variant); M.units[unit] = nil end
end

local function attach(unit)
	if #M.plan == 0 or secret(unit) or type(unit) ~= "string" then return end
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	local uf = plate and plate.UnitFrame
	if not uf or secret(uf) then return end
	local bar = uf.healthBar or (uf.HealthBarsContainer and uf.HealthBarsContainer.healthBar) or uf.HealthBar
	if not bar or secret(bar) or bar:IsForbidden() then return end
	local fill = bar:GetStatusBarTexture()
	if not fill or secret(fill) then return end
	local bundle = M.bundles[bar]
	if not bundle then bundle = {}; M.bundles[bar] = bundle end
	local variant = bundle[M.signature]
	if variant and variant.fill ~= fill then disable(variant); variant = nil end
	if not variant then variant = createVariant(bar, fill); bundle[M.signature] = variant end
	if not variant then return end
	if variant.unit then M.units[variant.unit] = nil end
	detach(unit)
	variant.unit, M.units[unit] = unit, variant
	variant.host:Show()
	for _, c in ipairs(variant.containers) do c:SetUnit(unit); c:SetEnabled(true) end
end

function M.Refresh() M.dirty = true end
function M.Apply()
	if InCombatLockdown() then M.pending = true; return end
	M.pending, M.dirty = nil, false
	for unit in pairs(M.units) do detach(unit) end
	M.plan, M.signature = compile()
	if not M.IsSupported() or #M.plan == 0 then
		M.events:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
		M.events:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
		return
	end
	M.events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	M.events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
		local unit
		if plate.GetUnit then unit = plate:GetUnit() else unit = plate.unitToken end
		if not secret(unit) then
			if not unit then unit = plate.namePlateUnitToken end
			if not secret(unit) and type(unit) == "string" then attach(unit) end
		end
	end
end

M.events = CreateFrame("Frame")
M.events:RegisterEvent("PLAYER_LOGIN")
M.events:RegisterEvent("PLAYER_REGEN_ENABLED")
if not (addon.variables and addon.variables.isForever) then M.events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") end
M.events:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" or (event == "PLAYER_REGEN_ENABLED" and M.pending)
		or (event == "PLAYER_SPECIALIZATION_CHANGED" and (unit == "player" or unit == nil)) then M.Apply()
	elseif event == "NAME_PLATE_UNIT_ADDED" then attach(unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then detach(unit) end
end)
